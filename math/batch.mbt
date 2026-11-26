// Explicit batch kernels over contiguous arrays.
//
// These are ordinary scalar loops for now; they exist as a stable, allocation
// free surface so a future MoonBit `V128` kernel (or the optional
// `tycho_math_simd` package) can be swapped in without changing any public
// signature. Call them when you already have (or can build) `FixedArray`s of
// hundreds or thousands of elements, e.g. skinning palettes or instance
// culling.

///|
fn min_count4(a : Int, b : Int, c : Int, d : Int) -> Int {
  let m0 = if a < b { a } else { b }
  let m1 = if c < d { c } else { d }
  if m0 < m1 {
    m0
  } else {
    m1
  }
}

///|
/// `dst[i] = a[i] * b[i]` for the first `count` elements (clamped to the
/// shortest array).
pub fn batch_mul_mat4(
  dst : FixedArray[Mat4],
  a : FixedArray[Mat4],
  b : FixedArray[Mat4],
  count : Int,
) -> Unit {
  let n = min_count4(count, dst.length(), a.length(), b.length())
  for i = 0; i < n; i = i + 1 {
    dst[i] = a[i] * b[i]
  }
}

///|
/// `dst[i] = mat * src[i]` for the first `count` points.
pub fn batch_transform_points3(
  dst : FixedArray[Vec3],
  mat : Mat4,
  src : FixedArray[Vec3],
  count : Int,
) -> Unit {
  let n = min_count4(count, dst.length(), src.length(), src.length())
  for i = 0; i < n; i = i + 1 {
    dst[i] = mat.transform_point3(src[i])
  }
}

///|
/// `dst[i] = affine * src[i]` for the first `count` points.
pub fn batch_transform_points3_affine(
  dst : FixedArray[Vec3],
  affine : Affine3,
  src : FixedArray[Vec3],
  count : Int,
) -> Unit {
  let n = min_count4(count, dst.length(), src.length(), src.length())
  for i = 0; i < n; i = i + 1 {
    dst[i] = affine.transform_point3(src[i])
  }
}

///|
/// Write `true`/`false` visibility flags and return how many boxes are visible.
pub fn batch_frustum_cull(
  visible : FixedArray[Bool],
  frustum : Frustum,
  boxes : FixedArray[Aabb3],
  count : Int,
) -> Int {
  let n = min_count4(count, visible.length(), boxes.length(), boxes.length())
  let mut hits = 0
  for i = 0; i < n; i = i + 1 {
    let keep = frustum.intersects_aabb(boxes[i])
    visible[i] = keep
    if keep {
      hits = hits + 1
    }
  }
  hits
}

///|
/// `dst[i] = q * src[i]` for the first `count` vectors.
pub fn batch_rotate_vec3(
  dst : FixedArray[Vec3],
  q : Quat,
  src : FixedArray[Vec3],
  count : Int,
) -> Unit {
  let n = min_count4(count, dst.length(), src.length(), src.length())
  for i = 0; i < n; i = i + 1 {
    dst[i] = q.mul_vec3(src[i])
  }
}
