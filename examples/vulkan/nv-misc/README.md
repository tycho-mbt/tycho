# vulkan/nv-misc

Example 28 — NVIDIA-only query and handle families: device fault info,

calibrated timestamps, diagnostic checkpoints, shader module identifiers,
NVX image view handles, DRM format modifier properties and the POSIX fd
import/export of fences and semaphores. Fourteenth coverage batch.
On a driver without the NVIDIA extensions the example reports SKIP.

## Windowing

This example runs headless (offscreen compute/graphics/API verification) and does not open a window.

## Run

```bash
./build.sh
./_build/native/debug/build/laplaceliu/tycho_vulkan_examples/vulkan/nv-misc/nv-misc.exe
```

## Output

```text
[28-nv] commands=13 coop=true of=true ts=true ident=true handle=true addr=0 combined=5242884 fd=true imp=0 sem=true imps=0 errors=0
[28-nv] OK — 13 NVIDIA-family commands, handles and fds verified
```
