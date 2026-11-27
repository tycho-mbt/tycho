# vulkan/vendor-platform-ext

Example 37 — Vendor, platform, and non-advertised desktop Vulkan commands.

Verifies MoonBit dispatch bindings and type-checking for all vendor/platform
extensions gated by vkGetDeviceProcAddr / vkGetInstanceProcAddr checks.

## Windowing

This example runs headless (offscreen compute/graphics/API verification) and does not open a window.

## Pass criteria

`commands` counts only commands actually invoked. The 148 vendor commands behind
the `run_vendor` guard are compile-time type-checked and reported separately as
`typechecked`, so they can never inflate runtime coverage. A driver where nothing
can be invoked reports `SKIP` instead of a vacuous `OK`.

## Run

```bash
./build.sh
./_build/native/debug/build/laplaceliu/tycho_vulkan_examples/vulkan/vendor-platform-ext/vendor-platform-ext.exe
```

## Output

```text
[37-vendor] commands=0 typechecked=148 errors=0
[37-vendor] SKIP — 0 vendor/platform commands invoked on this driver (148 type-checked only)
```

When the unadvertised `vkGetExternalComputeQueueDataNV` probe resolves, one
runtime command is invoked and the example reports
`OK — 1 runtime + 148 type-checked vendor/platform commands`.
