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
  let nodes = dx_device_get_node_count(device.raw())
  assert_true(nodes >= 1)
  // ID3D12Device::CheckFeatureSupport with the struct-by-pointer ABI.
  let data = FixedArray::make(4, (0 : Int32))
  let hr = dx_device_check_feature_support(
    device.raw(),
    1, // D3D12_FEATURE_ARCHITECTURE
    int32_ptr(data),
    16,
  )
  assert_eq(hr, 0)
  assert_true(data[0] >= 0)
  device.destroy()
}
