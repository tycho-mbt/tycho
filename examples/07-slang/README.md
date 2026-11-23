# 07-slang

Example 07 — Slang shader triangle (compile_slang via bundled official slangc).

Pure MoonBit binding. Verifies rendering by reading back rendered pixels.

## Window Screenshot

![07-slang window screenshot](./screenshot.png)

## Run

```bash
./build.sh
./_build/native/debug/build/laplaceliu/tycho_vulkan_examples/07-slang/07-slang.exe
```

## Output

```text
[07-slang] instance=0 device=0
[07-slang] graphics pipeline = 0
[07-slang] acquire=0 submit=0 rendered pixels=60000/480000
[07-slang] present=0 (0=VK_SUCCESS)
[07-slang] OK — triangle rendered (60000 non-zero pixels) and presented
```
