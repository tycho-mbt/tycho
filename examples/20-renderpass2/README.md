# 20-renderpass2

Example 20 — render pass 2, queries, conditional rendering, push descriptors.

Fifth execution-coverage batch (headless offscreen). The pass/fail gate counts
validation errors via the generated debug messenger, not just return codes.

## Windowing

This example runs headless (offscreen compute/graphics/API verification) and does not open a window.

## Run

```bash
./build.sh
./_build/native/debug/build/laplaceliu/tycho_vulkan_examples/20-renderpass2/20-renderpass2.exe
```

## Output

```text
[20-rp2] commands=20 submit=0 wait=0 pixels=512 errors=0
[20-rp2] OK — 20 renderpass2/query/push-descriptor commands, 512 pixels, 0 validation errors
```
