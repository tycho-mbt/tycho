# 39-rhi-msaa-offscreen

Offscreen 4x MSAA dynamic render pass (`begin_render_pass` / `end_render_pass`) with automatic resolve into a single-sample `RGBA8` texture, verified via readback for intermediate anti-aliased coverage pixels and presented to the swapchain.

## Run

```bash
./build.sh
./_build/native/debug/build/laplaceliu/tycho_vulkan_examples/39-rhi-msaa-offscreen/39-rhi-msaa-offscreen.exe
```

## Screenshot

![39-rhi-msaa-offscreen screenshot](./screenshot.png)

> Runs headless by default for automated verification. Pass `--window` (or `TYCHO_WINDOW=1`) to render on screen.
