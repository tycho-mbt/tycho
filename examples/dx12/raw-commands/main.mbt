// dx12/raw-commands — exercises the generated GraphicsCommandList recording
// thunks: resource barriers, OMSetRenderTargets, ClearRenderTargetView,
// RSSetViewports / RSSetScissorRects, IASetPrimitiveTopology, plus
// CreateCommittedResource / CreateRenderTargetView and resource queries.
//
// Commands are recorded and the list closed (not executed), which is enough to
// exercise the record-time API under the debug layer with zero validation
// errors. Structs are program-lifetime arrays so raw pointers stay valid.
// Non-Windows hosts SKIP.

///|
fn fail(what : String) -> Unit {
  println("[dx12/raw-commands] FAIL — \{what} (last HRESULT=\{@dx12.last_error()})")
}

let iid_resource : FixedArray[Byte] = [
  0xbe, 0x42, 0x64, 0x69, 0x2e, 0xa7, 0x59, 0x40, 0xbc, 0x79, 0x5b, 0x5c,
  0x98, 0x04, 0x0f, 0xad,
]

let iid_command_allocator : FixedArray[Byte] = [
  0xe4, 0xde, 0x02, 0x61, 0x59, 0xaf, 0x09, 0x4b, 0xb9, 0x99, 0xb4, 0x4d,
  0x73, 0xf0, 0x9b, 0x24,
]

let iid_graphics_command_list : FixedArray[Byte] = [
  0x0f, 0x0d, 0x16, 0x5b, 0x1b, 0xac, 0x85, 0x41, 0x8b, 0xa8, 0xb3, 0xae,
  0x42, 0xa5, 0xa4, 0x55,
]

let iid_descriptor_heap : FixedArray[Byte] = [
  0x1d, 0x47, 0xfb, 0x8e, 0x6c, 0x61, 0x49, 0x4f, 0x90, 0xf7, 0x12, 0x7b,
  0xb7, 0x63, 0xfa, 0x51,
]

// D3D12_HEAP_PROPERTIES { Type=DEFAULT(1), CPUPageProperty=0, MemoryPool=0,
// CreationNodeMask=0, VisibleNodeMask=0 }.
let heap_props : FixedArray[Int32] = [1, 0, 0, 0, 0]

// D3D12_RESOURCE_DESC: 64x64 R8G8B8A8_UNORM 2D, ALLOW_RENDER_TARGET. Alignment is
// UINT64 (4 bytes padding after Dimension); Flags at offset 48.
let tex_desc_rt : FixedArray[Byte] = [
  0x03, 0x00, 0x00, 0x00, // Dimension = TEXTURE2D
  0x00, 0x00, 0x00, 0x00, // padding
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // Alignment = 0
  0x40, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // Width = 64
  0x40, 0x00, 0x00, 0x00, // Height = 64
  0x01, 0x00, // DepthOrArraySize = 1
  0x01, 0x00, // MipLevels = 1
  0x1c, 0x00, 0x00, 0x00, // Format = R8G8B8A8_UNORM (28)
  0x01, 0x00, 0x00, 0x00, // SampleDesc.Count = 1
  0x00, 0x00, 0x00, 0x00, // SampleDesc.Quality = 0
  0x00, 0x00, 0x00, 0x00, // Layout = UNKNOWN
  0x01, 0x00, 0x00, 0x00, // Flags = ALLOW_RENDER_TARGET (1)
  0x00, 0x00, 0x00, 0x00, // padding
]

// D3D12_RESOURCE_BARRIER (transition) as four Int64 words:
//   [0] = Type(0) | Flags(0)<<32
//   [1] = pResource (filled at runtime)
//   [2] = Subresource(0xFFFFFFFF) | StateBefore<<32
//   [3] = StateAfter | padding<<32
let barrier_to_rt : FixedArray[Int64] = [0, 0, 4294967295, 4] // COMMON -> RENDER_TARGET(4)

let barrier_to_common : FixedArray[Int64] = [0, 0, 21474836479, 0] // RENDER_TARGET(4) -> COMMON

// One RTV CPU handle slot for OMSetRenderTargets (filled at runtime).
let rtv_slot : FixedArray[Int64] = [0]

// D3D12_VIEWPORT { 0, 0, 64, 64, 0, 1 } as six little-endian floats.
let viewport : FixedArray[Byte] = [
  0x00, 0x00, 0x00, 0x00, // TopLeftX = 0
  0x00, 0x00, 0x00, 0x00, // TopLeftY = 0
  0x00, 0x00, 0x80, 0x42, // Width = 64
  0x00, 0x00, 0x80, 0x42, // Height = 64
  0x00, 0x00, 0x00, 0x00, // MinDepth = 0
  0x00, 0x00, 0x80, 0x3f, // MaxDepth = 1
]

let scissor : FixedArray[Int32] = [0, 0, 64, 64]

let clear_color : FixedArray[Byte] = [
  0x00, 0x00, 0x00, 0x00, // R = 0
  0x00, 0x00, 0x00, 0x00, // G = 0
  0x00, 0x00, 0x00, 0x00, // B = 0
  0x00, 0x00, 0x80, 0x3f, // A = 1
]

// RTV heap desc { Type=RTV(2), NumDescriptors=1, Flags=0, NodeMask=0 }.
let rtv_heap_desc : FixedArray[Int32] = [2, 1, 0, 0]

// Scratch buffer for ID3D12Resource::GetDesc (56-byte D3D12_RESOURCE_DESC).
let rdesc_buf : FixedArray[Byte] = FixedArray::make(56, (0 : Byte))

// Out-buffer for the 8-byte D3D12_CPU_DESCRIPTOR_HANDLE struct return (the COM
// ABI hands it back through a hidden pointer, not a register).
let cpu_handle_buf : FixedArray[Int64] = FixedArray::make(1, (0 : Int64))

///|
fn main {
  if !@dx12.available() {
    println("[dx12/raw-commands] SKIP — d3d12.dll / dxgi.dll not loadable on this host")
    return
  }
  let device = match @dx12.Device::create(warp=@dx12.env_requests_warp(), debug=true) {
    Some(d) => d
    None =>
      match @dx12.Device::create(warp=true, debug=true) {
        Some(d) => d
        None => {
          fail("no D3D12 device (hardware and WARP both refused)")
          return
        }
      }
  }
  let raw = device.raw()
  let mut probed = 0
  let mut ok = true

  // Command allocator + list (DIRECT).
  let ca_out = FixedArray::make(1, (0 : Int64))
  let hr_ca = @dx12.dx_d3d12_device_create_command_allocator(
    raw, 0, @dx12.bytes_ptr(iid_command_allocator), @dx12.int64_ptr(ca_out),
  )
  probed = probed + 1
  if hr_ca != 0 || ca_out[0] == (0 : Int64) {
    fail("CreateCommandAllocator")
    device.destroy()
    return
  }
  let ca = ca_out[0].reinterpret_as_uint64()
  let cl_out = FixedArray::make(1, (0 : Int64))
  let hr_cl = @dx12.dx_d3d12_device_create_command_list(
    raw, 0, 0, ca, (0 : UInt64), @dx12.bytes_ptr(iid_graphics_command_list), @dx12.int64_ptr(cl_out),
  )
  probed = probed + 1
  if hr_cl != 0 || cl_out[0] == (0 : Int64) {
    fail("CreateCommandList")
    device.destroy()
    return
  }
  let cl = cl_out[0].reinterpret_as_uint64()

  // CreateCommittedResource: a DEFAULT-heap render-target texture.
  let tex_out = FixedArray::make(1, (0 : Int64))
  let hr_tex = @dx12.dx_d3d12_device_create_committed_resource(
    raw,
    @dx12.int32_ptr(heap_props),
    0, // D3D12_HEAP_FLAG_NONE
    @dx12.bytes_ptr(tex_desc_rt),
    0, // D3D12_RESOURCE_STATE_COMMON
    (0 : UInt64), // no optimized clear value
    @dx12.bytes_ptr(iid_resource),
    @dx12.int64_ptr(tex_out),
  )
  probed = probed + 1
  if hr_tex != 0 || tex_out[0] == (0 : Int64) {
    fail("CreateCommittedResource")
    device.destroy()
    return
  }
  let tex = tex_out[0].reinterpret_as_uint64()

  // ID3D12Resource::GetDesc / GetGPUVirtualAddress.
  let _ = @dx12.dx_d3d12_resource_get_desc(tex, @dx12.bytes_ptr(rdesc_buf))
  probed = probed + 1
  // GetGPUVirtualAddress is exercised; the value can be 0 on some adapters
  // before the resource is made resident, so it is not asserted.
  let _ = @dx12.dx_d3d12_resource_get_gpu_virtual_address(tex)
  probed = probed + 1

  // RTV descriptor heap + CreateRenderTargetView.
  let heap_out = FixedArray::make(1, (0 : Int64))
  let hr_heap = @dx12.dx_d3d12_device_create_descriptor_heap(
    raw, @dx12.int32_ptr(rtv_heap_desc), @dx12.bytes_ptr(iid_descriptor_heap), @dx12.int64_ptr(heap_out),
  )
  probed = probed + 1
  if hr_heap != 0 || heap_out[0] == (0 : Int64) {
    fail("CreateDescriptorHeap(RTV)")
    device.destroy()
    return
  }
  let heap = heap_out[0].reinterpret_as_uint64()
  let _ = @dx12.dx_d3d12_descriptor_heap_get_cpu_descriptor_handle_for_heap_start(heap, @dx12.int64_ptr(cpu_handle_buf))
  probed = probed + 1
  rtv_slot[0] = cpu_handle_buf[0]
  // The CPU-handle parameter is a struct passed by pointer in the raw ABI.
  @dx12.dx_d3d12_device_create_render_target_view(raw, tex, (0 : UInt64), @dx12.int64_ptr(rtv_slot))
  probed = probed + 1

  // Record: COMMON -> RENDER_TARGET, bind + clear, set rasterizer/IA state,
  // then RENDER_TARGET -> COMMON.
  barrier_to_rt[1] = tex.reinterpret_as_int64()
  barrier_to_common[1] = tex.reinterpret_as_int64()
  @dx12.dx_d3d12_graphics_command_list_resource_barrier(cl, 1, @dx12.int64_ptr(barrier_to_rt))
  probed = probed + 1
  @dx12.dx_d3d12_graphics_command_list_om_set_render_targets(cl, 1, @dx12.int64_ptr(rtv_slot), 1, (0 : UInt64))
  probed = probed + 1
  @dx12.dx_d3d12_graphics_command_list_clear_render_target_view(cl, @dx12.int64_ptr(rtv_slot), @dx12.bytes_ptr(clear_color), 0, (0 : UInt64))
  probed = probed + 1
  @dx12.dx_d3d12_graphics_command_list_rs_set_viewports(cl, 1, @dx12.bytes_ptr(viewport))
  probed = probed + 1
  @dx12.dx_d3d12_graphics_command_list_rs_set_scissor_rects(cl, 1, @dx12.int32_ptr(scissor))
  probed = probed + 1
  @dx12.dx_d3d12_graphics_command_list_ia_set_primitive_topology(cl, 4) // TRIANGLELIST
  probed = probed + 1
  @dx12.dx_d3d12_graphics_command_list_resource_barrier(cl, 1, @dx12.int64_ptr(barrier_to_common))
  probed = probed + 1
  let hr_close = @dx12.dx_d3d12_graphics_command_list_close(cl)
  probed = probed + 1
  ok = ok && hr_close == 0

  let _ = @dx12.com_release(tex)
  let _ = @dx12.com_release(heap)
  let _ = @dx12.com_release(cl)
  let _ = @dx12.com_release(ca)
  probed = probed + 4

  let errs = device.validation_errors()
  let adapter = if device.is_warp() { "warp" } else { "hardware" }
  device.destroy()
  if ok && errs == 0 {
    println(
      "[dx12/raw-commands] OK — commands=\{probed} generated COM calls verified (adapter=\{adapter}, committed resource + RTV + barrier/clear/viewport/scissor/topology recording), 0 validation errors",
    )
  } else {
    println("[dx12/raw-commands] FAIL — ok=\{ok} errs=\{errs} commands=\{probed}")
  }
}
