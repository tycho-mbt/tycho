# laplaceliu/tycho

Unified pure-MoonBit Render Hardware Interface (RHI) built atop `laplaceliu/tycho_vulkan`, `laplaceliu/tycho_window`, and `laplaceliu/tycho_shader` with **zero C stubs**.

## Install

```bash
moon add laplaceliu/tycho
```

Link flags are **not** transitive in MoonBit: the final executable must declare them
itself. Add this to the `moon.pkg` of your executable package:

```moonbit
// moon.pkg
options(
  "link": {
    "native": {
      "cc": "cc",
      "cc-link-flags": "-lvulkan -lX11", // -lX11 only needed for windowing/WSI
    },
  },
)
```

Requirements: a Vulkan **1.3** loader + driver (`libvulkan-dev`, `libx11-dev` on
Debian/Ubuntu). No Vulkan SDK, `-I`, or env var is needed at build time.

## Features (Vulkan 1.3 Backend)

- Backend-opaque handles: `Device`, `Swapchain`, `Pipeline`, `Buffer`, `Texture`, `Sampler`, `CommandBuffer`, `Fence`, `TimestampPool`
- Vulkan 1.3 **Dynamic Rendering** + **Synchronization2**, **2 frames-in-flight**, and automatic swapchain recreation on resize / `OUT_OF_DATE`
- Pure-MoonBit free-list GPU memory sub-allocator (`RegionPool` / `SubAllocator`) with persistent mapping for host-visible buffers and separated buffer/image blocks
- **SPIR-V Auto-Reflection**: `PipelineDesc::from_spirv` and `Device::create_compute_pipeline_auto` derive vertex layouts, descriptor bindings, push constant ranges, and MRT attachment counts directly from SPIR-V bytecode
- **Multiple Render Targets (MRT)**, **4x MSAA Offscreen Resolve**, **Hardware Mipmap Generation** (`create_texture_mipmapped`, `readback_mip`, sampler LOD control), **Compute Storage Images** (`create_storage_texture`, `bind_storage_image`), and **GPU Timestamp Queries** (`TimestampPool`)
