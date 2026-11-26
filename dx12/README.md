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
| `Device` | FL 12_0 device + direct queue + fence; hardware adapter first, WARP on request; optional debug layer (`ID3D12InfoQueue` message counting); `wait_idle`, `raw()` for raw COM interop |
| `CommandList` | direct allocator + command list, `begin` / `transition` / clear / draw / copy / `execute_wait` |
| `ResourceState` | typed states (`RenderTarget`, `CopySource`, `CopyDest`, `Present`, …); the shim tracks the native state per texture and only emits a barrier when it actually changes, and drawing/copying from the wrong state fails with `E_ILLEGAL_METHOD_CALL` |
| `Pipeline` | empty root signature + graphics PSO from DXIL blobs |
| `Texture` | RGBA8 UNORM render target with its own RTV heap (`state()` reports the tracked state) |
| `Swapchain` | DXGI flip-model (`DXGI_SWAP_EFFECT_FLIP_DISCARD`, 3 buffers) on an `HWND`; `target(index)` wraps a back buffer, `present()` distinguishes presented / occluded / failed, `resize()` recreates the RTV heap |
| `Readback` | READBACK-heap buffer, rows repacked to tightly packed RGBA8 on the MoonBit side |
| generated dispatch | `dispatch_generated.c` / `dispatch_generated.mbt`: one thunk per COM method for 17 interfaces (490 methods), generated from `registry/d3d12-abi.txt` |

Capability queries: `Device::shader_model`, `Device::mesh_tier`, `Device::raytracing_tier`,
`Device::is_warp`, `Device::validation_errors`.

## Code generation

`registry/d3d12-abi.txt` is the committed COM ABI manifest, distilled once from `d3d12.h` with
`tools/dump-d3d12-abi.py` (the only step that needs the Windows SDK). Regenerating the dispatch
layer needs nothing but Python:

```bash
python tools/gen-dx12-bindings.py          # writes dispatch_generated.{c,mbt}
python tools/gen-dx12-bindings.py --check  # drift gate, wired into ./check-generated.sh
```

Environment: `TYCHO_DX12_WARP=1` forces the WARP software adapter (the DX12 counterpart of
`TYCHO_VULKAN_LIB`); `TYCHO_D3D12_LIB` / `TYCHO_DXGI_LIB` override the DLL paths.

Windows-only by behaviour, buildable everywhere: on other hosts every entry point reports
"unavailable" so callers can `SKIP` instead of failing.

## Not here yet

Descriptor heaps beyond a single RTV, resource state tracking, DXGI swapchain presentation,
root signature layouts for the RHI slot model, and the generated full-surface binding (M1b).
