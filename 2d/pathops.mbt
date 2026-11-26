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
// or the result is unsupported; callers may fall back to coverage compositing.
pub fn Path::op(self : Path, other : Path, op : PathOp) -> Path? {
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
