# vulkan/setup

Example 01 — Setup (following vulkan-tutorial.com/Drawing_a_triangle/Setup).

Instance + validation layers + physical device + queue families + logical device.
Pure MoonBit generated binding; validation messages go to stderr.

## Windowing

This example runs headless (offscreen compute/graphics/API verification) and does not open a window.

## Run

```bash
./build.sh
./_build/native/debug/build/laplaceliu/tycho_vulkan_examples/vulkan/setup/setup.exe
```

## Output

```text
[vulkan/setup] vkCreateInstance = 0 (0=VK_SUCCESS)
[vulkan/setup] physical devices = 3, picked first
[vulkan/setup] queue families = 6, graphics family = 0
[vulkan/setup] vkCreateDevice = 0, graphics queue retrieved
[vulkan/setup] OK — setup chapter validated
```
