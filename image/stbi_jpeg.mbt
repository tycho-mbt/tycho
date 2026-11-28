// Pure MoonBit port of stb_image v2.34 JPEG decoder.
// Supports baseline (SOF0/SOF1) and progressive (SOF2), 1/3/4 components,
// YCbCr, Adobe RGB, CMYK, YCCK, restart markers (DRI/RST), and arbitrary
// integer subsampling ratios.

///|
const JPEG_FAST_BITS : Int = 9

///|
const JPEG_MARKER_NONE : Int = 0xFF

///|
let jpeg_bmask : FixedArray[UInt] = [
  0, 1, 3, 7, 15, 31, 63, 127, 255, 511, 1023, 2047, 4095, 8191, 16383, 32767,
  65535,
]

///|
let jpeg_jbias : FixedArray[Int] = [
  0, -1, -3, -7, -15, -31, -63, -127, -255, -511, -1023, -2047, -4095, -8191,
  -16383, -32767,
]

///|
let jpeg_dezigzag : FixedArray[Int] = [
  0, 1, 8, 16, 9, 2, 3, 10, 17, 24, 32, 25, 18, 11, 4, 5, 12, 19, 26, 33, 40,
  48, 41, 34, 27, 20, 13, 6, 7, 14, 21, 28, 35, 42, 49, 56, 57, 50, 43, 36, 29,
  22, 15, 23, 30, 37, 44, 51, 58, 59, 52, 45, 38, 31, 39, 46, 53, 60, 61, 54,
  47, 55, 62, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63,
]

///|
fn jpeg_to_i16(v : Int) -> Int {
  (v << 16) >> 16
}

///|
fn jpeg_clamp(x : Int) -> Byte {
  if x < 0 {
    (0 : Byte)
  } else if x > 255 {
    (255 : Byte)
  } else {
    x.to_byte()
  }
}

///|
fn jpeg_lrot(x : UInt, n : Int) -> UInt {
  if n == 0 {
    x
  } else {
    (x << n) | (x >> (32 - n))
  }
}

///|
priv struct JpegHuffman {
  fast : FixedArray[Int] // 512 entries
  code : FixedArray[Int] // 256 entries
  values : FixedArray[Int] // 256 entries
  size : FixedArray[Int] // 257 entries
  maxcode : FixedArray[UInt] // 18 entries
  delta : FixedArray[Int] // 17 entries
}

///|
fn JpegHuffman::new() -> JpegHuffman {
  {
    fast: FixedArray::make(1 << JPEG_FAST_BITS, 255),
    code: FixedArray::make(256, 0),
    values: FixedArray::make(256, 0),
    size: FixedArray::make(257, 0),
    maxcode: FixedArray::make(18, (0 : UInt)),
    delta: FixedArray::make(17, 0),
  }
}

///|
priv struct JpegComp {
  mut id : Int
  mut h : Int
  mut v : Int
  mut tq : Int
  mut hd : Int
  mut ha : Int
  mut dc_pred : Int
  mut x : Int
  mut y : Int
  mut w2 : Int
  mut h2 : Int
  mut data : FixedArray[Byte]
  mut linebuf : FixedArray[Byte]
  mut coeff : FixedArray[Int]
  mut coeff_w : Int
}

///|
fn JpegComp::new() -> JpegComp {
  {
    id: 0,
    h: 0,
    v: 0,
    tq: 0,
    hd: 0,
    ha: 0,
    dc_pred: 0,
    x: 0,
    y: 0,
    w2: 0,
    h2: 0,
    data: FixedArray::make(0, (0 : Byte)),
    linebuf: FixedArray::make(0, (0 : Byte)),
    coeff: FixedArray::make(0, 0),
    coeff_w: 0,
  }
}

///|
priv struct StbiJpeg {
  s : StbiContext
  huff_dc : FixedArray[JpegHuffman]
  huff_ac : FixedArray[JpegHuffman]
  dequant : FixedArray[FixedArray[Int]]
  fast_ac : FixedArray[FixedArray[Int]]
  mut img_h_max : Int
  mut img_v_max : Int
  mut img_mcu_x : Int
  mut img_mcu_y : Int
  mut img_mcu_w : Int
  mut img_mcu_h : Int
  img_comp : FixedArray[JpegComp]
  mut code_buffer : UInt
  mut code_bits : Int
  mut marker : Int
  mut nomore : Bool
  mut progressive : Bool
  mut spec_start : Int
  mut spec_end : Int
  mut succ_high : Int
  mut succ_low : Int
  mut eob_run : Int
  mut jfif : Bool
  mut app14_color_transform : Int
  mut rgb : Int
  mut scan_n : Int
  order : FixedArray[Int]
  mut restart_interval : Int
  mut todo : Int
}

///|
fn StbiJpeg::new(s : StbiContext) -> StbiJpeg {
  {
    s,
    huff_dc: FixedArray::makei(4, fn(_) { JpegHuffman::new() }),
    huff_ac: FixedArray::makei(4, fn(_) { JpegHuffman::new() }),
    dequant: FixedArray::makei(4, fn(_) { FixedArray::make(64, 0) }),
    fast_ac: FixedArray::makei(4, fn(_) {
      FixedArray::make(1 << JPEG_FAST_BITS, 0)
    }),
    img_h_max: 0,
    img_v_max: 0,
    img_mcu_x: 0,
    img_mcu_y: 0,
    img_mcu_w: 0,
    img_mcu_h: 0,
    img_comp: FixedArray::makei(4, fn(_) { JpegComp::new() }),
    code_buffer: (0 : UInt),
    code_bits: 0,
    marker: JPEG_MARKER_NONE,
    nomore: false,
    progressive: false,
    spec_start: 0,
    spec_end: 0,
    succ_high: 0,
    succ_low: 0,
    eob_run: 0,
    jfif: false,
    app14_color_transform: -1,
    rgb: 0,
    scan_n: 0,
    order: FixedArray::make(4, 0),
    restart_interval: 0,
    todo: 0,
  }
}

///|
fn jpeg_build_huffman(h : JpegHuffman, count : FixedArray[Int]) -> Bool {
  let mut k = 0
  for i = 0; i < 16; i = i + 1 {
    for j = 0; j < count[i]; j = j + 1 {
      if k >= 256 {
        return false
      }
      h.size[k] = i + 1
      k += 1
    }
  }
  h.size[k] = 0
  let mut code : UInt = (0 : UInt)
  k = 0
  for j = 1; j <= 16; j = j + 1 {
    h.delta[j] = k - code.reinterpret_as_int()
    if h.size[k] == j {
      while h.size[k] == j {
        h.code[k] = code.reinterpret_as_int()
        k += 1
        code = code + (1 : UInt)
      }
      if code - (1 : UInt) >= ((1 : UInt) << j) {
        return false
      }
    }
    h.maxcode[j] = code << (16 - j)
    code = code << 1
  }
  h.maxcode[17] = (0xFFFFFFFF : UInt)
  for i = 0; i < (1 << JPEG_FAST_BITS); i = i + 1 {
    h.fast[i] = 255
  }
  for i = 0; i < k; i = i + 1 {
    let s = h.size[i]
    if s <= JPEG_FAST_BITS {
      let c = h.code[i] << (JPEG_FAST_BITS - s)
      let m = 1 << (JPEG_FAST_BITS - s)
      for j = 0; j < m; j = j + 1 {
        h.fast[c + j] = i
      }
    }
  }
  true
}

///|
fn jpeg_build_fast_ac(fast_ac : FixedArray[Int], h : JpegHuffman) -> Unit {
  for i = 0; i < (1 << JPEG_FAST_BITS); i = i + 1 {
    let fast = h.fast[i]
    fast_ac[i] = 0
    if fast < 255 {
      let rs = h.values[fast]
      let run = (rs >> 4) & 15
      let magbits = rs & 15
      let len = h.size[fast]
      if magbits != 0 && len + magbits <= JPEG_FAST_BITS {
        let mut k = ((i << len) & ((1 << JPEG_FAST_BITS) - 1)) >>
          (JPEG_FAST_BITS - magbits)
        let m = 1 << (magbits - 1)
        if k < m {
          k += (-1 << magbits) + 1
        }
        if k >= -128 && k <= 127 {
          fast_ac[i] = jpeg_to_i16(k * 256 + run * 16 + (len + magbits))
        }
      }
    }
  }
}

///|
fn StbiJpeg::grow_buffer_unsafe(self : StbiJpeg) -> Unit {
  while true {
    let b = if self.nomore { 0 } else { self.s.get8() }
    if b == 0xFF {
      let mut c = self.s.get8()
      while c == 0xFF {
        c = self.s.get8()
      }
      if c != 0 {
        self.marker = c
        self.nomore = true
        return
      }
    }
    self.code_buffer = self.code_buffer |
      (b.reinterpret_as_uint() << (24 - self.code_bits))
    self.code_bits += 8
    if self.code_bits > 24 {
      break
    }
  }
}

///|
fn StbiJpeg::huff_decode(self : StbiJpeg, h : JpegHuffman) -> Int {
  if self.code_bits < 16 {
    self.grow_buffer_unsafe()
  }
  let c = ((self.code_buffer >> (32 - JPEG_FAST_BITS)) &
    ((1 << JPEG_FAST_BITS) - 1).reinterpret_as_uint()).reinterpret_as_int()
  let mut k = h.fast[c]
  if k < 255 {
    let s = h.size[k]
    if s > self.code_bits {
      return -1
    }
    self.code_buffer = self.code_buffer << s
    self.code_bits -= s
    return h.values[k]
  }
  let temp = self.code_buffer >> 16
  k = JPEG_FAST_BITS + 1
  while k < 17 {
    if temp < h.maxcode[k] {
      break
    }
    k += 1
  }
  if k == 17 {
    self.code_bits -= 16
    return -1
  }
  if k > self.code_bits {
    return -1
  }
  let sym = ((self.code_buffer >> (32 - k)) & jpeg_bmask[k]).reinterpret_as_int() +
    h.delta[k]
  if sym < 0 || sym >= 256 {
    return -1
  }
  self.code_bits -= k
  self.code_buffer = self.code_buffer << k
  h.values[sym]
}

///|
fn StbiJpeg::extend_receive(self : StbiJpeg, n : Int) -> Int {
  if self.code_bits < n {
    self.grow_buffer_unsafe()
  }
  if self.code_bits < n {
    return 0
  }
  let sgn = (self.code_buffer >> 31).reinterpret_as_int()
  let mut k = jpeg_lrot(self.code_buffer, n)
  self.code_buffer = k & jpeg_bmask[n].lnot()
  k = k & jpeg_bmask[n]
  self.code_bits -= n
  k.reinterpret_as_int() + (jpeg_jbias[n] & (sgn - 1))
}

///|
fn StbiJpeg::get_bits(self : StbiJpeg, n : Int) -> Int {
  if self.code_bits < n {
    self.grow_buffer_unsafe()
  }
  if self.code_bits < n {
    return 0
  }
  let mut k = jpeg_lrot(self.code_buffer, n)
  self.code_buffer = k & jpeg_bmask[n].lnot()
  k = k & jpeg_bmask[n]
  self.code_bits -= n
  k.reinterpret_as_int()
}

///|
fn StbiJpeg::get_bit(self : StbiJpeg) -> Bool {
  if self.code_bits < 1 {
    self.grow_buffer_unsafe()
  }
  if self.code_bits < 1 {
    return false
  }
  let k = self.code_buffer
  self.code_buffer = self.code_buffer << 1
  self.code_bits -= 1
  (k & (0x80000000 : UInt)) != (0 : UInt)
}

///|
fn StbiJpeg::decode_block(
  self : StbiJpeg,
  data : FixedArray[Int],
  hdc : JpegHuffman,
  hac : JpegHuffman,
  fac : FixedArray[Int],
  b : Int,
  dequant : FixedArray[Int],
) -> Bool {
  if self.code_bits < 16 {
    self.grow_buffer_unsafe()
  }
  let t = self.huff_decode(hdc)
  if t < 0 || t > 15 {
    return false
  }
  for i = 0; i < 64; i = i + 1 {
    data[i] = 0
  }
  let diff = if t != 0 { self.extend_receive(t) } else { 0 }
  if !stbi_addints_valid(self.img_comp[b].dc_pred, diff) {
    return false
  }
  let dc = self.img_comp[b].dc_pred + diff
  self.img_comp[b].dc_pred = dc
  if !stbi_mul2shorts_valid(dc, dequant[0]) {
    return false
  }
  data[0] = jpeg_to_i16(dc * dequant[0])
  let mut k = 1
  while k < 64 {
    if self.code_bits < 16 {
      self.grow_buffer_unsafe()
    }
    let c = ((self.code_buffer >> (32 - JPEG_FAST_BITS)) &
      ((1 << JPEG_FAST_BITS) - 1).reinterpret_as_uint()).reinterpret_as_int()
    let r = fac[c]
    if r != 0 {
      k += (r >> 4) & 15
      let s = r & 15
      if s > self.code_bits {
        return false
      }
      self.code_buffer = self.code_buffer << s
      self.code_bits -= s
      let zig = jpeg_dezigzag[k]
      k += 1
      data[zig] = jpeg_to_i16((r >> 8) * dequant[zig])
    } else {
      let rs = self.huff_decode(hac)
      if rs < 0 {
        return false
      }
      let s = rs & 15
      let run = rs >> 4
      if s == 0 {
        if rs != 0xF0 {
          break
        }
        k += 16
      } else {
        k += run
        let zig = jpeg_dezigzag[k]
        k += 1
        data[zig] = jpeg_to_i16(self.extend_receive(s) * dequant[zig])
      }
    }
  }
  true
}

///|
fn StbiJpeg::decode_block_prog_dc(
  self : StbiJpeg,
  coeff : FixedArray[Int],
  off : Int,
  hdc : JpegHuffman,
  b : Int,
) -> Bool {
  if self.spec_end != 0 {
    return false
  }
  if self.code_bits < 16 {
    self.grow_buffer_unsafe()
  }
  if self.succ_high == 0 {
    let t = self.huff_decode(hdc)
    if t < 0 || t > 15 {
      return false
    }
    let diff = if t != 0 { self.extend_receive(t) } else { 0 }
    if !stbi_addints_valid(self.img_comp[b].dc_pred, diff) {
      return false
    }
    let dc = self.img_comp[b].dc_pred + diff
    self.img_comp[b].dc_pred = dc
    if !stbi_mul2shorts_valid(dc, 1 << self.succ_low) {
      return false
    }
    coeff[off] = jpeg_to_i16(dc * (1 << self.succ_low))
  } else if self.get_bit() {
    coeff[off] = jpeg_to_i16(coeff[off] + (1 << self.succ_low))
  }
  true
}

///|
fn StbiJpeg::decode_block_prog_ac(
  self : StbiJpeg,
  coeff : FixedArray[Int],
  off : Int,
  hac : JpegHuffman,
  fac : FixedArray[Int],
) -> Bool {
  if self.spec_start == 0 {
    return false
  }
  if self.succ_high == 0 {
    let shift = self.succ_low
    if self.eob_run != 0 {
      self.eob_run -= 1
      return true
    }
    let mut k = self.spec_start
    while k <= self.spec_end {
      if self.code_bits < 16 {
        self.grow_buffer_unsafe()
      }
      let c = ((self.code_buffer >> (32 - JPEG_FAST_BITS)) &
        ((1 << JPEG_FAST_BITS) - 1).reinterpret_as_uint()).reinterpret_as_int()
      let r = fac[c]
      if r != 0 {
        k += (r >> 4) & 15
        let s = r & 15
        if s > self.code_bits {
          return false
        }
        self.code_buffer = self.code_buffer << s
        self.code_bits -= s
        let zig = jpeg_dezigzag[k]
        k += 1
        coeff[off + zig] = jpeg_to_i16((r >> 8) * (1 << shift))
      } else {
        let rs = self.huff_decode(hac)
        if rs < 0 {
          return false
        }
        let s = rs & 15
        let run = rs >> 4
        if s == 0 {
          if run < 15 {
            self.eob_run = 1 << run
            if run != 0 {
              self.eob_run += self.get_bits(run)
            }
            self.eob_run -= 1
            break
          }
          k += 16
        } else {
          k += run
          let zig = jpeg_dezigzag[k]
          k += 1
          coeff[off + zig] = jpeg_to_i16(self.extend_receive(s) * (1 << shift))
        }
      }
    }
  } else {
    let bit = jpeg_to_i16(1 << self.succ_low)
    if self.eob_run != 0 {
      self.eob_run -= 1
      for k = self.spec_start; k <= self.spec_end; k = k + 1 {
        let idx = off + jpeg_dezigzag[k]
        let p = coeff[idx]
        if p != 0 {
          if self.get_bit() {
            if (p & bit) == 0 {
              if p > 0 {
                coeff[idx] = jpeg_to_i16(p + bit)
              } else {
                coeff[idx] = jpeg_to_i16(p - bit)
              }
            }
          }
        }
      }
    } else {
      let mut k = self.spec_start
      while k <= self.spec_end {
        let rs = self.huff_decode(hac)
        if rs < 0 {
          return false
        }
        let mut s = rs & 15
        let mut r = rs >> 4
        if s == 0 {
          if r < 15 {
            self.eob_run = (1 << r) - 1
            if r != 0 {
              self.eob_run += self.get_bits(r)
            }
            r = 64
          }
        } else {
          if s != 1 {
            return false
          }
          s = if self.get_bit() { bit } else { -bit }
        }
        while k <= self.spec_end {
          let idx = off + jpeg_dezigzag[k]
          k += 1
          let p = coeff[idx]
          if p != 0 {
            if self.get_bit() {
              if (p & bit) == 0 {
                if p > 0 {
                  coeff[idx] = jpeg_to_i16(p + bit)
                } else {
                  coeff[idx] = jpeg_to_i16(p - bit)
                }
              }
            }
          } else {
            if r == 0 {
              coeff[idx] = jpeg_to_i16(s)
              break
            }
            r -= 1
          }
        }
      }
    }
  }
  true
}

///|
// Exact stb_image integer IDCT (matches both scalar C and SSE2/NEON bit-for-bit).
fn jpeg_idct_block(
  out : FixedArray[Byte],
  out_off : Int,
  out_stride : Int,
  data : FixedArray[Int],
  data_off : Int,
) -> Unit {
  let val : FixedArray[Int] = FixedArray::make(64, 0)
  // Columns
  for i = 0; i < 8; i = i + 1 {
    let d0 = data[data_off + i]
    let d1 = data[data_off + i + 8]
    let d2 = data[data_off + i + 16]
    let d3 = data[data_off + i + 24]
    let d4 = data[data_off + i + 32]
    let d5 = data[data_off + i + 40]
    let d6 = data[data_off + i + 48]
    let d7 = data[data_off + i + 56]
    if d1 == 0 && d2 == 0 && d3 == 0 && d4 == 0 && d5 == 0 && d6 == 0 && d7 == 0 {
      let dcterm = d0 * 4
      val[i] = dcterm
      val[i + 8] = dcterm
      val[i + 16] = dcterm
      val[i + 24] = dcterm
      val[i + 32] = dcterm
      val[i + 40] = dcterm
      val[i + 48] = dcterm
      val[i + 56] = dcterm
    } else {
      let mut p2 = d2
      let mut p3 = d6
      let mut p1 = (p2 + p3) * 2217
      let mut t2 = p1 + p3 * -7567
      let mut t3 = p1 + p2 * 3135
      p2 = d0
      p3 = d4
      let mut t0 = (p2 + p3) * 4096
      let mut t1 = (p2 - p3) * 4096
      let x0 = t0 + t3 + 512
      let x3 = t0 - t3 + 512
      let x1 = t1 + t2 + 512
      let x2 = t1 - t2 + 512
      t0 = d7
      t1 = d5
      t2 = d3
      t3 = d1
      p3 = t0 + t2
      let p4 = t1 + t3
      p1 = t0 + t3
      p2 = t1 + t2
      let p5 = (p3 + p4) * 4816
      t0 = t0 * 1223
      t1 = t1 * 8410
      t2 = t2 * 12586
      t3 = t3 * 6149
      p1 = p5 + p1 * -3685
      p2 = p5 + p2 * -10497
      p3 = p3 * -8034
      let p4s = p4 * -1597
      t3 += p1 + p4s
      t2 += p2 + p3
      t1 += p2 + p4s
      t0 += p1 + p3
      val[i] = (x0 + t3) >> 10
      val[i + 56] = (x0 - t3) >> 10
      val[i + 8] = (x1 + t2) >> 10
      val[i + 48] = (x1 - t2) >> 10
      val[i + 16] = (x2 + t1) >> 10
      val[i + 40] = (x2 - t1) >> 10
      val[i + 24] = (x3 + t0) >> 10
      val[i + 32] = (x3 - t0) >> 10
    }
  }
  // Rows
  for i = 0; i < 8; i = i + 1 {
    let vo = i * 8
    let s0 = val[vo]
    let s1 = val[vo + 1]
    let s2 = val[vo + 2]
    let s3 = val[vo + 3]
    let s4 = val[vo + 4]
    let s5 = val[vo + 5]
    let s6 = val[vo + 6]
    let s7 = val[vo + 7]
    let mut p2 = s2
    let mut p3 = s6
    let mut p1 = (p2 + p3) * 2217
    let mut t2 = p1 + p3 * -7567
    let mut t3 = p1 + p2 * 3135
    p2 = s0
    p3 = s4
    let mut t0 = (p2 + p3) * 4096
    let mut t1 = (p2 - p3) * 4096
    let bias = 65536 + (128 << 17)
    let x0 = t0 + t3 + bias
    let x3 = t0 - t3 + bias
    let x1 = t1 + t2 + bias
    let x2 = t1 - t2 + bias
    t0 = s7
    t1 = s5
    t2 = s3
    t3 = s1
    p3 = t0 + t2
    let p4 = t1 + t3
    p1 = t0 + t3
    p2 = t1 + t2
    let p5 = (p3 + p4) * 4816
    t0 = t0 * 1223
    t1 = t1 * 8410
    t2 = t2 * 12586
    t3 = t3 * 6149
    p1 = p5 + p1 * -3685
    p2 = p5 + p2 * -10497
    p3 = p3 * -8034
    let p4s = p4 * -1597
    t3 += p1 + p4s
    t2 += p2 + p3
    t1 += p2 + p4s
    t0 += p1 + p3
    let oo = out_off + i * out_stride
    out[oo] = jpeg_clamp((x0 + t3) >> 17)
    out[oo + 7] = jpeg_clamp((x0 - t3) >> 17)
    out[oo + 1] = jpeg_clamp((x1 + t2) >> 17)
    out[oo + 6] = jpeg_clamp((x1 - t2) >> 17)
    out[oo + 2] = jpeg_clamp((x2 + t1) >> 17)
    out[oo + 5] = jpeg_clamp((x2 - t1) >> 17)
    out[oo + 3] = jpeg_clamp((x3 + t0) >> 17)
    out[oo + 4] = jpeg_clamp((x3 - t0) >> 17)
  }
}

///|
fn StbiJpeg::get_marker(self : StbiJpeg) -> Int {
  if self.marker != JPEG_MARKER_NONE {
    let x = self.marker
    self.marker = JPEG_MARKER_NONE
    return x
  }
  let mut x = self.s.get8()
  if x != 0xFF {
    return JPEG_MARKER_NONE
  }
  while x == 0xFF {
    x = self.s.get8()
  }
  x
}

///|
fn jpeg_is_restart(x : Int) -> Bool {
  x >= 0xD0 && x <= 0xD7
}

///|
fn StbiJpeg::reset(self : StbiJpeg) -> Unit {
  self.code_bits = 0
  self.code_buffer = (0 : UInt)
  self.nomore = false
  for i = 0; i < 4; i = i + 1 {
    self.img_comp[i].dc_pred = 0
  }
  self.marker = JPEG_MARKER_NONE
  self.todo = if self.restart_interval != 0 {
    self.restart_interval
  } else {
    0x7FFFFFFF
  }
  self.eob_run = 0
}

///|
fn StbiJpeg::parse_entropy_coded_data(self : StbiJpeg) -> Bool {
  self.reset()
  if !self.progressive {
    let data : FixedArray[Int] = FixedArray::make(64, 0)
    if self.scan_n == 1 {
      let n = self.order[0]
      let comp = self.img_comp[n]
      let w = (comp.x + 7) >> 3
      let h = (comp.y + 7) >> 3
      for j = 0; j < h; j = j + 1 {
        for i = 0; i < w; i = i + 1 {
          let ha = comp.ha
          if !self.decode_block(
              data,
              self.huff_dc[comp.hd],
              self.huff_ac[ha],
              self.fast_ac[ha],
              n,
              self.dequant[comp.tq],
            ) {
            return false
          }
          jpeg_idct_block(comp.data, comp.w2 * j * 8 + i * 8, comp.w2, data, 0)
          self.todo -= 1
          if self.todo <= 0 {
            if self.code_bits < 24 {
              self.grow_buffer_unsafe()
            }
            if !jpeg_is_restart(self.marker) {
              return true
            }
            self.reset()
          }
        }
      }
      true
    } else {
      for j = 0; j < self.img_mcu_y; j = j + 1 {
        for i = 0; i < self.img_mcu_x; i = i + 1 {
          for k = 0; k < self.scan_n; k = k + 1 {
            let n = self.order[k]
            let comp = self.img_comp[n]
            for y = 0; y < comp.v; y = y + 1 {
              for x = 0; x < comp.h; x = x + 1 {
                let x2 = (i * comp.h + x) * 8
                let y2 = (j * comp.v + y) * 8
                let ha = comp.ha
                if !self.decode_block(
                    data,
                    self.huff_dc[comp.hd],
                    self.huff_ac[ha],
                    self.fast_ac[ha],
                    n,
                    self.dequant[comp.tq],
                  ) {
                  return false
                }
                jpeg_idct_block(comp.data, comp.w2 * y2 + x2, comp.w2, data, 0)
              }
            }
          }
          self.todo -= 1
          if self.todo <= 0 {
            if self.code_bits < 24 {
              self.grow_buffer_unsafe()
            }
            if !jpeg_is_restart(self.marker) {
              return true
            }
            self.reset()
          }
        }
      }
      true
    }
  } else if self.scan_n == 1 {
    let n = self.order[0]
    let comp = self.img_comp[n]
    let w = (comp.x + 7) >> 3
    let h = (comp.y + 7) >> 3
    for j = 0; j < h; j = j + 1 {
      for i = 0; i < w; i = i + 1 {
        let off = 64 * (i + j * comp.coeff_w)
        if !self.nomore {
          if self.spec_start == 0 {
            if !self.decode_block_prog_dc(
                comp.coeff,
                off,
                self.huff_dc[comp.hd],
                n,
              ) {
              return false
            }
          } else {
            let ha = comp.ha
            if !self.decode_block_prog_ac(
                comp.coeff,
                off,
                self.huff_ac[ha],
                self.fast_ac[ha],
              ) {
              return false
            }
          }
        }
        self.todo -= 1
        if self.todo <= 0 {
          if self.code_bits < 24 {
            self.grow_buffer_unsafe()
          }
          if !jpeg_is_restart(self.marker) {
            return true
          }
          self.reset()
        }
      }
    }
    true
  } else {
    for j = 0; j < self.img_mcu_y; j = j + 1 {
      for i = 0; i < self.img_mcu_x; i = i + 1 {
        for k = 0; k < self.scan_n; k = k + 1 {
          let n = self.order[k]
          let comp = self.img_comp[n]
          for y = 0; y < comp.v; y = y + 1 {
            for x = 0; x < comp.h; x = x + 1 {
              let x2 = i * comp.h + x
              let y2 = j * comp.v + y
              let off = 64 * (x2 + y2 * comp.coeff_w)
              if !self.decode_block_prog_dc(
                  comp.coeff,
                  off,
                  self.huff_dc[comp.hd],
                  n,
                ) {
                return false
              }
            }
          }
        }
        self.todo -= 1
        if self.todo <= 0 {
          if self.code_bits < 24 {
            self.grow_buffer_unsafe()
          }
          if !jpeg_is_restart(self.marker) {
            return true
          }
          self.reset()
        }
      }
    }
    true
  }
}

///|
fn StbiJpeg::finish(self : StbiJpeg) -> Unit {
  if self.progressive {
    for n = 0; n < self.s.img_n; n = n + 1 {
      let comp = self.img_comp[n]
      let w = (comp.x + 7) >> 3
      let h = (comp.y + 7) >> 3
      let dq = self.dequant[comp.tq]
      for j = 0; j < h; j = j + 1 {
        for i = 0; i < w; i = i + 1 {
          let off = 64 * (i + j * comp.coeff_w)
          for k = 0; k < 64; k = k + 1 {
            comp.coeff[off + k] = jpeg_to_i16(comp.coeff[off + k] * dq[k])
          }
          jpeg_idct_block(
            comp.data,
            comp.w2 * j * 8 + i * 8,
            comp.w2,
            comp.coeff,
            off,
          )
        }
      }
    }
  }
}

///|
fn StbiJpeg::process_marker(self : StbiJpeg, m : Int) -> Bool {
  if m == JPEG_MARKER_NONE {
    return false
  }
  if m == 0xDD {
    if self.s.get16be() != 4 {
      return false
    }
    self.restart_interval = self.s.get16be()
    return true
  }
  if m == 0xDB {
    let mut l = self.s.get16be() - 2
    while l > 0 {
      let q = self.s.get8()
      let p = q >> 4
      let sixteen = p != 0
      let t = q & 15
      if p != 0 && p != 1 {
        return false
      }
      if t > 3 {
        return false
      }
      for i = 0; i < 64; i = i + 1 {
        self.dequant[t][jpeg_dezigzag[i]] = if sixteen {
          self.s.get16be()
        } else {
          self.s.get8()
        }
      }
      l -= if sixteen { 129 } else { 65 }
    }
    return l == 0
  }
  if m == 0xC4 {
    let mut l = self.s.get16be() - 2
    while l > 0 {
      let sizes : FixedArray[Int] = FixedArray::make(16, 0)
      let q = self.s.get8()
      let tc = q >> 4
      let th = q & 15
      if tc > 1 || th > 3 {
        return false
      }
      let mut n = 0
      for i = 0; i < 16; i = i + 1 {
        sizes[i] = self.s.get8()
        n += sizes[i]
      }
      if n > 256 {
        return false
      }
      l -= 17
      let h = if tc == 0 { self.huff_dc[th] } else { self.huff_ac[th] }
      if !jpeg_build_huffman(h, sizes) {
        return false
      }
      for i = 0; i < n; i = i + 1 {
        h.values[i] = self.s.get8()
      }
      if tc != 0 {
        jpeg_build_fast_ac(self.fast_ac[th], h)
      }
      l -= n
    }
    return l == 0
  }
  if (m >= 0xE0 && m <= 0xEF) || m == 0xFE {
    let mut l = self.s.get16be()
    if l < 2 {
      return false
    }
    l -= 2
    if m == 0xE0 && l >= 5 {
      let ok = self.s.get8() == 74 &&
        self.s.get8() == 70 &&
        self.s.get8() == 73 &&
        self.s.get8() == 70 &&
        self.s.get8() == 0
      l -= 5
      if ok {
        self.jfif = true
      }
    } else if m == 0xEE && l >= 12 {
      let ok = self.s.get8() == 65 &&
        self.s.get8() == 100 &&
        self.s.get8() == 111 &&
        self.s.get8() == 98 &&
        self.s.get8() == 101 &&
        self.s.get8() == 0
      l -= 6
      if ok {
        let _ = self.s.get8()
        let _ = self.s.get16be()
        let _ = self.s.get16be()
        self.app14_color_transform = self.s.get8()
        l -= 6
      }
    }
    self.s.skip(l)
    return true
  }
  false
}

///|
fn StbiJpeg::process_scan_header(self : StbiJpeg) -> Bool {
  let ls = self.s.get16be()
  self.scan_n = self.s.get8()
  if self.scan_n < 1 || self.scan_n > 4 || self.scan_n > self.s.img_n {
    return false
  }
  if ls != 6 + 2 * self.scan_n {
    return false
  }
  for i = 0; i < self.scan_n; i = i + 1 {
    let id = self.s.get8()
    let q = self.s.get8()
    let mut which = 0
    while which < self.s.img_n {
      if self.img_comp[which].id == id {
        break
      }
      which += 1
    }
    if which == self.s.img_n {
      return false
    }
    self.img_comp[which].hd = q >> 4
    if self.img_comp[which].hd > 3 {
      return false
    }
    self.img_comp[which].ha = q & 15
    if self.img_comp[which].ha > 3 {
      return false
    }
    self.order[i] = which
  }
  self.spec_start = self.s.get8()
  self.spec_end = self.s.get8()
  let aa = self.s.get8()
  self.succ_high = aa >> 4
  self.succ_low = aa & 15
  if self.progressive {
    if self.spec_start > 63 ||
      self.spec_end > 63 ||
      self.spec_start > self.spec_end ||
      self.succ_high > 13 ||
      self.succ_low > 13 {
      return false
    }
  } else {
    if self.spec_start != 0 || self.succ_high != 0 || self.succ_low != 0 {
      return false
    }
    self.spec_end = 63
  }
  true
}

///|
fn StbiJpeg::process_frame_header(self : StbiJpeg, scan : Int) -> Bool {
  let s = self.s
  let lf = s.get16be()
  if lf < 11 {
    return false
  }
  let p = s.get8()
  if p != 8 {
    return false
  }
  s.img_y = s.get16be()
  if s.img_y == 0 {
    return false
  }
  s.img_x = s.get16be()
  if s.img_x == 0 {
    return false
  }
  if s.img_y > STBI_MAX_DIMENSIONS || s.img_x > STBI_MAX_DIMENSIONS {
    return false
  }
  let c = s.get8()
  if c != 3 && c != 1 && c != 4 {
    return false
  }
  s.img_n = c
  if lf != 8 + 3 * s.img_n {
    return false
  }
  self.rgb = 0
  let rgb_ids : FixedArray[Int] = [82, 71, 66] // 'R','G','B'
  for i = 0; i < s.img_n; i = i + 1 {
    self.img_comp[i].id = s.get8()
    if s.img_n == 3 && self.img_comp[i].id == rgb_ids[i] {
      self.rgb += 1
    }
    let q = s.get8()
    self.img_comp[i].h = q >> 4
    if self.img_comp[i].h == 0 || self.img_comp[i].h > 4 {
      return false
    }
    self.img_comp[i].v = q & 15
    if self.img_comp[i].v == 0 || self.img_comp[i].v > 4 {
      return false
    }
    self.img_comp[i].tq = s.get8()
    if self.img_comp[i].tq > 3 {
      return false
    }
  }
  if scan != STBI_SCAN_LOAD {
    return true
  }
  if !stbi_mad3sizes_valid(s.img_x, s.img_y, s.img_n, 0) {
    return false
  }
  let mut h_max = 1
  let mut v_max = 1
  for i = 0; i < s.img_n; i = i + 1 {
    if self.img_comp[i].h > h_max {
      h_max = self.img_comp[i].h
    }
    if self.img_comp[i].v > v_max {
      v_max = self.img_comp[i].v
    }
  }
  for i = 0; i < s.img_n; i = i + 1 {
    if h_max % self.img_comp[i].h != 0 || v_max % self.img_comp[i].v != 0 {
      return false
    }
  }
  self.img_h_max = h_max
  self.img_v_max = v_max
  self.img_mcu_w = h_max * 8
  self.img_mcu_h = v_max * 8
  self.img_mcu_x = (s.img_x + self.img_mcu_w - 1) / self.img_mcu_w
  self.img_mcu_y = (s.img_y + self.img_mcu_h - 1) / self.img_mcu_h
  for i = 0; i < s.img_n; i = i + 1 {
    let comp = self.img_comp[i]
    comp.x = (s.img_x * comp.h + h_max - 1) / h_max
    comp.y = (s.img_y * comp.v + v_max - 1) / v_max
    comp.w2 = self.img_mcu_x * comp.h * 8
    comp.h2 = self.img_mcu_y * comp.v * 8
    if !stbi_mad2sizes_valid(comp.w2, comp.h2, 15) {
      return false
    }
    comp.data = FixedArray::make(comp.w2 * comp.h2, (0 : Byte))
    if self.progressive {
      comp.coeff_w = comp.w2 / 8
      if !stbi_mad3sizes_valid(comp.w2, comp.h2, 2, 15) {
        return false
      }
      comp.coeff = FixedArray::make(comp.w2 * comp.h2, 0)
    }
  }
  true
}

///|
fn StbiJpeg::decode_header(self : StbiJpeg, scan : Int) -> Bool {
  self.jfif = false
  self.app14_color_transform = -1
  self.marker = JPEG_MARKER_NONE
  let mut m = self.get_marker()
  if m != 0xD8 {
    return false
  }
  if scan == STBI_SCAN_TYPE {
    return true
  }
  m = self.get_marker()
  while m != 0xC0 && m != 0xC1 && m != 0xC2 {
    if !self.process_marker(m) {
      return false
    }
    m = self.get_marker()
    while m == JPEG_MARKER_NONE {
      if self.s.at_eof() {
        return false
      }
      m = self.get_marker()
    }
  }
  self.progressive = m == 0xC2
  self.process_frame_header(scan)
}

///|
fn StbiJpeg::skip_junk_at_end(self : StbiJpeg) -> Int {
  while !self.s.at_eof() {
    let mut x = self.s.get8()
    while x == 0xFF {
      if self.s.at_eof() {
        return JPEG_MARKER_NONE
      }
      x = self.s.get8()
      if x != 0 && x != 0xFF {
        return x
      }
    }
  }
  JPEG_MARKER_NONE
}

///|
fn StbiJpeg::decode_image(self : StbiJpeg) -> Bool {
  let mut got_data = false
  self.restart_interval = 0
  if !self.decode_header(STBI_SCAN_LOAD) {
    return false
  }
  let mut m = self.get_marker()
  while m != 0xD9 {
    if m == 0xDA {
      got_data = true
      if !self.process_scan_header() {
        return false
      }
      if !self.parse_entropy_coded_data() {
        return false
      }
      if self.marker == JPEG_MARKER_NONE {
        self.marker = self.skip_junk_at_end()
      }
      m = self.get_marker()
      if jpeg_is_restart(m) {
        m = self.get_marker()
      }
    } else if m == 0xDC {
      let ld = self.s.get16be()
      let nl = self.s.get16be()
      if ld != 4 || nl != self.s.img_y {
        return false
      }
      m = self.get_marker()
    } else {
      if !self.process_marker(m) {
        return false
      }
      m = self.get_marker()
    }
  }
  if self.progressive {
    self.finish()
  }
  got_data
}

///|
fn jpeg_resample_row_v_2(
  out : FixedArray[Byte],
  src : FixedArray[Byte],
  near_off : Int,
  far_off : Int,
  w : Int,
) -> Unit {
  for i = 0; i < w; i = i + 1 {
    out[i] = ((3 * src[near_off + i].to_int() + src[far_off + i].to_int() + 2) >>
    2).to_byte()
  }
}

///|
fn jpeg_resample_row_h_2(
  out : FixedArray[Byte],
  src : FixedArray[Byte],
  near_off : Int,
  w : Int,
) -> Unit {
  if w == 1 {
    let v = src[near_off]
    out[0] = v
    out[1] = v
    return
  }
  out[0] = src[near_off]
  out[1] = ((src[near_off].to_int() * 3 + src[near_off + 1].to_int() + 2) >> 2).to_byte()
  for i = 1; i < w - 1; i = i + 1 {
    let n = 3 * src[near_off + i].to_int() + 2
    out[i * 2] = ((n + src[near_off + i - 1].to_int()) >> 2).to_byte()
    out[i * 2 + 1] = ((n + src[near_off + i + 1].to_int()) >> 2).to_byte()
  }
  out[(w - 1) * 2] = ((src[near_off + w - 2].to_int() * 3 +
    src[near_off + w - 1].to_int() +
    2) >>
  2).to_byte()
  out[(w - 1) * 2 + 1] = src[near_off + w - 1]
}

///|
fn jpeg_resample_row_hv_2(
  out : FixedArray[Byte],
  src : FixedArray[Byte],
  near_off : Int,
  far_off : Int,
  w : Int,
) -> Unit {
  if w == 1 {
    let v = ((3 * src[near_off].to_int() + src[far_off].to_int() + 2) >> 2).to_byte()
    out[0] = v
    out[1] = v
    return
  }
  let mut t1 = 3 * src[near_off].to_int() + src[far_off].to_int()
  out[0] = ((t1 + 2) >> 2).to_byte()
  for i = 1; i < w; i = i + 1 {
    let t0 = t1
    t1 = 3 * src[near_off + i].to_int() + src[far_off + i].to_int()
    out[i * 2 - 1] = ((3 * t0 + t1 + 8) >> 4).to_byte()
    out[i * 2] = ((3 * t1 + t0 + 8) >> 4).to_byte()
  }
  out[w * 2 - 1] = ((t1 + 2) >> 2).to_byte()
}

///|
fn jpeg_resample_row_generic(
  out : FixedArray[Byte],
  src : FixedArray[Byte],
  near_off : Int,
  w : Int,
  hs : Int,
) -> Unit {
  for i = 0; i < w; i = i + 1 {
    let v = src[near_off + i]
    for j = 0; j < hs; j = j + 1 {
      out[i * hs + j] = v
    }
  }
}

///|
fn jpeg_ycbcr_to_rgb_row(
  out : FixedArray[Byte],
  out_off : Int,
  y_buf : FixedArray[Byte],
  y_off : Int,
  cb_buf : FixedArray[Byte],
  cb_off : Int,
  cr_buf : FixedArray[Byte],
  cr_off : Int,
  count : Int,
  step : Int,
) -> Unit {
  let mut o = out_off
  for i = 0; i < count; i = i + 1 {
    let y_fixed = (y_buf[y_off + i].to_int() << 20) + (1 << 19)
    let cr = cr_buf[cr_off + i].to_int() - 128
    let cb = cb_buf[cb_off + i].to_int() - 128
    let r = (y_fixed + cr * 1470208) >> 20
    let g = (y_fixed + cr * -748800 + ((cb * -360960) & -65536)) >> 20
    let b = (y_fixed + cb * 1858048) >> 20
    out[o] = jpeg_clamp(r)
    out[o + 1] = jpeg_clamp(g)
    out[o + 2] = jpeg_clamp(b)
    if step == 4 {
      out[o + 3] = (255 : Byte)
    }
    o += step
  }
}

///|
fn jpeg_blinn_8x8(x : Int, y : Int) -> Byte {
  let t = x * y + 128
  ((t + (t >> 8)) >> 8).to_byte()
}

///|
priv struct JpegResample {
  mode : Int // 0=1x1, 1=v2, 2=h2, 3=hv2, 4=generic
  mut line0 : Int
  mut line1 : Int
  hs : Int
  vs : Int
  w_lores : Int
  mut ystep : Int
  mut ypos : Int
}

///|
fn stbi_jpeg_load(s : StbiContext, req_comp : Int) -> StbiDecodeResult? {
  if req_comp < 0 || req_comp > 4 {
    return None
  }
  let z = StbiJpeg::new(s)
  s.img_n = 0
  if !z.decode_image() {
    return None
  }
  let n = if req_comp != 0 {
    req_comp
  } else if s.img_n >= 3 {
    3
  } else {
    1
  }
  let is_rgb = s.img_n == 3 &&
    (z.rgb == 3 || (z.app14_color_transform == 0 && !z.jfif))
  let decode_n = if s.img_n == 3 && n < 3 && !is_rgb { 1 } else { s.img_n }
  if decode_n <= 0 {
    return None
  }
  let res_comp : FixedArray[JpegResample] = FixedArray::makei(4, fn(k) {
    if k < decode_n {
      let comp = z.img_comp[k]
      comp.linebuf = FixedArray::make(s.img_x + 4, (0 : Byte))
      let hs = z.img_h_max / comp.h
      let vs = z.img_v_max / comp.v
      let mode = if hs == 1 && vs == 1 {
        0
      } else if hs == 1 && vs == 2 {
        1
      } else if hs == 2 && vs == 1 {
        2
      } else if hs == 2 && vs == 2 {
        3
      } else {
        4
      }
      {
        mode,
        line0: 0,
        line1: 0,
        hs,
        vs,
        w_lores: (s.img_x + hs - 1) / hs,
        ystep: vs >> 1,
        ypos: 0,
      }
    } else {
      {
        mode: 0,
        line0: 0,
        line1: 0,
        hs: 1,
        vs: 1,
        w_lores: 0,
        ystep: 0,
        ypos: 0,
      }
    }
  })
  if !stbi_mad3sizes_valid(n, s.img_x, s.img_y, 1) {
    return None
  }
  let output : FixedArray[Byte] = FixedArray::make(
    n * s.img_x * s.img_y,
    (0 : Byte),
  )
  let cbuf : FixedArray[FixedArray[Byte]] = FixedArray::make(
    4,
    FixedArray::make(0, (0 : Byte)),
  )
  let coff : FixedArray[Int] = FixedArray::make(4, 0)
  for j = 0; j < s.img_y; j = j + 1 {
    let row_off = n * s.img_x * j
    for k = 0; k < decode_n; k = k + 1 {
      let r = res_comp[k]
      let comp = z.img_comp[k]
      let y_bot = r.ystep >= (r.vs >> 1)
      let near = if y_bot { r.line1 } else { r.line0 }
      let far = if y_bot { r.line0 } else { r.line1 }
      if r.mode == 0 {
        cbuf[k] = comp.data
        coff[k] = near
      } else {
        if r.mode == 1 {
          jpeg_resample_row_v_2(comp.linebuf, comp.data, near, far, r.w_lores)
        } else if r.mode == 2 {
          jpeg_resample_row_h_2(comp.linebuf, comp.data, near, r.w_lores)
        } else if r.mode == 3 {
          jpeg_resample_row_hv_2(comp.linebuf, comp.data, near, far, r.w_lores)
        } else {
          jpeg_resample_row_generic(
            comp.linebuf,
            comp.data,
            near,
            r.w_lores,
            r.hs,
          )
        }
        cbuf[k] = comp.linebuf
        coff[k] = 0
      }
      r.ystep += 1
      if r.ystep >= r.vs {
        r.ystep = 0
        r.line0 = r.line1
        r.ypos += 1
        if r.ypos < comp.y {
          r.line1 += comp.w2
        }
      }
    }
    if n >= 3 {
      if s.img_n == 3 {
        if is_rgb {
          let mut o = row_off
          for i = 0; i < s.img_x; i = i + 1 {
            output[o] = cbuf[0][coff[0] + i]
            output[o + 1] = cbuf[1][coff[1] + i]
            output[o + 2] = cbuf[2][coff[2] + i]
            if n == 4 {
              output[o + 3] = (255 : Byte)
            }
            o += n
          }
        } else {
          jpeg_ycbcr_to_rgb_row(
            output,
            row_off,
            cbuf[0],
            coff[0],
            cbuf[1],
            coff[1],
            cbuf[2],
            coff[2],
            s.img_x,
            n,
          )
        }
      } else if s.img_n == 4 {
        if z.app14_color_transform == 0 {
          let mut o = row_off
          for i = 0; i < s.img_x; i = i + 1 {
            let m = cbuf[3][coff[3] + i].to_int()
            output[o] = jpeg_blinn_8x8(cbuf[0][coff[0] + i].to_int(), m)
            output[o + 1] = jpeg_blinn_8x8(cbuf[1][coff[1] + i].to_int(), m)
            output[o + 2] = jpeg_blinn_8x8(cbuf[2][coff[2] + i].to_int(), m)
            if n == 4 {
              output[o + 3] = (255 : Byte)
            }
            o += n
          }
        } else if z.app14_color_transform == 2 {
          jpeg_ycbcr_to_rgb_row(
            output,
            row_off,
            cbuf[0],
            coff[0],
            cbuf[1],
            coff[1],
            cbuf[2],
            coff[2],
            s.img_x,
            n,
          )
          let mut o = row_off
          for i = 0; i < s.img_x; i = i + 1 {
            let m = cbuf[3][coff[3] + i].to_int()
            output[o] = jpeg_blinn_8x8(255 - output[o].to_int(), m)
            output[o + 1] = jpeg_blinn_8x8(255 - output[o + 1].to_int(), m)
            output[o + 2] = jpeg_blinn_8x8(255 - output[o + 2].to_int(), m)
            o += n
          }
        } else {
          jpeg_ycbcr_to_rgb_row(
            output,
            row_off,
            cbuf[0],
            coff[0],
            cbuf[1],
            coff[1],
            cbuf[2],
            coff[2],
            s.img_x,
            n,
          )
        }
      } else {
        let mut o = row_off
        for i = 0; i < s.img_x; i = i + 1 {
          let v = cbuf[0][coff[0] + i]
          output[o] = v
          output[o + 1] = v
          output[o + 2] = v
          if n == 4 {
            output[o + 3] = (255 : Byte)
          }
          o += n
        }
      }
    } else if is_rgb {
      if n == 1 {
        for i = 0; i < s.img_x; i = i + 1 {
          output[row_off + i] = stbi_compute_y(
            cbuf[0][coff[0] + i].to_int(),
            cbuf[1][coff[1] + i].to_int(),
            cbuf[2][coff[2] + i].to_int(),
          )
        }
      } else {
        for i = 0; i < s.img_x; i = i + 1 {
          output[row_off + i * 2] = stbi_compute_y(
            cbuf[0][coff[0] + i].to_int(),
            cbuf[1][coff[1] + i].to_int(),
            cbuf[2][coff[2] + i].to_int(),
          )
          output[row_off + i * 2 + 1] = (255 : Byte)
        }
      }
    } else if s.img_n == 4 && z.app14_color_transform == 0 {
      let mut o = row_off
      for i = 0; i < s.img_x; i = i + 1 {
        let m = cbuf[3][coff[3] + i].to_int()
        let r = jpeg_blinn_8x8(cbuf[0][coff[0] + i].to_int(), m).to_int()
        let g = jpeg_blinn_8x8(cbuf[1][coff[1] + i].to_int(), m).to_int()
        let b = jpeg_blinn_8x8(cbuf[2][coff[2] + i].to_int(), m).to_int()
        output[o] = stbi_compute_y(r, g, b)
        if n == 2 {
          output[o + 1] = (255 : Byte)
        }
        o += n
      }
    } else if s.img_n == 4 && z.app14_color_transform == 2 {
      let mut o = row_off
      for i = 0; i < s.img_x; i = i + 1 {
        output[o] = jpeg_blinn_8x8(
          255 - cbuf[0][coff[0] + i].to_int(),
          cbuf[3][coff[3] + i].to_int(),
        )
        if n == 2 {
          output[o + 1] = (255 : Byte)
        }
        o += n
      }
    } else if n == 1 {
      for i = 0; i < s.img_x; i = i + 1 {
        output[row_off + i] = cbuf[0][coff[0] + i]
      }
    } else {
      for i = 0; i < s.img_x; i = i + 1 {
        output[row_off + i * 2] = cbuf[0][coff[0] + i]
        output[row_off + i * 2 + 1] = (255 : Byte)
      }
    }
  }
  let orig_comp = if s.img_n >= 3 { 3 } else { 1 }
  Some({
    width: s.img_x,
    height: s.img_y,
    comp: orig_comp,
    pixels: StbiRawPixels::Bits8(output),
  })
}

///|
fn stbi_jpeg_test(s : StbiContext) -> Bool {
  let j = StbiJpeg::new(s)
  let r = j.decode_header(STBI_SCAN_TYPE)
  s.rewind()
  r
}

///|
fn stbi_jpeg_info(s : StbiContext) -> StbiInfo? {
  let j = StbiJpeg::new(s)
  if !j.decode_header(STBI_SCAN_HEADER) {
    s.rewind()
    return None
  }
  Some({
    width: s.img_x,
    height: s.img_y,
    channels: if s.img_n >= 3 { 3 } else { 1 },
    image_type: StbiImageType::Jpeg,
    is_16_bit: false,
    is_hdr: false,
    is_iphone_png: false,
  })
}
