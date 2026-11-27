// window/wayland — Linux Wayland WSI & windowing verification:
// Exercises runtime-loaded libwayland-client + xdg-shell + VK_KHR_wayland_surface
// when WAYLAND_DISPLAY is active (or TYCHO_WINDOW_BACKEND=wayland).
// Reports SKIP if no Wayland compositor is running in the current session.

///|
fn main {
  try {
    let opts = @exwin.Options::parse("window/wayland")
    if @win.initialize() == 0 || !@win.is_wayland() {
      println("[window/wayland] SKIP — no Wayland compositor active (check WAYLAND_DISPLAY / XDG_RUNTIME_DIR)")
      return
    }

    let dev = @tycho.Device::new_desc(
      @tycho.DeviceDesc::new("window/wayland", validation=true, headless=false),
    )
    let sc = @exwin_rhi.open(
      dev,
      opts,
      clear_color=@tycho.ClearColor::rgba(0.15, 0.55, 0.85, 1.0),
    ) catch {
      @tycho.RhiError::SwapchainFailed(msg) => {
        dev.destroy()
        println("[window/wayland] SKIP — \{msg}")
        return
      }
      e => {
        dev.destroy()
        raise e
      }
    }
    sc.set_title("window/wayland (Wayland)")
    let scale = sc.content_scale()
    sc.set_cursor_mode(@tycho.CursorMode::Hidden)
    sc.set_cursor_mode(@tycho.CursorMode::Locked)
    sc.set_cursor_mode(@tycho.CursorMode::Normal)
    sc.set_fullscreen(true)
    sc.set_fullscreen(false)

    let mut frames = 0
    let mut px : FixedArray[Byte] = []
    for i = 0; i < 2; i = i + 1 {
      let _ = i
      let _ = sc.poll_events()
      let cmd = sc.begin_frame_commands()
      cmd.begin_swapchain_pass(sc)
      cmd.end_swapchain_pass()
      sc.end_frame(cmd)
      px = sc.readback()
      frames = frames + 1
    }
    let w = sc.width()
    let h = sc.height()
    let is_bgra = sc.color_format() == @tycho.TextureFormat::BGRA8
    let mid = ((h / 2) * w + w / 2) * 4
    let r = if is_bgra { px[mid + 2].to_int() } else { px[mid].to_int() }
    let g = px[mid + 1].to_int()
    let b = if is_bgra { px[mid].to_int() } else { px[mid + 2].to_int() }
    let pixel_ok = px.length() == w * h * 4 && r < 80 && g > 100 && b > 180

    if opts.window {
      while @exwin_rhi.next_frame(sc) {
        let cmd = sc.begin_frame_commands()
        cmd.begin_swapchain_pass(sc)
        cmd.end_swapchain_pass()
        sc.end_frame(cmd)
        frames = frames + 1
      }
    }

    sc.destroy()
    let errs = dev.validation_errors()
    dev.destroy()

    if pixel_ok && errs == 0 && frames == 2 {
      println(
        "[window/wayland] OK — Wayland WSI presented \{frames} frames (\{w}x\{h}, scale=\{scale}, 0 validation errors)",
      )
    } else {
      println(
        "[window/wayland] FAIL — pixel_ok=\{pixel_ok} (rgb=\{r},\{g},\{b}) frames=\{frames} errs=\{errs}",
      )
    }
  } catch {
    e => println("[window/wayland] FAIL — \{e}")
  }
}
