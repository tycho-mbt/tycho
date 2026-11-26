# 78-dx12-depth

Offscreen render target + depth test on the DX12 backend, headless — the first DX12 example that
does not need a window, so it can run on a CI runner.

## What it proves

| Piece | Detail |
|---|---|
| Offscreen target | `Device::create_render_target` allocates a `DEFAULT`-heap RGBA8 texture with its own RTV; the RHI records it through `Device::begin_commands` / `begin_render_pass` / `end_render_pass` |
| Depth | `Device::create_depth_texture` allocates `D32_FLOAT` with a DSV heap; the PSO gets `DepthEnable` + `LESS_EQUAL` + a write mask, and the draw binds RTV and DSV together |
| Readback | `Texture::readback()` records a throwaway command list, transitions to `CopySource`, copies into a `READBACK` buffer and repacks the padded rows |
| Depth semantics | the same triangle is drawn twice at z=0.75 (red) and z=0.25 (green) with two uniform buffers. Green wins **in both draw orders** — the result depends on depth, not on submission order. With depth off, the second draw would paint over the first and one of the two runs would come back red |

## Screenshot

![78-dx12-depth screenshot](./screenshot.png)

## Run

```powershell
moon build --target native examples/78-dx12-depth
.\_build\native\debug\build\laplaceliu\tycho_vulkan_examples\78-dx12-depth\78-dx12-depth.exe
```

Expected:

```
[78-dx12-depth] OK — offscreen RGBA8 + Depth32F, nearer fragment wins in both draw orders (far-first=(25, 204, 76), near-first=(25, 204, 76), 0 validation errors)
```

`TYCHO_DX12_WARP=1` forces WARP (same result); `--screenshot <path>` writes the verified frame.
Non-Windows hosts report `SKIP`.

## Regenerate the shader artifacts

```bash
python tools/gen-dual-shaders.py          # SPIR-V + DXIL from shader.slang
python tools/gen-dual-shaders.py --check  # drift gate (needs slangc)
```
