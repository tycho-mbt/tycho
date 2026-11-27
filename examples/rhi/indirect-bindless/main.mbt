// rhi/indirect-bindless — RHI v0.5 GPU-driven indirect draw + BindlessHeap:
// 1. dispatch_indirect triggers compute shader writing VkDrawIndirectCommand + VkDrawIndexedIndirectCommand
// 2. BindlessHeap registers red=0, blue=1; Pass 1 uses draw_indirect -> (red, blue)
// 3. unregister_texture(red) + register_texture(green) reuses slot 0 (UPDATE_AFTER_BIND)
// 4. Pass 2 draws with draw_indexed_indirect -> (green, blue) without rebuilding pipeline/VBO

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
        "Tycho RHI Indirect Bindless",
        validation=true,
        headless=!show_win,
      ),
    )
    if !dev.capabilities().supports_bindless ||
      !dev.capabilities().supports_indirect_draw {
      println(
        "[rhi/indirect-bindless] SKIP — device lacks bindless or multiDrawIndirect support",
      )
      dev.destroy()
      return
    }

    let heap = dev.create_bindless_heap(max_textures=64)
    let red_tex = dev.create_texture(
      2,
      2,
      Bytes::makei(16, fn(i) {
        let c = i % 4
        if c == 0 || c == 3 {
          (255 : Byte)
        } else {
          (0 : Byte)
        }
      }),
    )
    let blue_tex = dev.create_texture(
      2,
      2,
      Bytes::makei(16, fn(i) {
        let c = i % 4
        if c == 2 || c == 3 {
          (255 : Byte)
        } else {
          (0 : Byte)
        }
      }),
    )
    let green_tex = dev.create_texture(
      2,
      2,
      Bytes::makei(16, fn(i) {
        let c = i % 4
        if c == 1 || c == 3 {
          (255 : Byte)
        } else {
          (0 : Byte)
        }
      }),
    )
    let samp = dev.create_sampler()
    let red_id = heap.register_texture(red_tex, samp)
    let blue_id = heap.register_texture(blue_tex, samp)

    let comp_spv = @tycho.compile_glsl(
      "examples/rhi/indirect-bindless/cull.comp",
      @tycho.ShaderStage::Compute,
    )
    let comp_pipe = dev.create_compute_pipeline_auto(comp_spv)

    let vert_spv = @tycho.compile_glsl(
      "examples/rhi/indirect-bindless/shader.vert",
      @tycho.ShaderStage::Vertex,
    )
    let frag_spv = @tycho.compile_glsl(
      "examples/rhi/indirect-bindless/shader.frag",
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

    let disp_indirect_buf = dev.create_buffer_with(
      12,
      @tycho.BufferKind::Indirect,
      location=@tycho.MemoryLocation::GpuOnly,
    )
    disp_indirect_buf.upload_floats([
      Float::reinterpret_from_int(1),
      Float::reinterpret_from_int(1),
      Float::reinterpret_from_int(1),
    ])
    let indirect_buf = dev.create_buffer_with(
      32,
      @tycho.BufferKind::Indirect,
      location=@tycho.MemoryLocation::GpuOnly,
    )
    let indexed_indirect_buf = dev.create_buffer_with(
      40,
      @tycho.BufferKind::Indirect,
      location=@tycho.MemoryLocation::GpuOnly,
    )
    let vbuf = dev.create_buffer_with(
      96,
      @tycho.BufferKind::Vertex,
      location=@tycho.MemoryLocation::GpuOnly,
    )
    let rf = Float::from_int(red_id)
    let bf = Float::from_int(blue_id)
    vbuf.upload_floats([
      (-0.9 : Float),
      (-0.5 : Float),
      rf,
      (0.0 : Float),
      (-0.1 : Float),
      (-0.5 : Float),
      rf,
      (0.0 : Float),
      (-0.5 : Float),
      (0.5 : Float),
      rf,
      (0.0 : Float),
      (0.1 : Float),
      (-0.5 : Float),
      bf,
      (0.0 : Float),
      (0.9 : Float),
      (-0.5 : Float),
      bf,
      (0.0 : Float),
      (0.5 : Float),
      (0.5 : Float),
      bf,
      (0.0 : Float),
    ])
    let ibuf = dev.create_buffer_with(
      24,
      @tycho.BufferKind::Index,
      location=@tycho.MemoryLocation::GpuOnly,
    )
    ibuf.upload_floats([
      Float::reinterpret_from_int(0),
      Float::reinterpret_from_int(1),
      Float::reinterpret_from_int(2),
      Float::reinterpret_from_int(3),
      Float::reinterpret_from_int(4),
      Float::reinterpret_from_int(5),
    ])

    let rt = dev.create_render_target(200, 200, @tycho.TextureFormat::RGBA8)
    let cmd = dev.begin_commands()
    cmd.bind_pipeline(comp_pipe)
    cmd.bind_storage(comp_pipe, 0, indirect_buf)
    cmd.bind_storage(comp_pipe, 1, indexed_indirect_buf)
    cmd.dispatch_indirect(disp_indirect_buf)
    cmd.barrier()
    cmd.begin_render_pass([
      @tycho.RenderTargetDesc::new(rt, clear_color=@tycho.ClearColor::black()),
    ])
    cmd.bind_pipeline(gfx_pipe)
    cmd.bind_bindless_heap(gfx_pipe, heap)
    cmd.bind_vertex(0, vbuf)
    cmd.draw_indirect(indirect_buf, 2)
    cmd.end_render_pass()
    dev.end_commands(cmd)

    let px1 = rt.readback()
    let li = (100 * 200 + 50) * 4
    let (lr1, lg1, lb1) = (
      px1[li].to_int(),
      px1[li + 1].to_int(),
      px1[li + 2].to_int(),
    )
    let ri = (100 * 200 + 150) * 4
    let (rr1, rg1, rb1) = (
      px1[ri].to_int(),
      px1[ri + 1].to_int(),
      px1[ri + 2].to_int(),
    )

    // Dynamically swap bindless slot `red_id` to `green_tex` and redraw with draw_indexed_indirect
    heap.unregister_texture(red_id)
    let reused_id = heap.register_texture(green_tex, samp)
    let cmd2 = dev.begin_commands()
    cmd2.begin_render_pass([
      @tycho.RenderTargetDesc::new(rt, clear_color=@tycho.ClearColor::black()),
    ])
    cmd2.bind_pipeline(gfx_pipe)
    cmd2.bind_bindless_heap(gfx_pipe, heap)
    cmd2.bind_vertex(0, vbuf)
    cmd2.bind_index(ibuf, @tycho.IndexType::Uint32)
    cmd2.draw_indexed_indirect(indexed_indirect_buf, 2)
    cmd2.end_render_pass()
    dev.end_commands(cmd2)

    let px2 = rt.readback()
    if shot != "" {
      let _ = @tycho.save_png(shot, 200, 200, px2)
    }
    if show_win {
      let sc = dev.create_swapchain("rhi/indirect-bindless", 600, 600)
      while !should_quit(sc) {
        sc.present_texture(rt)
      }
      sc.destroy()
    }
    let (lr2, lg2, lb2) = (
      px2[li].to_int(),
      px2[li + 1].to_int(),
      px2[li + 2].to_int(),
    )
    let (rr2, rg2, rb2) = (
      px2[ri].to_int(),
      px2[ri + 1].to_int(),
      px2[ri + 2].to_int(),
    )

    let errs = dev.validation_errors()
    rt.destroy()
    ibuf.destroy()
    vbuf.destroy()
    indexed_indirect_buf.destroy()
    indirect_buf.destroy()
    disp_indirect_buf.destroy()
    gfx_pipe.destroy()
    comp_pipe.destroy()
    samp.destroy()
    green_tex.destroy()
    blue_tex.destroy()
    red_tex.destroy()
    heap.destroy()
    dev.destroy()

    let p1_ok = lr1 > 240 &&
      lg1 < 20 &&
      lb1 < 20 &&
      rr1 < 20 &&
      rg1 < 20 &&
      rb1 > 240
    let slot_reused = reused_id == red_id
    let p2_ok = lr2 < 20 &&
      lg2 > 240 &&
      lb2 < 20 &&
      rr2 < 20 &&
      rg2 < 20 &&
      rb2 > 240
    println(
      "[rhi/indirect-bindless] ids=(\{red_id}->\{reused_id},\{blue_id}) p1=((\{lr1},\{lg1},\{lb1}),(\{rr1},\{rg1},\{rb1})) p2=((\{lr2},\{lg2},\{lb2}),(\{rr2},\{rg2},\{rb2}))",
    )
    if p1_ok && slot_reused && p2_ok && errs == 0 {
      println(
        "[rhi/indirect-bindless] OK — dispatch_indirect + draw_indirect + draw_indexed_indirect + bindless slot reuse passed (0 validation errors)",
      )
    } else {
      println(
        "[rhi/indirect-bindless] FAIL — p1=\{p1_ok} reused=\{slot_reused} p2=\{p2_ok} errs=\{errs}",
      )
    }
  } catch {
    err => println("[rhi/indirect-bindless] FAIL — \{err}")
  }
}
