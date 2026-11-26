// std140 / std430 layout writer.
//
// Hand-computing UBO offsets and padding is the classic source of "my matrix is
// garbage on screen" bugs. `GpuPackWriter` owns a pre-allocated `Float` scratch
// buffer, aligns every push according to the selected layout, and gives you a
// `FixedArray[Float]` ready for `Buffer::upload_floats`.

///|
/// Uniform/storage buffer layout rules.
#derive(Eq, Debug)
pub(all) enum GpuLayout {
  /// std140: every array/struct member is padded to 16-byte boundaries.
  Std140
  /// std430 (SSBO): tighter packing, `vec3` keeps a 16-byte alignment but no
  /// tail padding is inserted before the next member.
  Std430
}

///|
pub struct GpuPackWriter {
  mut buf : FixedArray[Float]
  mut len : Int
  layout : GpuLayout
}

///|
/// Create a std140 writer with room for `float_capacity` floats. The buffer
/// grows automatically if more data is pushed.
pub fn GpuPackWriter::new(float_capacity : Int) -> GpuPackWriter {
  GpuPackWriter::std140(float_capacity)
}

///|
pub fn GpuPackWriter::std140(float_capacity : Int) -> GpuPackWriter {
  {
    buf: FixedArray::make(
      if float_capacity > 0 { float_capacity } else { 16 },
      (0.0 : Float),
    ),
    len: 0,
    layout: Std140,
  }
}

///|
pub fn GpuPackWriter::std430(float_capacity : Int) -> GpuPackWriter {
  {
    buf: FixedArray::make(
      if float_capacity > 0 { float_capacity } else { 16 },
      (0.0 : Float),
    ),
    len: 0,
    layout: Std430,
  }
}

///|
pub fn GpuPackWriter::layout(self : GpuPackWriter) -> GpuLayout {
  self.layout
}

///|
/// Reset the write cursor; the underlying buffer is reused (no allocation).
pub fn GpuPackWriter::reset(self : GpuPackWriter) -> Unit {
  self.len = 0
}

///|
/// Number of floats written so far.
pub fn GpuPackWriter::length(self : GpuPackWriter) -> Int {
  self.len
}

///|
fn GpuPackWriter::grow(self : GpuPackWriter, need : Int) -> Unit {
  if need <= self.buf.length() {
    return
  }
  let mut cap = if self.buf.length() > 0 { self.buf.length() } else { 16 }
  while cap < need {
    cap = cap * 2
  }
  let next : FixedArray[Float] = FixedArray::make(cap, (0.0 : Float))
  for i = 0; i < self.len; i = i + 1 {
    next[i] = self.buf[i]
  }
  self.buf = next
}

///|
fn GpuPackWriter::align_to(self : GpuPackWriter, floats : Int) -> Unit {
  let rem = self.len % floats
  if rem != 0 {
    let pad = floats - rem
    for i = 0; i < pad; i = i + 1 {
      self.push_raw(0.0)
    }
  }
}

///|
fn GpuPackWriter::push_raw(self : GpuPackWriter, v : Float) -> Unit {
  self.grow(self.len + 1)
  self.buf[self.len] = v
  self.len = self.len + 1
}

///|
pub fn GpuPackWriter::push_float(self : GpuPackWriter, v : Float) -> Unit {
  self.align_to(1)
  self.push_raw(v)
}

///|
pub fn GpuPackWriter::push_vec2(self : GpuPackWriter, v : Vec2) -> Unit {
  self.align_to(2)
  self.push_raw(v.x)
  self.push_raw(v.y)
}

///|
/// Push a `vec3`: 4 floats (one explicit/implicit pad) in std140, 3 floats in
/// std430. The next `push_*` realigns as needed.
pub fn GpuPackWriter::push_vec3(self : GpuPackWriter, v : Vec3) -> Unit {
  self.align_to(4)
  self.push_raw(v.x)
  self.push_raw(v.y)
  self.push_raw(v.z)
  if self.layout == Std140 {
    self.push_raw(0.0)
  }
}

///|
/// Push a `vec3` padded to 16 bytes regardless of layout.
pub fn GpuPackWriter::push_vec3_padded(
  self : GpuPackWriter,
  v : Vec3,
  pad? : Float = 0.0,
) -> Unit {
  self.align_to(4)
  self.push_raw(v.x)
  self.push_raw(v.y)
  self.push_raw(v.z)
  self.push_raw(pad)
}

///|
pub fn GpuPackWriter::push_vec4(self : GpuPackWriter, v : Vec4) -> Unit {
  self.align_to(4)
  self.push_raw(v.x)
  self.push_raw(v.y)
  self.push_raw(v.z)
  self.push_raw(v.w)
}

///|
/// Push a `mat4` as 16 column-major floats (byte-identical to GPU `mat4`).
pub fn GpuPackWriter::push_mat4(self : GpuPackWriter, m : Mat4) -> Unit {
  self.align_to(4)
  self.grow(self.len + 16)
  m.write_to(self.buf, self.len)
  self.len = self.len + 16
}

///|
/// Push a `mat3`: 12 floats (three columns each padded to 16 bytes), which is
/// valid for both std140 and std430.
pub fn GpuPackWriter::push_mat3(self : GpuPackWriter, m : Mat3) -> Unit {
  self.push_vec3_padded(m.x_axis)
  self.push_vec3_padded(m.y_axis)
  self.push_vec3_padded(m.z_axis)
}

///|
/// Push a `mat2`: 8 floats in std140 (columns padded to 16 bytes) or 4 floats
/// in std430.
pub fn GpuPackWriter::push_mat2(self : GpuPackWriter, m : Mat2) -> Unit {
  if self.layout == Std140 {
    // Each column occupies a full 16-byte slot under std140.
    self.push_vec4(Vec4::new(m.x_axis.x, m.x_axis.y, 0.0, 0.0))
    self.push_vec4(Vec4::new(m.y_axis.x, m.y_axis.y, 0.0, 0.0))
  } else {
    self.push_vec2(m.x_axis)
    self.push_vec2(m.y_axis)
  }
}

///|
/// Push the translation column of an affine transform as a `vec4` with `w = 1`.
pub fn GpuPackWriter::push_affine_translation(self : GpuPackWriter, a : Affine3) -> Unit {
  self.push_vec4(a.translation.extend_w(1.0))
}

///|
/// Copy of exactly the written floats (never the whole backing buffer).
pub fn GpuPackWriter::as_floats(self : GpuPackWriter) -> FixedArray[Float] {
  let out : FixedArray[Float] = FixedArray::make(self.len, (0.0 : Float))
  for i = 0; i < self.len; i = i + 1 {
    out[i] = self.buf[i]
  }
  out
}

///|
/// Borrow the backing buffer without copying. Only the first `length()` floats
/// are meaningful.
pub fn GpuPackWriter::buffer(self : GpuPackWriter) -> FixedArray[Float] {
  self.buf
}
