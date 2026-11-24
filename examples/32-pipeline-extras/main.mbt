// Example 32 — Pipeline Executable Properties, Pipeline Binary, Descriptor Buffer
// Image Capture Data, Buffer Device Address EXT, Host Image Copy EXT, and
// NVIDIA Cooperative Matrix 2 / Copy Memory Indirect queries.

let g_errors : Ref[Int] = Ref::new(0)

///|
fn main {
  let na = @vk.VkAllocationCallbacks::null()
  let app = @vk.VkApplicationInfo::new()
  app.set_pApplicationName(@vk.cstr("Tycho32PipeExtras"))
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
    println("[32-pipe] FAIL — vkCreateInstance=\{ir}")
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
      println("[32-pipe] VALIDATION: \{@vk.read_cstr(data.get_pMessage())}")
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

  let mut n = 0
  // Coverage evidence: `avail` = extension-gated groups this driver can verify,
  // `ran` = groups that actually executed a command. Without it a driver that
  // lacks every gated extension reports OK after verifying nothing.
  let mut avail = 0
  let mut ran = 0

  // 1. Physical device cooperative matrix 2 flexible dimensions (NVIDIA)
  let before_1 = n
  if has_ext("VK_NV_cooperative_matrix2") {
    avail = avail + 1
    let cmc = FixedArray::make(1, (0 : UInt32))
    let _ = (ifn.vkGetPhysicalDeviceCooperativeMatrixFlexibleDimensionsPropertiesNV)(
      phys,
      cmc,
      @vk.VkCooperativeMatrixFlexibleDimensionsPropertiesNV::null(),
    )
    if cmc[0] > (0 : UInt32) {
      let arr = @vk.VkCooperativeMatrixFlexibleDimensionsPropertiesNV::array(cmc[0].reinterpret_as_int())
      let _ = (ifn.vkGetPhysicalDeviceCooperativeMatrixFlexibleDimensionsPropertiesNV)(phys, cmc, arr)
      arr.free()
    }
    n = n + 1
  }
  if n > before_1 {
    ran = ran + 1
  }

  // Query features
  let pep_q = @vk.VkPhysicalDevicePipelineExecutablePropertiesFeaturesKHR::new()
  let pb_q = @vk.VkPhysicalDevicePipelineBinaryFeaturesKHR::new()
  let db_q = @vk.VkPhysicalDeviceDescriptorBufferFeaturesEXT::new()
  let f12_q = @vk.VkPhysicalDeviceVulkan12Features::new()
  let f14_q = @vk.VkPhysicalDeviceVulkan14Features::new()
  let f2_q = @vk.VkPhysicalDeviceFeatures2::new()
  f2_q.set_pNext(pep_q.as_ptr())
  pep_q.set_pNext(pb_q.as_ptr())
  pb_q.set_pNext(db_q.as_ptr())
  db_q.set_pNext(f12_q.as_ptr())
  f12_q.set_pNext(f14_q.as_ptr())
  (ifn.vkGetPhysicalDeviceFeatures2)(phys, f2_q)

  let pep_en = @vk.VkPhysicalDevicePipelineExecutablePropertiesFeaturesKHR::new()
  pep_en.set_pipelineExecutableInfo(pep_q.get_pipelineExecutableInfo())
  let pb_en = @vk.VkPhysicalDevicePipelineBinaryFeaturesKHR::new()
  pb_en.set_pipelineBinaries(pb_q.get_pipelineBinaries())
  let db_en = @vk.VkPhysicalDeviceDescriptorBufferFeaturesEXT::new()
  db_en.set_descriptorBuffer(db_q.get_descriptorBuffer())
  db_en.set_descriptorBufferCaptureReplay(db_q.get_descriptorBufferCaptureReplay())
  let f12_en = @vk.VkPhysicalDeviceVulkan12Features::new()
  f12_en.set_bufferDeviceAddress(f12_q.get_bufferDeviceAddress())
  f12_en.set_bufferDeviceAddressCaptureReplay(f12_q.get_bufferDeviceAddressCaptureReplay())
  let f14_en = @vk.VkPhysicalDeviceVulkan14Features::new()
  f14_en.set_hostImageCopy(f14_q.get_hostImageCopy())

  pep_en.set_pNext(pb_en.as_ptr())
  pb_en.set_pNext(db_en.as_ptr())
  db_en.set_pNext(f12_en.as_ptr())
  f12_en.set_pNext(f14_en.as_ptr())

  let want = [
    "VK_KHR_pipeline_executable_properties",
    "VK_KHR_pipeline_binary",
    "VK_EXT_descriptor_buffer",
    "VK_EXT_host_image_copy",
  ]
  let den = FixedArray::make(want.length(), "")
  let mut nden = 0
  for i = 0; i < want.length(); i = i + 1 {
    if want[i] == "VK_EXT_host_image_copy" && f14_q.get_hostImageCopy() == 0 {
      continue
    }
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
  dci.set_pNext(pep_en.as_ptr())
  dci.set_queueCreateInfoCount((1 : UInt32))
  dci.set_pQueueCreateInfos(qci)
  dci.set_enabledExtensionCount(nden.reinterpret_as_uint())
  dci.set_ppEnabledExtensionNames(@vk.cstr_array(den))
  let dev_out = FixedArray::make(1, @vk.VkDevice::null())
  let dr = (ifn.vkCreateDevice)(phys, dci, na, dev_out)
  if dr != 0 {
    println("[32-pipe] FAIL — vkCreateDevice=\{dr}")
    return
  }
  let dev = dev_out[0]
  let dfn = @vk.DeviceFn::load(dev)
  let has = fn(name : String) -> Bool {
    (ifn.vkGetDeviceProcAddr)(dev, @vk.cstr(name)) != (0 : UInt64)
  }

  // Create compute pipeline
  let spv = @shader.compile_shader_file_env("examples/32-pipeline-extras/shader.comp", @shader.SHADER_KIND_COMPUTE, @shader.SHADER_ENV_VULKAN_1_3)
  let smci = @vk.VkShaderModuleCreateInfo::new()
  smci.set_codeSize((spv.length() * 4).to_uint64())
  smci.set_pCode(spv)
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

  let stage = @vk.VkPipelineShaderStageCreateInfo::new()
  stage.set_stage(@vk.VK_SHADER_STAGE_COMPUTE_BIT)
  stage.set_module(sm_out[0])
  stage.set_pName(@vk.cstr("main"))
  let cpci = @vk.VkComputePipelineCreateInfo::new()
  cpci.set_stage(stage)
  cpci.set_layout(pl_out[0])
  if has_ext("VK_KHR_pipeline_executable_properties") && pep_q.get_pipelineExecutableInfo() != 0 {
    cpci.set_flags(
      @vk.VK_PIPELINE_CREATE_CAPTURE_STATISTICS_BIT_KHR |
      @vk.VK_PIPELINE_CREATE_CAPTURE_INTERNAL_REPRESENTATIONS_BIT_KHR,
    )
  }
  let pipe_out = FixedArray::make(1, @vk.VkPipeline::null())
  let pr = (dfn.vkCreateComputePipelines)(dev, @vk.VkPipelineCache::null(), (1 : UInt32), cpci, na, pipe_out)

  // 2. Pipeline Executable Properties (3 commands)
  let before_2 = n
  let pep_gate = pr == 0 && has_ext("VK_KHR_pipeline_executable_properties") && pep_q.get_pipelineExecutableInfo() != 0 && has("vkGetPipelineExecutablePropertiesKHR")
  if pep_gate {
    avail = avail + 1
    let pi = @vk.VkPipelineInfoKHR::new()
    pi.set_pipeline(pipe_out[0])
    let ec = FixedArray::make(1, (0 : UInt32))
    let _ = (dfn.vkGetPipelineExecutablePropertiesKHR)(dev, pi, ec, @vk.VkPipelineExecutablePropertiesKHR::null())
    if ec[0] > (0 : UInt32) {
      let props = @vk.VkPipelineExecutablePropertiesKHR::array(ec[0].reinterpret_as_int())
      let _ = (dfn.vkGetPipelineExecutablePropertiesKHR)(dev, pi, ec, props)
      props.free()
    }
    n = n + 1

    let ei = @vk.VkPipelineExecutableInfoKHR::new()
    ei.set_pipeline(pipe_out[0])
    ei.set_executableIndex((0 : UInt32))
    let sc = FixedArray::make(1, (0 : UInt32))
    let _ = (dfn.vkGetPipelineExecutableStatisticsKHR)(dev, ei, sc, @vk.VkPipelineExecutableStatisticKHR::null())
    if sc[0] > (0 : UInt32) {
      let stats = @vk.VkPipelineExecutableStatisticKHR::array(sc[0].reinterpret_as_int())
      let _ = (dfn.vkGetPipelineExecutableStatisticsKHR)(dev, ei, sc, stats)
      stats.free()
    }
    n = n + 1

    let ic = FixedArray::make(1, (0 : UInt32))
    let _ = (dfn.vkGetPipelineExecutableInternalRepresentationsKHR)(
      dev,
      ei,
      ic,
      @vk.VkPipelineExecutableInternalRepresentationKHR::null(),
    )
    if ic[0] > (0 : UInt32) {
      let reps = @vk.VkPipelineExecutableInternalRepresentationKHR::array(ic[0].reinterpret_as_int())
      let _ = (dfn.vkGetPipelineExecutableInternalRepresentationsKHR)(dev, ei, ic, reps)
      reps.free()
    }
    n = n + 1
    pi.free()
    ei.free()
  }
  if pep_gate && n > before_2 {
    ran = ran + 1
  }

  // 3. Pipeline Binary KHR (4 commands: GetPipelineKeyKHR, CreatePipelineBinariesKHR, GetPipelineBinaryDataKHR, DestroyPipelineBinaryKHR)
  let before_3 = n
  let pb_gate = has_ext("VK_KHR_pipeline_binary") && pb_q.get_pipelineBinaries() != 0 && has("vkGetPipelineKeyKHR")
  if pb_gate {
    avail = avail + 1
    let pki = @vk.VkPipelineCreateInfoKHR::new()
    pki.set_pNext(cpci.as_ptr())
    let key = @vk.VkPipelineBinaryKeyKHR::new()
    let _ = (dfn.vkGetPipelineKeyKHR)(dev, pki, key)
    n = n + 1

    let pbci = @vk.VkPipelineBinaryCreateInfoKHR::new()
    pbci.set_pPipelineCreateInfo(pki)
    let handles = @vk.VkPipelineBinaryHandlesInfoKHR::new()
    let r1 = (dfn.vkCreatePipelineBinariesKHR)(dev, pbci, na, handles)
    let bcnt = handles.get_pipelineBinaryCount().reinterpret_as_int()
    if r1 == 0 && bcnt > 0 {
      let bins = FixedArray::make(bcnt, @vk.VkPipelineBinaryKHR::null())
      handles.set_pPipelineBinaries(bins)
      let r2 = (dfn.vkCreatePipelineBinariesKHR)(dev, pbci, na, handles)
      n = n + 1
      if r2 == 0 {
        let di = @vk.VkPipelineBinaryDataInfoKHR::new()
        di.set_pipelineBinary(bins[0])
        let dkey = @vk.VkPipelineBinaryKeyKHR::new()
        let dsz = FixedArray::make(1, (0 : UInt64))
        let _ = (dfn.vkGetPipelineBinaryDataKHR)(dev, di, dkey, dsz, (0 : UInt64))
        n = n + 1
        di.free()
        dkey.free()
        for i = 0; i < bcnt; i = i + 1 {
          (dfn.vkDestroyPipelineBinaryKHR)(dev, bins[i], na)
        }
        n = n + 1
      }
    }
    handles.free()
    pbci.free()
    key.free()
    pki.free()
  }
  if pb_gate && n > before_3 {
    ran = ran + 1
  }

  // 4. Buffer Device Address EXT (dedicated device because VK_EXT_buffer_device_address
  // is mutually exclusive with VkPhysicalDeviceVulkan12Features::bufferDeviceAddress)
  let before_4 = n
  let bda_gate = has_ext("VK_EXT_buffer_device_address")
  if bda_gate {
    avail = avail + 1
    let bda_ext_en = @vk.VkPhysicalDeviceBufferDeviceAddressFeaturesEXT::new()
    bda_ext_en.set_bufferDeviceAddress((1 : UInt32))
    let dci2 = @vk.VkDeviceCreateInfo::new()
    dci2.set_pNext(bda_ext_en.as_ptr())
    dci2.set_queueCreateInfoCount((1 : UInt32))
    dci2.set_pQueueCreateInfos(qci)
    dci2.set_enabledExtensionCount((1 : UInt32))
    dci2.set_ppEnabledExtensionNames(@vk.cstr_array(["VK_EXT_buffer_device_address"]))
    let dev2_out = FixedArray::make(1, @vk.VkDevice::null())
    if (ifn.vkCreateDevice)(phys, dci2, na, dev2_out) == 0 {
      let dev2 = dev2_out[0]
      let dfn2 = @vk.DeviceFn::load(dev2)
      let bci = @vk.VkBufferCreateInfo::new()
      bci.set_size((256 : UInt64))
      bci.set_usage(@vk.VK_BUFFER_USAGE_SHADER_DEVICE_ADDRESS_BIT)
      let bo = FixedArray::make(1, @vk.VkBuffer::null())
      let _ = (dfn2.vkCreateBuffer)(dev2, bci, na, bo)
      let rq = @vk.VkMemoryRequirements::new()
      (dfn2.vkGetBufferMemoryRequirements)(dev2, bo[0], rq)
      let ai = @vk.VkMemoryAllocateInfo::new()
      ai.set_allocationSize(rq.get_size())
      let mo = FixedArray::make(1, @vk.VkDeviceMemory::null())
      let _ = (dfn2.vkAllocateMemory)(dev2, ai, na, mo)
      let _ = (dfn2.vkBindBufferMemory)(dev2, bo[0], mo[0], (0 : UInt64))
      let bdai = @vk.VkBufferDeviceAddressInfo::new()
      bdai.set_buffer(bo[0])
      let addr = (dfn2.vkGetBufferDeviceAddressEXT)(dev2, bdai)
      if addr != (0 : UInt64) {
        n = n + 1
      }
      (dfn2.vkDestroyBuffer)(dev2, bo[0], na)
      (dfn2.vkFreeMemory)(dev2, mo[0], na)
      (dfn2.vkDestroyDevice)(dev2, na)
    }
    bda_ext_en.free()
    dci2.free()
  }
  if bda_gate && n > before_4 {
    ran = ran + 1
  }

  // 5. GetImageSubresourceLayout2EXT (VK_EXT_host_image_copy)
  let before_5 = n
  let hic_gate = has_ext("VK_EXT_host_image_copy") && f14_q.get_hostImageCopy() != 0 && has("vkGetImageSubresourceLayout2EXT")
  if hic_gate {
    avail = avail + 1
    let ici2 = @vk.VkImageCreateInfo::new()
    ici2.set_imageType(@vk.VK_IMAGE_TYPE_2D)
    ici2.set_format(@vk.VK_FORMAT_R8G8B8A8_UNORM)
    let e3 = @vk.VkExtent3D::new()
    e3.set_width((16 : UInt32))
    e3.set_height((16 : UInt32))
    e3.set_depth((1 : UInt32))
    ici2.set_extent(e3)
    ici2.set_mipLevels((1 : UInt32))
    ici2.set_arrayLayers((1 : UInt32))
    ici2.set_samples(@vk.VK_SAMPLE_COUNT_1_BIT)
    ici2.set_tiling(@vk.VK_IMAGE_TILING_LINEAR)
    ici2.set_usage(@vk.VK_IMAGE_USAGE_TRANSFER_SRC_BIT)
    let io = FixedArray::make(1, @vk.VkImage::null())
    if (dfn.vkCreateImage)(dev, ici2, na, io) == 0 {
      let isr = @vk.VkImageSubresource::new()
      isr.set_aspectMask(@vk.VK_IMAGE_ASPECT_COLOR_BIT)
      let is2 = @vk.VkImageSubresource2::new()
      is2.set_imageSubresource(isr)
      let sl2 = @vk.VkSubresourceLayout2::new()
      (dfn.vkGetImageSubresourceLayout2EXT)(dev, io[0], is2, sl2)
      n = n + 1
      (dfn.vkDestroyImage)(dev, io[0], na)
    }
  }
  if hic_gate && n > before_5 {
    ran = ran + 1
  }

  // 6. Descriptor Buffer Image / ImageView Opaque Capture Data EXT
  let before_6 = n
  let dcap_gate = has_ext("VK_EXT_descriptor_buffer") && db_q.get_descriptorBufferCaptureReplay() != 0 && has("vkGetImageOpaqueCaptureDescriptorDataEXT")
  if dcap_gate {
    avail = avail + 1
    let dbp = @vk.VkPhysicalDeviceDescriptorBufferPropertiesEXT::new()
    let p2 = @vk.VkPhysicalDeviceProperties2::new()
    p2.set_pNext(dbp.as_ptr())
    (ifn.vkGetPhysicalDeviceProperties2)(phys, p2)
    let isz = dbp.get_imageCaptureReplayDescriptorDataSize().to_int()
    let ivsz = dbp.get_imageViewCaptureReplayDescriptorDataSize().to_int()
    if isz > 0 || ivsz > 0 {
      let ici3 = @vk.VkImageCreateInfo::new()
      ici3.set_flags(@vk.VK_IMAGE_CREATE_DESCRIPTOR_BUFFER_CAPTURE_REPLAY_BIT_EXT)
      ici3.set_imageType(@vk.VK_IMAGE_TYPE_2D)
      ici3.set_format(@vk.VK_FORMAT_R8G8B8A8_UNORM)
      let e3 = @vk.VkExtent3D::new()
      e3.set_width((16 : UInt32))
      e3.set_height((16 : UInt32))
      e3.set_depth((1 : UInt32))
      ici3.set_extent(e3)
      ici3.set_mipLevels((1 : UInt32))
      ici3.set_arrayLayers((1 : UInt32))
      ici3.set_samples(@vk.VK_SAMPLE_COUNT_1_BIT)
      ici3.set_tiling(@vk.VK_IMAGE_TILING_OPTIMAL)
      ici3.set_usage(@vk.VK_IMAGE_USAGE_SAMPLED_BIT)
      let io = FixedArray::make(1, @vk.VkImage::null())
      if (dfn.vkCreateImage)(dev, ici3, na, io) == 0 {
        let rq = @vk.VkMemoryRequirements::new()
        (dfn.vkGetImageMemoryRequirements)(dev, io[0], rq)
        let afi = @vk.VkMemoryAllocateFlagsInfo::new()
        afi.set_flags(@vk.VK_MEMORY_ALLOCATE_DEVICE_ADDRESS_BIT | @vk.VK_MEMORY_ALLOCATE_DEVICE_ADDRESS_CAPTURE_REPLAY_BIT)
        let ai = @vk.VkMemoryAllocateInfo::new()
        ai.set_pNext(afi.as_ptr())
        ai.set_allocationSize(rq.get_size())
        let mo = FixedArray::make(1, @vk.VkDeviceMemory::null())
        if (dfn.vkAllocateMemory)(dev, ai, na, mo) == 0 {
          let _ = (dfn.vkBindImageMemory)(dev, io[0], mo[0], (0 : UInt64))
          if isz > 0 {
            let icdi = @vk.VkImageCaptureDescriptorDataInfoEXT::new()
            icdi.set_image(io[0])
            let buf = FixedArray::make(isz, (0 : Byte))
            let _ = (dfn.vkGetImageOpaqueCaptureDescriptorDataEXT)(dev, icdi, @vk.byte_ptr(buf))
            n = n + 1
          }
          if ivsz > 0 {
            let ivci = @vk.VkImageViewCreateInfo::new()
            ivci.set_flags(@vk.VK_IMAGE_VIEW_CREATE_DESCRIPTOR_BUFFER_CAPTURE_REPLAY_BIT_EXT)
            ivci.set_image(io[0])
            ivci.set_viewType(@vk.VK_IMAGE_VIEW_TYPE_2D)
            ivci.set_format(@vk.VK_FORMAT_R8G8B8A8_UNORM)
            let sr = @vk.VkImageSubresourceRange::new()
            sr.set_aspectMask(@vk.VK_IMAGE_ASPECT_COLOR_BIT)
            sr.set_levelCount((1 : UInt32))
            sr.set_layerCount((1 : UInt32))
            ivci.set_subresourceRange(sr)
            let ivo = FixedArray::make(1, @vk.VkImageView::null())
            if (dfn.vkCreateImageView)(dev, ivci, na, ivo) == 0 {
              let ivcdi = @vk.VkImageViewCaptureDescriptorDataInfoEXT::new()
              ivcdi.set_imageView(ivo[0])
              let buf = FixedArray::make(ivsz, (0 : Byte))
              let _ = (dfn.vkGetImageViewOpaqueCaptureDescriptorDataEXT)(dev, ivcdi, @vk.byte_ptr(buf))
              n = n + 1
              (dfn.vkDestroyImageView)(dev, ivo[0], na)
            }
          }
          (dfn.vkFreeMemory)(dev, mo[0], na)
        }
        (dfn.vkDestroyImage)(dev, io[0], na)
      }
    }
  }
  if dcap_gate && n > before_6 {
    ran = ran + 1
  }

  if pr == 0 {
    (dfn.vkDestroyPipeline)(dev, pipe_out[0], na)
  }
  (dfn.vkDestroyPipelineLayout)(dev, pl_out[0], na)
  (dfn.vkDestroyDescriptorSetLayout)(dev, dsl_out[0], na)
  (dfn.vkDestroyShaderModule)(dev, sm_out[0], na)
  (dfn.vkDestroyDevice)(dev, na)
  @vk.destroy_debug_messenger(inst, ifn, messenger)
  (ifn.vkDestroyInstance)(inst, na)

  println("[32-pipe] commands=\{n} pipe=\{pr} errors=\{g_errors.val}")
  let shortfall = avail - ran
  if pr != 0 || g_errors.val != 0 {
    println("[32-pipe] FAIL — pr=\{pr} n=\{n} groups=\{ran}/\{avail} errors=\{g_errors.val}")
  } else if shortfall > 0 {
    println("[32-pipe] FAIL — \{shortfall} supported extension group(s) executed nothing (groups=\{ran}/\{avail} n=\{n})")
  } else if n == 0 {
    println("[32-pipe] SKIP — 0 pipeline/descriptor-buffer/address commands available on this driver")
  } else {
    println("[32-pipe] OK — \{n} pipeline/descriptor-buffer/address commands verified, 0 validation errors")
  }
}
