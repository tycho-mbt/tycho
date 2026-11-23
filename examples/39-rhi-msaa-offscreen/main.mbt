// Example 39 — Offscreen 4x MSAA render pass + resolve + swapchain blit.
// Verifies anti-aliased edge coverage pixels (20 < v < 235) exist in the
// resolved single-sample texture, then presents it to the window.

///|
fn main {
  try {
    let dev = @rhi.Device::new("Tycho RHI MSAA Offscreen", true)
    let sc = dev.create_swapchain("Tycho RHI MSAA Offscreen", 800, 600)

    let msaa_tex = dev.create_render_target(
      256,
      256,
      @rhi.TextureFormat::RGBA8,
      samples=@rhi.SampleCount::X4,
    )
    let resolve_tex = dev.create_render_target(
      256,
      256,
      @rhi.TextureFormat::RGBA8,
      samples=@rhi.SampleCount::X1,
    )

    let tri_vert = @rhi.compile_glsl(
      "examples/39-rhi-msaa-offscreen/tri.vert",
      @rhi.ShaderStage::Vertex,
    )
    let tri_frag = @rhi.compile_glsl(
      "examples/39-rhi-msaa-offscreen/tri.frag",
      @rhi.ShaderStage::Fragment,
    )
    let off_pipe = dev.create_graphics_pipeline(
      @rhi.PipelineDesc::new(
        tri_vert,
        tri_frag,
        samples=@rhi.SampleCount::X4,
        color_format=Some(@rhi.TextureFormat::RGBA8),
      ),
    )

    let quad_vert = @rhi.compile_glsl(
      "examples/39-rhi-msaa-offscreen/quad.vert",
      @rhi.ShaderStage::Vertex,
    )
    let quad_frag = @rhi.compile_glsl(
      "examples/39-rhi-msaa-offscreen/quad.frag",
      @rhi.ShaderStage::Fragment,
    )
    let present_pipe = sc.create_pipeline_desc(
      @rhi.PipelineDesc::new(quad_vert, quad_frag, texture_slots=1),
    )
    let samp = dev.create_sampler()

    // Render diagonal triangle into 4x MSAA offscreen target and resolve
    let off_cmd = dev.begin_commands()
    off_cmd.begin_render_pass([
      @rhi.RenderTargetDesc::new(
        msaa_tex,
        load_op=@rhi.LoadOp::Clear,
        store_op=@rhi.StoreOp::DontCare,
        clear_color=@rhi.ClearColor::black(),
        resolve_texture=Some(resolve_tex),
      ),
    ])
    off_cmd.bind_pipeline(off_pipe)
    off_cmd.draw(3, 1)
    off_cmd.end_render_pass()
    dev.end_commands(off_cmd)

    let resolved = resolve_tex.readback()
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

    // Blit resolved offscreen texture onto the window swapchain
    let start = @rhi.Swapchain::time()
    let mut frames = 0
    while !sc.should_close() && frames < 10 && @rhi.Swapchain::time() - start < 0.8 {
      let cmd = sc.begin_frame()
      cmd.bind_pipeline(present_pipe)
      cmd.bind_texture(present_pipe, 0, resolve_tex, samp)
      cmd.draw(6, 1)
      sc.end_frame(cmd)
      frames = frames + 1
    }

    let errs = dev.validation_errors()
    samp.destroy()
    present_pipe.destroy()
    off_pipe.destroy()
    resolve_tex.destroy()
    msaa_tex.destroy()
    sc.destroy()
    dev.destroy()
    println(
      "[39-rhi-msaa-offscreen] white=\{white} black=\{black} partial_aa=\{partial} frames=\{frames}",
    )
    if white > 100 && black > 100 && partial > 5 && errs == 0 {
      println(
        "[39-rhi-msaa-offscreen] OK — 4x MSAA offscreen resolve produced \{partial} anti-aliased edge pixels, 0 validation errors",
      )
    } else {
      println(
        "[39-rhi-msaa-offscreen] FAIL — white=\{white} black=\{black} partial=\{partial} errs=\{errs}",
      )
    }
  } catch {
    err => println("[39-rhi-msaa-offscreen] FAIL — \{err}")
  }
}
