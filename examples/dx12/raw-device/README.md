# dx12/raw-device

Extends `dx12/raw-dispatch` over more of the generated COM dispatch, calling the
`dx_*` thunks on `Device::raw()` directly (no hand-written safe API), under the
D3D12 debug layer asserting zero validation errors.

## What it exercises

- `ID3D12Device::CreateCommandQueue` (DIRECT) +
  `ID3D12CommandQueue::GetDesc` / `GetTimestampFrequency` / `GetClockCalibration`
- `ID3D12Device::CreateCommandAllocator` + `CreateCommandList`, then
  `ID3D12GraphicsCommandList::Close` / `Reset` / `Close`
- `ID3D12Device::CreateDescriptorHeap` for the non-RTV types
  (CBV_SRV_UAV, SAMPLER, DSV) + `GetDesc`
- `ID3D12Device::GetCopyableFootprints` for a 64x64 RGBA8 texture

Structs are marshalled as program-lifetime byte/int arrays so the raw pointers
stay valid for the whole call. Note `D3D12_RESOURCE_DESC::Alignment` is a
`UINT64`, so the desc carries 4 bytes of padding after `Dimension`.

Non-Windows hosts report `SKIP`.

## Run

```
moon run examples/dx12/raw-device --target native
```

Expected tail: `[dx12/raw-device] OK — commands=<N> generated COM calls verified …, 0 validation errors`.
