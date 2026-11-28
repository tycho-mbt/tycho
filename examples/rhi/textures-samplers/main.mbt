// rhi/textures-samplers — RHI v0.4 texture formats, cubemap, subregion upload, blit, and sampler extensions.

///|
fn solid_rgba(
  r : Int32,
  g : Int32,
  b : Int32,
  a : Int32,
  pixels : Int32,
) -> Bytes {
  Bytes::makei(pixels * 4, fn(i) {
    let ch = i % 4
    if ch == 0 {
      r.to_byte()
    } else if ch == 1 {
      g.to_byte()
    } else if ch == 2 {
      b.to_byte()
    } else {
      a.to_byte()
    }
  })
}

///|
fn main {
  try {
    let opts = @exwin.Options::parse("rhi/textures-samplers")
    let show_win = opts.window
    let dev = @tycho.Device::new_desc(
      @tycho.DeviceDesc::new(
        "Tycho RHI Textures",
        validation=true,
        headless=!show_win,
      ),
    )

    // 1. Cubemap: +X=red, -X=cyan, +Y=green, -Y=magenta, +Z=blue, -Z=yellow
    let cube = dev.create_cubemap(4, @tycho.TextureFormat::RGBA8, [
      solid_rgba(255, 0, 0, 255, 16),
      solid_rgba(0, 255, 255, 255, 16),
      solid_rgba(0, 255, 0, 255, 16),
      solid_rgba(255, 0, 255, 255, 16),
      solid_rgba(0, 0, 255, 255, 16),
      solid_rgba(255, 255, 0, 255, 16),
    ])

    // 2. R8 texture + upload_subregion (fill 4x4 with 0, then patch all 4x4 with 200)
    let r8_tex = dev.create_texture_format(
      4,
      4,
      @tycho.TextureFormat::R8,
      Bytes::make(16, (0 : Byte)),
    )
    r8_tex.upload_subregion(0, 0, 4, 4, Bytes::make(16, (200 : Byte)))

    // 3. Anisotropic + ClampToBorder sampler
    let samp = dev.create_sampler_desc(
      @tycho.SamplerDesc::new(
        mag=@tycho.Filter::Linear,
        min=@tycho.Filter::Linear,
        address=@tycho.AddressMode::ClampToBorder,
        border_color=@tycho.BorderColor::OpaqueWhite,
        anisotropy=(8.0 : Float),
      ),
    )

    // 4. RGBA16F HDR render target + RGBA8 blit destination
    let hdr_rt = dev.create_render_target(800, 600, @tycho.TextureFormat::RGBA16F)
    let ldr_rt = dev.create_render_target(800, 600, @tycho.TextureFormat::RGBA8)

    let vert = @tycho.compile_glsl(
      "examples/rhi/textures-samplers/shader.vert",
      @tycho.ShaderStage::Vertex,
    )
    let frag = @tycho.compile_glsl(
      "examples/rhi/textures-samplers/shader.frag",
      @tycho.ShaderStage::Fragment,
    )
    let pipe = dev.create_graphics_pipeline(
      @tycho.PipelineDesc::new(
        vert,
        frag,
        texture_slots=2,
        color_format=@tycho.TextureFormat::RGBA16F,
      ),
    )

    let cmd = dev.begin_commands()
    cmd.begin_render_pass([@tycho.RenderTargetDesc::new(hdr_rt)])
    cmd.bind_pipeline(pipe)
    cmd.bind_texture(pipe, 0, cube, samp)
    cmd.bind_texture(pipe, 1, r8_tex, samp)
    cmd.draw(6, 1)
    cmd.end_render_pass()
    cmd.blit_texture(hdr_rt, ldr_rt)
    dev.end_commands(cmd)

    let px = ldr_rt.readback()
    opts.capture(800, 600, px)
    if show_win {
      let sc = @exwin_rhi.open(dev, opts)
      while @exwin_rhi.next_frame(sc) {
        sc.present_texture(ldr_rt)
      }
      sc.destroy()
    }
    // Left half (x=200, y=300): +Z blue + R8 green(~200) -> (0, ~200, 255)
    let li = (300 * 800 + 200) * 4
    let (lr, lg, lb) = (
      px[li].to_int(),
      px[li + 1].to_int(),
      px[li + 2].to_int(),
    )
    // Right half (x=600, y=300): +X red + R8 green(~200) -> (255, ~200, 0)
    let ri = (300 * 800 + 600) * 4
    let (rr, rg, rb) = (
      px[ri].to_int(),
      px[ri + 1].to_int(),
      px[ri + 2].to_int(),
    )

    let errs = dev.validation_errors()
    pipe.destroy()
    ldr_rt.destroy()
    hdr_rt.destroy()
    samp.destroy()
    r8_tex.destroy()
    cube.destroy()
    dev.destroy()

    let left_ok = lr < 20 && lg > 180 && lb > 240
    let right_ok = rr > 240 && rg > 180 && rb < 20
    println(
      "[rhi/textures-samplers] left=(\{lr},\{lg},\{lb}) right=(\{rr},\{rg},\{rb})",
    )
    if left_ok && right_ok && errs == 0 {
      println(
        "[rhi/textures-samplers] OK — cubemap + R8 subregion + RGBA16F + blit + anisotropy/border sampler passed (0 validation errors)",
      )
    } else {
      println(
        "[rhi/textures-samplers] FAIL — left=\{left_ok} right=\{right_ok} errs=\{errs}",
      )
    }
  } catch {
    err => println("[rhi/textures-samplers] FAIL — \{err}")
  }
}
