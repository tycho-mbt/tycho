# vulkan/wsi-queries

Example 30 — WSI & Swapchain extended queries/control batch.

Covers surface support/present-modes/capabilities2/formats2, device-group
present capabilities/modes/rectangles, AcquireNextImage2KHR, HDR metadata,
swapchain status, and present-wait / release-swapchain-images when supported.

## Windowing

This example creates a native X11 window and `VkSurfaceKHR` transiently to verify WSI/swapchain setup and closes immediately without a presentation loop.

## Run

```bash
./build.sh
./_build/native/debug/build/laplaceliu/tycho_vulkan_examples/vulkan/wsi-queries/wsi-queries.exe
```

## Output

```text
[30-wsi] commands=11 support=0/1 pms=0 sw=0 acq2=0 errors=0
[30-wsi] OK — 11 WSI/swapchain commands verified, 0 validation errors
```
