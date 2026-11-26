// Declarative 2D Canvas recording into an immutable DisplayList (inspired by SkCanvas).

///|
priv struct CanvasSaveEntry {
  transform : Matrix3
}

///|
pub struct Canvas {
  priv ops : Array[DrawOp]
  priv stack : Array[CanvasSaveEntry]
  priv mut cur_transform : Matrix3
  priv mut bounds : Rect
}

///|
pub fn Canvas::new() -> Canvas {
  {
    ops: [],
    stack: [],
    cur_transform: Matrix3::identity(),
    bounds: Rect::zero(),
  }
}

///|
fn Canvas::expand_bounds(self : Canvas, local_rect : Rect) -> Unit {
  if local_rect.is_empty() {
    return
  }
  let mapped = self.cur_transform.map_rect(local_rect)
  self.bounds = self.bounds.union(mapped)
}

///|
pub fn Canvas::save_count(self : Canvas) -> Int {
  self.stack.length() + 1
}

///|
pub fn Canvas::save(self : Canvas) -> Int {
  let prev = self.save_count()
  self.stack.push({ transform: self.cur_transform })
  self.ops.push(DrawOp::Save)
  prev
}

///|
pub fn Canvas::save_layer(
  self : Canvas,
  bounds? : Rect? = None,
  paint? : Paint = Paint::new(),
) -> Int {
  let prev = self.save_count()
  self.stack.push({ transform: self.cur_transform })
  self.ops.push(DrawOp::SaveLayer(bounds, paint))
  prev
}

///|
pub fn Canvas::save_backdrop_layer(
  self : Canvas,
  bounds : Rect,
  filter : ImageFilter,
) -> Int {
  let prev = self.save_count()
  self.stack.push({ transform: self.cur_transform })
  self.ops.push(DrawOp::SaveBackdropLayer(bounds, filter))
  self.expand_bounds(bounds)
  prev
}

///|
pub fn Canvas::restore(self : Canvas) -> Unit {
  match self.stack.pop() {
    Some(entry) => {
      self.cur_transform = entry.transform
      self.ops.push(DrawOp::Restore)
    }
    None => ()
  }
}

///|
pub fn Canvas::restore_to_count(self : Canvas, target_count : Int) -> Unit {
  let target = if target_count < 1 { 1 } else { target_count }
  while self.save_count() > target {
    self.restore()
  }
}

///|
pub fn Canvas::concat(self : Canvas, mat : Matrix3) -> Unit {
  self.cur_transform = self.cur_transform.concat(mat)
  self.ops.push(DrawOp::Concat(mat))
}

///|
pub fn Canvas::translate(self : Canvas, dx : Float, dy : Float) -> Unit {
  self.concat(Matrix3::translate(dx, dy))
}

///|
pub fn Canvas::scale(self : Canvas, sx : Float, sy : Float) -> Unit {
  self.concat(Matrix3::scale(sx, sy))
}

///|
pub fn Canvas::rotate(self : Canvas, radians : Float) -> Unit {
  self.concat(Matrix3::rotate(radians))
}

///|
pub fn Canvas::clip_rect(
  self : Canvas,
  rect : Rect,
  op? : ClipOp = ClipOp::Intersect,
) -> Unit {
  self.ops.push(DrawOp::ClipRect(rect, op))
}

///|
pub fn Canvas::clip_rrect(
  self : Canvas,
  rrect : RRect,
  op? : ClipOp = ClipOp::Intersect,
) -> Unit {
  self.ops.push(DrawOp::ClipRRect(rrect, op))
}

///|
pub fn Canvas::clip_path(
  self : Canvas,
  path : Path,
  op? : ClipOp = ClipOp::Intersect,
) -> Unit {
  self.ops.push(DrawOp::ClipPath(path, op))
}

///|
pub fn Canvas::clear(self : Canvas, color : Color) -> Unit {
  self.ops.push(DrawOp::Clear(color))
}

///|
pub fn Canvas::draw_rect(self : Canvas, rect : Rect, paint : Paint) -> Unit {
  self.expand_bounds(rect)
  self.ops.push(DrawOp::DrawRect(rect, paint))
}

///|
pub fn Canvas::draw_rrect(self : Canvas, rrect : RRect, paint : Paint) -> Unit {
  self.expand_bounds(rrect.rect)
  self.ops.push(DrawOp::DrawRRect(rrect, paint))
}

///|
pub fn Canvas::draw_circle(
  self : Canvas,
  center : Point,
  radius : Float,
  paint : Paint,
) -> Unit {
  let d = radius * (2.0 : Float)
  self.expand_bounds(Rect::new(center.x - radius, center.y - radius, d, d))
  self.ops.push(DrawOp::DrawCircle(center, radius, paint))
}

///|
pub fn Canvas::draw_line(
  self : Canvas,
  p0 : Point,
  p1 : Point,
  paint : Paint,
) -> Unit {
  let pad = paint.stroke_width * (0.5 : Float)
  let r = Rect::from_ltrb(
    @tmath.min_f(p0.x, p1.x) - pad,
    @tmath.min_f(p0.y, p1.y) - pad,
    @tmath.max_f(p0.x, p1.x) + pad,
    @tmath.max_f(p0.y, p1.y) + pad,
  )
  self.expand_bounds(r)
  self.ops.push(DrawOp::DrawLine(p0, p1, paint))
}

///|
pub fn Canvas::draw_rrect_shadow(
  self : Canvas,
  rrect : RRect,
  dx : Float,
  dy : Float,
  blur : Float,
  spread : Float,
  color : Color,
) -> Unit {
  let pad = blur + spread
  self.expand_bounds(rrect.rect.offset(dx, dy).inflate(pad))
  self.ops.push(DrawOp::DrawRRectShadow(rrect, dx, dy, blur, spread, color))
}

///|
pub fn Canvas::draw_path(self : Canvas, path : Path, paint : Paint) -> Unit {
  let pad = if paint.style == PaintStyle::Fill {
    (0.0 : Float)
  } else {
    paint.stroke_width * (0.5 : Float)
  }
  self.expand_bounds(path.bounds().inflate(pad))
  self.ops.push(DrawOp::DrawPath(path, paint))
}

///|
pub fn Canvas::draw_oval(self : Canvas, rect : Rect, paint : Paint) -> Unit {
  let p = PathBuilder::new().add_oval(rect).build()
  self.draw_path(p, paint)
}

///|
pub fn Canvas::draw_arc(
  self : Canvas,
  rect : Rect,
  start_degrees : Float,
  sweep_degrees : Float,
  paint : Paint,
) -> Unit {
  let pb = PathBuilder::new()
  let _ = pb.arc_to(rect, start_degrees, sweep_degrees, force_move=true)
  if @tmath.abs_f(sweep_degrees) >= (359.999 : Float) {
    let _ = pb.close()
  }
  self.draw_path(pb.build(), paint)
}

///|
// Draw the ring between two rounded rects. Fill uses an EvenOdd path; stroke
// draws both contours.
pub fn Canvas::draw_drrect(
  self : Canvas,
  outer : RRect,
  inner : RRect,
  paint : Paint,
) -> Unit {
  if paint.style == PaintStyle::Fill || paint.style == PaintStyle::StrokeAndFill {
    let p = PathBuilder::new()
      .add_rrect(outer)
      .add_rrect(inner)
      .build(fill_rule=FillRule::EvenOdd)
    self.draw_path(p, { ..paint, style: PaintStyle::Fill })
  }
  if paint.style == PaintStyle::Stroke || paint.style == PaintStyle::StrokeAndFill {
    let sp = { ..paint, style: PaintStyle::Stroke }
    self.draw_rrect(outer, sp)
    if !inner.rect.is_empty() {
      self.draw_rrect(inner, sp)
    }
  }
}

///|
pub fn Canvas::draw_points(
  self : Canvas,
  points : Array[Point],
  paint : Paint,
) -> Unit {
  let r = @tmath.max_f(paint.stroke_width * (0.5 : Float), (0.5 : Float))
  for p in points {
    self.draw_circle(p, r, paint)
  }
}

///|
pub fn Canvas::draw_dashed_path(
  self : Canvas,
  path : Path,
  pattern : Array[Float],
  phase : Float,
  paint : Paint,
) -> Unit {
  self.draw_path(path.dashed(pattern, phase~), paint)
}

///|
pub fn Canvas::draw_image(
  self : Canvas,
  image : Image2D,
  pos : Point,
  paint? : Paint = Paint::new(),
) -> Unit {
  let src = Rect::new(
    (0.0 : Float),
    (0.0 : Float),
    Float::from_int(image.width),
    Float::from_int(image.height),
  )
  let dst = Rect::new(
    pos.x,
    pos.y,
    Float::from_int(image.width),
    Float::from_int(image.height),
  )
  self.draw_image_rect(image, src, dst, paint~)
}

///|
pub fn Canvas::draw_image_rect(
  self : Canvas,
  image : Image2D,
  src : Rect,
  dst : Rect,
  paint? : Paint = Paint::new(),
) -> Unit {
  self.expand_bounds(dst)
  self.ops.push(DrawOp::DrawImage(image, src, dst, paint))
}

///|
// Nine-patch: corners keep their source size, edges stretch, center scales.
pub fn Canvas::draw_nine_patch(
  self : Canvas,
  image : Image2D,
  center_src : Rect,
  dst : Rect,
  paint? : Paint = Paint::new(),
) -> Unit {
  let iw = Float::from_int(image.width)
  let ih = Float::from_int(image.height)
  let l = @tmath.clamp_f(center_src.x, (0.0 : Float), iw)
  let t = @tmath.clamp_f(center_src.y, (0.0 : Float), ih)
  let r = iw - @tmath.clamp_f(center_src.right(), (0.0 : Float), iw)
  let b = ih - @tmath.clamp_f(center_src.bottom(), (0.0 : Float), ih)
  let sx : Array[Float] = [(0.0 : Float), l, iw - r, iw]
  let sy : Array[Float] = [(0.0 : Float), t, ih - b, ih]
  let dx : Array[Float] = [dst.x, dst.x + l, dst.right() - r, dst.right()]
  let dy : Array[Float] = [dst.y, dst.y + t, dst.bottom() - b, dst.bottom()]
  for row = 0; row < 3; row = row + 1 {
    for col = 0; col < 3; col = col + 1 {
      let sw = sx[col + 1] - sx[col]
      let sh = sy[row + 1] - sy[row]
      let dw = dx[col + 1] - dx[col]
      let dh = dy[row + 1] - dy[row]
      if sw > (0.0 : Float) && sh > (0.0 : Float) && dw > (0.0 : Float) && dh > (0.0 : Float) {
        self.draw_image_rect(
          image,
          Rect::new(sx[col], sy[row], sw, sh),
          Rect::new(dx[col], dy[row], dw, dh),
          paint~,
        )
      }
    }
  }
}

///|
// Draw many sub-rects of one image in a single call.
pub fn Canvas::draw_atlas(
  self : Canvas,
  image : Image2D,
  entries : Array[(Rect, Rect)],
  paint? : Paint = Paint::new(),
) -> Unit {
  for e in entries {
    self.draw_image_rect(image, e.0, e.1, paint~)
  }
}

///|
pub fn Canvas::draw_paragraph(
  self : Canvas,
  paragraph : Paragraph,
  pos : Point,
) -> Unit {
  self.expand_bounds(Rect::new(pos.x, pos.y, paragraph.width(), paragraph.height()))
  self.ops.push(DrawOp::DrawParagraph(paragraph, pos))
}

///|
pub fn Canvas::draw_display_list(self : Canvas, dl : DisplayList) -> Unit {
  if dl.ops.length() == 0 {
    return
  }
  self.expand_bounds(dl.bounds)
  self.ops.push(DrawOp::DrawDisplayList(dl))
}

///|
pub fn Canvas::finish(self : Canvas) -> DisplayList {
  let ops_arr = FixedArray::makei(self.ops.length(), fn(i) { self.ops[i] })
  { ops: ops_arr, bounds: self.bounds }
}
