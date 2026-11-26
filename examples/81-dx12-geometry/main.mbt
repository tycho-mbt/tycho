// Example 81 — vertex + index buffers on the DX12 backend, headless.
//
// Before this slice the DX12 backend could only draw with `SV_VertexID`; binding
// a vertex buffer was a silent no-op. Now the pipeline carries a real
// `D3D12_INPUT_ELEMENT_DESC` layout (SPIR-V location n -> TEXCOORD n) and the
// command list binds IASetVertexBuffers / IASetIndexBuffer, so a quad with
// per-vertex colours and an index buffer must render as four coloured corners.

const SIZE : Int = 128

// 4 vertices x (float3 position + float4 colour) = 28 bytes each.
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
/// Quad corners: red, green, blue, yellow, counter-clockwise from bottom-left.
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
      println("[81-dx12-geometry] SKIP — d3d12.dll / dxgi.dll not loadable on this host")
      return
    }
    if shader_vs_spv[0] != (0x07230203 : UInt32) || shader_fs_spv[0] != (0x07230203 : UInt32) {
      println("[81-dx12-geometry] FAIL — SPIR-V artifact lost its magic number")
      return
    }
    if shader_vs_dxil_bytes != shader_vs_dxil.length() * 4 ||
      shader_fs_dxil_bytes != shader_fs_dxil.length() * 4 {
      println("[81-dx12-geometry] FAIL — DXIL padding is not 4-byte aligned")
      return
    }
    let dev = @tycho.Device::new_desc(
      @tycho.DeviceDesc::new(
        "81-dx12-geometry",
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
    ibuf.upload_uint32([(0 : UInt32), (1 : UInt32), (2 : UInt32), (0 : UInt32), (2 : UInt32), (3 : UInt32)])

    let cmd = dev.begin_commands()
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
    cmd.draw_indexed(6)
    cmd.end_render_pass()
    dev.end_commands(cmd)
    let px = rt.readback()
    if shot != "" {
      let _ = @tycho.save_png(shot, SIZE, SIZE, px)
    }

    // The diagonal of the two triangles passes exactly through the centre, so
    // both triangles contribute (red + blue) / 2 there.
    let centre = pixel(px, SIZE / 2, SIZE / 2)
    let centre_ok = near(centre, 127, 0, 127, 24)
    // Orientation-agnostic: each of the four corners must show one dominant
    // colour. Sampling close to the corner keeps the interpolation bleed small,
    // and the predicate form tolerates the remaining blend.
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
    let size_ok = px.length() == SIZE * SIZE * 4
    let errs = dev.validation_errors()
    ibuf.destroy()
    vbuf.destroy()
    pipe.destroy()
    rt.destroy()
    dev.destroy()

    if size_ok && centre_ok && matched == 4 && errs == 0 {
      println(
        "[81-dx12-geometry] OK — vertex + index buffers drew an indexed quad (centre=(\{centre.0}, \{centre.1}, \{centre.2}), \{matched}/4 corners matched, 0 validation errors)",
      )
    } else {
      println(
        "[81-dx12-geometry] FAIL — size_ok=\{size_ok} centre=(\{centre.0}, \{centre.1}, \{centre.2}) centre_ok=\{centre_ok} corners=\{matched}/4 errs=\{errs}",
      )
    }
  } catch {
    err => println("[81-dx12-geometry] FAIL — \{err}")
  }
}
