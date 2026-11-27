# rhi/dx12-uniform

A uniform slot on the DX12 backend — the counterpart of `rhi/uniform`, and the first
cross-backend slice built on the **one Slang source, two artifacts** decision.

## What it proves

| Piece | Detail |
|---|---|
| Shader artifacts | `shader.slang` is compiled by `tools/gen-dual-shaders.py` into **SPIR-V** (Vulkan) and **DXIL** (DX12); both are committed in `shader_artifacts.mbt`, so no shader compiler is needed at build or run time |
| Binding mapping | the uniform block is declared once as `[[vk::binding(0, 0)]]` **and** `register(b0, space0)`; the RHI maps uniform slot 0 to descriptor set 0 / binding 0 on Vulkan and root CBV 0 on DX12 |
| Uniform upload | `Device::create_buffer(16, BufferKind::Uniform)` allocates a persistently mapped UPLOAD-heap buffer; `upload_floats` writes it; `bind_uniform` records `SetGraphicsRootConstantBufferView` — no descriptor heap involved |
| Clip space | the DX12 backend draws with a **negative viewport height** and flips `FrontCounterClockwise` with it, so Vulkan-authored clip space and winding carry over unchanged (`docs/original-design/03-dx12.md` §6.1 item 2) |

## Screenshot

![rhi/dx12-uniform screenshot](./screenshot.png)

## Run

```powershell
moon build --target native examples/rhi/dx12-uniform
.\_build\native\debug\build\laplaceliu\tycho_vulkan_examples\rhi\dx12-uniform\dx12-uniform.exe
```

Expected:

```
[rhi/dx12-uniform] OK — uniform slot tinted the DX12 triangle (centre=(51, 204, 102), 3 frames, 0 validation errors)
```

`TYCHO_DX12_WARP=1` forces WARP; `--window` keeps presenting until the window closes;
`--screenshot <path>` writes the verified frame as PNG. Non-Windows hosts report `SKIP`.

The backend has no offscreen render-target path yet, so unlike `rhi/uniform` this example is
windowed-only; `09` stays the headless Vulkan gate.

## Regenerate the shader artifacts

```bash
python tools/gen-dual-shaders.py          # writes shader_artifacts.mbt
python tools/gen-dual-shaders.py --check  # drift gate (needs slangc)
```
