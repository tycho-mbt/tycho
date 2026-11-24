# Tycho Architecture

Tycho is a pure-MoonBit native Vulkan & RHI graphics stack designed so downstream applications import only `"laplaceliu/tycho" @tycho` (or `"laplaceliu/tycho_vulkan" @vk`) with **zero user C** and **zero LunarG Vulkan SDK build dependency**.

## Workspace Module Graph

```
codegen/ (laplaceliu/tycho_codegen, private)
   └── generates 6 files in vulkan/ from codegen/registry/vk.xml

vulkan/  (laplaceliu/tycho_vulkan)     ── dynamic Vulkan loader + vendored 1.4.363 headers (zero link flags)
window/  (laplaceliu/tycho_window)     ── Linux (Wayland/X11), Windows (Win32), macOS (Cocoa+Metal) via dlopen/LoadLibraryA
shader/  (laplaceliu/tycho_shader)     ── GLSL/Slang compile, SPIR-V reflect, image I/O

tycho/   (laplaceliu/tycho)            ── imports vulkan, window, shader; zero link flags
examples/(laplaceliu/tycho_vulkan_examples) ── 52 pure-MoonBit examples & suites
```

### Design Invariants

1. **Vendored Vulkan headers, runtime loader ≥ 1.3**:
   C headers live in `vulkan/include/vulkan/`. All Vulkan functions are dynamically resolved via `vkGetInstanceProcAddr` / `vkGetDeviceProcAddr`, and the RHI targets Vulkan **1.3** core (`VK_API_VERSION_1_3`), so downstream consumers need no `-I` flags or SDK environment variables.
2. **Compile-time ABI verification**:
   Generated C shims emit `_Static_assert(sizeof(C field) <= MoonBit type width)` across generated Vulkan structs and scalar parameters; `check-generated.sh` ensures committed files match `./generate.sh` output with zero diff.
3. **Zero user C in examples**:
   `check-examples-pure.sh` enforces that `examples/` contains zero `.c` files and zero `native-stub` declarations.

## RHI Layering (`tycho/`)

| File | Responsibility |
|---|---|
| `tycho/types.mbt` | Backend-agnostic descriptors (`DeviceDesc`, `PipelineDesc`, `MeshPipelineDesc`, `SwapchainDesc`, `SamplerDesc`, `RenderTargetDesc`, `DepthTargetDesc`), enums (`TextureFormat`, `BufferKind`, `MemoryLocation`, `BlendMode`, `CullMode`, `Filter`, `AddressMode`, `CompareOp`, `BackendKind`), `RhiError`, and re-exports from `tycho_window` / `tycho_shader`. |
| `tycho/rhi.mbt` | Public RHI façade (`Device`, `Swapchain`, `Pipeline`, `Buffer`, `Texture`, `Sampler`, `Fence`, `TimestampPool`, `BindlessHeap`, `CommandBuffer`). Contains **zero** direct `@vk.*` or Vulkan dispatch (`dfn.*`) references — every operation delegates to backend helpers, keeping `BackendKind` extensible to future Metal/DX12 backends. |
| `tycho/vk_backend.mbt` | Vulkan 1.3 backend implementation: instance/device selection, validation capture, 2-frame swapchain synchronization, dynamic rendering (`VkRenderingInfo`), `synchronization2` barriers (`VkDependencyInfo`), automatic image layout tracking, dynamic descriptor pool growth, bindless descriptor indexing heap, and `VkPipelineCache`. |
| `tycho/alloc.mbt` | Block-based free-list GPU memory sub-allocator and generation-based deferred deletion queue. |

## Vulkan 1.3 Backend Internals

- **Dynamic Rendering & Sync2**: Render passes map directly to `vkCmdBeginRendering` / `vkCmdEndRendering` with explicit `LoadOp` (`Clear`, `Load`, `DontCare`), `StoreOp` (`Store`, `DontCare`), optional MSAA resolve attachments (`SampleCount::X4` -> `X1`), MRT color attachment arrays (`color_formats`), and depth/stencil attachments (`Depth32F` / `Depth24Stencil8`), including depth-only passes (`depth_only=true`) or pipelines with matching `depth_format` and `depth_test=false`.
- **Automatic Layout Tracking**: Each `VkTextureState` tracks its current layout so `begin_render_pass`, `bind_texture`, `bind_storage_image`, `blit_texture`, `transition_for_sampling`, `transition_for_compute`, and `readback` emit minimal `VkImageMemoryBarrier2` transitions automatically.
- **Memory SubAllocator & Deferred Deletion**:
  - Allocations are sub-allocated from device memory blocks via a free-list allocator keyed by `MemoryLocation` (`GpuOnly`, `CpuToGpu`, `GpuToCpu`).
  - `destroy()` on buffers, textures, samplers, pipelines, and heaps enqueues GPU handles alongside the active submission generation (`current_gen`) instead of blocking with `vkDeviceWaitIdle`.
  - Resources are reclaimed automatically once `completed_gen` advances via `Fence::wait()`, `Swapchain::end_frame()`, or `Device::wait_idle()`.
- **Pipeline Reflection & Descriptor Scaling**:
  - `PipelineDesc::from_spirv` and `Device::create_compute_pipeline_auto` invoke `@shader.reflect_spirv` on SPIR-V bytecode to deduce descriptor bindings (UBO, combined image sampler, SSBO, storage image, acceleration structure), push constant sizes, and vertex input attributes (`vec2`/`vec3`/`vec4`).
  - Per-pipeline descriptor pools expand dynamically when draw counts exceed a single pool's capacity.
  - Optional `BindlessHeap` binds a descriptor-indexed texture array (`set=1` by default) via `CommandBuffer::bind_bindless_heap`.
- **Stencil, Indirect-Count & Inline Ray Query**:
  - `PipelineDesc.stencil` (`StencilState` / `StencilFaceState`) pairs with `DepthTargetDesc` stencil load/store ops on `Depth24Stencil8` targets and dynamic `CommandBuffer::set_stencil_reference`.
  - `draw_indirect_count` / `draw_indexed_indirect_count` use Vulkan 1.2 `drawIndirectCount`.
  - When `DeviceCapabilities.supports_ray_query` is true, `Device::create_blas` / `Device::create_tlas` build device-local acceleration structures (`AccelStruct`) backed by device-address-enabled `SubAllocator` blocks and bound via `CommandBuffer::bind_accel_struct`.

## Verification Architecture

- **Headless-by-default**: Rendering examples default to `DeviceDesc::new(..., headless=true)` and execute offscreen passes with pixel/buffer assertions, optional `--window` interactive rendering (`want_window()`), and `--screenshot <path>` PNG capture (`screenshot_path()`).
- **Cross-platform CI matrix**: `.github/workflows/ci.yml` runs on **Linux** (`ubuntu-latest`, Mesa `lavapipe` + `tools/run-all.sh`), **Windows** (`windows-latest`, MSVC + Mesa `lavapipe` via `tools/run-ci-suite.py`), and **macOS** (`macos-15`, MoltenVK via `tools/run-ci-suite.py`). Locally, `tools/run-all.sh both` verifies both Mesa `lavapipe` and native `nvidia` hardware, failing on non-zero exit codes, `FAIL` markers, validation errors, or vacuous `0`-command passes (`SKIP` is reserved for drivers missing optional hardware extensions).
