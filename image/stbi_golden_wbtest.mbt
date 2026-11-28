// Golden-data verification tests locking down pure MoonBit stb_image behavior
// against upstream C stb_image.h v2.34 across all formats, options, and edge cases.

///|
priv struct GoldenReader {
  buf : Bytes
  mut pos : Int
}

///|
fn GoldenReader::u8(self : GoldenReader) -> Int {
  let v = self.buf[self.pos].to_int()
  self.pos += 1
  v
}

///|
fn GoldenReader::u32(self : GoldenReader) -> UInt {
  let b0 = self.u8().reinterpret_as_uint()
  let b1 = self.u8().reinterpret_as_uint()
  let b2 = self.u8().reinterpret_as_uint()
  let b3 = self.u8().reinterpret_as_uint()
  b0 | (b1 << 8) | (b2 << 16) | (b3 << 24)
}

///|
fn GoldenReader::i32(self : GoldenReader) -> Int {
  self.u32().reinterpret_as_int()
}

///|
fn GoldenReader::str(self : GoldenReader) -> String {
  let len = self.u32().reinterpret_as_int()
  let sb = StringBuilder()
  for i = 0; i < len; i = i + 1 {
    sb.write_char(Int::unsafe_to_char(self.u8()))
  }
  sb.to_string()
}

///|
fn GoldenReader::blob(self : GoldenReader) -> Bytes {
  let len = self.u32().reinterpret_as_int()
  let start = self.pos
  self.pos += len
  Bytes::makei(len, fn(i) { self.buf[start + i] })
}

///|
fn bytes_match(a : Bytes, b : Bytes) -> Bool {
  if a.length() != b.length() {
    return false
  }
  for i = 0; i < a.length(); i = i + 1 {
    if a[i] != b[i] {
      return false
    }
  }
  true
}

///|
fn u16_matches_le_blob(arr : FixedArray[UInt16], blob : Bytes) -> Bool {
  if arr.length() * 2 != blob.length() {
    return false
  }
  for i = 0; i < arr.length(); i = i + 1 {
    let expected = blob[i * 2].to_int() | (blob[i * 2 + 1].to_int() << 8)
    if arr[i].to_int() != expected {
      return false
    }
  }
  true
}

///|
fn f32_matches_le_blob(arr : FixedArray[Float], blob : Bytes) -> Bool {
  if arr.length() * 4 != blob.length() {
    return false
  }
  for i = 0; i < arr.length(); i = i + 1 {
    let bits = blob[i * 4].to_int().reinterpret_as_uint() |
      (blob[i * 4 + 1].to_int().reinterpret_as_uint() << 8) |
      (blob[i * 4 + 2].to_int().reinterpret_as_uint() << 16) |
      (blob[i * 4 + 3].to_int().reinterpret_as_uint() << 24)
    let got_bits = arr[i].reinterpret_as_uint()
    if got_bits != bits {
      return false
    }
  }
  true
}

///|
test "golden: pure moonbit matches stb_image v2.34 across all formats and options" {
  let gbytes = read_file_bytes("image/testdata/golden.bin")
  assert_true(gbytes.length() > 12)
  let r : GoldenReader = { buf: gbytes, pos: 0 }
  // Magic "STBG"
  assert_eq(r.u8(), 83)
  assert_eq(r.u8(), 84)
  assert_eq(r.u8(), 66)
  assert_eq(r.u8(), 71)
  let ver = r.u32().reinterpret_as_int()
  assert_eq(ver, 1)
  let count = r.u32().reinterpret_as_int()
  assert_true(count >= 70)

  let failures : Array[String] = []

  for idx = 0; idx < count; idx = idx + 1 {
    let path = r.str()
    let fbytes = read_file_bytes(path)

    // 1. info / is_16_bit / is_hdr
    let g_info_ok = r.u8() != 0
    let g_iw = r.i32()
    let g_ih = r.i32()
    let g_ic = r.i32()
    let g_is16 = r.u8() != 0
    let g_ishdr = r.u8() != 0

    match stbi_info_from_memory(fbytes) {
      Some(info) =>
        if !g_info_ok ||
          info.width != g_iw ||
          info.height != g_ih ||
          info.channels != g_ic {
          failures.push(
            "info mismatch for \{path}: got (\{info.width},\{info.height},\{info.channels}) want ok=\{g_info_ok} (\{g_iw},\{g_ih},\{g_ic})",
          )
        }
      None =>
        if g_info_ok {
          failures.push(
            "info failed for \{path}: want (\{g_iw},\{g_ih},\{g_ic})",
          )
        }
    }
    if stbi_is_16_bit_from_memory(fbytes) != g_is16 {
      failures.push("is_16_bit mismatch for \{path}")
    }
    if stbi_is_hdr_from_memory(fbytes) != g_ishdr {
      failures.push("is_hdr mismatch for \{path}")
    }

    // 2. stbi_load_from_memory for req_comp = 0..4
    for rc = 0; rc <= 4; rc = rc + 1 {
      let g_ok = r.u8() != 0
      let g_w = r.i32()
      let g_h = r.i32()
      let g_c = r.i32()
      let g_px = r.blob()
      match stbi_load_from_memory(fbytes, desired_channels=rc) {
        Some(img) =>
          if !g_ok {
            failures.push("load8(rc=\{rc}) succeeded unexpectedly for \{path}")
          } else if img.width != g_w ||
            img.height != g_h ||
            img.channels_in_file != g_c {
            failures.push(
              "load8(rc=\{rc}) dims mismatch for \{path}: got (\{img.width},\{img.height},\{img.channels_in_file}) want (\{g_w},\{g_h},\{g_c})",
            )
          } else if !bytes_match(img.data, g_px) {
            failures.push("load8(rc=\{rc}) pixel mismatch for \{path}")
          }
        None =>
          if g_ok {
            failures.push("load8(rc=\{rc}) failed for \{path}")
          }
      }
    }

    // 3. flip_vertically=true, req_comp=4
    let gf_ok = r.u8() != 0
    let gf_w = r.i32()
    let gf_h = r.i32()
    let gf_c = r.i32()
    let gf_px = r.blob()
    let flip_opts : StbiOptions = {
      ..StbiOptions::default(),
      flip_vertically: true,
    }
    match stbi_load_from_memory(fbytes, desired_channels=4, options=flip_opts) {
      Some(img) =>
        if !gf_ok ||
          img.width != gf_w ||
          img.height != gf_h ||
          img.channels_in_file != gf_c ||
          !bytes_match(img.data, gf_px) {
          failures.push("load8(flip) mismatch for \{path}")
        }
      None =>
        if gf_ok {
          failures.push("load8(flip) failed for \{path}")
        }
    }

    // 4. stbi_load_16_from_memory for req_comp = 0, 4
    let reqs : FixedArray[Int] = [0, 4]
    for k = 0; k < 2; k = k + 1 {
      let rc = reqs[k]
      let g_ok = r.u8() != 0
      let g_w = r.i32()
      let g_h = r.i32()
      let g_c = r.i32()
      let g_px = r.blob()
      match stbi_load_16_from_memory(fbytes, desired_channels=rc) {
        Some(img) =>
          if !g_ok ||
            img.width != g_w ||
            img.height != g_h ||
            img.channels_in_file != g_c ||
            !u16_matches_le_blob(img.data, g_px) {
            failures.push("load16(rc=\{rc}) mismatch for \{path}")
          }
        None =>
          if g_ok {
            failures.push("load16(rc=\{rc}) failed for \{path}")
          }
      }
    }

    // 5. stbi_loadf_from_memory for req_comp = 0, 4
    for k = 0; k < 2; k = k + 1 {
      let rc = reqs[k]
      let g_ok = r.u8() != 0
      let g_w = r.i32()
      let g_h = r.i32()
      let g_c = r.i32()
      let g_px = r.blob()
      match stbi_loadf_from_memory(fbytes, desired_channels=rc) {
        Some(img) =>
          if !g_ok ||
            img.width != g_w ||
            img.height != g_h ||
            img.channels_in_file != g_c ||
            !f32_matches_le_blob(img.data, g_px) {
            failures.push("loadf(rc=\{rc}) mismatch for \{path}")
          }
        None =>
          if g_ok {
            failures.push("loadf(rc=\{rc}) failed for \{path}")
          }
      }
    }

    // 6. Animated GIF
    let gflag = r.u8()
    if gflag == 1 {
      let gw = r.i32()
      let gh = r.i32()
      let gz = r.i32()
      let gc = r.i32()
      let gdelays : FixedArray[Int] = FixedArray::make(gz, 0)
      for f = 0; f < gz; f = f + 1 {
        gdelays[f] = r.i32()
      }
      let gpx = r.blob()
      match stbi_load_gif_from_memory(fbytes, desired_channels=4) {
        Some(gif) => {
          let mut delays_ok = gif.delays.length() == gz
          if delays_ok {
            for f = 0; f < gz; f = f + 1 {
              if gif.delays[f] != gdelays[f] {
                delays_ok = false
              }
            }
          }
          if gif.width != gw ||
            gif.height != gh ||
            gif.frames != gz ||
            gif.channels_in_file != gc ||
            !delays_ok ||
            !bytes_match(gif.data, gpx) {
            failures.push("gif_anim mismatch for \{path}")
          }
        }
        None => failures.push("gif_anim failed for \{path}")
      }
    } else if gflag == 0 {
      let _ = r.i32()
      let _ = r.i32()
      let _ = r.i32()
      let _ = r.i32()
      let _ = r.blob()
      match stbi_load_gif_from_memory(fbytes, desired_channels=4) {
        Some(_) => failures.push("gif_anim unexpectedly succeeded for \{path}")
        None => ()
      }
    }
  }

  assert_eq(r.pos, gbytes.length())
  if failures.length() > 0 {
    let mut msg = "\{failures.length()} golden mismatches:\n"
    let lim = if failures.length() < 20 { failures.length() } else { 20 }
    for i = 0; i < lim; i = i + 1 {
      msg = msg + "  - " + failures[i] + "\n"
    }
    fail(msg)
  }
}

///|
test "real repository PNG screenshot decodes identically to C stb_image" {
  let bytes = read_file_bytes("examples/dx12/triangle/screenshot.png")
  assert_true(bytes.length() > 0)
  let pure_img = decode_rgba(bytes)
  match @shader.decode_image(bytes) {
    Some((c_px, c_w, c_h)) => {
      assert_eq(pure_img.width, c_w)
      assert_eq(pure_img.height, c_h)
      assert_true(bytes_match(pure_img.data, c_px))
    }
    None => fail("C stb_image failed on screenshot.png")
  }
}

///|
test "stbi_zlib_decode and stbi_zlib_decode_noheader round-trip" {
  // zlib.compress(b"hello world hello world hello world")
  let zbytes = Bytes::from_array([
    (0x78 : Byte),
    (0x9C : Byte),
    (0xCB : Byte),
    (0x48 : Byte),
    (0xCD : Byte),
    (0xC9 : Byte),
    (0xC9 : Byte),
    (0x57 : Byte),
    (0x28 : Byte),
    (0xCF : Byte),
    (0x2F : Byte),
    (0xCA : Byte),
    (0x49 : Byte),
    (0x51 : Byte),
    (0xC8 : Byte),
    (0xC0 : Byte),
    (0xCE : Byte),
    (0x06 : Byte),
    (0x00 : Byte),
    (0xEF : Byte),
    (0x93 : Byte),
    (0x0D : Byte),
    (0x55 : Byte),
  ])
  match stbi_zlib_decode(zbytes) {
    Some(out) => assert_eq(out, b"hello world hello world hello world")
    None => fail("stbi_zlib_decode failed")
  }
  let raw_deflate = Bytes::makei(zbytes.length() - 6, fn(i) { zbytes[i + 2] })
  match stbi_zlib_decode_noheader(raw_deflate) {
    Some(out) => assert_eq(out, b"hello world hello world hello world")
    None => fail("stbi_zlib_decode_noheader failed")
  }
}
