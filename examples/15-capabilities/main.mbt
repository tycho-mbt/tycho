// Example 15 — device capability dump (headless). The reachability oracle for
// binding coverage: which extensions/versions/features this driver actually
// exposes. Also exercises the fixed-size char-array getters and a four-link
// pNext chain (features2 -> 1.1 -> 1.2 -> 1.3 -> 1.4).

///|
fn feat(sb : StringBuilder, name : String, v : UInt32) -> Unit {
  if v != 0 {
    sb.write_string(name)
    sb.write_string(" ")
  }
}

///|
fn main {
  let na = @vk.VkAllocationCallbacks::null()
  let app = @vk.VkApplicationInfo::new()
  app.set_pApplicationName(@vk.cstr("Tycho Capabilities"))
  app.set_apiVersion((4210688 : UInt32)) // VK_MAKE_API_VERSION(0, 1, 4, 0)
  let ici = @vk.VkInstanceCreateInfo::new()
  ici.set_pApplicationInfo(app)
  let inst_out = FixedArray::make(1, @vk.VkInstance::null())
  let ir = @vk.vkCreateInstance(ici, na, inst_out)
  if ir != 0 {
    println("[15-cap] FAIL — vkCreateInstance=\{ir}")
    return
  }
  let inst = inst_out[0]
  let ifn = @vk.InstanceFn::load(inst)

  // instance extensions
  let iec = FixedArray::make(1, (0 : UInt32))
  let _ = @vk.vkEnumerateInstanceExtensionProperties((0 : UInt64), iec, @vk.VkExtensionProperties::null())
  let iexts = @vk.VkExtensionProperties::array(iec[0].reinterpret_as_int())
  let _ = @vk.vkEnumerateInstanceExtensionProperties((0 : UInt64), iec, iexts)
  let isb = StringBuilder()
  for i = 0; i < iec[0].reinterpret_as_int(); i = i + 1 {
    isb.write_string(iexts.get_extensionName_string_at(i))
    isb.write_string(" ")
  }
  println("[15-cap] instance_extensions(\{iec[0]}): \{isb}")

  let pc = FixedArray::make(1, (16 : UInt32))
  let pdevs = FixedArray::make(16, @vk.VkPhysicalDevice::null())
  let _ = (ifn.vkEnumeratePhysicalDevices)(inst, pc, pdevs)
  let phys = pdevs[0]

  // properties2 -> driver properties (char-array getters)
  let drv = @vk.VkPhysicalDeviceDriverProperties::new()
  let props2 = @vk.VkPhysicalDeviceProperties2::new()
  props2.set_pNext(drv.as_ptr())
  (ifn.vkGetPhysicalDeviceProperties2)(phys, props2)
  let props = props2.get_properties()
  println(
    "[15-cap] device=\{props.get_deviceName_string()} apiVersion=\{props.get_apiVersion()} driverVersion=\{props.get_driverVersion()} deviceType=\{props.get_deviceType()}",
  )
  println("[15-cap] driver=\{drv.get_driverName_string()} info=\{drv.get_driverInfo_string()}")

  // device extensions
  let dec = FixedArray::make(1, (0 : UInt32))
  let _ = (ifn.vkEnumerateDeviceExtensionProperties)(phys, (0 : UInt64), dec, @vk.VkExtensionProperties::null())
  let dexts = @vk.VkExtensionProperties::array(dec[0].reinterpret_as_int())
  let _ = (ifn.vkEnumerateDeviceExtensionProperties)(phys, (0 : UInt64), dec, dexts)
  let dsb = StringBuilder()
  for i = 0; i < dec[0].reinterpret_as_int(); i = i + 1 {
    dsb.write_string(dexts.get_extensionName_string_at(i))
    dsb.write_string(" ")
  }
  println("[15-cap] device_extensions(\{dec[0]}): \{dsb}")

  // four-link pNext feature chain
  let f11 = @vk.VkPhysicalDeviceVulkan11Features::new()
  let f12 = @vk.VkPhysicalDeviceVulkan12Features::new()
  let f13 = @vk.VkPhysicalDeviceVulkan13Features::new()
  let f14 = @vk.VkPhysicalDeviceVulkan14Features::new()
  f13.set_pNext(f14.as_ptr())
  f12.set_pNext(f13.as_ptr())
  f11.set_pNext(f12.as_ptr())
  let f2 = @vk.VkPhysicalDeviceFeatures2::new()
  f2.set_pNext(f11.as_ptr())
  (ifn.vkGetPhysicalDeviceFeatures2)(phys, f2)

  let s11 = StringBuilder()
  feat(s11, "storageBuffer16BitAccess", f11.get_storageBuffer16BitAccess())
  feat(s11, "uniformAndStorageBuffer16BitAccess", f11.get_uniformAndStorageBuffer16BitAccess())
  feat(s11, "storagePushConstant16", f11.get_storagePushConstant16())
  feat(s11, "storageInputOutput16", f11.get_storageInputOutput16())
  feat(s11, "multiview", f11.get_multiview())
  feat(s11, "multiviewGeometryShader", f11.get_multiviewGeometryShader())
  feat(s11, "multiviewTessellationShader", f11.get_multiviewTessellationShader())
  feat(s11, "variablePointersStorageBuffer", f11.get_variablePointersStorageBuffer())
  feat(s11, "variablePointers", f11.get_variablePointers())
  feat(s11, "protectedMemory", f11.get_protectedMemory())
  feat(s11, "samplerYcbcrConversion", f11.get_samplerYcbcrConversion())
  feat(s11, "shaderDrawParameters", f11.get_shaderDrawParameters())
  println("[15-cap] features11: \{s11}")

  let s12 = StringBuilder()
  feat(s12, "samplerMirrorClampToEdge", f12.get_samplerMirrorClampToEdge())
  feat(s12, "drawIndirectCount", f12.get_drawIndirectCount())
  feat(s12, "storageBuffer8BitAccess", f12.get_storageBuffer8BitAccess())
  feat(s12, "uniformAndStorageBuffer8BitAccess", f12.get_uniformAndStorageBuffer8BitAccess())
  feat(s12, "storagePushConstant8", f12.get_storagePushConstant8())
  feat(s12, "shaderBufferInt64Atomics", f12.get_shaderBufferInt64Atomics())
  feat(s12, "shaderSharedInt64Atomics", f12.get_shaderSharedInt64Atomics())
  feat(s12, "shaderFloat16", f12.get_shaderFloat16())
  feat(s12, "shaderInt8", f12.get_shaderInt8())
  feat(s12, "descriptorIndexing", f12.get_descriptorIndexing())
  feat(s12, "descriptorBindingPartiallyBound", f12.get_descriptorBindingPartiallyBound())
  feat(s12, "descriptorBindingVariableDescriptorCount", f12.get_descriptorBindingVariableDescriptorCount())
  feat(s12, "runtimeDescriptorArray", f12.get_runtimeDescriptorArray())
  feat(s12, "samplerFilterMinmax", f12.get_samplerFilterMinmax())
  feat(s12, "scalarBlockLayout", f12.get_scalarBlockLayout())
  feat(s12, "imagelessFramebuffer", f12.get_imagelessFramebuffer())
  feat(s12, "uniformBufferStandardLayout", f12.get_uniformBufferStandardLayout())
  feat(s12, "shaderSubgroupExtendedTypes", f12.get_shaderSubgroupExtendedTypes())
  feat(s12, "separateDepthStencilLayouts", f12.get_separateDepthStencilLayouts())
  feat(s12, "hostQueryReset", f12.get_hostQueryReset())
  feat(s12, "timelineSemaphore", f12.get_timelineSemaphore())
  feat(s12, "bufferDeviceAddress", f12.get_bufferDeviceAddress())
  feat(s12, "bufferDeviceAddressCaptureReplay", f12.get_bufferDeviceAddressCaptureReplay())
  feat(s12, "vulkanMemoryModel", f12.get_vulkanMemoryModel())
  feat(s12, "shaderOutputViewportIndex", f12.get_shaderOutputViewportIndex())
  feat(s12, "shaderOutputLayer", f12.get_shaderOutputLayer())
  feat(s12, "subgroupBroadcastDynamicId", f12.get_subgroupBroadcastDynamicId())
  println("[15-cap] features12: \{s12}")

  let s13 = StringBuilder()
  feat(s13, "robustImageAccess", f13.get_robustImageAccess())
  feat(s13, "inlineUniformBlock", f13.get_inlineUniformBlock())
  feat(s13, "pipelineCreationCacheControl", f13.get_pipelineCreationCacheControl())
  feat(s13, "privateData", f13.get_privateData())
  feat(s13, "shaderDemoteToHelperInvocation", f13.get_shaderDemoteToHelperInvocation())
  feat(s13, "shaderTerminateInvocation", f13.get_shaderTerminateInvocation())
  feat(s13, "subgroupSizeControl", f13.get_subgroupSizeControl())
  feat(s13, "computeFullSubgroups", f13.get_computeFullSubgroups())
  feat(s13, "synchronization2", f13.get_synchronization2())
  feat(s13, "textureCompressionASTC_HDR", f13.get_textureCompressionASTC_HDR())
  feat(s13, "shaderZeroInitializeWorkgroupMemory", f13.get_shaderZeroInitializeWorkgroupMemory())
  feat(s13, "dynamicRendering", f13.get_dynamicRendering())
  feat(s13, "shaderIntegerDotProduct", f13.get_shaderIntegerDotProduct())
  feat(s13, "maintenance4", f13.get_maintenance4())
  println("[15-cap] features13: \{s13}")

  let s14 = StringBuilder()
  feat(s14, "globalPriorityQuery", f14.get_globalPriorityQuery())
  feat(s14, "shaderSubgroupRotate", f14.get_shaderSubgroupRotate())
  feat(s14, "shaderFloatControls2", f14.get_shaderFloatControls2())
  feat(s14, "shaderExpectAssume", f14.get_shaderExpectAssume())
  feat(s14, "rectangularLines", f14.get_rectangularLines())
  feat(s14, "bresenhamLines", f14.get_bresenhamLines())
  feat(s14, "smoothLines", f14.get_smoothLines())
  feat(s14, "stippledRectangularLines", f14.get_stippledRectangularLines())
  feat(s14, "stippledBresenhamLines", f14.get_stippledBresenhamLines())
  feat(s14, "stippledSmoothLines", f14.get_stippledSmoothLines())
  feat(s14, "vertexAttributeInstanceRateDivisor", f14.get_vertexAttributeInstanceRateDivisor())
  feat(s14, "vertexAttributeInstanceRateZeroDivisor", f14.get_vertexAttributeInstanceRateZeroDivisor())
  feat(s14, "indexTypeUint8", f14.get_indexTypeUint8())
  feat(s14, "dynamicRenderingLocalRead", f14.get_dynamicRenderingLocalRead())
  feat(s14, "maintenance5", f14.get_maintenance5())
  feat(s14, "maintenance6", f14.get_maintenance6())
  feat(s14, "pipelineProtectedAccess", f14.get_pipelineProtectedAccess())
  feat(s14, "pipelineRobustness", f14.get_pipelineRobustness())
  feat(s14, "hostImageCopy", f14.get_hostImageCopy())
  feat(s14, "pushDescriptor", f14.get_pushDescriptor())
  println("[15-cap] features14: \{s14}")

  // queue families
  let qfc = FixedArray::make(1, (0 : UInt32))
  (ifn.vkGetPhysicalDeviceQueueFamilyProperties)(phys, qfc, @vk.VkQueueFamilyProperties::null())
  let qfp = @vk.VkQueueFamilyProperties::array(qfc[0].reinterpret_as_int())
  (ifn.vkGetPhysicalDeviceQueueFamilyProperties)(phys, qfc, qfp)
  let qsb = StringBuilder()
  for i = 0; i < qfc[0].reinterpret_as_int(); i = i + 1 {
    qsb.write_string(
      "[\{i} flags=\{qfp.get_queueFlags_at(i)} count=\{qfp.get_queueCount_at(i)}] ",
    )
  }
  println("[15-cap] queue_families(\{qfc[0]}): \{qsb}")

  f2.free()
  f11.free()
  f12.free()
  f13.free()
  f14.free()
  props2.free()
  drv.free()
  (ifn.vkDestroyInstance)(inst, na)
  if props.get_apiVersion() > 0 && dec[0] > 0 {
    println("[15-cap] OK — capability dump complete")
  } else {
    println("[15-cap] FAIL — empty capability query")
  }
}