// Tycho RHI — Vulkan 1.3 backend implementation (pure MoonBit via @vk / @win).
// Uses Dynamic Rendering, Synchronization2, 2 frames-in-flight, automatic
// swapchain resize recreation, and the pure-MoonBit SubAllocator.

const MAX_FRAMES : Int = 2

const SETS_PER_FRAME : Int = 16

const MAX_PIPELINE_SETS : Int = 32

let g_rhi_validation_errors : Ref[Int] = Ref(0)

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
  alloc : SubAllocator
  messenger : @vk.VkDebugUtilsMessengerEXT
  error_baseline : Int
  timestamp_period_ns : Float
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
  mut depth_image : @vk.VkImage
  mut depth_view : @vk.VkImageView
  mut depth_mem : MemAlloc?
  pool : @vk.VkCommandPool
  cmds : FixedArray[@vk.VkCommandBuffer]
  image_available : FixedArray[@vk.VkSemaphore]
  in_flight : FixedArray[@vk.VkFence]
  readback_bufs : FixedArray[VkBufferState]
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
  descriptor_pool : @vk.VkDescriptorPool
  sets : FixedArray[@vk.VkDescriptorSet]
  last_gen : FixedArray[UInt64]
  set_cursor : FixedArray[Int]
  vert_module : @vk.VkShaderModule
  frag_module : @vk.VkShaderModule
  uniform_slots : Int
  texture_slots : Int
  storage_slots : Int
  storage_image_slots : Int
  uniform_bindings : FixedArray[Int]
  texture_bindings : FixedArray[Int]
  storage_bindings : FixedArray[Int]
  storage_image_bindings : FixedArray[Int]
  compute : Bool
  cur_uniforms : FixedArray[Buffer?]
  cur_textures : FixedArray[(Texture, Sampler)?]
  cur_storage : FixedArray[Buffer?]
  cur_storage_images : FixedArray[Texture?]
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
  format : TextureFormat
  samples : SampleCount
  width : Int
  height : Int
  mip_levels : Int
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
}

///|
priv struct VkTimestampPoolState {
  device : VkDeviceState
  pool : @vk.VkQueryPool
  count : Int
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
  mut bound : Pipeline?
  mut active_render_targets : Array[RenderTargetDesc]
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
    TextureFormat::RGBA32F => @vk.VK_FORMAT_R32G32B32A32_SFLOAT
    TextureFormat::Depth32F => @vk.VK_FORMAT_D32_SFLOAT
  }
}

///|
fn texture_format_bytes(f : TextureFormat) -> Int {
  match f {
    TextureFormat::RGBA8 => 4
    TextureFormat::BGRA8 => 4
    TextureFormat::RGBA32F => 16
    TextureFormat::Depth32F => 4
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
fn vk_device_create(
  app_name : String,
  validation : Bool,
) -> VkDeviceState raise RhiError {
  let na = @vk.VkAllocationCallbacks::null()
  let app = @vk.VkApplicationInfo::new()
  app.set_pApplicationName(@vk.cstr(app_name))
  app.set_apiVersion((4206592 : UInt32)) // VK_MAKE_API_VERSION(0, 1, 3, 0)
  let se = @win.surface_extensions()
  let ext_arr : Array[String] = []
  for i = 0; i < se.length(); i = i + 1 {
    ext_arr.push(se[i])
  }
  let use_debug = validation && has_instance_extension("VK_EXT_debug_utils")
  if use_debug {
    ext_arr.push("VK_EXT_debug_utils")
  }
  let exts = FixedArray::makei(ext_arr.length(), fn(i) { ext_arr[i] })
  let ici = @vk.VkInstanceCreateInfo::new()
  ici.set_pApplicationInfo(app)
  ici.set_enabledExtensionCount(exts.length().reinterpret_as_uint())
  ici.set_ppEnabledExtensionNames(@vk.cstr_array(exts))
  if validation && has_instance_layer("VK_LAYER_KHRONOS_validation") {
    ici.set_enabledLayerCount((1 : UInt32))
    ici.set_ppEnabledLayerNames(@vk.cstr_array(["VK_LAYER_KHRONOS_validation"]))
  }
  match @win.platform() {
    @win.Platform::MacOS =>
      ici.set_flags(@vk.VK_INSTANCE_CREATE_ENUMERATE_PORTABILITY_BIT_KHR)
    _ => ()
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
  for pi = 0; pi < pcount; pi = pi + 1 {
    let pd = pdevs[pi]
    let pprops = @vk.VkPhysicalDeviceProperties::new()
    (ifn.vkGetPhysicalDeviceProperties)(pd, pprops)
    let discrete = pprops.get_deviceType() ==
      @vk.VK_PHYSICAL_DEVICE_TYPE_DISCRETE_GPU
    let ts_period = pprops.get_limits().get_timestampPeriod()
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

  let f13q = @vk.VkPhysicalDeviceVulkan13Features::new()
  let f2 = @vk.VkPhysicalDeviceFeatures2::new()
  f2.set_pNext(f13q.as_ptr())
  (ifn.vkGetPhysicalDeviceFeatures2)(chosen_phys, f2)
  let has_dyn = f13q.get_dynamicRendering()
  let has_sync2 = f13q.get_synchronization2()
  f2.free()
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

  let priority = FixedArray::make(1, (1.0 : Float))
  let qci = @vk.VkDeviceQueueCreateInfo::new()
  qci.set_queueFamilyIndex(chosen_qf)
  qci.set_queueCount((1 : UInt32))
  qci.set_pQueuePriorities(priority)
  let f13 = @vk.VkPhysicalDeviceVulkan13Features::new()
  f13.set_dynamicRendering((1 : UInt32))
  f13.set_synchronization2((1 : UInt32))
  let dci = @vk.VkDeviceCreateInfo::new()
  dci.set_pNext(f13.as_ptr())
  dci.set_queueCreateInfoCount((1 : UInt32))
  dci.set_pQueueCreateInfos(qci)
  dci.set_enabledExtensionCount((1 : UInt32))
  dci.set_ppEnabledExtensionNames(@vk.cstr_array(["VK_KHR_swapchain"]))
  let dev_out = FixedArray::make(1, @vk.VkDevice::null())
  let dr = (ifn.vkCreateDevice)(chosen_phys, dci, na, dev_out)
  dci.free()
  f13.free()
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
  let alloc = SubAllocator::new(dev, dfn, ifn, chosen_phys)
  {
    inst,
    ifn,
    phys: chosen_phys,
    dev,
    dfn,
    queue,
    queue_family: chosen_qf,
    pool: pool_out[0],
    alloc,
    messenger,
    error_baseline,
    timestamp_period_ns,
  }
}

///|
fn vk_device_destroy(d : VkDeviceState) -> Unit {
  let na = @vk.VkAllocationCallbacks::null()
  let _ = (d.dfn.vkDeviceWaitIdle)(d.dev)
  d.alloc.destroy()
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
) -> Unit {
  let range = @vk.VkImageSubresourceRange::new()
  range.set_aspectMask(aspect)
  range.set_baseMipLevel(base_mip.reinterpret_as_uint())
  range.set_levelCount(mip_count.reinterpret_as_uint())
  range.set_layerCount((1 : UInt32))
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
) -> VkBufferState raise RhiError {
  if size <= 0 {
    raise InvalidArgument("Buffer size must be positive (got \{size})")
  }
  let na = @vk.VkAllocationCallbacks::null()
  let usage = match kind {
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
  let flags = @vk.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT |
    @vk.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT
  let alloc = d.alloc.alloc(req, flags, true, false)
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
) -> Unit raise RhiError {
  if byte_len > b.size {
    raise InvalidArgument(
      "Upload size \{byte_len} exceeds buffer capacity \{b.size}",
    )
  }
  if byte_len > 0 {
    @vk.memcpy_ptr(b.alloc.mapped, src_ptr, byte_len)
  }
}

///|
fn vk_buffer_destroy(b : VkBufferState) -> Unit {
  let _ = (b.device.dfn.vkDeviceWaitIdle)(b.device.dev)
  (b.device.dfn.vkDestroyBuffer)(
    b.device.dev,
    b.buffer,
    @vk.VkAllocationCallbacks::null(),
  )
  b.device.alloc.free(b.alloc)
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
) -> VkTextureState raise RhiError {
  if width <= 0 || height <= 0 {
    raise InvalidArgument("Texture dimensions must be positive")
  }
  let levels = if mip_levels < 1 { 1 } else { mip_levels }
  let na = @vk.VkAllocationCallbacks::null()
  let extent = @vk.VkExtent3D::new()
  extent.set_width(width.reinterpret_as_uint())
  extent.set_height(height.reinterpret_as_uint())
  extent.set_depth((1 : UInt32))
  let ici = @vk.VkImageCreateInfo::new()
  ici.set_imageType(@vk.VK_IMAGE_TYPE_2D)
  ici.set_format(vk_format)
  ici.set_extent(extent)
  ici.set_mipLevels(levels.reinterpret_as_uint())
  ici.set_arrayLayers((1 : UInt32))
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
  let range = @vk.VkImageSubresourceRange::new()
  range.set_aspectMask(aspect)
  range.set_baseMipLevel((0 : UInt32))
  range.set_levelCount(levels.reinterpret_as_uint())
  range.set_layerCount((1 : UInt32))
  let ivci = @vk.VkImageViewCreateInfo::new()
  ivci.set_image(image)
  ivci.set_viewType(@vk.VK_IMAGE_VIEW_TYPE_2D)
  ivci.set_format(vk_format)
  ivci.set_subresourceRange(range)
  let view_out = FixedArray::make(1, @vk.VkImageView::null())
  let vr = (d.dfn.vkCreateImageView)(d.dev, ivci, na, view_out)
  range.free()
  ivci.free()
  if vr != 0 {
    (d.dfn.vkDestroyImage)(d.dev, image, na)
    d.alloc.free(alloc)
    raise AllocationFailed("vkCreateImageView failed with code \{vr}")
  }
  {
    device: d,
    image,
    alloc,
    view: view_out[0],
    format,
    samples,
    width,
    height,
    mip_levels: levels,
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
  if format == TextureFormat::Depth32F {
    raise InvalidArgument(
      "Use create_depth_texture for Depth32F textures",
    )
  }
  let expected_bytes = width * height * texture_format_bytes(format)
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
    vk_texture_format(format),
    @vk.VK_IMAGE_USAGE_TRANSFER_DST_BIT |
    @vk.VK_IMAGE_USAGE_TRANSFER_SRC_BIT |
    @vk.VK_IMAGE_USAGE_SAMPLED_BIT,
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
  cmd_image_barrier2(
    d,
    cmd,
    tex.image,
    @vk.VK_IMAGE_ASPECT_COLOR_BIT,
    @vk.VK_PIPELINE_STAGE_2_ALL_TRANSFER_BIT,
    @vk.VK_ACCESS_2_TRANSFER_WRITE_BIT,
    @vk.VK_PIPELINE_STAGE_2_FRAGMENT_SHADER_BIT |
    @vk.VK_PIPELINE_STAGE_2_COMPUTE_SHADER_BIT,
    @vk.VK_ACCESS_2_SHADER_READ_BIT,
    @vk.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
    @vk.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
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
    vk_texture_format(format),
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
    vk_texture_format(format),
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
  let _ = (t.device.dfn.vkDeviceWaitIdle)(t.device.dev)
  let na = @vk.VkAllocationCallbacks::null()
  (t.device.dfn.vkDestroyImageView)(t.device.dev, t.view, na)
  (t.device.dfn.vkDestroyImage)(t.device.dev, t.image, na)
  t.device.alloc.free(t.alloc)
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
fn build_swapchain_resources(
  d : VkDeviceState,
  surface : @vk.VkSurfaceKHR,
  window : UInt64,
  req_w : Int,
  req_h : Int,
  old_swapchain : @vk.VkSwapchainKHR,
  has_depth : Bool,
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
  swci.set_imageUsage(
    @vk.VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT | @vk.VK_IMAGE_USAGE_TRANSFER_SRC_BIT,
  )
  swci.set_imageSharingMode(@vk.VK_SHARING_MODE_EXCLUSIVE)
  swci.set_preTransform(caps.get_currentTransform())
  swci.set_compositeAlpha(@vk.VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR)
  swci.set_presentMode(@vk.VK_PRESENT_MODE_FIFO_KHR)
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
  let na = @vk.VkAllocationCallbacks::null()
  let _ = @win.initialize()
  let window = @win.create(
    desc.width,
    desc.height,
    desc.title,
  )
  let surface = @win.create_surface(d.inst, window)
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

  let rb_bytes = w * h * 4
  let rb0 = vk_buffer_create(d, rb_bytes, BufferKind::Staging)
  let rb1 = vk_buffer_create(d, rb_bytes, BufferKind::Staging)
  let readback_bufs = FixedArray::make(MAX_FRAMES, rb0)
  readback_bufs[1] = rb1

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
    depth_image,
    depth_view,
    depth_mem,
    pool,
    cmds,
    image_available,
    in_flight,
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
  for i = 0; i < MAX_FRAMES; i = i + 1 {
    vk_buffer_destroy(s.readback_bufs[i])
  }
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

  let rb_bytes = w * h * 4
  s.readback_bufs[0] = vk_buffer_create(d, rb_bytes, BufferKind::Staging)
  s.readback_bufs[1] = vk_buffer_create(d, rb_bytes, BufferKind::Staging)
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
fn vk_swapchain_begin_frame(
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

  cmd_image_barrier2(
    d,
    cmd,
    s.images[s.image_index],
    @vk.VK_IMAGE_ASPECT_COLOR_BIT,
    @vk.VK_PIPELINE_STAGE_2_COLOR_ATTACHMENT_OUTPUT_BIT,
    @vk.VK_ACCESS_2_NONE,
    @vk.VK_PIPELINE_STAGE_2_COLOR_ATTACHMENT_OUTPUT_BIT,
    @vk.VK_ACCESS_2_COLOR_ATTACHMENT_WRITE_BIT,
    @vk.VK_IMAGE_LAYOUT_UNDEFINED,
    @vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
  )
  if s.has_depth {
    cmd_image_barrier2(
      d,
      cmd,
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
  let cv = @vk.VkClearValue::new()
  cv.set_color_rgba(
    s.clear_color.r,
    s.clear_color.g,
    s.clear_color.b,
    s.clear_color.a,
  )
  let catt = @vk.VkRenderingAttachmentInfo::new()
  catt.set_imageView(s.views[s.image_index])
  catt.set_imageLayout(@vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL)
  catt.set_loadOp(@vk.VK_ATTACHMENT_LOAD_OP_CLEAR)
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

  (d.dfn.vkCmdBeginRendering)(cmd, ri)
  ext.free()
  area.free()
  cv.free()
  catt.free()
  dcv.free()
  datt.free()
  ri.free()

  set_dynamic_viewport_scissor(d, cmd, s.width, s.height)
  {
    device: d,
    cmd,
    frame_idx: fi,
    frame_gen: s.frame_gen,
    pending_uniforms: [],
    pending_textures: [],
    pending_storage: [],
    pending_storage_images: [],
    bound: None,
    active_render_targets: [],
  }
}

///|
fn vk_swapchain_end_frame(
  s : VkSwapchainState,
  c : VkCmdState,
) -> Unit raise RhiError {
  let d = s.device
  let fi = s.frame_idx
  let img_idx = s.image_index
  (d.dfn.vkCmdEndRendering)(c.cmd)
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
  if sr != 0 {
    raise CommandFailed("vkQueueSubmit2 failed: \{sr}")
  }

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
  for i = 0; i < MAX_FRAMES; i = i + 1 {
    vk_buffer_destroy(s.readback_bufs[i])
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
fn alloc_pipeline_descriptors(
  d : VkDeviceState,
  u_bindings : FixedArray[Int],
  t_bindings : FixedArray[Int],
  s_bindings : FixedArray[Int],
  si_bindings : FixedArray[Int],
  stages : UInt32,
) -> (
  @vk.VkDescriptorSetLayout,
  @vk.VkDescriptorPool,
  FixedArray[@vk.VkDescriptorSet],
) raise RhiError {
  let na = @vk.VkAllocationCallbacks::null()
  let uniform_slots = u_bindings.length()
  let texture_slots = t_bindings.length()
  let storage_slots = s_bindings.length()
  let storage_image_slots = si_bindings.length()
  let total = uniform_slots + texture_slots + storage_slots + storage_image_slots
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

  if total == 0 {
    return (
      set_layout,
      @vk.VkDescriptorPool::null(),
      FixedArray::make(0, @vk.VkDescriptorSet::null()),
    )
  }

  let nsizes = (if uniform_slots > 0 { 1 } else { 0 }) +
    (if texture_slots > 0 { 1 } else { 0 }) +
    (if storage_slots > 0 { 1 } else { 0 }) +
    (if storage_image_slots > 0 { 1 } else { 0 })
  let sizes = @vk.VkDescriptorPoolSize::array(nsizes)
  let mut si = 0
  if uniform_slots > 0 {
    sizes.set_type_at(si, @vk.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER)
    sizes.set_descriptorCount_at(
      si,
      (uniform_slots * MAX_PIPELINE_SETS).reinterpret_as_uint(),
    )
    si = si + 1
  }
  if texture_slots > 0 {
    sizes.set_type_at(si, @vk.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER)
    sizes.set_descriptorCount_at(
      si,
      (texture_slots * MAX_PIPELINE_SETS).reinterpret_as_uint(),
    )
    si = si + 1
  }
  if storage_slots > 0 {
    sizes.set_type_at(si, @vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER)
    sizes.set_descriptorCount_at(
      si,
      (storage_slots * MAX_PIPELINE_SETS).reinterpret_as_uint(),
    )
    si = si + 1
  }
  if storage_image_slots > 0 {
    sizes.set_type_at(si, @vk.VK_DESCRIPTOR_TYPE_STORAGE_IMAGE)
    sizes.set_descriptorCount_at(
      si,
      (storage_image_slots * MAX_PIPELINE_SETS).reinterpret_as_uint(),
    )
  }
  let dpci = @vk.VkDescriptorPoolCreateInfo::new()
  dpci.set_maxSets(MAX_PIPELINE_SETS.reinterpret_as_uint())
  dpci.set_poolSizeCount(nsizes.reinterpret_as_uint())
  dpci.set_pPoolSizes(sizes)
  let dpool_out = FixedArray::make(1, @vk.VkDescriptorPool::null())
  let pr = (d.dfn.vkCreateDescriptorPool)(d.dev, dpci, na, dpool_out)
  sizes.free()
  dpci.free()
  if pr != 0 {
    (d.dfn.vkDestroyDescriptorSetLayout)(d.dev, set_layout, na)
    raise PipelineFailed("vkCreateDescriptorPool failed: \{pr}")
  }
  let descriptor_pool = dpool_out[0]
  let layouts = FixedArray::make(MAX_PIPELINE_SETS, set_layout)
  let dsai = @vk.VkDescriptorSetAllocateInfo::new()
  dsai.set_descriptorPool(descriptor_pool)
  dsai.set_descriptorSetCount(MAX_PIPELINE_SETS.reinterpret_as_uint())
  dsai.set_pSetLayouts(layouts)
  let sets = FixedArray::make(MAX_PIPELINE_SETS, @vk.VkDescriptorSet::null())
  let ar = (d.dfn.vkAllocateDescriptorSets)(d.dev, dsai, sets)
  dsai.free()
  if ar != 0 {
    (d.dfn.vkDestroyDescriptorPool)(d.dev, descriptor_pool, na)
    (d.dfn.vkDestroyDescriptorSetLayout)(d.dev, set_layout, na)
    raise PipelineFailed("vkAllocateDescriptorSets failed: \{ar}")
  }
  (set_layout, descriptor_pool, sets)
}

///|
fn vk_graphics_pipeline_create(
  d : VkDeviceState,
  desc : PipelineDesc,
  default_color_vk_fmt : UInt32,
) -> VkPipelineState raise RhiError {
  if desc.vert.length() == 0 || desc.frag.length() == 0 {
    raise InvalidArgument("Graphics pipeline requires non-empty SPIR-V shaders")
  }
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
  let fsmci = @vk.VkShaderModuleCreateInfo::new()
  fsmci.set_codeSize((desc.frag.length() * 4).to_uint64())
  fsmci.set_pCode(desc.frag)
  let fsm_out = FixedArray::make(1, @vk.VkShaderModule::null())
  let fr = (d.dfn.vkCreateShaderModule)(d.dev, fsmci, na, fsm_out)
  fsmci.free()
  if fr != 0 {
    (d.dfn.vkDestroyShaderModule)(d.dev, vsm_out[0], na)
    raise PipelineFailed("Fragment vkCreateShaderModule failed: \{fr}")
  }

  let stages = @vk.VkPipelineShaderStageCreateInfo::array(2)
  stages.set_stage_at(0, @vk.VK_SHADER_STAGE_VERTEX_BIT)
  stages.set_module_at(0, vsm_out[0])
  stages.set_pName_at(0, @vk.cstr("main"))
  stages.set_stage_at(1, @vk.VK_SHADER_STAGE_FRAGMENT_BIT)
  stages.set_module_at(1, fsm_out[0])
  stages.set_pName_at(1, @vk.cstr("main"))

  let nattr = desc.vertex_formats.length()
  let attribs = @vk.VkVertexInputAttributeDescription::array(nattr)
  let mut offset = 0
  for i = 0; i < nattr; i = i + 1 {
    let f = desc.vertex_formats[i]
    attribs.set_binding_at(i, (0 : UInt32))
    attribs.set_location_at(i, i.reinterpret_as_uint())
    attribs.set_format_at(i, vk_vertex_format(f))
    attribs.set_offset_at(i, offset.reinterpret_as_uint())
    offset = offset + vertex_format_bytes(f)
  }
  let vbinding = @vk.VkVertexInputBindingDescription::new()
  vbinding.set_binding((0 : UInt32))
  vbinding.set_stride(offset.reinterpret_as_uint())
  vbinding.set_inputRate(@vk.VK_VERTEX_INPUT_RATE_VERTEX)
  let vertex_input = @vk.VkPipelineVertexInputStateCreateInfo::new()
  if nattr > 0 {
    vertex_input.set_vertexBindingDescriptionCount((1 : UInt32))
    vertex_input.set_pVertexBindingDescriptions(vbinding)
    vertex_input.set_vertexAttributeDescriptionCount(nattr.reinterpret_as_uint())
    vertex_input.set_pVertexAttributeDescriptions(attribs)
  }

  let input_assembly = @vk.VkPipelineInputAssemblyStateCreateInfo::new()
  input_assembly.set_topology(@vk.VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST)

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
  depth_stencil.set_depthCompareOp(@vk.VK_COMPARE_OP_LESS)

  let color_vk_fmts : FixedArray[UInt32] = if desc.color_formats.length() > 0 {
    FixedArray::makei(desc.color_formats.length(), fn(i) {
      vk_texture_format(desc.color_formats[i])
    })
  } else {
    let single = match desc.color_format {
      Some(f) => vk_texture_format(f)
      None => default_color_vk_fmt
    }
    FixedArray::make(1, single)
  }
  let n_colors = color_vk_fmts.length()

  let blend_atts = @vk.VkPipelineColorBlendAttachmentState::array(n_colors)
  let mask = @vk.VK_COLOR_COMPONENT_R_BIT |
    @vk.VK_COLOR_COMPONENT_G_BIT |
    @vk.VK_COLOR_COMPONENT_B_BIT |
    @vk.VK_COLOR_COMPONENT_A_BIT
  for i = 0; i < n_colors; i = i + 1 {
    blend_atts.set_colorWriteMask_at(i, mask)
    if desc.blend {
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

  let (set_layout, descriptor_pool, sets) = alloc_pipeline_descriptors(
    d,
    u_bindings,
    t_bindings,
    s_bindings,
    si_bindings,
    @vk.VK_SHADER_STAGE_VERTEX_BIT | @vk.VK_SHADER_STAGE_FRAGMENT_BIT,
  )

  let total_slots = desc.uniform_slots +
    desc.texture_slots +
    desc.storage_slots +
    desc.storage_image_slots
  let plci = @vk.VkPipelineLayoutCreateInfo::new()
  if total_slots > 0 {
    plci.set_setLayoutCount((1 : UInt32))
    plci.set_pSetLayouts(FixedArray::make(1, set_layout))
  }
  let pcr = @vk.VkPushConstantRange::new()
  if desc.push_constant_size > 0 {
    pcr.set_stageFlags(
      @vk.VK_SHADER_STAGE_VERTEX_BIT | @vk.VK_SHADER_STAGE_FRAGMENT_BIT,
    )
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
    vbinding.free()
    vertex_input.free()
    input_assembly.free()
    viewport_state.free()
    dyn_ci.free()
    rasterizer.free()
    multisample.free()
    depth_stencil.free()
    blend_atts.free()
    color_blend.free()
    if total_slots > 0 {
      (d.dfn.vkDestroyDescriptorPool)(d.dev, descriptor_pool, na)
    }
    (d.dfn.vkDestroyDescriptorSetLayout)(d.dev, set_layout, na)
    (d.dfn.vkDestroyShaderModule)(d.dev, vsm_out[0], na)
    (d.dfn.vkDestroyShaderModule)(d.dev, fsm_out[0], na)
    raise PipelineFailed("vkCreatePipelineLayout failed: \{plr}")
  }

  let prci = @vk.VkPipelineRenderingCreateInfo::new()
  prci.set_colorAttachmentCount(n_colors.reinterpret_as_uint())
  prci.set_pColorAttachmentFormats(color_vk_fmts)
  if desc.depth_test || desc.depth_write {
    prci.set_depthAttachmentFormat(@vk.VK_FORMAT_D32_SFLOAT)
  }

  let gpci = @vk.VkGraphicsPipelineCreateInfo::new()
  gpci.set_pNext(prci.as_ptr())
  gpci.set_stageCount((2 : UInt32))
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
    @vk.VkPipelineCache::null(),
    (1 : UInt32),
    gpci,
    na,
    pipe_out,
  )
  prci.free()
  gpci.free()
  stages.free()
  attribs.free()
  vbinding.free()
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
    if total_slots > 0 {
      (d.dfn.vkDestroyDescriptorPool)(d.dev, descriptor_pool, na)
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
    descriptor_pool,
    sets,
    last_gen: FixedArray::make(MAX_FRAMES, (0 : UInt64)),
    set_cursor: FixedArray::make(MAX_FRAMES, 0),
    vert_module: vsm_out[0],
    frag_module: fsm_out[0],
    uniform_slots: desc.uniform_slots,
    texture_slots: desc.texture_slots,
    storage_slots: desc.storage_slots,
    storage_image_slots: desc.storage_image_slots,
    uniform_bindings: u_bindings,
    texture_bindings: t_bindings,
    storage_bindings: s_bindings,
    storage_image_bindings: si_bindings,
    compute: false,
    cur_uniforms: FixedArray::make(desc.uniform_slots, None),
    cur_textures: FixedArray::make(desc.texture_slots, None),
    cur_storage: FixedArray::make(desc.storage_slots, None),
    cur_storage_images: FixedArray::make(desc.storage_image_slots, None),
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

  let (set_layout, descriptor_pool, sets) = alloc_pipeline_descriptors(
    d,
    u_bindings,
    t_bindings,
    s_bindings,
    si_bindings,
    @vk.VK_SHADER_STAGE_COMPUTE_BIT,
  )
  let uniform_slots = u_bindings.length()
  let texture_slots = t_bindings.length()
  let storage_slots = s_bindings.length()
  let storage_image_slots = si_bindings.length()
  let total_slots = uniform_slots +
    texture_slots +
    storage_slots +
    storage_image_slots
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
    if total_slots > 0 {
      (d.dfn.vkDestroyDescriptorPool)(d.dev, descriptor_pool, na)
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
    @vk.VkPipelineCache::null(),
    (1 : UInt32),
    cpci,
    na,
    pipe_out,
  )
  stage.free()
  cpci.free()
  if cpr != 0 {
    (d.dfn.vkDestroyPipelineLayout)(d.dev, pl_out[0], na)
    if total_slots > 0 {
      (d.dfn.vkDestroyDescriptorPool)(d.dev, descriptor_pool, na)
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
    descriptor_pool,
    sets,
    last_gen: FixedArray::make(MAX_FRAMES, (0 : UInt64)),
    set_cursor: FixedArray::make(MAX_FRAMES, 0),
    vert_module: sm_out[0],
    frag_module: @vk.VkShaderModule::null(),
    uniform_slots,
    texture_slots,
    storage_slots,
    storage_image_slots,
    uniform_bindings: u_bindings,
    texture_bindings: t_bindings,
    storage_bindings: s_bindings,
    storage_image_bindings: si_bindings,
    compute: true,
    cur_uniforms: FixedArray::make(uniform_slots, None),
    cur_textures: FixedArray::make(texture_slots, None),
    cur_storage: FixedArray::make(storage_slots, None),
    cur_storage_images: FixedArray::make(storage_image_slots, None),
  }
}

///|
fn vk_pipeline_destroy(p : VkPipelineState) -> Unit {
  let na = @vk.VkAllocationCallbacks::null()
  let d = p.device
  let _ = (d.dfn.vkDeviceWaitIdle)(d.dev)
  (d.dfn.vkDestroyPipeline)(d.dev, p.pipeline, na)
  (d.dfn.vkDestroyPipelineLayout)(d.dev, p.layout, na)
  (d.dfn.vkDestroyDescriptorSetLayout)(d.dev, p.set_layout, na)
  if p.uniform_slots + p.texture_slots + p.storage_slots + p.storage_image_slots >
    0 {
    (d.dfn.vkDestroyDescriptorPool)(d.dev, p.descriptor_pool, na)
  }
  (d.dfn.vkDestroyShaderModule)(d.dev, p.vert_module, na)
  if p.frag_module.as_ptr() != (0 : UInt64) {
    (d.dfn.vkDestroyShaderModule)(d.dev, p.frag_module, na)
  }
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
fn vk_cmd_flush_slots(c : VkCmdState) -> Unit {
  for entry in c.pending_uniforms {
    let (p, slot, buf) = entry
    let ps = p.inner
    if slot >= 0 && slot < ps.uniform_slots {
      ps.cur_uniforms[slot] = Some(buf)
    }
  }
  c.pending_uniforms.clear()
  for entry in c.pending_textures {
    let (p, slot, tex, samp) = entry
    let ps = p.inner
    if slot >= 0 && slot < ps.texture_slots {
      ps.cur_textures[slot] = Some((tex, samp))
    }
  }
  c.pending_textures.clear()
  for entry in c.pending_storage {
    let (p, slot, buf) = entry
    let ps = p.inner
    if slot >= 0 && slot < ps.storage_slots {
      ps.cur_storage[slot] = Some(buf)
    }
  }
  c.pending_storage.clear()
  for entry in c.pending_storage_images {
    let (p, slot, tex) = entry
    let ps = p.inner
    if slot >= 0 && slot < ps.storage_image_slots {
      ps.cur_storage_images[slot] = Some(tex)
    }
  }
  c.pending_storage_images.clear()

  match c.bound {
    Some(p) => {
      let ps = p.inner
      let total = ps.uniform_slots +
        ps.texture_slots +
        ps.storage_slots +
        ps.storage_image_slots
      if total > 0 {
        let f = c.frame_idx % MAX_FRAMES
        if ps.last_gen[f] != c.frame_gen {
          ps.last_gen[f] = c.frame_gen
          ps.set_cursor[f] = 0
        }
        let cursor = ps.set_cursor[f] % SETS_PER_FRAME
        ps.set_cursor[f] = ps.set_cursor[f] + 1
        let dset = ps.sets[f * SETS_PER_FRAME + cursor]
        for i = 0; i < ps.uniform_slots; i = i + 1 {
          match ps.cur_uniforms[i] {
            Some(buf) =>
              write_descriptor_buffer(
                c.device,
                dset,
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
                dset,
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
                dset,
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
                dset,
                ps.storage_image_bindings[i],
                tex.inner,
              )
            None => ()
          }
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
  let d = tp.device
  let _ = (d.dfn.vkDeviceWaitIdle)(d.dev)
  (d.dfn.vkDestroyQueryPool)(d.dev, tp.pool, @vk.VkAllocationCallbacks::null())
}

///|
fn vk_cmd_begin_render_pass(
  c : VkCmdState,
  colors : Array[RenderTargetDesc],
  depth : DepthTargetDesc?,
) -> Unit raise RhiError {
  if colors.length() == 0 {
    raise InvalidArgument("begin_render_pass requires at least one color target")
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
        @vk.VK_IMAGE_ASPECT_DEPTH_BIT,
        @vk.VK_PIPELINE_STAGE_2_ALL_COMMANDS_BIT,
        @vk.VK_ACCESS_2_DEPTH_STENCIL_ATTACHMENT_WRITE_BIT,
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

  let w = colors[0].texture.inner.width
  let h = colors[0].texture.inner.height
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
  ri.set_pColorAttachments(catts)
  let datt = @vk.VkRenderingAttachmentInfo::new()
  match depth {
    Some(dt) => {
      cv.set_depth_stencil(dt.clear_depth, (0 : UInt32))
      datt.set_imageView(dt.texture.inner.view)
      datt.set_imageLayout(@vk.VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL)
      datt.set_loadOp(vk_load_op(dt.load_op))
      datt.set_storeOp(vk_store_op(dt.store_op))
      datt.set_clearValue(cv)
      ri.set_pDepthAttachment(datt)
    }
    None => ()
  }
  (d.dfn.vkCmdBeginRendering)(c.cmd, ri)
  ext.free()
  area.free()
  cv.free()
  catts.free()
  datt.free()
  ri.free()
  set_dynamic_viewport_scissor(d, c.cmd, w, h)
  c.active_render_targets = colors
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
  c.active_render_targets = []
}
