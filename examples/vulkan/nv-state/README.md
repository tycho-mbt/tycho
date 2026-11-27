# vulkan/nv-state

Example 29 — the small NVIDIA-only dynamic state families: exclusive

scissor, viewport W scaling, the AMD buffer marker and the compute
occupancy priority. Fifteenth coverage batch. The marker value is read
back so the command has to have written it.

## Windowing

This example runs headless (offscreen compute/graphics/API verification) and does not open a window.

## Run

```bash
./build.sh
./_build/native/debug/build/laplaceliu/tycho_vulkan_examples/vulkan/nv-state/nv-state.exe
```

## Output

```text
[29-nv] commands=5 marker=true submit=0 wait=0 errors=0
[29-nv] OK — 5 NVIDIA state commands, marker value verified
```
