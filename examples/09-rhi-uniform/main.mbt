// Example 09 — RHI slot binding: a uniform slot tints the triangle.
// Default headless offscreen verification; pass `--window` (or TYCHO_WINDOW=1) for screen rendering.

///|
fn should_quit(sc : @tycho.Swapchain) -> Bool {
  if sc.should_close() {
    return true
  }
  for ev in sc.poll_events() {
    match ev {
      @tycho.Event::KeyDown(k, _) => if k == @tycho.KEY_ESCAPE { return true }
      _ => ()
    }
  }
  false
}

///|
fn main {
  try {
    let show_win = @tycho.want_window()
    let shot = @tycho.screenshot_path()
    let dev = @tycho.Device::new_desc(
      @tycho.DeviceDesc::new("Tycho RHI Uniform", validation=true, headless=!show_win),
    )
    let vert = @tycho.compile_glsl(
      "examples/09-rhi-uniform/shader.vert",
      @tycho.ShaderStage::Vertex,
    )
    let frag = @tycho.compile_glsl(
      "examples/09-rhi-uniform/shader.frag",
      @tycho.ShaderStage::Fragment,
    )
    let ubo = dev.create_buffer(16, @tycho.BufferKind::Uniform)
    ubo.upload_floats([(0.2 : Float), (0.8 : Float), (0.4 : Float), (1.0 : Float)])
    let mut pixels : FixedArray[Byte] = []
    let mut frames = 0
    if show_win {
      let sc = dev.create_swapchain_desc(
        @tycho.SwapchainDesc::new("Tycho RHI Uniform", 800, 600, enable_readback=true),
      )
      let pipe = sc.create_pipeline(vert, frag, 1)
      while !should_quit(sc) {
        let cmd = sc.begin_frame()
        cmd.bind_pipeline(pipe)
        cmd.bind_uniform(pipe, 0, ubo)
        cmd.draw(3, 1)
        sc.end_frame(cmd)
        if frames == 0 {
          pixels = sc.readback()
          if shot != "" {
            let _ = @tycho.save_png(
              shot,
              800,
              600,
              pixels,
              bgra=sc.color_format() == @tycho.TextureFormat::BGRA8,
            )
          }
        }
        frames = frames + 1
      }
      pipe.destroy()
      sc.destroy()
    } else {
      let rt = dev.create_render_target(800, 600, @tycho.TextureFormat::RGBA8)
      let pipe = dev.create_graphics_pipeline(
        @tycho.PipelineDesc::new(
          vert,
          frag,
          uniform_slots=1,
          color_format=Some(@tycho.TextureFormat::RGBA8),
        ),
      )
      let cmd = dev.begin_commands()
      cmd.begin_render_pass([@tycho.RenderTargetDesc::new(rt)])
      cmd.bind_pipeline(pipe)
      cmd.bind_uniform(pipe, 0, ubo)
      cmd.draw(3, 1)
      cmd.end_render_pass()
      dev.end_commands(cmd)
      pixels = rt.readback()
      frames = 1
      if shot != "" {
        let _ = @tycho.save_png(shot, 800, 600, pixels)
      }
      pipe.destroy()
      rt.destroy()
    }
    let centre = (300 * 800 + 400) * 4
    let c0 = pixels[centre].to_int()
    let g = pixels[centre + 1].to_int()
    let c2 = pixels[centre + 2].to_int()
    let errs = dev.validation_errors()
    ubo.destroy()
    dev.destroy()
    println(
      "[09-rhi-uniform] centre channels=(\{c0}, \{g}, \{c2}), frames=\{frames}",
    )
    if g > 150 && g > c0 && g > c2 && errs == 0 {
      println("[09-rhi-uniform] OK — uniform slot tinted the triangle (0 validation errors)")
    } else {
      println("[09-rhi-uniform] FAIL — g=\{g} c0=\{c0} c2=\{c2} errs=\{errs}")
    }
  } catch {
    err => println("[09-rhi-uniform] FAIL — \{err}")
  }
}
