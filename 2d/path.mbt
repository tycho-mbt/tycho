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
let g_next_path_revision : Ref[Int] = Ref(1)

///|
fn alloc_path_revision() -> Int {
  let r = g_next_path_revision.val
  g_next_path_revision.val = r + 1
  r
}

///|
pub struct Path {
  priv id : UInt64
  priv revision : Int
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
// Monotonic revision, useful for invalidating geometry caches when a path is
// rebuilt or transformed.
pub fn Path::revision(self : Path) -> Int {
  self.revision
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
  priv mut cur_x : Float
  priv mut cur_y : Float
  priv mut start_x : Float
  priv mut start_y : Float
  priv mut has_cur : Bool
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
    cur_x: (0.0 : Float),
    cur_y: (0.0 : Float),
    start_x: (0.0 : Float),
    start_y: (0.0 : Float),
    has_cur: false,
  }
}

///|
pub fn PathBuilder::current_point(self : PathBuilder) -> Point? {
  if self.has_cur {
    Some({ x: self.cur_x, y: self.cur_y })
  } else {
    None
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
  self.cur_x = x
  self.cur_y = y
  self.start_x = x
  self.start_y = y
  self.has_cur = true
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
  self.cur_x = x
  self.cur_y = y
  self.has_cur = true
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
  self.cur_x = x
  self.cur_y = y
  self.has_cur = true
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
  self.cur_x = x
  self.cur_y = y
  self.has_cur = true
  self
}

///|
pub fn PathBuilder::close(self : PathBuilder) -> PathBuilder {
  self.verbs.push(PathVerb::Close)
  if self.has_cur {
    self.cur_x = self.start_x
    self.cur_y = self.start_y
  }
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
  let lim = @tmath.min_f(hw, hh)
  let tlx = @tmath.min_f(rr.tl, lim)
  let tly = @tmath.min_f(rr.tl_y, lim)
  let trx = @tmath.min_f(rr.tr, lim)
  let tr_y = @tmath.min_f(rr.tr_y, lim)
  let brx = @tmath.min_f(rr.br, lim)
  let br_y = @tmath.min_f(rr.br_y, lim)
  let blx = @tmath.min_f(rr.bl, lim)
  let bly = @tmath.min_f(rr.bl_y, lim)
  let k = (0.55228475 : Float) // 4/3 * (sqrt(2) - 1)
  let x0 = r.x
  let y0 = r.y
  let x1 = r.right()
  let y1 = r.bottom()
  let _ = self.move_to(x0 + tlx, y0)
  let _ = self.line_to(x1 - trx, y0)
  if trx > (0.0 : Float) && tr_y > (0.0 : Float) {
    let _ = self.cubic_to(x1 - trx * (1.0 - k), y0, x1, y0 + tr_y * (1.0 - k), x1, y0 + tr_y)
  }
  let _ = self.line_to(x1, y1 - br_y)
  if brx > (0.0 : Float) && br_y > (0.0 : Float) {
    let _ = self.cubic_to(x1, y1 - br_y * (1.0 - k), x1 - brx * (1.0 - k), y1, x1 - brx, y1)
  }
  let _ = self.line_to(x0 + blx, y1)
  if blx > (0.0 : Float) && bly > (0.0 : Float) {
    let _ = self.cubic_to(x0 + blx * (1.0 - k), y1, x0, y1 - bly * (1.0 - k), x0, y1 - bly)
  }
  let _ = self.line_to(x0, y0 + tly)
  if tlx > (0.0 : Float) && tly > (0.0 : Float) {
    let _ = self.cubic_to(x0, y0 + tly * (1.0 - k), x0 + tlx * (1.0 - k), y0, x0 + tlx, y0)
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
    revision: alloc_path_revision(),
    bounds,
    fill_rule,
    verbs: FixedArray::makei(self.verbs.length(), fn(i) { self.verbs[i] }),
    points: FixedArray::makei(self.points.length(), fn(i) { self.points[i] }),
  }
}

///|
const PI_F : Float = 3.141592653589793

///|
// Append an elliptical arc from `start_degrees` sweeping `sweep_degrees`.
// The arc is approximated by cubic Béziers (<= 90 degrees per segment).
pub fn PathBuilder::arc_to(
  self : PathBuilder,
  rect : Rect,
  start_degrees : Float,
  sweep_degrees : Float,
  force_move? : Bool = false,
) -> PathBuilder {
  if rect.is_empty() {
    return self
  }
  let sweep = if sweep_degrees > (360.0 : Float) {
    (360.0 : Float)
  } else if sweep_degrees < (-360.0 : Float) {
    (-360.0 : Float)
  } else {
    sweep_degrees
  }
  if @tmath.abs_f(sweep) < (1.0e-4 : Float) {
    return self
  }
  let cx = rect.x + rect.width * (0.5 : Float)
  let cy = rect.y + rect.height * (0.5 : Float)
  let rx = rect.width * (0.5 : Float)
  let ry = rect.height * (0.5 : Float)
  let a0 = start_degrees * (PI_F / (180.0 : Float))
  let a1 = a0 + sweep * (PI_F / (180.0 : Float))
  let p0x = cx + rx * @tmath.cos(a0)
  let p0y = cy + ry * @tmath.sin(a0)
  if force_move || !self.has_cur {
    let _ = self.move_to(p0x, p0y)
  } else {
    let _ = self.line_to(p0x, p0y)
  }
  let span = @tmath.abs_f(a1 - a0)
  let mut n_seg = (span / (PI_F * (0.5 : Float))).to_int()
  if Float::from_int(n_seg) * (PI_F * (0.5 : Float)) < span {
    n_seg = n_seg + 1
  }
  if n_seg < 1 {
    n_seg = 1
  }
  let delta = (a1 - a0) / Float::from_int(n_seg)
  let mut t0 = a0
  for _i = 0; _i < n_seg; _i = _i + 1 {
    let t1 = t0 + delta
    let k = ((4.0 : Float) / (3.0 : Float)) * @tmath.tan(delta * (0.25 : Float))
    let c1x = cx + rx * (@tmath.cos(t0) - k * @tmath.sin(t0))
    let c1y = cy + ry * (@tmath.sin(t0) + k * @tmath.cos(t0))
    let c2x = cx + rx * (@tmath.cos(t1) + k * @tmath.sin(t1))
    let c2y = cy + ry * (@tmath.sin(t1) - k * @tmath.cos(t1))
    let px = cx + rx * @tmath.cos(t1)
    let py = cy + ry * @tmath.sin(t1)
    let _ = self.cubic_to(c1x, c1y, c2x, c2y, px, py)
    t0 = t1
  }
  self
}

///|
// Convenience: arc that closes itself for a full ellipse.
pub fn PathBuilder::add_arc(
  self : PathBuilder,
  rect : Rect,
  start_degrees : Float,
  sweep_degrees : Float,
) -> PathBuilder {
  let _ = self.arc_to(rect, start_degrees, sweep_degrees, force_move=true)
  if @tmath.abs_f(sweep_degrees) >= (359.999 : Float) {
    self.close()
  } else {
    self
  }
}

///|
// Rational quadratic (conic) approximated by one quadratic, exact at t = 0.5.
pub fn PathBuilder::conic_to(
  self : PathBuilder,
  cx : Float,
  cy : Float,
  x : Float,
  y : Float,
  weight : Float,
) -> PathBuilder {
  let p0 = match self.current_point() {
    Some(p) => p
    None => {
      let _ = self.move_to((0.0 : Float), (0.0 : Float))
      Point::zero()
    }
  }
  let w = @tmath.max_f((0.0 : Float), weight)
  let denom = (2.0 : Float) + (2.0 : Float) * w
  if denom < (1.0e-6 : Float) {
    return self.quad_to(cx, cy, x, y)
  }
  let mx = (p0.x + (2.0 : Float) * w * cx + x) / denom
  let my = (p0.y + (2.0 : Float) * w * cy + y) / denom
  let qx = (2.0 : Float) * mx - (p0.x + x) * (0.5 : Float)
  let qy = (2.0 : Float) * my - (p0.y + y) * (0.5 : Float)
  self.quad_to(qx, qy, x, y)
}

///|
pub fn PathBuilder::add_path(self : PathBuilder, other : Path) -> PathBuilder {
  self.add_path_translated(other, (0.0 : Float), (0.0 : Float))
}

///|
pub fn PathBuilder::add_path_translated(
  self : PathBuilder,
  other : Path,
  dx : Float,
  dy : Float,
) -> PathBuilder {
  let mut pi = 0
  for v in other.verbs {
    match v {
      PathVerb::Move => {
        let x = other.points[pi] + dx
        let y = other.points[pi + 1] + dy
        pi = pi + 2
        let _ = self.move_to(x, y)
      }
      PathVerb::Line => {
        let x = other.points[pi] + dx
        let y = other.points[pi + 1] + dy
        pi = pi + 2
        let _ = self.line_to(x, y)
      }
      PathVerb::Quad => {
        let cx = other.points[pi] + dx
        let cy = other.points[pi + 1] + dy
        let x = other.points[pi + 2] + dx
        let y = other.points[pi + 3] + dy
        pi = pi + 4
        let _ = self.quad_to(cx, cy, x, y)
      }
      PathVerb::Cubic => {
        let c1x = other.points[pi] + dx
        let c1y = other.points[pi + 1] + dy
        let c2x = other.points[pi + 2] + dx
        let c2y = other.points[pi + 3] + dy
        let x = other.points[pi + 4] + dx
        let y = other.points[pi + 5] + dy
        pi = pi + 6
        let _ = self.cubic_to(c1x, c1y, c2x, c2y, x, y)
      }
      PathVerb::Close => {
        let _ = self.close()
      }
    }
  }
  self
}

///|
pub fn Path::transform(self : Path, m : Matrix3) -> Path {
  let n = self.points.length()
  let pts = FixedArray::make(n, (0.0 : Float))
  let mut i = 0
  while i + 1 < n {
    let p = m.map_point({ x: self.points[i], y: self.points[i + 1] })
    pts[i] = p.x
    pts[i + 1] = p.y
    i = i + 2
  }
  {
    id: alloc_path_id(),
    revision: alloc_path_revision(),
    bounds: m.map_rect(self.bounds),
    fill_rule: self.fill_rule,
    verbs: self.verbs,
    points: pts,
  }
}

///|
pub fn Path::translated(self : Path, dx : Float, dy : Float) -> Path {
  self.transform(Matrix3::translate(dx, dy))
}

///|
// Tight bounds of the flattened geometry (curve extrema included).
pub fn Path::compute_tight_bounds(
  self : Path,
  tolerance? : Float = (0.25 : Float),
) -> Rect {
  let contours = flatten_path_contours(self, Matrix3::identity(), tolerance~)
  let mut has = false
  let mut min_x = (0.0 : Float)
  let mut min_y = (0.0 : Float)
  let mut max_x = (0.0 : Float)
  let mut max_y = (0.0 : Float)
  for pair in contours {
    for p in pair.0 {
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
  }
  if !has {
    Rect::zero()
  } else {
    Rect::from_ltrb(min_x, min_y, max_x, max_y)
  }
}

///|
pub fn Path::contains(
  self : Path,
  x : Float,
  y : Float,
  fill_rule? : FillRule,
) -> Bool {
  let rule = match fill_rule {
    Some(r) => r
    None => self.fill_rule
  }
  let contours = flatten_path_contours(
    self,
    Matrix3::identity(),
    tolerance=(0.2 : Float),
  )
  let mut winding = 0
  let mut crossings = 0
  for pair in contours {
    let pts = pair.0
    let n = pts.length()
    if n < 2 {
      continue
    }
    for i = 0; i < n; i = i + 1 {
      let a = pts[i]
      let b = pts[(i + 1) % n]
      if a.y <= y {
        if b.y > y {
          let cross = (b.x - a.x) * (y - a.y) - (x - a.x) * (b.y - a.y)
          if cross > (0.0 : Float) {
            winding = winding + 1
            crossings = crossings + 1
          }
        }
      } else if b.y <= y {
        let cross = (b.x - a.x) * (y - a.y) - (x - a.x) * (b.y - a.y)
        if cross < (0.0 : Float) {
          winding = winding - 1
          crossings = crossings + 1
        }
      }
    }
  }
  match rule {
    FillRule::NonZero => winding != 0
    FillRule::EvenOdd => crossings % 2 == 1
  }
}

///|
pub struct PathMeasure {
  priv contours : Array[(Array[Point], Bool)]
  priv cum : Array[Array[Float]]
  priv total : Float
}

///|
pub fn PathMeasure::new(
  path : Path,
  force_closed? : Bool = false,
  tolerance? : Float = (0.25 : Float),
) -> PathMeasure {
  let raw = flatten_path_contours(path, Matrix3::identity(), tolerance~)
  let contours : Array[(Array[Point], Bool)] = []
  let cums : Array[Array[Float]] = []
  let mut total = (0.0 : Float)
  for pair in raw {
    let pts = pair.0
    let closed = pair.1 || force_closed
    if pts.length() < 2 {
      continue
    }
    let cum : Array[Float] = [(0.0 : Float)]
    let mut acc = (0.0 : Float)
    let mut i = 1
    while i < pts.length() {
      acc = acc + pts[i].distance_to(pts[i - 1])
      cum.push(acc)
      i = i + 1
    }
    if closed && pts[0].distance_to(pts[pts.length() - 1]) > (1.0e-4 : Float) {
      acc = acc + pts[pts.length() - 1].distance_to(pts[0])
      pts.push(pts[0])
      cum.push(acc)
    }
    total = total + acc
    contours.push((pts, closed))
    cums.push(cum)
  }
  { contours, cum: cums, total }
}

///|
pub fn Path::measure(
  self : Path,
  force_closed? : Bool = false,
  tolerance? : Float = (0.25 : Float),
) -> PathMeasure {
  PathMeasure::new(self, force_closed~, tolerance~)
}

///|
pub fn PathMeasure::length(self : PathMeasure) -> Float {
  self.total
}

///|
// Position and unit tangent at an arc-length distance from the start.
pub fn PathMeasure::pos_at(self : PathMeasure, distance : Float) -> (Point, Point)? {
  if self.total <= (0.0 : Float) {
    return None
  }
  let d = @tmath.clamp_f(distance, (0.0 : Float), self.total)
  let mut acc = (0.0 : Float)
  let last = self.contours.length() - 1
  for ci = 0; ci <= last; ci = ci + 1 {
    let cum = self.cum[ci]
    let seg_total = cum[cum.length() - 1]
    if d <= acc + seg_total || ci == last {
      let local_d = d - acc
      let pts = self.contours[ci].0
      let mut i = 1
      while i < cum.length() && cum[i] < local_d {
        i = i + 1
      }
      if i >= pts.length() {
        i = pts.length() - 1
      }
      let a = pts[i - 1]
      let b = pts[i]
      let seg = cum[i] - cum[i - 1]
      let t = if seg > (0.0 : Float) {
        @tmath.clamp_f((local_d - cum[i - 1]) / seg, (0.0 : Float), (1.0 : Float))
      } else {
        (0.0 : Float)
      }
      let p = a.lerp(b, t)
      let dx = b.x - a.x
      let dy = b.y - a.y
      let len = @tmath.sqrt(dx * dx + dy * dy)
      let dir = if len > (1.0e-6 : Float) {
        { x: dx / len, y: dy / len }
      } else {
        { x: (1.0 : Float), y: (0.0 : Float) }
      }
      return Some((p, dir))
    }
    acc = acc + seg_total
  }
  None
}

///|
// Polyline approximation of a sub-range, sampled every ~2 px.
pub fn PathMeasure::segment(
  self : PathMeasure,
  start : Float,
  stop : Float,
) -> Path {
  let d0 = @tmath.clamp_f(start, (0.0 : Float), self.total)
  let d1 = @tmath.clamp_f(stop, (0.0 : Float), self.total)
  let b = PathBuilder::new()
  if d1 <= d0 {
    return b.build()
  }
  match self.pos_at(d0) {
    Some((p, _)) => {
      let _ = b.move_to(p.x, p.y)
    }
    None => ()
  }
  let span = d1 - d0
  let mut n = (span / (2.0 : Float)).to_int()
  if Float::from_int(n) * (2.0 : Float) < span {
    n = n + 1
  }
  if n < 1 {
    n = 1
  }
  for i = 1; i <= n; i = i + 1 {
    let d = d0 + span * Float::from_int(i) / Float::from_int(n)
    match self.pos_at(d) {
      Some((p, _)) => {
        let _ = b.line_to(p.x, p.y)
      }
      None => ()
    }
  }
  b.build()
}

///|
// Split the path into dashes following an alternating on/off pattern (in
// path-space units). The result is an open polyline path intended for stroke.
pub fn Path::dashed(self : Path, pattern : Array[Float], phase? : Float = 0.0) -> Path {
  let n = pattern.length()
  if n == 0 {
    return self
  }
  let mut total = (0.0 : Float)
  for v in pattern {
    total = total + @tmath.max_f(v, (1.0e-3 : Float))
  }
  if total <= (0.0 : Float) {
    return self
  }
  let mut ph = phase
  while ph < (0.0 : Float) {
    ph = ph + total
  }
  while ph >= total {
    ph = ph - total
  }
  let mut idx = 0
  let mut remaining = @tmath.max_f(pattern[0], (1.0e-3 : Float))
  let mut on = true
  while ph > (0.0 : Float) {
    if ph >= remaining {
      ph = ph - remaining
      idx = (idx + 1) % n
      remaining = @tmath.max_f(pattern[idx], (1.0e-3 : Float))
      on = !on
    } else {
      remaining = remaining - ph
      ph = (0.0 : Float)
    }
  }
  let b = PathBuilder::new()
  let contours = flatten_path_contours(
    self,
    Matrix3::identity(),
    tolerance=(0.25 : Float),
  )
  for pair in contours {
    let pts = pair.0
    let closed = pair.1
    let m = pts.length()
    if m < 2 {
      continue
    }
    let seg_count = if closed { m } else { m - 1 }
    let mut dash_started = false
    for i = 0; i < seg_count; i = i + 1 {
      let a = pts[i]
      let bb = pts[(i + 1) % m]
      let seg_len = a.distance_to(bb)
      if seg_len <= (1.0e-6 : Float) {
        continue
      }
      let mut t0 = (0.0 : Float)
      while t0 < seg_len - (1.0e-6 : Float) {
        let step = @tmath.min_f(remaining, seg_len - t0)
        if on && step > (1.0e-6 : Float) {
          let p0 = a.lerp(bb, t0 / seg_len)
          let p1 = a.lerp(bb, (t0 + step) / seg_len)
          if !dash_started {
            let _ = b.move_to(p0.x, p0.y)
            dash_started = true
          } else {
            let _ = b.line_to(p0.x, p0.y)
          }
          let _ = b.line_to(p1.x, p1.y)
        }
        t0 = t0 + step
        remaining = remaining - step
        if remaining <= (1.0e-6 : Float) {
          idx = (idx + 1) % n
          remaining = @tmath.max_f(pattern[idx], (1.0e-3 : Float))
          on = !on
          dash_started = false
        }
      }
    }
  }
  b.build(fill_rule=self.fill_rule)
}
