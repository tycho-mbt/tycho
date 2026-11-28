# vulkan/win32-interop

Windows-specific Vulkan interop & WSI verification suite (pure MoonBit, zero C).

Exercises every Windows host-reachable Win32 and NVIDIA Windows extension with
`VK_LAYER_KHRONOS_validation` enabled and asserts zero validation errors:

- `VK_KHR_win32_surface`: direct `VkWin32SurfaceCreateInfoKHR` + `vkCreateWin32SurfaceKHR` + `vkGetPhysicalDeviceWin32PresentationSupportKHR`
- `VK_KHR_external_memory_win32`: `OPAQUE_WIN32` export/import round-trip (including named UTF-16 `LPCWSTR` via `@vk.wstr`) with `vkGetMemoryWin32HandleKHR` and host-visible shared-memory verification; `vkGetMemoryWin32HandlePropertiesKHR` is exercised with a non-opaque D3D handle (VUID-00666 forbids opaque handle types), gated on `vkGetPhysicalDeviceImageFormatProperties2` reporting the handle type exportable
- `VK_KHR_external_semaphore_win32`: export/import + queue signal/wait round-trip via `vkGetSemaphoreWin32HandleKHR` and `vkImportSemaphoreWin32HandleKHR`, plus `VkD3D12FenceSubmitInfoKHR`
- `VK_KHR_external_fence_win32`: export/import + queue signal/wait round-trip via `vkGetFenceWin32HandleKHR` and `vkImportFenceWin32HandleKHR`
- `VK_NV_external_memory_capabilities` + `VK_NV_external_memory_win32`: `vkGetPhysicalDeviceExternalImageFormatPropertiesNV` and `vkGetMemoryWin32HandleNV`
- `VK_EXT_full_screen_exclusive`: `vkGetPhysicalDeviceSurfacePresentModes2EXT`, `vkGetDeviceGroupSurfacePresentModes2EXT`, `vkAcquireFullScreenExclusiveModeEXT`, `vkReleaseFullScreenExclusiveModeEXT` with `HMONITOR` from `@win.monitor_handle`
- `VK_NV_acquire_winrt_display`: `vkGetWinrtDisplayNV` always; `vkAcquireWinrtDisplayNV` is opt-in via `TYCHO_WINRT_ACQUIRE=1` because acquiring a WinRT display still owned by the desktop access-violates some drivers (NVIDIA) instead of returning an error
- `VK_NV_external_compute_queue`: `vkCreateExternalComputeQueueNV`, `vkGetExternalComputeQueueDataNV`, `vkDestroyExternalComputeQueueNV`
- `VK_KHR_win32_keyed_mutex` & `VK_NV_win32_keyed_mutex`: struct layout verification

On non-Windows hosts the example reports `SKIP` cleanly.

## Driver-specific gating

Every extension is probed with the matching `vkGetPhysicalDeviceExternal*Properties`
/ capabilities query before use, and each section tolerates legitimate runtime
failures (occluded window, headless display, desktop-owned WinRT display) while
still requiring **zero validation errors**.

- NVIDIA reports D3D11/D3D12 memory handle types as *import-only* for Vulkan
  resources, so the D3D-handle export path (and thus
  `vkGetMemoryWin32HandlePropertiesKHR`) is skipped there. It runs on drivers that
  report the handle type exportable. A D3D12-created-handle import path is covered
  by the DX12 interop example.
- `vkAcquireWinrtDisplayNV` is disabled by default (see above); set
  `TYCHO_WINRT_ACQUIRE=1` to exercise it on a host with an acquirable WinRT display.

## Run

```
moon run examples/vulkan/win32-interop --target native
```

Expected tail on a Windows host with the validation layer:
`[vulkan/win32-interop] OK — <N> Windows interop commands in <M> sections, 0 validation errors`.
