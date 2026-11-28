// Auto-generated compile- and link-verification coverage for gated/platform/D3D11/PIX thunks.

///|
fn tc_typecheck_dxgi_unreached_0(probed : Ref[Int]) -> Unit {
  let _ = @dx12.dx_dxgi_decode_swap_chain_get_color_space((0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_decode_swap_chain_get_dest_size((0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_decode_swap_chain_get_source_rect((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_decode_swap_chain_get_target_rect((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_decode_swap_chain_present_buffer((0 : UInt64), 0, 0, 0)
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_decode_swap_chain_set_color_space((0 : UInt64), 0)
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_decode_swap_chain_set_dest_size((0 : UInt64), 0, 0)
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_decode_swap_chain_set_source_rect((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_decode_swap_chain_set_target_rect((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
}

///|
fn tc_typecheck_dxgi_unreached_1(probed : Ref[Int]) -> Unit {
  let _ = @dx12.dx_dxgi_device_create_surface((0 : UInt64), (0 : UInt64), 0, 0, (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_device_get_adapter((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_device_get_gpu_thread_priority((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_device_get_parent((0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_device_get_private_data((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_device_query_resource_residency((0 : UInt64), (0 : UInt64), (0 : UInt64), 0)
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_device_set_gpu_thread_priority((0 : UInt64), 0)
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_device_set_private_data((0 : UInt64), (0 : UInt64), 0, (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_device_set_private_data_interface((0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
}

///|
fn tc_typecheck_dxgi_unreached_2(probed : Ref[Int]) -> Unit {
  let _ = @dx12.dx_dxgi_device1_create_surface((0 : UInt64), (0 : UInt64), 0, 0, (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_device1_get_adapter((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_device1_get_gpu_thread_priority((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_device1_get_maximum_frame_latency((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_device1_get_parent((0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_device1_get_private_data((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_device1_query_resource_residency((0 : UInt64), (0 : UInt64), (0 : UInt64), 0)
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_device1_set_gpu_thread_priority((0 : UInt64), 0)
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_device1_set_maximum_frame_latency((0 : UInt64), 0)
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_device1_set_private_data((0 : UInt64), (0 : UInt64), 0, (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_device1_set_private_data_interface((0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
}

///|
fn tc_typecheck_dxgi_unreached_3(probed : Ref[Int]) -> Unit {
  let _ = @dx12.dx_dxgi_device2_create_surface((0 : UInt64), (0 : UInt64), 0, 0, (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_device2_enqueue_set_event((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_device2_get_adapter((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_device2_get_gpu_thread_priority((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_device2_get_maximum_frame_latency((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_device2_get_parent((0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_device2_get_private_data((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_device2_offer_resources((0 : UInt64), 0, (0 : UInt64), 0)
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_device2_query_resource_residency((0 : UInt64), (0 : UInt64), (0 : UInt64), 0)
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_device2_reclaim_resources((0 : UInt64), 0, (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_device2_set_gpu_thread_priority((0 : UInt64), 0)
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_device2_set_maximum_frame_latency((0 : UInt64), 0)
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_device2_set_private_data((0 : UInt64), (0 : UInt64), 0, (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_device2_set_private_data_interface((0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
}

///|
fn tc_typecheck_dxgi_unreached_4(probed : Ref[Int]) -> Unit {
  let _ = @dx12.dx_dxgi_device3_create_surface((0 : UInt64), (0 : UInt64), 0, 0, (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_device3_enqueue_set_event((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_device3_get_adapter((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_device3_get_gpu_thread_priority((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_device3_get_maximum_frame_latency((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_device3_get_parent((0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_device3_get_private_data((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_device3_offer_resources((0 : UInt64), 0, (0 : UInt64), 0)
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_device3_query_resource_residency((0 : UInt64), (0 : UInt64), (0 : UInt64), 0)
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_device3_reclaim_resources((0 : UInt64), 0, (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_device3_set_gpu_thread_priority((0 : UInt64), 0)
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_device3_set_maximum_frame_latency((0 : UInt64), 0)
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_device3_set_private_data((0 : UInt64), (0 : UInt64), 0, (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_device3_set_private_data_interface((0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  @dx12.dx_dxgi_device3_trim((0 : UInt64))
  probed.val = probed.val + 1
}

///|
fn tc_typecheck_dxgi_unreached_5(probed : Ref[Int]) -> Unit {
  let _ = @dx12.dx_dxgi_device4_create_surface((0 : UInt64), (0 : UInt64), 0, 0, (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_device4_enqueue_set_event((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_device4_get_adapter((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_device4_get_gpu_thread_priority((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_device4_get_maximum_frame_latency((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_device4_get_parent((0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_device4_get_private_data((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_device4_offer_resources((0 : UInt64), 0, (0 : UInt64), 0)
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_device4_offer_resources1((0 : UInt64), 0, (0 : UInt64), 0, 0)
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_device4_query_resource_residency((0 : UInt64), (0 : UInt64), (0 : UInt64), 0)
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_device4_reclaim_resources((0 : UInt64), 0, (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_device4_reclaim_resources1((0 : UInt64), 0, (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_device4_set_gpu_thread_priority((0 : UInt64), 0)
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_device4_set_maximum_frame_latency((0 : UInt64), 0)
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_device4_set_private_data((0 : UInt64), (0 : UInt64), 0, (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_device4_set_private_data_interface((0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  @dx12.dx_dxgi_device4_trim((0 : UInt64))
  probed.val = probed.val + 1
}

///|
fn tc_typecheck_dxgi_unreached_6(probed : Ref[Int]) -> Unit {
  let _ = @dx12.dx_dxgi_device_sub_object_get_device((0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_device_sub_object_get_parent((0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_device_sub_object_get_private_data((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_device_sub_object_set_private_data((0 : UInt64), (0 : UInt64), 0, (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_device_sub_object_set_private_data_interface((0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
}

///|
fn tc_typecheck_dxgi_unreached_7(probed : Ref[Int]) -> Unit {
  @dx12.dx_dxgi_display_control_set_stereo_enabled((0 : UInt64), 0)
  probed.val = probed.val + 1
}

///|
fn tc_typecheck_dxgi_unreached_8(probed : Ref[Int]) -> Unit {
  let _ = @dx12.dx_dxgi_factory_create_software_adapter((0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_factory_create_swap_chain((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
}

///|
fn tc_typecheck_dxgi_unreached_9(probed : Ref[Int]) -> Unit {
  let _ = @dx12.dx_dxgi_factory1_create_software_adapter((0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_factory1_create_swap_chain((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
}

///|
fn tc_typecheck_dxgi_unreached_10(probed : Ref[Int]) -> Unit {
  let _ = @dx12.dx_dxgi_factory2_create_software_adapter((0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_factory2_create_swap_chain((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_factory2_create_swap_chain_for_composition((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_factory2_create_swap_chain_for_core_window((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_factory2_get_shared_resource_adapter_luid((0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
}

///|
fn tc_typecheck_dxgi_unreached_11(probed : Ref[Int]) -> Unit {
  let _ = @dx12.dx_dxgi_factory3_create_software_adapter((0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_factory3_create_swap_chain((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_factory3_create_swap_chain_for_composition((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_factory3_create_swap_chain_for_core_window((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_factory3_create_swap_chain_for_hwnd((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_factory3_get_shared_resource_adapter_luid((0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
}

///|
fn tc_typecheck_dxgi_unreached_12(probed : Ref[Int]) -> Unit {
  let _ = @dx12.dx_dxgi_factory4_create_software_adapter((0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_factory4_create_swap_chain((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_factory4_create_swap_chain_for_composition((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_factory4_create_swap_chain_for_core_window((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_factory4_create_swap_chain_for_hwnd((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_factory4_get_shared_resource_adapter_luid((0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
}

///|
fn tc_typecheck_dxgi_unreached_13(probed : Ref[Int]) -> Unit {
  let _ = @dx12.dx_dxgi_factory5_create_software_adapter((0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_factory5_create_swap_chain((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_factory5_create_swap_chain_for_composition((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_factory5_create_swap_chain_for_core_window((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_factory5_create_swap_chain_for_hwnd((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_factory5_get_shared_resource_adapter_luid((0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
}

///|
fn tc_typecheck_dxgi_unreached_14(probed : Ref[Int]) -> Unit {
  let _ = @dx12.dx_dxgi_factory6_create_software_adapter((0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_factory6_create_swap_chain((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_factory6_create_swap_chain_for_composition((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_factory6_create_swap_chain_for_core_window((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_factory6_create_swap_chain_for_hwnd((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_factory6_get_shared_resource_adapter_luid((0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
}

///|
fn tc_typecheck_dxgi_unreached_15(probed : Ref[Int]) -> Unit {
  let _ = @dx12.dx_dxgi_factory7_create_software_adapter((0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_factory7_create_swap_chain((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_factory7_create_swap_chain_for_composition((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_factory7_create_swap_chain_for_core_window((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_factory7_create_swap_chain_for_hwnd((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_factory7_get_shared_resource_adapter_luid((0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
}

///|
fn tc_typecheck_dxgi_unreached_16(probed : Ref[Int]) -> Unit {
  let _ = @dx12.dx_dxgi_factory_media_create_decode_swap_chain_for_composition_surface_handle((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_factory_media_create_swap_chain_for_composition_surface_handle((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
}

///|
fn tc_typecheck_dxgi_unreached_17(probed : Ref[Int]) -> Unit {
  let _ = @dx12.dx_dxgi_keyed_mutex_acquire_sync((0 : UInt64), (0 : Int64), 0)
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_keyed_mutex_get_device((0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_keyed_mutex_get_parent((0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_keyed_mutex_get_private_data((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_keyed_mutex_release_sync((0 : UInt64), (0 : Int64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_keyed_mutex_set_private_data((0 : UInt64), (0 : UInt64), 0, (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_keyed_mutex_set_private_data_interface((0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
}

///|
fn tc_typecheck_dxgi_unreached_18(probed : Ref[Int]) -> Unit {
  let _ = @dx12.dx_dxgi_output_get_display_surface_data((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_output_get_gamma_control((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  @dx12.dx_dxgi_output_release_ownership((0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_output_set_display_surface((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_output_set_gamma_control((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_output_take_ownership((0 : UInt64), (0 : UInt64), 0)
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_output_wait_for_v_blank((0 : UInt64))
  probed.val = probed.val + 1
}

///|
fn tc_typecheck_dxgi_unreached_19(probed : Ref[Int]) -> Unit {
  let _ = @dx12.dx_dxgi_output1_duplicate_output((0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_output1_get_display_surface_data((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_output1_get_display_surface_data1((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_output1_get_gamma_control((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  @dx12.dx_dxgi_output1_release_ownership((0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_output1_set_display_surface((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_output1_set_gamma_control((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_output1_take_ownership((0 : UInt64), (0 : UInt64), 0)
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_output1_wait_for_v_blank((0 : UInt64))
  probed.val = probed.val + 1
}

///|
fn tc_typecheck_dxgi_unreached_20(probed : Ref[Int]) -> Unit {
  let _ = @dx12.dx_dxgi_output2_duplicate_output((0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_output2_get_display_surface_data((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_output2_get_display_surface_data1((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_output2_get_gamma_control((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  @dx12.dx_dxgi_output2_release_ownership((0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_output2_set_display_surface((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_output2_set_gamma_control((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_output2_take_ownership((0 : UInt64), (0 : UInt64), 0)
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_output2_wait_for_v_blank((0 : UInt64))
  probed.val = probed.val + 1
}

///|
fn tc_typecheck_dxgi_unreached_21(probed : Ref[Int]) -> Unit {
  let _ = @dx12.dx_dxgi_output3_duplicate_output((0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_output3_get_display_surface_data((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_output3_get_display_surface_data1((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_output3_get_gamma_control((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  @dx12.dx_dxgi_output3_release_ownership((0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_output3_set_display_surface((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_output3_set_gamma_control((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_output3_take_ownership((0 : UInt64), (0 : UInt64), 0)
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_output3_wait_for_v_blank((0 : UInt64))
  probed.val = probed.val + 1
}

///|
fn tc_typecheck_dxgi_unreached_22(probed : Ref[Int]) -> Unit {
  let _ = @dx12.dx_dxgi_output4_duplicate_output((0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_output4_get_display_surface_data((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_output4_get_display_surface_data1((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_output4_get_gamma_control((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  @dx12.dx_dxgi_output4_release_ownership((0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_output4_set_display_surface((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_output4_set_gamma_control((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_output4_take_ownership((0 : UInt64), (0 : UInt64), 0)
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_output4_wait_for_v_blank((0 : UInt64))
  probed.val = probed.val + 1
}

///|
fn tc_typecheck_dxgi_unreached_23(probed : Ref[Int]) -> Unit {
  let _ = @dx12.dx_dxgi_output5_duplicate_output((0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_output5_duplicate_output1((0 : UInt64), (0 : UInt64), 0, 0, (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_output5_get_display_surface_data((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_output5_get_display_surface_data1((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_output5_get_gamma_control((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  @dx12.dx_dxgi_output5_release_ownership((0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_output5_set_display_surface((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_output5_set_gamma_control((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_output5_take_ownership((0 : UInt64), (0 : UInt64), 0)
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_output5_wait_for_v_blank((0 : UInt64))
  probed.val = probed.val + 1
}

///|
fn tc_typecheck_dxgi_unreached_24(probed : Ref[Int]) -> Unit {
  let _ = @dx12.dx_dxgi_output6_duplicate_output((0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_output6_duplicate_output1((0 : UInt64), (0 : UInt64), 0, 0, (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_output6_get_display_surface_data((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_output6_get_display_surface_data1((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_output6_get_gamma_control((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  @dx12.dx_dxgi_output6_release_ownership((0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_output6_set_display_surface((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_output6_set_gamma_control((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_output6_take_ownership((0 : UInt64), (0 : UInt64), 0)
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_output6_wait_for_v_blank((0 : UInt64))
  probed.val = probed.val + 1
}

///|
fn tc_typecheck_dxgi_unreached_25(probed : Ref[Int]) -> Unit {
  let _ = @dx12.dx_dxgi_output_duplication_acquire_next_frame((0 : UInt64), 0, (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  @dx12.dx_dxgi_output_duplication_get_desc((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_output_duplication_get_frame_dirty_rects((0 : UInt64), 0, (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_output_duplication_get_frame_move_rects((0 : UInt64), 0, (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_output_duplication_get_frame_pointer_shape((0 : UInt64), 0, (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_output_duplication_get_parent((0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_output_duplication_get_private_data((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_output_duplication_map_desktop_surface((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_output_duplication_release_frame((0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_output_duplication_set_private_data((0 : UInt64), (0 : UInt64), 0, (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_output_duplication_set_private_data_interface((0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_output_duplication_un_map_desktop_surface((0 : UInt64))
  probed.val = probed.val + 1
}

///|
fn tc_typecheck_dxgi_unreached_26(probed : Ref[Int]) -> Unit {
  let _ = @dx12.dx_dxgi_resource_get_device((0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_resource_get_eviction_priority((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_resource_get_parent((0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_resource_get_private_data((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_resource_get_shared_handle((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_resource_get_usage((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_resource_set_eviction_priority((0 : UInt64), 0)
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_resource_set_private_data((0 : UInt64), (0 : UInt64), 0, (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_resource_set_private_data_interface((0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
}

///|
fn tc_typecheck_dxgi_unreached_27(probed : Ref[Int]) -> Unit {
  let _ = @dx12.dx_dxgi_resource1_create_shared_handle((0 : UInt64), (0 : UInt64), 0, (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_resource1_create_subresource_surface((0 : UInt64), 0, (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_resource1_get_device((0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_resource1_get_eviction_priority((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_resource1_get_parent((0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_resource1_get_private_data((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_resource1_get_shared_handle((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_resource1_get_usage((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_resource1_set_eviction_priority((0 : UInt64), 0)
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_resource1_set_private_data((0 : UInt64), (0 : UInt64), 0, (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_resource1_set_private_data_interface((0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
}

///|
fn tc_typecheck_dxgi_unreached_28(probed : Ref[Int]) -> Unit {
  let _ = @dx12.dx_dxgi_surface_get_desc((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_surface_get_device((0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_surface_get_parent((0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_surface_get_private_data((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_surface_map((0 : UInt64), (0 : UInt64), 0)
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_surface_set_private_data((0 : UInt64), (0 : UInt64), 0, (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_surface_set_private_data_interface((0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_surface_unmap((0 : UInt64))
  probed.val = probed.val + 1
}

///|
fn tc_typecheck_dxgi_unreached_29(probed : Ref[Int]) -> Unit {
  let _ = @dx12.dx_dxgi_surface1_get_dc((0 : UInt64), 0, (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_surface1_get_desc((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_surface1_get_device((0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_surface1_get_parent((0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_surface1_get_private_data((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_surface1_map((0 : UInt64), (0 : UInt64), 0)
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_surface1_release_dc((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_surface1_set_private_data((0 : UInt64), (0 : UInt64), 0, (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_surface1_set_private_data_interface((0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_surface1_unmap((0 : UInt64))
  probed.val = probed.val + 1
}

///|
fn tc_typecheck_dxgi_unreached_30(probed : Ref[Int]) -> Unit {
  let _ = @dx12.dx_dxgi_surface2_get_dc((0 : UInt64), 0, (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_surface2_get_desc((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_surface2_get_device((0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_surface2_get_parent((0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_surface2_get_private_data((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_surface2_get_resource((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_surface2_map((0 : UInt64), (0 : UInt64), 0)
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_surface2_release_dc((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_surface2_set_private_data((0 : UInt64), (0 : UInt64), 0, (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_surface2_set_private_data_interface((0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_surface2_unmap((0 : UInt64))
  probed.val = probed.val + 1
}

///|
fn tc_typecheck_dxgi_unreached_31(probed : Ref[Int]) -> Unit {
  let _ = @dx12.dx_dxgi_swap_chain_resize_target((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_swap_chain_set_fullscreen_state((0 : UInt64), 0, (0 : UInt64))
  probed.val = probed.val + 1
}

///|
fn tc_typecheck_dxgi_unreached_32(probed : Ref[Int]) -> Unit {
  let _ = @dx12.dx_dxgi_swap_chain1_get_core_window((0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_swap_chain1_resize_target((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_swap_chain1_set_fullscreen_state((0 : UInt64), 0, (0 : UInt64))
  probed.val = probed.val + 1
}

///|
fn tc_typecheck_dxgi_unreached_33(probed : Ref[Int]) -> Unit {
  let _ = @dx12.dx_dxgi_swap_chain2_get_core_window((0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_swap_chain2_resize_target((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_swap_chain2_set_fullscreen_state((0 : UInt64), 0, (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_swap_chain2_set_matrix_transform((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
}

///|
fn tc_typecheck_dxgi_unreached_34(probed : Ref[Int]) -> Unit {
  let _ = @dx12.dx_dxgi_swap_chain3_get_core_window((0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_swap_chain3_resize_buffers1((0 : UInt64), 0, 0, 0, 0, 0, (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_swap_chain3_resize_target((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_swap_chain3_set_fullscreen_state((0 : UInt64), 0, (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_swap_chain3_set_matrix_transform((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
}

///|
fn tc_typecheck_dxgi_unreached_35(probed : Ref[Int]) -> Unit {
  let _ = @dx12.dx_dxgi_swap_chain4_get_core_window((0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_swap_chain4_resize_buffers1((0 : UInt64), 0, 0, 0, 0, 0, (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_swap_chain4_resize_target((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_swap_chain4_set_fullscreen_state((0 : UInt64), 0, (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_swap_chain4_set_matrix_transform((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
}

///|
fn tc_typecheck_dxgi_unreached_36(probed : Ref[Int]) -> Unit {
  let _ = @dx12.dx_dxgi_swap_chain_media_check_present_duration_support((0 : UInt64), 0, (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_swap_chain_media_get_frame_statistics_media((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_dxgi_swap_chain_media_set_present_duration((0 : UInt64), 0)
  probed.val = probed.val + 1
}

///|
fn typecheck_dxgi_unreached(probed : Ref[Int]) -> Unit {
  tc_typecheck_dxgi_unreached_0(probed)
  tc_typecheck_dxgi_unreached_1(probed)
  tc_typecheck_dxgi_unreached_2(probed)
  tc_typecheck_dxgi_unreached_3(probed)
  tc_typecheck_dxgi_unreached_4(probed)
  tc_typecheck_dxgi_unreached_5(probed)
  tc_typecheck_dxgi_unreached_6(probed)
  tc_typecheck_dxgi_unreached_7(probed)
  tc_typecheck_dxgi_unreached_8(probed)
  tc_typecheck_dxgi_unreached_9(probed)
  tc_typecheck_dxgi_unreached_10(probed)
  tc_typecheck_dxgi_unreached_11(probed)
  tc_typecheck_dxgi_unreached_12(probed)
  tc_typecheck_dxgi_unreached_13(probed)
  tc_typecheck_dxgi_unreached_14(probed)
  tc_typecheck_dxgi_unreached_15(probed)
  tc_typecheck_dxgi_unreached_16(probed)
  tc_typecheck_dxgi_unreached_17(probed)
  tc_typecheck_dxgi_unreached_18(probed)
  tc_typecheck_dxgi_unreached_19(probed)
  tc_typecheck_dxgi_unreached_20(probed)
  tc_typecheck_dxgi_unreached_21(probed)
  tc_typecheck_dxgi_unreached_22(probed)
  tc_typecheck_dxgi_unreached_23(probed)
  tc_typecheck_dxgi_unreached_24(probed)
  tc_typecheck_dxgi_unreached_25(probed)
  tc_typecheck_dxgi_unreached_26(probed)
  tc_typecheck_dxgi_unreached_27(probed)
  tc_typecheck_dxgi_unreached_28(probed)
  tc_typecheck_dxgi_unreached_29(probed)
  tc_typecheck_dxgi_unreached_30(probed)
  tc_typecheck_dxgi_unreached_31(probed)
  tc_typecheck_dxgi_unreached_32(probed)
  tc_typecheck_dxgi_unreached_33(probed)
  tc_typecheck_dxgi_unreached_34(probed)
  tc_typecheck_dxgi_unreached_35(probed)
  tc_typecheck_dxgi_unreached_36(probed)
}
