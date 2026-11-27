# dx12/compute

Compute + storage image on the DX12 backend — the counterpart of
`rhi/compute-storage-image`, rendered headless.

## What it proves

| Piece | Detail |
|---|---|
| UAV | `Device::create_storage_texture` allocates a `DEFAULT`-heap RGBA8 texture with `ALLOW_UNORDERED_ACCESS`, starting in `UNORDERED_ACCESS`, and takes a slot in the same shader-visible heap the SRVs use |
| Compute pipeline | its **own** root signature (root CBVs, then one UAV table `u0..u(n-1)` in space 0) and `CreateComputePipelineState` |
| Dispatch | `Dispatch` goes through `SetComputeRootSignature` / `SetComputeRootDescriptorTable`, which are a different set of D3D12 calls from the graphics ones — hence `set_compute_pipeline` rather than `set_pipeline` |
| Result | the shader writes `float4(x/64, y/64, 0.5, 1)`, so origin / centre / far corner pin the whole gradient and `SV_DispatchThreadID` mapping |

`create_compute_pipeline_auto` (SPIR-V reflection) raises `BackendUnsupported` on DX12: a DXIL
container carries no reflection data, so the slot counts are passed explicitly to
`create_compute_pipeline`.

## Screenshot

![dx12/compute screenshot](./screenshot.png)

## Run

```powershell
moon build --target native examples/dx12/compute
.\_build\native\debug\build\laplaceliu\tycho_vulkan_examples\dx12\compute\compute.exe
```

Expected:

```
[dx12/compute] OK — compute wrote a 64x64 UAV (origin=(0, 0, 127), centre=(127, 127, 127), far=(251, 251, 127), 0 validation errors)
```

`TYCHO_DX12_WARP=1` forces WARP; `--screenshot <path>` writes the UAV as PNG. Non-Windows hosts
report `SKIP`.

## Regenerate the shader artifacts

```bash
python tools/gen-dual-shaders.py          # SPIR-V + DXIL from shader.slang
python tools/gen-dual-shaders.py --check  # drift gate (needs slangc)
```
