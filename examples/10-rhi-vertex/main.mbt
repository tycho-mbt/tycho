// Example 10 — RHI vertex-buffer slot: per-vertex position + colour attributes.
// User code imports only laplaceliu/tycho.

///|
fn rgb_at(pixels : FixedArray[Byte], x : Int, y : Int) -> (Int, Int, Int) {
  let i = (y * 800 + x) * 4
  // Swapchain prefers BGRA8
  (pixels[i + 2].to_int(), pixels[i + 1].to_int(), pixels[i].to_int())
}

///|
fn main {
  try {
    let dev = @tycho.Device::new("Tycho RHI Vertex", true)
    let sc = dev.create_swapchain_desc(
      @tycho.SwapchainDesc::new("Tycho RHI Vertex", 800, 600, enable_readback=true),
    )
    let vert = @tycho.compile_glsl(
      "examples/10-rhi-vertex/shader.vert",
      @tycho.ShaderStage::Vertex,
    )
    let frag = @tycho.compile_glsl(
      "examples/10-rhi-vertex/shader.frag",
      @tycho.ShaderStage::Fragment,
    )
    let pipe = sc.create_pipeline_desc(
      @tycho.PipelineDesc::new(
        vert,
        frag,
        vertex_formats=[@tycho.VertexFormat::Float2, @tycho.VertexFormat::Float3],
      ),
    )
    let vbuf = dev.create_buffer(60, @tycho.BufferKind::Vertex)
    vbuf.upload_floats([
      (0.0 : Float), (-0.5 : Float), (1.0 : Float), (0.0 : Float), (0.0 : Float),
      (0.5 : Float), (0.5 : Float), (0.0 : Float), (1.0 : Float), (0.0 : Float),
      (-0.5 : Float), (0.5 : Float), (0.0 : Float), (0.0 : Float), (1.0 : Float),
    ])
    let start = @tycho.Swapchain::time()
    let mut pixels : FixedArray[Byte] = []
    let mut frames = 0
    while !sc.should_close() && frames < 10 && @tycho.Swapchain::time() - start < 0.8 {
      let cmd = sc.begin_frame()
      cmd.bind_pipeline(pipe)
      cmd.bind_vertex(0, vbuf)
      cmd.draw(3, 1)
      sc.end_frame(cmd)
      if frames == 0 {
        pixels = sc.readback()
      }
      frames = frames + 1
    }
    let (r0, g0, b0) = rgb_at(pixels, 400, 180)
    let (r1, g1, b1) = rgb_at(pixels, 570, 430)
    let (r2, g2, b2) = rgb_at(pixels, 230, 430)
    let errs = dev.validation_errors()
    vbuf.destroy()
    pipe.destroy()
    sc.destroy()
    dev.destroy()
    println(
      "[10-rhi-vertex] near-vertex RGB: (\{r0},\{g0},\{b0}) (\{r1},\{g1},\{b1}) (\{r2},\{g2},\{b2})",
    )
    if r0 > g0 && r0 > b0 && g1 > r1 && g1 > b1 && b2 > r2 && b2 > g2 && errs == 0 {
      println("[10-rhi-vertex] OK — vertex slot delivered per-vertex colours (0 validation errors)")
    } else {
      println("[10-rhi-vertex] FAIL — validation_errors=\{errs}")
    }
  } catch {
    err => println("[10-rhi-vertex] FAIL — \{err}")
  }
}
