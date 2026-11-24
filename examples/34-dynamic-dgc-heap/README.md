# 34-dynamic-dgc-heap

Example 34 — Extended Dynamic State 3 (NV dynamic states), Shading Rate Image NV,

Mesh Shader NV, Maintenance10 EndRendering2, Descriptor Buffer Embedded Samplers,
Descriptor Heap EXT, and Device Generated Commands NV/Compute.

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
./_build/native/debug/build/laplaceliu/tycho_vulkan_examples/34-dynamic-dgc-heap/34-dynamic-dgc-heap.exe
```

## Output

```text
[34-dgc] commands=13 errors=0
[34-dgc] OK — 13 dynamic-state/embedded-sampler/maintenance10 commands verified, 0 validation errors
```
