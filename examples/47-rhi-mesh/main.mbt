// Example 47 — RHI v0.5 capability-gated Mesh Shader pipeline (`VK_EXT_mesh_shader`).

///|
fn main {
  try {
    let dev = @tycho.Device::new_desc(
      @tycho.DeviceDesc::new("Tycho RHI Mesh", validation=true, headless=true),
    )
    if !dev.capabilities().supports_mesh_shader {
      println("[47-rhi-mesh] SKIP — device lacks VK_EXT_mesh_shader")
      dev.destroy()
      return
    }
    let mesh_spv = @tycho.compile_glsl(
      "examples/47-rhi-mesh/shader.mesh",
      @tycho.ShaderStage::Mesh,
    )
    let frag_spv = @tycho.compile_glsl(
      "examples/47-rhi-mesh/shader.frag",
      @tycho.ShaderStage::Fragment,
    )
    let pipe = dev.create_mesh_pipeline(
      @tycho.MeshPipelineDesc::new(
        mesh_spv,
        frag_spv,
        color_format=Some(@tycho.TextureFormat::RGBA8),
      ),
    )
    let rt = dev.create_render_target(200, 200, @tycho.TextureFormat::RGBA8)
    let cmd = dev.begin_commands()
    cmd.begin_render_pass([
      @tycho.RenderTargetDesc::new(rt, clear_color=@tycho.ClearColor::black()),
    ])
    cmd.bind_pipeline(pipe)
    cmd.draw_mesh_tasks(1, 1, 1)
    cmd.end_render_pass()
    dev.end_commands(cmd)

    let px = rt.readback()
    let mut rgb_pixels = 0
    for i = 0; i < 200 * 200; i = i + 1 {
      let off = i * 4
      if px[off] != (0 : Byte) ||
        px[off + 1] != (0 : Byte) ||
        px[off + 2] != (0 : Byte) {
        rgb_pixels = rgb_pixels + 1
      }
    }
    let errs = dev.validation_errors()
    rt.destroy()
    pipe.destroy()
    dev.destroy()

    if rgb_pixels > 1000 && errs == 0 {
      println(
        "[47-rhi-mesh] OK — mesh shader rendered \{rgb_pixels} RGB pixels via @tycho, 0 validation errors",
      )
    } else {
      println("[47-rhi-mesh] FAIL — pixels=\{rgb_pixels} errs=\{errs}")
    }
  } catch {
    err => println("[47-rhi-mesh] FAIL — \{err}")
  }
}
