// Pure-MoonBit unit tests for laplaceliu/tycho_2d core geometry, paths, atlas, font, and paragraph layout.

///|
test "rect intersection union and matrix transforms" {
  let a = Rect::new((10.0 : Float), (20.0 : Float), (100.0 : Float), (50.0 : Float))
  let b = Rect::new((50.0 : Float), (30.0 : Float), (80.0 : Float), (60.0 : Float))
  let inter = a.intersect(b)
  assert_eq(inter, Rect::new((50.0 : Float), (30.0 : Float), (60.0 : Float), (40.0 : Float)))
  let uni = a.union(b)
  assert_eq(uni, Rect::new((10.0 : Float), (20.0 : Float), (120.0 : Float), (70.0 : Float)))
  let m = Matrix3::translate((100.0 : Float), (50.0 : Float)).concat(
    Matrix3::scale((2.0 : Float), (3.0 : Float)),
  )
  let pt = m.map_point(Point::new((5.0 : Float), (10.0 : Float)))
  assert_eq(pt, Point::new((110.0 : Float), (80.0 : Float)))
  assert_eq(m.is_axis_aligned(), true)
}

///|
test "path builder bounds and tessellation produce triangles" {
  let path = PathBuilder::new()
    .move_to((0.0 : Float), (0.0 : Float))
    .line_to((100.0 : Float), (0.0 : Float))
    .quad_to((120.0 : Float), (50.0 : Float), (100.0 : Float), (100.0 : Float))
    .cubic_to((50.0 : Float), (120.0 : Float), (20.0 : Float), (80.0 : Float), (0.0 : Float), (100.0 : Float))
    .close()
    .build()
  assert_eq(path.is_empty(), false)
  let b = path.bounds()
  assert_true(b.width >= (100.0 : Float) && b.height >= (100.0 : Float))
  let (fan, _) = tessellate_fill_fan(path, Matrix3::identity())
  assert_true(fan.length() >= 18)
  let stroke = tessellate_stroke(
    path,
    Matrix3::identity(),
    (6.0 : Float),
    StrokeCap::Round,
    StrokeJoin::Round,
    (4.0 : Float),
  )
  assert_true(stroke.length() >= 36)
}

///|
test "skyline packer packs and detects full" {
  let p = SkylinePacker::new(64, 64)
  assert_eq(p.alloc(32, 32), Some((0, 0)))
  assert_eq(p.alloc(32, 32), Some((32, 0)))
  assert_eq(p.alloc(64, 32), Some((0, 32)))
  assert_eq(p.alloc(1, 1), None)
  p.reset()
  assert_eq(p.alloc(64, 64), Some((0, 0)))
}

///|
test "builtin font metrics and paragraph wrapping plus caret selection" {
  let pb = ParagraphBuilder::new(
    style=ParagraphStyle::new(align=TextAlign::Left, max_lines=2, ellipsis="..."),
  )
  let p = pb
    .add_text("Hello Tycho UI world!", style=TextStyle::new(font_size=(16.0 : Float)))
    .build()
  p.layout((95.0 : Float))
  assert_eq(p.line_count(), 2)
  assert_true(p.width() > (0.0 : Float) && p.height() > (0.0 : Float))
  let pos = p.get_position_for_offset(Point::new((25.0 : Float), (5.0 : Float)))
  assert_true(pos.offset >= 1 && pos.line == 0)
  let caret = p.get_caret_rect(pos)
  assert_true(caret.width > (0.0 : Float) && caret.height > (0.0 : Float))
  let boxes = p.get_boxes_for_range(0, 5)
  assert_true(boxes.length() == 1 && boxes[0].width > (0.0 : Float))
}

///|
test "canvas records ImagePattern, ColorMatrix, DropShadow, and ClipOp::Difference" {
  let c = Canvas::new()
  let img = Image2D::from_bytes(1, 2, 2, Bytes::make(16, (255 : Byte)))
  let pat_paint = Paint::new(
    shader=Some(
      Shader2D::ImagePattern(
        img,
        Matrix3::identity(),
        @tycho.Filter::Linear,
        TileMode::Repeat,
        TileMode::Mirror,
      ),
    ),
  )
  c.draw_rect(Rect::new((0.0 : Float), (0.0 : Float), (40.0 : Float), (40.0 : Float)), pat_paint)
  let _ = c.save()
  c.clip_rect(Rect::new((5.0 : Float), (5.0 : Float), (10.0 : Float), (10.0 : Float)), op=ClipOp::Difference)
  let mat : FixedArray[Float] = FixedArray::make(20, (0.0 : Float))
  mat[0] = (1.0 : Float)
  mat[6] = (1.0 : Float)
  mat[12] = (1.0 : Float)
  mat[18] = (1.0 : Float)
  let _ = c.save_layer(paint=Paint::new(image_filter=Some(ImageFilter::ColorMatrix(mat))))
  let p = PathBuilder::new().add_circle((20.0 : Float), (20.0 : Float), (12.0 : Float)).build()
  c.draw_path(
    p,
    Paint::new(
      color=Color::white(),
      image_filter=Some(ImageFilter::DropShadow((2.0 : Float), (2.0 : Float), (4.0 : Float), (4.0 : Float), Color::black())),
    ),
  )
  c.restore()
  c.restore()
  let dl = c.finish()
  assert_true(dl.op_count() >= 6)
}

///|
test "elliptical rrect radii and tier-2 path fallback geometry" {
  let rect = Rect::new((0.0 : Float), (0.0 : Float), (120.0 : Float), (60.0 : Float))
  let rx = (24.0 : Float)
  let ry = (10.0 : Float)
  let rr = RRect::per_corner_xy(rect, rx, ry, rx, ry, rx, ry, rx, ry)
  assert_eq(rr.is_circular(), false)
  assert_eq(rr.is_rect(), false)
  let circular = RRect::per_corner(rect, (12.0 : Float), (12.0 : Float), (12.0 : Float), (12.0 : Float))
  assert_eq(circular.is_circular(), true)
  // Elliptical corners must still produce valid fill geometry and bounds.
  let p = PathBuilder::new().add_rrect(rr).build()
  let b = p.bounds()
  assert_true(b.width >= (120.0 : Float) && b.height >= (60.0 : Float))
  let (fan, fan_bounds) = tessellate_fill_fan(p, Matrix3::identity())
  assert_true(fan.length() >= 18)
  assert_true(fan_bounds.width >= (120.0 : Float))
  // Uniform corners keep the same geometry as before (rx == ry).
  let p2 = PathBuilder::new().add_rrect(circular).build()
  assert_true(p2.bounds().width >= (120.0 : Float))
}

///|
test "display list direct-render eligibility" {
  let r = Rect::new((0.0 : Float), (0.0 : Float), (10.0 : Float), (10.0 : Float))
  let c = Canvas::new()
  c.draw_rect(r, Paint::fill(Color::white()))
  c.clip_rect(r, op=ClipOp::Intersect)
  assert_eq(c.finish().needs_offscreen(), false)

  let c2 = Canvas::new()
  c2.clip_rect(r, op=ClipOp::Difference)
  assert_eq(c2.finish().needs_offscreen(), true)

  let c3 = Canvas::new()
  let p = PathBuilder::new().add_circle((5.0 : Float), (5.0 : Float), (3.0 : Float)).build()
  c3.draw_path(p, Paint::fill(Color::white()))
  assert_eq(c3.finish().needs_offscreen(), true)

  let c4 = Canvas::new()
  c4.draw_rrect(RRect::uniform(r, (2.0 : Float)), Paint::fill(Color::white()))
  let sub = c4.finish()
  let c5 = Canvas::new()
  c5.draw_display_list(sub)
  assert_eq(c5.finish().needs_offscreen(), false)

  let c6 = Canvas::new()
  c6.clip_rrect(RRect::uniform(r, (2.0 : Float)))
  assert_eq(c6.finish().needs_offscreen(), true)
}

///|
test "font advance tracks fractional sizes" {
  let f = FontFace::builtin()
  let a = f.advance_width(65, (12.0 : Float))
  let b = f.advance_width(65, (12.5 : Float))
  assert_true(b > a)
  let (asc0, desc0, lh0) = f.metrics((12.0 : Float))
  let (asc1, desc1, lh1) = f.metrics((24.0 : Float))
  assert_true(asc1 > asc0 && desc1 > desc0 && lh1 > lh0)
}

///|
test "path api: arc, conic, add_path, transform, contains, measure" {
  let rect = Rect::new((0.0 : Float), (0.0 : Float), (100.0 : Float), (100.0 : Float))
  // Quarter arc: top-right quadrant of the inscribed ellipse.
  let arc = PathBuilder::new()
    .arc_to(rect, (0.0 : Float), (90.0 : Float), force_move=true)
    .build()
  let qb = arc.compute_tight_bounds()
  assert_true(qb.x > (49.0 : Float) && qb.x < (51.0 : Float))
  assert_true(qb.width > (49.0 : Float) && qb.width < (51.0 : Float))
  // Full ellipse closes and covers the whole rect.
  let full = PathBuilder::new().add_arc(rect, (0.0 : Float), (360.0 : Float)).build()
  let fb = full.compute_tight_bounds()
  assert_true(fb.width > (99.0 : Float) && fb.width < (101.0 : Float))
  assert_true(fb.height > (99.0 : Float) && fb.height < (101.0 : Float))
  // Conic with weight 1 is a parabola with the given control point.
  let conic = PathBuilder::new()
    .move_to((0.0 : Float), (0.0 : Float))
    .conic_to((50.0 : Float), (100.0 : Float), (100.0 : Float), (0.0 : Float), (1.0 : Float))
    .build()
  assert_true(conic.bounds().width >= (100.0 : Float))
  // add_path translates all commands.
  let small = PathBuilder::new()
    .add_rect(Rect::new((0.0 : Float), (0.0 : Float), (10.0 : Float), (10.0 : Float)))
    .build()
  let moved = PathBuilder::new().add_path_translated(small, (20.0 : Float), (30.0 : Float)).build()
  assert_eq(moved.bounds().x, (20.0 : Float))
  assert_eq(moved.bounds().y, (30.0 : Float))
  let scaled = small.transform(Matrix3::scale((2.0 : Float), (2.0 : Float)))
  assert_eq(scaled.bounds().width, (20.0 : Float))
  // contains.
  assert_true(small.contains((5.0 : Float), (5.0 : Float)))
  assert_true(!small.contains((15.0 : Float), (5.0 : Float)))
  // PathMeasure on a straight line.
  let line = PathBuilder::new()
    .move_to((0.0 : Float), (0.0 : Float))
    .line_to((100.0 : Float), (0.0 : Float))
    .build()
  let m = line.measure()
  assert_true(m.length() > (99.0 : Float) && m.length() < (101.0 : Float))
  match m.pos_at((50.0 : Float)) {
    Some((p, d)) => {
      assert_true(p.x > (49.0 : Float) && p.x < (51.0 : Float))
      assert_true(d.x > (0.9 : Float))
    }
    None => assert_true(false)
  }
  let seg = m.segment((25.0 : Float), (75.0 : Float))
  assert_true(seg.bounds().width > (49.0 : Float))
}

///|
test "coverage rasterizer: rect fill and even-odd hole" {
  let rect = PathBuilder::new()
    .add_rect(Rect::new((0.0 : Float), (0.0 : Float), (10.0 : Float), (10.0 : Float)))
    .build()
  let bmp = rasterize_coverage(rect, Matrix3::identity()).unwrap()
  assert_true(bmp.width >= 10 && bmp.height >= 10)
  let cx = 5 - bmp.origin_x
  let cy = 5 - bmp.origin_y
  assert_eq(bmp.pixels[cy * bmp.width + cx].to_int(), 255)
  assert_eq(bmp.pixels[0].to_int(), 0)
  // Two nested rects with EvenOdd leave the center empty.
  let rings = PathBuilder::new()
    .add_rect(Rect::new((0.0 : Float), (0.0 : Float), (20.0 : Float), (20.0 : Float)))
    .add_rect(Rect::new((5.0 : Float), (5.0 : Float), (10.0 : Float), (10.0 : Float)))
    .build(fill_rule=FillRule::EvenOdd)
  let bm2 = rasterize_coverage(rings, Matrix3::identity()).unwrap()
  let hx = 10 - bm2.origin_x
  let hy = 10 - bm2.origin_y
  assert_eq(bm2.pixels[hy * bm2.width + hx].to_int(), 0)
  let rx = 2 - bm2.origin_x
  let ry = 10 - bm2.origin_y
  assert_eq(bm2.pixels[ry * bm2.width + rx].to_int(), 255)
}

///|
test "canvas shape helpers: oval, arc, drrect, points, nine-patch, atlas, dash" {
  let c = Canvas::new()
  c.draw_oval(
    Rect::new((0.0 : Float), (0.0 : Float), (20.0 : Float), (10.0 : Float)),
    Paint::fill(Color::white()),
  )
  c.draw_arc(
    Rect::new((0.0 : Float), (0.0 : Float), (20.0 : Float), (20.0 : Float)),
    (0.0 : Float),
    (180.0 : Float),
    Paint::stroke(Color::white(), (2.0 : Float)),
  )
  c.draw_drrect(
    RRect::uniform(
      Rect::new((0.0 : Float), (0.0 : Float), (40.0 : Float), (40.0 : Float)),
      (8.0 : Float),
    ),
    RRect::uniform(
      Rect::new((10.0 : Float), (10.0 : Float), (20.0 : Float), (20.0 : Float)),
      (4.0 : Float),
    ),
    Paint::fill(Color::white()),
  )
  c.draw_points(
    [Point::new((1.0 : Float), (1.0 : Float)), Point::new((2.0 : Float), (2.0 : Float))],
    Paint::stroke(Color::white(), (4.0 : Float)),
  )
  let img = Image2D::from_bytes(9, 4, 4, Bytes::make(64, (255 : Byte)))
  let ci = Canvas::new()
  ci.draw_nine_patch(
    img,
    Rect::new((1.0 : Float), (1.0 : Float), (2.0 : Float), (2.0 : Float)),
    Rect::new((0.0 : Float), (0.0 : Float), (100.0 : Float), (100.0 : Float)),
  )
  ci.draw_atlas(img, [
    (
      Rect::new((0.0 : Float), (0.0 : Float), (2.0 : Float), (2.0 : Float)),
      Rect::new((0.0 : Float), (0.0 : Float), (10.0 : Float), (10.0 : Float)),
    ),
    (
      Rect::new((2.0 : Float), (2.0 : Float), (2.0 : Float), (2.0 : Float)),
      Rect::new((10.0 : Float), (10.0 : Float), (10.0 : Float), (10.0 : Float)),
    ),
  ])
  // Both nine-patch and atlas collapse into one indexed mesh each.
  assert_eq(ci.finish().op_count(), 2)
  let line = PathBuilder::new()
    .move_to((0.0 : Float), (0.0 : Float))
    .line_to((100.0 : Float), (0.0 : Float))
    .build()
  c.draw_dashed_path(
    line,
    [(10.0 : Float), (10.0 : Float)],
    (0.0 : Float),
    Paint::stroke(Color::white(), (2.0 : Float)),
  )
  let dl = c.finish()
  assert_true(dl.op_count() >= 6)
  let dashed = line.dashed([(10.0 : Float), (10.0 : Float)])
  let m = PathMeasure::new(dashed)
  assert_true(m.length() > (49.0 : Float) && m.length() < (51.0 : Float))
}

///|
test "path ops: union, intersect, difference, xor with a convex clip" {
  let a = PathBuilder::new()
    .add_rect(Rect::new((0.0 : Float), (0.0 : Float), (10.0 : Float), (10.0 : Float)))
    .build()
  let b = PathBuilder::new()
    .add_rect(Rect::new((4.0 : Float), (6.0 : Float), (10.0 : Float), (10.0 : Float)))
    .build()
  let u = a.op(b, PathOp::Union).unwrap()
  assert_true(u.contains((2.0 : Float), (2.0 : Float)))
  assert_true(u.contains((7.0 : Float), (7.0 : Float)))
  assert_true(u.contains((12.0 : Float), (12.0 : Float)))
  assert_true(u.bounds().width >= (14.0 : Float))
  let i = a.op(b, PathOp::Intersect).unwrap()
  let ib = i.compute_tight_bounds()
  assert_true(ib.x > (3.5 : Float) && ib.x < (4.5 : Float))
  assert_true(ib.y > (5.5 : Float) && ib.y < (6.5 : Float))
  assert_true(ib.width > (5.5 : Float) && ib.width < (6.5 : Float))
  assert_true(ib.height > (3.5 : Float) && ib.height < (4.5 : Float))
  assert_true(i.contains((7.0 : Float), (7.0 : Float)))
  assert_true(!i.contains((2.0 : Float), (2.0 : Float)))
  let d = a.op(b, PathOp::Difference).unwrap()
  assert_true(d.contains((2.0 : Float), (2.0 : Float)))
  assert_true(!d.contains((7.0 : Float), (7.0 : Float)))
  assert_true(!d.contains((12.0 : Float), (12.0 : Float)))
  let x = a.op(b, PathOp::Xor).unwrap()
  assert_true(x.contains((2.0 : Float), (2.0 : Float)))
  assert_true(!x.contains((7.0 : Float), (7.0 : Float)))
  assert_true(x.contains((12.0 : Float), (12.0 : Float)))
  // Non-convex clips fall back to scanline compositing.
  let notch = PathBuilder::new()
    .move_to((0.0 : Float), (0.0 : Float))
    .line_to((10.0 : Float), (0.0 : Float))
    .line_to((5.0 : Float), (5.0 : Float))
    .line_to((10.0 : Float), (10.0 : Float))
    .line_to((0.0 : Float), (10.0 : Float))
    .close()
    .build()
  let ni = a.op(notch, PathOp::Intersect).unwrap()
  assert_true(ni.contains((2.0 : Float), (4.0 : Float)))
  assert_true(!ni.contains((9.0 : Float), (4.0 : Float)))
  let nd = a.op(notch, PathOp::Difference).unwrap()
  assert_true(nd.contains((9.0 : Float), (4.0 : Float)))
  assert_true(!nd.contains((2.0 : Float), (4.0 : Float)))
  let nu = a.op(notch, PathOp::Union).unwrap()
  assert_true(nu.contains((2.0 : Float), (4.0 : Float)))
  assert_true(nu.contains((9.0 : Float), (4.0 : Float)))
  let nx = a.op(notch, PathOp::Xor).unwrap()
  assert_true(nx.contains((9.0 : Float), (4.0 : Float)))
  assert_true(!nx.contains((2.0 : Float), (4.0 : Float)))
}

///|
test "paint color/mask filters are independent of image_filter" {
  let m : FixedArray[Float] = FixedArray::make(20, (0.0 : Float))
  let p = Paint::new(
    color_filter=Some(ColorFilter::Matrix(m)),
    mask_filter=Some(MaskFilter::Blur((2.0 : Float), (3.0 : Float))),
  )
  match p.image_filter {
    None => assert_true(true)
    Some(_) => assert_true(false)
  }
  match p.mask_filter {
    Some(MaskFilter::Blur(sx, sy)) => {
      assert_eq(sx, (2.0 : Float))
      assert_eq(sy, (3.0 : Float))
    }
    None => assert_true(false)
  }
  match p.color_filter {
    Some(ColorFilter::Matrix(mm)) => assert_eq(mm.length(), 20)
    _ => assert_true(false)
  }
}

///|
test "draw_vertices records a mesh and expands bounds" {
  let c = Canvas::new()
  c.draw_vertices([
    Vertex2D::new((10.0 : Float), (20.0 : Float)),
    Vertex2D::new((50.0 : Float), (20.0 : Float)),
    Vertex2D::new((10.0 : Float), (60.0 : Float)),
  ], [0, 1, 2])
  let dl = c.finish()
  assert_eq(dl.op_count(), 1)
  let b = dl.bounds()
  assert_true(b.x <= (10.0 : Float))
  assert_true(b.y <= (20.0 : Float))
  assert_true(b.width >= (40.0 : Float))
  assert_true(b.height >= (40.0 : Float))
}

///|
test "draw_path_shadow wraps a blurred layer" {
  let c = Canvas::new()
  let p = PathBuilder::new()
    .add_rect(Rect::new((0.0 : Float), (0.0 : Float), (20.0 : Float), (20.0 : Float)))
    .build()
  c.draw_path_shadow(p, (2.0 : Float), (2.0 : Float), (4.0 : Float), Color::from_rgba8(0, 0, 0))
  let dl = c.finish()
  // SaveLayer + DrawPath + Restore.
  assert_eq(dl.op_count(), 3)
}

///|
test "font fallback chain picks per-codepoint faces" {
  let latin_bytes = @tycho.read_file_bytes(
    "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
  )
  let cjk_bytes = @tycho.read_file_bytes(
    "/usr/share/fonts/truetype/droid/DroidSansFallbackFull.ttf",
  )
  match (
    FontFace::from_ttf_bytes(latin_bytes),
    FontFace::from_ttf_bytes(cjk_bytes),
  ) {
    (Some(latin), Some(cjk)) => {
      let chain = FontFallbackChain::new(latin, fallbacks=[cjk])
      assert_eq(chain.face_for(65).id(), latin.id())
      assert_eq(chain.face_for(0x4E2D).id(), cjk.id())
      let p = ParagraphBuilder::new()
        .add_text(
          "A中B",
          style=TextStyle::new(font=latin, fallback=Some(chain)),
        )
        .build()
      p.layout((1000.0 : Float))
      let gs = p.placed_glyphs()
      assert_eq(gs.length(), 3)
      assert_eq(gs[1].codepoint, 0x4E2D)
      assert_eq(gs[0].font.id(), latin.id())
      assert_eq(gs[1].font.id(), cjk.id())
      assert_eq(gs[2].font.id(), latin.id())
    }
    _ => ()
  }
}

///|
test "CBDT color glyph parses and emoji fallback prefers color" {
  let latin_bytes = @tycho.read_file_bytes(
    "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
  )
  let emoji_bytes = @tycho.read_file_bytes(
    "/usr/share/fonts/truetype/noto/NotoColorEmoji.ttf",
  )
  match (
    FontFace::from_ttf_bytes(latin_bytes),
    FontFace::from_ttf_bytes(emoji_bytes),
  ) {
    (Some(latin), Some(emoji)) => {
      assert_true(emoji.has_color_bitmap(0x1F600))
      match emoji.color_bitmap(0x1F600, (48.0 : Float)) {
        Some(cb) => {
          assert_true(cb.width > 0 && cb.height > 0)
          assert_true(cb.png.length() > 0)
        }
        None => assert_true(false)
      }
      let chain = FontFallbackChain::new(latin, fallbacks=[emoji])
      assert_eq(chain.face_for(0x1F600).id(), emoji.id())
    }
    _ => ()
  }
}

///|
test "justify, tab advance and kinsoku helpers" {
  let p = ParagraphBuilder::new(
    style=ParagraphStyle::new(align=TextAlign::Justify),
  )
    .add_text(
      "one two three four five six",
      style=TextStyle::new(font_size=(16.0 : Float)),
    )
    .build()
  p.layout((80.0 : Float))
  let lines = p.line_metrics()
  assert_true(lines.length() > 1)
  assert_true(@tmath.abs_f(lines[0].width - (80.0 : Float)) < (1.0 : Float))
  assert_true(lines[lines.length() - 1].width < (80.0 : Float))
  // Tab advances like four spaces.
  let pt = ParagraphBuilder::new()
    .add_text("A\tB", style=TextStyle::new(font_size=(16.0 : Float)))
    .build()
  pt.layout((1000.0 : Float))
  let gs = pt.placed_glyphs()
  assert_eq(gs.length(), 2)
  assert_true(gs[1].x > gs[0].advance * (3.0 : Float))
  assert_true(is_no_start(0xFF0C))
  assert_true(is_no_end(0xFF08))
}

///|
test "legacy kern and RTL visual order" {
  let bytes = @tycho.read_file_bytes(
    "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
  )
  match FontFace::from_ttf_bytes(bytes) {
    Some(font) => {
      let k = font.kern(65, 86, (100.0 : Float))
      assert_true(k < (0.0 : Float))
      assert_true(font.has_gpos_kern())
      let gp = font.gpos_kern(
        font.glyph_id(65),
        font.glyph_id(86),
        (100.0 : Float),
      )
      assert_true(gp < (0.0 : Float))
      let p = ParagraphBuilder::new()
        .add_text(
          "AV",
          style=TextStyle::new(font=font, font_size=(100.0 : Float)),
        )
        .build()
      p.layout((1000.0 : Float))
      let gs = p.placed_glyphs()
      assert_eq(gs.length(), 2)
      let sum = font.advance_width(65, (100.0 : Float)) +
        font.advance_width(86, (100.0 : Float))
      assert_true(gs[1].x < sum)
      // A pure Hebrew run is laid out in reverse visual order.
      let pr = ParagraphBuilder::new()
        .add_text(
          "אבג",
          style=TextStyle::new(font=font, font_size=(100.0 : Float)),
        )
        .build()
      pr.layout((1000.0 : Float))
      let gr = pr.placed_glyphs()
      assert_eq(gr.length(), 3)
      assert_eq(gr[0].codepoint, 0x05D2)
      assert_eq(gr[1].codepoint, 0x05D1)
      assert_eq(gr[2].codepoint, 0x05D0)

      // Real GSUB `liga` ligature: two source chars -> one glyph id.
      let lig = shape_run(font, "fi")
      assert_eq(lig.length(), 1)
      assert_eq(lig[0].cp, 102)
      assert_eq(lig[0].source_end, 2)
      assert_true(lig[0].glyph_id > 0)
      assert_eq(lig[0].glyph_id, font.glyph_id(0xFB01))
      let pl = ParagraphBuilder::new()
        .add_text(
          "fi",
          style=TextStyle::new(font=font, font_size=(100.0 : Float)),
        )
        .build()
      pl.layout((1000.0 : Float))
      let gl = pl.placed_glyphs()
      assert_eq(gl.length(), 1)
      assert_eq(gl[0].codepoint, 102)
      assert_eq(gl[0].glyph_id, font.glyph_id(0xFB01))

      // Arabic joining forms: beh+alef -> initial beh + final alef.
      let ar1 = shape_run(font, "با")
      assert_eq(ar1.length(), 2)
      assert_eq(ar1[0].cp, 0x0628)
      assert_eq(ar1[1].cp, 0x0627)
      assert_eq(ar1[0].glyph_id, font.glyph_id(0xFE91))
      assert_eq(ar1[1].glyph_id, font.glyph_id(0xFE8E))
      // alef+beh -> isolated alef + isolated beh.
      let ar2 = shape_run(font, "اب")
      assert_eq(ar2.length(), 2)
      assert_eq(ar2[0].cp, 0xFE8D)
      assert_eq(ar2[1].cp, 0xFE8F)
      assert_eq(ar2[0].glyph_id, font.glyph_id(0xFE8D))
      assert_eq(ar2[1].glyph_id, font.glyph_id(0xFE8F))
      // `rlig` combines lam+alef into one glyph with one source cluster.
      let la = shape_run(font, "لا")
      assert_eq(la.length(), 1)
      assert_eq(la[0].source_start, 0)
      assert_eq(la[0].source_end, 2)
    }
    None => ()
  }
}

///|
test "synthetic bold and italic glyph bitmaps" {
  let bytes = @tycho.read_file_bytes(
    "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
  )
  match FontFace::from_ttf_bytes(bytes) {
    Some(font) =>
      match font.ttf {
        Some(t) => {
          let gid = font.glyph_id(65)
          let (ox, oy, gw, gh, px) = rasterize_ttf_glyph_gid(t, gid, (64.0 : Float))
          let (bx, by, bw, bh, bpx) = synthesize_glyph_bitmap(
            ox,
            oy,
            gw,
            gh,
            px,
            true,
            false,
          )
          let (_ix, _iy, iw, ih, _ipx) = synthesize_glyph_bitmap(
            ox,
            oy,
            gw,
            gh,
            px,
            false,
            true,
          )
          assert_true(bw > gw && bh > gh)
          assert_true(bx == ox - 1 && by == oy - 1)
          assert_true(iw > gw && ih == gh)
          let mut normal_px = 0
          for b in px {
            if b.to_int() > 0 {
              normal_px = normal_px + 1
            }
          }
          let mut bold_px = 0
          for b in bpx {
            if b.to_int() > 0 {
              bold_px = bold_px + 1
            }
          }
          assert_true(bold_px > normal_px)
          // Style flags propagate to PlacedGlyph.
          let p = ParagraphBuilder::new()
            .add_text(
              "A",
              style=TextStyle::new(
                font=font,
                font_size=(64.0 : Float),
                bold=true,
                italic=true,
              ),
            )
            .build()
          p.layout((1000.0 : Float))
          let gs = p.placed_glyphs()
          assert_eq(gs.length(), 1)
          assert_true(gs[0].bold && gs[0].italic)
        }
        None => ()
      }
    None => ()
  }
}

///|
test "SDF glyph encoding keeps inside/outside distances" {
  let bytes = @tycho.read_file_bytes(
    "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
  )
  match FontFace::from_ttf_bytes(bytes) {
    Some(font) =>
      match font.ttf {
        Some(t) => {
          let (_ox, _oy, gw, gh, px) = rasterize_ttf_glyph_gid(
            t,
            font.glyph_id(65),
            (64.0 : Float),
          )
          let (w, h, sdf) = build_sdf(gw, gh, px)
          assert_eq(w, gw + SDF_SPREAD * 2)
          assert_eq(h, gh + SDF_SPREAD * 2)
          let mut hi = 0
          let mut lo = 0
          for b in sdf {
            let v = b.to_int()
            if v > 200 {
              hi = hi + 1
            }
            if v < 50 {
              lo = lo + 1
            }
          }
          assert_true(hi > 0 && lo > 0)
          // Fixed base-size entries scale metrics for arbitrary sizes.
          let e : GlyphEntry = {
            uv_x0: (0.0 : Float),
            uv_y0: (0.0 : Float),
            uv_x1: (1.0 : Float),
            uv_y1: (1.0 : Float),
            offset_x: -10,
            offset_y: -20,
            width: 100,
            height: 80,
            advance: 40.0,
            is_sdf: true,
            sdf_base: (64.0 : Float),
          }
          let s = scale_glyph_entry(e, (1.5 : Float), (60.0 : Float))
          assert_eq(s.offset_x, -15)
          assert_eq(s.offset_y, -30)
          assert_eq(s.width, 150)
          assert_eq(s.height, 120)
          assert_true(s.advance == (60.0 : Float))
        }
        None => ()
      }
    None => ()
  }
}

///|
fn test_u16(a : Array[Byte], off : Int, v : Int) -> Unit {
  a[off] = ((v >> 8) & 0xFF).to_byte()
  a[off + 1] = (v & 0xFF).to_byte()
}

///|
fn test_u32(a : Array[Byte], off : Int, v : Int) -> Unit {
  a[off] = ((v >> 24) & 0xFF).to_byte()
  a[off + 1] = ((v >> 16) & 0xFF).to_byte()
  a[off + 2] = ((v >> 8) & 0xFF).to_byte()
  a[off + 3] = (v & 0xFF).to_byte()
}

///|
test "bidi weak/neutral resolution orders digits and Hebrew" {
  let p = ParagraphBuilder::new()
    .add_text("ABC אבג", style=TextStyle::new(font_size=(16.0 : Float)))
    .build()
  p.layout((1000.0 : Float))
  let cps : Array[Int] = []
  for g in p.placed_glyphs() {
    cps.push(g.codepoint)
  }
  assert_eq(cps.length(), 6)
  assert_eq(cps[0], 65)
  assert_eq(cps[1], 66)
  assert_eq(cps[2], 67)
  assert_eq(cps[3], 0x05D2)
  assert_eq(cps[4], 0x05D1)
  assert_eq(cps[5], 0x05D0)

  let p2 = ParagraphBuilder::new()
    .add_text("אבג 123", style=TextStyle::new(font_size=(16.0 : Float)))
    .build()
  p2.layout((1000.0 : Float))
  let cps2 : Array[Int] = []
  for g in p2.placed_glyphs() {
    cps2.push(g.codepoint)
  }
  assert_eq(cps2.length(), 6)
  assert_eq(cps2[0], 49)
  assert_eq(cps2[1], 50)
  assert_eq(cps2[2], 51)
  assert_eq(cps2[3], 0x05D2)
  assert_eq(cps2[4], 0x05D1)
  assert_eq(cps2[5], 0x05D0)
}

///|
test "caret affinity distinguishes line-end positions" {
  let p = ParagraphBuilder::new()
    .add_text("AB", style=TextStyle::new(font_size=(16.0 : Float)))
    .build()
  p.layout((1000.0 : Float))
  let down = p.get_caret_rect(TextPosition::new(2, 0))
  let up = p.get_caret_rect(
    TextPosition::new(2, 0, affinity=TextAffinity::Upstream),
  )
  assert_true(up.x < down.x)
}

///|
test "inline image participates in paragraph layout" {
  let px : Array[Byte] = [
    255, 0, 0, 255, 0, 255, 0, 255, 0, 0, 255, 255, 255, 255, 0, 255,
  ]
  let img = Image2D::from_bytes(7, 2, 2, Bytes::from_array(px))
  let p = ParagraphBuilder::new()
    .add_text("A", style=TextStyle::new(font_size=(16.0 : Float)))
    .add_inline_image(img, (20.0 : Float), (10.0 : Float))
    .add_text("B", style=TextStyle::new(font_size=(16.0 : Float)))
    .build()
  p.layout((1000.0 : Float))
  let gs = p.placed_glyphs()
  assert_eq(gs.length(), 3)
  let mut found = false
  for g in gs {
    match g.image {
      Some(_) => {
        found = true
        assert_true(g.image_w == (20.0 : Float))
        assert_true(g.image_h == (10.0 : Float))
      }
      None => ()
    }
  }
  assert_true(found)
  assert_true(p.line_metrics()[0].height >= (10.0 : Float))
}

///|
test "hyphen and soft hyphen break opportunities" {
  let p = ParagraphBuilder::new()
    .add_text(
      "co\u{00AD}operate",
      style=TextStyle::new(font_size=(16.0 : Float)),
    )
    .build()
  p.layout((40.0 : Float))
  assert_true(p.line_metrics().length() > 1)
  for g in p.placed_glyphs() {
    assert_true(g.codepoint != 0x00AD)
  }
  let ph = ParagraphBuilder::new()
    .add_text(
      "well-known",
      style=TextStyle::new(font_size=(16.0 : Float)),
    )
    .build()
  ph.layout((40.0 : Float))
  assert_true(ph.line_metrics().length() > 1)
}

///|
test "fvar axes and variation-to-synthetic style" {
  let a = Array::make(36, (0 : Byte))
  test_u16(a, 0, 1)
  test_u16(a, 4, 16)
  test_u16(a, 6, 2)
  test_u16(a, 8, 1)
  test_u16(a, 10, 20)
  // Axis "wght": 100..900, default 400 (16.16 fixed).
  a[16] = 119
  a[17] = 103
  a[18] = 104
  a[19] = 116
  test_u32(a, 20, 100 * 65536)
  test_u32(a, 24, 400 * 65536)
  test_u32(a, 28, 900 * 65536)
  let axes = parse_fvar(Bytes::from_array(a), 0)
  assert_eq(axes.length(), 1)
  assert_eq(axes[0].tag, "wght")
  assert_true(axes[0].min_value == (100.0 : Float))
  assert_true(axes[0].default_value == (400.0 : Float))
  assert_true(axes[0].max_value == (900.0 : Float))

  let bytes = @tycho.read_file_bytes(
    "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
  )
  match FontFace::from_ttf_bytes(bytes) {
    Some(font) => {
      assert_eq(font.variation_axes().length(), 0)
      let p = ParagraphBuilder::new()
        .add_text(
          "A",
          style=TextStyle::new(
            font=font,
            font_size=(48.0 : Float),
            variations=[("wght", (700.0 : Float))],
          ),
        )
        .build()
      p.layout((1000.0 : Float))
      assert_true(p.placed_glyphs()[0].bold)
      let pi = ParagraphBuilder::new()
        .add_text(
          "A",
          style=TextStyle::new(
            font=font,
            font_size=(48.0 : Float),
            variations=[("ital", (1.0 : Float))],
          ),
        )
        .build()
      pi.layout((1000.0 : Float))
      assert_true(pi.placed_glyphs()[0].italic)
    }
    None => ()
  }
}

///|
test "GDEF classes drive GSUB lookup flags" {
  let bytes = @tycho.read_file_bytes(
    "/usr/share/fonts/truetype/lohit-devanagari/Lohit-Devanagari.ttf",
  )
  match FontFace::from_ttf_bytes(bytes) {
    Some(font) =>
      match (font.gdef, font.gsub) {
        (Some(gdef), Some(gsub)) => {
          let base = font.glyph_id(0x0915)
          let mark = font.glyph_id(0x093F)
          assert_eq(gdef.glyph_class(base), 1)
          assert_eq(gdef.glyph_class(mark), 3)
          assert_true(gsub_glyph_ignored(gsub, mark, 0x0008))
          assert_true(!gsub_glyph_ignored(gsub, base, 0x0008))
        }
        _ => assert_true(false)
      }
    None => ()
  }
}

///|
test "devanagari pre-base matra and conjunct features" {
  let bytes = @tycho.read_file_bytes(
    "/usr/share/fonts/truetype/lohit-devanagari/Lohit-Devanagari.ttf",
  )
  match FontFace::from_ttf_bytes(bytes) {
    Some(font) => {
      // i-matra is reordered before the base consonant.
      let ki = shape_run(font, "कि")
      assert_eq(ki.length(), 2)
      assert_eq(ki[0].cp, 0x093F)
      assert_eq(ki[1].cp, 0x0915)
      // half/cjct consumes the virama in a conjunct.
      let ste = shape_run(font, "स्ते")
      assert_true(ste.length() > 0)
      let mut has_virama = false
      for s in ste {
        if s.cp == 0x094D {
          has_virama = true
        }
      }
      assert_true(!has_virama)
      assert_true(ste.length() < 4)
    }
    None => ()
  }
}
