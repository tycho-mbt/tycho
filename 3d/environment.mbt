// Environment lighting: a procedural linear sky, GGX-prefiltered into a
// cubemap mip chain (a PMREM approximation). Mip 0 is the sharp sky; the last
// mip is a near-diffuse irradiance average. The PBR shader samples
// `textureLod(uEnv, R, roughness * maxLod)`, so no gamma hack is needed.

///|
fn env_f_of_int(i : Int) -> Float {
  Float::from_double(i.to_double())
}

///|
fn cube_dir(face : Int, u : Float, v : Float) -> @tmath.Vec3 {
  let raw = match face {
    0 => @tmath.Vec3::new(1.0, -v, -u)
    1 => @tmath.Vec3::new(-1.0, -v, u)
    2 => @tmath.Vec3::new(u, 1.0, v)
    3 => @tmath.Vec3::new(u, -1.0, -v)
    4 => @tmath.Vec3::new(u, -v, 1.0)
    _ => @tmath.Vec3::new(-u, -v, -1.0)
  }
  raw.normalize()
}

///|
fn dir_face_uv(d : @tmath.Vec3) -> (Int, Float, Float) {
  let ax = d.x.abs()
  let ay = d.y.abs()
  let az = d.z.abs()
  if ax >= ay && ax >= az {
    if d.x > 0.0 {
      (0, -d.z / ax, -d.y / ax)
    } else {
      (1, d.z / ax, -d.y / ax)
    }
  } else if ay >= az {
    if d.y > 0.0 {
      (2, d.x / ay, d.z / ay)
    } else {
      (3, d.x / ay, -d.z / ay)
    }
  } else if d.z > 0.0 {
    (4, d.x / az, -d.y / az)
  } else {
    (5, -d.x / az, -d.y / az)
  }
}

///|
fn clamp255(val : Float) -> Byte {
  let c : Float = if val < 0.0 {
    0.0
  } else if val > 1.0 {
    1.0
  } else {
    val
  }
  (c * (255.0 : Float)).to_int().to_byte()
}

///|
fn clamp_index(i : Int, n : Int) -> Int {
  if i < 0 {
    0
  } else if i >= n {
    n - 1
  } else {
    i
  }
}

///|
/// Authored sRGB sky (gradient plus sun lobe), converted to linear.
fn env_sky(dir : @tmath.Vec3, sun_dir : @tmath.Vec3) -> (Float, Float, Float) {
  let rgb : (Float, Float, Float) = if dir.y >= 0.0 {
    let t : Float = dir.y
    let rr : Float = 0.85 * (1.0 - t) + 0.16 * t
    let gg : Float = 0.58 * (1.0 - t) + 0.34 * t
    let bb : Float = 0.42 * (1.0 - t) + 0.78 * t
    let sd = dir.dot(sun_dir)
    let sun : Float = if sd > 0.0 {
      sd * sd * sd * sd * sd * sd * 0.45
    } else {
      0.0
    }
    (rr + sun, gg + sun * 0.9, bb + sun * 0.6)
  } else {
    let t : Float = -dir.y
    let r0 : Float = 0.26 * (1.0 - t) + 0.09 * t
    let g0 : Float = 0.24 * (1.0 - t) + 0.10 * t
    let b0 : Float = 0.28 * (1.0 - t) + 0.13 * t
    (r0, g0, b0)
  }
  let (r, g, b) = rgb
  (srgb_to_linear(r), srgb_to_linear(g), srgb_to_linear(b))
}

///|
fn make_faces_linear(
  sun_dir : @tmath.Vec3,
  size : Int,
) -> Array[FixedArray[Float]] {
  let faces : Array[FixedArray[Float]] = []
  for f = 0; f < 6; f = f + 1 {
    let buf = FixedArray::make(size * size * 3, (0.0 : Float))
    for y = 0; y < size; y = y + 1 {
      let v = (env_f_of_int(y) + 0.5) / env_f_of_int(size) * 2.0 - 1.0
      for x = 0; x < size; x = x + 1 {
        let u = (env_f_of_int(x) + 0.5) / env_f_of_int(size) * 2.0 - 1.0
        let d = cube_dir(f, u, v)
        let (r, g, b) = env_sky(d, sun_dir)
        let o = (y * size + x) * 3
        buf[o] = r
        buf[o + 1] = g
        buf[o + 2] = b
      }
    }
    faces.push(buf)
  }
  faces
}

///|
fn sample_cube(
  faces : Array[FixedArray[Float]],
  size : Int,
  d : @tmath.Vec3,
) -> (Float, Float, Float) {
  let (f, u, v) = dir_face_uv(d)
  let fs = env_f_of_int(size)
  let fx = (u + 1.0) * 0.5 * fs - 0.5
  let fy = (v + 1.0) * 0.5 * fs - 0.5
  let xi = fx.to_double().to_int()
  let yi = fy.to_double().to_int()
  let tx = fx - env_f_of_int(xi)
  let ty = fy - env_f_of_int(yi)
  let x0 = clamp_index(xi, size)
  let x1 = clamp_index(xi + 1, size)
  let y0 = clamp_index(yi, size)
  let y1 = clamp_index(yi + 1, size)
  let buf = faces[f]
  let i00 = (y0 * size + x0) * 3
  let i10 = (y0 * size + x1) * 3
  let i01 = (y1 * size + x0) * 3
  let i11 = (y1 * size + x1) * 3
  let w00 : Float = (1.0 - tx) * (1.0 - ty)
  let w10 : Float = tx * (1.0 - ty)
  let w01 : Float = (1.0 - tx) * ty
  let w11 : Float = tx * ty
  (
    buf[i00] * w00 + buf[i10] * w10 + buf[i01] * w01 + buf[i11] * w11,
    buf[i00 + 1] * w00 + buf[i10 + 1] * w10 + buf[i01 + 1] * w01 + buf[i11 + 1] * w11,
    buf[i00 + 2] * w00 + buf[i10 + 2] * w10 + buf[i01 + 2] * w01 + buf[i11 + 2] * w11,
  )
}

///|
fn radical_inverse_vdc(bits_in : UInt) -> Float {
  let mut bits = bits_in
  bits = (bits << 16) | (bits >> 16)
  bits = ((bits & (0x55555555 : UInt)) << 1) | ((bits & (0xAAAAAAAA : UInt)) >> 1)
  bits = ((bits & (0x33333333 : UInt)) << 2) | ((bits & (0xCCCCCCCC : UInt)) >> 2)
  bits = ((bits & (0x0F0F0F0F : UInt)) << 4) | ((bits & (0xF0F0F0F0 : UInt)) >> 4)
  bits = ((bits & (0x00FF00FF : UInt)) << 8) | ((bits & (0xFF00FF00 : UInt)) >> 8)
  env_f_of_int((bits >> 8).reinterpret_as_int()) * (1.0 / 16777216.0)
}

///|
fn env_mip_count(size : Int) -> Int {
  let mut s = size
  let mut n = 1
  while s > 1 {
    s = s / 2
    n = n + 1
  }
  n
}

///|
/// GGX importance-sampled prefilter. Mip `m` uses roughness `m / (mips - 1)`;
/// mip 0 is a straight copy so sharp reflections stay exact.
fn prefilter_cubemap(
  base : Array[FixedArray[Float]],
  size : Int,
  mips : Int,
) -> Array[Array[FixedArray[Float]]] {
  let levels : Array[Array[FixedArray[Float]]] = []
  let copy : Array[FixedArray[Float]] = []
  for f = 0; f < 6; f = f + 1 {
    let src = base[f]
    let dst = FixedArray::make(size * size * 3, (0.0 : Float))
    for i = 0; i < src.length(); i = i + 1 {
      dst[i] = src[i]
    }
    copy.push(dst)
  }
  levels.push(copy)
  let samples = 32
  for m = 1; m < mips; m = m + 1 {
    let s = if size >> m < 1 { 1 } else { size >> m }
    let roughness = env_f_of_int(m) / env_f_of_int(mips - 1)
    let a : Float = roughness * roughness
    let a2 : Float = a * a
    let faces : Array[FixedArray[Float]] = []
    for f = 0; f < 6; f = f + 1 {
      let out = FixedArray::make(s * s * 3, (0.0 : Float))
      for y = 0; y < s; y = y + 1 {
        let v = (env_f_of_int(y) + 0.5) / env_f_of_int(s) * 2.0 - 1.0
        for x = 0; x < s; x = x + 1 {
          let u = (env_f_of_int(x) + 0.5) / env_f_of_int(s) * 2.0 - 1.0
          let n = cube_dir(f, u, v)
          let up = if n.z.abs() < 0.999 {
            @tmath.Vec3::unit_z()
          } else {
            @tmath.Vec3::unit_x()
          }
          let t = up.cross(n).normalize()
          let bt = n.cross(t)
          let mut sr : Float = 0.0
          let mut sg : Float = 0.0
          let mut sb : Float = 0.0
          let mut weight : Float = 0.0
          for i = 0; i < samples; i = i + 1 {
            let xi1 = env_f_of_int(i) / env_f_of_int(samples)
            let xi2 = radical_inverse_vdc(i.reinterpret_as_uint())
            let phi = xi1 * @tmath.TAU
            let cos_theta = @tmath.sqrt(
              (1.0 - xi2) / (1.0 + (a2 - 1.0) * xi2),
            )
            let sin_sq : Float = 1.0 - cos_theta * cos_theta
            let sin_theta : Float = @tmath.sqrt(
              if sin_sq < (0.0 : Float) { (0.0 : Float) } else { sin_sq },
            )
            let (sp, cp) = @tmath.sin_cos(phi)
            let lt = t.scale(cp * sin_theta)
            let lb = bt.scale(sp * sin_theta)
            let ln = n.scale(cos_theta)
            let l = lt + lb + ln
            let ndotl = n.dot(l)
            if ndotl > (1.0e-4 : Float) {
              let (cr, cg, cb) = sample_cube(base, size, l)
              sr = sr + cr * ndotl
              sg = sg + cg * ndotl
              sb = sb + cb * ndotl
              weight = weight + ndotl
            }
          }
          let o = (y * s + x) * 3
          if weight > 0.0 {
            out[o] = sr / weight
            out[o + 1] = sg / weight
            out[o + 2] = sb / weight
          }
        }
      }
      faces.push(out)
    }
    levels.push(faces)
  }
  levels
}

///|
fn encode_face(buf : FixedArray[Float], size : Int) -> Bytes {
  let arr = FixedArray::make(size * size * 4, (0 : Byte))
  for i = 0; i < size * size; i = i + 1 {
    arr[i * 4] = clamp255(buf[i * 3])
    arr[i * 4 + 1] = clamp255(buf[i * 3 + 1])
    arr[i * 4 + 2] = clamp255(buf[i * 3 + 2])
    arr[i * 4 + 3] = (255 : Byte)
  }
  Bytes::from_array(arr)
}

///|
/// Create a procedural sky cubemap with a GGX-prefiltered mip chain.
/// Values are stored linear in RGBA8; shaders sample with `textureLod`.
pub fn procedural_environment_cubemap(
  dev : @tycho.Device,
  sun_dir : @tmath.Vec3,
  size? : Int = 64,
) -> @tycho.Texture raise {
  let s = if size < 4 { 4 } else { size }
  let base = make_faces_linear(sun_dir, s)
  let mips = env_mip_count(s)
  let filtered = prefilter_cubemap(base, s, mips)
  let levels : Array[Array[Bytes]] = []
  for m = 0; m < mips; m = m + 1 {
    let ms = if s >> m < 1 { 1 } else { s >> m }
    let faces : Array[Bytes] = []
    for f = 0; f < 6; f = f + 1 {
      faces.push(encode_face(filtered[m][f], ms))
    }
    levels.push(faces)
  }
  dev.create_cubemap_mipmapped(s, @tycho.TextureFormat::RGBA8, levels)
}

///|
/// A tiny dark cube used when the user never sets an environment, so the
/// shaders always have a valid `samplerCube` binding.
pub fn default_environment_cubemap(dev : @tycho.Device) -> @tycho.Texture raise {
  let faces : Array[Bytes] = []
  for i = 0; i < 6; i = i + 1 {
    let _ = i
    faces.push(Bytes::from_array([(8 : Byte), (10 : Byte), (16 : Byte), (255 : Byte)]))
  }
  dev.create_cubemap(1, @tycho.TextureFormat::RGBA8, faces)
}
