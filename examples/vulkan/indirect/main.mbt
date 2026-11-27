// vulkan/indirect — the indirect draw family: vkCmdDrawIndirect,
// vkCmdDrawIndexedIndirect, both Count variants and vkCmdBindIndexBuffer2.
// Thirteenth coverage batch. Each draw command renders into its own image and
// the pixels are counted, so a silently ignored draw fails the gate.

///|
let na : @vk.VkAllocationCallbacks = @vk.VkAllocationCallbacks::null()

///|
let g_errors : Ref[Int] = { val: 0 }

///|
fn main {
  let mut n = 0
  let app = @vk.VkApplicationInfo::new()
  app.set_pApplicationName(@vk.cstr("Tycho Indirect"))
  app.set_apiVersion((4210688 : UInt32)) // 1.4 (vkCmdBindIndexBuffer2 is 1.4 core)
  let ici = @vk.VkInstanceCreateInfo::new()
  ici.set_pApplicationInfo(app)
  ici.set_enabledLayerCount((1 : UInt32))
  ici.set_ppEnabledLayerNames(@vk.cstr_array(["VK_LAYER_KHRONOS_validation"]))
  ici.set_enabledExtensionCount((1 : UInt32))
  ici.set_ppEnabledExtensionNames(@vk.cstr_array(["VK_EXT_debug_utils"]))
  let inst_out = FixedArray::make(1, @vk.VkInstance::null())
  let ir = @vk.vkCreateInstance(ici, na, inst_out)
  if ir != 0 {
    println("[27-ind] FAIL — vkCreateInstance=\{ir}")
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
      eprintln("[27-ind] VALIDATION: \{@vk.read_cstr(data.get_pMessage())}")
      (0 : UInt32)
    },
  )
  let pc = FixedArray::make(1, (16 : UInt32))
  let pdevs = FixedArray::make(16, @vk.VkPhysicalDevice::null())
  let _ = (ifn.vkEnumeratePhysicalDevices)(inst, pc, pdevs)
  let phys = pdevs[0]
  let dec = FixedArray::make(1, (0 : UInt32))
  let _ = (ifn.vkEnumerateDeviceExtensionProperties)(phys, (0 : UInt64), dec, @vk.VkExtensionProperties::null())
  let dn = dec[0].reinterpret_as_int()
  let dexts = @vk.VkExtensionProperties::array(dn)
  let _ = (ifn.vkEnumerateDeviceExtensionProperties)(phys, (0 : UInt64), dec, dexts)
  let exts = FixedArray::make(dn, "")
  for i = 0; i < dn; i = i + 1 {
    exts[i] = dexts.get_extensionName_string_at(i)
  }
  // dynamic rendering (1.3) and multi-draw indirect
  let f13 = @vk.VkPhysicalDeviceVulkan13Features::new()
  f13.set_dynamicRendering((1 : UInt32))
  f13.set_synchronization2((1 : UInt32))
  let f12 = @vk.VkPhysicalDeviceVulkan12Features::new()
  f12.set_drawIndirectCount((1 : UInt32))
  f12.set_pNext(f13.as_ptr())
  let feats = @vk.VkPhysicalDeviceFeatures::new()
  feats.set_multiDrawIndirect((1 : UInt32))
  let prio = FixedArray::make(1, (1.0 : Float))
  let qci = @vk.VkDeviceQueueCreateInfo::new()
  qci.set_queueFamilyIndex((0 : UInt32))
  qci.set_queueCount((1 : UInt32))
  qci.set_pQueuePriorities(prio)
  let dci = @vk.VkDeviceCreateInfo::new()
  dci.set_pNext(f12.as_ptr())
  dci.set_pEnabledFeatures(feats)
  dci.set_queueCreateInfoCount((1 : UInt32))
  dci.set_pQueueCreateInfos(qci)
  let dev_out = FixedArray::make(1, @vk.VkDevice::null())
  let dr = (ifn.vkCreateDevice)(phys, dci, na, dev_out)
  if dr != 0 {
    println("[27-ind] FAIL — vkCreateDevice=\{dr}")
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
  let memtype = fn(bits : UInt32, props : UInt32) -> Int {
    let mut mi = -1
    for i = 0; i < mp.get_memoryTypeCount().reinterpret_as_int(); i = i + 1 {
      if (bits & ((1 : UInt32) << i)) != (0 : UInt32) {
        if (mp.get_memoryTypes_at(i).get_propertyFlags() & props) == props {
          mi = i
          break
        }
      }
    }
    mi
  }
  let host = @vk.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | @vk.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT
  let devlocal = @vk.VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT
  let mkbuf = fn(size : UInt64, usage : UInt32, props : UInt32) -> (@vk.VkBuffer, @vk.VkDeviceMemory) {
    let ci = @vk.VkBufferCreateInfo::new()
    ci.set_size(size)
    ci.set_usage(usage)
    let o = FixedArray::make(1, @vk.VkBuffer::null())
    let _ = (dfn.vkCreateBuffer)(dev, ci, na, o)
    let rq = @vk.VkMemoryRequirements::new()
    (dfn.vkGetBufferMemoryRequirements)(dev, o[0], rq)
    let ai = @vk.VkMemoryAllocateInfo::new()
    ai.set_allocationSize(rq.get_size())
    ai.set_memoryTypeIndex(memtype(rq.get_memoryTypeBits(), props).reinterpret_as_uint())
    let mo = FixedArray::make(1, @vk.VkDeviceMemory::null())
    let _ = (dfn.vkAllocateMemory)(dev, ai, na, mo)
    let _ = (dfn.vkBindBufferMemory)(dev, o[0], mo[0], (0 : UInt64))
    ci.free()
    (o[0], mo[0])
  }
  let side = 64
  let sideu = (64 : UInt32)
  let px = (side * side * 4).to_uint64()

  // ---- pipeline with a static viewport ----
  let vert = @shader.compile_shader_file("examples/vulkan/indirect/shader.vert", @shader.SHADER_KIND_VERTEX)
  let frag = @shader.compile_shader_file("examples/vulkan/indirect/shader.frag", @shader.SHADER_KIND_FRAGMENT)
  let vsmci = @vk.VkShaderModuleCreateInfo::new()
  vsmci.set_codeSize((vert.length() * 4).to_uint64())
  vsmci.set_pCode(vert)
  let vsm_out = FixedArray::make(1, @vk.VkShaderModule::null())
  let _ = (dfn.vkCreateShaderModule)(dev, vsmci, na, vsm_out)
  let fsmci = @vk.VkShaderModuleCreateInfo::new()
  fsmci.set_codeSize((frag.length() * 4).to_uint64())
  fsmci.set_pCode(frag)
  let fsm_out = FixedArray::make(1, @vk.VkShaderModule::null())
  let _ = (dfn.vkCreateShaderModule)(dev, fsmci, na, fsm_out)
  let stages = @vk.VkPipelineShaderStageCreateInfo::array(2)
  stages.set_stage_at(0, @vk.VK_SHADER_STAGE_VERTEX_BIT)
  stages.set_module_at(0, vsm_out[0])
  stages.set_pName_at(0, @vk.cstr("main"))
  stages.set_stage_at(1, @vk.VK_SHADER_STAGE_FRAGMENT_BIT)
  stages.set_module_at(1, fsm_out[0])
  stages.set_pName_at(1, @vk.cstr("main"))
  let plci = @vk.VkPipelineLayoutCreateInfo::new()
  let pl_out = FixedArray::make(1, @vk.VkPipelineLayout::null())
  let _ = (dfn.vkCreatePipelineLayout)(dev, plci, na, pl_out)
  let layout = pl_out[0]
  let vinput = @vk.VkPipelineVertexInputStateCreateInfo::new()
  let iasm = @vk.VkPipelineInputAssemblyStateCreateInfo::new()
  iasm.set_topology(@vk.VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST)
  let vp = @vk.VkViewport::new()
  vp.set_width(Float::from_int(side))
  vp.set_height(Float::from_int(side))
  vp.set_minDepth((0.0 : Float))
  vp.set_maxDepth((1.0 : Float))
  let ext2 = @vk.VkExtent2D::new()
  ext2.set_width(sideu)
  ext2.set_height(sideu)
  let sc = @vk.VkRect2D::new()
  sc.set_extent(ext2)
  let vpstate = @vk.VkPipelineViewportStateCreateInfo::new()
  vpstate.set_viewportCount((1 : UInt32))
  vpstate.set_pViewports(vp)
  vpstate.set_scissorCount((1 : UInt32))
  vpstate.set_pScissors(sc)
  let rast = @vk.VkPipelineRasterizationStateCreateInfo::new()
  rast.set_polygonMode(@vk.VK_POLYGON_MODE_FILL)
  rast.set_cullMode(@vk.VK_CULL_MODE_NONE)
  rast.set_frontFace(@vk.VK_FRONT_FACE_COUNTER_CLOCKWISE)
  rast.set_lineWidth((1.0 : Float))
  let ms = @vk.VkPipelineMultisampleStateCreateInfo::new()
  ms.set_rasterizationSamples(@vk.VK_SAMPLE_COUNT_1_BIT)
  let cba = @vk.VkPipelineColorBlendAttachmentState::new()
  cba.set_colorWriteMask(@vk.VK_COLOR_COMPONENT_R_BIT | @vk.VK_COLOR_COMPONENT_G_BIT | @vk.VK_COLOR_COMPONENT_B_BIT | @vk.VK_COLOR_COMPONENT_A_BIT)
  let cbstate = @vk.VkPipelineColorBlendStateCreateInfo::new()
  cbstate.set_attachmentCount((1 : UInt32))
  cbstate.set_pAttachments(cba)
  let prci = @vk.VkPipelineRenderingCreateInfo::new()
  prci.set_colorAttachmentCount((1 : UInt32))
  prci.set_pColorAttachmentFormats(FixedArray::make(1, @vk.VK_FORMAT_R8G8B8A8_UNORM))
  let gpci = @vk.VkGraphicsPipelineCreateInfo::new()
  gpci.set_pNext(prci.as_ptr())
  gpci.set_stageCount((2 : UInt32))
  gpci.set_pStages(stages)
  gpci.set_pVertexInputState(vinput)
  gpci.set_pInputAssemblyState(iasm)
  gpci.set_pViewportState(vpstate)
  gpci.set_pRasterizationState(rast)
  gpci.set_pMultisampleState(ms)
  gpci.set_pColorBlendState(cbstate)
  gpci.set_layout(layout)
  let pipe_out = FixedArray::make(1, @vk.VkPipeline::null())
  let gpr = (dfn.vkCreateGraphicsPipelines)(dev, @vk.VkPipelineCache::null(), (1 : UInt32), gpci, na, pipe_out)
  if gpr != 0 {
    println("[27-ind] FAIL — pipeline=\{gpr}")
    return
  }
  let pipe = pipe_out[0]

  // ---- indirect command buffers ----
  let (ibuf, imem) = mkbuf((6 : UInt64), @vk.VK_BUFFER_USAGE_INDEX_BUFFER_BIT, host)
  let idx : Array[Byte] = []
  idx.push((0 : Byte))
  idx.push((0 : Byte))
  idx.push((1 : Byte))
  idx.push((0 : Byte))
  idx.push((2 : Byte))
  idx.push((0 : Byte))
  let _ = @vk.upload_bytes(dev, imem, Bytes::from_array(idx), 6)
  let (dbuf, dmem) = mkbuf((16 : UInt64), @vk.VK_BUFFER_USAGE_INDIRECT_BUFFER_BIT, host)
  let draw = FixedArray::make(4, (0 : UInt32))
  draw[0] = (3 : UInt32) // vertexCount
  draw[1] = (1 : UInt32) // instanceCount
  let _ = @vk.upload_uint32(dev, dmem, draw, 16)
  let (idbuf, idmem) = mkbuf((20 : UInt64), @vk.VK_BUFFER_USAGE_INDIRECT_BUFFER_BIT, host)
  let idraw = FixedArray::make(5, (0 : UInt32))
  idraw[0] = (3 : UInt32) // indexCount
  idraw[1] = (1 : UInt32) // instanceCount
  let _ = @vk.upload_uint32(dev, idmem, idraw, 20)
  let (cbuf, cmem) = mkbuf((4 : UInt64), @vk.VK_BUFFER_USAGE_INDIRECT_BUFFER_BIT, host)
  let count = FixedArray::make(1, (1 : UInt32))
  let _ = @vk.upload_uint32(dev, cmem, count, 4)

  // ---- one image per draw command ----
  let images : Array[@vk.VkImage] = []
  let imems : Array[@vk.VkDeviceMemory] = []
  let views : Array[@vk.VkImageView] = []
  let range = @vk.VkImageSubresourceRange::new()
  range.set_aspectMask(@vk.VK_IMAGE_ASPECT_COLOR_BIT)
  range.set_levelCount((1 : UInt32))
  range.set_layerCount((1 : UInt32))
  for i = 0; i < 4; i = i + 1 {
    let e3 = @vk.VkExtent3D::new()
    e3.set_width(sideu)
    e3.set_height(sideu)
    e3.set_depth((1 : UInt32))
    let ici2 = @vk.VkImageCreateInfo::new()
    ici2.set_imageType(@vk.VK_IMAGE_TYPE_2D)
    ici2.set_format(@vk.VK_FORMAT_R8G8B8A8_UNORM)
    ici2.set_extent(e3)
    ici2.set_mipLevels((1 : UInt32))
    ici2.set_arrayLayers((1 : UInt32))
    ici2.set_samples(@vk.VK_SAMPLE_COUNT_1_BIT)
    ici2.set_tiling(@vk.VK_IMAGE_TILING_OPTIMAL)
    ici2.set_usage(@vk.VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT | @vk.VK_IMAGE_USAGE_TRANSFER_SRC_BIT)
    let io = FixedArray::make(1, @vk.VkImage::null())
    let _ = (dfn.vkCreateImage)(dev, ici2, na, io)
    let rq = @vk.VkMemoryRequirements::new()
    (dfn.vkGetImageMemoryRequirements)(dev, io[0], rq)
    let ai = @vk.VkMemoryAllocateInfo::new()
    ai.set_allocationSize(rq.get_size())
    ai.set_memoryTypeIndex(memtype(rq.get_memoryTypeBits(), devlocal).reinterpret_as_uint())
    let mo = FixedArray::make(1, @vk.VkDeviceMemory::null())
    let _ = (dfn.vkAllocateMemory)(dev, ai, na, mo)
    let _ = (dfn.vkBindImageMemory)(dev, io[0], mo[0], (0 : UInt64))
    let ivci = @vk.VkImageViewCreateInfo::new()
    ivci.set_image(io[0])
    ivci.set_viewType(@vk.VK_IMAGE_VIEW_TYPE_2D)
    ivci.set_format(@vk.VK_FORMAT_R8G8B8A8_UNORM)
    ivci.set_subresourceRange(range)
    let vo = FixedArray::make(1, @vk.VkImageView::null())
    let _ = (dfn.vkCreateImageView)(dev, ivci, na, vo)
    images.push(io[0])
    imems.push(mo[0])
    views.push(vo[0])
  }
  let pixbufs : Array[@vk.VkBuffer] = []
  let pixmems : Array[@vk.VkDeviceMemory] = []
  for i = 0; i < 4; i = i + 1 {
    let (pb, pm) = mkbuf((px * 4), @vk.VK_BUFFER_USAGE_TRANSFER_DST_BIT, host)
    pixbufs.push(pb)
    pixmems.push(pm)
  }

  // ---- record ----
  let cpobj = @vk.VkCommandPoolCreateInfo::new()
  cpobj.set_queueFamilyIndex((0 : UInt32))
  cpobj.set_flags(@vk.VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT)
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
  for i = 0; i < 4; i = i + 1 {
    // undefined -> color attachment
    let b2 = @vk.VkImageMemoryBarrier2::new()
    b2.set_srcStageMask(@vk.VK_PIPELINE_STAGE_2_NONE)
    b2.set_srcAccessMask(@vk.VK_ACCESS_2_NONE)
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
    (dfn.vkCmdPipelineBarrier2)(cb, dep)
    let cv = @vk.VkClearValue::new()
    cv.set_color_rgba((0.0 : Float), (0.0 : Float), (0.0 : Float), (1.0 : Float))
    let att = @vk.VkRenderingAttachmentInfo::new()
    att.set_imageView(views[i])
    att.set_imageLayout(@vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL)
    att.set_loadOp(@vk.VK_ATTACHMENT_LOAD_OP_CLEAR)
    att.set_storeOp(@vk.VK_ATTACHMENT_STORE_OP_STORE)
    att.set_clearValue(cv)
    let area = @vk.VkRect2D::new()
    area.set_extent(ext2)
    let ri = @vk.VkRenderingInfo::new()
    ri.set_renderArea(area)
    ri.set_layerCount((1 : UInt32))
    ri.set_colorAttachmentCount((1 : UInt32))
    ri.set_pColorAttachments(att)
    (dfn.vkCmdBeginRendering)(cb, ri)
    (dfn.vkCmdBindPipeline)(cb, @vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe)
    if i == 0 {
      (dfn.vkCmdDrawIndirect)(cb, dbuf, (0 : UInt64), (1 : UInt32), (16 : UInt32))
      n = n + 1
    } else if i == 1 {
      if has("vkCmdBindIndexBuffer2") {
        (dfn.vkCmdBindIndexBuffer2)(cb, ibuf, (0 : UInt64), (6 : UInt64), @vk.VK_INDEX_TYPE_UINT16)
        n = n + 1
      } else {
        (dfn.vkCmdBindIndexBuffer)(cb, ibuf, (0 : UInt64), @vk.VK_INDEX_TYPE_UINT16)
      }
      (dfn.vkCmdDrawIndexedIndirect)(cb, idbuf, (0 : UInt64), (1 : UInt32), (20 : UInt32))
      n = n + 1
    } else if i == 2 {
      (dfn.vkCmdDrawIndirectCount)(cb, dbuf, (0 : UInt64), cbuf, (0 : UInt64), (1 : UInt32), (16 : UInt32))
      n = n + 1
    } else {
      if has("vkCmdBindIndexBuffer2") {
        (dfn.vkCmdBindIndexBuffer2)(cb, ibuf, (0 : UInt64), (6 : UInt64), @vk.VK_INDEX_TYPE_UINT16)
        n = n + 1
      } else {
        (dfn.vkCmdBindIndexBuffer)(cb, ibuf, (0 : UInt64), @vk.VK_INDEX_TYPE_UINT16)
      }
      (dfn.vkCmdDrawIndexedIndirectCount)(cb, idbuf, (0 : UInt64), cbuf, (0 : UInt64), (1 : UInt32), (20 : UInt32))
      n = n + 1
    }
    (dfn.vkCmdEndRendering)(cb)
  }
  // copy every image back so each draw can be checked separately
  for i = 0; i < 4; i = i + 1 {
    let b3 = @vk.VkImageMemoryBarrier2::new()
    b3.set_srcStageMask(@vk.VK_PIPELINE_STAGE_2_COLOR_ATTACHMENT_OUTPUT_BIT)
    b3.set_srcAccessMask(@vk.VK_ACCESS_2_COLOR_ATTACHMENT_WRITE_BIT)
    b3.set_dstStageMask(@vk.VK_PIPELINE_STAGE_2_COPY_BIT)
    b3.set_dstAccessMask(@vk.VK_ACCESS_2_TRANSFER_READ_BIT)
    b3.set_oldLayout(@vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL)
    b3.set_newLayout(@vk.VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL)
    b3.set_srcQueueFamilyIndex((0xFFFFFFFF : UInt32))
    b3.set_dstQueueFamilyIndex((0xFFFFFFFF : UInt32))
    b3.set_image(images[i])
    b3.set_subresourceRange(range)
    let dep = @vk.VkDependencyInfo::new()
    dep.set_imageMemoryBarrierCount((1 : UInt32))
    dep.set_pImageMemoryBarriers(b3)
    (dfn.vkCmdPipelineBarrier2)(cb, dep)
    let sub = @vk.VkImageSubresourceLayers::new()
    sub.set_aspectMask(@vk.VK_IMAGE_ASPECT_COLOR_BIT)
    sub.set_layerCount((1 : UInt32))
    let e3 = @vk.VkExtent3D::new()
    e3.set_width(sideu)
    e3.set_height(sideu)
    e3.set_depth((1 : UInt32))
    let region = @vk.VkBufferImageCopy::new()
    region.set_bufferOffset((0 : UInt64))
    region.set_imageSubresource(sub)
    region.set_imageExtent(e3)
    (dfn.vkCmdCopyImageToBuffer)(cb, images[i], @vk.VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL, pixbufs[i], (1 : UInt32), region)
  }
  let _ = (dfn.vkEndCommandBuffer)(cb)
  let fci = @vk.VkFenceCreateInfo::new()
  let fence_out = FixedArray::make(1, @vk.VkFence::null())
  let _ = (dfn.vkCreateFence)(dev, fci, na, fence_out)
  let si = @vk.VkSubmitInfo::new()
  si.set_commandBufferCount((1 : UInt32))
  si.set_pCommandBuffers(FixedArray::make(1, cb))
  let sr = (dfn.vkQueueSubmit)(queue, (1 : UInt32), si, fence_out[0])
  let wr = (dfn.vkWaitForFences)(dev, (1 : UInt32), fence_out, (1 : UInt32), (20000000000 : UInt64))

  // ---- assertions: every draw must have produced geometry ----
  let mut red = 0
  let mut draw_ok = true
  for i = 0; i < 4; i = i + 1 {
    let pixels = @vk.download_buffer(dev, pixmems[i], (side * side * 4))
    let mut lit = 0
    let mut k = 0
    while k < side * side {
      if pixels[k * 4] > (0 : Byte) {
        lit = lit + 1
      }
      k = k + 1
    }
    red = red + lit
    if lit == 0 {
      draw_ok = false
    }
  }

  (dfn.vkDestroyFence)(dev, fence_out[0], na)
  (dfn.vkDestroyCommandPool)(dev, cp_out[0], na)
  (dfn.vkDestroyPipeline)(dev, pipe, na)
  (dfn.vkDestroyPipelineLayout)(dev, layout, na)
  (dfn.vkDestroyShaderModule)(dev, vsm_out[0], na)
  (dfn.vkDestroyShaderModule)(dev, fsm_out[0], na)
  for i = 0; i < 4; i = i + 1 {
    (dfn.vkDestroyImageView)(dev, views[i], na)
    (dfn.vkDestroyImage)(dev, images[i], na)
    (dfn.vkFreeMemory)(dev, imems[i], na)
  }
  for i = 0; i < 4; i = i + 1 {
    (dfn.vkDestroyBuffer)(dev, pixbufs[i], na)
    (dfn.vkFreeMemory)(dev, pixmems[i], na)
  }
  (dfn.vkDestroyBuffer)(dev, cbuf, na)
  (dfn.vkFreeMemory)(dev, cmem, na)
  (dfn.vkDestroyBuffer)(dev, idbuf, na)
  (dfn.vkFreeMemory)(dev, idmem, na)
  (dfn.vkDestroyBuffer)(dev, dbuf, na)
  (dfn.vkFreeMemory)(dev, dmem, na)
  (dfn.vkDestroyBuffer)(dev, ibuf, na)
  (dfn.vkFreeMemory)(dev, imem, na)
  (dfn.vkDestroyDevice)(dev, na)
  @vk.destroy_debug_messenger(inst, ifn, messenger)
  (ifn.vkDestroyInstance)(inst, na)
  println("[27-ind] commands=\{n} red=\{red} submit=\{sr} wait=\{wr} errors=\{g_errors.val}")
  if n >= 4 && draw_ok && sr == 0 && wr == 0 && g_errors.val == 0 {
    println("[27-ind] OK — \{n} indirect draw commands, geometry rendered")
  } else {
    println("[27-ind] FAIL — commands=\{n} draw=\{draw_ok} errors=\{g_errors.val}")
  }
}
