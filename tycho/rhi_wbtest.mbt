// Unit tests for pure RHI helper functions (scissor clamping, descriptor range, upload slice count).

///|
test "clamp_scissor_rect handles negative origins and target bounds" {
  assert_eq(clamp_scissor_rect(10, 20, 100, 50, 800, 600), (10, 20, 100, 50))
  assert_eq(clamp_scissor_rect(-20, -10, 100, 50, 800, 600), (0, 0, 80, 40))
  assert_eq(clamp_scissor_rect(-100, 10, 50, 40, 800, 600), (0, 10, 0, 40))
  assert_eq(clamp_scissor_rect(750, 550, 100, 100, 800, 600), (750, 550, 50, 50))
  assert_eq(clamp_scissor_rect(900, 700, 50, 50, 800, 600), (800, 600, 0, 0))
  assert_eq(clamp_scissor_rect(10, 20, -5, 30, 800, 600), (10, 20, 0, 0))
  assert_eq(clamp_scissor_rect(-10, 5, 30, 20, 0, 0), (0, 5, 20, 20))
}

///|
test "resolve_descriptor_range clamps offset and size cleanly" {
  assert_eq(resolve_descriptor_range(1024, 0, -1), (0, 1024))
  assert_eq(resolve_descriptor_range(1024, 256, 512), (256, 512))
  assert_eq(resolve_descriptor_range(1024, 768, 512), (768, 256))
  assert_eq(resolve_descriptor_range(1024, -64, 128), (0, 128))
  assert_eq(resolve_descriptor_range(1024, 2048, -1), (1024, 0))
}

///|
test "resolve_upload_count validates element counts" {
  assert_eq(resolve_upload_count(-1, 10), 10)
  assert_eq(resolve_upload_count(0, 10), 0)
  assert_eq(resolve_upload_count(4, 10), 4)
  let mut neg_err = false
  try {
    let _ = resolve_upload_count(-2, 10)
  } catch {
    InvalidArgument(_) => neg_err = true
    _ => ()
  }
  assert_eq(neg_err, true)
  let mut oob_err = false
  try {
    let _ = resolve_upload_count(11, 10)
  } catch {
    InvalidArgument(_) => oob_err = true
    _ => ()
  }
  assert_eq(oob_err, true)
}

///|
test "record_first keeps the earliest recorded error" {
  let first = record_first(None, "bind_pipeline: backend mismatch")
  assert_eq(first, Some("bind_pipeline: backend mismatch"))
  let second = record_first(first, "end_commands: later message")
  assert_eq(second, Some("bind_pipeline: backend mismatch"))
}

///|
test "vertex formats expose stable codes and byte sizes" {
  let formats : Array[VertexFormat] = [
    VertexFormat::Float2, VertexFormat::Float3, VertexFormat::Float4,
    VertexFormat::Float1, VertexFormat::Int1, VertexFormat::Uint1,
    VertexFormat::Unorm8x4, VertexFormat::Uint16x4,
  ]
  for i = 0; i < formats.length(); i = i + 1 {
    assert_eq(formats[i].code(), i)
  }
  assert_eq(VertexFormat::Float1.bytes(), 4)
  assert_eq(VertexFormat::Unorm8x4.bytes(), 4)
  assert_eq(VertexFormat::Uint16x4.bytes(), 8)
  assert_eq(VertexFormat::Float2.bytes(), 8)
  assert_eq(VertexFormat::Float3.bytes(), 12)
  assert_eq(VertexFormat::Float4.bytes(), 16)
}

///|
test "buffer usage combines roles and maps back to a kind" {
  let u = BufferUsage::storage().combine(BufferUsage::indirect())
  assert_true(u.contains(BufferUsage::storage()))
  assert_true(u.contains(BufferUsage::indirect()))
  assert_true(!u.contains(BufferUsage::vertex()))
  assert_eq(u.as_kind(), BufferKind::Indirect)
  // The legacy shortcuts keep the transfer bits the backends used to add.
  assert_true(BufferUsage::from_kind(BufferKind::Storage).contains(BufferUsage::copy_src()))
  assert_true(BufferUsage::from_kind(BufferKind::Vertex).contains(BufferUsage::copy_dst()))
  assert_true(BufferUsage::from_kind(BufferKind::Uniform).bits() != (0 : UInt32))
}

///|
test "texture desc defaults and usage flags" {
  let desc = TextureDesc::new(
    64,
    32,
    TextureFormat::RGBA8,
    usage=TextureUsage::sampled().combine(TextureUsage::render_attachment()),
  )
  assert_eq(desc.width, 64)
  assert_eq(desc.height, 32)
  assert_eq(desc.mip_levels, 1)
  assert_eq(desc.samples, SampleCount::X1)
  assert_true(desc.usage.contains(TextureUsage::sampled()))
  assert_true(desc.usage.contains(TextureUsage::render_attachment()))
  assert_true(!desc.usage.contains(TextureUsage::storage()))
  match desc.dimension {
    TextureDimension::D2 => ()
    _ => fail("default dimension must be D2")
  }
  let arr = TextureDesc::new(8, 8, TextureFormat::RGBA8, dimension=TextureDimension::D2Array(4))
  match arr.dimension {
    TextureDimension::D2Array(n) => assert_eq(n, 4)
    _ => fail("array dimension must round-trip")
  }
}
