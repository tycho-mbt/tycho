#!/usr/bin/env bash
# The typed 3D examples (examples/3d/* plus the cross-module general/3d-hud)
# must go through @t3d/@tgeo and must not drop to raw RHI drawing commands;
# every example must stay free of 2d/ui siblings.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail=0

for pkg in "$ROOT"/examples/*/*/moon.pkg; do
  [ -f "$pkg" ] || continue
  dir="$(dirname "$pkg")"
  name="${dir#"$ROOT"/examples/}"
  # Only the typed 3D examples are covered by this check.
  case "$name" in
    3d/* | general/3d-hud) ;;
    *) continue ;;
  esac

  # The 3D + 2D HUD composition demo (R-2D1) lives in general/ because importing
  # tycho_2d is its entire point. The tycho_3d library itself never depends on
  # 2d/ui, and the raw-RHI ban below still applies to it.
  if [ "$name" = "general/3d-hud" ]; then
    :
  elif grep -qE 'tycho_2d|tycho_ui' "$pkg"; then
    echo "PURITY: $name imports a 2d/ui sibling" >&2
    fail=1
  fi

  if ! grep -q 'laplaceliu/tycho_3d' "$pkg"; then
    echo "PURITY: $name does not import tycho_3d" >&2
    fail=1
  fi
  for raw in create_graphics_pipeline create_compute_pipeline begin_render_pass \
             bind_vertex bind_index draw_indexed upload_floats create_buffer_with; do
    if grep -q "$raw" "$dir/main.mbt"; then
      echo "PURITY: $name calls raw RHI '$raw'" >&2
      fail=1
    fi
  done
done

if [ "$fail" -ne 0 ]; then
  echo "EXAMPLES PURITY CHECK FAILED" >&2
  exit 1
fi
echo "EXAMPLES PURITY OK"
