// Example 16 — physical-device query/enumeration coverage (headless).
// Sweeps the reachable vkGetPhysicalDevice* / vkEnumerate* surface, including
// the promoted core/KHR alias pairs, which are separate dispatch slots.
// Extension-gated queries run only where the driver advertises them.

///|
fn has_ext(exts : FixedArray[String], n : Int, name : String) -> Bool {
  for i = 0; i < n; i = i + 1 {
    if exts[i] == name {
      return true
    }
  }
  false
}

///|
// Promoted core commands keep their KHR/EXT names, but the loader only resolves
// those aliases when the originating instance extension is enabled. Enable the
// ones this driver advertises and gate each alias call on that.
fn pick_instance_exts(want : FixedArray[String]) -> (FixedArray[String], Int) {
  let c = FixedArray::make(1, (0 : UInt32))
  let _ = @vk.vkEnumerateInstanceExtensionProperties(
    (0 : UInt64),
    c,
    @vk.VkExtensionProperties::null(),
  )
  let n = c[0].reinterpret_as_int()
  let props = @vk.VkExtensionProperties::array(n)
  let _ = @vk.vkEnumerateInstanceExtensionProperties((0 : UInt64), c, props)
  let avail = FixedArray::make(n, "")
  for i = 0; i < n; i = i + 1 {
    avail[i] = props.get_extensionName_string_at(i)
  }
  let out = FixedArray::make(want.length(), "")
  let mut k = 0
  for i = 0; i < want.length(); i = i + 1 {
    if has_ext(avail, n, want[i]) {
      out[k] = want[i]
      k = k + 1
    }
  }
  (out, k)
}

///|
fn main {
  let na = @vk.VkAllocationCallbacks::null()
  let app = @vk.VkApplicationInfo::new()
  app.set_pApplicationName(@vk.cstr("Tycho Queries"))
  app.set_apiVersion((4210688 : UInt32))
  let (exts, next) = pick_instance_exts([
    "VK_KHR_surface",
    "VK_KHR_get_physical_device_properties2",
    "VK_KHR_external_memory_capabilities",
    "VK_KHR_external_fence_capabilities",
    "VK_KHR_external_semaphore_capabilities",
    "VK_KHR_device_group_creation",
    "VK_EXT_tooling_info",
    "VK_KHR_calibrated_timestamps",
    "VK_EXT_calibrated_timestamps",
    "VK_KHR_get_display_properties2",
    "VK_KHR_display",
  ])
  let ici = @vk.VkInstanceCreateInfo::new()
  ici.set_pApplicationInfo(app)
  ici.set_enabledLayerCount((1 : UInt32))
  ici.set_ppEnabledLayerNames(@vk.cstr_array(["VK_LAYER_KHRONOS_validation"]))
  ici.set_enabledExtensionCount(next.reinterpret_as_uint())
  ici.set_ppEnabledExtensionNames(@vk.cstr_array(exts))
  let inst_out = FixedArray::make(1, @vk.VkInstance::null())
  let ir = @vk.vkCreateInstance(ici, na, inst_out)
  if ir != 0 {
    println("[16-query] FAIL — vkCreateInstance=\{ir}")
    return
  }
  let inst = inst_out[0]
  let mut ifn = @vk.InstanceFn::load(inst)
  let iext = fn(name) { has_ext(exts, next, name) }
  let pc = FixedArray::make(1, (16 : UInt32))
  let pdevs = FixedArray::make(16, @vk.VkPhysicalDevice::null())
  let _ = (ifn.vkEnumeratePhysicalDevices)(inst, pc, pdevs)
  let phys = pdevs[0]
  let mut n = 0

  // device extension list gates the optional queries below
  let dec = FixedArray::make(1, (0 : UInt32))
  let _ = (ifn.vkEnumerateDeviceExtensionProperties)(
    phys,
    (0 : UInt64),
    dec,
    @vk.VkExtensionProperties::null(),
  )
  let dn = dec[0].reinterpret_as_int()
  let dexts = @vk.VkExtensionProperties::array(dn)
  let _ = (ifn.vkEnumerateDeviceExtensionProperties)(phys, (0 : UInt64), dec, dexts)
  let exts = FixedArray::make(dn, "")
  for i = 0; i < dn; i = i + 1 {
    exts[i] = dexts.get_extensionName_string_at(i)
  }
  n = n + 1

  // Physical-device commands contributed by *device* extensions only resolve
  // once a logical device with that extension exists. Create one enabling the
  // subset these queries need (only those the driver advertises).
  let want_dev = [
    "VK_EXT_sample_locations",
    "VK_KHR_cooperative_matrix",
    "VK_NV_cooperative_matrix",
    "VK_KHR_fragment_shading_rate",
    "VK_NV_framebuffer_mixed_samples",
  ]
  let den = FixedArray::make(want_dev.length(), "")
  let mut nden = 0
  for i = 0; i < want_dev.length(); i = i + 1 {
    if has_ext(exts, dn, want_dev[i]) {
      den[nden] = want_dev[i]
      nden = nden + 1
    }
  }
  let prio = FixedArray::make(1, (1.0 : Float))
  let qci = @vk.VkDeviceQueueCreateInfo::new()
  qci.set_queueFamilyIndex((0 : UInt32))
  qci.set_queueCount((1 : UInt32))
  qci.set_pQueuePriorities(prio)
  let dci = @vk.VkDeviceCreateInfo::new()
  dci.set_queueCreateInfoCount((1 : UInt32))
  dci.set_pQueueCreateInfos(qci)
  dci.set_enabledExtensionCount(nden.reinterpret_as_uint())
  dci.set_ppEnabledExtensionNames(@vk.cstr_array(den))
  let dev_out = FixedArray::make(1, @vk.VkDevice::null())
  let dr = (ifn.vkCreateDevice)(phys, dci, na, dev_out)
  if dr != 0 {
    println("[16-query] FAIL — vkCreateDevice=\{dr}")
    return
  }
  let dev = dev_out[0]
  let dfn = @vk.DeviceFn::load(dev)
  n = n + 1
  // InstanceFn is a snapshot: device-extension entry points were NULL when it
  // was first loaded. Reload now that a device with those extensions exists.
  ifn = @vk.InstanceFn::load(inst)
  let f1 = @vk.VkPhysicalDeviceFeatures::new()
  (ifn.vkGetPhysicalDeviceFeatures)(phys, f1)
  n = n + 1
  let f2 = @vk.VkPhysicalDeviceFeatures2::new()
  (ifn.vkGetPhysicalDeviceFeatures2)(phys, f2)
  n = n + 1
  let f2k = @vk.VkPhysicalDeviceFeatures2::new()
  let p2k = @vk.VkPhysicalDeviceProperties2::new()
  if iext("VK_KHR_get_physical_device_properties2") {
    (ifn.vkGetPhysicalDeviceFeatures2KHR)(phys, f2k)
    n = n + 1
    (ifn.vkGetPhysicalDeviceProperties2KHR)(phys, p2k)
    n = n + 1
  }

  let fmt = @vk.VK_FORMAT_R8G8B8A8_UNORM
  let fp = @vk.VkFormatProperties::new()
  (ifn.vkGetPhysicalDeviceFormatProperties)(phys, fmt, fp)
  n = n + 1
  let fp2 = @vk.VkFormatProperties2::new()
  (ifn.vkGetPhysicalDeviceFormatProperties2)(phys, fmt, fp2)
  n = n + 1
  let fp2k = @vk.VkFormatProperties2::new()
  if iext("VK_KHR_get_physical_device_properties2") {
    (ifn.vkGetPhysicalDeviceFormatProperties2KHR)(phys, fmt, fp2k)
    n = n + 1
  }
  if fp.get_optimalTilingFeatures() == 0 && fp2.get_formatProperties().get_optimalTilingFeatures() == 0 {
    println("[16-query] FAIL — R8G8B8A8_UNORM has no optimal tiling features")
    return
  }

  let ifp = @vk.VkImageFormatProperties::new()
  let ifr = (ifn.vkGetPhysicalDeviceImageFormatProperties)(
    phys,
    fmt,
    @vk.VK_IMAGE_TYPE_2D,
    @vk.VK_IMAGE_TILING_OPTIMAL,
    @vk.VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT | @vk.VK_IMAGE_USAGE_TRANSFER_SRC_BIT,
    (0 : UInt32),
    ifp,
  )
  n = n + 1
  let ifi2 = @vk.VkPhysicalDeviceImageFormatInfo2::new()
  ifi2.set_format(fmt)
  ifi2.set_type(@vk.VK_IMAGE_TYPE_2D)
  ifi2.set_tiling(@vk.VK_IMAGE_TILING_OPTIMAL)
  ifi2.set_usage(
    @vk.VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT | @vk.VK_IMAGE_USAGE_TRANSFER_SRC_BIT,
  )
  let ifp2 = @vk.VkImageFormatProperties2::new()
  let ifr2 = (ifn.vkGetPhysicalDeviceImageFormatProperties2)(phys, ifi2, ifp2)
  n = n + 1
  let ifp2k = @vk.VkImageFormatProperties2::new()
  if iext("VK_KHR_get_physical_device_properties2") {
    let _ = (ifn.vkGetPhysicalDeviceImageFormatProperties2KHR)(phys, ifi2, ifp2k)
    n = n + 1
  }
  if ifr != 0 || ifr2 != 0 {
    println("[16-query] FAIL — image format properties \{ifr}/\{ifr2}")
    return
  }
  if ifp.get_maxExtent().get_width() == 0 {
    println("[16-query] FAIL — zero max extent")
    return
  }

  let mp2 = @vk.VkPhysicalDeviceMemoryProperties2::new()
  (ifn.vkGetPhysicalDeviceMemoryProperties2)(phys, mp2)
  n = n + 1
  let mp2k = @vk.VkPhysicalDeviceMemoryProperties2::new()
  if iext("VK_KHR_get_physical_device_properties2") {
    (ifn.vkGetPhysicalDeviceMemoryProperties2KHR)(phys, mp2k)
    n = n + 1
  }
  if mp2.get_memoryProperties().get_memoryTypeCount() == 0 {
    println("[16-query] FAIL — no memory types")
    return
  }

  let qfc = FixedArray::make(1, (0 : UInt32))
  (ifn.vkGetPhysicalDeviceQueueFamilyProperties2)(phys, qfc, @vk.VkQueueFamilyProperties2::null())
  let qfp2 = @vk.VkQueueFamilyProperties2::array(qfc[0].reinterpret_as_int())
  (ifn.vkGetPhysicalDeviceQueueFamilyProperties2)(phys, qfc, qfp2)
  n = n + 1
  let qfc2 = FixedArray::make(1, (0 : UInt32))
  let mut qfp2k = @vk.VkQueueFamilyProperties2::array(0)
  if iext("VK_KHR_get_physical_device_properties2") {
    (ifn.vkGetPhysicalDeviceQueueFamilyProperties2KHR)(phys, qfc2, @vk.VkQueueFamilyProperties2::null())
    qfp2k = @vk.VkQueueFamilyProperties2::array(qfc2[0].reinterpret_as_int())
    (ifn.vkGetPhysicalDeviceQueueFamilyProperties2KHR)(phys, qfc2, qfp2k)
    n = n + 1
  }

  // sparse image format properties (count may legitimately be 0)
  let sfc = FixedArray::make(1, (8 : UInt32))
  let sfp = @vk.VkSparseImageFormatProperties::array(8)
  (ifn.vkGetPhysicalDeviceSparseImageFormatProperties)(
    phys,
    fmt,
    @vk.VK_IMAGE_TYPE_2D,
    @vk.VK_SAMPLE_COUNT_1_BIT,
    @vk.VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT,
    @vk.VK_IMAGE_TILING_OPTIMAL,
    sfc,
    sfp,
  )
  n = n + 1
  let sfi2 = @vk.VkPhysicalDeviceSparseImageFormatInfo2::new()
  sfi2.set_format(fmt)
  sfi2.set_type(@vk.VK_IMAGE_TYPE_2D)
  sfi2.set_samples(@vk.VK_SAMPLE_COUNT_1_BIT)
  sfi2.set_usage(@vk.VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT)
  sfi2.set_tiling(@vk.VK_IMAGE_TILING_OPTIMAL)
  let sfc2 = FixedArray::make(1, (8 : UInt32))
  let sfp2 = @vk.VkSparseImageFormatProperties2::array(8)
  (ifn.vkGetPhysicalDeviceSparseImageFormatProperties2)(phys, sfi2, sfc2, sfp2)
  n = n + 1
  let sfc2k = FixedArray::make(1, (8 : UInt32))
  let sfp2k = @vk.VkSparseImageFormatProperties2::array(8)
  if iext("VK_KHR_get_physical_device_properties2") {
    (ifn.vkGetPhysicalDeviceSparseImageFormatProperties2KHR)(phys, sfi2, sfc2k, sfp2k)
    n = n + 1
  }

  // --- external memory / fence / semaphore capabilities (fd on Linux) ---
  let ebi = @vk.VkPhysicalDeviceExternalBufferInfo::new()
  ebi.set_usage(@vk.VK_BUFFER_USAGE_TRANSFER_SRC_BIT)
  ebi.set_handleType(@vk.VK_EXTERNAL_MEMORY_HANDLE_TYPE_OPAQUE_FD_BIT)
  let ebp = @vk.VkExternalBufferProperties::new()
  (ifn.vkGetPhysicalDeviceExternalBufferProperties)(phys, ebi, ebp)
  n = n + 1
  let ebp_k = @vk.VkExternalBufferProperties::new()
  if iext("VK_KHR_external_memory_capabilities") {
    (ifn.vkGetPhysicalDeviceExternalBufferPropertiesKHR)(phys, ebi, ebp_k)
    n = n + 1
  }
  let efi = @vk.VkPhysicalDeviceExternalFenceInfo::new()
  efi.set_handleType(@vk.VK_EXTERNAL_FENCE_HANDLE_TYPE_OPAQUE_FD_BIT)
  let efp = @vk.VkExternalFenceProperties::new()
  (ifn.vkGetPhysicalDeviceExternalFenceProperties)(phys, efi, efp)
  n = n + 1
  let efp_k = @vk.VkExternalFenceProperties::new()
  if iext("VK_KHR_external_fence_capabilities") {
    (ifn.vkGetPhysicalDeviceExternalFencePropertiesKHR)(phys, efi, efp_k)
    n = n + 1
  }
  let esi = @vk.VkPhysicalDeviceExternalSemaphoreInfo::new()
  esi.set_handleType(@vk.VK_EXTERNAL_SEMAPHORE_HANDLE_TYPE_OPAQUE_FD_BIT)
  let esp = @vk.VkExternalSemaphoreProperties::new()
  (ifn.vkGetPhysicalDeviceExternalSemaphoreProperties)(phys, esi, esp)
  n = n + 1
  let esp_k = @vk.VkExternalSemaphoreProperties::new()
  if iext("VK_KHR_external_semaphore_capabilities") {
    (ifn.vkGetPhysicalDeviceExternalSemaphorePropertiesKHR)(phys, esi, esp_k)
    n = n + 1
  }

  // --- tool properties (validation layer reports itself here) ---
  let tc = FixedArray::make(1, (0 : UInt32))
  let _ = (ifn.vkGetPhysicalDeviceToolProperties)(phys, tc, @vk.VkPhysicalDeviceToolProperties::null())
  let tools = @vk.VkPhysicalDeviceToolProperties::array(tc[0].reinterpret_as_int())
  let _ = (ifn.vkGetPhysicalDeviceToolProperties)(phys, tc, tools)
  n = n + 1
  let tc2 = FixedArray::make(1, (0 : UInt32))
  let mut tools2 = @vk.VkPhysicalDeviceToolProperties::array(0)
  if iext("VK_EXT_tooling_info") {
    let _ = (ifn.vkGetPhysicalDeviceToolPropertiesEXT)(phys, tc2, @vk.VkPhysicalDeviceToolProperties::null())
    tools2 = @vk.VkPhysicalDeviceToolProperties::array(tc2[0].reinterpret_as_int())
    let _ = (ifn.vkGetPhysicalDeviceToolPropertiesEXT)(phys, tc2, tools2)
    n = n + 1
  }
  let mut saw_validation = false
  for i = 0; i < tc[0].reinterpret_as_int(); i = i + 1 {
    if tools.get_name_string_at(i).contains("Validation") {
      saw_validation = true
    }
  }

  // --- device groups / deprecated device layer enumeration ---
  let gc = FixedArray::make(1, (0 : UInt32))
  let _ = (ifn.vkEnumeratePhysicalDeviceGroups)(inst, gc, @vk.VkPhysicalDeviceGroupProperties::null())
  let groups = @vk.VkPhysicalDeviceGroupProperties::array(gc[0].reinterpret_as_int())
  let _ = (ifn.vkEnumeratePhysicalDeviceGroups)(inst, gc, groups)
  n = n + 1
  let gc2 = FixedArray::make(1, (0 : UInt32))
  let mut groups2 = @vk.VkPhysicalDeviceGroupProperties::array(0)
  if iext("VK_KHR_device_group_creation") {
    let _ = (ifn.vkEnumeratePhysicalDeviceGroupsKHR)(inst, gc2, @vk.VkPhysicalDeviceGroupProperties::null())
    groups2 = @vk.VkPhysicalDeviceGroupProperties::array(gc2[0].reinterpret_as_int())
    let _ = (ifn.vkEnumeratePhysicalDeviceGroupsKHR)(inst, gc2, groups2)
    n = n + 1
  }
  let lc = FixedArray::make(1, (0 : UInt32))
  let _ = (ifn.vkEnumerateDeviceLayerProperties)(phys, lc, @vk.VkLayerProperties::null())
  let layers = @vk.VkLayerProperties::array(lc[0].reinterpret_as_int())
  let _ = (ifn.vkEnumerateDeviceLayerProperties)(phys, lc, layers)
  n = n + 1

  // --- multisample properties (needs VK_EXT_sample_locations) ---
  if has_ext(exts, dn, "VK_EXT_sample_locations") {
    let ms = @vk.VkMultisamplePropertiesEXT::new()
    (ifn.vkGetPhysicalDeviceMultisamplePropertiesEXT)(phys, @vk.VK_SAMPLE_COUNT_1_BIT, ms)
    n = n + 1
  }

  // --- extension-gated queries ---
  if iext("VK_KHR_calibrated_timestamps") {
    let tdc = FixedArray::make(1, (0 : UInt32))
    let _ = (ifn.vkGetPhysicalDeviceCalibrateableTimeDomainsKHR)(phys, tdc, FixedArray::make(0, (0 : UInt32)))
    let tds = FixedArray::make(tdc[0].reinterpret_as_int(), (0 : UInt32))
    let _ = (ifn.vkGetPhysicalDeviceCalibrateableTimeDomainsKHR)(phys, tdc, tds)
    n = n + 1
  }
  if iext("VK_EXT_calibrated_timestamps") {
    let tdc2 = FixedArray::make(1, (0 : UInt32))
    let _ = (ifn.vkGetPhysicalDeviceCalibrateableTimeDomainsEXT)(phys, tdc2, FixedArray::make(0, (0 : UInt32)))
    let tds2 = FixedArray::make(tdc2[0].reinterpret_as_int(), (0 : UInt32))
    let _ = (ifn.vkGetPhysicalDeviceCalibrateableTimeDomainsEXT)(phys, tdc2, tds2)
    n = n + 1
  }
  // vkGetPhysicalDeviceDescriptorSizeEXT is skipped: lavapipe advertises
  // VK_EXT_descriptor_buffer but never resolves this instance-level entry point
  // (even after creating a device with the extension and reloading InstanceFn).
  // It belongs to a future descriptor-buffer batch that probes it device-side.
  if has_ext(exts, dn, "VK_KHR_cooperative_matrix") {
    let cmc = FixedArray::make(1, (0 : UInt32))
    let _ = (ifn.vkGetPhysicalDeviceCooperativeMatrixPropertiesKHR)(phys, cmc, @vk.VkCooperativeMatrixPropertiesKHR::null())
    let cms = @vk.VkCooperativeMatrixPropertiesKHR::array(cmc[0].reinterpret_as_int())
    let _ = (ifn.vkGetPhysicalDeviceCooperativeMatrixPropertiesKHR)(phys, cmc, cms)
    n = n + 1
  }
  if has_ext(exts, dn, "VK_NV_cooperative_matrix") {
    let cmc = FixedArray::make(1, (0 : UInt32))
    let _ = (ifn.vkGetPhysicalDeviceCooperativeMatrixPropertiesNV)(phys, cmc, @vk.VkCooperativeMatrixPropertiesNV::null())
    let cms = @vk.VkCooperativeMatrixPropertiesNV::array(cmc[0].reinterpret_as_int())
    let _ = (ifn.vkGetPhysicalDeviceCooperativeMatrixPropertiesNV)(phys, cmc, cms)
    n = n + 1
  }
  if has_ext(exts, dn, "VK_KHR_fragment_shading_rate") {
    let fsc = FixedArray::make(1, (0 : UInt32))
    let _ = (ifn.vkGetPhysicalDeviceFragmentShadingRatesKHR)(phys, fsc, @vk.VkPhysicalDeviceFragmentShadingRateKHR::null())
    let fsr = @vk.VkPhysicalDeviceFragmentShadingRateKHR::array(fsc[0].reinterpret_as_int())
    let _ = (ifn.vkGetPhysicalDeviceFragmentShadingRatesKHR)(phys, fsc, fsr)
    n = n + 1
  }
  if has_ext(exts, dn, "VK_NV_framebuffer_mixed_samples") {
    let mc = FixedArray::make(1, (0 : UInt32))
    let _ = (ifn.vkGetPhysicalDeviceSupportedFramebufferMixedSamplesCombinationsNV)(phys, mc, @vk.VkFramebufferMixedSamplesCombinationNV::null())
    let ms2 = @vk.VkFramebufferMixedSamplesCombinationNV::array(mc[0].reinterpret_as_int())
    let _ = (ifn.vkGetPhysicalDeviceSupportedFramebufferMixedSamplesCombinationsNV)(phys, mc, ms2)
    n = n + 1
  }
  if iext("VK_KHR_display") {
    let dc = FixedArray::make(1, (0 : UInt32))
    let _ = (ifn.vkGetPhysicalDeviceDisplayPropertiesKHR)(phys, dc, @vk.VkDisplayPropertiesKHR::null())
    let dps = @vk.VkDisplayPropertiesKHR::array(dc[0].reinterpret_as_int())
    let _ = (ifn.vkGetPhysicalDeviceDisplayPropertiesKHR)(phys, dc, dps)
    n = n + 1
    let dc2 = FixedArray::make(1, (0 : UInt32))
    let mut dps2 = @vk.VkDisplayProperties2KHR::array(0)
    if iext("VK_KHR_get_display_properties2") {
      let _ = (ifn.vkGetPhysicalDeviceDisplayProperties2KHR)(phys, dc2, @vk.VkDisplayProperties2KHR::null())
      dps2 = @vk.VkDisplayProperties2KHR::array(dc2[0].reinterpret_as_int())
      let _ = (ifn.vkGetPhysicalDeviceDisplayProperties2KHR)(phys, dc2, dps2)
      n = n + 1
    }
    let plc = FixedArray::make(1, (0 : UInt32))
    let _ = (ifn.vkGetPhysicalDeviceDisplayPlanePropertiesKHR)(phys, plc, @vk.VkDisplayPlanePropertiesKHR::null())
    let plps = @vk.VkDisplayPlanePropertiesKHR::array(plc[0].reinterpret_as_int())
    let _ = (ifn.vkGetPhysicalDeviceDisplayPlanePropertiesKHR)(phys, plc, plps)
    n = n + 1
    let plc2 = FixedArray::make(1, (0 : UInt32))
    let mut plps2 = @vk.VkDisplayPlaneProperties2KHR::array(0)
    if iext("VK_KHR_get_display_properties2") {
      let _ = (ifn.vkGetPhysicalDeviceDisplayPlaneProperties2KHR)(phys, plc2, @vk.VkDisplayPlaneProperties2KHR::null())
      plps2 = @vk.VkDisplayPlaneProperties2KHR::array(plc2[0].reinterpret_as_int())
      let _ = (ifn.vkGetPhysicalDeviceDisplayPlaneProperties2KHR)(phys, plc2, plps2)
      n = n + 1
    }
  }

  (dfn.vkDestroyDevice)(dev, na)
  let _ = (ifn.vkDestroyInstance)(inst, na)
  println("[16-query] commands exercised=\{n} tools=\{tc[0]} groupCount=\{gc[0]}")
  // 18 = the unconditional core queries; optional ones are extension-gated and
  // differ per driver (lavapipe 29, NVIDIA 38 at time of writing).
  let core_ok = n >= 18 &&
    saw_validation &&
    qfc[0] > 0 &&
    gc[0] > 0 &&
    mp2.get_memoryProperties().get_memoryTypeCount() > 0
  if core_ok {
    println("[16-query] OK — \{n} query commands, validation layer visible via tool properties")
  } else {
    println("[16-query] FAIL — n=\{n} saw_validation=\{saw_validation} queues=\{qfc[0]} groups=\{gc[0]}")
  }
}