# vulkan/indirect

Example 27 — the indirect draw family: vkCmdDrawIndirect,

vkCmdDrawIndexedIndirect, both Count variants and vkCmdBindIndexBuffer2.
Thirteenth coverage batch. Each draw command renders into its own image and
the pixels are counted, so a silently ignored draw fails the gate.

## Windowing

This example runs headless (offscreen compute/graphics/API verification) and does not open a window.

## Run

```bash
./build.sh
./_build/native/debug/build/laplaceliu/tycho_vulkan_examples/vulkan/indirect/indirect.exe
```

## Output

```text
[27-ind] commands=6 red=16384 submit=0 wait=0 errors=0
[27-ind] OK — 6 indirect draw commands, geometry rendered
```
