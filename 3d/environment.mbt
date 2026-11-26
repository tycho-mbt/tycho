// Environment lighting for M0: a procedural LDR cubemap (sky gradient plus a
// sun lobe) in the spirit of examples/49. PMREM prefiltering is a later
// milestone; the shaders currently decode with pow(2.2) and attenuate by
// roughness, which is an explicit interim approximation.

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
fn make_faces(sun_dir : @tmath.Vec3, size : Int) -> Array[Bytes] {
  let faces : Array[Bytes] = []
  for f = 0; f < 6; f = f + 1 {
    let arr = FixedArray::make(size * size * 4, (0 : Byte))
    for y = 0; y < size; y = y + 1 {
      let v = (env_f_of_int(y) + 0.5) / env_f_of_int(size) * 2.0 - 1.0
      for x = 0; x < size; x = x + 1 {
        let u = (env_f_of_int(x) + 0.5) / env_f_of_int(size) * 2.0 - 1.0
        let d = cube_dir(f, u, v)
        let rgb : (Float, Float, Float) = if d.y >= 0.0 {
          let t : Float = d.y
          let rr : Float = 0.85 * (1.0 - t) + 0.16 * t
          let gg : Float = 0.58 * (1.0 - t) + 0.34 * t
          let bb : Float = 0.42 * (1.0 - t) + 0.78 * t
          let sd = d.dot(sun_dir)
          let sun : Float = if sd > 0.0 {
            sd * sd * sd * sd * sd * sd * 0.45
          } else {
            0.0
          }
          (rr + sun, gg + sun * 0.9, bb + sun * 0.6)
        } else {
          let t : Float = -d.y
          let r0 : Float = 0.26 * (1.0 - t) + 0.09 * t
          let g0 : Float = 0.24 * (1.0 - t) + 0.10 * t
          let b0 : Float = 0.28 * (1.0 - t) + 0.13 * t
          (r0, g0, b0)
        }
        let (r, g, b) = rgb
        let i = (y * size + x) * 4
        arr[i] = clamp255(r)
        arr[i + 1] = clamp255(g)
        arr[i + 2] = clamp255(b)
        arr[i + 3] = (255 : Byte)
      }
    }
    faces.push(Bytes::from_array(arr))
  }
  faces
}

///|
/// Create a procedural sky cubemap (RGBA8, LDR, gamma-decoded by the shaders).
pub fn procedural_environment_cubemap(
  dev : @tycho.Device,
  sun_dir : @tmath.Vec3,
  size? : Int = 32,
) -> @tycho.Texture raise {
  let s = if size < 1 { 1 } else { size }
  dev.create_cubemap(s, @tycho.TextureFormat::RGBA8, make_faces(sun_dir, s))
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
