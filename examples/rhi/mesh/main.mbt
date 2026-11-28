// rhi/mesh — RHI v0.5 capability-gated Task + Mesh Shader pipeline (`VK_EXT_mesh_shader`):
// - Task shader (`shader.task`) emits workgroup with taskPayloadSharedEXT + push constants
// - Mesh shader (`shader.mesh`) pulls triangle vertices from SSBO (`BufferKind::Storage`)
// - Exercises both direct `draw_mesh_tasks` and indirect `draw_mesh_tasks_indirect`

///|
fn main {
  try {
    let opts = @exwin.Options::parse("rhi/mesh")
    let show_win = opts.window
    let dev = @tycho.Device::new_desc(
      @tycho.DeviceDesc::new(
        "Tycho RHI Mesh",
        validation=true,
        headless=!show_win,
      ),
    )
    if !dev.capabilities().supports_mesh_shader {
      println("[rhi/mesh] SKIP — device lacks VK_EXT_mesh_shader")
      dev.destroy()
      return
    }
    let task_spv = @tycho.compile_glsl(
      "examples/rhi/mesh/shader.task",
      @tycho.ShaderStage::Task,
    )
    let mesh_spv = @tycho.compile_glsl(
      "examples/rhi/mesh/shader.mesh",
      @tycho.ShaderStage::Mesh,
    )
    let frag_spv = @tycho.compile_glsl(
      "examples/rhi/mesh/shader.frag",
      @tycho.ShaderStage::Fragment,
    )
    let pipe = dev.create_mesh_pipeline(
      @tycho.MeshPipelineDesc::new(
        mesh_spv,
        frag_spv,
        task=task_spv,
        storage_slots=1,
        push_constant_size=20,
        color_format=@tycho.TextureFormat::RGBA8,
      ),
    )

    let ssbo = dev.create_buffer_with(
      48,
      @tycho.BufferKind::Storage,
      location=@tycho.MemoryLocation::GpuOnly,
    )
    ssbo.upload_floats([
      (-0.35 : Float),
      (-0.5 : Float),
      (0.0 : Float),
      (1.0 : Float),
      (0.35 : Float),
      (-0.5 : Float),
      (0.0 : Float),
      (1.0 : Float),
      (0.0 : Float),
      (0.5 : Float),
      (0.0 : Float),
      (1.0 : Float),
    ])
    let indirect_buf = dev.create_buffer_with(
      12,
      @tycho.BufferKind::Indirect,
      location=@tycho.MemoryLocation::GpuOnly,
    )
    indirect_buf.upload_floats([
      Float::reinterpret_from_int(1),
      Float::reinterpret_from_int(1),
      Float::reinterpret_from_int(1),
    ])

    let rt = dev.create_render_target(800, 600, @tycho.TextureFormat::RGBA8)
    let cmd = dev.begin_commands()
    cmd.begin_render_pass([
      @tycho.RenderTargetDesc::new(rt, clear_color=@tycho.ClearColor::black()),
    ])
    cmd.bind_pipeline(pipe)
    cmd.bind_storage(pipe, 0, ssbo)
    // Left red triangle via direct draw_mesh_tasks
    cmd.push_constants_floats(pipe, [
      (0.95 : Float),
      (0.05 : Float),
      (0.05 : Float),
      (1.0 : Float),
      (-0.5 : Float),
    ])
    cmd.draw_mesh_tasks(1, 1, 1)
    // Right green triangle via draw_mesh_tasks_indirect
    cmd.push_constants_floats(pipe, [
      (0.05 : Float),
      (0.95 : Float),
      (0.1 : Float),
      (1.0 : Float),
      (0.5 : Float),
    ])
    cmd.draw_mesh_tasks_indirect(indirect_buf, 1)
    cmd.end_render_pass()
    dev.end_commands(cmd)

    let px = rt.readback()
    opts.capture(800, 600, px)
    if show_win {
      let sc = @exwin_rhi.open(dev, opts)
      while @exwin_rhi.next_frame(sc) {
        sc.present_texture(rt)
      }
      sc.destroy()
    }
    let li = (300 * 800 + 200) * 4
    let (lr, lg, lb) = (
      px[li].to_int(),
      px[li + 1].to_int(),
      px[li + 2].to_int(),
    )
    let ri = (300 * 800 + 600) * 4
    let (rr, rg, rb) = (
      px[ri].to_int(),
      px[ri + 1].to_int(),
      px[ri + 2].to_int(),
    )

    let errs = dev.validation_errors()
    rt.destroy()
    indirect_buf.destroy()
    ssbo.destroy()
    pipe.destroy()
    dev.destroy()

    let left_ok = lr > 200 && lg < 40 && lb < 40
    let right_ok = rr < 40 && rg > 200 && rb < 60
    println("[rhi/mesh] left=(\{lr},\{lg},\{lb}) right=(\{rr},\{rg},\{rb})")
    if left_ok && right_ok && errs == 0 {
      println(
        "[rhi/mesh] OK — task+mesh shader + SSBO + push constants + draw_mesh_tasks_indirect passed (0 validation errors)",
      )
    } else {
      println(
        "[rhi/mesh] FAIL — left=\{left_ok} right=\{right_ok} errs=\{errs}",
      )
    }
  } catch {
    err => println("[rhi/mesh] FAIL — \{err}")
  }
}
