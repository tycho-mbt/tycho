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
