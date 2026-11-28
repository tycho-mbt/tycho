// dx12/advanced — three RHI features that used to be missing or unsupported on the
// DX12 backend, each verified independently:
//
//  1. push constants      -> root constants at `b15, space0`
//  2. storage buffer      -> UAV buffer written by compute and read back
//  3. GPU-side draw count -> `ExecuteIndirect` with a count buffer

const WIDTH : Int = 800

const HEIGHT : Int = 600

// 0.2, 0.6, 0.9, 1.0 in 8-bit terms; the shader writes the tint verbatim.
const TINT_R : Int = 51

const TINT_G : Int = 153

const TINT_B : Int = 230

const STORAGE_FLOATS : Int = 64

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
fn main {
  let opts = @exwin.Options::parse("dx12/advanced")
  try {
    if !@tycho.dx12_available() {
      println("[dx12/advanced] SKIP — d3d12.dll / dxgi.dll not loadable on this host")
      return
    }
    // Both artifacts are committed: DXIL is what this backend binds, SPIR-V is
    // the one Vulkan would take.
    if shader_vs_spv[0] != (0x07230203 : UInt32) ||
      shader_fs_spv[0] != (0x07230203 : UInt32) ||
      shader_cs_spv[0] != (0x07230203 : UInt32) {
      println("[dx12/advanced] FAIL — SPIR-V artifact lost its magic number")
      return
    }
    if shader_vs_dxil_bytes != shader_vs_dxil.length() * 4 ||
      shader_fs_dxil_bytes != shader_fs_dxil.length() * 4 ||
      shader_cs_dxil_bytes != shader_cs_dxil.length() * 4 {
      println("[dx12/advanced] FAIL — DXIL padding is not 4-byte aligned")
      return
    }
    let dev = @tycho.Device::new_desc(
      @tycho.DeviceDesc::new(
        "dx12/advanced",
        validation=true,
        headless=true,
        backend=@tycho.BackendKind::Dx12,
      ),
    )
    let rt = dev.create_render_target(WIDTH, HEIGHT, @tycho.TextureFormat::RGBA8)
    let pipe = dev.create_graphics_pipeline(
      @tycho.PipelineDesc::new(
        shader_vs_dxil,
        shader_fs_dxil,
        push_constant_size=16,
        color_format=@tycho.TextureFormat::RGBA8,
      ),
    )
    let clear = @tycho.ClearColor::rgba(0.05, 0.05, 0.1, 1.0)
    let tint : FixedArray[Float] = [(0.2 : Float), (0.6 : Float), (0.9 : Float), (1.0 : Float)]

    // 1. Push constants: the tint exists only in the root constants block.
    let cmd = dev.begin_commands()
    cmd.begin_render_pass([@tycho.RenderTargetDesc::new(rt, clear_color=clear)])
    cmd.bind_pipeline(pipe)
    cmd.push_constants_floats(pipe, tint)
    cmd.draw(3, 1)
    cmd.end_render_pass()
    dev.end_commands(cmd)
    let push_px = rt.readback()
    opts.capture(WIDTH, HEIGHT, push_px)
    let push_centre = pixel(push_px, WIDTH / 2, HEIGHT / 2)
    let push_ok = near(push_centre, TINT_R, TINT_G, TINT_B, 8)

    // 2. GPU-side count: the same draw args, first with count 0 (nothing must be
    //    drawn), then with count 1.
    let args = dev.create_buffer(16, @tycho.BufferKind::Indirect)
    args.upload_uint32([(3 : UInt32), (1 : UInt32), (0 : UInt32), (0 : UInt32)])
    let counts = dev.create_buffer(4, @tycho.BufferKind::Indirect)
    let mut count_ok = true
    for expected in [0, 1] {
      counts.upload_uint32([expected.reinterpret_as_uint()])
      let pass = dev.begin_commands()
      pass.begin_render_pass([@tycho.RenderTargetDesc::new(rt, clear_color=clear)])
      pass.bind_pipeline(pipe)
      pass.push_constants_floats(pipe, tint)
      pass.draw_indirect_count(args, counts, 1)
      pass.end_render_pass()
      dev.end_commands(pass)
      let px = rt.readback()
      let centre = pixel(px, WIDTH / 2, HEIGHT / 2)
      if expected == 0 {
        // Nothing was drawn: the clear colour must survive.
        count_ok = count_ok && near(centre, 13, 13, 26, 6)
      } else {
        count_ok = count_ok && near(centre, TINT_R, TINT_G, TINT_B, 8)
      }
    }

    // 3. Storage buffer written by compute, read back through a staging copy.
    let cpipe = dev.create_compute_pipeline(shader_cs_dxil, 0, 1)
    let sbuf = dev.create_buffer(STORAGE_FLOATS * 4, @tycho.BufferKind::Storage)
    let ccmd = dev.begin_commands()
    ccmd.bind_pipeline(cpipe)
    ccmd.bind_storage(cpipe, 0, sbuf)
    ccmd.dispatch(1, 1, 1)
    dev.end_commands(ccmd)
    let raw = sbuf.download()
    let mut storage_ok = raw.length() == STORAGE_FLOATS * 4
    let bits = fn(i : Int) -> UInt {
      let b0 = raw[i * 4].to_int().reinterpret_as_uint()
      let b1 = raw[i * 4 + 1].to_int().reinterpret_as_uint()
      let b2 = raw[i * 4 + 2].to_int().reinterpret_as_uint()
      let b3 = raw[i * 4 + 3].to_int().reinterpret_as_uint()
      b0 | (b1 << 8) | (b2 << 16) | (b3 << 24)
    }
    // Values are float(i * 2); for non-negative integers the IEEE bit pattern is
    // monotonic, so a strictly increasing sequence proves every thread ran and
    // wrote its own slot.
    let mut previous = -1
    for i = 0; i < STORAGE_FLOATS; i = i + 1 {
      // For non-negative floats the IEEE bit pattern is monotonic, so comparing
      // raw words proves each thread wrote its own slot (0, 2, 4, ...).
      let value = bits(i).reinterpret_as_int()
      if i == 0 {
        storage_ok = storage_ok && value == 0
      } else {
        storage_ok = storage_ok && value > previous
      }
      previous = value
    }

    let errs = dev.validation_errors()
    sbuf.destroy()
    cpipe.destroy()
    counts.destroy()
    args.destroy()
    pipe.destroy()
    rt.destroy()
    dev.destroy()

    if push_ok && count_ok && storage_ok && errs == 0 {
      println(
        "[dx12/advanced] OK — push constants tinted (\{push_centre.0}, \{push_centre.1}, \{push_centre.2}), GPU count honoured, \{STORAGE_FLOATS} storage floats read back, 0 validation errors",
      )
    } else {
      println(
        "[dx12/advanced] FAIL — push_ok=\{push_ok} centre=(\{push_centre.0}, \{push_centre.1}, \{push_centre.2}) count_ok=\{count_ok} storage_ok=\{storage_ok} errs=\{errs}",
      )
    }
  } catch {
    err => println("[dx12/advanced] FAIL — \{err}")
  }
}
