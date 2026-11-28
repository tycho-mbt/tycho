// dx12/raw-device-all — exercises the d3d12.dll free entry points, D3D12
// singletons, core D3D12 object interfaces, and the full ID3D12Device0..14 chain
// through the generated dx_* dispatch under the debug layer with 0 errors.
// Non-Windows hosts SKIP cleanly.

///|
fn main {
  if !@dx12.available() {
    println("[dx12/raw-device-all] SKIP — d3d12.dll / dxgi.dll not loadable on this host")
    return
  }
  let device = match @dx12.Device::create(warp=@dx12.env_requests_warp(), debug=true) {
    Some(d) => d
    None =>
      match @dx12.Device::create(warp=true, debug=true) {
        Some(d) => d
        None => {
          println("[dx12/raw-device-all] FAIL — no D3D12 device")
          return
        }
      }
  }
  let raw_dev = device.raw()
  let probed : Ref[Int] = Ref(0)
  let mut ok = true

  let out_ptr = @dx12.raw_alloc(16)
  let err_ptr = @dx12.raw_alloc(16)
  let scratch = @dx12.raw_alloc(16384)
  let priv_val = @dx12.raw_alloc(16)
  @dx12.write_u32(priv_val, 0, (7 : UInt32))
  let priv_sz = @dx12.raw_alloc(8)
  let priv_guid = @dx12.bytes_ptr(@dx12.iid_d3d12_object)
  let name_utf16 = @dx12.to_utf16("tycho_raw_device_all")
  let name_w = @dx12.bytes_ptr(name_utf16)

  // --- 1. Free d3d12.dll entry points ---
  @dx12.write_u64(out_ptr, 0, (0 : UInt64))
  if @dx12.d3d12_get_debug_interface(@dx12.bytes_ptr(@dx12.iid_iunknown), out_ptr) == 0 {
    let dbg = @dx12.read_u64(out_ptr, 0)
    if dbg != (0 : UInt64) { let _ = @dx12.com_release(dbg) }
  }
  let _ = @dx12.d3d12_enable_experimental_features(0, (0 : UInt64), (0 : UInt64), (0 : UInt64))
  @dx12.write_u64(out_ptr, 0, (0 : UInt64))
  if @dx12.d3d12_create_device((0 : UInt64), 0xC000, @dx12.bytes_ptr(@dx12.iid_d3d12_device), out_ptr) == 0 {
    let td = @dx12.read_u64(out_ptr, 0)
    if td != (0 : UInt64) { let _ = @dx12.com_release(td) }
  }
  probed.val = probed.val + 3

  // Serialize v1.0 & v1.1 empty root signatures + deserializers.
  let rs_desc_v10 = @dx12.raw_alloc(24) // D3D12_ROOT_SIGNATURE_DESC (24B zeroed)
  @dx12.write_u64(out_ptr, 0, (0 : UInt64))
  @dx12.write_u64(err_ptr, 0, (0 : UInt64))
  if @dx12.d3d12_serialize_root_signature(rs_desc_v10, 1, out_ptr, err_ptr) == 0 {
    let b10 = @dx12.read_u64(out_ptr, 0)
    if b10 != (0 : UInt64) {
      let b10_ptr = @dx12.dx_id3_d10_blob_get_buffer_pointer(b10)
      let b10_len = @dx12.dx_id3_d10_blob_get_buffer_size(b10)
      let d_out = @dx12.raw_alloc(16)
      @dx12.write_u64(d_out, 0, (0 : UInt64))
      if @dx12.d3d12_create_root_signature_deserializer(
          b10_ptr, b10_len, @dx12.bytes_ptr(@dx12.iid_d3d12_root_signature_deserializer), d_out,
        ) == 0 {
        let d10 = @dx12.read_u64(d_out, 0)
        if d10 != (0 : UInt64) {
          let _ = @dx12.dx_d3d12_root_signature_deserializer_get_root_signature_desc(d10)
          let _ = @dx12.com_release(d10)
          probed.val = probed.val + 1
        }
      }
      @dx12.raw_free(d_out)
      let _ = @dx12.com_release(b10)
    }
  }
  if @dx12.read_u64(err_ptr, 0) != (0 : UInt64) { let _ = @dx12.com_release(@dx12.read_u64(err_ptr, 0)) }
  @dx12.raw_free(rs_desc_v10)

  let rs_desc_v11 = @dx12.raw_alloc(48)
  @dx12.write_u32(rs_desc_v11, 0, (2 : UInt32)) // D3D_ROOT_SIGNATURE_VERSION_1_1
  @dx12.write_u64(out_ptr, 0, (0 : UInt64))
  @dx12.write_u64(err_ptr, 0, (0 : UInt64))
  let hr_v11 = @dx12.d3d12_serialize_versioned_root_signature(rs_desc_v11, out_ptr, err_ptr)
  let rs_blob_obj = @dx12.read_u64(out_ptr, 0)
  if @dx12.read_u64(err_ptr, 0) != (0 : UInt64) { let _ = @dx12.com_release(@dx12.read_u64(err_ptr, 0)) }
  ok = ok && hr_v11 == 0 && rs_blob_obj != (0 : UInt64)
  let rs_blob = @dx12.dx_id3_d10_blob_get_buffer_pointer(rs_blob_obj)
  let rs_len = @dx12.dx_id3_d10_blob_get_buffer_size(rs_blob_obj)

  @dx12.write_u64(out_ptr, 0, (0 : UInt64))
  if @dx12.d3d12_create_versioned_root_signature_deserializer(
      rs_blob, rs_len, @dx12.bytes_ptr(@dx12.iid_d3d12_versioned_root_signature_deserializer), out_ptr,
    ) == 0 {
    let dv = @dx12.read_u64(out_ptr, 0)
    if dv != (0 : UInt64) {
      let _ = @dx12.dx_d3d12_versioned_root_signature_deserializer_get_unconverted_root_signature_desc(dv)
      let p_conv = @dx12.raw_alloc(16)
      let _ = @dx12.dx_d3d12_versioned_root_signature_deserializer_get_root_signature_desc_at_version(dv, 2, p_conv)
      @dx12.raw_free(p_conv)
      let _ = @dx12.com_release(dv)
      probed.val = probed.val + 2
    }
  }
  probed.val = probed.val + 4

  // --- 2. Build shared D3D12 objects for testing ---
  let q_desc = @dx12.raw_alloc(16)
  @dx12.write_u64(out_ptr, 0, (0 : UInt64))
  let _ = @dx12.dx_d3d12_device_create_command_queue(raw_dev, q_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_command_queue), out_ptr)
  let queue = @dx12.read_u64(out_ptr, 0)

  @dx12.write_u64(out_ptr, 0, (0 : UInt64))
  let _ = @dx12.dx_d3d12_device_create_command_allocator(raw_dev, 0, @dx12.bytes_ptr(@dx12.iid_d3d12_command_allocator), out_ptr)
  let ca = @dx12.read_u64(out_ptr, 0)

  @dx12.write_u64(out_ptr, 0, (0 : UInt64))
  let _ = @dx12.dx_d3d12_device_create_fence(raw_dev, (0 : Int64), 0, @dx12.bytes_ptr(@dx12.iid_d3d12_fence), out_ptr)
  let fence = @dx12.read_u64(out_ptr, 0)

  @dx12.write_u64(out_ptr, 0, (0 : UInt64))
  let _ = @dx12.dx_d3d12_device_create_root_signature(raw_dev, 0, rs_blob, rs_len, @dx12.bytes_ptr(@dx12.iid_d3d12_root_signature), out_ptr)
  let rs = @dx12.read_u64(out_ptr, 0)

  // Compute & Graphics & Stream PSO descs
  let cs_bytes = @dx12.raw_alloc(mini_cs_dxil_bytes + 8)
  @dx12.memcpy_ptr(cs_bytes, @dx12.bytes_ptr(mini_cs_dxil), mini_cs_dxil_bytes)
  let vs_bytes = @dx12.raw_alloc(mini_vs_dxil_bytes + 8)
  @dx12.memcpy_ptr(vs_bytes, @dx12.bytes_ptr(mini_vs_dxil), mini_vs_dxil_bytes)
  let ps_bytes = @dx12.raw_alloc(mini_ps_dxil_bytes + 8)
  @dx12.memcpy_ptr(ps_bytes, @dx12.bytes_ptr(mini_ps_dxil), mini_ps_dxil_bytes)
  let lib_bytes = @dx12.raw_alloc(mini_lib_dxil_bytes + 8)
  @dx12.memcpy_ptr(lib_bytes, @dx12.bytes_ptr(mini_lib_dxil), mini_lib_dxil_bytes)

  let cpsd = @dx12.raw_alloc(64)
  @dx12.write_u64(cpsd, 0, rs)
  @dx12.write_u64(cpsd, 8, cs_bytes)
  @dx12.write_u64(cpsd, 16, mini_cs_dxil_bytes.to_uint64())

  let gpsd = @dx12.raw_alloc(656)
  @dx12.write_u64(gpsd, 0, rs)
  @dx12.write_u64(gpsd, 8, vs_bytes)
  @dx12.write_u64(gpsd, 16, mini_vs_dxil_bytes.to_uint64())
  @dx12.write_u64(gpsd, 24, ps_bytes)
  @dx12.write_u64(gpsd, 32, mini_ps_dxil_bytes.to_uint64())
  @dx12.write_u32(gpsd, 164, (0xF : UInt32)) // RenderTarget[0].RenderTargetWriteMask
  @dx12.write_u32(gpsd, 448, (0xFFFFFFFF : UInt32)) // SampleMask
  @dx12.write_u32(gpsd, 452, (3 : UInt32)) // FillMode = SOLID
  @dx12.write_u32(gpsd, 456, (1 : UInt32)) // CullMode = NONE
  @dx12.write_u32(gpsd, 572, (3 : UInt32)) // PrimitiveTopologyType = TRIANGLE
  @dx12.write_u32(gpsd, 576, (1 : UInt32)) // NumRenderTargets = 1
  @dx12.write_u32(gpsd, 580, (28 : UInt32)) // R8G8B8A8_UNORM
  @dx12.write_u32(gpsd, 616, (1 : UInt32)) // SampleDesc.Count = 1

  let stream_buf = @dx12.raw_alloc(48)
  @dx12.write_u32(stream_buf, 0, (0 : UInt32)) // ROOT_SIGNATURE
  @dx12.write_u64(stream_buf, 8, rs)
  @dx12.write_u32(stream_buf, 16, (6 : UInt32)) // CS (D3D12_PIPELINE_STATE_SUBOBJECT_TYPE_CS = 6)
  @dx12.write_u64(stream_buf, 24, cs_bytes)
  @dx12.write_u64(stream_buf, 32, mini_cs_dxil_bytes.to_uint64())
  let stream_desc = @dx12.raw_alloc(16)
  @dx12.write_u64(stream_desc, 0, (40 : UInt64))
  @dx12.write_u64(stream_desc, 8, stream_buf)

  @dx12.write_u64(out_ptr, 0, (0 : UInt64))
  let _ = @dx12.dx_d3d12_device_create_compute_pipeline_state(raw_dev, cpsd, @dx12.bytes_ptr(@dx12.iid_d3d12_pipeline_state), out_ptr)
  let lib_pso = @dx12.read_u64(out_ptr, 0)

  // Heap properties + descs + resources
  let heap_default = @dx12.raw_alloc(32)
  @dx12.write_u32(heap_default, 0, (1 : UInt32)) // DEFAULT
  @dx12.write_u32(heap_default, 12, (1 : UInt32))
  @dx12.write_u32(heap_default, 16, (1 : UInt32))

  let buf_desc = @dx12.raw_alloc(64)
  @dx12.write_u32(buf_desc, 0, (1 : UInt32)) // BUFFER
  @dx12.write_u64(buf_desc, 16, (4096 : UInt64))
  @dx12.write_u32(buf_desc, 24, (1 : UInt32))
  @dx12.write_u32(buf_desc, 28, (0x00010001 : UInt32))
  @dx12.write_u32(buf_desc, 36, (1 : UInt32))
  @dx12.write_u32(buf_desc, 44, (1 : UInt32)) // ROW_MAJOR
  @dx12.write_u32(buf_desc, 48, (4 : UInt32)) // ALLOW_UNORDERED_ACCESS

  let tex_desc = @dx12.raw_alloc(64)
  @dx12.write_u32(tex_desc, 0, (3 : UInt32)) // TEXTURE2D
  @dx12.write_u64(tex_desc, 16, (64 : UInt64))
  @dx12.write_u32(tex_desc, 24, (64 : UInt32))
  @dx12.write_u32(tex_desc, 28, (0x00010001 : UInt32))
  @dx12.write_u32(tex_desc, 32, (28 : UInt32)) // R8G8B8A8_UNORM
  @dx12.write_u32(tex_desc, 36, (1 : UInt32))
  @dx12.write_u32(tex_desc, 48, (1 : UInt32)) // ALLOW_RENDER_TARGET

  let tex_desc1 = @dx12.raw_alloc(80)
  @dx12.memcpy_ptr(tex_desc1, tex_desc, 56)

  let ds_desc = @dx12.raw_alloc(64)
  @dx12.memcpy_ptr(ds_desc, tex_desc, 56)
  @dx12.write_u32(ds_desc, 32, (40 : UInt32)) // D32_FLOAT
  @dx12.write_u32(ds_desc, 48, (2 : UInt32)) // ALLOW_DEPTH_STENCIL

  let tiled_desc = @dx12.raw_alloc(64)
  @dx12.write_u32(tiled_desc, 0, (3 : UInt32))
  @dx12.write_u64(tiled_desc, 16, (256 : UInt64))
  @dx12.write_u32(tiled_desc, 24, (256 : UInt32))
  @dx12.write_u32(tiled_desc, 28, (0x00010001 : UInt32))
  @dx12.write_u32(tiled_desc, 32, (28 : UInt32))
  @dx12.write_u32(tiled_desc, 36, (1 : UInt32))
  @dx12.write_u32(tiled_desc, 44, (2 : UInt32)) // D3D12_TEXTURE_LAYOUT_64KB_UNDEFINED_SWIZZLE
  let tiled_desc1 = @dx12.raw_alloc(80)
  @dx12.memcpy_ptr(tiled_desc1, tiled_desc, 56)

  let heap_desc = @dx12.raw_alloc(64)
  @dx12.write_u64(heap_desc, 0, (65536 : UInt64))
  @dx12.write_u32(heap_desc, 8, (1 : UInt32))
  @dx12.write_u32(heap_desc, 20, (1 : UInt32))
  @dx12.write_u32(heap_desc, 24, (1 : UInt32))
  @dx12.write_u64(heap_desc, 32, (65536 : UInt64))
  @dx12.write_u32(heap_desc, 40, (0 : UInt32))

  @dx12.write_u64(out_ptr, 0, (0 : UInt64))
  let _ = @dx12.dx_d3d12_device_create_committed_resource(raw_dev, heap_default, 0, buf_desc, 0, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), out_ptr)
  let buf_def = @dx12.read_u64(out_ptr, 0)
  @dx12.write_u64(out_ptr, 0, (0 : UInt64))
  let _ = @dx12.dx_d3d12_device_create_committed_resource(raw_dev, heap_default, 0, buf_desc, 0, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), out_ptr)
  let buf_uav = @dx12.read_u64(out_ptr, 0)
  @dx12.write_u64(out_ptr, 0, (0 : UInt64))
  let _ = @dx12.dx_d3d12_device_create_committed_resource(raw_dev, heap_default, 0, tex_desc, 0, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), out_ptr)
  let tex_rt = @dx12.read_u64(out_ptr, 0)
  @dx12.write_u64(out_ptr, 0, (0 : UInt64))
  let _ = @dx12.dx_d3d12_device_create_committed_resource(raw_dev, heap_default, 0, ds_desc, 16, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), out_ptr)
  let tex_ds = @dx12.read_u64(out_ptr, 0)
  @dx12.write_u64(out_ptr, 0, (0 : UInt64))
  let _ = @dx12.dx_d3d12_device_create_heap(raw_dev, heap_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_heap), out_ptr)
  let heap_obj = @dx12.read_u64(out_ptr, 0)
  @dx12.write_u64(out_ptr, 0, (0 : UInt64))
  let _ = @dx12.dx_d3d12_device_create_reserved_resource(raw_dev, tiled_desc, 0, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), out_ptr)
  let reserved_res = @dx12.read_u64(out_ptr, 0)

  // Descriptor heaps (CPU-only for Create*View/CopyDescriptors + shader-visible CBV_SRV_UAV for GPU handle)
  let dh_desc = @dx12.raw_alloc(16)
  @dx12.write_u32(dh_desc, 0, (0 : UInt32)) // CBV_SRV_UAV
  @dx12.write_u32(dh_desc, 4, (8 : UInt32))
  @dx12.write_u32(dh_desc, 8, (1 : UInt32)) // SHADER_VISIBLE

  let dh_cpu_desc = @dx12.raw_alloc(16)
  @dx12.write_u32(dh_cpu_desc, 0, (0 : UInt32))
  @dx12.write_u32(dh_cpu_desc, 4, (8 : UInt32))
  @dx12.write_u64(out_ptr, 0, (0 : UInt64))
  let _ = @dx12.dx_d3d12_device_create_descriptor_heap(raw_dev, dh_cpu_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_descriptor_heap), out_ptr)
  let dh_srv_cpu = @dx12.read_u64(out_ptr, 0)
  @dx12.write_u32(dh_cpu_desc, 0, (1 : UInt32)) // SAMPLER
  @dx12.write_u64(out_ptr, 0, (0 : UInt64))
  let _ = @dx12.dx_d3d12_device_create_descriptor_heap(raw_dev, dh_cpu_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_descriptor_heap), out_ptr)
  let dh_samp = @dx12.read_u64(out_ptr, 0)
  @dx12.write_u32(dh_cpu_desc, 0, (2 : UInt32)) // RTV
  @dx12.write_u64(out_ptr, 0, (0 : UInt64))
  let _ = @dx12.dx_d3d12_device_create_descriptor_heap(raw_dev, dh_cpu_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_descriptor_heap), out_ptr)
  let dh_rtv = @dx12.read_u64(out_ptr, 0)
  @dx12.write_u32(dh_cpu_desc, 0, (3 : UInt32)) // DSV
  @dx12.write_u64(out_ptr, 0, (0 : UInt64))
  let _ = @dx12.dx_d3d12_device_create_descriptor_heap(raw_dev, dh_cpu_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_descriptor_heap), out_ptr)
  let dh_dsv = @dx12.read_u64(out_ptr, 0)

  let inc_srv = @dx12.dx_d3d12_device_get_descriptor_handle_increment_size(raw_dev, 0).to_uint64()
  let cpu_h = @dx12.raw_alloc(8)
  let _ = @dx12.dx_d3d12_descriptor_heap_get_cpu_descriptor_handle_for_heap_start(dh_srv_cpu, cpu_h)
  let h_cbv = @dx12.read_u64(cpu_h, 0)
  let h_srv = h_cbv + inc_srv
  let h_uav = h_cbv + inc_srv * (2 : UInt64)
  let _ = @dx12.dx_d3d12_descriptor_heap_get_cpu_descriptor_handle_for_heap_start(dh_rtv, cpu_h)
  let h_rtv = @dx12.read_u64(cpu_h, 0)
  let _ = @dx12.dx_d3d12_descriptor_heap_get_cpu_descriptor_handle_for_heap_start(dh_dsv, cpu_h)
  let h_dsv = @dx12.read_u64(cpu_h, 0)
  let _ = @dx12.dx_d3d12_descriptor_heap_get_cpu_descriptor_handle_for_heap_start(dh_samp, cpu_h)
  let h_samp = @dx12.read_u64(cpu_h, 0)

  // Dispatch thunks dereference *(D3D12_CPU_DESCRIPTOR_HANDLE*), so pass slot pointers.
  let cpu_arr = @dx12.raw_alloc(48)
  @dx12.write_u64(cpu_arr, 0, h_cbv)
  @dx12.write_u64(cpu_arr, 8, h_srv)
  @dx12.write_u64(cpu_arr, 16, h_uav)
  @dx12.write_u64(cpu_arr, 24, h_rtv)
  @dx12.write_u64(cpu_arr, 32, h_dsv)
  @dx12.write_u64(cpu_arr, 40, h_samp)
  let cpu_cbv = cpu_arr
  let cpu_srv = cpu_arr + (8 : UInt64)
  let cpu_uav = cpu_arr + (16 : UInt64)
  let cpu_rtv = cpu_arr + (24 : UInt64)
  let cpu_dsv = cpu_arr + (32 : UInt64)
  let cpu_samp = cpu_arr + (40 : UInt64)
  let sz_arr = @dx12.raw_alloc(8)
  @dx12.write_u32(sz_arr, 0, (1 : UInt32))

  let cbv_desc = @dx12.raw_alloc(16)
  @dx12.write_u64(cbv_desc, 0, @dx12.dx_d3d12_resource_get_gpu_virtual_address(buf_def).reinterpret_as_uint64())
  @dx12.write_u32(cbv_desc, 8, (256 : UInt32))

  let srv_desc = @dx12.raw_alloc(40)
  @dx12.write_u32(srv_desc, 4, (1 : UInt32)) // BUFFER
  @dx12.write_u32(srv_desc, 8, (5768 : UInt32)) // DEFAULT_SHADER_4_COMPONENT_MAPPING
  @dx12.write_u32(srv_desc, 24, (16 : UInt32)) // NumElements
  @dx12.write_u32(srv_desc, 28, (16 : UInt32)) // StructureByteStride

  let uav_desc = @dx12.raw_alloc(40)
  @dx12.write_u32(uav_desc, 4, (1 : UInt32)) // BUFFER
  @dx12.write_u32(uav_desc, 16, (16 : UInt32))
  @dx12.write_u32(uav_desc, 20, (16 : UInt32))

  let samp_desc = @dx12.raw_alloc(56)
  @dx12.write_u32(samp_desc, 0, (21 : UInt32)) // MIN_MAG_MIP_LINEAR
  @dx12.write_u32(samp_desc, 4, (1 : UInt32))
  @dx12.write_u32(samp_desc, 8, (1 : UInt32))
  @dx12.write_u32(samp_desc, 12, (1 : UInt32))
  @dx12.write_u32(samp_desc, 24, (1 : UInt32))
  @dx12.write_u32(samp_desc, 48, (0x7F7FFFFF : UInt32))

  let samp2_desc = @dx12.raw_alloc(64)
  @dx12.memcpy_ptr(samp2_desc, samp_desc, 52)

  let qh_desc = @dx12.raw_alloc(16)
  @dx12.write_u32(qh_desc, 0, (2 : UInt32)) // TIMESTAMP
  @dx12.write_u32(qh_desc, 4, (2 : UInt32))

  let arg_desc = @dx12.raw_alloc(16) // DRAW = 0
  let csig_desc = @dx12.raw_alloc(24)
  @dx12.write_u32(csig_desc, 0, (16 : UInt32))
  @dx12.write_u32(csig_desc, 4, (1 : UInt32))
  @dx12.write_u64(csig_desc, 8, arg_desc)

  let res_arr = @dx12.raw_alloc(8)
  @dx12.write_u64(res_arr, 0, heap_obj)
  let prio_arr = @dx12.raw_alloc(8)
  @dx12.write_u32(prio_arr, 0, (0x78000000 : UInt32))
  let fence_arr = @dx12.raw_alloc(8)
  @dx12.write_u64(fence_arr, 0, fence)
  let val_arr = @dx12.raw_alloc(8)
  @dx12.write_u64(val_arr, 0, (0 : UInt64))
  let ev = @dx12.create_event()
  let arch_buf = @dx12.raw_alloc(16)

  // Raytracing StateObject (optional on rt_tier > 0)
  let rt_tier = device.raytracing_tier()
  let rt_inputs = @dx12.raw_alloc(32) // Type=0 TOP_LEVEL, NumDescs=0 -> valid
  let rt_prebuild = @dx12.raw_alloc(32)
  let rt_ident = @dx12.raw_alloc(16)
  let exp_name_utf16 = @dx12.to_utf16("rgen_main")
  let exp_desc = @dx12.raw_alloc(24)
  @dx12.write_u64(exp_desc, 0, @dx12.bytes_ptr(exp_name_utf16))
  let dxil_lib_desc = @dx12.raw_alloc(32)
  @dx12.write_u64(dxil_lib_desc, 0, lib_bytes)
  @dx12.write_u64(dxil_lib_desc, 8, mini_lib_dxil_bytes.to_uint64())
  @dx12.write_u32(dxil_lib_desc, 16, (1 : UInt32))
  @dx12.write_u64(dxil_lib_desc, 24, exp_desc)
  let so_cfg = @dx12.raw_alloc(8)
  @dx12.write_u32(so_cfg, 0, (4 : UInt32)) // ALLOW_STATE_OBJECT_ADDITIONS
  let so_global_rs = @dx12.raw_alloc(8)
  @dx12.write_u64(so_global_rs, 0, rs)
  let so_shader_cfg = @dx12.raw_alloc(8)
  @dx12.write_u32(so_shader_cfg, 0, (16 : UInt32)) // MaxPayloadSizeInBytes
  @dx12.write_u32(so_shader_cfg, 4, (8 : UInt32)) // MaxAttributeSizeInBytes
  let so_pipe_cfg = @dx12.raw_alloc(8)
  @dx12.write_u32(so_pipe_cfg, 0, (1 : UInt32)) // MaxTraceRecursionDepth
  let so_subobj = @dx12.raw_alloc(80)
  @dx12.write_u32(so_subobj, 0, (0 : UInt32)) // STATE_OBJECT_CONFIG
  @dx12.write_u64(so_subobj, 8, so_cfg)
  @dx12.write_u32(so_subobj, 16, (1 : UInt32)) // GLOBAL_ROOT_SIGNATURE
  @dx12.write_u64(so_subobj, 24, so_global_rs)
  @dx12.write_u32(so_subobj, 32, (5 : UInt32)) // DXIL_LIBRARY
  @dx12.write_u64(so_subobj, 40, dxil_lib_desc)
  @dx12.write_u32(so_subobj, 48, (9 : UInt32)) // RAYTRACING_SHADER_CONFIG
  @dx12.write_u64(so_subobj, 56, so_shader_cfg)
  @dx12.write_u32(so_subobj, 64, (10 : UInt32)) // RAYTRACING_PIPELINE_CONFIG
  @dx12.write_u64(so_subobj, 72, so_pipe_cfg)
  let rt_so_desc = @dx12.raw_alloc(16)
  @dx12.write_u32(rt_so_desc, 0, (3 : UInt32)) // RAYTRACING_PIPELINE
  @dx12.write_u32(rt_so_desc, 4, (5 : UInt32))
  @dx12.write_u64(rt_so_desc, 8, so_subobj)

  let rt_add_subobj = @dx12.raw_alloc(64)
  @dx12.write_u32(rt_add_subobj, 0, (0 : UInt32)) // STATE_OBJECT_CONFIG
  @dx12.write_u64(rt_add_subobj, 8, so_cfg)
  @dx12.write_u32(rt_add_subobj, 16, (1 : UInt32)) // GLOBAL_ROOT_SIGNATURE
  @dx12.write_u64(rt_add_subobj, 24, so_global_rs)
  @dx12.write_u32(rt_add_subobj, 32, (9 : UInt32)) // RAYTRACING_SHADER_CONFIG
  @dx12.write_u64(rt_add_subobj, 40, so_shader_cfg)
  @dx12.write_u32(rt_add_subobj, 48, (10 : UInt32)) // RAYTRACING_PIPELINE_CONFIG
  @dx12.write_u64(rt_add_subobj, 56, so_pipe_cfg)
  let rt_add_desc = @dx12.raw_alloc(16)
  @dx12.write_u32(rt_add_desc, 0, (3 : UInt32)) // RAYTRACING_PIPELINE
  @dx12.write_u32(rt_add_desc, 4, (4 : UInt32))
  @dx12.write_u64(rt_add_desc, 8, rt_add_subobj)

  let mut rt_so : UInt64 = (0 : UInt64)
  if rt_tier > 0 {
    @dx12.write_u64(out_ptr, 0, (0 : UInt64))
    if @dx12.dx_d3d12_device5_create_state_object(raw_dev, rt_so_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_state_object), out_ptr) == 0 {
      rt_so = @dx12.read_u64(out_ptr, 0)
    }
  }

  let cache_desc = @dx12.raw_alloc(48)
  @dx12.write_u32(cache_desc, 0, (0x11223344 : UInt32)) // non-zero Identifier GUID
  @dx12.write_u32(cache_desc, 16, (0 : UInt32)) // MEMORY mode
  @dx12.write_u32(cache_desc, 24, (65536 : UInt32))
  @dx12.write_u32(cache_desc, 28, (64 : UInt32))
  @dx12.write_u64(cache_desc, 40, (1 : UInt64))

  let ctx : DeviceCtx = {
    raw_dev, scratch, out_ptr, priv_guid, priv_val, priv_sz, name_w,
    q_desc, rs_blob, rs_len, rs, gpsd, cpsd, stream_desc, ca, dh_desc,
    heap_default, buf_desc, tex_desc, tex_desc1, tiled_desc, tiled_desc1, heap_desc,
    cbv_desc, srv_desc, uav_desc, samp_desc, samp2_desc,
    cpu_cbv, cpu_srv, cpu_uav, cpu_rtv, cpu_dsv, cpu_samp, cpu_arr, sz_arr,
    buf_def, buf_uav, tex_rt, tex_ds, heap_obj, res_arr, prio_arr,
    qh_desc, csig_desc, fence, fence_arr, val_arr, ev, arch_buf,
    reserved_res, rt_inputs, rt_prebuild, rt_ident, rt_so_desc, rt_add_desc, rt_so,
    cache_desc, rt_tier, probed, fence_seq: (0 : Int64),
  }

  // --- 3. Probe singletons, objects, and full ID3D12Device0..14 chain ---
  probe_singletons(raw_dev, rs_desc_v11, rs_blob, rs_len, scratch, out_ptr, probed)
  probe_objects(ctx, queue, rs_blob_obj, lib_pso)
  probe_device_chain(ctx)

  // --- 4. Cleanup ---
  ignore(name_utf16)
  ignore(exp_name_utf16)
  if rt_so != (0 : UInt64) { let _ = @dx12.com_release(rt_so) }
  if lib_pso != (0 : UInt64) { let _ = @dx12.com_release(lib_pso) }
  if reserved_res != (0 : UInt64) { let _ = @dx12.com_release(reserved_res) }
  if dh_srv_cpu != (0 : UInt64) { let _ = @dx12.com_release(dh_srv_cpu) }
  if dh_samp != (0 : UInt64) { let _ = @dx12.com_release(dh_samp) }
  if dh_rtv != (0 : UInt64) { let _ = @dx12.com_release(dh_rtv) }
  if dh_dsv != (0 : UInt64) { let _ = @dx12.com_release(dh_dsv) }
  if heap_obj != (0 : UInt64) { let _ = @dx12.com_release(heap_obj) }
  if tex_ds != (0 : UInt64) { let _ = @dx12.com_release(tex_ds) }
  if tex_rt != (0 : UInt64) { let _ = @dx12.com_release(tex_rt) }
  if buf_uav != (0 : UInt64) { let _ = @dx12.com_release(buf_uav) }
  if buf_def != (0 : UInt64) { let _ = @dx12.com_release(buf_def) }
  if rs != (0 : UInt64) { let _ = @dx12.com_release(rs) }
  if fence != (0 : UInt64) { let _ = @dx12.com_release(fence) }
  if ca != (0 : UInt64) { let _ = @dx12.com_release(ca) }
  if queue != (0 : UInt64) { let _ = @dx12.com_release(queue) }
  let _ = @dx12.com_release(rs_blob_obj)

  @dx12.close_handle(ev)
  @dx12.raw_free(cache_desc)
  @dx12.raw_free(rt_add_desc)
  @dx12.raw_free(rt_add_subobj)
  @dx12.raw_free(rt_so_desc)
  @dx12.raw_free(so_subobj)
  @dx12.raw_free(so_pipe_cfg)
  @dx12.raw_free(so_shader_cfg)
  @dx12.raw_free(so_global_rs)
  @dx12.raw_free(so_cfg)
  @dx12.raw_free(dxil_lib_desc)
  @dx12.raw_free(exp_desc)
  @dx12.raw_free(rt_ident)
  @dx12.raw_free(rt_prebuild)
  @dx12.raw_free(rt_inputs)
  @dx12.raw_free(arch_buf)
  @dx12.raw_free(val_arr)
  @dx12.raw_free(fence_arr)
  @dx12.raw_free(prio_arr)
  @dx12.raw_free(res_arr)
  @dx12.raw_free(csig_desc)
  @dx12.raw_free(arg_desc)
  @dx12.raw_free(qh_desc)
  @dx12.raw_free(samp2_desc)
  @dx12.raw_free(samp_desc)
  @dx12.raw_free(uav_desc)
  @dx12.raw_free(srv_desc)
  @dx12.raw_free(cbv_desc)
  @dx12.raw_free(sz_arr)
  @dx12.raw_free(cpu_arr)
  @dx12.raw_free(cpu_h)
  @dx12.raw_free(dh_cpu_desc)
  @dx12.raw_free(dh_desc)
  @dx12.raw_free(heap_desc)
  @dx12.raw_free(tiled_desc1)
  @dx12.raw_free(tiled_desc)
  @dx12.raw_free(ds_desc)
  @dx12.raw_free(tex_desc1)
  @dx12.raw_free(tex_desc)
  @dx12.raw_free(buf_desc)
  @dx12.raw_free(heap_default)
  @dx12.raw_free(stream_desc)
  @dx12.raw_free(stream_buf)
  @dx12.raw_free(gpsd)
  @dx12.raw_free(cpsd)
  @dx12.raw_free(lib_bytes)
  @dx12.raw_free(ps_bytes)
  @dx12.raw_free(vs_bytes)
  @dx12.raw_free(cs_bytes)
  @dx12.raw_free(q_desc)
  @dx12.raw_free(rs_desc_v11)
  @dx12.raw_free(priv_sz)
  @dx12.raw_free(priv_val)
  @dx12.raw_free(scratch)
  @dx12.raw_free(err_ptr)
  @dx12.raw_free(out_ptr)

  let errs = device.validation_errors()
  let adapter = if device.is_warp() { "warp" } else { "hardware" }
  device.destroy()
  if ok && errs == 0 {
    println(
      "[dx12/raw-device-all] OK — commands=\{probed.val} generated D3D12 device, object, singleton & free entry calls verified (adapter=\{adapter}), 0 validation errors",
    )
  } else {
    println("[dx12/raw-device-all] FAIL — ok=\{ok} errs=\{errs} commands=\{probed.val}")
  }
}
