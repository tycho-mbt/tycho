// rhi/hardening — RHI v0.3 hardening regression suite:
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

    // upload_mat4 equivalence: rotation + non-uniform scale + translation, so a
    // row/column-major mix-up cannot hide behind a symmetric identity matrix.
    let mat_buf = dev_h.create_buffer_with(
      64,
      @tycho.BufferKind::Storage,
      location=@tycho.MemoryLocation::GpuOnly,
    )
    let probe_mat = @tmath.Mat4::from_scale_rotation_translation(
      @tmath.Vec3::new(2.0, 0.5, 3.0),
      @tmath.Quat::from_axis_angle(@tmath.Vec3::new(0.3, 1.0, -0.2), 0.7),
      @tmath.Vec3::new(4.0, -2.0, 1.5),
    )
    mat_buf.upload_mat4(probe_mat)
    let mat_bytes = mat_buf.download()
    let mat_want = probe_mat.to_cols_array()
    let mut mat_ok = true
    for i = 0; i < 16; i = i + 1 {
      if float_at(mat_bytes, i) != mat_want[i] {
        mat_ok = false
      }
    }
    mat_buf.destroy()

    // Deferred deletion across submit_commands + Fence::wait() without wait_idle()
    let async_buf = dev_h.create_buffer_with(256, @tycho.BufferKind::Storage)
    async_buf.upload_floats([(1.0 : Float), (2.0 : Float), (3.0 : Float), (4.0 : Float)])
    let fence = dev_h.create_fence(false)
    let acmd = dev_h.begin_commands()
    acmd.barrier()
    dev_h.submit_commands(acmd, fence)
    // Destroy while submitted work is still tracked against submitted_gen
    async_buf.destroy()
    let before_wait = dev_h.allocator_used_bytes()
    fence.wait()
    let after_wait = dev_h.allocator_used_bytes()
    fence.destroy()
    let async_del_ok = before_wait > (0 : UInt64) && after_wait == (0 : UInt64)

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

    // 2. Dynamic descriptor pool expansion (40+ draws in 1 frame): headless by default, `--window` for screen
    let opts = @exwin.Options::parse("rhi/hardening")
    let show_win = opts.window
    let dev = @tycho.Device::new_desc(
      @tycho.DeviceDesc::new("Tycho RHI Hardening", validation=true, headless=!show_win),
    )
    let vert = @tycho.compile_glsl(
      "examples/rhi/hardening/shader.vert",
      @tycho.ShaderStage::Vertex,
    )
    let frag = @tycho.compile_glsl(
      "examples/rhi/hardening/shader.frag",
      @tycho.ShaderStage::Fragment,
    )

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
    let mut scale = 1.0
    let mut is_fs = false
    let keys_ok = @tycho.KEY_W != 0 && @tycho.KEY_F1 != 0 && @tycho.KEY_LSHIFT != 0
    let mut is_bgra = false
    if show_win {
      let sc = @exwin_rhi.open(dev, opts, present_mode=@tycho.PresentMode::Mailbox)
      is_bgra = sc.color_format() == @tycho.TextureFormat::BGRA8
      let pipe = sc.create_pipeline(vert, frag, 1)
      scale = sc.content_scale()
      is_fs = sc.is_fullscreen()
      sc.set_cursor_mode(@tycho.CursorMode::Hidden)
      sc.set_cursor_mode(@tycho.CursorMode::Normal)
      let mut f = 0
      while @exwin_rhi.next_frame(sc) {
        let transient = dev.create_buffer(128, @tycho.BufferKind::Uniform)
        transient.destroy()
        let inflight_ubo = dev.create_buffer(64, @tycho.BufferKind::Uniform)
        inflight_ubo.upload_floats([(0.0 : Float), (0.9 : Float), (0.1 : Float), (1.0 : Float)])
        let cmd = sc.begin_frame_commands()
        cmd.begin_swapchain_pass(sc)
        cmd.bind_pipeline(pipe)
        for i = 0; i < 40; i = i + 1 {
          cmd.bind_uniform(pipe, 0, ubos[i])
          cmd.draw(3, 1)
        }
        cmd.bind_uniform(pipe, 0, inflight_ubo)
        cmd.draw(3, 1)
        cmd.end_swapchain_pass()
        sc.end_frame(cmd)
        inflight_ubo.destroy()
        if f == 0 {
          pixels = sc.readback()
          @exwin_rhi.capture(opts, sc, pixels)
        }
        f = f + 1
      }
      pipe.destroy()
      sc.destroy()
    } else {
      let rt = dev.create_render_target(400, 300, @tycho.TextureFormat::RGBA8)
      let pipe = dev.create_graphics_pipeline(
        @tycho.PipelineDesc::new(
          vert,
          frag,
          uniform_slots=1,
          color_format=Some(@tycho.TextureFormat::RGBA8),
        ),
      )
      for f = 0; f < 6; f = f + 1 {
        let transient = dev.create_buffer(128, @tycho.BufferKind::Uniform)
        transient.destroy()
        let inflight_ubo = dev.create_buffer(64, @tycho.BufferKind::Uniform)
        inflight_ubo.upload_floats([(0.0 : Float), (0.9 : Float), (0.1 : Float), (1.0 : Float)])
        let fence = dev.create_fence(false)
        let cmd = dev.begin_commands()
        cmd.begin_render_pass([@tycho.RenderTargetDesc::new(rt)])
        cmd.bind_pipeline(pipe)
        for i = 0; i < 40; i = i + 1 {
          cmd.bind_uniform(pipe, 0, ubos[i])
          cmd.draw(3, 1)
        }
        cmd.bind_uniform(pipe, 0, inflight_ubo)
        cmd.draw(3, 1)
        cmd.end_render_pass()
        dev.submit_commands(cmd, fence)
        inflight_ubo.destroy()
        fence.wait()
        fence.destroy()
        if f == 0 {
          pixels = rt.readback()
          opts.capture(400, 300, pixels)
        }
      }
      pipe.destroy()
      rt.destroy()
    }

    let c = (150 * 400 + 200) * 4
    let (r, g, b) = if is_bgra {
      (pixels[c + 2].to_int(), pixels[c + 1].to_int(), pixels[c].to_int())
    } else {
      (pixels[c].to_int(), pixels[c + 1].to_int(), pixels[c + 2].to_int())
    }
    let draw40_ok = g > 200 && r < 50 && b < 70

    for u in ubos {
      u.destroy()
    }
    let errs = dev.validation_errors()
    dev.wait_idle()
    let used_after_wait = dev.allocator_used_bytes()
    dev.destroy()

    println(
      "[rhi/hardening] device=\"\{caps.device_name}\" max2d=\{caps.max_image_dimension_2d} msaa=\{caps.max_framebuffer_samples} bindless=\{caps.supports_bindless} mesh=\{caps.supports_mesh_shader} rq=\{caps.supports_ray_query} rgb=(\{r},\{g},\{b}) scale=\{scale} used=\{used_after_wait}",
    )
    if caps_ok &&
      gpu_buf_ok &&
      mat_ok &&
      async_del_ok &&
      headless_clean &&
      draw40_ok &&
      scale > 0.0 &&
      !is_fs &&
      keys_ok &&
      used_after_wait == (0 : UInt64) &&
      errs == 0 {
      println(
        "[rhi/hardening] OK — headless, GpuOnly+offset+upload_mat4, submit+fence deferred deletion, in-flight UBO destroy, cursor/keys, and 40-draw expansion passed (0 validation errors)",
      )
    } else {
      println(
        "[rhi/hardening] FAIL — caps=\{caps_ok} gpu_buf=\{gpu_buf_ok} mat4=\{mat_ok} async_del=\{async_del_ok} headless=\{headless_clean} draw40=\{draw40_ok} scale=\{scale} fs=\{is_fs} keys=\{keys_ok} used=\{used_after_wait} errs=\{errs}",
      )
    }
  } catch {
    err => println("[rhi/hardening] FAIL — \{err}")
  }
}
