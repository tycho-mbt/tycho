# 58 — coverage atlas quality gate

Renders 300 procedural icon paths (concave stars, EvenOdd rings, rounded
squares) at 1920x1080 twice:

1. through the CPU coverage atlas (one batched draw, zero MSAA passes);
2. through the per-path 4x MSAA fallback.

The two images are compared with a windowed 8x8 SSIM and the gate requires
SSIM >= 0.98, coverage draws == icon count, and zero validation errors.

## Run

```sh
cd tycho/examples
moon build --target native 58-tycho-2d-svg-icons
./_build/native/debug/build/laplaceliu/tycho_vulkan_examples/58-tycho-2d-svg-icons/58-tycho-2d-svg-icons.exe
```

Sample output on NVIDIA:

```json
{"ssim":0.9979281441423402,"coverage_draws":300,"coverage_passes":0,"msaa_passes":40,"coverage_draw_calls":2,"msaa_draw_calls":1}
[58-tycho-2d-svg-icons] OK — SSIM=0.9979, coverage 300 icons / 0 passes, MSAA 40 passes, 0 validation errors
```
