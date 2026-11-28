#!/usr/bin/env python3
"""Measure how much of the generated DX12 COM dispatch is exercised by examples.

Usage: python tools/dx12-exec-coverage.py [--list] [--json]

This is the DX12 analog of tools/coverage.py (Vulkan): a source scan of the
example suites for the generated `dx_*` thunks, mapped back to the manifest's
Interface::Method surface. It measures *executed* raw-dispatch coverage.

It is deliberately distinct from tools/dx12-coverage.py, which gates *binding
completeness* (every header method is bound). A method can be bound (100% there)
yet never called by an example (what this script tracks). The hand-written safe
API in dx12.mbt reaches COM through dx12_stub.c, not the generated thunks, so
examples that only use the safe API do not count toward this metric — that is
what examples/dx12/raw-dispatch is for.
"""

from __future__ import annotations

import importlib.util
import json
import pathlib
import re
import sys

sys.dont_write_bytecode = True

ROOT = pathlib.Path(__file__).resolve().parent.parent


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


def executed(fn_to_method):
    done = set()
    for pat in ("examples/dx12/*/main.mbt", "dx12/dx12_wbtest.mbt"):
        for f in ROOT.glob(pat):
            text = f.read_text(encoding="utf-8")
            for m in re.finditer(r"\bdx_[a-z0-9_]+\b", text):
                label = fn_to_method.get(m.group(0))
                if label:
                    done.add(label)
    return done


def main() -> int:
    gen = load_generator()
    fn_to_method = surface(gen)
    done = executed(fn_to_method)
    total = len(fn_to_method)
    remaining = sorted(set(fn_to_method.values()) - done)

    report = {
        "generated_methods": total,
        "executed": len(done),
        "remaining": len(remaining),
        "percent": round(100.0 * len(done) / max(1, total), 2),
    }
    if "--json" in sys.argv:
        report["remaining_methods"] = remaining
        print(json.dumps(report, indent=2))
        return 0

    print(f"generated COM methods : {total}")
    print(f"executed by examples  : {len(done)} ({report['percent']}%)")
    print(f"remaining             : {len(remaining)}")
    if "--list" in sys.argv:
        by_iface = {}
        for label in remaining:
            iface, _, method = label.partition("::")
            by_iface.setdefault(iface, []).append(method)
        for iface in sorted(by_iface):
            print(f"  {iface} ({len(by_iface[iface])})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
