#!/usr/bin/env bash
# The typed 3D examples (61+) must go through @t3d/@tgeo and must not drop to
# raw RHI drawing commands; every example must stay free of 2d/ui siblings.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail=0

for dir in "$ROOT"/examples/[0-9]*; do
  [ -d "$dir" ] || continue
  name="$(basename "$dir")"
  pkg="$dir/moon.pkg"
  [ -f "$pkg" ] || continue
  # Only the typed 3D examples are covered by this check.
  case "$name" in
    *tycho-3d*|*tycho-geometry*) ;;
    *) continue ;;
  esac

  # Example 72 is the 3D + 2D HUD composition demo (R-2D1): importing tycho_2d
  # is its entire point. The tycho_3d library itself never depends on 2d/ui,
  # and the raw-RHI ban below still applies to it.
  if [ "$name" = "72-tycho-3d-hud" ]; then
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
