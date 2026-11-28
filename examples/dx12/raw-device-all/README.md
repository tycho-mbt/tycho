# dx12/raw-device-all

Exercises the full `ID3D12Device`..`ID3D12Device14` inheritance chain, the
core `d3d12.dll` free entry points, D3D12 singletons (DRED, Tools, DeviceFactory,
DeviceConfiguration), and core D3D12 object interfaces (`ID3D12Object`,
`ID3D12DeviceChild`, `ID3D12Pageable`, `ID3D12RootSignature`,
`ID3D12RootSignatureDeserializer`, `ID3D12VersionedRootSignatureDeserializer`,
`ID3D12Heap0..1`, `ID3D12Resource0..2`, `ID3D12Fence0..1`,
`ID3D12DescriptorHeap`, `ID3D12CommandAllocator`, `ID3D12QueryHeap`,
`ID3D12CommandSignature`, `ID3D12CommandQueue`, `ID3D12CommandList`,
`ID3D12PipelineState`, `ID3D12PipelineLibrary0..1`,
`ID3D12ShaderCacheSession`, `ID3D12StateObject`, `ID3D12StateObjectProperties0..1`,
`ID3D10Blob`, `ID3DDestructionNotifier`) through the generated `dx_*` COM
dispatch layer with zero D3D12 debug-layer validation errors.

Runs on both hardware adapters and `TYCHO_DX12_WARP=1`, and cleanly `SKIP`s on
non-Windows hosts.
