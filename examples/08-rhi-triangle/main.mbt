// Example 08 — RHI triangle. User code imports only laplaceliu/tycho: no Vulkan
// handles, no descriptor sets, no swapchain/sync boilerplate, no C.

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
fn main {
  try {
    let dev = @rhi.Device::new("Tycho RHI Triangle", true)
    let sc = dev.create_swapchain("Tycho RHI Triangle", 800, 600)
    let vert = @rhi.compile_glsl(
      "examples/08-rhi-triangle/shader.vert",
      @rhi.ShaderStage::Vertex,
    )
    let frag = @rhi.compile_glsl(
      "examples/08-rhi-triangle/shader.frag",
      @rhi.ShaderStage::Fragment,
    )
    let pipe = sc.create_pipeline(vert, frag, 0)
    let start = @rhi.Swapchain::time()
    let mut pixels = 0
    let mut frames = 0
    while !sc.should_close() && frames < 10 && @rhi.Swapchain::time() - start < 0.8 {
      let cmd = sc.begin_frame()
      cmd.bind_pipeline(pipe)
      cmd.draw(3, 1)
      sc.end_frame(cmd)
      if frames == 0 {
        pixels = count_rgb(sc.readback())
      }
      frames = frames + 1
    }
    let errs = dev.validation_errors()
    pipe.destroy()
    sc.destroy()
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
