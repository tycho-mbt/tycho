# laplaceliu/tycho

Unified pure-MoonBit Render Hardware Interface (RHI) built atop `laplaceliu/tycho_vulkan`, `laplaceliu/tycho_window`, and `laplaceliu/tycho_shader` with **zero C stubs**.

## Install

```bash
moon add laplaceliu/tycho
```

No `cc-link-flags` are required. `laplaceliu/tycho_vulkan` and `laplaceliu/tycho_window`
resolve the Vulkan loader (`libvulkan.so.1` / `vulkan-1.dll` / `libvulkan.1.dylib` /
`libMoltenVK.dylib`) and the OS windowing libraries (`libwayland-client`, `libX11`,
`user32`, `AppKit` + `QuartzCore`) at runtime through `dlopen` / `LoadLibraryA`, so
downstream `moon.pkg` files only need the imports.

Requirements: a Vulkan **1.3** loader + driver (`dynamicRendering` + `synchronization2`).
No Vulkan SDK, `-I`, `VULKAN_SDK`, or `-lvulkan` / `-lX11` / `libx11-dev` / `libvulkan-dev`
dev package is needed at build time; the loader and windowing libraries only have to be
present at runtime (standard on desktop Linux, Windows, and macOS).

## Features (Vulkan 1.3 Backend)

- Backend-opaque handles: `Device`, `Swapchain`, `Pipeline`, `Buffer`, `Texture`, `Sampler`, `CommandBuffer`, `Fence`, `TimestampPool`, `BindlessHeap`, `AccelStruct`
- Vulkan 1.3 **Dynamic Rendering** + **Synchronization2**, **2 frames-in-flight**, X11 + runtime-loaded Wayland swapchains, and automatic recreation on resize / `OUT_OF_DATE`
- Pure-MoonBit free-list GPU memory sub-allocator (`RegionPool` / `SubAllocator`) with `GpuOnly`/`CpuToGpu`/`GpuToCpu` tiers, deferred deletion queue, and `VK_MEMORY_ALLOCATE_DEVICE_ADDRESS_BIT` when Ray Query is supported
- **SPIR-V Auto-Reflection**: `PipelineDesc::from_spirv` and `Device::create_compute_pipeline_auto` derive vertex layouts, descriptor bindings (UBO, texture, SSBO, storage image, `OpTypeAccelerationStructureKHR`), push constant ranges, and MRT attachment counts directly from SPIR-V bytecode
- **Modern GPU Features**: **MRT**, **4x MSAA Offscreen Resolve**, **Hardware Mipmap Generation**, **Compute Storage Images**, **Indirect / Indirect-Count Draw**, **Bindless Heap**, **Mesh Shaders**, **StencilState + dynamic `set_stencil_reference`**, **Inline Ray Query (`create_blas` / `create_tlas` / `bind_accel_struct`)**, and **GPU Timestamp Queries** (`TimestampPool`)
- **Deterministic backend errors**: a cross-backend misuse (DX12 resource on a Vulkan command buffer or vice versa, a command the other backend does not implement) is recorded in `CommandBuffer::first_error` and raised from `Device::end_commands` / `Swapchain::end_frame` as `RhiError::BackendUnsupported`. Recording calls never drop a mistake silently.
- **Native optional parameters**: pipeline/sampler/render-target descriptions use MoonBit optional arguments (`depth_format? : TextureFormat`, `compare_op? : CompareOp`, `resolve_texture? : Texture`, …), so call sites read `depth_format=TextureFormat::Depth32F` instead of `depth_format=Some(TextureFormat::Depth32F)`, and an existing `Option` forwards with `depth_format?=maybe_depth`.

## Math

The RHI depends on `laplaceliu/tycho_math` so the whole stack speaks one math dialect
(column-major, GPU-upload ready, explicit clip space). The dependency is used only in the
façade, for typed conveniences:

- `RayInstanceDesc::from_affine3(blas, Affine3)` — and the identity default of
  `RayInstanceDesc::new` — produce the row-major 3x4 TLAS transform via
  `Affine3::to_vk_transform_3x4()`, so the `VkTransformMatrixKHR` layout lives in one place.
- `CommandBuffer::push_constants_mat4(pipe, Mat4)`.

The raw APIs stay first-class: `Buffer::upload_floats`, `push_constants_floats` /
`push_constants_bytes` still take `FixedArray[Float]` / `Bytes`, so you can bypass math
entirely, and the Vulkan backend (`vk_backend.mbt`) never imports `@tmath` so it remains
replaceable. `check-math-layering.sh` enforces both directions: `tycho_math` keeps zero
`laplaceliu/*` dependencies and never references the RHI.

Every typed helper is a **thin wrapper over the raw call** (raw stays the primitive), and falls
into one of two classes: *completeness* twins of an existing raw call (`upload_mat4`,
`push_constants_mat4`, `RayInstanceDesc::from_affine3`), which are covered by equivalence tests
with non-degenerate matrices, and *exploratory* APIs, which require a real call site before they
are added because a test cannot validate an API's shape. See ADR-002 §3.
