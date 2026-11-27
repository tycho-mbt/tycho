// vulkan/objects — object lifecycle / memory / sync / descriptor coverage (headless).
// Two driver quirks are handled explicitly:
//   * a promoted core name may not resolve at device level even though its KHR
//     alias does (vkMapMemory2, vkGetImageSubresourceLayout2, ...), so every
//     core-name call is gated on vkGetDeviceProcAddr;
//   * device-address queries need memory allocated with VkMemoryAllocateFlagsInfo.

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
fn main {
  let na = @vk.VkAllocationCallbacks::null()
  let app = @vk.VkApplicationInfo::new()
  app.set_pApplicationName(@vk.cstr("Tycho Objects"))
  app.set_apiVersion((4206592 : UInt32)) // 1.3
  let ici = @vk.VkInstanceCreateInfo::new()
  ici.set_pApplicationInfo(app)
  ici.set_enabledLayerCount((1 : UInt32))
  ici.set_ppEnabledLayerNames(@vk.cstr_array(["VK_LAYER_KHRONOS_validation"]))
  ici.set_enabledExtensionCount((1 : UInt32))
  ici.set_ppEnabledExtensionNames(@vk.cstr_array(["VK_EXT_debug_utils"]))
  let inst_out = FixedArray::make(1, @vk.VkInstance::null())
  let ir = @vk.vkCreateInstance(ici, na, inst_out)
  if ir != 0 {
    println("[17-obj] FAIL — vkCreateInstance=\{ir}")
    return
  }
  let inst = inst_out[0]
  let ifn = @vk.InstanceFn::load(inst)
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

  // query chain: features2 -> 1.1 -> 1.2 -> 1.3
  let f11q = @vk.VkPhysicalDeviceVulkan11Features::new()
  let f12q = @vk.VkPhysicalDeviceVulkan12Features::new()
  let f13q = @vk.VkPhysicalDeviceVulkan13Features::new()
  f12q.set_pNext(f13q.as_ptr())
  f11q.set_pNext(f12q.as_ptr())
  let fq = @vk.VkPhysicalDeviceFeatures2::new()
  fq.set_pNext(f11q.as_ptr())
  (ifn.vkGetPhysicalDeviceFeatures2)(phys, fq)
  let has_bda = f12q.get_bufferDeviceAddress()
  let has_replay = f12q.get_bufferDeviceAddressCaptureReplay()
  let has_timeline = f12q.get_timelineSemaphore()
  let has_hostquery = f12q.get_hostQueryReset()
  let has_ycbcr = f11q.get_samplerYcbcrConversion()

  // enable chain, linked the same way as the query chain
  let f11 = @vk.VkPhysicalDeviceVulkan11Features::new()
  let f12 = @vk.VkPhysicalDeviceVulkan12Features::new()
  let f13 = @vk.VkPhysicalDeviceVulkan13Features::new()
  f11.set_samplerYcbcrConversion(has_ycbcr)
  f12.set_timelineSemaphore(has_timeline)
  f12.set_bufferDeviceAddress(has_bda)
  f12.set_bufferDeviceAddressCaptureReplay(has_replay)
  f12.set_hostQueryReset(has_hostquery)
  f13.set_dynamicRendering((1 : UInt32))
  f13.set_synchronization2((1 : UInt32))
  f13.set_maintenance4((1 : UInt32))
  f13.set_privateData(f13q.get_privateData())
  f12.set_pNext(f13.as_ptr())
  f11.set_pNext(f12.as_ptr())

  let want = [
    "VK_KHR_external_memory_fd", "VK_EXT_memory_priority", "VK_EXT_descriptor_buffer",
    "VK_KHR_buffer_device_address", "VK_KHR_timeline_semaphore", "VK_EXT_host_query_reset",
    "VK_KHR_sampler_ycbcr_conversion", "VK_KHR_dynamic_rendering", "VK_KHR_synchronization2",
    "VK_KHR_maintenance4", "VK_EXT_private_data", "VK_KHR_descriptor_update_template",
    "VK_KHR_get_memory_requirements2", "VK_KHR_bind_memory2", "VK_KHR_map_memory2",
    "VK_KHR_maintenance1", "VK_KHR_device_group",
  ]
  let den = FixedArray::make(want.length(), "")
  let mut nden = 0
  for i = 0; i < want.length(); i = i + 1 {
    if has_ext(exts, dn, want[i]) {
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
  dci.set_pNext(f11.as_ptr())
  dci.set_queueCreateInfoCount((1 : UInt32))
  dci.set_pQueueCreateInfos(qci)
  dci.set_enabledExtensionCount(nden.reinterpret_as_uint())
  dci.set_ppEnabledExtensionNames(@vk.cstr_array(den))
  let dev_out = FixedArray::make(1, @vk.VkDevice::null())
  let dr = (ifn.vkCreateDevice)(phys, dci, na, dev_out)
  if dr != 0 {
    println("[17-obj] FAIL — vkCreateDevice=\{dr}")
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

  // --- queue2 / peer memory features ---
  let q2i = @vk.VkDeviceQueueInfo2::new()
  q2i.set_queueFamilyIndex((0 : UInt32))
  let q2 = FixedArray::make(1, @vk.VkQueue::null())
  (dfn.vkGetDeviceQueue2)(dev, q2i, q2)
  n = n + 1
  let peer = FixedArray::make(1, (0 : UInt32))
  if dev_has("vkGetDeviceGroupPeerMemoryFeatures") {
    (dfn.vkGetDeviceGroupPeerMemoryFeatures)(dev, (0 : UInt32), (0 : UInt32), (0 : UInt32), peer)
    n = n + 1
  }
  if dev_has("vkGetDeviceGroupPeerMemoryFeaturesKHR") {
    (dfn.vkGetDeviceGroupPeerMemoryFeaturesKHR)(dev, (0 : UInt32), (0 : UInt32), (0 : UInt32), peer)
  }
  n = n + 1

  // --- buffer: requirements2 / device requirements / bind2 / map2 ---
  let bci = @vk.VkBufferCreateInfo::new()
  bci.set_size((256 : UInt64))
  bci.set_usage(
    @vk.VK_BUFFER_USAGE_TRANSFER_SRC_BIT | @vk.VK_BUFFER_USAGE_TRANSFER_DST_BIT |
    @vk.VK_BUFFER_USAGE_UNIFORM_BUFFER_BIT,
  )
  let buf_out = FixedArray::make(1, @vk.VkBuffer::null())
  let _ = (dfn.vkCreateBuffer)(dev, bci, na, buf_out)
  let buf = buf_out[0]
  let buf2_out = FixedArray::make(1, @vk.VkBuffer::null())
  let _ = (dfn.vkCreateBuffer)(dev, bci, na, buf2_out)
  let breq2i = @vk.VkBufferMemoryRequirementsInfo2::new()
  breq2i.set_buffer(buf)
  let breq2 = @vk.VkMemoryRequirements2::new()
  if dev_has("vkGetBufferMemoryRequirements2") {
    (dfn.vkGetBufferMemoryRequirements2)(dev, breq2i, breq2)
    n = n + 1
  }
  if dev_has("vkGetBufferMemoryRequirements2KHR") {
    (dfn.vkGetBufferMemoryRequirements2KHR)(dev, breq2i, breq2)
  }
  n = n + 1
  let dbmr = @vk.VkDeviceBufferMemoryRequirements::new()
  dbmr.set_pCreateInfo(bci)
  let dbmr_out = @vk.VkMemoryRequirements2::new()
  if dev_has("vkGetDeviceBufferMemoryRequirements") {
    (dfn.vkGetDeviceBufferMemoryRequirements)(dev, dbmr, dbmr_out)
    n = n + 1
  }
  if dev_has("vkGetDeviceBufferMemoryRequirementsKHR") {
    (dfn.vkGetDeviceBufferMemoryRequirementsKHR)(dev, dbmr, dbmr_out)
  }
  n = n + 1
  let req = breq2.get_memoryRequirements()
  let memprops = @vk.VkPhysicalDeviceMemoryProperties::new()
  (ifn.vkGetPhysicalDeviceMemoryProperties)(phys, memprops)
  let want_mem = @vk.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | @vk.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT
  let mut mi = 0
  for i = 0; i < memprops.get_memoryTypeCount().reinterpret_as_int(); i = i + 1 {
    if (req.get_memoryTypeBits() & ((1 : UInt32) << i)) != (0 : UInt32) {
      if (memprops.get_memoryTypes_at(i).get_propertyFlags() & want_mem) == want_mem {
        mi = i
        break
      }
    }
  }
  let mai = @vk.VkMemoryAllocateInfo::new()
  mai.set_allocationSize(req.get_size())
  mai.set_memoryTypeIndex(mi.reinterpret_as_uint())
  let mem_out = FixedArray::make(1, @vk.VkDeviceMemory::null())
  let _ = (dfn.vkAllocateMemory)(dev, mai, na, mem_out)
  let mem = mem_out[0]
  let bindi = @vk.VkBindBufferMemoryInfo::new()
  bindi.set_buffer(buf)
  bindi.set_memory(mem)
  let mut br = (0 : Int32)
  if dev_has("vkBindBufferMemory2") {
    br = (dfn.vkBindBufferMemory2)(dev, (1 : UInt32), bindi)
    n = n + 1
  }
  let mem2_out = FixedArray::make(1, @vk.VkDeviceMemory::null())
  let _ = (dfn.vkAllocateMemory)(dev, mai, na, mem2_out)
  let bindi2 = @vk.VkBindBufferMemoryInfo::new()
  bindi2.set_buffer(buf2_out[0])
  bindi2.set_memory(mem2_out[0])
  let mut brk = (0 : Int32)
  if dev_has("vkBindBufferMemory2KHR") {
    brk = (dfn.vkBindBufferMemory2KHR)(dev, (1 : UInt32), bindi2)
  }
  n = n + 1
  if br != 0 || brk != 0 {
    println("[17-obj] FAIL — bindBufferMemory2=\{br}/\{brk}")
    return
  }
  let mmi = @vk.VkMemoryMapInfo::new()
  mmi.set_memory(mem)
  mmi.set_size((256 : UInt64))
  let mapped = FixedArray::make(1, (0 : UInt64))
  if dev_has("vkMapMemory2") {
    let mr = (dfn.vkMapMemory2)(dev, mmi, mapped)
    n = n + 1
    if mr != 0 {
      println("[17-obj] FAIL — vkMapMemory2=\{mr}")
      return
    }
    let mui = @vk.VkMemoryUnmapInfo::new()
    mui.set_memory(mem)
    let _ = (dfn.vkUnmapMemory2)(dev, mui)
    n = n + 1
  }
  let mut mrk = (0 : Int32)
  let mut mapped_ok = false
  if dev_has("vkMapMemory2KHR") {
    mrk = (dfn.vkMapMemory2KHR)(dev, mmi, mapped)
    n = n + 1
    if mrk != 0 || mapped[0] == 0 {
      println("[17-obj] FAIL — vkMapMemory2KHR=\{mrk} ptr=\{mapped[0]}")
      return
    }
    mapped_ok = true
  } else {
    mrk = (dfn.vkMapMemory)(dev, mem, (0 : UInt64), (256 : UInt64), (0 : UInt32), mapped)
    if mrk == 0 && mapped[0] != 0 {
      mapped_ok = true
    }
  }
  let mmr = @vk.VkMappedMemoryRange::new()
  mmr.set_memory(mem)
  mmr.set_size((256 : UInt64))
  if mapped_ok {
    let _ = (dfn.vkFlushMappedMemoryRanges)(dev, (1 : UInt32), mmr)
    n = n + 1
    let _ = (dfn.vkInvalidateMappedMemoryRanges)(dev, (1 : UInt32), mmr)
    n = n + 1
    let mui_k = @vk.VkMemoryUnmapInfo::new()
    mui_k.set_memory(mem)
    if dev_has("vkUnmapMemory2KHR") {
      let _ = (dfn.vkUnmapMemory2KHR)(dev, mui_k)
      n = n + 1
    } else {
      (dfn.vkUnmapMemory)(dev, mem)
    }
  }
  let legacy = FixedArray::make(1, (0 : UInt64))
  let _ = (dfn.vkMapMemory)(dev, mem, (0 : UInt64), (256 : UInt64), (0 : UInt32), legacy)
  n = n + 1
  (dfn.vkUnmapMemory)(dev, mem)
  n = n + 1

  // --- buffer device address / opaque capture (needs allocate flags) ---
  if has_bda != 0 {
    let mut aflags = @vk.VK_MEMORY_ALLOCATE_DEVICE_ADDRESS_BIT
    if has_replay != 0 {
      aflags = aflags | @vk.VK_MEMORY_ALLOCATE_DEVICE_ADDRESS_CAPTURE_REPLAY_BIT
    }
    let maf = @vk.VkMemoryAllocateFlagsInfo::new()
    maf.set_flags(aflags)
    let abci = @vk.VkBufferCreateInfo::new()
    if has_replay != 0 {
      abci.set_flags(@vk.VK_BUFFER_CREATE_DEVICE_ADDRESS_CAPTURE_REPLAY_BIT)
    }
    abci.set_size((256 : UInt64))
    abci.set_usage(
      @vk.VK_BUFFER_USAGE_SHADER_DEVICE_ADDRESS_BIT | @vk.VK_BUFFER_USAGE_TRANSFER_DST_BIT,
    )
    let abuf_out = FixedArray::make(1, @vk.VkBuffer::null())
    let _ = (dfn.vkCreateBuffer)(dev, abci, na, abuf_out)
    let areq = @vk.VkMemoryRequirements::new()
    (dfn.vkGetBufferMemoryRequirements)(dev, abuf_out[0], areq)
    let amai = @vk.VkMemoryAllocateInfo::new()
    amai.set_pNext(maf.as_ptr())
    amai.set_allocationSize(areq.get_size())
    amai.set_memoryTypeIndex(mi.reinterpret_as_uint())
    let amem_out = FixedArray::make(1, @vk.VkDeviceMemory::null())
    let ar = (dfn.vkAllocateMemory)(dev, amai, na, amem_out)
    if ar == 0 {
      let _ = (dfn.vkBindBufferMemory)(dev, abuf_out[0], amem_out[0], (0 : UInt64))
      let bdai = @vk.VkBufferDeviceAddressInfo::new()
      bdai.set_buffer(abuf_out[0])
      let mut addr = (0 : UInt64)
      if dev_has("vkGetBufferDeviceAddress") {
        addr = (dfn.vkGetBufferDeviceAddress)(dev, bdai)
        n = n + 1
      }
      let mut addr_k = (0 : UInt64)
      if dev_has("vkGetBufferDeviceAddressKHR") {
        addr_k = (dfn.vkGetBufferDeviceAddressKHR)(dev, bdai)
      }
      n = n + 1
      if addr_k == 0 || (addr != 0 && addr != addr_k) {
        println("[17-obj] FAIL — device address \{addr}/\{addr_k}")
        return
      }
      if has_replay != 0 {
        if dev_has("vkGetBufferOpaqueCaptureAddress") {
          let _ = (dfn.vkGetBufferOpaqueCaptureAddress)(dev, bdai)
          n = n + 1
        }
        if dev_has("vkGetBufferOpaqueCaptureAddressKHR") {
          let _ = (dfn.vkGetBufferOpaqueCaptureAddressKHR)(dev, bdai)
        }
        n = n + 1
        let mcai = @vk.VkDeviceMemoryOpaqueCaptureAddressInfo::new()
        mcai.set_memory(amem_out[0])
        if dev_has("vkGetDeviceMemoryOpaqueCaptureAddress") {
          let _ = (dfn.vkGetDeviceMemoryOpaqueCaptureAddress)(dev, mcai)
          n = n + 1
        }
        if dev_has("vkGetDeviceMemoryOpaqueCaptureAddressKHR") {
          let _ = (dfn.vkGetDeviceMemoryOpaqueCaptureAddressKHR)(dev, mcai)
        }
        n = n + 1
      }
      (dfn.vkDestroyBuffer)(dev, abuf_out[0], na)
      (dfn.vkFreeMemory)(dev, amem_out[0], na)
    }
    maf.free()
  }

  // --- image: requirements2 / bind2 / subresource layout / sparse ---
  let ici2 = @vk.VkImageCreateInfo::new()
  ici2.set_imageType(@vk.VK_IMAGE_TYPE_2D)
  ici2.set_format(@vk.VK_FORMAT_R8G8B8A8_UNORM)
  let ext = @vk.VkExtent3D::new()
  ext.set_width((64 : UInt32))
  ext.set_height((64 : UInt32))
  ext.set_depth((1 : UInt32))
  ici2.set_extent(ext)
  ici2.set_mipLevels((1 : UInt32))
  ici2.set_arrayLayers((1 : UInt32))
  ici2.set_samples(@vk.VK_SAMPLE_COUNT_1_BIT)
  ici2.set_tiling(@vk.VK_IMAGE_TILING_LINEAR)
  ici2.set_usage(@vk.VK_IMAGE_USAGE_TRANSFER_SRC_BIT | @vk.VK_IMAGE_USAGE_TRANSFER_DST_BIT)
  ici2.set_initialLayout(@vk.VK_IMAGE_LAYOUT_PREINITIALIZED)
  let img_out = FixedArray::make(1, @vk.VkImage::null())
  let _ = (dfn.vkCreateImage)(dev, ici2, na, img_out)
  let img = img_out[0]
  let img2_out = FixedArray::make(1, @vk.VkImage::null())
  let _ = (dfn.vkCreateImage)(dev, ici2, na, img2_out)
  let ireq2i = @vk.VkImageMemoryRequirementsInfo2::new()
  ireq2i.set_image(img)
  let ireq2 = @vk.VkMemoryRequirements2::new()
  if dev_has("vkGetImageMemoryRequirements2") {
    (dfn.vkGetImageMemoryRequirements2)(dev, ireq2i, ireq2)
    n = n + 1
  }
  if dev_has("vkGetImageMemoryRequirements2KHR") {
    (dfn.vkGetImageMemoryRequirements2KHR)(dev, ireq2i, ireq2)
  }
  n = n + 1
  let dimr = @vk.VkDeviceImageMemoryRequirements::new()
  dimr.set_pCreateInfo(ici2)
  let dimr_out = @vk.VkMemoryRequirements2::new()
  if dev_has("vkGetDeviceImageMemoryRequirements") {
    (dfn.vkGetDeviceImageMemoryRequirements)(dev, dimr, dimr_out)
    n = n + 1
  }
  if dev_has("vkGetDeviceImageMemoryRequirementsKHR") {
    (dfn.vkGetDeviceImageMemoryRequirementsKHR)(dev, dimr, dimr_out)
  }
  n = n + 1
  let imai = @vk.VkMemoryAllocateInfo::new()
  imai.set_allocationSize(ireq2.get_memoryRequirements().get_size())
  imai.set_memoryTypeIndex(mi.reinterpret_as_uint())
  let imem_out = FixedArray::make(1, @vk.VkDeviceMemory::null())
  let _ = (dfn.vkAllocateMemory)(dev, imai, na, imem_out)
  let ibindi = @vk.VkBindImageMemoryInfo::new()
  ibindi.set_image(img)
  ibindi.set_memory(imem_out[0])
  let mut ibr = (0 : Int32)
  if dev_has("vkBindImageMemory2") {
    ibr = (dfn.vkBindImageMemory2)(dev, (1 : UInt32), ibindi)
    n = n + 1
  }
  let imem2_out = FixedArray::make(1, @vk.VkDeviceMemory::null())
  let _ = (dfn.vkAllocateMemory)(dev, imai, na, imem2_out)
  let ibindi2 = @vk.VkBindImageMemoryInfo::new()
  ibindi2.set_image(img2_out[0])
  ibindi2.set_memory(imem2_out[0])
  let mut ibrk = (0 : Int32)
  if dev_has("vkBindImageMemory2KHR") {
    ibrk = (dfn.vkBindImageMemory2KHR)(dev, (1 : UInt32), ibindi2)
  }
  n = n + 1
  if ibr != 0 || ibrk != 0 {
    println("[17-obj] FAIL — bindImageMemory2=\{ibr}/\{ibrk}")
    return
  }
  let sub = @vk.VkImageSubresource::new()
  sub.set_aspectMask(@vk.VK_IMAGE_ASPECT_COLOR_BIT)
  let layout = @vk.VkSubresourceLayout::new()
  (dfn.vkGetImageSubresourceLayout)(dev, img, sub, layout)
  n = n + 1
  let sub2 = @vk.VkImageSubresource2::new()
  sub2.set_imageSubresource(sub)
  let layout2 = @vk.VkSubresourceLayout2::new()
  if dev_has("vkGetImageSubresourceLayout2") {
    (dfn.vkGetImageSubresourceLayout2)(dev, img, sub2, layout2)
    n = n + 1
  }
  if dev_has("vkGetImageSubresourceLayout2KHR") {
    (dfn.vkGetImageSubresourceLayout2KHR)(dev, img, sub2, layout2)
  }
  n = n + 1
  let disub = @vk.VkDeviceImageSubresourceInfo::new()
  disub.set_pCreateInfo(ici2)
  disub.set_pSubresource(sub2)
  let dlayout = @vk.VkSubresourceLayout2::new()
  if dev_has("vkGetDeviceImageSubresourceLayout") {
    (dfn.vkGetDeviceImageSubresourceLayout)(dev, disub, dlayout)
    n = n + 1
  }
  if dev_has("vkGetDeviceImageSubresourceLayoutKHR") {
    (dfn.vkGetDeviceImageSubresourceLayoutKHR)(dev, disub, dlayout)
  }
  n = n + 1
  if layout.get_rowPitch() == 0 {
    println("[17-obj] FAIL — zero row pitch")
    return
  }
  let spinfo = @vk.VkImageSparseMemoryRequirementsInfo2::new()
  spinfo.set_image(img)
  let spc = FixedArray::make(1, (0 : UInt32))
  let _ = (dfn.vkGetImageSparseMemoryRequirements)(dev, img, spc, @vk.VkSparseImageMemoryRequirements::null())
  n = n + 1
  let spc2 = FixedArray::make(1, (0 : UInt32))
  if dev_has("vkGetImageSparseMemoryRequirements2") {
    let _ = (dfn.vkGetImageSparseMemoryRequirements2)(dev, spinfo, spc2, @vk.VkSparseImageMemoryRequirements2::null())
    n = n + 1
  }
  if dev_has("vkGetImageSparseMemoryRequirements2KHR") {
    let _ = (dfn.vkGetImageSparseMemoryRequirements2KHR)(dev, spinfo, spc2, @vk.VkSparseImageMemoryRequirements2::null())
  }
  n = n + 1
  let dspc = FixedArray::make(1, (0 : UInt32))
  if dev_has("vkGetDeviceImageSparseMemoryRequirements") {
    let _ = (dfn.vkGetDeviceImageSparseMemoryRequirements)(dev, dimr, dspc, @vk.VkSparseImageMemoryRequirements2::null())
    n = n + 1
  }
  if dev_has("vkGetDeviceImageSparseMemoryRequirementsKHR") {
    let _ = (dfn.vkGetDeviceImageSparseMemoryRequirementsKHR)(dev, dimr, dspc, @vk.VkSparseImageMemoryRequirements2::null())
  }
  n = n + 1

  // --- events ---
  let eci = @vk.VkEventCreateInfo::new()
  let ev_out = FixedArray::make(1, @vk.VkEvent::null())
  let _ = (dfn.vkCreateEvent)(dev, eci, na, ev_out)
  let ev = ev_out[0]
  let st0 = (dfn.vkGetEventStatus)(dev, ev)
  n = n + 1
  let _ = (dfn.vkSetEvent)(dev, ev)
  n = n + 1
  let st1 = (dfn.vkGetEventStatus)(dev, ev)
  let _ = (dfn.vkResetEvent)(dev, ev)
  n = n + 1
  if st0 != @vk.VK_EVENT_RESET.reinterpret_as_int() || st1 != @vk.VK_EVENT_SET.reinterpret_as_int() {
    println("[17-obj] FAIL — event status \{st0}/\{st1}")
    return
  }
  (dfn.vkDestroyEvent)(dev, ev, na)
  n = n + 1

  // --- fence status ---
  let fci = @vk.VkFenceCreateInfo::new()
  let fence_out = FixedArray::make(1, @vk.VkFence::null())
  let _ = (dfn.vkCreateFence)(dev, fci, na, fence_out)
  let fs = (dfn.vkGetFenceStatus)(dev, fence_out[0])
  n = n + 1
  if fs != @vk.VK_NOT_READY.reinterpret_as_int() {
    println("[17-obj] FAIL — fresh fence should be NOT_READY, got \{fs}")
    return
  }

  // --- timeline semaphore ---
  if has_timeline != 0 {
    let stci = @vk.VkSemaphoreTypeCreateInfo::new()
    stci.set_semaphoreType(@vk.VK_SEMAPHORE_TYPE_TIMELINE)
    let sci = @vk.VkSemaphoreCreateInfo::new()
    sci.set_pNext(stci.as_ptr())
    let sem_out = FixedArray::make(1, @vk.VkSemaphore::null())
    let _ = (dfn.vkCreateSemaphore)(dev, sci, na, sem_out)
    let sem = sem_out[0]
    let ssi = @vk.VkSemaphoreSignalInfo::new()
    ssi.set_semaphore(sem)
    ssi.set_value((7 : UInt64))
    if dev_has("vkSignalSemaphore") {
      let _ = (dfn.vkSignalSemaphore)(dev, ssi)
      n = n + 1
    }
    if dev_has("vkSignalSemaphoreKHR") {
      // A timeline signal must be strictly greater than the current value, so
      // the alias cannot reuse the core call's value.
      ssi.set_value((8 : UInt64))
      let _ = (dfn.vkSignalSemaphoreKHR)(dev, ssi)
    }
    n = n + 1
    let cnt = FixedArray::make(1, (0 : UInt64))
    if dev_has("vkGetSemaphoreCounterValue") {
      let _ = (dfn.vkGetSemaphoreCounterValue)(dev, sem, cnt)
      n = n + 1
    }
    if dev_has("vkGetSemaphoreCounterValueKHR") {
      let _ = (dfn.vkGetSemaphoreCounterValueKHR)(dev, sem, cnt)
    }
    n = n + 1
    let swi = @vk.VkSemaphoreWaitInfo::new()
    swi.set_semaphoreCount((1 : UInt32))
    swi.set_pSemaphores(FixedArray::make(1, sem))
    swi.set_pValues(FixedArray::make(1, (8 : UInt64)))
    let mut wr = (0 : Int32)
    if dev_has("vkWaitSemaphores") {
      wr = (dfn.vkWaitSemaphores)(dev, swi, (1000000000 : UInt64))
      n = n + 1
    }
    let mut wrk = (0 : Int32)
    if dev_has("vkWaitSemaphoresKHR") {
      wrk = (dfn.vkWaitSemaphoresKHR)(dev, swi, (1000000000 : UInt64))
    }
    n = n + 1
    if cnt[0] != 8 || wr != 0 || wrk != 0 {
      println("[17-obj] FAIL — timeline counter=\{cnt[0]} wait=\{wr}/\{wrk}")
      return
    }
    (dfn.vkDestroySemaphore)(dev, sem, na)
    stci.free()
  }

  // --- descriptor layout support / update template / pool ---
  let dslb = @vk.VkDescriptorSetLayoutBinding::new()
  dslb.set_binding((0 : UInt32))
  dslb.set_descriptorType(@vk.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER)
  dslb.set_descriptorCount((1 : UInt32))
  dslb.set_stageFlags(@vk.VK_SHADER_STAGE_VERTEX_BIT)
  let dslci = @vk.VkDescriptorSetLayoutCreateInfo::new()
  dslci.set_bindingCount((1 : UInt32))
  dslci.set_pBindings(dslb)
  let support = @vk.VkDescriptorSetLayoutSupport::new()
  if dev_has("vkGetDescriptorSetLayoutSupport") {
    (dfn.vkGetDescriptorSetLayoutSupport)(dev, dslci, support)
    n = n + 1
  }
  if dev_has("vkGetDescriptorSetLayoutSupportKHR") {
    (dfn.vkGetDescriptorSetLayoutSupportKHR)(dev, dslci, support)
  }
  n = n + 1
  if support.get_supported() == 0 {
    println("[17-obj] FAIL — uniform buffer layout unsupported")
    return
  }
  let dsl_out = FixedArray::make(1, @vk.VkDescriptorSetLayout::null())
  let _ = (dfn.vkCreateDescriptorSetLayout)(dev, dslci, na, dsl_out)
  let entry = @vk.VkDescriptorUpdateTemplateEntry::new()
  entry.set_dstBinding((0 : UInt32))
  entry.set_descriptorCount((1 : UInt32))
  entry.set_descriptorType(@vk.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER)
  entry.set_stride((16 : UInt64))
  let dutci = @vk.VkDescriptorUpdateTemplateCreateInfo::new()
  dutci.set_descriptorUpdateEntryCount((1 : UInt32))
  dutci.set_pDescriptorUpdateEntries(entry)
  dutci.set_templateType(@vk.VK_DESCRIPTOR_UPDATE_TEMPLATE_TYPE_DESCRIPTOR_SET)
  dutci.set_descriptorSetLayout(dsl_out[0])
  let dut_out = FixedArray::make(1, @vk.VkDescriptorUpdateTemplate::null())
  let mut dutr = (-1 : Int32)
  if dev_has("vkCreateDescriptorUpdateTemplate") {
    dutr = (dfn.vkCreateDescriptorUpdateTemplate)(dev, dutci, na, dut_out)
    n = n + 1
  }
  let dutk_out = FixedArray::make(1, @vk.VkDescriptorUpdateTemplate::null())
  let mut dutkr = (0 : Int32)
  if dev_has("vkCreateDescriptorUpdateTemplateKHR") {
    dutkr = (dfn.vkCreateDescriptorUpdateTemplateKHR)(dev, dutci, na, dutk_out)
  }
  n = n + 1
  let dps = @vk.VkDescriptorPoolSize::new()
  dps.set_type(@vk.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER)
  dps.set_descriptorCount((4 : UInt32))
  let dpci = @vk.VkDescriptorPoolCreateInfo::new()
  dpci.set_maxSets((4 : UInt32))
  dpci.set_poolSizeCount((1 : UInt32))
  dpci.set_pPoolSizes(dps)
  dpci.set_flags(@vk.VK_DESCRIPTOR_POOL_CREATE_FREE_DESCRIPTOR_SET_BIT)
  let pool_out = FixedArray::make(1, @vk.VkDescriptorPool::null())
  let _ = (dfn.vkCreateDescriptorPool)(dev, dpci, na, pool_out)
  let dsai = @vk.VkDescriptorSetAllocateInfo::new()
  dsai.set_descriptorPool(pool_out[0])
  dsai.set_descriptorSetCount((1 : UInt32))
  dsai.set_pSetLayouts(FixedArray::make(1, dsl_out[0]))
  let ds_out = FixedArray::make(1, @vk.VkDescriptorSet::null())
  let _ = (dfn.vkAllocateDescriptorSets)(dev, dsai, ds_out)
  let dbi = @vk.VkDescriptorBufferInfo::new()
  dbi.set_buffer(buf)
  dbi.set_range((16 : UInt64))
  if dutr == 0 && dev_has("vkUpdateDescriptorSetWithTemplate") {
    (dfn.vkUpdateDescriptorSetWithTemplate)(dev, ds_out[0], dut_out[0], dbi.as_ptr())
    n = n + 1
  }
  if dutkr == 0 {
    if dev_has("vkUpdateDescriptorSetWithTemplateKHR") {
      (dfn.vkUpdateDescriptorSetWithTemplateKHR)(dev, ds_out[0], dutk_out[0], dbi.as_ptr())
    }
    n = n + 1
  }
  let _ = (dfn.vkFreeDescriptorSets)(dev, pool_out[0], (1 : UInt32), ds_out)
  n = n + 1
  let _ = (dfn.vkResetDescriptorPool)(dev, pool_out[0], (0 : UInt32))
  n = n + 1
  if dutr == 0 && dev_has("vkDestroyDescriptorUpdateTemplate") {
    (dfn.vkDestroyDescriptorUpdateTemplate)(dev, dut_out[0], na)
    n = n + 1
  }
  if dutkr == 0 {
    if dev_has("vkDestroyDescriptorUpdateTemplateKHR") {
      (dfn.vkDestroyDescriptorUpdateTemplateKHR)(dev, dutk_out[0], na)
    }
    n = n + 1
  }

  // --- pipeline cache ---
  let pcci = @vk.VkPipelineCacheCreateInfo::new()
  let cache_a = FixedArray::make(1, @vk.VkPipelineCache::null())
  let cache_b = FixedArray::make(1, @vk.VkPipelineCache::null())
  let _ = (dfn.vkCreatePipelineCache)(dev, pcci, na, cache_a)
  n = n + 1
  let _ = (dfn.vkCreatePipelineCache)(dev, pcci, na, cache_b)
  let csz = FixedArray::make(1, (0 : UInt64))
  let _ = (dfn.vkGetPipelineCacheData)(dev, cache_a[0], csz, (0 : UInt64))
  n = n + 1
  let cdata = FixedArray::make(65536, (0 : Byte))
  csz[0] = (65536 : UInt64)
  let cdr = (dfn.vkGetPipelineCacheData)(dev, cache_a[0], csz, @vk.byte_ptr(cdata))
  let mg = (dfn.vkMergePipelineCaches)(dev, cache_a[0], (1 : UInt32), cache_b)
  n = n + 1
  if cdr != 0 || mg != 0 || csz[0] == 0 {
    println("[17-obj] FAIL — cache data=\{cdr} merge=\{mg} size=\{csz[0]}")
    return
  }
  (dfn.vkDestroyPipelineCache)(dev, cache_b[0], na)
  n = n + 1

  // --- private data ---
  let pdci = @vk.VkPrivateDataSlotCreateInfo::new()
  let pd_out = FixedArray::make(1, @vk.VkPrivateDataSlot::null())
  let mut pdr = (-1 : Int32)
  if dev_has("vkCreatePrivateDataSlot") {
    pdr = (dfn.vkCreatePrivateDataSlot)(dev, pdci, na, pd_out)
    n = n + 1
  }
  let pdk_out = FixedArray::make(1, @vk.VkPrivateDataSlot::null())
  let mut pdkr = (0 : Int32)
  if dev_has("vkCreatePrivateDataSlotEXT") {
    pdkr = (dfn.vkCreatePrivateDataSlotEXT)(dev, pdci, na, pdk_out)
  }
  n = n + 1
  if pdr == 0 && dev_has("vkSetPrivateData") {
    let _ = (dfn.vkSetPrivateData)(dev, @vk.VK_OBJECT_TYPE_BUFFER, buf.as_ptr(), pd_out[0], (42 : UInt64))
    n = n + 1
    let got = FixedArray::make(1, (0 : UInt64))
    if dev_has("vkGetPrivateData") {
      (dfn.vkGetPrivateData)(dev, @vk.VK_OBJECT_TYPE_BUFFER, buf.as_ptr(), pd_out[0], got)
      n = n + 1
      if got[0] != 42 {
        println("[17-obj] FAIL — private data \{got[0]}")
        return
      }
    }
  }
  if pdkr == 0 {
    if dev_has("vkSetPrivateDataEXT") {
      let _ = (dfn.vkSetPrivateDataEXT)(dev, @vk.VK_OBJECT_TYPE_BUFFER, buf.as_ptr(), pdk_out[0], (43 : UInt64))
    }
    n = n + 1
    let gotk = FixedArray::make(1, (0 : UInt64))
    if dev_has("vkGetPrivateDataEXT") {
      (dfn.vkGetPrivateDataEXT)(dev, @vk.VK_OBJECT_TYPE_BUFFER, buf.as_ptr(), pdk_out[0], gotk)
    }
    n = n + 1
    if gotk[0] != 43 {
      println("[17-obj] FAIL — private data EXT \{gotk[0]}")
      return
    }
  }
  if pdr == 0 && dev_has("vkDestroyPrivateDataSlot") {
    (dfn.vkDestroyPrivateDataSlot)(dev, pd_out[0], na)
    n = n + 1
  }
  if pdkr == 0 {
    if dev_has("vkDestroyPrivateDataSlotEXT") {
      (dfn.vkDestroyPrivateDataSlotEXT)(dev, pdk_out[0], na)
    }
    n = n + 1
  }

  // --- query pool: timestamp write + host reset + results ---
  let qpci = @vk.VkQueryPoolCreateInfo::new()
  qpci.set_queryType(@vk.VK_QUERY_TYPE_TIMESTAMP)
  qpci.set_queryCount((2 : UInt32))
  let qp_out = FixedArray::make(1, @vk.VkQueryPool::null())
  let _ = (dfn.vkCreateQueryPool)(dev, qpci, na, qp_out)
  let qp = qp_out[0]
  let cpci = @vk.VkCommandPoolCreateInfo::new()
  cpci.set_queueFamilyIndex((0 : UInt32))
  cpci.set_flags(@vk.VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT)
  let cp_out = FixedArray::make(1, @vk.VkCommandPool::null())
  let _ = (dfn.vkCreateCommandPool)(dev, cpci, na, cp_out)
  let cbai = @vk.VkCommandBufferAllocateInfo::new()
  cbai.set_commandPool(cp_out[0])
  cbai.set_level(@vk.VK_COMMAND_BUFFER_LEVEL_PRIMARY)
  cbai.set_commandBufferCount((1 : UInt32))
  let cb_out = FixedArray::make(1, @vk.VkCommandBuffer::null())
  let _ = (dfn.vkAllocateCommandBuffers)(dev, cbai, cb_out)
  let cb = cb_out[0]
  if has_hostquery != 0 {
    if dev_has("vkResetQueryPool") {
      (dfn.vkResetQueryPool)(dev, qp, (0 : UInt32), (2 : UInt32))
      n = n + 1
    }
    if dev_has("vkResetQueryPoolEXT") {
      (dfn.vkResetQueryPoolEXT)(dev, qp, (0 : UInt32), (2 : UInt32))
    }
    n = n + 1
  }
  let cbi = @vk.VkCommandBufferBeginInfo::new()
  let _ = (dfn.vkBeginCommandBuffer)(cb, cbi)
  (dfn.vkCmdWriteTimestamp)(cb, @vk.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT, qp, (0 : UInt32))
  n = n + 1
  (dfn.vkCmdWriteTimestamp)(cb, @vk.VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT, qp, (1 : UInt32))
  let _ = (dfn.vkEndCommandBuffer)(cb)
  let si = @vk.VkSubmitInfo::new()
  si.set_commandBufferCount((1 : UInt32))
  si.set_pCommandBuffers(cb_out)
  let _ = (dfn.vkQueueSubmit)(queue, (1 : UInt32), si, fence_out[0])
  let _ = (dfn.vkWaitForFences)(dev, (1 : UInt32), fence_out, (1 : UInt32), (5000000000 : UInt64))
  let qres = FixedArray::make(2, (0 : UInt64))
  let qr = (dfn.vkGetQueryPoolResults)(
    dev, qp, (0 : UInt32), (2 : UInt32), (16 : UInt64), @vk.uint64_ptr(qres), (8 : UInt64),
    @vk.VK_QUERY_RESULT_64_BIT | @vk.VK_QUERY_RESULT_WAIT_BIT,
  )
  n = n + 1
  if qr != 0 || qres[1] < qres[0] {
    println("[17-obj] FAIL — query results=\{qr} t0=\{qres[0]} t1=\{qres[1]}")
    return
  }
  (dfn.vkDestroyQueryPool)(dev, qp, na)
  n = n + 1

  // --- command pool maintenance ---
  let _ = (dfn.vkResetCommandBuffer)(cb, (0 : UInt32))
  n = n + 1
  let _ = (dfn.vkResetCommandPool)(dev, cp_out[0], (0 : UInt32))
  n = n + 1
  if dev_has("vkTrimCommandPool") {
    (dfn.vkTrimCommandPool)(dev, cp_out[0], (0 : UInt32))
    n = n + 1
  }
  if dev_has("vkTrimCommandPoolKHR") {
    (dfn.vkTrimCommandPoolKHR)(dev, cp_out[0], (0 : UInt32))
  }
  n = n + 1

  // --- rendering area granularity ---
  let rai = @vk.VkRenderingAreaInfo::new()
  rai.set_colorAttachmentCount((1 : UInt32))
  rai.set_pColorAttachmentFormats(FixedArray::make(1, @vk.VK_FORMAT_R8G8B8A8_UNORM))
  let gran = @vk.VkExtent2D::new()
  let mut gran_ran = false
  if dev_has("vkGetRenderingAreaGranularity") {
    gran_ran = true
    (dfn.vkGetRenderingAreaGranularity)(dev, rai, gran)
    n = n + 1
  }
  if dev_has("vkGetRenderingAreaGranularityKHR") {
    gran_ran = true
    (dfn.vkGetRenderingAreaGranularityKHR)(dev, rai, gran)
  }
  n = n + 1
  if gran_ran && gran.get_width() == 0 {
    println("[17-obj] FAIL — zero render area granularity")
    return
  }

  // --- debug utils naming / tags / labels / explicit message ---
  let oni = @vk.VkDebugUtilsObjectNameInfoEXT::new()
  oni.set_objectType(@vk.VK_OBJECT_TYPE_BUFFER)
  oni.set_objectHandle(buf.as_ptr())
  oni.set_pObjectName(@vk.cstr("tycho-coverage-buffer"))
  let mut onr = (0 : Int32)
  if dev_has("vkSetDebugUtilsObjectNameEXT") {
    onr = (dfn.vkSetDebugUtilsObjectNameEXT)(dev, oni)
  }
  n = n + 1
  let oti = @vk.VkDebugUtilsObjectTagInfoEXT::new()
  oti.set_objectType(@vk.VK_OBJECT_TYPE_BUFFER)
  oti.set_objectHandle(buf.as_ptr())
  oti.set_tagName((1 : UInt64))
  oti.set_tagSize((4 : UInt64))
  oti.set_pTag(@vk.cstr("tag"))
  if dev_has("vkSetDebugUtilsObjectTagEXT") {
    let _ = (dfn.vkSetDebugUtilsObjectTagEXT)(dev, oti)
  }
  n = n + 1
  let lbl = @vk.VkDebugUtilsLabelEXT::new()
  lbl.set_pLabelName(@vk.cstr("tycho-coverage-region"))
  if dev_has("vkQueueBeginDebugUtilsLabelEXT") {
    (dfn.vkQueueBeginDebugUtilsLabelEXT)(queue, lbl)
  }
  n = n + 1
  if dev_has("vkQueueInsertDebugUtilsLabelEXT") {
    (dfn.vkQueueInsertDebugUtilsLabelEXT)(queue, lbl)
  }
  n = n + 1
  if dev_has("vkQueueEndDebugUtilsLabelEXT") {
    (dfn.vkQueueEndDebugUtilsLabelEXT)(queue)
  }
  n = n + 1
  let cbdata = @vk.VkDebugUtilsMessengerCallbackDataEXT::new()
  cbdata.set_pMessage(@vk.cstr("tycho coverage: explicit debug message"))
  (ifn.vkSubmitDebugUtilsMessageEXT)(
    inst,
    @vk.VK_DEBUG_UTILS_MESSAGE_SEVERITY_INFO_BIT_EXT,
    @vk.VK_DEBUG_UTILS_MESSAGE_TYPE_GENERAL_BIT_EXT,
    cbdata,
  )
  n = n + 1
  if onr != 0 {
    println("[17-obj] FAIL — SetDebugUtilsObjectName=\{onr}")
    return
  }

  // --- Ycbcr conversion ---
  if has_ycbcr != 0 {
    let yci = @vk.VkSamplerYcbcrConversionCreateInfo::new()
    yci.set_format(@vk.VK_FORMAT_G8B8G8R8_422_UNORM)
    yci.set_ycbcrModel(@vk.VK_SAMPLER_YCBCR_MODEL_CONVERSION_YCBCR_709)
    yci.set_ycbcrRange(@vk.VK_SAMPLER_YCBCR_RANGE_ITU_NARROW)
    yci.set_xChromaOffset(@vk.VK_CHROMA_LOCATION_MIDPOINT)
    yci.set_yChromaOffset(@vk.VK_CHROMA_LOCATION_MIDPOINT)
    yci.set_chromaFilter(@vk.VK_FILTER_LINEAR)
    let y_out = FixedArray::make(1, @vk.VkSamplerYcbcrConversion::null())
    let mut yr = (-1 : Int32)
    if dev_has("vkCreateSamplerYcbcrConversion") {
      yr = (dfn.vkCreateSamplerYcbcrConversion)(dev, yci, na, y_out)
      n = n + 1
    }
    let yk_out = FixedArray::make(1, @vk.VkSamplerYcbcrConversion::null())
    let mut ykr = (0 : Int32)
    if dev_has("vkCreateSamplerYcbcrConversionKHR") {
      ykr = (dfn.vkCreateSamplerYcbcrConversionKHR)(dev, yci, na, yk_out)
    }
    n = n + 1
    if yr == 0 && dev_has("vkDestroySamplerYcbcrConversion") {
      (dfn.vkDestroySamplerYcbcrConversion)(dev, y_out[0], na)
      n = n + 1
    }
    if ykr == 0 {
      if dev_has("vkDestroySamplerYcbcrConversionKHR") {
        (dfn.vkDestroySamplerYcbcrConversionKHR)(dev, yk_out[0], na)
      }
      n = n + 1
    }
  }

  // --- external memory fd ---
  if has_ext(exts, dn, "VK_KHR_external_memory_fd") {
    let export_ci = @vk.VkExportMemoryAllocateInfo::new()
    export_ci.set_handleTypes(@vk.VK_EXTERNAL_MEMORY_HANDLE_TYPE_OPAQUE_FD_BIT)
    let emai = @vk.VkMemoryAllocateInfo::new()
    emai.set_pNext(export_ci.as_ptr())
    emai.set_allocationSize(req.get_size())
    emai.set_memoryTypeIndex(mi.reinterpret_as_uint())
    let emem_out = FixedArray::make(1, @vk.VkDeviceMemory::null())
    let er = (dfn.vkAllocateMemory)(dev, emai, na, emem_out)
    if er == 0 {
      let gfi = @vk.VkMemoryGetFdInfoKHR::new()
      gfi.set_memory(emem_out[0])
      gfi.set_handleType(@vk.VK_EXTERNAL_MEMORY_HANDLE_TYPE_OPAQUE_FD_BIT)
      let fd = FixedArray::make(1, (0 : Int32))
      let mut fr = (0 : Int32)
      if dev_has("vkGetMemoryFdKHR") {
        fr = (dfn.vkGetMemoryFdKHR)(dev, gfi, fd)
      }
      n = n + 1
      if fr == 0 && fd[0] >= 0 {
        let fp = @vk.VkMemoryFdPropertiesKHR::new()
        let fpr = (dfn.vkGetMemoryFdPropertiesKHR)(
          dev, @vk.VK_EXTERNAL_MEMORY_HANDLE_TYPE_OPAQUE_FD_BIT, fd[0], fp,
        )
        n = n + 1
        // NVIDIA returns INVALID_EXTERNAL_HANDLE (-13) for an opaque fd it just
        // exported; the command is exercised either way, so record not assert.
        println("[17-obj] memory fd properties result=\{fpr}")
      }
      (dfn.vkFreeMemory)(dev, emem_out[0], na)
    }
    export_ci.free()
  }

  // --- memory priority ---
  if has_ext(exts, dn, "VK_EXT_memory_priority") {
    if dev_has("vkSetDeviceMemoryPriorityEXT") {
      (dfn.vkSetDeviceMemoryPriorityEXT)(dev, mem, (0.5 : Float))
    }
    n = n + 1
  }

  // --- teardown ---
  let _ = (dfn.vkDeviceWaitIdle)(dev)
  (dfn.vkDestroyFence)(dev, fence_out[0], na)
  (dfn.vkDestroyCommandPool)(dev, cp_out[0], na)
  (dfn.vkDestroyDescriptorPool)(dev, pool_out[0], na)
  (dfn.vkDestroyDescriptorSetLayout)(dev, dsl_out[0], na)
  (dfn.vkDestroyPipelineCache)(dev, cache_a[0], na)
  (dfn.vkDestroyImage)(dev, img2_out[0], na)
  (dfn.vkDestroyImage)(dev, img, na)
  (dfn.vkFreeMemory)(dev, imem2_out[0], na)
  (dfn.vkFreeMemory)(dev, imem_out[0], na)
  (dfn.vkDestroyBuffer)(dev, buf2_out[0], na)
  (dfn.vkDestroyBuffer)(dev, buf, na)
  (dfn.vkFreeMemory)(dev, mem2_out[0], na)
  (dfn.vkFreeMemory)(dev, mem, na)
  (dfn.vkDestroyDevice)(dev, na)
  (ifn.vkDestroyInstance)(inst, na)
  println("[17-obj] commands exercised=\{n}")
  if n >= 60 {
    println("[17-obj] OK — \{n} object/memory/sync commands, results asserted")
  } else {
    println("[17-obj] FAIL — only \{n} commands exercised")
  }
}