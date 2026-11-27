# rhi/dx12-indirect

Indirect draws and timestamp queries on the DX12 backend, headless.

## What it proves

| Piece | Detail |
|---|---|
| Indirect draw | `draw_indexed_indirect` runs `ExecuteIndirect` through an `ID3D12CommandSignature`; the argument buffer is Vulkan's `VkDrawIndexedIndirectCommand` verbatim (20 B: indexCount, instanceCount, firstIndex, vertexOffset, firstInstance), which is byte-identical to `D3D12_DRAW_INDEXED_ARGUMENTS` |
| Command signatures | one signature per argument layout (draw 16 B / draw-indexed 20 B / dispatch 12 B), created lazily and cached on the device |
| Timestamps | `ID3D12QueryHeap` of type `TIMESTAMP` plus a READBACK staging buffer; `write_timestamp` records `EndQuery`, and the resolve is appended by `end_commands` (the only point where every write is recorded and the copy still reaches the GPU) |
| Unsupported calls | a `draw_mesh_tasks` on a DX12 list now fails `end_commands` with `BackendUnsupported("mesh shaders is not implemented…")` instead of silently doing nothing — this example asserts that |

The quad is the same one `81` draws, so an indirect path that dropped arguments would immediately show
wrong pixels; the timestamps must both be non-zero, which proves the query heap and the resolve ran.

## Screenshot

![rhi/dx12-indirect screenshot](./screenshot.png)

## Run

```powershell
moon build --target native examples/rhi/dx12-indirect
.\_build\native\debug\build\laplaceliu\tycho_vulkan_examples\rhi\dx12-indirect\dx12-indirect.exe
```

Expected:

```
[rhi/dx12-indirect] OK — indirect indexed draw + timestamps (centre=(126, 0, 129), 4/4 corners matched, pass=0.004096 ms, unsupported calls rejected, 0 validation errors)
```

`TYCHO_DX12_WARP=1` forces WARP (the pass time then grows by ~50x, which is a useful sanity check that
the timestamps really measure GPU work); `--screenshot <path>` writes the frame as PNG.

## Regenerate the shader artifacts

```bash
python tools/gen-dual-shaders.py          # SPIR-V + DXIL from shader.slang
python tools/gen-dual-shaders.py --check  # drift gate (needs slangc)
```
