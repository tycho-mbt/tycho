// dx12/triangle — Windows Direct3D 12 offscreen triangle (M1a vertical slice):
// device -> command list -> graphics PSO from embedded DXIL -> render target
// -> readback, all through laplaceliu/tycho_dx12 (runtime-loaded d3d12.dll /
// dxgi.dll, no C in this package and no import libraries).
//
// Default: headless offscreen verification, CI friendly.
// `--window` (or TYCHO_WINDOW=1): present the same triangle in a Win32 window.
// `--screenshot <path>` (or TYCHO_SCREENSHOT): write the verified frame as PNG.
//
// Adapter choice: hardware first, WARP as fallback; TYCHO_DX12_WARP=1 forces
// WARP so a GPU-less CI runner exercises exactly the same binary.
// Non-Windows hosts report SKIP.

const CANVAS_W : Int = 128

const CANVAS_H : Int = 128

const WINDOW_W : Int = 480

const WINDOW_H : Int = 320

const CLEAR_R : Float = 0.1

const CLEAR_G : Float = 0.2

const CLEAR_B : Float = 0.4

///|
fn fail(what : String) -> Unit {
  println("[dx12/triangle] FAIL — \{what} (last HRESULT=\{@dx12.last_error()})")
}

///|
fn pixel(px : FixedArray[Byte], w : Int, x : Int, y : Int) -> (Int, Int, Int) {
  let i = (y * w + x) * 4
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
/// The three vertices land at (w/2, 3h/4) red, (3w/4, h/4) green and (w/4, h/4)
/// blue, so each sample sits a fraction of the way inside from its vertex.
fn frame_ok(px : FixedArray[Byte], w : Int, h : Int) -> Bool {
  let inset_x = w / 24
  let inset_y = h / 24
  px.length() == w * h * 4 &&
  near(pixel(px, w, 2, 2), 26, 51, 102, 6) &&
  dominant(pixel(px, w, w / 2, h * 3 / 4 - inset_y), 0) &&
  dominant(pixel(px, w, w * 3 / 4 - inset_x, h / 4 + inset_y), 1) &&
  dominant(pixel(px, w, w / 4 + inset_x, h / 4 + inset_y), 2)
}

///|
/// Records one frame into `target` and, when `capture` is set, copies it out
/// before the target returns to the PRESENT state.
fn draw_frame(
  device : @dx12.Device,
  cmd : @dx12.CommandList,
  pipe : @dx12.Pipeline,
  target : @dx12.Texture,
  rb : @dx12.Readback,
  capture : Bool,
) -> (Bool, FixedArray[Byte]?) {
  let mut ok = cmd.begin()
  ok = ok && cmd.transition(target, @dx12.ResourceState::RenderTarget)
  ok = ok && cmd.clear(target, CLEAR_R, CLEAR_G, CLEAR_B, 1.0)
  ok = ok && cmd.set_pipeline(pipe)
  ok = ok && cmd.draw(target, 3)
  if capture {
    ok = ok && cmd.transition(target, @dx12.ResourceState::CopySource)
    ok = ok && cmd.copy_to_readback(target, rb)
  }
  ok = ok && cmd.transition(target, @dx12.ResourceState::Present)
  ok = ok && cmd.execute_wait(device)
  let px = if ok && capture {
    let bytes = rb.bytes()
    Some(FixedArray::makei(bytes.length(), fn(i) { bytes[i] }))
  } else {
    None
  }
  (ok, px)
}

///|
fn main {
  let show_win = @shader.want_window()
  let shot = @shader.screenshot_path()
  if !@dx12.available() {
    println("[dx12/triangle] SKIP — d3d12.dll / dxgi.dll not loadable on this host")
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
  let cmd = match @dx12.CommandList::create(device) {
    Some(c) => c
    None => {
      fail("command list")
      pipeline.destroy()
      device.destroy()
      return
    }
  }

  let mut frames = 0
  let mut ok = true
  let mut pixels_ok = false
  let mut size = (0, 0)
  let mut px : FixedArray[Byte] = []

  if show_win {
    if @win.initialize() == 0 {
      println("[dx12/triangle] SKIP — user32.dll unavailable")
      cmd.destroy()
      pipeline.destroy()
      device.destroy()
      return
    }
    let win = @win.create(WINDOW_W, WINDOW_H, "dx12/triangle")
    if win == (0 : UInt64) {
      println("[dx12/triangle] SKIP — no Win32 window")
      cmd.destroy()
      pipeline.destroy()
      device.destroy()
      return
    }
    let swapchain = match @dx12.Swapchain::create(
      device,
      @win.native_handle(win),
      WINDOW_W,
      WINDOW_H,
    ) {
      Some(s) => s
      None => {
        println("[dx12/triangle] SKIP — no DXGI swapchain for this window")
        @win.destroy(win)
        cmd.destroy()
        pipeline.destroy()
        device.destroy()
        return
      }
    }
    let rb = match @dx12.Readback::create(device, WINDOW_W, WINDOW_H) {
      Some(r) => r
      None => {
        fail("readback buffer")
        swapchain.destroy()
        @win.destroy(win)
        cmd.destroy()
        pipeline.destroy()
        device.destroy()
        return
      }
    }
    size = (WINDOW_W, WINDOW_H)
    let mut present_failed = false
    while @win.should_close(win) == 0 && !present_failed {
      @win.poll()
      let target = match swapchain.target(swapchain.current_index()) {
        Some(t) => t
        None => {
          present_failed = true
          break
        }
      }
      let (frame_drawn, captured) = draw_frame(device, cmd, pipeline, target, rb, frames == 0)
      target.destroy()
      ok = ok && frame_drawn
      if frames == 0 {
        match captured {
          Some(p) => px = p
          None => ()
        }
      }
      match swapchain.present() {
        @dx12.PresentResult::Failed => present_failed = true
        _ => ()
      }
      frames = frames + 1
    }
    pixels_ok = frame_ok(px, WINDOW_W, WINDOW_H)
    let _ = device.wait_idle()
    rb.destroy()
    swapchain.destroy()
    @win.destroy(win)
  } else {
    let target = match @dx12.Texture::create(device, CANVAS_W, CANVAS_H) {
      Some(t) => t
      None => {
        fail("render target")
        cmd.destroy()
        pipeline.destroy()
        device.destroy()
        return
      }
    }
    let rb = match @dx12.Readback::create(device, CANVAS_W, CANVAS_H) {
      Some(r) => r
      None => {
        fail("readback buffer")
        target.destroy()
        cmd.destroy()
        pipeline.destroy()
        device.destroy()
        return
      }
    }
    size = (CANVAS_W, CANVAS_H)
    let (frame_drawn, captured) = draw_frame(device, cmd, pipeline, target, rb, true)
    ok = frame_drawn
    match captured {
      Some(p) => px = p
      None => ()
    }
    frames = 1
    pixels_ok = frame_ok(px, CANVAS_W, CANVAS_H)
    let _ = device.wait_idle()
    rb.destroy()
    target.destroy()
  }

  if shot != "" && px.length() > 0 {
    let (w, h) = size
    let _ = @shader.save_png(shot, w, h, px)
  }

  let errs = device.validation_errors()
  let adapter = if device.is_warp() { "warp" } else { "hardware" }
  let shader_model = device.shader_model()
  cmd.destroy()
  pipeline.destroy()
  device.destroy()

  if ok && pixels_ok && errs == 0 {
    let (w, h) = size
    let mode = if show_win { "windowed" } else { "offscreen" }
    println(
      "[dx12/triangle] OK — D3D12 \{mode} triangle (\{w}x\{h}, \{frames} frame(s), adapter=\{adapter}, shader model 6.\{shader_model % 16}, clear + 3 vertex regions verified, 0 validation errors)",
    )
  } else {
    println(
      "[dx12/triangle] FAIL — command_ok=\{ok} pixels_ok=\{pixels_ok} frames=\{frames} errs=\{errs}",
    )
  }
}
