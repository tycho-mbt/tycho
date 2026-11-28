// Pure MoonBit port of stb_image v2.34 zlib / DEFLATE decoder.

///|
const ZFAST_BITS : Int = 9

///|
const ZFAST_MASK : Int = 511 // (1 << 9) - 1

///|
const ZNSYMS : Int = 288

///|
priv struct StbiZHuffman {
  fast : FixedArray[Int] // 512 entries (uint16)
  firstcode : FixedArray[Int] // 16 entries
  maxcode : FixedArray[Int] // 17 entries
  firstsymbol : FixedArray[Int] // 16 entries
  size : FixedArray[Int] // 288 entries
  value : FixedArray[Int] // 288 entries
}

///|
fn StbiZHuffman::new() -> StbiZHuffman {
  {
    fast: FixedArray::make(1 << ZFAST_BITS, 0),
    firstcode: FixedArray::make(16, 0),
    maxcode: FixedArray::make(17, 0),
    firstsymbol: FixedArray::make(16, 0),
    size: FixedArray::make(ZNSYMS, 0),
    value: FixedArray::make(ZNSYMS, 0),
  }
}

///|
fn zbitreverse16(n_in : Int) -> Int {
  let mut n = n_in & 0xFFFF
  n = ((n & 0xAAAA) >> 1) | ((n & 0x5555) << 1)
  n = ((n & 0xCCCC) >> 2) | ((n & 0x3333) << 2)
  n = ((n & 0xF0F0) >> 4) | ((n & 0x0F0F) << 4)
  n = ((n & 0xFF00) >> 8) | ((n & 0x00FF) << 8)
  n & 0xFFFF
}

///|
fn zbit_reverse(v : Int, bits : Int) -> Int {
  zbitreverse16(v) >> (16 - bits)
}

///|
fn zbuild_huffman(
  z : StbiZHuffman,
  sizelist : FixedArray[Int],
  offset : Int,
  num : Int,
) -> Bool {
  let next_code : FixedArray[Int] = FixedArray::make(16, 0)
  let sizes : FixedArray[Int] = FixedArray::make(17, 0)
  for i = 0; i < 512; i = i + 1 {
    z.fast[i] = 0
  }
  for i = 0; i < num; i = i + 1 {
    let s = sizelist[offset + i]
    if s < 0 || s >= 17 {
      return false
    }
    sizes[s] += 1
  }
  sizes[0] = 0
  for i = 1; i < 16; i = i + 1 {
    if sizes[i] > (1 << i) {
      return false
    }
  }
  let mut code = 0
  let mut k = 0
  for i = 1; i < 16; i = i + 1 {
    next_code[i] = code
    z.firstcode[i] = code
    z.firstsymbol[i] = k
    code = code + sizes[i]
    if sizes[i] != 0 {
      if code - 1 >= (1 << i) {
        return false
      }
    }
    z.maxcode[i] = code << (16 - i)
    code = code << 1
    k += sizes[i]
  }
  z.maxcode[16] = 0x10000
  for i = 0; i < num; i = i + 1 {
    let s = sizelist[offset + i]
    if s != 0 {
      let c = next_code[s] - z.firstcode[s] + z.firstsymbol[s]
      let fastv = (s << 9) | i
      z.size[c] = s
      z.value[c] = i
      if s <= ZFAST_BITS {
        let mut j = zbit_reverse(next_code[s], s)
        let step = 1 << s
        while j < (1 << ZFAST_BITS) {
          z.fast[j] = fastv
          j += step
        }
      }
      next_code[s] += 1
    }
  }
  true
}

///|
priv struct StbiZBuf {
  zbuf : FixedArray[Byte]
  zlen : Int
  mut zpos : Int
  mut num_bits : Int
  mut hit_zeof_once : Bool
  mut code_buffer : UInt
  mut zout : FixedArray[Byte]
  mut zout_pos : Int
  mut zout_cap : Int
  z_expandable : Bool
  z_length : StbiZHuffman
  z_distance : StbiZHuffman
}

///|
fn StbiZBuf::zeof(self : StbiZBuf) -> Bool {
  self.zpos >= self.zlen
}

///|
fn StbiZBuf::zget8(self : StbiZBuf) -> Int {
  if self.zpos >= self.zlen {
    0
  } else {
    let b = self.zbuf[self.zpos].to_int()
    self.zpos += 1
    b
  }
}

///|
fn StbiZBuf::fill_bits(self : StbiZBuf) -> Unit {
  while true {
    if self.num_bits < 32 && self.code_buffer >= ((1 : UInt) << self.num_bits) {
      self.zpos = self.zlen
      return
    }
    self.code_buffer = self.code_buffer |
      (self.zget8().reinterpret_as_uint() << self.num_bits)
    self.num_bits += 8
    if self.num_bits > 24 {
      break
    }
  }
}

///|
fn StbiZBuf::zreceive(self : StbiZBuf, n : Int) -> Int {
  if self.num_bits < n {
    self.fill_bits()
  }
  let mask = ((1 : UInt) << n) - (1 : UInt)
  let k = (self.code_buffer & mask).reinterpret_as_int()
  self.code_buffer = self.code_buffer >> n
  self.num_bits -= n
  k
}

///|
fn StbiZBuf::huffman_decode_slow(self : StbiZBuf, z : StbiZHuffman) -> Int {
  let k = zbit_reverse(self.code_buffer.reinterpret_as_int(), 16)
  let mut s = ZFAST_BITS + 1
  while s < 16 {
    if k < z.maxcode[s] {
      break
    }
    s += 1
  }
  if s >= 16 {
    return -1
  }
  let b = (k >> (16 - s)) - z.firstcode[s] + z.firstsymbol[s]
  if b < 0 || b >= ZNSYMS {
    return -1
  }
  if z.size[b] != s {
    return -1
  }
  self.code_buffer = self.code_buffer >> s
  self.num_bits -= s
  z.value[b]
}

///|
fn StbiZBuf::huffman_decode(self : StbiZBuf, z : StbiZHuffman) -> Int {
  if self.num_bits < 16 {
    if self.zeof() {
      if !self.hit_zeof_once {
        self.hit_zeof_once = true
        self.num_bits += 16
      } else {
        return -1
      }
    } else {
      self.fill_bits()
    }
  }
  let b = z.fast[(self.code_buffer & ZFAST_MASK.reinterpret_as_uint()).reinterpret_as_int()]
  if b != 0 {
    let s = b >> 9
    self.code_buffer = self.code_buffer >> s
    self.num_bits -= s
    return b & 511
  }
  self.huffman_decode_slow(z)
}

///|
fn StbiZBuf::zexpand(self : StbiZBuf, n : Int) -> Bool {
  if !self.z_expandable {
    return false
  }
  let cur = self.zout_pos
  if STBI_INT_MAX - cur < n {
    return false
  }
  let mut limit = if self.zout_cap == 0 { 1 } else { self.zout_cap }
  while cur + n > limit {
    if limit > STBI_INT_MAX / 2 {
      return false
    }
    limit *= 2
  }
  let next : FixedArray[Byte] = FixedArray::make(limit, (0 : Byte))
  for i = 0; i < cur; i = i + 1 {
    next[i] = self.zout[i]
  }
  self.zout = next
  self.zout_cap = limit
  true
}

///|
let zlength_base : FixedArray[Int] = [
  3, 4, 5, 6, 7, 8, 9, 10, 11, 13, 15, 17, 19, 23, 27, 31, 35, 43, 51, 59, 67,
  83, 99, 115, 131, 163, 195, 227, 258, 0, 0,
]

///|
let zlength_extra : FixedArray[Int] = [
  0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5,
  5, 5, 0, 0, 0,
]

///|
let zdist_base : FixedArray[Int] = [
  1, 2, 3, 4, 5, 7, 9, 13, 17, 25, 33, 49, 65, 97, 129, 193, 257, 385, 513,
  769, 1025, 1537, 2049, 3073, 4097, 6145, 8193, 12289, 16385, 24577, 0, 0,
]

///|
let zdist_extra : FixedArray[Int] = [
  0, 0, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10, 10, 11,
  11, 12, 12, 13, 13, 0, 0,
]

///|
let zlength_dezigzag : FixedArray[Int] = [
  16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15,
]

///|
fn zdefault_length_table() -> FixedArray[Int] {
  let t : FixedArray[Int] = FixedArray::make(ZNSYMS, 8)
  for i = 144; i <= 255; i = i + 1 {
    t[i] = 9
  }
  for i = 256; i <= 279; i = i + 1 {
    t[i] = 7
  }
  t
}

///|
fn zdefault_distance_table() -> FixedArray[Int] {
  FixedArray::make(32, 5)
}

///|
fn StbiZBuf::parse_huffman_block(self : StbiZBuf) -> Bool {
  while true {
    let mut z = self.huffman_decode(self.z_length)
    if z < 256 {
      if z < 0 {
        return false
      }
      if self.zout_pos >= self.zout_cap {
        if !self.zexpand(1) {
          return false
        }
      }
      self.zout[self.zout_pos] = z.to_byte()
      self.zout_pos += 1
    } else {
      if z == 256 {
        if self.hit_zeof_once && self.num_bits < 16 {
          return false
        }
        return true
      }
      if z >= 286 {
        return false
      }
      z -= 257
      let mut len = zlength_base[z]
      let lex = zlength_extra[z]
      if lex != 0 {
        len += self.zreceive(lex)
      }
      z = self.huffman_decode(self.z_distance)
      if z < 0 || z >= 30 {
        return false
      }
      let mut dist = zdist_base[z]
      let dex = zdist_extra[z]
      if dex != 0 {
        dist += self.zreceive(dex)
      }
      if self.zout_pos < dist {
        return false
      }
      if len > self.zout_cap - self.zout_pos {
        if !self.zexpand(len) {
          return false
        }
      }
      let out = self.zout
      let mut src = self.zout_pos - dist
      let mut dst = self.zout_pos
      if dist == 1 {
        let v = out[src]
        for i = 0; i < len; i = i + 1 {
          out[dst + i] = v
        }
        self.zout_pos = dst + len
      } else {
        for i = 0; i < len; i = i + 1 {
          out[dst] = out[src]
          dst += 1
          src += 1
        }
        self.zout_pos = dst
      }
    }
  }
  true
}

///|
fn StbiZBuf::compute_huffman_codes(self : StbiZBuf) -> Bool {
  let z_codelength = StbiZHuffman::new()
  let lencodes : FixedArray[Int] = FixedArray::make(286 + 32 + 137, 0)
  let codelength_sizes : FixedArray[Int] = FixedArray::make(19, 0)
  let hlit = self.zreceive(5) + 257
  let hdist = self.zreceive(5) + 1
  let hclen = self.zreceive(4) + 4
  let ntot = hlit + hdist
  for i = 0; i < hclen; i = i + 1 {
    codelength_sizes[zlength_dezigzag[i]] = self.zreceive(3)
  }
  if !zbuild_huffman(z_codelength, codelength_sizes, 0, 19) {
    return false
  }
  let mut n = 0
  while n < ntot {
    let c = self.huffman_decode(z_codelength)
    if c < 0 || c >= 19 {
      return false
    }
    if c < 16 {
      lencodes[n] = c
      n += 1
    } else {
      let mut fill = 0
      let mut rep = 0
      if c == 16 {
        rep = self.zreceive(2) + 3
        if n == 0 {
          return false
        }
        fill = lencodes[n - 1]
      } else if c == 17 {
        rep = self.zreceive(3) + 3
      } else if c == 18 {
        rep = self.zreceive(7) + 11
      } else {
        return false
      }
      if ntot - n < rep {
        return false
      }
      for i = 0; i < rep; i = i + 1 {
        lencodes[n + i] = fill
      }
      n += rep
    }
  }
  if n != ntot {
    return false
  }
  if !zbuild_huffman(self.z_length, lencodes, 0, hlit) {
    return false
  }
  if !zbuild_huffman(self.z_distance, lencodes, hlit, hdist) {
    return false
  }
  true
}

///|
fn StbiZBuf::parse_uncompressed_block(self : StbiZBuf) -> Bool {
  let header : FixedArray[Int] = FixedArray::make(4, 0)
  if (self.num_bits & 7) != 0 {
    let _ = self.zreceive(self.num_bits & 7)
  }
  let mut k = 0
  while self.num_bits > 0 {
    if k >= 4 {
      return false
    }
    header[k] = (self.code_buffer & (255 : UInt)).reinterpret_as_int()
    k += 1
    self.code_buffer = self.code_buffer >> 8
    self.num_bits -= 8
  }
  if self.num_bits < 0 {
    return false
  }
  while k < 4 {
    header[k] = self.zget8()
    k += 1
  }
  let len = header[1] * 256 + header[0]
  let nlen = header[3] * 256 + header[2]
  if nlen != (len ^ 0xFFFF) {
    return false
  }
  if len > self.zlen - self.zpos {
    return false
  }
  if len > self.zout_cap - self.zout_pos {
    if !self.zexpand(len) {
      return false
    }
  }
  for i = 0; i < len; i = i + 1 {
    self.zout[self.zout_pos + i] = self.zbuf[self.zpos + i]
  }
  self.zpos += len
  self.zout_pos += len
  true
}

///|
fn StbiZBuf::parse_zlib_header(self : StbiZBuf) -> Bool {
  let cmf = self.zget8()
  let cm = cmf & 15
  let flg = self.zget8()
  if self.zeof() {
    return false
  }
  if (cmf * 256 + flg) % 31 != 0 {
    return false
  }
  if (flg & 32) != 0 {
    return false
  }
  if cm != 8 {
    return false
  }
  true
}

///|
fn StbiZBuf::parse_zlib(self : StbiZBuf, parse_header : Bool) -> Bool {
  if parse_header {
    if !self.parse_zlib_header() {
      return false
    }
  }
  self.num_bits = 0
  self.code_buffer = (0 : UInt)
  self.hit_zeof_once = false
  let def_len = zdefault_length_table()
  let def_dist = zdefault_distance_table()
  while true {
    let final_blk = self.zreceive(1)
    let btype = self.zreceive(2)
    if btype == 0 {
      if !self.parse_uncompressed_block() {
        return false
      }
    } else if btype == 3 {
      return false
    } else {
      if btype == 1 {
        if !zbuild_huffman(self.z_length, def_len, 0, ZNSYMS) {
          return false
        }
        if !zbuild_huffman(self.z_distance, def_dist, 0, 32) {
          return false
        }
      } else if !self.compute_huffman_codes() {
        return false
      }
      if !self.parse_huffman_block() {
        return false
      }
    }
    if final_blk != 0 {
      break
    }
  }
  true
}

///|
fn stbi_zlib_decode_internal(
  src : FixedArray[Byte],
  src_len : Int,
  initial_size : Int,
  parse_header : Bool,
) -> (FixedArray[Byte], Int)? {
  let cap = if initial_size > 0 { initial_size } else { 16384 }
  let z : StbiZBuf = {
    zbuf: src,
    zlen: src_len,
    zpos: 0,
    num_bits: 0,
    hit_zeof_once: false,
    code_buffer: (0 : UInt),
    zout: FixedArray::make(cap, (0 : Byte)),
    zout_pos: 0,
    zout_cap: cap,
    z_expandable: true,
    z_length: StbiZHuffman::new(),
    z_distance: StbiZHuffman::new(),
  }
  if z.parse_zlib(parse_header) {
    Some((z.zout, z.zout_pos))
  } else {
    None
  }
}

///|
/// Decompress a zlib-framed DEFLATE stream (matches `stbi_zlib_decode_malloc`).
pub fn stbi_zlib_decode(data : Bytes) -> Bytes? {
  let src : FixedArray[Byte] = FixedArray::makei(data.length(), fn(i) { data[i] })
  match stbi_zlib_decode_internal(src, data.length(), 16384, true) {
    Some((buf, len)) => Some(Bytes::from_array(buf[:len]))
    None => None
  }
}

///|
/// Decompress a raw DEFLATE stream without zlib header (matches `stbi_zlib_decode_noheader_malloc`).
pub fn stbi_zlib_decode_noheader(data : Bytes) -> Bytes? {
  let src : FixedArray[Byte] = FixedArray::makei(data.length(), fn(i) { data[i] })
  match stbi_zlib_decode_internal(src, data.length(), 16384, false) {
    Some((buf, len)) => Some(Bytes::from_array(buf[:len]))
    None => None
  }
}
