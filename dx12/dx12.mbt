// Direct3D 12 bindings for Tycho — M1a: hand-written minimal surface.
//
// Everything here is pure MoonBit: d3d12.dll / dxgi.dll are loaded at runtime by
// the native shim, no import libraries are needed, and every COM vtable call
// lives behind these functions. The shipped surface is deliberately small
// (device / command list / pipeline / render target / readback) until the
// codegen takes over in M1b.

// ---------------------------------------------------------------------------
// Native shim
// ---------------------------------------------------------------------------

extern "c" fn init_ffi() -> Int32 = "tycho_dx12_init"

extern "c" fn last_error_ffi() -> Int32 = "tycho_dx12_last_error"

extern "c" fn env_requests_warp_ffi() -> Int32 = "tycho_dx12_env_requests_warp"

extern "c" fn device_create_ffi(use_warp : Int, debug : Int) -> UInt64 = "tycho_dx12_device_create"

extern "c" fn device_destroy_ffi(dev : UInt64) = "tycho_dx12_device_destroy"

extern "c" fn device_validation_errors_ffi(dev : UInt64) -> Int32 = "tycho_dx12_device_validation_errors"

extern "c" fn device_is_warp_ffi(dev : UInt64) -> Int32 = "tycho_dx12_device_is_warp"

extern "c" fn device_shader_model_ffi(dev : UInt64) -> Int32 = "tycho_dx12_device_shader_model"

extern "c" fn device_mesh_tier_ffi(dev : UInt64) -> Int32 = "tycho_dx12_device_mesh_tier"

extern "c" fn device_raytracing_tier_ffi(dev : UInt64) -> Int32 = "tycho_dx12_device_raytracing_tier"

extern "c" fn commands_create_ffi(dev : UInt64) -> UInt64 = "tycho_dx12_commands_create"

extern "c" fn commands_destroy_ffi(cmds : UInt64) = "tycho_dx12_commands_destroy"

extern "c" fn commands_begin_ffi(cmds : UInt64) -> Int32 = "tycho_dx12_commands_begin"

extern "c" fn cmd_barrier_to_render_target_ffi(cmds : UInt64, tex : UInt64) -> Int32 = "tycho_dx12_cmd_barrier_to_render_target"

extern "c" fn cmd_barrier_to_copy_source_ffi(cmds : UInt64, tex : UInt64) -> Int32 = "tycho_dx12_cmd_barrier_to_copy_source"

extern "c" fn cmd_clear_ffi(cmds : UInt64, tex : UInt64, r : Float, g : Float, b : Float, a : Float) -> Int32 = "tycho_dx12_cmd_clear"

extern "c" fn cmd_set_pipeline_ffi(cmds : UInt64, pipe : UInt64) -> Int32 = "tycho_dx12_cmd_set_pipeline"

extern "c" fn cmd_draw_ffi(cmds : UInt64, tex : UInt64, vertices : Int) -> Int32 = "tycho_dx12_cmd_draw"

extern "c" fn cmd_copy_to_readback_ffi(cmds : UInt64, tex : UInt64, rb : UInt64) -> Int32 = "tycho_dx12_cmd_copy_to_readback"

extern "c" fn commands_execute_wait_ffi(dev : UInt64, cmds : UInt64) -> Int32 = "tycho_dx12_commands_execute_wait"

#borrow(vs, ps)
extern "c" fn pipeline_create_ffi(dev : UInt64, vs : FixedArray[UInt32], vs_bytes : Int, ps : FixedArray[UInt32], ps_bytes : Int) -> UInt64 = "tycho_dx12_pipeline_create"

extern "c" fn pipeline_destroy_ffi(pipe : UInt64) = "tycho_dx12_pipeline_destroy"

extern "c" fn texture_create_ffi(dev : UInt64, width : Int, height : Int) -> UInt64 = "tycho_dx12_texture_create"

extern "c" fn texture_destroy_ffi(tex : UInt64) = "tycho_dx12_texture_destroy"

extern "c" fn readback_create_ffi(dev : UInt64, width : Int, height : Int) -> UInt64 = "tycho_dx12_readback_create"

extern "c" fn readback_destroy_ffi(rb : UInt64) = "tycho_dx12_readback_destroy"

extern "c" fn readback_bytes_ffi(rb : UInt64) -> Bytes = "tycho_dx12_readback_bytes"

// ---------------------------------------------------------------------------
// Device
// ---------------------------------------------------------------------------

///|
/// A Direct3D 12 device plus its single direct queue and fence.
pub struct Device {
  handle : UInt64
}

///|
/// Returns `true` when `d3d12.dll` and `dxgi.dll` are loadable on this host.
pub fn available() -> Bool {
  init_ffi() != 0
}

///|
/// The HRESULT of the last failing call, as a signed 32-bit value.
pub fn last_error() -> Int {
  last_error_ffi().to_int()
}

///|
/// `TYCHO_DX12_WARP=1` asks runners to use the WARP software adapter, the DX12
/// counterpart of `TYCHO_VULKAN_LIB` for driver selection.
pub fn env_requests_warp() -> Bool {
  env_requests_warp_ffi() != 0
}

///|
/// Creates a device on the first hardware adapter, or on WARP when `warp` is set.
/// `debug` enables the D3D12 debug layer (and its message queue).
pub fn Device::create(warp? : Bool = false, debug? : Bool = false) -> Device? {
  let handle = device_create_ffi(
    if warp { 1 } else { 0 },
    if debug { 1 } else { 0 },
  )
  if handle == (0 : UInt64) {
    None
  } else {
    Some({ handle, })
  }
}

///|
pub fn Device::handle(self : Device) -> UInt64 {
  self.handle
}

///|
pub fn Device::destroy(self : Device) -> Unit {
  device_destroy_ffi(self.handle)
}

///|
/// Number of debug-layer messages with ERROR/CORRUPTION severity.
pub fn Device::validation_errors(self : Device) -> Int {
  device_validation_errors_ffi(self.handle).to_int()
}

///|
pub fn Device::is_warp(self : Device) -> Bool {
  device_is_warp_ffi(self.handle) != 0
}

///|
/// Highest shader model as the raw `D3D_SHADER_MODEL` value (0x60 = 6.0, 0x67 = 6.7).
pub fn Device::shader_model(self : Device) -> Int {
  device_shader_model_ffi(self.handle).to_int()
}

///|
/// `D3D12_MESH_SHADER_TIER` (0 = none, 10 = 1.0).
pub fn Device::mesh_tier(self : Device) -> Int {
  device_mesh_tier_ffi(self.handle).to_int()
}

///|
/// `D3D12_RAYTRACING_TIER` (0 = none, 10 = 1.0, 11 = 1.1).
pub fn Device::raytracing_tier(self : Device) -> Int {
  device_raytracing_tier_ffi(self.handle).to_int()
}

// ---------------------------------------------------------------------------
// Pipelines, render targets, readback buffers
// ---------------------------------------------------------------------------

///|
/// Graphics pipeline: an empty root signature plus a PSO built from DXIL blobs.
pub struct Pipeline {
  handle : UInt64
}

///|
pub fn Pipeline::create(
  device : Device,
  vs_dxil : FixedArray[UInt32],
  vs_bytes : Int,
  ps_dxil : FixedArray[UInt32],
  ps_bytes : Int,
) -> Pipeline? {
  let handle = pipeline_create_ffi(device.handle, vs_dxil, vs_bytes, ps_dxil, ps_bytes)
  if handle == (0 : UInt64) {
    None
  } else {
    Some({ handle, })
  }
}

///|
pub fn Pipeline::handle(self : Pipeline) -> UInt64 {
  self.handle
}

///|
pub fn Pipeline::destroy(self : Pipeline) -> Unit {
  pipeline_destroy_ffi(self.handle)
}

///|
/// RGBA8 UNORM render target with its own RTV descriptor heap.
pub struct Texture {
  handle : UInt64
}

///|
pub fn Texture::create(device : Device, width : Int, height : Int) -> Texture? {
  let handle = texture_create_ffi(device.handle, width, height)
  if handle == (0 : UInt64) {
    None
  } else {
    Some({ handle, })
  }
}

///|
pub fn Texture::handle(self : Texture) -> UInt64 {
  self.handle
}

///|
pub fn Texture::destroy(self : Texture) -> Unit {
  texture_destroy_ffi(self.handle)
}

///|
/// Readback (CPU-readable) buffer sized for one RGBA8 copy of `width x height`.
pub struct Readback {
  handle : UInt64
}

///|
pub fn Readback::create(device : Device, width : Int, height : Int) -> Readback? {
  let handle = readback_create_ffi(device.handle, width, height)
  if handle == (0 : UInt64) {
    None
  } else {
    Some({ handle, })
  }
}

///|
pub fn Readback::handle(self : Readback) -> UInt64 {
  self.handle
}

///|
/// Tightly packed RGBA8 pixels, row pitch padding already removed.
pub fn Readback::bytes(self : Readback) -> Bytes {
  readback_bytes_ffi(self.handle)
}

///|
pub fn Readback::destroy(self : Readback) -> Unit {
  readback_destroy_ffi(self.handle)
}

// ---------------------------------------------------------------------------
// Command list
// ---------------------------------------------------------------------------

///|
/// A direct command allocator + command list pair.
pub struct CommandList {
  handle : UInt64
}

///|
pub fn CommandList::create(device : Device) -> CommandList? {
  let handle = commands_create_ffi(device.handle)
  if handle == (0 : UInt64) {
    None
  } else {
    Some({ handle, })
  }
}

///|
pub fn CommandList::handle(self : CommandList) -> UInt64 {
  self.handle
}

///|
pub fn CommandList::destroy(self : CommandList) -> Unit {
  commands_destroy_ffi(self.handle)
}

///|
pub fn CommandList::begin(self : CommandList) -> Bool {
  commands_begin_ffi(self.handle) != 0
}

///|
pub fn CommandList::barrier_to_render_target(self : CommandList, tex : Texture) -> Bool {
  cmd_barrier_to_render_target_ffi(self.handle, tex.handle) != 0
}

///|
pub fn CommandList::barrier_to_copy_source(self : CommandList, tex : Texture) -> Bool {
  cmd_barrier_to_copy_source_ffi(self.handle, tex.handle) != 0
}

///|
pub fn CommandList::clear(
  self : CommandList,
  tex : Texture,
  r : Float,
  g : Float,
  b : Float,
  a : Float,
) -> Bool {
  cmd_clear_ffi(self.handle, tex.handle, r, g, b, a) != 0
}

///|
pub fn CommandList::set_pipeline(self : CommandList, pipe : Pipeline) -> Bool {
  cmd_set_pipeline_ffi(self.handle, pipe.handle) != 0
}

///|
pub fn CommandList::draw(self : CommandList, tex : Texture, vertices : Int) -> Bool {
  cmd_draw_ffi(self.handle, tex.handle, vertices) != 0
}

///|
pub fn CommandList::copy_to_readback(self : CommandList, tex : Texture, rb : Readback) -> Bool {
  cmd_copy_to_readback_ffi(self.handle, tex.handle, rb.handle) != 0
}

///|
pub fn CommandList::execute_wait(self : CommandList, device : Device) -> Bool {
  commands_execute_wait_ffi(device.handle, self.handle) != 0
}
