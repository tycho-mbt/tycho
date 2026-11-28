// dx12/raw-device — exercises more of the generated COM dispatch: command queue
// and command list lifecycles, queue timestamp queries, the non-RTV descriptor
// heap types, and GetCopyableFootprints. Calls the dx_* thunks on Device::raw()
// directly (no hand-written safe API), under the debug layer with zero errors.
//
// Structs are marshalled as program-lifetime byte/int arrays so the raw pointers
// handed to the thunks stay valid for the whole call. Non-Windows hosts SKIP.

///|
fn fail(what : String) -> Unit {
  println("[dx12/raw-device] FAIL — \{what} (last HRESULT=\{@dx12.last_error()})")
}

// IID bytes (little-endian Data1/Data2/Data3, then Data4 as-is), from d3d12.h.
let iid_command_queue : FixedArray[Byte] = [
  0xa6, 0x70, 0xc8, 0x0e, 0x7e, 0x5d, 0x22, 0x4c, 0x8c, 0xfc, 0x5b, 0xaa,
  0xe0, 0x76, 0x16, 0xed,
]

let iid_graphics_command_list : FixedArray[Byte] = [
  0x0f, 0x0d, 0x16, 0x5b, 0x1b, 0xac, 0x85, 0x41, 0x8b, 0xa8, 0xb3, 0xae,
  0x42, 0xa5, 0xa4, 0x55,
]

let iid_command_allocator : FixedArray[Byte] = [
  0xe4, 0xde, 0x02, 0x61, 0x59, 0xaf, 0x09, 0x4b, 0xb9, 0x99, 0xb4, 0x4d,
  0x73, 0xf0, 0x9b, 0x24,
]

let iid_descriptor_heap : FixedArray[Byte] = [
  0x1d, 0x47, 0xfb, 0x8e, 0x6c, 0x61, 0x49, 0x4f, 0x90, 0xf7, 0x12, 0x7b,
  0xb7, 0x63, 0xfa, 0x51,
]

// D3D12_COMMAND_QUEUE_DESC { Type=DIRECT(0), Priority=0, Flags=0, NodeMask=0 }.
let queue_desc : FixedArray[Int32] = [0, 0, 0, 0]

// D3D12_RESOURCE_DESC for a 64x64 R8G8B8A8_UNORM 2D texture. Note Alignment is a
// UINT64, so there is 4 bytes of padding after Dimension (56 bytes total).
let tex_desc : FixedArray[Byte] = [
  0x03, 0x00, 0x00, 0x00, // Dimension = TEXTURE2D
  0x00, 0x00, 0x00, 0x00, // padding
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // Alignment = 0 (UINT64)
  0x40, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // Width = 64 (UINT64)
  0x40, 0x00, 0x00, 0x00, // Height = 64
  0x01, 0x00, // DepthOrArraySize = 1
  0x01, 0x00, // MipLevels = 1
  0x1c, 0x00, 0x00, 0x00, // Format = R8G8B8A8_UNORM (28)
  0x01, 0x00, 0x00, 0x00, // SampleDesc.Count = 1
  0x00, 0x00, 0x00, 0x00, // SampleDesc.Quality = 0
  0x00, 0x00, 0x00, 0x00, // Layout = UNKNOWN
  0x00, 0x00, 0x00, 0x00, // Flags = 0
  0x00, 0x00, 0x00, 0x00, // padding
]

///|
fn main {
  if !@dx12.available() {
    println("[dx12/raw-device] SKIP — d3d12.dll / dxgi.dll not loadable on this host")
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

  // ID3D12Device::CreateCommandQueue (DIRECT) + GetDesc / GetTimestampFrequency /
  // GetClockCalibration, then Release.
  let queue_out = FixedArray::make(1, (0 : Int64))
  let hr_queue = @dx12.dx_d3d12_device_create_command_queue(
    raw,
    @dx12.int32_ptr(queue_desc),
    @dx12.bytes_ptr(iid_command_queue),
    @dx12.int64_ptr(queue_out),
  )
  probed = probed + 1
  if hr_queue == 0 && queue_out[0] != (0 : Int64) {
    let queue = queue_out[0].reinterpret_as_uint64()
    let qdesc = FixedArray::make(4, (0 : Int32))
    let _ = @dx12.dx_d3d12_command_queue_get_desc(queue, @dx12.int32_ptr(qdesc))
    probed = probed + 1
    ok = ok && qdesc[0] == 0
    let freq = FixedArray::make(1, (0 : Int64))
    let hr_freq = @dx12.dx_d3d12_command_queue_get_timestamp_frequency(queue, @dx12.int64_ptr(freq))
    probed = probed + 1
    ok = ok && hr_freq == 0 && freq[0] > (0 : Int64)
    let gpu_ts = FixedArray::make(1, (0 : Int64))
    let cpu_ts = FixedArray::make(1, (0 : Int64))
    let hr_cal = @dx12.dx_d3d12_command_queue_get_clock_calibration(
      queue,
      @dx12.int64_ptr(gpu_ts),
      @dx12.int64_ptr(cpu_ts),
    )
    probed = probed + 1
    ok = ok && hr_cal == 0
    let _ = @dx12.com_release(queue)
    probed = probed + 1
  } else {
    ok = false
  }

  // CreateCommandAllocator + CreateCommandList, then Close / Reset / Close.
  let ca_out = FixedArray::make(1, (0 : Int64))
  let hr_ca = @dx12.dx_d3d12_device_create_command_allocator(
    raw,
    0,
    @dx12.bytes_ptr(iid_command_allocator),
    @dx12.int64_ptr(ca_out),
  )
  probed = probed + 1
  if hr_ca == 0 && ca_out[0] != (0 : Int64) {
    let ca = ca_out[0].reinterpret_as_uint64()
    let cl_out = FixedArray::make(1, (0 : Int64))
    let hr_cl = @dx12.dx_d3d12_device_create_command_list(
      raw,
      0, // nodeMask
      0, // D3D12_COMMAND_LIST_TYPE_DIRECT
      ca,
      (0 : UInt64), // no initial PSO
      @dx12.bytes_ptr(iid_graphics_command_list),
      @dx12.int64_ptr(cl_out),
    )
    probed = probed + 1
    if hr_cl == 0 && cl_out[0] != (0 : Int64) {
      let cl = cl_out[0].reinterpret_as_uint64()
      let hr_close = @dx12.dx_d3d12_graphics_command_list_close(cl)
      probed = probed + 1
      let hr_reset = @dx12.dx_d3d12_graphics_command_list_reset(cl, ca, (0 : UInt64))
      probed = probed + 1
      let hr_close2 = @dx12.dx_d3d12_graphics_command_list_close(cl)
      probed = probed + 1
      ok = ok && hr_close == 0 && hr_reset == 0 && hr_close2 == 0
      let _ = @dx12.com_release(cl)
      probed = probed + 1
    } else {
      ok = false
    }
    let _ = @dx12.com_release(ca)
    probed = probed + 1
  } else {
    ok = false
  }

  // CreateDescriptorHeap for the non-RTV types (CBV_SRV_UAV=0, SAMPLER=1, DSV=3)
  // and read each desc back.
  let heap_types : FixedArray[Int32] = [0, 1, 3]
  for hi = 0; hi < heap_types.length(); hi = hi + 1 {
    let ht = heap_types[hi]
    let desc : FixedArray[Int32] = [ht, 16, 0, 0]
    let heap_out = FixedArray::make(1, (0 : Int64))
    let hr_heap = @dx12.dx_d3d12_device_create_descriptor_heap(
      raw,
      @dx12.int32_ptr(desc),
      @dx12.bytes_ptr(iid_descriptor_heap),
      @dx12.int64_ptr(heap_out),
    )
    probed = probed + 1
    // Read desc[0] after the call so the array outlives the raw pointer use.
    ok = ok && desc[0] == ht
    if hr_heap == 0 && heap_out[0] != (0 : Int64) {
      let heap = heap_out[0].reinterpret_as_uint64()
      let dbuf = FixedArray::make(4, (0 : Int32))
      let _ = @dx12.dx_d3d12_descriptor_heap_get_desc(heap, @dx12.int32_ptr(dbuf))
      probed = probed + 1
      ok = ok && dbuf[0] == ht && dbuf[1] == 16
      let _ = @dx12.com_release(heap)
      probed = probed + 1
    } else {
      ok = false
    }
  }

  // ID3D12Device::GetCopyableFootprints for the 64x64 RGBA8 texture.
  let layouts = FixedArray::make(32, (0 : Byte)) // D3D12_PLACED_SUBRESOURCE_FOOTPRINT
  let num_rows = FixedArray::make(1, (0 : Int32))
  let row_size = FixedArray::make(1, (0 : Int32))
  let total_bytes = FixedArray::make(1, (0 : Int64))
  @dx12.dx_d3d12_device_get_copyable_footprints(
    raw,
    @dx12.bytes_ptr(tex_desc),
    0, // firstSubresource
    1, // numSubresources
    (0 : Int64), // baseOffset
    @dx12.bytes_ptr(layouts),
    @dx12.int32_ptr(num_rows),
    @dx12.int32_ptr(row_size),
    @dx12.int64_ptr(total_bytes),
  )
  probed = probed + 1
  ok = ok && num_rows[0] == 64 && row_size[0] == 256 && total_bytes[0] == (16384 : Int64)

  let errs = device.validation_errors()
  let adapter = if device.is_warp() { "warp" } else { "hardware" }
  device.destroy()
  if ok && errs == 0 {
    println(
      "[dx12/raw-device] OK — commands=\{probed} generated COM calls verified (adapter=\{adapter}, queue/list lifecycles + timestamp queries + heap types + copyable footprints), 0 validation errors",
    )
  } else {
    println("[dx12/raw-device] FAIL — ok=\{ok} errs=\{errs} commands=\{probed}")
  }
}
