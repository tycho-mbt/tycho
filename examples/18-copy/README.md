# 18-copy

Example 18 — copy / clear / blit / resolve + events + labels + secondary

command buffers (headless, offscreen images). Third execution-coverage batch.
Optional entry points are gated on device-level resolvability; the result is
asserted by reading back a copied pixel, not by return codes alone.

## Windowing

This example runs headless (offscreen compute/graphics/API verification) and does not open a window.

## Run

```bash
./build.sh
./_build/native/debug/build/laplaceliu/tycho_vulkan_examples/18-copy/18-copy.exe
```

## Output

```text
[18-copy] commands=26 resolved=true pixel=50,100,200,255
[18-copy] OK — 26 recording commands, copied pixel verified
```
