// Generated DXGI swapchain raw-dispatch verification (IDXGISwapChain0..4).

///|
fn drain_dxgi_queue(
  queue : UInt64,
  fence : UInt64,
  ev : UInt64,
  fence_val : Ref[Int64],
) -> Unit {
  if queue == (0 : UInt64) || fence == (0 : UInt64) {
    return
  }
  fence_val.val = fence_val.val + (1 : Int64)
  let target = fence_val.val
  if @dx12.dx_d3d12_command_queue_signal(queue, fence, target) == 0 {
    while @dx12.dx_d3d12_fence_get_completed_value(fence) < target {
      if @dx12.dx_d3d12_fence_set_event_on_completion(fence, target, ev) == 0 {
        let _ = @dx12.wait_event(ev, 5000)
      } else {
        break
      }
    }
  }
}

///|
fn probe_swapchain_chain(
  sc_base : UInt64,
  queue : UInt64,
  fence : UInt64,
  ev : UInt64,
  fence_val : Ref[Int64],
  scratch : UInt64,
  probed : Ref[Int],
) -> Unit {
  let priv_guid = @dx12.bytes_ptr(@dx12.iid_dxgi_object)
  let priv_val = @dx12.raw_alloc(16)
  @dx12.write_u32(priv_val, 0, (99 : UInt32))
  let priv_sz = @dx12.raw_alloc(8)
  let out_ptr = @dx12.raw_alloc(16)
  let bool_out = @dx12.raw_alloc(8)
  let u32_a = @dx12.raw_alloc(8)
  let u32_b = @dx12.raw_alloc(8)
  let rgba = @dx12.raw_alloc(16)
  let present_params = @dx12.raw_alloc(32)
  let matrix = @dx12.raw_alloc(24)

  let qi_iids : Array[FixedArray[Byte]] = [
    @dx12.iid_dxgi_swap_chain,
    @dx12.iid_dxgi_swap_chain1,
    @dx12.iid_dxgi_swap_chain2,
    @dx12.iid_dxgi_swap_chain3,
    @dx12.iid_dxgi_swap_chain4,
  ]
  let ifs : Array[UInt64] = Array::make(5, (0 : UInt64))
  ifs[0] = sc_base
  for i = 1; i < 5; i = i + 1 {
    @dx12.write_u64(out_ptr, 0, (0 : UInt64))
    if @dx12.com_query_interface(sc_base, @dx12.bytes_ptr(qi_iids[i]), out_ptr) == 0 {
      ifs[i] = @dx12.read_u64(out_ptr, 0)
    }
  }

  if ifs[0] != (0 : UInt64) {
    let s = ifs[0]
    let _ = @dx12.dx_dxgi_swap_chain_set_private_data(s, priv_guid, 4, priv_val)
    @dx12.write_u32(priv_sz, 0, (4 : UInt32))
    let _ = @dx12.dx_dxgi_swap_chain_get_private_data(s, priv_guid, priv_sz, scratch)
    let _ = @dx12.dx_dxgi_swap_chain_set_private_data_interface(s, priv_guid, (0 : UInt64))
    @dx12.write_u64(out_ptr, 0, (0 : UInt64))
    if @dx12.dx_dxgi_swap_chain_get_parent(s, @dx12.bytes_ptr(@dx12.iid_dxgi_factory2), out_ptr) == 0 {
      let p = @dx12.read_u64(out_ptr, 0)
      if p != (0 : UInt64) { let _ = @dx12.com_release(p) }
    }
    @dx12.write_u64(out_ptr, 0, (0 : UInt64))
    if @dx12.dx_dxgi_swap_chain_get_device(s, @dx12.bytes_ptr(@dx12.iid_d3d12_device), out_ptr) == 0 {
      let d = @dx12.read_u64(out_ptr, 0)
      if d != (0 : UInt64) { let _ = @dx12.com_release(d) }
    }
    let _ = @dx12.dx_dxgi_swap_chain_present(s, 1, 0)
    @dx12.write_u64(out_ptr, 0, (0 : UInt64))
    if @dx12.dx_dxgi_swap_chain_get_buffer(s, 0, @dx12.bytes_ptr(@dx12.iid_d3d12_resource), out_ptr) == 0 {
      let b = @dx12.read_u64(out_ptr, 0)
      if b != (0 : UInt64) { let _ = @dx12.com_release(b) }
    }
    @dx12.write_u64(out_ptr, 0, (0 : UInt64))
    let _ = @dx12.dx_dxgi_swap_chain_get_fullscreen_state(s, bool_out, out_ptr)
    if @dx12.read_u64(out_ptr, 0) != (0 : UInt64) {
      let _ = @dx12.com_release(@dx12.read_u64(out_ptr, 0))
    }
    let _ = @dx12.dx_dxgi_swap_chain_get_desc(s, scratch)
    drain_dxgi_queue(queue, fence, ev, fence_val)
    let _ = @dx12.dx_dxgi_swap_chain_resize_buffers(s, 3, 64, 64, 28, 0)
    @dx12.write_u64(out_ptr, 0, (0 : UInt64))
    if @dx12.dx_dxgi_swap_chain_get_containing_output(s, out_ptr) == 0 {
      let o = @dx12.read_u64(out_ptr, 0)
      if o != (0 : UInt64) { let _ = @dx12.com_release(o) }
    }
    let _ = @dx12.dx_dxgi_swap_chain_get_frame_statistics(s, scratch)
    let _ = @dx12.dx_dxgi_swap_chain_get_last_present_count(s, u32_a)
    probed.val = probed.val + 13
  }

  if ifs[1] != (0 : UInt64) {
    let s = ifs[1]
    let _ = @dx12.dx_dxgi_swap_chain1_set_private_data(s, priv_guid, 4, priv_val)
    @dx12.write_u32(priv_sz, 0, (4 : UInt32))
    let _ = @dx12.dx_dxgi_swap_chain1_get_private_data(s, priv_guid, priv_sz, scratch)
    let _ = @dx12.dx_dxgi_swap_chain1_set_private_data_interface(s, priv_guid, (0 : UInt64))
    @dx12.write_u64(out_ptr, 0, (0 : UInt64))
    if @dx12.dx_dxgi_swap_chain1_get_parent(s, @dx12.bytes_ptr(@dx12.iid_dxgi_factory2), out_ptr) == 0 {
      let p = @dx12.read_u64(out_ptr, 0)
      if p != (0 : UInt64) { let _ = @dx12.com_release(p) }
    }
    @dx12.write_u64(out_ptr, 0, (0 : UInt64))
    if @dx12.dx_dxgi_swap_chain1_get_device(s, @dx12.bytes_ptr(@dx12.iid_d3d12_device), out_ptr) == 0 {
      let d = @dx12.read_u64(out_ptr, 0)
      if d != (0 : UInt64) { let _ = @dx12.com_release(d) }
    }
    let _ = @dx12.dx_dxgi_swap_chain1_present(s, 0, 0)
    @dx12.write_u64(out_ptr, 0, (0 : UInt64))
    if @dx12.dx_dxgi_swap_chain1_get_buffer(s, 0, @dx12.bytes_ptr(@dx12.iid_d3d12_resource), out_ptr) == 0 {
      let b = @dx12.read_u64(out_ptr, 0)
      if b != (0 : UInt64) { let _ = @dx12.com_release(b) }
    }
    @dx12.write_u64(out_ptr, 0, (0 : UInt64))
    let _ = @dx12.dx_dxgi_swap_chain1_get_fullscreen_state(s, bool_out, out_ptr)
    if @dx12.read_u64(out_ptr, 0) != (0 : UInt64) {
      let _ = @dx12.com_release(@dx12.read_u64(out_ptr, 0))
    }
    let _ = @dx12.dx_dxgi_swap_chain1_get_desc(s, scratch)
    drain_dxgi_queue(queue, fence, ev, fence_val)
    let _ = @dx12.dx_dxgi_swap_chain1_resize_buffers(s, 3, 64, 64, 28, 0)
    @dx12.write_u64(out_ptr, 0, (0 : UInt64))
    if @dx12.dx_dxgi_swap_chain1_get_containing_output(s, out_ptr) == 0 {
      let o = @dx12.read_u64(out_ptr, 0)
      if o != (0 : UInt64) { let _ = @dx12.com_release(o) }
    }
    let _ = @dx12.dx_dxgi_swap_chain1_get_frame_statistics(s, scratch)
    let _ = @dx12.dx_dxgi_swap_chain1_get_last_present_count(s, u32_a)
    let _ = @dx12.dx_dxgi_swap_chain1_get_desc1(s, scratch)
    let _ = @dx12.dx_dxgi_swap_chain1_get_fullscreen_desc(s, scratch)
    let _ = @dx12.dx_dxgi_swap_chain1_get_hwnd(s, out_ptr)
    let _ = @dx12.dx_dxgi_swap_chain1_present1(s, 0, 0, present_params)
    let _ = @dx12.dx_dxgi_swap_chain1_is_temporary_mono_supported(s)
    @dx12.write_u64(out_ptr, 0, (0 : UInt64))
    let _ = @dx12.dx_dxgi_swap_chain1_get_restrict_to_output(s, out_ptr)
    let _ = @dx12.dx_dxgi_swap_chain1_set_background_color(s, rgba)
    let _ = @dx12.dx_dxgi_swap_chain1_get_background_color(s, rgba)
    let _ = @dx12.dx_dxgi_swap_chain1_set_rotation(s, 1) // DXGI_MODE_ROTATION_IDENTITY
    let _ = @dx12.dx_dxgi_swap_chain1_get_rotation(s, u32_a)
    probed.val = probed.val + 23
  }

  if ifs[2] != (0 : UInt64) {
    let s = ifs[2]
    let _ = @dx12.dx_dxgi_swap_chain2_set_private_data(s, priv_guid, 4, priv_val)
    @dx12.write_u32(priv_sz, 0, (4 : UInt32))
    let _ = @dx12.dx_dxgi_swap_chain2_get_private_data(s, priv_guid, priv_sz, scratch)
    let _ = @dx12.dx_dxgi_swap_chain2_set_private_data_interface(s, priv_guid, (0 : UInt64))
    @dx12.write_u64(out_ptr, 0, (0 : UInt64))
    if @dx12.dx_dxgi_swap_chain2_get_parent(s, @dx12.bytes_ptr(@dx12.iid_dxgi_factory2), out_ptr) == 0 {
      let p = @dx12.read_u64(out_ptr, 0)
      if p != (0 : UInt64) { let _ = @dx12.com_release(p) }
    }
    @dx12.write_u64(out_ptr, 0, (0 : UInt64))
    if @dx12.dx_dxgi_swap_chain2_get_device(s, @dx12.bytes_ptr(@dx12.iid_d3d12_device), out_ptr) == 0 {
      let d = @dx12.read_u64(out_ptr, 0)
      if d != (0 : UInt64) { let _ = @dx12.com_release(d) }
    }
    let _ = @dx12.dx_dxgi_swap_chain2_present(s, 0, 0)
    @dx12.write_u64(out_ptr, 0, (0 : UInt64))
    if @dx12.dx_dxgi_swap_chain2_get_buffer(s, 0, @dx12.bytes_ptr(@dx12.iid_d3d12_resource), out_ptr) == 0 {
      let b = @dx12.read_u64(out_ptr, 0)
      if b != (0 : UInt64) { let _ = @dx12.com_release(b) }
    }
    @dx12.write_u64(out_ptr, 0, (0 : UInt64))
    let _ = @dx12.dx_dxgi_swap_chain2_get_fullscreen_state(s, bool_out, out_ptr)
    if @dx12.read_u64(out_ptr, 0) != (0 : UInt64) {
      let _ = @dx12.com_release(@dx12.read_u64(out_ptr, 0))
    }
    let _ = @dx12.dx_dxgi_swap_chain2_get_desc(s, scratch)
    drain_dxgi_queue(queue, fence, ev, fence_val)
    let _ = @dx12.dx_dxgi_swap_chain2_resize_buffers(s, 3, 64, 64, 28, 0)
    @dx12.write_u64(out_ptr, 0, (0 : UInt64))
    if @dx12.dx_dxgi_swap_chain2_get_containing_output(s, out_ptr) == 0 {
      let o = @dx12.read_u64(out_ptr, 0)
      if o != (0 : UInt64) { let _ = @dx12.com_release(o) }
    }
    let _ = @dx12.dx_dxgi_swap_chain2_get_frame_statistics(s, scratch)
    let _ = @dx12.dx_dxgi_swap_chain2_get_last_present_count(s, u32_a)
    let _ = @dx12.dx_dxgi_swap_chain2_get_desc1(s, scratch)
    let _ = @dx12.dx_dxgi_swap_chain2_get_fullscreen_desc(s, scratch)
    let _ = @dx12.dx_dxgi_swap_chain2_get_hwnd(s, out_ptr)
    let _ = @dx12.dx_dxgi_swap_chain2_present1(s, 0, 0, present_params)
    let _ = @dx12.dx_dxgi_swap_chain2_is_temporary_mono_supported(s)
    @dx12.write_u64(out_ptr, 0, (0 : UInt64))
    let _ = @dx12.dx_dxgi_swap_chain2_get_restrict_to_output(s, out_ptr)
    let _ = @dx12.dx_dxgi_swap_chain2_set_background_color(s, rgba)
    let _ = @dx12.dx_dxgi_swap_chain2_get_background_color(s, rgba)
    let _ = @dx12.dx_dxgi_swap_chain2_set_rotation(s, 1)
    let _ = @dx12.dx_dxgi_swap_chain2_get_rotation(s, u32_a)
    let _ = @dx12.dx_dxgi_swap_chain2_set_source_size(s, 64, 64)
    let _ = @dx12.dx_dxgi_swap_chain2_get_source_size(s, u32_a, u32_b)
    let _ = @dx12.dx_dxgi_swap_chain2_set_maximum_frame_latency(s, 2)
    let _ = @dx12.dx_dxgi_swap_chain2_get_maximum_frame_latency(s, u32_a)
    let waitable = @dx12.dx_dxgi_swap_chain2_get_frame_latency_waitable_object(s)
    if waitable != (0 : UInt64) { @dx12.close_handle(waitable) }
    let _ = @dx12.dx_dxgi_swap_chain2_get_matrix_transform(s, matrix)
    probed.val = probed.val + 29
  }

  if ifs[3] != (0 : UInt64) {
    let s = ifs[3]
    let _ = @dx12.dx_dxgi_swap_chain3_set_private_data(s, priv_guid, 4, priv_val)
    @dx12.write_u32(priv_sz, 0, (4 : UInt32))
    let _ = @dx12.dx_dxgi_swap_chain3_get_private_data(s, priv_guid, priv_sz, scratch)
    let _ = @dx12.dx_dxgi_swap_chain3_set_private_data_interface(s, priv_guid, (0 : UInt64))
    @dx12.write_u64(out_ptr, 0, (0 : UInt64))
    if @dx12.dx_dxgi_swap_chain3_get_parent(s, @dx12.bytes_ptr(@dx12.iid_dxgi_factory2), out_ptr) == 0 {
      let p = @dx12.read_u64(out_ptr, 0)
      if p != (0 : UInt64) { let _ = @dx12.com_release(p) }
    }
    @dx12.write_u64(out_ptr, 0, (0 : UInt64))
    if @dx12.dx_dxgi_swap_chain3_get_device(s, @dx12.bytes_ptr(@dx12.iid_d3d12_device), out_ptr) == 0 {
      let d = @dx12.read_u64(out_ptr, 0)
      if d != (0 : UInt64) { let _ = @dx12.com_release(d) }
    }
    let _ = @dx12.dx_dxgi_swap_chain3_present(s, 0, 0)
    @dx12.write_u64(out_ptr, 0, (0 : UInt64))
    if @dx12.dx_dxgi_swap_chain3_get_buffer(s, 0, @dx12.bytes_ptr(@dx12.iid_d3d12_resource), out_ptr) == 0 {
      let b = @dx12.read_u64(out_ptr, 0)
      if b != (0 : UInt64) { let _ = @dx12.com_release(b) }
    }
    @dx12.write_u64(out_ptr, 0, (0 : UInt64))
    let _ = @dx12.dx_dxgi_swap_chain3_get_fullscreen_state(s, bool_out, out_ptr)
    if @dx12.read_u64(out_ptr, 0) != (0 : UInt64) {
      let _ = @dx12.com_release(@dx12.read_u64(out_ptr, 0))
    }
    let _ = @dx12.dx_dxgi_swap_chain3_get_desc(s, scratch)
    drain_dxgi_queue(queue, fence, ev, fence_val)
    let _ = @dx12.dx_dxgi_swap_chain3_resize_buffers(s, 3, 64, 64, 28, 0)
    @dx12.write_u64(out_ptr, 0, (0 : UInt64))
    if @dx12.dx_dxgi_swap_chain3_get_containing_output(s, out_ptr) == 0 {
      let o = @dx12.read_u64(out_ptr, 0)
      if o != (0 : UInt64) { let _ = @dx12.com_release(o) }
    }
    let _ = @dx12.dx_dxgi_swap_chain3_get_frame_statistics(s, scratch)
    let _ = @dx12.dx_dxgi_swap_chain3_get_last_present_count(s, u32_a)
    let _ = @dx12.dx_dxgi_swap_chain3_get_desc1(s, scratch)
    let _ = @dx12.dx_dxgi_swap_chain3_get_fullscreen_desc(s, scratch)
    let _ = @dx12.dx_dxgi_swap_chain3_get_hwnd(s, out_ptr)
    let _ = @dx12.dx_dxgi_swap_chain3_present1(s, 0, 0, present_params)
    let _ = @dx12.dx_dxgi_swap_chain3_is_temporary_mono_supported(s)
    @dx12.write_u64(out_ptr, 0, (0 : UInt64))
    let _ = @dx12.dx_dxgi_swap_chain3_get_restrict_to_output(s, out_ptr)
    let _ = @dx12.dx_dxgi_swap_chain3_set_background_color(s, rgba)
    let _ = @dx12.dx_dxgi_swap_chain3_get_background_color(s, rgba)
    let _ = @dx12.dx_dxgi_swap_chain3_set_rotation(s, 1)
    let _ = @dx12.dx_dxgi_swap_chain3_get_rotation(s, u32_a)
    let _ = @dx12.dx_dxgi_swap_chain3_set_source_size(s, 64, 64)
    let _ = @dx12.dx_dxgi_swap_chain3_get_source_size(s, u32_a, u32_b)
    let _ = @dx12.dx_dxgi_swap_chain3_set_maximum_frame_latency(s, 2)
    let _ = @dx12.dx_dxgi_swap_chain3_get_maximum_frame_latency(s, u32_a)
    let waitable = @dx12.dx_dxgi_swap_chain3_get_frame_latency_waitable_object(s)
    if waitable != (0 : UInt64) { @dx12.close_handle(waitable) }
    let _ = @dx12.dx_dxgi_swap_chain3_get_matrix_transform(s, matrix)
    let _ = @dx12.dx_dxgi_swap_chain3_get_current_back_buffer_index(s)
    let _ = @dx12.dx_dxgi_swap_chain3_check_color_space_support(s, 0, u32_a)
    let _ = @dx12.dx_dxgi_swap_chain3_set_color_space1(s, 0)
    probed.val = probed.val + 32
  }

  if ifs[4] != (0 : UInt64) {
    let s = ifs[4]
    let _ = @dx12.dx_dxgi_swap_chain4_set_private_data(s, priv_guid, 4, priv_val)
    @dx12.write_u32(priv_sz, 0, (4 : UInt32))
    let _ = @dx12.dx_dxgi_swap_chain4_get_private_data(s, priv_guid, priv_sz, scratch)
    let _ = @dx12.dx_dxgi_swap_chain4_set_private_data_interface(s, priv_guid, (0 : UInt64))
    @dx12.write_u64(out_ptr, 0, (0 : UInt64))
    if @dx12.dx_dxgi_swap_chain4_get_parent(s, @dx12.bytes_ptr(@dx12.iid_dxgi_factory2), out_ptr) == 0 {
      let p = @dx12.read_u64(out_ptr, 0)
      if p != (0 : UInt64) { let _ = @dx12.com_release(p) }
    }
    @dx12.write_u64(out_ptr, 0, (0 : UInt64))
    if @dx12.dx_dxgi_swap_chain4_get_device(s, @dx12.bytes_ptr(@dx12.iid_d3d12_device), out_ptr) == 0 {
      let d = @dx12.read_u64(out_ptr, 0)
      if d != (0 : UInt64) { let _ = @dx12.com_release(d) }
    }
    let _ = @dx12.dx_dxgi_swap_chain4_present(s, 0, 0)
    @dx12.write_u64(out_ptr, 0, (0 : UInt64))
    if @dx12.dx_dxgi_swap_chain4_get_buffer(s, 0, @dx12.bytes_ptr(@dx12.iid_d3d12_resource), out_ptr) == 0 {
      let b = @dx12.read_u64(out_ptr, 0)
      if b != (0 : UInt64) { let _ = @dx12.com_release(b) }
    }
    @dx12.write_u64(out_ptr, 0, (0 : UInt64))
    let _ = @dx12.dx_dxgi_swap_chain4_get_fullscreen_state(s, bool_out, out_ptr)
    if @dx12.read_u64(out_ptr, 0) != (0 : UInt64) {
      let _ = @dx12.com_release(@dx12.read_u64(out_ptr, 0))
    }
    let _ = @dx12.dx_dxgi_swap_chain4_get_desc(s, scratch)
    drain_dxgi_queue(queue, fence, ev, fence_val)
    let _ = @dx12.dx_dxgi_swap_chain4_resize_buffers(s, 3, 64, 64, 28, 0)
    @dx12.write_u64(out_ptr, 0, (0 : UInt64))
    if @dx12.dx_dxgi_swap_chain4_get_containing_output(s, out_ptr) == 0 {
      let o = @dx12.read_u64(out_ptr, 0)
      if o != (0 : UInt64) { let _ = @dx12.com_release(o) }
    }
    let _ = @dx12.dx_dxgi_swap_chain4_get_frame_statistics(s, scratch)
    let _ = @dx12.dx_dxgi_swap_chain4_get_last_present_count(s, u32_a)
    let _ = @dx12.dx_dxgi_swap_chain4_get_desc1(s, scratch)
    let _ = @dx12.dx_dxgi_swap_chain4_get_fullscreen_desc(s, scratch)
    let _ = @dx12.dx_dxgi_swap_chain4_get_hwnd(s, out_ptr)
    let _ = @dx12.dx_dxgi_swap_chain4_present1(s, 0, 0, present_params)
    let _ = @dx12.dx_dxgi_swap_chain4_is_temporary_mono_supported(s)
    @dx12.write_u64(out_ptr, 0, (0 : UInt64))
    let _ = @dx12.dx_dxgi_swap_chain4_get_restrict_to_output(s, out_ptr)
    let _ = @dx12.dx_dxgi_swap_chain4_set_background_color(s, rgba)
    let _ = @dx12.dx_dxgi_swap_chain4_get_background_color(s, rgba)
    let _ = @dx12.dx_dxgi_swap_chain4_set_rotation(s, 1)
    let _ = @dx12.dx_dxgi_swap_chain4_get_rotation(s, u32_a)
    let _ = @dx12.dx_dxgi_swap_chain4_set_source_size(s, 64, 64)
    let _ = @dx12.dx_dxgi_swap_chain4_get_source_size(s, u32_a, u32_b)
    let _ = @dx12.dx_dxgi_swap_chain4_set_maximum_frame_latency(s, 2)
    let _ = @dx12.dx_dxgi_swap_chain4_get_maximum_frame_latency(s, u32_a)
    let waitable = @dx12.dx_dxgi_swap_chain4_get_frame_latency_waitable_object(s)
    if waitable != (0 : UInt64) { @dx12.close_handle(waitable) }
    let _ = @dx12.dx_dxgi_swap_chain4_get_matrix_transform(s, matrix)
    let _ = @dx12.dx_dxgi_swap_chain4_get_current_back_buffer_index(s)
    let _ = @dx12.dx_dxgi_swap_chain4_check_color_space_support(s, 0, u32_a)
    let _ = @dx12.dx_dxgi_swap_chain4_set_color_space1(s, 0)
    let _ = @dx12.dx_dxgi_swap_chain4_set_hdr_meta_data(s, 0, 0, (0 : UInt64))
    probed.val = probed.val + 33
  }

  for i = 1; i < 5; i = i + 1 {
    if ifs[i] != (0 : UInt64) {
      let _ = @dx12.com_release(ifs[i])
    }
  }
  @dx12.raw_free(priv_val)
  @dx12.raw_free(priv_sz)
  @dx12.raw_free(out_ptr)
  @dx12.raw_free(bool_out)
  @dx12.raw_free(u32_a)
  @dx12.raw_free(u32_b)
  @dx12.raw_free(rgba)
  @dx12.raw_free(present_params)
  @dx12.raw_free(matrix)
}
