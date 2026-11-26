#!/usr/bin/env bash
# Enforce the module layering rules from roadmap/tycho-3d-design.md:
#   geometry -> math only (no RHI, no 2d/ui)
#   3d       -> tycho + math + geometry + pool, never 2d/ui
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail=0

check_imports() {
  local label="$1" pkg="$2" allowed="$3"
  while IFS= read -r dep; do
    [ -z "$dep" ] && continue
    if ! grep -qE "$allowed" <<<"$dep"; then
      echo "LAYERING: $label imports forbidden package '$dep'" >&2
      fail=1
    fi
  done < <(grep -oE '"[^"]+"' "$pkg" | tr -d '"')
}

check_imports "geometry" "$ROOT/geometry/moon.pkg" '^(laplaceliu/tycho_math$|moonbitlang/core/)'
check_imports "3d" "$ROOT/3d/moon.pkg" \
  '^(laplaceliu/tycho$|laplaceliu/tycho_math$|laplaceliu/tycho_geometry$|laplaceliu/tycho/pool$|moonbitlang/core/)'

for src in "$ROOT/3d"/*.mbt; do
  if grep -qE '@g2d|@ui\b|tycho_2d|tycho_ui' "$src"; then
    echo "LAYERING: $(basename "$src") references 2d/ui" >&2
    fail=1
  fi
done

for src in "$ROOT/geometry"/*.mbt; do
  if grep -qE '@tycho\b|@g2d|@ui\b|create_buffer|create_texture|PipelineDesc' "$src"; then
    echo "LAYERING: $(basename "$src") touches GPU/RHI concepts" >&2
    fail=1
  fi
done

if [ "$fail" -ne 0 ]; then
  echo "3D LAYERING CHECK FAILED" >&2
  exit 1
fi
echo "3D LAYERING OK"
