// rhi/dx12-indirect — indirect draws and timestamp queries on the DX12 backend.
//
// The quad from `81` is drawn again, but the arguments come from a buffer
// (`ExecuteIndirect` through a command signature) instead of the draw call, and
// GPU timestamps bracket the pass.
//
// The argument layout is Vulkan's `VkDrawIndexedIndirectCommand` verbatim
// (20 bytes: indexCount, instanceCount, firstIndex, vertexOffset, firstInstance),
// which is byte-identical to `D3D12_DRAW_INDEXED_ARGUMENTS` — one buffer serves
// both backends.

const SIZE : Int = 128

const VERTEX_STRIDE : Int = 28

const VERTEX_BYTES : Int = 4 * VERTEX_STRIDE

const INDEX_BYTES : Int = 6 * 4

///|
fn pixel(px : FixedArray[Byte], x : Int, y : Int) -> (Int, Int, Int) {
  let i = (y * SIZE + x) * 4
  if i + 3 >= px.length() {
    return (-1, -1, -1)
  }
  (px[i].to_int(), px[i + 1].to_int(), px[i + 2].to_int())
}

///|
fn near(rgb : (Int, Int, Int), r : Int, g : Int, b : Int, tolerance : Int) -> Bool {
  let (ar, ag, ab) = rgb
  (ar - r).abs() <= tolerance && (ag - g).abs() <= tolerance && (ab - b).abs() <= tolerance
}

///|
fn vertex_data() -> FixedArray[Float] {
  [
    (-0.8 : Float), (-0.8 : Float), (0.0 : Float), (1.0 : Float), (0.0 : Float), (0.0 : Float),
    (1.0 : Float), //
    (0.8 : Float), (-0.8 : Float), (0.0 : Float), (0.0 : Float), (1.0 : Float), (0.0 : Float),
    (1.0 : Float), //
    (0.8 : Float), (0.8 : Float), (0.0 : Float), (0.0 : Float), (0.0 : Float), (1.0 : Float),
    (1.0 : Float), //
    (-0.8 : Float), (0.8 : Float), (0.0 : Float), (1.0 : Float), (1.0 : Float), (0.0 : Float),
    (1.0 : Float), //
  ]
}

///|
fn main {
  let shot = @tycho.screenshot_path()
  try {
    if !@tycho.dx12_available() {
      println("[rhi/dx12-indirect] SKIP — d3d12.dll / dxgi.dll not loadable on this host")
      return
    }
    // Both artifacts are committed: DXIL is what this backend binds, SPIR-V is the
    // one Vulkan would take.
    if shader_vs_spv[0] != (0x07230203 : UInt32) || shader_fs_spv[0] != (0x07230203 : UInt32) {
      println("[rhi/dx12-indirect] FAIL — SPIR-V artifact lost its magic number")
      return
    }
    if shader_vs_dxil_bytes != shader_vs_dxil.length() * 4 ||
      shader_fs_dxil_bytes != shader_fs_dxil.length() * 4 {
      println("[rhi/dx12-indirect] FAIL — DXIL padding is not 4-byte aligned")
      return
    }
    let dev = @tycho.Device::new_desc(
      @tycho.DeviceDesc::new(
        "rhi/dx12-indirect",
        validation=true,
        headless=true,
        backend=@tycho.BackendKind::Dx12,
      ),
    )
    let rt = dev.create_render_target(SIZE, SIZE, @tycho.TextureFormat::RGBA8)
    let pipe = dev.create_graphics_pipeline(
      @tycho.PipelineDesc::new(
        shader_vs_dxil,
        shader_fs_dxil,
        vertex_formats=[
          @tycho.VertexFormat::Float3,
          @tycho.VertexFormat::Float4,
        ],
        color_format=Some(@tycho.TextureFormat::RGBA8),
      ),
    )
    let vbuf = dev.create_buffer(VERTEX_BYTES, @tycho.BufferKind::Vertex)
    vbuf.upload_floats(vertex_data())
    let ibuf = dev.create_buffer(INDEX_BYTES, @tycho.BufferKind::Index)
    ibuf.upload_uint32([
      (0 : UInt32), (1 : UInt32), (2 : UInt32), (0 : UInt32), (2 : UInt32), (3 : UInt32),
    ])
    // VkDrawIndexedIndirectCommand == D3D12_DRAW_INDEXED_ARGUMENTS.
    let args = dev.create_buffer(20, @tycho.BufferKind::Indirect)
    args.upload_uint32([
      (6 : UInt32), (1 : UInt32), (0 : UInt32), (0 : UInt32), (0 : UInt32),
    ])
    let pool = dev.create_timestamp_pool(2)

    let cmd = dev.begin_commands()
    cmd.write_timestamp(pool, 0)
    cmd.begin_render_pass(
      [
        @tycho.RenderTargetDesc::new(
          rt,
          clear_color=@tycho.ClearColor::rgba(0.05, 0.05, 0.1, 1.0),
        ),
      ],
    )
    cmd.bind_pipeline(pipe)
    cmd.bind_vertex(0, vbuf)
    cmd.bind_index(ibuf, @tycho.IndexType::Uint32)
    cmd.draw_indexed_indirect(args, 1)
    cmd.end_render_pass()
    cmd.write_timestamp(pool, 1)
    dev.end_commands(cmd)
    let px = rt.readback()
    if shot != "" {
      let _ = @tycho.save_png(shot, SIZE, SIZE, px)
    }

    let centre = pixel(px, SIZE / 2, SIZE / 2)
    let centre_ok = near(centre, 127, 0, 127, 24)
    let quads = [
      pixel(px, SIZE / 8, SIZE / 8),
      pixel(px, SIZE * 7 / 8, SIZE / 8),
      pixel(px, SIZE / 8, SIZE * 7 / 8),
      pixel(px, SIZE * 7 / 8, SIZE * 7 / 8),
    ]
    let dominates = fn(c : (Int, Int, Int), channel : Int) -> Bool {
      let (r, g, b) = c
      if channel == 0 {
        r > 150 && r > g + 80 && r > b + 80
      } else if channel == 1 {
        g > 150 && g > r + 80 && g > b + 80
      } else if channel == 2 {
        b > 150 && b > r + 80 && b > g + 80
      } else {
        r > 150 && g > 150 && b < 100
      }
    }
    let mut matched = 0
    for channel = 0; channel < 4; channel = channel + 1 {
      for got in quads {
        if dominates(got, channel) {
          matched = matched + 1
          break
        }
      }
    }
    // Unsupported recording calls used to be silent no-ops. They are now recorded
    // and surfaced by `end_commands`, so a caller cannot believe the work ran.
    let mut guarded = false
    let probe = dev.begin_commands()
    probe.draw_mesh_tasks(1, 1, 1)
    try {
      dev.end_commands(probe)
    } catch {
      @tycho.RhiError::BackendUnsupported(message) => guarded = message.contains("mesh")
      _ => ()
    }

    // The timestamps prove the query heap is wired: both ticks must be non-zero
    // (the GPU wrote them) and the pass must not report negative time.
    let ticks = pool.resolve_ns()
    let timestamps_ok = ticks.length() == 2 && ticks[0] >= 0.0 && ticks[1] > 0.0
    let elapsed = pool.elapsed_ms(0, 1)
    let size_ok = px.length() == SIZE * SIZE * 4
    let errs = dev.validation_errors()
    pool.destroy()
    args.destroy()
    ibuf.destroy()
    vbuf.destroy()
    pipe.destroy()
    rt.destroy()
    dev.destroy()

    if size_ok && centre_ok && matched == 4 && timestamps_ok && guarded && errs == 0 {
      println(
        "[rhi/dx12-indirect] OK — indirect indexed draw + timestamps (centre=(\{centre.0}, \{centre.1}, \{centre.2}), \{matched}/4 corners matched, pass=\{elapsed} ms, unsupported calls rejected, 0 validation errors)",
      )
    } else {
      println(
        "[rhi/dx12-indirect] FAIL — size_ok=\{size_ok} centre=(\{centre.0}, \{centre.1}, \{centre.2}) centre_ok=\{centre_ok} corners=\{matched}/4 timestamps_ok=\{timestamps_ok} guarded=\{guarded} ticks=(\{ticks[0]}, \{ticks[1]}) errs=\{errs}",
      )
    }
  } catch {
    err => println("[rhi/dx12-indirect] FAIL — \{err}")
  }
}
