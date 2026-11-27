# vulkan/transform-feedback

Example 31 — Transform Feedback + Local Read + Extended Dynamic State batch.

Covers vkCmdBindTransformFeedbackBuffersEXT, vkCmdBeginTransformFeedbackEXT,
vkCmdEndTransformFeedbackEXT, vkCmdDrawIndirectByteCountEXT,
vkCmdSetRenderingInputAttachmentIndices[KHR], vkCmdSetDepthClampRangeEXT,
vkCmdSetDepthBias2EXT, vkCmdSetSampleLocationsEXT,
vkCmdSetAttachmentFeedbackLoopEnableEXT, vkCmdBindShadersEXT.

## Windowing

This example runs headless (offscreen compute/graphics/API verification) and does not open a window.

## Run

```bash
./build.sh
./_build/native/debug/build/laplaceliu/tycho_vulkan_examples/vulkan/transform-feedback/transform-feedback.exe
```

## Output

```text
[31-tf] commands=10 pipe=0 submit=0 wait=0 tf_ok=true errors=0
[31-tf] OK — 10 transform-feedback/local-read/state commands verified, 0 validation errors
```
