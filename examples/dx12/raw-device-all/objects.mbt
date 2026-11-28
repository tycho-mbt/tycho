// Generated-dispatch verification of core D3D12 object and resource interfaces.

///|
fn probe_objects(ctx : DeviceCtx, queue : UInt64, rs_blob_obj : UInt64, lib_pso : UInt64) -> Unit {
  let out = ctx.out_ptr
  let sc = ctx.scratch
  let p = ctx.probed

  // 1. ID3D12Object + ID3DDestructionNotifier on fence
  let _ = @dx12.dx_d3d12_object_set_private_data(ctx.fence, ctx.priv_guid, 4, ctx.priv_val)
  @dx12.write_u32(ctx.priv_sz, 0, (4 : UInt32))
  let _ = @dx12.dx_d3d12_object_get_private_data(ctx.fence, ctx.priv_guid, ctx.priv_sz, sc)
  let _ = @dx12.dx_d3d12_object_set_private_data_interface(ctx.fence, ctx.priv_guid, (0 : UInt64))
  let _ = @dx12.dx_d3d12_object_set_name(ctx.fence, ctx.name_w)
  p.val = p.val + 4

  @dx12.write_u64(out, 0, (0 : UInt64))
  if @dx12.com_query_interface(ctx.fence, @dx12.bytes_ptr(@dx12.iid_id3_d_destruction_notifier), out) == 0 {
    let dn = @dx12.read_u64(out, 0)
    if dn != (0 : UInt64) {
      let cb_id = sc + (64 : UInt64)
      @dx12.write_u32(cb_id, 0, (0 : UInt32))
      // Register with null fn fails cleanly with E_INVALIDARG; keep safe & unregister 0
      let _ = @dx12.dx_id3_d_destruction_notifier_register_destruction_callback(dn, (0 : UInt64), (0 : UInt64), cb_id)
      let _ = @dx12.dx_id3_d_destruction_notifier_unregister_destruction_callback(dn, 0)
      let _ = @dx12.com_release(dn)
      p.val = p.val + 2
    }
  }

  // 2. ID3D12DeviceChild + ID3D12Pageable on heap_obj
  let _ = @dx12.dx_d3d12_device_child_set_private_data(ctx.heap_obj, ctx.priv_guid, 4, ctx.priv_val)
  @dx12.write_u32(ctx.priv_sz, 0, (4 : UInt32))
  let _ = @dx12.dx_d3d12_device_child_get_private_data(ctx.heap_obj, ctx.priv_guid, ctx.priv_sz, sc)
  let _ = @dx12.dx_d3d12_device_child_set_private_data_interface(ctx.heap_obj, ctx.priv_guid, (0 : UInt64))
  let _ = @dx12.dx_d3d12_device_child_set_name(ctx.heap_obj, ctx.name_w)
  @dx12.write_u64(out, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device_child_get_device(ctx.heap_obj, @dx12.bytes_ptr(@dx12.iid_d3d12_device), out) == 0 {
    let _ = @dx12.com_release(@dx12.read_u64(out, 0))
  }
  let _ = @dx12.dx_d3d12_pageable_set_private_data(ctx.heap_obj, ctx.priv_guid, 4, ctx.priv_val)
  @dx12.write_u32(ctx.priv_sz, 0, (4 : UInt32))
  let _ = @dx12.dx_d3d12_pageable_get_private_data(ctx.heap_obj, ctx.priv_guid, ctx.priv_sz, sc)
  let _ = @dx12.dx_d3d12_pageable_set_private_data_interface(ctx.heap_obj, ctx.priv_guid, (0 : UInt64))
  let _ = @dx12.dx_d3d12_pageable_set_name(ctx.heap_obj, ctx.name_w)
  @dx12.write_u64(out, 0, (0 : UInt64))
  if @dx12.dx_d3d12_pageable_get_device(ctx.heap_obj, @dx12.bytes_ptr(@dx12.iid_d3d12_device), out) == 0 {
    let _ = @dx12.com_release(@dx12.read_u64(out, 0))
  }
  p.val = p.val + 10

  // 3. ID3D12Heap0..1
  let _ = @dx12.dx_d3d12_heap_set_private_data(ctx.heap_obj, ctx.priv_guid, 4, ctx.priv_val)
  @dx12.write_u32(ctx.priv_sz, 0, (4 : UInt32))
  let _ = @dx12.dx_d3d12_heap_get_private_data(ctx.heap_obj, ctx.priv_guid, ctx.priv_sz, sc)
  let _ = @dx12.dx_d3d12_heap_set_private_data_interface(ctx.heap_obj, ctx.priv_guid, (0 : UInt64))
  let _ = @dx12.dx_d3d12_heap_set_name(ctx.heap_obj, ctx.name_w)
  @dx12.write_u64(out, 0, (0 : UInt64))
  if @dx12.dx_d3d12_heap_get_device(ctx.heap_obj, @dx12.bytes_ptr(@dx12.iid_d3d12_device), out) == 0 {
    let _ = @dx12.com_release(@dx12.read_u64(out, 0))
  }
  let _ = @dx12.dx_d3d12_heap_get_desc(ctx.heap_obj, sc)
  p.val = p.val + 6

  @dx12.write_u64(out, 0, (0 : UInt64))
  if @dx12.com_query_interface(ctx.heap_obj, @dx12.bytes_ptr(@dx12.iid_d3d12_heap1), out) == 0 {
    let h1 = @dx12.read_u64(out, 0)
    if h1 != (0 : UInt64) {
      let _ = @dx12.dx_d3d12_heap1_set_private_data(h1, ctx.priv_guid, 4, ctx.priv_val)
      @dx12.write_u32(ctx.priv_sz, 0, (4 : UInt32))
      let _ = @dx12.dx_d3d12_heap1_get_private_data(h1, ctx.priv_guid, ctx.priv_sz, sc)
      let _ = @dx12.dx_d3d12_heap1_set_private_data_interface(h1, ctx.priv_guid, (0 : UInt64))
      let _ = @dx12.dx_d3d12_heap1_set_name(h1, ctx.name_w)
      @dx12.write_u64(out, 0, (0 : UInt64))
      if @dx12.dx_d3d12_heap1_get_device(h1, @dx12.bytes_ptr(@dx12.iid_d3d12_device), out) == 0 {
        let _ = @dx12.com_release(@dx12.read_u64(out, 0))
      }
      let _ = @dx12.dx_d3d12_heap1_get_desc(h1, sc)
      @dx12.write_u64(out, 0, (0 : UInt64))
      let _ = @dx12.dx_d3d12_heap1_get_protected_resource_session(h1, @dx12.bytes_ptr(@dx12.iid_d3d12_protected_resource_session), out)
      let _ = @dx12.com_release(h1)
      p.val = p.val + 7
    }
  }

  // 4. ID3D12Resource0..2 on an UPLOAD buffer (for Map/Unmap) + buf_def
  let upload_props = sc
  @dx12.write_u32(upload_props, 0, (2 : UInt32)) // UPLOAD
  @dx12.write_u32(upload_props, 4, (0 : UInt32))
  @dx12.write_u32(upload_props, 8, (0 : UInt32))
  @dx12.write_u32(upload_props, 12, (1 : UInt32))
  @dx12.write_u32(upload_props, 16, (1 : UInt32))
  let up_desc = sc + (64 : UInt64)
  @dx12.write_u32(up_desc, 0, (1 : UInt32)) // BUFFER
  @dx12.write_u64(up_desc, 8, (0 : UInt64))
  @dx12.write_u64(up_desc, 16, (4096 : UInt64))
  @dx12.write_u32(up_desc, 24, (1 : UInt32))
  @dx12.write_u32(up_desc, 28, (0x00010001 : UInt32))
  @dx12.write_u32(up_desc, 32, (0 : UInt32))
  @dx12.write_u32(up_desc, 36, (1 : UInt32))
  @dx12.write_u32(up_desc, 40, (0 : UInt32))
  @dx12.write_u32(up_desc, 44, (1 : UInt32)) // ROW_MAJOR
  @dx12.write_u32(up_desc, 48, (0 : UInt32)) // Flags = 0

  @dx12.write_u64(out, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device_create_committed_resource(
      ctx.raw_dev, upload_props, 0, up_desc, 0x1 | 0x2 | 0x40 | 0x80 | 0x200 | 0x800, // GENERIC_READ (0xAC3? wait: GENERIC_READ = 0x1|0x2|0x40|0x80|0x200|0x800 = 0xAC3! Or 2755)
      (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), out,
    ) == 0 {
    let r0 = @dx12.read_u64(out, 0)
    if r0 != (0 : UInt64) {
      let _ = @dx12.dx_d3d12_resource_set_private_data(r0, ctx.priv_guid, 4, ctx.priv_val)
      @dx12.write_u32(ctx.priv_sz, 0, (4 : UInt32))
      let _ = @dx12.dx_d3d12_resource_get_private_data(r0, ctx.priv_guid, ctx.priv_sz, sc + (256 : UInt64))
      let _ = @dx12.dx_d3d12_resource_set_private_data_interface(r0, ctx.priv_guid, (0 : UInt64))
      let _ = @dx12.dx_d3d12_resource_set_name(r0, ctx.name_w)
      @dx12.write_u64(out, 0, (0 : UInt64))
      if @dx12.dx_d3d12_resource_get_device(r0, @dx12.bytes_ptr(@dx12.iid_d3d12_device), out) == 0 {
        let _ = @dx12.com_release(@dx12.read_u64(out, 0))
      }
      let _ = @dx12.dx_d3d12_resource_get_desc(r0, sc + (256 : UInt64))
      let _ = @dx12.dx_d3d12_resource_get_gpu_virtual_address(r0)
      let _ = @dx12.dx_d3d12_resource_get_heap_properties(r0, sc + (512 : UInt64), sc + (544 : UInt64))
      @dx12.write_u64(out, 0, (0 : UInt64))
      if @dx12.dx_d3d12_resource_map(r0, 0, (0 : UInt64), out) == 0 {
        @dx12.dx_d3d12_resource_unmap(r0, 0, (0 : UInt64))
      }
      p.val = p.val + 10

      @dx12.write_u64(out, 0, (0 : UInt64))
      if @dx12.com_query_interface(r0, @dx12.bytes_ptr(@dx12.iid_d3d12_resource1), out) == 0 {
        let r1 = @dx12.read_u64(out, 0)
        if r1 != (0 : UInt64) {
          let _ = @dx12.dx_d3d12_resource1_set_private_data(r1, ctx.priv_guid, 4, ctx.priv_val)
          @dx12.write_u32(ctx.priv_sz, 0, (4 : UInt32))
          let _ = @dx12.dx_d3d12_resource1_get_private_data(r1, ctx.priv_guid, ctx.priv_sz, sc + (256 : UInt64))
          let _ = @dx12.dx_d3d12_resource1_set_private_data_interface(r1, ctx.priv_guid, (0 : UInt64))
          let _ = @dx12.dx_d3d12_resource1_set_name(r1, ctx.name_w)
          @dx12.write_u64(out, 0, (0 : UInt64))
          if @dx12.dx_d3d12_resource1_get_device(r1, @dx12.bytes_ptr(@dx12.iid_d3d12_device), out) == 0 {
            let _ = @dx12.com_release(@dx12.read_u64(out, 0))
          }
          let _ = @dx12.dx_d3d12_resource1_get_desc(r1, sc + (256 : UInt64))
          let _ = @dx12.dx_d3d12_resource1_get_gpu_virtual_address(r1)
          let _ = @dx12.dx_d3d12_resource1_get_heap_properties(r1, sc + (512 : UInt64), sc + (544 : UInt64))
          @dx12.write_u64(out, 0, (0 : UInt64))
          let _ = @dx12.dx_d3d12_resource1_get_protected_resource_session(r1, @dx12.bytes_ptr(@dx12.iid_d3d12_protected_resource_session), out)
          @dx12.write_u64(out, 0, (0 : UInt64))
          if @dx12.dx_d3d12_resource1_map(r1, 0, (0 : UInt64), out) == 0 {
            @dx12.dx_d3d12_resource1_unmap(r1, 0, (0 : UInt64))
          }
          let _ = @dx12.com_release(r1)
          p.val = p.val + 11
        }
      }

      @dx12.write_u64(out, 0, (0 : UInt64))
      if @dx12.com_query_interface(r0, @dx12.bytes_ptr(@dx12.iid_d3d12_resource2), out) == 0 {
        let r2 = @dx12.read_u64(out, 0)
        if r2 != (0 : UInt64) {
          let _ = @dx12.dx_d3d12_resource2_set_private_data(r2, ctx.priv_guid, 4, ctx.priv_val)
          @dx12.write_u32(ctx.priv_sz, 0, (4 : UInt32))
          let _ = @dx12.dx_d3d12_resource2_get_private_data(r2, ctx.priv_guid, ctx.priv_sz, sc + (256 : UInt64))
          let _ = @dx12.dx_d3d12_resource2_set_private_data_interface(r2, ctx.priv_guid, (0 : UInt64))
          let _ = @dx12.dx_d3d12_resource2_set_name(r2, ctx.name_w)
          @dx12.write_u64(out, 0, (0 : UInt64))
          if @dx12.dx_d3d12_resource2_get_device(r2, @dx12.bytes_ptr(@dx12.iid_d3d12_device), out) == 0 {
            let _ = @dx12.com_release(@dx12.read_u64(out, 0))
          }
          let _ = @dx12.dx_d3d12_resource2_get_desc(r2, sc + (256 : UInt64))
          let _ = @dx12.dx_d3d12_resource2_get_desc1(r2, sc + (256 : UInt64))
          let _ = @dx12.dx_d3d12_resource2_get_gpu_virtual_address(r2)
          let _ = @dx12.dx_d3d12_resource2_get_heap_properties(r2, sc + (512 : UInt64), sc + (544 : UInt64))
          @dx12.write_u64(out, 0, (0 : UInt64))
          let _ = @dx12.dx_d3d12_resource2_get_protected_resource_session(r2, @dx12.bytes_ptr(@dx12.iid_d3d12_protected_resource_session), out)
          @dx12.write_u64(out, 0, (0 : UInt64))
          if @dx12.dx_d3d12_resource2_map(r2, 0, (0 : UInt64), out) == 0 {
            @dx12.dx_d3d12_resource2_unmap(r2, 0, (0 : UInt64))
          }
          let _ = @dx12.com_release(r2)
          p.val = p.val + 12
        }
      }
      let _ = @dx12.com_release(r0)
    }
  }

  // 5. ID3D12Fence0..1
  let _ = @dx12.dx_d3d12_fence_set_private_data(ctx.fence, ctx.priv_guid, 4, ctx.priv_val)
  @dx12.write_u32(ctx.priv_sz, 0, (4 : UInt32))
  let _ = @dx12.dx_d3d12_fence_get_private_data(ctx.fence, ctx.priv_guid, ctx.priv_sz, sc)
  let _ = @dx12.dx_d3d12_fence_set_private_data_interface(ctx.fence, ctx.priv_guid, (0 : UInt64))
  let _ = @dx12.dx_d3d12_fence_set_name(ctx.fence, ctx.name_w)
  @dx12.write_u64(out, 0, (0 : UInt64))
  if @dx12.dx_d3d12_fence_get_device(ctx.fence, @dx12.bytes_ptr(@dx12.iid_d3d12_device), out) == 0 {
    let _ = @dx12.com_release(@dx12.read_u64(out, 0))
  }
  ctx.fence_seq = ctx.fence_seq + (1 : Int64)
  let _ = @dx12.dx_d3d12_fence_signal(ctx.fence, ctx.fence_seq)
  let _ = @dx12.dx_d3d12_fence_get_completed_value(ctx.fence)
  let _ = @dx12.dx_d3d12_fence_set_event_on_completion(ctx.fence, ctx.fence_seq, ctx.ev)
  let _ = @dx12.wait_event(ctx.ev, 1000)
  p.val = p.val + 8

  @dx12.write_u64(out, 0, (0 : UInt64))
  if @dx12.com_query_interface(ctx.fence, @dx12.bytes_ptr(@dx12.iid_d3d12_fence1), out) == 0 {
    let f1 = @dx12.read_u64(out, 0)
    if f1 != (0 : UInt64) {
      let _ = @dx12.dx_d3d12_fence1_set_private_data(f1, ctx.priv_guid, 4, ctx.priv_val)
      @dx12.write_u32(ctx.priv_sz, 0, (4 : UInt32))
      let _ = @dx12.dx_d3d12_fence1_get_private_data(f1, ctx.priv_guid, ctx.priv_sz, sc)
      let _ = @dx12.dx_d3d12_fence1_set_private_data_interface(f1, ctx.priv_guid, (0 : UInt64))
      let _ = @dx12.dx_d3d12_fence1_set_name(f1, ctx.name_w)
      @dx12.write_u64(out, 0, (0 : UInt64))
      if @dx12.dx_d3d12_fence1_get_device(f1, @dx12.bytes_ptr(@dx12.iid_d3d12_device), out) == 0 {
        let _ = @dx12.com_release(@dx12.read_u64(out, 0))
      }
      ctx.fence_seq = ctx.fence_seq + (1 : Int64)
      let _ = @dx12.dx_d3d12_fence1_signal(f1, ctx.fence_seq)
      let _ = @dx12.dx_d3d12_fence1_get_completed_value(f1)
      let _ = @dx12.dx_d3d12_fence1_set_event_on_completion(f1, ctx.fence_seq, ctx.ev)
      let _ = @dx12.wait_event(ctx.ev, 1000)
      let _ = @dx12.dx_d3d12_fence1_get_creation_flags(f1)
      let _ = @dx12.com_release(f1)
      p.val = p.val + 9
    }
  }

  // 6. ID3D12CommandAllocator, ID3D12QueryHeap, ID3D12CommandSignature, ID3D12RootSignature, ID3D10Blob
  let _ = @dx12.dx_d3d12_command_allocator_set_private_data(ctx.ca, ctx.priv_guid, 4, ctx.priv_val)
  @dx12.write_u32(ctx.priv_sz, 0, (4 : UInt32))
  let _ = @dx12.dx_d3d12_command_allocator_get_private_data(ctx.ca, ctx.priv_guid, ctx.priv_sz, sc)
  let _ = @dx12.dx_d3d12_command_allocator_set_private_data_interface(ctx.ca, ctx.priv_guid, (0 : UInt64))
  let _ = @dx12.dx_d3d12_command_allocator_set_name(ctx.ca, ctx.name_w)
  @dx12.write_u64(out, 0, (0 : UInt64))
  if @dx12.dx_d3d12_command_allocator_get_device(ctx.ca, @dx12.bytes_ptr(@dx12.iid_d3d12_device), out) == 0 {
    let _ = @dx12.com_release(@dx12.read_u64(out, 0))
  }
  let _ = @dx12.dx_d3d12_command_allocator_reset(ctx.ca)
  p.val = p.val + 6

  @dx12.write_u64(out, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device_create_query_heap(ctx.raw_dev, ctx.qh_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_query_heap), out) == 0 {
    let qh = @dx12.read_u64(out, 0)
    let _ = @dx12.dx_d3d12_query_heap_set_private_data(qh, ctx.priv_guid, 4, ctx.priv_val)
    @dx12.write_u32(ctx.priv_sz, 0, (4 : UInt32))
    let _ = @dx12.dx_d3d12_query_heap_get_private_data(qh, ctx.priv_guid, ctx.priv_sz, sc)
    let _ = @dx12.dx_d3d12_query_heap_set_private_data_interface(qh, ctx.priv_guid, (0 : UInt64))
    let _ = @dx12.dx_d3d12_query_heap_set_name(qh, ctx.name_w)
    @dx12.write_u64(out, 0, (0 : UInt64))
    if @dx12.dx_d3d12_query_heap_get_device(qh, @dx12.bytes_ptr(@dx12.iid_d3d12_device), out) == 0 {
      let _ = @dx12.com_release(@dx12.read_u64(out, 0))
    }
    let _ = @dx12.com_release(qh)
    p.val = p.val + 5
  }

  @dx12.write_u64(out, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device_create_command_signature(ctx.raw_dev, ctx.csig_desc, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_command_signature), out) == 0 {
    let csig = @dx12.read_u64(out, 0)
    let _ = @dx12.dx_d3d12_command_signature_set_private_data(csig, ctx.priv_guid, 4, ctx.priv_val)
    @dx12.write_u32(ctx.priv_sz, 0, (4 : UInt32))
    let _ = @dx12.dx_d3d12_command_signature_get_private_data(csig, ctx.priv_guid, ctx.priv_sz, sc)
    let _ = @dx12.dx_d3d12_command_signature_set_private_data_interface(csig, ctx.priv_guid, (0 : UInt64))
    let _ = @dx12.dx_d3d12_command_signature_set_name(csig, ctx.name_w)
    @dx12.write_u64(out, 0, (0 : UInt64))
    if @dx12.dx_d3d12_command_signature_get_device(csig, @dx12.bytes_ptr(@dx12.iid_d3d12_device), out) == 0 {
      let _ = @dx12.com_release(@dx12.read_u64(out, 0))
    }
    let _ = @dx12.com_release(csig)
    p.val = p.val + 5
  }

  let _ = @dx12.dx_d3d12_root_signature_set_private_data(ctx.rs, ctx.priv_guid, 4, ctx.priv_val)
  @dx12.write_u32(ctx.priv_sz, 0, (4 : UInt32))
  let _ = @dx12.dx_d3d12_root_signature_get_private_data(ctx.rs, ctx.priv_guid, ctx.priv_sz, sc)
  let _ = @dx12.dx_d3d12_root_signature_set_private_data_interface(ctx.rs, ctx.priv_guid, (0 : UInt64))
  let _ = @dx12.dx_d3d12_root_signature_set_name(ctx.rs, ctx.name_w)
  @dx12.write_u64(out, 0, (0 : UInt64))
  if @dx12.dx_d3d12_root_signature_get_device(ctx.rs, @dx12.bytes_ptr(@dx12.iid_d3d12_device), out) == 0 {
    let _ = @dx12.com_release(@dx12.read_u64(out, 0))
  }
  let _ = @dx12.dx_id3_d10_blob_get_buffer_pointer(rs_blob_obj)
  let _ = @dx12.dx_id3_d10_blob_get_buffer_size(rs_blob_obj)
  p.val = p.val + 7

  // 7. ID3D12DescriptorHeap (shader-visible CBV_SRV_UAV so GPU handle is valid too)
  @dx12.write_u64(out, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device_create_descriptor_heap(ctx.raw_dev, ctx.dh_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_descriptor_heap), out) == 0 {
    let dh = @dx12.read_u64(out, 0)
    let _ = @dx12.dx_d3d12_descriptor_heap_set_private_data(dh, ctx.priv_guid, 4, ctx.priv_val)
    @dx12.write_u32(ctx.priv_sz, 0, (4 : UInt32))
    let _ = @dx12.dx_d3d12_descriptor_heap_get_private_data(dh, ctx.priv_guid, ctx.priv_sz, sc)
    let _ = @dx12.dx_d3d12_descriptor_heap_set_private_data_interface(dh, ctx.priv_guid, (0 : UInt64))
    let _ = @dx12.dx_d3d12_descriptor_heap_set_name(dh, ctx.name_w)
    @dx12.write_u64(out, 0, (0 : UInt64))
    if @dx12.dx_d3d12_descriptor_heap_get_device(dh, @dx12.bytes_ptr(@dx12.iid_d3d12_device), out) == 0 {
      let _ = @dx12.com_release(@dx12.read_u64(out, 0))
    }
    let _ = @dx12.dx_d3d12_descriptor_heap_get_desc(dh, sc)
    let _ = @dx12.dx_d3d12_descriptor_heap_get_cpu_descriptor_handle_for_heap_start(dh, sc)
    let _ = @dx12.dx_d3d12_descriptor_heap_get_gpu_descriptor_handle_for_heap_start(dh, sc)
    let _ = @dx12.com_release(dh)
    p.val = p.val + 8
  }

  // 8. ID3D12CommandList + ID3D12CommandQueue (Wait + Signal + ExecuteCommandLists + SetMarker)
  @dx12.write_u64(out, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device_create_command_list(
      ctx.raw_dev, 0, 0, ctx.ca, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_graphics_command_list), out,
    ) == 0 {
    let cl_g = @dx12.read_u64(out, 0)
    let _ = @dx12.dx_d3d12_graphics_command_list_close(cl_g)
    @dx12.write_u64(out, 0, (0 : UInt64))
    if @dx12.com_query_interface(cl_g, @dx12.bytes_ptr(@dx12.iid_d3d12_command_list), out) == 0 {
      let cl = @dx12.read_u64(out, 0)
      let _ = @dx12.dx_d3d12_command_list_set_private_data(cl, ctx.priv_guid, 4, ctx.priv_val)
      @dx12.write_u32(ctx.priv_sz, 0, (4 : UInt32))
      let _ = @dx12.dx_d3d12_command_list_get_private_data(cl, ctx.priv_guid, ctx.priv_sz, sc)
      let _ = @dx12.dx_d3d12_command_list_set_private_data_interface(cl, ctx.priv_guid, (0 : UInt64))
      let _ = @dx12.dx_d3d12_command_list_set_name(cl, ctx.name_w)
      @dx12.write_u64(out, 0, (0 : UInt64))
      if @dx12.dx_d3d12_command_list_get_device(cl, @dx12.bytes_ptr(@dx12.iid_d3d12_device), out) == 0 {
        let _ = @dx12.com_release(@dx12.read_u64(out, 0))
      }
      let _ = @dx12.dx_d3d12_command_list_get_type(cl)
      let cl_arr = sc + (128 : UInt64)
      @dx12.write_u64(cl_arr, 0, cl)
      @dx12.dx_d3d12_command_queue_execute_command_lists(queue, 1, cl_arr)
      let _ = @dx12.com_release(cl)
      p.val = p.val + 7
    }
    let _ = @dx12.com_release(cl_g)
  }

  let _ = @dx12.dx_d3d12_command_queue_set_private_data(queue, ctx.priv_guid, 4, ctx.priv_val)
  @dx12.write_u32(ctx.priv_sz, 0, (4 : UInt32))
  let _ = @dx12.dx_d3d12_command_queue_get_private_data(queue, ctx.priv_guid, ctx.priv_sz, sc)
  let _ = @dx12.dx_d3d12_command_queue_set_private_data_interface(queue, ctx.priv_guid, (0 : UInt64))
  let _ = @dx12.dx_d3d12_command_queue_set_name(queue, ctx.name_w)
  @dx12.write_u64(out, 0, (0 : UInt64))
  if @dx12.dx_d3d12_command_queue_get_device(queue, @dx12.bytes_ptr(@dx12.iid_d3d12_device), out) == 0 {
    let _ = @dx12.com_release(@dx12.read_u64(out, 0))
  }
  @dx12.dx_d3d12_command_queue_set_marker(queue, 0, (0 : UInt64), 0)
  let _ = @dx12.dx_d3d12_command_queue_get_desc(queue, sc)
  let _ = @dx12.dx_d3d12_command_queue_get_timestamp_frequency(queue, sc + (64 : UInt64))
  let _ = @dx12.dx_d3d12_command_queue_get_clock_calibration(queue, sc + (72 : UInt64), sc + (80 : UInt64))
  ctx.fence_seq = ctx.fence_seq + (1 : Int64)
  let wait_seq = ctx.fence_seq
  let _ = @dx12.dx_d3d12_fence_signal(ctx.fence, wait_seq)
  let _ = @dx12.dx_d3d12_command_queue_wait(queue, ctx.fence, wait_seq)
  ctx.fence_seq = ctx.fence_seq + (1 : Int64)
  let sig_seq = ctx.fence_seq
  let _ = @dx12.dx_d3d12_command_queue_signal(queue, ctx.fence, sig_seq)
  while @dx12.dx_d3d12_fence_get_completed_value(ctx.fence) < sig_seq {
    if @dx12.dx_d3d12_fence_set_event_on_completion(ctx.fence, sig_seq, ctx.ev) == 0 {
      let _ = @dx12.wait_event(ctx.ev, 5000)
    } else {
      break
    }
  }
  p.val = p.val + 11

  // 9. ID3D12PipelineState + ID3D12PipelineLibrary0..1
  if lib_pso != (0 : UInt64) {
    let _ = @dx12.dx_d3d12_pipeline_state_set_private_data(lib_pso, ctx.priv_guid, 4, ctx.priv_val)
    @dx12.write_u32(ctx.priv_sz, 0, (4 : UInt32))
    let _ = @dx12.dx_d3d12_pipeline_state_get_private_data(lib_pso, ctx.priv_guid, ctx.priv_sz, sc)
    let _ = @dx12.dx_d3d12_pipeline_state_set_private_data_interface(lib_pso, ctx.priv_guid, (0 : UInt64))
    let _ = @dx12.dx_d3d12_pipeline_state_set_name(lib_pso, ctx.name_w)
    @dx12.write_u64(out, 0, (0 : UInt64))
    if @dx12.dx_d3d12_pipeline_state_get_device(lib_pso, @dx12.bytes_ptr(@dx12.iid_d3d12_device), out) == 0 {
      let _ = @dx12.com_release(@dx12.read_u64(out, 0))
    }
    @dx12.write_u64(out, 0, (0 : UInt64))
    if @dx12.dx_d3d12_pipeline_state_get_cached_blob(lib_pso, out) == 0 {
      let b = @dx12.read_u64(out, 0)
      if b != (0 : UInt64) { let _ = @dx12.com_release(b) }
    }
    p.val = p.val + 6

    @dx12.write_u64(out, 0, (0 : UInt64))
    if @dx12.dx_d3d12_device1_create_pipeline_library(ctx.raw_dev, (0 : UInt64), (0 : Int64), @dx12.bytes_ptr(@dx12.iid_d3d12_pipeline_library), out) == 0 {
      let pl0 = @dx12.read_u64(out, 0)
      if pl0 != (0 : UInt64) {
        let _ = @dx12.dx_d3d12_pipeline_library_set_private_data(pl0, ctx.priv_guid, 4, ctx.priv_val)
        @dx12.write_u32(ctx.priv_sz, 0, (4 : UInt32))
        let _ = @dx12.dx_d3d12_pipeline_library_get_private_data(pl0, ctx.priv_guid, ctx.priv_sz, sc)
        let _ = @dx12.dx_d3d12_pipeline_library_set_private_data_interface(pl0, ctx.priv_guid, (0 : UInt64))
        let _ = @dx12.dx_d3d12_pipeline_library_set_name(pl0, ctx.name_w)
        @dx12.write_u64(out, 0, (0 : UInt64))
        if @dx12.dx_d3d12_pipeline_library_get_device(pl0, @dx12.bytes_ptr(@dx12.iid_d3d12_device), out) == 0 {
          let _ = @dx12.com_release(@dx12.read_u64(out, 0))
        }
        let _ = @dx12.dx_d3d12_pipeline_library_store_pipeline(pl0, ctx.name_w, lib_pso)
        let ser_sz = @dx12.dx_d3d12_pipeline_library_get_serialized_size(pl0)
        if ser_sz > (0 : Int64) {
          let ser_buf = @dx12.raw_alloc(ser_sz.to_int())
          if @dx12.dx_d3d12_pipeline_library_serialize(pl0, ser_buf, ser_sz) == 0 {
            @dx12.write_u64(out, 0, (0 : UInt64))
            if @dx12.dx_d3d12_device1_create_pipeline_library(ctx.raw_dev, ser_buf, ser_sz, @dx12.bytes_ptr(@dx12.iid_d3d12_pipeline_library1), out) == 0 {
              let pl1 = @dx12.read_u64(out, 0)
              if pl1 != (0 : UInt64) {
                let _ = @dx12.dx_d3d12_pipeline_library1_set_private_data(pl1, ctx.priv_guid, 4, ctx.priv_val)
                @dx12.write_u32(ctx.priv_sz, 0, (4 : UInt32))
                let _ = @dx12.dx_d3d12_pipeline_library1_get_private_data(pl1, ctx.priv_guid, ctx.priv_sz, sc)
                let _ = @dx12.dx_d3d12_pipeline_library1_set_private_data_interface(pl1, ctx.priv_guid, (0 : UInt64))
                let _ = @dx12.dx_d3d12_pipeline_library1_set_name(pl1, ctx.name_w)
                @dx12.write_u64(out, 0, (0 : UInt64))
                if @dx12.dx_d3d12_pipeline_library1_get_device(pl1, @dx12.bytes_ptr(@dx12.iid_d3d12_device), out) == 0 {
                  let _ = @dx12.com_release(@dx12.read_u64(out, 0))
                }
                let _ = @dx12.dx_d3d12_pipeline_library1_get_serialized_size(pl1)
                let _ = @dx12.dx_d3d12_pipeline_library1_serialize(pl1, ser_buf, ser_sz)
                @dx12.write_u64(out, 0, (0 : UInt64))
                if @dx12.dx_d3d12_pipeline_library1_load_compute_pipeline(pl1, ctx.name_w, ctx.cpsd, @dx12.bytes_ptr(@dx12.iid_d3d12_pipeline_state), out) == 0 {
                  let _ = @dx12.com_release(@dx12.read_u64(out, 0))
                }
                @dx12.write_u64(out, 0, (0 : UInt64))
                if @dx12.dx_d3d12_pipeline_library1_load_pipeline(pl1, ctx.name_w, ctx.stream_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_pipeline_state), out) == 0 {
                  let _ = @dx12.com_release(@dx12.read_u64(out, 0))
                }
                let _ = @dx12.com_release(pl1)
                p.val = p.val + 9
              }
            }
          }
          @dx12.raw_free(ser_buf)
        }
        let _ = @dx12.com_release(pl0)
        p.val = p.val + 8
      }
    }
  }

  // 10. ID3D12ShaderCacheSession
  @dx12.write_u64(out, 0, (0 : UInt64))
  if @dx12.dx_d3d12_device9_create_shader_cache_session(ctx.raw_dev, ctx.cache_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_shader_cache_session), out) == 0 {
    let scs = @dx12.read_u64(out, 0)
    if scs != (0 : UInt64) {
      let _ = @dx12.dx_d3d12_shader_cache_session_set_private_data(scs, ctx.priv_guid, 4, ctx.priv_val)
      @dx12.write_u32(ctx.priv_sz, 0, (4 : UInt32))
      let _ = @dx12.dx_d3d12_shader_cache_session_get_private_data(scs, ctx.priv_guid, ctx.priv_sz, sc)
      let _ = @dx12.dx_d3d12_shader_cache_session_set_private_data_interface(scs, ctx.priv_guid, (0 : UInt64))
      let _ = @dx12.dx_d3d12_shader_cache_session_set_name(scs, ctx.name_w)
      @dx12.write_u64(out, 0, (0 : UInt64))
      if @dx12.dx_d3d12_shader_cache_session_get_device(scs, @dx12.bytes_ptr(@dx12.iid_d3d12_device), out) == 0 {
        let _ = @dx12.com_release(@dx12.read_u64(out, 0))
      }
      let _ = @dx12.dx_d3d12_shader_cache_session_get_desc(scs, sc)
      let key_buf = sc + (256 : UInt64)
      let val_buf = sc + (272 : UInt64)
      let val_sz = sc + (288 : UInt64)
      @dx12.write_u32(key_buf, 0, (0x12345678 : UInt32))
      @dx12.write_u32(val_buf, 0, (0xDEADBEEF : UInt32))
      @dx12.write_u32(val_sz, 0, (4 : UInt32))
      let _ = @dx12.dx_d3d12_shader_cache_session_store_value(scs, key_buf, 4, val_buf, 4)
      let _ = @dx12.dx_d3d12_shader_cache_session_find_value(scs, key_buf, 4, val_buf + (16 : UInt64), val_sz)
      @dx12.dx_d3d12_shader_cache_session_set_delete_on_destroy(scs)
      let _ = @dx12.com_release(scs)
      p.val = p.val + 9
    }
  }

  // 11. ID3D12StateObject + ID3D12StateObjectProperties0..1
  if ctx.rt_so != (0 : UInt64) {
    let so = ctx.rt_so
    let _ = @dx12.dx_d3d12_state_object_set_private_data(so, ctx.priv_guid, 4, ctx.priv_val)
    @dx12.write_u32(ctx.priv_sz, 0, (4 : UInt32))
    let _ = @dx12.dx_d3d12_state_object_get_private_data(so, ctx.priv_guid, ctx.priv_sz, sc)
    let _ = @dx12.dx_d3d12_state_object_set_private_data_interface(so, ctx.priv_guid, (0 : UInt64))
    let _ = @dx12.dx_d3d12_state_object_set_name(so, ctx.name_w)
    @dx12.write_u64(out, 0, (0 : UInt64))
    if @dx12.dx_d3d12_state_object_get_device(so, @dx12.bytes_ptr(@dx12.iid_d3d12_device), out) == 0 {
      let _ = @dx12.com_release(@dx12.read_u64(out, 0))
    }
    p.val = p.val + 5

    @dx12.write_u64(out, 0, (0 : UInt64))
    if @dx12.com_query_interface(so, @dx12.bytes_ptr(@dx12.iid_d3d12_state_object_properties), out) == 0 {
      let sop = @dx12.read_u64(out, 0)
      if sop != (0 : UInt64) {
        let exp_name = @dx12.to_utf16("rgen_main")
        let _ = @dx12.dx_d3d12_state_object_properties_get_shader_identifier(sop, @dx12.bytes_ptr(exp_name))
        let ssz = @dx12.dx_d3d12_state_object_properties_get_shader_stack_size(sop, @dx12.bytes_ptr(exp_name))
        let _ = ssz
        let pssz = @dx12.dx_d3d12_state_object_properties_get_pipeline_stack_size(sop)
        @dx12.dx_d3d12_state_object_properties_set_pipeline_stack_size(sop, pssz)
        ignore(exp_name)
        let _ = @dx12.com_release(sop)
        p.val = p.val + 4
      }
    }
    @dx12.write_u64(out, 0, (0 : UInt64))
    if @dx12.com_query_interface(so, @dx12.bytes_ptr(@dx12.iid_d3d12_state_object_properties1), out) == 0 {
      let sop1 = @dx12.read_u64(out, 0)
      if sop1 != (0 : UInt64) {
        let exp_name = @dx12.to_utf16("rgen_main")
        let _ = @dx12.dx_d3d12_state_object_properties1_get_shader_identifier(sop1, @dx12.bytes_ptr(exp_name))
        let _ = @dx12.dx_d3d12_state_object_properties1_get_shader_stack_size(sop1, @dx12.bytes_ptr(exp_name))
        let ssz1 = @dx12.dx_d3d12_state_object_properties1_get_pipeline_stack_size(sop1)
        @dx12.dx_d3d12_state_object_properties1_set_pipeline_stack_size(sop1, ssz1)
        ignore(exp_name)
        let _ = @dx12.com_release(sop1)
        p.val = p.val + 4
      }
    }
  }
}
