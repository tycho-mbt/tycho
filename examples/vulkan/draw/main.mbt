// vulkan/draw — dynamic state + draw/dispatch variants (headless offscreen
// rendering). Fourth execution-coverage batch. The pipeline's dynamic-state
// list is built from the same resolvability test that gates each setter, so a
// state is never declared without being set (which would be a VUID violation).

///|
let na : @vk.VkAllocationCallbacks = @vk.VkAllocationCallbacks::null()

///|
let g_errors : Ref[Int] = { val: 0 }

///|
fn main {
  let app = @vk.VkApplicationInfo::new()
  app.set_pApplicationName(@vk.cstr("Tycho Draw"))
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
    println("[vulkan/draw] FAIL — vkCreateInstance=\{ir}")
    return
  }
  let inst = inst_out[0]
  let ifn = @vk.InstanceFn::load(inst)
  let messenger = @vk.create_debug_messenger(
    inst, ifn,
    @vk.VK_DEBUG_UTILS_MESSAGE_SEVERITY_ERROR_BIT_EXT,
    @vk.VK_DEBUG_UTILS_MESSAGE_TYPE_VALIDATION_BIT_EXT,
    (_sev, _ty, data, _ud) => {
      g_errors.val = g_errors.val + 1
      println("[vulkan/draw] VALIDATION: \{@vk.read_cstr(data.get_pMessage())}")
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
  let eds1q = @vk.VkPhysicalDeviceExtendedDynamicStateFeaturesEXT::new()
  let eds2q = @vk.VkPhysicalDeviceExtendedDynamicState2FeaturesEXT::new()
  let eds3q = @vk.VkPhysicalDeviceExtendedDynamicState3FeaturesEXT::new()
  let vidsq = @vk.VkPhysicalDeviceVertexInputDynamicStateFeaturesEXT::new()
  let cweq = @vk.VkPhysicalDeviceColorWriteEnableFeaturesEXT::new()
  let dceq = @vk.VkPhysicalDeviceDepthClipEnableFeaturesEXT::new()
  let mdq = @vk.VkPhysicalDeviceMultiDrawFeaturesEXT::new()
  let dccq = @vk.VkPhysicalDeviceDepthClipControlFeaturesEXT::new()
  let tfq = @vk.VkPhysicalDeviceTransformFeedbackFeaturesEXT::new()
  let tfpq = @vk.VkPhysicalDeviceTransformFeedbackPropertiesEXT::new()
  let fsrq = @vk.VkPhysicalDeviceFragmentShadingRateFeaturesKHR::new()
  let drprop = @vk.VkPhysicalDeviceDiscardRectanglePropertiesEXT::new()
  let f14q = @vk.VkPhysicalDeviceVulkan14Features::new()
  eds2q.set_pNext(eds3q.as_ptr())
  eds1q.set_pNext(eds2q.as_ptr())
  cweq.set_pNext(vidsq.as_ptr())
  dceq.set_pNext(mdq.as_ptr())
  mdq.set_pNext(dccq.as_ptr())
  dccq.set_pNext(tfq.as_ptr())
  tfq.set_pNext(tfpq.as_ptr())
  tfpq.set_pNext(fsrq.as_ptr())
  fsrq.set_pNext(drprop.as_ptr())
  drprop.set_pNext(f14q.as_ptr())
  f14q.set_pNext(cweq.as_ptr())
  vidsq.set_pNext(eds1q.as_ptr())
  let fq = @vk.VkPhysicalDeviceFeatures2::new()
  fq.set_pNext(dceq.as_ptr())
  (ifn.vkGetPhysicalDeviceFeatures2)(phys, fq)
  let f13 = @vk.VkPhysicalDeviceVulkan13Features::new()
  f13.set_dynamicRendering((1 : UInt32))
  f13.set_synchronization2((1 : UInt32))
  let f12 = @vk.VkPhysicalDeviceVulkan12Features::new()
  f12.set_drawIndirectCount((1 : UInt32))
  let eds1 = @vk.VkPhysicalDeviceExtendedDynamicStateFeaturesEXT::new()
  eds1.set_extendedDynamicState(eds1q.get_extendedDynamicState())
  let eds2 = @vk.VkPhysicalDeviceExtendedDynamicState2FeaturesEXT::new()
  eds2.set_extendedDynamicState2(eds2q.get_extendedDynamicState2())
  eds2.set_extendedDynamicState2LogicOp(eds2q.get_extendedDynamicState2LogicOp())
  eds2.set_extendedDynamicState2PatchControlPoints(eds2q.get_extendedDynamicState2PatchControlPoints())
  let vids = @vk.VkPhysicalDeviceVertexInputDynamicStateFeaturesEXT::new()
  vids.set_vertexInputDynamicState(vidsq.get_vertexInputDynamicState())
  let fsr = @vk.VkPhysicalDeviceFragmentShadingRateFeaturesKHR::new()
  fsr.set_pipelineFragmentShadingRate(fsrq.get_pipelineFragmentShadingRate())
  fsr.set_primitiveFragmentShadingRate(fsrq.get_primitiveFragmentShadingRate())
  fsr.set_attachmentFragmentShadingRate(fsrq.get_attachmentFragmentShadingRate())
  let f14 = @vk.VkPhysicalDeviceVulkan14Features::new()
  f14.set_dynamicRenderingLocalRead(f14q.get_dynamicRenderingLocalRead())
  let dcc = @vk.VkPhysicalDeviceDepthClipControlFeaturesEXT::new()
  dcc.set_depthClipControl(dccq.get_depthClipControl())
  let tf = @vk.VkPhysicalDeviceTransformFeedbackFeaturesEXT::new()
  tf.set_transformFeedback(tfq.get_transformFeedback())
  let md = @vk.VkPhysicalDeviceMultiDrawFeaturesEXT::new()
  md.set_multiDraw(mdq.get_multiDraw())
  let dce = @vk.VkPhysicalDeviceDepthClipEnableFeaturesEXT::new()
  dce.set_depthClipEnable(dceq.get_depthClipEnable())
  let cwe = @vk.VkPhysicalDeviceColorWriteEnableFeaturesEXT::new()
  cwe.set_colorWriteEnable(cweq.get_colorWriteEnable())
  let eds3 = @vk.VkPhysicalDeviceExtendedDynamicState3FeaturesEXT::new()
  eds3.set_extendedDynamicState3TessellationDomainOrigin(eds3q.get_extendedDynamicState3TessellationDomainOrigin())
  eds3.set_extendedDynamicState3DepthClampEnable(eds3q.get_extendedDynamicState3DepthClampEnable())
  eds3.set_extendedDynamicState3PolygonMode(eds3q.get_extendedDynamicState3PolygonMode())
  eds3.set_extendedDynamicState3RasterizationSamples(eds3q.get_extendedDynamicState3RasterizationSamples())
  eds3.set_extendedDynamicState3SampleMask(eds3q.get_extendedDynamicState3SampleMask())
  eds3.set_extendedDynamicState3AlphaToCoverageEnable(eds3q.get_extendedDynamicState3AlphaToCoverageEnable())
  eds3.set_extendedDynamicState3LogicOpEnable(eds3q.get_extendedDynamicState3LogicOpEnable())
  eds3.set_extendedDynamicState3DepthClipEnable(eds3q.get_extendedDynamicState3DepthClipEnable())
  eds3.set_extendedDynamicState3ConservativeRasterizationMode(eds3q.get_extendedDynamicState3ConservativeRasterizationMode())
  eds3.set_extendedDynamicState3ExtraPrimitiveOverestimationSize(eds3q.get_extendedDynamicState3ExtraPrimitiveOverestimationSize())
  eds3.set_extendedDynamicState3ProvokingVertexMode(eds3q.get_extendedDynamicState3ProvokingVertexMode())
  eds3.set_extendedDynamicState3LineRasterizationMode(eds3q.get_extendedDynamicState3LineRasterizationMode())
  eds3.set_extendedDynamicState3LineStippleEnable(eds3q.get_extendedDynamicState3LineStippleEnable())
  eds3.set_extendedDynamicState3ColorWriteMask(eds3q.get_extendedDynamicState3ColorWriteMask())
  eds3.set_extendedDynamicState3AlphaToOneEnable(eds3q.get_extendedDynamicState3AlphaToOneEnable())
  eds3.set_extendedDynamicState3ColorBlendAdvanced(eds3q.get_extendedDynamicState3ColorBlendAdvanced())
  eds3.set_extendedDynamicState3ColorBlendEnable(eds3q.get_extendedDynamicState3ColorBlendEnable())
  eds3.set_extendedDynamicState3ColorBlendEquation(eds3q.get_extendedDynamicState3ColorBlendEquation())
  eds3.set_extendedDynamicState3CoverageModulationMode(eds3q.get_extendedDynamicState3CoverageModulationMode())
  eds3.set_extendedDynamicState3CoverageModulationTable(eds3q.get_extendedDynamicState3CoverageModulationTable())
  eds3.set_extendedDynamicState3CoverageModulationTableEnable(eds3q.get_extendedDynamicState3CoverageModulationTableEnable())
  eds3.set_extendedDynamicState3CoverageReductionMode(eds3q.get_extendedDynamicState3CoverageReductionMode())
  eds3.set_extendedDynamicState3CoverageToColorEnable(eds3q.get_extendedDynamicState3CoverageToColorEnable())
  eds3.set_extendedDynamicState3CoverageToColorLocation(eds3q.get_extendedDynamicState3CoverageToColorLocation())
  eds3.set_extendedDynamicState3DepthClipNegativeOneToOne(eds3q.get_extendedDynamicState3DepthClipNegativeOneToOne())
  eds3.set_extendedDynamicState3RasterizationStream(eds3q.get_extendedDynamicState3RasterizationStream())
  eds3.set_extendedDynamicState3RepresentativeFragmentTestEnable(eds3q.get_extendedDynamicState3RepresentativeFragmentTestEnable())
  eds3.set_extendedDynamicState3SampleLocationsEnable(eds3q.get_extendedDynamicState3SampleLocationsEnable())
  eds3.set_extendedDynamicState3ShadingRateImageEnable(eds3q.get_extendedDynamicState3ShadingRateImageEnable())
  eds3.set_extendedDynamicState3ViewportSwizzle(eds3q.get_extendedDynamicState3ViewportSwizzle())
  eds3.set_extendedDynamicState3ViewportWScalingEnable(eds3q.get_extendedDynamicState3ViewportWScalingEnable())
  eds3.set_pNext(vids.as_ptr())
  vids.set_pNext(dce.as_ptr())
  dce.set_pNext(md.as_ptr())
  md.set_pNext(dcc.as_ptr())
  f14.set_rectangularLines(f14q.get_rectangularLines())
  f14.set_bresenhamLines(f14q.get_bresenhamLines())
  f14.set_smoothLines(f14q.get_smoothLines())
  f14.set_stippledRectangularLines(f14q.get_stippledRectangularLines())
  f14.set_stippledBresenhamLines(f14q.get_stippledBresenhamLines())
  f14.set_stippledSmoothLines(f14q.get_stippledSmoothLines())
  f14.set_pushDescriptor(f14q.get_pushDescriptor())
  dcc.set_pNext(fsr.as_ptr())
  fsr.set_pNext(f14.as_ptr())
  f14.set_pNext(tf.as_ptr())
  tf.set_pNext(cwe.as_ptr())
  cwe.set_pNext(eds2.as_ptr())
  eds2.set_pNext(eds1.as_ptr())
  eds1.set_pNext(f13.as_ptr())
  f12.set_pNext(eds3.as_ptr())
  let want = ["VK_KHR_dynamic_rendering", "VK_KHR_synchronization2", "VK_KHR_draw_indirect_count", "VK_EXT_multi_draw", "VK_EXT_extended_dynamic_state", "VK_EXT_extended_dynamic_state2", "VK_EXT_extended_dynamic_state3", "VK_EXT_vertex_input_dynamic_state", "VK_KHR_push_descriptor", "VK_KHR_maintenance4", "VK_EXT_line_rasterization", "VK_KHR_line_rasterization", "VK_EXT_extended_dynamic_state3", "VK_EXT_vertex_input_dynamic_state", "VK_EXT_conservative_rasterization", "VK_EXT_color_write_enable", "VK_EXT_depth_clip_enable", "VK_EXT_multi_draw", "VK_EXT_discard_rectangles", "VK_EXT_sample_locations", "VK_KHR_fragment_shading_rate", "VK_NV_framebuffer_mixed_samples", "VK_NV_coverage_reduction_mode", "VK_NV_viewport_swizzle", "VK_NV_clip_space_w_scaling", "VK_NV_shading_rate_image", "VK_NV_representative_fragment_test", "VK_NV_scissor_exclusive", "VK_EXT_attachment_feedback_loop_layout", "VK_EXT_rasterization_order_attachment_access", "VK_EXT_depth_bias_control", "VK_EXT_depth_clamp_control", "VK_NV_compute_occupancy_priority", "VK_EXT_depth_clip_control", "VK_EXT_transform_feedback", "VK_EXT_blend_operation_advanced", "VK_KHR_fragment_shading_rate", "VK_KHR_dynamic_rendering_local_read"]
  let den = FixedArray::make(want.length(), "")
  let mut nden = 0
  for i = 0; i < want.length(); i = i + 1 {
    if want[i] == "VK_KHR_push_descriptor" && f14q.get_pushDescriptor() == 0 {
      continue
    }
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
  dci.set_pNext(f12.as_ptr())
  dci.set_queueCreateInfoCount((1 : UInt32))
  dci.set_pQueueCreateInfos(qci)
  dci.set_enabledExtensionCount(nden.reinterpret_as_uint())
  dci.set_ppEnabledExtensionNames(@vk.cstr_array(den))
  let dev_out = FixedArray::make(1, @vk.VkDevice::null())
  let dr = (ifn.vkCreateDevice)(phys, dci, na, dev_out)
  if dr != 0 {
    println("[vulkan/draw] FAIL — vkCreateDevice=\{dr}")
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

  // dynamic states: include only those whose setter resolves
  let use_wc = has("vkCmdSetViewportWithCount")
  let dsarr : Array[UInt32] = []
  let add_ds = fn(cmd : String, state : UInt32) -> Unit {
    if has(cmd) {
      dsarr.push(state)
    }
  }
  add_ds("vkCmdSetLineWidth", @vk.VK_DYNAMIC_STATE_LINE_WIDTH)
  add_ds("vkCmdSetDepthBias", @vk.VK_DYNAMIC_STATE_DEPTH_BIAS)
  add_ds("vkCmdSetBlendConstants", @vk.VK_DYNAMIC_STATE_BLEND_CONSTANTS)
  add_ds("vkCmdSetDepthBounds", @vk.VK_DYNAMIC_STATE_DEPTH_BOUNDS)
  add_ds("vkCmdSetStencilCompareMask", @vk.VK_DYNAMIC_STATE_STENCIL_COMPARE_MASK)
  add_ds("vkCmdSetStencilWriteMask", @vk.VK_DYNAMIC_STATE_STENCIL_WRITE_MASK)
  add_ds("vkCmdSetStencilReference", @vk.VK_DYNAMIC_STATE_STENCIL_REFERENCE)
  if eds1q.get_extendedDynamicState() != 0 {
    add_ds("vkCmdSetCullMode", @vk.VK_DYNAMIC_STATE_CULL_MODE)
  }
  if eds1q.get_extendedDynamicState() != 0 {
    add_ds("vkCmdSetFrontFace", @vk.VK_DYNAMIC_STATE_FRONT_FACE)
  }
  if eds1q.get_extendedDynamicState() != 0 {
    add_ds("vkCmdSetPrimitiveTopology", @vk.VK_DYNAMIC_STATE_PRIMITIVE_TOPOLOGY)
  }
  if eds1q.get_extendedDynamicState() != 0 {
    add_ds("vkCmdSetDepthTestEnable", @vk.VK_DYNAMIC_STATE_DEPTH_TEST_ENABLE)
  }
  if eds1q.get_extendedDynamicState() != 0 {
    add_ds("vkCmdSetDepthWriteEnable", @vk.VK_DYNAMIC_STATE_DEPTH_WRITE_ENABLE)
  }
  if eds1q.get_extendedDynamicState() != 0 {
    add_ds("vkCmdSetDepthCompareOp", @vk.VK_DYNAMIC_STATE_DEPTH_COMPARE_OP)
  }
  if eds1q.get_extendedDynamicState() != 0 {
    add_ds("vkCmdSetDepthBoundsTestEnable", @vk.VK_DYNAMIC_STATE_DEPTH_BOUNDS_TEST_ENABLE)
  }
  if eds1q.get_extendedDynamicState() != 0 {
    add_ds("vkCmdSetStencilTestEnable", @vk.VK_DYNAMIC_STATE_STENCIL_TEST_ENABLE)
  }
  if eds1q.get_extendedDynamicState() != 0 {
    add_ds("vkCmdSetStencilOp", @vk.VK_DYNAMIC_STATE_STENCIL_OP)
  }
  if eds2q.get_extendedDynamicState2() != 0 {
    add_ds("vkCmdSetRasterizerDiscardEnable", @vk.VK_DYNAMIC_STATE_RASTERIZER_DISCARD_ENABLE)
  }
  if eds2q.get_extendedDynamicState2() != 0 {
    add_ds("vkCmdSetDepthBiasEnable", @vk.VK_DYNAMIC_STATE_DEPTH_BIAS_ENABLE)
  }
  if eds2q.get_extendedDynamicState2() != 0 {
    add_ds("vkCmdSetPrimitiveRestartEnable", @vk.VK_DYNAMIC_STATE_PRIMITIVE_RESTART_ENABLE)
  }
  // vkCmdBindVertexBuffers2 sets strides, which requires this state.
  add_ds("vkCmdBindVertexBuffers2", @vk.VK_DYNAMIC_STATE_VERTEX_INPUT_BINDING_STRIDE)
  add_ds("vkCmdSetViewportWithCount", @vk.VK_DYNAMIC_STATE_VIEWPORT_WITH_COUNT)
  add_ds("vkCmdSetScissorWithCount", @vk.VK_DYNAMIC_STATE_SCISSOR_WITH_COUNT)
  if eds2q.get_extendedDynamicState2PatchControlPoints() != 0 {
    add_ds("vkCmdSetPatchControlPointsEXT", @vk.VK_DYNAMIC_STATE_PATCH_CONTROL_POINTS_EXT)
  }
  if eds3q.get_extendedDynamicState3TessellationDomainOrigin() != 0 {
    add_ds("vkCmdSetTessellationDomainOriginEXT", @vk.VK_DYNAMIC_STATE_TESSELLATION_DOMAIN_ORIGIN_EXT)
  }
  if eds3q.get_extendedDynamicState3DepthClampEnable() != 0 {
    add_ds("vkCmdSetDepthClampEnableEXT", @vk.VK_DYNAMIC_STATE_DEPTH_CLAMP_ENABLE_EXT)
  }
  if eds3q.get_extendedDynamicState3PolygonMode() != 0 {
    add_ds("vkCmdSetPolygonModeEXT", @vk.VK_DYNAMIC_STATE_POLYGON_MODE_EXT)
  }
  if eds3q.get_extendedDynamicState3RasterizationSamples() != 0 {
    add_ds("vkCmdSetRasterizationSamplesEXT", @vk.VK_DYNAMIC_STATE_RASTERIZATION_SAMPLES_EXT)
  }
  if eds3q.get_extendedDynamicState3SampleMask() != 0 {
    add_ds("vkCmdSetSampleMaskEXT", @vk.VK_DYNAMIC_STATE_SAMPLE_MASK_EXT)
  }
  if eds3q.get_extendedDynamicState3AlphaToCoverageEnable() != 0 {
    add_ds("vkCmdSetAlphaToCoverageEnableEXT", @vk.VK_DYNAMIC_STATE_ALPHA_TO_COVERAGE_ENABLE_EXT)
  }
  if eds2q.get_extendedDynamicState2LogicOp() != 0 {
    add_ds("vkCmdSetLogicOpEnableEXT", @vk.VK_DYNAMIC_STATE_LOGIC_OP_ENABLE_EXT)
  }
  if cweq.get_colorWriteEnable() != 0 {
    add_ds("vkCmdSetColorWriteEnableEXT", @vk.VK_DYNAMIC_STATE_COLOR_WRITE_ENABLE_EXT)
  }
  if eds3q.get_extendedDynamicState3DepthClipEnable() != 0 && dceq.get_depthClipEnable() != 0 {
    add_ds("vkCmdSetDepthClipEnableEXT", @vk.VK_DYNAMIC_STATE_DEPTH_CLIP_ENABLE_EXT)
  }
  if eds3q.get_extendedDynamicState3ConservativeRasterizationMode() != 0 {
    add_ds("vkCmdSetConservativeRasterizationModeEXT", @vk.VK_DYNAMIC_STATE_CONSERVATIVE_RASTERIZATION_MODE_EXT)
  }
  if eds3q.get_extendedDynamicState3ProvokingVertexMode() != 0 {
    add_ds("vkCmdSetProvokingVertexModeEXT", @vk.VK_DYNAMIC_STATE_PROVOKING_VERTEX_MODE_EXT)
  }
  if eds3q.get_extendedDynamicState3LineRasterizationMode() != 0 || f14q.get_rectangularLines() != 0 {
    add_ds("vkCmdSetLineRasterizationModeEXT", @vk.VK_DYNAMIC_STATE_LINE_RASTERIZATION_MODE_EXT)
  }
  if eds3q.get_extendedDynamicState3LineStippleEnable() != 0 || f14q.get_stippledRectangularLines() != 0 {
    add_ds("vkCmdSetLineStipple", @vk.VK_DYNAMIC_STATE_LINE_STIPPLE)
  }
  if eds3q.get_extendedDynamicState3ExtraPrimitiveOverestimationSize() != 0 {
    add_ds("vkCmdSetExtraPrimitiveOverestimationSizeEXT", @vk.VK_DYNAMIC_STATE_EXTRA_PRIMITIVE_OVERESTIMATION_SIZE_EXT)
  }
  if vidsq.get_vertexInputDynamicState() != 0 {
    add_ds("vkCmdSetVertexInputEXT", @vk.VK_DYNAMIC_STATE_VERTEX_INPUT_EXT)
  }
  if eds2q.get_extendedDynamicState2LogicOp() != 0 {
    add_ds("vkCmdSetLogicOpEXT", @vk.VK_DYNAMIC_STATE_LOGIC_OP_EXT)
  }
  if eds3q.get_extendedDynamicState3AlphaToOneEnable() != 0 {
    add_ds("vkCmdSetAlphaToOneEnableEXT", @vk.VK_DYNAMIC_STATE_ALPHA_TO_ONE_ENABLE_EXT)
  }
  if eds3q.get_extendedDynamicState3ColorBlendEnable() != 0 {
    add_ds("vkCmdSetColorBlendEnableEXT", @vk.VK_DYNAMIC_STATE_COLOR_BLEND_ENABLE_EXT)
  }
  if eds3q.get_extendedDynamicState3ColorWriteMask() != 0 {
    add_ds("vkCmdSetColorWriteMaskEXT", @vk.VK_DYNAMIC_STATE_COLOR_WRITE_MASK_EXT)
  }
  if eds3q.get_extendedDynamicState3RasterizationStream() != 0 && tfq.get_transformFeedback() != 0 && tfpq.get_maxTransformFeedbackStreams() > 0 {
    add_ds("vkCmdSetRasterizationStreamEXT", @vk.VK_DYNAMIC_STATE_RASTERIZATION_STREAM_EXT)
  }
  if eds3q.get_extendedDynamicState3SampleLocationsEnable() != 0 {
    add_ds("vkCmdSetSampleLocationsEnableEXT", @vk.VK_DYNAMIC_STATE_SAMPLE_LOCATIONS_ENABLE_EXT)
  }
  if eds3q.get_extendedDynamicState3LineStippleEnable() != 0 {
    add_ds("vkCmdSetLineStippleEnableEXT", @vk.VK_DYNAMIC_STATE_LINE_STIPPLE_ENABLE_EXT)
  }
  if eds3q.get_extendedDynamicState3DepthClipNegativeOneToOne() != 0 && dccq.get_depthClipControl() != 0 {
    add_ds("vkCmdSetDepthClipNegativeOneToOneEXT", @vk.VK_DYNAMIC_STATE_DEPTH_CLIP_NEGATIVE_ONE_TO_ONE_EXT)
  }
  if eds1q.get_extendedDynamicState() != 0 {
    add_ds("vkCmdSetCullModeEXT", @vk.VK_DYNAMIC_STATE_CULL_MODE_EXT)
  }
  if eds1q.get_extendedDynamicState() != 0 {
    add_ds("vkCmdSetFrontFaceEXT", @vk.VK_DYNAMIC_STATE_FRONT_FACE_EXT)
  }
  if eds1q.get_extendedDynamicState() != 0 {
    add_ds("vkCmdSetPrimitiveTopologyEXT", @vk.VK_DYNAMIC_STATE_PRIMITIVE_TOPOLOGY_EXT)
  }
  if eds1q.get_extendedDynamicState() != 0 {
    add_ds("vkCmdSetViewportWithCountEXT", @vk.VK_DYNAMIC_STATE_VIEWPORT_WITH_COUNT_EXT)
  }
  if eds1q.get_extendedDynamicState() != 0 {
    add_ds("vkCmdSetScissorWithCountEXT", @vk.VK_DYNAMIC_STATE_SCISSOR_WITH_COUNT_EXT)
  }
  if eds1q.get_extendedDynamicState() != 0 {
    add_ds("vkCmdSetDepthTestEnableEXT", @vk.VK_DYNAMIC_STATE_DEPTH_TEST_ENABLE_EXT)
  }
  if eds1q.get_extendedDynamicState() != 0 {
    add_ds("vkCmdSetDepthWriteEnableEXT", @vk.VK_DYNAMIC_STATE_DEPTH_WRITE_ENABLE_EXT)
  }
  if eds1q.get_extendedDynamicState() != 0 {
    add_ds("vkCmdSetDepthCompareOpEXT", @vk.VK_DYNAMIC_STATE_DEPTH_COMPARE_OP_EXT)
  }
  if eds1q.get_extendedDynamicState() != 0 {
    add_ds("vkCmdSetDepthBoundsTestEnableEXT", @vk.VK_DYNAMIC_STATE_DEPTH_BOUNDS_TEST_ENABLE_EXT)
  }
  if eds1q.get_extendedDynamicState() != 0 {
    add_ds("vkCmdSetStencilTestEnableEXT", @vk.VK_DYNAMIC_STATE_STENCIL_TEST_ENABLE_EXT)
  }
  if eds1q.get_extendedDynamicState() != 0 {
    add_ds("vkCmdSetStencilOpEXT", @vk.VK_DYNAMIC_STATE_STENCIL_OP_EXT)
  }
  if eds2q.get_extendedDynamicState2() != 0 {
    add_ds("vkCmdSetRasterizerDiscardEnableEXT", @vk.VK_DYNAMIC_STATE_RASTERIZER_DISCARD_ENABLE_EXT)
  }
  if eds2q.get_extendedDynamicState2() != 0 {
    add_ds("vkCmdSetDepthBiasEnableEXT", @vk.VK_DYNAMIC_STATE_DEPTH_BIAS_ENABLE_EXT)
  }
  if eds2q.get_extendedDynamicState2() != 0 {
    add_ds("vkCmdSetPrimitiveRestartEnableEXT", @vk.VK_DYNAMIC_STATE_PRIMITIVE_RESTART_ENABLE_EXT)
  }
  if eds3q.get_extendedDynamicState3LineStippleEnable() != 0 || f14q.get_stippledRectangularLines() != 0 {
    add_ds("vkCmdSetLineStippleEXT", @vk.VK_DYNAMIC_STATE_LINE_STIPPLE_EXT)
  }
  if eds3q.get_extendedDynamicState3LineStippleEnable() != 0 || f14q.get_stippledRectangularLines() != 0 {
    add_ds("vkCmdSetLineStippleKHR", @vk.VK_DYNAMIC_STATE_LINE_STIPPLE_KHR)
  }
  if has_ext("VK_EXT_discard_rectangles") {
    add_ds("vkCmdSetDiscardRectangleEnableEXT", @vk.VK_DYNAMIC_STATE_DISCARD_RECTANGLE_ENABLE_EXT)
  }
  if has_ext("VK_EXT_discard_rectangles") {
    add_ds("vkCmdSetDiscardRectangleModeEXT", @vk.VK_DYNAMIC_STATE_DISCARD_RECTANGLE_MODE_EXT)
  }
  if has_ext("VK_EXT_discard_rectangles") {
    add_ds("vkCmdSetDiscardRectangleEXT", @vk.VK_DYNAMIC_STATE_DISCARD_RECTANGLE_EXT)
  }
  if eds3q.get_extendedDynamicState3ColorBlendEquation() != 0 {
    add_ds("vkCmdSetColorBlendEquationEXT", @vk.VK_DYNAMIC_STATE_COLOR_BLEND_EQUATION_EXT)
  }
  if fsrq.get_pipelineFragmentShadingRate() != 0 {
    add_ds("vkCmdSetFragmentShadingRateKHR", @vk.VK_DYNAMIC_STATE_FRAGMENT_SHADING_RATE_KHR)
  }
  if eds3q.get_extendedDynamicState3SampleLocationsEnable() != 0 {
    add_ds("vkCmdSetSampleLocationsEnableEXT", @vk.VK_DYNAMIC_STATE_SAMPLE_LOCATIONS_ENABLE_EXT)
  }
  // EXT/KHR aliases resolve to the same numeric value as the core state, and
  // pDynamicStates must not contain duplicates.
  let uniq : Array[UInt32] = []
  for i = 0; i < dsarr.length(); i = i + 1 {
    let mut dup = false
    for j = 0; j < uniq.length(); j = j + 1 {
      if uniq[j] == dsarr[i] {
        dup = true
      }
    }
    if !dup {
      uniq.push(dsarr[i])
    }
  }
  let ds = FixedArray::make(uniq.length(), (0 : UInt32))
  for i = 0; i < uniq.length(); i = i + 1 {
    ds[i] = uniq[i]
  }

  // offscreen color target
  let ici2 = @vk.VkImageCreateInfo::new()
  ici2.set_imageType(@vk.VK_IMAGE_TYPE_2D)
  ici2.set_format(@vk.VK_FORMAT_R8G8B8A8_UNORM)
  let ext3 = @vk.VkExtent3D::new()
  ext3.set_width((64 : UInt32))
  ext3.set_height((64 : UInt32))
  ext3.set_depth((1 : UInt32))
  ici2.set_extent(ext3)
  ici2.set_mipLevels((1 : UInt32))
  ici2.set_arrayLayers((1 : UInt32))
  ici2.set_samples(@vk.VK_SAMPLE_COUNT_1_BIT)
  ici2.set_tiling(@vk.VK_IMAGE_TILING_OPTIMAL)
  ici2.set_usage(@vk.VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT | @vk.VK_IMAGE_USAGE_TRANSFER_SRC_BIT)
  let img_out = FixedArray::make(1, @vk.VkImage::null())
  let _ = (dfn.vkCreateImage)(dev, ici2, na, img_out)
  let img = img_out[0]
  let ireq = @vk.VkMemoryRequirements::new()
  (dfn.vkGetImageMemoryRequirements)(dev, img, ireq)
  let mp = @vk.VkPhysicalDeviceMemoryProperties::new()
  (ifn.vkGetPhysicalDeviceMemoryProperties)(phys, mp)
  let mut mi = 0
  for i = 0; i < mp.get_memoryTypeCount().reinterpret_as_int(); i = i + 1 {
    if (ireq.get_memoryTypeBits() & ((1 : UInt32) << i)) != (0 : UInt32) {
      if (mp.get_memoryTypes_at(i).get_propertyFlags() & @vk.VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT) != (0 : UInt32) {
        mi = i
        break
      }
    }
  }
  let mai = @vk.VkMemoryAllocateInfo::new()
  mai.set_allocationSize(ireq.get_size())
  mai.set_memoryTypeIndex(mi.reinterpret_as_uint())
  let imem_out = FixedArray::make(1, @vk.VkDeviceMemory::null())
  let _ = (dfn.vkAllocateMemory)(dev, mai, na, imem_out)
  let _ = (dfn.vkBindImageMemory)(dev, img, imem_out[0], (0 : UInt64))
  let range = @vk.VkImageSubresourceRange::new()
  range.set_aspectMask(@vk.VK_IMAGE_ASPECT_COLOR_BIT)
  range.set_levelCount((1 : UInt32))
  range.set_layerCount((1 : UInt32))
  let ivci = @vk.VkImageViewCreateInfo::new()
  ivci.set_image(img)
  ivci.set_viewType(@vk.VK_IMAGE_VIEW_TYPE_2D)
  ivci.set_format(@vk.VK_FORMAT_R8G8B8A8_UNORM)
  ivci.set_subresourceRange(range)
  let iv_out = FixedArray::make(1, @vk.VkImageView::null())
  let _ = (dfn.vkCreateImageView)(dev, ivci, na, iv_out)
  let view = iv_out[0]

  // pipeline: push-constant range + fully dynamic state
  let vert = @shader.compile_shader_file("examples/vulkan/draw/shader.vert", @shader.SHADER_KIND_VERTEX)
  let frag = @shader.compile_shader_file("examples/vulkan/draw/shader.frag", @shader.SHADER_KIND_FRAGMENT)
  let vsmci = @vk.VkShaderModuleCreateInfo::new()
  vsmci.set_codeSize((vert.length() * 4).to_uint64())
  vsmci.set_pCode(vert)
  let vsm_out = FixedArray::make(1, @vk.VkShaderModule::null())
  let _ = (dfn.vkCreateShaderModule)(dev, vsmci, na, vsm_out)
  let fsmci = @vk.VkShaderModuleCreateInfo::new()
  fsmci.set_codeSize((frag.length() * 4).to_uint64())
  fsmci.set_pCode(frag)
  let fsm_out = FixedArray::make(1, @vk.VkShaderModule::null())
  let _ = (dfn.vkCreateShaderModule)(dev, fsmci, na, fsm_out)
  let stages = @vk.VkPipelineShaderStageCreateInfo::array(2)
  stages.set_stage_at(0, @vk.VK_SHADER_STAGE_VERTEX_BIT)
  stages.set_module_at(0, vsm_out[0])
  stages.set_pName_at(0, @vk.cstr("main"))
  stages.set_stage_at(1, @vk.VK_SHADER_STAGE_FRAGMENT_BIT)
  stages.set_module_at(1, fsm_out[0])
  stages.set_pName_at(1, @vk.cstr("main"))
  let pcr = @vk.VkPushConstantRange::new()
  pcr.set_stageFlags(@vk.VK_SHADER_STAGE_FRAGMENT_BIT)
  pcr.set_offset((0 : UInt32))
  pcr.set_size((16 : UInt32))
  let plci = @vk.VkPipelineLayoutCreateInfo::new()
  plci.set_pushConstantRangeCount((1 : UInt32))
  plci.set_pPushConstantRanges(pcr)
  let pl_out = FixedArray::make(1, @vk.VkPipelineLayout::null())
  let _ = (dfn.vkCreatePipelineLayout)(dev, plci, na, pl_out)
  let layout = pl_out[0]
  let vinput = @vk.VkPipelineVertexInputStateCreateInfo::new()
  let iasm = @vk.VkPipelineInputAssemblyStateCreateInfo::new()
  iasm.set_topology(@vk.VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST)
  let vpstate = @vk.VkPipelineViewportStateCreateInfo::new()
  vpstate.set_viewportCount(if use_wc { (0 : UInt32) } else { (1 : UInt32) })
  vpstate.set_scissorCount(if use_wc { (0 : UInt32) } else { (1 : UInt32) })
  let rast = @vk.VkPipelineRasterizationStateCreateInfo::new()
  rast.set_polygonMode(@vk.VK_POLYGON_MODE_FILL)
  rast.set_cullMode(@vk.VK_CULL_MODE_NONE)
  rast.set_frontFace(@vk.VK_FRONT_FACE_CLOCKWISE)
  rast.set_lineWidth((1.0 : Float))
  let ms = @vk.VkPipelineMultisampleStateCreateInfo::new()
  ms.set_rasterizationSamples(@vk.VK_SAMPLE_COUNT_1_BIT)
  let cba = @vk.VkPipelineColorBlendAttachmentState::new()
  cba.set_colorWriteMask(@vk.VK_COLOR_COMPONENT_R_BIT | @vk.VK_COLOR_COMPONENT_G_BIT | @vk.VK_COLOR_COMPONENT_B_BIT | @vk.VK_COLOR_COMPONENT_A_BIT)
  let cbstate = @vk.VkPipelineColorBlendStateCreateInfo::new()
  cbstate.set_attachmentCount((1 : UInt32))
  cbstate.set_pAttachments(cba)
  let dyn_state = @vk.VkPipelineDynamicStateCreateInfo::new()
  dyn_state.set_dynamicStateCount(ds.length().reinterpret_as_uint())
  dyn_state.set_pDynamicStates(ds)
  let prci = @vk.VkPipelineRenderingCreateInfo::new()
  prci.set_colorAttachmentCount((1 : UInt32))
  prci.set_pColorAttachmentFormats(FixedArray::make(1, @vk.VK_FORMAT_R8G8B8A8_UNORM))
  let gpci = @vk.VkGraphicsPipelineCreateInfo::new()
  gpci.set_pNext(prci.as_ptr())
  gpci.set_stageCount((2 : UInt32))
  gpci.set_pStages(stages)
  gpci.set_pVertexInputState(vinput)
  gpci.set_pInputAssemblyState(iasm)
  gpci.set_pViewportState(vpstate)
  gpci.set_pRasterizationState(rast)
  gpci.set_pMultisampleState(ms)
  gpci.set_pColorBlendState(cbstate)
  gpci.set_pDynamicState(dyn_state)
  gpci.set_layout(layout)
  let pipe_out = FixedArray::make(1, @vk.VkPipeline::null())
  let gpr = (dfn.vkCreateGraphicsPipelines)(dev, @vk.VkPipelineCache::null(), (1 : UInt32), gpci, na, pipe_out)
  if gpr != 0 {
    println("[vulkan/draw] FAIL — pipeline=\{gpr} states=\{ds.length()}")
    return
  }
  let pipe = pipe_out[0]
  // VIEWPORT and VIEWPORT_WITH_COUNT are mutually exclusive (VUID-...-04132),
  // so the legacy pair is exercised on a second pipeline.
  let ds2 = FixedArray::make(2, (0 : UInt32))
  ds2[0] = @vk.VK_DYNAMIC_STATE_VIEWPORT
  ds2[1] = @vk.VK_DYNAMIC_STATE_SCISSOR
  let dyn2 = @vk.VkPipelineDynamicStateCreateInfo::new()
  dyn2.set_dynamicStateCount((2 : UInt32))
  dyn2.set_pDynamicStates(ds2)
  let vp2 = @vk.VkPipelineViewportStateCreateInfo::new()
  vp2.set_viewportCount((1 : UInt32))
  vp2.set_scissorCount((1 : UInt32))
  let gpci2 = @vk.VkGraphicsPipelineCreateInfo::new()
  gpci2.set_pNext(prci.as_ptr())
  gpci2.set_stageCount((2 : UInt32))
  gpci2.set_pStages(stages)
  gpci2.set_pVertexInputState(vinput)
  gpci2.set_pInputAssemblyState(iasm)
  gpci2.set_pViewportState(vp2)
  gpci2.set_pRasterizationState(rast)
  gpci2.set_pMultisampleState(ms)
  gpci2.set_pColorBlendState(cbstate)
  gpci2.set_pDynamicState(dyn2)
  gpci2.set_layout(layout)
  let pipe2_out = FixedArray::make(1, @vk.VkPipeline::null())
  let gpr2 = (dfn.vkCreateGraphicsPipelines)(dev, @vk.VkPipelineCache::null(), (1 : UInt32), gpci2, na, pipe2_out)
  let pipe2 = pipe2_out[0]

  // index + indirect buffers
  let host = @vk.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | @vk.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT
  let mkbuf = fn(size : UInt64, usage : UInt32, props : UInt32) -> (@vk.VkBuffer, @vk.VkDeviceMemory) {
    let ci = @vk.VkBufferCreateInfo::new()
    ci.set_size(size)
    ci.set_usage(usage)
    let o = FixedArray::make(1, @vk.VkBuffer::null())
    let _ = (dfn.vkCreateBuffer)(dev, ci, na, o)
    let rq = @vk.VkMemoryRequirements::new()
    (dfn.vkGetBufferMemoryRequirements)(dev, o[0], rq)
    let mut bmi = 0
    for i = 0; i < mp.get_memoryTypeCount().reinterpret_as_int(); i = i + 1 {
      if (rq.get_memoryTypeBits() & ((1 : UInt32) << i)) != (0 : UInt32) {
        if (mp.get_memoryTypes_at(i).get_propertyFlags() & props) == props {
          bmi = i
          break
        }
      }
    }
    let ai = @vk.VkMemoryAllocateInfo::new()
    ai.set_allocationSize(rq.get_size())
    ai.set_memoryTypeIndex(bmi.reinterpret_as_uint())
    let mo = FixedArray::make(1, @vk.VkDeviceMemory::null())
    let _ = (dfn.vkAllocateMemory)(dev, ai, na, mo)
    let _ = (dfn.vkBindBufferMemory)(dev, o[0], mo[0], (0 : UInt64))
    ci.free()
    (o[0], mo[0])
  }
  let (ibuf, imem2) = mkbuf((64 : UInt64), @vk.VK_BUFFER_USAGE_INDEX_BUFFER_BIT, host)
  let (dbuf, dmem) = mkbuf((256 : UInt64), @vk.VK_BUFFER_USAGE_INDIRECT_BUFFER_BIT, host)
  let (cbuf, cmem) = mkbuf((64 : UInt64), @vk.VK_BUFFER_USAGE_INDIRECT_BUFFER_BIT | @vk.VK_BUFFER_USAGE_TRANSFER_DST_BIT, host)
  let (vbuf, vmem) = mkbuf((24 : UInt64), @vk.VK_BUFFER_USAGE_VERTEX_BUFFER_BIT, host)
  let (rbuf, rmem) = mkbuf((64 * 64 * 4).to_uint64(), @vk.VK_BUFFER_USAGE_TRANSFER_DST_BIT, host)
  let idx = FixedArray::make(6, (0 : UInt32))
  for i = 0; i < 6; i = i + 1 {
    idx[i] = (i % 3).reinterpret_as_uint()
  }
  let _ = @vk.upload_uint32(dev, imem2, idx, 24)
  // VkDrawIndirectCommand {vertexCount, instanceCount, firstVertex, firstInstance}
  let dcmd = FixedArray::make(4, (0 : UInt32))
  dcmd[0] = (3 : UInt32)
  dcmd[1] = (1 : UInt32)
  let _ = @vk.upload_uint32(dev, dmem, dcmd, 16)
  let cnt = FixedArray::make(1, (1 : UInt32))
  let _ = @vk.upload_uint32(dev, cmem, cnt, 4)

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

  let b2 = @vk.VkImageMemoryBarrier2::new()
  b2.set_srcStageMask(@vk.VK_PIPELINE_STAGE_2_TOP_OF_PIPE_BIT)
  b2.set_dstStageMask(@vk.VK_PIPELINE_STAGE_2_COLOR_ATTACHMENT_OUTPUT_BIT)
  b2.set_dstAccessMask(@vk.VK_ACCESS_2_COLOR_ATTACHMENT_WRITE_BIT)
  b2.set_oldLayout(@vk.VK_IMAGE_LAYOUT_UNDEFINED)
  b2.set_newLayout(@vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL)
  b2.set_srcQueueFamilyIndex((0xFFFFFFFF : UInt32))
  b2.set_dstQueueFamilyIndex((0xFFFFFFFF : UInt32))
  b2.set_image(img)
  b2.set_subresourceRange(range)
  let dep = @vk.VkDependencyInfo::new()
  dep.set_imageMemoryBarrierCount((1 : UInt32))
  dep.set_pImageMemoryBarriers(b2)
  (dfn.vkCmdPipelineBarrier2)(cb, dep)

  let cv = @vk.VkClearValue::new()
  cv.set_color_rgba((0.0 : Float), (0.0 : Float), (0.0 : Float), (1.0 : Float))
  let att = @vk.VkRenderingAttachmentInfo::new()
  att.set_imageView(view)
  att.set_imageLayout(@vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL)
  att.set_loadOp(@vk.VK_ATTACHMENT_LOAD_OP_CLEAR)
  att.set_storeOp(@vk.VK_ATTACHMENT_STORE_OP_STORE)
  att.set_clearValue(cv)
  let ext2 = @vk.VkExtent2D::new()
  ext2.set_width((64 : UInt32))
  ext2.set_height((64 : UInt32))
  let area = @vk.VkRect2D::new()
  area.set_extent(ext2)
  let ri = @vk.VkRenderingInfo::new()
  ri.set_renderArea(area)
  ri.set_layerCount((1 : UInt32))
  ri.set_colorAttachmentCount((1 : UInt32))
  ri.set_pColorAttachments(att)
  if has("vkCmdBeginRenderingKHR") {
    (dfn.vkCmdBeginRenderingKHR)(cb, ri)
    n = n + 1
  } else {
    (dfn.vkCmdBeginRendering)(cb, ri)
  }
  (dfn.vkCmdBindPipeline)(cb, @vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe)

  // ---- every declared dynamic state ----
  let vp = @vk.VkViewport::new()
  vp.set_width((64.0 : Float))
  vp.set_height((64.0 : Float))
  vp.set_maxDepth((1.0 : Float))
  let _vps = FixedArray::make(1, vp)
  let sc = @vk.VkRect2D::new()
  sc.set_extent(ext2)
  let _scs = FixedArray::make(1, sc)
  if gpr2 == 0 {
    (dfn.vkCmdBindPipeline)(cb, @vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe2)
    if has("vkCmdSetViewport") {
      (dfn.vkCmdSetViewport)(cb, (0 : UInt32), (1 : UInt32), vp)
      n = n + 1
    }
    if has("vkCmdSetScissor") {
      (dfn.vkCmdSetScissor)(cb, (0 : UInt32), (1 : UInt32), sc)
      n = n + 1
    }
    (dfn.vkCmdDraw)(cb, (3 : UInt32), (1 : UInt32), (0 : UInt32), (0 : UInt32))
    (dfn.vkCmdBindPipeline)(cb, @vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe)
  }
  if has("vkCmdSetViewportWithCount") {
    (dfn.vkCmdSetViewportWithCount)(cb, (1 : UInt32), vp)
    n = n + 1
  }
  if has("vkCmdSetScissorWithCount") {
    (dfn.vkCmdSetScissorWithCount)(cb, (1 : UInt32), sc)
    n = n + 1
  }
  if has("vkCmdSetLineWidth") {
    (dfn.vkCmdSetLineWidth)(cb, (1.0 : Float))
    n = n + 1
  }
  if has("vkCmdSetDepthBias") {
    (dfn.vkCmdSetDepthBias)(cb, (0.0 : Float), (0.0 : Float), (0.0 : Float))
    n = n + 1
  }
  if has("vkCmdSetBlendConstants") {
    (dfn.vkCmdSetBlendConstants)(cb, FixedArray::make(4, (0.0 : Float)))
    n = n + 1
  }
  if has("vkCmdSetDepthBounds") {
    (dfn.vkCmdSetDepthBounds)(cb, (0.0 : Float), (1.0 : Float))
    n = n + 1
  }
  if has("vkCmdSetStencilCompareMask") {
    (dfn.vkCmdSetStencilCompareMask)(cb, @vk.VK_STENCIL_FACE_FRONT_AND_BACK, (0xFF : UInt32))
    n = n + 1
  }
  if has("vkCmdSetStencilWriteMask") {
    (dfn.vkCmdSetStencilWriteMask)(cb, @vk.VK_STENCIL_FACE_FRONT_AND_BACK, (0xFF : UInt32))
    n = n + 1
  }
  if has("vkCmdSetStencilReference") {
    (dfn.vkCmdSetStencilReference)(cb, @vk.VK_STENCIL_FACE_FRONT_AND_BACK, (0 : UInt32))
    n = n + 1
  }
  if has("vkCmdSetCullMode") && eds1q.get_extendedDynamicState() != 0 {
    (dfn.vkCmdSetCullMode)(cb, @vk.VK_CULL_MODE_NONE)
    n = n + 1
  }
  if has("vkCmdSetFrontFace") && eds1q.get_extendedDynamicState() != 0 {
    (dfn.vkCmdSetFrontFace)(cb, @vk.VK_FRONT_FACE_CLOCKWISE)
    n = n + 1
  }
  if has("vkCmdSetPrimitiveTopology") && eds1q.get_extendedDynamicState() != 0 {
    (dfn.vkCmdSetPrimitiveTopology)(cb, @vk.VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST)
    n = n + 1
  }
  if has("vkCmdSetDepthTestEnable") && eds1q.get_extendedDynamicState() != 0 {
    (dfn.vkCmdSetDepthTestEnable)(cb, (0 : UInt32))
    n = n + 1
  }
  if has("vkCmdSetDepthWriteEnable") && eds1q.get_extendedDynamicState() != 0 {
    (dfn.vkCmdSetDepthWriteEnable)(cb, (0 : UInt32))
    n = n + 1
  }
  if has("vkCmdSetDepthCompareOp") && eds1q.get_extendedDynamicState() != 0 {
    (dfn.vkCmdSetDepthCompareOp)(cb, @vk.VK_COMPARE_OP_LESS_OR_EQUAL)
    n = n + 1
  }
  if has("vkCmdSetDepthBoundsTestEnable") && eds1q.get_extendedDynamicState() != 0 {
    (dfn.vkCmdSetDepthBoundsTestEnable)(cb, (0 : UInt32))
    n = n + 1
  }
  if has("vkCmdSetStencilTestEnable") && eds1q.get_extendedDynamicState() != 0 {
    (dfn.vkCmdSetStencilTestEnable)(cb, (0 : UInt32))
    n = n + 1
  }
  if has("vkCmdSetStencilOp") && eds1q.get_extendedDynamicState() != 0 {
    (dfn.vkCmdSetStencilOp)(cb, @vk.VK_STENCIL_FACE_FRONT_AND_BACK, @vk.VK_STENCIL_OP_KEEP, @vk.VK_STENCIL_OP_KEEP, @vk.VK_STENCIL_OP_KEEP, @vk.VK_COMPARE_OP_ALWAYS)
    n = n + 1
  }
  if has("vkCmdSetRasterizerDiscardEnable") && eds2q.get_extendedDynamicState2() != 0 {
    (dfn.vkCmdSetRasterizerDiscardEnable)(cb, (0 : UInt32))
    n = n + 1
  }
  if has("vkCmdSetDepthBiasEnable") && eds2q.get_extendedDynamicState2() != 0 {
    (dfn.vkCmdSetDepthBiasEnable)(cb, (0 : UInt32))
    n = n + 1
  }
  if has("vkCmdSetPrimitiveRestartEnable") && eds2q.get_extendedDynamicState2() != 0 {
    (dfn.vkCmdSetPrimitiveRestartEnable)(cb, (0 : UInt32))
    n = n + 1
  }
  if has("vkCmdSetPatchControlPointsEXT") && eds2q.get_extendedDynamicState2PatchControlPoints() != 0 {
    (dfn.vkCmdSetPatchControlPointsEXT)(cb, (3 : UInt32))
    n = n + 1
  }
  if has("vkCmdSetTessellationDomainOriginEXT") && eds3q.get_extendedDynamicState3TessellationDomainOrigin() != 0 {
    (dfn.vkCmdSetTessellationDomainOriginEXT)(cb, @vk.VK_TESSELLATION_DOMAIN_ORIGIN_UPPER_LEFT)
    n = n + 1
  }
  if has("vkCmdSetDepthClampEnableEXT") && eds3q.get_extendedDynamicState3DepthClampEnable() != 0 {
    (dfn.vkCmdSetDepthClampEnableEXT)(cb, (0 : UInt32))
    n = n + 1
  }
  if has("vkCmdSetPolygonModeEXT") && eds3q.get_extendedDynamicState3PolygonMode() != 0 {
    (dfn.vkCmdSetPolygonModeEXT)(cb, @vk.VK_POLYGON_MODE_FILL)
    n = n + 1
  }
  if has("vkCmdSetRasterizationSamplesEXT") && eds3q.get_extendedDynamicState3RasterizationSamples() != 0 {
    (dfn.vkCmdSetRasterizationSamplesEXT)(cb, @vk.VK_SAMPLE_COUNT_1_BIT)
    n = n + 1
  }
  if has("vkCmdSetSampleMaskEXT") && eds3q.get_extendedDynamicState3SampleMask() != 0 {
    (dfn.vkCmdSetSampleMaskEXT)(cb, @vk.VK_SAMPLE_COUNT_1_BIT, FixedArray::make(1, (0xFFFFFFFF : UInt32)))
    n = n + 1
  }
  if has("vkCmdSetAlphaToCoverageEnableEXT") && eds3q.get_extendedDynamicState3AlphaToCoverageEnable() != 0 {
    (dfn.vkCmdSetAlphaToCoverageEnableEXT)(cb, (0 : UInt32))
    n = n + 1
  }
  if has("vkCmdSetLogicOpEnableEXT") && eds2q.get_extendedDynamicState2LogicOp() != 0 {
    (dfn.vkCmdSetLogicOpEnableEXT)(cb, (0 : UInt32))
    n = n + 1
  }
  if has("vkCmdSetColorWriteEnableEXT") && cweq.get_colorWriteEnable() != 0 {
    (dfn.vkCmdSetColorWriteEnableEXT)(cb, (1 : UInt32), FixedArray::make(1, (1 : UInt32)))
    n = n + 1
  }
  if has("vkCmdSetDepthClipEnableEXT") && eds3q.get_extendedDynamicState3DepthClipEnable() != 0 && dceq.get_depthClipEnable() != 0 {
    (dfn.vkCmdSetDepthClipEnableEXT)(cb, (1 : UInt32))
    n = n + 1
  }
  if has("vkCmdSetConservativeRasterizationModeEXT") && eds3q.get_extendedDynamicState3ConservativeRasterizationMode() != 0 {
    (dfn.vkCmdSetConservativeRasterizationModeEXT)(cb, @vk.VK_CONSERVATIVE_RASTERIZATION_MODE_DISABLED_EXT)
    n = n + 1
  }
  if has("vkCmdSetProvokingVertexModeEXT") && eds3q.get_extendedDynamicState3ProvokingVertexMode() != 0 {
    (dfn.vkCmdSetProvokingVertexModeEXT)(cb, @vk.VK_PROVOKING_VERTEX_MODE_FIRST_VERTEX_EXT)
    n = n + 1
  }
  if has("vkCmdSetLineRasterizationModeEXT") && (eds3q.get_extendedDynamicState3LineRasterizationMode() != 0 || f14q.get_rectangularLines() != 0) {
    (dfn.vkCmdSetLineRasterizationModeEXT)(cb, @vk.VK_LINE_RASTERIZATION_MODE_DEFAULT)
    n = n + 1
  }
  if has("vkCmdSetLineStipple") && (eds3q.get_extendedDynamicState3LineStippleEnable() != 0 || f14q.get_stippledRectangularLines() != 0) {
    (dfn.vkCmdSetLineStipple)(cb, (1 : UInt32), (0xFFFF : UInt))
    n = n + 1
  }
  if has("vkCmdSetExtraPrimitiveOverestimationSizeEXT") && eds3q.get_extendedDynamicState3ExtraPrimitiveOverestimationSize() != 0 {
    (dfn.vkCmdSetExtraPrimitiveOverestimationSizeEXT)(cb, (0.0 : Float))
    n = n + 1
  }
  if has("vkCmdSetVertexInputEXT") && vidsq.get_vertexInputDynamicState() != 0 {
    let vbd = @vk.VkVertexInputBindingDescription2EXT::new()
    vbd.set_binding((0 : UInt32))
    vbd.set_stride((8 : UInt32))
    vbd.set_inputRate(@vk.VK_VERTEX_INPUT_RATE_VERTEX)
    vbd.set_divisor((1 : UInt32))
    (dfn.vkCmdSetVertexInputEXT)(cb, (1 : UInt32), vbd, (0 : UInt32), @vk.VkVertexInputAttributeDescription2EXT::null())
    n = n + 1
    vbd.free()
  }
  if has("vkCmdSetRenderingAttachmentLocations") {
    let loc = @vk.VkRenderingAttachmentLocationInfo::new()
    loc.set_colorAttachmentCount((1 : UInt32))
    loc.set_pColorAttachmentLocations(FixedArray::make(1, (0 : UInt32)))
    (dfn.vkCmdSetRenderingAttachmentLocations)(cb, loc)
    n = n + 1
    loc.free()
  }
  if has("vkCmdSetRenderingAttachmentLocationsKHR") {
    let loc = @vk.VkRenderingAttachmentLocationInfo::new()
    loc.set_colorAttachmentCount((1 : UInt32))
    loc.set_pColorAttachmentLocations(FixedArray::make(1, (0 : UInt32)))
    (dfn.vkCmdSetRenderingAttachmentLocationsKHR)(cb, loc)
    n = n + 1
    loc.free()
  }

  if has("vkCmdSetLogicOpEXT") && eds2q.get_extendedDynamicState2LogicOp() != 0 {
    (dfn.vkCmdSetLogicOpEXT)(cb, @vk.VK_LOGIC_OP_COPY)
    n = n + 1
  }
  if has("vkCmdSetAlphaToOneEnableEXT") && eds3q.get_extendedDynamicState3AlphaToOneEnable() != 0 {
    (dfn.vkCmdSetAlphaToOneEnableEXT)(cb, (0 : UInt32))
    n = n + 1
  }
  if has("vkCmdSetColorBlendEnableEXT") && eds3q.get_extendedDynamicState3ColorBlendEnable() != 0 {
    (dfn.vkCmdSetColorBlendEnableEXT)(cb, (0 : UInt32), (1 : UInt32), FixedArray::make(1, (0 : UInt32)))
    n = n + 1
  }
  if has("vkCmdSetColorWriteMaskEXT") && eds3q.get_extendedDynamicState3ColorWriteMask() != 0 {
    (dfn.vkCmdSetColorWriteMaskEXT)(cb, (0 : UInt32), (1 : UInt32), FixedArray::make(1, (0xF : UInt32)))
    n = n + 1
  }
  if has("vkCmdSetRasterizationStreamEXT") && eds3q.get_extendedDynamicState3RasterizationStream() != 0 && tfq.get_transformFeedback() != 0 && tfpq.get_maxTransformFeedbackStreams() > 0 {
    (dfn.vkCmdSetRasterizationStreamEXT)(cb, (0 : UInt32))
    n = n + 1
  }
  if has("vkCmdSetSampleLocationsEnableEXT") && eds3q.get_extendedDynamicState3SampleLocationsEnable() != 0 {
    (dfn.vkCmdSetSampleLocationsEnableEXT)(cb, (0 : UInt32))
    n = n + 1
  }
  if has("vkCmdSetLineStippleEnableEXT") && eds3q.get_extendedDynamicState3LineStippleEnable() != 0 {
    (dfn.vkCmdSetLineStippleEnableEXT)(cb, (0 : UInt32))
    n = n + 1
  }
  if has("vkCmdSetDepthClipNegativeOneToOneEXT") && eds3q.get_extendedDynamicState3DepthClipNegativeOneToOne() != 0 && dccq.get_depthClipControl() != 0 {
    (dfn.vkCmdSetDepthClipNegativeOneToOneEXT)(cb, (0 : UInt32))
    n = n + 1
  }
  if has("vkCmdSetCullModeEXT") && eds1q.get_extendedDynamicState() != 0 {
    (dfn.vkCmdSetCullModeEXT)(cb, @vk.VK_CULL_MODE_NONE)
    n = n + 1
  }
  if has("vkCmdSetFrontFaceEXT") && eds1q.get_extendedDynamicState() != 0 {
    (dfn.vkCmdSetFrontFaceEXT)(cb, @vk.VK_FRONT_FACE_CLOCKWISE)
    n = n + 1
  }
  if has("vkCmdSetPrimitiveTopologyEXT") && eds1q.get_extendedDynamicState() != 0 {
    (dfn.vkCmdSetPrimitiveTopologyEXT)(cb, @vk.VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST)
    n = n + 1
  }
  if has("vkCmdSetViewportWithCountEXT") && eds1q.get_extendedDynamicState() != 0 {
    (dfn.vkCmdSetViewportWithCountEXT)(cb, (1 : UInt32), vp)
    n = n + 1
  }
  if has("vkCmdSetScissorWithCountEXT") && eds1q.get_extendedDynamicState() != 0 {
    (dfn.vkCmdSetScissorWithCountEXT)(cb, (1 : UInt32), sc)
    n = n + 1
  }
  if has("vkCmdSetDepthTestEnableEXT") && eds1q.get_extendedDynamicState() != 0 {
    (dfn.vkCmdSetDepthTestEnableEXT)(cb, (0 : UInt32))
    n = n + 1
  }
  if has("vkCmdSetDepthWriteEnableEXT") && eds1q.get_extendedDynamicState() != 0 {
    (dfn.vkCmdSetDepthWriteEnableEXT)(cb, (0 : UInt32))
    n = n + 1
  }
  if has("vkCmdSetDepthCompareOpEXT") && eds1q.get_extendedDynamicState() != 0 {
    (dfn.vkCmdSetDepthCompareOpEXT)(cb, @vk.VK_COMPARE_OP_LESS_OR_EQUAL)
    n = n + 1
  }
  if has("vkCmdSetDepthBoundsTestEnableEXT") && eds1q.get_extendedDynamicState() != 0 {
    (dfn.vkCmdSetDepthBoundsTestEnableEXT)(cb, (0 : UInt32))
    n = n + 1
  }
  if has("vkCmdSetStencilTestEnableEXT") && eds1q.get_extendedDynamicState() != 0 {
    (dfn.vkCmdSetStencilTestEnableEXT)(cb, (0 : UInt32))
    n = n + 1
  }
  if has("vkCmdSetStencilOpEXT") && eds1q.get_extendedDynamicState() != 0 {
    (dfn.vkCmdSetStencilOpEXT)(cb, @vk.VK_STENCIL_FACE_FRONT_AND_BACK, @vk.VK_STENCIL_OP_KEEP, @vk.VK_STENCIL_OP_KEEP, @vk.VK_STENCIL_OP_KEEP, @vk.VK_COMPARE_OP_ALWAYS)
    n = n + 1
  }
  if has("vkCmdSetRasterizerDiscardEnableEXT") && eds2q.get_extendedDynamicState2() != 0 {
    (dfn.vkCmdSetRasterizerDiscardEnableEXT)(cb, (0 : UInt32))
    n = n + 1
  }
  if has("vkCmdSetDepthBiasEnableEXT") && eds2q.get_extendedDynamicState2() != 0 {
    (dfn.vkCmdSetDepthBiasEnableEXT)(cb, (0 : UInt32))
    n = n + 1
  }
  if has("vkCmdSetPrimitiveRestartEnableEXT") && eds2q.get_extendedDynamicState2() != 0 {
    (dfn.vkCmdSetPrimitiveRestartEnableEXT)(cb, (0 : UInt32))
    n = n + 1
  }
  if (has("vkCmdSetLineStippleEXT") && eds3q.get_extendedDynamicState3LineStippleEnable() != 0) || f14q.get_stippledRectangularLines() != 0 {
    (dfn.vkCmdSetLineStippleEXT)(cb, (1 : UInt32), (0xFFFF : UInt))
    n = n + 1
  }
  if (has("vkCmdSetLineStippleKHR") && eds3q.get_extendedDynamicState3LineStippleEnable() != 0) || f14q.get_stippledRectangularLines() != 0 {
    (dfn.vkCmdSetLineStippleKHR)(cb, (1 : UInt32), (0xFFFF : UInt))
    n = n + 1
  }
  let cbe = @vk.VkColorBlendEquationEXT::new()
  cbe.set_srcColorBlendFactor(@vk.VK_BLEND_FACTOR_ONE)
  cbe.set_dstColorBlendFactor(@vk.VK_BLEND_FACTOR_ZERO)
  cbe.set_colorBlendOp(@vk.VK_BLEND_OP_ADD)
  cbe.set_srcAlphaBlendFactor(@vk.VK_BLEND_FACTOR_ONE)
  cbe.set_dstAlphaBlendFactor(@vk.VK_BLEND_FACTOR_ZERO)
  cbe.set_alphaBlendOp(@vk.VK_BLEND_OP_ADD)
  let fsrExt = @vk.VkExtent2D::new()
  fsrExt.set_width((1 : UInt32))
  fsrExt.set_height((1 : UInt32))
  if has("vkCmdSetDiscardRectangleEnableEXT") && has_ext("VK_EXT_discard_rectangles") {
    (dfn.vkCmdSetDiscardRectangleEnableEXT)(cb, (0 : UInt32))
    n = n + 1
  }
  if has("vkCmdSetDiscardRectangleModeEXT") && has_ext("VK_EXT_discard_rectangles") {
    (dfn.vkCmdSetDiscardRectangleModeEXT)(cb, @vk.VK_DISCARD_RECTANGLE_MODE_EXCLUSIVE_EXT)
    n = n + 1
  }
  if has("vkCmdSetDiscardRectangleEXT") && has_ext("VK_EXT_discard_rectangles") {
    (dfn.vkCmdSetDiscardRectangleEXT)(cb, (0 : UInt32), (1 : UInt32), sc)
    n = n + 1
  }
  if has("vkCmdSetColorBlendEquationEXT") && eds3q.get_extendedDynamicState3ColorBlendEquation() != 0 {
    (dfn.vkCmdSetColorBlendEquationEXT)(cb, (0 : UInt32), (1 : UInt32), cbe)
    n = n + 1
  }
  if has("vkCmdSetFragmentShadingRateKHR") && fsrq.get_pipelineFragmentShadingRate() != 0 {
    (dfn.vkCmdSetFragmentShadingRateKHR)(cb, fsrExt, FixedArray::make(2, @vk.VK_FRAGMENT_SHADING_RATE_COMBINER_OP_KEEP_KHR))
    n = n + 1
  }
  if has("vkCmdSetSampleLocationsEnableEXT") && eds3q.get_extendedDynamicState3SampleLocationsEnable() != 0 {
    (dfn.vkCmdSetSampleLocationsEnableEXT)(cb, (0 : UInt32))
    n = n + 1
  }
  // ---- push constants (legacy + 2 + 2KHR) ----
  let pcdata = FixedArray::make(4, (1.0 : Float))
  (dfn.vkCmdPushConstants)(cb, layout, @vk.VK_SHADER_STAGE_FRAGMENT_BIT, (0 : UInt32), (16 : UInt32), @vk.float_ptr(pcdata))
  n = n + 1
  if has("vkCmdPushConstants2") {
    let pci = @vk.VkPushConstantsInfo::new()
    pci.set_layout(layout)
    pci.set_stageFlags(@vk.VK_SHADER_STAGE_FRAGMENT_BIT)
    pci.set_size((16 : UInt32))
    pci.set_pValues(@vk.float_ptr(pcdata))
    (dfn.vkCmdPushConstants2)(cb, pci)
    n = n + 1
    pci.free()
  }
  if has("vkCmdPushConstants2KHR") {
    let pci = @vk.VkPushConstantsInfo::new()
    pci.set_layout(layout)
    pci.set_stageFlags(@vk.VK_SHADER_STAGE_FRAGMENT_BIT)
    pci.set_size((16 : UInt32))
    pci.set_pValues(@vk.float_ptr(pcdata))
    (dfn.vkCmdPushConstants2KHR)(cb, pci)
    n = n + 1
    pci.free()
  }

  // ---- binds ----
  (dfn.vkCmdBindIndexBuffer)(cb, ibuf, (0 : UInt64), @vk.VK_INDEX_TYPE_UINT32)
  n = n + 1
  let vb_arr = FixedArray::make(1, vbuf)
  let vb_off = FixedArray::make(1, (0 : UInt64))
  let vb_size = FixedArray::make(1, (24 : UInt64))
  let vb_stride = FixedArray::make(1, (8 : UInt64))
  if has("vkCmdBindVertexBuffers2") {
    (dfn.vkCmdBindVertexBuffers2)(cb, (0 : UInt32), (1 : UInt32), vb_arr, vb_off, vb_size, vb_stride)
    n = n + 1
  }
  if has("vkCmdBindVertexBuffers2EXT") {
    (dfn.vkCmdBindVertexBuffers2EXT)(cb, (0 : UInt32), (1 : UInt32), vb_arr, vb_off, vb_size, vb_stride)
    n = n + 1
  }

  // ---- draw variants ----
  (dfn.vkCmdDraw)(cb, (3 : UInt32), (1 : UInt32), (0 : UInt32), (0 : UInt32))
  (dfn.vkCmdDrawIndexed)(cb, (6 : UInt32), (1 : UInt32), (0 : UInt32), (0 : Int32), (0 : UInt32))
  n = n + 1
  if has("vkCmdDrawIndirectCountKHR") {
    (dfn.vkCmdDrawIndirectCountKHR)(cb, dbuf, (0 : UInt64), cbuf, (0 : UInt64), (1 : UInt32), (16 : UInt32))
    n = n + 1
  }
  if has("vkCmdDrawIndexedIndirectCountKHR") {
    (dfn.vkCmdDrawIndexedIndirectCountKHR)(cb, dbuf, (0 : UInt64), cbuf, (0 : UInt64), (1 : UInt32), (20 : UInt32))
    n = n + 1
  }
  if has("vkCmdDrawMultiEXT") && mdq.get_multiDraw() != 0 {
    let md = @vk.VkMultiDrawInfoEXT::new()
    md.set_vertexCount((3 : UInt32))
    md.set_firstVertex((0 : UInt32))
    (dfn.vkCmdDrawMultiEXT)(cb, (1 : UInt32), md, (1 : UInt32), (0 : UInt32), (0 : UInt32))
    n = n + 1
    md.free()
  }
  if has("vkCmdDrawMultiIndexedEXT") && mdq.get_multiDraw() != 0 {
    let md = @vk.VkMultiDrawIndexedInfoEXT::new()
    md.set_indexCount((6 : UInt32))
    md.set_firstIndex((0 : UInt32))
    md.set_vertexOffset((0 : Int32))
    (dfn.vkCmdDrawMultiIndexedEXT)(cb, (1 : UInt32), md, (1 : UInt32), (0 : UInt32), (0 : UInt32), FixedArray::make(0, (0 : Int32)))
    n = n + 1
    md.free()
  }
  // clear inside rendering
  let ca = @vk.VkClearAttachment::new()
  ca.set_aspectMask(@vk.VK_IMAGE_ASPECT_COLOR_BIT)
  ca.set_colorAttachment((0 : UInt32))
  ca.set_clearValue(cv)
  let cr = @vk.VkClearRect::new()
  cr.set_rect(area)
  cr.set_baseArrayLayer((0 : UInt32))
  cr.set_layerCount((1 : UInt32))
  (dfn.vkCmdClearAttachments)(cb, (1 : UInt32), ca, (1 : UInt32), cr)
  n = n + 1
  (dfn.vkCmdDraw)(cb, (3 : UInt32), (1 : UInt32), (0 : UInt32), (0 : UInt32))
  if has("vkCmdEndRenderingKHR") {
    (dfn.vkCmdEndRenderingKHR)(cb)
    n = n + 1
  } else {
    (dfn.vkCmdEndRendering)(cb)
  }
  // offscreen readback: count_rendered assumes a presentable swapchain image,
  // so transition to TRANSFER_SRC and copy explicitly instead.
  b2.set_srcStageMask(@vk.VK_PIPELINE_STAGE_2_COLOR_ATTACHMENT_OUTPUT_BIT)
  b2.set_srcAccessMask(@vk.VK_ACCESS_2_COLOR_ATTACHMENT_WRITE_BIT)
  b2.set_dstStageMask(@vk.VK_PIPELINE_STAGE_2_ALL_TRANSFER_BIT)
  b2.set_dstAccessMask(@vk.VK_ACCESS_2_TRANSFER_READ_BIT)
  b2.set_oldLayout(@vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL)
  b2.set_newLayout(@vk.VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL)
  (dfn.vkCmdPipelineBarrier2)(cb, dep)
  let bic = @vk.VkBufferImageCopy::new()
  let subl = @vk.VkImageSubresourceLayers::new()
  subl.set_aspectMask(@vk.VK_IMAGE_ASPECT_COLOR_BIT)
  subl.set_layerCount((1 : UInt32))
  bic.set_imageSubresource(subl)
  bic.set_imageExtent(ext3)
  (dfn.vkCmdCopyImageToBuffer)(cb, img, @vk.VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL, rbuf, (1 : UInt32), bic)
  let _ = (dfn.vkEndCommandBuffer)(cb)

  let fci = @vk.VkFenceCreateInfo::new()
  let fence_out = FixedArray::make(1, @vk.VkFence::null())
  let _ = (dfn.vkCreateFence)(dev, fci, na, fence_out)
  let si = @vk.VkSubmitInfo::new()
  si.set_commandBufferCount((1 : UInt32))
  si.set_pCommandBuffers(cb_out)
  let sr = (dfn.vkQueueSubmit)(queue, (1 : UInt32), si, fence_out[0])
  let wr = (dfn.vkWaitForFences)(dev, (1 : UInt32), fence_out, (1 : UInt32), (10000000000 : UInt64))
  let px = @vk.download_buffer(dev, rmem, 64 * 64 * 4)
  let mut pixels = 0
  for i = 0; i < 64 * 64; i = i + 1 {
    if px[i * 4] != (0 : Byte) || px[i * 4 + 1] != (0 : Byte) || px[i * 4 + 2] != (0 : Byte) {
      pixels = pixels + 1
    }
  }
  let _ = (dfn.vkDeviceWaitIdle)(dev)

  (dfn.vkDestroyFence)(dev, fence_out[0], na)
  (dfn.vkDestroyCommandPool)(dev, cp_out[0], na)
  (dfn.vkDestroyBuffer)(dev, vbuf, na)
  (dfn.vkFreeMemory)(dev, vmem, na)
  (dfn.vkDestroyBuffer)(dev, rbuf, na)
  (dfn.vkFreeMemory)(dev, rmem, na)
  (dfn.vkDestroyBuffer)(dev, ibuf, na)
  (dfn.vkFreeMemory)(dev, imem2, na)
  (dfn.vkDestroyBuffer)(dev, dbuf, na)
  (dfn.vkFreeMemory)(dev, dmem, na)
  (dfn.vkDestroyBuffer)(dev, cbuf, na)
  (dfn.vkFreeMemory)(dev, cmem, na)
  if gpr2 == 0 {
    (dfn.vkDestroyPipeline)(dev, pipe2, na)
  }
  (dfn.vkDestroyPipeline)(dev, pipe, na)
  (dfn.vkDestroyPipelineLayout)(dev, layout, na)
  (dfn.vkDestroyShaderModule)(dev, vsm_out[0], na)
  (dfn.vkDestroyShaderModule)(dev, fsm_out[0], na)
  (dfn.vkDestroyImageView)(dev, view, na)
  (dfn.vkDestroyImage)(dev, img, na)
  (dfn.vkFreeMemory)(dev, imem_out[0], na)
  (dfn.vkDestroyDevice)(dev, na)
  @vk.destroy_debug_messenger(inst, ifn, messenger)
  (ifn.vkDestroyInstance)(inst, na)
  println("[vulkan/draw] commands=\{n} states=\{ds.length()} submit=\{sr} wait=\{wr} pixels=\{pixels}")
  if sr == 0 && wr == 0 && pixels > 0 && n >= 30 && g_errors.val == 0 {
    println("[vulkan/draw] OK — \{n} draw/state commands, \{ds.length()} dynamic states, \{pixels} pixels")
  } else {
    println("[vulkan/draw] FAIL — submit=\{sr} wait=\{wr} pixels=\{pixels} n=\{n} validation_errors=\{g_errors.val}")
  }
}