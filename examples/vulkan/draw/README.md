# vulkan/draw

Example 19 — dynamic state + draw/dispatch variants (headless offscreen

rendering). Fourth execution-coverage batch. The pipeline's dynamic-state
list is built from the same resolvability test that gates each setter, so a
state is never declared without being set (which would be a VUID violation).

## Windowing

This example runs headless (offscreen compute/graphics/API verification) and does not open a window.

## Run

```bash
./build.sh
./_build/native/debug/build/laplaceliu/tycho_vulkan_examples/vulkan/draw/draw.exe
```

## Output

```text
[vulkan/draw] commands=80 states=50 submit=0 wait=0 pixels=512
[vulkan/draw] OK — 80 draw/state commands, 50 dynamic states, 512 pixels
```
