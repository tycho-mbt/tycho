// Example 73 — Windows Win32 WSI & windowing verification:
// Exercises the runtime-loaded Win32 backend (window_win32.c, user32.dll via
// LoadLibraryA), VK_KHR_win32_surface, swapchain acquire/present, the
// fullscreen-resize recreation path (oldSwapchain) and CPU readback — all with
// zero validation errors. Reports SKIP on non-Windows hosts so the Linux gate
// stays green.

///|
fn should_quit(sc : @tycho.Swapchain) -> Bool {
  if sc.should_close() {
    return true
  }
  for ev in sc.poll_events() {
    match ev {
      @tycho.Event::KeyDown(k, _) => if k == @tycho.KEY_ESCAPE { return true }
      _ => ()
    }
  }
  false
}

///|
fn present_n(sc : @tycho.Swapchain, n : Int) -> FixedArray[Byte] raise @tycho.RhiError {
  let mut px : FixedArray[Byte] = []
  for i = 0; i < n; i = i + 1 {
    let _ = i
    let _ = sc.poll_events()
    let cmd = sc.begin_frame_commands()
    cmd.begin_swapchain_pass(sc)
    cmd.end_swapchain_pass()
    sc.end_frame(cmd)
    px = sc.readback()
  }
  px
}

///|
fn center_rgb(px : FixedArray[Byte], w : Int, h : Int, bgra : Bool) -> (Int, Int, Int) {
  let mid = ((h / 2) * w + w / 2) * 4
  if px.length() < mid + 4 {
    return (-1, -1, -1)
  }
  let r = if bgra { px[mid + 2].to_int() } else { px[mid].to_int() }
  let g = px[mid + 1].to_int()
  let b = if bgra { px[mid].to_int() } else { px[mid + 2].to_int() }
  (r, g, b)
}

///|
fn main {
  try {
    match @win.platform() {
      @win.Platform::Windows => ()
      _ => {
        println("[73-win32-window] SKIP — Win32 WSI is Windows-only")
        return
      }
    }
    if @win.initialize() == 0 {
      println("[73-win32-window] SKIP — user32.dll unavailable")
      return
    }

    let dev = @tycho.Device::new_desc(
      @tycho.DeviceDesc::new("73-win32-window", validation=true, headless=false),
    )
    let sc = dev.create_swapchain_desc(
      @tycho.SwapchainDesc::new(
        "73-win32-window",
        480,
        320,
        enable_readback=true,
        clear_color=@tycho.ClearColor::rgba(0.15, 0.55, 0.85, 1.0),
        present_mode=@tycho.PresentMode::Mailbox,
      ),
    ) catch {
      @tycho.RhiError::SwapchainFailed(msg) => {
        dev.destroy()
        println("[73-win32-window] SKIP — \{msg}")
        return
      }
      e => {
        dev.destroy()
        raise e
      }
    }

    sc.set_title("73-win32-window (Win32 surface + swapchain)")
    let scale = sc.content_scale()
    sc.set_cursor_mode(@tycho.CursorMode::Hidden)
    sc.set_cursor_mode(@tycho.CursorMode::Locked)
    sc.set_cursor_mode(@tycho.CursorMode::Normal)
    sc.set_cursor_shape(@tycho.CursorShape::Pointer)
    sc.set_cursor_shape(@tycho.CursorShape::Default)

    // Win32 clipboard round-trip (OpenClipboard / SetClipboardData path).
    let prev_clip = sc.clipboard_text()
    sc.set_clipboard_text("73-win32-window")
    let clip_ok = sc.clipboard_text() == "73-win32-window"
    sc.set_clipboard_text(prev_clip)

    let mut frames = 0
    let mut px = present_n(sc, 2)
    frames = frames + 2
    let w0 = sc.width()
    let h0 = sc.height()
    let bgra = sc.color_format() == @tycho.TextureFormat::BGRA8
    let (r, g, b) = center_rgb(px, w0, h0, bgra)
    let pixel_ok = px.length() == w0 * h0 * 4 && r >= 0 && r < 80 && g > 100 && b > 180

    // Fullscreen toggling calls SetWindowPos(monitor rect); WM_SIZE then trips
    // the RHI's resize detection, so this exercises swapchain recreation through
    // oldSwapchain — a path only a real Win32 window can reach.
    sc.set_fullscreen(true)
    if !sc.is_fullscreen() {
      // Non-interactive desktops (e.g. a session-0 CI runner) refuse the resize:
      // report SKIP instead of pretending the recreation path was verified.
      sc.destroy()
      dev.destroy()
      println("[73-win32-window] SKIP — fullscreen resize refused by this desktop")
      return
    }
    px = present_n(sc, 3)
    frames = frames + 3
    let w1 = sc.width()
    let h1 = sc.height()
    sc.set_fullscreen(false)
    let fs_off = !sc.is_fullscreen()
    px = present_n(sc, 3)
    frames = frames + 3
    let w2 = sc.width()
    let h2 = sc.height()
    let (fw, fh) = sc.framebuffer_size()
    let resized = w1 > 0 && h1 > 0 && w2 > 0 && h2 > 0 && (w1 != w0 || h1 != h0)
    let synced = w2 == fw && h2 == fh

    if @tycho.want_window() {
      while !should_quit(sc) {
        let _ = present_n(sc, 1)
        frames = frames + 1
      }
    }

    sc.destroy()
    let errs = dev.validation_errors()
    dev.destroy()

    if pixel_ok && resized && synced && fs_off && clip_ok && errs == 0 {
      println(
        "[73-win32-window] OK — Win32 WSI presented \{frames} frames (\{w0}x\{h0} -> fullscreen \{w1}x\{h1} -> \{w2}x\{h2}, scale=\{scale}, 0 validation errors)",
      )
    } else {
      println(
        "[73-win32-window] FAIL — pixel_ok=\{pixel_ok} rgb=\{r},\{g},\{b} resized=\{resized} w0=\{w0}x\{h0} w1=\{w1}x\{h1} w2=\{w2}x\{h2} window=\{fw}x\{fh} synced=\{synced} fullscreen_off=\{fs_off} clipboard=\{clip_ok} errs=\{errs}",
      )
    }
  } catch {
    e => println("[73-win32-window] FAIL — \{e}")
  }
}
