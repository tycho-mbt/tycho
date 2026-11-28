# dx12/rayquery

Inline ray query (DXR Tier 1.1 / SM 6.5) verification on the DX12 RHI backend.

## What it proves

- `Device::create_blas` + `Device::create_tlas` (passing the BLAS GPU virtual address into `D3D12_RAYTRACING_INSTANCE_DESC::AccelerationStructure`)
- Acceleration-structure SRV (`D3D12_SRV_DIMENSION_RAYTRACING_ACCELERATION_STRUCTURE`) bound at `t0` in a compute pipeline
- `RayQuery<RAY_FLAG_FORCE_OPAQUE>` tracing primary rays against a single triangle: green `(0, 255, 0)` on hit at the centre pixel, blue `(0, 0, 255)` on miss at the corner pixel
- Zero D3D12 debug-layer validation errors on both hardware and WARP

## Run

```powershell
moon build --target native examples/dx12/rayquery
.\_build\native\debug\build\laplaceliu\tycho_vulkan_examples\dx12\rayquery\rayquery.exe
```
