// Boolean path operations. This first implementation handles a convex clip
// polygon exactly (Sutherland-Hodgman) and represents Union as same-winding
// contours under NonZero. Non-convex clips return None; callers can fall back
// to coverage compositing.

///|
#derive(Eq, Debug)
pub(all) enum PathOp {
  Union
  Intersect
  Difference
  Xor
}

///|
fn polygon_signed_area(pts : Array[Point]) -> Float {
  let n = pts.length()
  let mut acc = (0.0 : Float)
  for i = 0; i < n; i = i + 1 {
    let p = pts[i]
    let q = pts[(i + 1) % n]
    acc = acc + p.x * q.y - q.x * p.y
  }
  acc * (0.5 : Float)
}

///|
fn polygon_is_convex(pts : Array[Point]) -> Bool {
  let n = pts.length()
  if n < 3 {
    return false
  }
  let mut sign = 0
  for i = 0; i < n; i = i + 1 {
    let a = pts[i]
    let b = pts[(i + 1) % n]
    let c = pts[(i + 2) % n]
    let cross = (b.x - a.x) * (c.y - b.y) - (b.y - a.y) * (c.x - b.x)
    if @tmath.abs_f(cross) > (1.0e-6 : Float) {
      let s = if cross > (0.0 : Float) { 1 } else { -1 }
      if sign == 0 {
        sign = s
      } else if sign != s {
        return false
      }
    }
  }
  sign != 0
}

///|
fn edge_side(a : Point, b : Point, p : Point) -> Float {
  (b.x - a.x) * (p.y - a.y) - (b.y - a.y) * (p.x - a.x)
}

///|
fn edge_intersection(p0 : Point, p1 : Point, a : Point, b : Point) -> Point {
  let d0 = edge_side(a, b, p0)
  let d1 = edge_side(a, b, p1)
  let denom = d0 - d1
  if @tmath.abs_f(denom) < (1.0e-9 : Float) {
    return p1
  }
  let t = d0 / denom
  {
    x: p0.x + (p1.x - p0.x) * t,
    y: p0.y + (p1.y - p0.y) * t,
  }
}

///|
fn clip_polygon(
  subject : Array[Point],
  clip : Array[Point],
  keep_inside : Bool,
) -> Array[Point] {
  let n = clip.length()
  if n < 3 || subject.length() < 3 {
    return []
  }
  let mut output = subject
  for i = 0; i < n; i = i + 1 {
    if output.length() == 0 {
      break
    }
    let a = clip[i]
    let b = clip[(i + 1) % n]
    let input = output
    output = []
    let mut prev = input[input.length() - 1]
    let prev_side = edge_side(a, b, prev)
    let mut prev_in = if keep_inside {
      prev_side >= (-1.0e-6 : Float)
    } else {
      prev_side <= (1.0e-6 : Float)
    }
    for cur in input {
      let cur_side = edge_side(a, b, cur)
      let cur_in = if keep_inside {
        cur_side >= (-1.0e-6 : Float)
      } else {
        cur_side <= (1.0e-6 : Float)
      }
      if cur_in {
        if !prev_in {
          output.push(edge_intersection(prev, cur, a, b))
        }
        output.push(cur)
      } else if prev_in {
        output.push(edge_intersection(prev, cur, a, b))
      }
      prev = cur
      prev_in = cur_in
    }
  }
  output
}

///|
fn add_polygon(b : PathBuilder, pts : Array[Point]) -> Unit {
  let n = pts.length()
  if n < 3 {
    return
  }
  let _ = b.move_to(pts[0].x, pts[0].y)
  for i = 1; i < n; i = i + 1 {
    let _ = b.line_to(pts[i].x, pts[i].y)
  }
  let _ = b.close()
}

///|
fn path_polygons(path : Path) -> Array[Array[Point]] {
  let out : Array[Array[Point]] = []
  let contours = flatten_path_contours(
    path,
    Matrix3::identity(),
    tolerance=(0.5 : Float),
  )
  for pair in contours {
    let pts = pair.0
    // Drop a duplicated closing point and degenerate contours.
    if pts.length() > 1 && pts[0].distance_to(pts[pts.length() - 1]) < (1.0e-5 : Float) {
      let _ = pts.pop()
    }
    if pts.length() >= 3 {
      out.push(pts)
    }
  }
  out
}

///|
// Boolean op with a convex `other`. Returns None when `other` is not convex
// or the result is unsupported; `Path::op` then falls back to scanline
// compositing.
fn Path::op_convex(self : Path, other : Path, op : PathOp) -> Path? {
  let a_polys = path_polygons(self)
  let b_polys = path_polygons(other)
  if a_polys.length() == 0 || b_polys.length() != 1 {
    return None
  }
  if op != PathOp::Union && a_polys.length() != 1 {
    return None
  }
  let b_raw = b_polys[0]
  if !polygon_is_convex(b_raw) {
    return None
  }
  let b = if polygon_signed_area(b_raw) < (0.0 : Float) {
    let rev : Array[Point] = []
    for i = b_raw.length() - 1; i >= 0; i = i - 1 {
      rev.push(b_raw[i])
    }
    rev
  } else {
    b_raw
  }
  match op {
    PathOp::Union => {
      let pb = PathBuilder::new()
      for poly in a_polys {
        if polygon_signed_area(poly) < (0.0 : Float) {
          let rev : Array[Point] = []
          for i = poly.length() - 1; i >= 0; i = i - 1 {
            rev.push(poly[i])
          }
          add_polygon(pb, rev)
        } else {
          add_polygon(pb, poly)
        }
      }
      add_polygon(pb, b)
      Some(pb.build(fill_rule=FillRule::NonZero))
    }
    PathOp::Intersect => {
      let pb = PathBuilder::new()
      for poly in a_polys {
        add_polygon(pb, clip_polygon(poly, b, true))
      }
      Some(pb.build())
    }
    PathOp::Difference => {
      // A - B = A with the convex intersection punched out (EvenOdd hole).
      let pb = PathBuilder::new()
      for poly in a_polys {
        add_polygon(pb, poly)
        add_polygon(pb, clip_polygon(poly, b, true))
      }
      Some(pb.build(fill_rule=FillRule::EvenOdd))
    }
    PathOp::Xor => {
      // EvenOdd winding over both contours is exactly the symmetric
      // difference: overlaps cross twice and cancel.
      let pb = PathBuilder::new()
      for poly in a_polys {
        add_polygon(pb, poly)
      }
      add_polygon(pb, b)
      Some(pb.build(fill_rule=FillRule::EvenOdd))
    }
  }
}

///|
fn interval_sort(xs : Array[Float], dirs : Array[Int]) -> Unit {
  for i = 1; i < xs.length(); i = i + 1 {
    let kx = xs[i]
    let kd = dirs[i]
    let mut j = i - 1
    while j >= 0 && xs[j] > kx {
      xs[j + 1] = xs[j]
      dirs[j + 1] = dirs[j]
      j = j - 1
    }
    xs[j + 1] = kx
    dirs[j + 1] = kd
  }
}

///|
fn scanline_intervals(
  polys : Array[Array[Point]],
  y : Float,
  rule : FillRule,
) -> Array[(Float, Float)] {
  let xs : Array[Float] = []
  let dirs : Array[Int] = []
  for pts in polys {
    let n = pts.length()
    if n < 2 {
      continue
    }
    for i = 0; i < n; i = i + 1 {
      let a = pts[i]
      let b = pts[(i + 1) % n]
      let up = a.y <= y && b.y > y
      let dn = b.y <= y && a.y > y
      if up || dn {
        let t = (y - a.y) / (b.y - a.y)
        xs.push(a.x + (b.x - a.x) * t)
        dirs.push(if up { 1 } else { -1 })
      }
    }
  }
  interval_sort(xs, dirs)
  let out : Array[(Float, Float)] = []
  match rule {
    FillRule::EvenOdd => {
      let mut i = 0
      while i + 1 < xs.length() {
        if xs[i + 1] - xs[i] > (1.0e-5 : Float) {
          out.push((xs[i], xs[i + 1]))
        }
        i = i + 2
      }
    }
    FillRule::NonZero => {
      let mut w = 0
      let mut start = (0.0 : Float)
      for i = 0; i < xs.length(); i = i + 1 {
        let before = w
        w = w + dirs[i]
        if before == 0 && w != 0 {
          start = xs[i]
        } else if before != 0 && w == 0 {
          if xs[i] - start > (1.0e-5 : Float) {
            out.push((start, xs[i]))
          }
        }
      }
    }
  }
  out
}

///|
fn merge_intervals(
  a : Array[(Float, Float)],
  b : Array[(Float, Float)],
) -> Array[(Float, Float)] {
  let all : Array[(Float, Float)] = []
  for v in a {
    all.push(v)
  }
  for v in b {
    all.push(v)
  }
  for i = 1; i < all.length(); i = i + 1 {
    let kv = all[i]
    let mut j = i - 1
    while j >= 0 && all[j].0 > kv.0 {
      all[j + 1] = all[j]
      j = j - 1
    }
    all[j + 1] = kv
  }
  let out : Array[(Float, Float)] = []
  for v in all {
    let n = out.length()
    if n > 0 && v.0 <= out[n - 1].1 + (1.0e-4 : Float) {
      let last = out[n - 1]
      out[n - 1] = (last.0, @tmath.max_f(last.1, v.1))
    } else {
      out.push(v)
    }
  }
  out
}

///|
fn intersect_intervals(
  a : Array[(Float, Float)],
  b : Array[(Float, Float)],
) -> Array[(Float, Float)] {
  let out : Array[(Float, Float)] = []
  for x in a {
    for y in b {
      let lo = @tmath.max_f(x.0, y.0)
      let hi = @tmath.min_f(x.1, y.1)
      if hi - lo > (1.0e-5 : Float) {
        out.push((lo, hi))
      }
    }
  }
  out
}

///|
fn subtract_intervals(
  a : Array[(Float, Float)],
  b : Array[(Float, Float)],
) -> Array[(Float, Float)] {
  let out : Array[(Float, Float)] = []
  for x in a {
    let mut pieces : Array[(Float, Float)] = [x]
    for y in b {
      let next : Array[(Float, Float)] = []
      for p in pieces {
        if y.1 <= p.0 || y.0 >= p.1 {
          next.push(p)
        } else {
          if p.0 < y.0 {
            next.push((p.0, y.0))
          }
          if y.1 < p.1 {
            next.push((y.1, p.1))
          }
        }
      }
      pieces = next
    }
    for p in pieces {
      if p.1 - p.0 > (1.0e-5 : Float) {
        out.push(p)
      }
    }
  }
  out
}

///|
fn combine_intervals(
  a : Array[(Float, Float)],
  b : Array[(Float, Float)],
  op : PathOp,
) -> Array[(Float, Float)] {
  match op {
    PathOp::Union => merge_intervals(a, b)
    PathOp::Intersect => intersect_intervals(a, b)
    PathOp::Difference => subtract_intervals(a, b)
    PathOp::Xor => merge_intervals(subtract_intervals(a, b), subtract_intervals(b, a))
  }
}

///|
// Coverage-compositing fallback: scanline intervals combined per op, emitted
// as half-pixel-tall strips. Works for concave/self-intersecting paths and
// holes, at the cost of a polygonal (stair-stepped) result.
fn scanline_op(
  a : Array[Array[Point]],
  b : Array[Array[Point]],
  rule_a : FillRule,
  rule_b : FillRule,
  op : PathOp,
) -> Path? {
  let mut has = false
  let mut min_x = (1.0e30 : Float)
  let mut min_y = (1.0e30 : Float)
  let mut max_x = (-1.0e30 : Float)
  let mut max_y = (-1.0e30 : Float)
  for polys in [a, b] {
    for pts in polys {
      for p in pts {
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
  }
  if !has {
    return Some(PathBuilder::new().build())
  }
  if max_x - min_x > (4096.0 : Float) || max_y - min_y > (4096.0 : Float) {
    return None
  }
  let step = (0.5 : Float)
  let pb = PathBuilder::new()
  let mut rects = 0
  let mut y = (min_y / step).floor() * step + step * (0.5 : Float)
  while y < max_y {
    let ia = scanline_intervals(a, y, rule_a)
    let ib = scanline_intervals(b, y, rule_b)
    let out = combine_intervals(ia, ib, op)
    for v in out {
      if v.1 - v.0 > (1.0e-4 : Float) {
        let _ = pb.add_rect(Rect::new(v.0, y - step * (0.5 : Float), v.1 - v.0, step))
        rects = rects + 1
        if rects > 20000 {
          return None
        }
      }
    }
    y = y + step
  }
  Some(pb.build(fill_rule=FillRule::EvenOdd))
}

///|
// Boolean op. Convex clips use exact clipping; anything else falls back to
// scanline coverage compositing.
pub fn Path::op(self : Path, other : Path, op : PathOp) -> Path? {
  match self.op_convex(other, op) {
    Some(p) => Some(p)
    None => {
      let a = path_polygons(self)
      let b = path_polygons(other)
      scanline_op(a, b, self.fill_rule(), other.fill_rule(), op)
    }
  }
}
