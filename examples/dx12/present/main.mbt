// dx12/present — Windows DXGI flip-model presentation through laplaceliu/tycho_dx12:
// native Win32 window (tycho_window) -> swapchain -> render into the back buffer
// -> Present, plus one back-buffer readback and one ResizeBuffers cycle.
//
// Reports SKIP on non-Windows hosts and when the desktop refuses a swapchain
// (a session-0 CI runner), so the gate stays honest everywhere.

const WIDTH : Int = 480

const HEIGHT : Int = 320

const CLEAR_R : Float = 0.05

const CLEAR_G : Float = 0.05

const CLEAR_B : Float = 0.25

///|
fn fail(what : String) -> Unit {
  println("[dx12/present] FAIL — \{what} (last HRESULT=\{@dx12.last_error()})")
}

///|
fn unsupported(what : String) -> Unit {
  println("[dx12/present] SKIP — \{what} (last HRESULT=\{@dx12.last_error()})")
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
/// Records one frame into the current back buffer. Returns the frame status and,
/// when `capture` is set, the pixels copied out before presentation.
fn render_frame(
  dev : @dx12.Device,
  sc : @dx12.Swapchain,
  cmd : @dx12.CommandList,
  pipe : @dx12.Pipeline,
  rb : @dx12.Readback,
  capture : Bool,
) -> (Bool, Bytes?) {
  let target = match sc.target(sc.current_index()) {
    Some(t) => t
    None => return (false, None)
  }
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
  ok = ok && cmd.execute_wait(dev)
  let captured = if ok && capture { Some(rb.bytes()) } else { None }
  target.destroy()
  (ok, captured)
}

///|
fn main {
  let show_win = @shader.want_window()
  let shot = @shader.screenshot_path()
  if !@dx12.available() {
    println("[dx12/present] SKIP — d3d12.dll / dxgi.dll not loadable on this host")
    return
  }
  match @win.platform() {
    @win.Platform::Windows => ()
    _ => {
      println("[dx12/present] SKIP — DXGI presentation is Windows-only")
      return
    }
  }
  if @win.initialize() == 0 {
    println("[dx12/present] SKIP — user32.dll unavailable")
    return
  }

  let win = @win.create(480, 320, "dx12/present")
  if win == (0 : UInt64) {
    println("[dx12/present] SKIP — no window from the Win32 backend")
    return
  }
  let hwnd = @win.native_handle(win)

  let want_warp = @dx12.env_requests_warp()
  let device = match @dx12.Device::create(warp=want_warp, debug=true) {
    Some(d) => d
    None =>
      match @dx12.Device::create(warp=true, debug=true) {
        Some(d) => d
        None => {
          fail("no D3D12 device (hardware and WARP both refused)")
          @win.destroy(win)
          return
        }
      }
  }
  let pipeline = match @dx12.Pipeline::create(
    device,
    dx12_present_vs,
    dx12_present_vs_bytes,
    dx12_present_ps,
    dx12_present_ps_bytes,
  ) {
    Some(p) => p
    None => {
      fail("CreateGraphicsPipelineState")
      device.destroy()
      @win.destroy(win)
      return
    }
  }
  let swapchain = match @dx12.Swapchain::create(device, hwnd, WIDTH, HEIGHT) {
    Some(s) => s
    None => {
      unsupported("no DXGI swapchain for this window")
      pipeline.destroy()
      device.destroy()
      @win.destroy(win)
      return
    }
  }
  let readback = match @dx12.Readback::create(device, WIDTH, HEIGHT) {
    Some(r) => r
    None => {
      fail("readback buffer")
      swapchain.destroy()
      pipeline.destroy()
      device.destroy()
      @win.destroy(win)
      return
    }
  }
  let cmd = match @dx12.CommandList::create(device) {
    Some(c) => c
    None => {
      fail("command list")
      readback.destroy()
      swapchain.destroy()
      pipeline.destroy()
      device.destroy()
      @win.destroy(win)
      return
    }
  }

  let mut frames = 0
  let mut presented = 0
  let mut occluded = 0
  let mut present_failed = false
  let mut all_ok = true
  let mut captured : Bytes? = None

  // Frame 0: render, copy the back buffer out, then present.
  for i = 0; i < 3; i = i + 1 {
    let (ok, px) = render_frame(device, swapchain, cmd, pipeline, readback, i == 0)
    all_ok = all_ok && ok
    if i == 0 {
      captured = px
    }
    if ok {
      frames = frames + 1
      match swapchain.present() {
        @dx12.PresentResult::Presented => presented = presented + 1
        @dx12.PresentResult::Occluded => occluded = occluded + 1
        @dx12.PresentResult::Failed => present_failed = true
      }
    }
  }

  // ResizeBuffers cycle at the same extent: this is the code path a WM_SIZE
  // triggers, and it must recreate the descriptor heap and the RTVs.
  let resized = swapchain.resize(device, WIDTH, HEIGHT)
  let (resize_frame_ok, _) = render_frame(device, swapchain, cmd, pipeline, readback, false)
  if resize_frame_ok {
    frames = frames + 1
    match swapchain.present() {
      @dx12.PresentResult::Presented => presented = presented + 1
      @dx12.PresentResult::Occluded => occluded = occluded + 1
      @dx12.PresentResult::Failed => present_failed = true
    }
  }

  // The verification frames are done; `--window` keeps the window alive and
  // presenting until the user closes it (same convention as the other examples).
  let verified_frames = frames
  if show_win {
    while @win.should_close(win) == 0 {
      @win.poll()
      let (interactive_ok, _) = render_frame(
        device,
        swapchain,
        cmd,
        pipeline,
        readback,
        false,
      )
      if interactive_ok {
        frames = frames + 1
        match swapchain.present() {
          @dx12.PresentResult::Presented => presented = presented + 1
          @dx12.PresentResult::Occluded => occluded = occluded + 1
          @dx12.PresentResult::Failed => present_failed = true
        }
      }
    }
  }

  // The triangle covers the whole viewport with flat orange (1.0, 0.5, 0.0), so
  // four samples across the back buffer must all match; anything else means the
  // viewport, the scissor or the flip-model copy went wrong.
  let mut pixel_ok = false
  match captured {
    Some(px) => {
      let samples = [
        pixel(px, WIDTH / 2, HEIGHT / 2),
        pixel(px, 2, 2),
        pixel(px, WIDTH - 3, 2),
        pixel(px, WIDTH - 3, HEIGHT - 3),
      ]
      let orange = fn(rgb : (Int, Int, Int)) -> Bool {
        let (r, g, b) = rgb
        r > 230 && g > 110 && g < 145 && b < 25
      }
      pixel_ok = px.length() == WIDTH * HEIGHT * 4 && orange(samples[0]) &&
        orange(samples[1]) && orange(samples[2]) && orange(samples[3])
    }
    None => ()
  }

  match captured {
    Some(bytes) => if shot != "" && bytes.length() == WIDTH * HEIGHT * 4 {
      let px = FixedArray::makei(bytes.length(), fn(i) { bytes[i] })
      let _ = @shader.save_png(shot, WIDTH, HEIGHT, px)
    }
    None => ()
  }

  let errs = device.validation_errors()
  let adapter = if device.is_warp() { "warp" } else { "hardware" }
  @win.poll()
  // The swapchain cannot be released while the GPU still reads its back buffers.
  let _ = device.wait_idle()
  readback.destroy()
  swapchain.destroy()
  cmd.destroy()
  pipeline.destroy()
  device.destroy()
  @win.destroy(win)

  if present_failed {
    unsupported("Present failed for this window")
    return
  }
  if all_ok && resize_frame_ok && resized && pixel_ok && errs == 0 &&
    verified_frames == 4 {
    println(
      "[dx12/present] OK — DXGI flip-model presented \{presented} frames (\{WIDTH}x\{HEIGHT}, occluded=\{occluded}, adapter=\{adapter}, resize ok, back-buffer readback verified, 0 validation errors)",
    )
  } else {
    println(
      "[dx12/present] FAIL — frames=\{frames} presented=\{presented} render_ok=\{all_ok} resize_ok=\{resized} resize_frame_ok=\{resize_frame_ok} pixel_ok=\{pixel_ok} errs=\{errs}",
    )
  }
}
