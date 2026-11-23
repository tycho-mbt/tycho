# 26-core-gaps

Example 26 — core surface gaps: instance queries, sparse binding, buffer

views, indirect dispatch and the copy-commands2 pair. Twelfth coverage batch.
Every step asserts on data, not on return codes alone.

## Windowing

This example runs headless (offscreen compute/graphics/API verification) and does not open a window.

## Run

```bash
./build.sh
./_build/native/debug/build/laplaceliu/tycho_vulkan_examples/26-core-gaps/26-core-gaps.exe
```

## Output

```text
[26-core] commitment=0 lazy_type=-1
[26-core] commands=9 version=4211051 layers=12 proc=true sparse=true view=true dispatch=true disp7=49 pixel=true commit=true submit=0 wait=0 errors=0
[26-core] OK — 9 core-surface commands, sparse/dispatch/copy verified
```
