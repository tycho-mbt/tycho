#!/usr/bin/env bash
# Prepare a Linux development environment for Tycho.
# Usage: ./setup-linux.sh [path-to-slang-release]
set -euo pipefail
cd "$(dirname "$0")"

TMP="${TMPDIR:-/tmp}"

# Resolve executables on PATH while ignoring our own .toolchain directory.
# build.sh puts .toolchain first on PATH, so a second run of this script would
# otherwise resolve "as" to .toolchain/as and create a self-referential symlink
# ("too many levels of symbolic links").
resolve_tool() {
  local name="$1" dir
  local IFS=:
  for dir in $PATH; do
    [ -n "$dir" ] || continue
    [ "$dir" = "$PWD/.toolchain" ] && continue
    if [ -f "$dir/$name" ] && [ -x "$dir/$name" ]; then
      printf '%s\n' "$dir/$name"
      return 0
    fi
  done
  return 1
}

# Drop the generated toolchain first: if a previous run left broken symlinks
# (e.g. as -> .toolchain/as), they sit first on PATH and poison every compiler
# probe below.
rm -rf .toolchain

echo "== picking a C99-capable compiler =="
probe=$(mktemp "$TMP/tycho_cc_probe_XXXXXX.c")
printf 'int main(void){for(int i=0;i<1;i++){}return 0;}\n' > "$probe"
chosen=""
for cand in "${TYCHO_CC:-}" gcc-14 gcc-13 gcc-12 gcc-11 gcc clang cc; do
  [ -n "$cand" ] || continue
  cc_path=$(resolve_tool "$cand") || continue
  if "$cc_path" -std=gnu99 -o "$TMP/tycho_cc_probe.out" "$probe" >/dev/null 2>&1; then
    chosen="$cc_path"
    break
  fi
done
rm -f "$probe" "$TMP/tycho_cc_probe.out"
if [ -z "$chosen" ]; then
  echo "ERROR: no C99-capable compiler found. Install gcc-12+ or clang." >&2
  exit 1
fi
resolved="$chosen"
mkdir -p .toolchain
ln -sf "$resolved" .toolchain/cc
ln -sf "$resolved" .toolchain/gcc
for tool in ar as ld nm objcopy objdump ranlib strip; do
  if tool_path=$(resolve_tool "$tool"); then
    ln -sf "$tool_path" ".toolchain/$tool"
  fi
done
echo "  cc/gcc -> $resolved (+ binutils)"

echo "== checking native dependencies =="
# Probe with the chosen compiler instead of hardcoding /usr/include, so the check
# also works on non-FHS prefixes (Nix, /usr/local, custom sysroots).
have_lib() {
  local flag="$1" out
  out=$(mktemp "$TMP/tycho_probe_XXXXXX")
  rm -f "$out"
  if printf 'int main(void){return 0;}\n' | "$resolved" -x c - "$flag" -o "$out" >/dev/null 2>&1; then
    rm -f "$out"
    return 0
  fi
  rm -f "$out"
  return 1
}
have_header() {
  local inc="$1" out
  out=$(mktemp "$TMP/tycho_probe_XXXXXX")
  rm -f "$out"
  if printf '#include <%s>\nint main(void){return 0;}\n' "$inc" \
      | "$resolved" -x c - -o "$out" >/dev/null 2>&1; then
    rm -f "$out"
    return 0
  fi
  rm -f "$out"
  return 1
}

missing=0
check() {
  if eval "$2" >/dev/null 2>&1; then
    echo "  ok       $1"
  else
    echo "  MISSING  $1  ->  $3"
    missing=1
  fi
}
check "Vulkan loader linkable (-lvulkan)" "have_lib -lvulkan" "sudo apt install libvulkan-dev libvulkan1 mesa-vulkan-drivers"
check "Xlib headers + lib (-lX11)" "have_header X11/Xlib.h && have_lib -lX11" "sudo apt install libx11-dev"
check "glslangValidator (tycho_shader)" "resolve_tool glslangValidator" "install Vulkan SDK or sudo apt install glslang-tools"
check "vendored Vulkan headers" "test -f vulkan/include/vulkan/vulkan_core.h" "committed in vulkan/include/vulkan"
check "vendored vk.xml" "test -f codegen/registry/vk.xml" "committed in codegen/registry"

if [ $# -ge 1 ]; then
  mkdir -p third_party
  # Store an absolute target: a relative path would be resolved against
  # third_party/ and produce a dangling link.
  slang_abs=$(cd "$(dirname "$1")" && printf '%s/%s\n' "$PWD" "$(basename "$1")")
  if [ ! -d "$slang_abs" ]; then
    echo "ERROR: $1 is not a directory (expected a Slang release root)." >&2
    exit 1
  fi
  rm -f third_party/slang
  ln -sfn "$slang_abs" third_party/slang
  echo "  third_party/slang -> $slang_abs"
fi

if [ "$missing" -ne 0 ]; then
  echo "Some dependencies are missing; install them and re-run." >&2
  exit 1
fi
echo "Ready. Build with ./build.sh"
