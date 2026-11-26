#!/usr/bin/env bash
# Enforce the math layering contract from ADR-002:
#   1. laplaceliu/tycho_math stays dependency-free (only moonbitlang/core/math).
#   2. tycho_math never references the RHI / 2D / UI / bindings packages.
#   3. The RHI uses @tmath only in its façade (rhi.mbt, types.mbt), never in the
#      Vulkan backend, so the backend stays replaceable by Metal/DX12.
set -euo pipefail
cd "$(dirname "$0")"

fail=0

# 1. No laplaceliu/* dependency in the math module.
if grep -nE '^[[:space:]]*"laplaceliu/' math/moon.mod math/moon.pkg >/dev/null 2>&1; then
  echo "FAIL: math/moon.mod and math/moon.pkg must not depend on laplaceliu/* packages"
  grep -nE '^[[:space:]]*"laplaceliu/' math/moon.mod math/moon.pkg || true
  fail=1
fi

# 2. No upward references from the math sources.
if grep -rnE '@(tycho|g2d|vk|shader|win)\b' math/*.mbt math/f64/*.mbt >/dev/null 2>&1; then
  echo "FAIL: tycho_math must not reference RHI/2D/UI/bindings packages"
  grep -rnE '@(tycho|g2d|vk|shader|win)\b' math/*.mbt math/f64/*.mbt || true
  fail=1
fi

# 3. @tmath only in the RHI façade (tests and benchmarks are exempt).
for f in tycho/*.mbt; do
  case "$f" in
    *_test.mbt|*_wbtest.mbt|*_bench.mbt|tycho/rhi.mbt|tycho/types.mbt) continue ;;
  esac
  if grep -q '@tmath' "$f"; then
    echo "FAIL: @tmath used outside the RHI façade: $f"
    grep -n '@tmath' "$f" || true
    fail=1
  fi
done

if [ "$fail" -eq 0 ]; then
  echo "OK: math layering contract holds (math is a leaf; RHI uses it only in its façade)"
fi

exit "$fail"
