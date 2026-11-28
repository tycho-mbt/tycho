// dx12/raw-interfaces — verifies the generated thunks for the ID3D12Device1..14
// interface chain. A D3D12 device implements every one of these interfaces, and
// the inherited methods sit at the same vtable slots, so the same raw device
// pointer can be called through each interface's thunks. This checks that every
// interface binding resolves and forwards correctly (GetNodeCount,
// GetDeviceRemovedReason, CheckFeatureSupport), under the debug layer with zero
// validation errors. Non-Windows hosts SKIP.

///|
fn fail(what : String) -> Unit {
  println("[dx12/raw-interfaces] FAIL — \{what} (last HRESULT=\{@dx12.last_error()})")
}

// Shared scratch for D3D12_FEATURE_DATA_ARCHITECTURE (program-lifetime so the raw
// pointer stays valid across every CheckFeatureSupport call).
let arch_buf : FixedArray[Int32] = FixedArray::make(4, (0 : Int32))

///|
fn main {
  if !@dx12.available() {
    println("[dx12/raw-interfaces] SKIP — d3d12.dll / dxgi.dll not loadable on this host")
    return
  }
  let device = match @dx12.Device::create(warp=@dx12.env_requests_warp(), debug=true) {
    Some(d) => d
    None =>
      match @dx12.Device::create(warp=true, debug=true) {
        Some(d) => d
        None => {
          fail("no D3D12 device (hardware and WARP both refused)")
          return
        }
      }
  }
  let raw = device.raw()
  let mut probed = 0
  let mut ok = true

  // Each block: GetNodeCount + GetDeviceRemovedReason + CheckFeatureSupport
  // (ARCHITECTURE) through one interface in the ID3D12DeviceN chain.
  let n1 = @dx12.dx_d3d12_device1_get_node_count(raw)
  let r1 = @dx12.dx_d3d12_device1_get_device_removed_reason(raw)
  let h1 = @dx12.dx_d3d12_device1_check_feature_support(raw, 1, @dx12.int32_ptr(arch_buf), 16)
  ok = ok && n1 >= 1 && r1 == 0 && h1 == 0
  probed = probed + 3

  let n2 = @dx12.dx_d3d12_device2_get_node_count(raw)
  let r2 = @dx12.dx_d3d12_device2_get_device_removed_reason(raw)
  let h2 = @dx12.dx_d3d12_device2_check_feature_support(raw, 1, @dx12.int32_ptr(arch_buf), 16)
  ok = ok && n2 >= 1 && r2 == 0 && h2 == 0
  probed = probed + 3

  let n3 = @dx12.dx_d3d12_device3_get_node_count(raw)
  let r3 = @dx12.dx_d3d12_device3_get_device_removed_reason(raw)
  let h3 = @dx12.dx_d3d12_device3_check_feature_support(raw, 1, @dx12.int32_ptr(arch_buf), 16)
  ok = ok && n3 >= 1 && r3 == 0 && h3 == 0
  probed = probed + 3

  let n4 = @dx12.dx_d3d12_device4_get_node_count(raw)
  let r4 = @dx12.dx_d3d12_device4_get_device_removed_reason(raw)
  let h4 = @dx12.dx_d3d12_device4_check_feature_support(raw, 1, @dx12.int32_ptr(arch_buf), 16)
  ok = ok && n4 >= 1 && r4 == 0 && h4 == 0
  probed = probed + 3

  let n5 = @dx12.dx_d3d12_device5_get_node_count(raw)
  let r5 = @dx12.dx_d3d12_device5_get_device_removed_reason(raw)
  let h5 = @dx12.dx_d3d12_device5_check_feature_support(raw, 1, @dx12.int32_ptr(arch_buf), 16)
  ok = ok && n5 >= 1 && r5 == 0 && h5 == 0
  probed = probed + 3

  let n6 = @dx12.dx_d3d12_device6_get_node_count(raw)
  let r6 = @dx12.dx_d3d12_device6_get_device_removed_reason(raw)
  let h6 = @dx12.dx_d3d12_device6_check_feature_support(raw, 1, @dx12.int32_ptr(arch_buf), 16)
  ok = ok && n6 >= 1 && r6 == 0 && h6 == 0
  probed = probed + 3

  let n7 = @dx12.dx_d3d12_device7_get_node_count(raw)
  let r7 = @dx12.dx_d3d12_device7_get_device_removed_reason(raw)
  let h7 = @dx12.dx_d3d12_device7_check_feature_support(raw, 1, @dx12.int32_ptr(arch_buf), 16)
  ok = ok && n7 >= 1 && r7 == 0 && h7 == 0
  probed = probed + 3

  let n8 = @dx12.dx_d3d12_device8_get_node_count(raw)
  let r8 = @dx12.dx_d3d12_device8_get_device_removed_reason(raw)
  let h8 = @dx12.dx_d3d12_device8_check_feature_support(raw, 1, @dx12.int32_ptr(arch_buf), 16)
  ok = ok && n8 >= 1 && r8 == 0 && h8 == 0
  probed = probed + 3

  let n9 = @dx12.dx_d3d12_device9_get_node_count(raw)
  let r9 = @dx12.dx_d3d12_device9_get_device_removed_reason(raw)
  let h9 = @dx12.dx_d3d12_device9_check_feature_support(raw, 1, @dx12.int32_ptr(arch_buf), 16)
  ok = ok && n9 >= 1 && r9 == 0 && h9 == 0
  probed = probed + 3

  let n10 = @dx12.dx_d3d12_device10_get_node_count(raw)
  let r10 = @dx12.dx_d3d12_device10_get_device_removed_reason(raw)
  let h10 = @dx12.dx_d3d12_device10_check_feature_support(raw, 1, @dx12.int32_ptr(arch_buf), 16)
  ok = ok && n10 >= 1 && r10 == 0 && h10 == 0
  probed = probed + 3

  let n11 = @dx12.dx_d3d12_device11_get_node_count(raw)
  let r11 = @dx12.dx_d3d12_device11_get_device_removed_reason(raw)
  let h11 = @dx12.dx_d3d12_device11_check_feature_support(raw, 1, @dx12.int32_ptr(arch_buf), 16)
  ok = ok && n11 >= 1 && r11 == 0 && h11 == 0
  probed = probed + 3

  let n12 = @dx12.dx_d3d12_device12_get_node_count(raw)
  let r12 = @dx12.dx_d3d12_device12_get_device_removed_reason(raw)
  let h12 = @dx12.dx_d3d12_device12_check_feature_support(raw, 1, @dx12.int32_ptr(arch_buf), 16)
  ok = ok && n12 >= 1 && r12 == 0 && h12 == 0
  probed = probed + 3

  let n13 = @dx12.dx_d3d12_device13_get_node_count(raw)
  let r13 = @dx12.dx_d3d12_device13_get_device_removed_reason(raw)
  let h13 = @dx12.dx_d3d12_device13_check_feature_support(raw, 1, @dx12.int32_ptr(arch_buf), 16)
  ok = ok && n13 >= 1 && r13 == 0 && h13 == 0
  probed = probed + 3

  let n14 = @dx12.dx_d3d12_device14_get_node_count(raw)
  let r14 = @dx12.dx_d3d12_device14_get_device_removed_reason(raw)
  let h14 = @dx12.dx_d3d12_device14_check_feature_support(raw, 1, @dx12.int32_ptr(arch_buf), 16)
  ok = ok && n14 >= 1 && r14 == 0 && h14 == 0
  probed = probed + 3

  let errs = device.validation_errors()
  let adapter = if device.is_warp() { "warp" } else { "hardware" }
  device.destroy()
  if ok && errs == 0 {
    println(
      "[dx12/raw-interfaces] OK — commands=\{probed} generated COM calls verified (adapter=\{adapter}, ID3D12Device1..14 interface chain bindings), 0 validation errors",
    )
  } else {
    println("[dx12/raw-interfaces] FAIL — ok=\{ok} errs=\{errs} commands=\{probed}")
  }
}
