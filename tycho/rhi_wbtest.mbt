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
