// Generated-dispatch verification across ID3D12GraphicsCommandList..ID3D12GraphicsCommandList10.

///|
struct CmdCtx {
  cl_base : UInt64
  ca : UInt64
  out_ptr : UInt64
  scratch : UInt64
  priv_guid : UInt64
  priv_val : UInt64
  priv_sz : UInt64
  name_w : UInt64
  rs : UInt64
  gpso : UInt64
  cpso : UInt64
  bundle_cl : UInt64
  dh_gpu_arr : UInt64
  gpu_srv_slot : UInt64
  gpu_uav_uint_slot : UInt64
  cpu_uav_uint_slot : UInt64
  gpu_uav_flt_slot : UInt64
  cpu_uav_flt_slot : UInt64
  rtv_slot : UInt64
  dsv_slot : UInt64
  vp_buf : UInt64
  rect_buf : UInt64
  blend_buf : UInt64
  rgba_buf : UInt64
  u32_clr : UInt64
  flt_clr : UInt64
  const32 : UInt64
  vbv_buf : UInt64
  ibv_buf : UInt64
  buf_src : UInt64
  buf_dst : UInt64
  tex_rt : UInt64
  tex_msaa : UInt64
  tex_res_dst : UInt64
  tex_uav_u32 : UInt64
  tex_uav_flt : UInt64
  tcl_src : UInt64
  tcl_dst : UInt64
  bar_rt_to_copy : UInt64
  bar_to_resolve : UInt64
  bar_resolve_to_copy : UInt64
  bar_rt_uav : UInt64
  qh_occ : UInt64
  buf_rb : UInt64
  csig_draw : UInt64
  wbi_param : UInt64
  wbi_mode : UInt64
  rp_rt : UInt64
  rt_build : UInt64
  rt_post_desc : UInt64
  rt_post_va_arr : UInt64
  rt_tlas_a_va : Int64
  rt_tlas_b_va : Int64
  rt_so : UInt64
  eb_grp : UInt64
  va_cbv : Int64
  va_srv : Int64
  va_uav : Int64
  can_depth_bounds : Bool
  can_sample_pos : Bool
  can_view_inst : Bool
  can_wbi : Bool
  can_rt : Bool
  can_uma : Bool
  vrs_tier : Int
  can_eb : Bool
  can_stencil_ref : Bool
  can_dyn_cut : Bool
  can_dyn_bias : Bool
  probed : Ref[Int]
}


///|
fn probe_cmdlist_v0(ctx : CmdCtx) -> Unit {
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.com_query_interface(ctx.cl_base, @dx12.bytes_ptr(@dx12.iid_d3d12_graphics_command_list), ctx.out_ptr) != 0 {
    return
  }
  let c = @dx12.read_u64(ctx.out_ptr, 0)
  if c == (0 : UInt64) { return }
  let _ = @dx12.dx_d3d12_graphics_command_list_set_private_data(c, ctx.priv_guid, 4, ctx.priv_val)
  @dx12.write_u32(ctx.priv_sz, 0, (4 : UInt32))
  let _ = @dx12.dx_d3d12_graphics_command_list_get_private_data(c, ctx.priv_guid, ctx.priv_sz, ctx.scratch)
  let _ = @dx12.dx_d3d12_graphics_command_list_set_private_data_interface(c, @dx12.bytes_ptr(@dx12.iid_d3d12_command_list), (0 : UInt64))
  let _ = @dx12.dx_d3d12_graphics_command_list_set_name(c, ctx.name_w)
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_graphics_command_list_get_device(c, @dx12.bytes_ptr(@dx12.iid_d3d12_device), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  let _ = @dx12.dx_d3d12_graphics_command_list_get_type(c)
  @dx12.dx_d3d12_graphics_command_list_clear_state(c, ctx.gpso)
  @dx12.dx_d3d12_graphics_command_list_set_pipeline_state(c, ctx.gpso)
  @dx12.dx_d3d12_graphics_command_list_set_descriptor_heaps(c, 1, ctx.dh_gpu_arr)
  @dx12.dx_d3d12_graphics_command_list_set_graphics_root_signature(c, ctx.rs)
  @dx12.dx_d3d12_graphics_command_list_set_graphics_root_descriptor_table(c, 0, ctx.gpu_srv_slot)
  @dx12.dx_d3d12_graphics_command_list_set_graphics_root32_bit_constant(c, 1, 1, 0)
  @dx12.dx_d3d12_graphics_command_list_set_graphics_root32_bit_constants(c, 1, 2, ctx.const32, 0)
  @dx12.dx_d3d12_graphics_command_list_set_graphics_root_constant_buffer_view(c, 2, ctx.va_cbv)
  @dx12.dx_d3d12_graphics_command_list_set_graphics_root_shader_resource_view(c, 3, ctx.va_srv)
  @dx12.dx_d3d12_graphics_command_list_set_graphics_root_unordered_access_view(c, 4, ctx.va_uav)
  @dx12.dx_d3d12_graphics_command_list_ia_set_primitive_topology(c, 4)
  @dx12.dx_d3d12_graphics_command_list_rs_set_viewports(c, 1, ctx.vp_buf)
  @dx12.dx_d3d12_graphics_command_list_rs_set_scissor_rects(c, 1, ctx.rect_buf)
  @dx12.dx_d3d12_graphics_command_list_om_set_blend_factor(c, ctx.blend_buf)
  @dx12.dx_d3d12_graphics_command_list_om_set_stencil_ref(c, 0)
  @dx12.dx_d3d12_graphics_command_list_om_set_render_targets(c, 1, ctx.rtv_slot, 1, ctx.dsv_slot)
  @dx12.dx_d3d12_graphics_command_list_clear_render_target_view(c, ctx.rtv_slot, ctx.rgba_buf, 0, (0 : UInt64))
  @dx12.dx_d3d12_graphics_command_list_clear_depth_stencil_view(c, ctx.dsv_slot, 1, (1.0 : Float), 0, 0, (0 : UInt64))
  @dx12.dx_d3d12_graphics_command_list_ia_set_vertex_buffers(c, 0, 1, ctx.vbv_buf)
  @dx12.dx_d3d12_graphics_command_list_ia_set_index_buffer(c, ctx.ibv_buf)
  @dx12.dx_d3d12_graphics_command_list_so_set_targets(c, 0, 0, (0 : UInt64))
  @dx12.dx_d3d12_graphics_command_list_begin_query(c, ctx.qh_occ, 0, 0)
  @dx12.dx_d3d12_graphics_command_list_draw_instanced(c, 3, 1, 0, 0)
  @dx12.dx_d3d12_graphics_command_list_draw_indexed_instanced(c, 3, 1, 0, 0, 0)
  @dx12.dx_d3d12_graphics_command_list_end_query(c, ctx.qh_occ, 0, 0)
  @dx12.dx_d3d12_graphics_command_list_resolve_query_data(c, ctx.qh_occ, 0, 0, 1, ctx.buf_rb, (0 : Int64))
  @dx12.dx_d3d12_graphics_command_list_execute_indirect(c, ctx.csig_draw, 1, ctx.buf_src, (0 : Int64), (0 : UInt64), (0 : Int64))
  @dx12.dx_d3d12_graphics_command_list_execute_bundle(c, ctx.bundle_cl)
  @dx12.dx_d3d12_graphics_command_list_set_pipeline_state(c, ctx.cpso)
  @dx12.dx_d3d12_graphics_command_list_set_compute_root_signature(c, ctx.rs)
  @dx12.dx_d3d12_graphics_command_list_set_compute_root_descriptor_table(c, 0, ctx.gpu_srv_slot)
  @dx12.dx_d3d12_graphics_command_list_set_compute_root32_bit_constant(c, 1, 1, 0)
  @dx12.dx_d3d12_graphics_command_list_set_compute_root32_bit_constants(c, 1, 2, ctx.const32, 0)
  @dx12.dx_d3d12_graphics_command_list_set_compute_root_constant_buffer_view(c, 2, ctx.va_cbv)
  @dx12.dx_d3d12_graphics_command_list_set_compute_root_shader_resource_view(c, 3, ctx.va_srv)
  @dx12.dx_d3d12_graphics_command_list_set_compute_root_unordered_access_view(c, 4, ctx.va_uav)
  @dx12.dx_d3d12_graphics_command_list_clear_unordered_access_view_uint(c, ctx.gpu_uav_uint_slot, ctx.cpu_uav_uint_slot, ctx.tex_uav_u32, ctx.u32_clr, 0, (0 : UInt64))
  @dx12.dx_d3d12_graphics_command_list_clear_unordered_access_view_float(c, ctx.gpu_uav_flt_slot, ctx.cpu_uav_flt_slot, ctx.tex_uav_flt, ctx.flt_clr, 0, (0 : UInt64))
  @dx12.dx_d3d12_graphics_command_list_dispatch(c, 1, 1, 1)
  @dx12.dx_d3d12_graphics_command_list_copy_buffer_region(c, ctx.buf_dst, (0 : Int64), ctx.buf_src, (0 : Int64), (256 : Int64))
  @dx12.dx_d3d12_graphics_command_list_copy_texture_region(c, ctx.tcl_dst, 0, 0, 0, ctx.tcl_src, (0 : UInt64))
  @dx12.dx_d3d12_graphics_command_list_resource_barrier(c, 1, ctx.bar_rt_to_copy)
  @dx12.dx_d3d12_graphics_command_list_copy_resource(c, ctx.tex_res_dst, ctx.tex_rt)
  @dx12.dx_d3d12_graphics_command_list_resource_barrier(c, 2, ctx.bar_to_resolve)
  @dx12.dx_d3d12_graphics_command_list_resolve_subresource(c, ctx.tex_res_dst, 0, ctx.tex_msaa, 0, 28)
  @dx12.dx_d3d12_graphics_command_list_set_marker(c, 0, (0 : UInt64), 0)
  ctx.probed.val = ctx.probed.val + 53
  @dx12.dx_d3d12_graphics_command_list_resource_barrier(c, 1, ctx.bar_resolve_to_copy)
  let _ = @dx12.dx_d3d12_graphics_command_list_close(c)
  let _ = @dx12.dx_d3d12_graphics_command_list_reset(c, ctx.ca, (0 : UInt64))
  ctx.probed.val = ctx.probed.val + 2
  let _ = @dx12.com_release(c)
}

///|
fn probe_cmdlist_v1(ctx : CmdCtx) -> Unit {
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.com_query_interface(ctx.cl_base, @dx12.bytes_ptr(@dx12.iid_d3d12_graphics_command_list1), ctx.out_ptr) != 0 {
    return
  }
  let c = @dx12.read_u64(ctx.out_ptr, 0)
  if c == (0 : UInt64) { return }
  let _ = @dx12.dx_d3d12_graphics_command_list1_set_private_data(c, ctx.priv_guid, 4, ctx.priv_val)
  @dx12.write_u32(ctx.priv_sz, 0, (4 : UInt32))
  let _ = @dx12.dx_d3d12_graphics_command_list1_get_private_data(c, ctx.priv_guid, ctx.priv_sz, ctx.scratch)
  let _ = @dx12.dx_d3d12_graphics_command_list1_set_private_data_interface(c, @dx12.bytes_ptr(@dx12.iid_d3d12_command_list), (0 : UInt64))
  let _ = @dx12.dx_d3d12_graphics_command_list1_set_name(c, ctx.name_w)
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_graphics_command_list1_get_device(c, @dx12.bytes_ptr(@dx12.iid_d3d12_device), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  let _ = @dx12.dx_d3d12_graphics_command_list1_get_type(c)
  @dx12.dx_d3d12_graphics_command_list1_clear_state(c, ctx.gpso)
  @dx12.dx_d3d12_graphics_command_list1_set_pipeline_state(c, ctx.gpso)
  @dx12.dx_d3d12_graphics_command_list1_set_descriptor_heaps(c, 1, ctx.dh_gpu_arr)
  @dx12.dx_d3d12_graphics_command_list1_set_graphics_root_signature(c, ctx.rs)
  @dx12.dx_d3d12_graphics_command_list1_set_graphics_root_descriptor_table(c, 0, ctx.gpu_srv_slot)
  @dx12.dx_d3d12_graphics_command_list1_set_graphics_root32_bit_constant(c, 1, 1, 0)
  @dx12.dx_d3d12_graphics_command_list1_set_graphics_root32_bit_constants(c, 1, 2, ctx.const32, 0)
  @dx12.dx_d3d12_graphics_command_list1_set_graphics_root_constant_buffer_view(c, 2, ctx.va_cbv)
  @dx12.dx_d3d12_graphics_command_list1_set_graphics_root_shader_resource_view(c, 3, ctx.va_srv)
  @dx12.dx_d3d12_graphics_command_list1_set_graphics_root_unordered_access_view(c, 4, ctx.va_uav)
  @dx12.dx_d3d12_graphics_command_list1_ia_set_primitive_topology(c, 4)
  @dx12.dx_d3d12_graphics_command_list1_rs_set_viewports(c, 1, ctx.vp_buf)
  @dx12.dx_d3d12_graphics_command_list1_rs_set_scissor_rects(c, 1, ctx.rect_buf)
  @dx12.dx_d3d12_graphics_command_list1_om_set_blend_factor(c, ctx.blend_buf)
  @dx12.dx_d3d12_graphics_command_list1_om_set_stencil_ref(c, 0)
  @dx12.dx_d3d12_graphics_command_list1_om_set_render_targets(c, 1, ctx.rtv_slot, 1, ctx.dsv_slot)
  @dx12.dx_d3d12_graphics_command_list1_clear_render_target_view(c, ctx.rtv_slot, ctx.rgba_buf, 0, (0 : UInt64))
  @dx12.dx_d3d12_graphics_command_list1_clear_depth_stencil_view(c, ctx.dsv_slot, 1, (1.0 : Float), 0, 0, (0 : UInt64))
  @dx12.dx_d3d12_graphics_command_list1_ia_set_vertex_buffers(c, 0, 1, ctx.vbv_buf)
  @dx12.dx_d3d12_graphics_command_list1_ia_set_index_buffer(c, ctx.ibv_buf)
  @dx12.dx_d3d12_graphics_command_list1_so_set_targets(c, 0, 0, (0 : UInt64))
  @dx12.dx_d3d12_graphics_command_list1_begin_query(c, ctx.qh_occ, 0, 0)
  @dx12.dx_d3d12_graphics_command_list1_draw_instanced(c, 3, 1, 0, 0)
  @dx12.dx_d3d12_graphics_command_list1_draw_indexed_instanced(c, 3, 1, 0, 0, 0)
  @dx12.dx_d3d12_graphics_command_list1_end_query(c, ctx.qh_occ, 0, 0)
  @dx12.dx_d3d12_graphics_command_list1_resolve_query_data(c, ctx.qh_occ, 0, 0, 1, ctx.buf_rb, (0 : Int64))
  @dx12.dx_d3d12_graphics_command_list1_execute_indirect(c, ctx.csig_draw, 1, ctx.buf_src, (0 : Int64), (0 : UInt64), (0 : Int64))
  @dx12.dx_d3d12_graphics_command_list1_execute_bundle(c, ctx.bundle_cl)
  @dx12.dx_d3d12_graphics_command_list1_set_pipeline_state(c, ctx.cpso)
  @dx12.dx_d3d12_graphics_command_list1_set_compute_root_signature(c, ctx.rs)
  @dx12.dx_d3d12_graphics_command_list1_set_compute_root_descriptor_table(c, 0, ctx.gpu_srv_slot)
  @dx12.dx_d3d12_graphics_command_list1_set_compute_root32_bit_constant(c, 1, 1, 0)
  @dx12.dx_d3d12_graphics_command_list1_set_compute_root32_bit_constants(c, 1, 2, ctx.const32, 0)
  @dx12.dx_d3d12_graphics_command_list1_set_compute_root_constant_buffer_view(c, 2, ctx.va_cbv)
  @dx12.dx_d3d12_graphics_command_list1_set_compute_root_shader_resource_view(c, 3, ctx.va_srv)
  @dx12.dx_d3d12_graphics_command_list1_set_compute_root_unordered_access_view(c, 4, ctx.va_uav)
  @dx12.dx_d3d12_graphics_command_list1_clear_unordered_access_view_uint(c, ctx.gpu_uav_uint_slot, ctx.cpu_uav_uint_slot, ctx.tex_uav_u32, ctx.u32_clr, 0, (0 : UInt64))
  @dx12.dx_d3d12_graphics_command_list1_clear_unordered_access_view_float(c, ctx.gpu_uav_flt_slot, ctx.cpu_uav_flt_slot, ctx.tex_uav_flt, ctx.flt_clr, 0, (0 : UInt64))
  @dx12.dx_d3d12_graphics_command_list1_dispatch(c, 1, 1, 1)
  @dx12.dx_d3d12_graphics_command_list1_copy_buffer_region(c, ctx.buf_dst, (0 : Int64), ctx.buf_src, (0 : Int64), (256 : Int64))
  @dx12.dx_d3d12_graphics_command_list1_copy_texture_region(c, ctx.tcl_dst, 0, 0, 0, ctx.tcl_src, (0 : UInt64))
  @dx12.dx_d3d12_graphics_command_list1_resource_barrier(c, 1, ctx.bar_rt_to_copy)
  @dx12.dx_d3d12_graphics_command_list1_copy_resource(c, ctx.tex_res_dst, ctx.tex_rt)
  @dx12.dx_d3d12_graphics_command_list1_resource_barrier(c, 2, ctx.bar_to_resolve)
  @dx12.dx_d3d12_graphics_command_list1_resolve_subresource(c, ctx.tex_res_dst, 0, ctx.tex_msaa, 0, 28)
  @dx12.dx_d3d12_graphics_command_list1_set_marker(c, 0, (0 : UInt64), 0)
  ctx.probed.val = ctx.probed.val + 53
  @dx12.dx_d3d12_graphics_command_list1_atomic_copy_buffer_uint(c, ctx.buf_dst, (0 : Int64), ctx.buf_src, (0 : Int64), 0, (0 : UInt64), (0 : UInt64))
  if ctx.can_uma { @dx12.dx_d3d12_graphics_command_list1_atomic_copy_buffer_uint64(c, ctx.buf_dst, (0 : Int64), ctx.buf_src, (0 : Int64), 0, (0 : UInt64), (0 : UInt64)) }
  if ctx.can_depth_bounds { @dx12.dx_d3d12_graphics_command_list1_om_set_depth_bounds(c, (0.0 : Float), (1.0 : Float)) }
  if ctx.can_sample_pos { @dx12.dx_d3d12_graphics_command_list1_set_sample_positions(c, 0, 0, (0 : UInt64)) }
  @dx12.dx_d3d12_graphics_command_list1_resolve_subresource_region(c, ctx.tex_res_dst, 0, 0, 0, ctx.tex_msaa, 0, ctx.rect_buf, 28, 3)
  if ctx.can_view_inst { @dx12.dx_d3d12_graphics_command_list1_set_view_instance_mask(c, 1) }
  ctx.probed.val = ctx.probed.val + 6
  @dx12.dx_d3d12_graphics_command_list1_resource_barrier(c, 1, ctx.bar_resolve_to_copy)
  let _ = @dx12.dx_d3d12_graphics_command_list1_close(c)
  let _ = @dx12.dx_d3d12_graphics_command_list1_reset(c, ctx.ca, (0 : UInt64))
  ctx.probed.val = ctx.probed.val + 2
  let _ = @dx12.com_release(c)
}

///|
fn probe_cmdlist_v2(ctx : CmdCtx) -> Unit {
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.com_query_interface(ctx.cl_base, @dx12.bytes_ptr(@dx12.iid_d3d12_graphics_command_list2), ctx.out_ptr) != 0 {
    return
  }
  let c = @dx12.read_u64(ctx.out_ptr, 0)
  if c == (0 : UInt64) { return }
  let _ = @dx12.dx_d3d12_graphics_command_list2_set_private_data(c, ctx.priv_guid, 4, ctx.priv_val)
  @dx12.write_u32(ctx.priv_sz, 0, (4 : UInt32))
  let _ = @dx12.dx_d3d12_graphics_command_list2_get_private_data(c, ctx.priv_guid, ctx.priv_sz, ctx.scratch)
  let _ = @dx12.dx_d3d12_graphics_command_list2_set_private_data_interface(c, @dx12.bytes_ptr(@dx12.iid_d3d12_command_list), (0 : UInt64))
  let _ = @dx12.dx_d3d12_graphics_command_list2_set_name(c, ctx.name_w)
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_graphics_command_list2_get_device(c, @dx12.bytes_ptr(@dx12.iid_d3d12_device), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  let _ = @dx12.dx_d3d12_graphics_command_list2_get_type(c)
  @dx12.dx_d3d12_graphics_command_list2_clear_state(c, ctx.gpso)
  @dx12.dx_d3d12_graphics_command_list2_set_pipeline_state(c, ctx.gpso)
  @dx12.dx_d3d12_graphics_command_list2_set_descriptor_heaps(c, 1, ctx.dh_gpu_arr)
  @dx12.dx_d3d12_graphics_command_list2_set_graphics_root_signature(c, ctx.rs)
  @dx12.dx_d3d12_graphics_command_list2_set_graphics_root_descriptor_table(c, 0, ctx.gpu_srv_slot)
  @dx12.dx_d3d12_graphics_command_list2_set_graphics_root32_bit_constant(c, 1, 1, 0)
  @dx12.dx_d3d12_graphics_command_list2_set_graphics_root32_bit_constants(c, 1, 2, ctx.const32, 0)
  @dx12.dx_d3d12_graphics_command_list2_set_graphics_root_constant_buffer_view(c, 2, ctx.va_cbv)
  @dx12.dx_d3d12_graphics_command_list2_set_graphics_root_shader_resource_view(c, 3, ctx.va_srv)
  @dx12.dx_d3d12_graphics_command_list2_set_graphics_root_unordered_access_view(c, 4, ctx.va_uav)
  @dx12.dx_d3d12_graphics_command_list2_ia_set_primitive_topology(c, 4)
  @dx12.dx_d3d12_graphics_command_list2_rs_set_viewports(c, 1, ctx.vp_buf)
  @dx12.dx_d3d12_graphics_command_list2_rs_set_scissor_rects(c, 1, ctx.rect_buf)
  @dx12.dx_d3d12_graphics_command_list2_om_set_blend_factor(c, ctx.blend_buf)
  @dx12.dx_d3d12_graphics_command_list2_om_set_stencil_ref(c, 0)
  @dx12.dx_d3d12_graphics_command_list2_om_set_render_targets(c, 1, ctx.rtv_slot, 1, ctx.dsv_slot)
  @dx12.dx_d3d12_graphics_command_list2_clear_render_target_view(c, ctx.rtv_slot, ctx.rgba_buf, 0, (0 : UInt64))
  @dx12.dx_d3d12_graphics_command_list2_clear_depth_stencil_view(c, ctx.dsv_slot, 1, (1.0 : Float), 0, 0, (0 : UInt64))
  @dx12.dx_d3d12_graphics_command_list2_ia_set_vertex_buffers(c, 0, 1, ctx.vbv_buf)
  @dx12.dx_d3d12_graphics_command_list2_ia_set_index_buffer(c, ctx.ibv_buf)
  @dx12.dx_d3d12_graphics_command_list2_so_set_targets(c, 0, 0, (0 : UInt64))
  @dx12.dx_d3d12_graphics_command_list2_begin_query(c, ctx.qh_occ, 0, 0)
  @dx12.dx_d3d12_graphics_command_list2_draw_instanced(c, 3, 1, 0, 0)
  @dx12.dx_d3d12_graphics_command_list2_draw_indexed_instanced(c, 3, 1, 0, 0, 0)
  @dx12.dx_d3d12_graphics_command_list2_end_query(c, ctx.qh_occ, 0, 0)
  @dx12.dx_d3d12_graphics_command_list2_resolve_query_data(c, ctx.qh_occ, 0, 0, 1, ctx.buf_rb, (0 : Int64))
  @dx12.dx_d3d12_graphics_command_list2_execute_indirect(c, ctx.csig_draw, 1, ctx.buf_src, (0 : Int64), (0 : UInt64), (0 : Int64))
  @dx12.dx_d3d12_graphics_command_list2_execute_bundle(c, ctx.bundle_cl)
  @dx12.dx_d3d12_graphics_command_list2_set_pipeline_state(c, ctx.cpso)
  @dx12.dx_d3d12_graphics_command_list2_set_compute_root_signature(c, ctx.rs)
  @dx12.dx_d3d12_graphics_command_list2_set_compute_root_descriptor_table(c, 0, ctx.gpu_srv_slot)
  @dx12.dx_d3d12_graphics_command_list2_set_compute_root32_bit_constant(c, 1, 1, 0)
  @dx12.dx_d3d12_graphics_command_list2_set_compute_root32_bit_constants(c, 1, 2, ctx.const32, 0)
  @dx12.dx_d3d12_graphics_command_list2_set_compute_root_constant_buffer_view(c, 2, ctx.va_cbv)
  @dx12.dx_d3d12_graphics_command_list2_set_compute_root_shader_resource_view(c, 3, ctx.va_srv)
  @dx12.dx_d3d12_graphics_command_list2_set_compute_root_unordered_access_view(c, 4, ctx.va_uav)
  @dx12.dx_d3d12_graphics_command_list2_clear_unordered_access_view_uint(c, ctx.gpu_uav_uint_slot, ctx.cpu_uav_uint_slot, ctx.tex_uav_u32, ctx.u32_clr, 0, (0 : UInt64))
  @dx12.dx_d3d12_graphics_command_list2_clear_unordered_access_view_float(c, ctx.gpu_uav_flt_slot, ctx.cpu_uav_flt_slot, ctx.tex_uav_flt, ctx.flt_clr, 0, (0 : UInt64))
  @dx12.dx_d3d12_graphics_command_list2_dispatch(c, 1, 1, 1)
  @dx12.dx_d3d12_graphics_command_list2_copy_buffer_region(c, ctx.buf_dst, (0 : Int64), ctx.buf_src, (0 : Int64), (256 : Int64))
  @dx12.dx_d3d12_graphics_command_list2_copy_texture_region(c, ctx.tcl_dst, 0, 0, 0, ctx.tcl_src, (0 : UInt64))
  @dx12.dx_d3d12_graphics_command_list2_resource_barrier(c, 1, ctx.bar_rt_to_copy)
  @dx12.dx_d3d12_graphics_command_list2_copy_resource(c, ctx.tex_res_dst, ctx.tex_rt)
  @dx12.dx_d3d12_graphics_command_list2_resource_barrier(c, 2, ctx.bar_to_resolve)
  @dx12.dx_d3d12_graphics_command_list2_resolve_subresource(c, ctx.tex_res_dst, 0, ctx.tex_msaa, 0, 28)
  @dx12.dx_d3d12_graphics_command_list2_set_marker(c, 0, (0 : UInt64), 0)
  ctx.probed.val = ctx.probed.val + 53
  @dx12.dx_d3d12_graphics_command_list2_atomic_copy_buffer_uint(c, ctx.buf_dst, (0 : Int64), ctx.buf_src, (0 : Int64), 0, (0 : UInt64), (0 : UInt64))
  if ctx.can_uma { @dx12.dx_d3d12_graphics_command_list2_atomic_copy_buffer_uint64(c, ctx.buf_dst, (0 : Int64), ctx.buf_src, (0 : Int64), 0, (0 : UInt64), (0 : UInt64)) }
  if ctx.can_depth_bounds { @dx12.dx_d3d12_graphics_command_list2_om_set_depth_bounds(c, (0.0 : Float), (1.0 : Float)) }
  if ctx.can_sample_pos { @dx12.dx_d3d12_graphics_command_list2_set_sample_positions(c, 0, 0, (0 : UInt64)) }
  @dx12.dx_d3d12_graphics_command_list2_resolve_subresource_region(c, ctx.tex_res_dst, 0, 0, 0, ctx.tex_msaa, 0, ctx.rect_buf, 28, 3)
  if ctx.can_view_inst { @dx12.dx_d3d12_graphics_command_list2_set_view_instance_mask(c, 1) }
  ctx.probed.val = ctx.probed.val + 6
  if ctx.can_wbi { @dx12.dx_d3d12_graphics_command_list2_write_buffer_immediate(c, 1, ctx.wbi_param, ctx.wbi_mode) }
  ctx.probed.val = ctx.probed.val + 1
  @dx12.dx_d3d12_graphics_command_list2_resource_barrier(c, 1, ctx.bar_resolve_to_copy)
  let _ = @dx12.dx_d3d12_graphics_command_list2_close(c)
  let _ = @dx12.dx_d3d12_graphics_command_list2_reset(c, ctx.ca, (0 : UInt64))
  ctx.probed.val = ctx.probed.val + 2
  let _ = @dx12.com_release(c)
}

///|
fn probe_cmdlist_v3(ctx : CmdCtx) -> Unit {
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.com_query_interface(ctx.cl_base, @dx12.bytes_ptr(@dx12.iid_d3d12_graphics_command_list3), ctx.out_ptr) != 0 {
    return
  }
  let c = @dx12.read_u64(ctx.out_ptr, 0)
  if c == (0 : UInt64) { return }
  let _ = @dx12.dx_d3d12_graphics_command_list3_set_private_data(c, ctx.priv_guid, 4, ctx.priv_val)
  @dx12.write_u32(ctx.priv_sz, 0, (4 : UInt32))
  let _ = @dx12.dx_d3d12_graphics_command_list3_get_private_data(c, ctx.priv_guid, ctx.priv_sz, ctx.scratch)
  let _ = @dx12.dx_d3d12_graphics_command_list3_set_private_data_interface(c, @dx12.bytes_ptr(@dx12.iid_d3d12_command_list), (0 : UInt64))
  let _ = @dx12.dx_d3d12_graphics_command_list3_set_name(c, ctx.name_w)
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_graphics_command_list3_get_device(c, @dx12.bytes_ptr(@dx12.iid_d3d12_device), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  let _ = @dx12.dx_d3d12_graphics_command_list3_get_type(c)
  @dx12.dx_d3d12_graphics_command_list3_clear_state(c, ctx.gpso)
  @dx12.dx_d3d12_graphics_command_list3_set_pipeline_state(c, ctx.gpso)
  @dx12.dx_d3d12_graphics_command_list3_set_descriptor_heaps(c, 1, ctx.dh_gpu_arr)
  @dx12.dx_d3d12_graphics_command_list3_set_graphics_root_signature(c, ctx.rs)
  @dx12.dx_d3d12_graphics_command_list3_set_graphics_root_descriptor_table(c, 0, ctx.gpu_srv_slot)
  @dx12.dx_d3d12_graphics_command_list3_set_graphics_root32_bit_constant(c, 1, 1, 0)
  @dx12.dx_d3d12_graphics_command_list3_set_graphics_root32_bit_constants(c, 1, 2, ctx.const32, 0)
  @dx12.dx_d3d12_graphics_command_list3_set_graphics_root_constant_buffer_view(c, 2, ctx.va_cbv)
  @dx12.dx_d3d12_graphics_command_list3_set_graphics_root_shader_resource_view(c, 3, ctx.va_srv)
  @dx12.dx_d3d12_graphics_command_list3_set_graphics_root_unordered_access_view(c, 4, ctx.va_uav)
  @dx12.dx_d3d12_graphics_command_list3_ia_set_primitive_topology(c, 4)
  @dx12.dx_d3d12_graphics_command_list3_rs_set_viewports(c, 1, ctx.vp_buf)
  @dx12.dx_d3d12_graphics_command_list3_rs_set_scissor_rects(c, 1, ctx.rect_buf)
  @dx12.dx_d3d12_graphics_command_list3_om_set_blend_factor(c, ctx.blend_buf)
  @dx12.dx_d3d12_graphics_command_list3_om_set_stencil_ref(c, 0)
  @dx12.dx_d3d12_graphics_command_list3_om_set_render_targets(c, 1, ctx.rtv_slot, 1, ctx.dsv_slot)
  @dx12.dx_d3d12_graphics_command_list3_clear_render_target_view(c, ctx.rtv_slot, ctx.rgba_buf, 0, (0 : UInt64))
  @dx12.dx_d3d12_graphics_command_list3_clear_depth_stencil_view(c, ctx.dsv_slot, 1, (1.0 : Float), 0, 0, (0 : UInt64))
  @dx12.dx_d3d12_graphics_command_list3_ia_set_vertex_buffers(c, 0, 1, ctx.vbv_buf)
  @dx12.dx_d3d12_graphics_command_list3_ia_set_index_buffer(c, ctx.ibv_buf)
  @dx12.dx_d3d12_graphics_command_list3_so_set_targets(c, 0, 0, (0 : UInt64))
  @dx12.dx_d3d12_graphics_command_list3_begin_query(c, ctx.qh_occ, 0, 0)
  @dx12.dx_d3d12_graphics_command_list3_draw_instanced(c, 3, 1, 0, 0)
  @dx12.dx_d3d12_graphics_command_list3_draw_indexed_instanced(c, 3, 1, 0, 0, 0)
  @dx12.dx_d3d12_graphics_command_list3_end_query(c, ctx.qh_occ, 0, 0)
  @dx12.dx_d3d12_graphics_command_list3_resolve_query_data(c, ctx.qh_occ, 0, 0, 1, ctx.buf_rb, (0 : Int64))
  @dx12.dx_d3d12_graphics_command_list3_execute_indirect(c, ctx.csig_draw, 1, ctx.buf_src, (0 : Int64), (0 : UInt64), (0 : Int64))
  @dx12.dx_d3d12_graphics_command_list3_execute_bundle(c, ctx.bundle_cl)
  @dx12.dx_d3d12_graphics_command_list3_set_pipeline_state(c, ctx.cpso)
  @dx12.dx_d3d12_graphics_command_list3_set_compute_root_signature(c, ctx.rs)
  @dx12.dx_d3d12_graphics_command_list3_set_compute_root_descriptor_table(c, 0, ctx.gpu_srv_slot)
  @dx12.dx_d3d12_graphics_command_list3_set_compute_root32_bit_constant(c, 1, 1, 0)
  @dx12.dx_d3d12_graphics_command_list3_set_compute_root32_bit_constants(c, 1, 2, ctx.const32, 0)
  @dx12.dx_d3d12_graphics_command_list3_set_compute_root_constant_buffer_view(c, 2, ctx.va_cbv)
  @dx12.dx_d3d12_graphics_command_list3_set_compute_root_shader_resource_view(c, 3, ctx.va_srv)
  @dx12.dx_d3d12_graphics_command_list3_set_compute_root_unordered_access_view(c, 4, ctx.va_uav)
  @dx12.dx_d3d12_graphics_command_list3_clear_unordered_access_view_uint(c, ctx.gpu_uav_uint_slot, ctx.cpu_uav_uint_slot, ctx.tex_uav_u32, ctx.u32_clr, 0, (0 : UInt64))
  @dx12.dx_d3d12_graphics_command_list3_clear_unordered_access_view_float(c, ctx.gpu_uav_flt_slot, ctx.cpu_uav_flt_slot, ctx.tex_uav_flt, ctx.flt_clr, 0, (0 : UInt64))
  @dx12.dx_d3d12_graphics_command_list3_dispatch(c, 1, 1, 1)
  @dx12.dx_d3d12_graphics_command_list3_copy_buffer_region(c, ctx.buf_dst, (0 : Int64), ctx.buf_src, (0 : Int64), (256 : Int64))
  @dx12.dx_d3d12_graphics_command_list3_copy_texture_region(c, ctx.tcl_dst, 0, 0, 0, ctx.tcl_src, (0 : UInt64))
  @dx12.dx_d3d12_graphics_command_list3_resource_barrier(c, 1, ctx.bar_rt_to_copy)
  @dx12.dx_d3d12_graphics_command_list3_copy_resource(c, ctx.tex_res_dst, ctx.tex_rt)
  @dx12.dx_d3d12_graphics_command_list3_resource_barrier(c, 2, ctx.bar_to_resolve)
  @dx12.dx_d3d12_graphics_command_list3_resolve_subresource(c, ctx.tex_res_dst, 0, ctx.tex_msaa, 0, 28)
  @dx12.dx_d3d12_graphics_command_list3_set_marker(c, 0, (0 : UInt64), 0)
  ctx.probed.val = ctx.probed.val + 53
  @dx12.dx_d3d12_graphics_command_list3_atomic_copy_buffer_uint(c, ctx.buf_dst, (0 : Int64), ctx.buf_src, (0 : Int64), 0, (0 : UInt64), (0 : UInt64))
  if ctx.can_uma { @dx12.dx_d3d12_graphics_command_list3_atomic_copy_buffer_uint64(c, ctx.buf_dst, (0 : Int64), ctx.buf_src, (0 : Int64), 0, (0 : UInt64), (0 : UInt64)) }
  if ctx.can_depth_bounds { @dx12.dx_d3d12_graphics_command_list3_om_set_depth_bounds(c, (0.0 : Float), (1.0 : Float)) }
  if ctx.can_sample_pos { @dx12.dx_d3d12_graphics_command_list3_set_sample_positions(c, 0, 0, (0 : UInt64)) }
  @dx12.dx_d3d12_graphics_command_list3_resolve_subresource_region(c, ctx.tex_res_dst, 0, 0, 0, ctx.tex_msaa, 0, ctx.rect_buf, 28, 3)
  if ctx.can_view_inst { @dx12.dx_d3d12_graphics_command_list3_set_view_instance_mask(c, 1) }
  ctx.probed.val = ctx.probed.val + 6
  if ctx.can_wbi { @dx12.dx_d3d12_graphics_command_list3_write_buffer_immediate(c, 1, ctx.wbi_param, ctx.wbi_mode) }
  ctx.probed.val = ctx.probed.val + 1
  @dx12.dx_d3d12_graphics_command_list3_resource_barrier(c, 1, ctx.bar_resolve_to_copy)
  let _ = @dx12.dx_d3d12_graphics_command_list3_close(c)
  let _ = @dx12.dx_d3d12_graphics_command_list3_reset(c, ctx.ca, (0 : UInt64))
  ctx.probed.val = ctx.probed.val + 2
  let _ = @dx12.com_release(c)
}

///|
fn probe_cmdlist_v4(ctx : CmdCtx) -> Unit {
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.com_query_interface(ctx.cl_base, @dx12.bytes_ptr(@dx12.iid_d3d12_graphics_command_list4), ctx.out_ptr) != 0 {
    return
  }
  let c = @dx12.read_u64(ctx.out_ptr, 0)
  if c == (0 : UInt64) { return }
  let _ = @dx12.dx_d3d12_graphics_command_list4_set_private_data(c, ctx.priv_guid, 4, ctx.priv_val)
  @dx12.write_u32(ctx.priv_sz, 0, (4 : UInt32))
  let _ = @dx12.dx_d3d12_graphics_command_list4_get_private_data(c, ctx.priv_guid, ctx.priv_sz, ctx.scratch)
  let _ = @dx12.dx_d3d12_graphics_command_list4_set_private_data_interface(c, @dx12.bytes_ptr(@dx12.iid_d3d12_command_list), (0 : UInt64))
  let _ = @dx12.dx_d3d12_graphics_command_list4_set_name(c, ctx.name_w)
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_graphics_command_list4_get_device(c, @dx12.bytes_ptr(@dx12.iid_d3d12_device), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  let _ = @dx12.dx_d3d12_graphics_command_list4_get_type(c)
  @dx12.dx_d3d12_graphics_command_list4_clear_state(c, ctx.gpso)
  @dx12.dx_d3d12_graphics_command_list4_set_pipeline_state(c, ctx.gpso)
  @dx12.dx_d3d12_graphics_command_list4_set_descriptor_heaps(c, 1, ctx.dh_gpu_arr)
  @dx12.dx_d3d12_graphics_command_list4_set_graphics_root_signature(c, ctx.rs)
  @dx12.dx_d3d12_graphics_command_list4_set_graphics_root_descriptor_table(c, 0, ctx.gpu_srv_slot)
  @dx12.dx_d3d12_graphics_command_list4_set_graphics_root32_bit_constant(c, 1, 1, 0)
  @dx12.dx_d3d12_graphics_command_list4_set_graphics_root32_bit_constants(c, 1, 2, ctx.const32, 0)
  @dx12.dx_d3d12_graphics_command_list4_set_graphics_root_constant_buffer_view(c, 2, ctx.va_cbv)
  @dx12.dx_d3d12_graphics_command_list4_set_graphics_root_shader_resource_view(c, 3, ctx.va_srv)
  @dx12.dx_d3d12_graphics_command_list4_set_graphics_root_unordered_access_view(c, 4, ctx.va_uav)
  @dx12.dx_d3d12_graphics_command_list4_ia_set_primitive_topology(c, 4)
  @dx12.dx_d3d12_graphics_command_list4_rs_set_viewports(c, 1, ctx.vp_buf)
  @dx12.dx_d3d12_graphics_command_list4_rs_set_scissor_rects(c, 1, ctx.rect_buf)
  @dx12.dx_d3d12_graphics_command_list4_om_set_blend_factor(c, ctx.blend_buf)
  @dx12.dx_d3d12_graphics_command_list4_om_set_stencil_ref(c, 0)
  @dx12.dx_d3d12_graphics_command_list4_om_set_render_targets(c, 1, ctx.rtv_slot, 1, ctx.dsv_slot)
  @dx12.dx_d3d12_graphics_command_list4_clear_render_target_view(c, ctx.rtv_slot, ctx.rgba_buf, 0, (0 : UInt64))
  @dx12.dx_d3d12_graphics_command_list4_clear_depth_stencil_view(c, ctx.dsv_slot, 1, (1.0 : Float), 0, 0, (0 : UInt64))
  @dx12.dx_d3d12_graphics_command_list4_ia_set_vertex_buffers(c, 0, 1, ctx.vbv_buf)
  @dx12.dx_d3d12_graphics_command_list4_ia_set_index_buffer(c, ctx.ibv_buf)
  @dx12.dx_d3d12_graphics_command_list4_so_set_targets(c, 0, 0, (0 : UInt64))
  @dx12.dx_d3d12_graphics_command_list4_begin_query(c, ctx.qh_occ, 0, 0)
  @dx12.dx_d3d12_graphics_command_list4_draw_instanced(c, 3, 1, 0, 0)
  @dx12.dx_d3d12_graphics_command_list4_draw_indexed_instanced(c, 3, 1, 0, 0, 0)
  @dx12.dx_d3d12_graphics_command_list4_end_query(c, ctx.qh_occ, 0, 0)
  @dx12.dx_d3d12_graphics_command_list4_resolve_query_data(c, ctx.qh_occ, 0, 0, 1, ctx.buf_rb, (0 : Int64))
  @dx12.dx_d3d12_graphics_command_list4_execute_indirect(c, ctx.csig_draw, 1, ctx.buf_src, (0 : Int64), (0 : UInt64), (0 : Int64))
  @dx12.dx_d3d12_graphics_command_list4_execute_bundle(c, ctx.bundle_cl)
  @dx12.dx_d3d12_graphics_command_list4_set_pipeline_state(c, ctx.cpso)
  @dx12.dx_d3d12_graphics_command_list4_set_compute_root_signature(c, ctx.rs)
  @dx12.dx_d3d12_graphics_command_list4_set_compute_root_descriptor_table(c, 0, ctx.gpu_srv_slot)
  @dx12.dx_d3d12_graphics_command_list4_set_compute_root32_bit_constant(c, 1, 1, 0)
  @dx12.dx_d3d12_graphics_command_list4_set_compute_root32_bit_constants(c, 1, 2, ctx.const32, 0)
  @dx12.dx_d3d12_graphics_command_list4_set_compute_root_constant_buffer_view(c, 2, ctx.va_cbv)
  @dx12.dx_d3d12_graphics_command_list4_set_compute_root_shader_resource_view(c, 3, ctx.va_srv)
  @dx12.dx_d3d12_graphics_command_list4_set_compute_root_unordered_access_view(c, 4, ctx.va_uav)
  @dx12.dx_d3d12_graphics_command_list4_clear_unordered_access_view_uint(c, ctx.gpu_uav_uint_slot, ctx.cpu_uav_uint_slot, ctx.tex_uav_u32, ctx.u32_clr, 0, (0 : UInt64))
  @dx12.dx_d3d12_graphics_command_list4_clear_unordered_access_view_float(c, ctx.gpu_uav_flt_slot, ctx.cpu_uav_flt_slot, ctx.tex_uav_flt, ctx.flt_clr, 0, (0 : UInt64))
  @dx12.dx_d3d12_graphics_command_list4_dispatch(c, 1, 1, 1)
  @dx12.dx_d3d12_graphics_command_list4_copy_buffer_region(c, ctx.buf_dst, (0 : Int64), ctx.buf_src, (0 : Int64), (256 : Int64))
  @dx12.dx_d3d12_graphics_command_list4_copy_texture_region(c, ctx.tcl_dst, 0, 0, 0, ctx.tcl_src, (0 : UInt64))
  @dx12.dx_d3d12_graphics_command_list4_resource_barrier(c, 1, ctx.bar_rt_to_copy)
  @dx12.dx_d3d12_graphics_command_list4_copy_resource(c, ctx.tex_res_dst, ctx.tex_rt)
  @dx12.dx_d3d12_graphics_command_list4_resource_barrier(c, 2, ctx.bar_to_resolve)
  @dx12.dx_d3d12_graphics_command_list4_resolve_subresource(c, ctx.tex_res_dst, 0, ctx.tex_msaa, 0, 28)
  @dx12.dx_d3d12_graphics_command_list4_set_marker(c, 0, (0 : UInt64), 0)
  ctx.probed.val = ctx.probed.val + 53
  @dx12.dx_d3d12_graphics_command_list4_atomic_copy_buffer_uint(c, ctx.buf_dst, (0 : Int64), ctx.buf_src, (0 : Int64), 0, (0 : UInt64), (0 : UInt64))
  if ctx.can_uma { @dx12.dx_d3d12_graphics_command_list4_atomic_copy_buffer_uint64(c, ctx.buf_dst, (0 : Int64), ctx.buf_src, (0 : Int64), 0, (0 : UInt64), (0 : UInt64)) }
  if ctx.can_depth_bounds { @dx12.dx_d3d12_graphics_command_list4_om_set_depth_bounds(c, (0.0 : Float), (1.0 : Float)) }
  if ctx.can_sample_pos { @dx12.dx_d3d12_graphics_command_list4_set_sample_positions(c, 0, 0, (0 : UInt64)) }
  @dx12.dx_d3d12_graphics_command_list4_resolve_subresource_region(c, ctx.tex_res_dst, 0, 0, 0, ctx.tex_msaa, 0, ctx.rect_buf, 28, 3)
  if ctx.can_view_inst { @dx12.dx_d3d12_graphics_command_list4_set_view_instance_mask(c, 1) }
  ctx.probed.val = ctx.probed.val + 6
  if ctx.can_wbi { @dx12.dx_d3d12_graphics_command_list4_write_buffer_immediate(c, 1, ctx.wbi_param, ctx.wbi_mode) }
  ctx.probed.val = ctx.probed.val + 1
  @dx12.dx_d3d12_graphics_command_list4_begin_render_pass(c, 1, ctx.rp_rt, (0 : UInt64), 0)
  @dx12.dx_d3d12_graphics_command_list4_end_render_pass(c)
  if ctx.can_rt {
    @dx12.dx_d3d12_graphics_command_list4_build_raytracing_acceleration_structure(c, ctx.rt_build, 0, (0 : UInt64))
    @dx12.dx_d3d12_graphics_command_list4_resource_barrier(c, 1, ctx.bar_rt_uav)
    @dx12.dx_d3d12_graphics_command_list4_emit_raytracing_acceleration_structure_postbuild_info(c, ctx.rt_post_desc, 1, ctx.rt_post_va_arr)
    @dx12.dx_d3d12_graphics_command_list4_copy_raytracing_acceleration_structure(c, ctx.rt_tlas_b_va, ctx.rt_tlas_a_va, 0)
    if ctx.rt_so != (0 : UInt64) { @dx12.dx_d3d12_graphics_command_list4_set_pipeline_state1(c, ctx.rt_so) }
  }
  ctx.probed.val = ctx.probed.val + 6
  @dx12.dx_d3d12_graphics_command_list4_resource_barrier(c, 1, ctx.bar_resolve_to_copy)
  let _ = @dx12.dx_d3d12_graphics_command_list4_close(c)
  let _ = @dx12.dx_d3d12_graphics_command_list4_reset(c, ctx.ca, (0 : UInt64))
  ctx.probed.val = ctx.probed.val + 2
  let _ = @dx12.com_release(c)
}

///|
fn probe_cmdlist_v5(ctx : CmdCtx) -> Unit {
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.com_query_interface(ctx.cl_base, @dx12.bytes_ptr(@dx12.iid_d3d12_graphics_command_list5), ctx.out_ptr) != 0 {
    return
  }
  let c = @dx12.read_u64(ctx.out_ptr, 0)
  if c == (0 : UInt64) { return }
  let _ = @dx12.dx_d3d12_graphics_command_list5_set_private_data(c, ctx.priv_guid, 4, ctx.priv_val)
  @dx12.write_u32(ctx.priv_sz, 0, (4 : UInt32))
  let _ = @dx12.dx_d3d12_graphics_command_list5_get_private_data(c, ctx.priv_guid, ctx.priv_sz, ctx.scratch)
  let _ = @dx12.dx_d3d12_graphics_command_list5_set_private_data_interface(c, @dx12.bytes_ptr(@dx12.iid_d3d12_command_list), (0 : UInt64))
  let _ = @dx12.dx_d3d12_graphics_command_list5_set_name(c, ctx.name_w)
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_graphics_command_list5_get_device(c, @dx12.bytes_ptr(@dx12.iid_d3d12_device), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  let _ = @dx12.dx_d3d12_graphics_command_list5_get_type(c)
  @dx12.dx_d3d12_graphics_command_list5_clear_state(c, ctx.gpso)
  @dx12.dx_d3d12_graphics_command_list5_set_pipeline_state(c, ctx.gpso)
  @dx12.dx_d3d12_graphics_command_list5_set_descriptor_heaps(c, 1, ctx.dh_gpu_arr)
  @dx12.dx_d3d12_graphics_command_list5_set_graphics_root_signature(c, ctx.rs)
  @dx12.dx_d3d12_graphics_command_list5_set_graphics_root_descriptor_table(c, 0, ctx.gpu_srv_slot)
  @dx12.dx_d3d12_graphics_command_list5_set_graphics_root32_bit_constant(c, 1, 1, 0)
  @dx12.dx_d3d12_graphics_command_list5_set_graphics_root32_bit_constants(c, 1, 2, ctx.const32, 0)
  @dx12.dx_d3d12_graphics_command_list5_set_graphics_root_constant_buffer_view(c, 2, ctx.va_cbv)
  @dx12.dx_d3d12_graphics_command_list5_set_graphics_root_shader_resource_view(c, 3, ctx.va_srv)
  @dx12.dx_d3d12_graphics_command_list5_set_graphics_root_unordered_access_view(c, 4, ctx.va_uav)
  @dx12.dx_d3d12_graphics_command_list5_ia_set_primitive_topology(c, 4)
  @dx12.dx_d3d12_graphics_command_list5_rs_set_viewports(c, 1, ctx.vp_buf)
  @dx12.dx_d3d12_graphics_command_list5_rs_set_scissor_rects(c, 1, ctx.rect_buf)
  @dx12.dx_d3d12_graphics_command_list5_om_set_blend_factor(c, ctx.blend_buf)
  @dx12.dx_d3d12_graphics_command_list5_om_set_stencil_ref(c, 0)
  @dx12.dx_d3d12_graphics_command_list5_om_set_render_targets(c, 1, ctx.rtv_slot, 1, ctx.dsv_slot)
  @dx12.dx_d3d12_graphics_command_list5_clear_render_target_view(c, ctx.rtv_slot, ctx.rgba_buf, 0, (0 : UInt64))
  @dx12.dx_d3d12_graphics_command_list5_clear_depth_stencil_view(c, ctx.dsv_slot, 1, (1.0 : Float), 0, 0, (0 : UInt64))
  @dx12.dx_d3d12_graphics_command_list5_ia_set_vertex_buffers(c, 0, 1, ctx.vbv_buf)
  @dx12.dx_d3d12_graphics_command_list5_ia_set_index_buffer(c, ctx.ibv_buf)
  @dx12.dx_d3d12_graphics_command_list5_so_set_targets(c, 0, 0, (0 : UInt64))
  @dx12.dx_d3d12_graphics_command_list5_begin_query(c, ctx.qh_occ, 0, 0)
  @dx12.dx_d3d12_graphics_command_list5_draw_instanced(c, 3, 1, 0, 0)
  @dx12.dx_d3d12_graphics_command_list5_draw_indexed_instanced(c, 3, 1, 0, 0, 0)
  @dx12.dx_d3d12_graphics_command_list5_end_query(c, ctx.qh_occ, 0, 0)
  @dx12.dx_d3d12_graphics_command_list5_resolve_query_data(c, ctx.qh_occ, 0, 0, 1, ctx.buf_rb, (0 : Int64))
  @dx12.dx_d3d12_graphics_command_list5_execute_indirect(c, ctx.csig_draw, 1, ctx.buf_src, (0 : Int64), (0 : UInt64), (0 : Int64))
  @dx12.dx_d3d12_graphics_command_list5_execute_bundle(c, ctx.bundle_cl)
  @dx12.dx_d3d12_graphics_command_list5_set_pipeline_state(c, ctx.cpso)
  @dx12.dx_d3d12_graphics_command_list5_set_compute_root_signature(c, ctx.rs)
  @dx12.dx_d3d12_graphics_command_list5_set_compute_root_descriptor_table(c, 0, ctx.gpu_srv_slot)
  @dx12.dx_d3d12_graphics_command_list5_set_compute_root32_bit_constant(c, 1, 1, 0)
  @dx12.dx_d3d12_graphics_command_list5_set_compute_root32_bit_constants(c, 1, 2, ctx.const32, 0)
  @dx12.dx_d3d12_graphics_command_list5_set_compute_root_constant_buffer_view(c, 2, ctx.va_cbv)
  @dx12.dx_d3d12_graphics_command_list5_set_compute_root_shader_resource_view(c, 3, ctx.va_srv)
  @dx12.dx_d3d12_graphics_command_list5_set_compute_root_unordered_access_view(c, 4, ctx.va_uav)
  @dx12.dx_d3d12_graphics_command_list5_clear_unordered_access_view_uint(c, ctx.gpu_uav_uint_slot, ctx.cpu_uav_uint_slot, ctx.tex_uav_u32, ctx.u32_clr, 0, (0 : UInt64))
  @dx12.dx_d3d12_graphics_command_list5_clear_unordered_access_view_float(c, ctx.gpu_uav_flt_slot, ctx.cpu_uav_flt_slot, ctx.tex_uav_flt, ctx.flt_clr, 0, (0 : UInt64))
  @dx12.dx_d3d12_graphics_command_list5_dispatch(c, 1, 1, 1)
  @dx12.dx_d3d12_graphics_command_list5_copy_buffer_region(c, ctx.buf_dst, (0 : Int64), ctx.buf_src, (0 : Int64), (256 : Int64))
  @dx12.dx_d3d12_graphics_command_list5_copy_texture_region(c, ctx.tcl_dst, 0, 0, 0, ctx.tcl_src, (0 : UInt64))
  @dx12.dx_d3d12_graphics_command_list5_resource_barrier(c, 1, ctx.bar_rt_to_copy)
  @dx12.dx_d3d12_graphics_command_list5_copy_resource(c, ctx.tex_res_dst, ctx.tex_rt)
  @dx12.dx_d3d12_graphics_command_list5_resource_barrier(c, 2, ctx.bar_to_resolve)
  @dx12.dx_d3d12_graphics_command_list5_resolve_subresource(c, ctx.tex_res_dst, 0, ctx.tex_msaa, 0, 28)
  @dx12.dx_d3d12_graphics_command_list5_set_marker(c, 0, (0 : UInt64), 0)
  ctx.probed.val = ctx.probed.val + 53
  @dx12.dx_d3d12_graphics_command_list5_atomic_copy_buffer_uint(c, ctx.buf_dst, (0 : Int64), ctx.buf_src, (0 : Int64), 0, (0 : UInt64), (0 : UInt64))
  if ctx.can_uma { @dx12.dx_d3d12_graphics_command_list5_atomic_copy_buffer_uint64(c, ctx.buf_dst, (0 : Int64), ctx.buf_src, (0 : Int64), 0, (0 : UInt64), (0 : UInt64)) }
  if ctx.can_depth_bounds { @dx12.dx_d3d12_graphics_command_list5_om_set_depth_bounds(c, (0.0 : Float), (1.0 : Float)) }
  if ctx.can_sample_pos { @dx12.dx_d3d12_graphics_command_list5_set_sample_positions(c, 0, 0, (0 : UInt64)) }
  @dx12.dx_d3d12_graphics_command_list5_resolve_subresource_region(c, ctx.tex_res_dst, 0, 0, 0, ctx.tex_msaa, 0, ctx.rect_buf, 28, 3)
  if ctx.can_view_inst { @dx12.dx_d3d12_graphics_command_list5_set_view_instance_mask(c, 1) }
  ctx.probed.val = ctx.probed.val + 6
  if ctx.can_wbi { @dx12.dx_d3d12_graphics_command_list5_write_buffer_immediate(c, 1, ctx.wbi_param, ctx.wbi_mode) }
  ctx.probed.val = ctx.probed.val + 1
  @dx12.dx_d3d12_graphics_command_list5_begin_render_pass(c, 1, ctx.rp_rt, (0 : UInt64), 0)
  @dx12.dx_d3d12_graphics_command_list5_end_render_pass(c)
  if ctx.can_rt {
    @dx12.dx_d3d12_graphics_command_list5_build_raytracing_acceleration_structure(c, ctx.rt_build, 0, (0 : UInt64))
    @dx12.dx_d3d12_graphics_command_list5_resource_barrier(c, 1, ctx.bar_rt_uav)
    @dx12.dx_d3d12_graphics_command_list5_emit_raytracing_acceleration_structure_postbuild_info(c, ctx.rt_post_desc, 1, ctx.rt_post_va_arr)
    @dx12.dx_d3d12_graphics_command_list5_copy_raytracing_acceleration_structure(c, ctx.rt_tlas_b_va, ctx.rt_tlas_a_va, 0)
    if ctx.rt_so != (0 : UInt64) { @dx12.dx_d3d12_graphics_command_list5_set_pipeline_state1(c, ctx.rt_so) }
  }
  ctx.probed.val = ctx.probed.val + 6
  if ctx.vrs_tier >= 1 { @dx12.dx_d3d12_graphics_command_list5_rs_set_shading_rate(c, 0, (0 : UInt64)) }
  if ctx.vrs_tier >= 2 { @dx12.dx_d3d12_graphics_command_list5_rs_set_shading_rate_image(c, (0 : UInt64)) }
  ctx.probed.val = ctx.probed.val + 2
  @dx12.dx_d3d12_graphics_command_list5_resource_barrier(c, 1, ctx.bar_resolve_to_copy)
  let _ = @dx12.dx_d3d12_graphics_command_list5_close(c)
  let _ = @dx12.dx_d3d12_graphics_command_list5_reset(c, ctx.ca, (0 : UInt64))
  ctx.probed.val = ctx.probed.val + 2
  let _ = @dx12.com_release(c)
}

///|
fn probe_cmdlist_v6(ctx : CmdCtx) -> Unit {
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.com_query_interface(ctx.cl_base, @dx12.bytes_ptr(@dx12.iid_d3d12_graphics_command_list6), ctx.out_ptr) != 0 {
    return
  }
  let c = @dx12.read_u64(ctx.out_ptr, 0)
  if c == (0 : UInt64) { return }
  let _ = @dx12.dx_d3d12_graphics_command_list6_set_private_data(c, ctx.priv_guid, 4, ctx.priv_val)
  @dx12.write_u32(ctx.priv_sz, 0, (4 : UInt32))
  let _ = @dx12.dx_d3d12_graphics_command_list6_get_private_data(c, ctx.priv_guid, ctx.priv_sz, ctx.scratch)
  let _ = @dx12.dx_d3d12_graphics_command_list6_set_private_data_interface(c, @dx12.bytes_ptr(@dx12.iid_d3d12_command_list), (0 : UInt64))
  let _ = @dx12.dx_d3d12_graphics_command_list6_set_name(c, ctx.name_w)
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_graphics_command_list6_get_device(c, @dx12.bytes_ptr(@dx12.iid_d3d12_device), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  let _ = @dx12.dx_d3d12_graphics_command_list6_get_type(c)
  @dx12.dx_d3d12_graphics_command_list6_clear_state(c, ctx.gpso)
  @dx12.dx_d3d12_graphics_command_list6_set_pipeline_state(c, ctx.gpso)
  @dx12.dx_d3d12_graphics_command_list6_set_descriptor_heaps(c, 1, ctx.dh_gpu_arr)
  @dx12.dx_d3d12_graphics_command_list6_set_graphics_root_signature(c, ctx.rs)
  @dx12.dx_d3d12_graphics_command_list6_set_graphics_root_descriptor_table(c, 0, ctx.gpu_srv_slot)
  @dx12.dx_d3d12_graphics_command_list6_set_graphics_root32_bit_constant(c, 1, 1, 0)
  @dx12.dx_d3d12_graphics_command_list6_set_graphics_root32_bit_constants(c, 1, 2, ctx.const32, 0)
  @dx12.dx_d3d12_graphics_command_list6_set_graphics_root_constant_buffer_view(c, 2, ctx.va_cbv)
  @dx12.dx_d3d12_graphics_command_list6_set_graphics_root_shader_resource_view(c, 3, ctx.va_srv)
  @dx12.dx_d3d12_graphics_command_list6_set_graphics_root_unordered_access_view(c, 4, ctx.va_uav)
  @dx12.dx_d3d12_graphics_command_list6_ia_set_primitive_topology(c, 4)
  @dx12.dx_d3d12_graphics_command_list6_rs_set_viewports(c, 1, ctx.vp_buf)
  @dx12.dx_d3d12_graphics_command_list6_rs_set_scissor_rects(c, 1, ctx.rect_buf)
  @dx12.dx_d3d12_graphics_command_list6_om_set_blend_factor(c, ctx.blend_buf)
  @dx12.dx_d3d12_graphics_command_list6_om_set_stencil_ref(c, 0)
  @dx12.dx_d3d12_graphics_command_list6_om_set_render_targets(c, 1, ctx.rtv_slot, 1, ctx.dsv_slot)
  @dx12.dx_d3d12_graphics_command_list6_clear_render_target_view(c, ctx.rtv_slot, ctx.rgba_buf, 0, (0 : UInt64))
  @dx12.dx_d3d12_graphics_command_list6_clear_depth_stencil_view(c, ctx.dsv_slot, 1, (1.0 : Float), 0, 0, (0 : UInt64))
  @dx12.dx_d3d12_graphics_command_list6_ia_set_vertex_buffers(c, 0, 1, ctx.vbv_buf)
  @dx12.dx_d3d12_graphics_command_list6_ia_set_index_buffer(c, ctx.ibv_buf)
  @dx12.dx_d3d12_graphics_command_list6_so_set_targets(c, 0, 0, (0 : UInt64))
  @dx12.dx_d3d12_graphics_command_list6_begin_query(c, ctx.qh_occ, 0, 0)
  @dx12.dx_d3d12_graphics_command_list6_draw_instanced(c, 3, 1, 0, 0)
  @dx12.dx_d3d12_graphics_command_list6_draw_indexed_instanced(c, 3, 1, 0, 0, 0)
  @dx12.dx_d3d12_graphics_command_list6_end_query(c, ctx.qh_occ, 0, 0)
  @dx12.dx_d3d12_graphics_command_list6_resolve_query_data(c, ctx.qh_occ, 0, 0, 1, ctx.buf_rb, (0 : Int64))
  @dx12.dx_d3d12_graphics_command_list6_execute_indirect(c, ctx.csig_draw, 1, ctx.buf_src, (0 : Int64), (0 : UInt64), (0 : Int64))
  @dx12.dx_d3d12_graphics_command_list6_execute_bundle(c, ctx.bundle_cl)
  @dx12.dx_d3d12_graphics_command_list6_set_pipeline_state(c, ctx.cpso)
  @dx12.dx_d3d12_graphics_command_list6_set_compute_root_signature(c, ctx.rs)
  @dx12.dx_d3d12_graphics_command_list6_set_compute_root_descriptor_table(c, 0, ctx.gpu_srv_slot)
  @dx12.dx_d3d12_graphics_command_list6_set_compute_root32_bit_constant(c, 1, 1, 0)
  @dx12.dx_d3d12_graphics_command_list6_set_compute_root32_bit_constants(c, 1, 2, ctx.const32, 0)
  @dx12.dx_d3d12_graphics_command_list6_set_compute_root_constant_buffer_view(c, 2, ctx.va_cbv)
  @dx12.dx_d3d12_graphics_command_list6_set_compute_root_shader_resource_view(c, 3, ctx.va_srv)
  @dx12.dx_d3d12_graphics_command_list6_set_compute_root_unordered_access_view(c, 4, ctx.va_uav)
  @dx12.dx_d3d12_graphics_command_list6_clear_unordered_access_view_uint(c, ctx.gpu_uav_uint_slot, ctx.cpu_uav_uint_slot, ctx.tex_uav_u32, ctx.u32_clr, 0, (0 : UInt64))
  @dx12.dx_d3d12_graphics_command_list6_clear_unordered_access_view_float(c, ctx.gpu_uav_flt_slot, ctx.cpu_uav_flt_slot, ctx.tex_uav_flt, ctx.flt_clr, 0, (0 : UInt64))
  @dx12.dx_d3d12_graphics_command_list6_dispatch(c, 1, 1, 1)
  @dx12.dx_d3d12_graphics_command_list6_copy_buffer_region(c, ctx.buf_dst, (0 : Int64), ctx.buf_src, (0 : Int64), (256 : Int64))
  @dx12.dx_d3d12_graphics_command_list6_copy_texture_region(c, ctx.tcl_dst, 0, 0, 0, ctx.tcl_src, (0 : UInt64))
  @dx12.dx_d3d12_graphics_command_list6_resource_barrier(c, 1, ctx.bar_rt_to_copy)
  @dx12.dx_d3d12_graphics_command_list6_copy_resource(c, ctx.tex_res_dst, ctx.tex_rt)
  @dx12.dx_d3d12_graphics_command_list6_resource_barrier(c, 2, ctx.bar_to_resolve)
  @dx12.dx_d3d12_graphics_command_list6_resolve_subresource(c, ctx.tex_res_dst, 0, ctx.tex_msaa, 0, 28)
  @dx12.dx_d3d12_graphics_command_list6_set_marker(c, 0, (0 : UInt64), 0)
  ctx.probed.val = ctx.probed.val + 53
  @dx12.dx_d3d12_graphics_command_list6_atomic_copy_buffer_uint(c, ctx.buf_dst, (0 : Int64), ctx.buf_src, (0 : Int64), 0, (0 : UInt64), (0 : UInt64))
  if ctx.can_uma { @dx12.dx_d3d12_graphics_command_list6_atomic_copy_buffer_uint64(c, ctx.buf_dst, (0 : Int64), ctx.buf_src, (0 : Int64), 0, (0 : UInt64), (0 : UInt64)) }
  if ctx.can_depth_bounds { @dx12.dx_d3d12_graphics_command_list6_om_set_depth_bounds(c, (0.0 : Float), (1.0 : Float)) }
  if ctx.can_sample_pos { @dx12.dx_d3d12_graphics_command_list6_set_sample_positions(c, 0, 0, (0 : UInt64)) }
  @dx12.dx_d3d12_graphics_command_list6_resolve_subresource_region(c, ctx.tex_res_dst, 0, 0, 0, ctx.tex_msaa, 0, ctx.rect_buf, 28, 3)
  if ctx.can_view_inst { @dx12.dx_d3d12_graphics_command_list6_set_view_instance_mask(c, 1) }
  ctx.probed.val = ctx.probed.val + 6
  if ctx.can_wbi { @dx12.dx_d3d12_graphics_command_list6_write_buffer_immediate(c, 1, ctx.wbi_param, ctx.wbi_mode) }
  ctx.probed.val = ctx.probed.val + 1
  @dx12.dx_d3d12_graphics_command_list6_begin_render_pass(c, 1, ctx.rp_rt, (0 : UInt64), 0)
  @dx12.dx_d3d12_graphics_command_list6_end_render_pass(c)
  if ctx.can_rt {
    @dx12.dx_d3d12_graphics_command_list6_build_raytracing_acceleration_structure(c, ctx.rt_build, 0, (0 : UInt64))
    @dx12.dx_d3d12_graphics_command_list6_resource_barrier(c, 1, ctx.bar_rt_uav)
    @dx12.dx_d3d12_graphics_command_list6_emit_raytracing_acceleration_structure_postbuild_info(c, ctx.rt_post_desc, 1, ctx.rt_post_va_arr)
    @dx12.dx_d3d12_graphics_command_list6_copy_raytracing_acceleration_structure(c, ctx.rt_tlas_b_va, ctx.rt_tlas_a_va, 0)
    if ctx.rt_so != (0 : UInt64) { @dx12.dx_d3d12_graphics_command_list6_set_pipeline_state1(c, ctx.rt_so) }
  }
  ctx.probed.val = ctx.probed.val + 6
  if ctx.vrs_tier >= 1 { @dx12.dx_d3d12_graphics_command_list6_rs_set_shading_rate(c, 0, (0 : UInt64)) }
  if ctx.vrs_tier >= 2 { @dx12.dx_d3d12_graphics_command_list6_rs_set_shading_rate_image(c, (0 : UInt64)) }
  ctx.probed.val = ctx.probed.val + 2
  @dx12.dx_d3d12_graphics_command_list6_resource_barrier(c, 1, ctx.bar_resolve_to_copy)
  let _ = @dx12.dx_d3d12_graphics_command_list6_close(c)
  let _ = @dx12.dx_d3d12_graphics_command_list6_reset(c, ctx.ca, (0 : UInt64))
  ctx.probed.val = ctx.probed.val + 2
  let _ = @dx12.com_release(c)
}

///|
fn probe_cmdlist_v7(ctx : CmdCtx) -> Unit {
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.com_query_interface(ctx.cl_base, @dx12.bytes_ptr(@dx12.iid_d3d12_graphics_command_list7), ctx.out_ptr) != 0 {
    return
  }
  let c = @dx12.read_u64(ctx.out_ptr, 0)
  if c == (0 : UInt64) { return }
  let _ = @dx12.dx_d3d12_graphics_command_list7_set_private_data(c, ctx.priv_guid, 4, ctx.priv_val)
  @dx12.write_u32(ctx.priv_sz, 0, (4 : UInt32))
  let _ = @dx12.dx_d3d12_graphics_command_list7_get_private_data(c, ctx.priv_guid, ctx.priv_sz, ctx.scratch)
  let _ = @dx12.dx_d3d12_graphics_command_list7_set_private_data_interface(c, @dx12.bytes_ptr(@dx12.iid_d3d12_command_list), (0 : UInt64))
  let _ = @dx12.dx_d3d12_graphics_command_list7_set_name(c, ctx.name_w)
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_graphics_command_list7_get_device(c, @dx12.bytes_ptr(@dx12.iid_d3d12_device), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  let _ = @dx12.dx_d3d12_graphics_command_list7_get_type(c)
  @dx12.dx_d3d12_graphics_command_list7_clear_state(c, ctx.gpso)
  @dx12.dx_d3d12_graphics_command_list7_set_pipeline_state(c, ctx.gpso)
  @dx12.dx_d3d12_graphics_command_list7_set_descriptor_heaps(c, 1, ctx.dh_gpu_arr)
  @dx12.dx_d3d12_graphics_command_list7_set_graphics_root_signature(c, ctx.rs)
  @dx12.dx_d3d12_graphics_command_list7_set_graphics_root_descriptor_table(c, 0, ctx.gpu_srv_slot)
  @dx12.dx_d3d12_graphics_command_list7_set_graphics_root32_bit_constant(c, 1, 1, 0)
  @dx12.dx_d3d12_graphics_command_list7_set_graphics_root32_bit_constants(c, 1, 2, ctx.const32, 0)
  @dx12.dx_d3d12_graphics_command_list7_set_graphics_root_constant_buffer_view(c, 2, ctx.va_cbv)
  @dx12.dx_d3d12_graphics_command_list7_set_graphics_root_shader_resource_view(c, 3, ctx.va_srv)
  @dx12.dx_d3d12_graphics_command_list7_set_graphics_root_unordered_access_view(c, 4, ctx.va_uav)
  @dx12.dx_d3d12_graphics_command_list7_ia_set_primitive_topology(c, 4)
  @dx12.dx_d3d12_graphics_command_list7_rs_set_viewports(c, 1, ctx.vp_buf)
  @dx12.dx_d3d12_graphics_command_list7_rs_set_scissor_rects(c, 1, ctx.rect_buf)
  @dx12.dx_d3d12_graphics_command_list7_om_set_blend_factor(c, ctx.blend_buf)
  @dx12.dx_d3d12_graphics_command_list7_om_set_stencil_ref(c, 0)
  @dx12.dx_d3d12_graphics_command_list7_om_set_render_targets(c, 1, ctx.rtv_slot, 1, ctx.dsv_slot)
  @dx12.dx_d3d12_graphics_command_list7_clear_render_target_view(c, ctx.rtv_slot, ctx.rgba_buf, 0, (0 : UInt64))
  @dx12.dx_d3d12_graphics_command_list7_clear_depth_stencil_view(c, ctx.dsv_slot, 1, (1.0 : Float), 0, 0, (0 : UInt64))
  @dx12.dx_d3d12_graphics_command_list7_ia_set_vertex_buffers(c, 0, 1, ctx.vbv_buf)
  @dx12.dx_d3d12_graphics_command_list7_ia_set_index_buffer(c, ctx.ibv_buf)
  @dx12.dx_d3d12_graphics_command_list7_so_set_targets(c, 0, 0, (0 : UInt64))
  @dx12.dx_d3d12_graphics_command_list7_begin_query(c, ctx.qh_occ, 0, 0)
  @dx12.dx_d3d12_graphics_command_list7_draw_instanced(c, 3, 1, 0, 0)
  @dx12.dx_d3d12_graphics_command_list7_draw_indexed_instanced(c, 3, 1, 0, 0, 0)
  @dx12.dx_d3d12_graphics_command_list7_end_query(c, ctx.qh_occ, 0, 0)
  @dx12.dx_d3d12_graphics_command_list7_resolve_query_data(c, ctx.qh_occ, 0, 0, 1, ctx.buf_rb, (0 : Int64))
  @dx12.dx_d3d12_graphics_command_list7_execute_indirect(c, ctx.csig_draw, 1, ctx.buf_src, (0 : Int64), (0 : UInt64), (0 : Int64))
  @dx12.dx_d3d12_graphics_command_list7_execute_bundle(c, ctx.bundle_cl)
  @dx12.dx_d3d12_graphics_command_list7_set_pipeline_state(c, ctx.cpso)
  @dx12.dx_d3d12_graphics_command_list7_set_compute_root_signature(c, ctx.rs)
  @dx12.dx_d3d12_graphics_command_list7_set_compute_root_descriptor_table(c, 0, ctx.gpu_srv_slot)
  @dx12.dx_d3d12_graphics_command_list7_set_compute_root32_bit_constant(c, 1, 1, 0)
  @dx12.dx_d3d12_graphics_command_list7_set_compute_root32_bit_constants(c, 1, 2, ctx.const32, 0)
  @dx12.dx_d3d12_graphics_command_list7_set_compute_root_constant_buffer_view(c, 2, ctx.va_cbv)
  @dx12.dx_d3d12_graphics_command_list7_set_compute_root_shader_resource_view(c, 3, ctx.va_srv)
  @dx12.dx_d3d12_graphics_command_list7_set_compute_root_unordered_access_view(c, 4, ctx.va_uav)
  @dx12.dx_d3d12_graphics_command_list7_clear_unordered_access_view_uint(c, ctx.gpu_uav_uint_slot, ctx.cpu_uav_uint_slot, ctx.tex_uav_u32, ctx.u32_clr, 0, (0 : UInt64))
  @dx12.dx_d3d12_graphics_command_list7_clear_unordered_access_view_float(c, ctx.gpu_uav_flt_slot, ctx.cpu_uav_flt_slot, ctx.tex_uav_flt, ctx.flt_clr, 0, (0 : UInt64))
  @dx12.dx_d3d12_graphics_command_list7_dispatch(c, 1, 1, 1)
  @dx12.dx_d3d12_graphics_command_list7_copy_buffer_region(c, ctx.buf_dst, (0 : Int64), ctx.buf_src, (0 : Int64), (256 : Int64))
  @dx12.dx_d3d12_graphics_command_list7_copy_texture_region(c, ctx.tcl_dst, 0, 0, 0, ctx.tcl_src, (0 : UInt64))
  @dx12.dx_d3d12_graphics_command_list7_resource_barrier(c, 1, ctx.bar_rt_to_copy)
  @dx12.dx_d3d12_graphics_command_list7_copy_resource(c, ctx.tex_res_dst, ctx.tex_rt)
  @dx12.dx_d3d12_graphics_command_list7_resource_barrier(c, 2, ctx.bar_to_resolve)
  @dx12.dx_d3d12_graphics_command_list7_resolve_subresource(c, ctx.tex_res_dst, 0, ctx.tex_msaa, 0, 28)
  @dx12.dx_d3d12_graphics_command_list7_set_marker(c, 0, (0 : UInt64), 0)
  ctx.probed.val = ctx.probed.val + 53
  @dx12.dx_d3d12_graphics_command_list7_atomic_copy_buffer_uint(c, ctx.buf_dst, (0 : Int64), ctx.buf_src, (0 : Int64), 0, (0 : UInt64), (0 : UInt64))
  if ctx.can_uma { @dx12.dx_d3d12_graphics_command_list7_atomic_copy_buffer_uint64(c, ctx.buf_dst, (0 : Int64), ctx.buf_src, (0 : Int64), 0, (0 : UInt64), (0 : UInt64)) }
  if ctx.can_depth_bounds { @dx12.dx_d3d12_graphics_command_list7_om_set_depth_bounds(c, (0.0 : Float), (1.0 : Float)) }
  if ctx.can_sample_pos { @dx12.dx_d3d12_graphics_command_list7_set_sample_positions(c, 0, 0, (0 : UInt64)) }
  @dx12.dx_d3d12_graphics_command_list7_resolve_subresource_region(c, ctx.tex_res_dst, 0, 0, 0, ctx.tex_msaa, 0, ctx.rect_buf, 28, 3)
  if ctx.can_view_inst { @dx12.dx_d3d12_graphics_command_list7_set_view_instance_mask(c, 1) }
  ctx.probed.val = ctx.probed.val + 6
  if ctx.can_wbi { @dx12.dx_d3d12_graphics_command_list7_write_buffer_immediate(c, 1, ctx.wbi_param, ctx.wbi_mode) }
  ctx.probed.val = ctx.probed.val + 1
  @dx12.dx_d3d12_graphics_command_list7_begin_render_pass(c, 1, ctx.rp_rt, (0 : UInt64), 0)
  @dx12.dx_d3d12_graphics_command_list7_end_render_pass(c)
  if ctx.can_rt {
    @dx12.dx_d3d12_graphics_command_list7_build_raytracing_acceleration_structure(c, ctx.rt_build, 0, (0 : UInt64))
    @dx12.dx_d3d12_graphics_command_list7_resource_barrier(c, 1, ctx.bar_rt_uav)
    @dx12.dx_d3d12_graphics_command_list7_emit_raytracing_acceleration_structure_postbuild_info(c, ctx.rt_post_desc, 1, ctx.rt_post_va_arr)
    @dx12.dx_d3d12_graphics_command_list7_copy_raytracing_acceleration_structure(c, ctx.rt_tlas_b_va, ctx.rt_tlas_a_va, 0)
    if ctx.rt_so != (0 : UInt64) { @dx12.dx_d3d12_graphics_command_list7_set_pipeline_state1(c, ctx.rt_so) }
  }
  ctx.probed.val = ctx.probed.val + 6
  if ctx.vrs_tier >= 1 { @dx12.dx_d3d12_graphics_command_list7_rs_set_shading_rate(c, 0, (0 : UInt64)) }
  if ctx.vrs_tier >= 2 { @dx12.dx_d3d12_graphics_command_list7_rs_set_shading_rate_image(c, (0 : UInt64)) }
  ctx.probed.val = ctx.probed.val + 2
  if ctx.can_eb { @dx12.dx_d3d12_graphics_command_list7_barrier(c, 1, ctx.eb_grp) }
  ctx.probed.val = ctx.probed.val + 1
  @dx12.dx_d3d12_graphics_command_list7_resource_barrier(c, 1, ctx.bar_resolve_to_copy)
  let _ = @dx12.dx_d3d12_graphics_command_list7_close(c)
  let _ = @dx12.dx_d3d12_graphics_command_list7_reset(c, ctx.ca, (0 : UInt64))
  ctx.probed.val = ctx.probed.val + 2
  let _ = @dx12.com_release(c)
}

///|
fn probe_cmdlist_v8(ctx : CmdCtx) -> Unit {
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.com_query_interface(ctx.cl_base, @dx12.bytes_ptr(@dx12.iid_d3d12_graphics_command_list8), ctx.out_ptr) != 0 {
    return
  }
  let c = @dx12.read_u64(ctx.out_ptr, 0)
  if c == (0 : UInt64) { return }
  let _ = @dx12.dx_d3d12_graphics_command_list8_set_private_data(c, ctx.priv_guid, 4, ctx.priv_val)
  @dx12.write_u32(ctx.priv_sz, 0, (4 : UInt32))
  let _ = @dx12.dx_d3d12_graphics_command_list8_get_private_data(c, ctx.priv_guid, ctx.priv_sz, ctx.scratch)
  let _ = @dx12.dx_d3d12_graphics_command_list8_set_private_data_interface(c, @dx12.bytes_ptr(@dx12.iid_d3d12_command_list), (0 : UInt64))
  let _ = @dx12.dx_d3d12_graphics_command_list8_set_name(c, ctx.name_w)
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_graphics_command_list8_get_device(c, @dx12.bytes_ptr(@dx12.iid_d3d12_device), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  let _ = @dx12.dx_d3d12_graphics_command_list8_get_type(c)
  @dx12.dx_d3d12_graphics_command_list8_clear_state(c, ctx.gpso)
  @dx12.dx_d3d12_graphics_command_list8_set_pipeline_state(c, ctx.gpso)
  @dx12.dx_d3d12_graphics_command_list8_set_descriptor_heaps(c, 1, ctx.dh_gpu_arr)
  @dx12.dx_d3d12_graphics_command_list8_set_graphics_root_signature(c, ctx.rs)
  @dx12.dx_d3d12_graphics_command_list8_set_graphics_root_descriptor_table(c, 0, ctx.gpu_srv_slot)
  @dx12.dx_d3d12_graphics_command_list8_set_graphics_root32_bit_constant(c, 1, 1, 0)
  @dx12.dx_d3d12_graphics_command_list8_set_graphics_root32_bit_constants(c, 1, 2, ctx.const32, 0)
  @dx12.dx_d3d12_graphics_command_list8_set_graphics_root_constant_buffer_view(c, 2, ctx.va_cbv)
  @dx12.dx_d3d12_graphics_command_list8_set_graphics_root_shader_resource_view(c, 3, ctx.va_srv)
  @dx12.dx_d3d12_graphics_command_list8_set_graphics_root_unordered_access_view(c, 4, ctx.va_uav)
  @dx12.dx_d3d12_graphics_command_list8_ia_set_primitive_topology(c, 4)
  @dx12.dx_d3d12_graphics_command_list8_rs_set_viewports(c, 1, ctx.vp_buf)
  @dx12.dx_d3d12_graphics_command_list8_rs_set_scissor_rects(c, 1, ctx.rect_buf)
  @dx12.dx_d3d12_graphics_command_list8_om_set_blend_factor(c, ctx.blend_buf)
  @dx12.dx_d3d12_graphics_command_list8_om_set_stencil_ref(c, 0)
  @dx12.dx_d3d12_graphics_command_list8_om_set_render_targets(c, 1, ctx.rtv_slot, 1, ctx.dsv_slot)
  @dx12.dx_d3d12_graphics_command_list8_clear_render_target_view(c, ctx.rtv_slot, ctx.rgba_buf, 0, (0 : UInt64))
  @dx12.dx_d3d12_graphics_command_list8_clear_depth_stencil_view(c, ctx.dsv_slot, 1, (1.0 : Float), 0, 0, (0 : UInt64))
  @dx12.dx_d3d12_graphics_command_list8_ia_set_vertex_buffers(c, 0, 1, ctx.vbv_buf)
  @dx12.dx_d3d12_graphics_command_list8_ia_set_index_buffer(c, ctx.ibv_buf)
  @dx12.dx_d3d12_graphics_command_list8_so_set_targets(c, 0, 0, (0 : UInt64))
  @dx12.dx_d3d12_graphics_command_list8_begin_query(c, ctx.qh_occ, 0, 0)
  @dx12.dx_d3d12_graphics_command_list8_draw_instanced(c, 3, 1, 0, 0)
  @dx12.dx_d3d12_graphics_command_list8_draw_indexed_instanced(c, 3, 1, 0, 0, 0)
  @dx12.dx_d3d12_graphics_command_list8_end_query(c, ctx.qh_occ, 0, 0)
  @dx12.dx_d3d12_graphics_command_list8_resolve_query_data(c, ctx.qh_occ, 0, 0, 1, ctx.buf_rb, (0 : Int64))
  @dx12.dx_d3d12_graphics_command_list8_execute_indirect(c, ctx.csig_draw, 1, ctx.buf_src, (0 : Int64), (0 : UInt64), (0 : Int64))
  @dx12.dx_d3d12_graphics_command_list8_execute_bundle(c, ctx.bundle_cl)
  @dx12.dx_d3d12_graphics_command_list8_set_pipeline_state(c, ctx.cpso)
  @dx12.dx_d3d12_graphics_command_list8_set_compute_root_signature(c, ctx.rs)
  @dx12.dx_d3d12_graphics_command_list8_set_compute_root_descriptor_table(c, 0, ctx.gpu_srv_slot)
  @dx12.dx_d3d12_graphics_command_list8_set_compute_root32_bit_constant(c, 1, 1, 0)
  @dx12.dx_d3d12_graphics_command_list8_set_compute_root32_bit_constants(c, 1, 2, ctx.const32, 0)
  @dx12.dx_d3d12_graphics_command_list8_set_compute_root_constant_buffer_view(c, 2, ctx.va_cbv)
  @dx12.dx_d3d12_graphics_command_list8_set_compute_root_shader_resource_view(c, 3, ctx.va_srv)
  @dx12.dx_d3d12_graphics_command_list8_set_compute_root_unordered_access_view(c, 4, ctx.va_uav)
  @dx12.dx_d3d12_graphics_command_list8_clear_unordered_access_view_uint(c, ctx.gpu_uav_uint_slot, ctx.cpu_uav_uint_slot, ctx.tex_uav_u32, ctx.u32_clr, 0, (0 : UInt64))
  @dx12.dx_d3d12_graphics_command_list8_clear_unordered_access_view_float(c, ctx.gpu_uav_flt_slot, ctx.cpu_uav_flt_slot, ctx.tex_uav_flt, ctx.flt_clr, 0, (0 : UInt64))
  @dx12.dx_d3d12_graphics_command_list8_dispatch(c, 1, 1, 1)
  @dx12.dx_d3d12_graphics_command_list8_copy_buffer_region(c, ctx.buf_dst, (0 : Int64), ctx.buf_src, (0 : Int64), (256 : Int64))
  @dx12.dx_d3d12_graphics_command_list8_copy_texture_region(c, ctx.tcl_dst, 0, 0, 0, ctx.tcl_src, (0 : UInt64))
  @dx12.dx_d3d12_graphics_command_list8_resource_barrier(c, 1, ctx.bar_rt_to_copy)
  @dx12.dx_d3d12_graphics_command_list8_copy_resource(c, ctx.tex_res_dst, ctx.tex_rt)
  @dx12.dx_d3d12_graphics_command_list8_resource_barrier(c, 2, ctx.bar_to_resolve)
  @dx12.dx_d3d12_graphics_command_list8_resolve_subresource(c, ctx.tex_res_dst, 0, ctx.tex_msaa, 0, 28)
  @dx12.dx_d3d12_graphics_command_list8_set_marker(c, 0, (0 : UInt64), 0)
  ctx.probed.val = ctx.probed.val + 53
  @dx12.dx_d3d12_graphics_command_list8_atomic_copy_buffer_uint(c, ctx.buf_dst, (0 : Int64), ctx.buf_src, (0 : Int64), 0, (0 : UInt64), (0 : UInt64))
  if ctx.can_uma { @dx12.dx_d3d12_graphics_command_list8_atomic_copy_buffer_uint64(c, ctx.buf_dst, (0 : Int64), ctx.buf_src, (0 : Int64), 0, (0 : UInt64), (0 : UInt64)) }
  if ctx.can_depth_bounds { @dx12.dx_d3d12_graphics_command_list8_om_set_depth_bounds(c, (0.0 : Float), (1.0 : Float)) }
  if ctx.can_sample_pos { @dx12.dx_d3d12_graphics_command_list8_set_sample_positions(c, 0, 0, (0 : UInt64)) }
  @dx12.dx_d3d12_graphics_command_list8_resolve_subresource_region(c, ctx.tex_res_dst, 0, 0, 0, ctx.tex_msaa, 0, ctx.rect_buf, 28, 3)
  if ctx.can_view_inst { @dx12.dx_d3d12_graphics_command_list8_set_view_instance_mask(c, 1) }
  ctx.probed.val = ctx.probed.val + 6
  if ctx.can_wbi { @dx12.dx_d3d12_graphics_command_list8_write_buffer_immediate(c, 1, ctx.wbi_param, ctx.wbi_mode) }
  ctx.probed.val = ctx.probed.val + 1
  @dx12.dx_d3d12_graphics_command_list8_begin_render_pass(c, 1, ctx.rp_rt, (0 : UInt64), 0)
  @dx12.dx_d3d12_graphics_command_list8_end_render_pass(c)
  if ctx.can_rt {
    @dx12.dx_d3d12_graphics_command_list8_build_raytracing_acceleration_structure(c, ctx.rt_build, 0, (0 : UInt64))
    @dx12.dx_d3d12_graphics_command_list8_resource_barrier(c, 1, ctx.bar_rt_uav)
    @dx12.dx_d3d12_graphics_command_list8_emit_raytracing_acceleration_structure_postbuild_info(c, ctx.rt_post_desc, 1, ctx.rt_post_va_arr)
    @dx12.dx_d3d12_graphics_command_list8_copy_raytracing_acceleration_structure(c, ctx.rt_tlas_b_va, ctx.rt_tlas_a_va, 0)
    if ctx.rt_so != (0 : UInt64) { @dx12.dx_d3d12_graphics_command_list8_set_pipeline_state1(c, ctx.rt_so) }
  }
  ctx.probed.val = ctx.probed.val + 6
  if ctx.vrs_tier >= 1 { @dx12.dx_d3d12_graphics_command_list8_rs_set_shading_rate(c, 0, (0 : UInt64)) }
  if ctx.vrs_tier >= 2 { @dx12.dx_d3d12_graphics_command_list8_rs_set_shading_rate_image(c, (0 : UInt64)) }
  ctx.probed.val = ctx.probed.val + 2
  if ctx.can_eb { @dx12.dx_d3d12_graphics_command_list8_barrier(c, 1, ctx.eb_grp) }
  ctx.probed.val = ctx.probed.val + 1
  if ctx.can_stencil_ref { @dx12.dx_d3d12_graphics_command_list8_om_set_front_and_back_stencil_ref(c, 0, 0) }
  ctx.probed.val = ctx.probed.val + 1
  @dx12.dx_d3d12_graphics_command_list8_resource_barrier(c, 1, ctx.bar_resolve_to_copy)
  let _ = @dx12.dx_d3d12_graphics_command_list8_close(c)
  let _ = @dx12.dx_d3d12_graphics_command_list8_reset(c, ctx.ca, (0 : UInt64))
  ctx.probed.val = ctx.probed.val + 2
  let _ = @dx12.com_release(c)
}

///|
fn probe_cmdlist_v9(ctx : CmdCtx) -> Unit {
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.com_query_interface(ctx.cl_base, @dx12.bytes_ptr(@dx12.iid_d3d12_graphics_command_list9), ctx.out_ptr) != 0 {
    return
  }
  let c = @dx12.read_u64(ctx.out_ptr, 0)
  if c == (0 : UInt64) { return }
  let _ = @dx12.dx_d3d12_graphics_command_list9_set_private_data(c, ctx.priv_guid, 4, ctx.priv_val)
  @dx12.write_u32(ctx.priv_sz, 0, (4 : UInt32))
  let _ = @dx12.dx_d3d12_graphics_command_list9_get_private_data(c, ctx.priv_guid, ctx.priv_sz, ctx.scratch)
  let _ = @dx12.dx_d3d12_graphics_command_list9_set_private_data_interface(c, @dx12.bytes_ptr(@dx12.iid_d3d12_command_list), (0 : UInt64))
  let _ = @dx12.dx_d3d12_graphics_command_list9_set_name(c, ctx.name_w)
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_graphics_command_list9_get_device(c, @dx12.bytes_ptr(@dx12.iid_d3d12_device), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  let _ = @dx12.dx_d3d12_graphics_command_list9_get_type(c)
  @dx12.dx_d3d12_graphics_command_list9_clear_state(c, ctx.gpso)
  @dx12.dx_d3d12_graphics_command_list9_set_pipeline_state(c, ctx.gpso)
  @dx12.dx_d3d12_graphics_command_list9_set_descriptor_heaps(c, 1, ctx.dh_gpu_arr)
  @dx12.dx_d3d12_graphics_command_list9_set_graphics_root_signature(c, ctx.rs)
  @dx12.dx_d3d12_graphics_command_list9_set_graphics_root_descriptor_table(c, 0, ctx.gpu_srv_slot)
  @dx12.dx_d3d12_graphics_command_list9_set_graphics_root32_bit_constant(c, 1, 1, 0)
  @dx12.dx_d3d12_graphics_command_list9_set_graphics_root32_bit_constants(c, 1, 2, ctx.const32, 0)
  @dx12.dx_d3d12_graphics_command_list9_set_graphics_root_constant_buffer_view(c, 2, ctx.va_cbv)
  @dx12.dx_d3d12_graphics_command_list9_set_graphics_root_shader_resource_view(c, 3, ctx.va_srv)
  @dx12.dx_d3d12_graphics_command_list9_set_graphics_root_unordered_access_view(c, 4, ctx.va_uav)
  @dx12.dx_d3d12_graphics_command_list9_ia_set_primitive_topology(c, 4)
  @dx12.dx_d3d12_graphics_command_list9_rs_set_viewports(c, 1, ctx.vp_buf)
  @dx12.dx_d3d12_graphics_command_list9_rs_set_scissor_rects(c, 1, ctx.rect_buf)
  @dx12.dx_d3d12_graphics_command_list9_om_set_blend_factor(c, ctx.blend_buf)
  @dx12.dx_d3d12_graphics_command_list9_om_set_stencil_ref(c, 0)
  @dx12.dx_d3d12_graphics_command_list9_om_set_render_targets(c, 1, ctx.rtv_slot, 1, ctx.dsv_slot)
  @dx12.dx_d3d12_graphics_command_list9_clear_render_target_view(c, ctx.rtv_slot, ctx.rgba_buf, 0, (0 : UInt64))
  @dx12.dx_d3d12_graphics_command_list9_clear_depth_stencil_view(c, ctx.dsv_slot, 1, (1.0 : Float), 0, 0, (0 : UInt64))
  @dx12.dx_d3d12_graphics_command_list9_ia_set_vertex_buffers(c, 0, 1, ctx.vbv_buf)
  @dx12.dx_d3d12_graphics_command_list9_ia_set_index_buffer(c, ctx.ibv_buf)
  @dx12.dx_d3d12_graphics_command_list9_so_set_targets(c, 0, 0, (0 : UInt64))
  @dx12.dx_d3d12_graphics_command_list9_begin_query(c, ctx.qh_occ, 0, 0)
  @dx12.dx_d3d12_graphics_command_list9_draw_instanced(c, 3, 1, 0, 0)
  @dx12.dx_d3d12_graphics_command_list9_draw_indexed_instanced(c, 3, 1, 0, 0, 0)
  @dx12.dx_d3d12_graphics_command_list9_end_query(c, ctx.qh_occ, 0, 0)
  @dx12.dx_d3d12_graphics_command_list9_resolve_query_data(c, ctx.qh_occ, 0, 0, 1, ctx.buf_rb, (0 : Int64))
  @dx12.dx_d3d12_graphics_command_list9_execute_indirect(c, ctx.csig_draw, 1, ctx.buf_src, (0 : Int64), (0 : UInt64), (0 : Int64))
  @dx12.dx_d3d12_graphics_command_list9_execute_bundle(c, ctx.bundle_cl)
  @dx12.dx_d3d12_graphics_command_list9_set_pipeline_state(c, ctx.cpso)
  @dx12.dx_d3d12_graphics_command_list9_set_compute_root_signature(c, ctx.rs)
  @dx12.dx_d3d12_graphics_command_list9_set_compute_root_descriptor_table(c, 0, ctx.gpu_srv_slot)
  @dx12.dx_d3d12_graphics_command_list9_set_compute_root32_bit_constant(c, 1, 1, 0)
  @dx12.dx_d3d12_graphics_command_list9_set_compute_root32_bit_constants(c, 1, 2, ctx.const32, 0)
  @dx12.dx_d3d12_graphics_command_list9_set_compute_root_constant_buffer_view(c, 2, ctx.va_cbv)
  @dx12.dx_d3d12_graphics_command_list9_set_compute_root_shader_resource_view(c, 3, ctx.va_srv)
  @dx12.dx_d3d12_graphics_command_list9_set_compute_root_unordered_access_view(c, 4, ctx.va_uav)
  @dx12.dx_d3d12_graphics_command_list9_clear_unordered_access_view_uint(c, ctx.gpu_uav_uint_slot, ctx.cpu_uav_uint_slot, ctx.tex_uav_u32, ctx.u32_clr, 0, (0 : UInt64))
  @dx12.dx_d3d12_graphics_command_list9_clear_unordered_access_view_float(c, ctx.gpu_uav_flt_slot, ctx.cpu_uav_flt_slot, ctx.tex_uav_flt, ctx.flt_clr, 0, (0 : UInt64))
  @dx12.dx_d3d12_graphics_command_list9_dispatch(c, 1, 1, 1)
  @dx12.dx_d3d12_graphics_command_list9_copy_buffer_region(c, ctx.buf_dst, (0 : Int64), ctx.buf_src, (0 : Int64), (256 : Int64))
  @dx12.dx_d3d12_graphics_command_list9_copy_texture_region(c, ctx.tcl_dst, 0, 0, 0, ctx.tcl_src, (0 : UInt64))
  @dx12.dx_d3d12_graphics_command_list9_resource_barrier(c, 1, ctx.bar_rt_to_copy)
  @dx12.dx_d3d12_graphics_command_list9_copy_resource(c, ctx.tex_res_dst, ctx.tex_rt)
  @dx12.dx_d3d12_graphics_command_list9_resource_barrier(c, 2, ctx.bar_to_resolve)
  @dx12.dx_d3d12_graphics_command_list9_resolve_subresource(c, ctx.tex_res_dst, 0, ctx.tex_msaa, 0, 28)
  @dx12.dx_d3d12_graphics_command_list9_set_marker(c, 0, (0 : UInt64), 0)
  ctx.probed.val = ctx.probed.val + 53
  @dx12.dx_d3d12_graphics_command_list9_atomic_copy_buffer_uint(c, ctx.buf_dst, (0 : Int64), ctx.buf_src, (0 : Int64), 0, (0 : UInt64), (0 : UInt64))
  if ctx.can_uma { @dx12.dx_d3d12_graphics_command_list9_atomic_copy_buffer_uint64(c, ctx.buf_dst, (0 : Int64), ctx.buf_src, (0 : Int64), 0, (0 : UInt64), (0 : UInt64)) }
  if ctx.can_depth_bounds { @dx12.dx_d3d12_graphics_command_list9_om_set_depth_bounds(c, (0.0 : Float), (1.0 : Float)) }
  if ctx.can_sample_pos { @dx12.dx_d3d12_graphics_command_list9_set_sample_positions(c, 0, 0, (0 : UInt64)) }
  @dx12.dx_d3d12_graphics_command_list9_resolve_subresource_region(c, ctx.tex_res_dst, 0, 0, 0, ctx.tex_msaa, 0, ctx.rect_buf, 28, 3)
  if ctx.can_view_inst { @dx12.dx_d3d12_graphics_command_list9_set_view_instance_mask(c, 1) }
  ctx.probed.val = ctx.probed.val + 6
  if ctx.can_wbi { @dx12.dx_d3d12_graphics_command_list9_write_buffer_immediate(c, 1, ctx.wbi_param, ctx.wbi_mode) }
  ctx.probed.val = ctx.probed.val + 1
  @dx12.dx_d3d12_graphics_command_list9_begin_render_pass(c, 1, ctx.rp_rt, (0 : UInt64), 0)
  @dx12.dx_d3d12_graphics_command_list9_end_render_pass(c)
  if ctx.can_rt {
    @dx12.dx_d3d12_graphics_command_list9_build_raytracing_acceleration_structure(c, ctx.rt_build, 0, (0 : UInt64))
    @dx12.dx_d3d12_graphics_command_list9_resource_barrier(c, 1, ctx.bar_rt_uav)
    @dx12.dx_d3d12_graphics_command_list9_emit_raytracing_acceleration_structure_postbuild_info(c, ctx.rt_post_desc, 1, ctx.rt_post_va_arr)
    @dx12.dx_d3d12_graphics_command_list9_copy_raytracing_acceleration_structure(c, ctx.rt_tlas_b_va, ctx.rt_tlas_a_va, 0)
    if ctx.rt_so != (0 : UInt64) { @dx12.dx_d3d12_graphics_command_list9_set_pipeline_state1(c, ctx.rt_so) }
  }
  ctx.probed.val = ctx.probed.val + 6
  if ctx.vrs_tier >= 1 { @dx12.dx_d3d12_graphics_command_list9_rs_set_shading_rate(c, 0, (0 : UInt64)) }
  if ctx.vrs_tier >= 2 { @dx12.dx_d3d12_graphics_command_list9_rs_set_shading_rate_image(c, (0 : UInt64)) }
  ctx.probed.val = ctx.probed.val + 2
  if ctx.can_eb { @dx12.dx_d3d12_graphics_command_list9_barrier(c, 1, ctx.eb_grp) }
  ctx.probed.val = ctx.probed.val + 1
  if ctx.can_stencil_ref { @dx12.dx_d3d12_graphics_command_list9_om_set_front_and_back_stencil_ref(c, 0, 0) }
  ctx.probed.val = ctx.probed.val + 1
  if ctx.can_dyn_bias { @dx12.dx_d3d12_graphics_command_list9_rs_set_depth_bias(c, (0.0 : Float), (0.0 : Float), (0.0 : Float)) }
  if ctx.can_dyn_cut { @dx12.dx_d3d12_graphics_command_list9_ia_set_index_buffer_strip_cut_value(c, 0) }
  ctx.probed.val = ctx.probed.val + 2
  @dx12.dx_d3d12_graphics_command_list9_resource_barrier(c, 1, ctx.bar_resolve_to_copy)
  let _ = @dx12.dx_d3d12_graphics_command_list9_close(c)
  let _ = @dx12.dx_d3d12_graphics_command_list9_reset(c, ctx.ca, (0 : UInt64))
  ctx.probed.val = ctx.probed.val + 2
  let _ = @dx12.com_release(c)
}

///|
fn probe_cmdlist_v10(ctx : CmdCtx) -> Unit {
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.com_query_interface(ctx.cl_base, @dx12.bytes_ptr(@dx12.iid_d3d12_graphics_command_list10), ctx.out_ptr) != 0 {
    return
  }
  let c = @dx12.read_u64(ctx.out_ptr, 0)
  if c == (0 : UInt64) { return }
  let _ = @dx12.dx_d3d12_graphics_command_list10_set_private_data(c, ctx.priv_guid, 4, ctx.priv_val)
  @dx12.write_u32(ctx.priv_sz, 0, (4 : UInt32))
  let _ = @dx12.dx_d3d12_graphics_command_list10_get_private_data(c, ctx.priv_guid, ctx.priv_sz, ctx.scratch)
  let _ = @dx12.dx_d3d12_graphics_command_list10_set_private_data_interface(c, @dx12.bytes_ptr(@dx12.iid_d3d12_command_list), (0 : UInt64))
  let _ = @dx12.dx_d3d12_graphics_command_list10_set_name(c, ctx.name_w)
  @dx12.write_u64(ctx.out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_graphics_command_list10_get_device(c, @dx12.bytes_ptr(@dx12.iid_d3d12_device), ctx.out_ptr) == 0 { let _ = @dx12.com_release(@dx12.read_u64(ctx.out_ptr, 0)) }
  let _ = @dx12.dx_d3d12_graphics_command_list10_get_type(c)
  @dx12.dx_d3d12_graphics_command_list10_clear_state(c, ctx.gpso)
  @dx12.dx_d3d12_graphics_command_list10_set_pipeline_state(c, ctx.gpso)
  @dx12.dx_d3d12_graphics_command_list10_set_descriptor_heaps(c, 1, ctx.dh_gpu_arr)
  @dx12.dx_d3d12_graphics_command_list10_set_graphics_root_signature(c, ctx.rs)
  @dx12.dx_d3d12_graphics_command_list10_set_graphics_root_descriptor_table(c, 0, ctx.gpu_srv_slot)
  @dx12.dx_d3d12_graphics_command_list10_set_graphics_root32_bit_constant(c, 1, 1, 0)
  @dx12.dx_d3d12_graphics_command_list10_set_graphics_root32_bit_constants(c, 1, 2, ctx.const32, 0)
  @dx12.dx_d3d12_graphics_command_list10_set_graphics_root_constant_buffer_view(c, 2, ctx.va_cbv)
  @dx12.dx_d3d12_graphics_command_list10_set_graphics_root_shader_resource_view(c, 3, ctx.va_srv)
  @dx12.dx_d3d12_graphics_command_list10_set_graphics_root_unordered_access_view(c, 4, ctx.va_uav)
  @dx12.dx_d3d12_graphics_command_list10_ia_set_primitive_topology(c, 4)
  @dx12.dx_d3d12_graphics_command_list10_rs_set_viewports(c, 1, ctx.vp_buf)
  @dx12.dx_d3d12_graphics_command_list10_rs_set_scissor_rects(c, 1, ctx.rect_buf)
  @dx12.dx_d3d12_graphics_command_list10_om_set_blend_factor(c, ctx.blend_buf)
  @dx12.dx_d3d12_graphics_command_list10_om_set_stencil_ref(c, 0)
  @dx12.dx_d3d12_graphics_command_list10_om_set_render_targets(c, 1, ctx.rtv_slot, 1, ctx.dsv_slot)
  @dx12.dx_d3d12_graphics_command_list10_clear_render_target_view(c, ctx.rtv_slot, ctx.rgba_buf, 0, (0 : UInt64))
  @dx12.dx_d3d12_graphics_command_list10_clear_depth_stencil_view(c, ctx.dsv_slot, 1, (1.0 : Float), 0, 0, (0 : UInt64))
  @dx12.dx_d3d12_graphics_command_list10_ia_set_vertex_buffers(c, 0, 1, ctx.vbv_buf)
  @dx12.dx_d3d12_graphics_command_list10_ia_set_index_buffer(c, ctx.ibv_buf)
  @dx12.dx_d3d12_graphics_command_list10_so_set_targets(c, 0, 0, (0 : UInt64))
  @dx12.dx_d3d12_graphics_command_list10_begin_query(c, ctx.qh_occ, 0, 0)
  @dx12.dx_d3d12_graphics_command_list10_draw_instanced(c, 3, 1, 0, 0)
  @dx12.dx_d3d12_graphics_command_list10_draw_indexed_instanced(c, 3, 1, 0, 0, 0)
  @dx12.dx_d3d12_graphics_command_list10_end_query(c, ctx.qh_occ, 0, 0)
  @dx12.dx_d3d12_graphics_command_list10_resolve_query_data(c, ctx.qh_occ, 0, 0, 1, ctx.buf_rb, (0 : Int64))
  @dx12.dx_d3d12_graphics_command_list10_execute_indirect(c, ctx.csig_draw, 1, ctx.buf_src, (0 : Int64), (0 : UInt64), (0 : Int64))
  @dx12.dx_d3d12_graphics_command_list10_execute_bundle(c, ctx.bundle_cl)
  @dx12.dx_d3d12_graphics_command_list10_set_pipeline_state(c, ctx.cpso)
  @dx12.dx_d3d12_graphics_command_list10_set_compute_root_signature(c, ctx.rs)
  @dx12.dx_d3d12_graphics_command_list10_set_compute_root_descriptor_table(c, 0, ctx.gpu_srv_slot)
  @dx12.dx_d3d12_graphics_command_list10_set_compute_root32_bit_constant(c, 1, 1, 0)
  @dx12.dx_d3d12_graphics_command_list10_set_compute_root32_bit_constants(c, 1, 2, ctx.const32, 0)
  @dx12.dx_d3d12_graphics_command_list10_set_compute_root_constant_buffer_view(c, 2, ctx.va_cbv)
  @dx12.dx_d3d12_graphics_command_list10_set_compute_root_shader_resource_view(c, 3, ctx.va_srv)
  @dx12.dx_d3d12_graphics_command_list10_set_compute_root_unordered_access_view(c, 4, ctx.va_uav)
  @dx12.dx_d3d12_graphics_command_list10_clear_unordered_access_view_uint(c, ctx.gpu_uav_uint_slot, ctx.cpu_uav_uint_slot, ctx.tex_uav_u32, ctx.u32_clr, 0, (0 : UInt64))
  @dx12.dx_d3d12_graphics_command_list10_clear_unordered_access_view_float(c, ctx.gpu_uav_flt_slot, ctx.cpu_uav_flt_slot, ctx.tex_uav_flt, ctx.flt_clr, 0, (0 : UInt64))
  @dx12.dx_d3d12_graphics_command_list10_dispatch(c, 1, 1, 1)
  @dx12.dx_d3d12_graphics_command_list10_copy_buffer_region(c, ctx.buf_dst, (0 : Int64), ctx.buf_src, (0 : Int64), (256 : Int64))
  @dx12.dx_d3d12_graphics_command_list10_copy_texture_region(c, ctx.tcl_dst, 0, 0, 0, ctx.tcl_src, (0 : UInt64))
  @dx12.dx_d3d12_graphics_command_list10_resource_barrier(c, 1, ctx.bar_rt_to_copy)
  @dx12.dx_d3d12_graphics_command_list10_copy_resource(c, ctx.tex_res_dst, ctx.tex_rt)
  @dx12.dx_d3d12_graphics_command_list10_resource_barrier(c, 2, ctx.bar_to_resolve)
  @dx12.dx_d3d12_graphics_command_list10_resolve_subresource(c, ctx.tex_res_dst, 0, ctx.tex_msaa, 0, 28)
  @dx12.dx_d3d12_graphics_command_list10_set_marker(c, 0, (0 : UInt64), 0)
  ctx.probed.val = ctx.probed.val + 53
  @dx12.dx_d3d12_graphics_command_list10_atomic_copy_buffer_uint(c, ctx.buf_dst, (0 : Int64), ctx.buf_src, (0 : Int64), 0, (0 : UInt64), (0 : UInt64))
  if ctx.can_uma { @dx12.dx_d3d12_graphics_command_list10_atomic_copy_buffer_uint64(c, ctx.buf_dst, (0 : Int64), ctx.buf_src, (0 : Int64), 0, (0 : UInt64), (0 : UInt64)) }
  if ctx.can_depth_bounds { @dx12.dx_d3d12_graphics_command_list10_om_set_depth_bounds(c, (0.0 : Float), (1.0 : Float)) }
  if ctx.can_sample_pos { @dx12.dx_d3d12_graphics_command_list10_set_sample_positions(c, 0, 0, (0 : UInt64)) }
  @dx12.dx_d3d12_graphics_command_list10_resolve_subresource_region(c, ctx.tex_res_dst, 0, 0, 0, ctx.tex_msaa, 0, ctx.rect_buf, 28, 3)
  if ctx.can_view_inst { @dx12.dx_d3d12_graphics_command_list10_set_view_instance_mask(c, 1) }
  ctx.probed.val = ctx.probed.val + 6
  if ctx.can_wbi { @dx12.dx_d3d12_graphics_command_list10_write_buffer_immediate(c, 1, ctx.wbi_param, ctx.wbi_mode) }
  ctx.probed.val = ctx.probed.val + 1
  @dx12.dx_d3d12_graphics_command_list10_begin_render_pass(c, 1, ctx.rp_rt, (0 : UInt64), 0)
  @dx12.dx_d3d12_graphics_command_list10_end_render_pass(c)
  if ctx.can_rt {
    @dx12.dx_d3d12_graphics_command_list10_build_raytracing_acceleration_structure(c, ctx.rt_build, 0, (0 : UInt64))
    @dx12.dx_d3d12_graphics_command_list10_resource_barrier(c, 1, ctx.bar_rt_uav)
    @dx12.dx_d3d12_graphics_command_list10_emit_raytracing_acceleration_structure_postbuild_info(c, ctx.rt_post_desc, 1, ctx.rt_post_va_arr)
    @dx12.dx_d3d12_graphics_command_list10_copy_raytracing_acceleration_structure(c, ctx.rt_tlas_b_va, ctx.rt_tlas_a_va, 0)
    if ctx.rt_so != (0 : UInt64) { @dx12.dx_d3d12_graphics_command_list10_set_pipeline_state1(c, ctx.rt_so) }
  }
  ctx.probed.val = ctx.probed.val + 6
  if ctx.vrs_tier >= 1 { @dx12.dx_d3d12_graphics_command_list10_rs_set_shading_rate(c, 0, (0 : UInt64)) }
  if ctx.vrs_tier >= 2 { @dx12.dx_d3d12_graphics_command_list10_rs_set_shading_rate_image(c, (0 : UInt64)) }
  ctx.probed.val = ctx.probed.val + 2
  if ctx.can_eb { @dx12.dx_d3d12_graphics_command_list10_barrier(c, 1, ctx.eb_grp) }
  ctx.probed.val = ctx.probed.val + 1
  if ctx.can_stencil_ref { @dx12.dx_d3d12_graphics_command_list10_om_set_front_and_back_stencil_ref(c, 0, 0) }
  ctx.probed.val = ctx.probed.val + 1
  if ctx.can_dyn_bias { @dx12.dx_d3d12_graphics_command_list10_rs_set_depth_bias(c, (0.0 : Float), (0.0 : Float), (0.0 : Float)) }
  if ctx.can_dyn_cut { @dx12.dx_d3d12_graphics_command_list10_ia_set_index_buffer_strip_cut_value(c, 0) }
  ctx.probed.val = ctx.probed.val + 2
  @dx12.dx_d3d12_graphics_command_list10_resource_barrier(c, 1, ctx.bar_resolve_to_copy)
  let _ = @dx12.dx_d3d12_graphics_command_list10_close(c)
  let _ = @dx12.dx_d3d12_graphics_command_list10_reset(c, ctx.ca, (0 : UInt64))
  ctx.probed.val = ctx.probed.val + 2
  let _ = @dx12.com_release(c)
}

///|
fn probe_cmdlist_chain(ctx : CmdCtx) -> Unit {

  probe_cmdlist_v0(ctx)

  probe_cmdlist_v1(ctx)

  probe_cmdlist_v2(ctx)

  probe_cmdlist_v3(ctx)

  probe_cmdlist_v4(ctx)

  probe_cmdlist_v5(ctx)

  probe_cmdlist_v6(ctx)

  probe_cmdlist_v7(ctx)

  probe_cmdlist_v8(ctx)

  probe_cmdlist_v9(ctx)

  probe_cmdlist_v10(ctx)

}
