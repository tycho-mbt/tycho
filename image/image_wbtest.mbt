// Unit tests for laplaceliu/tycho_image: typed decode/load errors and shapes.

///|
test "decode_rgba rejects empty data" {
  let rejected = try {
    let _ = decode_rgba(b"")
    false
  } catch {
    ImageError::DecodeFailed(_) => true
    _ => false
  }
  assert_true(rejected)
}

///|
test "save_png compresses and stays pixel-exact via pure MoonBit decode_rgba" {
  let w = 64
  let h = 64
  let rgba : FixedArray[Byte] = FixedArray::make(w * h * 4, (0 : Byte))
  for y = 0; y < h; y = y + 1 {
    for x = 0; x < w; x = x + 1 {
      let i = (y * w + x) * 4
      rgba[i] = (x * 4).to_byte()
      rgba[i + 1] = (y * 4).to_byte()
      rgba[i + 2] = (40 : Byte)
      rgba[i + 3] = (255 : Byte)
    }
  }
  let path = "/tmp/tycho_image_compress_roundtrip.png"
  save_png_rgba(path, w, h, Bytes::from_array(rgba[:]))
  let bytes = read_file_bytes(path)
  assert_true(bytes.length() > 0)
  assert_true(bytes.length() < w * h * 4 / 4)
  let img = decode_rgba(bytes)
  assert_eq(img.width, w)
  assert_eq(img.height, h)
  let mid = ((h / 2) * w + w / 2) * 4
  assert_eq(img.data[mid].to_int(), (w / 2) * 4)
  assert_eq(img.data[mid + 1].to_int(), (h / 2) * 4)
  assert_eq(img.data[mid + 2].to_int(), 40)
  assert_eq(img.data[mid + 3].to_int(), 255)
}

///|
test "save_png swaps bgra into rgba via pure MoonBit decode_rgba" {
  let w = 2
  let h = 2
  let px : FixedArray[Byte] = FixedArray::make(w * h * 4, (0 : Byte))
  for i = 0; i < w * h; i = i + 1 {
    px[i * 4] = (200 : Byte)
    px[i * 4 + 1] = (100 : Byte)
    px[i * 4 + 2] = (50 : Byte)
    px[i * 4 + 3] = (255 : Byte)
  }
  let path = "/tmp/tycho_image_bgra_roundtrip.png"
  save_png_rgba(path, w, h, Bytes::from_array(px[:]), bgra=true)
  let img = load_rgba(path)
  assert_eq(img.width, 2)
  assert_eq(img.height, 2)
  assert_eq(img.data[0].to_int(), 50)
  assert_eq(img.data[1].to_int(), 100)
  assert_eq(img.data[2].to_int(), 200)
}

///|
test "png round-trips through save_png and load_rgba" {
  let path = "/tmp/tycho_image_roundtrip.png"
  let px : Array[Byte] = [255, 0, 0, 255, 0, 255, 0, 255, 0, 0, 255, 255, 255, 255, 255, 255]
  save_png_rgba(path, 2, 2, Bytes::from_array(px))
  let img = load_rgba(path)
  assert_eq(img.width, 2)
  assert_eq(img.height, 2)
  assert_eq(img.format, ImageFormat::RGBA8)
  assert_eq(img.data.length(), 16)
  assert_eq(img.byte_size(), 16)
  assert_true(!img.is_empty())
  // Top-left pixel must survive the encode/decode round-trip.
  assert_eq(img.data[0].to_int(), 255)
  assert_eq(img.data[1].to_int(), 0)
  assert_eq(img.data[2].to_int(), 0)
  assert_eq(img.data[3].to_int(), 255)
}

///|
test "load_hdr reads linear float pixels" {
  let hdr = load_hdr("shader/testdata/test_2x2.hdr")
  assert_eq(hdr.width, 2)
  assert_eq(hdr.height, 2)
  assert_true(hdr.pixels.length() >= 12)
  assert_true(!hdr.is_empty())
}

///|
test "read_file_bytes reports a missing file as IoFailed" {
  let rejected = try {
    let _ = read_file_bytes_checked("no/such/file.bin")
    false
  } catch {
    ImageError::IoFailed(_) => true
    _ => false
  }
  assert_true(rejected)
  assert_eq(read_file_bytes("no/such/file.bin").length(), 0)
}

///|
test "save_png refuses a float image" {
  let rejected = try {
    save_png("/tmp/tycho_image_should_not_exist.png", Image::new(1, 1, ImageFormat::R32Float, b""))
    false
  } catch {
    ImageError::EncodeFailed(_) => true
    _ => false
  }
  assert_true(rejected)
}

///|
test "save_png compresses and stays pixel-exact via pure MoonBit decode_rgba" {
  let w = 64
  let h = 64
  let rgba : FixedArray[Byte] = FixedArray::make(w * h * 4, (0 : Byte))
  for y = 0; y < h; y = y + 1 {
    for x = 0; x < w; x = x + 1 {
      let i = (y * w + x) * 4
      rgba[i] = (x * 4).to_byte()
      rgba[i + 1] = (y * 4).to_byte()
      rgba[i + 2] = (40 : Byte)
      rgba[i + 3] = (255 : Byte)
    }
  }
  let path = "/tmp/tycho_image_compress_roundtrip.png"
  save_png_rgba(path, w, h, Bytes::from_array(rgba[:]))
  let bytes = read_file_bytes(path)
  assert_true(bytes.length() > 0)
  assert_true(bytes.length() < w * h * 4 / 4)
  let img = decode_rgba(bytes)
  assert_eq(img.width, w)
  assert_eq(img.height, h)
  let mid = ((h / 2) * w + w / 2) * 4
  assert_eq(img.data[mid].to_int(), (w / 2) * 4)
  assert_eq(img.data[mid + 1].to_int(), (h / 2) * 4)
  assert_eq(img.data[mid + 2].to_int(), 40)
  assert_eq(img.data[mid + 3].to_int(), 255)
}

///|
test "save_png swaps bgra into rgba via pure MoonBit decode_rgba" {
  let w = 2
  let h = 2
  let px : FixedArray[Byte] = FixedArray::make(w * h * 4, (0 : Byte))
  for i = 0; i < w * h; i = i + 1 {
    px[i * 4] = (200 : Byte)
    px[i * 4 + 1] = (100 : Byte)
    px[i * 4 + 2] = (50 : Byte)
    px[i * 4 + 3] = (255 : Byte)
  }
  let path = "/tmp/tycho_image_bgra_roundtrip.png"
  save_png_rgba(path, w, h, Bytes::from_array(px[:]), bgra=true)
  let img = load_rgba(path)
  assert_eq(img.width, 2)
  assert_eq(img.height, 2)
  assert_eq(img.data[0].to_int(), 50)
  assert_eq(img.data[1].to_int(), 100)
  assert_eq(img.data[2].to_int(), 200)
}
