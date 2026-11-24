// Example 37 — Vendor, platform, and non-advertised desktop Vulkan commands.
// Verifies MoonBit dispatch bindings and type-checking for all vendor/platform
// extensions gated by vkGetDeviceProcAddr / vkGetInstanceProcAddr checks.

let na : @vk.VkAllocationCallbacks = @vk.VkAllocationCallbacks::null()
let g_errors : Ref[Int] = Ref(0)

///|
fn main {
  let app = @vk.VkApplicationInfo::new()
  app.set_pApplicationName(@vk.cstr("Tycho37VendorPlatform"))
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
    println("[37-vendor] FAIL — vkCreateInstance=\{ir}")
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
      println("[37-vendor] VALIDATION: \{@vk.read_cstr(data.get_pMessage())}")
      (0 : UInt32)
    },
  )
  let pc = FixedArray::make(1, (16 : UInt32))
  let devs = FixedArray::make(16, @vk.VkPhysicalDevice::null())
  let _ = (ifn.vkEnumeratePhysicalDevices)(inst, pc, devs)
  let phys = devs[0]

  let prio = FixedArray::make(1, (1.0 : Float))
  let qci = @vk.VkDeviceQueueCreateInfo::new()
  qci.set_queueFamilyIndex((0 : UInt32))
  qci.set_queueCount((1 : UInt32))
  qci.set_pQueuePriorities(prio)
  let dci = @vk.VkDeviceCreateInfo::new()
  dci.set_queueCreateInfoCount((1 : UInt32))
  dci.set_pQueueCreateInfos(qci)
  let dev_out = FixedArray::make(1, @vk.VkDevice::null())
  let dr = (ifn.vkCreateDevice)(phys, dci, na, dev_out)
  if dr != 0 {
    println("[37-vendor] FAIL — vkCreateDevice=\{dr}")
    return
  }
  let dev = dev_out[0]
  let dfn = @vk.DeviceFn::load(dev)
  let queue_out = FixedArray::make(1, @vk.VkQueue::null())
  (dfn.vkGetDeviceQueue)(dev, (0 : UInt32), (0 : UInt32), queue_out)
  let queue = queue_out[0]

  // Probe vkGetExternalComputeQueueDataNV via proc addr (not exported in libvulkan.so.1)
  let ext_proc = (ifn.vkGetDeviceProcAddr)(dev, @vk.cstr("vkGetExternalComputeQueueDataNV"))

  // `probed` counts commands actually invoked. The 148 vendor commands below the
  // guard are only type-checked at compile time, so they must not be counted as
  // runtime coverage (otherwise "0 invoked" still reports 149).
  let run_vendor = false
  let mut probed = 0
  if ext_proc != (0 : UInt64) {
    probed = probed + 1
  }
  if run_vendor {
    let _ = (dfn.vkAcquireFullScreenExclusiveModeEXT)(dev, @vk.VkSwapchainKHR::null())
    probed = probed + 1
    let _ = (dfn.vkAcquirePerformanceConfigurationINTEL)(dev, @vk.VkPerformanceConfigurationAcquireInfoINTEL::null(), FixedArray::make(1, @vk.VkPerformanceConfigurationINTEL::null()))
    probed = probed + 1
    let _ = (dfn.vkAcquireProfilingLockKHR)(dev, @vk.VkAcquireProfilingLockInfoKHR::null())
    probed = probed + 1
    let _ = (ifn.vkAcquireWinrtDisplayNV)(phys, @vk.VkDisplayKHR::null())
    probed = probed + 1
    (dfn.vkAntiLagUpdateAMD)(dev, @vk.VkAntiLagDataAMD::null())
    probed = probed + 1
    let _ = (dfn.vkBindDataGraphPipelineSessionMemoryARM)(dev, (0 : UInt32), @vk.VkBindDataGraphPipelineSessionMemoryInfoARM::null())
    probed = probed + 1
    let _ = (dfn.vkBindTensorMemoryARM)(dev, (0 : UInt32), @vk.VkBindTensorMemoryInfoARM::null())
    probed = probed + 1
    (dfn.vkClearShaderInstrumentationMetricsARM)(dev, @vk.VkShaderInstrumentationARM::null())
    probed = probed + 1
    (dfn.vkCmdBeginConditionalRendering2EXT)(@vk.VkCommandBuffer::null(), @vk.VkConditionalRenderingBeginInfo2EXT::null())
    probed = probed + 1
    let _ = (dfn.vkCmdBeginGpaSampleAMD)(@vk.VkCommandBuffer::null(), @vk.VkGpaSessionAMD::null(), @vk.VkGpaSampleBeginInfoAMD::null(), FixedArray::make(1, (0 : UInt32)))
    probed = probed + 1
    let _ = (dfn.vkCmdBeginGpaSessionAMD)(@vk.VkCommandBuffer::null(), @vk.VkGpaSessionAMD::null())
    probed = probed + 1
    (dfn.vkCmdBeginPerTileExecutionQCOM)(@vk.VkCommandBuffer::null(), @vk.VkPerTileBeginInfoQCOM::null())
    probed = probed + 1
    (dfn.vkCmdBeginShaderInstrumentationARM)(@vk.VkCommandBuffer::null(), @vk.VkShaderInstrumentationARM::null())
    probed = probed + 1
    (dfn.vkCmdBeginTransformFeedback2EXT)(@vk.VkCommandBuffer::null(), (0 : UInt32), (0 : UInt32), @vk.VkBindTransformFeedbackBuffer2InfoEXT::null())
    probed = probed + 1
    (dfn.vkCmdBindIndexBuffer3KHR)(@vk.VkCommandBuffer::null(), @vk.VkBindIndexBuffer3InfoKHR::null())
    probed = probed + 1
    (dfn.vkCmdBindInvocationMaskHUAWEI)(@vk.VkCommandBuffer::null(), @vk.VkImageView::null(), (0 : UInt32))
    probed = probed + 1
    (dfn.vkCmdBindTileMemoryQCOM)(@vk.VkCommandBuffer::null(), @vk.VkTileMemoryBindInfoQCOM::null())
    probed = probed + 1
    (dfn.vkCmdBindTransformFeedbackBuffers2EXT)(@vk.VkCommandBuffer::null(), (0 : UInt32), (0 : UInt32), @vk.VkBindTransformFeedbackBuffer2InfoEXT::null())
    probed = probed + 1
    (dfn.vkCmdBindVertexBuffers3KHR)(@vk.VkCommandBuffer::null(), (0 : UInt32), (0 : UInt32), @vk.VkBindVertexBuffer3InfoKHR::null())
    probed = probed + 1
    (dfn.vkCmdCopyGpaSessionResultsAMD)(@vk.VkCommandBuffer::null(), @vk.VkGpaSessionAMD::null())
    probed = probed + 1
    (dfn.vkCmdCopyImageToMemoryKHR)(@vk.VkCommandBuffer::null(), @vk.VkCopyDeviceMemoryImageInfoKHR::null())
    probed = probed + 1
    (dfn.vkCmdCopyMemoryKHR)(@vk.VkCommandBuffer::null(), @vk.VkCopyDeviceMemoryInfoKHR::null())
    probed = probed + 1
    (dfn.vkCmdCopyMemoryToImageKHR)(@vk.VkCommandBuffer::null(), @vk.VkCopyDeviceMemoryImageInfoKHR::null())
    probed = probed + 1
    (dfn.vkCmdCopyQueryPoolResultsToMemoryKHR)(@vk.VkCommandBuffer::null(), @vk.VkQueryPool::null(), (0 : UInt32), (0 : UInt32), @vk.VkStridedDeviceAddressRangeKHR::null(), (0 : UInt32), (0 : UInt32))
    probed = probed + 1
    (dfn.vkCmdCopyTensorARM)(@vk.VkCommandBuffer::null(), @vk.VkCopyTensorInfoARM::null())
    probed = probed + 1
    (dfn.vkCmdDebugMarkerBeginEXT)(@vk.VkCommandBuffer::null(), @vk.VkDebugMarkerMarkerInfoEXT::null())
    probed = probed + 1
    (dfn.vkCmdDebugMarkerEndEXT)(@vk.VkCommandBuffer::null())
    probed = probed + 1
    (dfn.vkCmdDebugMarkerInsertEXT)(@vk.VkCommandBuffer::null(), @vk.VkDebugMarkerMarkerInfoEXT::null())
    probed = probed + 1
    (dfn.vkCmdDispatchDataGraphARM)(@vk.VkCommandBuffer::null(), @vk.VkDataGraphPipelineSessionARM::null(), @vk.VkDataGraphPipelineDispatchInfoARM::null())
    probed = probed + 1
    (dfn.vkCmdDispatchGraphAMDX)(@vk.VkCommandBuffer::null(), (0 : UInt64), (0 : UInt64), @vk.VkDispatchGraphCountInfoAMDX::null())
    probed = probed + 1
    (dfn.vkCmdDispatchGraphIndirectAMDX)(@vk.VkCommandBuffer::null(), (0 : UInt64), (0 : UInt64), @vk.VkDispatchGraphCountInfoAMDX::null())
    probed = probed + 1
    (dfn.vkCmdDispatchGraphIndirectCountAMDX)(@vk.VkCommandBuffer::null(), (0 : UInt64), (0 : UInt64), (0 : UInt64))
    probed = probed + 1
    (dfn.vkCmdDispatchIndirect2KHR)(@vk.VkCommandBuffer::null(), @vk.VkDispatchIndirect2InfoKHR::null())
    probed = probed + 1
    (dfn.vkCmdDispatchTileQCOM)(@vk.VkCommandBuffer::null(), @vk.VkDispatchTileInfoQCOM::null())
    probed = probed + 1
    (dfn.vkCmdDrawClusterHUAWEI)(@vk.VkCommandBuffer::null(), (0 : UInt32), (0 : UInt32), (0 : UInt32))
    probed = probed + 1
    (dfn.vkCmdDrawClusterIndirectHUAWEI)(@vk.VkCommandBuffer::null(), @vk.VkBuffer::null(), (0 : UInt64))
    probed = probed + 1
    (dfn.vkCmdDrawIndexedIndirect2KHR)(@vk.VkCommandBuffer::null(), @vk.VkDrawIndirect2InfoKHR::null())
    probed = probed + 1
    (dfn.vkCmdDrawIndexedIndirectCount2KHR)(@vk.VkCommandBuffer::null(), @vk.VkDrawIndirectCount2InfoKHR::null())
    probed = probed + 1
    (dfn.vkCmdDrawIndexedIndirectCountAMD)(@vk.VkCommandBuffer::null(), @vk.VkBuffer::null(), (0 : UInt64), @vk.VkBuffer::null(), (0 : UInt64), (0 : UInt32), (0 : UInt32))
    probed = probed + 1
    (dfn.vkCmdDrawIndirect2KHR)(@vk.VkCommandBuffer::null(), @vk.VkDrawIndirect2InfoKHR::null())
    probed = probed + 1
    (dfn.vkCmdDrawIndirectByteCount2EXT)(@vk.VkCommandBuffer::null(), (0 : UInt32), (0 : UInt32), @vk.VkBindTransformFeedbackBuffer2InfoEXT::null(), (0 : UInt32), (0 : UInt32))
    probed = probed + 1
    (dfn.vkCmdDrawIndirectCount2KHR)(@vk.VkCommandBuffer::null(), @vk.VkDrawIndirectCount2InfoKHR::null())
    probed = probed + 1
    (dfn.vkCmdDrawIndirectCountAMD)(@vk.VkCommandBuffer::null(), @vk.VkBuffer::null(), (0 : UInt64), @vk.VkBuffer::null(), (0 : UInt64), (0 : UInt32), (0 : UInt32))
    probed = probed + 1
    (dfn.vkCmdDrawMeshTasksIndirect2EXT)(@vk.VkCommandBuffer::null(), @vk.VkDrawIndirect2InfoKHR::null())
    probed = probed + 1
    (dfn.vkCmdDrawMeshTasksIndirectCount2EXT)(@vk.VkCommandBuffer::null(), @vk.VkDrawIndirectCount2InfoKHR::null())
    probed = probed + 1
    (dfn.vkCmdEndGpaSampleAMD)(@vk.VkCommandBuffer::null(), @vk.VkGpaSessionAMD::null(), (0 : UInt32))
    probed = probed + 1
    let _ = (dfn.vkCmdEndGpaSessionAMD)(@vk.VkCommandBuffer::null(), @vk.VkGpaSessionAMD::null())
    probed = probed + 1
    (dfn.vkCmdEndPerTileExecutionQCOM)(@vk.VkCommandBuffer::null(), @vk.VkPerTileEndInfoQCOM::null())
    probed = probed + 1
    (dfn.vkCmdEndRendering2EXT)(@vk.VkCommandBuffer::null(), @vk.VkRenderingEndInfoKHR::null())
    probed = probed + 1
    (dfn.vkCmdEndShaderInstrumentationARM)(@vk.VkCommandBuffer::null())
    probed = probed + 1
    (dfn.vkCmdEndTransformFeedback2EXT)(@vk.VkCommandBuffer::null(), (0 : UInt32), (0 : UInt32), @vk.VkBindTransformFeedbackBuffer2InfoEXT::null())
    probed = probed + 1
    (dfn.vkCmdFillMemoryKHR)(@vk.VkCommandBuffer::null(), @vk.VkDeviceAddressRangeKHR::null(), (0 : UInt32), (0 : UInt32))
    probed = probed + 1
    (dfn.vkCmdInitializeGraphScratchMemoryAMDX)(@vk.VkCommandBuffer::null(), @vk.VkPipeline::null(), (0 : UInt64), (0 : UInt64))
    probed = probed + 1
    (dfn.vkCmdSetDispatchParametersARM)(@vk.VkCommandBuffer::null(), @vk.VkDispatchParametersARM::null())
    probed = probed + 1
    let _ = (dfn.vkCmdSetPerformanceMarkerINTEL)(@vk.VkCommandBuffer::null(), @vk.VkPerformanceMarkerInfoINTEL::null())
    probed = probed + 1
    let _ = (dfn.vkCmdSetPerformanceOverrideINTEL)(@vk.VkCommandBuffer::null(), @vk.VkPerformanceOverrideInfoINTEL::null())
    probed = probed + 1
    let _ = (dfn.vkCmdSetPerformanceStreamMarkerINTEL)(@vk.VkCommandBuffer::null(), @vk.VkPerformanceStreamMarkerInfoINTEL::null())
    probed = probed + 1
    (dfn.vkCmdSetPrimitiveRestartIndexEXT)(@vk.VkCommandBuffer::null(), (0 : UInt32))
    probed = probed + 1
    (dfn.vkCmdSubpassShadingHUAWEI)(@vk.VkCommandBuffer::null())
    probed = probed + 1
    (dfn.vkCmdUpdateMemoryKHR)(@vk.VkCommandBuffer::null(), @vk.VkDeviceAddressRangeKHR::null(), (0 : UInt32), (0 : UInt64), (0 : UInt64))
    probed = probed + 1
    (dfn.vkCmdWriteMarkerToMemoryAMD)(@vk.VkCommandBuffer::null(), @vk.VkMemoryMarkerInfoAMD::null())
    probed = probed + 1
    let _ = (dfn.vkCreateAccelerationStructure2KHR)(dev, @vk.VkAccelerationStructureCreateInfo2KHR::null(), na, FixedArray::make(1, @vk.VkAccelerationStructureKHR::null()))
    probed = probed + 1
    let _ = (dfn.vkCreateDataGraphPipelineSessionARM)(dev, @vk.VkDataGraphPipelineSessionCreateInfoARM::null(), na, FixedArray::make(1, @vk.VkDataGraphPipelineSessionARM::null()))
    probed = probed + 1
    let _ = (dfn.vkCreateDataGraphPipelinesARM)(dev, @vk.VkDeferredOperationKHR::null(), @vk.VkPipelineCache::null(), (0 : UInt32), @vk.VkDataGraphPipelineCreateInfoARM::null(), na, FixedArray::make(1, @vk.VkPipeline::null()))
    probed = probed + 1
    let _ = (dfn.vkCreateExecutionGraphPipelinesAMDX)(dev, @vk.VkPipelineCache::null(), (0 : UInt32), @vk.VkExecutionGraphPipelineCreateInfoAMDX::null(), na, FixedArray::make(1, @vk.VkPipeline::null()))
    probed = probed + 1
    let _ = (dfn.vkCreateExternalComputeQueueNV)(dev, @vk.VkExternalComputeQueueCreateInfoNV::null(), na, FixedArray::make(1, @vk.VkExternalComputeQueueNV::null()))
    probed = probed + 1
    let _ = (dfn.vkCreateGpaSessionAMD)(dev, @vk.VkGpaSessionCreateInfoAMD::null(), na, FixedArray::make(1, @vk.VkGpaSessionAMD::null()))
    probed = probed + 1
    let _ = (ifn.vkCreateHeadlessSurfaceEXT)(inst, @vk.VkHeadlessSurfaceCreateInfoEXT::null(), na, FixedArray::make(1, @vk.VkSurfaceKHR::null()))
    probed = probed + 1
    let _ = (ifn.vkCreateMetalSurfaceEXT)(inst, @vk.VkMetalSurfaceCreateInfoEXT::null(), na, FixedArray::make(1, @vk.VkSurfaceKHR::null()))
    probed = probed + 1
    let _ = (dfn.vkCreateShaderInstrumentationARM)(dev, @vk.VkShaderInstrumentationCreateInfoARM::null(), na, FixedArray::make(1, @vk.VkShaderInstrumentationARM::null()))
    probed = probed + 1
    let _ = (dfn.vkCreateSharedSwapchainsKHR)(dev, (0 : UInt32), @vk.VkSwapchainCreateInfoKHR::null(), na, FixedArray::make(1, @vk.VkSwapchainKHR::null()))
    probed = probed + 1
    let _ = (dfn.vkCreateTensorARM)(dev, @vk.VkTensorCreateInfoARM::null(), na, FixedArray::make(1, @vk.VkTensorARM::null()))
    probed = probed + 1
    let _ = (dfn.vkCreateTensorViewARM)(dev, @vk.VkTensorViewCreateInfoARM::null(), na, FixedArray::make(1, @vk.VkTensorViewARM::null()))
    probed = probed + 1
    let _ = (dfn.vkCreateValidationCacheEXT)(dev, @vk.VkValidationCacheCreateInfoEXT::null(), na, FixedArray::make(1, @vk.VkValidationCacheEXT::null()))
    probed = probed + 1
    let _ = (ifn.vkCreateWin32SurfaceKHR)(inst, @vk.VkWin32SurfaceCreateInfoKHR::null(), na, FixedArray::make(1, @vk.VkSurfaceKHR::null()))
    probed = probed + 1
    let _ = (dfn.vkDebugMarkerSetObjectNameEXT)(dev, @vk.VkDebugMarkerObjectNameInfoEXT::null())
    probed = probed + 1
    let _ = (dfn.vkDebugMarkerSetObjectTagEXT)(dev, @vk.VkDebugMarkerObjectTagInfoEXT::null())
    probed = probed + 1
    (dfn.vkDestroyDataGraphPipelineSessionARM)(dev, @vk.VkDataGraphPipelineSessionARM::null(), na)
    probed = probed + 1
    (dfn.vkDestroyExternalComputeQueueNV)(dev, @vk.VkExternalComputeQueueNV::null(), na)
    probed = probed + 1
    (dfn.vkDestroyGpaSessionAMD)(dev, @vk.VkGpaSessionAMD::null(), na)
    probed = probed + 1
    (dfn.vkDestroyShaderInstrumentationARM)(dev, @vk.VkShaderInstrumentationARM::null(), na)
    probed = probed + 1
    (dfn.vkDestroyTensorARM)(dev, @vk.VkTensorARM::null(), na)
    probed = probed + 1
    (dfn.vkDestroyTensorViewARM)(dev, @vk.VkTensorViewARM::null(), na)
    probed = probed + 1
    (dfn.vkDestroyValidationCacheEXT)(dev, @vk.VkValidationCacheEXT::null(), na)
    probed = probed + 1
    let _ = (ifn.vkEnumeratePhysicalDeviceQueueFamilyPerformanceCountersByRegionARM)(phys, (0 : UInt32), FixedArray::make(1, (0 : UInt32)), @vk.VkPerformanceCounterARM::null(), @vk.VkPerformanceCounterDescriptionARM::null())
    probed = probed + 1
    let _ = (ifn.vkEnumeratePhysicalDeviceQueueFamilyPerformanceQueryCountersKHR)(phys, (0 : UInt32), FixedArray::make(1, (0 : UInt32)), @vk.VkPerformanceCounterKHR::null(), @vk.VkPerformanceCounterDescriptionKHR::null())
    probed = probed + 1
    let _ = (ifn.vkEnumeratePhysicalDeviceShaderInstrumentationMetricsARM)(phys, FixedArray::make(1, (0 : UInt32)), @vk.VkShaderInstrumentationMetricDescriptionARM::null())
    probed = probed + 1
    (dfn.vkExportMetalObjectsEXT)(dev, @vk.VkExportMetalObjectsInfoEXT::null())
    probed = probed + 1
    let _ = (dfn.vkGetDataGraphPipelineAvailablePropertiesARM)(dev, @vk.VkDataGraphPipelineInfoARM::null(), FixedArray::make(1, (0 : UInt32)), FixedArray::make(1, (0 : UInt32)))
    probed = probed + 1
    let _ = (dfn.vkGetDataGraphPipelinePropertiesARM)(dev, @vk.VkDataGraphPipelineInfoARM::null(), (0 : UInt32), @vk.VkDataGraphPipelinePropertyQueryResultARM::null())
    probed = probed + 1
    let _ = (dfn.vkGetDataGraphPipelineSessionBindPointRequirementsARM)(dev, @vk.VkDataGraphPipelineSessionBindPointRequirementsInfoARM::null(), FixedArray::make(1, (0 : UInt32)), @vk.VkDataGraphPipelineSessionBindPointRequirementARM::null())
    probed = probed + 1
    (dfn.vkGetDataGraphPipelineSessionMemoryRequirementsARM)(dev, @vk.VkDataGraphPipelineSessionMemoryRequirementsInfoARM::null(), @vk.VkMemoryRequirements2::null())
    probed = probed + 1
    (dfn.vkGetDescriptorSetHostMappingVALVE)(dev, @vk.VkDescriptorSet::null(), FixedArray::make(1, (0 : UInt64)))
    probed = probed + 1
    (dfn.vkGetDescriptorSetLayoutHostMappingInfoVALVE)(dev, @vk.VkDescriptorSetBindingReferenceVALVE::null(), @vk.VkDescriptorSetLayoutHostMappingInfoVALVE::null())
    probed = probed + 1
    let _ = (dfn.vkGetDeviceFaultDebugInfoKHR)(dev, @vk.VkDeviceFaultDebugInfoKHR::null())
    probed = probed + 1
    let _ = (dfn.vkGetDeviceFaultReportsKHR)(dev, (0 : UInt64), FixedArray::make(1, (0 : UInt32)), @vk.VkDeviceFaultInfoKHR::null())
    probed = probed + 1
    let _ = (dfn.vkGetDeviceGroupSurfacePresentModes2EXT)(dev, @vk.VkPhysicalDeviceSurfaceInfo2KHR::null(), FixedArray::make(1, (0 : UInt32)))
    probed = probed + 1
    let _ = (dfn.vkGetDeviceSubpassShadingMaxWorkgroupSizeHUAWEI)(dev, @vk.VkRenderPass::null(), @vk.VkExtent2D::null())
    probed = probed + 1
    (dfn.vkGetDeviceTensorMemoryRequirementsARM)(dev, @vk.VkDeviceTensorMemoryRequirementsARM::null(), @vk.VkMemoryRequirements2::null())
    probed = probed + 1
    let _ = (dfn.vkGetDynamicRenderingTilePropertiesQCOM)(dev, @vk.VkRenderingInfo::null(), @vk.VkTilePropertiesQCOM::null())
    probed = probed + 1
    let _ = (dfn.vkGetExecutionGraphPipelineNodeIndexAMDX)(dev, @vk.VkPipeline::null(), @vk.VkPipelineShaderStageNodeCreateInfoAMDX::null(), FixedArray::make(1, (0 : UInt32)))
    probed = probed + 1
    let _ = (dfn.vkGetExecutionGraphPipelineScratchSizeAMDX)(dev, @vk.VkPipeline::null(), @vk.VkExecutionGraphPipelineScratchSizeAMDX::null())
    probed = probed + 1
    let _ = (dfn.vkGetFenceWin32HandleKHR)(dev, @vk.VkFenceGetWin32HandleInfoKHR::null(), (0 : UInt64))
    probed = probed + 1
    let _ = (dfn.vkGetFramebufferTilePropertiesQCOM)(dev, @vk.VkFramebuffer::null(), FixedArray::make(1, (0 : UInt32)), @vk.VkTilePropertiesQCOM::null())
    probed = probed + 1
    let _ = (dfn.vkGetGpaDeviceClockInfoAMD)(dev, @vk.VkGpaDeviceGetClockInfoAMD::null())
    probed = probed + 1
    let _ = (dfn.vkGetGpaSessionResultsAMD)(dev, @vk.VkGpaSessionAMD::null(), (0 : UInt32), FixedArray::make(1, (0 : UInt64)), (0 : UInt64))
    probed = probed + 1
    let _ = (dfn.vkGetGpaSessionStatusAMD)(dev, @vk.VkGpaSessionAMD::null())
    probed = probed + 1
    let _ = (dfn.vkGetMemoryMetalHandleEXT)(dev, @vk.VkMemoryGetMetalHandleInfoEXT::null(), FixedArray::make(1, (0 : UInt64)))
    probed = probed + 1
    let _ = (dfn.vkGetMemoryMetalHandlePropertiesEXT)(dev, (0 : UInt32), (0 : UInt64), @vk.VkMemoryMetalHandlePropertiesEXT::null())
    probed = probed + 1
    let _ = (dfn.vkGetMemoryRemoteAddressNV)(dev, @vk.VkMemoryGetRemoteAddressInfoNV::null(), (0 : UInt64))
    probed = probed + 1
    let _ = (dfn.vkGetMemoryWin32HandleKHR)(dev, @vk.VkMemoryGetWin32HandleInfoKHR::null(), (0 : UInt64))
    probed = probed + 1
    let _ = (dfn.vkGetMemoryWin32HandleNV)(dev, @vk.VkDeviceMemory::null(), (0 : UInt32), (0 : UInt64))
    probed = probed + 1
    let _ = (dfn.vkGetMemoryWin32HandlePropertiesKHR)(dev, (0 : UInt32), (0 : UInt64), @vk.VkMemoryWin32HandlePropertiesKHR::null())
    probed = probed + 1
    let _ = (dfn.vkGetPastPresentationTimingGOOGLE)(dev, @vk.VkSwapchainKHR::null(), FixedArray::make(1, (0 : UInt32)), @vk.VkPastPresentationTimingGOOGLE::null())
    probed = probed + 1
    let _ = (dfn.vkGetPerformanceParameterINTEL)(dev, (0 : UInt32), @vk.VkPerformanceValueINTEL::null())
    probed = probed + 1
    let _ = (ifn.vkGetPhysicalDeviceCooperativeMatrixProperties2EXT)(phys, @vk.VkPhysicalDeviceCooperativeMatrixInfo2EXT::null(), FixedArray::make(1, (0 : UInt32)), @vk.VkCooperativeMatrixProperties2EXT::null())
    probed = probed + 1
    let _ = (ifn.vkGetPhysicalDeviceExternalImageFormatPropertiesNV)(phys, (0 : UInt32), (0 : UInt32), (0 : UInt32), (0 : UInt32), (0 : UInt32), (0 : UInt32), @vk.VkExternalImageFormatPropertiesNV::null())
    probed = probed + 1
    (ifn.vkGetPhysicalDeviceExternalTensorPropertiesARM)(phys, @vk.VkPhysicalDeviceExternalTensorInfoARM::null(), @vk.VkExternalTensorPropertiesARM::null())
    probed = probed + 1
    let _ = (ifn.vkGetPhysicalDeviceQueueFamilyDataGraphEngineOperationPropertiesARM)(phys, (0 : UInt32), @vk.VkQueueFamilyDataGraphPropertiesARM::null(), @vk.VkBaseOutStructure::null())
    probed = probed + 1
    let _ = (ifn.vkGetPhysicalDeviceQueueFamilyDataGraphOpticalFlowImageFormatsARM)(phys, (0 : UInt32), @vk.VkQueueFamilyDataGraphPropertiesARM::null(), @vk.VkDataGraphOpticalFlowImageFormatInfoARM::null(), FixedArray::make(1, (0 : UInt32)), @vk.VkDataGraphOpticalFlowImageFormatPropertiesARM::null())
    probed = probed + 1
    (ifn.vkGetPhysicalDeviceQueueFamilyDataGraphProcessingEnginePropertiesARM)(phys, @vk.VkPhysicalDeviceQueueFamilyDataGraphProcessingEngineInfoARM::null(), @vk.VkQueueFamilyDataGraphProcessingEnginePropertiesARM::null())
    probed = probed + 1
    let _ = (ifn.vkGetPhysicalDeviceQueueFamilyDataGraphPropertiesARM)(phys, (0 : UInt32), FixedArray::make(1, (0 : UInt32)), @vk.VkQueueFamilyDataGraphPropertiesARM::null())
    probed = probed + 1
    (ifn.vkGetPhysicalDeviceQueueFamilyPerformanceQueryPassesKHR)(phys, @vk.VkQueryPoolPerformanceCreateInfoKHR::null(), FixedArray::make(1, (0 : UInt32)))
    probed = probed + 1
    let _ = (ifn.vkGetPhysicalDeviceSurfacePresentModes2EXT)(phys, @vk.VkPhysicalDeviceSurfaceInfo2KHR::null(), FixedArray::make(1, (0 : UInt32)), FixedArray::make(1, (0 : UInt32)))
    probed = probed + 1
    let _ = (ifn.vkGetPhysicalDeviceWin32PresentationSupportKHR)(phys, (0 : UInt32))
    probed = probed + 1
    let _ = (dfn.vkGetPipelinePropertiesEXT)(dev, @vk.VkPipelineInfoKHR::null(), @vk.VkBaseOutStructure::null())
    probed = probed + 1
    let _ = (dfn.vkGetRefreshCycleDurationGOOGLE)(dev, @vk.VkSwapchainKHR::null(), @vk.VkRefreshCycleDurationGOOGLE::null())
    probed = probed + 1
    let _ = (dfn.vkGetSemaphoreWin32HandleKHR)(dev, @vk.VkSemaphoreGetWin32HandleInfoKHR::null(), (0 : UInt64))
    probed = probed + 1
    let _ = (dfn.vkGetShaderInfoAMD)(dev, @vk.VkPipeline::null(), (0 : UInt32), (0 : UInt32), FixedArray::make(1, (0 : UInt64)), (0 : UInt64))
    probed = probed + 1
    let _ = (dfn.vkGetShaderInstrumentationValuesARM)(dev, @vk.VkShaderInstrumentationARM::null(), FixedArray::make(1, (0 : UInt32)), (0 : UInt64), (0 : UInt32))
    probed = probed + 1
    (dfn.vkGetTensorMemoryRequirementsARM)(dev, @vk.VkTensorMemoryRequirementsInfoARM::null(), @vk.VkMemoryRequirements2::null())
    probed = probed + 1
    let _ = (dfn.vkGetTensorOpaqueCaptureDescriptorDataARM)(dev, @vk.VkTensorCaptureDescriptorDataInfoARM::null(), (0 : UInt64))
    probed = probed + 1
    let _ = (dfn.vkGetTensorViewOpaqueCaptureDescriptorDataARM)(dev, @vk.VkTensorViewCaptureDescriptorDataInfoARM::null(), (0 : UInt64))
    probed = probed + 1
    let _ = (dfn.vkGetValidationCacheDataEXT)(dev, @vk.VkValidationCacheEXT::null(), FixedArray::make(1, (0 : UInt64)), (0 : UInt64))
    probed = probed + 1
    let _ = (ifn.vkGetWinrtDisplayNV)(phys, (0 : UInt32), FixedArray::make(1, @vk.VkDisplayKHR::null()))
    probed = probed + 1
    let _ = (dfn.vkImportFenceWin32HandleKHR)(dev, @vk.VkImportFenceWin32HandleInfoKHR::null())
    probed = probed + 1
    let _ = (dfn.vkImportSemaphoreWin32HandleKHR)(dev, @vk.VkImportSemaphoreWin32HandleInfoKHR::null())
    probed = probed + 1
    let _ = (dfn.vkInitializePerformanceApiINTEL)(dev, @vk.VkInitializePerformanceApiInfoINTEL::null())
    probed = probed + 1
    let _ = (dfn.vkMergeValidationCachesEXT)(dev, @vk.VkValidationCacheEXT::null(), (0 : UInt32), FixedArray::make(1, @vk.VkValidationCacheEXT::null()))
    probed = probed + 1
    let _ = (dfn.vkQueueSetPerfHintQCOM)(queue, @vk.VkPerfHintInfoQCOM::null())
    probed = probed + 1
    let _ = (dfn.vkQueueSetPerformanceConfigurationINTEL)(queue, @vk.VkPerformanceConfigurationINTEL::null())
    probed = probed + 1
    let _ = (dfn.vkReleaseFullScreenExclusiveModeEXT)(dev, @vk.VkSwapchainKHR::null())
    probed = probed + 1
    let _ = (dfn.vkReleasePerformanceConfigurationINTEL)(dev, @vk.VkPerformanceConfigurationINTEL::null())
    probed = probed + 1
    (dfn.vkReleaseProfilingLockKHR)(dev)
    probed = probed + 1
    let _ = (dfn.vkResetGpaSessionAMD)(dev, @vk.VkGpaSessionAMD::null())
    probed = probed + 1
    let _ = (dfn.vkSetGpaDeviceClockModeAMD)(dev, @vk.VkGpaDeviceClockModeInfoAMD::null())
    probed = probed + 1
    (dfn.vkSetLocalDimmingAMD)(dev, @vk.VkSwapchainKHR::null(), (0 : UInt32))
    probed = probed + 1
    (dfn.vkUninitializePerformanceApiINTEL)(dev)
    probed = probed + 1
  }
  let typechecked = 148
  (dfn.vkDestroyDevice)(dev, na)
  @vk.destroy_debug_messenger(inst, ifn, messenger)
  (ifn.vkDestroyInstance)(inst, na)
  println("[37-vendor] commands=\{probed} typechecked=\{typechecked} errors=\{g_errors.val}")
  if g_errors.val != 0 {
    println("[37-vendor] FAIL — errors=\{g_errors.val} commands=\{probed}")
  } else if probed == 0 {
    println("[37-vendor] SKIP — 0 vendor/platform commands invoked on this driver (\{typechecked} type-checked only)")
  } else {
    println("[37-vendor] OK — \{probed} runtime + \{typechecked} type-checked vendor/platform commands, 0 validation errors")
  }
}
