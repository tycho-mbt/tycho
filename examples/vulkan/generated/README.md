# vulkan/generated

Example 25 — VK_EXT_device_generated_commands: an indirect execution set plus

an indirect commands layout, preprocessed and executed on the device. Eleventh
coverage batch. The compute result is the assertion.
The preprocess pass and the execute pass are two separate submissions joined
by a semaphore. One submission carrying both deadlocks the NVIDIA queue
(the fence times out and the device never idles); the split form runs on
both lavapipe and NVIDIA.

## Windowing

This example runs headless (offscreen compute/graphics/API verification) and does not open a window.

## Run

```bash
./build.sh
./_build/native/debug/build/laplaceliu/tycho_vulkan_examples/vulkan/generated/generated.exe
```

## Output

```text
[25-gen] commands=8 v0=11 v7=11 submit=0/0 wait=0 errors=0
[25-gen] OK — 8 generated-command commands, compute result verified
```
