// Generated three-layer dispatch (ash-style). Entry = global linked symbols;
// Instance/Device = FuncRef tables loaded via per-command C wrappers.

pub extern "c" fn vkCreateInstance(pCreateInfo : VkInstanceCreateInfo, pAllocator : VkAllocationCallbacks, pInstance : FixedArray[VkInstance]) -> Int32 = "tycho_entry_vkCreateInstance"
pub extern "c" fn vkGetInstanceProcAddr(instance : VkInstance, pName : UInt64) -> UInt64 = "tycho_entry_vkGetInstanceProcAddr"
pub extern "c" fn vkEnumerateInstanceVersion(pApiVersion : FixedArray[UInt32]) -> Int32 = "tycho_entry_vkEnumerateInstanceVersion"
pub extern "c" fn vkEnumerateInstanceLayerProperties(pPropertyCount : FixedArray[UInt32], pProperties : VkLayerProperties) -> Int32 = "tycho_entry_vkEnumerateInstanceLayerProperties"
pub extern "c" fn vkEnumerateInstanceExtensionProperties(pLayerName : UInt64, pPropertyCount : FixedArray[UInt32], pProperties : VkExtensionProperties) -> Int32 = "tycho_entry_vkEnumerateInstanceExtensionProperties"
pub extern "c" fn vkGetExternalComputeQueueDataNV(externalQueue : VkExternalComputeQueueNV, params : VkExternalComputeQueueDataParamsNV, pData : UInt64) -> Unit = "tycho_entry_vkGetExternalComputeQueueDataNV"

pub struct InstanceFn {
  vkDestroyInstance : FuncRef[(VkInstance, VkAllocationCallbacks) -> Unit]
  vkEnumeratePhysicalDevices : FuncRef[(VkInstance, FixedArray[UInt32], FixedArray[VkPhysicalDevice]) -> Int32]
  vkGetDeviceProcAddr : FuncRef[(VkDevice, UInt64) -> UInt64]
  vkGetPhysicalDeviceProperties : FuncRef[(VkPhysicalDevice, VkPhysicalDeviceProperties) -> Unit]
  vkGetPhysicalDeviceQueueFamilyProperties : FuncRef[(VkPhysicalDevice, FixedArray[UInt32], VkQueueFamilyProperties) -> Unit]
  vkGetPhysicalDeviceMemoryProperties : FuncRef[(VkPhysicalDevice, VkPhysicalDeviceMemoryProperties) -> Unit]
  vkGetPhysicalDeviceFeatures : FuncRef[(VkPhysicalDevice, VkPhysicalDeviceFeatures) -> Unit]
  vkGetPhysicalDeviceFormatProperties : FuncRef[(VkPhysicalDevice, UInt32, VkFormatProperties) -> Unit]
  vkGetPhysicalDeviceImageFormatProperties : FuncRef[(VkPhysicalDevice, UInt32, UInt32, UInt32, UInt32, UInt32, VkImageFormatProperties) -> Int32]
  vkCreateDevice : FuncRef[(VkPhysicalDevice, VkDeviceCreateInfo, VkAllocationCallbacks, FixedArray[VkDevice]) -> Int32]
  vkEnumerateDeviceLayerProperties : FuncRef[(VkPhysicalDevice, FixedArray[UInt32], VkLayerProperties) -> Int32]
  vkEnumerateDeviceExtensionProperties : FuncRef[(VkPhysicalDevice, UInt64, FixedArray[UInt32], VkExtensionProperties) -> Int32]
  vkGetPhysicalDeviceSparseImageFormatProperties : FuncRef[(VkPhysicalDevice, UInt32, UInt32, UInt32, UInt32, UInt32, FixedArray[UInt32], VkSparseImageFormatProperties) -> Unit]
  vkCreateAndroidSurfaceKHR : FuncRef[(VkInstance, VkAndroidSurfaceCreateInfoKHR, VkAllocationCallbacks, FixedArray[VkSurfaceKHR]) -> Int32]
  vkCreateSurfaceOHOS : FuncRef[(VkInstance, VkSurfaceCreateInfoOHOS, VkAllocationCallbacks, FixedArray[VkSurfaceKHR]) -> Int32]
  vkGetPhysicalDeviceDisplayPropertiesKHR : FuncRef[(VkPhysicalDevice, FixedArray[UInt32], VkDisplayPropertiesKHR) -> Int32]
  vkGetPhysicalDeviceDisplayPlanePropertiesKHR : FuncRef[(VkPhysicalDevice, FixedArray[UInt32], VkDisplayPlanePropertiesKHR) -> Int32]
  vkGetDisplayPlaneSupportedDisplaysKHR : FuncRef[(VkPhysicalDevice, UInt32, FixedArray[UInt32], FixedArray[VkDisplayKHR]) -> Int32]
  vkGetDisplayModePropertiesKHR : FuncRef[(VkPhysicalDevice, VkDisplayKHR, FixedArray[UInt32], VkDisplayModePropertiesKHR) -> Int32]
  vkCreateDisplayModeKHR : FuncRef[(VkPhysicalDevice, VkDisplayKHR, VkDisplayModeCreateInfoKHR, VkAllocationCallbacks, FixedArray[VkDisplayModeKHR]) -> Int32]
  vkGetDisplayPlaneCapabilitiesKHR : FuncRef[(VkPhysicalDevice, VkDisplayModeKHR, UInt32, VkDisplayPlaneCapabilitiesKHR) -> Int32]
  vkCreateDisplayPlaneSurfaceKHR : FuncRef[(VkInstance, VkDisplaySurfaceCreateInfoKHR, VkAllocationCallbacks, FixedArray[VkSurfaceKHR]) -> Int32]
  vkDestroySurfaceKHR : FuncRef[(VkInstance, VkSurfaceKHR, VkAllocationCallbacks) -> Unit]
  vkGetPhysicalDeviceSurfaceSupportKHR : FuncRef[(VkPhysicalDevice, UInt32, VkSurfaceKHR, FixedArray[UInt32]) -> Int32]
  vkGetPhysicalDeviceSurfaceCapabilitiesKHR : FuncRef[(VkPhysicalDevice, VkSurfaceKHR, VkSurfaceCapabilitiesKHR) -> Int32]
  vkGetPhysicalDeviceSurfaceFormatsKHR : FuncRef[(VkPhysicalDevice, VkSurfaceKHR, FixedArray[UInt32], VkSurfaceFormatKHR) -> Int32]
  vkGetPhysicalDeviceSurfacePresentModesKHR : FuncRef[(VkPhysicalDevice, VkSurfaceKHR, FixedArray[UInt32], FixedArray[UInt32]) -> Int32]
  vkCreateViSurfaceNN : FuncRef[(VkInstance, VkViSurfaceCreateInfoNN, VkAllocationCallbacks, FixedArray[VkSurfaceKHR]) -> Int32]
  vkCreateWaylandSurfaceKHR : FuncRef[(VkInstance, VkWaylandSurfaceCreateInfoKHR, VkAllocationCallbacks, FixedArray[VkSurfaceKHR]) -> Int32]
  vkGetPhysicalDeviceWaylandPresentationSupportKHR : FuncRef[(VkPhysicalDevice, UInt32, UInt64) -> UInt32]
  vkCreateUbmSurfaceSEC : FuncRef[(VkInstance, VkUbmSurfaceCreateInfoSEC, VkAllocationCallbacks, FixedArray[VkSurfaceKHR]) -> Int32]
  vkGetPhysicalDeviceUbmPresentationSupportSEC : FuncRef[(VkPhysicalDevice, UInt32, UInt64) -> UInt32]
  vkCreateWin32SurfaceKHR : FuncRef[(VkInstance, VkWin32SurfaceCreateInfoKHR, VkAllocationCallbacks, FixedArray[VkSurfaceKHR]) -> Int32]
  vkGetPhysicalDeviceWin32PresentationSupportKHR : FuncRef[(VkPhysicalDevice, UInt32) -> UInt32]
  vkCreateXlibSurfaceKHR : FuncRef[(VkInstance, VkXlibSurfaceCreateInfoKHR, VkAllocationCallbacks, FixedArray[VkSurfaceKHR]) -> Int32]
  vkGetPhysicalDeviceXlibPresentationSupportKHR : FuncRef[(VkPhysicalDevice, UInt32, UInt64, UInt64) -> UInt32]
  vkCreateXcbSurfaceKHR : FuncRef[(VkInstance, VkXcbSurfaceCreateInfoKHR, VkAllocationCallbacks, FixedArray[VkSurfaceKHR]) -> Int32]
  vkGetPhysicalDeviceXcbPresentationSupportKHR : FuncRef[(VkPhysicalDevice, UInt32, UInt64, UInt32) -> UInt32]
  vkCreateDirectFBSurfaceEXT : FuncRef[(VkInstance, VkDirectFBSurfaceCreateInfoEXT, VkAllocationCallbacks, FixedArray[VkSurfaceKHR]) -> Int32]
  vkGetPhysicalDeviceDirectFBPresentationSupportEXT : FuncRef[(VkPhysicalDevice, UInt32, UInt64) -> UInt32]
  vkCreateImagePipeSurfaceFUCHSIA : FuncRef[(VkInstance, VkImagePipeSurfaceCreateInfoFUCHSIA, VkAllocationCallbacks, FixedArray[VkSurfaceKHR]) -> Int32]
  vkCreateStreamDescriptorSurfaceGGP : FuncRef[(VkInstance, VkStreamDescriptorSurfaceCreateInfoGGP, VkAllocationCallbacks, FixedArray[VkSurfaceKHR]) -> Int32]
  vkCreateScreenSurfaceQNX : FuncRef[(VkInstance, VkScreenSurfaceCreateInfoQNX, VkAllocationCallbacks, FixedArray[VkSurfaceKHR]) -> Int32]
  vkGetPhysicalDeviceScreenPresentationSupportQNX : FuncRef[(VkPhysicalDevice, UInt32, UInt64) -> UInt32]
  vkCreateDebugReportCallbackEXT : FuncRef[(VkInstance, VkDebugReportCallbackCreateInfoEXT, VkAllocationCallbacks, FixedArray[VkDebugReportCallbackEXT]) -> Int32]
  vkDestroyDebugReportCallbackEXT : FuncRef[(VkInstance, VkDebugReportCallbackEXT, VkAllocationCallbacks) -> Unit]
  vkDebugReportMessageEXT : FuncRef[(VkInstance, UInt32, UInt32, UInt64, UInt64, Int32, UInt64, UInt64) -> Unit]
  vkGetPhysicalDeviceExternalImageFormatPropertiesNV : FuncRef[(VkPhysicalDevice, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, VkExternalImageFormatPropertiesNV) -> Int32]
  vkGetPhysicalDeviceFeatures2 : FuncRef[(VkPhysicalDevice, VkPhysicalDeviceFeatures2) -> Unit]
  vkGetPhysicalDeviceFeatures2KHR : FuncRef[(VkPhysicalDevice, VkPhysicalDeviceFeatures2) -> Unit]
  vkGetPhysicalDeviceProperties2 : FuncRef[(VkPhysicalDevice, VkPhysicalDeviceProperties2) -> Unit]
  vkGetPhysicalDeviceProperties2KHR : FuncRef[(VkPhysicalDevice, VkPhysicalDeviceProperties2) -> Unit]
  vkGetPhysicalDeviceFormatProperties2 : FuncRef[(VkPhysicalDevice, UInt32, VkFormatProperties2) -> Unit]
  vkGetPhysicalDeviceFormatProperties2KHR : FuncRef[(VkPhysicalDevice, UInt32, VkFormatProperties2) -> Unit]
  vkGetPhysicalDeviceImageFormatProperties2 : FuncRef[(VkPhysicalDevice, VkPhysicalDeviceImageFormatInfo2, VkImageFormatProperties2) -> Int32]
  vkGetPhysicalDeviceImageFormatProperties2KHR : FuncRef[(VkPhysicalDevice, VkPhysicalDeviceImageFormatInfo2, VkImageFormatProperties2) -> Int32]
  vkGetPhysicalDeviceQueueFamilyProperties2 : FuncRef[(VkPhysicalDevice, FixedArray[UInt32], VkQueueFamilyProperties2) -> Unit]
  vkGetPhysicalDeviceQueueFamilyProperties2KHR : FuncRef[(VkPhysicalDevice, FixedArray[UInt32], VkQueueFamilyProperties2) -> Unit]
  vkGetPhysicalDeviceMemoryProperties2 : FuncRef[(VkPhysicalDevice, VkPhysicalDeviceMemoryProperties2) -> Unit]
  vkGetPhysicalDeviceMemoryProperties2KHR : FuncRef[(VkPhysicalDevice, VkPhysicalDeviceMemoryProperties2) -> Unit]
  vkGetPhysicalDeviceSparseImageFormatProperties2 : FuncRef[(VkPhysicalDevice, VkPhysicalDeviceSparseImageFormatInfo2, FixedArray[UInt32], VkSparseImageFormatProperties2) -> Unit]
  vkGetPhysicalDeviceSparseImageFormatProperties2KHR : FuncRef[(VkPhysicalDevice, VkPhysicalDeviceSparseImageFormatInfo2, FixedArray[UInt32], VkSparseImageFormatProperties2) -> Unit]
  vkGetPhysicalDeviceExternalBufferProperties : FuncRef[(VkPhysicalDevice, VkPhysicalDeviceExternalBufferInfo, VkExternalBufferProperties) -> Unit]
  vkGetPhysicalDeviceExternalBufferPropertiesKHR : FuncRef[(VkPhysicalDevice, VkPhysicalDeviceExternalBufferInfo, VkExternalBufferProperties) -> Unit]
  vkGetPhysicalDeviceExternalMemorySciBufPropertiesNV : FuncRef[(VkPhysicalDevice, UInt32, UInt64, VkMemorySciBufPropertiesNV) -> Int32]
  vkGetPhysicalDeviceSciBufAttributesNV : FuncRef[(VkPhysicalDevice, UInt64) -> Int32]
  vkGetPhysicalDeviceExternalSemaphoreProperties : FuncRef[(VkPhysicalDevice, VkPhysicalDeviceExternalSemaphoreInfo, VkExternalSemaphoreProperties) -> Unit]
  vkGetPhysicalDeviceExternalSemaphorePropertiesKHR : FuncRef[(VkPhysicalDevice, VkPhysicalDeviceExternalSemaphoreInfo, VkExternalSemaphoreProperties) -> Unit]
  vkGetPhysicalDeviceExternalFenceProperties : FuncRef[(VkPhysicalDevice, VkPhysicalDeviceExternalFenceInfo, VkExternalFenceProperties) -> Unit]
  vkGetPhysicalDeviceExternalFencePropertiesKHR : FuncRef[(VkPhysicalDevice, VkPhysicalDeviceExternalFenceInfo, VkExternalFenceProperties) -> Unit]
  vkGetPhysicalDeviceSciSyncAttributesNV : FuncRef[(VkPhysicalDevice, VkSciSyncAttributesInfoNV, UInt64) -> Int32]
  vkReleaseDisplayEXT : FuncRef[(VkPhysicalDevice, VkDisplayKHR) -> Int32]
  vkAcquireXlibDisplayEXT : FuncRef[(VkPhysicalDevice, UInt64, VkDisplayKHR) -> Int32]
  vkGetRandROutputDisplayEXT : FuncRef[(VkPhysicalDevice, UInt64, UInt64, FixedArray[VkDisplayKHR]) -> Int32]
  vkAcquireWinrtDisplayNV : FuncRef[(VkPhysicalDevice, VkDisplayKHR) -> Int32]
  vkGetWinrtDisplayNV : FuncRef[(VkPhysicalDevice, UInt32, FixedArray[VkDisplayKHR]) -> Int32]
  vkGetPhysicalDeviceSurfaceCapabilities2EXT : FuncRef[(VkPhysicalDevice, VkSurfaceKHR, VkSurfaceCapabilities2EXT) -> Int32]
  vkEnumeratePhysicalDeviceGroups : FuncRef[(VkInstance, FixedArray[UInt32], VkPhysicalDeviceGroupProperties) -> Int32]
  vkEnumeratePhysicalDeviceGroupsKHR : FuncRef[(VkInstance, FixedArray[UInt32], VkPhysicalDeviceGroupProperties) -> Int32]
  vkGetPhysicalDevicePresentRectanglesKHR : FuncRef[(VkPhysicalDevice, VkSurfaceKHR, FixedArray[UInt32], VkRect2D) -> Int32]
  vkCreateIOSSurfaceMVK : FuncRef[(VkInstance, VkIOSSurfaceCreateInfoMVK, VkAllocationCallbacks, FixedArray[VkSurfaceKHR]) -> Int32]
  vkCreateMacOSSurfaceMVK : FuncRef[(VkInstance, VkMacOSSurfaceCreateInfoMVK, VkAllocationCallbacks, FixedArray[VkSurfaceKHR]) -> Int32]
  vkCreateMetalSurfaceEXT : FuncRef[(VkInstance, VkMetalSurfaceCreateInfoEXT, VkAllocationCallbacks, FixedArray[VkSurfaceKHR]) -> Int32]
  vkGetPhysicalDeviceMultisamplePropertiesEXT : FuncRef[(VkPhysicalDevice, UInt32, VkMultisamplePropertiesEXT) -> Unit]
  vkGetPhysicalDeviceSurfaceCapabilities2KHR : FuncRef[(VkPhysicalDevice, VkPhysicalDeviceSurfaceInfo2KHR, VkSurfaceCapabilities2KHR) -> Int32]
  vkGetPhysicalDeviceSurfaceFormats2KHR : FuncRef[(VkPhysicalDevice, VkPhysicalDeviceSurfaceInfo2KHR, FixedArray[UInt32], VkSurfaceFormat2KHR) -> Int32]
  vkGetPhysicalDeviceDisplayProperties2KHR : FuncRef[(VkPhysicalDevice, FixedArray[UInt32], VkDisplayProperties2KHR) -> Int32]
  vkGetPhysicalDeviceDisplayPlaneProperties2KHR : FuncRef[(VkPhysicalDevice, FixedArray[UInt32], VkDisplayPlaneProperties2KHR) -> Int32]
  vkGetDisplayModeProperties2KHR : FuncRef[(VkPhysicalDevice, VkDisplayKHR, FixedArray[UInt32], VkDisplayModeProperties2KHR) -> Int32]
  vkGetDisplayPlaneCapabilities2KHR : FuncRef[(VkPhysicalDevice, VkDisplayPlaneInfo2KHR, VkDisplayPlaneCapabilities2KHR) -> Int32]
  vkGetPhysicalDeviceCalibrateableTimeDomainsKHR : FuncRef[(VkPhysicalDevice, FixedArray[UInt32], FixedArray[UInt32]) -> Int32]
  vkGetPhysicalDeviceCalibrateableTimeDomainsEXT : FuncRef[(VkPhysicalDevice, FixedArray[UInt32], FixedArray[UInt32]) -> Int32]
  vkCreateDebugUtilsMessengerEXT : FuncRef[(VkInstance, VkDebugUtilsMessengerCreateInfoEXT, VkAllocationCallbacks, FixedArray[VkDebugUtilsMessengerEXT]) -> Int32]
  vkDestroyDebugUtilsMessengerEXT : FuncRef[(VkInstance, VkDebugUtilsMessengerEXT, VkAllocationCallbacks) -> Unit]
  vkSubmitDebugUtilsMessageEXT : FuncRef[(VkInstance, UInt32, UInt32, VkDebugUtilsMessengerCallbackDataEXT) -> Unit]
  vkGetPhysicalDeviceCooperativeMatrixPropertiesNV : FuncRef[(VkPhysicalDevice, FixedArray[UInt32], VkCooperativeMatrixPropertiesNV) -> Int32]
  vkGetPhysicalDeviceSurfacePresentModes2EXT : FuncRef[(VkPhysicalDevice, VkPhysicalDeviceSurfaceInfo2KHR, FixedArray[UInt32], FixedArray[UInt32]) -> Int32]
  vkEnumeratePhysicalDeviceQueueFamilyPerformanceQueryCountersKHR : FuncRef[(VkPhysicalDevice, UInt32, FixedArray[UInt32], VkPerformanceCounterKHR, VkPerformanceCounterDescriptionKHR) -> Int32]
  vkGetPhysicalDeviceQueueFamilyPerformanceQueryPassesKHR : FuncRef[(VkPhysicalDevice, VkQueryPoolPerformanceCreateInfoKHR, FixedArray[UInt32]) -> Unit]
  vkCreateHeadlessSurfaceEXT : FuncRef[(VkInstance, VkHeadlessSurfaceCreateInfoEXT, VkAllocationCallbacks, FixedArray[VkSurfaceKHR]) -> Int32]
  vkGetPhysicalDeviceSupportedFramebufferMixedSamplesCombinationsNV : FuncRef[(VkPhysicalDevice, FixedArray[UInt32], VkFramebufferMixedSamplesCombinationNV) -> Int32]
  vkGetPhysicalDeviceToolProperties : FuncRef[(VkPhysicalDevice, FixedArray[UInt32], VkPhysicalDeviceToolProperties) -> Int32]
  vkGetPhysicalDeviceToolPropertiesEXT : FuncRef[(VkPhysicalDevice, FixedArray[UInt32], VkPhysicalDeviceToolProperties) -> Int32]
  vkGetPhysicalDeviceRefreshableObjectTypesKHR : FuncRef[(VkPhysicalDevice, FixedArray[UInt32], FixedArray[UInt32]) -> Int32]
  vkGetPhysicalDeviceFragmentShadingRatesKHR : FuncRef[(VkPhysicalDevice, FixedArray[UInt32], VkPhysicalDeviceFragmentShadingRateKHR) -> Int32]
  vkGetPhysicalDeviceVideoCapabilitiesKHR : FuncRef[(VkPhysicalDevice, VkVideoProfileInfoKHR, VkVideoCapabilitiesKHR) -> Int32]
  vkGetPhysicalDeviceVideoFormatPropertiesKHR : FuncRef[(VkPhysicalDevice, VkPhysicalDeviceVideoFormatInfoKHR, FixedArray[UInt32], VkVideoFormatPropertiesKHR) -> Int32]
  vkGetPhysicalDeviceVideoEncodeQualityLevelPropertiesKHR : FuncRef[(VkPhysicalDevice, VkPhysicalDeviceVideoEncodeQualityLevelInfoKHR, VkVideoEncodeQualityLevelPropertiesKHR) -> Int32]
  vkAcquireDrmDisplayEXT : FuncRef[(VkPhysicalDevice, Int32, VkDisplayKHR) -> Int32]
  vkGetDrmDisplayEXT : FuncRef[(VkPhysicalDevice, Int32, UInt32, FixedArray[VkDisplayKHR]) -> Int32]
  vkGetPhysicalDeviceOpticalFlowImageFormatsNV : FuncRef[(VkPhysicalDevice, VkOpticalFlowImageFormatInfoNV, FixedArray[UInt32], VkOpticalFlowImageFormatPropertiesNV) -> Int32]
  vkGetPhysicalDeviceCooperativeMatrixPropertiesKHR : FuncRef[(VkPhysicalDevice, FixedArray[UInt32], VkCooperativeMatrixPropertiesKHR) -> Int32]
  vkGetPhysicalDeviceCooperativeMatrixProperties2EXT : FuncRef[(VkPhysicalDevice, VkPhysicalDeviceCooperativeMatrixInfo2EXT, FixedArray[UInt32], VkCooperativeMatrixProperties2EXT) -> Int32]
  vkGetPhysicalDeviceCooperativeMatrixFlexibleDimensionsPropertiesNV : FuncRef[(VkPhysicalDevice, FixedArray[UInt32], VkCooperativeMatrixFlexibleDimensionsPropertiesNV) -> Int32]
  vkGetPhysicalDeviceCooperativeVectorPropertiesNV : FuncRef[(VkPhysicalDevice, FixedArray[UInt32], VkCooperativeVectorPropertiesNV) -> Int32]
  vkEnumeratePhysicalDeviceShaderInstrumentationMetricsARM : FuncRef[(VkPhysicalDevice, FixedArray[UInt32], VkShaderInstrumentationMetricDescriptionARM) -> Int32]
  vkGetPhysicalDeviceExternalTensorPropertiesARM : FuncRef[(VkPhysicalDevice, VkPhysicalDeviceExternalTensorInfoARM, VkExternalTensorPropertiesARM) -> Unit]
  vkGetPhysicalDeviceQueueFamilyDataGraphPropertiesARM : FuncRef[(VkPhysicalDevice, UInt32, FixedArray[UInt32], VkQueueFamilyDataGraphPropertiesARM) -> Int32]
  vkGetPhysicalDeviceQueueFamilyDataGraphProcessingEnginePropertiesARM : FuncRef[(VkPhysicalDevice, VkPhysicalDeviceQueueFamilyDataGraphProcessingEngineInfoARM, VkQueueFamilyDataGraphProcessingEnginePropertiesARM) -> Unit]
  vkEnumeratePhysicalDeviceQueueFamilyPerformanceCountersByRegionARM : FuncRef[(VkPhysicalDevice, UInt32, FixedArray[UInt32], VkPerformanceCounterARM, VkPerformanceCounterDescriptionARM) -> Int32]
  vkGetPhysicalDeviceDescriptorSizeEXT : FuncRef[(VkPhysicalDevice, UInt32) -> UInt64]
  vkGetPhysicalDeviceQueueFamilyDataGraphEngineOperationPropertiesARM : FuncRef[(VkPhysicalDevice, UInt32, VkQueueFamilyDataGraphPropertiesARM, VkBaseOutStructure) -> Int32]
  vkGetPhysicalDeviceQueueFamilyDataGraphOpticalFlowImageFormatsARM : FuncRef[(VkPhysicalDevice, UInt32, VkQueueFamilyDataGraphPropertiesARM, VkDataGraphOpticalFlowImageFormatInfoARM, FixedArray[UInt32], VkDataGraphOpticalFlowImageFormatPropertiesARM) -> Int32]
}

extern "c" fn load_vkDestroyInstance(inst : VkInstance) -> FuncRef[(VkInstance, VkAllocationCallbacks) -> Unit] = "tycho_gpa_vkDestroyInstance"
extern "c" fn load_vkEnumeratePhysicalDevices(inst : VkInstance) -> FuncRef[(VkInstance, FixedArray[UInt32], FixedArray[VkPhysicalDevice]) -> Int32] = "tycho_gpa_vkEnumeratePhysicalDevices"
extern "c" fn load_vkGetDeviceProcAddr(inst : VkInstance) -> FuncRef[(VkDevice, UInt64) -> UInt64] = "tycho_gpa_vkGetDeviceProcAddr"
extern "c" fn load_vkGetPhysicalDeviceProperties(inst : VkInstance) -> FuncRef[(VkPhysicalDevice, VkPhysicalDeviceProperties) -> Unit] = "tycho_gpa_vkGetPhysicalDeviceProperties"
extern "c" fn load_vkGetPhysicalDeviceQueueFamilyProperties(inst : VkInstance) -> FuncRef[(VkPhysicalDevice, FixedArray[UInt32], VkQueueFamilyProperties) -> Unit] = "tycho_gpa_vkGetPhysicalDeviceQueueFamilyProperties"
extern "c" fn load_vkGetPhysicalDeviceMemoryProperties(inst : VkInstance) -> FuncRef[(VkPhysicalDevice, VkPhysicalDeviceMemoryProperties) -> Unit] = "tycho_gpa_vkGetPhysicalDeviceMemoryProperties"
extern "c" fn load_vkGetPhysicalDeviceFeatures(inst : VkInstance) -> FuncRef[(VkPhysicalDevice, VkPhysicalDeviceFeatures) -> Unit] = "tycho_gpa_vkGetPhysicalDeviceFeatures"
extern "c" fn load_vkGetPhysicalDeviceFormatProperties(inst : VkInstance) -> FuncRef[(VkPhysicalDevice, UInt32, VkFormatProperties) -> Unit] = "tycho_gpa_vkGetPhysicalDeviceFormatProperties"
extern "c" fn load_vkGetPhysicalDeviceImageFormatProperties(inst : VkInstance) -> FuncRef[(VkPhysicalDevice, UInt32, UInt32, UInt32, UInt32, UInt32, VkImageFormatProperties) -> Int32] = "tycho_gpa_vkGetPhysicalDeviceImageFormatProperties"
extern "c" fn load_vkCreateDevice(inst : VkInstance) -> FuncRef[(VkPhysicalDevice, VkDeviceCreateInfo, VkAllocationCallbacks, FixedArray[VkDevice]) -> Int32] = "tycho_gpa_vkCreateDevice"
extern "c" fn load_vkEnumerateDeviceLayerProperties(inst : VkInstance) -> FuncRef[(VkPhysicalDevice, FixedArray[UInt32], VkLayerProperties) -> Int32] = "tycho_gpa_vkEnumerateDeviceLayerProperties"
extern "c" fn load_vkEnumerateDeviceExtensionProperties(inst : VkInstance) -> FuncRef[(VkPhysicalDevice, UInt64, FixedArray[UInt32], VkExtensionProperties) -> Int32] = "tycho_gpa_vkEnumerateDeviceExtensionProperties"
extern "c" fn load_vkGetPhysicalDeviceSparseImageFormatProperties(inst : VkInstance) -> FuncRef[(VkPhysicalDevice, UInt32, UInt32, UInt32, UInt32, UInt32, FixedArray[UInt32], VkSparseImageFormatProperties) -> Unit] = "tycho_gpa_vkGetPhysicalDeviceSparseImageFormatProperties"
extern "c" fn load_vkCreateAndroidSurfaceKHR(inst : VkInstance) -> FuncRef[(VkInstance, VkAndroidSurfaceCreateInfoKHR, VkAllocationCallbacks, FixedArray[VkSurfaceKHR]) -> Int32] = "tycho_gpa_vkCreateAndroidSurfaceKHR"
extern "c" fn load_vkCreateSurfaceOHOS(inst : VkInstance) -> FuncRef[(VkInstance, VkSurfaceCreateInfoOHOS, VkAllocationCallbacks, FixedArray[VkSurfaceKHR]) -> Int32] = "tycho_gpa_vkCreateSurfaceOHOS"
extern "c" fn load_vkGetPhysicalDeviceDisplayPropertiesKHR(inst : VkInstance) -> FuncRef[(VkPhysicalDevice, FixedArray[UInt32], VkDisplayPropertiesKHR) -> Int32] = "tycho_gpa_vkGetPhysicalDeviceDisplayPropertiesKHR"
extern "c" fn load_vkGetPhysicalDeviceDisplayPlanePropertiesKHR(inst : VkInstance) -> FuncRef[(VkPhysicalDevice, FixedArray[UInt32], VkDisplayPlanePropertiesKHR) -> Int32] = "tycho_gpa_vkGetPhysicalDeviceDisplayPlanePropertiesKHR"
extern "c" fn load_vkGetDisplayPlaneSupportedDisplaysKHR(inst : VkInstance) -> FuncRef[(VkPhysicalDevice, UInt32, FixedArray[UInt32], FixedArray[VkDisplayKHR]) -> Int32] = "tycho_gpa_vkGetDisplayPlaneSupportedDisplaysKHR"
extern "c" fn load_vkGetDisplayModePropertiesKHR(inst : VkInstance) -> FuncRef[(VkPhysicalDevice, VkDisplayKHR, FixedArray[UInt32], VkDisplayModePropertiesKHR) -> Int32] = "tycho_gpa_vkGetDisplayModePropertiesKHR"
extern "c" fn load_vkCreateDisplayModeKHR(inst : VkInstance) -> FuncRef[(VkPhysicalDevice, VkDisplayKHR, VkDisplayModeCreateInfoKHR, VkAllocationCallbacks, FixedArray[VkDisplayModeKHR]) -> Int32] = "tycho_gpa_vkCreateDisplayModeKHR"
extern "c" fn load_vkGetDisplayPlaneCapabilitiesKHR(inst : VkInstance) -> FuncRef[(VkPhysicalDevice, VkDisplayModeKHR, UInt32, VkDisplayPlaneCapabilitiesKHR) -> Int32] = "tycho_gpa_vkGetDisplayPlaneCapabilitiesKHR"
extern "c" fn load_vkCreateDisplayPlaneSurfaceKHR(inst : VkInstance) -> FuncRef[(VkInstance, VkDisplaySurfaceCreateInfoKHR, VkAllocationCallbacks, FixedArray[VkSurfaceKHR]) -> Int32] = "tycho_gpa_vkCreateDisplayPlaneSurfaceKHR"
extern "c" fn load_vkDestroySurfaceKHR(inst : VkInstance) -> FuncRef[(VkInstance, VkSurfaceKHR, VkAllocationCallbacks) -> Unit] = "tycho_gpa_vkDestroySurfaceKHR"
extern "c" fn load_vkGetPhysicalDeviceSurfaceSupportKHR(inst : VkInstance) -> FuncRef[(VkPhysicalDevice, UInt32, VkSurfaceKHR, FixedArray[UInt32]) -> Int32] = "tycho_gpa_vkGetPhysicalDeviceSurfaceSupportKHR"
extern "c" fn load_vkGetPhysicalDeviceSurfaceCapabilitiesKHR(inst : VkInstance) -> FuncRef[(VkPhysicalDevice, VkSurfaceKHR, VkSurfaceCapabilitiesKHR) -> Int32] = "tycho_gpa_vkGetPhysicalDeviceSurfaceCapabilitiesKHR"
extern "c" fn load_vkGetPhysicalDeviceSurfaceFormatsKHR(inst : VkInstance) -> FuncRef[(VkPhysicalDevice, VkSurfaceKHR, FixedArray[UInt32], VkSurfaceFormatKHR) -> Int32] = "tycho_gpa_vkGetPhysicalDeviceSurfaceFormatsKHR"
extern "c" fn load_vkGetPhysicalDeviceSurfacePresentModesKHR(inst : VkInstance) -> FuncRef[(VkPhysicalDevice, VkSurfaceKHR, FixedArray[UInt32], FixedArray[UInt32]) -> Int32] = "tycho_gpa_vkGetPhysicalDeviceSurfacePresentModesKHR"
extern "c" fn load_vkCreateViSurfaceNN(inst : VkInstance) -> FuncRef[(VkInstance, VkViSurfaceCreateInfoNN, VkAllocationCallbacks, FixedArray[VkSurfaceKHR]) -> Int32] = "tycho_gpa_vkCreateViSurfaceNN"
extern "c" fn load_vkCreateWaylandSurfaceKHR(inst : VkInstance) -> FuncRef[(VkInstance, VkWaylandSurfaceCreateInfoKHR, VkAllocationCallbacks, FixedArray[VkSurfaceKHR]) -> Int32] = "tycho_gpa_vkCreateWaylandSurfaceKHR"
extern "c" fn load_vkGetPhysicalDeviceWaylandPresentationSupportKHR(inst : VkInstance) -> FuncRef[(VkPhysicalDevice, UInt32, UInt64) -> UInt32] = "tycho_gpa_vkGetPhysicalDeviceWaylandPresentationSupportKHR"
extern "c" fn load_vkCreateUbmSurfaceSEC(inst : VkInstance) -> FuncRef[(VkInstance, VkUbmSurfaceCreateInfoSEC, VkAllocationCallbacks, FixedArray[VkSurfaceKHR]) -> Int32] = "tycho_gpa_vkCreateUbmSurfaceSEC"
extern "c" fn load_vkGetPhysicalDeviceUbmPresentationSupportSEC(inst : VkInstance) -> FuncRef[(VkPhysicalDevice, UInt32, UInt64) -> UInt32] = "tycho_gpa_vkGetPhysicalDeviceUbmPresentationSupportSEC"
extern "c" fn load_vkCreateWin32SurfaceKHR(inst : VkInstance) -> FuncRef[(VkInstance, VkWin32SurfaceCreateInfoKHR, VkAllocationCallbacks, FixedArray[VkSurfaceKHR]) -> Int32] = "tycho_gpa_vkCreateWin32SurfaceKHR"
extern "c" fn load_vkGetPhysicalDeviceWin32PresentationSupportKHR(inst : VkInstance) -> FuncRef[(VkPhysicalDevice, UInt32) -> UInt32] = "tycho_gpa_vkGetPhysicalDeviceWin32PresentationSupportKHR"
extern "c" fn load_vkCreateXlibSurfaceKHR(inst : VkInstance) -> FuncRef[(VkInstance, VkXlibSurfaceCreateInfoKHR, VkAllocationCallbacks, FixedArray[VkSurfaceKHR]) -> Int32] = "tycho_gpa_vkCreateXlibSurfaceKHR"
extern "c" fn load_vkGetPhysicalDeviceXlibPresentationSupportKHR(inst : VkInstance) -> FuncRef[(VkPhysicalDevice, UInt32, UInt64, UInt64) -> UInt32] = "tycho_gpa_vkGetPhysicalDeviceXlibPresentationSupportKHR"
extern "c" fn load_vkCreateXcbSurfaceKHR(inst : VkInstance) -> FuncRef[(VkInstance, VkXcbSurfaceCreateInfoKHR, VkAllocationCallbacks, FixedArray[VkSurfaceKHR]) -> Int32] = "tycho_gpa_vkCreateXcbSurfaceKHR"
extern "c" fn load_vkGetPhysicalDeviceXcbPresentationSupportKHR(inst : VkInstance) -> FuncRef[(VkPhysicalDevice, UInt32, UInt64, UInt32) -> UInt32] = "tycho_gpa_vkGetPhysicalDeviceXcbPresentationSupportKHR"
extern "c" fn load_vkCreateDirectFBSurfaceEXT(inst : VkInstance) -> FuncRef[(VkInstance, VkDirectFBSurfaceCreateInfoEXT, VkAllocationCallbacks, FixedArray[VkSurfaceKHR]) -> Int32] = "tycho_gpa_vkCreateDirectFBSurfaceEXT"
extern "c" fn load_vkGetPhysicalDeviceDirectFBPresentationSupportEXT(inst : VkInstance) -> FuncRef[(VkPhysicalDevice, UInt32, UInt64) -> UInt32] = "tycho_gpa_vkGetPhysicalDeviceDirectFBPresentationSupportEXT"
extern "c" fn load_vkCreateImagePipeSurfaceFUCHSIA(inst : VkInstance) -> FuncRef[(VkInstance, VkImagePipeSurfaceCreateInfoFUCHSIA, VkAllocationCallbacks, FixedArray[VkSurfaceKHR]) -> Int32] = "tycho_gpa_vkCreateImagePipeSurfaceFUCHSIA"
extern "c" fn load_vkCreateStreamDescriptorSurfaceGGP(inst : VkInstance) -> FuncRef[(VkInstance, VkStreamDescriptorSurfaceCreateInfoGGP, VkAllocationCallbacks, FixedArray[VkSurfaceKHR]) -> Int32] = "tycho_gpa_vkCreateStreamDescriptorSurfaceGGP"
extern "c" fn load_vkCreateScreenSurfaceQNX(inst : VkInstance) -> FuncRef[(VkInstance, VkScreenSurfaceCreateInfoQNX, VkAllocationCallbacks, FixedArray[VkSurfaceKHR]) -> Int32] = "tycho_gpa_vkCreateScreenSurfaceQNX"
extern "c" fn load_vkGetPhysicalDeviceScreenPresentationSupportQNX(inst : VkInstance) -> FuncRef[(VkPhysicalDevice, UInt32, UInt64) -> UInt32] = "tycho_gpa_vkGetPhysicalDeviceScreenPresentationSupportQNX"
extern "c" fn load_vkCreateDebugReportCallbackEXT(inst : VkInstance) -> FuncRef[(VkInstance, VkDebugReportCallbackCreateInfoEXT, VkAllocationCallbacks, FixedArray[VkDebugReportCallbackEXT]) -> Int32] = "tycho_gpa_vkCreateDebugReportCallbackEXT"
extern "c" fn load_vkDestroyDebugReportCallbackEXT(inst : VkInstance) -> FuncRef[(VkInstance, VkDebugReportCallbackEXT, VkAllocationCallbacks) -> Unit] = "tycho_gpa_vkDestroyDebugReportCallbackEXT"
extern "c" fn load_vkDebugReportMessageEXT(inst : VkInstance) -> FuncRef[(VkInstance, UInt32, UInt32, UInt64, UInt64, Int32, UInt64, UInt64) -> Unit] = "tycho_gpa_vkDebugReportMessageEXT"
extern "c" fn load_vkGetPhysicalDeviceExternalImageFormatPropertiesNV(inst : VkInstance) -> FuncRef[(VkPhysicalDevice, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, VkExternalImageFormatPropertiesNV) -> Int32] = "tycho_gpa_vkGetPhysicalDeviceExternalImageFormatPropertiesNV"
extern "c" fn load_vkGetPhysicalDeviceFeatures2(inst : VkInstance) -> FuncRef[(VkPhysicalDevice, VkPhysicalDeviceFeatures2) -> Unit] = "tycho_gpa_vkGetPhysicalDeviceFeatures2"
extern "c" fn load_vkGetPhysicalDeviceFeatures2KHR(inst : VkInstance) -> FuncRef[(VkPhysicalDevice, VkPhysicalDeviceFeatures2) -> Unit] = "tycho_gpa_vkGetPhysicalDeviceFeatures2KHR"
extern "c" fn load_vkGetPhysicalDeviceProperties2(inst : VkInstance) -> FuncRef[(VkPhysicalDevice, VkPhysicalDeviceProperties2) -> Unit] = "tycho_gpa_vkGetPhysicalDeviceProperties2"
extern "c" fn load_vkGetPhysicalDeviceProperties2KHR(inst : VkInstance) -> FuncRef[(VkPhysicalDevice, VkPhysicalDeviceProperties2) -> Unit] = "tycho_gpa_vkGetPhysicalDeviceProperties2KHR"
extern "c" fn load_vkGetPhysicalDeviceFormatProperties2(inst : VkInstance) -> FuncRef[(VkPhysicalDevice, UInt32, VkFormatProperties2) -> Unit] = "tycho_gpa_vkGetPhysicalDeviceFormatProperties2"
extern "c" fn load_vkGetPhysicalDeviceFormatProperties2KHR(inst : VkInstance) -> FuncRef[(VkPhysicalDevice, UInt32, VkFormatProperties2) -> Unit] = "tycho_gpa_vkGetPhysicalDeviceFormatProperties2KHR"
extern "c" fn load_vkGetPhysicalDeviceImageFormatProperties2(inst : VkInstance) -> FuncRef[(VkPhysicalDevice, VkPhysicalDeviceImageFormatInfo2, VkImageFormatProperties2) -> Int32] = "tycho_gpa_vkGetPhysicalDeviceImageFormatProperties2"
extern "c" fn load_vkGetPhysicalDeviceImageFormatProperties2KHR(inst : VkInstance) -> FuncRef[(VkPhysicalDevice, VkPhysicalDeviceImageFormatInfo2, VkImageFormatProperties2) -> Int32] = "tycho_gpa_vkGetPhysicalDeviceImageFormatProperties2KHR"
extern "c" fn load_vkGetPhysicalDeviceQueueFamilyProperties2(inst : VkInstance) -> FuncRef[(VkPhysicalDevice, FixedArray[UInt32], VkQueueFamilyProperties2) -> Unit] = "tycho_gpa_vkGetPhysicalDeviceQueueFamilyProperties2"
extern "c" fn load_vkGetPhysicalDeviceQueueFamilyProperties2KHR(inst : VkInstance) -> FuncRef[(VkPhysicalDevice, FixedArray[UInt32], VkQueueFamilyProperties2) -> Unit] = "tycho_gpa_vkGetPhysicalDeviceQueueFamilyProperties2KHR"
extern "c" fn load_vkGetPhysicalDeviceMemoryProperties2(inst : VkInstance) -> FuncRef[(VkPhysicalDevice, VkPhysicalDeviceMemoryProperties2) -> Unit] = "tycho_gpa_vkGetPhysicalDeviceMemoryProperties2"
extern "c" fn load_vkGetPhysicalDeviceMemoryProperties2KHR(inst : VkInstance) -> FuncRef[(VkPhysicalDevice, VkPhysicalDeviceMemoryProperties2) -> Unit] = "tycho_gpa_vkGetPhysicalDeviceMemoryProperties2KHR"
extern "c" fn load_vkGetPhysicalDeviceSparseImageFormatProperties2(inst : VkInstance) -> FuncRef[(VkPhysicalDevice, VkPhysicalDeviceSparseImageFormatInfo2, FixedArray[UInt32], VkSparseImageFormatProperties2) -> Unit] = "tycho_gpa_vkGetPhysicalDeviceSparseImageFormatProperties2"
extern "c" fn load_vkGetPhysicalDeviceSparseImageFormatProperties2KHR(inst : VkInstance) -> FuncRef[(VkPhysicalDevice, VkPhysicalDeviceSparseImageFormatInfo2, FixedArray[UInt32], VkSparseImageFormatProperties2) -> Unit] = "tycho_gpa_vkGetPhysicalDeviceSparseImageFormatProperties2KHR"
extern "c" fn load_vkGetPhysicalDeviceExternalBufferProperties(inst : VkInstance) -> FuncRef[(VkPhysicalDevice, VkPhysicalDeviceExternalBufferInfo, VkExternalBufferProperties) -> Unit] = "tycho_gpa_vkGetPhysicalDeviceExternalBufferProperties"
extern "c" fn load_vkGetPhysicalDeviceExternalBufferPropertiesKHR(inst : VkInstance) -> FuncRef[(VkPhysicalDevice, VkPhysicalDeviceExternalBufferInfo, VkExternalBufferProperties) -> Unit] = "tycho_gpa_vkGetPhysicalDeviceExternalBufferPropertiesKHR"
extern "c" fn load_vkGetPhysicalDeviceExternalMemorySciBufPropertiesNV(inst : VkInstance) -> FuncRef[(VkPhysicalDevice, UInt32, UInt64, VkMemorySciBufPropertiesNV) -> Int32] = "tycho_gpa_vkGetPhysicalDeviceExternalMemorySciBufPropertiesNV"
extern "c" fn load_vkGetPhysicalDeviceSciBufAttributesNV(inst : VkInstance) -> FuncRef[(VkPhysicalDevice, UInt64) -> Int32] = "tycho_gpa_vkGetPhysicalDeviceSciBufAttributesNV"
extern "c" fn load_vkGetPhysicalDeviceExternalSemaphoreProperties(inst : VkInstance) -> FuncRef[(VkPhysicalDevice, VkPhysicalDeviceExternalSemaphoreInfo, VkExternalSemaphoreProperties) -> Unit] = "tycho_gpa_vkGetPhysicalDeviceExternalSemaphoreProperties"
extern "c" fn load_vkGetPhysicalDeviceExternalSemaphorePropertiesKHR(inst : VkInstance) -> FuncRef[(VkPhysicalDevice, VkPhysicalDeviceExternalSemaphoreInfo, VkExternalSemaphoreProperties) -> Unit] = "tycho_gpa_vkGetPhysicalDeviceExternalSemaphorePropertiesKHR"
extern "c" fn load_vkGetPhysicalDeviceExternalFenceProperties(inst : VkInstance) -> FuncRef[(VkPhysicalDevice, VkPhysicalDeviceExternalFenceInfo, VkExternalFenceProperties) -> Unit] = "tycho_gpa_vkGetPhysicalDeviceExternalFenceProperties"
extern "c" fn load_vkGetPhysicalDeviceExternalFencePropertiesKHR(inst : VkInstance) -> FuncRef[(VkPhysicalDevice, VkPhysicalDeviceExternalFenceInfo, VkExternalFenceProperties) -> Unit] = "tycho_gpa_vkGetPhysicalDeviceExternalFencePropertiesKHR"
extern "c" fn load_vkGetPhysicalDeviceSciSyncAttributesNV(inst : VkInstance) -> FuncRef[(VkPhysicalDevice, VkSciSyncAttributesInfoNV, UInt64) -> Int32] = "tycho_gpa_vkGetPhysicalDeviceSciSyncAttributesNV"
extern "c" fn load_vkReleaseDisplayEXT(inst : VkInstance) -> FuncRef[(VkPhysicalDevice, VkDisplayKHR) -> Int32] = "tycho_gpa_vkReleaseDisplayEXT"
extern "c" fn load_vkAcquireXlibDisplayEXT(inst : VkInstance) -> FuncRef[(VkPhysicalDevice, UInt64, VkDisplayKHR) -> Int32] = "tycho_gpa_vkAcquireXlibDisplayEXT"
extern "c" fn load_vkGetRandROutputDisplayEXT(inst : VkInstance) -> FuncRef[(VkPhysicalDevice, UInt64, UInt64, FixedArray[VkDisplayKHR]) -> Int32] = "tycho_gpa_vkGetRandROutputDisplayEXT"
extern "c" fn load_vkAcquireWinrtDisplayNV(inst : VkInstance) -> FuncRef[(VkPhysicalDevice, VkDisplayKHR) -> Int32] = "tycho_gpa_vkAcquireWinrtDisplayNV"
extern "c" fn load_vkGetWinrtDisplayNV(inst : VkInstance) -> FuncRef[(VkPhysicalDevice, UInt32, FixedArray[VkDisplayKHR]) -> Int32] = "tycho_gpa_vkGetWinrtDisplayNV"
extern "c" fn load_vkGetPhysicalDeviceSurfaceCapabilities2EXT(inst : VkInstance) -> FuncRef[(VkPhysicalDevice, VkSurfaceKHR, VkSurfaceCapabilities2EXT) -> Int32] = "tycho_gpa_vkGetPhysicalDeviceSurfaceCapabilities2EXT"
extern "c" fn load_vkEnumeratePhysicalDeviceGroups(inst : VkInstance) -> FuncRef[(VkInstance, FixedArray[UInt32], VkPhysicalDeviceGroupProperties) -> Int32] = "tycho_gpa_vkEnumeratePhysicalDeviceGroups"
extern "c" fn load_vkEnumeratePhysicalDeviceGroupsKHR(inst : VkInstance) -> FuncRef[(VkInstance, FixedArray[UInt32], VkPhysicalDeviceGroupProperties) -> Int32] = "tycho_gpa_vkEnumeratePhysicalDeviceGroupsKHR"
extern "c" fn load_vkGetPhysicalDevicePresentRectanglesKHR(inst : VkInstance) -> FuncRef[(VkPhysicalDevice, VkSurfaceKHR, FixedArray[UInt32], VkRect2D) -> Int32] = "tycho_gpa_vkGetPhysicalDevicePresentRectanglesKHR"
extern "c" fn load_vkCreateIOSSurfaceMVK(inst : VkInstance) -> FuncRef[(VkInstance, VkIOSSurfaceCreateInfoMVK, VkAllocationCallbacks, FixedArray[VkSurfaceKHR]) -> Int32] = "tycho_gpa_vkCreateIOSSurfaceMVK"
extern "c" fn load_vkCreateMacOSSurfaceMVK(inst : VkInstance) -> FuncRef[(VkInstance, VkMacOSSurfaceCreateInfoMVK, VkAllocationCallbacks, FixedArray[VkSurfaceKHR]) -> Int32] = "tycho_gpa_vkCreateMacOSSurfaceMVK"
extern "c" fn load_vkCreateMetalSurfaceEXT(inst : VkInstance) -> FuncRef[(VkInstance, VkMetalSurfaceCreateInfoEXT, VkAllocationCallbacks, FixedArray[VkSurfaceKHR]) -> Int32] = "tycho_gpa_vkCreateMetalSurfaceEXT"
extern "c" fn load_vkGetPhysicalDeviceMultisamplePropertiesEXT(inst : VkInstance) -> FuncRef[(VkPhysicalDevice, UInt32, VkMultisamplePropertiesEXT) -> Unit] = "tycho_gpa_vkGetPhysicalDeviceMultisamplePropertiesEXT"
extern "c" fn load_vkGetPhysicalDeviceSurfaceCapabilities2KHR(inst : VkInstance) -> FuncRef[(VkPhysicalDevice, VkPhysicalDeviceSurfaceInfo2KHR, VkSurfaceCapabilities2KHR) -> Int32] = "tycho_gpa_vkGetPhysicalDeviceSurfaceCapabilities2KHR"
extern "c" fn load_vkGetPhysicalDeviceSurfaceFormats2KHR(inst : VkInstance) -> FuncRef[(VkPhysicalDevice, VkPhysicalDeviceSurfaceInfo2KHR, FixedArray[UInt32], VkSurfaceFormat2KHR) -> Int32] = "tycho_gpa_vkGetPhysicalDeviceSurfaceFormats2KHR"
extern "c" fn load_vkGetPhysicalDeviceDisplayProperties2KHR(inst : VkInstance) -> FuncRef[(VkPhysicalDevice, FixedArray[UInt32], VkDisplayProperties2KHR) -> Int32] = "tycho_gpa_vkGetPhysicalDeviceDisplayProperties2KHR"
extern "c" fn load_vkGetPhysicalDeviceDisplayPlaneProperties2KHR(inst : VkInstance) -> FuncRef[(VkPhysicalDevice, FixedArray[UInt32], VkDisplayPlaneProperties2KHR) -> Int32] = "tycho_gpa_vkGetPhysicalDeviceDisplayPlaneProperties2KHR"
extern "c" fn load_vkGetDisplayModeProperties2KHR(inst : VkInstance) -> FuncRef[(VkPhysicalDevice, VkDisplayKHR, FixedArray[UInt32], VkDisplayModeProperties2KHR) -> Int32] = "tycho_gpa_vkGetDisplayModeProperties2KHR"
extern "c" fn load_vkGetDisplayPlaneCapabilities2KHR(inst : VkInstance) -> FuncRef[(VkPhysicalDevice, VkDisplayPlaneInfo2KHR, VkDisplayPlaneCapabilities2KHR) -> Int32] = "tycho_gpa_vkGetDisplayPlaneCapabilities2KHR"
extern "c" fn load_vkGetPhysicalDeviceCalibrateableTimeDomainsKHR(inst : VkInstance) -> FuncRef[(VkPhysicalDevice, FixedArray[UInt32], FixedArray[UInt32]) -> Int32] = "tycho_gpa_vkGetPhysicalDeviceCalibrateableTimeDomainsKHR"
extern "c" fn load_vkGetPhysicalDeviceCalibrateableTimeDomainsEXT(inst : VkInstance) -> FuncRef[(VkPhysicalDevice, FixedArray[UInt32], FixedArray[UInt32]) -> Int32] = "tycho_gpa_vkGetPhysicalDeviceCalibrateableTimeDomainsEXT"
extern "c" fn load_vkCreateDebugUtilsMessengerEXT(inst : VkInstance) -> FuncRef[(VkInstance, VkDebugUtilsMessengerCreateInfoEXT, VkAllocationCallbacks, FixedArray[VkDebugUtilsMessengerEXT]) -> Int32] = "tycho_gpa_vkCreateDebugUtilsMessengerEXT"
extern "c" fn load_vkDestroyDebugUtilsMessengerEXT(inst : VkInstance) -> FuncRef[(VkInstance, VkDebugUtilsMessengerEXT, VkAllocationCallbacks) -> Unit] = "tycho_gpa_vkDestroyDebugUtilsMessengerEXT"
extern "c" fn load_vkSubmitDebugUtilsMessageEXT(inst : VkInstance) -> FuncRef[(VkInstance, UInt32, UInt32, VkDebugUtilsMessengerCallbackDataEXT) -> Unit] = "tycho_gpa_vkSubmitDebugUtilsMessageEXT"
extern "c" fn load_vkGetPhysicalDeviceCooperativeMatrixPropertiesNV(inst : VkInstance) -> FuncRef[(VkPhysicalDevice, FixedArray[UInt32], VkCooperativeMatrixPropertiesNV) -> Int32] = "tycho_gpa_vkGetPhysicalDeviceCooperativeMatrixPropertiesNV"
extern "c" fn load_vkGetPhysicalDeviceSurfacePresentModes2EXT(inst : VkInstance) -> FuncRef[(VkPhysicalDevice, VkPhysicalDeviceSurfaceInfo2KHR, FixedArray[UInt32], FixedArray[UInt32]) -> Int32] = "tycho_gpa_vkGetPhysicalDeviceSurfacePresentModes2EXT"
extern "c" fn load_vkEnumeratePhysicalDeviceQueueFamilyPerformanceQueryCountersKHR(inst : VkInstance) -> FuncRef[(VkPhysicalDevice, UInt32, FixedArray[UInt32], VkPerformanceCounterKHR, VkPerformanceCounterDescriptionKHR) -> Int32] = "tycho_gpa_vkEnumeratePhysicalDeviceQueueFamilyPerformanceQueryCountersKHR"
extern "c" fn load_vkGetPhysicalDeviceQueueFamilyPerformanceQueryPassesKHR(inst : VkInstance) -> FuncRef[(VkPhysicalDevice, VkQueryPoolPerformanceCreateInfoKHR, FixedArray[UInt32]) -> Unit] = "tycho_gpa_vkGetPhysicalDeviceQueueFamilyPerformanceQueryPassesKHR"
extern "c" fn load_vkCreateHeadlessSurfaceEXT(inst : VkInstance) -> FuncRef[(VkInstance, VkHeadlessSurfaceCreateInfoEXT, VkAllocationCallbacks, FixedArray[VkSurfaceKHR]) -> Int32] = "tycho_gpa_vkCreateHeadlessSurfaceEXT"
extern "c" fn load_vkGetPhysicalDeviceSupportedFramebufferMixedSamplesCombinationsNV(inst : VkInstance) -> FuncRef[(VkPhysicalDevice, FixedArray[UInt32], VkFramebufferMixedSamplesCombinationNV) -> Int32] = "tycho_gpa_vkGetPhysicalDeviceSupportedFramebufferMixedSamplesCombinationsNV"
extern "c" fn load_vkGetPhysicalDeviceToolProperties(inst : VkInstance) -> FuncRef[(VkPhysicalDevice, FixedArray[UInt32], VkPhysicalDeviceToolProperties) -> Int32] = "tycho_gpa_vkGetPhysicalDeviceToolProperties"
extern "c" fn load_vkGetPhysicalDeviceToolPropertiesEXT(inst : VkInstance) -> FuncRef[(VkPhysicalDevice, FixedArray[UInt32], VkPhysicalDeviceToolProperties) -> Int32] = "tycho_gpa_vkGetPhysicalDeviceToolPropertiesEXT"
extern "c" fn load_vkGetPhysicalDeviceRefreshableObjectTypesKHR(inst : VkInstance) -> FuncRef[(VkPhysicalDevice, FixedArray[UInt32], FixedArray[UInt32]) -> Int32] = "tycho_gpa_vkGetPhysicalDeviceRefreshableObjectTypesKHR"
extern "c" fn load_vkGetPhysicalDeviceFragmentShadingRatesKHR(inst : VkInstance) -> FuncRef[(VkPhysicalDevice, FixedArray[UInt32], VkPhysicalDeviceFragmentShadingRateKHR) -> Int32] = "tycho_gpa_vkGetPhysicalDeviceFragmentShadingRatesKHR"
extern "c" fn load_vkGetPhysicalDeviceVideoCapabilitiesKHR(inst : VkInstance) -> FuncRef[(VkPhysicalDevice, VkVideoProfileInfoKHR, VkVideoCapabilitiesKHR) -> Int32] = "tycho_gpa_vkGetPhysicalDeviceVideoCapabilitiesKHR"
extern "c" fn load_vkGetPhysicalDeviceVideoFormatPropertiesKHR(inst : VkInstance) -> FuncRef[(VkPhysicalDevice, VkPhysicalDeviceVideoFormatInfoKHR, FixedArray[UInt32], VkVideoFormatPropertiesKHR) -> Int32] = "tycho_gpa_vkGetPhysicalDeviceVideoFormatPropertiesKHR"
extern "c" fn load_vkGetPhysicalDeviceVideoEncodeQualityLevelPropertiesKHR(inst : VkInstance) -> FuncRef[(VkPhysicalDevice, VkPhysicalDeviceVideoEncodeQualityLevelInfoKHR, VkVideoEncodeQualityLevelPropertiesKHR) -> Int32] = "tycho_gpa_vkGetPhysicalDeviceVideoEncodeQualityLevelPropertiesKHR"
extern "c" fn load_vkAcquireDrmDisplayEXT(inst : VkInstance) -> FuncRef[(VkPhysicalDevice, Int32, VkDisplayKHR) -> Int32] = "tycho_gpa_vkAcquireDrmDisplayEXT"
extern "c" fn load_vkGetDrmDisplayEXT(inst : VkInstance) -> FuncRef[(VkPhysicalDevice, Int32, UInt32, FixedArray[VkDisplayKHR]) -> Int32] = "tycho_gpa_vkGetDrmDisplayEXT"
extern "c" fn load_vkGetPhysicalDeviceOpticalFlowImageFormatsNV(inst : VkInstance) -> FuncRef[(VkPhysicalDevice, VkOpticalFlowImageFormatInfoNV, FixedArray[UInt32], VkOpticalFlowImageFormatPropertiesNV) -> Int32] = "tycho_gpa_vkGetPhysicalDeviceOpticalFlowImageFormatsNV"
extern "c" fn load_vkGetPhysicalDeviceCooperativeMatrixPropertiesKHR(inst : VkInstance) -> FuncRef[(VkPhysicalDevice, FixedArray[UInt32], VkCooperativeMatrixPropertiesKHR) -> Int32] = "tycho_gpa_vkGetPhysicalDeviceCooperativeMatrixPropertiesKHR"
extern "c" fn load_vkGetPhysicalDeviceCooperativeMatrixProperties2EXT(inst : VkInstance) -> FuncRef[(VkPhysicalDevice, VkPhysicalDeviceCooperativeMatrixInfo2EXT, FixedArray[UInt32], VkCooperativeMatrixProperties2EXT) -> Int32] = "tycho_gpa_vkGetPhysicalDeviceCooperativeMatrixProperties2EXT"
extern "c" fn load_vkGetPhysicalDeviceCooperativeMatrixFlexibleDimensionsPropertiesNV(inst : VkInstance) -> FuncRef[(VkPhysicalDevice, FixedArray[UInt32], VkCooperativeMatrixFlexibleDimensionsPropertiesNV) -> Int32] = "tycho_gpa_vkGetPhysicalDeviceCooperativeMatrixFlexibleDimensionsPropertiesNV"
extern "c" fn load_vkGetPhysicalDeviceCooperativeVectorPropertiesNV(inst : VkInstance) -> FuncRef[(VkPhysicalDevice, FixedArray[UInt32], VkCooperativeVectorPropertiesNV) -> Int32] = "tycho_gpa_vkGetPhysicalDeviceCooperativeVectorPropertiesNV"
extern "c" fn load_vkEnumeratePhysicalDeviceShaderInstrumentationMetricsARM(inst : VkInstance) -> FuncRef[(VkPhysicalDevice, FixedArray[UInt32], VkShaderInstrumentationMetricDescriptionARM) -> Int32] = "tycho_gpa_vkEnumeratePhysicalDeviceShaderInstrumentationMetricsARM"
extern "c" fn load_vkGetPhysicalDeviceExternalTensorPropertiesARM(inst : VkInstance) -> FuncRef[(VkPhysicalDevice, VkPhysicalDeviceExternalTensorInfoARM, VkExternalTensorPropertiesARM) -> Unit] = "tycho_gpa_vkGetPhysicalDeviceExternalTensorPropertiesARM"
extern "c" fn load_vkGetPhysicalDeviceQueueFamilyDataGraphPropertiesARM(inst : VkInstance) -> FuncRef[(VkPhysicalDevice, UInt32, FixedArray[UInt32], VkQueueFamilyDataGraphPropertiesARM) -> Int32] = "tycho_gpa_vkGetPhysicalDeviceQueueFamilyDataGraphPropertiesARM"
extern "c" fn load_vkGetPhysicalDeviceQueueFamilyDataGraphProcessingEnginePropertiesARM(inst : VkInstance) -> FuncRef[(VkPhysicalDevice, VkPhysicalDeviceQueueFamilyDataGraphProcessingEngineInfoARM, VkQueueFamilyDataGraphProcessingEnginePropertiesARM) -> Unit] = "tycho_gpa_vkGetPhysicalDeviceQueueFamilyDataGraphProcessingEnginePropertiesARM"
extern "c" fn load_vkEnumeratePhysicalDeviceQueueFamilyPerformanceCountersByRegionARM(inst : VkInstance) -> FuncRef[(VkPhysicalDevice, UInt32, FixedArray[UInt32], VkPerformanceCounterARM, VkPerformanceCounterDescriptionARM) -> Int32] = "tycho_gpa_vkEnumeratePhysicalDeviceQueueFamilyPerformanceCountersByRegionARM"
extern "c" fn load_vkGetPhysicalDeviceDescriptorSizeEXT(inst : VkInstance) -> FuncRef[(VkPhysicalDevice, UInt32) -> UInt64] = "tycho_gpa_vkGetPhysicalDeviceDescriptorSizeEXT"
extern "c" fn load_vkGetPhysicalDeviceQueueFamilyDataGraphEngineOperationPropertiesARM(inst : VkInstance) -> FuncRef[(VkPhysicalDevice, UInt32, VkQueueFamilyDataGraphPropertiesARM, VkBaseOutStructure) -> Int32] = "tycho_gpa_vkGetPhysicalDeviceQueueFamilyDataGraphEngineOperationPropertiesARM"
extern "c" fn load_vkGetPhysicalDeviceQueueFamilyDataGraphOpticalFlowImageFormatsARM(inst : VkInstance) -> FuncRef[(VkPhysicalDevice, UInt32, VkQueueFamilyDataGraphPropertiesARM, VkDataGraphOpticalFlowImageFormatInfoARM, FixedArray[UInt32], VkDataGraphOpticalFlowImageFormatPropertiesARM) -> Int32] = "tycho_gpa_vkGetPhysicalDeviceQueueFamilyDataGraphOpticalFlowImageFormatsARM"

pub fn InstanceFn::load(inst : VkInstance) -> InstanceFn {
  {
    vkDestroyInstance: load_vkDestroyInstance(inst),
    vkEnumeratePhysicalDevices: load_vkEnumeratePhysicalDevices(inst),
    vkGetDeviceProcAddr: load_vkGetDeviceProcAddr(inst),
    vkGetPhysicalDeviceProperties: load_vkGetPhysicalDeviceProperties(inst),
    vkGetPhysicalDeviceQueueFamilyProperties: load_vkGetPhysicalDeviceQueueFamilyProperties(inst),
    vkGetPhysicalDeviceMemoryProperties: load_vkGetPhysicalDeviceMemoryProperties(inst),
    vkGetPhysicalDeviceFeatures: load_vkGetPhysicalDeviceFeatures(inst),
    vkGetPhysicalDeviceFormatProperties: load_vkGetPhysicalDeviceFormatProperties(inst),
    vkGetPhysicalDeviceImageFormatProperties: load_vkGetPhysicalDeviceImageFormatProperties(inst),
    vkCreateDevice: load_vkCreateDevice(inst),
    vkEnumerateDeviceLayerProperties: load_vkEnumerateDeviceLayerProperties(inst),
    vkEnumerateDeviceExtensionProperties: load_vkEnumerateDeviceExtensionProperties(inst),
    vkGetPhysicalDeviceSparseImageFormatProperties: load_vkGetPhysicalDeviceSparseImageFormatProperties(inst),
    vkCreateAndroidSurfaceKHR: load_vkCreateAndroidSurfaceKHR(inst),
    vkCreateSurfaceOHOS: load_vkCreateSurfaceOHOS(inst),
    vkGetPhysicalDeviceDisplayPropertiesKHR: load_vkGetPhysicalDeviceDisplayPropertiesKHR(inst),
    vkGetPhysicalDeviceDisplayPlanePropertiesKHR: load_vkGetPhysicalDeviceDisplayPlanePropertiesKHR(inst),
    vkGetDisplayPlaneSupportedDisplaysKHR: load_vkGetDisplayPlaneSupportedDisplaysKHR(inst),
    vkGetDisplayModePropertiesKHR: load_vkGetDisplayModePropertiesKHR(inst),
    vkCreateDisplayModeKHR: load_vkCreateDisplayModeKHR(inst),
    vkGetDisplayPlaneCapabilitiesKHR: load_vkGetDisplayPlaneCapabilitiesKHR(inst),
    vkCreateDisplayPlaneSurfaceKHR: load_vkCreateDisplayPlaneSurfaceKHR(inst),
    vkDestroySurfaceKHR: load_vkDestroySurfaceKHR(inst),
    vkGetPhysicalDeviceSurfaceSupportKHR: load_vkGetPhysicalDeviceSurfaceSupportKHR(inst),
    vkGetPhysicalDeviceSurfaceCapabilitiesKHR: load_vkGetPhysicalDeviceSurfaceCapabilitiesKHR(inst),
    vkGetPhysicalDeviceSurfaceFormatsKHR: load_vkGetPhysicalDeviceSurfaceFormatsKHR(inst),
    vkGetPhysicalDeviceSurfacePresentModesKHR: load_vkGetPhysicalDeviceSurfacePresentModesKHR(inst),
    vkCreateViSurfaceNN: load_vkCreateViSurfaceNN(inst),
    vkCreateWaylandSurfaceKHR: load_vkCreateWaylandSurfaceKHR(inst),
    vkGetPhysicalDeviceWaylandPresentationSupportKHR: load_vkGetPhysicalDeviceWaylandPresentationSupportKHR(inst),
    vkCreateUbmSurfaceSEC: load_vkCreateUbmSurfaceSEC(inst),
    vkGetPhysicalDeviceUbmPresentationSupportSEC: load_vkGetPhysicalDeviceUbmPresentationSupportSEC(inst),
    vkCreateWin32SurfaceKHR: load_vkCreateWin32SurfaceKHR(inst),
    vkGetPhysicalDeviceWin32PresentationSupportKHR: load_vkGetPhysicalDeviceWin32PresentationSupportKHR(inst),
    vkCreateXlibSurfaceKHR: load_vkCreateXlibSurfaceKHR(inst),
    vkGetPhysicalDeviceXlibPresentationSupportKHR: load_vkGetPhysicalDeviceXlibPresentationSupportKHR(inst),
    vkCreateXcbSurfaceKHR: load_vkCreateXcbSurfaceKHR(inst),
    vkGetPhysicalDeviceXcbPresentationSupportKHR: load_vkGetPhysicalDeviceXcbPresentationSupportKHR(inst),
    vkCreateDirectFBSurfaceEXT: load_vkCreateDirectFBSurfaceEXT(inst),
    vkGetPhysicalDeviceDirectFBPresentationSupportEXT: load_vkGetPhysicalDeviceDirectFBPresentationSupportEXT(inst),
    vkCreateImagePipeSurfaceFUCHSIA: load_vkCreateImagePipeSurfaceFUCHSIA(inst),
    vkCreateStreamDescriptorSurfaceGGP: load_vkCreateStreamDescriptorSurfaceGGP(inst),
    vkCreateScreenSurfaceQNX: load_vkCreateScreenSurfaceQNX(inst),
    vkGetPhysicalDeviceScreenPresentationSupportQNX: load_vkGetPhysicalDeviceScreenPresentationSupportQNX(inst),
    vkCreateDebugReportCallbackEXT: load_vkCreateDebugReportCallbackEXT(inst),
    vkDestroyDebugReportCallbackEXT: load_vkDestroyDebugReportCallbackEXT(inst),
    vkDebugReportMessageEXT: load_vkDebugReportMessageEXT(inst),
    vkGetPhysicalDeviceExternalImageFormatPropertiesNV: load_vkGetPhysicalDeviceExternalImageFormatPropertiesNV(inst),
    vkGetPhysicalDeviceFeatures2: load_vkGetPhysicalDeviceFeatures2(inst),
    vkGetPhysicalDeviceFeatures2KHR: load_vkGetPhysicalDeviceFeatures2KHR(inst),
    vkGetPhysicalDeviceProperties2: load_vkGetPhysicalDeviceProperties2(inst),
    vkGetPhysicalDeviceProperties2KHR: load_vkGetPhysicalDeviceProperties2KHR(inst),
    vkGetPhysicalDeviceFormatProperties2: load_vkGetPhysicalDeviceFormatProperties2(inst),
    vkGetPhysicalDeviceFormatProperties2KHR: load_vkGetPhysicalDeviceFormatProperties2KHR(inst),
    vkGetPhysicalDeviceImageFormatProperties2: load_vkGetPhysicalDeviceImageFormatProperties2(inst),
    vkGetPhysicalDeviceImageFormatProperties2KHR: load_vkGetPhysicalDeviceImageFormatProperties2KHR(inst),
    vkGetPhysicalDeviceQueueFamilyProperties2: load_vkGetPhysicalDeviceQueueFamilyProperties2(inst),
    vkGetPhysicalDeviceQueueFamilyProperties2KHR: load_vkGetPhysicalDeviceQueueFamilyProperties2KHR(inst),
    vkGetPhysicalDeviceMemoryProperties2: load_vkGetPhysicalDeviceMemoryProperties2(inst),
    vkGetPhysicalDeviceMemoryProperties2KHR: load_vkGetPhysicalDeviceMemoryProperties2KHR(inst),
    vkGetPhysicalDeviceSparseImageFormatProperties2: load_vkGetPhysicalDeviceSparseImageFormatProperties2(inst),
    vkGetPhysicalDeviceSparseImageFormatProperties2KHR: load_vkGetPhysicalDeviceSparseImageFormatProperties2KHR(inst),
    vkGetPhysicalDeviceExternalBufferProperties: load_vkGetPhysicalDeviceExternalBufferProperties(inst),
    vkGetPhysicalDeviceExternalBufferPropertiesKHR: load_vkGetPhysicalDeviceExternalBufferPropertiesKHR(inst),
    vkGetPhysicalDeviceExternalMemorySciBufPropertiesNV: load_vkGetPhysicalDeviceExternalMemorySciBufPropertiesNV(inst),
    vkGetPhysicalDeviceSciBufAttributesNV: load_vkGetPhysicalDeviceSciBufAttributesNV(inst),
    vkGetPhysicalDeviceExternalSemaphoreProperties: load_vkGetPhysicalDeviceExternalSemaphoreProperties(inst),
    vkGetPhysicalDeviceExternalSemaphorePropertiesKHR: load_vkGetPhysicalDeviceExternalSemaphorePropertiesKHR(inst),
    vkGetPhysicalDeviceExternalFenceProperties: load_vkGetPhysicalDeviceExternalFenceProperties(inst),
    vkGetPhysicalDeviceExternalFencePropertiesKHR: load_vkGetPhysicalDeviceExternalFencePropertiesKHR(inst),
    vkGetPhysicalDeviceSciSyncAttributesNV: load_vkGetPhysicalDeviceSciSyncAttributesNV(inst),
    vkReleaseDisplayEXT: load_vkReleaseDisplayEXT(inst),
    vkAcquireXlibDisplayEXT: load_vkAcquireXlibDisplayEXT(inst),
    vkGetRandROutputDisplayEXT: load_vkGetRandROutputDisplayEXT(inst),
    vkAcquireWinrtDisplayNV: load_vkAcquireWinrtDisplayNV(inst),
    vkGetWinrtDisplayNV: load_vkGetWinrtDisplayNV(inst),
    vkGetPhysicalDeviceSurfaceCapabilities2EXT: load_vkGetPhysicalDeviceSurfaceCapabilities2EXT(inst),
    vkEnumeratePhysicalDeviceGroups: load_vkEnumeratePhysicalDeviceGroups(inst),
    vkEnumeratePhysicalDeviceGroupsKHR: load_vkEnumeratePhysicalDeviceGroupsKHR(inst),
    vkGetPhysicalDevicePresentRectanglesKHR: load_vkGetPhysicalDevicePresentRectanglesKHR(inst),
    vkCreateIOSSurfaceMVK: load_vkCreateIOSSurfaceMVK(inst),
    vkCreateMacOSSurfaceMVK: load_vkCreateMacOSSurfaceMVK(inst),
    vkCreateMetalSurfaceEXT: load_vkCreateMetalSurfaceEXT(inst),
    vkGetPhysicalDeviceMultisamplePropertiesEXT: load_vkGetPhysicalDeviceMultisamplePropertiesEXT(inst),
    vkGetPhysicalDeviceSurfaceCapabilities2KHR: load_vkGetPhysicalDeviceSurfaceCapabilities2KHR(inst),
    vkGetPhysicalDeviceSurfaceFormats2KHR: load_vkGetPhysicalDeviceSurfaceFormats2KHR(inst),
    vkGetPhysicalDeviceDisplayProperties2KHR: load_vkGetPhysicalDeviceDisplayProperties2KHR(inst),
    vkGetPhysicalDeviceDisplayPlaneProperties2KHR: load_vkGetPhysicalDeviceDisplayPlaneProperties2KHR(inst),
    vkGetDisplayModeProperties2KHR: load_vkGetDisplayModeProperties2KHR(inst),
    vkGetDisplayPlaneCapabilities2KHR: load_vkGetDisplayPlaneCapabilities2KHR(inst),
    vkGetPhysicalDeviceCalibrateableTimeDomainsKHR: load_vkGetPhysicalDeviceCalibrateableTimeDomainsKHR(inst),
    vkGetPhysicalDeviceCalibrateableTimeDomainsEXT: load_vkGetPhysicalDeviceCalibrateableTimeDomainsEXT(inst),
    vkCreateDebugUtilsMessengerEXT: load_vkCreateDebugUtilsMessengerEXT(inst),
    vkDestroyDebugUtilsMessengerEXT: load_vkDestroyDebugUtilsMessengerEXT(inst),
    vkSubmitDebugUtilsMessageEXT: load_vkSubmitDebugUtilsMessageEXT(inst),
    vkGetPhysicalDeviceCooperativeMatrixPropertiesNV: load_vkGetPhysicalDeviceCooperativeMatrixPropertiesNV(inst),
    vkGetPhysicalDeviceSurfacePresentModes2EXT: load_vkGetPhysicalDeviceSurfacePresentModes2EXT(inst),
    vkEnumeratePhysicalDeviceQueueFamilyPerformanceQueryCountersKHR: load_vkEnumeratePhysicalDeviceQueueFamilyPerformanceQueryCountersKHR(inst),
    vkGetPhysicalDeviceQueueFamilyPerformanceQueryPassesKHR: load_vkGetPhysicalDeviceQueueFamilyPerformanceQueryPassesKHR(inst),
    vkCreateHeadlessSurfaceEXT: load_vkCreateHeadlessSurfaceEXT(inst),
    vkGetPhysicalDeviceSupportedFramebufferMixedSamplesCombinationsNV: load_vkGetPhysicalDeviceSupportedFramebufferMixedSamplesCombinationsNV(inst),
    vkGetPhysicalDeviceToolProperties: load_vkGetPhysicalDeviceToolProperties(inst),
    vkGetPhysicalDeviceToolPropertiesEXT: load_vkGetPhysicalDeviceToolPropertiesEXT(inst),
    vkGetPhysicalDeviceRefreshableObjectTypesKHR: load_vkGetPhysicalDeviceRefreshableObjectTypesKHR(inst),
    vkGetPhysicalDeviceFragmentShadingRatesKHR: load_vkGetPhysicalDeviceFragmentShadingRatesKHR(inst),
    vkGetPhysicalDeviceVideoCapabilitiesKHR: load_vkGetPhysicalDeviceVideoCapabilitiesKHR(inst),
    vkGetPhysicalDeviceVideoFormatPropertiesKHR: load_vkGetPhysicalDeviceVideoFormatPropertiesKHR(inst),
    vkGetPhysicalDeviceVideoEncodeQualityLevelPropertiesKHR: load_vkGetPhysicalDeviceVideoEncodeQualityLevelPropertiesKHR(inst),
    vkAcquireDrmDisplayEXT: load_vkAcquireDrmDisplayEXT(inst),
    vkGetDrmDisplayEXT: load_vkGetDrmDisplayEXT(inst),
    vkGetPhysicalDeviceOpticalFlowImageFormatsNV: load_vkGetPhysicalDeviceOpticalFlowImageFormatsNV(inst),
    vkGetPhysicalDeviceCooperativeMatrixPropertiesKHR: load_vkGetPhysicalDeviceCooperativeMatrixPropertiesKHR(inst),
    vkGetPhysicalDeviceCooperativeMatrixProperties2EXT: load_vkGetPhysicalDeviceCooperativeMatrixProperties2EXT(inst),
    vkGetPhysicalDeviceCooperativeMatrixFlexibleDimensionsPropertiesNV: load_vkGetPhysicalDeviceCooperativeMatrixFlexibleDimensionsPropertiesNV(inst),
    vkGetPhysicalDeviceCooperativeVectorPropertiesNV: load_vkGetPhysicalDeviceCooperativeVectorPropertiesNV(inst),
    vkEnumeratePhysicalDeviceShaderInstrumentationMetricsARM: load_vkEnumeratePhysicalDeviceShaderInstrumentationMetricsARM(inst),
    vkGetPhysicalDeviceExternalTensorPropertiesARM: load_vkGetPhysicalDeviceExternalTensorPropertiesARM(inst),
    vkGetPhysicalDeviceQueueFamilyDataGraphPropertiesARM: load_vkGetPhysicalDeviceQueueFamilyDataGraphPropertiesARM(inst),
    vkGetPhysicalDeviceQueueFamilyDataGraphProcessingEnginePropertiesARM: load_vkGetPhysicalDeviceQueueFamilyDataGraphProcessingEnginePropertiesARM(inst),
    vkEnumeratePhysicalDeviceQueueFamilyPerformanceCountersByRegionARM: load_vkEnumeratePhysicalDeviceQueueFamilyPerformanceCountersByRegionARM(inst),
    vkGetPhysicalDeviceDescriptorSizeEXT: load_vkGetPhysicalDeviceDescriptorSizeEXT(inst),
    vkGetPhysicalDeviceQueueFamilyDataGraphEngineOperationPropertiesARM: load_vkGetPhysicalDeviceQueueFamilyDataGraphEngineOperationPropertiesARM(inst),
    vkGetPhysicalDeviceQueueFamilyDataGraphOpticalFlowImageFormatsARM: load_vkGetPhysicalDeviceQueueFamilyDataGraphOpticalFlowImageFormatsARM(inst),
  }
}

pub struct DeviceFn {
  vkDestroyDevice : FuncRef[(VkDevice, VkAllocationCallbacks) -> Unit]
  vkGetDeviceQueue : FuncRef[(VkDevice, UInt32, UInt32, FixedArray[VkQueue]) -> Unit]
  vkQueueSubmit : FuncRef[(VkQueue, UInt32, VkSubmitInfo, VkFence) -> Int32]
  vkQueueWaitIdle : FuncRef[(VkQueue) -> Int32]
  vkDeviceWaitIdle : FuncRef[(VkDevice) -> Int32]
  vkAllocateMemory : FuncRef[(VkDevice, VkMemoryAllocateInfo, VkAllocationCallbacks, FixedArray[VkDeviceMemory]) -> Int32]
  vkFreeMemory : FuncRef[(VkDevice, VkDeviceMemory, VkAllocationCallbacks) -> Unit]
  vkMapMemory : FuncRef[(VkDevice, VkDeviceMemory, UInt64, UInt64, UInt32, FixedArray[UInt64]) -> Int32]
  vkUnmapMemory : FuncRef[(VkDevice, VkDeviceMemory) -> Unit]
  vkFlushMappedMemoryRanges : FuncRef[(VkDevice, UInt32, VkMappedMemoryRange) -> Int32]
  vkInvalidateMappedMemoryRanges : FuncRef[(VkDevice, UInt32, VkMappedMemoryRange) -> Int32]
  vkGetDeviceMemoryCommitment : FuncRef[(VkDevice, VkDeviceMemory, FixedArray[UInt64]) -> Unit]
  vkGetBufferMemoryRequirements : FuncRef[(VkDevice, VkBuffer, VkMemoryRequirements) -> Unit]
  vkBindBufferMemory : FuncRef[(VkDevice, VkBuffer, VkDeviceMemory, UInt64) -> Int32]
  vkGetImageMemoryRequirements : FuncRef[(VkDevice, VkImage, VkMemoryRequirements) -> Unit]
  vkBindImageMemory : FuncRef[(VkDevice, VkImage, VkDeviceMemory, UInt64) -> Int32]
  vkGetImageSparseMemoryRequirements : FuncRef[(VkDevice, VkImage, FixedArray[UInt32], VkSparseImageMemoryRequirements) -> Unit]
  vkQueueBindSparse : FuncRef[(VkQueue, UInt32, VkBindSparseInfo, VkFence) -> Int32]
  vkCreateFence : FuncRef[(VkDevice, VkFenceCreateInfo, VkAllocationCallbacks, FixedArray[VkFence]) -> Int32]
  vkDestroyFence : FuncRef[(VkDevice, VkFence, VkAllocationCallbacks) -> Unit]
  vkResetFences : FuncRef[(VkDevice, UInt32, FixedArray[VkFence]) -> Int32]
  vkGetFenceStatus : FuncRef[(VkDevice, VkFence) -> Int32]
  vkWaitForFences : FuncRef[(VkDevice, UInt32, FixedArray[VkFence], UInt32, UInt64) -> Int32]
  vkCreateSemaphore : FuncRef[(VkDevice, VkSemaphoreCreateInfo, VkAllocationCallbacks, FixedArray[VkSemaphore]) -> Int32]
  vkDestroySemaphore : FuncRef[(VkDevice, VkSemaphore, VkAllocationCallbacks) -> Unit]
  vkCreateEvent : FuncRef[(VkDevice, VkEventCreateInfo, VkAllocationCallbacks, FixedArray[VkEvent]) -> Int32]
  vkDestroyEvent : FuncRef[(VkDevice, VkEvent, VkAllocationCallbacks) -> Unit]
  vkGetEventStatus : FuncRef[(VkDevice, VkEvent) -> Int32]
  vkSetEvent : FuncRef[(VkDevice, VkEvent) -> Int32]
  vkResetEvent : FuncRef[(VkDevice, VkEvent) -> Int32]
  vkCreateQueryPool : FuncRef[(VkDevice, VkQueryPoolCreateInfo, VkAllocationCallbacks, FixedArray[VkQueryPool]) -> Int32]
  vkDestroyQueryPool : FuncRef[(VkDevice, VkQueryPool, VkAllocationCallbacks) -> Unit]
  vkGetQueryPoolResults : FuncRef[(VkDevice, VkQueryPool, UInt32, UInt32, UInt64, UInt64, UInt64, UInt32) -> Int32]
  vkResetQueryPool : FuncRef[(VkDevice, VkQueryPool, UInt32, UInt32) -> Unit]
  vkResetQueryPoolEXT : FuncRef[(VkDevice, VkQueryPool, UInt32, UInt32) -> Unit]
  vkCreateBuffer : FuncRef[(VkDevice, VkBufferCreateInfo, VkAllocationCallbacks, FixedArray[VkBuffer]) -> Int32]
  vkDestroyBuffer : FuncRef[(VkDevice, VkBuffer, VkAllocationCallbacks) -> Unit]
  vkCreateBufferView : FuncRef[(VkDevice, VkBufferViewCreateInfo, VkAllocationCallbacks, FixedArray[VkBufferView]) -> Int32]
  vkDestroyBufferView : FuncRef[(VkDevice, VkBufferView, VkAllocationCallbacks) -> Unit]
  vkCreateImage : FuncRef[(VkDevice, VkImageCreateInfo, VkAllocationCallbacks, FixedArray[VkImage]) -> Int32]
  vkDestroyImage : FuncRef[(VkDevice, VkImage, VkAllocationCallbacks) -> Unit]
  vkGetImageSubresourceLayout : FuncRef[(VkDevice, VkImage, VkImageSubresource, VkSubresourceLayout) -> Unit]
  vkCreateImageView : FuncRef[(VkDevice, VkImageViewCreateInfo, VkAllocationCallbacks, FixedArray[VkImageView]) -> Int32]
  vkDestroyImageView : FuncRef[(VkDevice, VkImageView, VkAllocationCallbacks) -> Unit]
  vkCreateShaderModule : FuncRef[(VkDevice, VkShaderModuleCreateInfo, VkAllocationCallbacks, FixedArray[VkShaderModule]) -> Int32]
  vkDestroyShaderModule : FuncRef[(VkDevice, VkShaderModule, VkAllocationCallbacks) -> Unit]
  vkCreatePipelineCache : FuncRef[(VkDevice, VkPipelineCacheCreateInfo, VkAllocationCallbacks, FixedArray[VkPipelineCache]) -> Int32]
  vkDestroyPipelineCache : FuncRef[(VkDevice, VkPipelineCache, VkAllocationCallbacks) -> Unit]
  vkGetPipelineCacheData : FuncRef[(VkDevice, VkPipelineCache, FixedArray[UInt64], UInt64) -> Int32]
  vkMergePipelineCaches : FuncRef[(VkDevice, VkPipelineCache, UInt32, FixedArray[VkPipelineCache]) -> Int32]
  vkCreatePipelineBinariesKHR : FuncRef[(VkDevice, VkPipelineBinaryCreateInfoKHR, VkAllocationCallbacks, VkPipelineBinaryHandlesInfoKHR) -> Int32]
  vkDestroyPipelineBinaryKHR : FuncRef[(VkDevice, VkPipelineBinaryKHR, VkAllocationCallbacks) -> Unit]
  vkGetPipelineKeyKHR : FuncRef[(VkDevice, VkPipelineCreateInfoKHR, VkPipelineBinaryKeyKHR) -> Int32]
  vkGetPipelineBinaryDataKHR : FuncRef[(VkDevice, VkPipelineBinaryDataInfoKHR, VkPipelineBinaryKeyKHR, FixedArray[UInt64], UInt64) -> Int32]
  vkReleaseCapturedPipelineDataKHR : FuncRef[(VkDevice, VkReleaseCapturedPipelineDataInfoKHR, VkAllocationCallbacks) -> Int32]
  vkCreateGraphicsPipelines : FuncRef[(VkDevice, VkPipelineCache, UInt32, VkGraphicsPipelineCreateInfo, VkAllocationCallbacks, FixedArray[VkPipeline]) -> Int32]
  vkCreateComputePipelines : FuncRef[(VkDevice, VkPipelineCache, UInt32, VkComputePipelineCreateInfo, VkAllocationCallbacks, FixedArray[VkPipeline]) -> Int32]
  vkGetDeviceSubpassShadingMaxWorkgroupSizeHUAWEI : FuncRef[(VkDevice, VkRenderPass, VkExtent2D) -> Int32]
  vkDestroyPipeline : FuncRef[(VkDevice, VkPipeline, VkAllocationCallbacks) -> Unit]
  vkCreatePipelineLayout : FuncRef[(VkDevice, VkPipelineLayoutCreateInfo, VkAllocationCallbacks, FixedArray[VkPipelineLayout]) -> Int32]
  vkDestroyPipelineLayout : FuncRef[(VkDevice, VkPipelineLayout, VkAllocationCallbacks) -> Unit]
  vkCreateSampler : FuncRef[(VkDevice, VkSamplerCreateInfo, VkAllocationCallbacks, FixedArray[VkSampler]) -> Int32]
  vkDestroySampler : FuncRef[(VkDevice, VkSampler, VkAllocationCallbacks) -> Unit]
  vkCreateDescriptorSetLayout : FuncRef[(VkDevice, VkDescriptorSetLayoutCreateInfo, VkAllocationCallbacks, FixedArray[VkDescriptorSetLayout]) -> Int32]
  vkDestroyDescriptorSetLayout : FuncRef[(VkDevice, VkDescriptorSetLayout, VkAllocationCallbacks) -> Unit]
  vkCreateDescriptorPool : FuncRef[(VkDevice, VkDescriptorPoolCreateInfo, VkAllocationCallbacks, FixedArray[VkDescriptorPool]) -> Int32]
  vkDestroyDescriptorPool : FuncRef[(VkDevice, VkDescriptorPool, VkAllocationCallbacks) -> Unit]
  vkResetDescriptorPool : FuncRef[(VkDevice, VkDescriptorPool, UInt32) -> Int32]
  vkAllocateDescriptorSets : FuncRef[(VkDevice, VkDescriptorSetAllocateInfo, FixedArray[VkDescriptorSet]) -> Int32]
  vkFreeDescriptorSets : FuncRef[(VkDevice, VkDescriptorPool, UInt32, FixedArray[VkDescriptorSet]) -> Int32]
  vkUpdateDescriptorSets : FuncRef[(VkDevice, UInt32, VkWriteDescriptorSet, UInt32, VkCopyDescriptorSet) -> Unit]
  vkCreateFramebuffer : FuncRef[(VkDevice, VkFramebufferCreateInfo, VkAllocationCallbacks, FixedArray[VkFramebuffer]) -> Int32]
  vkDestroyFramebuffer : FuncRef[(VkDevice, VkFramebuffer, VkAllocationCallbacks) -> Unit]
  vkCreateRenderPass : FuncRef[(VkDevice, VkRenderPassCreateInfo, VkAllocationCallbacks, FixedArray[VkRenderPass]) -> Int32]
  vkDestroyRenderPass : FuncRef[(VkDevice, VkRenderPass, VkAllocationCallbacks) -> Unit]
  vkGetRenderAreaGranularity : FuncRef[(VkDevice, VkRenderPass, VkExtent2D) -> Unit]
  vkGetRenderingAreaGranularity : FuncRef[(VkDevice, VkRenderingAreaInfo, VkExtent2D) -> Unit]
  vkGetRenderingAreaGranularityKHR : FuncRef[(VkDevice, VkRenderingAreaInfo, VkExtent2D) -> Unit]
  vkCreateCommandPool : FuncRef[(VkDevice, VkCommandPoolCreateInfo, VkAllocationCallbacks, FixedArray[VkCommandPool]) -> Int32]
  vkDestroyCommandPool : FuncRef[(VkDevice, VkCommandPool, VkAllocationCallbacks) -> Unit]
  vkResetCommandPool : FuncRef[(VkDevice, VkCommandPool, UInt32) -> Int32]
  vkAllocateCommandBuffers : FuncRef[(VkDevice, VkCommandBufferAllocateInfo, FixedArray[VkCommandBuffer]) -> Int32]
  vkFreeCommandBuffers : FuncRef[(VkDevice, VkCommandPool, UInt32, FixedArray[VkCommandBuffer]) -> Unit]
  vkBeginCommandBuffer : FuncRef[(VkCommandBuffer, VkCommandBufferBeginInfo) -> Int32]
  vkEndCommandBuffer : FuncRef[(VkCommandBuffer) -> Int32]
  vkResetCommandBuffer : FuncRef[(VkCommandBuffer, UInt32) -> Int32]
  vkCmdBindPipeline : FuncRef[(VkCommandBuffer, UInt32, VkPipeline) -> Unit]
  vkCmdSetPrimitiveRestartIndexEXT : FuncRef[(VkCommandBuffer, UInt32) -> Unit]
  vkCmdSetAttachmentFeedbackLoopEnableEXT : FuncRef[(VkCommandBuffer, UInt32) -> Unit]
  vkCmdSetViewport : FuncRef[(VkCommandBuffer, UInt32, UInt32, VkViewport) -> Unit]
  vkCmdSetScissor : FuncRef[(VkCommandBuffer, UInt32, UInt32, VkRect2D) -> Unit]
  vkCmdSetLineWidth : FuncRef[(VkCommandBuffer, Float) -> Unit]
  vkCmdSetDepthBias : FuncRef[(VkCommandBuffer, Float, Float, Float) -> Unit]
  vkCmdSetBlendConstants : FuncRef[(VkCommandBuffer, FixedArray[Float]) -> Unit]
  vkCmdSetDepthBounds : FuncRef[(VkCommandBuffer, Float, Float) -> Unit]
  vkCmdSetStencilCompareMask : FuncRef[(VkCommandBuffer, UInt32, UInt32) -> Unit]
  vkCmdSetStencilWriteMask : FuncRef[(VkCommandBuffer, UInt32, UInt32) -> Unit]
  vkCmdSetStencilReference : FuncRef[(VkCommandBuffer, UInt32, UInt32) -> Unit]
  vkCmdBindDescriptorSets : FuncRef[(VkCommandBuffer, UInt32, VkPipelineLayout, UInt32, UInt32, FixedArray[VkDescriptorSet], UInt32, FixedArray[UInt32]) -> Unit]
  vkCmdBindIndexBuffer : FuncRef[(VkCommandBuffer, VkBuffer, UInt64, UInt32) -> Unit]
  vkCmdBindVertexBuffers : FuncRef[(VkCommandBuffer, UInt32, UInt32, FixedArray[VkBuffer], FixedArray[UInt64]) -> Unit]
  vkCmdDraw : FuncRef[(VkCommandBuffer, UInt32, UInt32, UInt32, UInt32) -> Unit]
  vkCmdDrawIndexed : FuncRef[(VkCommandBuffer, UInt32, UInt32, UInt32, Int32, UInt32) -> Unit]
  vkCmdDrawMultiEXT : FuncRef[(VkCommandBuffer, UInt32, VkMultiDrawInfoEXT, UInt32, UInt32, UInt32) -> Unit]
  vkCmdDrawMultiIndexedEXT : FuncRef[(VkCommandBuffer, UInt32, VkMultiDrawIndexedInfoEXT, UInt32, UInt32, UInt32, FixedArray[Int32]) -> Unit]
  vkCmdDrawIndirect : FuncRef[(VkCommandBuffer, VkBuffer, UInt64, UInt32, UInt32) -> Unit]
  vkCmdDrawIndexedIndirect : FuncRef[(VkCommandBuffer, VkBuffer, UInt64, UInt32, UInt32) -> Unit]
  vkCmdDispatch : FuncRef[(VkCommandBuffer, UInt32, UInt32, UInt32) -> Unit]
  vkCmdDispatchIndirect : FuncRef[(VkCommandBuffer, VkBuffer, UInt64) -> Unit]
  vkCmdSubpassShadingHUAWEI : FuncRef[(VkCommandBuffer) -> Unit]
  vkCmdDrawClusterHUAWEI : FuncRef[(VkCommandBuffer, UInt32, UInt32, UInt32) -> Unit]
  vkCmdDrawClusterIndirectHUAWEI : FuncRef[(VkCommandBuffer, VkBuffer, UInt64) -> Unit]
  vkCmdUpdatePipelineIndirectBufferNV : FuncRef[(VkCommandBuffer, UInt32, VkPipeline) -> Unit]
  vkCmdCopyBuffer : FuncRef[(VkCommandBuffer, VkBuffer, VkBuffer, UInt32, VkBufferCopy) -> Unit]
  vkCmdCopyImage : FuncRef[(VkCommandBuffer, VkImage, UInt32, VkImage, UInt32, UInt32, VkImageCopy) -> Unit]
  vkCmdBlitImage : FuncRef[(VkCommandBuffer, VkImage, UInt32, VkImage, UInt32, UInt32, VkImageBlit, UInt32) -> Unit]
  vkCmdCopyBufferToImage : FuncRef[(VkCommandBuffer, VkBuffer, VkImage, UInt32, UInt32, VkBufferImageCopy) -> Unit]
  vkCmdCopyImageToBuffer : FuncRef[(VkCommandBuffer, VkImage, UInt32, VkBuffer, UInt32, VkBufferImageCopy) -> Unit]
  vkCmdCopyMemoryIndirectNV : FuncRef[(VkCommandBuffer, UInt64, UInt32, UInt32) -> Unit]
  vkCmdCopyMemoryIndirectKHR : FuncRef[(VkCommandBuffer, VkCopyMemoryIndirectInfoKHR) -> Unit]
  vkCmdCopyMemoryToImageIndirectNV : FuncRef[(VkCommandBuffer, UInt64, UInt32, UInt32, VkImage, UInt32, VkImageSubresourceLayers) -> Unit]
  vkCmdCopyMemoryToImageIndirectKHR : FuncRef[(VkCommandBuffer, VkCopyMemoryToImageIndirectInfoKHR) -> Unit]
  vkCmdUpdateBuffer : FuncRef[(VkCommandBuffer, VkBuffer, UInt64, UInt64, UInt64) -> Unit]
  vkCmdFillBuffer : FuncRef[(VkCommandBuffer, VkBuffer, UInt64, UInt64, UInt32) -> Unit]
  vkCmdClearColorImage : FuncRef[(VkCommandBuffer, VkImage, UInt32, VkClearColorValue, UInt32, VkImageSubresourceRange) -> Unit]
  vkCmdClearDepthStencilImage : FuncRef[(VkCommandBuffer, VkImage, UInt32, VkClearDepthStencilValue, UInt32, VkImageSubresourceRange) -> Unit]
  vkCmdClearAttachments : FuncRef[(VkCommandBuffer, UInt32, VkClearAttachment, UInt32, VkClearRect) -> Unit]
  vkCmdResolveImage : FuncRef[(VkCommandBuffer, VkImage, UInt32, VkImage, UInt32, UInt32, VkImageResolve) -> Unit]
  vkCmdSetEvent : FuncRef[(VkCommandBuffer, VkEvent, UInt32) -> Unit]
  vkCmdResetEvent : FuncRef[(VkCommandBuffer, VkEvent, UInt32) -> Unit]
  vkCmdWaitEvents : FuncRef[(VkCommandBuffer, UInt32, FixedArray[VkEvent], UInt32, UInt32, UInt32, VkMemoryBarrier, UInt32, VkBufferMemoryBarrier, UInt32, VkImageMemoryBarrier) -> Unit]
  vkCmdPipelineBarrier : FuncRef[(VkCommandBuffer, UInt32, UInt32, UInt32, UInt32, VkMemoryBarrier, UInt32, VkBufferMemoryBarrier, UInt32, VkImageMemoryBarrier) -> Unit]
  vkCmdBeginQuery : FuncRef[(VkCommandBuffer, VkQueryPool, UInt32, UInt32) -> Unit]
  vkCmdEndQuery : FuncRef[(VkCommandBuffer, VkQueryPool, UInt32) -> Unit]
  vkCmdBeginConditionalRenderingEXT : FuncRef[(VkCommandBuffer, VkConditionalRenderingBeginInfoEXT) -> Unit]
  vkCmdEndConditionalRenderingEXT : FuncRef[(VkCommandBuffer) -> Unit]
  vkCmdBeginCustomResolveEXT : FuncRef[(VkCommandBuffer, VkBeginCustomResolveInfoEXT) -> Unit]
  vkCmdResetQueryPool : FuncRef[(VkCommandBuffer, VkQueryPool, UInt32, UInt32) -> Unit]
  vkCmdWriteTimestamp : FuncRef[(VkCommandBuffer, UInt32, VkQueryPool, UInt32) -> Unit]
  vkCmdCopyQueryPoolResults : FuncRef[(VkCommandBuffer, VkQueryPool, UInt32, UInt32, VkBuffer, UInt64, UInt64, UInt32) -> Unit]
  vkCmdPushConstants : FuncRef[(VkCommandBuffer, VkPipelineLayout, UInt32, UInt32, UInt32, UInt64) -> Unit]
  vkCmdBeginRenderPass : FuncRef[(VkCommandBuffer, VkRenderPassBeginInfo, UInt32) -> Unit]
  vkCmdNextSubpass : FuncRef[(VkCommandBuffer, UInt32) -> Unit]
  vkCmdEndRenderPass : FuncRef[(VkCommandBuffer) -> Unit]
  vkCmdExecuteCommands : FuncRef[(VkCommandBuffer, UInt32, FixedArray[VkCommandBuffer]) -> Unit]
  vkCreateSharedSwapchainsKHR : FuncRef[(VkDevice, UInt32, VkSwapchainCreateInfoKHR, VkAllocationCallbacks, FixedArray[VkSwapchainKHR]) -> Int32]
  vkCreateSwapchainKHR : FuncRef[(VkDevice, VkSwapchainCreateInfoKHR, VkAllocationCallbacks, FixedArray[VkSwapchainKHR]) -> Int32]
  vkDestroySwapchainKHR : FuncRef[(VkDevice, VkSwapchainKHR, VkAllocationCallbacks) -> Unit]
  vkGetSwapchainImagesKHR : FuncRef[(VkDevice, VkSwapchainKHR, FixedArray[UInt32], FixedArray[VkImage]) -> Int32]
  vkAcquireNextImageKHR : FuncRef[(VkDevice, VkSwapchainKHR, UInt64, VkSemaphore, VkFence, FixedArray[UInt32]) -> Int32]
  vkQueuePresentKHR : FuncRef[(VkQueue, VkPresentInfoKHR) -> Int32]
  vkDebugMarkerSetObjectNameEXT : FuncRef[(VkDevice, VkDebugMarkerObjectNameInfoEXT) -> Int32]
  vkDebugMarkerSetObjectTagEXT : FuncRef[(VkDevice, VkDebugMarkerObjectTagInfoEXT) -> Int32]
  vkCmdDebugMarkerBeginEXT : FuncRef[(VkCommandBuffer, VkDebugMarkerMarkerInfoEXT) -> Unit]
  vkCmdDebugMarkerEndEXT : FuncRef[(VkCommandBuffer) -> Unit]
  vkCmdDebugMarkerInsertEXT : FuncRef[(VkCommandBuffer, VkDebugMarkerMarkerInfoEXT) -> Unit]
  vkGetMemoryWin32HandleNV : FuncRef[(VkDevice, VkDeviceMemory, UInt32, UInt64) -> Int32]
  vkCmdExecuteGeneratedCommandsNV : FuncRef[(VkCommandBuffer, UInt32, VkGeneratedCommandsInfoNV) -> Unit]
  vkCmdPreprocessGeneratedCommandsNV : FuncRef[(VkCommandBuffer, VkGeneratedCommandsInfoNV) -> Unit]
  vkCmdBindPipelineShaderGroupNV : FuncRef[(VkCommandBuffer, UInt32, VkPipeline, UInt32) -> Unit]
  vkGetGeneratedCommandsMemoryRequirementsNV : FuncRef[(VkDevice, VkGeneratedCommandsMemoryRequirementsInfoNV, VkMemoryRequirements2) -> Unit]
  vkCreateIndirectCommandsLayoutNV : FuncRef[(VkDevice, VkIndirectCommandsLayoutCreateInfoNV, VkAllocationCallbacks, FixedArray[VkIndirectCommandsLayoutNV]) -> Int32]
  vkDestroyIndirectCommandsLayoutNV : FuncRef[(VkDevice, VkIndirectCommandsLayoutNV, VkAllocationCallbacks) -> Unit]
  vkCmdExecuteGeneratedCommandsEXT : FuncRef[(VkCommandBuffer, UInt32, VkGeneratedCommandsInfoEXT) -> Unit]
  vkCmdPreprocessGeneratedCommandsEXT : FuncRef[(VkCommandBuffer, VkGeneratedCommandsInfoEXT, VkCommandBuffer) -> Unit]
  vkGetGeneratedCommandsMemoryRequirementsEXT : FuncRef[(VkDevice, VkGeneratedCommandsMemoryRequirementsInfoEXT, VkMemoryRequirements2) -> Unit]
  vkCreateIndirectCommandsLayoutEXT : FuncRef[(VkDevice, VkIndirectCommandsLayoutCreateInfoEXT, VkAllocationCallbacks, FixedArray[VkIndirectCommandsLayoutEXT]) -> Int32]
  vkDestroyIndirectCommandsLayoutEXT : FuncRef[(VkDevice, VkIndirectCommandsLayoutEXT, VkAllocationCallbacks) -> Unit]
  vkCreateIndirectExecutionSetEXT : FuncRef[(VkDevice, VkIndirectExecutionSetCreateInfoEXT, VkAllocationCallbacks, FixedArray[VkIndirectExecutionSetEXT]) -> Int32]
  vkDestroyIndirectExecutionSetEXT : FuncRef[(VkDevice, VkIndirectExecutionSetEXT, VkAllocationCallbacks) -> Unit]
  vkUpdateIndirectExecutionSetPipelineEXT : FuncRef[(VkDevice, VkIndirectExecutionSetEXT, UInt32, VkWriteIndirectExecutionSetPipelineEXT) -> Unit]
  vkUpdateIndirectExecutionSetShaderEXT : FuncRef[(VkDevice, VkIndirectExecutionSetEXT, UInt32, VkWriteIndirectExecutionSetShaderEXT) -> Unit]
  vkCmdPushDescriptorSet : FuncRef[(VkCommandBuffer, UInt32, VkPipelineLayout, UInt32, UInt32, VkWriteDescriptorSet) -> Unit]
  vkCmdPushDescriptorSetKHR : FuncRef[(VkCommandBuffer, UInt32, VkPipelineLayout, UInt32, UInt32, VkWriteDescriptorSet) -> Unit]
  vkTrimCommandPool : FuncRef[(VkDevice, VkCommandPool, UInt32) -> Unit]
  vkTrimCommandPoolKHR : FuncRef[(VkDevice, VkCommandPool, UInt32) -> Unit]
  vkGetMemoryWin32HandleKHR : FuncRef[(VkDevice, VkMemoryGetWin32HandleInfoKHR, UInt64) -> Int32]
  vkGetMemoryWin32HandlePropertiesKHR : FuncRef[(VkDevice, UInt32, UInt64, VkMemoryWin32HandlePropertiesKHR) -> Int32]
  vkGetMemoryFdKHR : FuncRef[(VkDevice, VkMemoryGetFdInfoKHR, FixedArray[Int32]) -> Int32]
  vkGetMemoryFdPropertiesKHR : FuncRef[(VkDevice, UInt32, Int32, VkMemoryFdPropertiesKHR) -> Int32]
  vkGetMemoryZirconHandleFUCHSIA : FuncRef[(VkDevice, VkMemoryGetZirconHandleInfoFUCHSIA, UInt64) -> Int32]
  vkGetMemoryZirconHandlePropertiesFUCHSIA : FuncRef[(VkDevice, UInt32, UInt64, VkMemoryZirconHandlePropertiesFUCHSIA) -> Int32]
  vkGetMemoryRemoteAddressNV : FuncRef[(VkDevice, VkMemoryGetRemoteAddressInfoNV, UInt64) -> Int32]
  vkGetMemorySciBufNV : FuncRef[(VkDevice, VkMemoryGetSciBufInfoNV, UInt64) -> Int32]
  vkGetSemaphoreWin32HandleKHR : FuncRef[(VkDevice, VkSemaphoreGetWin32HandleInfoKHR, UInt64) -> Int32]
  vkImportSemaphoreWin32HandleKHR : FuncRef[(VkDevice, VkImportSemaphoreWin32HandleInfoKHR) -> Int32]
  vkGetSemaphoreFdKHR : FuncRef[(VkDevice, VkSemaphoreGetFdInfoKHR, FixedArray[Int32]) -> Int32]
  vkImportSemaphoreFdKHR : FuncRef[(VkDevice, VkImportSemaphoreFdInfoKHR) -> Int32]
  vkGetSemaphoreZirconHandleFUCHSIA : FuncRef[(VkDevice, VkSemaphoreGetZirconHandleInfoFUCHSIA, UInt64) -> Int32]
  vkImportSemaphoreZirconHandleFUCHSIA : FuncRef[(VkDevice, VkImportSemaphoreZirconHandleInfoFUCHSIA) -> Int32]
  vkGetFenceWin32HandleKHR : FuncRef[(VkDevice, VkFenceGetWin32HandleInfoKHR, UInt64) -> Int32]
  vkImportFenceWin32HandleKHR : FuncRef[(VkDevice, VkImportFenceWin32HandleInfoKHR) -> Int32]
  vkGetFenceFdKHR : FuncRef[(VkDevice, VkFenceGetFdInfoKHR, FixedArray[Int32]) -> Int32]
  vkImportFenceFdKHR : FuncRef[(VkDevice, VkImportFenceFdInfoKHR) -> Int32]
  vkGetFenceSciSyncFenceNV : FuncRef[(VkDevice, VkFenceGetSciSyncInfoNV, UInt64) -> Int32]
  vkGetFenceSciSyncObjNV : FuncRef[(VkDevice, VkFenceGetSciSyncInfoNV, UInt64) -> Int32]
  vkImportFenceSciSyncFenceNV : FuncRef[(VkDevice, VkImportFenceSciSyncInfoNV) -> Int32]
  vkImportFenceSciSyncObjNV : FuncRef[(VkDevice, VkImportFenceSciSyncInfoNV) -> Int32]
  vkGetSemaphoreSciSyncObjNV : FuncRef[(VkDevice, VkSemaphoreGetSciSyncInfoNV, UInt64) -> Int32]
  vkImportSemaphoreSciSyncObjNV : FuncRef[(VkDevice, VkImportSemaphoreSciSyncInfoNV) -> Int32]
  vkCreateSemaphoreSciSyncPoolNV : FuncRef[(VkDevice, VkSemaphoreSciSyncPoolCreateInfoNV, VkAllocationCallbacks, FixedArray[VkSemaphoreSciSyncPoolNV]) -> Int32]
  vkDestroySemaphoreSciSyncPoolNV : FuncRef[(VkDevice, VkSemaphoreSciSyncPoolNV, VkAllocationCallbacks) -> Unit]
  vkDisplayPowerControlEXT : FuncRef[(VkDevice, VkDisplayKHR, VkDisplayPowerInfoEXT) -> Int32]
  vkRegisterDeviceEventEXT : FuncRef[(VkDevice, VkDeviceEventInfoEXT, VkAllocationCallbacks, FixedArray[VkFence]) -> Int32]
  vkRegisterDisplayEventEXT : FuncRef[(VkDevice, VkDisplayKHR, VkDisplayEventInfoEXT, VkAllocationCallbacks, FixedArray[VkFence]) -> Int32]
  vkGetSwapchainCounterEXT : FuncRef[(VkDevice, VkSwapchainKHR, UInt32, FixedArray[UInt64]) -> Int32]
  vkGetDeviceGroupPeerMemoryFeatures : FuncRef[(VkDevice, UInt32, UInt32, UInt32, FixedArray[UInt32]) -> Unit]
  vkGetDeviceGroupPeerMemoryFeaturesKHR : FuncRef[(VkDevice, UInt32, UInt32, UInt32, FixedArray[UInt32]) -> Unit]
  vkBindBufferMemory2 : FuncRef[(VkDevice, UInt32, VkBindBufferMemoryInfo) -> Int32]
  vkBindBufferMemory2KHR : FuncRef[(VkDevice, UInt32, VkBindBufferMemoryInfo) -> Int32]
  vkBindImageMemory2 : FuncRef[(VkDevice, UInt32, VkBindImageMemoryInfo) -> Int32]
  vkBindImageMemory2KHR : FuncRef[(VkDevice, UInt32, VkBindImageMemoryInfo) -> Int32]
  vkCmdSetDeviceMask : FuncRef[(VkCommandBuffer, UInt32) -> Unit]
  vkCmdSetDeviceMaskKHR : FuncRef[(VkCommandBuffer, UInt32) -> Unit]
  vkGetDeviceGroupPresentCapabilitiesKHR : FuncRef[(VkDevice, VkDeviceGroupPresentCapabilitiesKHR) -> Int32]
  vkGetDeviceGroupSurfacePresentModesKHR : FuncRef[(VkDevice, VkSurfaceKHR, FixedArray[UInt32]) -> Int32]
  vkAcquireNextImage2KHR : FuncRef[(VkDevice, VkAcquireNextImageInfoKHR, FixedArray[UInt32]) -> Int32]
  vkCmdDispatchBase : FuncRef[(VkCommandBuffer, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32) -> Unit]
  vkCmdDispatchBaseKHR : FuncRef[(VkCommandBuffer, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32) -> Unit]
  vkCreateDescriptorUpdateTemplate : FuncRef[(VkDevice, VkDescriptorUpdateTemplateCreateInfo, VkAllocationCallbacks, FixedArray[VkDescriptorUpdateTemplate]) -> Int32]
  vkCreateDescriptorUpdateTemplateKHR : FuncRef[(VkDevice, VkDescriptorUpdateTemplateCreateInfo, VkAllocationCallbacks, FixedArray[VkDescriptorUpdateTemplate]) -> Int32]
  vkDestroyDescriptorUpdateTemplate : FuncRef[(VkDevice, VkDescriptorUpdateTemplate, VkAllocationCallbacks) -> Unit]
  vkDestroyDescriptorUpdateTemplateKHR : FuncRef[(VkDevice, VkDescriptorUpdateTemplate, VkAllocationCallbacks) -> Unit]
  vkUpdateDescriptorSetWithTemplate : FuncRef[(VkDevice, VkDescriptorSet, VkDescriptorUpdateTemplate, UInt64) -> Unit]
  vkUpdateDescriptorSetWithTemplateKHR : FuncRef[(VkDevice, VkDescriptorSet, VkDescriptorUpdateTemplate, UInt64) -> Unit]
  vkCmdPushDescriptorSetWithTemplate : FuncRef[(VkCommandBuffer, VkDescriptorUpdateTemplate, VkPipelineLayout, UInt32, UInt64) -> Unit]
  vkCmdPushDescriptorSetWithTemplateKHR : FuncRef[(VkCommandBuffer, VkDescriptorUpdateTemplate, VkPipelineLayout, UInt32, UInt64) -> Unit]
  vkSetHdrMetadataEXT : FuncRef[(VkDevice, UInt32, FixedArray[VkSwapchainKHR], VkHdrMetadataEXT) -> Unit]
  vkGetSwapchainStatusKHR : FuncRef[(VkDevice, VkSwapchainKHR) -> Int32]
  vkGetRefreshCycleDurationGOOGLE : FuncRef[(VkDevice, VkSwapchainKHR, VkRefreshCycleDurationGOOGLE) -> Int32]
  vkGetPastPresentationTimingGOOGLE : FuncRef[(VkDevice, VkSwapchainKHR, FixedArray[UInt32], VkPastPresentationTimingGOOGLE) -> Int32]
  vkCmdSetViewportWScalingNV : FuncRef[(VkCommandBuffer, UInt32, UInt32, VkViewportWScalingNV) -> Unit]
  vkCmdSetDiscardRectangleEXT : FuncRef[(VkCommandBuffer, UInt32, UInt32, VkRect2D) -> Unit]
  vkCmdSetDiscardRectangleEnableEXT : FuncRef[(VkCommandBuffer, UInt32) -> Unit]
  vkCmdSetDiscardRectangleModeEXT : FuncRef[(VkCommandBuffer, UInt32) -> Unit]
  vkCmdSetSampleLocationsEXT : FuncRef[(VkCommandBuffer, VkSampleLocationsInfoEXT) -> Unit]
  vkGetBufferMemoryRequirements2 : FuncRef[(VkDevice, VkBufferMemoryRequirementsInfo2, VkMemoryRequirements2) -> Unit]
  vkGetBufferMemoryRequirements2KHR : FuncRef[(VkDevice, VkBufferMemoryRequirementsInfo2, VkMemoryRequirements2) -> Unit]
  vkGetImageMemoryRequirements2 : FuncRef[(VkDevice, VkImageMemoryRequirementsInfo2, VkMemoryRequirements2) -> Unit]
  vkGetImageMemoryRequirements2KHR : FuncRef[(VkDevice, VkImageMemoryRequirementsInfo2, VkMemoryRequirements2) -> Unit]
  vkGetImageSparseMemoryRequirements2 : FuncRef[(VkDevice, VkImageSparseMemoryRequirementsInfo2, FixedArray[UInt32], VkSparseImageMemoryRequirements2) -> Unit]
  vkGetImageSparseMemoryRequirements2KHR : FuncRef[(VkDevice, VkImageSparseMemoryRequirementsInfo2, FixedArray[UInt32], VkSparseImageMemoryRequirements2) -> Unit]
  vkGetDeviceBufferMemoryRequirements : FuncRef[(VkDevice, VkDeviceBufferMemoryRequirements, VkMemoryRequirements2) -> Unit]
  vkGetDeviceBufferMemoryRequirementsKHR : FuncRef[(VkDevice, VkDeviceBufferMemoryRequirements, VkMemoryRequirements2) -> Unit]
  vkGetDeviceImageMemoryRequirements : FuncRef[(VkDevice, VkDeviceImageMemoryRequirements, VkMemoryRequirements2) -> Unit]
  vkGetDeviceImageMemoryRequirementsKHR : FuncRef[(VkDevice, VkDeviceImageMemoryRequirements, VkMemoryRequirements2) -> Unit]
  vkGetDeviceImageSparseMemoryRequirements : FuncRef[(VkDevice, VkDeviceImageMemoryRequirements, FixedArray[UInt32], VkSparseImageMemoryRequirements2) -> Unit]
  vkGetDeviceImageSparseMemoryRequirementsKHR : FuncRef[(VkDevice, VkDeviceImageMemoryRequirements, FixedArray[UInt32], VkSparseImageMemoryRequirements2) -> Unit]
  vkCreateSamplerYcbcrConversion : FuncRef[(VkDevice, VkSamplerYcbcrConversionCreateInfo, VkAllocationCallbacks, FixedArray[VkSamplerYcbcrConversion]) -> Int32]
  vkCreateSamplerYcbcrConversionKHR : FuncRef[(VkDevice, VkSamplerYcbcrConversionCreateInfo, VkAllocationCallbacks, FixedArray[VkSamplerYcbcrConversion]) -> Int32]
  vkDestroySamplerYcbcrConversion : FuncRef[(VkDevice, VkSamplerYcbcrConversion, VkAllocationCallbacks) -> Unit]
  vkDestroySamplerYcbcrConversionKHR : FuncRef[(VkDevice, VkSamplerYcbcrConversion, VkAllocationCallbacks) -> Unit]
  vkGetDeviceQueue2 : FuncRef[(VkDevice, VkDeviceQueueInfo2, FixedArray[VkQueue]) -> Unit]
  vkCreateValidationCacheEXT : FuncRef[(VkDevice, VkValidationCacheCreateInfoEXT, VkAllocationCallbacks, FixedArray[VkValidationCacheEXT]) -> Int32]
  vkDestroyValidationCacheEXT : FuncRef[(VkDevice, VkValidationCacheEXT, VkAllocationCallbacks) -> Unit]
  vkGetValidationCacheDataEXT : FuncRef[(VkDevice, VkValidationCacheEXT, FixedArray[UInt64], UInt64) -> Int32]
  vkMergeValidationCachesEXT : FuncRef[(VkDevice, VkValidationCacheEXT, UInt32, FixedArray[VkValidationCacheEXT]) -> Int32]
  vkGetDescriptorSetLayoutSupport : FuncRef[(VkDevice, VkDescriptorSetLayoutCreateInfo, VkDescriptorSetLayoutSupport) -> Unit]
  vkGetDescriptorSetLayoutSupportKHR : FuncRef[(VkDevice, VkDescriptorSetLayoutCreateInfo, VkDescriptorSetLayoutSupport) -> Unit]
  vkGetSwapchainGrallocUsageANDROID : FuncRef[(VkDevice, UInt32, UInt32, FixedArray[Int32]) -> Int32]
  vkGetSwapchainGrallocUsage2ANDROID : FuncRef[(VkDevice, UInt32, UInt32, UInt32, FixedArray[UInt64], FixedArray[UInt64]) -> Int32]
  vkAcquireImageANDROID : FuncRef[(VkDevice, VkImage, Int32, VkSemaphore, VkFence) -> Int32]
  vkQueueSignalReleaseImageANDROID : FuncRef[(VkQueue, UInt32, FixedArray[VkSemaphore], VkImage, FixedArray[Int32]) -> Int32]
  vkGetShaderInfoAMD : FuncRef[(VkDevice, VkPipeline, UInt32, UInt32, FixedArray[UInt64], UInt64) -> Int32]
  vkSetLocalDimmingAMD : FuncRef[(VkDevice, VkSwapchainKHR, UInt32) -> Unit]
  vkGetCalibratedTimestampsKHR : FuncRef[(VkDevice, UInt32, VkCalibratedTimestampInfoKHR, FixedArray[UInt64], FixedArray[UInt64]) -> Int32]
  vkGetCalibratedTimestampsEXT : FuncRef[(VkDevice, UInt32, VkCalibratedTimestampInfoKHR, FixedArray[UInt64], FixedArray[UInt64]) -> Int32]
  vkSetDebugUtilsObjectNameEXT : FuncRef[(VkDevice, VkDebugUtilsObjectNameInfoEXT) -> Int32]
  vkSetDebugUtilsObjectTagEXT : FuncRef[(VkDevice, VkDebugUtilsObjectTagInfoEXT) -> Int32]
  vkQueueBeginDebugUtilsLabelEXT : FuncRef[(VkQueue, VkDebugUtilsLabelEXT) -> Unit]
  vkQueueEndDebugUtilsLabelEXT : FuncRef[(VkQueue) -> Unit]
  vkQueueInsertDebugUtilsLabelEXT : FuncRef[(VkQueue, VkDebugUtilsLabelEXT) -> Unit]
  vkCmdBeginDebugUtilsLabelEXT : FuncRef[(VkCommandBuffer, VkDebugUtilsLabelEXT) -> Unit]
  vkCmdEndDebugUtilsLabelEXT : FuncRef[(VkCommandBuffer) -> Unit]
  vkCmdInsertDebugUtilsLabelEXT : FuncRef[(VkCommandBuffer, VkDebugUtilsLabelEXT) -> Unit]
  vkGetMemoryHostPointerPropertiesEXT : FuncRef[(VkDevice, UInt32, UInt64, VkMemoryHostPointerPropertiesEXT) -> Int32]
  vkCmdWriteBufferMarkerAMD : FuncRef[(VkCommandBuffer, UInt32, VkBuffer, UInt64, UInt32) -> Unit]
  vkCreateRenderPass2 : FuncRef[(VkDevice, VkRenderPassCreateInfo2, VkAllocationCallbacks, FixedArray[VkRenderPass]) -> Int32]
  vkCreateRenderPass2KHR : FuncRef[(VkDevice, VkRenderPassCreateInfo2, VkAllocationCallbacks, FixedArray[VkRenderPass]) -> Int32]
  vkCmdBeginRenderPass2 : FuncRef[(VkCommandBuffer, VkRenderPassBeginInfo, VkSubpassBeginInfo) -> Unit]
  vkCmdBeginRenderPass2KHR : FuncRef[(VkCommandBuffer, VkRenderPassBeginInfo, VkSubpassBeginInfo) -> Unit]
  vkCmdNextSubpass2 : FuncRef[(VkCommandBuffer, VkSubpassBeginInfo, VkSubpassEndInfo) -> Unit]
  vkCmdNextSubpass2KHR : FuncRef[(VkCommandBuffer, VkSubpassBeginInfo, VkSubpassEndInfo) -> Unit]
  vkCmdEndRenderPass2 : FuncRef[(VkCommandBuffer, VkSubpassEndInfo) -> Unit]
  vkCmdEndRenderPass2KHR : FuncRef[(VkCommandBuffer, VkSubpassEndInfo) -> Unit]
  vkGetSemaphoreCounterValue : FuncRef[(VkDevice, VkSemaphore, FixedArray[UInt64]) -> Int32]
  vkGetSemaphoreCounterValueKHR : FuncRef[(VkDevice, VkSemaphore, FixedArray[UInt64]) -> Int32]
  vkWaitSemaphores : FuncRef[(VkDevice, VkSemaphoreWaitInfo, UInt64) -> Int32]
  vkWaitSemaphoresKHR : FuncRef[(VkDevice, VkSemaphoreWaitInfo, UInt64) -> Int32]
  vkSignalSemaphore : FuncRef[(VkDevice, VkSemaphoreSignalInfo) -> Int32]
  vkSignalSemaphoreKHR : FuncRef[(VkDevice, VkSemaphoreSignalInfo) -> Int32]
  vkGetAndroidHardwareBufferPropertiesANDROID : FuncRef[(VkDevice, UInt64, VkAndroidHardwareBufferPropertiesANDROID) -> Int32]
  vkGetMemoryAndroidHardwareBufferANDROID : FuncRef[(VkDevice, VkMemoryGetAndroidHardwareBufferInfoANDROID, FixedArray[UInt64]) -> Int32]
  vkCmdDrawIndirectCount : FuncRef[(VkCommandBuffer, VkBuffer, UInt64, VkBuffer, UInt64, UInt32, UInt32) -> Unit]
  vkCmdDrawIndirectCountKHR : FuncRef[(VkCommandBuffer, VkBuffer, UInt64, VkBuffer, UInt64, UInt32, UInt32) -> Unit]
  vkCmdDrawIndirectCountAMD : FuncRef[(VkCommandBuffer, VkBuffer, UInt64, VkBuffer, UInt64, UInt32, UInt32) -> Unit]
  vkCmdDrawIndexedIndirectCount : FuncRef[(VkCommandBuffer, VkBuffer, UInt64, VkBuffer, UInt64, UInt32, UInt32) -> Unit]
  vkCmdDrawIndexedIndirectCountKHR : FuncRef[(VkCommandBuffer, VkBuffer, UInt64, VkBuffer, UInt64, UInt32, UInt32) -> Unit]
  vkCmdDrawIndexedIndirectCountAMD : FuncRef[(VkCommandBuffer, VkBuffer, UInt64, VkBuffer, UInt64, UInt32, UInt32) -> Unit]
  vkCmdSetCheckpointNV : FuncRef[(VkCommandBuffer, UInt64) -> Unit]
  vkGetQueueCheckpointDataNV : FuncRef[(VkQueue, FixedArray[UInt32], VkCheckpointDataNV) -> Unit]
  vkCmdBindTransformFeedbackBuffersEXT : FuncRef[(VkCommandBuffer, UInt32, UInt32, FixedArray[VkBuffer], FixedArray[UInt64], FixedArray[UInt64]) -> Unit]
  vkCmdBeginTransformFeedbackEXT : FuncRef[(VkCommandBuffer, UInt32, UInt32, FixedArray[VkBuffer], FixedArray[UInt64]) -> Unit]
  vkCmdEndTransformFeedbackEXT : FuncRef[(VkCommandBuffer, UInt32, UInt32, FixedArray[VkBuffer], FixedArray[UInt64]) -> Unit]
  vkCmdBeginQueryIndexedEXT : FuncRef[(VkCommandBuffer, VkQueryPool, UInt32, UInt32, UInt32) -> Unit]
  vkCmdEndQueryIndexedEXT : FuncRef[(VkCommandBuffer, VkQueryPool, UInt32, UInt32) -> Unit]
  vkCmdDrawIndirectByteCountEXT : FuncRef[(VkCommandBuffer, UInt32, UInt32, VkBuffer, UInt64, UInt32, UInt32) -> Unit]
  vkCmdSetExclusiveScissorNV : FuncRef[(VkCommandBuffer, UInt32, UInt32, VkRect2D) -> Unit]
  vkCmdSetExclusiveScissorEnableNV : FuncRef[(VkCommandBuffer, UInt32, UInt32, FixedArray[UInt32]) -> Unit]
  vkCmdBindShadingRateImageNV : FuncRef[(VkCommandBuffer, VkImageView, UInt32) -> Unit]
  vkCmdSetViewportShadingRatePaletteNV : FuncRef[(VkCommandBuffer, UInt32, UInt32, VkShadingRatePaletteNV) -> Unit]
  vkCmdSetCoarseSampleOrderNV : FuncRef[(VkCommandBuffer, UInt32, UInt32, VkCoarseSampleOrderCustomNV) -> Unit]
  vkCmdDrawMeshTasksNV : FuncRef[(VkCommandBuffer, UInt32, UInt32) -> Unit]
  vkCmdDrawMeshTasksIndirectNV : FuncRef[(VkCommandBuffer, VkBuffer, UInt64, UInt32, UInt32) -> Unit]
  vkCmdDrawMeshTasksIndirectCountNV : FuncRef[(VkCommandBuffer, VkBuffer, UInt64, VkBuffer, UInt64, UInt32, UInt32) -> Unit]
  vkCmdDrawMeshTasksEXT : FuncRef[(VkCommandBuffer, UInt32, UInt32, UInt32) -> Unit]
  vkCmdDrawMeshTasksIndirectEXT : FuncRef[(VkCommandBuffer, VkBuffer, UInt64, UInt32, UInt32) -> Unit]
  vkCmdDrawMeshTasksIndirectCountEXT : FuncRef[(VkCommandBuffer, VkBuffer, UInt64, VkBuffer, UInt64, UInt32, UInt32) -> Unit]
  vkCompileDeferredNV : FuncRef[(VkDevice, VkPipeline, UInt32) -> Int32]
  vkCreateAccelerationStructureNV : FuncRef[(VkDevice, VkAccelerationStructureCreateInfoNV, VkAllocationCallbacks, FixedArray[VkAccelerationStructureNV]) -> Int32]
  vkCmdBindInvocationMaskHUAWEI : FuncRef[(VkCommandBuffer, VkImageView, UInt32) -> Unit]
  vkDestroyAccelerationStructureKHR : FuncRef[(VkDevice, VkAccelerationStructureKHR, VkAllocationCallbacks) -> Unit]
  vkDestroyAccelerationStructureNV : FuncRef[(VkDevice, VkAccelerationStructureNV, VkAllocationCallbacks) -> Unit]
  vkGetAccelerationStructureMemoryRequirementsNV : FuncRef[(VkDevice, VkAccelerationStructureMemoryRequirementsInfoNV, VkMemoryRequirements2) -> Unit]
  vkBindAccelerationStructureMemoryNV : FuncRef[(VkDevice, UInt32, VkBindAccelerationStructureMemoryInfoNV) -> Int32]
  vkCmdCopyAccelerationStructureNV : FuncRef[(VkCommandBuffer, VkAccelerationStructureNV, VkAccelerationStructureNV, UInt32) -> Unit]
  vkCmdCopyAccelerationStructureKHR : FuncRef[(VkCommandBuffer, VkCopyAccelerationStructureInfoKHR) -> Unit]
  vkCopyAccelerationStructureKHR : FuncRef[(VkDevice, VkDeferredOperationKHR, VkCopyAccelerationStructureInfoKHR) -> Int32]
  vkCmdCopyAccelerationStructureToMemoryKHR : FuncRef[(VkCommandBuffer, VkCopyAccelerationStructureToMemoryInfoKHR) -> Unit]
  vkCopyAccelerationStructureToMemoryKHR : FuncRef[(VkDevice, VkDeferredOperationKHR, VkCopyAccelerationStructureToMemoryInfoKHR) -> Int32]
  vkCmdCopyMemoryToAccelerationStructureKHR : FuncRef[(VkCommandBuffer, VkCopyMemoryToAccelerationStructureInfoKHR) -> Unit]
  vkCopyMemoryToAccelerationStructureKHR : FuncRef[(VkDevice, VkDeferredOperationKHR, VkCopyMemoryToAccelerationStructureInfoKHR) -> Int32]
  vkCmdWriteAccelerationStructuresPropertiesKHR : FuncRef[(VkCommandBuffer, UInt32, FixedArray[VkAccelerationStructureKHR], UInt32, VkQueryPool, UInt32) -> Unit]
  vkCmdWriteAccelerationStructuresPropertiesNV : FuncRef[(VkCommandBuffer, UInt32, FixedArray[VkAccelerationStructureNV], UInt32, VkQueryPool, UInt32) -> Unit]
  vkCmdBuildAccelerationStructureNV : FuncRef[(VkCommandBuffer, VkAccelerationStructureInfoNV, VkBuffer, UInt64, UInt32, VkAccelerationStructureNV, VkAccelerationStructureNV, VkBuffer, UInt64) -> Unit]
  vkWriteAccelerationStructuresPropertiesKHR : FuncRef[(VkDevice, UInt32, FixedArray[VkAccelerationStructureKHR], UInt32, UInt64, UInt64, UInt64) -> Int32]
  vkCmdTraceRaysKHR : FuncRef[(VkCommandBuffer, VkStridedDeviceAddressRegionKHR, VkStridedDeviceAddressRegionKHR, VkStridedDeviceAddressRegionKHR, VkStridedDeviceAddressRegionKHR, UInt32, UInt32, UInt32) -> Unit]
  vkCmdTraceRaysNV : FuncRef[(VkCommandBuffer, VkBuffer, UInt64, VkBuffer, UInt64, UInt64, VkBuffer, UInt64, UInt64, VkBuffer, UInt64, UInt64, UInt32, UInt32, UInt32) -> Unit]
  vkGetRayTracingShaderGroupHandlesKHR : FuncRef[(VkDevice, VkPipeline, UInt32, UInt32, UInt64, UInt64) -> Int32]
  vkGetRayTracingShaderGroupHandlesNV : FuncRef[(VkDevice, VkPipeline, UInt32, UInt32, UInt64, UInt64) -> Int32]
  vkGetRayTracingCaptureReplayShaderGroupHandlesKHR : FuncRef[(VkDevice, VkPipeline, UInt32, UInt32, UInt64, UInt64) -> Int32]
  vkGetAccelerationStructureHandleNV : FuncRef[(VkDevice, VkAccelerationStructureNV, UInt64, UInt64) -> Int32]
  vkCreateRayTracingPipelinesNV : FuncRef[(VkDevice, VkPipelineCache, UInt32, VkRayTracingPipelineCreateInfoNV, VkAllocationCallbacks, FixedArray[VkPipeline]) -> Int32]
  vkCreateRayTracingPipelinesKHR : FuncRef[(VkDevice, VkDeferredOperationKHR, VkPipelineCache, UInt32, VkRayTracingPipelineCreateInfoKHR, VkAllocationCallbacks, FixedArray[VkPipeline]) -> Int32]
  vkCmdTraceRaysIndirectKHR : FuncRef[(VkCommandBuffer, VkStridedDeviceAddressRegionKHR, VkStridedDeviceAddressRegionKHR, VkStridedDeviceAddressRegionKHR, VkStridedDeviceAddressRegionKHR, UInt64) -> Unit]
  vkCmdTraceRaysIndirect2KHR : FuncRef[(VkCommandBuffer, UInt64) -> Unit]
  vkGetClusterAccelerationStructureBuildSizesNV : FuncRef[(VkDevice, VkClusterAccelerationStructureInputInfoNV, VkAccelerationStructureBuildSizesInfoKHR) -> Unit]
  vkCmdBuildClusterAccelerationStructureIndirectNV : FuncRef[(VkCommandBuffer, VkClusterAccelerationStructureCommandsInfoNV) -> Unit]
  vkGetDeviceAccelerationStructureCompatibilityKHR : FuncRef[(VkDevice, VkAccelerationStructureVersionInfoKHR, FixedArray[UInt32]) -> Unit]
  vkGetRayTracingShaderGroupStackSizeKHR : FuncRef[(VkDevice, VkPipeline, UInt32, UInt32) -> UInt64]
  vkCmdSetRayTracingPipelineStackSizeKHR : FuncRef[(VkCommandBuffer, UInt32) -> Unit]
  vkGetImageViewHandleNVX : FuncRef[(VkDevice, VkImageViewHandleInfoNVX) -> UInt32]
  vkGetImageViewHandle64NVX : FuncRef[(VkDevice, VkImageViewHandleInfoNVX) -> UInt64]
  vkGetImageViewAddressNVX : FuncRef[(VkDevice, VkImageView, VkImageViewAddressPropertiesNVX) -> Int32]
  vkGetDeviceCombinedImageSamplerIndexNVX : FuncRef[(VkDevice, UInt64, UInt64) -> UInt64]
  vkGetDeviceGroupSurfacePresentModes2EXT : FuncRef[(VkDevice, VkPhysicalDeviceSurfaceInfo2KHR, FixedArray[UInt32]) -> Int32]
  vkAcquireFullScreenExclusiveModeEXT : FuncRef[(VkDevice, VkSwapchainKHR) -> Int32]
  vkReleaseFullScreenExclusiveModeEXT : FuncRef[(VkDevice, VkSwapchainKHR) -> Int32]
  vkAcquireProfilingLockKHR : FuncRef[(VkDevice, VkAcquireProfilingLockInfoKHR) -> Int32]
  vkReleaseProfilingLockKHR : FuncRef[(VkDevice) -> Unit]
  vkGetImageDrmFormatModifierPropertiesEXT : FuncRef[(VkDevice, VkImage, VkImageDrmFormatModifierPropertiesEXT) -> Int32]
  vkGetBufferOpaqueCaptureAddress : FuncRef[(VkDevice, VkBufferDeviceAddressInfo) -> UInt64]
  vkGetBufferOpaqueCaptureAddressKHR : FuncRef[(VkDevice, VkBufferDeviceAddressInfo) -> UInt64]
  vkGetBufferDeviceAddress : FuncRef[(VkDevice, VkBufferDeviceAddressInfo) -> UInt64]
  vkGetBufferDeviceAddressKHR : FuncRef[(VkDevice, VkBufferDeviceAddressInfo) -> UInt64]
  vkGetBufferDeviceAddressEXT : FuncRef[(VkDevice, VkBufferDeviceAddressInfo) -> UInt64]
  vkInitializePerformanceApiINTEL : FuncRef[(VkDevice, VkInitializePerformanceApiInfoINTEL) -> Int32]
  vkUninitializePerformanceApiINTEL : FuncRef[(VkDevice) -> Unit]
  vkCmdSetPerformanceMarkerINTEL : FuncRef[(VkCommandBuffer, VkPerformanceMarkerInfoINTEL) -> Int32]
  vkCmdSetPerformanceStreamMarkerINTEL : FuncRef[(VkCommandBuffer, VkPerformanceStreamMarkerInfoINTEL) -> Int32]
  vkCmdSetPerformanceOverrideINTEL : FuncRef[(VkCommandBuffer, VkPerformanceOverrideInfoINTEL) -> Int32]
  vkAcquirePerformanceConfigurationINTEL : FuncRef[(VkDevice, VkPerformanceConfigurationAcquireInfoINTEL, FixedArray[VkPerformanceConfigurationINTEL]) -> Int32]
  vkReleasePerformanceConfigurationINTEL : FuncRef[(VkDevice, VkPerformanceConfigurationINTEL) -> Int32]
  vkQueueSetPerformanceConfigurationINTEL : FuncRef[(VkQueue, VkPerformanceConfigurationINTEL) -> Int32]
  vkGetPerformanceParameterINTEL : FuncRef[(VkDevice, UInt32, VkPerformanceValueINTEL) -> Int32]
  vkGetDeviceMemoryOpaqueCaptureAddress : FuncRef[(VkDevice, VkDeviceMemoryOpaqueCaptureAddressInfo) -> UInt64]
  vkGetDeviceMemoryOpaqueCaptureAddressKHR : FuncRef[(VkDevice, VkDeviceMemoryOpaqueCaptureAddressInfo) -> UInt64]
  vkGetPipelineExecutablePropertiesKHR : FuncRef[(VkDevice, VkPipelineInfoKHR, FixedArray[UInt32], VkPipelineExecutablePropertiesKHR) -> Int32]
  vkGetPipelineExecutableStatisticsKHR : FuncRef[(VkDevice, VkPipelineExecutableInfoKHR, FixedArray[UInt32], VkPipelineExecutableStatisticKHR) -> Int32]
  vkGetPipelineExecutableInternalRepresentationsKHR : FuncRef[(VkDevice, VkPipelineExecutableInfoKHR, FixedArray[UInt32], VkPipelineExecutableInternalRepresentationKHR) -> Int32]
  vkCmdSetLineStipple : FuncRef[(VkCommandBuffer, UInt32, UInt) -> Unit]
  vkCmdSetLineStippleKHR : FuncRef[(VkCommandBuffer, UInt32, UInt) -> Unit]
  vkCmdSetLineStippleEXT : FuncRef[(VkCommandBuffer, UInt32, UInt) -> Unit]
  vkGetFaultData : FuncRef[(VkDevice, UInt32, FixedArray[UInt32], FixedArray[UInt32], VkFaultData) -> Int32]
  vkCreateAccelerationStructureKHR : FuncRef[(VkDevice, VkAccelerationStructureCreateInfoKHR, VkAllocationCallbacks, FixedArray[VkAccelerationStructureKHR]) -> Int32]
  vkCmdBuildAccelerationStructuresKHR : FuncRef[(VkCommandBuffer, UInt32, VkAccelerationStructureBuildGeometryInfoKHR, FixedArray[UInt64]) -> Unit]
  vkCmdBuildAccelerationStructuresIndirectKHR : FuncRef[(VkCommandBuffer, UInt32, VkAccelerationStructureBuildGeometryInfoKHR, FixedArray[UInt64], FixedArray[UInt32], FixedArray[UInt64]) -> Unit]
  vkBuildAccelerationStructuresKHR : FuncRef[(VkDevice, VkDeferredOperationKHR, UInt32, VkAccelerationStructureBuildGeometryInfoKHR, FixedArray[UInt64]) -> Int32]
  vkGetAccelerationStructureDeviceAddressKHR : FuncRef[(VkDevice, VkAccelerationStructureDeviceAddressInfoKHR) -> UInt64]
  vkCreateDeferredOperationKHR : FuncRef[(VkDevice, VkAllocationCallbacks, FixedArray[VkDeferredOperationKHR]) -> Int32]
  vkDestroyDeferredOperationKHR : FuncRef[(VkDevice, VkDeferredOperationKHR, VkAllocationCallbacks) -> Unit]
  vkGetDeferredOperationMaxConcurrencyKHR : FuncRef[(VkDevice, VkDeferredOperationKHR) -> UInt32]
  vkGetDeferredOperationResultKHR : FuncRef[(VkDevice, VkDeferredOperationKHR) -> Int32]
  vkDeferredOperationJoinKHR : FuncRef[(VkDevice, VkDeferredOperationKHR) -> Int32]
  vkGetPipelineIndirectMemoryRequirementsNV : FuncRef[(VkDevice, VkComputePipelineCreateInfo, VkMemoryRequirements2) -> Unit]
  vkGetPipelineIndirectDeviceAddressNV : FuncRef[(VkDevice, VkPipelineIndirectDeviceAddressInfoNV) -> UInt64]
  vkAntiLagUpdateAMD : FuncRef[(VkDevice, VkAntiLagDataAMD) -> Unit]
  vkCmdSetCullMode : FuncRef[(VkCommandBuffer, UInt32) -> Unit]
  vkCmdSetCullModeEXT : FuncRef[(VkCommandBuffer, UInt32) -> Unit]
  vkCmdSetFrontFace : FuncRef[(VkCommandBuffer, UInt32) -> Unit]
  vkCmdSetFrontFaceEXT : FuncRef[(VkCommandBuffer, UInt32) -> Unit]
  vkCmdSetPrimitiveTopology : FuncRef[(VkCommandBuffer, UInt32) -> Unit]
  vkCmdSetPrimitiveTopologyEXT : FuncRef[(VkCommandBuffer, UInt32) -> Unit]
  vkCmdSetViewportWithCount : FuncRef[(VkCommandBuffer, UInt32, VkViewport) -> Unit]
  vkCmdSetViewportWithCountEXT : FuncRef[(VkCommandBuffer, UInt32, VkViewport) -> Unit]
  vkCmdSetScissorWithCount : FuncRef[(VkCommandBuffer, UInt32, VkRect2D) -> Unit]
  vkCmdSetScissorWithCountEXT : FuncRef[(VkCommandBuffer, UInt32, VkRect2D) -> Unit]
  vkCmdBindIndexBuffer2 : FuncRef[(VkCommandBuffer, VkBuffer, UInt64, UInt64, UInt32) -> Unit]
  vkCmdBindIndexBuffer2KHR : FuncRef[(VkCommandBuffer, VkBuffer, UInt64, UInt64, UInt32) -> Unit]
  vkCmdBindVertexBuffers2 : FuncRef[(VkCommandBuffer, UInt32, UInt32, FixedArray[VkBuffer], FixedArray[UInt64], FixedArray[UInt64], FixedArray[UInt64]) -> Unit]
  vkCmdBindVertexBuffers2EXT : FuncRef[(VkCommandBuffer, UInt32, UInt32, FixedArray[VkBuffer], FixedArray[UInt64], FixedArray[UInt64], FixedArray[UInt64]) -> Unit]
  vkCmdSetDepthTestEnable : FuncRef[(VkCommandBuffer, UInt32) -> Unit]
  vkCmdSetDepthTestEnableEXT : FuncRef[(VkCommandBuffer, UInt32) -> Unit]
  vkCmdSetDepthWriteEnable : FuncRef[(VkCommandBuffer, UInt32) -> Unit]
  vkCmdSetDepthWriteEnableEXT : FuncRef[(VkCommandBuffer, UInt32) -> Unit]
  vkCmdSetDepthCompareOp : FuncRef[(VkCommandBuffer, UInt32) -> Unit]
  vkCmdSetDepthCompareOpEXT : FuncRef[(VkCommandBuffer, UInt32) -> Unit]
  vkCmdSetDepthBoundsTestEnable : FuncRef[(VkCommandBuffer, UInt32) -> Unit]
  vkCmdSetDepthBoundsTestEnableEXT : FuncRef[(VkCommandBuffer, UInt32) -> Unit]
  vkCmdSetStencilTestEnable : FuncRef[(VkCommandBuffer, UInt32) -> Unit]
  vkCmdSetStencilTestEnableEXT : FuncRef[(VkCommandBuffer, UInt32) -> Unit]
  vkCmdSetStencilOp : FuncRef[(VkCommandBuffer, UInt32, UInt32, UInt32, UInt32, UInt32) -> Unit]
  vkCmdSetStencilOpEXT : FuncRef[(VkCommandBuffer, UInt32, UInt32, UInt32, UInt32, UInt32) -> Unit]
  vkCmdSetPatchControlPointsEXT : FuncRef[(VkCommandBuffer, UInt32) -> Unit]
  vkCmdSetRasterizerDiscardEnable : FuncRef[(VkCommandBuffer, UInt32) -> Unit]
  vkCmdSetRasterizerDiscardEnableEXT : FuncRef[(VkCommandBuffer, UInt32) -> Unit]
  vkCmdSetDepthBiasEnable : FuncRef[(VkCommandBuffer, UInt32) -> Unit]
  vkCmdSetDepthBiasEnableEXT : FuncRef[(VkCommandBuffer, UInt32) -> Unit]
  vkCmdSetLogicOpEXT : FuncRef[(VkCommandBuffer, UInt32) -> Unit]
  vkCmdSetPrimitiveRestartEnable : FuncRef[(VkCommandBuffer, UInt32) -> Unit]
  vkCmdSetPrimitiveRestartEnableEXT : FuncRef[(VkCommandBuffer, UInt32) -> Unit]
  vkCmdSetTessellationDomainOriginEXT : FuncRef[(VkCommandBuffer, UInt32) -> Unit]
  vkCmdSetDepthClampEnableEXT : FuncRef[(VkCommandBuffer, UInt32) -> Unit]
  vkCmdSetPolygonModeEXT : FuncRef[(VkCommandBuffer, UInt32) -> Unit]
  vkCmdSetRasterizationSamplesEXT : FuncRef[(VkCommandBuffer, UInt32) -> Unit]
  vkCmdSetSampleMaskEXT : FuncRef[(VkCommandBuffer, UInt32, FixedArray[UInt32]) -> Unit]
  vkCmdSetAlphaToCoverageEnableEXT : FuncRef[(VkCommandBuffer, UInt32) -> Unit]
  vkCmdSetAlphaToOneEnableEXT : FuncRef[(VkCommandBuffer, UInt32) -> Unit]
  vkCmdSetLogicOpEnableEXT : FuncRef[(VkCommandBuffer, UInt32) -> Unit]
  vkCmdSetColorBlendEnableEXT : FuncRef[(VkCommandBuffer, UInt32, UInt32, FixedArray[UInt32]) -> Unit]
  vkCmdSetColorBlendEquationEXT : FuncRef[(VkCommandBuffer, UInt32, UInt32, VkColorBlendEquationEXT) -> Unit]
  vkCmdSetColorWriteMaskEXT : FuncRef[(VkCommandBuffer, UInt32, UInt32, FixedArray[UInt32]) -> Unit]
  vkCmdSetRasterizationStreamEXT : FuncRef[(VkCommandBuffer, UInt32) -> Unit]
  vkCmdSetConservativeRasterizationModeEXT : FuncRef[(VkCommandBuffer, UInt32) -> Unit]
  vkCmdSetExtraPrimitiveOverestimationSizeEXT : FuncRef[(VkCommandBuffer, Float) -> Unit]
  vkCmdSetDepthClipEnableEXT : FuncRef[(VkCommandBuffer, UInt32) -> Unit]
  vkCmdSetSampleLocationsEnableEXT : FuncRef[(VkCommandBuffer, UInt32) -> Unit]
  vkCmdSetColorBlendAdvancedEXT : FuncRef[(VkCommandBuffer, UInt32, UInt32, VkColorBlendAdvancedEXT) -> Unit]
  vkCmdSetProvokingVertexModeEXT : FuncRef[(VkCommandBuffer, UInt32) -> Unit]
  vkCmdSetLineRasterizationModeEXT : FuncRef[(VkCommandBuffer, UInt32) -> Unit]
  vkCmdSetLineStippleEnableEXT : FuncRef[(VkCommandBuffer, UInt32) -> Unit]
  vkCmdSetDepthClipNegativeOneToOneEXT : FuncRef[(VkCommandBuffer, UInt32) -> Unit]
  vkCmdSetViewportWScalingEnableNV : FuncRef[(VkCommandBuffer, UInt32) -> Unit]
  vkCmdSetViewportSwizzleNV : FuncRef[(VkCommandBuffer, UInt32, UInt32, VkViewportSwizzleNV) -> Unit]
  vkCmdSetCoverageToColorEnableNV : FuncRef[(VkCommandBuffer, UInt32) -> Unit]
  vkCmdSetCoverageToColorLocationNV : FuncRef[(VkCommandBuffer, UInt32) -> Unit]
  vkCmdSetCoverageModulationModeNV : FuncRef[(VkCommandBuffer, UInt32) -> Unit]
  vkCmdSetCoverageModulationTableEnableNV : FuncRef[(VkCommandBuffer, UInt32) -> Unit]
  vkCmdSetCoverageModulationTableNV : FuncRef[(VkCommandBuffer, UInt32, FixedArray[Float]) -> Unit]
  vkCmdSetShadingRateImageEnableNV : FuncRef[(VkCommandBuffer, UInt32) -> Unit]
  vkCmdSetCoverageReductionModeNV : FuncRef[(VkCommandBuffer, UInt32) -> Unit]
  vkCmdSetRepresentativeFragmentTestEnableNV : FuncRef[(VkCommandBuffer, UInt32) -> Unit]
  vkCreatePrivateDataSlot : FuncRef[(VkDevice, VkPrivateDataSlotCreateInfo, VkAllocationCallbacks, FixedArray[VkPrivateDataSlot]) -> Int32]
  vkCreatePrivateDataSlotEXT : FuncRef[(VkDevice, VkPrivateDataSlotCreateInfo, VkAllocationCallbacks, FixedArray[VkPrivateDataSlot]) -> Int32]
  vkDestroyPrivateDataSlot : FuncRef[(VkDevice, VkPrivateDataSlot, VkAllocationCallbacks) -> Unit]
  vkDestroyPrivateDataSlotEXT : FuncRef[(VkDevice, VkPrivateDataSlot, VkAllocationCallbacks) -> Unit]
  vkSetPrivateData : FuncRef[(VkDevice, UInt32, UInt64, VkPrivateDataSlot, UInt64) -> Int32]
  vkSetPrivateDataEXT : FuncRef[(VkDevice, UInt32, UInt64, VkPrivateDataSlot, UInt64) -> Int32]
  vkGetPrivateData : FuncRef[(VkDevice, UInt32, UInt64, VkPrivateDataSlot, FixedArray[UInt64]) -> Unit]
  vkGetPrivateDataEXT : FuncRef[(VkDevice, UInt32, UInt64, VkPrivateDataSlot, FixedArray[UInt64]) -> Unit]
  vkCmdCopyBuffer2 : FuncRef[(VkCommandBuffer, VkCopyBufferInfo2) -> Unit]
  vkCmdCopyBuffer2KHR : FuncRef[(VkCommandBuffer, VkCopyBufferInfo2) -> Unit]
  vkCmdCopyImage2 : FuncRef[(VkCommandBuffer, VkCopyImageInfo2) -> Unit]
  vkCmdCopyImage2KHR : FuncRef[(VkCommandBuffer, VkCopyImageInfo2) -> Unit]
  vkCmdBlitImage2 : FuncRef[(VkCommandBuffer, VkBlitImageInfo2) -> Unit]
  vkCmdBlitImage2KHR : FuncRef[(VkCommandBuffer, VkBlitImageInfo2) -> Unit]
  vkCmdCopyBufferToImage2 : FuncRef[(VkCommandBuffer, VkCopyBufferToImageInfo2) -> Unit]
  vkCmdCopyBufferToImage2KHR : FuncRef[(VkCommandBuffer, VkCopyBufferToImageInfo2) -> Unit]
  vkCmdCopyImageToBuffer2 : FuncRef[(VkCommandBuffer, VkCopyImageToBufferInfo2) -> Unit]
  vkCmdCopyImageToBuffer2KHR : FuncRef[(VkCommandBuffer, VkCopyImageToBufferInfo2) -> Unit]
  vkCmdResolveImage2 : FuncRef[(VkCommandBuffer, VkResolveImageInfo2) -> Unit]
  vkCmdResolveImage2KHR : FuncRef[(VkCommandBuffer, VkResolveImageInfo2) -> Unit]
  vkCmdRefreshObjectsKHR : FuncRef[(VkCommandBuffer, VkRefreshObjectListKHR) -> Unit]
  vkCmdSetFragmentShadingRateKHR : FuncRef[(VkCommandBuffer, VkExtent2D, FixedArray[UInt32]) -> Unit]
  vkCmdSetFragmentShadingRateEnumNV : FuncRef[(VkCommandBuffer, UInt32, FixedArray[UInt32]) -> Unit]
  vkGetAccelerationStructureBuildSizesKHR : FuncRef[(VkDevice, UInt32, VkAccelerationStructureBuildGeometryInfoKHR, FixedArray[UInt32], VkAccelerationStructureBuildSizesInfoKHR) -> Unit]
  vkCmdSetVertexInputEXT : FuncRef[(VkCommandBuffer, UInt32, VkVertexInputBindingDescription2EXT, UInt32, VkVertexInputAttributeDescription2EXT) -> Unit]
  vkCmdSetColorWriteEnableEXT : FuncRef[(VkCommandBuffer, UInt32, FixedArray[UInt32]) -> Unit]
  vkCmdSetEvent2 : FuncRef[(VkCommandBuffer, VkEvent, VkDependencyInfo) -> Unit]
  vkCmdSetEvent2KHR : FuncRef[(VkCommandBuffer, VkEvent, VkDependencyInfo) -> Unit]
  vkCmdResetEvent2 : FuncRef[(VkCommandBuffer, VkEvent, UInt64) -> Unit]
  vkCmdResetEvent2KHR : FuncRef[(VkCommandBuffer, VkEvent, UInt64) -> Unit]
  vkCmdWaitEvents2 : FuncRef[(VkCommandBuffer, UInt32, FixedArray[VkEvent], VkDependencyInfo) -> Unit]
  vkCmdWaitEvents2KHR : FuncRef[(VkCommandBuffer, UInt32, FixedArray[VkEvent], VkDependencyInfo) -> Unit]
  vkCmdPipelineBarrier2 : FuncRef[(VkCommandBuffer, VkDependencyInfo) -> Unit]
  vkCmdPipelineBarrier2KHR : FuncRef[(VkCommandBuffer, VkDependencyInfo) -> Unit]
  vkQueueSubmit2 : FuncRef[(VkQueue, UInt32, VkSubmitInfo2, VkFence) -> Int32]
  vkQueueSubmit2KHR : FuncRef[(VkQueue, UInt32, VkSubmitInfo2, VkFence) -> Int32]
  vkCmdWriteTimestamp2 : FuncRef[(VkCommandBuffer, UInt64, VkQueryPool, UInt32) -> Unit]
  vkCmdWriteTimestamp2KHR : FuncRef[(VkCommandBuffer, UInt64, VkQueryPool, UInt32) -> Unit]
  vkCmdWriteBufferMarker2AMD : FuncRef[(VkCommandBuffer, UInt64, VkBuffer, UInt64, UInt32) -> Unit]
  vkGetQueueCheckpointData2NV : FuncRef[(VkQueue, FixedArray[UInt32], VkCheckpointData2NV) -> Unit]
  vkCopyMemoryToImage : FuncRef[(VkDevice, VkCopyMemoryToImageInfo) -> Int32]
  vkCopyMemoryToImageEXT : FuncRef[(VkDevice, VkCopyMemoryToImageInfo) -> Int32]
  vkCopyImageToMemory : FuncRef[(VkDevice, VkCopyImageToMemoryInfo) -> Int32]
  vkCopyImageToMemoryEXT : FuncRef[(VkDevice, VkCopyImageToMemoryInfo) -> Int32]
  vkCopyImageToImage : FuncRef[(VkDevice, VkCopyImageToImageInfo) -> Int32]
  vkCopyImageToImageEXT : FuncRef[(VkDevice, VkCopyImageToImageInfo) -> Int32]
  vkTransitionImageLayout : FuncRef[(VkDevice, UInt32, VkHostImageLayoutTransitionInfo) -> Int32]
  vkTransitionImageLayoutEXT : FuncRef[(VkDevice, UInt32, VkHostImageLayoutTransitionInfo) -> Int32]
  vkGetCommandPoolMemoryConsumption : FuncRef[(VkDevice, VkCommandPool, VkCommandBuffer, VkCommandPoolMemoryConsumption) -> Unit]
  vkCreateVideoSessionKHR : FuncRef[(VkDevice, VkVideoSessionCreateInfoKHR, VkAllocationCallbacks, FixedArray[VkVideoSessionKHR]) -> Int32]
  vkDestroyVideoSessionKHR : FuncRef[(VkDevice, VkVideoSessionKHR, VkAllocationCallbacks) -> Unit]
  vkCreateVideoSessionParametersKHR : FuncRef[(VkDevice, VkVideoSessionParametersCreateInfoKHR, VkAllocationCallbacks, FixedArray[VkVideoSessionParametersKHR]) -> Int32]
  vkUpdateVideoSessionParametersKHR : FuncRef[(VkDevice, VkVideoSessionParametersKHR, VkVideoSessionParametersUpdateInfoKHR) -> Int32]
  vkGetEncodedVideoSessionParametersKHR : FuncRef[(VkDevice, VkVideoEncodeSessionParametersGetInfoKHR, VkVideoEncodeSessionParametersFeedbackInfoKHR, FixedArray[UInt64], UInt64) -> Int32]
  vkDestroyVideoSessionParametersKHR : FuncRef[(VkDevice, VkVideoSessionParametersKHR, VkAllocationCallbacks) -> Unit]
  vkGetVideoSessionMemoryRequirementsKHR : FuncRef[(VkDevice, VkVideoSessionKHR, FixedArray[UInt32], VkVideoSessionMemoryRequirementsKHR) -> Int32]
  vkBindVideoSessionMemoryKHR : FuncRef[(VkDevice, VkVideoSessionKHR, UInt32, VkBindVideoSessionMemoryInfoKHR) -> Int32]
  vkCmdDecodeVideoKHR : FuncRef[(VkCommandBuffer, VkVideoDecodeInfoKHR) -> Unit]
  vkCmdBeginVideoCodingKHR : FuncRef[(VkCommandBuffer, VkVideoBeginCodingInfoKHR) -> Unit]
  vkCmdControlVideoCodingKHR : FuncRef[(VkCommandBuffer, VkVideoCodingControlInfoKHR) -> Unit]
  vkCmdEndVideoCodingKHR : FuncRef[(VkCommandBuffer, VkVideoEndCodingInfoKHR) -> Unit]
  vkCmdEncodeVideoKHR : FuncRef[(VkCommandBuffer, VkVideoEncodeInfoKHR) -> Unit]
  vkCmdDecompressMemoryNV : FuncRef[(VkCommandBuffer, UInt32, VkDecompressMemoryRegionNV) -> Unit]
  vkCmdDecompressMemoryIndirectCountNV : FuncRef[(VkCommandBuffer, UInt64, UInt64, UInt32) -> Unit]
  vkGetPartitionedAccelerationStructuresBuildSizesNV : FuncRef[(VkDevice, VkPartitionedAccelerationStructureInstancesInputNV, VkAccelerationStructureBuildSizesInfoKHR) -> Unit]
  vkCmdBuildPartitionedAccelerationStructuresNV : FuncRef[(VkCommandBuffer, VkBuildPartitionedAccelerationStructureInfoNV) -> Unit]
  vkCmdDecompressMemoryEXT : FuncRef[(VkCommandBuffer, VkDecompressMemoryInfoEXT) -> Unit]
  vkCmdDecompressMemoryIndirectCountEXT : FuncRef[(VkCommandBuffer, UInt64, UInt64, UInt64, UInt32, UInt32) -> Unit]
  vkCreateCuModuleNVX : FuncRef[(VkDevice, VkCuModuleCreateInfoNVX, VkAllocationCallbacks, FixedArray[VkCuModuleNVX]) -> Int32]
  vkCreateCuFunctionNVX : FuncRef[(VkDevice, VkCuFunctionCreateInfoNVX, VkAllocationCallbacks, FixedArray[VkCuFunctionNVX]) -> Int32]
  vkDestroyCuModuleNVX : FuncRef[(VkDevice, VkCuModuleNVX, VkAllocationCallbacks) -> Unit]
  vkDestroyCuFunctionNVX : FuncRef[(VkDevice, VkCuFunctionNVX, VkAllocationCallbacks) -> Unit]
  vkCmdCuLaunchKernelNVX : FuncRef[(VkCommandBuffer, VkCuLaunchInfoNVX) -> Unit]
  vkGetDescriptorSetLayoutSizeEXT : FuncRef[(VkDevice, VkDescriptorSetLayout, FixedArray[UInt64]) -> Unit]
  vkGetDescriptorSetLayoutBindingOffsetEXT : FuncRef[(VkDevice, VkDescriptorSetLayout, UInt32, FixedArray[UInt64]) -> Unit]
  vkGetDescriptorEXT : FuncRef[(VkDevice, VkDescriptorGetInfoEXT, UInt64, UInt64) -> Unit]
  vkCmdBindDescriptorBuffersEXT : FuncRef[(VkCommandBuffer, UInt32, VkDescriptorBufferBindingInfoEXT) -> Unit]
  vkCmdSetDescriptorBufferOffsetsEXT : FuncRef[(VkCommandBuffer, UInt32, VkPipelineLayout, UInt32, UInt32, FixedArray[UInt32], FixedArray[UInt64]) -> Unit]
  vkCmdBindDescriptorBufferEmbeddedSamplersEXT : FuncRef[(VkCommandBuffer, UInt32, VkPipelineLayout, UInt32) -> Unit]
  vkGetBufferOpaqueCaptureDescriptorDataEXT : FuncRef[(VkDevice, VkBufferCaptureDescriptorDataInfoEXT, UInt64) -> Int32]
  vkGetImageOpaqueCaptureDescriptorDataEXT : FuncRef[(VkDevice, VkImageCaptureDescriptorDataInfoEXT, UInt64) -> Int32]
  vkGetImageViewOpaqueCaptureDescriptorDataEXT : FuncRef[(VkDevice, VkImageViewCaptureDescriptorDataInfoEXT, UInt64) -> Int32]
  vkGetSamplerOpaqueCaptureDescriptorDataEXT : FuncRef[(VkDevice, VkSamplerCaptureDescriptorDataInfoEXT, UInt64) -> Int32]
  vkGetAccelerationStructureOpaqueCaptureDescriptorDataEXT : FuncRef[(VkDevice, VkAccelerationStructureCaptureDescriptorDataInfoEXT, UInt64) -> Int32]
  vkSetDeviceMemoryPriorityEXT : FuncRef[(VkDevice, VkDeviceMemory, Float) -> Unit]
  vkWaitForPresent2KHR : FuncRef[(VkDevice, VkSwapchainKHR, VkPresentWait2InfoKHR) -> Int32]
  vkWaitForPresentKHR : FuncRef[(VkDevice, VkSwapchainKHR, UInt64, UInt64) -> Int32]
  vkCreateBufferCollectionFUCHSIA : FuncRef[(VkDevice, VkBufferCollectionCreateInfoFUCHSIA, VkAllocationCallbacks, FixedArray[VkBufferCollectionFUCHSIA]) -> Int32]
  vkSetBufferCollectionBufferConstraintsFUCHSIA : FuncRef[(VkDevice, VkBufferCollectionFUCHSIA, VkBufferConstraintsInfoFUCHSIA) -> Int32]
  vkSetBufferCollectionImageConstraintsFUCHSIA : FuncRef[(VkDevice, VkBufferCollectionFUCHSIA, VkImageConstraintsInfoFUCHSIA) -> Int32]
  vkDestroyBufferCollectionFUCHSIA : FuncRef[(VkDevice, VkBufferCollectionFUCHSIA, VkAllocationCallbacks) -> Unit]
  vkGetBufferCollectionPropertiesFUCHSIA : FuncRef[(VkDevice, VkBufferCollectionFUCHSIA, VkBufferCollectionPropertiesFUCHSIA) -> Int32]
  vkCreateCudaModuleNV : FuncRef[(VkDevice, VkCudaModuleCreateInfoNV, VkAllocationCallbacks, FixedArray[VkCudaModuleNV]) -> Int32]
  vkGetCudaModuleCacheNV : FuncRef[(VkDevice, VkCudaModuleNV, FixedArray[UInt64], UInt64) -> Int32]
  vkCreateCudaFunctionNV : FuncRef[(VkDevice, VkCudaFunctionCreateInfoNV, VkAllocationCallbacks, FixedArray[VkCudaFunctionNV]) -> Int32]
  vkDestroyCudaModuleNV : FuncRef[(VkDevice, VkCudaModuleNV, VkAllocationCallbacks) -> Unit]
  vkDestroyCudaFunctionNV : FuncRef[(VkDevice, VkCudaFunctionNV, VkAllocationCallbacks) -> Unit]
  vkCmdCudaLaunchKernelNV : FuncRef[(VkCommandBuffer, VkCudaLaunchInfoNV) -> Unit]
  vkCmdBeginRendering : FuncRef[(VkCommandBuffer, VkRenderingInfo) -> Unit]
  vkCmdBeginRenderingKHR : FuncRef[(VkCommandBuffer, VkRenderingInfo) -> Unit]
  vkCmdEndRendering : FuncRef[(VkCommandBuffer) -> Unit]
  vkCmdEndRendering2KHR : FuncRef[(VkCommandBuffer, VkRenderingEndInfoKHR) -> Unit]
  vkCmdEndRendering2EXT : FuncRef[(VkCommandBuffer, VkRenderingEndInfoKHR) -> Unit]
  vkCmdEndRenderingKHR : FuncRef[(VkCommandBuffer) -> Unit]
  vkGetDescriptorSetLayoutHostMappingInfoVALVE : FuncRef[(VkDevice, VkDescriptorSetBindingReferenceVALVE, VkDescriptorSetLayoutHostMappingInfoVALVE) -> Unit]
  vkGetDescriptorSetHostMappingVALVE : FuncRef[(VkDevice, VkDescriptorSet, FixedArray[UInt64]) -> Unit]
  vkCreateMicromapEXT : FuncRef[(VkDevice, VkMicromapCreateInfoEXT, VkAllocationCallbacks, FixedArray[VkMicromapEXT]) -> Int32]
  vkCmdBuildMicromapsEXT : FuncRef[(VkCommandBuffer, UInt32, VkMicromapBuildInfoEXT) -> Unit]
  vkBuildMicromapsEXT : FuncRef[(VkDevice, VkDeferredOperationKHR, UInt32, VkMicromapBuildInfoEXT) -> Int32]
  vkDestroyMicromapEXT : FuncRef[(VkDevice, VkMicromapEXT, VkAllocationCallbacks) -> Unit]
  vkCmdCopyMicromapEXT : FuncRef[(VkCommandBuffer, VkCopyMicromapInfoEXT) -> Unit]
  vkCopyMicromapEXT : FuncRef[(VkDevice, VkDeferredOperationKHR, VkCopyMicromapInfoEXT) -> Int32]
  vkCmdCopyMicromapToMemoryEXT : FuncRef[(VkCommandBuffer, VkCopyMicromapToMemoryInfoEXT) -> Unit]
  vkCopyMicromapToMemoryEXT : FuncRef[(VkDevice, VkDeferredOperationKHR, VkCopyMicromapToMemoryInfoEXT) -> Int32]
  vkCmdCopyMemoryToMicromapEXT : FuncRef[(VkCommandBuffer, VkCopyMemoryToMicromapInfoEXT) -> Unit]
  vkCopyMemoryToMicromapEXT : FuncRef[(VkDevice, VkDeferredOperationKHR, VkCopyMemoryToMicromapInfoEXT) -> Int32]
  vkCmdWriteMicromapsPropertiesEXT : FuncRef[(VkCommandBuffer, UInt32, FixedArray[VkMicromapEXT], UInt32, VkQueryPool, UInt32) -> Unit]
  vkWriteMicromapsPropertiesEXT : FuncRef[(VkDevice, UInt32, FixedArray[VkMicromapEXT], UInt32, UInt64, UInt64, UInt64) -> Int32]
  vkGetDeviceMicromapCompatibilityEXT : FuncRef[(VkDevice, VkMicromapVersionInfoEXT, FixedArray[UInt32]) -> Unit]
  vkGetMicromapBuildSizesEXT : FuncRef[(VkDevice, UInt32, VkMicromapBuildInfoEXT, VkMicromapBuildSizesInfoEXT) -> Unit]
  vkGetShaderModuleIdentifierEXT : FuncRef[(VkDevice, VkShaderModule, VkShaderModuleIdentifierEXT) -> Unit]
  vkGetShaderModuleCreateInfoIdentifierEXT : FuncRef[(VkDevice, VkShaderModuleCreateInfo, VkShaderModuleIdentifierEXT) -> Unit]
  vkGetImageSubresourceLayout2 : FuncRef[(VkDevice, VkImage, VkImageSubresource2, VkSubresourceLayout2) -> Unit]
  vkGetImageSubresourceLayout2KHR : FuncRef[(VkDevice, VkImage, VkImageSubresource2, VkSubresourceLayout2) -> Unit]
  vkGetImageSubresourceLayout2EXT : FuncRef[(VkDevice, VkImage, VkImageSubresource2, VkSubresourceLayout2) -> Unit]
  vkGetPipelinePropertiesEXT : FuncRef[(VkDevice, VkPipelineInfoKHR, VkBaseOutStructure) -> Int32]
  vkExportMetalObjectsEXT : FuncRef[(VkDevice, VkExportMetalObjectsInfoEXT) -> Unit]
  vkCmdBindTileMemoryQCOM : FuncRef[(VkCommandBuffer, VkTileMemoryBindInfoQCOM) -> Unit]
  vkGetFramebufferTilePropertiesQCOM : FuncRef[(VkDevice, VkFramebuffer, FixedArray[UInt32], VkTilePropertiesQCOM) -> Int32]
  vkGetDynamicRenderingTilePropertiesQCOM : FuncRef[(VkDevice, VkRenderingInfo, VkTilePropertiesQCOM) -> Int32]
  vkCreateOpticalFlowSessionNV : FuncRef[(VkDevice, VkOpticalFlowSessionCreateInfoNV, VkAllocationCallbacks, FixedArray[VkOpticalFlowSessionNV]) -> Int32]
  vkDestroyOpticalFlowSessionNV : FuncRef[(VkDevice, VkOpticalFlowSessionNV, VkAllocationCallbacks) -> Unit]
  vkBindOpticalFlowSessionImageNV : FuncRef[(VkDevice, VkOpticalFlowSessionNV, UInt32, VkImageView, UInt32) -> Int32]
  vkCmdOpticalFlowExecuteNV : FuncRef[(VkCommandBuffer, VkOpticalFlowSessionNV, VkOpticalFlowExecuteInfoNV) -> Unit]
  vkGetDeviceFaultInfoEXT : FuncRef[(VkDevice, VkDeviceFaultCountsEXT, VkDeviceFaultInfoEXT) -> Int32]
  vkGetDeviceFaultReportsKHR : FuncRef[(VkDevice, UInt64, FixedArray[UInt32], VkDeviceFaultInfoKHR) -> Int32]
  vkGetDeviceFaultDebugInfoKHR : FuncRef[(VkDevice, VkDeviceFaultDebugInfoKHR) -> Int32]
  vkCmdSetDepthBias2EXT : FuncRef[(VkCommandBuffer, VkDepthBiasInfoEXT) -> Unit]
  vkReleaseSwapchainImagesKHR : FuncRef[(VkDevice, VkReleaseSwapchainImagesInfoKHR) -> Int32]
  vkReleaseSwapchainImagesEXT : FuncRef[(VkDevice, VkReleaseSwapchainImagesInfoKHR) -> Int32]
  vkGetDeviceImageSubresourceLayout : FuncRef[(VkDevice, VkDeviceImageSubresourceInfo, VkSubresourceLayout2) -> Unit]
  vkGetDeviceImageSubresourceLayoutKHR : FuncRef[(VkDevice, VkDeviceImageSubresourceInfo, VkSubresourceLayout2) -> Unit]
  vkMapMemory2 : FuncRef[(VkDevice, VkMemoryMapInfo, FixedArray[UInt64]) -> Int32]
  vkMapMemory2KHR : FuncRef[(VkDevice, VkMemoryMapInfo, FixedArray[UInt64]) -> Int32]
  vkUnmapMemory2 : FuncRef[(VkDevice, VkMemoryUnmapInfo) -> Int32]
  vkUnmapMemory2KHR : FuncRef[(VkDevice, VkMemoryUnmapInfo) -> Int32]
  vkCreateShadersEXT : FuncRef[(VkDevice, UInt32, VkShaderCreateInfoEXT, VkAllocationCallbacks, FixedArray[VkShaderEXT]) -> Int32]
  vkDestroyShaderEXT : FuncRef[(VkDevice, VkShaderEXT, VkAllocationCallbacks) -> Unit]
  vkGetShaderBinaryDataEXT : FuncRef[(VkDevice, VkShaderEXT, FixedArray[UInt64], UInt64) -> Int32]
  vkCmdBindShadersEXT : FuncRef[(VkCommandBuffer, UInt32, FixedArray[UInt32], FixedArray[VkShaderEXT]) -> Unit]
  vkSetSwapchainPresentTimingQueueSizeEXT : FuncRef[(VkDevice, VkSwapchainKHR, UInt32) -> Int32]
  vkGetSwapchainTimingPropertiesEXT : FuncRef[(VkDevice, VkSwapchainKHR, VkSwapchainTimingPropertiesEXT, FixedArray[UInt64]) -> Int32]
  vkGetSwapchainTimeDomainPropertiesEXT : FuncRef[(VkDevice, VkSwapchainKHR, VkSwapchainTimeDomainPropertiesEXT, FixedArray[UInt64]) -> Int32]
  vkGetPastPresentationTimingEXT : FuncRef[(VkDevice, VkPastPresentationTimingInfoEXT, VkPastPresentationTimingPropertiesEXT) -> Int32]
  vkGetScreenBufferPropertiesQNX : FuncRef[(VkDevice, UInt64, VkScreenBufferPropertiesQNX) -> Int32]
  vkGetExecutionGraphPipelineScratchSizeAMDX : FuncRef[(VkDevice, VkPipeline, VkExecutionGraphPipelineScratchSizeAMDX) -> Int32]
  vkGetExecutionGraphPipelineNodeIndexAMDX : FuncRef[(VkDevice, VkPipeline, VkPipelineShaderStageNodeCreateInfoAMDX, FixedArray[UInt32]) -> Int32]
  vkCreateExecutionGraphPipelinesAMDX : FuncRef[(VkDevice, VkPipelineCache, UInt32, VkExecutionGraphPipelineCreateInfoAMDX, VkAllocationCallbacks, FixedArray[VkPipeline]) -> Int32]
  vkCmdInitializeGraphScratchMemoryAMDX : FuncRef[(VkCommandBuffer, VkPipeline, UInt64, UInt64) -> Unit]
  vkCmdDispatchGraphAMDX : FuncRef[(VkCommandBuffer, UInt64, UInt64, VkDispatchGraphCountInfoAMDX) -> Unit]
  vkCmdDispatchGraphIndirectAMDX : FuncRef[(VkCommandBuffer, UInt64, UInt64, VkDispatchGraphCountInfoAMDX) -> Unit]
  vkCmdDispatchGraphIndirectCountAMDX : FuncRef[(VkCommandBuffer, UInt64, UInt64, UInt64) -> Unit]
  vkCreateGpaSessionAMD : FuncRef[(VkDevice, VkGpaSessionCreateInfoAMD, VkAllocationCallbacks, FixedArray[VkGpaSessionAMD]) -> Int32]
  vkDestroyGpaSessionAMD : FuncRef[(VkDevice, VkGpaSessionAMD, VkAllocationCallbacks) -> Unit]
  vkSetGpaDeviceClockModeAMD : FuncRef[(VkDevice, VkGpaDeviceClockModeInfoAMD) -> Int32]
  vkGetGpaDeviceClockInfoAMD : FuncRef[(VkDevice, VkGpaDeviceGetClockInfoAMD) -> Int32]
  vkCmdBeginGpaSessionAMD : FuncRef[(VkCommandBuffer, VkGpaSessionAMD) -> Int32]
  vkCmdEndGpaSessionAMD : FuncRef[(VkCommandBuffer, VkGpaSessionAMD) -> Int32]
  vkCmdBeginGpaSampleAMD : FuncRef[(VkCommandBuffer, VkGpaSessionAMD, VkGpaSampleBeginInfoAMD, FixedArray[UInt32]) -> Int32]
  vkCmdEndGpaSampleAMD : FuncRef[(VkCommandBuffer, VkGpaSessionAMD, UInt32) -> Unit]
  vkGetGpaSessionStatusAMD : FuncRef[(VkDevice, VkGpaSessionAMD) -> Int32]
  vkGetGpaSessionResultsAMD : FuncRef[(VkDevice, VkGpaSessionAMD, UInt32, FixedArray[UInt64], UInt64) -> Int32]
  vkResetGpaSessionAMD : FuncRef[(VkDevice, VkGpaSessionAMD) -> Int32]
  vkCmdCopyGpaSessionResultsAMD : FuncRef[(VkCommandBuffer, VkGpaSessionAMD) -> Unit]
  vkCmdBindDescriptorSets2 : FuncRef[(VkCommandBuffer, VkBindDescriptorSetsInfo) -> Unit]
  vkCmdBindDescriptorSets2KHR : FuncRef[(VkCommandBuffer, VkBindDescriptorSetsInfo) -> Unit]
  vkCmdPushConstants2 : FuncRef[(VkCommandBuffer, VkPushConstantsInfo) -> Unit]
  vkCmdPushConstants2KHR : FuncRef[(VkCommandBuffer, VkPushConstantsInfo) -> Unit]
  vkCmdPushDescriptorSet2 : FuncRef[(VkCommandBuffer, VkPushDescriptorSetInfo) -> Unit]
  vkCmdPushDescriptorSet2KHR : FuncRef[(VkCommandBuffer, VkPushDescriptorSetInfo) -> Unit]
  vkCmdPushDescriptorSetWithTemplate2 : FuncRef[(VkCommandBuffer, VkPushDescriptorSetWithTemplateInfo) -> Unit]
  vkCmdPushDescriptorSetWithTemplate2KHR : FuncRef[(VkCommandBuffer, VkPushDescriptorSetWithTemplateInfo) -> Unit]
  vkCmdSetDescriptorBufferOffsets2EXT : FuncRef[(VkCommandBuffer, VkSetDescriptorBufferOffsetsInfoEXT) -> Unit]
  vkCmdBindDescriptorBufferEmbeddedSamplers2EXT : FuncRef[(VkCommandBuffer, VkBindDescriptorBufferEmbeddedSamplersInfoEXT) -> Unit]
  vkSetLatencySleepModeNV : FuncRef[(VkDevice, VkSwapchainKHR, VkLatencySleepModeInfoNV) -> Int32]
  vkLatencySleepNV : FuncRef[(VkDevice, VkSwapchainKHR, VkLatencySleepInfoNV) -> Int32]
  vkSetLatencyMarkerNV : FuncRef[(VkDevice, VkSwapchainKHR, VkSetLatencyMarkerInfoNV) -> Unit]
  vkGetLatencyTimingsNV : FuncRef[(VkDevice, VkSwapchainKHR, VkGetLatencyMarkerInfoNV) -> Unit]
  vkQueueNotifyOutOfBandNV : FuncRef[(VkQueue, VkOutOfBandQueueTypeInfoNV) -> Unit]
  vkSetLatencySleepModeLegacyNV : FuncRef[(VkDevice, UInt32, UInt32, UInt32) -> Unit]
  vkLatencySleepLegacyNV : FuncRef[(VkDevice, VkSemaphore, UInt64) -> Unit]
  vkSetLatencyMarkerLegacyNV : FuncRef[(VkDevice, UInt64, UInt32) -> Unit]
  vkGetLatencyTimingsLegacyNV : FuncRef[(VkDevice, UInt64) -> Unit]
  vkQueueNotifyOutOfBandLegacyNV : FuncRef[(VkQueue, UInt32) -> Unit]
  vkGetSleepStatusLegacyNV : FuncRef[(VkDevice, FixedArray[UInt32]) -> Unit]
  vkShutdownLatencyDeviceLegacyNV : FuncRef[(VkDevice) -> Unit]
  vkCmdSetRenderingAttachmentLocations : FuncRef[(VkCommandBuffer, VkRenderingAttachmentLocationInfo) -> Unit]
  vkCmdSetRenderingAttachmentLocationsKHR : FuncRef[(VkCommandBuffer, VkRenderingAttachmentLocationInfo) -> Unit]
  vkCmdSetRenderingInputAttachmentIndices : FuncRef[(VkCommandBuffer, VkRenderingInputAttachmentIndexInfo) -> Unit]
  vkCmdSetRenderingInputAttachmentIndicesKHR : FuncRef[(VkCommandBuffer, VkRenderingInputAttachmentIndexInfo) -> Unit]
  vkCmdSetDepthClampRangeEXT : FuncRef[(VkCommandBuffer, UInt32, VkDepthClampRangeEXT) -> Unit]
  vkGetMemoryMetalHandleEXT : FuncRef[(VkDevice, VkMemoryGetMetalHandleInfoEXT, FixedArray[UInt64]) -> Int32]
  vkGetMemoryMetalHandlePropertiesEXT : FuncRef[(VkDevice, UInt32, UInt64, VkMemoryMetalHandlePropertiesEXT) -> Int32]
  vkConvertCooperativeVectorMatrixNV : FuncRef[(VkDevice, VkConvertCooperativeVectorMatrixInfoNV) -> Int32]
  vkCmdConvertCooperativeVectorMatrixNV : FuncRef[(VkCommandBuffer, UInt32, VkConvertCooperativeVectorMatrixInfoNV) -> Unit]
  vkCmdDispatchTileQCOM : FuncRef[(VkCommandBuffer, VkDispatchTileInfoQCOM) -> Unit]
  vkCmdBeginPerTileExecutionQCOM : FuncRef[(VkCommandBuffer, VkPerTileBeginInfoQCOM) -> Unit]
  vkCmdEndPerTileExecutionQCOM : FuncRef[(VkCommandBuffer, VkPerTileEndInfoQCOM) -> Unit]
  vkCreateExternalComputeQueueNV : FuncRef[(VkDevice, VkExternalComputeQueueCreateInfoNV, VkAllocationCallbacks, FixedArray[VkExternalComputeQueueNV]) -> Int32]
  vkDestroyExternalComputeQueueNV : FuncRef[(VkDevice, VkExternalComputeQueueNV, VkAllocationCallbacks) -> Unit]
  vkCreateShaderInstrumentationARM : FuncRef[(VkDevice, VkShaderInstrumentationCreateInfoARM, VkAllocationCallbacks, FixedArray[VkShaderInstrumentationARM]) -> Int32]
  vkDestroyShaderInstrumentationARM : FuncRef[(VkDevice, VkShaderInstrumentationARM, VkAllocationCallbacks) -> Unit]
  vkCmdBeginShaderInstrumentationARM : FuncRef[(VkCommandBuffer, VkShaderInstrumentationARM) -> Unit]
  vkCmdEndShaderInstrumentationARM : FuncRef[(VkCommandBuffer) -> Unit]
  vkGetShaderInstrumentationValuesARM : FuncRef[(VkDevice, VkShaderInstrumentationARM, FixedArray[UInt32], UInt64, UInt32) -> Int32]
  vkClearShaderInstrumentationMetricsARM : FuncRef[(VkDevice, VkShaderInstrumentationARM) -> Unit]
  vkCreateTensorARM : FuncRef[(VkDevice, VkTensorCreateInfoARM, VkAllocationCallbacks, FixedArray[VkTensorARM]) -> Int32]
  vkDestroyTensorARM : FuncRef[(VkDevice, VkTensorARM, VkAllocationCallbacks) -> Unit]
  vkCreateTensorViewARM : FuncRef[(VkDevice, VkTensorViewCreateInfoARM, VkAllocationCallbacks, FixedArray[VkTensorViewARM]) -> Int32]
  vkDestroyTensorViewARM : FuncRef[(VkDevice, VkTensorViewARM, VkAllocationCallbacks) -> Unit]
  vkGetTensorMemoryRequirementsARM : FuncRef[(VkDevice, VkTensorMemoryRequirementsInfoARM, VkMemoryRequirements2) -> Unit]
  vkBindTensorMemoryARM : FuncRef[(VkDevice, UInt32, VkBindTensorMemoryInfoARM) -> Int32]
  vkGetDeviceTensorMemoryRequirementsARM : FuncRef[(VkDevice, VkDeviceTensorMemoryRequirementsARM, VkMemoryRequirements2) -> Unit]
  vkCmdCopyTensorARM : FuncRef[(VkCommandBuffer, VkCopyTensorInfoARM) -> Unit]
  vkGetTensorOpaqueCaptureDescriptorDataARM : FuncRef[(VkDevice, VkTensorCaptureDescriptorDataInfoARM, UInt64) -> Int32]
  vkGetTensorViewOpaqueCaptureDescriptorDataARM : FuncRef[(VkDevice, VkTensorViewCaptureDescriptorDataInfoARM, UInt64) -> Int32]
  vkCreateDataGraphPipelinesARM : FuncRef[(VkDevice, VkDeferredOperationKHR, VkPipelineCache, UInt32, VkDataGraphPipelineCreateInfoARM, VkAllocationCallbacks, FixedArray[VkPipeline]) -> Int32]
  vkCreateDataGraphPipelineSessionARM : FuncRef[(VkDevice, VkDataGraphPipelineSessionCreateInfoARM, VkAllocationCallbacks, FixedArray[VkDataGraphPipelineSessionARM]) -> Int32]
  vkGetDataGraphPipelineSessionBindPointRequirementsARM : FuncRef[(VkDevice, VkDataGraphPipelineSessionBindPointRequirementsInfoARM, FixedArray[UInt32], VkDataGraphPipelineSessionBindPointRequirementARM) -> Int32]
  vkGetDataGraphPipelineSessionMemoryRequirementsARM : FuncRef[(VkDevice, VkDataGraphPipelineSessionMemoryRequirementsInfoARM, VkMemoryRequirements2) -> Unit]
  vkBindDataGraphPipelineSessionMemoryARM : FuncRef[(VkDevice, UInt32, VkBindDataGraphPipelineSessionMemoryInfoARM) -> Int32]
  vkDestroyDataGraphPipelineSessionARM : FuncRef[(VkDevice, VkDataGraphPipelineSessionARM, VkAllocationCallbacks) -> Unit]
  vkCmdDispatchDataGraphARM : FuncRef[(VkCommandBuffer, VkDataGraphPipelineSessionARM, VkDataGraphPipelineDispatchInfoARM) -> Unit]
  vkGetDataGraphPipelineAvailablePropertiesARM : FuncRef[(VkDevice, VkDataGraphPipelineInfoARM, FixedArray[UInt32], FixedArray[UInt32]) -> Int32]
  vkGetDataGraphPipelinePropertiesARM : FuncRef[(VkDevice, VkDataGraphPipelineInfoARM, UInt32, VkDataGraphPipelinePropertyQueryResultARM) -> Int32]
  vkGetNativeBufferPropertiesOHOS : FuncRef[(VkDevice, UInt64, VkNativeBufferPropertiesOHOS) -> Int32]
  vkGetMemoryNativeBufferOHOS : FuncRef[(VkDevice, VkMemoryGetNativeBufferInfoOHOS, FixedArray[UInt64]) -> Int32]
  vkGetSwapchainGrallocUsageOHOS : FuncRef[(VkDevice, UInt32, UInt32, FixedArray[UInt64]) -> Int32]
  vkAcquireImageOHOS : FuncRef[(VkDevice, VkImage, Int32, VkSemaphore, VkFence) -> Int32]
  vkQueueSignalReleaseImageOHOS : FuncRef[(VkQueue, UInt32, FixedArray[VkSemaphore], VkImage, FixedArray[Int32]) -> Int32]
  vkQueueSetPerfHintQCOM : FuncRef[(VkQueue, VkPerfHintInfoQCOM) -> Int32]
  vkCmdSetComputeOccupancyPriorityNV : FuncRef[(VkCommandBuffer, VkComputeOccupancyPriorityParametersNV) -> Unit]
  vkWriteSamplerDescriptorsEXT : FuncRef[(VkDevice, UInt32, VkSamplerCreateInfo, VkHostAddressRangeEXT) -> Int32]
  vkWriteResourceDescriptorsEXT : FuncRef[(VkDevice, UInt32, VkResourceDescriptorInfoEXT, VkHostAddressRangeEXT) -> Int32]
  vkCmdBindSamplerHeapEXT : FuncRef[(VkCommandBuffer, VkBindHeapInfoEXT) -> Unit]
  vkCmdBindResourceHeapEXT : FuncRef[(VkCommandBuffer, VkBindHeapInfoEXT) -> Unit]
  vkCmdPushDataEXT : FuncRef[(VkCommandBuffer, VkPushDataInfoEXT) -> Unit]
  vkRegisterCustomBorderColorEXT : FuncRef[(VkDevice, VkSamplerCustomBorderColorCreateInfoEXT, UInt32, FixedArray[UInt32]) -> Int32]
  vkUnregisterCustomBorderColorEXT : FuncRef[(VkDevice, UInt32) -> Unit]
  vkGetImageOpaqueCaptureDataEXT : FuncRef[(VkDevice, UInt32, FixedArray[VkImage], VkHostAddressRangeEXT) -> Int32]
  vkGetTensorOpaqueCaptureDataARM : FuncRef[(VkDevice, UInt32, FixedArray[VkTensorARM], VkHostAddressRangeEXT) -> Int32]
  vkCmdCopyMemoryKHR : FuncRef[(VkCommandBuffer, VkCopyDeviceMemoryInfoKHR) -> Unit]
  vkCmdCopyMemoryToImageKHR : FuncRef[(VkCommandBuffer, VkCopyDeviceMemoryImageInfoKHR) -> Unit]
  vkCmdCopyImageToMemoryKHR : FuncRef[(VkCommandBuffer, VkCopyDeviceMemoryImageInfoKHR) -> Unit]
  vkCmdUpdateMemoryKHR : FuncRef[(VkCommandBuffer, VkDeviceAddressRangeKHR, UInt32, UInt64, UInt64) -> Unit]
  vkCmdFillMemoryKHR : FuncRef[(VkCommandBuffer, VkDeviceAddressRangeKHR, UInt32, UInt32) -> Unit]
  vkCmdCopyQueryPoolResultsToMemoryKHR : FuncRef[(VkCommandBuffer, VkQueryPool, UInt32, UInt32, VkStridedDeviceAddressRangeKHR, UInt32, UInt32) -> Unit]
  vkCmdBeginConditionalRendering2EXT : FuncRef[(VkCommandBuffer, VkConditionalRenderingBeginInfo2EXT) -> Unit]
  vkCmdBindTransformFeedbackBuffers2EXT : FuncRef[(VkCommandBuffer, UInt32, UInt32, VkBindTransformFeedbackBuffer2InfoEXT) -> Unit]
  vkCmdBeginTransformFeedback2EXT : FuncRef[(VkCommandBuffer, UInt32, UInt32, VkBindTransformFeedbackBuffer2InfoEXT) -> Unit]
  vkCmdEndTransformFeedback2EXT : FuncRef[(VkCommandBuffer, UInt32, UInt32, VkBindTransformFeedbackBuffer2InfoEXT) -> Unit]
  vkCmdDrawIndirectByteCount2EXT : FuncRef[(VkCommandBuffer, UInt32, UInt32, VkBindTransformFeedbackBuffer2InfoEXT, UInt32, UInt32) -> Unit]
  vkCmdWriteMarkerToMemoryAMD : FuncRef[(VkCommandBuffer, VkMemoryMarkerInfoAMD) -> Unit]
  vkCmdBindIndexBuffer3KHR : FuncRef[(VkCommandBuffer, VkBindIndexBuffer3InfoKHR) -> Unit]
  vkCmdBindVertexBuffers3KHR : FuncRef[(VkCommandBuffer, UInt32, UInt32, VkBindVertexBuffer3InfoKHR) -> Unit]
  vkCmdDrawIndirect2KHR : FuncRef[(VkCommandBuffer, VkDrawIndirect2InfoKHR) -> Unit]
  vkCmdDrawIndexedIndirect2KHR : FuncRef[(VkCommandBuffer, VkDrawIndirect2InfoKHR) -> Unit]
  vkCmdDrawIndirectCount2KHR : FuncRef[(VkCommandBuffer, VkDrawIndirectCount2InfoKHR) -> Unit]
  vkCmdDrawIndexedIndirectCount2KHR : FuncRef[(VkCommandBuffer, VkDrawIndirectCount2InfoKHR) -> Unit]
  vkCmdDrawMeshTasksIndirect2EXT : FuncRef[(VkCommandBuffer, VkDrawIndirect2InfoKHR) -> Unit]
  vkCmdDrawMeshTasksIndirectCount2EXT : FuncRef[(VkCommandBuffer, VkDrawIndirectCount2InfoKHR) -> Unit]
  vkCmdDispatchIndirect2KHR : FuncRef[(VkCommandBuffer, VkDispatchIndirect2InfoKHR) -> Unit]
  vkCreateAccelerationStructure2KHR : FuncRef[(VkDevice, VkAccelerationStructureCreateInfo2KHR, VkAllocationCallbacks, FixedArray[VkAccelerationStructureKHR]) -> Int32]
  vkCmdSetDispatchParametersARM : FuncRef[(VkCommandBuffer, VkDispatchParametersARM) -> Unit]
}

extern "c" fn load_vkDestroyDevice(dev : VkDevice) -> FuncRef[(VkDevice, VkAllocationCallbacks) -> Unit] = "tycho_gpa_vkDestroyDevice"
extern "c" fn load_vkGetDeviceQueue(dev : VkDevice) -> FuncRef[(VkDevice, UInt32, UInt32, FixedArray[VkQueue]) -> Unit] = "tycho_gpa_vkGetDeviceQueue"
extern "c" fn load_vkQueueSubmit(dev : VkDevice) -> FuncRef[(VkQueue, UInt32, VkSubmitInfo, VkFence) -> Int32] = "tycho_gpa_vkQueueSubmit"
extern "c" fn load_vkQueueWaitIdle(dev : VkDevice) -> FuncRef[(VkQueue) -> Int32] = "tycho_gpa_vkQueueWaitIdle"
extern "c" fn load_vkDeviceWaitIdle(dev : VkDevice) -> FuncRef[(VkDevice) -> Int32] = "tycho_gpa_vkDeviceWaitIdle"
extern "c" fn load_vkAllocateMemory(dev : VkDevice) -> FuncRef[(VkDevice, VkMemoryAllocateInfo, VkAllocationCallbacks, FixedArray[VkDeviceMemory]) -> Int32] = "tycho_gpa_vkAllocateMemory"
extern "c" fn load_vkFreeMemory(dev : VkDevice) -> FuncRef[(VkDevice, VkDeviceMemory, VkAllocationCallbacks) -> Unit] = "tycho_gpa_vkFreeMemory"
extern "c" fn load_vkMapMemory(dev : VkDevice) -> FuncRef[(VkDevice, VkDeviceMemory, UInt64, UInt64, UInt32, FixedArray[UInt64]) -> Int32] = "tycho_gpa_vkMapMemory"
extern "c" fn load_vkUnmapMemory(dev : VkDevice) -> FuncRef[(VkDevice, VkDeviceMemory) -> Unit] = "tycho_gpa_vkUnmapMemory"
extern "c" fn load_vkFlushMappedMemoryRanges(dev : VkDevice) -> FuncRef[(VkDevice, UInt32, VkMappedMemoryRange) -> Int32] = "tycho_gpa_vkFlushMappedMemoryRanges"
extern "c" fn load_vkInvalidateMappedMemoryRanges(dev : VkDevice) -> FuncRef[(VkDevice, UInt32, VkMappedMemoryRange) -> Int32] = "tycho_gpa_vkInvalidateMappedMemoryRanges"
extern "c" fn load_vkGetDeviceMemoryCommitment(dev : VkDevice) -> FuncRef[(VkDevice, VkDeviceMemory, FixedArray[UInt64]) -> Unit] = "tycho_gpa_vkGetDeviceMemoryCommitment"
extern "c" fn load_vkGetBufferMemoryRequirements(dev : VkDevice) -> FuncRef[(VkDevice, VkBuffer, VkMemoryRequirements) -> Unit] = "tycho_gpa_vkGetBufferMemoryRequirements"
extern "c" fn load_vkBindBufferMemory(dev : VkDevice) -> FuncRef[(VkDevice, VkBuffer, VkDeviceMemory, UInt64) -> Int32] = "tycho_gpa_vkBindBufferMemory"
extern "c" fn load_vkGetImageMemoryRequirements(dev : VkDevice) -> FuncRef[(VkDevice, VkImage, VkMemoryRequirements) -> Unit] = "tycho_gpa_vkGetImageMemoryRequirements"
extern "c" fn load_vkBindImageMemory(dev : VkDevice) -> FuncRef[(VkDevice, VkImage, VkDeviceMemory, UInt64) -> Int32] = "tycho_gpa_vkBindImageMemory"
extern "c" fn load_vkGetImageSparseMemoryRequirements(dev : VkDevice) -> FuncRef[(VkDevice, VkImage, FixedArray[UInt32], VkSparseImageMemoryRequirements) -> Unit] = "tycho_gpa_vkGetImageSparseMemoryRequirements"
extern "c" fn load_vkQueueBindSparse(dev : VkDevice) -> FuncRef[(VkQueue, UInt32, VkBindSparseInfo, VkFence) -> Int32] = "tycho_gpa_vkQueueBindSparse"
extern "c" fn load_vkCreateFence(dev : VkDevice) -> FuncRef[(VkDevice, VkFenceCreateInfo, VkAllocationCallbacks, FixedArray[VkFence]) -> Int32] = "tycho_gpa_vkCreateFence"
extern "c" fn load_vkDestroyFence(dev : VkDevice) -> FuncRef[(VkDevice, VkFence, VkAllocationCallbacks) -> Unit] = "tycho_gpa_vkDestroyFence"
extern "c" fn load_vkResetFences(dev : VkDevice) -> FuncRef[(VkDevice, UInt32, FixedArray[VkFence]) -> Int32] = "tycho_gpa_vkResetFences"
extern "c" fn load_vkGetFenceStatus(dev : VkDevice) -> FuncRef[(VkDevice, VkFence) -> Int32] = "tycho_gpa_vkGetFenceStatus"
extern "c" fn load_vkWaitForFences(dev : VkDevice) -> FuncRef[(VkDevice, UInt32, FixedArray[VkFence], UInt32, UInt64) -> Int32] = "tycho_gpa_vkWaitForFences"
extern "c" fn load_vkCreateSemaphore(dev : VkDevice) -> FuncRef[(VkDevice, VkSemaphoreCreateInfo, VkAllocationCallbacks, FixedArray[VkSemaphore]) -> Int32] = "tycho_gpa_vkCreateSemaphore"
extern "c" fn load_vkDestroySemaphore(dev : VkDevice) -> FuncRef[(VkDevice, VkSemaphore, VkAllocationCallbacks) -> Unit] = "tycho_gpa_vkDestroySemaphore"
extern "c" fn load_vkCreateEvent(dev : VkDevice) -> FuncRef[(VkDevice, VkEventCreateInfo, VkAllocationCallbacks, FixedArray[VkEvent]) -> Int32] = "tycho_gpa_vkCreateEvent"
extern "c" fn load_vkDestroyEvent(dev : VkDevice) -> FuncRef[(VkDevice, VkEvent, VkAllocationCallbacks) -> Unit] = "tycho_gpa_vkDestroyEvent"
extern "c" fn load_vkGetEventStatus(dev : VkDevice) -> FuncRef[(VkDevice, VkEvent) -> Int32] = "tycho_gpa_vkGetEventStatus"
extern "c" fn load_vkSetEvent(dev : VkDevice) -> FuncRef[(VkDevice, VkEvent) -> Int32] = "tycho_gpa_vkSetEvent"
extern "c" fn load_vkResetEvent(dev : VkDevice) -> FuncRef[(VkDevice, VkEvent) -> Int32] = "tycho_gpa_vkResetEvent"
extern "c" fn load_vkCreateQueryPool(dev : VkDevice) -> FuncRef[(VkDevice, VkQueryPoolCreateInfo, VkAllocationCallbacks, FixedArray[VkQueryPool]) -> Int32] = "tycho_gpa_vkCreateQueryPool"
extern "c" fn load_vkDestroyQueryPool(dev : VkDevice) -> FuncRef[(VkDevice, VkQueryPool, VkAllocationCallbacks) -> Unit] = "tycho_gpa_vkDestroyQueryPool"
extern "c" fn load_vkGetQueryPoolResults(dev : VkDevice) -> FuncRef[(VkDevice, VkQueryPool, UInt32, UInt32, UInt64, UInt64, UInt64, UInt32) -> Int32] = "tycho_gpa_vkGetQueryPoolResults"
extern "c" fn load_vkResetQueryPool(dev : VkDevice) -> FuncRef[(VkDevice, VkQueryPool, UInt32, UInt32) -> Unit] = "tycho_gpa_vkResetQueryPool"
extern "c" fn load_vkResetQueryPoolEXT(dev : VkDevice) -> FuncRef[(VkDevice, VkQueryPool, UInt32, UInt32) -> Unit] = "tycho_gpa_vkResetQueryPoolEXT"
extern "c" fn load_vkCreateBuffer(dev : VkDevice) -> FuncRef[(VkDevice, VkBufferCreateInfo, VkAllocationCallbacks, FixedArray[VkBuffer]) -> Int32] = "tycho_gpa_vkCreateBuffer"
extern "c" fn load_vkDestroyBuffer(dev : VkDevice) -> FuncRef[(VkDevice, VkBuffer, VkAllocationCallbacks) -> Unit] = "tycho_gpa_vkDestroyBuffer"
extern "c" fn load_vkCreateBufferView(dev : VkDevice) -> FuncRef[(VkDevice, VkBufferViewCreateInfo, VkAllocationCallbacks, FixedArray[VkBufferView]) -> Int32] = "tycho_gpa_vkCreateBufferView"
extern "c" fn load_vkDestroyBufferView(dev : VkDevice) -> FuncRef[(VkDevice, VkBufferView, VkAllocationCallbacks) -> Unit] = "tycho_gpa_vkDestroyBufferView"
extern "c" fn load_vkCreateImage(dev : VkDevice) -> FuncRef[(VkDevice, VkImageCreateInfo, VkAllocationCallbacks, FixedArray[VkImage]) -> Int32] = "tycho_gpa_vkCreateImage"
extern "c" fn load_vkDestroyImage(dev : VkDevice) -> FuncRef[(VkDevice, VkImage, VkAllocationCallbacks) -> Unit] = "tycho_gpa_vkDestroyImage"
extern "c" fn load_vkGetImageSubresourceLayout(dev : VkDevice) -> FuncRef[(VkDevice, VkImage, VkImageSubresource, VkSubresourceLayout) -> Unit] = "tycho_gpa_vkGetImageSubresourceLayout"
extern "c" fn load_vkCreateImageView(dev : VkDevice) -> FuncRef[(VkDevice, VkImageViewCreateInfo, VkAllocationCallbacks, FixedArray[VkImageView]) -> Int32] = "tycho_gpa_vkCreateImageView"
extern "c" fn load_vkDestroyImageView(dev : VkDevice) -> FuncRef[(VkDevice, VkImageView, VkAllocationCallbacks) -> Unit] = "tycho_gpa_vkDestroyImageView"
extern "c" fn load_vkCreateShaderModule(dev : VkDevice) -> FuncRef[(VkDevice, VkShaderModuleCreateInfo, VkAllocationCallbacks, FixedArray[VkShaderModule]) -> Int32] = "tycho_gpa_vkCreateShaderModule"
extern "c" fn load_vkDestroyShaderModule(dev : VkDevice) -> FuncRef[(VkDevice, VkShaderModule, VkAllocationCallbacks) -> Unit] = "tycho_gpa_vkDestroyShaderModule"
extern "c" fn load_vkCreatePipelineCache(dev : VkDevice) -> FuncRef[(VkDevice, VkPipelineCacheCreateInfo, VkAllocationCallbacks, FixedArray[VkPipelineCache]) -> Int32] = "tycho_gpa_vkCreatePipelineCache"
extern "c" fn load_vkDestroyPipelineCache(dev : VkDevice) -> FuncRef[(VkDevice, VkPipelineCache, VkAllocationCallbacks) -> Unit] = "tycho_gpa_vkDestroyPipelineCache"
extern "c" fn load_vkGetPipelineCacheData(dev : VkDevice) -> FuncRef[(VkDevice, VkPipelineCache, FixedArray[UInt64], UInt64) -> Int32] = "tycho_gpa_vkGetPipelineCacheData"
extern "c" fn load_vkMergePipelineCaches(dev : VkDevice) -> FuncRef[(VkDevice, VkPipelineCache, UInt32, FixedArray[VkPipelineCache]) -> Int32] = "tycho_gpa_vkMergePipelineCaches"
extern "c" fn load_vkCreatePipelineBinariesKHR(dev : VkDevice) -> FuncRef[(VkDevice, VkPipelineBinaryCreateInfoKHR, VkAllocationCallbacks, VkPipelineBinaryHandlesInfoKHR) -> Int32] = "tycho_gpa_vkCreatePipelineBinariesKHR"
extern "c" fn load_vkDestroyPipelineBinaryKHR(dev : VkDevice) -> FuncRef[(VkDevice, VkPipelineBinaryKHR, VkAllocationCallbacks) -> Unit] = "tycho_gpa_vkDestroyPipelineBinaryKHR"
extern "c" fn load_vkGetPipelineKeyKHR(dev : VkDevice) -> FuncRef[(VkDevice, VkPipelineCreateInfoKHR, VkPipelineBinaryKeyKHR) -> Int32] = "tycho_gpa_vkGetPipelineKeyKHR"
extern "c" fn load_vkGetPipelineBinaryDataKHR(dev : VkDevice) -> FuncRef[(VkDevice, VkPipelineBinaryDataInfoKHR, VkPipelineBinaryKeyKHR, FixedArray[UInt64], UInt64) -> Int32] = "tycho_gpa_vkGetPipelineBinaryDataKHR"
extern "c" fn load_vkReleaseCapturedPipelineDataKHR(dev : VkDevice) -> FuncRef[(VkDevice, VkReleaseCapturedPipelineDataInfoKHR, VkAllocationCallbacks) -> Int32] = "tycho_gpa_vkReleaseCapturedPipelineDataKHR"
extern "c" fn load_vkCreateGraphicsPipelines(dev : VkDevice) -> FuncRef[(VkDevice, VkPipelineCache, UInt32, VkGraphicsPipelineCreateInfo, VkAllocationCallbacks, FixedArray[VkPipeline]) -> Int32] = "tycho_gpa_vkCreateGraphicsPipelines"
extern "c" fn load_vkCreateComputePipelines(dev : VkDevice) -> FuncRef[(VkDevice, VkPipelineCache, UInt32, VkComputePipelineCreateInfo, VkAllocationCallbacks, FixedArray[VkPipeline]) -> Int32] = "tycho_gpa_vkCreateComputePipelines"
extern "c" fn load_vkGetDeviceSubpassShadingMaxWorkgroupSizeHUAWEI(dev : VkDevice) -> FuncRef[(VkDevice, VkRenderPass, VkExtent2D) -> Int32] = "tycho_gpa_vkGetDeviceSubpassShadingMaxWorkgroupSizeHUAWEI"
extern "c" fn load_vkDestroyPipeline(dev : VkDevice) -> FuncRef[(VkDevice, VkPipeline, VkAllocationCallbacks) -> Unit] = "tycho_gpa_vkDestroyPipeline"
extern "c" fn load_vkCreatePipelineLayout(dev : VkDevice) -> FuncRef[(VkDevice, VkPipelineLayoutCreateInfo, VkAllocationCallbacks, FixedArray[VkPipelineLayout]) -> Int32] = "tycho_gpa_vkCreatePipelineLayout"
extern "c" fn load_vkDestroyPipelineLayout(dev : VkDevice) -> FuncRef[(VkDevice, VkPipelineLayout, VkAllocationCallbacks) -> Unit] = "tycho_gpa_vkDestroyPipelineLayout"
extern "c" fn load_vkCreateSampler(dev : VkDevice) -> FuncRef[(VkDevice, VkSamplerCreateInfo, VkAllocationCallbacks, FixedArray[VkSampler]) -> Int32] = "tycho_gpa_vkCreateSampler"
extern "c" fn load_vkDestroySampler(dev : VkDevice) -> FuncRef[(VkDevice, VkSampler, VkAllocationCallbacks) -> Unit] = "tycho_gpa_vkDestroySampler"
extern "c" fn load_vkCreateDescriptorSetLayout(dev : VkDevice) -> FuncRef[(VkDevice, VkDescriptorSetLayoutCreateInfo, VkAllocationCallbacks, FixedArray[VkDescriptorSetLayout]) -> Int32] = "tycho_gpa_vkCreateDescriptorSetLayout"
extern "c" fn load_vkDestroyDescriptorSetLayout(dev : VkDevice) -> FuncRef[(VkDevice, VkDescriptorSetLayout, VkAllocationCallbacks) -> Unit] = "tycho_gpa_vkDestroyDescriptorSetLayout"
extern "c" fn load_vkCreateDescriptorPool(dev : VkDevice) -> FuncRef[(VkDevice, VkDescriptorPoolCreateInfo, VkAllocationCallbacks, FixedArray[VkDescriptorPool]) -> Int32] = "tycho_gpa_vkCreateDescriptorPool"
extern "c" fn load_vkDestroyDescriptorPool(dev : VkDevice) -> FuncRef[(VkDevice, VkDescriptorPool, VkAllocationCallbacks) -> Unit] = "tycho_gpa_vkDestroyDescriptorPool"
extern "c" fn load_vkResetDescriptorPool(dev : VkDevice) -> FuncRef[(VkDevice, VkDescriptorPool, UInt32) -> Int32] = "tycho_gpa_vkResetDescriptorPool"
extern "c" fn load_vkAllocateDescriptorSets(dev : VkDevice) -> FuncRef[(VkDevice, VkDescriptorSetAllocateInfo, FixedArray[VkDescriptorSet]) -> Int32] = "tycho_gpa_vkAllocateDescriptorSets"
extern "c" fn load_vkFreeDescriptorSets(dev : VkDevice) -> FuncRef[(VkDevice, VkDescriptorPool, UInt32, FixedArray[VkDescriptorSet]) -> Int32] = "tycho_gpa_vkFreeDescriptorSets"
extern "c" fn load_vkUpdateDescriptorSets(dev : VkDevice) -> FuncRef[(VkDevice, UInt32, VkWriteDescriptorSet, UInt32, VkCopyDescriptorSet) -> Unit] = "tycho_gpa_vkUpdateDescriptorSets"
extern "c" fn load_vkCreateFramebuffer(dev : VkDevice) -> FuncRef[(VkDevice, VkFramebufferCreateInfo, VkAllocationCallbacks, FixedArray[VkFramebuffer]) -> Int32] = "tycho_gpa_vkCreateFramebuffer"
extern "c" fn load_vkDestroyFramebuffer(dev : VkDevice) -> FuncRef[(VkDevice, VkFramebuffer, VkAllocationCallbacks) -> Unit] = "tycho_gpa_vkDestroyFramebuffer"
extern "c" fn load_vkCreateRenderPass(dev : VkDevice) -> FuncRef[(VkDevice, VkRenderPassCreateInfo, VkAllocationCallbacks, FixedArray[VkRenderPass]) -> Int32] = "tycho_gpa_vkCreateRenderPass"
extern "c" fn load_vkDestroyRenderPass(dev : VkDevice) -> FuncRef[(VkDevice, VkRenderPass, VkAllocationCallbacks) -> Unit] = "tycho_gpa_vkDestroyRenderPass"
extern "c" fn load_vkGetRenderAreaGranularity(dev : VkDevice) -> FuncRef[(VkDevice, VkRenderPass, VkExtent2D) -> Unit] = "tycho_gpa_vkGetRenderAreaGranularity"
extern "c" fn load_vkGetRenderingAreaGranularity(dev : VkDevice) -> FuncRef[(VkDevice, VkRenderingAreaInfo, VkExtent2D) -> Unit] = "tycho_gpa_vkGetRenderingAreaGranularity"
extern "c" fn load_vkGetRenderingAreaGranularityKHR(dev : VkDevice) -> FuncRef[(VkDevice, VkRenderingAreaInfo, VkExtent2D) -> Unit] = "tycho_gpa_vkGetRenderingAreaGranularityKHR"
extern "c" fn load_vkCreateCommandPool(dev : VkDevice) -> FuncRef[(VkDevice, VkCommandPoolCreateInfo, VkAllocationCallbacks, FixedArray[VkCommandPool]) -> Int32] = "tycho_gpa_vkCreateCommandPool"
extern "c" fn load_vkDestroyCommandPool(dev : VkDevice) -> FuncRef[(VkDevice, VkCommandPool, VkAllocationCallbacks) -> Unit] = "tycho_gpa_vkDestroyCommandPool"
extern "c" fn load_vkResetCommandPool(dev : VkDevice) -> FuncRef[(VkDevice, VkCommandPool, UInt32) -> Int32] = "tycho_gpa_vkResetCommandPool"
extern "c" fn load_vkAllocateCommandBuffers(dev : VkDevice) -> FuncRef[(VkDevice, VkCommandBufferAllocateInfo, FixedArray[VkCommandBuffer]) -> Int32] = "tycho_gpa_vkAllocateCommandBuffers"
extern "c" fn load_vkFreeCommandBuffers(dev : VkDevice) -> FuncRef[(VkDevice, VkCommandPool, UInt32, FixedArray[VkCommandBuffer]) -> Unit] = "tycho_gpa_vkFreeCommandBuffers"
extern "c" fn load_vkBeginCommandBuffer(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkCommandBufferBeginInfo) -> Int32] = "tycho_gpa_vkBeginCommandBuffer"
extern "c" fn load_vkEndCommandBuffer(dev : VkDevice) -> FuncRef[(VkCommandBuffer) -> Int32] = "tycho_gpa_vkEndCommandBuffer"
extern "c" fn load_vkResetCommandBuffer(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32) -> Int32] = "tycho_gpa_vkResetCommandBuffer"
extern "c" fn load_vkCmdBindPipeline(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32, VkPipeline) -> Unit] = "tycho_gpa_vkCmdBindPipeline"
extern "c" fn load_vkCmdSetPrimitiveRestartIndexEXT(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32) -> Unit] = "tycho_gpa_vkCmdSetPrimitiveRestartIndexEXT"
extern "c" fn load_vkCmdSetAttachmentFeedbackLoopEnableEXT(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32) -> Unit] = "tycho_gpa_vkCmdSetAttachmentFeedbackLoopEnableEXT"
extern "c" fn load_vkCmdSetViewport(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32, UInt32, VkViewport) -> Unit] = "tycho_gpa_vkCmdSetViewport"
extern "c" fn load_vkCmdSetScissor(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32, UInt32, VkRect2D) -> Unit] = "tycho_gpa_vkCmdSetScissor"
extern "c" fn load_vkCmdSetLineWidth(dev : VkDevice) -> FuncRef[(VkCommandBuffer, Float) -> Unit] = "tycho_gpa_vkCmdSetLineWidth"
extern "c" fn load_vkCmdSetDepthBias(dev : VkDevice) -> FuncRef[(VkCommandBuffer, Float, Float, Float) -> Unit] = "tycho_gpa_vkCmdSetDepthBias"
extern "c" fn load_vkCmdSetBlendConstants(dev : VkDevice) -> FuncRef[(VkCommandBuffer, FixedArray[Float]) -> Unit] = "tycho_gpa_vkCmdSetBlendConstants"
extern "c" fn load_vkCmdSetDepthBounds(dev : VkDevice) -> FuncRef[(VkCommandBuffer, Float, Float) -> Unit] = "tycho_gpa_vkCmdSetDepthBounds"
extern "c" fn load_vkCmdSetStencilCompareMask(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32, UInt32) -> Unit] = "tycho_gpa_vkCmdSetStencilCompareMask"
extern "c" fn load_vkCmdSetStencilWriteMask(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32, UInt32) -> Unit] = "tycho_gpa_vkCmdSetStencilWriteMask"
extern "c" fn load_vkCmdSetStencilReference(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32, UInt32) -> Unit] = "tycho_gpa_vkCmdSetStencilReference"
extern "c" fn load_vkCmdBindDescriptorSets(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32, VkPipelineLayout, UInt32, UInt32, FixedArray[VkDescriptorSet], UInt32, FixedArray[UInt32]) -> Unit] = "tycho_gpa_vkCmdBindDescriptorSets"
extern "c" fn load_vkCmdBindIndexBuffer(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkBuffer, UInt64, UInt32) -> Unit] = "tycho_gpa_vkCmdBindIndexBuffer"
extern "c" fn load_vkCmdBindVertexBuffers(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32, UInt32, FixedArray[VkBuffer], FixedArray[UInt64]) -> Unit] = "tycho_gpa_vkCmdBindVertexBuffers"
extern "c" fn load_vkCmdDraw(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32, UInt32, UInt32, UInt32) -> Unit] = "tycho_gpa_vkCmdDraw"
extern "c" fn load_vkCmdDrawIndexed(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32, UInt32, UInt32, Int32, UInt32) -> Unit] = "tycho_gpa_vkCmdDrawIndexed"
extern "c" fn load_vkCmdDrawMultiEXT(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32, VkMultiDrawInfoEXT, UInt32, UInt32, UInt32) -> Unit] = "tycho_gpa_vkCmdDrawMultiEXT"
extern "c" fn load_vkCmdDrawMultiIndexedEXT(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32, VkMultiDrawIndexedInfoEXT, UInt32, UInt32, UInt32, FixedArray[Int32]) -> Unit] = "tycho_gpa_vkCmdDrawMultiIndexedEXT"
extern "c" fn load_vkCmdDrawIndirect(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkBuffer, UInt64, UInt32, UInt32) -> Unit] = "tycho_gpa_vkCmdDrawIndirect"
extern "c" fn load_vkCmdDrawIndexedIndirect(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkBuffer, UInt64, UInt32, UInt32) -> Unit] = "tycho_gpa_vkCmdDrawIndexedIndirect"
extern "c" fn load_vkCmdDispatch(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32, UInt32, UInt32) -> Unit] = "tycho_gpa_vkCmdDispatch"
extern "c" fn load_vkCmdDispatchIndirect(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkBuffer, UInt64) -> Unit] = "tycho_gpa_vkCmdDispatchIndirect"
extern "c" fn load_vkCmdSubpassShadingHUAWEI(dev : VkDevice) -> FuncRef[(VkCommandBuffer) -> Unit] = "tycho_gpa_vkCmdSubpassShadingHUAWEI"
extern "c" fn load_vkCmdDrawClusterHUAWEI(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32, UInt32, UInt32) -> Unit] = "tycho_gpa_vkCmdDrawClusterHUAWEI"
extern "c" fn load_vkCmdDrawClusterIndirectHUAWEI(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkBuffer, UInt64) -> Unit] = "tycho_gpa_vkCmdDrawClusterIndirectHUAWEI"
extern "c" fn load_vkCmdUpdatePipelineIndirectBufferNV(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32, VkPipeline) -> Unit] = "tycho_gpa_vkCmdUpdatePipelineIndirectBufferNV"
extern "c" fn load_vkCmdCopyBuffer(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkBuffer, VkBuffer, UInt32, VkBufferCopy) -> Unit] = "tycho_gpa_vkCmdCopyBuffer"
extern "c" fn load_vkCmdCopyImage(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkImage, UInt32, VkImage, UInt32, UInt32, VkImageCopy) -> Unit] = "tycho_gpa_vkCmdCopyImage"
extern "c" fn load_vkCmdBlitImage(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkImage, UInt32, VkImage, UInt32, UInt32, VkImageBlit, UInt32) -> Unit] = "tycho_gpa_vkCmdBlitImage"
extern "c" fn load_vkCmdCopyBufferToImage(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkBuffer, VkImage, UInt32, UInt32, VkBufferImageCopy) -> Unit] = "tycho_gpa_vkCmdCopyBufferToImage"
extern "c" fn load_vkCmdCopyImageToBuffer(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkImage, UInt32, VkBuffer, UInt32, VkBufferImageCopy) -> Unit] = "tycho_gpa_vkCmdCopyImageToBuffer"
extern "c" fn load_vkCmdCopyMemoryIndirectNV(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt64, UInt32, UInt32) -> Unit] = "tycho_gpa_vkCmdCopyMemoryIndirectNV"
extern "c" fn load_vkCmdCopyMemoryIndirectKHR(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkCopyMemoryIndirectInfoKHR) -> Unit] = "tycho_gpa_vkCmdCopyMemoryIndirectKHR"
extern "c" fn load_vkCmdCopyMemoryToImageIndirectNV(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt64, UInt32, UInt32, VkImage, UInt32, VkImageSubresourceLayers) -> Unit] = "tycho_gpa_vkCmdCopyMemoryToImageIndirectNV"
extern "c" fn load_vkCmdCopyMemoryToImageIndirectKHR(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkCopyMemoryToImageIndirectInfoKHR) -> Unit] = "tycho_gpa_vkCmdCopyMemoryToImageIndirectKHR"
extern "c" fn load_vkCmdUpdateBuffer(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkBuffer, UInt64, UInt64, UInt64) -> Unit] = "tycho_gpa_vkCmdUpdateBuffer"
extern "c" fn load_vkCmdFillBuffer(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkBuffer, UInt64, UInt64, UInt32) -> Unit] = "tycho_gpa_vkCmdFillBuffer"
extern "c" fn load_vkCmdClearColorImage(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkImage, UInt32, VkClearColorValue, UInt32, VkImageSubresourceRange) -> Unit] = "tycho_gpa_vkCmdClearColorImage"
extern "c" fn load_vkCmdClearDepthStencilImage(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkImage, UInt32, VkClearDepthStencilValue, UInt32, VkImageSubresourceRange) -> Unit] = "tycho_gpa_vkCmdClearDepthStencilImage"
extern "c" fn load_vkCmdClearAttachments(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32, VkClearAttachment, UInt32, VkClearRect) -> Unit] = "tycho_gpa_vkCmdClearAttachments"
extern "c" fn load_vkCmdResolveImage(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkImage, UInt32, VkImage, UInt32, UInt32, VkImageResolve) -> Unit] = "tycho_gpa_vkCmdResolveImage"
extern "c" fn load_vkCmdSetEvent(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkEvent, UInt32) -> Unit] = "tycho_gpa_vkCmdSetEvent"
extern "c" fn load_vkCmdResetEvent(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkEvent, UInt32) -> Unit] = "tycho_gpa_vkCmdResetEvent"
extern "c" fn load_vkCmdWaitEvents(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32, FixedArray[VkEvent], UInt32, UInt32, UInt32, VkMemoryBarrier, UInt32, VkBufferMemoryBarrier, UInt32, VkImageMemoryBarrier) -> Unit] = "tycho_gpa_vkCmdWaitEvents"
extern "c" fn load_vkCmdPipelineBarrier(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32, UInt32, UInt32, UInt32, VkMemoryBarrier, UInt32, VkBufferMemoryBarrier, UInt32, VkImageMemoryBarrier) -> Unit] = "tycho_gpa_vkCmdPipelineBarrier"
extern "c" fn load_vkCmdBeginQuery(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkQueryPool, UInt32, UInt32) -> Unit] = "tycho_gpa_vkCmdBeginQuery"
extern "c" fn load_vkCmdEndQuery(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkQueryPool, UInt32) -> Unit] = "tycho_gpa_vkCmdEndQuery"
extern "c" fn load_vkCmdBeginConditionalRenderingEXT(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkConditionalRenderingBeginInfoEXT) -> Unit] = "tycho_gpa_vkCmdBeginConditionalRenderingEXT"
extern "c" fn load_vkCmdEndConditionalRenderingEXT(dev : VkDevice) -> FuncRef[(VkCommandBuffer) -> Unit] = "tycho_gpa_vkCmdEndConditionalRenderingEXT"
extern "c" fn load_vkCmdBeginCustomResolveEXT(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkBeginCustomResolveInfoEXT) -> Unit] = "tycho_gpa_vkCmdBeginCustomResolveEXT"
extern "c" fn load_vkCmdResetQueryPool(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkQueryPool, UInt32, UInt32) -> Unit] = "tycho_gpa_vkCmdResetQueryPool"
extern "c" fn load_vkCmdWriteTimestamp(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32, VkQueryPool, UInt32) -> Unit] = "tycho_gpa_vkCmdWriteTimestamp"
extern "c" fn load_vkCmdCopyQueryPoolResults(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkQueryPool, UInt32, UInt32, VkBuffer, UInt64, UInt64, UInt32) -> Unit] = "tycho_gpa_vkCmdCopyQueryPoolResults"
extern "c" fn load_vkCmdPushConstants(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkPipelineLayout, UInt32, UInt32, UInt32, UInt64) -> Unit] = "tycho_gpa_vkCmdPushConstants"
extern "c" fn load_vkCmdBeginRenderPass(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkRenderPassBeginInfo, UInt32) -> Unit] = "tycho_gpa_vkCmdBeginRenderPass"
extern "c" fn load_vkCmdNextSubpass(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32) -> Unit] = "tycho_gpa_vkCmdNextSubpass"
extern "c" fn load_vkCmdEndRenderPass(dev : VkDevice) -> FuncRef[(VkCommandBuffer) -> Unit] = "tycho_gpa_vkCmdEndRenderPass"
extern "c" fn load_vkCmdExecuteCommands(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32, FixedArray[VkCommandBuffer]) -> Unit] = "tycho_gpa_vkCmdExecuteCommands"
extern "c" fn load_vkCreateSharedSwapchainsKHR(dev : VkDevice) -> FuncRef[(VkDevice, UInt32, VkSwapchainCreateInfoKHR, VkAllocationCallbacks, FixedArray[VkSwapchainKHR]) -> Int32] = "tycho_gpa_vkCreateSharedSwapchainsKHR"
extern "c" fn load_vkCreateSwapchainKHR(dev : VkDevice) -> FuncRef[(VkDevice, VkSwapchainCreateInfoKHR, VkAllocationCallbacks, FixedArray[VkSwapchainKHR]) -> Int32] = "tycho_gpa_vkCreateSwapchainKHR"
extern "c" fn load_vkDestroySwapchainKHR(dev : VkDevice) -> FuncRef[(VkDevice, VkSwapchainKHR, VkAllocationCallbacks) -> Unit] = "tycho_gpa_vkDestroySwapchainKHR"
extern "c" fn load_vkGetSwapchainImagesKHR(dev : VkDevice) -> FuncRef[(VkDevice, VkSwapchainKHR, FixedArray[UInt32], FixedArray[VkImage]) -> Int32] = "tycho_gpa_vkGetSwapchainImagesKHR"
extern "c" fn load_vkAcquireNextImageKHR(dev : VkDevice) -> FuncRef[(VkDevice, VkSwapchainKHR, UInt64, VkSemaphore, VkFence, FixedArray[UInt32]) -> Int32] = "tycho_gpa_vkAcquireNextImageKHR"
extern "c" fn load_vkQueuePresentKHR(dev : VkDevice) -> FuncRef[(VkQueue, VkPresentInfoKHR) -> Int32] = "tycho_gpa_vkQueuePresentKHR"
extern "c" fn load_vkDebugMarkerSetObjectNameEXT(dev : VkDevice) -> FuncRef[(VkDevice, VkDebugMarkerObjectNameInfoEXT) -> Int32] = "tycho_gpa_vkDebugMarkerSetObjectNameEXT"
extern "c" fn load_vkDebugMarkerSetObjectTagEXT(dev : VkDevice) -> FuncRef[(VkDevice, VkDebugMarkerObjectTagInfoEXT) -> Int32] = "tycho_gpa_vkDebugMarkerSetObjectTagEXT"
extern "c" fn load_vkCmdDebugMarkerBeginEXT(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkDebugMarkerMarkerInfoEXT) -> Unit] = "tycho_gpa_vkCmdDebugMarkerBeginEXT"
extern "c" fn load_vkCmdDebugMarkerEndEXT(dev : VkDevice) -> FuncRef[(VkCommandBuffer) -> Unit] = "tycho_gpa_vkCmdDebugMarkerEndEXT"
extern "c" fn load_vkCmdDebugMarkerInsertEXT(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkDebugMarkerMarkerInfoEXT) -> Unit] = "tycho_gpa_vkCmdDebugMarkerInsertEXT"
extern "c" fn load_vkGetMemoryWin32HandleNV(dev : VkDevice) -> FuncRef[(VkDevice, VkDeviceMemory, UInt32, UInt64) -> Int32] = "tycho_gpa_vkGetMemoryWin32HandleNV"
extern "c" fn load_vkCmdExecuteGeneratedCommandsNV(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32, VkGeneratedCommandsInfoNV) -> Unit] = "tycho_gpa_vkCmdExecuteGeneratedCommandsNV"
extern "c" fn load_vkCmdPreprocessGeneratedCommandsNV(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkGeneratedCommandsInfoNV) -> Unit] = "tycho_gpa_vkCmdPreprocessGeneratedCommandsNV"
extern "c" fn load_vkCmdBindPipelineShaderGroupNV(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32, VkPipeline, UInt32) -> Unit] = "tycho_gpa_vkCmdBindPipelineShaderGroupNV"
extern "c" fn load_vkGetGeneratedCommandsMemoryRequirementsNV(dev : VkDevice) -> FuncRef[(VkDevice, VkGeneratedCommandsMemoryRequirementsInfoNV, VkMemoryRequirements2) -> Unit] = "tycho_gpa_vkGetGeneratedCommandsMemoryRequirementsNV"
extern "c" fn load_vkCreateIndirectCommandsLayoutNV(dev : VkDevice) -> FuncRef[(VkDevice, VkIndirectCommandsLayoutCreateInfoNV, VkAllocationCallbacks, FixedArray[VkIndirectCommandsLayoutNV]) -> Int32] = "tycho_gpa_vkCreateIndirectCommandsLayoutNV"
extern "c" fn load_vkDestroyIndirectCommandsLayoutNV(dev : VkDevice) -> FuncRef[(VkDevice, VkIndirectCommandsLayoutNV, VkAllocationCallbacks) -> Unit] = "tycho_gpa_vkDestroyIndirectCommandsLayoutNV"
extern "c" fn load_vkCmdExecuteGeneratedCommandsEXT(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32, VkGeneratedCommandsInfoEXT) -> Unit] = "tycho_gpa_vkCmdExecuteGeneratedCommandsEXT"
extern "c" fn load_vkCmdPreprocessGeneratedCommandsEXT(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkGeneratedCommandsInfoEXT, VkCommandBuffer) -> Unit] = "tycho_gpa_vkCmdPreprocessGeneratedCommandsEXT"
extern "c" fn load_vkGetGeneratedCommandsMemoryRequirementsEXT(dev : VkDevice) -> FuncRef[(VkDevice, VkGeneratedCommandsMemoryRequirementsInfoEXT, VkMemoryRequirements2) -> Unit] = "tycho_gpa_vkGetGeneratedCommandsMemoryRequirementsEXT"
extern "c" fn load_vkCreateIndirectCommandsLayoutEXT(dev : VkDevice) -> FuncRef[(VkDevice, VkIndirectCommandsLayoutCreateInfoEXT, VkAllocationCallbacks, FixedArray[VkIndirectCommandsLayoutEXT]) -> Int32] = "tycho_gpa_vkCreateIndirectCommandsLayoutEXT"
extern "c" fn load_vkDestroyIndirectCommandsLayoutEXT(dev : VkDevice) -> FuncRef[(VkDevice, VkIndirectCommandsLayoutEXT, VkAllocationCallbacks) -> Unit] = "tycho_gpa_vkDestroyIndirectCommandsLayoutEXT"
extern "c" fn load_vkCreateIndirectExecutionSetEXT(dev : VkDevice) -> FuncRef[(VkDevice, VkIndirectExecutionSetCreateInfoEXT, VkAllocationCallbacks, FixedArray[VkIndirectExecutionSetEXT]) -> Int32] = "tycho_gpa_vkCreateIndirectExecutionSetEXT"
extern "c" fn load_vkDestroyIndirectExecutionSetEXT(dev : VkDevice) -> FuncRef[(VkDevice, VkIndirectExecutionSetEXT, VkAllocationCallbacks) -> Unit] = "tycho_gpa_vkDestroyIndirectExecutionSetEXT"
extern "c" fn load_vkUpdateIndirectExecutionSetPipelineEXT(dev : VkDevice) -> FuncRef[(VkDevice, VkIndirectExecutionSetEXT, UInt32, VkWriteIndirectExecutionSetPipelineEXT) -> Unit] = "tycho_gpa_vkUpdateIndirectExecutionSetPipelineEXT"
extern "c" fn load_vkUpdateIndirectExecutionSetShaderEXT(dev : VkDevice) -> FuncRef[(VkDevice, VkIndirectExecutionSetEXT, UInt32, VkWriteIndirectExecutionSetShaderEXT) -> Unit] = "tycho_gpa_vkUpdateIndirectExecutionSetShaderEXT"
extern "c" fn load_vkCmdPushDescriptorSet(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32, VkPipelineLayout, UInt32, UInt32, VkWriteDescriptorSet) -> Unit] = "tycho_gpa_vkCmdPushDescriptorSet"
extern "c" fn load_vkCmdPushDescriptorSetKHR(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32, VkPipelineLayout, UInt32, UInt32, VkWriteDescriptorSet) -> Unit] = "tycho_gpa_vkCmdPushDescriptorSetKHR"
extern "c" fn load_vkTrimCommandPool(dev : VkDevice) -> FuncRef[(VkDevice, VkCommandPool, UInt32) -> Unit] = "tycho_gpa_vkTrimCommandPool"
extern "c" fn load_vkTrimCommandPoolKHR(dev : VkDevice) -> FuncRef[(VkDevice, VkCommandPool, UInt32) -> Unit] = "tycho_gpa_vkTrimCommandPoolKHR"
extern "c" fn load_vkGetMemoryWin32HandleKHR(dev : VkDevice) -> FuncRef[(VkDevice, VkMemoryGetWin32HandleInfoKHR, UInt64) -> Int32] = "tycho_gpa_vkGetMemoryWin32HandleKHR"
extern "c" fn load_vkGetMemoryWin32HandlePropertiesKHR(dev : VkDevice) -> FuncRef[(VkDevice, UInt32, UInt64, VkMemoryWin32HandlePropertiesKHR) -> Int32] = "tycho_gpa_vkGetMemoryWin32HandlePropertiesKHR"
extern "c" fn load_vkGetMemoryFdKHR(dev : VkDevice) -> FuncRef[(VkDevice, VkMemoryGetFdInfoKHR, FixedArray[Int32]) -> Int32] = "tycho_gpa_vkGetMemoryFdKHR"
extern "c" fn load_vkGetMemoryFdPropertiesKHR(dev : VkDevice) -> FuncRef[(VkDevice, UInt32, Int32, VkMemoryFdPropertiesKHR) -> Int32] = "tycho_gpa_vkGetMemoryFdPropertiesKHR"
extern "c" fn load_vkGetMemoryZirconHandleFUCHSIA(dev : VkDevice) -> FuncRef[(VkDevice, VkMemoryGetZirconHandleInfoFUCHSIA, UInt64) -> Int32] = "tycho_gpa_vkGetMemoryZirconHandleFUCHSIA"
extern "c" fn load_vkGetMemoryZirconHandlePropertiesFUCHSIA(dev : VkDevice) -> FuncRef[(VkDevice, UInt32, UInt64, VkMemoryZirconHandlePropertiesFUCHSIA) -> Int32] = "tycho_gpa_vkGetMemoryZirconHandlePropertiesFUCHSIA"
extern "c" fn load_vkGetMemoryRemoteAddressNV(dev : VkDevice) -> FuncRef[(VkDevice, VkMemoryGetRemoteAddressInfoNV, UInt64) -> Int32] = "tycho_gpa_vkGetMemoryRemoteAddressNV"
extern "c" fn load_vkGetMemorySciBufNV(dev : VkDevice) -> FuncRef[(VkDevice, VkMemoryGetSciBufInfoNV, UInt64) -> Int32] = "tycho_gpa_vkGetMemorySciBufNV"
extern "c" fn load_vkGetSemaphoreWin32HandleKHR(dev : VkDevice) -> FuncRef[(VkDevice, VkSemaphoreGetWin32HandleInfoKHR, UInt64) -> Int32] = "tycho_gpa_vkGetSemaphoreWin32HandleKHR"
extern "c" fn load_vkImportSemaphoreWin32HandleKHR(dev : VkDevice) -> FuncRef[(VkDevice, VkImportSemaphoreWin32HandleInfoKHR) -> Int32] = "tycho_gpa_vkImportSemaphoreWin32HandleKHR"
extern "c" fn load_vkGetSemaphoreFdKHR(dev : VkDevice) -> FuncRef[(VkDevice, VkSemaphoreGetFdInfoKHR, FixedArray[Int32]) -> Int32] = "tycho_gpa_vkGetSemaphoreFdKHR"
extern "c" fn load_vkImportSemaphoreFdKHR(dev : VkDevice) -> FuncRef[(VkDevice, VkImportSemaphoreFdInfoKHR) -> Int32] = "tycho_gpa_vkImportSemaphoreFdKHR"
extern "c" fn load_vkGetSemaphoreZirconHandleFUCHSIA(dev : VkDevice) -> FuncRef[(VkDevice, VkSemaphoreGetZirconHandleInfoFUCHSIA, UInt64) -> Int32] = "tycho_gpa_vkGetSemaphoreZirconHandleFUCHSIA"
extern "c" fn load_vkImportSemaphoreZirconHandleFUCHSIA(dev : VkDevice) -> FuncRef[(VkDevice, VkImportSemaphoreZirconHandleInfoFUCHSIA) -> Int32] = "tycho_gpa_vkImportSemaphoreZirconHandleFUCHSIA"
extern "c" fn load_vkGetFenceWin32HandleKHR(dev : VkDevice) -> FuncRef[(VkDevice, VkFenceGetWin32HandleInfoKHR, UInt64) -> Int32] = "tycho_gpa_vkGetFenceWin32HandleKHR"
extern "c" fn load_vkImportFenceWin32HandleKHR(dev : VkDevice) -> FuncRef[(VkDevice, VkImportFenceWin32HandleInfoKHR) -> Int32] = "tycho_gpa_vkImportFenceWin32HandleKHR"
extern "c" fn load_vkGetFenceFdKHR(dev : VkDevice) -> FuncRef[(VkDevice, VkFenceGetFdInfoKHR, FixedArray[Int32]) -> Int32] = "tycho_gpa_vkGetFenceFdKHR"
extern "c" fn load_vkImportFenceFdKHR(dev : VkDevice) -> FuncRef[(VkDevice, VkImportFenceFdInfoKHR) -> Int32] = "tycho_gpa_vkImportFenceFdKHR"
extern "c" fn load_vkGetFenceSciSyncFenceNV(dev : VkDevice) -> FuncRef[(VkDevice, VkFenceGetSciSyncInfoNV, UInt64) -> Int32] = "tycho_gpa_vkGetFenceSciSyncFenceNV"
extern "c" fn load_vkGetFenceSciSyncObjNV(dev : VkDevice) -> FuncRef[(VkDevice, VkFenceGetSciSyncInfoNV, UInt64) -> Int32] = "tycho_gpa_vkGetFenceSciSyncObjNV"
extern "c" fn load_vkImportFenceSciSyncFenceNV(dev : VkDevice) -> FuncRef[(VkDevice, VkImportFenceSciSyncInfoNV) -> Int32] = "tycho_gpa_vkImportFenceSciSyncFenceNV"
extern "c" fn load_vkImportFenceSciSyncObjNV(dev : VkDevice) -> FuncRef[(VkDevice, VkImportFenceSciSyncInfoNV) -> Int32] = "tycho_gpa_vkImportFenceSciSyncObjNV"
extern "c" fn load_vkGetSemaphoreSciSyncObjNV(dev : VkDevice) -> FuncRef[(VkDevice, VkSemaphoreGetSciSyncInfoNV, UInt64) -> Int32] = "tycho_gpa_vkGetSemaphoreSciSyncObjNV"
extern "c" fn load_vkImportSemaphoreSciSyncObjNV(dev : VkDevice) -> FuncRef[(VkDevice, VkImportSemaphoreSciSyncInfoNV) -> Int32] = "tycho_gpa_vkImportSemaphoreSciSyncObjNV"
extern "c" fn load_vkCreateSemaphoreSciSyncPoolNV(dev : VkDevice) -> FuncRef[(VkDevice, VkSemaphoreSciSyncPoolCreateInfoNV, VkAllocationCallbacks, FixedArray[VkSemaphoreSciSyncPoolNV]) -> Int32] = "tycho_gpa_vkCreateSemaphoreSciSyncPoolNV"
extern "c" fn load_vkDestroySemaphoreSciSyncPoolNV(dev : VkDevice) -> FuncRef[(VkDevice, VkSemaphoreSciSyncPoolNV, VkAllocationCallbacks) -> Unit] = "tycho_gpa_vkDestroySemaphoreSciSyncPoolNV"
extern "c" fn load_vkDisplayPowerControlEXT(dev : VkDevice) -> FuncRef[(VkDevice, VkDisplayKHR, VkDisplayPowerInfoEXT) -> Int32] = "tycho_gpa_vkDisplayPowerControlEXT"
extern "c" fn load_vkRegisterDeviceEventEXT(dev : VkDevice) -> FuncRef[(VkDevice, VkDeviceEventInfoEXT, VkAllocationCallbacks, FixedArray[VkFence]) -> Int32] = "tycho_gpa_vkRegisterDeviceEventEXT"
extern "c" fn load_vkRegisterDisplayEventEXT(dev : VkDevice) -> FuncRef[(VkDevice, VkDisplayKHR, VkDisplayEventInfoEXT, VkAllocationCallbacks, FixedArray[VkFence]) -> Int32] = "tycho_gpa_vkRegisterDisplayEventEXT"
extern "c" fn load_vkGetSwapchainCounterEXT(dev : VkDevice) -> FuncRef[(VkDevice, VkSwapchainKHR, UInt32, FixedArray[UInt64]) -> Int32] = "tycho_gpa_vkGetSwapchainCounterEXT"
extern "c" fn load_vkGetDeviceGroupPeerMemoryFeatures(dev : VkDevice) -> FuncRef[(VkDevice, UInt32, UInt32, UInt32, FixedArray[UInt32]) -> Unit] = "tycho_gpa_vkGetDeviceGroupPeerMemoryFeatures"
extern "c" fn load_vkGetDeviceGroupPeerMemoryFeaturesKHR(dev : VkDevice) -> FuncRef[(VkDevice, UInt32, UInt32, UInt32, FixedArray[UInt32]) -> Unit] = "tycho_gpa_vkGetDeviceGroupPeerMemoryFeaturesKHR"
extern "c" fn load_vkBindBufferMemory2(dev : VkDevice) -> FuncRef[(VkDevice, UInt32, VkBindBufferMemoryInfo) -> Int32] = "tycho_gpa_vkBindBufferMemory2"
extern "c" fn load_vkBindBufferMemory2KHR(dev : VkDevice) -> FuncRef[(VkDevice, UInt32, VkBindBufferMemoryInfo) -> Int32] = "tycho_gpa_vkBindBufferMemory2KHR"
extern "c" fn load_vkBindImageMemory2(dev : VkDevice) -> FuncRef[(VkDevice, UInt32, VkBindImageMemoryInfo) -> Int32] = "tycho_gpa_vkBindImageMemory2"
extern "c" fn load_vkBindImageMemory2KHR(dev : VkDevice) -> FuncRef[(VkDevice, UInt32, VkBindImageMemoryInfo) -> Int32] = "tycho_gpa_vkBindImageMemory2KHR"
extern "c" fn load_vkCmdSetDeviceMask(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32) -> Unit] = "tycho_gpa_vkCmdSetDeviceMask"
extern "c" fn load_vkCmdSetDeviceMaskKHR(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32) -> Unit] = "tycho_gpa_vkCmdSetDeviceMaskKHR"
extern "c" fn load_vkGetDeviceGroupPresentCapabilitiesKHR(dev : VkDevice) -> FuncRef[(VkDevice, VkDeviceGroupPresentCapabilitiesKHR) -> Int32] = "tycho_gpa_vkGetDeviceGroupPresentCapabilitiesKHR"
extern "c" fn load_vkGetDeviceGroupSurfacePresentModesKHR(dev : VkDevice) -> FuncRef[(VkDevice, VkSurfaceKHR, FixedArray[UInt32]) -> Int32] = "tycho_gpa_vkGetDeviceGroupSurfacePresentModesKHR"
extern "c" fn load_vkAcquireNextImage2KHR(dev : VkDevice) -> FuncRef[(VkDevice, VkAcquireNextImageInfoKHR, FixedArray[UInt32]) -> Int32] = "tycho_gpa_vkAcquireNextImage2KHR"
extern "c" fn load_vkCmdDispatchBase(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32) -> Unit] = "tycho_gpa_vkCmdDispatchBase"
extern "c" fn load_vkCmdDispatchBaseKHR(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32) -> Unit] = "tycho_gpa_vkCmdDispatchBaseKHR"
extern "c" fn load_vkCreateDescriptorUpdateTemplate(dev : VkDevice) -> FuncRef[(VkDevice, VkDescriptorUpdateTemplateCreateInfo, VkAllocationCallbacks, FixedArray[VkDescriptorUpdateTemplate]) -> Int32] = "tycho_gpa_vkCreateDescriptorUpdateTemplate"
extern "c" fn load_vkCreateDescriptorUpdateTemplateKHR(dev : VkDevice) -> FuncRef[(VkDevice, VkDescriptorUpdateTemplateCreateInfo, VkAllocationCallbacks, FixedArray[VkDescriptorUpdateTemplate]) -> Int32] = "tycho_gpa_vkCreateDescriptorUpdateTemplateKHR"
extern "c" fn load_vkDestroyDescriptorUpdateTemplate(dev : VkDevice) -> FuncRef[(VkDevice, VkDescriptorUpdateTemplate, VkAllocationCallbacks) -> Unit] = "tycho_gpa_vkDestroyDescriptorUpdateTemplate"
extern "c" fn load_vkDestroyDescriptorUpdateTemplateKHR(dev : VkDevice) -> FuncRef[(VkDevice, VkDescriptorUpdateTemplate, VkAllocationCallbacks) -> Unit] = "tycho_gpa_vkDestroyDescriptorUpdateTemplateKHR"
extern "c" fn load_vkUpdateDescriptorSetWithTemplate(dev : VkDevice) -> FuncRef[(VkDevice, VkDescriptorSet, VkDescriptorUpdateTemplate, UInt64) -> Unit] = "tycho_gpa_vkUpdateDescriptorSetWithTemplate"
extern "c" fn load_vkUpdateDescriptorSetWithTemplateKHR(dev : VkDevice) -> FuncRef[(VkDevice, VkDescriptorSet, VkDescriptorUpdateTemplate, UInt64) -> Unit] = "tycho_gpa_vkUpdateDescriptorSetWithTemplateKHR"
extern "c" fn load_vkCmdPushDescriptorSetWithTemplate(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkDescriptorUpdateTemplate, VkPipelineLayout, UInt32, UInt64) -> Unit] = "tycho_gpa_vkCmdPushDescriptorSetWithTemplate"
extern "c" fn load_vkCmdPushDescriptorSetWithTemplateKHR(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkDescriptorUpdateTemplate, VkPipelineLayout, UInt32, UInt64) -> Unit] = "tycho_gpa_vkCmdPushDescriptorSetWithTemplateKHR"
extern "c" fn load_vkSetHdrMetadataEXT(dev : VkDevice) -> FuncRef[(VkDevice, UInt32, FixedArray[VkSwapchainKHR], VkHdrMetadataEXT) -> Unit] = "tycho_gpa_vkSetHdrMetadataEXT"
extern "c" fn load_vkGetSwapchainStatusKHR(dev : VkDevice) -> FuncRef[(VkDevice, VkSwapchainKHR) -> Int32] = "tycho_gpa_vkGetSwapchainStatusKHR"
extern "c" fn load_vkGetRefreshCycleDurationGOOGLE(dev : VkDevice) -> FuncRef[(VkDevice, VkSwapchainKHR, VkRefreshCycleDurationGOOGLE) -> Int32] = "tycho_gpa_vkGetRefreshCycleDurationGOOGLE"
extern "c" fn load_vkGetPastPresentationTimingGOOGLE(dev : VkDevice) -> FuncRef[(VkDevice, VkSwapchainKHR, FixedArray[UInt32], VkPastPresentationTimingGOOGLE) -> Int32] = "tycho_gpa_vkGetPastPresentationTimingGOOGLE"
extern "c" fn load_vkCmdSetViewportWScalingNV(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32, UInt32, VkViewportWScalingNV) -> Unit] = "tycho_gpa_vkCmdSetViewportWScalingNV"
extern "c" fn load_vkCmdSetDiscardRectangleEXT(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32, UInt32, VkRect2D) -> Unit] = "tycho_gpa_vkCmdSetDiscardRectangleEXT"
extern "c" fn load_vkCmdSetDiscardRectangleEnableEXT(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32) -> Unit] = "tycho_gpa_vkCmdSetDiscardRectangleEnableEXT"
extern "c" fn load_vkCmdSetDiscardRectangleModeEXT(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32) -> Unit] = "tycho_gpa_vkCmdSetDiscardRectangleModeEXT"
extern "c" fn load_vkCmdSetSampleLocationsEXT(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkSampleLocationsInfoEXT) -> Unit] = "tycho_gpa_vkCmdSetSampleLocationsEXT"
extern "c" fn load_vkGetBufferMemoryRequirements2(dev : VkDevice) -> FuncRef[(VkDevice, VkBufferMemoryRequirementsInfo2, VkMemoryRequirements2) -> Unit] = "tycho_gpa_vkGetBufferMemoryRequirements2"
extern "c" fn load_vkGetBufferMemoryRequirements2KHR(dev : VkDevice) -> FuncRef[(VkDevice, VkBufferMemoryRequirementsInfo2, VkMemoryRequirements2) -> Unit] = "tycho_gpa_vkGetBufferMemoryRequirements2KHR"
extern "c" fn load_vkGetImageMemoryRequirements2(dev : VkDevice) -> FuncRef[(VkDevice, VkImageMemoryRequirementsInfo2, VkMemoryRequirements2) -> Unit] = "tycho_gpa_vkGetImageMemoryRequirements2"
extern "c" fn load_vkGetImageMemoryRequirements2KHR(dev : VkDevice) -> FuncRef[(VkDevice, VkImageMemoryRequirementsInfo2, VkMemoryRequirements2) -> Unit] = "tycho_gpa_vkGetImageMemoryRequirements2KHR"
extern "c" fn load_vkGetImageSparseMemoryRequirements2(dev : VkDevice) -> FuncRef[(VkDevice, VkImageSparseMemoryRequirementsInfo2, FixedArray[UInt32], VkSparseImageMemoryRequirements2) -> Unit] = "tycho_gpa_vkGetImageSparseMemoryRequirements2"
extern "c" fn load_vkGetImageSparseMemoryRequirements2KHR(dev : VkDevice) -> FuncRef[(VkDevice, VkImageSparseMemoryRequirementsInfo2, FixedArray[UInt32], VkSparseImageMemoryRequirements2) -> Unit] = "tycho_gpa_vkGetImageSparseMemoryRequirements2KHR"
extern "c" fn load_vkGetDeviceBufferMemoryRequirements(dev : VkDevice) -> FuncRef[(VkDevice, VkDeviceBufferMemoryRequirements, VkMemoryRequirements2) -> Unit] = "tycho_gpa_vkGetDeviceBufferMemoryRequirements"
extern "c" fn load_vkGetDeviceBufferMemoryRequirementsKHR(dev : VkDevice) -> FuncRef[(VkDevice, VkDeviceBufferMemoryRequirements, VkMemoryRequirements2) -> Unit] = "tycho_gpa_vkGetDeviceBufferMemoryRequirementsKHR"
extern "c" fn load_vkGetDeviceImageMemoryRequirements(dev : VkDevice) -> FuncRef[(VkDevice, VkDeviceImageMemoryRequirements, VkMemoryRequirements2) -> Unit] = "tycho_gpa_vkGetDeviceImageMemoryRequirements"
extern "c" fn load_vkGetDeviceImageMemoryRequirementsKHR(dev : VkDevice) -> FuncRef[(VkDevice, VkDeviceImageMemoryRequirements, VkMemoryRequirements2) -> Unit] = "tycho_gpa_vkGetDeviceImageMemoryRequirementsKHR"
extern "c" fn load_vkGetDeviceImageSparseMemoryRequirements(dev : VkDevice) -> FuncRef[(VkDevice, VkDeviceImageMemoryRequirements, FixedArray[UInt32], VkSparseImageMemoryRequirements2) -> Unit] = "tycho_gpa_vkGetDeviceImageSparseMemoryRequirements"
extern "c" fn load_vkGetDeviceImageSparseMemoryRequirementsKHR(dev : VkDevice) -> FuncRef[(VkDevice, VkDeviceImageMemoryRequirements, FixedArray[UInt32], VkSparseImageMemoryRequirements2) -> Unit] = "tycho_gpa_vkGetDeviceImageSparseMemoryRequirementsKHR"
extern "c" fn load_vkCreateSamplerYcbcrConversion(dev : VkDevice) -> FuncRef[(VkDevice, VkSamplerYcbcrConversionCreateInfo, VkAllocationCallbacks, FixedArray[VkSamplerYcbcrConversion]) -> Int32] = "tycho_gpa_vkCreateSamplerYcbcrConversion"
extern "c" fn load_vkCreateSamplerYcbcrConversionKHR(dev : VkDevice) -> FuncRef[(VkDevice, VkSamplerYcbcrConversionCreateInfo, VkAllocationCallbacks, FixedArray[VkSamplerYcbcrConversion]) -> Int32] = "tycho_gpa_vkCreateSamplerYcbcrConversionKHR"
extern "c" fn load_vkDestroySamplerYcbcrConversion(dev : VkDevice) -> FuncRef[(VkDevice, VkSamplerYcbcrConversion, VkAllocationCallbacks) -> Unit] = "tycho_gpa_vkDestroySamplerYcbcrConversion"
extern "c" fn load_vkDestroySamplerYcbcrConversionKHR(dev : VkDevice) -> FuncRef[(VkDevice, VkSamplerYcbcrConversion, VkAllocationCallbacks) -> Unit] = "tycho_gpa_vkDestroySamplerYcbcrConversionKHR"
extern "c" fn load_vkGetDeviceQueue2(dev : VkDevice) -> FuncRef[(VkDevice, VkDeviceQueueInfo2, FixedArray[VkQueue]) -> Unit] = "tycho_gpa_vkGetDeviceQueue2"
extern "c" fn load_vkCreateValidationCacheEXT(dev : VkDevice) -> FuncRef[(VkDevice, VkValidationCacheCreateInfoEXT, VkAllocationCallbacks, FixedArray[VkValidationCacheEXT]) -> Int32] = "tycho_gpa_vkCreateValidationCacheEXT"
extern "c" fn load_vkDestroyValidationCacheEXT(dev : VkDevice) -> FuncRef[(VkDevice, VkValidationCacheEXT, VkAllocationCallbacks) -> Unit] = "tycho_gpa_vkDestroyValidationCacheEXT"
extern "c" fn load_vkGetValidationCacheDataEXT(dev : VkDevice) -> FuncRef[(VkDevice, VkValidationCacheEXT, FixedArray[UInt64], UInt64) -> Int32] = "tycho_gpa_vkGetValidationCacheDataEXT"
extern "c" fn load_vkMergeValidationCachesEXT(dev : VkDevice) -> FuncRef[(VkDevice, VkValidationCacheEXT, UInt32, FixedArray[VkValidationCacheEXT]) -> Int32] = "tycho_gpa_vkMergeValidationCachesEXT"
extern "c" fn load_vkGetDescriptorSetLayoutSupport(dev : VkDevice) -> FuncRef[(VkDevice, VkDescriptorSetLayoutCreateInfo, VkDescriptorSetLayoutSupport) -> Unit] = "tycho_gpa_vkGetDescriptorSetLayoutSupport"
extern "c" fn load_vkGetDescriptorSetLayoutSupportKHR(dev : VkDevice) -> FuncRef[(VkDevice, VkDescriptorSetLayoutCreateInfo, VkDescriptorSetLayoutSupport) -> Unit] = "tycho_gpa_vkGetDescriptorSetLayoutSupportKHR"
extern "c" fn load_vkGetSwapchainGrallocUsageANDROID(dev : VkDevice) -> FuncRef[(VkDevice, UInt32, UInt32, FixedArray[Int32]) -> Int32] = "tycho_gpa_vkGetSwapchainGrallocUsageANDROID"
extern "c" fn load_vkGetSwapchainGrallocUsage2ANDROID(dev : VkDevice) -> FuncRef[(VkDevice, UInt32, UInt32, UInt32, FixedArray[UInt64], FixedArray[UInt64]) -> Int32] = "tycho_gpa_vkGetSwapchainGrallocUsage2ANDROID"
extern "c" fn load_vkAcquireImageANDROID(dev : VkDevice) -> FuncRef[(VkDevice, VkImage, Int32, VkSemaphore, VkFence) -> Int32] = "tycho_gpa_vkAcquireImageANDROID"
extern "c" fn load_vkQueueSignalReleaseImageANDROID(dev : VkDevice) -> FuncRef[(VkQueue, UInt32, FixedArray[VkSemaphore], VkImage, FixedArray[Int32]) -> Int32] = "tycho_gpa_vkQueueSignalReleaseImageANDROID"
extern "c" fn load_vkGetShaderInfoAMD(dev : VkDevice) -> FuncRef[(VkDevice, VkPipeline, UInt32, UInt32, FixedArray[UInt64], UInt64) -> Int32] = "tycho_gpa_vkGetShaderInfoAMD"
extern "c" fn load_vkSetLocalDimmingAMD(dev : VkDevice) -> FuncRef[(VkDevice, VkSwapchainKHR, UInt32) -> Unit] = "tycho_gpa_vkSetLocalDimmingAMD"
extern "c" fn load_vkGetCalibratedTimestampsKHR(dev : VkDevice) -> FuncRef[(VkDevice, UInt32, VkCalibratedTimestampInfoKHR, FixedArray[UInt64], FixedArray[UInt64]) -> Int32] = "tycho_gpa_vkGetCalibratedTimestampsKHR"
extern "c" fn load_vkGetCalibratedTimestampsEXT(dev : VkDevice) -> FuncRef[(VkDevice, UInt32, VkCalibratedTimestampInfoKHR, FixedArray[UInt64], FixedArray[UInt64]) -> Int32] = "tycho_gpa_vkGetCalibratedTimestampsEXT"
extern "c" fn load_vkSetDebugUtilsObjectNameEXT(dev : VkDevice) -> FuncRef[(VkDevice, VkDebugUtilsObjectNameInfoEXT) -> Int32] = "tycho_gpa_vkSetDebugUtilsObjectNameEXT"
extern "c" fn load_vkSetDebugUtilsObjectTagEXT(dev : VkDevice) -> FuncRef[(VkDevice, VkDebugUtilsObjectTagInfoEXT) -> Int32] = "tycho_gpa_vkSetDebugUtilsObjectTagEXT"
extern "c" fn load_vkQueueBeginDebugUtilsLabelEXT(dev : VkDevice) -> FuncRef[(VkQueue, VkDebugUtilsLabelEXT) -> Unit] = "tycho_gpa_vkQueueBeginDebugUtilsLabelEXT"
extern "c" fn load_vkQueueEndDebugUtilsLabelEXT(dev : VkDevice) -> FuncRef[(VkQueue) -> Unit] = "tycho_gpa_vkQueueEndDebugUtilsLabelEXT"
extern "c" fn load_vkQueueInsertDebugUtilsLabelEXT(dev : VkDevice) -> FuncRef[(VkQueue, VkDebugUtilsLabelEXT) -> Unit] = "tycho_gpa_vkQueueInsertDebugUtilsLabelEXT"
extern "c" fn load_vkCmdBeginDebugUtilsLabelEXT(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkDebugUtilsLabelEXT) -> Unit] = "tycho_gpa_vkCmdBeginDebugUtilsLabelEXT"
extern "c" fn load_vkCmdEndDebugUtilsLabelEXT(dev : VkDevice) -> FuncRef[(VkCommandBuffer) -> Unit] = "tycho_gpa_vkCmdEndDebugUtilsLabelEXT"
extern "c" fn load_vkCmdInsertDebugUtilsLabelEXT(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkDebugUtilsLabelEXT) -> Unit] = "tycho_gpa_vkCmdInsertDebugUtilsLabelEXT"
extern "c" fn load_vkGetMemoryHostPointerPropertiesEXT(dev : VkDevice) -> FuncRef[(VkDevice, UInt32, UInt64, VkMemoryHostPointerPropertiesEXT) -> Int32] = "tycho_gpa_vkGetMemoryHostPointerPropertiesEXT"
extern "c" fn load_vkCmdWriteBufferMarkerAMD(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32, VkBuffer, UInt64, UInt32) -> Unit] = "tycho_gpa_vkCmdWriteBufferMarkerAMD"
extern "c" fn load_vkCreateRenderPass2(dev : VkDevice) -> FuncRef[(VkDevice, VkRenderPassCreateInfo2, VkAllocationCallbacks, FixedArray[VkRenderPass]) -> Int32] = "tycho_gpa_vkCreateRenderPass2"
extern "c" fn load_vkCreateRenderPass2KHR(dev : VkDevice) -> FuncRef[(VkDevice, VkRenderPassCreateInfo2, VkAllocationCallbacks, FixedArray[VkRenderPass]) -> Int32] = "tycho_gpa_vkCreateRenderPass2KHR"
extern "c" fn load_vkCmdBeginRenderPass2(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkRenderPassBeginInfo, VkSubpassBeginInfo) -> Unit] = "tycho_gpa_vkCmdBeginRenderPass2"
extern "c" fn load_vkCmdBeginRenderPass2KHR(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkRenderPassBeginInfo, VkSubpassBeginInfo) -> Unit] = "tycho_gpa_vkCmdBeginRenderPass2KHR"
extern "c" fn load_vkCmdNextSubpass2(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkSubpassBeginInfo, VkSubpassEndInfo) -> Unit] = "tycho_gpa_vkCmdNextSubpass2"
extern "c" fn load_vkCmdNextSubpass2KHR(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkSubpassBeginInfo, VkSubpassEndInfo) -> Unit] = "tycho_gpa_vkCmdNextSubpass2KHR"
extern "c" fn load_vkCmdEndRenderPass2(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkSubpassEndInfo) -> Unit] = "tycho_gpa_vkCmdEndRenderPass2"
extern "c" fn load_vkCmdEndRenderPass2KHR(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkSubpassEndInfo) -> Unit] = "tycho_gpa_vkCmdEndRenderPass2KHR"
extern "c" fn load_vkGetSemaphoreCounterValue(dev : VkDevice) -> FuncRef[(VkDevice, VkSemaphore, FixedArray[UInt64]) -> Int32] = "tycho_gpa_vkGetSemaphoreCounterValue"
extern "c" fn load_vkGetSemaphoreCounterValueKHR(dev : VkDevice) -> FuncRef[(VkDevice, VkSemaphore, FixedArray[UInt64]) -> Int32] = "tycho_gpa_vkGetSemaphoreCounterValueKHR"
extern "c" fn load_vkWaitSemaphores(dev : VkDevice) -> FuncRef[(VkDevice, VkSemaphoreWaitInfo, UInt64) -> Int32] = "tycho_gpa_vkWaitSemaphores"
extern "c" fn load_vkWaitSemaphoresKHR(dev : VkDevice) -> FuncRef[(VkDevice, VkSemaphoreWaitInfo, UInt64) -> Int32] = "tycho_gpa_vkWaitSemaphoresKHR"
extern "c" fn load_vkSignalSemaphore(dev : VkDevice) -> FuncRef[(VkDevice, VkSemaphoreSignalInfo) -> Int32] = "tycho_gpa_vkSignalSemaphore"
extern "c" fn load_vkSignalSemaphoreKHR(dev : VkDevice) -> FuncRef[(VkDevice, VkSemaphoreSignalInfo) -> Int32] = "tycho_gpa_vkSignalSemaphoreKHR"
extern "c" fn load_vkGetAndroidHardwareBufferPropertiesANDROID(dev : VkDevice) -> FuncRef[(VkDevice, UInt64, VkAndroidHardwareBufferPropertiesANDROID) -> Int32] = "tycho_gpa_vkGetAndroidHardwareBufferPropertiesANDROID"
extern "c" fn load_vkGetMemoryAndroidHardwareBufferANDROID(dev : VkDevice) -> FuncRef[(VkDevice, VkMemoryGetAndroidHardwareBufferInfoANDROID, FixedArray[UInt64]) -> Int32] = "tycho_gpa_vkGetMemoryAndroidHardwareBufferANDROID"
extern "c" fn load_vkCmdDrawIndirectCount(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkBuffer, UInt64, VkBuffer, UInt64, UInt32, UInt32) -> Unit] = "tycho_gpa_vkCmdDrawIndirectCount"
extern "c" fn load_vkCmdDrawIndirectCountKHR(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkBuffer, UInt64, VkBuffer, UInt64, UInt32, UInt32) -> Unit] = "tycho_gpa_vkCmdDrawIndirectCountKHR"
extern "c" fn load_vkCmdDrawIndirectCountAMD(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkBuffer, UInt64, VkBuffer, UInt64, UInt32, UInt32) -> Unit] = "tycho_gpa_vkCmdDrawIndirectCountAMD"
extern "c" fn load_vkCmdDrawIndexedIndirectCount(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkBuffer, UInt64, VkBuffer, UInt64, UInt32, UInt32) -> Unit] = "tycho_gpa_vkCmdDrawIndexedIndirectCount"
extern "c" fn load_vkCmdDrawIndexedIndirectCountKHR(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkBuffer, UInt64, VkBuffer, UInt64, UInt32, UInt32) -> Unit] = "tycho_gpa_vkCmdDrawIndexedIndirectCountKHR"
extern "c" fn load_vkCmdDrawIndexedIndirectCountAMD(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkBuffer, UInt64, VkBuffer, UInt64, UInt32, UInt32) -> Unit] = "tycho_gpa_vkCmdDrawIndexedIndirectCountAMD"
extern "c" fn load_vkCmdSetCheckpointNV(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt64) -> Unit] = "tycho_gpa_vkCmdSetCheckpointNV"
extern "c" fn load_vkGetQueueCheckpointDataNV(dev : VkDevice) -> FuncRef[(VkQueue, FixedArray[UInt32], VkCheckpointDataNV) -> Unit] = "tycho_gpa_vkGetQueueCheckpointDataNV"
extern "c" fn load_vkCmdBindTransformFeedbackBuffersEXT(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32, UInt32, FixedArray[VkBuffer], FixedArray[UInt64], FixedArray[UInt64]) -> Unit] = "tycho_gpa_vkCmdBindTransformFeedbackBuffersEXT"
extern "c" fn load_vkCmdBeginTransformFeedbackEXT(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32, UInt32, FixedArray[VkBuffer], FixedArray[UInt64]) -> Unit] = "tycho_gpa_vkCmdBeginTransformFeedbackEXT"
extern "c" fn load_vkCmdEndTransformFeedbackEXT(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32, UInt32, FixedArray[VkBuffer], FixedArray[UInt64]) -> Unit] = "tycho_gpa_vkCmdEndTransformFeedbackEXT"
extern "c" fn load_vkCmdBeginQueryIndexedEXT(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkQueryPool, UInt32, UInt32, UInt32) -> Unit] = "tycho_gpa_vkCmdBeginQueryIndexedEXT"
extern "c" fn load_vkCmdEndQueryIndexedEXT(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkQueryPool, UInt32, UInt32) -> Unit] = "tycho_gpa_vkCmdEndQueryIndexedEXT"
extern "c" fn load_vkCmdDrawIndirectByteCountEXT(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32, UInt32, VkBuffer, UInt64, UInt32, UInt32) -> Unit] = "tycho_gpa_vkCmdDrawIndirectByteCountEXT"
extern "c" fn load_vkCmdSetExclusiveScissorNV(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32, UInt32, VkRect2D) -> Unit] = "tycho_gpa_vkCmdSetExclusiveScissorNV"
extern "c" fn load_vkCmdSetExclusiveScissorEnableNV(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32, UInt32, FixedArray[UInt32]) -> Unit] = "tycho_gpa_vkCmdSetExclusiveScissorEnableNV"
extern "c" fn load_vkCmdBindShadingRateImageNV(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkImageView, UInt32) -> Unit] = "tycho_gpa_vkCmdBindShadingRateImageNV"
extern "c" fn load_vkCmdSetViewportShadingRatePaletteNV(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32, UInt32, VkShadingRatePaletteNV) -> Unit] = "tycho_gpa_vkCmdSetViewportShadingRatePaletteNV"
extern "c" fn load_vkCmdSetCoarseSampleOrderNV(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32, UInt32, VkCoarseSampleOrderCustomNV) -> Unit] = "tycho_gpa_vkCmdSetCoarseSampleOrderNV"
extern "c" fn load_vkCmdDrawMeshTasksNV(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32, UInt32) -> Unit] = "tycho_gpa_vkCmdDrawMeshTasksNV"
extern "c" fn load_vkCmdDrawMeshTasksIndirectNV(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkBuffer, UInt64, UInt32, UInt32) -> Unit] = "tycho_gpa_vkCmdDrawMeshTasksIndirectNV"
extern "c" fn load_vkCmdDrawMeshTasksIndirectCountNV(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkBuffer, UInt64, VkBuffer, UInt64, UInt32, UInt32) -> Unit] = "tycho_gpa_vkCmdDrawMeshTasksIndirectCountNV"
extern "c" fn load_vkCmdDrawMeshTasksEXT(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32, UInt32, UInt32) -> Unit] = "tycho_gpa_vkCmdDrawMeshTasksEXT"
extern "c" fn load_vkCmdDrawMeshTasksIndirectEXT(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkBuffer, UInt64, UInt32, UInt32) -> Unit] = "tycho_gpa_vkCmdDrawMeshTasksIndirectEXT"
extern "c" fn load_vkCmdDrawMeshTasksIndirectCountEXT(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkBuffer, UInt64, VkBuffer, UInt64, UInt32, UInt32) -> Unit] = "tycho_gpa_vkCmdDrawMeshTasksIndirectCountEXT"
extern "c" fn load_vkCompileDeferredNV(dev : VkDevice) -> FuncRef[(VkDevice, VkPipeline, UInt32) -> Int32] = "tycho_gpa_vkCompileDeferredNV"
extern "c" fn load_vkCreateAccelerationStructureNV(dev : VkDevice) -> FuncRef[(VkDevice, VkAccelerationStructureCreateInfoNV, VkAllocationCallbacks, FixedArray[VkAccelerationStructureNV]) -> Int32] = "tycho_gpa_vkCreateAccelerationStructureNV"
extern "c" fn load_vkCmdBindInvocationMaskHUAWEI(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkImageView, UInt32) -> Unit] = "tycho_gpa_vkCmdBindInvocationMaskHUAWEI"
extern "c" fn load_vkDestroyAccelerationStructureKHR(dev : VkDevice) -> FuncRef[(VkDevice, VkAccelerationStructureKHR, VkAllocationCallbacks) -> Unit] = "tycho_gpa_vkDestroyAccelerationStructureKHR"
extern "c" fn load_vkDestroyAccelerationStructureNV(dev : VkDevice) -> FuncRef[(VkDevice, VkAccelerationStructureNV, VkAllocationCallbacks) -> Unit] = "tycho_gpa_vkDestroyAccelerationStructureNV"
extern "c" fn load_vkGetAccelerationStructureMemoryRequirementsNV(dev : VkDevice) -> FuncRef[(VkDevice, VkAccelerationStructureMemoryRequirementsInfoNV, VkMemoryRequirements2) -> Unit] = "tycho_gpa_vkGetAccelerationStructureMemoryRequirementsNV"
extern "c" fn load_vkBindAccelerationStructureMemoryNV(dev : VkDevice) -> FuncRef[(VkDevice, UInt32, VkBindAccelerationStructureMemoryInfoNV) -> Int32] = "tycho_gpa_vkBindAccelerationStructureMemoryNV"
extern "c" fn load_vkCmdCopyAccelerationStructureNV(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkAccelerationStructureNV, VkAccelerationStructureNV, UInt32) -> Unit] = "tycho_gpa_vkCmdCopyAccelerationStructureNV"
extern "c" fn load_vkCmdCopyAccelerationStructureKHR(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkCopyAccelerationStructureInfoKHR) -> Unit] = "tycho_gpa_vkCmdCopyAccelerationStructureKHR"
extern "c" fn load_vkCopyAccelerationStructureKHR(dev : VkDevice) -> FuncRef[(VkDevice, VkDeferredOperationKHR, VkCopyAccelerationStructureInfoKHR) -> Int32] = "tycho_gpa_vkCopyAccelerationStructureKHR"
extern "c" fn load_vkCmdCopyAccelerationStructureToMemoryKHR(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkCopyAccelerationStructureToMemoryInfoKHR) -> Unit] = "tycho_gpa_vkCmdCopyAccelerationStructureToMemoryKHR"
extern "c" fn load_vkCopyAccelerationStructureToMemoryKHR(dev : VkDevice) -> FuncRef[(VkDevice, VkDeferredOperationKHR, VkCopyAccelerationStructureToMemoryInfoKHR) -> Int32] = "tycho_gpa_vkCopyAccelerationStructureToMemoryKHR"
extern "c" fn load_vkCmdCopyMemoryToAccelerationStructureKHR(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkCopyMemoryToAccelerationStructureInfoKHR) -> Unit] = "tycho_gpa_vkCmdCopyMemoryToAccelerationStructureKHR"
extern "c" fn load_vkCopyMemoryToAccelerationStructureKHR(dev : VkDevice) -> FuncRef[(VkDevice, VkDeferredOperationKHR, VkCopyMemoryToAccelerationStructureInfoKHR) -> Int32] = "tycho_gpa_vkCopyMemoryToAccelerationStructureKHR"
extern "c" fn load_vkCmdWriteAccelerationStructuresPropertiesKHR(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32, FixedArray[VkAccelerationStructureKHR], UInt32, VkQueryPool, UInt32) -> Unit] = "tycho_gpa_vkCmdWriteAccelerationStructuresPropertiesKHR"
extern "c" fn load_vkCmdWriteAccelerationStructuresPropertiesNV(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32, FixedArray[VkAccelerationStructureNV], UInt32, VkQueryPool, UInt32) -> Unit] = "tycho_gpa_vkCmdWriteAccelerationStructuresPropertiesNV"
extern "c" fn load_vkCmdBuildAccelerationStructureNV(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkAccelerationStructureInfoNV, VkBuffer, UInt64, UInt32, VkAccelerationStructureNV, VkAccelerationStructureNV, VkBuffer, UInt64) -> Unit] = "tycho_gpa_vkCmdBuildAccelerationStructureNV"
extern "c" fn load_vkWriteAccelerationStructuresPropertiesKHR(dev : VkDevice) -> FuncRef[(VkDevice, UInt32, FixedArray[VkAccelerationStructureKHR], UInt32, UInt64, UInt64, UInt64) -> Int32] = "tycho_gpa_vkWriteAccelerationStructuresPropertiesKHR"
extern "c" fn load_vkCmdTraceRaysKHR(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkStridedDeviceAddressRegionKHR, VkStridedDeviceAddressRegionKHR, VkStridedDeviceAddressRegionKHR, VkStridedDeviceAddressRegionKHR, UInt32, UInt32, UInt32) -> Unit] = "tycho_gpa_vkCmdTraceRaysKHR"
extern "c" fn load_vkCmdTraceRaysNV(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkBuffer, UInt64, VkBuffer, UInt64, UInt64, VkBuffer, UInt64, UInt64, VkBuffer, UInt64, UInt64, UInt32, UInt32, UInt32) -> Unit] = "tycho_gpa_vkCmdTraceRaysNV"
extern "c" fn load_vkGetRayTracingShaderGroupHandlesKHR(dev : VkDevice) -> FuncRef[(VkDevice, VkPipeline, UInt32, UInt32, UInt64, UInt64) -> Int32] = "tycho_gpa_vkGetRayTracingShaderGroupHandlesKHR"
extern "c" fn load_vkGetRayTracingShaderGroupHandlesNV(dev : VkDevice) -> FuncRef[(VkDevice, VkPipeline, UInt32, UInt32, UInt64, UInt64) -> Int32] = "tycho_gpa_vkGetRayTracingShaderGroupHandlesNV"
extern "c" fn load_vkGetRayTracingCaptureReplayShaderGroupHandlesKHR(dev : VkDevice) -> FuncRef[(VkDevice, VkPipeline, UInt32, UInt32, UInt64, UInt64) -> Int32] = "tycho_gpa_vkGetRayTracingCaptureReplayShaderGroupHandlesKHR"
extern "c" fn load_vkGetAccelerationStructureHandleNV(dev : VkDevice) -> FuncRef[(VkDevice, VkAccelerationStructureNV, UInt64, UInt64) -> Int32] = "tycho_gpa_vkGetAccelerationStructureHandleNV"
extern "c" fn load_vkCreateRayTracingPipelinesNV(dev : VkDevice) -> FuncRef[(VkDevice, VkPipelineCache, UInt32, VkRayTracingPipelineCreateInfoNV, VkAllocationCallbacks, FixedArray[VkPipeline]) -> Int32] = "tycho_gpa_vkCreateRayTracingPipelinesNV"
extern "c" fn load_vkCreateRayTracingPipelinesKHR(dev : VkDevice) -> FuncRef[(VkDevice, VkDeferredOperationKHR, VkPipelineCache, UInt32, VkRayTracingPipelineCreateInfoKHR, VkAllocationCallbacks, FixedArray[VkPipeline]) -> Int32] = "tycho_gpa_vkCreateRayTracingPipelinesKHR"
extern "c" fn load_vkCmdTraceRaysIndirectKHR(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkStridedDeviceAddressRegionKHR, VkStridedDeviceAddressRegionKHR, VkStridedDeviceAddressRegionKHR, VkStridedDeviceAddressRegionKHR, UInt64) -> Unit] = "tycho_gpa_vkCmdTraceRaysIndirectKHR"
extern "c" fn load_vkCmdTraceRaysIndirect2KHR(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt64) -> Unit] = "tycho_gpa_vkCmdTraceRaysIndirect2KHR"
extern "c" fn load_vkGetClusterAccelerationStructureBuildSizesNV(dev : VkDevice) -> FuncRef[(VkDevice, VkClusterAccelerationStructureInputInfoNV, VkAccelerationStructureBuildSizesInfoKHR) -> Unit] = "tycho_gpa_vkGetClusterAccelerationStructureBuildSizesNV"
extern "c" fn load_vkCmdBuildClusterAccelerationStructureIndirectNV(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkClusterAccelerationStructureCommandsInfoNV) -> Unit] = "tycho_gpa_vkCmdBuildClusterAccelerationStructureIndirectNV"
extern "c" fn load_vkGetDeviceAccelerationStructureCompatibilityKHR(dev : VkDevice) -> FuncRef[(VkDevice, VkAccelerationStructureVersionInfoKHR, FixedArray[UInt32]) -> Unit] = "tycho_gpa_vkGetDeviceAccelerationStructureCompatibilityKHR"
extern "c" fn load_vkGetRayTracingShaderGroupStackSizeKHR(dev : VkDevice) -> FuncRef[(VkDevice, VkPipeline, UInt32, UInt32) -> UInt64] = "tycho_gpa_vkGetRayTracingShaderGroupStackSizeKHR"
extern "c" fn load_vkCmdSetRayTracingPipelineStackSizeKHR(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32) -> Unit] = "tycho_gpa_vkCmdSetRayTracingPipelineStackSizeKHR"
extern "c" fn load_vkGetImageViewHandleNVX(dev : VkDevice) -> FuncRef[(VkDevice, VkImageViewHandleInfoNVX) -> UInt32] = "tycho_gpa_vkGetImageViewHandleNVX"
extern "c" fn load_vkGetImageViewHandle64NVX(dev : VkDevice) -> FuncRef[(VkDevice, VkImageViewHandleInfoNVX) -> UInt64] = "tycho_gpa_vkGetImageViewHandle64NVX"
extern "c" fn load_vkGetImageViewAddressNVX(dev : VkDevice) -> FuncRef[(VkDevice, VkImageView, VkImageViewAddressPropertiesNVX) -> Int32] = "tycho_gpa_vkGetImageViewAddressNVX"
extern "c" fn load_vkGetDeviceCombinedImageSamplerIndexNVX(dev : VkDevice) -> FuncRef[(VkDevice, UInt64, UInt64) -> UInt64] = "tycho_gpa_vkGetDeviceCombinedImageSamplerIndexNVX"
extern "c" fn load_vkGetDeviceGroupSurfacePresentModes2EXT(dev : VkDevice) -> FuncRef[(VkDevice, VkPhysicalDeviceSurfaceInfo2KHR, FixedArray[UInt32]) -> Int32] = "tycho_gpa_vkGetDeviceGroupSurfacePresentModes2EXT"
extern "c" fn load_vkAcquireFullScreenExclusiveModeEXT(dev : VkDevice) -> FuncRef[(VkDevice, VkSwapchainKHR) -> Int32] = "tycho_gpa_vkAcquireFullScreenExclusiveModeEXT"
extern "c" fn load_vkReleaseFullScreenExclusiveModeEXT(dev : VkDevice) -> FuncRef[(VkDevice, VkSwapchainKHR) -> Int32] = "tycho_gpa_vkReleaseFullScreenExclusiveModeEXT"
extern "c" fn load_vkAcquireProfilingLockKHR(dev : VkDevice) -> FuncRef[(VkDevice, VkAcquireProfilingLockInfoKHR) -> Int32] = "tycho_gpa_vkAcquireProfilingLockKHR"
extern "c" fn load_vkReleaseProfilingLockKHR(dev : VkDevice) -> FuncRef[(VkDevice) -> Unit] = "tycho_gpa_vkReleaseProfilingLockKHR"
extern "c" fn load_vkGetImageDrmFormatModifierPropertiesEXT(dev : VkDevice) -> FuncRef[(VkDevice, VkImage, VkImageDrmFormatModifierPropertiesEXT) -> Int32] = "tycho_gpa_vkGetImageDrmFormatModifierPropertiesEXT"
extern "c" fn load_vkGetBufferOpaqueCaptureAddress(dev : VkDevice) -> FuncRef[(VkDevice, VkBufferDeviceAddressInfo) -> UInt64] = "tycho_gpa_vkGetBufferOpaqueCaptureAddress"
extern "c" fn load_vkGetBufferOpaqueCaptureAddressKHR(dev : VkDevice) -> FuncRef[(VkDevice, VkBufferDeviceAddressInfo) -> UInt64] = "tycho_gpa_vkGetBufferOpaqueCaptureAddressKHR"
extern "c" fn load_vkGetBufferDeviceAddress(dev : VkDevice) -> FuncRef[(VkDevice, VkBufferDeviceAddressInfo) -> UInt64] = "tycho_gpa_vkGetBufferDeviceAddress"
extern "c" fn load_vkGetBufferDeviceAddressKHR(dev : VkDevice) -> FuncRef[(VkDevice, VkBufferDeviceAddressInfo) -> UInt64] = "tycho_gpa_vkGetBufferDeviceAddressKHR"
extern "c" fn load_vkGetBufferDeviceAddressEXT(dev : VkDevice) -> FuncRef[(VkDevice, VkBufferDeviceAddressInfo) -> UInt64] = "tycho_gpa_vkGetBufferDeviceAddressEXT"
extern "c" fn load_vkInitializePerformanceApiINTEL(dev : VkDevice) -> FuncRef[(VkDevice, VkInitializePerformanceApiInfoINTEL) -> Int32] = "tycho_gpa_vkInitializePerformanceApiINTEL"
extern "c" fn load_vkUninitializePerformanceApiINTEL(dev : VkDevice) -> FuncRef[(VkDevice) -> Unit] = "tycho_gpa_vkUninitializePerformanceApiINTEL"
extern "c" fn load_vkCmdSetPerformanceMarkerINTEL(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkPerformanceMarkerInfoINTEL) -> Int32] = "tycho_gpa_vkCmdSetPerformanceMarkerINTEL"
extern "c" fn load_vkCmdSetPerformanceStreamMarkerINTEL(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkPerformanceStreamMarkerInfoINTEL) -> Int32] = "tycho_gpa_vkCmdSetPerformanceStreamMarkerINTEL"
extern "c" fn load_vkCmdSetPerformanceOverrideINTEL(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkPerformanceOverrideInfoINTEL) -> Int32] = "tycho_gpa_vkCmdSetPerformanceOverrideINTEL"
extern "c" fn load_vkAcquirePerformanceConfigurationINTEL(dev : VkDevice) -> FuncRef[(VkDevice, VkPerformanceConfigurationAcquireInfoINTEL, FixedArray[VkPerformanceConfigurationINTEL]) -> Int32] = "tycho_gpa_vkAcquirePerformanceConfigurationINTEL"
extern "c" fn load_vkReleasePerformanceConfigurationINTEL(dev : VkDevice) -> FuncRef[(VkDevice, VkPerformanceConfigurationINTEL) -> Int32] = "tycho_gpa_vkReleasePerformanceConfigurationINTEL"
extern "c" fn load_vkQueueSetPerformanceConfigurationINTEL(dev : VkDevice) -> FuncRef[(VkQueue, VkPerformanceConfigurationINTEL) -> Int32] = "tycho_gpa_vkQueueSetPerformanceConfigurationINTEL"
extern "c" fn load_vkGetPerformanceParameterINTEL(dev : VkDevice) -> FuncRef[(VkDevice, UInt32, VkPerformanceValueINTEL) -> Int32] = "tycho_gpa_vkGetPerformanceParameterINTEL"
extern "c" fn load_vkGetDeviceMemoryOpaqueCaptureAddress(dev : VkDevice) -> FuncRef[(VkDevice, VkDeviceMemoryOpaqueCaptureAddressInfo) -> UInt64] = "tycho_gpa_vkGetDeviceMemoryOpaqueCaptureAddress"
extern "c" fn load_vkGetDeviceMemoryOpaqueCaptureAddressKHR(dev : VkDevice) -> FuncRef[(VkDevice, VkDeviceMemoryOpaqueCaptureAddressInfo) -> UInt64] = "tycho_gpa_vkGetDeviceMemoryOpaqueCaptureAddressKHR"
extern "c" fn load_vkGetPipelineExecutablePropertiesKHR(dev : VkDevice) -> FuncRef[(VkDevice, VkPipelineInfoKHR, FixedArray[UInt32], VkPipelineExecutablePropertiesKHR) -> Int32] = "tycho_gpa_vkGetPipelineExecutablePropertiesKHR"
extern "c" fn load_vkGetPipelineExecutableStatisticsKHR(dev : VkDevice) -> FuncRef[(VkDevice, VkPipelineExecutableInfoKHR, FixedArray[UInt32], VkPipelineExecutableStatisticKHR) -> Int32] = "tycho_gpa_vkGetPipelineExecutableStatisticsKHR"
extern "c" fn load_vkGetPipelineExecutableInternalRepresentationsKHR(dev : VkDevice) -> FuncRef[(VkDevice, VkPipelineExecutableInfoKHR, FixedArray[UInt32], VkPipelineExecutableInternalRepresentationKHR) -> Int32] = "tycho_gpa_vkGetPipelineExecutableInternalRepresentationsKHR"
extern "c" fn load_vkCmdSetLineStipple(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32, UInt) -> Unit] = "tycho_gpa_vkCmdSetLineStipple"
extern "c" fn load_vkCmdSetLineStippleKHR(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32, UInt) -> Unit] = "tycho_gpa_vkCmdSetLineStippleKHR"
extern "c" fn load_vkCmdSetLineStippleEXT(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32, UInt) -> Unit] = "tycho_gpa_vkCmdSetLineStippleEXT"
extern "c" fn load_vkGetFaultData(dev : VkDevice) -> FuncRef[(VkDevice, UInt32, FixedArray[UInt32], FixedArray[UInt32], VkFaultData) -> Int32] = "tycho_gpa_vkGetFaultData"
extern "c" fn load_vkCreateAccelerationStructureKHR(dev : VkDevice) -> FuncRef[(VkDevice, VkAccelerationStructureCreateInfoKHR, VkAllocationCallbacks, FixedArray[VkAccelerationStructureKHR]) -> Int32] = "tycho_gpa_vkCreateAccelerationStructureKHR"
extern "c" fn load_vkCmdBuildAccelerationStructuresKHR(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32, VkAccelerationStructureBuildGeometryInfoKHR, FixedArray[UInt64]) -> Unit] = "tycho_gpa_vkCmdBuildAccelerationStructuresKHR"
extern "c" fn load_vkCmdBuildAccelerationStructuresIndirectKHR(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32, VkAccelerationStructureBuildGeometryInfoKHR, FixedArray[UInt64], FixedArray[UInt32], FixedArray[UInt64]) -> Unit] = "tycho_gpa_vkCmdBuildAccelerationStructuresIndirectKHR"
extern "c" fn load_vkBuildAccelerationStructuresKHR(dev : VkDevice) -> FuncRef[(VkDevice, VkDeferredOperationKHR, UInt32, VkAccelerationStructureBuildGeometryInfoKHR, FixedArray[UInt64]) -> Int32] = "tycho_gpa_vkBuildAccelerationStructuresKHR"
extern "c" fn load_vkGetAccelerationStructureDeviceAddressKHR(dev : VkDevice) -> FuncRef[(VkDevice, VkAccelerationStructureDeviceAddressInfoKHR) -> UInt64] = "tycho_gpa_vkGetAccelerationStructureDeviceAddressKHR"
extern "c" fn load_vkCreateDeferredOperationKHR(dev : VkDevice) -> FuncRef[(VkDevice, VkAllocationCallbacks, FixedArray[VkDeferredOperationKHR]) -> Int32] = "tycho_gpa_vkCreateDeferredOperationKHR"
extern "c" fn load_vkDestroyDeferredOperationKHR(dev : VkDevice) -> FuncRef[(VkDevice, VkDeferredOperationKHR, VkAllocationCallbacks) -> Unit] = "tycho_gpa_vkDestroyDeferredOperationKHR"
extern "c" fn load_vkGetDeferredOperationMaxConcurrencyKHR(dev : VkDevice) -> FuncRef[(VkDevice, VkDeferredOperationKHR) -> UInt32] = "tycho_gpa_vkGetDeferredOperationMaxConcurrencyKHR"
extern "c" fn load_vkGetDeferredOperationResultKHR(dev : VkDevice) -> FuncRef[(VkDevice, VkDeferredOperationKHR) -> Int32] = "tycho_gpa_vkGetDeferredOperationResultKHR"
extern "c" fn load_vkDeferredOperationJoinKHR(dev : VkDevice) -> FuncRef[(VkDevice, VkDeferredOperationKHR) -> Int32] = "tycho_gpa_vkDeferredOperationJoinKHR"
extern "c" fn load_vkGetPipelineIndirectMemoryRequirementsNV(dev : VkDevice) -> FuncRef[(VkDevice, VkComputePipelineCreateInfo, VkMemoryRequirements2) -> Unit] = "tycho_gpa_vkGetPipelineIndirectMemoryRequirementsNV"
extern "c" fn load_vkGetPipelineIndirectDeviceAddressNV(dev : VkDevice) -> FuncRef[(VkDevice, VkPipelineIndirectDeviceAddressInfoNV) -> UInt64] = "tycho_gpa_vkGetPipelineIndirectDeviceAddressNV"
extern "c" fn load_vkAntiLagUpdateAMD(dev : VkDevice) -> FuncRef[(VkDevice, VkAntiLagDataAMD) -> Unit] = "tycho_gpa_vkAntiLagUpdateAMD"
extern "c" fn load_vkCmdSetCullMode(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32) -> Unit] = "tycho_gpa_vkCmdSetCullMode"
extern "c" fn load_vkCmdSetCullModeEXT(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32) -> Unit] = "tycho_gpa_vkCmdSetCullModeEXT"
extern "c" fn load_vkCmdSetFrontFace(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32) -> Unit] = "tycho_gpa_vkCmdSetFrontFace"
extern "c" fn load_vkCmdSetFrontFaceEXT(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32) -> Unit] = "tycho_gpa_vkCmdSetFrontFaceEXT"
extern "c" fn load_vkCmdSetPrimitiveTopology(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32) -> Unit] = "tycho_gpa_vkCmdSetPrimitiveTopology"
extern "c" fn load_vkCmdSetPrimitiveTopologyEXT(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32) -> Unit] = "tycho_gpa_vkCmdSetPrimitiveTopologyEXT"
extern "c" fn load_vkCmdSetViewportWithCount(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32, VkViewport) -> Unit] = "tycho_gpa_vkCmdSetViewportWithCount"
extern "c" fn load_vkCmdSetViewportWithCountEXT(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32, VkViewport) -> Unit] = "tycho_gpa_vkCmdSetViewportWithCountEXT"
extern "c" fn load_vkCmdSetScissorWithCount(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32, VkRect2D) -> Unit] = "tycho_gpa_vkCmdSetScissorWithCount"
extern "c" fn load_vkCmdSetScissorWithCountEXT(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32, VkRect2D) -> Unit] = "tycho_gpa_vkCmdSetScissorWithCountEXT"
extern "c" fn load_vkCmdBindIndexBuffer2(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkBuffer, UInt64, UInt64, UInt32) -> Unit] = "tycho_gpa_vkCmdBindIndexBuffer2"
extern "c" fn load_vkCmdBindIndexBuffer2KHR(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkBuffer, UInt64, UInt64, UInt32) -> Unit] = "tycho_gpa_vkCmdBindIndexBuffer2KHR"
extern "c" fn load_vkCmdBindVertexBuffers2(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32, UInt32, FixedArray[VkBuffer], FixedArray[UInt64], FixedArray[UInt64], FixedArray[UInt64]) -> Unit] = "tycho_gpa_vkCmdBindVertexBuffers2"
extern "c" fn load_vkCmdBindVertexBuffers2EXT(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32, UInt32, FixedArray[VkBuffer], FixedArray[UInt64], FixedArray[UInt64], FixedArray[UInt64]) -> Unit] = "tycho_gpa_vkCmdBindVertexBuffers2EXT"
extern "c" fn load_vkCmdSetDepthTestEnable(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32) -> Unit] = "tycho_gpa_vkCmdSetDepthTestEnable"
extern "c" fn load_vkCmdSetDepthTestEnableEXT(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32) -> Unit] = "tycho_gpa_vkCmdSetDepthTestEnableEXT"
extern "c" fn load_vkCmdSetDepthWriteEnable(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32) -> Unit] = "tycho_gpa_vkCmdSetDepthWriteEnable"
extern "c" fn load_vkCmdSetDepthWriteEnableEXT(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32) -> Unit] = "tycho_gpa_vkCmdSetDepthWriteEnableEXT"
extern "c" fn load_vkCmdSetDepthCompareOp(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32) -> Unit] = "tycho_gpa_vkCmdSetDepthCompareOp"
extern "c" fn load_vkCmdSetDepthCompareOpEXT(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32) -> Unit] = "tycho_gpa_vkCmdSetDepthCompareOpEXT"
extern "c" fn load_vkCmdSetDepthBoundsTestEnable(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32) -> Unit] = "tycho_gpa_vkCmdSetDepthBoundsTestEnable"
extern "c" fn load_vkCmdSetDepthBoundsTestEnableEXT(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32) -> Unit] = "tycho_gpa_vkCmdSetDepthBoundsTestEnableEXT"
extern "c" fn load_vkCmdSetStencilTestEnable(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32) -> Unit] = "tycho_gpa_vkCmdSetStencilTestEnable"
extern "c" fn load_vkCmdSetStencilTestEnableEXT(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32) -> Unit] = "tycho_gpa_vkCmdSetStencilTestEnableEXT"
extern "c" fn load_vkCmdSetStencilOp(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32, UInt32, UInt32, UInt32, UInt32) -> Unit] = "tycho_gpa_vkCmdSetStencilOp"
extern "c" fn load_vkCmdSetStencilOpEXT(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32, UInt32, UInt32, UInt32, UInt32) -> Unit] = "tycho_gpa_vkCmdSetStencilOpEXT"
extern "c" fn load_vkCmdSetPatchControlPointsEXT(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32) -> Unit] = "tycho_gpa_vkCmdSetPatchControlPointsEXT"
extern "c" fn load_vkCmdSetRasterizerDiscardEnable(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32) -> Unit] = "tycho_gpa_vkCmdSetRasterizerDiscardEnable"
extern "c" fn load_vkCmdSetRasterizerDiscardEnableEXT(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32) -> Unit] = "tycho_gpa_vkCmdSetRasterizerDiscardEnableEXT"
extern "c" fn load_vkCmdSetDepthBiasEnable(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32) -> Unit] = "tycho_gpa_vkCmdSetDepthBiasEnable"
extern "c" fn load_vkCmdSetDepthBiasEnableEXT(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32) -> Unit] = "tycho_gpa_vkCmdSetDepthBiasEnableEXT"
extern "c" fn load_vkCmdSetLogicOpEXT(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32) -> Unit] = "tycho_gpa_vkCmdSetLogicOpEXT"
extern "c" fn load_vkCmdSetPrimitiveRestartEnable(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32) -> Unit] = "tycho_gpa_vkCmdSetPrimitiveRestartEnable"
extern "c" fn load_vkCmdSetPrimitiveRestartEnableEXT(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32) -> Unit] = "tycho_gpa_vkCmdSetPrimitiveRestartEnableEXT"
extern "c" fn load_vkCmdSetTessellationDomainOriginEXT(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32) -> Unit] = "tycho_gpa_vkCmdSetTessellationDomainOriginEXT"
extern "c" fn load_vkCmdSetDepthClampEnableEXT(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32) -> Unit] = "tycho_gpa_vkCmdSetDepthClampEnableEXT"
extern "c" fn load_vkCmdSetPolygonModeEXT(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32) -> Unit] = "tycho_gpa_vkCmdSetPolygonModeEXT"
extern "c" fn load_vkCmdSetRasterizationSamplesEXT(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32) -> Unit] = "tycho_gpa_vkCmdSetRasterizationSamplesEXT"
extern "c" fn load_vkCmdSetSampleMaskEXT(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32, FixedArray[UInt32]) -> Unit] = "tycho_gpa_vkCmdSetSampleMaskEXT"
extern "c" fn load_vkCmdSetAlphaToCoverageEnableEXT(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32) -> Unit] = "tycho_gpa_vkCmdSetAlphaToCoverageEnableEXT"
extern "c" fn load_vkCmdSetAlphaToOneEnableEXT(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32) -> Unit] = "tycho_gpa_vkCmdSetAlphaToOneEnableEXT"
extern "c" fn load_vkCmdSetLogicOpEnableEXT(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32) -> Unit] = "tycho_gpa_vkCmdSetLogicOpEnableEXT"
extern "c" fn load_vkCmdSetColorBlendEnableEXT(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32, UInt32, FixedArray[UInt32]) -> Unit] = "tycho_gpa_vkCmdSetColorBlendEnableEXT"
extern "c" fn load_vkCmdSetColorBlendEquationEXT(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32, UInt32, VkColorBlendEquationEXT) -> Unit] = "tycho_gpa_vkCmdSetColorBlendEquationEXT"
extern "c" fn load_vkCmdSetColorWriteMaskEXT(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32, UInt32, FixedArray[UInt32]) -> Unit] = "tycho_gpa_vkCmdSetColorWriteMaskEXT"
extern "c" fn load_vkCmdSetRasterizationStreamEXT(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32) -> Unit] = "tycho_gpa_vkCmdSetRasterizationStreamEXT"
extern "c" fn load_vkCmdSetConservativeRasterizationModeEXT(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32) -> Unit] = "tycho_gpa_vkCmdSetConservativeRasterizationModeEXT"
extern "c" fn load_vkCmdSetExtraPrimitiveOverestimationSizeEXT(dev : VkDevice) -> FuncRef[(VkCommandBuffer, Float) -> Unit] = "tycho_gpa_vkCmdSetExtraPrimitiveOverestimationSizeEXT"
extern "c" fn load_vkCmdSetDepthClipEnableEXT(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32) -> Unit] = "tycho_gpa_vkCmdSetDepthClipEnableEXT"
extern "c" fn load_vkCmdSetSampleLocationsEnableEXT(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32) -> Unit] = "tycho_gpa_vkCmdSetSampleLocationsEnableEXT"
extern "c" fn load_vkCmdSetColorBlendAdvancedEXT(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32, UInt32, VkColorBlendAdvancedEXT) -> Unit] = "tycho_gpa_vkCmdSetColorBlendAdvancedEXT"
extern "c" fn load_vkCmdSetProvokingVertexModeEXT(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32) -> Unit] = "tycho_gpa_vkCmdSetProvokingVertexModeEXT"
extern "c" fn load_vkCmdSetLineRasterizationModeEXT(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32) -> Unit] = "tycho_gpa_vkCmdSetLineRasterizationModeEXT"
extern "c" fn load_vkCmdSetLineStippleEnableEXT(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32) -> Unit] = "tycho_gpa_vkCmdSetLineStippleEnableEXT"
extern "c" fn load_vkCmdSetDepthClipNegativeOneToOneEXT(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32) -> Unit] = "tycho_gpa_vkCmdSetDepthClipNegativeOneToOneEXT"
extern "c" fn load_vkCmdSetViewportWScalingEnableNV(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32) -> Unit] = "tycho_gpa_vkCmdSetViewportWScalingEnableNV"
extern "c" fn load_vkCmdSetViewportSwizzleNV(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32, UInt32, VkViewportSwizzleNV) -> Unit] = "tycho_gpa_vkCmdSetViewportSwizzleNV"
extern "c" fn load_vkCmdSetCoverageToColorEnableNV(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32) -> Unit] = "tycho_gpa_vkCmdSetCoverageToColorEnableNV"
extern "c" fn load_vkCmdSetCoverageToColorLocationNV(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32) -> Unit] = "tycho_gpa_vkCmdSetCoverageToColorLocationNV"
extern "c" fn load_vkCmdSetCoverageModulationModeNV(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32) -> Unit] = "tycho_gpa_vkCmdSetCoverageModulationModeNV"
extern "c" fn load_vkCmdSetCoverageModulationTableEnableNV(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32) -> Unit] = "tycho_gpa_vkCmdSetCoverageModulationTableEnableNV"
extern "c" fn load_vkCmdSetCoverageModulationTableNV(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32, FixedArray[Float]) -> Unit] = "tycho_gpa_vkCmdSetCoverageModulationTableNV"
extern "c" fn load_vkCmdSetShadingRateImageEnableNV(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32) -> Unit] = "tycho_gpa_vkCmdSetShadingRateImageEnableNV"
extern "c" fn load_vkCmdSetCoverageReductionModeNV(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32) -> Unit] = "tycho_gpa_vkCmdSetCoverageReductionModeNV"
extern "c" fn load_vkCmdSetRepresentativeFragmentTestEnableNV(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32) -> Unit] = "tycho_gpa_vkCmdSetRepresentativeFragmentTestEnableNV"
extern "c" fn load_vkCreatePrivateDataSlot(dev : VkDevice) -> FuncRef[(VkDevice, VkPrivateDataSlotCreateInfo, VkAllocationCallbacks, FixedArray[VkPrivateDataSlot]) -> Int32] = "tycho_gpa_vkCreatePrivateDataSlot"
extern "c" fn load_vkCreatePrivateDataSlotEXT(dev : VkDevice) -> FuncRef[(VkDevice, VkPrivateDataSlotCreateInfo, VkAllocationCallbacks, FixedArray[VkPrivateDataSlot]) -> Int32] = "tycho_gpa_vkCreatePrivateDataSlotEXT"
extern "c" fn load_vkDestroyPrivateDataSlot(dev : VkDevice) -> FuncRef[(VkDevice, VkPrivateDataSlot, VkAllocationCallbacks) -> Unit] = "tycho_gpa_vkDestroyPrivateDataSlot"
extern "c" fn load_vkDestroyPrivateDataSlotEXT(dev : VkDevice) -> FuncRef[(VkDevice, VkPrivateDataSlot, VkAllocationCallbacks) -> Unit] = "tycho_gpa_vkDestroyPrivateDataSlotEXT"
extern "c" fn load_vkSetPrivateData(dev : VkDevice) -> FuncRef[(VkDevice, UInt32, UInt64, VkPrivateDataSlot, UInt64) -> Int32] = "tycho_gpa_vkSetPrivateData"
extern "c" fn load_vkSetPrivateDataEXT(dev : VkDevice) -> FuncRef[(VkDevice, UInt32, UInt64, VkPrivateDataSlot, UInt64) -> Int32] = "tycho_gpa_vkSetPrivateDataEXT"
extern "c" fn load_vkGetPrivateData(dev : VkDevice) -> FuncRef[(VkDevice, UInt32, UInt64, VkPrivateDataSlot, FixedArray[UInt64]) -> Unit] = "tycho_gpa_vkGetPrivateData"
extern "c" fn load_vkGetPrivateDataEXT(dev : VkDevice) -> FuncRef[(VkDevice, UInt32, UInt64, VkPrivateDataSlot, FixedArray[UInt64]) -> Unit] = "tycho_gpa_vkGetPrivateDataEXT"
extern "c" fn load_vkCmdCopyBuffer2(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkCopyBufferInfo2) -> Unit] = "tycho_gpa_vkCmdCopyBuffer2"
extern "c" fn load_vkCmdCopyBuffer2KHR(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkCopyBufferInfo2) -> Unit] = "tycho_gpa_vkCmdCopyBuffer2KHR"
extern "c" fn load_vkCmdCopyImage2(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkCopyImageInfo2) -> Unit] = "tycho_gpa_vkCmdCopyImage2"
extern "c" fn load_vkCmdCopyImage2KHR(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkCopyImageInfo2) -> Unit] = "tycho_gpa_vkCmdCopyImage2KHR"
extern "c" fn load_vkCmdBlitImage2(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkBlitImageInfo2) -> Unit] = "tycho_gpa_vkCmdBlitImage2"
extern "c" fn load_vkCmdBlitImage2KHR(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkBlitImageInfo2) -> Unit] = "tycho_gpa_vkCmdBlitImage2KHR"
extern "c" fn load_vkCmdCopyBufferToImage2(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkCopyBufferToImageInfo2) -> Unit] = "tycho_gpa_vkCmdCopyBufferToImage2"
extern "c" fn load_vkCmdCopyBufferToImage2KHR(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkCopyBufferToImageInfo2) -> Unit] = "tycho_gpa_vkCmdCopyBufferToImage2KHR"
extern "c" fn load_vkCmdCopyImageToBuffer2(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkCopyImageToBufferInfo2) -> Unit] = "tycho_gpa_vkCmdCopyImageToBuffer2"
extern "c" fn load_vkCmdCopyImageToBuffer2KHR(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkCopyImageToBufferInfo2) -> Unit] = "tycho_gpa_vkCmdCopyImageToBuffer2KHR"
extern "c" fn load_vkCmdResolveImage2(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkResolveImageInfo2) -> Unit] = "tycho_gpa_vkCmdResolveImage2"
extern "c" fn load_vkCmdResolveImage2KHR(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkResolveImageInfo2) -> Unit] = "tycho_gpa_vkCmdResolveImage2KHR"
extern "c" fn load_vkCmdRefreshObjectsKHR(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkRefreshObjectListKHR) -> Unit] = "tycho_gpa_vkCmdRefreshObjectsKHR"
extern "c" fn load_vkCmdSetFragmentShadingRateKHR(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkExtent2D, FixedArray[UInt32]) -> Unit] = "tycho_gpa_vkCmdSetFragmentShadingRateKHR"
extern "c" fn load_vkCmdSetFragmentShadingRateEnumNV(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32, FixedArray[UInt32]) -> Unit] = "tycho_gpa_vkCmdSetFragmentShadingRateEnumNV"
extern "c" fn load_vkGetAccelerationStructureBuildSizesKHR(dev : VkDevice) -> FuncRef[(VkDevice, UInt32, VkAccelerationStructureBuildGeometryInfoKHR, FixedArray[UInt32], VkAccelerationStructureBuildSizesInfoKHR) -> Unit] = "tycho_gpa_vkGetAccelerationStructureBuildSizesKHR"
extern "c" fn load_vkCmdSetVertexInputEXT(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32, VkVertexInputBindingDescription2EXT, UInt32, VkVertexInputAttributeDescription2EXT) -> Unit] = "tycho_gpa_vkCmdSetVertexInputEXT"
extern "c" fn load_vkCmdSetColorWriteEnableEXT(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32, FixedArray[UInt32]) -> Unit] = "tycho_gpa_vkCmdSetColorWriteEnableEXT"
extern "c" fn load_vkCmdSetEvent2(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkEvent, VkDependencyInfo) -> Unit] = "tycho_gpa_vkCmdSetEvent2"
extern "c" fn load_vkCmdSetEvent2KHR(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkEvent, VkDependencyInfo) -> Unit] = "tycho_gpa_vkCmdSetEvent2KHR"
extern "c" fn load_vkCmdResetEvent2(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkEvent, UInt64) -> Unit] = "tycho_gpa_vkCmdResetEvent2"
extern "c" fn load_vkCmdResetEvent2KHR(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkEvent, UInt64) -> Unit] = "tycho_gpa_vkCmdResetEvent2KHR"
extern "c" fn load_vkCmdWaitEvents2(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32, FixedArray[VkEvent], VkDependencyInfo) -> Unit] = "tycho_gpa_vkCmdWaitEvents2"
extern "c" fn load_vkCmdWaitEvents2KHR(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32, FixedArray[VkEvent], VkDependencyInfo) -> Unit] = "tycho_gpa_vkCmdWaitEvents2KHR"
extern "c" fn load_vkCmdPipelineBarrier2(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkDependencyInfo) -> Unit] = "tycho_gpa_vkCmdPipelineBarrier2"
extern "c" fn load_vkCmdPipelineBarrier2KHR(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkDependencyInfo) -> Unit] = "tycho_gpa_vkCmdPipelineBarrier2KHR"
extern "c" fn load_vkQueueSubmit2(dev : VkDevice) -> FuncRef[(VkQueue, UInt32, VkSubmitInfo2, VkFence) -> Int32] = "tycho_gpa_vkQueueSubmit2"
extern "c" fn load_vkQueueSubmit2KHR(dev : VkDevice) -> FuncRef[(VkQueue, UInt32, VkSubmitInfo2, VkFence) -> Int32] = "tycho_gpa_vkQueueSubmit2KHR"
extern "c" fn load_vkCmdWriteTimestamp2(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt64, VkQueryPool, UInt32) -> Unit] = "tycho_gpa_vkCmdWriteTimestamp2"
extern "c" fn load_vkCmdWriteTimestamp2KHR(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt64, VkQueryPool, UInt32) -> Unit] = "tycho_gpa_vkCmdWriteTimestamp2KHR"
extern "c" fn load_vkCmdWriteBufferMarker2AMD(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt64, VkBuffer, UInt64, UInt32) -> Unit] = "tycho_gpa_vkCmdWriteBufferMarker2AMD"
extern "c" fn load_vkGetQueueCheckpointData2NV(dev : VkDevice) -> FuncRef[(VkQueue, FixedArray[UInt32], VkCheckpointData2NV) -> Unit] = "tycho_gpa_vkGetQueueCheckpointData2NV"
extern "c" fn load_vkCopyMemoryToImage(dev : VkDevice) -> FuncRef[(VkDevice, VkCopyMemoryToImageInfo) -> Int32] = "tycho_gpa_vkCopyMemoryToImage"
extern "c" fn load_vkCopyMemoryToImageEXT(dev : VkDevice) -> FuncRef[(VkDevice, VkCopyMemoryToImageInfo) -> Int32] = "tycho_gpa_vkCopyMemoryToImageEXT"
extern "c" fn load_vkCopyImageToMemory(dev : VkDevice) -> FuncRef[(VkDevice, VkCopyImageToMemoryInfo) -> Int32] = "tycho_gpa_vkCopyImageToMemory"
extern "c" fn load_vkCopyImageToMemoryEXT(dev : VkDevice) -> FuncRef[(VkDevice, VkCopyImageToMemoryInfo) -> Int32] = "tycho_gpa_vkCopyImageToMemoryEXT"
extern "c" fn load_vkCopyImageToImage(dev : VkDevice) -> FuncRef[(VkDevice, VkCopyImageToImageInfo) -> Int32] = "tycho_gpa_vkCopyImageToImage"
extern "c" fn load_vkCopyImageToImageEXT(dev : VkDevice) -> FuncRef[(VkDevice, VkCopyImageToImageInfo) -> Int32] = "tycho_gpa_vkCopyImageToImageEXT"
extern "c" fn load_vkTransitionImageLayout(dev : VkDevice) -> FuncRef[(VkDevice, UInt32, VkHostImageLayoutTransitionInfo) -> Int32] = "tycho_gpa_vkTransitionImageLayout"
extern "c" fn load_vkTransitionImageLayoutEXT(dev : VkDevice) -> FuncRef[(VkDevice, UInt32, VkHostImageLayoutTransitionInfo) -> Int32] = "tycho_gpa_vkTransitionImageLayoutEXT"
extern "c" fn load_vkGetCommandPoolMemoryConsumption(dev : VkDevice) -> FuncRef[(VkDevice, VkCommandPool, VkCommandBuffer, VkCommandPoolMemoryConsumption) -> Unit] = "tycho_gpa_vkGetCommandPoolMemoryConsumption"
extern "c" fn load_vkCreateVideoSessionKHR(dev : VkDevice) -> FuncRef[(VkDevice, VkVideoSessionCreateInfoKHR, VkAllocationCallbacks, FixedArray[VkVideoSessionKHR]) -> Int32] = "tycho_gpa_vkCreateVideoSessionKHR"
extern "c" fn load_vkDestroyVideoSessionKHR(dev : VkDevice) -> FuncRef[(VkDevice, VkVideoSessionKHR, VkAllocationCallbacks) -> Unit] = "tycho_gpa_vkDestroyVideoSessionKHR"
extern "c" fn load_vkCreateVideoSessionParametersKHR(dev : VkDevice) -> FuncRef[(VkDevice, VkVideoSessionParametersCreateInfoKHR, VkAllocationCallbacks, FixedArray[VkVideoSessionParametersKHR]) -> Int32] = "tycho_gpa_vkCreateVideoSessionParametersKHR"
extern "c" fn load_vkUpdateVideoSessionParametersKHR(dev : VkDevice) -> FuncRef[(VkDevice, VkVideoSessionParametersKHR, VkVideoSessionParametersUpdateInfoKHR) -> Int32] = "tycho_gpa_vkUpdateVideoSessionParametersKHR"
extern "c" fn load_vkGetEncodedVideoSessionParametersKHR(dev : VkDevice) -> FuncRef[(VkDevice, VkVideoEncodeSessionParametersGetInfoKHR, VkVideoEncodeSessionParametersFeedbackInfoKHR, FixedArray[UInt64], UInt64) -> Int32] = "tycho_gpa_vkGetEncodedVideoSessionParametersKHR"
extern "c" fn load_vkDestroyVideoSessionParametersKHR(dev : VkDevice) -> FuncRef[(VkDevice, VkVideoSessionParametersKHR, VkAllocationCallbacks) -> Unit] = "tycho_gpa_vkDestroyVideoSessionParametersKHR"
extern "c" fn load_vkGetVideoSessionMemoryRequirementsKHR(dev : VkDevice) -> FuncRef[(VkDevice, VkVideoSessionKHR, FixedArray[UInt32], VkVideoSessionMemoryRequirementsKHR) -> Int32] = "tycho_gpa_vkGetVideoSessionMemoryRequirementsKHR"
extern "c" fn load_vkBindVideoSessionMemoryKHR(dev : VkDevice) -> FuncRef[(VkDevice, VkVideoSessionKHR, UInt32, VkBindVideoSessionMemoryInfoKHR) -> Int32] = "tycho_gpa_vkBindVideoSessionMemoryKHR"
extern "c" fn load_vkCmdDecodeVideoKHR(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkVideoDecodeInfoKHR) -> Unit] = "tycho_gpa_vkCmdDecodeVideoKHR"
extern "c" fn load_vkCmdBeginVideoCodingKHR(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkVideoBeginCodingInfoKHR) -> Unit] = "tycho_gpa_vkCmdBeginVideoCodingKHR"
extern "c" fn load_vkCmdControlVideoCodingKHR(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkVideoCodingControlInfoKHR) -> Unit] = "tycho_gpa_vkCmdControlVideoCodingKHR"
extern "c" fn load_vkCmdEndVideoCodingKHR(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkVideoEndCodingInfoKHR) -> Unit] = "tycho_gpa_vkCmdEndVideoCodingKHR"
extern "c" fn load_vkCmdEncodeVideoKHR(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkVideoEncodeInfoKHR) -> Unit] = "tycho_gpa_vkCmdEncodeVideoKHR"
extern "c" fn load_vkCmdDecompressMemoryNV(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32, VkDecompressMemoryRegionNV) -> Unit] = "tycho_gpa_vkCmdDecompressMemoryNV"
extern "c" fn load_vkCmdDecompressMemoryIndirectCountNV(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt64, UInt64, UInt32) -> Unit] = "tycho_gpa_vkCmdDecompressMemoryIndirectCountNV"
extern "c" fn load_vkGetPartitionedAccelerationStructuresBuildSizesNV(dev : VkDevice) -> FuncRef[(VkDevice, VkPartitionedAccelerationStructureInstancesInputNV, VkAccelerationStructureBuildSizesInfoKHR) -> Unit] = "tycho_gpa_vkGetPartitionedAccelerationStructuresBuildSizesNV"
extern "c" fn load_vkCmdBuildPartitionedAccelerationStructuresNV(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkBuildPartitionedAccelerationStructureInfoNV) -> Unit] = "tycho_gpa_vkCmdBuildPartitionedAccelerationStructuresNV"
extern "c" fn load_vkCmdDecompressMemoryEXT(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkDecompressMemoryInfoEXT) -> Unit] = "tycho_gpa_vkCmdDecompressMemoryEXT"
extern "c" fn load_vkCmdDecompressMemoryIndirectCountEXT(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt64, UInt64, UInt64, UInt32, UInt32) -> Unit] = "tycho_gpa_vkCmdDecompressMemoryIndirectCountEXT"
extern "c" fn load_vkCreateCuModuleNVX(dev : VkDevice) -> FuncRef[(VkDevice, VkCuModuleCreateInfoNVX, VkAllocationCallbacks, FixedArray[VkCuModuleNVX]) -> Int32] = "tycho_gpa_vkCreateCuModuleNVX"
extern "c" fn load_vkCreateCuFunctionNVX(dev : VkDevice) -> FuncRef[(VkDevice, VkCuFunctionCreateInfoNVX, VkAllocationCallbacks, FixedArray[VkCuFunctionNVX]) -> Int32] = "tycho_gpa_vkCreateCuFunctionNVX"
extern "c" fn load_vkDestroyCuModuleNVX(dev : VkDevice) -> FuncRef[(VkDevice, VkCuModuleNVX, VkAllocationCallbacks) -> Unit] = "tycho_gpa_vkDestroyCuModuleNVX"
extern "c" fn load_vkDestroyCuFunctionNVX(dev : VkDevice) -> FuncRef[(VkDevice, VkCuFunctionNVX, VkAllocationCallbacks) -> Unit] = "tycho_gpa_vkDestroyCuFunctionNVX"
extern "c" fn load_vkCmdCuLaunchKernelNVX(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkCuLaunchInfoNVX) -> Unit] = "tycho_gpa_vkCmdCuLaunchKernelNVX"
extern "c" fn load_vkGetDescriptorSetLayoutSizeEXT(dev : VkDevice) -> FuncRef[(VkDevice, VkDescriptorSetLayout, FixedArray[UInt64]) -> Unit] = "tycho_gpa_vkGetDescriptorSetLayoutSizeEXT"
extern "c" fn load_vkGetDescriptorSetLayoutBindingOffsetEXT(dev : VkDevice) -> FuncRef[(VkDevice, VkDescriptorSetLayout, UInt32, FixedArray[UInt64]) -> Unit] = "tycho_gpa_vkGetDescriptorSetLayoutBindingOffsetEXT"
extern "c" fn load_vkGetDescriptorEXT(dev : VkDevice) -> FuncRef[(VkDevice, VkDescriptorGetInfoEXT, UInt64, UInt64) -> Unit] = "tycho_gpa_vkGetDescriptorEXT"
extern "c" fn load_vkCmdBindDescriptorBuffersEXT(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32, VkDescriptorBufferBindingInfoEXT) -> Unit] = "tycho_gpa_vkCmdBindDescriptorBuffersEXT"
extern "c" fn load_vkCmdSetDescriptorBufferOffsetsEXT(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32, VkPipelineLayout, UInt32, UInt32, FixedArray[UInt32], FixedArray[UInt64]) -> Unit] = "tycho_gpa_vkCmdSetDescriptorBufferOffsetsEXT"
extern "c" fn load_vkCmdBindDescriptorBufferEmbeddedSamplersEXT(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32, VkPipelineLayout, UInt32) -> Unit] = "tycho_gpa_vkCmdBindDescriptorBufferEmbeddedSamplersEXT"
extern "c" fn load_vkGetBufferOpaqueCaptureDescriptorDataEXT(dev : VkDevice) -> FuncRef[(VkDevice, VkBufferCaptureDescriptorDataInfoEXT, UInt64) -> Int32] = "tycho_gpa_vkGetBufferOpaqueCaptureDescriptorDataEXT"
extern "c" fn load_vkGetImageOpaqueCaptureDescriptorDataEXT(dev : VkDevice) -> FuncRef[(VkDevice, VkImageCaptureDescriptorDataInfoEXT, UInt64) -> Int32] = "tycho_gpa_vkGetImageOpaqueCaptureDescriptorDataEXT"
extern "c" fn load_vkGetImageViewOpaqueCaptureDescriptorDataEXT(dev : VkDevice) -> FuncRef[(VkDevice, VkImageViewCaptureDescriptorDataInfoEXT, UInt64) -> Int32] = "tycho_gpa_vkGetImageViewOpaqueCaptureDescriptorDataEXT"
extern "c" fn load_vkGetSamplerOpaqueCaptureDescriptorDataEXT(dev : VkDevice) -> FuncRef[(VkDevice, VkSamplerCaptureDescriptorDataInfoEXT, UInt64) -> Int32] = "tycho_gpa_vkGetSamplerOpaqueCaptureDescriptorDataEXT"
extern "c" fn load_vkGetAccelerationStructureOpaqueCaptureDescriptorDataEXT(dev : VkDevice) -> FuncRef[(VkDevice, VkAccelerationStructureCaptureDescriptorDataInfoEXT, UInt64) -> Int32] = "tycho_gpa_vkGetAccelerationStructureOpaqueCaptureDescriptorDataEXT"
extern "c" fn load_vkSetDeviceMemoryPriorityEXT(dev : VkDevice) -> FuncRef[(VkDevice, VkDeviceMemory, Float) -> Unit] = "tycho_gpa_vkSetDeviceMemoryPriorityEXT"
extern "c" fn load_vkWaitForPresent2KHR(dev : VkDevice) -> FuncRef[(VkDevice, VkSwapchainKHR, VkPresentWait2InfoKHR) -> Int32] = "tycho_gpa_vkWaitForPresent2KHR"
extern "c" fn load_vkWaitForPresentKHR(dev : VkDevice) -> FuncRef[(VkDevice, VkSwapchainKHR, UInt64, UInt64) -> Int32] = "tycho_gpa_vkWaitForPresentKHR"
extern "c" fn load_vkCreateBufferCollectionFUCHSIA(dev : VkDevice) -> FuncRef[(VkDevice, VkBufferCollectionCreateInfoFUCHSIA, VkAllocationCallbacks, FixedArray[VkBufferCollectionFUCHSIA]) -> Int32] = "tycho_gpa_vkCreateBufferCollectionFUCHSIA"
extern "c" fn load_vkSetBufferCollectionBufferConstraintsFUCHSIA(dev : VkDevice) -> FuncRef[(VkDevice, VkBufferCollectionFUCHSIA, VkBufferConstraintsInfoFUCHSIA) -> Int32] = "tycho_gpa_vkSetBufferCollectionBufferConstraintsFUCHSIA"
extern "c" fn load_vkSetBufferCollectionImageConstraintsFUCHSIA(dev : VkDevice) -> FuncRef[(VkDevice, VkBufferCollectionFUCHSIA, VkImageConstraintsInfoFUCHSIA) -> Int32] = "tycho_gpa_vkSetBufferCollectionImageConstraintsFUCHSIA"
extern "c" fn load_vkDestroyBufferCollectionFUCHSIA(dev : VkDevice) -> FuncRef[(VkDevice, VkBufferCollectionFUCHSIA, VkAllocationCallbacks) -> Unit] = "tycho_gpa_vkDestroyBufferCollectionFUCHSIA"
extern "c" fn load_vkGetBufferCollectionPropertiesFUCHSIA(dev : VkDevice) -> FuncRef[(VkDevice, VkBufferCollectionFUCHSIA, VkBufferCollectionPropertiesFUCHSIA) -> Int32] = "tycho_gpa_vkGetBufferCollectionPropertiesFUCHSIA"
extern "c" fn load_vkCreateCudaModuleNV(dev : VkDevice) -> FuncRef[(VkDevice, VkCudaModuleCreateInfoNV, VkAllocationCallbacks, FixedArray[VkCudaModuleNV]) -> Int32] = "tycho_gpa_vkCreateCudaModuleNV"
extern "c" fn load_vkGetCudaModuleCacheNV(dev : VkDevice) -> FuncRef[(VkDevice, VkCudaModuleNV, FixedArray[UInt64], UInt64) -> Int32] = "tycho_gpa_vkGetCudaModuleCacheNV"
extern "c" fn load_vkCreateCudaFunctionNV(dev : VkDevice) -> FuncRef[(VkDevice, VkCudaFunctionCreateInfoNV, VkAllocationCallbacks, FixedArray[VkCudaFunctionNV]) -> Int32] = "tycho_gpa_vkCreateCudaFunctionNV"
extern "c" fn load_vkDestroyCudaModuleNV(dev : VkDevice) -> FuncRef[(VkDevice, VkCudaModuleNV, VkAllocationCallbacks) -> Unit] = "tycho_gpa_vkDestroyCudaModuleNV"
extern "c" fn load_vkDestroyCudaFunctionNV(dev : VkDevice) -> FuncRef[(VkDevice, VkCudaFunctionNV, VkAllocationCallbacks) -> Unit] = "tycho_gpa_vkDestroyCudaFunctionNV"
extern "c" fn load_vkCmdCudaLaunchKernelNV(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkCudaLaunchInfoNV) -> Unit] = "tycho_gpa_vkCmdCudaLaunchKernelNV"
extern "c" fn load_vkCmdBeginRendering(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkRenderingInfo) -> Unit] = "tycho_gpa_vkCmdBeginRendering"
extern "c" fn load_vkCmdBeginRenderingKHR(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkRenderingInfo) -> Unit] = "tycho_gpa_vkCmdBeginRenderingKHR"
extern "c" fn load_vkCmdEndRendering(dev : VkDevice) -> FuncRef[(VkCommandBuffer) -> Unit] = "tycho_gpa_vkCmdEndRendering"
extern "c" fn load_vkCmdEndRendering2KHR(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkRenderingEndInfoKHR) -> Unit] = "tycho_gpa_vkCmdEndRendering2KHR"
extern "c" fn load_vkCmdEndRendering2EXT(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkRenderingEndInfoKHR) -> Unit] = "tycho_gpa_vkCmdEndRendering2EXT"
extern "c" fn load_vkCmdEndRenderingKHR(dev : VkDevice) -> FuncRef[(VkCommandBuffer) -> Unit] = "tycho_gpa_vkCmdEndRenderingKHR"
extern "c" fn load_vkGetDescriptorSetLayoutHostMappingInfoVALVE(dev : VkDevice) -> FuncRef[(VkDevice, VkDescriptorSetBindingReferenceVALVE, VkDescriptorSetLayoutHostMappingInfoVALVE) -> Unit] = "tycho_gpa_vkGetDescriptorSetLayoutHostMappingInfoVALVE"
extern "c" fn load_vkGetDescriptorSetHostMappingVALVE(dev : VkDevice) -> FuncRef[(VkDevice, VkDescriptorSet, FixedArray[UInt64]) -> Unit] = "tycho_gpa_vkGetDescriptorSetHostMappingVALVE"
extern "c" fn load_vkCreateMicromapEXT(dev : VkDevice) -> FuncRef[(VkDevice, VkMicromapCreateInfoEXT, VkAllocationCallbacks, FixedArray[VkMicromapEXT]) -> Int32] = "tycho_gpa_vkCreateMicromapEXT"
extern "c" fn load_vkCmdBuildMicromapsEXT(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32, VkMicromapBuildInfoEXT) -> Unit] = "tycho_gpa_vkCmdBuildMicromapsEXT"
extern "c" fn load_vkBuildMicromapsEXT(dev : VkDevice) -> FuncRef[(VkDevice, VkDeferredOperationKHR, UInt32, VkMicromapBuildInfoEXT) -> Int32] = "tycho_gpa_vkBuildMicromapsEXT"
extern "c" fn load_vkDestroyMicromapEXT(dev : VkDevice) -> FuncRef[(VkDevice, VkMicromapEXT, VkAllocationCallbacks) -> Unit] = "tycho_gpa_vkDestroyMicromapEXT"
extern "c" fn load_vkCmdCopyMicromapEXT(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkCopyMicromapInfoEXT) -> Unit] = "tycho_gpa_vkCmdCopyMicromapEXT"
extern "c" fn load_vkCopyMicromapEXT(dev : VkDevice) -> FuncRef[(VkDevice, VkDeferredOperationKHR, VkCopyMicromapInfoEXT) -> Int32] = "tycho_gpa_vkCopyMicromapEXT"
extern "c" fn load_vkCmdCopyMicromapToMemoryEXT(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkCopyMicromapToMemoryInfoEXT) -> Unit] = "tycho_gpa_vkCmdCopyMicromapToMemoryEXT"
extern "c" fn load_vkCopyMicromapToMemoryEXT(dev : VkDevice) -> FuncRef[(VkDevice, VkDeferredOperationKHR, VkCopyMicromapToMemoryInfoEXT) -> Int32] = "tycho_gpa_vkCopyMicromapToMemoryEXT"
extern "c" fn load_vkCmdCopyMemoryToMicromapEXT(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkCopyMemoryToMicromapInfoEXT) -> Unit] = "tycho_gpa_vkCmdCopyMemoryToMicromapEXT"
extern "c" fn load_vkCopyMemoryToMicromapEXT(dev : VkDevice) -> FuncRef[(VkDevice, VkDeferredOperationKHR, VkCopyMemoryToMicromapInfoEXT) -> Int32] = "tycho_gpa_vkCopyMemoryToMicromapEXT"
extern "c" fn load_vkCmdWriteMicromapsPropertiesEXT(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32, FixedArray[VkMicromapEXT], UInt32, VkQueryPool, UInt32) -> Unit] = "tycho_gpa_vkCmdWriteMicromapsPropertiesEXT"
extern "c" fn load_vkWriteMicromapsPropertiesEXT(dev : VkDevice) -> FuncRef[(VkDevice, UInt32, FixedArray[VkMicromapEXT], UInt32, UInt64, UInt64, UInt64) -> Int32] = "tycho_gpa_vkWriteMicromapsPropertiesEXT"
extern "c" fn load_vkGetDeviceMicromapCompatibilityEXT(dev : VkDevice) -> FuncRef[(VkDevice, VkMicromapVersionInfoEXT, FixedArray[UInt32]) -> Unit] = "tycho_gpa_vkGetDeviceMicromapCompatibilityEXT"
extern "c" fn load_vkGetMicromapBuildSizesEXT(dev : VkDevice) -> FuncRef[(VkDevice, UInt32, VkMicromapBuildInfoEXT, VkMicromapBuildSizesInfoEXT) -> Unit] = "tycho_gpa_vkGetMicromapBuildSizesEXT"
extern "c" fn load_vkGetShaderModuleIdentifierEXT(dev : VkDevice) -> FuncRef[(VkDevice, VkShaderModule, VkShaderModuleIdentifierEXT) -> Unit] = "tycho_gpa_vkGetShaderModuleIdentifierEXT"
extern "c" fn load_vkGetShaderModuleCreateInfoIdentifierEXT(dev : VkDevice) -> FuncRef[(VkDevice, VkShaderModuleCreateInfo, VkShaderModuleIdentifierEXT) -> Unit] = "tycho_gpa_vkGetShaderModuleCreateInfoIdentifierEXT"
extern "c" fn load_vkGetImageSubresourceLayout2(dev : VkDevice) -> FuncRef[(VkDevice, VkImage, VkImageSubresource2, VkSubresourceLayout2) -> Unit] = "tycho_gpa_vkGetImageSubresourceLayout2"
extern "c" fn load_vkGetImageSubresourceLayout2KHR(dev : VkDevice) -> FuncRef[(VkDevice, VkImage, VkImageSubresource2, VkSubresourceLayout2) -> Unit] = "tycho_gpa_vkGetImageSubresourceLayout2KHR"
extern "c" fn load_vkGetImageSubresourceLayout2EXT(dev : VkDevice) -> FuncRef[(VkDevice, VkImage, VkImageSubresource2, VkSubresourceLayout2) -> Unit] = "tycho_gpa_vkGetImageSubresourceLayout2EXT"
extern "c" fn load_vkGetPipelinePropertiesEXT(dev : VkDevice) -> FuncRef[(VkDevice, VkPipelineInfoKHR, VkBaseOutStructure) -> Int32] = "tycho_gpa_vkGetPipelinePropertiesEXT"
extern "c" fn load_vkExportMetalObjectsEXT(dev : VkDevice) -> FuncRef[(VkDevice, VkExportMetalObjectsInfoEXT) -> Unit] = "tycho_gpa_vkExportMetalObjectsEXT"
extern "c" fn load_vkCmdBindTileMemoryQCOM(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkTileMemoryBindInfoQCOM) -> Unit] = "tycho_gpa_vkCmdBindTileMemoryQCOM"
extern "c" fn load_vkGetFramebufferTilePropertiesQCOM(dev : VkDevice) -> FuncRef[(VkDevice, VkFramebuffer, FixedArray[UInt32], VkTilePropertiesQCOM) -> Int32] = "tycho_gpa_vkGetFramebufferTilePropertiesQCOM"
extern "c" fn load_vkGetDynamicRenderingTilePropertiesQCOM(dev : VkDevice) -> FuncRef[(VkDevice, VkRenderingInfo, VkTilePropertiesQCOM) -> Int32] = "tycho_gpa_vkGetDynamicRenderingTilePropertiesQCOM"
extern "c" fn load_vkCreateOpticalFlowSessionNV(dev : VkDevice) -> FuncRef[(VkDevice, VkOpticalFlowSessionCreateInfoNV, VkAllocationCallbacks, FixedArray[VkOpticalFlowSessionNV]) -> Int32] = "tycho_gpa_vkCreateOpticalFlowSessionNV"
extern "c" fn load_vkDestroyOpticalFlowSessionNV(dev : VkDevice) -> FuncRef[(VkDevice, VkOpticalFlowSessionNV, VkAllocationCallbacks) -> Unit] = "tycho_gpa_vkDestroyOpticalFlowSessionNV"
extern "c" fn load_vkBindOpticalFlowSessionImageNV(dev : VkDevice) -> FuncRef[(VkDevice, VkOpticalFlowSessionNV, UInt32, VkImageView, UInt32) -> Int32] = "tycho_gpa_vkBindOpticalFlowSessionImageNV"
extern "c" fn load_vkCmdOpticalFlowExecuteNV(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkOpticalFlowSessionNV, VkOpticalFlowExecuteInfoNV) -> Unit] = "tycho_gpa_vkCmdOpticalFlowExecuteNV"
extern "c" fn load_vkGetDeviceFaultInfoEXT(dev : VkDevice) -> FuncRef[(VkDevice, VkDeviceFaultCountsEXT, VkDeviceFaultInfoEXT) -> Int32] = "tycho_gpa_vkGetDeviceFaultInfoEXT"
extern "c" fn load_vkGetDeviceFaultReportsKHR(dev : VkDevice) -> FuncRef[(VkDevice, UInt64, FixedArray[UInt32], VkDeviceFaultInfoKHR) -> Int32] = "tycho_gpa_vkGetDeviceFaultReportsKHR"
extern "c" fn load_vkGetDeviceFaultDebugInfoKHR(dev : VkDevice) -> FuncRef[(VkDevice, VkDeviceFaultDebugInfoKHR) -> Int32] = "tycho_gpa_vkGetDeviceFaultDebugInfoKHR"
extern "c" fn load_vkCmdSetDepthBias2EXT(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkDepthBiasInfoEXT) -> Unit] = "tycho_gpa_vkCmdSetDepthBias2EXT"
extern "c" fn load_vkReleaseSwapchainImagesKHR(dev : VkDevice) -> FuncRef[(VkDevice, VkReleaseSwapchainImagesInfoKHR) -> Int32] = "tycho_gpa_vkReleaseSwapchainImagesKHR"
extern "c" fn load_vkReleaseSwapchainImagesEXT(dev : VkDevice) -> FuncRef[(VkDevice, VkReleaseSwapchainImagesInfoKHR) -> Int32] = "tycho_gpa_vkReleaseSwapchainImagesEXT"
extern "c" fn load_vkGetDeviceImageSubresourceLayout(dev : VkDevice) -> FuncRef[(VkDevice, VkDeviceImageSubresourceInfo, VkSubresourceLayout2) -> Unit] = "tycho_gpa_vkGetDeviceImageSubresourceLayout"
extern "c" fn load_vkGetDeviceImageSubresourceLayoutKHR(dev : VkDevice) -> FuncRef[(VkDevice, VkDeviceImageSubresourceInfo, VkSubresourceLayout2) -> Unit] = "tycho_gpa_vkGetDeviceImageSubresourceLayoutKHR"
extern "c" fn load_vkMapMemory2(dev : VkDevice) -> FuncRef[(VkDevice, VkMemoryMapInfo, FixedArray[UInt64]) -> Int32] = "tycho_gpa_vkMapMemory2"
extern "c" fn load_vkMapMemory2KHR(dev : VkDevice) -> FuncRef[(VkDevice, VkMemoryMapInfo, FixedArray[UInt64]) -> Int32] = "tycho_gpa_vkMapMemory2KHR"
extern "c" fn load_vkUnmapMemory2(dev : VkDevice) -> FuncRef[(VkDevice, VkMemoryUnmapInfo) -> Int32] = "tycho_gpa_vkUnmapMemory2"
extern "c" fn load_vkUnmapMemory2KHR(dev : VkDevice) -> FuncRef[(VkDevice, VkMemoryUnmapInfo) -> Int32] = "tycho_gpa_vkUnmapMemory2KHR"
extern "c" fn load_vkCreateShadersEXT(dev : VkDevice) -> FuncRef[(VkDevice, UInt32, VkShaderCreateInfoEXT, VkAllocationCallbacks, FixedArray[VkShaderEXT]) -> Int32] = "tycho_gpa_vkCreateShadersEXT"
extern "c" fn load_vkDestroyShaderEXT(dev : VkDevice) -> FuncRef[(VkDevice, VkShaderEXT, VkAllocationCallbacks) -> Unit] = "tycho_gpa_vkDestroyShaderEXT"
extern "c" fn load_vkGetShaderBinaryDataEXT(dev : VkDevice) -> FuncRef[(VkDevice, VkShaderEXT, FixedArray[UInt64], UInt64) -> Int32] = "tycho_gpa_vkGetShaderBinaryDataEXT"
extern "c" fn load_vkCmdBindShadersEXT(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32, FixedArray[UInt32], FixedArray[VkShaderEXT]) -> Unit] = "tycho_gpa_vkCmdBindShadersEXT"
extern "c" fn load_vkSetSwapchainPresentTimingQueueSizeEXT(dev : VkDevice) -> FuncRef[(VkDevice, VkSwapchainKHR, UInt32) -> Int32] = "tycho_gpa_vkSetSwapchainPresentTimingQueueSizeEXT"
extern "c" fn load_vkGetSwapchainTimingPropertiesEXT(dev : VkDevice) -> FuncRef[(VkDevice, VkSwapchainKHR, VkSwapchainTimingPropertiesEXT, FixedArray[UInt64]) -> Int32] = "tycho_gpa_vkGetSwapchainTimingPropertiesEXT"
extern "c" fn load_vkGetSwapchainTimeDomainPropertiesEXT(dev : VkDevice) -> FuncRef[(VkDevice, VkSwapchainKHR, VkSwapchainTimeDomainPropertiesEXT, FixedArray[UInt64]) -> Int32] = "tycho_gpa_vkGetSwapchainTimeDomainPropertiesEXT"
extern "c" fn load_vkGetPastPresentationTimingEXT(dev : VkDevice) -> FuncRef[(VkDevice, VkPastPresentationTimingInfoEXT, VkPastPresentationTimingPropertiesEXT) -> Int32] = "tycho_gpa_vkGetPastPresentationTimingEXT"
extern "c" fn load_vkGetScreenBufferPropertiesQNX(dev : VkDevice) -> FuncRef[(VkDevice, UInt64, VkScreenBufferPropertiesQNX) -> Int32] = "tycho_gpa_vkGetScreenBufferPropertiesQNX"
extern "c" fn load_vkGetExecutionGraphPipelineScratchSizeAMDX(dev : VkDevice) -> FuncRef[(VkDevice, VkPipeline, VkExecutionGraphPipelineScratchSizeAMDX) -> Int32] = "tycho_gpa_vkGetExecutionGraphPipelineScratchSizeAMDX"
extern "c" fn load_vkGetExecutionGraphPipelineNodeIndexAMDX(dev : VkDevice) -> FuncRef[(VkDevice, VkPipeline, VkPipelineShaderStageNodeCreateInfoAMDX, FixedArray[UInt32]) -> Int32] = "tycho_gpa_vkGetExecutionGraphPipelineNodeIndexAMDX"
extern "c" fn load_vkCreateExecutionGraphPipelinesAMDX(dev : VkDevice) -> FuncRef[(VkDevice, VkPipelineCache, UInt32, VkExecutionGraphPipelineCreateInfoAMDX, VkAllocationCallbacks, FixedArray[VkPipeline]) -> Int32] = "tycho_gpa_vkCreateExecutionGraphPipelinesAMDX"
extern "c" fn load_vkCmdInitializeGraphScratchMemoryAMDX(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkPipeline, UInt64, UInt64) -> Unit] = "tycho_gpa_vkCmdInitializeGraphScratchMemoryAMDX"
extern "c" fn load_vkCmdDispatchGraphAMDX(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt64, UInt64, VkDispatchGraphCountInfoAMDX) -> Unit] = "tycho_gpa_vkCmdDispatchGraphAMDX"
extern "c" fn load_vkCmdDispatchGraphIndirectAMDX(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt64, UInt64, VkDispatchGraphCountInfoAMDX) -> Unit] = "tycho_gpa_vkCmdDispatchGraphIndirectAMDX"
extern "c" fn load_vkCmdDispatchGraphIndirectCountAMDX(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt64, UInt64, UInt64) -> Unit] = "tycho_gpa_vkCmdDispatchGraphIndirectCountAMDX"
extern "c" fn load_vkCreateGpaSessionAMD(dev : VkDevice) -> FuncRef[(VkDevice, VkGpaSessionCreateInfoAMD, VkAllocationCallbacks, FixedArray[VkGpaSessionAMD]) -> Int32] = "tycho_gpa_vkCreateGpaSessionAMD"
extern "c" fn load_vkDestroyGpaSessionAMD(dev : VkDevice) -> FuncRef[(VkDevice, VkGpaSessionAMD, VkAllocationCallbacks) -> Unit] = "tycho_gpa_vkDestroyGpaSessionAMD"
extern "c" fn load_vkSetGpaDeviceClockModeAMD(dev : VkDevice) -> FuncRef[(VkDevice, VkGpaDeviceClockModeInfoAMD) -> Int32] = "tycho_gpa_vkSetGpaDeviceClockModeAMD"
extern "c" fn load_vkGetGpaDeviceClockInfoAMD(dev : VkDevice) -> FuncRef[(VkDevice, VkGpaDeviceGetClockInfoAMD) -> Int32] = "tycho_gpa_vkGetGpaDeviceClockInfoAMD"
extern "c" fn load_vkCmdBeginGpaSessionAMD(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkGpaSessionAMD) -> Int32] = "tycho_gpa_vkCmdBeginGpaSessionAMD"
extern "c" fn load_vkCmdEndGpaSessionAMD(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkGpaSessionAMD) -> Int32] = "tycho_gpa_vkCmdEndGpaSessionAMD"
extern "c" fn load_vkCmdBeginGpaSampleAMD(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkGpaSessionAMD, VkGpaSampleBeginInfoAMD, FixedArray[UInt32]) -> Int32] = "tycho_gpa_vkCmdBeginGpaSampleAMD"
extern "c" fn load_vkCmdEndGpaSampleAMD(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkGpaSessionAMD, UInt32) -> Unit] = "tycho_gpa_vkCmdEndGpaSampleAMD"
extern "c" fn load_vkGetGpaSessionStatusAMD(dev : VkDevice) -> FuncRef[(VkDevice, VkGpaSessionAMD) -> Int32] = "tycho_gpa_vkGetGpaSessionStatusAMD"
extern "c" fn load_vkGetGpaSessionResultsAMD(dev : VkDevice) -> FuncRef[(VkDevice, VkGpaSessionAMD, UInt32, FixedArray[UInt64], UInt64) -> Int32] = "tycho_gpa_vkGetGpaSessionResultsAMD"
extern "c" fn load_vkResetGpaSessionAMD(dev : VkDevice) -> FuncRef[(VkDevice, VkGpaSessionAMD) -> Int32] = "tycho_gpa_vkResetGpaSessionAMD"
extern "c" fn load_vkCmdCopyGpaSessionResultsAMD(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkGpaSessionAMD) -> Unit] = "tycho_gpa_vkCmdCopyGpaSessionResultsAMD"
extern "c" fn load_vkCmdBindDescriptorSets2(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkBindDescriptorSetsInfo) -> Unit] = "tycho_gpa_vkCmdBindDescriptorSets2"
extern "c" fn load_vkCmdBindDescriptorSets2KHR(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkBindDescriptorSetsInfo) -> Unit] = "tycho_gpa_vkCmdBindDescriptorSets2KHR"
extern "c" fn load_vkCmdPushConstants2(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkPushConstantsInfo) -> Unit] = "tycho_gpa_vkCmdPushConstants2"
extern "c" fn load_vkCmdPushConstants2KHR(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkPushConstantsInfo) -> Unit] = "tycho_gpa_vkCmdPushConstants2KHR"
extern "c" fn load_vkCmdPushDescriptorSet2(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkPushDescriptorSetInfo) -> Unit] = "tycho_gpa_vkCmdPushDescriptorSet2"
extern "c" fn load_vkCmdPushDescriptorSet2KHR(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkPushDescriptorSetInfo) -> Unit] = "tycho_gpa_vkCmdPushDescriptorSet2KHR"
extern "c" fn load_vkCmdPushDescriptorSetWithTemplate2(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkPushDescriptorSetWithTemplateInfo) -> Unit] = "tycho_gpa_vkCmdPushDescriptorSetWithTemplate2"
extern "c" fn load_vkCmdPushDescriptorSetWithTemplate2KHR(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkPushDescriptorSetWithTemplateInfo) -> Unit] = "tycho_gpa_vkCmdPushDescriptorSetWithTemplate2KHR"
extern "c" fn load_vkCmdSetDescriptorBufferOffsets2EXT(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkSetDescriptorBufferOffsetsInfoEXT) -> Unit] = "tycho_gpa_vkCmdSetDescriptorBufferOffsets2EXT"
extern "c" fn load_vkCmdBindDescriptorBufferEmbeddedSamplers2EXT(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkBindDescriptorBufferEmbeddedSamplersInfoEXT) -> Unit] = "tycho_gpa_vkCmdBindDescriptorBufferEmbeddedSamplers2EXT"
extern "c" fn load_vkSetLatencySleepModeNV(dev : VkDevice) -> FuncRef[(VkDevice, VkSwapchainKHR, VkLatencySleepModeInfoNV) -> Int32] = "tycho_gpa_vkSetLatencySleepModeNV"
extern "c" fn load_vkLatencySleepNV(dev : VkDevice) -> FuncRef[(VkDevice, VkSwapchainKHR, VkLatencySleepInfoNV) -> Int32] = "tycho_gpa_vkLatencySleepNV"
extern "c" fn load_vkSetLatencyMarkerNV(dev : VkDevice) -> FuncRef[(VkDevice, VkSwapchainKHR, VkSetLatencyMarkerInfoNV) -> Unit] = "tycho_gpa_vkSetLatencyMarkerNV"
extern "c" fn load_vkGetLatencyTimingsNV(dev : VkDevice) -> FuncRef[(VkDevice, VkSwapchainKHR, VkGetLatencyMarkerInfoNV) -> Unit] = "tycho_gpa_vkGetLatencyTimingsNV"
extern "c" fn load_vkQueueNotifyOutOfBandNV(dev : VkDevice) -> FuncRef[(VkQueue, VkOutOfBandQueueTypeInfoNV) -> Unit] = "tycho_gpa_vkQueueNotifyOutOfBandNV"
extern "c" fn load_vkSetLatencySleepModeLegacyNV(dev : VkDevice) -> FuncRef[(VkDevice, UInt32, UInt32, UInt32) -> Unit] = "tycho_gpa_vkSetLatencySleepModeLegacyNV"
extern "c" fn load_vkLatencySleepLegacyNV(dev : VkDevice) -> FuncRef[(VkDevice, VkSemaphore, UInt64) -> Unit] = "tycho_gpa_vkLatencySleepLegacyNV"
extern "c" fn load_vkSetLatencyMarkerLegacyNV(dev : VkDevice) -> FuncRef[(VkDevice, UInt64, UInt32) -> Unit] = "tycho_gpa_vkSetLatencyMarkerLegacyNV"
extern "c" fn load_vkGetLatencyTimingsLegacyNV(dev : VkDevice) -> FuncRef[(VkDevice, UInt64) -> Unit] = "tycho_gpa_vkGetLatencyTimingsLegacyNV"
extern "c" fn load_vkQueueNotifyOutOfBandLegacyNV(dev : VkDevice) -> FuncRef[(VkQueue, UInt32) -> Unit] = "tycho_gpa_vkQueueNotifyOutOfBandLegacyNV"
extern "c" fn load_vkGetSleepStatusLegacyNV(dev : VkDevice) -> FuncRef[(VkDevice, FixedArray[UInt32]) -> Unit] = "tycho_gpa_vkGetSleepStatusLegacyNV"
extern "c" fn load_vkShutdownLatencyDeviceLegacyNV(dev : VkDevice) -> FuncRef[(VkDevice) -> Unit] = "tycho_gpa_vkShutdownLatencyDeviceLegacyNV"
extern "c" fn load_vkCmdSetRenderingAttachmentLocations(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkRenderingAttachmentLocationInfo) -> Unit] = "tycho_gpa_vkCmdSetRenderingAttachmentLocations"
extern "c" fn load_vkCmdSetRenderingAttachmentLocationsKHR(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkRenderingAttachmentLocationInfo) -> Unit] = "tycho_gpa_vkCmdSetRenderingAttachmentLocationsKHR"
extern "c" fn load_vkCmdSetRenderingInputAttachmentIndices(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkRenderingInputAttachmentIndexInfo) -> Unit] = "tycho_gpa_vkCmdSetRenderingInputAttachmentIndices"
extern "c" fn load_vkCmdSetRenderingInputAttachmentIndicesKHR(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkRenderingInputAttachmentIndexInfo) -> Unit] = "tycho_gpa_vkCmdSetRenderingInputAttachmentIndicesKHR"
extern "c" fn load_vkCmdSetDepthClampRangeEXT(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32, VkDepthClampRangeEXT) -> Unit] = "tycho_gpa_vkCmdSetDepthClampRangeEXT"
extern "c" fn load_vkGetMemoryMetalHandleEXT(dev : VkDevice) -> FuncRef[(VkDevice, VkMemoryGetMetalHandleInfoEXT, FixedArray[UInt64]) -> Int32] = "tycho_gpa_vkGetMemoryMetalHandleEXT"
extern "c" fn load_vkGetMemoryMetalHandlePropertiesEXT(dev : VkDevice) -> FuncRef[(VkDevice, UInt32, UInt64, VkMemoryMetalHandlePropertiesEXT) -> Int32] = "tycho_gpa_vkGetMemoryMetalHandlePropertiesEXT"
extern "c" fn load_vkConvertCooperativeVectorMatrixNV(dev : VkDevice) -> FuncRef[(VkDevice, VkConvertCooperativeVectorMatrixInfoNV) -> Int32] = "tycho_gpa_vkConvertCooperativeVectorMatrixNV"
extern "c" fn load_vkCmdConvertCooperativeVectorMatrixNV(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32, VkConvertCooperativeVectorMatrixInfoNV) -> Unit] = "tycho_gpa_vkCmdConvertCooperativeVectorMatrixNV"
extern "c" fn load_vkCmdDispatchTileQCOM(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkDispatchTileInfoQCOM) -> Unit] = "tycho_gpa_vkCmdDispatchTileQCOM"
extern "c" fn load_vkCmdBeginPerTileExecutionQCOM(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkPerTileBeginInfoQCOM) -> Unit] = "tycho_gpa_vkCmdBeginPerTileExecutionQCOM"
extern "c" fn load_vkCmdEndPerTileExecutionQCOM(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkPerTileEndInfoQCOM) -> Unit] = "tycho_gpa_vkCmdEndPerTileExecutionQCOM"
extern "c" fn load_vkCreateExternalComputeQueueNV(dev : VkDevice) -> FuncRef[(VkDevice, VkExternalComputeQueueCreateInfoNV, VkAllocationCallbacks, FixedArray[VkExternalComputeQueueNV]) -> Int32] = "tycho_gpa_vkCreateExternalComputeQueueNV"
extern "c" fn load_vkDestroyExternalComputeQueueNV(dev : VkDevice) -> FuncRef[(VkDevice, VkExternalComputeQueueNV, VkAllocationCallbacks) -> Unit] = "tycho_gpa_vkDestroyExternalComputeQueueNV"
extern "c" fn load_vkCreateShaderInstrumentationARM(dev : VkDevice) -> FuncRef[(VkDevice, VkShaderInstrumentationCreateInfoARM, VkAllocationCallbacks, FixedArray[VkShaderInstrumentationARM]) -> Int32] = "tycho_gpa_vkCreateShaderInstrumentationARM"
extern "c" fn load_vkDestroyShaderInstrumentationARM(dev : VkDevice) -> FuncRef[(VkDevice, VkShaderInstrumentationARM, VkAllocationCallbacks) -> Unit] = "tycho_gpa_vkDestroyShaderInstrumentationARM"
extern "c" fn load_vkCmdBeginShaderInstrumentationARM(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkShaderInstrumentationARM) -> Unit] = "tycho_gpa_vkCmdBeginShaderInstrumentationARM"
extern "c" fn load_vkCmdEndShaderInstrumentationARM(dev : VkDevice) -> FuncRef[(VkCommandBuffer) -> Unit] = "tycho_gpa_vkCmdEndShaderInstrumentationARM"
extern "c" fn load_vkGetShaderInstrumentationValuesARM(dev : VkDevice) -> FuncRef[(VkDevice, VkShaderInstrumentationARM, FixedArray[UInt32], UInt64, UInt32) -> Int32] = "tycho_gpa_vkGetShaderInstrumentationValuesARM"
extern "c" fn load_vkClearShaderInstrumentationMetricsARM(dev : VkDevice) -> FuncRef[(VkDevice, VkShaderInstrumentationARM) -> Unit] = "tycho_gpa_vkClearShaderInstrumentationMetricsARM"
extern "c" fn load_vkCreateTensorARM(dev : VkDevice) -> FuncRef[(VkDevice, VkTensorCreateInfoARM, VkAllocationCallbacks, FixedArray[VkTensorARM]) -> Int32] = "tycho_gpa_vkCreateTensorARM"
extern "c" fn load_vkDestroyTensorARM(dev : VkDevice) -> FuncRef[(VkDevice, VkTensorARM, VkAllocationCallbacks) -> Unit] = "tycho_gpa_vkDestroyTensorARM"
extern "c" fn load_vkCreateTensorViewARM(dev : VkDevice) -> FuncRef[(VkDevice, VkTensorViewCreateInfoARM, VkAllocationCallbacks, FixedArray[VkTensorViewARM]) -> Int32] = "tycho_gpa_vkCreateTensorViewARM"
extern "c" fn load_vkDestroyTensorViewARM(dev : VkDevice) -> FuncRef[(VkDevice, VkTensorViewARM, VkAllocationCallbacks) -> Unit] = "tycho_gpa_vkDestroyTensorViewARM"
extern "c" fn load_vkGetTensorMemoryRequirementsARM(dev : VkDevice) -> FuncRef[(VkDevice, VkTensorMemoryRequirementsInfoARM, VkMemoryRequirements2) -> Unit] = "tycho_gpa_vkGetTensorMemoryRequirementsARM"
extern "c" fn load_vkBindTensorMemoryARM(dev : VkDevice) -> FuncRef[(VkDevice, UInt32, VkBindTensorMemoryInfoARM) -> Int32] = "tycho_gpa_vkBindTensorMemoryARM"
extern "c" fn load_vkGetDeviceTensorMemoryRequirementsARM(dev : VkDevice) -> FuncRef[(VkDevice, VkDeviceTensorMemoryRequirementsARM, VkMemoryRequirements2) -> Unit] = "tycho_gpa_vkGetDeviceTensorMemoryRequirementsARM"
extern "c" fn load_vkCmdCopyTensorARM(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkCopyTensorInfoARM) -> Unit] = "tycho_gpa_vkCmdCopyTensorARM"
extern "c" fn load_vkGetTensorOpaqueCaptureDescriptorDataARM(dev : VkDevice) -> FuncRef[(VkDevice, VkTensorCaptureDescriptorDataInfoARM, UInt64) -> Int32] = "tycho_gpa_vkGetTensorOpaqueCaptureDescriptorDataARM"
extern "c" fn load_vkGetTensorViewOpaqueCaptureDescriptorDataARM(dev : VkDevice) -> FuncRef[(VkDevice, VkTensorViewCaptureDescriptorDataInfoARM, UInt64) -> Int32] = "tycho_gpa_vkGetTensorViewOpaqueCaptureDescriptorDataARM"
extern "c" fn load_vkCreateDataGraphPipelinesARM(dev : VkDevice) -> FuncRef[(VkDevice, VkDeferredOperationKHR, VkPipelineCache, UInt32, VkDataGraphPipelineCreateInfoARM, VkAllocationCallbacks, FixedArray[VkPipeline]) -> Int32] = "tycho_gpa_vkCreateDataGraphPipelinesARM"
extern "c" fn load_vkCreateDataGraphPipelineSessionARM(dev : VkDevice) -> FuncRef[(VkDevice, VkDataGraphPipelineSessionCreateInfoARM, VkAllocationCallbacks, FixedArray[VkDataGraphPipelineSessionARM]) -> Int32] = "tycho_gpa_vkCreateDataGraphPipelineSessionARM"
extern "c" fn load_vkGetDataGraphPipelineSessionBindPointRequirementsARM(dev : VkDevice) -> FuncRef[(VkDevice, VkDataGraphPipelineSessionBindPointRequirementsInfoARM, FixedArray[UInt32], VkDataGraphPipelineSessionBindPointRequirementARM) -> Int32] = "tycho_gpa_vkGetDataGraphPipelineSessionBindPointRequirementsARM"
extern "c" fn load_vkGetDataGraphPipelineSessionMemoryRequirementsARM(dev : VkDevice) -> FuncRef[(VkDevice, VkDataGraphPipelineSessionMemoryRequirementsInfoARM, VkMemoryRequirements2) -> Unit] = "tycho_gpa_vkGetDataGraphPipelineSessionMemoryRequirementsARM"
extern "c" fn load_vkBindDataGraphPipelineSessionMemoryARM(dev : VkDevice) -> FuncRef[(VkDevice, UInt32, VkBindDataGraphPipelineSessionMemoryInfoARM) -> Int32] = "tycho_gpa_vkBindDataGraphPipelineSessionMemoryARM"
extern "c" fn load_vkDestroyDataGraphPipelineSessionARM(dev : VkDevice) -> FuncRef[(VkDevice, VkDataGraphPipelineSessionARM, VkAllocationCallbacks) -> Unit] = "tycho_gpa_vkDestroyDataGraphPipelineSessionARM"
extern "c" fn load_vkCmdDispatchDataGraphARM(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkDataGraphPipelineSessionARM, VkDataGraphPipelineDispatchInfoARM) -> Unit] = "tycho_gpa_vkCmdDispatchDataGraphARM"
extern "c" fn load_vkGetDataGraphPipelineAvailablePropertiesARM(dev : VkDevice) -> FuncRef[(VkDevice, VkDataGraphPipelineInfoARM, FixedArray[UInt32], FixedArray[UInt32]) -> Int32] = "tycho_gpa_vkGetDataGraphPipelineAvailablePropertiesARM"
extern "c" fn load_vkGetDataGraphPipelinePropertiesARM(dev : VkDevice) -> FuncRef[(VkDevice, VkDataGraphPipelineInfoARM, UInt32, VkDataGraphPipelinePropertyQueryResultARM) -> Int32] = "tycho_gpa_vkGetDataGraphPipelinePropertiesARM"
extern "c" fn load_vkGetNativeBufferPropertiesOHOS(dev : VkDevice) -> FuncRef[(VkDevice, UInt64, VkNativeBufferPropertiesOHOS) -> Int32] = "tycho_gpa_vkGetNativeBufferPropertiesOHOS"
extern "c" fn load_vkGetMemoryNativeBufferOHOS(dev : VkDevice) -> FuncRef[(VkDevice, VkMemoryGetNativeBufferInfoOHOS, FixedArray[UInt64]) -> Int32] = "tycho_gpa_vkGetMemoryNativeBufferOHOS"
extern "c" fn load_vkGetSwapchainGrallocUsageOHOS(dev : VkDevice) -> FuncRef[(VkDevice, UInt32, UInt32, FixedArray[UInt64]) -> Int32] = "tycho_gpa_vkGetSwapchainGrallocUsageOHOS"
extern "c" fn load_vkAcquireImageOHOS(dev : VkDevice) -> FuncRef[(VkDevice, VkImage, Int32, VkSemaphore, VkFence) -> Int32] = "tycho_gpa_vkAcquireImageOHOS"
extern "c" fn load_vkQueueSignalReleaseImageOHOS(dev : VkDevice) -> FuncRef[(VkQueue, UInt32, FixedArray[VkSemaphore], VkImage, FixedArray[Int32]) -> Int32] = "tycho_gpa_vkQueueSignalReleaseImageOHOS"
extern "c" fn load_vkQueueSetPerfHintQCOM(dev : VkDevice) -> FuncRef[(VkQueue, VkPerfHintInfoQCOM) -> Int32] = "tycho_gpa_vkQueueSetPerfHintQCOM"
extern "c" fn load_vkCmdSetComputeOccupancyPriorityNV(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkComputeOccupancyPriorityParametersNV) -> Unit] = "tycho_gpa_vkCmdSetComputeOccupancyPriorityNV"
extern "c" fn load_vkWriteSamplerDescriptorsEXT(dev : VkDevice) -> FuncRef[(VkDevice, UInt32, VkSamplerCreateInfo, VkHostAddressRangeEXT) -> Int32] = "tycho_gpa_vkWriteSamplerDescriptorsEXT"
extern "c" fn load_vkWriteResourceDescriptorsEXT(dev : VkDevice) -> FuncRef[(VkDevice, UInt32, VkResourceDescriptorInfoEXT, VkHostAddressRangeEXT) -> Int32] = "tycho_gpa_vkWriteResourceDescriptorsEXT"
extern "c" fn load_vkCmdBindSamplerHeapEXT(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkBindHeapInfoEXT) -> Unit] = "tycho_gpa_vkCmdBindSamplerHeapEXT"
extern "c" fn load_vkCmdBindResourceHeapEXT(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkBindHeapInfoEXT) -> Unit] = "tycho_gpa_vkCmdBindResourceHeapEXT"
extern "c" fn load_vkCmdPushDataEXT(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkPushDataInfoEXT) -> Unit] = "tycho_gpa_vkCmdPushDataEXT"
extern "c" fn load_vkRegisterCustomBorderColorEXT(dev : VkDevice) -> FuncRef[(VkDevice, VkSamplerCustomBorderColorCreateInfoEXT, UInt32, FixedArray[UInt32]) -> Int32] = "tycho_gpa_vkRegisterCustomBorderColorEXT"
extern "c" fn load_vkUnregisterCustomBorderColorEXT(dev : VkDevice) -> FuncRef[(VkDevice, UInt32) -> Unit] = "tycho_gpa_vkUnregisterCustomBorderColorEXT"
extern "c" fn load_vkGetImageOpaqueCaptureDataEXT(dev : VkDevice) -> FuncRef[(VkDevice, UInt32, FixedArray[VkImage], VkHostAddressRangeEXT) -> Int32] = "tycho_gpa_vkGetImageOpaqueCaptureDataEXT"
extern "c" fn load_vkGetTensorOpaqueCaptureDataARM(dev : VkDevice) -> FuncRef[(VkDevice, UInt32, FixedArray[VkTensorARM], VkHostAddressRangeEXT) -> Int32] = "tycho_gpa_vkGetTensorOpaqueCaptureDataARM"
extern "c" fn load_vkCmdCopyMemoryKHR(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkCopyDeviceMemoryInfoKHR) -> Unit] = "tycho_gpa_vkCmdCopyMemoryKHR"
extern "c" fn load_vkCmdCopyMemoryToImageKHR(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkCopyDeviceMemoryImageInfoKHR) -> Unit] = "tycho_gpa_vkCmdCopyMemoryToImageKHR"
extern "c" fn load_vkCmdCopyImageToMemoryKHR(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkCopyDeviceMemoryImageInfoKHR) -> Unit] = "tycho_gpa_vkCmdCopyImageToMemoryKHR"
extern "c" fn load_vkCmdUpdateMemoryKHR(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkDeviceAddressRangeKHR, UInt32, UInt64, UInt64) -> Unit] = "tycho_gpa_vkCmdUpdateMemoryKHR"
extern "c" fn load_vkCmdFillMemoryKHR(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkDeviceAddressRangeKHR, UInt32, UInt32) -> Unit] = "tycho_gpa_vkCmdFillMemoryKHR"
extern "c" fn load_vkCmdCopyQueryPoolResultsToMemoryKHR(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkQueryPool, UInt32, UInt32, VkStridedDeviceAddressRangeKHR, UInt32, UInt32) -> Unit] = "tycho_gpa_vkCmdCopyQueryPoolResultsToMemoryKHR"
extern "c" fn load_vkCmdBeginConditionalRendering2EXT(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkConditionalRenderingBeginInfo2EXT) -> Unit] = "tycho_gpa_vkCmdBeginConditionalRendering2EXT"
extern "c" fn load_vkCmdBindTransformFeedbackBuffers2EXT(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32, UInt32, VkBindTransformFeedbackBuffer2InfoEXT) -> Unit] = "tycho_gpa_vkCmdBindTransformFeedbackBuffers2EXT"
extern "c" fn load_vkCmdBeginTransformFeedback2EXT(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32, UInt32, VkBindTransformFeedbackBuffer2InfoEXT) -> Unit] = "tycho_gpa_vkCmdBeginTransformFeedback2EXT"
extern "c" fn load_vkCmdEndTransformFeedback2EXT(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32, UInt32, VkBindTransformFeedbackBuffer2InfoEXT) -> Unit] = "tycho_gpa_vkCmdEndTransformFeedback2EXT"
extern "c" fn load_vkCmdDrawIndirectByteCount2EXT(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32, UInt32, VkBindTransformFeedbackBuffer2InfoEXT, UInt32, UInt32) -> Unit] = "tycho_gpa_vkCmdDrawIndirectByteCount2EXT"
extern "c" fn load_vkCmdWriteMarkerToMemoryAMD(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkMemoryMarkerInfoAMD) -> Unit] = "tycho_gpa_vkCmdWriteMarkerToMemoryAMD"
extern "c" fn load_vkCmdBindIndexBuffer3KHR(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkBindIndexBuffer3InfoKHR) -> Unit] = "tycho_gpa_vkCmdBindIndexBuffer3KHR"
extern "c" fn load_vkCmdBindVertexBuffers3KHR(dev : VkDevice) -> FuncRef[(VkCommandBuffer, UInt32, UInt32, VkBindVertexBuffer3InfoKHR) -> Unit] = "tycho_gpa_vkCmdBindVertexBuffers3KHR"
extern "c" fn load_vkCmdDrawIndirect2KHR(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkDrawIndirect2InfoKHR) -> Unit] = "tycho_gpa_vkCmdDrawIndirect2KHR"
extern "c" fn load_vkCmdDrawIndexedIndirect2KHR(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkDrawIndirect2InfoKHR) -> Unit] = "tycho_gpa_vkCmdDrawIndexedIndirect2KHR"
extern "c" fn load_vkCmdDrawIndirectCount2KHR(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkDrawIndirectCount2InfoKHR) -> Unit] = "tycho_gpa_vkCmdDrawIndirectCount2KHR"
extern "c" fn load_vkCmdDrawIndexedIndirectCount2KHR(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkDrawIndirectCount2InfoKHR) -> Unit] = "tycho_gpa_vkCmdDrawIndexedIndirectCount2KHR"
extern "c" fn load_vkCmdDrawMeshTasksIndirect2EXT(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkDrawIndirect2InfoKHR) -> Unit] = "tycho_gpa_vkCmdDrawMeshTasksIndirect2EXT"
extern "c" fn load_vkCmdDrawMeshTasksIndirectCount2EXT(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkDrawIndirectCount2InfoKHR) -> Unit] = "tycho_gpa_vkCmdDrawMeshTasksIndirectCount2EXT"
extern "c" fn load_vkCmdDispatchIndirect2KHR(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkDispatchIndirect2InfoKHR) -> Unit] = "tycho_gpa_vkCmdDispatchIndirect2KHR"
extern "c" fn load_vkCreateAccelerationStructure2KHR(dev : VkDevice) -> FuncRef[(VkDevice, VkAccelerationStructureCreateInfo2KHR, VkAllocationCallbacks, FixedArray[VkAccelerationStructureKHR]) -> Int32] = "tycho_gpa_vkCreateAccelerationStructure2KHR"
extern "c" fn load_vkCmdSetDispatchParametersARM(dev : VkDevice) -> FuncRef[(VkCommandBuffer, VkDispatchParametersARM) -> Unit] = "tycho_gpa_vkCmdSetDispatchParametersARM"

pub fn DeviceFn::load(dev : VkDevice) -> DeviceFn {
  {
    vkDestroyDevice: load_vkDestroyDevice(dev),
    vkGetDeviceQueue: load_vkGetDeviceQueue(dev),
    vkQueueSubmit: load_vkQueueSubmit(dev),
    vkQueueWaitIdle: load_vkQueueWaitIdle(dev),
    vkDeviceWaitIdle: load_vkDeviceWaitIdle(dev),
    vkAllocateMemory: load_vkAllocateMemory(dev),
    vkFreeMemory: load_vkFreeMemory(dev),
    vkMapMemory: load_vkMapMemory(dev),
    vkUnmapMemory: load_vkUnmapMemory(dev),
    vkFlushMappedMemoryRanges: load_vkFlushMappedMemoryRanges(dev),
    vkInvalidateMappedMemoryRanges: load_vkInvalidateMappedMemoryRanges(dev),
    vkGetDeviceMemoryCommitment: load_vkGetDeviceMemoryCommitment(dev),
    vkGetBufferMemoryRequirements: load_vkGetBufferMemoryRequirements(dev),
    vkBindBufferMemory: load_vkBindBufferMemory(dev),
    vkGetImageMemoryRequirements: load_vkGetImageMemoryRequirements(dev),
    vkBindImageMemory: load_vkBindImageMemory(dev),
    vkGetImageSparseMemoryRequirements: load_vkGetImageSparseMemoryRequirements(dev),
    vkQueueBindSparse: load_vkQueueBindSparse(dev),
    vkCreateFence: load_vkCreateFence(dev),
    vkDestroyFence: load_vkDestroyFence(dev),
    vkResetFences: load_vkResetFences(dev),
    vkGetFenceStatus: load_vkGetFenceStatus(dev),
    vkWaitForFences: load_vkWaitForFences(dev),
    vkCreateSemaphore: load_vkCreateSemaphore(dev),
    vkDestroySemaphore: load_vkDestroySemaphore(dev),
    vkCreateEvent: load_vkCreateEvent(dev),
    vkDestroyEvent: load_vkDestroyEvent(dev),
    vkGetEventStatus: load_vkGetEventStatus(dev),
    vkSetEvent: load_vkSetEvent(dev),
    vkResetEvent: load_vkResetEvent(dev),
    vkCreateQueryPool: load_vkCreateQueryPool(dev),
    vkDestroyQueryPool: load_vkDestroyQueryPool(dev),
    vkGetQueryPoolResults: load_vkGetQueryPoolResults(dev),
    vkResetQueryPool: load_vkResetQueryPool(dev),
    vkResetQueryPoolEXT: load_vkResetQueryPoolEXT(dev),
    vkCreateBuffer: load_vkCreateBuffer(dev),
    vkDestroyBuffer: load_vkDestroyBuffer(dev),
    vkCreateBufferView: load_vkCreateBufferView(dev),
    vkDestroyBufferView: load_vkDestroyBufferView(dev),
    vkCreateImage: load_vkCreateImage(dev),
    vkDestroyImage: load_vkDestroyImage(dev),
    vkGetImageSubresourceLayout: load_vkGetImageSubresourceLayout(dev),
    vkCreateImageView: load_vkCreateImageView(dev),
    vkDestroyImageView: load_vkDestroyImageView(dev),
    vkCreateShaderModule: load_vkCreateShaderModule(dev),
    vkDestroyShaderModule: load_vkDestroyShaderModule(dev),
    vkCreatePipelineCache: load_vkCreatePipelineCache(dev),
    vkDestroyPipelineCache: load_vkDestroyPipelineCache(dev),
    vkGetPipelineCacheData: load_vkGetPipelineCacheData(dev),
    vkMergePipelineCaches: load_vkMergePipelineCaches(dev),
    vkCreatePipelineBinariesKHR: load_vkCreatePipelineBinariesKHR(dev),
    vkDestroyPipelineBinaryKHR: load_vkDestroyPipelineBinaryKHR(dev),
    vkGetPipelineKeyKHR: load_vkGetPipelineKeyKHR(dev),
    vkGetPipelineBinaryDataKHR: load_vkGetPipelineBinaryDataKHR(dev),
    vkReleaseCapturedPipelineDataKHR: load_vkReleaseCapturedPipelineDataKHR(dev),
    vkCreateGraphicsPipelines: load_vkCreateGraphicsPipelines(dev),
    vkCreateComputePipelines: load_vkCreateComputePipelines(dev),
    vkGetDeviceSubpassShadingMaxWorkgroupSizeHUAWEI: load_vkGetDeviceSubpassShadingMaxWorkgroupSizeHUAWEI(dev),
    vkDestroyPipeline: load_vkDestroyPipeline(dev),
    vkCreatePipelineLayout: load_vkCreatePipelineLayout(dev),
    vkDestroyPipelineLayout: load_vkDestroyPipelineLayout(dev),
    vkCreateSampler: load_vkCreateSampler(dev),
    vkDestroySampler: load_vkDestroySampler(dev),
    vkCreateDescriptorSetLayout: load_vkCreateDescriptorSetLayout(dev),
    vkDestroyDescriptorSetLayout: load_vkDestroyDescriptorSetLayout(dev),
    vkCreateDescriptorPool: load_vkCreateDescriptorPool(dev),
    vkDestroyDescriptorPool: load_vkDestroyDescriptorPool(dev),
    vkResetDescriptorPool: load_vkResetDescriptorPool(dev),
    vkAllocateDescriptorSets: load_vkAllocateDescriptorSets(dev),
    vkFreeDescriptorSets: load_vkFreeDescriptorSets(dev),
    vkUpdateDescriptorSets: load_vkUpdateDescriptorSets(dev),
    vkCreateFramebuffer: load_vkCreateFramebuffer(dev),
    vkDestroyFramebuffer: load_vkDestroyFramebuffer(dev),
    vkCreateRenderPass: load_vkCreateRenderPass(dev),
    vkDestroyRenderPass: load_vkDestroyRenderPass(dev),
    vkGetRenderAreaGranularity: load_vkGetRenderAreaGranularity(dev),
    vkGetRenderingAreaGranularity: load_vkGetRenderingAreaGranularity(dev),
    vkGetRenderingAreaGranularityKHR: load_vkGetRenderingAreaGranularityKHR(dev),
    vkCreateCommandPool: load_vkCreateCommandPool(dev),
    vkDestroyCommandPool: load_vkDestroyCommandPool(dev),
    vkResetCommandPool: load_vkResetCommandPool(dev),
    vkAllocateCommandBuffers: load_vkAllocateCommandBuffers(dev),
    vkFreeCommandBuffers: load_vkFreeCommandBuffers(dev),
    vkBeginCommandBuffer: load_vkBeginCommandBuffer(dev),
    vkEndCommandBuffer: load_vkEndCommandBuffer(dev),
    vkResetCommandBuffer: load_vkResetCommandBuffer(dev),
    vkCmdBindPipeline: load_vkCmdBindPipeline(dev),
    vkCmdSetPrimitiveRestartIndexEXT: load_vkCmdSetPrimitiveRestartIndexEXT(dev),
    vkCmdSetAttachmentFeedbackLoopEnableEXT: load_vkCmdSetAttachmentFeedbackLoopEnableEXT(dev),
    vkCmdSetViewport: load_vkCmdSetViewport(dev),
    vkCmdSetScissor: load_vkCmdSetScissor(dev),
    vkCmdSetLineWidth: load_vkCmdSetLineWidth(dev),
    vkCmdSetDepthBias: load_vkCmdSetDepthBias(dev),
    vkCmdSetBlendConstants: load_vkCmdSetBlendConstants(dev),
    vkCmdSetDepthBounds: load_vkCmdSetDepthBounds(dev),
    vkCmdSetStencilCompareMask: load_vkCmdSetStencilCompareMask(dev),
    vkCmdSetStencilWriteMask: load_vkCmdSetStencilWriteMask(dev),
    vkCmdSetStencilReference: load_vkCmdSetStencilReference(dev),
    vkCmdBindDescriptorSets: load_vkCmdBindDescriptorSets(dev),
    vkCmdBindIndexBuffer: load_vkCmdBindIndexBuffer(dev),
    vkCmdBindVertexBuffers: load_vkCmdBindVertexBuffers(dev),
    vkCmdDraw: load_vkCmdDraw(dev),
    vkCmdDrawIndexed: load_vkCmdDrawIndexed(dev),
    vkCmdDrawMultiEXT: load_vkCmdDrawMultiEXT(dev),
    vkCmdDrawMultiIndexedEXT: load_vkCmdDrawMultiIndexedEXT(dev),
    vkCmdDrawIndirect: load_vkCmdDrawIndirect(dev),
    vkCmdDrawIndexedIndirect: load_vkCmdDrawIndexedIndirect(dev),
    vkCmdDispatch: load_vkCmdDispatch(dev),
    vkCmdDispatchIndirect: load_vkCmdDispatchIndirect(dev),
    vkCmdSubpassShadingHUAWEI: load_vkCmdSubpassShadingHUAWEI(dev),
    vkCmdDrawClusterHUAWEI: load_vkCmdDrawClusterHUAWEI(dev),
    vkCmdDrawClusterIndirectHUAWEI: load_vkCmdDrawClusterIndirectHUAWEI(dev),
    vkCmdUpdatePipelineIndirectBufferNV: load_vkCmdUpdatePipelineIndirectBufferNV(dev),
    vkCmdCopyBuffer: load_vkCmdCopyBuffer(dev),
    vkCmdCopyImage: load_vkCmdCopyImage(dev),
    vkCmdBlitImage: load_vkCmdBlitImage(dev),
    vkCmdCopyBufferToImage: load_vkCmdCopyBufferToImage(dev),
    vkCmdCopyImageToBuffer: load_vkCmdCopyImageToBuffer(dev),
    vkCmdCopyMemoryIndirectNV: load_vkCmdCopyMemoryIndirectNV(dev),
    vkCmdCopyMemoryIndirectKHR: load_vkCmdCopyMemoryIndirectKHR(dev),
    vkCmdCopyMemoryToImageIndirectNV: load_vkCmdCopyMemoryToImageIndirectNV(dev),
    vkCmdCopyMemoryToImageIndirectKHR: load_vkCmdCopyMemoryToImageIndirectKHR(dev),
    vkCmdUpdateBuffer: load_vkCmdUpdateBuffer(dev),
    vkCmdFillBuffer: load_vkCmdFillBuffer(dev),
    vkCmdClearColorImage: load_vkCmdClearColorImage(dev),
    vkCmdClearDepthStencilImage: load_vkCmdClearDepthStencilImage(dev),
    vkCmdClearAttachments: load_vkCmdClearAttachments(dev),
    vkCmdResolveImage: load_vkCmdResolveImage(dev),
    vkCmdSetEvent: load_vkCmdSetEvent(dev),
    vkCmdResetEvent: load_vkCmdResetEvent(dev),
    vkCmdWaitEvents: load_vkCmdWaitEvents(dev),
    vkCmdPipelineBarrier: load_vkCmdPipelineBarrier(dev),
    vkCmdBeginQuery: load_vkCmdBeginQuery(dev),
    vkCmdEndQuery: load_vkCmdEndQuery(dev),
    vkCmdBeginConditionalRenderingEXT: load_vkCmdBeginConditionalRenderingEXT(dev),
    vkCmdEndConditionalRenderingEXT: load_vkCmdEndConditionalRenderingEXT(dev),
    vkCmdBeginCustomResolveEXT: load_vkCmdBeginCustomResolveEXT(dev),
    vkCmdResetQueryPool: load_vkCmdResetQueryPool(dev),
    vkCmdWriteTimestamp: load_vkCmdWriteTimestamp(dev),
    vkCmdCopyQueryPoolResults: load_vkCmdCopyQueryPoolResults(dev),
    vkCmdPushConstants: load_vkCmdPushConstants(dev),
    vkCmdBeginRenderPass: load_vkCmdBeginRenderPass(dev),
    vkCmdNextSubpass: load_vkCmdNextSubpass(dev),
    vkCmdEndRenderPass: load_vkCmdEndRenderPass(dev),
    vkCmdExecuteCommands: load_vkCmdExecuteCommands(dev),
    vkCreateSharedSwapchainsKHR: load_vkCreateSharedSwapchainsKHR(dev),
    vkCreateSwapchainKHR: load_vkCreateSwapchainKHR(dev),
    vkDestroySwapchainKHR: load_vkDestroySwapchainKHR(dev),
    vkGetSwapchainImagesKHR: load_vkGetSwapchainImagesKHR(dev),
    vkAcquireNextImageKHR: load_vkAcquireNextImageKHR(dev),
    vkQueuePresentKHR: load_vkQueuePresentKHR(dev),
    vkDebugMarkerSetObjectNameEXT: load_vkDebugMarkerSetObjectNameEXT(dev),
    vkDebugMarkerSetObjectTagEXT: load_vkDebugMarkerSetObjectTagEXT(dev),
    vkCmdDebugMarkerBeginEXT: load_vkCmdDebugMarkerBeginEXT(dev),
    vkCmdDebugMarkerEndEXT: load_vkCmdDebugMarkerEndEXT(dev),
    vkCmdDebugMarkerInsertEXT: load_vkCmdDebugMarkerInsertEXT(dev),
    vkGetMemoryWin32HandleNV: load_vkGetMemoryWin32HandleNV(dev),
    vkCmdExecuteGeneratedCommandsNV: load_vkCmdExecuteGeneratedCommandsNV(dev),
    vkCmdPreprocessGeneratedCommandsNV: load_vkCmdPreprocessGeneratedCommandsNV(dev),
    vkCmdBindPipelineShaderGroupNV: load_vkCmdBindPipelineShaderGroupNV(dev),
    vkGetGeneratedCommandsMemoryRequirementsNV: load_vkGetGeneratedCommandsMemoryRequirementsNV(dev),
    vkCreateIndirectCommandsLayoutNV: load_vkCreateIndirectCommandsLayoutNV(dev),
    vkDestroyIndirectCommandsLayoutNV: load_vkDestroyIndirectCommandsLayoutNV(dev),
    vkCmdExecuteGeneratedCommandsEXT: load_vkCmdExecuteGeneratedCommandsEXT(dev),
    vkCmdPreprocessGeneratedCommandsEXT: load_vkCmdPreprocessGeneratedCommandsEXT(dev),
    vkGetGeneratedCommandsMemoryRequirementsEXT: load_vkGetGeneratedCommandsMemoryRequirementsEXT(dev),
    vkCreateIndirectCommandsLayoutEXT: load_vkCreateIndirectCommandsLayoutEXT(dev),
    vkDestroyIndirectCommandsLayoutEXT: load_vkDestroyIndirectCommandsLayoutEXT(dev),
    vkCreateIndirectExecutionSetEXT: load_vkCreateIndirectExecutionSetEXT(dev),
    vkDestroyIndirectExecutionSetEXT: load_vkDestroyIndirectExecutionSetEXT(dev),
    vkUpdateIndirectExecutionSetPipelineEXT: load_vkUpdateIndirectExecutionSetPipelineEXT(dev),
    vkUpdateIndirectExecutionSetShaderEXT: load_vkUpdateIndirectExecutionSetShaderEXT(dev),
    vkCmdPushDescriptorSet: load_vkCmdPushDescriptorSet(dev),
    vkCmdPushDescriptorSetKHR: load_vkCmdPushDescriptorSetKHR(dev),
    vkTrimCommandPool: load_vkTrimCommandPool(dev),
    vkTrimCommandPoolKHR: load_vkTrimCommandPoolKHR(dev),
    vkGetMemoryWin32HandleKHR: load_vkGetMemoryWin32HandleKHR(dev),
    vkGetMemoryWin32HandlePropertiesKHR: load_vkGetMemoryWin32HandlePropertiesKHR(dev),
    vkGetMemoryFdKHR: load_vkGetMemoryFdKHR(dev),
    vkGetMemoryFdPropertiesKHR: load_vkGetMemoryFdPropertiesKHR(dev),
    vkGetMemoryZirconHandleFUCHSIA: load_vkGetMemoryZirconHandleFUCHSIA(dev),
    vkGetMemoryZirconHandlePropertiesFUCHSIA: load_vkGetMemoryZirconHandlePropertiesFUCHSIA(dev),
    vkGetMemoryRemoteAddressNV: load_vkGetMemoryRemoteAddressNV(dev),
    vkGetMemorySciBufNV: load_vkGetMemorySciBufNV(dev),
    vkGetSemaphoreWin32HandleKHR: load_vkGetSemaphoreWin32HandleKHR(dev),
    vkImportSemaphoreWin32HandleKHR: load_vkImportSemaphoreWin32HandleKHR(dev),
    vkGetSemaphoreFdKHR: load_vkGetSemaphoreFdKHR(dev),
    vkImportSemaphoreFdKHR: load_vkImportSemaphoreFdKHR(dev),
    vkGetSemaphoreZirconHandleFUCHSIA: load_vkGetSemaphoreZirconHandleFUCHSIA(dev),
    vkImportSemaphoreZirconHandleFUCHSIA: load_vkImportSemaphoreZirconHandleFUCHSIA(dev),
    vkGetFenceWin32HandleKHR: load_vkGetFenceWin32HandleKHR(dev),
    vkImportFenceWin32HandleKHR: load_vkImportFenceWin32HandleKHR(dev),
    vkGetFenceFdKHR: load_vkGetFenceFdKHR(dev),
    vkImportFenceFdKHR: load_vkImportFenceFdKHR(dev),
    vkGetFenceSciSyncFenceNV: load_vkGetFenceSciSyncFenceNV(dev),
    vkGetFenceSciSyncObjNV: load_vkGetFenceSciSyncObjNV(dev),
    vkImportFenceSciSyncFenceNV: load_vkImportFenceSciSyncFenceNV(dev),
    vkImportFenceSciSyncObjNV: load_vkImportFenceSciSyncObjNV(dev),
    vkGetSemaphoreSciSyncObjNV: load_vkGetSemaphoreSciSyncObjNV(dev),
    vkImportSemaphoreSciSyncObjNV: load_vkImportSemaphoreSciSyncObjNV(dev),
    vkCreateSemaphoreSciSyncPoolNV: load_vkCreateSemaphoreSciSyncPoolNV(dev),
    vkDestroySemaphoreSciSyncPoolNV: load_vkDestroySemaphoreSciSyncPoolNV(dev),
    vkDisplayPowerControlEXT: load_vkDisplayPowerControlEXT(dev),
    vkRegisterDeviceEventEXT: load_vkRegisterDeviceEventEXT(dev),
    vkRegisterDisplayEventEXT: load_vkRegisterDisplayEventEXT(dev),
    vkGetSwapchainCounterEXT: load_vkGetSwapchainCounterEXT(dev),
    vkGetDeviceGroupPeerMemoryFeatures: load_vkGetDeviceGroupPeerMemoryFeatures(dev),
    vkGetDeviceGroupPeerMemoryFeaturesKHR: load_vkGetDeviceGroupPeerMemoryFeaturesKHR(dev),
    vkBindBufferMemory2: load_vkBindBufferMemory2(dev),
    vkBindBufferMemory2KHR: load_vkBindBufferMemory2KHR(dev),
    vkBindImageMemory2: load_vkBindImageMemory2(dev),
    vkBindImageMemory2KHR: load_vkBindImageMemory2KHR(dev),
    vkCmdSetDeviceMask: load_vkCmdSetDeviceMask(dev),
    vkCmdSetDeviceMaskKHR: load_vkCmdSetDeviceMaskKHR(dev),
    vkGetDeviceGroupPresentCapabilitiesKHR: load_vkGetDeviceGroupPresentCapabilitiesKHR(dev),
    vkGetDeviceGroupSurfacePresentModesKHR: load_vkGetDeviceGroupSurfacePresentModesKHR(dev),
    vkAcquireNextImage2KHR: load_vkAcquireNextImage2KHR(dev),
    vkCmdDispatchBase: load_vkCmdDispatchBase(dev),
    vkCmdDispatchBaseKHR: load_vkCmdDispatchBaseKHR(dev),
    vkCreateDescriptorUpdateTemplate: load_vkCreateDescriptorUpdateTemplate(dev),
    vkCreateDescriptorUpdateTemplateKHR: load_vkCreateDescriptorUpdateTemplateKHR(dev),
    vkDestroyDescriptorUpdateTemplate: load_vkDestroyDescriptorUpdateTemplate(dev),
    vkDestroyDescriptorUpdateTemplateKHR: load_vkDestroyDescriptorUpdateTemplateKHR(dev),
    vkUpdateDescriptorSetWithTemplate: load_vkUpdateDescriptorSetWithTemplate(dev),
    vkUpdateDescriptorSetWithTemplateKHR: load_vkUpdateDescriptorSetWithTemplateKHR(dev),
    vkCmdPushDescriptorSetWithTemplate: load_vkCmdPushDescriptorSetWithTemplate(dev),
    vkCmdPushDescriptorSetWithTemplateKHR: load_vkCmdPushDescriptorSetWithTemplateKHR(dev),
    vkSetHdrMetadataEXT: load_vkSetHdrMetadataEXT(dev),
    vkGetSwapchainStatusKHR: load_vkGetSwapchainStatusKHR(dev),
    vkGetRefreshCycleDurationGOOGLE: load_vkGetRefreshCycleDurationGOOGLE(dev),
    vkGetPastPresentationTimingGOOGLE: load_vkGetPastPresentationTimingGOOGLE(dev),
    vkCmdSetViewportWScalingNV: load_vkCmdSetViewportWScalingNV(dev),
    vkCmdSetDiscardRectangleEXT: load_vkCmdSetDiscardRectangleEXT(dev),
    vkCmdSetDiscardRectangleEnableEXT: load_vkCmdSetDiscardRectangleEnableEXT(dev),
    vkCmdSetDiscardRectangleModeEXT: load_vkCmdSetDiscardRectangleModeEXT(dev),
    vkCmdSetSampleLocationsEXT: load_vkCmdSetSampleLocationsEXT(dev),
    vkGetBufferMemoryRequirements2: load_vkGetBufferMemoryRequirements2(dev),
    vkGetBufferMemoryRequirements2KHR: load_vkGetBufferMemoryRequirements2KHR(dev),
    vkGetImageMemoryRequirements2: load_vkGetImageMemoryRequirements2(dev),
    vkGetImageMemoryRequirements2KHR: load_vkGetImageMemoryRequirements2KHR(dev),
    vkGetImageSparseMemoryRequirements2: load_vkGetImageSparseMemoryRequirements2(dev),
    vkGetImageSparseMemoryRequirements2KHR: load_vkGetImageSparseMemoryRequirements2KHR(dev),
    vkGetDeviceBufferMemoryRequirements: load_vkGetDeviceBufferMemoryRequirements(dev),
    vkGetDeviceBufferMemoryRequirementsKHR: load_vkGetDeviceBufferMemoryRequirementsKHR(dev),
    vkGetDeviceImageMemoryRequirements: load_vkGetDeviceImageMemoryRequirements(dev),
    vkGetDeviceImageMemoryRequirementsKHR: load_vkGetDeviceImageMemoryRequirementsKHR(dev),
    vkGetDeviceImageSparseMemoryRequirements: load_vkGetDeviceImageSparseMemoryRequirements(dev),
    vkGetDeviceImageSparseMemoryRequirementsKHR: load_vkGetDeviceImageSparseMemoryRequirementsKHR(dev),
    vkCreateSamplerYcbcrConversion: load_vkCreateSamplerYcbcrConversion(dev),
    vkCreateSamplerYcbcrConversionKHR: load_vkCreateSamplerYcbcrConversionKHR(dev),
    vkDestroySamplerYcbcrConversion: load_vkDestroySamplerYcbcrConversion(dev),
    vkDestroySamplerYcbcrConversionKHR: load_vkDestroySamplerYcbcrConversionKHR(dev),
    vkGetDeviceQueue2: load_vkGetDeviceQueue2(dev),
    vkCreateValidationCacheEXT: load_vkCreateValidationCacheEXT(dev),
    vkDestroyValidationCacheEXT: load_vkDestroyValidationCacheEXT(dev),
    vkGetValidationCacheDataEXT: load_vkGetValidationCacheDataEXT(dev),
    vkMergeValidationCachesEXT: load_vkMergeValidationCachesEXT(dev),
    vkGetDescriptorSetLayoutSupport: load_vkGetDescriptorSetLayoutSupport(dev),
    vkGetDescriptorSetLayoutSupportKHR: load_vkGetDescriptorSetLayoutSupportKHR(dev),
    vkGetSwapchainGrallocUsageANDROID: load_vkGetSwapchainGrallocUsageANDROID(dev),
    vkGetSwapchainGrallocUsage2ANDROID: load_vkGetSwapchainGrallocUsage2ANDROID(dev),
    vkAcquireImageANDROID: load_vkAcquireImageANDROID(dev),
    vkQueueSignalReleaseImageANDROID: load_vkQueueSignalReleaseImageANDROID(dev),
    vkGetShaderInfoAMD: load_vkGetShaderInfoAMD(dev),
    vkSetLocalDimmingAMD: load_vkSetLocalDimmingAMD(dev),
    vkGetCalibratedTimestampsKHR: load_vkGetCalibratedTimestampsKHR(dev),
    vkGetCalibratedTimestampsEXT: load_vkGetCalibratedTimestampsEXT(dev),
    vkSetDebugUtilsObjectNameEXT: load_vkSetDebugUtilsObjectNameEXT(dev),
    vkSetDebugUtilsObjectTagEXT: load_vkSetDebugUtilsObjectTagEXT(dev),
    vkQueueBeginDebugUtilsLabelEXT: load_vkQueueBeginDebugUtilsLabelEXT(dev),
    vkQueueEndDebugUtilsLabelEXT: load_vkQueueEndDebugUtilsLabelEXT(dev),
    vkQueueInsertDebugUtilsLabelEXT: load_vkQueueInsertDebugUtilsLabelEXT(dev),
    vkCmdBeginDebugUtilsLabelEXT: load_vkCmdBeginDebugUtilsLabelEXT(dev),
    vkCmdEndDebugUtilsLabelEXT: load_vkCmdEndDebugUtilsLabelEXT(dev),
    vkCmdInsertDebugUtilsLabelEXT: load_vkCmdInsertDebugUtilsLabelEXT(dev),
    vkGetMemoryHostPointerPropertiesEXT: load_vkGetMemoryHostPointerPropertiesEXT(dev),
    vkCmdWriteBufferMarkerAMD: load_vkCmdWriteBufferMarkerAMD(dev),
    vkCreateRenderPass2: load_vkCreateRenderPass2(dev),
    vkCreateRenderPass2KHR: load_vkCreateRenderPass2KHR(dev),
    vkCmdBeginRenderPass2: load_vkCmdBeginRenderPass2(dev),
    vkCmdBeginRenderPass2KHR: load_vkCmdBeginRenderPass2KHR(dev),
    vkCmdNextSubpass2: load_vkCmdNextSubpass2(dev),
    vkCmdNextSubpass2KHR: load_vkCmdNextSubpass2KHR(dev),
    vkCmdEndRenderPass2: load_vkCmdEndRenderPass2(dev),
    vkCmdEndRenderPass2KHR: load_vkCmdEndRenderPass2KHR(dev),
    vkGetSemaphoreCounterValue: load_vkGetSemaphoreCounterValue(dev),
    vkGetSemaphoreCounterValueKHR: load_vkGetSemaphoreCounterValueKHR(dev),
    vkWaitSemaphores: load_vkWaitSemaphores(dev),
    vkWaitSemaphoresKHR: load_vkWaitSemaphoresKHR(dev),
    vkSignalSemaphore: load_vkSignalSemaphore(dev),
    vkSignalSemaphoreKHR: load_vkSignalSemaphoreKHR(dev),
    vkGetAndroidHardwareBufferPropertiesANDROID: load_vkGetAndroidHardwareBufferPropertiesANDROID(dev),
    vkGetMemoryAndroidHardwareBufferANDROID: load_vkGetMemoryAndroidHardwareBufferANDROID(dev),
    vkCmdDrawIndirectCount: load_vkCmdDrawIndirectCount(dev),
    vkCmdDrawIndirectCountKHR: load_vkCmdDrawIndirectCountKHR(dev),
    vkCmdDrawIndirectCountAMD: load_vkCmdDrawIndirectCountAMD(dev),
    vkCmdDrawIndexedIndirectCount: load_vkCmdDrawIndexedIndirectCount(dev),
    vkCmdDrawIndexedIndirectCountKHR: load_vkCmdDrawIndexedIndirectCountKHR(dev),
    vkCmdDrawIndexedIndirectCountAMD: load_vkCmdDrawIndexedIndirectCountAMD(dev),
    vkCmdSetCheckpointNV: load_vkCmdSetCheckpointNV(dev),
    vkGetQueueCheckpointDataNV: load_vkGetQueueCheckpointDataNV(dev),
    vkCmdBindTransformFeedbackBuffersEXT: load_vkCmdBindTransformFeedbackBuffersEXT(dev),
    vkCmdBeginTransformFeedbackEXT: load_vkCmdBeginTransformFeedbackEXT(dev),
    vkCmdEndTransformFeedbackEXT: load_vkCmdEndTransformFeedbackEXT(dev),
    vkCmdBeginQueryIndexedEXT: load_vkCmdBeginQueryIndexedEXT(dev),
    vkCmdEndQueryIndexedEXT: load_vkCmdEndQueryIndexedEXT(dev),
    vkCmdDrawIndirectByteCountEXT: load_vkCmdDrawIndirectByteCountEXT(dev),
    vkCmdSetExclusiveScissorNV: load_vkCmdSetExclusiveScissorNV(dev),
    vkCmdSetExclusiveScissorEnableNV: load_vkCmdSetExclusiveScissorEnableNV(dev),
    vkCmdBindShadingRateImageNV: load_vkCmdBindShadingRateImageNV(dev),
    vkCmdSetViewportShadingRatePaletteNV: load_vkCmdSetViewportShadingRatePaletteNV(dev),
    vkCmdSetCoarseSampleOrderNV: load_vkCmdSetCoarseSampleOrderNV(dev),
    vkCmdDrawMeshTasksNV: load_vkCmdDrawMeshTasksNV(dev),
    vkCmdDrawMeshTasksIndirectNV: load_vkCmdDrawMeshTasksIndirectNV(dev),
    vkCmdDrawMeshTasksIndirectCountNV: load_vkCmdDrawMeshTasksIndirectCountNV(dev),
    vkCmdDrawMeshTasksEXT: load_vkCmdDrawMeshTasksEXT(dev),
    vkCmdDrawMeshTasksIndirectEXT: load_vkCmdDrawMeshTasksIndirectEXT(dev),
    vkCmdDrawMeshTasksIndirectCountEXT: load_vkCmdDrawMeshTasksIndirectCountEXT(dev),
    vkCompileDeferredNV: load_vkCompileDeferredNV(dev),
    vkCreateAccelerationStructureNV: load_vkCreateAccelerationStructureNV(dev),
    vkCmdBindInvocationMaskHUAWEI: load_vkCmdBindInvocationMaskHUAWEI(dev),
    vkDestroyAccelerationStructureKHR: load_vkDestroyAccelerationStructureKHR(dev),
    vkDestroyAccelerationStructureNV: load_vkDestroyAccelerationStructureNV(dev),
    vkGetAccelerationStructureMemoryRequirementsNV: load_vkGetAccelerationStructureMemoryRequirementsNV(dev),
    vkBindAccelerationStructureMemoryNV: load_vkBindAccelerationStructureMemoryNV(dev),
    vkCmdCopyAccelerationStructureNV: load_vkCmdCopyAccelerationStructureNV(dev),
    vkCmdCopyAccelerationStructureKHR: load_vkCmdCopyAccelerationStructureKHR(dev),
    vkCopyAccelerationStructureKHR: load_vkCopyAccelerationStructureKHR(dev),
    vkCmdCopyAccelerationStructureToMemoryKHR: load_vkCmdCopyAccelerationStructureToMemoryKHR(dev),
    vkCopyAccelerationStructureToMemoryKHR: load_vkCopyAccelerationStructureToMemoryKHR(dev),
    vkCmdCopyMemoryToAccelerationStructureKHR: load_vkCmdCopyMemoryToAccelerationStructureKHR(dev),
    vkCopyMemoryToAccelerationStructureKHR: load_vkCopyMemoryToAccelerationStructureKHR(dev),
    vkCmdWriteAccelerationStructuresPropertiesKHR: load_vkCmdWriteAccelerationStructuresPropertiesKHR(dev),
    vkCmdWriteAccelerationStructuresPropertiesNV: load_vkCmdWriteAccelerationStructuresPropertiesNV(dev),
    vkCmdBuildAccelerationStructureNV: load_vkCmdBuildAccelerationStructureNV(dev),
    vkWriteAccelerationStructuresPropertiesKHR: load_vkWriteAccelerationStructuresPropertiesKHR(dev),
    vkCmdTraceRaysKHR: load_vkCmdTraceRaysKHR(dev),
    vkCmdTraceRaysNV: load_vkCmdTraceRaysNV(dev),
    vkGetRayTracingShaderGroupHandlesKHR: load_vkGetRayTracingShaderGroupHandlesKHR(dev),
    vkGetRayTracingShaderGroupHandlesNV: load_vkGetRayTracingShaderGroupHandlesNV(dev),
    vkGetRayTracingCaptureReplayShaderGroupHandlesKHR: load_vkGetRayTracingCaptureReplayShaderGroupHandlesKHR(dev),
    vkGetAccelerationStructureHandleNV: load_vkGetAccelerationStructureHandleNV(dev),
    vkCreateRayTracingPipelinesNV: load_vkCreateRayTracingPipelinesNV(dev),
    vkCreateRayTracingPipelinesKHR: load_vkCreateRayTracingPipelinesKHR(dev),
    vkCmdTraceRaysIndirectKHR: load_vkCmdTraceRaysIndirectKHR(dev),
    vkCmdTraceRaysIndirect2KHR: load_vkCmdTraceRaysIndirect2KHR(dev),
    vkGetClusterAccelerationStructureBuildSizesNV: load_vkGetClusterAccelerationStructureBuildSizesNV(dev),
    vkCmdBuildClusterAccelerationStructureIndirectNV: load_vkCmdBuildClusterAccelerationStructureIndirectNV(dev),
    vkGetDeviceAccelerationStructureCompatibilityKHR: load_vkGetDeviceAccelerationStructureCompatibilityKHR(dev),
    vkGetRayTracingShaderGroupStackSizeKHR: load_vkGetRayTracingShaderGroupStackSizeKHR(dev),
    vkCmdSetRayTracingPipelineStackSizeKHR: load_vkCmdSetRayTracingPipelineStackSizeKHR(dev),
    vkGetImageViewHandleNVX: load_vkGetImageViewHandleNVX(dev),
    vkGetImageViewHandle64NVX: load_vkGetImageViewHandle64NVX(dev),
    vkGetImageViewAddressNVX: load_vkGetImageViewAddressNVX(dev),
    vkGetDeviceCombinedImageSamplerIndexNVX: load_vkGetDeviceCombinedImageSamplerIndexNVX(dev),
    vkGetDeviceGroupSurfacePresentModes2EXT: load_vkGetDeviceGroupSurfacePresentModes2EXT(dev),
    vkAcquireFullScreenExclusiveModeEXT: load_vkAcquireFullScreenExclusiveModeEXT(dev),
    vkReleaseFullScreenExclusiveModeEXT: load_vkReleaseFullScreenExclusiveModeEXT(dev),
    vkAcquireProfilingLockKHR: load_vkAcquireProfilingLockKHR(dev),
    vkReleaseProfilingLockKHR: load_vkReleaseProfilingLockKHR(dev),
    vkGetImageDrmFormatModifierPropertiesEXT: load_vkGetImageDrmFormatModifierPropertiesEXT(dev),
    vkGetBufferOpaqueCaptureAddress: load_vkGetBufferOpaqueCaptureAddress(dev),
    vkGetBufferOpaqueCaptureAddressKHR: load_vkGetBufferOpaqueCaptureAddressKHR(dev),
    vkGetBufferDeviceAddress: load_vkGetBufferDeviceAddress(dev),
    vkGetBufferDeviceAddressKHR: load_vkGetBufferDeviceAddressKHR(dev),
    vkGetBufferDeviceAddressEXT: load_vkGetBufferDeviceAddressEXT(dev),
    vkInitializePerformanceApiINTEL: load_vkInitializePerformanceApiINTEL(dev),
    vkUninitializePerformanceApiINTEL: load_vkUninitializePerformanceApiINTEL(dev),
    vkCmdSetPerformanceMarkerINTEL: load_vkCmdSetPerformanceMarkerINTEL(dev),
    vkCmdSetPerformanceStreamMarkerINTEL: load_vkCmdSetPerformanceStreamMarkerINTEL(dev),
    vkCmdSetPerformanceOverrideINTEL: load_vkCmdSetPerformanceOverrideINTEL(dev),
    vkAcquirePerformanceConfigurationINTEL: load_vkAcquirePerformanceConfigurationINTEL(dev),
    vkReleasePerformanceConfigurationINTEL: load_vkReleasePerformanceConfigurationINTEL(dev),
    vkQueueSetPerformanceConfigurationINTEL: load_vkQueueSetPerformanceConfigurationINTEL(dev),
    vkGetPerformanceParameterINTEL: load_vkGetPerformanceParameterINTEL(dev),
    vkGetDeviceMemoryOpaqueCaptureAddress: load_vkGetDeviceMemoryOpaqueCaptureAddress(dev),
    vkGetDeviceMemoryOpaqueCaptureAddressKHR: load_vkGetDeviceMemoryOpaqueCaptureAddressKHR(dev),
    vkGetPipelineExecutablePropertiesKHR: load_vkGetPipelineExecutablePropertiesKHR(dev),
    vkGetPipelineExecutableStatisticsKHR: load_vkGetPipelineExecutableStatisticsKHR(dev),
    vkGetPipelineExecutableInternalRepresentationsKHR: load_vkGetPipelineExecutableInternalRepresentationsKHR(dev),
    vkCmdSetLineStipple: load_vkCmdSetLineStipple(dev),
    vkCmdSetLineStippleKHR: load_vkCmdSetLineStippleKHR(dev),
    vkCmdSetLineStippleEXT: load_vkCmdSetLineStippleEXT(dev),
    vkGetFaultData: load_vkGetFaultData(dev),
    vkCreateAccelerationStructureKHR: load_vkCreateAccelerationStructureKHR(dev),
    vkCmdBuildAccelerationStructuresKHR: load_vkCmdBuildAccelerationStructuresKHR(dev),
    vkCmdBuildAccelerationStructuresIndirectKHR: load_vkCmdBuildAccelerationStructuresIndirectKHR(dev),
    vkBuildAccelerationStructuresKHR: load_vkBuildAccelerationStructuresKHR(dev),
    vkGetAccelerationStructureDeviceAddressKHR: load_vkGetAccelerationStructureDeviceAddressKHR(dev),
    vkCreateDeferredOperationKHR: load_vkCreateDeferredOperationKHR(dev),
    vkDestroyDeferredOperationKHR: load_vkDestroyDeferredOperationKHR(dev),
    vkGetDeferredOperationMaxConcurrencyKHR: load_vkGetDeferredOperationMaxConcurrencyKHR(dev),
    vkGetDeferredOperationResultKHR: load_vkGetDeferredOperationResultKHR(dev),
    vkDeferredOperationJoinKHR: load_vkDeferredOperationJoinKHR(dev),
    vkGetPipelineIndirectMemoryRequirementsNV: load_vkGetPipelineIndirectMemoryRequirementsNV(dev),
    vkGetPipelineIndirectDeviceAddressNV: load_vkGetPipelineIndirectDeviceAddressNV(dev),
    vkAntiLagUpdateAMD: load_vkAntiLagUpdateAMD(dev),
    vkCmdSetCullMode: load_vkCmdSetCullMode(dev),
    vkCmdSetCullModeEXT: load_vkCmdSetCullModeEXT(dev),
    vkCmdSetFrontFace: load_vkCmdSetFrontFace(dev),
    vkCmdSetFrontFaceEXT: load_vkCmdSetFrontFaceEXT(dev),
    vkCmdSetPrimitiveTopology: load_vkCmdSetPrimitiveTopology(dev),
    vkCmdSetPrimitiveTopologyEXT: load_vkCmdSetPrimitiveTopologyEXT(dev),
    vkCmdSetViewportWithCount: load_vkCmdSetViewportWithCount(dev),
    vkCmdSetViewportWithCountEXT: load_vkCmdSetViewportWithCountEXT(dev),
    vkCmdSetScissorWithCount: load_vkCmdSetScissorWithCount(dev),
    vkCmdSetScissorWithCountEXT: load_vkCmdSetScissorWithCountEXT(dev),
    vkCmdBindIndexBuffer2: load_vkCmdBindIndexBuffer2(dev),
    vkCmdBindIndexBuffer2KHR: load_vkCmdBindIndexBuffer2KHR(dev),
    vkCmdBindVertexBuffers2: load_vkCmdBindVertexBuffers2(dev),
    vkCmdBindVertexBuffers2EXT: load_vkCmdBindVertexBuffers2EXT(dev),
    vkCmdSetDepthTestEnable: load_vkCmdSetDepthTestEnable(dev),
    vkCmdSetDepthTestEnableEXT: load_vkCmdSetDepthTestEnableEXT(dev),
    vkCmdSetDepthWriteEnable: load_vkCmdSetDepthWriteEnable(dev),
    vkCmdSetDepthWriteEnableEXT: load_vkCmdSetDepthWriteEnableEXT(dev),
    vkCmdSetDepthCompareOp: load_vkCmdSetDepthCompareOp(dev),
    vkCmdSetDepthCompareOpEXT: load_vkCmdSetDepthCompareOpEXT(dev),
    vkCmdSetDepthBoundsTestEnable: load_vkCmdSetDepthBoundsTestEnable(dev),
    vkCmdSetDepthBoundsTestEnableEXT: load_vkCmdSetDepthBoundsTestEnableEXT(dev),
    vkCmdSetStencilTestEnable: load_vkCmdSetStencilTestEnable(dev),
    vkCmdSetStencilTestEnableEXT: load_vkCmdSetStencilTestEnableEXT(dev),
    vkCmdSetStencilOp: load_vkCmdSetStencilOp(dev),
    vkCmdSetStencilOpEXT: load_vkCmdSetStencilOpEXT(dev),
    vkCmdSetPatchControlPointsEXT: load_vkCmdSetPatchControlPointsEXT(dev),
    vkCmdSetRasterizerDiscardEnable: load_vkCmdSetRasterizerDiscardEnable(dev),
    vkCmdSetRasterizerDiscardEnableEXT: load_vkCmdSetRasterizerDiscardEnableEXT(dev),
    vkCmdSetDepthBiasEnable: load_vkCmdSetDepthBiasEnable(dev),
    vkCmdSetDepthBiasEnableEXT: load_vkCmdSetDepthBiasEnableEXT(dev),
    vkCmdSetLogicOpEXT: load_vkCmdSetLogicOpEXT(dev),
    vkCmdSetPrimitiveRestartEnable: load_vkCmdSetPrimitiveRestartEnable(dev),
    vkCmdSetPrimitiveRestartEnableEXT: load_vkCmdSetPrimitiveRestartEnableEXT(dev),
    vkCmdSetTessellationDomainOriginEXT: load_vkCmdSetTessellationDomainOriginEXT(dev),
    vkCmdSetDepthClampEnableEXT: load_vkCmdSetDepthClampEnableEXT(dev),
    vkCmdSetPolygonModeEXT: load_vkCmdSetPolygonModeEXT(dev),
    vkCmdSetRasterizationSamplesEXT: load_vkCmdSetRasterizationSamplesEXT(dev),
    vkCmdSetSampleMaskEXT: load_vkCmdSetSampleMaskEXT(dev),
    vkCmdSetAlphaToCoverageEnableEXT: load_vkCmdSetAlphaToCoverageEnableEXT(dev),
    vkCmdSetAlphaToOneEnableEXT: load_vkCmdSetAlphaToOneEnableEXT(dev),
    vkCmdSetLogicOpEnableEXT: load_vkCmdSetLogicOpEnableEXT(dev),
    vkCmdSetColorBlendEnableEXT: load_vkCmdSetColorBlendEnableEXT(dev),
    vkCmdSetColorBlendEquationEXT: load_vkCmdSetColorBlendEquationEXT(dev),
    vkCmdSetColorWriteMaskEXT: load_vkCmdSetColorWriteMaskEXT(dev),
    vkCmdSetRasterizationStreamEXT: load_vkCmdSetRasterizationStreamEXT(dev),
    vkCmdSetConservativeRasterizationModeEXT: load_vkCmdSetConservativeRasterizationModeEXT(dev),
    vkCmdSetExtraPrimitiveOverestimationSizeEXT: load_vkCmdSetExtraPrimitiveOverestimationSizeEXT(dev),
    vkCmdSetDepthClipEnableEXT: load_vkCmdSetDepthClipEnableEXT(dev),
    vkCmdSetSampleLocationsEnableEXT: load_vkCmdSetSampleLocationsEnableEXT(dev),
    vkCmdSetColorBlendAdvancedEXT: load_vkCmdSetColorBlendAdvancedEXT(dev),
    vkCmdSetProvokingVertexModeEXT: load_vkCmdSetProvokingVertexModeEXT(dev),
    vkCmdSetLineRasterizationModeEXT: load_vkCmdSetLineRasterizationModeEXT(dev),
    vkCmdSetLineStippleEnableEXT: load_vkCmdSetLineStippleEnableEXT(dev),
    vkCmdSetDepthClipNegativeOneToOneEXT: load_vkCmdSetDepthClipNegativeOneToOneEXT(dev),
    vkCmdSetViewportWScalingEnableNV: load_vkCmdSetViewportWScalingEnableNV(dev),
    vkCmdSetViewportSwizzleNV: load_vkCmdSetViewportSwizzleNV(dev),
    vkCmdSetCoverageToColorEnableNV: load_vkCmdSetCoverageToColorEnableNV(dev),
    vkCmdSetCoverageToColorLocationNV: load_vkCmdSetCoverageToColorLocationNV(dev),
    vkCmdSetCoverageModulationModeNV: load_vkCmdSetCoverageModulationModeNV(dev),
    vkCmdSetCoverageModulationTableEnableNV: load_vkCmdSetCoverageModulationTableEnableNV(dev),
    vkCmdSetCoverageModulationTableNV: load_vkCmdSetCoverageModulationTableNV(dev),
    vkCmdSetShadingRateImageEnableNV: load_vkCmdSetShadingRateImageEnableNV(dev),
    vkCmdSetCoverageReductionModeNV: load_vkCmdSetCoverageReductionModeNV(dev),
    vkCmdSetRepresentativeFragmentTestEnableNV: load_vkCmdSetRepresentativeFragmentTestEnableNV(dev),
    vkCreatePrivateDataSlot: load_vkCreatePrivateDataSlot(dev),
    vkCreatePrivateDataSlotEXT: load_vkCreatePrivateDataSlotEXT(dev),
    vkDestroyPrivateDataSlot: load_vkDestroyPrivateDataSlot(dev),
    vkDestroyPrivateDataSlotEXT: load_vkDestroyPrivateDataSlotEXT(dev),
    vkSetPrivateData: load_vkSetPrivateData(dev),
    vkSetPrivateDataEXT: load_vkSetPrivateDataEXT(dev),
    vkGetPrivateData: load_vkGetPrivateData(dev),
    vkGetPrivateDataEXT: load_vkGetPrivateDataEXT(dev),
    vkCmdCopyBuffer2: load_vkCmdCopyBuffer2(dev),
    vkCmdCopyBuffer2KHR: load_vkCmdCopyBuffer2KHR(dev),
    vkCmdCopyImage2: load_vkCmdCopyImage2(dev),
    vkCmdCopyImage2KHR: load_vkCmdCopyImage2KHR(dev),
    vkCmdBlitImage2: load_vkCmdBlitImage2(dev),
    vkCmdBlitImage2KHR: load_vkCmdBlitImage2KHR(dev),
    vkCmdCopyBufferToImage2: load_vkCmdCopyBufferToImage2(dev),
    vkCmdCopyBufferToImage2KHR: load_vkCmdCopyBufferToImage2KHR(dev),
    vkCmdCopyImageToBuffer2: load_vkCmdCopyImageToBuffer2(dev),
    vkCmdCopyImageToBuffer2KHR: load_vkCmdCopyImageToBuffer2KHR(dev),
    vkCmdResolveImage2: load_vkCmdResolveImage2(dev),
    vkCmdResolveImage2KHR: load_vkCmdResolveImage2KHR(dev),
    vkCmdRefreshObjectsKHR: load_vkCmdRefreshObjectsKHR(dev),
    vkCmdSetFragmentShadingRateKHR: load_vkCmdSetFragmentShadingRateKHR(dev),
    vkCmdSetFragmentShadingRateEnumNV: load_vkCmdSetFragmentShadingRateEnumNV(dev),
    vkGetAccelerationStructureBuildSizesKHR: load_vkGetAccelerationStructureBuildSizesKHR(dev),
    vkCmdSetVertexInputEXT: load_vkCmdSetVertexInputEXT(dev),
    vkCmdSetColorWriteEnableEXT: load_vkCmdSetColorWriteEnableEXT(dev),
    vkCmdSetEvent2: load_vkCmdSetEvent2(dev),
    vkCmdSetEvent2KHR: load_vkCmdSetEvent2KHR(dev),
    vkCmdResetEvent2: load_vkCmdResetEvent2(dev),
    vkCmdResetEvent2KHR: load_vkCmdResetEvent2KHR(dev),
    vkCmdWaitEvents2: load_vkCmdWaitEvents2(dev),
    vkCmdWaitEvents2KHR: load_vkCmdWaitEvents2KHR(dev),
    vkCmdPipelineBarrier2: load_vkCmdPipelineBarrier2(dev),
    vkCmdPipelineBarrier2KHR: load_vkCmdPipelineBarrier2KHR(dev),
    vkQueueSubmit2: load_vkQueueSubmit2(dev),
    vkQueueSubmit2KHR: load_vkQueueSubmit2KHR(dev),
    vkCmdWriteTimestamp2: load_vkCmdWriteTimestamp2(dev),
    vkCmdWriteTimestamp2KHR: load_vkCmdWriteTimestamp2KHR(dev),
    vkCmdWriteBufferMarker2AMD: load_vkCmdWriteBufferMarker2AMD(dev),
    vkGetQueueCheckpointData2NV: load_vkGetQueueCheckpointData2NV(dev),
    vkCopyMemoryToImage: load_vkCopyMemoryToImage(dev),
    vkCopyMemoryToImageEXT: load_vkCopyMemoryToImageEXT(dev),
    vkCopyImageToMemory: load_vkCopyImageToMemory(dev),
    vkCopyImageToMemoryEXT: load_vkCopyImageToMemoryEXT(dev),
    vkCopyImageToImage: load_vkCopyImageToImage(dev),
    vkCopyImageToImageEXT: load_vkCopyImageToImageEXT(dev),
    vkTransitionImageLayout: load_vkTransitionImageLayout(dev),
    vkTransitionImageLayoutEXT: load_vkTransitionImageLayoutEXT(dev),
    vkGetCommandPoolMemoryConsumption: load_vkGetCommandPoolMemoryConsumption(dev),
    vkCreateVideoSessionKHR: load_vkCreateVideoSessionKHR(dev),
    vkDestroyVideoSessionKHR: load_vkDestroyVideoSessionKHR(dev),
    vkCreateVideoSessionParametersKHR: load_vkCreateVideoSessionParametersKHR(dev),
    vkUpdateVideoSessionParametersKHR: load_vkUpdateVideoSessionParametersKHR(dev),
    vkGetEncodedVideoSessionParametersKHR: load_vkGetEncodedVideoSessionParametersKHR(dev),
    vkDestroyVideoSessionParametersKHR: load_vkDestroyVideoSessionParametersKHR(dev),
    vkGetVideoSessionMemoryRequirementsKHR: load_vkGetVideoSessionMemoryRequirementsKHR(dev),
    vkBindVideoSessionMemoryKHR: load_vkBindVideoSessionMemoryKHR(dev),
    vkCmdDecodeVideoKHR: load_vkCmdDecodeVideoKHR(dev),
    vkCmdBeginVideoCodingKHR: load_vkCmdBeginVideoCodingKHR(dev),
    vkCmdControlVideoCodingKHR: load_vkCmdControlVideoCodingKHR(dev),
    vkCmdEndVideoCodingKHR: load_vkCmdEndVideoCodingKHR(dev),
    vkCmdEncodeVideoKHR: load_vkCmdEncodeVideoKHR(dev),
    vkCmdDecompressMemoryNV: load_vkCmdDecompressMemoryNV(dev),
    vkCmdDecompressMemoryIndirectCountNV: load_vkCmdDecompressMemoryIndirectCountNV(dev),
    vkGetPartitionedAccelerationStructuresBuildSizesNV: load_vkGetPartitionedAccelerationStructuresBuildSizesNV(dev),
    vkCmdBuildPartitionedAccelerationStructuresNV: load_vkCmdBuildPartitionedAccelerationStructuresNV(dev),
    vkCmdDecompressMemoryEXT: load_vkCmdDecompressMemoryEXT(dev),
    vkCmdDecompressMemoryIndirectCountEXT: load_vkCmdDecompressMemoryIndirectCountEXT(dev),
    vkCreateCuModuleNVX: load_vkCreateCuModuleNVX(dev),
    vkCreateCuFunctionNVX: load_vkCreateCuFunctionNVX(dev),
    vkDestroyCuModuleNVX: load_vkDestroyCuModuleNVX(dev),
    vkDestroyCuFunctionNVX: load_vkDestroyCuFunctionNVX(dev),
    vkCmdCuLaunchKernelNVX: load_vkCmdCuLaunchKernelNVX(dev),
    vkGetDescriptorSetLayoutSizeEXT: load_vkGetDescriptorSetLayoutSizeEXT(dev),
    vkGetDescriptorSetLayoutBindingOffsetEXT: load_vkGetDescriptorSetLayoutBindingOffsetEXT(dev),
    vkGetDescriptorEXT: load_vkGetDescriptorEXT(dev),
    vkCmdBindDescriptorBuffersEXT: load_vkCmdBindDescriptorBuffersEXT(dev),
    vkCmdSetDescriptorBufferOffsetsEXT: load_vkCmdSetDescriptorBufferOffsetsEXT(dev),
    vkCmdBindDescriptorBufferEmbeddedSamplersEXT: load_vkCmdBindDescriptorBufferEmbeddedSamplersEXT(dev),
    vkGetBufferOpaqueCaptureDescriptorDataEXT: load_vkGetBufferOpaqueCaptureDescriptorDataEXT(dev),
    vkGetImageOpaqueCaptureDescriptorDataEXT: load_vkGetImageOpaqueCaptureDescriptorDataEXT(dev),
    vkGetImageViewOpaqueCaptureDescriptorDataEXT: load_vkGetImageViewOpaqueCaptureDescriptorDataEXT(dev),
    vkGetSamplerOpaqueCaptureDescriptorDataEXT: load_vkGetSamplerOpaqueCaptureDescriptorDataEXT(dev),
    vkGetAccelerationStructureOpaqueCaptureDescriptorDataEXT: load_vkGetAccelerationStructureOpaqueCaptureDescriptorDataEXT(dev),
    vkSetDeviceMemoryPriorityEXT: load_vkSetDeviceMemoryPriorityEXT(dev),
    vkWaitForPresent2KHR: load_vkWaitForPresent2KHR(dev),
    vkWaitForPresentKHR: load_vkWaitForPresentKHR(dev),
    vkCreateBufferCollectionFUCHSIA: load_vkCreateBufferCollectionFUCHSIA(dev),
    vkSetBufferCollectionBufferConstraintsFUCHSIA: load_vkSetBufferCollectionBufferConstraintsFUCHSIA(dev),
    vkSetBufferCollectionImageConstraintsFUCHSIA: load_vkSetBufferCollectionImageConstraintsFUCHSIA(dev),
    vkDestroyBufferCollectionFUCHSIA: load_vkDestroyBufferCollectionFUCHSIA(dev),
    vkGetBufferCollectionPropertiesFUCHSIA: load_vkGetBufferCollectionPropertiesFUCHSIA(dev),
    vkCreateCudaModuleNV: load_vkCreateCudaModuleNV(dev),
    vkGetCudaModuleCacheNV: load_vkGetCudaModuleCacheNV(dev),
    vkCreateCudaFunctionNV: load_vkCreateCudaFunctionNV(dev),
    vkDestroyCudaModuleNV: load_vkDestroyCudaModuleNV(dev),
    vkDestroyCudaFunctionNV: load_vkDestroyCudaFunctionNV(dev),
    vkCmdCudaLaunchKernelNV: load_vkCmdCudaLaunchKernelNV(dev),
    vkCmdBeginRendering: load_vkCmdBeginRendering(dev),
    vkCmdBeginRenderingKHR: load_vkCmdBeginRenderingKHR(dev),
    vkCmdEndRendering: load_vkCmdEndRendering(dev),
    vkCmdEndRendering2KHR: load_vkCmdEndRendering2KHR(dev),
    vkCmdEndRendering2EXT: load_vkCmdEndRendering2EXT(dev),
    vkCmdEndRenderingKHR: load_vkCmdEndRenderingKHR(dev),
    vkGetDescriptorSetLayoutHostMappingInfoVALVE: load_vkGetDescriptorSetLayoutHostMappingInfoVALVE(dev),
    vkGetDescriptorSetHostMappingVALVE: load_vkGetDescriptorSetHostMappingVALVE(dev),
    vkCreateMicromapEXT: load_vkCreateMicromapEXT(dev),
    vkCmdBuildMicromapsEXT: load_vkCmdBuildMicromapsEXT(dev),
    vkBuildMicromapsEXT: load_vkBuildMicromapsEXT(dev),
    vkDestroyMicromapEXT: load_vkDestroyMicromapEXT(dev),
    vkCmdCopyMicromapEXT: load_vkCmdCopyMicromapEXT(dev),
    vkCopyMicromapEXT: load_vkCopyMicromapEXT(dev),
    vkCmdCopyMicromapToMemoryEXT: load_vkCmdCopyMicromapToMemoryEXT(dev),
    vkCopyMicromapToMemoryEXT: load_vkCopyMicromapToMemoryEXT(dev),
    vkCmdCopyMemoryToMicromapEXT: load_vkCmdCopyMemoryToMicromapEXT(dev),
    vkCopyMemoryToMicromapEXT: load_vkCopyMemoryToMicromapEXT(dev),
    vkCmdWriteMicromapsPropertiesEXT: load_vkCmdWriteMicromapsPropertiesEXT(dev),
    vkWriteMicromapsPropertiesEXT: load_vkWriteMicromapsPropertiesEXT(dev),
    vkGetDeviceMicromapCompatibilityEXT: load_vkGetDeviceMicromapCompatibilityEXT(dev),
    vkGetMicromapBuildSizesEXT: load_vkGetMicromapBuildSizesEXT(dev),
    vkGetShaderModuleIdentifierEXT: load_vkGetShaderModuleIdentifierEXT(dev),
    vkGetShaderModuleCreateInfoIdentifierEXT: load_vkGetShaderModuleCreateInfoIdentifierEXT(dev),
    vkGetImageSubresourceLayout2: load_vkGetImageSubresourceLayout2(dev),
    vkGetImageSubresourceLayout2KHR: load_vkGetImageSubresourceLayout2KHR(dev),
    vkGetImageSubresourceLayout2EXT: load_vkGetImageSubresourceLayout2EXT(dev),
    vkGetPipelinePropertiesEXT: load_vkGetPipelinePropertiesEXT(dev),
    vkExportMetalObjectsEXT: load_vkExportMetalObjectsEXT(dev),
    vkCmdBindTileMemoryQCOM: load_vkCmdBindTileMemoryQCOM(dev),
    vkGetFramebufferTilePropertiesQCOM: load_vkGetFramebufferTilePropertiesQCOM(dev),
    vkGetDynamicRenderingTilePropertiesQCOM: load_vkGetDynamicRenderingTilePropertiesQCOM(dev),
    vkCreateOpticalFlowSessionNV: load_vkCreateOpticalFlowSessionNV(dev),
    vkDestroyOpticalFlowSessionNV: load_vkDestroyOpticalFlowSessionNV(dev),
    vkBindOpticalFlowSessionImageNV: load_vkBindOpticalFlowSessionImageNV(dev),
    vkCmdOpticalFlowExecuteNV: load_vkCmdOpticalFlowExecuteNV(dev),
    vkGetDeviceFaultInfoEXT: load_vkGetDeviceFaultInfoEXT(dev),
    vkGetDeviceFaultReportsKHR: load_vkGetDeviceFaultReportsKHR(dev),
    vkGetDeviceFaultDebugInfoKHR: load_vkGetDeviceFaultDebugInfoKHR(dev),
    vkCmdSetDepthBias2EXT: load_vkCmdSetDepthBias2EXT(dev),
    vkReleaseSwapchainImagesKHR: load_vkReleaseSwapchainImagesKHR(dev),
    vkReleaseSwapchainImagesEXT: load_vkReleaseSwapchainImagesEXT(dev),
    vkGetDeviceImageSubresourceLayout: load_vkGetDeviceImageSubresourceLayout(dev),
    vkGetDeviceImageSubresourceLayoutKHR: load_vkGetDeviceImageSubresourceLayoutKHR(dev),
    vkMapMemory2: load_vkMapMemory2(dev),
    vkMapMemory2KHR: load_vkMapMemory2KHR(dev),
    vkUnmapMemory2: load_vkUnmapMemory2(dev),
    vkUnmapMemory2KHR: load_vkUnmapMemory2KHR(dev),
    vkCreateShadersEXT: load_vkCreateShadersEXT(dev),
    vkDestroyShaderEXT: load_vkDestroyShaderEXT(dev),
    vkGetShaderBinaryDataEXT: load_vkGetShaderBinaryDataEXT(dev),
    vkCmdBindShadersEXT: load_vkCmdBindShadersEXT(dev),
    vkSetSwapchainPresentTimingQueueSizeEXT: load_vkSetSwapchainPresentTimingQueueSizeEXT(dev),
    vkGetSwapchainTimingPropertiesEXT: load_vkGetSwapchainTimingPropertiesEXT(dev),
    vkGetSwapchainTimeDomainPropertiesEXT: load_vkGetSwapchainTimeDomainPropertiesEXT(dev),
    vkGetPastPresentationTimingEXT: load_vkGetPastPresentationTimingEXT(dev),
    vkGetScreenBufferPropertiesQNX: load_vkGetScreenBufferPropertiesQNX(dev),
    vkGetExecutionGraphPipelineScratchSizeAMDX: load_vkGetExecutionGraphPipelineScratchSizeAMDX(dev),
    vkGetExecutionGraphPipelineNodeIndexAMDX: load_vkGetExecutionGraphPipelineNodeIndexAMDX(dev),
    vkCreateExecutionGraphPipelinesAMDX: load_vkCreateExecutionGraphPipelinesAMDX(dev),
    vkCmdInitializeGraphScratchMemoryAMDX: load_vkCmdInitializeGraphScratchMemoryAMDX(dev),
    vkCmdDispatchGraphAMDX: load_vkCmdDispatchGraphAMDX(dev),
    vkCmdDispatchGraphIndirectAMDX: load_vkCmdDispatchGraphIndirectAMDX(dev),
    vkCmdDispatchGraphIndirectCountAMDX: load_vkCmdDispatchGraphIndirectCountAMDX(dev),
    vkCreateGpaSessionAMD: load_vkCreateGpaSessionAMD(dev),
    vkDestroyGpaSessionAMD: load_vkDestroyGpaSessionAMD(dev),
    vkSetGpaDeviceClockModeAMD: load_vkSetGpaDeviceClockModeAMD(dev),
    vkGetGpaDeviceClockInfoAMD: load_vkGetGpaDeviceClockInfoAMD(dev),
    vkCmdBeginGpaSessionAMD: load_vkCmdBeginGpaSessionAMD(dev),
    vkCmdEndGpaSessionAMD: load_vkCmdEndGpaSessionAMD(dev),
    vkCmdBeginGpaSampleAMD: load_vkCmdBeginGpaSampleAMD(dev),
    vkCmdEndGpaSampleAMD: load_vkCmdEndGpaSampleAMD(dev),
    vkGetGpaSessionStatusAMD: load_vkGetGpaSessionStatusAMD(dev),
    vkGetGpaSessionResultsAMD: load_vkGetGpaSessionResultsAMD(dev),
    vkResetGpaSessionAMD: load_vkResetGpaSessionAMD(dev),
    vkCmdCopyGpaSessionResultsAMD: load_vkCmdCopyGpaSessionResultsAMD(dev),
    vkCmdBindDescriptorSets2: load_vkCmdBindDescriptorSets2(dev),
    vkCmdBindDescriptorSets2KHR: load_vkCmdBindDescriptorSets2KHR(dev),
    vkCmdPushConstants2: load_vkCmdPushConstants2(dev),
    vkCmdPushConstants2KHR: load_vkCmdPushConstants2KHR(dev),
    vkCmdPushDescriptorSet2: load_vkCmdPushDescriptorSet2(dev),
    vkCmdPushDescriptorSet2KHR: load_vkCmdPushDescriptorSet2KHR(dev),
    vkCmdPushDescriptorSetWithTemplate2: load_vkCmdPushDescriptorSetWithTemplate2(dev),
    vkCmdPushDescriptorSetWithTemplate2KHR: load_vkCmdPushDescriptorSetWithTemplate2KHR(dev),
    vkCmdSetDescriptorBufferOffsets2EXT: load_vkCmdSetDescriptorBufferOffsets2EXT(dev),
    vkCmdBindDescriptorBufferEmbeddedSamplers2EXT: load_vkCmdBindDescriptorBufferEmbeddedSamplers2EXT(dev),
    vkSetLatencySleepModeNV: load_vkSetLatencySleepModeNV(dev),
    vkLatencySleepNV: load_vkLatencySleepNV(dev),
    vkSetLatencyMarkerNV: load_vkSetLatencyMarkerNV(dev),
    vkGetLatencyTimingsNV: load_vkGetLatencyTimingsNV(dev),
    vkQueueNotifyOutOfBandNV: load_vkQueueNotifyOutOfBandNV(dev),
    vkSetLatencySleepModeLegacyNV: load_vkSetLatencySleepModeLegacyNV(dev),
    vkLatencySleepLegacyNV: load_vkLatencySleepLegacyNV(dev),
    vkSetLatencyMarkerLegacyNV: load_vkSetLatencyMarkerLegacyNV(dev),
    vkGetLatencyTimingsLegacyNV: load_vkGetLatencyTimingsLegacyNV(dev),
    vkQueueNotifyOutOfBandLegacyNV: load_vkQueueNotifyOutOfBandLegacyNV(dev),
    vkGetSleepStatusLegacyNV: load_vkGetSleepStatusLegacyNV(dev),
    vkShutdownLatencyDeviceLegacyNV: load_vkShutdownLatencyDeviceLegacyNV(dev),
    vkCmdSetRenderingAttachmentLocations: load_vkCmdSetRenderingAttachmentLocations(dev),
    vkCmdSetRenderingAttachmentLocationsKHR: load_vkCmdSetRenderingAttachmentLocationsKHR(dev),
    vkCmdSetRenderingInputAttachmentIndices: load_vkCmdSetRenderingInputAttachmentIndices(dev),
    vkCmdSetRenderingInputAttachmentIndicesKHR: load_vkCmdSetRenderingInputAttachmentIndicesKHR(dev),
    vkCmdSetDepthClampRangeEXT: load_vkCmdSetDepthClampRangeEXT(dev),
    vkGetMemoryMetalHandleEXT: load_vkGetMemoryMetalHandleEXT(dev),
    vkGetMemoryMetalHandlePropertiesEXT: load_vkGetMemoryMetalHandlePropertiesEXT(dev),
    vkConvertCooperativeVectorMatrixNV: load_vkConvertCooperativeVectorMatrixNV(dev),
    vkCmdConvertCooperativeVectorMatrixNV: load_vkCmdConvertCooperativeVectorMatrixNV(dev),
    vkCmdDispatchTileQCOM: load_vkCmdDispatchTileQCOM(dev),
    vkCmdBeginPerTileExecutionQCOM: load_vkCmdBeginPerTileExecutionQCOM(dev),
    vkCmdEndPerTileExecutionQCOM: load_vkCmdEndPerTileExecutionQCOM(dev),
    vkCreateExternalComputeQueueNV: load_vkCreateExternalComputeQueueNV(dev),
    vkDestroyExternalComputeQueueNV: load_vkDestroyExternalComputeQueueNV(dev),
    vkCreateShaderInstrumentationARM: load_vkCreateShaderInstrumentationARM(dev),
    vkDestroyShaderInstrumentationARM: load_vkDestroyShaderInstrumentationARM(dev),
    vkCmdBeginShaderInstrumentationARM: load_vkCmdBeginShaderInstrumentationARM(dev),
    vkCmdEndShaderInstrumentationARM: load_vkCmdEndShaderInstrumentationARM(dev),
    vkGetShaderInstrumentationValuesARM: load_vkGetShaderInstrumentationValuesARM(dev),
    vkClearShaderInstrumentationMetricsARM: load_vkClearShaderInstrumentationMetricsARM(dev),
    vkCreateTensorARM: load_vkCreateTensorARM(dev),
    vkDestroyTensorARM: load_vkDestroyTensorARM(dev),
    vkCreateTensorViewARM: load_vkCreateTensorViewARM(dev),
    vkDestroyTensorViewARM: load_vkDestroyTensorViewARM(dev),
    vkGetTensorMemoryRequirementsARM: load_vkGetTensorMemoryRequirementsARM(dev),
    vkBindTensorMemoryARM: load_vkBindTensorMemoryARM(dev),
    vkGetDeviceTensorMemoryRequirementsARM: load_vkGetDeviceTensorMemoryRequirementsARM(dev),
    vkCmdCopyTensorARM: load_vkCmdCopyTensorARM(dev),
    vkGetTensorOpaqueCaptureDescriptorDataARM: load_vkGetTensorOpaqueCaptureDescriptorDataARM(dev),
    vkGetTensorViewOpaqueCaptureDescriptorDataARM: load_vkGetTensorViewOpaqueCaptureDescriptorDataARM(dev),
    vkCreateDataGraphPipelinesARM: load_vkCreateDataGraphPipelinesARM(dev),
    vkCreateDataGraphPipelineSessionARM: load_vkCreateDataGraphPipelineSessionARM(dev),
    vkGetDataGraphPipelineSessionBindPointRequirementsARM: load_vkGetDataGraphPipelineSessionBindPointRequirementsARM(dev),
    vkGetDataGraphPipelineSessionMemoryRequirementsARM: load_vkGetDataGraphPipelineSessionMemoryRequirementsARM(dev),
    vkBindDataGraphPipelineSessionMemoryARM: load_vkBindDataGraphPipelineSessionMemoryARM(dev),
    vkDestroyDataGraphPipelineSessionARM: load_vkDestroyDataGraphPipelineSessionARM(dev),
    vkCmdDispatchDataGraphARM: load_vkCmdDispatchDataGraphARM(dev),
    vkGetDataGraphPipelineAvailablePropertiesARM: load_vkGetDataGraphPipelineAvailablePropertiesARM(dev),
    vkGetDataGraphPipelinePropertiesARM: load_vkGetDataGraphPipelinePropertiesARM(dev),
    vkGetNativeBufferPropertiesOHOS: load_vkGetNativeBufferPropertiesOHOS(dev),
    vkGetMemoryNativeBufferOHOS: load_vkGetMemoryNativeBufferOHOS(dev),
    vkGetSwapchainGrallocUsageOHOS: load_vkGetSwapchainGrallocUsageOHOS(dev),
    vkAcquireImageOHOS: load_vkAcquireImageOHOS(dev),
    vkQueueSignalReleaseImageOHOS: load_vkQueueSignalReleaseImageOHOS(dev),
    vkQueueSetPerfHintQCOM: load_vkQueueSetPerfHintQCOM(dev),
    vkCmdSetComputeOccupancyPriorityNV: load_vkCmdSetComputeOccupancyPriorityNV(dev),
    vkWriteSamplerDescriptorsEXT: load_vkWriteSamplerDescriptorsEXT(dev),
    vkWriteResourceDescriptorsEXT: load_vkWriteResourceDescriptorsEXT(dev),
    vkCmdBindSamplerHeapEXT: load_vkCmdBindSamplerHeapEXT(dev),
    vkCmdBindResourceHeapEXT: load_vkCmdBindResourceHeapEXT(dev),
    vkCmdPushDataEXT: load_vkCmdPushDataEXT(dev),
    vkRegisterCustomBorderColorEXT: load_vkRegisterCustomBorderColorEXT(dev),
    vkUnregisterCustomBorderColorEXT: load_vkUnregisterCustomBorderColorEXT(dev),
    vkGetImageOpaqueCaptureDataEXT: load_vkGetImageOpaqueCaptureDataEXT(dev),
    vkGetTensorOpaqueCaptureDataARM: load_vkGetTensorOpaqueCaptureDataARM(dev),
    vkCmdCopyMemoryKHR: load_vkCmdCopyMemoryKHR(dev),
    vkCmdCopyMemoryToImageKHR: load_vkCmdCopyMemoryToImageKHR(dev),
    vkCmdCopyImageToMemoryKHR: load_vkCmdCopyImageToMemoryKHR(dev),
    vkCmdUpdateMemoryKHR: load_vkCmdUpdateMemoryKHR(dev),
    vkCmdFillMemoryKHR: load_vkCmdFillMemoryKHR(dev),
    vkCmdCopyQueryPoolResultsToMemoryKHR: load_vkCmdCopyQueryPoolResultsToMemoryKHR(dev),
    vkCmdBeginConditionalRendering2EXT: load_vkCmdBeginConditionalRendering2EXT(dev),
    vkCmdBindTransformFeedbackBuffers2EXT: load_vkCmdBindTransformFeedbackBuffers2EXT(dev),
    vkCmdBeginTransformFeedback2EXT: load_vkCmdBeginTransformFeedback2EXT(dev),
    vkCmdEndTransformFeedback2EXT: load_vkCmdEndTransformFeedback2EXT(dev),
    vkCmdDrawIndirectByteCount2EXT: load_vkCmdDrawIndirectByteCount2EXT(dev),
    vkCmdWriteMarkerToMemoryAMD: load_vkCmdWriteMarkerToMemoryAMD(dev),
    vkCmdBindIndexBuffer3KHR: load_vkCmdBindIndexBuffer3KHR(dev),
    vkCmdBindVertexBuffers3KHR: load_vkCmdBindVertexBuffers3KHR(dev),
    vkCmdDrawIndirect2KHR: load_vkCmdDrawIndirect2KHR(dev),
    vkCmdDrawIndexedIndirect2KHR: load_vkCmdDrawIndexedIndirect2KHR(dev),
    vkCmdDrawIndirectCount2KHR: load_vkCmdDrawIndirectCount2KHR(dev),
    vkCmdDrawIndexedIndirectCount2KHR: load_vkCmdDrawIndexedIndirectCount2KHR(dev),
    vkCmdDrawMeshTasksIndirect2EXT: load_vkCmdDrawMeshTasksIndirect2EXT(dev),
    vkCmdDrawMeshTasksIndirectCount2EXT: load_vkCmdDrawMeshTasksIndirectCount2EXT(dev),
    vkCmdDispatchIndirect2KHR: load_vkCmdDispatchIndirect2KHR(dev),
    vkCreateAccelerationStructure2KHR: load_vkCreateAccelerationStructure2KHR(dev),
    vkCmdSetDispatchParametersARM: load_vkCmdSetDispatchParametersARM(dev),
  }
}

