// Tycho RHI public API façade.
// Users import only `"laplaceliu/tycho" @tycho` — zero Vulkan handles, descriptor
// sets, sync primitives, or C stubs are exposed.

///|
pub struct Device {
  priv inner : VkDeviceState
}

///|
pub struct Swapchain {
  priv inner : VkSwapchainState
}

///|
pub struct Pipeline {
  priv inner : VkPipelineState
}

///|
pub struct Buffer {
  priv inner : VkBufferState
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
pub struct CommandBuffer {
  priv inner : VkCmdState
}

///|
pub fn Device::new(
  app_name : String,
  validation : Bool,
) -> Device raise RhiError {
  Device::new_desc(DeviceDesc::new(app_name, validation~, headless=false))
}

///|
pub fn Device::new_desc(desc : DeviceDesc) -> Device raise RhiError {
  { inner: vk_device_create(desc) }
}

///|
pub fn Device::capabilities(self : Device) -> DeviceCapabilities {
  self.inner.caps
}

///|
pub fn Device::pipeline_cache_data(self : Device) -> Bytes {
  vk_device_pipeline_cache_data(self.inner)
}

///|
pub fn Device::backend(self : Device) -> BackendKind {
  let _ = self
  BackendKind::Vulkan
}

///|
pub fn Device::validation_errors(self : Device) -> Int {
  g_rhi_validation_errors.val - self.inner.error_baseline
}

///|
pub fn Device::allocator_stats(self : Device) -> (Int, Int) {
  self.inner.alloc.stats()
}

///|
pub fn Device::allocator_used_bytes(self : Device) -> UInt64 {
  self.inner.alloc.used_bytes()
}

///|
pub fn Device::wait_idle(self : Device) -> Unit {
  vk_device_wait_idle(self.inner)
}

///|
pub fn Device::destroy(self : Device) -> Unit {
  vk_device_destroy(self.inner)
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
  { inner: vk_swapchain_create(self.inner, desc) }
}

///|
pub fn Swapchain::width(self : Swapchain) -> Int {
  self.inner.width
}

///|
pub fn Swapchain::height(self : Swapchain) -> Int {
  self.inner.height
}

///|
pub fn Swapchain::color_format(self : Swapchain) -> TextureFormat {
  vk_swapchain_color_format(self.inner)
}

///|
pub fn Swapchain::should_close(self : Swapchain) -> Bool {
  @win.should_close(self.inner.window) != 0
}

///|
pub fn Swapchain::poll_events(self : Swapchain) -> Array[Event] {
  @win.poll_events(self.inner.window)
}

///|
pub fn Swapchain::set_title(self : Swapchain, title : String) -> Unit {
  @win.set_title(self.inner.window, title)
}

///|
pub fn Swapchain::set_cursor_mode(self : Swapchain, mode : CursorMode) -> Unit {
  @win.set_cursor_mode(self.inner.window, mode)
}

///|
pub fn Swapchain::set_fullscreen(self : Swapchain, fullscreen : Bool) -> Unit {
  @win.set_fullscreen(self.inner.window, fullscreen)
}

///|
pub fn Swapchain::is_fullscreen(self : Swapchain) -> Bool {
  @win.is_fullscreen(self.inner.window)
}

///|
pub fn Swapchain::content_scale(self : Swapchain) -> Double {
  @win.content_scale(self.inner.window)
}

///|
pub fn Swapchain::time() -> Double {
  @win.time()
}

///|
pub fn Swapchain::begin_frame(self : Swapchain) -> CommandBuffer raise RhiError {
  { inner: vk_swapchain_begin_frame(self.inner) }
}

///|
pub fn Swapchain::begin_frame_commands(
  self : Swapchain,
) -> CommandBuffer raise RhiError {
  { inner: vk_swapchain_begin_frame_commands(self.inner) }
}

///|
pub fn CommandBuffer::blit_to_swapchain(
  self : CommandBuffer,
  src : Texture,
  swapchain : Swapchain,
) -> Unit {
  vk_cmd_blit_to_swapchain(self.inner, src.inner, swapchain.inner)
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
  vk_cmd_begin_swapchain_pass(self.inner, swapchain.inner, load_op, clear_color)
}

///|
pub fn CommandBuffer::end_swapchain_pass(self : CommandBuffer) -> Unit {
  vk_cmd_end_swapchain_pass(self.inner)
}

///|
pub fn Swapchain::end_frame(
  self : Swapchain,
  cmd : CommandBuffer,
) -> Unit raise RhiError {
  vk_swapchain_end_frame(self.inner, cmd.inner)
}

///|
pub fn Swapchain::readback(self : Swapchain) -> FixedArray[Byte] {
  vk_swapchain_readback(self.inner)
}

///|
pub fn Swapchain::destroy(self : Swapchain) -> Unit {
  vk_swapchain_destroy(self.inner)
}

///|
pub fn Swapchain::create_pipeline(
  self : Swapchain,
  vert_spv : FixedArray[UInt32],
  frag_spv : FixedArray[UInt32],
  uniform_slots : Int,
) -> Pipeline raise RhiError {
  self.create_pipeline_desc(
    PipelineDesc::new(vert_spv, frag_spv, uniform_slots~),
  )
}

///|
pub fn Swapchain::create_pipeline_desc(
  self : Swapchain,
  desc : PipelineDesc,
) -> Pipeline raise RhiError {
  {
    inner: vk_graphics_pipeline_create(
      self.inner.device,
      desc,
      self.inner.format,
    ),
  }
}

///|
pub fn Device::create_graphics_pipeline(
  self : Device,
  desc : PipelineDesc,
) -> Pipeline raise RhiError {
  { inner: vk_graphics_pipeline_create_default(self.inner, desc) }
}

///|
pub fn Device::create_mesh_pipeline(
  self : Device,
  desc : MeshPipelineDesc,
) -> Pipeline raise RhiError {
  { inner: vk_mesh_pipeline_create_default(self.inner, desc) }
}

///|
pub fn Swapchain::create_mesh_pipeline(
  self : Swapchain,
  desc : MeshPipelineDesc,
) -> Pipeline raise RhiError {
  {
    inner: vk_mesh_pipeline_create(
      self.inner.device,
      desc,
      self.inner.format,
    ),
  }
}

///|
pub fn Device::create_compute_pipeline(
  self : Device,
  spv : FixedArray[UInt32],
  uniform_slots : Int,
  storage_slots : Int,
  storage_image_slots? : Int = 0,
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
  {
    inner: vk_compute_pipeline_create(
      self.inner,
      spv,
      u_binds,
      t_binds,
      s_binds,
      si_binds,
      push_constant_size,
    ),
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
      @shader.ReflectedDescriptorKind::Sampler => ()
    }
  }
  u_arr.sort_by(fn(a, b) { a - b })
  t_arr.sort_by(fn(a, b) { a - b })
  s_arr.sort_by(fn(a, b) { a - b })
  si_arr.sort_by(fn(a, b) { a - b })
  {
    inner: vk_compute_pipeline_create(
      self.inner,
      spv,
      FixedArray::makei(u_arr.length(), fn(i) { u_arr[i] }),
      FixedArray::makei(t_arr.length(), fn(i) { t_arr[i] }),
      FixedArray::makei(s_arr.length(), fn(i) { s_arr[i] }),
      FixedArray::makei(si_arr.length(), fn(i) { si_arr[i] }),
      refl.push_constant_size,
    ),
  }
}

///|
pub fn Pipeline::destroy(self : Pipeline) -> Unit {
  vk_pipeline_destroy(self.inner)
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
  { inner: vk_buffer_create(self.inner, size, kind, location~) }
}

///|
pub fn Buffer::upload_bytes(
  self : Buffer,
  data : Bytes,
  offset? : Int = 0,
) -> Unit raise RhiError {
  vk_buffer_upload_bytes(self.inner, data, offset)
}

///|
pub fn Buffer::upload_floats(
  self : Buffer,
  data : FixedArray[Float],
  offset? : Int = 0,
) -> Unit raise RhiError {
  vk_buffer_upload_floats(self.inner, data, offset)
}

///|
pub fn Buffer::upload_uint32(
  self : Buffer,
  data : FixedArray[UInt32],
  offset? : Int = 0,
) -> Unit raise RhiError {
  vk_buffer_upload_uint32(self.inner, data, offset)
}

///|
pub fn Buffer::upload_uint16(
  self : Buffer,
  data : FixedArray[UInt16],
  offset? : Int = 0,
) -> Unit raise RhiError {
  let bytes = Bytes::makei(data.length() * 2, fn(i) {
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
  vk_buffer_download(self.inner)
}

///|
pub fn Buffer::destroy(self : Buffer) -> Unit {
  vk_buffer_destroy(self.inner)
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
  { inner: vk_texture_create_uploaded(self.inner, width, height, format, pixels) }
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
    inner: vk_texture_create_mipmapped(self.inner, width, height, format, pixels),
  }
}

///|
pub fn Device::create_storage_texture(
  self : Device,
  width : Int,
  height : Int,
  format : TextureFormat,
) -> Texture raise RhiError {
  { inner: vk_texture_create_storage(self.inner, width, height, format) }
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
  { inner: vk_texture_create_cubemap(self.inner, size, format, total) }
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
      self.inner,
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
      self.inner,
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
      self.inner,
      width,
      height,
      format,
      samples,
    ),
  }
}

///|
pub fn Texture::width(self : Texture) -> Int {
  self.inner.width
}

///|
pub fn Texture::height(self : Texture) -> Int {
  self.inner.height
}

///|
pub fn Texture::mip_levels(self : Texture) -> Int {
  self.inner.mip_levels
}

///|
pub fn Texture::layers(self : Texture) -> Int {
  self.inner.layers
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
    self.inner,
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
  vk_texture_readback(self.inner)
}

///|
pub fn Texture::readback_mip(
  self : Texture,
  level : Int,
) -> FixedArray[Byte] raise RhiError {
  vk_texture_readback_mip(self.inner, level)
}

///|
pub fn Texture::destroy(self : Texture) -> Unit {
  vk_texture_destroy(self.inner)
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
  { inner: vk_sampler_create(self.inner, desc) }
}

///|
pub fn Sampler::destroy(self : Sampler) -> Unit {
  let s = self.inner
  enqueue_delete(s.device, DeleteSampler(s.sampler))
}

///|
pub fn Device::create_fence(
  self : Device,
  signaled : Bool,
) -> Fence raise RhiError {
  { inner: vk_fence_create(self.inner, signaled) }
}

///|
pub fn Fence::wait(self : Fence) -> Unit {
  vk_fence_wait(self.inner)
}

///|
pub fn Fence::reset(self : Fence) -> Unit {
  vk_fence_reset(self.inner)
}

///|
pub fn Fence::destroy(self : Fence) -> Unit {
  vk_fence_destroy(self.inner)
}

///|
pub fn Device::create_timestamp_pool(
  self : Device,
  count : Int,
) -> TimestampPool raise RhiError {
  { inner: vk_timestamp_pool_create(self.inner, count) }
}

///|
pub fn TimestampPool::resolve_ns(
  self : TimestampPool,
) -> FixedArray[Double] raise RhiError {
  vk_timestamp_pool_resolve_ns(self.inner)
}

///|
pub fn TimestampPool::elapsed_ms(
  self : TimestampPool,
  start_idx : Int,
  end_idx : Int,
) -> Double raise RhiError {
  if start_idx < 0 ||
    end_idx < 0 ||
    start_idx >= self.inner.count ||
    end_idx >= self.inner.count {
    raise InvalidArgument("Timestamp query index out of range")
  }
  let ns = self.resolve_ns()
  let diff = ns[end_idx] - ns[start_idx]
  if diff < 0.0 { 0.0 } else { diff / 1000000.0 }
}

///|
pub fn TimestampPool::destroy(self : TimestampPool) -> Unit {
  vk_timestamp_pool_destroy(self.inner)
}

///|
pub fn Device::create_bindless_heap(
  self : Device,
  max_textures? : Int = 1024,
) -> BindlessHeap raise RhiError {
  { inner: vk_bindless_heap_create(self.inner, max_textures) }
}

///|
pub fn BindlessHeap::register_texture(
  self : BindlessHeap,
  texture : Texture,
  sampler : Sampler,
) -> Int raise RhiError {
  vk_bindless_heap_register(self.inner, texture.inner, sampler.inner)
}

///|
pub fn BindlessHeap::unregister_texture(self : BindlessHeap, index : Int) -> Unit {
  vk_bindless_heap_unregister(self.inner, index)
}

///|
pub fn BindlessHeap::destroy(self : BindlessHeap) -> Unit {
  vk_bindless_heap_destroy(self.inner)
}

///|
pub fn Device::begin_commands(self : Device) -> CommandBuffer raise RhiError {
  let d = self.inner
  let cmd = begin_one_time(d)
  d.active_recordings = d.active_recordings + 1
  {
    inner: {
      device: d,
      cmd,
      frame_idx: 0,
      frame_gen: d.current_gen,
      pending_uniforms: [],
      pending_textures: [],
      pending_storage: [],
      pending_storage_images: [],
      bound: None,
      active_render_targets: [],
      active_depth_target: None,
      in_swapchain_pass: false,
      swapchain_image_initialized: false,
    },
  }
}

///|
pub fn Device::end_commands(
  self : Device,
  cmd : CommandBuffer,
) -> Unit raise RhiError {
  let d = self.inner
  if d.active_recordings > 0 {
    d.active_recordings = d.active_recordings - 1
  }
  end_one_time(d, cmd.inner.cmd)
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
  vk_device_submit_commands(self.inner, cmd.inner, fence.inner)
}

///|
pub fn CommandBuffer::begin_render_pass(
  self : CommandBuffer,
  colors : Array[RenderTargetDesc],
  depth? : DepthTargetDesc? = None,
) -> Unit raise RhiError {
  vk_cmd_begin_render_pass(self.inner, colors, depth)
}

///|
pub fn CommandBuffer::end_render_pass(self : CommandBuffer) -> Unit {
  vk_cmd_end_render_pass(self.inner)
}

///|
pub fn CommandBuffer::bind_pipeline(
  self : CommandBuffer,
  pipeline : Pipeline,
) -> Unit {
  vk_cmd_bind_pipeline(self.inner, pipeline)
}

///|
pub fn CommandBuffer::bind_uniform(
  self : CommandBuffer,
  pipeline : Pipeline,
  slot : Int,
  buffer : Buffer,
) -> Unit {
  self.inner.pending_uniforms.push((pipeline, slot, buffer))
}

///|
pub fn CommandBuffer::bind_texture(
  self : CommandBuffer,
  pipeline : Pipeline,
  slot : Int,
  texture : Texture,
  sampler : Sampler,
) -> Unit {
  self.inner.pending_textures.push((pipeline, slot, texture, sampler))
}

///|
pub fn CommandBuffer::bind_storage(
  self : CommandBuffer,
  pipeline : Pipeline,
  slot : Int,
  buffer : Buffer,
) -> Unit {
  self.inner.pending_storage.push((pipeline, slot, buffer))
}

///|
pub fn CommandBuffer::bind_storage_image(
  self : CommandBuffer,
  pipeline : Pipeline,
  slot : Int,
  texture : Texture,
) -> Unit {
  self.inner.pending_storage_images.push((pipeline, slot, texture))
}

///|
pub fn CommandBuffer::transition_for_compute(
  self : CommandBuffer,
  texture : Texture,
) -> Unit {
  vk_cmd_transition_for_compute(self.inner, texture.inner)
}

///|
pub fn CommandBuffer::transition_for_sampling(
  self : CommandBuffer,
  texture : Texture,
) -> Unit {
  vk_cmd_transition_for_sampling(self.inner, texture.inner)
}

///|
pub fn CommandBuffer::blit_texture(
  self : CommandBuffer,
  src : Texture,
  dst : Texture,
  filter? : Filter = Filter::Linear,
) -> Unit {
  vk_cmd_blit_texture(self.inner, src.inner, dst.inner, filter)
}

///|
pub fn CommandBuffer::reset_timestamps(
  self : CommandBuffer,
  pool : TimestampPool,
) -> Unit {
  vk_cmd_reset_timestamps(self.inner, pool.inner)
}

///|
pub fn CommandBuffer::write_timestamp(
  self : CommandBuffer,
  pool : TimestampPool,
  index : Int,
  at_start? : Bool = false,
) -> Unit {
  vk_cmd_write_timestamp(self.inner, pool.inner, index, at_start)
}

///|
pub fn CommandBuffer::bind_vertex(
  self : CommandBuffer,
  slot : Int,
  buffer : Buffer,
  offset? : Int = 0,
) -> Unit {
  vk_cmd_bind_vertex(self.inner, slot, buffer.inner, offset)
}

///|
pub fn CommandBuffer::bind_index(
  self : CommandBuffer,
  buffer : Buffer,
  index_type : IndexType,
  offset? : Int = 0,
) -> Unit {
  vk_cmd_bind_index(self.inner, buffer.inner, index_type, offset)
}

///|
pub fn CommandBuffer::push_constants_floats(
  self : CommandBuffer,
  pipeline : Pipeline,
  data : FixedArray[Float],
  offset? : Int = 0,
) -> Unit {
  vk_cmd_push_constants_floats(self.inner, pipeline.inner, data, offset)
}

///|
pub fn CommandBuffer::push_constants_bytes(
  self : CommandBuffer,
  pipeline : Pipeline,
  data : Bytes,
  offset? : Int = 0,
) -> Unit {
  vk_cmd_push_constants_bytes(self.inner, pipeline.inner, data, offset)
}

///|
pub fn CommandBuffer::set_viewport(
  self : CommandBuffer,
  x : Float,
  y : Float,
  w : Float,
  h : Float,
) -> Unit {
  vk_cmd_set_viewport(self.inner, x, y, w, h)
}

///|
pub fn CommandBuffer::set_scissor(
  self : CommandBuffer,
  x : Int,
  y : Int,
  w : Int,
  h : Int,
) -> Unit {
  vk_cmd_set_scissor(self.inner, x, y, w, h)
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
  vk_cmd_draw_instanced(
    self.inner,
    vertices,
    instances,
    first_vertex,
    first_instance,
  )
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
  vk_cmd_draw_indexed_full(
    self.inner,
    index_count,
    instances,
    first_index,
    vertex_offset,
    first_instance,
  )
}

///|
pub fn CommandBuffer::dispatch(
  self : CommandBuffer,
  x : Int,
  y : Int,
  z : Int,
) -> Unit {
  vk_cmd_dispatch(self.inner, x, y, z)
}

///|
pub fn CommandBuffer::draw_indirect(
  self : CommandBuffer,
  buffer : Buffer,
  draw_count : Int,
  offset? : Int = 0,
  stride? : Int = 16,
) -> Unit {
  vk_cmd_draw_indirect(self.inner, buffer.inner, draw_count, offset, stride)
}

///|
pub fn CommandBuffer::draw_indexed_indirect(
  self : CommandBuffer,
  buffer : Buffer,
  draw_count : Int,
  offset? : Int = 0,
  stride? : Int = 20,
) -> Unit {
  vk_cmd_draw_indexed_indirect(
    self.inner,
    buffer.inner,
    draw_count,
    offset,
    stride,
  )
}

///|
pub fn CommandBuffer::dispatch_indirect(
  self : CommandBuffer,
  buffer : Buffer,
  offset? : Int = 0,
) -> Unit {
  vk_cmd_dispatch_indirect(self.inner, buffer.inner, offset)
}

///|
pub fn CommandBuffer::draw_mesh_tasks(
  self : CommandBuffer,
  x : Int,
  y : Int,
  z : Int,
) -> Unit {
  vk_cmd_draw_mesh_tasks(self.inner, x, y, z)
}

///|
pub fn CommandBuffer::draw_mesh_tasks_indirect(
  self : CommandBuffer,
  buffer : Buffer,
  draw_count : Int,
  offset? : Int = 0,
  stride? : Int = 12,
) -> Unit {
  vk_cmd_draw_mesh_tasks_indirect(
    self.inner,
    buffer.inner,
    draw_count,
    offset,
    stride,
  )
}

///|
pub fn CommandBuffer::bind_bindless_heap(
  self : CommandBuffer,
  pipeline : Pipeline,
  heap : BindlessHeap,
  set_index? : Int = 1,
) -> Unit {
  vk_cmd_bind_bindless_heap(self.inner, pipeline.inner, heap.inner, set_index)
}

///|
pub fn CommandBuffer::copy_buffer(
  self : CommandBuffer,
  src : Buffer,
  dst : Buffer,
  size : Int,
) -> Unit {
  vk_cmd_copy_buffer(self.inner, src.inner, dst.inner, size)
}

///|
pub fn CommandBuffer::barrier(self : CommandBuffer) -> Unit {
  vk_cmd_barrier(self.inner)
}
