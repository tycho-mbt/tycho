// Bounding-volume hierarchy for CPU picking.
//
// `ray_mesh_hit` tests every triangle, which is fine for a debug gizmo and far
// too slow for an editor that picks against a 100k-triangle mesh every pointer
// move. `MeshBvh` builds a median-split binary BVH over triangle centroids once
// per mesh and answers the same `MeshHit` in logarithmic time.
//
// The tree is built in the mesh's local space: `Renderer3D::pick` transforms the
// world ray into local space once (`Affine3::inverse` without renormalizing, so
// the ray parameter stays the world distance), traverses, and transforms the
// hit normal back with the normal matrix. Nodes store a tight AABB and either a
// contiguous triangle range (leaf) or two child indices.

///|
const BVH_LEAF_SIZE : Int = 8

///|
const BVH_MAX_DEPTH : Int = 32

///|
priv struct BvhNode {
  bounds : @tmath.Aabb3
  // Leaf: `count > 0` and `start` is the first slot in `MeshBvh::triangles`.
  // Interior: `left` / `right` are child node indices and `count == 0`.
  left : Int
  right : Int
  start : Int
  count : Int
}

///|
/// CPU-side BVH over one mesh's triangles, in mesh-local space.
///
/// Build once per mesh (`Renderer3D::pick` caches one per uploaded mesh) and
/// reuse for any number of rays. The source mesh is kept by reference, so the
/// BVH stays valid as long as the `MeshData` is not mutated.
pub struct MeshBvh {
  priv mesh : @tgeo.MeshData
  // Triangle ids in leaf order; leaves index contiguous slices.
  priv triangles : Array[Int]
  priv nodes : Array[BvhNode]
  priv bounds : @tmath.Aabb3
}

///|
fn bvh_axis_value(v : @tmath.Vec3, axis : Int) -> Float {
  if axis == 0 {
    v.x
  } else if axis == 1 {
    v.y
  } else {
    v.z
  }
}

///|
fn bvh_triangle_bounds(mesh : @tgeo.MeshData, tri : Int) -> @tmath.Aabb3 {
  let idx = mesh.indices()
  let pos = mesh.positions()
  let p0 = pos[idx[tri * 3].reinterpret_as_int()]
  let p1 = pos[idx[tri * 3 + 1].reinterpret_as_int()]
  let p2 = pos[idx[tri * 3 + 2].reinterpret_as_int()]
  @tmath.Aabb3::new(p0.min(p1).min(p2), p0.max(p1).max(p2))
}

///|
/// Sort `order[start..end]` by centroid on `axis` (a stable order is not
/// required; leaves only need spatial coherence).
fn bvh_sort_range(
  order : Array[Int],
  start : Int,
  end : Int,
  axis : Int,
  centroids : Array[@tmath.Vec3],
) -> Unit {
  let sub : Array[Int] = []
  for i = start; i < end; i = i + 1 {
    sub.push(order[i])
  }
  sub.sort_by(fn(a, b) {
    let ca = bvh_axis_value(centroids[a], axis)
    let cb = bvh_axis_value(centroids[b], axis)
    if ca < cb {
      -1
    } else if ca > cb {
      1
    } else {
      0
    }
  })
  for i = 0; i < sub.length(); i = i + 1 {
    order[start + i] = sub[i]
  }
}

///|
fn bvh_build_node(
  mesh : @tgeo.MeshData,
  order : Array[Int],
  centroids : Array[@tmath.Vec3],
  nodes : Array[BvhNode],
  start : Int,
  end : Int,
  depth : Int,
) -> Int {
  let slot = nodes.length()
  let mut node_bounds = bvh_triangle_bounds(mesh, order[start])
  let mut cmin = centroids[order[start]]
  let mut cmax = cmin
  for i = start + 1; i < end; i = i + 1 {
    let tri = order[i]
    node_bounds = node_bounds.union(bvh_triangle_bounds(mesh, tri))
    cmin = cmin.min(centroids[tri])
    cmax = cmax.max(centroids[tri])
  }
  nodes.push({ bounds: node_bounds, left: -1, right: -1, start, count: 0 })
  let count = end - start
  let extent = cmax - cmin
  // Pick the longest centroid axis; degenerate extents mean the range is
  // coincident, so a leaf is both correct and cheaper.
  let axis = if extent.x >= extent.y && extent.x >= extent.z {
    0
  } else if extent.y >= extent.z {
    1
  } else {
    2
  }
  let axis_extent = bvh_axis_value(extent, axis)
  if count <= BVH_LEAF_SIZE || depth >= BVH_MAX_DEPTH || axis_extent <= (1.0e-12 : Float) {
    nodes[slot] = { ..nodes[slot], count }
    return slot
  }
  bvh_sort_range(order, start, end, axis, centroids)
  let mid = start + count / 2
  let left = bvh_build_node(mesh, order, centroids, nodes, start, mid, depth + 1)
  let right = bvh_build_node(mesh, order, centroids, nodes, mid, end, depth + 1)
  nodes[slot] = { ..nodes[slot], left, right }
  slot
}

///|
/// Build a BVH for `mesh`. Cost is `O(n log n)` in triangles and memory is
/// roughly `32 bytes * 2 * leaves`; an empty mesh still returns a valid,
/// always-missing BVH.
pub fn MeshBvh::build(mesh : @tgeo.MeshData) -> MeshBvh {
  let n = mesh.triangle_count()
  let order : Array[Int] = []
  let centroids : Array[@tmath.Vec3] = []
  let idx = mesh.indices()
  let pos = mesh.positions()
  for t = 0; t < n; t = t + 1 {
    order.push(t)
    let p0 = pos[idx[t * 3].reinterpret_as_int()]
    let p1 = pos[idx[t * 3 + 1].reinterpret_as_int()]
    let p2 = pos[idx[t * 3 + 2].reinterpret_as_int()]
    centroids.push((p0 + p1 + p2).scale(1.0 / 3.0))
  }
  let nodes : Array[BvhNode] = []
  if n > 0 {
    let _ = bvh_build_node(mesh, order, centroids, nodes, 0, n, 0)
  } else {
    nodes.push({
      bounds: mesh.bounds(),
      left: -1,
      right: -1,
      start: 0,
      count: 0,
    })
  }
  { mesh, triangles: order, nodes, bounds: mesh.bounds() }
}

///|
/// The source mesh this hierarchy indexes.
pub fn MeshBvh::mesh(self : MeshBvh) -> @tgeo.MeshData {
  self.mesh
}

///|
/// Tight local-space bounds of every indexed triangle.
pub fn MeshBvh::bounds(self : MeshBvh) -> @tmath.Aabb3 {
  self.bounds
}

///|
/// Number of triangles covered.
pub fn MeshBvh::triangle_count(self : MeshBvh) -> Int {
  self.triangles.length()
}

///|
/// Number of BVH nodes (interior + leaves); useful for memory sanity checks.
pub fn MeshBvh::node_count(self : MeshBvh) -> Int {
  self.nodes.length()
}

///|
/// Nearest triangle hit under a world-space ray, matching `ray_mesh_hit`.
///
/// The returned `distance` is the world-space distance along a normalized ray,
/// `triangle` is the mesh triangle index and `normal` is the world-space face
/// normal from the normal matrix.
pub fn MeshBvh::ray_hit(
  self : MeshBvh,
  ray : @tmath.Ray,
  world : @tmath.Affine3,
) -> MeshHit? {
  if self.triangles.length() == 0 {
    return None
  }
  match world.inverse() {
    None => None
    Some(inv) => {
      let local_ray = @tmath.Ray::new(
        inv.transform_point3(ray.origin),
        inv.transform_vector3(ray.dir),
      )
      let limits = match local_ray.intersect_aabb(self.bounds) {
        Some(r) => r
        None => return None
      }
      if limits.1 < 0.0 {
        return None
      }
      let nm = match world.normal_matrix() {
        Some(m) => m
        None => world.matrix3
      }
      let idx = self.mesh.indices()
      let pos = self.mesh.positions()
      let mut best : Float = 1.0e30
      let mut best_triangle = -1
      let mut best_normal = @tmath.Vec3::new(0.0, 1.0, 0.0)
      let stack : Array[Int] = [0]
      while stack.length() > 0 {
        let slot = match stack.pop() {
          Some(v) => v
          None => -1
        }
        if slot >= 0 {
          let node = self.nodes[slot]
          if node.count > 0 {
            let last = node.start + node.count
            for k = node.start; k < last; k = k + 1 {
              let tri = self.triangles[k]
              let p0 = pos[idx[tri * 3].reinterpret_as_int()]
              let p1 = pos[idx[tri * 3 + 1].reinterpret_as_int()]
              let p2 = pos[idx[tri * 3 + 2].reinterpret_as_int()]
              match local_ray.intersect_triangle(p0, p1, p2) {
                Some(t) =>
                  if t > 1.0e-6 && t < best {
                    best = t
                    best_triangle = tri
                    let face_n = (p1 - p0).cross(p2 - p0)
                    if face_n.length_sq() > (1.0e-20 : Float) {
                      best_normal = nm.mul_vec3(face_n).normalize()
                    }
                  }
                None => ()
              }
            }
          } else {
            for child in [node.left, node.right] {
              if child >= 0 {
                match local_ray.intersect_aabb(self.nodes[child].bounds) {
                  // Descend only when the child is in front of the eye and
                  // closer than the best hit so far.
                  Some(r) => if r.1 >= 0.0 && r.0 < best {
                    stack.push(child)
                  }
                  None => ()
                }
              }
            }
          }
        }
      }
      if best_triangle < 0 {
        None
      } else {
        Some({
          triangle: best_triangle,
          distance: best,
          position: ray.at(best),
          normal: best_normal,
        })
      }
    }
  }
}
