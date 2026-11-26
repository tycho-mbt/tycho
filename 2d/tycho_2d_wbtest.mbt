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
  c.draw_nine_patch(
    img,
    Rect::new((1.0 : Float), (1.0 : Float), (2.0 : Float), (2.0 : Float)),
    Rect::new((0.0 : Float), (0.0 : Float), (100.0 : Float), (100.0 : Float)),
  )
  c.draw_atlas(img, [
    (
      Rect::new((0.0 : Float), (0.0 : Float), (2.0 : Float), (2.0 : Float)),
      Rect::new((0.0 : Float), (0.0 : Float), (10.0 : Float), (10.0 : Float)),
    ),
    (
      Rect::new((2.0 : Float), (2.0 : Float), (2.0 : Float), (2.0 : Float)),
      Rect::new((10.0 : Float), (10.0 : Float), (10.0 : Float), (10.0 : Float)),
    ),
  ])
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
  assert_true(dl.op_count() >= 7)
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
  // Non-convex clips are rejected so callers can fall back.
  let notch = PathBuilder::new()
    .move_to((0.0 : Float), (0.0 : Float))
    .line_to((10.0 : Float), (0.0 : Float))
    .line_to((5.0 : Float), (5.0 : Float))
    .line_to((10.0 : Float), (10.0 : Float))
    .line_to((0.0 : Float), (10.0 : Float))
    .close()
    .build()
  match a.op(notch, PathOp::Intersect) {
    Some(_) => assert_true(false)
    None => assert_true(true)
  }
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
