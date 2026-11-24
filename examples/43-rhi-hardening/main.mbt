// Example 43 — RHI v0.3 hardening regression suite:
// 1. Headless DeviceDesc + Device::capabilities()
// 2. MemoryLocation::GpuOnly (DEVICE_LOCAL) buffer + offset uploads + download
// 3. Deferred deletion queue (zero vkDeviceWaitIdle on resource destroy)
// 4. Dynamic descriptor pool expansion (> 16 draws with distinct UBOs in one frame)

///|
fn float_at(data : Bytes, i : Int) -> Float {
  let bits = data[i * 4].to_int() |
    (data[i * 4 + 1].to_int() << 8) |
    (data[i * 4 + 2].to_int() << 16) |
    (data[i * 4 + 3].to_int() << 24)
  Float::reinterpret_from_int(bits)
}

///|
fn main {
  try {
    // 1. Headless device + capabilities + GpuOnly buffer with offset upload
    let dev_h = @tycho.Device::new_desc(
      @tycho.DeviceDesc::new("Tycho RHI Hardening Headless", validation=true, headless=true),
    )
    let caps = dev_h.capabilities()
    let caps_ok = caps.device_name != "" && caps.max_image_dimension_2d >= 4096

    let gpu_buf = dev_h.create_buffer_with(
      32,
      @tycho.BufferKind::Storage,
      location=@tycho.MemoryLocation::GpuOnly,
    )
    gpu_buf.upload_floats([(1.0 : Float), (2.0 : Float), (3.0 : Float), (4.0 : Float)], offset=0)
    gpu_buf.upload_floats([(5.0 : Float), (6.0 : Float), (7.0 : Float), (8.0 : Float)], offset=16)
    let dl = gpu_buf.download()
    let mut gpu_buf_ok = true
    for i = 0; i < 8; i = i + 1 {
      if float_at(dl, i) != Float::from_int(i + 1) {
        gpu_buf_ok = false
      }
    }
    gpu_buf.destroy()

    // Deferred deletion stress on headless device
    for i = 0; i < 30; i = i + 1 {
      let _ = i
      let tmp_b = dev_h.create_buffer(256, @tycho.BufferKind::Uniform)
      let tmp_t = dev_h.create_render_target(16, 16, @tycho.TextureFormat::RGBA8)
      tmp_b.destroy()
      tmp_t.destroy()
    }
    dev_h.wait_idle()
    let headless_clean = dev_h.allocator_used_bytes() == (0 : UInt64) &&
      dev_h.validation_errors() == 0
    dev_h.destroy()

    // 2. Windowed device + dynamic descriptor pool expansion (40 draws in 1 frame)
    let dev = @tycho.Device::new("Tycho RHI Hardening", true)
    let sc = dev.create_swapchain_desc(
      @tycho.SwapchainDesc::new(
        "Tycho RHI Hardening",
        400,
        300,
        enable_readback=true,
        present_mode=@tycho.PresentMode::Mailbox,
      ),
    )
    let vert = @tycho.compile_glsl(
      "examples/43-rhi-hardening/shader.vert",
      @tycho.ShaderStage::Vertex,
    )
    let frag = @tycho.compile_glsl(
      "examples/43-rhi-hardening/shader.frag",
      @tycho.ShaderStage::Fragment,
    )
    let pipe = sc.create_pipeline(vert, frag, 1)

    let ubos : Array[@tycho.Buffer] = []
    for i = 0; i < 40; i = i + 1 {
      let u = dev.create_buffer(16, @tycho.BufferKind::Uniform)
      if i == 39 {
        u.upload_floats([(0.1 : Float), (0.9 : Float), (0.2 : Float), (1.0 : Float)])
      } else {
        u.upload_floats([(0.9 : Float), (0.1 : Float), (0.1 : Float), (1.0 : Float)])
      }
      ubos.push(u)
    }

    let mut pixels : FixedArray[Byte] = []
    for f = 0; f < 4; f = f + 1 {
      // Create & destroy a transient buffer per frame to exercise deferred deletion across frames
      let transient = dev.create_buffer(128, @tycho.BufferKind::Uniform)
      transient.destroy()

      let cmd = sc.begin_frame_commands()
      cmd.begin_swapchain_pass(sc)
      cmd.bind_pipeline(pipe)
      for i = 0; i < 40; i = i + 1 {
        cmd.bind_uniform(pipe, 0, ubos[i])
        cmd.draw(3, 1)
      }
      cmd.end_swapchain_pass()
      sc.end_frame(cmd)
      if f == 0 {
        pixels = sc.readback()
      }
    }

    let c = (150 * 400 + 200) * 4
    let (r, g, b) = if sc.color_format() == @tycho.TextureFormat::BGRA8 {
      (pixels[c + 2].to_int(), pixels[c + 1].to_int(), pixels[c].to_int())
    } else {
      (pixels[c].to_int(), pixels[c + 1].to_int(), pixels[c + 2].to_int())
    }
    let draw40_ok = g > 200 && r < 50 && b < 70

    for u in ubos {
      u.destroy()
    }
    pipe.destroy()
    let errs = dev.validation_errors()
    sc.destroy()
    dev.wait_idle()
    let used_after_wait = dev.allocator_used_bytes()
    dev.destroy()

    println(
      "[43-rhi-hardening] device=\"\{caps.device_name}\" max2d=\{caps.max_image_dimension_2d} msaa=\{caps.max_framebuffer_samples} bindless=\{caps.supports_bindless} mesh=\{caps.supports_mesh_shader} rq=\{caps.supports_ray_query} rgb=(\{r},\{g},\{b}) used=\{used_after_wait}",
    )
    if caps_ok &&
      gpu_buf_ok &&
      headless_clean &&
      draw40_ok &&
      used_after_wait == (0 : UInt64) &&
      errs == 0 {
      println(
        "[43-rhi-hardening] OK — headless, GpuOnly+offset, deferred deletion, and 40-draw descriptor expansion passed (0 validation errors)",
      )
    } else {
      println(
        "[43-rhi-hardening] FAIL — caps=\{caps_ok} gpu_buf=\{gpu_buf_ok} headless=\{headless_clean} draw40=\{draw40_ok} used=\{used_after_wait} errs=\{errs}",
      )
    }
  } catch {
    err => println("[43-rhi-hardening] FAIL — \{err}")
  }
}
