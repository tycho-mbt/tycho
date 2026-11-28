# dx12/raw-dispatch

Verifies the **generated 1:1 COM dispatch layer** (`dx12/dispatch_generated.*`)
directly, rather than the hand-written safe API that every other `dx12` example
uses. It calls the `dx_*` thunks on the raw `ID3D12Device *` from
`@dx12.Device::raw()`, proving the full-surface binding is callable and
ABI-correct.

## What it exercises

- `ID3D12Device::GetNodeCount`, `GetDeviceRemovedReason` (scalar returns)
- `ID3D12Device::CheckFeatureSupport` for `D3D12_FEATURE_ARCHITECTURE` and
  `D3D12_FEATURE_SHADER_MODEL`, passing the feature structs by pointer through
  the raw ABI (`@dx12.int32_ptr`)
- `ID3D12Device::CreateDescriptorHeap` (RTV) + `ID3D12DescriptorHeap::GetDesc`
  (struct-by-value return lowered to an out-pointer) + `IUnknown::Release`
- `ID3D12Device::CreateCommandAllocator` (DIRECT) + `Reset` + `Release`
- `ID3D12Device::CreateFence` + `ID3D12Fence::GetCompletedValue` + `Release`

The `Create*` methods need an IID; the manifest deliberately omits the
`IUnknown` methods, so lifetime is managed with `@dx12.com_release` /
`@dx12.com_add_ref`. IID byte arrays and the heap desc are program-lifetime
globals so the raw pointers handed to the thunks stay valid for the whole call.

Runs under the D3D12 debug layer and asserts **zero validation errors**.
Non-Windows hosts report `SKIP`.

## Run

```
moon run examples/dx12/raw-dispatch --target native
```

Expected tail: `[dx12/raw-dispatch] OK — commands=<N> generated COM calls verified …, 0 validation errors`.
