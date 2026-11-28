# laplaceliu/tycho_dx12

Pure-MoonBit Direct3D 12 bindings for Tycho — the Windows counterpart of `laplaceliu/tycho_vulkan`.

Zero user C and zero import libraries: `d3d12.dll` and `dxgi.dll` are loaded at runtime with
`LoadLibraryA` and every entry point is resolved with `GetProcAddress`, so downstream `moon.pkg`
files need no `cc-link-flags` (`d3d12.lib`, `dxgi.lib`, `dxguid.lib` are all unnecessary).

## Status

Two layers, both complete for the desktop surface:

- A **hand-written safe API** (`dx12.mbt` + `dx12_stub.c`): COM plumbing, runtime loader, and the
  device / command / pipeline / texture / buffer / swapchain / readback path, with resource-state
  tracking, root signatures for the RHI slot model, and SRV / sampler / UAV / RTV descriptor heaps.
  The RHI backend (`tycho/dx12_backend.mbt`) is built on this layer.
- A **generated full-surface dispatch** (`dispatch_generated.{c,mbt}`): one 1:1 thunk per COM method
  for the whole `ID3D12*` / `IDXGI*` surface, callable directly via `Device::raw()` (see
  `examples/dx12/raw-dispatch`).

`examples/dx12/` verifies both layers end-to-end under the D3D12 debug layer asserting zero validation errors on both hardware adapters and `TYCHO_DX12_WARP=1`:
- Safe API suites: `triangle`, `present`, `depth`, `geometry`, `indirect`, `compute`, `advanced`, `mrt`, `texture`, `mesh`, `uniform`, `rayquery`, `rhi-triangle`, `vulkan-interop` (plus DX12-RHI examples)
- Raw generated dispatch suites: `raw-dispatch`, `raw-commands`, `raw-device`, `raw-interfaces`, `raw-state`, `raw-dxgi`, `raw-device-all`, `raw-cmdlist-all`, `raw-platform-ext`

| Surface | Notes |
|---|---|
| `Device` | FL 12_0 device + direct queue + fence; hardware adapter first, WARP on request; optional debug layer (`ID3D12InfoQueue` message counting); `wait_idle`, `raw()` for raw COM interop |
| `CommandList` | direct allocator + command list, `begin` / `transition` / clear / `draw` / `draw_indexed` / `bind_vertex` / `bind_index` / `copy_to_readback` / `execute_wait` |
| `ResourceState` | typed states (`RenderTarget`, `CopySource`, `CopyDest`, `Present`, …); the shim tracks the native state per texture and only emits a barrier when it actually changes, and drawing/copying from the wrong state fails with `E_ILLEGAL_METHOD_CALL` |
| `Pipeline` | graphics PSO from DXIL blobs: root signature (root CBVs + SRV/sampler or UAV tables), depth state, and an input layout built from packed element records (`TEXCOORD(location * 10)`, the index Slang emits) |
| `Texture` | RGBA8 UNORM render target with its own RTV heap (`state()` reports the tracked state) |
| `Swapchain` | DXGI flip-model (`DXGI_SWAP_EFFECT_FLIP_DISCARD`, 3 buffers) on an `HWND`; `target(index)` wraps a back buffer, `present()` distinguishes presented / occluded / failed, `resize()` recreates the RTV heap |
| `Readback` | READBACK-heap buffer, rows repacked to tightly packed RGBA8 on the MoonBit side |
| generated dispatch | `dispatch_generated.c` / `dispatch_generated.mbt`: one thunk per COM method for 125 interfaces (2753 methods), generated from `registry/d3d12-abi.txt` |
| raw COM lifetime | `com_release` / `com_add_ref` (IUnknown, omitted from the manifest) + `int32_ptr` / `int64_ptr` / `bytes_ptr` marshalling helpers for the raw dispatch ABI |

Capability queries: `Device::shader_model`, `Device::mesh_tier`, `Device::raytracing_tier`,
`Device::is_warp`, `Device::validation_errors`.

## Code generation

`registry/d3d12-abi.txt` is the committed COM ABI manifest, distilled once from `d3d12.h`,
`d3dcommon.h` and `dxgi*.h` with `tools/dump-d3d12-abi.py` (the only step that needs the Windows
SDK). It covers **the whole surface**: 125 interfaces / 2753 methods, i.e. every `ID3D12*` and
`IDXGI*` interface in those headers. Regenerating the dispatch layer needs nothing but Python:

```bash
python tools/gen-dx12-bindings.py            # writes dispatch_generated.{c,mbt}
python tools/gen-dx12-bindings.py --check    # drift gate, wired into ./check-generated.sh
python tools/dx12-coverage.py --check        # 100% gate: header surface vs manifest (binding)
python tools/dx12-exec-coverage.py --check   # 100% gate: 2753/2753 COM methods + 15/15 free entry points
python tools/dx12-exec-coverage.py --live-only # report genuinely live-exercised methods separately
```

`dx12-coverage.py` gates *binding completeness* (every header method is bound);
`dx12-exec-coverage.py --check` gates *full surface coverage* across `examples/dx12/*` and
`dx12/dx12_wbtest.mbt` (2,753 / 2,753 COM methods = 100.0%, and 15 / 15 DLL free entry points),
while `--live-only` measures live-invoked calls excluding the `raw-platform-ext` compile-verified
platform/D3D11/PIX/destructive block.

`gen-dx12-bindings.py` refuses to guess a type: every parameter and return spelling must be in its
scalar/pointer knowledge sets or be recorded as a `kind` in the manifest. A header bump that
introduces an unknown spelling fails with the exact `Interface::Method` instead of silently
truncating a pointer to 32 bits, and `dx12-coverage.py` reports any interface or method the
manifest is missing.

Environment: `TYCHO_DX12_WARP=1` forces the WARP software adapter (the DX12 counterpart of
`TYCHO_VULKAN_LIB`); `TYCHO_D3D12_LIB` / `TYCHO_DXGI_LIB` override the DLL paths.

Windows-only by behaviour, buildable everywhere: on other hosts every entry point reports
"unavailable" so callers can `SKIP` instead of failing.

## Not here yet

- Mesh-shader root signature payload + amplification, multi-geometry / multi-instance acceleration
  structures, swapchain depth, and depth readback are explicitly rejected by the RHI backend.
- D3D12MA and full Agility SDK support.
