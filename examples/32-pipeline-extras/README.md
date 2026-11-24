# 32-pipeline-extras

Example 32 — Pipeline Executable Properties, Pipeline Binary, Descriptor Buffer

Image Capture Data, Buffer Device Address EXT, Host Image Copy EXT, and
NVIDIA Cooperative Matrix 2 / Copy Memory Indirect queries.

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
./_build/native/debug/build/laplaceliu/tycho_vulkan_examples/32-pipeline-extras/32-pipeline-extras.exe
```

## Output

```text
[32-pipe] commands=12 pipe=0 errors=0
[32-pipe] OK — 12 pipeline/descriptor-buffer/address commands verified, 0 validation errors
```
