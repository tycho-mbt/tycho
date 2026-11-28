#!/usr/bin/env bash
# Golden gate for tycho_3d: unit tests plus headless 3D examples on every
# available ICD (lavapipe and NVIDIA here). Each example asserts its own pixels,
# stats and picking, and must report validation=0.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if [ -d "$ROOT/.toolchain" ]; then
  export PATH="$ROOT/.toolchain:$PATH"
fi

EXAMPLES=(
  3d/showcase
  3d/hello
  3d/transmission
  3d/ssao
  geometry/primitives
  3d/instances
  3d/textures
  3d/transparency
  3d/debug-lines
  3d/env-quality
  3d/msaa
  3d/gltf
  3d/gpu-driven
  general/3d-hud
  3d/hdr-ibl
  3d/brdf-fallback
  3d/shadow-atlas
  3d/animation
  3d/gltf-viewer
  3d/gltf-animation
  3d/skinning
  3d/lod
  3d/clearcoat
  3d/morph
  3d/point-shadow
  3d/ray-shadow
)

echo "== unit tests =="
(cd "$ROOT/geometry" && moon test --target native)
(cd "$ROOT/3d" && moon test --target native)

echo "== geometry wasm =="
(cd "$ROOT/geometry" && moon check --target wasm-gc .)

echo "== layering =="
"$ROOT/tools/check-3d-layering.sh"
echo "== examples purity =="
"$ROOT/tools/check-examples-pure.sh"

echo "== build examples =="
(cd "$ROOT/examples" && moon build --target native "${EXAMPLES[@]}" rhi/pbr-showcase)
BIN_DIR="$ROOT/_build/native/debug/build/laplaceliu/tycho_vulkan_examples"

drivers=()
for name in lvp nvidia; do
  for icd in "/usr/share/vulkan/icd.d/${name}_icd.x86_64.json" \
             "/usr/share/vulkan/icd.d/${name}_icd.json"; do
    if [ -f "$icd" ]; then
      drivers+=("$name:$icd")
      break
    fi
  done
done
if [ ${#drivers[@]} -eq 0 ]; then
  echo "3D GATE: no Vulkan ICDs found; unit tests only"
  exit 0
fi

for entry in "${drivers[@]}"; do
  name="${entry%%:*}"
  icd="${entry#*:}"
  echo "== driver: $name =="
  for exe in "${EXAMPLES[@]}"; do
    out="$(VK_ICD_FILENAMES="$icd" timeout 300 "$BIN_DIR/$exe/${exe##*/}.exe" 2>&1)"
    echo "$out" | tail -2
    if ! grep -q "validation=0" <<<"$out"; then
      echo "3D GATE FAILED: $exe on $name reported validation errors" >&2
      exit 1
    fi
    if ! grep -q "\] OK" <<<"$out"; then
      echo "3D GATE FAILED: $exe on $name did not report OK" >&2
      exit 1
    fi
    if grep -q "LEAK" <<<"$out"; then
      echo "3D GATE FAILED: $exe on $name reported an allocator leak" >&2
      exit 1
    fi
  done
  echo "== driver: $name raw RHI regression (49) =="
  reg_out="$(VK_ICD_FILENAMES="$icd" timeout 300 "$BIN_DIR/rhi/pbr-showcase/pbr-showcase.exe" 2>&1)"
  echo "$reg_out" | tail -1
  if ! grep -q "\] OK" <<<"$reg_out" || ! grep -q "0 validation errors" <<<"$reg_out"; then
    echo "3D GATE FAILED: 49 regression on $name" >&2
    exit 1
  fi
done

echo "3D GATE OK: ${#drivers[@]} driver(s), ${#EXAMPLES[@]} examples, unit tests green"
