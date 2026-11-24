// Example 13 — RHI sampler state: nearest vs linear on a 2x2 checker.
// Default headless offscreen verification; pass `--window` (or TYCHO_WINDOW=1) for screen rendering.

///|
fn centre_green(pixels : FixedArray[Byte]) -> Int {
  pixels[(300 * 800 + 400) * 4 + 1].to_int()
}

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
      @tycho.DeviceDesc::new("Tycho RHI Sampler", validation=true, headless=!show_win),
    )
    let vert = @tycho.compile_glsl(
      "examples/13-rhi-sampler/shader.vert",
      @tycho.ShaderStage::Vertex,
    )
    let frag = @tycho.compile_glsl(
      "examples/13-rhi-sampler/shader.frag",
      @tycho.ShaderStage::Fragment,
    )
    let checker : Bytes = Bytes::from_array([
      0, 0, 0, 255, 255, 255, 255, 255,
      255, 255, 255, 255, 0, 0, 0, 255,
    ])
    let tex = dev.create_texture(2, 2, checker)
    let nearest = dev.create_sampler_desc(
      @tycho.SamplerDesc::new(
        mag=@tycho.Filter::Nearest,
        min=@tycho.Filter::Nearest,
        address=@tycho.AddressMode::ClampToEdge,
      ),
    )
    let linear = dev.create_sampler_desc(
      @tycho.SamplerDesc::new(
        mag=@tycho.Filter::Linear,
        min=@tycho.Filter::Linear,
        address=@tycho.AddressMode::ClampToEdge,
      ),
    )
    let mut g_nearest = 0
    let mut g_linear = 0
    if show_win {
      let sc = dev.create_swapchain_desc(
        @tycho.SwapchainDesc::new("Tycho RHI Sampler", 800, 600, enable_readback=true),
      )
      let pipe = sc.create_pipeline_desc(
        @tycho.PipelineDesc::new(vert, frag, texture_slots=1),
      )
      for phase = 0; phase < 2; phase = phase + 1 {
        let samp = if phase == 0 { nearest } else { linear }
        let cmd = sc.begin_frame()
        cmd.bind_pipeline(pipe)
        cmd.bind_texture(pipe, 0, tex, samp)
        cmd.draw(6, 1)
        sc.end_frame(cmd)
        let px = sc.readback()
        let g = centre_green(px)
        if phase == 0 {
          g_nearest = g
        } else {
          g_linear = g
          if shot != "" {
            let _ = @tycho.save_png(
              shot,
              800,
              600,
              px,
              bgra=sc.color_format() == @tycho.TextureFormat::BGRA8,
            )
          }
        }
      }
      while !should_quit(sc) {
        let cmd = sc.begin_frame()
        cmd.bind_pipeline(pipe)
        cmd.bind_texture(pipe, 0, tex, linear)
        cmd.draw(6, 1)
        sc.end_frame(cmd)
      }
      pipe.destroy()
      sc.destroy()
    } else {
      let rt = dev.create_render_target(800, 600, @tycho.TextureFormat::RGBA8)
      let pipe = dev.create_graphics_pipeline(
        @tycho.PipelineDesc::new(
          vert,
          frag,
          texture_slots=1,
          color_format=Some(@tycho.TextureFormat::RGBA8),
        ),
      )
      for phase = 0; phase < 2; phase = phase + 1 {
        let samp = if phase == 0 { nearest } else { linear }
        let cmd = dev.begin_commands()
        cmd.begin_render_pass([@tycho.RenderTargetDesc::new(rt)])
        cmd.bind_pipeline(pipe)
        cmd.bind_texture(pipe, 0, tex, samp)
        cmd.draw(6, 1)
        cmd.end_render_pass()
        dev.end_commands(cmd)
        let px = rt.readback()
        let g = centre_green(px)
        if phase == 0 {
          g_nearest = g
        } else {
          g_linear = g
          if shot != "" {
            let _ = @tycho.save_png(shot, 800, 600, px)
          }
        }
      }
      pipe.destroy()
      rt.destroy()
    }
    let errs = dev.validation_errors()
    linear.destroy()
    nearest.destroy()
    tex.destroy()
    dev.destroy()
    println(
      "[13-rhi-sampler] centre green: nearest=\{g_nearest}, linear=\{g_linear}",
    )
    let linear_ok = (g_linear >= 124 && g_linear <= 131) ||
      (g_linear >= 184 && g_linear <= 191)
    if g_nearest < 30 && linear_ok && errs == 0 {
      println("[13-rhi-sampler] OK — sampler state changed the sampled result (0 validation errors)")
    } else {
      println("[13-rhi-sampler] FAIL — g_nearest=\{g_nearest} g_linear=\{g_linear} errs=\{errs}")
    }
  } catch {
    err => println("[13-rhi-sampler] FAIL — \{err}")
  }
}
