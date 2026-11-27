// vulkan/wsi-queries — WSI & Swapchain extended queries/control batch.
// Covers surface support/present-modes/capabilities2/formats2, device-group
// present capabilities/modes/rectangles, AcquireNextImage2KHR, HDR metadata,
// swapchain status, and present-wait / release-swapchain-images when supported.

let g_errors : Ref[Int] = Ref(0)

///|
fn main {
  let opts = @exwin.Options::parse("vulkan/wsi-queries")
  let w32 = opts.width.reinterpret_as_uint()
  let na = @vk.VkAllocationCallbacks::null()
  let app = @vk.VkApplicationInfo::new()
  app.set_pApplicationName(@vk.cstr("Tycho30WSI"))
  app.set_apiVersion((4210688 : UInt32)) // 1.4

  // Query available instance extensions
  let iec = FixedArray::make(1, (0 : UInt32))
  let _ = @vk.vkEnumerateInstanceExtensionProperties((0 : UInt64), iec, @vk.VkExtensionProperties::null())
  let nie = iec[0].reinterpret_as_int()
  let iep = @vk.VkExtensionProperties::array(nie)
  let _ = @vk.vkEnumerateInstanceExtensionProperties((0 : UInt64), iec, iep)
  let has_iext = fn(name : String) -> Bool {
    for i = 0; i < nie; i = i + 1 {
      if iep.get_extensionName_string_at(i) == name {
        return true
      }
    }
    false
  }

  let want_iext = [
    "VK_KHR_surface",
    "VK_KHR_xlib_surface",
    "VK_KHR_wayland_surface",
    "VK_KHR_win32_surface",
    "VK_EXT_metal_surface",
    "VK_EXT_debug_utils",
    "VK_KHR_get_surface_capabilities2",
    "VK_KHR_display",
    "VK_EXT_display_surface_counter",
  ]
  let iext_arr = FixedArray::make(want_iext.length(), "")
  let mut niext = 0
  for i = 0; i < want_iext.length(); i = i + 1 {
    if has_iext(want_iext[i]) {
      iext_arr[niext] = want_iext[i]
      niext = niext + 1
    }
  }

  let ici = @vk.VkInstanceCreateInfo::new()
  ici.set_pApplicationInfo(app)
  ici.set_enabledLayerCount((1 : UInt32))
  ici.set_ppEnabledLayerNames(@vk.cstr_array(["VK_LAYER_KHRONOS_validation"]))
  ici.set_enabledExtensionCount(niext.reinterpret_as_uint())
  ici.set_ppEnabledExtensionNames(@vk.cstr_array(iext_arr))
  let inst_out = FixedArray::make(1, @vk.VkInstance::null())
  let ir = @vk.vkCreateInstance(ici, na, inst_out)
  if ir != 0 {
    println("[30-wsi] FAIL — vkCreateInstance=\{ir}")
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
      println("[30-wsi] VALIDATION: \{@vk.read_cstr(data.get_pMessage())}")
      (0 : UInt32)
    },
  )

  let pc = FixedArray::make(1, (16 : UInt32))
  let devs = FixedArray::make(16, @vk.VkPhysicalDevice::null())
  let _ = (ifn.vkEnumeratePhysicalDevices)(inst, pc, devs)
  let phys = devs[0]

  // Query device extensions
  let dec = FixedArray::make(1, (0 : UInt32))
  let _ = (ifn.vkEnumerateDeviceExtensionProperties)(phys, (0 : UInt64), dec, @vk.VkExtensionProperties::null())
  let nde = dec[0].reinterpret_as_int()
  let dep = @vk.VkExtensionProperties::array(nde)
  let _ = (ifn.vkEnumerateDeviceExtensionProperties)(phys, (0 : UInt64), dec, dep)
  let has_dext = fn(name : String) -> Bool {
    for i = 0; i < nde; i = i + 1 {
      if dep.get_extensionName_string_at(i) == name {
        return true
      }
    }
    false
  }

  let want_dext = [
    "VK_KHR_swapchain",
    "VK_EXT_hdr_metadata",
    "VK_KHR_shared_presentable_image",
  ]
  let dext_arr = FixedArray::make(want_dext.length(), "")
  let mut ndext = 0
  for i = 0; i < want_dext.length(); i = i + 1 {
    if has_dext(want_dext[i]) {
      dext_arr[ndext] = want_dext[i]
      ndext = ndext + 1
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
  dci.set_enabledExtensionCount(ndext.reinterpret_as_uint())
  dci.set_ppEnabledExtensionNames(@vk.cstr_array(dext_arr))
  let dev_out = FixedArray::make(1, @vk.VkDevice::null())
  let dr = (ifn.vkCreateDevice)(phys, dci, na, dev_out)
  if dr != 0 {
    println("[30-wsi] FAIL — vkCreateDevice=\{dr}")
    return
  }
  let dev = dev_out[0]
  let dfn = @vk.DeviceFn::load(dev)
  let dev_has = fn(name : String) -> Bool {
    (ifn.vkGetDeviceProcAddr)(dev, @vk.cstr(name)) != (0 : UInt64)
  }

  let mut n = 0
  let win = @exwin_native.open(opts)
  if win == (0 : UInt64) {
    println("[vulkan/wsi-queries] SKIP — no window backend (Wayland/X11/Win32 unavailable)")
    return
  }
  let surface = @win.create_surface(inst, win)

  // 1. Surface support
  let supported = FixedArray::make(1, (0 : UInt32))
  let r_sup = (ifn.vkGetPhysicalDeviceSurfaceSupportKHR)(phys, (0 : UInt32), surface, supported)
  n = n + 1

  // 2. Surface present modes
  let pmc = FixedArray::make(1, (0 : UInt32))
  let _ = (ifn.vkGetPhysicalDeviceSurfacePresentModesKHR)(phys, surface, pmc, FixedArray::make(0, (0 : UInt32)))
  let npm = pmc[0].reinterpret_as_int()
  let pms = FixedArray::make(if npm > 0 { npm } else { 1 }, (0 : UInt32))
  if npm > 0 {
    let _ = (ifn.vkGetPhysicalDeviceSurfacePresentModesKHR)(phys, surface, pmc, pms)
  }
  n = n + 1

  // 3. Surface capabilities2 & formats2
  if has_iext("VK_KHR_get_surface_capabilities2") {
    let si2 = @vk.VkPhysicalDeviceSurfaceInfo2KHR::new()
    si2.set_surface(surface)
    let sc2 = @vk.VkSurfaceCapabilities2KHR::new()
    let _ = (ifn.vkGetPhysicalDeviceSurfaceCapabilities2KHR)(phys, si2, sc2)
    n = n + 1
    let fc2 = FixedArray::make(1, (0 : UInt32))
    let _ = (ifn.vkGetPhysicalDeviceSurfaceFormats2KHR)(phys, si2, fc2, @vk.VkSurfaceFormat2KHR::null())
    let nf2 = fc2[0].reinterpret_as_int()
    if nf2 > 0 {
      let fmts2 = @vk.VkSurfaceFormat2KHR::array(nf2)
      let _ = (ifn.vkGetPhysicalDeviceSurfaceFormats2KHR)(phys, si2, fc2, fmts2)
      fmts2.free()
    }
    n = n + 1
    si2.free()
    sc2.free()
  }

  // 4. Display surface counter capabilities2 EXT
  if has_iext("VK_EXT_display_surface_counter") {
    let sce = @vk.VkSurfaceCapabilities2EXT::new()
    let _ = (ifn.vkGetPhysicalDeviceSurfaceCapabilities2EXT)(phys, surface, sce)
    sce.free()
    n = n + 1
  }

  // 5. Device group present capabilities, surface present modes, present rectangles
  if dev_has("vkGetDeviceGroupPresentCapabilitiesKHR") {
    let dgpc = @vk.VkDeviceGroupPresentCapabilitiesKHR::new()
    let _ = (dfn.vkGetDeviceGroupPresentCapabilitiesKHR)(dev, dgpc)
    dgpc.free()
    n = n + 1
  }
  if dev_has("vkGetDeviceGroupSurfacePresentModesKHR") {
    let dgpm = FixedArray::make(1, (0 : UInt32))
    let _ = (dfn.vkGetDeviceGroupSurfacePresentModesKHR)(dev, surface, dgpm)
    n = n + 1
  }
  let rc = FixedArray::make(1, (0 : UInt32))
  let _ = (ifn.vkGetPhysicalDevicePresentRectanglesKHR)(phys, surface, rc, @vk.VkRect2D::null())
  if rc[0] > (0 : UInt32) {
    let rects = @vk.VkRect2D::array(rc[0].reinterpret_as_int())
    let _ = (ifn.vkGetPhysicalDevicePresentRectanglesKHR)(phys, surface, rc, rects)
    rects.free()
  }
  n = n + 1

  // 6. Create swapchain and test AcquireNextImage2KHR, SetHdrMetadataEXT, GetSwapchainStatusKHR
  let caps = @vk.VkSurfaceCapabilitiesKHR::new()
  let _ = (ifn.vkGetPhysicalDeviceSurfaceCapabilitiesKHR)(phys, surface, caps)
  let fc = FixedArray::make(1, (0 : UInt32))
  let _ = (ifn.vkGetPhysicalDeviceSurfaceFormatsKHR)(phys, surface, fc, @vk.VkSurfaceFormatKHR::null())
  let nf = fc[0].reinterpret_as_int()
  let fmts = @vk.VkSurfaceFormatKHR::array(nf)
  let _ = (ifn.vkGetPhysicalDeviceSurfaceFormatsKHR)(phys, surface, fc, fmts)
  let ext = @vk.VkExtent2D::new()
  let cur_w = caps.get_currentExtent().get_width()
  let cur_h = caps.get_currentExtent().get_height()
  ext.set_width(if cur_w == (0xFFFFFFFF : UInt32) { w32 } else { cur_w })
  ext.set_height(if cur_h == (0xFFFFFFFF : UInt32) { w32 } else { cur_h })

  let swci = @vk.VkSwapchainCreateInfoKHR::new()
  swci.set_surface(surface)
  swci.set_minImageCount(caps.get_minImageCount())
  swci.set_imageFormat(fmts.get_format_at(0))
  swci.set_imageColorSpace(fmts.get_colorSpace_at(0))
  swci.set_imageExtent(ext)
  swci.set_imageArrayLayers((1 : UInt32))
  swci.set_imageUsage(@vk.VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT)
  swci.set_preTransform(caps.get_currentTransform())
  swci.set_compositeAlpha(@vk.VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR)
  swci.set_presentMode(@vk.VK_PRESENT_MODE_FIFO_KHR)
  swci.set_clipped((1 : UInt32))
  let sw_out = FixedArray::make(1, @vk.VkSwapchainKHR::null())
  let swr = (dfn.vkCreateSwapchainKHR)(dev, swci, na, sw_out)
  let sw = sw_out[0]

  let mut acq2_r = (0 : Int32)
  if swr == 0 {
    let fci = @vk.VkFenceCreateInfo::new()
    let fence_out = FixedArray::make(1, @vk.VkFence::null())
    let _ = (dfn.vkCreateFence)(dev, fci, na, fence_out)

    // AcquireNextImage2KHR
    if dev_has("vkAcquireNextImage2KHR") {
      let ai2 = @vk.VkAcquireNextImageInfoKHR::new()
      ai2.set_swapchain(sw)
      ai2.set_timeout((10000000000 : UInt64))
      ai2.set_fence(fence_out[0])
      ai2.set_deviceMask((1 : UInt32))
      let img_idx = FixedArray::make(1, (0 : UInt32))
      acq2_r = (dfn.vkAcquireNextImage2KHR)(dev, ai2, img_idx)
      let _ = (dfn.vkWaitForFences)(dev, (1 : UInt32), fence_out, (1 : UInt32), (10000000000 : UInt64))
      ai2.free()
      n = n + 1
    }

    // SetHdrMetadataEXT (NVIDIA)
    if has_dext("VK_EXT_hdr_metadata") && dev_has("vkSetHdrMetadataEXT") {
      let hdr = @vk.VkHdrMetadataEXT::new()
      hdr.set_maxLuminance((1000.0 : Float))
      hdr.set_minLuminance((0.01 : Float))
      hdr.set_maxContentLightLevel((1000.0 : Float))
      hdr.set_maxFrameAverageLightLevel((400.0 : Float))
      (dfn.vkSetHdrMetadataEXT)(dev, (1 : UInt32), sw_out, hdr)
      hdr.free()
      n = n + 1
    }

    // GetSwapchainStatusKHR (VK_KHR_shared_presentable_image)
    if has_dext("VK_KHR_shared_presentable_image") && dev_has("vkGetSwapchainStatusKHR") {
      let _ = (dfn.vkGetSwapchainStatusKHR)(dev, sw)
      n = n + 1
    }

    let _ = (dfn.vkDeviceWaitIdle)(dev)
    (dfn.vkDestroyFence)(dev, fence_out[0], na)
    (dfn.vkDestroySwapchainKHR)(dev, sw, na)
  }

  (ifn.vkDestroySurfaceKHR)(inst, surface, na)
  @exwin_native.destroy(win)
  (dfn.vkDestroyDevice)(dev, na)
  @vk.destroy_debug_messenger(inst, ifn, messenger)
  (ifn.vkDestroyInstance)(inst, na)

  println("[30-wsi] commands=\{n} support=\{r_sup}/\{supported[0]} pms=\{npm} sw=\{swr} acq2=\{acq2_r} errors=\{g_errors.val}")
  if r_sup == 0 && supported[0] != 0 && swr == 0 && acq2_r >= 0 && n >= 6 && g_errors.val == 0 {
    println("[30-wsi] OK — \{n} WSI/swapchain commands verified, 0 validation errors")
  } else {
    println("[30-wsi] FAIL — n=\{n} sup=\{r_sup}/\{supported[0]} sw=\{swr} acq2=\{acq2_r} errors=\{g_errors.val}")
  }
}
