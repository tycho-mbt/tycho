# 43-rhi-hardening

Regression suite for RHI v0.3 hardening features:
- Headless `DeviceDesc` + `Device::capabilities()`
- `MemoryLocation::GpuOnly` (`DEVICE_LOCAL`) buffer with offset uploads & download
- Deferred resource deletion without `vkDeviceWaitIdle` stalls
- Dynamic descriptor pool expansion (> 16 sets per frame)
- `SwapchainDesc` with `PresentMode::Mailbox` & `begin_frame_commands` / `begin_swapchain_pass`
