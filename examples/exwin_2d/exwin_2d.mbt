// Window preview helper for the 2D examples.
//
// A 2D scene is laid out on a fixed canvas (1920x1080 for the text stress and
// perf harnesses, 960x320 for the MSDF test, ...) and that canvas is exactly
// what the example asserts on, so it cannot simply follow the window. Every
// example now opens the same 800x600 window, which would show only the top-left
// corner of a larger canvas: `fit` re-wraps the finished display list in a
// centred, aspect-preserving scale so the whole scene is visible.
//
//   renderer.render_swapchain(sc, @exwin_2d.fit(dl, w, h, sc), clear_color=bg)
//
// The window frame and the `--screenshot` PNG therefore letterbox identically
// (`@exwin.fit_size` is the single source of truth for the fit math).

///|
/// Scale `dl` (authored at `width` x `height`) into the current swapchain frame,
/// preserving aspect and centring it. Returns `dl` untouched when the two sizes
/// already match, so the common 800x600 case allocates nothing.
pub fn fit(
  dl : @g2d.DisplayList,
  width : Int,
  height : Int,
  sc : @tycho.Swapchain,
) -> @g2d.DisplayList {
  if width <= 0 || height <= 0 {
    return dl
  }
  let dst_w = sc.width().to_int()
  let dst_h = sc.height().to_int()
  let (dw, dh) = @exwin.fit_size_into(width, height, dst_w, dst_h)
  if dw == width && dh == height {
    return dl
  }
  let c = @g2d.Canvas::new()
  c.translate(
    Float::from_int((dst_w - dw) / 2),
    Float::from_int((dst_h - dh) / 2),
  )
  c.scale(
    Float::from_int(dw) / Float::from_int(width),
    Float::from_int(dh) / Float::from_int(height),
  )
  c.draw_display_list(dl)
  c.finish()
}
