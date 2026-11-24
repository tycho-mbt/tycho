// Example 46 — RHI v0.5 GPU-driven indirect draw + BindlessHeap:
// 1. Compute shader writes 2 VkDrawIndirectCommand structs into BufferKind::Indirect
// 2. BindlessHeap registers 2 distinct textures (red=0, blue=1)
// 3. Graphics pass draws both triangles via draw_indirect(buf, 2) sampling bindless uTextures[]

///|
fn main {
  try {
    let dev = @tycho.Device::new_desc(
      @tycho.DeviceDesc::new("Tycho RHI Indirect Bindless", validation=true, headless=true),
    )
    if !dev.capabilities().supports_bindless {
      println("[46-rhi-indirect-bindless] SKIP — device lacks bindless support")
      dev.destroy()
      return
    }

    let heap = dev.create_bindless_heap(max_textures=64)
    let red_tex = dev.create_texture(
      2,
      2,
      Bytes::makei(16, fn(i) {
        let c = i % 4
        if c == 0 || c == 3 { (255 : Byte) } else { (0 : Byte) }
      }),
    )
    let blue_tex = dev.create_texture(
      2,
      2,
      Bytes::makei(16, fn(i) {
        let c = i % 4
        if c == 2 || c == 3 { (255 : Byte) } else { (0 : Byte) }
      }),
    )
    let samp = dev.create_sampler()
    let red_id = heap.register_texture(red_tex, samp)
    let blue_id = heap.register_texture(blue_tex, samp)

    let comp_spv = @tycho.compile_glsl(
      "examples/46-rhi-indirect-bindless/cull.comp",
      @tycho.ShaderStage::Compute,
    )
    let comp_pipe = dev.create_compute_pipeline_auto(comp_spv)

    let vert_spv = @tycho.compile_glsl(
      "examples/46-rhi-indirect-bindless/shader.vert",
      @tycho.ShaderStage::Vertex,
    )
    let frag_spv = @tycho.compile_glsl(
      "examples/46-rhi-indirect-bindless/shader.frag",
      @tycho.ShaderStage::Fragment,
    )
    let gfx_pipe = dev.create_graphics_pipeline(
      @tycho.PipelineDesc::from_spirv(
        vert_spv,
        frag_spv,
        color_format=Some(@tycho.TextureFormat::RGBA8),
        bindless_heap=Some(heap),
      ),
    )

    let indirect_buf = dev.create_buffer_with(
      32,
      @tycho.BufferKind::Indirect,
      location=@tycho.MemoryLocation::GpuOnly,
    )
    let vbuf = dev.create_buffer_with(
      96,
      @tycho.BufferKind::Vertex,
      location=@tycho.MemoryLocation::GpuOnly,
    )
    // 6 vertices (2 triangles): (x, y, tex_idx, 0.0)
    let rf = Float::from_int(red_id)
    let bf = Float::from_int(blue_id)
    vbuf.upload_floats([
      (-0.9 : Float), (-0.5 : Float), rf, (0.0 : Float),
      (-0.1 : Float), (-0.5 : Float), rf, (0.0 : Float),
      (-0.5 : Float), (0.5 : Float), rf, (0.0 : Float),
      (0.1 : Float), (-0.5 : Float), bf, (0.0 : Float),
      (0.9 : Float), (-0.5 : Float), bf, (0.0 : Float),
      (0.5 : Float), (0.5 : Float), bf, (0.0 : Float),
    ])

    let rt = dev.create_render_target(200, 200, @tycho.TextureFormat::RGBA8)
    let cmd = dev.begin_commands()
    cmd.bind_pipeline(comp_pipe)
    cmd.bind_storage(comp_pipe, 0, indirect_buf)
    cmd.dispatch(1, 1, 1)
    cmd.barrier()
    cmd.begin_render_pass([
      @tycho.RenderTargetDesc::new(
        rt,
        clear_color=@tycho.ClearColor::black(),
      ),
    ])
    cmd.bind_pipeline(gfx_pipe)
    cmd.bind_bindless_heap(gfx_pipe, heap)
    cmd.bind_vertex(0, vbuf)
    cmd.draw_indirect(indirect_buf, 2)
    cmd.end_render_pass()
    dev.end_commands(cmd)

    let px = rt.readback()
    let li = (100 * 200 + 50) * 4
    let (lr, lg, lb) = (px[li].to_int(), px[li + 1].to_int(), px[li + 2].to_int())
    let ri = (100 * 200 + 150) * 4
    let (rr, rg, rb) = (px[ri].to_int(), px[ri + 1].to_int(), px[ri + 2].to_int())

    let errs = dev.validation_errors()
    rt.destroy()
    vbuf.destroy()
    indirect_buf.destroy()
    gfx_pipe.destroy()
    comp_pipe.destroy()
    samp.destroy()
    blue_tex.destroy()
    red_tex.destroy()
    heap.destroy()
    dev.destroy()

    let left_ok = lr > 240 && lg < 20 && lb < 20
    let right_ok = rr < 20 && rg < 20 && rb > 240
    println(
      "[46-rhi-indirect-bindless] ids=(\{red_id},\{blue_id}) left=(\{lr},\{lg},\{lb}) right=(\{rr},\{rg},\{rb})",
    )
    if left_ok && right_ok && errs == 0 {
      println(
        "[46-rhi-indirect-bindless] OK — compute->indirect draw + bindless heap (ids \{red_id}, \{blue_id}) passed (0 validation errors)",
      )
    } else {
      println(
        "[46-rhi-indirect-bindless] FAIL — left=\{left_ok} right=\{right_ok} errs=\{errs}",
      )
    }
  } catch {
    err => println("[46-rhi-indirect-bindless] FAIL — \{err}")
  }
}
