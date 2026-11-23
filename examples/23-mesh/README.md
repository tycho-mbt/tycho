# 23-mesh

Example 23 — mesh shaders (VK_EXT_mesh_shader): no vertex input, no input

assembly; the mesh stage emits primitives directly. Covers direct, indirect
and indirect-count mesh draws. Eighth coverage batch.

## Windowing

This example runs headless (offscreen compute/graphics/API verification) and does not open a window.

## Run

```bash
./build.sh
./_build/native/debug/build/laplaceliu/tycho_vulkan_examples/23-mesh/23-mesh.exe
```

## Output

```text
[23-mesh] commands=3 pixels=512 submit=0 wait=0 errors=0
[23-mesh] OK — 3 mesh draw commands, 512 pixels, 0 validation errors
```
