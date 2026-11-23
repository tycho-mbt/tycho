# 24-raytracing

Example 24 — ray tracing (VK_KHR_acceleration_structure + ray_tracing_pipeline):

BLAS/TLAS build, ray tracing pipeline, shader binding table, trace rays, and
the host-side build/copy/property variants. Ninth coverage batch.
The ray hits a single triangle; the payload written to the output buffer is
the assertion, so a silently broken AS or SBT cannot pass.

## Windowing

This example runs headless (offscreen compute/graphics/API verification) and does not open a window.

## Run

```bash
./build.sh
./_build/native/debug/build/laplaceliu/tycho_vulkan_examples/24-raytracing/24-raytracing.exe
```

## Output

```text
[24-rt] commands=17 hit=1 submit=0 wait=0 errors=0
[24-rt] OK — 17 ray tracing commands, ray hit the triangle (payload=1)
```
