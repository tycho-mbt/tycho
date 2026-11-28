# dx12/vulkan-interop

Live Windows Direct3D 12 <-> Vulkan GPU interop example (pure MoonBit, zero user C).

## What it proves

1. **Adapter LUID matching**: matches `ID3D12Device::GetAdapterLuid` against `VkPhysicalDeviceIDProperties::deviceLUID` on Windows hardware.
2. **D3D12 Shared Resource -> Vulkan External Memory**:
   - Creates a `D3D12_HEAP_FLAG_SHARED` RGBA8 texture with `ALLOW_RENDER_TARGET | ALLOW_SIMULTANEOUS_ACCESS`.
   - Exports a named NT `HANDLE` via `ID3D12Device::CreateSharedHandle` (exercising `OpenSharedHandle` and `OpenSharedHandleByName` as well).
   - Queries `vkGetMemoryWin32HandlePropertiesKHR(..., VK_EXTERNAL_MEMORY_HANDLE_TYPE_D3D12_RESOURCE_BIT, ...)` live, creates a `VkImage`, imports the D3D12 resource via `VkImportMemoryWin32HandleInfoKHR` + `VkMemoryDedicatedAllocateInfo`, and binds it.
3. **D3D12 Shared Fence <-> Vulkan Timeline Semaphore**:
   - Creates a `D3D12_FENCE_FLAG_SHARED` fence, exports an NT `HANDLE`, and imports it into a Vulkan timeline `VkSemaphore` (`VK_EXTERNAL_SEMAPHORE_HANDLE_TYPE_D3D12_FENCE_BIT`).
   - Signals value `1` from the D3D12 direct queue -> Vulkan waits for `1` -> Vulkan signals value `2` -> D3D12 waits for `2` via `SetEventOnCompletion`.
4. **Zero validation errors** on both the D3D12 debug layer and `VK_LAYER_KHRONOS_validation`.

Non-Windows hosts and GPU-less WARP/lavapipe runners report `SKIP` cleanly when no matching hardware LUID pair exists.

## Run

```powershell
moon build --target native examples/dx12/vulkan-interop
.\_build\native\debug\build\laplaceliu\tycho_vulkan_examples\dx12\vulkan-interop\vulkan-interop.exe
```
