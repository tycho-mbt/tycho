// 61 — MSDF scale quality gate.
//
// Renders the same paragraph at 0.5x/1x/2x/4x twice: once through the RGBA
// MSDF atlas (kind=9) and once through the normal bitmap glyph path. Each pair
// is compared with windowed SSIM. --window previews the last scale;
// --screenshot <path> writes the 1x image.

///|
fn luminance61(px : FixedArray[Byte], i : Int) -> Double {
  px[i].to_int().to_double() * 0.299 +
  px[i + 1].to_int().to_double() * 0.587 +
  px[i + 2].to_int().to_double() * 0.114
}

///|
fn windowed_ssim61(
  a : FixedArray[Byte],
  b : FixedArray[Byte],
  w : Int,
  h : Int,
) -> Double {
  let c1 = 2.55 * 2.55
  let c2 = 7.65 * 7.65
  let ws = 8
  let n = (ws * ws).to_double()
  let mut total = 0.0
  let mut windows = 0
  let mut y0 = 0
  while y0 + ws <= h {
    let mut x0 = 0
    while x0 + ws <= w {
      let mut sx = 0.0
      let mut sy = 0.0
      let mut sxx = 0.0
      let mut syy = 0.0
      let mut sxy = 0.0
      for dy = 0; dy < ws; dy = dy + 1 {
        for dx = 0; dx < ws; dx = dx + 1 {
          let i = ((y0 + dy) * w + (x0 + dx)) * 4
          let lx = luminance61(a, i)
          let ly = luminance61(b, i)
          sx = sx + lx
          sy = sy + ly
          sxx = sxx + lx * lx
          syy = syy + ly * ly
          sxy = sxy + lx * ly
        }
      }
      let mux = sx / n
      let muy = sy / n
      let vx = sxx / n - mux * mux
      let vy = syy / n - muy * muy
      let cov = sxy / n - mux * muy
      let num = (2.0 * mux * muy + c1) * (2.0 * cov + c2)
      let den = (mux * mux + muy * muy + c1) * (vx + vy + c2)
      total = total + num / den
      windows = windows + 1
      x0 = x0 + ws
    }
    y0 = y0 + ws
  }
  if windows == 0 {
    0.0
  } else {
    total / windows.to_double()
  }
}

///|
fn render_at(
  font : @g2d.FontFace,
  size : Float,
  w : Int,
  _h : Int,
  bg : @g2d.Color,
) -> @g2d.DisplayList {
  let c = @g2d.Canvas::new()
  c.clear(bg)
  let para = @g2d.ParagraphBuilder::new()
    .add_text(
      "MSDF Aa 0123",
      style=@g2d.TextStyle::new(
        font=font,
        font_size=size,
        color=@g2d.Color::white(),
      ),
    )
    .build()
  para.layout(Float::from_int(w - 24))
  c.draw_paragraph(para, @g2d.Point::new((12.0 : Float), (24.0 : Float)))
  c.finish()
}

///|
fn main {
  try {
    let show_win = @tycho.want_window()
    let shot = @tycho.screenshot_path()
    let bytes = @tycho.read_file_bytes(
      "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
    )
    let font = match @g2d.FontFace::from_ttf_bytes(bytes) {
      Some(f) => f
      None => {
        println("[2d/msdf] FAIL — DejaVuSans not found")
        return
      }
    }
    let dev = @tycho.Device::new_desc(
      @tycho.DeviceDesc::new(
        "2d/msdf",
        validation=true,
        headless=!show_win,
      ),
    )
    let w = 960
    let h = 320
    let bg = @g2d.Color::from_rgba8(16, 20, 30)
    let renderer = @g2d.Renderer2D::new(dev)
    let rt = dev.create_render_target(w, h, @tycho.TextureFormat::RGBA8)
    renderer.set_msdf_min_size((8.0 : Float))

    let scales : Array[Float] = [0.5, 1.0, 2.0, 4.0]
    let scores : Array[Double] = []
    let mut worst = 1.0
    let mut last_dl = render_at(font, (48.0 : Float), w, h, bg)
    for i = 0; i < scales.length(); i = i + 1 {
      let size = (48.0 : Float) * scales[i]
      let dl = render_at(font, size, w, h, bg)
      last_dl = dl
      renderer.set_msdf_enabled(true)
      renderer.render_offscreen(dl, rt, clear_color=bg)
      let msdf_px = rt.readback()
      renderer.set_msdf_enabled(false)
      renderer.render_offscreen(dl, rt, clear_color=bg)
      let bmp_px = rt.readback()

      let score = windowed_ssim61(msdf_px, bmp_px, w, h)
      scores.push(score)
      if score < worst {
        worst = score
      }
      if i == 1 && shot != "" {
        let _ = @tycho.save_png(shot, w, h, msdf_px)
      }
    }
    let errs = dev.validation_errors()
    let mut all_ok = errs == 0 && worst >= 0.98
    for s in scores {
      if s < 0.98 {
        all_ok = false
      }
    }
    println(
      "{\"scores\":[\{scores[0]},\{scores[1]},\{scores[2]},\{scores[3]}],\"worst\":\{worst},\"errors\":\{errs}}",
    )
    if all_ok {
      println(
        "[2d/msdf] OK — 0.5x/1x/2x/4x SSIM worst=\{worst}, 0 validation errors",
      )
    } else {
      println(
        "[2d/msdf] FAIL — worst=\{worst} scores=\{Repr(scores)} errs=\{errs}",
      )
    }
    if show_win {
      let sc = dev.create_swapchain_desc(
        @tycho.SwapchainDesc::new(
          "2d/msdf",
          w,
          h,
          depth=true,
          depth_format=@tycho.TextureFormat::Depth24Stencil8,
          clear_color=bg.to_clear_color(),
        ),
      )
      while !sc.should_close() {
        let mut quit = false
        for ev in sc.poll_events() {
          match ev {
            @tycho.Event::KeyDown(k, _) => if k == @tycho.KEY_ESCAPE { quit = true }
            _ => ()
          }
        }
        if quit { break }
        sc.sync_size()
        renderer.set_msdf_enabled(true)
        renderer.render_swapchain(sc, last_dl, clear_color=bg)
      }
      sc.destroy()
    }
    rt.destroy()
    renderer.destroy()
    dev.destroy()
  } catch {
    err => println("[2d/msdf] FAIL — \{err}")
  }
}
