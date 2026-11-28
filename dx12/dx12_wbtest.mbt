// Whitebox checks for the generated COM dispatch layer. They run only where
// Direct3D 12 exists; elsewhere the package is still buildable and the tests
// pass without touching the driver.

///|
test "generated dispatch reaches a device" {
  if !available() {
    return
  }
  let device = match Device::create(warp=true, debug=false) {
    Some(d) => d
    None => return
  }
  // ID3D12Device::GetNodeCount through the generated thunk. `raw()` is the COM
  // object; `handle()` would be the wrapper struct.
  let nodes = dx_d3d12_device_get_node_count(device.raw())
  assert_true(nodes >= 1)
  // ID3D12Device::CheckFeatureSupport with the struct-by-pointer ABI.
  let data = FixedArray::make(4, (0 : Int32))
  let hr = dx_d3d12_device_check_feature_support(
    device.raw(),
    1, // D3D12_FEATURE_ARCHITECTURE
    int32_ptr(data),
    16,
  )
  assert_eq(hr, 0)
  assert_true(data[0] >= 0)
  // QueryInterface ID3D12Device -> ID3D12Device1 using generated IID.
  let d1_out = FixedArray::make(1, (0 : Int64))
  let hr_qi = com_query_interface(device.raw(), bytes_ptr(iid_d3d12_device1), int64_ptr(d1_out))
  assert_eq(hr_qi, 0)
  assert_true(d1_out[0] != (0 : Int64))
  let _ = com_release(d1_out[0].reinterpret_as_uint64())
  // CreateDXGIFactory2 via dynamic dxgi.dll entry point.
  let fac_out = FixedArray::make(1, (0 : Int64))
  let hr_fac = create_dxgi_factory2(0, bytes_ptr(iid_dxgi_factory4), int64_ptr(fac_out))
  assert_eq(hr_fac, 0)
  assert_true(fac_out[0] != (0 : Int64))
  let _ = com_release(fac_out[0].reinterpret_as_uint64())
  // D3D12SerializeVersionedRootSignature with an empty 1.1 root signature.
  // D3D12_VERSIONED_ROOT_SIGNATURE_DESC: Version=2 (1.1) at 0, Desc_1_1 (40B) at 8 -> 48B.
  let rs_desc = raw_alloc(48)
  write_u32(rs_desc, 0, (2 : UInt32)) // D3D_ROOT_SIGNATURE_VERSION_1_1
  let blob_out = FixedArray::make(1, (0 : Int64))
  let err_out = FixedArray::make(1, (0 : Int64))
  let hr_rs = d3d12_serialize_versioned_root_signature(rs_desc, int64_ptr(blob_out), int64_ptr(err_out))
  raw_free(rs_desc)
  assert_eq(hr_rs, 0)
  assert_true(blob_out[0] != (0 : Int64))
  let blob = blob_out[0].reinterpret_as_uint64()
  assert_true(dx_id3_d10_blob_get_buffer_size(blob) > (0 : Int64))
  let _ = com_release(blob)
  if err_out[0] != (0 : Int64) {
    let _ = com_release(err_out[0].reinterpret_as_uint64())
  }
  device.destroy()
}

///|
test "to_utf16 encodes null-terminated UTF-16LE" {
  let utf16 = to_utf16("AB")
  assert_eq(utf16.length(), 6)
  assert_eq(utf16[0], b'A')
  assert_eq(utf16[1], (0 : Byte))
  assert_eq(utf16[2], b'B')
  assert_eq(utf16[3], (0 : Byte))
  assert_eq(utf16[4], (0 : Byte))
  assert_eq(utf16[5], (0 : Byte))
}
