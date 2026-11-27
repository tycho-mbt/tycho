# rhi/dx12-advanced

Three DX12 RHI features that were previously missing or rejected, each verified in one run.

## What it proves

| Feature | Detail |
|---|---|
| Push constants | D3D12 has no push constants, so they map to **root constants at `b15, space0`**. Slang would otherwise place `[[vk::push_constant]]` at `cb0` and collide with uniform slot 0, so the shader pins the register (`register(b15, space0)`) and the root signature declares the same slot. The tint exists only in the root-constant block, so the pixel proves the binding |
| Storage buffers | `BufferKind::Storage` allocates a DEFAULT-heap buffer with a raw UAV view (`R32_TYPELESS` + `D3D12_BUFFER_UAV_FLAG_RAW`), bound into the compute UAV table. Reading it back goes through a staging copy because the buffer is not CPU visible |
| GPU-side draw count | `draw_indirect_count` passes an `ID3D12Resource` count buffer to `ExecuteIndirect`: with count 0 nothing is drawn (the clear colour survives), with count 1 the same arguments draw the triangle |
| Sizes | push constants: 16 bytes; storage: 64 floats; args: `D3D12_DRAW_ARGUMENTS` (16 B) |

## Screenshot

![rhi/dx12-advanced screenshot](./screenshot.png)

## Run

```powershell
moon build --target native examples/rhi/dx12-advanced
.\_build\native\debug\build\laplaceliu\tycho_vulkan_examples\rhi\dx12-advanced\dx12-advanced.exe
```

Expected:

```
[rhi/dx12-advanced] OK — push constants tinted (51, 153, 229), GPU count honoured, 64 storage floats read back, 0 validation errors
```

`TYCHO_DX12_WARP=1` forces WARP (the tint then reads exactly `(51, 153, 230)`, the unrounded value);
`--screenshot <path>` writes the push-constant frame as PNG.

## Regenerate the shader artifacts

```bash
python tools/gen-dual-shaders.py          # SPIR-V + DXIL from shader.slang
python tools/gen-dual-shaders.py --check  # drift gate (needs slangc)
```
