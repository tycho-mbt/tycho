# 35-nv-rt-micromap

Example 35 — NVIDIA Ray Tracing (VK_NV_ray_tracing), Opacity Micromap

(VK_EXT_opacity_micromap), Cluster AS NV, and Partitioned AS NV.

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
./_build/native/debug/build/laplaceliu/tycho_vulkan_examples/35-nv-rt-micromap/35-nv-rt-micromap.exe
```

## Output

```text
[35-nvrt] commands=9 errors=0
[35-nvrt] OK — 9 NV RT & opacity micromap commands verified, 0 validation errors
```
