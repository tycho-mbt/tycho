// dx12/vulkan-interop — Live Windows DX12 <-> Vulkan shared memory & fence interop.
//
// Exercises:
// - Adapter LUID matching (ID3D12Device::GetAdapterLuid == VkPhysicalDeviceIDProperties::deviceLUID)
// - D3D12_HEAP_FLAG_SHARED texture -> CreateSharedHandle / OpenSharedHandle / OpenSharedHandleByName
// - Vulkan vkGetMemoryWin32HandlePropertiesKHR(D3D12_RESOURCE_BIT) + dedicated VkImage import
// - D3D12_FENCE_FLAG_SHARED fence <-> Vulkan timeline VkSemaphore cross-API signal/wait round-trip
//
// Asserts zero D3D12 debug-layer errors and zero Khronos Vulkan validation errors.
// Non-Windows hosts or runners without a matching hardware LUID pair report SKIP.

let na : @vk.VkAllocationCallbacks = @vk.VkAllocationCallbacks::null()

let vk_errors : Ref[Int] = Ref(0)

// Program-lifetime buffers so raw pointers passed to DX12 thunks stay valid.
let luid_buf : FixedArray[Byte] = FixedArray::make(8, (0 : Byte))

let heap_props : FixedArray[Int32] = [1, 0, 0, 0, 0] // DEFAULT heap

// D3D12_RESOURCE_DESC: 64x64 RGBA8 2D, ALLOW_RENDER_TARGET (1) | ALLOW_SIMULTANEOUS_ACCESS (32) = 0x21.
let shared_tex_desc : FixedArray[Byte] = [
  0x03, 0x00, 0x00, 0x00, // Dimension = TEXTURE2D
  0x00, 0x00, 0x00, 0x00, // pad
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // Alignment = 0
  0x40, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // Width = 64
  0x40, 0x00, 0x00, 0x00, // Height = 64
  0x01, 0x00, // DepthOrArraySize = 1
  0x01, 0x00, // MipLevels = 1
  0x1c, 0x00, 0x00, 0x00, // Format = R8G8B8A8_UNORM (28)
  0x01, 0x00, 0x00, 0x00, // SampleDesc.Count = 1
  0x00, 0x00, 0x00, 0x00, // SampleDesc.Quality = 0
  0x00, 0x00, 0x00, 0x00, // Layout = UNKNOWN
  0x21, 0x00, 0x00, 0x00, // Flags = ALLOW_RENDER_TARGET | ALLOW_SIMULTANEOUS_ACCESS
  0x00, 0x00, 0x00, 0x00, // pad
]

let queue_desc : FixedArray[Int32] = [0, 0, 0, 0] // DIRECT

let tex_name : FixedArray[Byte] = @dx12.to_utf16("Local\\TychoDxVkSharedTex2026")

let fence_name : FixedArray[Byte] = @dx12.to_utf16("Local\\TychoDxVkSharedFence2026")

///|
fn ext_in(props : @vk.VkExtensionProperties, count : Int, name : String) -> Bool {
  for i = 0; i < count; i = i + 1 {
    if props.get_extensionName_string_at(i) == name {
      return true
    }
  }
  false
}

///|
fn mem_type(
  phys : @vk.VkPhysicalDevice,
  ifn : @vk.InstanceFn,
  bits : UInt32,
) -> Int {
  let mp = @vk.VkPhysicalDeviceMemoryProperties::new()
  (ifn.vkGetPhysicalDeviceMemoryProperties)(phys, mp)
  let n = mp.get_memoryTypeCount().reinterpret_as_int()
  let mut found = -1
  for i = 0; i < n; i = i + 1 {
    if (bits & ((1 : UInt32) << i)) != 0 {
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
      println("[dx12/vulkan-interop] SKIP — Windows-only suite")
      return
    }
  }
  if !@dx12.available() {
    println("[dx12/vulkan-interop] SKIP — d3d12.dll / dxgi.dll unavailable")
    return
  }
  if @dx12.env_requests_warp() {
    println("[dx12/vulkan-interop] SKIP — TYCHO_DX12_WARP=1 (requires hardware LUID match)")
    return
  }
  let dx_dev = match @dx12.Device::create(warp=false, debug=true) {
    Some(d) => d
    None => {
      println("[dx12/vulkan-interop] SKIP — no hardware D3D12 device")
      return
    }
  }
  let raw_dev = dx_dev.raw()
  let _ = @dx12.dx_d3d12_device_get_adapter_luid(raw_dev, @dx12.bytes_ptr(luid_buf))

  // Check Vulkan validation + required instance extensions.
  let lc = FixedArray::make(1, (0 : UInt32))
  let _ = @vk.vkEnumerateInstanceLayerProperties(lc, @vk.VkLayerProperties::null())
  let layers = @vk.VkLayerProperties::array(lc[0].reinterpret_as_int())
  let _ = @vk.vkEnumerateInstanceLayerProperties(lc, layers)
  let mut has_val = false
  for i = 0; i < lc[0].reinterpret_as_int(); i = i + 1 {
    if layers.get_layerName_string_at(i) == "VK_LAYER_KHRONOS_validation" {
      has_val = true
    }
  }
  layers.free()
  if !has_val {
    dx_dev.destroy()
    println("[dx12/vulkan-interop] SKIP — VK_LAYER_KHRONOS_validation unavailable")
    return
  }

  let iec = FixedArray::make(1, (0 : UInt32))
  let _ = @vk.vkEnumerateInstanceExtensionProperties((0 : UInt64), iec, @vk.VkExtensionProperties::null())
  let iexts = @vk.VkExtensionProperties::array(iec[0].reinterpret_as_int())
  let _ = @vk.vkEnumerateInstanceExtensionProperties((0 : UInt64), iec, iexts)
  let icount = iec[0].reinterpret_as_int()
  let need_i : FixedArray[String] = [
    "VK_EXT_debug_utils",
    "VK_KHR_get_physical_device_properties2",
    "VK_KHR_external_memory_capabilities",
    "VK_KHR_external_semaphore_capabilities",
  ]
  for name in need_i {
    if !ext_in(iexts, icount, name) {
      iexts.free()
      dx_dev.destroy()
      println("[dx12/vulkan-interop] SKIP — missing Vulkan instance extension \{name}")
      return
    }
  }
  iexts.free()

  let app = @vk.VkApplicationInfo::new()
  app.set_pApplicationName(@vk.cstr("TychoDxVkInterop"))
  app.set_apiVersion((4206592 : UInt32)) // 1.3
  let ici = @vk.VkInstanceCreateInfo::new()
  ici.set_pApplicationInfo(app)
  ici.set_enabledLayerCount((1 : UInt32))
  ici.set_ppEnabledLayerNames(@vk.cstr_array(["VK_LAYER_KHRONOS_validation"]))
  ici.set_enabledExtensionCount((4 : UInt32))
  ici.set_ppEnabledExtensionNames(@vk.cstr_array(need_i))
  let inst_out = FixedArray::make(1, @vk.VkInstance::null())
  if @vk.vkCreateInstance(ici, na, inst_out) != 0 {
    app.free()
    ici.free()
    dx_dev.destroy()
    println("[dx12/vulkan-interop] SKIP — vkCreateInstance failed")
    return
  }
  app.free()
  ici.free()
  let inst = inst_out[0]
  let ifn = @vk.InstanceFn::load(inst)
  let messenger = @vk.create_debug_messenger(
    inst,
    ifn,
    @vk.VK_DEBUG_UTILS_MESSAGE_SEVERITY_ERROR_BIT_EXT,
    @vk.VK_DEBUG_UTILS_MESSAGE_TYPE_VALIDATION_BIT_EXT,
    (_sev, _ty, data, _ud) => {
      vk_errors.val = vk_errors.val + 1
      println("[dx12/vulkan-interop] VK VALIDATION: \{@vk.read_cstr(data.get_pMessage())}")
      (0 : UInt32)
    },
  )

  // Find Vulkan physical device whose deviceLUID matches the DX12 adapter LUID.
  let pc = FixedArray::make(1, (16 : UInt32))
  let devs = FixedArray::make(16, @vk.VkPhysicalDevice::null())
  let _ = (ifn.vkEnumeratePhysicalDevices)(inst, pc, devs)
  let ndev = pc[0].reinterpret_as_int()
  let mut phys = @vk.VkPhysicalDevice::null()
  for i = 0; i < ndev; i = i + 1 {
    let idp = @vk.VkPhysicalDeviceIDProperties::new()
    let p2 = @vk.VkPhysicalDeviceProperties2::new()
    p2.set_pNext(idp.as_ptr())
    (ifn.vkGetPhysicalDeviceProperties2)(devs[i], p2)
    let api = p2.get_properties().get_apiVersion()
    let valid = idp.get_deviceLUIDValid() != 0
    let dluid = idp.get_deviceLUID()
    let mut same = valid && dluid.length() >= 8
    if same {
      for b = 0; b < 8; b = b + 1 {
        if dluid[b] != luid_buf[b] {
          same = false
          break
        }
      }
    }
    idp.free()
    p2.free()
    if same && api >= (4206592 : UInt32) {
      phys = devs[i]
      break
    }
  }
  if phys.as_ptr() == (0 : UInt64) {
    @vk.destroy_debug_messenger(inst, ifn, messenger)
    (ifn.vkDestroyInstance)(inst, na)
    dx_dev.destroy()
    println("[dx12/vulkan-interop] SKIP — no Vulkan physical device matches DX12 adapter LUID")
    return
  }

  let dec = FixedArray::make(1, (0 : UInt32))
  let _ = (ifn.vkEnumerateDeviceExtensionProperties)(phys, (0 : UInt64), dec, @vk.VkExtensionProperties::null())
  let dexts = @vk.VkExtensionProperties::array(dec[0].reinterpret_as_int())
  let _ = (ifn.vkEnumerateDeviceExtensionProperties)(phys, (0 : UInt64), dec, dexts)
  let dcount = dec[0].reinterpret_as_int()
  let need_d : FixedArray[String] = [
    "VK_KHR_external_memory",
    "VK_KHR_external_memory_win32",
    "VK_KHR_external_semaphore",
    "VK_KHR_external_semaphore_win32",
    "VK_KHR_timeline_semaphore",
    "VK_KHR_dedicated_allocation",
  ]
  for name in need_d {
    if !ext_in(dexts, dcount, name) {
      dexts.free()
      @vk.destroy_debug_messenger(inst, ifn, messenger)
      (ifn.vkDestroyInstance)(inst, na)
      dx_dev.destroy()
      println("[dx12/vulkan-interop] SKIP — missing Vulkan device extension \{name}")
      return
    }
  }
  dexts.free()

  let f12q = @vk.VkPhysicalDeviceVulkan12Features::new()
  let f2q = @vk.VkPhysicalDeviceFeatures2::new()
  f2q.set_pNext(f12q.as_ptr())
  (ifn.vkGetPhysicalDeviceFeatures2)(phys, f2q)
  let has_tl = f12q.get_timelineSemaphore() != 0
  f12q.free()
  f2q.free()
  if !has_tl {
    @vk.destroy_debug_messenger(inst, ifn, messenger)
    (ifn.vkDestroyInstance)(inst, na)
    dx_dev.destroy()
    println("[dx12/vulkan-interop] SKIP — timelineSemaphore unsupported")
    return
  }

  // Pick a graphics/compute queue family.
  let qfc = FixedArray::make(1, (0 : UInt32))
  (ifn.vkGetPhysicalDeviceQueueFamilyProperties)(phys, qfc, @vk.VkQueueFamilyProperties::null())
  let qfps = @vk.VkQueueFamilyProperties::array(qfc[0].reinterpret_as_int())
  (ifn.vkGetPhysicalDeviceQueueFamilyProperties)(phys, qfc, qfps)
  let mut qfam = 0
  for i = 0; i < qfc[0].reinterpret_as_int(); i = i + 1 {
    if (qfps.get_queueFlags_at(i) & @vk.VK_QUEUE_GRAPHICS_BIT) != 0 {
      qfam = i
      break
    }
  }
  qfps.free()

  let f12 = @vk.VkPhysicalDeviceVulkan12Features::new()
  f12.set_timelineSemaphore((1 : UInt32))
  let f2 = @vk.VkPhysicalDeviceFeatures2::new()
  f2.set_pNext(f12.as_ptr())
  let prio = FixedArray::make(1, (1.0 : Float))
  let qci = @vk.VkDeviceQueueCreateInfo::new()
  qci.set_queueFamilyIndex(qfam.reinterpret_as_uint())
  qci.set_queueCount((1 : UInt32))
  qci.set_pQueuePriorities(prio)
  let dci = @vk.VkDeviceCreateInfo::new()
  dci.set_queueCreateInfoCount((1 : UInt32))
  dci.set_pQueueCreateInfos(qci)
  dci.set_enabledExtensionCount((6 : UInt32))
  dci.set_ppEnabledExtensionNames(@vk.cstr_array(need_d))
  dci.set_pNext(f2.as_ptr())
  let vk_dev_out = FixedArray::make(1, @vk.VkDevice::null())
  let dr = (ifn.vkCreateDevice)(phys, dci, na, vk_dev_out)
  f12.free()
  f2.free()
  qci.free()
  dci.free()
  if dr != 0 {
    @vk.destroy_debug_messenger(inst, ifn, messenger)
    (ifn.vkDestroyInstance)(inst, na)
    dx_dev.destroy()
    println("[dx12/vulkan-interop] FAIL — vkCreateDevice=\{dr}")
    return
  }
  let vk_dev = vk_dev_out[0]
  let dfn = @vk.DeviceFn::load(vk_dev)
  let vk_q_out = FixedArray::make(1, @vk.VkQueue::null())
  (dfn.vkGetDeviceQueue)(vk_dev, qfam.reinterpret_as_uint(), (0 : UInt32), vk_q_out)
  let vk_queue = vk_q_out[0]

  let mut ok = true
  let mut dx_calls = 0
  let mut vk_calls = 0

  // --- 1. D3D12 Shared Resource -> Vulkan External Memory Import ---
  let tex_out = FixedArray::make(1, (0 : Int64))
  let hr_tex = @dx12.dx_d3d12_device_create_committed_resource(
    raw_dev,
    @dx12.int32_ptr(heap_props),
    0x1, // D3D12_HEAP_FLAG_SHARED
    @dx12.bytes_ptr(shared_tex_desc),
    0, // COMMON
    (0 : UInt64),
    @dx12.bytes_ptr(@dx12.iid_d3d12_resource),
    @dx12.int64_ptr(tex_out),
  )
  dx_calls = dx_calls + 1
  if hr_tex == 0 && tex_out[0] != (0 : Int64) {
    let d3d_tex = tex_out[0].reinterpret_as_uint64()
    let h_out = FixedArray::make(1, (0 : Int64))
    let hr_sh = @dx12.dx_d3d12_device_create_shared_handle(
      raw_dev,
      d3d_tex,
      (0 : UInt64),
      0x10000000, // GENERIC_ALL
      @dx12.bytes_ptr(tex_name),
      @dx12.int64_ptr(h_out),
    )
    dx_calls = dx_calls + 1
    let h_tex = h_out[0].reinterpret_as_uint64()
    if hr_sh == 0 && h_tex != (0 : UInt64) {
      // Exercise OpenSharedHandle & OpenSharedHandleByName on DX12 too.
      let opened_out = FixedArray::make(1, (0 : Int64))
      let hr_open = @dx12.dx_d3d12_device_open_shared_handle(
        raw_dev,
        h_tex,
        @dx12.bytes_ptr(@dx12.iid_d3d12_resource),
        @dx12.int64_ptr(opened_out),
      )
      dx_calls = dx_calls + 1
      ok = ok && hr_open == 0 && opened_out[0] != (0 : Int64)
      if opened_out[0] != (0 : Int64) {
        let _ = @dx12.com_release(opened_out[0].reinterpret_as_uint64())
      }
      let named_h_out = FixedArray::make(1, (0 : Int64))
      let hr_by_name = @dx12.dx_d3d12_device_open_shared_handle_by_name(
        raw_dev,
        @dx12.bytes_ptr(tex_name),
        0x10000000,
        @dx12.int64_ptr(named_h_out),
      )
      dx_calls = dx_calls + 1
      ok = ok && hr_by_name == 0 && named_h_out[0] != (0 : Int64)
      if named_h_out[0] != (0 : Int64) {
        @dx12.close_handle(named_h_out[0].reinterpret_as_uint64())
      }

      // Vulkan side: query handle properties + dedicated VkImage import.
      let mwp = @vk.VkMemoryWin32HandlePropertiesKHR::new()
      let pr = (dfn.vkGetMemoryWin32HandlePropertiesKHR)(
        vk_dev,
        @vk.VK_EXTERNAL_MEMORY_HANDLE_TYPE_D3D12_RESOURCE_BIT,
        h_tex,
        mwp,
      )
      vk_calls = vk_calls + 1
      let handle_bits = mwp.get_memoryTypeBits()
      mwp.free()
      ok = ok && pr == 0 && handle_bits != (0 : UInt32)

      let emi = @vk.VkExternalMemoryImageCreateInfo::new()
      emi.set_handleTypes(@vk.VK_EXTERNAL_MEMORY_HANDLE_TYPE_D3D12_RESOURCE_BIT)
      let ext3 = @vk.VkExtent3D::new()
      ext3.set_width((64 : UInt32))
      ext3.set_height((64 : UInt32))
      ext3.set_depth((1 : UInt32))
      let imci = @vk.VkImageCreateInfo::new()
      imci.set_imageType(@vk.VK_IMAGE_TYPE_2D)
      imci.set_format(@vk.VK_FORMAT_R8G8B8A8_UNORM)
      imci.set_extent(ext3)
      imci.set_mipLevels((1 : UInt32))
      imci.set_arrayLayers((1 : UInt32))
      imci.set_samples(@vk.VK_SAMPLE_COUNT_1_BIT)
      imci.set_tiling(@vk.VK_IMAGE_TILING_OPTIMAL)
      imci.set_usage(@vk.VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT | @vk.VK_IMAGE_USAGE_TRANSFER_SRC_BIT)
      imci.set_sharingMode(@vk.VK_SHARING_MODE_EXCLUSIVE)
      imci.set_initialLayout(@vk.VK_IMAGE_LAYOUT_UNDEFINED)
      imci.set_pNext(emi.as_ptr())
      let vk_img_out = FixedArray::make(1, @vk.VkImage::null())
      let ir = (dfn.vkCreateImage)(vk_dev, imci, na, vk_img_out)
      vk_calls = vk_calls + 1
      emi.free()
      ext3.free()
      imci.free()
      if ir == 0 {
        let vk_img = vk_img_out[0]
        let req = @vk.VkMemoryRequirements::new()
        (dfn.vkGetImageMemoryRequirements)(vk_dev, vk_img, req)
        vk_calls = vk_calls + 1
        let mt = mem_type(phys, ifn, req.get_memoryTypeBits() & handle_bits)
        let sz = req.get_size()
        req.free()
        if mt >= 0 {
          let imp = @vk.VkImportMemoryWin32HandleInfoKHR::new()
          imp.set_handleType(@vk.VK_EXTERNAL_MEMORY_HANDLE_TYPE_D3D12_RESOURCE_BIT)
          imp.set_handle(h_tex)
          let ded = @vk.VkMemoryDedicatedAllocateInfo::new()
          ded.set_image(vk_img)
          imp.set_pNext(ded.as_ptr())
          let mai = @vk.VkMemoryAllocateInfo::new()
          mai.set_allocationSize(sz)
          mai.set_memoryTypeIndex(mt.reinterpret_as_uint())
          mai.set_pNext(imp.as_ptr())
          let mem_out = FixedArray::make(1, @vk.VkDeviceMemory::null())
          let ar = (dfn.vkAllocateMemory)(vk_dev, mai, na, mem_out)
          vk_calls = vk_calls + 1
          imp.free()
          ded.free()
          mai.free()
          if ar == 0 {
            let br = (dfn.vkBindImageMemory)(vk_dev, vk_img, mem_out[0], (0 : UInt64))
            vk_calls = vk_calls + 1
            ok = ok && br == 0
            (dfn.vkFreeMemory)(vk_dev, mem_out[0], na)
          } else {
            ok = false
          }
        } else {
          ok = false
        }
        (dfn.vkDestroyImage)(vk_dev, vk_img, na)
      } else {
        ok = false
      }
      @dx12.close_handle(h_tex)
    } else {
      ok = false
    }
    let _ = @dx12.com_release(d3d_tex)
  } else {
    ok = false
  }

  // --- 2. D3D12 Shared Fence <-> Vulkan Timeline Semaphore Sync ---
  let q_out = FixedArray::make(1, (0 : Int64))
  let hr_q = @dx12.dx_d3d12_device_create_command_queue(
    raw_dev,
    @dx12.int32_ptr(queue_desc),
    @dx12.bytes_ptr(@dx12.iid_d3d12_command_queue),
    @dx12.int64_ptr(q_out),
  )
  dx_calls = dx_calls + 1
  let f_out = FixedArray::make(1, (0 : Int64))
  let hr_f = @dx12.dx_d3d12_device_create_fence(
    raw_dev,
    (0 : Int64),
    0x1, // D3D12_FENCE_FLAG_SHARED
    @dx12.bytes_ptr(@dx12.iid_d3d12_fence),
    @dx12.int64_ptr(f_out),
  )
  dx_calls = dx_calls + 1
  if hr_q == 0 && hr_f == 0 && q_out[0] != (0 : Int64) && f_out[0] != (0 : Int64) {
    let dx_q = q_out[0].reinterpret_as_uint64()
    let dx_f = f_out[0].reinterpret_as_uint64()
    let hf_out = FixedArray::make(1, (0 : Int64))
    let hr_fh = @dx12.dx_d3d12_device_create_shared_handle(
      raw_dev,
      dx_f,
      (0 : UInt64),
      0x10000000,
      @dx12.bytes_ptr(fence_name),
      @dx12.int64_ptr(hf_out),
    )
    dx_calls = dx_calls + 1
    let h_fence = hf_out[0].reinterpret_as_uint64()
    if hr_fh == 0 && h_fence != (0 : UInt64) {
      let stc = @vk.VkSemaphoreTypeCreateInfo::new()
      stc.set_semaphoreType(@vk.VK_SEMAPHORE_TYPE_TIMELINE)
      stc.set_initialValue((0 : UInt64))
      let sci = @vk.VkSemaphoreCreateInfo::new()
      sci.set_pNext(stc.as_ptr())
      let sem_out = FixedArray::make(1, @vk.VkSemaphore::null())
      let sr = (dfn.vkCreateSemaphore)(vk_dev, sci, na, sem_out)
      vk_calls = vk_calls + 1
      stc.free()
      sci.free()
      if sr == 0 {
        let sem = sem_out[0]
        let isw = @vk.VkImportSemaphoreWin32HandleInfoKHR::new()
        isw.set_semaphore(sem)
        isw.set_handleType(@vk.VK_EXTERNAL_SEMAPHORE_HANDLE_TYPE_D3D12_FENCE_BIT)
        isw.set_handle(h_fence)
        let isr = (dfn.vkImportSemaphoreWin32HandleKHR)(vk_dev, isw)
        vk_calls = vk_calls + 1
        isw.free()
        if isr == 0 {
          // DX12 signals 1 -> Vulkan waits for 1 -> Vulkan signals 2 -> DX12 waits for 2.
          let hr_sig = @dx12.dx_d3d12_command_queue_signal(dx_q, dx_f, (1 : Int64))
          dx_calls = dx_calls + 1
          let wvals = FixedArray::make(1, (1 : UInt64))
          let swi = @vk.VkSemaphoreWaitInfo::new()
          swi.set_semaphoreCount((1 : UInt32))
          swi.set_pSemaphores(sem_out)
          swi.set_pValues(wvals)
          let wr = (dfn.vkWaitSemaphoresKHR)(vk_dev, swi, (5000000000 : UInt64))
          vk_calls = vk_calls + 1
          swi.free()

          let svals = FixedArray::make(1, (2 : UInt64))
          let tsi = @vk.VkTimelineSemaphoreSubmitInfo::new()
          tsi.set_signalSemaphoreValueCount((1 : UInt32))
          tsi.set_pSignalSemaphoreValues(svals)
          let sub = @vk.VkSubmitInfo::new()
          sub.set_pNext(tsi.as_ptr())
          sub.set_signalSemaphoreCount((1 : UInt32))
          sub.set_pSignalSemaphores(sem_out)
          let qr = (dfn.vkQueueSubmit)(vk_queue, (1 : UInt32), sub, @vk.VkFence::null())
          vk_calls = vk_calls + 1
          tsi.free()
          sub.free()

          let ev = @dx12.create_event()
          let hr_ev = @dx12.dx_d3d12_fence_set_event_on_completion(dx_f, (2 : Int64), ev)
          dx_calls = dx_calls + 1
          let wr_ev = @dx12.wait_event(ev, 5000)
          @dx12.close_handle(ev)
          let completed = @dx12.dx_d3d12_fence_get_completed_value(dx_f)
          dx_calls = dx_calls + 1
          ok = ok && hr_sig == 0 && wr == 0 && qr == 0 && hr_ev == 0 && wr_ev == 0 &&
            completed >= (2 : Int64)
        } else {
          ok = false
        }
        (dfn.vkQueueWaitIdle)(vk_queue) |> ignore
        (dfn.vkDestroySemaphore)(vk_dev, sem, na)
      } else {
        ok = false
      }
      @dx12.close_handle(h_fence)
    } else {
      ok = false
    }
    let _ = @dx12.com_release(dx_f)
    let _ = @dx12.com_release(dx_q)
  } else {
    ok = false
  }

  (dfn.vkDeviceWaitIdle)(vk_dev) |> ignore
  (dfn.vkDestroyDevice)(vk_dev, na)
  @vk.destroy_debug_messenger(inst, ifn, messenger)
  (ifn.vkDestroyInstance)(inst, na)
  let dx_errs = dx_dev.validation_errors()
  dx_dev.destroy()

  if ok && dx_errs == 0 && vk_errors.val == 0 {
    println(
      "[dx12/vulkan-interop] OK — D3D12 shared resource + fence <-> Vulkan memory + timeline semaphore verified (dx_calls=\{dx_calls}, vk_calls=\{vk_calls}, 0 dx12 + 0 vk validation errors)",
    )
  } else {
    println(
      "[dx12/vulkan-interop] FAIL — ok=\{ok} dx_errs=\{dx_errs} vk_errs=\{vk_errors.val} dx_calls=\{dx_calls} vk_calls=\{vk_calls}",
    )
  }
}
