#!/usr/bin/env bash
# Golden gate for tycho_3d: unit tests plus headless examples 61/62 on every
# available ICD (lavapipe and NVIDIA here). Each example asserts its own pixels,
# stats and picking, and must report validation=0.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if [ -d "$ROOT/.toolchain" ]; then
  export PATH="$ROOT/.toolchain:$PATH"
fi

EXAMPLES=(
  62-tycho-3d-showcase
  63-tycho-geometry-primitives
  64-tycho-3d-instances
  65-tycho-3d-textures
  66-tycho-3d-transparency
  67-tycho-3d-debug-lines
  68-tycho-3d-env-quality
  69-tycho-3d-msaa
  70-tycho-3d-gltf
  71-tycho-3d-gpu-driven
  72-tycho-3d-hud
  73-tycho-3d-hdr-ibl
  74-tycho-3d-brdf-fallback
  75-tycho-3d-shadow-atlas
  76-tycho-3d-animation
  77-tycho-3d-gltf-viewer
  78-tycho-3d-gltf-animation
  79-tycho-3d-skinning
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
(cd "$ROOT/examples" && moon build --target native "${EXAMPLES[@]}" 49-rhi-pbr-showcase)
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
    out="$(VK_ICD_FILENAMES="$icd" timeout 300 "$BIN_DIR/$exe/$exe.exe" 2>&1)"
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
  reg_out="$(VK_ICD_FILENAMES="$icd" timeout 300 "$BIN_DIR/49-rhi-pbr-showcase/49-rhi-pbr-showcase.exe" 2>&1)"
  echo "$reg_out" | tail -1
  if ! grep -q "\] OK" <<<"$reg_out" || ! grep -q "0 validation errors" <<<"$reg_out"; then
    echo "3D GATE FAILED: 49 regression on $name" >&2
    exit 1
  fi
done

echo "3D GATE OK: ${#drivers[@]} driver(s), ${#EXAMPLES[@]} examples, unit tests green"
