# dx12/raw-state

Exercises generated `ID3D12GraphicsCommandList` state thunks that need no
resources, calling the `dx_*` functions on `Device::raw()` directly (no
hand-written safe API), under the D3D12 debug layer asserting zero validation
errors.

## What it exercises

- `OMSetBlendFactor`, `OMSetStencilRef`
- `IASetVertexBuffers` / `IASetIndexBuffer` (unbind with `num_views=0` / null view)
- `SetMarker` (null payload)
- `Close`

`BeginEvent` / `EndEvent` are deliberately omitted: the debug layer raises an
ERROR-severity diagnostic recommending the `PIXBeginEvent` / `PIXEndEvent` macros
(which are header macros, not separate COM methods).

Non-Windows hosts report `SKIP`.

## Run

```
moon run examples/dx12/raw-state --target native
```

Expected tail: `[dx12/raw-state] OK — commands=<N> generated COM calls verified …, 0 validation errors`.
