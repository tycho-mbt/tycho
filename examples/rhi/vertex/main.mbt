// rhi/vertex — RHI vertex-buffer slot: per-vertex position + colour attributes.
// Default headless offscreen verification; pass `--window` (or TYCHO_WINDOW=1) for screen rendering.

///|
fn rgb_at(
  pixels : FixedArray[Byte],
  x : Int32,
  y : Int32,
  bgra : Bool,
) -> (Int32, Int32, Int32) {
  let i = (y * 800 + x) * 4
  if bgra {
    (pixels[i + 2].to_int(), pixels[i + 1].to_int(), pixels[i].to_int())
  } else {
    (pixels[i].to_int(), pixels[i + 1].to_int(), pixels[i + 2].to_int())
  }
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
      @tycho.DeviceDesc::new(
        "Tycho RHI Vertex",
        validation=true,
        headless=!show_win,
      ),
    )
    let vert = @tycho.compile_glsl(
      "examples/rhi/vertex/shader.vert",
      @tycho.ShaderStage::Vertex,
    )
    let frag = @tycho.compile_glsl(
      "examples/rhi/vertex/shader.frag",
      @tycho.ShaderStage::Fragment,
    )
    let vbuf = dev.create_buffer(60, @tycho.BufferKind::Vertex)
    vbuf.upload_floats([
      (0.0 : Float),
      (-0.5 : Float),
      (1.0 : Float),
      (0.0 : Float),
      (0.0 : Float),
      (0.5 : Float),
      (0.5 : Float),
      (0.0 : Float),
      (1.0 : Float),
      (0.0 : Float),
      (-0.5 : Float),
      (0.5 : Float),
      (0.0 : Float),
      (0.0 : Float),
      (1.0 : Float),
    ])
    let mut pixels : FixedArray[Byte] = []
    let mut is_bgra = false
    if show_win {
      let sc = dev.create_swapchain_desc(
        @tycho.SwapchainDesc::new(
          "rhi/vertex",
          800,
          600,
          enable_readback=true,
        ),
      )
      is_bgra = sc.color_format() == @tycho.TextureFormat::BGRA8
      let pipe = sc.create_pipeline_desc(
        @tycho.PipelineDesc::new(vert, frag, vertex_formats=[
          @tycho.VertexFormat::Float2,
          @tycho.VertexFormat::Float3,
        ]),
      )
      let mut frames = 0
      while !should_quit(sc) {
        let cmd = sc.begin_frame()
        cmd.bind_pipeline(pipe)
        cmd.bind_vertex(0, vbuf)
        cmd.draw(3, 1)
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
          vertex_formats=[
            @tycho.VertexFormat::Float2,
            @tycho.VertexFormat::Float3,
          ],
          color_format=Some(@tycho.TextureFormat::RGBA8),
        ),
      )
      let cmd = dev.begin_commands()
      cmd.begin_render_pass([@tycho.RenderTargetDesc::new(rt)])
      cmd.bind_pipeline(pipe)
      cmd.bind_vertex(0, vbuf)
      cmd.draw(3, 1)
      cmd.end_render_pass()
      dev.end_commands(cmd)
      pixels = rt.readback()
      if shot != "" {
        let _ = @tycho.save_png(shot, 800, 600, pixels)
      }
      pipe.destroy()
      rt.destroy()
    }
    let (r0, g0, b0) = rgb_at(pixels, 400, 180, is_bgra)
    let (r1, g1, b1) = rgb_at(pixels, 570, 430, is_bgra)
    let (r2, g2, b2) = rgb_at(pixels, 230, 430, is_bgra)
    let errs = dev.validation_errors()
    vbuf.destroy()
    dev.destroy()
    println(
      "[rhi/vertex] near-vertex RGB: (\{r0},\{g0},\{b0}) (\{r1},\{g1},\{b1}) (\{r2},\{g2},\{b2})",
    )
    if r0 > g0 &&
      r0 > b0 &&
      g1 > r1 &&
      g1 > b1 &&
      b2 > r2 &&
      b2 > g2 &&
      errs == 0 {
      println(
        "[rhi/vertex] OK — vertex slot delivered per-vertex colours (0 validation errors)",
      )
    } else {
      println("[rhi/vertex] FAIL — validation_errors=\{errs}")
    }
  } catch {
    err => println("[rhi/vertex] FAIL — \{err}")
  }
}
