// dx12/uniform — a uniform slot on the DX12 backend, the counterpart of
// `rhi/uniform`.
//
// The shaders come from one Slang source (`shader.slang`) compiled by
// `tools/gen-dual-shaders.py` into both artifacts: SPIR-V for Vulkan and DXIL for
// DX12, committed in `shader_artifacts.mbt`. The uniform block is declared once
// as `[[vk::binding(0, 0)]]` + `register(b0, space0)`, which is exactly the slot
// mapping the RHI depends on: uniform slot 0 == descriptor set 0 / binding 0 ==
// root CBV 0.
//
// DX12 has no offscreen render-target path in the backend yet, so this runs
// windowed (and SKIPs elsewhere); `rhi/uniform` remains the headless Vulkan
// gate. Add `--window` for an interactive loop, `--screenshot <path>` for a PNG.

const TINT_R : Float = 0.2

const TINT_G : Float = 0.8

const TINT_B : Float = 0.4

///|
fn pixel(px : FixedArray[Byte], w : Int, x : Int, y : Int) -> (Int, Int, Int) {
  let i = (y * w + x) * 4
  if i + 3 >= px.length() {
    return (-1, -1, -1)
  }
  (px[i].to_int(), px[i + 1].to_int(), px[i + 2].to_int())
}

///|
fn main {
  let opts = @exwin.Options::parse("dx12/uniform")
  let w = opts.width
  let h = opts.height
  let show_win = opts.window
  try {
    if !@tycho.dx12_available() {
      println("[dx12/uniform] SKIP — d3d12.dll / dxgi.dll not loadable on this host")
      return
    }
    // Both artifacts are committed: DXIL is what this backend binds, and the
    // SPIR-V blob is the one Vulkan would take. Sanity-check both so a generator
    // regression cannot slip through unnoticed.
    if shader_vs_spv[0] != (0x07230203 : UInt32) || shader_fs_spv[0] != (0x07230203 : UInt32) {
      println("[dx12/uniform] FAIL — SPIR-V artifact lost its magic number")
      return
    }
    if shader_vs_dxil_bytes != shader_vs_dxil.length() * 4 ||
      shader_fs_dxil_bytes != shader_fs_dxil.length() * 4 {
      println("[dx12/uniform] FAIL — DXIL padding is not 4-byte aligned")
      return
    }

    let dev = @tycho.Device::new_desc(
      @tycho.DeviceDesc::new(
        "dx12/uniform",
        validation=true,
        headless=false,
        backend=@tycho.BackendKind::Dx12,
      ),
    )
    let sc = @exwin_rhi.open(
      dev,
      opts,
      clear_color=@tycho.ClearColor::rgba(0.1, 0.2, 0.4, 1.0),
    )
    // One uniform slot -> root CBV 0 in the DX12 root signature.
    let pipe = sc.create_pipeline(shader_vs_dxil, shader_fs_dxil, 1)
    let ubo = dev.create_buffer(16, @tycho.BufferKind::Uniform)
    ubo.upload_floats([TINT_R, TINT_G, TINT_B, (1.0 : Float)])

    let mut frames = 0
    let mut px : FixedArray[Byte] = []
    for i = 0; i < 3; i = i + 1 {
      let cmd = sc.begin_frame()
      cmd.bind_pipeline(pipe)
      cmd.bind_uniform(pipe, 0, ubo)
      cmd.draw(3, 1)
      sc.end_frame(cmd)
      if i == 0 {
        px = sc.readback()
      }
      frames = frames + 1
    }
    let verified_frames = frames
    if show_win {
      while @exwin_rhi.next_frame(sc) {
        let cmd = sc.begin_frame()
        cmd.bind_pipeline(pipe)
        cmd.bind_uniform(pipe, 0, ubo)
        cmd.draw(3, 1)
        sc.end_frame(cmd)
        frames = frames + 1
      }
    }

    let (r, g, b) = pixel(px, w, w / 2, h / 2)
    let size_ok = px.length() == w * h * 4
    let tinted = g > 150 && g > r + 60 && g > b + 60
    if size_ok {
      opts.capture(w, h, px)
    }
    let errs = dev.validation_errors()
    ubo.destroy()
    pipe.destroy()
    sc.destroy()
    dev.destroy()

    if size_ok && tinted && errs == 0 && verified_frames == 3 {
      println(
        "[dx12/uniform] OK — uniform slot tinted the DX12 triangle (centre=(\{r}, \{g}, \{b}), \{frames} frames, 0 validation errors)",
      )
    } else {
      println(
        "[dx12/uniform] FAIL — size_ok=\{size_ok} tinted=\{tinted} centre=(\{r}, \{g}, \{b}) frames=\{frames} errs=\{errs}",
      )
    }
  } catch {
    err => println("[dx12/uniform] FAIL — \{err}")
  }
}
