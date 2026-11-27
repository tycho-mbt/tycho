// Edge extraction from a `MeshData` into `LineData`.
//
// `edges` keeps boundary edges plus creases whose dihedral angle exceeds a
// threshold (three.js `EdgesGeometry`); `wireframe` keeps every unique
// triangle edge (three.js `WireframeGeometry`).
//
// Both match edges by *quantized position*, never by vertex index: hard-edge
// generators (box, cylinder, ...) split shared corners into one vertex per
// face, so the same geometric edge has different indices on its two sides.

///|
/// Round a coordinate onto a 1 mm grid (three.js uses a 1e-4 string key).
/// `floor(x + 0.5)` is round-half-up; the 1e-3 scale keeps the quantized value
/// inside `Int` (32-bit) for coordinates up to ~2.1e6 m.
fn quantize_coord(v : Float) -> Int {
  (v * 1000.0 + 0.5).floor().to_int()
}

///|
fn position_key(p : @tmath.Vec3) -> (Int, Int, Int) {
  (quantize_coord(p.x), quantize_coord(p.y), quantize_coord(p.z))
}

///|
/// Collapse position-identical vertices onto canonical ids.
/// Returns `(unique positions, per-vertex canonical id)`.
fn canonical_vertices(
  mesh : MeshData,
) -> (Array[@tmath.Vec3], Array[Int]) {
  let map : @hashmap.HashMap[(Int, Int, Int), Int] = @hashmap.HashMap([])
  let unique : Array[@tmath.Vec3] = []
  let ids : Array[Int] = []
  for p in mesh.positions {
    let key = position_key(p)
    let id = match map.get(key) {
      Some(i) => i
      None => {
        let i = unique.length()
        map.set(key, i)
        unique.push(p)
        i
      }
    }
    ids.push(id)
  }
  (unique, ids)
}

///|
/// Boundary + crease edges. An edge shared by two triangles is emitted only
/// when the angle between their normals exceeds `threshold_angle` degrees;
/// edges used by a single triangle (mesh boundaries) are always emitted.
pub fn edges(mesh : MeshData, threshold_angle? : Float = 1.0) -> LineData {
  let (unique, ids) = canonical_vertices(mesh)
  let threshold = @tmath.cos(@tmath.deg_to_rad(threshold_angle))
  // Pending unmatched directed edges; `alive` marks the ones still unmatched.
  let pending : Array[(Int, Int, @tmath.Vec3)] = []
  let alive : Array[Bool] = []
  let lookup : @hashmap.HashMap[(Int, Int), Int] = @hashmap.HashMap([])
  let out : Array[UInt] = []
  let index_count = mesh.indices.length()
  let mut t = 0
  while t + 2 < index_count {
    let i0 = ids[mesh.indices[t].reinterpret_as_int()]
    let i1 = ids[mesh.indices[t + 1].reinterpret_as_int()]
    let i2 = ids[mesh.indices[t + 2].reinterpret_as_int()]
    if i0 != i1 && i1 != i2 && i2 != i0 {
      let a = unique[i0]
      let b = unique[i1]
      let c = unique[i2]
      match (b - a).cross(c - a).try_normalize() {
        Some(normal) => {
          let corners : Array[(Int, Int)] = [(i0, i1), (i1, i2), (i2, i0)]
          for corner in corners {
            let (u, v) = corner
            match lookup.get((v, u)) {
              Some(k) => {
                if alive[k] {
                  if normal.dot(pending[k].2) <= threshold {
                    out.push(u.reinterpret_as_uint())
                    out.push(v.reinterpret_as_uint())
                  }
                  alive[k] = false
                }
              }
              None => {
                if !lookup.contains((u, v)) {
                  lookup.set((u, v), pending.length())
                  pending.push((u, v, normal))
                  alive.push(true)
                }
              }
            }
          }
        }
        None => ()
      }
    }
    t = t + 3
  }
  // Edges that never found a sibling are boundaries: always visible.
  for k = 0; k < pending.length(); k = k + 1 {
    if alive[k] {
      out.push(pending[k].0.reinterpret_as_uint())
      out.push(pending[k].1.reinterpret_as_uint())
    }
  }
  LineData::new(FixedArray::from_array(unique), FixedArray::from_array(out))
}

///|
/// Every unique triangle edge, i.e. the full wireframe of the mesh.
pub fn wireframe(mesh : MeshData) -> LineData {
  let (unique, ids) = canonical_vertices(mesh)
  let seen : @hashmap.HashMap[(Int, Int), Unit] = @hashmap.HashMap([])
  let out : Array[UInt] = []
  let index_count = mesh.indices.length()
  let mut t = 0
  while t + 2 < index_count {
    let i0 = ids[mesh.indices[t].reinterpret_as_int()]
    let i1 = ids[mesh.indices[t + 1].reinterpret_as_int()]
    let i2 = ids[mesh.indices[t + 2].reinterpret_as_int()]
    let corners : Array[(Int, Int)] = [(i0, i1), (i1, i2), (i2, i0)]
    for corner in corners {
      let (u, v) = corner
      if u != v {
        let key = if u < v { (u, v) } else { (v, u) }
        if !seen.contains(key) {
          seen.set(key, ())
          out.push(u.reinterpret_as_uint())
          out.push(v.reinterpret_as_uint())
        }
      }
    }
    t = t + 3
  }
  LineData::new(FixedArray::from_array(unique), FixedArray::from_array(out))
}
