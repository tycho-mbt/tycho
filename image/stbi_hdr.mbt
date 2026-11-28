// Pure MoonBit port of stb_image v2.34 Radiance RGBE HDR decoder.

///|
const HDR_BUFLEN : Int = 1024

///|
fn hdr_test_core(s : StbiContext, sig : FixedArray[Int]) -> Bool {
  for i = 0; i < sig.length(); i = i + 1 {
    if s.get8() != sig[i] {
      return false
    }
  }
  s.rewind()
  true
}

///|
fn stbi_hdr_test(s : StbiContext) -> Bool {
  let sig1 : FixedArray[Int] = [35, 63, 82, 65, 68, 73, 65, 78, 67, 69, 10] // "#?RADIANCE\n"
  let sig2 : FixedArray[Int] = [35, 63, 82, 71, 66, 69, 10] // "#?RGBE\n"
  let mut r = hdr_test_core(s, sig1)
  s.rewind()
  if !r {
    r = hdr_test_core(s, sig2)
    s.rewind()
  }
  r
}

///|
fn hdr_gettoken(s : StbiContext) -> String {
  let buf = StringBuilder()
  let mut len = 0
  let mut c = s.get8()
  while !s.at_eof() && c != 10 {
    buf.write_char(Int::unsafe_to_char(c))
    len += 1
    if len == HDR_BUFLEN - 1 {
      while !s.at_eof() && s.get8() != 10 {
        ()
      }
      break
    }
    c = s.get8()
  }
  buf.to_string()
}

///|
fn hdr_ldexp_one(exp : Int) -> Float {
  // Exact IEEE-754 double 2^exp for exp in -135..119, then narrow to float32.
  let bits : Int64 = (exp + 1023).to_int64() << 52
  Float::from_double(bits.reinterpret_as_double())
}

///|
fn hdr_makelut(req_comp : Int) -> FixedArray[Float] {
  let lut : FixedArray[Float] = FixedArray::make(256, (0.0 : Float))
  lut[0] = (0.0 : Float)
  for k = 1; k < 256; k = k + 1 {
    let mut v = hdr_ldexp_one(k - 136)
    if req_comp <= 2 {
      v = v / (3.0 : Float)
    }
    lut[k] = v
  }
  lut
}

///|
fn hdr_convert(
  output : FixedArray[Float],
  out_off : Int,
  r : Int,
  g : Int,
  b : Int,
  e : Int,
  req_comp : Int,
  explut : FixedArray[Float],
) -> Unit {
  let scale = explut[e]
  if req_comp <= 2 {
    output[out_off] = (Float::from_int(r + g + b) + (1.5 : Float)) * scale
    if req_comp == 2 {
      output[out_off + 1] = (1.0 : Float)
    }
  } else {
    output[out_off] = (Float::from_int(r) + (0.5 : Float)) * scale
    output[out_off + 1] = (Float::from_int(g) + (0.5 : Float)) * scale
    output[out_off + 2] = (Float::from_int(b) + (0.5 : Float)) * scale
    if req_comp == 4 {
      output[out_off + 3] = (1.0 : Float)
    }
  }
}

///|
fn hdr_parse_int(s : String, start : Int) -> (Int, Int) {
  let len = s.length()
  let mut i = start
  while i < len && s[i] == 32 {
    i += 1
  }
  let mut sign = 1
  if i < len && s[i] == 45 {
    sign = -1
    i += 1
  } else if i < len && s[i] == 43 {
    i += 1
  }
  let mut val = 0
  while i < len {
    let ch = s[i].to_int()
    if ch >= 48 && ch <= 57 {
      val = val * 10 + (ch - 48)
      i += 1
    } else {
      break
    }
  }
  (sign * val, i)
}

///|
fn hdr_parse_dims(token : String) -> (Int, Int)? {
  let len = token.length()
  if len < 7 {
    return None
  }
  // "-Y "
  if token[0] != 45 || token[1] != 89 || token[2] != 32 {
    return None
  }
  let (h, pos0) = hdr_parse_int(token, 3)
  let mut pos = pos0
  while pos < len && token[pos] == 32 {
    pos += 1
  }
  // "+X "
  if pos + 3 > len ||
    token[pos] != 43 ||
    token[pos + 1] != 88 ||
    token[pos + 2] != 32 {
    return None
  }
  let (w, _) = hdr_parse_int(token, pos + 3)
  Some((w, h))
}

///|
fn hdr_load_pixels(
  s : StbiContext,
  hdr_data : FixedArray[Float],
  width : Int,
  height : Int,
  req_comp : Int,
  isrle_in : Bool,
) -> Bool {
  let explut = hdr_makelut(req_comp)
  let mut isrle = isrle_in
  let scanline : FixedArray[Int] = if isrle {
    FixedArray::make(width * 4, 0)
  } else {
    FixedArray::make(0, 0)
  }
  for y = 0; y < height; y = y + 1 {
    let mut c0 = s.get8()
    let mut c1 = s.get8()
    let mut c2 = s.get8()
    let mut c3 = s.get8()
    if !isrle || c0 != 2 || c1 != 2 || (c2 & 0x80) != 0 {
      isrle = false
      let mut x = 0
      while true {
        hdr_convert(
          hdr_data,
          (y * width + x) * req_comp,
          c0,
          c1,
          c2,
          c3,
          req_comp,
          explut,
        )
        x += 1
        if x >= width {
          break
        }
        c0 = s.get8()
        c1 = s.get8()
        c2 = s.get8()
        c3 = s.get8()
      }
      continue
    }
    if ((c2 << 8) | c3) != width {
      return false
    }
    for k = 0; k < 4; k = k + 1 {
      let mut x = 0
      while x < width {
        let count = s.get8()
        if count > 128 {
          let value = s.get8()
          let run = count - 128
          if run == 0 || width - x < run {
            return false
          }
          for j = 0; j < run; j = j + 1 {
            scanline[x * 4 + k] = value
            x += 1
          }
        } else {
          if count == 0 || width - x < count {
            return false
          }
          for j = 0; j < count; j = j + 1 {
            scanline[x * 4 + k] = s.get8()
            x += 1
          }
        }
      }
    }
    for x = 0; x < width; x = x + 1 {
      hdr_convert(
        hdr_data,
        (y * width + x) * req_comp,
        scanline[x * 4],
        scanline[x * 4 + 1],
        scanline[x * 4 + 2],
        scanline[x * 4 + 3],
        req_comp,
        explut,
      )
    }
  }
  true
}

///|
fn stbi_hdr_load(
  s : StbiContext,
  req_comp_in : Int,
) -> (FixedArray[Float], Int, Int, Int)? {
  if req_comp_in < 0 || req_comp_in > 4 {
    return None
  }
  let header_token = hdr_gettoken(s)
  if header_token != "#?RADIANCE" && header_token != "#?RGBE" {
    return None
  }
  let mut valid = false
  while true {
    let token = hdr_gettoken(s)
    if token.length() == 0 {
      break
    }
    if token == "FORMAT=32-bit_rle_rgbe" {
      valid = true
    }
  }
  if !valid {
    return None
  }
  let dim_token = hdr_gettoken(s)
  let (width, height) = match hdr_parse_dims(dim_token) {
    Some(pair) => pair
    None => return None
  }
  if width <= 0 ||
    width > STBI_MAX_DIMENSIONS ||
    height <= 0 ||
    height > STBI_MAX_DIMENSIONS {
    return None
  }
  let req_comp = if req_comp_in == 0 { 3 } else { req_comp_in }
  if !stbi_mad4sizes_valid(width, height, req_comp, 4, 0) {
    return None
  }
  let hdr_data : FixedArray[Float] = FixedArray::make(
    width * height * req_comp,
    (0.0 : Float),
  )
  let isrle = width >= 8 && width < 32768
  if !hdr_load_pixels(s, hdr_data, width, height, req_comp, isrle) {
    return None
  }
  Some((hdr_data, width, height, 3))
}

///|
fn stbi_hdr_info(s : StbiContext) -> StbiInfo? {
  if !stbi_hdr_test(s) {
    s.rewind()
    return None
  }
  let mut valid = false
  while true {
    let token = hdr_gettoken(s)
    if token.length() == 0 {
      break
    }
    if token == "FORMAT=32-bit_rle_rgbe" {
      valid = true
    }
  }
  if !valid {
    s.rewind()
    return None
  }
  let dim_token = hdr_gettoken(s)
  match hdr_parse_dims(dim_token) {
    None => {
      s.rewind()
      None
    }
    Some((x, y)) =>
      Some({
        width: x,
        height: y,
        channels: 3,
        image_type: StbiImageType::Hdr,
        is_16_bit: false,
        is_hdr: true,
        is_iphone_png: false,
      })
  }
}
