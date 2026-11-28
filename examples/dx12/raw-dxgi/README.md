# dx12/raw-dxgi

Live verification of the generated DXGI COM dispatch layer and DXGI DLL free functions.

Covers:
- Free `dxgi.dll` entry points (`CreateDXGIFactory`, `CreateDXGIFactory1`, `CreateDXGIFactory2`, `DXGIGetDebugInterface1`, `DXGIDeclareAdapterRemovalSupport`, `DXGIDisableVBlankVirtualization`)
- `IDXGIObject` + full `IDXGIFactory` .. `IDXGIFactory7` inheritance chain
- `IDXGIDisplayControl`
- Full `IDXGIAdapter` .. `IDXGIAdapter4` inheritance chain
- Full `IDXGIOutput` .. `IDXGIOutput6` inheritance chain (plus `IDXGIOutputDuplication` when available; gracefully skipped on WARP/headless)
- Full `IDXGISwapChain` .. `IDXGISwapChain4` inheritance chain on a Win32 `HWND`

Asserts 0 D3D12 debug-layer validation errors on both hardware and `TYCHO_DX12_WARP=1`.

## Run

```powershell
moon build --target native examples/dx12/raw-dxgi
.\_build\native\debug\build\laplaceliu\tycho_vulkan_examples\dx12\raw-dxgi\raw-dxgi.exe
```
