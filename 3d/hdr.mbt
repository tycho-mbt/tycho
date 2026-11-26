// Radiance RGBE (.hdr) decoding/encoding plus float16 packing.
//
// Real HDR assets feed the IBL chain, so the decoder handles both the classic
// adaptive-RLE and flat scanline layouts and honours the -Y/+Y, +X/-X
// orientation flags. `f16_bits` converts linear floats into the RGBA16F texels
// used by the environment cubemap, keeping values above 1.0 (the sun) intact.

///|
/// Linear RGB image decoded from a Radiance `.hdr` file.
pub(all) struct HdrImage {
  width : Int
  height : Int
  rgb : FixedArray[Float]
}

///|
pub fn HdrImage::new(width : Int, height : Int) -> HdrImage {
  {
    width,
    height,
    rgb: FixedArray::make(width * height * 3, (0.0 : Float)),
  }
}

///|
pub fn HdrImage::pixel(
  self : HdrImage,
  x : Int,
  y : Int,
) -> (Float, Float, Float) {
  let o = (y * self.width + x) * 3
  (self.rgb[o], self.rgb[o + 1], self.rgb[o + 2])
}

///|
pub fn HdrImage::set_pixel(
  self : HdrImage,
  x : Int,
  y : Int,
  r : Float,
  g : Float,
  b : Float,
) -> Unit {
  let o = (y * self.width + x) * 3
  self.rgb[o] = r
  self.rgb[o + 1] = g
  self.rgb[o + 2] = b
}

///|
/// Equirectangular UV for a world direction: `u` wraps around +Y (`0.5` looks
/// along +Z) and `v` is 0 at the zenith, 1 at the nadir.
pub fn equirect_uv(dir : @tmath.Vec3) -> (Float, Float) {
  let u = (0.5 : Float) + @tmath.atan2(dir.x, dir.z) / (2.0 * @tmath.PI)
  let y : Float = if dir.y > 1.0 {
    1.0
  } else if dir.y < (-1.0 : Float) {
    -1.0
  } else {
    dir.y
  }
  (u, v_of_acos(y))
}

///|
fn v_of_acos(y : Float) -> Float {
  @tmath.acos(y) / @tmath.PI
}

///|
/// IEEE binary16 bits, round-to-nearest on the top mantissa bit. Values below
/// 2^-14 flush to zero (environment texels are never that dark in practice).
pub fn f16_bits(v : Float) -> UInt16 {
  let d = v.to_double().reinterpret_as_uint64()
  let sign : Int = ((d >> 63) & (1 : UInt64)).to_uint().reinterpret_as_int() << 15
  let exp : Int = ((d >> 52) & (0x7FF : UInt64)).to_uint().reinterpret_as_int()
  let man : UInt64 = d & (0xFFFFFFFFFFFFF : UInt64)
  let e = exp - 1023
  if e > 15 {
    return (sign | 0x7C00).to_uint16()
  }
  if e < -14 {
    return sign.to_uint16()
  }
  let mut m : Int = ((man >> 42) & (0x3FF : UInt64)).to_uint().reinterpret_as_int()
  let round : Int = ((man >> 41) & (1 : UInt64)).to_uint().reinterpret_as_int()
  let mut ee = e + 15
  if round == 1 {
    m = m + 1
    if m == 1024 {
      m = 0
      ee = ee + 1
    }
    if ee >= 31 {
      return (sign | 0x7C00).to_uint16()
    }
  }
  (sign | (ee << 10) | m).to_uint16()
}

///|
/// Decode IEEE binary16 bits back to a float (used by tests and LUT readback).
pub fn f16_to_float(bits : UInt16) -> Float {
  let b = bits.to_uint().reinterpret_as_int()
  let negative = (b & 0x8000) != 0
  let exp = (b >> 10) & 0x1F
  let man = b & 0x3FF
  let mut v : Float = 0.0
  if exp == 0 {
    v = Float::from_int(man) / (1024.0 : Float) * @tmath.pow(2.0, -14.0)
  } else if exp == 31 {
    v = 65504.0
  } else {
    v = (1.0 + Float::from_int(man) / (1024.0 : Float)) *
      @tmath.pow(2.0, Float::from_int(exp - 15))
  }
  if negative {
    -v
  } else {
    v
  }
}

///|
// ---------------------------------------------------------------------------
// Radiance decoding
// ---------------------------------------------------------------------------

///|
fn hdr_u8(data : Bytes, i : Int) -> Int {
  if i < 0 || i >= data.length() {
    -1
  } else {
    data[i].to_int() & 0xFF
  }
}

///|
fn hdr_line_end(data : Bytes, pos : Int) -> Int {
  let mut i = pos
  while i < data.length() && hdr_u8(data, i) != 10 {
    i = i + 1
  }
  i
}

///|
fn hdr_skip_ws(data : Bytes, pos : Int) -> Int {
  let mut i = pos
  while i < data.length() {
    let c = hdr_u8(data, i)
    if c == 32 || c == 9 {
      i = i + 1
    } else {
      break
    }
  }
  i
}

///|
fn hdr_token(data : Bytes, pos : Int) -> (Int, Int) {
  let start = hdr_skip_ws(data, pos)
  let mut i = start
  while i < data.length() {
    let c = hdr_u8(data, i)
    if c == 32 || c == 9 || c == 10 || c == 13 {
      break
    }
    i = i + 1
  }
  (start, i)
}

///|
fn hdr_parse_int(data : Bytes, start : Int, end : Int) -> Int {
  let mut v = 0
  for i = start; i < end; i = i + 1 {
    let c = hdr_u8(data, i)
    if c >= 48 && c <= 57 {
      v = v * 10 + (c - 48)
    }
  }
  v
}

///|
fn rgbe_to_rgb(r : Int, g : Int, b : Int, e : Int) -> (Float, Float, Float) {
  if e == 0 {
    (0.0, 0.0, 0.0)
  } else {
    let scale = @tmath.pow(2.0, Float::from_int(e - 136))
    (
      Float::from_int(r) * scale,
      Float::from_int(g) * scale,
      Float::from_int(b) * scale,
    )
  }
}

///|
/// Decode a Radiance RGBE image. Returns `None` for malformed input.
pub fn decode_hdr(data : Bytes) -> HdrImage? {
  let n = data.length()
  if n < 16 || hdr_u8(data, 0) != 35 {
    return None
  }
  // Walk the header lines until the blank separator.
  let mut pos = hdr_line_end(data, 0) + 1
  let mut separated = false
  while pos < n {
    let end = hdr_line_end(data, pos)
    if end == pos || (end == pos + 1 && hdr_u8(data, pos) == 13) {
      pos = end + 1
      separated = true
      break
    }
    pos = end + 1
  }
  if !separated {
    return None
  }
  // Resolution line, e.g. "-Y 512 +X 1024".
  let (s0, e0) = hdr_token(data, pos)
  let (s1, e1) = hdr_token(data, e0)
  let (s2, e2) = hdr_token(data, e1)
  let (s3, e3) = hdr_token(data, e2)
  if e3 <= s3 {
    return None
  }
  let mut flip_y = false
  if e0 > s0 && hdr_u8(data, s0) == 43 {
    flip_y = true
  }
  let mut flip_x = false
  if e2 > s2 && hdr_u8(data, s2) == 45 {
    flip_x = true
  }
  let height = hdr_parse_int(data, s1, e1)
  let width = hdr_parse_int(data, s3, e3)
  if width <= 0 || height <= 0 || width > 65536 || height > 65536 {
    return None
  }
  let img = HdrImage::new(width, height)
  pos = hdr_line_end(data, e3) + 1
  for y = 0; y < height; y = y + 1 {
    let dst_y = if flip_y { height - 1 - y } else { y }
    let rle = width >= 8 &&
      width <= 32767 &&
      hdr_u8(data, pos) == 2 &&
      hdr_u8(data, pos + 1) == 2 &&
      ((hdr_u8(data, pos + 2) << 8) | hdr_u8(data, pos + 3)) == width
    if rle {
      pos = pos + 4
      let chans = FixedArray::make(4 * width, (0 : Int))
      for c = 0; c < 4; c = c + 1 {
        let mut x = 0
        while x < width {
          let code = hdr_u8(data, pos)
          pos = pos + 1
          if code < 0 {
            return None
          }
          if code > 128 {
            let run = code - 128
            let v = hdr_u8(data, pos)
            pos = pos + 1
            if v < 0 || x + run > width {
              return None
            }
            for i = 0; i < run; i = i + 1 {
              chans[c * width + x + i] = v
            }
            x = x + run
          } else {
            if code == 0 || x + code > width || pos + code > n {
              return None
            }
            for i = 0; i < code; i = i + 1 {
              chans[c * width + x + i] = hdr_u8(data, pos)
              pos = pos + 1
            }
            x = x + code
          }
        }
      }
      for x = 0; x < width; x = x + 1 {
        let (r, g, b) = rgbe_to_rgb(
          chans[x],
          chans[width + x],
          chans[2 * width + x],
          chans[3 * width + x],
        )
        let dst_x = if flip_x { width - 1 - x } else { x }
        img.set_pixel(dst_x, dst_y, r, g, b)
      }
    } else {
      for x = 0; x < width; x = x + 1 {
        if pos + 4 > n {
          return None
        }
        let (r, g, b) = rgbe_to_rgb(
          hdr_u8(data, pos),
          hdr_u8(data, pos + 1),
          hdr_u8(data, pos + 2),
          hdr_u8(data, pos + 3),
        )
        pos = pos + 4
        let dst_x = if flip_x { width - 1 - x } else { x }
        img.set_pixel(dst_x, dst_y, r, g, b)
      }
    }
  }
  Some(img)
}

// ---------------------------------------------------------------------------
// Radiance encoding (used by tests and synthetic HDR assets)
// ---------------------------------------------------------------------------

///|
fn hdr_push_bytes(out : Array[Byte], data : Bytes) -> Unit {
  for i = 0; i < data.length(); i = i + 1 {
    out.push(data[i])
  }
}

///|
fn hdr_push_int(out : Array[Byte], v : Int) -> Unit {
  if v >= 10 {
    hdr_push_int(out, v / 10)
  }
  out.push((48 + v % 10).to_byte())
}

///|
fn rgb_to_rgbe(r : Float, g : Float, b : Float) -> (Int, Int, Int, Int) {
  let v : Float = if r > g {
    if r > b {
      r
    } else {
      b
    }
  } else if g > b {
    g
  } else {
    b
  }
  if v < (1.0e-32 : Float) {
    (0, 0, 0, 0)
  } else {
    let mut m = v
    let mut e = 0
    while m >= 1.0 {
      m = m * 0.5
      e = e + 1
    }
    while m < (0.5 : Float) {
      m = m * 2.0
      e = e - 1
    }
    let scale = m * (256.0 : Float) / v
    let rq = (r * scale).to_int()
    let gq = (g * scale).to_int()
    let bq = (b * scale).to_int()
    (u8_clamp(rq), u8_clamp(gq), u8_clamp(bq), e + 128)
  }
}

///|
fn u8_clamp(v : Int) -> Int {
  if v < 0 {
    0
  } else if v > 255 {
    255
  } else {
    v
  }
}

///|
fn hdr_encode_runs(out : Array[Byte], chans : FixedArray[Int], base : Int, w : Int) -> Unit {
  let mut x = 0
  while x < w {
    let mut run = 1
    while x + run < w && run < 127 && chans[base + x + run] == chans[base + x] {
      run = run + 1
    }
    if run >= 4 {
      out.push((128 + run).to_byte())
      out.push(chans[base + x].to_byte())
      x = x + run
    } else {
      // Literal block: stop before the next run of four equal values.
      let mut lit = 0
      while x + lit < w && lit < 128 {
        if lit > 0 {
          let mut r2 = 1
          while x + lit + r2 < w &&
            r2 < 4 &&
            chans[base + x + lit + r2] == chans[base + x + lit] {
            r2 = r2 + 1
          }
          if r2 >= 4 {
            break
          }
        }
        lit = lit + 1
      }
      if lit == 0 {
        lit = 1
      }
      out.push(lit.to_byte())
      for i = 0; i < lit; i = i + 1 {
        out.push(chans[base + x + i].to_byte())
      }
      x = x + lit
    }
  }
}

///|
/// Encode a linear RGB image as Radiance RGBE. RLE is used when the width
/// permits it (8..32767); otherwise scanlines are stored flat.
pub fn encode_hdr(img : HdrImage, rle? : Bool = true) -> Bytes {
  let out : Array[Byte] = []
  hdr_push_bytes(out, b"#?RADIANCE\n")
  hdr_push_bytes(out, b"FORMAT=32-bit_rle_rgbe\n")
  hdr_push_bytes(out, b"\n")
  hdr_push_bytes(out, b"-Y ")
  hdr_push_int(out, img.height)
  hdr_push_bytes(out, b" +X ")
  hdr_push_int(out, img.width)
  hdr_push_bytes(out, b"\n")
  let use_rle = rle && img.width >= 8 && img.width <= 32767
  for y = 0; y < img.height; y = y + 1 {
    let w = img.width
    let chans = FixedArray::make(4 * w, (0 : Int))
    for x = 0; x < w; x = x + 1 {
      let (r, g, b) = img.pixel(x, y)
      let (rq, gq, bq, eq) = rgb_to_rgbe(r, g, b)
      chans[x] = rq
      chans[w + x] = gq
      chans[2 * w + x] = bq
      chans[3 * w + x] = eq
    }
    if use_rle {
      out.push((2 : Byte))
      out.push((2 : Byte))
      out.push((w >> 8).to_byte())
      out.push((w & 0xFF).to_byte())
      for c = 0; c < 4; c = c + 1 {
        hdr_encode_runs(out, chans, c * w, w)
      }
    } else {
      for x = 0; x < w; x = x + 1 {
        out.push(chans[x].to_byte())
        out.push(chans[w + x].to_byte())
        out.push(chans[2 * w + x].to_byte())
        out.push(chans[3 * w + x].to_byte())
      }
    }
  }
  Bytes::from_array(out)
}
