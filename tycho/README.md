# laplaceliu/tycho

Unified pure-MoonBit Render Hardware Interface (RHI) built atop `laplaceliu/tycho_vulkan`, `laplaceliu/tycho_window`, and `laplaceliu/tycho_shader` with **zero C stubs**.

## Features (v0.1 — Vulkan 1.3 Backend)

- Backend-opaque handles: `Device`, `Swapchain`, `Pipeline`, `Buffer`, `Texture`, `Sampler`, `CommandBuffer`, `Fence`
- Vulkan 1.3 **Dynamic Rendering** (`VK_KHR_dynamic_rendering` core) and **Synchronization2**
- **2 frames-in-flight** ring synchronization + automatic swapchain recreation on resize / `OUT_OF_DATE`
- Pure-MoonBit free-list GPU memory sub-allocator (`RegionPool` / `SubAllocator`) with persistent mapping for host-visible buffers and separated buffer/image blocks
- Slot-based descriptor binding (uniform, texture+sampler, storage slots) + push constants + depth testing + MSAA offscreen render & resolve passes
