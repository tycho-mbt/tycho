# dx12/raw-interfaces

Verifies the generated thunks for the whole `ID3D12Device1..14` interface chain.
A D3D12 device implements every one of these interfaces, and inherited methods sit
at the same vtable slots, so the same raw device pointer (`Device::raw()`) can be
called through each interface's thunks.

For each of `ID3D12Device1` … `ID3D12Device14` it calls `GetNodeCount`,
`GetDeviceRemovedReason`, and `CheckFeatureSupport` (ARCHITECTURE), checking that
every interface binding resolves and forwards correctly. Runs under the D3D12
debug layer asserting zero validation errors. Non-Windows hosts report `SKIP`.

This is binding/ABI verification of the multi-interface surface rather than new
rendering functionality; the distinct-functionality coverage lives in
`raw-dispatch`, `raw-device`, and `raw-commands`.

## Run

```
moon run examples/dx12/raw-interfaces --target native
```

Expected tail: `[dx12/raw-interfaces] OK — commands=<N> generated COM calls verified …, 0 validation errors`.
