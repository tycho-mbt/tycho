#!/usr/bin/env python3
"""Cross-platform Tycho example test runner for CI (Linux, Windows, macOS).

Runs built MoonBit example binaries (.exe on all native targets), enforces the
same strict PASS / SKIP / FAIL / non-vacuous-coverage rules as tools/run-all.sh,
and works uniformly under Python 3 on Linux, Windows, and macOS.
"""

from __future__ import annotations

import argparse
import pathlib
import re
import subprocess
import sys

RHI_EXAMPLES = [
    "08-rhi-triangle",
    "09-rhi-uniform",
    "10-rhi-vertex",
    "11-rhi-texture",
    "12-rhi-compute",
    "13-rhi-sampler",
    "38-rhi-3d-cube",
    "39-rhi-msaa-offscreen",
    "40-rhi-reflection-mipmaps",
    "41-rhi-compute-storage-image",
    "42-rhi-mrt-postprocess",
    "43-rhi-hardening",
    "44-rhi-pipeline-instancing",
    "45-rhi-textures-samplers",
    "46-rhi-indirect-bindless",
    "47-rhi-mesh",
    "48-rhi-shadow-hdr",
    "49-rhi-pbr-showcase",
    "50-rhi-bench",
    "52-rhi-rayquery-stencil",
    "53-rhi-2d-sdf-batch",
]

WORD_FAIL = re.compile(r"\bFAIL\b")
WORD_SKIP = re.compile(r"\bSKIP\b")
VACUOUS_OK = re.compile(r"OK — 0 |commands=0 ")


def discover_examples(root: pathlib.Path, mode: str) -> list[str]:
    if mode == "rhi":
        return [
            name
            for name in RHI_EXAMPLES
            if (root / "examples" / name / "moon.pkg").is_file()
        ]
    names = []
    for pkg in sorted((root / "examples").glob("*/moon.pkg")):
        names.append(pkg.parent.name)
    return names


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--build-dir",
        default="_build/native/debug/build/laplaceliu/tycho_vulkan_examples",
    )
    parser.add_argument("--mode", choices=("rhi", "all"), default="rhi")
    parser.add_argument("--skip", default="")
    parser.add_argument("--timeout", type=int, default=90)
    parser.add_argument("--require-pass", type=int, default=1)
    args = parser.parse_args()

    root = pathlib.Path(__file__).resolve().parent.parent
    build_dir = pathlib.Path(args.build_dir)
    if not build_dir.is_absolute():
        build_dir = root / build_dir
    if not build_dir.is_dir():
        print(f"ERROR: build dir not found: {build_dir}", file=sys.stderr)
        return 1

    skip_set = {s.strip() for s in args.skip.split(",") if s.strip()}
    examples = discover_examples(root, args.mode)

    passed = 0
    failed = 0
    skipped = 0

    for name in examples:
        if name in skip_set:
            print(f"  SKIP     {name} (--skip)")
            skipped += 1
            continue
        exe = build_dir / name / f"{name}.exe"
        if not exe.is_file():
            print(f"  MISSING  {name} ({exe})")
            failed += 1
            continue
        try:
            proc = subprocess.run(
                [str(exe)],
                cwd=str(root),
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
                errors="replace",
                timeout=args.timeout,
            )
            rc = proc.returncode
            out = proc.stdout or ""
        except subprocess.TimeoutExpired as exc:
            rc = -1
            out = (exc.stdout or "") + f"\nTIMEOUT after {args.timeout}s"

        lines = [ln for ln in out.splitlines() if ln.strip()]
        tail = lines[-1] if lines else "(no output)"

        if rc != 0 or WORD_FAIL.search(out):
            print(f"  FAIL     {name} (rc={rc})")
            for ln in lines[-10:]:
                print(f"           {ln}")
            failed += 1
        elif WORD_SKIP.search(out):
            skip_lines = [ln for ln in lines if WORD_SKIP.search(ln)]
            summary = skip_lines[-1] if skip_lines else tail
            print(f"  SKIP     {name}  |  {summary}")
            skipped += 1
        elif VACUOUS_OK.search(out):
            print(f"  FAIL     {name} (empty coverage: OK with 0 commands)")
            for ln in lines[-10:]:
                print(f"           {ln}")
            failed += 1
        else:
            print(f"  OK       {name}  |  {tail}")
            passed += 1

    print(f"[summary] passed={passed} failed={failed} skipped={skipped}")
    if failed > 0:
        return 1
    if passed < args.require_pass:
        print(
            f"ERROR: passed={passed} < --require-pass={args.require_pass}",
            file=sys.stderr,
        )
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
