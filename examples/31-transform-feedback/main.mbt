// Example 31 — Transform Feedback + Local Read + Extended Dynamic State batch.
// Covers vkCmdBindTransformFeedbackBuffersEXT, vkCmdBeginTransformFeedbackEXT,
// vkCmdEndTransformFeedbackEXT, vkCmdDrawIndirectByteCountEXT,
// vkCmdSetRenderingInputAttachmentIndices[KHR], vkCmdSetDepthClampRangeEXT,
// vkCmdSetDepthBias2EXT, vkCmdSetSampleLocationsEXT,
// vkCmdSetAttachmentFeedbackLoopEnableEXT, vkCmdBindShadersEXT.

let g_errors : Ref[Int] = Ref(0)

///|
fn main {
  let na = @vk.VkAllocationCallbacks::null()
  let app = @vk.VkApplicationInfo::new()
  app.set_pApplicationName(@vk.cstr("Tycho31TF"))
  app.set_apiVersion((4210688 : UInt32)) // 1.4

  let ici = @vk.VkInstanceCreateInfo::new()
  ici.set_pApplicationInfo(app)
  ici.set_enabledLayerCount((1 : UInt32))
  ici.set_ppEnabledLayerNames(@vk.cstr_array(["VK_LAYER_KHRONOS_validation"]))
  ici.set_enabledExtensionCount((1 : UInt32))
  ici.set_ppEnabledExtensionNames(@vk.cstr_array(["VK_EXT_debug_utils"]))
  let inst_out = FixedArray::make(1, @vk.VkInstance::null())
  let ir = @vk.vkCreateInstance(ici, na, inst_out)
  if ir != 0 {
    println("[31-tf] FAIL — vkCreateInstance=\{ir}")
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
      println("[31-tf] VALIDATION: \{@vk.read_cstr(data.get_pMessage())}")
      (0 : UInt32)
    },
  )

  let pc = FixedArray::make(1, (16 : UInt32))
  let devs = FixedArray::make(16, @vk.VkPhysicalDevice::null())
  let _ = (ifn.vkEnumeratePhysicalDevices)(inst, pc, devs)
  let phys = devs[0]

  // Query extensions
  let dec = FixedArray::make(1, (0 : UInt32))
  let _ = (ifn.vkEnumerateDeviceExtensionProperties)(phys, (0 : UInt64), dec, @vk.VkExtensionProperties::null())
  let nde = dec[0].reinterpret_as_int()
  let dep = @vk.VkExtensionProperties::array(nde)
  let _ = (ifn.vkEnumerateDeviceExtensionProperties)(phys, (0 : UInt64), dec, dep)
  let has_ext = fn(name : String) -> Bool {
    for i = 0; i < nde; i = i + 1 {
      if dep.get_extensionName_string_at(i) == name {
        return true
      }
    }
    false
  }

  if !has_ext("VK_EXT_transform_feedback") {
    println("[31-tf] SKIP — VK_EXT_transform_feedback not supported")
    @vk.destroy_debug_messenger(inst, ifn, messenger)
    (ifn.vkDestroyInstance)(inst, na)
    return
  }

  // Query features
  let tf_q = @vk.VkPhysicalDeviceTransformFeedbackFeaturesEXT::new()
  let lr_q = @vk.VkPhysicalDeviceDynamicRenderingLocalReadFeatures::new()
  let f13_q = @vk.VkPhysicalDeviceVulkan13Features::new()
  let dcc_q = @vk.VkPhysicalDeviceDepthClampControlFeaturesEXT::new()
  let dbc_q = @vk.VkPhysicalDeviceDepthBiasControlFeaturesEXT::new()
  let afl_q = @vk.VkPhysicalDeviceAttachmentFeedbackLoopDynamicStateFeaturesEXT::new()
  let afll_q = @vk.VkPhysicalDeviceAttachmentFeedbackLoopLayoutFeaturesEXT::new()
  let so_q = @vk.VkPhysicalDeviceShaderObjectFeaturesEXT::new()
  let f2_q = @vk.VkPhysicalDeviceFeatures2::new()
  f2_q.set_pNext(f13_q.as_ptr())
  f13_q.set_pNext(tf_q.as_ptr())
  tf_q.set_pNext(lr_q.as_ptr())
  lr_q.set_pNext(dcc_q.as_ptr())
  dcc_q.set_pNext(dbc_q.as_ptr())
  dbc_q.set_pNext(afl_q.as_ptr())
  afl_q.set_pNext(afll_q.as_ptr())
  afll_q.set_pNext(so_q.as_ptr())
  (ifn.vkGetPhysicalDeviceFeatures2)(phys, f2_q)

  let tf_en = @vk.VkPhysicalDeviceTransformFeedbackFeaturesEXT::new()
  tf_en.set_transformFeedback(tf_q.get_transformFeedback())
  let lr_en = @vk.VkPhysicalDeviceDynamicRenderingLocalReadFeatures::new()
  lr_en.set_dynamicRenderingLocalRead(lr_q.get_dynamicRenderingLocalRead())
  let f13_en = @vk.VkPhysicalDeviceVulkan13Features::new()
  f13_en.set_dynamicRendering((1 : UInt32))
  f13_en.set_synchronization2((1 : UInt32))
  let dcc_en = @vk.VkPhysicalDeviceDepthClampControlFeaturesEXT::new()
  dcc_en.set_depthClampControl(dcc_q.get_depthClampControl())
  let dbc_en = @vk.VkPhysicalDeviceDepthBiasControlFeaturesEXT::new()
  dbc_en.set_depthBiasControl(dbc_q.get_depthBiasControl())
  let afl_en = @vk.VkPhysicalDeviceAttachmentFeedbackLoopDynamicStateFeaturesEXT::new()
  afl_en.set_attachmentFeedbackLoopDynamicState(afl_q.get_attachmentFeedbackLoopDynamicState())
  let afll_en = @vk.VkPhysicalDeviceAttachmentFeedbackLoopLayoutFeaturesEXT::new()
  afll_en.set_attachmentFeedbackLoopLayout(afll_q.get_attachmentFeedbackLoopLayout())
  let so_en = @vk.VkPhysicalDeviceShaderObjectFeaturesEXT::new()
  so_en.set_shaderObject(so_q.get_shaderObject())

  f13_en.set_pNext(tf_en.as_ptr())
  tf_en.set_pNext(lr_en.as_ptr())
  lr_en.set_pNext(dcc_en.as_ptr())
  dcc_en.set_pNext(dbc_en.as_ptr())
  dbc_en.set_pNext(afl_en.as_ptr())
  afl_en.set_pNext(afll_en.as_ptr())
  afll_en.set_pNext(so_en.as_ptr())

  let want = [
    "VK_EXT_transform_feedback",
    "VK_KHR_dynamic_rendering_local_read",
    "VK_EXT_depth_clamp_control",
    "VK_EXT_depth_bias_control",
    "VK_EXT_sample_locations",
    "VK_EXT_attachment_feedback_loop_layout",
    "VK_EXT_attachment_feedback_loop_dynamic_state",
    "VK_EXT_shader_object",
  ]
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
  dci.set_pNext(f13_en.as_ptr())
  dci.set_queueCreateInfoCount((1 : UInt32))
  dci.set_pQueueCreateInfos(qci)
  dci.set_enabledExtensionCount(nden.reinterpret_as_uint())
  dci.set_ppEnabledExtensionNames(@vk.cstr_array(den))
  let dev_out = FixedArray::make(1, @vk.VkDevice::null())
  let dr = (ifn.vkCreateDevice)(phys, dci, na, dev_out)
  if dr != 0 {
    println("[31-tf] FAIL — vkCreateDevice=\{dr}")
    return
  }
  let dev = dev_out[0]
  let dfn = @vk.DeviceFn::load(dev)
  let has = fn(name : String) -> Bool {
    (ifn.vkGetDeviceProcAddr)(dev, @vk.cstr(name)) != (0 : UInt64)
  }
  let q_out = FixedArray::make(1, @vk.VkQueue::null())
  (dfn.vkGetDeviceQueue)(dev, (0 : UInt32), (0 : UInt32), q_out)
  let queue = q_out[0]

  let mp = @vk.VkPhysicalDeviceMemoryProperties::new()
  (ifn.vkGetPhysicalDeviceMemoryProperties)(phys, mp)
  let memtype = fn(bits : UInt32, props : UInt32) -> UInt32 {
    for i = 0; i < mp.get_memoryTypeCount().reinterpret_as_int(); i = i + 1 {
      if (bits & ((1 : UInt32) << i)) != (0 : UInt32) {
        if (mp.get_memoryTypes_at(i).get_propertyFlags() & props) == props {
          return i.reinterpret_as_uint()
        }
      }
    }
    (0 : UInt32)
  }
  let host = @vk.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | @vk.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT
  let mkbuf = fn(size : UInt64, usage : UInt32) -> (@vk.VkBuffer, @vk.VkDeviceMemory) {
    let ci = @vk.VkBufferCreateInfo::new()
    ci.set_size(size)
    ci.set_usage(usage)
    let bo = FixedArray::make(1, @vk.VkBuffer::null())
    let _ = (dfn.vkCreateBuffer)(dev, ci, na, bo)
    let rq = @vk.VkMemoryRequirements::new()
    (dfn.vkGetBufferMemoryRequirements)(dev, bo[0], rq)
    let ai = @vk.VkMemoryAllocateInfo::new()
    ai.set_allocationSize(rq.get_size())
    ai.set_memoryTypeIndex(memtype(rq.get_memoryTypeBits(), host))
    let mo = FixedArray::make(1, @vk.VkDeviceMemory::null())
    let _ = (dfn.vkAllocateMemory)(dev, ai, na, mo)
    let _ = (dfn.vkBindBufferMemory)(dev, bo[0], mo[0], (0 : UInt64))
    (bo[0], mo[0])
  }

  // Transform feedback buffer + counter buffer
  let (tf_buf, tf_mem) = mkbuf((256 : UInt64), @vk.VK_BUFFER_USAGE_TRANSFORM_FEEDBACK_BUFFER_BIT_EXT | @vk.VK_BUFFER_USAGE_TRANSFER_SRC_BIT)
  let (cnt_buf, cnt_mem) = mkbuf((64 : UInt64), @vk.VK_BUFFER_USAGE_TRANSFORM_FEEDBACK_COUNTER_BUFFER_BIT_EXT | @vk.VK_BUFFER_USAGE_INDIRECT_BUFFER_BIT)

  // Offscreen color image (64x64)
  let ici_img = @vk.VkImageCreateInfo::new()
  ici_img.set_imageType(@vk.VK_IMAGE_TYPE_2D)
  ici_img.set_format(@vk.VK_FORMAT_R8G8B8A8_UNORM)
  let ext3 = @vk.VkExtent3D::new()
  ext3.set_width((64 : UInt32))
  ext3.set_height((64 : UInt32))
  ext3.set_depth((1 : UInt32))
  ici_img.set_extent(ext3)
  ici_img.set_mipLevels((1 : UInt32))
  ici_img.set_arrayLayers((1 : UInt32))
  ici_img.set_samples(@vk.VK_SAMPLE_COUNT_1_BIT)
  ici_img.set_tiling(@vk.VK_IMAGE_TILING_OPTIMAL)
  ici_img.set_usage(@vk.VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT | @vk.VK_IMAGE_USAGE_TRANSFER_SRC_BIT)
  let img_out = FixedArray::make(1, @vk.VkImage::null())
  let _ = (dfn.vkCreateImage)(dev, ici_img, na, img_out)
  let irq = @vk.VkMemoryRequirements::new()
  (dfn.vkGetImageMemoryRequirements)(dev, img_out[0], irq)
  let iai = @vk.VkMemoryAllocateInfo::new()
  iai.set_allocationSize(irq.get_size())
  iai.set_memoryTypeIndex(memtype(irq.get_memoryTypeBits(), @vk.VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT))
  let imem_out = FixedArray::make(1, @vk.VkDeviceMemory::null())
  let _ = (dfn.vkAllocateMemory)(dev, iai, na, imem_out)
  let _ = (dfn.vkBindImageMemory)(dev, img_out[0], imem_out[0], (0 : UInt64))
  let ivci = @vk.VkImageViewCreateInfo::new()
  ivci.set_image(img_out[0])
  ivci.set_viewType(@vk.VK_IMAGE_VIEW_TYPE_2D)
  ivci.set_format(@vk.VK_FORMAT_R8G8B8A8_UNORM)
  let sr = @vk.VkImageSubresourceRange::new()
  sr.set_aspectMask(@vk.VK_IMAGE_ASPECT_COLOR_BIT)
  sr.set_levelCount((1 : UInt32))
  sr.set_layerCount((1 : UInt32))
  ivci.set_subresourceRange(sr)
  let iv_out = FixedArray::make(1, @vk.VkImageView::null())
  let _ = (dfn.vkCreateImageView)(dev, ivci, na, iv_out)

  // Compile transform feedback shaders
  let vspv = @shader.compile_shader_file_env("examples/31-transform-feedback/tf.vert", @shader.SHADER_KIND_VERTEX, @shader.SHADER_ENV_VULKAN_1_3)
  let fspv = @shader.compile_shader_file_env("examples/31-transform-feedback/tf.frag", @shader.SHADER_KIND_FRAGMENT, @shader.SHADER_ENV_VULKAN_1_3)
  let vsm_ci = @vk.VkShaderModuleCreateInfo::new()
  vsm_ci.set_codeSize((vspv.length() * 4).to_uint64())
  vsm_ci.set_pCode(vspv)
  let vsm_out = FixedArray::make(1, @vk.VkShaderModule::null())
  let _ = (dfn.vkCreateShaderModule)(dev, vsm_ci, na, vsm_out)
  let fsm_ci = @vk.VkShaderModuleCreateInfo::new()
  fsm_ci.set_codeSize((fspv.length() * 4).to_uint64())
  fsm_ci.set_pCode(fspv)
  let fsm_out = FixedArray::make(1, @vk.VkShaderModule::null())
  let _ = (dfn.vkCreateShaderModule)(dev, fsm_ci, na, fsm_out)

  let plci = @vk.VkPipelineLayoutCreateInfo::new()
  let pl_out = FixedArray::make(1, @vk.VkPipelineLayout::null())
  let _ = (dfn.vkCreatePipelineLayout)(dev, plci, na, pl_out)

  // Dynamic states
  let dstates : Array[UInt32] = [@vk.VK_DYNAMIC_STATE_VIEWPORT, @vk.VK_DYNAMIC_STATE_SCISSOR]
  let use_dcc = has_ext("VK_EXT_depth_clamp_control") && dcc_q.get_depthClampControl() != 0 && has("vkCmdSetDepthClampRangeEXT")
  if use_dcc {
    dstates.push(@vk.VK_DYNAMIC_STATE_DEPTH_CLAMP_RANGE_EXT)
  }
  let use_dbc = has_ext("VK_EXT_depth_bias_control") && dbc_q.get_depthBiasControl() != 0 && has("vkCmdSetDepthBias2EXT")
  if use_dbc {
    dstates.push(@vk.VK_DYNAMIC_STATE_DEPTH_BIAS)
  }
  let use_afl = has_ext("VK_EXT_attachment_feedback_loop_dynamic_state") && afl_q.get_attachmentFeedbackLoopDynamicState() != 0 && has("vkCmdSetAttachmentFeedbackLoopEnableEXT")
  if use_afl {
    dstates.push(@vk.VK_DYNAMIC_STATE_ATTACHMENT_FEEDBACK_LOOP_ENABLE_EXT)
  }
  let ds_arr = FixedArray::make(dstates.length(), (0 : UInt32))
  for i = 0; i < dstates.length(); i = i + 1 {
    ds_arr[i] = dstates[i]
  }
  let dsci = @vk.VkPipelineDynamicStateCreateInfo::new()
  dsci.set_dynamicStateCount(ds_arr.length().reinterpret_as_uint())
  dsci.set_pDynamicStates(ds_arr)

  let stages = @vk.VkPipelineShaderStageCreateInfo::array(2)
  stages.set_stage_at(0, @vk.VK_SHADER_STAGE_VERTEX_BIT)
  stages.set_module_at(0, vsm_out[0])
  stages.set_pName_at(0, @vk.cstr("main"))
  stages.set_stage_at(1, @vk.VK_SHADER_STAGE_FRAGMENT_BIT)
  stages.set_module_at(1, fsm_out[0])
  stages.set_pName_at(1, @vk.cstr("main"))

  let vi = @vk.VkPipelineVertexInputStateCreateInfo::new()
  let ia = @vk.VkPipelineInputAssemblyStateCreateInfo::new()
  ia.set_topology(@vk.VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST)
  let vp_st = @vk.VkPipelineViewportStateCreateInfo::new()
  vp_st.set_viewportCount((1 : UInt32))
  vp_st.set_scissorCount((1 : UInt32))
  let rs = @vk.VkPipelineRasterizationStateCreateInfo::new()
  rs.set_polygonMode(@vk.VK_POLYGON_MODE_FILL)
  rs.set_cullMode(@vk.VK_CULL_MODE_NONE)
  rs.set_frontFace(@vk.VK_FRONT_FACE_CLOCKWISE)
  rs.set_lineWidth((1.0 : Float))
  let ms = @vk.VkPipelineMultisampleStateCreateInfo::new()
  ms.set_rasterizationSamples(@vk.VK_SAMPLE_COUNT_1_BIT)
  let cba = @vk.VkPipelineColorBlendAttachmentState::new()
  cba.set_colorWriteMask((15 : UInt32))
  let cb_st = @vk.VkPipelineColorBlendStateCreateInfo::new()
  cb_st.set_attachmentCount((1 : UInt32))
  cb_st.set_pAttachments(cba)
  let rend = @vk.VkPipelineRenderingCreateInfo::new()
  rend.set_colorAttachmentCount((1 : UInt32))
  rend.set_pColorAttachmentFormats(FixedArray::make(1, @vk.VK_FORMAT_R8G8B8A8_UNORM))

  let gpci = @vk.VkGraphicsPipelineCreateInfo::new()
  gpci.set_pNext(rend.as_ptr())
  gpci.set_stageCount((2 : UInt32))
  gpci.set_pStages(stages)
  gpci.set_pVertexInputState(vi)
  gpci.set_pInputAssemblyState(ia)
  gpci.set_pViewportState(vp_st)
  gpci.set_pRasterizationState(rs)
  gpci.set_pMultisampleState(ms)
  gpci.set_pColorBlendState(cb_st)
  gpci.set_pDynamicState(dsci)
  gpci.set_layout(pl_out[0])
  let pipe_out = FixedArray::make(1, @vk.VkPipeline::null())
  let pr = (dfn.vkCreateGraphicsPipelines)(dev, @vk.VkPipelineCache::null(), (1 : UInt32), gpci, na, pipe_out)

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

  let mut n = 0
  let bi = @vk.VkCommandBufferBeginInfo::new()
  let _ = (dfn.vkBeginCommandBuffer)(cb, bi)

  // Transition color attachment
  let bar = @vk.VkImageMemoryBarrier2::new()
  bar.set_srcStageMask(@vk.VK_PIPELINE_STAGE_2_TOP_OF_PIPE_BIT)
  bar.set_dstStageMask(@vk.VK_PIPELINE_STAGE_2_COLOR_ATTACHMENT_OUTPUT_BIT)
  bar.set_dstAccessMask(@vk.VK_ACCESS_2_COLOR_ATTACHMENT_WRITE_BIT)
  bar.set_oldLayout(@vk.VK_IMAGE_LAYOUT_UNDEFINED)
  bar.set_newLayout(@vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL)
  bar.set_image(img_out[0])
  bar.set_subresourceRange(sr)
  let dep_i = @vk.VkDependencyInfo::new()
  dep_i.set_imageMemoryBarrierCount((1 : UInt32))
  dep_i.set_pImageMemoryBarriers(bar)
  (dfn.vkCmdPipelineBarrier2)(cb, dep_i)

  let att = @vk.VkRenderingAttachmentInfo::new()
  att.set_imageView(iv_out[0])
  att.set_imageLayout(@vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL)
  att.set_loadOp(@vk.VK_ATTACHMENT_LOAD_OP_CLEAR)
  att.set_storeOp(@vk.VK_ATTACHMENT_STORE_OP_STORE)
  let cv = @vk.VkClearValue::new()
  cv.set_color_rgba((0.0 : Float), (0.0 : Float), (0.0 : Float), (1.0 : Float))
  att.set_clearValue(cv)
  let rarea = @vk.VkRect2D::new()
  let rext = @vk.VkExtent2D::new()
  rext.set_width((64 : UInt32))
  rext.set_height((64 : UInt32))
  rarea.set_extent(rext)
  let rinfo = @vk.VkRenderingInfo::new()
  rinfo.set_renderArea(rarea)
  rinfo.set_layerCount((1 : UInt32))
  rinfo.set_colorAttachmentCount((1 : UInt32))
  rinfo.set_pColorAttachments(att)

  (dfn.vkCmdBeginRendering)(cb, rinfo)
  (dfn.vkCmdBindPipeline)(cb, @vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_out[0])
  let vp = @vk.VkViewport::new()
  vp.set_width((64.0 : Float))
  vp.set_height((64.0 : Float))
  vp.set_maxDepth((1.0 : Float))
  (dfn.vkCmdSetViewport)(cb, (0 : UInt32), (1 : UInt32), vp)
  (dfn.vkCmdSetScissor)(cb, (0 : UInt32), (1 : UInt32), rarea)

  // Local read input attachment indices (1.4 core + KHR alias)
  if lr_q.get_dynamicRenderingLocalRead() != 0 {
    let iai_lr = @vk.VkRenderingInputAttachmentIndexInfo::new()
    iai_lr.set_colorAttachmentCount((1 : UInt32))
    iai_lr.set_pColorAttachmentInputIndices(FixedArray::make(1, (0xFFFFFFFF : UInt32)))
    if has("vkCmdSetRenderingInputAttachmentIndices") {
      (dfn.vkCmdSetRenderingInputAttachmentIndices)(cb, iai_lr)
      n = n + 1
    }
    if has("vkCmdSetRenderingInputAttachmentIndicesKHR") {
      (dfn.vkCmdSetRenderingInputAttachmentIndicesKHR)(cb, iai_lr)
      n = n + 1
    }
    iai_lr.free()
  }

  // Extended dynamic states
  if use_dcc {
    let rng = @vk.VkDepthClampRangeEXT::new()
    rng.set_minDepthClamp((0.0 : Float))
    rng.set_maxDepthClamp((1.0 : Float))
    (dfn.vkCmdSetDepthClampRangeEXT)(cb, @vk.VK_DEPTH_CLAMP_MODE_USER_DEFINED_RANGE_EXT, rng)
    rng.free()
    n = n + 1
  }
  if use_dbc {
    let dbi = @vk.VkDepthBiasInfoEXT::new()
    dbi.set_depthBiasConstantFactor((0.0 : Float))
    dbi.set_depthBiasClamp((0.0 : Float))
    dbi.set_depthBiasSlopeFactor((0.0 : Float))
    (dfn.vkCmdSetDepthBias2EXT)(cb, dbi)
    dbi.free()
    n = n + 1
  }
  if use_afl {
    (dfn.vkCmdSetAttachmentFeedbackLoopEnableEXT)(cb, (0 : UInt32))
    n = n + 1
  }

  // Transform feedback: bind -> begin -> draw -> end -> draw indirect byte count
  let tf_bufs = FixedArray::make(1, tf_buf)
  let tf_offs = FixedArray::make(1, (0 : UInt64))
  let tf_szs = FixedArray::make(1, (256 : UInt64))
  (dfn.vkCmdBindTransformFeedbackBuffersEXT)(cb, (0 : UInt32), (1 : UInt32), tf_bufs, tf_offs, tf_szs)
  n = n + 1
  let cnt_bufs = FixedArray::make(1, cnt_buf)
  let cnt_offs = FixedArray::make(1, (0 : UInt64))
  (dfn.vkCmdBeginTransformFeedbackEXT)(cb, (0 : UInt32), (0 : UInt32), FixedArray::make(0, @vk.VkBuffer::null()), FixedArray::make(0, (0 : UInt64)))
  n = n + 1
  (dfn.vkCmdDraw)(cb, (3 : UInt32), (1 : UInt32), (0 : UInt32), (0 : UInt32))
  (dfn.vkCmdEndTransformFeedbackEXT)(cb, (0 : UInt32), (1 : UInt32), cnt_bufs, cnt_offs)
  n = n + 1

  (dfn.vkCmdEndRendering)(cb)

  // Barrier so counter buffer write is visible to DrawIndirectByteCountEXT
  let cbar = @vk.VkBufferMemoryBarrier2::new()
  cbar.set_srcStageMask(@vk.VK_PIPELINE_STAGE_2_TRANSFORM_FEEDBACK_BIT_EXT)
  cbar.set_srcAccessMask(@vk.VK_ACCESS_2_TRANSFORM_FEEDBACK_COUNTER_WRITE_BIT_EXT)
  cbar.set_dstStageMask(@vk.VK_PIPELINE_STAGE_2_DRAW_INDIRECT_BIT)
  cbar.set_dstAccessMask(@vk.VK_ACCESS_2_INDIRECT_COMMAND_READ_BIT)
  cbar.set_buffer(cnt_buf)
  cbar.set_size((64 : UInt64))
  let cdep = @vk.VkDependencyInfo::new()
  cdep.set_bufferMemoryBarrierCount((1 : UInt32))
  cdep.set_pBufferMemoryBarriers(cbar)
  (dfn.vkCmdPipelineBarrier2)(cb, cdep)

  // Second rendering pass: DrawIndirectByteCountEXT
  (dfn.vkCmdBeginRendering)(cb, rinfo)
  (dfn.vkCmdBindPipeline)(cb, @vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_out[0])
  (dfn.vkCmdSetViewport)(cb, (0 : UInt32), (1 : UInt32), vp)
  (dfn.vkCmdSetScissor)(cb, (0 : UInt32), (1 : UInt32), rarea)
  (dfn.vkCmdDrawIndirectByteCountEXT)(cb, (1 : UInt32), (0 : UInt32), cnt_buf, (0 : UInt64), (0 : UInt32), (16 : UInt32))
  n = n + 1
  (dfn.vkCmdEndRendering)(cb)

  // Also test vkCmdBindShadersEXT with null shader (unbind) when shader_object is supported
  if has_ext("VK_EXT_shader_object") && so_q.get_shaderObject() != 0 && has("vkCmdBindShadersEXT") {
    let stg = FixedArray::make(1, @vk.VK_SHADER_STAGE_COMPUTE_BIT)
    let shs = FixedArray::make(1, @vk.VkShaderEXT::null())
    (dfn.vkCmdBindShadersEXT)(cb, (1 : UInt32), stg, shs)
    n = n + 1
  }

  let _ = (dfn.vkEndCommandBuffer)(cb)

  let fci = @vk.VkFenceCreateInfo::new()
  let fence_out = FixedArray::make(1, @vk.VkFence::null())
  let _ = (dfn.vkCreateFence)(dev, fci, na, fence_out)
  let si = @vk.VkSubmitInfo::new()
  si.set_commandBufferCount((1 : UInt32))
  si.set_pCommandBuffers(cb_out)
  let sres = (dfn.vkQueueSubmit)(queue, (1 : UInt32), si, fence_out[0])
  let wres = (dfn.vkWaitForFences)(dev, (1 : UInt32), fence_out, (1 : UInt32), (10000000000 : UInt64))

  // Verify transform feedback actually wrote vertex 0 (w = 1.0 -> 0x3f800000 at bytes 12..15)
  let tf_bytes = @vk.download_buffer(dev, tf_mem, 48)
  let tf_ok = tf_bytes[14] == (0x80 : Byte) && tf_bytes[15] == (0x3F : Byte)

  (dfn.vkDestroyFence)(dev, fence_out[0], na)
  (dfn.vkDestroyCommandPool)(dev, cp_out[0], na)
  (dfn.vkDestroyPipeline)(dev, pipe_out[0], na)
  (dfn.vkDestroyPipelineLayout)(dev, pl_out[0], na)
  (dfn.vkDestroyShaderModule)(dev, vsm_out[0], na)
  (dfn.vkDestroyShaderModule)(dev, fsm_out[0], na)
  (dfn.vkDestroyImageView)(dev, iv_out[0], na)
  (dfn.vkDestroyImage)(dev, img_out[0], na)
  (dfn.vkFreeMemory)(dev, imem_out[0], na)
  (dfn.vkDestroyBuffer)(dev, tf_buf, na)
  (dfn.vkFreeMemory)(dev, tf_mem, na)
  (dfn.vkDestroyBuffer)(dev, cnt_buf, na)
  (dfn.vkFreeMemory)(dev, cnt_mem, na)
  (dfn.vkDestroyDevice)(dev, na)
  @vk.destroy_debug_messenger(inst, ifn, messenger)
  (ifn.vkDestroyInstance)(inst, na)

  println("[31-tf] commands=\{n} pipe=\{pr} submit=\{sres} wait=\{wres} tf_ok=\{tf_ok} errors=\{g_errors.val}")
  if pr == 0 && sres == 0 && wres == 0 && tf_ok && n >= 4 && g_errors.val == 0 {
    println("[31-tf] OK — \{n} transform-feedback/local-read/state commands verified, 0 validation errors")
  } else {
    println("[31-tf] FAIL — pr=\{pr} submit=\{sres} wait=\{wres} tf_ok=\{tf_ok} n=\{n} errors=\{g_errors.val}")
  }
}
