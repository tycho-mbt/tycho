// Pure MoonBit port of stb_image v2.34 Photoshop PSD decoder.

///|
fn stbi_psd_test(s : StbiContext) -> Bool {
  let r = s.get32be() == (0x38425053 : UInt)
  s.rewind()
  r
}

///|
fn psd_decode_rle(
  s : StbiContext,
  out : FixedArray[Byte],
  channel : Int,
  pixel_count : Int,
) -> Bool {
  let mut count = 0
  let mut p = channel
  while count < pixel_count {
    let nleft = pixel_count - count
    let len_raw = s.get8()
    if len_raw == 128 {
      // No-op
    } else if len_raw < 128 {
      let len = len_raw + 1
      if len > nleft {
        return false
      }
      count += len
      for i = 0; i < len; i = i + 1 {
        out[p] = s.get8().to_byte()
        p += 4
      }
    } else {
      let len = 257 - len_raw
      if len > nleft {
        return false
      }
      let val = s.get8().to_byte()
      count += len
      for i = 0; i < len; i = i + 1 {
        out[p] = val
        p += 4
      }
    }
  }
  true
}

///|
fn stbi_psd_load(
  s : StbiContext,
  req_comp : Int,
  bpc : Int,
) -> StbiDecodeResult? {
  if s.get32be() != (0x38425053 : UInt) {
    return None
  }
  if s.get16be() != 1 {
    return None
  }
  s.skip(6)
  let channel_count = s.get16be()
  if channel_count < 0 || channel_count > 16 {
    return None
  }
  let h_u = s.get32be()
  let w_u = s.get32be()
  if h_u > STBI_MAX_DIMENSIONS.reinterpret_as_uint() ||
    w_u > STBI_MAX_DIMENSIONS.reinterpret_as_uint() {
    return None
  }
  let h = h_u.reinterpret_as_int()
  let w = w_u.reinterpret_as_int()
  let bitdepth = s.get16be()
  if bitdepth != 8 && bitdepth != 16 {
    return None
  }
  if s.get16be() != 3 {
    return None
  }
  s.skip(s.get32be().reinterpret_as_int())
  s.skip(s.get32be().reinterpret_as_int())
  s.skip(s.get32be().reinterpret_as_int())
  let compression = s.get16be()
  if compression > 1 {
    return None
  }
  if !stbi_mad3sizes_valid(4, w, h, 0) {
    return None
  }
  let pixel_count = w * h
  let out_16 = compression == 0 && bitdepth == 16 && bpc == 16

  if out_16 {
    if !stbi_mad3sizes_valid(8, w, h, 0) {
      return None
    }
    let mut out16 : FixedArray[UInt16] = FixedArray::make(
      4 * pixel_count,
      (0 : UInt16),
    )
    for ch = 0; ch < 4; ch = ch + 1 {
      if ch >= channel_count {
        let val : UInt16 = if ch == 3 { (65535 : UInt16) } else { (0 : UInt16) }
        for i = 0; i < pixel_count; i = i + 1 {
          out16[i * 4 + ch] = val
        }
      } else {
        for i = 0; i < pixel_count; i = i + 1 {
          out16[i * 4 + ch] = s.get16be().to_uint16()
        }
      }
    }
    if channel_count >= 4 {
      for i = 0; i < pixel_count; i = i + 1 {
        let base = i * 4
        let alpha = out16[base + 3].to_int()
        if alpha != 0 && alpha != 65535 {
          let a : Float = Float::from_int(alpha) / (65535.0 : Float)
          let ra : Float = (1.0 : Float) / a
          let inv_a : Float = (65535.0 : Float) * ((1.0 : Float) - ra)
          out16[base] = (Float::from_int(out16[base].to_int()) * ra + inv_a)
            .to_int()
            .to_uint16()
          out16[base + 1] = (Float::from_int(out16[base + 1].to_int()) * ra +
            inv_a)
            .to_int()
            .to_uint16()
          out16[base + 2] = (Float::from_int(out16[base + 2].to_int()) * ra +
            inv_a)
            .to_int()
            .to_uint16()
        }
      }
    }
    if req_comp != 0 && req_comp != 4 {
      match stbi_convert_format16(out16, 4, req_comp, w, h) {
        Some(c) => out16 = c
        None => return None
      }
    }
    Some({ width: w, height: h, comp: 4, pixels: StbiRawPixels::Bits16(out16) })
  } else {
    let mut out8 : FixedArray[Byte] = FixedArray::make(
      4 * pixel_count,
      (0 : Byte),
    )
    if compression != 0 {
      s.skip(h * channel_count * 2)
      for ch = 0; ch < 4; ch = ch + 1 {
        if ch >= channel_count {
          let val : Byte = if ch == 3 { (255 : Byte) } else { (0 : Byte) }
          for i = 0; i < pixel_count; i = i + 1 {
            out8[i * 4 + ch] = val
          }
        } else if !psd_decode_rle(s, out8, ch, pixel_count) {
          return None
        }
      }
    } else {
      for ch = 0; ch < 4; ch = ch + 1 {
        if ch >= channel_count {
          let val : Byte = if ch == 3 { (255 : Byte) } else { (0 : Byte) }
          for i = 0; i < pixel_count; i = i + 1 {
            out8[i * 4 + ch] = val
          }
        } else if bitdepth == 16 {
          for i = 0; i < pixel_count; i = i + 1 {
            out8[i * 4 + ch] = (s.get16be() >> 8).to_byte()
          }
        } else {
          for i = 0; i < pixel_count; i = i + 1 {
            out8[i * 4 + ch] = s.get8().to_byte()
          }
        }
      }
    }
    if channel_count >= 4 {
      for i = 0; i < pixel_count; i = i + 1 {
        let base = i * 4
        let alpha = out8[base + 3].to_int()
        if alpha != 0 && alpha != 255 {
          let a : Float = Float::from_int(alpha) / (255.0 : Float)
          let ra : Float = (1.0 : Float) / a
          let inv_a : Float = (255.0 : Float) * ((1.0 : Float) - ra)
          out8[base] = (Float::from_int(out8[base].to_int()) * ra + inv_a)
            .to_int()
            .to_byte()
          out8[base + 1] = (Float::from_int(out8[base + 1].to_int()) * ra +
            inv_a)
            .to_int()
            .to_byte()
          out8[base + 2] = (Float::from_int(out8[base + 2].to_int()) * ra +
            inv_a)
            .to_int()
            .to_byte()
        }
      }
    }
    if req_comp != 0 && req_comp != 4 {
      match stbi_convert_format(out8, 4, req_comp, w, h) {
        Some(c) => out8 = c
        None => return None
      }
    }
    Some({ width: w, height: h, comp: 4, pixels: StbiRawPixels::Bits8(out8) })
  }
}

///|
fn stbi_psd_info(s : StbiContext) -> StbiInfo? {
  if s.get32be() != (0x38425053 : UInt) {
    s.rewind()
    return None
  }
  if s.get16be() != 1 {
    s.rewind()
    return None
  }
  s.skip(6)
  let channel_count = s.get16be()
  if channel_count < 0 || channel_count > 16 {
    s.rewind()
    return None
  }
  let y = s.get32be().reinterpret_as_int()
  let x = s.get32be().reinterpret_as_int()
  let depth = s.get16be()
  if depth != 8 && depth != 16 {
    s.rewind()
    return None
  }
  if s.get16be() != 3 {
    s.rewind()
    return None
  }
  Some({
    width: x,
    height: y,
    channels: 4,
    image_type: StbiImageType::Psd,
    is_16_bit: depth == 16,
    is_hdr: false,
    is_iphone_png: false,
  })
}
