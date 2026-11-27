# dx12/mrt

Multiple sampled textures and multiple render targets on the DX12 backend.

## What it proves

| Piece | Detail |
|---|---|
| Texture slots | `texture_slots = 2` gives one single-descriptor root table per slot (`t0`, `t1`), so each texture binds its own heap entry instead of requiring a contiguous descriptor range. Slot 0 receives texture A, slot 1 texture B |
| MRT | the pipeline declares two RTV formats, `begin_render_pass` binds both targets (`OMSetRenderTargets` with two handles), and the fragment writes `SV_Target0` / `SV_Target1` |
| sRGB format | the second target is `RGBA8Srgb`. Writing linear `0.5` stores `188`, while the same value in the linear target stays `128` — the byte pattern itself proves the DXGI format reached the RTV and the PSO |
| Formats | four-byte colour formats (RGBA8 / BGRA8 and their sRGB variants) are accepted by both the upload and the render-target paths; the mapping lives in `dx12_stub.c` so no numeric DXGI value leaks into MoonBit |

## Screenshot

![dx12/mrt screenshot](./screenshot.png)

(The screenshot is the linear target: the colour of texture A.)

## Run

```powershell
moon build --target native examples/dx12/mrt
.\_build\native\debug\build\laplaceliu\tycho_vulkan_examples\dx12\mrt\mrt.exe
```

Expected:

```
[dx12/mrt] OK — two texture slots + MRT (linear=(64, 128, 191), srgb=(188, 188, 188), 0 validation errors)
```

`TYCHO_DX12_WARP=1` forces WARP; `--screenshot <path>` writes the linear target as PNG.
