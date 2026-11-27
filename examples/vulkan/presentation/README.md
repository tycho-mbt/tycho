# vulkan/presentation

Example 02 — Presentation (vulkan-tutorial.com/Drawing_a_triangle/Presentation).

X11 window surface + swap chain + image views. Pure MoonBit (no C stub).

## Windowing

This example creates a native X11 window and `VkSurfaceKHR` transiently to verify WSI/swapchain setup and closes immediately without a presentation loop.

## Run

```bash
./build.sh
./_build/native/debug/build/laplaceliu/tycho_vulkan_examples/vulkan/presentation/presentation.exe
```

## Output

```text
[02-present] instance=0 device=0
[02-present] vkCreateSwapchainKHR = 0
[02-present] swapchain images = 3, image views created = 3
[02-present] OK — presentation chapter validated
```
