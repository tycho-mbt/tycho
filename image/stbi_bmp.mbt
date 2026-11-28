// Pure MoonBit port of stb_image v2.34 BMP decoder.

///|
fn bmp_test_raw(s : StbiContext) -> Bool {
  if s.get8() != 66 {
    return false
  } // 'B'
  if s.get8() != 77 {
    return false
  } // 'M'
  let _ = s.get32le()
  let _ = s.get16le()
  let _ = s.get16le()
  let _ = s.get32le()
  let sz = s.get32le().reinterpret_as_int()
  sz == 12 || sz == 40 || sz == 56 || sz == 108 || sz == 124
}

///|
fn stbi_bmp_test(s : StbiContext) -> Bool {
  let r = bmp_test_raw(s)
  s.rewind()
  r
}

///|
fn bmp_high_bit(z_in : UInt) -> Int {
  let mut z = z_in
  let mut n = 0
  if z == (0 : UInt) {
    return -1
  }
  if z >= (0x10000 : UInt) {
    n += 16
    z = z >> 16
  }
  if z >= (0x00100 : UInt) {
    n += 8
    z = z >> 8
  }
  if z >= (0x00010 : UInt) {
    n += 4
    z = z >> 4
  }
  if z >= (0x00004 : UInt) {
    n += 2
    z = z >> 2
  }
  if z >= (0x00002 : UInt) {
    n += 1
  }
  n
}

///|
fn bmp_bitcount(a_in : UInt) -> Int {
  let mut a = a_in
  a = (a & (0x55555555 : UInt)) + ((a >> 1) & (0x55555555 : UInt))
  a = (a & (0x33333333 : UInt)) + ((a >> 2) & (0x33333333 : UInt))
  a = (a + (a >> 4)) & (0x0F0F0F0F : UInt)
  a = a + (a >> 8)
  a = a + (a >> 16)
  (a & (0xFF : UInt)).reinterpret_as_int()
}

///|
let bmp_mul_table : FixedArray[UInt] = [
  0, 0xFF, 0x55, 0x49, 0x11, 0x21, 0x41, 0x81, 0x01,
]

///|
let bmp_shift_table : FixedArray[Int] = [0, 0, 0, 1, 0, 2, 4, 6, 0]

///|
fn bmp_shiftsigned(v_in : UInt, shift : Int, bits : Int) -> Int {
  let mut v = if shift < 0 { v_in << -shift } else { v_in >> shift }
  v = v >> (8 - bits)
  ((v * bmp_mul_table[bits]) >> bmp_shift_table[bits]).reinterpret_as_int()
}

///|
priv struct StbiBmpData {
  mut bpp : Int
  mut offset : Int
  mut hsz : Int
  mut mr : UInt
  mut mg : UInt
  mut mb : UInt
  mut ma : UInt
  mut all_a : UInt
  mut extra_read : Int
}

///|
fn bmp_set_mask_defaults(info : StbiBmpData, compress : Int) -> Bool {
  if compress == 3 {
    return true
  }
  if compress == 0 {
    if info.bpp == 16 {
      info.mr = (31 : UInt) << 10
      info.mg = (31 : UInt) << 5
      info.mb = (31 : UInt)
      info.ma = (0 : UInt)
    } else if info.bpp == 32 {
      info.mr = (0xFF : UInt) << 16
      info.mg = (0xFF : UInt) << 8
      info.mb = (0xFF : UInt)
      info.ma = (0 : UInt)
      info.all_a = (0 : UInt)
    } else {
      info.mr = (0 : UInt)
      info.mg = (0 : UInt)
      info.mb = (0 : UInt)
      info.ma = (0 : UInt)
    }
    return true
  }
  false
}

///|
fn bmp_parse_header(s : StbiContext, info : StbiBmpData) -> Bool {
  if s.get8() != 66 || s.get8() != 77 {
    return false
  }
  let _ = s.get32le()
  let _ = s.get16le()
  let _ = s.get16le()
  info.offset = s.get32le().reinterpret_as_int()
  info.hsz = s.get32le().reinterpret_as_int()
  info.mr = (0 : UInt)
  info.mg = (0 : UInt)
  info.mb = (0 : UInt)
  info.ma = (0 : UInt)
  info.extra_read = 14
  if info.offset < 0 {
    return false
  }
  let hsz = info.hsz
  if hsz != 12 && hsz != 40 && hsz != 56 && hsz != 108 && hsz != 124 {
    return false
  }
  if hsz == 12 {
    s.img_x = s.get16le()
    s.img_y = s.get16le()
  } else {
    s.img_x = s.get32le().reinterpret_as_int()
    s.img_y = s.get32le().reinterpret_as_int()
  }
  if s.get16le() != 1 {
    return false
  }
  info.bpp = s.get16le()
  if hsz != 12 {
    let compress = s.get32le().reinterpret_as_int()
    if compress == 1 || compress == 2 || compress >= 4 {
      return false
    }
    if compress == 3 && info.bpp != 16 && info.bpp != 32 {
      return false
    }
    let _ = s.get32le()
    let _ = s.get32le()
    let _ = s.get32le()
    let _ = s.get32le()
    let _ = s.get32le()
    if hsz == 40 {
      if info.bpp == 16 || info.bpp == 32 {
        if compress == 0 {
          let _ = bmp_set_mask_defaults(info, compress)
        } else if compress == 3 {
          info.mr = s.get32le()
          info.mg = s.get32le()
          info.mb = s.get32le()
          info.extra_read += 12
          if info.mr == info.mg && info.mg == info.mb {
            return false
          }
        } else {
          return false
        }
      }
    } else {
      if hsz != 56 && hsz != 108 && hsz != 124 {
        return false
      }
      info.mr = s.get32le()
      info.mg = s.get32le()
      info.mb = s.get32le()
      info.ma = s.get32le()
      if compress != 3 {
        let _ = bmp_set_mask_defaults(info, compress)
      }
      if hsz >= 108 {
        let _ = s.get32le()
        for i = 0; i < 12; i = i + 1 {
          let _ = s.get32le()
        }
      }
      if hsz == 124 {
        let _ = s.get32le()
        let _ = s.get32le()
        let _ = s.get32le()
        let _ = s.get32le()
      }
    }
  }
  true
}

///|
fn stbi_bmp_load(s : StbiContext, req_comp : Int) -> StbiDecodeResult? {
  let info : StbiBmpData = {
    bpp: 0,
    offset: 0,
    hsz: 0,
    mr: (0 : UInt),
    mg: (0 : UInt),
    mb: (0 : UInt),
    ma: (0 : UInt),
    all_a: (255 : UInt),
    extra_read: 0,
  }
  if !bmp_parse_header(s, info) {
    return None
  }
  // Exact match with stb_image v2.34 unsigned img_y / img_x check
  if s.img_y.reinterpret_as_uint() > STBI_MAX_DIMENSIONS.reinterpret_as_uint() ||
    s.img_y < -STBI_MAX_DIMENSIONS ||
    s.img_y == 0 ||
    s.img_x.reinterpret_as_uint() > STBI_MAX_DIMENSIONS.reinterpret_as_uint() ||
    s.img_x <= 0 {
    return None
  }
  let flip_vertically = s.img_y > 0
  if s.img_y < 0 {
    s.img_y = -s.img_y
  }
  let mr = info.mr
  let mg = info.mg
  let mb = info.mb
  let mut ma = info.ma
  let mut all_a = info.all_a

  let bytes_read_so_far = info.hsz + info.extra_read
  if info.offset < bytes_read_so_far {
    return None
  }
  let mut psize = 0
  if info.hsz == 12 {
    if info.bpp < 24 {
      psize = (info.offset - bytes_read_so_far) / 3
    }
  } else if info.bpp < 16 {
    psize = (info.offset - bytes_read_so_far) >> 2
  }
  if psize == 0 {
    if bytes_read_so_far <= 0 || bytes_read_so_far > 1024 {
      return None
    }
    if info.offset < bytes_read_so_far ||
      info.offset - bytes_read_so_far > 256 * 4 {
      return None
    }
    s.skip(info.offset - bytes_read_so_far)
  }

  if info.bpp == 24 && ma == (0xFF000000 : UInt) {
    s.img_n = 3
  } else {
    s.img_n = if ma != (0 : UInt) { 4 } else { 3 }
  }
  let target = if req_comp != 0 && req_comp >= 3 { req_comp } else { s.img_n }
  if !stbi_mad3sizes_valid(target, s.img_x, s.img_y, 0) {
    return None
  }
  let mut out : FixedArray[Byte] = FixedArray::make(
    target * s.img_x * s.img_y,
    (0 : Byte),
  )

  if info.bpp < 16 {
    if psize == 0 || psize > 256 {
      return None
    }
    let pal : FixedArray[Byte] = FixedArray::make(256 * 4, (0 : Byte))
    for i = 0; i < psize; i = i + 1 {
      pal[i * 4 + 2] = s.get8().to_byte()
      pal[i * 4 + 1] = s.get8().to_byte()
      pal[i * 4] = s.get8().to_byte()
      if info.hsz != 12 {
        let _ = s.get8()
      }
      pal[i * 4 + 3] = (255 : Byte)
    }
    s.skip(
      info.offset -
      info.extra_read -
      info.hsz -
      psize * (if info.hsz == 12 { 3 } else { 4 }),
    )
    let width = if info.bpp == 1 {
      (s.img_x + 7) >> 3
    } else if info.bpp == 4 {
      (s.img_x + 1) >> 1
    } else if info.bpp == 8 {
      s.img_x
    } else {
      return None
    }
    let pad = -width & 3
    let mut z = 0
    if info.bpp == 1 {
      for j = 0; j < s.img_y; j = j + 1 {
        let mut bit_offset = 7
        let mut v = s.get8()
        for i = 0; i < s.img_x; i = i + 1 {
          let color = (v >> bit_offset) & 1
          out[z] = pal[color * 4]
          out[z + 1] = pal[color * 4 + 1]
          out[z + 2] = pal[color * 4 + 2]
          z += 3
          if target == 4 {
            out[z] = (255 : Byte)
            z += 1
          }
          if i + 1 == s.img_x {
            break
          }
          bit_offset -= 1
          if bit_offset < 0 {
            bit_offset = 7
            v = s.get8()
          }
        }
        s.skip(pad)
      }
    } else {
      for j = 0; j < s.img_y; j = j + 1 {
        for i = 0; i < s.img_x; i = i + 2 {
          let mut v = s.get8()
          let mut v2 = 0
          if info.bpp == 4 {
            v2 = v & 15
            v = v >> 4
          }
          out[z] = pal[v * 4]
          out[z + 1] = pal[v * 4 + 1]
          out[z + 2] = pal[v * 4 + 2]
          z += 3
          if target == 4 {
            out[z] = (255 : Byte)
            z += 1
          }
          if i + 1 == s.img_x {
            break
          }
          v = if info.bpp == 8 { s.get8() } else { v2 }
          out[z] = pal[v * 4]
          out[z + 1] = pal[v * 4 + 1]
          out[z + 2] = pal[v * 4 + 2]
          z += 3
          if target == 4 {
            out[z] = (255 : Byte)
            z += 1
          }
        }
        s.skip(pad)
      }
    }
  } else {
    let width = if info.bpp == 24 {
      3 * s.img_x
    } else if info.bpp == 16 {
      2 * s.img_x
    } else {
      0
    }
    let pad = -width & 3
    let mut easy = 0
    let mut alpha_override = 0
    if info.bpp == 24 {
      easy = 1
    } else if info.bpp == 32 {
      if info.hsz < 56 {
        ma = (0 : UInt)
      }
      if mb == (0xFF : UInt) &&
        mg == (0xFF00 : UInt) &&
        mr == (0x00FF0000 : UInt) &&
        (ma == (0xFF000000 : UInt) || ma == (0 : UInt)) {
        easy = 2
        alpha_override = if ma != (0 : UInt) { 0 } else { 255 }
      }
    }
    let mut rshift = 0
    let mut gshift = 0
    let mut bshift = 0
    let mut ashift = 0
    let mut rcount = 0
    let mut gcount = 0
    let mut bcount = 0
    let mut acount = 0
    if easy == 0 {
      if mr == (0 : UInt) || mg == (0 : UInt) || mb == (0 : UInt) {
        return None
      }
      rshift = bmp_high_bit(mr) - 7
      rcount = bmp_bitcount(mr)
      gshift = bmp_high_bit(mg) - 7
      gcount = bmp_bitcount(mg)
      bshift = bmp_high_bit(mb) - 7
      bcount = bmp_bitcount(mb)
      ashift = bmp_high_bit(ma) - 7
      acount = bmp_bitcount(ma)
      if rcount > 8 || gcount > 8 || bcount > 8 || acount > 8 {
        return None
      }
    }
    let mut z = 0
    for j = 0; j < s.img_y; j = j + 1 {
      if easy != 0 {
        for i = 0; i < s.img_x; i = i + 1 {
          out[z + 2] = s.get8().to_byte()
          out[z + 1] = s.get8().to_byte()
          out[z] = s.get8().to_byte()
          z += 3
          let a = if easy == 2 { s.get8() | alpha_override } else { 255 }
          all_a = all_a | a.reinterpret_as_uint()
          if target == 4 {
            out[z] = a.to_byte()
            z += 1
          }
        }
      } else {
        for i = 0; i < s.img_x; i = i + 1 {
          let v = if info.bpp == 16 {
            s.get16le().reinterpret_as_uint()
          } else {
            s.get32le()
          }
          out[z] = bmp_shiftsigned(v & mr, rshift, rcount).to_byte()
          out[z + 1] = bmp_shiftsigned(v & mg, gshift, gcount).to_byte()
          out[z + 2] = bmp_shiftsigned(v & mb, bshift, bcount).to_byte()
          z += 3
          let a = if ma != (0 : UInt) {
            bmp_shiftsigned(v & ma, ashift, acount)
          } else {
            255
          }
          all_a = all_a | a.reinterpret_as_uint()
          if target == 4 {
            out[z] = a.to_byte()
            z += 1
          }
        }
      }
      s.skip(pad)
    }
  }

  if target == 4 && all_a == (0 : UInt) {
    let mut i = 4 * s.img_x * s.img_y - 1
    while i >= 0 {
      out[i] = (255 : Byte)
      i -= 4
    }
  }

  if flip_vertically {
    stbi_vertical_flip_bytes(out, s.img_x, s.img_y, target)
  }

  if req_comp != 0 && req_comp != target {
    match stbi_convert_format(out, target, req_comp, s.img_x, s.img_y) {
      Some(c) => out = c
      None => return None
    }
  }

  Some({
    width: s.img_x,
    height: s.img_y,
    comp: s.img_n,
    pixels: StbiRawPixels::Bits8(out),
  })
}

///|
fn stbi_bmp_info(s : StbiContext) -> StbiInfo? {
  let info : StbiBmpData = {
    bpp: 0,
    offset: 0,
    hsz: 0,
    mr: (0 : UInt),
    mg: (0 : UInt),
    mb: (0 : UInt),
    ma: (0 : UInt),
    all_a: (255 : UInt),
    extra_read: 0,
  }
  if !bmp_parse_header(s, info) {
    s.rewind()
    return None
  }
  let comp = if info.bpp == 24 && info.ma == (0xFF000000 : UInt) {
    3
  } else if info.ma != (0 : UInt) {
    4
  } else {
    3
  }
  Some({
    width: s.img_x,
    height: s.img_y,
    channels: comp,
    image_type: StbiImageType::Bmp,
    is_16_bit: false,
    is_hdr: false,
    is_iphone_png: false,
  })
}
