# 74-dx12-triangle

Verifies `laplaceliu/tycho_dx12` end to end on Windows: device creation, a command list, a graphics
PSO built from embedded DXIL, an offscreen RGBA8 render target, and a `COPY_SOURCE -> READBACK`
copy whose pixels are asserted from pure MoonBit.

The triangle comes from `SV_VertexID` (no vertex buffer) with per-vertex colors, so a passing run
proves vertex fetch, rasterization, barycentric interpolation, the RTV binding and the readback
path all work. The center of a cleared corner is checked against the clear color, and one sample
near each vertex must be dominated by that vertex's channel.

## Run

```powershell
moon build --target native examples/74-dx12-triangle
.\_build\native\debug\build\laplaceliu\tycho_vulkan_examples\74-dx12-triangle\74-dx12-triangle.exe

# Software adapter (GPU-less runners, CI):
$env:TYCHO_DX12_WARP = "1"
.\_build\native\debug\build\laplaceliu\tycho_vulkan_examples\74-dx12-triangle\74-dx12-triangle.exe
```

Expected (default is headless offscreen verification, so it runs on a CI runner):

```
[74-dx12-triangle] OK — D3D12 offscreen triangle (128x128, 1 frame(s), adapter=hardware, shader model 6.7, clear + 3 vertex regions verified, 0 validation errors)
[74-dx12-triangle] SKIP — d3d12.dll / dxgi.dll not loadable on this host        # non-Windows
```

Add `--window` (or set `TYCHO_WINDOW=1`) to present the same triangle in a 480x320 Win32 window
through a DXGI flip-model swapchain; close the window to exit. Add `--screenshot <path>` (or set
`TYCHO_SCREENSHOT`) to write the verified frame as PNG — the file is taken from whichever path ran,
so `--window --screenshot out.png` captures a presented back buffer.

## Shaders

`shaders.hlsl` is compiled to DXIL by `tools/gen-dx12-shaders.py` into the committed
`shaders_dxil.mbt` (SM 6.0), so neither the build nor CI needs `dxc`. Regenerate with:

```bash
python tools/gen-dx12-shaders.py          # writes shaders_dxil.mbt
python tools/gen-dx12-shaders.py --check  # drift gate
```

The vertex output struct declares the inter-stage semantic (`TEXCOORD0`) **before** `SV_Position`
on purpose: vertex-stage output registers are packed in declaration order while pixel-stage inputs
always start at register 0, so the other order produces a PSO creation failure
(`Signatures between stages are incompatible`).
