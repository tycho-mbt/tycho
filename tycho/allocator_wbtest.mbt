// Unit tests for the pure-MoonBit RegionPool sub-allocator.

///|
test "region pool alignment and splitting" {
  let pool = RegionPool::new((1024 : UInt64))
  let a = pool.try_alloc((100 : UInt64), (16 : UInt64))
  assert_eq(a, Some((0 : UInt64)))
  let b = pool.try_alloc((64 : UInt64), (256 : UInt64))
  // 100 rounded up to 256 alignment => 256
  assert_eq(b, Some((256 : UInt64)))
  // Padding [100..256) stays reusable for smaller aligned requests
  let c = pool.try_alloc((128 : UInt64), (16 : UInt64))
  // align_up(100, 16) = 112; 112 + 128 = 240 <= 256, fits inside padding!
  assert_eq(c, Some((112 : UInt64)))
  assert_eq(pool.used_bytes(), (292 : UInt64))
}

///|
test "region pool free coalescing and reuse" {
  let pool = RegionPool::new((512 : UInt64))
  let a = pool.try_alloc((128 : UInt64), (1 : UInt64)).unwrap()
  let b = pool.try_alloc((128 : UInt64), (1 : UInt64)).unwrap()
  let c = pool.try_alloc((128 : UInt64), (1 : UInt64)).unwrap()
  let d = pool.try_alloc((128 : UInt64), (1 : UInt64)).unwrap()
  assert_eq(pool.try_alloc((1 : UInt64), (1 : UInt64)), None)
  // Out-of-order frees must coalesce completely back into one 512-byte region
  pool.free(b, (128 : UInt64))
  pool.free(d, (128 : UInt64))
  pool.free(a, (128 : UInt64))
  pool.free(c, (128 : UInt64))
  assert_eq(pool.used_bytes(), (0 : UInt64))
  assert_eq(pool.free_list.length(), 1)
  assert_eq(pool.try_alloc((512 : UInt64), (1 : UInt64)), Some((0 : UInt64)))
}

///|
test "region pool oom returns none" {
  let pool = RegionPool::new((256 : UInt64))
  assert_eq(pool.try_alloc((300 : UInt64), (1 : UInt64)), None)
  assert_eq(pool.try_alloc((0 : UInt64), (16 : UInt64)), None)
}

///|
test "region pool serves 64 KiB placements and reuses a freed slot" {
  // Mirrors the DX12 placed-buffer path: uniform buffers are tiny but placed
  // resources must start on D3D12_DEFAULT_RESOURCE_PLACEMENT_ALIGNMENT.
  let pool = RegionPool::new((262144 : UInt64))
  let align = (65536 : UInt64)
  let a = pool.try_alloc((32 : UInt64), align).unwrap()
  let b = pool.try_alloc((32 : UInt64), align).unwrap()
  let c = pool.try_alloc((32 : UInt64), align).unwrap()
  let d = pool.try_alloc((32 : UInt64), align).unwrap()
  assert_eq(a, (0 : UInt64))
  assert_eq(b, (65536 : UInt64))
  assert_eq(c, (131072 : UInt64))
  assert_eq(d, (196608 : UInt64))
  // A 256 KiB block fits exactly four 64 KiB slots; the fifth is when the backend
  // falls back to a committed resource.
  assert_eq(pool.try_alloc((32 : UInt64), align), None)
  pool.free(b, (32 : UInt64))
  assert_eq(pool.try_alloc((32 : UInt64), align), Some((65536 : UInt64)))
}
