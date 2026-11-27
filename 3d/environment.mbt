// Environment lighting: a procedural linear sky, GGX-prefiltered on the GPU
// into a cubemap mip chain (PMREM approximation). Mip 0 is the sharp sky; the
// last mip is a near-diffuse irradiance average. The PBR shader samples
// `textureLod(uEnv, R, roughness * maxLod)`.
//
// Prefiltering renders each face of each mip into a 6*s x s strip, reads the
// strip back and assembles the final mip chain on the CPU. That keeps the
// expensive GGX integration (hundreds of samples) on the GPU while reusing the
// existing cubemap upload path.

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
fn push_f16(arr : Array[Byte], v : Float) -> Unit {
  let bits = f16_bits(v).to_uint()
  arr.push((bits & (0xFF : UInt)).to_byte())
  arr.push(((bits >> 8) & (0xFF : UInt)).to_byte())
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
/// Pack a linear RGB face into RGBA16F (alpha = 1), preserving HDR values.
fn encode_face(buf : FixedArray[Float], size : Int) -> Bytes {
  let arr : Array[Byte] = []
  for i = 0; i < size * size; i = i + 1 {
    push_f16(arr, buf[i * 3])
    push_f16(arr, buf[i * 3 + 1])
    push_f16(arr, buf[i * 3 + 2])
    push_f16(arr, 1.0)
  }
  Bytes::from_array(arr)
}

///|
fn encode_faces(faces : Array[FixedArray[Float]], size : Int) -> Array[Bytes] {
  let out : Array[Bytes] = []
  for f = 0; f < 6; f = f + 1 {
    out.push(encode_face(faces[f], size))
  }
  out
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
/// Cut the six faces out of a `6*s` wide render-target readback.
fn extract_faces(
  px : FixedArray[Byte],
  strip_w : Int,
  s : Int,
  bpp : Int,
) -> Array[Bytes] {
  let faces : Array[Bytes] = []
  for f = 0; f < 6; f = f + 1 {
    let arr = FixedArray::make(s * s * bpp, (0 : Byte))
    for y = 0; y < s; y = y + 1 {
      let src_row = y * strip_w * bpp + f * s * bpp
      let dst_row = y * s * bpp
      for i = 0; i < s * bpp; i = i + 1 {
        arr[dst_row + i] = px[src_row + i]
      }
    }
    faces.push(Bytes::from_array(arr))
  }
  faces
}

///|
/// Bilinear sample of an equirectangular linear image along `dir`.
fn equirect_sample(
  img : HdrImage,
  dir : @tmath.Vec3,
) -> (Float, Float, Float) {
  let (u, v) = equirect_uv(dir)
  let w = img.width
  let h = img.height
  let fx = u * env_f_of_int(w) - 0.5
  let fy = v * env_f_of_int(h) - 0.5
  let mut x0 = fx.to_int()
  if x0 < 0 {
    x0 = 0
  }
  if x0 >= w {
    x0 = w - 1
  }
  let mut y0 = fy.to_int()
  if y0 < 0 {
    y0 = 0
  }
  if y0 >= h {
    y0 = h - 1
  }
  let x1 = (x0 + 1) % w
  let y1 = if y0 + 1 < h { y0 + 1 } else { y0 }
  let tx : Float = fx - env_f_of_int(x0)
  let ty : Float = fy - env_f_of_int(y0)
  let (r00, g00, b00) = img.pixel(x0, y0)
  let (r10, g10, b10) = img.pixel(x1, y0)
  let (r01, g01, b01) = img.pixel(x0, y1)
  let (r11, g11, b11) = img.pixel(x1, y1)
  let lerp2 = fn(a : Float, b : Float, c : Float, d : Float) -> Float {
    let top = a + (b - a) * tx
    let bot = c + (d - c) * tx
    top + (bot - top) * ty
  }
  (lerp2(r00, r10, r01, r11), lerp2(g00, g10, g01, g11), lerp2(b00, b10, b01, b11))
}

///|
fn equirect_faces_linear(img : HdrImage, size : Int) -> Array[FixedArray[Float]] {
  let faces : Array[FixedArray[Float]] = []
  for f = 0; f < 6; f = f + 1 {
    let buf = FixedArray::make(size * size * 3, (0.0 : Float))
    for y = 0; y < size; y = y + 1 {
      let v = (env_f_of_int(y) + 0.5) / env_f_of_int(size) * 2.0 - 1.0
      for x = 0; x < size; x = x + 1 {
        let u = (env_f_of_int(x) + 0.5) / env_f_of_int(size) * 2.0 - 1.0
        let d = cube_dir(f, u, v)
        let (r, g, b) = equirect_sample(img, d)
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
/// GGX-prefilter linear faces into an RGBA16F cubemap mip chain. Mip 0 is the
/// sharp source; each later mip integrates more roughness samples on the GPU.
fn prefilter_cubemap(
  dev : @tycho.Device,
  base_faces : Array[FixedArray[Float]],
  s : Int,
  samples : Int,
) -> @tycho.Texture raise {
  let sample_count = if samples < 8 { 8 } else { samples }
  let fmt = @tycho.TextureFormat::RGBA16F
  let base_bytes = encode_faces(base_faces, s)
  let src = dev.create_cubemap(s, fmt, base_bytes)
  let src_sampler = dev.create_sampler_desc(
    @tycho.SamplerDesc::new(
      mag=@tycho.Filter::Linear,
      min=@tycho.Filter::Linear,
      mipmap=@tycho.Filter::Linear,
      address=@tycho.AddressMode::ClampToEdge,
    ),
  )
  let pipe = dev.create_graphics_pipeline(
    @tycho.PipelineDesc::from_spirv(
      spv_prefilter_vert,
      spv_prefilter_frag,
      color_format=fmt,
    ),
  )
  let mips = env_mip_count(s)
  let levels : Array[Array[Bytes]] = [base_bytes]
  for m = 1; m < mips; m = m + 1 {
    let ms = if s >> m < 1 { 1 } else { s >> m }
    let rt = dev.create_render_target(6 * ms, ms, fmt)
    let cmd = dev.begin_commands()
    cmd.begin_render_pass(
      [
        @tycho.RenderTargetDesc::new(
          rt,
          load_op=@tycho.LoadOp::Clear,
          store_op=@tycho.StoreOp::Store,
          clear_color=@tycho.ClearColor::black(),
        ),
      ],
    )
    cmd.bind_pipeline(pipe)
    cmd.bind_texture(pipe, 0, src, src_sampler)
    let roughness = env_f_of_int(m) / env_f_of_int(mips - 1)
    for f = 0; f < 6; f = f + 1 {
      cmd.set_viewport(env_f_of_int(f * ms), 0.0, env_f_of_int(ms), env_f_of_int(ms))
      cmd.set_scissor(f * ms, 0, ms, ms)
      cmd.push_constants_floats(
        pipe,
        [
          env_f_of_int(f),
          roughness,
          env_f_of_int(sample_count),
          env_f_of_int(ms),
        ],
      )
      cmd.draw(3, 1)
    }
    cmd.end_render_pass()
    dev.end_commands(cmd)
    let px = rt.readback()
    levels.push(extract_faces(px, 6 * ms, ms, 8))
    rt.destroy()
  }
  pipe.destroy()
  src_sampler.destroy()
  src.destroy()
  dev.create_cubemap_mipmapped(s, fmt, levels)
}

///|
/// Create a procedural sky cubemap with a GPU-prefiltered mip chain.
/// `size` is the base face resolution (256 by default); `samples` is the GGX
/// integration sample count per texel per mip (128 by default).
pub fn procedural_environment_cubemap(
  dev : @tycho.Device,
  sun_dir : @tmath.Vec3,
  size? : Int = 256,
  samples? : Int = 128,
) -> @tycho.Texture raise {
  let s = if size < 16 { 16 } else { size }
  prefilter_cubemap(dev, make_faces_linear(sun_dir, s), s, samples)
}

///|
/// Build a GGX-prefiltered RGBA16F environment cubemap from a linear HDR
/// equirectangular image (see `decode_hdr`). Values above 1.0 survive, so the
/// sun keeps its energy through the mip chain.
pub fn equirect_environment_cubemap(
  dev : @tycho.Device,
  image : HdrImage,
  size? : Int = 256,
  samples? : Int = 128,
) -> @tycho.Texture raise {
  let s = if size < 16 { 16 } else { size }
  prefilter_cubemap(dev, equirect_faces_linear(image, s), s, samples)
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
