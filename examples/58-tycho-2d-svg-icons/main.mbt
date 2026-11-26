// 58 — coverage atlas vs 4x MSAA quality gate.
//
// Renders 300 procedural icon paths twice: once through the CPU coverage
// atlas and once through the per-path MSAA fallback, then compares the two
// images with windowed SSIM. Also asserts that coverage removes per-path
// render passes.

const PI58 : Float = 3.141592653589793

const ICON_COUNT : Int = 300

///|
fn make_icon(index : Int, cx : Float, cy : Float) -> @g2d.Path {
  let variant = index % 3
  if variant == 0 {
    // Concave N-point star.
    let spokes = 5 + index % 6
    let r_out = (20.0 : Float) + Float::from_int(index % 5) * (3.0 : Float)
    let r_in = r_out * (0.45 : Float)
    let pb = @g2d.PathBuilder::new()
    for k = 0; k < spokes * 2; k = k + 1 {
      let ang = PI58 * Float::from_int(k) / Float::from_int(spokes)
      let r = if k % 2 == 0 { r_out } else { r_in }
      let x = cx + r * @tmath.cos(ang)
      let y = cy + r * @tmath.sin(ang)
      let _ = if k == 0 {
        pb.move_to(x, y)
      } else {
        pb.line_to(x, y)
      }
    }
    pb.close().build()
  } else if variant == 1 {
    // Ring with an EvenOdd hole.
    let r = (18.0 : Float) + Float::from_int(index % 4) * (2.0 : Float)
    @g2d.PathBuilder::new()
      .add_circle(cx, cy, r)
      .add_circle(cx, cy, r * (0.5 : Float))
      .build(fill_rule=@g2d.FillRule::EvenOdd)
  } else {
    // Rounded square.
    let half = (16.0 : Float) + Float::from_int(index % 3) * (3.0 : Float)
    let rr = @g2d.RRect::uniform(
      @g2d.Rect::new(
        cx - half,
        cy - half,
        half * (2.0 : Float),
        half * (2.0 : Float),
      ),
      half * (0.35 : Float),
    )
    @g2d.PathBuilder::new().add_rrect(rr).build()
  }
}

///|
fn luminance(px : FixedArray[Byte], i : Int) -> Double {
  px[i].to_int().to_double() * 0.299 +
  px[i + 1].to_int().to_double() * 0.587 +
  px[i + 2].to_int().to_double() * 0.114
}

///|
fn windowed_ssim(
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
          let lx = luminance(a, i)
          let ly = luminance(b, i)
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
fn main {
  try {
    let dev = @tycho.Device::new_desc(
      @tycho.DeviceDesc::new("58-tycho-2d-svg-icons", validation=true, headless=true),
    )
    let w = 1920
    let h = 1080
    let bg = @g2d.Color::from_rgba8(18, 22, 34)
    let c = @g2d.Canvas::new()
    c.clear(bg)
    for i = 0; i < ICON_COUNT; i = i + 1 {
      let col = i % 30
      let row = i / 30
      let cx = Float::from_int(32 + col * 62)
      let cy = Float::from_int(60 + row * 100)
      let p = make_icon(i, cx, cy)
      let r = 90 + (i * 37) % 150
      let g = 90 + (i * 53) % 150
      let b = 90 + (i * 71) % 150
      c.draw_path(p, @g2d.Paint::fill(@g2d.Color::from_rgba8(r, g, b)))
    }
    let dl = c.finish()
    let renderer = @g2d.Renderer2D::new(dev)
    let rt = dev.create_render_target(w, h, @tycho.TextureFormat::RGBA8)

    renderer.set_coverage_enabled(true)
    renderer.render_offscreen(dl, rt, clear_color=bg)
    let cov_stats = renderer.stats()
    let cov_px = rt.readback()

    renderer.set_coverage_enabled(false)
    renderer.render_offscreen(dl, rt, clear_color=bg)
    let msaa_stats = renderer.stats()
    let msaa_px = rt.readback()

    let score = windowed_ssim(cov_px, msaa_px, w, h)
    println(
      "{\"ssim\":\{score},\"coverage_draws\":\{cov_stats.coverage_draws},\"coverage_passes\":\{cov_stats.path_passes},\"msaa_passes\":\{msaa_stats.path_passes},\"coverage_draw_calls\":\{cov_stats.draw_calls},\"msaa_draw_calls\":\{msaa_stats.draw_calls}}",
    )
    let errs = dev.validation_errors()
    let ok = score >= 0.98 &&
      cov_stats.coverage_draws == ICON_COUNT &&
      cov_stats.path_passes <= 1 &&
      msaa_stats.path_passes > 10 &&
      errs == 0
    if ok {
      println(
        "[58-tycho-2d-svg-icons] OK — SSIM=\{score}, coverage \{cov_stats.coverage_draws} icons / \{cov_stats.path_passes} passes, MSAA \{msaa_stats.path_passes} passes, 0 validation errors",
      )
    } else {
      println(
        "[58-tycho-2d-svg-icons] FAIL — ssim=\{score} cov_draws=\{cov_stats.coverage_draws} cov_passes=\{cov_stats.path_passes} msaa_passes=\{msaa_stats.path_passes} errs=\{errs}",
      )
    }
    rt.destroy()
    renderer.destroy()
    dev.destroy()
  } catch {
    err => println("[58-tycho-2d-svg-icons] FAIL — \{err}")
  }
}
