// Example 74 — Windows Direct3D 12 offscreen triangle (M1a vertical slice):
// device -> command list -> graphics PSO from embedded DXIL -> render target
// -> readback, all through laplaceliu/tycho_dx12 (runtime-loaded d3d12.dll /
// dxgi.dll, no C in this package and no import libraries).
//
// Adapter choice: hardware first, WARP as fallback; TYCHO_DX12_WARP=1 forces
// WARP so a GPU-less CI runner exercises exactly the same binary.
// Non-Windows hosts report SKIP.

const WIDTH : Int = 128

const HEIGHT : Int = 128

const CLEAR_R : Float = 0.1

const CLEAR_G : Float = 0.2

const CLEAR_B : Float = 0.4

///|
fn fail(what : String) -> Unit {
  println("[74-dx12-triangle] FAIL — \{what} (last HRESULT=\{@dx12.last_error()})")
}

///|
fn pixel(px : Bytes, x : Int, y : Int) -> (Int, Int, Int) {
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
fn dominant(rgb : (Int, Int, Int), channel : Int) -> Bool {
  let (r, g, b) = rgb
  let major = if channel == 0 { r } else if channel == 1 { g } else { b }
  let other_a = if channel == 0 { g } else { r }
  let other_b = if channel == 2 { g } else { b }
  major > 150 && major > other_a + 60 && major > other_b + 60
}

///|
fn main {
  if !@dx12.available() {
    println("[74-dx12-triangle] SKIP — d3d12.dll / dxgi.dll not loadable on this host")
    return
  }

  let want_warp = @dx12.env_requests_warp()
  let device = match @dx12.Device::create(warp=want_warp, debug=true) {
    Some(d) => d
    None =>
      match @dx12.Device::create(warp=true, debug=true) {
        Some(d) => d
        None => {
          fail("no D3D12 device (hardware and WARP both refused)")
          return
        }
      }
  }

  let pipeline = match @dx12.Pipeline::create(
    device,
    dx12_triangle_vs,
    dx12_triangle_vs_bytes,
    dx12_triangle_ps,
    dx12_triangle_ps_bytes,
  ) {
    Some(p) => p
    None => {
      let errs = device.validation_errors()
      fail("CreateGraphicsPipelineState, debug-layer messages=\{errs}")
      device.destroy()
      return
    }
  }
  let target = match @dx12.Texture::create(device, WIDTH, HEIGHT) {
    Some(t) => t
    None => {
      fail("render target")
      pipeline.destroy()
      device.destroy()
      return
    }
  }
  let readback = match @dx12.Readback::create(device, WIDTH, HEIGHT) {
    Some(r) => r
    None => {
      fail("readback buffer")
      target.destroy()
      pipeline.destroy()
      device.destroy()
      return
    }
  }

  let ok = match @dx12.CommandList::create(device) {
    Some(cmd) => {
      let mut steps_ok = cmd.begin()
      steps_ok = steps_ok && cmd.barrier_to_render_target(target)
      steps_ok = steps_ok &&
        cmd.clear(target, CLEAR_R, CLEAR_G, CLEAR_B, 1.0)
      steps_ok = steps_ok && cmd.set_pipeline(pipeline)
      steps_ok = steps_ok && cmd.draw(target, 3)
      steps_ok = steps_ok && cmd.barrier_to_copy_source(target)
      steps_ok = steps_ok && cmd.copy_to_readback(target, readback)
      steps_ok = steps_ok && cmd.execute_wait(device)
      cmd.destroy()
      steps_ok
    }
    None => {
      fail("command list")
      false
    }
  }
  if !ok {
    fail("command recording / submission")
  }

  let px = readback.bytes()
  let adapter = if device.is_warp() { "warp" } else { "hardware" }
  let shader_model = device.shader_model()
  let clear_rgb = pixel(px, 2, 2)
  // NDC -> framebuffer row is y_row = (1 - (y * 0.5 + 0.5)) * height, so the
  // three vertices land at (64,96) red, (96,32) green and (32,32) blue; sample
  // each one a few pixels inside the triangle.
  let red_rgb = pixel(px, WIDTH / 2, HEIGHT - 40)
  let green_rgb = pixel(px, WIDTH * 3 / 4 - 6, 37)
  let blue_rgb = pixel(px, WIDTH / 4 + 6, 37)
  let clear_ok = near(clear_rgb, 26, 51, 102, 6)
  let red_ok = dominant(red_rgb, 0)
  let green_ok = dominant(green_rgb, 1)
  let blue_ok = dominant(blue_rgb, 2)
  let size_ok = px.length() == WIDTH * HEIGHT * 4
  let errs = device.validation_errors()

  readback.destroy()
  target.destroy()
  pipeline.destroy()
  device.destroy()

  if ok && clear_ok && red_ok && green_ok && blue_ok && size_ok && errs == 0 {
    println(
      "[74-dx12-triangle] OK — D3D12 offscreen triangle (\{WIDTH}x\{HEIGHT}, adapter=\{adapter}, shader model 6.\{shader_model % 16}, clear + 3 vertex regions verified, 0 validation errors)",
    )
  } else {
    let (cr, cg, cb) = clear_rgb
    let (rr, rg, rb) = red_rgb
    let (gr, gg, gb) = green_rgb
    let (br, bg, bb) = blue_rgb
    println(
      "[74-dx12-triangle] FAIL — command_ok=\{ok} size_ok=\{size_ok} clear_ok=\{clear_ok}(\{cr},\{cg},\{cb}) red_ok=\{red_ok}(\{rr},\{rg},\{rb}) green_ok=\{green_ok}(\{gr},\{gg},\{gb}) blue_ok=\{blue_ok}(\{br},\{bg},\{bb}) errs=\{errs}",
    )
  }
}
