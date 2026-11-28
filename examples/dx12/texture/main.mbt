// dx12/texture — sampled texture on the DX12 backend, the counterpart of
// `rhi/texture`, rendered offscreen so it needs no window.
//
// Exercises the first half of the descriptor work: an upload-heap texture gains a
// shader-visible SRV, the pipeline declares one SRV descriptor table (t0, space 0)
// plus a static sampler (s0, linear/clamp), and `bind_texture` points the table at
// the texture. A 2x2 albedo with four distinct colours fills the viewport, so the
// four quadrants must come back as those four colours.

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
  let opts = @exwin.Options::parse("dx12/texture")
  try {
    if !@tycho.dx12_available() {
      println("[dx12/texture] SKIP — d3d12.dll / dxgi.dll not loadable on this host")
      return
    }
    if shader_vs_spv[0] != (0x07230203 : UInt32) || shader_fs_spv[0] != (0x07230203 : UInt32) {
      println("[dx12/texture] FAIL — SPIR-V artifact lost its magic number")
      return
    }
    if shader_vs_dxil_bytes != shader_vs_dxil.length() * 4 ||
      shader_fs_dxil_bytes != shader_fs_dxil.length() * 4 {
      println("[dx12/texture] FAIL — DXIL padding is not 4-byte aligned")
      return
    }
    let dev = @tycho.Device::new_desc(
      @tycho.DeviceDesc::new(
        "dx12/texture",
        validation=true,
        headless=true,
        backend=@tycho.BackendKind::Dx12,
      ),
    )
    let rt = dev.create_render_target(WIDTH, HEIGHT, @tycho.TextureFormat::RGBA8)
    let tex = dev.create_texture(2, 2, albedo())
    // ClampToEdge keeps the albedo stretched exactly once over the viewport; the
    // default descriptor repeats it, which would tile the 2x2 texels.
    let samp = dev.create_sampler_desc(
      @tycho.SamplerDesc::new(address=@tycho.AddressMode::ClampToEdge),
    )
    let pipe = dev.create_graphics_pipeline(
      @tycho.PipelineDesc::new(
        shader_vs_dxil,
        shader_fs_dxil,
        texture_slots=1,
        color_format=@tycho.TextureFormat::RGBA8,
      ),
    )

    // Renders one frame with `sampler` bound to slot 0 and reads it back.
    let render = fn(sampler : @tycho.Sampler) -> FixedArray[Byte] raise @tycho.RhiError {
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
      cmd.bind_texture(pipe, 0, tex, sampler)
      cmd.draw(3, 1)
      cmd.end_render_pass()
      dev.end_commands(cmd)
      rt.readback()
    }
    let px = render(samp)
    opts.capture(WIDTH, HEIGHT, px)

    // Orientation is a backend detail (the DX12 path flips Y), so compare the four
    // quadrants as a set instead of pinning each corner.
    let quads = [
      pixel(px, WIDTH / 4, HEIGHT / 4),
      pixel(px, WIDTH * 3 / 4, HEIGHT / 4),
      pixel(px, WIDTH / 4, HEIGHT * 3 / 4),
      pixel(px, WIDTH * 3 / 4, HEIGHT * 3 / 4),
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
    // `SamplerDesc` must actually reach the heap: at the exact centre of the
    // image the four texels meet, so a linear sampler averages them into a grey
    // while a point sampler returns one pure colour.
    let nearest = dev.create_sampler_desc(
      @tycho.SamplerDesc::new(
        mag=@tycho.Filter::Nearest,
        min=@tycho.Filter::Nearest,
        mipmap=@tycho.Filter::Nearest,
        address=@tycho.AddressMode::ClampToEdge,
      ),
    )
    let px_point = render(nearest)
    let centre_linear = pixel(px, WIDTH / 2, HEIGHT / 2)
    let centre_point = pixel(px_point, WIDTH / 2, HEIGHT / 2)
    let spread = fn(rgb : (Int, Int, Int)) -> Int {
      let (r, g, b) = rgb
      let hi = if r > g {
        if r > b {
          r
        } else {
          b
        }
      } else if g > b {
        g
      } else {
        b
      }
      let lo = if r < g {
        if r < b {
          r
        } else {
          b
        }
      } else if g < b {
        g
      } else {
        b
      }
      hi - lo
    }
    let linear_is_averaged = spread(centre_linear) < 100
    let point_is_pure = spread(centre_point) > 150
    nearest.destroy()

    // Descriptor slots are recycled: the heap holds 16 samplers, so 40 create /
    // destroy cycles only succeed if a destroyed slot is handed out again.
    let mut recycles = 0
    for i = 0; i < 40; i = i + 1 {
      let scratch = dev.create_sampler()
      scratch.destroy()
      recycles = recycles + 1
    }
    let slots_recycled = recycles == 40

    let size_ok = px.length() == WIDTH * HEIGHT * 4
    let errs = dev.validation_errors()
    samp.destroy()
    tex.destroy()
    pipe.destroy()
    rt.destroy()
    dev.destroy()

    if size_ok &&
      matched == 4 &&
      linear_is_averaged &&
      point_is_pure &&
      slots_recycled &&
      errs == 0 {
      println(
        "[dx12/texture] OK — 2x2 albedo sampled through an SRV table + sampler heap (\{matched}/4 quadrants matched, linear centre=(\{centre_linear.0}, \{centre_linear.1}, \{centre_linear.2}) averaged, point centre=(\{centre_point.0}, \{centre_point.1}, \{centre_point.2}) pure, \{recycles} sampler slots recycled, 0 validation errors)",
      )
    } else {
      println(
        "[dx12/texture] FAIL — size_ok=\{size_ok} matched=\{matched}/4 linear_avg=\{linear_is_averaged} point_pure=\{point_is_pure} recycled=\{slots_recycled} linear_centre=(\{centre_linear.0}, \{centre_linear.1}, \{centre_linear.2}) point_centre=(\{centre_point.0}, \{centre_point.1}, \{centre_point.2}) errs=\{errs}",
      )
    }
  } catch {
    err => println("[dx12/texture] FAIL — \{err}")
  }
}
