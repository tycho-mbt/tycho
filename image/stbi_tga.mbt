// Pure MoonBit port of stb_image v2.34 TGA decoder.

///|
fn tga_get_comp(bits_per_pixel : Int, is_grey : Bool) -> (Int, Bool) {
  if is_grey && bits_per_pixel == 16 {
    return (2, false)
  }
  if bits_per_pixel == 15 || bits_per_pixel == 16 {
    return (3, true)
  }
  match bits_per_pixel {
    8 => (1, false)
    24 => (3, false)
    32 => (4, false)
    _ => (0, false)
  }
}

///|
fn tga_info_impl(s : StbiContext) -> (Int, Int, Int)? {
  let _ = s.get8() // id len
  let tga_colormap_type = s.get8()
  if tga_colormap_type > 1 {
    return None
  }
  let tga_image_type = s.get8()
  let tga_colormap_bpp = if tga_colormap_type == 1 {
    if tga_image_type != 1 && tga_image_type != 9 {
      return None
    }
    s.skip(4)
    let sz = s.get8()
    if sz != 8 && sz != 15 && sz != 16 && sz != 24 && sz != 32 {
      return None
    }
    s.skip(4)
    sz
  } else {
    if tga_image_type != 2 &&
      tga_image_type != 3 &&
      tga_image_type != 10 &&
      tga_image_type != 11 {
      return None
    }
    s.skip(9)
    0
  }
  let tga_w = s.get16le()
  let tga_h = s.get16le()
  if tga_w < 1 || tga_h < 1 {
    return None
  }
  let tga_bpp = s.get8()
  let _ = s.get8()
  let (tga_comp, _) = if tga_colormap_bpp != 0 {
    if tga_bpp != 8 && tga_bpp != 16 {
      return None
    }
    tga_get_comp(tga_colormap_bpp, false)
  } else {
    tga_get_comp(tga_bpp, tga_image_type == 3 || tga_image_type == 11)
  }
  if tga_comp == 0 {
    return None
  }
  Some((tga_w, tga_h, tga_comp))
}

///|
fn stbi_tga_info(s : StbiContext) -> StbiInfo? {
  match tga_info_impl(s) {
    None => {
      s.rewind()
      None
    }
    Some((w, h, comp)) =>
      Some({
        width: w,
        height: h,
        channels: comp,
        image_type: StbiImageType::Tga,
        is_16_bit: false,
        is_hdr: false,
        is_iphone_png: false,
      })
  }
}

///|
fn stbi_tga_test(s : StbiContext) -> Bool {
  let res = match tga_info_impl(s) {
    Some(_) => true
    None => false
  }
  s.rewind()
  res
}

///|
fn tga_read_rgb16(
  s : StbiContext,
  out : FixedArray[Byte],
  off : Int,
) -> Unit {
  let px = s.get16le()
  let r = (px >> 10) & 31
  let g = (px >> 5) & 31
  let b = px & 31
  out[off] = ((r * 255) / 31).to_byte()
  out[off + 1] = ((g * 255) / 31).to_byte()
  out[off + 2] = ((b * 255) / 31).to_byte()
}

///|
fn stbi_tga_load(s : StbiContext, req_comp : Int) -> StbiDecodeResult? {
  let tga_offset = s.get8()
  let tga_indexed = s.get8() != 0
  let mut tga_image_type = s.get8()
  let mut tga_is_rle = false
  let tga_palette_start = s.get16le()
  let tga_palette_len = s.get16le()
  let tga_palette_bits = s.get8()
  let _ = s.get16le() // x origin
  let _ = s.get16le() // y origin
  let tga_width = s.get16le()
  let tga_height = s.get16le()
  let tga_bpp = s.get8()
  let tga_desc = s.get8()

  if tga_width > STBI_MAX_DIMENSIONS || tga_height > STBI_MAX_DIMENSIONS {
    return None
  }
  if tga_width == 0 || tga_height == 0 {
    return None
  }
  if tga_image_type >= 8 {
    tga_image_type -= 8
    tga_is_rle = true
  }
  let (tga_comp, tga_rgb16) = if tga_indexed {
    tga_get_comp(tga_palette_bits, false)
  } else {
    tga_get_comp(tga_bpp, tga_image_type == 3)
  }
  if tga_comp == 0 {
    return None
  }
  if !stbi_mad3sizes_valid(tga_width, tga_height, tga_comp, 0) {
    return None
  }
  let mut tga_data : FixedArray[Byte] = FixedArray::make(
    tga_width * tga_height * tga_comp,
    (0 : Byte),
  )
  s.skip(tga_offset)

  if !tga_indexed && !tga_is_rle && !tga_rgb16 {
    for i = 0; i < tga_height; i = i + 1 {
      if !s.getn(tga_data, i * tga_width * tga_comp, tga_width * tga_comp) {
        return None
      }
    }
  } else {
    let mut tga_palette : FixedArray[Byte] = FixedArray::make(0, (0 : Byte))
    if tga_indexed {
      if tga_palette_len == 0 ||
        !stbi_mad2sizes_valid(tga_palette_len, tga_comp, 0) {
        return None
      }
      s.skip(tga_palette_start)
      tga_palette = FixedArray::make(tga_palette_len * tga_comp, (0 : Byte))
      if tga_rgb16 {
        for i = 0; i < tga_palette_len; i = i + 1 {
          tga_read_rgb16(s, tga_palette, i * tga_comp)
        }
      } else if !s.getn(tga_palette, 0, tga_palette_len * tga_comp) {
        return None
      }
    }
    let raw_data : FixedArray[Byte] = FixedArray::make(4, (0 : Byte))
    let mut rle_count = 0
    let mut rle_repeating = false
    let mut read_next_pixel = true
    let total = tga_width * tga_height
    for i = 0; i < total; i = i + 1 {
      if tga_is_rle {
        if rle_count == 0 {
          let cmd = s.get8()
          rle_count = 1 + (cmd & 127)
          rle_repeating = (cmd >> 7) != 0
          read_next_pixel = true
        } else if !rle_repeating {
          read_next_pixel = true
        }
      } else {
        read_next_pixel = true
      }
      if read_next_pixel {
        if tga_indexed {
          let mut pal_idx = if tga_bpp == 8 { s.get8() } else { s.get16le() }
          if pal_idx >= tga_palette_len {
            pal_idx = 0
          }
          let base = pal_idx * tga_comp
          for j = 0; j < tga_comp; j = j + 1 {
            raw_data[j] = tga_palette[base + j]
          }
        } else if tga_rgb16 {
          tga_read_rgb16(s, raw_data, 0)
        } else {
          for j = 0; j < tga_comp; j = j + 1 {
            raw_data[j] = s.get8().to_byte()
          }
        }
        read_next_pixel = false
      }
      let dst = i * tga_comp
      for j = 0; j < tga_comp; j = j + 1 {
        tga_data[dst + j] = raw_data[j]
      }
      rle_count -= 1
    }
  }

  // Horizontal flip
  if (tga_desc & 0x10) != 0 {
    let half_w = tga_width / 2
    for i = 0; i < tga_height; i = i + 1 {
      let row = i * tga_width * tga_comp
      for j = 0; j < half_w; j = j + 1 {
        let p = row + j * tga_comp
        let q = row + (tga_width - 1 - j) * tga_comp
        for k = 0; k < tga_comp; k = k + 1 {
          let t = tga_data[p + k]
          tga_data[p + k] = tga_data[q + k]
          tga_data[q + k] = t
        }
      }
    }
  }

  // Vertical flip
  if (tga_desc & 0x20) == 0 {
    stbi_vertical_flip_bytes(tga_data, tga_width, tga_height, tga_comp)
  }

  // Swap BGR -> RGB
  if tga_comp >= 3 && !tga_rgb16 {
    let total = tga_width * tga_height
    for i = 0; i < total; i = i + 1 {
      let base = i * tga_comp
      let t = tga_data[base]
      tga_data[base] = tga_data[base + 2]
      tga_data[base + 2] = t
    }
  }

  if req_comp != 0 && req_comp != tga_comp {
    match stbi_convert_format(tga_data, tga_comp, req_comp, tga_width, tga_height) {
      Some(c) => tga_data = c
      None => return None
    }
  }

  Some({
    width: tga_width,
    height: tga_height,
    comp: tga_comp,
    pixels: StbiRawPixels::Bits8(tga_data),
  })
}
