# vulkan/hostcopy

Example 21 — host image copy, deferred host operations, debug report, shader

objects, dispatch base and the sync2 KHR aliases. Sixth coverage batch.
Gate counts validation errors, not just return codes.

## Windowing

This example runs headless (offscreen compute/graphics/API verification) and does not open a window.

## Run

```bash
./build.sh
./_build/native/debug/build/laplaceliu/tycho_vulkan_examples/vulkan/hostcopy/hostcopy.exe
```

## Output

```text
[21-host] commands=27 host_pixel=true compute=true report_msgs=4 errors=0
[21-host] OK — 27 host-copy/deferred/shader-object/dispatch commands verified
```
