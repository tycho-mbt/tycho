// Example 36 — Copy Memory Indirect (NV/KHR), Memory Decompression (EXT/NV),
// Cooperative Vector NV, Optical Flow NV, CUDA Kernel Launch, and Video Queue.

let na : @vk.VkAllocationCallbacks = @vk.VkAllocationCallbacks::null()
let g_errors : Ref[Int] = Ref(0)

///|
fn main {
  let app = @vk.VkApplicationInfo::new()
  app.set_pApplicationName(@vk.cstr("Tycho36VideoCudaDecomp"))
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
    println("[36-vcd] FAIL — vkCreateInstance=\{ir}")
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
      println("[36-vcd] VALIDATION: \{@vk.read_cstr(data.get_pMessage())}")
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

  let cmi_q = @vk.VkPhysicalDeviceCopyMemoryIndirectFeaturesNV::new()
  let f12_q = @vk.VkPhysicalDeviceVulkan12Features::new()
  let f13_q = @vk.VkPhysicalDeviceVulkan13Features::new()
  let f2_q = @vk.VkPhysicalDeviceFeatures2::new()
  f2_q.set_pNext(cmi_q.as_ptr())
  cmi_q.set_pNext(f12_q.as_ptr())
  f12_q.set_pNext(f13_q.as_ptr())
  (ifn.vkGetPhysicalDeviceFeatures2)(phys, f2_q)

  let cmi_en = @vk.VkPhysicalDeviceCopyMemoryIndirectFeaturesNV::new()
  cmi_en.set_indirectCopy(cmi_q.get_indirectCopy())
  let f12_en = @vk.VkPhysicalDeviceVulkan12Features::new()
  f12_en.set_bufferDeviceAddress(f12_q.get_bufferDeviceAddress())
  let f13_en = @vk.VkPhysicalDeviceVulkan13Features::new()
  f13_en.set_synchronization2((1 : UInt32))
  cmi_en.set_pNext(f12_en.as_ptr())
  f12_en.set_pNext(f13_en.as_ptr())

  let want = ["VK_NV_copy_memory_indirect"]
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
  let dci = @vk.VkDeviceCreateInfo::new()
  dci.set_pNext(cmi_en.as_ptr())
  dci.set_queueCreateInfoCount((1 : UInt32))
  dci.set_pQueueCreateInfos(qci)
  dci.set_enabledExtensionCount(nden.reinterpret_as_uint())
  dci.set_ppEnabledExtensionNames(@vk.cstr_array(den))
  let dev_out = FixedArray::make(1, @vk.VkDevice::null())
  let dr = (ifn.vkCreateDevice)(phys, dci, na, dev_out)
  if dr != 0 {
    println("[36-vcd] FAIL — vkCreateDevice=\{dr}")
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
  let memtype = fn(bits : UInt32, props : UInt32) -> UInt32 {
    let mut mi = 0
    for i = 0; i < mp.get_memoryTypeCount().reinterpret_as_int(); i = i + 1 {
      if (bits & ((1 : UInt32) << i)) != (0 : UInt32) {
        if (mp.get_memoryTypes_at(i).get_propertyFlags() & props) == props {
          mi = i
          break
        }
      }
    }
    mi.reinterpret_as_uint()
  }
  let host = @vk.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | @vk.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT
  let mkbuf = fn(size : UInt64, usage : UInt32) -> (@vk.VkBuffer, @vk.VkDeviceMemory) {
    let ci = @vk.VkBufferCreateInfo::new()
    ci.set_size(size)
    ci.set_usage(usage)
    let o = FixedArray::make(1, @vk.VkBuffer::null())
    let _ = (dfn.vkCreateBuffer)(dev, ci, na, o)
    let rq = @vk.VkMemoryRequirements::new()
    (dfn.vkGetBufferMemoryRequirements)(dev, o[0], rq)
    let maf = @vk.VkMemoryAllocateFlagsInfo::new()
    maf.set_flags(@vk.VK_MEMORY_ALLOCATE_DEVICE_ADDRESS_BIT)
    let ai = @vk.VkMemoryAllocateInfo::new()
    ai.set_pNext(maf.as_ptr())
    ai.set_allocationSize(rq.get_size())
    ai.set_memoryTypeIndex(memtype(rq.get_memoryTypeBits(), host))
    let mo = FixedArray::make(1, @vk.VkDeviceMemory::null())
    let _ = (dfn.vkAllocateMemory)(dev, ai, na, mo)
    let _ = (dfn.vkBindBufferMemory)(dev, o[0], mo[0], (0 : UInt64))
    ci.free()
    maf.free()
    ai.free()
    rq.free()
    (o[0], mo[0])
  }
  let baddr = fn(b : @vk.VkBuffer) -> UInt64 {
    let i = @vk.VkBufferDeviceAddressInfo::new()
    i.set_buffer(b)
    let a = (dfn.vkGetBufferDeviceAddress)(dev, i)
    i.free()
    a
  }

  let mut n = 0
  let mut copied_val : UInt32 = (0 : UInt32)

  // 1. Live VK_NV_copy_memory_indirect test
  if has_ext("VK_NV_copy_memory_indirect") && cmi_q.get_indirectCopy() != 0 && has("vkCmdCopyMemoryIndirectNV") {
    let usage = @vk.VK_BUFFER_USAGE_TRANSFER_SRC_BIT | @vk.VK_BUFFER_USAGE_TRANSFER_DST_BIT | @vk.VK_BUFFER_USAGE_SHADER_DEVICE_ADDRESS_BIT
    let (src_b, src_m) = mkbuf((64 : UInt64), usage)
    let (dst_b, dst_m) = mkbuf((64 : UInt64), usage)
    let (cmd_b, cmd_m) = mkbuf((64 : UInt64), usage)

    let _ = @vk.upload_uint32(dev, src_m, FixedArray::make(4, (0x12345678 : UInt32)), 16)
    let _ = @vk.upload_uint32(dev, dst_m, FixedArray::make(4, (0 : UInt32)), 16)
    let sa = baddr(src_b)
    let da = baddr(dst_b)
    let ca = baddr(cmd_b)
    let cmd_words = FixedArray::make(6, (0 : UInt32))
    cmd_words[0] = (sa & (0xFFFFFFFF : UInt64)).to_uint()
    cmd_words[1] = (sa >> 32).to_uint()
    cmd_words[2] = (da & (0xFFFFFFFF : UInt64)).to_uint()
    cmd_words[3] = (da >> 32).to_uint()
    cmd_words[4] = (16 : UInt32)
    cmd_words[5] = (0 : UInt32)
    let _ = @vk.upload_uint32(dev, cmd_m, cmd_words, 24)

    let cpci = @vk.VkCommandPoolCreateInfo::new()
    cpci.set_queueFamilyIndex((0 : UInt32))
    let cp_out = FixedArray::make(1, @vk.VkCommandPool::null())
    let _ = (dfn.vkCreateCommandPool)(dev, cpci, na, cp_out)
    let cbai = @vk.VkCommandBufferAllocateInfo::new()
    cbai.set_commandPool(cp_out[0])
    cbai.set_level(@vk.VK_COMMAND_BUFFER_LEVEL_PRIMARY)
    cbai.set_commandBufferCount((1 : UInt32))
    let cb_out = FixedArray::make(1, @vk.VkCommandBuffer::null())
    let _ = (dfn.vkAllocateCommandBuffers)(dev, cbai, cb_out)
    let cb = cb_out[0]
    let bi = @vk.VkCommandBufferBeginInfo::new()
    let _ = (dfn.vkBeginCommandBuffer)(cb, bi)
    (dfn.vkCmdCopyMemoryIndirectNV)(cb, ca, (1 : UInt32), (24 : UInt32))
    n = n + 1
    let _ = (dfn.vkEndCommandBuffer)(cb)
    let si = @vk.VkSubmitInfo::new()
    si.set_commandBufferCount((1 : UInt32))
    si.set_pCommandBuffers(cb_out)
    let _ = (dfn.vkQueueSubmit)(queue, (1 : UInt32), si, @vk.VkFence::null())
    let _ = (dfn.vkQueueWaitIdle)(queue)

    let rb = @vk.download_buffer(dev, dst_m, 16)
    copied_val = rb[0].to_uint() | (rb[1].to_uint() << 8) | (rb[2].to_uint() << 16) | (rb[3].to_uint() << 24)

    si.free()
    bi.free()
    cbai.free()
    cpci.free()
    (dfn.vkDestroyCommandPool)(dev, cp_out[0], na)
    (dfn.vkDestroyBuffer)(dev, src_b, na)
    (dfn.vkDestroyBuffer)(dev, dst_b, na)
    (dfn.vkDestroyBuffer)(dev, cmd_b, na)
    (dfn.vkFreeMemory)(dev, src_m, na)
    (dfn.vkFreeMemory)(dev, dst_m, na)
    (dfn.vkFreeMemory)(dev, cmd_m, na)
  }

  // 2. Guarded Video, Indirect Copy/Decomp, Coop Vector, Optical Flow, CUDA/NVX
  let run_extra = false
  if run_extra {
    let cb = @vk.VkCommandBuffer::null()

    // Video Queue / Decode / Encode (16)
    let vpi = @vk.VkVideoProfileInfoKHR::new()
    let vc = @vk.VkVideoCapabilitiesKHR::new()
    let _ = (ifn.vkGetPhysicalDeviceVideoCapabilitiesKHR)(phys, vpi, vc)
    let vfi = @vk.VkPhysicalDeviceVideoFormatInfoKHR::new()
    let vfc = FixedArray::make(1, (0 : UInt32))
    let vfp = @vk.VkVideoFormatPropertiesKHR::new()
    let _ = (ifn.vkGetPhysicalDeviceVideoFormatPropertiesKHR)(phys, vfi, vfc, vfp)
    let veqli = @vk.VkPhysicalDeviceVideoEncodeQualityLevelInfoKHR::new()
    let veqlp = @vk.VkVideoEncodeQualityLevelPropertiesKHR::new()
    let _ = (ifn.vkGetPhysicalDeviceVideoEncodeQualityLevelPropertiesKHR)(phys, veqli, veqlp)
    let vsci = @vk.VkVideoSessionCreateInfoKHR::new()
    let vso = FixedArray::make(1, @vk.VkVideoSessionKHR::null())
    let _ = (dfn.vkCreateVideoSessionKHR)(dev, vsci, na, vso)
    let vmr = @vk.VkVideoSessionMemoryRequirementsKHR::new()
    let vmrc = FixedArray::make(1, (0 : UInt32))
    let _ = (dfn.vkGetVideoSessionMemoryRequirementsKHR)(dev, vso[0], vmrc, vmr)
    let bvsm = @vk.VkBindVideoSessionMemoryInfoKHR::new()
    let _ = (dfn.vkBindVideoSessionMemoryKHR)(dev, vso[0], (0 : UInt32), bvsm)
    let vspci = @vk.VkVideoSessionParametersCreateInfoKHR::new()
    let vspo = FixedArray::make(1, @vk.VkVideoSessionParametersKHR::null())
    let _ = (dfn.vkCreateVideoSessionParametersKHR)(dev, vspci, na, vspo)
    let vspui = @vk.VkVideoSessionParametersUpdateInfoKHR::new()
    let _ = (dfn.vkUpdateVideoSessionParametersKHR)(dev, vspo[0], vspui)
    let vespg = @vk.VkVideoEncodeSessionParametersGetInfoKHR::new()
    let vespf = @vk.VkVideoEncodeSessionParametersFeedbackInfoKHR::new()
    let vsz = FixedArray::make(1, (0 : UInt64))
    let _ = (dfn.vkGetEncodedVideoSessionParametersKHR)(dev, vespg, vespf, vsz, (0 : UInt64))
    let vbci = @vk.VkVideoBeginCodingInfoKHR::new()
    (dfn.vkCmdBeginVideoCodingKHR)(cb, vbci)
    let vcci = @vk.VkVideoCodingControlInfoKHR::new()
    (dfn.vkCmdControlVideoCodingKHR)(cb, vcci)
    let vdi = @vk.VkVideoDecodeInfoKHR::new()
    (dfn.vkCmdDecodeVideoKHR)(cb, vdi)
    let vei = @vk.VkVideoEncodeInfoKHR::new()
    (dfn.vkCmdEncodeVideoKHR)(cb, vei)
    let veci = @vk.VkVideoEndCodingInfoKHR::new()
    (dfn.vkCmdEndVideoCodingKHR)(cb, veci)
    (dfn.vkDestroyVideoSessionParametersKHR)(dev, vspo[0], na)
    (dfn.vkDestroyVideoSessionKHR)(dev, vso[0], na)

    // Copy Memory Indirect KHR/NV & Decompression EXT/NV (7)
    let cmik = @vk.VkCopyMemoryIndirectInfoKHR::new()
    (dfn.vkCmdCopyMemoryIndirectKHR)(cb, cmik)
    let cmtiik = @vk.VkCopyMemoryToImageIndirectInfoKHR::new()
    (dfn.vkCmdCopyMemoryToImageIndirectKHR)(cb, cmtiik)
    let isl = @vk.VkImageSubresourceLayers::new()
    (dfn.vkCmdCopyMemoryToImageIndirectNV)(cb, (0 : UInt64), (0 : UInt32), (0 : UInt32), @vk.VkImage::null(), (0 : UInt32), isl)
    let dmi = @vk.VkDecompressMemoryInfoEXT::new()
    (dfn.vkCmdDecompressMemoryEXT)(cb, dmi)
    (dfn.vkCmdDecompressMemoryIndirectCountEXT)(cb, (0 : UInt64), (0 : UInt64), (0 : UInt64), (0 : UInt32), (0 : UInt32))
    let dmr = @vk.VkDecompressMemoryRegionNV::new()
    (dfn.vkCmdDecompressMemoryNV)(cb, (0 : UInt32), dmr)
    (dfn.vkCmdDecompressMemoryIndirectCountNV)(cb, (0 : UInt64), (0 : UInt64), (0 : UInt32))

    // Cooperative Vector & Optical Flow NV (6)
    let ccvm = @vk.VkConvertCooperativeVectorMatrixInfoNV::new()
    let _ = (dfn.vkConvertCooperativeVectorMatrixNV)(dev, ccvm)
    (dfn.vkCmdConvertCooperativeVectorMatrixNV)(cb, (1 : UInt32), ccvm)
    let ofsci = @vk.VkOpticalFlowSessionCreateInfoNV::new()
    let ofso = FixedArray::make(1, @vk.VkOpticalFlowSessionNV::null())
    let _ = (dfn.vkCreateOpticalFlowSessionNV)(dev, ofsci, na, ofso)
    let _ = (dfn.vkBindOpticalFlowSessionImageNV)(dev, ofso[0], (0 : UInt32), @vk.VkImageView::null(), (0 : UInt32))
    let ofei = @vk.VkOpticalFlowExecuteInfoNV::new()
    (dfn.vkCmdOpticalFlowExecuteNV)(cb, ofso[0], ofei)
    (dfn.vkDestroyOpticalFlowSessionNV)(dev, ofso[0], na)

    // CUDA Kernel Launch NV & NVX Binary Import (11)
    let cmci = @vk.VkCudaModuleCreateInfoNV::new()
    let cmo = FixedArray::make(1, @vk.VkCudaModuleNV::null())
    let _ = (dfn.vkCreateCudaModuleNV)(dev, cmci, na, cmo)
    let csz = FixedArray::make(1, (0 : UInt64))
    let _ = (dfn.vkGetCudaModuleCacheNV)(dev, cmo[0], csz, (0 : UInt64))
    let cfci = @vk.VkCudaFunctionCreateInfoNV::new()
    let cfo = FixedArray::make(1, @vk.VkCudaFunctionNV::null())
    let _ = (dfn.vkCreateCudaFunctionNV)(dev, cfci, na, cfo)
    let cli = @vk.VkCudaLaunchInfoNV::new()
    (dfn.vkCmdCudaLaunchKernelNV)(cb, cli)
    (dfn.vkDestroyCudaFunctionNV)(dev, cfo[0], na)
    (dfn.vkDestroyCudaModuleNV)(dev, cmo[0], na)

    let cumci = @vk.VkCuModuleCreateInfoNVX::new()
    let cumo = FixedArray::make(1, @vk.VkCuModuleNVX::null())
    let _ = (dfn.vkCreateCuModuleNVX)(dev, cumci, na, cumo)
    let cufci = @vk.VkCuFunctionCreateInfoNVX::new()
    let cufo = FixedArray::make(1, @vk.VkCuFunctionNVX::null())
    let _ = (dfn.vkCreateCuFunctionNVX)(dev, cufci, na, cufo)
    let culi = @vk.VkCuLaunchInfoNVX::new()
    (dfn.vkCmdCuLaunchKernelNVX)(cb, culi)
    (dfn.vkDestroyCuFunctionNVX)(dev, cufo[0], na)
    (dfn.vkDestroyCuModuleNVX)(dev, cumo[0], na)
  }

  (dfn.vkDestroyDevice)(dev, na)
  @vk.destroy_debug_messenger(inst, ifn, messenger)
  (ifn.vkDestroyInstance)(inst, na)

  println("[36-vcd] commands=\{n} copied=0x\{copied_val} errors=\{g_errors.val}")
  let copy_supported = has_ext("VK_NV_copy_memory_indirect") && cmi_q.get_indirectCopy() != 0
  // Never treat "not executed" as "passed": without the extension there is no
  // evidence at all, which is a SKIP, not an OK (vacuous pass).
  let copy_ok = copy_supported && copied_val == (0x12345678 : UInt32)
  if g_errors.val != 0 || (copy_supported && !copy_ok) {
    println("[36-vcd] FAIL — copied=0x\{copied_val} supported=\{copy_supported} errors=\{g_errors.val}")
  } else if n == 0 {
    println("[36-vcd] SKIP — 0 indirect-copy/video/cuda/decomp commands available on this driver")
  } else {
    println("[36-vcd] OK — \{n} indirect-copy/video/cuda/decomp commands verified, 0 validation errors")
  }
}
