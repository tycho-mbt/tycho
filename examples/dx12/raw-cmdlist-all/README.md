# dx12/raw-cmdlist-all

Exercises the full `ID3D12GraphicsCommandList`..`ID3D12GraphicsCommandList10`
inheritance chain through the generated `dx_*` COM dispatch layer on a live
command list, feature-gating optional hardware features (`DepthBounds`,
`SamplePositions`, `ViewInstancing`, `WriteBufferImmediate`, `Raytracing`,
`VariableShadingRate`, `MeshShader`, `EnhancedBarriers`, `StencilRef`,
`DynamicDepthBias`) and verifying zero D3D12 debug-layer validation errors.

Runs on both hardware adapters and `TYCHO_DX12_WARP=1`, and cleanly `SKIP`s on
non-Windows hosts.
