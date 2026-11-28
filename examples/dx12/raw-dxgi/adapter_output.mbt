// Generated DXGI adapter & output raw-dispatch verification (IDXGIAdapter0..4, IDXGIOutput0..6).

///|
fn probe_adapter_chain(
  adapter_base : UInt64,
  d3d_dev : UInt64,
  scratch : UInt64,
  out_iids : Array[(UInt64, String)],
  probed : Ref[Int],
) -> Unit {
  let priv_guid = @dx12.bytes_ptr(@dx12.iid_dxgi_object)
  let priv_val = @dx12.raw_alloc(16)
  @dx12.write_u32(priv_val, 0, (42 : UInt32))
  let priv_sz = @dx12.raw_alloc(8)
  let out_ptr = @dx12.raw_alloc(16)
  let luid_ptr = @dx12.raw_alloc(16)
  let umd_ptr = @dx12.raw_alloc(16)

  // Query Adapter1..4 (Adapter0 is adapter_base).
  let qi_iids : Array[FixedArray[Byte]] = [
    @dx12.iid_dxgi_adapter,
    @dx12.iid_dxgi_adapter1,
    @dx12.iid_dxgi_adapter2,
    @dx12.iid_dxgi_adapter3,
    @dx12.iid_dxgi_adapter4,
  ]
  let ifs : Array[UInt64] = Array::make(5, (0 : UInt64))
  ifs[0] = adapter_base
  for i = 1; i < 5; i = i + 1 {
    @dx12.write_u64(out_ptr, 0, (0 : UInt64))
    let hr = @dx12.com_query_interface(adapter_base, @dx12.bytes_ptr(qi_iids[i]), out_ptr)
    if hr == 0 {
      ifs[i] = @dx12.read_u64(out_ptr, 0)
    }
  }

  let ev = @dx12.create_event()

  if ifs[0] != (0 : UInt64) {
    let a = ifs[0]
    let _ = @dx12.dx_dxgi_adapter_set_private_data(a, priv_guid, 4, priv_val)
    @dx12.write_u32(priv_sz, 0, (4 : UInt32))
    let _ = @dx12.dx_dxgi_adapter_get_private_data(a, priv_guid, priv_sz, scratch)
    let _ = @dx12.dx_dxgi_adapter_set_private_data_interface(a, priv_guid, (0 : UInt64))
    @dx12.write_u64(out_ptr, 0, (0 : UInt64))
    if @dx12.dx_dxgi_adapter_get_parent(a, @dx12.bytes_ptr(@dx12.iid_dxgi_factory), out_ptr) == 0 {
      let p = @dx12.read_u64(out_ptr, 0)
      if p != (0 : UInt64) { let _ = @dx12.com_release(p) }
    }
    let _ = @dx12.dx_dxgi_adapter_get_desc(a, scratch)
    let _ = @dx12.dx_dxgi_adapter_check_interface_support(a, @dx12.bytes_ptr(@dx12.iid_d3d12_device), umd_ptr)
    @dx12.write_u64(out_ptr, 0, (0 : UInt64))
    if @dx12.dx_dxgi_adapter_enum_outputs(a, 0, out_ptr) == 0 {
      let o = @dx12.read_u64(out_ptr, 0)
      if o != (0 : UInt64) {
        probe_output_chain(o, d3d_dev, scratch, out_iids, probed)
        let _ = @dx12.com_release(o)
      }
    }
    probed.val = probed.val + 7
  }

  if ifs[1] != (0 : UInt64) {
    let a = ifs[1]
    let _ = @dx12.dx_dxgi_adapter1_set_private_data(a, priv_guid, 4, priv_val)
    @dx12.write_u32(priv_sz, 0, (4 : UInt32))
    let _ = @dx12.dx_dxgi_adapter1_get_private_data(a, priv_guid, priv_sz, scratch)
    let _ = @dx12.dx_dxgi_adapter1_set_private_data_interface(a, priv_guid, (0 : UInt64))
    @dx12.write_u64(out_ptr, 0, (0 : UInt64))
    if @dx12.dx_dxgi_adapter1_get_parent(a, @dx12.bytes_ptr(@dx12.iid_dxgi_factory1), out_ptr) == 0 {
      let p = @dx12.read_u64(out_ptr, 0)
      if p != (0 : UInt64) { let _ = @dx12.com_release(p) }
    }
    let _ = @dx12.dx_dxgi_adapter1_get_desc(a, scratch)
    let _ = @dx12.dx_dxgi_adapter1_get_desc1(a, scratch)
    let _ = @dx12.dx_dxgi_adapter1_check_interface_support(a, @dx12.bytes_ptr(@dx12.iid_d3d12_device), umd_ptr)
    @dx12.write_u64(out_ptr, 0, (0 : UInt64))
    if @dx12.dx_dxgi_adapter1_enum_outputs(a, 0, out_ptr) == 0 {
      let o = @dx12.read_u64(out_ptr, 0)
      if o != (0 : UInt64) { let _ = @dx12.com_release(o) }
    }
    probed.val = probed.val + 8
  }

  if ifs[2] != (0 : UInt64) {
    let a = ifs[2]
    let _ = @dx12.dx_dxgi_adapter2_set_private_data(a, priv_guid, 4, priv_val)
    @dx12.write_u32(priv_sz, 0, (4 : UInt32))
    let _ = @dx12.dx_dxgi_adapter2_get_private_data(a, priv_guid, priv_sz, scratch)
    let _ = @dx12.dx_dxgi_adapter2_set_private_data_interface(a, priv_guid, (0 : UInt64))
    @dx12.write_u64(out_ptr, 0, (0 : UInt64))
    if @dx12.dx_dxgi_adapter2_get_parent(a, @dx12.bytes_ptr(@dx12.iid_dxgi_factory2), out_ptr) == 0 {
      let p = @dx12.read_u64(out_ptr, 0)
      if p != (0 : UInt64) { let _ = @dx12.com_release(p) }
    }
    let _ = @dx12.dx_dxgi_adapter2_get_desc(a, scratch)
    let _ = @dx12.dx_dxgi_adapter2_get_desc1(a, scratch)
    let _ = @dx12.dx_dxgi_adapter2_get_desc2(a, scratch)
    let _ = @dx12.dx_dxgi_adapter2_check_interface_support(a, @dx12.bytes_ptr(@dx12.iid_d3d12_device), umd_ptr)
    @dx12.write_u64(out_ptr, 0, (0 : UInt64))
    if @dx12.dx_dxgi_adapter2_enum_outputs(a, 0, out_ptr) == 0 {
      let o = @dx12.read_u64(out_ptr, 0)
      if o != (0 : UInt64) { let _ = @dx12.com_release(o) }
    }
    probed.val = probed.val + 9
  }

  if ifs[3] != (0 : UInt64) {
    let a = ifs[3]
    let _ = @dx12.dx_dxgi_adapter3_set_private_data(a, priv_guid, 4, priv_val)
    @dx12.write_u32(priv_sz, 0, (4 : UInt32))
    let _ = @dx12.dx_dxgi_adapter3_get_private_data(a, priv_guid, priv_sz, scratch)
    let _ = @dx12.dx_dxgi_adapter3_set_private_data_interface(a, priv_guid, (0 : UInt64))
    @dx12.write_u64(out_ptr, 0, (0 : UInt64))
    if @dx12.dx_dxgi_adapter3_get_parent(a, @dx12.bytes_ptr(@dx12.iid_dxgi_factory4), out_ptr) == 0 {
      let p = @dx12.read_u64(out_ptr, 0)
      if p != (0 : UInt64) { let _ = @dx12.com_release(p) }
    }
    let _ = @dx12.dx_dxgi_adapter3_get_desc(a, scratch)
    let _ = @dx12.dx_dxgi_adapter3_get_desc1(a, scratch)
    let _ = @dx12.dx_dxgi_adapter3_get_desc2(a, scratch)
    let _ = @dx12.dx_dxgi_adapter3_check_interface_support(a, @dx12.bytes_ptr(@dx12.iid_d3d12_device), umd_ptr)
    @dx12.write_u64(out_ptr, 0, (0 : UInt64))
    if @dx12.dx_dxgi_adapter3_enum_outputs(a, 0, out_ptr) == 0 {
      let o = @dx12.read_u64(out_ptr, 0)
      if o != (0 : UInt64) { let _ = @dx12.com_release(o) }
    }
    let _ = @dx12.dx_dxgi_adapter3_query_video_memory_info(a, 0, 0, scratch)
    let _ = @dx12.dx_dxgi_adapter3_set_video_memory_reservation(a, 0, 0, (0 : Int64))
    let cookie = @dx12.raw_alloc(8)
    if @dx12.dx_dxgi_adapter3_register_video_memory_budget_change_notification_event(a, ev, cookie) == 0 {
      @dx12.dx_dxgi_adapter3_unregister_video_memory_budget_change_notification(a, @dx12.read_u32(cookie, 0).reinterpret_as_int())
      probed.val = probed.val + 1
    }
    if @dx12.dx_dxgi_adapter3_register_hardware_content_protection_teardown_status_event(a, ev, cookie) == 0 {
      @dx12.dx_dxgi_adapter3_unregister_hardware_content_protection_teardown_status(a, @dx12.read_u32(cookie, 0).reinterpret_as_int())
      probed.val = probed.val + 1
    }
    @dx12.raw_free(cookie)
    probed.val = probed.val + 13
  }

  if ifs[4] != (0 : UInt64) {
    let a = ifs[4]
    let _ = @dx12.dx_dxgi_adapter4_set_private_data(a, priv_guid, 4, priv_val)
    @dx12.write_u32(priv_sz, 0, (4 : UInt32))
    let _ = @dx12.dx_dxgi_adapter4_get_private_data(a, priv_guid, priv_sz, scratch)
    let _ = @dx12.dx_dxgi_adapter4_set_private_data_interface(a, priv_guid, (0 : UInt64))
    @dx12.write_u64(out_ptr, 0, (0 : UInt64))
    if @dx12.dx_dxgi_adapter4_get_parent(a, @dx12.bytes_ptr(@dx12.iid_dxgi_factory4), out_ptr) == 0 {
      let p = @dx12.read_u64(out_ptr, 0)
      if p != (0 : UInt64) { let _ = @dx12.com_release(p) }
    }
    let _ = @dx12.dx_dxgi_adapter4_get_desc(a, scratch)
    let _ = @dx12.dx_dxgi_adapter4_get_desc1(a, scratch)
    let _ = @dx12.dx_dxgi_adapter4_get_desc2(a, scratch)
    let _ = @dx12.dx_dxgi_adapter4_get_desc3(a, scratch)
    let _ = @dx12.dx_dxgi_adapter4_check_interface_support(a, @dx12.bytes_ptr(@dx12.iid_d3d12_device), umd_ptr)
    @dx12.write_u64(out_ptr, 0, (0 : UInt64))
    if @dx12.dx_dxgi_adapter4_enum_outputs(a, 0, out_ptr) == 0 {
      let o = @dx12.read_u64(out_ptr, 0)
      if o != (0 : UInt64) { let _ = @dx12.com_release(o) }
    }
    let _ = @dx12.dx_dxgi_adapter4_query_video_memory_info(a, 0, 0, scratch)
    let _ = @dx12.dx_dxgi_adapter4_set_video_memory_reservation(a, 0, 0, (0 : Int64))
    let cookie = @dx12.raw_alloc(8)
    if @dx12.dx_dxgi_adapter4_register_video_memory_budget_change_notification_event(a, ev, cookie) == 0 {
      @dx12.dx_dxgi_adapter4_unregister_video_memory_budget_change_notification(a, @dx12.read_u32(cookie, 0).reinterpret_as_int())
      probed.val = probed.val + 1
    }
    if @dx12.dx_dxgi_adapter4_register_hardware_content_protection_teardown_status_event(a, ev, cookie) == 0 {
      @dx12.dx_dxgi_adapter4_unregister_hardware_content_protection_teardown_status(a, @dx12.read_u32(cookie, 0).reinterpret_as_int())
      probed.val = probed.val + 1
    }
    @dx12.raw_free(cookie)
    probed.val = probed.val + 14
  }

  for i = 1; i < 5; i = i + 1 {
    if ifs[i] != (0 : UInt64) {
      let _ = @dx12.com_release(ifs[i])
    }
  }
  @dx12.close_handle(ev)
  @dx12.raw_free(priv_val)
  @dx12.raw_free(priv_sz)
  @dx12.raw_free(out_ptr)
  @dx12.raw_free(luid_ptr)
  @dx12.raw_free(umd_ptr)
}

///|
fn probe_output_chain(
  output_base : UInt64,
  d3d_dev : UInt64,
  scratch : UInt64,
  _out_iids : Array[(UInt64, String)],
  probed : Ref[Int],
) -> Unit {
  let priv_guid = @dx12.bytes_ptr(@dx12.iid_dxgi_object)
  let priv_val = @dx12.raw_alloc(16)
  @dx12.write_u32(priv_val, 0, (77 : UInt32))
  let priv_sz = @dx12.raw_alloc(8)
  let out_ptr = @dx12.raw_alloc(16)
  let num_modes = @dx12.raw_alloc(8)
  let flags_out = @dx12.raw_alloc(8)
  let mode_in = @dx12.raw_alloc(48)
  @dx12.write_u32(mode_in, 0, (64 : UInt32))
  @dx12.write_u32(mode_in, 4, (64 : UInt32))
  @dx12.write_u32(mode_in, 16, (28 : UInt32)) // R8G8B8A8_UNORM

  let qi_iids : Array[FixedArray[Byte]] = [
    @dx12.iid_dxgi_output,
    @dx12.iid_dxgi_output1,
    @dx12.iid_dxgi_output2,
    @dx12.iid_dxgi_output3,
    @dx12.iid_dxgi_output4,
    @dx12.iid_dxgi_output5,
    @dx12.iid_dxgi_output6,
  ]
  let ifs : Array[UInt64] = Array::make(7, (0 : UInt64))
  ifs[0] = output_base
  for i = 1; i < 7; i = i + 1 {
    @dx12.write_u64(out_ptr, 0, (0 : UInt64))
    if @dx12.com_query_interface(output_base, @dx12.bytes_ptr(qi_iids[i]), out_ptr) == 0 {
      ifs[i] = @dx12.read_u64(out_ptr, 0)
    }
  }

  if ifs[0] != (0 : UInt64) {
    let o = ifs[0]
    let _ = @dx12.dx_dxgi_output_set_private_data(o, priv_guid, 4, priv_val)
    @dx12.write_u32(priv_sz, 0, (4 : UInt32))
    let _ = @dx12.dx_dxgi_output_get_private_data(o, priv_guid, priv_sz, scratch)
    let _ = @dx12.dx_dxgi_output_set_private_data_interface(o, priv_guid, (0 : UInt64))
    @dx12.write_u64(out_ptr, 0, (0 : UInt64))
    if @dx12.dx_dxgi_output_get_parent(o, @dx12.bytes_ptr(@dx12.iid_dxgi_adapter), out_ptr) == 0 {
      let p = @dx12.read_u64(out_ptr, 0)
      if p != (0 : UInt64) { let _ = @dx12.com_release(p) }
    }
    let _ = @dx12.dx_dxgi_output_get_desc(o, scratch)
    @dx12.write_u32(num_modes, 0, (0 : UInt32))
    let _ = @dx12.dx_dxgi_output_get_display_mode_list(o, 28, 0, num_modes, (0 : UInt64))
    let _ = @dx12.dx_dxgi_output_find_closest_matching_mode(o, mode_in, scratch, d3d_dev)
    let _ = @dx12.dx_dxgi_output_get_gamma_control_capabilities(o, scratch)
    let _ = @dx12.dx_dxgi_output_get_frame_statistics(o, scratch)
    probed.val = probed.val + 9
  }

  if ifs[1] != (0 : UInt64) {
    let o = ifs[1]
    let _ = @dx12.dx_dxgi_output1_set_private_data(o, priv_guid, 4, priv_val)
    @dx12.write_u32(priv_sz, 0, (4 : UInt32))
    let _ = @dx12.dx_dxgi_output1_get_private_data(o, priv_guid, priv_sz, scratch)
    let _ = @dx12.dx_dxgi_output1_set_private_data_interface(o, priv_guid, (0 : UInt64))
    @dx12.write_u64(out_ptr, 0, (0 : UInt64))
    if @dx12.dx_dxgi_output1_get_parent(o, @dx12.bytes_ptr(@dx12.iid_dxgi_adapter), out_ptr) == 0 {
      let p = @dx12.read_u64(out_ptr, 0)
      if p != (0 : UInt64) { let _ = @dx12.com_release(p) }
    }
    let _ = @dx12.dx_dxgi_output1_get_desc(o, scratch)
    @dx12.write_u32(num_modes, 0, (0 : UInt32))
    let _ = @dx12.dx_dxgi_output1_get_display_mode_list(o, 28, 0, num_modes, (0 : UInt64))
    let _ = @dx12.dx_dxgi_output1_find_closest_matching_mode(o, mode_in, scratch, d3d_dev)
    let _ = @dx12.dx_dxgi_output1_get_gamma_control_capabilities(o, scratch)
    let _ = @dx12.dx_dxgi_output1_get_frame_statistics(o, scratch)
    @dx12.write_u32(num_modes, 0, (0 : UInt32))
    let _ = @dx12.dx_dxgi_output1_get_display_mode_list1(o, 28, 0, num_modes, (0 : UInt64))
    let _ = @dx12.dx_dxgi_output1_find_closest_matching_mode1(o, mode_in, scratch, d3d_dev)
    probed.val = probed.val + 11
  }

  if ifs[2] != (0 : UInt64) {
    let o = ifs[2]
    let _ = @dx12.dx_dxgi_output2_set_private_data(o, priv_guid, 4, priv_val)
    @dx12.write_u32(priv_sz, 0, (4 : UInt32))
    let _ = @dx12.dx_dxgi_output2_get_private_data(o, priv_guid, priv_sz, scratch)
    let _ = @dx12.dx_dxgi_output2_set_private_data_interface(o, priv_guid, (0 : UInt64))
    @dx12.write_u64(out_ptr, 0, (0 : UInt64))
    if @dx12.dx_dxgi_output2_get_parent(o, @dx12.bytes_ptr(@dx12.iid_dxgi_adapter), out_ptr) == 0 {
      let p = @dx12.read_u64(out_ptr, 0)
      if p != (0 : UInt64) { let _ = @dx12.com_release(p) }
    }
    let _ = @dx12.dx_dxgi_output2_get_desc(o, scratch)
    @dx12.write_u32(num_modes, 0, (0 : UInt32))
    let _ = @dx12.dx_dxgi_output2_get_display_mode_list(o, 28, 0, num_modes, (0 : UInt64))
    let _ = @dx12.dx_dxgi_output2_find_closest_matching_mode(o, mode_in, scratch, d3d_dev)
    let _ = @dx12.dx_dxgi_output2_get_gamma_control_capabilities(o, scratch)
    let _ = @dx12.dx_dxgi_output2_get_frame_statistics(o, scratch)
    @dx12.write_u32(num_modes, 0, (0 : UInt32))
    let _ = @dx12.dx_dxgi_output2_get_display_mode_list1(o, 28, 0, num_modes, (0 : UInt64))
    let _ = @dx12.dx_dxgi_output2_find_closest_matching_mode1(o, mode_in, scratch, d3d_dev)
    let _ = @dx12.dx_dxgi_output2_supports_overlays(o)
    probed.val = probed.val + 12
  }

  if ifs[3] != (0 : UInt64) {
    let o = ifs[3]
    let _ = @dx12.dx_dxgi_output3_set_private_data(o, priv_guid, 4, priv_val)
    @dx12.write_u32(priv_sz, 0, (4 : UInt32))
    let _ = @dx12.dx_dxgi_output3_get_private_data(o, priv_guid, priv_sz, scratch)
    let _ = @dx12.dx_dxgi_output3_set_private_data_interface(o, priv_guid, (0 : UInt64))
    @dx12.write_u64(out_ptr, 0, (0 : UInt64))
    if @dx12.dx_dxgi_output3_get_parent(o, @dx12.bytes_ptr(@dx12.iid_dxgi_adapter), out_ptr) == 0 {
      let p = @dx12.read_u64(out_ptr, 0)
      if p != (0 : UInt64) { let _ = @dx12.com_release(p) }
    }
    let _ = @dx12.dx_dxgi_output3_get_desc(o, scratch)
    @dx12.write_u32(num_modes, 0, (0 : UInt32))
    let _ = @dx12.dx_dxgi_output3_get_display_mode_list(o, 28, 0, num_modes, (0 : UInt64))
    let _ = @dx12.dx_dxgi_output3_find_closest_matching_mode(o, mode_in, scratch, d3d_dev)
    let _ = @dx12.dx_dxgi_output3_get_gamma_control_capabilities(o, scratch)
    let _ = @dx12.dx_dxgi_output3_get_frame_statistics(o, scratch)
    @dx12.write_u32(num_modes, 0, (0 : UInt32))
    let _ = @dx12.dx_dxgi_output3_get_display_mode_list1(o, 28, 0, num_modes, (0 : UInt64))
    let _ = @dx12.dx_dxgi_output3_find_closest_matching_mode1(o, mode_in, scratch, d3d_dev)
    let _ = @dx12.dx_dxgi_output3_supports_overlays(o)
    let _ = @dx12.dx_dxgi_output3_check_overlay_support(o, 28, d3d_dev, flags_out)
    probed.val = probed.val + 13
  }

  if ifs[4] != (0 : UInt64) {
    let o = ifs[4]
    let _ = @dx12.dx_dxgi_output4_set_private_data(o, priv_guid, 4, priv_val)
    @dx12.write_u32(priv_sz, 0, (4 : UInt32))
    let _ = @dx12.dx_dxgi_output4_get_private_data(o, priv_guid, priv_sz, scratch)
    let _ = @dx12.dx_dxgi_output4_set_private_data_interface(o, priv_guid, (0 : UInt64))
    @dx12.write_u64(out_ptr, 0, (0 : UInt64))
    if @dx12.dx_dxgi_output4_get_parent(o, @dx12.bytes_ptr(@dx12.iid_dxgi_adapter), out_ptr) == 0 {
      let p = @dx12.read_u64(out_ptr, 0)
      if p != (0 : UInt64) { let _ = @dx12.com_release(p) }
    }
    let _ = @dx12.dx_dxgi_output4_get_desc(o, scratch)
    @dx12.write_u32(num_modes, 0, (0 : UInt32))
    let _ = @dx12.dx_dxgi_output4_get_display_mode_list(o, 28, 0, num_modes, (0 : UInt64))
    let _ = @dx12.dx_dxgi_output4_find_closest_matching_mode(o, mode_in, scratch, d3d_dev)
    let _ = @dx12.dx_dxgi_output4_get_gamma_control_capabilities(o, scratch)
    let _ = @dx12.dx_dxgi_output4_get_frame_statistics(o, scratch)
    @dx12.write_u32(num_modes, 0, (0 : UInt32))
    let _ = @dx12.dx_dxgi_output4_get_display_mode_list1(o, 28, 0, num_modes, (0 : UInt64))
    let _ = @dx12.dx_dxgi_output4_find_closest_matching_mode1(o, mode_in, scratch, d3d_dev)
    let _ = @dx12.dx_dxgi_output4_supports_overlays(o)
    let _ = @dx12.dx_dxgi_output4_check_overlay_support(o, 28, d3d_dev, flags_out)
    let _ = @dx12.dx_dxgi_output4_check_overlay_color_space_support(o, 28, 0, d3d_dev, flags_out)
    probed.val = probed.val + 14
  }

  if ifs[5] != (0 : UInt64) {
    let o = ifs[5]
    let _ = @dx12.dx_dxgi_output5_set_private_data(o, priv_guid, 4, priv_val)
    @dx12.write_u32(priv_sz, 0, (4 : UInt32))
    let _ = @dx12.dx_dxgi_output5_get_private_data(o, priv_guid, priv_sz, scratch)
    let _ = @dx12.dx_dxgi_output5_set_private_data_interface(o, priv_guid, (0 : UInt64))
    @dx12.write_u64(out_ptr, 0, (0 : UInt64))
    if @dx12.dx_dxgi_output5_get_parent(o, @dx12.bytes_ptr(@dx12.iid_dxgi_adapter), out_ptr) == 0 {
      let p = @dx12.read_u64(out_ptr, 0)
      if p != (0 : UInt64) { let _ = @dx12.com_release(p) }
    }
    let _ = @dx12.dx_dxgi_output5_get_desc(o, scratch)
    @dx12.write_u32(num_modes, 0, (0 : UInt32))
    let _ = @dx12.dx_dxgi_output5_get_display_mode_list(o, 28, 0, num_modes, (0 : UInt64))
    let _ = @dx12.dx_dxgi_output5_find_closest_matching_mode(o, mode_in, scratch, d3d_dev)
    let _ = @dx12.dx_dxgi_output5_get_gamma_control_capabilities(o, scratch)
    let _ = @dx12.dx_dxgi_output5_get_frame_statistics(o, scratch)
    @dx12.write_u32(num_modes, 0, (0 : UInt32))
    let _ = @dx12.dx_dxgi_output5_get_display_mode_list1(o, 28, 0, num_modes, (0 : UInt64))
    let _ = @dx12.dx_dxgi_output5_find_closest_matching_mode1(o, mode_in, scratch, d3d_dev)
    let _ = @dx12.dx_dxgi_output5_supports_overlays(o)
    let _ = @dx12.dx_dxgi_output5_check_overlay_support(o, 28, d3d_dev, flags_out)
    let _ = @dx12.dx_dxgi_output5_check_overlay_color_space_support(o, 28, 0, d3d_dev, flags_out)
    probed.val = probed.val + 14
  }

  if ifs[6] != (0 : UInt64) {
    let o = ifs[6]
    let _ = @dx12.dx_dxgi_output6_set_private_data(o, priv_guid, 4, priv_val)
    @dx12.write_u32(priv_sz, 0, (4 : UInt32))
    let _ = @dx12.dx_dxgi_output6_get_private_data(o, priv_guid, priv_sz, scratch)
    let _ = @dx12.dx_dxgi_output6_set_private_data_interface(o, priv_guid, (0 : UInt64))
    @dx12.write_u64(out_ptr, 0, (0 : UInt64))
    if @dx12.dx_dxgi_output6_get_parent(o, @dx12.bytes_ptr(@dx12.iid_dxgi_adapter), out_ptr) == 0 {
      let p = @dx12.read_u64(out_ptr, 0)
      if p != (0 : UInt64) { let _ = @dx12.com_release(p) }
    }
    let _ = @dx12.dx_dxgi_output6_get_desc(o, scratch)
    let _ = @dx12.dx_dxgi_output6_get_desc1(o, scratch)
    @dx12.write_u32(num_modes, 0, (0 : UInt32))
    let _ = @dx12.dx_dxgi_output6_get_display_mode_list(o, 28, 0, num_modes, (0 : UInt64))
    let _ = @dx12.dx_dxgi_output6_find_closest_matching_mode(o, mode_in, scratch, d3d_dev)
    let _ = @dx12.dx_dxgi_output6_get_gamma_control_capabilities(o, scratch)
    let _ = @dx12.dx_dxgi_output6_get_frame_statistics(o, scratch)
    @dx12.write_u32(num_modes, 0, (0 : UInt32))
    let _ = @dx12.dx_dxgi_output6_get_display_mode_list1(o, 28, 0, num_modes, (0 : UInt64))
    let _ = @dx12.dx_dxgi_output6_find_closest_matching_mode1(o, mode_in, scratch, d3d_dev)
    let _ = @dx12.dx_dxgi_output6_supports_overlays(o)
    let _ = @dx12.dx_dxgi_output6_check_overlay_support(o, 28, d3d_dev, flags_out)
    let _ = @dx12.dx_dxgi_output6_check_overlay_color_space_support(o, 28, 0, d3d_dev, flags_out)
    let _ = @dx12.dx_dxgi_output6_check_hardware_composition_support(o, flags_out)
    probed.val = probed.val + 16
  }

  for i = 1; i < 7; i = i + 1 {
    if ifs[i] != (0 : UInt64) {
      let _ = @dx12.com_release(ifs[i])
    }
  }
  @dx12.raw_free(priv_val)
  @dx12.raw_free(priv_sz)
  @dx12.raw_free(out_ptr)
  @dx12.raw_free(num_modes)
  @dx12.raw_free(flags_out)
  @dx12.raw_free(mode_in)
}
