// Adaptive Bezier flattening, Stencil-then-Cover fan tessellation, and vector stroke expansion.

///|
fn flatten_quad(
  out : Array[Point],
  p0 : Point,
  p1 : Point,
  p2 : Point,
  tol_sq : Double,
  depth : Int,
) -> Unit {
  let mx = (p0.x + p2.x) * (0.5 : Float)
  let my = (p0.y + p2.y) * (0.5 : Float)
  let dx = (p1.x - mx).to_double()
  let dy = (p1.y - my).to_double()
  if depth >= 7 || dx * dx + dy * dy <= tol_sq {
    out.push(p2)
    return
  }
  let p01 = p0.lerp(p1, (0.5 : Float))
  let p12 = p1.lerp(p2, (0.5 : Float))
  let mid = p01.lerp(p12, (0.5 : Float))
  flatten_quad(out, p0, p01, mid, tol_sq, depth + 1)
  flatten_quad(out, mid, p12, p2, tol_sq, depth + 1)
}

///|
fn flatten_cubic(
  out : Array[Point],
  p0 : Point,
  p1 : Point,
  p2 : Point,
  p3 : Point,
  tol_sq : Double,
  depth : Int,
) -> Unit {
  let l1 = p0.lerp(p3, (1.0 : Float) / (3.0 : Float))
  let l2 = p0.lerp(p3, (2.0 : Float) / (3.0 : Float))
  let d1x = (p1.x - l1.x).to_double()
  let d1y = (p1.y - l1.y).to_double()
  let d2x = (p2.x - l2.x).to_double()
  let d2y = (p2.y - l2.y).to_double()
  let err = if d1x * d1x + d1y * d1y > d2x * d2x + d2y * d2y {
    d1x * d1x + d1y * d1y
  } else {
    d2x * d2x + d2y * d2y
  }
  if depth >= 7 || err <= tol_sq {
    out.push(p3)
    return
  }
  let p01 = p0.lerp(p1, (0.5 : Float))
  let p12 = p1.lerp(p2, (0.5 : Float))
  let p23 = p2.lerp(p3, (0.5 : Float))
  let p012 = p01.lerp(p12, (0.5 : Float))
  let p123 = p12.lerp(p23, (0.5 : Float))
  let mid = p012.lerp(p123, (0.5 : Float))
  flatten_cubic(out, p0, p01, p012, mid, tol_sq, depth + 1)
  flatten_cubic(out, mid, p123, p23, p3, tol_sq, depth + 1)
}

///|
pub fn flatten_path_contours(
  path : Path,
  xform : Matrix3,
  tolerance? : Float = (0.25 : Float),
) -> Array[(Array[Point], Bool)] {
  let contours : Array[(Array[Point], Bool)] = []
  let tol_sq = (tolerance * tolerance).to_double()
  let mut cur_pts : Array[Point] = []
  let mut cur_pt = Point::zero()
  let mut pi = 0
  let mut closed = false
  for v in path.verbs {
    match v {
      PathVerb::Move => {
        if cur_pts.length() > 0 {
          contours.push((cur_pts, closed))
          cur_pts = []
        }
        let pt = xform.map_point({ x: path.points[pi], y: path.points[pi + 1] })
        pi = pi + 2
        cur_pts.push(pt)
        cur_pt = pt
        closed = false
      }
      PathVerb::Line => {
        let pt = xform.map_point({ x: path.points[pi], y: path.points[pi + 1] })
        pi = pi + 2
        if pt.distance_to(cur_pt) > (1.0e-4 : Float) {
          cur_pts.push(pt)
          cur_pt = pt
        }
      }
      PathVerb::Quad => {
        let c = xform.map_point({ x: path.points[pi], y: path.points[pi + 1] })
        let e = xform.map_point({ x: path.points[pi + 2], y: path.points[pi + 3] })
        pi = pi + 4
        flatten_quad(cur_pts, cur_pt, c, e, tol_sq, 0)
        cur_pt = e
      }
      PathVerb::Cubic => {
        let c1 = xform.map_point({ x: path.points[pi], y: path.points[pi + 1] })
        let c2 = xform.map_point({ x: path.points[pi + 2], y: path.points[pi + 3] })
        let e = xform.map_point({ x: path.points[pi + 4], y: path.points[pi + 5] })
        pi = pi + 6
        flatten_cubic(cur_pts, cur_pt, c1, c2, e, tol_sq, 0)
        cur_pt = e
      }
      PathVerb::Close => {
        closed = true
        if cur_pts.length() > 1 && cur_pt.distance_to(cur_pts[0]) > (1.0e-4 : Float) {
          cur_pts.push(cur_pts[0])
          cur_pt = cur_pts[0]
        }
      }
    }
  }
  if cur_pts.length() > 0 {
    contours.push((cur_pts, closed))
  }
  contours
}

///|
// Generates screen-space vec2 triangles for Stencil-then-Cover (triangle fan per contour).
pub fn tessellate_fill_fan(
  path : Path,
  xform : Matrix3,
  tolerance? : Float = (0.25 : Float),
) -> (Array[Float], Rect) {
  let contours = flatten_path_contours(path, xform, tolerance~)
  let verts : Array[Float] = []
  let mut has_pts = false
  let mut min_x = (0.0 : Float)
  let mut min_y = (0.0 : Float)
  let mut max_x = (0.0 : Float)
  let mut max_y = (0.0 : Float)
  for pair in contours {
    let (pts, _) = pair
    if pts.length() < 3 {
      continue
    }
    let anchor = pts[0]
    for pt in pts {
      if !has_pts {
        has_pts = true
        min_x = pt.x
        max_x = pt.x
        min_y = pt.y
        max_y = pt.y
      } else {
        if pt.x < min_x { min_x = pt.x }
        if pt.x > max_x { max_x = pt.x }
        if pt.y < min_y { min_y = pt.y }
        if pt.y > max_y { max_y = pt.y }
      }
    }
    for i = 1; i + 1 < pts.length(); i = i + 1 {
      let a = pts[i]
      let b = pts[i + 1]
      verts.push(anchor.x)
      verts.push(anchor.y)
      verts.push(a.x)
      verts.push(a.y)
      verts.push(b.x)
      verts.push(b.y)
    }
  }
  let bounds = if has_pts {
    Rect::from_ltrb(min_x, min_y, max_x, max_y).inflate((2.0 : Float))
  } else {
    Rect::zero()
  }
  (verts, bounds)
}

///|
fn push_tri(
  out : Array[Float],
  a : Point,
  b : Point,
  c : Point,
) -> Unit {
  out.push(a.x)
  out.push(a.y)
  out.push(b.x)
  out.push(b.y)
  out.push(c.x)
  out.push(c.y)
}

///|
fn push_quad_tris(
  out : Array[Float],
  a : Point,
  b : Point,
  c : Point,
  d : Point,
) -> Unit {
  push_tri(out, a, b, c)
  push_tri(out, a, c, d)
}

///|
fn seg_normal(a : Point, b : Point) -> Point? {
  let dx = (b.x - a.x).to_double()
  let dy = (b.y - a.y).to_double()
  let len = (dx * dx + dy * dy).sqrt()
  if len < 1.0e-6 {
    None
  } else {
    let inv = 1.0 / len
    Some({ x: Float::from_double(-dy * inv), y: Float::from_double(dx * inv) })
  }
}

///|
fn push_round_fan(
  out : Array[Float],
  center : Point,
  r : Float,
  start_dir : Point,
  end_dir : Point,
  ccw : Bool,
) -> Unit {
  let steps = 8
  let a0 = atan2_approx(start_dir.y.to_double(), start_dir.x.to_double())
  let mut a1 = atan2_approx(end_dir.y.to_double(), end_dir.x.to_double())
  let two_pi = 6.283185307179586
  if ccw {
    while a1 < a0 {
      a1 = a1 + two_pi
    }
  } else {
    while a1 > a0 {
      a1 = a1 - two_pi
    }
  }
  let mut prev = {
    x: center.x + start_dir.x * r,
    y: center.y + start_dir.y * r,
  }
  for i = 1; i <= steps; i = i + 1 {
    let t = i.to_double() / steps.to_double()
    let ang = a0 + (a1 - a0) * t
    let (sn, cs) = sin_cos_d(ang)
    let cur = {
      x: center.x + Float::from_double(cs) * r,
      y: center.y + Float::from_double(sn) * r,
    }
    push_tri(out, center, prev, cur)
    prev = cur
  }
}

///|
fn atan2_approx(y : Double, x : Double) -> Double {
  let pi = 3.141592653589793
  let half_pi = 1.5707963267948966
  if x == 0.0 {
    return if y > 0.0 { half_pi } else if y < 0.0 { -half_pi } else { 0.0 }
  }
  let abs_x = if x < 0.0 { -x } else { x }
  let abs_y = if y < 0.0 { -y } else { y }
  let a = if abs_x > abs_y { abs_y / abs_x } else { abs_x / abs_y }
  let s = a * a
  let mut r = ((-0.0464964749 * s + 0.15931422) * s - 0.327622764) * s * a + a
  if abs_y > abs_x {
    r = half_pi - r
  }
  if x < 0.0 {
    r = pi - r
  }
  if y < 0.0 {
    r = -r
  }
  r
}

///|
// Expands path contours into stroke triangle geometry (screen-space vec2).
pub fn tessellate_stroke(
  path : Path,
  xform : Matrix3,
  stroke_width : Float,
  cap : StrokeCap,
  join : StrokeJoin,
  miter_limit : Float,
  tolerance? : Float = (0.25 : Float),
) -> Array[Float] {
  let contours = flatten_path_contours(path, xform, tolerance~)
  let out : Array[Float] = []
  let hw = max_f((0.5 : Float), stroke_width * (0.5 : Float))
  for pair in contours {
    let (raw_pts, closed) = pair
    if raw_pts.length() < 2 {
      continue
    }
    let pts : Array[Point] = []
    for p in raw_pts {
      if pts.length() == 0 || p.distance_to(pts[pts.length() - 1]) > (1.0e-3 : Float) {
        pts.push(p)
      }
    }
    if pts.length() < 2 {
      continue
    }
    let seg_count = pts.length() - 1
    let normals : Array[Point] = []
    for i = 0; i < seg_count; i = i + 1 {
      let n = match seg_normal(pts[i], pts[i + 1]) {
        Some(v) => v
        None => { x: (0.0 : Float), y: (1.0 : Float) }
      }
      normals.push(n)
      let p0 = pts[i]
      let p1 = pts[i + 1]
      let off = n.scale(hw)
      push_quad_tris(
        out,
        p0.add(off),
        p1.add(off),
        p1.sub(off),
        p0.sub(off),
      )
    }
    // Joins
    let join_count = if closed { seg_count } else { seg_count - 1 }
    for j = 0; j < join_count; j = j + 1 {
      let n0 = normals[j]
      let n1 = normals[(j + 1) % seg_count]
      let vertex = pts[(j + 1) % pts.length()]
      let cross = n0.x * n1.y - n0.y * n1.x
      if abs_f(cross) < (1.0e-4 : Float) {
        continue
      }
      let sign = if cross > (0.0 : Float) { (-1.0 : Float) } else { (1.0 : Float) }
      let a_dir = n0.scale(sign)
      let b_dir = n1.scale(sign)
      let pa = vertex.add(a_dir.scale(hw))
      let pb = vertex.add(b_dir.scale(hw))
      match join {
        StrokeJoin::Round => push_round_fan(out, vertex, hw, a_dir, b_dir, cross < (0.0 : Float))
        StrokeJoin::Bevel => push_tri(out, vertex, pa, pb)
        StrokeJoin::Miter => {
          let sum_x = (a_dir.x + b_dir.x).to_double()
          let sum_y = (a_dir.y + b_dir.y).to_double()
          let slen = (sum_x * sum_x + sum_y * sum_y).sqrt()
          if slen > 1.0e-5 {
            let dot_d = (a_dir.x * b_dir.x + a_dir.y * b_dir.y).to_double()
            let miter_len = hw.to_double() / ((1.0 + dot_d) * 0.5).sqrt()
            if miter_len <= (hw * miter_limit).to_double() {
              let mx = Float::from_double(sum_x / slen * miter_len)
              let my = Float::from_double(sum_y / slen * miter_len)
              let pm = { x: vertex.x + mx, y: vertex.y + my }
              push_tri(out, vertex, pa, pm)
              push_tri(out, vertex, pm, pb)
            } else {
              push_tri(out, vertex, pa, pb)
            }
          } else {
            push_tri(out, vertex, pa, pb)
          }
        }
      }
    }
    // End caps for open contours
    if !closed {
      let s0 = pts[0]
      let n0 = normals[0]
      let tan0 = { x: -n0.y, y: n0.x }
      match cap {
        StrokeCap::Butt => ()
        StrokeCap::Square => {
          let ext = tan0.scale(hw)
          let off = n0.scale(hw)
          push_quad_tris(
            out,
            s0.add(off),
            s0.add(off).add(ext),
            s0.sub(off).add(ext),
            s0.sub(off),
          )
        }
        StrokeCap::Round => push_round_fan(out, s0, hw, n0, n0.scale((-1.0 : Float)), false)
      }
      let last_i = seg_count - 1
      let s1 = pts[pts.length() - 1]
      let n1 = normals[last_i]
      let tan1 = { x: n1.y, y: -n1.x }
      match cap {
        StrokeCap::Butt => ()
        StrokeCap::Square => {
          let ext = tan1.scale(hw)
          let off = n1.scale(hw)
          push_quad_tris(
            out,
            s1.add(off),
            s1.add(off).add(ext),
            s1.sub(off).add(ext),
            s1.sub(off),
          )
        }
        StrokeCap::Round => push_round_fan(out, s1, hw, n1.scale((-1.0 : Float)), n1, false)
      }
    }
  }
  out
}
