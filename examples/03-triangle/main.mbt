// Example 03 — Drawing a triangle (vulkan-tutorial.com/Drawing_a_triangle).
// Pure MoonBit binding. Verifies rendering by reading back rendered pixels.

///|
fn main {
  let na = @vk.VkAllocationCallbacks::null()
  let app = @vk.VkApplicationInfo::new()
  app.set_pApplicationName(@vk.cstr("Hello Triangle"))
  app.set_apiVersion((4194304 : UInt32))
  let ici = @vk.VkInstanceCreateInfo::new()
  ici.set_pApplicationInfo(app)
  ici.set_enabledLayerCount((1 : UInt32))
  ici.set_ppEnabledLayerNames(@vk.cstr_array(["VK_LAYER_KHRONOS_validation"]))
  ici.set_enabledExtensionCount((3 : UInt32))
  ici.set_ppEnabledExtensionNames(@vk.cstr_array(@win.surface_extensions()))
  let inst_out = FixedArray::make(1, @vk.VkInstance::null())
  let ir = @vk.vkCreateInstance(ici, na, inst_out)
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
  dci.set_enabledExtensionCount((1 : UInt32))
  dci.set_ppEnabledExtensionNames(@vk.cstr_array(["VK_KHR_swapchain"]))
  let dev_out = FixedArray::make(1, @vk.VkDevice::null())
  let dr = (ifn.vkCreateDevice)(phys, dci, na, dev_out)
  let dev = dev_out[0]
  let dfn = @vk.DeviceFn::load(dev)
  let queue_out = FixedArray::make(1, @vk.VkQueue::null())
  (dfn.vkGetDeviceQueue)(dev, (0 : UInt32), (0 : UInt32), queue_out)
  let queue = queue_out[0]
  println("[03-triangle] instance=\{ir} device=\{dr}")

  // surface + swapchain + views (windowing via GLFW)
  let _ = @win.initialize()
  let win = @win.create((800 : Int32), (600 : Int32), "Tycho-Example")
  let surface = @win.create_surface(inst, win)
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
  let format = formats.get_format_at(0)
  let extent = @vk.VkExtent2D::new()
  extent.set_width((800 : UInt32))
  extent.set_height((600 : UInt32))
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
  ) // COLOR_ATTACHMENT(16) | TRANSFER_SRC(1)
  swci.set_imageSharingMode(@vk.VK_SHARING_MODE_EXCLUSIVE)
  swci.set_preTransform(caps.get_currentTransform())
  swci.set_compositeAlpha(@vk.VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR)
  swci.set_presentMode(@vk.VK_PRESENT_MODE_FIFO_KHR)
  swci.set_clipped((1 : UInt32))
  let sc_out = FixedArray::make(1, @vk.VkSwapchainKHR::null())
  let _ = (dfn.vkCreateSwapchainKHR)(dev, swci, na, sc_out)
  let swapchain = sc_out[0]
  let ic = FixedArray::make(1, (8 : UInt32))
  let images = FixedArray::make(8, @vk.VkImage::null())
  let _ = (dfn.vkGetSwapchainImagesKHR)(dev, swapchain, ic, images)
  let nimg = ic[0].reinterpret_as_int()
  let views = FixedArray::make(nimg, @vk.VkImageView::null())
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

  // render pass
  let attachment = @vk.VkAttachmentDescription::new()
  attachment.set_format(format)
  attachment.set_samples(@vk.VK_SAMPLE_COUNT_1_BIT)
  attachment.set_loadOp(@vk.VK_ATTACHMENT_LOAD_OP_CLEAR) // CLEAR
  attachment.set_storeOp(@vk.VK_ATTACHMENT_STORE_OP_STORE) // STORE
  attachment.set_stencilLoadOp(@vk.VK_ATTACHMENT_LOAD_OP_DONT_CARE) // DONT_CARE (LoadOp)
  attachment.set_stencilStoreOp(@vk.VK_ATTACHMENT_STORE_OP_DONT_CARE) // DONT_CARE (StoreOp)
  attachment.set_initialLayout(@vk.VK_IMAGE_LAYOUT_UNDEFINED)
  attachment.set_finalLayout(@vk.VK_IMAGE_LAYOUT_PRESENT_SRC_KHR)
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

  // shader modules + pipeline
  let vert_code = @shader.compile_shader_file(
    "examples/03-triangle/shader.vert",
    @shader.SHADER_KIND_VERTEX,
  )
  let frag_code = @shader.compile_shader_file(
    "examples/03-triangle/shader.frag",
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
  rasterizer.set_cullMode(@vk.VK_CULL_MODE_BACK_BIT) // BACK
  rasterizer.set_frontFace(@vk.VK_FRONT_FACE_CLOCKWISE) // CCW: matches this vertex order in Vulkan framebuffer coords
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
  println("[03-triangle] graphics pipeline = \{gpr}")

  // framebuffers
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

  // command pool + buffers
  let cpci = @vk.VkCommandPoolCreateInfo::new()
  cpci.set_queueFamilyIndex((0 : UInt32))
  let pool_out = FixedArray::make(1, @vk.VkCommandPool::null())
  let _ = (dfn.vkCreateCommandPool)(dev, cpci, na, pool_out)
  let cmd_buffers = FixedArray::make(nimg, @vk.VkCommandBuffer::null())
  let cbai = @vk.VkCommandBufferAllocateInfo::new()
  cbai.set_commandPool(pool_out[0])
  cbai.set_level(@vk.VK_COMMAND_BUFFER_LEVEL_PRIMARY)
  cbai.set_commandBufferCount(nimg.reinterpret_as_uint())
  let _ = (dfn.vkAllocateCommandBuffers)(dev, cbai, cmd_buffers)

  // record command buffers
  let clear_value = @vk.VkClearValue::new()
  clear_value.set_color_rgba(
    (0.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (1.0 : Float),
  )
  let render_area = @vk.VkRect2D::new()
  render_area.set_extent(extent)
  for i = 0; i < nimg; i = i + 1 {
    let cbi = @vk.VkCommandBufferBeginInfo::new()
    let _ = (dfn.vkBeginCommandBuffer)(cmd_buffers[i], cbi)
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
    (dfn.vkCmdDraw)(
      cmd_buffers[i],
      (3 : UInt32),
      (1 : UInt32),
      (0 : UInt32),
      (0 : UInt32),
    )
    (dfn.vkCmdEndRenderPass)(cmd_buffers[i])
    let _ = (dfn.vkEndCommandBuffer)(cmd_buffers[i])
    cbi.free()
    rpbi.free()
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

  // draw + present loop: keep presenting while the window is open so the frame
  // stays on screen (a single present before teardown can be lost).
  let img_idx = FixedArray::make(1, (0 : UInt32))
  let wait_stages = FixedArray::make(
    1,
    @vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT,
  )
  let wait_sems = FixedArray::make(1, img_avail[0])
  let cmd_arr = FixedArray::make(1, @vk.VkCommandBuffer::null())
  let signal_sems = FixedArray::make(1, render_done[0])
  let submit = @vk.VkSubmitInfo::new()
  submit.set_waitSemaphoreCount((1 : UInt32))
  submit.set_pWaitSemaphores(wait_sems)
  submit.set_pWaitDstStageMask(wait_stages)
  submit.set_commandBufferCount((1 : UInt32))
  submit.set_pCommandBuffers(cmd_arr)
  submit.set_signalSemaphoreCount((1 : UInt32))
  submit.set_pSignalSemaphores(signal_sems)
  let present_sems = FixedArray::make(1, render_done[0])
  let swapchains = FixedArray::make(1, swapchain)
  let present = @vk.VkPresentInfoKHR::new()
  present.set_waitSemaphoreCount((1 : UInt32))
  present.set_pWaitSemaphores(present_sems)
  present.set_swapchainCount((1 : UInt32))
  present.set_pSwapchains(swapchains)
  present.set_pImageIndices(img_idx)
  let t0 = @win.time()
  let mut rendered = (0 : UInt32)
  let mut verified = false
  let mut pr = 0
  let mut ar = 0
  let mut sr = 0
  while @win.should_close(win) == 0 && @win.time() - t0 < 3.0 {
    @win.poll()
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
    cmd_arr[0] = cmd_buffers[img_idx[0].reinterpret_as_int()]
    sr = (dfn.vkQueueSubmit)(queue, (1 : UInt32), submit, fence[0])
    let _ = (dfn.vkQueueWaitIdle)(queue)
    if !verified {
      rendered = @vk.count_rendered(
        dev,
        phys,
        queue,
        pool_out[0],
        images[img_idx[0].reinterpret_as_int()],
        (800 : UInt32),
        (600 : UInt32),
      )
      verified = true
      println(
        "[03-triangle] acquire=\{ar} submit=\{sr} rendered pixels=\{rendered}/480000",
      )
    }
    pr = (dfn.vkQueuePresentKHR)(queue, present)
    let _ = (dfn.vkQueueWaitIdle)(queue)
  }
  let _ = (dfn.vkDeviceWaitIdle)(dev)
  println("[03-triangle] present=\{pr} (0=VK_SUCCESS)")
  submit.free()
  present.free()

  // cleanup
  (dfn.vkDestroyFence)(dev, fence[0], na)
  (dfn.vkDestroySemaphore)(dev, img_avail[0], na)
  (dfn.vkDestroySemaphore)(dev, render_done[0], na)
  (dfn.vkDestroyCommandPool)(dev, pool_out[0], na)
  for i = 0; i < nimg; i = i + 1 {
    (dfn.vkDestroyFramebuffer)(dev, framebuffers[i], na)
    (dfn.vkDestroyImageView)(dev, views[i], na)
  }
  (dfn.vkDestroyPipeline)(dev, pipeline, na)
  (dfn.vkDestroyPipelineLayout)(dev, pl_out[0], na)
  (dfn.vkDestroyRenderPass)(dev, render_pass, na)
  (dfn.vkDestroyShaderModule)(dev, vsm_out[0], na)
  (dfn.vkDestroyShaderModule)(dev, fsm_out[0], na)
  (dfn.vkDestroySwapchainKHR)(dev, swapchain, na)
  (ifn.vkDestroySurfaceKHR)(inst, surface, na)
  (dfn.vkDestroyDevice)(dev, na)
  (ifn.vkDestroyInstance)(inst, na)
  @win.destroy(win)
  @win.terminate()
  // VK_SUBOPTIMAL_KHR (1000001003) still means the frame was presented.
  if rendered > 0 && (pr == 0 || pr == 1000001003) {
    println(
      "[03-triangle] OK — triangle rendered (\{rendered} non-zero pixels) and presented",
    )
  } else {
    println("[03-triangle] FAIL — rendered=\{rendered} present=\{pr}")
  }
}
