// Vector path builder and immutable cached Path (inspired by SkPathBuilder / SkPath).

///|
#derive(Eq, Debug)
pub(all) enum FillRule {
  NonZero
  EvenOdd
}

///|
#derive(Eq, Debug)
pub(all) enum PathVerb {
  Move
  Line
  Quad
  Cubic
  Close
}

///|
let g_next_path_id : Ref[UInt64] = Ref((1 : UInt64))

///|
fn alloc_path_id() -> UInt64 {
  let id = g_next_path_id.val
  g_next_path_id.val = id + (1 : UInt64)
  id
}

///|
pub struct Path {
  priv id : UInt64
  priv bounds : Rect
  priv fill_rule : FillRule
  priv verbs : FixedArray[PathVerb]
  priv points : FixedArray[Float]
}

///|
pub fn Path::id(self : Path) -> UInt64 {
  self.id
}

///|
pub fn Path::bounds(self : Path) -> Rect {
  self.bounds
}

///|
pub fn Path::fill_rule(self : Path) -> FillRule {
  self.fill_rule
}

///|
pub fn Path::is_empty(self : Path) -> Bool {
  self.verbs.length() == 0
}

///|
pub struct PathBuilder {
  priv verbs : Array[PathVerb]
  priv points : Array[Float]
  priv mut has_pts : Bool
  priv mut min_x : Float
  priv mut min_y : Float
  priv mut max_x : Float
  priv mut max_y : Float
}

///|
pub fn PathBuilder::new() -> PathBuilder {
  {
    verbs: [],
    points: [],
    has_pts: false,
    min_x: (0.0 : Float),
    min_y: (0.0 : Float),
    max_x: (0.0 : Float),
    max_y: (0.0 : Float),
  }
}

///|
fn PathBuilder::record_pt(self : PathBuilder, x : Float, y : Float) -> Unit {
  if !self.has_pts {
    self.has_pts = true
    self.min_x = x
    self.max_x = x
    self.min_y = y
    self.max_y = y
  } else {
    if x < self.min_x { self.min_x = x }
    if x > self.max_x { self.max_x = x }
    if y < self.min_y { self.min_y = y }
    if y > self.max_y { self.max_y = y }
  }
  self.points.push(x)
  self.points.push(y)
}

///|
pub fn PathBuilder::move_to(self : PathBuilder, x : Float, y : Float) -> PathBuilder {
  self.verbs.push(PathVerb::Move)
  self.record_pt(x, y)
  self
}

///|
pub fn PathBuilder::line_to(self : PathBuilder, x : Float, y : Float) -> PathBuilder {
  if self.verbs.length() == 0 {
    let _ = self.move_to(x, y)
    return self
  }
  self.verbs.push(PathVerb::Line)
  self.record_pt(x, y)
  self
}

///|
pub fn PathBuilder::quad_to(
  self : PathBuilder,
  cx : Float,
  cy : Float,
  x : Float,
  y : Float,
) -> PathBuilder {
  if self.verbs.length() == 0 {
    let _ = self.move_to((0.0 : Float), (0.0 : Float))
  }
  self.verbs.push(PathVerb::Quad)
  self.record_pt(cx, cy)
  self.record_pt(x, y)
  self
}

///|
pub fn PathBuilder::cubic_to(
  self : PathBuilder,
  c1x : Float,
  c1y : Float,
  c2x : Float,
  c2y : Float,
  x : Float,
  y : Float,
) -> PathBuilder {
  if self.verbs.length() == 0 {
    let _ = self.move_to((0.0 : Float), (0.0 : Float))
  }
  self.verbs.push(PathVerb::Cubic)
  self.record_pt(c1x, c1y)
  self.record_pt(c2x, c2y)
  self.record_pt(x, y)
  self
}

///|
pub fn PathBuilder::close(self : PathBuilder) -> PathBuilder {
  self.verbs.push(PathVerb::Close)
  self
}

///|
pub fn PathBuilder::add_rect(self : PathBuilder, r : Rect) -> PathBuilder {
  if r.is_empty() {
    return self
  }
  let _ = self.move_to(r.x, r.y)
  let _ = self.line_to(r.right(), r.y)
  let _ = self.line_to(r.right(), r.bottom())
  let _ = self.line_to(r.x, r.bottom())
  self.close()
}

///|
pub fn PathBuilder::add_rrect(self : PathBuilder, rr : RRect) -> PathBuilder {
  let r = rr.rect
  if r.is_empty() {
    return self
  }
  if rr.is_rect() {
    return self.add_rect(r)
  }
  let hw = r.width * (0.5 : Float)
  let hh = r.height * (0.5 : Float)
  let lim = min_f(hw, hh)
  let tl = min_f(rr.tl, lim)
  let tr = min_f(rr.tr, lim)
  let br = min_f(rr.br, lim)
  let bl = min_f(rr.bl, lim)
  let k = (0.55228475 : Float) // 4/3 * (sqrt(2) - 1)
  let x0 = r.x
  let y0 = r.y
  let x1 = r.right()
  let y1 = r.bottom()
  let _ = self.move_to(x0 + tl, y0)
  let _ = self.line_to(x1 - tr, y0)
  if tr > (0.0 : Float) {
    let _ = self.cubic_to(x1 - tr * (1.0 - k), y0, x1, y0 + tr * (1.0 - k), x1, y0 + tr)
  }
  let _ = self.line_to(x1, y1 - br)
  if br > (0.0 : Float) {
    let _ = self.cubic_to(x1, y1 - br * (1.0 - k), x1 - br * (1.0 - k), y1, x1 - br, y1)
  }
  let _ = self.line_to(x0 + bl, y1)
  if bl > (0.0 : Float) {
    let _ = self.cubic_to(x0 + bl * (1.0 - k), y1, x0, y1 - bl * (1.0 - k), x0, y1 - bl)
  }
  let _ = self.line_to(x0, y0 + tl)
  if tl > (0.0 : Float) {
    let _ = self.cubic_to(x0, y0 + tl * (1.0 - k), x0 + tl * (1.0 - k), y0, x0 + tl, y0)
  }
  self.close()
}

///|
pub fn PathBuilder::add_oval(self : PathBuilder, r : Rect) -> PathBuilder {
  if r.is_empty() {
    return self
  }
  let cx = r.x + r.width * (0.5 : Float)
  let cy = r.y + r.height * (0.5 : Float)
  let rx = r.width * (0.5 : Float)
  let ry = r.height * (0.5 : Float)
  let kx = rx * (0.55228475 : Float)
  let ky = ry * (0.55228475 : Float)
  let _ = self.move_to(cx, r.y)
  let _ = self.cubic_to(cx + kx, r.y, r.right(), cy - ky, r.right(), cy)
  let _ = self.cubic_to(r.right(), cy + ky, cx + kx, r.bottom(), cx, r.bottom())
  let _ = self.cubic_to(cx - kx, r.bottom(), r.x, cy + ky, r.x, cy)
  let _ = self.cubic_to(r.x, cy - ky, cx - kx, r.y, cx, r.y)
  self.close()
}

///|
pub fn PathBuilder::add_circle(
  self : PathBuilder,
  cx : Float,
  cy : Float,
  radius : Float,
) -> PathBuilder {
  if radius <= (0.0 : Float) {
    return self
  }
  self.add_oval(
    Rect::new(cx - radius, cy - radius, radius * (2.0 : Float), radius * (2.0 : Float)),
  )
}

///|
pub fn PathBuilder::build(
  self : PathBuilder,
  fill_rule? : FillRule = FillRule::NonZero,
) -> Path {
  let bounds = if self.has_pts {
    Rect::from_ltrb(self.min_x, self.min_y, self.max_x, self.max_y)
  } else {
    Rect::zero()
  }
  {
    id: alloc_path_id(),
    bounds,
    fill_rule,
    verbs: FixedArray::makei(self.verbs.length(), fn(i) { self.verbs[i] }),
    points: FixedArray::makei(self.points.length(), fn(i) { self.points[i] }),
  }
}
