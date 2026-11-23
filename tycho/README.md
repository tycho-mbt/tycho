# laplaceliu/tycho

Unified pure-MoonBit Render Hardware Interface (RHI) built atop `laplaceliu/tycho_vulkan`, `laplaceliu/tycho_window`, and `laplaceliu/tycho_shader` with **zero C stubs**.

## Features (Vulkan 1.3 Backend)

- Backend-opaque handles: `Device`, `Swapchain`, `Pipeline`, `Buffer`, `Texture`, `Sampler`, `CommandBuffer`, `Fence`, `TimestampPool`
- Vulkan 1.3 **Dynamic Rendering** + **Synchronization2**, **2 frames-in-flight**, and automatic swapchain recreation on resize / `OUT_OF_DATE`
- Pure-MoonBit free-list GPU memory sub-allocator (`RegionPool` / `SubAllocator`) with persistent mapping for host-visible buffers and separated buffer/image blocks
- **SPIR-V Auto-Reflection**: `PipelineDesc::from_spirv` and `Device::create_compute_pipeline_auto` derive vertex layouts, descriptor bindings, push constant ranges, and MRT attachment counts directly from SPIR-V bytecode
- **Multiple Render Targets (MRT)**, **4x MSAA Offscreen Resolve**, **Hardware Mipmap Generation** (`create_texture_mipmapped`, `readback_mip`, sampler LOD control), **Compute Storage Images** (`create_storage_texture`, `bind_storage_image`), and **GPU Timestamp Queries** (`TimestampPool`)
