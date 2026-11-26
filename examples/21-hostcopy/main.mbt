// Example 21 — host image copy, deferred host operations, debug report, shader
// objects, dispatch base and the sync2 KHR aliases. Sixth coverage batch.
// Gate counts validation errors, not just return codes.

///|
let na : @vk.VkAllocationCallbacks = @vk.VkAllocationCallbacks::null()

///|
let g_errors : Ref[Int] = { val: 0 }

///|
let g_report : Ref[Int] = { val: 0 }

///|
fn main {
  let app = @vk.VkApplicationInfo::new()
  app.set_pApplicationName(@vk.cstr("Tycho HostCopy"))
  app.set_apiVersion((4210688 : UInt32)) // 1.4
  let ici = @vk.VkInstanceCreateInfo::new()
  ici.set_pApplicationInfo(app)
  ici.set_enabledLayerCount((1 : UInt32))
  ici.set_ppEnabledLayerNames(@vk.cstr_array(["VK_LAYER_KHRONOS_validation"]))
  ici.set_enabledExtensionCount((2 : UInt32))
  ici.set_ppEnabledExtensionNames(@vk.cstr_array(["VK_EXT_debug_utils", "VK_EXT_debug_report"]))
  let inst_out = FixedArray::make(1, @vk.VkInstance::null())
  let ir = @vk.vkCreateInstance(ici, na, inst_out)
  if ir != 0 {
    println("[21-host] FAIL — vkCreateInstance=\{ir}")
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
      println("[21-host] VALIDATION: \{@vk.read_cstr(data.get_pMessage())}")
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
  // query then enable: hostImageCopy / shaderObject / synchronization2
  let soq = @vk.VkPhysicalDeviceShaderObjectFeaturesEXT::new()
  let f13q = @vk.VkPhysicalDeviceVulkan13Features::new()
  let f14q = @vk.VkPhysicalDeviceVulkan14Features::new()
  soq.set_pNext(f13q.as_ptr())
  f13q.set_pNext(f14q.as_ptr())
  let fq = @vk.VkPhysicalDeviceFeatures2::new()
  fq.set_pNext(soq.as_ptr())
  (ifn.vkGetPhysicalDeviceFeatures2)(phys, fq)
  let so = @vk.VkPhysicalDeviceShaderObjectFeaturesEXT::new()
  so.set_shaderObject(soq.get_shaderObject())
  let f13 = @vk.VkPhysicalDeviceVulkan13Features::new()
  f13.set_synchronization2((1 : UInt32))
  f13.set_dynamicRendering((1 : UInt32))
  let f14 = @vk.VkPhysicalDeviceVulkan14Features::new()
  f14.set_hostImageCopy(f14q.get_hostImageCopy())
  so.set_pNext(f13.as_ptr())
  f13.set_pNext(f14.as_ptr())
  let want = ["VK_EXT_host_image_copy", "VK_EXT_shader_object", "VK_KHR_synchronization2", "VK_KHR_deferred_host_operations", "VK_KHR_device_group", "VK_EXT_calibrated_timestamps", "VK_EXT_external_memory_host", "VK_KHR_dynamic_rendering", "VK_KHR_maintenance6"]
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
  dci.set_pNext(so.as_ptr())
  dci.set_queueCreateInfoCount((1 : UInt32))
  dci.set_pQueueCreateInfos(qci)
  dci.set_enabledExtensionCount(nden.reinterpret_as_uint())
  dci.set_ppEnabledExtensionNames(@vk.cstr_array(den))
  let dev_out = FixedArray::make(1, @vk.VkDevice::null())
  let dr = (ifn.vkCreateDevice)(phys, dci, na, dev_out)
  if dr != 0 {
    println("[21-host] FAIL — vkCreateDevice=\{dr}")
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
  let npix = w * w

  // ---- debug report callback (legacy path, separate from debug utils) ----
  let drci = @vk.VkDebugReportCallbackCreateInfoEXT::new()
  drci.set_flags(@vk.VK_DEBUG_REPORT_ERROR_BIT_EXT | @vk.VK_DEBUG_REPORT_WARNING_BIT_EXT | @vk.VK_DEBUG_REPORT_INFORMATION_BIT_EXT)
  drci.set_pfnCallback(
    (_flags, _objType, _obj, _loc, _code, _layer, _msg, _ud) => {
      g_report.val = g_report.val + 1
      (0 : UInt32)
    },
  )
  let dr_out = FixedArray::make(1, @vk.VkDebugReportCallbackEXT::null())
  let drr = (ifn.vkCreateDebugReportCallbackEXT)(inst, drci, na, dr_out)
  if drr == 0 {
    n = n + 1
    (ifn.vkDebugReportMessageEXT)(
      inst,
      @vk.VK_DEBUG_REPORT_INFORMATION_BIT_EXT,
      @vk.VK_DEBUG_REPORT_OBJECT_TYPE_INSTANCE_EXT,
      inst.as_ptr(),
      (0 : UInt64),
      (0 : Int32),
      @vk.cstr("tycho"),
      @vk.cstr("explicit debug report message"),
    )
    n = n + 1
  }

  // ---- images for host copy ----
  let mkimg = fn(usage : UInt32) -> (@vk.VkImage, @vk.VkDeviceMemory) {
    let ci = @vk.VkImageCreateInfo::new()
    ci.set_imageType(@vk.VK_IMAGE_TYPE_2D)
    ci.set_format(fmt)
    let e3 = @vk.VkExtent3D::new()
    e3.set_width(w.reinterpret_as_uint())
    e3.set_height(w.reinterpret_as_uint())
    e3.set_depth((1 : UInt32))
    ci.set_extent(e3)
    ci.set_mipLevels((1 : UInt32))
    ci.set_arrayLayers((1 : UInt32))
    ci.set_samples(@vk.VK_SAMPLE_COUNT_1_BIT)
    ci.set_tiling(@vk.VK_IMAGE_TILING_OPTIMAL)
    ci.set_usage(usage)
    let o = FixedArray::make(1, @vk.VkImage::null())
    let _ = (dfn.vkCreateImage)(dev, ci, na, o)
    let rq = @vk.VkMemoryRequirements::new()
    (dfn.vkGetImageMemoryRequirements)(dev, o[0], rq)
    let ai = @vk.VkMemoryAllocateInfo::new()
    ai.set_allocationSize(rq.get_size())
    ai.set_memoryTypeIndex(memtype(rq.get_memoryTypeBits(), dev_local))
    let mo = FixedArray::make(1, @vk.VkDeviceMemory::null())
    let _ = (dfn.vkAllocateMemory)(dev, ai, na, mo)
    let _ = (dfn.vkBindImageMemory)(dev, o[0], mo[0], (0 : UInt64))
    ci.free()
    e3.free()
    (o[0], mo[0])
  }
  let husage = if f14q.get_hostImageCopy() != 0 {
    @vk.VK_IMAGE_USAGE_TRANSFER_SRC_BIT | @vk.VK_IMAGE_USAGE_TRANSFER_DST_BIT | @vk.VK_IMAGE_USAGE_HOST_TRANSFER_BIT
  } else {
    @vk.VK_IMAGE_USAGE_TRANSFER_SRC_BIT | @vk.VK_IMAGE_USAGE_TRANSFER_DST_BIT
  }
  let (imgA, memA) = mkimg(husage)
  let (imgB, memB) = mkimg(husage)
  let sub = @vk.VkImageSubresourceLayers::new()
  sub.set_aspectMask(@vk.VK_IMAGE_ASPECT_COLOR_BIT)
  sub.set_layerCount((1 : UInt32))
  let e3 = @vk.VkExtent3D::new()
  e3.set_width(w.reinterpret_as_uint())
  e3.set_height(w.reinterpret_as_uint())
  e3.set_depth((1 : UInt32))
  let region = @vk.VkMemoryToImageCopy::new()
  region.set_imageSubresource(sub)
  region.set_imageExtent(e3)
  let parr : Array[Byte] = []
  for i = 0; i < npix; i = i + 1 {
    parr.push((10 : Byte))
    parr.push((20 : Byte))
    parr.push((30 : Byte))
    parr.push((255 : Byte))
  }
  let pattern = Bytes::from_array(parr)
  region.set_pHostPointer(@vk.bytes_ptr(pattern))
  let hostCopyOk = f14q.get_hostImageCopy() != 0
  let mut host_pixel_ok = false
  if hostCopyOk {
    let tli = @vk.VkHostImageLayoutTransitionInfo::new()
    tli.set_image(imgA)
    tli.set_oldLayout(@vk.VK_IMAGE_LAYOUT_UNDEFINED)
    tli.set_newLayout(@vk.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL)
    let sr = @vk.VkImageSubresourceRange::new()
    sr.set_aspectMask(@vk.VK_IMAGE_ASPECT_COLOR_BIT)
    sr.set_levelCount((1 : UInt32))
    sr.set_layerCount((1 : UInt32))
    tli.set_subresourceRange(sr)
    if has("vkTransitionImageLayout") {
      let _ = (dfn.vkTransitionImageLayout)(dev, (1 : UInt32), tli)
      n = n + 1
    }
    if has("vkTransitionImageLayoutEXT") {
      let _ = (dfn.vkTransitionImageLayoutEXT)(dev, (1 : UInt32), tli)
      n = n + 1
    }
    let cmi = @vk.VkCopyMemoryToImageInfo::new()
    cmi.set_dstImage(imgA)
    cmi.set_dstImageLayout(@vk.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL)
    cmi.set_regionCount((1 : UInt32))
    cmi.set_pRegions(region)
    if has("vkCopyMemoryToImage") {
      let _ = (dfn.vkCopyMemoryToImage)(dev, cmi)
      n = n + 1
    }
    if has("vkCopyMemoryToImageEXT") {
      let _ = (dfn.vkCopyMemoryToImageEXT)(dev, cmi)
      n = n + 1
    }
    // image -> image host copy
    let tli2 = @vk.VkHostImageLayoutTransitionInfo::new()
    tli2.set_image(imgB)
    tli2.set_oldLayout(@vk.VK_IMAGE_LAYOUT_UNDEFINED)
    tli2.set_newLayout(@vk.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL)
    tli2.set_subresourceRange(sr)
    if has("vkTransitionImageLayout") {
      let _ = (dfn.vkTransitionImageLayout)(dev, (1 : UInt32), tli2)
    }
    let cii = @vk.VkCopyImageToImageInfo::new()
    cii.set_srcImage(imgA)
    cii.set_srcImageLayout(@vk.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL)
    cii.set_dstImage(imgB)
    cii.set_dstImageLayout(@vk.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL)
    cii.set_regionCount((1 : UInt32))
    let ic2 = @vk.VkImageCopy2::new()
    ic2.set_srcSubresource(sub)
    ic2.set_dstSubresource(sub)
    ic2.set_extent(e3)
    cii.set_pRegions(ic2)
    if has("vkCopyImageToImage") {
      let _ = (dfn.vkCopyImageToImage)(dev, cii)
      n = n + 1
    }
    if has("vkCopyImageToImageEXT") {
      let _ = (dfn.vkCopyImageToImageEXT)(dev, cii)
      n = n + 1
    }
    // image -> memory host readback
    let out = Bytes::make(npix * 4, 0)
    let cim = @vk.VkCopyImageToMemoryInfo::new()
    cim.set_srcImage(imgB)
    cim.set_srcImageLayout(@vk.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL)
    cim.set_regionCount((1 : UInt32))
    let imc = @vk.VkImageToMemoryCopy::new()
    imc.set_pHostPointer(@vk.bytes_ptr(out))
    imc.set_imageSubresource(sub)
    imc.set_imageExtent(e3)
    cim.set_pRegions(imc)
    if has("vkCopyImageToMemory") {
      let _ = (dfn.vkCopyImageToMemory)(dev, cim)
      n = n + 1
    }
    if has("vkCopyImageToMemoryEXT") {
      let _ = (dfn.vkCopyImageToMemoryEXT)(dev, cim)
      n = n + 1
    }
    host_pixel_ok = out[0] == (10 : Byte) && out[1] == (20 : Byte) && out[2] == (30 : Byte)
    imc.free()
    cim.free()
    ic2.free()
    cii.free()
    tli2.free()
    cmi.free()
    tli.free()
    sr.free()
  }

  // ---- deferred host operations ----
  if has("vkCreateDeferredOperationKHR") {
    let dop_out = FixedArray::make(1, @vk.VkDeferredOperationKHR::null())
    let dop_r = (dfn.vkCreateDeferredOperationKHR)(dev, na, dop_out)
    n = n + 1
    if dop_r == 0 {
      let dop = dop_out[0]
      let mc = (dfn.vkGetDeferredOperationMaxConcurrencyKHR)(dev, dop)
      n = n + 1
      let jr = (dfn.vkDeferredOperationJoinKHR)(dev, dop)
      n = n + 1
      let rr = (dfn.vkGetDeferredOperationResultKHR)(dev, dop)
      n = n + 1
      (dfn.vkDestroyDeferredOperationKHR)(dev, dop, na)
      n = n + 1
      if jr != 0 || rr != 0 {
        println("[21-host] FAIL — deferred join=\{jr} result=\{rr} concurrency=\{mc}")
        return
      }
    }
  }

  // ---- shader objects: create / binary data / destroy ----
  if soq.get_shaderObject() != 0 && has("vkCreateShadersEXT") {
    let vert = @shader.compile_shader_file("examples/19-draw/shader.vert", @shader.SHADER_KIND_VERTEX)
    let frag = @shader.compile_shader_file("examples/19-draw/shader.frag", @shader.SHADER_KIND_FRAGMENT)
    let scis = @vk.VkShaderCreateInfoEXT::array(2)
    scis.set_stage_at(0, @vk.VK_SHADER_STAGE_VERTEX_BIT)
    scis.set_nextStage_at(0, @vk.VK_SHADER_STAGE_FRAGMENT_BIT)
    scis.set_codeType_at(0, @vk.VK_SHADER_CODE_TYPE_SPIRV_EXT)
    scis.set_codeSize_at(0, (vert.length() * 4).to_uint64())
    scis.set_pCode_at(0, @vk.uint32_ptr(vert))
    scis.set_pName_at(0, @vk.cstr("main"))
    scis.set_stage_at(1, @vk.VK_SHADER_STAGE_FRAGMENT_BIT)
    scis.set_codeType_at(1, @vk.VK_SHADER_CODE_TYPE_SPIRV_EXT)
    scis.set_codeSize_at(1, (frag.length() * 4).to_uint64())
    scis.set_pCode_at(1, @vk.uint32_ptr(frag))
    scis.set_pName_at(1, @vk.cstr("main"))
    let sh_out = FixedArray::make(2, @vk.VkShaderEXT::null())
    let shr = (dfn.vkCreateShadersEXT)(dev, (2 : UInt32), scis, na, sh_out)
    n = n + 1
    if shr == 0 {
      let sz = FixedArray::make(1, (0 : UInt64))
      let _ = (dfn.vkGetShaderBinaryDataEXT)(dev, sh_out[0], sz, (0 : UInt64))
      n = n + 1
      if sz[0] > 0 {
        // pData must be 16-byte aligned (VUID-...-08499)
        let buf = @vk.aligned_alloc(65536, 16)
        sz[0] = (65536 : UInt64)
        let br = (dfn.vkGetShaderBinaryDataEXT)(dev, sh_out[0], sz, buf)
        @vk.free_ptr(buf)
        if br != 0 {
          println("[21-host] FAIL — shader binary data=\{br}")
          return
        }
      }
      (dfn.vkDestroyShaderEXT)(dev, sh_out[0], na)
      n = n + 1
      (dfn.vkDestroyShaderEXT)(dev, sh_out[1], na)
      n = n + 1
    }
    scis.free()
  }

  // ---- compute: dispatch base + sync2 KHR aliases ----
  let comp = @shader.compile_shader_file("examples/21-hostcopy/shader.comp", @shader.SHADER_KIND_COMPUTE)
  let csmci = @vk.VkShaderModuleCreateInfo::new()
  csmci.set_codeSize((comp.length() * 4).to_uint64())
  csmci.set_pCode(comp)
  let csm_out = FixedArray::make(1, @vk.VkShaderModule::null())
  let _ = (dfn.vkCreateShaderModule)(dev, csmci, na, csm_out)
  let dslb = @vk.VkDescriptorSetLayoutBinding::new()
  dslb.set_binding((0 : UInt32))
  dslb.set_descriptorType(@vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER)
  dslb.set_descriptorCount((1 : UInt32))
  dslb.set_stageFlags(@vk.VK_SHADER_STAGE_COMPUTE_BIT)
  let dslci = @vk.VkDescriptorSetLayoutCreateInfo::new()
  dslci.set_bindingCount((1 : UInt32))
  dslci.set_pBindings(dslb)
  let dsl_out = FixedArray::make(1, @vk.VkDescriptorSetLayout::null())
  let _ = (dfn.vkCreateDescriptorSetLayout)(dev, dslci, na, dsl_out)
  let plci = @vk.VkPipelineLayoutCreateInfo::new()
  plci.set_setLayoutCount((1 : UInt32))
  plci.set_pSetLayouts(dsl_out)
  let pl_out = FixedArray::make(1, @vk.VkPipelineLayout::null())
  let _ = (dfn.vkCreatePipelineLayout)(dev, plci, na, pl_out)
  let cstage = @vk.VkPipelineShaderStageCreateInfo::new()
  cstage.set_stage(@vk.VK_SHADER_STAGE_COMPUTE_BIT)
  cstage.set_module(csm_out[0])
  cstage.set_pName(@vk.cstr("main"))
  let cpci = @vk.VkComputePipelineCreateInfo::new()
  cpci.set_stage(cstage)
  cpci.set_layout(pl_out[0])
  let cpipe_out = FixedArray::make(1, @vk.VkPipeline::null())
  let cpr = (dfn.vkCreateComputePipelines)(dev, @vk.VkPipelineCache::null(), (1 : UInt32), cpci, na, cpipe_out)
  if cpr != 0 {
    println("[21-host] FAIL — compute pipeline=\{cpr}")
    return
  }
  let sbci = @vk.VkBufferCreateInfo::new()
  sbci.set_size((64 : UInt64))
  sbci.set_usage(@vk.VK_BUFFER_USAGE_STORAGE_BUFFER_BIT)
  let sb_out = FixedArray::make(1, @vk.VkBuffer::null())
  let _ = (dfn.vkCreateBuffer)(dev, sbci, na, sb_out)
  let sbreq = @vk.VkMemoryRequirements::new()
  (dfn.vkGetBufferMemoryRequirements)(dev, sb_out[0], sbreq)
  let sbai = @vk.VkMemoryAllocateInfo::new()
  sbai.set_allocationSize(sbreq.get_size())
  sbai.set_memoryTypeIndex(memtype(sbreq.get_memoryTypeBits(), host))
  let sbmem_out = FixedArray::make(1, @vk.VkDeviceMemory::null())
  let _ = (dfn.vkAllocateMemory)(dev, sbai, na, sbmem_out)
  let _ = (dfn.vkBindBufferMemory)(dev, sb_out[0], sbmem_out[0], (0 : UInt64))
  let dps = @vk.VkDescriptorPoolSize::new()
  dps.set_type(@vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER)
  dps.set_descriptorCount((1 : UInt32))
  let dpci = @vk.VkDescriptorPoolCreateInfo::new()
  dpci.set_maxSets((1 : UInt32))
  dpci.set_poolSizeCount((1 : UInt32))
  dpci.set_pPoolSizes(dps)
  let pool_out = FixedArray::make(1, @vk.VkDescriptorPool::null())
  let _ = (dfn.vkCreateDescriptorPool)(dev, dpci, na, pool_out)
  let dsai = @vk.VkDescriptorSetAllocateInfo::new()
  dsai.set_descriptorPool(pool_out[0])
  dsai.set_descriptorSetCount((1 : UInt32))
  dsai.set_pSetLayouts(dsl_out)
  let ds_out = FixedArray::make(1, @vk.VkDescriptorSet::null())
  let _ = (dfn.vkAllocateDescriptorSets)(dev, dsai, ds_out)
  let dbi = @vk.VkDescriptorBufferInfo::new()
  dbi.set_buffer(sb_out[0])
  dbi.set_range((64 : UInt64))
  let wd = @vk.VkWriteDescriptorSet::new()
  wd.set_dstSet(ds_out[0])
  wd.set_dstBinding((0 : UInt32))
  wd.set_descriptorCount((1 : UInt32))
  wd.set_descriptorType(@vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER)
  wd.set_pBufferInfo(dbi)
  (dfn.vkUpdateDescriptorSets)(dev, (1 : UInt32), wd, (0 : UInt32), @vk.VkCopyDescriptorSet::null())

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
  (dfn.vkCmdBindPipeline)(cb, @vk.VK_PIPELINE_BIND_POINT_COMPUTE, cpipe_out[0])
  (dfn.vkCmdBindDescriptorSets)(cb, @vk.VK_PIPELINE_BIND_POINT_COMPUTE, pl_out[0], (0 : UInt32), (1 : UInt32), ds_out, (0 : UInt32), FixedArray::make(0, (0 : UInt32)))
  if has("vkCmdDispatchBase") {
    (dfn.vkCmdDispatchBase)(cb, (0 : UInt32), (0 : UInt32), (0 : UInt32), (8 : UInt32), (1 : UInt32), (1 : UInt32))
    n = n + 1
  }
  if has("vkCmdDispatchBaseKHR") {
    (dfn.vkCmdDispatchBaseKHR)(cb, (0 : UInt32), (0 : UInt32), (0 : UInt32), (8 : UInt32), (1 : UInt32), (1 : UInt32))
    n = n + 1
  }
  let mb = @vk.VkMemoryBarrier2::new()
  mb.set_srcStageMask(@vk.VK_PIPELINE_STAGE_2_COMPUTE_SHADER_BIT)
  mb.set_srcAccessMask(@vk.VK_ACCESS_2_SHADER_STORAGE_WRITE_BIT)
  mb.set_dstStageMask(@vk.VK_PIPELINE_STAGE_2_HOST_BIT)
  mb.set_dstAccessMask(@vk.VK_ACCESS_2_HOST_READ_BIT)
  let dep = @vk.VkDependencyInfo::new()
  dep.set_memoryBarrierCount((1 : UInt32))
  dep.set_pMemoryBarriers(mb)
  if has("vkCmdPipelineBarrier2KHR") {
    (dfn.vkCmdPipelineBarrier2KHR)(cb, dep)
    n = n + 1
  }
  let _ = (dfn.vkEndCommandBuffer)(cb)
  let fci = @vk.VkFenceCreateInfo::new()
  let fence_out = FixedArray::make(1, @vk.VkFence::null())
  let _ = (dfn.vkCreateFence)(dev, fci, na, fence_out)
  let cbsi = @vk.VkCommandBufferSubmitInfo::new()
  cbsi.set_commandBuffer(cb)
  let si2 = @vk.VkSubmitInfo2::new()
  si2.set_commandBufferInfoCount((1 : UInt32))
  si2.set_pCommandBufferInfos(cbsi)
  let _sr = if has("vkQueueSubmit2KHR") {
    let r = (dfn.vkQueueSubmit2KHR)(queue, (1 : UInt32), si2, fence_out[0])
    n = n + 1
    r
  } else {
    (dfn.vkQueueSubmit2)(queue, (1 : UInt32), si2, fence_out[0])
  }
  let _wr = (dfn.vkWaitForFences)(dev, (1 : UInt32), fence_out, (1 : UInt32), (10000000000 : UInt64))
  let got = @vk.download_buffer(dev, sbmem_out[0], 32)
  let v0 = got[0].to_int() + got[1].to_int() * 256
  let v7 = got[28].to_int() + got[29].to_int() * 256
  let compute_ok = v0 == 1 && v7 == 22

  // ---- misc device queries ----
  if has("vkGetMemoryHostPointerPropertiesEXT") {
    let hp = @vk.VkMemoryHostPointerPropertiesEXT::new()
    // pHostPointer must be aligned to minImportedHostPointerAlignment
    let aligned = @vk.aligned_alloc(8192, 4096)
    let _ = (dfn.vkGetMemoryHostPointerPropertiesEXT)(dev, @vk.VK_EXTERNAL_MEMORY_HANDLE_TYPE_HOST_ALLOCATION_BIT_EXT, aligned, hp)
    @vk.free_ptr(aligned)
    n = n + 1
  }
  if has("vkGetCalibratedTimestampsEXT") {
    let ti = @vk.VkCalibratedTimestampInfoKHR::new()
    ti.set_timeDomain(@vk.VK_TIME_DOMAIN_DEVICE_EXT)
    let ts = FixedArray::make(1, (0 : UInt64))
    let devts = FixedArray::make(1, (0 : UInt64))
    let _ = (dfn.vkGetCalibratedTimestampsEXT)(dev, (1 : UInt32), ti, ts, devts)
    n = n + 1
  }
  // render area granularity needs a render pass object
  let att = @vk.VkAttachmentDescription::new()
  att.set_format(fmt)
  att.set_samples(@vk.VK_SAMPLE_COUNT_1_BIT)
  att.set_loadOp(@vk.VK_ATTACHMENT_LOAD_OP_CLEAR)
  att.set_storeOp(@vk.VK_ATTACHMENT_STORE_OP_STORE)
  att.set_initialLayout(@vk.VK_IMAGE_LAYOUT_UNDEFINED)
  att.set_finalLayout(@vk.VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL)
  let aref = @vk.VkAttachmentReference::new()
  aref.set_attachment((0 : UInt32))
  aref.set_layout(@vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL)
  let spd = @vk.VkSubpassDescription::new()
  spd.set_pipelineBindPoint(@vk.VK_PIPELINE_BIND_POINT_GRAPHICS)
  spd.set_colorAttachmentCount((1 : UInt32))
  spd.set_pColorAttachments(aref)
  let rpci = @vk.VkRenderPassCreateInfo::new()
  rpci.set_attachmentCount((1 : UInt32))
  rpci.set_pAttachments(att)
  rpci.set_subpassCount((1 : UInt32))
  rpci.set_pSubpasses(spd)
  let rp_out = FixedArray::make(1, @vk.VkRenderPass::null())
  let _ = (dfn.vkCreateRenderPass)(dev, rpci, na, rp_out)
  if has("vkGetRenderAreaGranularity") {
    let g = @vk.VkExtent2D::new()
    (dfn.vkGetRenderAreaGranularity)(dev, rp_out[0], g)
    n = n + 1
  }
  let _ = (dfn.vkDeviceWaitIdle)(dev)

  // ---- teardown ----
  (dfn.vkDestroyRenderPass)(dev, rp_out[0], na)
  (dfn.vkDestroyFence)(dev, fence_out[0], na)
  (dfn.vkDestroyCommandPool)(dev, cp_out[0], na)
  (dfn.vkDestroyDescriptorPool)(dev, pool_out[0], na)
  (dfn.vkDestroyDescriptorSetLayout)(dev, dsl_out[0], na)
  (dfn.vkDestroyPipeline)(dev, cpipe_out[0], na)
  (dfn.vkDestroyPipelineLayout)(dev, pl_out[0], na)
  (dfn.vkDestroyShaderModule)(dev, csm_out[0], na)
  (dfn.vkDestroyBuffer)(dev, sb_out[0], na)
  (dfn.vkFreeMemory)(dev, sbmem_out[0], na)
  (dfn.vkDestroyImage)(dev, imgA, na)
  (dfn.vkFreeMemory)(dev, memA, na)
  (dfn.vkDestroyImage)(dev, imgB, na)
  (dfn.vkFreeMemory)(dev, memB, na)
  if drr == 0 {
    (ifn.vkDestroyDebugReportCallbackEXT)(inst, dr_out[0], na)
    n = n + 1
  }
  (dfn.vkDestroyDevice)(dev, na)
  @vk.destroy_debug_messenger(inst, ifn, messenger)
  (ifn.vkDestroyInstance)(inst, na)
  println("[21-host] commands=\{n} host_pixel=\{host_pixel_ok} compute=\{compute_ok} report_msgs=\{g_report.val} errors=\{g_errors.val}")
  if n >= 14 && compute_ok && g_errors.val == 0 && (hostCopyOk == false || host_pixel_ok) {
    println("[21-host] OK — \{n} host-copy/deferred/shader-object/dispatch commands verified")
  } else {
    println("[21-host] FAIL — n=\{n} compute=\{compute_ok} host_pixel=\{host_pixel_ok} errors=\{g_errors.val}")
  }
}