// rhi/msaa-offscreen — Offscreen 4x MSAA render pass + resolve.
// Default headless verification; pass `--window` (or TYCHO_WINDOW=1) to present in a window.

///|
fn main {
  try {
    let opts = @exwin.Options::parse("rhi/msaa-offscreen")
    let show_win = opts.window
    let dev = @tycho.Device::new_desc(
      @tycho.DeviceDesc::new(
        "Tycho RHI MSAA Offscreen",
        validation=true,
        headless=!show_win,
      ),
    )

    let msaa_tex = dev.create_render_target(
      256,
      256,
      @tycho.TextureFormat::RGBA8,
      samples=@tycho.SampleCount::X4,
    )
    let resolve_tex = dev.create_render_target(
      256,
      256,
      @tycho.TextureFormat::RGBA8,
      samples=@tycho.SampleCount::X1,
    )

    let tri_vert = @tycho.compile_glsl(
      "examples/rhi/msaa-offscreen/tri.vert",
      @tycho.ShaderStage::Vertex,
    )
    let tri_frag = @tycho.compile_glsl(
      "examples/rhi/msaa-offscreen/tri.frag",
      @tycho.ShaderStage::Fragment,
    )
    let off_pipe = dev.create_graphics_pipeline(
      @tycho.PipelineDesc::new(
        tri_vert,
        tri_frag,
        samples=@tycho.SampleCount::X4,
        color_format=Some(@tycho.TextureFormat::RGBA8),
      ),
    )

    let off_cmd = dev.begin_commands()
    off_cmd.begin_render_pass([
      @tycho.RenderTargetDesc::new(
        msaa_tex,
        load_op=@tycho.LoadOp::Clear,
        store_op=@tycho.StoreOp::DontCare,
        clear_color=@tycho.ClearColor::black(),
        resolve_texture=Some(resolve_tex),
      ),
    ])
    off_cmd.bind_pipeline(off_pipe)
    off_cmd.draw(3, 1)
    off_cmd.end_render_pass()
    dev.end_commands(off_cmd)

    let resolved = resolve_tex.readback()
    opts.capture(256, 256, resolved)
    let mut white = 0
    let mut black = 0
    let mut partial = 0
    let n = 256 * 256
    for i = 0; i < n; i = i + 1 {
      let v = resolved[i * 4].to_int()
      if v > 240 {
        white = white + 1
      } else if v < 10 {
        black = black + 1
      } else if v >= 20 && v <= 235 {
        partial = partial + 1
      }
    }

    let mut frames = 0
    if show_win {
      let sc = @exwin_rhi.open(dev, opts)
      while @exwin_rhi.next_frame(sc) {
        sc.present_texture(resolve_tex)
        frames = frames + 1
      }
      sc.destroy()
    }

    let errs = dev.validation_errors()
    off_pipe.destroy()
    resolve_tex.destroy()
    msaa_tex.destroy()
    dev.destroy()
    println(
      "[rhi/msaa-offscreen] white=\{white} black=\{black} partial_aa=\{partial} frames=\{frames}",
    )
    if white > 100 && black > 100 && partial > 5 && errs == 0 {
      println(
        "[rhi/msaa-offscreen] OK — 4x MSAA offscreen resolve produced \{partial} anti-aliased edge pixels, 0 validation errors",
      )
    } else {
      println(
        "[rhi/msaa-offscreen] FAIL — white=\{white} black=\{black} partial=\{partial} errs=\{errs}",
      )
    }
  } catch {
    err => println("[rhi/msaa-offscreen] FAIL — \{err}")
  }
}
