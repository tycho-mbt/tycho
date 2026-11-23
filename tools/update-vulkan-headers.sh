#!/usr/bin/env bash
# Sync vendored Vulkan headers and vk.xml from a local Vulkan SDK installation.
# Usage: ./tools/update-vulkan-headers.sh /path/to/VulkanSDK/<ver>/x86_64
set -euo pipefail
cd "$(dirname "$0")/.."

if [ $# -lt 1 ]; then
  echo "Usage: $0 <vulkan-sdk-arch-dir> (e.g. /home/laplaceliu/VulkanSDK/1.4.363.1/x86_64)" >&2
  exit 1
fi
SDK="$1"
mkdir -p vulkan/include/vulkan codegen/registry

for h in vk_platform.h vulkan.h vulkan_core.h vulkan_beta.h \
         vulkan_xlib.h vulkan_xcb.h vulkan_wayland.h \
         vulkan_win32.h vulkan_metal.h; do
  cp "$SDK/include/vulkan/$h" "vulkan/include/vulkan/$h"
done
rm -rf vulkan/include/vulkan/vk_video
cp -r "$SDK/include/vk_video" vulkan/include/vulkan/vk_video
cp "$SDK/share/vulkan/registry/vk.xml" codegen/registry/vk.xml

grep -E "VK_HEADER_VERSION\b" vulkan/include/vulkan/vulkan_core.h
echo "Updated headers and vk.xml. Run ./generate.sh to regenerate bindings."
