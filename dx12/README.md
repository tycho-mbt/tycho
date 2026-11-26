# laplaceliu/tycho_dx12

Pure-MoonBit Direct3D 12 bindings for Tycho — the Windows counterpart of `laplaceliu/tycho_vulkan`.

Zero user C and zero import libraries: `d3d12.dll` and `dxgi.dll` are loaded at runtime with
`LoadLibraryA` and every entry point is resolved with `GetProcAddress`, so downstream `moon.pkg`
files need no `cc-link-flags` (`d3d12.lib`, `dxgi.lib`, `dxguid.lib` are all unnecessary).

## Status — M1a (hand-written minimal surface)

This is the first vertical slice described in
[docs/original-design/03-dx12.md](../../docs/original-design/03-dx12.md) §6.1: the COM plumbing,
the runtime loader and the device/command/pipeline/readback path, hand-written so the shape can be
validated before the code generator takes over in M1b.

| Surface | Notes |
|---|---|
| `Device` | FL 12_0 device + direct queue + fence; hardware adapter first, WARP on request; optional debug layer (`ID3D12InfoQueue` message counting) |
| `CommandList` | direct allocator + command list, `begin` / transitions / clear / draw / copy / `execute_wait` |
| `Pipeline` | empty root signature + graphics PSO from DXIL blobs |
| `Texture` | RGBA8 UNORM render target with its own RTV heap |
| `Readback` | READBACK-heap buffer, rows repacked to tightly packed RGBA8 on the MoonBit side |

Capability queries: `Device::shader_model`, `Device::mesh_tier`, `Device::raytracing_tier`,
`Device::is_warp`, `Device::validation_errors`.

Environment: `TYCHO_DX12_WARP=1` forces the WARP software adapter (the DX12 counterpart of
`TYCHO_VULKAN_LIB`); `TYCHO_D3D12_LIB` / `TYCHO_DXGI_LIB` override the DLL paths.

Windows-only by behaviour, buildable everywhere: on other hosts every entry point reports
"unavailable" so callers can `SKIP` instead of failing.

## Not here yet

Descriptor heaps beyond a single RTV, resource state tracking, DXGI swapchain presentation,
root signature layouts for the RHI slot model, and the generated full-surface binding (M1b).
