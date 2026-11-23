// Example 26 — core surface gaps: instance queries, sparse binding, buffer
// views, indirect dispatch and the copy-commands2 pair. Twelfth coverage batch.
// Every step asserts on data, not on return codes alone.

///|
let na : @vk.VkAllocationCallbacks = @vk.VkAllocationCallbacks::null()

///|
let g_errors : Ref[Int] = { val: 0 }

///|
fn main {
  let mut n = 0
  // ---- instance-level queries ----
  let ver = FixedArray::make(1, (0 : UInt32))
  let iv = @vk.vkEnumerateInstanceVersion(ver)
  n = n + 1
  let lcount = FixedArray::make(1, (0 : UInt32))
  let _ = @vk.vkEnumerateInstanceLayerProperties(lcount, @vk.VkLayerProperties::null())
  let layers = @vk.VkLayerProperties::array(lcount[0].reinterpret_as_int())
  let _ = @vk.vkEnumerateInstanceLayerProperties(lcount, layers)
  n = n + 1
  let app = @vk.VkApplicationInfo::new()
  app.set_pApplicationName(@vk.cstr("Tycho CoreGaps"))
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
    println("[26-core] FAIL — vkCreateInstance=\{ir}")
    return
  }
  let inst = inst_out[0]
  let ifn = @vk.InstanceFn::load(inst)
  // resolving an instance-level entry point by name must succeed
  let proc = @vk.vkGetInstanceProcAddr(inst, @vk.cstr("vkEnumeratePhysicalDevices"))
  n = n + 1
  let proc_ok = proc != (0 : UInt64)
  let messenger = @vk.create_debug_messenger(
    inst, ifn,
    @vk.VK_DEBUG_UTILS_MESSAGE_SEVERITY_ERROR_BIT_EXT,
    @vk.VK_DEBUG_UTILS_MESSAGE_TYPE_VALIDATION_BIT_EXT,
    (_s, _t, data, _u) => {
      g_errors.val = g_errors.val + 1
      eprintln("[26-core] VALIDATION: \{@vk.read_cstr(data.get_pMessage())}")
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
  let has_ext = fn(name : String) -> Bool {
    for i = 0; i < dn; i = i + 1 {
      if exts[i] == name {
        return true
      }
    }
    false
  }
  let want = ["VK_KHR_copy_commands2"]
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
  let feat_q = @vk.VkPhysicalDeviceFeatures::new()
  (ifn.vkGetPhysicalDeviceFeatures)(phys, feat_q)
  let has_sparse = feat_q.get_sparseBinding() != 0 && feat_q.get_sparseResidencyBuffer() != 0
  let feats = @vk.VkPhysicalDeviceFeatures::new()
  if has_sparse {
    feats.set_sparseBinding((1 : UInt32))
    feats.set_sparseResidencyBuffer((1 : UInt32))
  }
  let dci = @vk.VkDeviceCreateInfo::new()
  dci.set_pEnabledFeatures(feats)
  dci.set_queueCreateInfoCount((1 : UInt32))
  dci.set_pQueueCreateInfos(qci)
  dci.set_enabledExtensionCount(nden.reinterpret_as_uint())
  dci.set_ppEnabledExtensionNames(@vk.cstr_array(den))
  let dev_out = FixedArray::make(1, @vk.VkDevice::null())
  let dr = (ifn.vkCreateDevice)(phys, dci, na, dev_out)
  if dr != 0 {
    println("[26-core] FAIL — vkCreateDevice=\{dr}")
    return
  }
  let dev = dev_out[0]
  let dfn = @vk.DeviceFn::load(dev)
  let queue_out = FixedArray::make(1, @vk.VkQueue::null())
  (dfn.vkGetDeviceQueue)(dev, (0 : UInt32), (0 : UInt32), queue_out)
  let queue = queue_out[0]
  let mp = @vk.VkPhysicalDeviceMemoryProperties::new()
  (ifn.vkGetPhysicalDeviceMemoryProperties)(phys, mp)
  // returns -1 when no memory type matches, so callers can skip optional paths
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

  // ---- device-level queries ----
  let (qbuf, qmem) = mkbuf((1048576 : UInt64), @vk.VK_BUFFER_USAGE_TRANSFER_SRC_BIT | @vk.VK_BUFFER_USAGE_TRANSFER_DST_BIT, host)
  let sparse_pat : Array[Byte] = []
  for i = 0; i < 1048576; i = i + 1 {
    sparse_pat.push((0xAB : Byte))
  }
  let _ = @vk.upload_bytes(dev, qmem, Bytes::from_array(sparse_pat), 1048576)
  // commitment is only defined for lazily allocated memory; the driver must
  // expose such a memory type, and the memory has to be used to be committed
  let lazy_type = memtype((0xFFFFFFFF : UInt32), @vk.VK_MEMORY_PROPERTY_LAZILY_ALLOCATED_BIT)
  let commitment = FixedArray::make(1, (0 : UInt64))
  let mut lazy_r = -1
  let lazy_out = FixedArray::make(1, @vk.VkDeviceMemory::null())
  let mut lazy_buf = @vk.VkBuffer::null()
  if lazy_type >= 0 {
    let lci = @vk.VkBufferCreateInfo::new()
    lci.set_size((4096 : UInt64))
    lci.set_usage(@vk.VK_BUFFER_USAGE_TRANSFER_SRC_BIT | @vk.VK_BUFFER_USAGE_TRANSFER_DST_BIT)
    let lbo = FixedArray::make(1, @vk.VkBuffer::null())
    let _ = (dfn.vkCreateBuffer)(dev, lci, na, lbo)
    lazy_buf = lbo[0]
    let lazy_ci = @vk.VkMemoryAllocateInfo::new()
    lazy_ci.set_allocationSize((4096 : UInt64))
    lazy_ci.set_memoryTypeIndex(lazy_type.reinterpret_as_uint())
    lazy_r = (dfn.vkAllocateMemory)(dev, lazy_ci, na, lazy_out)
    if lazy_r == 0 {
      let _ = (dfn.vkBindBufferMemory)(dev, lazy_buf, lazy_out[0], (0 : UInt64))
    }
  }
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

  // ---- sparse binding ----
  let mut sb = @vk.VkBuffer::null()
  let mut smem = @vk.VkDeviceMemory::null()
  let mut sparse_align = (4096 : UInt64)
  let bf_out = FixedArray::make(1, @vk.VkFence::null())
  let mut bs = (0 : Int32)
  let mut bsr = (0 : Int32)
  if has_sparse {
    let sparse_ci = @vk.VkBufferCreateInfo::new()
    sparse_ci.set_size((1048576 : UInt64))
    sparse_ci.set_usage(@vk.VK_BUFFER_USAGE_TRANSFER_SRC_BIT | @vk.VK_BUFFER_USAGE_TRANSFER_DST_BIT)
    sparse_ci.set_flags(@vk.VK_BUFFER_CREATE_SPARSE_BINDING_BIT | @vk.VK_BUFFER_CREATE_SPARSE_RESIDENCY_BIT)
    let sb_out = FixedArray::make(1, @vk.VkBuffer::null())
    let _ = (dfn.vkCreateBuffer)(dev, sparse_ci, na, sb_out)
    sb = sb_out[0]
    let srq = @vk.VkMemoryRequirements::new()
    (dfn.vkGetBufferMemoryRequirements)(dev, sb, srq)
    // sparse binds must be a multiple of the buffer's memory alignment
    sparse_align = srq.get_alignment()
    let sai = @vk.VkMemoryAllocateInfo::new()
    sai.set_allocationSize(srq.get_size())
    sai.set_memoryTypeIndex(memtype(srq.get_memoryTypeBits(), devlocal).reinterpret_as_uint())
    let smem_out = FixedArray::make(1, @vk.VkDeviceMemory::null())
    let _ = (dfn.vkAllocateMemory)(dev, sai, na, smem_out)
    smem = smem_out[0]
    let smb = @vk.VkSparseMemoryBind::new()
    smb.set_memory(smem)
    smb.set_memoryOffset((0 : UInt64))
    smb.set_size(sparse_align)
    let sbi = @vk.VkSparseBufferMemoryBindInfo::new()
    sbi.set_buffer(sb)
    sbi.set_bindCount((1 : UInt32))
    sbi.set_pBinds(smb)
    let bsi = @vk.VkBindSparseInfo::new()
    bsi.set_bufferBindCount((1 : UInt32))
    bsi.set_pBufferBinds(sbi)
    let bfci = @vk.VkFenceCreateInfo::new()
    let _ = (dfn.vkCreateFence)(dev, bfci, na, bf_out)
    bs = (dfn.vkQueueBindSparse)(queue, (1 : UInt32), bsi, bf_out[0])
    n = n + 1
    bsr = (dfn.vkWaitForFences)(dev, (1 : UInt32), bf_out, (1 : UInt32), (20000000000 : UInt64))
  }

  // ---- buffer view ----
  let (texbuf, texmem) = mkbuf((64 : UInt64), @vk.VK_BUFFER_USAGE_UNIFORM_TEXEL_BUFFER_BIT, host)
  let bvci = @vk.VkBufferViewCreateInfo::new()
  bvci.set_buffer(texbuf)
  bvci.set_format(@vk.VK_FORMAT_R32G32B32A32_SFLOAT)
  bvci.set_offset((0 : UInt64))
  bvci.set_range((64 : UInt64))
  let bv_out = FixedArray::make(1, @vk.VkBufferView::null())
  let bvr = (dfn.vkCreateBufferView)(dev, bvci, na, bv_out)
  n = n + 1
  let view_ok = bvr == 0
  if view_ok {
    (dfn.vkDestroyBufferView)(dev, bv_out[0], na)
    n = n + 1
  }

  // ---- compute pipeline for the indirect dispatch ----
  let comp = @shader.compile_shader_file_env("examples/26-core-gaps/shader.comp", @shader.SHADER_KIND_COMPUTE, @shader.SHADER_ENV_VULKAN_1_3)
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
  let cpci = @vk.VkComputePipelineCreateInfo::new()
  cpci.set_stage(cstage)
  cpci.set_layout(layout)
  let pipe_out = FixedArray::make(1, @vk.VkPipeline::null())
  let pr = (dfn.vkCreateComputePipelines)(dev, @vk.VkPipelineCache::null(), (1 : UInt32), cpci, na, pipe_out)
  if pr != 0 {
    println("[26-core] FAIL — compute pipeline=\{pr}")
    return
  }
  let pipe = pipe_out[0]
  let (obuf, omem) = mkbuf((64 : UInt64), @vk.VK_BUFFER_USAGE_STORAGE_BUFFER_BIT, host)
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
  let (ibuf, imem) = mkbuf((64 : UInt64), @vk.VK_BUFFER_USAGE_INDIRECT_BUFFER_BIT, host)
  let disp = FixedArray::make(3, (0 : UInt32))
  disp[0] = (8 : UInt32)
  disp[1] = (1 : UInt32)
  disp[2] = (1 : UInt32)
  let _ = @vk.upload_uint32(dev, imem, disp, 12)

  // ---- image for the copy-commands2 pair ----
  let side = 64
  let iw = (64 : UInt32)
  let fmt = @vk.VK_FORMAT_R8G8B8A8_UNORM
  let ici2 = @vk.VkImageCreateInfo::new()
  ici2.set_imageType(@vk.VK_IMAGE_TYPE_2D)
  ici2.set_format(fmt)
  let e3 = @vk.VkExtent3D::new()
  e3.set_width(iw)
  e3.set_height(iw)
  e3.set_depth((1 : UInt32))
  ici2.set_extent(e3)
  ici2.set_mipLevels((1 : UInt32))
  ici2.set_arrayLayers((1 : UInt32))
  ici2.set_samples(@vk.VK_SAMPLE_COUNT_1_BIT)
  ici2.set_tiling(@vk.VK_IMAGE_TILING_OPTIMAL)
  ici2.set_usage(@vk.VK_IMAGE_USAGE_TRANSFER_SRC_BIT | @vk.VK_IMAGE_USAGE_TRANSFER_DST_BIT)
  let img_out = FixedArray::make(1, @vk.VkImage::null())
  let _ = (dfn.vkCreateImage)(dev, ici2, na, img_out)
  let img = img_out[0]
  let irq = @vk.VkMemoryRequirements::new()
  (dfn.vkGetImageMemoryRequirements)(dev, img, irq)
  let iai = @vk.VkMemoryAllocateInfo::new()
  iai.set_allocationSize(irq.get_size())
  iai.set_memoryTypeIndex(memtype(irq.get_memoryTypeBits(), devlocal).reinterpret_as_uint())
  let imem_out = FixedArray::make(1, @vk.VkDeviceMemory::null())
  let _ = (dfn.vkAllocateMemory)(dev, iai, na, imem_out)
  let _ = (dfn.vkBindImageMemory)(dev, img, imem_out[0], (0 : UInt64))
  let (srcbuf, srcmem) = mkbuf(((side * side * 4).to_uint64()), @vk.VK_BUFFER_USAGE_TRANSFER_SRC_BIT, host)
  let (dstbuf, dstmem) = mkbuf(((side * side * 4).to_uint64()), @vk.VK_BUFFER_USAGE_TRANSFER_DST_BIT, host)
  let parr : Array[Byte] = []
  for i = 0; i < side * side; i = i + 1 {
    parr.push((9 : Byte))
    parr.push((8 : Byte))
    parr.push((7 : Byte))
    parr.push((255 : Byte))
  }
  let _ = @vk.upload_bytes(dev, srcmem, Bytes::from_array(parr), (side * side * 4))

  // ---- record everything ----
  let bi = @vk.VkCommandBufferBeginInfo::new()
  let _ = (dfn.vkBeginCommandBuffer)(cb, bi)
  if has_sparse {
    // host -> sparse buffer
    let c1 = @vk.VkBufferCopy::new()
    c1.set_srcOffset((0 : UInt64))
    c1.set_dstOffset((0 : UInt64))
    c1.set_size(sparse_align)
    (dfn.vkCmdCopyBuffer)(cb, qbuf, sb, (1 : UInt32), c1)
    // sparse buffer -> host (proves the sparse binding is usable); the driver
    // needs the write made visible before the read
    let sbbar = @vk.VkBufferMemoryBarrier::new()
    sbbar.set_srcAccessMask(@vk.VK_ACCESS_TRANSFER_WRITE_BIT)
    sbbar.set_dstAccessMask(@vk.VK_ACCESS_TRANSFER_READ_BIT)
    sbbar.set_srcQueueFamilyIndex((0xFFFFFFFF : UInt32))
    sbbar.set_dstQueueFamilyIndex((0xFFFFFFFF : UInt32))
    sbbar.set_buffer(sb)
    sbbar.set_offset((0 : UInt64))
    sbbar.set_size(sparse_align)
    (dfn.vkCmdPipelineBarrier)(cb, @vk.VK_PIPELINE_STAGE_TRANSFER_BIT, @vk.VK_PIPELINE_STAGE_TRANSFER_BIT, (0 : UInt32), (0 : UInt32), @vk.VkMemoryBarrier::null(), (1 : UInt32), sbbar, (0 : UInt32), @vk.VkImageMemoryBarrier::null())
    let c2 = @vk.VkBufferCopy::new()
    c2.set_srcOffset((0 : UInt64))
    c2.set_dstOffset((0 : UInt64))
    c2.set_size(sparse_align)
    (dfn.vkCmdCopyBuffer)(cb, sb, qbuf, (1 : UInt32), c2)
  }
  // host -> lazily allocated memory -> host (commits the memory)
  if lazy_r == 0 {
    let lc1 = @vk.VkBufferCopy::new()
    lc1.set_srcOffset((0 : UInt64))
    lc1.set_dstOffset((0 : UInt64))
    lc1.set_size((4096 : UInt64))
    (dfn.vkCmdCopyBuffer)(cb, qbuf, lazy_buf, (1 : UInt32), lc1)
    let lc2 = @vk.VkBufferCopy::new()
    lc2.set_srcOffset((0 : UInt64))
    lc2.set_dstOffset((0 : UInt64))
    lc2.set_size((4096 : UInt64))
    (dfn.vkCmdCopyBuffer)(cb, lazy_buf, qbuf, (1 : UInt32), lc2)
  }
  // indirect dispatch
  (dfn.vkCmdBindPipeline)(cb, @vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe)
  (dfn.vkCmdBindDescriptorSets)(cb, @vk.VK_PIPELINE_BIND_POINT_COMPUTE, layout, (0 : UInt32), (1 : UInt32), ds_out, (0 : UInt32), FixedArray::make(0, (0 : UInt32)))
  (dfn.vkCmdDispatchIndirect)(cb, ibuf, (0 : UInt64))
  n = n + 1
  // buffer -> image (copy commands 2)
  let sub = @vk.VkImageSubresourceLayers::new()
  sub.set_aspectMask(@vk.VK_IMAGE_ASPECT_COLOR_BIT)
  sub.set_layerCount((1 : UInt32))
  let range = @vk.VkImageSubresourceRange::new()
  range.set_aspectMask(@vk.VK_IMAGE_ASPECT_COLOR_BIT)
  range.set_levelCount((1 : UInt32))
  range.set_layerCount((1 : UInt32))
  let off = @vk.VkOffset3D::new()
  off.set_x((0 : Int32))
  off.set_y((0 : Int32))
  off.set_z((0 : Int32))
  let bic = @vk.VkBufferImageCopy2::new()
  bic.set_bufferOffset((0 : UInt64))
  bic.set_imageSubresource(sub)
  bic.set_imageOffset(off)
  bic.set_imageExtent(e3)
  let cb2i = @vk.VkCopyBufferToImageInfo2::new()
  cb2i.set_srcBuffer(srcbuf)
  cb2i.set_dstImage(img)
  cb2i.set_dstImageLayout(@vk.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL)
  cb2i.set_regionCount((1 : UInt32))
  cb2i.set_pRegions(bic)
  // image layout: undefined -> transfer dst
  let bar = @vk.VkImageMemoryBarrier::new()
  bar.set_image(img)
  bar.set_srcAccessMask((0 : UInt32))
  bar.set_dstAccessMask(@vk.VK_ACCESS_TRANSFER_WRITE_BIT)
  bar.set_oldLayout(@vk.VK_IMAGE_LAYOUT_UNDEFINED)
  bar.set_newLayout(@vk.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL)
  bar.set_srcQueueFamilyIndex((0xFFFFFFFF : UInt32))
  bar.set_dstQueueFamilyIndex((0xFFFFFFFF : UInt32))
  bar.set_subresourceRange(range)
  (dfn.vkCmdPipelineBarrier)(cb, @vk.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT, @vk.VK_PIPELINE_STAGE_TRANSFER_BIT, (0 : UInt32), (0 : UInt32), @vk.VkMemoryBarrier::null(), (0 : UInt32), @vk.VkBufferMemoryBarrier::null(), (1 : UInt32), bar)
  if has_ext("VK_KHR_copy_commands2") {
    (dfn.vkCmdCopyBufferToImage2)(cb, cb2i)
    n = n + 1
  }
  // transfer dst -> transfer src
  let bar2 = @vk.VkImageMemoryBarrier::new()
  bar2.set_image(img)
  bar2.set_srcAccessMask(@vk.VK_ACCESS_TRANSFER_WRITE_BIT)
  bar2.set_dstAccessMask(@vk.VK_ACCESS_TRANSFER_READ_BIT)
  bar2.set_oldLayout(@vk.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL)
  bar2.set_newLayout(@vk.VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL)
  bar2.set_srcQueueFamilyIndex((0xFFFFFFFF : UInt32))
  bar2.set_dstQueueFamilyIndex((0xFFFFFFFF : UInt32))
  bar2.set_subresourceRange(range)
  (dfn.vkCmdPipelineBarrier)(cb, @vk.VK_PIPELINE_STAGE_TRANSFER_BIT, @vk.VK_PIPELINE_STAGE_TRANSFER_BIT, (0 : UInt32), (0 : UInt32), @vk.VkMemoryBarrier::null(), (0 : UInt32), @vk.VkBufferMemoryBarrier::null(), (1 : UInt32), bar2)
  // image -> buffer (copy commands 2)
  // the image-to-buffer region reuses VkBufferImageCopy2 in this header
  let ibc = @vk.VkBufferImageCopy2::new()
  ibc.set_bufferOffset((0 : UInt64))
  ibc.set_imageSubresource(sub)
  ibc.set_imageOffset(off)
  ibc.set_imageExtent(e3)
  let ci2b = @vk.VkCopyImageToBufferInfo2::new()
  ci2b.set_srcImage(img)
  ci2b.set_srcImageLayout(@vk.VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL)
  ci2b.set_dstBuffer(dstbuf)
  ci2b.set_regionCount((1 : UInt32))
  ci2b.set_pRegions(ibc)
  if has_ext("VK_KHR_copy_commands2") {
    (dfn.vkCmdCopyImageToBuffer2)(cb, ci2b)
    n = n + 1
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
  let _ = (dfn.vkDeviceWaitIdle)(dev)

  // ---- assertions ----
  let got = @vk.download_buffer(dev, omem, 32)
  let dispatch_ok = got[0].to_int() == 42 && got[28].to_int() == 49
  let disp7 = got[28].to_int()
  let pix = @vk.download_buffer(dev, dstmem, 4)
  let pixel_ok = pix[0] == (9 : Byte) && pix[1] == (8 : Byte) && pix[2] == (7 : Byte) && pix[3] == (255 : Byte)
  let sparse_bytes = @vk.download_buffer(dev, qmem, 16)
  let mut sparse_ok = true
  for i = 0; i < 16; i = i + 1 {
    if sparse_bytes[i] != (0xAB : Byte) {
      sparse_ok = false
    }
  }
  let mut commit_ok = true
  if lazy_r == 0 {
    (dfn.vkGetDeviceMemoryCommitment)(dev, lazy_out[0], commitment)
    n = n + 1
    commit_ok = commitment[0] > (0 : UInt64)
  }
  eprintln("[26-core] commitment=\{commitment[0]} lazy_type=\{lazy_type}")

  (dfn.vkDestroyFence)(dev, fence_out[0], na)
  if has_sparse {
    (dfn.vkDestroyFence)(dev, bf_out[0], na)
  }
  (dfn.vkDestroyCommandPool)(dev, cp_out[0], na)
  (dfn.vkDestroyDescriptorPool)(dev, pool_out[0], na)
  (dfn.vkDestroyDescriptorSetLayout)(dev, dsl_out[0], na)
  (dfn.vkDestroyPipeline)(dev, pipe, na)
  (dfn.vkDestroyPipelineLayout)(dev, layout, na)
  (dfn.vkDestroyShaderModule)(dev, sm_out[0], na)
  (dfn.vkDestroyImage)(dev, img, na)
  (dfn.vkFreeMemory)(dev, imem_out[0], na)
  (dfn.vkDestroyBuffer)(dev, srcbuf, na)
  (dfn.vkFreeMemory)(dev, srcmem, na)
  (dfn.vkDestroyBuffer)(dev, dstbuf, na)
  (dfn.vkFreeMemory)(dev, dstmem, na)
  (dfn.vkDestroyBuffer)(dev, obuf, na)
  (dfn.vkFreeMemory)(dev, omem, na)
  (dfn.vkDestroyBuffer)(dev, ibuf, na)
  (dfn.vkFreeMemory)(dev, imem, na)
  (dfn.vkDestroyBuffer)(dev, texbuf, na)
  (dfn.vkFreeMemory)(dev, texmem, na)
  if lazy_r == 0 {
    (dfn.vkDestroyBuffer)(dev, lazy_buf, na)
    (dfn.vkFreeMemory)(dev, lazy_out[0], na)
  }
  if has_sparse {
    (dfn.vkDestroyBuffer)(dev, sb, na)
    (dfn.vkFreeMemory)(dev, smem, na)
  }
  (dfn.vkDestroyBuffer)(dev, qbuf, na)
  (dfn.vkFreeMemory)(dev, qmem, na)
  (dfn.vkDestroyDevice)(dev, na)
  @vk.destroy_debug_messenger(inst, ifn, messenger)
  (ifn.vkDestroyInstance)(inst, na)
  println("[26-core] commands=\{n} version=\{ver[0]} layers=\{lcount[0]} proc=\{proc_ok} sparse=\{(bs == 0 && bsr == 0 && sparse_ok)} view=\{view_ok} dispatch=\{dispatch_ok} disp7=\{disp7} pixel=\{pixel_ok} commit=\{commit_ok} submit=\{sr} wait=\{wr} errors=\{g_errors.val}")
  if iv == 0 &&
     proc_ok &&
     bs == 0 &&
     bsr == 0 &&
     sparse_ok &&
     view_ok &&
     dispatch_ok &&
     pixel_ok &&
     commit_ok &&
     sr == 0 &&
     wr == 0 &&
     g_errors.val == 0 {
    println("[26-core] OK — \{n} core-surface commands, sparse/dispatch/copy verified")
  } else {
    println("[26-core] FAIL — sparse=\{bs}/\{bsr}/\{sparse_ok} view=\{view_ok} dispatch=\{dispatch_ok} pixel=\{pixel_ok} commit=\{commit_ok} errors=\{g_errors.val}")
  }
}
