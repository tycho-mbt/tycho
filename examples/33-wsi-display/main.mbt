// Example 33 — Extended WSI, Swapchain Maintenance1, Present Wait/Timing,
// Display/DRM properties, and NVIDIA Low Latency 1/2 commands.

let g_errors : Ref[Int] = Ref(0)

///|
fn main {
  let na = @vk.VkAllocationCallbacks::null()
  let app = @vk.VkApplicationInfo::new()
  app.set_pApplicationName(@vk.cstr("Tycho33WSIDisplay"))
  app.set_apiVersion((4210688 : UInt32)) // 1.4

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
    "VK_EXT_debug_utils",
    "VK_KHR_get_surface_capabilities2",
    "VK_KHR_surface_maintenance1",
    "VK_KHR_display",
    "VK_KHR_get_display_properties2",
    "VK_EXT_direct_mode_display",
    "VK_EXT_acquire_drm_display",
    "VK_EXT_display_surface_counter",
    "VK_EXT_surface_maintenance1",
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
    println("[33-wsi] FAIL — vkCreateInstance=\{ir}")
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
      println("[33-wsi] VALIDATION: \{@vk.read_cstr(data.get_pMessage())}")
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
  let has_dext = fn(name : String) -> Bool {
    for i = 0; i < nde; i = i + 1 {
      if dep.get_extensionName_string_at(i) == name {
        return true
      }
    }
    false
  }

  let swm_q = @vk.VkPhysicalDeviceSwapchainMaintenance1FeaturesKHR::new()
  let pw_q = @vk.VkPhysicalDevicePresentWaitFeaturesKHR::new()
  let pw2_q = @vk.VkPhysicalDevicePresentWait2FeaturesKHR::new()
  let pt_q = @vk.VkPhysicalDevicePresentTimingFeaturesEXT::new()
  let f12_q = @vk.VkPhysicalDeviceVulkan12Features::new()
  let f2_q = @vk.VkPhysicalDeviceFeatures2::new()
  f2_q.set_pNext(swm_q.as_ptr())
  swm_q.set_pNext(pw_q.as_ptr())
  pw_q.set_pNext(pw2_q.as_ptr())
  pw2_q.set_pNext(pt_q.as_ptr())
  pt_q.set_pNext(f12_q.as_ptr())
  (ifn.vkGetPhysicalDeviceFeatures2)(phys, f2_q)

  let swm_en = @vk.VkPhysicalDeviceSwapchainMaintenance1FeaturesKHR::new()
  swm_en.set_swapchainMaintenance1(swm_q.get_swapchainMaintenance1())
  let pw_en = @vk.VkPhysicalDevicePresentWaitFeaturesKHR::new()
  pw_en.set_presentWait(pw_q.get_presentWait())
  let pw2_en = @vk.VkPhysicalDevicePresentWait2FeaturesKHR::new()
  pw2_en.set_presentWait2(pw2_q.get_presentWait2())
  let pt_en = @vk.VkPhysicalDevicePresentTimingFeaturesEXT::new()
  pt_en.set_presentTiming(pt_q.get_presentTiming())
  let f12_en = @vk.VkPhysicalDeviceVulkan12Features::new()
  f12_en.set_timelineSemaphore(f12_q.get_timelineSemaphore())

  swm_en.set_pNext(pw_en.as_ptr())
  pw_en.set_pNext(pw2_en.as_ptr())
  pw2_en.set_pNext(pt_en.as_ptr())
  pt_en.set_pNext(f12_en.as_ptr())

  let want_dext = [
    "VK_KHR_swapchain",
    "VK_KHR_swapchain_maintenance1",
    "VK_EXT_swapchain_maintenance1",
    "VK_KHR_present_id",
    "VK_KHR_present_wait",
    "VK_KHR_present_id2",
    "VK_KHR_present_wait2",
    "VK_KHR_calibrated_timestamps",
    "VK_EXT_present_timing",
    "VK_NV_low_latency2",
    "VK_EXT_display_control",
  ]
  let dext_arr = FixedArray::make(want_dext.length(), "")
  let mut ndext = 0
  for i = 0; i < want_dext.length(); i = i + 1 {
    if want_dext[i] == "VK_EXT_swapchain_maintenance1" && has_dext("VK_KHR_swapchain_maintenance1") {
      // prefer KHR; we'll test EXT if KHR not used, or test proc addr cleanly
      continue
    }
    if want_dext[i] == "VK_EXT_display_control" && !has_iext("VK_EXT_display_surface_counter") {
      continue
    }
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
  dci.set_pNext(swm_en.as_ptr())
  dci.set_queueCreateInfoCount((1 : UInt32))
  dci.set_pQueueCreateInfos(qci)
  dci.set_enabledExtensionCount(ndext.reinterpret_as_uint())
  dci.set_ppEnabledExtensionNames(@vk.cstr_array(dext_arr))
  let dev_out = FixedArray::make(1, @vk.VkDevice::null())
  let dr = (ifn.vkCreateDevice)(phys, dci, na, dev_out)
  if dr != 0 {
    println("[33-wsi] FAIL — vkCreateDevice=\{dr}")
    return
  }
  let dev = dev_out[0]
  let dfn = @vk.DeviceFn::load(dev)
  let queue_out = FixedArray::make(1, @vk.VkQueue::null())
  (dfn.vkGetDeviceQueue)(dev, (0 : UInt32), (0 : UInt32), queue_out)
  let queue = queue_out[0]
  let dev_has = fn(name : String) -> Bool {
    (ifn.vkGetDeviceProcAddr)(dev, @vk.cstr(name)) != (0 : UInt64)
  }
  let inst_has = fn(name : String) -> Bool {
    @vk.vkGetInstanceProcAddr(inst, @vk.cstr(name)) != (0 : UInt64)
  }

  let mut n = 0
  // Coverage evidence: `avail` counts the extension-gated groups this driver can
  // verify, `ran` counts the groups that actually executed a command. Judging on
  // n/errors alone lets a driver that lacks every extension report OK after
  // verifying nothing (vacuous pass).
  let mut avail = 0
  let mut ran = 0
  let _ = @win.initialize()
  let win = @win.create((256 : Int32), (256 : Int32), "Tycho33WSI")
  let surface = @win.create_surface(inst, win)

  // Guard platform presentation calls that require a live Xlib/XCB/Wayland display handle
  let run_xcb = false
  if run_xcb && inst_has("vkCreateXcbSurfaceKHR") {
    let xci = @vk.VkXcbSurfaceCreateInfoKHR::from_ptr((0 : UInt64))
    let so = FixedArray::make(1, @vk.VkSurfaceKHR::null())
    let _ = (ifn.vkCreateXcbSurfaceKHR)(inst, xci, na, so)
    let _ = (ifn.vkGetPhysicalDeviceXcbPresentationSupportKHR)(phys, (0 : UInt32), (0 : UInt64), (0 : UInt32))
    let _ = (ifn.vkGetPhysicalDeviceXlibPresentationSupportKHR)(phys, (0 : UInt32), (0 : UInt64), (0 : UInt64))
  }
  let run_wayland = false
  if run_wayland && inst_has("vkCreateWaylandSurfaceKHR") {
    let wci = @vk.VkWaylandSurfaceCreateInfoKHR::from_ptr((0 : UInt64))
    let so = FixedArray::make(1, @vk.VkSurfaceKHR::null())
    let _ = (ifn.vkCreateWaylandSurfaceKHR)(inst, wci, na, so)
    let _ = (ifn.vkGetPhysicalDeviceWaylandPresentationSupportKHR)(phys, (0 : UInt32), (0 : UInt64))
  }

  // 2. Display / Plane / Mode / DRM queries
  let mut first_disp = @vk.VkDisplayKHR::null()
  if has_iext("VK_KHR_display") {
    let dpc = FixedArray::make(1, (0 : UInt32))
    let _ = (ifn.vkGetPhysicalDeviceDisplayPropertiesKHR)(phys, dpc, @vk.VkDisplayPropertiesKHR::null())
    if dpc[0] > (0 : UInt32) {
      let dps = @vk.VkDisplayPropertiesKHR::array(dpc[0].reinterpret_as_int())
      let _ = (ifn.vkGetPhysicalDeviceDisplayPropertiesKHR)(phys, dpc, dps)
      first_disp = dps.get_display_at(0)
      dps.free()
    }
    let pl_cnt = FixedArray::make(1, (0 : UInt32))
    let _ = (ifn.vkGetPhysicalDeviceDisplayPlanePropertiesKHR)(phys, pl_cnt, @vk.VkDisplayPlanePropertiesKHR::null())
    if pl_cnt[0] > (0 : UInt32) {
      let sd_cnt = FixedArray::make(1, (0 : UInt32))
      let _ = (ifn.vkGetDisplayPlaneSupportedDisplaysKHR)(phys, (0 : UInt32), sd_cnt, FixedArray::make(0, @vk.VkDisplayKHR::null()))
      if sd_cnt[0] > (0 : UInt32) {
        let sds = FixedArray::make(sd_cnt[0].reinterpret_as_int(), @vk.VkDisplayKHR::null())
        let _ = (ifn.vkGetDisplayPlaneSupportedDisplaysKHR)(phys, (0 : UInt32), sd_cnt, sds)
        if first_disp.as_ptr() == (0 : UInt64) {
          first_disp = sds[0]
        }
      }
      n = n + 1
    }
    if first_disp.as_ptr() != (0 : UInt64) {
      let mc = FixedArray::make(1, (0 : UInt32))
      let _ = (ifn.vkGetDisplayModePropertiesKHR)(phys, first_disp, mc, @vk.VkDisplayModePropertiesKHR::null())
      let mut first_mode = @vk.VkDisplayModeKHR::null()
      if mc[0] > (0 : UInt32) {
        let mps = @vk.VkDisplayModePropertiesKHR::array(mc[0].reinterpret_as_int())
        let _ = (ifn.vkGetDisplayModePropertiesKHR)(phys, first_disp, mc, mps)
        first_mode = mps.get_displayMode_at(0)
        mps.free()
      }
      n = n + 1
      if has_iext("VK_KHR_get_display_properties2") {
        let mc2 = FixedArray::make(1, (0 : UInt32))
        let _ = (ifn.vkGetDisplayModeProperties2KHR)(phys, first_disp, mc2, @vk.VkDisplayModeProperties2KHR::null())
        if mc2[0] > (0 : UInt32) {
          let mps2 = @vk.VkDisplayModeProperties2KHR::array(mc2[0].reinterpret_as_int())
          let _ = (ifn.vkGetDisplayModeProperties2KHR)(phys, first_disp, mc2, mps2)
          mps2.free()
        }
        n = n + 1
      }
      if first_mode.as_ptr() != (0 : UInt64) {
        let dpcaps = @vk.VkDisplayPlaneCapabilitiesKHR::new()
        let _ = (ifn.vkGetDisplayPlaneCapabilitiesKHR)(phys, first_mode, (0 : UInt32), dpcaps)
        dpcaps.free()
        n = n + 1
        if has_iext("VK_KHR_get_display_properties2") {
          let dpi2 = @vk.VkDisplayPlaneInfo2KHR::new()
          dpi2.set_mode(first_mode)
          dpi2.set_planeIndex((0 : UInt32))
          let dpcaps2 = @vk.VkDisplayPlaneCapabilities2KHR::new()
          let _ = (ifn.vkGetDisplayPlaneCapabilities2KHR)(phys, dpi2, dpcaps2)
          dpi2.free()
          dpcaps2.free()
          n = n + 1
        }
      }
    }
    let can_create_mode = false
    if can_create_mode && first_disp.as_ptr() != (0 : UInt64) {
      let dmci = @vk.VkDisplayModeCreateInfoKHR::new()
      let dmo = FixedArray::make(1, @vk.VkDisplayModeKHR::null())
      let _ = (ifn.vkCreateDisplayModeKHR)(phys, first_disp, dmci, na, dmo)
      let dsci = @vk.VkDisplaySurfaceCreateInfoKHR::new()
      let dso = FixedArray::make(1, @vk.VkSurfaceKHR::null())
      let _ = (ifn.vkCreateDisplayPlaneSurfaceKHR)(inst, dsci, na, dso)
      dmci.free()
      dsci.free()
    }
  }
  let has_drm_fd = false
  if has_drm_fd && has_iext("VK_EXT_acquire_drm_display") {
    let do_drm = FixedArray::make(1, @vk.VkDisplayKHR::null())
    let _ = (ifn.vkGetDrmDisplayEXT)(phys, (0 : Int32), (0 : UInt32), do_drm)
    let _ = (ifn.vkAcquireDrmDisplayEXT)(phys, (0 : Int32), do_drm[0])
    if has_iext("VK_EXT_direct_mode_display") {
      let _ = (ifn.vkReleaseDisplayEXT)(phys, do_drm[0])
    }
  }

  // 3. Swapchain creation for Maintenance1, PresentTiming, LowLatency2, DisplayControl
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
  ext.set_width(if cur_w == (0xFFFFFFFF : UInt32) { (256 : UInt32) } else { cur_w })
  ext.set_height(if cur_h == (0xFFFFFFFF : UInt32) { (256 : UInt32) } else { cur_h })

  let swci = @vk.VkSwapchainCreateInfoKHR::new()
  if has_dext("VK_EXT_present_timing") && pt_q.get_presentTiming() != 0 {
    swci.set_flags(@vk.VK_SWAPCHAIN_CREATE_PRESENT_TIMING_BIT_EXT)
  }
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

  if swr == 0 {
    // 3a. ReleaseSwapchainImagesKHR (when swapchainMaintenance1 is enabled)
    let before_3a = n
    let swm_gate = has_dext("VK_KHR_swapchain_maintenance1") && swm_q.get_swapchainMaintenance1() != 0 && dev_has("vkReleaseSwapchainImagesKHR")
    if swm_gate {
      avail = avail + 1
      let fci = @vk.VkFenceCreateInfo::new()
      let fence_out = FixedArray::make(1, @vk.VkFence::null())
      let _ = (dfn.vkCreateFence)(dev, fci, na, fence_out)
      let idx = FixedArray::make(1, (0 : UInt32))
      let ar = (dfn.vkAcquireNextImageKHR)(dev, sw, (10000000000 : UInt64), @vk.VkSemaphore::null(), fence_out[0], idx)
      let _ = (dfn.vkWaitForFences)(dev, (1 : UInt32), fence_out, (1 : UInt32), (10000000000 : UInt64))
      if ar == 0 || ar == 1000001003 {
        let rsi = @vk.VkReleaseSwapchainImagesInfoKHR::new()
        rsi.set_swapchain(sw)
        rsi.set_imageIndexCount((1 : UInt32))
        rsi.set_pImageIndices(idx)
        let _ = (dfn.vkReleaseSwapchainImagesKHR)(dev, rsi)
        rsi.free()
        n = n + 1
      }
      (dfn.vkDestroyFence)(dev, fence_out[0], na)
      fci.free()
    }
    if swm_gate && n > before_3a {
      ran = ran + 1
    }
    let test_ext_release = false
    if test_ext_release && dev_has("vkReleaseSwapchainImagesEXT") {
      let rsi = @vk.VkReleaseSwapchainImagesInfoKHR::new()
      let _ = (dfn.vkReleaseSwapchainImagesEXT)(dev, rsi)
      rsi.free()
    }

    // 3b. Present Wait 1 & 2 (gated unless present-id submitted)
    let has_presented_id = false
    if has_presented_id && dev_has("vkWaitForPresentKHR") {
      let _ = (dfn.vkWaitForPresentKHR)(dev, sw, (0 : UInt64), (0 : UInt64))
    }
    if has_presented_id && dev_has("vkWaitForPresent2KHR") {
      let pw2i = @vk.VkPresentWait2InfoKHR::new()
      let _ = (dfn.vkWaitForPresent2KHR)(dev, sw, pw2i)
      pw2i.free()
    }

    // 3c. Present Timing EXT (when feature supported & extension enabled)
    let before_3c = n
    let pt_gate = has_dext("VK_EXT_present_timing") && pt_q.get_presentTiming() != 0
    if pt_gate {
      avail = avail + 1
      if dev_has("vkSetSwapchainPresentTimingQueueSizeEXT") {
        let _ = (dfn.vkSetSwapchainPresentTimingQueueSizeEXT)(dev, sw, (4 : UInt32))
        n = n + 1
      }
      if dev_has("vkGetSwapchainTimeDomainPropertiesEXT") {
        let tdp = @vk.VkSwapchainTimeDomainPropertiesEXT::new()
        let cnt = FixedArray::make(1, (0 : UInt64))
        let _ = (dfn.vkGetSwapchainTimeDomainPropertiesEXT)(dev, sw, tdp, cnt)
        tdp.free()
        n = n + 1
      }
      if dev_has("vkGetSwapchainTimingPropertiesEXT") {
        let tp = @vk.VkSwapchainTimingPropertiesEXT::new()
        let cnt = FixedArray::make(1, (0 : UInt64))
        let _ = (dfn.vkGetSwapchainTimingPropertiesEXT)(dev, sw, tp, cnt)
        tp.free()
        n = n + 1
      }
      if dev_has("vkGetPastPresentationTimingEXT") {
        let pti = @vk.VkPastPresentationTimingInfoEXT::new()
        pti.set_swapchain(sw)
        let ptp = @vk.VkPastPresentationTimingPropertiesEXT::new()
        let _ = (dfn.vkGetPastPresentationTimingEXT)(dev, pti, ptp)
        pti.free()
        ptp.free()
        n = n + 1
      }
    }
    if pt_gate && n > before_3c {
      ran = ran + 1
    }

    // 3d. NVIDIA Low Latency 2 (live when supported)
    let before_3d = n
    let nv_gate = has_dext("VK_NV_low_latency2") && f12_q.get_timelineSemaphore() != 0 && dev_has("vkSetLatencySleepModeNV")
    if nv_gate {
      avail = avail + 1
      let lsmi = @vk.VkLatencySleepModeInfoNV::new()
      lsmi.set_lowLatencyMode((1 : UInt32))
      lsmi.set_lowLatencyBoost((0 : UInt32))
      lsmi.set_minimumIntervalUs((0 : UInt32))
      let _ = (dfn.vkSetLatencySleepModeNV)(dev, sw, lsmi)
      n = n + 1

      let stci = @vk.VkSemaphoreTypeCreateInfo::new()
      stci.set_semaphoreType(@vk.VK_SEMAPHORE_TYPE_TIMELINE)
      stci.set_initialValue((0 : UInt64))
      let sci = @vk.VkSemaphoreCreateInfo::new()
      sci.set_pNext(stci.as_ptr())
      let sem_out = FixedArray::make(1, @vk.VkSemaphore::null())
      if (dfn.vkCreateSemaphore)(dev, sci, na, sem_out) == 0 {
        let lsi = @vk.VkLatencySleepInfoNV::new()
        lsi.set_signalSemaphore(sem_out[0])
        lsi.set_value((1 : UInt64))
        let _ = (dfn.vkLatencySleepNV)(dev, sw, lsi)
        lsi.free()
        n = n + 1
        (dfn.vkDestroySemaphore)(dev, sem_out[0], na)
      }
      sci.free()
      stci.free()

      let slmi = @vk.VkSetLatencyMarkerInfoNV::new()
      slmi.set_presentID((1 : UInt64))
      slmi.set_marker(@vk.VK_LATENCY_MARKER_SIMULATION_START_NV)
      (dfn.vkSetLatencyMarkerNV)(dev, sw, slmi)
      slmi.free()
      n = n + 1

      let glm = @vk.VkGetLatencyMarkerInfoNV::new()
      glm.set_timingCount((0 : UInt32))
      (dfn.vkGetLatencyTimingsNV)(dev, sw, glm)
      glm.free()
      n = n + 1

      let oob = @vk.VkOutOfBandQueueTypeInfoNV::new()
      oob.set_queueType(@vk.VK_OUT_OF_BAND_QUEUE_TYPE_RENDER_NV)
      (dfn.vkQueueNotifyOutOfBandNV)(queue, oob)
      oob.free()
      n = n + 1
      lsmi.free()
    }
    if nv_gate && n > before_3d {
      ran = ran + 1
    }

    // 3e. Legacy NV Low Latency & Display Control (guarded unless legacy device/display present)
    let has_legacy_ll = false
    if has_legacy_ll && dev_has("vkSetLatencySleepModeLegacyNV") {
      (dfn.vkSetLatencySleepModeLegacyNV)(dev, (0 : UInt32), (0 : UInt32), (0 : UInt32))
      (dfn.vkLatencySleepLegacyNV)(dev, @vk.VkSemaphore::null(), (0 : UInt64))
      let status = FixedArray::make(1, (0 : UInt32))
      (dfn.vkGetSleepStatusLegacyNV)(dev, status)
      (dfn.vkSetLatencyMarkerLegacyNV)(dev, (0 : UInt64), (0 : UInt32))
      (dfn.vkGetLatencyTimingsLegacyNV)(dev, (0 : UInt64))
      (dfn.vkQueueNotifyOutOfBandLegacyNV)(queue, (0 : UInt32))
      (dfn.vkShutdownLatencyDeviceLegacyNV)(dev)
    }
    let before_3e = n
    let dc_gate = has_dext("VK_EXT_display_control") && has_iext("VK_EXT_display_surface_counter")
    if dc_gate {
      avail = avail + 1
      if dev_has("vkGetSwapchainCounterEXT") {
        let cnt = FixedArray::make(1, (0 : UInt64))
        let _ = (dfn.vkGetSwapchainCounterEXT)(dev, sw, @vk.VK_SURFACE_COUNTER_VBLANK_BIT_EXT, cnt)
        n = n + 1
      }
      if dev_has("vkRegisterDeviceEventEXT") {
        let dei = @vk.VkDeviceEventInfoEXT::new()
        let fo = FixedArray::make(1, @vk.VkFence::null())
        let rr = (dfn.vkRegisterDeviceEventEXT)(dev, dei, na, fo)
        if rr == 0 {
          (dfn.vkDestroyFence)(dev, fo[0], na)
        }
        dei.free()
        n = n + 1
      }
      let has_live_disp_ctrl = false
      if has_live_disp_ctrl && first_disp.as_ptr() != (0 : UInt64) {
        let dpi = @vk.VkDisplayPowerInfoEXT::new()
        let _ = (dfn.vkDisplayPowerControlEXT)(dev, first_disp, dpi)
        let dsei = @vk.VkDisplayEventInfoEXT::new()
        let fo = FixedArray::make(1, @vk.VkFence::null())
        let _ = (dfn.vkRegisterDisplayEventEXT)(dev, first_disp, dsei, na, fo)
        dpi.free()
        dsei.free()
      }
    }
    if dc_gate && n > before_3e {
      ran = ran + 1
    }

    let _ = (dfn.vkDeviceWaitIdle)(dev)
    (dfn.vkDestroySwapchainKHR)(dev, sw, na)
  }

  (ifn.vkDestroySurfaceKHR)(inst, surface, na)
  @win.destroy(win)
  @win.terminate()
  (dfn.vkDestroyDevice)(dev, na)
  @vk.destroy_debug_messenger(inst, ifn, messenger)
  (ifn.vkDestroyInstance)(inst, na)

  println("[33-wsi] commands=\{n} sw=\{swr} errors=\{g_errors.val}")
  let shortfall = avail - ran
  if swr != 0 || g_errors.val != 0 {
    println("[33-wsi] FAIL — sw=\{swr} n=\{n} groups=\{ran}/\{avail} errors=\{g_errors.val}")
  } else if shortfall > 0 {
    println("[33-wsi] FAIL — \{shortfall} supported extension group(s) executed nothing (groups=\{ran}/\{avail} n=\{n})")
  } else if n == 0 {
    println("[33-wsi] SKIP — 0 WSI/display/latency commands available on this driver")
  } else {
    println("[33-wsi] OK — \{n} WSI/display/latency commands verified, 0 validation errors")
  }
}
