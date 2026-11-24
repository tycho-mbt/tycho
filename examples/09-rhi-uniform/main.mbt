// Example 09 — RHI slot binding: a uniform slot tints the triangle.
// User code imports only laplaceliu/tycho; descriptor sets stay internal.

///|
fn main {
  try {
    let dev = @tycho.Device::new("Tycho RHI Uniform", true)
    let sc = dev.create_swapchain("Tycho RHI Uniform", 800, 600)
    let vert = @tycho.compile_glsl(
      "examples/09-rhi-uniform/shader.vert",
      @tycho.ShaderStage::Vertex,
    )
    let frag = @tycho.compile_glsl(
      "examples/09-rhi-uniform/shader.frag",
      @tycho.ShaderStage::Fragment,
    )
    let pipe = sc.create_pipeline(vert, frag, 1)
    let ubo = dev.create_buffer(16, @tycho.BufferKind::Uniform)
    ubo.upload_floats([(0.2 : Float), (0.8 : Float), (0.4 : Float), (1.0 : Float)])
    let start = @tycho.Swapchain::time()
    let mut pixels : FixedArray[Byte] = []
    let mut frames = 0
    while !sc.should_close() && frames < 10 && @tycho.Swapchain::time() - start < 0.8 {
      let cmd = sc.begin_frame()
      cmd.bind_pipeline(pipe)
      cmd.bind_uniform(pipe, 0, ubo)
      cmd.draw(3, 1)
      sc.end_frame(cmd)
      if frames == 0 {
        pixels = sc.readback()
      }
      frames = frames + 1
    }
    let centre = (300 * 800 + 400) * 4
    // Swapchain readback matches BGRA layout (or RGBA); check green dominant.
    let c0 = pixels[centre].to_int()
    let g = pixels[centre + 1].to_int()
    let c2 = pixels[centre + 2].to_int()
    let errs = dev.validation_errors()
    ubo.destroy()
    pipe.destroy()
    sc.destroy()
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
