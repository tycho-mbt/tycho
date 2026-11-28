// dx12/raw-state — exercises generated GraphicsCommandList state thunks that need
// no resources: OMSetBlendFactor, OMSetStencilRef, IASetVertexBuffers /
// IASetIndexBuffer (unbind), and SetMarker. Calls the dx_* thunks on
// Device::raw() directly, under the debug layer with zero validation errors.
// (BeginEvent/EndEvent are omitted: the debug layer flags them as ERROR-severity
// diagnostics recommending the PIX macros.) Non-Windows hosts SKIP.

///|
fn fail(what : String) -> Unit {
  println("[dx12/raw-state] FAIL — \{what} (last HRESULT=\{@dx12.last_error()})")
}

let iid_command_allocator : FixedArray[Byte] = [
  0xe4, 0xde, 0x02, 0x61, 0x59, 0xaf, 0x09, 0x4b, 0xb9, 0x99, 0xb4, 0x4d,
  0x73, 0xf0, 0x9b, 0x24,
]

let iid_graphics_command_list : FixedArray[Byte] = [
  0x0f, 0x0d, 0x16, 0x5b, 0x1b, 0xac, 0x85, 0x41, 0x8b, 0xa8, 0xb3, 0xae,
  0x42, 0xa5, 0xa4, 0x55,
]

// FLOAT[4] blend factor { 1, 1, 1, 1 } (program-lifetime for the raw pointer).
let blend_factor : FixedArray[Byte] = [
  0x00, 0x00, 0x80, 0x3f, 0x00, 0x00, 0x80, 0x3f,
  0x00, 0x00, 0x80, 0x3f, 0x00, 0x00, 0x80, 0x3f,
]

///|
fn main {
  if !@dx12.available() {
    println("[dx12/raw-state] SKIP — d3d12.dll / dxgi.dll not loadable on this host")
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

  // Output-merger state.
  @dx12.dx_d3d12_graphics_command_list_om_set_blend_factor(cl, @dx12.bytes_ptr(blend_factor))
  probed = probed + 1
  @dx12.dx_d3d12_graphics_command_list_om_set_stencil_ref(cl, 0)
  probed = probed + 1
  // Input-assembler unbind (num_views=0 / null view is valid).
  @dx12.dx_d3d12_graphics_command_list_ia_set_vertex_buffers(cl, 0, 0, (0 : UInt64))
  probed = probed + 1
  @dx12.dx_d3d12_graphics_command_list_ia_set_index_buffer(cl, (0 : UInt64))
  probed = probed + 1
  // Debug marker (null payload, size 0). BeginEvent/EndEvent are omitted: the
  // debug layer flags them as ERROR-severity diagnostics recommending PIX.
  @dx12.dx_d3d12_graphics_command_list_set_marker(cl, 0, (0 : UInt64), 0)
  probed = probed + 1

  let hr_close = @dx12.dx_d3d12_graphics_command_list_close(cl)
  probed = probed + 1
  ok = ok && hr_close == 0

  let _ = @dx12.com_release(cl)
  let _ = @dx12.com_release(ca)
  probed = probed + 2

  let errs = device.validation_errors()
  let adapter = if device.is_warp() { "warp" } else { "hardware" }
  device.destroy()
  if ok && errs == 0 {
    println(
      "[dx12/raw-state] OK — commands=\{probed} generated COM calls verified (adapter=\{adapter}, OM/IA state + debug marker), 0 validation errors",
    )
  } else {
    println("[dx12/raw-state] FAIL — ok=\{ok} errs=\{errs} commands=\{probed}")
  }
}
