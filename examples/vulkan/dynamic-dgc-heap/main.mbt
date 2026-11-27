// vulkan/dynamic-dgc-heap — Extended Dynamic State 3 (NV dynamic states), Shading Rate Image NV,
// Mesh Shader NV, Maintenance10 EndRendering2, Descriptor Buffer Embedded Samplers,
// Descriptor Heap EXT, and Device Generated Commands NV/Compute.

let na : @vk.VkAllocationCallbacks = @vk.VkAllocationCallbacks::null()
let g_errors : Ref[Int] = Ref(0)

///|
fn main {
  let app = @vk.VkApplicationInfo::new()
  app.set_pApplicationName(@vk.cstr("Tycho34DynDgcHeap"))
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
    println("[34-dgc] FAIL — vkCreateInstance=\{ir}")
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
      println("[34-dgc] VALIDATION: \{@vk.read_cstr(data.get_pMessage())}")
      (0 : UInt32)
    },
  )

  let pc = FixedArray::make(1, (16 : UInt32))
  let devs = FixedArray::make(16, @vk.VkPhysicalDevice::null())
  let _ = (ifn.vkEnumeratePhysicalDevices)(inst, pc, devs)
  let phys = devs[0]

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

  let eds3_q = @vk.VkPhysicalDeviceExtendedDynamicState3FeaturesEXT::new()
  let db_q = @vk.VkPhysicalDeviceDescriptorBufferFeaturesEXT::new()
  let m10_q = @vk.VkPhysicalDeviceMaintenance10FeaturesKHR::new()
  let f12_q = @vk.VkPhysicalDeviceVulkan12Features::new()
  let f13_q = @vk.VkPhysicalDeviceVulkan13Features::new()
  let f14_q = @vk.VkPhysicalDeviceVulkan14Features::new()
  let f2_q = @vk.VkPhysicalDeviceFeatures2::new()
  f2_q.set_pNext(eds3_q.as_ptr())
  eds3_q.set_pNext(db_q.as_ptr())
  db_q.set_pNext(m10_q.as_ptr())
  m10_q.set_pNext(f12_q.as_ptr())
  f12_q.set_pNext(f13_q.as_ptr())
  f13_q.set_pNext(f14_q.as_ptr())
  (ifn.vkGetPhysicalDeviceFeatures2)(phys, f2_q)

  let eds3_en = @vk.VkPhysicalDeviceExtendedDynamicState3FeaturesEXT::new()
  eds3_en.set_extendedDynamicState3ViewportWScalingEnable(eds3_q.get_extendedDynamicState3ViewportWScalingEnable())
  eds3_en.set_extendedDynamicState3ViewportSwizzle(eds3_q.get_extendedDynamicState3ViewportSwizzle())
  eds3_en.set_extendedDynamicState3ShadingRateImageEnable(eds3_q.get_extendedDynamicState3ShadingRateImageEnable())
  eds3_en.set_extendedDynamicState3CoverageToColorEnable(eds3_q.get_extendedDynamicState3CoverageToColorEnable())
  eds3_en.set_extendedDynamicState3CoverageToColorLocation(eds3_q.get_extendedDynamicState3CoverageToColorLocation())
  eds3_en.set_extendedDynamicState3CoverageModulationMode(eds3_q.get_extendedDynamicState3CoverageModulationMode())
  eds3_en.set_extendedDynamicState3CoverageModulationTableEnable(eds3_q.get_extendedDynamicState3CoverageModulationTableEnable())
  eds3_en.set_extendedDynamicState3CoverageModulationTable(eds3_q.get_extendedDynamicState3CoverageModulationTable())
  eds3_en.set_extendedDynamicState3CoverageReductionMode(eds3_q.get_extendedDynamicState3CoverageReductionMode())
  eds3_en.set_extendedDynamicState3RepresentativeFragmentTestEnable(eds3_q.get_extendedDynamicState3RepresentativeFragmentTestEnable())
  eds3_en.set_extendedDynamicState3ColorBlendAdvanced(eds3_q.get_extendedDynamicState3ColorBlendAdvanced())

  let db_en = @vk.VkPhysicalDeviceDescriptorBufferFeaturesEXT::new()
  db_en.set_descriptorBuffer(db_q.get_descriptorBuffer())
  let m10_en = @vk.VkPhysicalDeviceMaintenance10FeaturesKHR::new()
  m10_en.set_maintenance10(m10_q.get_maintenance10())
  let f12_en = @vk.VkPhysicalDeviceVulkan12Features::new()
  f12_en.set_bufferDeviceAddress(f12_q.get_bufferDeviceAddress())
  let f13_en = @vk.VkPhysicalDeviceVulkan13Features::new()
  f13_en.set_dynamicRendering((1 : UInt32))
  f13_en.set_synchronization2((1 : UInt32))
  f13_en.set_maintenance4((1 : UInt32))
  let f14_en = @vk.VkPhysicalDeviceVulkan14Features::new()
  f14_en.set_maintenance5(f14_q.get_maintenance5())
  f14_en.set_maintenance6(f14_q.get_maintenance6())

  eds3_en.set_pNext(db_en.as_ptr())
  db_en.set_pNext(m10_en.as_ptr())
  m10_en.set_pNext(f12_en.as_ptr())
  f12_en.set_pNext(f13_en.as_ptr())
  f13_en.set_pNext(f14_en.as_ptr())

  let want = [
    "VK_EXT_extended_dynamic_state3",
    "VK_EXT_descriptor_buffer",
    "VK_KHR_maintenance10",
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
  dci.set_pNext(eds3_en.as_ptr())
  dci.set_queueCreateInfoCount((1 : UInt32))
  dci.set_pQueueCreateInfos(qci)
  dci.set_enabledExtensionCount(nden.reinterpret_as_uint())
  dci.set_ppEnabledExtensionNames(@vk.cstr_array(den))
  let dev_out = FixedArray::make(1, @vk.VkDevice::null())
  let dr = (ifn.vkCreateDevice)(phys, dci, na, dev_out)
  if dr != 0 {
    println("[34-dgc] FAIL — vkCreateDevice=\{dr}")
    return
  }
  let dev = dev_out[0]
  let dfn = @vk.DeviceFn::load(dev)
  let has = fn(name : String) -> Bool {
    (ifn.vkGetDeviceProcAddr)(dev, @vk.cstr(name)) != (0 : UInt64)
  }

  let mut n = 0
  // Coverage evidence: `avail` = extension-gated groups this driver can verify,
  // `ran` = groups that actually executed a command, so a driver without these
  // extensions cannot report OK after verifying nothing.
  let mut avail = 0
  let mut ran = 0

  // Command pool & buffer
  let cpci = @vk.VkCommandPoolCreateInfo::new()
  cpci.set_queueFamilyIndex((0 : UInt32))
  cpci.set_flags(@vk.VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT)
  let cp_out = FixedArray::make(1, @vk.VkCommandPool::null())
  let _ = (dfn.vkCreateCommandPool)(dev, cpci, na, cp_out)
  let cbai = @vk.VkCommandBufferAllocateInfo::new()
  cbai.set_commandPool(cp_out[0])
  cbai.set_level(@vk.VK_COMMAND_BUFFER_LEVEL_PRIMARY)
  cbai.set_commandBufferCount((1 : UInt32))
  let cb_out = FixedArray::make(1, @vk.VkCommandBuffer::null())
  let _ = (dfn.vkAllocateCommandBuffers)(dev, cbai, cb_out)
  let cb = cb_out[0]

  // 1. Descriptor buffer embedded samplers (EXT + Maintenance6 EXT2)
  let mut emb_pl = @vk.VkPipelineLayout::null()
  let mut emb_dsl = @vk.VkDescriptorSetLayout::null()
  let mut emb_samp = @vk.VkSampler::null()
  if has_ext("VK_EXT_descriptor_buffer") && db_q.get_descriptorBuffer() != 0 {
    let sci = @vk.VkSamplerCreateInfo::new()
    sci.set_magFilter(@vk.VK_FILTER_NEAREST)
    sci.set_minFilter(@vk.VK_FILTER_NEAREST)
    let so = FixedArray::make(1, @vk.VkSampler::null())
    if (dfn.vkCreateSampler)(dev, sci, na, so) == 0 {
      emb_samp = so[0]
      let dslb = @vk.VkDescriptorSetLayoutBinding::new()
      dslb.set_binding((0 : UInt32))
      dslb.set_descriptorType(@vk.VK_DESCRIPTOR_TYPE_SAMPLER)
      dslb.set_descriptorCount((1 : UInt32))
      dslb.set_stageFlags(@vk.VK_SHADER_STAGE_COMPUTE_BIT)
      dslb.set_pImmutableSamplers(FixedArray::make(1, emb_samp))
      let dslci = @vk.VkDescriptorSetLayoutCreateInfo::new()
      dslci.set_flags(
        @vk.VK_DESCRIPTOR_SET_LAYOUT_CREATE_DESCRIPTOR_BUFFER_BIT_EXT |
        @vk.VK_DESCRIPTOR_SET_LAYOUT_CREATE_EMBEDDED_IMMUTABLE_SAMPLERS_BIT_EXT,
      )
      dslci.set_bindingCount((1 : UInt32))
      dslci.set_pBindings(dslb)
      let dslo = FixedArray::make(1, @vk.VkDescriptorSetLayout::null())
      if (dfn.vkCreateDescriptorSetLayout)(dev, dslci, na, dslo) == 0 {
        emb_dsl = dslo[0]
        let plci = @vk.VkPipelineLayoutCreateInfo::new()
        plci.set_setLayoutCount((1 : UInt32))
        plci.set_pSetLayouts(dslo)
        let plo = FixedArray::make(1, @vk.VkPipelineLayout::null())
        if (dfn.vkCreatePipelineLayout)(dev, plci, na, plo) == 0 {
          emb_pl = plo[0]
        }
        plci.free()
      }
      dslci.free()
      dslb.free()
    }
    sci.free()
  }

  let bi = @vk.VkCommandBufferBeginInfo::new()
  let _ = (dfn.vkBeginCommandBuffer)(cb, bi)

  let before_1 = n
  if emb_pl.as_ptr() != (0 : UInt64) {
    avail = avail + 1
    if has("vkCmdBindDescriptorBufferEmbeddedSamplersEXT") {
      (dfn.vkCmdBindDescriptorBufferEmbeddedSamplersEXT)(
        cb,
        @vk.VK_PIPELINE_BIND_POINT_COMPUTE,
        emb_pl,
        (0 : UInt32),
      )
      n = n + 1
    }
    if f14_q.get_maintenance6() != 0 && has("vkCmdBindDescriptorBufferEmbeddedSamplers2EXT") {
      let info = @vk.VkBindDescriptorBufferEmbeddedSamplersInfoEXT::new()
      info.set_stageFlags(@vk.VK_SHADER_STAGE_COMPUTE_BIT)
      info.set_layout(emb_pl)
      info.set_set((0 : UInt32))
      (dfn.vkCmdBindDescriptorBufferEmbeddedSamplers2EXT)(cb, info)
      info.free()
      n = n + 1
    }
  }
  if n > before_1 {
    ran = ran + 1
  }

  // 2. Extended Dynamic State 3 (11 NV dynamic states)
  // The extension alone is not proof: some drivers expose EDS3 without any of
  // these NV states, so only expect commands when a state feature is advertised.
  let before_2 = n
  let eds3_any = has_ext("VK_EXT_extended_dynamic_state3") &&
    (eds3_q.get_extendedDynamicState3ViewportWScalingEnable() != 0 ||
      eds3_q.get_extendedDynamicState3ViewportSwizzle() != 0 ||
      eds3_q.get_extendedDynamicState3ShadingRateImageEnable() != 0 ||
      eds3_q.get_extendedDynamicState3CoverageToColorEnable() != 0 ||
      eds3_q.get_extendedDynamicState3CoverageToColorLocation() != 0 ||
      eds3_q.get_extendedDynamicState3CoverageModulationMode() != 0 ||
      eds3_q.get_extendedDynamicState3CoverageModulationTableEnable() != 0 ||
      eds3_q.get_extendedDynamicState3CoverageModulationTable() != 0 ||
      eds3_q.get_extendedDynamicState3CoverageReductionMode() != 0 ||
      eds3_q.get_extendedDynamicState3RepresentativeFragmentTestEnable() != 0 ||
      eds3_q.get_extendedDynamicState3ColorBlendAdvanced() != 0)
  if eds3_any {
    avail = avail + 1
  }
  if has_ext("VK_EXT_extended_dynamic_state3") {
    if eds3_q.get_extendedDynamicState3ViewportWScalingEnable() != 0 && has("vkCmdSetViewportWScalingEnableNV") {
      (dfn.vkCmdSetViewportWScalingEnableNV)(cb, (0 : UInt32))
      n = n + 1
    }
    if eds3_q.get_extendedDynamicState3ViewportSwizzle() != 0 && has("vkCmdSetViewportSwizzleNV") {
      let sw = @vk.VkViewportSwizzleNV::new()
      (dfn.vkCmdSetViewportSwizzleNV)(cb, (0 : UInt32), (1 : UInt32), sw)
      sw.free()
      n = n + 1
    }
    if eds3_q.get_extendedDynamicState3ShadingRateImageEnable() != 0 && has("vkCmdSetShadingRateImageEnableNV") {
      (dfn.vkCmdSetShadingRateImageEnableNV)(cb, (0 : UInt32))
      n = n + 1
    }
    if eds3_q.get_extendedDynamicState3CoverageToColorEnable() != 0 && has("vkCmdSetCoverageToColorEnableNV") {
      (dfn.vkCmdSetCoverageToColorEnableNV)(cb, (0 : UInt32))
      n = n + 1
    }
    if eds3_q.get_extendedDynamicState3CoverageToColorLocation() != 0 && has("vkCmdSetCoverageToColorLocationNV") {
      (dfn.vkCmdSetCoverageToColorLocationNV)(cb, (0 : UInt32))
      n = n + 1
    }
    if eds3_q.get_extendedDynamicState3CoverageModulationMode() != 0 && has("vkCmdSetCoverageModulationModeNV") {
      (dfn.vkCmdSetCoverageModulationModeNV)(cb, (0 : UInt32))
      n = n + 1
    }
    if eds3_q.get_extendedDynamicState3CoverageModulationTableEnable() != 0 && has("vkCmdSetCoverageModulationTableEnableNV") {
      (dfn.vkCmdSetCoverageModulationTableEnableNV)(cb, (0 : UInt32))
      n = n + 1
    }
    if eds3_q.get_extendedDynamicState3CoverageModulationTable() != 0 && has("vkCmdSetCoverageModulationTableNV") {
      (dfn.vkCmdSetCoverageModulationTableNV)(cb, (1 : UInt32), FixedArray::make(1, (1.0 : Float)))
      n = n + 1
    }
    if eds3_q.get_extendedDynamicState3CoverageReductionMode() != 0 && has("vkCmdSetCoverageReductionModeNV") {
      (dfn.vkCmdSetCoverageReductionModeNV)(cb, (0 : UInt32))
      n = n + 1
    }
    if eds3_q.get_extendedDynamicState3RepresentativeFragmentTestEnable() != 0 && has("vkCmdSetRepresentativeFragmentTestEnableNV") {
      (dfn.vkCmdSetRepresentativeFragmentTestEnableNV)(cb, (0 : UInt32))
      n = n + 1
    }
    if eds3_q.get_extendedDynamicState3ColorBlendAdvanced() != 0 && has("vkCmdSetColorBlendAdvancedEXT") {
      let cba = @vk.VkColorBlendAdvancedEXT::new()
      (dfn.vkCmdSetColorBlendAdvancedEXT)(cb, (0 : UInt32), (1 : UInt32), cba)
      cba.free()
      n = n + 1
    }
  }
  if n > before_2 {
    ran = ran + 1
  }

  // 3. Maintenance10 vkCmdEndRendering2KHR
  let before_3 = n
  let m10_gate = has_ext("VK_KHR_maintenance10") && m10_q.get_maintenance10() != 0 && has("vkCmdEndRendering2KHR")
  if m10_gate {
    avail = avail + 1
    let area = @vk.VkRect2D::new()
    let ext2 = @vk.VkExtent2D::new()
    ext2.set_width((16 : UInt32))
    ext2.set_height((16 : UInt32))
    area.set_extent(ext2)
    let ri = @vk.VkRenderingInfo::new()
    ri.set_renderArea(area)
    ri.set_layerCount((1 : UInt32))
    (dfn.vkCmdBeginRendering)(cb, ri)
    let rei = @vk.VkRenderingEndInfoKHR::new()
    (dfn.vkCmdEndRendering2KHR)(cb, rei)
    rei.free()
    ri.free()
    area.free()
    ext2.free()
    n = n + 1
  }
  if m10_gate && n > before_3 {
    ran = ran + 1
  }

  // 4. Guarded Shading Rate NV, Mesh NV, Custom Resolve, Descriptor Heap EXT, DGC NV/EXT
  let run_sri = false
  if run_sri {
    (dfn.vkCmdBindShadingRateImageNV)(cb, @vk.VkImageView::null(), (0 : UInt32))
    let cso = @vk.VkCoarseSampleOrderCustomNV::new()
    (dfn.vkCmdSetCoarseSampleOrderNV)(cb, (0 : UInt32), (0 : UInt32), cso)
    let srp = @vk.VkShadingRatePaletteNV::new()
    (dfn.vkCmdSetViewportShadingRatePaletteNV)(cb, (0 : UInt32), (1 : UInt32), srp)
    (dfn.vkCmdSetFragmentShadingRateEnumNV)(cb, (0 : UInt32), FixedArray::make(2, (0 : UInt32)))
    cso.free()
    srp.free()
  }

  let run_mesh_nv = false
  if run_mesh_nv {
    (dfn.vkCmdDrawMeshTasksNV)(cb, (1 : UInt32), (0 : UInt32))
    (dfn.vkCmdDrawMeshTasksIndirectNV)(cb, @vk.VkBuffer::null(), (0 : UInt64), (1 : UInt32), (0 : UInt32))
    (dfn.vkCmdDrawMeshTasksIndirectCountNV)(cb, @vk.VkBuffer::null(), (0 : UInt64), @vk.VkBuffer::null(), (0 : UInt64), (1 : UInt32), (0 : UInt32))
  }

  let run_custom_resolve = false
  if run_custom_resolve {
    let bcr = @vk.VkBeginCustomResolveInfoEXT::new()
    (dfn.vkCmdBeginCustomResolveEXT)(cb, bcr)
    bcr.free()
    let rcpd = @vk.VkReleaseCapturedPipelineDataInfoKHR::new()
    let _ = (dfn.vkReleaseCapturedPipelineDataKHR)(dev, rcpd, na)
    rcpd.free()
  }

  let run_desc_heap = false
  if run_desc_heap {
    let acd = @vk.VkAccelerationStructureCaptureDescriptorDataInfoEXT::new()
    let _ = (dfn.vkGetAccelerationStructureOpaqueCaptureDescriptorDataEXT)(dev, acd, (0 : UInt64))
    let bhi = @vk.VkBindHeapInfoEXT::new()
    (dfn.vkCmdBindResourceHeapEXT)(cb, bhi)
    (dfn.vkCmdBindSamplerHeapEXT)(cb, bhi)
    let pdi = @vk.VkPushDataInfoEXT::new()
    (dfn.vkCmdPushDataEXT)(cb, pdi)
    let har = @vk.VkHostAddressRangeEXT::new()
    let _ = (dfn.vkGetImageOpaqueCaptureDataEXT)(dev, (0 : UInt32), FixedArray::make(1, @vk.VkImage::null()), har)
    let _ = (dfn.vkGetTensorOpaqueCaptureDataARM)(dev, (0 : UInt32), FixedArray::make(1, @vk.VkTensorARM::null()), har)
    let scb = @vk.VkSamplerCustomBorderColorCreateInfoEXT::new()
    let idx_out = FixedArray::make(1, (0 : UInt32))
    let _ = (dfn.vkRegisterCustomBorderColorEXT)(dev, scb, (0 : UInt32), idx_out)
    (dfn.vkUnregisterCustomBorderColorEXT)(dev, (0 : UInt32))
    let rdi = @vk.VkResourceDescriptorInfoEXT::new()
    let _ = (dfn.vkWriteResourceDescriptorsEXT)(dev, (0 : UInt32), rdi, har)
    let sci2 = @vk.VkSamplerCreateInfo::new()
    let _ = (dfn.vkWriteSamplerDescriptorsEXT)(dev, (0 : UInt32), sci2, har)
    acd.free()
    bhi.free()
    pdi.free()
    har.free()
    scb.free()
    rdi.free()
    sci2.free()
  }

  let run_dgc_nv = false
  if run_dgc_nv {
    let iclci = @vk.VkIndirectCommandsLayoutCreateInfoNV::new()
    let icl_out = FixedArray::make(1, @vk.VkIndirectCommandsLayoutNV::null())
    let _ = (dfn.vkCreateIndirectCommandsLayoutNV)(dev, iclci, na, icl_out)
    (dfn.vkDestroyIndirectCommandsLayoutNV)(dev, icl_out[0], na)
    let gcmr = @vk.VkGeneratedCommandsMemoryRequirementsInfoNV::new()
    let mr2 = @vk.VkMemoryRequirements2::new()
    (dfn.vkGetGeneratedCommandsMemoryRequirementsNV)(dev, gcmr, mr2)
    let gci = @vk.VkGeneratedCommandsInfoNV::new()
    (dfn.vkCmdPreprocessGeneratedCommandsNV)(cb, gci)
    (dfn.vkCmdExecuteGeneratedCommandsNV)(cb, (0 : UInt32), gci)
    (dfn.vkCmdBindPipelineShaderGroupNV)(cb, (0 : UInt32), @vk.VkPipeline::null(), (0 : UInt32))
    let cpci = @vk.VkComputePipelineCreateInfo::new()
    (dfn.vkGetPipelineIndirectMemoryRequirementsNV)(dev, cpci, mr2)
    let pida = @vk.VkPipelineIndirectDeviceAddressInfoNV::new()
    let _ = (dfn.vkGetPipelineIndirectDeviceAddressNV)(dev, pida)
    (dfn.vkCmdUpdatePipelineIndirectBufferNV)(cb, @vk.VK_PIPELINE_BIND_POINT_COMPUTE, @vk.VkPipeline::null())
    let wies = @vk.VkWriteIndirectExecutionSetShaderEXT::new()
    (dfn.vkUpdateIndirectExecutionSetShaderEXT)(dev, @vk.VkIndirectExecutionSetEXT::null(), (0 : UInt32), wies)
    iclci.free()
    gcmr.free()
    mr2.free()
    gci.free()
    cpci.free()
    pida.free()
    wies.free()
  }

  let _ = (dfn.vkEndCommandBuffer)(cb)
  let _ = (dfn.vkDeviceWaitIdle)(dev)

  if emb_pl.as_ptr() != (0 : UInt64) {
    (dfn.vkDestroyPipelineLayout)(dev, emb_pl, na)
  }
  if emb_dsl.as_ptr() != (0 : UInt64) {
    (dfn.vkDestroyDescriptorSetLayout)(dev, emb_dsl, na)
  }
  if emb_samp.as_ptr() != (0 : UInt64) {
    (dfn.vkDestroySampler)(dev, emb_samp, na)
  }
  (dfn.vkDestroyCommandPool)(dev, cp_out[0], na)
  (dfn.vkDestroyDevice)(dev, na)
  @vk.destroy_debug_messenger(inst, ifn, messenger)
  (ifn.vkDestroyInstance)(inst, na)

  println("[34-dgc] commands=\{n} errors=\{g_errors.val}")
  let shortfall = avail - ran
  if g_errors.val != 0 {
    println("[34-dgc] FAIL — errors=\{g_errors.val} n=\{n} groups=\{ran}/\{avail}")
  } else if shortfall > 0 {
    println("[34-dgc] FAIL — \{shortfall} supported extension group(s) executed nothing (groups=\{ran}/\{avail} n=\{n})")
  } else if n == 0 {
    println("[34-dgc] SKIP — 0 dynamic-state/embedded-sampler/maintenance10 commands available on this driver")
  } else {
    println("[34-dgc] OK — \{n} dynamic-state/embedded-sampler/maintenance10 commands verified, 0 validation errors")
  }
}
