#!/usr/bin/env bash
# Run Wayland-capable windowed examples against an active Wayland compositor.
# Set WAYLAND_DISPLAY before running (e.g. WAYLAND_DISPLAY=wayland-0).
set -euo pipefail
cd "$(dirname "$0")/.."

if [ -z "${WAYLAND_DISPLAY:-}" ]; then
  echo "SKIP: WAYLAND_DISPLAY is not set."
  exit 0
fi

BUILD_DIR="${TYCHO_EXAMPLES_DIR:-_build/native/debug/build/laplaceliu/tycho_vulkan_examples}"
export TYCHO_WINDOW_BACKEND=wayland

for name in vulkan/presentation vulkan/wsi-queries vulkan/wsi-display window/wayland; do
  exe="$BUILD_DIR/$name/${name##*/}.exe"
  echo "=== $name (Wayland) ==="
  timeout 30 "$exe"
done

