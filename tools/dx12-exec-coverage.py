#!/usr/bin/env python3
"""Measure how much of the generated DX12 COM dispatch is exercised by examples.

Usage: python tools/dx12-exec-coverage.py [--list] [--json] [--live-only] [--check]

This is the DX12 analog of tools/coverage.py (Vulkan): a source scan of the
example suites for the generated `dx_*` thunks and the 15 DLL free entry points,
mapped back to the manifest's Interface::Method surface.

Flags:
  --list       Print remaining uncovered interfaces (and free functions)
  --json       Emit machine-readable JSON report
  --live-only  Exclude examples/dx12/raw-platform-ext/* to measure only live calls
  --check      Exit 1 unless 100% of COM methods and all 15 free functions are covered
"""

from __future__ import annotations

import importlib.util
import json
import pathlib
import re
import sys

sys.dont_write_bytecode = True

ROOT = pathlib.Path(__file__).resolve().parent.parent

FREE_ENTRY_POINTS = [
    "d3d12_create_device",
    "d3d12_get_debug_interface",
    "d3d12_serialize_root_signature",
    "d3d12_create_root_signature_deserializer",
    "d3d12_serialize_versioned_root_signature",
    "d3d12_create_versioned_root_signature_deserializer",
    "d3d12_create_versioned_root_signature_deserializer_from_subobject_in_library",
    "d3d12_enable_experimental_features",
    "d3d12_get_interface",
    "create_dxgi_factory",
    "create_dxgi_factory1",
    "create_dxgi_factory2",
    "dxgi_get_debug_interface1",
    "dxgi_declare_adapter_removal_support",
    "dxgi_disable_vblank_virtualization",
]


def load_generator():
    path = ROOT / "tools" / "gen-dx12-bindings.py"
    spec = importlib.util.spec_from_file_location("gen_dx12_bindings", path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def surface(gen):
    """Map generated function name -> 'Interface::Method' and the reverse."""
    fn_to_method = {}
    for iface in gen.parse_manifest()[0]:
        prefix = gen.iface_prefix(iface["name"])
        for method in iface["methods"]:
            fn = "dx_" + prefix + "_" + gen.snake(method["name"])
            fn_to_method[fn] = iface["name"] + "::" + method["name"]
    return fn_to_method


def executed(fn_to_method, live_only: bool):
    done = set()
    free_done = set()
    free_set = set(FREE_ENTRY_POINTS)
    for pat in ("examples/dx12/*/*.mbt", "dx12/dx12_wbtest.mbt"):
        for f in ROOT.glob(pat):
            if live_only and f.parent.name == "raw-platform-ext":
                continue
            text = f.read_text(encoding="utf-8")
            for m in re.finditer(r"\bdx_[a-z0-9_]+\b", text):
                label = fn_to_method.get(m.group(0))
                if label:
                    done.add(label)
            for m in re.finditer(r"(?:@dx12\.)?\b([a-z0-9_]+)\b", text):
                name = m.group(1)
                if name in free_set:
                    free_done.add(name)
    return done, free_done


def main() -> int:
    live_only = "--live-only" in sys.argv
    check = "--check" in sys.argv
    gen = load_generator()
    fn_to_method = surface(gen)
    done, free_done = executed(fn_to_method, live_only)
    total = len(fn_to_method)
    remaining = sorted(set(fn_to_method.values()) - done)
    free_total = len(FREE_ENTRY_POINTS)
    free_remaining = sorted(set(FREE_ENTRY_POINTS) - free_done)

    report = {
        "generated_methods": total,
        "executed": len(done),
        "remaining": len(remaining),
        "percent": round(100.0 * len(done) / max(1, total), 2),
        "free_entry_points": free_total,
        "free_executed": len(free_done),
        "free_remaining": free_remaining,
        "live_only": live_only,
    }
    if "--json" in sys.argv:
        report["remaining_methods"] = remaining
        print(json.dumps(report, indent=2))
        if check and (remaining or free_remaining):
            return 1
        return 0

    mode = " (live-only)" if live_only else ""
    print(f"generated COM methods : {total}")
    print(f"executed by examples  : {len(done)} ({report['percent']}%){mode}")
    print(f"remaining COM         : {len(remaining)}")
    print(f"free DLL entry points : {len(free_done)} / {free_total}")
    if "--list" in sys.argv:
        by_iface = {}
        for label in remaining:
            iface, _, method = label.partition("::")
            by_iface.setdefault(iface, []).append(method)
        for iface in sorted(by_iface):
            print(f"  {iface} ({len(by_iface[iface])})")
        if free_remaining:
            print("  free entry points missing:", ", ".join(free_remaining))
    if check and (remaining or free_remaining):
        print(
            f"FAIL: {len(remaining)} COM methods and {len(free_remaining)} free entry points uncovered",
            file=sys.stderr,
        )
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
