// Pure MoonBit port of stb_image v2.34 core infrastructure:
// buffer reader, overflow checks, channel & bit-depth conversions,
// vertical flip, and top-level dispatch.

///|
const STBI_MAX_DIMENSIONS : Int = 16777216 // 1 << 24

///|
const STBI_INT_MAX : Int = 2147483647

///|
const STBI_INT_MIN : Int = -2147483648

///|
const STBI_SCAN_LOAD : Int = 0

///|
const STBI_SCAN_TYPE : Int = 1

///|
const STBI_SCAN_HEADER : Int = 2

///|
/// Image type identified by `stbi_info_from_memory`.
#derive(Eq, Debug)
pub(all) enum StbiImageType {
  Unsupported
  Png
  Jpeg
  Bmp
  Tga
  Gif
  Psd
  Hdr
  Pnm
}

///|
/// Metadata returned by `stbi_info_from_memory`.
#derive(Eq, Debug)
pub(all) struct StbiInfo {
  width : Int
  height : Int
  channels : Int
  image_type : StbiImageType
  is_16_bit : Bool
  is_hdr : Bool
  is_iphone_png : Bool
}

///|
/// Per-call decode options (replaces stb_image's global mutable flags cleanly).
pub(all) struct StbiOptions {
  flip_vertically : Bool
  unpremultiply_iphone_png : Bool
  convert_iphone_png_to_rgb : Bool
  ldr_to_hdr_gamma : Float
  ldr_to_hdr_scale : Float
  hdr_to_ldr_gamma : Float
  hdr_to_ldr_scale : Float
}

///|
pub fn StbiOptions::default() -> StbiOptions {
  {
    flip_vertically: false,
    unpremultiply_iphone_png: false,
    convert_iphone_png_to_rgb: false,
    ldr_to_hdr_gamma: (2.2 : Float),
    ldr_to_hdr_scale: (1.0 : Float),
    hdr_to_ldr_gamma: (2.2 : Float),
    hdr_to_ldr_scale: (1.0 : Float),
  }
}

///|
/// Decoded 8-bit image from `stbi_load_from_memory`.
pub(all) struct StbiImage8 {
  width : Int
  height : Int
  channels_in_file : Int
  channels : Int
  data : Bytes
}

///|
/// Decoded 16-bit image from `stbi_load_16_from_memory`.
pub(all) struct StbiImage16 {
  width : Int
  height : Int
  channels_in_file : Int
  channels : Int
  data : FixedArray[UInt16]
}

///|
/// Decoded 32-bit float image from `stbi_loadf_from_memory`.
pub(all) struct StbiImageF {
  width : Int
  height : Int
  channels_in_file : Int
  channels : Int
  data : FixedArray[Float]
}

///|
/// Decoded multi-frame animated GIF from `stbi_load_gif_from_memory`.
pub(all) struct StbiGif {
  width : Int
  height : Int
  frames : Int
  channels_in_file : Int
  channels : Int
  delays : FixedArray[Int]
  data : Bytes
}

///|
priv enum StbiRawPixels {
  Bits8(FixedArray[Byte])
  Bits16(FixedArray[UInt16])
}

///|
priv struct StbiDecodeResult {
  width : Int
  height : Int
  comp : Int
  pixels : StbiRawPixels
}

///|
/// Internal sequential byte-buffer reader matching `stbi__context`.
priv struct StbiContext {
  buf : Bytes
  len : Int
  mut pos : Int
  mut img_x : Int
  mut img_y : Int
  mut img_n : Int
  mut img_out_n : Int
  options : StbiOptions
}

///|
fn StbiContext::new(buf : Bytes, options : StbiOptions) -> StbiContext {
  {
    buf,
    len: buf.length(),
    pos: 0,
    img_x: 0,
    img_y: 0,
    img_n: 0,
    img_out_n: 0,
    options,
  }
}

///|
fn StbiContext::set_err(self : StbiContext, msg : String) -> Unit {
  ignore(self)
  ignore(msg)
}

///|
fn StbiContext::rewind(self : StbiContext) -> Unit {
  self.pos = 0
}

///|
fn StbiContext::at_eof(self : StbiContext) -> Bool {
  self.pos >= self.len
}

///|
fn StbiContext::get8(self : StbiContext) -> Int {
  if self.pos < self.len {
    let b = self.buf[self.pos].to_int()
    self.pos += 1
    b
  } else {
    0
  }
}

///|
fn StbiContext::skip(self : StbiContext, n : Int) -> Unit {
  if n == 0 {
    return
  }
  if n < 0 {
    self.pos = self.len
    return
  }
  if n > self.len - self.pos {
    self.pos = self.len
  } else {
    self.pos += n
  }
}

///|
fn StbiContext::getn(
  self : StbiContext,
  dst : FixedArray[Byte],
  dst_off : Int,
  n : Int,
) -> Bool {
  if n <= 0 {
    return true
  }
  if n <= self.len - self.pos {
    for i = 0; i < n; i = i + 1 {
      dst[dst_off + i] = self.buf[self.pos + i]
    }
    self.pos += n
    true
  } else {
    false
  }
}

///|
fn StbiContext::get16be(self : StbiContext) -> Int {
  let z = self.get8()
  (z << 8) + self.get8()
}

///|
fn StbiContext::get32be(self : StbiContext) -> UInt {
  let hi = self.get16be().reinterpret_as_uint()
  let lo = self.get16be().reinterpret_as_uint()
  (hi << 16) + lo
}

///|
fn StbiContext::get16le(self : StbiContext) -> Int {
  let z = self.get8()
  z + (self.get8() << 8)
}

///|
fn StbiContext::get32le(self : StbiContext) -> UInt {
  let lo = self.get16le().reinterpret_as_uint()
  let hi = self.get16le().reinterpret_as_uint()
  lo + (hi << 16)
}

///|
fn stbi_addsizes_valid(a : Int, b : Int) -> Bool {
  if b < 0 {
    return false
  }
  a <= STBI_INT_MAX - b
}

///|
fn stbi_mul2sizes_valid(a : Int, b : Int) -> Bool {
  if a < 0 || b < 0 {
    return false
  }
  if b == 0 {
    return true
  }
  a <= STBI_INT_MAX / b
}

///|
fn stbi_mad2sizes_valid(a : Int, b : Int, add : Int) -> Bool {
  stbi_mul2sizes_valid(a, b) && stbi_addsizes_valid(a * b, add)
}

///|
fn stbi_mad3sizes_valid(a : Int, b : Int, c : Int, add : Int) -> Bool {
  stbi_mul2sizes_valid(a, b) &&
  stbi_mul2sizes_valid(a * b, c) &&
  stbi_addsizes_valid(a * b * c, add)
}

///|
fn stbi_mad4sizes_valid(a : Int, b : Int, c : Int, d : Int, add : Int) -> Bool {
  stbi_mul2sizes_valid(a, b) &&
  stbi_mul2sizes_valid(a * b, c) &&
  stbi_mul2sizes_valid(a * b * c, d) &&
  stbi_addsizes_valid(a * b * c * d, add)
}

///|
fn stbi_addints_valid(a : Int, b : Int) -> Bool {
  if (a >= 0) != (b >= 0) {
    return true
  }
  if a < 0 && b < 0 {
    return a >= STBI_INT_MIN - b
  }
  a <= STBI_INT_MAX - b
}

///|
fn stbi_mul2shorts_valid(a : Int, b : Int) -> Bool {
  if b == 0 || b == -1 {
    return true
  }
  if (a >= 0) == (b >= 0) {
    return a <= 32767 / b
  }
  if b < 0 {
    return a <= -32768 / b
  }
  a >= -32768 / b
}

///|
fn stbi_compute_y(r : Int, g : Int, b : Int) -> Byte {
  (((r * 77) + (g * 150) + (29 * b)) >> 8).to_byte()
}

///|
fn stbi_compute_y_16(r : Int, g : Int, b : Int) -> UInt16 {
  (((r * 77) + (g * 150) + (29 * b)) >> 8).to_uint16()
}

///|
fn stbi_convert_format(
  data : FixedArray[Byte],
  img_n : Int,
  req_comp : Int,
  x : Int,
  y : Int,
) -> FixedArray[Byte]? {
  if req_comp == img_n {
    return Some(data)
  }
  if req_comp < 1 || req_comp > 4 || !stbi_mad3sizes_valid(req_comp, x, y, 0) {
    return None
  }
  let good : FixedArray[Byte] = FixedArray::make(req_comp * x * y, (0 : Byte))
  let combo = img_n * 8 + req_comp
  for j = 0; j < y; j = j + 1 {
    let mut si = j * x * img_n
    let mut di = j * x * req_comp
    match combo {
      10 => // (1, 2)
        for i = 0; i < x; i = i + 1 {
          good[di] = data[si]
          good[di + 1] = (255 : Byte)
          si += 1
          di += 2
        }
      11 => // (1, 3)
        for i = 0; i < x; i = i + 1 {
          let v = data[si]
          good[di] = v
          good[di + 1] = v
          good[di + 2] = v
          si += 1
          di += 3
        }
      12 => // (1, 4)
        for i = 0; i < x; i = i + 1 {
          let v = data[si]
          good[di] = v
          good[di + 1] = v
          good[di + 2] = v
          good[di + 3] = (255 : Byte)
          si += 1
          di += 4
        }
      17 => // (2, 1)
        for i = 0; i < x; i = i + 1 {
          good[di] = data[si]
          si += 2
          di += 1
        }
      19 => // (2, 3)
        for i = 0; i < x; i = i + 1 {
          let v = data[si]
          good[di] = v
          good[di + 1] = v
          good[di + 2] = v
          si += 2
          di += 3
        }
      20 => // (2, 4)
        for i = 0; i < x; i = i + 1 {
          let v = data[si]
          good[di] = v
          good[di + 1] = v
          good[di + 2] = v
          good[di + 3] = data[si + 1]
          si += 2
          di += 4
        }
      28 => // (3, 4)
        for i = 0; i < x; i = i + 1 {
          good[di] = data[si]
          good[di + 1] = data[si + 1]
          good[di + 2] = data[si + 2]
          good[di + 3] = (255 : Byte)
          si += 3
          di += 4
        }
      25 => // (3, 1)
        for i = 0; i < x; i = i + 1 {
          good[di] = stbi_compute_y(
            data[si].to_int(),
            data[si + 1].to_int(),
            data[si + 2].to_int(),
          )
          si += 3
          di += 1
        }
      26 => // (3, 2)
        for i = 0; i < x; i = i + 1 {
          good[di] = stbi_compute_y(
            data[si].to_int(),
            data[si + 1].to_int(),
            data[si + 2].to_int(),
          )
          good[di + 1] = (255 : Byte)
          si += 3
          di += 2
        }
      33 => // (4, 1)
        for i = 0; i < x; i = i + 1 {
          good[di] = stbi_compute_y(
            data[si].to_int(),
            data[si + 1].to_int(),
            data[si + 2].to_int(),
          )
          si += 4
          di += 1
        }
      34 => // (4, 2)
        for i = 0; i < x; i = i + 1 {
          good[di] = stbi_compute_y(
            data[si].to_int(),
            data[si + 1].to_int(),
            data[si + 2].to_int(),
          )
          good[di + 1] = data[si + 3]
          si += 4
          di += 2
        }
      35 => // (4, 3)
        for i = 0; i < x; i = i + 1 {
          good[di] = data[si]
          good[di + 1] = data[si + 1]
          good[di + 2] = data[si + 2]
          si += 4
          di += 3
        }
      _ => return None
    }
  }
  Some(good)
}

///|
fn stbi_convert_format16(
  data : FixedArray[UInt16],
  img_n : Int,
  req_comp : Int,
  x : Int,
  y : Int,
) -> FixedArray[UInt16]? {
  if req_comp == img_n {
    return Some(data)
  }
  if req_comp < 1 || req_comp > 4 || !stbi_mad4sizes_valid(req_comp, x, y, 2, 0) {
    return None
  }
  let good : FixedArray[UInt16] = FixedArray::make(
    req_comp * x * y,
    (0 : UInt16),
  )
  let max16 : UInt16 = (65535 : UInt16)
  let combo = img_n * 8 + req_comp
  for j = 0; j < y; j = j + 1 {
    let mut si = j * x * img_n
    let mut di = j * x * req_comp
    match combo {
      10 =>
        for i = 0; i < x; i = i + 1 {
          good[di] = data[si]
          good[di + 1] = max16
          si += 1
          di += 2
        }
      11 =>
        for i = 0; i < x; i = i + 1 {
          let v = data[si]
          good[di] = v
          good[di + 1] = v
          good[di + 2] = v
          si += 1
          di += 3
        }
      12 =>
        for i = 0; i < x; i = i + 1 {
          let v = data[si]
          good[di] = v
          good[di + 1] = v
          good[di + 2] = v
          good[di + 3] = max16
          si += 1
          di += 4
        }
      17 =>
        for i = 0; i < x; i = i + 1 {
          good[di] = data[si]
          si += 2
          di += 1
        }
      19 =>
        for i = 0; i < x; i = i + 1 {
          let v = data[si]
          good[di] = v
          good[di + 1] = v
          good[di + 2] = v
          si += 2
          di += 3
        }
      20 =>
        for i = 0; i < x; i = i + 1 {
          let v = data[si]
          good[di] = v
          good[di + 1] = v
          good[di + 2] = v
          good[di + 3] = data[si + 1]
          si += 2
          di += 4
        }
      28 =>
        for i = 0; i < x; i = i + 1 {
          good[di] = data[si]
          good[di + 1] = data[si + 1]
          good[di + 2] = data[si + 2]
          good[di + 3] = max16
          si += 3
          di += 4
        }
      25 =>
        for i = 0; i < x; i = i + 1 {
          good[di] = stbi_compute_y_16(
            data[si].to_int(),
            data[si + 1].to_int(),
            data[si + 2].to_int(),
          )
          si += 3
          di += 1
        }
      26 =>
        for i = 0; i < x; i = i + 1 {
          good[di] = stbi_compute_y_16(
            data[si].to_int(),
            data[si + 1].to_int(),
            data[si + 2].to_int(),
          )
          good[di + 1] = max16
          si += 3
          di += 2
        }
      33 =>
        for i = 0; i < x; i = i + 1 {
          good[di] = stbi_compute_y_16(
            data[si].to_int(),
            data[si + 1].to_int(),
            data[si + 2].to_int(),
          )
          si += 4
          di += 1
        }
      34 =>
        for i = 0; i < x; i = i + 1 {
          good[di] = stbi_compute_y_16(
            data[si].to_int(),
            data[si + 1].to_int(),
            data[si + 2].to_int(),
          )
          good[di + 1] = data[si + 3]
          si += 4
          di += 2
        }
      35 =>
        for i = 0; i < x; i = i + 1 {
          good[di] = data[si]
          good[di + 1] = data[si + 1]
          good[di + 2] = data[si + 2]
          si += 4
          di += 3
        }
      _ => return None
    }
  }
  Some(good)
}

///|
fn stbi_convert_16_to_8(
  orig : FixedArray[UInt16],
  w : Int,
  h : Int,
  channels : Int,
) -> FixedArray[Byte]? {
  if !stbi_mad3sizes_valid(w, h, channels, 0) {
    return None
  }
  let img_len = w * h * channels
  let reduced : FixedArray[Byte] = FixedArray::make(img_len, (0 : Byte))
  for i = 0; i < img_len; i = i + 1 {
    reduced[i] = ((orig[i].to_int() >> 8) & 0xFF).to_byte()
  }
  Some(reduced)
}

///|
fn stbi_convert_8_to_16(
  orig : FixedArray[Byte],
  w : Int,
  h : Int,
  channels : Int,
) -> FixedArray[UInt16]? {
  if !stbi_mad4sizes_valid(w, h, channels, 2, 0) {
    return None
  }
  let img_len = w * h * channels
  let enlarged : FixedArray[UInt16] = FixedArray::make(img_len, (0 : UInt16))
  for i = 0; i < img_len; i = i + 1 {
    let v = orig[i].to_int()
    enlarged[i] = ((v << 8) + v).to_uint16()
  }
  Some(enlarged)
}

///|
fn stbi_vertical_flip_bytes(
  image : FixedArray[Byte],
  w : Int,
  h : Int,
  bytes_per_pixel : Int,
) -> Unit {
  let row_bytes = w * bytes_per_pixel
  let half = h >> 1
  for row = 0; row < half; row = row + 1 {
    let r0 = row * row_bytes
    let r1 = (h - row - 1) * row_bytes
    for i = 0; i < row_bytes; i = i + 1 {
      let tmp = image[r0 + i]
      image[r0 + i] = image[r1 + i]
      image[r1 + i] = tmp
    }
  }
}

///|
fn stbi_vertical_flip_u16(
  image : FixedArray[UInt16],
  w : Int,
  h : Int,
  channels : Int,
) -> Unit {
  let row_elems = w * channels
  let half = h >> 1
  for row = 0; row < half; row = row + 1 {
    let r0 = row * row_elems
    let r1 = (h - row - 1) * row_elems
    for i = 0; i < row_elems; i = i + 1 {
      let tmp = image[r0 + i]
      image[r0 + i] = image[r1 + i]
      image[r1 + i] = tmp
    }
  }
}

///|
fn stbi_vertical_flip_f(
  image : FixedArray[Float],
  w : Int,
  h : Int,
  channels : Int,
) -> Unit {
  let row_elems = w * channels
  let half = h >> 1
  for row = 0; row < half; row = row + 1 {
    let r0 = row * row_elems
    let r1 = (h - row - 1) * row_elems
    for i = 0; i < row_elems; i = i + 1 {
      let tmp = image[r0 + i]
      image[r0 + i] = image[r1 + i]
      image[r1 + i] = tmp
    }
  }
}

///|
fn stbi_ldr_to_hdr(
  data : FixedArray[Byte],
  x : Int,
  y : Int,
  comp : Int,
  options : StbiOptions,
) -> FixedArray[Float]? {
  if !stbi_mad4sizes_valid(x, y, comp, 4, 0) {
    return None
  }
  let output : FixedArray[Float] = FixedArray::make(x * y * comp, (0.0 : Float))
  let gamma_lut : FixedArray[Float] = FixedArray::make(256, (0.0 : Float))
  let gamma = options.ldr_to_hdr_gamma.to_double()
  let scale = options.ldr_to_hdr_scale.to_double()
  for i = 0; i < 256; i = i + 1 {
    let f = (Float::from_int(i) / (255.0 : Float)).to_double()
    gamma_lut[i] = Float::from_double(@math.pow(f, gamma) * scale)
  }
  let n = if (comp & 1) != 0 { comp } else { comp - 1 }
  let total = x * y
  for i = 0; i < total; i = i + 1 {
    let base = i * comp
    for k = 0; k < n; k = k + 1 {
      output[base + k] = gamma_lut[data[base + k].to_int()]
    }
  }
  if n < comp {
    for i = 0; i < total; i = i + 1 {
      let base = i * comp
      output[base + n] = Float::from_int(data[base + n].to_int()) /
        (255.0 : Float)
    }
  }
  Some(output)
}

///|
fn stbi_hdr_to_ldr(
  data : FixedArray[Float],
  x : Int,
  y : Int,
  comp : Int,
  options : StbiOptions,
) -> FixedArray[Byte]? {
  if !stbi_mad3sizes_valid(x, y, comp, 0) {
    return None
  }
  let output : FixedArray[Byte] = FixedArray::make(x * y * comp, (0 : Byte))
  let scale_i : Float = (1.0 : Float) / options.hdr_to_ldr_scale
  let gamma_i : Float = (1.0 : Float) / options.hdr_to_ldr_gamma
  let n = if (comp & 1) != 0 { comp } else { comp - 1 }
  let total = x * y
  for i = 0; i < total; i = i + 1 {
    let base = i * comp
    for k = 0; k < n; k = k + 1 {
      let scaled = (data[base + k] * scale_i).to_double()
      let mut z = Float::from_double(@math.pow(scaled, gamma_i.to_double())) *
        (255.0 : Float) +
        (0.5 : Float)
      if z < (0.0 : Float) {
        z = (0.0 : Float)
      }
      if z > (255.0 : Float) {
        z = (255.0 : Float)
      }
      output[base + k] = z.to_int().to_byte()
    }
    if n < comp {
      let mut z = data[base + n] * (255.0 : Float) + (0.5 : Float)
      if z < (0.0 : Float) {
        z = (0.0 : Float)
      }
      if z > (255.0 : Float) {
        z = (255.0 : Float)
      }
      output[base + n] = z.to_int().to_byte()
    }
  }
  Some(output)
}

///|
fn stbi_load_main(
  s : StbiContext,
  req_comp : Int,
  bpc : Int,
) -> StbiDecodeResult? {
  if req_comp < 0 || req_comp > 4 {
    s.set_err("bad req_comp")
    return None
  }
  if stbi_png_test(s) {
    return stbi_png_load(s, req_comp)
  }
  if stbi_bmp_test(s) {
    return stbi_bmp_load(s, req_comp)
  }
  if stbi_gif_test(s) {
    return stbi_gif_load(s, req_comp)
  }
  if stbi_psd_test(s) {
    return stbi_psd_load(s, req_comp, bpc)
  }
  if stbi_jpeg_test(s) {
    return stbi_jpeg_load(s, req_comp)
  }
  if stbi_pnm_test(s) {
    return stbi_pnm_load(s, req_comp)
  }
  if stbi_hdr_test(s) {
    match stbi_hdr_load(s, req_comp) {
      Some((hdr, w, h, comp)) => {
        let oc = if req_comp != 0 { req_comp } else { comp }
        match stbi_hdr_to_ldr(hdr, w, h, oc, s.options) {
          Some(ldr) =>
            return Some({
              width: w,
              height: h,
              comp,
              pixels: StbiRawPixels::Bits8(ldr),
            })
          None => return None
        }
      }
      None => return None
    }
  }
  if stbi_tga_test(s) {
    return stbi_tga_load(s, req_comp)
  }
  s.set_err("unknown image type")
  None
}

///|
/// Decode an 8-bit image from memory (pure MoonBit `stbi_load_from_memory`).
pub fn stbi_load_from_memory(
  buffer : Bytes,
  desired_channels? : Int = 0,
  options? : StbiOptions = StbiOptions::default(),
) -> StbiImage8? {
  let s = StbiContext::new(buffer, options)
  match stbi_load_main(s, desired_channels, 8) {
    None => None
    Some(res) => {
      let out_c = if desired_channels != 0 {
        desired_channels
      } else {
        res.comp
      }
      let px8 = match res.pixels {
        StbiRawPixels::Bits8(b) => b
        StbiRawPixels::Bits16(u) =>
          match stbi_convert_16_to_8(u, res.width, res.height, out_c) {
            Some(b) => b
            None => return None
          }
      }
      if options.flip_vertically {
        stbi_vertical_flip_bytes(px8, res.width, res.height, out_c)
      }
      Some({
        width: res.width,
        height: res.height,
        channels_in_file: res.comp,
        channels: out_c,
        data: Bytes::from_array(px8[:]),
      })
    }
  }
}

///|
/// Decode a 16-bit image from memory (pure MoonBit `stbi_load_16_from_memory`).
pub fn stbi_load_16_from_memory(
  buffer : Bytes,
  desired_channels? : Int = 0,
  options? : StbiOptions = StbiOptions::default(),
) -> StbiImage16? {
  let s = StbiContext::new(buffer, options)
  match stbi_load_main(s, desired_channels, 16) {
    None => None
    Some(res) => {
      let out_c = if desired_channels != 0 {
        desired_channels
      } else {
        res.comp
      }
      let px16 = match res.pixels {
        StbiRawPixels::Bits16(u) => u
        StbiRawPixels::Bits8(b) =>
          match stbi_convert_8_to_16(b, res.width, res.height, out_c) {
            Some(u) => u
            None => return None
          }
      }
      if options.flip_vertically {
        stbi_vertical_flip_u16(px16, res.width, res.height, out_c)
      }
      Some({
        width: res.width,
        height: res.height,
        channels_in_file: res.comp,
        channels: out_c,
        data: px16,
      })
    }
  }
}

///|
/// Decode a 32-bit float image from memory (pure MoonBit `stbi_loadf_from_memory`).
pub fn stbi_loadf_from_memory(
  buffer : Bytes,
  desired_channels? : Int = 0,
  options? : StbiOptions = StbiOptions::default(),
) -> StbiImageF? {
  let s = StbiContext::new(buffer, options)
  if stbi_hdr_test(s) {
    match stbi_hdr_load(s, desired_channels) {
      Some((hdr_data, w, h, comp)) => {
        let out_c = if desired_channels != 0 { desired_channels } else { comp }
        if options.flip_vertically {
          stbi_vertical_flip_f(hdr_data, w, h, out_c)
        }
        return Some({
          width: w,
          height: h,
          channels_in_file: comp,
          channels: out_c,
          data: hdr_data,
        })
      }
      None => return None
    }
  }
  match stbi_load_main(s, desired_channels, 8) {
    None => None
    Some(res) => {
      let out_c = if desired_channels != 0 {
        desired_channels
      } else {
        res.comp
      }
      let px8 = match res.pixels {
        StbiRawPixels::Bits8(b) => b
        StbiRawPixels::Bits16(u) =>
          match stbi_convert_16_to_8(u, res.width, res.height, out_c) {
            Some(b) => b
            None => return None
          }
      }
      if options.flip_vertically {
        stbi_vertical_flip_bytes(px8, res.width, res.height, out_c)
      }
      match stbi_ldr_to_hdr(px8, res.width, res.height, out_c, options) {
        Some(f) =>
          Some({
            width: res.width,
            height: res.height,
            channels_in_file: res.comp,
            channels: out_c,
            data: f,
          })
        None => None
      }
    }
  }
}

///|
/// Decode all frames of a GIF from memory (pure MoonBit `stbi_load_gif_from_memory`).
pub fn stbi_load_gif_from_memory(
  buffer : Bytes,
  desired_channels? : Int = 0,
  options? : StbiOptions = StbiOptions::default(),
) -> StbiGif? {
  if desired_channels < 0 || desired_channels > 4 {
    return None
  }
  let s = StbiContext::new(buffer, options)
  stbi_load_gif_main(s, desired_channels)
}

///|
/// Probe image dimensions, channels, and format without decoding pixels.
pub fn stbi_info_from_memory(buffer : Bytes) -> StbiInfo? {
  let s = StbiContext::new(buffer, StbiOptions::default())
  match stbi_jpeg_info(s) {
    Some(info) => return Some(info)
    None => ()
  }
  match stbi_png_info(s) {
    Some(info) => return Some(info)
    None => ()
  }
  match stbi_gif_info(s) {
    Some(info) => return Some(info)
    None => ()
  }
  match stbi_bmp_info(s) {
    Some(info) => return Some(info)
    None => ()
  }
  match stbi_psd_info(s) {
    Some(info) => return Some(info)
    None => ()
  }
  match stbi_pnm_info(s) {
    Some(info) => return Some(info)
    None => ()
  }
  match stbi_hdr_info(s) {
    Some(info) => return Some(info)
    None => ()
  }
  match stbi_tga_info(s) {
    Some(info) => return Some(info)
    None => ()
  }
  None
}

///|
/// Return true if the image in `buffer` has 16 bits per channel.
pub fn stbi_is_16_bit_from_memory(buffer : Bytes) -> Bool {
  match stbi_info_from_memory(buffer) {
    Some(info) => info.is_16_bit
    None => false
  }
}

///|
/// Return true if `buffer` starts with a Radiance HDR signature.
pub fn stbi_is_hdr_from_memory(buffer : Bytes) -> Bool {
  let s = StbiContext::new(buffer, StbiOptions::default())
  stbi_hdr_test(s)
}
