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
// Paint-level filters apply per draw: wrap the draw in a single-op layer so
// the layer composite performs the blur/color-matrix. Returns the paint to use
// for the inner draw and whether a matching restore is required.
fn Canvas::begin_filtered(
  self : Canvas,
  bounds : Rect,
  paint : Paint,
) -> (Paint, Bool) {
  let has = match (paint.color_filter, paint.mask_filter) {
    (None, None) => false
    _ => true
  }
  if !has {
    return (paint, false)
  }
  self.expand_bounds(bounds)
  let _ = self.save_layer(bounds=Some(bounds), paint=paint)
  ({ ..paint, color_filter: None, mask_filter: None }, true)
}

///|
fn Canvas::end_filtered(self : Canvas, layered : Bool) -> Unit {
  if layered {
    self.restore()
  }
}

///|
pub fn Canvas::draw_rect(self : Canvas, rect : Rect, paint : Paint) -> Unit {
  let (p, layered) = self.begin_filtered(rect, paint)
  self.expand_bounds(rect)
  self.ops.push(DrawOp::DrawRect(rect, p))
  self.end_filtered(layered)
}

///|
pub fn Canvas::draw_rrect(self : Canvas, rrect : RRect, paint : Paint) -> Unit {
  let pad = if paint.style == PaintStyle::Fill {
    (0.0 : Float)
  } else {
    paint.stroke_width * (0.5 : Float)
  }
  let bounds = rrect.rect.inflate(pad)
  let (p, layered) = self.begin_filtered(bounds, paint)
  self.expand_bounds(rrect.rect)
  self.ops.push(DrawOp::DrawRRect(rrect, p))
  self.end_filtered(layered)
}

///|
pub fn Canvas::draw_circle(
  self : Canvas,
  center : Point,
  radius : Float,
  paint : Paint,
) -> Unit {
  let d = radius * (2.0 : Float)
  let bounds = Rect::new(center.x - radius, center.y - radius, d, d)
  let (p, layered) = self.begin_filtered(bounds, paint)
  self.expand_bounds(bounds)
  self.ops.push(DrawOp::DrawCircle(center, radius, p))
  self.end_filtered(layered)
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
  let (p, layered) = self.begin_filtered(r, paint)
  self.expand_bounds(r)
  self.ops.push(DrawOp::DrawLine(p0, p1, p))
  self.end_filtered(layered)
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
  let bounds = path.bounds().inflate(pad)
  let (p, layered) = self.begin_filtered(bounds, paint)
  self.expand_bounds(bounds)
  self.ops.push(DrawOp::DrawPath(path, p))
  self.end_filtered(layered)
}

///|
// Drop shadow for an arbitrary path: offset the path, draw it into a layer,
// and blur the layer on composite.
pub fn Canvas::draw_path_shadow(
  self : Canvas,
  path : Path,
  dx : Float,
  dy : Float,
  blur : Float,
  color : Color,
) -> Unit {
  let shadow_path = path.translated(dx, dy)
  if blur <= (0.0 : Float) {
    self.draw_path(shadow_path, Paint::fill(color))
    return
  }
  let b = shadow_path.bounds().inflate(blur + (2.0 : Float))
  self.expand_bounds(b)
  let _ = self.save_layer(
    bounds=Some(b),
    paint=Paint::new(mask_filter=Some(MaskFilter::Blur(blur, blur))),
  )
  self.draw_path(shadow_path, Paint::fill(color))
  self.restore()
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
  let (p, layered) = self.begin_filtered(dst, paint)
  self.expand_bounds(dst)
  self.ops.push(DrawOp::DrawImage(image, src, dst, p))
  self.end_filtered(layered)
}

///|
// Emit many sub-rects of one image as a single indexed mesh (one draw).
fn Canvas::draw_image_quads(
  self : Canvas,
  image : Image2D,
  quads : Array[(Rect, Rect)],
  paint : Paint,
) -> Unit {
  if quads.length() == 0 {
    return
  }
  let iw = Float::from_int(image.width)
  let ih = Float::from_int(image.height)
  if iw <= (0.0 : Float) || ih <= (0.0 : Float) {
    return
  }
  let verts : Array[Vertex2D] = []
  let idx : Array[Int] = []
  for q in quads {
    let src = q.0
    let dst = q.1
    if dst.width <= (0.0 : Float) || dst.height <= (0.0 : Float) {
      continue
    }
    let u0 = src.x / iw
    let v0 = src.y / ih
    let u1 = src.right() / iw
    let v1 = src.bottom() / ih
    let base = verts.length()
    verts.push(Vertex2D::new(dst.x, dst.y, u=u0, v=v0))
    verts.push(Vertex2D::new(dst.right(), dst.y, u=u1, v=v0))
    verts.push(Vertex2D::new(dst.right(), dst.bottom(), u=u1, v=v1))
    verts.push(Vertex2D::new(dst.x, dst.bottom(), u=u0, v=v1))
    idx.push(base)
    idx.push(base + 1)
    idx.push(base + 2)
    idx.push(base)
    idx.push(base + 2)
    idx.push(base + 3)
  }
  if verts.length() == 0 {
    return
  }
  self.draw_vertices(verts, idx, paint~, image=Some(image))
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
  let quads : Array[(Rect, Rect)] = []
  for row = 0; row < 3; row = row + 1 {
    for col = 0; col < 3; col = col + 1 {
      let sw = sx[col + 1] - sx[col]
      let sh = sy[row + 1] - sy[row]
      let dw = dx[col + 1] - dx[col]
      let dh = dy[row + 1] - dy[row]
      if sw > (0.0 : Float) &&
        sh > (0.0 : Float) &&
        dw > (0.0 : Float) &&
        dh > (0.0 : Float) {
        quads.push((
          Rect::new(sx[col], sy[row], sw, sh),
          Rect::new(dx[col], dy[row], dw, dh),
        ))
      }
    }
  }
  self.draw_image_quads(image, quads, paint)
}

///|
// Draw many sub-rects of one image as a single indexed mesh.
pub fn Canvas::draw_atlas(
  self : Canvas,
  image : Image2D,
  entries : Array[(Rect, Rect)],
  paint? : Paint = Paint::new(),
) -> Unit {
  self.draw_image_quads(image, entries, paint)
}

///|
// Draw an indexed triangle mesh. Vertex positions are in local space and
// transformed by the current matrix; `image` (optional) is sampled with the
// per-vertex UVs in [0, 1] and multiplied by the vertex color.
pub fn Canvas::draw_vertices(
  self : Canvas,
  vertices : Array[Vertex2D],
  indices : Array[Int],
  paint? : Paint = Paint::new(),
  image? : Image2D? = None,
) -> Unit {
  if vertices.length() == 0 {
    return
  }
  let mut has = false
  let mut min_x = (0.0 : Float)
  let mut min_y = (0.0 : Float)
  let mut max_x = (0.0 : Float)
  let mut max_y = (0.0 : Float)
  for v in vertices {
    let p = self.cur_transform.map_point({ x: v.x, y: v.y })
    if !has {
      has = true
      min_x = p.x
      max_x = p.x
      min_y = p.y
      max_y = p.y
    } else {
      if p.x < min_x {
        min_x = p.x
      }
      if p.x > max_x {
        max_x = p.x
      }
      if p.y < min_y {
        min_y = p.y
      }
      if p.y > max_y {
        max_y = p.y
      }
    }
  }
  if !has {
    return
  }
  let bounds = Rect::from_ltrb(min_x, min_y, max_x, max_y)
  let (p, layered) = self.begin_filtered(bounds, paint)
  self.expand_bounds(bounds)
  self.ops.push(DrawOp::DrawVertices(vertices, indices, p, image))
  self.end_filtered(layered)
}

///|
pub fn Canvas::draw_paragraph(
  self : Canvas,
  paragraph : Paragraph,
  pos : Point,
) -> Unit {
  let bounds = Rect::new(pos.x, pos.y, paragraph.width(), paragraph.height())
  self.expand_bounds(bounds)
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
