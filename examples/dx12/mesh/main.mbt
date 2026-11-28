// dx12/mesh — mesh shader pipeline on DX12, headless.
//
// Nothing feeds the pipeline: no input layout, no vertex buffer, no index buffer.
// A single `DispatchMesh(1,1,1)` launches one mesh-shader workgroup that writes a
// three-vertex triangle with per-vertex colours, which is the smallest thing that
// proves the mesh path (stream-descriptor PSO + `ID3D12GraphicsCommandList6::
// DispatchMesh`) is wired.

const WIDTH : Int = 800

const HEIGHT : Int = 600

///|
fn pixel(px : FixedArray[Byte], x : Int, y : Int) -> (Int, Int, Int) {
  let i = (y * WIDTH + x) * 4
  if i + 3 >= px.length() {
    return (-1, -1, -1)
  }
  (px[i].to_int(), px[i + 1].to_int(), px[i + 2].to_int())
}

///|
fn dominates(c : (Int, Int, Int), channel : Int) -> Bool {
  let (r, g, b) = c
  if channel == 0 {
    r > 120 && r > g + 60 && r > b + 60
  } else if channel == 1 {
    g > 120 && g > r + 60 && g > b + 60
  } else {
    b > 120 && b > r + 60 && b > g + 60
  }
}

///|
fn main {
  let opts = @exwin.Options::parse("dx12/mesh")
  try {
    if !@tycho.dx12_available() {
      println("[dx12/mesh] SKIP — d3d12.dll / dxgi.dll not loadable on this host")
      return
    }
    // Both artifacts are committed: DXIL is what this backend binds, SPIR-V is the
    // one Vulkan would take.
    if shader_ms_spv[0] != (0x07230203 : UInt32) || shader_fs_spv[0] != (0x07230203 : UInt32) {
      println("[dx12/mesh] FAIL — SPIR-V artifact lost its magic number")
      return
    }
    if shader_ms_dxil_bytes != shader_ms_dxil.length() * 4 ||
      shader_fs_dxil_bytes != shader_fs_dxil.length() * 4 {
      println("[dx12/mesh] FAIL — DXIL padding is not 4-byte aligned")
      return
    }
    let dev = @tycho.Device::new_desc(
      @tycho.DeviceDesc::new(
        "dx12/mesh",
        validation=true,
        headless=true,
        backend=@tycho.BackendKind::Dx12,
      ),
    )
    if !dev.capabilities().supports_mesh_shader {
      println("[dx12/mesh] SKIP — adapter does not support mesh shaders")
      dev.destroy()
      return
    }
    let rt = dev.create_render_target(WIDTH, HEIGHT, @tycho.TextureFormat::RGBA8)
    let pipe = dev.create_mesh_pipeline(
      @tycho.MeshPipelineDesc::new(shader_ms_dxil, shader_fs_dxil),
    )
    let cmd = dev.begin_commands()
    cmd.begin_render_pass([
      @tycho.RenderTargetDesc::new(
        rt,
        clear_color=@tycho.ClearColor::rgba(0.05, 0.05, 0.1, 1.0),
      ),
    ])
    cmd.bind_pipeline(pipe)
    cmd.draw_mesh_tasks(1, 1, 1)
    cmd.end_render_pass()
    dev.end_commands(cmd)
    let px = rt.readback()
    opts.capture(WIDTH, HEIGHT, px)

    // One sample near each vertex; the mesh shader writes red / green / blue
    // there, and the rasteriser interpolates between them.
    let samples = [
      pixel(px, WIDTH / 2, HEIGHT * 15 / 100),
      pixel(px, WIDTH * 85 / 100, HEIGHT * 85 / 100),
      pixel(px, WIDTH * 15 / 100, HEIGHT * 85 / 100),
    ]
    let mut matched = 0
    for channel = 0; channel < 3; channel = channel + 1 {
      for sample in samples {
        if dominates(sample, channel) {
          matched = matched + 1
          break
        }
      }
    }
    let size_ok = px.length() == WIDTH * HEIGHT * 4
    let errs = dev.validation_errors()
    pipe.destroy()
    rt.destroy()
    dev.destroy()

    if size_ok && matched == 3 && errs == 0 {
      println(
        "[dx12/mesh] OK — mesh shader drew a triangle via DispatchMesh (\{matched}/3 vertex colours matched, 0 validation errors)",
      )
    } else {
      println(
        "[dx12/mesh] FAIL — size_ok=\{size_ok} matched=\{matched}/3 apex=(\{samples[0].0}, \{samples[0].1}, \{samples[0].2}) right=(\{samples[1].0}, \{samples[1].1}, \{samples[1].2}) left=(\{samples[2].0}, \{samples[2].1}, \{samples[2].2}) errs=\{errs}",
      )
    }
  } catch {
    err => println("[dx12/mesh] FAIL — \{err}")
  }
}
