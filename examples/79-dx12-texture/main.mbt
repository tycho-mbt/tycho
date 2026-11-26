// Example 79 — sampled texture on the DX12 backend, the counterpart of
// `11-rhi-texture`, rendered offscreen so it needs no window.
//
// Exercises the first half of the descriptor work: an upload-heap texture gains a
// shader-visible SRV, the pipeline declares one SRV descriptor table (t0, space 0)
// plus a static sampler (s0, linear/clamp), and `bind_texture` points the table at
// the texture. A 2x2 albedo with four distinct colours fills the viewport, so the
// four quadrants must come back as those four colours.

const SIZE : Int = 128

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
/// A 2x2 RGBA8 albedo: red, green, blue, yellow.
fn albedo() -> Bytes {
  Bytes::makei(16, fn(i) {
    let texel = i / 4
    let channel = i % 4
    let color = match texel {
      0 => (255, 0, 0)
      1 => (0, 255, 0)
      2 => (0, 0, 255)
      _ => (255, 255, 0)
    }
    let value = if channel == 0 {
      color.0
    } else if channel == 1 {
      color.1
    } else if channel == 2 {
      color.2
    } else {
      255
    }
    value.to_byte()
  })
}

///|
fn main {
  let shot = @tycho.screenshot_path()
  try {
    if !@tycho.dx12_available() {
      println("[79-dx12-texture] SKIP — d3d12.dll / dxgi.dll not loadable on this host")
      return
    }
    if shader_vs_spv[0] != (0x07230203 : UInt32) || shader_fs_spv[0] != (0x07230203 : UInt32) {
      println("[79-dx12-texture] FAIL — SPIR-V artifact lost its magic number")
      return
    }
    if shader_vs_dxil_bytes != shader_vs_dxil.length() * 4 ||
      shader_fs_dxil_bytes != shader_fs_dxil.length() * 4 {
      println("[79-dx12-texture] FAIL — DXIL padding is not 4-byte aligned")
      return
    }
    let dev = @tycho.Device::new_desc(
      @tycho.DeviceDesc::new(
        "79-dx12-texture",
        validation=true,
        headless=true,
        backend=@tycho.BackendKind::Dx12,
      ),
    )
    let rt = dev.create_render_target(SIZE, SIZE, @tycho.TextureFormat::RGBA8)
    let tex = dev.create_texture(2, 2, albedo())
    let samp = dev.create_sampler()
    let pipe = dev.create_graphics_pipeline(
      @tycho.PipelineDesc::new(
        shader_vs_dxil,
        shader_fs_dxil,
        texture_slots=1,
        color_format=Some(@tycho.TextureFormat::RGBA8),
      ),
    )

    let cmd = dev.begin_commands()
    cmd.begin_render_pass(
      [
        @tycho.RenderTargetDesc::new(
          rt,
          clear_color=@tycho.ClearColor::rgba(0.0, 0.0, 0.0, 1.0),
        ),
      ],
    )
    cmd.bind_pipeline(pipe)
    cmd.bind_texture(pipe, 0, tex, samp)
    cmd.draw(3, 1)
    cmd.end_render_pass()
    dev.end_commands(cmd)
    let px = rt.readback()
    if shot != "" {
      let _ = @tycho.save_png(shot, SIZE, SIZE, px)
    }

    // Orientation is a backend detail (the DX12 path flips Y), so compare the four
    // quadrants as a set instead of pinning each corner.
    let quads = [
      pixel(px, SIZE / 4, SIZE / 4),
      pixel(px, SIZE * 3 / 4, SIZE / 4),
      pixel(px, SIZE / 4, SIZE * 3 / 4),
      pixel(px, SIZE * 3 / 4, SIZE * 3 / 4),
    ]
    let want = [(255, 0, 0), (0, 255, 0), (0, 0, 255), (255, 255, 0)]
    let mut matched = 0
    for target in want {
      for got in quads {
        if near(got, target.0, target.1, target.2, 24) {
          matched = matched + 1
          break
        }
      }
    }
    let size_ok = px.length() == SIZE * SIZE * 4
    let errs = dev.validation_errors()
    samp.destroy()
    tex.destroy()
    pipe.destroy()
    rt.destroy()
    dev.destroy()

    if size_ok && matched == 4 && errs == 0 {
      println(
        "[79-dx12-texture] OK — 2x2 albedo sampled through an SRV table + sampler heap (\{matched}/4 quadrants matched, \{SIZE}x\{SIZE}, 0 validation errors)",
      )
    } else {
      println(
        "[79-dx12-texture] FAIL — size_ok=\{size_ok} matched=\{matched}/4 tl=(\{quads[0].0}, \{quads[0].1}, \{quads[0].2}) tr=(\{quads[1].0}, \{quads[1].1}, \{quads[1].2}) bl=(\{quads[2].0}, \{quads[2].1}, \{quads[2].2}) br=(\{quads[3].0}, \{quads[3].1}, \{quads[3].2}) errs=\{errs}",
      )
    }
  } catch {
    err => println("[79-dx12-texture] FAIL — \{err}")
  }
}
