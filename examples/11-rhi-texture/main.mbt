// Example 11 — RHI texture/sampler slot: a sampled texture fills the quad.
// User code imports only laplaceliu/tycho.

///|
fn main {
  try {
    let dev = @tycho.Device::new("Tycho RHI Texture", true)
    let sc = dev.create_swapchain_desc(
      @tycho.SwapchainDesc::new("Tycho RHI Texture", 800, 600, enable_readback=true),
    )
    let vert = @tycho.compile_glsl(
      "examples/11-rhi-texture/shader.vert",
      @tycho.ShaderStage::Vertex,
    )
    let frag = @tycho.compile_glsl(
      "examples/11-rhi-texture/shader.frag",
      @tycho.ShaderStage::Fragment,
    )
    let pipe = sc.create_pipeline_desc(
      @tycho.PipelineDesc::new(vert, frag, texture_slots=1),
    )
    let magenta : Bytes = Bytes::from_array([
      255, 0, 255, 255, 255, 0, 255, 255,
      255, 0, 255, 255, 255, 0, 255, 255,
    ])
    let tex = dev.create_texture(2, 2, magenta)
    let samp = dev.create_sampler()
    let start = @tycho.Swapchain::time()
    let mut pixels : FixedArray[Byte] = []
    let mut frames = 0
    while !sc.should_close() && frames < 10 && @tycho.Swapchain::time() - start < 0.8 {
      let cmd = sc.begin_frame()
      cmd.bind_pipeline(pipe)
      cmd.bind_texture(pipe, 0, tex, samp)
      cmd.draw(6, 1)
      sc.end_frame(cmd)
      if frames == 0 {
        pixels = sc.readback()
      }
      frames = frames + 1
    }
    let i = (300 * 800 + 400) * 4
    let b = pixels[i].to_int()
    let g = pixels[i + 1].to_int()
    let r = pixels[i + 2].to_int()
    let errs = dev.validation_errors()
    samp.destroy()
    tex.destroy()
    pipe.destroy()
    sc.destroy()
    dev.destroy()
    println("[11-rhi-texture] centre RGB = (\{r}, \{g}, \{b}), frames=\{frames}")
    if r > 200 && b > 200 && g < 60 && errs == 0 {
      println("[11-rhi-texture] OK — texture slot sampled the uploaded image (0 validation errors)")
    } else {
      println("[11-rhi-texture] FAIL — validation_errors=\{errs}")
    }
  } catch {
    err => println("[11-rhi-texture] FAIL — \{err}")
  }
}
