// rhi/texture — RHI texture/sampler slot: a sampled texture fills the quad.
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
      @tycho.DeviceDesc::new("Tycho RHI Texture", validation=true, headless=!show_win),
    )
    let vert = @tycho.compile_glsl(
      "examples/rhi/texture/shader.vert",
      @tycho.ShaderStage::Vertex,
    )
    let frag = @tycho.compile_glsl(
      "examples/rhi/texture/shader.frag",
      @tycho.ShaderStage::Fragment,
    )
    let magenta : Bytes = Bytes::from_array([
      255, 0, 255, 255, 255, 0, 255, 255,
      255, 0, 255, 255, 255, 0, 255, 255,
    ])
    let tex = dev.create_texture(2, 2, magenta)
    let samp = dev.create_sampler()
    let mut pixels : FixedArray[Byte] = []
    let mut frames = 0
    let mut is_bgra = false
    if show_win {
      let sc = dev.create_swapchain_desc(
        @tycho.SwapchainDesc::new("rhi/texture", 800, 600, enable_readback=true),
      )
      is_bgra = sc.color_format() == @tycho.TextureFormat::BGRA8
      let pipe = sc.create_pipeline_desc(
        @tycho.PipelineDesc::new(vert, frag, texture_slots=1),
      )
      while !should_quit(sc) {
        let cmd = sc.begin_frame()
        cmd.bind_pipeline(pipe)
        cmd.bind_texture(pipe, 0, tex, samp)
        cmd.draw(6, 1)
        sc.end_frame(cmd)
        if frames == 0 {
          pixels = sc.readback()
          if shot != "" {
            let _ = @tycho.save_png(shot, 800, 600, pixels, bgra=is_bgra)
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
          texture_slots=1,
          color_format=Some(@tycho.TextureFormat::RGBA8),
        ),
      )
      let cmd = dev.begin_commands()
      cmd.begin_render_pass([@tycho.RenderTargetDesc::new(rt)])
      cmd.bind_pipeline(pipe)
      cmd.bind_texture(pipe, 0, tex, samp)
      cmd.draw(6, 1)
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
    let i = (300 * 800 + 400) * 4
    let (r, g, b) = if is_bgra {
      (pixels[i + 2].to_int(), pixels[i + 1].to_int(), pixels[i].to_int())
    } else {
      (pixels[i].to_int(), pixels[i + 1].to_int(), pixels[i + 2].to_int())
    }
    let errs = dev.validation_errors()
    samp.destroy()
    tex.destroy()
    dev.destroy()
    println("[rhi/texture] centre RGB = (\{r}, \{g}, \{b}), frames=\{frames}")
    if r > 200 && b > 200 && g < 60 && errs == 0 {
      println("[rhi/texture] OK — texture slot sampled the uploaded image (0 validation errors)")
    } else {
      println("[rhi/texture] FAIL — validation_errors=\{errs}")
    }
  } catch {
    err => println("[rhi/texture] FAIL — \{err}")
  }
}
