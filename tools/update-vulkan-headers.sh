#!/usr/bin/env bash
# Sync vendored Vulkan headers and vk.xml from a local Vulkan SDK installation.
#
# Usage: ./tools/update-vulkan-headers.sh [--add-headers] /path/to/VulkanSDK/<ver>/x86_64
#
# Default policy: refresh the header set this package already vendors (contents
# follow the SDK) and *report* headers the SDK newly ships. Adopting new platform
# headers changes the compilable command surface, which is also the denominator
# used by tools/coverage.py, so it stays an explicit decision: --add-headers.
set -euo pipefail
cd "$(dirname "$0")/.."

add_headers=0
if [ "${1:-}" = "--add-headers" ]; then
  add_headers=1
  shift
fi

if [ $# -lt 1 ]; then
  echo "Usage: $0 [--add-headers] <vulkan-sdk-arch-dir> (e.g. \$VULKAN_SDK, i.e. …/VulkanSDK/<ver>/x86_64)" >&2
  exit 1
fi
SDK="$1"

for req in "$SDK/include/vulkan" "$SDK/include/vk_video" "$SDK/share/vulkan/registry/vk.xml"; do
  if [ ! -e "$req" ]; then
    echo "ERROR: $req not found — pass the SDK's <arch> directory (…/VulkanSDK/<ver>/x86_64)." >&2
    exit 1
  fi
done

# The include closure of vulkan.h: itself plus every `#include "vulkan_*.h"`
# behind its VK_USE_PLATFORM_* guards. Deriving it keeps the check correct when
# upstream adds or renames a platform header (vulkan_ohos.h arrived in 1.4).
closure=$(
  {
    echo vulkan.h
    grep -o '#include "\(vk_platform\|vulkan_[a-z0-9_]*\)\.h"' "$SDK/include/vulkan/vulkan.h" \
      | sed -e 's/^#include "//' -e 's/"$//'
  } | sort -u
)
if [ -z "$closure" ]; then
  echo "ERROR: could not derive the header closure from $SDK/include/vulkan/vulkan.h" >&2
  exit 1
fi

# vulkan.h references headers the SDK itself does not ship for unsupported
# platforms (vulkan_sci.h). Those includes are guarded, so ignore them.
available=""
unavailable=""
for h in $closure; do
  if [ -f "$SDK/include/vulkan/$h" ]; then
    available="$available $h"
  else
    unavailable="$unavailable $h"
  fi
done
if [ -n "$unavailable" ]; then
  echo "Not shipped by this SDK (guarded in vulkan.h, ignored):$unavailable"
fi

mkdir -p vulkan/include/vulkan codegen/registry
old_list=$(find vulkan/include/vulkan -maxdepth 1 -name '*.h' -printf '%f\n' | sort)

# A header we vendor disappearing upstream means vk.xml/macros moved: that needs
# a human, because codegen/main.mbt reads specific filenames.
dropped=""
for h in $old_list; do
  if [ ! -f "$SDK/include/vulkan/$h" ]; then
    dropped="$dropped $h"
  fi
done
if [ -n "$dropped" ]; then
  echo "ERROR: these vendored headers no longer exist in the SDK:$dropped" >&2
  echo "       Update the header reads in codegen/main.mbt, then re-run." >&2
  exit 1
fi

# Refresh contents of what we already vendor (and drop stale .h files first so a
# rename cannot leave a shadow copy behind).
find vulkan/include/vulkan -maxdepth 1 -name '*.h' -delete
for h in $old_list; do
  cp "$SDK/include/vulkan/$h" vulkan/include/vulkan/
done

# New upstream headers are reported, not adopted silently.
new_headers=$(for h in $available; do
  case " $(echo $old_list) " in
    *" $h "*) ;;
    *) echo "$h" ;;
  esac
done)
if [ -n "$new_headers" ]; then
  if [ "$add_headers" -eq 1 ]; then
    echo "Adopting headers newly shipped by the SDK:"
    echo "$new_headers" | sed 's/^/  + /'
    for h in $new_headers; do
      cp "$SDK/include/vulkan/$h" vulkan/include/vulkan/
    done
  else
    echo "Headers newly shipped by the SDK (not vendored):"
    echo "$new_headers" | sed 's/^/  + /'
    echo "  -> re-run with --add-headers to vendor them, or add a VK_USE_PLATFORM_*"
    echo "     entry to codegen/main.mbt if they are needed by a new backend."
  fi
fi

rm -rf vulkan/include/vulkan/vk_video
cp -r "$SDK/include/vk_video" vulkan/include/vulkan/vk_video
cp "$SDK/share/vulkan/registry/vk.xml" codegen/registry/vk.xml

# codegen/main.mbt reads a fixed set of headers to build its "is this type
# available in the build" set and its platform guards. A rename or removal there
# must be mirrored in the generator, so fail early with a readable message
# instead of producing bindings with silently missing accessors.
generator_headers="vulkan.h vulkan_core.h vulkan_beta.h vulkan_xlib.h vulkan_xcb.h \
vulkan_wayland.h vulkan_win32.h vulkan_metal.h"
missing=0
for h in $generator_headers; do
  if [ ! -f "vulkan/include/vulkan/$h" ]; then
    echo "  MISSING header read by codegen: $h" >&2
    missing=1
  fi
done
if [ ! -f "vulkan/include/vulkan/vk_video/vulkan_video_codec_h264std.h" ]; then
  echo "  MISSING vk_video/ headers (vulkan_core.h includes them)" >&2
  missing=1
fi
if [ "$missing" -ne 0 ]; then
  echo "Update the header list in codegen/main.mbt before running ./generate.sh." >&2
  exit 1
fi

grep -E "VK_HEADER_VERSION\b" vulkan/include/vulkan/vulkan_core.h
echo "Vendored $(find vulkan/include/vulkan -maxdepth 1 -name '*.h' | wc -l) headers + codegen/registry/vk.xml."
echo "Run ./generate.sh to regenerate bindings."
