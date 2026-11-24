// Example 08 — RHI triangle. Default headless offscreen verification; pass `--window`
// (or TYCHO_WINDOW=1) to open an interactive window.

///|
fn count_rgb(pixels : FixedArray[Byte]) -> Int {
  let mut n = 0
  let mut i = 0
  while i + 3 < pixels.length() {
    if pixels[i] != (0 : Byte) ||
      pixels[i + 1] != (0 : Byte) ||
      pixels[i + 2] != (0 : Byte) {
      n = n + 1
    }
    i = i + 4
  }
  n
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
      @tycho.DeviceDesc::new("Tycho RHI Triangle", validation=true, headless=!show_win),
    )
    let vert = @tycho.compile_glsl(
      "examples/08-rhi-triangle/shader.vert",
      @tycho.ShaderStage::Vertex,
    )
    let frag = @tycho.compile_glsl(
      "examples/08-rhi-triangle/shader.frag",
      @tycho.ShaderStage::Fragment,
    )
    let mut pixels = 0
    let mut frames = 0
    if show_win {
      let sc = dev.create_swapchain_desc(
        @tycho.SwapchainDesc::new("08-rhi-triangle", 800, 600, enable_readback=true),
      )
      let pipe = sc.create_pipeline(vert, frag, 0)
      while !should_quit(sc) {
        let cmd = sc.begin_frame()
        cmd.bind_pipeline(pipe)
        cmd.draw(3, 1)
        sc.end_frame(cmd)
        if frames == 0 {
          let px = sc.readback()
          pixels = count_rgb(px)
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
          color_format=Some(@tycho.TextureFormat::RGBA8),
        ),
      )
      let cmd = dev.begin_commands()
      cmd.begin_render_pass([@tycho.RenderTargetDesc::new(rt)])
      cmd.bind_pipeline(pipe)
      cmd.draw(3, 1)
      cmd.end_render_pass()
      dev.end_commands(cmd)
      let px = rt.readback()
      pixels = count_rgb(px)
      frames = 1
      if shot != "" {
        let _ = @tycho.save_png(shot, 800, 600, px)
      }
      pipe.destroy()
      rt.destroy()
    }
    let errs = dev.validation_errors()
    dev.destroy()
    if pixels > 0 && errs == 0 {
      println(
        "[08-rhi-triangle] OK — RHI triangle rendered (\{pixels} RGB pixels, \{frames} frames, 0 validation errors)",
      )
    } else {
      println(
        "[08-rhi-triangle] FAIL — pixels=\{pixels} validation_errors=\{errs}",
      )
    }
  } catch {
    err => println("[08-rhi-triangle] FAIL — \{err}")
  }
}
