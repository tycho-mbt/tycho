// rhi/dx12-mrt — two texture slots and multi-render-target output on DX12.
//
// The pass writes two targets at once: a linear RGBA8 target that receives the
// first texture, and an RGBA8_SRGB target that receives the second. sRGB encoding
// makes the two stored byte patterns differ for the same linear value, so the
// assertion pins both the MRT wiring and the format support.

const SIZE : Int = 64

// Linear values uploaded to the two textures: 0.25/0.5/0.75 and 0.5 grey.
const A_R : Int = 64

const A_G : Int = 128

const A_B : Int = 191

// sRGB encode of linear 0.5 is 0.7354, i.e. 188 in 8 bits.
const SRGB_GREY : Int = 188

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
/// A 2x2 texture of one solid colour, tightly packed RGBA8.
fn solid(r : Int, g : Int, b : Int) -> Bytes {
  Bytes::makei(16, fn(i) {
    let channel = i % 4
    let value = if channel == 0 {
      r
    } else if channel == 1 {
      g
    } else if channel == 2 {
      b
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
      println("[rhi/dx12-mrt] SKIP — d3d12.dll / dxgi.dll not loadable on this host")
      return
    }
    if shader_vs_dxil_bytes != shader_vs_dxil.length() * 4 ||
      shader_fs_dxil_bytes != shader_fs_dxil.length() * 4 {
      println("[rhi/dx12-mrt] FAIL — DXIL padding is not 4-byte aligned")
      return
    }
    let dev = @tycho.Device::new_desc(
      @tycho.DeviceDesc::new(
        "rhi/dx12-mrt",
        validation=true,
        headless=true,
        backend=@tycho.BackendKind::Dx12,
      ),
    )
    let rt_linear = dev.create_render_target(SIZE, SIZE, @tycho.TextureFormat::RGBA8)
    let rt_srgb = dev.create_render_target(SIZE, SIZE, @tycho.TextureFormat::RGBA8Srgb)
    let tex_a = dev.create_texture(2, 2, solid(A_R, A_G, A_B))
    let tex_b = dev.create_texture(2, 2, solid(128, 128, 128))
    let samp = dev.create_sampler()
    let pipe = dev.create_graphics_pipeline(
      @tycho.PipelineDesc::new(
        shader_vs_dxil,
        shader_fs_dxil,
        texture_slots=2,
        color_formats=[
          @tycho.TextureFormat::RGBA8,
          @tycho.TextureFormat::RGBA8Srgb,
        ],
      ),
    )

    let cmd = dev.begin_commands()
    cmd.begin_render_pass([
      @tycho.RenderTargetDesc::new(
        rt_linear,
        clear_color=@tycho.ClearColor::rgba(0.0, 0.0, 0.0, 1.0),
      ),
      @tycho.RenderTargetDesc::new(
        rt_srgb,
        clear_color=@tycho.ClearColor::rgba(0.0, 0.0, 0.0, 1.0),
      ),
    ])
    cmd.bind_pipeline(pipe)
    cmd.bind_texture(pipe, 0, tex_a, samp)
    cmd.bind_texture(pipe, 1, tex_b, samp)
    cmd.draw(3, 1)
    cmd.end_render_pass()
    dev.end_commands(cmd)
    let px_linear = rt_linear.readback()
    let px_srgb = rt_srgb.readback()
    if shot != "" {
      let _ = @tycho.save_png(shot, SIZE, SIZE, px_linear)
    }

    let linear_centre = pixel(px_linear, SIZE / 2, SIZE / 2)
    let srgb_centre = pixel(px_srgb, SIZE / 2, SIZE / 2)
    let linear_ok = near(linear_centre, A_R, A_G, A_B, 8)
    // An sRGB target stores the encoded value, so 0.5 linear lands near 188.
    let srgb_ok = near(srgb_centre, SRGB_GREY, SRGB_GREY, SRGB_GREY, 8)
    let size_ok = px_linear.length() == SIZE * SIZE * 4 && px_srgb.length() == SIZE * SIZE * 4
    let errs = dev.validation_errors()
    samp.destroy()
    tex_b.destroy()
    tex_a.destroy()
    pipe.destroy()
    rt_srgb.destroy()
    rt_linear.destroy()
    dev.destroy()

    if size_ok && linear_ok && srgb_ok && errs == 0 {
      println(
        "[rhi/dx12-mrt] OK — two texture slots + MRT (linear=(\{linear_centre.0}, \{linear_centre.1}, \{linear_centre.2}), srgb=(\{srgb_centre.0}, \{srgb_centre.1}, \{srgb_centre.2}), 0 validation errors)",
      )
    } else {
      println(
        "[rhi/dx12-mrt] FAIL — linear=(\{linear_centre.0}, \{linear_centre.1}, \{linear_centre.2}) srgb=(\{srgb_centre.0}, \{srgb_centre.1}, \{srgb_centre.2}) linear_ok=\{linear_ok} srgb_ok=\{srgb_ok} errs=\{errs}",
      )
    }
  } catch {
    err => println("[rhi/dx12-mrt] FAIL — \{err}")
  }
}
