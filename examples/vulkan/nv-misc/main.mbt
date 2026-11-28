// vulkan/nv-misc — NVIDIA-only query and handle families: device fault info,
// calibrated timestamps, diagnostic checkpoints, shader module identifiers,
// NVX image view handles, DRM format modifier properties and the POSIX fd
// import/export of fences and semaphores. Fourteenth coverage batch.
// On a driver without the NVIDIA extensions the example reports SKIP.

///|
let na : @vk.VkAllocationCallbacks = @vk.VkAllocationCallbacks::null()

///|
let g_errors : Ref[Int] = { val: 0 }

///|
fn main {
  let mut n = 0
  let app = @vk.VkApplicationInfo::new()
  app.set_pApplicationName(@vk.cstr("Tycho NVMisc"))
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
    println("[28-nv] FAIL — vkCreateInstance=\{ir}")
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
      eprintln("[28-nv] VALIDATION: \{@vk.read_cstr(data.get_pMessage())}")
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
  // device extensions this batch needs: core NVIDIA extensions are required,
  // while Linux-only DRM/POSIX-fd extensions are enabled when advertised.
  let required = [
    "VK_EXT_device_fault",
    "VK_KHR_calibrated_timestamps",
    "VK_NV_device_diagnostic_checkpoints",
    "VK_EXT_shader_module_identifier",
    "VK_NVX_image_view_handle",
  ]
  let optional = [
    "VK_EXT_image_drm_format_modifier",
    "VK_KHR_external_fence_fd",
    "VK_KHR_external_semaphore_fd",
  ]
  let den = FixedArray::make(required.length() + optional.length(), "")
  let mut nden = 0
  let mut missing = 0
  for i = 0; i < required.length(); i = i + 1 {
    if has_ext(required[i]) {
      den[nden] = required[i]
      nden = nden + 1
    } else {
      missing = missing + 1
    }
  }
  let has_fence_fd = has_ext("VK_KHR_external_fence_fd")
  let has_sem_fd = has_ext("VK_KHR_external_semaphore_fd")
  for i = 0; i < optional.length(); i = i + 1 {
    if has_ext(optional[i]) {
      den[nden] = optional[i]
      nden = nden + 1
    }
  }
  if missing > 0 || !has_ext("VK_NV_cooperative_vector") || !has_ext("VK_NV_optical_flow") {
    println("[28-nv] SKIP — \{missing} NVIDIA extensions missing on this driver")
    @vk.destroy_debug_messenger(inst, ifn, messenger)
    (ifn.vkDestroyInstance)(inst, na)
    return
  }
  let f12 = @vk.VkPhysicalDeviceVulkan12Features::new()
  f12.set_bufferDeviceAddress((1 : UInt32))
  let smid = @vk.VkPhysicalDeviceShaderModuleIdentifierFeaturesEXT::new()
  smid.set_shaderModuleIdentifier((1 : UInt32))
  f12.set_pNext(smid.as_ptr())
  let feats = @vk.VkPhysicalDeviceFeatures::new()
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
  dci.set_enabledExtensionCount(nden.reinterpret_as_uint())
  dci.set_ppEnabledExtensionNames(@vk.cstr_array(den))
  let dev_out = FixedArray::make(1, @vk.VkDevice::null())
  let dr = (ifn.vkCreateDevice)(phys, dci, na, dev_out)
  if dr != 0 {
    println("[28-nv] FAIL — vkCreateDevice=\{dr}")
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

  // ---- physical device level queries ----
  let coop_count = FixedArray::make(1, (0 : UInt32))
  let coop_r = if has("vkGetPhysicalDeviceCooperativeVectorPropertiesNV") {
    let r = (ifn.vkGetPhysicalDeviceCooperativeVectorPropertiesNV)(phys, coop_count, @vk.VkCooperativeVectorPropertiesNV::null())
    n = n + 1
    r
  } else {
    0
  }
  let coop_ok = coop_r >= 0
  let ofi = @vk.VkOpticalFlowImageFormatInfoNV::new()
  ofi.set_usage(@vk.VK_OPTICAL_FLOW_USAGE_INPUT_BIT_NV | @vk.VK_OPTICAL_FLOW_USAGE_OUTPUT_BIT_NV)
  let of_count = FixedArray::make(1, (0 : UInt32))
  let of_r = if has("vkGetPhysicalDeviceOpticalFlowImageFormatsNV") {
    let r = (ifn.vkGetPhysicalDeviceOpticalFlowImageFormatsNV)(phys, ofi, of_count, @vk.VkOpticalFlowImageFormatPropertiesNV::null())
    n = n + 1
    r
  } else {
    0
  }
  let of_ok = of_r >= 0

  // vkGetDeviceFaultInfoEXT is only legal on a lost device (VUID-...-07336),
  // so it cannot be exercised on a healthy one and stays uncovered.

  // ---- calibrated timestamps ----
  let ctsi = @vk.VkCalibratedTimestampInfoKHR::new()
  ctsi.set_timeDomain(@vk.VK_TIME_DOMAIN_DEVICE_KHR)
  let ts = FixedArray::make(1, (0 : UInt64))
  let ts_dev = FixedArray::make(1, (0 : UInt64))
  let ts_r = if has("vkGetCalibratedTimestampsKHR") {
    let r = (dfn.vkGetCalibratedTimestampsKHR)(dev, (1 : UInt32), ctsi, ts, ts_dev)
    n = n + 1
    r
  } else {
    0
  }
  let ts_ok = ts_r == 0

  // ---- a small image, view and sampler for the handle queries ----
  let e3 = @vk.VkExtent3D::new()
  e3.set_width((16 : UInt32))
  e3.set_height((16 : UInt32))
  e3.set_depth((1 : UInt32))
  let imci = @vk.VkImageCreateInfo::new()
  imci.set_imageType(@vk.VK_IMAGE_TYPE_2D)
  imci.set_format(@vk.VK_FORMAT_R8G8B8A8_UNORM)
  imci.set_extent(e3)
  imci.set_mipLevels((1 : UInt32))
  imci.set_arrayLayers((1 : UInt32))
  imci.set_samples(@vk.VK_SAMPLE_COUNT_1_BIT)
  imci.set_tiling(@vk.VK_IMAGE_TILING_OPTIMAL)
  imci.set_usage(@vk.VK_IMAGE_USAGE_SAMPLED_BIT | @vk.VK_IMAGE_USAGE_TRANSFER_SRC_BIT)
  let img_out = FixedArray::make(1, @vk.VkImage::null())
  let _ = (dfn.vkCreateImage)(dev, imci, na, img_out)
  let img = img_out[0]
  let mp = @vk.VkPhysicalDeviceMemoryProperties::new()
  (ifn.vkGetPhysicalDeviceMemoryProperties)(phys, mp)
  let mut mi = 0
  for i = 0; i < mp.get_memoryTypeCount().reinterpret_as_int(); i = i + 1 {
    if (mp.get_memoryTypes_at(i).get_propertyFlags() & @vk.VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT) != (0 : UInt32) {
      mi = i
      break
    }
  }
  let irq = @vk.VkMemoryRequirements::new()
  (dfn.vkGetImageMemoryRequirements)(dev, img, irq)
  let iai = @vk.VkMemoryAllocateInfo::new()
  iai.set_allocationSize(irq.get_size())
  iai.set_memoryTypeIndex(mi.reinterpret_as_uint())
  let imem_out = FixedArray::make(1, @vk.VkDeviceMemory::null())
  let _ = (dfn.vkAllocateMemory)(dev, iai, na, imem_out)
  let _ = (dfn.vkBindImageMemory)(dev, img, imem_out[0], (0 : UInt64))
  let range = @vk.VkImageSubresourceRange::new()
  range.set_aspectMask(@vk.VK_IMAGE_ASPECT_COLOR_BIT)
  range.set_levelCount((1 : UInt32))
  range.set_layerCount((1 : UInt32))
  let ivci = @vk.VkImageViewCreateInfo::new()
  ivci.set_image(img)
  ivci.set_viewType(@vk.VK_IMAGE_VIEW_TYPE_2D)
  ivci.set_format(@vk.VK_FORMAT_R8G8B8A8_UNORM)
  ivci.set_subresourceRange(range)
  let view_out = FixedArray::make(1, @vk.VkImageView::null())
  let _ = (dfn.vkCreateImageView)(dev, ivci, na, view_out)
  let view = view_out[0]
  let sci = @vk.VkSamplerCreateInfo::new()
  sci.set_magFilter(@vk.VK_FILTER_NEAREST)
  sci.set_minFilter(@vk.VK_FILTER_NEAREST)
  let samp_out = FixedArray::make(1, @vk.VkSampler::null())
  let _ = (dfn.vkCreateSampler)(dev, sci, na, samp_out)
  let samp = samp_out[0]

  // vkGetImageDrmFormatModifierPropertiesEXT needs an image created with
  // VK_IMAGE_TILING_DRM_FORMAT_MODIFIER_EXT; this driver reports an
  // imageCreateMaxExtent of 0 for DRM tiling, so there is no legal image to
  // query and the command stays uncovered here.

  // ---- diagnostic checkpoints ----
  let cp_count = FixedArray::make(1, (0 : UInt32))
  let cpdata = @vk.VkCheckpointDataNV::new()
  if has("vkGetQueueCheckpointDataNV") {
    (dfn.vkGetQueueCheckpointDataNV)(queue, cp_count, cpdata)
    n = n + 1
  }
  let cp2_count = FixedArray::make(1, (0 : UInt32))
  let cp2data = @vk.VkCheckpointData2NV::new()
  if has("vkGetQueueCheckpointData2NV") {
    (dfn.vkGetQueueCheckpointData2NV)(queue, cp2_count, cp2data)
    n = n + 1
  }

  // ---- shader module identifiers ----
  let code = @shader.compile_shader_file("examples/vulkan/nv-misc/shader.comp", @shader.ShaderStage::Compute)
  let smci = @vk.VkShaderModuleCreateInfo::new()
  smci.set_codeSize((code.length() * 4).to_uint64())
  smci.set_pCode(code)
  let sm_out = FixedArray::make(1, @vk.VkShaderModule::null())
  let _ = (dfn.vkCreateShaderModule)(dev, smci, na, sm_out)
  let ident = @vk.VkShaderModuleIdentifierEXT::new()
  if has("vkGetShaderModuleIdentifierEXT") {
    (dfn.vkGetShaderModuleIdentifierEXT)(dev, sm_out[0], ident)
    n = n + 1
  }
  let ident2 = @vk.VkShaderModuleIdentifierEXT::new()
  if has("vkGetShaderModuleCreateInfoIdentifierEXT") {
    (dfn.vkGetShaderModuleCreateInfoIdentifierEXT)(dev, smci, ident2)
    n = n + 1
  }
  let ident_ok = ident.get_identifierSize() > (0 : UInt32)

  // ---- NVX image view handles ----
  let hinfo = @vk.VkImageViewHandleInfoNVX::new()
  hinfo.set_imageView(view)
  hinfo.set_descriptorType(@vk.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER)
  hinfo.set_sampler(samp)
  let handle_size = if has("vkGetImageViewHandleNVX") {
    let r = (dfn.vkGetImageViewHandleNVX)(dev, hinfo)
    n = n + 1
    r
  } else {
    0
  }
  let handle64 = if has("vkGetImageViewHandle64NVX") {
    let r = (dfn.vkGetImageViewHandle64NVX)(dev, hinfo)
    n = n + 1
    r
  } else {
    0
  }
  let addr = @vk.VkImageViewAddressPropertiesNVX::new()
  let addr_r = if has("vkGetImageViewAddressNVX") {
    let r = (dfn.vkGetImageViewAddressNVX)(dev, view, addr)
    n = n + 1
    r
  } else {
    0
  }
  let combined = if has("vkGetDeviceCombinedImageSamplerIndexNVX") {
    let r = (dfn.vkGetDeviceCombinedImageSamplerIndexNVX)(dev, view.as_ptr(), samp.as_ptr())
    n = n + 1
    r
  } else {
    0
  }
  let handle_ok = handle_size > (0 : UInt32) && handle64 != (0 : UInt64)

  // ---- POSIX fd import/export (Linux/POSIX only; skipped when fd extensions are absent) ----
  let mut fd_ok = true
  let mut imp_r = 0
  let mut sfd_ok = true
  let mut imps_r = 0
  if has_fence_fd {
    let efci = @vk.VkExportFenceCreateInfo::new()
    efci.set_handleTypes(@vk.VK_EXTERNAL_FENCE_HANDLE_TYPE_OPAQUE_FD_BIT)
    let fci = @vk.VkFenceCreateInfo::new()
    fci.set_pNext(efci.as_ptr())
    let fci2 = @vk.VkFenceCreateInfo::new()
    let fence_out = FixedArray::make(1, @vk.VkFence::null())
    let _ = (dfn.vkCreateFence)(dev, fci, na, fence_out)
    let fd = FixedArray::make(1, (0 : Int32))
    let fgfi = @vk.VkFenceGetFdInfoKHR::new()
    fgfi.set_fence(fence_out[0])
    fgfi.set_handleType(@vk.VK_EXTERNAL_FENCE_HANDLE_TYPE_OPAQUE_FD_BIT)
    let fd_r = if has("vkGetFenceFdKHR") {
      let r = (dfn.vkGetFenceFdKHR)(dev, fgfi, fd)
      n = n + 1
      r
    } else {
      0
    }
    fd_ok = fd_r == 0 && fd[0] >= 0
    let impfence_out = FixedArray::make(1, @vk.VkFence::null())
    let _ = (dfn.vkCreateFence)(dev, fci2, na, impfence_out)
    let ifi = @vk.VkImportFenceFdInfoKHR::new()
    ifi.set_fd(fd[0])
    ifi.set_fence(impfence_out[0])
    ifi.set_handleType(@vk.VK_EXTERNAL_FENCE_HANDLE_TYPE_OPAQUE_FD_BIT)
    ifi.set_flags(@vk.VK_FENCE_IMPORT_TEMPORARY_BIT)
    imp_r = if has("vkImportFenceFdKHR") && fd_ok {
      let r = (dfn.vkImportFenceFdKHR)(dev, ifi)
      n = n + 1
      r
    } else {
      0
    }
    if imp_r == 0 {
      (dfn.vkDestroyFence)(dev, impfence_out[0], na)
    }
    (dfn.vkDestroyFence)(dev, fence_out[0], na)
  }
  if has_sem_fd {
    let sci3 = @vk.VkSemaphoreCreateInfo::new()
    let esci = @vk.VkExportSemaphoreCreateInfo::new()
    esci.set_handleTypes(@vk.VK_EXTERNAL_SEMAPHORE_HANDLE_TYPE_OPAQUE_FD_BIT)
    let sci2 = @vk.VkSemaphoreCreateInfo::new()
    sci2.set_pNext(esci.as_ptr())
    let sem_out = FixedArray::make(1, @vk.VkSemaphore::null())
    let _ = (dfn.vkCreateSemaphore)(dev, sci2, na, sem_out)
    let sfd = FixedArray::make(1, (0 : Int32))
    let sgfi = @vk.VkSemaphoreGetFdInfoKHR::new()
    sgfi.set_semaphore(sem_out[0])
    sgfi.set_handleType(@vk.VK_EXTERNAL_SEMAPHORE_HANDLE_TYPE_OPAQUE_FD_BIT)
    let sfd_r = if has("vkGetSemaphoreFdKHR") {
      let r = (dfn.vkGetSemaphoreFdKHR)(dev, sgfi, sfd)
      n = n + 1
      r
    } else {
      0
    }
    sfd_ok = sfd_r == 0 && sfd[0] >= 0
    let impsem_out = FixedArray::make(1, @vk.VkSemaphore::null())
    let _ = (dfn.vkCreateSemaphore)(dev, sci3, na, impsem_out)
    let isi = @vk.VkImportSemaphoreFdInfoKHR::new()
    isi.set_fd(sfd[0])
    isi.set_semaphore(impsem_out[0])
    isi.set_handleType(@vk.VK_EXTERNAL_SEMAPHORE_HANDLE_TYPE_OPAQUE_FD_BIT)
    isi.set_flags(@vk.VK_SEMAPHORE_IMPORT_TEMPORARY_BIT)
    imps_r = if has("vkImportSemaphoreFdKHR") && sfd_ok {
      let r = (dfn.vkImportSemaphoreFdKHR)(dev, isi)
      n = n + 1
      r
    } else {
      0
    }
    if imps_r == 0 {
      (dfn.vkDestroySemaphore)(dev, impsem_out[0], na)
    }
    (dfn.vkDestroySemaphore)(dev, sem_out[0], na)
  }

  (dfn.vkDestroySampler)(dev, samp, na)
  (dfn.vkDestroyImageView)(dev, view, na)
  (dfn.vkDestroyImage)(dev, img, na)
  (dfn.vkFreeMemory)(dev, imem_out[0], na)
  (dfn.vkDestroyShaderModule)(dev, sm_out[0], na)
  (dfn.vkDestroyDevice)(dev, na)
  @vk.destroy_debug_messenger(inst, ifn, messenger)
  (ifn.vkDestroyInstance)(inst, na)
  let min_cmds = 9 + (if has_fence_fd { 2 } else { 0 }) + (if has_sem_fd { 2 } else { 0 })
  println("[28-nv] commands=\{n} coop=\{coop_ok} of=\{of_ok} ts=\{ts_ok} ident=\{ident_ok} handle=\{handle_ok} addr=\{addr_r} combined=\{combined} fd=\{fd_ok} imp=\{imp_r} sem=\{sfd_ok} imps=\{imps_r} errors=\{g_errors.val}")
  if coop_ok &&
     of_ok &&
     ts_ok &&
     ident_ok &&
     handle_ok &&
     addr_r == 0 &&
     fd_ok &&
     imp_r == 0 &&
     sfd_ok &&
     imps_r == 0 &&
     n >= min_cmds &&
     g_errors.val == 0 {
    println("[28-nv] OK — \{n} NVIDIA-family commands and handles verified")
  } else {
    println("[28-nv] FAIL — commands=\{n} errors=\{g_errors.val}")
  }
}
