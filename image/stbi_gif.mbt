// Pure MoonBit port of stb_image v2.34 GIF decoder (single-frame and animated).

///|
priv struct StbiGifState {
  mut w : Int
  mut h : Int
  mut has_out : Bool
  mut out : FixedArray[Byte]
  mut flags : Int
  mut bgindex : Int
  mut transparent : Int
  mut eflags : Int
  mut use_lpal : Bool
  mut parse : Int
  mut step : Int
  mut lflags : Int
  mut start_x : Int
  mut start_y : Int
  mut max_x : Int
  mut max_y : Int
  mut cur_x : Int
  mut cur_y : Int
  mut line_size : Int
  mut delay : Int
  suffix : FixedArray[Byte]
  prefix : FixedArray[Int]
  pal : FixedArray[Byte]
  lpal : FixedArray[Byte]
}

///|
fn StbiGifState::new() -> StbiGifState {
  {
    w: 0,
    h: 0,
    has_out: false,
    out: FixedArray::make(0, (0 : Byte)),
    flags: 0,
    bgindex: 0,
    transparent: -1,
    eflags: 0,
    use_lpal: false,
    parse: 0,
    step: 0,
    lflags: 0,
    start_x: 0,
    start_y: 0,
    max_x: 0,
    max_y: 0,
    cur_x: 0,
    cur_y: 0,
    line_size: 0,
    delay: 0,
    suffix: FixedArray::make(4097, (0 : Byte)),
    prefix: FixedArray::make(4097, 0),
    pal: FixedArray::make(256 * 3, (0 : Byte)),
    lpal: FixedArray::make(256 * 3, (0 : Byte)),
  }
}

///|
fn gif_test_raw(s : StbiContext) -> Bool {
  if s.get8() != 71 || s.get8() != 73 || s.get8() != 70 || s.get8() != 56 {
    return false
  }
  let sz = s.get8()
  if sz != 57 && sz != 55 {
    return false
  }
  s.get8() == 97
}

///|
fn stbi_gif_test(s : StbiContext) -> Bool {
  let r = gif_test_raw(s)
  s.rewind()
  r
}

///|
fn gif_parse_colortable(
  s : StbiContext,
  pal : FixedArray[Byte],
  num_entries : Int,
) -> Unit {
  for i = 0; i < num_entries; i = i + 1 {
    pal[i * 3] = s.get8().to_byte()
    pal[i * 3 + 1] = s.get8().to_byte()
    pal[i * 3 + 2] = s.get8().to_byte()
  }
}

///|
fn gif_header(s : StbiContext, g : StbiGifState, is_info : Bool) -> Bool {
  if s.get8() != 71 || s.get8() != 73 || s.get8() != 70 || s.get8() != 56 {
    return false
  }
  let ver = s.get8()
  if ver != 55 && ver != 57 {
    return false
  }
  if s.get8() != 97 {
    return false
  }
  g.w = s.get16le()
  g.h = s.get16le()
  g.flags = s.get8()
  g.bgindex = s.get8()
  let _ = s.get8() // ratio
  g.transparent = -1
  if g.w > STBI_MAX_DIMENSIONS || g.h > STBI_MAX_DIMENSIONS {
    return false
  }
  if g.w == 0 || g.h == 0 {
    return false
  }
  if is_info {
    return true
  }
  if (g.flags & 0x80) != 0 {
    gif_parse_colortable(s, g.pal, 2 << (g.flags & 7))
  } else {
    g.bgindex = -1
  }
  true
}

///|
fn stbi_gif_info(s : StbiContext) -> StbiInfo? {
  let g = StbiGifState::new()
  if !gif_header(s, g, true) {
    s.rewind()
    return None
  }
  Some({
    width: g.w,
    height: g.h,
    channels: 4,
    image_type: StbiImageType::Gif,
    is_16_bit: false,
    is_hdr: false,
    is_iphone_png: false,
  })
}

///|
fn gif_process_raster(s : StbiContext, g : StbiGifState) -> Bool {
  let lzw_cs = s.get8()
  if lzw_cs < 2 || lzw_cs > 8 {
    return false
  }
  let clear = 1 << lzw_cs
  let mut first = true
  let mut codesize = lzw_cs + 1
  let mut codemask = (1 << codesize) - 1
  let mut bits = 0
  let mut valid_bits = 0
  for init_code = 0; init_code < clear; init_code = init_code + 1 {
    g.prefix[init_code] = 0
    g.suffix[init_code] = init_code.to_byte()
  }
  let mut avail = clear + 2
  let mut oldcode = -1
  let mut len = 0
  let revbuf : FixedArray[Byte] = FixedArray::make(4096, (0 : Byte))
  let color_table = if g.use_lpal { g.lpal } else { g.pal }

  while true {
    while valid_bits < codesize {
      if len == 0 {
        len = s.get8()
        if len == 0 {
          return true
        }
      }
      len -= 1
      bits = bits | (s.get8() << valid_bits)
      valid_bits += 8
    }
    let code = bits & codemask
    bits = bits >> codesize
    valid_bits -= codesize
    if code == clear {
      codesize = lzw_cs + 1
      codemask = (1 << codesize) - 1
      avail = clear + 2
      oldcode = -1
      first = false
    } else if code == clear + 1 {
      s.skip(len)
      while true {
        let blen = s.get8()
        if blen <= 0 {
          break
        }
        s.skip(blen)
      }
      return true
    } else if code <= avail {
      if first {
        return false
      }
      let mut revind = 4096
      let mut cur = code
      if code == avail {
        if oldcode < 0 {
          return false
        }
        cur = oldcode
        while cur >= clear {
          cur = g.prefix[cur]
        }
        revind -= 1
        revbuf[revind] = cur.to_byte()
        cur = oldcode
      }
      while cur >= clear {
        revind -= 1
        revbuf[revind] = g.suffix[cur]
        cur = g.prefix[cur]
      }
      revind -= 1
      revbuf[revind] = cur.to_byte()
      if oldcode >= 0 {
        g.prefix[avail] = oldcode
        g.suffix[avail] = cur.to_byte()
        if avail < 4096 {
          avail += 1
          if avail > codemask && avail < 4096 {
            codesize += 1
            codemask = (1 << codesize) - 1
          }
        }
      }
      oldcode = code
      while revind < 4096 && g.cur_y < g.max_y {
        let col = revbuf[revind].to_int()
        revind += 1
        if col != g.transparent {
          let ci = col * 3
          let pi = g.cur_x + g.cur_y
          g.out[pi] = color_table[ci]
          g.out[pi + 1] = color_table[ci + 1]
          g.out[pi + 2] = color_table[ci + 2]
          g.out[pi + 3] = (255 : Byte)
        }
        g.cur_x += 4
        if g.cur_x >= g.max_x {
          g.cur_x = g.start_x
          g.cur_y += g.step
          while g.cur_y >= g.max_y && g.parse > 0 {
            g.step = (1 << g.parse) * g.line_size
            g.cur_y = g.start_y + (g.step >> 1)
            g.parse -= 1
          }
        }
      }
    } else {
      return false
    }
  }
  true
}

///|
priv enum GifNextResult {
  Frame
  Done
  Err
}

///|
fn gif_load_next(
  s : StbiContext,
  g : StbiGifState,
  saved : FixedArray[Byte]?,
) -> GifNextResult {
  let mut first_frame = false
  if !g.has_out {
    if !gif_header(s, g, false) {
      return GifNextResult::Err
    }
    if !stbi_mad3sizes_valid(4, g.w, g.h, 0) {
      return GifNextResult::Err
    }
    g.out = FixedArray::make(4 * g.w * g.h, (0 : Byte))
    g.has_out = true
    first_frame = true
  } else {
    let mut dispose = (g.eflags & 0x1C) >> 2
    if dispose == 3 && saved is None {
      dispose = 2
    }
    if dispose == 3 {
      match saved {
        Some(sv) => {
          let mut y = g.start_y
          while y < g.max_y {
            for x = g.start_x; x < g.max_x; x = x + 1 {
              g.out[y + x] = sv[y + x]
            }
            y += g.line_size
          }
        }
        None => ()
      }
    } else if dispose == 2 {
      let bg : FixedArray[Byte] = FixedArray::make(4, (0 : Byte))
      if g.bgindex >= 0 && g.transparent < 0 {
        bg[0] = g.pal[g.bgindex * 3]
        bg[1] = g.pal[g.bgindex * 3 + 1]
        bg[2] = g.pal[g.bgindex * 3 + 2]
        bg[3] = (255 : Byte)
      }
      let mut y = g.start_y
      while y < g.max_y {
        for x = g.start_x; x < g.max_x; x = x + 1 {
          g.out[y + x] = bg[x & 3]
        }
        y += g.line_size
      }
    }
  }

  while true {
    let tag = s.get8()
    if tag == 0x2C {
      let x = s.get16le()
      let y = s.get16le()
      let w = s.get16le()
      let h = s.get16le()
      if x + w > g.w || y + h > g.h {
        return GifNextResult::Err
      }
      g.line_size = g.w * 4
      g.start_x = x * 4
      g.start_y = y * g.line_size
      g.max_x = g.start_x + w * 4
      g.max_y = g.start_y + h * g.line_size
      g.cur_x = g.start_x
      g.cur_y = g.start_y
      if w == 0 {
        g.cur_y = g.max_y
      }
      g.lflags = s.get8()
      if (g.lflags & 0x40) != 0 {
        g.step = 8 * g.line_size
        g.parse = 3
      } else {
        g.step = g.line_size
        g.parse = 0
      }
      if (g.lflags & 0x80) != 0 {
        gif_parse_colortable(s, g.lpal, 2 << (g.lflags & 7))
        g.use_lpal = true
      } else if (g.flags & 0x80) != 0 {
        g.use_lpal = false
      } else {
        return GifNextResult::Err
      }
      if first_frame && g.bgindex >= 0 && g.transparent < 0 {
        let bg : FixedArray[Byte] = [
          g.pal[g.bgindex * 3],
          g.pal[g.bgindex * 3 + 1],
          g.pal[g.bgindex * 3 + 2],
          (255 : Byte),
        ]
        let total = g.h * g.line_size
        for i = 0; i < total; i = i + 1 {
          g.out[i] = bg[i & 3]
        }
      }
      return if gif_process_raster(s, g) {
        GifNextResult::Frame
      } else {
        GifNextResult::Err
      }
    } else if tag == 0x21 {
      let ext = s.get8()
      if ext == 0xF9 {
        let len = s.get8()
        if len == 4 {
          g.eflags = s.get8()
          g.delay = 10 * s.get16le()
          g.transparent = s.get8()
          if (g.eflags & 0x01) == 0 {
            g.transparent = -1
          }
        } else {
          s.skip(len)
          continue
        }
      }
      while true {
        let len = s.get8()
        if len == 0 {
          break
        }
        s.skip(len)
      }
    } else if tag == 0x3B {
      return GifNextResult::Done
    } else {
      return GifNextResult::Err
    }
  }
  GifNextResult::Err
}

///|
fn stbi_load_gif_main(s : StbiContext, req_comp : Int) -> StbiGif? {
  if !stbi_gif_test(s) {
    return None
  }
  let g = StbiGifState::new()
  let frame_pixels : Array[FixedArray[Byte]] = []
  let frame_delays : Array[Int] = []
  let mut saved_pixels : FixedArray[Byte]? = None
  let mut totalbytes = 0
  let mut stride = 0

  while true {
    match gif_load_next(s, g, saved_pixels) {
      GifNextResult::Err => return None
      GifNextResult::Done => break
      GifNextResult::Frame => {
        stride = g.w * g.h * 4
        if !stbi_addints_valid(totalbytes, stride) {
          return None
        }
        totalbytes += stride
        let copy : FixedArray[Byte] = FixedArray::makei(stride, fn(i) {
          g.out[i]
        })
        frame_pixels.push(copy)
        frame_delays.push(g.delay)
        if (g.eflags & 0x1C) != 0x0C {
          saved_pixels = Some(copy)
        }
      }
    }
  }

  let layers = frame_pixels.length()
  if !stbi_mad2sizes_valid(layers, stride, 0) {
    return None
  }
  let mut out : FixedArray[Byte] = FixedArray::make(layers * stride, (0 : Byte))
  let delays : FixedArray[Int] = FixedArray::make(layers, 0)
  for i = 0; i < layers; i = i + 1 {
    delays[i] = frame_delays[i]
    let fp = frame_pixels[i]
    let base = i * stride
    for k = 0; k < stride; k = k + 1 {
      out[base + k] = fp[k]
    }
    if s.options.flip_vertically {
      let row_bytes = g.w * 4
      let half = g.h >> 1
      for row = 0; row < half; row = row + 1 {
        let r0 = base + row * row_bytes
        let r1 = base + (g.h - row - 1) * row_bytes
        for k = 0; k < row_bytes; k = k + 1 {
          let tmp = out[r0 + k]
          out[r0 + k] = out[r1 + k]
          out[r1 + k] = tmp
        }
      }
    }
  }
  let out_c = if req_comp != 0 { req_comp } else { 4 }
  if req_comp != 0 && req_comp != 4 {
    match stbi_convert_format(out, 4, req_comp, g.w, layers * g.h) {
      Some(c) => out = c
      None => return None
    }
  }
  Some({
    width: g.w,
    height: g.h,
    frames: layers,
    channels_in_file: 4,
    channels: out_c,
    delays,
    data: Bytes::from_array(out[:]),
  })
}

///|
fn stbi_gif_load(s : StbiContext, req_comp : Int) -> StbiDecodeResult? {
  let g = StbiGifState::new()
  match gif_load_next(s, g, None) {
    GifNextResult::Frame => {
      let mut out = g.out
      if req_comp != 0 && req_comp != 4 {
        match stbi_convert_format(out, 4, req_comp, g.w, g.h) {
          Some(c) => out = c
          None => return None
        }
      }
      Some({
        width: g.w,
        height: g.h,
        comp: 4,
        pixels: StbiRawPixels::Bits8(out),
      })
    }
    _ => None
  }
}
