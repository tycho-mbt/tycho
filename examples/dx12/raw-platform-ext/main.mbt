// dx12/raw-platform-ext — DX12 counterpart of examples/vulkan/vendor-platform-ext.
// Live-probes optional/host-gated DX12 & DXGI interfaces and compile-verifies
// all remaining gated, D3D11-interop, PIX, and destructive COM/DLL thunks.
// Non-Windows hosts SKIP cleanly.

///|
fn main {
  if !@dx12.available() {
    println("[dx12/raw-platform-ext] SKIP — d3d12.dll / dxgi.dll not loadable on this host")
    return
  }
  let device = match @dx12.Device::create(warp=@dx12.env_requests_warp(), debug=true) {
    Some(d) => d
    None =>
      match @dx12.Device::create(warp=true, debug=true) {
        Some(d) => d
        None => {
          println("[dx12/raw-platform-ext] FAIL — no D3D12 device")
          return
        }
      }
  }
  let raw_dev = device.raw()
  let probed : Ref[Int] = Ref(0)
  let out_ptr = @dx12.raw_alloc(16)
  let scratch = @dx12.raw_alloc(4096)

  // --- 1. Live capability & optional interface probes ---
  // Protected Resource Session support (D3D12_FEATURE_PROTECTED_RESOURCE_SESSION_SUPPORT = 24)
  let _ = @dx12.dx_d3d12_device_check_feature_support(raw_dev, 24, scratch, 8)
  probed.val = probed.val + 1

  // DirectSR (DSR) DeviceFactory optional probe
  @dx12.write_u64(out_ptr, 0, (0 : UInt64))
  if @dx12.d3d12_get_interface(
      @dx12.bytes_ptr(@dx12.clsid_d3_d12_dsr_device_factory),
      @dx12.bytes_ptr(@dx12.iid_d3d12_dsr_device_factory),
      out_ptr,
    ) == 0 {
    let p = @dx12.read_u64(out_ptr, 0)
    if p != (0 : UInt64) { let _ = @dx12.com_release(p) }
  }
  probed.val = probed.val + 1

  // Optional device-level interfaces (VirtualizationGuestDevice, GBVDiagnostics, SwapChainAssistant)
  let opt_dev_iids : Array[FixedArray[Byte]] = [
    @dx12.iid_d3d12_virtualization_guest_device,
    @dx12.iid_d3d12_gbv_diagnostics,
    @dx12.iid_d3d12_swap_chain_assistant,
    @dx12.iid_d3d12_lifetime_tracker,
  ]
  for iid in opt_dev_iids {
    @dx12.write_u64(out_ptr, 0, (0 : UInt64))
    if @dx12.com_query_interface(raw_dev, @dx12.bytes_ptr(iid), out_ptr) == 0 {
      let p = @dx12.read_u64(out_ptr, 0)
      if p != (0 : UInt64) { let _ = @dx12.com_release(p) }
    }
    probed.val = probed.val + 1
  }

  // DXGI Factory Media + DXGI Device probes (D3D11/DXGI interop surfaces)
  @dx12.write_u64(out_ptr, 0, (0 : UInt64))
  if @dx12.create_dxgi_factory2(0, @dx12.bytes_ptr(@dx12.iid_dxgi_factory2), out_ptr) == 0 {
    let fac = @dx12.read_u64(out_ptr, 0)
    if fac != (0 : UInt64) {
      @dx12.write_u64(out_ptr, 0, (0 : UInt64))
      if @dx12.com_query_interface(fac, @dx12.bytes_ptr(@dx12.iid_dxgi_factory_media), out_ptr) == 0 {
        let fm = @dx12.read_u64(out_ptr, 0)
        if fm != (0 : UInt64) { let _ = @dx12.com_release(fm) }
      }
      probed.val = probed.val + 1
      let _ = @dx12.com_release(fac)
    }
  }

  // Optional ID3D12PageableTools on a small committed buffer
  let heap_def = @dx12.raw_alloc(32)
  @dx12.write_u32(heap_def, 0, (1 : UInt32))
  @dx12.write_u32(heap_def, 12, (1 : UInt32))
  @dx12.write_u32(heap_def, 16, (1 : UInt32))
  let buf_desc = @dx12.raw_alloc(64)
  @dx12.write_u32(buf_desc, 0, (1 : UInt32))
  @dx12.write_u64(buf_desc, 16, (256 : UInt64))
  @dx12.write_u32(buf_desc, 24, (1 : UInt32))
  @dx12.write_u32(buf_desc, 28, (0x00010001 : UInt32))
  @dx12.write_u32(buf_desc, 36, (1 : UInt32))
  @dx12.write_u32(buf_desc, 44, (1 : UInt32))
  @dx12.write_u64(out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device_create_committed_resource(
      raw_dev, heap_def, 0, buf_desc, 0, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), out_ptr,
    ) == 0 {
    let res = @dx12.read_u64(out_ptr, 0)
    if res != (0 : UInt64) {
      @dx12.write_u64(out_ptr, 0, (0 : UInt64))
      if @dx12.com_query_interface(res, @dx12.bytes_ptr(@dx12.iid_d3d12_pageable_tools), out_ptr) == 0 {
        let pt = @dx12.read_u64(out_ptr, 0)
        if pt != (0 : UInt64) {
          let _ = @dx12.dx_d3d12_pageable_tools_get_allocation(pt, scratch)
          let _ = @dx12.com_release(pt)
          probed.val = probed.val + 1
        }
      }
      for res_iid in [
        @dx12.iid_dxgi_resource,
        @dx12.iid_dxgi_resource1,
        @dx12.iid_dxgi_surface,
        @dx12.iid_dxgi_surface1,
        @dx12.iid_dxgi_surface2,
        @dx12.iid_dxgi_keyed_mutex,
        @dx12.iid_dxgi_device_sub_object,
      ] {
        @dx12.write_u64(out_ptr, 0, (0 : UInt64))
        if @dx12.com_query_interface(res, @dx12.bytes_ptr(res_iid), out_ptr) == 0 {
          let rp = @dx12.read_u64(out_ptr, 0)
          if rp != (0 : UInt64) { let _ = @dx12.com_release(rp) }
        }
        probed.val = probed.val + 1
      }
      let _ = @dx12.com_release(res)
    }
  }
  @dx12.raw_free(buf_desc)
  @dx12.raw_free(heap_def)

  // --- 2. Compile- and link-verify all remaining D3D12/DXGI surface ---
  // Runtime-false guard ensures MoonBit + MSVC type-check and link every
  // gated, D3D11-interop, PIX, and destructive thunk without executing it.
  if probed.val < 0 {
    typecheck_d3d12_unreached(probed)
    typecheck_dxgi_unreached(probed)
  }

  @dx12.raw_free(scratch)
  @dx12.raw_free(out_ptr)

  let errs = device.validation_errors()
  let adapter = if device.is_warp() { "warp" } else { "hardware" }
  device.destroy()
  if errs == 0 && probed.val > 0 {
    println(
      "[dx12/raw-platform-ext] OK — commands=\{probed.val} live optional probes + 100% static COM/DLL surface verified (adapter=\{adapter}), 0 validation errors",
    )
  } else {
    println("[dx12/raw-platform-ext] FAIL — errs=\{errs} commands=\{probed.val}")
  }
}
