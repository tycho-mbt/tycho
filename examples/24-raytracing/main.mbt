// Example 24 — ray tracing (VK_KHR_acceleration_structure + ray_tracing_pipeline):
// BLAS/TLAS build, ray tracing pipeline, shader binding table, trace rays, and
// the host-side build/copy/property variants. Ninth coverage batch.
// The ray hits a single triangle; the payload written to the output buffer is
// the assertion, so a silently broken AS or SBT cannot pass.

///|
let na : @vk.VkAllocationCallbacks = @vk.VkAllocationCallbacks::null()

///|
let g_errors : Ref[Int] = { val: 0 }

///|
fn main {
  let app = @vk.VkApplicationInfo::new()
  app.set_pApplicationName(@vk.cstr("Tycho RayTracing"))
  app.set_apiVersion((4206592 : UInt32))
  let ici = @vk.VkInstanceCreateInfo::new()
  ici.set_pApplicationInfo(app)
  ici.set_enabledLayerCount((1 : UInt32))
  ici.set_ppEnabledLayerNames(@vk.cstr_array(["VK_LAYER_KHRONOS_validation"]))
  ici.set_enabledExtensionCount((1 : UInt32))
  ici.set_ppEnabledExtensionNames(@vk.cstr_array(["VK_EXT_debug_utils"]))
  let inst_out = FixedArray::make(1, @vk.VkInstance::null())
  let ir = @vk.vkCreateInstance(ici, na, inst_out)
  if ir != 0 {
    println("[24-rt] FAIL — vkCreateInstance=\{ir}")
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
      println("[24-rt] VALIDATION: \{@vk.read_cstr(data.get_pMessage())}")
      (0 : UInt32)
    },
  )
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
  let has_ext = fn(name : String) -> Bool {
    for i = 0; i < dn; i = i + 1 {
      if exts[i] == name {
        return true
      }
    }
    false
  }
  if !has_ext("VK_KHR_acceleration_structure") || !has_ext("VK_KHR_ray_tracing_pipeline") {
    println("[24-rt] SKIP — ray tracing extensions not supported")
    (ifn.vkDestroyInstance)(inst, na)
    return
  }
  let asq = @vk.VkPhysicalDeviceAccelerationStructureFeaturesKHR::new()
  let rtq = @vk.VkPhysicalDeviceRayTracingPipelineFeaturesKHR::new()
  let f12q = @vk.VkPhysicalDeviceVulkan12Features::new()
  let f13q = @vk.VkPhysicalDeviceVulkan13Features::new()
  asq.set_pNext(rtq.as_ptr())
  rtq.set_pNext(f12q.as_ptr())
  f12q.set_pNext(f13q.as_ptr())
  let fq = @vk.VkPhysicalDeviceFeatures2::new()
  fq.set_pNext(asq.as_ptr())
  (ifn.vkGetPhysicalDeviceFeatures2)(phys, fq)
  let asf = @vk.VkPhysicalDeviceAccelerationStructureFeaturesKHR::new()
  asf.set_accelerationStructure(asq.get_accelerationStructure())
  asf.set_accelerationStructureHostCommands(asq.get_accelerationStructureHostCommands())
  asf.set_accelerationStructureIndirectBuild(asq.get_accelerationStructureIndirectBuild())
  let rtf = @vk.VkPhysicalDeviceRayTracingPipelineFeaturesKHR::new()
  rtf.set_rayTracingPipeline(rtq.get_rayTracingPipeline())
  rtf.set_rayTracingPipelineTraceRaysIndirect(rtq.get_rayTracingPipelineTraceRaysIndirect())
  rtf.set_rayTracingPipelineShaderGroupHandleCaptureReplay(rtq.get_rayTracingPipelineShaderGroupHandleCaptureReplay())
  let f12 = @vk.VkPhysicalDeviceVulkan12Features::new()
  f12.set_bufferDeviceAddress(f12q.get_bufferDeviceAddress())
  f12.set_descriptorIndexing(f12q.get_descriptorIndexing())
  f12.set_runtimeDescriptorArray(f12q.get_runtimeDescriptorArray())
  f12.set_descriptorBindingPartiallyBound(f12q.get_descriptorBindingPartiallyBound())
  f12.set_scalarBlockLayout(f12q.get_scalarBlockLayout())
  let f13 = @vk.VkPhysicalDeviceVulkan13Features::new()
  f13.set_synchronization2((1 : UInt32))
  f13.set_maintenance4((1 : UInt32))
  asf.set_pNext(rtf.as_ptr())
  rtf.set_pNext(f12.as_ptr())
  f12.set_pNext(f13.as_ptr())
  let want = ["VK_KHR_acceleration_structure", "VK_KHR_ray_tracing_pipeline", "VK_KHR_buffer_device_address", "VK_KHR_deferred_host_operations", "VK_KHR_synchronization2", "VK_KHR_spirv_1_4", "VK_KHR_shader_float_controls", "VK_KHR_maintenance4", "VK_EXT_descriptor_indexing", "VK_EXT_scalar_block_layout"]
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
  dci.set_pNext(asf.as_ptr())
  dci.set_queueCreateInfoCount((1 : UInt32))
  dci.set_pQueueCreateInfos(qci)
  dci.set_enabledExtensionCount(nden.reinterpret_as_uint())
  dci.set_ppEnabledExtensionNames(@vk.cstr_array(den))
  let dev_out = FixedArray::make(1, @vk.VkDevice::null())
  let dr = (ifn.vkCreateDevice)(phys, dci, na, dev_out)
  if dr != 0 {
    println("[24-rt] FAIL — vkCreateDevice=\{dr}")
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
  let dev_local = @vk.VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT
  let addr_flags = @vk.VK_MEMORY_ALLOCATE_DEVICE_ADDRESS_BIT
  let mkbuf = fn(size : UInt64, usage : UInt32, props : UInt32) -> (@vk.VkBuffer, @vk.VkDeviceMemory) {
    let ci = @vk.VkBufferCreateInfo::new()
    ci.set_size(size)
    ci.set_usage(usage)
    let o = FixedArray::make(1, @vk.VkBuffer::null())
    let _ = (dfn.vkCreateBuffer)(dev, ci, na, o)
    let rq = @vk.VkMemoryRequirements::new()
    (dfn.vkGetBufferMemoryRequirements)(dev, o[0], rq)
    let maf = @vk.VkMemoryAllocateFlagsInfo::new()
    maf.set_flags(addr_flags)
    let ai = @vk.VkMemoryAllocateInfo::new()
    ai.set_pNext(maf.as_ptr())
    ai.set_allocationSize(rq.get_size())
    ai.set_memoryTypeIndex(memtype(rq.get_memoryTypeBits(), props))
    let mo = FixedArray::make(1, @vk.VkDeviceMemory::null())
    let _ = (dfn.vkAllocateMemory)(dev, ai, na, mo)
    let _ = (dfn.vkBindBufferMemory)(dev, o[0], mo[0], (0 : UInt64))
    ci.free()
    maf.free()
    (o[0], mo[0])
  }
  let baddr = fn(b : @vk.VkBuffer) -> UInt64 {
    let i = @vk.VkBufferDeviceAddressInfo::new()
    i.set_buffer(b)
    (dfn.vkGetBufferDeviceAddress)(dev, i)
  }
  let devaddr = fn(a : UInt64) -> @vk.VkDeviceOrHostAddressConstKHR {
    let u = @vk.VkDeviceOrHostAddressConstKHR::new()
    u.set_deviceAddress(a)
    u
  }
  let devaddr_mut = fn(a : UInt64) -> @vk.VkDeviceOrHostAddressKHR {
    let u = @vk.VkDeviceOrHostAddressKHR::new()
    u.set_deviceAddress(a)
    u
  }
  let as_usage = @vk.VK_BUFFER_USAGE_ACCELERATION_STRUCTURE_STORAGE_BIT_KHR | @vk.VK_BUFFER_USAGE_SHADER_DEVICE_ADDRESS_BIT
  let geo_usage = @vk.VK_BUFFER_USAGE_ACCELERATION_STRUCTURE_BUILD_INPUT_READ_ONLY_BIT_KHR | @vk.VK_BUFFER_USAGE_SHADER_DEVICE_ADDRESS_BIT | @vk.VK_BUFFER_USAGE_TRANSFER_DST_BIT

  // triangle geometry
  let (vbuf, vmem) = mkbuf((36 : UInt64), geo_usage, host)
  let verts = FixedArray::make(9, (0.0 : Float))
  verts[0] = (-1.0 : Float)
  verts[1] = (-1.0 : Float)
  verts[2] = (0.0 : Float)
  verts[3] = (1.0 : Float)
  verts[4] = (-1.0 : Float)
  verts[5] = (0.0 : Float)
  verts[6] = (0.0 : Float)
  verts[7] = (1.0 : Float)
  verts[8] = (0.0 : Float)
  let _ = @vk.upload_buffer(dev, vmem, verts, 36)
  let (ibuf, imem) = mkbuf((12 : UInt64), geo_usage, host)
  let idx = FixedArray::make(3, (0 : UInt32))
  idx[1] = (1 : UInt32)
  idx[2] = (2 : UInt32)
  let _ = @vk.upload_uint32(dev, imem, idx, 12)

  // BLAS
  let tri = @vk.VkAccelerationStructureGeometryTrianglesDataKHR::new()
  tri.set_vertexFormat(@vk.VK_FORMAT_R32G32B32_SFLOAT)
  tri.set_vertexData(devaddr(baddr(vbuf)))
  tri.set_vertexStride((12 : UInt64))
  tri.set_maxVertex((2 : UInt32))
  tri.set_indexType(@vk.VK_INDEX_TYPE_UINT32)
  tri.set_indexData(devaddr(baddr(ibuf)))
  let geo = @vk.VkAccelerationStructureGeometryKHR::new()
  geo.set_geometryType(@vk.VK_GEOMETRY_TYPE_TRIANGLES_KHR)
  geo.set_flags(@vk.VK_GEOMETRY_OPAQUE_BIT_KHR)
  let gdata = @vk.VkAccelerationStructureGeometryDataKHR::new()
  gdata.set_triangles(tri)
  geo.set_geometry(gdata)
  let binfo = @vk.VkAccelerationStructureBuildGeometryInfoKHR::new()
  binfo.set_type(@vk.VK_ACCELERATION_STRUCTURE_TYPE_BOTTOM_LEVEL_KHR)
  binfo.set_flags(@vk.VK_BUILD_ACCELERATION_STRUCTURE_PREFER_FAST_TRACE_BIT_KHR | @vk.VK_BUILD_ACCELERATION_STRUCTURE_ALLOW_COMPACTION_BIT_KHR)
  binfo.set_mode(@vk.VK_BUILD_ACCELERATION_STRUCTURE_MODE_BUILD_KHR)
  binfo.set_geometryCount((1 : UInt32))
  binfo.set_pGeometries(geo)
  let primcount = FixedArray::make(1, (1 : UInt32))
  let sizes = @vk.VkAccelerationStructureBuildSizesInfoKHR::new()
  (dfn.vkGetAccelerationStructureBuildSizesKHR)(dev, @vk.VK_ACCELERATION_STRUCTURE_BUILD_TYPE_DEVICE_KHR, binfo, primcount, sizes)
  n = n + 1
  let (blasbuf, blasmem) = mkbuf(sizes.get_accelerationStructureSize(), as_usage, host)
  let bci = @vk.VkAccelerationStructureCreateInfoKHR::new()
  bci.set_buffer(blasbuf)
  bci.set_size(sizes.get_accelerationStructureSize())
  bci.set_type(@vk.VK_ACCELERATION_STRUCTURE_TYPE_BOTTOM_LEVEL_KHR)
  let blas_out = FixedArray::make(1, @vk.VkAccelerationStructureKHR::null())
  let _ = (dfn.vkCreateAccelerationStructureKHR)(dev, bci, na, blas_out)
  n = n + 1
  let blas = blas_out[0]
  let (scratch, scratchmem) = mkbuf(sizes.get_buildScratchSize(), @vk.VK_BUFFER_USAGE_STORAGE_BUFFER_BIT | @vk.VK_BUFFER_USAGE_SHADER_DEVICE_ADDRESS_BIT, dev_local)
  binfo.set_dstAccelerationStructure(blas)
  binfo.set_scratchData(devaddr_mut(baddr(scratch)))
  let rangeinfo = @vk.VkAccelerationStructureBuildRangeInfoKHR::new()
  rangeinfo.set_primitiveCount((1 : UInt32))
  rangeinfo.set_firstVertex((0 : UInt32))
  let ranges = FixedArray::make(1, rangeinfo.as_ptr())

  let cpobj = @vk.VkCommandPoolCreateInfo::new()
  cpobj.set_queueFamilyIndex((0 : UInt32))
  cpobj.set_flags(@vk.VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT)
  let cp_out = FixedArray::make(1, @vk.VkCommandPool::null())
  let _ = (dfn.vkCreateCommandPool)(dev, cpobj, na, cp_out)
  let cbai = @vk.VkCommandBufferAllocateInfo::new()
  cbai.set_commandPool(cp_out[0])
  cbai.set_level(@vk.VK_COMMAND_BUFFER_LEVEL_PRIMARY)
  cbai.set_commandBufferCount((1 : UInt32))
  let cb_out = FixedArray::make(1, @vk.VkCommandBuffer::null())
  let _ = (dfn.vkAllocateCommandBuffers)(dev, cbai, cb_out)
  let cb = cb_out[0]
  let bi = @vk.VkCommandBufferBeginInfo::new()
  bi.set_flags(@vk.VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT)
  let _ = (dfn.vkBeginCommandBuffer)(cb, bi)
  (dfn.vkCmdBuildAccelerationStructuresKHR)(cb, (1 : UInt32), binfo, ranges)
  n = n + 1
  let _ = (dfn.vkEndCommandBuffer)(cb)
  let fci = @vk.VkFenceCreateInfo::new()
  let fence_out = FixedArray::make(1, @vk.VkFence::null())
  let _ = (dfn.vkCreateFence)(dev, fci, na, fence_out)
  let si = @vk.VkSubmitInfo::new()
  si.set_commandBufferCount((1 : UInt32))
  si.set_pCommandBuffers(cb_out)
  let _ = (dfn.vkQueueSubmit)(queue, (1 : UInt32), si, fence_out[0])
  let _ = (dfn.vkWaitForFences)(dev, (1 : UInt32), fence_out, (1 : UInt32), (20000000000 : UInt64))
  let _ = (dfn.vkResetFences)(dev, (1 : UInt32), fence_out)
  let blasaddr_i = @vk.VkAccelerationStructureDeviceAddressInfoKHR::new()
  blasaddr_i.set_accelerationStructure(blas)
  let blas_addr = (dfn.vkGetAccelerationStructureDeviceAddressKHR)(dev, blasaddr_i)
  n = n + 1

  // TLAS with one instance
  let xform = @vk.VkTransformMatrixKHR::new()
  xform.set_matrix(@tmath.Affine3::identity().to_vk_transform_3x4_bytes())
  let insts = @vk.rt_instance_array(1)
  @vk.rt_instance_set(insts, 0, xform, (0 : UInt32), (0xFF : UInt32), (0 : UInt32), @vk.VK_GEOMETRY_INSTANCE_TRIANGLE_FACING_CULL_DISABLE_BIT_KHR, blas_addr)
  let (instbuf, instmem) = mkbuf((64 : UInt64), geo_usage, host)
  let (stg, stgmem) = mkbuf((64 : UInt64), @vk.VK_BUFFER_USAGE_TRANSFER_SRC_BIT, host)
  let stgh = FixedArray::make(1, (0 : UInt64))
  let _ = (dfn.vkMapMemory)(dev, stgmem, (0 : UInt64), (64 : UInt64), (0 : UInt32), stgh)
  @vk.memcpy_ptr(stgh[0], insts, 64)
  (dfn.vkUnmapMemory)(dev, stgmem)
  let tgeo = @vk.VkAccelerationStructureGeometryInstancesDataKHR::new()
  tgeo.set_data(devaddr(baddr(instbuf)))
  let tgeoi = @vk.VkAccelerationStructureGeometryKHR::new()
  tgeoi.set_geometryType(@vk.VK_GEOMETRY_TYPE_INSTANCES_KHR)
  let tdata = @vk.VkAccelerationStructureGeometryDataKHR::new()
  tdata.set_instances(tgeo)
  tgeoi.set_geometry(tdata)
  let tinfo = @vk.VkAccelerationStructureBuildGeometryInfoKHR::new()
  tinfo.set_type(@vk.VK_ACCELERATION_STRUCTURE_TYPE_TOP_LEVEL_KHR)
  tinfo.set_flags(@vk.VK_BUILD_ACCELERATION_STRUCTURE_PREFER_FAST_TRACE_BIT_KHR)
  tinfo.set_mode(@vk.VK_BUILD_ACCELERATION_STRUCTURE_MODE_BUILD_KHR)
  tinfo.set_geometryCount((1 : UInt32))
  tinfo.set_pGeometries(tgeoi)
  let tsizes = @vk.VkAccelerationStructureBuildSizesInfoKHR::new()
  (dfn.vkGetAccelerationStructureBuildSizesKHR)(dev, @vk.VK_ACCELERATION_STRUCTURE_BUILD_TYPE_DEVICE_KHR, tinfo, primcount, tsizes)
  let (tlasbuf, tlasmem) = mkbuf(tsizes.get_accelerationStructureSize(), as_usage, dev_local)
  let tci = @vk.VkAccelerationStructureCreateInfoKHR::new()
  tci.set_buffer(tlasbuf)
  tci.set_size(tsizes.get_accelerationStructureSize())
  tci.set_type(@vk.VK_ACCELERATION_STRUCTURE_TYPE_TOP_LEVEL_KHR)
  let tlas_out = FixedArray::make(1, @vk.VkAccelerationStructureKHR::null())
  let _ = (dfn.vkCreateAccelerationStructureKHR)(dev, tci, na, tlas_out)
  let tlas = tlas_out[0]
  let (tscratch, tscratchmem) = mkbuf(tsizes.get_buildScratchSize(), @vk.VK_BUFFER_USAGE_STORAGE_BUFFER_BIT | @vk.VK_BUFFER_USAGE_SHADER_DEVICE_ADDRESS_BIT, dev_local)
  tinfo.set_dstAccelerationStructure(tlas)
  tinfo.set_scratchData(devaddr_mut(baddr(tscratch)))
  let trange = @vk.VkAccelerationStructureBuildRangeInfoKHR::new()
  trange.set_primitiveCount((1 : UInt32))
  let tranges = FixedArray::make(1, trange.as_ptr())
  let _ = (dfn.vkResetCommandBuffer)(cb, (0 : UInt32))
  let _ = (dfn.vkBeginCommandBuffer)(cb, bi)
  let bcopy = @vk.VkBufferCopy::new()
  bcopy.set_size((64 : UInt64))
  (dfn.vkCmdCopyBuffer)(cb, stg, instbuf, (1 : UInt32), bcopy)
  let mb0 = @vk.VkMemoryBarrier2::new()
  mb0.set_srcStageMask(@vk.VK_PIPELINE_STAGE_2_ALL_TRANSFER_BIT)
  mb0.set_srcAccessMask(@vk.VK_ACCESS_2_TRANSFER_WRITE_BIT)
  mb0.set_dstStageMask(@vk.VK_PIPELINE_STAGE_2_ACCELERATION_STRUCTURE_BUILD_BIT_KHR)
  mb0.set_dstAccessMask(@vk.VK_ACCESS_2_ACCELERATION_STRUCTURE_READ_BIT_KHR)
  let dep0 = @vk.VkDependencyInfo::new()
  dep0.set_memoryBarrierCount((1 : UInt32))
  dep0.set_pMemoryBarriers(mb0)
  (dfn.vkCmdPipelineBarrier2)(cb, dep0)
  (dfn.vkCmdBuildAccelerationStructuresKHR)(cb, (1 : UInt32), tinfo, tranges)
  let _ = (dfn.vkEndCommandBuffer)(cb)
  let _ = (dfn.vkQueueSubmit)(queue, (1 : UInt32), si, fence_out[0])
  let _ = (dfn.vkWaitForFences)(dev, (1 : UInt32), fence_out, (1 : UInt32), (20000000000 : UInt64))
  let _ = (dfn.vkResetFences)(dev, (1 : UInt32), fence_out)
  let taddr_i = @vk.VkAccelerationStructureDeviceAddressInfoKHR::new()
  taddr_i.set_accelerationStructure(tlas)
  let _tlas_addr = (dfn.vkGetAccelerationStructureDeviceAddressKHR)(dev, taddr_i)

  // ray tracing pipeline: raygen + miss + closesthit
  let rgen = @shader.compile_shader_file_env("examples/24-raytracing/shader.rgen", @shader.SHADER_KIND_RAYGEN, @shader.SHADER_ENV_VULKAN_1_3)
  let rmiss = @shader.compile_shader_file_env("examples/24-raytracing/shader.rmiss", @shader.SHADER_KIND_MISS, @shader.SHADER_ENV_VULKAN_1_3)
  let rchit = @shader.compile_shader_file_env("examples/24-raytracing/shader.rchit", @shader.SHADER_KIND_CLOSESTHIT, @shader.SHADER_ENV_VULKAN_1_3)
  if rgen.length() == 0 || rmiss.length() == 0 || rchit.length() == 0 {
    println("[24-rt] FAIL — ray tracing shaders did not compile")
    return
  }
  let mkm = fn(code : FixedArray[UInt32]) -> @vk.VkShaderModule {
    let ci = @vk.VkShaderModuleCreateInfo::new()
    ci.set_codeSize((code.length() * 4).to_uint64())
    ci.set_pCode(code)
    let o = FixedArray::make(1, @vk.VkShaderModule::null())
    let _ = (dfn.vkCreateShaderModule)(dev, ci, na, o)
    ci.free()
    o[0]
  }
  let mgen = mkm(rgen)
  let mmiss = mkm(rmiss)
  let mchit = mkm(rchit)
  let stages = @vk.VkPipelineShaderStageCreateInfo::array(3)
  stages.set_stage_at(0, @vk.VK_SHADER_STAGE_RAYGEN_BIT_KHR)
  stages.set_module_at(0, mgen)
  stages.set_pName_at(0, @vk.cstr("main"))
  stages.set_stage_at(1, @vk.VK_SHADER_STAGE_MISS_BIT_KHR)
  stages.set_module_at(1, mmiss)
  stages.set_pName_at(1, @vk.cstr("main"))
  stages.set_stage_at(2, @vk.VK_SHADER_STAGE_CLOSEST_HIT_BIT_KHR)
  stages.set_module_at(2, mchit)
  stages.set_pName_at(2, @vk.cstr("main"))
  let groups = @vk.VkRayTracingShaderGroupCreateInfoKHR::array(3)
  groups.set_type_at(0, @vk.VK_RAY_TRACING_SHADER_GROUP_TYPE_GENERAL_KHR)
  groups.set_generalShader_at(0, (0 : UInt32))
  groups.set_closestHitShader_at(0, (0xFFFFFFFF : UInt32))
  groups.set_anyHitShader_at(0, (0xFFFFFFFF : UInt32))
  groups.set_intersectionShader_at(0, (0xFFFFFFFF : UInt32))
  groups.set_type_at(1, @vk.VK_RAY_TRACING_SHADER_GROUP_TYPE_GENERAL_KHR)
  groups.set_generalShader_at(1, (1 : UInt32))
  groups.set_closestHitShader_at(1, (0xFFFFFFFF : UInt32))
  groups.set_anyHitShader_at(1, (0xFFFFFFFF : UInt32))
  groups.set_intersectionShader_at(1, (0xFFFFFFFF : UInt32))
  groups.set_type_at(2, @vk.VK_RAY_TRACING_SHADER_GROUP_TYPE_TRIANGLES_HIT_GROUP_KHR)
  groups.set_generalShader_at(2, (0xFFFFFFFF : UInt32))
  groups.set_closestHitShader_at(2, (2 : UInt32))
  groups.set_anyHitShader_at(2, (0xFFFFFFFF : UInt32))
  groups.set_intersectionShader_at(2, (0xFFFFFFFF : UInt32))
  // descriptors: set 0 = TLAS + output storage buffer
  let bindings = @vk.VkDescriptorSetLayoutBinding::array(2)
  bindings.set_binding_at(0, (0 : UInt32))
  bindings.set_descriptorType_at(0, @vk.VK_DESCRIPTOR_TYPE_ACCELERATION_STRUCTURE_KHR)
  bindings.set_descriptorCount_at(0, (1 : UInt32))
  bindings.set_stageFlags_at(0, @vk.VK_SHADER_STAGE_RAYGEN_BIT_KHR)
  bindings.set_binding_at(1, (1 : UInt32))
  bindings.set_descriptorType_at(1, @vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER)
  bindings.set_descriptorCount_at(1, (1 : UInt32))
  bindings.set_stageFlags_at(1, @vk.VK_SHADER_STAGE_RAYGEN_BIT_KHR)
  let dslci = @vk.VkDescriptorSetLayoutCreateInfo::new()
  dslci.set_bindingCount((2 : UInt32))
  dslci.set_pBindings(bindings)
  let dsl_out = FixedArray::make(1, @vk.VkDescriptorSetLayout::null())
  let _ = (dfn.vkCreateDescriptorSetLayout)(dev, dslci, na, dsl_out)
  let plci = @vk.VkPipelineLayoutCreateInfo::new()
  plci.set_setLayoutCount((1 : UInt32))
  plci.set_pSetLayouts(dsl_out)
  let pl_out = FixedArray::make(1, @vk.VkPipelineLayout::null())
  let _ = (dfn.vkCreatePipelineLayout)(dev, plci, na, pl_out)
  let rtpci = @vk.VkRayTracingPipelineCreateInfoKHR::new()
  rtpci.set_stageCount((3 : UInt32))
  rtpci.set_pStages(stages)
  rtpci.set_groupCount((3 : UInt32))
  rtpci.set_pGroups(groups)
  rtpci.set_maxPipelineRayRecursionDepth((1 : UInt32))
  rtpci.set_layout(pl_out[0])
  if rtq.get_rayTracingPipelineShaderGroupHandleCaptureReplay() != 0 {
    rtpci.set_flags(@vk.VK_PIPELINE_CREATE_RAY_TRACING_SHADER_GROUP_HANDLE_CAPTURE_REPLAY_BIT_KHR)
  }
  let rtdyn = @vk.VkPipelineDynamicStateCreateInfo::new()
  rtdyn.set_dynamicStateCount((1 : UInt32))
  rtdyn.set_pDynamicStates(FixedArray::make(1, @vk.VK_DYNAMIC_STATE_RAY_TRACING_PIPELINE_STACK_SIZE_KHR))
  rtpci.set_pDynamicState(rtdyn)
  let rtpipe_out = FixedArray::make(1, @vk.VkPipeline::null())
  let rtpr = (dfn.vkCreateRayTracingPipelinesKHR)(dev, @vk.VkDeferredOperationKHR::null(), @vk.VkPipelineCache::null(), (1 : UInt32), rtpci, na, rtpipe_out)
  n = n + 1
  if rtpr != 0 {
    println("[24-rt] FAIL — ray tracing pipeline=\{rtpr}")
    return
  }
  let rtpipe = rtpipe_out[0]
  let rtpprops = @vk.VkPhysicalDeviceRayTracingPipelinePropertiesKHR::new()
  let props2 = @vk.VkPhysicalDeviceProperties2::new()
  props2.set_pNext(rtpprops.as_ptr())
  (ifn.vkGetPhysicalDeviceProperties2)(phys, props2)
  let handle_size = rtpprops.get_shaderGroupHandleSize()
  let handle_align = rtpprops.get_shaderGroupHandleAlignment()
  let base_align = rtpprops.get_shaderGroupBaseAlignment()
  let stride = ((handle_size + handle_align - 1) / handle_align) * handle_align
  let sbt_size = base_align * 3
  let (sbt, sbtmem) = mkbuf(sbt_size.to_uint64(), @vk.VK_BUFFER_USAGE_SHADER_BINDING_TABLE_BIT_KHR | @vk.VK_BUFFER_USAGE_SHADER_DEVICE_ADDRESS_BIT, host)
  let handles = FixedArray::make(handle_size.reinterpret_as_int() * 3, (0 : Byte))
  let hr = (dfn.vkGetRayTracingShaderGroupHandlesKHR)(dev, rtpipe, (0 : UInt32), (3 : UInt32), (handle_size * 3).to_uint64(), @vk.byte_ptr(handles))
  n = n + 1
  if hr != 0 {
    println("[24-rt] FAIL — shader group handles=\{hr}")
    return
  }
  let sbth = FixedArray::make(1, (0 : UInt64))
  let _ = (dfn.vkMapMemory)(dev, sbtmem, (0 : UInt64), sbt_size.to_uint64(), (0 : UInt32), sbth)
  for g = 0; g < 3; g = g + 1 {
    let _ = @vk.memcpy_ptr(sbth[0] + (g.reinterpret_as_uint() * base_align).to_uint64(), @vk.byte_ptr(handles) + (g.reinterpret_as_uint() * handle_size).to_uint64(), handle_size.reinterpret_as_int())
  }
  (dfn.vkUnmapMemory)(dev, sbtmem)
  let sbt_addr = baddr(sbt)
  if has("vkGetRayTracingShaderGroupStackSizeKHR") {
    let _ = (dfn.vkGetRayTracingShaderGroupStackSizeKHR)(dev, rtpipe, (0 : UInt32), @vk.VK_SHADER_GROUP_SHADER_GENERAL_KHR)
    n = n + 1
  }

  // output buffer + descriptor set
  let (obuf, omem) = mkbuf((64 : UInt64), @vk.VK_BUFFER_USAGE_STORAGE_BUFFER_BIT, host)
  let dpsizes = @vk.VkDescriptorPoolSize::array(2)
  dpsizes.set_type_at(0, @vk.VK_DESCRIPTOR_TYPE_ACCELERATION_STRUCTURE_KHR)
  dpsizes.set_descriptorCount_at(0, (1 : UInt32))
  dpsizes.set_type_at(1, @vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER)
  dpsizes.set_descriptorCount_at(1, (1 : UInt32))
  let dpci = @vk.VkDescriptorPoolCreateInfo::new()
  dpci.set_maxSets((1 : UInt32))
  dpci.set_poolSizeCount((2 : UInt32))
  dpci.set_pPoolSizes(dpsizes)
  let pool_out = FixedArray::make(1, @vk.VkDescriptorPool::null())
  let _ = (dfn.vkCreateDescriptorPool)(dev, dpci, na, pool_out)
  let dsai = @vk.VkDescriptorSetAllocateInfo::new()
  dsai.set_descriptorPool(pool_out[0])
  dsai.set_descriptorSetCount((1 : UInt32))
  dsai.set_pSetLayouts(dsl_out)
  let ds_out = FixedArray::make(1, @vk.VkDescriptorSet::null())
  let _ = (dfn.vkAllocateDescriptorSets)(dev, dsai, ds_out)
  let aswrite = @vk.VkWriteDescriptorSetAccelerationStructureKHR::new()
  aswrite.set_accelerationStructureCount((1 : UInt32))
  aswrite.set_pAccelerationStructures(tlas_out)
  let writes = @vk.VkWriteDescriptorSet::array(2)
  writes.set_dstSet_at(0, ds_out[0])
  writes.set_dstBinding_at(0, (0 : UInt32))
  writes.set_descriptorCount_at(0, (1 : UInt32))
  writes.set_descriptorType_at(0, @vk.VK_DESCRIPTOR_TYPE_ACCELERATION_STRUCTURE_KHR)
  writes.set_pNext_at(0, aswrite.as_ptr())
  let dbi = @vk.VkDescriptorBufferInfo::new()
  dbi.set_buffer(obuf)
  dbi.set_range((64 : UInt64))
  writes.set_dstSet_at(1, ds_out[0])
  writes.set_dstBinding_at(1, (1 : UInt32))
  writes.set_descriptorCount_at(1, (1 : UInt32))
  writes.set_descriptorType_at(1, @vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER)
  writes.set_pBufferInfo_at(1, dbi)
  (dfn.vkUpdateDescriptorSets)(dev, (2 : UInt32), writes, (0 : UInt32), @vk.VkCopyDescriptorSet::null())

  // trace
  let _ = (dfn.vkResetCommandBuffer)(cb, (0 : UInt32))
  let _ = (dfn.vkBeginCommandBuffer)(cb, bi)
  (dfn.vkCmdBindPipeline)(cb, @vk.VK_PIPELINE_BIND_POINT_RAY_TRACING_KHR, rtpipe)
  (dfn.vkCmdBindDescriptorSets)(cb, @vk.VK_PIPELINE_BIND_POINT_RAY_TRACING_KHR, pl_out[0], (0 : UInt32), (1 : UInt32), ds_out, (0 : UInt32), FixedArray::make(0, (0 : UInt32)))
  if has("vkCmdSetRayTracingPipelineStackSizeKHR") {
    (dfn.vkCmdSetRayTracingPipelineStackSizeKHR)(cb, (4096 : UInt32))
    n = n + 1
  }
  let mkregion = fn(off : UInt64, sz : UInt64) -> @vk.VkStridedDeviceAddressRegionKHR {
    let r = @vk.VkStridedDeviceAddressRegionKHR::new()
    r.set_deviceAddress(sbt_addr + off)
    r.set_stride(sz)
    r.set_size(sz)
    r
  }
  let rgen_r = mkregion((0 : UInt64), stride.to_uint64())
  let miss_r = mkregion((base_align).to_uint64(), stride.to_uint64())
  let hit_r = mkregion((base_align * 2).to_uint64(), stride.to_uint64())
  let call_r = @vk.VkStridedDeviceAddressRegionKHR::new()
  if has("vkCmdTraceRaysKHR") {
    (dfn.vkCmdTraceRaysKHR)(cb, rgen_r, miss_r, hit_r, call_r, (1 : UInt32), (1 : UInt32), (1 : UInt32))
    n = n + 1
  }
  let mb1 = @vk.VkMemoryBarrier2::new()
  mb1.set_srcStageMask(@vk.VK_PIPELINE_STAGE_2_RAY_TRACING_SHADER_BIT_KHR)
  mb1.set_srcAccessMask(@vk.VK_ACCESS_2_SHADER_STORAGE_WRITE_BIT)
  mb1.set_dstStageMask(@vk.VK_PIPELINE_STAGE_2_HOST_BIT)
  mb1.set_dstAccessMask(@vk.VK_ACCESS_2_HOST_READ_BIT)
  let dep1 = @vk.VkDependencyInfo::new()
  dep1.set_memoryBarrierCount((1 : UInt32))
  dep1.set_pMemoryBarriers(mb1)
  (dfn.vkCmdPipelineBarrier2)(cb, dep1)
  let _ = (dfn.vkEndCommandBuffer)(cb)
  let sr = (dfn.vkQueueSubmit)(queue, (1 : UInt32), si, fence_out[0])
  let wr = (dfn.vkWaitForFences)(dev, (1 : UInt32), fence_out, (1 : UInt32), (30000000000 : UInt64))
  let got = @vk.download_buffer(dev, omem, 8)
  let hit = got[0].to_int() + got[1].to_int() * 256
  let _ = (dfn.vkDeviceWaitIdle)(dev)


  let freebuf = fn(b : @vk.VkBuffer, m : @vk.VkDeviceMemory) -> Unit {
    (dfn.vkDestroyBuffer)(dev, b, na)
    (dfn.vkFreeMemory)(dev, m, na)
  }
  // ---- remaining ray tracing surface: host build/copy, indirect, properties ----
  let (blas2buf, blas2mem) = mkbuf(sizes.get_accelerationStructureSize(), as_usage, host)
  let bci2 = @vk.VkAccelerationStructureCreateInfoKHR::new()
  bci2.set_buffer(blas2buf)
  bci2.set_size(sizes.get_accelerationStructureSize())
  bci2.set_type(@vk.VK_ACCELERATION_STRUCTURE_TYPE_BOTTOM_LEVEL_KHR)
  let blas2_out = FixedArray::make(1, @vk.VkAccelerationStructureKHR::null())
  let _ = (dfn.vkCreateAccelerationStructureKHR)(dev, bci2, na, blas2_out)
  let blas2 = blas2_out[0]
  let as_arr = FixedArray::make(1, blas)
  let (serbuf, sermem) = mkbuf(sizes.get_accelerationStructureSize() + 256, @vk.VK_BUFFER_USAGE_TRANSFER_DST_BIT | @vk.VK_BUFFER_USAGE_TRANSFER_SRC_BIT | @vk.VK_BUFFER_USAGE_SHADER_DEVICE_ADDRESS_BIT, host)
  let qpci2 = @vk.VkQueryPoolCreateInfo::new()
  qpci2.set_queryType(@vk.VK_QUERY_TYPE_ACCELERATION_STRUCTURE_COMPACTED_SIZE_KHR)
  qpci2.set_queryCount((1 : UInt32))
  let qp2_out = FixedArray::make(1, @vk.VkQueryPool::null())
  let _ = (dfn.vkCreateQueryPool)(dev, qpci2, na, qp2_out)

  let host_ok = asq.get_accelerationStructureHostCommands() != 0
  // host-side build into blas2 (deferred operation handle is optional)
  let binfo2 = @vk.VkAccelerationStructureBuildGeometryInfoKHR::new()
  binfo2.set_type(@vk.VK_ACCELERATION_STRUCTURE_TYPE_BOTTOM_LEVEL_KHR)
  binfo2.set_flags(@vk.VK_BUILD_ACCELERATION_STRUCTURE_PREFER_FAST_TRACE_BIT_KHR | @vk.VK_BUILD_ACCELERATION_STRUCTURE_ALLOW_COMPACTION_BIT_KHR)
  binfo2.set_mode(@vk.VK_BUILD_ACCELERATION_STRUCTURE_MODE_BUILD_KHR)
  binfo2.set_geometryCount((1 : UInt32))
  binfo2.set_pGeometries(geo)
  binfo2.set_dstAccelerationStructure(blas2)
  binfo2.set_scratchData(devaddr_mut(baddr(scratch)))
  if host_ok && has("vkBuildAccelerationStructuresKHR") {
    let _ = (dfn.vkBuildAccelerationStructuresKHR)(dev, @vk.VkDeferredOperationKHR::null(), (1 : UInt32), binfo2, ranges)
    n = n + 1
  }
  // host copy blas -> blas2, then serialize to memory and back
  let cpi = @vk.VkCopyAccelerationStructureInfoKHR::new()
  cpi.set_src(blas)
  cpi.set_dst(blas2)
  cpi.set_mode(@vk.VK_COPY_ACCELERATION_STRUCTURE_MODE_CLONE_KHR)
  if host_ok && has("vkCopyAccelerationStructureKHR") {
    let _ = (dfn.vkCopyAccelerationStructureKHR)(dev, @vk.VkDeferredOperationKHR::null(), cpi)
    n = n + 1
  }
  let ctmi = @vk.VkCopyAccelerationStructureToMemoryInfoKHR::new()
  ctmi.set_src(blas)
  ctmi.set_dst(devaddr_mut(baddr(serbuf)))
  ctmi.set_mode(@vk.VK_COPY_ACCELERATION_STRUCTURE_MODE_SERIALIZE_KHR)
  if host_ok && has("vkCopyAccelerationStructureToMemoryKHR") {
    let _ = (dfn.vkCopyAccelerationStructureToMemoryKHR)(dev, @vk.VkDeferredOperationKHR::null(), ctmi)
    n = n + 1
  }
  let cmti = @vk.VkCopyMemoryToAccelerationStructureInfoKHR::new()
  cmti.set_src(devaddr(baddr(serbuf)))
  cmti.set_dst(blas2)
  cmti.set_mode(@vk.VK_COPY_ACCELERATION_STRUCTURE_MODE_DESERIALIZE_KHR)
  if host_ok && has("vkCopyMemoryToAccelerationStructureKHR") {
    let _ = (dfn.vkCopyMemoryToAccelerationStructureKHR)(dev, @vk.VkDeferredOperationKHR::null(), cmti)
    n = n + 1
  }
  // host properties query
  if host_ok && has("vkWriteAccelerationStructuresPropertiesKHR") {
    let qres = FixedArray::make(1, (0 : UInt64))
    let _ = (dfn.vkWriteAccelerationStructuresPropertiesKHR)(dev, (1 : UInt32), as_arr, @vk.VK_QUERY_TYPE_ACCELERATION_STRUCTURE_COMPACTED_SIZE_KHR, (8 : UInt64), @vk.uint64_ptr(qres), (8 : UInt64))
    n = n + 1
  }
  // compatibility check against the device's AS version
  if has("vkGetDeviceAccelerationStructureCompatibilityKHR") {
    let ver = @vk.VkAccelerationStructureVersionInfoKHR::new()
    let vdata = FixedArray::make(16, (0 : Byte))
    vdata[0] = (1 : Byte)
    ver.set_pVersionData(vdata)
    let compat = FixedArray::make(1, (0 : UInt32))
    (dfn.vkGetDeviceAccelerationStructureCompatibilityKHR)(dev, ver, compat)
    n = n + 1
  }
  if has("vkGetRayTracingCaptureReplayShaderGroupHandlesKHR") && rtq.get_rayTracingPipelineShaderGroupHandleCaptureReplay() != 0 {
    let crsize = rtpprops.get_shaderGroupHandleCaptureReplaySize()
    let cap = FixedArray::make(crsize.reinterpret_as_int() * 3, (0 : Byte))
    let _ = (dfn.vkGetRayTracingCaptureReplayShaderGroupHandlesKHR)(dev, rtpipe, (0 : UInt32), (3 : UInt32), (crsize * 3).to_uint64(), @vk.byte_ptr(cap))
    n = n + 1
  }

  // device-side: indirect build, copies, properties query, indirect trace
  let (indbuf, indmem) = mkbuf((256 : UInt64), @vk.VK_BUFFER_USAGE_INDIRECT_BUFFER_BIT | @vk.VK_BUFFER_USAGE_SHADER_DEVICE_ADDRESS_BIT, host)
  let indh = FixedArray::make(1, (0 : UInt64))
  let _ = (dfn.vkMapMemory)(dev, indmem, (0 : UInt64), (256 : UInt64), (0 : UInt32), indh)
  // VkAccelerationStructureBuildRangeInfoKHR {primitiveCount, primitiveOffset, firstVertex, transformOffset}
  let rbytes = FixedArray::make(4, (0 : UInt32))
  rbytes[0] = (1 : UInt32)
  @vk.memcpy_ptr(indh[0], @vk.uint32_ptr(rbytes), 16)
  // VkTraceRaysIndirectCommandKHR {width,height,depth} at offset 64
  let dims = FixedArray::make(3, (1 : UInt32))
  @vk.memcpy_ptr(indh[0] + 64, @vk.uint32_ptr(dims), 12)
  (dfn.vkUnmapMemory)(dev, indmem)
  let ind_addr = baddr(indbuf)
  let _ = (dfn.vkResetCommandBuffer)(cb, (0 : UInt32))
  let _ = (dfn.vkBeginCommandBuffer)(cb, bi)
  if asq.get_accelerationStructureIndirectBuild() != 0 && has("vkCmdBuildAccelerationStructuresIndirectKHR") {
    let binfo3 = @vk.VkAccelerationStructureBuildGeometryInfoKHR::new()
    binfo3.set_type(@vk.VK_ACCELERATION_STRUCTURE_TYPE_BOTTOM_LEVEL_KHR)
    binfo3.set_mode(@vk.VK_BUILD_ACCELERATION_STRUCTURE_MODE_BUILD_KHR)
    binfo3.set_geometryCount((1 : UInt32))
    binfo3.set_pGeometries(geo)
    binfo3.set_dstAccelerationStructure(blas2)
    binfo3.set_scratchData(devaddr_mut(baddr(scratch)))
    let maxcounts = FixedArray::make(1, (1 : UInt32))
    let strides = FixedArray::make(1, (16 : UInt64))
    let pp = FixedArray::make(1, ind_addr)
    (dfn.vkCmdBuildAccelerationStructuresIndirectKHR)(cb, (1 : UInt32), binfo3, pp, maxcounts, strides)
    n = n + 1
    binfo3.free()
  }
  if has("vkCmdCopyAccelerationStructureKHR") {
    (dfn.vkCmdCopyAccelerationStructureKHR)(cb, cpi)
    n = n + 1
  }
  if has("vkCmdCopyAccelerationStructureToMemoryKHR") {
    (dfn.vkCmdCopyAccelerationStructureToMemoryKHR)(cb, ctmi)
    n = n + 1
  }
  if has("vkCmdCopyMemoryToAccelerationStructureKHR") {
    (dfn.vkCmdCopyMemoryToAccelerationStructureKHR)(cb, cmti)
    n = n + 1
  }
  if has("vkCmdWriteAccelerationStructuresPropertiesKHR") {
    (dfn.vkCmdResetQueryPool)(cb, qp2_out[0], (0 : UInt32), (1 : UInt32))
    (dfn.vkCmdWriteAccelerationStructuresPropertiesKHR)(cb, (1 : UInt32), as_arr, @vk.VK_QUERY_TYPE_ACCELERATION_STRUCTURE_COMPACTED_SIZE_KHR, qp2_out[0], (0 : UInt32))
    n = n + 1
  }
  (dfn.vkCmdBindPipeline)(cb, @vk.VK_PIPELINE_BIND_POINT_RAY_TRACING_KHR, rtpipe)
  (dfn.vkCmdBindDescriptorSets)(cb, @vk.VK_PIPELINE_BIND_POINT_RAY_TRACING_KHR, pl_out[0], (0 : UInt32), (1 : UInt32), ds_out, (0 : UInt32), FixedArray::make(0, (0 : UInt32)))
  if has("vkCmdSetRayTracingPipelineStackSizeKHR") {
    (dfn.vkCmdSetRayTracingPipelineStackSizeKHR)(cb, (4096 : UInt32))
  }
  if has("vkCmdTraceRaysIndirectKHR") {
    (dfn.vkCmdTraceRaysIndirectKHR)(cb, rgen_r, miss_r, hit_r, call_r, ind_addr + 64)
    n = n + 1
  }
  if has("vkCmdTraceRaysIndirect2KHR") {
    // VkTraceRaysIndirectCommand2KHR lives at offset 128: six strided regions
    // (address,stride,size each) followed by width/height/depth.
    let t2 = @vk.VkTraceRaysIndirectCommand2KHR::new()
    t2.set_raygenShaderRecordAddress(rgen_r.get_deviceAddress())
    t2.set_raygenShaderRecordSize(rgen_r.get_size())
    t2.set_missShaderBindingTableAddress(miss_r.get_deviceAddress())
    t2.set_missShaderBindingTableSize(miss_r.get_size())
    t2.set_missShaderBindingTableStride(miss_r.get_stride())
    t2.set_hitShaderBindingTableAddress(hit_r.get_deviceAddress())
    t2.set_hitShaderBindingTableSize(hit_r.get_size())
    t2.set_hitShaderBindingTableStride(hit_r.get_stride())
    t2.set_width((1 : UInt32))
    t2.set_height((1 : UInt32))
    t2.set_depth((1 : UInt32))
    let _ = (dfn.vkMapMemory)(dev, indmem, (0 : UInt64), (256 : UInt64), (0 : UInt32), indh)
    @vk.memcpy_ptr(indh[0] + 128, t2.as_ptr(), 104)
    (dfn.vkUnmapMemory)(dev, indmem)
    (dfn.vkCmdTraceRaysIndirect2KHR)(cb, ind_addr + 128)
    n = n + 1
    t2.free()
  }
  freebuf(indbuf, indmem)
  let _ = (dfn.vkDeviceWaitIdle)(dev)
  (dfn.vkDestroyQueryPool)(dev, qp2_out[0], na)
  (dfn.vkDestroyAccelerationStructureKHR)(dev, blas2, na)
  freebuf(blas2buf, blas2mem)
  freebuf(serbuf, sermem)
  cpi.free()
  ctmi.free()
  cmti.free()
  binfo2.free()
  bci2.free()
  qpci2.free()
  // teardown
  (dfn.vkDestroyFence)(dev, fence_out[0], na)
  (dfn.vkDestroyCommandPool)(dev, cp_out[0], na)
  (dfn.vkDestroyDescriptorPool)(dev, pool_out[0], na)
  (dfn.vkDestroyDescriptorSetLayout)(dev, dsl_out[0], na)
  (dfn.vkDestroyPipeline)(dev, rtpipe, na)
  (dfn.vkDestroyPipelineLayout)(dev, pl_out[0], na)
  (dfn.vkDestroyShaderModule)(dev, mgen, na)
  (dfn.vkDestroyShaderModule)(dev, mmiss, na)
  (dfn.vkDestroyShaderModule)(dev, mchit, na)
  (dfn.vkDestroyAccelerationStructureKHR)(dev, tlas, na)
  n = n + 1
  (dfn.vkDestroyAccelerationStructureKHR)(dev, blas, na)
  freebuf(vbuf, vmem)
  freebuf(ibuf, imem)
  freebuf(blasbuf, blasmem)
  freebuf(scratch, scratchmem)
  freebuf(tlasbuf, tlasmem)
  freebuf(tscratch, tscratchmem)
  freebuf(instbuf, instmem)
  freebuf(stg, stgmem)
  freebuf(sbt, sbtmem)
  freebuf(obuf, omem)
  @vk.rt_instance_free(insts)
  (dfn.vkDestroyDevice)(dev, na)
  @vk.destroy_debug_messenger(inst, ifn, messenger)
  (ifn.vkDestroyInstance)(inst, na)
  println("[24-rt] commands=\{n} hit=\{hit} submit=\{sr} wait=\{wr} errors=\{g_errors.val}")
  if sr == 0 && wr == 0 && hit == 1 && n >= 8 && g_errors.val == 0 {
    println("[24-rt] OK — \{n} ray tracing commands, ray hit the triangle (payload=1)")
  } else {
    println("[24-rt] FAIL — hit=\{hit} n=\{n} errors=\{g_errors.val}")
  }
}