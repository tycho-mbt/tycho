# 33-wsi-display

Example 33 — Extended WSI, Swapchain Maintenance1, Present Wait/Timing,

Display/DRM properties, and NVIDIA Low Latency 1/2 commands.

## Windowing

This example creates a native X11 window and `VkSurfaceKHR` transiently to verify WSI, swapchain maintenance, present timing, and low-latency commands, then closes without a presentation loop.

## Run

```bash
./build.sh
./_build/native/debug/build/laplaceliu/tycho_vulkan_examples/33-wsi-display/33-wsi-display.exe
```

## Output

```text
[33-wsi] commands=17 sw=0 errors=0
[33-wsi] OK — 17 WSI/display/latency commands verified, 0 validation errors
```
