# 36-video-cuda-decomp

Example 36 — Copy Memory Indirect (NV/KHR), Memory Decompression (EXT/NV),

Cooperative Vector NV, Optical Flow NV, CUDA Kernel Launch, and Video Queue.

## Windowing

This example runs headless (offscreen compute/graphics/API verification) and does not open a window.

## Pass criteria

`OK` requires at least one executed command. On a driver that lacks every
extension this batch targets (for example `lavapipe`), the example prints
`SKIP` (exit 0) instead of a vacuous `OK`; if the driver advertises a group but
none of its commands run, it prints `FAIL`.

## Run

```bash
./build.sh
./_build/native/debug/build/laplaceliu/tycho_vulkan_examples/36-video-cuda-decomp/36-video-cuda-decomp.exe
```

## Output

```text
[36-vcd] commands=1 copied=0x305419896 errors=0
[36-vcd] OK — 1 indirect-copy/video/cuda/decomp commands verified, 0 validation errors
```
