// vulkan/renderpass2 — render pass 2, queries, conditional rendering, push descriptors.
// Fifth execution-coverage batch (headless offscreen). The pass/fail gate counts
// validation errors via the generated debug messenger, not just return codes.

///|
let na : @vk.VkAllocationCallbacks = @vk.VkAllocationCallbacks::null()

///|
let g_errors : Ref[Int] = { val: 0 }

///|
fn main {
  let app = @vk.VkApplicationInfo::new()
  app.set_pApplicationName(@vk.cstr("Tycho RenderPass2"))
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
    println("[20-rp2] FAIL — vkCreateInstance=\{ir}")
    return
  }
  let inst = inst_out[0]
  let ifn = @vk.InstanceFn::load(inst)
  let messenger = @vk.create_debug_messenger(
    inst,
    ifn,
    @vk.VK_DEBUG_UTILS_MESSAGE_SEVERITY_ERROR_BIT_EXT,
    @vk.VK_DEBUG_UTILS_MESSAGE_TYPE_VALIDATION_BIT_EXT,
    (_sev, _ty, data, _ud) => {
      g_errors.val = g_errors.val + 1
      println("[20-rp2] VALIDATION: \{@vk.read_cstr(data.get_pMessage())}")
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
  let crq = @vk.VkPhysicalDeviceConditionalRenderingFeaturesEXT::new()
  let fq = @vk.VkPhysicalDeviceFeatures2::new()
  fq.set_pNext(crq.as_ptr())
  (ifn.vkGetPhysicalDeviceFeatures2)(phys, fq)
  let f13 = @vk.VkPhysicalDeviceVulkan13Features::new()
  f13.set_synchronization2((1 : UInt32))
  let cr = @vk.VkPhysicalDeviceConditionalRenderingFeaturesEXT::new()
  cr.set_conditionalRendering(crq.get_conditionalRendering())
  cr.set_pNext(f13.as_ptr())
  let want = ["VK_KHR_create_renderpass2", "VK_KHR_push_descriptor", "VK_EXT_conditional_rendering", "VK_KHR_synchronization2", "VK_KHR_maintenance5", "VK_AMD_buffer_marker", "VK_NV_device_diagnostic_checkpoints", "VK_KHR_descriptor_update_template", "VK_EXT_transform_feedback"]
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
  dci.set_pNext(cr.as_ptr())
  dci.set_queueCreateInfoCount((1 : UInt32))
  dci.set_pQueueCreateInfos(qci)
  dci.set_enabledExtensionCount(nden.reinterpret_as_uint())
  dci.set_ppEnabledExtensionNames(@vk.cstr_array(den))
  let dev_out = FixedArray::make(1, @vk.VkDevice::null())
  let dr = (ifn.vkCreateDevice)(phys, dci, na, dev_out)
  if dr != 0 {
    println("[20-rp2] FAIL — vkCreateDevice=\{dr}")
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

  // offscreen color target
  let fmt = @vk.VK_FORMAT_R8G8B8A8_UNORM
  let ici2 = @vk.VkImageCreateInfo::new()
  ici2.set_imageType(@vk.VK_IMAGE_TYPE_2D)
  ici2.set_format(fmt)
  let ext3 = @vk.VkExtent3D::new()
  ext3.set_width((64 : UInt32))
  ext3.set_height((64 : UInt32))
  ext3.set_depth((1 : UInt32))
  ici2.set_extent(ext3)
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

  // render pass 2 with two subpasses
  let att = @vk.VkAttachmentDescription2::new()
  att.set_format(fmt)
  att.set_samples(@vk.VK_SAMPLE_COUNT_1_BIT)
  att.set_loadOp(@vk.VK_ATTACHMENT_LOAD_OP_CLEAR)
  att.set_storeOp(@vk.VK_ATTACHMENT_STORE_OP_STORE)
  att.set_stencilLoadOp(@vk.VK_ATTACHMENT_LOAD_OP_DONT_CARE)
  att.set_stencilStoreOp(@vk.VK_ATTACHMENT_STORE_OP_DONT_CARE)
  att.set_initialLayout(@vk.VK_IMAGE_LAYOUT_UNDEFINED)
  att.set_finalLayout(@vk.VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL)
  let aref = @vk.VkAttachmentReference2::new()
  aref.set_attachment((0 : UInt32))
  aref.set_layout(@vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL)
  let sp0 = @vk.VkSubpassDescription2::new()
  sp0.set_pipelineBindPoint(@vk.VK_PIPELINE_BIND_POINT_GRAPHICS)
  sp0.set_colorAttachmentCount((1 : UInt32))
  sp0.set_pColorAttachments(aref)
  let sp1 = @vk.VkSubpassDescription2::new()
  sp1.set_pipelineBindPoint(@vk.VK_PIPELINE_BIND_POINT_GRAPHICS)
  sp1.set_colorAttachmentCount((1 : UInt32))
  sp1.set_pColorAttachments(aref)
  let subs = @vk.VkSubpassDescription2::array(2)
  subs.set_pipelineBindPoint_at(0, @vk.VK_PIPELINE_BIND_POINT_GRAPHICS)
  subs.set_colorAttachmentCount_at(0, (1 : UInt32))
  subs.set_pColorAttachments_at(0, aref)
  subs.set_pipelineBindPoint_at(1, @vk.VK_PIPELINE_BIND_POINT_GRAPHICS)
  subs.set_colorAttachmentCount_at(1, (1 : UInt32))
  subs.set_pColorAttachments_at(1, aref)
  let dep2 = @vk.VkSubpassDependency2::new()
  dep2.set_srcSubpass((0 : UInt32))
  dep2.set_dstSubpass((1 : UInt32))
  dep2.set_srcStageMask(@vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT)
  dep2.set_dstStageMask(@vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT)
  dep2.set_srcAccessMask(@vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT)
  dep2.set_dstAccessMask(@vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT)
  let rpci2 = @vk.VkRenderPassCreateInfo2::new()
  rpci2.set_attachmentCount((1 : UInt32))
  rpci2.set_pAttachments(att)
  rpci2.set_subpassCount((2 : UInt32))
  rpci2.set_pSubpasses(subs)
  rpci2.set_dependencyCount((1 : UInt32))
  rpci2.set_pDependencies(dep2)
  let rp_out = FixedArray::make(1, @vk.VkRenderPass::null())
  let rpr = if has("vkCreateRenderPass2") {
    (dfn.vkCreateRenderPass2)(dev, rpci2, na, rp_out)
  } else {
    (dfn.vkCreateRenderPass2KHR)(dev, rpci2, na, rp_out)
  }
  if rpr != 0 {
    println("[20-rp2] FAIL — CreateRenderPass2=\{rpr}")
    return
  }
  n = n + 1
  let rp = rp_out[0]
  let fbci = @vk.VkFramebufferCreateInfo::new()
  fbci.set_renderPass(rp)
  fbci.set_attachmentCount((1 : UInt32))
  fbci.set_pAttachments(FixedArray::make(1, view))
  fbci.set_width((64 : UInt32))
  fbci.set_height((64 : UInt32))
  fbci.set_layers((1 : UInt32))
  let fb_out = FixedArray::make(1, @vk.VkFramebuffer::null())
  let _ = (dfn.vkCreateFramebuffer)(dev, fbci, na, fb_out)
  let fb = fb_out[0]

  // descriptor layouts: set 0 regular, set 1 push
  let dslb = @vk.VkDescriptorSetLayoutBinding::new()
  dslb.set_binding((0 : UInt32))
  dslb.set_descriptorType(@vk.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER)
  dslb.set_descriptorCount((1 : UInt32))
  dslb.set_stageFlags(@vk.VK_SHADER_STAGE_FRAGMENT_BIT)
  let dslci = @vk.VkDescriptorSetLayoutCreateInfo::new()
  dslci.set_bindingCount((1 : UInt32))
  dslci.set_pBindings(dslb)
  let dsl_a = FixedArray::make(1, @vk.VkDescriptorSetLayout::null())
  let _ = (dfn.vkCreateDescriptorSetLayout)(dev, dslci, na, dsl_a)
  let dslci_p = @vk.VkDescriptorSetLayoutCreateInfo::new()
  dslci_p.set_bindingCount((1 : UInt32))
  dslci_p.set_pBindings(dslb)
  dslci_p.set_flags(@vk.VK_DESCRIPTOR_SET_LAYOUT_CREATE_PUSH_DESCRIPTOR_BIT)
  let dsl_b = FixedArray::make(1, @vk.VkDescriptorSetLayout::null())
  let _ = (dfn.vkCreateDescriptorSetLayout)(dev, dslci_p, na, dsl_b)
  let plci = @vk.VkPipelineLayoutCreateInfo::new()
  plci.set_setLayoutCount((2 : UInt32))
  plci.set_pSetLayouts(FixedArray::make(2, dsl_a[0]))
  let pl_out = FixedArray::make(1, @vk.VkPipelineLayout::null())
  let _ = (dfn.vkCreatePipelineLayout)(dev, plci, na, pl_out)
  let layout = pl_out[0]
  let sets_arr = FixedArray::make(2, dsl_a[0])
  sets_arr[1] = dsl_b[0]
  plci.set_pSetLayouts(sets_arr)
  let _ = (dfn.vkDestroyPipelineLayout)(dev, layout, na)
  let _ = (dfn.vkCreatePipelineLayout)(dev, plci, na, pl_out)
  let layout2 = pl_out[0]

  // pipeline
  let vert = @shader.compile_shader_file("examples/vulkan/renderpass2/shader.vert", @shader.SHADER_KIND_VERTEX)
  let frag = @shader.compile_shader_file("examples/vulkan/renderpass2/shader.frag", @shader.SHADER_KIND_FRAGMENT)
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
  let vinput = @vk.VkPipelineVertexInputStateCreateInfo::new()
  let iasm = @vk.VkPipelineInputAssemblyStateCreateInfo::new()
  iasm.set_topology(@vk.VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST)
  let ext2 = @vk.VkExtent2D::new()
  ext2.set_width((64 : UInt32))
  ext2.set_height((64 : UInt32))
  let vp = @vk.VkViewport::new()
  vp.set_width((64.0 : Float))
  vp.set_height((64.0 : Float))
  vp.set_maxDepth((1.0 : Float))
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
  rast.set_frontFace(@vk.VK_FRONT_FACE_CLOCKWISE)
  rast.set_lineWidth((1.0 : Float))
  let ms = @vk.VkPipelineMultisampleStateCreateInfo::new()
  ms.set_rasterizationSamples(@vk.VK_SAMPLE_COUNT_1_BIT)
  let cba = @vk.VkPipelineColorBlendAttachmentState::new()
  cba.set_colorWriteMask(@vk.VK_COLOR_COMPONENT_R_BIT | @vk.VK_COLOR_COMPONENT_G_BIT | @vk.VK_COLOR_COMPONENT_B_BIT | @vk.VK_COLOR_COMPONENT_A_BIT)
  let cbstate = @vk.VkPipelineColorBlendStateCreateInfo::new()
  cbstate.set_attachmentCount((1 : UInt32))
  cbstate.set_pAttachments(cba)
  let gpci = @vk.VkGraphicsPipelineCreateInfo::new()
  gpci.set_stageCount((2 : UInt32))
  gpci.set_pStages(stages)
  gpci.set_pVertexInputState(vinput)
  gpci.set_pInputAssemblyState(iasm)
  gpci.set_pViewportState(vpstate)
  gpci.set_pRasterizationState(rast)
  gpci.set_pMultisampleState(ms)
  gpci.set_pColorBlendState(cbstate)
  gpci.set_layout(layout2)
  gpci.set_renderPass(rp)
  gpci.set_subpass((0 : UInt32))
  let pipe_out = FixedArray::make(1, @vk.VkPipeline::null())
  let gpr = (dfn.vkCreateGraphicsPipelines)(dev, @vk.VkPipelineCache::null(), (1 : UInt32), gpci, na, pipe_out)
  if gpr != 0 {
    println("[20-rp2] FAIL — pipeline=\{gpr}")
    return
  }
  let pipe = pipe_out[0]
  gpci.set_subpass((1 : UInt32))
  let pipe1_out = FixedArray::make(1, @vk.VkPipeline::null())
  let gpr1 = (dfn.vkCreateGraphicsPipelines)(dev, @vk.VkPipelineCache::null(), (1 : UInt32), gpci, na, pipe1_out)
  let pipe1 = pipe1_out[0]

  // buffers + descriptor set + update template
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
    ai.set_memoryTypeIndex(memtype(rq.get_memoryTypeBits(), props))
    let mo = FixedArray::make(1, @vk.VkDeviceMemory::null())
    let _ = (dfn.vkAllocateMemory)(dev, ai, na, mo)
    let _ = (dfn.vkBindBufferMemory)(dev, o[0], mo[0], (0 : UInt64))
    ci.free()
    (o[0], mo[0])
  }
  let (ubuf, umem) = mkbuf((64 : UInt64), @vk.VK_BUFFER_USAGE_UNIFORM_BUFFER_BIT, host)
  let (ibuf, imem2) = mkbuf((64 : UInt64), @vk.VK_BUFFER_USAGE_INDEX_BUFFER_BIT, host)
  let (pred, premem) = mkbuf((64 : UInt64), @vk.VK_BUFFER_USAGE_TRANSFER_DST_BIT | @vk.VK_BUFFER_USAGE_INDIRECT_BUFFER_BIT | @vk.VK_BUFFER_USAGE_CONDITIONAL_RENDERING_BIT_EXT, host)
  let (mark, markmem) = mkbuf((64 : UInt64), @vk.VK_BUFFER_USAGE_TRANSFER_DST_BIT, host)
  let (rbuf, rmem) = mkbuf((64 * 64 * 4).to_uint64(), @vk.VK_BUFFER_USAGE_TRANSFER_DST_BIT, host)
  let udata = FixedArray::make(4, (1.0 : Float))
  let _ = @vk.upload_buffer(dev, umem, udata, 16)
  let idx = FixedArray::make(6, (0 : UInt32))
  for i = 0; i < 6; i = i + 1 {
    idx[i] = (i % 3).reinterpret_as_uint()
  }
  let _ = @vk.upload_uint32(dev, imem2, idx, 24)
  let dps = @vk.VkDescriptorPoolSize::new()
  dps.set_type(@vk.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER)
  dps.set_descriptorCount((2 : UInt32))
  let dpci = @vk.VkDescriptorPoolCreateInfo::new()
  dpci.set_maxSets((2 : UInt32))
  dpci.set_poolSizeCount((1 : UInt32))
  dpci.set_pPoolSizes(dps)
  let pool_out = FixedArray::make(1, @vk.VkDescriptorPool::null())
  let _ = (dfn.vkCreateDescriptorPool)(dev, dpci, na, pool_out)
  let dsai = @vk.VkDescriptorSetAllocateInfo::new()
  dsai.set_descriptorPool(pool_out[0])
  dsai.set_descriptorSetCount((1 : UInt32))
  dsai.set_pSetLayouts(FixedArray::make(1, dsl_a[0]))
  let ds_out = FixedArray::make(1, @vk.VkDescriptorSet::null())
  let _ = (dfn.vkAllocateDescriptorSets)(dev, dsai, ds_out)
  let dbi = @vk.VkDescriptorBufferInfo::new()
  dbi.set_buffer(ubuf)
  dbi.set_range((16 : UInt64))
  let wd = @vk.VkWriteDescriptorSet::new()
  wd.set_dstSet(ds_out[0])
  wd.set_dstBinding((0 : UInt32))
  wd.set_descriptorCount((1 : UInt32))
  wd.set_descriptorType(@vk.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER)
  wd.set_pBufferInfo(dbi)
  (dfn.vkUpdateDescriptorSets)(dev, (1 : UInt32), wd, (0 : UInt32), @vk.VkCopyDescriptorSet::null())
  let entry = @vk.VkDescriptorUpdateTemplateEntry::new()
  entry.set_dstBinding((0 : UInt32))
  entry.set_descriptorCount((1 : UInt32))
  entry.set_descriptorType(@vk.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER)
  entry.set_stride((16 : UInt64))
  let dutci = @vk.VkDescriptorUpdateTemplateCreateInfo::new()
  dutci.set_descriptorUpdateEntryCount((1 : UInt32))
  dutci.set_pDescriptorUpdateEntries(entry)
  dutci.set_templateType(@vk.VK_DESCRIPTOR_UPDATE_TEMPLATE_TYPE_PUSH_DESCRIPTORS)
  dutci.set_pipelineBindPoint(@vk.VK_PIPELINE_BIND_POINT_GRAPHICS)
  dutci.set_pipelineLayout(layout2)
  dutci.set_set((1 : UInt32))
  let dut_out = FixedArray::make(1, @vk.VkDescriptorUpdateTemplate::null())
  let dutr = if has("vkCreateDescriptorUpdateTemplate") {
    (dfn.vkCreateDescriptorUpdateTemplate)(dev, dutci, na, dut_out)
  } else {
    (dfn.vkCreateDescriptorUpdateTemplateKHR)(dev, dutci, na, dut_out)
  }

  // query pools
  let qpci = @vk.VkQueryPoolCreateInfo::new()
  qpci.set_queryType(@vk.VK_QUERY_TYPE_OCCLUSION)
  qpci.set_queryCount((2 : UInt32))
  let qp_out = FixedArray::make(1, @vk.VkQueryPool::null())
  let _ = (dfn.vkCreateQueryPool)(dev, qpci, na, qp_out)
  let qp = qp_out[0]

  let cpci = @vk.VkCommandPoolCreateInfo::new()
  cpci.set_queueFamilyIndex((0 : UInt32))
  let cp_out = FixedArray::make(1, @vk.VkCommandPool::null())
  let _ = (dfn.vkCreateCommandPool)(dev, cpci, na, cp_out)
  let cbai = @vk.VkCommandBufferAllocateInfo::new()
  cbai.set_commandPool(cp_out[0])
  cbai.set_level(@vk.VK_COMMAND_BUFFER_LEVEL_PRIMARY)
  cbai.set_commandBufferCount((1 : UInt32))
  let cb_out = FixedArray::make(1, @vk.VkCommandBuffer::null())
  let _ = (dfn.vkAllocateCommandBuffers)(dev, cbai, cb_out)
  let cb = cb_out[0]
  let bi = @vk.VkCommandBufferBeginInfo::new()
  let _ = (dfn.vkBeginCommandBuffer)(cb, bi)
  let cv = @vk.VkClearValue::new()
  cv.set_color_rgba((0.0 : Float), (0.0 : Float), (0.0 : Float), (1.0 : Float))
  let area = @vk.VkRect2D::new()
  area.set_extent(ext2)
  let rpbi = @vk.VkRenderPassBeginInfo::new()
  rpbi.set_renderPass(rp)
  rpbi.set_framebuffer(fb)
  rpbi.set_renderArea(area)
  rpbi.set_clearValueCount((1 : UInt32))
  rpbi.set_pClearValues(cv)
  let sbi = @vk.VkSubpassBeginInfo::new()
  sbi.set_contents(@vk.VK_SUBPASS_CONTENTS_INLINE)
  let sei = @vk.VkSubpassEndInfo::new()
  (dfn.vkCmdResetQueryPool)(cb, qp, (0 : UInt32), (2 : UInt32))
  n = n + 1
  if has("vkCmdBeginRenderPass2") {
    (dfn.vkCmdBeginRenderPass2)(cb, rpbi, sbi)
    n = n + 1
  }
  if has("vkCmdBeginRenderPass2KHR") {
    // a second begin would be invalid; exercise the KHR alias on a fresh CB below
    n = n + 0
  }
  (dfn.vkCmdBindPipeline)(cb, @vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe)

  // BindDescriptorSets2 / KHR (set 0)
  let bdsi = @vk.VkBindDescriptorSetsInfo::new()
  bdsi.set_stageFlags(@vk.VK_SHADER_STAGE_FRAGMENT_BIT)
  bdsi.set_layout(layout2)
  bdsi.set_firstSet((0 : UInt32))
  bdsi.set_descriptorSetCount((1 : UInt32))
  bdsi.set_pDescriptorSets(ds_out)
  if has("vkCmdBindDescriptorSets2") {
    (dfn.vkCmdBindDescriptorSets2)(cb, bdsi)
    n = n + 1
  }
  if has("vkCmdBindDescriptorSets2KHR") {
    (dfn.vkCmdBindDescriptorSets2KHR)(cb, bdsi)
    n = n + 1
  }
  // push descriptors for set 1: legacy, KHR, 2, 2KHR
  let pwd = @vk.VkWriteDescriptorSet::new()
  pwd.set_dstBinding((0 : UInt32))
  pwd.set_descriptorCount((1 : UInt32))
  pwd.set_descriptorType(@vk.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER)
  pwd.set_pBufferInfo(dbi)
  if has("vkCmdPushDescriptorSet") {
    (dfn.vkCmdPushDescriptorSet)(cb, @vk.VK_PIPELINE_BIND_POINT_GRAPHICS, layout2, (1 : UInt32), (1 : UInt32), pwd)
    n = n + 1
  }
  if has("vkCmdPushDescriptorSetKHR") {
    (dfn.vkCmdPushDescriptorSetKHR)(cb, @vk.VK_PIPELINE_BIND_POINT_GRAPHICS, layout2, (1 : UInt32), (1 : UInt32), pwd)
    n = n + 1
  }
  let pdsi = @vk.VkPushDescriptorSetInfo::new()
  pdsi.set_stageFlags(@vk.VK_SHADER_STAGE_FRAGMENT_BIT)
  pdsi.set_layout(layout2)
  pdsi.set_set((1 : UInt32))
  pdsi.set_descriptorWriteCount((1 : UInt32))
  pdsi.set_pDescriptorWrites(pwd)
  if has("vkCmdPushDescriptorSet2") {
    (dfn.vkCmdPushDescriptorSet2)(cb, pdsi)
    n = n + 1
  }
  if has("vkCmdPushDescriptorSet2KHR") {
    (dfn.vkCmdPushDescriptorSet2KHR)(cb, pdsi)
    n = n + 1
  }
  if dutr == 0 {
    if has("vkCmdPushDescriptorSetWithTemplate") {
      (dfn.vkCmdPushDescriptorSetWithTemplate)(cb, dut_out[0], layout2, (1 : UInt32), dbi.as_ptr())
      n = n + 1
    }
    if has("vkCmdPushDescriptorSetWithTemplateKHR") {
      (dfn.vkCmdPushDescriptorSetWithTemplateKHR)(cb, dut_out[0], layout2, (1 : UInt32), dbi.as_ptr())
      n = n + 1
    }
    let ptpl = @vk.VkPushDescriptorSetWithTemplateInfo::new()
    ptpl.set_descriptorUpdateTemplate(dut_out[0])
    ptpl.set_layout(layout2)
    ptpl.set_set((1 : UInt32))
    ptpl.set_pData(dbi.as_ptr())
    if has("vkCmdPushDescriptorSetWithTemplate2") {
      (dfn.vkCmdPushDescriptorSetWithTemplate2)(cb, ptpl)
      n = n + 1
    }
    if has("vkCmdPushDescriptorSetWithTemplate2KHR") {
      (dfn.vkCmdPushDescriptorSetWithTemplate2KHR)(cb, ptpl)
      n = n + 1
    }
    ptpl.free()
  }

  // occlusion query + indexed query
  (dfn.vkCmdBeginQuery)(cb, qp, (0 : UInt32), (0 : UInt32))
  n = n + 1
  (dfn.vkCmdDraw)(cb, (3 : UInt32), (1 : UInt32), (0 : UInt32), (0 : UInt32))
  (dfn.vkCmdEndQuery)(cb, qp, (0 : UInt32))
  n = n + 1
  if has("vkCmdBeginQueryIndexedEXT") {
    (dfn.vkCmdBeginQueryIndexedEXT)(cb, qp, (1 : UInt32), (0 : UInt32), (0 : UInt32))
    n = n + 1
    (dfn.vkCmdDraw)(cb, (3 : UInt32), (1 : UInt32), (0 : UInt32), (0 : UInt32))
    (dfn.vkCmdEndQueryIndexedEXT)(cb, qp, (1 : UInt32), (0 : UInt32))
    n = n + 1
  }
  // indexed draw + index buffer 2
  (dfn.vkCmdBindIndexBuffer)(cb, ibuf, (0 : UInt64), @vk.VK_INDEX_TYPE_UINT32)
  if has("vkCmdBindIndexBuffer2KHR") {
    (dfn.vkCmdBindIndexBuffer2KHR)(cb, ibuf, (0 : UInt64), (24 : UInt64), @vk.VK_INDEX_TYPE_UINT32)
    n = n + 1
  }
  (dfn.vkCmdDrawIndexed)(cb, (6 : UInt32), (1 : UInt32), (0 : UInt32), (0 : Int32), (0 : UInt32))
  if has("vkCmdWriteBufferMarkerAMD") {
    (dfn.vkCmdWriteBufferMarkerAMD)(cb, @vk.VK_PIPELINE_STAGE_TRANSFER_BIT, mark, (0 : UInt64), (0x1234 : UInt32))
    n = n + 1
  }
  if has("vkCmdSetCheckpointNV") {
    (dfn.vkCmdSetCheckpointNV)(cb, @vk.cstr("tycho-checkpoint"))
    n = n + 1
  }
  // subpass transition: legacy + 2 + 2KHR
  if has("vkCmdNextSubpass2") {
    (dfn.vkCmdNextSubpass2)(cb, sbi, sei)
    n = n + 1
  } else {
    (dfn.vkCmdNextSubpass)(cb, @vk.VK_SUBPASS_CONTENTS_INLINE)
    n = n + 1
  }
  if gpr1 == 0 {
    (dfn.vkCmdBindPipeline)(cb, @vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe1)
  }
  (dfn.vkCmdDraw)(cb, (3 : UInt32), (1 : UInt32), (0 : UInt32), (0 : UInt32))
  if has("vkCmdEndRenderPass2") {
    (dfn.vkCmdEndRenderPass2)(cb, sei)
    n = n + 1
  }
  if has("vkCmdEndRenderPass2KHR") {
    n = n + 0
  }
  // query results may only be copied outside a render pass, and conditional
  // rendering needs its own render-pass instance with a CONDITIONAL_RENDERING buffer
  // copy results into the predicate buffer, then conditional rendering
  (dfn.vkCmdCopyQueryPoolResults)(cb, qp, (0 : UInt32), (1 : UInt32), pred, (0 : UInt64), (8 : UInt64), @vk.VK_QUERY_RESULT_64_BIT | @vk.VK_QUERY_RESULT_WAIT_BIT)
  n = n + 1
  let mb = @vk.VkMemoryBarrier2::new()
  mb.set_srcStageMask(@vk.VK_PIPELINE_STAGE_2_ALL_TRANSFER_BIT)
  mb.set_srcAccessMask(@vk.VK_ACCESS_2_TRANSFER_WRITE_BIT)
  mb.set_dstStageMask(@vk.VK_PIPELINE_STAGE_2_CONDITIONAL_RENDERING_BIT_EXT)
  mb.set_dstAccessMask(@vk.VK_ACCESS_2_CONDITIONAL_RENDERING_READ_BIT_EXT)
  let dep = @vk.VkDependencyInfo::new()
  dep.set_memoryBarrierCount((1 : UInt32))
  dep.set_pMemoryBarriers(mb)
  (dfn.vkCmdPipelineBarrier2)(cb, dep)
  if has("vkCmdBeginConditionalRenderingEXT") && crq.get_conditionalRendering() != 0 {
    (dfn.vkCmdBeginRenderPass2)(cb, rpbi, sbi)
    (dfn.vkCmdBindPipeline)(cb, @vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe)
    let cri = @vk.VkConditionalRenderingBeginInfoEXT::new()
    cri.set_buffer(pred)
    (dfn.vkCmdBeginConditionalRenderingEXT)(cb, cri)
    n = n + 1
    (dfn.vkCmdDraw)(cb, (3 : UInt32), (1 : UInt32), (0 : UInt32), (0 : UInt32))
    (dfn.vkCmdEndConditionalRenderingEXT)(cb)
    n = n + 1
    cri.free()
    (dfn.vkCmdNextSubpass2)(cb, sbi, sei)
    if gpr1 == 0 {
      (dfn.vkCmdBindPipeline)(cb, @vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe1)
    }
    (dfn.vkCmdEndRenderPass2)(cb, sei)
  }
  // readback
  let bic = @vk.VkBufferImageCopy::new()
  let subl = @vk.VkImageSubresourceLayers::new()
  subl.set_aspectMask(@vk.VK_IMAGE_ASPECT_COLOR_BIT)
  subl.set_layerCount((1 : UInt32))
  bic.set_imageSubresource(subl)
  bic.set_imageExtent(ext3)
  (dfn.vkCmdCopyImageToBuffer)(cb, img, @vk.VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL, rbuf, (1 : UInt32), bic)
  let _ = (dfn.vkEndCommandBuffer)(cb)

  // separate CB for the KHR aliases: a render pass instance cannot be begun twice
  let cb2_out = FixedArray::make(1, @vk.VkCommandBuffer::null())
  let cbai_k = @vk.VkCommandBufferAllocateInfo::new()
  cbai_k.set_commandPool(cp_out[0])
  cbai_k.set_level(@vk.VK_COMMAND_BUFFER_LEVEL_PRIMARY)
  cbai_k.set_commandBufferCount((1 : UInt32))
  let _ = (dfn.vkAllocateCommandBuffers)(dev, cbai_k, cb2_out)
  let cb2 = cb2_out[0]
  let _ = (dfn.vkBeginCommandBuffer)(cb2, bi)
  let mut khr_rp = false
  if has("vkCmdBeginRenderPass2KHR") {
    (dfn.vkCmdBeginRenderPass2KHR)(cb2, rpbi, sbi)
    n = n + 1
    khr_rp = true
    (dfn.vkCmdBindPipeline)(cb2, @vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe)
    (dfn.vkCmdDraw)(cb2, (3 : UInt32), (1 : UInt32), (0 : UInt32), (0 : UInt32))
    if has("vkCmdNextSubpass2KHR") {
      (dfn.vkCmdNextSubpass2KHR)(cb2, sbi, sei)
      n = n + 1
      if gpr1 == 0 {
        (dfn.vkCmdBindPipeline)(cb2, @vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe1)
      }
      (dfn.vkCmdDraw)(cb2, (3 : UInt32), (1 : UInt32), (0 : UInt32), (0 : UInt32))
    }
    if has("vkCmdEndRenderPass2KHR") {
      (dfn.vkCmdEndRenderPass2KHR)(cb2, sei)
      n = n + 1
    }
  }
  let _ = (dfn.vkEndCommandBuffer)(cb2)

  let fci = @vk.VkFenceCreateInfo::new()
  let fence_out = FixedArray::make(1, @vk.VkFence::null())
  let _ = (dfn.vkCreateFence)(dev, fci, na, fence_out)
  let si = @vk.VkSubmitInfo::new()
  let cbs = FixedArray::make(2, cb)
  cbs[1] = cb2
  si.set_commandBufferCount(if khr_rp { (2 : UInt32) } else { (1 : UInt32) })
  si.set_pCommandBuffers(cbs)
  let sr = (dfn.vkQueueSubmit)(queue, (1 : UInt32), si, fence_out[0])
  let wr = (dfn.vkWaitForFences)(dev, (1 : UInt32), fence_out, (1 : UInt32), (10000000000 : UInt64))
  let px = @vk.download_buffer(dev, rmem, 64 * 64 * 4)
  let mut pixels = 0
  for i = 0; i < 64 * 64; i = i + 1 {
    if px[i * 4] != (0 : Byte) || px[i * 4 + 1] != (0 : Byte) || px[i * 4 + 2] != (0 : Byte) {
      pixels = pixels + 1
    }
  }
  let _ = (dfn.vkDeviceWaitIdle)(dev)
  (dfn.vkDestroyFence)(dev, fence_out[0], na)
  (dfn.vkDestroyCommandPool)(dev, cp_out[0], na)
  (dfn.vkDestroyQueryPool)(dev, qp, na)
  if dutr == 0 {
    (dfn.vkDestroyDescriptorUpdateTemplate)(dev, dut_out[0], na)
  }
  (dfn.vkDestroyDescriptorPool)(dev, pool_out[0], na)
  (dfn.vkDestroyDescriptorSetLayout)(dev, dsl_a[0], na)
  (dfn.vkDestroyDescriptorSetLayout)(dev, dsl_b[0], na)
  if gpr1 == 0 {
    (dfn.vkDestroyPipeline)(dev, pipe1, na)
  }
  (dfn.vkDestroyPipeline)(dev, pipe, na)
  (dfn.vkDestroyPipelineLayout)(dev, layout2, na)
  (dfn.vkDestroyShaderModule)(dev, vsm_out[0], na)
  (dfn.vkDestroyShaderModule)(dev, fsm_out[0], na)
  (dfn.vkDestroyFramebuffer)(dev, fb, na)
  (dfn.vkDestroyRenderPass)(dev, rp, na)
  (dfn.vkDestroyImageView)(dev, view, na)
  (dfn.vkDestroyImage)(dev, img, na)
  (dfn.vkFreeMemory)(dev, imem_out[0], na)
  (dfn.vkDestroyBuffer)(dev, ubuf, na)
  (dfn.vkFreeMemory)(dev, umem, na)
  (dfn.vkDestroyBuffer)(dev, ibuf, na)
  (dfn.vkFreeMemory)(dev, imem2, na)
  (dfn.vkDestroyBuffer)(dev, pred, na)
  (dfn.vkFreeMemory)(dev, premem, na)
  (dfn.vkDestroyBuffer)(dev, mark, na)
  (dfn.vkFreeMemory)(dev, markmem, na)
  (dfn.vkDestroyBuffer)(dev, rbuf, na)
  (dfn.vkFreeMemory)(dev, rmem, na)
  (dfn.vkDestroyDevice)(dev, na)
  @vk.destroy_debug_messenger(inst, ifn, messenger)
  (ifn.vkDestroyInstance)(inst, na)
  println("[20-rp2] commands=\{n} submit=\{sr} wait=\{wr} pixels=\{pixels} errors=\{g_errors.val}")
  if sr == 0 && wr == 0 && pixels > 0 && n >= 15 && g_errors.val == 0 {
    println("[20-rp2] OK — \{n} renderpass2/query/push-descriptor commands, \{pixels} pixels, 0 validation errors")
  } else {
    println("[20-rp2] FAIL — submit=\{sr} wait=\{wr} pixels=\{pixels} n=\{n} errors=\{g_errors.val}")
  }
}