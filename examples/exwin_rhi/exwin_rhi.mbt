// Unified window policy for the examples that draw through `laplaceliu/tycho`
// (`rhi/*`, `3d/*`, `2d/*`, `ui/*`, `general/*`, `dx12/*` RHI demos).
//
// Every one of those examples used to repeat the same four things: create a
// swapchain with a hand-written size, re-implement `should_quit`, remember (or
// forget) `sync_size()` on resize, and handle `--screenshot` on its own path.
// The three functions below are the single implementation of that policy.
//
//   let opts = @exwin.Options::parse("rhi/triangle")
//   ...
//   let sc = @exwin_rhi.open(dev, opts)      // 800x600, readback on
//   while @exwin_rhi.next_frame(sc) { ... }  // Esc / close button / resize
//   @exwin_rhi.capture(opts, sc, px)         // honours --screenshot

///|
/// Open the interactive swapchain an example was asked for.
///
/// `enable_readback` is always on so `Swapchain::readback()` works for
/// `--screenshot`; `depth`/`depth_format`/`clear_color` follow the example's
/// own scene setup (the 2D examples need `Depth24Stencil8` and their own clear
/// colour, the 3D ones the default).
pub fn open(
  dev : @tycho.Device,
  opts : @exwin.Options,
  depth? : Bool = false,
  depth_format? : @tycho.TextureFormat = @tycho.TextureFormat::Depth32F,
  clear_color? : @tycho.ClearColor = @tycho.ClearColor::black(),
  present_mode? : @tycho.PresentMode = @tycho.PresentMode::Fifo,
) -> @tycho.Swapchain raise @tycho.RhiError {
  dev.create_swapchain_desc(
    @tycho.SwapchainDesc::new(
      opts.name,
      opts.width,
      opts.height,
      depth~,
      depth_format~,
      clear_color~,
      present_mode~,
      enable_readback=true,
    ),
  )
}

///|
/// Drain this frame's events and decide whether to quit.
///
/// Returns the events for loops that drive a camera, hover state or IME with
/// them, plus `true` once the window was closed or Esc was pressed — the two
/// quit conditions every example should honour.
pub fn poll(sc : @tycho.Swapchain) -> (Array[@tycho.Event], Bool) {
  let mut quit = sc.should_close()
  let events = sc.poll_events()
  for ev in events {
    match ev {
      @tycho.Event::CloseRequested => quit = true
      @tycho.Event::KeyDown(k, _) => if k == @tycho.KeyCode::Escape { quit = true }
      _ => ()
    }
  }
  (events, quit)
}

///|
/// One frame of an event-driven loop: returns `false` when the user asked to
/// quit, otherwise swallows the events and resizes the swapchain to the window.
///
/// Use `poll` instead when the loop body needs the events (camera, hover).
pub fn next_frame(sc : @tycho.Swapchain) -> Bool {
  let (_, quit) = poll(sc)
  if quit {
    return false
  }
  // A resize only needs to be adopted, not to abort the demo: the next
  // `begin_frame` recreates the swapchain against the new extent.
  try {
    sc.sync_size()
  } catch {
    _ => ()
  }
  true
}

///|
/// Save the frame just read back from `sc` when `--screenshot` was given,
/// picking the byte order from the swapchain format.
pub fn capture(opts : @exwin.Options, sc : @tycho.Swapchain, pixels : FixedArray[Byte]) -> Unit {
  opts.capture(
    sc.width().to_int(),
    sc.height().to_int(),
    pixels,
    bgra=sc.color_format() == @tycho.TextureFormat::BGRA8,
  )
}
