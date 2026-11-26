// Normal and tangent generation for `MeshData`.

///|
/// Area-weighted smooth vertex normals. Triangles are assumed to be CCW when
/// seen from the front (the package-wide convention), so the un-normalized
/// cross product points outward.
pub fn MeshData::compute_vertex_normals(self : MeshData) -> Unit {
  let n = self.positions.length()
  if n == 0 {
    return
  }
  let acc : FixedArray[@tmath.Vec3] = FixedArray::make(n, @tmath.Vec3::zero())
  let ic = self.indices.length()
  let mut i = 0
  while i + 2 < ic {
    let i0 = self.indices[i].reinterpret_as_int()
    let i1 = self.indices[i + 1].reinterpret_as_int()
    let i2 = self.indices[i + 2].reinterpret_as_int()
    let a = self.positions[i0]
    let b = self.positions[i1]
    let c = self.positions[i2]
    // Not normalized: the length is twice the triangle area, which is exactly
    // the area weight we want when accumulating.
    let face_n = (b - a).cross(c - a)
    acc[i0] = acc[i0] + face_n
    acc[i1] = acc[i1] + face_n
    acc[i2] = acc[i2] + face_n
    i = i + 3
  }
  let out : FixedArray[@tmath.Vec3] = FixedArray::make(n, @tmath.Vec3::zero())
  for j = 0; j < n; j = j + 1 {
    out[j] = acc[j].normalize()
  }
  self.normals = out
}

///|
/// Per-vertex tangents (Lengyel's method), orthonormalized against the normals.
/// Requires UVs; degenerate UV triangles are skipped and fall back to any
/// orthonormal vector. `w` stores the bitangent handedness sign.
pub fn MeshData::compute_tangents(self : MeshData) -> Unit {
  let n = self.positions.length()
  if n == 0 {
    return
  }
  let tan : FixedArray[@tmath.Vec3] = FixedArray::make(n, @tmath.Vec3::zero())
  let bit : FixedArray[@tmath.Vec3] = FixedArray::make(n, @tmath.Vec3::zero())
  let ic = self.indices.length()
  let mut i = 0
  while i + 2 < ic {
    let i0 = self.indices[i].reinterpret_as_int()
    let i1 = self.indices[i + 1].reinterpret_as_int()
    let i2 = self.indices[i + 2].reinterpret_as_int()
    let p0 = self.positions[i0]
    let e1 = self.positions[i1] - p0
    let e2 = self.positions[i2] - p0
    let duv1 = self.uvs[i1] - self.uvs[i0]
    let duv2 = self.uvs[i2] - self.uvs[i0]
    let r = duv1.x * duv2.y - duv2.x * duv1.y
    if r.abs() > (1.0e-12 : Float) {
      let f : Float = 1.0 / r
      let t = (e1.scale(duv2.y) - e2.scale(duv1.y)).scale(f)
      let bt = (e2.scale(duv1.x) - e1.scale(duv2.x)).scale(f)
      tan[i0] = tan[i0] + t
      tan[i1] = tan[i1] + t
      tan[i2] = tan[i2] + t
      bit[i0] = bit[i0] + bt
      bit[i1] = bit[i1] + bt
      bit[i2] = bit[i2] + bt
    }
    i = i + 3
  }
  let out : FixedArray[@tmath.Vec4] = FixedArray::make(
    n,
    @tmath.Vec4::new(0.0, 0.0, 0.0, 1.0),
  )
  for j = 0; j < n; j = j + 1 {
    let nrm = self.normals[j]
    let t = tan[j]
    let proj = t - nrm.scale(nrm.dot(t))
    let t_ortho = match proj.try_normalize() {
      Some(v) => v
      None => nrm.any_orthonormal()
    }
    let w : Float = if nrm.cross(t_ortho).dot(bit[j]) < 0.0 {
      -1.0
    } else {
      1.0
    }
    out[j] = @tmath.Vec4::new(t_ortho.x, t_ortho.y, t_ortho.z, w)
  }
  self.tangents = Some(out)
}
