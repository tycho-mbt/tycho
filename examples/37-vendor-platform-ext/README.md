# 37-vendor-platform-ext

Example 37 — Vendor, platform, and non-advertised desktop Vulkan commands.

Verifies MoonBit dispatch bindings and type-checking for all vendor/platform
extensions gated by vkGetDeviceProcAddr / vkGetInstanceProcAddr checks.

## Windowing

This example runs headless (offscreen compute/graphics/API verification) and does not open a window.

## Run

```bash
./build.sh
./_build/native/debug/build/laplaceliu/tycho_vulkan_examples/37-vendor-platform-ext/37-vendor-platform-ext.exe
```

## Output

```text
[37-vendor] commands=149 errors=0
[37-vendor] OK — 149 vendor/platform commands type-checked & gated, 0 validation errors
```
