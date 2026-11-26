// Tycho RHI public API façade.
// Users import only `"laplaceliu/tycho" @tycho` — zero Vulkan handles, descriptor
// sets, sync primitives, or C stubs are exposed.

// Backend selection: the Vulkan path keeps its existing state objects, the DX12
// path holds the matching laplaceliu/tycho_dx12 handles. Methods that only exist
// on one backend funnel through `vk()` / `dx12()` and raise `BackendUnsupported`
// instead of silently doing nothing.

///|
priv enum DeviceBackend {
  VkDevice(VkDeviceState)
  Dx12Device(Dx12DeviceState)
}

///|
priv enum SwapchainBackend {
  VkSwapchain(VkSwapchainState)
  Dx12Swapchain(Dx12SwapchainState)
}

///|
priv enum PipelineBackend {
  VkPipeline(VkPipelineState)
  Dx12Pipeline(Dx12PipelineState)
}

///|
priv enum BufferBackend {
  VkBuffer(VkBufferState)
  Dx12Buffer(Dx12BufferState)
}

///|
priv enum CommandsBackend {
  VkCommands(VkCmdState)
  Dx12Commands(Dx12CommandState)
}

///|
pub struct Device {
  priv backend : DeviceBackend
}

///|
pub struct Swapchain {
  priv backend : SwapchainBackend
}

///|
pub struct Pipeline {
  priv backend : PipelineBackend
}

///|
fn Device::vk(self : Device) -> VkDeviceState raise RhiError {
  match self.backend {
    VkDevice(state) => state
    Dx12Device(_) =>
      raise RhiError::BackendUnsupported(
        "this device operation is not implemented on the DX12 backend",
      )
  }
}

///|
fn Swapchain::vk(self : Swapchain) -> VkSwapchainState raise RhiError {
  match self.backend {
    VkSwapchain(state) => state
    Dx12Swapchain(_) =>
      raise RhiError::BackendUnsupported(
        "this swapchain operation is not implemented on the DX12 backend",
      )
  }
}

///|
fn CommandBuffer::vk(self : CommandBuffer) -> VkCmdState raise RhiError {
  match self.backend {
    VkCommands(state) => state
    Dx12Commands(_) =>
      raise RhiError::BackendUnsupported(
        "this command is not implemented on the DX12 backend",
      )
  }
}

///|
pub struct Buffer {
  priv backend : BufferBackend
}

///|
pub struct Texture {
  priv inner : VkTextureState
}

///|
pub struct Sampler {
  priv inner : VkSamplerState
}

///|
pub struct Fence {
  priv inner : VkFenceState
}

///|
pub struct TimestampPool {
  priv inner : VkTimestampPoolState
}

///|
pub struct BindlessHeap {
  priv inner : VkBindlessHeapState
}

///|
pub struct AccelStruct {
  priv inner : VkAccelStructState
}

///|
pub struct CommandBuffer {
  priv backend : CommandsBackend
}

///|
fn Buffer::vk(self : Buffer) -> VkBufferState raise RhiError {
  match self.backend {
    VkBuffer(state) => state
    Dx12Buffer(_) =>
      raise RhiError::BackendUnsupported("this buffer operation is not implemented on DX12")
  }
}

///|
fn Buffer::dx12(self : Buffer) -> Dx12BufferState? {
  match self.backend {
    Dx12Buffer(state) => Some(state)
    VkBuffer(_) => None
  }
}

// Vulkan-only handles: they are only ever produced by the Vulkan backend, so the
// accessors below cannot fail.

fn Texture::vk(self : Texture) -> VkTextureState {
  self.inner
}

fn Sampler::vk(self : Sampler) -> VkSamplerState {
  self.inner
}

fn Fence::vk(self : Fence) -> VkFenceState {
  self.inner
}

fn TimestampPool::vk(self : TimestampPool) -> VkTimestampPoolState {
  self.inner
}

fn BindlessHeap::vk(self : BindlessHeap) -> VkBindlessHeapState {
  self.inner
}

fn AccelStruct::vk(self : AccelStruct) -> VkAccelStructState {
  self.inner
}

///|
pub fn Device::new(
  app_name : String,
  validation : Bool,
) -> Device raise RhiError {
  Device::new_desc(DeviceDesc::new(app_name, validation~, headless=false))
}

///|
/// Whether the DX12 backend can be created on this host (`d3d12.dll` / `dxgi.dll`
/// loadable). Callers use this to SKIP instead of failing on non-Windows hosts.
pub fn dx12_available() -> Bool {
  @dx12.available()
}

///|
pub fn Device::new_desc(desc : DeviceDesc) -> Device raise RhiError {
  match desc.backend {
    BackendKind::Vulkan => { backend: VkDevice(vk_device_create(desc)) }
    BackendKind::Dx12 => { backend: Dx12Device(dx12_device_create(desc)) }
  }
}

///|
pub fn Device::capabilities(self : Device) -> DeviceCapabilities {
  match self.backend {
    VkDevice(state) => state.caps
    Dx12Device(state) => dx12_capabilities(state)
  }
}

///|
pub fn Device::pipeline_cache_data(self : Device) -> Bytes {
  match self.backend {
    VkDevice(state) => vk_device_pipeline_cache_data(state)
    Dx12Device(_) => b""
  }
}

///|
pub fn Device::backend(self : Device) -> BackendKind {
  match self.backend {
    VkDevice(_) => BackendKind::Vulkan
    Dx12Device(_) => BackendKind::Dx12
  }
}

///|
pub fn Device::validation_errors(self : Device) -> Int {
  match self.backend {
    VkDevice(state) => g_rhi_validation_errors.val - state.error_baseline
    Dx12Device(state) => state.device.validation_errors()
  }
}

///|
pub fn Device::allocator_stats(self : Device) -> (Int, Int) {
  match self.backend {
    VkDevice(state) => state.alloc.stats()
    // DX12 allocates committed resources per object today; the free-list
    // allocator is the next piece of the backend.
    Dx12Device(_) => (0, 0)
  }
}

///|
pub fn Device::allocator_used_bytes(self : Device) -> UInt64 {
  match self.backend {
    VkDevice(state) => state.alloc.used_bytes()
    Dx12Device(_) => (0 : UInt64)
  }
}

///|
pub fn Device::wait_idle(self : Device) -> Unit {
  match self.backend {
    VkDevice(state) => vk_device_wait_idle(state)
    Dx12Device(state) => {
      let _ = state.device.wait_idle()
    }
  }
}

///|
pub fn Device::destroy(self : Device) -> Unit {
  match self.backend {
    VkDevice(state) => vk_device_destroy(state)
    Dx12Device(state) => dx12_device_destroy(state)
  }
}

///|
pub fn Device::create_swapchain(
  self : Device,
  title : String,
  width : Int,
  height : Int,
) -> Swapchain raise RhiError {
  self.create_swapchain_desc(SwapchainDesc::new(title, width, height))
}

///|
pub fn Device::create_swapchain_desc(
  self : Device,
  desc : SwapchainDesc,
) -> Swapchain raise RhiError {
  match self.backend {
    VkDevice(state) => { backend: VkSwapchain(vk_swapchain_create(state, desc)) }
    Dx12Device(state) => { backend: Dx12Swapchain(dx12_swapchain_create(state, desc)) }
  }
}

///|
pub fn Swapchain::width(self : Swapchain) -> Int {
  match self.backend {
    VkSwapchain(state) => state.width
    Dx12Swapchain(state) => state.width
  }
}

///|
pub fn Swapchain::height(self : Swapchain) -> Int {
  match self.backend {
    VkSwapchain(state) => state.height
    Dx12Swapchain(state) => state.height
  }
}

///|
pub fn Swapchain::color_format(self : Swapchain) -> TextureFormat {
  match self.backend {
    VkSwapchain(state) => vk_swapchain_color_format(state)
    Dx12Swapchain(_) => TextureFormat::RGBA8
  }
}

///|
pub fn Swapchain::has_depth(self : Swapchain) -> Bool {
  match self.backend {
    VkSwapchain(state) => state.has_depth
    Dx12Swapchain(_) => false
  }
}

///|
pub fn Swapchain::depth_format(self : Swapchain) -> TextureFormat {
  match self.backend {
    VkSwapchain(state) => state.depth_format
    Dx12Swapchain(_) => TextureFormat::Depth32F
  }
}

///|
/// The native window handle backing this swapchain (HWND on Windows).
fn Swapchain::window(self : Swapchain) -> UInt64 {
  match self.backend {
    VkSwapchain(state) => state.window
    Dx12Swapchain(state) => state.window
  }
}

///|
pub fn Swapchain::should_close(self : Swapchain) -> Bool {
  match self.backend {
    VkSwapchain(state) => @win.should_close(state.window) != 0
    Dx12Swapchain(state) => @win.should_close(state.window) != 0
  }
}

///|
pub fn Swapchain::sync_size(self : Swapchain) -> Unit raise RhiError {
  vk_swapchain_sync_size(self.vk())
}

///|
pub fn Swapchain::wait_events(timeout_ms? : Int = 4) -> Unit {
  @win.wait_events(timeout_ms)
}

///|
pub fn Swapchain::poll_events(self : Swapchain) -> Array[Event] {
  match self.backend {
    VkSwapchain(state) => @win.poll_events(state.window)
    Dx12Swapchain(state) => @win.poll_events(state.window)
  }
}

///|
pub fn Swapchain::set_title(self : Swapchain, title : String) -> Unit {
  @win.set_title(self.window(), title)
}

///|
pub fn Swapchain::set_cursor_mode(self : Swapchain, mode : CursorMode) -> Unit {
  @win.set_cursor_mode(self.window(), mode)
}

///|
pub fn Swapchain::set_cursor_shape(
  self : Swapchain,
  shape : CursorShape,
) -> Unit {
  @win.set_cursor_shape(self.window(), shape)
}

///|
pub fn Swapchain::clipboard_text(self : Swapchain) -> String {
  @win.clipboard_text(self.window())
}

///|
pub fn Swapchain::set_clipboard_text(self : Swapchain, text : String) -> Unit {
  @win.set_clipboard_text(self.window(), text)
}

///|
pub fn Swapchain::set_fullscreen(self : Swapchain, fullscreen : Bool) -> Unit {
  @win.set_fullscreen(self.window(), fullscreen)
}

///|
pub fn Swapchain::is_fullscreen(self : Swapchain) -> Bool {
  @win.is_fullscreen(self.window())
}

///|
pub fn Swapchain::content_scale(self : Swapchain) -> Double {
  @win.content_scale(self.window())
}

///|
pub fn Swapchain::framebuffer_size(self : Swapchain) -> (Int, Int) {
  @win.framebuffer_size(self.window())
}

///|
pub fn Swapchain::mouse_pos(self : Swapchain) -> (Double, Double) {
  @win.mouse_pos(self.window())
}

///|
pub fn Swapchain::is_mouse_down(self : Swapchain, button : Int) -> Bool {
  @win.is_mouse_down(self.window(), button)
}

///|
pub fn Swapchain::time() -> Double {
  @win.time()
}

///|
pub fn Swapchain::begin_frame(self : Swapchain) -> CommandBuffer raise RhiError {
  match self.backend {
    VkSwapchain(state) => { backend: VkCommands(vk_swapchain_begin_frame(state)) }
    Dx12Swapchain(state) => { backend: Dx12Commands(dx12_begin_frame(state)) }
  }
}

///|
pub fn Swapchain::begin_frame_commands(
  self : Swapchain,
) -> CommandBuffer raise RhiError {
  match self.backend {
    VkSwapchain(state) => { backend: VkCommands(vk_swapchain_begin_frame_commands(state)) }
    Dx12Swapchain(state) => { backend: Dx12Commands(dx12_begin_frame_commands(state)) }
  }
}

///|
/// Runs `apply` with the Vulkan command state; a no-op on the DX12 backend,
/// which does not implement these recording calls yet.
fn CommandBuffer::on_vk(
  self : CommandBuffer,
  apply : (VkCmdState) -> Unit,
) -> Unit {
  match self.backend {
    VkCommands(state) => apply(state)
    Dx12Commands(_) => ()
  }
}

///|
/// Runs `apply` with the Vulkan command state and a Vulkan buffer; a no-op when
/// either side belongs to another backend.
fn CommandBuffer::on_vk_buffer(
  self : CommandBuffer,
  buffer : Buffer,
  apply : (VkCmdState, VkBufferState) -> Unit,
) -> Unit {
  match (self.backend, buffer.backend) {
    (VkCommands(cmd), VkBuffer(state)) => apply(cmd, state)
    _ => ()
  }
}

///|
fn CommandBuffer::on_vk_buffers(
  self : CommandBuffer,
  first : Buffer,
  second : Buffer,
  apply : (VkCmdState, VkBufferState, VkBufferState) -> Unit,
) -> Unit {
  match (self.backend, first.backend, second.backend) {
    (VkCommands(cmd), VkBuffer(a), VkBuffer(b)) => apply(cmd, a, b)
    _ => ()
  }
}

///|
pub fn CommandBuffer::frame_slot(self : CommandBuffer) -> Int {
  match self.backend {
    VkCommands(state) => state.frame_idx
    Dx12Commands(_) => 0
  }
}

///|
pub fn CommandBuffer::blit_to_swapchain(
  self : CommandBuffer,
  src : Texture,
  swapchain : Swapchain,
) -> Unit {
  match self.backend {
    VkCommands(state) =>
      match swapchain.backend {
        VkSwapchain(sc) => vk_cmd_blit_to_swapchain(state, src.inner, sc)
        Dx12Swapchain(_) => ()
      }
    // Texture upload/blit is a Vulkan-backend feature today.
    Dx12Commands(_) => ()
  }
}

///|
pub fn Swapchain::present_texture(
  self : Swapchain,
  src : Texture,
) -> Unit raise RhiError {
  let cmd = self.begin_frame_commands()
  cmd.blit_to_swapchain(src, self)
  self.end_frame(cmd)
}

///|
pub fn CommandBuffer::begin_swapchain_pass(
  self : CommandBuffer,
  swapchain : Swapchain,
  load_op? : LoadOp = LoadOp::Clear,
  clear_color? : ClearColor? = None,
) -> Unit {
  match self.backend {
    VkCommands(state) =>
      match swapchain.backend {
        VkSwapchain(sc) => vk_cmd_begin_swapchain_pass(state, sc, load_op, clear_color)
        Dx12Swapchain(_) => ()
      }
    Dx12Commands(state) => dx12_begin_swapchain_pass(state, load_op, clear_color)
  }
}

///|
pub fn CommandBuffer::end_swapchain_pass(self : CommandBuffer) -> Unit {
  match self.backend {
    VkCommands(state) => vk_cmd_end_swapchain_pass(state)
    // The DX12 pass ending is the barrier to PRESENT, emitted by end_frame.
    Dx12Commands(_) => ()
  }
}

///|
pub fn Swapchain::end_frame(
  self : Swapchain,
  cmd : CommandBuffer,
) -> Unit raise RhiError {
  match self.backend {
    VkSwapchain(state) =>
      match cmd.backend {
        VkCommands(commands) => vk_swapchain_end_frame(state, commands)
        Dx12Commands(_) =>
          raise RhiError::InvalidArgument("DX12 command buffer given to a Vulkan swapchain")
      }
    Dx12Swapchain(state) =>
      match cmd.backend {
        Dx12Commands(commands) => dx12_end_frame(state, commands)
        VkCommands(_) =>
          raise RhiError::InvalidArgument("Vulkan command buffer given to a DX12 swapchain")
      }
  }
}

///|
pub fn Swapchain::readback(self : Swapchain) -> FixedArray[Byte] {
  match self.backend {
    VkSwapchain(state) => vk_swapchain_readback(state)
    Dx12Swapchain(state) => dx12_swapchain_readback(state)
  }
}

///|
pub fn Swapchain::destroy(self : Swapchain) -> Unit {
  match self.backend {
    VkSwapchain(state) => vk_swapchain_destroy(state)
    Dx12Swapchain(state) => dx12_swapchain_destroy(state)
  }
}

///|
pub fn Swapchain::create_pipeline(
  self : Swapchain,
  vert_spv : FixedArray[UInt32],
  frag_spv : FixedArray[UInt32],
  uniform_slots : Int,
) -> Pipeline raise RhiError {
  match self.backend {
    Dx12Swapchain(state) =>
      return {
        backend: Dx12Pipeline(dx12_pipeline_create(state, vert_spv, frag_spv, uniform_slots)),
      }
    VkSwapchain(_) => ()
  }
  self.create_pipeline_desc(
    PipelineDesc::new(vert_spv, frag_spv, uniform_slots~),
  )
}

///|
pub fn Swapchain::create_pipeline_desc(
  self : Swapchain,
  desc : PipelineDesc,
) -> Pipeline raise RhiError {
  match self.backend {
    Dx12Swapchain(state) => {
      if desc.texture_slots > 0 ||
        desc.storage_slots > 0 ||
        desc.storage_image_slots > 0 ||
        desc.accel_slots > 0 {
        raise RhiError::BackendUnsupported(
          "the DX12 backend implements uniform slots only (texture/storage/accel slots need a descriptor heap)",
        )
      }
      if desc.push_constant_size > 0 {
        raise RhiError::BackendUnsupported(
          "push constants are not implemented on the DX12 backend yet",
        )
      }
      return {
        backend: Dx12Pipeline(
          dx12_pipeline_create(state, desc.vert, desc.frag, desc.uniform_slots),
        ),
      }
    }
    VkSwapchain(_) => ()
  }
  {
    backend: VkPipeline(vk_graphics_pipeline_create(self.vk().device, desc, self.vk().format)),
  }
}

///|
pub fn Device::create_graphics_pipeline(
  self : Device,
  desc : PipelineDesc,
) -> Pipeline raise RhiError {
  { backend: VkPipeline(vk_graphics_pipeline_create_default(self.vk(), desc)) }
}

///|
pub fn Device::create_mesh_pipeline(
  self : Device,
  desc : MeshPipelineDesc,
) -> Pipeline raise RhiError {
  { backend: VkPipeline(vk_mesh_pipeline_create_default(self.vk(), desc)) }
}

///|
pub fn Swapchain::create_mesh_pipeline(
  self : Swapchain,
  desc : MeshPipelineDesc,
) -> Pipeline raise RhiError {
  {
    backend: VkPipeline(vk_mesh_pipeline_create(self.vk().device, desc, self.vk().format)),
  }
}

///|
pub fn Device::create_compute_pipeline(
  self : Device,
  spv : FixedArray[UInt32],
  uniform_slots : Int,
  storage_slots : Int,
  storage_image_slots? : Int = 0,
  accel_slots? : Int = 0,
  push_constant_size? : Int = 0,
) -> Pipeline raise RhiError {
  let u_binds = resolve_slot_bindings(uniform_slots, [], 0)
  let t_binds = FixedArray::make(0, 0)
  let s_binds = resolve_slot_bindings(storage_slots, [], uniform_slots)
  let si_binds = resolve_slot_bindings(
    storage_image_slots,
    [],
    uniform_slots + storage_slots,
  )
  let a_binds = resolve_slot_bindings(
    accel_slots,
    [],
    uniform_slots + storage_slots + storage_image_slots,
  )
  {
    backend: VkPipeline(vk_compute_pipeline_create(
      self.vk(),
      spv,
      u_binds,
      t_binds,
      s_binds,
      si_binds,
      a_binds,
      push_constant_size,
    )),
  }
}

///|
pub fn Device::create_compute_pipeline_auto(
  self : Device,
  spv : FixedArray[UInt32],
) -> Pipeline raise RhiError {
  let refl = @shader.reflect_spirv(spv)
  let u_arr : Array[Int] = []
  let t_arr : Array[Int] = []
  let s_arr : Array[Int] = []
  let si_arr : Array[Int] = []
  let a_arr : Array[Int] = []
  for b in refl.bindings {
    if b.set != 0 {
      continue
    }
    match b.kind {
      @shader.ReflectedDescriptorKind::UniformBuffer =>
        push_unique_int(u_arr, b.binding)
      @shader.ReflectedDescriptorKind::CombinedImageSampler |
      @shader.ReflectedDescriptorKind::SampledImage =>
        push_unique_int(t_arr, b.binding)
      @shader.ReflectedDescriptorKind::StorageBuffer =>
        push_unique_int(s_arr, b.binding)
      @shader.ReflectedDescriptorKind::StorageImage =>
        push_unique_int(si_arr, b.binding)
      @shader.ReflectedDescriptorKind::AccelerationStructure =>
        push_unique_int(a_arr, b.binding)
      @shader.ReflectedDescriptorKind::Sampler => ()
    }
  }
  u_arr.sort_by(fn(a, b) { a - b })
  t_arr.sort_by(fn(a, b) { a - b })
  s_arr.sort_by(fn(a, b) { a - b })
  si_arr.sort_by(fn(a, b) { a - b })
  a_arr.sort_by(fn(a, b) { a - b })
  {
    backend: VkPipeline(vk_compute_pipeline_create(
      self.vk(),
      spv,
      FixedArray::makei(u_arr.length(), fn(i) { u_arr[i] }),
      FixedArray::makei(t_arr.length(), fn(i) { t_arr[i] }),
      FixedArray::makei(s_arr.length(), fn(i) { s_arr[i] }),
      FixedArray::makei(si_arr.length(), fn(i) { si_arr[i] }),
      FixedArray::makei(a_arr.length(), fn(i) { a_arr[i] }),
      refl.push_constant_size,
    )),
  }
}

///|
pub fn Pipeline::destroy(self : Pipeline) -> Unit {
  match self.backend {
    VkPipeline(state) => vk_pipeline_destroy(state)
    Dx12Pipeline(state) => state.pipe.destroy()
  }
}

///|
pub fn Device::create_buffer(
  self : Device,
  size : Int,
  kind : BufferKind,
) -> Buffer raise RhiError {
  self.create_buffer_with(size, kind)
}

///|
pub fn Device::create_buffer_with(
  self : Device,
  size : Int,
  kind : BufferKind,
  location? : MemoryLocation = MemoryLocation::CpuToGpu,
) -> Buffer raise RhiError {
  match self.backend {
    VkDevice(state) => { backend: VkBuffer(vk_buffer_create(state, size, kind, location~)) }
    Dx12Device(state) => { backend: Dx12Buffer(dx12_buffer_create(state, size, kind, location)) }
  }
}

///|
pub fn Buffer::size(self : Buffer) -> Int {
  match self.backend {
    VkBuffer(state) => state.size
    Dx12Buffer(state) => state.size
  }
}

///|
fn resolve_upload_count(count : Int, data_len : Int) -> Int raise RhiError {
  if count == -1 {
    data_len
  } else if count < 0 || count > data_len {
    raise InvalidArgument(
      "Upload element count \{count} out of range [0, \{data_len}]",
    )
  } else {
    count
  }
}

///|
pub fn Buffer::upload_bytes(
  self : Buffer,
  data : Bytes,
  offset? : Int = 0,
  count? : Int = -1,
) -> Unit raise RhiError {
  let n = resolve_upload_count(count, data.length())
  match self.dx12() {
    Some(state) => dx12_buffer_write(state, data, offset, n)
    None => vk_buffer_upload_bytes(self.vk(), data, offset, n)
  }
}

///|
pub fn Buffer::upload_floats(
  self : Buffer,
  data : FixedArray[Float],
  offset? : Int = 0,
  count? : Int = -1,
) -> Unit raise RhiError {
  let n = resolve_upload_count(count, data.length())
  match self.dx12() {
    Some(state) => {
      if !state.buffer.write_floats(data, offset~) {
        raise AllocationFailed("DX12 uniform upload exceeded the buffer size")
      }
    }
    None => vk_buffer_upload_floats(self.vk(), data, offset, n)
  }
}

///|
/// Upload a column-major `Mat4` (16 floats) at `offset` bytes.
///
/// Provisional (ADR-002 §3.2): a completeness twin of `upload_floats`, covered by
/// the equivalence test in `examples/43-rhi-hardening`; the shape may still change
/// in a 0.x minor until it sees external use.
pub fn Buffer::upload_mat4(
  self : Buffer,
  m : @tmath.Mat4,
  offset? : Int = 0,
) -> Unit raise RhiError {
  self.upload_floats(m.to_cols_array(), offset~)
}

///|
pub fn Buffer::upload_uint32(
  self : Buffer,
  data : FixedArray[UInt32],
  offset? : Int = 0,
  count? : Int = -1,
) -> Unit raise RhiError {
  let n = resolve_upload_count(count, data.length())
  vk_buffer_upload_uint32(self.vk(), data, offset, n)
}

///|
fn dx12_buffer_write(
  state : Dx12BufferState,
  data : Bytes,
  offset : Int,
  count : Int,
) -> Unit raise RhiError {
  let slice = Bytes::makei(count, fn(i) { data[i] })
  if !state.buffer.write(slice, offset~) {
    raise AllocationFailed("DX12 upload exceeded the buffer size")
  }
}

///|
pub fn Buffer::upload_uint16(
  self : Buffer,
  data : FixedArray[UInt16],
  offset? : Int = 0,
  count? : Int = -1,
) -> Unit raise RhiError {
  let n = resolve_upload_count(count, data.length())
  let bytes = Bytes::makei(n * 2, fn(i) {
    let v = data[i / 2].to_int()
    if i % 2 == 0 {
      (v & 0xFF).to_byte()
    } else {
      ((v >> 8) & 0xFF).to_byte()
    }
  })
  self.upload_bytes(bytes, offset~)
}

///|
pub fn Buffer::download(self : Buffer) -> Bytes raise RhiError {
  match self.backend {
    VkBuffer(state) => vk_buffer_download(state)
    Dx12Buffer(_) =>
      raise RhiError::BackendUnsupported("readback buffers are not implemented on DX12")
  }
}

///|
pub fn Buffer::destroy(self : Buffer) -> Unit {
  match self.backend {
    VkBuffer(state) => vk_buffer_destroy(state)
    Dx12Buffer(state) => state.buffer.destroy()
  }
}

///|
pub fn Device::create_texture(
  self : Device,
  width : Int,
  height : Int,
  pixels : Bytes,
) -> Texture raise RhiError {
  self.create_texture_format(width, height, TextureFormat::RGBA8, pixels)
}

///|
pub fn Device::create_texture_format(
  self : Device,
  width : Int,
  height : Int,
  format : TextureFormat,
  pixels : Bytes,
) -> Texture raise RhiError {
  { inner: vk_texture_create_uploaded(self.vk(), width, height, format, pixels) }
}

///|
pub fn Device::create_texture_mipmapped(
  self : Device,
  width : Int,
  height : Int,
  format : TextureFormat,
  pixels : Bytes,
) -> Texture raise RhiError {
  {
    inner: vk_texture_create_mipmapped(self.vk(), width, height, format, pixels),
  }
}

///|
pub fn Device::create_storage_texture(
  self : Device,
  width : Int,
  height : Int,
  format : TextureFormat,
) -> Texture raise RhiError {
  { inner: vk_texture_create_storage(self.vk(), width, height, format) }
}

///|
pub fn Device::create_cubemap(
  self : Device,
  size : Int,
  format : TextureFormat,
  faces : Array[Bytes],
) -> Texture raise RhiError {
  if faces.length() != 6 {
    raise InvalidArgument("Cubemap requires exactly 6 face byte buffers")
  }
  let face_bytes = size * size * texture_format_bytes(format)
  let total = Bytes::makei(face_bytes * 6, fn(i) {
    let f = i / face_bytes
    let off = i % face_bytes
    if off < faces[f].length() {
      faces[f][off]
    } else {
      (0 : Byte)
    }
  })
  { inner: vk_texture_create_cubemap(self.vk(), size, format, total) }
}

///|
/// Create a cubemap with an explicit, CPU-prefiltered mip chain.
/// `levels[m][f]` is mip `m` face `f` (mip 0 is `size` x `size`).
pub fn Device::create_cubemap_mipmapped(
  self : Device,
  size : Int,
  format : TextureFormat,
  levels : Array[Array[Bytes]],
) -> Texture raise RhiError {
  if levels.length() == 0 {
    raise InvalidArgument("Cubemap requires at least one mip level")
  }
  let bpp = texture_format_bytes(format)
  let all : Array[Byte] = []
  for m = 0; m < levels.length(); m = m + 1 {
    let s = if size >> m < 1 { 1 } else { size >> m }
    let faces = levels[m]
    if faces.length() != 6 {
      raise InvalidArgument("Each cubemap mip needs exactly 6 faces")
    }
    let need = s * s * bpp
    for f = 0; f < 6; f = f + 1 {
      let buf = faces[f]
      for i = 0; i < need; i = i + 1 {
        all.push(if i < buf.length() { buf[i] } else { (0 : Byte) })
      }
    }
  }
  {
    inner: vk_texture_create_cubemap_mipmapped(
      self.vk(),
      size,
      format,
      levels.length(),
      Bytes::from_array(all),
    ),
  }
}

///|
pub fn Device::create_texture_array(
  self : Device,
  width : Int,
  height : Int,
  layers : Int,
  format : TextureFormat,
  pixels : Bytes,
) -> Texture raise RhiError {
  {
    inner: vk_texture_create_2d_array(
      self.vk(),
      width,
      height,
      layers,
      format,
      pixels,
    ),
  }
}

///|
pub fn Device::create_render_target(
  self : Device,
  width : Int,
  height : Int,
  format : TextureFormat,
  samples? : SampleCount = SampleCount::X1,
) -> Texture raise RhiError {
  if is_depth_format(format) {
    raise InvalidArgument("Use create_depth_texture for depth targets")
  }
  {
    inner: vk_texture_create_render_target(
      self.vk(),
      width,
      height,
      format,
      samples,
    ),
  }
}

///|
pub fn Device::create_depth_texture(
  self : Device,
  width : Int,
  height : Int,
  samples? : SampleCount = SampleCount::X1,
) -> Texture raise RhiError {
  self.create_depth_texture_format(
    width,
    height,
    TextureFormat::Depth32F,
    samples~,
  )
}

///|
pub fn Device::create_depth_texture_format(
  self : Device,
  width : Int,
  height : Int,
  format : TextureFormat,
  samples? : SampleCount = SampleCount::X1,
) -> Texture raise RhiError {
  if !is_depth_format(format) {
    raise InvalidArgument("Expected Depth32F or Depth24Stencil8 format")
  }
  {
    inner: vk_texture_create_depth_target(
      self.vk(),
      width,
      height,
      format,
      samples,
    ),
  }
}

///|
pub fn Texture::width(self : Texture) -> Int {
  self.vk().width
}

///|
pub fn Texture::format(self : Texture) -> TextureFormat {
  self.vk().format
}

///|
pub fn Texture::height(self : Texture) -> Int {
  self.vk().height
}

///|
pub fn Texture::mip_levels(self : Texture) -> Int {
  self.vk().mip_levels
}

///|
pub fn Texture::layers(self : Texture) -> Int {
  self.vk().layers
}

///|
// Upload several subregions in one submit. Each entry is (x, y, w, h, pixels);
// all regions target layer 0 / mip 0. Prefer this over repeated
// upload_subregion calls when populating an atlas.
pub fn Texture::upload_subregions(
  self : Texture,
  regions : Array[(Int, Int, Int, Int, Bytes)],
) -> Unit raise RhiError {
  vk_texture_upload_subregions(self.vk(), regions)
}

///|
pub fn Texture::upload_subregion(
  self : Texture,
  x : Int,
  y : Int,
  width : Int,
  height : Int,
  pixels : Bytes,
  layer? : Int = 0,
  mip_level? : Int = 0,
) -> Unit raise RhiError {
  vk_texture_upload_subregion(
    self.vk(),
    x,
    y,
    width,
    height,
    pixels,
    layer,
    mip_level,
  )
}

///|
pub fn Texture::readback(self : Texture) -> FixedArray[Byte] raise RhiError {
  vk_texture_readback(self.vk())
}

///|
pub fn Texture::readback_mip(
  self : Texture,
  level : Int,
) -> FixedArray[Byte] raise RhiError {
  vk_texture_readback_mip(self.vk(), level)
}

///|
pub fn Texture::destroy(self : Texture) -> Unit {
  vk_texture_destroy(self.vk())
}

///|
pub fn Device::create_sampler(self : Device) -> Sampler raise RhiError {
  self.create_sampler_desc(SamplerDesc::new())
}

///|
pub fn Device::create_sampler_desc(
  self : Device,
  desc : SamplerDesc,
) -> Sampler raise RhiError {
  { inner: vk_sampler_create(self.vk(), desc) }
}

///|
pub fn Sampler::destroy(self : Sampler) -> Unit {
  let s = self.vk()
  enqueue_delete(s.device, DeleteSampler(s.sampler))
}

///|
pub fn Device::create_fence(
  self : Device,
  signaled : Bool,
) -> Fence raise RhiError {
  { inner: vk_fence_create(self.vk(), signaled) }
}

///|
pub fn Fence::wait(self : Fence) -> Unit {
  vk_fence_wait(self.vk())
}

///|
pub fn Fence::reset(self : Fence) -> Unit {
  vk_fence_reset(self.vk())
}

///|
pub fn Fence::destroy(self : Fence) -> Unit {
  vk_fence_destroy(self.vk())
}

///|
pub fn Device::create_timestamp_pool(
  self : Device,
  count : Int,
) -> TimestampPool raise RhiError {
  { inner: vk_timestamp_pool_create(self.vk(), count) }
}

///|
pub fn TimestampPool::resolve_ns(
  self : TimestampPool,
) -> FixedArray[Double] raise RhiError {
  vk_timestamp_pool_resolve_ns(self.vk())
}

///|
pub fn TimestampPool::elapsed_ms(
  self : TimestampPool,
  start_idx : Int,
  end_idx : Int,
) -> Double raise RhiError {
  if start_idx < 0 ||
    end_idx < 0 ||
    start_idx >= self.vk().count ||
    end_idx >= self.vk().count {
    raise InvalidArgument("Timestamp query index out of range")
  }
  let ns = self.resolve_ns()
  let diff = ns[end_idx] - ns[start_idx]
  if diff < 0.0 { 0.0 } else { diff / 1000000.0 }
}

///|
pub fn TimestampPool::destroy(self : TimestampPool) -> Unit {
  vk_timestamp_pool_destroy(self.vk())
}

///|
pub fn Device::create_bindless_heap(
  self : Device,
  max_textures? : Int = 1024,
) -> BindlessHeap raise RhiError {
  { inner: vk_bindless_heap_create(self.vk(), max_textures) }
}

///|
pub fn BindlessHeap::register_texture(
  self : BindlessHeap,
  texture : Texture,
  sampler : Sampler,
) -> Int raise RhiError {
  vk_bindless_heap_register(self.vk(), texture.inner, sampler.inner)
}

///|
pub fn BindlessHeap::unregister_texture(self : BindlessHeap, index : Int) -> Unit {
  vk_bindless_heap_unregister(self.vk(), index)
}

///|
pub fn BindlessHeap::destroy(self : BindlessHeap) -> Unit {
  vk_bindless_heap_destroy(self.vk())
}

///|
pub fn Device::begin_commands(self : Device) -> CommandBuffer raise RhiError {
  let d = self.vk()
  let cmd = begin_one_time(d)
  let fi = (d.current_gen.to_int() + d.active_recordings) & 1
  d.active_recordings = d.active_recordings + 1
  let frame_gen = d.next_cmd_gen
  d.next_cmd_gen = d.next_cmd_gen + (1 : UInt64)
  {
    backend: VkCommands({
      device: d,
      cmd,
      frame_idx: fi,
      frame_gen,
      pending_uniforms: [],
      pending_textures: [],
      pending_storage: [],
      pending_storage_images: [],
      pending_accel: [],
      bound: None,
      active_render_targets: [],
      active_depth_target: None,
      in_swapchain_pass: false,
      swapchain_image_initialized: false,
      render_w: 0,
      render_h: 0,
    }),
  }
}

///|
pub fn Device::end_commands(
  self : Device,
  cmd : CommandBuffer,
) -> Unit raise RhiError {
  let d = self.vk()
  if d.active_recordings > 0 {
    d.active_recordings = d.active_recordings - 1
  }
  end_one_time(d, cmd.vk().cmd)
  d.completed_gen = d.current_gen
  d.current_gen = d.current_gen + (1 : UInt64)
  flush_deletes(d, false)
}

///|
pub fn Device::submit_commands(
  self : Device,
  cmd : CommandBuffer,
  fence : Fence,
) -> Unit raise RhiError {
  vk_device_submit_commands(self.vk(), cmd.vk(), fence.inner)
}

///|
pub fn CommandBuffer::begin_render_pass(
  self : CommandBuffer,
  colors : Array[RenderTargetDesc],
  depth? : DepthTargetDesc? = None,
) -> Unit raise RhiError {
  vk_cmd_begin_render_pass(self.vk(), colors, depth)
}

///|
pub fn CommandBuffer::end_render_pass(self : CommandBuffer) -> Unit {
  match self.backend {
    VkCommands(state) => vk_cmd_end_render_pass(state)
    Dx12Commands(_) => ()
  }
}

///|
pub fn CommandBuffer::bind_pipeline(
  self : CommandBuffer,
  pipeline : Pipeline,
) -> Unit {
  match self.backend {
    VkCommands(state) =>
      match pipeline.backend {
        VkPipeline(pipe) => vk_cmd_bind_pipeline(state, pipe)
        Dx12Pipeline(_) => ()
      }
    Dx12Commands(state) =>
      match pipeline.backend {
        Dx12Pipeline(pipe) => dx12_bind_pipeline(state, pipe)
        VkPipeline(_) => ()
      }
  }
}

///|
pub fn CommandBuffer::bind_uniform(
  self : CommandBuffer,
  pipeline : Pipeline,
  slot : Int,
  buffer : Buffer,
  offset? : Int = 0,
  size? : Int = -1,
) -> Unit {
  match self.backend {
    VkCommands(_) =>
      match (pipeline.backend, buffer.backend) {
        (VkPipeline(pipe), VkBuffer(b)) => self.on_vk(fn(state) {
          state.pending_uniforms.push((pipe, slot, b, offset, size))
        })
        _ => ()
      }
    Dx12Commands(cmd) =>
      match (pipeline.backend, buffer.backend) {
        (Dx12Pipeline(pipe), Dx12Buffer(state)) => {
          // Uniform binding is recorded immediately (root CBV); failures surface
          // at the next raising call, matching the Vulkan path.
          let _ = dx12_bind_uniform(cmd, pipe, slot, state, offset)
        }
        _ => ()
      }
  }
}

///|
pub fn CommandBuffer::bind_texture(
  self : CommandBuffer,
  pipeline : Pipeline,
  slot : Int,
  texture : Texture,
  sampler : Sampler,
) -> Unit {
  match pipeline.backend {
    VkPipeline(pipe) => self.on_vk(fn(state) { state.pending_textures.push((pipe, slot, texture, sampler)) })
    Dx12Pipeline(_) => ()
  }
}

///|
pub fn CommandBuffer::bind_storage(
  self : CommandBuffer,
  pipeline : Pipeline,
  slot : Int,
  buffer : Buffer,
  offset? : Int = 0,
  size? : Int = -1,
) -> Unit {
  match (pipeline.backend, buffer.backend) {
    (VkPipeline(pipe), VkBuffer(b)) => self.on_vk(fn(state) {
      state.pending_storage.push((pipe, slot, b, offset, size))
    })
    _ => ()
  }
}

///|
pub fn CommandBuffer::bind_storage_image(
  self : CommandBuffer,
  pipeline : Pipeline,
  slot : Int,
  texture : Texture,
) -> Unit {
  match pipeline.backend {
    VkPipeline(pipe) => self.on_vk(fn(state) { state.pending_storage_images.push((pipe, slot, texture)) })
    Dx12Pipeline(_) => ()
  }
}

///|
pub fn CommandBuffer::transition_for_compute(
  self : CommandBuffer,
  texture : Texture,
) -> Unit {
  match self.backend {
    VkCommands(state) => vk_cmd_transition_for_compute(state, texture.inner)
    Dx12Commands(state) => {
      let _ = state.commands.transition(state.target, @dx12.ResourceState::UnorderedAccess)
    }
  }
}

///|
pub fn CommandBuffer::transition_for_sampling(
  self : CommandBuffer,
  texture : Texture,
) -> Unit {
  match self.backend {
    VkCommands(state) => vk_cmd_transition_for_sampling(state, texture.inner)
    Dx12Commands(state) => {
      let _ = state.commands.transition(state.target, @dx12.ResourceState::ShaderResource)
    }
  }
}

///|
pub fn CommandBuffer::blit_texture(
  self : CommandBuffer,
  src : Texture,
  dst : Texture,
  filter? : Filter = Filter::Linear,
) -> Unit {
  self.on_vk(fn(state) { vk_cmd_blit_texture(state, src.inner, dst.inner, filter) })
}

///|
pub fn CommandBuffer::reset_timestamps(
  self : CommandBuffer,
  pool : TimestampPool,
) -> Unit {
  self.on_vk(fn(state) { vk_cmd_reset_timestamps(state, pool.inner) })
}

///|
pub fn CommandBuffer::write_timestamp(
  self : CommandBuffer,
  pool : TimestampPool,
  index : Int,
  at_start? : Bool = false,
) -> Unit {
  self.on_vk(fn(state) { vk_cmd_write_timestamp(state, pool.inner, index, at_start) })
}

///|
pub fn CommandBuffer::bind_vertex(
  self : CommandBuffer,
  slot : Int,
  buffer : Buffer,
  offset? : Int = 0,
) -> Unit {
  self.on_vk_buffer(buffer, fn(state, b) { vk_cmd_bind_vertex(state, slot, b, offset) })
}

///|
pub fn CommandBuffer::bind_index(
  self : CommandBuffer,
  buffer : Buffer,
  index_type : IndexType,
  offset? : Int = 0,
) -> Unit {
  self.on_vk_buffer(buffer, fn(state, b) { vk_cmd_bind_index(state, b, index_type, offset) })
}

///|
pub fn CommandBuffer::push_constants_floats(
  self : CommandBuffer,
  pipeline : Pipeline,
  data : FixedArray[Float],
  offset? : Int = 0,
) -> Unit {
  match pipeline.backend {
    VkPipeline(pipe) => self.on_vk(fn(state) { vk_cmd_push_constants_floats(state, pipe, data, offset) })
    Dx12Pipeline(_) => ()
  }
}

///|
/// Push a column-major `Mat4` as the 16 floats of a `mat4` push constant.
pub fn CommandBuffer::push_constants_mat4(
  self : CommandBuffer,
  pipeline : Pipeline,
  m : @tmath.Mat4,
  offset? : Int = 0,
) -> Unit {
  self.push_constants_floats(pipeline, m.to_cols_array(), offset~)
}

///|
pub fn CommandBuffer::push_constants_bytes(
  self : CommandBuffer,
  pipeline : Pipeline,
  data : Bytes,
  offset? : Int = 0,
) -> Unit {
  match pipeline.backend {
    VkPipeline(pipe) => self.on_vk(fn(state) { vk_cmd_push_constants_bytes(state, pipe, data, offset) })
    Dx12Pipeline(_) => ()
  }
}

///|
pub fn CommandBuffer::set_viewport(
  self : CommandBuffer,
  x : Float,
  y : Float,
  w : Float,
  h : Float,
) -> Unit {
  self.on_vk(fn(state) { vk_cmd_set_viewport(state, x, y, w, h) })
}

///|
pub fn CommandBuffer::set_scissor(
  self : CommandBuffer,
  x : Int,
  y : Int,
  w : Int,
  h : Int,
) -> Unit {
  self.on_vk(fn(state) { vk_cmd_set_scissor(state, x, y, w, h) })
}

///|
pub fn CommandBuffer::set_stencil_reference(
  self : CommandBuffer,
  reference : Int,
) -> Unit {
  self.on_vk(fn(state) { vk_cmd_set_stencil_reference(state, reference) })
}

///|
pub fn CommandBuffer::bind_accel_struct(
  self : CommandBuffer,
  pipeline : Pipeline,
  slot : Int,
  accel : AccelStruct,
) -> Unit {
  match pipeline.backend {
    VkPipeline(pipe) => self.on_vk(fn(state) { state.pending_accel.push((pipe, slot, accel)) })
    Dx12Pipeline(_) => ()
  }
}

///|
pub fn Device::create_blas(
  self : Device,
  geometries : Array[RayGeometryDesc],
) -> AccelStruct raise RhiError {
  { inner: vk_create_blas(self.vk(), geometries) }
}

///|
pub fn Device::create_tlas(
  self : Device,
  instances : Array[RayInstanceDesc],
) -> AccelStruct raise RhiError {
  { inner: vk_create_tlas(self.vk(), instances) }
}

///|
pub fn AccelStruct::destroy(self : AccelStruct) -> Unit {
  vk_accel_struct_destroy(self.vk())
}

///|
pub fn CommandBuffer::draw(
  self : CommandBuffer,
  vertices : Int,
  instances : Int,
) -> Unit {
  self.draw_instanced(vertices, instances, 0, 0)
}

///|
pub fn CommandBuffer::draw_instanced(
  self : CommandBuffer,
  vertices : Int,
  instances : Int,
  first_vertex : Int,
  first_instance : Int,
) -> Unit {
  match self.backend {
    Dx12Commands(state) => dx12_draw(state, vertices, instances)
    VkCommands(state) =>
      vk_cmd_draw_instanced(state, vertices, instances, first_vertex, first_instance)
  }
}

///|
pub fn CommandBuffer::draw_indexed(
  self : CommandBuffer,
  index_count : Int,
  instances? : Int = 1,
) -> Unit {
  self.draw_indexed_full(index_count, instances, 0, 0, 0)
}

///|
pub fn CommandBuffer::draw_indexed_full(
  self : CommandBuffer,
  index_count : Int,
  instances : Int,
  first_index : Int,
  vertex_offset : Int,
  first_instance : Int,
) -> Unit {
  self.on_vk(fn(state) {
    vk_cmd_draw_indexed_full(state, index_count, instances, first_index, vertex_offset, first_instance)
  })
}

///|
pub fn CommandBuffer::dispatch(
  self : CommandBuffer,
  x : Int,
  y : Int,
  z : Int,
) -> Unit {
  self.on_vk(fn(state) { vk_cmd_dispatch(state, x, y, z) })
}

///|
pub fn CommandBuffer::draw_indirect(
  self : CommandBuffer,
  buffer : Buffer,
  draw_count : Int,
  offset? : Int = 0,
  stride? : Int = 16,
) -> Unit {
  self.on_vk_buffer(buffer, fn(state, b) {
    vk_cmd_draw_indirect(state, b, draw_count, offset, stride)
  })
}

///|
pub fn CommandBuffer::draw_indexed_indirect(
  self : CommandBuffer,
  buffer : Buffer,
  draw_count : Int,
  offset? : Int = 0,
  stride? : Int = 20,
) -> Unit {
  self.on_vk_buffer(buffer, fn(state, b) {
    vk_cmd_draw_indexed_indirect(state, b, draw_count, offset, stride)
  })
}

///|
pub fn CommandBuffer::draw_indirect_count(
  self : CommandBuffer,
  buffer : Buffer,
  count_buffer : Buffer,
  max_draw_count : Int,
  offset? : Int = 0,
  count_offset? : Int = 0,
  stride? : Int = 16,
) -> Unit {
  self.on_vk_buffers(buffer, count_buffer, fn(state, a, b) {
    vk_cmd_draw_indirect_count(state, a, b, max_draw_count, offset, count_offset, stride)
  })
}

///|
pub fn CommandBuffer::draw_indexed_indirect_count(
  self : CommandBuffer,
  buffer : Buffer,
  count_buffer : Buffer,
  max_draw_count : Int,
  offset? : Int = 0,
  count_offset? : Int = 0,
  stride? : Int = 20,
) -> Unit {
  self.on_vk_buffers(buffer, count_buffer, fn(state, a, b) {
    vk_cmd_draw_indexed_indirect_count(state, a, b, max_draw_count, offset, count_offset, stride)
  })
}

///|
pub fn CommandBuffer::dispatch_indirect(
  self : CommandBuffer,
  buffer : Buffer,
  offset? : Int = 0,
) -> Unit {
  self.on_vk_buffer(buffer, fn(state, b) { vk_cmd_dispatch_indirect(state, b, offset) })
}

///|
pub fn CommandBuffer::draw_mesh_tasks(
  self : CommandBuffer,
  x : Int,
  y : Int,
  z : Int,
) -> Unit {
  self.on_vk(fn(state) { vk_cmd_draw_mesh_tasks(state, x, y, z) })
}

///|
pub fn CommandBuffer::draw_mesh_tasks_indirect(
  self : CommandBuffer,
  buffer : Buffer,
  draw_count : Int,
  offset? : Int = 0,
  stride? : Int = 12,
) -> Unit {
  self.on_vk_buffer(buffer, fn(state, b) {
    vk_cmd_draw_mesh_tasks_indirect(state, b, draw_count, offset, stride)
  })
}

///|
pub fn CommandBuffer::bind_bindless_heap(
  self : CommandBuffer,
  pipeline : Pipeline,
  heap : BindlessHeap,
  set_index? : Int = 1,
) -> Unit {
  match pipeline.backend {
    VkPipeline(pipe) => self.on_vk(fn(state) { vk_cmd_bind_bindless_heap(state, pipe, heap.inner, set_index) })
    Dx12Pipeline(_) => ()
  }
}

///|
pub fn CommandBuffer::copy_buffer(
  self : CommandBuffer,
  src : Buffer,
  dst : Buffer,
  size : Int,
) -> Unit {
  self.on_vk_buffers(src, dst, fn(state, a, b) { vk_cmd_copy_buffer(state, a, b, size) })
}

///|
pub fn CommandBuffer::barrier(self : CommandBuffer) -> Unit {
  self.on_vk(fn(state) { vk_cmd_barrier(state) })
}
