// Example 14 — Vulkan 1.3 dynamic rendering + synchronization2 (no render pass,
// no framebuffer). Exercises three binding capabilities end to end:
//   1. typed pNext chains: features2 -> Vulkan13Features, pipeline -> RenderingCreateInfo
//   2. the generated debug messenger (capture-free callback + read_cstr)
//   3. vkCmdPipelineBarrier2 / vkCmdBeginRendering / vkQueueSubmit2
// Pure MoonBit; verifies by pixel readback and by a deliberate validation error.

// FuncRef callbacks must be capture-free, so state lives in top-level refs.
let g_msgs : Ref[Int] = { val: 0 }

let g_errors : Ref[Int] = { val: 0 }

///|
fn find_mem_type(
  memprops : @vk.VkPhysicalDeviceMemoryProperties,
  type_bits : UInt32,
  props : UInt32,
) -> Int {
  let n = memprops.get_memoryTypeCount().reinterpret_as_int()
  for i = 0; i < n; i = i + 1 {
    if (type_bits & ((1 : UInt32) << i)) != (0 : UInt32) &&
      (memprops.get_memoryTypes_at(i).get_propertyFlags() & props) == props {
      return i
    }
  }
  -1
}

///|
fn create_offscreen(
  dev : @vk.VkDevice,
  dfn : @vk.DeviceFn,
  phys : @vk.VkPhysicalDevice,
  ifn : @vk.InstanceFn,
  format : UInt32,
  w : UInt32,
  h : UInt32,
) -> (@vk.VkImage, @vk.VkDeviceMemory, @vk.VkImageView) {
  let na = @vk.VkAllocationCallbacks::null()
  let ext = @vk.VkExtent3D::new()
  ext.set_width(w)
  ext.set_height(h)
  ext.set_depth((1 : UInt32))
  let ici = @vk.VkImageCreateInfo::new()
  ici.set_imageType(@vk.VK_IMAGE_TYPE_2D)
  ici.set_format(format)
  ici.set_extent(ext)
  ici.set_mipLevels((1 : UInt32))
  ici.set_arrayLayers((1 : UInt32))
  ici.set_samples(@vk.VK_SAMPLE_COUNT_1_BIT)
  ici.set_tiling(@vk.VK_IMAGE_TILING_OPTIMAL)
  ici.set_usage(@vk.VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT | @vk.VK_IMAGE_USAGE_TRANSFER_SRC_BIT)
  ici.set_sharingMode(@vk.VK_SHARING_MODE_EXCLUSIVE)
  let img_out = FixedArray::make(1, @vk.VkImage::null())
  let _ = (dfn.vkCreateImage)(dev, ici, na, img_out)
  let req = @vk.VkMemoryRequirements::new()
  (dfn.vkGetImageMemoryRequirements)(dev, img_out[0], req)
  let mp = @vk.VkPhysicalDeviceMemoryProperties::new()
  (ifn.vkGetPhysicalDeviceMemoryProperties)(phys, mp)
  let mt = find_mem_type(mp, req.get_memoryTypeBits(), @vk.VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT)
  let mai = @vk.VkMemoryAllocateInfo::new()
  mai.set_allocationSize(req.get_size())
  mai.set_memoryTypeIndex(mt.reinterpret_as_uint())
  let mem_out = FixedArray::make(1, @vk.VkDeviceMemory::null())
  let _ = (dfn.vkAllocateMemory)(dev, mai, na, mem_out)
  let _ = (dfn.vkBindImageMemory)(dev, img_out[0], mem_out[0], (0 : UInt64))
  let range = @vk.VkImageSubresourceRange::new()
  range.set_aspectMask(@vk.VK_IMAGE_ASPECT_COLOR_BIT)
  range.set_levelCount((1 : UInt32))
  range.set_layerCount((1 : UInt32))
  let ivci = @vk.VkImageViewCreateInfo::new()
  ivci.set_image(img_out[0])
  ivci.set_viewType(@vk.VK_IMAGE_VIEW_TYPE_2D)
  ivci.set_format(format)
  ivci.set_subresourceRange(range)
  let iv_out = FixedArray::make(1, @vk.VkImageView::null())
  let _ = (dfn.vkCreateImageView)(dev, ivci, na, iv_out)
  ext.free()
  ici.free()
  req.free()
  mp.free()
  mai.free()
  range.free()
  ivci.free()
  (img_out[0], mem_out[0], iv_out[0])
}

///|
fn readback_offscreen(
  dev : @vk.VkDevice,
  dfn : @vk.DeviceFn,
  phys : @vk.VkPhysicalDevice,
  ifn : @vk.InstanceFn,
  queue : @vk.VkQueue,
  pool : @vk.VkCommandPool,
  image : @vk.VkImage,
  w : Int,
  h : Int,
) -> FixedArray[Byte] {
  let na = @vk.VkAllocationCallbacks::null()
  let bytes = w * h * 4
  let bci = @vk.VkBufferCreateInfo::new()
  bci.set_size(bytes.to_uint64())
  bci.set_usage(@vk.VK_BUFFER_USAGE_TRANSFER_DST_BIT)
  bci.set_sharingMode(@vk.VK_SHARING_MODE_EXCLUSIVE)
  let buf_out = FixedArray::make(1, @vk.VkBuffer::null())
  let _ = (dfn.vkCreateBuffer)(dev, bci, na, buf_out)
  let req = @vk.VkMemoryRequirements::new()
  (dfn.vkGetBufferMemoryRequirements)(dev, buf_out[0], req)
  let mp = @vk.VkPhysicalDeviceMemoryProperties::new()
  (ifn.vkGetPhysicalDeviceMemoryProperties)(phys, mp)
  let mt = find_mem_type(
    mp,
    req.get_memoryTypeBits(),
    @vk.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | @vk.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT,
  )
  let mai = @vk.VkMemoryAllocateInfo::new()
  mai.set_allocationSize(req.get_size())
  mai.set_memoryTypeIndex(mt.reinterpret_as_uint())
  let mem_out = FixedArray::make(1, @vk.VkDeviceMemory::null())
  let _ = (dfn.vkAllocateMemory)(dev, mai, na, mem_out)
  let _ = (dfn.vkBindBufferMemory)(dev, buf_out[0], mem_out[0], (0 : UInt64))
  let cbai = @vk.VkCommandBufferAllocateInfo::new()
  cbai.set_commandPool(pool)
  cbai.set_level(@vk.VK_COMMAND_BUFFER_LEVEL_PRIMARY)
  cbai.set_commandBufferCount((1 : UInt32))
  let cmd_out = FixedArray::make(1, @vk.VkCommandBuffer::null())
  let _ = (dfn.vkAllocateCommandBuffers)(dev, cbai, cmd_out)
  let bi = @vk.VkCommandBufferBeginInfo::new()
  bi.set_flags(@vk.VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT)
  let _ = (dfn.vkBeginCommandBuffer)(cmd_out[0], bi)
  let sub = @vk.VkImageSubresourceLayers::new()
  sub.set_aspectMask(@vk.VK_IMAGE_ASPECT_COLOR_BIT)
  sub.set_layerCount((1 : UInt32))
  let ext = @vk.VkExtent3D::new()
  ext.set_width(w.reinterpret_as_uint())
  ext.set_height(h.reinterpret_as_uint())
  ext.set_depth((1 : UInt32))
  let region = @vk.VkBufferImageCopy::new()
  region.set_imageSubresource(sub)
  region.set_imageExtent(ext)
  (dfn.vkCmdCopyImageToBuffer)(
    cmd_out[0],
    image,
    @vk.VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,
    buf_out[0],
    (1 : UInt32),
    region,
  )
  let _ = (dfn.vkEndCommandBuffer)(cmd_out[0])
  let si = @vk.VkSubmitInfo::new()
  si.set_commandBufferCount((1 : UInt32))
  si.set_pCommandBuffers(cmd_out)
  let _ = (dfn.vkQueueSubmit)(queue, (1 : UInt32), si, @vk.VkFence::null())
  let _ = (dfn.vkQueueWaitIdle)(queue)
  let raw = @vk.download_buffer(dev, mem_out[0], bytes)
  let out = FixedArray::makei(raw.length(), fn(i) { raw[i] })
  (dfn.vkFreeCommandBuffers)(dev, pool, (1 : UInt32), cmd_out)
  (dfn.vkDestroyBuffer)(dev, buf_out[0], na)
  (dfn.vkFreeMemory)(dev, mem_out[0], na)
  bci.free()
  req.free()
  mp.free()
  mai.free()
  cbai.free()
  bi.free()
  sub.free()
  ext.free()
  region.free()
  si.free()
  out
}

///|
fn count_rgb_pixels(px : FixedArray[Byte]) -> UInt32 {
  let mut n = 0
  let mut i = 0
  while i + 3 < px.length() {
    if px[i] != (0 : Byte) || px[i + 1] != (0 : Byte) || px[i + 2] != (0 : Byte) {
      n = n + 1
    }
    i = i + 4
  }
  n.reinterpret_as_uint()
}

///|
fn main {
  let show_win = @shader.want_window()
  let shot = @shader.screenshot_path()
  let na = @vk.VkAllocationCallbacks::null()
  let app = @vk.VkApplicationInfo::new()
  app.set_pApplicationName(@vk.cstr("Tycho Dynamic Rendering"))
  app.set_apiVersion((4206592 : UInt32)) // VK_MAKE_API_VERSION(0, 1, 3, 0)
  let ici = @vk.VkInstanceCreateInfo::new()
  ici.set_pApplicationInfo(app)
  ici.set_enabledLayerCount((1 : UInt32))
  ici.set_ppEnabledLayerNames(@vk.cstr_array(["VK_LAYER_KHRONOS_validation"]))
  if show_win {
    let se = @win.surface_extensions()
    let exts = FixedArray::make(se.length() + 1, "")
    for i = 0; i < se.length(); i = i + 1 {
      exts[i] = se[i]
    }
    exts[se.length()] = "VK_EXT_debug_utils"
    ici.set_enabledExtensionCount(exts.length().reinterpret_as_uint())
    ici.set_ppEnabledExtensionNames(@vk.cstr_array(exts))
  } else {
    ici.set_enabledExtensionCount((1 : UInt32))
    ici.set_ppEnabledExtensionNames(@vk.cstr_array(["VK_EXT_debug_utils"]))
  }
  let inst_out = FixedArray::make(1, @vk.VkInstance::null())
  let ir = @vk.vkCreateInstance(ici, na, inst_out)
  let inst = inst_out[0]
  let ifn = @vk.InstanceFn::load(inst)
  if ir != 0 {
    println("[14-dyn] FAIL — vkCreateInstance=\{ir}")
    return
  }

  // --- (2) debug messenger from the generated layer ---
  let messenger = @vk.create_debug_messenger(
    inst,
    ifn,
    @vk.VK_DEBUG_UTILS_MESSAGE_SEVERITY_WARNING_BIT_EXT |
    @vk.VK_DEBUG_UTILS_MESSAGE_SEVERITY_ERROR_BIT_EXT,
    @vk.VK_DEBUG_UTILS_MESSAGE_TYPE_GENERAL_BIT_EXT |
    @vk.VK_DEBUG_UTILS_MESSAGE_TYPE_VALIDATION_BIT_EXT |
    @vk.VK_DEBUG_UTILS_MESSAGE_TYPE_PERFORMANCE_BIT_EXT,
    (sev, _ty, data, _ud) => {
      g_msgs.val = g_msgs.val + 1
      let msg = @vk.read_cstr(data.get_pMessage())
      if (sev & @vk.VK_DEBUG_UTILS_MESSAGE_SEVERITY_ERROR_BIT_EXT) != (0 : UInt32) {
        g_errors.val = g_errors.val + 1
        println("[14-dyn] VALIDATION ERROR: \{msg}")
      }
      (0 : UInt32)
    },
  )

  let pc = FixedArray::make(1, (16 : UInt32))
  let pdevs = FixedArray::make(16, @vk.VkPhysicalDevice::null())
  let _ = (ifn.vkEnumeratePhysicalDevices)(inst, pc, pdevs)
  let phys = pdevs[0]
  let props = @vk.VkPhysicalDeviceProperties::new()
  (ifn.vkGetPhysicalDeviceProperties)(phys, props)

  // --- (1a) pNext chain: features2 -> Vulkan13Features ---
  let f13q = @vk.VkPhysicalDeviceVulkan13Features::new()
  let f2 = @vk.VkPhysicalDeviceFeatures2::new()
  f2.set_pNext(f13q.as_ptr())
  (ifn.vkGetPhysicalDeviceFeatures2)(phys, f2)
  let has_dyn = f13q.get_dynamicRendering()
  let has_sync2 = f13q.get_synchronization2()
  println(
    "[14-dyn] apiVersion=\{props.get_apiVersion()} dynamicRendering=\{has_dyn} synchronization2=\{has_sync2}",
  )
  if has_dyn == 0 || has_sync2 == 0 {
    println("[14-dyn] FAIL — device lacks dynamicRendering/synchronization2")
    return
  }

  let prio = FixedArray::make(1, (1.0 : Float))
  let qci = @vk.VkDeviceQueueCreateInfo::new()
  qci.set_queueFamilyIndex((0 : UInt32))
  qci.set_queueCount((1 : UInt32))
  qci.set_pQueuePriorities(prio)
  // --- (1b) pNext chain: device create info -> Vulkan13Features (enable) ---
  let f13 = @vk.VkPhysicalDeviceVulkan13Features::new()
  f13.set_dynamicRendering((1 : UInt32))
  f13.set_synchronization2((1 : UInt32))
  let dci = @vk.VkDeviceCreateInfo::new()
  dci.set_pNext(f13.as_ptr())
  dci.set_queueCreateInfoCount((1 : UInt32))
  dci.set_pQueueCreateInfos(qci)
  if show_win {
    dci.set_enabledExtensionCount((1 : UInt32))
    dci.set_ppEnabledExtensionNames(@vk.cstr_array(["VK_KHR_swapchain"]))
  }
  let dev_out = FixedArray::make(1, @vk.VkDevice::null())
  let dr = (ifn.vkCreateDevice)(phys, dci, na, dev_out)
  let dev = dev_out[0]
  let dfn = @vk.DeviceFn::load(dev)
  let queue_out = FixedArray::make(1, @vk.VkQueue::null())
  (dfn.vkGetDeviceQueue)(dev, (0 : UInt32), (0 : UInt32), queue_out)
  let queue = queue_out[0]
  if dr != 0 {
    println("[14-dyn] FAIL — vkCreateDevice=\{dr}")
    return
  }

  let extent = @vk.VkExtent2D::new()
  extent.set_width((800 : UInt32))
  extent.set_height((600 : UInt32))
  let mut win : UInt64 = (0 : UInt64)
  let mut surface = @vk.VkSurfaceKHR::null()
  let mut swapchain = @vk.VkSwapchainKHR::null()
  let mut format = @vk.VK_FORMAT_R8G8B8A8_UNORM
  let mut nimg = 1
  let images = FixedArray::make(8, @vk.VkImage::null())
  let views = FixedArray::make(8, @vk.VkImageView::null())
  let mut off_mem = @vk.VkDeviceMemory::null()
  let range = @vk.VkImageSubresourceRange::new()
  range.set_aspectMask(@vk.VK_IMAGE_ASPECT_COLOR_BIT)
  range.set_levelCount((1 : UInt32))
  range.set_layerCount((1 : UInt32))
  if show_win {
    let _ = @win.initialize()
    win = @win.create((800 : Int32), (600 : Int32), "14-dynamic-rendering")
    surface = @win.create_surface(inst, win)
    let caps = @vk.VkSurfaceCapabilitiesKHR::new()
    let _ = (ifn.vkGetPhysicalDeviceSurfaceCapabilitiesKHR)(phys, surface, caps)
    let fc = FixedArray::make(1, (0 : UInt32))
    let _ = (ifn.vkGetPhysicalDeviceSurfaceFormatsKHR)(
      phys,
      surface,
      fc,
      @vk.VkSurfaceFormatKHR::null(),
    )
    let formats = @vk.VkSurfaceFormatKHR::array(fc[0].reinterpret_as_int())
    let _ = (ifn.vkGetPhysicalDeviceSurfaceFormatsKHR)(phys, surface, fc, formats)
    format = formats.get_format_at(0)
    let swci = @vk.VkSwapchainCreateInfoKHR::new()
    swci.set_surface(surface)
    swci.set_minImageCount(caps.get_minImageCount())
    swci.set_imageFormat(format)
    swci.set_imageColorSpace(formats.get_colorSpace_at(0))
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
    let sc_out = FixedArray::make(1, @vk.VkSwapchainKHR::null())
    let _ = (dfn.vkCreateSwapchainKHR)(dev, swci, na, sc_out)
    swapchain = sc_out[0]
    let ic = FixedArray::make(1, (8 : UInt32))
    let _ = (dfn.vkGetSwapchainImagesKHR)(dev, swapchain, ic, images)
    nimg = ic[0].reinterpret_as_int()
    for i = 0; i < nimg; i = i + 1 {
      let ivci = @vk.VkImageViewCreateInfo::new()
      ivci.set_image(images[i])
      ivci.set_viewType(@vk.VK_IMAGE_VIEW_TYPE_2D)
      ivci.set_format(format)
      ivci.set_subresourceRange(range)
      let iv_out = FixedArray::make(1, @vk.VkImageView::null())
      let _ = (dfn.vkCreateImageView)(dev, ivci, na, iv_out)
      views[i] = iv_out[0]
      ivci.free()
    }
  } else {
    let (oi, om, ov) = create_offscreen(dev, dfn, phys, ifn, format, (800 : UInt32), (600 : UInt32))
    images[0] = oi
    off_mem = om
    views[0] = ov
  }

  // shaders + pipeline (no render pass: VkPipelineRenderingCreateInfo chained)
  let vert_code = @shader.compile_shader_file(
    "examples/14-dynamic-rendering/shader.vert",
    @shader.SHADER_KIND_VERTEX,
  )
  let frag_code = @shader.compile_shader_file(
    "examples/14-dynamic-rendering/shader.frag",
    @shader.SHADER_KIND_FRAGMENT,
  )
  let vsmci = @vk.VkShaderModuleCreateInfo::new()
  vsmci.set_codeSize((vert_code.length() * 4).to_uint64())
  vsmci.set_pCode(vert_code)
  let vsm_out = FixedArray::make(1, @vk.VkShaderModule::null())
  let _ = (dfn.vkCreateShaderModule)(dev, vsmci, na, vsm_out)
  let fsmci = @vk.VkShaderModuleCreateInfo::new()
  fsmci.set_codeSize((frag_code.length() * 4).to_uint64())
  fsmci.set_pCode(frag_code)
  let fsm_out = FixedArray::make(1, @vk.VkShaderModule::null())
  let _ = (dfn.vkCreateShaderModule)(dev, fsmci, na, fsm_out)
  let stages = @vk.VkPipelineShaderStageCreateInfo::array(2)
  stages.set_stage_at(0, @vk.VK_SHADER_STAGE_VERTEX_BIT)
  stages.set_module_at(0, vsm_out[0])
  stages.set_pName_at(0, @vk.cstr("main"))
  stages.set_stage_at(1, @vk.VK_SHADER_STAGE_FRAGMENT_BIT)
  stages.set_module_at(1, fsm_out[0])
  stages.set_pName_at(1, @vk.cstr("main"))
  let vertex_input = @vk.VkPipelineVertexInputStateCreateInfo::new()
  let input_assembly = @vk.VkPipelineInputAssemblyStateCreateInfo::new()
  input_assembly.set_topology(@vk.VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST)
  let viewport = @vk.VkViewport::new()
  viewport.set_width((800.0 : Float))
  viewport.set_height((600.0 : Float))
  viewport.set_maxDepth((1.0 : Float))
  let scissor = @vk.VkRect2D::new()
  scissor.set_extent(extent)
  let viewport_state = @vk.VkPipelineViewportStateCreateInfo::new()
  viewport_state.set_viewportCount((1 : UInt32))
  viewport_state.set_pViewports(viewport)
  viewport_state.set_scissorCount((1 : UInt32))
  viewport_state.set_pScissors(scissor)
  let rasterizer = @vk.VkPipelineRasterizationStateCreateInfo::new()
  rasterizer.set_polygonMode(@vk.VK_POLYGON_MODE_FILL)
  rasterizer.set_cullMode(@vk.VK_CULL_MODE_NONE)
  rasterizer.set_frontFace(@vk.VK_FRONT_FACE_CLOCKWISE)
  rasterizer.set_lineWidth((1.0 : Float))
  let multisample = @vk.VkPipelineMultisampleStateCreateInfo::new()
  multisample.set_rasterizationSamples(@vk.VK_SAMPLE_COUNT_1_BIT)
  let blend_attachment = @vk.VkPipelineColorBlendAttachmentState::new()
  blend_attachment.set_colorWriteMask(
    @vk.VK_COLOR_COMPONENT_R_BIT |
    @vk.VK_COLOR_COMPONENT_G_BIT |
    @vk.VK_COLOR_COMPONENT_B_BIT |
    @vk.VK_COLOR_COMPONENT_A_BIT,
  )
  let color_blend = @vk.VkPipelineColorBlendStateCreateInfo::new()
  color_blend.set_attachmentCount((1 : UInt32))
  color_blend.set_pAttachments(blend_attachment)
  let plci = @vk.VkPipelineLayoutCreateInfo::new()
  let pl_out = FixedArray::make(1, @vk.VkPipelineLayout::null())
  let _ = (dfn.vkCreatePipelineLayout)(dev, plci, na, pl_out)
  // --- (1c) pNext chain: graphics pipeline -> pipeline rendering info ---
  let prci = @vk.VkPipelineRenderingCreateInfo::new()
  prci.set_colorAttachmentCount((1 : UInt32))
  prci.set_pColorAttachmentFormats(FixedArray::make(1, format))
  let gpci = @vk.VkGraphicsPipelineCreateInfo::new()
  gpci.set_pNext(prci.as_ptr())
  gpci.set_stageCount((2 : UInt32))
  gpci.set_pStages(stages)
  gpci.set_pVertexInputState(vertex_input)
  gpci.set_pInputAssemblyState(input_assembly)
  gpci.set_pViewportState(viewport_state)
  gpci.set_pRasterizationState(rasterizer)
  gpci.set_pMultisampleState(multisample)
  gpci.set_pColorBlendState(color_blend)
  gpci.set_layout(pl_out[0])
  let pipe_out = FixedArray::make(1, @vk.VkPipeline::null())
  let gpr = (dfn.vkCreateGraphicsPipelines)(
    dev,
    @vk.VkPipelineCache::null(),
    (1 : UInt32),
    gpci,
    na,
    pipe_out,
  )
  let pipeline = pipe_out[0]
  if gpr != 0 {
    println("[14-dyn] FAIL — vkCreateGraphicsPipelines=\{gpr}")
    return
  }

  // command pool + buffers
  let cpci = @vk.VkCommandPoolCreateInfo::new()
  cpci.set_queueFamilyIndex((0 : UInt32))
  cpci.set_flags(@vk.VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT)
  let pool_out = FixedArray::make(1, @vk.VkCommandPool::null())
  let _ = (dfn.vkCreateCommandPool)(dev, cpci, na, pool_out)
  let cmd_buffers = FixedArray::make(nimg, @vk.VkCommandBuffer::null())
  let cbai = @vk.VkCommandBufferAllocateInfo::new()
  cbai.set_commandPool(pool_out[0])
  cbai.set_level(@vk.VK_COMMAND_BUFFER_LEVEL_PRIMARY)
  cbai.set_commandBufferCount(nimg.reinterpret_as_uint())
  let _ = (dfn.vkAllocateCommandBuffers)(dev, cbai, cmd_buffers)

  // --- (3) record with synchronization2 barriers + dynamic rendering ---
  let clear_value = @vk.VkClearValue::new()
  clear_value.set_color_rgba((0.0 : Float), (0.0 : Float), (0.0 : Float), (1.0 : Float))
  let render_area = @vk.VkRect2D::new()
  render_area.set_extent(extent)
  for i = 0; i < nimg; i = i + 1 {
    let cbi = @vk.VkCommandBufferBeginInfo::new()
    let _ = (dfn.vkBeginCommandBuffer)(cmd_buffers[i], cbi)
    // UNDEFINED -> COLOR_ATTACHMENT_OPTIMAL via vkCmdPipelineBarrier2
    let b2 = @vk.VkImageMemoryBarrier2::new()
    b2.set_srcStageMask(@vk.VK_PIPELINE_STAGE_2_TOP_OF_PIPE_BIT)
    b2.set_srcAccessMask((0 : UInt64))
    b2.set_dstStageMask(@vk.VK_PIPELINE_STAGE_2_COLOR_ATTACHMENT_OUTPUT_BIT)
    b2.set_dstAccessMask(@vk.VK_ACCESS_2_COLOR_ATTACHMENT_WRITE_BIT)
    b2.set_oldLayout(@vk.VK_IMAGE_LAYOUT_UNDEFINED)
    b2.set_newLayout(@vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL)
    b2.set_srcQueueFamilyIndex((0xFFFFFFFF : UInt32))
    b2.set_dstQueueFamilyIndex((0xFFFFFFFF : UInt32))
    b2.set_image(images[i])
    b2.set_subresourceRange(range)
    let dep = @vk.VkDependencyInfo::new()
    dep.set_imageMemoryBarrierCount((1 : UInt32))
    dep.set_pImageMemoryBarriers(b2)
    (dfn.vkCmdPipelineBarrier2)(cmd_buffers[i], dep)
    // vkCmdBeginRendering (no render pass / framebuffer)
    let att = @vk.VkRenderingAttachmentInfo::new()
    att.set_imageView(views[i])
    att.set_imageLayout(@vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL)
    att.set_loadOp(@vk.VK_ATTACHMENT_LOAD_OP_CLEAR)
    att.set_storeOp(@vk.VK_ATTACHMENT_STORE_OP_STORE)
    att.set_clearValue(clear_value)
    let ri = @vk.VkRenderingInfo::new()
    ri.set_renderArea(render_area)
    ri.set_layerCount((1 : UInt32))
    ri.set_colorAttachmentCount((1 : UInt32))
    ri.set_pColorAttachments(att)
    (dfn.vkCmdBeginRendering)(cmd_buffers[i], ri)
    (dfn.vkCmdBindPipeline)(cmd_buffers[i], @vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipeline)
    (dfn.vkCmdDraw)(cmd_buffers[i], (3 : UInt32), (1 : UInt32), (0 : UInt32), (0 : UInt32))
    (dfn.vkCmdEndRendering)(cmd_buffers[i])
    // COLOR_ATTACHMENT_OPTIMAL -> PRESENT_SRC_KHR
    b2.set_srcStageMask(@vk.VK_PIPELINE_STAGE_2_COLOR_ATTACHMENT_OUTPUT_BIT)
    b2.set_srcAccessMask(@vk.VK_ACCESS_2_COLOR_ATTACHMENT_WRITE_BIT)
    b2.set_dstStageMask(@vk.VK_PIPELINE_STAGE_2_BOTTOM_OF_PIPE_BIT)
    b2.set_dstAccessMask((0 : UInt64))
    b2.set_oldLayout(@vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL)
    b2.set_newLayout(
      if show_win {
        @vk.VK_IMAGE_LAYOUT_PRESENT_SRC_KHR
      } else {
        @vk.VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL
      },
    )
    (dfn.vkCmdPipelineBarrier2)(cmd_buffers[i], dep)
    let _ = (dfn.vkEndCommandBuffer)(cmd_buffers[i])
    cbi.free()
    ri.free()
    att.free()
    dep.free()
    b2.free()
  }

  // sync objects
  let semci = @vk.VkSemaphoreCreateInfo::new()
  let img_avail = FixedArray::make(1, @vk.VkSemaphore::null())
  let render_done = FixedArray::make(1, @vk.VkSemaphore::null())
  let _ = (dfn.vkCreateSemaphore)(dev, semci, na, img_avail)
  let _ = (dfn.vkCreateSemaphore)(dev, semci, na, render_done)
  let fci = @vk.VkFenceCreateInfo::new()
  fci.set_flags(@vk.VK_FENCE_CREATE_SIGNALED_BIT)
  let fence = FixedArray::make(1, @vk.VkFence::null())
  let _ = (dfn.vkCreateFence)(dev, fci, na, fence)

  // --- (3) vkQueueSubmit2 with VkSemaphoreSubmitInfo / VkCommandBufferSubmitInfo ---
  let wait_si = @vk.VkSemaphoreSubmitInfo::new()
  wait_si.set_semaphore(img_avail[0])
  wait_si.set_stageMask(@vk.VK_PIPELINE_STAGE_2_COLOR_ATTACHMENT_OUTPUT_BIT)
  let signal_si = @vk.VkSemaphoreSubmitInfo::new()
  signal_si.set_semaphore(render_done[0])
  signal_si.set_stageMask(@vk.VK_PIPELINE_STAGE_2_ALL_COMMANDS_BIT)
  let cmd_si = @vk.VkCommandBufferSubmitInfo::new()
  let si2 = @vk.VkSubmitInfo2::new()
  si2.set_waitSemaphoreInfoCount((1 : UInt32))
  si2.set_pWaitSemaphoreInfos(wait_si)
  si2.set_commandBufferInfoCount((1 : UInt32))
  si2.set_pCommandBufferInfos(cmd_si)
  si2.set_signalSemaphoreInfoCount((1 : UInt32))
  si2.set_pSignalSemaphoreInfos(signal_si)
  let present_sems = FixedArray::make(1, render_done[0])
  let swapchains = FixedArray::make(1, swapchain)
  let img_idx = FixedArray::make(1, (0 : UInt32))
  let present = @vk.VkPresentInfoKHR::new()
  present.set_waitSemaphoreCount((1 : UInt32))
  present.set_pWaitSemaphores(present_sems)
  present.set_swapchainCount((1 : UInt32))
  present.set_pSwapchains(swapchains)
  present.set_pImageIndices(img_idx)

  let mut rendered = (0 : UInt32)
  let mut verified = false
  let mut frames = 0
  let mut sr = 0
  let mut pr = 0
  if show_win {
    while @win.should_close(win) == 0 {
      @win.poll()
      let _ = (dfn.vkWaitForFences)(
        dev,
        (1 : UInt32),
        fence,
        (1 : UInt32),
        (0xFFFFFFFFFFFFFFFF : UInt64),
      )
      let _ = (dfn.vkAcquireNextImageKHR)(
        dev,
        swapchain,
        (0xFFFFFFFFFFFFFFFF : UInt64),
        img_avail[0],
        @vk.VkFence::null(),
        img_idx,
      )
      let _ = (dfn.vkResetFences)(dev, (1 : UInt32), fence)
      let idx = img_idx[0].reinterpret_as_int()
      cmd_si.set_commandBuffer(cmd_buffers[idx])
      sr = (dfn.vkQueueSubmit2)(queue, (1 : UInt32), si2, fence[0])
      let _ = (dfn.vkQueueWaitIdle)(queue)
      if !verified {
        rendered = @vk.count_rendered(
          dev,
          phys,
          queue,
          pool_out[0],
          images[idx],
          (800 : UInt32),
          (600 : UInt32),
        )
        if shot != "" {
          let px = @vk.readback_image(
            dev,
            phys,
            queue,
            pool_out[0],
            images[idx],
            (800 : UInt32),
            (600 : UInt32),
          )
          let _ = @shader.save_png(shot, 800, 600, px, bgra=format == @vk.VK_FORMAT_B8G8R8A8_UNORM)
        }
        verified = true
        println("[14-dyn] submit2=\{sr} rendered pixels=\{rendered}/480000")
      }
      pr = (dfn.vkQueuePresentKHR)(queue, present)
      let _ = (dfn.vkQueueWaitIdle)(queue)
      frames = frames + 1
    }
  } else {
    let _ = (dfn.vkResetFences)(dev, (1 : UInt32), fence)
    cmd_si.set_commandBuffer(cmd_buffers[0])
    let h_si2 = @vk.VkSubmitInfo2::new()
    h_si2.set_commandBufferInfoCount((1 : UInt32))
    h_si2.set_pCommandBufferInfos(cmd_si)
    sr = (dfn.vkQueueSubmit2)(queue, (1 : UInt32), h_si2, fence[0])
    let _ = (dfn.vkQueueWaitIdle)(queue)
    h_si2.free()
    let px = readback_offscreen(dev, dfn, phys, ifn, queue, pool_out[0], images[0], 800, 600)
    rendered = count_rgb_pixels(px)
    if shot != "" {
      let _ = @shader.save_png(shot, 800, 600, px)
    }
    frames = 1
    println("[14-dyn] headless submit2=\{sr} rendered pixels=\{rendered}/480000")
  }
  let _ = (dfn.vkDeviceWaitIdle)(dev)
  let render_errors = g_errors.val
  println("[14-dyn] frames=\{frames} validation messages=\{g_msgs.val} errors=\{render_errors}")

  // --- negative control: prove the messenger is not vacuous ---
  let bad = @vk.VkBufferCreateInfo::new()
  bad.set_size((0 : UInt64)) // invalid: must be > 0
  bad.set_usage((0 : UInt32)) // invalid: required bitmask
  let bad_out = FixedArray::make(1, @vk.VkBuffer::null())
  let bad_r = (dfn.vkCreateBuffer)(dev, bad, na, bad_out)
  let _ = (dfn.vkDeviceWaitIdle)(dev)
  let provoked = g_errors.val - render_errors
  println("[14-dyn] negative control: deliberate invalid buffer provoked \{provoked} errors")
  // Validation reports the error but the driver may still create the object.
  if bad_r == 0 {
    (dfn.vkDestroyBuffer)(dev, bad_out[0], na)
  }
  bad.free()

  // cleanup
  (dfn.vkDestroyFence)(dev, fence[0], na)
  (dfn.vkDestroySemaphore)(dev, img_avail[0], na)
  (dfn.vkDestroySemaphore)(dev, render_done[0], na)
  (dfn.vkDestroyCommandPool)(dev, pool_out[0], na)
  for i = 0; i < nimg; i = i + 1 {
    (dfn.vkDestroyImageView)(dev, views[i], na)
  }
  (dfn.vkDestroyPipeline)(dev, pipeline, na)
  (dfn.vkDestroyPipelineLayout)(dev, pl_out[0], na)
  (dfn.vkDestroyShaderModule)(dev, vsm_out[0], na)
  (dfn.vkDestroyShaderModule)(dev, fsm_out[0], na)
  if show_win {
    (dfn.vkDestroySwapchainKHR)(dev, swapchain, na)
    (ifn.vkDestroySurfaceKHR)(inst, surface, na)
  } else {
    (dfn.vkDestroyImage)(dev, images[0], na)
    (dfn.vkFreeMemory)(dev, off_mem, na)
  }
  (dfn.vkDestroyDevice)(dev, na)
  @vk.destroy_debug_messenger(inst, ifn, messenger)
  (ifn.vkDestroyInstance)(inst, na)
  if show_win {
    @win.destroy(win)
    @win.terminate()
  }
  si2.free()
  wait_si.free()
  signal_si.free()
  cmd_si.free()
  present.free()
  prci.free()
  f13.free()
  f2.free()
  f13q.free()
  range.free()
  // VK_SUBOPTIMAL_KHR (1000001003) still means the frame was presented.
  if rendered > 0 && render_errors == 0 && provoked > 0 && (pr == 0 || pr == 1000001003) {
    println(
      "[14-dyn] OK — dynamic rendering + sync2 drew \{rendered} pixels over \{frames} frames, 0 validation errors, messenger proven live",
    )
  } else {
    println(
      "[14-dyn] FAIL — rendered=\{rendered} render_errors=\{render_errors} provoked=\{provoked} present=\{pr}",
    )
  }
}