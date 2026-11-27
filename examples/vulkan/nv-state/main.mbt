// vulkan/nv-state — the small NVIDIA-only dynamic state families: exclusive
// scissor, viewport W scaling, the AMD buffer marker and the compute
// occupancy priority. Fifteenth coverage batch. The marker value is read
// back so the command has to have written it.

///|
let na : @vk.VkAllocationCallbacks = @vk.VkAllocationCallbacks::null()

///|
let g_errors : Ref[Int] = { val: 0 }

///|
fn main {
  let mut n = 0
  let app = @vk.VkApplicationInfo::new()
  app.set_pApplicationName(@vk.cstr("Tycho NVState"))
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
    println("[29-nv] FAIL — vkCreateInstance=\{ir}")
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
      eprintln("[29-nv] VALIDATION: \{@vk.read_cstr(data.get_pMessage())}")
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
  let want = [
    "VK_NV_scissor_exclusive",
    "VK_NV_clip_space_w_scaling",
    "VK_AMD_buffer_marker",
    "VK_NV_compute_occupancy_priority",
  ]
  let den = FixedArray::make(want.length(), "")
  let mut nden = 0
  let mut missing = 0
  for i = 0; i < want.length(); i = i + 1 {
    if has_ext(want[i]) {
      den[nden] = want[i]
      nden = nden + 1
    } else {
      missing = missing + 1
    }
  }
  if missing > 0 {
    println("[29-nv] SKIP — \{missing} NVIDIA extensions missing on this driver")
    @vk.destroy_debug_messenger(inst, ifn, messenger)
    (ifn.vkDestroyInstance)(inst, na)
    return
  }
  let feats = @vk.VkPhysicalDeviceFeatures::new()
  let excl = @vk.VkPhysicalDeviceExclusiveScissorFeaturesNV::new()
  excl.set_exclusiveScissor((1 : UInt32))
  let f13 = @vk.VkPhysicalDeviceVulkan13Features::new()
  f13.set_dynamicRendering((1 : UInt32))
  excl.set_pNext(f13.as_ptr())
  let prio = FixedArray::make(1, (1.0 : Float))
  let qci = @vk.VkDeviceQueueCreateInfo::new()
  qci.set_queueFamilyIndex((0 : UInt32))
  qci.set_queueCount((1 : UInt32))
  qci.set_pQueuePriorities(prio)
  let dci = @vk.VkDeviceCreateInfo::new()
  dci.set_pNext(excl.as_ptr())
  dci.set_pEnabledFeatures(feats)
  dci.set_queueCreateInfoCount((1 : UInt32))
  dci.set_pQueueCreateInfos(qci)
  dci.set_enabledExtensionCount(nden.reinterpret_as_uint())
  dci.set_ppEnabledExtensionNames(@vk.cstr_array(den))
  let dev_out = FixedArray::make(1, @vk.VkDevice::null())
  let dr = (ifn.vkCreateDevice)(phys, dci, na, dev_out)
  if dr != 0 {
    println("[29-nv] FAIL — vkCreateDevice=\{dr}")
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

  // ---- graphics pipeline with the NVIDIA dynamic states ----
  let vert = @shader.compile_shader_file("examples/vulkan/nv-state/shader.vert", @shader.SHADER_KIND_VERTEX)
  let frag = @shader.compile_shader_file("examples/vulkan/nv-state/shader.frag", @shader.SHADER_KIND_FRAGMENT)
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
  let side = 64
  let sideu = (64 : UInt32)
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
  let ds = FixedArray::make(4, (0 : UInt32))
  ds[0] = @vk.VK_DYNAMIC_STATE_VIEWPORT
  ds[1] = @vk.VK_DYNAMIC_STATE_SCISSOR
  ds[2] = @vk.VK_DYNAMIC_STATE_EXCLUSIVE_SCISSOR_ENABLE_NV
  ds[3] = @vk.VK_DYNAMIC_STATE_EXCLUSIVE_SCISSOR_NV
  let dynst = @vk.VkPipelineDynamicStateCreateInfo::new()
  dynst.set_dynamicStateCount(ds.length().reinterpret_as_uint())
  dynst.set_pDynamicStates(ds)
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
  gpci.set_pDynamicState(dynst)
  gpci.set_layout(layout)
  let pipe_out = FixedArray::make(1, @vk.VkPipeline::null())
  let gpr = (dfn.vkCreateGraphicsPipelines)(dev, @vk.VkPipelineCache::null(), (1 : UInt32), gpci, na, pipe_out)
  if gpr != 0 {
    println("[29-nv] FAIL — pipeline=\{gpr}")
    return
  }
  let pipe = pipe_out[0]

  // ---- compute pipeline for the occupancy priority ----
  let code = @shader.compile_shader_file("examples/vulkan/nv-state/shader.comp", @shader.SHADER_KIND_COMPUTE)
  let csmci = @vk.VkShaderModuleCreateInfo::new()
  csmci.set_codeSize((code.length() * 4).to_uint64())
  csmci.set_pCode(code)
  let csm_out = FixedArray::make(1, @vk.VkShaderModule::null())
  let _ = (dfn.vkCreateShaderModule)(dev, csmci, na, csm_out)
  let cstage = @vk.VkPipelineShaderStageCreateInfo::new()
  cstage.set_stage(@vk.VK_SHADER_STAGE_COMPUTE_BIT)
  cstage.set_module(csm_out[0])
  cstage.set_pName(@vk.cstr("main"))
  let cpci = @vk.VkComputePipelineCreateInfo::new()
  cpci.set_stage(cstage)
  cpci.set_layout(layout)
  let cpipe_out = FixedArray::make(1, @vk.VkPipeline::null())
  let cpr = (dfn.vkCreateComputePipelines)(dev, @vk.VkPipelineCache::null(), (1 : UInt32), cpci, na, cpipe_out)
  if cpr != 0 {
    println("[29-nv] FAIL — compute pipeline=\{cpr}")
    return
  }
  let cpipe = cpipe_out[0]

  // ---- marker buffer ----
  let (mbuf, mmem) = mkbuf((16 : UInt64), @vk.VK_BUFFER_USAGE_TRANSFER_DST_BIT, host)

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
  (dfn.vkCmdBindPipeline)(cb, @vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe)
  if has("vkCmdSetViewport") {
    (dfn.vkCmdSetViewport)(cb, (0 : UInt32), (1 : UInt32), vp)
  }
  if has("vkCmdSetScissor") {
    (dfn.vkCmdSetScissor)(cb, (0 : UInt32), (1 : UInt32), sc)
  }
  if has("vkCmdSetExclusiveScissorEnableNV") {
    (dfn.vkCmdSetExclusiveScissorEnableNV)(cb, (0 : UInt32), (1 : UInt32), FixedArray::make(1, (1 : UInt32)))
    n = n + 1
  }
  if has("vkCmdSetExclusiveScissorNV") {
    (dfn.vkCmdSetExclusiveScissorNV)(cb, (0 : UInt32), (1 : UInt32), sc)
    n = n + 1
  }
  if has("vkCmdSetViewportWScalingNV") {
    let ws = @vk.VkViewportWScalingNV::new()
    ws.set_xcoeff((1.0 : Float))
    ws.set_ycoeff((1.0 : Float))
    (dfn.vkCmdSetViewportWScalingNV)(cb, (0 : UInt32), (1 : UInt32), ws)
    n = n + 1
  }
  if has("vkCmdWriteBufferMarker2AMD") {
    (dfn.vkCmdWriteBufferMarker2AMD)(cb, @vk.VK_PIPELINE_STAGE_2_ALL_COMMANDS_BIT, mbuf, (0 : UInt64), (305419896 : UInt32))
    n = n + 1
  }
  (dfn.vkCmdBindPipeline)(cb, @vk.VK_PIPELINE_BIND_POINT_COMPUTE, cpipe)
  if has("vkCmdSetComputeOccupancyPriorityNV") {
    let op = @vk.VkComputeOccupancyPriorityParametersNV::new()
    op.set_occupancyPriority((0.5 : Float))
    op.set_occupancyThrottling((0.5 : Float))
    (dfn.vkCmdSetComputeOccupancyPriorityNV)(cb, op)
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
  let marker = @vk.download_buffer(dev, mmem, 4)
  // the marker is a little-endian uint32
  let marker_ok = marker[0] == (0x78 : Byte) && marker[1] == (0x56 : Byte) && marker[2] == (0x34 : Byte) && marker[3] == (0x12 : Byte)

  (dfn.vkDestroyFence)(dev, fence_out[0], na)
  (dfn.vkDestroyCommandPool)(dev, cp_out[0], na)
  (dfn.vkDestroyPipeline)(dev, pipe, na)
  (dfn.vkDestroyPipeline)(dev, cpipe, na)
  (dfn.vkDestroyPipelineLayout)(dev, layout, na)
  (dfn.vkDestroyShaderModule)(dev, vsm_out[0], na)
  (dfn.vkDestroyShaderModule)(dev, fsm_out[0], na)
  (dfn.vkDestroyShaderModule)(dev, csm_out[0], na)
  (dfn.vkDestroyBuffer)(dev, mbuf, na)
  (dfn.vkFreeMemory)(dev, mmem, na)
  (dfn.vkDestroyDevice)(dev, na)
  @vk.destroy_debug_messenger(inst, ifn, messenger)
  (ifn.vkDestroyInstance)(inst, na)
  println("[29-nv] commands=\{n} marker=\{marker_ok} submit=\{sr} wait=\{wr} errors=\{g_errors.val}")
  if n >= 5 && marker_ok && sr == 0 && wr == 0 && g_errors.val == 0 {
    println("[29-nv] OK — \{n} NVIDIA state commands, marker value verified")
  } else {
    println("[29-nv] FAIL — commands=\{n} marker=\{marker_ok} errors=\{g_errors.val}")
  }
}
