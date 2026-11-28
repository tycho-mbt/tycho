// Auto-generated compile- and link-verification coverage for gated/platform/D3D11/PIX thunks.

///|
fn tc_typecheck_d3d12_unreached_0(probed : Ref[Int]) -> Unit {
  @dx12.dx_d3d12_command_queue_begin_event((0 : UInt64), 0, (0 : UInt64), 0)
  probed.val = probed.val + 1
  @dx12.dx_d3d12_command_queue_copy_tile_mappings((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64), 0)
  probed.val = probed.val + 1
  @dx12.dx_d3d12_command_queue_end_event((0 : UInt64))
  probed.val = probed.val + 1
  @dx12.dx_d3d12_command_queue_update_tile_mappings((0 : UInt64), (0 : UInt64), 0, (0 : UInt64), (0 : UInt64), (0 : UInt64), 0, (0 : UInt64), (0 : UInt64), (0 : UInt64), 0)
  probed.val = probed.val + 1
}

///|
fn tc_typecheck_d3d12_unreached_1(probed : Ref[Int]) -> Unit {
  let _ = @dx12.dx_d3d12_dsr_device_factory_create_dsr_device((0 : UInt64), (0 : UInt64), 0, (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
}

///|
fn tc_typecheck_d3d12_unreached_2(probed : Ref[Int]) -> Unit {
  let _ = @dx12.dx_d3d12_device_set_stable_power_state((0 : UInt64), 0)
  probed.val = probed.val + 1
}

///|
fn tc_typecheck_d3d12_unreached_3(probed : Ref[Int]) -> Unit {
  let _ = @dx12.dx_d3d12_device1_set_stable_power_state((0 : UInt64), 0)
  probed.val = probed.val + 1
}

///|
fn tc_typecheck_d3d12_unreached_4(probed : Ref[Int]) -> Unit {
  let _ = @dx12.dx_d3d12_device10_create_lifetime_tracker((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_device10_create_meta_command((0 : UInt64), (0 : UInt64), 0, (0 : UInt64), (0 : Int64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_device10_create_protected_resource_session((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_device10_create_protected_resource_session1((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  @dx12.dx_d3d12_device10_create_sampler_feedback_unordered_access_view((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_device10_enumerate_meta_command_parameters((0 : UInt64), (0 : UInt64), 0, (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_device10_open_existing_heap_from_address((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_device10_open_existing_heap_from_file_mapping((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  @dx12.dx_d3d12_device10_remove_device((0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_device10_set_stable_power_state((0 : UInt64), 0)
  probed.val = probed.val + 1
}

///|
fn tc_typecheck_d3d12_unreached_5(probed : Ref[Int]) -> Unit {
  let _ = @dx12.dx_d3d12_device11_create_lifetime_tracker((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_device11_create_meta_command((0 : UInt64), (0 : UInt64), 0, (0 : UInt64), (0 : Int64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_device11_create_protected_resource_session((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_device11_create_protected_resource_session1((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  @dx12.dx_d3d12_device11_create_sampler_feedback_unordered_access_view((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_device11_enumerate_meta_command_parameters((0 : UInt64), (0 : UInt64), 0, (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_device11_open_existing_heap_from_address((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_device11_open_existing_heap_from_file_mapping((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  @dx12.dx_d3d12_device11_remove_device((0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_device11_set_stable_power_state((0 : UInt64), 0)
  probed.val = probed.val + 1
}

///|
fn tc_typecheck_d3d12_unreached_6(probed : Ref[Int]) -> Unit {
  let _ = @dx12.dx_d3d12_device12_create_lifetime_tracker((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_device12_create_meta_command((0 : UInt64), (0 : UInt64), 0, (0 : UInt64), (0 : Int64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_device12_create_protected_resource_session((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_device12_create_protected_resource_session1((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  @dx12.dx_d3d12_device12_create_sampler_feedback_unordered_access_view((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_device12_enumerate_meta_command_parameters((0 : UInt64), (0 : UInt64), 0, (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_device12_open_existing_heap_from_address((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_device12_open_existing_heap_from_file_mapping((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  @dx12.dx_d3d12_device12_remove_device((0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_device12_set_stable_power_state((0 : UInt64), 0)
  probed.val = probed.val + 1
}

///|
fn tc_typecheck_d3d12_unreached_7(probed : Ref[Int]) -> Unit {
  let _ = @dx12.dx_d3d12_device13_create_lifetime_tracker((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_device13_create_meta_command((0 : UInt64), (0 : UInt64), 0, (0 : UInt64), (0 : Int64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_device13_create_protected_resource_session((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_device13_create_protected_resource_session1((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  @dx12.dx_d3d12_device13_create_sampler_feedback_unordered_access_view((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_device13_enumerate_meta_command_parameters((0 : UInt64), (0 : UInt64), 0, (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_device13_open_existing_heap_from_address((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_device13_open_existing_heap_from_address1((0 : UInt64), (0 : UInt64), (0 : Int64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_device13_open_existing_heap_from_file_mapping((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  @dx12.dx_d3d12_device13_remove_device((0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_device13_set_stable_power_state((0 : UInt64), 0)
  probed.val = probed.val + 1
}

///|
fn tc_typecheck_d3d12_unreached_8(probed : Ref[Int]) -> Unit {
  let _ = @dx12.dx_d3d12_device14_create_lifetime_tracker((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_device14_create_meta_command((0 : UInt64), (0 : UInt64), 0, (0 : UInt64), (0 : Int64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_device14_create_protected_resource_session((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_device14_create_protected_resource_session1((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_device14_create_root_signature_from_subobject_in_library((0 : UInt64), 0, (0 : UInt64), (0 : Int64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  @dx12.dx_d3d12_device14_create_sampler_feedback_unordered_access_view((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_device14_enumerate_meta_command_parameters((0 : UInt64), (0 : UInt64), 0, (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_device14_open_existing_heap_from_address((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_device14_open_existing_heap_from_address1((0 : UInt64), (0 : UInt64), (0 : Int64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_device14_open_existing_heap_from_file_mapping((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  @dx12.dx_d3d12_device14_remove_device((0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_device14_set_stable_power_state((0 : UInt64), 0)
  probed.val = probed.val + 1
}

///|
fn tc_typecheck_d3d12_unreached_9(probed : Ref[Int]) -> Unit {
  let _ = @dx12.dx_d3d12_device2_set_stable_power_state((0 : UInt64), 0)
  probed.val = probed.val + 1
}

///|
fn tc_typecheck_d3d12_unreached_10(probed : Ref[Int]) -> Unit {
  let _ = @dx12.dx_d3d12_device3_open_existing_heap_from_address((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_device3_open_existing_heap_from_file_mapping((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_device3_set_stable_power_state((0 : UInt64), 0)
  probed.val = probed.val + 1
}

///|
fn tc_typecheck_d3d12_unreached_11(probed : Ref[Int]) -> Unit {
  let _ = @dx12.dx_d3d12_device4_create_protected_resource_session((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_device4_open_existing_heap_from_address((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_device4_open_existing_heap_from_file_mapping((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_device4_set_stable_power_state((0 : UInt64), 0)
  probed.val = probed.val + 1
}

///|
fn tc_typecheck_d3d12_unreached_12(probed : Ref[Int]) -> Unit {
  let _ = @dx12.dx_d3d12_device5_create_lifetime_tracker((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_device5_create_meta_command((0 : UInt64), (0 : UInt64), 0, (0 : UInt64), (0 : Int64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_device5_create_protected_resource_session((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_device5_enumerate_meta_command_parameters((0 : UInt64), (0 : UInt64), 0, (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_device5_open_existing_heap_from_address((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_device5_open_existing_heap_from_file_mapping((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  @dx12.dx_d3d12_device5_remove_device((0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_device5_set_stable_power_state((0 : UInt64), 0)
  probed.val = probed.val + 1
}

///|
fn tc_typecheck_d3d12_unreached_13(probed : Ref[Int]) -> Unit {
  let _ = @dx12.dx_d3d12_device6_create_lifetime_tracker((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_device6_create_meta_command((0 : UInt64), (0 : UInt64), 0, (0 : UInt64), (0 : Int64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_device6_create_protected_resource_session((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_device6_enumerate_meta_command_parameters((0 : UInt64), (0 : UInt64), 0, (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_device6_open_existing_heap_from_address((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_device6_open_existing_heap_from_file_mapping((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  @dx12.dx_d3d12_device6_remove_device((0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_device6_set_stable_power_state((0 : UInt64), 0)
  probed.val = probed.val + 1
}

///|
fn tc_typecheck_d3d12_unreached_14(probed : Ref[Int]) -> Unit {
  let _ = @dx12.dx_d3d12_device7_create_lifetime_tracker((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_device7_create_meta_command((0 : UInt64), (0 : UInt64), 0, (0 : UInt64), (0 : Int64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_device7_create_protected_resource_session((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_device7_create_protected_resource_session1((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_device7_enumerate_meta_command_parameters((0 : UInt64), (0 : UInt64), 0, (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_device7_open_existing_heap_from_address((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_device7_open_existing_heap_from_file_mapping((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  @dx12.dx_d3d12_device7_remove_device((0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_device7_set_stable_power_state((0 : UInt64), 0)
  probed.val = probed.val + 1
}

///|
fn tc_typecheck_d3d12_unreached_15(probed : Ref[Int]) -> Unit {
  let _ = @dx12.dx_d3d12_device8_create_lifetime_tracker((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_device8_create_meta_command((0 : UInt64), (0 : UInt64), 0, (0 : UInt64), (0 : Int64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_device8_create_protected_resource_session((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_device8_create_protected_resource_session1((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  @dx12.dx_d3d12_device8_create_sampler_feedback_unordered_access_view((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_device8_enumerate_meta_command_parameters((0 : UInt64), (0 : UInt64), 0, (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_device8_open_existing_heap_from_address((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_device8_open_existing_heap_from_file_mapping((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  @dx12.dx_d3d12_device8_remove_device((0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_device8_set_stable_power_state((0 : UInt64), 0)
  probed.val = probed.val + 1
}

///|
fn tc_typecheck_d3d12_unreached_16(probed : Ref[Int]) -> Unit {
  let _ = @dx12.dx_d3d12_device9_create_lifetime_tracker((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_device9_create_meta_command((0 : UInt64), (0 : UInt64), 0, (0 : UInt64), (0 : Int64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_device9_create_protected_resource_session((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_device9_create_protected_resource_session1((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  @dx12.dx_d3d12_device9_create_sampler_feedback_unordered_access_view((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_device9_enumerate_meta_command_parameters((0 : UInt64), (0 : UInt64), 0, (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_device9_open_existing_heap_from_address((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_device9_open_existing_heap_from_file_mapping((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  @dx12.dx_d3d12_device9_remove_device((0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_device9_set_stable_power_state((0 : UInt64), 0)
  probed.val = probed.val + 1
}

///|
fn tc_typecheck_d3d12_unreached_17(probed : Ref[Int]) -> Unit {
  let _ = @dx12.dx_d3d12_device_configuration1_create_versioned_root_signature_deserializer_from_subobject_in_library((0 : UInt64), (0 : UInt64), (0 : Int64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
}

///|
fn tc_typecheck_d3d12_unreached_18(probed : Ref[Int]) -> Unit {
  let _ = @dx12.dx_d3d12_device_factory_apply_to_global_state((0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_device_factory_create_device((0 : UInt64), (0 : UInt64), 0, (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_device_factory_enable_experimental_features((0 : UInt64), 0, (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_device_factory_initialize_from_global_state((0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_device_factory_set_flags((0 : UInt64), 0)
  probed.val = probed.val + 1
}

///|
fn tc_typecheck_d3d12_unreached_19(probed : Ref[Int]) -> Unit {
  @dx12.dx_d3d12_device_tools_set_next_allocation_address((0 : UInt64), (0 : Int64))
  probed.val = probed.val + 1
}

///|
fn tc_typecheck_d3d12_unreached_20(probed : Ref[Int]) -> Unit {
  let _ = @dx12.dx_d3d12_device_tools1_get_application_specific_driver_blob_status((0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_device_tools1_get_application_specific_driver_state((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  @dx12.dx_d3d12_device_tools1_set_next_allocation_address((0 : UInt64), (0 : Int64))
  probed.val = probed.val + 1
}

///|
fn tc_typecheck_d3d12_unreached_21(probed : Ref[Int]) -> Unit {
  @dx12.dx_d3d12_gbv_diagnostics_gbv_reserved0((0 : UInt64))
  probed.val = probed.val + 1
  @dx12.dx_d3d12_gbv_diagnostics_gbv_reserved1((0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_gbv_diagnostics_get_gbv_entire_subresource_states_data((0 : UInt64), (0 : UInt64), (0 : UInt64), 0)
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_gbv_diagnostics_get_gbv_resource_info((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_gbv_diagnostics_get_gbv_resource_uniform_state((0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_gbv_diagnostics_get_gbv_subresource_state((0 : UInt64), (0 : UInt64), 0, (0 : UInt64))
  probed.val = probed.val + 1
}

///|
fn tc_typecheck_d3d12_unreached_22(probed : Ref[Int]) -> Unit {
  @dx12.dx_d3d12_graphics_command_list_begin_event((0 : UInt64), 0, (0 : UInt64), 0)
  probed.val = probed.val + 1
  @dx12.dx_d3d12_graphics_command_list_copy_tiles((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : Int64), 0)
  probed.val = probed.val + 1
  @dx12.dx_d3d12_graphics_command_list_discard_resource((0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  @dx12.dx_d3d12_graphics_command_list_end_event((0 : UInt64))
  probed.val = probed.val + 1
  @dx12.dx_d3d12_graphics_command_list_set_predication((0 : UInt64), (0 : UInt64), (0 : Int64), 0)
  probed.val = probed.val + 1
}

///|
fn tc_typecheck_d3d12_unreached_23(probed : Ref[Int]) -> Unit {
  @dx12.dx_d3d12_graphics_command_list1_begin_event((0 : UInt64), 0, (0 : UInt64), 0)
  probed.val = probed.val + 1
  @dx12.dx_d3d12_graphics_command_list1_copy_tiles((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : Int64), 0)
  probed.val = probed.val + 1
  @dx12.dx_d3d12_graphics_command_list1_discard_resource((0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  @dx12.dx_d3d12_graphics_command_list1_end_event((0 : UInt64))
  probed.val = probed.val + 1
  @dx12.dx_d3d12_graphics_command_list1_set_predication((0 : UInt64), (0 : UInt64), (0 : Int64), 0)
  probed.val = probed.val + 1
}

///|
fn tc_typecheck_d3d12_unreached_24(probed : Ref[Int]) -> Unit {
  @dx12.dx_d3d12_graphics_command_list10_begin_event((0 : UInt64), 0, (0 : UInt64), 0)
  probed.val = probed.val + 1
  @dx12.dx_d3d12_graphics_command_list10_copy_tiles((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : Int64), 0)
  probed.val = probed.val + 1
  @dx12.dx_d3d12_graphics_command_list10_discard_resource((0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  @dx12.dx_d3d12_graphics_command_list10_dispatch_graph((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  @dx12.dx_d3d12_graphics_command_list10_dispatch_mesh((0 : UInt64), 0, 0, 0)
  probed.val = probed.val + 1
  @dx12.dx_d3d12_graphics_command_list10_dispatch_rays((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  @dx12.dx_d3d12_graphics_command_list10_end_event((0 : UInt64))
  probed.val = probed.val + 1
  @dx12.dx_d3d12_graphics_command_list10_execute_meta_command((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : Int64))
  probed.val = probed.val + 1
  @dx12.dx_d3d12_graphics_command_list10_initialize_meta_command((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : Int64))
  probed.val = probed.val + 1
  @dx12.dx_d3d12_graphics_command_list10_set_predication((0 : UInt64), (0 : UInt64), (0 : Int64), 0)
  probed.val = probed.val + 1
  @dx12.dx_d3d12_graphics_command_list10_set_program((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  @dx12.dx_d3d12_graphics_command_list10_set_protected_resource_session((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
}

///|
fn tc_typecheck_d3d12_unreached_25(probed : Ref[Int]) -> Unit {
  @dx12.dx_d3d12_graphics_command_list2_begin_event((0 : UInt64), 0, (0 : UInt64), 0)
  probed.val = probed.val + 1
  @dx12.dx_d3d12_graphics_command_list2_copy_tiles((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : Int64), 0)
  probed.val = probed.val + 1
  @dx12.dx_d3d12_graphics_command_list2_discard_resource((0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  @dx12.dx_d3d12_graphics_command_list2_end_event((0 : UInt64))
  probed.val = probed.val + 1
  @dx12.dx_d3d12_graphics_command_list2_set_predication((0 : UInt64), (0 : UInt64), (0 : Int64), 0)
  probed.val = probed.val + 1
}

///|
fn tc_typecheck_d3d12_unreached_26(probed : Ref[Int]) -> Unit {
  @dx12.dx_d3d12_graphics_command_list3_begin_event((0 : UInt64), 0, (0 : UInt64), 0)
  probed.val = probed.val + 1
  @dx12.dx_d3d12_graphics_command_list3_copy_tiles((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : Int64), 0)
  probed.val = probed.val + 1
  @dx12.dx_d3d12_graphics_command_list3_discard_resource((0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  @dx12.dx_d3d12_graphics_command_list3_end_event((0 : UInt64))
  probed.val = probed.val + 1
  @dx12.dx_d3d12_graphics_command_list3_set_predication((0 : UInt64), (0 : UInt64), (0 : Int64), 0)
  probed.val = probed.val + 1
  @dx12.dx_d3d12_graphics_command_list3_set_protected_resource_session((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
}

///|
fn tc_typecheck_d3d12_unreached_27(probed : Ref[Int]) -> Unit {
  @dx12.dx_d3d12_graphics_command_list4_begin_event((0 : UInt64), 0, (0 : UInt64), 0)
  probed.val = probed.val + 1
  @dx12.dx_d3d12_graphics_command_list4_copy_tiles((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : Int64), 0)
  probed.val = probed.val + 1
  @dx12.dx_d3d12_graphics_command_list4_discard_resource((0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  @dx12.dx_d3d12_graphics_command_list4_dispatch_rays((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  @dx12.dx_d3d12_graphics_command_list4_end_event((0 : UInt64))
  probed.val = probed.val + 1
  @dx12.dx_d3d12_graphics_command_list4_execute_meta_command((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : Int64))
  probed.val = probed.val + 1
  @dx12.dx_d3d12_graphics_command_list4_initialize_meta_command((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : Int64))
  probed.val = probed.val + 1
  @dx12.dx_d3d12_graphics_command_list4_set_predication((0 : UInt64), (0 : UInt64), (0 : Int64), 0)
  probed.val = probed.val + 1
  @dx12.dx_d3d12_graphics_command_list4_set_protected_resource_session((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
}

///|
fn tc_typecheck_d3d12_unreached_28(probed : Ref[Int]) -> Unit {
  @dx12.dx_d3d12_graphics_command_list5_begin_event((0 : UInt64), 0, (0 : UInt64), 0)
  probed.val = probed.val + 1
  @dx12.dx_d3d12_graphics_command_list5_copy_tiles((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : Int64), 0)
  probed.val = probed.val + 1
  @dx12.dx_d3d12_graphics_command_list5_discard_resource((0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  @dx12.dx_d3d12_graphics_command_list5_dispatch_rays((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  @dx12.dx_d3d12_graphics_command_list5_end_event((0 : UInt64))
  probed.val = probed.val + 1
  @dx12.dx_d3d12_graphics_command_list5_execute_meta_command((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : Int64))
  probed.val = probed.val + 1
  @dx12.dx_d3d12_graphics_command_list5_initialize_meta_command((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : Int64))
  probed.val = probed.val + 1
  @dx12.dx_d3d12_graphics_command_list5_set_predication((0 : UInt64), (0 : UInt64), (0 : Int64), 0)
  probed.val = probed.val + 1
  @dx12.dx_d3d12_graphics_command_list5_set_protected_resource_session((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
}

///|
fn tc_typecheck_d3d12_unreached_29(probed : Ref[Int]) -> Unit {
  @dx12.dx_d3d12_graphics_command_list6_begin_event((0 : UInt64), 0, (0 : UInt64), 0)
  probed.val = probed.val + 1
  @dx12.dx_d3d12_graphics_command_list6_copy_tiles((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : Int64), 0)
  probed.val = probed.val + 1
  @dx12.dx_d3d12_graphics_command_list6_discard_resource((0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  @dx12.dx_d3d12_graphics_command_list6_dispatch_mesh((0 : UInt64), 0, 0, 0)
  probed.val = probed.val + 1
  @dx12.dx_d3d12_graphics_command_list6_dispatch_rays((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  @dx12.dx_d3d12_graphics_command_list6_end_event((0 : UInt64))
  probed.val = probed.val + 1
  @dx12.dx_d3d12_graphics_command_list6_execute_meta_command((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : Int64))
  probed.val = probed.val + 1
  @dx12.dx_d3d12_graphics_command_list6_initialize_meta_command((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : Int64))
  probed.val = probed.val + 1
  @dx12.dx_d3d12_graphics_command_list6_set_predication((0 : UInt64), (0 : UInt64), (0 : Int64), 0)
  probed.val = probed.val + 1
  @dx12.dx_d3d12_graphics_command_list6_set_protected_resource_session((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
}

///|
fn tc_typecheck_d3d12_unreached_30(probed : Ref[Int]) -> Unit {
  @dx12.dx_d3d12_graphics_command_list7_begin_event((0 : UInt64), 0, (0 : UInt64), 0)
  probed.val = probed.val + 1
  @dx12.dx_d3d12_graphics_command_list7_copy_tiles((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : Int64), 0)
  probed.val = probed.val + 1
  @dx12.dx_d3d12_graphics_command_list7_discard_resource((0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  @dx12.dx_d3d12_graphics_command_list7_dispatch_mesh((0 : UInt64), 0, 0, 0)
  probed.val = probed.val + 1
  @dx12.dx_d3d12_graphics_command_list7_dispatch_rays((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  @dx12.dx_d3d12_graphics_command_list7_end_event((0 : UInt64))
  probed.val = probed.val + 1
  @dx12.dx_d3d12_graphics_command_list7_execute_meta_command((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : Int64))
  probed.val = probed.val + 1
  @dx12.dx_d3d12_graphics_command_list7_initialize_meta_command((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : Int64))
  probed.val = probed.val + 1
  @dx12.dx_d3d12_graphics_command_list7_set_predication((0 : UInt64), (0 : UInt64), (0 : Int64), 0)
  probed.val = probed.val + 1
  @dx12.dx_d3d12_graphics_command_list7_set_protected_resource_session((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
}

///|
fn tc_typecheck_d3d12_unreached_31(probed : Ref[Int]) -> Unit {
  @dx12.dx_d3d12_graphics_command_list8_begin_event((0 : UInt64), 0, (0 : UInt64), 0)
  probed.val = probed.val + 1
  @dx12.dx_d3d12_graphics_command_list8_copy_tiles((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : Int64), 0)
  probed.val = probed.val + 1
  @dx12.dx_d3d12_graphics_command_list8_discard_resource((0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  @dx12.dx_d3d12_graphics_command_list8_dispatch_mesh((0 : UInt64), 0, 0, 0)
  probed.val = probed.val + 1
  @dx12.dx_d3d12_graphics_command_list8_dispatch_rays((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  @dx12.dx_d3d12_graphics_command_list8_end_event((0 : UInt64))
  probed.val = probed.val + 1
  @dx12.dx_d3d12_graphics_command_list8_execute_meta_command((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : Int64))
  probed.val = probed.val + 1
  @dx12.dx_d3d12_graphics_command_list8_initialize_meta_command((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : Int64))
  probed.val = probed.val + 1
  @dx12.dx_d3d12_graphics_command_list8_set_predication((0 : UInt64), (0 : UInt64), (0 : Int64), 0)
  probed.val = probed.val + 1
  @dx12.dx_d3d12_graphics_command_list8_set_protected_resource_session((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
}

///|
fn tc_typecheck_d3d12_unreached_32(probed : Ref[Int]) -> Unit {
  @dx12.dx_d3d12_graphics_command_list9_begin_event((0 : UInt64), 0, (0 : UInt64), 0)
  probed.val = probed.val + 1
  @dx12.dx_d3d12_graphics_command_list9_copy_tiles((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : Int64), 0)
  probed.val = probed.val + 1
  @dx12.dx_d3d12_graphics_command_list9_discard_resource((0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  @dx12.dx_d3d12_graphics_command_list9_dispatch_mesh((0 : UInt64), 0, 0, 0)
  probed.val = probed.val + 1
  @dx12.dx_d3d12_graphics_command_list9_dispatch_rays((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  @dx12.dx_d3d12_graphics_command_list9_end_event((0 : UInt64))
  probed.val = probed.val + 1
  @dx12.dx_d3d12_graphics_command_list9_execute_meta_command((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : Int64))
  probed.val = probed.val + 1
  @dx12.dx_d3d12_graphics_command_list9_initialize_meta_command((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : Int64))
  probed.val = probed.val + 1
  @dx12.dx_d3d12_graphics_command_list9_set_predication((0 : UInt64), (0 : UInt64), (0 : Int64), 0)
  probed.val = probed.val + 1
  @dx12.dx_d3d12_graphics_command_list9_set_protected_resource_session((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
}

///|
fn tc_typecheck_d3d12_unreached_33(probed : Ref[Int]) -> Unit {
  @dx12.dx_d3d12_lifetime_owner_lifetime_state_updated((0 : UInt64), 0)
  probed.val = probed.val + 1
}

///|
fn tc_typecheck_d3d12_unreached_34(probed : Ref[Int]) -> Unit {
  let _ = @dx12.dx_d3d12_lifetime_tracker_destroy_owned_object((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_lifetime_tracker_get_device((0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_lifetime_tracker_get_private_data((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_lifetime_tracker_set_name((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_lifetime_tracker_set_private_data((0 : UInt64), (0 : UInt64), 0, (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_lifetime_tracker_set_private_data_interface((0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
}

///|
fn tc_typecheck_d3d12_unreached_35(probed : Ref[Int]) -> Unit {
  let _ = @dx12.dx_d3d12_meta_command_get_device((0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_meta_command_get_private_data((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_meta_command_get_required_parameter_resource_size((0 : UInt64), 0, 0)
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_meta_command_set_name((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_meta_command_set_private_data((0 : UInt64), (0 : UInt64), 0, (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_meta_command_set_private_data_interface((0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
}

///|
fn tc_typecheck_d3d12_unreached_36(probed : Ref[Int]) -> Unit {
  let _ = @dx12.dx_d3d12_pageable_tools_get_allocation((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
}

///|
fn tc_typecheck_d3d12_unreached_37(probed : Ref[Int]) -> Unit {
  let _ = @dx12.dx_d3d12_pipeline_library_load_compute_pipeline((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_pipeline_library_load_graphics_pipeline((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
}

///|
fn tc_typecheck_d3d12_unreached_38(probed : Ref[Int]) -> Unit {
  let _ = @dx12.dx_d3d12_pipeline_library1_load_graphics_pipeline((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_pipeline_library1_store_pipeline((0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
}

///|
fn tc_typecheck_d3d12_unreached_39(probed : Ref[Int]) -> Unit {
  let _ = @dx12.dx_d3d12_protected_resource_session_get_desc((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_protected_resource_session_get_device((0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_protected_resource_session_get_private_data((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_protected_resource_session_get_session_status((0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_protected_resource_session_get_status_fence((0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_protected_resource_session_set_name((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_protected_resource_session_set_private_data((0 : UInt64), (0 : UInt64), 0, (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_protected_resource_session_set_private_data_interface((0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
}

///|
fn tc_typecheck_d3d12_unreached_40(probed : Ref[Int]) -> Unit {
  let _ = @dx12.dx_d3d12_protected_resource_session1_get_desc((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_protected_resource_session1_get_desc1((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_protected_resource_session1_get_device((0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_protected_resource_session1_get_private_data((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_protected_resource_session1_get_session_status((0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_protected_resource_session1_get_status_fence((0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_protected_resource_session1_set_name((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_protected_resource_session1_set_private_data((0 : UInt64), (0 : UInt64), 0, (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_protected_resource_session1_set_private_data_interface((0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
}

///|
fn tc_typecheck_d3d12_unreached_41(probed : Ref[Int]) -> Unit {
  let _ = @dx12.dx_d3d12_protected_session_get_device((0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_protected_session_get_private_data((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_protected_session_get_session_status((0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_protected_session_get_status_fence((0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_protected_session_set_name((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_protected_session_set_private_data((0 : UInt64), (0 : UInt64), 0, (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_protected_session_set_private_data_interface((0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
}

///|
fn tc_typecheck_d3d12_unreached_42(probed : Ref[Int]) -> Unit {
  let _ = @dx12.dx_d3d12_resource_read_from_subresource((0 : UInt64), (0 : UInt64), 0, 0, 0, (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_resource_write_to_subresource((0 : UInt64), 0, (0 : UInt64), (0 : UInt64), 0, 0)
  probed.val = probed.val + 1
}

///|
fn tc_typecheck_d3d12_unreached_43(probed : Ref[Int]) -> Unit {
  let _ = @dx12.dx_d3d12_resource1_read_from_subresource((0 : UInt64), (0 : UInt64), 0, 0, 0, (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_resource1_write_to_subresource((0 : UInt64), 0, (0 : UInt64), (0 : UInt64), 0, 0)
  probed.val = probed.val + 1
}

///|
fn tc_typecheck_d3d12_unreached_44(probed : Ref[Int]) -> Unit {
  let _ = @dx12.dx_d3d12_resource2_read_from_subresource((0 : UInt64), (0 : UInt64), 0, 0, 0, (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_resource2_write_to_subresource((0 : UInt64), 0, (0 : UInt64), (0 : UInt64), 0, 0)
  probed.val = probed.val + 1
}

///|
fn tc_typecheck_d3d12_unreached_45(probed : Ref[Int]) -> Unit {
  let _ = @dx12.dx_d3d12_sdk_configuration_set_sdk_version((0 : UInt64), 0, (0 : UInt64))
  probed.val = probed.val + 1
}

///|
fn tc_typecheck_d3d12_unreached_46(probed : Ref[Int]) -> Unit {
  let _ = @dx12.dx_d3d12_sdk_configuration1_create_device_factory((0 : UInt64), 0, (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_sdk_configuration1_set_sdk_version((0 : UInt64), 0, (0 : UInt64))
  probed.val = probed.val + 1
}

///|
fn tc_typecheck_d3d12_unreached_47(probed : Ref[Int]) -> Unit {
  let _ = @dx12.dx_d3d12_state_object_properties1_get_program_identifier((0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
}

///|
fn tc_typecheck_d3d12_unreached_48(probed : Ref[Int]) -> Unit {
  let _ = @dx12.dx_d3d12_swap_chain_assistant_get_current_resource_and_command_queue((0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_swap_chain_assistant_get_luid((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_swap_chain_assistant_get_swap_chain_object((0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_swap_chain_assistant_insert_implicit_sync((0 : UInt64))
  probed.val = probed.val + 1
}

///|
fn tc_typecheck_d3d12_unreached_49(probed : Ref[Int]) -> Unit {
  let _ = @dx12.dx_d3d12_tools1_reserve_gpuva_ranges_at_create((0 : UInt64), (0 : UInt64), 0)
  probed.val = probed.val + 1
}

///|
fn tc_typecheck_d3d12_unreached_50(probed : Ref[Int]) -> Unit {
  let _ = @dx12.dx_d3d12_tools2_reserve_gpuva_ranges_at_create((0 : UInt64), (0 : UInt64), 0)
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_tools2_set_application_specific_driver_state((0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
}

///|
fn tc_typecheck_d3d12_unreached_51(probed : Ref[Int]) -> Unit {
  let _ = @dx12.dx_d3d12_virtualization_guest_device_create_fence_fd((0 : UInt64), (0 : UInt64), (0 : Int64), (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_virtualization_guest_device_share_with_host((0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
}

///|
fn tc_typecheck_d3d12_unreached_52(probed : Ref[Int]) -> Unit {
  let _ = @dx12.dx_d3d12_work_graph_properties_get_entrypoint_id((0 : UInt64), (0 : UInt64), 0, 0)
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_work_graph_properties_get_entrypoint_index((0 : UInt64), 0, (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_work_graph_properties_get_entrypoint_record_alignment_in_bytes((0 : UInt64), 0, 0)
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_work_graph_properties_get_entrypoint_record_size_in_bytes((0 : UInt64), 0, 0)
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_work_graph_properties_get_node_id((0 : UInt64), (0 : UInt64), 0, 0)
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_work_graph_properties_get_node_index((0 : UInt64), 0, (0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_work_graph_properties_get_node_local_root_arguments_table_index((0 : UInt64), 0, 0)
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_work_graph_properties_get_num_entrypoints((0 : UInt64), 0)
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_work_graph_properties_get_num_nodes((0 : UInt64), 0)
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_work_graph_properties_get_num_work_graphs((0 : UInt64))
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_work_graph_properties_get_program_name((0 : UInt64), 0)
  probed.val = probed.val + 1
  let _ = @dx12.dx_d3d12_work_graph_properties_get_work_graph_index((0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
  @dx12.dx_d3d12_work_graph_properties_get_work_graph_memory_requirements((0 : UInt64), 0, (0 : UInt64))
  probed.val = probed.val + 1
}

///|
fn typecheck_d3d12_unreached(probed : Ref[Int]) -> Unit {
  tc_typecheck_d3d12_unreached_0(probed)
  tc_typecheck_d3d12_unreached_1(probed)
  tc_typecheck_d3d12_unreached_2(probed)
  tc_typecheck_d3d12_unreached_3(probed)
  tc_typecheck_d3d12_unreached_4(probed)
  tc_typecheck_d3d12_unreached_5(probed)
  tc_typecheck_d3d12_unreached_6(probed)
  tc_typecheck_d3d12_unreached_7(probed)
  tc_typecheck_d3d12_unreached_8(probed)
  tc_typecheck_d3d12_unreached_9(probed)
  tc_typecheck_d3d12_unreached_10(probed)
  tc_typecheck_d3d12_unreached_11(probed)
  tc_typecheck_d3d12_unreached_12(probed)
  tc_typecheck_d3d12_unreached_13(probed)
  tc_typecheck_d3d12_unreached_14(probed)
  tc_typecheck_d3d12_unreached_15(probed)
  tc_typecheck_d3d12_unreached_16(probed)
  tc_typecheck_d3d12_unreached_17(probed)
  tc_typecheck_d3d12_unreached_18(probed)
  tc_typecheck_d3d12_unreached_19(probed)
  tc_typecheck_d3d12_unreached_20(probed)
  tc_typecheck_d3d12_unreached_21(probed)
  tc_typecheck_d3d12_unreached_22(probed)
  tc_typecheck_d3d12_unreached_23(probed)
  tc_typecheck_d3d12_unreached_24(probed)
  tc_typecheck_d3d12_unreached_25(probed)
  tc_typecheck_d3d12_unreached_26(probed)
  tc_typecheck_d3d12_unreached_27(probed)
  tc_typecheck_d3d12_unreached_28(probed)
  tc_typecheck_d3d12_unreached_29(probed)
  tc_typecheck_d3d12_unreached_30(probed)
  tc_typecheck_d3d12_unreached_31(probed)
  tc_typecheck_d3d12_unreached_32(probed)
  tc_typecheck_d3d12_unreached_33(probed)
  tc_typecheck_d3d12_unreached_34(probed)
  tc_typecheck_d3d12_unreached_35(probed)
  tc_typecheck_d3d12_unreached_36(probed)
  tc_typecheck_d3d12_unreached_37(probed)
  tc_typecheck_d3d12_unreached_38(probed)
  tc_typecheck_d3d12_unreached_39(probed)
  tc_typecheck_d3d12_unreached_40(probed)
  tc_typecheck_d3d12_unreached_41(probed)
  tc_typecheck_d3d12_unreached_42(probed)
  tc_typecheck_d3d12_unreached_43(probed)
  tc_typecheck_d3d12_unreached_44(probed)
  tc_typecheck_d3d12_unreached_45(probed)
  tc_typecheck_d3d12_unreached_46(probed)
  tc_typecheck_d3d12_unreached_47(probed)
  tc_typecheck_d3d12_unreached_48(probed)
  tc_typecheck_d3d12_unreached_49(probed)
  tc_typecheck_d3d12_unreached_50(probed)
  tc_typecheck_d3d12_unreached_51(probed)
  tc_typecheck_d3d12_unreached_52(probed)
  let _ = @dx12.d3d12_create_versioned_root_signature_deserializer_from_subobject_in_library((0 : UInt64), (0 : Int64), (0 : UInt64), (0 : UInt64), (0 : UInt64))
  probed.val = probed.val + 1
}
