// Pure-MoonBit port of mapbox/earcut 3.0.2 — the triangulator behind
// three.js `ShapeUtils.triangulateShape` (see `refs/three.js/src/extras/lib/earcut.js`).
//
// Only the ear-clipping core is ported: the z-order curve acceleration is
// omitted because it is a pure speed optimization (it changes triangle order,
// not the geometric result). Every robustness pass is kept: collinear /
// duplicate filtering, local self-intersection curing, and polygon splitting.
//
// Nodes live in one `Array[ENode]` and are addressed by index; `-1` is null.
// Nodes are never reclaimed, which matches the reference (its nodes are also
// garbage after removal).

///|
/// One polygon vertex in the circular doubly linked list.
priv struct ENode {
  // Vertex index in the caller's coordinate array.
  i : Int
  x : Float
  y : Float
  mut prev : Int
  mut next : Int
  // Steiner points are injected duplicates and must never be filtered.
  mut steiner : Bool
}

///|
fn enode_create(i : Int, x : Float, y : Float) -> ENode {
  { i, x, y, prev: -1, next: -1, steiner: false }
}

///|
fn enode_insert(
  nodes : Array[ENode],
  i : Int,
  x : Float,
  y : Float,
  last : Int,
) -> Int {
  let p = nodes.length()
  nodes.push(enode_create(i, x, y))
  if last < 0 {
    nodes[p].prev = p
    nodes[p].next = p
  } else {
    let after = nodes[last].next
    nodes[p].next = after
    nodes[p].prev = last
    nodes[after].prev = p
    nodes[last].next = p
  }
  p
}

///|
fn enode_remove(nodes : Array[ENode], p : Int) -> Unit {
  let prev = nodes[p].prev
  let next = nodes[p].next
  nodes[next].prev = prev
  nodes[prev].next = next
}

///|
fn enode_equals(nodes : Array[ENode], a : Int, b : Int) -> Bool {
  nodes[a].x == nodes[b].x && nodes[a].y == nodes[b].y
}

///|
/// Twice the signed area of the triangle `(p, q, r)`; negative when the
/// corner turns clockwise.
fn enode_area(nodes : Array[ENode], p : Int, q : Int, r : Int) -> Float {
  (nodes[q].y - nodes[p].y) * (nodes[r].x - nodes[q].x) -
  (nodes[q].x - nodes[p].x) * (nodes[r].y - nodes[q].y)
}

///|
fn polygon_signed_area(
  data : Array[@tmath.Vec2],
  start : Int,
  end : Int,
) -> Float {
  let mut sum : Float = 0.0
  let mut j = end - 1
  for i = start; i < end; i = i + 1 {
    sum = sum + (data[j].x - data[i].x) * (data[i].y + data[j].y)
    j = i
  }
  sum
}

///|
/// Build a circular doubly linked list over `data[start..end)` in the
/// requested winding order. Returns the last inserted node, or -1.
fn linked_list(
  nodes : Array[ENode],
  data : Array[@tmath.Vec2],
  start : Int,
  end : Int,
  clockwise : Bool,
) -> Int {
  let mut last = -1
  if clockwise == (polygon_signed_area(data, start, end) > 0.0) {
    for i = start; i < end; i = i + 1 {
      last = enode_insert(nodes, i, data[i].x, data[i].y, last)
    }
  } else {
    for i = end - 1; i >= start; i = i - 1 {
      last = enode_insert(nodes, i, data[i].x, data[i].y, last)
    }
  }
  if last >= 0 && enode_equals(nodes, last, nodes[last].next) {
    let next = nodes[last].next
    enode_remove(nodes, last)
    last = next
  }
  last
}

///|
/// Drop duplicate and collinear vertices.
fn filter_points(nodes : Array[ENode], start : Int, end : Int) -> Int {
  if start < 0 {
    return start
  }
  let mut stop = if end < 0 { start } else { end }
  let mut p = start
  let mut again = true
  while again || p != stop {
    again = false
    if !nodes[p].steiner &&
      (enode_equals(nodes, p, nodes[p].next) ||
        enode_area(nodes, nodes[p].prev, p, nodes[p].next) == 0.0) {
      let prev = nodes[p].prev
      enode_remove(nodes, p)
      p = prev
      stop = p
      if p == nodes[p].next {
        break
      }
      again = true
    } else {
      p = nodes[p].next
    }
  }
  stop
}

///|
fn point_in_triangle(
  ax : Float,
  ay : Float,
  bx : Float,
  by : Float,
  cx : Float,
  cy : Float,
  px : Float,
  py : Float,
) -> Bool {
  (cx - px) * (ay - py) >= (ax - px) * (cy - py) &&
  (ax - px) * (by - py) >= (bx - px) * (ay - py) &&
  (bx - px) * (cy - py) >= (cx - px) * (by - py)
}

///|
/// Like `point_in_triangle`, but false when the point equals the first vertex
/// (that vertex is the ear tip itself and must not disqualify the ear).
fn point_in_triangle_except_first(
  nodes : Array[ENode],
  a : Int,
  b : Int,
  c : Int,
  p : Int,
) -> Bool {
  let ax = nodes[a].x
  let ay = nodes[a].y
  let px = nodes[p].x
  let py = nodes[p].y
  if ax == px && ay == py {
    return false
  }
  point_in_triangle(
    ax,
    ay,
    nodes[b].x,
    nodes[b].y,
    nodes[c].x,
    nodes[c].y,
    px,
    py,
  )
}

///|
/// A corner is an ear when it is convex and its triangle contains no other
/// reflex vertex.
fn is_ear(nodes : Array[ENode], ear : Int) -> Bool {
  let a = nodes[ear].prev
  let b = ear
  let c = nodes[ear].next
  if enode_area(nodes, a, b, c) >= 0.0 {
    return false
  }
  let ax = nodes[a].x
  let ay = nodes[a].y
  let bx = nodes[b].x
  let by = nodes[b].y
  let cx = nodes[c].x
  let cy = nodes[c].y
  let x0 = if ax < bx { if ax < cx { ax } else { cx } } else if bx < cx {
    bx
  } else {
    cx
  }
  let y0 = if ay < by { if ay < cy { ay } else { cy } } else if by < cy {
    by
  } else {
    cy
  }
  let x1 = if ax > bx { if ax > cx { ax } else { cx } } else if bx > cx {
    bx
  } else {
    cx
  }
  let y1 = if ay > by { if ay > cy { ay } else { cy } } else if by > cy {
    by
  } else {
    cy
  }
  let mut p = nodes[c].next
  while p != a {
    if nodes[p].x >= x0 &&
      nodes[p].x <= x1 &&
      nodes[p].y >= y0 &&
      nodes[p].y <= y1 &&
      point_in_triangle_except_first(nodes, a, b, c, p) &&
      enode_area(nodes, nodes[p].prev, p, nodes[p].next) >= 0.0 {
      return false
    }
    p = nodes[p].next
  }
  true
}

///|
fn segment_sign(v : Float) -> Int {
  if v > 0.0 {
    1
  } else if v < 0.0 {
    -1
  } else {
    0
  }
}

///|
fn on_segment(nodes : Array[ENode], p : Int, q : Int, r : Int) -> Bool {
  let qx = nodes[q].x
  let qy = nodes[q].y
  let px = nodes[p].x
  let py = nodes[p].y
  let rx = nodes[r].x
  let ry = nodes[r].y
  let min_x = if px < rx { px } else { rx }
  let max_x = if px > rx { px } else { rx }
  let min_y = if py < ry { py } else { ry }
  let max_y = if py > ry { py } else { ry }
  qx <= max_x && qx >= min_x && qy <= max_y && qy >= min_y
}

///|
fn segments_intersect(
  nodes : Array[ENode],
  p1 : Int,
  q1 : Int,
  p2 : Int,
  q2 : Int,
) -> Bool {
  let o1 = segment_sign(enode_area(nodes, p1, q1, p2))
  let o2 = segment_sign(enode_area(nodes, p1, q1, q2))
  let o3 = segment_sign(enode_area(nodes, p2, q2, p1))
  let o4 = segment_sign(enode_area(nodes, p2, q2, q1))
  if o1 != o2 && o3 != o4 {
    return true
  }
  if o1 == 0 && on_segment(nodes, p1, p2, q1) {
    return true
  }
  if o2 == 0 && on_segment(nodes, p1, q2, q1) {
    return true
  }
  if o3 == 0 && on_segment(nodes, p2, p1, q2) {
    return true
  }
  if o4 == 0 && on_segment(nodes, p2, q1, q2) {
    return true
  }
  false
}

///|
fn intersects_polygon(nodes : Array[ENode], a : Int, b : Int) -> Bool {
  let mut p = a
  while true {
    if nodes[p].i != nodes[a].i &&
      nodes[nodes[p].next].i != nodes[a].i &&
      nodes[p].i != nodes[b].i &&
      nodes[nodes[p].next].i != nodes[b].i &&
      segments_intersect(nodes, p, nodes[p].next, a, b) {
      return true
    }
    p = nodes[p].next
    if p == a {
      break
    }
  }
  false
}

///|
fn locally_inside(nodes : Array[ENode], a : Int, b : Int) -> Bool {
  if enode_area(nodes, nodes[a].prev, a, nodes[a].next) < 0.0 {
    enode_area(nodes, a, b, nodes[a].next) >= 0.0 &&
    enode_area(nodes, a, nodes[a].prev, b) >= 0.0
  } else {
    enode_area(nodes, a, b, nodes[a].prev) < 0.0 ||
    enode_area(nodes, a, nodes[a].next, b) < 0.0
  }
}

///|
fn middle_inside(nodes : Array[ENode], a : Int, b : Int) -> Bool {
  let mut p = a
  let mut inside = false
  let px = (nodes[a].x + nodes[b].x) / 2.0
  let py = (nodes[a].y + nodes[b].y) / 2.0
  while true {
    let next = nodes[p].next
    if (nodes[p].y > py) != (nodes[next].y > py) &&
      nodes[next].y != nodes[p].y &&
      px < (nodes[next].x - nodes[p].x) * (py - nodes[p].y) /
        (nodes[next].y - nodes[p].y) + nodes[p].x {
      inside = !inside
    }
    p = next
    if p == a {
      break
    }
  }
  inside
}

///|
fn is_valid_diagonal(nodes : Array[ENode], a : Int, b : Int) -> Bool {
  let locally_visible = locally_inside(nodes, a, b) &&
    locally_inside(nodes, b, a) &&
    middle_inside(nodes, a, b) &&
    (enode_area(nodes, nodes[a].prev, a, nodes[b].prev) != 0.0 ||
      enode_area(nodes, a, nodes[b].prev, b) != 0.0)
  let zero_length = enode_equals(nodes, a, b) &&
    enode_area(nodes, nodes[a].prev, a, nodes[a].next) > 0.0 &&
    enode_area(nodes, nodes[b].prev, b, nodes[b].next) > 0.0
  nodes[nodes[a].next].i != nodes[b].i &&
  nodes[nodes[a].prev].i != nodes[b].i &&
  !intersects_polygon(nodes, a, b) &&
  (locally_visible || zero_length)
}

///|
/// Link two nodes with a bridge: within one ring this splits the polygon in
/// two; across an outer ring and a hole it merges them into a single ring.
fn split_polygon(nodes : Array[ENode], a : Int, b : Int) -> Int {
  let a2 = nodes.length()
  nodes.push(enode_create(nodes[a].i, nodes[a].x, nodes[a].y))
  let b2 = nodes.length()
  nodes.push(enode_create(nodes[b].i, nodes[b].x, nodes[b].y))
  let a_next = nodes[a].next
  let b_prev = nodes[b].prev
  nodes[a].next = b
  nodes[b].prev = a
  nodes[a2].next = a_next
  nodes[a_next].prev = a2
  nodes[b2].next = a2
  nodes[a2].prev = b2
  nodes[b_prev].next = b2
  nodes[b2].prev = b_prev
  b2
}

///|
fn cure_local_intersections(
  nodes : Array[ENode],
  start : Int,
  triangles : Array[Int],
) -> Int {
  let mut p = start
  let mut stop = start
  while true {
    let a = nodes[p].prev
    let b = nodes[nodes[p].next].next
    if !enode_equals(nodes, a, b) &&
      segments_intersect(nodes, a, p, nodes[p].next, b) &&
      locally_inside(nodes, a, b) &&
      locally_inside(nodes, b, a) {
      triangles.push(nodes[a].i)
      triangles.push(nodes[p].i)
      triangles.push(nodes[b].i)
      let next = nodes[p].next
      enode_remove(nodes, p)
      enode_remove(nodes, next)
      p = b
      stop = b
    }
    p = nodes[p].next
    if p == stop {
      break
    }
  }
  filter_points(nodes, p, -1)
}

///|
fn split_earcut(
  nodes : Array[ENode],
  start : Int,
  triangles : Array[Int],
) -> Unit {
  let mut a = start
  while true {
    let mut b = nodes[nodes[a].next].next
    while b != nodes[a].prev {
      if nodes[a].i != nodes[b].i && is_valid_diagonal(nodes, a, b) {
        let c = split_polygon(nodes, a, b)
        let left = filter_points(nodes, a, nodes[a].next)
        let right = filter_points(nodes, c, nodes[c].next)
        earcut_linked(nodes, left, triangles, 0)
        earcut_linked(nodes, right, triangles, 0)
        return
      }
      b = nodes[b].next
    }
    a = nodes[a].next
    if a == start {
      break
    }
  }
}

///|
fn earcut_linked(
  nodes : Array[ENode],
  ear : Int,
  triangles : Array[Int],
  pass : Int,
) -> Unit {
  if ear < 0 {
    return
  }
  let mut stop = ear
  let mut current = ear
  while nodes[current].prev != nodes[current].next {
    let prev = nodes[current].prev
    let next = nodes[current].next
    if is_ear(nodes, current) {
      triangles.push(nodes[prev].i)
      triangles.push(nodes[current].i)
      triangles.push(nodes[next].i)
      enode_remove(nodes, current)
      // Skipping the next vertex produces fewer slivers.
      current = nodes[next].next
      stop = current
      continue
    }
    current = next
    // Full sweep without finding an ear: escalate the robustness passes.
    if current == stop {
      if pass == 0 {
        earcut_linked(nodes, filter_points(nodes, current, -1), triangles, 1)
      } else if pass == 1 {
        let cured = cure_local_intersections(
          nodes,
          filter_points(nodes, current, -1),
          triangles,
        )
        earcut_linked(nodes, cured, triangles, 2)
      } else {
        split_earcut(nodes, current, triangles)
      }
      break
    }
  }
}

///|
fn get_leftmost(nodes : Array[ENode], start : Int) -> Int {
  let mut p = start
  let mut leftmost = start
  while true {
    if nodes[p].x < nodes[leftmost].x ||
      (nodes[p].x == nodes[leftmost].x && nodes[p].y < nodes[leftmost].y) {
      leftmost = p
    }
    p = nodes[p].next
    if p == start {
      break
    }
  }
  leftmost
}

///|
fn hole_less(nodes : Array[ENode], a : Int, b : Int) -> Bool {
  if nodes[a].x != nodes[b].x {
    return nodes[a].x < nodes[b].x
  }
  if nodes[a].y != nodes[b].y {
    return nodes[a].y < nodes[b].y
  }
  let a_next = nodes[a].next
  let b_next = nodes[b].next
  let a_slope = (nodes[a_next].y - nodes[a].y) / (nodes[a_next].x - nodes[a].x)
  let b_slope = (nodes[b_next].y - nodes[b].y) / (nodes[b_next].x - nodes[b].x)
  a_slope < b_slope
}

///|
/// Whether sector `m` contains sector `p` (same coordinates, different rings).
fn sector_contains_sector(nodes : Array[ENode], m : Int, p : Int) -> Bool {
  enode_area(nodes, nodes[m].prev, m, nodes[p].prev) < 0.0 &&
  enode_area(nodes, nodes[p].next, m, nodes[m].next) < 0.0
}

///|
/// David Eberly's bridge search between a hole and the outer ring.
fn find_hole_bridge(nodes : Array[ENode], hole : Int, outer : Int) -> Int {
  let hx = nodes[hole].x
  let hy = nodes[hole].y
  let mut qx : Float = -3.0e38
  let mut m = -1
  if enode_equals(nodes, hole, outer) {
    return outer
  }
  let mut p = outer
  while true {
    let p_next = nodes[p].next
    if enode_equals(nodes, hole, p_next) {
      return p_next
    }
    if hy <= nodes[p].y &&
      hy >= nodes[p_next].y &&
      nodes[p_next].y != nodes[p].y {
      let x = nodes[p].x + (hy - nodes[p].y) * (nodes[p_next].x - nodes[p].x) /
        (nodes[p_next].y - nodes[p].y)
      if x <= hx && x > qx {
        qx = x
        m = if nodes[p].x < nodes[p_next].x { p } else { p_next }
        if x == hx {
          // Hole touches the outer segment: pick its leftmost endpoint.
          return m
        }
      }
    }
    p = p_next
    if p == outer {
      break
    }
  }
  if m < 0 {
    return -1
  }
  let stop = m
  let mx = nodes[m].x
  let my = nodes[m].y
  let mut tan_min : Float = 3.0e38
  p = m
  while true {
    let px = nodes[p].x
    let py = nodes[p].y
    if hx >= px && px >= mx && hx != px {
      let inside = if hy < my {
        point_in_triangle(hx, hy, mx, my, qx, hy, px, py)
      } else {
        point_in_triangle(qx, hy, mx, my, hx, hy, px, py)
      }
      if inside {
        let tan = (hy - py).abs() / (hx - px)
        let better = tan < tan_min ||
          (tan == tan_min &&
            (px > mx || (px == mx && sector_contains_sector(nodes, m, p))))
        if locally_inside(nodes, p, hole) && better {
          m = p
          tan_min = tan
        }
      }
    }
    p = nodes[p].next
    if p == stop {
      break
    }
  }
  m
}

///|
fn eliminate_hole(nodes : Array[ENode], hole : Int, outer : Int) -> Int {
  let bridge = find_hole_bridge(nodes, hole, outer)
  if bridge < 0 {
    return outer
  }
  let bridge_reverse = split_polygon(nodes, bridge, hole)
  let _ = filter_points(nodes, bridge_reverse, nodes[bridge_reverse].next)
  filter_points(nodes, bridge, nodes[bridge].next)
}

///|
/// Merge every hole ring into the outer ring (left-to-right bridge order).
fn eliminate_holes(
  nodes : Array[ENode],
  data : Array[@tmath.Vec2],
  hole_starts : Array[Int],
  outer : Int,
) -> Int {
  let queue : Array[Int] = []
  for h = 0; h < hole_starts.length(); h = h + 1 {
    let start = hole_starts[h]
    let end = if h + 1 < hole_starts.length() {
      hole_starts[h + 1]
    } else {
      data.length()
    }
    let list = linked_list(nodes, data, start, end, false)
    if list >= 0 {
      if nodes[list].next == list {
        nodes[list].steiner = true
      }
      queue.push(get_leftmost(nodes, list))
    }
  }
  // Insertion sort by (x, y, slope); hole counts are tiny.
  let mut i = 1
  while i < queue.length() {
    let current = queue[i]
    let mut j = i - 1
    while j >= 0 && hole_less(nodes, current, queue[j]) {
      queue[j + 1] = queue[j]
      j = j - 1
    }
    queue[j + 1] = current
    i = i + 1
  }
  let mut result = outer
  for hole in queue {
    result = eliminate_hole(nodes, hole, result)
  }
  result
}

///|
/// Triangulate `contour` minus `holes`, returning triangle indices into the
/// concatenated `contour ++ holes...` vertex array.
///
/// Output triangles are CCW when the contour is CCW (and holes CW); callers
/// that need a fixed orientation should normalize the rings first
/// (`Shape2D` helpers do).
pub fn triangulate(
  contour : Array[@tmath.Vec2],
  holes : Array[Array[@tmath.Vec2]],
) -> Array[UInt] {
  let data : Array[@tmath.Vec2] = []
  for p in contour {
    data.push(p)
  }
  let hole_starts : Array[Int] = []
  for hole in holes {
    hole_starts.push(data.length())
    for p in hole {
      data.push(p)
    }
  }
  let outer_len = if hole_starts.length() > 0 {
    hole_starts[0]
  } else {
    data.length()
  }
  if outer_len < 3 {
    return []
  }
  let nodes : Array[ENode] = []
  let triangles : Array[Int] = []
  let outer = linked_list(nodes, data, 0, outer_len, true)
  if outer < 0 || nodes[outer].next == nodes[outer].prev {
    return []
  }
  let start = if hole_starts.length() > 0 {
    eliminate_holes(nodes, data, hole_starts, outer)
  } else {
    outer
  }
  earcut_linked(nodes, start, triangles, 0)
  let out : Array[UInt] = []
  for index in triangles {
    out.push(index.reinterpret_as_uint())
  }
  out
}
