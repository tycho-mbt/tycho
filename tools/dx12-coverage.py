#!/usr/bin/env python3
"""Report (and gate) how much of the Direct3D 12 / DXGI COM surface is bound.

Usage: python tools/dx12-coverage.py [--check] [--list]

The binding is generated from the same headers this script reads, so the target
is 100%: every interface and every COM method in d3d12.h, d3dcommon.h and
dxgi*.h must appear in dx12/registry/d3d12-abi.txt. `--check` exits non-zero if
anything is missing, which is what makes "100%" a maintained invariant instead of
a one-off claim.

Requires the Windows SDK headers (the manifest itself is committed, so the rest
of the generator runs anywhere).
"""

from __future__ import annotations

import importlib.util
import pathlib
import sys

# Importing the extractor by path would drop a __pycache__ into tools/; keep the
# tree clean for the drift gate.
sys.dont_write_bytecode = True

ROOT = pathlib.Path(__file__).resolve().parent.parent
MANIFEST = ROOT / "dx12" / "registry" / "d3d12-abi.txt"


def load_extractor():
    """The module name has a dash, so import it by path."""
    path = ROOT / "tools" / "dump-d3d12-abi.py"
    spec = importlib.util.spec_from_file_location("dump_d3d12_abi", path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def header_surface(extractor) -> dict[str, int]:
    surface: dict[str, int] = {}
    for header_path in extractor.DEFAULT_HEADERS:
        if not header_path.is_file():
            continue
        lines = header_path.read_text(encoding="utf-8", errors="replace").splitlines()
        i = 0
        while i < len(lines):
            if not extractor.re.match(r"\s*typedef struct (\w+)Vtbl\s*$", lines[i]):
                i += 1
                continue
            name, methods, i = extractor.parse_interface(lines, i)
            surface[name] = len(methods)
    return surface


def manifest_surface() -> dict[str, int]:
    surface: dict[str, int] = {}
    current = None
    for raw in MANIFEST.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if line.startswith("interface "):
            current = line.split()[1]
            surface[current] = 0
        elif line.startswith("kind ") or not line or line.startswith("#"):
            continue
        elif current and raw.startswith("  ") and " ret=" in line:
            surface[current] += 1
    return surface


def main() -> int:
    check_only = "--check" in sys.argv[1:]
    show_list = "--list" in sys.argv[1:]
    extractor = load_extractor()
    header = header_surface(extractor)
    manifest = manifest_surface()

    missing = {k: v for k, v in header.items() if k not in manifest}
    short = {
        k: (v, manifest[k])
        for k, v in header.items()
        if k in manifest and manifest[k] != v
    }
    extra = [k for k in manifest if k not in header]

    h_total = sum(header.values())
    m_total = sum(manifest.values())
    covered = sum(v for k, v in header.items() if k in manifest)
    pct = 100.0 * covered / h_total if h_total else 0.0

    print(f"headers   : {len(header):3d} interfaces / {h_total:5d} methods")
    print(f"manifest  : {len(manifest):3d} interfaces / {m_total:5d} methods")
    print(f"coverage  : {pct:5.1f}% of methods, {100.0 * len([k for k in header if k in manifest]) / len(header) if header else 0:5.1f}% of interfaces")

    if show_list:
        for name in sorted(header):
            state = "bound" if name in manifest and manifest[name] == header[name] else "MISSING"
            print(f"  {state:8s} {name} ({header[name]} methods)")

    if missing or short or extra:
        for name, count in sorted(missing.items()):
            print(f"MISSING interface {name} ({count} methods)", file=sys.stderr)
        for name, (want, have) in sorted(short.items()):
            print(f"MISMATCH {name}: header {want}, manifest {have}", file=sys.stderr)
        for name in extra:
            print(f"STALE {name}: in the manifest, not in the headers", file=sys.stderr)
        if check_only:
            return 1
        return 0

    if check_only:
        print("dx12 surface is complete (every header interface and method is bound)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
