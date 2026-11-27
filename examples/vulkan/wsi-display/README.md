# vulkan/wsi-display

Example 33 — Extended WSI, Swapchain Maintenance1, Present Wait/Timing,

Display/DRM properties, and NVIDIA Low Latency 1/2 commands.

## Windowing

This example creates a native X11 window and `VkSurfaceKHR` transiently to verify WSI, swapchain maintenance, present timing, and low-latency commands, then closes without a presentation loop.

## Pass criteria

`OK` requires at least one executed command. On a driver that lacks every
extension this batch targets (for example `lavapipe`), the example prints
`SKIP` (exit 0) instead of a vacuous `OK`; if the driver advertises a group but
none of its commands run, it prints `FAIL`.

## Run

```bash
./build.sh
./_build/native/debug/build/laplaceliu/tycho_vulkan_examples/vulkan/wsi-display/wsi-display.exe
```

## Output

```text
[33-wsi] commands=17 sw=0 errors=0
[33-wsi] OK — 17 WSI/display/latency commands verified, 0 validation errors
```
