// dx12/raw-dispatch — verifies the generated 1:1 COM dispatch layer directly.
//
// Every other dx12 example goes through the hand-written safe API (dx12.mbt ->
// dx12_stub.c). This one instead calls the generated `dx_*` thunks on the raw
// `ID3D12Device *` from `Device::raw()`, proving the full-surface binding is
// callable and ABI-correct: device queries, CheckFeatureSupport across several
// feature structs, and descriptor-heap / command-allocator / fence lifecycles
// with IUnknown refcounting via @dx12.com_release.
//
// Runs under the D3D12 debug layer and asserts zero validation errors.
// Non-Windows hosts report SKIP.

///|
fn fail(what : String) -> Unit {
  println("[dx12/raw-dispatch] FAIL — \{what} (last HRESULT=\{@dx12.last_error()})")
}

// IID bytes (GUID layout: little-endian Data1/Data2/Data3, then Data4 as-is).
// Distilled from the Windows SDK d3d12.h MIDL_INTERFACE declarations. These are
// program-lifetime globals so the raw pointers handed to the generated Create*
// thunks stay valid for the whole call (a local array could be freed once its
// last direct use — bytes_ptr — returns).
let iid_descriptor_heap : FixedArray[Byte] = [
  0x1d, 0x47, 0xfb, 0x8e, 0x6c, 0x61, 0x49, 0x4f, 0x90, 0xf7, 0x12, 0x7b,
  0xb7, 0x63, 0xfa, 0x51,
]

let iid_command_allocator : FixedArray[Byte] = [
  0xe4, 0xde, 0x02, 0x61, 0x59, 0xaf, 0x09, 0x4b, 0xb9, 0x99, 0xb4, 0x4d,
  0x73, 0xf0, 0x9b, 0x24,
]

let iid_fence : FixedArray[Byte] = [
  0xcf, 0x3d, 0x75, 0x0a, 0xd8, 0xc4, 0x91, 0x4b, 0xad, 0xf6, 0xbe, 0x5a,
  0x60, 0xd9, 0x5a, 0x76,
]

// D3D12_DESCRIPTOR_HEAP_DESC { Type=RTV(2), NumDescriptors=16, Flags=0, NodeMask=0 }.
let heap_desc : FixedArray[Int32] = [2, 16, 0, 0]

///|
fn main {
  if !@dx12.available() {
    println("[dx12/raw-dispatch] SKIP — d3d12.dll / dxgi.dll not loadable on this host")
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

  // ID3D12Device::GetNodeCount / GetDeviceRemovedReason (scalar returns).
  let nodes = @dx12.dx_d3d12_device_get_node_count(raw)
  probed = probed + 1
  ok = ok && nodes >= 1
  let removed = @dx12.dx_d3d12_device_get_device_removed_reason(raw)
  probed = probed + 1
  ok = ok && removed == 0

  // ID3D12Device::CheckFeatureSupport with several feature structs, each passed
  // by pointer through the raw ABI.
  let arch = FixedArray::make(4, (0 : Int32)) // D3D12_FEATURE_DATA_ARCHITECTURE
  let hr_arch = @dx12.dx_d3d12_device_check_feature_support(raw, 1, @dx12.int32_ptr(arch), 16)
  probed = probed + 1
  ok = ok && hr_arch == 0
  // SHADER_MODEL takes the requested model as input and returns the highest
  // supported; the size must equal sizeof(D3D12_FEATURE_DATA_SHADER_MODEL).
  let sm = FixedArray::make(1, (0x60 : Int32))
  let hr_sm = @dx12.dx_d3d12_device_check_feature_support(raw, 7, @dx12.int32_ptr(sm), 4)
  probed = probed + 1
  ok = ok && hr_sm == 0 && sm[0] >= 0x60

  // ID3D12Device::CreateDescriptorHeap (RTV, 16 descriptors) then read its desc
  // back through ID3D12DescriptorHeap::GetDesc, and Release it.
  let heap_out = FixedArray::make(1, (0 : Int64))
  let hr_heap = @dx12.dx_d3d12_device_create_descriptor_heap(
    raw,
    @dx12.int32_ptr(heap_desc),
    @dx12.bytes_ptr(iid_descriptor_heap),
    @dx12.int64_ptr(heap_out),
  )
  probed = probed + 1
  if hr_heap == 0 && heap_out[0] != (0 : Int64) {
    let heap = heap_out[0].reinterpret_as_uint64()
    let desc_buf = FixedArray::make(4, (0 : Int32))
    let _ = @dx12.dx_d3d12_descriptor_heap_get_desc(heap, @dx12.int32_ptr(desc_buf))
    probed = probed + 1
    ok = ok && desc_buf[0] == 2 && desc_buf[1] == 16
    let _ = @dx12.com_release(heap)
    probed = probed + 1
  } else {
    ok = false
  }

  // ID3D12Device::CreateCommandAllocator (DIRECT) + Reset, then Release.
  let ca_out = FixedArray::make(1, (0 : Int64))
  let hr_ca = @dx12.dx_d3d12_device_create_command_allocator(
    raw,
    0, // D3D12_COMMAND_LIST_TYPE_DIRECT
    @dx12.bytes_ptr(iid_command_allocator),
    @dx12.int64_ptr(ca_out),
  )
  probed = probed + 1
  if hr_ca == 0 && ca_out[0] != (0 : Int64) {
    let ca = ca_out[0].reinterpret_as_uint64()
    let hr_reset = @dx12.dx_d3d12_command_allocator_reset(ca)
    probed = probed + 1
    ok = ok && hr_reset == 0
    let _ = @dx12.com_release(ca)
    probed = probed + 1
  } else {
    ok = false
  }

  // ID3D12Device::CreateFence + GetCompletedValue, then Release.
  let fence_out = FixedArray::make(1, (0 : Int64))
  let hr_fence = @dx12.dx_d3d12_device_create_fence(
    raw,
    (0 : Int64),
    0, // D3D12_FENCE_FLAG_NONE
    @dx12.bytes_ptr(iid_fence),
    @dx12.int64_ptr(fence_out),
  )
  probed = probed + 1
  if hr_fence == 0 && fence_out[0] != (0 : Int64) {
    let fence = fence_out[0].reinterpret_as_uint64()
    let completed = @dx12.dx_d3d12_fence_get_completed_value(fence)
    probed = probed + 1
    ok = ok && completed == (0 : Int64)
    let _ = @dx12.com_release(fence)
    probed = probed + 1
  } else {
    ok = false
  }

  let errs = device.validation_errors()
  let adapter = if device.is_warp() { "warp" } else { "hardware" }
  device.destroy()
  if ok && errs == 0 {
    println(
      "[dx12/raw-dispatch] OK — commands=\{probed} generated COM calls verified (adapter=\{adapter}, device queries + feature support + heap/allocator/fence lifecycles), 0 validation errors",
    )
  } else {
    println("[dx12/raw-dispatch] FAIL — ok=\{ok} errs=\{errs} commands=\{probed}")
  }
}
