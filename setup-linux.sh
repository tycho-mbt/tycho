#!/usr/bin/env bash
# Prepare a Linux development environment for Tycho.
# Usage: ./setup-linux.sh [path-to-slang-release]
set -euo pipefail
cd "$(dirname "$0")"

echo "== picking a C99-capable compiler =="
probe=$(mktemp /tmp/tycho_cc_probe_XXXXXX.c)
printf 'int main(void){for(int i=0;i<1;i++){}return 0;}\n' > "$probe"
chosen=""
for cand in "${TYCHO_CC:-}" gcc-14 gcc-13 gcc-12 gcc-11 gcc clang cc; do
  [ -n "$cand" ] || continue
  command -v "$cand" >/dev/null 2>&1 || continue
  if "$cand" -std=gnu99 -o /tmp/tycho_cc_probe.out "$probe" >/dev/null 2>&1; then
    chosen="$cand"
    break
  fi
done
rm -f "$probe" /tmp/tycho_cc_probe.out
if [ -z "$chosen" ]; then
  echo "ERROR: no C99-capable compiler found. Install gcc-12+ or clang." >&2
  exit 1
fi
resolved=$(command -v "$chosen")
mkdir -p .toolchain
ln -sf "$resolved" .toolchain/cc
ln -sf "$resolved" .toolchain/gcc
for tool in ar as ld nm objcopy objdump ranlib strip; do
  if command -v "$tool" >/dev/null 2>&1; then
    ln -sf "$(command -v "$tool")" ".toolchain/$tool"
  fi
done
echo "  cc/gcc -> $resolved (+ binutils)"

echo "== checking native dependencies =="
missing=0
check() {
  if eval "$2" >/dev/null 2>&1; then
    echo "  ok       $1"
  else
    echo "  MISSING  $1  ->  $3"
    missing=1
  fi
}
check "Vulkan loader (libvulkan.so.1)" "ldconfig -p | grep libvulkan.so.1 >/dev/null" "sudo apt install libvulkan1 mesa-vulkan-drivers"
check "Xlib headers (tycho_window)" "test -f /usr/include/X11/Xlib.h" "sudo apt install libx11-dev"
check "glslangValidator (tycho_shader)" "command -v glslangValidator" "install Vulkan SDK or sudo apt install glslang-tools"
check "vendored Vulkan headers" "test -f vulkan/include/vulkan/vulkan_core.h" "committed in vulkan/include/vulkan"
check "vendored vk.xml" "test -f codegen/registry/vk.xml" "committed in codegen/registry"

if [ $# -ge 1 ]; then
  mkdir -p third_party
  ln -sfn "$1" third_party/slang
  echo "  third_party/slang -> $1"
fi

if [ "$missing" -ne 0 ]; then
  echo "Some dependencies are missing; install them and re-run." >&2
  exit 1
fi
echo "Ready. Build with ./build.sh"
