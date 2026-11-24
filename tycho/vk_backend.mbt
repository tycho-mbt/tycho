// Tycho RHI — Vulkan 1.3 backend implementation (pure MoonBit via @vk / @win).
// Uses Dynamic Rendering, Synchronization2, 2 frames-in-flight, automatic
// swapchain resize recreation, and the pure-MoonBit SubAllocator.

const MAX_FRAMES : Int = 2

const SETS_PER_FRAME : Int = 16

let g_rhi_validation_errors : Ref[Int] = Ref(0)

///|
priv enum DeleteKind {
  DeleteBuffer(@vk.VkBuffer, MemAlloc)
  DeleteTexture(@vk.VkImageView, @vk.VkImageView, @vk.VkImage, MemAlloc)
  DeleteSampler(@vk.VkSampler)
  DeletePipeline(
    @vk.VkPipeline,
    @vk.VkPipelineLayout,
    @vk.VkDescriptorSetLayout,
    Array[@vk.VkDescriptorPool],
    @vk.VkShaderModule,
    @vk.VkShaderModule,
    @vk.VkShaderModule,
  )
  DeleteTimestampPool(@vk.VkQueryPool)
  DeleteBindlessHeap(@vk.VkDescriptorPool, @vk.VkDescriptorSetLayout)
  DeleteAccelStruct(@vk.VkAccelerationStructureKHR, @vk.VkBuffer, MemAlloc)
}

///|
priv struct DeferredDelete {
  ready_after_gen : UInt64
  kind : DeleteKind
}

///|
priv struct VkDeviceState {
  inst : @vk.VkInstance
  ifn : @vk.InstanceFn
  phys : @vk.VkPhysicalDevice
  dev : @vk.VkDevice
  dfn : @vk.DeviceFn
  queue : @vk.VkQueue
  queue_family : UInt32
  pool : @vk.VkCommandPool
  pipeline_cache : @vk.VkPipelineCache
  alloc : SubAllocator
  messenger : @vk.VkDebugUtilsMessengerEXT
  error_baseline : Int
  timestamp_period_ns : Float
  supports_timestamps : Bool
  headless : Bool
  caps : DeviceCapabilities
  mut current_gen : UInt64
  mut completed_gen : UInt64
  mut active_recordings : Int
  pending_deletes : Array[DeferredDelete]
  depth_stencil_vk_format : UInt32
}

///|
priv struct VkSwapchainState {
  device : VkDeviceState
  window : UInt64
  surface : @vk.VkSurfaceKHR
  mut swapchain : @vk.VkSwapchainKHR
  mut format : UInt32
  mut images : FixedArray[@vk.VkImage]
  mut views : FixedArray[@vk.VkImageView]
  mut render_finished : Array[@vk.VkSemaphore]
  has_depth : Bool
  enable_readback : Bool
  present_mode : PresentMode
  mut depth_image : @vk.VkImage
  mut depth_view : @vk.VkImageView
  mut depth_mem : MemAlloc?
  pool : @vk.VkCommandPool
  cmds : FixedArray[@vk.VkCommandBuffer]
  image_available : FixedArray[@vk.VkSemaphore]
  in_flight : FixedArray[@vk.VkFence]
  slot_gen : FixedArray[UInt64]
  readback_bufs : Array[VkBufferState]
  clear_color : ClearColor
  mut width : Int
  mut height : Int
  mut frame_idx : Int
  mut last_frame_idx : Int
  mut image_index : Int
  mut frame_gen : UInt64
  mut needs_recreate : Bool
}

///|
priv struct VkPipelineState {
  device : VkDeviceState
  pipeline : @vk.VkPipeline
  layout : @vk.VkPipelineLayout
  set_layout : @vk.VkDescriptorSetLayout
  pools : Array[@vk.VkDescriptorPool]
  frame_sets : FixedArray[Array[@vk.VkDescriptorSet]]
  last_gen : FixedArray[UInt64]
  set_cursor : FixedArray[Int]
  slot_dirty : FixedArray[Bool]
  vert_module : @vk.VkShaderModule
  frag_module : @vk.VkShaderModule
  task_module : @vk.VkShaderModule
  stage_flags : UInt32
  uniform_slots : Int
  texture_slots : Int
  storage_slots : Int
  storage_image_slots : Int
  accel_slots : Int
  uniform_bindings : FixedArray[Int]
  texture_bindings : FixedArray[Int]
  storage_bindings : FixedArray[Int]
  storage_image_bindings : FixedArray[Int]
  accel_bindings : FixedArray[Int]
  compute : Bool
  stencil_ref : UInt32?
  cur_uniforms : FixedArray[Buffer?]
  cur_textures : FixedArray[(Texture, Sampler)?]
  cur_storage : FixedArray[Buffer?]
  cur_storage_images : FixedArray[Texture?]
  cur_accel : FixedArray[AccelStruct?]
}

///|
priv struct VkBufferState {
  device : VkDeviceState
  buffer : @vk.VkBuffer
  alloc : MemAlloc
  size : Int
}

///|
priv struct VkTextureState {
  device : VkDeviceState
  image : @vk.VkImage
  alloc : MemAlloc
  view : @vk.VkImageView
  attachment_view : @vk.VkImageView
  format : TextureFormat
  samples : SampleCount
  width : Int
  height : Int
  mip_levels : Int
  layers : Int
  aspect : UInt32
  mut layout : UInt32
}

///|
priv struct VkSamplerState {
  device : VkDeviceState
  sampler : @vk.VkSampler
}

///|
priv struct VkFenceState {
  device : VkDeviceState
  fence : @vk.VkFence
  mut submitted_gen : UInt64
}

///|
priv struct VkTimestampPoolState {
  device : VkDeviceState
  pool : @vk.VkQueryPool
  count : Int
}

///|
priv struct VkBindlessHeapState {
  device : VkDeviceState
  set_layout : @vk.VkDescriptorSetLayout
  pool : @vk.VkDescriptorPool
  set : @vk.VkDescriptorSet
  capacity : Int
  mut next_idx : Int
  free_indices : Array[Int]
}

///|
priv struct VkAccelStructState {
  device : VkDeviceState
  accel : @vk.VkAccelerationStructureKHR
  buffer : @vk.VkBuffer
  alloc : MemAlloc
  device_address : UInt64
}

///|
priv struct VkCmdState {
  device : VkDeviceState
  cmd : @vk.VkCommandBuffer
  frame_idx : Int
  frame_gen : UInt64
  pending_uniforms : Array[(Pipeline, Int, Buffer)]
  pending_textures : Array[(Pipeline, Int, Texture, Sampler)]
  pending_storage : Array[(Pipeline, Int, Buffer)]
  pending_storage_images : Array[(Pipeline, Int, Texture)]
  pending_accel : Array[(Pipeline, Int, AccelStruct)]
  mut bound : Pipeline?
  mut active_render_targets : Array[RenderTargetDesc]
  mut active_depth_target : DepthTargetDesc?
  mut in_swapchain_pass : Bool
  mut swapchain_image_initialized : Bool
}

///|
fn vk_vertex_format(f : VertexFormat) -> UInt32 {
  match f {
    VertexFormat::Float2 => @vk.VK_FORMAT_R32G32_SFLOAT
    VertexFormat::Float3 => @vk.VK_FORMAT_R32G32B32_SFLOAT
    VertexFormat::Float4 => @vk.VK_FORMAT_R32G32B32A32_SFLOAT
  }
}

///|
fn vertex_format_bytes(f : VertexFormat) -> Int {
  match f {
    VertexFormat::Float2 => 8
    VertexFormat::Float3 => 12
    VertexFormat::Float4 => 16
  }
}

///|
fn vk_texture_format(f : TextureFormat) -> UInt32 {
  match f {
    TextureFormat::RGBA8 => @vk.VK_FORMAT_R8G8B8A8_UNORM
    TextureFormat::BGRA8 => @vk.VK_FORMAT_B8G8R8A8_UNORM
    TextureFormat::RGBA8Srgb => @vk.VK_FORMAT_R8G8B8A8_SRGB
    TextureFormat::BGRA8Srgb => @vk.VK_FORMAT_B8G8R8A8_SRGB
    TextureFormat::RGBA16F => @vk.VK_FORMAT_R16G16B16A16_SFLOAT
    TextureFormat::RG16F => @vk.VK_FORMAT_R16G16_SFLOAT
    TextureFormat::R8 => @vk.VK_FORMAT_R8_UNORM
    TextureFormat::RGBA32F => @vk.VK_FORMAT_R32G32B32A32_SFLOAT
    TextureFormat::Depth32F => @vk.VK_FORMAT_D32_SFLOAT
    TextureFormat::Depth24Stencil8 => @vk.VK_FORMAT_D24_UNORM_S8_UINT
  }
}

///|
fn vk_texture_format_for(d : VkDeviceState, f : TextureFormat) -> UInt32 {
  match f {
    TextureFormat::Depth24Stencil8 => d.depth_stencil_vk_format
    _ => vk_texture_format(f)
  }
}

///|
fn texture_format_bytes(f : TextureFormat) -> Int {
  match f {
    TextureFormat::RGBA8 => 4
    TextureFormat::BGRA8 => 4
    TextureFormat::RGBA8Srgb => 4
    TextureFormat::BGRA8Srgb => 4
    TextureFormat::RGBA16F => 8
    TextureFormat::RG16F => 4
    TextureFormat::R8 => 1
    TextureFormat::RGBA32F => 16
    TextureFormat::Depth32F => 4
    TextureFormat::Depth24Stencil8 => 4
  }
}

///|
fn is_depth_format(f : TextureFormat) -> Bool {
  f == TextureFormat::Depth32F || f == TextureFormat::Depth24Stencil8
}

///|
fn depth_barrier_aspect(f : TextureFormat) -> UInt32 {
  match f {
    TextureFormat::Depth24Stencil8 =>
      @vk.VK_IMAGE_ASPECT_DEPTH_BIT | @vk.VK_IMAGE_ASPECT_STENCIL_BIT
    _ => @vk.VK_IMAGE_ASPECT_DEPTH_BIT
  }
}

///|
fn vk_filter(f : Filter) -> UInt32 {
  match f {
    Filter::Nearest => @vk.VK_FILTER_NEAREST
    Filter::Linear => @vk.VK_FILTER_LINEAR
  }
}

///|
fn vk_address(a : AddressMode) -> UInt32 {
  match a {
    AddressMode::Repeat => @vk.VK_SAMPLER_ADDRESS_MODE_REPEAT
    AddressMode::ClampToEdge => @vk.VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE
    AddressMode::ClampToBorder => @vk.VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_BORDER
  }
}

///|
fn vk_border_color(b : BorderColor) -> UInt32 {
  match b {
    BorderColor::TransparentBlack => @vk.VK_BORDER_COLOR_FLOAT_TRANSPARENT_BLACK
    BorderColor::OpaqueBlack => @vk.VK_BORDER_COLOR_FLOAT_OPAQUE_BLACK
    BorderColor::OpaqueWhite => @vk.VK_BORDER_COLOR_FLOAT_OPAQUE_WHITE
  }
}

///|
fn vk_cull(c : CullMode) -> UInt32 {
  match c {
    CullMode::None => @vk.VK_CULL_MODE_NONE
    CullMode::Back => @vk.VK_CULL_MODE_BACK_BIT
    CullMode::Front => @vk.VK_CULL_MODE_FRONT_BIT
  }
}

///|
fn vk_front_face(f : FrontFace) -> UInt32 {
  match f {
    FrontFace::Clockwise => @vk.VK_FRONT_FACE_CLOCKWISE
    FrontFace::CounterClockwise => @vk.VK_FRONT_FACE_COUNTER_CLOCKWISE
  }
}

///|
fn vk_load_op(op : LoadOp) -> UInt32 {
  match op {
    LoadOp::Clear => @vk.VK_ATTACHMENT_LOAD_OP_CLEAR
    LoadOp::Load => @vk.VK_ATTACHMENT_LOAD_OP_LOAD
    LoadOp::DontCare => @vk.VK_ATTACHMENT_LOAD_OP_DONT_CARE
  }
}

///|
fn vk_store_op(op : StoreOp) -> UInt32 {
  match op {
    StoreOp::Store => @vk.VK_ATTACHMENT_STORE_OP_STORE
    StoreOp::DontCare => @vk.VK_ATTACHMENT_STORE_OP_DONT_CARE
  }
}

///|
fn vk_samples(s : SampleCount) -> UInt32 {
  match s {
    SampleCount::X1 => @vk.VK_SAMPLE_COUNT_1_BIT
    SampleCount::X4 => @vk.VK_SAMPLE_COUNT_4_BIT
  }
}

///|
fn vk_topology(t : PrimitiveTopology) -> UInt32 {
  match t {
    PrimitiveTopology::TriangleList => @vk.VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST
    PrimitiveTopology::TriangleStrip => @vk.VK_PRIMITIVE_TOPOLOGY_TRIANGLE_STRIP
    PrimitiveTopology::LineList => @vk.VK_PRIMITIVE_TOPOLOGY_LINE_LIST
    PrimitiveTopology::LineStrip => @vk.VK_PRIMITIVE_TOPOLOGY_LINE_STRIP
    PrimitiveTopology::PointList => @vk.VK_PRIMITIVE_TOPOLOGY_POINT_LIST
  }
}

///|
fn vk_compare_op(c : CompareOp) -> UInt32 {
  match c {
    CompareOp::Never => @vk.VK_COMPARE_OP_NEVER
    CompareOp::Less => @vk.VK_COMPARE_OP_LESS
    CompareOp::Equal => @vk.VK_COMPARE_OP_EQUAL
    CompareOp::LessEqual => @vk.VK_COMPARE_OP_LESS_OR_EQUAL
    CompareOp::Greater => @vk.VK_COMPARE_OP_GREATER
    CompareOp::NotEqual => @vk.VK_COMPARE_OP_NOT_EQUAL
    CompareOp::GreaterEqual => @vk.VK_COMPARE_OP_GREATER_OR_EQUAL
    CompareOp::Always => @vk.VK_COMPARE_OP_ALWAYS
  }
}

///|
fn vk_step_mode(m : VertexStepMode) -> UInt32 {
  match m {
    VertexStepMode::Vertex => @vk.VK_VERTEX_INPUT_RATE_VERTEX
    VertexStepMode::Instance => @vk.VK_VERTEX_INPUT_RATE_INSTANCE
  }
}

///|
fn has_instance_layer(name : String) -> Bool {
  let cnt = FixedArray::make(1, (0 : UInt32))
  let _ = @vk.vkEnumerateInstanceLayerProperties(
    cnt,
    @vk.VkLayerProperties::null(),
  )
  let n = cnt[0].reinterpret_as_int()
  if n <= 0 {
    return false
  }
  let props = @vk.VkLayerProperties::array(n)
  let _ = @vk.vkEnumerateInstanceLayerProperties(cnt, props)
  let mut found = false
  for i = 0; i < n; i = i + 1 {
    if props.get_layerName_string_at(i) == name {
      found = true
      break
    }
  }
  props.free()
  found
}

///|
fn has_instance_extension(name : String) -> Bool {
  let cnt = FixedArray::make(1, (0 : UInt32))
  let _ = @vk.vkEnumerateInstanceExtensionProperties(
    (0 : UInt64),
    cnt,
    @vk.VkExtensionProperties::null(),
  )
  let n = cnt[0].reinterpret_as_int()
  if n <= 0 {
    return false
  }
  let props = @vk.VkExtensionProperties::array(n)
  let _ = @vk.vkEnumerateInstanceExtensionProperties((0 : UInt64), cnt, props)
  let mut found = false
  for i = 0; i < n; i = i + 1 {
    if props.get_extensionName_string_at(i) == name {
      found = true
      break
    }
  }
  props.free()
  found
}

///|
fn has_device_extension(
  ifn : @vk.InstanceFn,
  phys : @vk.VkPhysicalDevice,
  name : String,
) -> Bool {
  let cnt = FixedArray::make(1, (0 : UInt32))
  let _ = (ifn.vkEnumerateDeviceExtensionProperties)(
    phys,
    (0 : UInt64),
    cnt,
    @vk.VkExtensionProperties::null(),
  )
  let n = cnt[0].reinterpret_as_int()
  if n <= 0 {
    return false
  }
  let props = @vk.VkExtensionProperties::array(n)
  let _ = (ifn.vkEnumerateDeviceExtensionProperties)(
    phys,
    (0 : UInt64),
    cnt,
    props,
  )
  let mut found = false
  for i = 0; i < n; i = i + 1 {
    if props.get_extensionName_string_at(i) == name {
      found = true
      break
    }
  }
  props.free()
  found
}

///|
fn max_samples_from_mask(mask : UInt32) -> Int {
  if (mask & (8 : UInt32)) != (0 : UInt32) {
    8
  } else if (mask & (4 : UInt32)) != (0 : UInt32) {
    4
  } else if (mask & (2 : UInt32)) != (0 : UInt32) {
    2
  } else {
    1
  }
}

///|
fn execute_delete(d : VkDeviceState, item : DeleteKind) -> Unit {
  let na = @vk.VkAllocationCallbacks::null()
  match item {
    DeleteBuffer(buf, alloc) => {
      (d.dfn.vkDestroyBuffer)(d.dev, buf, na)
      d.alloc.free(alloc)
    }
    DeleteTexture(view, attachment_view, image, alloc) => {
      if attachment_view.as_ptr() != view.as_ptr() &&
        attachment_view.as_ptr() != (0 : UInt64) {
        (d.dfn.vkDestroyImageView)(d.dev, attachment_view, na)
      }
      (d.dfn.vkDestroyImageView)(d.dev, view, na)
      (d.dfn.vkDestroyImage)(d.dev, image, na)
      d.alloc.free(alloc)
    }
    DeleteSampler(sampler) => (d.dfn.vkDestroySampler)(d.dev, sampler, na)
    DeletePipeline(
      pipeline,
      layout,
      set_layout,
      pools,
      vert_module,
      frag_module,
      task_module,
    ) => {
      (d.dfn.vkDestroyPipeline)(d.dev, pipeline, na)
      (d.dfn.vkDestroyPipelineLayout)(d.dev, layout, na)
      (d.dfn.vkDestroyDescriptorSetLayout)(d.dev, set_layout, na)
      for pool in pools {
        (d.dfn.vkDestroyDescriptorPool)(d.dev, pool, na)
      }
      (d.dfn.vkDestroyShaderModule)(d.dev, vert_module, na)
      if frag_module.as_ptr() != (0 : UInt64) {
        (d.dfn.vkDestroyShaderModule)(d.dev, frag_module, na)
      }
      if task_module.as_ptr() != (0 : UInt64) {
        (d.dfn.vkDestroyShaderModule)(d.dev, task_module, na)
      }
    }
    DeleteTimestampPool(pool) => (d.dfn.vkDestroyQueryPool)(d.dev, pool, na)
    DeleteBindlessHeap(pool, set_layout) => {
      (d.dfn.vkDestroyDescriptorPool)(d.dev, pool, na)
      (d.dfn.vkDestroyDescriptorSetLayout)(d.dev, set_layout, na)
    }
    DeleteAccelStruct(accel, buf, alloc) => {
      (d.dfn.vkDestroyAccelerationStructureKHR)(d.dev, accel, na)
      (d.dfn.vkDestroyBuffer)(d.dev, buf, na)
      d.alloc.free(alloc)
    }
  }
}

///|
fn flush_deletes(d : VkDeviceState, force : Bool) -> Unit {
  if d.pending_deletes.length() == 0 {
    return
  }
  let remaining : Array[DeferredDelete] = []
  for entry in d.pending_deletes {
    if force || entry.ready_after_gen <= d.completed_gen {
      execute_delete(d, entry.kind)
    } else {
      remaining.push(entry)
    }
  }
  d.pending_deletes.clear()
  for entry in remaining {
    d.pending_deletes.push(entry)
  }
}

///|
fn enqueue_delete(d : VkDeviceState, kind : DeleteKind) -> Unit {
  let safe_gen = if d.active_recordings > 0 {
    d.current_gen
  } else if d.current_gen > (1 : UInt64) {
    d.current_gen - (1 : UInt64)
  } else {
    (0 : UInt64)
  }
  if safe_gen <= d.completed_gen {
    execute_delete(d, kind)
  } else {
    d.pending_deletes.push({ ready_after_gen: safe_gen, kind })
  }
}

///|
fn vk_device_create(desc : DeviceDesc) -> VkDeviceState raise RhiError {
  let na = @vk.VkAllocationCallbacks::null()
  let app = @vk.VkApplicationInfo::new()
  app.set_pApplicationName(@vk.cstr(desc.app_name))
  app.set_apiVersion((4206592 : UInt32)) // VK_MAKE_API_VERSION(0, 1, 3, 0)
  let ext_arr : Array[String] = []
  let push_ext = fn(e : String) {
    if !ext_arr.contains(e) {
      ext_arr.push(e)
    }
  }
  if !desc.headless {
    let se = @win.surface_extensions()
    for i = 0; i < se.length(); i = i + 1 {
      push_ext(se[i])
    }
  }
  if has_instance_extension("VK_KHR_portability_enumeration") {
    push_ext("VK_KHR_portability_enumeration")
  }
  let use_debug = desc.validation &&
    has_instance_extension("VK_EXT_debug_utils")
  if use_debug {
    push_ext("VK_EXT_debug_utils")
  }
  let exts = FixedArray::makei(ext_arr.length(), fn(i) { ext_arr[i] })
  let ici = @vk.VkInstanceCreateInfo::new()
  ici.set_pApplicationInfo(app)
  ici.set_enabledExtensionCount(exts.length().reinterpret_as_uint())
  if exts.length() > 0 {
    ici.set_ppEnabledExtensionNames(@vk.cstr_array(exts))
  }
  if desc.validation && has_instance_layer("VK_LAYER_KHRONOS_validation") {
    ici.set_enabledLayerCount((1 : UInt32))
    ici.set_ppEnabledLayerNames(@vk.cstr_array(["VK_LAYER_KHRONOS_validation"]))
  }
  if ext_arr.contains("VK_KHR_portability_enumeration") {
    ici.set_flags(@vk.VK_INSTANCE_CREATE_ENUMERATE_PORTABILITY_BIT_KHR)
  }
  let inst_out = FixedArray::make(1, @vk.VkInstance::null())
  let ir = @vk.vkCreateInstance(ici, na, inst_out)
  ici.free()
  app.free()
  if ir != 0 {
    // Distinguish "loader too old" from generic failures: the most common
    // cause of this error is a loader older than 1.3 (e.g. Ubuntu 20.04),
    // and installing a newer Vulkan SDK does not upgrade the driver.
    let hint = if ir == @vk.VK_ERROR_INCOMPATIBLE_DRIVER.reinterpret_as_int() {
      " (VK_ERROR_INCOMPATIBLE_DRIVER: the Vulkan loader/driver is older than 1.3; Tycho needs a 1.3+ loader and driver at runtime — a newer Vulkan SDK does not upgrade the driver)"
    } else {
      ""
    }
    raise InitFailed("vkCreateInstance failed with code \{ir}\{hint}")
  }
  let inst = inst_out[0]
  let ifn = @vk.InstanceFn::load(inst)
  let error_baseline = g_rhi_validation_errors.val
  let messenger = if use_debug {
    @vk.create_debug_messenger(
      inst,
      ifn,
      @vk.VK_DEBUG_UTILS_MESSAGE_SEVERITY_WARNING_BIT_EXT |
      @vk.VK_DEBUG_UTILS_MESSAGE_SEVERITY_ERROR_BIT_EXT,
      @vk.VK_DEBUG_UTILS_MESSAGE_TYPE_GENERAL_BIT_EXT |
      @vk.VK_DEBUG_UTILS_MESSAGE_TYPE_VALIDATION_BIT_EXT |
      @vk.VK_DEBUG_UTILS_MESSAGE_TYPE_PERFORMANCE_BIT_EXT,
      (sev, _ty, data, _ud) => {
        let msg = @vk.read_cstr(data.get_pMessage())
        if (sev & @vk.VK_DEBUG_UTILS_MESSAGE_SEVERITY_ERROR_BIT_EXT) !=
          (0 : UInt32) {
          g_rhi_validation_errors.val = g_rhi_validation_errors.val + 1
          println("[rhi] VALIDATION ERROR: \{msg}")
        }
        (0 : UInt32)
      },
    )
  } else {
    @vk.VkDebugUtilsMessengerEXT::null()
  }

  let pc = FixedArray::make(1, (16 : UInt32))
  let pdevs = FixedArray::make(16, @vk.VkPhysicalDevice::null())
  let _ = (ifn.vkEnumeratePhysicalDevices)(inst, pc, pdevs)
  let pcount = pc[0].reinterpret_as_int()
  if pcount <= 0 {
    if use_debug {
      @vk.destroy_debug_messenger(inst, ifn, messenger)
    }
    (ifn.vkDestroyInstance)(inst, na)
    raise DeviceFailed("No Vulkan physical devices found")
  }
  // Pick a physical device with graphics + compute support (prefer discrete GPU)
  let mut chosen_phys = pdevs[0]
  let mut chosen_qf : UInt32 = (0 : UInt32)
  let mut found_device = false
  let mut is_discrete = false
  let mut timestamp_period_ns : Float = (1.0 : Float)
  let mut timestamp_valid_bits : UInt32 = (0 : UInt32)
  let mut device_name = ""
  let mut api_version : UInt32 = (0 : UInt32)
  let mut driver_version : UInt32 = (0 : UInt32)
  let mut max_dim_2d = 0
  let mut max_samples = 1
  let mut max_aniso : Float = (1.0 : Float)
  for pi = 0; pi < pcount; pi = pi + 1 {
    let pd = pdevs[pi]
    let pprops = @vk.VkPhysicalDeviceProperties::new()
    (ifn.vkGetPhysicalDeviceProperties)(pd, pprops)
    let discrete = pprops.get_deviceType() ==
      @vk.VK_PHYSICAL_DEVICE_TYPE_DISCRETE_GPU
    let limits = pprops.get_limits()
    let ts_period = limits.get_timestampPeriod()
    let dname = pprops.get_deviceName_string()
    let api_v = pprops.get_apiVersion()
    let drv_v = pprops.get_driverVersion()
    let dim_2d = limits.get_maxImageDimension2D().reinterpret_as_int()
    let msaa = max_samples_from_mask(limits.get_framebufferColorSampleCounts())
    let aniso = limits.get_maxSamplerAnisotropy()
    pprops.free()
    let qfc = FixedArray::make(1, (0 : UInt32))
    (ifn.vkGetPhysicalDeviceQueueFamilyProperties)(
      pd,
      qfc,
      @vk.VkQueueFamilyProperties::null(),
    )
    let qn = qfc[0].reinterpret_as_int()
    if qn <= 0 {
      continue
    }
    let qprops = @vk.VkQueueFamilyProperties::array(qn)
    (ifn.vkGetPhysicalDeviceQueueFamilyProperties)(pd, qfc, qprops)
    for qi = 0; qi < qn; qi = qi + 1 {
      let flags = qprops.get_queueFlags_at(qi)
      if (flags & (@vk.VK_QUEUE_GRAPHICS_BIT | @vk.VK_QUEUE_COMPUTE_BIT)) ==
        (@vk.VK_QUEUE_GRAPHICS_BIT | @vk.VK_QUEUE_COMPUTE_BIT) {
        if !found_device || (!is_discrete && discrete) {
          chosen_phys = pd
          chosen_qf = qi.reinterpret_as_uint()
          found_device = true
          is_discrete = discrete
          timestamp_period_ns = ts_period
          timestamp_valid_bits = qprops.get_timestampValidBits_at(qi)
          device_name = dname
          api_version = api_v
          driver_version = drv_v
          max_dim_2d = dim_2d
          max_samples = msaa
          max_aniso = aniso
        }
        break
      }
    }
    qprops.free()
  }
  if !found_device {
    if use_debug {
      @vk.destroy_debug_messenger(inst, ifn, messenger)
    }
    (ifn.vkDestroyInstance)(inst, na)
    raise DeviceFailed("No physical device with GRAPHICS|COMPUTE queue family")
  }

  let has_mesh_ext = has_device_extension(
    ifn, chosen_phys, "VK_EXT_mesh_shader",
  )
  let has_rq_ext = has_device_extension(
      ifn, chosen_phys, "VK_KHR_ray_query",
    ) &&
    has_device_extension(ifn, chosen_phys, "VK_KHR_acceleration_structure") &&
    has_device_extension(ifn, chosen_phys, "VK_KHR_deferred_host_operations")

  let f13q = @vk.VkPhysicalDeviceVulkan13Features::new()
  let f12q = @vk.VkPhysicalDeviceVulkan12Features::new()
  let as_q = @vk.VkPhysicalDeviceAccelerationStructureFeaturesKHR::new()
  let rq_q = @vk.VkPhysicalDeviceRayQueryFeaturesKHR::new()
  let mesh_q = @vk.VkPhysicalDeviceMeshShaderFeaturesEXT::new()
  let mut q_tail = f13q.as_ptr()
  if has_mesh_ext {
    mesh_q.set_pNext(q_tail)
    q_tail = mesh_q.as_ptr()
  }
  if has_rq_ext {
    rq_q.set_pNext(q_tail)
    as_q.set_pNext(rq_q.as_ptr())
    q_tail = as_q.as_ptr()
  }
  f12q.set_pNext(q_tail)
  let f2 = @vk.VkPhysicalDeviceFeatures2::new()
  f2.set_pNext(f12q.as_ptr())
  (ifn.vkGetPhysicalDeviceFeatures2)(chosen_phys, f2)
  let has_dyn = f13q.get_dynamicRendering()
  let has_sync2 = f13q.get_synchronization2()
  let has_maint4 = f13q.get_maintenance4() != (0 : UInt32)
  let core_feat = f2.get_features()
  let supports_anisotropy = core_feat.get_samplerAnisotropy() != (0 : UInt32)
  let has_draw_indirect_count = f12q.get_drawIndirectCount() != (0 : UInt32)
  let supports_indirect_draw = core_feat.get_multiDrawIndirect() != (0 : UInt32) &&
    has_draw_indirect_count
  let supports_bindless = f12q.get_descriptorBindingSampledImageUpdateAfterBind() !=
    (0 : UInt32) &&
    f12q.get_descriptorBindingPartiallyBound() != (0 : UInt32) &&
    f12q.get_runtimeDescriptorArray() != (0 : UInt32) &&
    f12q.get_shaderSampledImageArrayNonUniformIndexing() != (0 : UInt32)
  let supports_mesh_shader = has_mesh_ext &&
    mesh_q.get_meshShader() != (0 : UInt32) &&
    mesh_q.get_taskShader() != (0 : UInt32)
  let supports_ray_query = has_rq_ext &&
    f12q.get_bufferDeviceAddress() != (0 : UInt32) &&
    as_q.get_accelerationStructure() != (0 : UInt32) &&
    rq_q.get_rayQuery() != (0 : UInt32)
  f2.free()
  mesh_q.free()
  rq_q.free()
  as_q.free()
  f12q.free()
  f13q.free()
  if has_dyn == (0 : UInt32) || has_sync2 == (0 : UInt32) {
    if use_debug {
      @vk.destroy_debug_messenger(inst, ifn, messenger)
    }
    (ifn.vkDestroyInstance)(inst, na)
    raise DeviceFailed(
      "Physical device lacks Vulkan 1.3 dynamicRendering or synchronization2",
    )
  }

  let fmt_props = @vk.VkFormatProperties::new()
  (ifn.vkGetPhysicalDeviceFormatProperties)(
    chosen_phys,
    @vk.VK_FORMAT_D24_UNORM_S8_UINT,
    fmt_props,
  )
  let depth_stencil_vk_format = if (
      fmt_props.get_optimalTilingFeatures() &
      @vk.VK_FORMAT_FEATURE_DEPTH_STENCIL_ATTACHMENT_BIT
    ) != (0 : UInt32) {
    @vk.VK_FORMAT_D24_UNORM_S8_UINT
  } else {
    @vk.VK_FORMAT_D32_SFLOAT_S8_UINT
  }
  fmt_props.free()

  let caps : DeviceCapabilities = {
    device_name,
    is_discrete,
    api_version,
    driver_version,
    max_image_dimension_2d: max_dim_2d,
    max_framebuffer_samples: max_samples,
    max_sampler_anisotropy: max_aniso,
    supports_anisotropy,
    supports_indirect_draw,
    supports_bindless,
    supports_mesh_shader,
    supports_ray_query,
  }

  let priority = FixedArray::make(1, (1.0 : Float))
  let qci = @vk.VkDeviceQueueCreateInfo::new()
  qci.set_queueFamilyIndex(chosen_qf)
  qci.set_queueCount((1 : UInt32))
  qci.set_pQueuePriorities(priority)
  let f12 = @vk.VkPhysicalDeviceVulkan12Features::new()
  if supports_bindless {
    f12.set_descriptorBindingSampledImageUpdateAfterBind((1 : UInt32))
    f12.set_descriptorBindingPartiallyBound((1 : UInt32))
    f12.set_runtimeDescriptorArray((1 : UInt32))
    f12.set_shaderSampledImageArrayNonUniformIndexing((1 : UInt32))
  }
  if supports_ray_query {
    f12.set_bufferDeviceAddress((1 : UInt32))
  }
  if has_draw_indirect_count {
    f12.set_drawIndirectCount((1 : UInt32))
  }
  let as_feat = @vk.VkPhysicalDeviceAccelerationStructureFeaturesKHR::new()
  let rq_feat = @vk.VkPhysicalDeviceRayQueryFeaturesKHR::new()
  let mesh_feat = @vk.VkPhysicalDeviceMeshShaderFeaturesEXT::new()
  if supports_mesh_shader {
    mesh_feat.set_meshShader((1 : UInt32))
    mesh_feat.set_taskShader((1 : UInt32))
  }
  if supports_ray_query {
    as_feat.set_accelerationStructure((1 : UInt32))
    rq_feat.set_rayQuery((1 : UInt32))
  }
  let f13 = @vk.VkPhysicalDeviceVulkan13Features::new()
  f13.set_dynamicRendering((1 : UInt32))
  f13.set_synchronization2((1 : UInt32))
  if has_maint4 {
    f13.set_maintenance4((1 : UInt32))
  }
  let mut pnext_tail = (0 : UInt64)
  if supports_ray_query {
    rq_feat.set_pNext(pnext_tail)
    as_feat.set_pNext(rq_feat.as_ptr())
    pnext_tail = as_feat.as_ptr()
  }
  if supports_mesh_shader {
    mesh_feat.set_pNext(pnext_tail)
    pnext_tail = mesh_feat.as_ptr()
  }
  if supports_bindless || supports_ray_query || has_draw_indirect_count {
    f12.set_pNext(pnext_tail)
    pnext_tail = f12.as_ptr()
  }
  f13.set_pNext(pnext_tail)
  let enabled_feats = @vk.VkPhysicalDeviceFeatures::new()
  if supports_anisotropy {
    enabled_feats.set_samplerAnisotropy((1 : UInt32))
  }
  if core_feat.get_multiDrawIndirect() != (0 : UInt32) {
    enabled_feats.set_multiDrawIndirect((1 : UInt32))
  }
  let dev_exts : Array[String] = []
  if has_device_extension(ifn, chosen_phys, "VK_KHR_portability_subset") {
    dev_exts.push("VK_KHR_portability_subset")
  }
  if !desc.headless {
    dev_exts.push("VK_KHR_swapchain")
  }
  if supports_mesh_shader {
    dev_exts.push("VK_EXT_mesh_shader")
  }
  if supports_ray_query {
    dev_exts.push("VK_KHR_acceleration_structure")
    dev_exts.push("VK_KHR_ray_query")
    dev_exts.push("VK_KHR_deferred_host_operations")
  }
  let dci = @vk.VkDeviceCreateInfo::new()
  dci.set_pNext(f13.as_ptr())
  dci.set_queueCreateInfoCount((1 : UInt32))
  dci.set_pQueueCreateInfos(qci)
  dci.set_pEnabledFeatures(enabled_feats)
  if dev_exts.length() > 0 {
    let ext_arr = FixedArray::makei(dev_exts.length(), fn(i) { dev_exts[i] })
    dci.set_enabledExtensionCount(ext_arr.length().reinterpret_as_uint())
    dci.set_ppEnabledExtensionNames(@vk.cstr_array(ext_arr))
  }
  let dev_out = FixedArray::make(1, @vk.VkDevice::null())
  let dr = (ifn.vkCreateDevice)(chosen_phys, dci, na, dev_out)
  dci.free()
  enabled_feats.free()
  f13.free()
  mesh_feat.free()
  rq_feat.free()
  as_feat.free()
  f12.free()
  qci.free()
  if dr != 0 {
    if use_debug {
      @vk.destroy_debug_messenger(inst, ifn, messenger)
    }
    (ifn.vkDestroyInstance)(inst, na)
    raise DeviceFailed("vkCreateDevice failed with code \{dr}")
  }
  let dev = dev_out[0]
  let dfn = @vk.DeviceFn::load(dev)
  let queue_out = FixedArray::make(1, @vk.VkQueue::null())
  (dfn.vkGetDeviceQueue)(dev, chosen_qf, (0 : UInt32), queue_out)
  let queue = queue_out[0]

  let cpci = @vk.VkCommandPoolCreateInfo::new()
  cpci.set_queueFamilyIndex(chosen_qf)
  cpci.set_flags(@vk.VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT)
  let pool_out = FixedArray::make(1, @vk.VkCommandPool::null())
  let cpr = (dfn.vkCreateCommandPool)(dev, cpci, na, pool_out)
  cpci.free()
  if cpr != 0 {
    (dfn.vkDestroyDevice)(dev, na)
    if use_debug {
      @vk.destroy_debug_messenger(inst, ifn, messenger)
    }
    (ifn.vkDestroyInstance)(inst, na)
    raise DeviceFailed("vkCreateCommandPool failed with code \{cpr}")
  }
  let pcci = @vk.VkPipelineCacheCreateInfo::new()
  if desc.pipeline_cache.length() > 0 {
    pcci.set_initialDataSize(desc.pipeline_cache.length().to_uint64())
    pcci.set_pInitialData(@vk.bytes_ptr(desc.pipeline_cache))
  }
  let pc_out = FixedArray::make(1, @vk.VkPipelineCache::null())
  let pcr = (dfn.vkCreatePipelineCache)(dev, pcci, na, pc_out)
  pcci.free()
  let pipeline_cache = if pcr == 0 {
    pc_out[0]
  } else {
    @vk.VkPipelineCache::null()
  }

  let alloc = SubAllocator::new(
    dev,
    dfn,
    ifn,
    chosen_phys,
    enable_device_address=supports_ray_query,
  )
  {
    inst,
    ifn,
    phys: chosen_phys,
    dev,
    dfn,
    queue,
    queue_family: chosen_qf,
    pool: pool_out[0],
    pipeline_cache,
    alloc,
    messenger,
    error_baseline,
    timestamp_period_ns,
    supports_timestamps: timestamp_valid_bits > (0 : UInt32) &&
    timestamp_period_ns > (0.0 : Float),
    headless: desc.headless,
    caps,
    current_gen: (1 : UInt64),
    completed_gen: (0 : UInt64),
    active_recordings: 0,
    pending_deletes: [],
    depth_stencil_vk_format,
  }
}

///|
fn vk_device_destroy(d : VkDeviceState) -> Unit {
  let na = @vk.VkAllocationCallbacks::null()
  let _ = (d.dfn.vkDeviceWaitIdle)(d.dev)
  flush_deletes(d, true)
  d.alloc.destroy()
  if d.pipeline_cache.as_ptr() != (0 : UInt64) {
    (d.dfn.vkDestroyPipelineCache)(d.dev, d.pipeline_cache, na)
  }
  (d.dfn.vkDestroyCommandPool)(d.dev, d.pool, na)
  (d.dfn.vkDestroyDevice)(d.dev, na)
  if d.messenger.as_ptr() != (0 : UInt64) {
    @vk.destroy_debug_messenger(d.inst, d.ifn, d.messenger)
  }
  (d.ifn.vkDestroyInstance)(d.inst, na)
}

///|
fn begin_one_time(d : VkDeviceState) -> @vk.VkCommandBuffer raise RhiError {
  let cbai = @vk.VkCommandBufferAllocateInfo::new()
  cbai.set_commandPool(d.pool)
  cbai.set_level(@vk.VK_COMMAND_BUFFER_LEVEL_PRIMARY)
  cbai.set_commandBufferCount((1 : UInt32))
  let out = FixedArray::make(1, @vk.VkCommandBuffer::null())
  let ar = (d.dfn.vkAllocateCommandBuffers)(d.dev, cbai, out)
  cbai.free()
  if ar != 0 {
    raise CommandFailed("vkAllocateCommandBuffers failed with code \{ar}")
  }
  let cbi = @vk.VkCommandBufferBeginInfo::new()
  cbi.set_flags(@vk.VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT)
  let br = (d.dfn.vkBeginCommandBuffer)(out[0], cbi)
  cbi.free()
  if br != 0 {
    raise CommandFailed("vkBeginCommandBuffer failed with code \{br}")
  }
  out[0]
}

///|
fn end_one_time(
  d : VkDeviceState,
  cmd : @vk.VkCommandBuffer,
) -> Unit raise RhiError {
  let er = (d.dfn.vkEndCommandBuffer)(cmd)
  if er != 0 {
    raise CommandFailed("vkEndCommandBuffer failed with code \{er}")
  }
  let cmd_si = @vk.VkCommandBufferSubmitInfo::new()
  cmd_si.set_commandBuffer(cmd)
  let si2 = @vk.VkSubmitInfo2::new()
  si2.set_commandBufferInfoCount((1 : UInt32))
  si2.set_pCommandBufferInfos(cmd_si)
  let sr = (d.dfn.vkQueueSubmit2)(
    d.queue,
    (1 : UInt32),
    si2,
    @vk.VkFence::null(),
  )
  si2.free()
  cmd_si.free()
  if sr != 0 {
    raise CommandFailed("vkQueueSubmit2 failed with code \{sr}")
  }
  let _ = (d.dfn.vkQueueWaitIdle)(d.queue)
  (d.dfn.vkFreeCommandBuffers)(
    d.dev,
    d.pool,
    (1 : UInt32),
    FixedArray::make(1, cmd),
  )
}

///|
fn cmd_image_barrier2_mips(
  d : VkDeviceState,
  cmd : @vk.VkCommandBuffer,
  image : @vk.VkImage,
  aspect : UInt32,
  base_mip : Int,
  mip_count : Int,
  src_stage : UInt64,
  src_access : UInt64,
  dst_stage : UInt64,
  dst_access : UInt64,
  old_layout : UInt32,
  new_layout : UInt32,
  layer_count? : Int = 1,
) -> Unit {
  let range = @vk.VkImageSubresourceRange::new()
  range.set_aspectMask(aspect)
  range.set_baseMipLevel(base_mip.reinterpret_as_uint())
  range.set_levelCount(mip_count.reinterpret_as_uint())
  range.set_layerCount(layer_count.reinterpret_as_uint())
  let b2 = @vk.VkImageMemoryBarrier2::new()
  b2.set_srcStageMask(src_stage)
  b2.set_srcAccessMask(src_access)
  b2.set_dstStageMask(dst_stage)
  b2.set_dstAccessMask(dst_access)
  b2.set_oldLayout(old_layout)
  b2.set_newLayout(new_layout)
  b2.set_srcQueueFamilyIndex((0xFFFFFFFF : UInt32))
  b2.set_dstQueueFamilyIndex((0xFFFFFFFF : UInt32))
  b2.set_image(image)
  b2.set_subresourceRange(range)
  let dep = @vk.VkDependencyInfo::new()
  dep.set_imageMemoryBarrierCount((1 : UInt32))
  dep.set_pImageMemoryBarriers(b2)
  (d.dfn.vkCmdPipelineBarrier2)(cmd, dep)
  dep.free()
  b2.free()
  range.free()
}

///|
fn cmd_image_barrier2(
  d : VkDeviceState,
  cmd : @vk.VkCommandBuffer,
  image : @vk.VkImage,
  aspect : UInt32,
  src_stage : UInt64,
  src_access : UInt64,
  dst_stage : UInt64,
  dst_access : UInt64,
  old_layout : UInt32,
  new_layout : UInt32,
) -> Unit {
  cmd_image_barrier2_mips(
    d, cmd, image, aspect, 0, 1, src_stage, src_access, dst_stage, dst_access, old_layout,
    new_layout,
  )
}

///|
fn vk_buffer_create(
  d : VkDeviceState,
  size : Int,
  kind : BufferKind,
  location? : MemoryLocation = MemoryLocation::CpuToGpu,
) -> VkBufferState raise RhiError {
  if size <= 0 {
    raise InvalidArgument("Buffer size must be positive (got \{size})")
  }
  let na = @vk.VkAllocationCallbacks::null()
  let mut usage = match kind {
    BufferKind::Vertex =>
      @vk.VK_BUFFER_USAGE_VERTEX_BUFFER_BIT | @vk.VK_BUFFER_USAGE_TRANSFER_DST_BIT
    BufferKind::Index =>
      @vk.VK_BUFFER_USAGE_INDEX_BUFFER_BIT | @vk.VK_BUFFER_USAGE_TRANSFER_DST_BIT
    BufferKind::Uniform => @vk.VK_BUFFER_USAGE_UNIFORM_BUFFER_BIT
    BufferKind::Staging =>
      @vk.VK_BUFFER_USAGE_TRANSFER_SRC_BIT | @vk.VK_BUFFER_USAGE_TRANSFER_DST_BIT
    BufferKind::Storage =>
      @vk.VK_BUFFER_USAGE_STORAGE_BUFFER_BIT |
      @vk.VK_BUFFER_USAGE_TRANSFER_SRC_BIT |
      @vk.VK_BUFFER_USAGE_TRANSFER_DST_BIT
    BufferKind::Indirect =>
      @vk.VK_BUFFER_USAGE_INDIRECT_BUFFER_BIT |
      @vk.VK_BUFFER_USAGE_STORAGE_BUFFER_BIT |
      @vk.VK_BUFFER_USAGE_TRANSFER_SRC_BIT |
      @vk.VK_BUFFER_USAGE_TRANSFER_DST_BIT
  }
  if location == MemoryLocation::GpuOnly {
    usage = usage |
      @vk.VK_BUFFER_USAGE_TRANSFER_DST_BIT |
      @vk.VK_BUFFER_USAGE_TRANSFER_SRC_BIT
  }
  if d.caps.supports_ray_query {
    usage = usage | @vk.VK_BUFFER_USAGE_SHADER_DEVICE_ADDRESS_BIT
    match kind {
      BufferKind::Vertex | BufferKind::Index | BufferKind::Storage =>
        usage = usage |
          @vk.VK_BUFFER_USAGE_ACCELERATION_STRUCTURE_BUILD_INPUT_READ_ONLY_BIT_KHR
      _ => ()
    }
  }
  let bci = @vk.VkBufferCreateInfo::new()
  bci.set_size(size.to_uint64())
  bci.set_usage(usage)
  bci.set_sharingMode(@vk.VK_SHARING_MODE_EXCLUSIVE)
  let buf_out = FixedArray::make(1, @vk.VkBuffer::null())
  let br = (d.dfn.vkCreateBuffer)(d.dev, bci, na, buf_out)
  bci.free()
  if br != 0 {
    raise AllocationFailed("vkCreateBuffer failed with code \{br}")
  }
  let buffer = buf_out[0]
  let req = @vk.VkMemoryRequirements::new()
  (d.dfn.vkGetBufferMemoryRequirements)(d.dev, buffer, req)
  let (flags, host_visible) = match location {
    MemoryLocation::GpuOnly =>
      (@vk.VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT, false)
    MemoryLocation::CpuToGpu | MemoryLocation::GpuToCpu =>
      (
        @vk.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT |
        @vk.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT,
        true,
      )
  }
  let alloc = d.alloc.alloc(req, flags, host_visible, false)
  req.free()
  let bir = (d.dfn.vkBindBufferMemory)(
    d.dev,
    buffer,
    alloc.memory,
    alloc.offset,
  )
  if bir != 0 {
    d.alloc.free(alloc)
    (d.dfn.vkDestroyBuffer)(d.dev, buffer, na)
    raise AllocationFailed("vkBindBufferMemory failed with code \{bir}")
  }
  { device: d, buffer, alloc, size }
}

///|
fn vk_buffer_upload_ptr(
  b : VkBufferState,
  src_ptr : UInt64,
  byte_len : Int,
  offset? : Int = 0,
) -> Unit raise RhiError {
  if offset < 0 || byte_len < 0 || offset + byte_len > b.size {
    raise InvalidArgument(
      "Upload range [\{offset}, \{offset + byte_len}) exceeds buffer capacity \{b.size}",
    )
  }
  if byte_len == 0 {
    return
  }
  if b.alloc.mapped != (0 : UInt64) {
    @vk.memcpy_ptr(b.alloc.mapped + offset.to_uint64(), src_ptr, byte_len)
  } else {
    let d = b.device
    let staging = vk_buffer_create(
      d,
      byte_len,
      BufferKind::Staging,
      location=MemoryLocation::CpuToGpu,
    )
    @vk.memcpy_ptr(staging.alloc.mapped, src_ptr, byte_len)
    let cmd = begin_one_time(d)
    let region = @vk.VkBufferCopy::new()
    region.set_srcOffset((0 : UInt64))
    region.set_dstOffset(offset.to_uint64())
    region.set_size(byte_len.to_uint64())
    (d.dfn.vkCmdCopyBuffer)(cmd, staging.buffer, b.buffer, (1 : UInt32), region)
    region.free()
    end_one_time(d, cmd)
    // end_one_time waited on the queue, so staging can be freed immediately.
    execute_delete(d, DeleteBuffer(staging.buffer, staging.alloc))
  }
}

///|
fn vk_buffer_download(b : VkBufferState) -> Bytes raise RhiError {
  let out = FixedArray::make(b.size, (0 : Byte))
  if b.size == 0 {
    return Bytes::from_array(out[:])
  }
  if b.alloc.mapped != (0 : UInt64) {
    @vk.memcpy_ptr(@vk.byte_ptr(out), b.alloc.mapped, b.size)
  } else {
    let d = b.device
    let staging = vk_buffer_create(
      d,
      b.size,
      BufferKind::Staging,
      location=MemoryLocation::GpuToCpu,
    )
    let cmd = begin_one_time(d)
    let region = @vk.VkBufferCopy::new()
    region.set_srcOffset((0 : UInt64))
    region.set_dstOffset((0 : UInt64))
    region.set_size(b.size.to_uint64())
    (d.dfn.vkCmdCopyBuffer)(cmd, b.buffer, staging.buffer, (1 : UInt32), region)
    region.free()
    end_one_time(d, cmd)
    @vk.memcpy_ptr(@vk.byte_ptr(out), staging.alloc.mapped, b.size)
    execute_delete(d, DeleteBuffer(staging.buffer, staging.alloc))
  }
  Bytes::from_array(out[:])
}

///|
fn vk_buffer_destroy(b : VkBufferState) -> Unit {
  enqueue_delete(b.device, DeleteBuffer(b.buffer, b.alloc))
}

///|
fn mip_count_for(width : Int, height : Int) -> Int {
  let mut levels = 1
  let mut dim = if width > height { width } else { height }
  while dim > 1 {
    dim = dim / 2
    levels = levels + 1
  }
  levels
}

///|
fn blit_offsets_bytes(w : Int, h : Int) -> Bytes {
  let arr : Array[Byte] = Array::make(24, (0 : Byte))
  // src/dst offset[0] = (0, 0, 0), offset[1] = (w, h, 1) as little-endian Int32
  arr[12] = (w & 0xFF).to_byte()
  arr[13] = ((w >> 8) & 0xFF).to_byte()
  arr[14] = ((w >> 16) & 0xFF).to_byte()
  arr[15] = ((w >> 24) & 0xFF).to_byte()
  arr[16] = (h & 0xFF).to_byte()
  arr[17] = ((h >> 8) & 0xFF).to_byte()
  arr[18] = ((h >> 16) & 0xFF).to_byte()
  arr[19] = ((h >> 24) & 0xFF).to_byte()
  arr[20] = (1 : Byte)
  Bytes::from_array(arr)
}

///|
fn create_image_and_view(
  d : VkDeviceState,
  width : Int,
  height : Int,
  vk_format : UInt32,
  usage : UInt32,
  aspect : UInt32,
  samples : SampleCount,
  format : TextureFormat,
  mip_levels? : Int = 1,
  layers? : Int = 1,
  flags? : UInt32 = (0 : UInt32),
  view_type? : UInt32 = @vk.VK_IMAGE_VIEW_TYPE_2D,
) -> VkTextureState raise RhiError {
  if width <= 0 || height <= 0 || layers <= 0 {
    raise InvalidArgument("Texture dimensions and layers must be positive")
  }
  let levels = if mip_levels < 1 { 1 } else { mip_levels }
  let na = @vk.VkAllocationCallbacks::null()
  let extent = @vk.VkExtent3D::new()
  extent.set_width(width.reinterpret_as_uint())
  extent.set_height(height.reinterpret_as_uint())
  extent.set_depth((1 : UInt32))
  let ici = @vk.VkImageCreateInfo::new()
  ici.set_flags(flags)
  ici.set_imageType(@vk.VK_IMAGE_TYPE_2D)
  ici.set_format(vk_format)
  ici.set_extent(extent)
  ici.set_mipLevels(levels.reinterpret_as_uint())
  ici.set_arrayLayers(layers.reinterpret_as_uint())
  ici.set_samples(vk_samples(samples))
  ici.set_tiling(@vk.VK_IMAGE_TILING_OPTIMAL)
  ici.set_usage(usage)
  ici.set_sharingMode(@vk.VK_SHARING_MODE_EXCLUSIVE)
  ici.set_initialLayout(@vk.VK_IMAGE_LAYOUT_UNDEFINED)
  let img_out = FixedArray::make(1, @vk.VkImage::null())
  let ir = (d.dfn.vkCreateImage)(d.dev, ici, na, img_out)
  extent.free()
  ici.free()
  if ir != 0 {
    raise AllocationFailed("vkCreateImage failed with code \{ir}")
  }
  let image = img_out[0]
  let req = @vk.VkMemoryRequirements::new()
  (d.dfn.vkGetImageMemoryRequirements)(d.dev, image, req)
  let alloc = d.alloc.alloc(
    req,
    @vk.VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT,
    false,
    true,
  )
  req.free()
  let br = (d.dfn.vkBindImageMemory)(d.dev, image, alloc.memory, alloc.offset)
  if br != 0 {
    d.alloc.free(alloc)
    (d.dfn.vkDestroyImage)(d.dev, image, na)
    raise AllocationFailed("vkBindImageMemory failed with code \{br}")
  }
  let view_aspect = if is_depth_format(format) {
    @vk.VK_IMAGE_ASPECT_DEPTH_BIT
  } else {
    aspect
  }
  let range = @vk.VkImageSubresourceRange::new()
  range.set_aspectMask(view_aspect)
  range.set_baseMipLevel((0 : UInt32))
  range.set_levelCount(levels.reinterpret_as_uint())
  range.set_layerCount(layers.reinterpret_as_uint())
  let ivci = @vk.VkImageViewCreateInfo::new()
  ivci.set_image(image)
  ivci.set_viewType(view_type)
  ivci.set_format(vk_format)
  ivci.set_subresourceRange(range)
  let view_out = FixedArray::make(1, @vk.VkImageView::null())
  let vr = (d.dfn.vkCreateImageView)(d.dev, ivci, na, view_out)
  if vr != 0 {
    range.free()
    ivci.free()
    (d.dfn.vkDestroyImage)(d.dev, image, na)
    d.alloc.free(alloc)
    raise AllocationFailed("vkCreateImageView failed with code \{vr}")
  }
  let mut attachment_view = view_out[0]
  if format == TextureFormat::Depth24Stencil8 {
    range.set_aspectMask(
      @vk.VK_IMAGE_ASPECT_DEPTH_BIT | @vk.VK_IMAGE_ASPECT_STENCIL_BIT,
    )
    ivci.set_subresourceRange(range)
    let av_out = FixedArray::make(1, @vk.VkImageView::null())
    let avr = (d.dfn.vkCreateImageView)(d.dev, ivci, na, av_out)
    if avr == 0 {
      attachment_view = av_out[0]
    }
  }
  range.free()
  ivci.free()
  {
    device: d,
    image,
    alloc,
    view: view_out[0],
    attachment_view,
    format,
    samples,
    width,
    height,
    mip_levels: levels,
    layers,
    aspect,
    layout: @vk.VK_IMAGE_LAYOUT_UNDEFINED,
  }
}

///|
fn vk_texture_create_uploaded(
  d : VkDeviceState,
  width : Int,
  height : Int,
  format : TextureFormat,
  pixels : Bytes,
) -> VkTextureState raise RhiError {
  vk_texture_create_layered(
    d,
    width,
    height,
    1,
    format,
    pixels,
    (0 : UInt32),
    @vk.VK_IMAGE_VIEW_TYPE_2D,
  )
}

///|
fn vk_texture_create_layered(
  d : VkDeviceState,
  width : Int,
  height : Int,
  layers : Int,
  format : TextureFormat,
  pixels : Bytes,
  flags : UInt32,
  view_type : UInt32,
) -> VkTextureState raise RhiError {
  if is_depth_format(format) {
    raise InvalidArgument("Use create_depth_texture for depth textures")
  }
  let layer_bytes = width * height * texture_format_bytes(format)
  let expected_bytes = layer_bytes * layers
  if pixels.length() < expected_bytes {
    raise InvalidArgument(
      "Texture upload bytes (\{pixels.length()}) smaller than \{expected_bytes}",
    )
  }
  let staging = vk_buffer_create(d, expected_bytes, BufferKind::Staging)
  vk_buffer_upload_ptr(staging, @vk.bytes_ptr(pixels), expected_bytes)
  let tex = create_image_and_view(
    d,
    width,
    height,
    vk_texture_format_for(d, format),
    @vk.VK_IMAGE_USAGE_TRANSFER_DST_BIT |
    @vk.VK_IMAGE_USAGE_TRANSFER_SRC_BIT |
    @vk.VK_IMAGE_USAGE_SAMPLED_BIT,
    @vk.VK_IMAGE_ASPECT_COLOR_BIT,
    SampleCount::X1,
    format,
    layers~,
    flags~,
    view_type~,
  )
  let cmd = begin_one_time(d)
  cmd_image_barrier2_mips(
    d,
    cmd,
    tex.image,
    @vk.VK_IMAGE_ASPECT_COLOR_BIT,
    0,
    1,
    @vk.VK_PIPELINE_STAGE_2_NONE,
    @vk.VK_ACCESS_2_NONE,
    @vk.VK_PIPELINE_STAGE_2_ALL_TRANSFER_BIT,
    @vk.VK_ACCESS_2_TRANSFER_WRITE_BIT,
    @vk.VK_IMAGE_LAYOUT_UNDEFINED,
    @vk.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
    layer_count=layers,
  )
  let extent = @vk.VkExtent3D::new()
  extent.set_width(width.reinterpret_as_uint())
  extent.set_height(height.reinterpret_as_uint())
  extent.set_depth((1 : UInt32))
  let region = @vk.VkBufferImageCopy::new()
  let sub = @vk.VkImageSubresourceLayers::new()
  sub.set_aspectMask(@vk.VK_IMAGE_ASPECT_COLOR_BIT)
  sub.set_layerCount(layers.reinterpret_as_uint())
  region.set_imageSubresource(sub)
  region.set_imageExtent(extent)
  (d.dfn.vkCmdCopyBufferToImage)(
    cmd,
    staging.buffer,
    tex.image,
    @vk.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
    (1 : UInt32),
    region,
  )
  cmd_image_barrier2_mips(
    d,
    cmd,
    tex.image,
    @vk.VK_IMAGE_ASPECT_COLOR_BIT,
    0,
    1,
    @vk.VK_PIPELINE_STAGE_2_ALL_TRANSFER_BIT,
    @vk.VK_ACCESS_2_TRANSFER_WRITE_BIT,
    @vk.VK_PIPELINE_STAGE_2_FRAGMENT_SHADER_BIT |
    @vk.VK_PIPELINE_STAGE_2_COMPUTE_SHADER_BIT,
    @vk.VK_ACCESS_2_SHADER_READ_BIT,
    @vk.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
    @vk.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
    layer_count=layers,
  )
  end_one_time(d, cmd)
  extent.free()
  region.free()
  sub.free()
  vk_buffer_destroy(staging)
  tex.layout = @vk.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL
  tex
}

///|
fn vk_texture_upload_subregion(
  t : VkTextureState,
  x : Int,
  y : Int,
  width : Int,
  height : Int,
  pixels : Bytes,
  layer : Int,
  mip_level : Int,
) -> Unit raise RhiError {
  if is_depth_format(t.format) {
    raise InvalidArgument("Cannot upload pixels to a depth texture")
  }
  if x < 0 || y < 0 || width <= 0 || height <= 0 {
    raise InvalidArgument("Subregion offset/size invalid")
  }
  if layer < 0 || layer >= t.layers || mip_level < 0 || mip_level >= t.mip_levels {
    raise InvalidArgument("Subregion layer or mip_level out of range")
  }
  let expected_bytes = width * height * texture_format_bytes(t.format)
  if pixels.length() < expected_bytes {
    raise InvalidArgument(
      "Subregion bytes (\{pixels.length()}) smaller than \{expected_bytes}",
    )
  }
  let d = t.device
  let staging = vk_buffer_create(d, expected_bytes, BufferKind::Staging)
  vk_buffer_upload_ptr(staging, @vk.bytes_ptr(pixels), expected_bytes)
  let cmd = begin_one_time(d)
  let prev_layout = t.layout
  cmd_image_barrier2_mips(
    d,
    cmd,
    t.image,
    t.aspect,
    mip_level,
    1,
    @vk.VK_PIPELINE_STAGE_2_ALL_COMMANDS_BIT,
    @vk.VK_ACCESS_2_SHADER_READ_BIT,
    @vk.VK_PIPELINE_STAGE_2_ALL_TRANSFER_BIT,
    @vk.VK_ACCESS_2_TRANSFER_WRITE_BIT,
    prev_layout,
    @vk.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
    layer_count=t.layers,
  )
  let offset = @vk.VkOffset3D::new()
  offset.set_x(x)
  offset.set_y(y)
  offset.set_z(0)
  let extent = @vk.VkExtent3D::new()
  extent.set_width(width.reinterpret_as_uint())
  extent.set_height(height.reinterpret_as_uint())
  extent.set_depth((1 : UInt32))
  let sub = @vk.VkImageSubresourceLayers::new()
  sub.set_aspectMask(@vk.VK_IMAGE_ASPECT_COLOR_BIT)
  sub.set_mipLevel(mip_level.reinterpret_as_uint())
  sub.set_baseArrayLayer(layer.reinterpret_as_uint())
  sub.set_layerCount((1 : UInt32))
  let region = @vk.VkBufferImageCopy::new()
  region.set_imageSubresource(sub)
  region.set_imageOffset(offset)
  region.set_imageExtent(extent)
  (d.dfn.vkCmdCopyBufferToImage)(
    cmd,
    staging.buffer,
    t.image,
    @vk.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
    (1 : UInt32),
    region,
  )
  let restore_layout = if prev_layout == @vk.VK_IMAGE_LAYOUT_UNDEFINED {
    @vk.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL
  } else {
    prev_layout
  }
  cmd_image_barrier2_mips(
    d,
    cmd,
    t.image,
    t.aspect,
    mip_level,
    1,
    @vk.VK_PIPELINE_STAGE_2_ALL_TRANSFER_BIT,
    @vk.VK_ACCESS_2_TRANSFER_WRITE_BIT,
    @vk.VK_PIPELINE_STAGE_2_FRAGMENT_SHADER_BIT |
    @vk.VK_PIPELINE_STAGE_2_COMPUTE_SHADER_BIT,
    @vk.VK_ACCESS_2_SHADER_READ_BIT,
    @vk.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
    restore_layout,
    layer_count=t.layers,
  )
  end_one_time(d, cmd)
  offset.free()
  extent.free()
  sub.free()
  region.free()
  execute_delete(d, DeleteBuffer(staging.buffer, staging.alloc))
  t.layout = restore_layout
}

///|
fn vk_texture_create_mipmapped(
  d : VkDeviceState,
  width : Int,
  height : Int,
  format : TextureFormat,
  pixels : Bytes,
) -> VkTextureState raise RhiError {
  if format == TextureFormat::Depth32F {
    raise InvalidArgument("Depth32F textures cannot generate mipmaps")
  }
  let expected_bytes = width * height * texture_format_bytes(format)
  if pixels.length() < expected_bytes {
    raise InvalidArgument(
      "Texture upload bytes (\{pixels.length()}) smaller than \{expected_bytes}",
    )
  }
  let levels = mip_count_for(width, height)
  let staging = vk_buffer_create(d, expected_bytes, BufferKind::Staging)
  vk_buffer_upload_ptr(staging, @vk.bytes_ptr(pixels), expected_bytes)
  let tex = create_image_and_view(
    d,
    width,
    height,
    vk_texture_format_for(d, format),
    @vk.VK_IMAGE_USAGE_TRANSFER_DST_BIT |
    @vk.VK_IMAGE_USAGE_TRANSFER_SRC_BIT |
    @vk.VK_IMAGE_USAGE_SAMPLED_BIT,
    @vk.VK_IMAGE_ASPECT_COLOR_BIT,
    SampleCount::X1,
    format,
    mip_levels=levels,
  )
  let cmd = begin_one_time(d)
  cmd_image_barrier2_mips(
    d,
    cmd,
    tex.image,
    @vk.VK_IMAGE_ASPECT_COLOR_BIT,
    0,
    levels,
    @vk.VK_PIPELINE_STAGE_2_NONE,
    @vk.VK_ACCESS_2_NONE,
    @vk.VK_PIPELINE_STAGE_2_ALL_TRANSFER_BIT,
    @vk.VK_ACCESS_2_TRANSFER_WRITE_BIT,
    @vk.VK_IMAGE_LAYOUT_UNDEFINED,
    @vk.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
  )
  let extent = @vk.VkExtent3D::new()
  extent.set_width(width.reinterpret_as_uint())
  extent.set_height(height.reinterpret_as_uint())
  extent.set_depth((1 : UInt32))
  let region = @vk.VkBufferImageCopy::new()
  let sub = @vk.VkImageSubresourceLayers::new()
  sub.set_aspectMask(@vk.VK_IMAGE_ASPECT_COLOR_BIT)
  sub.set_mipLevel((0 : UInt32))
  sub.set_layerCount((1 : UInt32))
  region.set_imageSubresource(sub)
  region.set_imageExtent(extent)
  (d.dfn.vkCmdCopyBufferToImage)(
    cmd,
    staging.buffer,
    tex.image,
    @vk.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
    (1 : UInt32),
    region,
  )
  extent.free()
  region.free()
  sub.free()

  let mut mip_w = width
  let mut mip_h = height
  let src_sub = @vk.VkImageSubresourceLayers::new()
  let dst_sub = @vk.VkImageSubresourceLayers::new()
  src_sub.set_aspectMask(@vk.VK_IMAGE_ASPECT_COLOR_BIT)
  src_sub.set_layerCount((1 : UInt32))
  dst_sub.set_aspectMask(@vk.VK_IMAGE_ASPECT_COLOR_BIT)
  dst_sub.set_layerCount((1 : UInt32))
  let blit = @vk.VkImageBlit::new()
  for i = 1; i < levels; i = i + 1 {
    cmd_image_barrier2_mips(
      d,
      cmd,
      tex.image,
      @vk.VK_IMAGE_ASPECT_COLOR_BIT,
      i - 1,
      1,
      @vk.VK_PIPELINE_STAGE_2_ALL_TRANSFER_BIT,
      @vk.VK_ACCESS_2_TRANSFER_WRITE_BIT,
      @vk.VK_PIPELINE_STAGE_2_ALL_TRANSFER_BIT,
      @vk.VK_ACCESS_2_TRANSFER_READ_BIT,
      @vk.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
      @vk.VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,
    )
    let next_w = if mip_w > 1 { mip_w / 2 } else { 1 }
    let next_h = if mip_h > 1 { mip_h / 2 } else { 1 }
    src_sub.set_mipLevel((i - 1).reinterpret_as_uint())
    dst_sub.set_mipLevel(i.reinterpret_as_uint())
    blit.set_srcSubresource(src_sub)
    blit.set_dstSubresource(dst_sub)
    blit.set_srcOffsets(blit_offsets_bytes(mip_w, mip_h))
    blit.set_dstOffsets(blit_offsets_bytes(next_w, next_h))
    (d.dfn.vkCmdBlitImage)(
      cmd,
      tex.image,
      @vk.VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,
      tex.image,
      @vk.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
      (1 : UInt32),
      blit,
      @vk.VK_FILTER_LINEAR,
    )
    cmd_image_barrier2_mips(
      d,
      cmd,
      tex.image,
      @vk.VK_IMAGE_ASPECT_COLOR_BIT,
      i - 1,
      1,
      @vk.VK_PIPELINE_STAGE_2_ALL_TRANSFER_BIT,
      @vk.VK_ACCESS_2_TRANSFER_READ_BIT,
      @vk.VK_PIPELINE_STAGE_2_FRAGMENT_SHADER_BIT |
      @vk.VK_PIPELINE_STAGE_2_COMPUTE_SHADER_BIT,
      @vk.VK_ACCESS_2_SHADER_READ_BIT,
      @vk.VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,
      @vk.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
    )
    mip_w = next_w
    mip_h = next_h
  }
  cmd_image_barrier2_mips(
    d,
    cmd,
    tex.image,
    @vk.VK_IMAGE_ASPECT_COLOR_BIT,
    levels - 1,
    1,
    @vk.VK_PIPELINE_STAGE_2_ALL_TRANSFER_BIT,
    @vk.VK_ACCESS_2_TRANSFER_WRITE_BIT,
    @vk.VK_PIPELINE_STAGE_2_FRAGMENT_SHADER_BIT |
    @vk.VK_PIPELINE_STAGE_2_COMPUTE_SHADER_BIT,
    @vk.VK_ACCESS_2_SHADER_READ_BIT,
    @vk.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
    @vk.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
  )
  end_one_time(d, cmd)
  src_sub.free()
  dst_sub.free()
  blit.free()
  vk_buffer_destroy(staging)
  tex.layout = @vk.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL
  tex
}

///|
fn vk_texture_create_storage(
  d : VkDeviceState,
  width : Int,
  height : Int,
  format : TextureFormat,
) -> VkTextureState raise RhiError {
  if format == TextureFormat::Depth32F {
    raise InvalidArgument("Depth32F cannot be used as a storage image")
  }
  let tex = create_image_and_view(
    d,
    width,
    height,
    vk_texture_format_for(d, format),
    @vk.VK_IMAGE_USAGE_STORAGE_BIT |
    @vk.VK_IMAGE_USAGE_SAMPLED_BIT |
    @vk.VK_IMAGE_USAGE_TRANSFER_SRC_BIT |
    @vk.VK_IMAGE_USAGE_TRANSFER_DST_BIT,
    @vk.VK_IMAGE_ASPECT_COLOR_BIT,
    SampleCount::X1,
    format,
  )
  let cmd = begin_one_time(d)
  cmd_image_barrier2(
    d,
    cmd,
    tex.image,
    @vk.VK_IMAGE_ASPECT_COLOR_BIT,
    @vk.VK_PIPELINE_STAGE_2_NONE,
    @vk.VK_ACCESS_2_NONE,
    @vk.VK_PIPELINE_STAGE_2_COMPUTE_SHADER_BIT,
    @vk.VK_ACCESS_2_SHADER_STORAGE_WRITE_BIT |
    @vk.VK_ACCESS_2_SHADER_STORAGE_READ_BIT,
    @vk.VK_IMAGE_LAYOUT_UNDEFINED,
    @vk.VK_IMAGE_LAYOUT_GENERAL,
  )
  end_one_time(d, cmd)
  tex.layout = @vk.VK_IMAGE_LAYOUT_GENERAL
  tex
}

///|
fn vk_texture_destroy(t : VkTextureState) -> Unit {
  enqueue_delete(t.device, DeleteTexture(t.view, t.attachment_view, t.image, t.alloc))
}

///|
fn vk_texture_readback_mip(
  t : VkTextureState,
  level : Int,
) -> FixedArray[Byte] raise RhiError {
  if t.samples != SampleCount::X1 {
    raise InvalidArgument("Cannot read back multisampled texture directly")
  }
  if level < 0 || level >= t.mip_levels {
    raise InvalidArgument(
      "Mip level \{level} out of range (0..\{t.mip_levels - 1})",
    )
  }
  let mut mw = t.width >> level
  let mut mh = t.height >> level
  if mw < 1 { mw = 1 }
  if mh < 1 { mh = 1 }
  let d = t.device
  let _ = (d.dfn.vkQueueWaitIdle)(d.queue)
  let bytes = mw * mh * texture_format_bytes(t.format)
  let staging = vk_buffer_create(d, bytes, BufferKind::Staging)
  let old_layout = t.layout
  let cmd = begin_one_time(d)
  cmd_image_barrier2_mips(
    d,
    cmd,
    t.image,
    @vk.VK_IMAGE_ASPECT_COLOR_BIT,
    level,
    1,
    @vk.VK_PIPELINE_STAGE_2_ALL_COMMANDS_BIT,
    @vk.VK_ACCESS_2_MEMORY_WRITE_BIT,
    @vk.VK_PIPELINE_STAGE_2_ALL_TRANSFER_BIT,
    @vk.VK_ACCESS_2_TRANSFER_READ_BIT,
    old_layout,
    @vk.VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,
  )
  let extent = @vk.VkExtent3D::new()
  extent.set_width(mw.reinterpret_as_uint())
  extent.set_height(mh.reinterpret_as_uint())
  extent.set_depth((1 : UInt32))
  let region = @vk.VkBufferImageCopy::new()
  let sub = @vk.VkImageSubresourceLayers::new()
  sub.set_aspectMask(@vk.VK_IMAGE_ASPECT_COLOR_BIT)
  sub.set_mipLevel(level.reinterpret_as_uint())
  sub.set_layerCount((1 : UInt32))
  region.set_imageSubresource(sub)
  region.set_imageExtent(extent)
  (d.dfn.vkCmdCopyImageToBuffer)(
    cmd,
    t.image,
    @vk.VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,
    staging.buffer,
    (1 : UInt32),
    region,
  )
  let restore_layout = if old_layout == @vk.VK_IMAGE_LAYOUT_UNDEFINED {
    @vk.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL
  } else {
    old_layout
  }
  cmd_image_barrier2_mips(
    d,
    cmd,
    t.image,
    @vk.VK_IMAGE_ASPECT_COLOR_BIT,
    level,
    1,
    @vk.VK_PIPELINE_STAGE_2_ALL_TRANSFER_BIT,
    @vk.VK_ACCESS_2_TRANSFER_READ_BIT,
    @vk.VK_PIPELINE_STAGE_2_ALL_COMMANDS_BIT,
    @vk.VK_ACCESS_2_SHADER_READ_BIT,
    @vk.VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,
    restore_layout,
  )
  end_one_time(d, cmd)
  extent.free()
  region.free()
  sub.free()
  if level == 0 && t.mip_levels == 1 {
    t.layout = restore_layout
  }
  let out = FixedArray::make(bytes, (0 : Byte))
  if bytes > 0 {
    @vk.memcpy_ptr(@vk.byte_ptr(out), staging.alloc.mapped, bytes)
  }
  vk_buffer_destroy(staging)
  out
}

///|
fn vk_texture_readback(t : VkTextureState) -> FixedArray[Byte] raise RhiError {
  vk_texture_readback_mip(t, 0)
}

///|
fn pick_vk_present_mode(
  d : VkDeviceState,
  surface : @vk.VkSurfaceKHR,
  requested : PresentMode,
) -> UInt32 {
  let target = match requested {
    PresentMode::Fifo => @vk.VK_PRESENT_MODE_FIFO_KHR
    PresentMode::Mailbox => @vk.VK_PRESENT_MODE_MAILBOX_KHR
    PresentMode::Immediate => @vk.VK_PRESENT_MODE_IMMEDIATE_KHR
  }
  let cnt = FixedArray::make(1, (0 : UInt32))
  let _ = (d.ifn.vkGetPhysicalDeviceSurfacePresentModesKHR)(
    d.phys,
    surface,
    cnt,
    FixedArray::make(0, (0 : UInt32)),
  )
  let n = cnt[0].reinterpret_as_int()
  if n <= 0 {
    return @vk.VK_PRESENT_MODE_FIFO_KHR
  }
  let modes = FixedArray::make(n, (0 : UInt32))
  let _ = (d.ifn.vkGetPhysicalDeviceSurfacePresentModesKHR)(
    d.phys,
    surface,
    cnt,
    modes,
  )
  for i = 0; i < n; i = i + 1 {
    if modes[i] == target {
      return target
    }
  }
  @vk.VK_PRESENT_MODE_FIFO_KHR
}

///|
fn build_swapchain_resources(
  d : VkDeviceState,
  surface : @vk.VkSurfaceKHR,
  window : UInt64,
  req_w : Int,
  req_h : Int,
  old_swapchain : @vk.VkSwapchainKHR,
  has_depth : Bool,
  enable_readback : Bool,
  present_mode : PresentMode,
) -> (
  @vk.VkSwapchainKHR,
  UInt32,
  Int,
  Int,
  FixedArray[@vk.VkImage],
  FixedArray[@vk.VkImageView],
  Array[@vk.VkSemaphore],
  @vk.VkImage,
  @vk.VkImageView,
  MemAlloc?,
) raise RhiError {
  let na = @vk.VkAllocationCallbacks::null()
  let supp = FixedArray::make(1, (0 : UInt32))
  let sr = (d.ifn.vkGetPhysicalDeviceSurfaceSupportKHR)(
    d.phys,
    d.queue_family,
    surface,
    supp,
  )
  if sr != 0 || supp[0] == (0 : UInt32) {
    raise SwapchainFailed(
      "Physical device does not support presentation to this surface",
    )
  }
  let caps = @vk.VkSurfaceCapabilitiesKHR::new()
  let cr = (d.ifn.vkGetPhysicalDeviceSurfaceCapabilitiesKHR)(
    d.phys,
    surface,
    caps,
  )
  if cr != 0 {
    caps.free()
    raise SwapchainFailed(
      "vkGetPhysicalDeviceSurfaceCapabilitiesKHR failed: \{cr}",
    )
  }
  let fc = FixedArray::make(1, (0 : UInt32))
  let _ = (d.ifn.vkGetPhysicalDeviceSurfaceFormatsKHR)(
    d.phys,
    surface,
    fc,
    @vk.VkSurfaceFormatKHR::null(),
  )
  let nfmt = fc[0].reinterpret_as_int()
  if nfmt <= 0 {
    caps.free()
    raise SwapchainFailed("No surface formats available")
  }
  let formats = @vk.VkSurfaceFormatKHR::array(nfmt)
  let _ = (d.ifn.vkGetPhysicalDeviceSurfaceFormatsKHR)(
    d.phys,
    surface,
    fc,
    formats,
  )
  // Prefer BGRA8 UNORM when exposed so color encoding matches across drivers.
  let mut format = formats.get_format_at(0)
  let mut color_space = formats.get_colorSpace_at(0)
  for i = 0; i < nfmt; i = i + 1 {
    if formats.get_format_at(i) == @vk.VK_FORMAT_B8G8R8A8_UNORM {
      format = formats.get_format_at(i)
      color_space = formats.get_colorSpace_at(i)
      break
    }
  }
  formats.free()

  let cur_ext = caps.get_currentExtent()
  let mut w = if cur_ext.get_width() != (0xFFFFFFFF : UInt32) {
    cur_ext.get_width().reinterpret_as_int()
  } else {
    let ww = @win.width(window)
    if ww > 0 { ww } else { req_w }
  }
  let mut h = if cur_ext.get_height() != (0xFFFFFFFF : UInt32) {
    cur_ext.get_height().reinterpret_as_int()
  } else {
    let wh = @win.height(window)
    if wh > 0 { wh } else { req_h }
  }
  if w < 1 { w = 1 }
  if h < 1 { h = 1 }
  let min_ext = caps.get_minImageExtent()
  let max_ext = caps.get_maxImageExtent()
  let min_w = min_ext.get_width().reinterpret_as_int()
  let max_w = max_ext.get_width().reinterpret_as_int()
  let min_h = min_ext.get_height().reinterpret_as_int()
  let max_h = max_ext.get_height().reinterpret_as_int()
  if w < min_w { w = min_w }
  if max_w > 0 && w > max_w { w = max_w }
  if h < min_h { h = min_h }
  if max_h > 0 && h > max_h { h = max_h }

  let mut min_imgs = caps.get_minImageCount() + (1 : UInt32)
  let max_imgs = caps.get_maxImageCount()
  if max_imgs > (0 : UInt32) && min_imgs > max_imgs {
    min_imgs = max_imgs
  }

  let extent = @vk.VkExtent2D::new()
  extent.set_width(w.reinterpret_as_uint())
  extent.set_height(h.reinterpret_as_uint())
  let swci = @vk.VkSwapchainCreateInfoKHR::new()
  swci.set_surface(surface)
  swci.set_minImageCount(min_imgs)
  swci.set_imageFormat(format)
  swci.set_imageColorSpace(color_space)
  swci.set_imageExtent(extent)
  swci.set_imageArrayLayers((1 : UInt32))
  let img_usage = if enable_readback {
    @vk.VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT |
    @vk.VK_IMAGE_USAGE_TRANSFER_SRC_BIT |
    @vk.VK_IMAGE_USAGE_TRANSFER_DST_BIT
  } else {
    @vk.VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT |
    @vk.VK_IMAGE_USAGE_TRANSFER_DST_BIT
  }
  swci.set_imageUsage(img_usage)
  swci.set_imageSharingMode(@vk.VK_SHARING_MODE_EXCLUSIVE)
  swci.set_preTransform(caps.get_currentTransform())
  swci.set_compositeAlpha(@vk.VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR)
  swci.set_presentMode(pick_vk_present_mode(d, surface, present_mode))
  swci.set_clipped((1 : UInt32))
  swci.set_oldSwapchain(old_swapchain)
  let sc_out = FixedArray::make(1, @vk.VkSwapchainKHR::null())
  let swr = (d.dfn.vkCreateSwapchainKHR)(d.dev, swci, na, sc_out)
  extent.free()
  swci.free()
  caps.free()
  if swr != 0 {
    raise SwapchainFailed("vkCreateSwapchainKHR failed with code \{swr}")
  }
  let swapchain = sc_out[0]
  let ic = FixedArray::make(1, (16 : UInt32))
  let img_buf = FixedArray::make(16, @vk.VkImage::null())
  let mut gir = (d.dfn.vkGetSwapchainImagesKHR)(d.dev, swapchain, ic, img_buf)
  let nimg = ic[0].reinterpret_as_int()
  let images = if gir == 5 && nimg > 16 {
    let big = FixedArray::make(nimg, @vk.VkImage::null())
    gir = (d.dfn.vkGetSwapchainImagesKHR)(d.dev, swapchain, ic, big)
    big
  } else {
    FixedArray::makei(nimg, fn(i) { img_buf[i] })
  }
  if gir != 0 {
    raise SwapchainFailed("vkGetSwapchainImagesKHR failed with code \{gir}")
  }
  let views = FixedArray::make(nimg, @vk.VkImageView::null())
  let range = @vk.VkImageSubresourceRange::new()
  range.set_aspectMask(@vk.VK_IMAGE_ASPECT_COLOR_BIT)
  range.set_levelCount((1 : UInt32))
  range.set_layerCount((1 : UInt32))
  for i = 0; i < nimg; i = i + 1 {
    let ivci = @vk.VkImageViewCreateInfo::new()
    ivci.set_image(images[i])
    ivci.set_viewType(@vk.VK_IMAGE_VIEW_TYPE_2D)
    ivci.set_format(format)
    ivci.set_subresourceRange(range)
    let iv_out = FixedArray::make(1, @vk.VkImageView::null())
    let _ = (d.dfn.vkCreateImageView)(d.dev, ivci, na, iv_out)
    views[i] = iv_out[0]
    ivci.free()
  }
  range.free()

  let render_finished : Array[@vk.VkSemaphore] = []
  let semci = @vk.VkSemaphoreCreateInfo::new()
  for i = 0; i < nimg; i = i + 1 {
    let s_out = FixedArray::make(1, @vk.VkSemaphore::null())
    let _ = (d.dfn.vkCreateSemaphore)(d.dev, semci, na, s_out)
    render_finished.push(s_out[0])
  }
  semci.free()

  let mut depth_image = @vk.VkImage::null()
  let mut depth_view = @vk.VkImageView::null()
  let mut depth_mem : MemAlloc? = None
  if has_depth {
    let dt = create_image_and_view(
      d,
      w,
      h,
      @vk.VK_FORMAT_D32_SFLOAT,
      @vk.VK_IMAGE_USAGE_DEPTH_STENCIL_ATTACHMENT_BIT,
      @vk.VK_IMAGE_ASPECT_DEPTH_BIT,
      SampleCount::X1,
      TextureFormat::Depth32F,
    )
    depth_image = dt.image
    depth_view = dt.view
    depth_mem = Some(dt.alloc)
  }

  (
    swapchain,
    format,
    w,
    h,
    images,
    views,
    render_finished,
    depth_image,
    depth_view,
    depth_mem,
  )
}

///|
fn vk_swapchain_create(
  d : VkDeviceState,
  desc : SwapchainDesc,
) -> VkSwapchainState raise RhiError {
  if d.headless {
    raise SwapchainFailed("Cannot create swapchain on a headless device")
  }
  let na = @vk.VkAllocationCallbacks::null()
  let _ = @win.initialize()
  let window = @win.create(
    desc.width,
    desc.height,
    desc.title,
  )
  let surface = @win.create_surface(d.inst, window)
  errdefer {
    (d.ifn.vkDestroySurfaceKHR)(d.inst, surface, na)
    @win.destroy(window)
    @win.terminate()
  }
  let (
    swapchain,
    format,
    w,
    h,
    images,
    views,
    render_finished,
    depth_image,
    depth_view,
    depth_mem,
  ) = build_swapchain_resources(
    d,
    surface,
    window,
    desc.width,
    desc.height,
    @vk.VkSwapchainKHR::null(),
    desc.depth,
    desc.enable_readback,
    desc.present_mode,
  )

  let cpci = @vk.VkCommandPoolCreateInfo::new()
  cpci.set_queueFamilyIndex(d.queue_family)
  cpci.set_flags(@vk.VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT)
  let pool_out = FixedArray::make(1, @vk.VkCommandPool::null())
  let _ = (d.dfn.vkCreateCommandPool)(d.dev, cpci, na, pool_out)
  cpci.free()
  let pool = pool_out[0]
  let cmds = FixedArray::make(MAX_FRAMES, @vk.VkCommandBuffer::null())
  let cbai = @vk.VkCommandBufferAllocateInfo::new()
  cbai.set_commandPool(pool)
  cbai.set_level(@vk.VK_COMMAND_BUFFER_LEVEL_PRIMARY)
  cbai.set_commandBufferCount(MAX_FRAMES.reinterpret_as_uint())
  let _ = (d.dfn.vkAllocateCommandBuffers)(d.dev, cbai, cmds)
  cbai.free()

  let image_available = FixedArray::make(MAX_FRAMES, @vk.VkSemaphore::null())
  let in_flight = FixedArray::make(MAX_FRAMES, @vk.VkFence::null())
  let semci = @vk.VkSemaphoreCreateInfo::new()
  let fci = @vk.VkFenceCreateInfo::new()
  fci.set_flags(@vk.VK_FENCE_CREATE_SIGNALED_BIT)
  for i = 0; i < MAX_FRAMES; i = i + 1 {
    let sa = FixedArray::make(1, @vk.VkSemaphore::null())
    let _ = (d.dfn.vkCreateSemaphore)(d.dev, semci, na, sa)
    image_available[i] = sa[0]
    let fa = FixedArray::make(1, @vk.VkFence::null())
    let _ = (d.dfn.vkCreateFence)(d.dev, fci, na, fa)
    in_flight[i] = fa[0]
  }
  semci.free()
  fci.free()

  let readback_bufs : Array[VkBufferState] = []
  if desc.enable_readback {
    let rb_bytes = w * h * 4
    readback_bufs.push(vk_buffer_create(d, rb_bytes, BufferKind::Staging))
    readback_bufs.push(vk_buffer_create(d, rb_bytes, BufferKind::Staging))
  }

  {
    device: d,
    window,
    surface,
    swapchain,
    format,
    images,
    views,
    render_finished,
    has_depth: desc.depth,
    enable_readback: desc.enable_readback,
    present_mode: desc.present_mode,
    depth_image,
    depth_view,
    depth_mem,
    pool,
    cmds,
    image_available,
    in_flight,
    slot_gen: FixedArray::make(MAX_FRAMES, (0 : UInt64)),
    readback_bufs,
    clear_color: desc.clear_color,
    width: w,
    height: h,
    frame_idx: 0,
    last_frame_idx: 0,
    image_index: 0,
    frame_gen: (0 : UInt64),
    needs_recreate: false,
  }
}

///|
fn recreate_swapchain(s : VkSwapchainState) -> Unit raise RhiError {
  let na = @vk.VkAllocationCallbacks::null()
  let d = s.device
  let _ = (d.dfn.vkDeviceWaitIdle)(d.dev)
  flush_deletes(d, true)
  for rb in s.readback_bufs {
    execute_delete(d, DeleteBuffer(rb.buffer, rb.alloc))
  }
  s.readback_bufs.clear()
  let old_sw = s.swapchain
  let old_views = s.views
  let old_sems = s.render_finished
  let old_depth_img = s.depth_image
  let old_depth_view = s.depth_view
  let old_depth_mem = s.depth_mem

  let (
    new_sw,
    fmt,
    w,
    h,
    imgs,
    views,
    sems,
    dimg,
    dview,
    dmem,
  ) = build_swapchain_resources(
    d,
    s.surface,
    s.window,
    s.width,
    s.height,
    old_sw,
    s.has_depth,
    s.enable_readback,
    s.present_mode,
  )
  for i = 0; i < old_views.length(); i = i + 1 {
    (d.dfn.vkDestroyImageView)(d.dev, old_views[i], na)
  }
  for sem in old_sems {
    (d.dfn.vkDestroySemaphore)(d.dev, sem, na)
  }
  match old_depth_mem {
    Some(m) => {
      (d.dfn.vkDestroyImageView)(d.dev, old_depth_view, na)
      (d.dfn.vkDestroyImage)(d.dev, old_depth_img, na)
      d.alloc.free(m)
    }
    None => ()
  }
  (d.dfn.vkDestroySwapchainKHR)(d.dev, old_sw, na)

  if s.enable_readback {
    let rb_bytes = w * h * 4
    s.readback_bufs.push(vk_buffer_create(d, rb_bytes, BufferKind::Staging))
    s.readback_bufs.push(vk_buffer_create(d, rb_bytes, BufferKind::Staging))
  }
  s.swapchain = new_sw
  s.format = fmt
  s.width = w
  s.height = h
  s.images = imgs
  s.views = views
  s.render_finished = sems
  s.depth_image = dimg
  s.depth_view = dview
  s.depth_mem = dmem
  s.needs_recreate = false
}

///|
fn set_dynamic_viewport_scissor(
  d : VkDeviceState,
  cmd : @vk.VkCommandBuffer,
  w : Int,
  h : Int,
) -> Unit {
  let vp = @vk.VkViewport::new()
  vp.set_x((0.0 : Float))
  vp.set_y((0.0 : Float))
  vp.set_width(Float::from_int(w))
  vp.set_height(Float::from_int(h))
  vp.set_minDepth((0.0 : Float))
  vp.set_maxDepth((1.0 : Float))
  (d.dfn.vkCmdSetViewport)(cmd, (0 : UInt32), (1 : UInt32), vp)
  vp.free()
  let ext = @vk.VkExtent2D::new()
  ext.set_width(w.reinterpret_as_uint())
  ext.set_height(h.reinterpret_as_uint())
  let sc = @vk.VkRect2D::new()
  sc.set_extent(ext)
  (d.dfn.vkCmdSetScissor)(cmd, (0 : UInt32), (1 : UInt32), sc)
  ext.free()
  sc.free()
}

///|
fn vk_swapchain_begin_frame_commands(
  s : VkSwapchainState,
) -> VkCmdState raise RhiError {
  let d = s.device
  @win.poll()
  if @win.take_resized(s.window) || s.needs_recreate {
    recreate_swapchain(s)
  }
  let fi = s.frame_idx
  let fence = FixedArray::make(1, s.in_flight[fi])
  let wr = (d.dfn.vkWaitForFences)(
    d.dev,
    (1 : UInt32),
    fence,
    (1 : UInt32),
    (0xFFFFFFFFFFFFFFFF : UInt64),
  )
  if wr != 0 {
    raise CommandFailed("vkWaitForFences failed: \{wr}")
  }
  if s.slot_gen[fi] > d.completed_gen {
    d.completed_gen = s.slot_gen[fi]
  }
  flush_deletes(d, false)

  let idx_out = FixedArray::make(1, (0 : UInt32))
  let mut ar = (d.dfn.vkAcquireNextImageKHR)(
    d.dev,
    s.swapchain,
    (0xFFFFFFFFFFFFFFFF : UInt64),
    s.image_available[fi],
    @vk.VkFence::null(),
    idx_out,
  )
  // VK_ERROR_OUT_OF_DATE_KHR (-1000001004)
  if ar == (-1000001004 : Int32) {
    recreate_swapchain(s)
    ar = (d.dfn.vkAcquireNextImageKHR)(
      d.dev,
      s.swapchain,
      (0xFFFFFFFFFFFFFFFF : UInt64),
      s.image_available[fi],
      @vk.VkFence::null(),
      idx_out,
    )
  }
  // Allow VK_SUCCESS (0) or VK_SUBOPTIMAL_KHR (1000001003)
  if ar != 0 && ar != (1000001003 : Int32) {
    raise SwapchainFailed("vkAcquireNextImageKHR failed with code \{ar}")
  }
  if ar == (1000001003 : Int32) {
    s.needs_recreate = true
  }
  let _ = (d.dfn.vkResetFences)(d.dev, (1 : UInt32), fence)
  s.image_index = idx_out[0].reinterpret_as_int()
  s.frame_gen = s.frame_gen + (1 : UInt64)
  let cmd = s.cmds[fi]
  let _ = (d.dfn.vkResetCommandBuffer)(cmd, (0 : UInt32))
  let cbi = @vk.VkCommandBufferBeginInfo::new()
  cbi.set_flags(@vk.VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT)
  let br = (d.dfn.vkBeginCommandBuffer)(cmd, cbi)
  cbi.free()
  if br != 0 {
    raise CommandFailed("vkBeginCommandBuffer failed: \{br}")
  }
  d.active_recordings = d.active_recordings + 1
  {
    device: d,
    cmd,
    frame_idx: fi,
    frame_gen: s.frame_gen,
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
  }
}

///|
fn vk_cmd_begin_swapchain_pass(
  c : VkCmdState,
  s : VkSwapchainState,
  load_op : LoadOp,
  clear_color : ClearColor?,
) -> Unit {
  let d = s.device
  let old_layout = if c.swapchain_image_initialized {
    @vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL
  } else {
    @vk.VK_IMAGE_LAYOUT_UNDEFINED
  }
  cmd_image_barrier2(
    d,
    c.cmd,
    s.images[s.image_index],
    @vk.VK_IMAGE_ASPECT_COLOR_BIT,
    @vk.VK_PIPELINE_STAGE_2_COLOR_ATTACHMENT_OUTPUT_BIT,
    @vk.VK_ACCESS_2_NONE,
    @vk.VK_PIPELINE_STAGE_2_COLOR_ATTACHMENT_OUTPUT_BIT,
    @vk.VK_ACCESS_2_COLOR_ATTACHMENT_WRITE_BIT |
    @vk.VK_ACCESS_2_COLOR_ATTACHMENT_READ_BIT,
    old_layout,
    @vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
  )
  c.swapchain_image_initialized = true
  if s.has_depth {
    cmd_image_barrier2(
      d,
      c.cmd,
      s.depth_image,
      @vk.VK_IMAGE_ASPECT_DEPTH_BIT,
      @vk.VK_PIPELINE_STAGE_2_EARLY_FRAGMENT_TESTS_BIT |
      @vk.VK_PIPELINE_STAGE_2_LATE_FRAGMENT_TESTS_BIT,
      @vk.VK_ACCESS_2_NONE,
      @vk.VK_PIPELINE_STAGE_2_EARLY_FRAGMENT_TESTS_BIT |
      @vk.VK_PIPELINE_STAGE_2_LATE_FRAGMENT_TESTS_BIT,
      @vk.VK_ACCESS_2_DEPTH_STENCIL_ATTACHMENT_READ_BIT |
      @vk.VK_ACCESS_2_DEPTH_STENCIL_ATTACHMENT_WRITE_BIT,
      @vk.VK_IMAGE_LAYOUT_UNDEFINED,
      @vk.VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL,
    )
  }

  let ext = @vk.VkExtent2D::new()
  ext.set_width(s.width.reinterpret_as_uint())
  ext.set_height(s.height.reinterpret_as_uint())
  let area = @vk.VkRect2D::new()
  area.set_extent(ext)
  let cc = match clear_color {
    Some(col) => col
    None => s.clear_color
  }
  let cv = @vk.VkClearValue::new()
  cv.set_color_rgba(cc.r, cc.g, cc.b, cc.a)
  let catt = @vk.VkRenderingAttachmentInfo::new()
  catt.set_imageView(s.views[s.image_index])
  catt.set_imageLayout(@vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL)
  catt.set_loadOp(vk_load_op(load_op))
  catt.set_storeOp(@vk.VK_ATTACHMENT_STORE_OP_STORE)
  catt.set_clearValue(cv)

  let ri = @vk.VkRenderingInfo::new()
  ri.set_renderArea(area)
  ri.set_layerCount((1 : UInt32))
  ri.set_colorAttachmentCount((1 : UInt32))
  ri.set_pColorAttachments(catt)

  let dcv = @vk.VkClearValue::new()
  let datt = @vk.VkRenderingAttachmentInfo::new()
  if s.has_depth {
    dcv.set_depth_stencil((1.0 : Float), (0 : UInt32))
    datt.set_imageView(s.depth_view)
    datt.set_imageLayout(@vk.VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL)
    datt.set_loadOp(@vk.VK_ATTACHMENT_LOAD_OP_CLEAR)
    datt.set_storeOp(@vk.VK_ATTACHMENT_STORE_OP_DONT_CARE)
    datt.set_clearValue(dcv)
    ri.set_pDepthAttachment(datt)
  }

  (d.dfn.vkCmdBeginRendering)(c.cmd, ri)
  ext.free()
  area.free()
  cv.free()
  catt.free()
  dcv.free()
  datt.free()
  ri.free()

  set_dynamic_viewport_scissor(d, c.cmd, s.width, s.height)
  c.in_swapchain_pass = true
}

///|
fn vk_cmd_end_swapchain_pass(c : VkCmdState) -> Unit {
  if c.in_swapchain_pass {
    (c.device.dfn.vkCmdEndRendering)(c.cmd)
    c.in_swapchain_pass = false
  }
}

///|
fn vk_swapchain_begin_frame(
  s : VkSwapchainState,
) -> VkCmdState raise RhiError {
  let c = vk_swapchain_begin_frame_commands(s)
  vk_cmd_begin_swapchain_pass(c, s, LoadOp::Clear, None)
  c
}

///|
fn vk_swapchain_end_frame(
  s : VkSwapchainState,
  c : VkCmdState,
) -> Unit raise RhiError {
  let d = s.device
  let fi = s.frame_idx
  let img_idx = s.image_index
  if c.in_swapchain_pass {
    vk_cmd_end_swapchain_pass(c)
  }
  if !c.swapchain_image_initialized {
    cmd_image_barrier2(
      d,
      c.cmd,
      s.images[img_idx],
      @vk.VK_IMAGE_ASPECT_COLOR_BIT,
      @vk.VK_PIPELINE_STAGE_2_COLOR_ATTACHMENT_OUTPUT_BIT,
      @vk.VK_ACCESS_2_NONE,
      @vk.VK_PIPELINE_STAGE_2_COLOR_ATTACHMENT_OUTPUT_BIT,
      @vk.VK_ACCESS_2_COLOR_ATTACHMENT_WRITE_BIT,
      @vk.VK_IMAGE_LAYOUT_UNDEFINED,
      @vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
    )
  }
  if s.enable_readback {
    cmd_image_barrier2(
      d,
      c.cmd,
      s.images[img_idx],
      @vk.VK_IMAGE_ASPECT_COLOR_BIT,
      @vk.VK_PIPELINE_STAGE_2_COLOR_ATTACHMENT_OUTPUT_BIT,
      @vk.VK_ACCESS_2_COLOR_ATTACHMENT_WRITE_BIT,
      @vk.VK_PIPELINE_STAGE_2_ALL_TRANSFER_BIT,
      @vk.VK_ACCESS_2_TRANSFER_READ_BIT,
      @vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
      @vk.VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,
    )
    let extent = @vk.VkExtent3D::new()
    extent.set_width(s.width.reinterpret_as_uint())
    extent.set_height(s.height.reinterpret_as_uint())
    extent.set_depth((1 : UInt32))
    let sub = @vk.VkImageSubresourceLayers::new()
    sub.set_aspectMask(@vk.VK_IMAGE_ASPECT_COLOR_BIT)
    sub.set_layerCount((1 : UInt32))
    let region = @vk.VkBufferImageCopy::new()
    region.set_imageSubresource(sub)
    region.set_imageExtent(extent)
    (d.dfn.vkCmdCopyImageToBuffer)(
      c.cmd,
      s.images[img_idx],
      @vk.VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,
      s.readback_bufs[fi].buffer,
      (1 : UInt32),
      region,
    )
    extent.free()
    sub.free()
    region.free()
    cmd_image_barrier2(
      d,
      c.cmd,
      s.images[img_idx],
      @vk.VK_IMAGE_ASPECT_COLOR_BIT,
      @vk.VK_PIPELINE_STAGE_2_ALL_TRANSFER_BIT,
      @vk.VK_ACCESS_2_TRANSFER_READ_BIT,
      @vk.VK_PIPELINE_STAGE_2_NONE,
      @vk.VK_ACCESS_2_NONE,
      @vk.VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,
      @vk.VK_IMAGE_LAYOUT_PRESENT_SRC_KHR,
    )
  } else {
    cmd_image_barrier2(
      d,
      c.cmd,
      s.images[img_idx],
      @vk.VK_IMAGE_ASPECT_COLOR_BIT,
      @vk.VK_PIPELINE_STAGE_2_COLOR_ATTACHMENT_OUTPUT_BIT,
      @vk.VK_ACCESS_2_COLOR_ATTACHMENT_WRITE_BIT,
      @vk.VK_PIPELINE_STAGE_2_NONE,
      @vk.VK_ACCESS_2_NONE,
      @vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
      @vk.VK_IMAGE_LAYOUT_PRESENT_SRC_KHR,
    )
  }
  let er = (d.dfn.vkEndCommandBuffer)(c.cmd)
  if er != 0 {
    raise CommandFailed("vkEndCommandBuffer failed: \{er}")
  }

  let wait_si = @vk.VkSemaphoreSubmitInfo::new()
  wait_si.set_semaphore(s.image_available[fi])
  wait_si.set_stageMask(@vk.VK_PIPELINE_STAGE_2_COLOR_ATTACHMENT_OUTPUT_BIT)
  let signal_si = @vk.VkSemaphoreSubmitInfo::new()
  signal_si.set_semaphore(s.render_finished[img_idx])
  signal_si.set_stageMask(@vk.VK_PIPELINE_STAGE_2_ALL_COMMANDS_BIT)
  let cmd_si = @vk.VkCommandBufferSubmitInfo::new()
  cmd_si.set_commandBuffer(c.cmd)
  let si2 = @vk.VkSubmitInfo2::new()
  si2.set_waitSemaphoreInfoCount((1 : UInt32))
  si2.set_pWaitSemaphoreInfos(wait_si)
  si2.set_commandBufferInfoCount((1 : UInt32))
  si2.set_pCommandBufferInfos(cmd_si)
  si2.set_signalSemaphoreInfoCount((1 : UInt32))
  si2.set_pSignalSemaphoreInfos(signal_si)
  let sr = (d.dfn.vkQueueSubmit2)(
    d.queue,
    (1 : UInt32),
    si2,
    s.in_flight[fi],
  )
  si2.free()
  wait_si.free()
  signal_si.free()
  cmd_si.free()
  if d.active_recordings > 0 {
    d.active_recordings = d.active_recordings - 1
  }
  if sr != 0 {
    raise CommandFailed("vkQueueSubmit2 failed: \{sr}")
  }
  s.slot_gen[fi] = d.current_gen
  d.current_gen = d.current_gen + (1 : UInt64)

  let wait_sems = FixedArray::make(1, s.render_finished[img_idx])
  let sws = FixedArray::make(1, s.swapchain)
  let idxs = FixedArray::make(1, img_idx.reinterpret_as_uint())
  let present = @vk.VkPresentInfoKHR::new()
  present.set_waitSemaphoreCount((1 : UInt32))
  present.set_pWaitSemaphores(wait_sems)
  present.set_swapchainCount((1 : UInt32))
  present.set_pSwapchains(sws)
  present.set_pImageIndices(idxs)
  let pr = (d.dfn.vkQueuePresentKHR)(d.queue, present)
  present.free()
  if pr == (-1000001004 : Int32) || pr == (1000001003 : Int32) {
    s.needs_recreate = true
  } else if pr != 0 {
    raise SwapchainFailed("vkQueuePresentKHR failed: \{pr}")
  }
  s.last_frame_idx = fi
  s.frame_idx = (fi + 1) % MAX_FRAMES
}

///|
fn vk_swapchain_readback(s : VkSwapchainState) -> FixedArray[Byte] {
  if !s.enable_readback || s.readback_bufs.length() == 0 {
    return FixedArray::make(0, (0 : Byte))
  }
  let d = s.device
  let fi = s.last_frame_idx
  let fence = FixedArray::make(1, s.in_flight[fi])
  let _ = (d.dfn.vkWaitForFences)(
    d.dev,
    (1 : UInt32),
    fence,
    (1 : UInt32),
    (0xFFFFFFFFFFFFFFFF : UInt64),
  )
  let bytes = s.width * s.height * 4
  let out = FixedArray::make(bytes, (0 : Byte))
  if bytes > 0 {
    @vk.memcpy_ptr(@vk.byte_ptr(out), s.readback_bufs[fi].alloc.mapped, bytes)
  }
  out
}

///|
fn vk_swapchain_destroy(s : VkSwapchainState) -> Unit {
  let na = @vk.VkAllocationCallbacks::null()
  let d = s.device
  let _ = (d.dfn.vkDeviceWaitIdle)(d.dev)
  flush_deletes(d, true)
  for rb in s.readback_bufs {
    execute_delete(d, DeleteBuffer(rb.buffer, rb.alloc))
  }
  s.readback_bufs.clear()
  for i = 0; i < MAX_FRAMES; i = i + 1 {
    (d.dfn.vkDestroyFence)(d.dev, s.in_flight[i], na)
    (d.dfn.vkDestroySemaphore)(d.dev, s.image_available[i], na)
  }
  for sem in s.render_finished {
    (d.dfn.vkDestroySemaphore)(d.dev, sem, na)
  }
  (d.dfn.vkDestroyCommandPool)(d.dev, s.pool, na)
  for i = 0; i < s.views.length(); i = i + 1 {
    (d.dfn.vkDestroyImageView)(d.dev, s.views[i], na)
  }
  match s.depth_mem {
    Some(m) => {
      (d.dfn.vkDestroyImageView)(d.dev, s.depth_view, na)
      (d.dfn.vkDestroyImage)(d.dev, s.depth_image, na)
      d.alloc.free(m)
    }
    None => ()
  }
  (d.dfn.vkDestroySwapchainKHR)(d.dev, s.swapchain, na)
  (d.ifn.vkDestroySurfaceKHR)(d.inst, s.surface, na)
  @win.destroy(s.window)
  @win.terminate()
}

///|
fn resolve_slot_bindings(
  count : Int,
  explicit : Array[Int],
  default_start : Int,
) -> FixedArray[Int] {
  FixedArray::makei(count, fn(i) {
    if i < explicit.length() {
      explicit[i]
    } else {
      default_start + i
    }
  })
}

///|
fn alloc_descriptor_pool_chunk(
  d : VkDeviceState,
  set_layout : @vk.VkDescriptorSetLayout,
  uniform_slots : Int,
  texture_slots : Int,
  storage_slots : Int,
  storage_image_slots : Int,
  accel_slots : Int,
  count : Int,
) -> (@vk.VkDescriptorPool, Array[@vk.VkDescriptorSet]) raise RhiError {
  let na = @vk.VkAllocationCallbacks::null()
  let nsizes = (if uniform_slots > 0 { 1 } else { 0 }) +
    (if texture_slots > 0 { 1 } else { 0 }) +
    (if storage_slots > 0 { 1 } else { 0 }) +
    (if storage_image_slots > 0 { 1 } else { 0 }) +
    (if accel_slots > 0 { 1 } else { 0 })
  let sizes = @vk.VkDescriptorPoolSize::array(nsizes)
  let mut si = 0
  if uniform_slots > 0 {
    sizes.set_type_at(si, @vk.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER)
    sizes.set_descriptorCount_at(
      si,
      (uniform_slots * count).reinterpret_as_uint(),
    )
    si = si + 1
  }
  if texture_slots > 0 {
    sizes.set_type_at(si, @vk.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER)
    sizes.set_descriptorCount_at(
      si,
      (texture_slots * count).reinterpret_as_uint(),
    )
    si = si + 1
  }
  if storage_slots > 0 {
    sizes.set_type_at(si, @vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER)
    sizes.set_descriptorCount_at(
      si,
      (storage_slots * count).reinterpret_as_uint(),
    )
    si = si + 1
  }
  if storage_image_slots > 0 {
    sizes.set_type_at(si, @vk.VK_DESCRIPTOR_TYPE_STORAGE_IMAGE)
    sizes.set_descriptorCount_at(
      si,
      (storage_image_slots * count).reinterpret_as_uint(),
    )
    si = si + 1
  }
  if accel_slots > 0 {
    sizes.set_type_at(si, @vk.VK_DESCRIPTOR_TYPE_ACCELERATION_STRUCTURE_KHR)
    sizes.set_descriptorCount_at(
      si,
      (accel_slots * count).reinterpret_as_uint(),
    )
  }
  let dpci = @vk.VkDescriptorPoolCreateInfo::new()
  dpci.set_maxSets(count.reinterpret_as_uint())
  dpci.set_poolSizeCount(nsizes.reinterpret_as_uint())
  dpci.set_pPoolSizes(sizes)
  let dpool_out = FixedArray::make(1, @vk.VkDescriptorPool::null())
  let pr = (d.dfn.vkCreateDescriptorPool)(d.dev, dpci, na, dpool_out)
  sizes.free()
  dpci.free()
  if pr != 0 {
    raise PipelineFailed("vkCreateDescriptorPool failed: \{pr}")
  }
  let descriptor_pool = dpool_out[0]
  let layouts = FixedArray::make(count, set_layout)
  let dsai = @vk.VkDescriptorSetAllocateInfo::new()
  dsai.set_descriptorPool(descriptor_pool)
  dsai.set_descriptorSetCount(count.reinterpret_as_uint())
  dsai.set_pSetLayouts(layouts)
  let sets = FixedArray::make(count, @vk.VkDescriptorSet::null())
  let ar = (d.dfn.vkAllocateDescriptorSets)(d.dev, dsai, sets)
  dsai.free()
  if ar != 0 {
    (d.dfn.vkDestroyDescriptorPool)(d.dev, descriptor_pool, na)
    raise PipelineFailed("vkAllocateDescriptorSets failed: \{ar}")
  }
  let out : Array[@vk.VkDescriptorSet] = []
  for i = 0; i < count; i = i + 1 {
    out.push(sets[i])
  }
  (descriptor_pool, out)
}

///|
fn alloc_pipeline_descriptors(
  d : VkDeviceState,
  u_bindings : FixedArray[Int],
  t_bindings : FixedArray[Int],
  s_bindings : FixedArray[Int],
  si_bindings : FixedArray[Int],
  a_bindings : FixedArray[Int],
  stages : UInt32,
) -> (
  @vk.VkDescriptorSetLayout,
  Array[@vk.VkDescriptorPool],
  FixedArray[Array[@vk.VkDescriptorSet]],
) raise RhiError {
  let na = @vk.VkAllocationCallbacks::null()
  let uniform_slots = u_bindings.length()
  let texture_slots = t_bindings.length()
  let storage_slots = s_bindings.length()
  let storage_image_slots = si_bindings.length()
  let accel_slots = a_bindings.length()
  let total = uniform_slots +
    texture_slots +
    storage_slots +
    storage_image_slots +
    accel_slots
  let bindings = @vk.VkDescriptorSetLayoutBinding::array(total)
  let mut bi = 0
  for i = 0; i < uniform_slots; i = i + 1 {
    bindings.set_binding_at(bi, u_bindings[i].reinterpret_as_uint())
    bindings.set_descriptorType_at(bi, @vk.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER)
    bindings.set_descriptorCount_at(bi, (1 : UInt32))
    bindings.set_stageFlags_at(bi, stages)
    bi = bi + 1
  }
  for i = 0; i < texture_slots; i = i + 1 {
    bindings.set_binding_at(bi, t_bindings[i].reinterpret_as_uint())
    bindings.set_descriptorType_at(
      bi,
      @vk.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,
    )
    bindings.set_descriptorCount_at(bi, (1 : UInt32))
    bindings.set_stageFlags_at(
      bi,
      if (stages & @vk.VK_SHADER_STAGE_COMPUTE_BIT) != (0 : UInt32) {
        stages
      } else {
        @vk.VK_SHADER_STAGE_FRAGMENT_BIT
      },
    )
    bi = bi + 1
  }
  for i = 0; i < storage_slots; i = i + 1 {
    bindings.set_binding_at(bi, s_bindings[i].reinterpret_as_uint())
    bindings.set_descriptorType_at(bi, @vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER)
    bindings.set_descriptorCount_at(bi, (1 : UInt32))
    bindings.set_stageFlags_at(bi, stages | @vk.VK_SHADER_STAGE_COMPUTE_BIT)
    bi = bi + 1
  }
  for i = 0; i < storage_image_slots; i = i + 1 {
    bindings.set_binding_at(bi, si_bindings[i].reinterpret_as_uint())
    bindings.set_descriptorType_at(bi, @vk.VK_DESCRIPTOR_TYPE_STORAGE_IMAGE)
    bindings.set_descriptorCount_at(bi, (1 : UInt32))
    bindings.set_stageFlags_at(bi, stages | @vk.VK_SHADER_STAGE_COMPUTE_BIT)
    bi = bi + 1
  }
  for i = 0; i < accel_slots; i = i + 1 {
    bindings.set_binding_at(bi, a_bindings[i].reinterpret_as_uint())
    bindings.set_descriptorType_at(
      bi,
      @vk.VK_DESCRIPTOR_TYPE_ACCELERATION_STRUCTURE_KHR,
    )
    bindings.set_descriptorCount_at(bi, (1 : UInt32))
    bindings.set_stageFlags_at(bi, stages | @vk.VK_SHADER_STAGE_COMPUTE_BIT)
    bi = bi + 1
  }
  let dslci = @vk.VkDescriptorSetLayoutCreateInfo::new()
  dslci.set_bindingCount(total.reinterpret_as_uint())
  dslci.set_pBindings(bindings)
  let dsl_out = FixedArray::make(1, @vk.VkDescriptorSetLayout::null())
  let lr = (d.dfn.vkCreateDescriptorSetLayout)(d.dev, dslci, na, dsl_out)
  bindings.free()
  dslci.free()
  if lr != 0 {
    raise PipelineFailed("vkCreateDescriptorSetLayout failed: \{lr}")
  }
  let set_layout = dsl_out[0]
  let frame_sets : FixedArray[Array[@vk.VkDescriptorSet]] = FixedArray::makei(
    MAX_FRAMES,
    fn(_i) { [] },
  )
  let pools : Array[@vk.VkDescriptorPool] = []

  if total == 0 {
    return (set_layout, pools, frame_sets)
  }

  for f = 0; f < MAX_FRAMES; f = f + 1 {
    let (pool, chunk) = alloc_descriptor_pool_chunk(
      d, set_layout, uniform_slots, texture_slots, storage_slots, storage_image_slots,
      accel_slots, SETS_PER_FRAME,
    ) catch {
      err => {
        for p in pools {
          (d.dfn.vkDestroyDescriptorPool)(d.dev, p, na)
        }
        (d.dfn.vkDestroyDescriptorSetLayout)(d.dev, set_layout, na)
        raise err
      }
    }
    pools.push(pool)
    for s in chunk {
      frame_sets[f].push(s)
    }
  }
  (set_layout, pools, frame_sets)
}

///|
fn vk_graphics_pipeline_create(
  d : VkDeviceState,
  desc : PipelineDesc,
  default_color_vk_fmt : UInt32,
) -> VkPipelineState raise RhiError {
  if desc.vert.length() == 0 || (!desc.depth_only && desc.frag.length() == 0) {
    raise InvalidArgument("Graphics pipeline requires non-empty SPIR-V shaders")
  }
  let has_frag = desc.frag.length() > 0
  let na = @vk.VkAllocationCallbacks::null()
  let vsmci = @vk.VkShaderModuleCreateInfo::new()
  vsmci.set_codeSize((desc.vert.length() * 4).to_uint64())
  vsmci.set_pCode(desc.vert)
  let vsm_out = FixedArray::make(1, @vk.VkShaderModule::null())
  let vr = (d.dfn.vkCreateShaderModule)(d.dev, vsmci, na, vsm_out)
  vsmci.free()
  if vr != 0 {
    raise PipelineFailed("Vertex vkCreateShaderModule failed: \{vr}")
  }
  let fsm_out = FixedArray::make(1, @vk.VkShaderModule::null())
  if has_frag {
    let fsmci = @vk.VkShaderModuleCreateInfo::new()
    fsmci.set_codeSize((desc.frag.length() * 4).to_uint64())
    fsmci.set_pCode(desc.frag)
    let fr = (d.dfn.vkCreateShaderModule)(d.dev, fsmci, na, fsm_out)
    fsmci.free()
    if fr != 0 {
      (d.dfn.vkDestroyShaderModule)(d.dev, vsm_out[0], na)
      raise PipelineFailed("Fragment vkCreateShaderModule failed: \{fr}")
    }
  }

  let stage_count = if has_frag { 2 } else { 1 }
  let stages = @vk.VkPipelineShaderStageCreateInfo::array(stage_count)
  stages.set_stage_at(0, @vk.VK_SHADER_STAGE_VERTEX_BIT)
  stages.set_module_at(0, vsm_out[0])
  stages.set_pName_at(0, @vk.cstr(desc.vert_entry))
  if has_frag {
    stages.set_stage_at(1, @vk.VK_SHADER_STAGE_FRAGMENT_BIT)
    stages.set_module_at(1, fsm_out[0])
    stages.set_pName_at(1, @vk.cstr(desc.frag_entry))
  }
  let stage_flags = if has_frag {
    @vk.VK_SHADER_STAGE_VERTEX_BIT | @vk.VK_SHADER_STAGE_FRAGMENT_BIT
  } else {
    @vk.VK_SHADER_STAGE_VERTEX_BIT
  }

  let use_layouts = desc.vertex_layouts.length() > 0
  let n_bindings = if use_layouts {
    desc.vertex_layouts.length()
  } else if desc.vertex_formats.length() > 0 {
    1
  } else {
    0
  }
  let nattr = if use_layouts {
    let mut total = 0
    for l in desc.vertex_layouts {
      total = total + l.attributes.length()
    }
    total
  } else {
    desc.vertex_formats.length()
  }
  let attribs = @vk.VkVertexInputAttributeDescription::array(nattr)
  let vbindings = @vk.VkVertexInputBindingDescription::array(n_bindings)
  if use_layouts {
    let mut ai = 0
    for bi = 0; bi < desc.vertex_layouts.length(); bi = bi + 1 {
      let l = desc.vertex_layouts[bi]
      vbindings.set_binding_at(bi, bi.reinterpret_as_uint())
      vbindings.set_stride_at(bi, l.stride.reinterpret_as_uint())
      vbindings.set_inputRate_at(bi, vk_step_mode(l.step_mode))
      for attr in l.attributes {
        attribs.set_binding_at(ai, bi.reinterpret_as_uint())
        attribs.set_location_at(ai, attr.location.reinterpret_as_uint())
        attribs.set_format_at(ai, vk_vertex_format(attr.format))
        attribs.set_offset_at(ai, attr.offset.reinterpret_as_uint())
        ai = ai + 1
      }
    }
  } else if desc.vertex_formats.length() > 0 {
    let mut offset = 0
    for i = 0; i < desc.vertex_formats.length(); i = i + 1 {
      let f = desc.vertex_formats[i]
      attribs.set_binding_at(i, (0 : UInt32))
      attribs.set_location_at(i, i.reinterpret_as_uint())
      attribs.set_format_at(i, vk_vertex_format(f))
      attribs.set_offset_at(i, offset.reinterpret_as_uint())
      offset = offset + vertex_format_bytes(f)
    }
    vbindings.set_binding_at(0, (0 : UInt32))
    vbindings.set_stride_at(0, offset.reinterpret_as_uint())
    vbindings.set_inputRate_at(0, @vk.VK_VERTEX_INPUT_RATE_VERTEX)
  }
  let vertex_input = @vk.VkPipelineVertexInputStateCreateInfo::new()
  if n_bindings > 0 {
    vertex_input.set_vertexBindingDescriptionCount(n_bindings.reinterpret_as_uint())
    vertex_input.set_pVertexBindingDescriptions(vbindings)
  }
  if nattr > 0 {
    vertex_input.set_vertexAttributeDescriptionCount(nattr.reinterpret_as_uint())
    vertex_input.set_pVertexAttributeDescriptions(attribs)
  }

  let input_assembly = @vk.VkPipelineInputAssemblyStateCreateInfo::new()
  input_assembly.set_topology(vk_topology(desc.topology))

  let viewport_state = @vk.VkPipelineViewportStateCreateInfo::new()
  viewport_state.set_viewportCount((1 : UInt32))
  viewport_state.set_scissorCount((1 : UInt32))

  let has_stencil = desc.stencil is Some(_)
  let dyn_count = if has_stencil { 3 } else { 2 }
  let dyn_states = FixedArray::make(dyn_count, @vk.VK_DYNAMIC_STATE_VIEWPORT)
  dyn_states[1] = @vk.VK_DYNAMIC_STATE_SCISSOR
  if has_stencil {
    dyn_states[2] = @vk.VK_DYNAMIC_STATE_STENCIL_REFERENCE
  }
  let dyn_ci = @vk.VkPipelineDynamicStateCreateInfo::new()
  dyn_ci.set_dynamicStateCount(dyn_count.reinterpret_as_uint())
  dyn_ci.set_pDynamicStates(dyn_states)

  let rasterizer = @vk.VkPipelineRasterizationStateCreateInfo::new()
  rasterizer.set_polygonMode(@vk.VK_POLYGON_MODE_FILL)
  rasterizer.set_cullMode(vk_cull(desc.cull_mode))
  rasterizer.set_frontFace(vk_front_face(desc.front_face))
  rasterizer.set_lineWidth((1.0 : Float))
  if desc.depth_bias {
    rasterizer.set_depthBiasEnable((1 : UInt32))
    rasterizer.set_depthBiasConstantFactor(desc.depth_bias_constant)
    rasterizer.set_depthBiasSlopeFactor(desc.depth_bias_slope)
  }

  let multisample = @vk.VkPipelineMultisampleStateCreateInfo::new()
  multisample.set_rasterizationSamples(vk_samples(desc.samples))

  let depth_stencil = @vk.VkPipelineDepthStencilStateCreateInfo::new()
  depth_stencil.set_depthTestEnable(
    if desc.depth_test { (1 : UInt32) } else { (0 : UInt32) },
  )
  depth_stencil.set_depthWriteEnable(
    if desc.depth_write { (1 : UInt32) } else { (0 : UInt32) },
  )
  depth_stencil.set_depthCompareOp(vk_compare_op(desc.depth_compare))
  let mut stencil_ref_opt : UInt32? = None
  match desc.stencil {
    Some(st) => {
      depth_stencil.set_stencilTestEnable((1 : UInt32))
      let f_st = vk_stencil_op_state(st.front, st.compare_mask, st.write_mask, st.reference)
      let b_st = vk_stencil_op_state(st.back, st.compare_mask, st.write_mask, st.reference)
      depth_stencil.set_front(f_st)
      depth_stencil.set_back(b_st)
      f_st.free()
      b_st.free()
      stencil_ref_opt = Some(st.reference)
    }
    None => ()
  }

  let color_vk_fmts : FixedArray[UInt32] = if desc.depth_only {
    FixedArray::make(0, (0 : UInt32))
  } else if desc.color_formats.length() > 0 {
    FixedArray::makei(desc.color_formats.length(), fn(i) {
      vk_texture_format_for(d, desc.color_formats[i])
    })
  } else {
    let single = match desc.color_format {
      Some(f) => vk_texture_format_for(d, f)
      None => default_color_vk_fmt
    }
    FixedArray::make(1, single)
  }
  let n_colors = color_vk_fmts.length()

  let effective_blend = match desc.blend_mode {
    Some(m) => m
    None => if desc.blend { BlendMode::Alpha } else { BlendMode::Opaque }
  }
  let blend_atts = @vk.VkPipelineColorBlendAttachmentState::array(n_colors)
  let mask = @vk.VK_COLOR_COMPONENT_R_BIT |
    @vk.VK_COLOR_COMPONENT_G_BIT |
    @vk.VK_COLOR_COMPONENT_B_BIT |
    @vk.VK_COLOR_COMPONENT_A_BIT
  for i = 0; i < n_colors; i = i + 1 {
    blend_atts.set_colorWriteMask_at(i, mask)
    match effective_blend {
      BlendMode::Opaque => ()
      BlendMode::Alpha => {
        blend_atts.set_blendEnable_at(i, (1 : UInt32))
        blend_atts.set_srcColorBlendFactor_at(i, @vk.VK_BLEND_FACTOR_SRC_ALPHA)
        blend_atts.set_dstColorBlendFactor_at(
          i,
          @vk.VK_BLEND_FACTOR_ONE_MINUS_SRC_ALPHA,
        )
        blend_atts.set_colorBlendOp_at(i, @vk.VK_BLEND_OP_ADD)
        blend_atts.set_srcAlphaBlendFactor_at(i, @vk.VK_BLEND_FACTOR_ONE)
        blend_atts.set_dstAlphaBlendFactor_at(
          i,
          @vk.VK_BLEND_FACTOR_ONE_MINUS_SRC_ALPHA,
        )
        blend_atts.set_alphaBlendOp_at(i, @vk.VK_BLEND_OP_ADD)
      }
      BlendMode::Additive => {
        blend_atts.set_blendEnable_at(i, (1 : UInt32))
        blend_atts.set_srcColorBlendFactor_at(i, @vk.VK_BLEND_FACTOR_SRC_ALPHA)
        blend_atts.set_dstColorBlendFactor_at(i, @vk.VK_BLEND_FACTOR_ONE)
        blend_atts.set_colorBlendOp_at(i, @vk.VK_BLEND_OP_ADD)
        blend_atts.set_srcAlphaBlendFactor_at(i, @vk.VK_BLEND_FACTOR_ONE)
        blend_atts.set_dstAlphaBlendFactor_at(i, @vk.VK_BLEND_FACTOR_ONE)
        blend_atts.set_alphaBlendOp_at(i, @vk.VK_BLEND_OP_ADD)
      }
      BlendMode::Premultiplied => {
        blend_atts.set_blendEnable_at(i, (1 : UInt32))
        blend_atts.set_srcColorBlendFactor_at(i, @vk.VK_BLEND_FACTOR_ONE)
        blend_atts.set_dstColorBlendFactor_at(
          i,
          @vk.VK_BLEND_FACTOR_ONE_MINUS_SRC_ALPHA,
        )
        blend_atts.set_colorBlendOp_at(i, @vk.VK_BLEND_OP_ADD)
        blend_atts.set_srcAlphaBlendFactor_at(i, @vk.VK_BLEND_FACTOR_ONE)
        blend_atts.set_dstAlphaBlendFactor_at(
          i,
          @vk.VK_BLEND_FACTOR_ONE_MINUS_SRC_ALPHA,
        )
        blend_atts.set_alphaBlendOp_at(i, @vk.VK_BLEND_OP_ADD)
      }
      BlendMode::Multiply => {
        blend_atts.set_blendEnable_at(i, (1 : UInt32))
        blend_atts.set_srcColorBlendFactor_at(i, @vk.VK_BLEND_FACTOR_DST_COLOR)
        blend_atts.set_dstColorBlendFactor_at(
          i,
          @vk.VK_BLEND_FACTOR_ONE_MINUS_SRC_ALPHA,
        )
        blend_atts.set_colorBlendOp_at(i, @vk.VK_BLEND_OP_ADD)
        blend_atts.set_srcAlphaBlendFactor_at(i, @vk.VK_BLEND_FACTOR_ONE)
        blend_atts.set_dstAlphaBlendFactor_at(
          i,
          @vk.VK_BLEND_FACTOR_ONE_MINUS_SRC_ALPHA,
        )
        blend_atts.set_alphaBlendOp_at(i, @vk.VK_BLEND_OP_ADD)
      }
    }
  }
  let color_blend = @vk.VkPipelineColorBlendStateCreateInfo::new()
  color_blend.set_attachmentCount(n_colors.reinterpret_as_uint())
  color_blend.set_pAttachments(blend_atts)

  let u_bindings = resolve_slot_bindings(
    desc.uniform_slots,
    desc.uniform_bindings,
    0,
  )
  let t_bindings = resolve_slot_bindings(
    desc.texture_slots,
    desc.texture_bindings,
    desc.uniform_slots,
  )
  let s_bindings = resolve_slot_bindings(
    desc.storage_slots,
    desc.storage_bindings,
    desc.uniform_slots + desc.texture_slots,
  )
  let si_bindings = resolve_slot_bindings(
    desc.storage_image_slots,
    desc.storage_image_bindings,
    desc.uniform_slots + desc.texture_slots + desc.storage_slots,
  )
  let a_bindings = resolve_slot_bindings(
    desc.accel_slots,
    desc.accel_bindings,
    desc.uniform_slots +
    desc.texture_slots +
    desc.storage_slots +
    desc.storage_image_slots,
  )

  let (set_layout, pools, frame_sets) = alloc_pipeline_descriptors(
    d,
    u_bindings,
    t_bindings,
    s_bindings,
    si_bindings,
    a_bindings,
    stage_flags,
  )

  let total_slots = desc.uniform_slots +
    desc.texture_slots +
    desc.storage_slots +
    desc.storage_image_slots +
    desc.accel_slots
  let plci = @vk.VkPipelineLayoutCreateInfo::new()
  match desc.bindless_heap {
    Some(heap) => {
      let sls = FixedArray::make(2, set_layout)
      sls[1] = heap.inner.set_layout
      plci.set_setLayoutCount((2 : UInt32))
      plci.set_pSetLayouts(sls)
    }
    None =>
      if total_slots > 0 {
        plci.set_setLayoutCount((1 : UInt32))
        plci.set_pSetLayouts(FixedArray::make(1, set_layout))
      }
  }
  let pcr = @vk.VkPushConstantRange::new()
  if desc.push_constant_size > 0 {
    pcr.set_stageFlags(stage_flags)
    pcr.set_offset((0 : UInt32))
    pcr.set_size(desc.push_constant_size.reinterpret_as_uint())
    plci.set_pushConstantRangeCount((1 : UInt32))
    plci.set_pPushConstantRanges(pcr)
  }
  let pl_out = FixedArray::make(1, @vk.VkPipelineLayout::null())
  let plr = (d.dfn.vkCreatePipelineLayout)(d.dev, plci, na, pl_out)
  plci.free()
  pcr.free()
  if plr != 0 {
    stages.free()
    attribs.free()
    vbindings.free()
    vertex_input.free()
    input_assembly.free()
    viewport_state.free()
    dyn_ci.free()
    rasterizer.free()
    multisample.free()
    depth_stencil.free()
    blend_atts.free()
    color_blend.free()
    for p in pools {
      (d.dfn.vkDestroyDescriptorPool)(d.dev, p, na)
    }
    (d.dfn.vkDestroyDescriptorSetLayout)(d.dev, set_layout, na)
    (d.dfn.vkDestroyShaderModule)(d.dev, vsm_out[0], na)
    (d.dfn.vkDestroyShaderModule)(d.dev, fsm_out[0], na)
    raise PipelineFailed("vkCreatePipelineLayout failed: \{plr}")
  }

  let prci = @vk.VkPipelineRenderingCreateInfo::new()
  prci.set_colorAttachmentCount(n_colors.reinterpret_as_uint())
  if n_colors > 0 {
    prci.set_pColorAttachmentFormats(color_vk_fmts)
  }
  match desc.depth_format {
    Some(f) => {
      let vk_df = vk_texture_format_for(d, f)
      prci.set_depthAttachmentFormat(vk_df)
      if f == TextureFormat::Depth24Stencil8 {
        prci.set_stencilAttachmentFormat(vk_df)
      }
    }
    None =>
      if desc.depth_test || desc.depth_write {
        prci.set_depthAttachmentFormat(@vk.VK_FORMAT_D32_SFLOAT)
      }
  }

  let gpci = @vk.VkGraphicsPipelineCreateInfo::new()
  gpci.set_pNext(prci.as_ptr())
  gpci.set_stageCount(stage_count.reinterpret_as_uint())
  gpci.set_pStages(stages)
  gpci.set_pVertexInputState(vertex_input)
  gpci.set_pInputAssemblyState(input_assembly)
  gpci.set_pViewportState(viewport_state)
  gpci.set_pRasterizationState(rasterizer)
  gpci.set_pMultisampleState(multisample)
  gpci.set_pDepthStencilState(depth_stencil)
  gpci.set_pColorBlendState(color_blend)
  gpci.set_pDynamicState(dyn_ci)
  gpci.set_layout(pl_out[0])

  let pipe_out = FixedArray::make(1, @vk.VkPipeline::null())
  let gpr = (d.dfn.vkCreateGraphicsPipelines)(
    d.dev,
    d.pipeline_cache,
    (1 : UInt32),
    gpci,
    na,
    pipe_out,
  )
  prci.free()
  gpci.free()
  stages.free()
  attribs.free()
  vbindings.free()
  vertex_input.free()
  input_assembly.free()
  viewport_state.free()
  dyn_ci.free()
  rasterizer.free()
  multisample.free()
  depth_stencil.free()
  blend_atts.free()
  color_blend.free()

  if gpr != 0 {
    (d.dfn.vkDestroyPipelineLayout)(d.dev, pl_out[0], na)
    for p in pools {
      (d.dfn.vkDestroyDescriptorPool)(d.dev, p, na)
    }
    (d.dfn.vkDestroyDescriptorSetLayout)(d.dev, set_layout, na)
    (d.dfn.vkDestroyShaderModule)(d.dev, vsm_out[0], na)
    (d.dfn.vkDestroyShaderModule)(d.dev, fsm_out[0], na)
    raise PipelineFailed("vkCreateGraphicsPipelines failed: \{gpr}")
  }

  {
    device: d,
    pipeline: pipe_out[0],
    layout: pl_out[0],
    set_layout,
    pools,
    frame_sets,
    last_gen: FixedArray::make(MAX_FRAMES, (0 : UInt64)),
    set_cursor: FixedArray::make(MAX_FRAMES, 0),
    slot_dirty: FixedArray::make(MAX_FRAMES, true),
    vert_module: vsm_out[0],
    frag_module: fsm_out[0],
    task_module: @vk.VkShaderModule::null(),
    stage_flags,
    uniform_slots: desc.uniform_slots,
    texture_slots: desc.texture_slots,
    storage_slots: desc.storage_slots,
    storage_image_slots: desc.storage_image_slots,
    accel_slots: desc.accel_slots,
    uniform_bindings: u_bindings,
    texture_bindings: t_bindings,
    storage_bindings: s_bindings,
    storage_image_bindings: si_bindings,
    accel_bindings: a_bindings,
    compute: false,
    stencil_ref: stencil_ref_opt,
    cur_uniforms: FixedArray::make(desc.uniform_slots, None),
    cur_textures: FixedArray::make(desc.texture_slots, None),
    cur_storage: FixedArray::make(desc.storage_slots, None),
    cur_storage_images: FixedArray::make(desc.storage_image_slots, None),
    cur_accel: FixedArray::make(desc.accel_slots, None),
  }
}

///|
fn vk_compute_pipeline_create(
  d : VkDeviceState,
  spv : FixedArray[UInt32],
  u_bindings : FixedArray[Int],
  t_bindings : FixedArray[Int],
  s_bindings : FixedArray[Int],
  si_bindings : FixedArray[Int],
  a_bindings : FixedArray[Int],
  push_constant_size : Int,
) -> VkPipelineState raise RhiError {
  if spv.length() == 0 {
    raise InvalidArgument("Compute pipeline requires non-empty SPIR-V shader")
  }
  let na = @vk.VkAllocationCallbacks::null()
  let smci = @vk.VkShaderModuleCreateInfo::new()
  smci.set_codeSize((spv.length() * 4).to_uint64())
  smci.set_pCode(spv)
  let sm_out = FixedArray::make(1, @vk.VkShaderModule::null())
  let sr = (d.dfn.vkCreateShaderModule)(d.dev, smci, na, sm_out)
  smci.free()
  if sr != 0 {
    raise PipelineFailed("Compute vkCreateShaderModule failed: \{sr}")
  }
  let stage = @vk.VkPipelineShaderStageCreateInfo::new()
  stage.set_stage(@vk.VK_SHADER_STAGE_COMPUTE_BIT)
  stage.set_module(sm_out[0])
  stage.set_pName(@vk.cstr("main"))

  let (set_layout, pools, frame_sets) = alloc_pipeline_descriptors(
    d,
    u_bindings,
    t_bindings,
    s_bindings,
    si_bindings,
    a_bindings,
    @vk.VK_SHADER_STAGE_COMPUTE_BIT,
  )
  let uniform_slots = u_bindings.length()
  let texture_slots = t_bindings.length()
  let storage_slots = s_bindings.length()
  let storage_image_slots = si_bindings.length()
  let accel_slots = a_bindings.length()
  let total_slots = uniform_slots +
    texture_slots +
    storage_slots +
    storage_image_slots +
    accel_slots
  let plci = @vk.VkPipelineLayoutCreateInfo::new()
  if total_slots > 0 {
    plci.set_setLayoutCount((1 : UInt32))
    plci.set_pSetLayouts(FixedArray::make(1, set_layout))
  }
  let pcr = @vk.VkPushConstantRange::new()
  if push_constant_size > 0 {
    pcr.set_stageFlags(@vk.VK_SHADER_STAGE_COMPUTE_BIT)
    pcr.set_offset((0 : UInt32))
    pcr.set_size(push_constant_size.reinterpret_as_uint())
    plci.set_pushConstantRangeCount((1 : UInt32))
    plci.set_pPushConstantRanges(pcr)
  }
  let pl_out = FixedArray::make(1, @vk.VkPipelineLayout::null())
  let plr = (d.dfn.vkCreatePipelineLayout)(d.dev, plci, na, pl_out)
  plci.free()
  pcr.free()
  if plr != 0 {
    stage.free()
    for p in pools {
      (d.dfn.vkDestroyDescriptorPool)(d.dev, p, na)
    }
    (d.dfn.vkDestroyDescriptorSetLayout)(d.dev, set_layout, na)
    (d.dfn.vkDestroyShaderModule)(d.dev, sm_out[0], na)
    raise PipelineFailed("Compute vkCreatePipelineLayout failed: \{plr}")
  }

  let cpci = @vk.VkComputePipelineCreateInfo::new()
  cpci.set_stage(stage)
  cpci.set_layout(pl_out[0])
  let pipe_out = FixedArray::make(1, @vk.VkPipeline::null())
  let cpr = (d.dfn.vkCreateComputePipelines)(
    d.dev,
    d.pipeline_cache,
    (1 : UInt32),
    cpci,
    na,
    pipe_out,
  )
  stage.free()
  cpci.free()
  if cpr != 0 {
    (d.dfn.vkDestroyPipelineLayout)(d.dev, pl_out[0], na)
    for p in pools {
      (d.dfn.vkDestroyDescriptorPool)(d.dev, p, na)
    }
    (d.dfn.vkDestroyDescriptorSetLayout)(d.dev, set_layout, na)
    (d.dfn.vkDestroyShaderModule)(d.dev, sm_out[0], na)
    raise PipelineFailed("vkCreateComputePipelines failed: \{cpr}")
  }

  {
    device: d,
    pipeline: pipe_out[0],
    layout: pl_out[0],
    set_layout,
    pools,
    frame_sets,
    last_gen: FixedArray::make(MAX_FRAMES, (0 : UInt64)),
    set_cursor: FixedArray::make(MAX_FRAMES, 0),
    slot_dirty: FixedArray::make(MAX_FRAMES, true),
    vert_module: sm_out[0],
    frag_module: @vk.VkShaderModule::null(),
    task_module: @vk.VkShaderModule::null(),
    stage_flags: @vk.VK_SHADER_STAGE_COMPUTE_BIT,
    uniform_slots,
    texture_slots,
    storage_slots,
    storage_image_slots,
    accel_slots,
    uniform_bindings: u_bindings,
    texture_bindings: t_bindings,
    storage_bindings: s_bindings,
    storage_image_bindings: si_bindings,
    accel_bindings: a_bindings,
    compute: true,
    stencil_ref: None,
    cur_uniforms: FixedArray::make(uniform_slots, None),
    cur_textures: FixedArray::make(texture_slots, None),
    cur_storage: FixedArray::make(storage_slots, None),
    cur_storage_images: FixedArray::make(storage_image_slots, None),
    cur_accel: FixedArray::make(accel_slots, None),
  }
}

///|
fn vk_pipeline_destroy(p : VkPipelineState) -> Unit {
  enqueue_delete(
    p.device,
    DeletePipeline(
      p.pipeline,
      p.layout,
      p.set_layout,
      p.pools,
      p.vert_module,
      p.frag_module,
      p.task_module,
    ),
  )
}

///|
fn write_descriptor_buffer(
  d : VkDeviceState,
  dset : @vk.VkDescriptorSet,
  binding : Int,
  desc_type : UInt32,
  buf : VkBufferState,
) -> Unit {
  let info = @vk.VkDescriptorBufferInfo::new()
  info.set_buffer(buf.buffer)
  info.set_offset((0 : UInt64))
  info.set_range(buf.size.to_uint64())
  let write = @vk.VkWriteDescriptorSet::new()
  write.set_dstSet(dset)
  write.set_dstBinding(binding.reinterpret_as_uint())
  write.set_dstArrayElement((0 : UInt32))
  write.set_descriptorCount((1 : UInt32))
  write.set_descriptorType(desc_type)
  write.set_pBufferInfo(info)
  (d.dfn.vkUpdateDescriptorSets)(
    d.dev,
    (1 : UInt32),
    write,
    (0 : UInt32),
    @vk.VkCopyDescriptorSet::null(),
  )
  info.free()
  write.free()
}

///|
fn write_descriptor_texture(
  d : VkDeviceState,
  dset : @vk.VkDescriptorSet,
  binding : Int,
  tex : VkTextureState,
  samp : VkSamplerState,
) -> Unit {
  let info = @vk.VkDescriptorImageInfo::new()
  info.set_sampler(samp.sampler)
  info.set_imageView(tex.view)
  info.set_imageLayout(@vk.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL)
  let write = @vk.VkWriteDescriptorSet::new()
  write.set_dstSet(dset)
  write.set_dstBinding(binding.reinterpret_as_uint())
  write.set_dstArrayElement((0 : UInt32))
  write.set_descriptorCount((1 : UInt32))
  write.set_descriptorType(@vk.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER)
  write.set_pImageInfo(info)
  (d.dfn.vkUpdateDescriptorSets)(
    d.dev,
    (1 : UInt32),
    write,
    (0 : UInt32),
    @vk.VkCopyDescriptorSet::null(),
  )
  info.free()
  write.free()
}

///|
fn write_descriptor_storage_image(
  d : VkDeviceState,
  dset : @vk.VkDescriptorSet,
  binding : Int,
  tex : VkTextureState,
) -> Unit {
  let info = @vk.VkDescriptorImageInfo::new()
  info.set_sampler(@vk.VkSampler::null())
  info.set_imageView(tex.view)
  info.set_imageLayout(@vk.VK_IMAGE_LAYOUT_GENERAL)
  let write = @vk.VkWriteDescriptorSet::new()
  write.set_dstSet(dset)
  write.set_dstBinding(binding.reinterpret_as_uint())
  write.set_dstArrayElement((0 : UInt32))
  write.set_descriptorCount((1 : UInt32))
  write.set_descriptorType(@vk.VK_DESCRIPTOR_TYPE_STORAGE_IMAGE)
  write.set_pImageInfo(info)
  (d.dfn.vkUpdateDescriptorSets)(
    d.dev,
    (1 : UInt32),
    write,
    (0 : UInt32),
    @vk.VkCopyDescriptorSet::null(),
  )
  info.free()
  write.free()
}

///|
fn write_descriptor_accel_struct(
  d : VkDeviceState,
  dset : @vk.VkDescriptorSet,
  binding : Int,
  accel : VkAccelStructState,
) -> Unit {
  let as_arr = FixedArray::make(1, accel.accel)
  let was = @vk.VkWriteDescriptorSetAccelerationStructureKHR::new()
  was.set_accelerationStructureCount((1 : UInt32))
  was.set_pAccelerationStructures(as_arr)
  let write = @vk.VkWriteDescriptorSet::new()
  write.set_pNext(was.as_ptr())
  write.set_dstSet(dset)
  write.set_dstBinding(binding.reinterpret_as_uint())
  write.set_dstArrayElement((0 : UInt32))
  write.set_descriptorCount((1 : UInt32))
  write.set_descriptorType(@vk.VK_DESCRIPTOR_TYPE_ACCELERATION_STRUCTURE_KHR)
  (d.dfn.vkUpdateDescriptorSets)(
    d.dev,
    (1 : UInt32),
    write,
    (0 : UInt32),
    @vk.VkCopyDescriptorSet::null(),
  )
  write.free()
  was.free()
}

///|
fn vk_cmd_flush_slots(c : VkCmdState) -> Unit {
  let f = c.frame_idx % MAX_FRAMES
  for entry in c.pending_uniforms {
    let (p, slot, buf) = entry
    let ps = p.inner
    if slot >= 0 && slot < ps.uniform_slots {
      let same = match ps.cur_uniforms[slot] {
        Some(prev) => prev.inner.buffer.as_ptr() == buf.inner.buffer.as_ptr()
        None => false
      }
      if !same {
        ps.cur_uniforms[slot] = Some(buf)
        ps.slot_dirty[f] = true
      }
    }
  }
  c.pending_uniforms.clear()
  for entry in c.pending_textures {
    let (p, slot, tex, samp) = entry
    let ps = p.inner
    if slot >= 0 && slot < ps.texture_slots {
      let same = match ps.cur_textures[slot] {
        Some((ptex, psamp)) =>
          ptex.inner.image.as_ptr() == tex.inner.image.as_ptr() &&
          psamp.inner.sampler.as_ptr() == samp.inner.sampler.as_ptr()
        None => false
      }
      if !same {
        ps.cur_textures[slot] = Some((tex, samp))
        ps.slot_dirty[f] = true
      }
    }
  }
  c.pending_textures.clear()
  for entry in c.pending_storage {
    let (p, slot, buf) = entry
    let ps = p.inner
    if slot >= 0 && slot < ps.storage_slots {
      let same = match ps.cur_storage[slot] {
        Some(prev) => prev.inner.buffer.as_ptr() == buf.inner.buffer.as_ptr()
        None => false
      }
      if !same {
        ps.cur_storage[slot] = Some(buf)
        ps.slot_dirty[f] = true
      }
    }
  }
  c.pending_storage.clear()
  for entry in c.pending_storage_images {
    let (p, slot, tex) = entry
    let ps = p.inner
    if slot >= 0 && slot < ps.storage_image_slots {
      let same = match ps.cur_storage_images[slot] {
        Some(ptex) => ptex.inner.image.as_ptr() == tex.inner.image.as_ptr()
        None => false
      }
      if !same {
        ps.cur_storage_images[slot] = Some(tex)
        ps.slot_dirty[f] = true
      }
    }
  }
  c.pending_storage_images.clear()
  for entry in c.pending_accel {
    let (p, slot, accel) = entry
    let ps = p.inner
    if slot >= 0 && slot < ps.accel_slots {
      let same = match ps.cur_accel[slot] {
        Some(pa) => pa.inner.accel.as_ptr() == accel.inner.accel.as_ptr()
        None => false
      }
      if !same {
        ps.cur_accel[slot] = Some(accel)
        ps.slot_dirty[f] = true
      }
    }
  }
  c.pending_accel.clear()

  match c.bound {
    Some(p) => {
      let ps = p.inner
      let total = ps.uniform_slots +
        ps.texture_slots +
        ps.storage_slots +
        ps.storage_image_slots +
        ps.accel_slots
      if total > 0 {
        if ps.last_gen[f] != c.frame_gen {
          ps.last_gen[f] = c.frame_gen
          ps.set_cursor[f] = 0
          ps.slot_dirty[f] = true
        }
        let dset = if ps.slot_dirty[f] || ps.set_cursor[f] == 0 {
          let cursor = ps.set_cursor[f]
          if cursor >= ps.frame_sets[f].length() {
            let (new_pool, chunk) = alloc_descriptor_pool_chunk(
              c.device,
              ps.set_layout,
              ps.uniform_slots,
              ps.texture_slots,
              ps.storage_slots,
              ps.storage_image_slots,
              ps.accel_slots,
              SETS_PER_FRAME,
            ) catch {
              _ => return
            }
            ps.pools.push(new_pool)
            for s in chunk {
              ps.frame_sets[f].push(s)
            }
          }
          let set_handle = ps.frame_sets[f][cursor]
          ps.set_cursor[f] = cursor + 1
          ps.slot_dirty[f] = false
          for i = 0; i < ps.uniform_slots; i = i + 1 {
            match ps.cur_uniforms[i] {
              Some(buf) =>
                write_descriptor_buffer(
                  c.device,
                  set_handle,
                  ps.uniform_bindings[i],
                  @vk.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER,
                  buf.inner,
                )
              None => ()
            }
          }
          for i = 0; i < ps.texture_slots; i = i + 1 {
            match ps.cur_textures[i] {
              Some((tex, samp)) =>
                write_descriptor_texture(
                  c.device,
                  set_handle,
                  ps.texture_bindings[i],
                  tex.inner,
                  samp.inner,
                )
              None => ()
            }
          }
          for i = 0; i < ps.storage_slots; i = i + 1 {
            match ps.cur_storage[i] {
              Some(buf) =>
                write_descriptor_buffer(
                  c.device,
                  set_handle,
                  ps.storage_bindings[i],
                  @vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER,
                  buf.inner,
                )
              None => ()
            }
          }
          for i = 0; i < ps.storage_image_slots; i = i + 1 {
            match ps.cur_storage_images[i] {
              Some(tex) =>
                write_descriptor_storage_image(
                  c.device,
                  set_handle,
                  ps.storage_image_bindings[i],
                  tex.inner,
                )
              None => ()
            }
          }
          for i = 0; i < ps.accel_slots; i = i + 1 {
            match ps.cur_accel[i] {
              Some(accel) =>
                write_descriptor_accel_struct(
                  c.device,
                  set_handle,
                  ps.accel_bindings[i],
                  accel.inner,
                )
              None => ()
            }
          }
          set_handle
        } else {
          ps.frame_sets[f][ps.set_cursor[f] - 1]
        }
        let point = if ps.compute {
          @vk.VK_PIPELINE_BIND_POINT_COMPUTE
        } else {
          @vk.VK_PIPELINE_BIND_POINT_GRAPHICS
        }
        let sets = FixedArray::make(1, dset)
        (c.device.dfn.vkCmdBindDescriptorSets)(
          c.cmd,
          point,
          ps.layout,
          (0 : UInt32),
          (1 : UInt32),
          sets,
          (0 : UInt32),
          FixedArray::make(0, (0 : UInt32)),
        )
      }
    }
    None => ()
  }
}

///|
fn vk_cmd_transition_for_compute(c : VkCmdState, tex : VkTextureState) -> Unit {
  if tex.layout == @vk.VK_IMAGE_LAYOUT_GENERAL {
    return
  }
  cmd_image_barrier2_mips(
    c.device,
    c.cmd,
    tex.image,
    @vk.VK_IMAGE_ASPECT_COLOR_BIT,
    0,
    tex.mip_levels,
    @vk.VK_PIPELINE_STAGE_2_ALL_COMMANDS_BIT,
    @vk.VK_ACCESS_2_SHADER_READ_BIT | @vk.VK_ACCESS_2_COLOR_ATTACHMENT_WRITE_BIT,
    @vk.VK_PIPELINE_STAGE_2_COMPUTE_SHADER_BIT,
    @vk.VK_ACCESS_2_SHADER_STORAGE_WRITE_BIT |
    @vk.VK_ACCESS_2_SHADER_STORAGE_READ_BIT,
    tex.layout,
    @vk.VK_IMAGE_LAYOUT_GENERAL,
  )
  tex.layout = @vk.VK_IMAGE_LAYOUT_GENERAL
}

///|
fn vk_cmd_transition_for_sampling(c : VkCmdState, tex : VkTextureState) -> Unit {
  if tex.layout == @vk.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL {
    return
  }
  cmd_image_barrier2_mips(
    c.device,
    c.cmd,
    tex.image,
    @vk.VK_IMAGE_ASPECT_COLOR_BIT,
    0,
    tex.mip_levels,
    @vk.VK_PIPELINE_STAGE_2_COMPUTE_SHADER_BIT |
    @vk.VK_PIPELINE_STAGE_2_COLOR_ATTACHMENT_OUTPUT_BIT |
    @vk.VK_PIPELINE_STAGE_2_ALL_TRANSFER_BIT,
    @vk.VK_ACCESS_2_SHADER_STORAGE_WRITE_BIT |
    @vk.VK_ACCESS_2_COLOR_ATTACHMENT_WRITE_BIT |
    @vk.VK_ACCESS_2_TRANSFER_WRITE_BIT,
    @vk.VK_PIPELINE_STAGE_2_FRAGMENT_SHADER_BIT |
    @vk.VK_PIPELINE_STAGE_2_COMPUTE_SHADER_BIT,
    @vk.VK_ACCESS_2_SHADER_READ_BIT,
    tex.layout,
    @vk.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
  )
  tex.layout = @vk.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL
}

///|
fn vk_timestamp_pool_create(
  d : VkDeviceState,
  count : Int,
) -> VkTimestampPoolState raise RhiError {
  if count <= 0 {
    raise InvalidArgument("TimestampPool count must be positive")
  }
  if !d.supports_timestamps {
    return { device: d, pool: @vk.VkQueryPool::null(), count }
  }
  let qpci = @vk.VkQueryPoolCreateInfo::new()
  qpci.set_queryType(@vk.VK_QUERY_TYPE_TIMESTAMP)
  qpci.set_queryCount(count.reinterpret_as_uint())
  let out = FixedArray::make(1, @vk.VkQueryPool::null())
  let r = (d.dfn.vkCreateQueryPool)(
    d.dev,
    qpci,
    @vk.VkAllocationCallbacks::null(),
    out,
  )
  qpci.free()
  if r != 0 {
    raise CommandFailed("vkCreateQueryPool failed: \{r}")
  }
  { device: d, pool: out[0], count }
}

///|
fn vk_timestamp_pool_resolve_ns(
  tp : VkTimestampPoolState,
) -> FixedArray[Double] raise RhiError {
  let d = tp.device
  let _ = (d.dfn.vkQueueWaitIdle)(d.queue)
  if !d.supports_timestamps || tp.pool.as_ptr() == (0 : UInt64) {
    return FixedArray::make(tp.count, 0.0)
  }
  let raw = FixedArray::make(tp.count, (0 : UInt64))
  let r = (d.dfn.vkGetQueryPoolResults)(
    d.dev,
    tp.pool,
    (0 : UInt32),
    tp.count.reinterpret_as_uint(),
    (tp.count * 8).to_uint64(),
    @vk.uint64_ptr(raw),
    (8 : UInt64),
    @vk.VK_QUERY_RESULT_64_BIT | @vk.VK_QUERY_RESULT_WAIT_BIT,
  )
  if r != 0 {
    raise CommandFailed("vkGetQueryPoolResults failed: \{r}")
  }
  let period = d.timestamp_period_ns.to_double()
  FixedArray::makei(tp.count, fn(i) { raw[i].to_double() * period })
}

///|
fn vk_timestamp_pool_destroy(tp : VkTimestampPoolState) -> Unit {
  if tp.pool.as_ptr() != (0 : UInt64) {
    enqueue_delete(tp.device, DeleteTimestampPool(tp.pool))
  }
}

///|
fn vk_cmd_begin_render_pass(
  c : VkCmdState,
  colors : Array[RenderTargetDesc],
  depth : DepthTargetDesc?,
) -> Unit raise RhiError {
  if colors.length() == 0 && depth is None {
    raise InvalidArgument("begin_render_pass requires at least one color or depth target")
  }
  let d = c.device
  for rt in colors {
    let ts = rt.texture.inner
    cmd_image_barrier2(
      d,
      c.cmd,
      ts.image,
      @vk.VK_IMAGE_ASPECT_COLOR_BIT,
      @vk.VK_PIPELINE_STAGE_2_ALL_COMMANDS_BIT,
      @vk.VK_ACCESS_2_SHADER_READ_BIT | @vk.VK_ACCESS_2_COLOR_ATTACHMENT_WRITE_BIT,
      @vk.VK_PIPELINE_STAGE_2_COLOR_ATTACHMENT_OUTPUT_BIT,
      @vk.VK_ACCESS_2_COLOR_ATTACHMENT_WRITE_BIT |
      @vk.VK_ACCESS_2_COLOR_ATTACHMENT_READ_BIT,
      ts.layout,
      @vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
    )
    ts.layout = @vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL
    match rt.resolve_texture {
      Some(rtex) => {
        let rts = rtex.inner
        cmd_image_barrier2(
          d,
          c.cmd,
          rts.image,
          @vk.VK_IMAGE_ASPECT_COLOR_BIT,
          @vk.VK_PIPELINE_STAGE_2_ALL_COMMANDS_BIT,
          @vk.VK_ACCESS_2_SHADER_READ_BIT |
          @vk.VK_ACCESS_2_COLOR_ATTACHMENT_WRITE_BIT,
          @vk.VK_PIPELINE_STAGE_2_COLOR_ATTACHMENT_OUTPUT_BIT,
          @vk.VK_ACCESS_2_COLOR_ATTACHMENT_WRITE_BIT,
          rts.layout,
          @vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
        )
        rts.layout = @vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL
      }
      None => ()
    }
  }
  match depth {
    Some(dt) => {
      let ds = dt.texture.inner
      cmd_image_barrier2(
        d,
        c.cmd,
        ds.image,
        ds.aspect,
        @vk.VK_PIPELINE_STAGE_2_ALL_COMMANDS_BIT,
        @vk.VK_ACCESS_2_DEPTH_STENCIL_ATTACHMENT_WRITE_BIT |
        @vk.VK_ACCESS_2_SHADER_READ_BIT,
        @vk.VK_PIPELINE_STAGE_2_EARLY_FRAGMENT_TESTS_BIT |
        @vk.VK_PIPELINE_STAGE_2_LATE_FRAGMENT_TESTS_BIT,
        @vk.VK_ACCESS_2_DEPTH_STENCIL_ATTACHMENT_READ_BIT |
        @vk.VK_ACCESS_2_DEPTH_STENCIL_ATTACHMENT_WRITE_BIT,
        ds.layout,
        @vk.VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL,
      )
      ds.layout = @vk.VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL
    }
    None => ()
  }

  let (w, h) = if colors.length() > 0 {
    (colors[0].texture.inner.width, colors[0].texture.inner.height)
  } else {
    match depth {
      Some(dt) => (dt.texture.inner.width, dt.texture.inner.height)
      None => (1, 1)
    }
  }
  let catts = @vk.VkRenderingAttachmentInfo::array(colors.length())
  let cv = @vk.VkClearValue::new()
  for i = 0; i < colors.length(); i = i + 1 {
    let rt = colors[i]
    cv.set_color_rgba(
      rt.clear_color.r,
      rt.clear_color.g,
      rt.clear_color.b,
      rt.clear_color.a,
    )
    catts.set_imageView_at(i, rt.texture.inner.view)
    catts.set_imageLayout_at(i, @vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL)
    catts.set_loadOp_at(i, vk_load_op(rt.load_op))
    catts.set_storeOp_at(i, vk_store_op(rt.store_op))
    catts.set_clearValue_at(i, cv)
    match rt.resolve_texture {
      Some(rtex) => {
        catts.set_resolveMode_at(i, @vk.VK_RESOLVE_MODE_AVERAGE_BIT)
        catts.set_resolveImageView_at(i, rtex.inner.view)
        catts.set_resolveImageLayout_at(
          i,
          @vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
        )
      }
      None => ()
    }
  }
  let ext = @vk.VkExtent2D::new()
  ext.set_width(w.reinterpret_as_uint())
  ext.set_height(h.reinterpret_as_uint())
  let area = @vk.VkRect2D::new()
  area.set_extent(ext)
  let ri = @vk.VkRenderingInfo::new()
  ri.set_renderArea(area)
  ri.set_layerCount((1 : UInt32))
  ri.set_colorAttachmentCount(colors.length().reinterpret_as_uint())
  if colors.length() > 0 {
    ri.set_pColorAttachments(catts)
  }
  let datt = @vk.VkRenderingAttachmentInfo::new()
  let satt = @vk.VkRenderingAttachmentInfo::new()
  match depth {
    Some(dt) => {
      cv.set_depth_stencil(dt.clear_depth, dt.clear_stencil.reinterpret_as_uint())
      datt.set_imageView(dt.texture.inner.attachment_view)
      datt.set_imageLayout(@vk.VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL)
      datt.set_loadOp(vk_load_op(dt.load_op))
      datt.set_storeOp(vk_store_op(dt.store_op))
      datt.set_clearValue(cv)
      ri.set_pDepthAttachment(datt)
      if dt.texture.inner.format == TextureFormat::Depth24Stencil8 {
        satt.set_imageView(dt.texture.inner.attachment_view)
        satt.set_imageLayout(@vk.VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL)
        satt.set_loadOp(vk_load_op(dt.stencil_load_op))
        satt.set_storeOp(vk_store_op(dt.stencil_store_op))
        satt.set_clearValue(cv)
        ri.set_pStencilAttachment(satt)
      }
    }
    None => ()
  }
  (d.dfn.vkCmdBeginRendering)(c.cmd, ri)
  ext.free()
  area.free()
  cv.free()
  catts.free()
  datt.free()
  satt.free()
  ri.free()
  set_dynamic_viewport_scissor(d, c.cmd, w, h)
  c.active_render_targets = colors
  c.active_depth_target = depth
}

///|
fn vk_cmd_end_render_pass(c : VkCmdState) -> Unit {
  let d = c.device
  (d.dfn.vkCmdEndRendering)(c.cmd)
  for rt in c.active_render_targets {
    let ts = rt.texture.inner
    if ts.samples == SampleCount::X1 {
      cmd_image_barrier2(
        d,
        c.cmd,
        ts.image,
        @vk.VK_IMAGE_ASPECT_COLOR_BIT,
        @vk.VK_PIPELINE_STAGE_2_COLOR_ATTACHMENT_OUTPUT_BIT,
        @vk.VK_ACCESS_2_COLOR_ATTACHMENT_WRITE_BIT,
        @vk.VK_PIPELINE_STAGE_2_FRAGMENT_SHADER_BIT |
        @vk.VK_PIPELINE_STAGE_2_COMPUTE_SHADER_BIT |
        @vk.VK_PIPELINE_STAGE_2_ALL_TRANSFER_BIT,
        @vk.VK_ACCESS_2_SHADER_READ_BIT | @vk.VK_ACCESS_2_TRANSFER_READ_BIT,
        @vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
        @vk.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
      )
      ts.layout = @vk.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL
    }
    match rt.resolve_texture {
      Some(rtex) => {
        let rts = rtex.inner
        cmd_image_barrier2(
          d,
          c.cmd,
          rts.image,
          @vk.VK_IMAGE_ASPECT_COLOR_BIT,
          @vk.VK_PIPELINE_STAGE_2_COLOR_ATTACHMENT_OUTPUT_BIT,
          @vk.VK_ACCESS_2_COLOR_ATTACHMENT_WRITE_BIT,
          @vk.VK_PIPELINE_STAGE_2_FRAGMENT_SHADER_BIT |
          @vk.VK_PIPELINE_STAGE_2_COMPUTE_SHADER_BIT |
          @vk.VK_PIPELINE_STAGE_2_ALL_TRANSFER_BIT,
          @vk.VK_ACCESS_2_SHADER_READ_BIT | @vk.VK_ACCESS_2_TRANSFER_READ_BIT,
          @vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
          @vk.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
        )
        rts.layout = @vk.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL
      }
      None => ()
    }
  }
  match c.active_depth_target {
    Some(dt) =>
      if dt.store_op == StoreOp::Store {
        let ds = dt.texture.inner
        cmd_image_barrier2(
          d,
          c.cmd,
          ds.image,
          ds.aspect,
          @vk.VK_PIPELINE_STAGE_2_EARLY_FRAGMENT_TESTS_BIT |
          @vk.VK_PIPELINE_STAGE_2_LATE_FRAGMENT_TESTS_BIT,
          @vk.VK_ACCESS_2_DEPTH_STENCIL_ATTACHMENT_WRITE_BIT,
          @vk.VK_PIPELINE_STAGE_2_FRAGMENT_SHADER_BIT |
          @vk.VK_PIPELINE_STAGE_2_COMPUTE_SHADER_BIT,
          @vk.VK_ACCESS_2_SHADER_READ_BIT,
          @vk.VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL,
          @vk.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
        )
        ds.layout = @vk.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL
      }
    None => ()
  }
  c.active_render_targets = []
  c.active_depth_target = None
}

///|
fn vk_cmd_blit_texture(
  c : VkCmdState,
  src : VkTextureState,
  dst : VkTextureState,
  filter : Filter,
) -> Unit {
  let d = c.device
  cmd_image_barrier2(
    d,
    c.cmd,
    src.image,
    src.aspect,
    @vk.VK_PIPELINE_STAGE_2_ALL_COMMANDS_BIT,
    @vk.VK_ACCESS_2_MEMORY_WRITE_BIT,
    @vk.VK_PIPELINE_STAGE_2_ALL_TRANSFER_BIT,
    @vk.VK_ACCESS_2_TRANSFER_READ_BIT,
    src.layout,
    @vk.VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,
  )
  cmd_image_barrier2(
    d,
    c.cmd,
    dst.image,
    dst.aspect,
    @vk.VK_PIPELINE_STAGE_2_ALL_COMMANDS_BIT,
    @vk.VK_ACCESS_2_SHADER_READ_BIT,
    @vk.VK_PIPELINE_STAGE_2_ALL_TRANSFER_BIT,
    @vk.VK_ACCESS_2_TRANSFER_WRITE_BIT,
    dst.layout,
    @vk.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
  )
  let src_sub = @vk.VkImageSubresourceLayers::new()
  src_sub.set_aspectMask(src.aspect)
  src_sub.set_layerCount((1 : UInt32))
  let dst_sub = @vk.VkImageSubresourceLayers::new()
  dst_sub.set_aspectMask(dst.aspect)
  dst_sub.set_layerCount((1 : UInt32))
  let blit = @vk.VkImageBlit::new()
  blit.set_srcSubresource(src_sub)
  blit.set_dstSubresource(dst_sub)
  blit.set_srcOffsets(blit_offsets_bytes(src.width, src.height))
  blit.set_dstOffsets(blit_offsets_bytes(dst.width, dst.height))
  (d.dfn.vkCmdBlitImage)(
    c.cmd,
    src.image,
    @vk.VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,
    dst.image,
    @vk.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
    (1 : UInt32),
    blit,
    vk_filter(filter),
  )
  src_sub.free()
  dst_sub.free()
  blit.free()
  let src_restore = if src.layout == @vk.VK_IMAGE_LAYOUT_UNDEFINED {
    @vk.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL
  } else {
    src.layout
  }
  cmd_image_barrier2(
    d,
    c.cmd,
    src.image,
    src.aspect,
    @vk.VK_PIPELINE_STAGE_2_ALL_TRANSFER_BIT,
    @vk.VK_ACCESS_2_TRANSFER_READ_BIT,
    @vk.VK_PIPELINE_STAGE_2_FRAGMENT_SHADER_BIT |
    @vk.VK_PIPELINE_STAGE_2_COMPUTE_SHADER_BIT,
    @vk.VK_ACCESS_2_SHADER_READ_BIT,
    @vk.VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,
    src_restore,
  )
  src.layout = src_restore
  cmd_image_barrier2(
    d,
    c.cmd,
    dst.image,
    dst.aspect,
    @vk.VK_PIPELINE_STAGE_2_ALL_TRANSFER_BIT,
    @vk.VK_ACCESS_2_TRANSFER_WRITE_BIT,
    @vk.VK_PIPELINE_STAGE_2_FRAGMENT_SHADER_BIT |
    @vk.VK_PIPELINE_STAGE_2_COMPUTE_SHADER_BIT,
    @vk.VK_ACCESS_2_SHADER_READ_BIT,
    @vk.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
    @vk.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
  )
  dst.layout = @vk.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL
}

///|
fn vk_cmd_blit_to_swapchain(
  c : VkCmdState,
  src : VkTextureState,
  sc : VkSwapchainState,
) -> Unit {
  let d = c.device
  let dst_img = sc.images[sc.image_index]
  cmd_image_barrier2(
    d,
    c.cmd,
    src.image,
    src.aspect,
    @vk.VK_PIPELINE_STAGE_2_ALL_COMMANDS_BIT,
    @vk.VK_ACCESS_2_MEMORY_WRITE_BIT,
    @vk.VK_PIPELINE_STAGE_2_ALL_TRANSFER_BIT,
    @vk.VK_ACCESS_2_TRANSFER_READ_BIT,
    src.layout,
    @vk.VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,
  )
  cmd_image_barrier2(
    d,
    c.cmd,
    dst_img,
    @vk.VK_IMAGE_ASPECT_COLOR_BIT,
    @vk.VK_PIPELINE_STAGE_2_COLOR_ATTACHMENT_OUTPUT_BIT,
    @vk.VK_ACCESS_2_NONE,
    @vk.VK_PIPELINE_STAGE_2_ALL_TRANSFER_BIT,
    @vk.VK_ACCESS_2_TRANSFER_WRITE_BIT,
    @vk.VK_IMAGE_LAYOUT_UNDEFINED,
    @vk.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
  )
  let src_sub = @vk.VkImageSubresourceLayers::new()
  src_sub.set_aspectMask(src.aspect)
  src_sub.set_layerCount((1 : UInt32))
  let dst_sub = @vk.VkImageSubresourceLayers::new()
  dst_sub.set_aspectMask(@vk.VK_IMAGE_ASPECT_COLOR_BIT)
  dst_sub.set_layerCount((1 : UInt32))
  let blit = @vk.VkImageBlit::new()
  blit.set_srcSubresource(src_sub)
  blit.set_dstSubresource(dst_sub)
  blit.set_srcOffsets(blit_offsets_bytes(src.width, src.height))
  blit.set_dstOffsets(blit_offsets_bytes(sc.width, sc.height))
  (d.dfn.vkCmdBlitImage)(
    c.cmd,
    src.image,
    @vk.VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,
    dst_img,
    @vk.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
    (1 : UInt32),
    blit,
    @vk.VK_FILTER_LINEAR,
  )
  src_sub.free()
  dst_sub.free()
  blit.free()
  let src_restore = if src.layout == @vk.VK_IMAGE_LAYOUT_UNDEFINED {
    @vk.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL
  } else {
    src.layout
  }
  cmd_image_barrier2(
    d,
    c.cmd,
    src.image,
    src.aspect,
    @vk.VK_PIPELINE_STAGE_2_ALL_TRANSFER_BIT,
    @vk.VK_ACCESS_2_TRANSFER_READ_BIT,
    @vk.VK_PIPELINE_STAGE_2_FRAGMENT_SHADER_BIT |
    @vk.VK_PIPELINE_STAGE_2_COMPUTE_SHADER_BIT,
    @vk.VK_ACCESS_2_SHADER_READ_BIT,
    @vk.VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,
    src_restore,
  )
  src.layout = src_restore
  cmd_image_barrier2(
    d,
    c.cmd,
    dst_img,
    @vk.VK_IMAGE_ASPECT_COLOR_BIT,
    @vk.VK_PIPELINE_STAGE_2_ALL_TRANSFER_BIT,
    @vk.VK_ACCESS_2_TRANSFER_WRITE_BIT,
    @vk.VK_PIPELINE_STAGE_2_COLOR_ATTACHMENT_OUTPUT_BIT,
    @vk.VK_ACCESS_2_COLOR_ATTACHMENT_WRITE_BIT,
    @vk.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
    @vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
  )
  c.swapchain_image_initialized = true
}

///|
fn vk_bindless_heap_create(
  d : VkDeviceState,
  capacity : Int,
) -> VkBindlessHeapState raise RhiError {
  if !d.caps.supports_bindless {
    raise DeviceFailed("Physical device does not support bindless descriptors")
  }
  if capacity <= 0 {
    raise InvalidArgument("BindlessHeap capacity must be positive")
  }
  let na = @vk.VkAllocationCallbacks::null()
  let binding = @vk.VkDescriptorSetLayoutBinding::new()
  binding.set_binding((0 : UInt32))
  binding.set_descriptorType(@vk.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER)
  binding.set_descriptorCount(capacity.reinterpret_as_uint())
  binding.set_stageFlags(
    @vk.VK_SHADER_STAGE_VERTEX_BIT |
    @vk.VK_SHADER_STAGE_FRAGMENT_BIT |
    @vk.VK_SHADER_STAGE_COMPUTE_BIT,
  )
  let bflags = FixedArray::make(
    1,
    @vk.VK_DESCRIPTOR_BINDING_PARTIALLY_BOUND_BIT |
    @vk.VK_DESCRIPTOR_BINDING_UPDATE_AFTER_BIND_BIT,
  )
  let bfci = @vk.VkDescriptorSetLayoutBindingFlagsCreateInfo::new()
  bfci.set_bindingCount((1 : UInt32))
  bfci.set_pBindingFlags(bflags)
  let dslci = @vk.VkDescriptorSetLayoutCreateInfo::new()
  dslci.set_pNext(bfci.as_ptr())
  dslci.set_flags(@vk.VK_DESCRIPTOR_SET_LAYOUT_CREATE_UPDATE_AFTER_BIND_POOL_BIT)
  dslci.set_bindingCount((1 : UInt32))
  dslci.set_pBindings(binding)
  let dsl_out = FixedArray::make(1, @vk.VkDescriptorSetLayout::null())
  let lr = (d.dfn.vkCreateDescriptorSetLayout)(d.dev, dslci, na, dsl_out)
  binding.free()
  bfci.free()
  dslci.free()
  if lr != 0 {
    raise PipelineFailed("Bindless vkCreateDescriptorSetLayout failed: \{lr}")
  }
  let set_layout = dsl_out[0]

  let psize = @vk.VkDescriptorPoolSize::new()
  psize.set_type(@vk.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER)
  psize.set_descriptorCount(capacity.reinterpret_as_uint())
  let dpci = @vk.VkDescriptorPoolCreateInfo::new()
  dpci.set_flags(@vk.VK_DESCRIPTOR_POOL_CREATE_UPDATE_AFTER_BIND_BIT)
  dpci.set_maxSets((1 : UInt32))
  dpci.set_poolSizeCount((1 : UInt32))
  dpci.set_pPoolSizes(psize)
  let pool_out = FixedArray::make(1, @vk.VkDescriptorPool::null())
  let pr = (d.dfn.vkCreateDescriptorPool)(d.dev, dpci, na, pool_out)
  psize.free()
  dpci.free()
  if pr != 0 {
    (d.dfn.vkDestroyDescriptorSetLayout)(d.dev, set_layout, na)
    raise PipelineFailed("Bindless vkCreateDescriptorPool failed: \{pr}")
  }
  let pool = pool_out[0]

  let layouts = FixedArray::make(1, set_layout)
  let dsai = @vk.VkDescriptorSetAllocateInfo::new()
  dsai.set_descriptorPool(pool)
  dsai.set_descriptorSetCount((1 : UInt32))
  dsai.set_pSetLayouts(layouts)
  let sets = FixedArray::make(1, @vk.VkDescriptorSet::null())
  let ar = (d.dfn.vkAllocateDescriptorSets)(d.dev, dsai, sets)
  dsai.free()
  if ar != 0 {
    (d.dfn.vkDestroyDescriptorPool)(d.dev, pool, na)
    (d.dfn.vkDestroyDescriptorSetLayout)(d.dev, set_layout, na)
    raise PipelineFailed("Bindless vkAllocateDescriptorSets failed: \{ar}")
  }
  {
    device: d,
    set_layout,
    pool,
    set: sets[0],
    capacity,
    next_idx: 0,
    free_indices: [],
  }
}

///|
fn vk_bindless_heap_register(
  h : VkBindlessHeapState,
  tex : VkTextureState,
  samp : VkSamplerState,
) -> Int raise RhiError {
  let idx = if h.free_indices.length() > 0 {
    h.free_indices.pop().unwrap()
  } else if h.next_idx < h.capacity {
    let i = h.next_idx
    h.next_idx = h.next_idx + 1
    i
  } else {
    raise AllocationFailed("BindlessHeap capacity (\{h.capacity}) exhausted")
  }
  let info = @vk.VkDescriptorImageInfo::new()
  info.set_sampler(samp.sampler)
  info.set_imageView(tex.view)
  info.set_imageLayout(@vk.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL)
  let write = @vk.VkWriteDescriptorSet::new()
  write.set_dstSet(h.set)
  write.set_dstBinding((0 : UInt32))
  write.set_dstArrayElement(idx.reinterpret_as_uint())
  write.set_descriptorCount((1 : UInt32))
  write.set_descriptorType(@vk.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER)
  write.set_pImageInfo(info)
  (h.device.dfn.vkUpdateDescriptorSets)(
    h.device.dev,
    (1 : UInt32),
    write,
    (0 : UInt32),
    @vk.VkCopyDescriptorSet::null(),
  )
  info.free()
  write.free()
  idx
}

///|
fn vk_bindless_heap_unregister(h : VkBindlessHeapState, idx : Int) -> Unit {
  if idx >= 0 && idx < h.next_idx {
    h.free_indices.push(idx)
  }
}

///|
fn vk_bindless_heap_destroy(h : VkBindlessHeapState) -> Unit {
  enqueue_delete(h.device, DeleteBindlessHeap(h.pool, h.set_layout))
}

///|
fn vk_mesh_pipeline_create(
  d : VkDeviceState,
  desc : MeshPipelineDesc,
  default_color_vk_fmt : UInt32,
) -> VkPipelineState raise RhiError {
  if !d.caps.supports_mesh_shader {
    raise DeviceFailed("Physical device does not support VK_EXT_mesh_shader")
  }
  if desc.mesh.length() == 0 || desc.frag.length() == 0 {
    raise InvalidArgument("Mesh pipeline requires non-empty mesh and frag SPIR-V")
  }
  let na = @vk.VkAllocationCallbacks::null()
  let msmci = @vk.VkShaderModuleCreateInfo::new()
  msmci.set_codeSize((desc.mesh.length() * 4).to_uint64())
  msmci.set_pCode(desc.mesh)
  let msm_out = FixedArray::make(1, @vk.VkShaderModule::null())
  let mr = (d.dfn.vkCreateShaderModule)(d.dev, msmci, na, msm_out)
  msmci.free()
  if mr != 0 {
    raise PipelineFailed("Mesh vkCreateShaderModule failed: \{mr}")
  }
  let fsmci = @vk.VkShaderModuleCreateInfo::new()
  fsmci.set_codeSize((desc.frag.length() * 4).to_uint64())
  fsmci.set_pCode(desc.frag)
  let fsm_out = FixedArray::make(1, @vk.VkShaderModule::null())
  let fr = (d.dfn.vkCreateShaderModule)(d.dev, fsmci, na, fsm_out)
  fsmci.free()
  if fr != 0 {
    (d.dfn.vkDestroyShaderModule)(d.dev, msm_out[0], na)
    raise PipelineFailed("Fragment vkCreateShaderModule failed: \{fr}")
  }
  let mut task_mod = @vk.VkShaderModule::null()
  let mut has_task = false
  match desc.task {
    Some(tspv) =>
      if tspv.length() > 0 {
        let tsmci = @vk.VkShaderModuleCreateInfo::new()
        tsmci.set_codeSize((tspv.length() * 4).to_uint64())
        tsmci.set_pCode(tspv)
        let tsm_out = FixedArray::make(1, @vk.VkShaderModule::null())
        let tr = (d.dfn.vkCreateShaderModule)(d.dev, tsmci, na, tsm_out)
        tsmci.free()
        if tr != 0 {
          (d.dfn.vkDestroyShaderModule)(d.dev, msm_out[0], na)
          (d.dfn.vkDestroyShaderModule)(d.dev, fsm_out[0], na)
          raise PipelineFailed("Task vkCreateShaderModule failed: \{tr}")
        }
        task_mod = tsm_out[0]
        has_task = true
      }
    None => ()
  }

  let stage_count = if has_task { 3 } else { 2 }
  let stages = @vk.VkPipelineShaderStageCreateInfo::array(stage_count)
  if has_task {
    stages.set_stage_at(0, @vk.VK_SHADER_STAGE_TASK_BIT_EXT)
    stages.set_module_at(0, task_mod)
    stages.set_pName_at(0, @vk.cstr(desc.task_entry))
    stages.set_stage_at(1, @vk.VK_SHADER_STAGE_MESH_BIT_EXT)
    stages.set_module_at(1, msm_out[0])
    stages.set_pName_at(1, @vk.cstr(desc.mesh_entry))
    stages.set_stage_at(2, @vk.VK_SHADER_STAGE_FRAGMENT_BIT)
    stages.set_module_at(2, fsm_out[0])
    stages.set_pName_at(2, @vk.cstr(desc.frag_entry))
  } else {
    stages.set_stage_at(0, @vk.VK_SHADER_STAGE_MESH_BIT_EXT)
    stages.set_module_at(0, msm_out[0])
    stages.set_pName_at(0, @vk.cstr(desc.mesh_entry))
    stages.set_stage_at(1, @vk.VK_SHADER_STAGE_FRAGMENT_BIT)
    stages.set_module_at(1, fsm_out[0])
    stages.set_pName_at(1, @vk.cstr(desc.frag_entry))
  }

  let stage_flags = @vk.VK_SHADER_STAGE_MESH_BIT_EXT |
    @vk.VK_SHADER_STAGE_FRAGMENT_BIT |
    (if has_task { @vk.VK_SHADER_STAGE_TASK_BIT_EXT } else { (0 : UInt32) })

  let viewport_state = @vk.VkPipelineViewportStateCreateInfo::new()
  viewport_state.set_viewportCount((1 : UInt32))
  viewport_state.set_scissorCount((1 : UInt32))
  let dyn_states = FixedArray::make(2, @vk.VK_DYNAMIC_STATE_VIEWPORT)
  dyn_states[1] = @vk.VK_DYNAMIC_STATE_SCISSOR
  let dyn_ci = @vk.VkPipelineDynamicStateCreateInfo::new()
  dyn_ci.set_dynamicStateCount((2 : UInt32))
  dyn_ci.set_pDynamicStates(dyn_states)
  let rasterizer = @vk.VkPipelineRasterizationStateCreateInfo::new()
  rasterizer.set_polygonMode(@vk.VK_POLYGON_MODE_FILL)
  rasterizer.set_cullMode(vk_cull(desc.cull_mode))
  rasterizer.set_frontFace(vk_front_face(desc.front_face))
  rasterizer.set_lineWidth((1.0 : Float))
  let multisample = @vk.VkPipelineMultisampleStateCreateInfo::new()
  multisample.set_rasterizationSamples(vk_samples(desc.samples))
  let depth_stencil = @vk.VkPipelineDepthStencilStateCreateInfo::new()
  depth_stencil.set_depthTestEnable(
    if desc.depth_test { (1 : UInt32) } else { (0 : UInt32) },
  )
  depth_stencil.set_depthWriteEnable(
    if desc.depth_write { (1 : UInt32) } else { (0 : UInt32) },
  )
  depth_stencil.set_depthCompareOp(vk_compare_op(desc.depth_compare))

  let color_vk_fmts : FixedArray[UInt32] = if desc.color_formats.length() > 0 {
    FixedArray::makei(desc.color_formats.length(), fn(i) {
      vk_texture_format_for(d, desc.color_formats[i])
    })
  } else {
    let single = match desc.color_format {
      Some(f) => vk_texture_format_for(d, f)
      None => default_color_vk_fmt
    }
    FixedArray::make(1, single)
  }
  let n_colors = color_vk_fmts.length()
  let effective_blend = match desc.blend_mode {
    Some(m) => m
    None => if desc.blend { BlendMode::Alpha } else { BlendMode::Opaque }
  }
  let blend_atts = @vk.VkPipelineColorBlendAttachmentState::array(n_colors)
  let mask = @vk.VK_COLOR_COMPONENT_R_BIT |
    @vk.VK_COLOR_COMPONENT_G_BIT |
    @vk.VK_COLOR_COMPONENT_B_BIT |
    @vk.VK_COLOR_COMPONENT_A_BIT
  for i = 0; i < n_colors; i = i + 1 {
    blend_atts.set_colorWriteMask_at(i, mask)
    match effective_blend {
      BlendMode::Opaque => ()
      BlendMode::Alpha => {
        blend_atts.set_blendEnable_at(i, (1 : UInt32))
        blend_atts.set_srcColorBlendFactor_at(i, @vk.VK_BLEND_FACTOR_SRC_ALPHA)
        blend_atts.set_dstColorBlendFactor_at(i, @vk.VK_BLEND_FACTOR_ONE_MINUS_SRC_ALPHA)
        blend_atts.set_colorBlendOp_at(i, @vk.VK_BLEND_OP_ADD)
        blend_atts.set_srcAlphaBlendFactor_at(i, @vk.VK_BLEND_FACTOR_ONE)
        blend_atts.set_dstAlphaBlendFactor_at(i, @vk.VK_BLEND_FACTOR_ONE_MINUS_SRC_ALPHA)
        blend_atts.set_alphaBlendOp_at(i, @vk.VK_BLEND_OP_ADD)
      }
      BlendMode::Additive => {
        blend_atts.set_blendEnable_at(i, (1 : UInt32))
        blend_atts.set_srcColorBlendFactor_at(i, @vk.VK_BLEND_FACTOR_SRC_ALPHA)
        blend_atts.set_dstColorBlendFactor_at(i, @vk.VK_BLEND_FACTOR_ONE)
        blend_atts.set_colorBlendOp_at(i, @vk.VK_BLEND_OP_ADD)
        blend_atts.set_srcAlphaBlendFactor_at(i, @vk.VK_BLEND_FACTOR_ONE)
        blend_atts.set_dstAlphaBlendFactor_at(i, @vk.VK_BLEND_FACTOR_ONE)
        blend_atts.set_alphaBlendOp_at(i, @vk.VK_BLEND_OP_ADD)
      }
      BlendMode::Premultiplied => {
        blend_atts.set_blendEnable_at(i, (1 : UInt32))
        blend_atts.set_srcColorBlendFactor_at(i, @vk.VK_BLEND_FACTOR_ONE)
        blend_atts.set_dstColorBlendFactor_at(i, @vk.VK_BLEND_FACTOR_ONE_MINUS_SRC_ALPHA)
        blend_atts.set_colorBlendOp_at(i, @vk.VK_BLEND_OP_ADD)
        blend_atts.set_srcAlphaBlendFactor_at(i, @vk.VK_BLEND_FACTOR_ONE)
        blend_atts.set_dstAlphaBlendFactor_at(i, @vk.VK_BLEND_FACTOR_ONE_MINUS_SRC_ALPHA)
        blend_atts.set_alphaBlendOp_at(i, @vk.VK_BLEND_OP_ADD)
      }
      BlendMode::Multiply => {
        blend_atts.set_blendEnable_at(i, (1 : UInt32))
        blend_atts.set_srcColorBlendFactor_at(i, @vk.VK_BLEND_FACTOR_DST_COLOR)
        blend_atts.set_dstColorBlendFactor_at(i, @vk.VK_BLEND_FACTOR_ONE_MINUS_SRC_ALPHA)
        blend_atts.set_colorBlendOp_at(i, @vk.VK_BLEND_OP_ADD)
        blend_atts.set_srcAlphaBlendFactor_at(i, @vk.VK_BLEND_FACTOR_ONE)
        blend_atts.set_dstAlphaBlendFactor_at(i, @vk.VK_BLEND_FACTOR_ONE_MINUS_SRC_ALPHA)
        blend_atts.set_alphaBlendOp_at(i, @vk.VK_BLEND_OP_ADD)
      }
    }
  }
  let color_blend = @vk.VkPipelineColorBlendStateCreateInfo::new()
  color_blend.set_attachmentCount(n_colors.reinterpret_as_uint())
  color_blend.set_pAttachments(blend_atts)

  let u_bindings = resolve_slot_bindings(desc.uniform_slots, desc.uniform_bindings, 0)
  let t_bindings = resolve_slot_bindings(desc.texture_slots, desc.texture_bindings, desc.uniform_slots)
  let s_bindings = resolve_slot_bindings(desc.storage_slots, desc.storage_bindings, desc.uniform_slots + desc.texture_slots)
  let si_bindings = resolve_slot_bindings(desc.storage_image_slots, desc.storage_image_bindings, desc.uniform_slots + desc.texture_slots + desc.storage_slots)
  let (set_layout, pools, frame_sets) = alloc_pipeline_descriptors(
    d, u_bindings, t_bindings, s_bindings, si_bindings, FixedArray::make(0, 0), stage_flags,
  )
  let total_slots = desc.uniform_slots + desc.texture_slots + desc.storage_slots + desc.storage_image_slots
  let plci = @vk.VkPipelineLayoutCreateInfo::new()
  match desc.bindless_heap {
    Some(heap) => {
      let sls = FixedArray::make(2, set_layout)
      sls[1] = heap.inner.set_layout
      plci.set_setLayoutCount((2 : UInt32))
      plci.set_pSetLayouts(sls)
    }
    None =>
      if total_slots > 0 {
        plci.set_setLayoutCount((1 : UInt32))
        plci.set_pSetLayouts(FixedArray::make(1, set_layout))
      }
  }
  let pcr = @vk.VkPushConstantRange::new()
  if desc.push_constant_size > 0 {
    pcr.set_stageFlags(stage_flags)
    pcr.set_offset((0 : UInt32))
    pcr.set_size(desc.push_constant_size.reinterpret_as_uint())
    plci.set_pushConstantRangeCount((1 : UInt32))
    plci.set_pPushConstantRanges(pcr)
  }
  let pl_out = FixedArray::make(1, @vk.VkPipelineLayout::null())
  let plr = (d.dfn.vkCreatePipelineLayout)(d.dev, plci, na, pl_out)
  plci.free()
  pcr.free()
  if plr != 0 {
    stages.free()
    viewport_state.free()
    dyn_ci.free()
    rasterizer.free()
    multisample.free()
    depth_stencil.free()
    blend_atts.free()
    color_blend.free()
    for p in pools {
      (d.dfn.vkDestroyDescriptorPool)(d.dev, p, na)
    }
    (d.dfn.vkDestroyDescriptorSetLayout)(d.dev, set_layout, na)
    (d.dfn.vkDestroyShaderModule)(d.dev, msm_out[0], na)
    (d.dfn.vkDestroyShaderModule)(d.dev, fsm_out[0], na)
    if has_task {
      (d.dfn.vkDestroyShaderModule)(d.dev, task_mod, na)
    }
    raise PipelineFailed("Mesh vkCreatePipelineLayout failed: \{plr}")
  }

  let prci = @vk.VkPipelineRenderingCreateInfo::new()
  prci.set_colorAttachmentCount(n_colors.reinterpret_as_uint())
  prci.set_pColorAttachmentFormats(color_vk_fmts)
  match desc.depth_format {
    Some(f) => {
      let vk_df = vk_texture_format_for(d, f)
      prci.set_depthAttachmentFormat(vk_df)
      if f == TextureFormat::Depth24Stencil8 {
        prci.set_stencilAttachmentFormat(vk_df)
      }
    }
    None =>
      if desc.depth_test || desc.depth_write {
        prci.set_depthAttachmentFormat(@vk.VK_FORMAT_D32_SFLOAT)
      }
  }
  let gpci = @vk.VkGraphicsPipelineCreateInfo::new()
  gpci.set_pNext(prci.as_ptr())
  gpci.set_stageCount(stage_count.reinterpret_as_uint())
  gpci.set_pStages(stages)
  gpci.set_pVertexInputState(@vk.VkPipelineVertexInputStateCreateInfo::null())
  gpci.set_pInputAssemblyState(@vk.VkPipelineInputAssemblyStateCreateInfo::null())
  gpci.set_pViewportState(viewport_state)
  gpci.set_pRasterizationState(rasterizer)
  gpci.set_pMultisampleState(multisample)
  gpci.set_pDepthStencilState(depth_stencil)
  gpci.set_pColorBlendState(color_blend)
  gpci.set_pDynamicState(dyn_ci)
  gpci.set_layout(pl_out[0])
  let pipe_out = FixedArray::make(1, @vk.VkPipeline::null())
  let gpr = (d.dfn.vkCreateGraphicsPipelines)(
    d.dev, d.pipeline_cache, (1 : UInt32), gpci, na, pipe_out,
  )
  prci.free()
  gpci.free()
  stages.free()
  viewport_state.free()
  dyn_ci.free()
  rasterizer.free()
  multisample.free()
  depth_stencil.free()
  blend_atts.free()
  color_blend.free()
  if gpr != 0 {
    (d.dfn.vkDestroyPipelineLayout)(d.dev, pl_out[0], na)
    for p in pools {
      (d.dfn.vkDestroyDescriptorPool)(d.dev, p, na)
    }
    (d.dfn.vkDestroyDescriptorSetLayout)(d.dev, set_layout, na)
    (d.dfn.vkDestroyShaderModule)(d.dev, msm_out[0], na)
    (d.dfn.vkDestroyShaderModule)(d.dev, fsm_out[0], na)
    if has_task {
      (d.dfn.vkDestroyShaderModule)(d.dev, task_mod, na)
    }
    raise PipelineFailed("Mesh vkCreateGraphicsPipelines failed: \{gpr}")
  }

  {
    device: d,
    pipeline: pipe_out[0],
    layout: pl_out[0],
    set_layout,
    pools,
    frame_sets,
    last_gen: FixedArray::make(MAX_FRAMES, (0 : UInt64)),
    set_cursor: FixedArray::make(MAX_FRAMES, 0),
    slot_dirty: FixedArray::make(MAX_FRAMES, true),
    vert_module: msm_out[0],
    frag_module: fsm_out[0],
    task_module: task_mod,
    stage_flags,
    uniform_slots: desc.uniform_slots,
    texture_slots: desc.texture_slots,
    storage_slots: desc.storage_slots,
    storage_image_slots: desc.storage_image_slots,
    accel_slots: 0,
    uniform_bindings: u_bindings,
    texture_bindings: t_bindings,
    storage_bindings: s_bindings,
    storage_image_bindings: si_bindings,
    accel_bindings: FixedArray::make(0, 0),
    compute: false,
    stencil_ref: None,
    cur_uniforms: FixedArray::make(desc.uniform_slots, None),
    cur_textures: FixedArray::make(desc.texture_slots, None),
    cur_storage: FixedArray::make(desc.storage_slots, None),
    cur_storage_images: FixedArray::make(desc.storage_image_slots, None),
    cur_accel: FixedArray::make(0, None),
  }
}

///|
fn vk_device_pipeline_cache_data(d : VkDeviceState) -> Bytes {
  if d.pipeline_cache.as_ptr() == (0 : UInt64) {
    return b""
  }
  let sz = FixedArray::make(1, (0 : UInt64))
  let r0 = (d.dfn.vkGetPipelineCacheData)(d.dev, d.pipeline_cache, sz, (0 : UInt64))
  if r0 != 0 || sz[0] == (0 : UInt64) {
    return b""
  }
  let n = sz[0].to_int()
  let out = FixedArray::make(n, (0 : Byte))
  let r1 = (d.dfn.vkGetPipelineCacheData)(
    d.dev,
    d.pipeline_cache,
    sz,
    @vk.byte_ptr(out),
  )
  if r1 != 0 {
    return b""
  }
  Bytes::from_array(out[:])
}

///|
fn vk_device_wait_idle(d : VkDeviceState) -> Unit {
  let _ = (d.dfn.vkDeviceWaitIdle)(d.dev)
  flush_deletes(d, true)
}

///|
fn vk_swapchain_color_format(s : VkSwapchainState) -> TextureFormat {
  if s.format == @vk.VK_FORMAT_B8G8R8A8_UNORM {
    TextureFormat::BGRA8
  } else {
    TextureFormat::RGBA8
  }
}

///|
fn vk_graphics_pipeline_create_default(
  d : VkDeviceState,
  desc : PipelineDesc,
) -> VkPipelineState raise RhiError {
  vk_graphics_pipeline_create(d, desc, @vk.VK_FORMAT_R8G8B8A8_UNORM)
}

///|
fn vk_mesh_pipeline_create_default(
  d : VkDeviceState,
  desc : MeshPipelineDesc,
) -> VkPipelineState raise RhiError {
  vk_mesh_pipeline_create(d, desc, @vk.VK_FORMAT_R8G8B8A8_UNORM)
}

///|
fn vk_buffer_upload_bytes(
  b : VkBufferState,
  data : Bytes,
  offset : Int,
) -> Unit raise RhiError {
  vk_buffer_upload_ptr(b, @vk.bytes_ptr(data), data.length(), offset~)
}

///|
fn vk_buffer_upload_floats(
  b : VkBufferState,
  data : FixedArray[Float],
  offset : Int,
) -> Unit raise RhiError {
  vk_buffer_upload_ptr(b, @vk.float_ptr(data), data.length() * 4, offset~)
}

///|
fn vk_buffer_upload_uint32(
  b : VkBufferState,
  data : FixedArray[UInt32],
  offset : Int,
) -> Unit raise RhiError {
  vk_buffer_upload_ptr(b, @vk.uint32_ptr(data), data.length() * 4, offset~)
}

///|
fn vk_texture_create_cubemap(
  d : VkDeviceState,
  size : Int,
  format : TextureFormat,
  total : Bytes,
) -> VkTextureState raise RhiError {
  vk_texture_create_layered(
    d,
    size,
    size,
    6,
    format,
    total,
    @vk.VK_IMAGE_CREATE_CUBE_COMPATIBLE_BIT,
    @vk.VK_IMAGE_VIEW_TYPE_CUBE,
  )
}

///|
fn vk_texture_create_2d_array(
  d : VkDeviceState,
  width : Int,
  height : Int,
  layers : Int,
  format : TextureFormat,
  pixels : Bytes,
) -> VkTextureState raise RhiError {
  vk_texture_create_layered(
    d,
    width,
    height,
    layers,
    format,
    pixels,
    (0 : UInt32),
    @vk.VK_IMAGE_VIEW_TYPE_2D_ARRAY,
  )
}

///|
fn vk_texture_create_render_target(
  d : VkDeviceState,
  width : Int,
  height : Int,
  format : TextureFormat,
  samples : SampleCount,
) -> VkTextureState raise RhiError {
  let usage = match samples {
    SampleCount::X1 =>
      @vk.VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT |
      @vk.VK_IMAGE_USAGE_SAMPLED_BIT |
      @vk.VK_IMAGE_USAGE_TRANSFER_SRC_BIT |
      @vk.VK_IMAGE_USAGE_TRANSFER_DST_BIT
    SampleCount::X4 => @vk.VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT
  }
  create_image_and_view(
    d,
    width,
    height,
    vk_texture_format_for(d, format),
    usage,
    @vk.VK_IMAGE_ASPECT_COLOR_BIT,
    samples,
    format,
  )
}

///|
fn vk_texture_create_depth_target(
  d : VkDeviceState,
  width : Int,
  height : Int,
  format : TextureFormat,
  samples : SampleCount,
) -> VkTextureState raise RhiError {
  let usage = @vk.VK_IMAGE_USAGE_DEPTH_STENCIL_ATTACHMENT_BIT |
    @vk.VK_IMAGE_USAGE_SAMPLED_BIT
  create_image_and_view(
    d,
    width,
    height,
    vk_texture_format_for(d, format),
    usage,
    depth_barrier_aspect(format),
    samples,
    format,
  )
}

///|
fn vk_sampler_create(
  d : VkDeviceState,
  desc : SamplerDesc,
) -> VkSamplerState raise RhiError {
  let ci = @vk.VkSamplerCreateInfo::new()
  ci.set_magFilter(vk_filter(desc.mag))
  ci.set_minFilter(vk_filter(desc.min))
  ci.set_addressModeU(vk_address(desc.address))
  ci.set_addressModeV(vk_address(desc.address))
  ci.set_addressModeW(vk_address(desc.address))
  ci.set_borderColor(vk_border_color(desc.border_color))
  if desc.anisotropy > (1.0 : Float) && d.caps.supports_anisotropy {
    let clamped = if desc.anisotropy > d.caps.max_sampler_anisotropy {
      d.caps.max_sampler_anisotropy
    } else {
      desc.anisotropy
    }
    ci.set_anisotropyEnable((1 : UInt32))
    ci.set_maxAnisotropy(clamped)
  } else {
    ci.set_anisotropyEnable((0 : UInt32))
    ci.set_maxAnisotropy((1.0 : Float))
  }
  ci.set_unnormalizedCoordinates((0 : UInt32))
  match desc.compare_op {
    Some(op) => {
      ci.set_compareEnable((1 : UInt32))
      ci.set_compareOp(vk_compare_op(op))
    }
    None => ci.set_compareEnable((0 : UInt32))
  }
  ci.set_mipmapMode(
    match desc.mipmap {
      Filter::Nearest => @vk.VK_SAMPLER_MIPMAP_MODE_NEAREST
      Filter::Linear => @vk.VK_SAMPLER_MIPMAP_MODE_LINEAR
    },
  )
  ci.set_mipLodBias(desc.mip_lod_bias)
  ci.set_minLod(desc.min_lod)
  ci.set_maxLod(desc.max_lod)
  let out = FixedArray::make(1, @vk.VkSampler::null())
  let r = (d.dfn.vkCreateSampler)(
    d.dev,
    ci,
    @vk.VkAllocationCallbacks::null(),
    out,
  )
  ci.free()
  if r != 0 {
    raise AllocationFailed("vkCreateSampler failed: \{r}")
  }
  { device: d, sampler: out[0] }
}

///|
fn vk_fence_create(
  d : VkDeviceState,
  signaled : Bool,
) -> VkFenceState raise RhiError {
  let ci = @vk.VkFenceCreateInfo::new()
  if signaled {
    ci.set_flags(@vk.VK_FENCE_CREATE_SIGNALED_BIT)
  }
  let out = FixedArray::make(1, @vk.VkFence::null())
  let r = (d.dfn.vkCreateFence)(d.dev, ci, @vk.VkAllocationCallbacks::null(), out)
  ci.free()
  if r != 0 {
    raise CommandFailed("vkCreateFence failed: \{r}")
  }
  { device: d, fence: out[0], submitted_gen: (0 : UInt64) }
}

///|
fn vk_fence_wait(f : VkFenceState) -> Unit {
  let arr = FixedArray::make(1, f.fence)
  let _ = (f.device.dfn.vkWaitForFences)(
    f.device.dev,
    (1 : UInt32),
    arr,
    (1 : UInt32),
    (0xFFFFFFFFFFFFFFFF : UInt64),
  )
  let d = f.device
  if f.submitted_gen > d.completed_gen {
    d.completed_gen = f.submitted_gen
  }
  flush_deletes(d, false)
}

///|
fn vk_fence_reset(f : VkFenceState) -> Unit {
  let arr = FixedArray::make(1, f.fence)
  let _ = (f.device.dfn.vkResetFences)(f.device.dev, (1 : UInt32), arr)
}

///|
fn vk_fence_destroy(f : VkFenceState) -> Unit {
  (f.device.dfn.vkDestroyFence)(
    f.device.dev,
    f.fence,
    @vk.VkAllocationCallbacks::null(),
  )
}

///|
fn vk_device_submit_commands(
  d : VkDeviceState,
  cmd : VkCmdState,
  fence : VkFenceState,
) -> Unit raise RhiError {
  let er = (d.dfn.vkEndCommandBuffer)(cmd.cmd)
  if d.active_recordings > 0 {
    d.active_recordings = d.active_recordings - 1
  }
  if er != 0 {
    raise CommandFailed("vkEndCommandBuffer failed: \{er}")
  }
  let cmd_si = @vk.VkCommandBufferSubmitInfo::new()
  cmd_si.set_commandBuffer(cmd.cmd)
  let si2 = @vk.VkSubmitInfo2::new()
  si2.set_commandBufferInfoCount((1 : UInt32))
  si2.set_pCommandBufferInfos(cmd_si)
  let sr = (d.dfn.vkQueueSubmit2)(d.queue, (1 : UInt32), si2, fence.fence)
  si2.free()
  cmd_si.free()
  if sr != 0 {
    raise CommandFailed("vkQueueSubmit2 failed: \{sr}")
  }
  fence.submitted_gen = d.current_gen
  d.current_gen = d.current_gen + (1 : UInt64)
}

///|
fn vk_cmd_bind_pipeline(c : VkCmdState, pipeline : Pipeline) -> Unit {
  let point = if pipeline.inner.compute {
    @vk.VK_PIPELINE_BIND_POINT_COMPUTE
  } else {
    @vk.VK_PIPELINE_BIND_POINT_GRAPHICS
  }
  (c.device.dfn.vkCmdBindPipeline)(c.cmd, point, pipeline.inner.pipeline)
  match pipeline.inner.stencil_ref {
    Some(r) =>
      (c.device.dfn.vkCmdSetStencilReference)(
        c.cmd,
        @vk.VK_STENCIL_FACE_FRONT_AND_BACK,
        r,
      )
    None => ()
  }
  c.bound = Some(pipeline)
}

///|
fn vk_cmd_reset_timestamps(c : VkCmdState, pool : VkTimestampPoolState) -> Unit {
  if !c.device.supports_timestamps || pool.pool.as_ptr() == (0 : UInt64) {
    return
  }
  (c.device.dfn.vkCmdResetQueryPool)(
    c.cmd,
    pool.pool,
    (0 : UInt32),
    pool.count.reinterpret_as_uint(),
  )
}

///|
fn vk_cmd_write_timestamp(
  c : VkCmdState,
  pool : VkTimestampPoolState,
  index : Int,
  at_start : Bool,
) -> Unit {
  if !c.device.supports_timestamps || pool.pool.as_ptr() == (0 : UInt64) {
    return
  }
  let stage = if at_start {
    @vk.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT
  } else {
    @vk.VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT
  }
  (c.device.dfn.vkCmdWriteTimestamp)(
    c.cmd,
    stage,
    pool.pool,
    index.reinterpret_as_uint(),
  )
}

///|
fn vk_cmd_bind_vertex(
  c : VkCmdState,
  slot : Int,
  buf : VkBufferState,
  offset : Int,
) -> Unit {
  let buffers = FixedArray::make(1, buf.buffer)
  let offsets = FixedArray::make(1, offset.to_uint64())
  (c.device.dfn.vkCmdBindVertexBuffers)(
    c.cmd,
    slot.reinterpret_as_uint(),
    (1 : UInt32),
    buffers,
    offsets,
  )
}

///|
fn vk_cmd_bind_index(
  c : VkCmdState,
  buf : VkBufferState,
  index_type : IndexType,
  offset : Int,
) -> Unit {
  let vk_ty = match index_type {
    IndexType::Uint16 => @vk.VK_INDEX_TYPE_UINT16
    IndexType::Uint32 => @vk.VK_INDEX_TYPE_UINT32
  }
  (c.device.dfn.vkCmdBindIndexBuffer)(c.cmd, buf.buffer, offset.to_uint64(), vk_ty)
}

///|
fn vk_cmd_push_constants_floats(
  c : VkCmdState,
  pipe : VkPipelineState,
  data : FixedArray[Float],
  offset : Int,
) -> Unit {
  (c.device.dfn.vkCmdPushConstants)(
    c.cmd,
    pipe.layout,
    pipe.stage_flags,
    offset.reinterpret_as_uint(),
    (data.length() * 4).reinterpret_as_uint(),
    @vk.float_ptr(data),
  )
}

///|
fn vk_cmd_push_constants_bytes(
  c : VkCmdState,
  pipe : VkPipelineState,
  data : Bytes,
  offset : Int,
) -> Unit {
  (c.device.dfn.vkCmdPushConstants)(
    c.cmd,
    pipe.layout,
    pipe.stage_flags,
    offset.reinterpret_as_uint(),
    data.length().reinterpret_as_uint(),
    @vk.bytes_ptr(data),
  )
}

///|
fn vk_cmd_set_viewport(
  c : VkCmdState,
  x : Float,
  y : Float,
  w : Float,
  h : Float,
) -> Unit {
  let vp = @vk.VkViewport::new()
  vp.set_x(x)
  vp.set_y(y)
  vp.set_width(w)
  vp.set_height(h)
  vp.set_minDepth((0.0 : Float))
  vp.set_maxDepth((1.0 : Float))
  (c.device.dfn.vkCmdSetViewport)(c.cmd, (0 : UInt32), (1 : UInt32), vp)
  vp.free()
}

///|
fn vk_cmd_set_scissor(
  c : VkCmdState,
  x : Int,
  y : Int,
  w : Int,
  h : Int,
) -> Unit {
  let off = @vk.VkOffset2D::new()
  off.set_x(x)
  off.set_y(y)
  let ext = @vk.VkExtent2D::new()
  ext.set_width(w.reinterpret_as_uint())
  ext.set_height(h.reinterpret_as_uint())
  let rect = @vk.VkRect2D::new()
  rect.set_offset(off)
  rect.set_extent(ext)
  (c.device.dfn.vkCmdSetScissor)(c.cmd, (0 : UInt32), (1 : UInt32), rect)
  off.free()
  ext.free()
  rect.free()
}

///|
fn vk_cmd_draw_instanced(
  c : VkCmdState,
  vertices : Int,
  instances : Int,
  first_vertex : Int,
  first_instance : Int,
) -> Unit {
  vk_cmd_flush_slots(c)
  (c.device.dfn.vkCmdDraw)(
    c.cmd,
    vertices.reinterpret_as_uint(),
    instances.reinterpret_as_uint(),
    first_vertex.reinterpret_as_uint(),
    first_instance.reinterpret_as_uint(),
  )
}

///|
fn vk_cmd_draw_indexed_full(
  c : VkCmdState,
  index_count : Int,
  instances : Int,
  first_index : Int,
  vertex_offset : Int,
  first_instance : Int,
) -> Unit {
  vk_cmd_flush_slots(c)
  (c.device.dfn.vkCmdDrawIndexed)(
    c.cmd,
    index_count.reinterpret_as_uint(),
    instances.reinterpret_as_uint(),
    first_index.reinterpret_as_uint(),
    vertex_offset,
    first_instance.reinterpret_as_uint(),
  )
}

///|
fn vk_cmd_dispatch(c : VkCmdState, x : Int, y : Int, z : Int) -> Unit {
  vk_cmd_flush_slots(c)
  (c.device.dfn.vkCmdDispatch)(
    c.cmd,
    x.reinterpret_as_uint(),
    y.reinterpret_as_uint(),
    z.reinterpret_as_uint(),
  )
}

///|
fn vk_cmd_draw_indirect(
  c : VkCmdState,
  buf : VkBufferState,
  draw_count : Int,
  offset : Int,
  stride : Int,
) -> Unit {
  vk_cmd_flush_slots(c)
  (c.device.dfn.vkCmdDrawIndirect)(
    c.cmd,
    buf.buffer,
    offset.to_uint64(),
    draw_count.reinterpret_as_uint(),
    stride.reinterpret_as_uint(),
  )
}

///|
fn vk_cmd_draw_indexed_indirect(
  c : VkCmdState,
  buf : VkBufferState,
  draw_count : Int,
  offset : Int,
  stride : Int,
) -> Unit {
  vk_cmd_flush_slots(c)
  (c.device.dfn.vkCmdDrawIndexedIndirect)(
    c.cmd,
    buf.buffer,
    offset.to_uint64(),
    draw_count.reinterpret_as_uint(),
    stride.reinterpret_as_uint(),
  )
}

///|
fn vk_cmd_dispatch_indirect(
  c : VkCmdState,
  buf : VkBufferState,
  offset : Int,
) -> Unit {
  vk_cmd_flush_slots(c)
  (c.device.dfn.vkCmdDispatchIndirect)(c.cmd, buf.buffer, offset.to_uint64())
}

///|
fn vk_cmd_draw_mesh_tasks(c : VkCmdState, x : Int, y : Int, z : Int) -> Unit {
  vk_cmd_flush_slots(c)
  (c.device.dfn.vkCmdDrawMeshTasksEXT)(
    c.cmd,
    x.reinterpret_as_uint(),
    y.reinterpret_as_uint(),
    z.reinterpret_as_uint(),
  )
}

///|
fn vk_cmd_draw_mesh_tasks_indirect(
  c : VkCmdState,
  buf : VkBufferState,
  draw_count : Int,
  offset : Int,
  stride : Int,
) -> Unit {
  vk_cmd_flush_slots(c)
  (c.device.dfn.vkCmdDrawMeshTasksIndirectEXT)(
    c.cmd,
    buf.buffer,
    offset.to_uint64(),
    draw_count.reinterpret_as_uint(),
    stride.reinterpret_as_uint(),
  )
}

///|
fn vk_cmd_bind_bindless_heap(
  c : VkCmdState,
  pipe : VkPipelineState,
  heap : VkBindlessHeapState,
  set_index : Int,
) -> Unit {
  let point = if pipe.compute {
    @vk.VK_PIPELINE_BIND_POINT_COMPUTE
  } else {
    @vk.VK_PIPELINE_BIND_POINT_GRAPHICS
  }
  let sets = FixedArray::make(1, heap.set)
  (c.device.dfn.vkCmdBindDescriptorSets)(
    c.cmd,
    point,
    pipe.layout,
    set_index.reinterpret_as_uint(),
    (1 : UInt32),
    sets,
    (0 : UInt32),
    FixedArray::make(0, (0 : UInt32)),
  )
}

///|
fn vk_cmd_copy_buffer(
  c : VkCmdState,
  src : VkBufferState,
  dst : VkBufferState,
  size : Int,
) -> Unit {
  let region = @vk.VkBufferCopy::new()
  region.set_srcOffset((0 : UInt64))
  region.set_dstOffset((0 : UInt64))
  region.set_size(size.to_uint64())
  (c.device.dfn.vkCmdCopyBuffer)(
    c.cmd,
    src.buffer,
    dst.buffer,
    (1 : UInt32),
    region,
  )
  region.free()
}

///|
fn vk_cmd_barrier(c : VkCmdState) -> Unit {
  let mb = @vk.VkMemoryBarrier2::new()
  mb.set_srcStageMask(
    @vk.VK_PIPELINE_STAGE_2_COMPUTE_SHADER_BIT |
    @vk.VK_PIPELINE_STAGE_2_COLOR_ATTACHMENT_OUTPUT_BIT,
  )
  mb.set_srcAccessMask(
    @vk.VK_ACCESS_2_SHADER_WRITE_BIT |
    @vk.VK_ACCESS_2_COLOR_ATTACHMENT_WRITE_BIT,
  )
  mb.set_dstStageMask(
    @vk.VK_PIPELINE_STAGE_2_ALL_TRANSFER_BIT |
    @vk.VK_PIPELINE_STAGE_2_DRAW_INDIRECT_BIT |
    @vk.VK_PIPELINE_STAGE_2_VERTEX_SHADER_BIT |
    @vk.VK_PIPELINE_STAGE_2_FRAGMENT_SHADER_BIT |
    @vk.VK_PIPELINE_STAGE_2_COMPUTE_SHADER_BIT,
  )
  mb.set_dstAccessMask(
    @vk.VK_ACCESS_2_TRANSFER_READ_BIT |
    @vk.VK_ACCESS_2_INDIRECT_COMMAND_READ_BIT |
    @vk.VK_ACCESS_2_SHADER_READ_BIT |
    @vk.VK_ACCESS_2_UNIFORM_READ_BIT,
  )
  let dep = @vk.VkDependencyInfo::new()
  dep.set_memoryBarrierCount((1 : UInt32))
  dep.set_pMemoryBarriers(mb)
  (c.device.dfn.vkCmdPipelineBarrier2)(c.cmd, dep)
  dep.free()
  mb.free()
}

///|
fn vk_stencil_op(op : StencilOp) -> UInt32 {
  match op {
    StencilOp::Keep => @vk.VK_STENCIL_OP_KEEP
    StencilOp::Zero => @vk.VK_STENCIL_OP_ZERO
    StencilOp::Replace => @vk.VK_STENCIL_OP_REPLACE
    StencilOp::IncrementAndClamp => @vk.VK_STENCIL_OP_INCREMENT_AND_CLAMP
    StencilOp::DecrementAndClamp => @vk.VK_STENCIL_OP_DECREMENT_AND_CLAMP
    StencilOp::Invert => @vk.VK_STENCIL_OP_INVERT
    StencilOp::IncrementAndWrap => @vk.VK_STENCIL_OP_INCREMENT_AND_WRAP
    StencilOp::DecrementAndWrap => @vk.VK_STENCIL_OP_DECREMENT_AND_WRAP
  }
}

///|
fn vk_stencil_op_state(
  face : StencilFaceState,
  compare_mask : UInt32,
  write_mask : UInt32,
  reference : UInt32,
) -> @vk.VkStencilOpState {
  let st = @vk.VkStencilOpState::new()
  st.set_failOp(vk_stencil_op(face.fail_op))
  st.set_passOp(vk_stencil_op(face.pass_op))
  st.set_depthFailOp(vk_stencil_op(face.depth_fail_op))
  st.set_compareOp(vk_compare_op(face.compare_op))
  st.set_compareMask(compare_mask)
  st.set_writeMask(write_mask)
  st.set_reference(reference)
  st
}

///|
fn vk_cmd_set_stencil_reference(c : VkCmdState, reference : Int) -> Unit {
  (c.device.dfn.vkCmdSetStencilReference)(
    c.cmd,
    @vk.VK_STENCIL_FACE_FRONT_AND_BACK,
    reference.reinterpret_as_uint(),
  )
}

///|
fn vk_cmd_draw_indirect_count(
  c : VkCmdState,
  buf : VkBufferState,
  count_buf : VkBufferState,
  max_draw_count : Int,
  offset : Int,
  count_offset : Int,
  stride : Int,
) -> Unit {
  vk_cmd_flush_slots(c)
  (c.device.dfn.vkCmdDrawIndirectCount)(
    c.cmd,
    buf.buffer,
    offset.to_uint64(),
    count_buf.buffer,
    count_offset.to_uint64(),
    max_draw_count.reinterpret_as_uint(),
    stride.reinterpret_as_uint(),
  )
}

///|
fn vk_cmd_draw_indexed_indirect_count(
  c : VkCmdState,
  buf : VkBufferState,
  count_buf : VkBufferState,
  max_draw_count : Int,
  offset : Int,
  count_offset : Int,
  stride : Int,
) -> Unit {
  vk_cmd_flush_slots(c)
  (c.device.dfn.vkCmdDrawIndexedIndirectCount)(
    c.cmd,
    buf.buffer,
    offset.to_uint64(),
    count_buf.buffer,
    count_offset.to_uint64(),
    max_draw_count.reinterpret_as_uint(),
    stride.reinterpret_as_uint(),
  )
}

///|
fn vk_buffer_device_address(d : VkDeviceState, buf : @vk.VkBuffer) -> UInt64 {
  let info = @vk.VkBufferDeviceAddressInfo::new()
  info.set_buffer(buf)
  let addr = (d.dfn.vkGetBufferDeviceAddress)(d.dev, info)
  info.free()
  addr
}

///|
fn vk_alloc_raw_buffer(
  d : VkDeviceState,
  size : UInt64,
  usage : UInt32,
  host_visible : Bool,
) -> (@vk.VkBuffer, MemAlloc) raise RhiError {
  let na = @vk.VkAllocationCallbacks::null()
  let bci = @vk.VkBufferCreateInfo::new()
  bci.set_size(if size == (0 : UInt64) { (64 : UInt64) } else { size })
  bci.set_usage(usage)
  bci.set_sharingMode(@vk.VK_SHARING_MODE_EXCLUSIVE)
  let buf_out = FixedArray::make(1, @vk.VkBuffer::null())
  let br = (d.dfn.vkCreateBuffer)(d.dev, bci, na, buf_out)
  bci.free()
  if br != 0 {
    raise AllocationFailed("vkCreateBuffer (AS) failed: \{br}")
  }
  let buffer = buf_out[0]
  let req = @vk.VkMemoryRequirements::new()
  (d.dfn.vkGetBufferMemoryRequirements)(d.dev, buffer, req)
  let flags = if host_visible {
    @vk.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT |
    @vk.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT
  } else {
    @vk.VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT
  }
  let alloc = d.alloc.alloc(req, flags, host_visible, false)
  req.free()
  let bir = (d.dfn.vkBindBufferMemory)(d.dev, buffer, alloc.memory, alloc.offset)
  if bir != 0 {
    d.alloc.free(alloc)
    (d.dfn.vkDestroyBuffer)(d.dev, buffer, na)
    raise AllocationFailed("vkBindBufferMemory (AS) failed: \{bir}")
  }
  (buffer, alloc)
}

///|
fn floats_to_bytes_le(floats : FixedArray[Float], count : Int) -> Bytes {
  let arr : Array[Byte] = []
  for i = 0; i < count; i = i + 1 {
    let f = if i < floats.length() { floats[i] } else { (0.0 : Float) }
    let bits = f.reinterpret_as_int()
    arr.push((bits & 0xFF).to_byte())
    arr.push(((bits >> 8) & 0xFF).to_byte())
    arr.push(((bits >> 16) & 0xFF).to_byte())
    arr.push(((bits >> 24) & 0xFF).to_byte())
  }
  Bytes::from_array(arr)
}

///|
fn vk_create_blas(
  d : VkDeviceState,
  geometries : Array[RayGeometryDesc],
) -> VkAccelStructState raise RhiError {
  if !d.caps.supports_ray_query {
    raise DeviceFailed("VK_KHR_ray_query / VK_KHR_acceleration_structure not supported")
  }
  if geometries.length() == 0 {
    raise InvalidArgument("create_blas requires at least one geometry")
  }
  let na = @vk.VkAllocationCallbacks::null()
  let n = geometries.length()
  let vk_geos = @vk.VkAccelerationStructureGeometryKHR::array(n)
  let prim_counts = FixedArray::make(n, (0 : UInt32))
  let tris_keep : Array[@vk.VkAccelerationStructureGeometryTrianglesDataKHR] = []
  let gdatas_keep : Array[@vk.VkAccelerationStructureGeometryDataKHR] = []
  let addrs_keep : Array[@vk.VkDeviceOrHostAddressConstKHR] = []
  for i = 0; i < n; i = i + 1 {
    let g = geometries[i]
    let vaddr = vk_buffer_device_address(d, g.vertex_buffer.inner.buffer)
    let vdev = @vk.VkDeviceOrHostAddressConstKHR::new()
    vdev.set_deviceAddress(vaddr)
    addrs_keep.push(vdev)
    let tri = @vk.VkAccelerationStructureGeometryTrianglesDataKHR::new()
    tri.set_vertexFormat(@vk.VK_FORMAT_R32G32B32_SFLOAT)
    tri.set_vertexData(vdev)
    tri.set_vertexStride(g.vertex_stride.to_uint64())
    tri.set_maxVertex(
      (if g.vertex_count > 0 { g.vertex_count - 1 } else { 0 }).reinterpret_as_uint(),
    )
    let prim_cnt = match g.index_buffer {
      Some(ib) => {
        let iaddr = vk_buffer_device_address(d, ib.inner.buffer)
        let idev = @vk.VkDeviceOrHostAddressConstKHR::new()
        idev.set_deviceAddress(iaddr)
        addrs_keep.push(idev)
        tri.set_indexType(
          match g.index_type {
            IndexType::Uint16 => @vk.VK_INDEX_TYPE_UINT16
            IndexType::Uint32 => @vk.VK_INDEX_TYPE_UINT32
          },
        )
        tri.set_indexData(idev)
        g.index_count / 3
      }
      None => {
        tri.set_indexType(@vk.VK_INDEX_TYPE_NONE_KHR)
        g.vertex_count / 3
      }
    }
    prim_counts[i] = prim_cnt.reinterpret_as_uint()
    tris_keep.push(tri)
    let gdata = @vk.VkAccelerationStructureGeometryDataKHR::new()
    gdata.set_triangles(tri)
    gdatas_keep.push(gdata)
    vk_geos.set_geometryType_at(i, @vk.VK_GEOMETRY_TYPE_TRIANGLES_KHR)
    vk_geos.set_flags_at(
      i,
      if g.is_opaque { @vk.VK_GEOMETRY_OPAQUE_BIT_KHR } else { (0 : UInt32) },
    )
    vk_geos.set_geometry_at(i, gdata)
  }

  let binfo = @vk.VkAccelerationStructureBuildGeometryInfoKHR::new()
  binfo.set_type(@vk.VK_ACCELERATION_STRUCTURE_TYPE_BOTTOM_LEVEL_KHR)
  binfo.set_flags(@vk.VK_BUILD_ACCELERATION_STRUCTURE_PREFER_FAST_TRACE_BIT_KHR)
  binfo.set_mode(@vk.VK_BUILD_ACCELERATION_STRUCTURE_MODE_BUILD_KHR)
  binfo.set_geometryCount(n.reinterpret_as_uint())
  binfo.set_pGeometries(vk_geos)
  let sizes = @vk.VkAccelerationStructureBuildSizesInfoKHR::new()
  (d.dfn.vkGetAccelerationStructureBuildSizesKHR)(
    d.dev,
    @vk.VK_ACCELERATION_STRUCTURE_BUILD_TYPE_DEVICE_KHR,
    binfo,
    prim_counts,
    sizes,
  )
  let as_size = sizes.get_accelerationStructureSize()
  let scratch_size = sizes.get_buildScratchSize()
  sizes.free()

  let (as_buf, as_alloc) = vk_alloc_raw_buffer(
    d,
    as_size,
    @vk.VK_BUFFER_USAGE_ACCELERATION_STRUCTURE_STORAGE_BIT_KHR |
    @vk.VK_BUFFER_USAGE_SHADER_DEVICE_ADDRESS_BIT,
    false,
  )
  let asci = @vk.VkAccelerationStructureCreateInfoKHR::new()
  asci.set_buffer(as_buf)
  asci.set_size(as_size)
  asci.set_type(@vk.VK_ACCELERATION_STRUCTURE_TYPE_BOTTOM_LEVEL_KHR)
  let as_out = FixedArray::make(1, @vk.VkAccelerationStructureKHR::null())
  let acr = (d.dfn.vkCreateAccelerationStructureKHR)(d.dev, asci, na, as_out)
  asci.free()
  if acr != 0 {
    (d.dfn.vkDestroyBuffer)(d.dev, as_buf, na)
    d.alloc.free(as_alloc)
    binfo.free()
    vk_geos.free()
    for t in tris_keep { t.free() }
    for gd in gdatas_keep { gd.free() }
    for a in addrs_keep { a.free() }
    raise AllocationFailed("vkCreateAccelerationStructureKHR (BLAS) failed: \{acr}")
  }
  let blas = as_out[0]

  let (scratch_buf, scratch_alloc) = vk_alloc_raw_buffer(
    d,
    scratch_size,
    @vk.VK_BUFFER_USAGE_STORAGE_BUFFER_BIT |
    @vk.VK_BUFFER_USAGE_SHADER_DEVICE_ADDRESS_BIT,
    false,
  )
  let scratch_dev = @vk.VkDeviceOrHostAddressKHR::new()
  scratch_dev.set_deviceAddress(vk_buffer_device_address(d, scratch_buf))
  binfo.set_dstAccelerationStructure(blas)
  binfo.set_scratchData(scratch_dev)

  let ranges_keep : Array[@vk.VkAccelerationStructureBuildRangeInfoKHR] = []
  let range_ptrs = FixedArray::make(n, (0 : UInt64))
  for i = 0; i < n; i = i + 1 {
    let ri = @vk.VkAccelerationStructureBuildRangeInfoKHR::new()
    ri.set_primitiveCount(prim_counts[i])
    ranges_keep.push(ri)
    range_ptrs[i] = ri.as_ptr()
  }

  let cmd = begin_one_time(d)
  (d.dfn.vkCmdBuildAccelerationStructuresKHR)(
    cmd,
    (1 : UInt32),
    binfo,
    range_ptrs,
  )
  end_one_time(d, cmd)

  (d.dfn.vkDestroyBuffer)(d.dev, scratch_buf, na)
  d.alloc.free(scratch_alloc)
  scratch_dev.free()
  binfo.free()
  vk_geos.free()
  for ri in ranges_keep { ri.free() }
  for t in tris_keep { t.free() }
  for gd in gdatas_keep { gd.free() }
  for a in addrs_keep { a.free() }

  let addr_i = @vk.VkAccelerationStructureDeviceAddressInfoKHR::new()
  addr_i.set_accelerationStructure(blas)
  let device_address = (d.dfn.vkGetAccelerationStructureDeviceAddressKHR)(
    d.dev, addr_i,
  )
  addr_i.free()
  { device: d, accel: blas, buffer: as_buf, alloc: as_alloc, device_address }
}

///|
fn vk_create_tlas(
  d : VkDeviceState,
  instances : Array[RayInstanceDesc],
) -> VkAccelStructState raise RhiError {
  if !d.caps.supports_ray_query {
    raise DeviceFailed("VK_KHR_ray_query / VK_KHR_acceleration_structure not supported")
  }
  if instances.length() == 0 {
    raise InvalidArgument("create_tlas requires at least one instance")
  }
  let na = @vk.VkAllocationCallbacks::null()
  let n = instances.length()
  let inst_bytes = (n * 64).to_uint64()
  let insts = @vk.rt_instance_array(n)
  for i = 0; i < n; i = i + 1 {
    let inst = instances[i]
    let xform = @vk.VkTransformMatrixKHR::new()
    xform.set_matrix(floats_to_bytes_le(inst.transform, 12))
    @vk.rt_instance_set(
      insts,
      i,
      xform,
      inst.custom_index.reinterpret_as_uint(),
      inst.mask.reinterpret_as_uint(),
      (0 : UInt32),
      @vk.VK_GEOMETRY_INSTANCE_TRIANGLE_FACING_CULL_DISABLE_BIT_KHR,
      inst.blas.inner.device_address,
    )
    xform.free()
  }
  let (inst_buf, inst_alloc) = vk_alloc_raw_buffer(
    d,
    inst_bytes,
    @vk.VK_BUFFER_USAGE_ACCELERATION_STRUCTURE_BUILD_INPUT_READ_ONLY_BIT_KHR |
    @vk.VK_BUFFER_USAGE_SHADER_DEVICE_ADDRESS_BIT,
    true,
  )
  @vk.memcpy_ptr(inst_alloc.mapped, insts, n * 64)
  @vk.free_ptr(insts)

  let inst_dev = @vk.VkDeviceOrHostAddressConstKHR::new()
  inst_dev.set_deviceAddress(vk_buffer_device_address(d, inst_buf))
  let tgeo = @vk.VkAccelerationStructureGeometryInstancesDataKHR::new()
  tgeo.set_data(inst_dev)
  let tdata = @vk.VkAccelerationStructureGeometryDataKHR::new()
  tdata.set_instances(tgeo)
  let tgeoi = @vk.VkAccelerationStructureGeometryKHR::new()
  tgeoi.set_geometryType(@vk.VK_GEOMETRY_TYPE_INSTANCES_KHR)
  tgeoi.set_geometry(tdata)

  let tinfo = @vk.VkAccelerationStructureBuildGeometryInfoKHR::new()
  tinfo.set_type(@vk.VK_ACCELERATION_STRUCTURE_TYPE_TOP_LEVEL_KHR)
  tinfo.set_flags(@vk.VK_BUILD_ACCELERATION_STRUCTURE_PREFER_FAST_TRACE_BIT_KHR)
  tinfo.set_mode(@vk.VK_BUILD_ACCELERATION_STRUCTURE_MODE_BUILD_KHR)
  tinfo.set_geometryCount((1 : UInt32))
  tinfo.set_pGeometries(tgeoi)
  let prim_cnt = FixedArray::make(1, n.reinterpret_as_uint())
  let tsizes = @vk.VkAccelerationStructureBuildSizesInfoKHR::new()
  (d.dfn.vkGetAccelerationStructureBuildSizesKHR)(
    d.dev,
    @vk.VK_ACCELERATION_STRUCTURE_BUILD_TYPE_DEVICE_KHR,
    tinfo,
    prim_cnt,
    tsizes,
  )
  let as_size = tsizes.get_accelerationStructureSize()
  let scratch_size = tsizes.get_buildScratchSize()
  tsizes.free()

  let (as_buf, as_alloc) = vk_alloc_raw_buffer(
    d,
    as_size,
    @vk.VK_BUFFER_USAGE_ACCELERATION_STRUCTURE_STORAGE_BIT_KHR |
    @vk.VK_BUFFER_USAGE_SHADER_DEVICE_ADDRESS_BIT,
    false,
  )
  let tci = @vk.VkAccelerationStructureCreateInfoKHR::new()
  tci.set_buffer(as_buf)
  tci.set_size(as_size)
  tci.set_type(@vk.VK_ACCELERATION_STRUCTURE_TYPE_TOP_LEVEL_KHR)
  let tlas_out = FixedArray::make(1, @vk.VkAccelerationStructureKHR::null())
  let tcr = (d.dfn.vkCreateAccelerationStructureKHR)(d.dev, tci, na, tlas_out)
  tci.free()
  if tcr != 0 {
    (d.dfn.vkDestroyBuffer)(d.dev, as_buf, na)
    d.alloc.free(as_alloc)
    (d.dfn.vkDestroyBuffer)(d.dev, inst_buf, na)
    d.alloc.free(inst_alloc)
    tinfo.free()
    tgeoi.free()
    tdata.free()
    tgeo.free()
    inst_dev.free()
    raise AllocationFailed("vkCreateAccelerationStructureKHR (TLAS) failed: \{tcr}")
  }
  let tlas = tlas_out[0]

  let (scratch_buf, scratch_alloc) = vk_alloc_raw_buffer(
    d,
    scratch_size,
    @vk.VK_BUFFER_USAGE_STORAGE_BUFFER_BIT |
    @vk.VK_BUFFER_USAGE_SHADER_DEVICE_ADDRESS_BIT,
    false,
  )
  let scratch_dev = @vk.VkDeviceOrHostAddressKHR::new()
  scratch_dev.set_deviceAddress(vk_buffer_device_address(d, scratch_buf))
  tinfo.set_dstAccelerationStructure(tlas)
  tinfo.set_scratchData(scratch_dev)
  let trange = @vk.VkAccelerationStructureBuildRangeInfoKHR::new()
  trange.set_primitiveCount(n.reinterpret_as_uint())
  let tranges = FixedArray::make(1, trange.as_ptr())

  let cmd = begin_one_time(d)
  (d.dfn.vkCmdBuildAccelerationStructuresKHR)(cmd, (1 : UInt32), tinfo, tranges)
  end_one_time(d, cmd)

  (d.dfn.vkDestroyBuffer)(d.dev, scratch_buf, na)
  d.alloc.free(scratch_alloc)
  (d.dfn.vkDestroyBuffer)(d.dev, inst_buf, na)
  d.alloc.free(inst_alloc)
  scratch_dev.free()
  trange.free()
  tinfo.free()
  tgeoi.free()
  tdata.free()
  tgeo.free()
  inst_dev.free()

  let addr_i = @vk.VkAccelerationStructureDeviceAddressInfoKHR::new()
  addr_i.set_accelerationStructure(tlas)
  let device_address = (d.dfn.vkGetAccelerationStructureDeviceAddressKHR)(
    d.dev, addr_i,
  )
  addr_i.free()
  { device: d, accel: tlas, buffer: as_buf, alloc: as_alloc, device_address }
}

///|
fn vk_accel_struct_destroy(a : VkAccelStructState) -> Unit {
  enqueue_delete(
    a.device,
    DeleteAccelStruct(a.accel, a.buffer, a.alloc),
  )
}
