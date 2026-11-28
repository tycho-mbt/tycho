// vulkan/win32-interop — Windows-specific Vulkan interop & WSI verification.
// Pure MoonBit (zero user C): exercises every Windows host-reachable Win32 and
// NVIDIA Windows extension command with VK_LAYER_KHRONOS_validation enabled and
// asserts zero validation errors. Non-Windows hosts report SKIP.
//
// Handle ownership (per spec): importing memory / semaphore / fence payloads
// from NT handles does NOT transfer ownership to Vulkan — the example keeps
// every exported handle open while the imported object is alive and closes it
// with @vk.win32_close_handle afterwards. KMT-style global handles are never
// closed.

let na : @vk.VkAllocationCallbacks = @vk.VkAllocationCallbacks::null()
let g_errors : Ref[Int] = Ref(0)

fn ext_in(props : @vk.VkExtensionProperties, count : Int, name : String) -> Bool {
  for i = 0; i < count; i = i + 1 {
    if props.get_extensionName_string_at(i) == name {
      return true
    }
  }
  false
}

fn list_has(list : FixedArray[String], count : Int, name : String) -> Bool {
  for i = 0; i < count; i = i + 1 {
    if list[i] == name {
      return true
    }
  }
  false
}

// Filter `want` down to the extensions present in `props`, preserving order.
fn pick(
  want : FixedArray[String],
  props : @vk.VkExtensionProperties,
  count : Int,
) -> (FixedArray[String], Int) {
  let out = FixedArray::make(want.length(), "")
  let mut n = 0
  for i = 0; i < want.length(); i = i + 1 {
    if ext_in(props, count, want[i]) {
      out[n] = want[i]
      n = n + 1
    }
  }
  (out, n)
}

// First memory type in `bits` whose flags include `want`, or -1.
fn mem_type(
  phys : @vk.VkPhysicalDevice,
  ifn : @vk.InstanceFn,
  bits : UInt32,
  want : UInt32,
) -> Int {
  let mp = @vk.VkPhysicalDeviceMemoryProperties::new()
  (ifn.vkGetPhysicalDeviceMemoryProperties)(phys, mp)
  let n = mp.get_memoryTypeCount().reinterpret_as_int()
  let mut found = -1
  for i = 0; i < n; i = i + 1 {
    if (bits & ((1 : UInt32) << i)) != 0 &&
      (mp.get_memoryTypes_at(i).get_propertyFlags() & want) == want {
      found = i
      break
    }
  }
  mp.free()
  found
}

///|
fn main {
  match @win.platform() {
    @win.Platform::Windows => ()
    _ => {
      println("[vulkan/win32-interop] SKIP — Windows-only suite (host is not Windows)")
      return
    }
  }
  let mut probed = 0
  let mut sections = 0

  // --- Instance: validation layer + every Windows-relevant instance extension ---
  let lc = FixedArray::make(1, (0 : UInt32))
  let _ = @vk.vkEnumerateInstanceLayerProperties(lc, @vk.VkLayerProperties::null())
  let layers = @vk.VkLayerProperties::array(lc[0].reinterpret_as_int())
  let _ = @vk.vkEnumerateInstanceLayerProperties(lc, layers)
  let mut has_validation = false
  for i = 0; i < lc[0].reinterpret_as_int(); i = i + 1 {
    if layers.get_layerName_string_at(i) == "VK_LAYER_KHRONOS_validation" {
      has_validation = true
    }
  }
  layers.free()
  if !has_validation {
    println("[vulkan/win32-interop] SKIP — VK_LAYER_KHRONOS_validation unavailable")
    return
  }
  let iec = FixedArray::make(1, (0 : UInt32))
  let _ = @vk.vkEnumerateInstanceExtensionProperties(
    (0 : UInt64),
    iec,
    @vk.VkExtensionProperties::null(),
  )
  let iexts = @vk.VkExtensionProperties::array(iec[0].reinterpret_as_int())
  let _ = @vk.vkEnumerateInstanceExtensionProperties((0 : UInt64), iec, iexts)
  let in_count = iec[0].reinterpret_as_int()
  let want_i : FixedArray[String] = [
    "VK_KHR_surface",
    "VK_KHR_win32_surface",
    "VK_KHR_get_physical_device_properties2",
    "VK_KHR_get_surface_capabilities2",
    "VK_KHR_external_memory_capabilities",
    "VK_KHR_external_semaphore_capabilities",
    "VK_KHR_external_fence_capabilities",
    "VK_KHR_display",
    "VK_EXT_direct_mode_display",
    "VK_NV_external_memory_capabilities",
    "VK_EXT_debug_utils",
  ]
  let (iext_list, ni) = pick(want_i, iexts, in_count)
  iexts.free()
  if !list_has(iext_list, ni, "VK_KHR_win32_surface") {
    println("[vulkan/win32-interop] SKIP — VK_KHR_win32_surface unavailable")
    return
  }
  let app = @vk.VkApplicationInfo::new()
  app.set_pApplicationName(@vk.cstr("TychoWin32Interop"))
  app.set_apiVersion((4206592 : UInt32)) // 1.3
  let ici = @vk.VkInstanceCreateInfo::new()
  ici.set_pApplicationInfo(app)
  ici.set_enabledLayerCount((1 : UInt32))
  ici.set_ppEnabledLayerNames(@vk.cstr_array(["VK_LAYER_KHRONOS_validation"]))
  ici.set_enabledExtensionCount(ni.reinterpret_as_uint())
  ici.set_ppEnabledExtensionNames(@vk.cstr_array(iext_list))
  let inst_out = FixedArray::make(1, @vk.VkInstance::null())
  let ir = @vk.vkCreateInstance(ici, na, inst_out)
  if ir != 0 {
    println("[vulkan/win32-interop] FAIL — vkCreateInstance=\{ir}")
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
      println("[vulkan/win32-interop] VALIDATION: \{@vk.read_cstr(data.get_pMessage())}")
      (0 : UInt32)
    },
  )

  // --- Physical device: prefer a discrete GPU on Vulkan 1.3+ ---
  let pc = FixedArray::make(1, (16 : UInt32))
  let devs = FixedArray::make(16, @vk.VkPhysicalDevice::null())
  let _ = (ifn.vkEnumeratePhysicalDevices)(inst, pc, devs)
  let ndev = pc[0].reinterpret_as_int()
  if ndev == 0 {
    println("[vulkan/win32-interop] SKIP — no Vulkan physical device")
    @vk.destroy_debug_messenger(inst, ifn, messenger)
    (ifn.vkDestroyInstance)(inst, na)
    return
  }
  let mut phys = devs[0]
  for i = 0; i < ndev; i = i + 1 {
    let props = @vk.VkPhysicalDeviceProperties::new()
    (ifn.vkGetPhysicalDeviceProperties)(devs[i], props)
    let api = props.get_apiVersion()
    let ty = props.get_deviceType()
    props.free()
    if api >= (4206592 : UInt32) && ty == @vk.VK_PHYSICAL_DEVICE_TYPE_DISCRETE_GPU {
      phys = devs[i]
      break
    }
  }

  // --- Device extensions: pick what the driver offers, drop broken deps ---
  let dec = FixedArray::make(1, (0 : UInt32))
  let _ = (ifn.vkEnumerateDeviceExtensionProperties)(
    phys,
    (0 : UInt64),
    dec,
    @vk.VkExtensionProperties::null(),
  )
  let dexts = @vk.VkExtensionProperties::array(dec[0].reinterpret_as_int())
  let _ = (ifn.vkEnumerateDeviceExtensionProperties)(phys, (0 : UInt64), dec, dexts)
  let dn = dec[0].reinterpret_as_int()
  let want_d : FixedArray[String] = [
    "VK_KHR_swapchain",
    "VK_KHR_external_memory",
    "VK_KHR_external_memory_win32",
    "VK_KHR_external_semaphore",
    "VK_KHR_external_semaphore_win32",
    "VK_KHR_external_fence",
    "VK_KHR_external_fence_win32",
    "VK_KHR_timeline_semaphore",
    "VK_KHR_win32_keyed_mutex",
    "VK_KHR_device_group",
    "VK_EXT_full_screen_exclusive",
    "VK_NV_external_memory",
    "VK_NV_external_memory_win32",
    "VK_NV_win32_keyed_mutex",
    "VK_NV_acquire_winrt_display",
    "VK_NV_external_compute_queue",
  ]
  let (picked, np) = pick(want_d, dexts, dn)
  dexts.free()
  let dext_list = FixedArray::make(want_d.length(), "")
  let mut nd = 0
  for i = 0; i < np; i = i + 1 {
    let e = picked[i]
    let ok = match e {
      "VK_KHR_external_memory_win32" => list_has(picked, np, "VK_KHR_external_memory")
      "VK_KHR_external_semaphore_win32" => list_has(picked, np, "VK_KHR_external_semaphore")
      "VK_KHR_external_fence_win32" => list_has(picked, np, "VK_KHR_external_fence")
      "VK_KHR_win32_keyed_mutex" => list_has(picked, np, "VK_KHR_external_memory_win32") &&
        list_has(picked, np, "VK_KHR_external_memory")
      "VK_NV_external_memory_win32" => list_has(picked, np, "VK_NV_external_memory")
      "VK_NV_win32_keyed_mutex" => list_has(picked, np, "VK_NV_external_memory_win32") &&
        list_has(picked, np, "VK_NV_external_memory")
      "VK_NV_acquire_winrt_display" => list_has(iext_list, ni, "VK_EXT_direct_mode_display")
      _ => true
    }
    if ok {
      dext_list[nd] = e
      nd = nd + 1
    }
  }
  let has_mem_win32 = list_has(dext_list, nd, "VK_KHR_external_memory_win32")
  let has_sem_win32 = list_has(dext_list, nd, "VK_KHR_external_semaphore_win32")
  let has_fence_win32 = list_has(dext_list, nd, "VK_KHR_external_fence_win32")
  let has_fse = list_has(dext_list, nd, "VK_EXT_full_screen_exclusive")
  let has_nv_mem = list_has(dext_list, nd, "VK_NV_external_memory_win32") &&
    list_has(iext_list, ni, "VK_NV_external_memory_capabilities")
  let has_nv_winrt = list_has(dext_list, nd, "VK_NV_acquire_winrt_display")
  let has_nv_ecq = list_has(dext_list, nd, "VK_NV_external_compute_queue")

  // --- Window + Win32 surface (also picks a present-capable queue family) ---
  if @win.initialize() == 0 {
    println("[vulkan/win32-interop] SKIP — Win32 window backend unavailable")
    @vk.destroy_debug_messenger(inst, ifn, messenger)
    (ifn.vkDestroyInstance)(inst, na)
    return
  }
  let win = @win.create(64, 64, "tycho win32-interop")
  if win == (0 : UInt64) {
    println("[vulkan/win32-interop] SKIP — could not create a Win32 window")
    @vk.destroy_debug_messenger(inst, ifn, messenger)
    (ifn.vkDestroyInstance)(inst, na)
    return
  }
  let hwnd = @win.native_handle(win)
  let hinst = @win.native_display(win)
  let hmon = @win.monitor_handle(win)
  let wci = @vk.VkWin32SurfaceCreateInfoKHR::new()
  wci.set_hinstance(hinst)
  wci.set_hwnd(hwnd)
  let surf_out = FixedArray::make(1, @vk.VkSurfaceKHR::null())
  let sr = (ifn.vkCreateWin32SurfaceKHR)(inst, wci, na, surf_out)
  probed = probed + 1
  wci.free()
  if sr != 0 {
    println("[vulkan/win32-interop] FAIL — vkCreateWin32SurfaceKHR=\{sr}")
    @win.destroy(win)
    @vk.destroy_debug_messenger(inst, ifn, messenger)
    (ifn.vkDestroyInstance)(inst, na)
    return
  }
  let surface = surf_out[0]
  sections = sections + 1
  let _ = (ifn.vkGetPhysicalDeviceWin32PresentationSupportKHR)(phys, (0 : UInt32))
  probed = probed + 1
  let qfc = FixedArray::make(1, (0 : UInt32))
  (ifn.vkGetPhysicalDeviceQueueFamilyProperties)(phys, qfc, @vk.VkQueueFamilyProperties::null())
  let qfps = @vk.VkQueueFamilyProperties::array(qfc[0].reinterpret_as_int())
  (ifn.vkGetPhysicalDeviceQueueFamilyProperties)(phys, qfc, qfps)
  let mut qfam = 0
  for i = 0; i < qfc[0].reinterpret_as_int(); i = i + 1 {
    if (qfps.get_queueFlags_at(i) & @vk.VK_QUEUE_GRAPHICS_BIT) != 0 {
      let sup = FixedArray::make(1, (0 : UInt32))
      let _ = (ifn.vkGetPhysicalDeviceSurfaceSupportKHR)(
        phys,
        i.reinterpret_as_uint(),
        surface,
        sup,
      )
      probed = probed + 1
      if sup[0] != 0 {
        qfam = i
        break
      }
    }
  }
  qfps.free()

  // --- Device (timeline semaphore feature enabled when supported) ---
  let f12q = @vk.VkPhysicalDeviceVulkan12Features::new()
  let f2q = @vk.VkPhysicalDeviceFeatures2::new()
  f2q.set_pNext(f12q.as_ptr())
  (ifn.vkGetPhysicalDeviceFeatures2)(phys, f2q)
  let has_timeline = f12q.get_timelineSemaphore() != 0
  let f12 = @vk.VkPhysicalDeviceVulkan12Features::new()
  f12.set_timelineSemaphore(f12q.get_timelineSemaphore())
  let f2 = @vk.VkPhysicalDeviceFeatures2::new()
  f2.set_pNext(f12.as_ptr())
  f12q.free()
  f2q.free()
  let prio = FixedArray::make(1, (1.0 : Float))
  let qci = @vk.VkDeviceQueueCreateInfo::new()
  qci.set_queueFamilyIndex(qfam.reinterpret_as_uint())
  qci.set_queueCount((1 : UInt32))
  qci.set_pQueuePriorities(prio)
  let dci = @vk.VkDeviceCreateInfo::new()
  dci.set_queueCreateInfoCount((1 : UInt32))
  dci.set_pQueueCreateInfos(qci)
  dci.set_enabledExtensionCount(nd.reinterpret_as_uint())
  dci.set_ppEnabledExtensionNames(@vk.cstr_array(dext_list))
  dci.set_pNext(f2.as_ptr())
  let dev_out = FixedArray::make(1, @vk.VkDevice::null())
  let dr = (ifn.vkCreateDevice)(phys, dci, na, dev_out)
  if dr != 0 {
    println("[vulkan/win32-interop] FAIL — vkCreateDevice=\{dr}")
    (ifn.vkDestroySurfaceKHR)(inst, surface, na)
    @win.destroy(win)
    @vk.destroy_debug_messenger(inst, ifn, messenger)
    (ifn.vkDestroyInstance)(inst, na)
    return
  }
  let dev = dev_out[0]
  let dfn = @vk.DeviceFn::load(dev)
  let queue_out = FixedArray::make(1, @vk.VkQueue::null())
  (dfn.vkGetDeviceQueue)(dev, qfam.reinterpret_as_uint(), (0 : UInt32), queue_out)
  let queue = queue_out[0]

  // --- 1. VK_KHR_external_memory_win32: export / import round-trip ---
  if has_mem_win32 {
    let ebi = @vk.VkPhysicalDeviceExternalBufferInfo::new()
    ebi.set_usage(@vk.VK_BUFFER_USAGE_TRANSFER_SRC_BIT | @vk.VK_BUFFER_USAGE_TRANSFER_DST_BIT)
    ebi.set_handleType(@vk.VK_EXTERNAL_MEMORY_HANDLE_TYPE_OPAQUE_WIN32_BIT)
    let ebp = @vk.VkExternalBufferProperties::new()
    (ifn.vkGetPhysicalDeviceExternalBufferProperties)(phys, ebi, ebp)
    probed = probed + 1
    let feats = ebp.get_externalMemoryProperties().get_externalMemoryFeatures()
    ebi.free()
    ebp.free()
    if (feats & @vk.VK_EXTERNAL_MEMORY_FEATURE_EXPORTABLE_BIT) != 0 &&
      (feats & @vk.VK_EXTERNAL_MEMORY_FEATURE_IMPORTABLE_BIT) != 0 {
      let size = (4096 : UInt64)
      let bci = @vk.VkBufferCreateInfo::new()
      bci.set_size(size)
      bci.set_usage(@vk.VK_BUFFER_USAGE_TRANSFER_SRC_BIT | @vk.VK_BUFFER_USAGE_TRANSFER_DST_BIT)
      bci.set_sharingMode(@vk.VK_SHARING_MODE_EXCLUSIVE)
      let emb = @vk.VkExternalMemoryBufferCreateInfo::new()
      emb.set_handleTypes(@vk.VK_EXTERNAL_MEMORY_HANDLE_TYPE_OPAQUE_WIN32_BIT)
      bci.set_pNext(emb.as_ptr())
      let buf_out = FixedArray::make(1, @vk.VkBuffer::null())
      let br = (dfn.vkCreateBuffer)(dev, bci, na, buf_out)
      probed = probed + 1
      let buf2_out = FixedArray::make(1, @vk.VkBuffer::null())
      let br2 = (dfn.vkCreateBuffer)(dev, bci, na, buf2_out)
      probed = probed + 1
      bci.free()
      emb.free()
      let req = @vk.VkMemoryRequirements::new()
      (dfn.vkGetBufferMemoryRequirements)(dev, buf_out[0], req)
      probed = probed + 1
      let mt = mem_type(
        phys,
        ifn,
        req.get_memoryTypeBits(),
        @vk.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | @vk.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT,
      )
      req.free()
      if br == 0 && br2 == 0 && mt >= 0 {
        // Export allocation: NT handle + a named UTF-16 LPCWSTR export.
        let ema = @vk.VkExportMemoryAllocateInfo::new()
        ema.set_handleTypes(@vk.VK_EXTERNAL_MEMORY_HANDLE_TYPE_OPAQUE_WIN32_BIT)
        let emw = @vk.VkExportMemoryWin32HandleInfoKHR::new()
        emw.set_dwAccess((0x10000000 : UInt32)) // GENERIC_ALL
        emw.set_name(@vk.wstr("TychoWin32InteropMem"))
        ema.set_pNext(emw.as_ptr())
        let mai = @vk.VkMemoryAllocateInfo::new()
        mai.set_allocationSize(size)
        mai.set_memoryTypeIndex(mt.reinterpret_as_uint())
        mai.set_pNext(ema.as_ptr())
        let mem_out = FixedArray::make(1, @vk.VkDeviceMemory::null())
        let ar = (dfn.vkAllocateMemory)(dev, mai, na, mem_out)
        probed = probed + 1
        mai.free()
        ema.free()
        emw.free()
        if ar == 0 {
          let mem = mem_out[0]
          let ghi = @vk.VkMemoryGetWin32HandleInfoKHR::new()
          ghi.set_memory(mem)
          ghi.set_handleType(@vk.VK_EXTERNAL_MEMORY_HANDLE_TYPE_OPAQUE_WIN32_BIT)
          let h_out = FixedArray::make(1, (0 : UInt64))
          let hr = (dfn.vkGetMemoryWin32HandleKHR)(dev, ghi, h_out)
          probed = probed + 1
          ghi.free()
          let hmem = h_out[0]
          // OPAQUE_WIN32 imports reuse the export's memory type; the handle
          // properties query is only valid for non-opaque (D3D) handle types
          // and is exercised separately below.
          let pr = 0
          let import_mt = mt
          // Import by handle.
          let imw = @vk.VkImportMemoryWin32HandleInfoKHR::new()
          imw.set_handleType(@vk.VK_EXTERNAL_MEMORY_HANDLE_TYPE_OPAQUE_WIN32_BIT)
          imw.set_handle(hmem)
          let mai2 = @vk.VkMemoryAllocateInfo::new()
          mai2.set_allocationSize(size)
          mai2.set_memoryTypeIndex(
            (if import_mt >= 0 { import_mt } else { mt }).reinterpret_as_uint(),
          )
          mai2.set_pNext(imw.as_ptr())
          let mem2_out = FixedArray::make(1, @vk.VkDeviceMemory::null())
          let ar2 = (dfn.vkAllocateMemory)(dev, mai2, na, mem2_out)
          probed = probed + 1
          mai2.free()
          imw.free()
          // Import by name (LPCWSTR).
          let imn = @vk.VkImportMemoryWin32HandleInfoKHR::new()
          imn.set_handleType(@vk.VK_EXTERNAL_MEMORY_HANDLE_TYPE_OPAQUE_WIN32_BIT)
          imn.set_name(@vk.wstr("TychoWin32InteropMem"))
          let mai3 = @vk.VkMemoryAllocateInfo::new()
          mai3.set_allocationSize(size)
          mai3.set_memoryTypeIndex(mt.reinterpret_as_uint())
          mai3.set_pNext(imn.as_ptr())
          let mem3_out = FixedArray::make(1, @vk.VkDeviceMemory::null())
          let ar3 = (dfn.vkAllocateMemory)(dev, mai3, na, mem3_out)
          probed = probed + 1
          mai3.free()
          imn.free()
          let mut shared_ok = false
          if hr == 0 && pr == 0 && ar2 == 0 && import_mt >= 0 {
            let _ = (dfn.vkBindBufferMemory)(dev, buf_out[0], mem, (0 : UInt64))
            probed = probed + 1
            let _ = (dfn.vkBindBufferMemory)(dev, buf2_out[0], mem2_out[0], (0 : UInt64))
            probed = probed + 1
            // Write a pattern through the export, read it through the import.
            let pattern = Bytes::make(256, (0x5A : Byte))
            let map_out = FixedArray::make(1, (0 : UInt64))
            let mr = (dfn.vkMapMemory)(dev, mem, (0 : UInt64), size, (0 : UInt32), map_out)
            probed = probed + 1
            if mr == 0 {
              @vk.memcpy_ptr(map_out[0], @vk.bytes_ptr(pattern), 256)
              (dfn.vkUnmapMemory)(dev, mem)
              probed = probed + 1
            }
            let map2_out = FixedArray::make(1, (0 : UInt64))
            let mr2 = (dfn.vkMapMemory)(dev, mem2_out[0], (0 : UInt64), size, (0 : UInt32), map2_out)
            probed = probed + 1
            if mr2 == 0 {
              let got = Bytes::make(256, (0 : Byte))
              @vk.memcpy_ptr(@vk.bytes_ptr(got), map2_out[0], 256)
              (dfn.vkUnmapMemory)(dev, mem2_out[0])
              probed = probed + 1
              shared_ok = got == pattern
            }
          }
          if ar3 == 0 {
            (dfn.vkFreeMemory)(dev, mem3_out[0], na)
            probed = probed + 1
          }
          if ar2 == 0 {
            (dfn.vkFreeMemory)(dev, mem2_out[0], na)
            probed = probed + 1
          }
          (dfn.vkFreeMemory)(dev, mem, na)
          probed = probed + 1
          if hmem != (0 : UInt64) {
            @vk.win32_close_handle(hmem)
          }
          if !shared_ok {
            println("[vulkan/win32-interop] FAIL — external memory round-trip mismatch (hr=\{hr} pr=\{pr} ar2=\{ar2} ar3=\{ar3})")
          } else {
            sections = sections + 1
          }
        }
      }
      (dfn.vkDestroyBuffer)(dev, buf_out[0], na)
      probed = probed + 1
      (dfn.vkDestroyBuffer)(dev, buf2_out[0], na)
      probed = probed + 1
    }
    // vkGetMemoryWin32HandlePropertiesKHR is only valid for non-opaque handle
    // types (VUID-vkGetMemoryWin32HandlePropertiesKHR-handleType-00666). D3D
    // handles are import-only for buffers, so export a texture image instead.
    let d3d_types : FixedArray[UInt32] = [
      @vk.VK_EXTERNAL_MEMORY_HANDLE_TYPE_D3D11_TEXTURE_BIT,
      @vk.VK_EXTERNAL_MEMORY_HANDLE_TYPE_D3D12_RESOURCE_BIT,
    ]
    let d3d_usages : FixedArray[UInt32] = [
      @vk.VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT | @vk.VK_IMAGE_USAGE_SAMPLED_BIT,
      @vk.VK_IMAGE_USAGE_SAMPLED_BIT,
      @vk.VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT,
      @vk.VK_IMAGE_USAGE_STORAGE_BIT | @vk.VK_IMAGE_USAGE_SAMPLED_BIT,
      @vk.VK_IMAGE_USAGE_TRANSFER_SRC_BIT | @vk.VK_IMAGE_USAGE_TRANSFER_DST_BIT,
    ]
    let mut d3d_done = false
    for ti = 0; ti < d3d_types.length() && !d3d_done; ti = ti + 1 {
      let ht = d3d_types[ti]
      // Find a usage for which this handle type is exportable, via
      // vkGetPhysicalDeviceImageFormatProperties2 + external-info pNext chain.
      let mut use_usage = (0 : UInt32)
      let mut found = false
      for ui = 0; ui < d3d_usages.length() && !found; ui = ui + 1 {
        let u = d3d_usages[ui]
        let ext_info = @vk.VkPhysicalDeviceExternalImageFormatInfo::new()
        ext_info.set_handleType(ht)
        let ifi2 = @vk.VkPhysicalDeviceImageFormatInfo2::new()
        ifi2.set_format(@vk.VK_FORMAT_R8G8B8A8_UNORM)
        ifi2.set_type(@vk.VK_IMAGE_TYPE_2D)
        ifi2.set_tiling(@vk.VK_IMAGE_TILING_OPTIMAL)
        ifi2.set_usage(u)
        ifi2.set_pNext(ext_info.as_ptr())
        let ext_props = @vk.VkExternalImageFormatProperties::new()
        let ifp2 = @vk.VkImageFormatProperties2::new()
        ifp2.set_pNext(ext_props.as_ptr())
        let qrr = (ifn.vkGetPhysicalDeviceImageFormatProperties2)(phys, ifi2, ifp2)
        probed = probed + 1
        let feats2 = ext_props.get_externalMemoryProperties().get_externalMemoryFeatures()
        ext_info.free()
        ifi2.free()
        ext_props.free()
        ifp2.free()
        if qrr == 0 && (feats2 & @vk.VK_EXTERNAL_MEMORY_FEATURE_EXPORTABLE_BIT) != 0 {
          use_usage = u
          found = true
        }
      }
      if !found {
        continue
      }
      let ici2 = @vk.VkImageCreateInfo::new()
      ici2.set_imageType(@vk.VK_IMAGE_TYPE_2D)
      ici2.set_format(@vk.VK_FORMAT_R8G8B8A8_UNORM)
      let ext2 = @vk.VkExtent3D::new()
      ext2.set_width((64 : UInt32))
      ext2.set_height((64 : UInt32))
      ext2.set_depth((1 : UInt32))
      ici2.set_extent(ext2)
      ici2.set_mipLevels((1 : UInt32))
      ici2.set_arrayLayers((1 : UInt32))
      ici2.set_samples(@vk.VK_SAMPLE_COUNT_1_BIT)
      ici2.set_tiling(@vk.VK_IMAGE_TILING_OPTIMAL)
      ici2.set_usage(use_usage)
      ici2.set_sharingMode(@vk.VK_SHARING_MODE_EXCLUSIVE)
      ici2.set_initialLayout(@vk.VK_IMAGE_LAYOUT_UNDEFINED)
      let emi2 = @vk.VkExternalMemoryImageCreateInfo::new()
      emi2.set_handleTypes(ht)
      ici2.set_pNext(emi2.as_ptr())
      let imgd_out = FixedArray::make(1, @vk.VkImage::null())
      let imrd = (dfn.vkCreateImage)(dev, ici2, na, imgd_out)
      probed = probed + 1
      ici2.free()
      emi2.free()
      ext2.free()
      if imrd == 0 {
        let reqd = @vk.VkMemoryRequirements::new()
        (dfn.vkGetImageMemoryRequirements)(dev, imgd_out[0], reqd)
        probed = probed + 1
        let mtd = mem_type(phys, ifn, reqd.get_memoryTypeBits(), (0 : UInt32))
        let aszd = reqd.get_size()
        reqd.free()
        if mtd >= 0 {
          let emad = @vk.VkExportMemoryAllocateInfo::new()
          emad.set_handleTypes(ht)
          let dedi = @vk.VkMemoryDedicatedAllocateInfo::new()
          dedi.set_image(imgd_out[0])
          emad.set_pNext(dedi.as_ptr())
          let maid = @vk.VkMemoryAllocateInfo::new()
          maid.set_allocationSize(aszd)
          maid.set_memoryTypeIndex(mtd.reinterpret_as_uint())
          maid.set_pNext(emad.as_ptr())
          let memd_out = FixedArray::make(1, @vk.VkDeviceMemory::null())
          let ard = (dfn.vkAllocateMemory)(dev, maid, na, memd_out)
          probed = probed + 1
          maid.free()
          emad.free()
          dedi.free()
          if ard == 0 {
            let _ = (dfn.vkBindImageMemory)(dev, imgd_out[0], memd_out[0], (0 : UInt64))
            probed = probed + 1
            let ghid = @vk.VkMemoryGetWin32HandleInfoKHR::new()
            ghid.set_memory(memd_out[0])
            ghid.set_handleType(ht)
            let hd_out = FixedArray::make(1, (0 : UInt64))
            let hrd = (dfn.vkGetMemoryWin32HandleKHR)(dev, ghid, hd_out)
            probed = probed + 1
            ghid.free()
            if hrd == 0 && hd_out[0] != (0 : UInt64) {
              let mwpd = @vk.VkMemoryWin32HandlePropertiesKHR::new()
              let prd = (dfn.vkGetMemoryWin32HandlePropertiesKHR)(dev, ht, hd_out[0], mwpd)
              probed = probed + 1
              if prd != 0 {
                println("[vulkan/win32-interop] FAIL — D3D handle properties query=\{prd}")
              } else {
                d3d_done = true
              }
              mwpd.free()
              @vk.win32_close_handle(hd_out[0])
            }
            (dfn.vkFreeMemory)(dev, memd_out[0], na)
            probed = probed + 1
          }
        }
        (dfn.vkDestroyImage)(dev, imgd_out[0], na)
        probed = probed + 1
      }
    }
  }

  // --- 2. VK_KHR_external_semaphore_win32: binary + timeline round-trips ---
  if has_sem_win32 {
    let esi = @vk.VkPhysicalDeviceExternalSemaphoreInfo::new()
    esi.set_handleType(@vk.VK_EXTERNAL_SEMAPHORE_HANDLE_TYPE_OPAQUE_WIN32_BIT)
    let esp = @vk.VkExternalSemaphoreProperties::new()
    (ifn.vkGetPhysicalDeviceExternalSemaphoreProperties)(phys, esi, esp)
    probed = probed + 1
    let sfeats = esp.get_externalSemaphoreFeatures()
    esi.free()
    esp.free()
    if (sfeats & @vk.VK_EXTERNAL_MEMORY_FEATURE_EXPORTABLE_BIT) != 0 &&
      (sfeats & @vk.VK_EXTERNAL_MEMORY_FEATURE_IMPORTABLE_BIT) != 0 {
      // Binary semaphore: export -> import -> signal via import, wait via export.
      let esc = @vk.VkExportSemaphoreCreateInfo::new()
      esc.set_handleTypes(@vk.VK_EXTERNAL_SEMAPHORE_HANDLE_TYPE_OPAQUE_WIN32_BIT)
      let esw = @vk.VkExportSemaphoreWin32HandleInfoKHR::new()
      esw.set_dwAccess((0x10000000 : UInt32))
      esw.set_name(@vk.wstr("TychoWin32InteropSem"))
      esc.set_pNext(esw.as_ptr())
      let sci = @vk.VkSemaphoreCreateInfo::new()
      sci.set_pNext(esc.as_ptr())
      let sem_a_out = FixedArray::make(1, @vk.VkSemaphore::null())
      let sar = (dfn.vkCreateSemaphore)(dev, sci, na, sem_a_out)
      probed = probed + 1
      sci.set_pNext((0 : UInt64))
      let sem_b_out = FixedArray::make(1, @vk.VkSemaphore::null())
      let sbr = (dfn.vkCreateSemaphore)(dev, sci, na, sem_b_out)
      probed = probed + 1
      sci.free()
      esc.free()
      esw.free()
      let mut binary_ok = false
      if sar == 0 && sbr == 0 {
        let sghi = @vk.VkSemaphoreGetWin32HandleInfoKHR::new()
        sghi.set_semaphore(sem_a_out[0])
        sghi.set_handleType(@vk.VK_EXTERNAL_SEMAPHORE_HANDLE_TYPE_OPAQUE_WIN32_BIT)
        let sh_out = FixedArray::make(1, (0 : UInt64))
        let shr = (dfn.vkGetSemaphoreWin32HandleKHR)(dev, sghi, sh_out)
        probed = probed + 1
        sghi.free()
        let isw = @vk.VkImportSemaphoreWin32HandleInfoKHR::new()
        isw.set_semaphore(sem_b_out[0])
        isw.set_handleType(@vk.VK_EXTERNAL_SEMAPHORE_HANDLE_TYPE_OPAQUE_WIN32_BIT)
        isw.set_handle(sh_out[0])
        let isr = (dfn.vkImportSemaphoreWin32HandleKHR)(dev, isw)
        probed = probed + 1
        isw.free()
        if shr == 0 && isr == 0 {
          let stage = FixedArray::make(1, @vk.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT)
          let sig = @vk.VkSubmitInfo::new()
          sig.set_signalSemaphoreCount((1 : UInt32))
          sig.set_pSignalSemaphores(sem_b_out)
          let r1 = (dfn.vkQueueSubmit)(queue, (1 : UInt32), sig, @vk.VkFence::null())
          probed = probed + 1
          sig.free()
          let wait = @vk.VkSubmitInfo::new()
          wait.set_waitSemaphoreCount((1 : UInt32))
          wait.set_pWaitSemaphores(sem_a_out)
          wait.set_pWaitDstStageMask(stage)
          let r2 = (dfn.vkQueueSubmit)(queue, (1 : UInt32), wait, @vk.VkFence::null())
          probed = probed + 1
          wait.free()
          let r3 = (dfn.vkQueueWaitIdle)(queue)
          probed = probed + 1
          binary_ok = r1 == 0 && r2 == 0 && r3 == 0
        }
        // Ownership stays with the app: close only after the import is destroyed.
        (dfn.vkDestroySemaphore)(dev, sem_b_out[0], na)
        probed = probed + 1
        if sh_out[0] != (0 : UInt64) {
          @vk.win32_close_handle(sh_out[0])
        }
      }
      (dfn.vkDestroySemaphore)(dev, sem_a_out[0], na)
      probed = probed + 1
      if binary_ok {
        sections = sections + 1
      } else {
        println("[vulkan/win32-interop] FAIL — binary semaphore win32 round-trip")
      }
      // Timeline semaphore: export -> import -> signal/wait by value, plus a
      // VkD3D12FenceSubmitInfoKHR submit (the D3D12-fence-style value submit).
      if has_timeline {
        let stc = @vk.VkSemaphoreTypeCreateInfo::new()
        stc.set_semaphoreType(@vk.VK_SEMAPHORE_TYPE_TIMELINE)
        stc.set_initialValue((0 : UInt64))
        let tesc = @vk.VkExportSemaphoreCreateInfo::new()
        tesc.set_handleTypes(@vk.VK_EXTERNAL_SEMAPHORE_HANDLE_TYPE_OPAQUE_WIN32_BIT)
        stc.set_pNext(tesc.as_ptr())
        let tsci = @vk.VkSemaphoreCreateInfo::new()
        tsci.set_pNext(stc.as_ptr())
        let ta_out = FixedArray::make(1, @vk.VkSemaphore::null())
        let tar = (dfn.vkCreateSemaphore)(dev, tsci, na, ta_out)
        probed = probed + 1
        let tb_out = FixedArray::make(1, @vk.VkSemaphore::null())
        let tbr = (dfn.vkCreateSemaphore)(dev, tsci, na, tb_out)
        probed = probed + 1
        tsci.free()
        stc.free()
        tesc.free()
        let mut timeline_ok = false
        let mut d3d12_submit_ok = false
        if tar == 0 && tbr == 0 {
          let tghi = @vk.VkSemaphoreGetWin32HandleInfoKHR::new()
          tghi.set_semaphore(ta_out[0])
          tghi.set_handleType(@vk.VK_EXTERNAL_SEMAPHORE_HANDLE_TYPE_OPAQUE_WIN32_BIT)
          let th_out = FixedArray::make(1, (0 : UInt64))
          let thr = (dfn.vkGetSemaphoreWin32HandleKHR)(dev, tghi, th_out)
          probed = probed + 1
          tghi.free()
          let tisw = @vk.VkImportSemaphoreWin32HandleInfoKHR::new()
          tisw.set_semaphore(tb_out[0])
          tisw.set_handleType(@vk.VK_EXTERNAL_SEMAPHORE_HANDLE_TYPE_OPAQUE_WIN32_BIT)
          tisw.set_handle(th_out[0])
          let tir = (dfn.vkImportSemaphoreWin32HandleKHR)(dev, tisw)
          probed = probed + 1
          tisw.free()
          if thr == 0 && tir == 0 {
            // Signal value 5 through the import with VkTimelineSemaphoreSubmitInfo.
            let vals = FixedArray::make(1, (5 : UInt64))
            let tsi = @vk.VkTimelineSemaphoreSubmitInfo::new()
            tsi.set_signalSemaphoreValueCount((1 : UInt32))
            tsi.set_pSignalSemaphoreValues(vals)
            let tsig = @vk.VkSubmitInfo::new()
            tsig.set_pNext(tsi.as_ptr())
            tsig.set_signalSemaphoreCount((1 : UInt32))
            tsig.set_pSignalSemaphores(tb_out)
            let tr1 = (dfn.vkQueueSubmit)(queue, (1 : UInt32), tsig, @vk.VkFence::null())
            probed = probed + 1
            tsig.free()
            tsi.free()
            let wvals = FixedArray::make(1, (5 : UInt64))
            let swi = @vk.VkSemaphoreWaitInfo::new()
            swi.set_semaphoreCount((1 : UInt32))
            swi.set_pSemaphores(ta_out)
            swi.set_pValues(wvals)
            let tw1 = (dfn.vkWaitSemaphoresKHR)(dev, swi, (5000000000 : UInt64))
            probed = probed + 1
            swi.free()
            timeline_ok = tr1 == 0 && tw1 == 0
            // Signal value 7 through VkD3D12FenceSubmitInfoKHR instead.
            let dvals = FixedArray::make(1, (7 : UInt64))
            let dsi = @vk.VkD3D12FenceSubmitInfoKHR::new()
            dsi.set_signalSemaphoreValuesCount((1 : UInt32))
            dsi.set_pSignalSemaphoreValues(dvals)
            let dsig = @vk.VkSubmitInfo::new()
            dsig.set_pNext(dsi.as_ptr())
            dsig.set_signalSemaphoreCount((1 : UInt32))
            dsig.set_pSignalSemaphores(tb_out)
            let dr1 = (dfn.vkQueueSubmit)(queue, (1 : UInt32), dsig, @vk.VkFence::null())
            probed = probed + 1
            dsig.free()
            dsi.free()
            let dwvals = FixedArray::make(1, (7 : UInt64))
            let dswi = @vk.VkSemaphoreWaitInfo::new()
            dswi.set_semaphoreCount((1 : UInt32))
            dswi.set_pSemaphores(ta_out)
            dswi.set_pValues(dwvals)
            let dw1 = (dfn.vkWaitSemaphoresKHR)(dev, dswi, (5000000000 : UInt64))
            probed = probed + 1
            dswi.free()
            d3d12_submit_ok = dr1 == 0 && dw1 == 0
          }
          (dfn.vkDestroySemaphore)(dev, tb_out[0], na)
          probed = probed + 1
          if th_out[0] != (0 : UInt64) {
            @vk.win32_close_handle(th_out[0])
          }
        }
        (dfn.vkDestroySemaphore)(dev, ta_out[0], na)
        probed = probed + 1
        if timeline_ok && d3d12_submit_ok {
          sections = sections + 1
        } else {
          println("[vulkan/win32-interop] FAIL — timeline semaphore win32 round-trip (timeline=\{timeline_ok} d3d12submit=\{d3d12_submit_ok})")
        }
      }
    }
  }

  // --- 3. VK_KHR_external_fence_win32: export / import / signal / wait ---
  if has_fence_win32 {
    let efi = @vk.VkPhysicalDeviceExternalFenceInfo::new()
    efi.set_handleType(@vk.VK_EXTERNAL_FENCE_HANDLE_TYPE_OPAQUE_WIN32_BIT)
    let efp = @vk.VkExternalFenceProperties::new()
    (ifn.vkGetPhysicalDeviceExternalFenceProperties)(phys, efi, efp)
    probed = probed + 1
    let ffeats = efp.get_externalFenceFeatures()
    efi.free()
    efp.free()
    if (ffeats & @vk.VK_EXTERNAL_MEMORY_FEATURE_EXPORTABLE_BIT) != 0 &&
      (ffeats & @vk.VK_EXTERNAL_MEMORY_FEATURE_IMPORTABLE_BIT) != 0 {
      let efc = @vk.VkExportFenceCreateInfo::new()
      efc.set_handleTypes(@vk.VK_EXTERNAL_FENCE_HANDLE_TYPE_OPAQUE_WIN32_BIT)
      let efw = @vk.VkExportFenceWin32HandleInfoKHR::new()
      efw.set_dwAccess((0x10000000 : UInt32))
      efw.set_name(@vk.wstr("TychoWin32InteropFence"))
      efc.set_pNext(efw.as_ptr())
      let fci = @vk.VkFenceCreateInfo::new()
      fci.set_pNext(efc.as_ptr())
      let fa_out = FixedArray::make(1, @vk.VkFence::null())
      let far = (dfn.vkCreateFence)(dev, fci, na, fa_out)
      probed = probed + 1
      fci.set_pNext((0 : UInt64))
      let fb_out = FixedArray::make(1, @vk.VkFence::null())
      let fbr = (dfn.vkCreateFence)(dev, fci, na, fb_out)
      probed = probed + 1
      let fc_out = FixedArray::make(1, @vk.VkFence::null())
      let fcr = (dfn.vkCreateFence)(dev, fci, na, fc_out)
      probed = probed + 1
      fci.free()
      efc.free()
      efw.free()
      let mut fence_ok = false
      if far == 0 && fbr == 0 && fcr == 0 {
        let fghi = @vk.VkFenceGetWin32HandleInfoKHR::new()
        fghi.set_fence(fa_out[0])
        fghi.set_handleType(@vk.VK_EXTERNAL_FENCE_HANDLE_TYPE_OPAQUE_WIN32_BIT)
        let fh_out = FixedArray::make(1, (0 : UInt64))
        let fhr = (dfn.vkGetFenceWin32HandleKHR)(dev, fghi, fh_out)
        probed = probed + 1
        fghi.free()
        let ifw = @vk.VkImportFenceWin32HandleInfoKHR::new()
        ifw.set_fence(fb_out[0])
        ifw.set_handleType(@vk.VK_EXTERNAL_FENCE_HANDLE_TYPE_OPAQUE_WIN32_BIT)
        ifw.set_handle(fh_out[0])
        let fir = (dfn.vkImportFenceWin32HandleKHR)(dev, ifw)
        probed = probed + 1
        ifw.free()
        // Second import path: open the named object (LPCWSTR).
        let ifn_info = @vk.VkImportFenceWin32HandleInfoKHR::new()
        ifn_info.set_fence(fc_out[0])
        ifn_info.set_handleType(@vk.VK_EXTERNAL_FENCE_HANDLE_TYPE_OPAQUE_WIN32_BIT)
        ifn_info.set_name(@vk.wstr("TychoWin32InteropFence"))
        let fir2 = (dfn.vkImportFenceWin32HandleKHR)(dev, ifn_info)
        probed = probed + 1
        ifn_info.free()
        if fhr == 0 && fir == 0 && fir2 == 0 {
          let sig = @vk.VkSubmitInfo::new()
          let r1 = (dfn.vkQueueSubmit)(queue, (1 : UInt32), sig, fb_out[0])
          probed = probed + 1
          sig.free()
          let fences = FixedArray::make(1, fa_out[0])
          let r2 = (dfn.vkWaitForFences)(dev, (1 : UInt32), fences, (1 : UInt32), (5000000000 : UInt64))
          probed = probed + 1
          let r3 = (dfn.vkResetFences)(dev, (1 : UInt32), fences)
          probed = probed + 1
          // The named import shares the payload: it must be reset too.
          let fences_c = FixedArray::make(1, fc_out[0])
          let r4 = (dfn.vkWaitForFences)(dev, (1 : UInt32), fences_c, (1 : UInt32), (0 : UInt64))
          probed = probed + 1
          fence_ok = r1 == 0 && r2 == 0 && r3 == 0 && r4 == 0
        }
        (dfn.vkDestroyFence)(dev, fc_out[0], na)
        probed = probed + 1
        (dfn.vkDestroyFence)(dev, fb_out[0], na)
        probed = probed + 1
        if fh_out[0] != (0 : UInt64) {
          @vk.win32_close_handle(fh_out[0])
        }
      }
      (dfn.vkDestroyFence)(dev, fa_out[0], na)
      probed = probed + 1
      if fence_ok {
        sections = sections + 1
      } else {
        println("[vulkan/win32-interop] FAIL — fence win32 round-trip")
      }
    }
  }

  // --- 4. VK_NV_external_memory_capabilities + VK_NV_external_memory_win32 ---
  if has_nv_mem {
    let nv_props = @vk.VkExternalImageFormatPropertiesNV::new()
    let nvr = (ifn.vkGetPhysicalDeviceExternalImageFormatPropertiesNV)(
      phys,
      @vk.VK_FORMAT_R8G8B8A8_UNORM,
      @vk.VK_IMAGE_TYPE_2D,
      @vk.VK_IMAGE_TILING_OPTIMAL,
      @vk.VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT | @vk.VK_IMAGE_USAGE_SAMPLED_BIT,
      (0 : UInt32),
      @vk.VK_EXTERNAL_MEMORY_HANDLE_TYPE_OPAQUE_WIN32_BIT_NV,
      nv_props,
    )
    probed = probed + 1
    let nv_feats = nv_props.get_externalMemoryFeatures()
    nv_props.free()
    let mut nv_ok = nvr == 0
    if nvr == 0 && (nv_feats & @vk.VK_EXTERNAL_MEMORY_FEATURE_EXPORTABLE_BIT_NV) != 0 {
      let ici_nv = @vk.VkImageCreateInfo::new()
      ici_nv.set_imageType(@vk.VK_IMAGE_TYPE_2D)
      ici_nv.set_format(@vk.VK_FORMAT_R8G8B8A8_UNORM)
      let ext = @vk.VkExtent3D::new()
      ext.set_width((64 : UInt32))
      ext.set_height((64 : UInt32))
      ext.set_depth((1 : UInt32))
      ici_nv.set_extent(ext)
      ici_nv.set_mipLevels((1 : UInt32))
      ici_nv.set_arrayLayers((1 : UInt32))
      ici_nv.set_samples(@vk.VK_SAMPLE_COUNT_1_BIT)
      ici_nv.set_tiling(@vk.VK_IMAGE_TILING_OPTIMAL)
      ici_nv.set_usage(@vk.VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT | @vk.VK_IMAGE_USAGE_SAMPLED_BIT)
      ici_nv.set_sharingMode(@vk.VK_SHARING_MODE_EXCLUSIVE)
      ici_nv.set_initialLayout(@vk.VK_IMAGE_LAYOUT_UNDEFINED)
      let emi_nv = @vk.VkExternalMemoryImageCreateInfoNV::new()
      emi_nv.set_handleTypes(@vk.VK_EXTERNAL_MEMORY_HANDLE_TYPE_OPAQUE_WIN32_BIT_NV)
      ici_nv.set_pNext(emi_nv.as_ptr())
      let img_out = FixedArray::make(1, @vk.VkImage::null())
      let imr = (dfn.vkCreateImage)(dev, ici_nv, na, img_out)
      probed = probed + 1
      ici_nv.free()
      emi_nv.free()
      ext.free()
      if imr == 0 {
        let ireq = @vk.VkMemoryRequirements::new()
        (dfn.vkGetImageMemoryRequirements)(dev, img_out[0], ireq)
        probed = probed + 1
        let imt = mem_type(phys, ifn, ireq.get_memoryTypeBits(), (0 : UInt32))
        let asz = ireq.get_size()
        ireq.free()
        if imt >= 0 {
          let ema_nv = @vk.VkExportMemoryAllocateInfoNV::new()
          ema_nv.set_handleTypes(@vk.VK_EXTERNAL_MEMORY_HANDLE_TYPE_OPAQUE_WIN32_BIT_NV)
          let mai_nv = @vk.VkMemoryAllocateInfo::new()
          mai_nv.set_allocationSize(asz)
          mai_nv.set_memoryTypeIndex(imt.reinterpret_as_uint())
          mai_nv.set_pNext(ema_nv.as_ptr())
          let imem_out = FixedArray::make(1, @vk.VkDeviceMemory::null())
          let iar = (dfn.vkAllocateMemory)(dev, mai_nv, na, imem_out)
          probed = probed + 1
          mai_nv.free()
          ema_nv.free()
          if iar == 0 {
            let _ = (dfn.vkBindImageMemory)(dev, img_out[0], imem_out[0], (0 : UInt64))
            probed = probed + 1
            let nh_out = FixedArray::make(1, (0 : UInt64))
            let nhr = (dfn.vkGetMemoryWin32HandleNV)(
              dev,
              imem_out[0],
              @vk.VK_EXTERNAL_MEMORY_HANDLE_TYPE_OPAQUE_WIN32_BIT_NV,
              nh_out,
            )
            probed = probed + 1
            nv_ok = nhr == 0 && nh_out[0] != (0 : UInt64)
            if nh_out[0] != (0 : UInt64) {
              @vk.win32_close_handle(nh_out[0])
            }
            (dfn.vkFreeMemory)(dev, imem_out[0], na)
            probed = probed + 1
          }
        }
        (dfn.vkDestroyImage)(dev, img_out[0], na)
        probed = probed + 1
      }
    }
    if nv_ok {
      sections = sections + 1
    } else {
      println("[vulkan/win32-interop] FAIL — NV external memory win32 path")
    }
  }

  // --- 5. VK_EXT_full_screen_exclusive: present modes 2 + acquire/release ---
  if has_fse {
    let caps = @vk.VkSurfaceCapabilitiesKHR::new()
    let _ = (ifn.vkGetPhysicalDeviceSurfaceCapabilitiesKHR)(phys, surface, caps)
    probed = probed + 1
    let fc = FixedArray::make(1, (0 : UInt32))
    let _ = (ifn.vkGetPhysicalDeviceSurfaceFormatsKHR)(
      phys,
      surface,
      fc,
      @vk.VkSurfaceFormatKHR::null(),
    )
    let formats = @vk.VkSurfaceFormatKHR::array(fc[0].reinterpret_as_int())
    let _ = (ifn.vkGetPhysicalDeviceSurfaceFormatsKHR)(phys, surface, fc, formats)
    probed = probed + 1
    let fse_win32 = @vk.VkSurfaceFullScreenExclusiveWin32InfoEXT::new()
    fse_win32.set_hmonitor(hmon)
    let info2 = @vk.VkPhysicalDeviceSurfaceInfo2KHR::new()
    info2.set_surface(surface)
    info2.set_pNext(fse_win32.as_ptr())
    let fse_caps = @vk.VkSurfaceCapabilitiesFullScreenExclusiveEXT::new()
    let caps2 = @vk.VkSurfaceCapabilities2KHR::new()
    caps2.set_pNext(fse_caps.as_ptr())
    let _ = (ifn.vkGetPhysicalDeviceSurfaceCapabilities2KHR)(phys, info2, caps2)
    probed = probed + 1
    let fse_supported = fse_caps.get_fullScreenExclusiveSupported() != 0
    caps2.free()
    fse_caps.free()
    let pmc = FixedArray::make(1, (16 : UInt32))
    let modes2 = FixedArray::make(16, (0 : UInt32))
    let pmr2 = (ifn.vkGetPhysicalDeviceSurfacePresentModes2EXT)(phys, info2, pmc, modes2)
    probed = probed + 1
    let npm = pmc[0].reinterpret_as_int()
    let gpm = FixedArray::make(1, (0 : UInt32))
    let gpmr = (dfn.vkGetDeviceGroupSurfacePresentModes2EXT)(dev, info2, gpm)
    probed = probed + 1
    let mut fse_ok = pmr2 == 0 && gpmr == 0 && npm > 0
    if fse_supported {
      let fse_info = @vk.VkSurfaceFullScreenExclusiveInfoEXT::new()
      fse_info.set_fullScreenExclusive(@vk.VK_FULL_SCREEN_EXCLUSIVE_APPLICATION_CONTROLLED_EXT)
      fse_info.set_pNext(fse_win32.as_ptr())
      let swci = @vk.VkSwapchainCreateInfoKHR::new()
      swci.set_surface(surface)
      swci.set_minImageCount(caps.get_minImageCount())
      swci.set_imageFormat(formats.get_format_at(0))
      swci.set_imageColorSpace(formats.get_colorSpace_at(0))
      let extent = @vk.VkExtent2D::new()
      let cw = caps.get_currentExtent().get_width()
      let ch = caps.get_currentExtent().get_height()
      extent.set_width(if cw != (0xFFFFFFFF : UInt32) { cw } else { (64 : UInt32) })
      extent.set_height(if ch != (0xFFFFFFFF : UInt32) { ch } else { (64 : UInt32) })
      swci.set_imageExtent(extent)
      swci.set_imageArrayLayers((1 : UInt32))
      swci.set_imageUsage(@vk.VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT)
      swci.set_imageSharingMode(@vk.VK_SHARING_MODE_EXCLUSIVE)
      swci.set_preTransform(caps.get_currentTransform())
      swci.set_compositeAlpha(@vk.VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR)
      swci.set_presentMode(@vk.VK_PRESENT_MODE_FIFO_KHR)
      swci.set_clipped((1 : UInt32))
      swci.set_pNext(fse_info.as_ptr())
      let sc_out = FixedArray::make(1, @vk.VkSwapchainKHR::null())
      let scr = (dfn.vkCreateSwapchainKHR)(dev, swci, na, sc_out)
      probed = probed + 1
      swci.free()
      fse_info.free()
      extent.free()
      if scr == 0 {
        // Acquire/release may legitimately fail on a headless/occluded window;
        // the commands are still exercised and must not raise validation errors.
        let _ = (dfn.vkAcquireFullScreenExclusiveModeEXT)(dev, sc_out[0])
        probed = probed + 1
        let _ = (dfn.vkReleaseFullScreenExclusiveModeEXT)(dev, sc_out[0])
        probed = probed + 1
        (dfn.vkDestroySwapchainKHR)(dev, sc_out[0], na)
        probed = probed + 1
      } else {
        fse_ok = false
        println("[vulkan/win32-interop] FAIL — FSE swapchain creation=\{scr}")
      }
    }
    caps.free()
    formats.free()
    info2.free()
    fse_win32.free()
    if fse_ok {
      sections = sections + 1
    } else {
      println("[vulkan/win32-interop] FAIL — full-screen-exclusive queries")
    }
  }

  // --- 6. VK_NV_acquire_winrt_display ---
  // vkGetWinrtDisplayNV is always safe. vkAcquireWinrtDisplayNV is opt-in
  // (TYCHO_WINRT_ACQUIRE=1): acquiring a WinRT display that is still owned by
  // the desktop crashes some drivers (NVIDIA access-violates) instead of
  // returning an error, so it must not run unattended in CI.
  if has_nv_winrt {
    let disp_out = FixedArray::make(1, @vk.VkDisplayKHR::null())
    let gwr = (ifn.vkGetWinrtDisplayNV)(phys, (0 : UInt32), disp_out)
    probed = probed + 1
    let want_acquire = match @env.get_env_var("TYCHO_WINRT_ACQUIRE") {
      Some(v) => v == "1" || v.equal_ignore_ascii_case("true")
      None => false
    }
    if gwr == 0 && want_acquire {
      let _ = (ifn.vkAcquireWinrtDisplayNV)(phys, disp_out[0])
      probed = probed + 1
    }
    sections = sections + 1
  }

  // --- 7. VK_NV_external_compute_queue ---
  if has_nv_ecq {
    let ecqi = @vk.VkExternalComputeQueueCreateInfoNV::new()
    ecqi.set_preferredQueue(queue)
    let ecq_out = FixedArray::make(1, @vk.VkExternalComputeQueueNV::null())
    let ecr = (dfn.vkCreateExternalComputeQueueNV)(dev, ecqi, na, ecq_out)
    probed = probed + 1
    ecqi.free()
    if ecr == 0 {
      let params = @vk.VkExternalComputeQueueDataParamsNV::new()
      params.set_deviceIndex((0 : UInt32))
      let data = @vk.aligned_alloc(256, 8)
      (dfn.vkGetExternalComputeQueueDataNV)(ecq_out[0], params, data)
      probed = probed + 1
      @vk.free_ptr(data)
      params.free()
      (dfn.vkDestroyExternalComputeQueueNV)(dev, ecq_out[0], na)
      probed = probed + 1
      sections = sections + 1
    }
  }

  // --- 8. Win32 keyed mutex structs (KHR + NV): layout verification ---
  let km_khr = @vk.VkWin32KeyedMutexAcquireReleaseInfoKHR::new()
  km_khr.set_acquireCount((0 : UInt32))
  km_khr.set_releaseCount((0 : UInt32))
  km_khr.set_pAcquireSyncs(FixedArray::make(0, @vk.VkDeviceMemory::null()))
  km_khr.set_pAcquireKeys(FixedArray::make(0, (0 : UInt64)))
  km_khr.set_pAcquireTimeouts(FixedArray::make(0, (0 : UInt32)))
  km_khr.set_pReleaseSyncs(FixedArray::make(0, @vk.VkDeviceMemory::null()))
  km_khr.set_pReleaseKeys(FixedArray::make(0, (0 : UInt64)))
  km_khr.set_acquireCount((2 : UInt32))
  km_khr.set_releaseCount((3 : UInt32))
  let km_khr_ok = km_khr.get_acquireCount() == (2 : UInt32) &&
    km_khr.get_releaseCount() == (3 : UInt32)
  km_khr.free()
  let km_nv = @vk.VkWin32KeyedMutexAcquireReleaseInfoNV::new()
  km_nv.set_acquireCount((2 : UInt32))
  km_nv.set_releaseCount((3 : UInt32))
  let km_nv_ok = km_nv.get_acquireCount() == (2 : UInt32) &&
    km_nv.get_releaseCount() == (3 : UInt32)
  km_nv.free()
  if km_khr_ok && km_nv_ok {
    sections = sections + 1
  } else {
    println("[vulkan/win32-interop] FAIL — keyed mutex struct layout")
  }

  // --- Cleanup + verdict ---
  let _ = (dfn.vkQueueWaitIdle)(queue)
  probed = probed + 1
  (ifn.vkDestroySurfaceKHR)(inst, surface, na)
  probed = probed + 1
  (dfn.vkDestroyDevice)(dev, na)
  @vk.destroy_debug_messenger(inst, ifn, messenger)
  (ifn.vkDestroyInstance)(inst, na)
  @win.destroy(win)
  @win.terminate()
  dci.free()
  qci.free()
  f2.free()
  f12.free()
  ici.free()
  app.free()
  println("[vulkan/win32-interop] commands=\{probed} sections=\{sections} errors=\{g_errors.val}")
  if g_errors.val != 0 {
    println("[vulkan/win32-interop] FAIL — \{g_errors.val} validation errors, commands=\{probed}")
  } else if probed == 0 {
    println("[vulkan/win32-interop] SKIP — no Windows interop commands invoked")
  } else {
    println("[vulkan/win32-interop] OK — \{probed} Windows interop commands in \{sections} sections, 0 validation errors")
  }
}
