// dx12/rhi-triangle — the Tycho RHI on the Direct3D 12 backend.
//
// Uses exactly the same façade as `rhi/triangle` (Device / Swapchain /
// Pipeline / CommandBuffer), selecting `BackendKind::Dx12` in the device
// descriptor. The shader blobs are DXIL on this backend: the RHI keeps one
// pipeline entry point whose words are SPIR-V on Vulkan and DXIL on DX12 until
// the cross-compiled-artifact plumbing lands.
//
// Non-Windows hosts and machines without d3d12.dll report SKIP.

///|
fn pixel(px : FixedArray[Byte], w : Int, x : Int, y : Int) -> (Int, Int, Int) {
  let i = (y * w + x) * 4
  if i + 3 >= px.length() {
    return (-1, -1, -1)
  }
  (px[i].to_int(), px[i + 1].to_int(), px[i + 2].to_int())
}

///|
fn dominant(rgb : (Int, Int, Int), channel : Int) -> Bool {
  let (r, g, b) = rgb
  let major = if channel == 0 { r } else if channel == 1 { g } else { b }
  let other_a = if channel == 0 { g } else { r }
  let other_b = if channel == 2 { g } else { b }
  major > 150 && major > other_a + 60 && major > other_b + 60
}

///|
fn main {
  let opts = @exwin.Options::parse("dx12/rhi-triangle")
  let w = opts.width
  let h = opts.height
  let show_win = opts.window
  try {
    if !@tycho.dx12_available() {
      println("[dx12/rhi-triangle] SKIP — d3d12.dll / dxgi.dll not loadable on this host")
      return
    }
    // DXIL containers are 4-byte aligned, which is what lets the single RHI
    // pipeline entry point derive the byte length from the word count.
    if dx12_rhi_vs_bytes != dx12_rhi_vs.length() * 4 ||
      dx12_rhi_ps_bytes != dx12_rhi_ps.length() * 4 {
      println("[dx12/rhi-triangle] FAIL — DXIL padding is not 4-byte aligned")
      return
    }
    let dev = @tycho.Device::new_desc(
      @tycho.DeviceDesc::new(
        "dx12/rhi-triangle",
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
    let pipe = sc.create_pipeline(dx12_rhi_vs, dx12_rhi_ps, 0)

    let mut frames = 0
    let mut px : FixedArray[Byte] = []
    for i = 0; i < 3; i = i + 1 {
      let cmd = sc.begin_frame()
      cmd.bind_pipeline(pipe)
      cmd.draw(3, 1)
      sc.end_frame(cmd)
      if i == 0 {
        px = sc.readback()
      }
      frames = frames + 1
    }
    let verified_frames = frames

    // `--window` keeps presenting until the window is closed (or Esc), exactly
    // like the Vulkan RHI examples; the verification frames above already ran.
    if show_win {
      while @exwin_rhi.next_frame(sc) {
        let cmd = sc.begin_frame()
        cmd.bind_pipeline(pipe)
        cmd.draw(3, 1)
        sc.end_frame(cmd)
        frames = frames + 1
      }
    }

    // The DX12 backend renders with a negative viewport height (Vulkan clip-space
    // convention, docs/original-design/03-dx12.md §6.1 item 2), so NDC y=-0.5 is
    // the top row: red sits at the apex (h/4), green and blue on the base (3h/4).
    let red_ok = dominant(pixel(px, w, w / 2, h / 4 + 8), 0)
    let green_ok = dominant(pixel(px, w, w * 3 / 4 - 8, h * 3 / 4 - 8), 1)
    let blue_ok = dominant(pixel(px, w, w / 4 + 8, h * 3 / 4 - 8), 2)
    let size_ok = px.length() == w * h * 4
    if px.length() == w * h * 4 {
      opts.capture(w, h, px)
    }
    let errs = dev.validation_errors()
    pipe.destroy()
    sc.destroy()
    dev.destroy()

    if red_ok && green_ok && blue_ok && size_ok && errs == 0 && verified_frames == 3 {
      println(
        "[dx12/rhi-triangle] OK — RHI triangle on the DX12 backend (\{w}x\{h}, \{frames} frames, 3 vertex regions verified, 0 validation errors)",
      )
    } else {
      println(
        "[dx12/rhi-triangle] FAIL — red=\{red_ok} green=\{green_ok} blue=\{blue_ok} size=\{size_ok} frames=\{frames} errs=\{errs}",
      )
    }
  } catch {
    err => println("[dx12/rhi-triangle] FAIL — \{err}")
  }
}
