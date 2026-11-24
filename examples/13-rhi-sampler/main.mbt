// Example 13 — RHI sampler state: nearest vs linear on a 2x2 checker.
// At UV (0.5, 0.5) nearest picks one texel (black), linear averages four (0.5),
// proving the sampler description took effect.

///|
fn centre_green(pixels : FixedArray[Byte]) -> Int {
  pixels[(300 * 800 + 400) * 4 + 1].to_int()
}

///|
fn main {
  try {
    let dev = @tycho.Device::new("Tycho RHI Sampler", true)
    let sc = dev.create_swapchain("Tycho RHI Sampler", 800, 600)
    let vert = @tycho.compile_glsl(
      "examples/13-rhi-sampler/shader.vert",
      @tycho.ShaderStage::Vertex,
    )
    let frag = @tycho.compile_glsl(
      "examples/13-rhi-sampler/shader.frag",
      @tycho.ShaderStage::Fragment,
    )
    let pipe = sc.create_pipeline_desc(
      @tycho.PipelineDesc::new(vert, frag, texture_slots=1),
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
    for phase = 0; phase < 2; phase = phase + 1 {
      let samp = if phase == 0 { nearest } else { linear }
      let cmd = sc.begin_frame()
      cmd.bind_pipeline(pipe)
      cmd.bind_texture(pipe, 0, tex, samp)
      cmd.draw(6, 1)
      sc.end_frame(cmd)
      let g = centre_green(sc.readback())
      if phase == 0 {
        g_nearest = g
      } else {
        g_linear = g
      }
    }
    let errs = dev.validation_errors()
    linear.destroy()
    nearest.destroy()
    tex.destroy()
    pipe.destroy()
    sc.destroy()
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
