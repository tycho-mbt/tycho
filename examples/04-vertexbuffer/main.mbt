// Example 04 — Vertex buffers (vulkan-tutorial.com/Vertex_buffers).
// Vertex input descriptions + vertex/staging buffers + device memory + copy command.
// Memory-type selection uses the generated nested/array getters (pure MoonBit).

///|
fn find_memory_type(
  memprops : @vk.VkPhysicalDeviceMemoryProperties,
  typeBits : UInt32,
  props : UInt32,
) -> Int32 {
  let n = memprops.get_memoryTypeCount().reinterpret_as_int()
  for i = 0; i < n; i = i + 1 {
    if (typeBits & ((1 : UInt32) << i)) != (0 : UInt32) {
      if (memprops.get_memoryTypes_at(i).get_propertyFlags() & props) == props {
        return i
      }
    }
  }
  -1
}

///|
fn create_buffer(
  dev : @vk.VkDevice,
  dfn : @vk.DeviceFn,
  phys : @vk.VkPhysicalDevice,
  ifn : @vk.InstanceFn,
  size : UInt64,
  usage : UInt32,
  mem_flags : UInt32,
) -> (@vk.VkBuffer, @vk.VkDeviceMemory) {
  let na = @vk.VkAllocationCallbacks::null()
  let bci = @vk.VkBufferCreateInfo::new()
  bci.set_size(size)
  bci.set_usage(usage)
  bci.set_sharingMode((0 : UInt32))
  let buf_out = FixedArray::make(1, @vk.VkBuffer::null())
  let _ = (dfn.vkCreateBuffer)(dev, bci, na, buf_out)
  let req = @vk.VkMemoryRequirements::new()
  (dfn.vkGetBufferMemoryRequirements)(dev, buf_out[0], req)
  let memprops = @vk.VkPhysicalDeviceMemoryProperties::new()
  (ifn.vkGetPhysicalDeviceMemoryProperties)(phys, memprops)
  let idx = find_memory_type(memprops, req.get_memoryTypeBits(), mem_flags)
  let mai = @vk.VkMemoryAllocateInfo::new()
  mai.set_allocationSize(req.get_size())
  mai.set_memoryTypeIndex(idx.reinterpret_as_uint())
  let mem_out = FixedArray::make(1, @vk.VkDeviceMemory::null())
  let _ = (dfn.vkAllocateMemory)(dev, mai, na, mem_out)
  let _ = (dfn.vkBindBufferMemory)(dev, buf_out[0], mem_out[0], (0 : UInt64))
  bci.free()
  req.free()
  memprops.free()
  mai.free()
  (buf_out[0], mem_out[0])
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
  ici.set_usage(
    @vk.VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT |
    @vk.VK_IMAGE_USAGE_TRANSFER_SRC_BIT,
  )
  ici.set_sharingMode(@vk.VK_SHARING_MODE_EXCLUSIVE)
  let img_out = FixedArray::make(1, @vk.VkImage::null())
  let _ = (dfn.vkCreateImage)(dev, ici, na, img_out)
  let req = @vk.VkMemoryRequirements::new()
  (dfn.vkGetImageMemoryRequirements)(dev, img_out[0], req)
  let mp = @vk.VkPhysicalDeviceMemoryProperties::new()
  (ifn.vkGetPhysicalDeviceMemoryProperties)(phys, mp)
  let mt = find_memory_type(
    mp,
    req.get_memoryTypeBits(),
    @vk.VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT,
  )
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
  w : Int32,
  h : Int32,
) -> FixedArray[Byte] {
  let na = @vk.VkAllocationCallbacks::null()
  let bytes = w * h * 4
  let (buf, mem) = create_buffer(
    dev,
    dfn,
    phys,
    ifn,
    bytes.to_uint64(),
    @vk.VK_BUFFER_USAGE_TRANSFER_DST_BIT,
    @vk.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT |
    @vk.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT,
  )
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
    buf,
    (1 : UInt32),
    region,
  )
  let _ = (dfn.vkEndCommandBuffer)(cmd_out[0])
  let si = @vk.VkSubmitInfo::new()
  si.set_commandBufferCount((1 : UInt32))
  si.set_pCommandBuffers(cmd_out)
  let _ = (dfn.vkQueueSubmit)(queue, (1 : UInt32), si, @vk.VkFence::null())
  let _ = (dfn.vkQueueWaitIdle)(queue)
  let raw = @vk.download_buffer(dev, mem, bytes)
  let out = FixedArray::makei(raw.length(), fn(i) { raw[i] })
  (dfn.vkFreeCommandBuffers)(dev, pool, (1 : UInt32), cmd_out)
  (dfn.vkDestroyBuffer)(dev, buf, na)
  (dfn.vkFreeMemory)(dev, mem, na)
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
  app.set_pApplicationName(@vk.cstr("Vertex Buffer"))
  app.set_apiVersion((4194304 : UInt32))
  let ici = @vk.VkInstanceCreateInfo::new()
  ici.set_pApplicationInfo(app)
  if show_win {
    ici.set_enabledExtensionCount((3 : UInt32))
    ici.set_ppEnabledExtensionNames(@vk.cstr_array(@win.surface_extensions()))
  }
  let inst_out = FixedArray::make(1, @vk.VkInstance::null())
  let _ = @vk.vkCreateInstance(ici, na, inst_out)
  let inst = inst_out[0]
  let ifn = @vk.InstanceFn::load(inst)
  let pc = FixedArray::make(1, (16 : UInt32))
  let pdevs = FixedArray::make(16, @vk.VkPhysicalDevice::null())
  let _ = (ifn.vkEnumeratePhysicalDevices)(inst, pc, pdevs)
  let phys = pdevs[0]
  let prio = FixedArray::make(1, (1.0 : Float))
  let qci = @vk.VkDeviceQueueCreateInfo::new()
  qci.set_queueFamilyIndex((0 : UInt32))
  qci.set_queueCount((1 : UInt32))
  qci.set_pQueuePriorities(prio)
  let dci = @vk.VkDeviceCreateInfo::new()
  dci.set_queueCreateInfoCount((1 : UInt32))
  dci.set_pQueueCreateInfos(qci)
  if show_win {
    dci.set_enabledExtensionCount((1 : UInt32))
    dci.set_ppEnabledExtensionNames(@vk.cstr_array(["VK_KHR_swapchain"]))
  }
  let dev_out = FixedArray::make(1, @vk.VkDevice::null())
  let _ = (ifn.vkCreateDevice)(phys, dci, na, dev_out)
  let dev = dev_out[0]
  let dfn = @vk.DeviceFn::load(dev)
  let queue_out = FixedArray::make(1, @vk.VkQueue::null())
  (dfn.vkGetDeviceQueue)(dev, (0 : UInt32), (0 : UInt32), queue_out)
  let queue = queue_out[0]

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
  if show_win {
    let _ = @win.initialize()
    win = @win.create((800 : Int32), (600 : Int32), "Tycho-Example")
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
    let _ = (ifn.vkGetPhysicalDeviceSurfaceFormatsKHR)(
      phys, surface, fc, formats,
    )
    format = formats.get_format_at(0)
    let swci = @vk.VkSwapchainCreateInfoKHR::new()
    swci.set_surface(surface)
    swci.set_minImageCount(caps.get_minImageCount())
    swci.set_imageFormat(format)
    swci.set_imageColorSpace(formats.get_colorSpace_at(0))
    swci.set_imageExtent(extent)
    swci.set_imageArrayLayers((1 : UInt32))
    swci.set_imageUsage(
      @vk.VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT |
      @vk.VK_IMAGE_USAGE_TRANSFER_SRC_BIT,
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
      let range = @vk.VkImageSubresourceRange::new()
      range.set_aspectMask(@vk.VK_IMAGE_ASPECT_COLOR_BIT)
      range.set_levelCount((1 : UInt32))
      range.set_layerCount((1 : UInt32))
      let ivci = @vk.VkImageViewCreateInfo::new()
      ivci.set_image(images[i])
      ivci.set_viewType(@vk.VK_IMAGE_VIEW_TYPE_2D)
      ivci.set_format(format)
      ivci.set_subresourceRange(range)
      let iv_out = FixedArray::make(1, @vk.VkImageView::null())
      let _ = (dfn.vkCreateImageView)(dev, ivci, na, iv_out)
      views[i] = iv_out[0]
      ivci.free()
      range.free()
    }
  } else {
    let (oi, om, ov) = create_offscreen(
      dev,
      dfn,
      phys,
      ifn,
      format,
      (800 : UInt32),
      (600 : UInt32),
    )
    images[0] = oi
    off_mem = om
    views[0] = ov
  }

  // --- Vertex buffer (pos vec2 + color vec3, 3 vertices) ---
  let vertices : FixedArray[Float] = [
    0.0, -0.5, 1.0, 0.0, 0.0, 0.5, 0.5, 0.0, 1.0, 0.0, -0.5, 0.5, 0.0, 0.0, 1.0,
  ]
  let vbytes : Int32 = 60
  let (staging_buf, staging_mem) = create_buffer(
    dev,
    dfn,
    phys,
    ifn,
    60,
    (1 : UInt32),
    (6 : UInt32),
  )
  let ur = @vk.upload_buffer(dev, staging_mem, vertices, vbytes)
  let (vertex_buf, vertex_mem) = create_buffer(
    dev,
    dfn,
    phys,
    ifn,
    60,
    (130 : UInt32),
    (1 : UInt32),
  )
  println("[04-vbuf] upload=\{ur} vertex buffer created")
  // copy staging -> vertex via single-time command buffer
  let cpci = @vk.VkCommandPoolCreateInfo::new()
  cpci.set_queueFamilyIndex((0 : UInt32))
  let pool_out = FixedArray::make(1, @vk.VkCommandPool::null())
  let _ = (dfn.vkCreateCommandPool)(dev, cpci, na, pool_out)
  let cbai = @vk.VkCommandBufferAllocateInfo::new()
  cbai.set_commandPool(pool_out[0])
  cbai.set_level(@vk.VK_COMMAND_BUFFER_LEVEL_PRIMARY)
  cbai.set_commandBufferCount((1 : UInt32))
  let copy_cmd = FixedArray::make(1, @vk.VkCommandBuffer::null())
  let _ = (dfn.vkAllocateCommandBuffers)(dev, cbai, copy_cmd)
  let cbi = @vk.VkCommandBufferBeginInfo::new()
  cbi.set_flags(@vk.VK_FENCE_CREATE_SIGNALED_BIT) // ONE_TIME_SUBMIT
  let _ = (dfn.vkBeginCommandBuffer)(copy_cmd[0], cbi)
  let region = @vk.VkBufferCopy::new()
  region.set_size((60 : UInt64))
  (dfn.vkCmdCopyBuffer)(
    copy_cmd[0],
    staging_buf,
    vertex_buf,
    (1 : UInt32),
    region,
  )
  let _ = (dfn.vkEndCommandBuffer)(copy_cmd[0])
  let copy_submit = @vk.VkSubmitInfo::new()
  copy_submit.set_commandBufferCount((1 : UInt32))
  copy_submit.set_pCommandBuffers(copy_cmd)
  let _ = (dfn.vkQueueSubmit)(
    queue,
    (1 : UInt32),
    copy_submit,
    @vk.VkFence::null(),
  )
  let _ = (dfn.vkQueueWaitIdle)(queue)
  (dfn.vkFreeCommandBuffers)(dev, pool_out[0], (1 : UInt32), copy_cmd)
  (dfn.vkDestroyCommandPool)(dev, pool_out[0], na)
  (dfn.vkDestroyBuffer)(dev, staging_buf, na)
  (dfn.vkFreeMemory)(dev, staging_mem, na)
  region.free()
  cbi.free()
  copy_submit.free()
  cbai.free()
  cpci.free()

  // --- Render pass ---
  let attachment = @vk.VkAttachmentDescription::new()
  attachment.set_format(format)
  attachment.set_samples(@vk.VK_SAMPLE_COUNT_1_BIT)
  attachment.set_loadOp(@vk.VK_ATTACHMENT_LOAD_OP_CLEAR)
  attachment.set_storeOp(@vk.VK_ATTACHMENT_STORE_OP_STORE)
  attachment.set_stencilLoadOp(@vk.VK_ATTACHMENT_LOAD_OP_DONT_CARE)
  attachment.set_stencilStoreOp(@vk.VK_ATTACHMENT_STORE_OP_DONT_CARE)
  attachment.set_initialLayout(@vk.VK_IMAGE_LAYOUT_UNDEFINED)
  attachment.set_finalLayout(
    if show_win {
      @vk.VK_IMAGE_LAYOUT_PRESENT_SRC_KHR
    } else {
      @vk.VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL
    },
  )
  let att_ref = @vk.VkAttachmentReference::new()
  att_ref.set_attachment((0 : UInt32))
  att_ref.set_layout(@vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL)
  let subpass = @vk.VkSubpassDescription::new()
  subpass.set_pipelineBindPoint(@vk.VK_PIPELINE_BIND_POINT_GRAPHICS)
  subpass.set_colorAttachmentCount((1 : UInt32))
  subpass.set_pColorAttachments(att_ref)
  let dependency = @vk.VkSubpassDependency::new()
  dependency.set_srcSubpass((0xFFFFFFFF : UInt32))
  dependency.set_dstSubpass((0 : UInt32))
  dependency.set_srcStageMask(@vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT)
  dependency.set_dstStageMask(@vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT)
  dependency.set_dstAccessMask(@vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT)
  let rpci = @vk.VkRenderPassCreateInfo::new()
  rpci.set_attachmentCount((1 : UInt32))
  rpci.set_pAttachments(attachment)
  rpci.set_subpassCount((1 : UInt32))
  rpci.set_pSubpasses(subpass)
  rpci.set_dependencyCount((1 : UInt32))
  rpci.set_pDependencies(dependency)
  let rp_out = FixedArray::make(1, @vk.VkRenderPass::null())
  let _ = (dfn.vkCreateRenderPass)(dev, rpci, na, rp_out)
  let render_pass = rp_out[0]

  // --- Pipeline with vertex input ---
  let vert_code = @shader.compile_shader_file(
    "examples/04-vertexbuffer/shader.vert",
    @shader.SHADER_KIND_VERTEX,
  )
  let frag_code = @shader.compile_shader_file(
    "examples/04-vertexbuffer/shader.frag",
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
  let binding = @vk.VkVertexInputBindingDescription::new()
  binding.set_binding((0 : UInt32))
  binding.set_stride((20 : UInt32))
  binding.set_inputRate((0 : UInt32))
  let attrs = @vk.VkVertexInputAttributeDescription::array(2)
  attrs.set_location_at(0, (0 : UInt32))
  attrs.set_binding_at(0, (0 : UInt32))
  attrs.set_format_at(0, (103 : UInt32)) // R32G32_SFLOAT
  attrs.set_offset_at(0, (0 : UInt32))
  attrs.set_location_at(1, (1 : UInt32))
  attrs.set_binding_at(1, (0 : UInt32))
  attrs.set_format_at(1, (106 : UInt32)) // R32G32B32_SFLOAT
  attrs.set_offset_at(1, (8 : UInt32))
  let vertex_input = @vk.VkPipelineVertexInputStateCreateInfo::new()
  vertex_input.set_vertexBindingDescriptionCount((1 : UInt32))
  vertex_input.set_pVertexBindingDescriptions(binding)
  vertex_input.set_vertexAttributeDescriptionCount((2 : UInt32))
  vertex_input.set_pVertexAttributeDescriptions(attrs)
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
  rasterizer.set_cullMode(@vk.VK_CULL_MODE_BACK_BIT)
  rasterizer.set_frontFace(@vk.VK_FRONT_FACE_CLOCKWISE) // CW: matches this vertex order; cull BACK keeps it
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
  let gpci = @vk.VkGraphicsPipelineCreateInfo::new()
  gpci.set_stageCount((2 : UInt32))
  gpci.set_pStages(stages)
  gpci.set_pVertexInputState(vertex_input)
  gpci.set_pInputAssemblyState(input_assembly)
  gpci.set_pViewportState(viewport_state)
  gpci.set_pRasterizationState(rasterizer)
  gpci.set_pMultisampleState(multisample)
  gpci.set_pColorBlendState(color_blend)
  gpci.set_layout(pl_out[0])
  gpci.set_renderPass(render_pass)
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
  println("[04-vbuf] graphics pipeline (vertex input) = \{gpr}")

  // --- Framebuffers + command buffers ---
  let framebuffers = FixedArray::make(nimg, @vk.VkFramebuffer::null())
  for i = 0; i < nimg; i = i + 1 {
    let atts = FixedArray::make(1, views[i])
    let fbci = @vk.VkFramebufferCreateInfo::new()
    fbci.set_renderPass(render_pass)
    fbci.set_attachmentCount((1 : UInt32))
    fbci.set_pAttachments(atts)
    fbci.set_width((800 : UInt32))
    fbci.set_height((600 : UInt32))
    fbci.set_layers((1 : UInt32))
    let fb_out = FixedArray::make(1, @vk.VkFramebuffer::null())
    let _ = (dfn.vkCreateFramebuffer)(dev, fbci, na, fb_out)
    framebuffers[i] = fb_out[0]
    fbci.free()
  }
  let cpci2 = @vk.VkCommandPoolCreateInfo::new()
  cpci2.set_queueFamilyIndex((0 : UInt32))
  let pool2 = FixedArray::make(1, @vk.VkCommandPool::null())
  let _ = (dfn.vkCreateCommandPool)(dev, cpci2, na, pool2)
  let cmd_buffers = FixedArray::make(nimg, @vk.VkCommandBuffer::null())
  let cbai2 = @vk.VkCommandBufferAllocateInfo::new()
  cbai2.set_commandPool(pool2[0])
  cbai2.set_level(@vk.VK_COMMAND_BUFFER_LEVEL_PRIMARY)
  cbai2.set_commandBufferCount(nimg.reinterpret_as_uint())
  let _ = (dfn.vkAllocateCommandBuffers)(dev, cbai2, cmd_buffers)
  let clear_value = @vk.VkClearValue::new()
  clear_value.set_color_rgba(
    (0.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (1.0 : Float),
  )
  let render_area = @vk.VkRect2D::new()
  render_area.set_extent(extent)
  let vbuffers = FixedArray::make(1, vertex_buf)
  let voffsets = FixedArray::make(1, (0 : UInt64))
  for i = 0; i < nimg; i = i + 1 {
    let cbi2 = @vk.VkCommandBufferBeginInfo::new()
    let _ = (dfn.vkBeginCommandBuffer)(cmd_buffers[i], cbi2)
    let rpbi = @vk.VkRenderPassBeginInfo::new()
    rpbi.set_renderPass(render_pass)
    rpbi.set_framebuffer(framebuffers[i])
    rpbi.set_renderArea(render_area)
    rpbi.set_clearValueCount((1 : UInt32))
    rpbi.set_pClearValues(clear_value)
    (dfn.vkCmdBeginRenderPass)(cmd_buffers[i], rpbi, (0 : UInt32))
    (dfn.vkCmdBindPipeline)(
      cmd_buffers[i],
      @vk.VK_PIPELINE_BIND_POINT_GRAPHICS,
      pipeline,
    )
    (dfn.vkCmdBindVertexBuffers)(
      cmd_buffers[i],
      (0 : UInt32),
      (1 : UInt32),
      vbuffers,
      voffsets,
    )
    (dfn.vkCmdDraw)(
      cmd_buffers[i],
      (3 : UInt32),
      (1 : UInt32),
      (0 : UInt32),
      (0 : UInt32),
    )
    (dfn.vkCmdEndRenderPass)(cmd_buffers[i])
    let _ = (dfn.vkEndCommandBuffer)(cmd_buffers[i])
    cbi2.free()
    rpbi.free()
  }

  // --- Sync + draw + present ---
  let semci = @vk.VkSemaphoreCreateInfo::new()
  let img_avail = FixedArray::make(1, @vk.VkSemaphore::null())
  let render_done = FixedArray::make(1, @vk.VkSemaphore::null())
  let _ = (dfn.vkCreateSemaphore)(dev, semci, na, img_avail)
  let _ = (dfn.vkCreateSemaphore)(dev, semci, na, render_done)
  let fci = @vk.VkFenceCreateInfo::new()
  fci.set_flags(@vk.VK_FENCE_CREATE_SIGNALED_BIT)
  let fence = FixedArray::make(1, @vk.VkFence::null())
  let _ = (dfn.vkCreateFence)(dev, fci, na, fence)
  let _ = (dfn.vkWaitForFences)(
    dev,
    (1 : UInt32),
    fence,
    (1 : UInt32),
    (0xFFFFFFFFFFFFFFFF : UInt64),
  )
  let img_idx = FixedArray::make(1, (0 : UInt32))
  let mut ar = 0
  let mut sr = 0
  let mut pr = 0
  let mut rendered = (0 : UInt32)
  if show_win {
    let _ = (dfn.vkWaitForFences)(
      dev,
      (1 : UInt32),
      fence,
      (1 : UInt32),
      (0xFFFFFFFFFFFFFFFF : UInt64),
    )
    ar = (dfn.vkAcquireNextImageKHR)(
      dev,
      swapchain,
      (0xFFFFFFFFFFFFFFFF : UInt64),
      img_avail[0],
      @vk.VkFence::null(),
      img_idx,
    )
    let _ = (dfn.vkResetFences)(dev, (1 : UInt32), fence)
    let submit = @vk.VkSubmitInfo::new()
    submit.set_waitSemaphoreCount((1 : UInt32))
    submit.set_pWaitSemaphores(FixedArray::make(1, img_avail[0]))
    submit.set_pWaitDstStageMask(
      FixedArray::make(1, @vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT),
    )
    submit.set_commandBufferCount((1 : UInt32))
    submit.set_pCommandBuffers(
      FixedArray::make(1, cmd_buffers[img_idx[0].reinterpret_as_int()]),
    )
    submit.set_signalSemaphoreCount((1 : UInt32))
    submit.set_pSignalSemaphores(FixedArray::make(1, render_done[0]))
    sr = (dfn.vkQueueSubmit)(queue, (1 : UInt32), submit, fence[0])
    let _ = (dfn.vkQueueWaitIdle)(queue)
    rendered = @vk.count_rendered(
      dev,
      phys,
      queue,
      pool2[0],
      images[img_idx[0].reinterpret_as_int()],
      (800 : UInt32),
      (600 : UInt32),
    )
    if shot != "" {
      let px = @vk.readback_image(
        dev,
        phys,
        queue,
        pool2[0],
        images[img_idx[0].reinterpret_as_int()],
        (800 : UInt32),
        (600 : UInt32),
      )
      let _ = @shader.save_png(
        shot,
        800,
        600,
        px,
        bgra=format == @vk.VK_FORMAT_B8G8R8A8_UNORM,
      )
    }
    println("[render] non-zero pixels=\{rendered}/480000")
    let present = @vk.VkPresentInfoKHR::new()
    present.set_waitSemaphoreCount((1 : UInt32))
    present.set_pWaitSemaphores(FixedArray::make(1, render_done[0]))
    present.set_swapchainCount((1 : UInt32))
    present.set_pSwapchains(FixedArray::make(1, swapchain))
    present.set_pImageIndices(img_idx)
    pr = (dfn.vkQueuePresentKHR)(queue, present)
    let _ = (dfn.vkDeviceWaitIdle)(dev)
    println("[04-vbuf] acquire=\{ar} submit=\{sr} present=\{pr} (0=VK_SUCCESS)")
    while @win.should_close(win) == 0 {
      @win.poll()
    }
  } else {
    let _ = (dfn.vkResetFences)(dev, (1 : UInt32), fence)
    let submit = @vk.VkSubmitInfo::new()
    submit.set_commandBufferCount((1 : UInt32))
    submit.set_pCommandBuffers(FixedArray::make(1, cmd_buffers[0]))
    sr = (dfn.vkQueueSubmit)(queue, (1 : UInt32), submit, fence[0])
    let _ = (dfn.vkQueueWaitIdle)(queue)
    let px = readback_offscreen(
      dev,
      dfn,
      phys,
      ifn,
      queue,
      pool2[0],
      images[0],
      800,
      600,
    )
    rendered = count_rgb_pixels(px)
    if shot != "" {
      let _ = @shader.save_png(shot, 800, 600, px)
    }
    println("[render] non-zero pixels=\{rendered}/480000")
  }

  // --- Cleanup ---
  (dfn.vkDestroyFence)(dev, fence[0], na)
  (dfn.vkDestroySemaphore)(dev, img_avail[0], na)
  (dfn.vkDestroySemaphore)(dev, render_done[0], na)
  (dfn.vkDestroyCommandPool)(dev, pool2[0], na)
  for i = 0; i < nimg; i = i + 1 {
    (dfn.vkDestroyFramebuffer)(dev, framebuffers[i], na)
    (dfn.vkDestroyImageView)(dev, views[i], na)
  }
  (dfn.vkDestroyPipeline)(dev, pipeline, na)
  (dfn.vkDestroyPipelineLayout)(dev, pl_out[0], na)
  (dfn.vkDestroyRenderPass)(dev, render_pass, na)
  (dfn.vkDestroyShaderModule)(dev, vsm_out[0], na)
  (dfn.vkDestroyShaderModule)(dev, fsm_out[0], na)
  (dfn.vkDestroyBuffer)(dev, vertex_buf, na)
  (dfn.vkFreeMemory)(dev, vertex_mem, na)
  if show_win {
    (dfn.vkDestroySwapchainKHR)(dev, swapchain, na)
    (ifn.vkDestroySurfaceKHR)(inst, surface, na)
  } else {
    (dfn.vkDestroyImage)(dev, images[0], na)
    (dfn.vkFreeMemory)(dev, off_mem, na)
  }
  (dfn.vkDestroyDevice)(dev, na)
  (ifn.vkDestroyInstance)(inst, na)
  if show_win {
    @win.destroy(win)
    @win.terminate()
  }
  // Judge on the pipeline/acquire/submit/present results and the read-back pixel
  // count instead of printing OK unconditionally.
  // VK_SUBOPTIMAL_KHR (1000001003) still means the frame was presented.
  if gpr == 0 &&
    ar == 0 &&
    sr == 0 &&
    (pr == 0 || pr == 1000001003) &&
    rendered > 0 {
    println("[04-vbuf] OK — vertex buffer chapter validated")
  } else {
    println(
      "[04-vbuf] FAIL — pipeline=\{gpr} acquire=\{ar} submit=\{sr} present=\{pr} pixels=\{rendered}",
    )
  }
}
