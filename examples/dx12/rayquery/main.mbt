// dx12/rayquery — inline ray query (DXR Tier 1.1 / SM 6.5) on the DX12 backend.
//
// Builds a single-triangle BLAS, wraps it in a TLAS (using the BLAS GPU VA),
// binds the TLAS as an acceleration-structure SRV at t0 alongside a 64x64 UAV
// at u0, dispatches a SM 6.5 RayQuery compute shader, and asserts green at the
// centre (triangle hit) and blue at the corner (miss), with 0 validation errors.

const SIZE : Int = 64

const GROUP : Int = 8

///|
fn pixel(px : FixedArray[Byte], x : Int, y : Int) -> (Int, Int, Int) {
  let i = (y * SIZE + x) * 4
  if i + 3 >= px.length() {
    return (-1, -1, -1)
  }
  (px[i].to_int(), px[i + 1].to_int(), px[i + 2].to_int())
}

///|
fn main {
  let opts = @exwin.Options::parse("dx12/rayquery")
  try {
    if !@tycho.dx12_available() {
      println("[dx12/rayquery] SKIP — d3d12.dll / dxgi.dll not loadable on this host")
      return
    }
    let probe = match @dx12.Device::create(warp=@dx12.env_requests_warp(), debug=false) {
      Some(d) => d
      None =>
        match @dx12.Device::create(warp=true, debug=false) {
          Some(d) => d
          None => {
            println("[dx12/rayquery] SKIP — no D3D12 device available")
            return
          }
        }
    }
    let tier = probe.raytracing_tier()
    let sm = probe.shader_model()
    probe.destroy()
    if tier < 11 || sm < 0x65 {
      println(
        "[dx12/rayquery] SKIP — requires DXR tier 1.1 and SM 6.5 (got tier=\{tier}, sm=\{sm})",
      )
      return
    }

    if dx12_rayquery_cs_bytes != dx12_rayquery_cs.length() * 4 {
      println("[dx12/rayquery] FAIL — DXIL padding is not 4-byte aligned")
      return
    }
    let dev = @tycho.Device::new_desc(
      @tycho.DeviceDesc::new(
        "dx12/rayquery",
        validation=true,
        headless=true,
        backend=@tycho.BackendKind::Dx12,
      ),
    )
    if !dev.capabilities().supports_ray_query {
      dev.destroy()
      println("[dx12/rayquery] SKIP — ray queries unsupported on this adapter")
      return
    }

    // Triangle covering the centre of [-1, 1]^2: (-0.5,-0.5,0), (0.5,-0.5,0), (0,0.5,0).
    let verts : FixedArray[Float] = [
      -0.5, -0.5, 0.0, 0.5, -0.5, 0.0, 0.0, 0.5, 0.0,
    ]
    let vbuf = dev.create_buffer_with(
      verts.length() * 4,
      @tycho.BufferKind::Vertex,
      location=@tycho.MemoryLocation::CpuToGpu,
    )
    vbuf.upload_floats(verts)

    let blas = dev.create_blas([
      @tycho.RayGeometryDesc::new(vbuf, 3, vertex_stride=12, is_opaque=true),
    ])
    let tlas = dev.create_tlas([@tycho.RayInstanceDesc::new(blas)])

    let tex = dev.create_storage_texture(SIZE, SIZE, @tycho.TextureFormat::RGBA8)
    let pipe = dev.create_compute_pipeline(
      dx12_rayquery_cs,
      0,
      0,
      storage_image_slots=1,
      accel_slots=1,
    )

    let cmd = dev.begin_commands()
    cmd.bind_pipeline(pipe)
    cmd.bind_storage_image(pipe, 0, tex)
    cmd.bind_accel_struct(pipe, 0, tlas)
    cmd.dispatch(SIZE / GROUP, SIZE / GROUP, 1)
    dev.end_commands(cmd)

    let px = tex.readback()
    opts.capture(SIZE, SIZE, px)

    let centre = pixel(px, SIZE / 2, SIZE / 2)
    let corner = pixel(px, 0, 0)
    let hit_ok = centre.0 < 10 && centre.1 > 240 && centre.2 < 10
    let miss_ok = corner.0 < 10 && corner.1 < 10 && corner.2 > 240
    let errs = dev.validation_errors()

    pipe.destroy()
    tex.destroy()
    tlas.destroy()
    blas.destroy()
    vbuf.destroy()
    dev.destroy()

    if hit_ok && miss_ok && errs == 0 {
      println(
        "[dx12/rayquery] OK — RayQuery hit triangle at centre=(\{centre.0}, \{centre.1}, \{centre.2}) and missed at corner=(\{corner.0}, \{corner.1}, \{corner.2}), 0 validation errors",
      )
    } else {
      println(
        "[dx12/rayquery] FAIL — hit_ok=\{hit_ok} miss_ok=\{miss_ok} centre=(\{centre.0}, \{centre.1}, \{centre.2}) corner=(\{corner.0}, \{corner.1}, \{corner.2}) errs=\{errs}",
      )
    }
  } catch {
    err => println("[dx12/rayquery] FAIL — \{err}")
  }
}
