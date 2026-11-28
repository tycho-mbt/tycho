# dx12/raw-platform-ext

Mirrors `examples/vulkan/vendor-platform-ext` for DX12/DXGI: live-probes
optional and host-gated DX12/DXGI interfaces (DirectSR, protected resource
sessions, virtualization guest device, GBV diagnostics, pageable tools,
DXGI media/resource/surface/device QI probes) under the debug layer with zero
validation errors, and compile-/link-verifies all remaining unreachable,
D3D11-only, PIX, and destructive COM thunks + DLL free entry points under a
runtime-false guard so the suite reaches 100% static + dynamic surface coverage
(2,753 / 2,753 COM methods + 15 / 15 free entry points).
