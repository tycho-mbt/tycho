// vulkan/generated — VK_EXT_device_generated_commands: an indirect execution set plus
// an indirect commands layout, preprocessed and executed on the device. Eleventh
// coverage batch. The compute result is the assertion.
//
// The preprocess pass and the execute pass are two separate submissions joined
// by a semaphore. One submission carrying both deadlocks the NVIDIA queue
// (the fence times out and the device never idles); the split form runs on
// both lavapipe and NVIDIA.

///|
let na : @vk.VkAllocationCallbacks = @vk.VkAllocationCallbacks::null()

///|
let g_errors : Ref[Int] = { val: 0 }

///|
fn main {
  let app = @vk.VkApplicationInfo::new()
  app.set_pApplicationName(@vk.cstr("Tycho Generated"))
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
    println("[25-gen] FAIL — vkCreateInstance=\{ir}")
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
      eprintln("[25-gen] VALIDATION: \{@vk.read_cstr(data.get_pMessage())}")
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
  if !has_ext("VK_EXT_device_generated_commands") {
    println("[25-gen] SKIP — VK_EXT_device_generated_commands not supported")
    (ifn.vkDestroyInstance)(inst, na)
    return
  }
  let dgq = @vk.VkPhysicalDeviceDeviceGeneratedCommandsFeaturesEXT::new()
  let dgpq = @vk.VkPhysicalDeviceDeviceGeneratedCommandsPropertiesEXT::new()
  let f13q = @vk.VkPhysicalDeviceVulkan13Features::new()
  dgq.set_pNext(dgpq.as_ptr())
  dgpq.set_pNext(f13q.as_ptr())
  let fq = @vk.VkPhysicalDeviceFeatures2::new()
  fq.set_pNext(dgq.as_ptr())
  (ifn.vkGetPhysicalDeviceFeatures2)(phys, fq)
  let dg = @vk.VkPhysicalDeviceDeviceGeneratedCommandsFeaturesEXT::new()
  dg.set_deviceGeneratedCommands(dgq.get_deviceGeneratedCommands())
  let f12 = @vk.VkPhysicalDeviceVulkan12Features::new()
  f12.set_bufferDeviceAddress((1 : UInt32))
  let f13 = @vk.VkPhysicalDeviceVulkan13Features::new()
  f13.set_synchronization2((1 : UInt32))
  f13.set_maintenance4((1 : UInt32))
  f12.set_pNext(f13.as_ptr())
  dg.set_pNext(f12.as_ptr())
  let want = ["VK_EXT_device_generated_commands", "VK_KHR_synchronization2", "VK_KHR_maintenance4", "VK_KHR_buffer_device_address", "VK_KHR_maintenance5"]
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
  dci.set_pNext(dg.as_ptr())
  dci.set_queueCreateInfoCount((1 : UInt32))
  dci.set_pQueueCreateInfos(qci)
  dci.set_enabledExtensionCount(nden.reinterpret_as_uint())
  dci.set_ppEnabledExtensionNames(@vk.cstr_array(den))
  let dev_out = FixedArray::make(1, @vk.VkDevice::null())
  let dr = (ifn.vkCreateDevice)(phys, dci, na, dev_out)
  if dr != 0 {
    println("[25-gen] FAIL — vkCreateDevice=\{dr}")
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
  let devlocal = @vk.VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT
  let mkbuf = fn(size : UInt64, usage : UInt32, props : UInt32) -> (@vk.VkBuffer, @vk.VkDeviceMemory) {
    let ci = @vk.VkBufferCreateInfo::new()
    ci.set_size(size)
    ci.set_usage(usage)
    let o = FixedArray::make(1, @vk.VkBuffer::null())
    let _ = (dfn.vkCreateBuffer)(dev, ci, na, o)
    let rq = @vk.VkMemoryRequirements::new()
    (dfn.vkGetBufferMemoryRequirements)(dev, o[0], rq)
    let maf = @vk.VkMemoryAllocateFlagsInfo::new()
    maf.set_flags(@vk.VK_MEMORY_ALLOCATE_DEVICE_ADDRESS_BIT)
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
  let baddr = fn(b : @vk.VkBuffer) -> UInt64 {
    let i = @vk.VkBufferDeviceAddressInfo::new()
    i.set_buffer(b)
    (dfn.vkGetBufferDeviceAddress)(dev, i)
  }

  // compute pipeline + descriptor set (storage buffer)
  let comp = @shader.compile_shader_file_env("examples/vulkan/generated/shader.comp", @shader.SHADER_KIND_COMPUTE, @shader.SHADER_ENV_VULKAN_1_3)
  let smci = @vk.VkShaderModuleCreateInfo::new()
  smci.set_codeSize((comp.length() * 4).to_uint64())
  smci.set_pCode(comp)
  let sm_out = FixedArray::make(1, @vk.VkShaderModule::null())
  let _ = (dfn.vkCreateShaderModule)(dev, smci, na, sm_out)
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
  let layout = pl_out[0]
  let cstage = @vk.VkPipelineShaderStageCreateInfo::new()
  cstage.set_stage(@vk.VK_SHADER_STAGE_COMPUTE_BIT)
  cstage.set_module(sm_out[0])
  cstage.set_pName(@vk.cstr("main"))
  // the execution set only accepts pipelines created as indirect-bindable
  let pflags2 = @vk.VkPipelineCreateFlags2CreateInfo::new()
  pflags2.set_flags(@vk.VK_PIPELINE_CREATE_2_INDIRECT_BINDABLE_BIT_EXT)
  let cpci = @vk.VkComputePipelineCreateInfo::new()
  cpci.set_pNext(pflags2.as_ptr())
  cpci.set_stage(cstage)
  cpci.set_layout(layout)
  let pipe_out = FixedArray::make(1, @vk.VkPipeline::null())
  let pr = (dfn.vkCreateComputePipelines)(dev, @vk.VkPipelineCache::null(), (1 : UInt32), cpci, na, pipe_out)
  if pr != 0 {
    println("[25-gen] FAIL — compute pipeline=\{pr}")
    return
  }
  let pipe = pipe_out[0]
  let (obuf, omem) = mkbuf((64 : UInt64), @vk.VK_BUFFER_USAGE_STORAGE_BUFFER_BIT, host)
  let seed = FixedArray::make(8, (3 : UInt32))
  let _ = @vk.upload_uint32(dev, omem, seed, 32)
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
  dbi.set_buffer(obuf)
  dbi.set_range((64 : UInt64))
  let wd = @vk.VkWriteDescriptorSet::new()
  wd.set_dstSet(ds_out[0])
  wd.set_dstBinding((0 : UInt32))
  wd.set_descriptorCount((1 : UInt32))
  wd.set_descriptorType(@vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER)
  wd.set_pBufferInfo(dbi)
  (dfn.vkUpdateDescriptorSets)(dev, (1 : UInt32), wd, (0 : UInt32), @vk.VkCopyDescriptorSet::null())

  // indirect execution set holding the compute pipeline
  let espi = @vk.VkIndirectExecutionSetPipelineInfoEXT::new()
  espi.set_maxPipelineCount((1 : UInt32))
  espi.set_initialPipeline(pipe)
  let esinfo = @vk.VkIndirectExecutionSetInfoEXT::new()
  esinfo.set_pPipelineInfo(espi)
  let esci = @vk.VkIndirectExecutionSetCreateInfoEXT::new()
  esci.set_type(@vk.VK_INDIRECT_EXECUTION_SET_INFO_TYPE_PIPELINES_EXT)
  esci.set_info(esinfo)
  let es_out = FixedArray::make(1, @vk.VkIndirectExecutionSetEXT::null())
  let esr = if has("vkCreateIndirectExecutionSetEXT") {
    let r = (dfn.vkCreateIndirectExecutionSetEXT)(dev, esci, na, es_out)
    n = n + 1
    r
  } else {
    -1
  }
  if esr != 0 {
    println("[25-gen] FAIL — CreateIndirectExecutionSet=\{esr}")
    return
  }
  let wes = @vk.VkWriteIndirectExecutionSetPipelineEXT::new()
  wes.set_index((0 : UInt32))
  wes.set_pipeline(pipe)
  if has("vkUpdateIndirectExecutionSetPipelineEXT") {
    (dfn.vkUpdateIndirectExecutionSetPipelineEXT)(dev, es_out[0], (1 : UInt32), wes)
    n = n + 1
  }

  // indirect commands layout: execution-set selector + dispatch
  let estok = @vk.VkIndirectCommandsExecutionSetTokenEXT::new()
  estok.set_type((0 : UInt32)) // VK_INDIRECT_EXECUTION_SET_INPUT_TYPE_INDEX_EXT
  estok.set_shaderStages(@vk.VK_SHADER_STAGE_COMPUTE_BIT)
  let tdata0 = @vk.VkIndirectCommandsTokenDataEXT::new()
  tdata0.set_pExecutionSet(estok)
  let tdata1 = @vk.VkIndirectCommandsTokenDataEXT::new() // the dispatch token carries no data
  let tokens = @vk.VkIndirectCommandsLayoutTokenEXT::array(2)
  tokens.set_type_at(0, @vk.VK_INDIRECT_COMMANDS_TOKEN_TYPE_EXECUTION_SET_EXT)
  tokens.set_data_at(0, tdata0)
  tokens.set_offset_at(0, (0 : UInt32))
  tokens.set_type_at(1, @vk.VK_INDIRECT_COMMANDS_TOKEN_TYPE_DISPATCH_EXT)
  tokens.set_data_at(1, tdata1)
  tokens.set_offset_at(1, (4 : UInt32))
  let ilci = @vk.VkIndirectCommandsLayoutCreateInfoEXT::new()
  ilci.set_flags(@vk.VK_INDIRECT_COMMANDS_LAYOUT_USAGE_EXPLICIT_PREPROCESS_BIT_EXT)
  ilci.set_shaderStages(@vk.VK_SHADER_STAGE_COMPUTE_BIT)
  ilci.set_indirectStride((16 : UInt32))
  ilci.set_tokenCount((2 : UInt32))
  ilci.set_pTokens(tokens)
  ilci.set_pipelineLayout(layout)
  let il_out = FixedArray::make(1, @vk.VkIndirectCommandsLayoutEXT::null())
  let ilr = if has("vkCreateIndirectCommandsLayoutEXT") {
    let r = (dfn.vkCreateIndirectCommandsLayoutEXT)(dev, ilci, na, il_out)
    n = n + 1
    r
  } else {
    -1
  }
  if ilr != 0 {
    println("[25-gen] FAIL — CreateIndirectCommandsLayout=\{ilr}")
    return
  }

  // preprocess buffer: the driver reports the size it needs for this layout
  let mri = @vk.VkGeneratedCommandsMemoryRequirementsInfoEXT::new()
  mri.set_indirectExecutionSet(es_out[0])
  mri.set_indirectCommandsLayout(il_out[0])
  mri.set_maxSequenceCount((1 : UInt32))
  mri.set_maxDrawCount((1 : UInt32))
  let mr2 = @vk.VkMemoryRequirements2::new()
  if has("vkGetGeneratedCommandsMemoryRequirementsEXT") {
    (dfn.vkGetGeneratedCommandsMemoryRequirementsEXT)(dev, mri, mr2)
    n = n + 1
  }
  let psize = mr2.get_memoryRequirements().get_size()
  let pusage2 = @vk.VkBufferUsageFlags2CreateInfo::new()
  pusage2.set_usage(@vk.VK_BUFFER_USAGE_2_PREPROCESS_BUFFER_BIT_EXT | @vk.VK_BUFFER_USAGE_INDIRECT_BUFFER_BIT.to_uint64() | @vk.VK_BUFFER_USAGE_SHADER_DEVICE_ADDRESS_BIT.to_uint64())
  let pci = @vk.VkBufferCreateInfo::new()
  pci.set_pNext(pusage2.as_ptr())
  pci.set_size(if psize > 0 { psize } else { 4096 })
  let pbuf_out = FixedArray::make(1, @vk.VkBuffer::null())
  let _ = (dfn.vkCreateBuffer)(dev, pci, na, pbuf_out)
  let pbuf = pbuf_out[0]
  let prq = @vk.VkMemoryRequirements::new()
  (dfn.vkGetBufferMemoryRequirements)(dev, pbuf, prq)
  let pmaf = @vk.VkMemoryAllocateFlagsInfo::new()
  pmaf.set_flags(@vk.VK_MEMORY_ALLOCATE_DEVICE_ADDRESS_BIT)
  let pai = @vk.VkMemoryAllocateInfo::new()
  pai.set_pNext(pmaf.as_ptr())
  pai.set_allocationSize(prq.get_size())
  pai.set_memoryTypeIndex(memtype(prq.get_memoryTypeBits(), devlocal))
  let pmem_out = FixedArray::make(1, @vk.VkDeviceMemory::null())
  let _ = (dfn.vkAllocateMemory)(dev, pai, na, pmem_out)
  let _ = (dfn.vkBindBufferMemory)(dev, pbuf, pmem_out[0], (0 : UInt64))
  let pmem = pmem_out[0]
  let (ibuf, imem) = mkbuf((64 : UInt64), @vk.VK_BUFFER_USAGE_INDIRECT_BUFFER_BIT | @vk.VK_BUFFER_USAGE_SHADER_DEVICE_ADDRESS_BIT, host)
  // sequence: execution set index (uint32) then dispatch dims (3 x uint32)
  let seq = FixedArray::make(4, (0 : UInt32))
  seq[1] = (8 : UInt32)
  seq[2] = (1 : UInt32)
  seq[3] = (1 : UInt32)
  let _ = @vk.upload_uint32(dev, imem, seq, 16)

  let gci = @vk.VkGeneratedCommandsInfoEXT::new()
  gci.set_shaderStages(@vk.VK_SHADER_STAGE_COMPUTE_BIT)
  gci.set_indirectExecutionSet(es_out[0])
  gci.set_indirectCommandsLayout(il_out[0])
  gci.set_maxSequenceCount((1 : UInt32))
  gci.set_maxDrawCount((1 : UInt32))
  gci.set_indirectAddress(baddr(ibuf))
  gci.set_indirectAddressSize((16 : UInt64))
  gci.set_preprocessAddress(baddr(pbuf))
  gci.set_preprocessSize(if psize > 0 { psize } else { 4096 })

  let cpobj = @vk.VkCommandPoolCreateInfo::new()
  cpobj.set_queueFamilyIndex((0 : UInt32))
  cpobj.set_flags(@vk.VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT)
  let cp_out = FixedArray::make(1, @vk.VkCommandPool::null())
  let _ = (dfn.vkCreateCommandPool)(dev, cpobj, na, cp_out)
  let cbai = @vk.VkCommandBufferAllocateInfo::new()
  cbai.set_commandPool(cp_out[0])
  cbai.set_level(@vk.VK_COMMAND_BUFFER_LEVEL_PRIMARY)
  cbai.set_commandBufferCount((2 : UInt32))
  let cb_out = FixedArray::make(2, @vk.VkCommandBuffer::null())
  let _ = (dfn.vkAllocateCommandBuffers)(dev, cbai, cb_out)
  let cb = cb_out[0]
  let pre = cb_out[1]
  let bi = @vk.VkCommandBufferBeginInfo::new()
  // the preprocess pass records the state the generated commands will run with
  let _ = (dfn.vkBeginCommandBuffer)(pre, bi)
  (dfn.vkCmdBindPipeline)(pre, @vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe)
  (dfn.vkCmdBindDescriptorSets)(pre, @vk.VK_PIPELINE_BIND_POINT_COMPUTE, layout, (0 : UInt32), (1 : UInt32), ds_out, (0 : UInt32), FixedArray::make(0, (0 : UInt32)))
  if has("vkCmdPreprocessGeneratedCommandsEXT") {
    (dfn.vkCmdPreprocessGeneratedCommandsEXT)(pre, gci, pre)
    n = n + 1
  }
  let _ = (dfn.vkEndCommandBuffer)(pre)
  let _ = (dfn.vkBeginCommandBuffer)(cb, bi)
  (dfn.vkCmdBindPipeline)(cb, @vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe)
  (dfn.vkCmdBindDescriptorSets)(cb, @vk.VK_PIPELINE_BIND_POINT_COMPUTE, layout, (0 : UInt32), (1 : UInt32), ds_out, (0 : UInt32), FixedArray::make(0, (0 : UInt32)))
  if has("vkCmdExecuteGeneratedCommandsEXT") {
    (dfn.vkCmdExecuteGeneratedCommandsEXT)(cb, (1 : UInt32), gci)
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
  (dfn.vkCmdPipelineBarrier2)(cb, dep)
  let _ = (dfn.vkEndCommandBuffer)(cb)

  // preprocess submission signals the semaphore the execute submission waits on
  let sem_out = FixedArray::make(1, @vk.VkSemaphore::null())
  let semci = @vk.VkSemaphoreCreateInfo::new()
  let _ = (dfn.vkCreateSemaphore)(dev, semci, na, sem_out)
  let s1 = @vk.VkSubmitInfo::new()
  s1.set_commandBufferCount((1 : UInt32))
  s1.set_pCommandBuffers(FixedArray::make(1, pre))
  s1.set_signalSemaphoreCount((1 : UInt32))
  s1.set_pSignalSemaphores(sem_out)
  let sr1 = (dfn.vkQueueSubmit)(queue, (1 : UInt32), s1, @vk.VkFence::null())
  let fci = @vk.VkFenceCreateInfo::new()
  let fence_out = FixedArray::make(1, @vk.VkFence::null())
  let _ = (dfn.vkCreateFence)(dev, fci, na, fence_out)
  let s2 = @vk.VkSubmitInfo::new()
  s2.set_commandBufferCount((1 : UInt32))
  s2.set_pCommandBuffers(FixedArray::make(1, cb))
  s2.set_waitSemaphoreCount((1 : UInt32))
  s2.set_pWaitSemaphores(sem_out)
  s2.set_pWaitDstStageMask(FixedArray::make(1, @vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT))
  let sr2 = (dfn.vkQueueSubmit)(queue, (1 : UInt32), s2, fence_out[0])
  let wr = (dfn.vkWaitForFences)(dev, (1 : UInt32), fence_out, (1 : UInt32), (20000000000 : UInt64))
  let got = @vk.download_buffer(dev, omem, 32)
  let v0 = got[0].to_int() + got[1].to_int() * 256
  let v7 = got[28].to_int() + got[29].to_int() * 256
  let compute_ok = v0 == 11 && v7 == 11

  if has("vkDestroyIndirectCommandsLayoutEXT") {
    (dfn.vkDestroyIndirectCommandsLayoutEXT)(dev, il_out[0], na)
    n = n + 1
  }
  if has("vkDestroyIndirectExecutionSetEXT") {
    (dfn.vkDestroyIndirectExecutionSetEXT)(dev, es_out[0], na)
    n = n + 1
  }
  (dfn.vkDestroySemaphore)(dev, sem_out[0], na)
  (dfn.vkDestroyFence)(dev, fence_out[0], na)
  (dfn.vkDestroyCommandPool)(dev, cp_out[0], na)
  (dfn.vkDestroyDescriptorPool)(dev, pool_out[0], na)
  (dfn.vkDestroyDescriptorSetLayout)(dev, dsl_out[0], na)
  (dfn.vkDestroyPipeline)(dev, pipe, na)
  (dfn.vkDestroyPipelineLayout)(dev, layout, na)
  (dfn.vkDestroyShaderModule)(dev, sm_out[0], na)
  (dfn.vkDestroyBuffer)(dev, obuf, na)
  (dfn.vkFreeMemory)(dev, omem, na)
  (dfn.vkDestroyBuffer)(dev, pbuf, na)
  (dfn.vkFreeMemory)(dev, pmem, na)
  (dfn.vkDestroyBuffer)(dev, ibuf, na)
  (dfn.vkFreeMemory)(dev, imem, na)
  (dfn.vkDestroyDevice)(dev, na)
  @vk.destroy_debug_messenger(inst, ifn, messenger)
  (ifn.vkDestroyInstance)(inst, na)
  println("[25-gen] commands=\{n} v0=\{v0} v7=\{v7} submit=\{sr1}/\{sr2} wait=\{wr} errors=\{g_errors.val}")
  if sr1 == 0 && sr2 == 0 && wr == 0 && compute_ok && n >= 7 && g_errors.val == 0 {
    println("[25-gen] OK — \{n} generated-command commands, compute result verified")
  } else {
    println("[25-gen] FAIL — compute=\{compute_ok} n=\{n} errors=\{g_errors.val}")
  }
}
