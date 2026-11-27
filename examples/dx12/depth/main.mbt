// dx12/depth — offscreen render target + depth test on the DX12 backend.
//
// This is the headless counterpart of `dx12/uniform`: the RHI allocates a
// colour target and a `Depth32F` buffer, records into them through
// `Device::begin_commands`, reads the result back, and asserts that the depth
// test decides the visible colour rather than the draw order.
//
// The same triangle is drawn twice at different clip-space z with two uniform
// buffers (green at z=0.25 in front, red at z=0.75 behind). With depth enabled
// and `LESS_EQUAL`, the centre is green in **both** orders; if depth were off
// (or the state machine broke) the second draw would win and one of the two runs
// would come back red.

const SIZE : Int = 128

const TINT_GREEN_R : Float = 0.1

const TINT_GREEN_G : Float = 0.8

const TINT_GREEN_B : Float = 0.3

const TINT_RED_R : Float = 0.9

const TINT_RED_G : Float = 0.1

const TINT_RED_B : Float = 0.1

///|
/// A 32-byte uniform block: `float4 tint` + `float z` + padding, matching the
/// Slang `Uniforms` struct.
fn uniform_block(r : Float, g : Float, b : Float, z : Float) -> FixedArray[Float] {
  [
    r, g, b, (1.0 : Float), // tint
    z, (0.0 : Float), (0.0 : Float), (0.0 : Float), // z + pad
  ]
}

///|
fn pixel(px : FixedArray[Byte], x : Int, y : Int) -> (Int, Int, Int) {
  let i = (y * SIZE + x) * 4
  if i + 3 >= px.length() {
    return (-1, -1, -1)
  }
  (px[i].to_int(), px[i + 1].to_int(), px[i + 2].to_int())
}

///|
fn is_green(rgb : (Int, Int, Int)) -> Bool {
  let (r, g, b) = rgb
  g > 150 && g > r + 80 && g > b + 80
}

///|
fn main {
  let opts = @exwin.Options::parse("dx12/depth")
  try {
    if !@tycho.dx12_available() {
      println("[dx12/depth] SKIP — d3d12.dll / dxgi.dll not loadable on this host")
      return
    }
    // Both artifacts are committed; DXIL is what this backend binds, and the
    // SPIR-V blob is the one Vulkan would take.
    if shader_vs_spv[0] != (0x07230203 : UInt32) || shader_fs_spv[0] != (0x07230203 : UInt32) {
      println("[dx12/depth] FAIL — SPIR-V artifact lost its magic number")
      return
    }
    if shader_vs_dxil_bytes != shader_vs_dxil.length() * 4 ||
      shader_fs_dxil_bytes != shader_fs_dxil.length() * 4 {
      println("[dx12/depth] FAIL — DXIL padding is not 4-byte aligned")
      return
    }
    let dev = @tycho.Device::new_desc(
      @tycho.DeviceDesc::new(
        "dx12/depth",
        validation=true,
        headless=true,
        backend=@tycho.BackendKind::Dx12,
      ),
    )
    let rt = dev.create_render_target(SIZE, SIZE, @tycho.TextureFormat::RGBA8)
    let depth = dev.create_depth_texture(SIZE, SIZE)
    let pipe = dev.create_graphics_pipeline(
      @tycho.PipelineDesc::new(
        shader_vs_dxil,
        shader_fs_dxil,
        uniform_slots=1,
        color_format=@tycho.TextureFormat::RGBA8,
        depth_format=@tycho.TextureFormat::Depth32F,
        depth_test=true,
        depth_write=true,
      ),
    )
    let near = dev.create_buffer(32, @tycho.BufferKind::Uniform)
    near.upload_floats(uniform_block(TINT_GREEN_R, TINT_GREEN_G, TINT_GREEN_B, 0.25))
    let far = dev.create_buffer(32, @tycho.BufferKind::Uniform)
    far.upload_floats(uniform_block(TINT_RED_R, TINT_RED_G, TINT_RED_B, 0.75))

    // Draws the same triangle twice, in the order given, into a freshly cleared
    // target; returns the readback of the centre pixel.
    let render = fn(first : @tycho.Buffer, second : @tycho.Buffer) -> (Int, Int, Int) raise @tycho.RhiError {
      let cmd = dev.begin_commands()
      cmd.begin_render_pass(
        [
          @tycho.RenderTargetDesc::new(
            rt,
            clear_color=@tycho.ClearColor::rgba(0.05, 0.05, 0.1, 1.0),
          ),
        ],
        depth=@tycho.DepthTargetDesc::new(depth),
      )
      cmd.bind_pipeline(pipe)
      cmd.bind_uniform(pipe, 0, first)
      cmd.draw(3, 1)
      cmd.bind_uniform(pipe, 0, second)
      cmd.draw(3, 1)
      cmd.end_render_pass()
      dev.end_commands(cmd)
      pixel(rt.readback(), SIZE / 2, SIZE / 2)
    }

    let far_then_near = render(far, near)
    let near_then_far = render(near, far)
    let shot_pixels = rt.readback()
    opts.capture(SIZE, SIZE, shot_pixels)

    // The uniform buffers come out of the shared RegionPool wrapped around a
    // placed heap, so a non-zero used size proves the pool path ran rather than
    // the committed fallback.
    let pooled_bytes = dev.allocator_used_bytes()
    let pool_ok = pooled_bytes > (0 : UInt64)
    let ok = is_green(far_then_near) && is_green(near_then_far) && pool_ok
    let errs = dev.validation_errors()
    near.destroy()
    far.destroy()
    pipe.destroy()
    rt.destroy()
    depth.destroy()
    dev.destroy()

    if ok && errs == 0 {
      println(
        "[dx12/depth] OK — offscreen RGBA8 + Depth32F, nearer fragment wins in both draw orders (far-first=(\{far_then_near.0}, \{far_then_near.1}, \{far_then_near.2}), near-first=(\{near_then_far.0}, \{near_then_far.1}, \{near_then_far.2}), pooled=\{pooled_bytes} B, 0 validation errors)",
      )
    } else {
      println(
        "[dx12/depth] FAIL — far-first=(\{far_then_near.0}, \{far_then_near.1}, \{far_then_near.2}) green=\{is_green(far_then_near)} near-first=(\{near_then_far.0}, \{near_then_far.1}, \{near_then_far.2}) green'=\{is_green(near_then_far)} errs=\{errs}",
      )
    }
  } catch {
    err => println("[dx12/depth] FAIL — \{err}")
  }
}
