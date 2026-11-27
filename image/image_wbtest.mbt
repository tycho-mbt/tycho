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
