#!/usr/bin/env bash
# Full verification: compile everything, run the unit tests of every package, and
# run the headless rendering examples (each of which prints OK only when the
# backend reported zero validation errors).
#
# Requires a C99-capable `cc` for the native backend (see setup-linux.sh; macOS
# and recent Linux distributions are fine out of the box).
set -euo pipefail
cd "$(dirname "$0")"

if [ -d "$PWD/.toolchain" ]; then
  export PATH="$PWD/.toolchain:$PATH"
fi
export PATH="$HOME/.moon/bin:$PATH"

echo "== moon check"
moon check

echo
echo "== moon test"
for pkg in tycho shader geometry 2d 3d ui image window dx12; do
  printf '%-10s ' "$pkg"
  moon test -p "$pkg" 2>&1 | grep -E '^Total tests' | tr '\n' ' '
  echo
done

EXAMPLES=(
  examples/rhi/triangle
  examples/rhi/texture
  examples/rhi/mrt-postprocess
  examples/2d/showcase
  examples/3d/showcase
  examples/3d/skinning
  examples/3d/morph
  examples/3d/gltf
  examples/general/3d-hud
  examples/ui/gallery
)

echo
echo "== headless examples"
fail=0
for ex in "${EXAMPLES[@]}"; do
  if out=$(moon run --target native "$ex" 2>&1); then
    line=$(printf '%s\n' "$out" | grep -E 'OK|validation' | tail -1)
    if printf '%s' "$out" | grep -q 'OK'; then
      echo "ok   $ex"
      printf '       %s\n' "$line"
    else
      echo "FAIL $ex (no OK in output)" >&2
      printf '%s\n' "$out" | tail -20 >&2
      fail=1
    fi
  else
    echo "FAIL $ex (non-zero exit)" >&2
    printf '%s\n' "$out" | tail -20 >&2
    fail=1
  fi
done

echo
if [ "$fail" -ne 0 ]; then
  echo "verify: FAILED" >&2
  exit 1
fi
echo "verify: all checks passed"
