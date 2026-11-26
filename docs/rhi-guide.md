# Tycho RHI Programming Guide

Import only `"laplaceliu/tycho" @tycho` in your `moon.pkg` — no `cc-link-flags` are needed,
because the Vulkan loader and OS windowing libraries are resolved at runtime (`dlopen` /
`LoadLibraryA`) by `laplaceliu/tycho_vulkan` and `laplaceliu/tycho_window`:

```moonbit-pkg
import {
  "laplaceliu/tycho" @tycho,
}
pkgtype(kind: "executable")
```

The RHI depends on `laplaceliu/tycho_math` and exposes typed helpers for the places where
graphics math crosses the API boundary: `cmd.push_constants_mat4(pipe, m)` and
`RayInstanceDesc::from_affine3(blas, affine)`. The raw `FixedArray[Float]` / `Bytes` APIs
(`upload_floats`, `push_constants_floats`, `push_constants_bytes`) remain available if you
prefer to compute matrices yourself.

## 1. Device & Headless / Window Modes

```moonbit
let show_win = @tycho.want_window()        // true when --window / -w is passed
let shot = @tycho.screenshot_path()        // non-empty when --screenshot <path> is passed
let dev = @tycho.Device::new_desc(
  @tycho.DeviceDesc::new("My App", validation=true, headless=!show_win),
)
let caps = dev.capabilities()              // device_name, supports_mesh_shader, supports_bindless, ...
// ... render ...
let errs = dev.validation_errors()
let used = dev.allocator_used_bytes()      // expect 0 after destroying resources + wait_idle()
dev.destroy()
```

### Swapchain & Window Input

```moonbit
let sc = dev.create_swapchain_desc(
  @tycho.SwapchainDesc::new("Window Title", 800, 600, depth=true, present_mode=@tycho.PresentMode::Mailbox),
)
while !sc.should_close() {
  for ev in sc.poll_events() {
    match ev {
      @tycho.Event::KeyDown(k, _) => if k == @tycho.KEY_ESCAPE { break }
      _ => ()
    }
  }
  let (mx, my) = sc.mouse_pos()
  let lmb = sc.is_mouse_down(1)
  let cmd = sc.begin_frame_commands()
  cmd.begin_swapchain_pass(sc)
  // record draws ...
  cmd.end_swapchain_pass()
  sc.end_frame(cmd)
}
sc.destroy()
```

Note on descriptor slots & binding ranges: `PipelineDesc::from_spirv` and `create_compute_pipeline_auto` sort bindings in `set = 0` ascending and assign **0-based per-kind slots** independently for uniforms (`bind_uniform`), textures (`bind_texture`), storage buffers (`bind_storage`), storage images (`bind_storage_image`), and acceleration structures (`bind_accel_struct`). `bind_uniform` and `bind_storage` accept optional `offset?` and `size?` byte sub-ranges for ring-buffered dynamic uploads, and `set_scissor` automatically clamps rects to the active render area.

## 2. Shaders & Pipeline Auto-Reflection

```moonbit
let vert = @tycho.compile_glsl("shader.vert", @tycho.ShaderStage::Vertex)
let frag = @tycho.compile_glsl("shader.frag", @tycho.ShaderStage::Fragment)
// Also available: compile_glsl_source, compile_slang, load_spirv, reflect_spirv

// Auto-reflected descriptors, push constants, and vertex attributes:
let pipe = dev.create_graphics_pipeline(
  @tycho.PipelineDesc::from_spirv(
    vert,
    frag,
    color_format=Some(@tycho.TextureFormat::RGBA16F),
    depth_test=true,
    depth_write=true,
    depth_format=Some(@tycho.TextureFormat::Depth32F),
    cull_mode=@tycho.CullMode::Back,
  ),
)
```

For explicit slot counts/layouts, construct `@tycho.PipelineDesc::new(...)` with `vertex_layouts` (`VertexBufferLayout::new`, `VertexAttribute::new`), `uniform_slots`, `texture_slots`, `storage_slots`, `storage_image_slots`, `push_constant_size`, `blend_mode`, and `color_formats` (for MRT).

- **Compute**: `dev.create_compute_pipeline_auto(comp_spv)` or `dev.create_compute_pipeline(...)`.
- **Mesh Shaders** (when `caps.supports_mesh_shader`): `dev.create_mesh_pipeline(@tycho.MeshPipelineDesc::new(mesh, frag, task=...))`.

## 3. Buffers, Textures, Samplers & Images

- **Buffers**:
  - `dev.create_buffer_with(bytes, @tycho.BufferKind::Vertex, location=@tycho.MemoryLocation::GpuOnly)` (`Index`, `Uniform`, `Storage`, `Staging`, `Indirect`; `CpuToGpu`, `GpuToCpu`).
  - Upload/download: `buf.upload_floats(arr, offset=0, count=-1)`, `buf.upload_mat4(m, offset=0)`, `buf.upload_uint16`, `buf.upload_uint32`, `buf.upload_bytes`, `buf.download()`, `buf.size()` (`count` uploads a leading slice when `>= 0`).
- **Textures**:
  - 2D / Mipmapped / Layered: `create_texture_format`, `create_texture_mipmapped`, `create_cubemap`, `create_texture_array`.
  - Targets & Compute: `create_render_target`, `create_depth_texture`, `create_depth_texture_format` (`Depth32F` or `Depth24Stencil8`), `create_storage_texture`.
  - Readback / PNG / HDR: `tex.readback()`, `tex.readback_mip(level)`, `@tycho.save_png(path, w, h, pixels)`, `@tycho.load_image(path)`, `@tycho.load_hdr_image(path)` (returns `(FixedArray[Float], Int, Int)` RGBA float pixels from Radiance `.hdr` RGBE).
- **Samplers**:
  - `@tycho.SamplerDesc::new(mag=Filter::Linear, min=Filter::Linear, mipmap=Filter::Linear, address=AddressMode::ClampToEdge, anisotropy=8.0, compare_op=Some(CompareOp::LessEqual))` + `dev.create_sampler_desc(desc)`.

## 4. Command Recording, Offscreen Passes & Sync

```moonbit
let ts = dev.create_timestamp_pool(2)
let fence = dev.create_fence(false)
let cmd = dev.begin_commands()
cmd.reset_timestamps(ts)
cmd.write_timestamp(ts, 0, at_start=true)

cmd.begin_render_pass(
  [@tycho.RenderTargetDesc::new(hdr_rt, load_op=@tycho.LoadOp::Clear, store_op=@tycho.StoreOp::Store, clear_color=@tycho.ClearColor::black())],
  depth=Some(@tycho.DepthTargetDesc::new(depth_tex, load_op=@tycho.LoadOp::Clear, store_op=@tycho.StoreOp::DontCare)),
)
cmd.set_viewport(0.0, 0.0, 800.0, 600.0)
cmd.set_scissor(0, 0, 800, 600)
cmd.bind_pipeline(pipe)
cmd.bind_vertex(0, vbuf)
cmd.bind_index(ibuf, @tycho.IndexType::Uint32)
cmd.bind_uniform(pipe, 0, ubo)
cmd.bind_texture(pipe, 0, shadow_tex, shadow_sampler)
cmd.push_constants_floats(pipe, pc)
cmd.draw_indexed(index_count, instances=1)
cmd.end_render_pass()

cmd.transition_for_sampling(hdr_rt)
cmd.write_timestamp(ts, 1)
dev.submit_commands(cmd, fence)
fence.wait() // flushes generation-eligible deferred deletions
let gpu_ms = ts.elapsed_ms(0, 1)
```

Additional commands: `draw_instanced`, `draw_indirect`, `draw_indexed_indirect`, `draw_indirect_count`, `draw_indexed_indirect_count`, `dispatch`, `dispatch_indirect`, `draw_mesh_tasks`, `draw_mesh_tasks_indirect`, `set_stencil_reference`, `bind_accel_struct`, `bind_bindless_heap`, `copy_buffer`, `blit_texture`, `blit_to_swapchain`, `barrier`.

### Inline Ray Query (BLAS / TLAS)

```moonbit
if dev.capabilities().supports_ray_query {
  let blas = dev.create_blas([
    @tycho.RayGeometryDesc::new(vbuf, vertex_count, index_buffer=Some(ibuf), index_count=index_count),
  ])
  let tlas = dev.create_tlas([@tycho.RayInstanceDesc::new(blas)])
  // In compute/fragment shader: layout(binding = 0) uniform accelerationStructureEXT tlas;
  let pipe = dev.create_compute_pipeline_auto(comp_spv)
  let cmd = dev.begin_commands()
  cmd.bind_pipeline(pipe)
  cmd.bind_accel_struct(pipe, 0, tlas)
  cmd.dispatch(16, 16, 1)
  dev.end_commands(cmd)
  tlas.destroy()
  blas.destroy()
}
```

## 5. Key RHI Examples

| Example | Demonstrates |
|---|---|
| `08-rhi-triangle` – `13-rhi-sampler` | Core RHI triangle, UBO, vertex buffer, texture, compute, sampler |
| `38-rhi-3d-cube` | Perspective 3D cube + depth testing |
| `39-rhi-msaa-offscreen` | `SampleCount::X4` MSAA offscreen resolve + blit |
| `40-rhi-reflection-mipmaps` | SPIR-V auto-reflection, mipmaps, anisotropic filtering, `Depth24Stencil8` |
| `41-rhi-compute-storage-image` | Compute storage image + `TimestampPool` |
| `42-rhi-mrt-postprocess` | MRT G-buffer (`RGBA8` + normals + `Depth32F`) + post-process |
| `43-rhi-hardening` | `GpuOnly` buffers, deferred deletion, dynamic descriptor pool expansion |
| `44-rhi-pipeline-instancing` | Vertex/instance step modes, alpha blending, `Depth24Stencil8` |
| `45-rhi-textures-samplers` | Cubemaps, 2D texture arrays, mip readbacks, border samplers |
| `46-rhi-indirect-bindless` | Indirect draw/dispatch + `BindlessHeap` |
| `47-rhi-mesh` | `VK_EXT_mesh_shader` task + mesh pipeline (`SKIP` if unsupported) |
| `48-rhi-shadow-hdr` | Shadow mapping (`CompareOp::LessEqual`) + `RGBA16F` HDR + bloom |
| `49-rhi-pbr-showcase` | Flagship Cook-Torrance GGX PBR + Cubemap IBL + 3×3 PCF shadow + Bloom + ACES |
| `50-rhi-bench` | 500 allocs, 500 push-constant draws, 20-frame deferred deletion leak gate |
| `51-wayland-window` | Linux Wayland WSI (`xdg-shell` + `VK_KHR_wayland_surface`) |
| `52-rhi-rayquery-stencil` | `StencilState` + `set_stencil_reference`, `draw_indirect_count`, Inline Ray Query (`create_blas`/`create_tlas`) |
| `53-rhi-2d-sdf-batch` | 2D per-corner SDF rounded rects, procedural icon atlas, hardware `set_scissor` clipping, and 30f × 2,000-quad ring-SSBO benchmark |
| `54-tycho-2d-showcase` | `laplaceliu/tycho_2d` showcase: gradients, TrueType/built-in paragraphs, Stencil-then-Cover paths, `save_layer`, and `BackdropFilter` blur |
| `55-tycho-ui-gallery` | `laplaceliu/tycho_ui` declarative UI showcase: three trees, `Signal[T]`, Dark/Light theme, `TextField`, `frosted_dialog`, and 100K virtual `ListView` |
| `73-win32-window` | Windows Win32 WSI (`user32.dll` + `VK_KHR_win32_surface`), fullscreen-resize swapchain recreation, clipboard, DPI `content_scale` |
| `74-dx12-triangle` | Direct3D 12 raw binding: device + command list + DXIL PSO + offscreen RTV + readback, on hardware or WARP |
