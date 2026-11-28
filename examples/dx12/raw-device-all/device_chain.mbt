// Generated-dispatch verification across ID3D12Device..ID3D12Device14.

///|
struct DeviceCtx {
  raw_dev : UInt64
  scratch : UInt64
  out_ptr : UInt64
  priv_guid : UInt64
  priv_val : UInt64
  priv_sz : UInt64
  name_w : UInt64
  q_desc : UInt64
  rs_blob : UInt64
  rs_len : Int64
  rs : UInt64
  gpsd : UInt64
  cpsd : UInt64
  stream_desc : UInt64
  ca : UInt64
  dh_desc : UInt64
  heap_default : UInt64
  buf_desc : UInt64
  tex_desc : UInt64
  tex_desc1 : UInt64
  tiled_desc : UInt64
  tiled_desc1 : UInt64
  heap_desc : UInt64
  cbv_desc : UInt64
  srv_desc : UInt64
  uav_desc : UInt64
  samp_desc : UInt64
  samp2_desc : UInt64
  cpu_cbv : UInt64
  cpu_srv : UInt64
  cpu_uav : UInt64
  cpu_rtv : UInt64
  cpu_dsv : UInt64
  cpu_samp : UInt64
  cpu_arr : UInt64
  sz_arr : UInt64
  buf_def : UInt64
  buf_uav : UInt64
  tex_rt : UInt64
  tex_ds : UInt64
  heap_obj : UInt64
  res_arr : UInt64
  prio_arr : UInt64
  qh_desc : UInt64
  csig_desc : UInt64
  fence : UInt64
  fence_arr : UInt64
  val_arr : UInt64
  ev : UInt64
  arch_buf : UInt64
  reserved_res : UInt64
  rt_inputs : UInt64
  rt_prebuild : UInt64
  rt_ident : UInt64
  rt_so_desc : UInt64
  rt_add_desc : UInt64
  rt_so : UInt64
  cache_desc : UInt64
  rt_tier : Int
  probed : Ref[Int]
  mut fence_seq : Int64
}


///|
fn probe_device_v0(ctx : DeviceCtx) -> Unit {
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.com_query_interface(ctx.raw_dev, @dx12.bytes_ptr(@dx12.iid_d3d12_device), ctx.out_ptr) != 0 {
    return
  }
  let d = @dx12.read_u64(ctx.out_ptr, 0)
  if d == (0 : UInt64) { return }
  let _ = @dx12.dx_d3d12_device_set_private_data(d, ctx.priv_guid, 4, ctx.priv_val)
  @dx12.write_u32(ctx.priv_sz, 0, (4 : UInt32))
  let _ = @dx12.dx_d3d12_device_get_private_data(d, ctx.priv_guid, ctx.priv_sz, ctx.scratch)
  let _ = @dx12.dx_d3d12_device_set_private_data_interface(d, ctx.priv_guid, (0 : UInt64))
  let _ = @dx12.dx_d3d12_device_set_name(d, ctx.name_w)
  let _ = @dx12.dx_d3d12_device_get_node_count(d)
  let _ = @dx12.dx_d3d12_device_get_device_removed_reason(d)
  let _ = @dx12.dx_d3d12_device_check_feature_support(d, 1, ctx.arch_buf, 16)
  let _ = @dx12.dx_d3d12_device_get_descriptor_handle_increment_size(d, 0)
  let _ = @dx12.dx_d3d12_device_get_resource_allocation_info(d, ctx.scratch, 0, 1, ctx.buf_desc)
  let _ = @dx12.dx_d3d12_device_get_custom_heap_properties(d, ctx.scratch, 0, 1)
  let _ = @dx12.dx_d3d12_device_get_adapter_luid(d, ctx.scratch)
  @dx12.dx_d3d12_device_get_copyable_footprints(d, ctx.tex_desc, 0, 1, (0 : Int64), ctx.scratch, ctx.scratch + (256 : UInt64), ctx.scratch + (512 : UInt64), ctx.scratch + (768 : UInt64))
  if ctx.reserved_res != (0 : UInt64) {
    @dx12.write_u32(ctx.scratch, 0, (1 : UInt32))
    @dx12.dx_d3d12_device_get_resource_tiling(d, ctx.reserved_res, ctx.scratch + (16 : UInt64), ctx.scratch + (32 : UInt64), ctx.scratch + (64 : UInt64), ctx.scratch, 0, ctx.scratch + (128 : UInt64))
  }
  @dx12.dx_d3d12_device_create_constant_buffer_view(d, ctx.cbv_desc, ctx.cpu_cbv)
  @dx12.dx_d3d12_device_create_shader_resource_view(d, ctx.buf_def, ctx.srv_desc, ctx.cpu_srv)
  @dx12.dx_d3d12_device_create_unordered_access_view(d, ctx.buf_uav, (0 : UInt64), ctx.uav_desc, ctx.cpu_uav)
  @dx12.dx_d3d12_device_create_render_target_view(d, ctx.tex_rt, (0 : UInt64), ctx.cpu_rtv)
  @dx12.dx_d3d12_device_create_depth_stencil_view(d, ctx.tex_ds, (0 : UInt64), ctx.cpu_dsv)
  @dx12.dx_d3d12_device_create_sampler(d, ctx.samp_desc, ctx.cpu_samp)
  @dx12.dx_d3d12_device_copy_descriptors(d, 1, ctx.cpu_arr + (8 : UInt64), ctx.sz_arr, 1, ctx.cpu_arr, ctx.sz_arr, 0)
  @dx12.dx_d3d12_device_copy_descriptors_simple(d, 1, ctx.cpu_uav, ctx.cpu_srv, 0)
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device_create_command_queue(d, ctx.q_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_command_queue), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device_create_command_allocator(d, 0, @dx12.bytes_ptr(@dx12.iid_d3d12_command_allocator), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device_create_graphics_pipeline_state(d, ctx.gpsd, @dx12.bytes_ptr(@dx12.iid_d3d12_pipeline_state), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device_create_compute_pipeline_state(d, ctx.cpsd, @dx12.bytes_ptr(@dx12.iid_d3d12_pipeline_state), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device_create_command_list(d, 0, 0, ctx.ca, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_graphics_command_list), ctx.out_ptr) == 0 { let cl = @dx12.read_u64(ctx.out_ptr, 0); let _ = @dx12.dx_d3d12_graphics_command_list_close(cl); let _ = @dx12.com_release(cl) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device_create_descriptor_heap(d, ctx.dh_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_descriptor_heap), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device_create_root_signature(d, 0, ctx.rs_blob, ctx.rs_len, @dx12.bytes_ptr(@dx12.iid_d3d12_root_signature), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device_create_committed_resource(d, ctx.heap_default, 0, ctx.buf_desc, 0, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device_create_heap(d, ctx.heap_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_heap), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device_create_placed_resource(d, ctx.heap_obj, (0 : Int64), ctx.buf_desc, 0, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device_create_reserved_resource(d, ctx.tiled_desc, 0, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device_create_fence(d, (0 : Int64), 1, @dx12.bytes_ptr(@dx12.iid_d3d12_fence), ctx.out_ptr) == 0 {
    let sf = @dx12.read_u64(ctx.out_ptr, 0)
    let sh_out = ctx.scratch + (1024 : UInt64)
    @dx12.write_u64(sh_out, 0, (0 : UInt64))
    if @dx12.dx_d3d12_device_create_shared_handle(d, sf, (0 : UInt64), 0x10000000, ctx.name_w, sh_out) == 0 {
      let sh = @dx12.read_u64(sh_out, 0)
      let open_out = ctx.scratch + (1040 : UInt64)
      @dx12.write_u64(open_out, 0, (0 : UInt64))
      if @dx12.dx_d3d12_device_open_shared_handle(d, sh, @dx12.bytes_ptr(@dx12.iid_d3d12_fence), open_out) == 0 { let _ = @dx12.com_release(@dx12.read_u64(open_out, 0)) }
      let sh2_out = ctx.scratch + (1056 : UInt64)
      @dx12.write_u64(sh2_out, 0, (0 : UInt64))
      if @dx12.dx_d3d12_device_open_shared_handle_by_name(d, ctx.name_w, 0x10000000, sh2_out) == 0 { @dx12.close_handle(@dx12.read_u64(sh2_out, 0)) }
      @dx12.close_handle(sh)
    }
    let _ = @dx12.com_release(sf)
  }
  let _ = @dx12.dx_d3d12_device_make_resident(d, 1, ctx.res_arr)
  let _ = @dx12.dx_d3d12_device_evict(d, 1, ctx.res_arr)
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device_create_query_heap(d, ctx.qh_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_query_heap), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device_create_command_signature(d, ctx.csig_desc, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_command_signature), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  ctx.probed.val = ctx.probed.val + 36
  let _ = @dx12.com_release(d)
}

///|
fn probe_device_v1(ctx : DeviceCtx) -> Unit {
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.com_query_interface(ctx.raw_dev, @dx12.bytes_ptr(@dx12.iid_d3d12_device1), ctx.out_ptr) != 0 {
    return
  }
  let d = @dx12.read_u64(ctx.out_ptr, 0)
  if d == (0 : UInt64) { return }
  let _ = @dx12.dx_d3d12_device1_set_private_data(d, ctx.priv_guid, 4, ctx.priv_val)
  @dx12.write_u32(ctx.priv_sz, 0, (4 : UInt32))
  let _ = @dx12.dx_d3d12_device1_get_private_data(d, ctx.priv_guid, ctx.priv_sz, ctx.scratch)
  let _ = @dx12.dx_d3d12_device1_set_private_data_interface(d, ctx.priv_guid, (0 : UInt64))
  let _ = @dx12.dx_d3d12_device1_set_name(d, ctx.name_w)
  let _ = @dx12.dx_d3d12_device1_get_node_count(d)
  let _ = @dx12.dx_d3d12_device1_get_device_removed_reason(d)
  let _ = @dx12.dx_d3d12_device1_check_feature_support(d, 1, ctx.arch_buf, 16)
  let _ = @dx12.dx_d3d12_device1_get_descriptor_handle_increment_size(d, 0)
  let _ = @dx12.dx_d3d12_device1_get_resource_allocation_info(d, ctx.scratch, 0, 1, ctx.buf_desc)
  let _ = @dx12.dx_d3d12_device1_get_custom_heap_properties(d, ctx.scratch, 0, 1)
  let _ = @dx12.dx_d3d12_device1_get_adapter_luid(d, ctx.scratch)
  @dx12.dx_d3d12_device1_get_copyable_footprints(d, ctx.tex_desc, 0, 1, (0 : Int64), ctx.scratch, ctx.scratch + (256 : UInt64), ctx.scratch + (512 : UInt64), ctx.scratch + (768 : UInt64))
  if ctx.reserved_res != (0 : UInt64) {
    @dx12.write_u32(ctx.scratch, 0, (1 : UInt32))
    @dx12.dx_d3d12_device1_get_resource_tiling(d, ctx.reserved_res, ctx.scratch + (16 : UInt64), ctx.scratch + (32 : UInt64), ctx.scratch + (64 : UInt64), ctx.scratch, 0, ctx.scratch + (128 : UInt64))
  }
  @dx12.dx_d3d12_device1_create_constant_buffer_view(d, ctx.cbv_desc, ctx.cpu_cbv)
  @dx12.dx_d3d12_device1_create_shader_resource_view(d, ctx.buf_def, ctx.srv_desc, ctx.cpu_srv)
  @dx12.dx_d3d12_device1_create_unordered_access_view(d, ctx.buf_uav, (0 : UInt64), ctx.uav_desc, ctx.cpu_uav)
  @dx12.dx_d3d12_device1_create_render_target_view(d, ctx.tex_rt, (0 : UInt64), ctx.cpu_rtv)
  @dx12.dx_d3d12_device1_create_depth_stencil_view(d, ctx.tex_ds, (0 : UInt64), ctx.cpu_dsv)
  @dx12.dx_d3d12_device1_create_sampler(d, ctx.samp_desc, ctx.cpu_samp)
  @dx12.dx_d3d12_device1_copy_descriptors(d, 1, ctx.cpu_arr + (8 : UInt64), ctx.sz_arr, 1, ctx.cpu_arr, ctx.sz_arr, 0)
  @dx12.dx_d3d12_device1_copy_descriptors_simple(d, 1, ctx.cpu_uav, ctx.cpu_srv, 0)
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device1_create_command_queue(d, ctx.q_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_command_queue), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device1_create_command_allocator(d, 0, @dx12.bytes_ptr(@dx12.iid_d3d12_command_allocator), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device1_create_graphics_pipeline_state(d, ctx.gpsd, @dx12.bytes_ptr(@dx12.iid_d3d12_pipeline_state), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device1_create_compute_pipeline_state(d, ctx.cpsd, @dx12.bytes_ptr(@dx12.iid_d3d12_pipeline_state), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device1_create_command_list(d, 0, 0, ctx.ca, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_graphics_command_list), ctx.out_ptr) == 0 { let cl = @dx12.read_u64(ctx.out_ptr, 0); let _ = @dx12.dx_d3d12_graphics_command_list_close(cl); let _ = @dx12.com_release(cl) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device1_create_descriptor_heap(d, ctx.dh_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_descriptor_heap), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device1_create_root_signature(d, 0, ctx.rs_blob, ctx.rs_len, @dx12.bytes_ptr(@dx12.iid_d3d12_root_signature), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device1_create_committed_resource(d, ctx.heap_default, 0, ctx.buf_desc, 0, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device1_create_heap(d, ctx.heap_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_heap), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device1_create_placed_resource(d, ctx.heap_obj, (0 : Int64), ctx.buf_desc, 0, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device1_create_reserved_resource(d, ctx.tiled_desc, 0, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device1_create_fence(d, (0 : Int64), 1, @dx12.bytes_ptr(@dx12.iid_d3d12_fence), ctx.out_ptr) == 0 {
    let sf = @dx12.read_u64(ctx.out_ptr, 0)
    let sh_out = ctx.scratch + (1024 : UInt64)
    @dx12.write_u64(sh_out, 0, (0 : UInt64))
    if @dx12.dx_d3d12_device1_create_shared_handle(d, sf, (0 : UInt64), 0x10000000, ctx.name_w, sh_out) == 0 {
      let sh = @dx12.read_u64(sh_out, 0)
      let open_out = ctx.scratch + (1040 : UInt64)
      @dx12.write_u64(open_out, 0, (0 : UInt64))
      if @dx12.dx_d3d12_device1_open_shared_handle(d, sh, @dx12.bytes_ptr(@dx12.iid_d3d12_fence), open_out) == 0 { let _ = @dx12.com_release(@dx12.read_u64(open_out, 0)) }
      let sh2_out = ctx.scratch + (1056 : UInt64)
      @dx12.write_u64(sh2_out, 0, (0 : UInt64))
      if @dx12.dx_d3d12_device1_open_shared_handle_by_name(d, ctx.name_w, 0x10000000, sh2_out) == 0 { @dx12.close_handle(@dx12.read_u64(sh2_out, 0)) }
      @dx12.close_handle(sh)
    }
    let _ = @dx12.com_release(sf)
  }
  let _ = @dx12.dx_d3d12_device1_make_resident(d, 1, ctx.res_arr)
  let _ = @dx12.dx_d3d12_device1_evict(d, 1, ctx.res_arr)
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device1_create_query_heap(d, ctx.qh_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_query_heap), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device1_create_command_signature(d, ctx.csig_desc, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_command_signature), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  ctx.probed.val = ctx.probed.val + 36
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device1_create_pipeline_library(d, (0 : UInt64), (0 : Int64), @dx12.bytes_ptr(@dx12.iid_d3d12_pipeline_library), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  let _ = @dx12.dx_d3d12_device1_set_event_on_multiple_fence_completion(d, ctx.fence_arr, ctx.val_arr, 1, 0, ctx.ev)
  let _ = @dx12.wait_event(ctx.ev, 1000)
  let _ = @dx12.dx_d3d12_device1_set_residency_priority(d, 1, ctx.res_arr, ctx.prio_arr)
  ctx.probed.val = ctx.probed.val + 3
  let _ = @dx12.com_release(d)
}

///|
fn probe_device_v2(ctx : DeviceCtx) -> Unit {
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.com_query_interface(ctx.raw_dev, @dx12.bytes_ptr(@dx12.iid_d3d12_device2), ctx.out_ptr) != 0 {
    return
  }
  let d = @dx12.read_u64(ctx.out_ptr, 0)
  if d == (0 : UInt64) { return }
  let _ = @dx12.dx_d3d12_device2_set_private_data(d, ctx.priv_guid, 4, ctx.priv_val)
  @dx12.write_u32(ctx.priv_sz, 0, (4 : UInt32))
  let _ = @dx12.dx_d3d12_device2_get_private_data(d, ctx.priv_guid, ctx.priv_sz, ctx.scratch)
  let _ = @dx12.dx_d3d12_device2_set_private_data_interface(d, ctx.priv_guid, (0 : UInt64))
  let _ = @dx12.dx_d3d12_device2_set_name(d, ctx.name_w)
  let _ = @dx12.dx_d3d12_device2_get_node_count(d)
  let _ = @dx12.dx_d3d12_device2_get_device_removed_reason(d)
  let _ = @dx12.dx_d3d12_device2_check_feature_support(d, 1, ctx.arch_buf, 16)
  let _ = @dx12.dx_d3d12_device2_get_descriptor_handle_increment_size(d, 0)
  let _ = @dx12.dx_d3d12_device2_get_resource_allocation_info(d, ctx.scratch, 0, 1, ctx.buf_desc)
  let _ = @dx12.dx_d3d12_device2_get_custom_heap_properties(d, ctx.scratch, 0, 1)
  let _ = @dx12.dx_d3d12_device2_get_adapter_luid(d, ctx.scratch)
  @dx12.dx_d3d12_device2_get_copyable_footprints(d, ctx.tex_desc, 0, 1, (0 : Int64), ctx.scratch, ctx.scratch + (256 : UInt64), ctx.scratch + (512 : UInt64), ctx.scratch + (768 : UInt64))
  if ctx.reserved_res != (0 : UInt64) {
    @dx12.write_u32(ctx.scratch, 0, (1 : UInt32))
    @dx12.dx_d3d12_device2_get_resource_tiling(d, ctx.reserved_res, ctx.scratch + (16 : UInt64), ctx.scratch + (32 : UInt64), ctx.scratch + (64 : UInt64), ctx.scratch, 0, ctx.scratch + (128 : UInt64))
  }
  @dx12.dx_d3d12_device2_create_constant_buffer_view(d, ctx.cbv_desc, ctx.cpu_cbv)
  @dx12.dx_d3d12_device2_create_shader_resource_view(d, ctx.buf_def, ctx.srv_desc, ctx.cpu_srv)
  @dx12.dx_d3d12_device2_create_unordered_access_view(d, ctx.buf_uav, (0 : UInt64), ctx.uav_desc, ctx.cpu_uav)
  @dx12.dx_d3d12_device2_create_render_target_view(d, ctx.tex_rt, (0 : UInt64), ctx.cpu_rtv)
  @dx12.dx_d3d12_device2_create_depth_stencil_view(d, ctx.tex_ds, (0 : UInt64), ctx.cpu_dsv)
  @dx12.dx_d3d12_device2_create_sampler(d, ctx.samp_desc, ctx.cpu_samp)
  @dx12.dx_d3d12_device2_copy_descriptors(d, 1, ctx.cpu_arr + (8 : UInt64), ctx.sz_arr, 1, ctx.cpu_arr, ctx.sz_arr, 0)
  @dx12.dx_d3d12_device2_copy_descriptors_simple(d, 1, ctx.cpu_uav, ctx.cpu_srv, 0)
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device2_create_command_queue(d, ctx.q_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_command_queue), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device2_create_command_allocator(d, 0, @dx12.bytes_ptr(@dx12.iid_d3d12_command_allocator), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device2_create_graphics_pipeline_state(d, ctx.gpsd, @dx12.bytes_ptr(@dx12.iid_d3d12_pipeline_state), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device2_create_compute_pipeline_state(d, ctx.cpsd, @dx12.bytes_ptr(@dx12.iid_d3d12_pipeline_state), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device2_create_command_list(d, 0, 0, ctx.ca, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_graphics_command_list), ctx.out_ptr) == 0 { let cl = @dx12.read_u64(ctx.out_ptr, 0); let _ = @dx12.dx_d3d12_graphics_command_list_close(cl); let _ = @dx12.com_release(cl) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device2_create_descriptor_heap(d, ctx.dh_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_descriptor_heap), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device2_create_root_signature(d, 0, ctx.rs_blob, ctx.rs_len, @dx12.bytes_ptr(@dx12.iid_d3d12_root_signature), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device2_create_committed_resource(d, ctx.heap_default, 0, ctx.buf_desc, 0, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device2_create_heap(d, ctx.heap_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_heap), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device2_create_placed_resource(d, ctx.heap_obj, (0 : Int64), ctx.buf_desc, 0, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device2_create_reserved_resource(d, ctx.tiled_desc, 0, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device2_create_fence(d, (0 : Int64), 1, @dx12.bytes_ptr(@dx12.iid_d3d12_fence), ctx.out_ptr) == 0 {
    let sf = @dx12.read_u64(ctx.out_ptr, 0)
    let sh_out = ctx.scratch + (1024 : UInt64)
    @dx12.write_u64(sh_out, 0, (0 : UInt64))
    if @dx12.dx_d3d12_device2_create_shared_handle(d, sf, (0 : UInt64), 0x10000000, ctx.name_w, sh_out) == 0 {
      let sh = @dx12.read_u64(sh_out, 0)
      let open_out = ctx.scratch + (1040 : UInt64)
      @dx12.write_u64(open_out, 0, (0 : UInt64))
      if @dx12.dx_d3d12_device2_open_shared_handle(d, sh, @dx12.bytes_ptr(@dx12.iid_d3d12_fence), open_out) == 0 { let _ = @dx12.com_release(@dx12.read_u64(open_out, 0)) }
      let sh2_out = ctx.scratch + (1056 : UInt64)
      @dx12.write_u64(sh2_out, 0, (0 : UInt64))
      if @dx12.dx_d3d12_device2_open_shared_handle_by_name(d, ctx.name_w, 0x10000000, sh2_out) == 0 { @dx12.close_handle(@dx12.read_u64(sh2_out, 0)) }
      @dx12.close_handle(sh)
    }
    let _ = @dx12.com_release(sf)
  }
  let _ = @dx12.dx_d3d12_device2_make_resident(d, 1, ctx.res_arr)
  let _ = @dx12.dx_d3d12_device2_evict(d, 1, ctx.res_arr)
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device2_create_query_heap(d, ctx.qh_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_query_heap), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device2_create_command_signature(d, ctx.csig_desc, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_command_signature), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  ctx.probed.val = ctx.probed.val + 36
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device2_create_pipeline_library(d, (0 : UInt64), (0 : Int64), @dx12.bytes_ptr(@dx12.iid_d3d12_pipeline_library), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  let _ = @dx12.dx_d3d12_device2_set_event_on_multiple_fence_completion(d, ctx.fence_arr, ctx.val_arr, 1, 0, ctx.ev)
  let _ = @dx12.wait_event(ctx.ev, 1000)
  let _ = @dx12.dx_d3d12_device2_set_residency_priority(d, 1, ctx.res_arr, ctx.prio_arr)
  ctx.probed.val = ctx.probed.val + 3
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device2_create_pipeline_state(d, ctx.stream_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_pipeline_state), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  ctx.probed.val = ctx.probed.val + 1
  let _ = @dx12.com_release(d)
}

///|
fn probe_device_v3(ctx : DeviceCtx) -> Unit {
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.com_query_interface(ctx.raw_dev, @dx12.bytes_ptr(@dx12.iid_d3d12_device3), ctx.out_ptr) != 0 {
    return
  }
  let d = @dx12.read_u64(ctx.out_ptr, 0)
  if d == (0 : UInt64) { return }
  let _ = @dx12.dx_d3d12_device3_set_private_data(d, ctx.priv_guid, 4, ctx.priv_val)
  @dx12.write_u32(ctx.priv_sz, 0, (4 : UInt32))
  let _ = @dx12.dx_d3d12_device3_get_private_data(d, ctx.priv_guid, ctx.priv_sz, ctx.scratch)
  let _ = @dx12.dx_d3d12_device3_set_private_data_interface(d, ctx.priv_guid, (0 : UInt64))
  let _ = @dx12.dx_d3d12_device3_set_name(d, ctx.name_w)
  let _ = @dx12.dx_d3d12_device3_get_node_count(d)
  let _ = @dx12.dx_d3d12_device3_get_device_removed_reason(d)
  let _ = @dx12.dx_d3d12_device3_check_feature_support(d, 1, ctx.arch_buf, 16)
  let _ = @dx12.dx_d3d12_device3_get_descriptor_handle_increment_size(d, 0)
  let _ = @dx12.dx_d3d12_device3_get_resource_allocation_info(d, ctx.scratch, 0, 1, ctx.buf_desc)
  let _ = @dx12.dx_d3d12_device3_get_custom_heap_properties(d, ctx.scratch, 0, 1)
  let _ = @dx12.dx_d3d12_device3_get_adapter_luid(d, ctx.scratch)
  @dx12.dx_d3d12_device3_get_copyable_footprints(d, ctx.tex_desc, 0, 1, (0 : Int64), ctx.scratch, ctx.scratch + (256 : UInt64), ctx.scratch + (512 : UInt64), ctx.scratch + (768 : UInt64))
  if ctx.reserved_res != (0 : UInt64) {
    @dx12.write_u32(ctx.scratch, 0, (1 : UInt32))
    @dx12.dx_d3d12_device3_get_resource_tiling(d, ctx.reserved_res, ctx.scratch + (16 : UInt64), ctx.scratch + (32 : UInt64), ctx.scratch + (64 : UInt64), ctx.scratch, 0, ctx.scratch + (128 : UInt64))
  }
  @dx12.dx_d3d12_device3_create_constant_buffer_view(d, ctx.cbv_desc, ctx.cpu_cbv)
  @dx12.dx_d3d12_device3_create_shader_resource_view(d, ctx.buf_def, ctx.srv_desc, ctx.cpu_srv)
  @dx12.dx_d3d12_device3_create_unordered_access_view(d, ctx.buf_uav, (0 : UInt64), ctx.uav_desc, ctx.cpu_uav)
  @dx12.dx_d3d12_device3_create_render_target_view(d, ctx.tex_rt, (0 : UInt64), ctx.cpu_rtv)
  @dx12.dx_d3d12_device3_create_depth_stencil_view(d, ctx.tex_ds, (0 : UInt64), ctx.cpu_dsv)
  @dx12.dx_d3d12_device3_create_sampler(d, ctx.samp_desc, ctx.cpu_samp)
  @dx12.dx_d3d12_device3_copy_descriptors(d, 1, ctx.cpu_arr + (8 : UInt64), ctx.sz_arr, 1, ctx.cpu_arr, ctx.sz_arr, 0)
  @dx12.dx_d3d12_device3_copy_descriptors_simple(d, 1, ctx.cpu_uav, ctx.cpu_srv, 0)
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device3_create_command_queue(d, ctx.q_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_command_queue), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device3_create_command_allocator(d, 0, @dx12.bytes_ptr(@dx12.iid_d3d12_command_allocator), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device3_create_graphics_pipeline_state(d, ctx.gpsd, @dx12.bytes_ptr(@dx12.iid_d3d12_pipeline_state), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device3_create_compute_pipeline_state(d, ctx.cpsd, @dx12.bytes_ptr(@dx12.iid_d3d12_pipeline_state), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device3_create_command_list(d, 0, 0, ctx.ca, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_graphics_command_list), ctx.out_ptr) == 0 { let cl = @dx12.read_u64(ctx.out_ptr, 0); let _ = @dx12.dx_d3d12_graphics_command_list_close(cl); let _ = @dx12.com_release(cl) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device3_create_descriptor_heap(d, ctx.dh_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_descriptor_heap), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device3_create_root_signature(d, 0, ctx.rs_blob, ctx.rs_len, @dx12.bytes_ptr(@dx12.iid_d3d12_root_signature), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device3_create_committed_resource(d, ctx.heap_default, 0, ctx.buf_desc, 0, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device3_create_heap(d, ctx.heap_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_heap), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device3_create_placed_resource(d, ctx.heap_obj, (0 : Int64), ctx.buf_desc, 0, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device3_create_reserved_resource(d, ctx.tiled_desc, 0, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device3_create_fence(d, (0 : Int64), 1, @dx12.bytes_ptr(@dx12.iid_d3d12_fence), ctx.out_ptr) == 0 {
    let sf = @dx12.read_u64(ctx.out_ptr, 0)
    let sh_out = ctx.scratch + (1024 : UInt64)
    @dx12.write_u64(sh_out, 0, (0 : UInt64))
    if @dx12.dx_d3d12_device3_create_shared_handle(d, sf, (0 : UInt64), 0x10000000, ctx.name_w, sh_out) == 0 {
      let sh = @dx12.read_u64(sh_out, 0)
      let open_out = ctx.scratch + (1040 : UInt64)
      @dx12.write_u64(open_out, 0, (0 : UInt64))
      if @dx12.dx_d3d12_device3_open_shared_handle(d, sh, @dx12.bytes_ptr(@dx12.iid_d3d12_fence), open_out) == 0 { let _ = @dx12.com_release(@dx12.read_u64(open_out, 0)) }
      let sh2_out = ctx.scratch + (1056 : UInt64)
      @dx12.write_u64(sh2_out, 0, (0 : UInt64))
      if @dx12.dx_d3d12_device3_open_shared_handle_by_name(d, ctx.name_w, 0x10000000, sh2_out) == 0 { @dx12.close_handle(@dx12.read_u64(sh2_out, 0)) }
      @dx12.close_handle(sh)
    }
    let _ = @dx12.com_release(sf)
  }
  let _ = @dx12.dx_d3d12_device3_make_resident(d, 1, ctx.res_arr)
  let _ = @dx12.dx_d3d12_device3_evict(d, 1, ctx.res_arr)
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device3_create_query_heap(d, ctx.qh_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_query_heap), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device3_create_command_signature(d, ctx.csig_desc, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_command_signature), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  ctx.probed.val = ctx.probed.val + 36
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device3_create_pipeline_library(d, (0 : UInt64), (0 : Int64), @dx12.bytes_ptr(@dx12.iid_d3d12_pipeline_library), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  let _ = @dx12.dx_d3d12_device3_set_event_on_multiple_fence_completion(d, ctx.fence_arr, ctx.val_arr, 1, 0, ctx.ev)
  let _ = @dx12.wait_event(ctx.ev, 1000)
  let _ = @dx12.dx_d3d12_device3_set_residency_priority(d, 1, ctx.res_arr, ctx.prio_arr)
  ctx.probed.val = ctx.probed.val + 3
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device3_create_pipeline_state(d, ctx.stream_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_pipeline_state), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  ctx.probed.val = ctx.probed.val + 1
  ctx.fence_seq = ctx.fence_seq + (1 : Int64)
  if @dx12.dx_d3d12_device3_enqueue_make_resident(d, 0, 1, ctx.res_arr, ctx.fence, ctx.fence_seq) == 0 {
    if @dx12.dx_d3d12_fence_get_completed_value(ctx.fence) < ctx.fence_seq {
      if @dx12.dx_d3d12_fence_set_event_on_completion(ctx.fence, ctx.fence_seq, ctx.ev) == 0 { let _ = @dx12.wait_event(ctx.ev, 1000) }
    }
    let _ = @dx12.dx_d3d12_device3_evict(d, 1, ctx.res_arr)
  }
  ctx.probed.val = ctx.probed.val + 1
  let _ = @dx12.com_release(d)
}

///|
fn probe_device_v4(ctx : DeviceCtx) -> Unit {
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.com_query_interface(ctx.raw_dev, @dx12.bytes_ptr(@dx12.iid_d3d12_device4), ctx.out_ptr) != 0 {
    return
  }
  let d = @dx12.read_u64(ctx.out_ptr, 0)
  if d == (0 : UInt64) { return }
  let _ = @dx12.dx_d3d12_device4_set_private_data(d, ctx.priv_guid, 4, ctx.priv_val)
  @dx12.write_u32(ctx.priv_sz, 0, (4 : UInt32))
  let _ = @dx12.dx_d3d12_device4_get_private_data(d, ctx.priv_guid, ctx.priv_sz, ctx.scratch)
  let _ = @dx12.dx_d3d12_device4_set_private_data_interface(d, ctx.priv_guid, (0 : UInt64))
  let _ = @dx12.dx_d3d12_device4_set_name(d, ctx.name_w)
  let _ = @dx12.dx_d3d12_device4_get_node_count(d)
  let _ = @dx12.dx_d3d12_device4_get_device_removed_reason(d)
  let _ = @dx12.dx_d3d12_device4_check_feature_support(d, 1, ctx.arch_buf, 16)
  let _ = @dx12.dx_d3d12_device4_get_descriptor_handle_increment_size(d, 0)
  let _ = @dx12.dx_d3d12_device4_get_resource_allocation_info(d, ctx.scratch, 0, 1, ctx.buf_desc)
  let _ = @dx12.dx_d3d12_device4_get_custom_heap_properties(d, ctx.scratch, 0, 1)
  let _ = @dx12.dx_d3d12_device4_get_adapter_luid(d, ctx.scratch)
  @dx12.dx_d3d12_device4_get_copyable_footprints(d, ctx.tex_desc, 0, 1, (0 : Int64), ctx.scratch, ctx.scratch + (256 : UInt64), ctx.scratch + (512 : UInt64), ctx.scratch + (768 : UInt64))
  if ctx.reserved_res != (0 : UInt64) {
    @dx12.write_u32(ctx.scratch, 0, (1 : UInt32))
    @dx12.dx_d3d12_device4_get_resource_tiling(d, ctx.reserved_res, ctx.scratch + (16 : UInt64), ctx.scratch + (32 : UInt64), ctx.scratch + (64 : UInt64), ctx.scratch, 0, ctx.scratch + (128 : UInt64))
  }
  @dx12.dx_d3d12_device4_create_constant_buffer_view(d, ctx.cbv_desc, ctx.cpu_cbv)
  @dx12.dx_d3d12_device4_create_shader_resource_view(d, ctx.buf_def, ctx.srv_desc, ctx.cpu_srv)
  @dx12.dx_d3d12_device4_create_unordered_access_view(d, ctx.buf_uav, (0 : UInt64), ctx.uav_desc, ctx.cpu_uav)
  @dx12.dx_d3d12_device4_create_render_target_view(d, ctx.tex_rt, (0 : UInt64), ctx.cpu_rtv)
  @dx12.dx_d3d12_device4_create_depth_stencil_view(d, ctx.tex_ds, (0 : UInt64), ctx.cpu_dsv)
  @dx12.dx_d3d12_device4_create_sampler(d, ctx.samp_desc, ctx.cpu_samp)
  @dx12.dx_d3d12_device4_copy_descriptors(d, 1, ctx.cpu_arr + (8 : UInt64), ctx.sz_arr, 1, ctx.cpu_arr, ctx.sz_arr, 0)
  @dx12.dx_d3d12_device4_copy_descriptors_simple(d, 1, ctx.cpu_uav, ctx.cpu_srv, 0)
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device4_create_command_queue(d, ctx.q_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_command_queue), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device4_create_command_allocator(d, 0, @dx12.bytes_ptr(@dx12.iid_d3d12_command_allocator), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device4_create_graphics_pipeline_state(d, ctx.gpsd, @dx12.bytes_ptr(@dx12.iid_d3d12_pipeline_state), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device4_create_compute_pipeline_state(d, ctx.cpsd, @dx12.bytes_ptr(@dx12.iid_d3d12_pipeline_state), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device4_create_command_list(d, 0, 0, ctx.ca, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_graphics_command_list), ctx.out_ptr) == 0 { let cl = @dx12.read_u64(ctx.out_ptr, 0); let _ = @dx12.dx_d3d12_graphics_command_list_close(cl); let _ = @dx12.com_release(cl) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device4_create_descriptor_heap(d, ctx.dh_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_descriptor_heap), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device4_create_root_signature(d, 0, ctx.rs_blob, ctx.rs_len, @dx12.bytes_ptr(@dx12.iid_d3d12_root_signature), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device4_create_committed_resource(d, ctx.heap_default, 0, ctx.buf_desc, 0, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device4_create_heap(d, ctx.heap_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_heap), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device4_create_placed_resource(d, ctx.heap_obj, (0 : Int64), ctx.buf_desc, 0, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device4_create_reserved_resource(d, ctx.tiled_desc, 0, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device4_create_fence(d, (0 : Int64), 1, @dx12.bytes_ptr(@dx12.iid_d3d12_fence), ctx.out_ptr) == 0 {
    let sf = @dx12.read_u64(ctx.out_ptr, 0)
    let sh_out = ctx.scratch + (1024 : UInt64)
    @dx12.write_u64(sh_out, 0, (0 : UInt64))
    if @dx12.dx_d3d12_device4_create_shared_handle(d, sf, (0 : UInt64), 0x10000000, ctx.name_w, sh_out) == 0 {
      let sh = @dx12.read_u64(sh_out, 0)
      let open_out = ctx.scratch + (1040 : UInt64)
      @dx12.write_u64(open_out, 0, (0 : UInt64))
      if @dx12.dx_d3d12_device4_open_shared_handle(d, sh, @dx12.bytes_ptr(@dx12.iid_d3d12_fence), open_out) == 0 { let _ = @dx12.com_release(@dx12.read_u64(open_out, 0)) }
      let sh2_out = ctx.scratch + (1056 : UInt64)
      @dx12.write_u64(sh2_out, 0, (0 : UInt64))
      if @dx12.dx_d3d12_device4_open_shared_handle_by_name(d, ctx.name_w, 0x10000000, sh2_out) == 0 { @dx12.close_handle(@dx12.read_u64(sh2_out, 0)) }
      @dx12.close_handle(sh)
    }
    let _ = @dx12.com_release(sf)
  }
  let _ = @dx12.dx_d3d12_device4_make_resident(d, 1, ctx.res_arr)
  let _ = @dx12.dx_d3d12_device4_evict(d, 1, ctx.res_arr)
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device4_create_query_heap(d, ctx.qh_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_query_heap), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device4_create_command_signature(d, ctx.csig_desc, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_command_signature), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  ctx.probed.val = ctx.probed.val + 36
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device4_create_pipeline_library(d, (0 : UInt64), (0 : Int64), @dx12.bytes_ptr(@dx12.iid_d3d12_pipeline_library), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  let _ = @dx12.dx_d3d12_device4_set_event_on_multiple_fence_completion(d, ctx.fence_arr, ctx.val_arr, 1, 0, ctx.ev)
  let _ = @dx12.wait_event(ctx.ev, 1000)
  let _ = @dx12.dx_d3d12_device4_set_residency_priority(d, 1, ctx.res_arr, ctx.prio_arr)
  ctx.probed.val = ctx.probed.val + 3
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device4_create_pipeline_state(d, ctx.stream_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_pipeline_state), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  ctx.probed.val = ctx.probed.val + 1
  ctx.fence_seq = ctx.fence_seq + (1 : Int64)
  if @dx12.dx_d3d12_device4_enqueue_make_resident(d, 0, 1, ctx.res_arr, ctx.fence, ctx.fence_seq) == 0 {
    if @dx12.dx_d3d12_fence_get_completed_value(ctx.fence) < ctx.fence_seq {
      if @dx12.dx_d3d12_fence_set_event_on_completion(ctx.fence, ctx.fence_seq, ctx.ev) == 0 { let _ = @dx12.wait_event(ctx.ev, 1000) }
    }
    let _ = @dx12.dx_d3d12_device4_evict(d, 1, ctx.res_arr)
  }
  ctx.probed.val = ctx.probed.val + 1
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device4_create_command_list1(d, 0, 0, 0, @dx12.bytes_ptr(@dx12.iid_d3d12_graphics_command_list), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device4_create_committed_resource1(d, ctx.heap_default, 0, ctx.buf_desc, 0, (0 : UInt64), (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device4_create_heap1(d, ctx.heap_desc, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_heap), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device4_create_reserved_resource1(d, ctx.tiled_desc, 0, (0 : UInt64), (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  let _ = @dx12.dx_d3d12_device4_get_resource_allocation_info1(d, ctx.scratch, 0, 1, ctx.buf_desc, ctx.scratch + (256 : UInt64))
  ctx.probed.val = ctx.probed.val + 5
  let _ = @dx12.com_release(d)
}

///|
fn probe_device_v5(ctx : DeviceCtx) -> Unit {
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.com_query_interface(ctx.raw_dev, @dx12.bytes_ptr(@dx12.iid_d3d12_device5), ctx.out_ptr) != 0 {
    return
  }
  let d = @dx12.read_u64(ctx.out_ptr, 0)
  if d == (0 : UInt64) { return }
  let _ = @dx12.dx_d3d12_device5_set_private_data(d, ctx.priv_guid, 4, ctx.priv_val)
  @dx12.write_u32(ctx.priv_sz, 0, (4 : UInt32))
  let _ = @dx12.dx_d3d12_device5_get_private_data(d, ctx.priv_guid, ctx.priv_sz, ctx.scratch)
  let _ = @dx12.dx_d3d12_device5_set_private_data_interface(d, ctx.priv_guid, (0 : UInt64))
  let _ = @dx12.dx_d3d12_device5_set_name(d, ctx.name_w)
  let _ = @dx12.dx_d3d12_device5_get_node_count(d)
  let _ = @dx12.dx_d3d12_device5_get_device_removed_reason(d)
  let _ = @dx12.dx_d3d12_device5_check_feature_support(d, 1, ctx.arch_buf, 16)
  let _ = @dx12.dx_d3d12_device5_get_descriptor_handle_increment_size(d, 0)
  let _ = @dx12.dx_d3d12_device5_get_resource_allocation_info(d, ctx.scratch, 0, 1, ctx.buf_desc)
  let _ = @dx12.dx_d3d12_device5_get_custom_heap_properties(d, ctx.scratch, 0, 1)
  let _ = @dx12.dx_d3d12_device5_get_adapter_luid(d, ctx.scratch)
  @dx12.dx_d3d12_device5_get_copyable_footprints(d, ctx.tex_desc, 0, 1, (0 : Int64), ctx.scratch, ctx.scratch + (256 : UInt64), ctx.scratch + (512 : UInt64), ctx.scratch + (768 : UInt64))
  if ctx.reserved_res != (0 : UInt64) {
    @dx12.write_u32(ctx.scratch, 0, (1 : UInt32))
    @dx12.dx_d3d12_device5_get_resource_tiling(d, ctx.reserved_res, ctx.scratch + (16 : UInt64), ctx.scratch + (32 : UInt64), ctx.scratch + (64 : UInt64), ctx.scratch, 0, ctx.scratch + (128 : UInt64))
  }
  @dx12.dx_d3d12_device5_create_constant_buffer_view(d, ctx.cbv_desc, ctx.cpu_cbv)
  @dx12.dx_d3d12_device5_create_shader_resource_view(d, ctx.buf_def, ctx.srv_desc, ctx.cpu_srv)
  @dx12.dx_d3d12_device5_create_unordered_access_view(d, ctx.buf_uav, (0 : UInt64), ctx.uav_desc, ctx.cpu_uav)
  @dx12.dx_d3d12_device5_create_render_target_view(d, ctx.tex_rt, (0 : UInt64), ctx.cpu_rtv)
  @dx12.dx_d3d12_device5_create_depth_stencil_view(d, ctx.tex_ds, (0 : UInt64), ctx.cpu_dsv)
  @dx12.dx_d3d12_device5_create_sampler(d, ctx.samp_desc, ctx.cpu_samp)
  @dx12.dx_d3d12_device5_copy_descriptors(d, 1, ctx.cpu_arr + (8 : UInt64), ctx.sz_arr, 1, ctx.cpu_arr, ctx.sz_arr, 0)
  @dx12.dx_d3d12_device5_copy_descriptors_simple(d, 1, ctx.cpu_uav, ctx.cpu_srv, 0)
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device5_create_command_queue(d, ctx.q_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_command_queue), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device5_create_command_allocator(d, 0, @dx12.bytes_ptr(@dx12.iid_d3d12_command_allocator), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device5_create_graphics_pipeline_state(d, ctx.gpsd, @dx12.bytes_ptr(@dx12.iid_d3d12_pipeline_state), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device5_create_compute_pipeline_state(d, ctx.cpsd, @dx12.bytes_ptr(@dx12.iid_d3d12_pipeline_state), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device5_create_command_list(d, 0, 0, ctx.ca, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_graphics_command_list), ctx.out_ptr) == 0 { let cl = @dx12.read_u64(ctx.out_ptr, 0); let _ = @dx12.dx_d3d12_graphics_command_list_close(cl); let _ = @dx12.com_release(cl) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device5_create_descriptor_heap(d, ctx.dh_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_descriptor_heap), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device5_create_root_signature(d, 0, ctx.rs_blob, ctx.rs_len, @dx12.bytes_ptr(@dx12.iid_d3d12_root_signature), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device5_create_committed_resource(d, ctx.heap_default, 0, ctx.buf_desc, 0, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device5_create_heap(d, ctx.heap_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_heap), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device5_create_placed_resource(d, ctx.heap_obj, (0 : Int64), ctx.buf_desc, 0, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device5_create_reserved_resource(d, ctx.tiled_desc, 0, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device5_create_fence(d, (0 : Int64), 1, @dx12.bytes_ptr(@dx12.iid_d3d12_fence), ctx.out_ptr) == 0 {
    let sf = @dx12.read_u64(ctx.out_ptr, 0)
    let sh_out = ctx.scratch + (1024 : UInt64)
    @dx12.write_u64(sh_out, 0, (0 : UInt64))
    if @dx12.dx_d3d12_device5_create_shared_handle(d, sf, (0 : UInt64), 0x10000000, ctx.name_w, sh_out) == 0 {
      let sh = @dx12.read_u64(sh_out, 0)
      let open_out = ctx.scratch + (1040 : UInt64)
      @dx12.write_u64(open_out, 0, (0 : UInt64))
      if @dx12.dx_d3d12_device5_open_shared_handle(d, sh, @dx12.bytes_ptr(@dx12.iid_d3d12_fence), open_out) == 0 { let _ = @dx12.com_release(@dx12.read_u64(open_out, 0)) }
      let sh2_out = ctx.scratch + (1056 : UInt64)
      @dx12.write_u64(sh2_out, 0, (0 : UInt64))
      if @dx12.dx_d3d12_device5_open_shared_handle_by_name(d, ctx.name_w, 0x10000000, sh2_out) == 0 { @dx12.close_handle(@dx12.read_u64(sh2_out, 0)) }
      @dx12.close_handle(sh)
    }
    let _ = @dx12.com_release(sf)
  }
  let _ = @dx12.dx_d3d12_device5_make_resident(d, 1, ctx.res_arr)
  let _ = @dx12.dx_d3d12_device5_evict(d, 1, ctx.res_arr)
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device5_create_query_heap(d, ctx.qh_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_query_heap), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device5_create_command_signature(d, ctx.csig_desc, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_command_signature), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  ctx.probed.val = ctx.probed.val + 36
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device5_create_pipeline_library(d, (0 : UInt64), (0 : Int64), @dx12.bytes_ptr(@dx12.iid_d3d12_pipeline_library), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  let _ = @dx12.dx_d3d12_device5_set_event_on_multiple_fence_completion(d, ctx.fence_arr, ctx.val_arr, 1, 0, ctx.ev)
  let _ = @dx12.wait_event(ctx.ev, 1000)
  let _ = @dx12.dx_d3d12_device5_set_residency_priority(d, 1, ctx.res_arr, ctx.prio_arr)
  ctx.probed.val = ctx.probed.val + 3
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device5_create_pipeline_state(d, ctx.stream_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_pipeline_state), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  ctx.probed.val = ctx.probed.val + 1
  ctx.fence_seq = ctx.fence_seq + (1 : Int64)
  if @dx12.dx_d3d12_device5_enqueue_make_resident(d, 0, 1, ctx.res_arr, ctx.fence, ctx.fence_seq) == 0 {
    if @dx12.dx_d3d12_fence_get_completed_value(ctx.fence) < ctx.fence_seq {
      if @dx12.dx_d3d12_fence_set_event_on_completion(ctx.fence, ctx.fence_seq, ctx.ev) == 0 { let _ = @dx12.wait_event(ctx.ev, 1000) }
    }
    let _ = @dx12.dx_d3d12_device5_evict(d, 1, ctx.res_arr)
  }
  ctx.probed.val = ctx.probed.val + 1
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device5_create_command_list1(d, 0, 0, 0, @dx12.bytes_ptr(@dx12.iid_d3d12_graphics_command_list), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device5_create_committed_resource1(d, ctx.heap_default, 0, ctx.buf_desc, 0, (0 : UInt64), (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device5_create_heap1(d, ctx.heap_desc, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_heap), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device5_create_reserved_resource1(d, ctx.tiled_desc, 0, (0 : UInt64), (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  let _ = @dx12.dx_d3d12_device5_get_resource_allocation_info1(d, ctx.scratch, 0, 1, ctx.buf_desc, ctx.scratch + (256 : UInt64))
  ctx.probed.val = ctx.probed.val + 5
  @dx12.write_u32(ctx.scratch, 0, (0 : UInt32))
  let _ = @dx12.dx_d3d12_device5_enumerate_meta_commands(d, ctx.scratch, (0 : UInt64))
  @dx12.dx_d3d12_device5_get_raytracing_acceleration_structure_prebuild_info(d, ctx.rt_inputs, ctx.rt_prebuild)
  let _ = @dx12.dx_d3d12_device5_check_driver_matching_identifier(d, 0, ctx.rt_ident)
  if ctx.rt_tier > 0 {
    @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
    if @dx12.dx_d3d12_device5_create_state_object(d, ctx.rt_so_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_state_object), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  }
  ctx.probed.val = ctx.probed.val + 4
  let _ = @dx12.com_release(d)
}

///|
fn probe_device_v6(ctx : DeviceCtx) -> Unit {
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.com_query_interface(ctx.raw_dev, @dx12.bytes_ptr(@dx12.iid_d3d12_device6), ctx.out_ptr) != 0 {
    return
  }
  let d = @dx12.read_u64(ctx.out_ptr, 0)
  if d == (0 : UInt64) { return }
  let _ = @dx12.dx_d3d12_device6_set_private_data(d, ctx.priv_guid, 4, ctx.priv_val)
  @dx12.write_u32(ctx.priv_sz, 0, (4 : UInt32))
  let _ = @dx12.dx_d3d12_device6_get_private_data(d, ctx.priv_guid, ctx.priv_sz, ctx.scratch)
  let _ = @dx12.dx_d3d12_device6_set_private_data_interface(d, ctx.priv_guid, (0 : UInt64))
  let _ = @dx12.dx_d3d12_device6_set_name(d, ctx.name_w)
  let _ = @dx12.dx_d3d12_device6_get_node_count(d)
  let _ = @dx12.dx_d3d12_device6_get_device_removed_reason(d)
  let _ = @dx12.dx_d3d12_device6_check_feature_support(d, 1, ctx.arch_buf, 16)
  let _ = @dx12.dx_d3d12_device6_get_descriptor_handle_increment_size(d, 0)
  let _ = @dx12.dx_d3d12_device6_get_resource_allocation_info(d, ctx.scratch, 0, 1, ctx.buf_desc)
  let _ = @dx12.dx_d3d12_device6_get_custom_heap_properties(d, ctx.scratch, 0, 1)
  let _ = @dx12.dx_d3d12_device6_get_adapter_luid(d, ctx.scratch)
  @dx12.dx_d3d12_device6_get_copyable_footprints(d, ctx.tex_desc, 0, 1, (0 : Int64), ctx.scratch, ctx.scratch + (256 : UInt64), ctx.scratch + (512 : UInt64), ctx.scratch + (768 : UInt64))
  if ctx.reserved_res != (0 : UInt64) {
    @dx12.write_u32(ctx.scratch, 0, (1 : UInt32))
    @dx12.dx_d3d12_device6_get_resource_tiling(d, ctx.reserved_res, ctx.scratch + (16 : UInt64), ctx.scratch + (32 : UInt64), ctx.scratch + (64 : UInt64), ctx.scratch, 0, ctx.scratch + (128 : UInt64))
  }
  @dx12.dx_d3d12_device6_create_constant_buffer_view(d, ctx.cbv_desc, ctx.cpu_cbv)
  @dx12.dx_d3d12_device6_create_shader_resource_view(d, ctx.buf_def, ctx.srv_desc, ctx.cpu_srv)
  @dx12.dx_d3d12_device6_create_unordered_access_view(d, ctx.buf_uav, (0 : UInt64), ctx.uav_desc, ctx.cpu_uav)
  @dx12.dx_d3d12_device6_create_render_target_view(d, ctx.tex_rt, (0 : UInt64), ctx.cpu_rtv)
  @dx12.dx_d3d12_device6_create_depth_stencil_view(d, ctx.tex_ds, (0 : UInt64), ctx.cpu_dsv)
  @dx12.dx_d3d12_device6_create_sampler(d, ctx.samp_desc, ctx.cpu_samp)
  @dx12.dx_d3d12_device6_copy_descriptors(d, 1, ctx.cpu_arr + (8 : UInt64), ctx.sz_arr, 1, ctx.cpu_arr, ctx.sz_arr, 0)
  @dx12.dx_d3d12_device6_copy_descriptors_simple(d, 1, ctx.cpu_uav, ctx.cpu_srv, 0)
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device6_create_command_queue(d, ctx.q_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_command_queue), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device6_create_command_allocator(d, 0, @dx12.bytes_ptr(@dx12.iid_d3d12_command_allocator), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device6_create_graphics_pipeline_state(d, ctx.gpsd, @dx12.bytes_ptr(@dx12.iid_d3d12_pipeline_state), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device6_create_compute_pipeline_state(d, ctx.cpsd, @dx12.bytes_ptr(@dx12.iid_d3d12_pipeline_state), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device6_create_command_list(d, 0, 0, ctx.ca, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_graphics_command_list), ctx.out_ptr) == 0 { let cl = @dx12.read_u64(ctx.out_ptr, 0); let _ = @dx12.dx_d3d12_graphics_command_list_close(cl); let _ = @dx12.com_release(cl) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device6_create_descriptor_heap(d, ctx.dh_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_descriptor_heap), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device6_create_root_signature(d, 0, ctx.rs_blob, ctx.rs_len, @dx12.bytes_ptr(@dx12.iid_d3d12_root_signature), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device6_create_committed_resource(d, ctx.heap_default, 0, ctx.buf_desc, 0, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device6_create_heap(d, ctx.heap_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_heap), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device6_create_placed_resource(d, ctx.heap_obj, (0 : Int64), ctx.buf_desc, 0, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device6_create_reserved_resource(d, ctx.tiled_desc, 0, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device6_create_fence(d, (0 : Int64), 1, @dx12.bytes_ptr(@dx12.iid_d3d12_fence), ctx.out_ptr) == 0 {
    let sf = @dx12.read_u64(ctx.out_ptr, 0)
    let sh_out = ctx.scratch + (1024 : UInt64)
    @dx12.write_u64(sh_out, 0, (0 : UInt64))
    if @dx12.dx_d3d12_device6_create_shared_handle(d, sf, (0 : UInt64), 0x10000000, ctx.name_w, sh_out) == 0 {
      let sh = @dx12.read_u64(sh_out, 0)
      let open_out = ctx.scratch + (1040 : UInt64)
      @dx12.write_u64(open_out, 0, (0 : UInt64))
      if @dx12.dx_d3d12_device6_open_shared_handle(d, sh, @dx12.bytes_ptr(@dx12.iid_d3d12_fence), open_out) == 0 { let _ = @dx12.com_release(@dx12.read_u64(open_out, 0)) }
      let sh2_out = ctx.scratch + (1056 : UInt64)
      @dx12.write_u64(sh2_out, 0, (0 : UInt64))
      if @dx12.dx_d3d12_device6_open_shared_handle_by_name(d, ctx.name_w, 0x10000000, sh2_out) == 0 { @dx12.close_handle(@dx12.read_u64(sh2_out, 0)) }
      @dx12.close_handle(sh)
    }
    let _ = @dx12.com_release(sf)
  }
  let _ = @dx12.dx_d3d12_device6_make_resident(d, 1, ctx.res_arr)
  let _ = @dx12.dx_d3d12_device6_evict(d, 1, ctx.res_arr)
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device6_create_query_heap(d, ctx.qh_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_query_heap), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device6_create_command_signature(d, ctx.csig_desc, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_command_signature), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  ctx.probed.val = ctx.probed.val + 36
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device6_create_pipeline_library(d, (0 : UInt64), (0 : Int64), @dx12.bytes_ptr(@dx12.iid_d3d12_pipeline_library), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  let _ = @dx12.dx_d3d12_device6_set_event_on_multiple_fence_completion(d, ctx.fence_arr, ctx.val_arr, 1, 0, ctx.ev)
  let _ = @dx12.wait_event(ctx.ev, 1000)
  let _ = @dx12.dx_d3d12_device6_set_residency_priority(d, 1, ctx.res_arr, ctx.prio_arr)
  ctx.probed.val = ctx.probed.val + 3
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device6_create_pipeline_state(d, ctx.stream_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_pipeline_state), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  ctx.probed.val = ctx.probed.val + 1
  ctx.fence_seq = ctx.fence_seq + (1 : Int64)
  if @dx12.dx_d3d12_device6_enqueue_make_resident(d, 0, 1, ctx.res_arr, ctx.fence, ctx.fence_seq) == 0 {
    if @dx12.dx_d3d12_fence_get_completed_value(ctx.fence) < ctx.fence_seq {
      if @dx12.dx_d3d12_fence_set_event_on_completion(ctx.fence, ctx.fence_seq, ctx.ev) == 0 { let _ = @dx12.wait_event(ctx.ev, 1000) }
    }
    let _ = @dx12.dx_d3d12_device6_evict(d, 1, ctx.res_arr)
  }
  ctx.probed.val = ctx.probed.val + 1
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device6_create_command_list1(d, 0, 0, 0, @dx12.bytes_ptr(@dx12.iid_d3d12_graphics_command_list), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device6_create_committed_resource1(d, ctx.heap_default, 0, ctx.buf_desc, 0, (0 : UInt64), (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device6_create_heap1(d, ctx.heap_desc, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_heap), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device6_create_reserved_resource1(d, ctx.tiled_desc, 0, (0 : UInt64), (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  let _ = @dx12.dx_d3d12_device6_get_resource_allocation_info1(d, ctx.scratch, 0, 1, ctx.buf_desc, ctx.scratch + (256 : UInt64))
  ctx.probed.val = ctx.probed.val + 5
  @dx12.write_u32(ctx.scratch, 0, (0 : UInt32))
  let _ = @dx12.dx_d3d12_device6_enumerate_meta_commands(d, ctx.scratch, (0 : UInt64))
  @dx12.dx_d3d12_device6_get_raytracing_acceleration_structure_prebuild_info(d, ctx.rt_inputs, ctx.rt_prebuild)
  let _ = @dx12.dx_d3d12_device6_check_driver_matching_identifier(d, 0, ctx.rt_ident)
  if ctx.rt_tier > 0 {
    @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
    if @dx12.dx_d3d12_device6_create_state_object(d, ctx.rt_so_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_state_object), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  }
  ctx.probed.val = ctx.probed.val + 4
  let _ = @dx12.dx_d3d12_device6_set_background_processing_mode(d, 0, 0, (0 : UInt64), ctx.scratch)
  ctx.probed.val = ctx.probed.val + 1
  let _ = @dx12.com_release(d)
}

///|
fn probe_device_v7(ctx : DeviceCtx) -> Unit {
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.com_query_interface(ctx.raw_dev, @dx12.bytes_ptr(@dx12.iid_d3d12_device7), ctx.out_ptr) != 0 {
    return
  }
  let d = @dx12.read_u64(ctx.out_ptr, 0)
  if d == (0 : UInt64) { return }
  let _ = @dx12.dx_d3d12_device7_set_private_data(d, ctx.priv_guid, 4, ctx.priv_val)
  @dx12.write_u32(ctx.priv_sz, 0, (4 : UInt32))
  let _ = @dx12.dx_d3d12_device7_get_private_data(d, ctx.priv_guid, ctx.priv_sz, ctx.scratch)
  let _ = @dx12.dx_d3d12_device7_set_private_data_interface(d, ctx.priv_guid, (0 : UInt64))
  let _ = @dx12.dx_d3d12_device7_set_name(d, ctx.name_w)
  let _ = @dx12.dx_d3d12_device7_get_node_count(d)
  let _ = @dx12.dx_d3d12_device7_get_device_removed_reason(d)
  let _ = @dx12.dx_d3d12_device7_check_feature_support(d, 1, ctx.arch_buf, 16)
  let _ = @dx12.dx_d3d12_device7_get_descriptor_handle_increment_size(d, 0)
  let _ = @dx12.dx_d3d12_device7_get_resource_allocation_info(d, ctx.scratch, 0, 1, ctx.buf_desc)
  let _ = @dx12.dx_d3d12_device7_get_custom_heap_properties(d, ctx.scratch, 0, 1)
  let _ = @dx12.dx_d3d12_device7_get_adapter_luid(d, ctx.scratch)
  @dx12.dx_d3d12_device7_get_copyable_footprints(d, ctx.tex_desc, 0, 1, (0 : Int64), ctx.scratch, ctx.scratch + (256 : UInt64), ctx.scratch + (512 : UInt64), ctx.scratch + (768 : UInt64))
  if ctx.reserved_res != (0 : UInt64) {
    @dx12.write_u32(ctx.scratch, 0, (1 : UInt32))
    @dx12.dx_d3d12_device7_get_resource_tiling(d, ctx.reserved_res, ctx.scratch + (16 : UInt64), ctx.scratch + (32 : UInt64), ctx.scratch + (64 : UInt64), ctx.scratch, 0, ctx.scratch + (128 : UInt64))
  }
  @dx12.dx_d3d12_device7_create_constant_buffer_view(d, ctx.cbv_desc, ctx.cpu_cbv)
  @dx12.dx_d3d12_device7_create_shader_resource_view(d, ctx.buf_def, ctx.srv_desc, ctx.cpu_srv)
  @dx12.dx_d3d12_device7_create_unordered_access_view(d, ctx.buf_uav, (0 : UInt64), ctx.uav_desc, ctx.cpu_uav)
  @dx12.dx_d3d12_device7_create_render_target_view(d, ctx.tex_rt, (0 : UInt64), ctx.cpu_rtv)
  @dx12.dx_d3d12_device7_create_depth_stencil_view(d, ctx.tex_ds, (0 : UInt64), ctx.cpu_dsv)
  @dx12.dx_d3d12_device7_create_sampler(d, ctx.samp_desc, ctx.cpu_samp)
  @dx12.dx_d3d12_device7_copy_descriptors(d, 1, ctx.cpu_arr + (8 : UInt64), ctx.sz_arr, 1, ctx.cpu_arr, ctx.sz_arr, 0)
  @dx12.dx_d3d12_device7_copy_descriptors_simple(d, 1, ctx.cpu_uav, ctx.cpu_srv, 0)
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device7_create_command_queue(d, ctx.q_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_command_queue), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device7_create_command_allocator(d, 0, @dx12.bytes_ptr(@dx12.iid_d3d12_command_allocator), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device7_create_graphics_pipeline_state(d, ctx.gpsd, @dx12.bytes_ptr(@dx12.iid_d3d12_pipeline_state), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device7_create_compute_pipeline_state(d, ctx.cpsd, @dx12.bytes_ptr(@dx12.iid_d3d12_pipeline_state), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device7_create_command_list(d, 0, 0, ctx.ca, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_graphics_command_list), ctx.out_ptr) == 0 { let cl = @dx12.read_u64(ctx.out_ptr, 0); let _ = @dx12.dx_d3d12_graphics_command_list_close(cl); let _ = @dx12.com_release(cl) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device7_create_descriptor_heap(d, ctx.dh_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_descriptor_heap), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device7_create_root_signature(d, 0, ctx.rs_blob, ctx.rs_len, @dx12.bytes_ptr(@dx12.iid_d3d12_root_signature), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device7_create_committed_resource(d, ctx.heap_default, 0, ctx.buf_desc, 0, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device7_create_heap(d, ctx.heap_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_heap), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device7_create_placed_resource(d, ctx.heap_obj, (0 : Int64), ctx.buf_desc, 0, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device7_create_reserved_resource(d, ctx.tiled_desc, 0, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device7_create_fence(d, (0 : Int64), 1, @dx12.bytes_ptr(@dx12.iid_d3d12_fence), ctx.out_ptr) == 0 {
    let sf = @dx12.read_u64(ctx.out_ptr, 0)
    let sh_out = ctx.scratch + (1024 : UInt64)
    @dx12.write_u64(sh_out, 0, (0 : UInt64))
    if @dx12.dx_d3d12_device7_create_shared_handle(d, sf, (0 : UInt64), 0x10000000, ctx.name_w, sh_out) == 0 {
      let sh = @dx12.read_u64(sh_out, 0)
      let open_out = ctx.scratch + (1040 : UInt64)
      @dx12.write_u64(open_out, 0, (0 : UInt64))
      if @dx12.dx_d3d12_device7_open_shared_handle(d, sh, @dx12.bytes_ptr(@dx12.iid_d3d12_fence), open_out) == 0 { let _ = @dx12.com_release(@dx12.read_u64(open_out, 0)) }
      let sh2_out = ctx.scratch + (1056 : UInt64)
      @dx12.write_u64(sh2_out, 0, (0 : UInt64))
      if @dx12.dx_d3d12_device7_open_shared_handle_by_name(d, ctx.name_w, 0x10000000, sh2_out) == 0 { @dx12.close_handle(@dx12.read_u64(sh2_out, 0)) }
      @dx12.close_handle(sh)
    }
    let _ = @dx12.com_release(sf)
  }
  let _ = @dx12.dx_d3d12_device7_make_resident(d, 1, ctx.res_arr)
  let _ = @dx12.dx_d3d12_device7_evict(d, 1, ctx.res_arr)
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device7_create_query_heap(d, ctx.qh_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_query_heap), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device7_create_command_signature(d, ctx.csig_desc, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_command_signature), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  ctx.probed.val = ctx.probed.val + 36
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device7_create_pipeline_library(d, (0 : UInt64), (0 : Int64), @dx12.bytes_ptr(@dx12.iid_d3d12_pipeline_library), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  let _ = @dx12.dx_d3d12_device7_set_event_on_multiple_fence_completion(d, ctx.fence_arr, ctx.val_arr, 1, 0, ctx.ev)
  let _ = @dx12.wait_event(ctx.ev, 1000)
  let _ = @dx12.dx_d3d12_device7_set_residency_priority(d, 1, ctx.res_arr, ctx.prio_arr)
  ctx.probed.val = ctx.probed.val + 3
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device7_create_pipeline_state(d, ctx.stream_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_pipeline_state), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  ctx.probed.val = ctx.probed.val + 1
  ctx.fence_seq = ctx.fence_seq + (1 : Int64)
  if @dx12.dx_d3d12_device7_enqueue_make_resident(d, 0, 1, ctx.res_arr, ctx.fence, ctx.fence_seq) == 0 {
    if @dx12.dx_d3d12_fence_get_completed_value(ctx.fence) < ctx.fence_seq {
      if @dx12.dx_d3d12_fence_set_event_on_completion(ctx.fence, ctx.fence_seq, ctx.ev) == 0 { let _ = @dx12.wait_event(ctx.ev, 1000) }
    }
    let _ = @dx12.dx_d3d12_device7_evict(d, 1, ctx.res_arr)
  }
  ctx.probed.val = ctx.probed.val + 1
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device7_create_command_list1(d, 0, 0, 0, @dx12.bytes_ptr(@dx12.iid_d3d12_graphics_command_list), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device7_create_committed_resource1(d, ctx.heap_default, 0, ctx.buf_desc, 0, (0 : UInt64), (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device7_create_heap1(d, ctx.heap_desc, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_heap), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device7_create_reserved_resource1(d, ctx.tiled_desc, 0, (0 : UInt64), (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  let _ = @dx12.dx_d3d12_device7_get_resource_allocation_info1(d, ctx.scratch, 0, 1, ctx.buf_desc, ctx.scratch + (256 : UInt64))
  ctx.probed.val = ctx.probed.val + 5
  @dx12.write_u32(ctx.scratch, 0, (0 : UInt32))
  let _ = @dx12.dx_d3d12_device7_enumerate_meta_commands(d, ctx.scratch, (0 : UInt64))
  @dx12.dx_d3d12_device7_get_raytracing_acceleration_structure_prebuild_info(d, ctx.rt_inputs, ctx.rt_prebuild)
  let _ = @dx12.dx_d3d12_device7_check_driver_matching_identifier(d, 0, ctx.rt_ident)
  if ctx.rt_tier > 0 {
    @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
    if @dx12.dx_d3d12_device7_create_state_object(d, ctx.rt_so_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_state_object), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  }
  ctx.probed.val = ctx.probed.val + 4
  let _ = @dx12.dx_d3d12_device7_set_background_processing_mode(d, 0, 0, (0 : UInt64), ctx.scratch)
  ctx.probed.val = ctx.probed.val + 1
  if ctx.rt_so != (0 : UInt64) {
    @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
    if @dx12.dx_d3d12_device7_add_to_state_object(d, ctx.rt_add_desc, ctx.rt_so, @dx12.bytes_ptr(@dx12.iid_d3d12_state_object), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  }
  ctx.probed.val = ctx.probed.val + 1
  let _ = @dx12.com_release(d)
}

///|
fn probe_device_v8(ctx : DeviceCtx) -> Unit {
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.com_query_interface(ctx.raw_dev, @dx12.bytes_ptr(@dx12.iid_d3d12_device8), ctx.out_ptr) != 0 {
    return
  }
  let d = @dx12.read_u64(ctx.out_ptr, 0)
  if d == (0 : UInt64) { return }
  let _ = @dx12.dx_d3d12_device8_set_private_data(d, ctx.priv_guid, 4, ctx.priv_val)
  @dx12.write_u32(ctx.priv_sz, 0, (4 : UInt32))
  let _ = @dx12.dx_d3d12_device8_get_private_data(d, ctx.priv_guid, ctx.priv_sz, ctx.scratch)
  let _ = @dx12.dx_d3d12_device8_set_private_data_interface(d, ctx.priv_guid, (0 : UInt64))
  let _ = @dx12.dx_d3d12_device8_set_name(d, ctx.name_w)
  let _ = @dx12.dx_d3d12_device8_get_node_count(d)
  let _ = @dx12.dx_d3d12_device8_get_device_removed_reason(d)
  let _ = @dx12.dx_d3d12_device8_check_feature_support(d, 1, ctx.arch_buf, 16)
  let _ = @dx12.dx_d3d12_device8_get_descriptor_handle_increment_size(d, 0)
  let _ = @dx12.dx_d3d12_device8_get_resource_allocation_info(d, ctx.scratch, 0, 1, ctx.buf_desc)
  let _ = @dx12.dx_d3d12_device8_get_custom_heap_properties(d, ctx.scratch, 0, 1)
  let _ = @dx12.dx_d3d12_device8_get_adapter_luid(d, ctx.scratch)
  @dx12.dx_d3d12_device8_get_copyable_footprints(d, ctx.tex_desc, 0, 1, (0 : Int64), ctx.scratch, ctx.scratch + (256 : UInt64), ctx.scratch + (512 : UInt64), ctx.scratch + (768 : UInt64))
  if ctx.reserved_res != (0 : UInt64) {
    @dx12.write_u32(ctx.scratch, 0, (1 : UInt32))
    @dx12.dx_d3d12_device8_get_resource_tiling(d, ctx.reserved_res, ctx.scratch + (16 : UInt64), ctx.scratch + (32 : UInt64), ctx.scratch + (64 : UInt64), ctx.scratch, 0, ctx.scratch + (128 : UInt64))
  }
  @dx12.dx_d3d12_device8_create_constant_buffer_view(d, ctx.cbv_desc, ctx.cpu_cbv)
  @dx12.dx_d3d12_device8_create_shader_resource_view(d, ctx.buf_def, ctx.srv_desc, ctx.cpu_srv)
  @dx12.dx_d3d12_device8_create_unordered_access_view(d, ctx.buf_uav, (0 : UInt64), ctx.uav_desc, ctx.cpu_uav)
  @dx12.dx_d3d12_device8_create_render_target_view(d, ctx.tex_rt, (0 : UInt64), ctx.cpu_rtv)
  @dx12.dx_d3d12_device8_create_depth_stencil_view(d, ctx.tex_ds, (0 : UInt64), ctx.cpu_dsv)
  @dx12.dx_d3d12_device8_create_sampler(d, ctx.samp_desc, ctx.cpu_samp)
  @dx12.dx_d3d12_device8_copy_descriptors(d, 1, ctx.cpu_arr + (8 : UInt64), ctx.sz_arr, 1, ctx.cpu_arr, ctx.sz_arr, 0)
  @dx12.dx_d3d12_device8_copy_descriptors_simple(d, 1, ctx.cpu_uav, ctx.cpu_srv, 0)
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device8_create_command_queue(d, ctx.q_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_command_queue), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device8_create_command_allocator(d, 0, @dx12.bytes_ptr(@dx12.iid_d3d12_command_allocator), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device8_create_graphics_pipeline_state(d, ctx.gpsd, @dx12.bytes_ptr(@dx12.iid_d3d12_pipeline_state), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device8_create_compute_pipeline_state(d, ctx.cpsd, @dx12.bytes_ptr(@dx12.iid_d3d12_pipeline_state), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device8_create_command_list(d, 0, 0, ctx.ca, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_graphics_command_list), ctx.out_ptr) == 0 { let cl = @dx12.read_u64(ctx.out_ptr, 0); let _ = @dx12.dx_d3d12_graphics_command_list_close(cl); let _ = @dx12.com_release(cl) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device8_create_descriptor_heap(d, ctx.dh_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_descriptor_heap), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device8_create_root_signature(d, 0, ctx.rs_blob, ctx.rs_len, @dx12.bytes_ptr(@dx12.iid_d3d12_root_signature), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device8_create_committed_resource(d, ctx.heap_default, 0, ctx.buf_desc, 0, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device8_create_heap(d, ctx.heap_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_heap), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device8_create_placed_resource(d, ctx.heap_obj, (0 : Int64), ctx.buf_desc, 0, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device8_create_reserved_resource(d, ctx.tiled_desc, 0, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device8_create_fence(d, (0 : Int64), 1, @dx12.bytes_ptr(@dx12.iid_d3d12_fence), ctx.out_ptr) == 0 {
    let sf = @dx12.read_u64(ctx.out_ptr, 0)
    let sh_out = ctx.scratch + (1024 : UInt64)
    @dx12.write_u64(sh_out, 0, (0 : UInt64))
    if @dx12.dx_d3d12_device8_create_shared_handle(d, sf, (0 : UInt64), 0x10000000, ctx.name_w, sh_out) == 0 {
      let sh = @dx12.read_u64(sh_out, 0)
      let open_out = ctx.scratch + (1040 : UInt64)
      @dx12.write_u64(open_out, 0, (0 : UInt64))
      if @dx12.dx_d3d12_device8_open_shared_handle(d, sh, @dx12.bytes_ptr(@dx12.iid_d3d12_fence), open_out) == 0 { let _ = @dx12.com_release(@dx12.read_u64(open_out, 0)) }
      let sh2_out = ctx.scratch + (1056 : UInt64)
      @dx12.write_u64(sh2_out, 0, (0 : UInt64))
      if @dx12.dx_d3d12_device8_open_shared_handle_by_name(d, ctx.name_w, 0x10000000, sh2_out) == 0 { @dx12.close_handle(@dx12.read_u64(sh2_out, 0)) }
      @dx12.close_handle(sh)
    }
    let _ = @dx12.com_release(sf)
  }
  let _ = @dx12.dx_d3d12_device8_make_resident(d, 1, ctx.res_arr)
  let _ = @dx12.dx_d3d12_device8_evict(d, 1, ctx.res_arr)
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device8_create_query_heap(d, ctx.qh_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_query_heap), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device8_create_command_signature(d, ctx.csig_desc, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_command_signature), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  ctx.probed.val = ctx.probed.val + 36
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device8_create_pipeline_library(d, (0 : UInt64), (0 : Int64), @dx12.bytes_ptr(@dx12.iid_d3d12_pipeline_library), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  let _ = @dx12.dx_d3d12_device8_set_event_on_multiple_fence_completion(d, ctx.fence_arr, ctx.val_arr, 1, 0, ctx.ev)
  let _ = @dx12.wait_event(ctx.ev, 1000)
  let _ = @dx12.dx_d3d12_device8_set_residency_priority(d, 1, ctx.res_arr, ctx.prio_arr)
  ctx.probed.val = ctx.probed.val + 3
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device8_create_pipeline_state(d, ctx.stream_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_pipeline_state), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  ctx.probed.val = ctx.probed.val + 1
  ctx.fence_seq = ctx.fence_seq + (1 : Int64)
  if @dx12.dx_d3d12_device8_enqueue_make_resident(d, 0, 1, ctx.res_arr, ctx.fence, ctx.fence_seq) == 0 {
    if @dx12.dx_d3d12_fence_get_completed_value(ctx.fence) < ctx.fence_seq {
      if @dx12.dx_d3d12_fence_set_event_on_completion(ctx.fence, ctx.fence_seq, ctx.ev) == 0 { let _ = @dx12.wait_event(ctx.ev, 1000) }
    }
    let _ = @dx12.dx_d3d12_device8_evict(d, 1, ctx.res_arr)
  }
  ctx.probed.val = ctx.probed.val + 1
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device8_create_command_list1(d, 0, 0, 0, @dx12.bytes_ptr(@dx12.iid_d3d12_graphics_command_list), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device8_create_committed_resource1(d, ctx.heap_default, 0, ctx.buf_desc, 0, (0 : UInt64), (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device8_create_heap1(d, ctx.heap_desc, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_heap), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device8_create_reserved_resource1(d, ctx.tiled_desc, 0, (0 : UInt64), (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  let _ = @dx12.dx_d3d12_device8_get_resource_allocation_info1(d, ctx.scratch, 0, 1, ctx.buf_desc, ctx.scratch + (256 : UInt64))
  ctx.probed.val = ctx.probed.val + 5
  @dx12.write_u32(ctx.scratch, 0, (0 : UInt32))
  let _ = @dx12.dx_d3d12_device8_enumerate_meta_commands(d, ctx.scratch, (0 : UInt64))
  @dx12.dx_d3d12_device8_get_raytracing_acceleration_structure_prebuild_info(d, ctx.rt_inputs, ctx.rt_prebuild)
  let _ = @dx12.dx_d3d12_device8_check_driver_matching_identifier(d, 0, ctx.rt_ident)
  if ctx.rt_tier > 0 {
    @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
    if @dx12.dx_d3d12_device8_create_state_object(d, ctx.rt_so_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_state_object), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  }
  ctx.probed.val = ctx.probed.val + 4
  let _ = @dx12.dx_d3d12_device8_set_background_processing_mode(d, 0, 0, (0 : UInt64), ctx.scratch)
  ctx.probed.val = ctx.probed.val + 1
  if ctx.rt_so != (0 : UInt64) {
    @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
    if @dx12.dx_d3d12_device8_add_to_state_object(d, ctx.rt_add_desc, ctx.rt_so, @dx12.bytes_ptr(@dx12.iid_d3d12_state_object), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  }
  ctx.probed.val = ctx.probed.val + 1
  let _ = @dx12.dx_d3d12_device8_get_resource_allocation_info2(d, ctx.scratch, 0, 1, ctx.buf_desc, ctx.scratch + (256 : UInt64))
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device8_create_committed_resource2(d, ctx.heap_default, 0, ctx.tex_desc1, 0, (0 : UInt64), (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device8_create_placed_resource1(d, ctx.heap_obj, (0 : Int64), ctx.tex_desc1, 0, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.dx_d3d12_device8_get_copyable_footprints1(d, ctx.tex_desc1, 0, 1, (0 : Int64), ctx.scratch, ctx.scratch + (256 : UInt64), ctx.scratch + (512 : UInt64), ctx.scratch + (768 : UInt64))
  ctx.probed.val = ctx.probed.val + 4
  let _ = @dx12.com_release(d)
}

///|
fn probe_device_v9(ctx : DeviceCtx) -> Unit {
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.com_query_interface(ctx.raw_dev, @dx12.bytes_ptr(@dx12.iid_d3d12_device9), ctx.out_ptr) != 0 {
    return
  }
  let d = @dx12.read_u64(ctx.out_ptr, 0)
  if d == (0 : UInt64) { return }
  let _ = @dx12.dx_d3d12_device9_set_private_data(d, ctx.priv_guid, 4, ctx.priv_val)
  @dx12.write_u32(ctx.priv_sz, 0, (4 : UInt32))
  let _ = @dx12.dx_d3d12_device9_get_private_data(d, ctx.priv_guid, ctx.priv_sz, ctx.scratch)
  let _ = @dx12.dx_d3d12_device9_set_private_data_interface(d, ctx.priv_guid, (0 : UInt64))
  let _ = @dx12.dx_d3d12_device9_set_name(d, ctx.name_w)
  let _ = @dx12.dx_d3d12_device9_get_node_count(d)
  let _ = @dx12.dx_d3d12_device9_get_device_removed_reason(d)
  let _ = @dx12.dx_d3d12_device9_check_feature_support(d, 1, ctx.arch_buf, 16)
  let _ = @dx12.dx_d3d12_device9_get_descriptor_handle_increment_size(d, 0)
  let _ = @dx12.dx_d3d12_device9_get_resource_allocation_info(d, ctx.scratch, 0, 1, ctx.buf_desc)
  let _ = @dx12.dx_d3d12_device9_get_custom_heap_properties(d, ctx.scratch, 0, 1)
  let _ = @dx12.dx_d3d12_device9_get_adapter_luid(d, ctx.scratch)
  @dx12.dx_d3d12_device9_get_copyable_footprints(d, ctx.tex_desc, 0, 1, (0 : Int64), ctx.scratch, ctx.scratch + (256 : UInt64), ctx.scratch + (512 : UInt64), ctx.scratch + (768 : UInt64))
  if ctx.reserved_res != (0 : UInt64) {
    @dx12.write_u32(ctx.scratch, 0, (1 : UInt32))
    @dx12.dx_d3d12_device9_get_resource_tiling(d, ctx.reserved_res, ctx.scratch + (16 : UInt64), ctx.scratch + (32 : UInt64), ctx.scratch + (64 : UInt64), ctx.scratch, 0, ctx.scratch + (128 : UInt64))
  }
  @dx12.dx_d3d12_device9_create_constant_buffer_view(d, ctx.cbv_desc, ctx.cpu_cbv)
  @dx12.dx_d3d12_device9_create_shader_resource_view(d, ctx.buf_def, ctx.srv_desc, ctx.cpu_srv)
  @dx12.dx_d3d12_device9_create_unordered_access_view(d, ctx.buf_uav, (0 : UInt64), ctx.uav_desc, ctx.cpu_uav)
  @dx12.dx_d3d12_device9_create_render_target_view(d, ctx.tex_rt, (0 : UInt64), ctx.cpu_rtv)
  @dx12.dx_d3d12_device9_create_depth_stencil_view(d, ctx.tex_ds, (0 : UInt64), ctx.cpu_dsv)
  @dx12.dx_d3d12_device9_create_sampler(d, ctx.samp_desc, ctx.cpu_samp)
  @dx12.dx_d3d12_device9_copy_descriptors(d, 1, ctx.cpu_arr + (8 : UInt64), ctx.sz_arr, 1, ctx.cpu_arr, ctx.sz_arr, 0)
  @dx12.dx_d3d12_device9_copy_descriptors_simple(d, 1, ctx.cpu_uav, ctx.cpu_srv, 0)
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device9_create_command_queue(d, ctx.q_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_command_queue), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device9_create_command_allocator(d, 0, @dx12.bytes_ptr(@dx12.iid_d3d12_command_allocator), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device9_create_graphics_pipeline_state(d, ctx.gpsd, @dx12.bytes_ptr(@dx12.iid_d3d12_pipeline_state), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device9_create_compute_pipeline_state(d, ctx.cpsd, @dx12.bytes_ptr(@dx12.iid_d3d12_pipeline_state), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device9_create_command_list(d, 0, 0, ctx.ca, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_graphics_command_list), ctx.out_ptr) == 0 { let cl = @dx12.read_u64(ctx.out_ptr, 0); let _ = @dx12.dx_d3d12_graphics_command_list_close(cl); let _ = @dx12.com_release(cl) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device9_create_descriptor_heap(d, ctx.dh_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_descriptor_heap), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device9_create_root_signature(d, 0, ctx.rs_blob, ctx.rs_len, @dx12.bytes_ptr(@dx12.iid_d3d12_root_signature), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device9_create_committed_resource(d, ctx.heap_default, 0, ctx.buf_desc, 0, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device9_create_heap(d, ctx.heap_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_heap), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device9_create_placed_resource(d, ctx.heap_obj, (0 : Int64), ctx.buf_desc, 0, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device9_create_reserved_resource(d, ctx.tiled_desc, 0, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device9_create_fence(d, (0 : Int64), 1, @dx12.bytes_ptr(@dx12.iid_d3d12_fence), ctx.out_ptr) == 0 {
    let sf = @dx12.read_u64(ctx.out_ptr, 0)
    let sh_out = ctx.scratch + (1024 : UInt64)
    @dx12.write_u64(sh_out, 0, (0 : UInt64))
    if @dx12.dx_d3d12_device9_create_shared_handle(d, sf, (0 : UInt64), 0x10000000, ctx.name_w, sh_out) == 0 {
      let sh = @dx12.read_u64(sh_out, 0)
      let open_out = ctx.scratch + (1040 : UInt64)
      @dx12.write_u64(open_out, 0, (0 : UInt64))
      if @dx12.dx_d3d12_device9_open_shared_handle(d, sh, @dx12.bytes_ptr(@dx12.iid_d3d12_fence), open_out) == 0 { let _ = @dx12.com_release(@dx12.read_u64(open_out, 0)) }
      let sh2_out = ctx.scratch + (1056 : UInt64)
      @dx12.write_u64(sh2_out, 0, (0 : UInt64))
      if @dx12.dx_d3d12_device9_open_shared_handle_by_name(d, ctx.name_w, 0x10000000, sh2_out) == 0 { @dx12.close_handle(@dx12.read_u64(sh2_out, 0)) }
      @dx12.close_handle(sh)
    }
    let _ = @dx12.com_release(sf)
  }
  let _ = @dx12.dx_d3d12_device9_make_resident(d, 1, ctx.res_arr)
  let _ = @dx12.dx_d3d12_device9_evict(d, 1, ctx.res_arr)
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device9_create_query_heap(d, ctx.qh_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_query_heap), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device9_create_command_signature(d, ctx.csig_desc, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_command_signature), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  ctx.probed.val = ctx.probed.val + 36
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device9_create_pipeline_library(d, (0 : UInt64), (0 : Int64), @dx12.bytes_ptr(@dx12.iid_d3d12_pipeline_library), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  let _ = @dx12.dx_d3d12_device9_set_event_on_multiple_fence_completion(d, ctx.fence_arr, ctx.val_arr, 1, 0, ctx.ev)
  let _ = @dx12.wait_event(ctx.ev, 1000)
  let _ = @dx12.dx_d3d12_device9_set_residency_priority(d, 1, ctx.res_arr, ctx.prio_arr)
  ctx.probed.val = ctx.probed.val + 3
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device9_create_pipeline_state(d, ctx.stream_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_pipeline_state), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  ctx.probed.val = ctx.probed.val + 1
  ctx.fence_seq = ctx.fence_seq + (1 : Int64)
  if @dx12.dx_d3d12_device9_enqueue_make_resident(d, 0, 1, ctx.res_arr, ctx.fence, ctx.fence_seq) == 0 {
    if @dx12.dx_d3d12_fence_get_completed_value(ctx.fence) < ctx.fence_seq {
      if @dx12.dx_d3d12_fence_set_event_on_completion(ctx.fence, ctx.fence_seq, ctx.ev) == 0 { let _ = @dx12.wait_event(ctx.ev, 1000) }
    }
    let _ = @dx12.dx_d3d12_device9_evict(d, 1, ctx.res_arr)
  }
  ctx.probed.val = ctx.probed.val + 1
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device9_create_command_list1(d, 0, 0, 0, @dx12.bytes_ptr(@dx12.iid_d3d12_graphics_command_list), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device9_create_committed_resource1(d, ctx.heap_default, 0, ctx.buf_desc, 0, (0 : UInt64), (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device9_create_heap1(d, ctx.heap_desc, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_heap), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device9_create_reserved_resource1(d, ctx.tiled_desc, 0, (0 : UInt64), (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  let _ = @dx12.dx_d3d12_device9_get_resource_allocation_info1(d, ctx.scratch, 0, 1, ctx.buf_desc, ctx.scratch + (256 : UInt64))
  ctx.probed.val = ctx.probed.val + 5
  @dx12.write_u32(ctx.scratch, 0, (0 : UInt32))
  let _ = @dx12.dx_d3d12_device9_enumerate_meta_commands(d, ctx.scratch, (0 : UInt64))
  @dx12.dx_d3d12_device9_get_raytracing_acceleration_structure_prebuild_info(d, ctx.rt_inputs, ctx.rt_prebuild)
  let _ = @dx12.dx_d3d12_device9_check_driver_matching_identifier(d, 0, ctx.rt_ident)
  if ctx.rt_tier > 0 {
    @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
    if @dx12.dx_d3d12_device9_create_state_object(d, ctx.rt_so_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_state_object), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  }
  ctx.probed.val = ctx.probed.val + 4
  let _ = @dx12.dx_d3d12_device9_set_background_processing_mode(d, 0, 0, (0 : UInt64), ctx.scratch)
  ctx.probed.val = ctx.probed.val + 1
  if ctx.rt_so != (0 : UInt64) {
    @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
    if @dx12.dx_d3d12_device9_add_to_state_object(d, ctx.rt_add_desc, ctx.rt_so, @dx12.bytes_ptr(@dx12.iid_d3d12_state_object), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  }
  ctx.probed.val = ctx.probed.val + 1
  let _ = @dx12.dx_d3d12_device9_get_resource_allocation_info2(d, ctx.scratch, 0, 1, ctx.buf_desc, ctx.scratch + (256 : UInt64))
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device9_create_committed_resource2(d, ctx.heap_default, 0, ctx.tex_desc1, 0, (0 : UInt64), (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device9_create_placed_resource1(d, ctx.heap_obj, (0 : Int64), ctx.tex_desc1, 0, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.dx_d3d12_device9_get_copyable_footprints1(d, ctx.tex_desc1, 0, 1, (0 : Int64), ctx.scratch, ctx.scratch + (256 : UInt64), ctx.scratch + (512 : UInt64), ctx.scratch + (768 : UInt64))
  ctx.probed.val = ctx.probed.val + 4
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device9_create_shader_cache_session(d, ctx.cache_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_shader_cache_session), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  let _ = @dx12.dx_d3d12_device9_shader_cache_control(d, 1, 1)
  let _ = @dx12.dx_d3d12_device9_shader_cache_control(d, 1, 2)
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device9_create_command_queue1(d, ctx.q_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_command_queue), @dx12.bytes_ptr(@dx12.iid_d3d12_command_queue), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  ctx.probed.val = ctx.probed.val + 3
  let _ = @dx12.com_release(d)
}

///|
fn probe_device_v10(ctx : DeviceCtx) -> Unit {
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.com_query_interface(ctx.raw_dev, @dx12.bytes_ptr(@dx12.iid_d3d12_device10), ctx.out_ptr) != 0 {
    return
  }
  let d = @dx12.read_u64(ctx.out_ptr, 0)
  if d == (0 : UInt64) { return }
  let _ = @dx12.dx_d3d12_device10_set_private_data(d, ctx.priv_guid, 4, ctx.priv_val)
  @dx12.write_u32(ctx.priv_sz, 0, (4 : UInt32))
  let _ = @dx12.dx_d3d12_device10_get_private_data(d, ctx.priv_guid, ctx.priv_sz, ctx.scratch)
  let _ = @dx12.dx_d3d12_device10_set_private_data_interface(d, ctx.priv_guid, (0 : UInt64))
  let _ = @dx12.dx_d3d12_device10_set_name(d, ctx.name_w)
  let _ = @dx12.dx_d3d12_device10_get_node_count(d)
  let _ = @dx12.dx_d3d12_device10_get_device_removed_reason(d)
  let _ = @dx12.dx_d3d12_device10_check_feature_support(d, 1, ctx.arch_buf, 16)
  let _ = @dx12.dx_d3d12_device10_get_descriptor_handle_increment_size(d, 0)
  let _ = @dx12.dx_d3d12_device10_get_resource_allocation_info(d, ctx.scratch, 0, 1, ctx.buf_desc)
  let _ = @dx12.dx_d3d12_device10_get_custom_heap_properties(d, ctx.scratch, 0, 1)
  let _ = @dx12.dx_d3d12_device10_get_adapter_luid(d, ctx.scratch)
  @dx12.dx_d3d12_device10_get_copyable_footprints(d, ctx.tex_desc, 0, 1, (0 : Int64), ctx.scratch, ctx.scratch + (256 : UInt64), ctx.scratch + (512 : UInt64), ctx.scratch + (768 : UInt64))
  if ctx.reserved_res != (0 : UInt64) {
    @dx12.write_u32(ctx.scratch, 0, (1 : UInt32))
    @dx12.dx_d3d12_device10_get_resource_tiling(d, ctx.reserved_res, ctx.scratch + (16 : UInt64), ctx.scratch + (32 : UInt64), ctx.scratch + (64 : UInt64), ctx.scratch, 0, ctx.scratch + (128 : UInt64))
  }
  @dx12.dx_d3d12_device10_create_constant_buffer_view(d, ctx.cbv_desc, ctx.cpu_cbv)
  @dx12.dx_d3d12_device10_create_shader_resource_view(d, ctx.buf_def, ctx.srv_desc, ctx.cpu_srv)
  @dx12.dx_d3d12_device10_create_unordered_access_view(d, ctx.buf_uav, (0 : UInt64), ctx.uav_desc, ctx.cpu_uav)
  @dx12.dx_d3d12_device10_create_render_target_view(d, ctx.tex_rt, (0 : UInt64), ctx.cpu_rtv)
  @dx12.dx_d3d12_device10_create_depth_stencil_view(d, ctx.tex_ds, (0 : UInt64), ctx.cpu_dsv)
  @dx12.dx_d3d12_device10_create_sampler(d, ctx.samp_desc, ctx.cpu_samp)
  @dx12.dx_d3d12_device10_copy_descriptors(d, 1, ctx.cpu_arr + (8 : UInt64), ctx.sz_arr, 1, ctx.cpu_arr, ctx.sz_arr, 0)
  @dx12.dx_d3d12_device10_copy_descriptors_simple(d, 1, ctx.cpu_uav, ctx.cpu_srv, 0)
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device10_create_command_queue(d, ctx.q_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_command_queue), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device10_create_command_allocator(d, 0, @dx12.bytes_ptr(@dx12.iid_d3d12_command_allocator), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device10_create_graphics_pipeline_state(d, ctx.gpsd, @dx12.bytes_ptr(@dx12.iid_d3d12_pipeline_state), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device10_create_compute_pipeline_state(d, ctx.cpsd, @dx12.bytes_ptr(@dx12.iid_d3d12_pipeline_state), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device10_create_command_list(d, 0, 0, ctx.ca, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_graphics_command_list), ctx.out_ptr) == 0 { let cl = @dx12.read_u64(ctx.out_ptr, 0); let _ = @dx12.dx_d3d12_graphics_command_list_close(cl); let _ = @dx12.com_release(cl) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device10_create_descriptor_heap(d, ctx.dh_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_descriptor_heap), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device10_create_root_signature(d, 0, ctx.rs_blob, ctx.rs_len, @dx12.bytes_ptr(@dx12.iid_d3d12_root_signature), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device10_create_committed_resource(d, ctx.heap_default, 0, ctx.buf_desc, 0, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device10_create_heap(d, ctx.heap_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_heap), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device10_create_placed_resource(d, ctx.heap_obj, (0 : Int64), ctx.buf_desc, 0, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device10_create_reserved_resource(d, ctx.tiled_desc, 0, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device10_create_fence(d, (0 : Int64), 1, @dx12.bytes_ptr(@dx12.iid_d3d12_fence), ctx.out_ptr) == 0 {
    let sf = @dx12.read_u64(ctx.out_ptr, 0)
    let sh_out = ctx.scratch + (1024 : UInt64)
    @dx12.write_u64(sh_out, 0, (0 : UInt64))
    if @dx12.dx_d3d12_device10_create_shared_handle(d, sf, (0 : UInt64), 0x10000000, ctx.name_w, sh_out) == 0 {
      let sh = @dx12.read_u64(sh_out, 0)
      let open_out = ctx.scratch + (1040 : UInt64)
      @dx12.write_u64(open_out, 0, (0 : UInt64))
      if @dx12.dx_d3d12_device10_open_shared_handle(d, sh, @dx12.bytes_ptr(@dx12.iid_d3d12_fence), open_out) == 0 { let _ = @dx12.com_release(@dx12.read_u64(open_out, 0)) }
      let sh2_out = ctx.scratch + (1056 : UInt64)
      @dx12.write_u64(sh2_out, 0, (0 : UInt64))
      if @dx12.dx_d3d12_device10_open_shared_handle_by_name(d, ctx.name_w, 0x10000000, sh2_out) == 0 { @dx12.close_handle(@dx12.read_u64(sh2_out, 0)) }
      @dx12.close_handle(sh)
    }
    let _ = @dx12.com_release(sf)
  }
  let _ = @dx12.dx_d3d12_device10_make_resident(d, 1, ctx.res_arr)
  let _ = @dx12.dx_d3d12_device10_evict(d, 1, ctx.res_arr)
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device10_create_query_heap(d, ctx.qh_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_query_heap), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device10_create_command_signature(d, ctx.csig_desc, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_command_signature), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  ctx.probed.val = ctx.probed.val + 36
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device10_create_pipeline_library(d, (0 : UInt64), (0 : Int64), @dx12.bytes_ptr(@dx12.iid_d3d12_pipeline_library), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  let _ = @dx12.dx_d3d12_device10_set_event_on_multiple_fence_completion(d, ctx.fence_arr, ctx.val_arr, 1, 0, ctx.ev)
  let _ = @dx12.wait_event(ctx.ev, 1000)
  let _ = @dx12.dx_d3d12_device10_set_residency_priority(d, 1, ctx.res_arr, ctx.prio_arr)
  ctx.probed.val = ctx.probed.val + 3
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device10_create_pipeline_state(d, ctx.stream_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_pipeline_state), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  ctx.probed.val = ctx.probed.val + 1
  ctx.fence_seq = ctx.fence_seq + (1 : Int64)
  if @dx12.dx_d3d12_device10_enqueue_make_resident(d, 0, 1, ctx.res_arr, ctx.fence, ctx.fence_seq) == 0 {
    if @dx12.dx_d3d12_fence_get_completed_value(ctx.fence) < ctx.fence_seq {
      if @dx12.dx_d3d12_fence_set_event_on_completion(ctx.fence, ctx.fence_seq, ctx.ev) == 0 { let _ = @dx12.wait_event(ctx.ev, 1000) }
    }
    let _ = @dx12.dx_d3d12_device10_evict(d, 1, ctx.res_arr)
  }
  ctx.probed.val = ctx.probed.val + 1
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device10_create_command_list1(d, 0, 0, 0, @dx12.bytes_ptr(@dx12.iid_d3d12_graphics_command_list), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device10_create_committed_resource1(d, ctx.heap_default, 0, ctx.buf_desc, 0, (0 : UInt64), (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device10_create_heap1(d, ctx.heap_desc, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_heap), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device10_create_reserved_resource1(d, ctx.tiled_desc, 0, (0 : UInt64), (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  let _ = @dx12.dx_d3d12_device10_get_resource_allocation_info1(d, ctx.scratch, 0, 1, ctx.buf_desc, ctx.scratch + (256 : UInt64))
  ctx.probed.val = ctx.probed.val + 5
  @dx12.write_u32(ctx.scratch, 0, (0 : UInt32))
  let _ = @dx12.dx_d3d12_device10_enumerate_meta_commands(d, ctx.scratch, (0 : UInt64))
  @dx12.dx_d3d12_device10_get_raytracing_acceleration_structure_prebuild_info(d, ctx.rt_inputs, ctx.rt_prebuild)
  let _ = @dx12.dx_d3d12_device10_check_driver_matching_identifier(d, 0, ctx.rt_ident)
  if ctx.rt_tier > 0 {
    @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
    if @dx12.dx_d3d12_device10_create_state_object(d, ctx.rt_so_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_state_object), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  }
  ctx.probed.val = ctx.probed.val + 4
  let _ = @dx12.dx_d3d12_device10_set_background_processing_mode(d, 0, 0, (0 : UInt64), ctx.scratch)
  ctx.probed.val = ctx.probed.val + 1
  if ctx.rt_so != (0 : UInt64) {
    @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
    if @dx12.dx_d3d12_device10_add_to_state_object(d, ctx.rt_add_desc, ctx.rt_so, @dx12.bytes_ptr(@dx12.iid_d3d12_state_object), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  }
  ctx.probed.val = ctx.probed.val + 1
  let _ = @dx12.dx_d3d12_device10_get_resource_allocation_info2(d, ctx.scratch, 0, 1, ctx.buf_desc, ctx.scratch + (256 : UInt64))
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device10_create_committed_resource2(d, ctx.heap_default, 0, ctx.tex_desc1, 0, (0 : UInt64), (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device10_create_placed_resource1(d, ctx.heap_obj, (0 : Int64), ctx.tex_desc1, 0, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.dx_d3d12_device10_get_copyable_footprints1(d, ctx.tex_desc1, 0, 1, (0 : Int64), ctx.scratch, ctx.scratch + (256 : UInt64), ctx.scratch + (512 : UInt64), ctx.scratch + (768 : UInt64))
  ctx.probed.val = ctx.probed.val + 4
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device10_create_shader_cache_session(d, ctx.cache_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_shader_cache_session), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  let _ = @dx12.dx_d3d12_device10_shader_cache_control(d, 1, 1)
  let _ = @dx12.dx_d3d12_device10_shader_cache_control(d, 1, 2)
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device10_create_command_queue1(d, ctx.q_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_command_queue), @dx12.bytes_ptr(@dx12.iid_d3d12_command_queue), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  ctx.probed.val = ctx.probed.val + 3
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device10_create_committed_resource3(d, ctx.heap_default, 0, ctx.tex_desc1, -1, (0 : UInt64), (0 : UInt64), 0, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device10_create_placed_resource2(d, ctx.heap_obj, (0 : Int64), ctx.tex_desc1, -1, (0 : UInt64), 0, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device10_create_reserved_resource2(d, ctx.tiled_desc1, -1, (0 : UInt64), (0 : UInt64), 0, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  ctx.probed.val = ctx.probed.val + 3
  let _ = @dx12.com_release(d)
}

///|
fn probe_device_v11(ctx : DeviceCtx) -> Unit {
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.com_query_interface(ctx.raw_dev, @dx12.bytes_ptr(@dx12.iid_d3d12_device11), ctx.out_ptr) != 0 {
    return
  }
  let d = @dx12.read_u64(ctx.out_ptr, 0)
  if d == (0 : UInt64) { return }
  let _ = @dx12.dx_d3d12_device11_set_private_data(d, ctx.priv_guid, 4, ctx.priv_val)
  @dx12.write_u32(ctx.priv_sz, 0, (4 : UInt32))
  let _ = @dx12.dx_d3d12_device11_get_private_data(d, ctx.priv_guid, ctx.priv_sz, ctx.scratch)
  let _ = @dx12.dx_d3d12_device11_set_private_data_interface(d, ctx.priv_guid, (0 : UInt64))
  let _ = @dx12.dx_d3d12_device11_set_name(d, ctx.name_w)
  let _ = @dx12.dx_d3d12_device11_get_node_count(d)
  let _ = @dx12.dx_d3d12_device11_get_device_removed_reason(d)
  let _ = @dx12.dx_d3d12_device11_check_feature_support(d, 1, ctx.arch_buf, 16)
  let _ = @dx12.dx_d3d12_device11_get_descriptor_handle_increment_size(d, 0)
  let _ = @dx12.dx_d3d12_device11_get_resource_allocation_info(d, ctx.scratch, 0, 1, ctx.buf_desc)
  let _ = @dx12.dx_d3d12_device11_get_custom_heap_properties(d, ctx.scratch, 0, 1)
  let _ = @dx12.dx_d3d12_device11_get_adapter_luid(d, ctx.scratch)
  @dx12.dx_d3d12_device11_get_copyable_footprints(d, ctx.tex_desc, 0, 1, (0 : Int64), ctx.scratch, ctx.scratch + (256 : UInt64), ctx.scratch + (512 : UInt64), ctx.scratch + (768 : UInt64))
  if ctx.reserved_res != (0 : UInt64) {
    @dx12.write_u32(ctx.scratch, 0, (1 : UInt32))
    @dx12.dx_d3d12_device11_get_resource_tiling(d, ctx.reserved_res, ctx.scratch + (16 : UInt64), ctx.scratch + (32 : UInt64), ctx.scratch + (64 : UInt64), ctx.scratch, 0, ctx.scratch + (128 : UInt64))
  }
  @dx12.dx_d3d12_device11_create_constant_buffer_view(d, ctx.cbv_desc, ctx.cpu_cbv)
  @dx12.dx_d3d12_device11_create_shader_resource_view(d, ctx.buf_def, ctx.srv_desc, ctx.cpu_srv)
  @dx12.dx_d3d12_device11_create_unordered_access_view(d, ctx.buf_uav, (0 : UInt64), ctx.uav_desc, ctx.cpu_uav)
  @dx12.dx_d3d12_device11_create_render_target_view(d, ctx.tex_rt, (0 : UInt64), ctx.cpu_rtv)
  @dx12.dx_d3d12_device11_create_depth_stencil_view(d, ctx.tex_ds, (0 : UInt64), ctx.cpu_dsv)
  @dx12.dx_d3d12_device11_create_sampler(d, ctx.samp_desc, ctx.cpu_samp)
  @dx12.dx_d3d12_device11_copy_descriptors(d, 1, ctx.cpu_arr + (8 : UInt64), ctx.sz_arr, 1, ctx.cpu_arr, ctx.sz_arr, 0)
  @dx12.dx_d3d12_device11_copy_descriptors_simple(d, 1, ctx.cpu_uav, ctx.cpu_srv, 0)
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device11_create_command_queue(d, ctx.q_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_command_queue), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device11_create_command_allocator(d, 0, @dx12.bytes_ptr(@dx12.iid_d3d12_command_allocator), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device11_create_graphics_pipeline_state(d, ctx.gpsd, @dx12.bytes_ptr(@dx12.iid_d3d12_pipeline_state), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device11_create_compute_pipeline_state(d, ctx.cpsd, @dx12.bytes_ptr(@dx12.iid_d3d12_pipeline_state), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device11_create_command_list(d, 0, 0, ctx.ca, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_graphics_command_list), ctx.out_ptr) == 0 { let cl = @dx12.read_u64(ctx.out_ptr, 0); let _ = @dx12.dx_d3d12_graphics_command_list_close(cl); let _ = @dx12.com_release(cl) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device11_create_descriptor_heap(d, ctx.dh_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_descriptor_heap), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device11_create_root_signature(d, 0, ctx.rs_blob, ctx.rs_len, @dx12.bytes_ptr(@dx12.iid_d3d12_root_signature), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device11_create_committed_resource(d, ctx.heap_default, 0, ctx.buf_desc, 0, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device11_create_heap(d, ctx.heap_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_heap), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device11_create_placed_resource(d, ctx.heap_obj, (0 : Int64), ctx.buf_desc, 0, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device11_create_reserved_resource(d, ctx.tiled_desc, 0, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device11_create_fence(d, (0 : Int64), 1, @dx12.bytes_ptr(@dx12.iid_d3d12_fence), ctx.out_ptr) == 0 {
    let sf = @dx12.read_u64(ctx.out_ptr, 0)
    let sh_out = ctx.scratch + (1024 : UInt64)
    @dx12.write_u64(sh_out, 0, (0 : UInt64))
    if @dx12.dx_d3d12_device11_create_shared_handle(d, sf, (0 : UInt64), 0x10000000, ctx.name_w, sh_out) == 0 {
      let sh = @dx12.read_u64(sh_out, 0)
      let open_out = ctx.scratch + (1040 : UInt64)
      @dx12.write_u64(open_out, 0, (0 : UInt64))
      if @dx12.dx_d3d12_device11_open_shared_handle(d, sh, @dx12.bytes_ptr(@dx12.iid_d3d12_fence), open_out) == 0 { let _ = @dx12.com_release(@dx12.read_u64(open_out, 0)) }
      let sh2_out = ctx.scratch + (1056 : UInt64)
      @dx12.write_u64(sh2_out, 0, (0 : UInt64))
      if @dx12.dx_d3d12_device11_open_shared_handle_by_name(d, ctx.name_w, 0x10000000, sh2_out) == 0 { @dx12.close_handle(@dx12.read_u64(sh2_out, 0)) }
      @dx12.close_handle(sh)
    }
    let _ = @dx12.com_release(sf)
  }
  let _ = @dx12.dx_d3d12_device11_make_resident(d, 1, ctx.res_arr)
  let _ = @dx12.dx_d3d12_device11_evict(d, 1, ctx.res_arr)
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device11_create_query_heap(d, ctx.qh_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_query_heap), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device11_create_command_signature(d, ctx.csig_desc, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_command_signature), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  ctx.probed.val = ctx.probed.val + 36
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device11_create_pipeline_library(d, (0 : UInt64), (0 : Int64), @dx12.bytes_ptr(@dx12.iid_d3d12_pipeline_library), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  let _ = @dx12.dx_d3d12_device11_set_event_on_multiple_fence_completion(d, ctx.fence_arr, ctx.val_arr, 1, 0, ctx.ev)
  let _ = @dx12.wait_event(ctx.ev, 1000)
  let _ = @dx12.dx_d3d12_device11_set_residency_priority(d, 1, ctx.res_arr, ctx.prio_arr)
  ctx.probed.val = ctx.probed.val + 3
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device11_create_pipeline_state(d, ctx.stream_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_pipeline_state), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  ctx.probed.val = ctx.probed.val + 1
  ctx.fence_seq = ctx.fence_seq + (1 : Int64)
  if @dx12.dx_d3d12_device11_enqueue_make_resident(d, 0, 1, ctx.res_arr, ctx.fence, ctx.fence_seq) == 0 {
    if @dx12.dx_d3d12_fence_get_completed_value(ctx.fence) < ctx.fence_seq {
      if @dx12.dx_d3d12_fence_set_event_on_completion(ctx.fence, ctx.fence_seq, ctx.ev) == 0 { let _ = @dx12.wait_event(ctx.ev, 1000) }
    }
    let _ = @dx12.dx_d3d12_device11_evict(d, 1, ctx.res_arr)
  }
  ctx.probed.val = ctx.probed.val + 1
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device11_create_command_list1(d, 0, 0, 0, @dx12.bytes_ptr(@dx12.iid_d3d12_graphics_command_list), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device11_create_committed_resource1(d, ctx.heap_default, 0, ctx.buf_desc, 0, (0 : UInt64), (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device11_create_heap1(d, ctx.heap_desc, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_heap), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device11_create_reserved_resource1(d, ctx.tiled_desc, 0, (0 : UInt64), (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  let _ = @dx12.dx_d3d12_device11_get_resource_allocation_info1(d, ctx.scratch, 0, 1, ctx.buf_desc, ctx.scratch + (256 : UInt64))
  ctx.probed.val = ctx.probed.val + 5
  @dx12.write_u32(ctx.scratch, 0, (0 : UInt32))
  let _ = @dx12.dx_d3d12_device11_enumerate_meta_commands(d, ctx.scratch, (0 : UInt64))
  @dx12.dx_d3d12_device11_get_raytracing_acceleration_structure_prebuild_info(d, ctx.rt_inputs, ctx.rt_prebuild)
  let _ = @dx12.dx_d3d12_device11_check_driver_matching_identifier(d, 0, ctx.rt_ident)
  if ctx.rt_tier > 0 {
    @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
    if @dx12.dx_d3d12_device11_create_state_object(d, ctx.rt_so_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_state_object), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  }
  ctx.probed.val = ctx.probed.val + 4
  let _ = @dx12.dx_d3d12_device11_set_background_processing_mode(d, 0, 0, (0 : UInt64), ctx.scratch)
  ctx.probed.val = ctx.probed.val + 1
  if ctx.rt_so != (0 : UInt64) {
    @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
    if @dx12.dx_d3d12_device11_add_to_state_object(d, ctx.rt_add_desc, ctx.rt_so, @dx12.bytes_ptr(@dx12.iid_d3d12_state_object), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  }
  ctx.probed.val = ctx.probed.val + 1
  let _ = @dx12.dx_d3d12_device11_get_resource_allocation_info2(d, ctx.scratch, 0, 1, ctx.buf_desc, ctx.scratch + (256 : UInt64))
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device11_create_committed_resource2(d, ctx.heap_default, 0, ctx.tex_desc1, 0, (0 : UInt64), (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device11_create_placed_resource1(d, ctx.heap_obj, (0 : Int64), ctx.tex_desc1, 0, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.dx_d3d12_device11_get_copyable_footprints1(d, ctx.tex_desc1, 0, 1, (0 : Int64), ctx.scratch, ctx.scratch + (256 : UInt64), ctx.scratch + (512 : UInt64), ctx.scratch + (768 : UInt64))
  ctx.probed.val = ctx.probed.val + 4
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device11_create_shader_cache_session(d, ctx.cache_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_shader_cache_session), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  let _ = @dx12.dx_d3d12_device11_shader_cache_control(d, 1, 1)
  let _ = @dx12.dx_d3d12_device11_shader_cache_control(d, 1, 2)
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device11_create_command_queue1(d, ctx.q_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_command_queue), @dx12.bytes_ptr(@dx12.iid_d3d12_command_queue), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  ctx.probed.val = ctx.probed.val + 3
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device11_create_committed_resource3(d, ctx.heap_default, 0, ctx.tex_desc1, -1, (0 : UInt64), (0 : UInt64), 0, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device11_create_placed_resource2(d, ctx.heap_obj, (0 : Int64), ctx.tex_desc1, -1, (0 : UInt64), 0, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device11_create_reserved_resource2(d, ctx.tiled_desc1, -1, (0 : UInt64), (0 : UInt64), 0, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  ctx.probed.val = ctx.probed.val + 3
  @dx12.dx_d3d12_device11_create_sampler2(d, ctx.samp2_desc, ctx.cpu_samp)
  ctx.probed.val = ctx.probed.val + 1
  let _ = @dx12.com_release(d)
}

///|
fn probe_device_v12(ctx : DeviceCtx) -> Unit {
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.com_query_interface(ctx.raw_dev, @dx12.bytes_ptr(@dx12.iid_d3d12_device12), ctx.out_ptr) != 0 {
    return
  }
  let d = @dx12.read_u64(ctx.out_ptr, 0)
  if d == (0 : UInt64) { return }
  let _ = @dx12.dx_d3d12_device12_set_private_data(d, ctx.priv_guid, 4, ctx.priv_val)
  @dx12.write_u32(ctx.priv_sz, 0, (4 : UInt32))
  let _ = @dx12.dx_d3d12_device12_get_private_data(d, ctx.priv_guid, ctx.priv_sz, ctx.scratch)
  let _ = @dx12.dx_d3d12_device12_set_private_data_interface(d, ctx.priv_guid, (0 : UInt64))
  let _ = @dx12.dx_d3d12_device12_set_name(d, ctx.name_w)
  let _ = @dx12.dx_d3d12_device12_get_node_count(d)
  let _ = @dx12.dx_d3d12_device12_get_device_removed_reason(d)
  let _ = @dx12.dx_d3d12_device12_check_feature_support(d, 1, ctx.arch_buf, 16)
  let _ = @dx12.dx_d3d12_device12_get_descriptor_handle_increment_size(d, 0)
  let _ = @dx12.dx_d3d12_device12_get_resource_allocation_info(d, ctx.scratch, 0, 1, ctx.buf_desc)
  let _ = @dx12.dx_d3d12_device12_get_custom_heap_properties(d, ctx.scratch, 0, 1)
  let _ = @dx12.dx_d3d12_device12_get_adapter_luid(d, ctx.scratch)
  @dx12.dx_d3d12_device12_get_copyable_footprints(d, ctx.tex_desc, 0, 1, (0 : Int64), ctx.scratch, ctx.scratch + (256 : UInt64), ctx.scratch + (512 : UInt64), ctx.scratch + (768 : UInt64))
  if ctx.reserved_res != (0 : UInt64) {
    @dx12.write_u32(ctx.scratch, 0, (1 : UInt32))
    @dx12.dx_d3d12_device12_get_resource_tiling(d, ctx.reserved_res, ctx.scratch + (16 : UInt64), ctx.scratch + (32 : UInt64), ctx.scratch + (64 : UInt64), ctx.scratch, 0, ctx.scratch + (128 : UInt64))
  }
  @dx12.dx_d3d12_device12_create_constant_buffer_view(d, ctx.cbv_desc, ctx.cpu_cbv)
  @dx12.dx_d3d12_device12_create_shader_resource_view(d, ctx.buf_def, ctx.srv_desc, ctx.cpu_srv)
  @dx12.dx_d3d12_device12_create_unordered_access_view(d, ctx.buf_uav, (0 : UInt64), ctx.uav_desc, ctx.cpu_uav)
  @dx12.dx_d3d12_device12_create_render_target_view(d, ctx.tex_rt, (0 : UInt64), ctx.cpu_rtv)
  @dx12.dx_d3d12_device12_create_depth_stencil_view(d, ctx.tex_ds, (0 : UInt64), ctx.cpu_dsv)
  @dx12.dx_d3d12_device12_create_sampler(d, ctx.samp_desc, ctx.cpu_samp)
  @dx12.dx_d3d12_device12_copy_descriptors(d, 1, ctx.cpu_arr + (8 : UInt64), ctx.sz_arr, 1, ctx.cpu_arr, ctx.sz_arr, 0)
  @dx12.dx_d3d12_device12_copy_descriptors_simple(d, 1, ctx.cpu_uav, ctx.cpu_srv, 0)
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device12_create_command_queue(d, ctx.q_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_command_queue), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device12_create_command_allocator(d, 0, @dx12.bytes_ptr(@dx12.iid_d3d12_command_allocator), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device12_create_graphics_pipeline_state(d, ctx.gpsd, @dx12.bytes_ptr(@dx12.iid_d3d12_pipeline_state), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device12_create_compute_pipeline_state(d, ctx.cpsd, @dx12.bytes_ptr(@dx12.iid_d3d12_pipeline_state), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device12_create_command_list(d, 0, 0, ctx.ca, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_graphics_command_list), ctx.out_ptr) == 0 { let cl = @dx12.read_u64(ctx.out_ptr, 0); let _ = @dx12.dx_d3d12_graphics_command_list_close(cl); let _ = @dx12.com_release(cl) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device12_create_descriptor_heap(d, ctx.dh_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_descriptor_heap), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device12_create_root_signature(d, 0, ctx.rs_blob, ctx.rs_len, @dx12.bytes_ptr(@dx12.iid_d3d12_root_signature), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device12_create_committed_resource(d, ctx.heap_default, 0, ctx.buf_desc, 0, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device12_create_heap(d, ctx.heap_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_heap), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device12_create_placed_resource(d, ctx.heap_obj, (0 : Int64), ctx.buf_desc, 0, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device12_create_reserved_resource(d, ctx.tiled_desc, 0, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device12_create_fence(d, (0 : Int64), 1, @dx12.bytes_ptr(@dx12.iid_d3d12_fence), ctx.out_ptr) == 0 {
    let sf = @dx12.read_u64(ctx.out_ptr, 0)
    let sh_out = ctx.scratch + (1024 : UInt64)
    @dx12.write_u64(sh_out, 0, (0 : UInt64))
    if @dx12.dx_d3d12_device12_create_shared_handle(d, sf, (0 : UInt64), 0x10000000, ctx.name_w, sh_out) == 0 {
      let sh = @dx12.read_u64(sh_out, 0)
      let open_out = ctx.scratch + (1040 : UInt64)
      @dx12.write_u64(open_out, 0, (0 : UInt64))
      if @dx12.dx_d3d12_device12_open_shared_handle(d, sh, @dx12.bytes_ptr(@dx12.iid_d3d12_fence), open_out) == 0 { let _ = @dx12.com_release(@dx12.read_u64(open_out, 0)) }
      let sh2_out = ctx.scratch + (1056 : UInt64)
      @dx12.write_u64(sh2_out, 0, (0 : UInt64))
      if @dx12.dx_d3d12_device12_open_shared_handle_by_name(d, ctx.name_w, 0x10000000, sh2_out) == 0 { @dx12.close_handle(@dx12.read_u64(sh2_out, 0)) }
      @dx12.close_handle(sh)
    }
    let _ = @dx12.com_release(sf)
  }
  let _ = @dx12.dx_d3d12_device12_make_resident(d, 1, ctx.res_arr)
  let _ = @dx12.dx_d3d12_device12_evict(d, 1, ctx.res_arr)
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device12_create_query_heap(d, ctx.qh_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_query_heap), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device12_create_command_signature(d, ctx.csig_desc, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_command_signature), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  ctx.probed.val = ctx.probed.val + 36
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device12_create_pipeline_library(d, (0 : UInt64), (0 : Int64), @dx12.bytes_ptr(@dx12.iid_d3d12_pipeline_library), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  let _ = @dx12.dx_d3d12_device12_set_event_on_multiple_fence_completion(d, ctx.fence_arr, ctx.val_arr, 1, 0, ctx.ev)
  let _ = @dx12.wait_event(ctx.ev, 1000)
  let _ = @dx12.dx_d3d12_device12_set_residency_priority(d, 1, ctx.res_arr, ctx.prio_arr)
  ctx.probed.val = ctx.probed.val + 3
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device12_create_pipeline_state(d, ctx.stream_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_pipeline_state), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  ctx.probed.val = ctx.probed.val + 1
  ctx.fence_seq = ctx.fence_seq + (1 : Int64)
  if @dx12.dx_d3d12_device12_enqueue_make_resident(d, 0, 1, ctx.res_arr, ctx.fence, ctx.fence_seq) == 0 {
    if @dx12.dx_d3d12_fence_get_completed_value(ctx.fence) < ctx.fence_seq {
      if @dx12.dx_d3d12_fence_set_event_on_completion(ctx.fence, ctx.fence_seq, ctx.ev) == 0 { let _ = @dx12.wait_event(ctx.ev, 1000) }
    }
    let _ = @dx12.dx_d3d12_device12_evict(d, 1, ctx.res_arr)
  }
  ctx.probed.val = ctx.probed.val + 1
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device12_create_command_list1(d, 0, 0, 0, @dx12.bytes_ptr(@dx12.iid_d3d12_graphics_command_list), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device12_create_committed_resource1(d, ctx.heap_default, 0, ctx.buf_desc, 0, (0 : UInt64), (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device12_create_heap1(d, ctx.heap_desc, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_heap), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device12_create_reserved_resource1(d, ctx.tiled_desc, 0, (0 : UInt64), (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  let _ = @dx12.dx_d3d12_device12_get_resource_allocation_info1(d, ctx.scratch, 0, 1, ctx.buf_desc, ctx.scratch + (256 : UInt64))
  ctx.probed.val = ctx.probed.val + 5
  @dx12.write_u32(ctx.scratch, 0, (0 : UInt32))
  let _ = @dx12.dx_d3d12_device12_enumerate_meta_commands(d, ctx.scratch, (0 : UInt64))
  @dx12.dx_d3d12_device12_get_raytracing_acceleration_structure_prebuild_info(d, ctx.rt_inputs, ctx.rt_prebuild)
  let _ = @dx12.dx_d3d12_device12_check_driver_matching_identifier(d, 0, ctx.rt_ident)
  if ctx.rt_tier > 0 {
    @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
    if @dx12.dx_d3d12_device12_create_state_object(d, ctx.rt_so_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_state_object), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  }
  ctx.probed.val = ctx.probed.val + 4
  let _ = @dx12.dx_d3d12_device12_set_background_processing_mode(d, 0, 0, (0 : UInt64), ctx.scratch)
  ctx.probed.val = ctx.probed.val + 1
  if ctx.rt_so != (0 : UInt64) {
    @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
    if @dx12.dx_d3d12_device12_add_to_state_object(d, ctx.rt_add_desc, ctx.rt_so, @dx12.bytes_ptr(@dx12.iid_d3d12_state_object), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  }
  ctx.probed.val = ctx.probed.val + 1
  let _ = @dx12.dx_d3d12_device12_get_resource_allocation_info2(d, ctx.scratch, 0, 1, ctx.buf_desc, ctx.scratch + (256 : UInt64))
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device12_create_committed_resource2(d, ctx.heap_default, 0, ctx.tex_desc1, 0, (0 : UInt64), (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device12_create_placed_resource1(d, ctx.heap_obj, (0 : Int64), ctx.tex_desc1, 0, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.dx_d3d12_device12_get_copyable_footprints1(d, ctx.tex_desc1, 0, 1, (0 : Int64), ctx.scratch, ctx.scratch + (256 : UInt64), ctx.scratch + (512 : UInt64), ctx.scratch + (768 : UInt64))
  ctx.probed.val = ctx.probed.val + 4
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device12_create_shader_cache_session(d, ctx.cache_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_shader_cache_session), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  let _ = @dx12.dx_d3d12_device12_shader_cache_control(d, 1, 1)
  let _ = @dx12.dx_d3d12_device12_shader_cache_control(d, 1, 2)
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device12_create_command_queue1(d, ctx.q_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_command_queue), @dx12.bytes_ptr(@dx12.iid_d3d12_command_queue), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  ctx.probed.val = ctx.probed.val + 3
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device12_create_committed_resource3(d, ctx.heap_default, 0, ctx.tex_desc1, -1, (0 : UInt64), (0 : UInt64), 0, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device12_create_placed_resource2(d, ctx.heap_obj, (0 : Int64), ctx.tex_desc1, -1, (0 : UInt64), 0, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device12_create_reserved_resource2(d, ctx.tiled_desc1, -1, (0 : UInt64), (0 : UInt64), 0, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  ctx.probed.val = ctx.probed.val + 3
  @dx12.dx_d3d12_device12_create_sampler2(d, ctx.samp2_desc, ctx.cpu_samp)
  ctx.probed.val = ctx.probed.val + 1
  let _ = @dx12.dx_d3d12_device12_get_resource_allocation_info3(d, ctx.scratch, 0, 1, ctx.buf_desc, (0 : UInt64), (0 : UInt64), ctx.scratch + (256 : UInt64))
  ctx.probed.val = ctx.probed.val + 1
  let _ = @dx12.com_release(d)
}

///|
fn probe_device_v13(ctx : DeviceCtx) -> Unit {
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.com_query_interface(ctx.raw_dev, @dx12.bytes_ptr(@dx12.iid_d3d12_device13), ctx.out_ptr) != 0 {
    return
  }
  let d = @dx12.read_u64(ctx.out_ptr, 0)
  if d == (0 : UInt64) { return }
  let _ = @dx12.dx_d3d12_device13_set_private_data(d, ctx.priv_guid, 4, ctx.priv_val)
  @dx12.write_u32(ctx.priv_sz, 0, (4 : UInt32))
  let _ = @dx12.dx_d3d12_device13_get_private_data(d, ctx.priv_guid, ctx.priv_sz, ctx.scratch)
  let _ = @dx12.dx_d3d12_device13_set_private_data_interface(d, ctx.priv_guid, (0 : UInt64))
  let _ = @dx12.dx_d3d12_device13_set_name(d, ctx.name_w)
  let _ = @dx12.dx_d3d12_device13_get_node_count(d)
  let _ = @dx12.dx_d3d12_device13_get_device_removed_reason(d)
  let _ = @dx12.dx_d3d12_device13_check_feature_support(d, 1, ctx.arch_buf, 16)
  let _ = @dx12.dx_d3d12_device13_get_descriptor_handle_increment_size(d, 0)
  let _ = @dx12.dx_d3d12_device13_get_resource_allocation_info(d, ctx.scratch, 0, 1, ctx.buf_desc)
  let _ = @dx12.dx_d3d12_device13_get_custom_heap_properties(d, ctx.scratch, 0, 1)
  let _ = @dx12.dx_d3d12_device13_get_adapter_luid(d, ctx.scratch)
  @dx12.dx_d3d12_device13_get_copyable_footprints(d, ctx.tex_desc, 0, 1, (0 : Int64), ctx.scratch, ctx.scratch + (256 : UInt64), ctx.scratch + (512 : UInt64), ctx.scratch + (768 : UInt64))
  if ctx.reserved_res != (0 : UInt64) {
    @dx12.write_u32(ctx.scratch, 0, (1 : UInt32))
    @dx12.dx_d3d12_device13_get_resource_tiling(d, ctx.reserved_res, ctx.scratch + (16 : UInt64), ctx.scratch + (32 : UInt64), ctx.scratch + (64 : UInt64), ctx.scratch, 0, ctx.scratch + (128 : UInt64))
  }
  @dx12.dx_d3d12_device13_create_constant_buffer_view(d, ctx.cbv_desc, ctx.cpu_cbv)
  @dx12.dx_d3d12_device13_create_shader_resource_view(d, ctx.buf_def, ctx.srv_desc, ctx.cpu_srv)
  @dx12.dx_d3d12_device13_create_unordered_access_view(d, ctx.buf_uav, (0 : UInt64), ctx.uav_desc, ctx.cpu_uav)
  @dx12.dx_d3d12_device13_create_render_target_view(d, ctx.tex_rt, (0 : UInt64), ctx.cpu_rtv)
  @dx12.dx_d3d12_device13_create_depth_stencil_view(d, ctx.tex_ds, (0 : UInt64), ctx.cpu_dsv)
  @dx12.dx_d3d12_device13_create_sampler(d, ctx.samp_desc, ctx.cpu_samp)
  @dx12.dx_d3d12_device13_copy_descriptors(d, 1, ctx.cpu_arr + (8 : UInt64), ctx.sz_arr, 1, ctx.cpu_arr, ctx.sz_arr, 0)
  @dx12.dx_d3d12_device13_copy_descriptors_simple(d, 1, ctx.cpu_uav, ctx.cpu_srv, 0)
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device13_create_command_queue(d, ctx.q_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_command_queue), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device13_create_command_allocator(d, 0, @dx12.bytes_ptr(@dx12.iid_d3d12_command_allocator), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device13_create_graphics_pipeline_state(d, ctx.gpsd, @dx12.bytes_ptr(@dx12.iid_d3d12_pipeline_state), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device13_create_compute_pipeline_state(d, ctx.cpsd, @dx12.bytes_ptr(@dx12.iid_d3d12_pipeline_state), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device13_create_command_list(d, 0, 0, ctx.ca, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_graphics_command_list), ctx.out_ptr) == 0 { let cl = @dx12.read_u64(ctx.out_ptr, 0); let _ = @dx12.dx_d3d12_graphics_command_list_close(cl); let _ = @dx12.com_release(cl) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device13_create_descriptor_heap(d, ctx.dh_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_descriptor_heap), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device13_create_root_signature(d, 0, ctx.rs_blob, ctx.rs_len, @dx12.bytes_ptr(@dx12.iid_d3d12_root_signature), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device13_create_committed_resource(d, ctx.heap_default, 0, ctx.buf_desc, 0, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device13_create_heap(d, ctx.heap_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_heap), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device13_create_placed_resource(d, ctx.heap_obj, (0 : Int64), ctx.buf_desc, 0, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device13_create_reserved_resource(d, ctx.tiled_desc, 0, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device13_create_fence(d, (0 : Int64), 1, @dx12.bytes_ptr(@dx12.iid_d3d12_fence), ctx.out_ptr) == 0 {
    let sf = @dx12.read_u64(ctx.out_ptr, 0)
    let sh_out = ctx.scratch + (1024 : UInt64)
    @dx12.write_u64(sh_out, 0, (0 : UInt64))
    if @dx12.dx_d3d12_device13_create_shared_handle(d, sf, (0 : UInt64), 0x10000000, ctx.name_w, sh_out) == 0 {
      let sh = @dx12.read_u64(sh_out, 0)
      let open_out = ctx.scratch + (1040 : UInt64)
      @dx12.write_u64(open_out, 0, (0 : UInt64))
      if @dx12.dx_d3d12_device13_open_shared_handle(d, sh, @dx12.bytes_ptr(@dx12.iid_d3d12_fence), open_out) == 0 { let _ = @dx12.com_release(@dx12.read_u64(open_out, 0)) }
      let sh2_out = ctx.scratch + (1056 : UInt64)
      @dx12.write_u64(sh2_out, 0, (0 : UInt64))
      if @dx12.dx_d3d12_device13_open_shared_handle_by_name(d, ctx.name_w, 0x10000000, sh2_out) == 0 { @dx12.close_handle(@dx12.read_u64(sh2_out, 0)) }
      @dx12.close_handle(sh)
    }
    let _ = @dx12.com_release(sf)
  }
  let _ = @dx12.dx_d3d12_device13_make_resident(d, 1, ctx.res_arr)
  let _ = @dx12.dx_d3d12_device13_evict(d, 1, ctx.res_arr)
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device13_create_query_heap(d, ctx.qh_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_query_heap), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device13_create_command_signature(d, ctx.csig_desc, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_command_signature), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  ctx.probed.val = ctx.probed.val + 36
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device13_create_pipeline_library(d, (0 : UInt64), (0 : Int64), @dx12.bytes_ptr(@dx12.iid_d3d12_pipeline_library), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  let _ = @dx12.dx_d3d12_device13_set_event_on_multiple_fence_completion(d, ctx.fence_arr, ctx.val_arr, 1, 0, ctx.ev)
  let _ = @dx12.wait_event(ctx.ev, 1000)
  let _ = @dx12.dx_d3d12_device13_set_residency_priority(d, 1, ctx.res_arr, ctx.prio_arr)
  ctx.probed.val = ctx.probed.val + 3
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device13_create_pipeline_state(d, ctx.stream_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_pipeline_state), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  ctx.probed.val = ctx.probed.val + 1
  ctx.fence_seq = ctx.fence_seq + (1 : Int64)
  if @dx12.dx_d3d12_device13_enqueue_make_resident(d, 0, 1, ctx.res_arr, ctx.fence, ctx.fence_seq) == 0 {
    if @dx12.dx_d3d12_fence_get_completed_value(ctx.fence) < ctx.fence_seq {
      if @dx12.dx_d3d12_fence_set_event_on_completion(ctx.fence, ctx.fence_seq, ctx.ev) == 0 { let _ = @dx12.wait_event(ctx.ev, 1000) }
    }
    let _ = @dx12.dx_d3d12_device13_evict(d, 1, ctx.res_arr)
  }
  ctx.probed.val = ctx.probed.val + 1
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device13_create_command_list1(d, 0, 0, 0, @dx12.bytes_ptr(@dx12.iid_d3d12_graphics_command_list), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device13_create_committed_resource1(d, ctx.heap_default, 0, ctx.buf_desc, 0, (0 : UInt64), (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device13_create_heap1(d, ctx.heap_desc, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_heap), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device13_create_reserved_resource1(d, ctx.tiled_desc, 0, (0 : UInt64), (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  let _ = @dx12.dx_d3d12_device13_get_resource_allocation_info1(d, ctx.scratch, 0, 1, ctx.buf_desc, ctx.scratch + (256 : UInt64))
  ctx.probed.val = ctx.probed.val + 5
  @dx12.write_u32(ctx.scratch, 0, (0 : UInt32))
  let _ = @dx12.dx_d3d12_device13_enumerate_meta_commands(d, ctx.scratch, (0 : UInt64))
  @dx12.dx_d3d12_device13_get_raytracing_acceleration_structure_prebuild_info(d, ctx.rt_inputs, ctx.rt_prebuild)
  let _ = @dx12.dx_d3d12_device13_check_driver_matching_identifier(d, 0, ctx.rt_ident)
  if ctx.rt_tier > 0 {
    @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
    if @dx12.dx_d3d12_device13_create_state_object(d, ctx.rt_so_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_state_object), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  }
  ctx.probed.val = ctx.probed.val + 4
  let _ = @dx12.dx_d3d12_device13_set_background_processing_mode(d, 0, 0, (0 : UInt64), ctx.scratch)
  ctx.probed.val = ctx.probed.val + 1
  if ctx.rt_so != (0 : UInt64) {
    @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
    if @dx12.dx_d3d12_device13_add_to_state_object(d, ctx.rt_add_desc, ctx.rt_so, @dx12.bytes_ptr(@dx12.iid_d3d12_state_object), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  }
  ctx.probed.val = ctx.probed.val + 1
  let _ = @dx12.dx_d3d12_device13_get_resource_allocation_info2(d, ctx.scratch, 0, 1, ctx.buf_desc, ctx.scratch + (256 : UInt64))
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device13_create_committed_resource2(d, ctx.heap_default, 0, ctx.tex_desc1, 0, (0 : UInt64), (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device13_create_placed_resource1(d, ctx.heap_obj, (0 : Int64), ctx.tex_desc1, 0, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.dx_d3d12_device13_get_copyable_footprints1(d, ctx.tex_desc1, 0, 1, (0 : Int64), ctx.scratch, ctx.scratch + (256 : UInt64), ctx.scratch + (512 : UInt64), ctx.scratch + (768 : UInt64))
  ctx.probed.val = ctx.probed.val + 4
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device13_create_shader_cache_session(d, ctx.cache_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_shader_cache_session), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  let _ = @dx12.dx_d3d12_device13_shader_cache_control(d, 1, 1)
  let _ = @dx12.dx_d3d12_device13_shader_cache_control(d, 1, 2)
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device13_create_command_queue1(d, ctx.q_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_command_queue), @dx12.bytes_ptr(@dx12.iid_d3d12_command_queue), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  ctx.probed.val = ctx.probed.val + 3
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device13_create_committed_resource3(d, ctx.heap_default, 0, ctx.tex_desc1, -1, (0 : UInt64), (0 : UInt64), 0, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device13_create_placed_resource2(d, ctx.heap_obj, (0 : Int64), ctx.tex_desc1, -1, (0 : UInt64), 0, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device13_create_reserved_resource2(d, ctx.tiled_desc1, -1, (0 : UInt64), (0 : UInt64), 0, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  ctx.probed.val = ctx.probed.val + 3
  @dx12.dx_d3d12_device13_create_sampler2(d, ctx.samp2_desc, ctx.cpu_samp)
  ctx.probed.val = ctx.probed.val + 1
  let _ = @dx12.dx_d3d12_device13_get_resource_allocation_info3(d, ctx.scratch, 0, 1, ctx.buf_desc, (0 : UInt64), (0 : UInt64), ctx.scratch + (256 : UInt64))
  ctx.probed.val = ctx.probed.val + 1
  let _ = @dx12.com_release(d)
}

///|
fn probe_device_v14(ctx : DeviceCtx) -> Unit {
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.com_query_interface(ctx.raw_dev, @dx12.bytes_ptr(@dx12.iid_d3d12_device14), ctx.out_ptr) != 0 {
    return
  }
  let d = @dx12.read_u64(ctx.out_ptr, 0)
  if d == (0 : UInt64) { return }
  let _ = @dx12.dx_d3d12_device14_set_private_data(d, ctx.priv_guid, 4, ctx.priv_val)
  @dx12.write_u32(ctx.priv_sz, 0, (4 : UInt32))
  let _ = @dx12.dx_d3d12_device14_get_private_data(d, ctx.priv_guid, ctx.priv_sz, ctx.scratch)
  let _ = @dx12.dx_d3d12_device14_set_private_data_interface(d, ctx.priv_guid, (0 : UInt64))
  let _ = @dx12.dx_d3d12_device14_set_name(d, ctx.name_w)
  let _ = @dx12.dx_d3d12_device14_get_node_count(d)
  let _ = @dx12.dx_d3d12_device14_get_device_removed_reason(d)
  let _ = @dx12.dx_d3d12_device14_check_feature_support(d, 1, ctx.arch_buf, 16)
  let _ = @dx12.dx_d3d12_device14_get_descriptor_handle_increment_size(d, 0)
  let _ = @dx12.dx_d3d12_device14_get_resource_allocation_info(d, ctx.scratch, 0, 1, ctx.buf_desc)
  let _ = @dx12.dx_d3d12_device14_get_custom_heap_properties(d, ctx.scratch, 0, 1)
  let _ = @dx12.dx_d3d12_device14_get_adapter_luid(d, ctx.scratch)
  @dx12.dx_d3d12_device14_get_copyable_footprints(d, ctx.tex_desc, 0, 1, (0 : Int64), ctx.scratch, ctx.scratch + (256 : UInt64), ctx.scratch + (512 : UInt64), ctx.scratch + (768 : UInt64))
  if ctx.reserved_res != (0 : UInt64) {
    @dx12.write_u32(ctx.scratch, 0, (1 : UInt32))
    @dx12.dx_d3d12_device14_get_resource_tiling(d, ctx.reserved_res, ctx.scratch + (16 : UInt64), ctx.scratch + (32 : UInt64), ctx.scratch + (64 : UInt64), ctx.scratch, 0, ctx.scratch + (128 : UInt64))
  }
  @dx12.dx_d3d12_device14_create_constant_buffer_view(d, ctx.cbv_desc, ctx.cpu_cbv)
  @dx12.dx_d3d12_device14_create_shader_resource_view(d, ctx.buf_def, ctx.srv_desc, ctx.cpu_srv)
  @dx12.dx_d3d12_device14_create_unordered_access_view(d, ctx.buf_uav, (0 : UInt64), ctx.uav_desc, ctx.cpu_uav)
  @dx12.dx_d3d12_device14_create_render_target_view(d, ctx.tex_rt, (0 : UInt64), ctx.cpu_rtv)
  @dx12.dx_d3d12_device14_create_depth_stencil_view(d, ctx.tex_ds, (0 : UInt64), ctx.cpu_dsv)
  @dx12.dx_d3d12_device14_create_sampler(d, ctx.samp_desc, ctx.cpu_samp)
  @dx12.dx_d3d12_device14_copy_descriptors(d, 1, ctx.cpu_arr + (8 : UInt64), ctx.sz_arr, 1, ctx.cpu_arr, ctx.sz_arr, 0)
  @dx12.dx_d3d12_device14_copy_descriptors_simple(d, 1, ctx.cpu_uav, ctx.cpu_srv, 0)
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device14_create_command_queue(d, ctx.q_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_command_queue), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device14_create_command_allocator(d, 0, @dx12.bytes_ptr(@dx12.iid_d3d12_command_allocator), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device14_create_graphics_pipeline_state(d, ctx.gpsd, @dx12.bytes_ptr(@dx12.iid_d3d12_pipeline_state), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device14_create_compute_pipeline_state(d, ctx.cpsd, @dx12.bytes_ptr(@dx12.iid_d3d12_pipeline_state), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device14_create_command_list(d, 0, 0, ctx.ca, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_graphics_command_list), ctx.out_ptr) == 0 { let cl = @dx12.read_u64(ctx.out_ptr, 0); let _ = @dx12.dx_d3d12_graphics_command_list_close(cl); let _ = @dx12.com_release(cl) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device14_create_descriptor_heap(d, ctx.dh_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_descriptor_heap), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device14_create_root_signature(d, 0, ctx.rs_blob, ctx.rs_len, @dx12.bytes_ptr(@dx12.iid_d3d12_root_signature), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device14_create_committed_resource(d, ctx.heap_default, 0, ctx.buf_desc, 0, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device14_create_heap(d, ctx.heap_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_heap), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device14_create_placed_resource(d, ctx.heap_obj, (0 : Int64), ctx.buf_desc, 0, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device14_create_reserved_resource(d, ctx.tiled_desc, 0, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device14_create_fence(d, (0 : Int64), 1, @dx12.bytes_ptr(@dx12.iid_d3d12_fence), ctx.out_ptr) == 0 {
    let sf = @dx12.read_u64(ctx.out_ptr, 0)
    let sh_out = ctx.scratch + (1024 : UInt64)
    @dx12.write_u64(sh_out, 0, (0 : UInt64))
    if @dx12.dx_d3d12_device14_create_shared_handle(d, sf, (0 : UInt64), 0x10000000, ctx.name_w, sh_out) == 0 {
      let sh = @dx12.read_u64(sh_out, 0)
      let open_out = ctx.scratch + (1040 : UInt64)
      @dx12.write_u64(open_out, 0, (0 : UInt64))
      if @dx12.dx_d3d12_device14_open_shared_handle(d, sh, @dx12.bytes_ptr(@dx12.iid_d3d12_fence), open_out) == 0 { let _ = @dx12.com_release(@dx12.read_u64(open_out, 0)) }
      let sh2_out = ctx.scratch + (1056 : UInt64)
      @dx12.write_u64(sh2_out, 0, (0 : UInt64))
      if @dx12.dx_d3d12_device14_open_shared_handle_by_name(d, ctx.name_w, 0x10000000, sh2_out) == 0 { @dx12.close_handle(@dx12.read_u64(sh2_out, 0)) }
      @dx12.close_handle(sh)
    }
    let _ = @dx12.com_release(sf)
  }
  let _ = @dx12.dx_d3d12_device14_make_resident(d, 1, ctx.res_arr)
  let _ = @dx12.dx_d3d12_device14_evict(d, 1, ctx.res_arr)
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device14_create_query_heap(d, ctx.qh_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_query_heap), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device14_create_command_signature(d, ctx.csig_desc, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_command_signature), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  ctx.probed.val = ctx.probed.val + 36
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device14_create_pipeline_library(d, (0 : UInt64), (0 : Int64), @dx12.bytes_ptr(@dx12.iid_d3d12_pipeline_library), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  let _ = @dx12.dx_d3d12_device14_set_event_on_multiple_fence_completion(d, ctx.fence_arr, ctx.val_arr, 1, 0, ctx.ev)
  let _ = @dx12.wait_event(ctx.ev, 1000)
  let _ = @dx12.dx_d3d12_device14_set_residency_priority(d, 1, ctx.res_arr, ctx.prio_arr)
  ctx.probed.val = ctx.probed.val + 3
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device14_create_pipeline_state(d, ctx.stream_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_pipeline_state), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  ctx.probed.val = ctx.probed.val + 1
  ctx.fence_seq = ctx.fence_seq + (1 : Int64)
  if @dx12.dx_d3d12_device14_enqueue_make_resident(d, 0, 1, ctx.res_arr, ctx.fence, ctx.fence_seq) == 0 {
    if @dx12.dx_d3d12_fence_get_completed_value(ctx.fence) < ctx.fence_seq {
      if @dx12.dx_d3d12_fence_set_event_on_completion(ctx.fence, ctx.fence_seq, ctx.ev) == 0 { let _ = @dx12.wait_event(ctx.ev, 1000) }
    }
    let _ = @dx12.dx_d3d12_device14_evict(d, 1, ctx.res_arr)
  }
  ctx.probed.val = ctx.probed.val + 1
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device14_create_command_list1(d, 0, 0, 0, @dx12.bytes_ptr(@dx12.iid_d3d12_graphics_command_list), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device14_create_committed_resource1(d, ctx.heap_default, 0, ctx.buf_desc, 0, (0 : UInt64), (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device14_create_heap1(d, ctx.heap_desc, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_heap), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device14_create_reserved_resource1(d, ctx.tiled_desc, 0, (0 : UInt64), (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  let _ = @dx12.dx_d3d12_device14_get_resource_allocation_info1(d, ctx.scratch, 0, 1, ctx.buf_desc, ctx.scratch + (256 : UInt64))
  ctx.probed.val = ctx.probed.val + 5
  @dx12.write_u32(ctx.scratch, 0, (0 : UInt32))
  let _ = @dx12.dx_d3d12_device14_enumerate_meta_commands(d, ctx.scratch, (0 : UInt64))
  @dx12.dx_d3d12_device14_get_raytracing_acceleration_structure_prebuild_info(d, ctx.rt_inputs, ctx.rt_prebuild)
  let _ = @dx12.dx_d3d12_device14_check_driver_matching_identifier(d, 0, ctx.rt_ident)
  if ctx.rt_tier > 0 {
    @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
    if @dx12.dx_d3d12_device14_create_state_object(d, ctx.rt_so_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_state_object), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  }
  ctx.probed.val = ctx.probed.val + 4
  let _ = @dx12.dx_d3d12_device14_set_background_processing_mode(d, 0, 0, (0 : UInt64), ctx.scratch)
  ctx.probed.val = ctx.probed.val + 1
  if ctx.rt_so != (0 : UInt64) {
    @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
    if @dx12.dx_d3d12_device14_add_to_state_object(d, ctx.rt_add_desc, ctx.rt_so, @dx12.bytes_ptr(@dx12.iid_d3d12_state_object), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  }
  ctx.probed.val = ctx.probed.val + 1
  let _ = @dx12.dx_d3d12_device14_get_resource_allocation_info2(d, ctx.scratch, 0, 1, ctx.buf_desc, ctx.scratch + (256 : UInt64))
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device14_create_committed_resource2(d, ctx.heap_default, 0, ctx.tex_desc1, 0, (0 : UInt64), (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device14_create_placed_resource1(d, ctx.heap_obj, (0 : Int64), ctx.tex_desc1, 0, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.dx_d3d12_device14_get_copyable_footprints1(d, ctx.tex_desc1, 0, 1, (0 : Int64), ctx.scratch, ctx.scratch + (256 : UInt64), ctx.scratch + (512 : UInt64), ctx.scratch + (768 : UInt64))
  ctx.probed.val = ctx.probed.val + 4
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device14_create_shader_cache_session(d, ctx.cache_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_shader_cache_session), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  let _ = @dx12.dx_d3d12_device14_shader_cache_control(d, 1, 1)
  let _ = @dx12.dx_d3d12_device14_shader_cache_control(d, 1, 2)
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device14_create_command_queue1(d, ctx.q_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_command_queue), @dx12.bytes_ptr(@dx12.iid_d3d12_command_queue), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  ctx.probed.val = ctx.probed.val + 3
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device14_create_committed_resource3(d, ctx.heap_default, 0, ctx.tex_desc1, -1, (0 : UInt64), (0 : UInt64), 0, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device14_create_placed_resource2(d, ctx.heap_obj, (0 : Int64), ctx.tex_desc1, -1, (0 : UInt64), 0, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device14_create_reserved_resource2(d, ctx.tiled_desc1, -1, (0 : UInt64), (0 : UInt64), 0, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  ctx.probed.val = ctx.probed.val + 3
  @dx12.dx_d3d12_device14_create_sampler2(d, ctx.samp2_desc, ctx.cpu_samp)
  ctx.probed.val = ctx.probed.val + 1
  let _ = @dx12.dx_d3d12_device14_get_resource_allocation_info3(d, ctx.scratch, 0, 1, ctx.buf_desc, (0 : UInt64), (0 : UInt64), ctx.scratch + (256 : UInt64))
  ctx.probed.val = ctx.probed.val + 1
  let _ = @dx12.com_release(d)
}

///|
fn probe_device_chain(ctx : DeviceCtx) -> Unit {

  probe_device_v0(ctx)

  probe_device_v1(ctx)

  probe_device_v2(ctx)

  probe_device_v3(ctx)

  probe_device_v4(ctx)

  probe_device_v5(ctx)

  probe_device_v6(ctx)

  probe_device_v7(ctx)

  probe_device_v8(ctx)

  probe_device_v9(ctx)

  probe_device_v10(ctx)

  probe_device_v11(ctx)

  probe_device_v12(ctx)

  probe_device_v13(ctx)

  probe_device_v14(ctx)

}
