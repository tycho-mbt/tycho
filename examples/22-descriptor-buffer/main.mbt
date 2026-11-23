// Example 22 — VK_EXT_descriptor_buffer: descriptors written into a buffer and
// bound by offset instead of through descriptor sets. Seventh coverage batch.

///|
let na : @vk.VkAllocationCallbacks = @vk.VkAllocationCallbacks::null()

///|
let g_errors : Ref[Int] = { val: 0 }

///|
fn main {
  let app = @vk.VkApplicationInfo::new()
  app.set_pApplicationName(@vk.cstr("Tycho DescriptorBuffer"))
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
    println("[22-dbuf] FAIL — vkCreateInstance=\{ir}")
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
      println("[22-dbuf] VALIDATION: \{@vk.read_cstr(data.get_pMessage())}")
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
  if !has_ext("VK_EXT_descriptor_buffer") {
    println("[22-dbuf] SKIP — VK_EXT_descriptor_buffer not supported")
    (ifn.vkDestroyInstance)(inst, na)
    return
  }
  let dbq = @vk.VkPhysicalDeviceDescriptorBufferFeaturesEXT::new()
  let dbpq = @vk.VkPhysicalDeviceDescriptorBufferPropertiesEXT::new()
  let f12q = @vk.VkPhysicalDeviceVulkan12Features::new()
  let f13q = @vk.VkPhysicalDeviceVulkan13Features::new()
  dbq.set_pNext(f12q.as_ptr())
  f12q.set_pNext(f13q.as_ptr())
  let fq = @vk.VkPhysicalDeviceFeatures2::new()
  fq.set_pNext(dbq.as_ptr())
  (ifn.vkGetPhysicalDeviceFeatures2)(phys, fq)
  let props2 = @vk.VkPhysicalDeviceProperties2::new()
  props2.set_pNext(dbpq.as_ptr())
  (ifn.vkGetPhysicalDeviceProperties2)(phys, props2)
  let db = @vk.VkPhysicalDeviceDescriptorBufferFeaturesEXT::new()
  db.set_descriptorBuffer(dbq.get_descriptorBuffer())
  db.set_descriptorBufferCaptureReplay(dbq.get_descriptorBufferCaptureReplay())
  let f12 = @vk.VkPhysicalDeviceVulkan12Features::new()
  f12.set_bufferDeviceAddress(f12q.get_bufferDeviceAddress())
  f12.set_bufferDeviceAddressCaptureReplay(f12q.get_bufferDeviceAddressCaptureReplay())
  let f13 = @vk.VkPhysicalDeviceVulkan13Features::new()
  f13.set_synchronization2((1 : UInt32))
  db.set_pNext(f12.as_ptr())
  f12.set_pNext(f13.as_ptr())
  let want = ["VK_EXT_descriptor_buffer", "VK_KHR_buffer_device_address", "VK_KHR_synchronization2", "VK_KHR_maintenance6"]
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
  dci.set_pNext(db.as_ptr())
  dci.set_queueCreateInfoCount((1 : UInt32))
  dci.set_pQueueCreateInfos(qci)
  dci.set_enabledExtensionCount(nden.reinterpret_as_uint())
  dci.set_ppEnabledExtensionNames(@vk.cstr_array(den))
  let dev_out = FixedArray::make(1, @vk.VkDevice::null())
  let dr = (ifn.vkCreateDevice)(phys, dci, na, dev_out)
  if dr != 0 {
    println("[22-dbuf] FAIL — vkCreateDevice=\{dr}")
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
  let mkbuf = fn(size : UInt64, usage : UInt32, props : UInt32, flags : UInt32) -> (@vk.VkBuffer, @vk.VkDeviceMemory) {
    let ci = @vk.VkBufferCreateInfo::new()
    ci.set_size(size)
    ci.set_usage(usage)
    ci.set_flags(flags)
    let o = FixedArray::make(1, @vk.VkBuffer::null())
    let _ = (dfn.vkCreateBuffer)(dev, ci, na, o)
    let rq = @vk.VkMemoryRequirements::new()
    (dfn.vkGetBufferMemoryRequirements)(dev, o[0], rq)
    let maf = @vk.VkMemoryAllocateFlagsInfo::new()
    let mut mflags = @vk.VK_MEMORY_ALLOCATE_DEVICE_ADDRESS_BIT
    if dbq.get_descriptorBufferCaptureReplay() != 0 && f12q.get_bufferDeviceAddressCaptureReplay() != 0 {
      mflags = mflags | @vk.VK_MEMORY_ALLOCATE_DEVICE_ADDRESS_CAPTURE_REPLAY_BIT
    }
    maf.set_flags(mflags)
    let ai = @vk.VkMemoryAllocateInfo::new()
    ai.set_pNext(maf.as_ptr())
    ai.set_allocationSize(rq.get_size())
    ai.set_memoryTypeIndex(memtype(rq.get_memoryTypeBits(), props))
    let mo = FixedArray::make(1, @vk.VkDeviceMemory::null())
    let _ = (dfn.vkAllocateMemory)(dev, ai, na, mo)
    let _ = (dfn.vkBindBufferMemory)(dev, o[0], mo[0], (0 : UInt64))
    ci.free()
    maf.free()
    (o[0], mo[0])
  }

  // descriptor set layout usable with descriptor buffers
  let dslb = @vk.VkDescriptorSetLayoutBinding::new()
  dslb.set_binding((0 : UInt32))
  dslb.set_descriptorType(@vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER)
  dslb.set_descriptorCount((1 : UInt32))
  dslb.set_stageFlags(@vk.VK_SHADER_STAGE_COMPUTE_BIT)
  let dslci = @vk.VkDescriptorSetLayoutCreateInfo::new()
  dslci.set_bindingCount((1 : UInt32))
  dslci.set_pBindings(dslb)
  dslci.set_flags(@vk.VK_DESCRIPTOR_SET_LAYOUT_CREATE_DESCRIPTOR_BUFFER_BIT_EXT)
  let dsl_out = FixedArray::make(1, @vk.VkDescriptorSetLayout::null())
  let _ = (dfn.vkCreateDescriptorSetLayout)(dev, dslci, na, dsl_out)
  let dsl = dsl_out[0]
  let layout_size = FixedArray::make(1, (0 : UInt64))
  let bind_off = FixedArray::make(1, (0 : UInt64))
  if has("vkGetDescriptorSetLayoutSizeEXT") {
    (dfn.vkGetDescriptorSetLayoutSizeEXT)(dev, dsl, layout_size)
    n = n + 1
  }
  if has("vkGetDescriptorSetLayoutBindingOffsetEXT") {
    (dfn.vkGetDescriptorSetLayoutBindingOffsetEXT)(dev, dsl, (0 : UInt32), bind_off)
    n = n + 1
  }
  if layout_size[0] == 0 {
    println("[22-dbuf] FAIL — descriptor layout size is zero")
    return
  }

  // data buffer + descriptor buffer
  let replay = if dbq.get_descriptorBufferCaptureReplay() != 0 && f12q.get_bufferDeviceAddressCaptureReplay() != 0 { (1 : UInt32) } else { (0 : UInt32) }
  let bflags = if replay != 0 {
    @vk.VK_BUFFER_CREATE_DEVICE_ADDRESS_CAPTURE_REPLAY_BIT |
    @vk.VK_BUFFER_CREATE_DESCRIPTOR_BUFFER_CAPTURE_REPLAY_BIT_EXT
  } else {
    (0 : UInt32)
  }
  let (data, data_mem) = mkbuf((64 : UInt64), @vk.VK_BUFFER_USAGE_STORAGE_BUFFER_BIT | @vk.VK_BUFFER_USAGE_SHADER_DEVICE_ADDRESS_BIT, host, bflags)
  let (desc, desc_mem) = mkbuf(layout_size[0] + 64, @vk.VK_BUFFER_USAGE_RESOURCE_DESCRIPTOR_BUFFER_BIT_EXT | @vk.VK_BUFFER_USAGE_SHADER_DEVICE_ADDRESS_BIT, host, bflags)
  let seed = FixedArray::make(8, (3 : UInt32))
  let _ = @vk.upload_uint32(dev, data_mem, seed, 32)
  let bdai = @vk.VkBufferDeviceAddressInfo::new()
  bdai.set_buffer(data)
  let data_addr = (dfn.vkGetBufferDeviceAddress)(dev, bdai)
  let desc_addr = (dfn.vkGetBufferDeviceAddress)(dev, {
    let i = @vk.VkBufferDeviceAddressInfo::new()
    i.set_buffer(desc)
    i
  })
  // pDescriptor of vkGetDescriptorEXT is a HOST pointer, not a device address.
  // lavapipe makes them coincide, which hides the mistake; NVIDIA does not.
  let desc_host = FixedArray::make(1, (0 : UInt64))
  let _ = (dfn.vkMapMemory)(dev, desc_mem, (0 : UInt64), layout_size[0] + 64, (0 : UInt32), desc_host)

  // write the descriptor into the descriptor buffer
  if has("vkGetDescriptorEXT") {
    let dai = @vk.VkDescriptorAddressInfoEXT::new()
    dai.set_address(data_addr)
    dai.set_range((64 : UInt64))
    let ddata = @vk.VkDescriptorDataEXT::new()
    ddata.set_pStorageBuffer(dai)
    let dgi = @vk.VkDescriptorGetInfoEXT::new()
    dgi.set_type(@vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER)
    dgi.set_data(ddata)
    (dfn.vkGetDescriptorEXT)(dev, dgi, dbpq.get_storageBufferDescriptorSize(), desc_host[0] + bind_off[0])
    n = n + 1
    dai.free()
    ddata.free()
    dgi.free()
  }

  // compute pipeline using that layout
  let comp = @shader.compile_shader_file("examples/22-descriptor-buffer/shader.comp", @shader.SHADER_KIND_COMPUTE)
  let smci = @vk.VkShaderModuleCreateInfo::new()
  smci.set_codeSize((comp.length() * 4).to_uint64())
  smci.set_pCode(comp)
  let sm_out = FixedArray::make(1, @vk.VkShaderModule::null())
  let _ = (dfn.vkCreateShaderModule)(dev, smci, na, sm_out)
  let plci = @vk.VkPipelineLayoutCreateInfo::new()
  plci.set_setLayoutCount((1 : UInt32))
  plci.set_pSetLayouts(dsl_out)
  let pl_out = FixedArray::make(1, @vk.VkPipelineLayout::null())
  let _ = (dfn.vkCreatePipelineLayout)(dev, plci, na, pl_out)
  let layout = pl_out[0]
  let cstage = @vk.VkPipelineShaderStageCreateInfo::new()
  cstage.set_stage(@vk.VK_SHADER_STAGE_COMPUTE_BIT)
  cstage.set_module(sm_out[0])
  cstage.set_pName(@vk.cstr("main"))
  let cpci = @vk.VkComputePipelineCreateInfo::new()
  cpci.set_stage(cstage)
  cpci.set_layout(layout)
  cpci.set_flags(@vk.VK_PIPELINE_CREATE_DESCRIPTOR_BUFFER_BIT_EXT)
  let pipe_out = FixedArray::make(1, @vk.VkPipeline::null())
  let pr = (dfn.vkCreateComputePipelines)(dev, @vk.VkPipelineCache::null(), (1 : UInt32), cpci, na, pipe_out)
  if pr != 0 {
    println("[22-dbuf] FAIL — compute pipeline=\{pr}")
    return
  }

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
  (dfn.vkCmdBindPipeline)(cb, @vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_out[0])
  let dbbi = @vk.VkDescriptorBufferBindingInfoEXT::new()
  dbbi.set_address(desc_addr)
  dbbi.set_usage(@vk.VK_BUFFER_USAGE_RESOURCE_DESCRIPTOR_BUFFER_BIT_EXT)
  if has("vkCmdBindDescriptorBuffersEXT") {
    (dfn.vkCmdBindDescriptorBuffersEXT)(cb, (1 : UInt32), dbbi)
    n = n + 1
  }
  let idxs = FixedArray::make(1, (0 : UInt32))
  let offs = FixedArray::make(1, (0 : UInt64))
  if has("vkCmdSetDescriptorBufferOffsetsEXT") {
    (dfn.vkCmdSetDescriptorBufferOffsetsEXT)(cb, @vk.VK_PIPELINE_BIND_POINT_COMPUTE, layout, (0 : UInt32), (1 : UInt32), idxs, offs)
    n = n + 1
  }
  if has("vkCmdSetDescriptorBufferOffsets2EXT") {
    let so = @vk.VkSetDescriptorBufferOffsetsInfoEXT::new()
    so.set_stageFlags(@vk.VK_SHADER_STAGE_COMPUTE_BIT)
    so.set_layout(layout)
    so.set_firstSet((0 : UInt32))
    so.set_setCount((1 : UInt32))
    so.set_pBufferIndices(idxs)
    so.set_pOffsets(offs)
    (dfn.vkCmdSetDescriptorBufferOffsets2EXT)(cb, so)
    n = n + 1
    so.free()
  }
  (dfn.vkCmdDispatch)(cb, (8 : UInt32), (1 : UInt32), (1 : UInt32))
  let mb = @vk.VkMemoryBarrier2::new()
  mb.set_srcStageMask(@vk.VK_PIPELINE_STAGE_2_COMPUTE_SHADER_BIT)
  mb.set_srcAccessMask(@vk.VK_ACCESS_2_SHADER_STORAGE_WRITE_BIT)
  mb.set_dstStageMask(@vk.VK_PIPELINE_STAGE_2_HOST_BIT)
  mb.set_dstAccessMask(@vk.VK_ACCESS_2_HOST_READ_BIT)
  let dep = @vk.VkDependencyInfo::new()
  dep.set_memoryBarrierCount((1 : UInt32))
  dep.set_pMemoryBarriers(mb)
  (dfn.vkCmdPipelineBarrier2)(cb, dep)
  let _ = (dfn.vkEndCommandBuffer)(cb)
  let fci = @vk.VkFenceCreateInfo::new()
  let fence_out = FixedArray::make(1, @vk.VkFence::null())
  let _ = (dfn.vkCreateFence)(dev, fci, na, fence_out)
  let si = @vk.VkSubmitInfo::new()
  si.set_commandBufferCount((1 : UInt32))
  si.set_pCommandBuffers(cb_out)
  let sr = (dfn.vkQueueSubmit)(queue, (1 : UInt32), si, fence_out[0])
  let wr = (dfn.vkWaitForFences)(dev, (1 : UInt32), fence_out, (1 : UInt32), (10000000000 : UInt64))
  let got = @vk.download_buffer(dev, data_mem, 32)
  let v0 = got[0].to_int() + got[1].to_int() * 256
  let v7 = got[28].to_int() + got[29].to_int() * 256
  let compute_ok = v0 == 11 && v7 == 11

  // opaque capture descriptor data (needs captureReplay)
  if replay != 0 {
    let bci = @vk.VkBufferCaptureDescriptorDataInfoEXT::new()
    bci.set_buffer(data)
    let cap = @vk.aligned_alloc(256, 16)
    if has("vkGetBufferOpaqueCaptureDescriptorDataEXT") {
      let _ = (dfn.vkGetBufferOpaqueCaptureDescriptorDataEXT)(dev, bci, cap)
      n = n + 1
    }
    let sci = @vk.VkSamplerCreateInfo::new()
    sci.set_flags(@vk.VK_SAMPLER_CREATE_DESCRIPTOR_BUFFER_CAPTURE_REPLAY_BIT_EXT)
    sci.set_magFilter(@vk.VK_FILTER_NEAREST)
    sci.set_minFilter(@vk.VK_FILTER_NEAREST)
    let samp_out = FixedArray::make(1, @vk.VkSampler::null())
    let _ = (dfn.vkCreateSampler)(dev, sci, na, samp_out)
    let scdi = @vk.VkSamplerCaptureDescriptorDataInfoEXT::new()
    scdi.set_sampler(samp_out[0])
    if has("vkGetSamplerOpaqueCaptureDescriptorDataEXT") {
      let _ = (dfn.vkGetSamplerOpaqueCaptureDescriptorDataEXT)(dev, scdi, cap)
      n = n + 1
    }
    (dfn.vkDestroySampler)(dev, samp_out[0], na)
    @vk.free_ptr(cap)
    bci.free()
    scdi.free()
    sci.free()
  }

  let _ = (dfn.vkDeviceWaitIdle)(dev)
  (dfn.vkDestroyFence)(dev, fence_out[0], na)
  (dfn.vkDestroyCommandPool)(dev, cp_out[0], na)
  (dfn.vkDestroyPipeline)(dev, pipe_out[0], na)
  (dfn.vkDestroyPipelineLayout)(dev, layout, na)
  (dfn.vkDestroyShaderModule)(dev, sm_out[0], na)
  (dfn.vkDestroyDescriptorSetLayout)(dev, dsl, na)
  (dfn.vkDestroyBuffer)(dev, data, na)
  (dfn.vkFreeMemory)(dev, data_mem, na)
  (dfn.vkUnmapMemory)(dev, desc_mem)
  (dfn.vkDestroyBuffer)(dev, desc, na)
  (dfn.vkFreeMemory)(dev, desc_mem, na)
  (dfn.vkDestroyDevice)(dev, na)
  @vk.destroy_debug_messenger(inst, ifn, messenger)
  (ifn.vkDestroyInstance)(inst, na)
  println("[22-dbuf] commands=\{n} layoutSize=\{layout_size[0]} v0=\{v0} v7=\{v7} errors=\{g_errors.val}")
  if sr == 0 && wr == 0 && compute_ok && n >= 5 && g_errors.val == 0 {
    println("[22-dbuf] OK — \{n} descriptor-buffer commands, compute result verified")
  } else {
    println("[22-dbuf] FAIL — submit=\{sr} wait=\{wr} compute=\{compute_ok} n=\{n} errors=\{g_errors.val}")
  }
}