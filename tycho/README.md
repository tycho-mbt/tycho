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

- Backend-opaque handles: `Device`, `Swapchain`, `Pipeline`, `Buffer`, `Texture`, `Sampler`, `CommandBuffer`, `Fence`, `TimestampPool`, `BindlessHeap`, `AccelStruct`
- Vulkan 1.3 **Dynamic Rendering** + **Synchronization2**, **2 frames-in-flight**, X11 + runtime-loaded Wayland swapchains, and automatic recreation on resize / `OUT_OF_DATE`
- Pure-MoonBit free-list GPU memory sub-allocator (`RegionPool` / `SubAllocator`) with `GpuOnly`/`CpuToGpu`/`GpuToCpu` tiers, deferred deletion queue, and `VK_MEMORY_ALLOCATE_DEVICE_ADDRESS_BIT` when Ray Query is supported
- **SPIR-V Auto-Reflection**: `PipelineDesc::from_spirv` and `Device::create_compute_pipeline_auto` derive vertex layouts, descriptor bindings (UBO, texture, SSBO, storage image, `OpTypeAccelerationStructureKHR`), push constant ranges, and MRT attachment counts directly from SPIR-V bytecode
- **Modern GPU Features**: **MRT**, **4x MSAA Offscreen Resolve**, **Hardware Mipmap Generation**, **Compute Storage Images**, **Indirect / Indirect-Count Draw**, **Bindless Heap**, **Mesh Shaders**, **StencilState + dynamic `set_stencil_reference`**, **Inline Ray Query (`create_blas` / `create_tlas` / `bind_accel_struct`)**, and **GPU Timestamp Queries** (`TimestampPool`)
