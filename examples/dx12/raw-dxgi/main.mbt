// dx12/raw-dxgi — exercises the generated DXGI dispatch thunks and free dxgi.dll
// entry points across IDXGIObject, IDXGIFactory0..7, IDXGIAdapter0..4,
// IDXGIOutput0..6, IDXGISwapChain0..4, and IDXGIDisplayControl.
// Non-Windows hosts SKIP cleanly.

///|
fn main {
  if !@dx12.available() {
    println("[dx12/raw-dxgi] SKIP — d3d12.dll / dxgi.dll not loadable on this host")
    return
  }
  let device = match @dx12.Device::create(warp=@dx12.env_requests_warp(), debug=true) {
    Some(d) => d
    None =>
      match @dx12.Device::create(warp=true, debug=true) {
        Some(d) => d
        None => {
          println("[dx12/raw-dxgi] FAIL — no D3D12 device")
          return
        }
      }
  }
  let raw_dev = device.raw()
  let probed : Ref[Int] = Ref(0)
  let mut ok = true

  // --- 1. Free dxgi.dll entry points ---
  let out_ptr = @dx12.raw_alloc(16)
  let _ = @dx12.dxgi_declare_adapter_removal_support()
  probed.val = probed.val + 1

  if @dx12.create_dxgi_factory(@dx12.bytes_ptr(@dx12.iid_dxgi_factory), out_ptr) == 0 {
    let f = @dx12.read_u64(out_ptr, 0)
    if f != (0 : UInt64) { let _ = @dx12.com_release(f) }
    probed.val = probed.val + 1
  }
  if @dx12.create_dxgi_factory1(@dx12.bytes_ptr(@dx12.iid_dxgi_factory1), out_ptr) == 0 {
    let f = @dx12.read_u64(out_ptr, 0)
    if f != (0 : UInt64) { let _ = @dx12.com_release(f) }
    probed.val = probed.val + 1
  }
  if @dx12.dxgi_get_debug_interface1(0, @dx12.bytes_ptr(@dx12.iid_iunknown), out_ptr) == 0 {
    let d = @dx12.read_u64(out_ptr, 0)
    if d != (0 : UInt64) { let _ = @dx12.com_release(d) }
    probed.val = probed.val + 1
  }
  @dx12.write_u64(out_ptr, 0, (0 : UInt64))
  let hr_f2 = @dx12.create_dxgi_factory2(0, @dx12.bytes_ptr(@dx12.iid_dxgi_factory2), out_ptr)
  let fac_base = @dx12.read_u64(out_ptr, 0)
  if hr_f2 != 0 || fac_base == (0 : UInt64) {
    @dx12.raw_free(out_ptr)
    device.destroy()
    println("[dx12/raw-dxgi] FAIL — CreateDXGIFactory2 failed (hr=\{hr_f2})")
    return
  }
  probed.val = probed.val + 1

  let scratch = @dx12.raw_alloc(16384)
  let priv_guid = @dx12.bytes_ptr(@dx12.iid_dxgi_object)
  let priv_val = @dx12.raw_alloc(16)
  @dx12.write_u32(priv_val, 0, (123 : UInt32))
  let priv_sz = @dx12.raw_alloc(8)
  let hwnd_out = @dx12.raw_alloc(8)
  let luid_ptr = @dx12.raw_alloc(16)
  let cookie = @dx12.raw_alloc(8)
  let allow_tearing = @dx12.raw_alloc(8)
  let _ = @dx12.dx_d3d12_device_get_adapter_luid(raw_dev, luid_ptr)

  // --- 2. Create a hidden Win32 window + DIRECT command queue for swapchain tests ---
  let mut win : UInt64 = (0 : UInt64)
  let mut hwnd : UInt64 = (0 : UInt64)
  if @win.initialize() != 0 {
    win = @win.create(64, 64, "tycho raw-dxgi")
    if win != (0 : UInt64) {
      hwnd = @win.native_handle(win)
    }
  }
  let q_desc = @dx12.raw_alloc(16) // DIRECT = 0
  @dx12.write_u64(out_ptr, 0, (0 : UInt64))
  let hr_q = @dx12.dx_d3d12_device_create_command_queue(
    raw_dev, q_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_command_queue), out_ptr,
  )
  let queue = @dx12.read_u64(out_ptr, 0)
  ok = ok && hr_q == 0 && queue != (0 : UInt64)

  // --- 3. IDXGIObject + IDXGIFactory0..7 + IDXGIDisplayControl ---
  // IDXGIFactory2 inherits from IDXGIFactory1 -> IDXGIFactory -> IDXGIObject.
  let qi_iids : Array[FixedArray[Byte]] = [
    @dx12.iid_dxgi_factory,
    @dx12.iid_dxgi_factory1,
    @dx12.iid_dxgi_factory2,
    @dx12.iid_dxgi_factory3,
    @dx12.iid_dxgi_factory4,
    @dx12.iid_dxgi_factory5,
    @dx12.iid_dxgi_factory6,
    @dx12.iid_dxgi_factory7,
  ]
  let ifs : Array[UInt64] = Array::make(8, (0 : UInt64))
  for i = 0; i < 8; i = i + 1 {
    @dx12.write_u64(out_ptr, 0, (0 : UInt64))
    if @dx12.com_query_interface(fac_base, @dx12.bytes_ptr(qi_iids[i]), out_ptr) == 0 {
      ifs[i] = @dx12.read_u64(out_ptr, 0)
    }
  }

  // IDXGIObject directly on fac_base.
  let _ = @dx12.dx_dxgi_object_set_private_data(fac_base, priv_guid, 4, priv_val)
  @dx12.write_u32(priv_sz, 0, (4 : UInt32))
  let _ = @dx12.dx_dxgi_object_get_private_data(fac_base, priv_guid, priv_sz, scratch)
  let _ = @dx12.dx_dxgi_object_set_private_data_interface(fac_base, priv_guid, (0 : UInt64))
  @dx12.write_u64(out_ptr, 0, (0 : UInt64))
  let _ = @dx12.dx_dxgi_object_get_parent(fac_base, @dx12.bytes_ptr(@dx12.iid_iunknown), out_ptr)
  probed.val = probed.val + 4

  // IDXGIDisplayControl (optional on factory).
  @dx12.write_u64(out_ptr, 0, (0 : UInt64))
  if @dx12.com_query_interface(fac_base, @dx12.bytes_ptr(@dx12.iid_dxgi_display_control), out_ptr) == 0 {
    let dc = @dx12.read_u64(out_ptr, 0)
    if dc != (0 : UInt64) {
      let _ = @dx12.dx_dxgi_display_control_is_stereo_enabled(dc)
      let _ = @dx12.com_release(dc)
      probed.val = probed.val + 1
    }
  }

  let ev = @dx12.create_event()

  if ifs[0] != (0 : UInt64) {
    let f = ifs[0]
    let _ = @dx12.dx_dxgi_factory_set_private_data(f, priv_guid, 4, priv_val)
    @dx12.write_u32(priv_sz, 0, (4 : UInt32))
    let _ = @dx12.dx_dxgi_factory_get_private_data(f, priv_guid, priv_sz, scratch)
    let _ = @dx12.dx_dxgi_factory_set_private_data_interface(f, priv_guid, (0 : UInt64))
    @dx12.write_u64(out_ptr, 0, (0 : UInt64))
    let _ = @dx12.dx_dxgi_factory_get_parent(f, @dx12.bytes_ptr(@dx12.iid_iunknown), out_ptr)
    if hwnd != (0 : UInt64) {
      let _ = @dx12.dx_dxgi_factory_make_window_association(f, hwnd, 0)
      let _ = @dx12.dx_dxgi_factory_get_window_association(f, hwnd_out)
    }
    @dx12.write_u64(out_ptr, 0, (0 : UInt64))
    if @dx12.dx_dxgi_factory_enum_adapters(f, 0, out_ptr) == 0 {
      let a = @dx12.read_u64(out_ptr, 0)
      if a != (0 : UInt64) {
        probe_adapter_chain(a, raw_dev, scratch, [], probed)
        let _ = @dx12.com_release(a)
      }
    }
    probed.val = probed.val + 7
  }

  if ifs[1] != (0 : UInt64) {
    let f = ifs[1]
    let _ = @dx12.dx_dxgi_factory1_set_private_data(f, priv_guid, 4, priv_val)
    @dx12.write_u32(priv_sz, 0, (4 : UInt32))
    let _ = @dx12.dx_dxgi_factory1_get_private_data(f, priv_guid, priv_sz, scratch)
    let _ = @dx12.dx_dxgi_factory1_set_private_data_interface(f, priv_guid, (0 : UInt64))
    @dx12.write_u64(out_ptr, 0, (0 : UInt64))
    let _ = @dx12.dx_dxgi_factory1_get_parent(f, @dx12.bytes_ptr(@dx12.iid_iunknown), out_ptr)
    if hwnd != (0 : UInt64) {
      let _ = @dx12.dx_dxgi_factory1_make_window_association(f, hwnd, 0)
      let _ = @dx12.dx_dxgi_factory1_get_window_association(f, hwnd_out)
    }
    @dx12.write_u64(out_ptr, 0, (0 : UInt64))
    if @dx12.dx_dxgi_factory1_enum_adapters(f, 0, out_ptr) == 0 {
      let a = @dx12.read_u64(out_ptr, 0)
      if a != (0 : UInt64) { let _ = @dx12.com_release(a) }
    }
    @dx12.write_u64(out_ptr, 0, (0 : UInt64))
    if @dx12.dx_dxgi_factory1_enum_adapters1(f, 0, out_ptr) == 0 {
      let a = @dx12.read_u64(out_ptr, 0)
      if a != (0 : UInt64) { let _ = @dx12.com_release(a) }
    }
    let _ = @dx12.dx_dxgi_factory1_is_current(f)
    probed.val = probed.val + 9
  }

  if ifs[2] != (0 : UInt64) {
    let f = ifs[2]
    let _ = @dx12.dx_dxgi_factory2_set_private_data(f, priv_guid, 4, priv_val)
    @dx12.write_u32(priv_sz, 0, (4 : UInt32))
    let _ = @dx12.dx_dxgi_factory2_get_private_data(f, priv_guid, priv_sz, scratch)
    let _ = @dx12.dx_dxgi_factory2_set_private_data_interface(f, priv_guid, (0 : UInt64))
    @dx12.write_u64(out_ptr, 0, (0 : UInt64))
    let _ = @dx12.dx_dxgi_factory2_get_parent(f, @dx12.bytes_ptr(@dx12.iid_iunknown), out_ptr)
    if hwnd != (0 : UInt64) {
      let _ = @dx12.dx_dxgi_factory2_make_window_association(f, hwnd, 0)
      let _ = @dx12.dx_dxgi_factory2_get_window_association(f, hwnd_out)
    }
    @dx12.write_u64(out_ptr, 0, (0 : UInt64))
    if @dx12.dx_dxgi_factory2_enum_adapters(f, 0, out_ptr) == 0 {
      let a = @dx12.read_u64(out_ptr, 0)
      if a != (0 : UInt64) { let _ = @dx12.com_release(a) }
    }
    @dx12.write_u64(out_ptr, 0, (0 : UInt64))
    if @dx12.dx_dxgi_factory2_enum_adapters1(f, 0, out_ptr) == 0 {
      let a = @dx12.read_u64(out_ptr, 0)
      if a != (0 : UInt64) { let _ = @dx12.com_release(a) }
    }
    let _ = @dx12.dx_dxgi_factory2_is_current(f)
    let _ = @dx12.dx_dxgi_factory2_is_windowed_stereo_enabled(f)
    if @dx12.dx_dxgi_factory2_register_stereo_status_event(f, ev, cookie) == 0 {
      @dx12.dx_dxgi_factory2_unregister_stereo_status(f, @dx12.read_u32(cookie, 0).reinterpret_as_int())
      probed.val = probed.val + 1
    }
    if @dx12.dx_dxgi_factory2_register_occlusion_status_event(f, ev, cookie) == 0 {
      @dx12.dx_dxgi_factory2_unregister_occlusion_status(f, @dx12.read_u32(cookie, 0).reinterpret_as_int())
      probed.val = probed.val + 1
    }
    if hwnd != (0 : UInt64) {
      if @dx12.dx_dxgi_factory2_register_stereo_status_window(f, hwnd, 0x0401, cookie) == 0 {
        @dx12.dx_dxgi_factory2_unregister_stereo_status(f, @dx12.read_u32(cookie, 0).reinterpret_as_int())
      }
      if @dx12.dx_dxgi_factory2_register_occlusion_status_window(f, hwnd, 0x0402, cookie) == 0 {
        @dx12.dx_dxgi_factory2_unregister_occlusion_status(f, @dx12.read_u32(cookie, 0).reinterpret_as_int())
      }
    }
    probed.val = probed.val + 10
  }

  if ifs[3] != (0 : UInt64) {
    let f = ifs[3]
    let _ = @dx12.dx_dxgi_factory3_set_private_data(f, priv_guid, 4, priv_val)
    @dx12.write_u32(priv_sz, 0, (4 : UInt32))
    let _ = @dx12.dx_dxgi_factory3_get_private_data(f, priv_guid, priv_sz, scratch)
    let _ = @dx12.dx_dxgi_factory3_set_private_data_interface(f, priv_guid, (0 : UInt64))
    @dx12.write_u64(out_ptr, 0, (0 : UInt64))
    let _ = @dx12.dx_dxgi_factory3_get_parent(f, @dx12.bytes_ptr(@dx12.iid_iunknown), out_ptr)
    if hwnd != (0 : UInt64) {
      let _ = @dx12.dx_dxgi_factory3_make_window_association(f, hwnd, 0)
      let _ = @dx12.dx_dxgi_factory3_get_window_association(f, hwnd_out)
    }
    @dx12.write_u64(out_ptr, 0, (0 : UInt64))
    if @dx12.dx_dxgi_factory3_enum_adapters(f, 0, out_ptr) == 0 {
      let a = @dx12.read_u64(out_ptr, 0)
      if a != (0 : UInt64) { let _ = @dx12.com_release(a) }
    }
    @dx12.write_u64(out_ptr, 0, (0 : UInt64))
    if @dx12.dx_dxgi_factory3_enum_adapters1(f, 0, out_ptr) == 0 {
      let a = @dx12.read_u64(out_ptr, 0)
      if a != (0 : UInt64) { let _ = @dx12.com_release(a) }
    }
    let _ = @dx12.dx_dxgi_factory3_is_current(f)
    let _ = @dx12.dx_dxgi_factory3_is_windowed_stereo_enabled(f)
    let _ = @dx12.dx_dxgi_factory3_get_creation_flags(f)
    if @dx12.dx_dxgi_factory3_register_stereo_status_event(f, ev, cookie) == 0 {
      @dx12.dx_dxgi_factory3_unregister_stereo_status(f, @dx12.read_u32(cookie, 0).reinterpret_as_int())
    }
    if @dx12.dx_dxgi_factory3_register_occlusion_status_event(f, ev, cookie) == 0 {
      @dx12.dx_dxgi_factory3_unregister_occlusion_status(f, @dx12.read_u32(cookie, 0).reinterpret_as_int())
    }
    if hwnd != (0 : UInt64) {
      if @dx12.dx_dxgi_factory3_register_stereo_status_window(f, hwnd, 0x0403, cookie) == 0 {
        @dx12.dx_dxgi_factory3_unregister_stereo_status(f, @dx12.read_u32(cookie, 0).reinterpret_as_int())
      }
      if @dx12.dx_dxgi_factory3_register_occlusion_status_window(f, hwnd, 0x0404, cookie) == 0 {
        @dx12.dx_dxgi_factory3_unregister_occlusion_status(f, @dx12.read_u32(cookie, 0).reinterpret_as_int())
      }
    }
    probed.val = probed.val + 15
  }

  if ifs[4] != (0 : UInt64) {
    let f = ifs[4]
    let _ = @dx12.dx_dxgi_factory4_set_private_data(f, priv_guid, 4, priv_val)
    @dx12.write_u32(priv_sz, 0, (4 : UInt32))
    let _ = @dx12.dx_dxgi_factory4_get_private_data(f, priv_guid, priv_sz, scratch)
    let _ = @dx12.dx_dxgi_factory4_set_private_data_interface(f, priv_guid, (0 : UInt64))
    @dx12.write_u64(out_ptr, 0, (0 : UInt64))
    let _ = @dx12.dx_dxgi_factory4_get_parent(f, @dx12.bytes_ptr(@dx12.iid_iunknown), out_ptr)
    if hwnd != (0 : UInt64) {
      let _ = @dx12.dx_dxgi_factory4_make_window_association(f, hwnd, 0)
      let _ = @dx12.dx_dxgi_factory4_get_window_association(f, hwnd_out)
    }
    @dx12.write_u64(out_ptr, 0, (0 : UInt64))
    if @dx12.dx_dxgi_factory4_enum_adapters(f, 0, out_ptr) == 0 {
      let a = @dx12.read_u64(out_ptr, 0)
      if a != (0 : UInt64) { let _ = @dx12.com_release(a) }
    }
    @dx12.write_u64(out_ptr, 0, (0 : UInt64))
    if @dx12.dx_dxgi_factory4_enum_adapters1(f, 0, out_ptr) == 0 {
      let a = @dx12.read_u64(out_ptr, 0)
      if a != (0 : UInt64) { let _ = @dx12.com_release(a) }
    }
    let _ = @dx12.dx_dxgi_factory4_is_current(f)
    let _ = @dx12.dx_dxgi_factory4_is_windowed_stereo_enabled(f)
    let _ = @dx12.dx_dxgi_factory4_get_creation_flags(f)
    @dx12.write_u64(out_ptr, 0, (0 : UInt64))
    if @dx12.dx_dxgi_factory4_enum_adapter_by_luid(f, luid_ptr, @dx12.bytes_ptr(@dx12.iid_dxgi_adapter1), out_ptr) == 0 {
      let a = @dx12.read_u64(out_ptr, 0)
      if a != (0 : UInt64) { let _ = @dx12.com_release(a) }
    }
    @dx12.write_u64(out_ptr, 0, (0 : UInt64))
    if @dx12.dx_dxgi_factory4_enum_warp_adapter(f, @dx12.bytes_ptr(@dx12.iid_dxgi_adapter1), out_ptr) == 0 {
      let a = @dx12.read_u64(out_ptr, 0)
      if a != (0 : UInt64) { let _ = @dx12.com_release(a) }
    }
    if @dx12.dx_dxgi_factory4_register_stereo_status_event(f, ev, cookie) == 0 {
      @dx12.dx_dxgi_factory4_unregister_stereo_status(f, @dx12.read_u32(cookie, 0).reinterpret_as_int())
    }
    if @dx12.dx_dxgi_factory4_register_occlusion_status_event(f, ev, cookie) == 0 {
      @dx12.dx_dxgi_factory4_unregister_occlusion_status(f, @dx12.read_u32(cookie, 0).reinterpret_as_int())
    }
    if hwnd != (0 : UInt64) {
      if @dx12.dx_dxgi_factory4_register_stereo_status_window(f, hwnd, 0x0405, cookie) == 0 {
        @dx12.dx_dxgi_factory4_unregister_stereo_status(f, @dx12.read_u32(cookie, 0).reinterpret_as_int())
      }
      if @dx12.dx_dxgi_factory4_register_occlusion_status_window(f, hwnd, 0x0406, cookie) == 0 {
        @dx12.dx_dxgi_factory4_unregister_occlusion_status(f, @dx12.read_u32(cookie, 0).reinterpret_as_int())
      }
    }
    probed.val = probed.val + 17
  }

  if ifs[5] != (0 : UInt64) {
    let f = ifs[5]
    let _ = @dx12.dx_dxgi_factory5_set_private_data(f, priv_guid, 4, priv_val)
    @dx12.write_u32(priv_sz, 0, (4 : UInt32))
    let _ = @dx12.dx_dxgi_factory5_get_private_data(f, priv_guid, priv_sz, scratch)
    let _ = @dx12.dx_dxgi_factory5_set_private_data_interface(f, priv_guid, (0 : UInt64))
    @dx12.write_u64(out_ptr, 0, (0 : UInt64))
    let _ = @dx12.dx_dxgi_factory5_get_parent(f, @dx12.bytes_ptr(@dx12.iid_iunknown), out_ptr)
    if hwnd != (0 : UInt64) {
      let _ = @dx12.dx_dxgi_factory5_make_window_association(f, hwnd, 0)
      let _ = @dx12.dx_dxgi_factory5_get_window_association(f, hwnd_out)
    }
    @dx12.write_u64(out_ptr, 0, (0 : UInt64))
    if @dx12.dx_dxgi_factory5_enum_adapters(f, 0, out_ptr) == 0 {
      let a = @dx12.read_u64(out_ptr, 0)
      if a != (0 : UInt64) { let _ = @dx12.com_release(a) }
    }
    @dx12.write_u64(out_ptr, 0, (0 : UInt64))
    if @dx12.dx_dxgi_factory5_enum_adapters1(f, 0, out_ptr) == 0 {
      let a = @dx12.read_u64(out_ptr, 0)
      if a != (0 : UInt64) { let _ = @dx12.com_release(a) }
    }
    let _ = @dx12.dx_dxgi_factory5_is_current(f)
    let _ = @dx12.dx_dxgi_factory5_is_windowed_stereo_enabled(f)
    let _ = @dx12.dx_dxgi_factory5_get_creation_flags(f)
    @dx12.write_u64(out_ptr, 0, (0 : UInt64))
    if @dx12.dx_dxgi_factory5_enum_adapter_by_luid(f, luid_ptr, @dx12.bytes_ptr(@dx12.iid_dxgi_adapter1), out_ptr) == 0 {
      let a = @dx12.read_u64(out_ptr, 0)
      if a != (0 : UInt64) { let _ = @dx12.com_release(a) }
    }
    @dx12.write_u64(out_ptr, 0, (0 : UInt64))
    if @dx12.dx_dxgi_factory5_enum_warp_adapter(f, @dx12.bytes_ptr(@dx12.iid_dxgi_adapter1), out_ptr) == 0 {
      let a = @dx12.read_u64(out_ptr, 0)
      if a != (0 : UInt64) { let _ = @dx12.com_release(a) }
    }
    let _ = @dx12.dx_dxgi_factory5_check_feature_support(f, 0, allow_tearing, 4)
    if @dx12.dx_dxgi_factory5_register_stereo_status_event(f, ev, cookie) == 0 {
      @dx12.dx_dxgi_factory5_unregister_stereo_status(f, @dx12.read_u32(cookie, 0).reinterpret_as_int())
    }
    if @dx12.dx_dxgi_factory5_register_occlusion_status_event(f, ev, cookie) == 0 {
      @dx12.dx_dxgi_factory5_unregister_occlusion_status(f, @dx12.read_u32(cookie, 0).reinterpret_as_int())
    }
    if hwnd != (0 : UInt64) {
      if @dx12.dx_dxgi_factory5_register_stereo_status_window(f, hwnd, 0x0407, cookie) == 0 {
        @dx12.dx_dxgi_factory5_unregister_stereo_status(f, @dx12.read_u32(cookie, 0).reinterpret_as_int())
      }
      if @dx12.dx_dxgi_factory5_register_occlusion_status_window(f, hwnd, 0x0408, cookie) == 0 {
        @dx12.dx_dxgi_factory5_unregister_occlusion_status(f, @dx12.read_u32(cookie, 0).reinterpret_as_int())
      }
    }
    probed.val = probed.val + 18
  }

  if ifs[6] != (0 : UInt64) {
    let f = ifs[6]
    let _ = @dx12.dx_dxgi_factory6_set_private_data(f, priv_guid, 4, priv_val)
    @dx12.write_u32(priv_sz, 0, (4 : UInt32))
    let _ = @dx12.dx_dxgi_factory6_get_private_data(f, priv_guid, priv_sz, scratch)
    let _ = @dx12.dx_dxgi_factory6_set_private_data_interface(f, priv_guid, (0 : UInt64))
    @dx12.write_u64(out_ptr, 0, (0 : UInt64))
    let _ = @dx12.dx_dxgi_factory6_get_parent(f, @dx12.bytes_ptr(@dx12.iid_iunknown), out_ptr)
    if hwnd != (0 : UInt64) {
      let _ = @dx12.dx_dxgi_factory6_make_window_association(f, hwnd, 0)
      let _ = @dx12.dx_dxgi_factory6_get_window_association(f, hwnd_out)
    }
    @dx12.write_u64(out_ptr, 0, (0 : UInt64))
    if @dx12.dx_dxgi_factory6_enum_adapters(f, 0, out_ptr) == 0 {
      let a = @dx12.read_u64(out_ptr, 0)
      if a != (0 : UInt64) { let _ = @dx12.com_release(a) }
    }
    @dx12.write_u64(out_ptr, 0, (0 : UInt64))
    if @dx12.dx_dxgi_factory6_enum_adapters1(f, 0, out_ptr) == 0 {
      let a = @dx12.read_u64(out_ptr, 0)
      if a != (0 : UInt64) { let _ = @dx12.com_release(a) }
    }
    let _ = @dx12.dx_dxgi_factory6_is_current(f)
    let _ = @dx12.dx_dxgi_factory6_is_windowed_stereo_enabled(f)
    let _ = @dx12.dx_dxgi_factory6_get_creation_flags(f)
    @dx12.write_u64(out_ptr, 0, (0 : UInt64))
    if @dx12.dx_dxgi_factory6_enum_adapter_by_luid(f, luid_ptr, @dx12.bytes_ptr(@dx12.iid_dxgi_adapter1), out_ptr) == 0 {
      let a = @dx12.read_u64(out_ptr, 0)
      if a != (0 : UInt64) { let _ = @dx12.com_release(a) }
    }
    @dx12.write_u64(out_ptr, 0, (0 : UInt64))
    if @dx12.dx_dxgi_factory6_enum_warp_adapter(f, @dx12.bytes_ptr(@dx12.iid_dxgi_adapter1), out_ptr) == 0 {
      let a = @dx12.read_u64(out_ptr, 0)
      if a != (0 : UInt64) { let _ = @dx12.com_release(a) }
    }
    let _ = @dx12.dx_dxgi_factory6_check_feature_support(f, 0, allow_tearing, 4)
    @dx12.write_u64(out_ptr, 0, (0 : UInt64))
    if @dx12.dx_dxgi_factory6_enum_adapter_by_gpu_preference(f, 0, 2, @dx12.bytes_ptr(@dx12.iid_dxgi_adapter1), out_ptr) == 0 {
      let a = @dx12.read_u64(out_ptr, 0)
      if a != (0 : UInt64) { let _ = @dx12.com_release(a) }
    }
    if @dx12.dx_dxgi_factory6_register_stereo_status_event(f, ev, cookie) == 0 {
      @dx12.dx_dxgi_factory6_unregister_stereo_status(f, @dx12.read_u32(cookie, 0).reinterpret_as_int())
    }
    if @dx12.dx_dxgi_factory6_register_occlusion_status_event(f, ev, cookie) == 0 {
      @dx12.dx_dxgi_factory6_unregister_occlusion_status(f, @dx12.read_u32(cookie, 0).reinterpret_as_int())
    }
    if hwnd != (0 : UInt64) {
      if @dx12.dx_dxgi_factory6_register_stereo_status_window(f, hwnd, 0x0409, cookie) == 0 {
        @dx12.dx_dxgi_factory6_unregister_stereo_status(f, @dx12.read_u32(cookie, 0).reinterpret_as_int())
      }
      if @dx12.dx_dxgi_factory6_register_occlusion_status_window(f, hwnd, 0x040A, cookie) == 0 {
        @dx12.dx_dxgi_factory6_unregister_occlusion_status(f, @dx12.read_u32(cookie, 0).reinterpret_as_int())
      }
    }
    probed.val = probed.val + 19
  }

  if ifs[7] != (0 : UInt64) {
    let f = ifs[7]
    let _ = @dx12.dx_dxgi_factory7_set_private_data(f, priv_guid, 4, priv_val)
    @dx12.write_u32(priv_sz, 0, (4 : UInt32))
    let _ = @dx12.dx_dxgi_factory7_get_private_data(f, priv_guid, priv_sz, scratch)
    let _ = @dx12.dx_dxgi_factory7_set_private_data_interface(f, priv_guid, (0 : UInt64))
    @dx12.write_u64(out_ptr, 0, (0 : UInt64))
    let _ = @dx12.dx_dxgi_factory7_get_parent(f, @dx12.bytes_ptr(@dx12.iid_iunknown), out_ptr)
    if hwnd != (0 : UInt64) {
      let _ = @dx12.dx_dxgi_factory7_make_window_association(f, hwnd, 0)
      let _ = @dx12.dx_dxgi_factory7_get_window_association(f, hwnd_out)
    }
    @dx12.write_u64(out_ptr, 0, (0 : UInt64))
    if @dx12.dx_dxgi_factory7_enum_adapters(f, 0, out_ptr) == 0 {
      let a = @dx12.read_u64(out_ptr, 0)
      if a != (0 : UInt64) { let _ = @dx12.com_release(a) }
    }
    @dx12.write_u64(out_ptr, 0, (0 : UInt64))
    if @dx12.dx_dxgi_factory7_enum_adapters1(f, 0, out_ptr) == 0 {
      let a = @dx12.read_u64(out_ptr, 0)
      if a != (0 : UInt64) { let _ = @dx12.com_release(a) }
    }
    let _ = @dx12.dx_dxgi_factory7_is_current(f)
    let _ = @dx12.dx_dxgi_factory7_is_windowed_stereo_enabled(f)
    let _ = @dx12.dx_dxgi_factory7_get_creation_flags(f)
    @dx12.write_u64(out_ptr, 0, (0 : UInt64))
    if @dx12.dx_dxgi_factory7_enum_adapter_by_luid(f, luid_ptr, @dx12.bytes_ptr(@dx12.iid_dxgi_adapter1), out_ptr) == 0 {
      let a = @dx12.read_u64(out_ptr, 0)
      if a != (0 : UInt64) { let _ = @dx12.com_release(a) }
    }
    @dx12.write_u64(out_ptr, 0, (0 : UInt64))
    if @dx12.dx_dxgi_factory7_enum_warp_adapter(f, @dx12.bytes_ptr(@dx12.iid_dxgi_adapter1), out_ptr) == 0 {
      let a = @dx12.read_u64(out_ptr, 0)
      if a != (0 : UInt64) { let _ = @dx12.com_release(a) }
    }
    let _ = @dx12.dx_dxgi_factory7_check_feature_support(f, 0, allow_tearing, 4)
    @dx12.write_u64(out_ptr, 0, (0 : UInt64))
    if @dx12.dx_dxgi_factory7_enum_adapter_by_gpu_preference(f, 0, 2, @dx12.bytes_ptr(@dx12.iid_dxgi_adapter1), out_ptr) == 0 {
      let a = @dx12.read_u64(out_ptr, 0)
      if a != (0 : UInt64) { let _ = @dx12.com_release(a) }
    }
    if @dx12.dx_dxgi_factory7_register_adapters_changed_event(f, ev, cookie) == 0 {
      let _ = @dx12.dx_dxgi_factory7_unregister_adapters_changed_event(f, @dx12.read_u32(cookie, 0).reinterpret_as_int())
      probed.val = probed.val + 2
    }
    if @dx12.dx_dxgi_factory7_register_stereo_status_event(f, ev, cookie) == 0 {
      @dx12.dx_dxgi_factory7_unregister_stereo_status(f, @dx12.read_u32(cookie, 0).reinterpret_as_int())
    }
    if @dx12.dx_dxgi_factory7_register_occlusion_status_event(f, ev, cookie) == 0 {
      @dx12.dx_dxgi_factory7_unregister_occlusion_status(f, @dx12.read_u32(cookie, 0).reinterpret_as_int())
    }
    if hwnd != (0 : UInt64) {
      if @dx12.dx_dxgi_factory7_register_stereo_status_window(f, hwnd, 0x040B, cookie) == 0 {
        @dx12.dx_dxgi_factory7_unregister_stereo_status(f, @dx12.read_u32(cookie, 0).reinterpret_as_int())
      }
      if @dx12.dx_dxgi_factory7_register_occlusion_status_window(f, hwnd, 0x040C, cookie) == 0 {
        @dx12.dx_dxgi_factory7_unregister_occlusion_status(f, @dx12.read_u32(cookie, 0).reinterpret_as_int())
      }
    }
    probed.val = probed.val + 19
  }

  // --- 4. SwapChain creation + IDXGISwapChain0..4 ---
  let fence_ev = @dx12.create_event()
  @dx12.write_u64(out_ptr, 0, (0 : UInt64))
  let hr_fence = @dx12.dx_d3d12_device_create_fence(
    raw_dev, (0 : Int64), 0, @dx12.bytes_ptr(@dx12.iid_d3d12_fence), out_ptr,
  )
  let fence = @dx12.read_u64(out_ptr, 0)
  let fence_val : Ref[Int64] = Ref((0 : Int64))
  ok = ok && hr_fence == 0 && fence != (0 : UInt64)

  if hwnd != (0 : UInt64) && queue != (0 : UInt64) && fence != (0 : UInt64) {
    let sc_desc1 = @dx12.raw_alloc(48)
    @dx12.write_u32(sc_desc1, 0, (64 : UInt32)) // Width
    @dx12.write_u32(sc_desc1, 4, (64 : UInt32)) // Height
    @dx12.write_u32(sc_desc1, 8, (28 : UInt32)) // R8G8B8A8_UNORM
    @dx12.write_u32(sc_desc1, 16, (1 : UInt32)) // SampleDesc.Count
    @dx12.write_u32(sc_desc1, 24, (0x20 : UInt32)) // DXGI_USAGE_RENDER_TARGET_OUTPUT
    @dx12.write_u32(sc_desc1, 28, (3 : UInt32)) // BufferCount
    @dx12.write_u32(sc_desc1, 36, (4 : UInt32)) // DXGI_SWAP_EFFECT_FLIP_DISCARD
    @dx12.write_u32(sc_desc1, 40, (3 : UInt32)) // DXGI_ALPHA_MODE_IGNORE
    @dx12.write_u32(sc_desc1, 44, (0 : UInt32)) // Flags = 0
    @dx12.write_u64(out_ptr, 0, (0 : UInt64))
    let hr_sc = @dx12.dx_dxgi_factory2_create_swap_chain_for_hwnd(
      fac_base, queue, hwnd, sc_desc1, (0 : UInt64), (0 : UInt64), out_ptr,
    )
    probed.val = probed.val + 1
    let sc = @dx12.read_u64(out_ptr, 0)
    if hr_sc == 0 && sc != (0 : UInt64) {
      let _ = @dx12.dx_dxgi_factory2_make_window_association(fac_base, hwnd, 2)
      probe_swapchain_chain(sc, queue, fence, fence_ev, fence_val, scratch, probed)
      drain_dxgi_queue(queue, fence, fence_ev, fence_val)
      let _ = @dx12.com_release(sc)
    } else {
      ok = false
    }
    @dx12.raw_free(sc_desc1)
  }

  let _ = @dx12.dxgi_disable_vblank_virtualization()
  probed.val = probed.val + 1

  for i = 0; i < 8; i = i + 1 {
    if ifs[i] != (0 : UInt64) {
      let _ = @dx12.com_release(ifs[i])
    }
  }
  if queue != (0 : UInt64) {
    if fence != (0 : UInt64) {
      drain_dxgi_queue(queue, fence, fence_ev, fence_val)
      let _ = @dx12.com_release(fence)
    }
    let _ = @dx12.com_release(queue)
  }
  @dx12.close_handle(fence_ev)
  let _ = @dx12.com_release(fac_base)
  if win != (0 : UInt64) {
    @win.destroy(win)
  }
  @dx12.close_handle(ev)
  @dx12.raw_free(out_ptr)
  @dx12.raw_free(scratch)
  @dx12.raw_free(priv_val)
  @dx12.raw_free(priv_sz)
  @dx12.raw_free(hwnd_out)
  @dx12.raw_free(luid_ptr)
  @dx12.raw_free(cookie)
  @dx12.raw_free(allow_tearing)
  @dx12.raw_free(q_desc)

  let errs = device.validation_errors()
  let adapter = if device.is_warp() { "warp" } else { "hardware" }
  device.destroy()
  if ok && errs == 0 {
    println(
      "[dx12/raw-dxgi] OK — commands=\{probed.val} generated DXGI COM + free entry calls verified (adapter=\{adapter}), 0 validation errors",
    )
  } else {
    println("[dx12/raw-dxgi] FAIL — ok=\{ok} errs=\{errs} commands=\{probed.val}")
  }
}
