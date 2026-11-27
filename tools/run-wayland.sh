#!/usr/bin/env bash
# Run any Tycho example under Wayland with one command.
# Usage: ./tools/run-wayland.sh [--nvidia|--lavapipe] <module/name> [args...]
# Example: ./tools/run-wayland.sh rhi/pbr-showcase --window
#          ./tools/run-wayland.sh window/wayland
set -euo pipefail
cd "$(dirname "$0")/.."

DRIVER_MODE="auto"
while [ $# -gt 0 ]; do
  case "$1" in
    --nvidia)   DRIVER_MODE="nvidia"; shift ;;
    --lavapipe) DRIVER_MODE="lavapipe"; shift ;;
    -h|--help)
      echo "Usage: $0 [--nvidia|--lavapipe] <example-name> [args...]"
      exit 0
      ;;
    *) break ;;
  esac
done

if [ $# -lt 1 ]; then
  echo "Usage: $0 [--nvidia|--lavapipe] <example-name> [args...]" >&2
  exit 1
fi

NAME="$1"
shift

BUILD_DIR="${TYCHO_EXAMPLES_DIR:-_build/native/debug/build/laplaceliu/tycho_vulkan_examples}"
EXE="$BUILD_DIR/$NAME/${NAME##*/}.exe"
if [ ! -x "$EXE" ]; then
  echo "ERROR: $EXE not found — run ./build.sh first." >&2
  exit 1
fi

export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
export TYCHO_WINDOW_BACKEND=wayland

WESTON_PID=""
cleanup() {
  if [ -n "$WESTON_PID" ]; then
    kill "$WESTON_PID" 2>/dev/null || true
    wait "$WESTON_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT

NESTED_WESTON=0
if [ -n "${WAYLAND_DISPLAY:-}" ] && [ -S "$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY" ]; then
  :
elif [ -S "$XDG_RUNTIME_DIR/wl-preview" ]; then
  export WAYLAND_DISPLAY=wl-preview
  NESTED_WESTON=1
elif command -v weston >/dev/null 2>&1 && [ -n "${DISPLAY:-}" ]; then
  export WAYLAND_DISPLAY=wl-preview
  NESTED_WESTON=1
  weston --backend=x11-backend.so --socket=wl-preview --width=1024 --height=768 >/tmp/tycho-weston.log 2>&1 &
  WESTON_PID=$!
  for _ in $(seq 1 50); do
    [ -S "$XDG_RUNTIME_DIR/wl-preview" ] && break
    sleep 0.1
  done
  if [ ! -S "$XDG_RUNTIME_DIR/wl-preview" ]; then
    echo "ERROR: weston failed to create $XDG_RUNTIME_DIR/wl-preview (see /tmp/tycho-weston.log)" >&2
    exit 1
  fi
else
  echo "ERROR: No Wayland compositor running and weston/DISPLAY not available." >&2
  exit 1
fi

# Nested Weston on X11 exposes Mesa/llvmpipe buffers rather than NVIDIA DRM,
# so default to lavapipe unless the caller explicitly asked for --nvidia or set VK_DRIVER_FILES.
if [ "$DRIVER_MODE" = "lavapipe" ] || { [ "$DRIVER_MODE" = "auto" ] && [ "$NESTED_WESTON" = "1" ] && [ -z "${VK_DRIVER_FILES:-}" ]; }; then
  for cand in /usr/share/vulkan/icd.d/lvp_icd.x86_64.json /usr/share/vulkan/icd.d/lvp_icd.json; do
    if [ -f "$cand" ]; then
      export VK_DRIVER_FILES="$cand"
      break
    fi
  done
fi

# Run without exec so EXIT trap cleans up any nested Weston we started.
"$EXE" "$@"
