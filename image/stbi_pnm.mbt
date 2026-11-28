// Pure MoonBit port of stb_image v2.34 PNM (P2/P3/P5/P6 PGM/PPM) decoder.

///|
fn stbi_pnm_test(s : StbiContext) -> Bool {
  let p = s.get8()
  let t = s.get8()
  s.rewind()
  p == 80 && (t == 50 || t == 51 || t == 53 || t == 54)
}

///|
fn pnm_isspace(c : Int) -> Bool {
  c == 32 || c == 9 || c == 10 || c == 11 || c == 12 || c == 13
}

///|
fn pnm_skip_whitespace(s : StbiContext, c_in : Int) -> Int {
  let mut c = c_in
  while true {
    while !s.at_eof() && pnm_isspace(c) {
      c = s.get8()
    }
    if s.at_eof() || c != 35 {
      break
    }
    while !s.at_eof() && c != 10 && c != 13 {
      c = s.get8()
    }
  }
  c
}

///|
fn pnm_getinteger(s : StbiContext, c_in : Int) -> (Int, Int, Bool) {
  let mut c = c_in
  let mut value = 0
  while !s.at_eof() && c >= 48 && c <= 57 {
    value = value * 10 + (c - 48)
    c = s.get8()
    if value > 214748364 || (value == 214748364 && c > 55) {
      return (0, c, false)
    }
  }
  (value, c, true)
}

///|
priv struct PnmHeader {
  x : Int
  y : Int
  comp : Int
  maxv : Int
  bits : Int
  is_ascii : Bool
}

///|
fn pnm_info_internal(s : StbiContext) -> PnmHeader? {
  s.rewind()
  let p = s.get8()
  let t = s.get8()
  if p != 80 || (t != 50 && t != 51 && t != 53 && t != 54) {
    s.rewind()
    return None
  }
  let comp = if t == 51 || t == 54 { 3 } else { 1 }
  let is_ascii = t == 50 || t == 51
  let mut c = s.get8()
  c = pnm_skip_whitespace(s, c)
  let (x, c1, ok1) = pnm_getinteger(s, c)
  if !ok1 || x == 0 {
    return None
  }
  c = pnm_skip_whitespace(s, c1)
  let (y, c2, ok2) = pnm_getinteger(s, c)
  if !ok2 || y == 0 {
    return None
  }
  c = pnm_skip_whitespace(s, c2)
  let (maxv, _, ok3) = pnm_getinteger(s, c)
  if !ok3 || maxv == 0 || maxv > 65535 {
    return None
  }
  let bits = if maxv > 255 { 16 } else { 8 }
  Some({ x, y, comp, maxv, bits, is_ascii })
}

///|
fn stbi_pnm_load(s : StbiContext, req_comp : Int) -> StbiDecodeResult? {
  let hdr = match pnm_info_internal(s) {
    Some(h) => h
    None => return None
  }
  if hdr.y > STBI_MAX_DIMENSIONS || hdr.x > STBI_MAX_DIMENSIONS {
    return None
  }
  s.img_x = hdr.x
  s.img_y = hdr.y
  s.img_n = hdr.comp
  let bpv = hdr.bits / 8
  if !stbi_mad4sizes_valid(hdr.comp, hdr.x, hdr.y, bpv, 0) {
    return None
  }
  let nvals = hdr.comp * hdr.x * hdr.y
  let raw : FixedArray[Byte] = FixedArray::make(nvals * bpv, (0 : Byte))
  if !hdr.is_ascii {
    if !s.getn(raw, 0, nvals * bpv) {
      return None
    }
  } else {
    let mut c = s.get8()
    for i = 0; i < nvals; i = i + 1 {
      c = pnm_skip_whitespace(s, c)
      let (val0, c_next, ok) = pnm_getinteger(s, c)
      if !ok || val0 < 0 {
        return None
      }
      c = c_next
      let val = if val0 > hdr.maxv { hdr.maxv - 1 } else { val0 }
      if bpv == 1 {
        raw[i] = val.to_byte()
      } else {
        raw[i * 2] = (val >> 8).to_byte()
        raw[i * 2 + 1] = val.to_byte()
      }
    }
  }

  if bpv == 2 {
    let mut out16 : FixedArray[UInt16] = FixedArray::make(nvals, (0 : UInt16))
    for i = 0; i < nvals; i = i + 1 {
      let mut val = (raw[i * 2].to_int() << 8) + raw[i * 2 + 1].to_int()
      if hdr.maxv != 65535 {
        if val >= hdr.maxv {
          val = hdr.maxv - 1
        }
        val = (val * 65535) / hdr.maxv
      }
      out16[i] = val.to_uint16()
    }
    if req_comp != 0 && req_comp != hdr.comp {
      match stbi_convert_format16(out16, hdr.comp, req_comp, hdr.x, hdr.y) {
        Some(c) => out16 = c
        None => return None
      }
    }
    Some({
      width: hdr.x,
      height: hdr.y,
      comp: hdr.comp,
      pixels: StbiRawPixels::Bits16(out16),
    })
  } else {
    let mut out8 = raw
    if hdr.maxv != 255 {
      for i = 0; i < nvals; i = i + 1 {
        let mut val = out8[i].to_int()
        if val >= hdr.maxv {
          val = hdr.maxv - 1
        }
        out8[i] = ((val * 255) / hdr.maxv).to_byte()
      }
    }
    if req_comp != 0 && req_comp != hdr.comp {
      match stbi_convert_format(out8, hdr.comp, req_comp, hdr.x, hdr.y) {
        Some(c) => out8 = c
        None => return None
      }
    }
    Some({
      width: hdr.x,
      height: hdr.y,
      comp: hdr.comp,
      pixels: StbiRawPixels::Bits8(out8),
    })
  }
}

///|
fn stbi_pnm_info(s : StbiContext) -> StbiInfo? {
  match pnm_info_internal(s) {
    None => None
    Some(h) =>
      Some({
        width: h.x,
        height: h.y,
        channels: h.comp,
        image_type: StbiImageType::Pnm,
        is_16_bit: h.bits == 16,
        is_hdr: false,
        is_iphone_png: false,
      })
  }
}
