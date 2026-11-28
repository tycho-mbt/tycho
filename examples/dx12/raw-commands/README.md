# dx12/raw-commands

Exercises the generated `ID3D12GraphicsCommandList` recording thunks plus the
resource/RTV creation they need, calling the `dx_*` functions on `Device::raw()`
directly (no hand-written safe API), under the D3D12 debug layer asserting zero
validation errors.

## What it exercises

- `ID3D12Device::CreateCommittedResource` (DEFAULT-heap render-target texture) +
  `ID3D12Resource::GetDesc` / `GetGPUVirtualAddress`
- `ID3D12Device::CreateDescriptorHeap` (RTV) +
  `ID3D12DescriptorHeap::GetCPUDescriptorHandleForHeapStart` +
  `ID3D12Device::CreateRenderTargetView`
- Recording: `ResourceBarrier` (COMMON↔RENDER_TARGET), `OMSetRenderTargets`,
  `ClearRenderTargetView`, `RSSetViewports`, `RSSetScissorRects`,
  `IASetPrimitiveTopology`, then `Close`

Commands are recorded and the list closed (not executed) — enough to exercise the
record-time API. Two raw-ABI subtleties are handled here:

- Struct returns such as `D3D12_CPU_DESCRIPTOR_HANDLE` come back through a hidden
  out-pointer, so a valid buffer must be passed (passing `0` writes to NULL).
- `D3D12_CPU_DESCRIPTOR_HANDLE` parameters are passed **by pointer** in the
  generated thunks (`CreateRenderTargetView`, `ClearRenderTargetView`), not by
  value.

Structs are program-lifetime arrays so the raw pointers stay valid for the whole
call. Non-Windows hosts report `SKIP`.

## Run

```
moon run examples/dx12/raw-commands --target native
```

Expected tail: `[dx12/raw-commands] OK — commands=<N> generated COM calls verified …, 0 validation errors`.
