// vulkan/mesh — mesh shaders (VK_EXT_mesh_shader): no vertex input, no input
// assembly; the mesh stage emits primitives directly. Covers direct, indirect
// and indirect-count mesh draws. Eighth coverage batch.

///|
let na : @vk.VkAllocationCallbacks = @vk.VkAllocationCallbacks::null()

///|
let g_errors : Ref[Int] = { val: 0 }

///|
fn main {
  let app = @vk.VkApplicationInfo::new()
  app.set_pApplicationName(@vk.cstr("Tycho Mesh"))
  app.set_apiVersion((4206592 : UInt32))
  let ici = @vk.VkInstanceCreateInfo::new()
  ici.set_pApplicationInfo(app)
  ici.set_enabledLayerCount((1 : UInt32))
  ici.set_ppEnabledLayerNames(@vk.cstr_array(["VK_LAYER_KHRONOS_validation"]))
  ici.set_enabledExtensionCount((1 : UInt32))
  ici.set_ppEnabledExtensionNames(@vk.cstr_array(["VK_EXT_debug_utils"]))
  let inst_out = FixedArray::make(1, @vk.VkInstance::null())
  let ir = @vk.vkCreateInstance(ici, na, inst_out)
  if ir != 0 {
    println("[vulkan/mesh] FAIL — vkCreateInstance=\{ir}")
    return
  }
  let inst = inst_out[0]
  let ifn = @vk.InstanceFn::load(inst)
  let messenger = @vk.create_debug_messenger(
    inst, ifn,
    @vk.VK_DEBUG_UTILS_MESSAGE_SEVERITY_ERROR_BIT_EXT,
    @vk.VK_DEBUG_UTILS_MESSAGE_TYPE_VALIDATION_BIT_EXT,
    (_s, _t, data, _u) => {
      g_errors.val = g_errors.val + 1
      println("[vulkan/mesh] VALIDATION: \{@vk.read_cstr(data.get_pMessage())}")
      (0 : UInt32)
    },
  )
  let pc = FixedArray::make(1, (16 : UInt32))
  let pdevs = FixedArray::make(16, @vk.VkPhysicalDevice::null())
  let _ = (ifn.vkEnumeratePhysicalDevices)(inst, pc, pdevs)
  let phys = pdevs[0]
  let mut n = 0
  let dec = FixedArray::make(1, (0 : UInt32))
  let _ = (ifn.vkEnumerateDeviceExtensionProperties)(phys, (0 : UInt64), dec, @vk.VkExtensionProperties::null())
  let dn = dec[0].reinterpret_as_int()
  let dexts = @vk.VkExtensionProperties::array(dn)
  let _ = (ifn.vkEnumerateDeviceExtensionProperties)(phys, (0 : UInt64), dec, dexts)
  let exts = FixedArray::make(dn, "")
  for i = 0; i < dn; i = i + 1 {
    exts[i] = dexts.get_extensionName_string_at(i)
  }
  let has_ext = fn(name : String) -> Bool {
    for i = 0; i < dn; i = i + 1 {
      if exts[i] == name {
        return true
      }
    }
    false
  }
  if !has_ext("VK_EXT_mesh_shader") {
    println("[vulkan/mesh] SKIP — VK_EXT_mesh_shader not supported")
    (ifn.vkDestroyInstance)(inst, na)
    return
  }
  let msq = @vk.VkPhysicalDeviceMeshShaderFeaturesEXT::new()
  let f13q = @vk.VkPhysicalDeviceVulkan13Features::new()
  let f12q = @vk.VkPhysicalDeviceVulkan12Features::new()
  msq.set_pNext(f12q.as_ptr())
  f12q.set_pNext(f13q.as_ptr())
  let fq = @vk.VkPhysicalDeviceFeatures2::new()
  fq.set_pNext(msq.as_ptr())
  (ifn.vkGetPhysicalDeviceFeatures2)(phys, fq)
  let ms = @vk.VkPhysicalDeviceMeshShaderFeaturesEXT::new()
  ms.set_meshShader(msq.get_meshShader())
  ms.set_taskShader(msq.get_taskShader())
  let f12 = @vk.VkPhysicalDeviceVulkan12Features::new()
  f12.set_drawIndirectCount(f12q.get_drawIndirectCount())
  let f13 = @vk.VkPhysicalDeviceVulkan13Features::new()
  f13.set_dynamicRendering((1 : UInt32))
  f13.set_synchronization2((1 : UInt32))
  f13.set_maintenance4((1 : UInt32))
  ms.set_pNext(f12.as_ptr())
  f12.set_pNext(f13.as_ptr())
  let want = ["VK_EXT_mesh_shader", "VK_KHR_dynamic_rendering", "VK_KHR_synchronization2", "VK_KHR_draw_indirect_count", "VK_EXT_extended_dynamic_state", "VK_KHR_maintenance4"]
  let den = FixedArray::make(want.length(), "")
  let mut nden = 0
  for i = 0; i < want.length(); i = i + 1 {
    if has_ext(want[i]) {
      den[nden] = want[i]
      nden = nden + 1
    }
  }
  let prio = FixedArray::make(1, (1.0 : Float))
  let qci = @vk.VkDeviceQueueCreateInfo::new()
  qci.set_queueFamilyIndex((0 : UInt32))
  qci.set_queueCount((1 : UInt32))
  qci.set_pQueuePriorities(prio)
  let dci = @vk.VkDeviceCreateInfo::new()
  dci.set_pNext(ms.as_ptr())
  dci.set_queueCreateInfoCount((1 : UInt32))
  dci.set_pQueueCreateInfos(qci)
  dci.set_enabledExtensionCount(nden.reinterpret_as_uint())
  dci.set_ppEnabledExtensionNames(@vk.cstr_array(den))
  let dev_out = FixedArray::make(1, @vk.VkDevice::null())
  let dr = (ifn.vkCreateDevice)(phys, dci, na, dev_out)
  if dr != 0 {
    println("[vulkan/mesh] FAIL — vkCreateDevice=\{dr}")
    return
  }
  let dev = dev_out[0]
  let dfn = @vk.DeviceFn::load(dev)
  let queue_out = FixedArray::make(1, @vk.VkQueue::null())
  (dfn.vkGetDeviceQueue)(dev, (0 : UInt32), (0 : UInt32), queue_out)
  let queue = queue_out[0]
  let has = fn(name : String) -> Bool {
    (ifn.vkGetDeviceProcAddr)(dev, @vk.cstr(name)) != (0 : UInt64)
  }
  let mp = @vk.VkPhysicalDeviceMemoryProperties::new()
  (ifn.vkGetPhysicalDeviceMemoryProperties)(phys, mp)
  let memtype = fn(bits : UInt32, props : UInt32) -> UInt32 {
    let mut mi = 0
    for i = 0; i < mp.get_memoryTypeCount().reinterpret_as_int(); i = i + 1 {
      if (bits & ((1 : UInt32) << i)) != (0 : UInt32) {
        if (mp.get_memoryTypes_at(i).get_propertyFlags() & props) == props {
          mi = i
          break
        }
      }
    }
    mi.reinterpret_as_uint()
  }
  let host = @vk.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | @vk.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT
  let dev_local = @vk.VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT
  let fmt = @vk.VK_FORMAT_R8G8B8A8_UNORM
  let w = 64

  // offscreen target
  let ici2 = @vk.VkImageCreateInfo::new()
  ici2.set_imageType(@vk.VK_IMAGE_TYPE_2D)
  ici2.set_format(fmt)
  let e3 = @vk.VkExtent3D::new()
  e3.set_width(w.reinterpret_as_uint())
  e3.set_height(w.reinterpret_as_uint())
  e3.set_depth((1 : UInt32))
  ici2.set_extent(e3)
  ici2.set_mipLevels((1 : UInt32))
  ici2.set_arrayLayers((1 : UInt32))
  ici2.set_samples(@vk.VK_SAMPLE_COUNT_1_BIT)
  ici2.set_tiling(@vk.VK_IMAGE_TILING_OPTIMAL)
  ici2.set_usage(@vk.VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT | @vk.VK_IMAGE_USAGE_TRANSFER_SRC_BIT)
  let img_out = FixedArray::make(1, @vk.VkImage::null())
  let _ = (dfn.vkCreateImage)(dev, ici2, na, img_out)
  let img = img_out[0]
  let ireq = @vk.VkMemoryRequirements::new()
  (dfn.vkGetImageMemoryRequirements)(dev, img, ireq)
  let imai = @vk.VkMemoryAllocateInfo::new()
  imai.set_allocationSize(ireq.get_size())
  imai.set_memoryTypeIndex(memtype(ireq.get_memoryTypeBits(), dev_local))
  let imem_out = FixedArray::make(1, @vk.VkDeviceMemory::null())
  let _ = (dfn.vkAllocateMemory)(dev, imai, na, imem_out)
  let _ = (dfn.vkBindImageMemory)(dev, img, imem_out[0], (0 : UInt64))
  let range = @vk.VkImageSubresourceRange::new()
  range.set_aspectMask(@vk.VK_IMAGE_ASPECT_COLOR_BIT)
  range.set_levelCount((1 : UInt32))
  range.set_layerCount((1 : UInt32))
  let ivci = @vk.VkImageViewCreateInfo::new()
  ivci.set_image(img)
  ivci.set_viewType(@vk.VK_IMAGE_VIEW_TYPE_2D)
  ivci.set_format(fmt)
  ivci.set_subresourceRange(range)
  let iv_out = FixedArray::make(1, @vk.VkImageView::null())
  let _ = (dfn.vkCreateImageView)(dev, ivci, na, iv_out)
  let view = iv_out[0]

  // mesh + fragment pipeline: no vertex input, no input assembly
  let meshc = @shader.compile_shader_file_env("examples/vulkan/mesh/shader.mesh", @shader.ShaderStage::Mesh, @shader.ShaderTarget::Vulkan13)
  let fragc = @shader.compile_shader_file_env("examples/vulkan/mesh/shader.frag", @shader.ShaderStage::Fragment, @shader.ShaderTarget::Vulkan13)
  if meshc.length() == 0 {
    println("[vulkan/mesh] FAIL — mesh shader did not compile")
    return
  }
  let msmci = @vk.VkShaderModuleCreateInfo::new()
  msmci.set_codeSize((meshc.length() * 4).to_uint64())
  msmci.set_pCode(meshc)
  let msm_out = FixedArray::make(1, @vk.VkShaderModule::null())
  let _ = (dfn.vkCreateShaderModule)(dev, msmci, na, msm_out)
  let fsmci = @vk.VkShaderModuleCreateInfo::new()
  fsmci.set_codeSize((fragc.length() * 4).to_uint64())
  fsmci.set_pCode(fragc)
  let fsm_out = FixedArray::make(1, @vk.VkShaderModule::null())
  let _ = (dfn.vkCreateShaderModule)(dev, fsmci, na, fsm_out)
  let stages = @vk.VkPipelineShaderStageCreateInfo::array(2)
  stages.set_stage_at(0, @vk.VK_SHADER_STAGE_MESH_BIT_EXT)
  stages.set_module_at(0, msm_out[0])
  stages.set_pName_at(0, @vk.cstr("main"))
  stages.set_stage_at(1, @vk.VK_SHADER_STAGE_FRAGMENT_BIT)
  stages.set_module_at(1, fsm_out[0])
  stages.set_pName_at(1, @vk.cstr("main"))
  let e2 = @vk.VkExtent2D::new()
  e2.set_width(w.reinterpret_as_uint())
  e2.set_height(w.reinterpret_as_uint())
  let vp = @vk.VkViewport::new()
  vp.set_width(Float::from_int(w))
  vp.set_height(Float::from_int(w))
  vp.set_maxDepth((1.0 : Float))
  let sc = @vk.VkRect2D::new()
  sc.set_extent(e2)
  let vpstate = @vk.VkPipelineViewportStateCreateInfo::new()
  vpstate.set_viewportCount((1 : UInt32))
  vpstate.set_pViewports(vp)
  vpstate.set_scissorCount((1 : UInt32))
  vpstate.set_pScissors(sc)
  let rast = @vk.VkPipelineRasterizationStateCreateInfo::new()
  rast.set_polygonMode(@vk.VK_POLYGON_MODE_FILL)
  rast.set_cullMode(@vk.VK_CULL_MODE_NONE)
  rast.set_frontFace(@vk.VK_FRONT_FACE_CLOCKWISE)
  rast.set_lineWidth((1.0 : Float))
  let mstate = @vk.VkPipelineMultisampleStateCreateInfo::new()
  mstate.set_rasterizationSamples(@vk.VK_SAMPLE_COUNT_1_BIT)
  let cba = @vk.VkPipelineColorBlendAttachmentState::new()
  cba.set_colorWriteMask(@vk.VK_COLOR_COMPONENT_R_BIT | @vk.VK_COLOR_COMPONENT_G_BIT | @vk.VK_COLOR_COMPONENT_B_BIT | @vk.VK_COLOR_COMPONENT_A_BIT)
  let cbstate = @vk.VkPipelineColorBlendStateCreateInfo::new()
  cbstate.set_attachmentCount((1 : UInt32))
  cbstate.set_pAttachments(cba)
  let plci = @vk.VkPipelineLayoutCreateInfo::new()
  let pl_out = FixedArray::make(1, @vk.VkPipelineLayout::null())
  let _ = (dfn.vkCreatePipelineLayout)(dev, plci, na, pl_out)
  let prci = @vk.VkPipelineRenderingCreateInfo::new()
  prci.set_colorAttachmentCount((1 : UInt32))
  prci.set_pColorAttachmentFormats(FixedArray::make(1, fmt))
  let gpci = @vk.VkGraphicsPipelineCreateInfo::new()
  gpci.set_pNext(prci.as_ptr())
  gpci.set_stageCount((2 : UInt32))
  gpci.set_pStages(stages)
  gpci.set_pViewportState(vpstate)
  gpci.set_pRasterizationState(rast)
  gpci.set_pMultisampleState(mstate)
  gpci.set_pColorBlendState(cbstate)
  gpci.set_layout(pl_out[0])
  let pipe_out = FixedArray::make(1, @vk.VkPipeline::null())
  let gpr = (dfn.vkCreateGraphicsPipelines)(dev, @vk.VkPipelineCache::null(), (1 : UInt32), gpci, na, pipe_out)
  if gpr != 0 {
    println("[vulkan/mesh] FAIL — mesh pipeline=\{gpr}")
    return
  }
  let pipe = pipe_out[0]

  // indirect buffers: VkDrawMeshTasksIndirectCommandEXT {x,y,z} + count
  let mkbuf = fn(size : UInt64, usage : UInt32) -> (@vk.VkBuffer, @vk.VkDeviceMemory) {
    let ci = @vk.VkBufferCreateInfo::new()
    ci.set_size(size)
    ci.set_usage(usage)
    let o = FixedArray::make(1, @vk.VkBuffer::null())
    let _ = (dfn.vkCreateBuffer)(dev, ci, na, o)
    let rq = @vk.VkMemoryRequirements::new()
    (dfn.vkGetBufferMemoryRequirements)(dev, o[0], rq)
    let ai = @vk.VkMemoryAllocateInfo::new()
    ai.set_allocationSize(rq.get_size())
    ai.set_memoryTypeIndex(memtype(rq.get_memoryTypeBits(), host))
    let mo = FixedArray::make(1, @vk.VkDeviceMemory::null())
    let _ = (dfn.vkAllocateMemory)(dev, ai, na, mo)
    let _ = (dfn.vkBindBufferMemory)(dev, o[0], mo[0], (0 : UInt64))
    ci.free()
    (o[0], mo[0])
  }
  let (ibuf, imem2) = mkbuf((64 : UInt64), @vk.VK_BUFFER_USAGE_INDIRECT_BUFFER_BIT)
  let (cbuf, cmem) = mkbuf((64 : UInt64), @vk.VK_BUFFER_USAGE_INDIRECT_BUFFER_BIT)
  let (rbuf, rmem) = mkbuf((w * w * 4).to_uint64(), @vk.VK_BUFFER_USAGE_TRANSFER_DST_BIT)
  let mcmd = FixedArray::make(3, (1 : UInt32))
  let _ = @vk.upload_uint32(dev, imem2, mcmd, 12)
  let cnt = FixedArray::make(1, (1 : UInt32))
  let _ = @vk.upload_uint32(dev, cmem, cnt, 4)

  let cpobj = @vk.VkCommandPoolCreateInfo::new()
  cpobj.set_queueFamilyIndex((0 : UInt32))
  let cp_out = FixedArray::make(1, @vk.VkCommandPool::null())
  let _ = (dfn.vkCreateCommandPool)(dev, cpobj, na, cp_out)
  let cbai = @vk.VkCommandBufferAllocateInfo::new()
  cbai.set_commandPool(cp_out[0])
  cbai.set_level(@vk.VK_COMMAND_BUFFER_LEVEL_PRIMARY)
  cbai.set_commandBufferCount((1 : UInt32))
  let cb_out = FixedArray::make(1, @vk.VkCommandBuffer::null())
  let _ = (dfn.vkAllocateCommandBuffers)(dev, cbai, cb_out)
  let cb = cb_out[0]
  let bi = @vk.VkCommandBufferBeginInfo::new()
  let _ = (dfn.vkBeginCommandBuffer)(cb, bi)
  let b2 = @vk.VkImageMemoryBarrier2::new()
  b2.set_srcStageMask(@vk.VK_PIPELINE_STAGE_2_TOP_OF_PIPE_BIT)
  b2.set_dstStageMask(@vk.VK_PIPELINE_STAGE_2_COLOR_ATTACHMENT_OUTPUT_BIT)
  b2.set_dstAccessMask(@vk.VK_ACCESS_2_COLOR_ATTACHMENT_WRITE_BIT)
  b2.set_oldLayout(@vk.VK_IMAGE_LAYOUT_UNDEFINED)
  b2.set_newLayout(@vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL)
  b2.set_srcQueueFamilyIndex((0xFFFFFFFF : UInt32))
  b2.set_dstQueueFamilyIndex((0xFFFFFFFF : UInt32))
  b2.set_image(img)
  b2.set_subresourceRange(range)
  let dep = @vk.VkDependencyInfo::new()
  dep.set_imageMemoryBarrierCount((1 : UInt32))
  dep.set_pImageMemoryBarriers(b2)
  (dfn.vkCmdPipelineBarrier2)(cb, dep)
  let cv = @vk.VkClearValue::new()
  cv.set_color_rgba((0.0 : Float), (0.0 : Float), (0.0 : Float), (1.0 : Float))
  let att = @vk.VkRenderingAttachmentInfo::new()
  att.set_imageView(view)
  att.set_imageLayout(@vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL)
  att.set_loadOp(@vk.VK_ATTACHMENT_LOAD_OP_CLEAR)
  att.set_storeOp(@vk.VK_ATTACHMENT_STORE_OP_STORE)
  att.set_clearValue(cv)
  let area = @vk.VkRect2D::new()
  area.set_extent(e2)
  let ri = @vk.VkRenderingInfo::new()
  ri.set_renderArea(area)
  ri.set_layerCount((1 : UInt32))
  ri.set_colorAttachmentCount((1 : UInt32))
  ri.set_pColorAttachments(att)
  (dfn.vkCmdBeginRendering)(cb, ri)
  (dfn.vkCmdBindPipeline)(cb, @vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe)
  if has("vkCmdDrawMeshTasksEXT") {
    (dfn.vkCmdDrawMeshTasksEXT)(cb, (1 : UInt32), (1 : UInt32), (1 : UInt32))
    n = n + 1
  }
  if has("vkCmdDrawMeshTasksIndirectEXT") {
    (dfn.vkCmdDrawMeshTasksIndirectEXT)(cb, ibuf, (0 : UInt64), (1 : UInt32), (12 : UInt32))
    n = n + 1
  }
  if has("vkCmdDrawMeshTasksIndirectCountEXT") {
    (dfn.vkCmdDrawMeshTasksIndirectCountEXT)(cb, ibuf, (0 : UInt64), cbuf, (0 : UInt64), (1 : UInt32), (12 : UInt32))
    n = n + 1
  }
  (dfn.vkCmdEndRendering)(cb)
  b2.set_srcStageMask(@vk.VK_PIPELINE_STAGE_2_COLOR_ATTACHMENT_OUTPUT_BIT)
  b2.set_srcAccessMask(@vk.VK_ACCESS_2_COLOR_ATTACHMENT_WRITE_BIT)
  b2.set_dstStageMask(@vk.VK_PIPELINE_STAGE_2_ALL_TRANSFER_BIT)
  b2.set_dstAccessMask(@vk.VK_ACCESS_2_TRANSFER_READ_BIT)
  b2.set_oldLayout(@vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL)
  b2.set_newLayout(@vk.VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL)
  (dfn.vkCmdPipelineBarrier2)(cb, dep)
  let bic = @vk.VkBufferImageCopy::new()
  let subl = @vk.VkImageSubresourceLayers::new()
  subl.set_aspectMask(@vk.VK_IMAGE_ASPECT_COLOR_BIT)
  subl.set_layerCount((1 : UInt32))
  bic.set_imageSubresource(subl)
  bic.set_imageExtent(e3)
  (dfn.vkCmdCopyImageToBuffer)(cb, img, @vk.VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL, rbuf, (1 : UInt32), bic)
  let _ = (dfn.vkEndCommandBuffer)(cb)
  let fci = @vk.VkFenceCreateInfo::new()
  let fence_out = FixedArray::make(1, @vk.VkFence::null())
  let _ = (dfn.vkCreateFence)(dev, fci, na, fence_out)
  let si = @vk.VkSubmitInfo::new()
  si.set_commandBufferCount((1 : UInt32))
  si.set_pCommandBuffers(cb_out)
  let sr = (dfn.vkQueueSubmit)(queue, (1 : UInt32), si, fence_out[0])
  let wr = (dfn.vkWaitForFences)(dev, (1 : UInt32), fence_out, (1 : UInt32), (10000000000 : UInt64))
  let px = @vk.download_buffer(dev, rmem, w * w * 4)
  let mut pixels = 0
  for i = 0; i < w * w; i = i + 1 {
    if px[i * 4] != (0 : Byte) || px[i * 4 + 1] != (0 : Byte) || px[i * 4 + 2] != (0 : Byte) {
      pixels = pixels + 1
    }
  }
  let _ = (dfn.vkDeviceWaitIdle)(dev)
  (dfn.vkDestroyFence)(dev, fence_out[0], na)
  (dfn.vkDestroyCommandPool)(dev, cp_out[0], na)
  (dfn.vkDestroyBuffer)(dev, ibuf, na)
  (dfn.vkFreeMemory)(dev, imem2, na)
  (dfn.vkDestroyBuffer)(dev, cbuf, na)
  (dfn.vkFreeMemory)(dev, cmem, na)
  (dfn.vkDestroyBuffer)(dev, rbuf, na)
  (dfn.vkFreeMemory)(dev, rmem, na)
  (dfn.vkDestroyPipeline)(dev, pipe, na)
  (dfn.vkDestroyPipelineLayout)(dev, pl_out[0], na)
  (dfn.vkDestroyShaderModule)(dev, msm_out[0], na)
  (dfn.vkDestroyShaderModule)(dev, fsm_out[0], na)
  (dfn.vkDestroyImageView)(dev, view, na)
  (dfn.vkDestroyImage)(dev, img, na)
  (dfn.vkFreeMemory)(dev, imem_out[0], na)
  (dfn.vkDestroyDevice)(dev, na)
  @vk.destroy_debug_messenger(inst, ifn, messenger)
  (ifn.vkDestroyInstance)(inst, na)
  println("[vulkan/mesh] commands=\{n} pixels=\{pixels} submit=\{sr} wait=\{wr} errors=\{g_errors.val}")
  if sr == 0 && wr == 0 && pixels > 0 && n >= 3 && g_errors.val == 0 {
    println("[vulkan/mesh] OK — \{n} mesh draw commands, \{pixels} pixels, 0 validation errors")
  } else {
    println("[vulkan/mesh] FAIL — pixels=\{pixels} n=\{n} errors=\{g_errors.val}")
  }
}