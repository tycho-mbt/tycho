// Earcut invariants: triangle counts, CCW output, and total area equal to the
// polygon area minus its holes.

///|
fn tri_area2(a : @tmath.Vec2, b : @tmath.Vec2, c : @tmath.Vec2) -> Float {
  (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)
}

///|
fn faces_area(
  verts : Array[@tmath.Vec2],
  faces : Array[UInt],
) -> Float {
  let mut sum : Float = 0.0
  let mut i = 0
  while i + 2 < faces.length() {
    let a = verts[faces[i].reinterpret_as_int()]
    let b = verts[faces[i + 1].reinterpret_as_int()]
    let c = verts[faces[i + 2].reinterpret_as_int()]
    sum = sum + tri_area2(a, b, c) * 0.5
    i = i + 3
  }
  sum
}

///|
fn faces_are_ccw(
  verts : Array[@tmath.Vec2],
  faces : Array[UInt],
) -> Bool {
  let mut i = 0
  while i + 2 < faces.length() {
    let a = verts[faces[i].reinterpret_as_int()]
    let b = verts[faces[i + 1].reinterpret_as_int()]
    let c = verts[faces[i + 2].reinterpret_as_int()]
    if tri_area2(a, b, c) <= 0.0 {
      return false
    }
    i = i + 3
  }
  true
}

///|
test "earcut simple polygon" {
  let square : Array[@tmath.Vec2] = [
    @tmath.Vec2::new(0.0, 0.0),
    @tmath.Vec2::new(1.0, 0.0),
    @tmath.Vec2::new(1.0, 1.0),
    @tmath.Vec2::new(0.0, 1.0),
  ]
  let faces = triangulate(square, [])
  need(faces.length() == 6, "square faces")
  need(faces_are_ccw(square, faces), "square ccw")
  need(close(faces_area(square, faces), 1.0), "square area")
  // Concave L shape: n - 2 triangles.
  let l_shape : Array[@tmath.Vec2] = [
    @tmath.Vec2::new(0.0, 0.0),
    @tmath.Vec2::new(2.0, 0.0),
    @tmath.Vec2::new(2.0, 1.0),
    @tmath.Vec2::new(1.0, 1.0),
    @tmath.Vec2::new(1.0, 2.0),
    @tmath.Vec2::new(0.0, 2.0),
  ]
  let l_faces = triangulate(l_shape, [])
  need(l_faces.length() == 4 * 3, "L faces")
  need(faces_are_ccw(l_shape, l_faces), "L ccw")
  need(close(faces_area(l_shape, l_faces), 3.0), "L area")
}

///|
test "earcut with hole" {
  let outer : Array[@tmath.Vec2] = [
    @tmath.Vec2::new(0.0, 0.0),
    @tmath.Vec2::new(2.0, 0.0),
    @tmath.Vec2::new(2.0, 2.0),
    @tmath.Vec2::new(0.0, 2.0),
  ]
  // Clockwise hole (earcut's expected orientation).
  let hole : Array[@tmath.Vec2] = [
    @tmath.Vec2::new(0.5, 0.5),
    @tmath.Vec2::new(0.5, 1.5),
    @tmath.Vec2::new(1.5, 1.5),
    @tmath.Vec2::new(1.5, 0.5),
  ]
  let verts : Array[@tmath.Vec2] = []
  for p in outer {
    verts.push(p)
  }
  for p in hole {
    verts.push(p)
  }
  let faces = triangulate(outer, [hole])
  // n + 2h - 2 triangles for a simple polygon with holes.
  need(faces.length() / 3 == 8, "holed faces")
  need(faces_are_ccw(verts, faces), "holed ccw")
  need(close(faces_area(verts, faces), 3.0), "holed area")
  for f in faces {
    need(f.reinterpret_as_int() < verts.length(), "holed index in range")
  }
}

///|
fn cw_square_at(
  cx : Float,
  cy : Float,
  half : Float,
) -> Array[@tmath.Vec2] {
  [
    @tmath.Vec2::new(cx + half, cy - half),
    @tmath.Vec2::new(cx - half, cy - half),
    @tmath.Vec2::new(cx - half, cy + half),
    @tmath.Vec2::new(cx + half, cy + half),
  ]
}

///|
test "earcut star polygon" {
  // 5-point star: alternating radii, concave at every inner vertex.
  let ring : Array[@tmath.Vec2] = []
  for i = 0; i < 10; i = i + 1 {
    let radius : Float = if i % 2 == 0 { 1.0 } else { 0.4 }
    let angle = f_of_int(i) * (@tmath.PI / 5.0)
    let (s, c) = @tmath.sin_cos(angle)
    ring.push(@tmath.Vec2::new(c * radius, s * radius))
  }
  let faces = triangulate(ring, [])
  need(faces.length() / 3 == 8, "star faces")
  need(faces_are_ccw(ring, faces), "star ccw")
  need(
    close(faces_area(ring, faces), @tmath.abs_f(polygon_area(ring)), eps=1.0e-4),
    "star area",
  )
}

///|
test "earcut two holes" {
  let outer : Array[@tmath.Vec2] = [
    @tmath.Vec2::new(-1.0, -1.0),
    @tmath.Vec2::new(1.0, -1.0),
    @tmath.Vec2::new(1.0, 1.0),
    @tmath.Vec2::new(-1.0, 1.0),
  ]
  let h1 = cw_square_at(-0.5, -0.5, 0.2)
  let h2 = cw_square_at(0.5, 0.5, 0.2)
  let verts : Array[@tmath.Vec2] = []
  for p in outer {
    verts.push(p)
  }
  for ring in [h1, h2] {
    for p in ring {
      verts.push(p)
    }
  }
  let faces = triangulate(outer, [h1, h2])
  // n + 2h - 2 for 12 vertices and 2 holes.
  need(faces.length() / 3 == 14, "two hole faces")
  need(faces_are_ccw(verts, faces), "two hole ccw")
  need(close(faces_area(verts, faces), 4.0 - 0.32, eps=1.0e-4), "two hole area")
}

///|
test "earcut filters degenerate input" {
  // Extra collinear vertex on the bottom edge.
  let ring : Array[@tmath.Vec2] = [
    @tmath.Vec2::new(0.0, 0.0),
    @tmath.Vec2::new(0.5, 0.0),
    @tmath.Vec2::new(1.0, 0.0),
    @tmath.Vec2::new(1.0, 1.0),
    @tmath.Vec2::new(0.0, 1.0),
  ]
  let faces = triangulate(ring, [])
  need(faces.length() / 3 == 3, "collinear faces")
  need(close(faces_area(ring, faces), 1.0), "collinear area")
  // Fewer than three points cannot form a polygon.
  let two : Array[@tmath.Vec2] = [
    @tmath.Vec2::new(0.0, 0.0),
    @tmath.Vec2::new(1.0, 0.0),
  ]
  need(triangulate(two, []).length() == 0, "degenerate contour")
}
