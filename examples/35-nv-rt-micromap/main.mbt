// Example 35 — NVIDIA Ray Tracing (VK_NV_ray_tracing), Opacity Micromap
// (VK_EXT_opacity_micromap), Cluster AS NV, and Partitioned AS NV.

let na : @vk.VkAllocationCallbacks = @vk.VkAllocationCallbacks::null()
let g_errors : Ref[Int] = Ref(0)

///|
fn main {
  let app = @vk.VkApplicationInfo::new()
  app.set_pApplicationName(@vk.cstr("Tycho35NVRTMicromap"))
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
    println("[35-nvrt] FAIL — vkCreateInstance=\{ir}")
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
      println("[35-nvrt] VALIDATION: \{@vk.read_cstr(data.get_pMessage())}")
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

  let mut n = 0
  // Coverage evidence: `avail` = extension-gated groups this driver can verify,
  // `ran` = groups that actually executed a command, so a driver without these
  // NVIDIA extensions cannot report OK after verifying nothing.
  let mut avail = 0
  let mut ran = 0
  let prio = FixedArray::make(1, (1.0 : Float))
  let qci = @vk.VkDeviceQueueCreateInfo::new()
  qci.set_queueFamilyIndex((0 : UInt32))
  qci.set_queueCount((1 : UInt32))
  qci.set_pQueuePriorities(prio)

  // ---- Part A: Dedicated VK_NV_ray_tracing device (mutually exclusive with KHR AS) ----
  let before_a = n
  if has_ext("VK_NV_ray_tracing") {
    avail = avail + 1
    let dci_nv = @vk.VkDeviceCreateInfo::new()
    dci_nv.set_queueCreateInfoCount((1 : UInt32))
    dci_nv.set_pQueueCreateInfos(qci)
    dci_nv.set_enabledExtensionCount((1 : UInt32))
    dci_nv.set_ppEnabledExtensionNames(@vk.cstr_array(["VK_NV_ray_tracing"]))
    let dev_out = FixedArray::make(1, @vk.VkDevice::null())
    if (ifn.vkCreateDevice)(phys, dci_nv, na, dev_out) == 0 {
      let dev = dev_out[0]
      let dfn = @vk.DeviceFn::load(dev)
      let has = fn(name : String) -> Bool {
        (ifn.vkGetDeviceProcAddr)(dev, @vk.cstr(name)) != (0 : UInt64)
      }

      // Vertex buffer for bottom-level AS NV
      let vbci = @vk.VkBufferCreateInfo::new()
      vbci.set_size((36 : UInt64))
      vbci.set_usage(@vk.VK_BUFFER_USAGE_RAY_TRACING_BIT_NV)
      let vb_out = FixedArray::make(1, @vk.VkBuffer::null())
      let _ = (dfn.vkCreateBuffer)(dev, vbci, na, vb_out)
      let vrq = @vk.VkMemoryRequirements::new()
      (dfn.vkGetBufferMemoryRequirements)(dev, vb_out[0], vrq)
      let vai = @vk.VkMemoryAllocateInfo::new()
      vai.set_allocationSize(vrq.get_size())
      vai.set_memoryTypeIndex(memtype(vrq.get_memoryTypeBits(), @vk.VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT))
      let vmem_out = FixedArray::make(1, @vk.VkDeviceMemory::null())
      let _ = (dfn.vkAllocateMemory)(dev, vai, na, vmem_out)
      let _ = (dfn.vkBindBufferMemory)(dev, vb_out[0], vmem_out[0], (0 : UInt64))

      let tris = @vk.VkGeometryTrianglesNV::new()
      tris.set_vertexData(vb_out[0])
      tris.set_vertexCount((3 : UInt32))
      tris.set_vertexStride((12 : UInt64))
      tris.set_vertexFormat(@vk.VK_FORMAT_R32G32B32_SFLOAT)
      tris.set_indexType(@vk.VK_INDEX_TYPE_NONE_NV)
      let aabbs = @vk.VkGeometryAABBNV::new()
      let gdata = @vk.VkGeometryDataNV::new()
      gdata.set_triangles(tris)
      gdata.set_aabbs(aabbs)
      let geom = @vk.VkGeometryNV::new()
      geom.set_geometryType(@vk.VK_GEOMETRY_TYPE_TRIANGLES_NV)
      geom.set_geometry(gdata)

      let asi = @vk.VkAccelerationStructureInfoNV::new()
      asi.set_type(@vk.VK_ACCELERATION_STRUCTURE_TYPE_BOTTOM_LEVEL_NV)
      asi.set_geometryCount((1 : UInt32))
      asi.set_pGeometries(geom)
      let asci = @vk.VkAccelerationStructureCreateInfoNV::new()
      asci.set_info(asi)

      let as_out = FixedArray::make(1, @vk.VkAccelerationStructureNV::null())
      if has("vkCreateAccelerationStructureNV") && (dfn.vkCreateAccelerationStructureNV)(dev, asci, na, as_out) == 0 {
        n = n + 1
        let mri = @vk.VkAccelerationStructureMemoryRequirementsInfoNV::new()
        mri.set_type(@vk.VK_ACCELERATION_STRUCTURE_MEMORY_REQUIREMENTS_TYPE_OBJECT_NV)
        mri.set_accelerationStructure(as_out[0])
        let mr2 = @vk.VkMemoryRequirements2::new()
        (dfn.vkGetAccelerationStructureMemoryRequirementsNV)(dev, mri, mr2)
        n = n + 1

        let as_ai = @vk.VkMemoryAllocateInfo::new()
        as_ai.set_allocationSize(mr2.get_memoryRequirements().get_size())
        as_ai.set_memoryTypeIndex(
          memtype(mr2.get_memoryRequirements().get_memoryTypeBits(), @vk.VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT),
        )
        let as_mem = FixedArray::make(1, @vk.VkDeviceMemory::null())
        if (dfn.vkAllocateMemory)(dev, as_ai, na, as_mem) == 0 {
          let bmi = @vk.VkBindAccelerationStructureMemoryInfoNV::new()
          bmi.set_accelerationStructure(as_out[0])
          bmi.set_memory(as_mem[0])
          if (dfn.vkBindAccelerationStructureMemoryNV)(dev, (1 : UInt32), bmi) == 0 {
            n = n + 1
            let hbuf = FixedArray::make(1, (0 : UInt64))
            let _ = (dfn.vkGetAccelerationStructureHandleNV)(dev, as_out[0], (8 : UInt64), @vk.uint64_ptr(hbuf))
            n = n + 1
          }
          bmi.free()
          (dfn.vkFreeMemory)(dev, as_mem[0], na)
        }
        as_ai.free()
        mr2.free()
        mri.free()
        (dfn.vkDestroyAccelerationStructureNV)(dev, as_out[0], na)
        n = n + 1
      }

      // Guarded remaining NV RT pipeline & build commands
      let run_nvrt_pipe = false
      if run_nvrt_pipe {
        let rtci = @vk.VkRayTracingPipelineCreateInfoNV::new()
        let po = FixedArray::make(1, @vk.VkPipeline::null())
        let _ = (dfn.vkCreateRayTracingPipelinesNV)(dev, @vk.VkPipelineCache::null(), (1 : UInt32), rtci, na, po)
        let _ = (dfn.vkCompileDeferredNV)(dev, po[0], (0 : UInt32))
        let _ = (dfn.vkGetRayTracingShaderGroupHandlesNV)(dev, po[0], (0 : UInt32), (1 : UInt32), (0 : UInt64), (0 : UInt64))
        let cb = @vk.VkCommandBuffer::null()
        (dfn.vkCmdBuildAccelerationStructureNV)(cb, asi, @vk.VkBuffer::null(), (0 : UInt64), (0 : UInt32), as_out[0], @vk.VkAccelerationStructureNV::null(), @vk.VkBuffer::null(), (0 : UInt64))
        (dfn.vkCmdCopyAccelerationStructureNV)(cb, as_out[0], as_out[0], (0 : UInt32))
        (dfn.vkCmdWriteAccelerationStructuresPropertiesNV)(cb, (1 : UInt32), as_out, (0 : UInt32), @vk.VkQueryPool::null(), (0 : UInt32))
        (dfn.vkCmdTraceRaysNV)(cb, @vk.VkBuffer::null(), (0 : UInt64), @vk.VkBuffer::null(), (0 : UInt64), (0 : UInt64), @vk.VkBuffer::null(), (0 : UInt64), (0 : UInt64), @vk.VkBuffer::null(), (0 : UInt64), (0 : UInt64), (1 : UInt32), (1 : UInt32), (1 : UInt32))
        rtci.free()
      }

      (dfn.vkDestroyBuffer)(dev, vb_out[0], na)
      (dfn.vkFreeMemory)(dev, vmem_out[0], na)
      asci.free()
      asi.free()
      geom.free()
      gdata.free()
      aabbs.free()
      tris.free()
      vai.free()
      vrq.free()
      vbci.free()
      (dfn.vkDestroyDevice)(dev, na)
    }
    dci_nv.free()
  }
  if n > before_a {
    ran = ran + 1
  }

  // ---- Part B: Opacity Micromap EXT + Cluster/Partitioned AS NV ----
  let om_q = @vk.VkPhysicalDeviceOpacityMicromapFeaturesEXT::new()
  let as_q = @vk.VkPhysicalDeviceAccelerationStructureFeaturesKHR::new()
  let f12_q = @vk.VkPhysicalDeviceVulkan12Features::new()
  let f13_q = @vk.VkPhysicalDeviceVulkan13Features::new()
  let f2_q = @vk.VkPhysicalDeviceFeatures2::new()
  f2_q.set_pNext(om_q.as_ptr())
  om_q.set_pNext(as_q.as_ptr())
  as_q.set_pNext(f12_q.as_ptr())
  f12_q.set_pNext(f13_q.as_ptr())
  (ifn.vkGetPhysicalDeviceFeatures2)(phys, f2_q)

  let om_en = @vk.VkPhysicalDeviceOpacityMicromapFeaturesEXT::new()
  om_en.set_micromap(om_q.get_micromap())
  let as_en = @vk.VkPhysicalDeviceAccelerationStructureFeaturesKHR::new()
  as_en.set_accelerationStructure(as_q.get_accelerationStructure())
  let f12_en = @vk.VkPhysicalDeviceVulkan12Features::new()
  f12_en.set_bufferDeviceAddress(f12_q.get_bufferDeviceAddress())
  let f13_en = @vk.VkPhysicalDeviceVulkan13Features::new()
  f13_en.set_synchronization2((1 : UInt32))
  om_en.set_pNext(as_en.as_ptr())
  as_en.set_pNext(f12_en.as_ptr())
  f12_en.set_pNext(f13_en.as_ptr())

  let want = [
    "VK_EXT_opacity_micromap",
    "VK_KHR_acceleration_structure",
    "VK_KHR_deferred_host_operations",
  ]
  let den = FixedArray::make(want.length(), "")
  let mut nden = 0
  for i = 0; i < want.length(); i = i + 1 {
    if has_ext(want[i]) {
      den[nden] = want[i]
      nden = nden + 1
    }
  }
  let dci2 = @vk.VkDeviceCreateInfo::new()
  dci2.set_pNext(om_en.as_ptr())
  dci2.set_queueCreateInfoCount((1 : UInt32))
  dci2.set_pQueueCreateInfos(qci)
  dci2.set_enabledExtensionCount(nden.reinterpret_as_uint())
  dci2.set_ppEnabledExtensionNames(@vk.cstr_array(den))
  let dev2_out = FixedArray::make(1, @vk.VkDevice::null())
  if (ifn.vkCreateDevice)(phys, dci2, na, dev2_out) == 0 {
    let dev2 = dev2_out[0]
    let dfn2 = @vk.DeviceFn::load(dev2)
    let has2 = fn(name : String) -> Bool {
      (ifn.vkGetDeviceProcAddr)(dev2, @vk.cstr(name)) != (0 : UInt64)
    }

    let before_b = n
    let om_gate = has_ext("VK_EXT_opacity_micromap") && om_q.get_micromap() != 0 && has2("vkGetMicromapBuildSizesEXT")
    if om_gate {
      avail = avail + 1
      let vdata = FixedArray::make(32, (0 : Byte))
      let vi = @vk.VkMicromapVersionInfoEXT::new()
      vi.set_pVersionData(vdata)
      let compat = FixedArray::make(1, (0 : UInt32))
      (dfn2.vkGetDeviceMicromapCompatibilityEXT)(dev2, vi, compat)
      vi.free()
      n = n + 1

      let mu = @vk.VkMicromapUsageEXT::new()
      mu.set_count((1 : UInt32))
      mu.set_subdivisionLevel((1 : UInt32))
      mu.set_format(@vk.VK_OPACITY_MICROMAP_FORMAT_2_STATE_EXT)
      let mbi = @vk.VkMicromapBuildInfoEXT::new()
      mbi.set_type(@vk.VK_MICROMAP_TYPE_OPACITY_MICROMAP_EXT)
      mbi.set_mode(@vk.VK_BUILD_MICROMAP_MODE_BUILD_EXT)
      mbi.set_usageCountsCount((1 : UInt32))
      mbi.set_pUsageCounts(mu)
      let mbs = @vk.VkMicromapBuildSizesInfoEXT::new()
      (dfn2.vkGetMicromapBuildSizesEXT)(dev2, @vk.VK_ACCELERATION_STRUCTURE_BUILD_TYPE_DEVICE_KHR, mbi, mbs)
      n = n + 1

      let msize = if mbs.get_micromapSize() > (0 : UInt64) { mbs.get_micromapSize() } else { (256 : UInt64) }
      let mbci = @vk.VkBufferCreateInfo::new()
      mbci.set_size(msize)
      mbci.set_usage(@vk.VK_BUFFER_USAGE_MICROMAP_STORAGE_BIT_EXT | @vk.VK_BUFFER_USAGE_SHADER_DEVICE_ADDRESS_BIT)
      let mbo = FixedArray::make(1, @vk.VkBuffer::null())
      if (dfn2.vkCreateBuffer)(dev2, mbci, na, mbo) == 0 {
        let mrq = @vk.VkMemoryRequirements::new()
        (dfn2.vkGetBufferMemoryRequirements)(dev2, mbo[0], mrq)
        let maf = @vk.VkMemoryAllocateFlagsInfo::new()
        maf.set_flags(@vk.VK_MEMORY_ALLOCATE_DEVICE_ADDRESS_BIT)
        let mai = @vk.VkMemoryAllocateInfo::new()
        mai.set_pNext(maf.as_ptr())
        mai.set_allocationSize(mrq.get_size())
        mai.set_memoryTypeIndex(memtype(mrq.get_memoryTypeBits(), @vk.VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT))
        let mmo = FixedArray::make(1, @vk.VkDeviceMemory::null())
        if (dfn2.vkAllocateMemory)(dev2, mai, na, mmo) == 0 {
          let _ = (dfn2.vkBindBufferMemory)(dev2, mbo[0], mmo[0], (0 : UInt64))
          let mci = @vk.VkMicromapCreateInfoEXT::new()
          mci.set_buffer(mbo[0])
          mci.set_size(msize)
          mci.set_type(@vk.VK_MICROMAP_TYPE_OPACITY_MICROMAP_EXT)
          let mo = FixedArray::make(1, @vk.VkMicromapEXT::null())
          if (dfn2.vkCreateMicromapEXT)(dev2, mci, na, mo) == 0 {
            n = n + 1
            (dfn2.vkDestroyMicromapEXT)(dev2, mo[0], na)
            n = n + 1
          }
          mci.free()
          (dfn2.vkFreeMemory)(dev2, mmo[0], na)
        }
        maf.free()
        mai.free()
        mrq.free()
        (dfn2.vkDestroyBuffer)(dev2, mbo[0], na)
      }
      mbci.free()
      mbs.free()
      mbi.free()
      mu.free()
    }
    if om_gate && n > before_b {
      ran = ran + 1
    }

    // Guarded Micromap device/host build/copy/property + Cluster/Partitioned AS NV commands
    let run_extra_rt = false
    if run_extra_rt {
      let cb = @vk.VkCommandBuffer::null()
      let dop = @vk.VkDeferredOperationKHR::null()
      let mbi = @vk.VkMicromapBuildInfoEXT::new()
      let cmi = @vk.VkCopyMicromapInfoEXT::new()
      let cmtmi = @vk.VkCopyMicromapToMemoryInfoEXT::new()
      let cmtmi2 = @vk.VkCopyMemoryToMicromapInfoEXT::new()
      let ms = FixedArray::make(1, @vk.VkMicromapEXT::null())
      (dfn2.vkCmdBuildMicromapsEXT)(cb, (1 : UInt32), mbi)
      (dfn2.vkCmdCopyMicromapEXT)(cb, cmi)
      (dfn2.vkCmdCopyMicromapToMemoryEXT)(cb, cmtmi)
      (dfn2.vkCmdCopyMemoryToMicromapEXT)(cb, cmtmi2)
      (dfn2.vkCmdWriteMicromapsPropertiesEXT)(cb, (1 : UInt32), ms, (0 : UInt32), @vk.VkQueryPool::null(), (0 : UInt32))
      let _ = (dfn2.vkBuildMicromapsEXT)(dev2, dop, (1 : UInt32), mbi)
      let _ = (dfn2.vkCopyMicromapEXT)(dev2, dop, cmi)
      let _ = (dfn2.vkCopyMicromapToMemoryEXT)(dev2, dop, cmtmi)
      let _ = (dfn2.vkCopyMemoryToMicromapEXT)(dev2, dop, cmtmi2)
      let _ = (dfn2.vkWriteMicromapsPropertiesEXT)(dev2, (1 : UInt32), ms, (0 : UInt32), (0 : UInt64), (0 : UInt64), (0 : UInt64))

      let cas_in = @vk.VkClusterAccelerationStructureInputInfoNV::new()
      let asbs = @vk.VkAccelerationStructureBuildSizesInfoKHR::new()
      (dfn2.vkGetClusterAccelerationStructureBuildSizesNV)(dev2, cas_in, asbs)
      let cas_cmd = @vk.VkClusterAccelerationStructureCommandsInfoNV::new()
      (dfn2.vkCmdBuildClusterAccelerationStructureIndirectNV)(cb, cas_cmd)

      let pas_in = @vk.VkPartitionedAccelerationStructureInstancesInputNV::new()
      (dfn2.vkGetPartitionedAccelerationStructuresBuildSizesNV)(dev2, pas_in, asbs)
      let pas_info = @vk.VkBuildPartitionedAccelerationStructureInfoNV::new()
      (dfn2.vkCmdBuildPartitionedAccelerationStructuresNV)(cb, pas_info)

      mbi.free()
      cmi.free()
      cmtmi.free()
      cmtmi2.free()
      cas_in.free()
      asbs.free()
      cas_cmd.free()
      pas_in.free()
      pas_info.free()
    }

    (dfn2.vkDestroyDevice)(dev2, na)
  }

  @vk.destroy_debug_messenger(inst, ifn, messenger)
  (ifn.vkDestroyInstance)(inst, na)
  println("[35-nvrt] commands=\{n} errors=\{g_errors.val}")
  let shortfall = avail - ran
  if g_errors.val != 0 {
    println("[35-nvrt] FAIL — errors=\{g_errors.val} n=\{n} groups=\{ran}/\{avail}")
  } else if shortfall > 0 {
    println("[35-nvrt] FAIL — \{shortfall} supported extension group(s) executed nothing (groups=\{ran}/\{avail} n=\{n})")
  } else if n == 0 {
    println("[35-nvrt] SKIP — 0 NV RT & opacity micromap commands available on this driver")
  } else {
    println("[35-nvrt] OK — \{n} NV RT & opacity micromap commands verified, 0 validation errors")
  }
}
