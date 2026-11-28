// Generated-dispatch verification of D3D12 singleton and configuration interfaces.

///|
fn probe_singletons(
  raw_dev : UInt64,
  rs_desc_v11 : UInt64,
  rs_bytes : UInt64,
  rs_len : Int64,
  scratch : UInt64,
  out_ptr : UInt64,
  probed : Ref[Int],
) -> Unit {
  // 1. DRED Settings (0..2) via D3D12GetInterface(CLSID_D3D12DeviceRemovedExtendedData)
  @dx12.write_u64(out_ptr, 0, (0 : UInt64))
  if @dx12.d3d12_get_interface(
      @dx12.bytes_ptr(@dx12.clsid_d3_d12_device_removed_extended_data),
      @dx12.bytes_ptr(@dx12.iid_d3d12_device_removed_extended_data_settings),
      out_ptr,
    ) == 0 {
    let s0 = @dx12.read_u64(out_ptr, 0)
    if s0 != (0 : UInt64) {
      @dx12.dx_d3d12_device_removed_extended_data_settings_set_auto_breadcrumbs_enablement(s0, 0)
      @dx12.dx_d3d12_device_removed_extended_data_settings_set_page_fault_enablement(s0, 0)
      @dx12.dx_d3d12_device_removed_extended_data_settings_set_watson_dump_enablement(s0, 0)
      probed.val = probed.val + 3

      @dx12.write_u64(out_ptr, 0, (0 : UInt64))
      if @dx12.com_query_interface(s0, @dx12.bytes_ptr(@dx12.iid_d3d12_device_removed_extended_data_settings1), out_ptr) == 0 {
        let s1 = @dx12.read_u64(out_ptr, 0)
        if s1 != (0 : UInt64) {
          @dx12.dx_d3d12_device_removed_extended_data_settings1_set_auto_breadcrumbs_enablement(s1, 0)
          @dx12.dx_d3d12_device_removed_extended_data_settings1_set_page_fault_enablement(s1, 0)
          @dx12.dx_d3d12_device_removed_extended_data_settings1_set_watson_dump_enablement(s1, 0)
          @dx12.dx_d3d12_device_removed_extended_data_settings1_set_breadcrumb_context_enablement(s1, 0)
          let _ = @dx12.com_release(s1)
          probed.val = probed.val + 4
        }
      }

      @dx12.write_u64(out_ptr, 0, (0 : UInt64))
      if @dx12.com_query_interface(s0, @dx12.bytes_ptr(@dx12.iid_d3d12_device_removed_extended_data_settings2), out_ptr) == 0 {
        let s2 = @dx12.read_u64(out_ptr, 0)
        if s2 != (0 : UInt64) {
          @dx12.dx_d3d12_device_removed_extended_data_settings2_set_auto_breadcrumbs_enablement(s2, 0)
          @dx12.dx_d3d12_device_removed_extended_data_settings2_set_page_fault_enablement(s2, 0)
          @dx12.dx_d3d12_device_removed_extended_data_settings2_set_watson_dump_enablement(s2, 0)
          @dx12.dx_d3d12_device_removed_extended_data_settings2_set_breadcrumb_context_enablement(s2, 0)
          @dx12.dx_d3d12_device_removed_extended_data_settings2_use_markers_only_auto_breadcrumbs(s2, 0)
          let _ = @dx12.com_release(s2)
          probed.val = probed.val + 5
        }
      }
      let _ = @dx12.com_release(s0)
    }
  }

  // 2. DRED output (0..2) via QI on device
  @dx12.write_u64(out_ptr, 0, (0 : UInt64))
  if @dx12.com_query_interface(raw_dev, @dx12.bytes_ptr(@dx12.iid_d3d12_device_removed_extended_data), out_ptr) == 0 {
    let d0 = @dx12.read_u64(out_ptr, 0)
    if d0 != (0 : UInt64) {
      let _ = @dx12.dx_d3d12_device_removed_extended_data_get_auto_breadcrumbs_output(d0, scratch)
      let _ = @dx12.dx_d3d12_device_removed_extended_data_get_page_fault_allocation_output(d0, scratch)
      let _ = @dx12.com_release(d0)
      probed.val = probed.val + 2
    }
  }
  @dx12.write_u64(out_ptr, 0, (0 : UInt64))
  if @dx12.com_query_interface(raw_dev, @dx12.bytes_ptr(@dx12.iid_d3d12_device_removed_extended_data1), out_ptr) == 0 {
    let d1 = @dx12.read_u64(out_ptr, 0)
    if d1 != (0 : UInt64) {
      let _ = @dx12.dx_d3d12_device_removed_extended_data1_get_auto_breadcrumbs_output(d1, scratch)
      let _ = @dx12.dx_d3d12_device_removed_extended_data1_get_page_fault_allocation_output(d1, scratch)
      let _ = @dx12.dx_d3d12_device_removed_extended_data1_get_auto_breadcrumbs_output1(d1, scratch)
      let _ = @dx12.dx_d3d12_device_removed_extended_data1_get_page_fault_allocation_output1(d1, scratch)
      let _ = @dx12.com_release(d1)
      probed.val = probed.val + 4
    }
  }
  @dx12.write_u64(out_ptr, 0, (0 : UInt64))
  if @dx12.com_query_interface(raw_dev, @dx12.bytes_ptr(@dx12.iid_d3d12_device_removed_extended_data2), out_ptr) == 0 {
    let d2 = @dx12.read_u64(out_ptr, 0)
    if d2 != (0 : UInt64) {
      let _ = @dx12.dx_d3d12_device_removed_extended_data2_get_auto_breadcrumbs_output(d2, scratch)
      let _ = @dx12.dx_d3d12_device_removed_extended_data2_get_page_fault_allocation_output(d2, scratch)
      let _ = @dx12.dx_d3d12_device_removed_extended_data2_get_auto_breadcrumbs_output1(d2, scratch)
      let _ = @dx12.dx_d3d12_device_removed_extended_data2_get_page_fault_allocation_output1(d2, scratch)
      let _ = @dx12.dx_d3d12_device_removed_extended_data2_get_page_fault_allocation_output2(d2, scratch)
      let _ = @dx12.dx_d3d12_device_removed_extended_data2_get_device_state(d2)
      let _ = @dx12.com_release(d2)
      probed.val = probed.val + 6
    }
  }

  // 3. ID3D12Tools0..2
  @dx12.write_u64(out_ptr, 0, (0 : UInt64))
  if @dx12.d3d12_get_interface(
      @dx12.bytes_ptr(@dx12.clsid_d3_d12_tools),
      @dx12.bytes_ptr(@dx12.iid_d3d12_tools),
      out_ptr,
    ) == 0 {
    let t0 = @dx12.read_u64(out_ptr, 0)
    if t0 != (0 : UInt64) {
      let _ = @dx12.dx_d3d12_tools_shader_instrumentation_enabled(t0)
      @dx12.dx_d3d12_tools_enable_shader_instrumentation(t0, 0)
      probed.val = probed.val + 2

      @dx12.write_u64(out_ptr, 0, (0 : UInt64))
      if @dx12.com_query_interface(t0, @dx12.bytes_ptr(@dx12.iid_d3d12_tools1), out_ptr) == 0 {
        let t1 = @dx12.read_u64(out_ptr, 0)
        if t1 != (0 : UInt64) {
          let _ = @dx12.dx_d3d12_tools1_shader_instrumentation_enabled(t1)
          @dx12.dx_d3d12_tools1_enable_shader_instrumentation(t1, 0)
          @dx12.dx_d3d12_tools1_clear_reserved_gpuva_ranges_list(t1)
          let _ = @dx12.com_release(t1)
          probed.val = probed.val + 3
        }
      }
      @dx12.write_u64(out_ptr, 0, (0 : UInt64))
      if @dx12.com_query_interface(t0, @dx12.bytes_ptr(@dx12.iid_d3d12_tools2), out_ptr) == 0 {
        let t2 = @dx12.read_u64(out_ptr, 0)
        if t2 != (0 : UInt64) {
          let _ = @dx12.dx_d3d12_tools2_shader_instrumentation_enabled(t2)
          @dx12.dx_d3d12_tools2_enable_shader_instrumentation(t2, 0)
          @dx12.dx_d3d12_tools2_clear_reserved_gpuva_ranges_list(t2)
          let _ = @dx12.com_release(t2)
          probed.val = probed.val + 3
        }
      }
      let _ = @dx12.com_release(t0)
    }
  }

  // 4. ID3D12SDKConfiguration1
  @dx12.write_u64(out_ptr, 0, (0 : UInt64))
  if @dx12.d3d12_get_interface(
      @dx12.bytes_ptr(@dx12.clsid_d3_d12_sdk_configuration),
      @dx12.bytes_ptr(@dx12.iid_d3d12_sdk_configuration1),
      out_ptr,
    ) == 0 {
    let sdk1 = @dx12.read_u64(out_ptr, 0)
    if sdk1 != (0 : UInt64) {
      @dx12.dx_d3d12_sdk_configuration1_free_unused_sd_ks(sdk1)
      let _ = @dx12.com_release(sdk1)
      probed.val = probed.val + 1
    }
  }

  // 5. ID3D12DeviceFactory + ID3D12DeviceConfiguration0..1
  @dx12.write_u64(out_ptr, 0, (0 : UInt64))
  if @dx12.d3d12_get_interface(
      @dx12.bytes_ptr(@dx12.clsid_d3_d12_device_factory),
      @dx12.bytes_ptr(@dx12.iid_d3d12_device_factory),
      out_ptr,
    ) == 0 {
    let df = @dx12.read_u64(out_ptr, 0)
    if df != (0 : UInt64) {
      let _ = @dx12.dx_d3d12_device_factory_get_flags(df)
      @dx12.write_u64(out_ptr, 0, (0 : UInt64))
      if @dx12.dx_d3d12_device_factory_get_configuration_interface(
          df,
          @dx12.bytes_ptr(@dx12.clsid_d3_d12_debug),
          @dx12.bytes_ptr(@dx12.iid_iunknown),
          out_ptr,
        ) == 0 {
        let _ = @dx12.com_release(@dx12.read_u64(out_ptr, 0))
      }
      probed.val = probed.val + 2

      @dx12.write_u64(out_ptr, 0, (0 : UInt64))
      if @dx12.com_query_interface(df, @dx12.bytes_ptr(@dx12.iid_d3d12_device_configuration), out_ptr) == 0 {
        let dc = @dx12.read_u64(out_ptr, 0)
        if dc != (0 : UInt64) {
          let _ = @dx12.dx_d3d12_device_configuration_get_desc(dc, scratch)
          let _ = @dx12.dx_d3d12_device_configuration_get_enabled_experimental_features(dc, scratch + (64 : UInt64), 0)
          let b_out = scratch + (256 : UInt64)
          let e_out = scratch + (264 : UInt64)
          @dx12.write_u64(b_out, 0, (0 : UInt64))
          @dx12.write_u64(e_out, 0, (0 : UInt64))
          if @dx12.dx_d3d12_device_configuration_serialize_versioned_root_signature(dc, rs_desc_v11, b_out, e_out) == 0 {
            let b = @dx12.read_u64(b_out, 0)
            if b != (0 : UInt64) { let _ = @dx12.com_release(b) }
          }
          if @dx12.read_u64(e_out, 0) != (0 : UInt64) { let _ = @dx12.com_release(@dx12.read_u64(e_out, 0)) }
          @dx12.write_u64(out_ptr, 0, (0 : UInt64))
          if @dx12.dx_d3d12_device_configuration_create_versioned_root_signature_deserializer(
              dc, rs_bytes, rs_len, @dx12.bytes_ptr(@dx12.iid_d3d12_versioned_root_signature_deserializer), out_ptr,
            ) == 0 {
            let _ = @dx12.com_release(@dx12.read_u64(out_ptr, 0))
          }
          let _ = @dx12.com_release(dc)
          probed.val = probed.val + 4
        }
      }

      @dx12.write_u64(out_ptr, 0, (0 : UInt64))
      if @dx12.com_query_interface(df, @dx12.bytes_ptr(@dx12.iid_d3d12_device_configuration1), out_ptr) == 0 {
        let dc1 = @dx12.read_u64(out_ptr, 0)
        if dc1 != (0 : UInt64) {
          let _ = @dx12.dx_d3d12_device_configuration1_get_desc(dc1, scratch)
          let _ = @dx12.dx_d3d12_device_configuration1_get_enabled_experimental_features(dc1, scratch + (64 : UInt64), 0)
          let b_out = scratch + (256 : UInt64)
          let e_out = scratch + (264 : UInt64)
          @dx12.write_u64(b_out, 0, (0 : UInt64))
          @dx12.write_u64(e_out, 0, (0 : UInt64))
          if @dx12.dx_d3d12_device_configuration1_serialize_versioned_root_signature(dc1, rs_desc_v11, b_out, e_out) == 0 {
            let b = @dx12.read_u64(b_out, 0)
            if b != (0 : UInt64) { let _ = @dx12.com_release(b) }
          }
          if @dx12.read_u64(e_out, 0) != (0 : UInt64) { let _ = @dx12.com_release(@dx12.read_u64(e_out, 0)) }
          @dx12.write_u64(out_ptr, 0, (0 : UInt64))
          if @dx12.dx_d3d12_device_configuration1_create_versioned_root_signature_deserializer(
              dc1, rs_bytes, rs_len, @dx12.bytes_ptr(@dx12.iid_d3d12_versioned_root_signature_deserializer), out_ptr,
            ) == 0 {
            let _ = @dx12.com_release(@dx12.read_u64(out_ptr, 0))
          }
          let _ = @dx12.com_release(dc1)
          probed.val = probed.val + 4
        }
      }

      let _ = @dx12.com_release(df)
    }
  }

  // 6. ID3D12DeviceTools0..1 (optional)
  @dx12.write_u64(out_ptr, 0, (0 : UInt64))
  if @dx12.com_query_interface(raw_dev, @dx12.bytes_ptr(@dx12.iid_d3d12_device_tools), out_ptr) == 0 {
    let dt0 = @dx12.read_u64(out_ptr, 0)
    if dt0 != (0 : UInt64) {
      let _ = @dx12.com_release(dt0)
    }
  }
  @dx12.write_u64(out_ptr, 0, (0 : UInt64))
  if @dx12.com_query_interface(raw_dev, @dx12.bytes_ptr(@dx12.iid_d3d12_device_tools1), out_ptr) == 0 {
    let dt1 = @dx12.read_u64(out_ptr, 0)
    if dt1 != (0 : UInt64) {
      let _ = @dx12.com_release(dt1)
    }
  }
}
