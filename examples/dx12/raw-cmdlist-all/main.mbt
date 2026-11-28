// dx12/raw-cmdlist-all — exercises ID3D12GraphicsCommandList..ID3D12GraphicsCommandList10
// through the generated dx_* COM dispatch layer under the debug layer with 0 errors.
// Non-Windows hosts SKIP cleanly.

///|
fn main {
  if !@dx12.available() {
    println("[dx12/raw-cmdlist-all] SKIP — d3d12.dll / dxgi.dll not loadable on this host")
    return
  }
  let device = match @dx12.Device::create(warp=@dx12.env_requests_warp(), debug=true) {
    Some(d) => d
    None =>
      match @dx12.Device::create(warp=true, debug=true) {
        Some(d) => d
        None => {
          println("[dx12/raw-cmdlist-all] FAIL — no D3D12 device")
          return
        }
      }
  }
  let raw_dev = device.raw()
  let probed : Ref[Int] = Ref(0)
  let ok = true

  let out_ptr = @dx12.raw_alloc(16)
  let err_ptr = @dx12.raw_alloc(16)
  let scratch = @dx12.raw_alloc(16384)
  let priv_val = @dx12.raw_alloc(16)
  @dx12.write_u32(priv_val, 0, (11 : UInt32))
  let priv_sz = @dx12.raw_alloc(8)
  let priv_guid = @dx12.bytes_ptr(@dx12.iid_d3d12_object)
  let name_utf16 = @dx12.to_utf16("tycho_raw_cmdlist_all")
  let name_w = @dx12.bytes_ptr(name_utf16)

  // --- 1. Feature checks for optional List1..List10 commands ---
  let opt1 = @dx12.raw_alloc(16)
  let _ = @dx12.dx_d3d12_device_check_feature_support(raw_dev, 1, opt1, 16)
  let can_uma = @dx12.read_u32(opt1, 8) != (0 : UInt32)

  let opt2 = @dx12.raw_alloc(8)
  let _ = @dx12.dx_d3d12_device_check_feature_support(raw_dev, 18, opt2, 8)
  let can_depth_bounds = @dx12.read_u32(opt2, 0) != (0 : UInt32)
  let can_sample_pos = @dx12.read_u32(opt2, 4) != (0 : UInt32)

  let opt3 = @dx12.raw_alloc(20)
  let _ = @dx12.dx_d3d12_device_check_feature_support(raw_dev, 21, opt3, 20)
  let can_wbi = (@dx12.read_u32(opt3, 8) & (1 : UInt32)) != (0 : UInt32)
  let can_view_inst = @dx12.read_u32(opt3, 12) != (0 : UInt32)

  let opt5 = @dx12.raw_alloc(12)
  let _ = @dx12.dx_d3d12_device_check_feature_support(raw_dev, 27, opt5, 12)
  let can_rt = @dx12.read_u32(opt5, 8) != (0 : UInt32)

  let opt6 = @dx12.raw_alloc(20)
  let _ = @dx12.dx_d3d12_device_check_feature_support(raw_dev, 30, opt6, 20)
  let vrs_tier = @dx12.read_u32(opt6, 8).reinterpret_as_int()

  let opt12 = @dx12.raw_alloc(12)
  let _ = @dx12.dx_d3d12_device_check_feature_support(raw_dev, 41, opt12, 12)
  let can_eb = @dx12.read_u32(opt12, 4) != (0 : UInt32)

  let opt14 = @dx12.raw_alloc(12)
  let _ = @dx12.dx_d3d12_device_check_feature_support(raw_dev, 43, opt14, 12)
  let can_stencil_ref = @dx12.read_u32(opt14, 8) != (0 : UInt32)

  let opt15 = @dx12.raw_alloc(8)
  let _ = @dx12.dx_d3d12_device_check_feature_support(raw_dev, 44, opt15, 8)
  let can_dyn_cut = @dx12.read_u32(opt15, 4) != (0 : UInt32)

  let opt16 = @dx12.raw_alloc(8)
  let _ = @dx12.dx_d3d12_device_check_feature_support(raw_dev, 45, opt16, 8)
  let can_dyn_bias = @dx12.read_u32(opt16, 0) != (0 : UInt32)

  // --- 2. 5-slot Root Signature: [0]=SRV Table(t0), [1]=32bit(b0), [2]=CBV(b1), [3]=SRV(t1), [4]=UAV(u0) ---
  let desc_range = @dx12.raw_alloc(24) // SRV(0), 1 descriptor, t0
  @dx12.write_u32(desc_range, 4, (1 : UInt32)) // NumDescriptors = 1

  let rp = @dx12.raw_alloc(160) // 5 * 32 bytes
  // [0] DESCRIPTOR_TABLE
  @dx12.write_u32(rp, 0, (0 : UInt32))
  @dx12.write_u32(rp, 8, (1 : UInt32))
  @dx12.write_u64(rp, 16, desc_range)
  // [1] 32BIT_CONSTANTS (b0, 2 ints)
  @dx12.write_u32(rp, 32, (1 : UInt32))
  @dx12.write_u32(rp, 40, (0 : UInt32))
  @dx12.write_u32(rp, 48, (2 : UInt32))
  // [2] CBV (b1)
  @dx12.write_u32(rp, 64, (2 : UInt32))
  @dx12.write_u32(rp, 72, (1 : UInt32))
  // [3] SRV (t1)
  @dx12.write_u32(rp, 96, (3 : UInt32))
  @dx12.write_u32(rp, 104, (1 : UInt32))
  // [4] UAV (u0)
  @dx12.write_u32(rp, 128, (4 : UInt32))
  @dx12.write_u32(rp, 136, (0 : UInt32))

  let rs_desc = @dx12.raw_alloc(48)
  @dx12.write_u32(rs_desc, 0, (2 : UInt32)) // v1.1
  @dx12.write_u32(rs_desc, 8, (5 : UInt32))
  @dx12.write_u64(rs_desc, 16, rp)
  @dx12.write_u32(rs_desc, 40, (1 : UInt32)) // ALLOW_INPUT_ASSEMBLER_INPUT_LAYOUT
  @dx12.write_u64(out_ptr, 0, (0 : UInt64))
  @dx12.write_u64(err_ptr, 0, (0 : UInt64))
  let _ = @dx12.d3d12_serialize_versioned_root_signature(rs_desc, out_ptr, err_ptr)
  let rs_blob = @dx12.read_u64(out_ptr, 0)
  if @dx12.read_u64(err_ptr, 0) != (0 : UInt64) { let _ = @dx12.com_release(@dx12.read_u64(err_ptr, 0)) }
  let rs_ptr = @dx12.dx_id3_d10_blob_get_buffer_pointer(rs_blob)
  let rs_len = @dx12.dx_id3_d10_blob_get_buffer_size(rs_blob)
  @dx12.write_u64(out_ptr, 0, (0 : UInt64))
  let _ = @dx12.dx_d3d12_device_create_root_signature(raw_dev, 0, rs_ptr, rs_len, @dx12.bytes_ptr(@dx12.iid_d3d12_root_signature), out_ptr)
  let rs = @dx12.read_u64(out_ptr, 0)
  let _ = @dx12.com_release(rs_blob)

  // --- 3. Pipelines (GPSO + CPSO) ---
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
  @dx12.write_u64(out_ptr, 0, (0 : UInt64))
  let _ = @dx12.dx_d3d12_device_create_compute_pipeline_state(raw_dev, cpsd, @dx12.bytes_ptr(@dx12.iid_d3d12_pipeline_state), out_ptr)
  let cpso = @dx12.read_u64(out_ptr, 0)

  let gpsd = @dx12.raw_alloc(656)
  @dx12.write_u64(gpsd, 0, rs)
  @dx12.write_u64(gpsd, 8, vs_bytes)
  @dx12.write_u64(gpsd, 16, mini_vs_dxil_bytes.to_uint64())
  @dx12.write_u64(gpsd, 24, ps_bytes)
  @dx12.write_u64(gpsd, 32, mini_ps_dxil_bytes.to_uint64())
  @dx12.write_u32(gpsd, 164, (0xF : UInt32))
  @dx12.write_u32(gpsd, 448, (0xFFFFFFFF : UInt32))
  @dx12.write_u32(gpsd, 452, (3 : UInt32))
  @dx12.write_u32(gpsd, 456, (1 : UInt32))
  @dx12.write_u32(gpsd, 572, (3 : UInt32)) // TRIANGLE
  @dx12.write_u32(gpsd, 576, (1 : UInt32))
  @dx12.write_u32(gpsd, 580, (28 : UInt32)) // R8G8B8A8_UNORM
  @dx12.write_u32(gpsd, 612, (40 : UInt32)) // DSVFormat = D32_FLOAT
  @dx12.write_u32(gpsd, 616, (1 : UInt32))
  @dx12.write_u64(out_ptr, 0, (0 : UInt64))
  let _ = @dx12.dx_d3d12_device_create_graphics_pipeline_state(raw_dev, gpsd, @dx12.bytes_ptr(@dx12.iid_d3d12_pipeline_state), out_ptr)
  let gpso = @dx12.read_u64(out_ptr, 0)

  // --- 4. Allocators & Command Lists (Direct + Bundle) ---
  @dx12.write_u64(out_ptr, 0, (0 : UInt64))
  let _ = @dx12.dx_d3d12_device_create_command_allocator(raw_dev, 0, @dx12.bytes_ptr(@dx12.iid_d3d12_command_allocator), out_ptr)
  let ca = @dx12.read_u64(out_ptr, 0)
  @dx12.write_u64(out_ptr, 0, (0 : UInt64))
  let _ = @dx12.dx_d3d12_device_create_command_list(raw_dev, 0, 0, ca, gpso, @dx12.bytes_ptr(@dx12.iid_d3d12_graphics_command_list), out_ptr)
  let cl_base = @dx12.read_u64(out_ptr, 0)

  @dx12.write_u64(out_ptr, 0, (0 : UInt64))
  let _ = @dx12.dx_d3d12_device_create_command_allocator(raw_dev, 1, @dx12.bytes_ptr(@dx12.iid_d3d12_command_allocator), out_ptr)
  let bundle_ca = @dx12.read_u64(out_ptr, 0)
  @dx12.write_u64(out_ptr, 0, (0 : UInt64))
  let _ = @dx12.dx_d3d12_device_create_command_list(raw_dev, 0, 1, bundle_ca, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_graphics_command_list), out_ptr)
  let bundle_cl = @dx12.read_u64(out_ptr, 0)
  let _ = @dx12.dx_d3d12_graphics_command_list_close(bundle_cl)

  // --- 5. Buffers & Textures ---
  let heap_def = @dx12.raw_alloc(32)
  @dx12.write_u32(heap_def, 0, (1 : UInt32))
  @dx12.write_u32(heap_def, 12, (1 : UInt32))
  @dx12.write_u32(heap_def, 16, (1 : UInt32))
  let heap_up = @dx12.raw_alloc(32)
  @dx12.write_u32(heap_up, 0, (2 : UInt32))
  @dx12.write_u32(heap_up, 12, (1 : UInt32))
  @dx12.write_u32(heap_up, 16, (1 : UInt32))
  let heap_rb = @dx12.raw_alloc(32)
  @dx12.write_u32(heap_rb, 0, (3 : UInt32))
  @dx12.write_u32(heap_rb, 12, (1 : UInt32))
  @dx12.write_u32(heap_rb, 16, (1 : UInt32))

  let buf_desc = @dx12.raw_alloc(64)
  @dx12.write_u32(buf_desc, 0, (1 : UInt32)) // BUFFER
  @dx12.write_u64(buf_desc, 16, (65536 : UInt64))
  @dx12.write_u32(buf_desc, 24, (1 : UInt32))
  @dx12.write_u32(buf_desc, 28, (0x00010001 : UInt32))
  @dx12.write_u32(buf_desc, 36, (1 : UInt32))
  @dx12.write_u32(buf_desc, 44, (1 : UInt32))

  @dx12.write_u64(out_ptr, 0, (0 : UInt64))
  let _ = @dx12.dx_d3d12_device_create_committed_resource(raw_dev, heap_up, 0, buf_desc, 0xAC3, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), out_ptr)
  let buf_src = @dx12.read_u64(out_ptr, 0)
  // Populate DrawArgs at offset 0 on buf_src
  @dx12.write_u64(out_ptr, 0, (0 : UInt64))
  if @dx12.dx_d3d12_resource_map(buf_src, 0, (0 : UInt64), out_ptr) == 0 {
    let mp = @dx12.read_u64(out_ptr, 0)
    @dx12.write_u32(mp, 0, (3 : UInt32)) // VertexCountPerInstance = 3
    @dx12.write_u32(mp, 4, (1 : UInt32)) // InstanceCount = 1
    @dx12.dx_d3d12_resource_unmap(buf_src, 0, (0 : UInt64))
  }

  @dx12.write_u64(out_ptr, 0, (0 : UInt64))
  let _ = @dx12.dx_d3d12_device_create_committed_resource(raw_dev, heap_rb, 0, buf_desc, 0x400, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), out_ptr)
  let buf_rb = @dx12.read_u64(out_ptr, 0)

  @dx12.write_u32(buf_desc, 48, (4 : UInt32)) // ALLOW_UNORDERED_ACCESS
  @dx12.write_u64(out_ptr, 0, (0 : UInt64))
  let _ = @dx12.dx_d3d12_device_create_committed_resource(raw_dev, heap_def, 0, buf_desc, 0x400, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), out_ptr)
  let buf_dst = @dx12.read_u64(out_ptr, 0)
  @dx12.write_u64(out_ptr, 0, (0 : UInt64))
  let _ = @dx12.dx_d3d12_device_create_committed_resource(raw_dev, heap_def, 0, buf_desc, 0x8, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), out_ptr)
  let buf_uav = @dx12.read_u64(out_ptr, 0)
  @dx12.write_u64(out_ptr, 0, (0 : UInt64))
  let _ = @dx12.dx_d3d12_device_create_committed_resource(raw_dev, heap_def, 0, buf_desc, 0x8, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), out_ptr)
  let buf_post = @dx12.read_u64(out_ptr, 0)

  let tex_desc = @dx12.raw_alloc(64)
  @dx12.write_u32(tex_desc, 0, (3 : UInt32))
  @dx12.write_u64(tex_desc, 16, (64 : UInt64))
  @dx12.write_u32(tex_desc, 24, (64 : UInt32))
  @dx12.write_u32(tex_desc, 28, (0x00010001 : UInt32))
  @dx12.write_u32(tex_desc, 32, (28 : UInt32)) // R8G8B8A8_UNORM
  @dx12.write_u32(tex_desc, 36, (1 : UInt32))
  @dx12.write_u32(tex_desc, 48, (1 : UInt32)) // ALLOW_RENDER_TARGET
  @dx12.write_u64(out_ptr, 0, (0 : UInt64))
  let _ = @dx12.dx_d3d12_device_create_committed_resource(raw_dev, heap_def, 0, tex_desc, 0x4, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), out_ptr)
  let tex_rt = @dx12.read_u64(out_ptr, 0)

  @dx12.write_u32(tex_desc, 48, (0 : UInt32))
  @dx12.write_u64(out_ptr, 0, (0 : UInt64))
  let _ = @dx12.dx_d3d12_device_create_committed_resource(raw_dev, heap_def, 0, tex_desc, 0x400, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), out_ptr)
  let tex_res_dst = @dx12.read_u64(out_ptr, 0)

  @dx12.write_u32(tex_desc, 36, (4 : UInt32)) // MSAA 4x
  @dx12.write_u32(tex_desc, 48, (1 : UInt32))
  @dx12.write_u64(out_ptr, 0, (0 : UInt64))
  let _ = @dx12.dx_d3d12_device_create_committed_resource(raw_dev, heap_def, 0, tex_desc, 0x2000, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), out_ptr)
  let tex_msaa = @dx12.read_u64(out_ptr, 0)

  @dx12.write_u32(tex_desc, 36, (1 : UInt32))
  @dx12.write_u32(tex_desc, 32, (40 : UInt32)) // D32_FLOAT
  @dx12.write_u32(tex_desc, 48, (2 : UInt32)) // ALLOW_DEPTH_STENCIL
  @dx12.write_u64(out_ptr, 0, (0 : UInt64))
  let _ = @dx12.dx_d3d12_device_create_committed_resource(raw_dev, heap_def, 0, tex_desc, 0x10, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), out_ptr)
  let tex_ds = @dx12.read_u64(out_ptr, 0)

  @dx12.write_u32(tex_desc, 32, (42 : UInt32)) // R32_UINT
  @dx12.write_u32(tex_desc, 48, (4 : UInt32)) // ALLOW_UNORDERED_ACCESS
  @dx12.write_u64(out_ptr, 0, (0 : UInt64))
  let _ = @dx12.dx_d3d12_device_create_committed_resource(raw_dev, heap_def, 0, tex_desc, 0x8, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), out_ptr)
  let tex_uav_u32 = @dx12.read_u64(out_ptr, 0)

  @dx12.write_u32(tex_desc, 32, (41 : UInt32)) // R32_FLOAT
  @dx12.write_u64(out_ptr, 0, (0 : UInt64))
  let _ = @dx12.dx_d3d12_device_create_committed_resource(raw_dev, heap_def, 0, tex_desc, 0x8, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), out_ptr)
  let tex_uav_flt = @dx12.read_u64(out_ptr, 0)

  // --- 6. Descriptor heaps + views ---
  let dh_desc = @dx12.raw_alloc(16)
  @dx12.write_u32(dh_desc, 0, (0 : UInt32))
  @dx12.write_u32(dh_desc, 4, (4 : UInt32))
  @dx12.write_u32(dh_desc, 8, (1 : UInt32)) // SHADER_VISIBLE
  @dx12.write_u64(out_ptr, 0, (0 : UInt64))
  let _ = @dx12.dx_d3d12_device_create_descriptor_heap(raw_dev, dh_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_descriptor_heap), out_ptr)
  let dh_gpu = @dx12.read_u64(out_ptr, 0)

  @dx12.write_u32(dh_desc, 8, (0 : UInt32)) // CPU only
  @dx12.write_u64(out_ptr, 0, (0 : UInt64))
  let _ = @dx12.dx_d3d12_device_create_descriptor_heap(raw_dev, dh_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_descriptor_heap), out_ptr)
  let dh_cpu = @dx12.read_u64(out_ptr, 0)

  @dx12.write_u32(dh_desc, 0, (2 : UInt32)) // RTV
  @dx12.write_u64(out_ptr, 0, (0 : UInt64))
  let _ = @dx12.dx_d3d12_device_create_descriptor_heap(raw_dev, dh_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_descriptor_heap), out_ptr)
  let dh_rtv = @dx12.read_u64(out_ptr, 0)

  @dx12.write_u32(dh_desc, 0, (3 : UInt32)) // DSV
  @dx12.write_u64(out_ptr, 0, (0 : UInt64))
  let _ = @dx12.dx_d3d12_device_create_descriptor_heap(raw_dev, dh_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_descriptor_heap), out_ptr)
  let dh_dsv = @dx12.read_u64(out_ptr, 0)

  let inc_srv = @dx12.dx_d3d12_device_get_descriptor_handle_increment_size(raw_dev, 0).to_uint64()
  let tmp_h = @dx12.raw_alloc(8)
  let _ = @dx12.dx_d3d12_descriptor_heap_get_cpu_descriptor_handle_for_heap_start(dh_gpu, tmp_h)
  let g_cpu0 = @dx12.read_u64(tmp_h, 0)
  let _ = @dx12.dx_d3d12_descriptor_heap_get_gpu_descriptor_handle_for_heap_start(dh_gpu, tmp_h)
  let g_gpu0 = @dx12.read_u64(tmp_h, 0)
  let _ = @dx12.dx_d3d12_descriptor_heap_get_cpu_descriptor_handle_for_heap_start(dh_cpu, tmp_h)
  let c_cpu0 = @dx12.read_u64(tmp_h, 0)
  let _ = @dx12.dx_d3d12_descriptor_heap_get_cpu_descriptor_handle_for_heap_start(dh_rtv, tmp_h)
  let h_rtv = @dx12.read_u64(tmp_h, 0)
  let _ = @dx12.dx_d3d12_descriptor_heap_get_cpu_descriptor_handle_for_heap_start(dh_dsv, tmp_h)
  let h_dsv = @dx12.read_u64(tmp_h, 0)

  // Slots: [0]=g_cpu0, [1]=g_gpu0, [2]=g_gpu_uav_u32, [3]=c_cpu_uav_u32, [4]=g_gpu_uav_flt, [5]=c_cpu_uav_flt, [6]=h_rtv, [7]=h_dsv, [8]=g_cpu_uav_u32, [9]=g_cpu_uav_flt
  let slots = @dx12.raw_alloc(80)
  @dx12.write_u64(slots, 0, g_cpu0)
  @dx12.write_u64(slots, 8, g_gpu0)
  @dx12.write_u64(slots, 16, g_gpu0 + inc_srv)
  @dx12.write_u64(slots, 24, c_cpu0 + inc_srv)
  @dx12.write_u64(slots, 32, g_gpu0 + inc_srv * (2 : UInt64))
  @dx12.write_u64(slots, 40, c_cpu0 + inc_srv * (2 : UInt64))
  @dx12.write_u64(slots, 48, h_rtv)
  @dx12.write_u64(slots, 56, h_dsv)
  @dx12.write_u64(slots, 64, g_cpu0 + inc_srv)
  @dx12.write_u64(slots, 72, g_cpu0 + inc_srv * (2 : UInt64))

  let srv_desc = @dx12.raw_alloc(40)
  @dx12.write_u32(srv_desc, 4, (1 : UInt32)) // BUFFER
  @dx12.write_u32(srv_desc, 8, (5768 : UInt32))
  @dx12.write_u32(srv_desc, 24, (16 : UInt32))
  @dx12.write_u32(srv_desc, 28, (16 : UInt32))
  @dx12.dx_d3d12_device_create_shader_resource_view(raw_dev, buf_src, srv_desc, slots)

  // UAVs in CPU heap AND shader-visible heap
  @dx12.dx_d3d12_device_create_unordered_access_view(raw_dev, tex_uav_u32, (0 : UInt64), (0 : UInt64), slots + (24 : UInt64))
  @dx12.dx_d3d12_device_create_unordered_access_view(raw_dev, tex_uav_u32, (0 : UInt64), (0 : UInt64), slots + (64 : UInt64))
  @dx12.dx_d3d12_device_create_unordered_access_view(raw_dev, tex_uav_flt, (0 : UInt64), (0 : UInt64), slots + (40 : UInt64))
  @dx12.dx_d3d12_device_create_unordered_access_view(raw_dev, tex_uav_flt, (0 : UInt64), (0 : UInt64), slots + (72 : UInt64))
  @dx12.dx_d3d12_device_create_render_target_view(raw_dev, tex_rt, (0 : UInt64), slots + (48 : UInt64))
  @dx12.dx_d3d12_device_create_depth_stencil_view(raw_dev, tex_ds, (0 : UInt64), slots + (56 : UInt64))

  // --- 7. Viewports, scissors, views, queries, barriers, RP, RT ---
  let dh_gpu_arr = @dx12.raw_alloc(8)
  @dx12.write_u64(dh_gpu_arr, 0, dh_gpu)
  let vp_buf = @dx12.raw_alloc(24)
  @dx12.write_u32(vp_buf, 8, (0x42800000 : UInt32)) // 64.0f
  @dx12.write_u32(vp_buf, 12, (0x42800000 : UInt32)) // 64.0f
  @dx12.write_u32(vp_buf, 20, (0x3F800000 : UInt32)) // MaxDepth = 1.0f
  let rect_buf = @dx12.raw_alloc(16)
  @dx12.write_u32(rect_buf, 8, (64 : UInt32))
  @dx12.write_u32(rect_buf, 12, (64 : UInt32))
  let blend_buf = @dx12.raw_alloc(16)
  let rgba_buf = @dx12.raw_alloc(16)
  let u32_clr = @dx12.raw_alloc(16)
  let flt_clr = @dx12.raw_alloc(16)
  let const32 = @dx12.raw_alloc(8)

  let va_cbv = @dx12.dx_d3d12_resource_get_gpu_virtual_address(buf_src)
  let va_srv = va_cbv
  let va_uav = @dx12.dx_d3d12_resource_get_gpu_virtual_address(buf_uav)

  let vbv_buf = @dx12.raw_alloc(16)
  @dx12.write_u64(vbv_buf, 0, va_cbv.reinterpret_as_uint64())
  @dx12.write_u32(vbv_buf, 8, (256 : UInt32))
  @dx12.write_u32(vbv_buf, 12, (16 : UInt32))
  let ibv_buf = @dx12.raw_alloc(16)
  @dx12.write_u64(ibv_buf, 0, va_cbv.reinterpret_as_uint64())
  @dx12.write_u32(ibv_buf, 8, (256 : UInt32))
  @dx12.write_u32(ibv_buf, 12, (42 : UInt32)) // R32_UINT

  // Texture copy locations (48B each): src = PlacedFootprint on buf_src, dst = SubresourceIndex(0) on tex_res_dst
  let tcl_src = @dx12.raw_alloc(48)
  @dx12.write_u64(tcl_src, 0, buf_src)
  @dx12.write_u32(tcl_src, 8, (1 : UInt32)) // PLACED_FOOTPRINT
  @dx12.write_u32(tcl_src, 24, (28 : UInt32)) // R8G8B8A8_UNORM
  @dx12.write_u32(tcl_src, 28, (64 : UInt32))
  @dx12.write_u32(tcl_src, 32, (64 : UInt32))
  @dx12.write_u32(tcl_src, 36, (1 : UInt32))
  @dx12.write_u32(tcl_src, 40, (256 : UInt32)) // RowPitch

  let tcl_dst = @dx12.raw_alloc(48)
  @dx12.write_u64(tcl_dst, 0, tex_res_dst)
  @dx12.write_u32(tcl_dst, 8, (0 : UInt32)) // SUBRESOURCE_INDEX

  // Barriers
  let bar_rt_to_copy = @dx12.raw_alloc(32)
  @dx12.write_u64(bar_rt_to_copy, 8, tex_rt)
  @dx12.write_u32(bar_rt_to_copy, 16, (0xFFFFFFFF : UInt32))
  @dx12.write_u32(bar_rt_to_copy, 20, (0x4 : UInt32)) // RENDER_TARGET
  @dx12.write_u32(bar_rt_to_copy, 24, (0x800 : UInt32)) // COPY_SOURCE

  let bar_to_resolve = @dx12.raw_alloc(64)
  @dx12.write_u64(bar_to_resolve, 8, tex_rt)
  @dx12.write_u32(bar_to_resolve, 16, (0xFFFFFFFF : UInt32))
  @dx12.write_u32(bar_to_resolve, 20, (0x800 : UInt32))
  @dx12.write_u32(bar_to_resolve, 24, (0x4 : UInt32))
  @dx12.write_u64(bar_to_resolve, 40, tex_res_dst)
  @dx12.write_u32(bar_to_resolve, 48, (0xFFFFFFFF : UInt32))
  @dx12.write_u32(bar_to_resolve, 52, (0x400 : UInt32)) // COPY_DEST
  @dx12.write_u32(bar_to_resolve, 56, (0x1000 : UInt32)) // RESOLVE_DEST

  let bar_resolve_to_copy = @dx12.raw_alloc(32)
  @dx12.write_u64(bar_resolve_to_copy, 8, tex_res_dst)
  @dx12.write_u32(bar_resolve_to_copy, 16, (0xFFFFFFFF : UInt32))
  @dx12.write_u32(bar_resolve_to_copy, 20, (0x1000 : UInt32))
  @dx12.write_u32(bar_resolve_to_copy, 24, (0x400 : UInt32))

  let qh_desc = @dx12.raw_alloc(16) // OCCLUSION(0), Count=2
  @dx12.write_u32(qh_desc, 4, (2 : UInt32))
  @dx12.write_u64(out_ptr, 0, (0 : UInt64))
  let _ = @dx12.dx_d3d12_device_create_query_heap(raw_dev, qh_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_query_heap), out_ptr)
  let qh_occ = @dx12.read_u64(out_ptr, 0)

  let arg_draw = @dx12.raw_alloc(16) // DRAW(0)
  let csig_desc = @dx12.raw_alloc(24)
  @dx12.write_u32(csig_desc, 0, (16 : UInt32))
  @dx12.write_u32(csig_desc, 4, (1 : UInt32))
  @dx12.write_u64(csig_desc, 8, arg_draw)
  @dx12.write_u64(out_ptr, 0, (0 : UInt64))
  let _ = @dx12.dx_d3d12_device_create_command_signature(raw_dev, csig_desc, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_command_signature), out_ptr)
  let csig_draw = @dx12.read_u64(out_ptr, 0)

  let wbi_param = @dx12.raw_alloc(16)
  @dx12.write_u64(wbi_param, 0, @dx12.dx_d3d12_resource_get_gpu_virtual_address(buf_dst).reinterpret_as_uint64())
  @dx12.write_u32(wbi_param, 8, (0xCAFEBABE : UInt32))
  let wbi_mode = @dx12.raw_alloc(8)

  let rp_rt = @dx12.raw_alloc(88)
  @dx12.write_u64(rp_rt, 0, h_rtv)
  @dx12.write_u32(rp_rt, 8, (1 : UInt32)) // PRESERVE
  @dx12.write_u32(rp_rt, 32, (1 : UInt32)) // PRESERVE

  // Raytracing TLAS + SO (optional on can_rt)
  let rt_inputs = @dx12.raw_alloc(32) // TOP_LEVEL(0), NumDescs=0
  let rt_prebuild = @dx12.raw_alloc(32)
  @dx12.dx_d3d12_device5_get_raytracing_acceleration_structure_prebuild_info(raw_dev, rt_inputs, rt_prebuild)

  let rt_buf_desc = @dx12.raw_alloc(64)
  @dx12.write_u32(rt_buf_desc, 0, (1 : UInt32))
  @dx12.write_u64(rt_buf_desc, 16, (65536 : UInt64))
  @dx12.write_u32(rt_buf_desc, 24, (1 : UInt32))
  @dx12.write_u32(rt_buf_desc, 28, (0x00010001 : UInt32))
  @dx12.write_u32(rt_buf_desc, 36, (1 : UInt32))
  @dx12.write_u32(rt_buf_desc, 44, (1 : UInt32))
  @dx12.write_u32(rt_buf_desc, 48, (4 : UInt32))

  let mut rt_tlas_a : UInt64 = (0 : UInt64)
  let mut rt_tlas_b : UInt64 = (0 : UInt64)
  let mut rt_scratch : UInt64 = (0 : UInt64)
  let mut rt_so : UInt64 = (0 : UInt64)
  let mut rt_tlas_a_va : Int64 = (0 : Int64)
  let mut rt_tlas_b_va : Int64 = (0 : Int64)

  let exp_name = @dx12.to_utf16("rgen_main")
  let exp_desc = @dx12.raw_alloc(24)
  @dx12.write_u64(exp_desc, 0, @dx12.bytes_ptr(exp_name))
  let dxil_lib_desc = @dx12.raw_alloc(32)
  @dx12.write_u64(dxil_lib_desc, 0, lib_bytes)
  @dx12.write_u64(dxil_lib_desc, 8, mini_lib_dxil_bytes.to_uint64())
  @dx12.write_u32(dxil_lib_desc, 16, (1 : UInt32))
  @dx12.write_u64(dxil_lib_desc, 24, exp_desc)
  let so_grs = @dx12.raw_alloc(8)
  @dx12.write_u64(so_grs, 0, rs)
  let so_sh = @dx12.raw_alloc(8)
  @dx12.write_u32(so_sh, 0, (16 : UInt32))
  @dx12.write_u32(so_sh, 4, (8 : UInt32))
  let so_pp = @dx12.raw_alloc(8)
  @dx12.write_u32(so_pp, 0, (1 : UInt32))
  let so_sub = @dx12.raw_alloc(64)
  @dx12.write_u32(so_sub, 0, (1 : UInt32))
  @dx12.write_u64(so_sub, 8, so_grs)
  @dx12.write_u32(so_sub, 16, (5 : UInt32))
  @dx12.write_u64(so_sub, 24, dxil_lib_desc)
  @dx12.write_u32(so_sub, 32, (9 : UInt32))
  @dx12.write_u64(so_sub, 40, so_sh)
  @dx12.write_u32(so_sub, 48, (10 : UInt32))
  @dx12.write_u64(so_sub, 56, so_pp)
  let rt_so_desc = @dx12.raw_alloc(16)
  @dx12.write_u32(rt_so_desc, 0, (3 : UInt32))
  @dx12.write_u32(rt_so_desc, 4, (4 : UInt32))
  @dx12.write_u64(rt_so_desc, 8, so_sub)

  if can_rt {
    @dx12.write_u64(out_ptr, 0, (0 : UInt64))
    let _ = @dx12.dx_d3d12_device_create_committed_resource(raw_dev, heap_def, 0, rt_buf_desc, 0x400000, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), out_ptr)
    rt_tlas_a = @dx12.read_u64(out_ptr, 0)
    @dx12.write_u64(out_ptr, 0, (0 : UInt64))
    let _ = @dx12.dx_d3d12_device_create_committed_resource(raw_dev, heap_def, 0, rt_buf_desc, 0x400000, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), out_ptr)
    rt_tlas_b = @dx12.read_u64(out_ptr, 0)
    @dx12.write_u64(out_ptr, 0, (0 : UInt64))
    let _ = @dx12.dx_d3d12_device_create_committed_resource(raw_dev, heap_def, 0, rt_buf_desc, 0x8, (0 : UInt64), @dx12.bytes_ptr(@dx12.iid_d3d12_resource), out_ptr)
    rt_scratch = @dx12.read_u64(out_ptr, 0)
    if rt_tlas_a != (0 : UInt64) { rt_tlas_a_va = @dx12.dx_d3d12_resource_get_gpu_virtual_address(rt_tlas_a) }
    if rt_tlas_b != (0 : UInt64) { rt_tlas_b_va = @dx12.dx_d3d12_resource_get_gpu_virtual_address(rt_tlas_b) }
    @dx12.write_u64(out_ptr, 0, (0 : UInt64))
    if @dx12.dx_d3d12_device5_create_state_object(raw_dev, rt_so_desc, @dx12.bytes_ptr(@dx12.iid_d3d12_state_object), out_ptr) == 0 {
      rt_so = @dx12.read_u64(out_ptr, 0)
    }
  }

  let rt_build = @dx12.raw_alloc(48)
  @dx12.write_u64(rt_build, 0, rt_tlas_a_va.reinterpret_as_uint64())
  if rt_scratch != (0 : UInt64) {
    @dx12.write_u64(rt_build, 40, @dx12.dx_d3d12_resource_get_gpu_virtual_address(rt_scratch).reinterpret_as_uint64())
  }
  let bar_rt_uav = @dx12.raw_alloc(32)
  @dx12.write_u32(bar_rt_uav, 0, (2 : UInt32)) // UAV
  @dx12.write_u64(bar_rt_uav, 8, rt_tlas_a)
  let rt_post_desc = @dx12.raw_alloc(16)
  @dx12.write_u64(rt_post_desc, 0, @dx12.dx_d3d12_resource_get_gpu_virtual_address(buf_post).reinterpret_as_uint64())
  @dx12.write_u32(rt_post_desc, 8, (3 : UInt32)) // CURRENT_SIZE
  let rt_post_va_arr = @dx12.raw_alloc(8)
  @dx12.write_u64(rt_post_va_arr, 0, rt_tlas_a_va.reinterpret_as_uint64())

  // Enhanced Barrier global NO_ACCESS -> NO_ACCESS
  let eb_global = @dx12.raw_alloc(16)
  @dx12.write_u32(eb_global, 8, (0x80000000 : UInt32))
  @dx12.write_u32(eb_global, 12, (0x80000000 : UInt32))
  let eb_grp = @dx12.raw_alloc(16)
  @dx12.write_u32(eb_grp, 4, (1 : UInt32))
  @dx12.write_u64(eb_grp, 8, eb_global)

  let ctx : CmdCtx = {
    cl_base, ca, out_ptr, scratch, priv_guid, priv_val, priv_sz, name_w,
    rs, gpso, cpso, bundle_cl, dh_gpu_arr,
    gpu_srv_slot: slots + (8 : UInt64),
    gpu_uav_uint_slot: slots + (16 : UInt64),
    cpu_uav_uint_slot: slots + (24 : UInt64),
    gpu_uav_flt_slot: slots + (32 : UInt64),
    cpu_uav_flt_slot: slots + (40 : UInt64),
    rtv_slot: slots + (48 : UInt64),
    dsv_slot: slots + (56 : UInt64),
    vp_buf, rect_buf, blend_buf, rgba_buf, u32_clr, flt_clr, const32,
    vbv_buf, ibv_buf, buf_src, buf_dst, tex_rt, tex_msaa, tex_res_dst,
    tex_uav_u32, tex_uav_flt, tcl_src, tcl_dst, bar_rt_to_copy,
    bar_to_resolve, bar_resolve_to_copy, bar_rt_uav, qh_occ, buf_rb,
    csig_draw, wbi_param, wbi_mode, rp_rt, rt_build, rt_post_desc,
    rt_post_va_arr, rt_tlas_a_va, rt_tlas_b_va, rt_so, eb_grp,
    va_cbv, va_srv, va_uav,
    can_depth_bounds, can_sample_pos, can_view_inst, can_wbi,
    can_rt: can_rt && rt_tlas_a != (0 : UInt64) && rt_tlas_b != (0 : UInt64),
    can_uma,
    vrs_tier, can_eb, can_stencil_ref, can_dyn_cut, can_dyn_bias,
    probed,
  }

  probe_cmdlist_chain(ctx)

  // Close & release cl_base (it was Reset cleanly at the end of v10)
  let _ = @dx12.dx_d3d12_graphics_command_list_close(cl_base)

  // --- 8. Cleanup ---
  ignore(name_utf16)
  ignore(exp_name)
  let _ = device.wait_idle()
  if rt_so != (0 : UInt64) { let _ = @dx12.com_release(rt_so) }
  if rt_scratch != (0 : UInt64) { let _ = @dx12.com_release(rt_scratch) }
  if rt_tlas_b != (0 : UInt64) { let _ = @dx12.com_release(rt_tlas_b) }
  if rt_tlas_a != (0 : UInt64) { let _ = @dx12.com_release(rt_tlas_a) }
  let _ = @dx12.com_release(csig_draw)
  let _ = @dx12.com_release(qh_occ)
  let _ = @dx12.com_release(dh_dsv)
  let _ = @dx12.com_release(dh_rtv)
  let _ = @dx12.com_release(dh_cpu)
  let _ = @dx12.com_release(dh_gpu)
  let _ = @dx12.com_release(tex_uav_flt)
  let _ = @dx12.com_release(tex_uav_u32)
  let _ = @dx12.com_release(tex_ds)
  let _ = @dx12.com_release(tex_msaa)
  let _ = @dx12.com_release(tex_res_dst)
  let _ = @dx12.com_release(tex_rt)
  let _ = @dx12.com_release(buf_post)
  let _ = @dx12.com_release(buf_uav)
  let _ = @dx12.com_release(buf_dst)
  let _ = @dx12.com_release(buf_rb)
  let _ = @dx12.com_release(buf_src)
  let _ = @dx12.com_release(bundle_cl)
  let _ = @dx12.com_release(bundle_ca)
  let _ = @dx12.com_release(cl_base)
  let _ = @dx12.com_release(ca)
  let _ = @dx12.com_release(gpso)
  let _ = @dx12.com_release(cpso)
  let _ = @dx12.com_release(rs)

  @dx12.raw_free(eb_grp)
  @dx12.raw_free(eb_global)
  @dx12.raw_free(rt_post_va_arr)
  @dx12.raw_free(rt_post_desc)
  @dx12.raw_free(bar_rt_uav)
  @dx12.raw_free(rt_build)
  @dx12.raw_free(rt_so_desc)
  @dx12.raw_free(so_sub)
  @dx12.raw_free(so_pp)
  @dx12.raw_free(so_sh)
  @dx12.raw_free(so_grs)
  @dx12.raw_free(dxil_lib_desc)
  @dx12.raw_free(exp_desc)
  @dx12.raw_free(rt_buf_desc)
  @dx12.raw_free(rt_prebuild)
  @dx12.raw_free(rt_inputs)
  @dx12.raw_free(rp_rt)
  @dx12.raw_free(wbi_mode)
  @dx12.raw_free(wbi_param)
  @dx12.raw_free(csig_desc)
  @dx12.raw_free(arg_draw)
  @dx12.raw_free(qh_desc)
  @dx12.raw_free(bar_resolve_to_copy)
  @dx12.raw_free(bar_to_resolve)
  @dx12.raw_free(bar_rt_to_copy)
  @dx12.raw_free(tcl_dst)
  @dx12.raw_free(tcl_src)
  @dx12.raw_free(ibv_buf)
  @dx12.raw_free(vbv_buf)
  @dx12.raw_free(const32)
  @dx12.raw_free(flt_clr)
  @dx12.raw_free(u32_clr)
  @dx12.raw_free(rgba_buf)
  @dx12.raw_free(blend_buf)
  @dx12.raw_free(rect_buf)
  @dx12.raw_free(vp_buf)
  @dx12.raw_free(dh_gpu_arr)
  @dx12.raw_free(srv_desc)
  @dx12.raw_free(slots)
  @dx12.raw_free(tmp_h)
  @dx12.raw_free(dh_desc)
  @dx12.raw_free(tex_desc)
  @dx12.raw_free(buf_desc)
  @dx12.raw_free(heap_rb)
  @dx12.raw_free(heap_up)
  @dx12.raw_free(heap_def)
  @dx12.raw_free(gpsd)
  @dx12.raw_free(cpsd)
  @dx12.raw_free(lib_bytes)
  @dx12.raw_free(ps_bytes)
  @dx12.raw_free(vs_bytes)
  @dx12.raw_free(cs_bytes)
  @dx12.raw_free(rs_desc)
  @dx12.raw_free(rp)
  @dx12.raw_free(desc_range)
  @dx12.raw_free(opt16)
  @dx12.raw_free(opt15)
  @dx12.raw_free(opt14)
  @dx12.raw_free(opt12)
  @dx12.raw_free(opt6)
  @dx12.raw_free(opt5)
  @dx12.raw_free(opt3)
  @dx12.raw_free(opt2)
  @dx12.raw_free(opt1)
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
      "[dx12/raw-cmdlist-all] OK — commands=\{probed.val} generated D3D12 command list calls verified (adapter=\{adapter}), 0 validation errors",
    )
  } else {
    println("[dx12/raw-cmdlist-all] FAIL — ok=\{ok} errs=\{errs} commands=\{probed.val}")
  }
}
