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

#borrow(values)
extern "c" fn int32_ptr_ffi(values : FixedArray[Int32]) -> UInt64 = "tycho_dx12_as_ptr"

extern "c" fn device_create_ffi(use_warp : Int, debug : Int) -> UInt64 = "tycho_dx12_device_create"

extern "c" fn device_destroy_ffi(dev : UInt64) = "tycho_dx12_device_destroy"

extern "c" fn device_validation_errors_ffi(dev : UInt64) -> Int32 = "tycho_dx12_device_validation_errors"

extern "c" fn device_wait_idle_ffi(dev : UInt64) -> Int32 = "tycho_dx12_device_wait_idle"

extern "c" fn device_is_warp_ffi(dev : UInt64) -> Int32 = "tycho_dx12_device_is_warp"

extern "c" fn device_raw_ffi(dev : UInt64) -> UInt64 = "tycho_dx12_device_raw"

extern "c" fn device_shader_model_ffi(dev : UInt64) -> Int32 = "tycho_dx12_device_shader_model"

extern "c" fn device_mesh_tier_ffi(dev : UInt64) -> Int32 = "tycho_dx12_device_mesh_tier"

extern "c" fn device_raytracing_tier_ffi(dev : UInt64) -> Int32 = "tycho_dx12_device_raytracing_tier"

extern "c" fn commands_create_ffi(dev : UInt64) -> UInt64 = "tycho_dx12_commands_create"

extern "c" fn commands_destroy_ffi(cmds : UInt64) = "tycho_dx12_commands_destroy"

extern "c" fn commands_begin_ffi(cmds : UInt64) -> Int32 = "tycho_dx12_commands_begin"

extern "c" fn cmd_transition_ffi(cmds : UInt64, tex : UInt64, state : Int) -> Int32 = "tycho_dx12_cmd_transition"

extern "c" fn texture_state_ffi(tex : UInt64) -> Int32 = "tycho_dx12_texture_state"

extern "c" fn swapchain_create_ffi(dev : UInt64, hwnd : UInt64, width : Int, height : Int) -> UInt64 = "tycho_dx12_swapchain_create"

extern "c" fn swapchain_destroy_ffi(sc : UInt64) = "tycho_dx12_swapchain_destroy"

extern "c" fn swapchain_width_ffi(sc : UInt64) -> Int32 = "tycho_dx12_swapchain_width"

extern "c" fn swapchain_height_ffi(sc : UInt64) -> Int32 = "tycho_dx12_swapchain_height"

extern "c" fn swapchain_current_index_ffi(sc : UInt64) -> Int32 = "tycho_dx12_swapchain_current_index"

extern "c" fn swapchain_present_ffi(sc : UInt64) -> Int32 = "tycho_dx12_swapchain_present"

extern "c" fn swapchain_target_ffi(sc : UInt64, index : Int) -> UInt64 = "tycho_dx12_swapchain_target"

extern "c" fn swapchain_resize_ffi(dev : UInt64, sc : UInt64, width : Int, height : Int) -> Int32 = "tycho_dx12_swapchain_resize"

extern "c" fn cmd_clear_ffi(cmds : UInt64, tex : UInt64, r : Float, g : Float, b : Float, a : Float) -> Int32 = "tycho_dx12_cmd_clear"

extern "c" fn cmd_set_pipeline_ffi(cmds : UInt64, pipe : UInt64) -> Int32 = "tycho_dx12_cmd_set_pipeline"

extern "c" fn cmd_draw_ffi(cmds : UInt64, tex : UInt64, vertices : Int, instances : Int, flip_y : Int) -> Int32 = "tycho_dx12_cmd_draw"

extern "c" fn cmd_set_cbv_ffi(cmds : UInt64, index : Int, gpu_address : UInt64) -> Int32 = "tycho_dx12_cmd_set_cbv"

extern "c" fn buffer_create_ffi(dev : UInt64, size : Int) -> UInt64 = "tycho_dx12_buffer_create"

#borrow(data)
extern "c" fn buffer_write_ffi(buf : UInt64, offset : Int, data : Bytes, len : Int) -> Int32 = "tycho_dx12_buffer_write"

#borrow(data)
extern "c" fn buffer_write_floats_ffi(buf : UInt64, offset : Int, data : FixedArray[Float], count : Int) -> Int32 = "tycho_dx12_buffer_write_floats"

extern "c" fn buffer_gpu_address_ffi(buf : UInt64) -> UInt64 = "tycho_dx12_buffer_gpu_address"

extern "c" fn buffer_size_ffi(buf : UInt64) -> Int32 = "tycho_dx12_buffer_size"

extern "c" fn buffer_destroy_ffi(buf : UInt64) = "tycho_dx12_buffer_destroy"

extern "c" fn cmd_copy_to_readback_ffi(cmds : UInt64, tex : UInt64, rb : UInt64) -> Int32 = "tycho_dx12_cmd_copy_to_readback"

extern "c" fn commands_execute_wait_ffi(dev : UInt64, cmds : UInt64) -> Int32 = "tycho_dx12_commands_execute_wait"

#borrow(vs, ps)
extern "c" fn pipeline_create_ffi(dev : UInt64, vs : FixedArray[UInt32], vs_bytes : Int, ps : FixedArray[UInt32], ps_bytes : Int, cbv_count : Int, flip_y : Int, depth_enable : Int, depth_write : Int, srv_tables : Int) -> UInt64 = "tycho_dx12_pipeline_create"

#borrow(pixels)
extern "c" fn texture_create_uploaded_ffi(dev : UInt64, width : Int, height : Int, pixels : Bytes, pixel_bytes : Int) -> UInt64 = "tycho_dx12_texture_create_uploaded"

extern "c" fn cmd_set_texture_ffi(cmds : UInt64, root_index : Int, tex : UInt64, sampler : UInt64) -> Int32 = "tycho_dx12_cmd_set_texture"

extern "c" fn sampler_create_ffi(dev : UInt64, filter : Int, address : Int, anisotropy : Float, min_lod : Float, max_lod : Float, mip_lod_bias : Float) -> UInt64 = "tycho_dx12_sampler_create"

extern "c" fn sampler_destroy_ffi(sampler : UInt64) = "tycho_dx12_sampler_destroy"

extern "c" fn storage_texture_create_ffi(dev : UInt64, width : Int, height : Int) -> UInt64 = "tycho_dx12_storage_texture_create"

#borrow(cs)
extern "c" fn compute_pipeline_create_ffi(dev : UInt64, cs : FixedArray[UInt32], cs_bytes : Int, cbv_count : Int, uav_tables : Int) -> UInt64 = "tycho_dx12_compute_pipeline_create"

extern "c" fn compute_pipeline_destroy_ffi(pipe : UInt64) = "tycho_dx12_pipeline_destroy"

extern "c" fn cmd_set_compute_pipeline_ffi(cmds : UInt64, pipe : UInt64) -> Int32 = "tycho_dx12_cmd_set_compute_pipeline"

extern "c" fn cmd_set_uav_ffi(cmds : UInt64, root_index : Int, tex : UInt64) -> Int32 = "tycho_dx12_cmd_set_uav"

extern "c" fn cmd_dispatch_ffi(cmds : UInt64, x : Int, y : Int, z : Int) -> Int32 = "tycho_dx12_cmd_dispatch"

extern "c" fn buffer_heap_create_ffi(dev : UInt64, size : Int) -> UInt64 = "tycho_dx12_buffer_heap_create"

extern "c" fn buffer_heap_destroy_ffi(heap : UInt64) = "tycho_dx12_buffer_heap_destroy"

extern "c" fn buffer_place_ffi(heap : UInt64, offset : Int, size : Int) -> UInt64 = "tycho_dx12_buffer_place"

extern "c" fn depth_create_ffi(dev : UInt64, width : Int, height : Int) -> UInt64 = "tycho_dx12_depth_create"

extern "c" fn cmd_set_depth_ffi(cmds : UInt64, tex : UInt64) -> Int32 = "tycho_dx12_cmd_set_depth"

extern "c" fn cmd_clear_depth_ffi(cmds : UInt64, tex : UInt64, depth : Float) -> Int32 = "tycho_dx12_cmd_clear_depth"

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
/// Data pointer of an `Int32` array, for the raw generated-dispatch ABI.
pub fn int32_ptr(values : FixedArray[Int32]) -> UInt64 {
  int32_ptr_ffi(values)
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
/// Blocks until the queue has drained. Call this before releasing anything the
/// GPU may still be using (swapchain, render targets, readback buffers).
pub fn Device::wait_idle(self : Device) -> Bool {
  device_wait_idle_ffi(self.handle) != 0
}

///|
pub fn Device::is_warp(self : Device) -> Bool {
  device_is_warp_ffi(self.handle) != 0
}

///|
/// The underlying `ID3D12Device *`, for the generated dispatch layer and other
/// raw interop. `Device::handle` is the wrapper, not the COM object.
pub fn Device::raw(self : Device) -> UInt64 {
  device_raw_ffi(self.handle)
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
///|
/// `cbv_count` root constant buffers are declared at `register(b<i>, space0)`;
/// `flip_y` renders with a negative viewport height (Vulkan clip-space
/// convention) and mirrors the front-face winding to match.
pub fn Pipeline::create(
  device : Device,
  vs_dxil : FixedArray[UInt32],
  vs_bytes : Int,
  ps_dxil : FixedArray[UInt32],
  ps_bytes : Int,
  cbv_count? : Int = 0,
  flip_y? : Bool = false,
  depth? : Bool = false,
  depth_write? : Bool = true,
  srv_tables? : Int = 0,
) -> Pipeline? {
  let handle = pipeline_create_ffi(
    device.handle,
    vs_dxil,
    vs_bytes,
    ps_dxil,
    ps_bytes,
    cbv_count,
    if flip_y { 1 } else { 0 },
    if depth { 1 } else { 0 },
    if depth_write { 1 } else { 0 },
    srv_tables,
  )
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
///|
/// Uploads tightly packed RGBA8 pixels into a DEFAULT-heap texture and gives it a
/// shader-visible SRV, so it can be bound with `CommandList::set_texture`.
pub fn Texture::create_uploaded(
  device : Device,
  width : Int,
  height : Int,
  pixels : Bytes,
) -> Texture? {
  let handle = texture_create_uploaded_ffi(device.handle, width, height, pixels, pixels.length())
  if handle == (0 : UInt64) {
    None
  } else {
    Some({ handle, })
  }
}

///|
/// A storage texture (`RWTexture2D` / UAV) that a compute shader writes into. It
/// starts in `ResourceState::UnorderedAccess` and can be read back afterwards.
pub fn Texture::create_storage(device : Device, width : Int, height : Int) -> Texture? {
  let handle = storage_texture_create_ffi(device.handle, width, height)
  if handle == (0 : UInt64) {
    None
  } else {
    Some({ handle, })
  }
}

///|
/// A depth buffer (`D32_FLOAT`) with its own DSV. Bind it with
/// `CommandList::set_depth` before clearing or drawing.
pub fn Texture::create_depth(device : Device, width : Int, height : Int) -> Texture? {
  let handle = depth_create_ffi(device.handle, width, height)
  if handle == (0 : UInt64) {
    None
  } else {
    Some({ handle, })
  }
}

///|
pub fn Texture::is_depth(self : Texture) -> Bool {
  match self.state() {
    Some(DepthWrite) => true
    _ => false
  }
}

pub fn Texture::handle(self : Texture) -> UInt64 {
  self.handle
}

///|
/// The texture's current resource state, as last set by `CommandList::transition`.
pub fn Texture::state(self : Texture) -> ResourceState? {
  ResourceState::from_code(texture_state_ffi(self.handle).to_int())
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
/// Typed resource states. `Present` and `Common` both map to the D3D12 value 0,
/// but keeping them apart lets a caller express intent (and lets the shim report
/// what a texture was last used for).
pub(all) enum ResourceState {
  Common
  RenderTarget
  CopySource
  CopyDest
  Present
  ShaderResource
  UnorderedAccess
  DepthWrite
}

///|
fn ResourceState::code(self : ResourceState) -> Int {
  match self {
    Common => 0
    RenderTarget => 1
    CopySource => 2
    CopyDest => 3
    Present => 4
    ShaderResource => 5
    UnorderedAccess => 6
    DepthWrite => 7
  }
}

///|
fn ResourceState::from_code(code : Int) -> ResourceState? {
  match code {
    0 => Some(Common)
    1 => Some(RenderTarget)
    2 => Some(CopySource)
    3 => Some(CopyDest)
    4 => Some(Present)
    5 => Some(ShaderResource)
    6 => Some(UnorderedAccess)
    7 => Some(DepthWrite)
    _ => None
  }
}

///|
/// Transitions the texture into `state`, emitting a barrier only when the native
/// state actually changes. Drawing or copying from a texture in the wrong state
/// fails with `E_ILLEGAL_METHOD_CALL` instead of corrupting the frame.
pub fn CommandList::transition(
  self : CommandList,
  tex : Texture,
  state : ResourceState,
) -> Bool {
  cmd_transition_ffi(self.handle, tex.handle, state.code()) != 0
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
pub fn CommandList::draw(
  self : CommandList,
  tex : Texture,
  vertices : Int,
  instances? : Int = 1,
  flip_y? : Bool = false,
) -> Bool {
  cmd_draw_ffi(self.handle, tex.handle, vertices, instances, if flip_y { 1 } else { 0 }) != 0
}

///|
/// Binds an upload buffer to root CBV `index` (see `Pipeline::create`'s
/// `cbv_count`).
pub fn CommandList::set_cbv(
  self : CommandList,
  index : Int,
  buffer : Buffer,
  offset? : Int = 0,
) -> Bool {
  cmd_set_cbv_ffi(self.handle, index, buffer.gpu_address() + offset.to_uint64()) != 0
}

// ---------------------------------------------------------------------------
// Upload buffer (CPU-visible, persistently mapped)
// ---------------------------------------------------------------------------

///|
/// A CPU-writable buffer on the UPLOAD heap. Uniform data is its only consumer
/// today; it is bound as a root CBV, so no descriptor heap is involved.
pub struct Buffer {
  handle : UInt64
}

///|
pub fn Buffer::create(device : Device, size : Int) -> Buffer? {
  let handle = buffer_create_ffi(device.handle, size)
  if handle == (0 : UInt64) {
    None
  } else {
    Some({ handle, })
  }
}

///|
pub fn Buffer::handle(self : Buffer) -> UInt64 {
  self.handle
}

///|
pub fn Buffer::size(self : Buffer) -> Int {
  buffer_size_ffi(self.handle).to_int()
}

///|
pub fn Buffer::gpu_address(self : Buffer) -> UInt64 {
  buffer_gpu_address_ffi(self.handle)
}

///|
pub fn Buffer::write(self : Buffer, data : Bytes, offset? : Int = 0) -> Bool {
  buffer_write_ffi(self.handle, offset, data, data.length()) != 0
}

///|
pub fn Buffer::write_floats(
  self : Buffer,
  data : FixedArray[Float],
  offset? : Int = 0,
) -> Bool {
  buffer_write_floats_ffi(self.handle, offset, data, data.length()) != 0
}

///|
pub fn Buffer::destroy(self : Buffer) -> Unit {
  buffer_destroy_ffi(self.handle)
}

///|
pub fn CommandList::copy_to_readback(self : CommandList, tex : Texture, rb : Readback) -> Bool {
  cmd_copy_to_readback_ffi(self.handle, tex.handle, rb.handle) != 0
}

///|
///|
/// Binds the depth attachment used by the next draws (and by `clear_depth`).
/// Passing the depth texture here is what makes `draw` emit a DSV.
pub fn CommandList::set_depth(self : CommandList, tex : Texture) -> Bool {
  cmd_set_depth_ffi(self.handle, tex.handle) != 0
}

///|
/// Binds a texture's SRV through the descriptor table at `root_index` (the table
/// follows the root CBVs in the signature the pipelines build). The sampler is a
/// static one declared by the root signature, so no sampler object is needed.
pub fn CommandList::set_texture(
  self : CommandList,
  root_index : Int,
  tex : Texture,
  sampler? : Sampler? = None,
) -> Bool {
  let sampler_handle = match sampler {
    Some(s) => s.handle
    None => (0 : UInt64)
  }
  cmd_set_texture_ffi(self.handle, root_index, tex.handle, sampler_handle) != 0
}

///|
/// Clears the bound depth attachment; requires `ResourceState::DepthWrite`.
pub fn CommandList::clear_depth(self : CommandList, tex : Texture, depth? : Float = 1.0) -> Bool {
  cmd_clear_depth_ffi(self.handle, tex.handle, depth) != 0
}

pub fn CommandList::execute_wait(self : CommandList, device : Device) -> Bool {
  commands_execute_wait_ffi(device.handle, self.handle) != 0
}

// ---------------------------------------------------------------------------
// Compute pipeline (root signature: root CBVs, then one UAV table)
// ---------------------------------------------------------------------------

///|
/// Root constant buffers at `register(b<i>, space0)` followed by one UAV table
/// covering `u0..u(n-1)` in space 0.
pub fn ComputePipeline::create(
  device : Device,
  cs_dxil : FixedArray[UInt32],
  cs_bytes : Int,
  cbv_count? : Int = 0,
  uav_tables? : Int = 0,
) -> ComputePipeline? {
  let handle = compute_pipeline_create_ffi(device.handle, cs_dxil, cs_bytes, cbv_count, uav_tables)
  if handle == (0 : UInt64) {
    None
  } else {
    Some({ handle, })
  }
}

///|
pub fn ComputePipeline::handle(self : ComputePipeline) -> UInt64 {
  self.handle
}

///|
pub fn ComputePipeline::destroy(self : ComputePipeline) -> Unit {
  compute_pipeline_destroy_ffi(self.handle)
}

///|
/// Binds the compute pipeline and its root signature. Graphics and compute use
/// different D3D12 entry points, so this is separate from `set_pipeline`.
pub fn CommandList::set_compute_pipeline(
  self : CommandList,
  pipe : ComputePipeline,
) -> Bool {
  cmd_set_compute_pipeline_ffi(self.handle, pipe.handle) != 0
}

///|
/// Binds a storage texture as an UAV table at `root_index` (the UAV table follows
/// the root CBVs in the signature `ComputePipeline::create` builds).
pub fn CommandList::set_uav(self : CommandList, root_index : Int, tex : Texture) -> Bool {
  cmd_set_uav_ffi(self.handle, root_index, tex.handle) != 0
}

///|
pub fn CommandList::dispatch(self : CommandList, x : Int, y : Int, z? : Int = 1) -> Bool {
  cmd_dispatch_ffi(self.handle, x, y, z) != 0
}

///|
/// A compute pipeline: one DXIL blob, its own root signature.
pub struct ComputePipeline {
  handle : UInt64
}

// ---------------------------------------------------------------------------
// Placed buffers (a heap the caller carves offsets out of)
// ---------------------------------------------------------------------------

///|
/// A UPLOAD heap whose contents are carved into placed buffers. The free-list
/// itself lives on the caller's side (the RHI uses the shared `RegionPool`).
pub struct BufferHeap {
  handle : UInt64
}

///|
pub fn BufferHeap::create(device : Device, size : Int) -> BufferHeap? {
  let handle = buffer_heap_create_ffi(device.handle, size)
  if handle == (0 : UInt64) {
    None
  } else {
    Some({ handle, })
  }
}

///|
pub fn BufferHeap::handle(self : BufferHeap) -> UInt64 {
  self.handle
}

///|
/// Places a buffer at `offset` inside the heap. `offset` must satisfy
/// `D3D12_DEFAULT_RESOURCE_PLACEMENT_ALIGNMENT` (64 KiB).
pub fn Buffer::place(heap : BufferHeap, offset : Int, size : Int) -> Buffer? {
  let handle = buffer_place_ffi(heap.handle, offset, size)
  if handle == (0 : UInt64) {
    None
  } else {
    Some({ handle, })
  }
}

///|
pub fn BufferHeap::destroy(self : BufferHeap) -> Unit {
  buffer_heap_destroy_ffi(self.handle)
}

// ---------------------------------------------------------------------------
// Sampler (a slot in the device's shader-visible sampler heap)
// ---------------------------------------------------------------------------

///|
/// How the sampled texels are interpolated.
pub(all) enum SamplerFilter {
  Point
  Linear
  Anisotropic
}

///|
/// Out-of-range addressing, applied to all three axes.
pub(all) enum SamplerAddress {
  Wrap
  Mirror
  Clamp
  Border
  MirrorOnce
}

///|
/// A sampler heap slot. Bound with `CommandList::set_texture`.
pub struct Sampler {
  handle : UInt64
}

///|
pub fn Sampler::create(
  device : Device,
  filter : SamplerFilter,
  address : SamplerAddress,
  anisotropy? : Float = 1.0,
  min_lod? : Float = 0.0,
  max_lod? : Float = 1000.0,
  mip_lod_bias? : Float = 0.0,
) -> Sampler? {
  let filter_code = match filter {
    Point => 0
    Linear => 1
    Anisotropic => 2
  }
  let address_code = match address {
    Wrap => 0
    Mirror => 1
    Clamp => 2
    Border => 3
    MirrorOnce => 4
  }
  let handle = sampler_create_ffi(
    device.handle,
    filter_code,
    address_code,
    anisotropy,
    min_lod,
    max_lod,
    mip_lod_bias,
  )
  if handle == (0 : UInt64) {
    None
  } else {
    Some({ handle, })
  }
}

///|
pub fn Sampler::handle(self : Sampler) -> UInt64 {
  self.handle
}

///|
/// Returns the slot to the device's free list; the heap slot is reused by the
/// next sampler created.
pub fn Sampler::destroy(self : Sampler) -> Unit {
  sampler_destroy_ffi(self.handle)
}

// ---------------------------------------------------------------------------
// DXGI flip-model swapchain
// ---------------------------------------------------------------------------

///|
/// Outcome of `Swapchain::present`.
pub(all) enum PresentResult {
  Presented
  /// Presented, but the window is not visible (minimised / occluded).
  Occluded
  Failed
}

///|
/// DXGI flip-model swapchain bound to a native window handle (`HWND`).
pub struct Swapchain {
  handle : UInt64
}

///|
pub fn Swapchain::create(
  device : Device,
  hwnd : UInt64,
  width : Int,
  height : Int,
) -> Swapchain? {
  let handle = swapchain_create_ffi(device.handle, hwnd, width, height)
  if handle == (0 : UInt64) {
    None
  } else {
    Some({ handle, })
  }
}

///|
pub fn Swapchain::handle(self : Swapchain) -> UInt64 {
  self.handle
}

///|
pub fn Swapchain::width(self : Swapchain) -> Int {
  swapchain_width_ffi(self.handle).to_int()
}

///|
pub fn Swapchain::height(self : Swapchain) -> Int {
  swapchain_height_ffi(self.handle).to_int()
}

///|
pub fn Swapchain::current_index(self : Swapchain) -> Int {
  swapchain_current_index_ffi(self.handle).to_int()
}

///|
/// A borrowed handle to back buffer `index`. The returned `Texture` must be
/// destroyed (which only frees the wrapper), and it starts in
/// `ResourceState::Present`.
pub fn Swapchain::target(self : Swapchain, index : Int) -> Texture? {
  let handle = swapchain_target_ffi(self.handle, index)
  if handle == (0 : UInt64) {
    None
  } else {
    Some({ handle, })
  }
}

///|
pub fn Swapchain::present(self : Swapchain) -> PresentResult {
  match swapchain_present_ffi(self.handle).to_int() {
    1 => Presented
    2 => Occluded
    _ => Failed
  }
}

///|
pub fn Swapchain::resize(
  self : Swapchain,
  device : Device,
  width : Int,
  height : Int,
) -> Bool {
  swapchain_resize_ffi(device.handle, self.handle, width, height) != 0
}

///|
pub fn Swapchain::destroy(self : Swapchain) -> Unit {
  swapchain_destroy_ffi(self.handle)
}
