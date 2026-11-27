// Unified platform window for the examples that drive a backend directly:
// `vulkan/*` on `laplaceliu/tycho_vulkan`, and the raw-binding `dx12/triangle` /
// `dx12/present` on `laplaceliu/tycho_dx12`.
//
// Those examples cannot use `@exwin_rhi` because they own the swapchain, but
// they share the same contract: the size and title come from `@exwin.Options`,
// a framebuffer size change is reported through `size()`, and Esc / the close
// button end the loop. This wraps `@tycho_window` so that policy is written
// once, on every platform, instead of repeated in each example.
//
//   let win = @exwin_native.open(opts)       // 0 => report SKIP
//   let surface = @win.create_surface(inst, win)
//   while @exwin_native.next_frame(win) { ... @exwin_native.size(win) ... }
//   @exwin_native.destroy(win)

///|
/// Create the window described by `opts`, or `0` when the platform has no
/// usable backend (headless runner, no display, Win32 missing outside Windows).
/// Callers report that as `SKIP`, never as a failure.
pub fn open(opts : @exwin.Options) -> UInt64 {
  if @win.initialize() == 0 {
    return 0
  }
  @win.create(opts.width, opts.height, opts.name)
}

///|
/// Current framebuffer size in pixels; recreate the swapchain when it differs
/// from the size it was built with (`content_scale` included).
pub fn size(win : UInt64) -> (Int, Int) {
  let (w, h) = @win.framebuffer_size(win)
  (w.to_int(), h.to_int())
}

///|
/// The OS handle a DXGI swapchain is created against.
pub fn native_handle(win : UInt64) -> UInt64 {
  @win.native_handle(win)
}

///|
/// Drain this frame's events and decide whether to quit (close button or Esc).
pub fn poll(win : UInt64) -> (Array[@win.Event], Bool) {
  @win.poll()
  let mut quit = @win.should_close(win) != 0
  let events = @win.poll_events(win)
  for ev in events {
    match ev {
      @win.Event::CloseRequested => quit = true
      @win.Event::KeyDown(k, _) => if k == @win.KEY_ESCAPE { quit = true }
      _ => ()
    }
  }
  (events, quit)
}

///|
/// One frame of an event-driven loop; `false` means quit.
pub fn next_frame(win : UInt64) -> Bool {
  let (_, quit) = poll(win)
  !quit
}

///|
/// Block until the compositor has something for us (interactive runs only).
pub fn wait_events(win : UInt64, timeout_ms? : Int32 = 16) -> Unit {
  let _ = win
  @win.wait_events(timeout_ms)
}

///|
/// Set the window title (the default is the example path).
pub fn set_title(win : UInt64, title : String) -> Unit {
  @win.set_title(win, title)
}

///|
/// Destroy the window and release the platform backend.
pub fn destroy(win : UInt64) -> Unit {
  @win.destroy(win)
  @win.terminate()
}
