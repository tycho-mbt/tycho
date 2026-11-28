// Pure MoonBit port of stb_image v2.34 PNG decoder.
// Supports 1/2/4/8/16-bit per channel, color types 0/2/3/4/6, PLTE, tRNS,
// all 5 scanline filters, Adam7 interlacing, and iPhone CgBI PNGs.

///|
let png_sig : FixedArray[Int] = [137, 80, 78, 71, 13, 10, 26, 10]

///|
let png_first_row_filter : FixedArray[Int] = [0, 1, 0, 5, 1]

///|
let png_depth_scale_table : FixedArray[Int] = [0, 0xFF, 0x55, 0, 0x11, 0, 0, 0, 0x01]

///|
fn png_type(a : Int, b : Int, c : Int, d : Int) -> UInt {
  (a.reinterpret_as_uint() << 24) +
  (b.reinterpret_as_uint() << 16) +
  (c.reinterpret_as_uint() << 8) +
  d.reinterpret_as_uint()
}

///|
fn png_paeth(a : Int, b : Int, c : Int) -> Int {
  let thresh = c * 3 - (a + b)
  let lo = if a < b { a } else { b }
  let hi = if a < b { b } else { a }
  let t0 = if hi <= thresh { lo } else { c }
  if thresh <= lo {
    hi
  } else {
    t0
  }
}

///|
fn png_check_header(s : StbiContext) -> Bool {
  for i = 0; i < 8; i = i + 1 {
    if s.get8() != png_sig[i] {
      s.set_err("bad png sig")
      return false
    }
  }
  true
}

///|
fn stbi_png_test(s : StbiContext) -> Bool {
  let r = png_check_header(s)
  s.rewind()
  r
}

///|
priv struct StbiPng {
  s : StbiContext
  mut depth : Int
  mut is_iphone : Bool
  mut out8 : FixedArray[Byte]
  mut out16 : FixedArray[UInt16]
}

///|
fn png_alpha_expand8(
  dest : FixedArray[Byte],
  dest_off : Int,
  src : FixedArray[Byte],
  src_off : Int,
  x : Int,
  img_n : Int,
) -> Unit {
  if img_n == 1 {
    for i = x - 1; i >= 0; i = i - 1 {
      dest[dest_off + i * 2 + 1] = (255 : Byte)
      dest[dest_off + i * 2] = src[src_off + i]
    }
  } else {
    for i = x - 1; i >= 0; i = i - 1 {
      dest[dest_off + i * 4 + 3] = (255 : Byte)
      dest[dest_off + i * 4 + 2] = src[src_off + i * 3 + 2]
      dest[dest_off + i * 4 + 1] = src[src_off + i * 3 + 1]
      dest[dest_off + i * 4] = src[src_off + i * 3]
    }
  }
}

///|
fn png_create_image_raw(
  a : StbiPng,
  raw : FixedArray[Byte],
  raw_off : Int,
  raw_len : Int,
  out_n : Int,
  x : Int,
  y : Int,
  depth : Int,
  color : Int,
) -> Bool {
  let s = a.s
  let img_n = s.img_n
  if !stbi_mad3sizes_valid(img_n, x, depth, 7) {
    s.set_err("too large")
    return false
  }
  let img_width_bytes = (img_n * x * depth + 7) >> 3
  if !stbi_mad2sizes_valid(img_width_bytes, y, img_width_bytes) {
    s.set_err("too large")
    return false
  }
  let img_len = (img_width_bytes + 1) * y
  if raw_len < img_len {
    s.set_err("not enough pixels")
    return false
  }
  if depth == 16 {
    if !stbi_mad4sizes_valid(x, y, out_n, 2, 0) {
      s.set_err("too large")
      return false
    }
    a.out16 = FixedArray::make(x * y * out_n, (0 : UInt16))
  } else {
    if !stbi_mad3sizes_valid(x, y, out_n, 0) {
      s.set_err("too large")
      return false
    }
    a.out8 = FixedArray::make(x * y * out_n, (0 : Byte))
  }
  let filter_buf : FixedArray[Byte] = FixedArray::make(
    img_width_bytes * 2,
    (0 : Byte),
  )
  let bytes = if depth == 16 { 2 } else { 1 }
  let filter_bytes = if depth < 8 { 1 } else { img_n * bytes }
  let width = if depth < 8 { img_width_bytes } else { x }
  let nk = width * filter_bytes
  let mut rpos = raw_off
  for j = 0; j < y; j = j + 1 {
    let cur_off = (j & 1) * img_width_bytes
    let prior_off = ((j ^ 1) & 1) * img_width_bytes
    let mut filter = raw[rpos].to_int()
    rpos += 1
    if filter > 4 {
      s.set_err("invalid filter")
      return false
    }
    if j == 0 {
      filter = png_first_row_filter[filter]
    }
    match filter {
      0 => // None
        for k = 0; k < nk; k = k + 1 {
          filter_buf[cur_off + k] = raw[rpos + k]
        }
      1 => { // Sub
        for k = 0; k < filter_bytes; k = k + 1 {
          filter_buf[cur_off + k] = raw[rpos + k]
        }
        for k = filter_bytes; k < nk; k = k + 1 {
          filter_buf[cur_off + k] = (raw[rpos + k].to_int() +
            filter_buf[cur_off + k - filter_bytes].to_int()).to_byte()
        }
      }
      2 => // Up
        for k = 0; k < nk; k = k + 1 {
          filter_buf[cur_off + k] = (raw[rpos + k].to_int() +
            filter_buf[prior_off + k].to_int()).to_byte()
        }
      3 => { // Avg
        for k = 0; k < filter_bytes; k = k + 1 {
          filter_buf[cur_off + k] = (raw[rpos + k].to_int() +
            (filter_buf[prior_off + k].to_int() >> 1)).to_byte()
        }
        for k = filter_bytes; k < nk; k = k + 1 {
          filter_buf[cur_off + k] = (raw[rpos + k].to_int() +
            ((filter_buf[prior_off + k].to_int() +
              filter_buf[cur_off + k - filter_bytes].to_int()) >>
            1)).to_byte()
        }
      }
      4 => { // Paeth
        for k = 0; k < filter_bytes; k = k + 1 {
          filter_buf[cur_off + k] = (raw[rpos + k].to_int() +
            filter_buf[prior_off + k].to_int()).to_byte()
        }
        for k = filter_bytes; k < nk; k = k + 1 {
          let p = png_paeth(
            filter_buf[cur_off + k - filter_bytes].to_int(),
            filter_buf[prior_off + k].to_int(),
            filter_buf[prior_off + k - filter_bytes].to_int(),
          )
          filter_buf[cur_off + k] = (raw[rpos + k].to_int() + p).to_byte()
        }
      }
      5 => { // Avg first row
        for k = 0; k < filter_bytes; k = k + 1 {
          filter_buf[cur_off + k] = raw[rpos + k]
        }
        for k = filter_bytes; k < nk; k = k + 1 {
          filter_buf[cur_off + k] = (raw[rpos + k].to_int() +
            (filter_buf[cur_off + k - filter_bytes].to_int() >> 1)).to_byte()
        }
      }
      _ => return false
    }
    rpos += nk
    let dest_off = j * x * out_n
    if depth < 8 {
      let scale = if color == 0 { png_depth_scale_table[depth] } else { 1 }
      let nsmp = x * img_n
      let mut in_idx = cur_off
      let mut inb = 0
      if depth == 4 {
        for i = 0; i < nsmp; i = i + 1 {
          if (i & 1) == 0 {
            inb = filter_buf[in_idx].to_int()
            in_idx += 1
          }
          a.out8[dest_off + i] = (scale * (inb >> 4)).to_byte()
          inb = (inb << 4) & 0xFF
        }
      } else if depth == 2 {
        for i = 0; i < nsmp; i = i + 1 {
          if (i & 3) == 0 {
            inb = filter_buf[in_idx].to_int()
            in_idx += 1
          }
          a.out8[dest_off + i] = (scale * (inb >> 6)).to_byte()
          inb = (inb << 2) & 0xFF
        }
      } else {
        for i = 0; i < nsmp; i = i + 1 {
          if (i & 7) == 0 {
            inb = filter_buf[in_idx].to_int()
            in_idx += 1
          }
          a.out8[dest_off + i] = (scale * (inb >> 7)).to_byte()
          inb = (inb << 1) & 0xFF
        }
      }
      if img_n != out_n {
        png_alpha_expand8(a.out8, dest_off, a.out8, dest_off, x, img_n)
      }
    } else if depth == 8 {
      if img_n == out_n {
        let row_n = x * img_n
        for i = 0; i < row_n; i = i + 1 {
          a.out8[dest_off + i] = filter_buf[cur_off + i]
        }
      } else {
        png_alpha_expand8(a.out8, dest_off, filter_buf, cur_off, x, img_n)
      }
    } else {
      // depth == 16
      let nsmp = x * img_n
      if img_n == out_n {
        for i = 0; i < nsmp; i = i + 1 {
          let c0 = filter_buf[cur_off + i * 2].to_int()
          let c1 = filter_buf[cur_off + i * 2 + 1].to_int()
          a.out16[dest_off + i] = ((c0 << 8) | c1).to_uint16()
        }
      } else if img_n == 1 {
        for i = 0; i < x; i = i + 1 {
          let c0 = filter_buf[cur_off + i * 2].to_int()
          let c1 = filter_buf[cur_off + i * 2 + 1].to_int()
          a.out16[dest_off + i * 2] = ((c0 << 8) | c1).to_uint16()
          a.out16[dest_off + i * 2 + 1] = (65535 : UInt16)
        }
      } else {
        for i = 0; i < x; i = i + 1 {
          let b0 = cur_off + i * 6
          a.out16[dest_off + i * 4] = ((filter_buf[b0].to_int() << 8) |
            filter_buf[b0 + 1].to_int()).to_uint16()
          a.out16[dest_off + i * 4 + 1] = ((filter_buf[b0 + 2].to_int() << 8) |
            filter_buf[b0 + 3].to_int()).to_uint16()
          a.out16[dest_off + i * 4 + 2] = ((filter_buf[b0 + 4].to_int() << 8) |
            filter_buf[b0 + 5].to_int()).to_uint16()
          a.out16[dest_off + i * 4 + 3] = (65535 : UInt16)
        }
      }
    }
  }
  true
}

///|
fn png_create_image(
  a : StbiPng,
  image_data : FixedArray[Byte],
  image_data_len : Int,
  out_n : Int,
  depth : Int,
  color : Int,
  interlaced : Int,
) -> Bool {
  if interlaced == 0 {
    return png_create_image_raw(
      a,
      image_data,
      0,
      image_data_len,
      out_n,
      a.s.img_x,
      a.s.img_y,
      depth,
      color,
    )
  }
  let img_x = a.s.img_x
  let img_y = a.s.img_y
  let xorig : FixedArray[Int] = [0, 4, 0, 2, 0, 1, 0]
  let yorig : FixedArray[Int] = [0, 0, 4, 0, 2, 0, 1]
  let xspc : FixedArray[Int] = [8, 8, 4, 4, 2, 2, 1]
  let yspc : FixedArray[Int] = [8, 8, 8, 4, 4, 2, 2]
  if depth == 16 {
    if !stbi_mad4sizes_valid(img_x, img_y, out_n, 2, 0) {
      a.s.set_err("too large")
      return false
    }
    let final16 : FixedArray[UInt16] = FixedArray::make(
      img_x * img_y * out_n,
      (0 : UInt16),
    )
    let mut off = 0
    let mut rem = image_data_len
    for p = 0; p < 7; p = p + 1 {
      let x = (img_x - xorig[p] + xspc[p] - 1) / xspc[p]
      let y = (img_y - yorig[p] + yspc[p] - 1) / yspc[p]
      if x > 0 && y > 0 {
        let pass_len = (((a.s.img_n * x * depth + 7) >> 3) + 1) * y
        if !png_create_image_raw(a, image_data, off, rem, out_n, x, y, depth, color) {
          return false
        }
        for j = 0; j < y; j = j + 1 {
          let oy = j * yspc[p] + yorig[p]
          for i = 0; i < x; i = i + 1 {
            let ox = i * xspc[p] + xorig[p]
            let dst = (oy * img_x + ox) * out_n
            let src = (j * x + i) * out_n
            for k = 0; k < out_n; k = k + 1 {
              final16[dst + k] = a.out16[src + k]
            }
          }
        }
        off += pass_len
        rem -= pass_len
      }
    }
    a.out16 = final16
  } else {
    if !stbi_mad3sizes_valid(img_x, img_y, out_n, 0) {
      a.s.set_err("too large")
      return false
    }
    let final8 : FixedArray[Byte] = FixedArray::make(
      img_x * img_y * out_n,
      (0 : Byte),
    )
    let mut off = 0
    let mut rem = image_data_len
    for p = 0; p < 7; p = p + 1 {
      let x = (img_x - xorig[p] + xspc[p] - 1) / xspc[p]
      let y = (img_y - yorig[p] + yspc[p] - 1) / yspc[p]
      if x > 0 && y > 0 {
        let pass_len = (((a.s.img_n * x * depth + 7) >> 3) + 1) * y
        if !png_create_image_raw(a, image_data, off, rem, out_n, x, y, depth, color) {
          return false
        }
        for j = 0; j < y; j = j + 1 {
          let oy = j * yspc[p] + yorig[p]
          for i = 0; i < x; i = i + 1 {
            let ox = i * xspc[p] + xorig[p]
            let dst = (oy * img_x + ox) * out_n
            let src = (j * x + i) * out_n
            for k = 0; k < out_n; k = k + 1 {
              final8[dst + k] = a.out8[src + k]
            }
          }
        }
        off += pass_len
        rem -= pass_len
      }
    }
    a.out8 = final8
  }
  true
}

///|
fn png_compute_transparency(
  z : StbiPng,
  tc : FixedArray[Int],
  out_n : Int,
) -> Unit {
  let pixel_count = z.s.img_x * z.s.img_y
  let p = z.out8
  if out_n == 2 {
    for i = 0; i < pixel_count; i = i + 1 {
      p[i * 2 + 1] = if p[i * 2].to_int() == tc[0] {
        (0 : Byte)
      } else {
        (255 : Byte)
      }
    }
  } else {
    for i = 0; i < pixel_count; i = i + 1 {
      let base = i * 4
      if p[base].to_int() == tc[0] &&
        p[base + 1].to_int() == tc[1] &&
        p[base + 2].to_int() == tc[2] {
        p[base + 3] = (0 : Byte)
      }
    }
  }
}

///|
fn png_compute_transparency16(
  z : StbiPng,
  tc16 : FixedArray[UInt16],
  out_n : Int,
) -> Unit {
  let pixel_count = z.s.img_x * z.s.img_y
  let p = z.out16
  if out_n == 2 {
    for i = 0; i < pixel_count; i = i + 1 {
      p[i * 2 + 1] = if p[i * 2] == tc16[0] {
        (0 : UInt16)
      } else {
        (65535 : UInt16)
      }
    }
  } else {
    for i = 0; i < pixel_count; i = i + 1 {
      let base = i * 4
      if p[base] == tc16[0] && p[base + 1] == tc16[1] && p[base + 2] == tc16[2] {
        p[base + 3] = (0 : UInt16)
      }
    }
  }
}

///|
fn png_expand_palette(
  a : StbiPng,
  palette : FixedArray[Byte],
  pal_img_n : Int,
) -> Bool {
  let pixel_count = a.s.img_x * a.s.img_y
  if !stbi_mad2sizes_valid(pixel_count, pal_img_n, 0) {
    return false
  }
  let orig = a.out8
  let p : FixedArray[Byte] = FixedArray::make(
    pixel_count * pal_img_n,
    (0 : Byte),
  )
  if pal_img_n == 3 {
    for i = 0; i < pixel_count; i = i + 1 {
      let n = orig[i].to_int() * 4
      p[i * 3] = palette[n]
      p[i * 3 + 1] = palette[n + 1]
      p[i * 3 + 2] = palette[n + 2]
    }
  } else {
    for i = 0; i < pixel_count; i = i + 1 {
      let n = orig[i].to_int() * 4
      p[i * 4] = palette[n]
      p[i * 4 + 1] = palette[n + 1]
      p[i * 4 + 2] = palette[n + 2]
      p[i * 4 + 3] = palette[n + 3]
    }
  }
  a.out8 = p
  true
}

///|
fn png_de_iphone(z : StbiPng) -> Unit {
  let s = z.s
  let pixel_count = s.img_x * s.img_y
  let p = z.out8
  if s.img_out_n == 3 {
    for i = 0; i < pixel_count; i = i + 1 {
      let base = i * 3
      let t = p[base]
      p[base] = p[base + 2]
      p[base + 2] = t
    }
  } else if s.options.unpremultiply_iphone_png {
    for i = 0; i < pixel_count; i = i + 1 {
      let base = i * 4
      let a = p[base + 3].to_int()
      let t = p[base].to_int()
      if a != 0 {
        let half = a / 2
        p[base] = ((p[base + 2].to_int() * 255 + half) / a).to_byte()
        p[base + 1] = ((p[base + 1].to_int() * 255 + half) / a).to_byte()
        p[base + 2] = ((t * 255 + half) / a).to_byte()
      } else {
        p[base] = p[base + 2]
        p[base + 2] = t.to_byte()
      }
    }
  } else {
    for i = 0; i < pixel_count; i = i + 1 {
      let base = i * 4
      let t = p[base]
      p[base] = p[base + 2]
      p[base + 2] = t
    }
  }
}

///|
fn png_parse_file(z : StbiPng, scan : Int, req_comp : Int) -> Bool {
  let s = z.s
  let palette : FixedArray[Byte] = FixedArray::make(1024, (0 : Byte))
  let mut pal_img_n = 0
  let mut pal_len = 0
  let mut has_trans = false
  let tc : FixedArray[Int] = [0, 0, 0]
  let tc16 : FixedArray[UInt16] = [(0 : UInt16), (0 : UInt16), (0 : UInt16)]
  let mut idata : FixedArray[Byte] = FixedArray::make(0, (0 : Byte))
  let mut ioff = 0
  let mut idata_limit = 0
  let mut first = true
  let mut interlace = 0
  let mut color = 0

  z.is_iphone = false
  if !png_check_header(s) {
    return false
  }
  if scan == STBI_SCAN_TYPE {
    return true
  }

  let ty_cgbi = png_type(67, 103, 66, 73) // 'CgBI'
  let ty_ihdr = png_type(73, 72, 68, 82) // 'IHDR'
  let ty_plte = png_type(80, 76, 84, 69) // 'PLTE'
  let ty_trns = png_type(116, 82, 78, 83) // 'tRNS'
  let ty_idat = png_type(73, 68, 65, 84) // 'IDAT'
  let ty_iend = png_type(73, 69, 78, 68) // 'IEND'

  while true {
    if s.at_eof() {
      s.set_err("outofdata")
      return false
    }
    let clen_u = s.get32be()
    let ctype = s.get32be()
    if clen_u > (1073741824 : UInt) {
      s.set_err("chunk too large")
      return false
    }
    let clen = clen_u.reinterpret_as_int()
    if ctype == ty_cgbi {
      z.is_iphone = true
      s.skip(clen)
    } else if ctype == ty_ihdr {
      if !first {
        s.set_err("multiple IHDR")
        return false
      }
      first = false
      if clen != 13 {
        s.set_err("bad IHDR len")
        return false
      }
      let w_u = s.get32be()
      let h_u = s.get32be()
      if w_u > STBI_MAX_DIMENSIONS.reinterpret_as_uint() ||
        h_u > STBI_MAX_DIMENSIONS.reinterpret_as_uint() {
        s.set_err("too large")
        return false
      }
      s.img_x = w_u.reinterpret_as_int()
      s.img_y = h_u.reinterpret_as_int()
      z.depth = s.get8()
      if z.depth != 1 &&
        z.depth != 2 &&
        z.depth != 4 &&
        z.depth != 8 &&
        z.depth != 16 {
        s.set_err("1/2/4/8/16-bit only")
        return false
      }
      color = s.get8()
      if color > 6 {
        s.set_err("bad ctype")
        return false
      }
      if color == 3 && z.depth == 16 {
        s.set_err("bad ctype")
        return false
      }
      if color == 3 {
        pal_img_n = 3
      } else if (color & 1) != 0 {
        s.set_err("bad ctype")
        return false
      }
      if z.depth < 8 && color != 0 && color != 3 {
        s.set_err("bad ctype")
        return false
      }
      let comp = s.get8()
      if comp != 0 {
        s.set_err("bad comp method")
        return false
      }
      let filter = s.get8()
      if filter != 0 {
        s.set_err("bad filter method")
        return false
      }
      interlace = s.get8()
      if interlace > 1 {
        s.set_err("bad interlace method")
        return false
      }
      if s.img_x == 0 || s.img_y == 0 {
        s.set_err("0-pixel image")
        return false
      }
      if pal_img_n == 0 {
        s.img_n = (if (color & 2) != 0 { 3 } else { 1 }) +
          (if (color & 4) != 0 { 1 } else { 0 })
        if (1 << 30) / s.img_x / s.img_n < s.img_y {
          s.set_err("too large")
          return false
        }
      } else {
        s.img_n = 1
        if (1 << 30) / s.img_x / 4 < s.img_y {
          s.set_err("too large")
          return false
        }
      }
    } else if ctype == ty_plte {
      if first {
        s.set_err("first not IHDR")
        return false
      }
      if clen > 256 * 3 {
        s.set_err("invalid PLTE")
        return false
      }
      pal_len = clen / 3
      if pal_len * 3 != clen {
        s.set_err("invalid PLTE")
        return false
      }
      for i = 0; i < pal_len; i = i + 1 {
        palette[i * 4] = s.get8().to_byte()
        palette[i * 4 + 1] = s.get8().to_byte()
        palette[i * 4 + 2] = s.get8().to_byte()
        palette[i * 4 + 3] = (255 : Byte)
      }
    } else if ctype == ty_trns {
      if first {
        s.set_err("first not IHDR")
        return false
      }
      if ioff > 0 {
        s.set_err("tRNS after IDAT")
        return false
      }
      if pal_img_n != 0 {
        if scan == STBI_SCAN_HEADER {
          s.img_n = 4
          return true
        }
        if pal_len == 0 {
          s.set_err("tRNS before PLTE")
          return false
        }
        if clen > pal_len {
          s.set_err("bad tRNS len")
          return false
        }
        pal_img_n = 4
        for i = 0; i < clen; i = i + 1 {
          palette[i * 4 + 3] = s.get8().to_byte()
        }
      } else {
        if (s.img_n & 1) == 0 {
          s.set_err("tRNS with alpha")
          return false
        }
        if clen != s.img_n * 2 {
          s.set_err("bad tRNS len")
          return false
        }
        has_trans = true
        if scan == STBI_SCAN_HEADER {
          s.img_n += 1
          return true
        }
        if z.depth == 16 {
          for k = 0; k < s.img_n && k < 3; k = k + 1 {
            tc16[k] = s.get16be().to_uint16()
          }
        } else {
          for k = 0; k < s.img_n && k < 3; k = k + 1 {
            tc[k] = (s.get16be() & 255) * png_depth_scale_table[z.depth]
          }
        }
      }
    } else if ctype == ty_idat {
      if first {
        s.set_err("first not IHDR")
        return false
      }
      if pal_img_n != 0 && pal_len == 0 {
        s.set_err("no PLTE")
        return false
      }
      if scan == STBI_SCAN_HEADER {
        if pal_img_n != 0 {
          s.img_n = pal_img_n
        }
        return true
      }
      if !stbi_addsizes_valid(ioff, clen) {
        return false
      }
      if ioff + clen > idata_limit {
        let mut next_lim = if idata_limit == 0 {
          if clen > 4096 { clen } else { 4096 }
        } else {
          idata_limit
        }
        while ioff + clen > next_lim {
          if next_lim > STBI_INT_MAX / 2 {
            s.set_err("IDAT size limit")
            return false
          }
          next_lim *= 2
        }
        let next_buf : FixedArray[Byte] = FixedArray::make(next_lim, (0 : Byte))
        for i = 0; i < ioff; i = i + 1 {
          next_buf[i] = idata[i]
        }
        idata = next_buf
        idata_limit = next_lim
      }
      if !s.getn(idata, ioff, clen) {
        s.set_err("outofdata")
        return false
      }
      ioff += clen
    } else if ctype == ty_iend {
      if first {
        s.set_err("first not IHDR")
        return false
      }
      if scan != STBI_SCAN_LOAD {
        return true
      }
      if ioff == 0 {
        s.set_err("no IDAT")
        return false
      }
      let bpl = (s.img_x * z.depth + 7) / 8
      let guess = bpl * s.img_y * s.img_n + s.img_y
      let (expanded, raw_len) = match
        stbi_zlib_decode_internal(idata, ioff, guess, !z.is_iphone) {
        Some(pair) => pair
        None => {
          s.set_err("zlib failed")
          return false
        }
      }
      if (req_comp == s.img_n + 1 && req_comp != 3 && pal_img_n == 0) ||
        has_trans {
        s.img_out_n = s.img_n + 1
      } else {
        s.img_out_n = s.img_n
      }
      if !png_create_image(z, expanded, raw_len, s.img_out_n, z.depth, color, interlace) {
        return false
      }
      if has_trans {
        if z.depth == 16 {
          png_compute_transparency16(z, tc16, s.img_out_n)
        } else {
          png_compute_transparency(z, tc, s.img_out_n)
        }
      }
      if z.is_iphone && s.options.convert_iphone_png_to_rgb && s.img_out_n > 2 {
        png_de_iphone(z)
      }
      if pal_img_n != 0 {
        s.img_n = pal_img_n
        s.img_out_n = pal_img_n
        if req_comp >= 3 {
          s.img_out_n = req_comp
        }
        if !png_expand_palette(z, palette, s.img_out_n) {
          return false
        }
      } else if has_trans {
        s.img_n += 1
      }
      let _ = s.get32be() // skip CRC
      return true
    } else {
      if first {
        s.set_err("first not IHDR")
        return false
      }
      if (ctype & ((1 : UInt) << 29)) == (0 : UInt) {
        s.set_err("PNG chunk not known")
        return false
      }
      s.skip(clen)
    }
    let _ = s.get32be() // skip CRC
  }
  false
}

///|
fn stbi_png_load(s : StbiContext, req_comp : Int) -> StbiDecodeResult? {
  if req_comp < 0 || req_comp > 4 {
    s.set_err("bad req_comp")
    return None
  }
  let p : StbiPng = {
    s,
    depth: 0,
    is_iphone: false,
    out8: FixedArray::make(0, (0 : Byte)),
    out16: FixedArray::make(0, (0 : UInt16)),
  }
  if !png_parse_file(p, STBI_SCAN_LOAD, req_comp) {
    return None
  }
  if p.depth == 16 {
    let mut data16 = p.out16
    if req_comp != 0 && req_comp != s.img_out_n {
      match stbi_convert_format16(data16, s.img_out_n, req_comp, s.img_x, s.img_y) {
        Some(c) => {
          data16 = c
          s.img_out_n = req_comp
        }
        None => return None
      }
    }
    Some({
      width: s.img_x,
      height: s.img_y,
      comp: s.img_n,
      pixels: StbiRawPixels::Bits16(data16),
    })
  } else if p.depth <= 8 {
    let mut data8 = p.out8
    if req_comp != 0 && req_comp != s.img_out_n {
      match stbi_convert_format(data8, s.img_out_n, req_comp, s.img_x, s.img_y) {
        Some(c) => {
          data8 = c
          s.img_out_n = req_comp
        }
        None => return None
      }
    }
    Some({
      width: s.img_x,
      height: s.img_y,
      comp: s.img_n,
      pixels: StbiRawPixels::Bits8(data8),
    })
  } else {
    None
  }
}

///|
fn stbi_png_info(s : StbiContext) -> StbiInfo? {
  let p : StbiPng = {
    s,
    depth: 0,
    is_iphone: false,
    out8: FixedArray::make(0, (0 : Byte)),
    out16: FixedArray::make(0, (0 : UInt16)),
  }
  if !png_parse_file(p, STBI_SCAN_HEADER, 0) {
    s.rewind()
    return None
  }
  Some({
    width: s.img_x,
    height: s.img_y,
    channels: s.img_n,
    image_type: StbiImageType::Png,
    is_16_bit: p.depth == 16,
    is_hdr: false,
    is_iphone_png: p.is_iphone,
  })
}
