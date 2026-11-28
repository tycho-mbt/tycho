// dx12/compute — compute + storage image on the DX12 backend, the counterpart of
// `rhi/compute-storage-image` (which is Vulkan only: DXIL carries no SPIR-V
// reflection, so the slot counts are passed explicitly here).
//
// The dispatch writes `float4(uv, 0.5, 1)` into an 800x600 RWTexture2D, so the
// readback proves three things at once: the UAV descriptor table is bound, the
// storage texture starts in UNORDERED_ACCESS, and SV_DispatchThreadID maps to the
// pixel it claims.

const WIDTH : Int = 800

const HEIGHT : Int = 600

const GROUP : Int = 8

///|
fn pixel(px : FixedArray[Byte], x : Int, y : Int) -> (Int, Int, Int) {
  let i = (y * WIDTH + x) * 4
  if i + 3 >= px.length() {
    return (-1, -1, -1)
  }
  (px[i].to_int(), px[i + 1].to_int(), px[i + 2].to_int())
}

///|
fn close(value : Int, want : Int, tolerance : Int) -> Bool {
  (value - want).abs() <= tolerance
}

///|
fn main {
  let opts = @exwin.Options::parse("dx12/compute")
  try {
    if !@tycho.dx12_available() {
      println("[dx12/compute] SKIP — d3d12.dll / dxgi.dll not loadable on this host")
      return
    }
    if shader_cs_spv[0] != (0x07230203 : UInt32) {
      println("[dx12/compute] FAIL — SPIR-V artifact lost its magic number")
      return
    }
    if shader_cs_dxil_bytes != shader_cs_dxil.length() * 4 {
      println("[dx12/compute] FAIL — DXIL padding is not 4-byte aligned")
      return
    }
    let dev = @tycho.Device::new_desc(
      @tycho.DeviceDesc::new(
        "dx12/compute",
        validation=true,
        headless=true,
        backend=@tycho.BackendKind::Dx12,
      ),
    )
    let tex = dev.create_storage_texture(WIDTH, HEIGHT, @tycho.TextureFormat::RGBA8)
    let pipe = dev.create_compute_pipeline(
      shader_cs_dxil,
      0,
      0,
      storage_image_slots=1,
    )

    let cmd = dev.begin_commands()
    cmd.bind_pipeline(pipe)
    cmd.bind_storage_image(pipe, 0, tex)
    cmd.dispatch(WIDTH / GROUP, HEIGHT / GROUP, 1)
    dev.end_commands(cmd)
    let px = tex.readback()
    opts.capture(WIDTH, HEIGHT, px)

    // uv = (x/800, y/600) with blue pinned at 0.5, so the corners and the centre
    // pin the whole gradient.
    let origin = pixel(px, 0, 0)
    let far = pixel(px, WIDTH - 1, HEIGHT - 1)
    let centre = pixel(px, WIDTH / 2, HEIGHT / 2)
    let origin_ok = close(origin.0, 0, 8) && close(origin.1, 0, 8) && close(origin.2, 128, 8)
    let far_ok = close(far.0, 255, 8) && close(far.1, 255, 8) && close(far.2, 128, 8)
    let centre_ok = close(centre.0, 127, 8) && close(centre.1, 127, 8) && close(centre.2, 128, 8)
    let size_ok = px.length() == WIDTH * HEIGHT * 4
    let errs = dev.validation_errors()
    pipe.destroy()
    tex.destroy()
    dev.destroy()

    if size_ok && origin_ok && far_ok && centre_ok && errs == 0 {
      println(
        "[dx12/compute] OK — compute wrote an 800x600 UAV (origin=(\{origin.0}, \{origin.1}, \{origin.2}), centre=(\{centre.0}, \{centre.1}, \{centre.2}), far=(\{far.0}, \{far.1}, \{far.2}), 0 validation errors)",
      )
    } else {
      println(
        "[dx12/compute] FAIL — size_ok=\{size_ok} origin=(\{origin.0}, \{origin.1}, \{origin.2}) far=(\{far.0}, \{far.1}, \{far.2}) centre=(\{centre.0}, \{centre.1}, \{centre.2}) errs=\{errs}",
      )
    }
  } catch {
    err => println("[dx12/compute] FAIL — \{err}")
  }
}
