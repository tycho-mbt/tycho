// Example 54 — Tycho 2D Engine Showcase (Skia / Impeller-inspired):
// Demonstrates:
// - Tier-1 SDF rounded rects, gradients, analytical drop shadows, RGBA8 image sprite, & Paragraph text
// - Tier-2 Stencil-then-Cover vector paths (EvenOdd self-intersecting star + NonZero Bezier stroke)
// - Tier-3 save_layer group opacity & save_backdrop_layer frosted-glass Gaussian blur inside ClipRRect
// - Headless pixel assertions + --screenshot <path> + --window preview.

///|
fn make_badge_image() -> @g2d.Image2D {
  let w = 32
  let h = 32
  let px = Array::make(w * h * 4, (0 : Byte))
  for y = 0; y < h; y = y + 1 {
    for x = 0; x < w; x = x + 1 {
      let i = (y * w + x) * 4
      let checker = ((x / 8) + (y / 8)) % 2 == 0
      px[i + 0] = (if checker { 90 } else { 245 }).to_byte()
      px[i + 1] = (if checker { 195 } else { 145 }).to_byte()
      px[i + 2] = (if checker { 255 } else { 85 }).to_byte()
      px[i + 3] = (255 : Byte)
    }
  }
  @g2d.Image2D::from_bytes(1, w, h, Bytes::from_array(px[:]))
}

///|
fn sin_cos_showcase(theta : Double) -> (Double, Double) {
  let (s, c) = @tmath.sin_cos(Float::from_double(theta))
  (s.to_double(), c.to_double())
}

///|
fn build_star_path(cx : Float, cy : Float, r : Float) -> @g2d.Path {
  // 5-point self-intersecting star: vertices connect every 2nd point (0 -> 2 -> 4 -> 1 -> 3 -> 0)
  // so EvenOdd produces a crisp hollow center pentagon!
  let pb = @g2d.PathBuilder::new()
  let two_pi = 6.283185307179586
  let order : FixedArray[Int] = [0, 2, 4, 1, 3]
  for k = 0; k < 5; k = k + 1 {
    let idx = order[k]
    let ang = -1.5707963267948966 + idx.to_double() * two_pi / 5.0
    let (sn, cs) = sin_cos_showcase(ang)
    let vx = cx + Float::from_double(cs) * r
    let vy = cy + Float::from_double(sn) * r
    if k == 0 {
      let _ = pb.move_to(vx, vy)
    } else {
      let _ = pb.line_to(vx, vy)
    }
  }
  pb.close().build(fill_rule=@g2d.FillRule::EvenOdd)
}

///|
fn build_wave_path(x0 : Float, y0 : Float) -> @g2d.Path {
  @g2d.PathBuilder::new()
    .move_to(x0, y0)
    .cubic_to(x0 + (45.0 : Float), y0 - (55.0 : Float), x0 + (95.0 : Float), y0 + (55.0 : Float), x0 + (145.0 : Float), y0 - (10.0 : Float))
    .build()
}

///|
fn build_scene(font : @g2d.FontFace, badge : @g2d.Image2D) -> @g2d.DisplayList {
  let c = @g2d.Canvas::new()
  let bg = @g2d.Color::from_rgba8(14, 18, 30)
  c.clear(bg)

  // 1. Header bar with linear gradient & analytical shadow
  let hdr_rect = @g2d.Rect::new((28.0 : Float), (20.0 : Float), (744.0 : Float), (68.0 : Float))
  let hdr_rrect = @g2d.RRect::per_corner(hdr_rect, (16.0 : Float), (16.0 : Float), (10.0 : Float), (10.0 : Float))
  c.draw_rrect_shadow(hdr_rrect, (0.0 : Float), (6.0 : Float), (16.0 : Float), (0.0 : Float), @g2d.Color::rgba((0.0 : Float), (0.0 : Float), (0.02 : Float), (0.65 : Float)))
  let hdr_grad = @g2d.Shader2D::LinearGradient(
    @g2d.Point::new((28.0 : Float), (20.0 : Float)),
    @g2d.Point::new((772.0 : Float), (88.0 : Float)),
    [
      @g2d.GradientStop::new((0.0 : Float), @g2d.Color::from_rgba8(32, 92, 198)),
      @g2d.GradientStop::new((0.5 : Float), @g2d.Color::from_rgba8(74, 72, 188)),
      @g2d.GradientStop::new((1.0 : Float), @g2d.Color::from_rgba8(146, 58, 168)),
    ],
    @g2d.TileMode::Clamp,
  )
  c.draw_rrect(hdr_rrect, @g2d.Paint::new(shader=Some(hdr_grad)))
  // Elliptical-corner pill (Tier-1 SDF, rx=24 != ry=14).
  let pill_rect = @g2d.Rect::new((648.0 : Float), (34.0 : Float), (104.0 : Float), (28.0 : Float))
  let pill = @g2d.RRect::per_corner_xy(
    pill_rect,
    (24.0 : Float),
    (14.0 : Float),
    (24.0 : Float),
    (14.0 : Float),
    (24.0 : Float),
    (14.0 : Float),
    (24.0 : Float),
    (14.0 : Float),
  )
  c.draw_rrect(pill, @g2d.Paint::fill(@g2d.Color::from_rgba8(255, 235, 120)))
  c.draw_image_rect(
    badge,
    @g2d.Rect::new((0.0 : Float), (0.0 : Float), (32.0 : Float), (32.0 : Float)),
    @g2d.Rect::new((44.0 : Float), (36.0 : Float), (36.0 : Float), (36.0 : Float)),
  )
  let title_para = @g2d.ParagraphBuilder::new()
    .add_text(
      "TYCHO 2D: SDF + STENCIL PATHS + TEXT + BACKDROP BLUR",
      style=@g2d.TextStyle::new(font~, font_size=(18.0 : Float), color=@g2d.Color::white()),
    )
    .build()
  c.draw_paragraph(title_para, @g2d.Point::new((96.0 : Float), (43.0 : Float)))

  // 2. Left card: Tier-2 Stencil-then-Cover (EvenOdd Star + Cubic Bezier Stroke)
  let left_rect = @g2d.Rect::new((28.0 : Float), (108.0 : Float), (360.0 : Float), (224.0 : Float))
  let left_rr = @g2d.RRect::uniform(left_rect, (14.0 : Float))
  c.draw_rrect(left_rr, @g2d.Paint::fill(@g2d.Color::from_rgba8(24, 30, 48)))
  c.draw_rrect(left_rr, @g2d.Paint::stroke(@g2d.Color::from_rgba8(64, 152, 245), (2.0 : Float)))
  let left_lbl = @g2d.ParagraphBuilder::new()
    .add_text(
      "Stencil-then-Cover (EvenOdd + Stroke)",
      style=@g2d.TextStyle::new(font~, font_size=(14.0 : Float), color=@g2d.Color::from_rgba8(180, 205, 245)),
    )
    .build()
  c.draw_paragraph(left_lbl, @g2d.Point::new((46.0 : Float), (122.0 : Float)))

  let star = build_star_path((126.0 : Float), (235.0 : Float), (68.0 : Float))
  c.draw_path(star, @g2d.Paint::fill(@g2d.Color::from_rgba8(255, 196, 56)))
  let wave = build_wave_path((218.0 : Float), (235.0 : Float))
  c.draw_path(
    wave,
    @g2d.Paint::stroke(
      @g2d.Color::from_rgba8(72, 232, 168),
      (8.0 : Float),
      cap=@g2d.StrokeCap::Round,
      join=@g2d.StrokeJoin::Round,
    ),
  )

  // 3. Right card: Radial Gradient + ClipRRect + save_layer group opacity
  let right_rect = @g2d.Rect::new((412.0 : Float), (108.0 : Float), (360.0 : Float), (224.0 : Float))
  let right_rr = @g2d.RRect::uniform(right_rect, (14.0 : Float))
  c.draw_rrect(right_rr, @g2d.Paint::fill(@g2d.Color::from_rgba8(24, 30, 48)))
  c.draw_rrect(right_rr, @g2d.Paint::stroke(@g2d.Color::from_rgba8(96, 212, 164), (2.0 : Float)))
  let right_lbl = @g2d.ParagraphBuilder::new()
    .add_text(
      "Radial Gradient + save_layer Opacity",
      style=@g2d.TextStyle::new(font~, font_size=(14.0 : Float), color=@g2d.Color::from_rgba8(180, 240, 215)),
    )
    .build()
  c.draw_paragraph(right_lbl, @g2d.Point::new((430.0 : Float), (122.0 : Float)))

  let rad_grad = @g2d.Shader2D::RadialGradient(
    @g2d.Point::new((500.0 : Float), (232.0 : Float)),
    (62.0 : Float),
    [
      @g2d.GradientStop::new((0.0 : Float), @g2d.Color::from_rgba8(255, 120, 180)),
      @g2d.GradientStop::new((1.0 : Float), @g2d.Color::from_rgba8(90, 56, 220)),
    ],
    @g2d.TileMode::Clamp,
  )
  c.draw_circle(@g2d.Point::new((500.0 : Float), (232.0 : Float)), (60.0 : Float), @g2d.Paint::new(shader=Some(rad_grad)))

  // save_layer group alpha + ColorMatrix tint + ImagePattern + ClipOp::Difference
  let _ = c.save_layer(paint=@g2d.Paint::fill(@g2d.Color::rgba((1.0 : Float), (1.0 : Float), (1.0 : Float), (0.55 : Float))))
  c.draw_rrect(
    @g2d.RRect::uniform(@g2d.Rect::new((590.0 : Float), (168.0 : Float), (76.0 : Float), (76.0 : Float)), (12.0 : Float)),
    @g2d.Paint::fill(@g2d.Color::from_rgba8(64, 184, 255)),
  )
  c.draw_rrect(
    @g2d.RRect::uniform(@g2d.Rect::new((626.0 : Float), (200.0 : Float), (76.0 : Float), (76.0 : Float)), (12.0 : Float)),
    @g2d.Paint::fill(@g2d.Color::from_rgba8(255, 148, 64)),
  )
  c.restore()

  // ImagePattern + ClipOp::Difference mini tile swatch at (688, 168)
  let pat_shader = @g2d.Shader2D::ImagePattern(
    badge,
    @g2d.Matrix3::scale((0.6 : Float), (0.6 : Float)),
    @tycho.Filter::Linear,
    @g2d.TileMode::Repeat,
    @g2d.TileMode::Repeat,
  )
  let _ = c.save()
  c.clip_rect(@g2d.Rect::new((712.0 : Float), (190.0 : Float), (20.0 : Float), (20.0 : Float)), op=@g2d.ClipOp::Difference)
  c.draw_rrect(
    @g2d.RRect::uniform(@g2d.Rect::new((696.0 : Float), (170.0 : Float), (54.0 : Float), (54.0 : Float)), (8.0 : Float)),
    @g2d.Paint::new(shader=Some(pat_shader)),
  )
  c.restore()

  // ColorMatrix save_layer badge at (702, 242) — standard 4x5 row-major matrix
  let cmat : FixedArray[Float] = FixedArray::make(20, (0.0 : Float))
  cmat[0] = (0.35 : Float); cmat[1] = (0.55 : Float); cmat[2] = (0.10 : Float)
  cmat[5] = (0.35 : Float); cmat[6] = (0.55 : Float); cmat[7] = (0.10 : Float)
  cmat[10] = (0.35 : Float); cmat[11] = (0.55 : Float); cmat[12] = (0.10 : Float)
  cmat[18] = (1.0 : Float)
  let _ = c.save_layer(paint=@g2d.Paint::new(image_filter=Some(@g2d.ImageFilter::ColorMatrix(cmat))))
  c.draw_rrect(
    @g2d.RRect::uniform(@g2d.Rect::new((702.0 : Float), (242.0 : Float), (48.0 : Float), (48.0 : Float)), (10.0 : Float)),
    @g2d.Paint::fill(@g2d.Color::from_rgba8(240, 80, 120)),
  )
  c.restore()

  // 4. Bottom banner + Frosted Glass BackdropFilter panel
  let bot_rect = @g2d.Rect::new((28.0 : Float), (352.0 : Float), (744.0 : Float), (222.0 : Float))
  c.draw_rrect(@g2d.RRect::uniform(bot_rect, (16.0 : Float)), @g2d.Paint::fill(@g2d.Color::from_rgba8(20, 26, 42)))
  let stripe_colors : Array[@g2d.Color] = [
    @g2d.Color::from_rgba8(245, 75, 110),
    @g2d.Color::from_rgba8(250, 185, 55),
    @g2d.Color::from_rgba8(55, 215, 155),
    @g2d.Color::from_rgba8(65, 155, 255),
    @g2d.Color::from_rgba8(175, 95, 250),
  ]
  for i = 0; i < stripe_colors.length(); i = i + 1 {
    let sx = Float::from_int(52 + i * 144)
    c.draw_rrect(
      @g2d.RRect::uniform(@g2d.Rect::new(sx, (372.0 : Float), (120.0 : Float), (182.0 : Float)), (14.0 : Float)),
      @g2d.Paint::fill(stripe_colors[i]),
    )
  }

  let glass_rect = @g2d.Rect::new((160.0 : Float), (392.0 : Float), (480.0 : Float), (142.0 : Float))
  let glass_rr = @g2d.RRect::uniform(glass_rect, (20.0 : Float))
  let _ = c.save()
  c.clip_rrect(glass_rr)
  let _ = c.save_backdrop_layer(
    glass_rect,
    @g2d.ImageFilter::Blur((16.0 : Float), (16.0 : Float), @g2d.TileMode::Clamp),
  )
  c.draw_rrect(glass_rr, @g2d.Paint::fill(@g2d.Color::rgba((0.08 : Float), (0.11 : Float), (0.20 : Float), (0.48 : Float))))
  c.draw_rrect(glass_rr, @g2d.Paint::stroke(@g2d.Color::rgba((1.0 : Float), (1.0 : Float), (1.0 : Float), (0.55 : Float)), (2.0 : Float)))
  let glass_lbl = @g2d.ParagraphBuilder::new(
    style=@g2d.ParagraphStyle::new(align=@g2d.TextAlign::Center),
  )
    .add_text(
      "BackdropFilter Frosted Glass (ClipRRect + Blur)",
      style=@g2d.TextStyle::new(font~, font_size=(16.0 : Float), color=@g2d.Color::white()),
    )
    .build()
  glass_lbl.layout((440.0 : Float))
  c.draw_paragraph(glass_lbl, @g2d.Point::new((180.0 : Float), (452.0 : Float)))
  c.restore()
  c.restore()

  // Direct per-primitive blend mode (no save_layer): Plus adds red + blue.
  c.draw_rect(
    @g2d.Rect::new((36.0 : Float), (30.0 : Float), (24.0 : Float), (24.0 : Float)),
    @g2d.Paint::fill(@g2d.Color::from_rgba8(255, 0, 0)),
  )
  c.draw_rect(
    @g2d.Rect::new((52.0 : Float), (30.0 : Float), (24.0 : Float), (24.0 : Float)),
    @g2d.Paint::new(
      color=@g2d.Color::from_rgba8(0, 0, 255),
      blend_mode=@g2d.BlendMode2D::Plus,
    ),
  )

  c.finish()
}

///|
fn px_at(px : FixedArray[Byte], w : Int, x : Int, y : Int) -> (Int, Int, Int, Int) {
  let i = (y * w + x) * 4
  (px[i].to_int(), px[i + 1].to_int(), px[i + 2].to_int(), px[i + 3].to_int())
}

///|
fn main {
  try {
    let show_win = @tycho.want_window()
    let shot = @tycho.screenshot_path()
    let dev = @tycho.Device::new_desc(
      @tycho.DeviceDesc::new("Tycho 2D Showcase", validation=true, headless=!show_win),
    )

    // Use system DejaVuSans.ttf if available, gracefully falling back to built-in crisp font on CI.
    let font_bytes = @tycho.read_file_bytes("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf")
    let font = if font_bytes.length() > 0 {
      match @g2d.FontFace::from_ttf_bytes(font_bytes) {
        Some(f) => f
        None => @g2d.FontFace::builtin()
      }
    } else {
      @g2d.FontFace::builtin()
    }
    let badge = make_badge_image()
    let dl = build_scene(font, badge)

    let w = 800
    let h = 600
    let renderer = @g2d.Renderer2D::new(dev)
    let rt = dev.create_render_target(w, h, @tycho.TextureFormat::RGBA8)
    renderer.render_offscreen(dl, rt, clear_color=@g2d.Color::from_rgba8(14, 18, 30))

    let px = rt.readback()
    if shot != "" {
      let _ = @tycho.save_png(shot, w, h, px)
    }

    // Assertions:
    // 1. EvenOdd star top tip around (126, 178) is bright gold (R>220, G>160, B<90)
    let (sr, sg, sb, _) = px_at(px, w, 126, 178)
    let star_tip_ok = sr > 210 && sg > 150 && sb < 100
    // 2. EvenOdd star hollow center at (126, 235) is dark slate card background (NOT gold!)
    let (hr, hg, hb, _) = px_at(px, w, 126, 235)
    let star_hole_ok = hr < 55 && hg < 65 && hb > hr
    // 3. Header gradient left (120, 26) bluer vs right (720, 76) magenta/redder
    let (gl_r, _, gl_b, _) = px_at(px, w, 120, 26)
    let (gr_r, _, _, _) = px_at(px, w, 720, 76)
    let grad_ok = gl_b > gl_r && gr_r > gl_r + 25
    // 4. Radial gradient circle center (500, 232) is warm pink-white
    let (cr, _cg, cb, _) = px_at(px, w, 500, 232)
    let radial_ok = cr > 200 && cb > 140
    // 5. Frosted glass boundary at (300, 405) shows tinted blurred backdrop (not pure black)
    let (fr, fg, fb, fa) = px_at(px, w, 300, 405)
    let frost_ok = fa > 200 && (fr + fg + fb) > 100
    // 6. ClipOp::Difference cutout at (722, 200) stays dark card background
    let (dr, dg, db, _) = px_at(px, w, 722, 200)
    let diff_ok = dr < 55 && dg < 65 && db < 85
    // 7. ColorMatrix grayscale layer at (726, 266) makes R == G == B
    let (mr, mg, mb, _) = px_at(px, w, 726, 266)
    let cmat_ok = mr > 100 && (mr - mg).abs() <= 4 && (mg - mb).abs() <= 4
    // 8. Elliptical pill (rx=24, ry=14): center and the wide-x interior point
    //    are filled; the sharp top-left corner stays transparent/background.
    let (pcr, pcg, pcb, _) = px_at(px, w, 700, 48)
    let pill_center_ok = pcr > 230 && pcg > 200 && pcb < 170
    let (per_, peg, peb, _) = px_at(px, w, 692, 54)
    let pill_ellipse_ok = per_ > 230 && peg > 200 && peb < 170
    let (pxr, pxg, pxb, _) = px_at(px, w, 650, 36)
    let pill_corner_ok = !(pxr > 230 && pxg > 200 && pxb < 170)
    // 9. Title text still rasterizes after switching glyph quads to padded,
    //    subpixel-position-sampleable atlas regions: look for a near-white pixel.
    let mut text_ok = false
    for ty = 44; ty < 68; ty = ty + 1 {
      for tx = 100; tx < 640; tx = tx + 1 {
        let (tr_, tg_, tb_, _) = px_at(px, w, tx, ty)
        if tr_ > 200 && tg_ > 200 && tb_ > 200 {
          text_ok = true
        }
      }
    }
    // 10. Direct Plus blend (no save_layer): red + blue overlap is magenta;
    //     blue over the header gradient stays blue-dominant.
    let (ovr, ovg, ovb, _) = px_at(px, w, 56, 42)
    let blend_overlap_ok = ovr > 200 && ovb > 200 && ovg < 80
    let (blr, blg, blb, _) = px_at(px, w, 70, 32)
    let blend_blue_ok = blb > 200 && blr < 80

    rt.destroy()

    if show_win {
      let cc = @g2d.Color::from_rgba8(14, 18, 30)
      let sc = dev.create_swapchain_desc(
        @tycho.SwapchainDesc::new(
          "54-tycho-2d-showcase",
          w,
          h,
          clear_color=cc.to_clear_color(),
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
        renderer.render_swapchain(sc, dl, clear_color=@g2d.Color::from_rgba8(14, 18, 30))
      }
      sc.destroy()
    }

    renderer.destroy()
    dev.wait_idle()
    let errs = dev.validation_errors()
    let used = dev.allocator_used_bytes()
    dev.destroy()

    if star_tip_ok && star_hole_ok && grad_ok && radial_ok && frost_ok && diff_ok && cmat_ok && pill_center_ok && pill_ellipse_ok && pill_corner_ok && text_ok && blend_overlap_ok && blend_blue_ok && errs == 0 && used == (0 : UInt64) {
      println("[54-tycho-2d-showcase] OK — SDF + elliptical pill + subpixel text + Plus blend + EvenOdd stencil star + Bezier stroke + ImagePattern + ClipDifference + ColorMatrix + frosted blur verified, 0 validation errors")
    } else {
      println(
        "[54-tycho-2d-showcase] FAIL — tip=\{star_tip_ok}(\{sr},\{sg},\{sb}) hole=\{star_hole_ok}(\{hr},\{hg},\{hb}) grad=\{grad_ok} rad=\{radial_ok} frost=\{frost_ok} diff=\{diff_ok}(\{dr},\{dg},\{db}) cmat=\{cmat_ok}(\{mr},\{mg},\{mb}) pill_center=\{pill_center_ok}(\{pcr},\{pcg},\{pcb}) pill_ellipse=\{pill_ellipse_ok}(\{per_},\{peg},\{peb}) pill_corner=\{pill_corner_ok}(\{pxr},\{pxg},\{pxb}) text=\{text_ok} blend_overlap=\{blend_overlap_ok}(\{ovr},\{ovg},\{ovb}) blend_blue=\{blend_blue_ok}(\{blr},\{blg},\{blb}) errs=\{errs} used=\{used}",
      )
    }
  } catch {
    err => println("[54-tycho-2d-showcase] FAIL — \{err}")
  }
}
