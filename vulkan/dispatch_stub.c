// Generated loaders — DO NOT EDIT.
#define VK_NO_PROTOTYPES
#define VK_ENABLE_BETA_EXTENSIONS
#if defined(_WIN32)
#define WIN32_LEAN_AND_MEAN
#define NOMINMAX
#include <windows.h>
#else
#include <dlfcn.h>
#endif
#include <stdlib.h>
#include "include/vulkan/vulkan.h"
#include "moonbit.h"

#if defined(__STDC_VERSION__) && __STDC_VERSION__ >= 201112L
#define TYCHO_STATIC_ASSERT(cond, msg) _Static_assert(cond, msg)
#else
#define TYCHO_SA_JOIN2(a, b) a##b
#define TYCHO_SA_JOIN(a, b) TYCHO_SA_JOIN2(a, b)
#define TYCHO_STATIC_ASSERT(cond, msg) typedef char TYCHO_SA_JOIN(tycho_sa_, __LINE__)[(cond) ? 1 : -1]
#endif

static PFN_vkGetInstanceProcAddr g_tycho_gipa = NULL;
static PFN_vkGetDeviceProcAddr g_tycho_gdpa = NULL;
static VkInstance g_tycho_last_inst = VK_NULL_HANDLE;
static int g_tycho_vk_tried = 0;

static void tycho_vk_ensure_loaded(void) {
  if (g_tycho_vk_tried) return;
  g_tycho_vk_tried = 1;
  const char *env = getenv("TYCHO_VULKAN_LIB");
#if defined(_WIN32)
  HMODULE lib = (env && env[0]) ? LoadLibraryA(env) : NULL;
  if (!lib) lib = LoadLibraryA("vulkan-1.dll");
  if (lib) {
    g_tycho_gipa = (PFN_vkGetInstanceProcAddr)GetProcAddress(lib, "vkGetInstanceProcAddr");
  }
#else
  const char *cands[] = {
#if defined(__APPLE__)
    "libvulkan.1.dylib",
    "libvulkan.dylib",
    "/opt/homebrew/lib/libvulkan.1.dylib",
    "/usr/local/lib/libvulkan.1.dylib",
    "libMoltenVK.dylib",
    "/opt/homebrew/lib/libMoltenVK.dylib",
    "/usr/local/lib/libMoltenVK.dylib",
#else
    "libvulkan.so.1",
    "libvulkan.so",
#endif
    NULL
  };
  if (env && env[0]) {
    void *lib = dlopen(env, RTLD_NOW | RTLD_LOCAL);
    if (lib) g_tycho_gipa = (PFN_vkGetInstanceProcAddr)dlsym(lib, "vkGetInstanceProcAddr");
  }
  for (int i = 0; !g_tycho_gipa && cands[i]; i++) {
    void *lib = dlopen(cands[i], RTLD_NOW | RTLD_LOCAL);
    if (lib) g_tycho_gipa = (PFN_vkGetInstanceProcAddr)dlsym(lib, "vkGetInstanceProcAddr");
  }
#endif
}

VkInstance tycho_vk_last_instance(void) { return g_tycho_last_inst; }

void *tycho_vk_gpa(VkInstance inst, const char *name) {
  tycho_vk_ensure_loaded();
  if (!g_tycho_gipa) return NULL;
  if (inst != VK_NULL_HANDLE) g_tycho_last_inst = inst;
  return (void *)g_tycho_gipa(inst, name);
}

void *tycho_vk_gdpa(VkDevice dev, const char *name) {
  tycho_vk_ensure_loaded();
  if (!g_tycho_gipa) return NULL;
  if (!g_tycho_gdpa && g_tycho_last_inst != VK_NULL_HANDLE) {
    g_tycho_gdpa = (PFN_vkGetDeviceProcAddr)g_tycho_gipa(g_tycho_last_inst, "vkGetDeviceProcAddr");
  }
  if (!g_tycho_gdpa) {
    g_tycho_gdpa = (PFN_vkGetDeviceProcAddr)g_tycho_gipa(VK_NULL_HANDLE, "vkGetDeviceProcAddr");
  }
  if (g_tycho_gdpa && dev != VK_NULL_HANDLE) return (void *)g_tycho_gdpa(dev, name);
  return (void *)g_tycho_gipa(g_tycho_last_inst, name);
}

MOONBIT_FFI_EXPORT void *tycho_entry_vkGetInstanceProcAddr(VkInstance inst, const char *pName) {
  return tycho_vk_gpa(inst, pName);
}
MOONBIT_FFI_EXPORT int32_t tycho_entry_vkCreateInstance(const VkInstanceCreateInfo *pCreateInfo, const VkAllocationCallbacks *pAllocator, VkInstance *pInstance) {
  PFN_vkCreateInstance fn = (PFN_vkCreateInstance)tycho_vk_gpa(VK_NULL_HANDLE, "vkCreateInstance");
  if (!fn) return (int32_t)VK_ERROR_INITIALIZATION_FAILED;
  VkResult r = fn(pCreateInfo, pAllocator, pInstance);
  if (r == VK_SUCCESS && pInstance && *pInstance != VK_NULL_HANDLE) g_tycho_last_inst = *pInstance;
  return (int32_t)r;
}
MOONBIT_FFI_EXPORT int32_t tycho_entry_vkEnumerateInstanceVersion(uint32_t *pApiVersion) {
  PFN_vkEnumerateInstanceVersion fn = (PFN_vkEnumerateInstanceVersion)tycho_vk_gpa(VK_NULL_HANDLE, "vkEnumerateInstanceVersion");
  if (!fn) { if (pApiVersion) *pApiVersion = VK_API_VERSION_1_0; return 0; }
  return (int32_t)fn(pApiVersion);
}
MOONBIT_FFI_EXPORT int32_t tycho_entry_vkEnumerateInstanceLayerProperties(uint32_t *pPropertyCount, VkLayerProperties *pProperties) {
  PFN_vkEnumerateInstanceLayerProperties fn = (PFN_vkEnumerateInstanceLayerProperties)tycho_vk_gpa(VK_NULL_HANDLE, "vkEnumerateInstanceLayerProperties");
  return fn ? (int32_t)fn(pPropertyCount, pProperties) : (int32_t)VK_ERROR_INITIALIZATION_FAILED;
}
MOONBIT_FFI_EXPORT int32_t tycho_entry_vkEnumerateInstanceExtensionProperties(const char *pLayerName, uint32_t *pPropertyCount, VkExtensionProperties *pProperties) {
  PFN_vkEnumerateInstanceExtensionProperties fn = (PFN_vkEnumerateInstanceExtensionProperties)tycho_vk_gpa(VK_NULL_HANDLE, "vkEnumerateInstanceExtensionProperties");
  return fn ? (int32_t)fn(pLayerName, pPropertyCount, pProperties) : (int32_t)VK_ERROR_INITIALIZATION_FAILED;
}
MOONBIT_FFI_EXPORT void tycho_entry_vkGetExternalComputeQueueDataNV(VkExternalComputeQueueNV externalQueue, VkExternalComputeQueueDataParamsNV *params, void *pData) {
  typedef void (VKAPI_PTR *TychoPFN_ECQ)(VkExternalComputeQueueNV, VkExternalComputeQueueDataParamsNV *, void *);
  TychoPFN_ECQ fn = (TychoPFN_ECQ)tycho_vk_gpa(VK_NULL_HANDLE, "vkGetExternalComputeQueueDataNV");
  if (fn) fn(externalQueue, params, pData);
}

TYCHO_STATIC_ASSERT(sizeof(VkInstance) <= sizeof(void*), "tycho ABI: vkDestroyInstance instance wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkDestroyInstance(void *h) { return tycho_vk_gpa((VkInstance)h, "vkDestroyInstance"); }
TYCHO_STATIC_ASSERT(sizeof(VkInstance) <= sizeof(void*), "tycho ABI: vkEnumeratePhysicalDevices instance wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkEnumeratePhysicalDevices(void *h) { return tycho_vk_gpa((VkInstance)h, "vkEnumeratePhysicalDevices"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetDeviceProcAddr device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetDeviceProcAddr(void *h) { return tycho_vk_gpa((VkInstance)h, "vkGetDeviceProcAddr"); }
TYCHO_STATIC_ASSERT(sizeof(VkPhysicalDevice) <= sizeof(void*), "tycho ABI: vkGetPhysicalDeviceProperties physicalDevice wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetPhysicalDeviceProperties(void *h) { return tycho_vk_gpa((VkInstance)h, "vkGetPhysicalDeviceProperties"); }
TYCHO_STATIC_ASSERT(sizeof(VkPhysicalDevice) <= sizeof(void*), "tycho ABI: vkGetPhysicalDeviceQueueFamilyProperties physicalDevice wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetPhysicalDeviceQueueFamilyProperties(void *h) { return tycho_vk_gpa((VkInstance)h, "vkGetPhysicalDeviceQueueFamilyProperties"); }
TYCHO_STATIC_ASSERT(sizeof(VkPhysicalDevice) <= sizeof(void*), "tycho ABI: vkGetPhysicalDeviceMemoryProperties physicalDevice wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetPhysicalDeviceMemoryProperties(void *h) { return tycho_vk_gpa((VkInstance)h, "vkGetPhysicalDeviceMemoryProperties"); }
TYCHO_STATIC_ASSERT(sizeof(VkPhysicalDevice) <= sizeof(void*), "tycho ABI: vkGetPhysicalDeviceFeatures physicalDevice wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetPhysicalDeviceFeatures(void *h) { return tycho_vk_gpa((VkInstance)h, "vkGetPhysicalDeviceFeatures"); }
TYCHO_STATIC_ASSERT(sizeof(VkPhysicalDevice) <= sizeof(void*), "tycho ABI: vkGetPhysicalDeviceFormatProperties physicalDevice wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkFormat) <= 4, "tycho ABI: vkGetPhysicalDeviceFormatProperties format wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetPhysicalDeviceFormatProperties(void *h) { return tycho_vk_gpa((VkInstance)h, "vkGetPhysicalDeviceFormatProperties"); }
TYCHO_STATIC_ASSERT(sizeof(VkPhysicalDevice) <= sizeof(void*), "tycho ABI: vkGetPhysicalDeviceImageFormatProperties physicalDevice wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkFormat) <= 4, "tycho ABI: vkGetPhysicalDeviceImageFormatProperties format wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkImageType) <= 4, "tycho ABI: vkGetPhysicalDeviceImageFormatProperties type wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkImageTiling) <= 4, "tycho ABI: vkGetPhysicalDeviceImageFormatProperties tiling wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkImageUsageFlags) <= 4, "tycho ABI: vkGetPhysicalDeviceImageFormatProperties usage wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkImageCreateFlags) <= 4, "tycho ABI: vkGetPhysicalDeviceImageFormatProperties flags wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetPhysicalDeviceImageFormatProperties(void *h) { return tycho_vk_gpa((VkInstance)h, "vkGetPhysicalDeviceImageFormatProperties"); }
TYCHO_STATIC_ASSERT(sizeof(VkPhysicalDevice) <= sizeof(void*), "tycho ABI: vkCreateDevice physicalDevice wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCreateDevice(void *h) { return tycho_vk_gpa((VkInstance)h, "vkCreateDevice"); }
TYCHO_STATIC_ASSERT(sizeof(VkPhysicalDevice) <= sizeof(void*), "tycho ABI: vkEnumerateDeviceLayerProperties physicalDevice wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkEnumerateDeviceLayerProperties(void *h) { return tycho_vk_gpa((VkInstance)h, "vkEnumerateDeviceLayerProperties"); }
TYCHO_STATIC_ASSERT(sizeof(VkPhysicalDevice) <= sizeof(void*), "tycho ABI: vkEnumerateDeviceExtensionProperties physicalDevice wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkEnumerateDeviceExtensionProperties(void *h) { return tycho_vk_gpa((VkInstance)h, "vkEnumerateDeviceExtensionProperties"); }
TYCHO_STATIC_ASSERT(sizeof(VkPhysicalDevice) <= sizeof(void*), "tycho ABI: vkGetPhysicalDeviceSparseImageFormatProperties physicalDevice wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkFormat) <= 4, "tycho ABI: vkGetPhysicalDeviceSparseImageFormatProperties format wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkImageType) <= 4, "tycho ABI: vkGetPhysicalDeviceSparseImageFormatProperties type wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkSampleCountFlagBits) <= 4, "tycho ABI: vkGetPhysicalDeviceSparseImageFormatProperties samples wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkImageUsageFlags) <= 4, "tycho ABI: vkGetPhysicalDeviceSparseImageFormatProperties usage wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkImageTiling) <= 4, "tycho ABI: vkGetPhysicalDeviceSparseImageFormatProperties tiling wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetPhysicalDeviceSparseImageFormatProperties(void *h) { return tycho_vk_gpa((VkInstance)h, "vkGetPhysicalDeviceSparseImageFormatProperties"); }
TYCHO_STATIC_ASSERT(sizeof(VkInstance) <= sizeof(void*), "tycho ABI: vkCreateAndroidSurfaceKHR instance wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCreateAndroidSurfaceKHR(void *h) { return tycho_vk_gpa((VkInstance)h, "vkCreateAndroidSurfaceKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkInstance) <= sizeof(void*), "tycho ABI: vkCreateSurfaceOHOS instance wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCreateSurfaceOHOS(void *h) { return tycho_vk_gpa((VkInstance)h, "vkCreateSurfaceOHOS"); }
TYCHO_STATIC_ASSERT(sizeof(VkPhysicalDevice) <= sizeof(void*), "tycho ABI: vkGetPhysicalDeviceDisplayPropertiesKHR physicalDevice wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetPhysicalDeviceDisplayPropertiesKHR(void *h) { return tycho_vk_gpa((VkInstance)h, "vkGetPhysicalDeviceDisplayPropertiesKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkPhysicalDevice) <= sizeof(void*), "tycho ABI: vkGetPhysicalDeviceDisplayPlanePropertiesKHR physicalDevice wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetPhysicalDeviceDisplayPlanePropertiesKHR(void *h) { return tycho_vk_gpa((VkInstance)h, "vkGetPhysicalDeviceDisplayPlanePropertiesKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkPhysicalDevice) <= sizeof(void*), "tycho ABI: vkGetDisplayPlaneSupportedDisplaysKHR physicalDevice wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkGetDisplayPlaneSupportedDisplaysKHR planeIndex wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetDisplayPlaneSupportedDisplaysKHR(void *h) { return tycho_vk_gpa((VkInstance)h, "vkGetDisplayPlaneSupportedDisplaysKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkPhysicalDevice) <= sizeof(void*), "tycho ABI: vkGetDisplayModePropertiesKHR physicalDevice wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDisplayKHR) <= sizeof(void*), "tycho ABI: vkGetDisplayModePropertiesKHR display wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetDisplayModePropertiesKHR(void *h) { return tycho_vk_gpa((VkInstance)h, "vkGetDisplayModePropertiesKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkPhysicalDevice) <= sizeof(void*), "tycho ABI: vkCreateDisplayModeKHR physicalDevice wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDisplayKHR) <= sizeof(void*), "tycho ABI: vkCreateDisplayModeKHR display wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCreateDisplayModeKHR(void *h) { return tycho_vk_gpa((VkInstance)h, "vkCreateDisplayModeKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkPhysicalDevice) <= sizeof(void*), "tycho ABI: vkGetDisplayPlaneCapabilitiesKHR physicalDevice wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDisplayModeKHR) <= sizeof(void*), "tycho ABI: vkGetDisplayPlaneCapabilitiesKHR mode wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkGetDisplayPlaneCapabilitiesKHR planeIndex wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetDisplayPlaneCapabilitiesKHR(void *h) { return tycho_vk_gpa((VkInstance)h, "vkGetDisplayPlaneCapabilitiesKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkInstance) <= sizeof(void*), "tycho ABI: vkCreateDisplayPlaneSurfaceKHR instance wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCreateDisplayPlaneSurfaceKHR(void *h) { return tycho_vk_gpa((VkInstance)h, "vkCreateDisplayPlaneSurfaceKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkInstance) <= sizeof(void*), "tycho ABI: vkDestroySurfaceKHR instance wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkSurfaceKHR) <= sizeof(void*), "tycho ABI: vkDestroySurfaceKHR surface wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkDestroySurfaceKHR(void *h) { return tycho_vk_gpa((VkInstance)h, "vkDestroySurfaceKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkPhysicalDevice) <= sizeof(void*), "tycho ABI: vkGetPhysicalDeviceSurfaceSupportKHR physicalDevice wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkGetPhysicalDeviceSurfaceSupportKHR queueFamilyIndex wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkSurfaceKHR) <= sizeof(void*), "tycho ABI: vkGetPhysicalDeviceSurfaceSupportKHR surface wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetPhysicalDeviceSurfaceSupportKHR(void *h) { return tycho_vk_gpa((VkInstance)h, "vkGetPhysicalDeviceSurfaceSupportKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkPhysicalDevice) <= sizeof(void*), "tycho ABI: vkGetPhysicalDeviceSurfaceCapabilitiesKHR physicalDevice wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkSurfaceKHR) <= sizeof(void*), "tycho ABI: vkGetPhysicalDeviceSurfaceCapabilitiesKHR surface wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetPhysicalDeviceSurfaceCapabilitiesKHR(void *h) { return tycho_vk_gpa((VkInstance)h, "vkGetPhysicalDeviceSurfaceCapabilitiesKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkPhysicalDevice) <= sizeof(void*), "tycho ABI: vkGetPhysicalDeviceSurfaceFormatsKHR physicalDevice wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkSurfaceKHR) <= sizeof(void*), "tycho ABI: vkGetPhysicalDeviceSurfaceFormatsKHR surface wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetPhysicalDeviceSurfaceFormatsKHR(void *h) { return tycho_vk_gpa((VkInstance)h, "vkGetPhysicalDeviceSurfaceFormatsKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkPhysicalDevice) <= sizeof(void*), "tycho ABI: vkGetPhysicalDeviceSurfacePresentModesKHR physicalDevice wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkSurfaceKHR) <= sizeof(void*), "tycho ABI: vkGetPhysicalDeviceSurfacePresentModesKHR surface wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetPhysicalDeviceSurfacePresentModesKHR(void *h) { return tycho_vk_gpa((VkInstance)h, "vkGetPhysicalDeviceSurfacePresentModesKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkInstance) <= sizeof(void*), "tycho ABI: vkCreateViSurfaceNN instance wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCreateViSurfaceNN(void *h) { return tycho_vk_gpa((VkInstance)h, "vkCreateViSurfaceNN"); }
TYCHO_STATIC_ASSERT(sizeof(VkInstance) <= sizeof(void*), "tycho ABI: vkCreateWaylandSurfaceKHR instance wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCreateWaylandSurfaceKHR(void *h) { return tycho_vk_gpa((VkInstance)h, "vkCreateWaylandSurfaceKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkPhysicalDevice) <= sizeof(void*), "tycho ABI: vkGetPhysicalDeviceWaylandPresentationSupportKHR physicalDevice wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkGetPhysicalDeviceWaylandPresentationSupportKHR queueFamilyIndex wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetPhysicalDeviceWaylandPresentationSupportKHR(void *h) { return tycho_vk_gpa((VkInstance)h, "vkGetPhysicalDeviceWaylandPresentationSupportKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkInstance) <= sizeof(void*), "tycho ABI: vkCreateUbmSurfaceSEC instance wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCreateUbmSurfaceSEC(void *h) { return tycho_vk_gpa((VkInstance)h, "vkCreateUbmSurfaceSEC"); }
TYCHO_STATIC_ASSERT(sizeof(VkPhysicalDevice) <= sizeof(void*), "tycho ABI: vkGetPhysicalDeviceUbmPresentationSupportSEC physicalDevice wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkGetPhysicalDeviceUbmPresentationSupportSEC queueFamilyIndex wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetPhysicalDeviceUbmPresentationSupportSEC(void *h) { return tycho_vk_gpa((VkInstance)h, "vkGetPhysicalDeviceUbmPresentationSupportSEC"); }
TYCHO_STATIC_ASSERT(sizeof(VkInstance) <= sizeof(void*), "tycho ABI: vkCreateWin32SurfaceKHR instance wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCreateWin32SurfaceKHR(void *h) { return tycho_vk_gpa((VkInstance)h, "vkCreateWin32SurfaceKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkPhysicalDevice) <= sizeof(void*), "tycho ABI: vkGetPhysicalDeviceWin32PresentationSupportKHR physicalDevice wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkGetPhysicalDeviceWin32PresentationSupportKHR queueFamilyIndex wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetPhysicalDeviceWin32PresentationSupportKHR(void *h) { return tycho_vk_gpa((VkInstance)h, "vkGetPhysicalDeviceWin32PresentationSupportKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkInstance) <= sizeof(void*), "tycho ABI: vkCreateXlibSurfaceKHR instance wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCreateXlibSurfaceKHR(void *h) { return tycho_vk_gpa((VkInstance)h, "vkCreateXlibSurfaceKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkPhysicalDevice) <= sizeof(void*), "tycho ABI: vkGetPhysicalDeviceXlibPresentationSupportKHR physicalDevice wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkGetPhysicalDeviceXlibPresentationSupportKHR queueFamilyIndex wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetPhysicalDeviceXlibPresentationSupportKHR(void *h) { return tycho_vk_gpa((VkInstance)h, "vkGetPhysicalDeviceXlibPresentationSupportKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkInstance) <= sizeof(void*), "tycho ABI: vkCreateXcbSurfaceKHR instance wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCreateXcbSurfaceKHR(void *h) { return tycho_vk_gpa((VkInstance)h, "vkCreateXcbSurfaceKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkPhysicalDevice) <= sizeof(void*), "tycho ABI: vkGetPhysicalDeviceXcbPresentationSupportKHR physicalDevice wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkGetPhysicalDeviceXcbPresentationSupportKHR queueFamilyIndex wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetPhysicalDeviceXcbPresentationSupportKHR(void *h) { return tycho_vk_gpa((VkInstance)h, "vkGetPhysicalDeviceXcbPresentationSupportKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkInstance) <= sizeof(void*), "tycho ABI: vkCreateDirectFBSurfaceEXT instance wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCreateDirectFBSurfaceEXT(void *h) { return tycho_vk_gpa((VkInstance)h, "vkCreateDirectFBSurfaceEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkPhysicalDevice) <= sizeof(void*), "tycho ABI: vkGetPhysicalDeviceDirectFBPresentationSupportEXT physicalDevice wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkGetPhysicalDeviceDirectFBPresentationSupportEXT queueFamilyIndex wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetPhysicalDeviceDirectFBPresentationSupportEXT(void *h) { return tycho_vk_gpa((VkInstance)h, "vkGetPhysicalDeviceDirectFBPresentationSupportEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkInstance) <= sizeof(void*), "tycho ABI: vkCreateImagePipeSurfaceFUCHSIA instance wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCreateImagePipeSurfaceFUCHSIA(void *h) { return tycho_vk_gpa((VkInstance)h, "vkCreateImagePipeSurfaceFUCHSIA"); }
TYCHO_STATIC_ASSERT(sizeof(VkInstance) <= sizeof(void*), "tycho ABI: vkCreateStreamDescriptorSurfaceGGP instance wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCreateStreamDescriptorSurfaceGGP(void *h) { return tycho_vk_gpa((VkInstance)h, "vkCreateStreamDescriptorSurfaceGGP"); }
TYCHO_STATIC_ASSERT(sizeof(VkInstance) <= sizeof(void*), "tycho ABI: vkCreateScreenSurfaceQNX instance wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCreateScreenSurfaceQNX(void *h) { return tycho_vk_gpa((VkInstance)h, "vkCreateScreenSurfaceQNX"); }
TYCHO_STATIC_ASSERT(sizeof(VkPhysicalDevice) <= sizeof(void*), "tycho ABI: vkGetPhysicalDeviceScreenPresentationSupportQNX physicalDevice wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkGetPhysicalDeviceScreenPresentationSupportQNX queueFamilyIndex wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetPhysicalDeviceScreenPresentationSupportQNX(void *h) { return tycho_vk_gpa((VkInstance)h, "vkGetPhysicalDeviceScreenPresentationSupportQNX"); }
TYCHO_STATIC_ASSERT(sizeof(VkInstance) <= sizeof(void*), "tycho ABI: vkCreateDebugReportCallbackEXT instance wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCreateDebugReportCallbackEXT(void *h) { return tycho_vk_gpa((VkInstance)h, "vkCreateDebugReportCallbackEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkInstance) <= sizeof(void*), "tycho ABI: vkDestroyDebugReportCallbackEXT instance wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDebugReportCallbackEXT) <= sizeof(void*), "tycho ABI: vkDestroyDebugReportCallbackEXT callback wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkDestroyDebugReportCallbackEXT(void *h) { return tycho_vk_gpa((VkInstance)h, "vkDestroyDebugReportCallbackEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkInstance) <= sizeof(void*), "tycho ABI: vkDebugReportMessageEXT instance wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDebugReportFlagsEXT) <= 4, "tycho ABI: vkDebugReportMessageEXT flags wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDebugReportObjectTypeEXT) <= 4, "tycho ABI: vkDebugReportMessageEXT objectType wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint64_t) <= 8, "tycho ABI: vkDebugReportMessageEXT object wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(size_t) <= 8, "tycho ABI: vkDebugReportMessageEXT location wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(int32_t) <= 4, "tycho ABI: vkDebugReportMessageEXT messageCode wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkDebugReportMessageEXT(void *h) { return tycho_vk_gpa((VkInstance)h, "vkDebugReportMessageEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkPhysicalDevice) <= sizeof(void*), "tycho ABI: vkGetPhysicalDeviceExternalImageFormatPropertiesNV physicalDevice wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkFormat) <= 4, "tycho ABI: vkGetPhysicalDeviceExternalImageFormatPropertiesNV format wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkImageType) <= 4, "tycho ABI: vkGetPhysicalDeviceExternalImageFormatPropertiesNV type wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkImageTiling) <= 4, "tycho ABI: vkGetPhysicalDeviceExternalImageFormatPropertiesNV tiling wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkImageUsageFlags) <= 4, "tycho ABI: vkGetPhysicalDeviceExternalImageFormatPropertiesNV usage wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkImageCreateFlags) <= 4, "tycho ABI: vkGetPhysicalDeviceExternalImageFormatPropertiesNV flags wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkExternalMemoryHandleTypeFlagsNV) <= 4, "tycho ABI: vkGetPhysicalDeviceExternalImageFormatPropertiesNV externalHandleType wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetPhysicalDeviceExternalImageFormatPropertiesNV(void *h) { return tycho_vk_gpa((VkInstance)h, "vkGetPhysicalDeviceExternalImageFormatPropertiesNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkPhysicalDevice) <= sizeof(void*), "tycho ABI: vkGetPhysicalDeviceFeatures2 physicalDevice wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetPhysicalDeviceFeatures2(void *h) { return tycho_vk_gpa((VkInstance)h, "vkGetPhysicalDeviceFeatures2"); }
TYCHO_STATIC_ASSERT(sizeof(VkPhysicalDevice) <= sizeof(void*), "tycho ABI: vkGetPhysicalDeviceFeatures2KHR physicalDevice wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetPhysicalDeviceFeatures2KHR(void *h) { return tycho_vk_gpa((VkInstance)h, "vkGetPhysicalDeviceFeatures2KHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkPhysicalDevice) <= sizeof(void*), "tycho ABI: vkGetPhysicalDeviceProperties2 physicalDevice wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetPhysicalDeviceProperties2(void *h) { return tycho_vk_gpa((VkInstance)h, "vkGetPhysicalDeviceProperties2"); }
TYCHO_STATIC_ASSERT(sizeof(VkPhysicalDevice) <= sizeof(void*), "tycho ABI: vkGetPhysicalDeviceProperties2KHR physicalDevice wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetPhysicalDeviceProperties2KHR(void *h) { return tycho_vk_gpa((VkInstance)h, "vkGetPhysicalDeviceProperties2KHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkPhysicalDevice) <= sizeof(void*), "tycho ABI: vkGetPhysicalDeviceFormatProperties2 physicalDevice wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkFormat) <= 4, "tycho ABI: vkGetPhysicalDeviceFormatProperties2 format wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetPhysicalDeviceFormatProperties2(void *h) { return tycho_vk_gpa((VkInstance)h, "vkGetPhysicalDeviceFormatProperties2"); }
TYCHO_STATIC_ASSERT(sizeof(VkPhysicalDevice) <= sizeof(void*), "tycho ABI: vkGetPhysicalDeviceFormatProperties2KHR physicalDevice wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkFormat) <= 4, "tycho ABI: vkGetPhysicalDeviceFormatProperties2KHR format wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetPhysicalDeviceFormatProperties2KHR(void *h) { return tycho_vk_gpa((VkInstance)h, "vkGetPhysicalDeviceFormatProperties2KHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkPhysicalDevice) <= sizeof(void*), "tycho ABI: vkGetPhysicalDeviceImageFormatProperties2 physicalDevice wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetPhysicalDeviceImageFormatProperties2(void *h) { return tycho_vk_gpa((VkInstance)h, "vkGetPhysicalDeviceImageFormatProperties2"); }
TYCHO_STATIC_ASSERT(sizeof(VkPhysicalDevice) <= sizeof(void*), "tycho ABI: vkGetPhysicalDeviceImageFormatProperties2KHR physicalDevice wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetPhysicalDeviceImageFormatProperties2KHR(void *h) { return tycho_vk_gpa((VkInstance)h, "vkGetPhysicalDeviceImageFormatProperties2KHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkPhysicalDevice) <= sizeof(void*), "tycho ABI: vkGetPhysicalDeviceQueueFamilyProperties2 physicalDevice wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetPhysicalDeviceQueueFamilyProperties2(void *h) { return tycho_vk_gpa((VkInstance)h, "vkGetPhysicalDeviceQueueFamilyProperties2"); }
TYCHO_STATIC_ASSERT(sizeof(VkPhysicalDevice) <= sizeof(void*), "tycho ABI: vkGetPhysicalDeviceQueueFamilyProperties2KHR physicalDevice wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetPhysicalDeviceQueueFamilyProperties2KHR(void *h) { return tycho_vk_gpa((VkInstance)h, "vkGetPhysicalDeviceQueueFamilyProperties2KHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkPhysicalDevice) <= sizeof(void*), "tycho ABI: vkGetPhysicalDeviceMemoryProperties2 physicalDevice wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetPhysicalDeviceMemoryProperties2(void *h) { return tycho_vk_gpa((VkInstance)h, "vkGetPhysicalDeviceMemoryProperties2"); }
TYCHO_STATIC_ASSERT(sizeof(VkPhysicalDevice) <= sizeof(void*), "tycho ABI: vkGetPhysicalDeviceMemoryProperties2KHR physicalDevice wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetPhysicalDeviceMemoryProperties2KHR(void *h) { return tycho_vk_gpa((VkInstance)h, "vkGetPhysicalDeviceMemoryProperties2KHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkPhysicalDevice) <= sizeof(void*), "tycho ABI: vkGetPhysicalDeviceSparseImageFormatProperties2 physicalDevice wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetPhysicalDeviceSparseImageFormatProperties2(void *h) { return tycho_vk_gpa((VkInstance)h, "vkGetPhysicalDeviceSparseImageFormatProperties2"); }
TYCHO_STATIC_ASSERT(sizeof(VkPhysicalDevice) <= sizeof(void*), "tycho ABI: vkGetPhysicalDeviceSparseImageFormatProperties2KHR physicalDevice wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetPhysicalDeviceSparseImageFormatProperties2KHR(void *h) { return tycho_vk_gpa((VkInstance)h, "vkGetPhysicalDeviceSparseImageFormatProperties2KHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkPhysicalDevice) <= sizeof(void*), "tycho ABI: vkGetPhysicalDeviceExternalBufferProperties physicalDevice wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetPhysicalDeviceExternalBufferProperties(void *h) { return tycho_vk_gpa((VkInstance)h, "vkGetPhysicalDeviceExternalBufferProperties"); }
TYCHO_STATIC_ASSERT(sizeof(VkPhysicalDevice) <= sizeof(void*), "tycho ABI: vkGetPhysicalDeviceExternalBufferPropertiesKHR physicalDevice wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetPhysicalDeviceExternalBufferPropertiesKHR(void *h) { return tycho_vk_gpa((VkInstance)h, "vkGetPhysicalDeviceExternalBufferPropertiesKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkPhysicalDevice) <= sizeof(void*), "tycho ABI: vkGetPhysicalDeviceExternalMemorySciBufPropertiesNV physicalDevice wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkExternalMemoryHandleTypeFlagBits) <= 4, "tycho ABI: vkGetPhysicalDeviceExternalMemorySciBufPropertiesNV handleType wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetPhysicalDeviceExternalMemorySciBufPropertiesNV(void *h) { return tycho_vk_gpa((VkInstance)h, "vkGetPhysicalDeviceExternalMemorySciBufPropertiesNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkPhysicalDevice) <= sizeof(void*), "tycho ABI: vkGetPhysicalDeviceSciBufAttributesNV physicalDevice wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetPhysicalDeviceSciBufAttributesNV(void *h) { return tycho_vk_gpa((VkInstance)h, "vkGetPhysicalDeviceSciBufAttributesNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkPhysicalDevice) <= sizeof(void*), "tycho ABI: vkGetPhysicalDeviceExternalSemaphoreProperties physicalDevice wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetPhysicalDeviceExternalSemaphoreProperties(void *h) { return tycho_vk_gpa((VkInstance)h, "vkGetPhysicalDeviceExternalSemaphoreProperties"); }
TYCHO_STATIC_ASSERT(sizeof(VkPhysicalDevice) <= sizeof(void*), "tycho ABI: vkGetPhysicalDeviceExternalSemaphorePropertiesKHR physicalDevice wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetPhysicalDeviceExternalSemaphorePropertiesKHR(void *h) { return tycho_vk_gpa((VkInstance)h, "vkGetPhysicalDeviceExternalSemaphorePropertiesKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkPhysicalDevice) <= sizeof(void*), "tycho ABI: vkGetPhysicalDeviceExternalFenceProperties physicalDevice wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetPhysicalDeviceExternalFenceProperties(void *h) { return tycho_vk_gpa((VkInstance)h, "vkGetPhysicalDeviceExternalFenceProperties"); }
TYCHO_STATIC_ASSERT(sizeof(VkPhysicalDevice) <= sizeof(void*), "tycho ABI: vkGetPhysicalDeviceExternalFencePropertiesKHR physicalDevice wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetPhysicalDeviceExternalFencePropertiesKHR(void *h) { return tycho_vk_gpa((VkInstance)h, "vkGetPhysicalDeviceExternalFencePropertiesKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkPhysicalDevice) <= sizeof(void*), "tycho ABI: vkGetPhysicalDeviceSciSyncAttributesNV physicalDevice wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetPhysicalDeviceSciSyncAttributesNV(void *h) { return tycho_vk_gpa((VkInstance)h, "vkGetPhysicalDeviceSciSyncAttributesNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkPhysicalDevice) <= sizeof(void*), "tycho ABI: vkReleaseDisplayEXT physicalDevice wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDisplayKHR) <= sizeof(void*), "tycho ABI: vkReleaseDisplayEXT display wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkReleaseDisplayEXT(void *h) { return tycho_vk_gpa((VkInstance)h, "vkReleaseDisplayEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkPhysicalDevice) <= sizeof(void*), "tycho ABI: vkAcquireXlibDisplayEXT physicalDevice wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDisplayKHR) <= sizeof(void*), "tycho ABI: vkAcquireXlibDisplayEXT display wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkAcquireXlibDisplayEXT(void *h) { return tycho_vk_gpa((VkInstance)h, "vkAcquireXlibDisplayEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkPhysicalDevice) <= sizeof(void*), "tycho ABI: vkGetRandROutputDisplayEXT physicalDevice wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetRandROutputDisplayEXT(void *h) { return tycho_vk_gpa((VkInstance)h, "vkGetRandROutputDisplayEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkPhysicalDevice) <= sizeof(void*), "tycho ABI: vkAcquireWinrtDisplayNV physicalDevice wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDisplayKHR) <= sizeof(void*), "tycho ABI: vkAcquireWinrtDisplayNV display wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkAcquireWinrtDisplayNV(void *h) { return tycho_vk_gpa((VkInstance)h, "vkAcquireWinrtDisplayNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkPhysicalDevice) <= sizeof(void*), "tycho ABI: vkGetWinrtDisplayNV physicalDevice wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkGetWinrtDisplayNV deviceRelativeId wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetWinrtDisplayNV(void *h) { return tycho_vk_gpa((VkInstance)h, "vkGetWinrtDisplayNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkPhysicalDevice) <= sizeof(void*), "tycho ABI: vkGetPhysicalDeviceSurfaceCapabilities2EXT physicalDevice wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkSurfaceKHR) <= sizeof(void*), "tycho ABI: vkGetPhysicalDeviceSurfaceCapabilities2EXT surface wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetPhysicalDeviceSurfaceCapabilities2EXT(void *h) { return tycho_vk_gpa((VkInstance)h, "vkGetPhysicalDeviceSurfaceCapabilities2EXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkInstance) <= sizeof(void*), "tycho ABI: vkEnumeratePhysicalDeviceGroups instance wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkEnumeratePhysicalDeviceGroups(void *h) { return tycho_vk_gpa((VkInstance)h, "vkEnumeratePhysicalDeviceGroups"); }
TYCHO_STATIC_ASSERT(sizeof(VkInstance) <= sizeof(void*), "tycho ABI: vkEnumeratePhysicalDeviceGroupsKHR instance wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkEnumeratePhysicalDeviceGroupsKHR(void *h) { return tycho_vk_gpa((VkInstance)h, "vkEnumeratePhysicalDeviceGroupsKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkPhysicalDevice) <= sizeof(void*), "tycho ABI: vkGetPhysicalDevicePresentRectanglesKHR physicalDevice wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkSurfaceKHR) <= sizeof(void*), "tycho ABI: vkGetPhysicalDevicePresentRectanglesKHR surface wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetPhysicalDevicePresentRectanglesKHR(void *h) { return tycho_vk_gpa((VkInstance)h, "vkGetPhysicalDevicePresentRectanglesKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkInstance) <= sizeof(void*), "tycho ABI: vkCreateIOSSurfaceMVK instance wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCreateIOSSurfaceMVK(void *h) { return tycho_vk_gpa((VkInstance)h, "vkCreateIOSSurfaceMVK"); }
TYCHO_STATIC_ASSERT(sizeof(VkInstance) <= sizeof(void*), "tycho ABI: vkCreateMacOSSurfaceMVK instance wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCreateMacOSSurfaceMVK(void *h) { return tycho_vk_gpa((VkInstance)h, "vkCreateMacOSSurfaceMVK"); }
TYCHO_STATIC_ASSERT(sizeof(VkInstance) <= sizeof(void*), "tycho ABI: vkCreateMetalSurfaceEXT instance wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCreateMetalSurfaceEXT(void *h) { return tycho_vk_gpa((VkInstance)h, "vkCreateMetalSurfaceEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkPhysicalDevice) <= sizeof(void*), "tycho ABI: vkGetPhysicalDeviceMultisamplePropertiesEXT physicalDevice wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkSampleCountFlagBits) <= 4, "tycho ABI: vkGetPhysicalDeviceMultisamplePropertiesEXT samples wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetPhysicalDeviceMultisamplePropertiesEXT(void *h) { return tycho_vk_gpa((VkInstance)h, "vkGetPhysicalDeviceMultisamplePropertiesEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkPhysicalDevice) <= sizeof(void*), "tycho ABI: vkGetPhysicalDeviceSurfaceCapabilities2KHR physicalDevice wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetPhysicalDeviceSurfaceCapabilities2KHR(void *h) { return tycho_vk_gpa((VkInstance)h, "vkGetPhysicalDeviceSurfaceCapabilities2KHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkPhysicalDevice) <= sizeof(void*), "tycho ABI: vkGetPhysicalDeviceSurfaceFormats2KHR physicalDevice wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetPhysicalDeviceSurfaceFormats2KHR(void *h) { return tycho_vk_gpa((VkInstance)h, "vkGetPhysicalDeviceSurfaceFormats2KHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkPhysicalDevice) <= sizeof(void*), "tycho ABI: vkGetPhysicalDeviceDisplayProperties2KHR physicalDevice wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetPhysicalDeviceDisplayProperties2KHR(void *h) { return tycho_vk_gpa((VkInstance)h, "vkGetPhysicalDeviceDisplayProperties2KHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkPhysicalDevice) <= sizeof(void*), "tycho ABI: vkGetPhysicalDeviceDisplayPlaneProperties2KHR physicalDevice wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetPhysicalDeviceDisplayPlaneProperties2KHR(void *h) { return tycho_vk_gpa((VkInstance)h, "vkGetPhysicalDeviceDisplayPlaneProperties2KHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkPhysicalDevice) <= sizeof(void*), "tycho ABI: vkGetDisplayModeProperties2KHR physicalDevice wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDisplayKHR) <= sizeof(void*), "tycho ABI: vkGetDisplayModeProperties2KHR display wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetDisplayModeProperties2KHR(void *h) { return tycho_vk_gpa((VkInstance)h, "vkGetDisplayModeProperties2KHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkPhysicalDevice) <= sizeof(void*), "tycho ABI: vkGetDisplayPlaneCapabilities2KHR physicalDevice wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetDisplayPlaneCapabilities2KHR(void *h) { return tycho_vk_gpa((VkInstance)h, "vkGetDisplayPlaneCapabilities2KHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkPhysicalDevice) <= sizeof(void*), "tycho ABI: vkGetPhysicalDeviceCalibrateableTimeDomainsKHR physicalDevice wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetPhysicalDeviceCalibrateableTimeDomainsKHR(void *h) { return tycho_vk_gpa((VkInstance)h, "vkGetPhysicalDeviceCalibrateableTimeDomainsKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkPhysicalDevice) <= sizeof(void*), "tycho ABI: vkGetPhysicalDeviceCalibrateableTimeDomainsEXT physicalDevice wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetPhysicalDeviceCalibrateableTimeDomainsEXT(void *h) { return tycho_vk_gpa((VkInstance)h, "vkGetPhysicalDeviceCalibrateableTimeDomainsEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkInstance) <= sizeof(void*), "tycho ABI: vkCreateDebugUtilsMessengerEXT instance wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCreateDebugUtilsMessengerEXT(void *h) { return tycho_vk_gpa((VkInstance)h, "vkCreateDebugUtilsMessengerEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkInstance) <= sizeof(void*), "tycho ABI: vkDestroyDebugUtilsMessengerEXT instance wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDebugUtilsMessengerEXT) <= sizeof(void*), "tycho ABI: vkDestroyDebugUtilsMessengerEXT messenger wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkDestroyDebugUtilsMessengerEXT(void *h) { return tycho_vk_gpa((VkInstance)h, "vkDestroyDebugUtilsMessengerEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkInstance) <= sizeof(void*), "tycho ABI: vkSubmitDebugUtilsMessageEXT instance wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDebugUtilsMessageSeverityFlagBitsEXT) <= 4, "tycho ABI: vkSubmitDebugUtilsMessageEXT messageSeverity wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDebugUtilsMessageTypeFlagsEXT) <= 4, "tycho ABI: vkSubmitDebugUtilsMessageEXT messageTypes wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkSubmitDebugUtilsMessageEXT(void *h) { return tycho_vk_gpa((VkInstance)h, "vkSubmitDebugUtilsMessageEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkPhysicalDevice) <= sizeof(void*), "tycho ABI: vkGetPhysicalDeviceCooperativeMatrixPropertiesNV physicalDevice wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetPhysicalDeviceCooperativeMatrixPropertiesNV(void *h) { return tycho_vk_gpa((VkInstance)h, "vkGetPhysicalDeviceCooperativeMatrixPropertiesNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkPhysicalDevice) <= sizeof(void*), "tycho ABI: vkGetPhysicalDeviceSurfacePresentModes2EXT physicalDevice wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetPhysicalDeviceSurfacePresentModes2EXT(void *h) { return tycho_vk_gpa((VkInstance)h, "vkGetPhysicalDeviceSurfacePresentModes2EXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkPhysicalDevice) <= sizeof(void*), "tycho ABI: vkEnumeratePhysicalDeviceQueueFamilyPerformanceQueryCountersKHR physicalDevice wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkEnumeratePhysicalDeviceQueueFamilyPerformanceQueryCountersKHR queueFamilyIndex wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkEnumeratePhysicalDeviceQueueFamilyPerformanceQueryCountersKHR(void *h) { return tycho_vk_gpa((VkInstance)h, "vkEnumeratePhysicalDeviceQueueFamilyPerformanceQueryCountersKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkPhysicalDevice) <= sizeof(void*), "tycho ABI: vkGetPhysicalDeviceQueueFamilyPerformanceQueryPassesKHR physicalDevice wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetPhysicalDeviceQueueFamilyPerformanceQueryPassesKHR(void *h) { return tycho_vk_gpa((VkInstance)h, "vkGetPhysicalDeviceQueueFamilyPerformanceQueryPassesKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkInstance) <= sizeof(void*), "tycho ABI: vkCreateHeadlessSurfaceEXT instance wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCreateHeadlessSurfaceEXT(void *h) { return tycho_vk_gpa((VkInstance)h, "vkCreateHeadlessSurfaceEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkPhysicalDevice) <= sizeof(void*), "tycho ABI: vkGetPhysicalDeviceSupportedFramebufferMixedSamplesCombinationsNV physicalDevice wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetPhysicalDeviceSupportedFramebufferMixedSamplesCombinationsNV(void *h) { return tycho_vk_gpa((VkInstance)h, "vkGetPhysicalDeviceSupportedFramebufferMixedSamplesCombinationsNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkPhysicalDevice) <= sizeof(void*), "tycho ABI: vkGetPhysicalDeviceToolProperties physicalDevice wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetPhysicalDeviceToolProperties(void *h) { return tycho_vk_gpa((VkInstance)h, "vkGetPhysicalDeviceToolProperties"); }
TYCHO_STATIC_ASSERT(sizeof(VkPhysicalDevice) <= sizeof(void*), "tycho ABI: vkGetPhysicalDeviceToolPropertiesEXT physicalDevice wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetPhysicalDeviceToolPropertiesEXT(void *h) { return tycho_vk_gpa((VkInstance)h, "vkGetPhysicalDeviceToolPropertiesEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkPhysicalDevice) <= sizeof(void*), "tycho ABI: vkGetPhysicalDeviceRefreshableObjectTypesKHR physicalDevice wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetPhysicalDeviceRefreshableObjectTypesKHR(void *h) { return tycho_vk_gpa((VkInstance)h, "vkGetPhysicalDeviceRefreshableObjectTypesKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkPhysicalDevice) <= sizeof(void*), "tycho ABI: vkGetPhysicalDeviceFragmentShadingRatesKHR physicalDevice wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetPhysicalDeviceFragmentShadingRatesKHR(void *h) { return tycho_vk_gpa((VkInstance)h, "vkGetPhysicalDeviceFragmentShadingRatesKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkPhysicalDevice) <= sizeof(void*), "tycho ABI: vkGetPhysicalDeviceVideoCapabilitiesKHR physicalDevice wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetPhysicalDeviceVideoCapabilitiesKHR(void *h) { return tycho_vk_gpa((VkInstance)h, "vkGetPhysicalDeviceVideoCapabilitiesKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkPhysicalDevice) <= sizeof(void*), "tycho ABI: vkGetPhysicalDeviceVideoFormatPropertiesKHR physicalDevice wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetPhysicalDeviceVideoFormatPropertiesKHR(void *h) { return tycho_vk_gpa((VkInstance)h, "vkGetPhysicalDeviceVideoFormatPropertiesKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkPhysicalDevice) <= sizeof(void*), "tycho ABI: vkGetPhysicalDeviceVideoEncodeQualityLevelPropertiesKHR physicalDevice wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetPhysicalDeviceVideoEncodeQualityLevelPropertiesKHR(void *h) { return tycho_vk_gpa((VkInstance)h, "vkGetPhysicalDeviceVideoEncodeQualityLevelPropertiesKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkPhysicalDevice) <= sizeof(void*), "tycho ABI: vkAcquireDrmDisplayEXT physicalDevice wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(int32_t) <= 4, "tycho ABI: vkAcquireDrmDisplayEXT drmFd wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDisplayKHR) <= sizeof(void*), "tycho ABI: vkAcquireDrmDisplayEXT display wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkAcquireDrmDisplayEXT(void *h) { return tycho_vk_gpa((VkInstance)h, "vkAcquireDrmDisplayEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkPhysicalDevice) <= sizeof(void*), "tycho ABI: vkGetDrmDisplayEXT physicalDevice wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(int32_t) <= 4, "tycho ABI: vkGetDrmDisplayEXT drmFd wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkGetDrmDisplayEXT connectorId wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetDrmDisplayEXT(void *h) { return tycho_vk_gpa((VkInstance)h, "vkGetDrmDisplayEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkPhysicalDevice) <= sizeof(void*), "tycho ABI: vkGetPhysicalDeviceOpticalFlowImageFormatsNV physicalDevice wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetPhysicalDeviceOpticalFlowImageFormatsNV(void *h) { return tycho_vk_gpa((VkInstance)h, "vkGetPhysicalDeviceOpticalFlowImageFormatsNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkPhysicalDevice) <= sizeof(void*), "tycho ABI: vkGetPhysicalDeviceCooperativeMatrixPropertiesKHR physicalDevice wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetPhysicalDeviceCooperativeMatrixPropertiesKHR(void *h) { return tycho_vk_gpa((VkInstance)h, "vkGetPhysicalDeviceCooperativeMatrixPropertiesKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkPhysicalDevice) <= sizeof(void*), "tycho ABI: vkGetPhysicalDeviceCooperativeMatrixProperties2EXT physicalDevice wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetPhysicalDeviceCooperativeMatrixProperties2EXT(void *h) { return tycho_vk_gpa((VkInstance)h, "vkGetPhysicalDeviceCooperativeMatrixProperties2EXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkPhysicalDevice) <= sizeof(void*), "tycho ABI: vkGetPhysicalDeviceCooperativeMatrixFlexibleDimensionsPropertiesNV physicalDevice wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetPhysicalDeviceCooperativeMatrixFlexibleDimensionsPropertiesNV(void *h) { return tycho_vk_gpa((VkInstance)h, "vkGetPhysicalDeviceCooperativeMatrixFlexibleDimensionsPropertiesNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkPhysicalDevice) <= sizeof(void*), "tycho ABI: vkGetPhysicalDeviceCooperativeVectorPropertiesNV physicalDevice wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetPhysicalDeviceCooperativeVectorPropertiesNV(void *h) { return tycho_vk_gpa((VkInstance)h, "vkGetPhysicalDeviceCooperativeVectorPropertiesNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkPhysicalDevice) <= sizeof(void*), "tycho ABI: vkEnumeratePhysicalDeviceShaderInstrumentationMetricsARM physicalDevice wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkEnumeratePhysicalDeviceShaderInstrumentationMetricsARM(void *h) { return tycho_vk_gpa((VkInstance)h, "vkEnumeratePhysicalDeviceShaderInstrumentationMetricsARM"); }
TYCHO_STATIC_ASSERT(sizeof(VkPhysicalDevice) <= sizeof(void*), "tycho ABI: vkGetPhysicalDeviceExternalTensorPropertiesARM physicalDevice wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetPhysicalDeviceExternalTensorPropertiesARM(void *h) { return tycho_vk_gpa((VkInstance)h, "vkGetPhysicalDeviceExternalTensorPropertiesARM"); }
TYCHO_STATIC_ASSERT(sizeof(VkPhysicalDevice) <= sizeof(void*), "tycho ABI: vkGetPhysicalDeviceQueueFamilyDataGraphPropertiesARM physicalDevice wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkGetPhysicalDeviceQueueFamilyDataGraphPropertiesARM queueFamilyIndex wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetPhysicalDeviceQueueFamilyDataGraphPropertiesARM(void *h) { return tycho_vk_gpa((VkInstance)h, "vkGetPhysicalDeviceQueueFamilyDataGraphPropertiesARM"); }
TYCHO_STATIC_ASSERT(sizeof(VkPhysicalDevice) <= sizeof(void*), "tycho ABI: vkGetPhysicalDeviceQueueFamilyDataGraphProcessingEnginePropertiesARM physicalDevice wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetPhysicalDeviceQueueFamilyDataGraphProcessingEnginePropertiesARM(void *h) { return tycho_vk_gpa((VkInstance)h, "vkGetPhysicalDeviceQueueFamilyDataGraphProcessingEnginePropertiesARM"); }
TYCHO_STATIC_ASSERT(sizeof(VkPhysicalDevice) <= sizeof(void*), "tycho ABI: vkEnumeratePhysicalDeviceQueueFamilyPerformanceCountersByRegionARM physicalDevice wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkEnumeratePhysicalDeviceQueueFamilyPerformanceCountersByRegionARM queueFamilyIndex wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkEnumeratePhysicalDeviceQueueFamilyPerformanceCountersByRegionARM(void *h) { return tycho_vk_gpa((VkInstance)h, "vkEnumeratePhysicalDeviceQueueFamilyPerformanceCountersByRegionARM"); }
TYCHO_STATIC_ASSERT(sizeof(VkPhysicalDevice) <= sizeof(void*), "tycho ABI: vkGetPhysicalDeviceDescriptorSizeEXT physicalDevice wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDescriptorType) <= 4, "tycho ABI: vkGetPhysicalDeviceDescriptorSizeEXT descriptorType wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetPhysicalDeviceDescriptorSizeEXT(void *h) { return tycho_vk_gpa((VkInstance)h, "vkGetPhysicalDeviceDescriptorSizeEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkPhysicalDevice) <= sizeof(void*), "tycho ABI: vkGetPhysicalDeviceQueueFamilyDataGraphEngineOperationPropertiesARM physicalDevice wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkGetPhysicalDeviceQueueFamilyDataGraphEngineOperationPropertiesARM queueFamilyIndex wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetPhysicalDeviceQueueFamilyDataGraphEngineOperationPropertiesARM(void *h) { return tycho_vk_gpa((VkInstance)h, "vkGetPhysicalDeviceQueueFamilyDataGraphEngineOperationPropertiesARM"); }
TYCHO_STATIC_ASSERT(sizeof(VkPhysicalDevice) <= sizeof(void*), "tycho ABI: vkGetPhysicalDeviceQueueFamilyDataGraphOpticalFlowImageFormatsARM physicalDevice wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkGetPhysicalDeviceQueueFamilyDataGraphOpticalFlowImageFormatsARM queueFamilyIndex wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetPhysicalDeviceQueueFamilyDataGraphOpticalFlowImageFormatsARM(void *h) { return tycho_vk_gpa((VkInstance)h, "vkGetPhysicalDeviceQueueFamilyDataGraphOpticalFlowImageFormatsARM"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkDestroyDevice device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkDestroyDevice(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkDestroyDevice"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetDeviceQueue device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkGetDeviceQueue queueFamilyIndex wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkGetDeviceQueue queueIndex wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetDeviceQueue(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetDeviceQueue"); }
TYCHO_STATIC_ASSERT(sizeof(VkQueue) <= sizeof(void*), "tycho ABI: vkQueueSubmit queue wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkQueueSubmit submitCount wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkFence) <= sizeof(void*), "tycho ABI: vkQueueSubmit fence wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkQueueSubmit(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkQueueSubmit"); }
TYCHO_STATIC_ASSERT(sizeof(VkQueue) <= sizeof(void*), "tycho ABI: vkQueueWaitIdle queue wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkQueueWaitIdle(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkQueueWaitIdle"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkDeviceWaitIdle device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkDeviceWaitIdle(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkDeviceWaitIdle"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkAllocateMemory device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkAllocateMemory(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkAllocateMemory"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkFreeMemory device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDeviceMemory) <= sizeof(void*), "tycho ABI: vkFreeMemory memory wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkFreeMemory(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkFreeMemory"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkMapMemory device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDeviceMemory) <= sizeof(void*), "tycho ABI: vkMapMemory memory wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDeviceSize) <= 8, "tycho ABI: vkMapMemory offset wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDeviceSize) <= 8, "tycho ABI: vkMapMemory size wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkMemoryMapFlags) <= 4, "tycho ABI: vkMapMemory flags wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkMapMemory(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkMapMemory"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkUnmapMemory device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDeviceMemory) <= sizeof(void*), "tycho ABI: vkUnmapMemory memory wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkUnmapMemory(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkUnmapMemory"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkFlushMappedMemoryRanges device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkFlushMappedMemoryRanges memoryRangeCount wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkFlushMappedMemoryRanges(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkFlushMappedMemoryRanges"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkInvalidateMappedMemoryRanges device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkInvalidateMappedMemoryRanges memoryRangeCount wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkInvalidateMappedMemoryRanges(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkInvalidateMappedMemoryRanges"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetDeviceMemoryCommitment device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDeviceMemory) <= sizeof(void*), "tycho ABI: vkGetDeviceMemoryCommitment memory wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetDeviceMemoryCommitment(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetDeviceMemoryCommitment"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetBufferMemoryRequirements device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkBuffer) <= sizeof(void*), "tycho ABI: vkGetBufferMemoryRequirements buffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetBufferMemoryRequirements(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetBufferMemoryRequirements"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkBindBufferMemory device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkBuffer) <= sizeof(void*), "tycho ABI: vkBindBufferMemory buffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDeviceMemory) <= sizeof(void*), "tycho ABI: vkBindBufferMemory memory wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDeviceSize) <= 8, "tycho ABI: vkBindBufferMemory memoryOffset wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkBindBufferMemory(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkBindBufferMemory"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetImageMemoryRequirements device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkImage) <= sizeof(void*), "tycho ABI: vkGetImageMemoryRequirements image wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetImageMemoryRequirements(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetImageMemoryRequirements"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkBindImageMemory device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkImage) <= sizeof(void*), "tycho ABI: vkBindImageMemory image wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDeviceMemory) <= sizeof(void*), "tycho ABI: vkBindImageMemory memory wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDeviceSize) <= 8, "tycho ABI: vkBindImageMemory memoryOffset wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkBindImageMemory(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkBindImageMemory"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetImageSparseMemoryRequirements device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkImage) <= sizeof(void*), "tycho ABI: vkGetImageSparseMemoryRequirements image wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetImageSparseMemoryRequirements(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetImageSparseMemoryRequirements"); }
TYCHO_STATIC_ASSERT(sizeof(VkQueue) <= sizeof(void*), "tycho ABI: vkQueueBindSparse queue wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkQueueBindSparse bindInfoCount wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkFence) <= sizeof(void*), "tycho ABI: vkQueueBindSparse fence wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkQueueBindSparse(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkQueueBindSparse"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkCreateFence device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCreateFence(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCreateFence"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkDestroyFence device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkFence) <= sizeof(void*), "tycho ABI: vkDestroyFence fence wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkDestroyFence(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkDestroyFence"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkResetFences device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkResetFences fenceCount wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkResetFences(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkResetFences"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetFenceStatus device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkFence) <= sizeof(void*), "tycho ABI: vkGetFenceStatus fence wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetFenceStatus(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetFenceStatus"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkWaitForFences device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkWaitForFences fenceCount wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkBool32) <= 4, "tycho ABI: vkWaitForFences waitAll wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint64_t) <= 8, "tycho ABI: vkWaitForFences timeout wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkWaitForFences(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkWaitForFences"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkCreateSemaphore device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCreateSemaphore(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCreateSemaphore"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkDestroySemaphore device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkSemaphore) <= sizeof(void*), "tycho ABI: vkDestroySemaphore semaphore wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkDestroySemaphore(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkDestroySemaphore"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkCreateEvent device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCreateEvent(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCreateEvent"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkDestroyEvent device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkEvent) <= sizeof(void*), "tycho ABI: vkDestroyEvent event wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkDestroyEvent(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkDestroyEvent"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetEventStatus device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkEvent) <= sizeof(void*), "tycho ABI: vkGetEventStatus event wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetEventStatus(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetEventStatus"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkSetEvent device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkEvent) <= sizeof(void*), "tycho ABI: vkSetEvent event wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkSetEvent(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkSetEvent"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkResetEvent device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkEvent) <= sizeof(void*), "tycho ABI: vkResetEvent event wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkResetEvent(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkResetEvent"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkCreateQueryPool device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCreateQueryPool(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCreateQueryPool"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkDestroyQueryPool device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkQueryPool) <= sizeof(void*), "tycho ABI: vkDestroyQueryPool queryPool wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkDestroyQueryPool(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkDestroyQueryPool"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetQueryPoolResults device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkQueryPool) <= sizeof(void*), "tycho ABI: vkGetQueryPoolResults queryPool wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkGetQueryPoolResults firstQuery wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkGetQueryPoolResults queryCount wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(size_t) <= 8, "tycho ABI: vkGetQueryPoolResults dataSize wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDeviceSize) <= 8, "tycho ABI: vkGetQueryPoolResults stride wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkQueryResultFlags) <= 4, "tycho ABI: vkGetQueryPoolResults flags wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetQueryPoolResults(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetQueryPoolResults"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkResetQueryPool device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkQueryPool) <= sizeof(void*), "tycho ABI: vkResetQueryPool queryPool wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkResetQueryPool firstQuery wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkResetQueryPool queryCount wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkResetQueryPool(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkResetQueryPool"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkResetQueryPoolEXT device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkQueryPool) <= sizeof(void*), "tycho ABI: vkResetQueryPoolEXT queryPool wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkResetQueryPoolEXT firstQuery wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkResetQueryPoolEXT queryCount wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkResetQueryPoolEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkResetQueryPoolEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkCreateBuffer device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCreateBuffer(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCreateBuffer"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkDestroyBuffer device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkBuffer) <= sizeof(void*), "tycho ABI: vkDestroyBuffer buffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkDestroyBuffer(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkDestroyBuffer"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkCreateBufferView device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCreateBufferView(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCreateBufferView"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkDestroyBufferView device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkBufferView) <= sizeof(void*), "tycho ABI: vkDestroyBufferView bufferView wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkDestroyBufferView(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkDestroyBufferView"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkCreateImage device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCreateImage(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCreateImage"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkDestroyImage device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkImage) <= sizeof(void*), "tycho ABI: vkDestroyImage image wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkDestroyImage(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkDestroyImage"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetImageSubresourceLayout device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkImage) <= sizeof(void*), "tycho ABI: vkGetImageSubresourceLayout image wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetImageSubresourceLayout(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetImageSubresourceLayout"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkCreateImageView device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCreateImageView(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCreateImageView"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkDestroyImageView device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkImageView) <= sizeof(void*), "tycho ABI: vkDestroyImageView imageView wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkDestroyImageView(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkDestroyImageView"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkCreateShaderModule device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCreateShaderModule(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCreateShaderModule"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkDestroyShaderModule device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkShaderModule) <= sizeof(void*), "tycho ABI: vkDestroyShaderModule shaderModule wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkDestroyShaderModule(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkDestroyShaderModule"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkCreatePipelineCache device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCreatePipelineCache(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCreatePipelineCache"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkDestroyPipelineCache device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkPipelineCache) <= sizeof(void*), "tycho ABI: vkDestroyPipelineCache pipelineCache wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkDestroyPipelineCache(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkDestroyPipelineCache"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetPipelineCacheData device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkPipelineCache) <= sizeof(void*), "tycho ABI: vkGetPipelineCacheData pipelineCache wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetPipelineCacheData(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetPipelineCacheData"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkMergePipelineCaches device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkPipelineCache) <= sizeof(void*), "tycho ABI: vkMergePipelineCaches dstCache wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkMergePipelineCaches srcCacheCount wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkMergePipelineCaches(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkMergePipelineCaches"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkCreatePipelineBinariesKHR device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCreatePipelineBinariesKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCreatePipelineBinariesKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkDestroyPipelineBinaryKHR device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkPipelineBinaryKHR) <= sizeof(void*), "tycho ABI: vkDestroyPipelineBinaryKHR pipelineBinary wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkDestroyPipelineBinaryKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkDestroyPipelineBinaryKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetPipelineKeyKHR device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetPipelineKeyKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetPipelineKeyKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetPipelineBinaryDataKHR device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetPipelineBinaryDataKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetPipelineBinaryDataKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkReleaseCapturedPipelineDataKHR device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkReleaseCapturedPipelineDataKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkReleaseCapturedPipelineDataKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkCreateGraphicsPipelines device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkPipelineCache) <= sizeof(void*), "tycho ABI: vkCreateGraphicsPipelines pipelineCache wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCreateGraphicsPipelines createInfoCount wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCreateGraphicsPipelines(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCreateGraphicsPipelines"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkCreateComputePipelines device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkPipelineCache) <= sizeof(void*), "tycho ABI: vkCreateComputePipelines pipelineCache wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCreateComputePipelines createInfoCount wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCreateComputePipelines(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCreateComputePipelines"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetDeviceSubpassShadingMaxWorkgroupSizeHUAWEI device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkRenderPass) <= sizeof(void*), "tycho ABI: vkGetDeviceSubpassShadingMaxWorkgroupSizeHUAWEI renderpass wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetDeviceSubpassShadingMaxWorkgroupSizeHUAWEI(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetDeviceSubpassShadingMaxWorkgroupSizeHUAWEI"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkDestroyPipeline device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkPipeline) <= sizeof(void*), "tycho ABI: vkDestroyPipeline pipeline wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkDestroyPipeline(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkDestroyPipeline"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkCreatePipelineLayout device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCreatePipelineLayout(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCreatePipelineLayout"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkDestroyPipelineLayout device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkPipelineLayout) <= sizeof(void*), "tycho ABI: vkDestroyPipelineLayout pipelineLayout wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkDestroyPipelineLayout(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkDestroyPipelineLayout"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkCreateSampler device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCreateSampler(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCreateSampler"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkDestroySampler device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkSampler) <= sizeof(void*), "tycho ABI: vkDestroySampler sampler wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkDestroySampler(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkDestroySampler"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkCreateDescriptorSetLayout device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCreateDescriptorSetLayout(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCreateDescriptorSetLayout"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkDestroyDescriptorSetLayout device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDescriptorSetLayout) <= sizeof(void*), "tycho ABI: vkDestroyDescriptorSetLayout descriptorSetLayout wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkDestroyDescriptorSetLayout(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkDestroyDescriptorSetLayout"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkCreateDescriptorPool device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCreateDescriptorPool(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCreateDescriptorPool"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkDestroyDescriptorPool device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDescriptorPool) <= sizeof(void*), "tycho ABI: vkDestroyDescriptorPool descriptorPool wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkDestroyDescriptorPool(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkDestroyDescriptorPool"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkResetDescriptorPool device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDescriptorPool) <= sizeof(void*), "tycho ABI: vkResetDescriptorPool descriptorPool wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDescriptorPoolResetFlags) <= 4, "tycho ABI: vkResetDescriptorPool flags wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkResetDescriptorPool(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkResetDescriptorPool"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkAllocateDescriptorSets device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkAllocateDescriptorSets(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkAllocateDescriptorSets"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkFreeDescriptorSets device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDescriptorPool) <= sizeof(void*), "tycho ABI: vkFreeDescriptorSets descriptorPool wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkFreeDescriptorSets descriptorSetCount wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkFreeDescriptorSets(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkFreeDescriptorSets"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkUpdateDescriptorSets device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkUpdateDescriptorSets descriptorWriteCount wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkUpdateDescriptorSets descriptorCopyCount wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkUpdateDescriptorSets(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkUpdateDescriptorSets"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkCreateFramebuffer device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCreateFramebuffer(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCreateFramebuffer"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkDestroyFramebuffer device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkFramebuffer) <= sizeof(void*), "tycho ABI: vkDestroyFramebuffer framebuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkDestroyFramebuffer(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkDestroyFramebuffer"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkCreateRenderPass device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCreateRenderPass(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCreateRenderPass"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkDestroyRenderPass device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkRenderPass) <= sizeof(void*), "tycho ABI: vkDestroyRenderPass renderPass wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkDestroyRenderPass(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkDestroyRenderPass"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetRenderAreaGranularity device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkRenderPass) <= sizeof(void*), "tycho ABI: vkGetRenderAreaGranularity renderPass wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetRenderAreaGranularity(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetRenderAreaGranularity"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetRenderingAreaGranularity device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetRenderingAreaGranularity(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetRenderingAreaGranularity"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetRenderingAreaGranularityKHR device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetRenderingAreaGranularityKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetRenderingAreaGranularityKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkCreateCommandPool device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCreateCommandPool(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCreateCommandPool"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkDestroyCommandPool device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkCommandPool) <= sizeof(void*), "tycho ABI: vkDestroyCommandPool commandPool wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkDestroyCommandPool(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkDestroyCommandPool"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkResetCommandPool device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkCommandPool) <= sizeof(void*), "tycho ABI: vkResetCommandPool commandPool wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkCommandPoolResetFlags) <= 4, "tycho ABI: vkResetCommandPool flags wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkResetCommandPool(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkResetCommandPool"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkAllocateCommandBuffers device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkAllocateCommandBuffers(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkAllocateCommandBuffers"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkFreeCommandBuffers device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkCommandPool) <= sizeof(void*), "tycho ABI: vkFreeCommandBuffers commandPool wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkFreeCommandBuffers commandBufferCount wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkFreeCommandBuffers(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkFreeCommandBuffers"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkBeginCommandBuffer commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkBeginCommandBuffer(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkBeginCommandBuffer"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkEndCommandBuffer commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkEndCommandBuffer(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkEndCommandBuffer"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkResetCommandBuffer commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkCommandBufferResetFlags) <= 4, "tycho ABI: vkResetCommandBuffer flags wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkResetCommandBuffer(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkResetCommandBuffer"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdBindPipeline commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkPipelineBindPoint) <= 4, "tycho ABI: vkCmdBindPipeline pipelineBindPoint wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkPipeline) <= sizeof(void*), "tycho ABI: vkCmdBindPipeline pipeline wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdBindPipeline(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdBindPipeline"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetPrimitiveRestartIndexEXT commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdSetPrimitiveRestartIndexEXT primitiveRestartIndex wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetPrimitiveRestartIndexEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetPrimitiveRestartIndexEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetAttachmentFeedbackLoopEnableEXT commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkImageAspectFlags) <= 4, "tycho ABI: vkCmdSetAttachmentFeedbackLoopEnableEXT aspectMask wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetAttachmentFeedbackLoopEnableEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetAttachmentFeedbackLoopEnableEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetViewport commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdSetViewport firstViewport wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdSetViewport viewportCount wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetViewport(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetViewport"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetScissor commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdSetScissor firstScissor wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdSetScissor scissorCount wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetScissor(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetScissor"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetLineWidth commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(float) <= 4, "tycho ABI: vkCmdSetLineWidth lineWidth wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetLineWidth(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetLineWidth"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetDepthBias commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(float) <= 4, "tycho ABI: vkCmdSetDepthBias depthBiasConstantFactor wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(float) <= 4, "tycho ABI: vkCmdSetDepthBias depthBiasClamp wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(float) <= 4, "tycho ABI: vkCmdSetDepthBias depthBiasSlopeFactor wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetDepthBias(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetDepthBias"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetBlendConstants commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetBlendConstants(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetBlendConstants"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetDepthBounds commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(float) <= 4, "tycho ABI: vkCmdSetDepthBounds minDepthBounds wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(float) <= 4, "tycho ABI: vkCmdSetDepthBounds maxDepthBounds wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetDepthBounds(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetDepthBounds"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetStencilCompareMask commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkStencilFaceFlags) <= 4, "tycho ABI: vkCmdSetStencilCompareMask faceMask wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdSetStencilCompareMask compareMask wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetStencilCompareMask(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetStencilCompareMask"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetStencilWriteMask commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkStencilFaceFlags) <= 4, "tycho ABI: vkCmdSetStencilWriteMask faceMask wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdSetStencilWriteMask writeMask wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetStencilWriteMask(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetStencilWriteMask"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetStencilReference commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkStencilFaceFlags) <= 4, "tycho ABI: vkCmdSetStencilReference faceMask wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdSetStencilReference reference wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetStencilReference(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetStencilReference"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdBindDescriptorSets commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkPipelineBindPoint) <= 4, "tycho ABI: vkCmdBindDescriptorSets pipelineBindPoint wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkPipelineLayout) <= sizeof(void*), "tycho ABI: vkCmdBindDescriptorSets layout wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdBindDescriptorSets firstSet wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdBindDescriptorSets descriptorSetCount wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdBindDescriptorSets dynamicOffsetCount wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdBindDescriptorSets(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdBindDescriptorSets"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdBindIndexBuffer commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkBuffer) <= sizeof(void*), "tycho ABI: vkCmdBindIndexBuffer buffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDeviceSize) <= 8, "tycho ABI: vkCmdBindIndexBuffer offset wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkIndexType) <= 4, "tycho ABI: vkCmdBindIndexBuffer indexType wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdBindIndexBuffer(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdBindIndexBuffer"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdBindVertexBuffers commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdBindVertexBuffers firstBinding wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdBindVertexBuffers bindingCount wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdBindVertexBuffers(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdBindVertexBuffers"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdDraw commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdDraw vertexCount wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdDraw instanceCount wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdDraw firstVertex wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdDraw firstInstance wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdDraw(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdDraw"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdDrawIndexed commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdDrawIndexed indexCount wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdDrawIndexed instanceCount wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdDrawIndexed firstIndex wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(int32_t) <= 4, "tycho ABI: vkCmdDrawIndexed vertexOffset wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdDrawIndexed firstInstance wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdDrawIndexed(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdDrawIndexed"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdDrawMultiEXT commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdDrawMultiEXT drawCount wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdDrawMultiEXT instanceCount wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdDrawMultiEXT firstInstance wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdDrawMultiEXT stride wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdDrawMultiEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdDrawMultiEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdDrawMultiIndexedEXT commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdDrawMultiIndexedEXT drawCount wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdDrawMultiIndexedEXT instanceCount wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdDrawMultiIndexedEXT firstInstance wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdDrawMultiIndexedEXT stride wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdDrawMultiIndexedEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdDrawMultiIndexedEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdDrawIndirect commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkBuffer) <= sizeof(void*), "tycho ABI: vkCmdDrawIndirect buffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDeviceSize) <= 8, "tycho ABI: vkCmdDrawIndirect offset wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdDrawIndirect drawCount wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdDrawIndirect stride wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdDrawIndirect(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdDrawIndirect"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdDrawIndexedIndirect commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkBuffer) <= sizeof(void*), "tycho ABI: vkCmdDrawIndexedIndirect buffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDeviceSize) <= 8, "tycho ABI: vkCmdDrawIndexedIndirect offset wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdDrawIndexedIndirect drawCount wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdDrawIndexedIndirect stride wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdDrawIndexedIndirect(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdDrawIndexedIndirect"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdDispatch commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdDispatch groupCountX wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdDispatch groupCountY wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdDispatch groupCountZ wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdDispatch(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdDispatch"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdDispatchIndirect commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkBuffer) <= sizeof(void*), "tycho ABI: vkCmdDispatchIndirect buffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDeviceSize) <= 8, "tycho ABI: vkCmdDispatchIndirect offset wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdDispatchIndirect(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdDispatchIndirect"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSubpassShadingHUAWEI commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSubpassShadingHUAWEI(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSubpassShadingHUAWEI"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdDrawClusterHUAWEI commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdDrawClusterHUAWEI groupCountX wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdDrawClusterHUAWEI groupCountY wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdDrawClusterHUAWEI groupCountZ wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdDrawClusterHUAWEI(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdDrawClusterHUAWEI"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdDrawClusterIndirectHUAWEI commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkBuffer) <= sizeof(void*), "tycho ABI: vkCmdDrawClusterIndirectHUAWEI buffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDeviceSize) <= 8, "tycho ABI: vkCmdDrawClusterIndirectHUAWEI offset wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdDrawClusterIndirectHUAWEI(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdDrawClusterIndirectHUAWEI"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdUpdatePipelineIndirectBufferNV commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkPipelineBindPoint) <= 4, "tycho ABI: vkCmdUpdatePipelineIndirectBufferNV pipelineBindPoint wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkPipeline) <= sizeof(void*), "tycho ABI: vkCmdUpdatePipelineIndirectBufferNV pipeline wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdUpdatePipelineIndirectBufferNV(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdUpdatePipelineIndirectBufferNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdCopyBuffer commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkBuffer) <= sizeof(void*), "tycho ABI: vkCmdCopyBuffer srcBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkBuffer) <= sizeof(void*), "tycho ABI: vkCmdCopyBuffer dstBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdCopyBuffer regionCount wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdCopyBuffer(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdCopyBuffer"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdCopyImage commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkImage) <= sizeof(void*), "tycho ABI: vkCmdCopyImage srcImage wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkImageLayout) <= 4, "tycho ABI: vkCmdCopyImage srcImageLayout wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkImage) <= sizeof(void*), "tycho ABI: vkCmdCopyImage dstImage wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkImageLayout) <= 4, "tycho ABI: vkCmdCopyImage dstImageLayout wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdCopyImage regionCount wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdCopyImage(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdCopyImage"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdBlitImage commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkImage) <= sizeof(void*), "tycho ABI: vkCmdBlitImage srcImage wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkImageLayout) <= 4, "tycho ABI: vkCmdBlitImage srcImageLayout wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkImage) <= sizeof(void*), "tycho ABI: vkCmdBlitImage dstImage wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkImageLayout) <= 4, "tycho ABI: vkCmdBlitImage dstImageLayout wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdBlitImage regionCount wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkFilter) <= 4, "tycho ABI: vkCmdBlitImage filter wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdBlitImage(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdBlitImage"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdCopyBufferToImage commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkBuffer) <= sizeof(void*), "tycho ABI: vkCmdCopyBufferToImage srcBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkImage) <= sizeof(void*), "tycho ABI: vkCmdCopyBufferToImage dstImage wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkImageLayout) <= 4, "tycho ABI: vkCmdCopyBufferToImage dstImageLayout wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdCopyBufferToImage regionCount wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdCopyBufferToImage(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdCopyBufferToImage"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdCopyImageToBuffer commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkImage) <= sizeof(void*), "tycho ABI: vkCmdCopyImageToBuffer srcImage wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkImageLayout) <= 4, "tycho ABI: vkCmdCopyImageToBuffer srcImageLayout wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkBuffer) <= sizeof(void*), "tycho ABI: vkCmdCopyImageToBuffer dstBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdCopyImageToBuffer regionCount wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdCopyImageToBuffer(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdCopyImageToBuffer"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdCopyMemoryIndirectNV commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDeviceAddress) <= 8, "tycho ABI: vkCmdCopyMemoryIndirectNV copyBufferAddress wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdCopyMemoryIndirectNV copyCount wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdCopyMemoryIndirectNV stride wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdCopyMemoryIndirectNV(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdCopyMemoryIndirectNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdCopyMemoryIndirectKHR commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdCopyMemoryIndirectKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdCopyMemoryIndirectKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdCopyMemoryToImageIndirectNV commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDeviceAddress) <= 8, "tycho ABI: vkCmdCopyMemoryToImageIndirectNV copyBufferAddress wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdCopyMemoryToImageIndirectNV copyCount wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdCopyMemoryToImageIndirectNV stride wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkImage) <= sizeof(void*), "tycho ABI: vkCmdCopyMemoryToImageIndirectNV dstImage wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkImageLayout) <= 4, "tycho ABI: vkCmdCopyMemoryToImageIndirectNV dstImageLayout wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdCopyMemoryToImageIndirectNV(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdCopyMemoryToImageIndirectNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdCopyMemoryToImageIndirectKHR commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdCopyMemoryToImageIndirectKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdCopyMemoryToImageIndirectKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdUpdateBuffer commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkBuffer) <= sizeof(void*), "tycho ABI: vkCmdUpdateBuffer dstBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDeviceSize) <= 8, "tycho ABI: vkCmdUpdateBuffer dstOffset wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDeviceSize) <= 8, "tycho ABI: vkCmdUpdateBuffer dataSize wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdUpdateBuffer(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdUpdateBuffer"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdFillBuffer commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkBuffer) <= sizeof(void*), "tycho ABI: vkCmdFillBuffer dstBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDeviceSize) <= 8, "tycho ABI: vkCmdFillBuffer dstOffset wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDeviceSize) <= 8, "tycho ABI: vkCmdFillBuffer size wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdFillBuffer data wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdFillBuffer(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdFillBuffer"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdClearColorImage commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkImage) <= sizeof(void*), "tycho ABI: vkCmdClearColorImage image wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkImageLayout) <= 4, "tycho ABI: vkCmdClearColorImage imageLayout wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdClearColorImage rangeCount wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdClearColorImage(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdClearColorImage"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdClearDepthStencilImage commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkImage) <= sizeof(void*), "tycho ABI: vkCmdClearDepthStencilImage image wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkImageLayout) <= 4, "tycho ABI: vkCmdClearDepthStencilImage imageLayout wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdClearDepthStencilImage rangeCount wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdClearDepthStencilImage(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdClearDepthStencilImage"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdClearAttachments commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdClearAttachments attachmentCount wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdClearAttachments rectCount wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdClearAttachments(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdClearAttachments"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdResolveImage commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkImage) <= sizeof(void*), "tycho ABI: vkCmdResolveImage srcImage wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkImageLayout) <= 4, "tycho ABI: vkCmdResolveImage srcImageLayout wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkImage) <= sizeof(void*), "tycho ABI: vkCmdResolveImage dstImage wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkImageLayout) <= 4, "tycho ABI: vkCmdResolveImage dstImageLayout wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdResolveImage regionCount wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdResolveImage(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdResolveImage"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetEvent commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkEvent) <= sizeof(void*), "tycho ABI: vkCmdSetEvent event wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkPipelineStageFlags) <= 4, "tycho ABI: vkCmdSetEvent stageMask wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetEvent(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetEvent"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdResetEvent commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkEvent) <= sizeof(void*), "tycho ABI: vkCmdResetEvent event wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkPipelineStageFlags) <= 4, "tycho ABI: vkCmdResetEvent stageMask wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdResetEvent(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdResetEvent"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdWaitEvents commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdWaitEvents eventCount wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkPipelineStageFlags) <= 4, "tycho ABI: vkCmdWaitEvents srcStageMask wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkPipelineStageFlags) <= 4, "tycho ABI: vkCmdWaitEvents dstStageMask wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdWaitEvents memoryBarrierCount wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdWaitEvents bufferMemoryBarrierCount wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdWaitEvents imageMemoryBarrierCount wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdWaitEvents(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdWaitEvents"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdPipelineBarrier commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkPipelineStageFlags) <= 4, "tycho ABI: vkCmdPipelineBarrier srcStageMask wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkPipelineStageFlags) <= 4, "tycho ABI: vkCmdPipelineBarrier dstStageMask wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDependencyFlags) <= 4, "tycho ABI: vkCmdPipelineBarrier dependencyFlags wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdPipelineBarrier memoryBarrierCount wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdPipelineBarrier bufferMemoryBarrierCount wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdPipelineBarrier imageMemoryBarrierCount wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdPipelineBarrier(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdPipelineBarrier"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdBeginQuery commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkQueryPool) <= sizeof(void*), "tycho ABI: vkCmdBeginQuery queryPool wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdBeginQuery query wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkQueryControlFlags) <= 4, "tycho ABI: vkCmdBeginQuery flags wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdBeginQuery(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdBeginQuery"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdEndQuery commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkQueryPool) <= sizeof(void*), "tycho ABI: vkCmdEndQuery queryPool wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdEndQuery query wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdEndQuery(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdEndQuery"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdBeginConditionalRenderingEXT commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdBeginConditionalRenderingEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdBeginConditionalRenderingEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdEndConditionalRenderingEXT commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdEndConditionalRenderingEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdEndConditionalRenderingEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdBeginCustomResolveEXT commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdBeginCustomResolveEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdBeginCustomResolveEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdResetQueryPool commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkQueryPool) <= sizeof(void*), "tycho ABI: vkCmdResetQueryPool queryPool wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdResetQueryPool firstQuery wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdResetQueryPool queryCount wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdResetQueryPool(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdResetQueryPool"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdWriteTimestamp commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkPipelineStageFlagBits) <= 4, "tycho ABI: vkCmdWriteTimestamp pipelineStage wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkQueryPool) <= sizeof(void*), "tycho ABI: vkCmdWriteTimestamp queryPool wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdWriteTimestamp query wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdWriteTimestamp(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdWriteTimestamp"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdCopyQueryPoolResults commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkQueryPool) <= sizeof(void*), "tycho ABI: vkCmdCopyQueryPoolResults queryPool wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdCopyQueryPoolResults firstQuery wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdCopyQueryPoolResults queryCount wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkBuffer) <= sizeof(void*), "tycho ABI: vkCmdCopyQueryPoolResults dstBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDeviceSize) <= 8, "tycho ABI: vkCmdCopyQueryPoolResults dstOffset wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDeviceSize) <= 8, "tycho ABI: vkCmdCopyQueryPoolResults stride wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkQueryResultFlags) <= 4, "tycho ABI: vkCmdCopyQueryPoolResults flags wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdCopyQueryPoolResults(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdCopyQueryPoolResults"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdPushConstants commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkPipelineLayout) <= sizeof(void*), "tycho ABI: vkCmdPushConstants layout wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkShaderStageFlags) <= 4, "tycho ABI: vkCmdPushConstants stageFlags wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdPushConstants offset wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdPushConstants size wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdPushConstants(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdPushConstants"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdBeginRenderPass commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkSubpassContents) <= 4, "tycho ABI: vkCmdBeginRenderPass contents wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdBeginRenderPass(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdBeginRenderPass"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdNextSubpass commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkSubpassContents) <= 4, "tycho ABI: vkCmdNextSubpass contents wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdNextSubpass(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdNextSubpass"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdEndRenderPass commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdEndRenderPass(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdEndRenderPass"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdExecuteCommands commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdExecuteCommands commandBufferCount wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdExecuteCommands(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdExecuteCommands"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkCreateSharedSwapchainsKHR device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCreateSharedSwapchainsKHR swapchainCount wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCreateSharedSwapchainsKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCreateSharedSwapchainsKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkCreateSwapchainKHR device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCreateSwapchainKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCreateSwapchainKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkDestroySwapchainKHR device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkSwapchainKHR) <= sizeof(void*), "tycho ABI: vkDestroySwapchainKHR swapchain wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkDestroySwapchainKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkDestroySwapchainKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetSwapchainImagesKHR device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkSwapchainKHR) <= sizeof(void*), "tycho ABI: vkGetSwapchainImagesKHR swapchain wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetSwapchainImagesKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetSwapchainImagesKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkAcquireNextImageKHR device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkSwapchainKHR) <= sizeof(void*), "tycho ABI: vkAcquireNextImageKHR swapchain wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint64_t) <= 8, "tycho ABI: vkAcquireNextImageKHR timeout wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkSemaphore) <= sizeof(void*), "tycho ABI: vkAcquireNextImageKHR semaphore wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkFence) <= sizeof(void*), "tycho ABI: vkAcquireNextImageKHR fence wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkAcquireNextImageKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkAcquireNextImageKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkQueue) <= sizeof(void*), "tycho ABI: vkQueuePresentKHR queue wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkQueuePresentKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkQueuePresentKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkDebugMarkerSetObjectNameEXT device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkDebugMarkerSetObjectNameEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkDebugMarkerSetObjectNameEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkDebugMarkerSetObjectTagEXT device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkDebugMarkerSetObjectTagEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkDebugMarkerSetObjectTagEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdDebugMarkerBeginEXT commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdDebugMarkerBeginEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdDebugMarkerBeginEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdDebugMarkerEndEXT commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdDebugMarkerEndEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdDebugMarkerEndEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdDebugMarkerInsertEXT commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdDebugMarkerInsertEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdDebugMarkerInsertEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetMemoryWin32HandleNV device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDeviceMemory) <= sizeof(void*), "tycho ABI: vkGetMemoryWin32HandleNV memory wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkExternalMemoryHandleTypeFlagsNV) <= 4, "tycho ABI: vkGetMemoryWin32HandleNV handleType wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetMemoryWin32HandleNV(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetMemoryWin32HandleNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdExecuteGeneratedCommandsNV commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkBool32) <= 4, "tycho ABI: vkCmdExecuteGeneratedCommandsNV isPreprocessed wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdExecuteGeneratedCommandsNV(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdExecuteGeneratedCommandsNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdPreprocessGeneratedCommandsNV commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdPreprocessGeneratedCommandsNV(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdPreprocessGeneratedCommandsNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdBindPipelineShaderGroupNV commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkPipelineBindPoint) <= 4, "tycho ABI: vkCmdBindPipelineShaderGroupNV pipelineBindPoint wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkPipeline) <= sizeof(void*), "tycho ABI: vkCmdBindPipelineShaderGroupNV pipeline wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdBindPipelineShaderGroupNV groupIndex wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdBindPipelineShaderGroupNV(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdBindPipelineShaderGroupNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetGeneratedCommandsMemoryRequirementsNV device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetGeneratedCommandsMemoryRequirementsNV(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetGeneratedCommandsMemoryRequirementsNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkCreateIndirectCommandsLayoutNV device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCreateIndirectCommandsLayoutNV(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCreateIndirectCommandsLayoutNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkDestroyIndirectCommandsLayoutNV device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkIndirectCommandsLayoutNV) <= sizeof(void*), "tycho ABI: vkDestroyIndirectCommandsLayoutNV indirectCommandsLayout wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkDestroyIndirectCommandsLayoutNV(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkDestroyIndirectCommandsLayoutNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdExecuteGeneratedCommandsEXT commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkBool32) <= 4, "tycho ABI: vkCmdExecuteGeneratedCommandsEXT isPreprocessed wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdExecuteGeneratedCommandsEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdExecuteGeneratedCommandsEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdPreprocessGeneratedCommandsEXT commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdPreprocessGeneratedCommandsEXT stateCommandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdPreprocessGeneratedCommandsEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdPreprocessGeneratedCommandsEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetGeneratedCommandsMemoryRequirementsEXT device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetGeneratedCommandsMemoryRequirementsEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetGeneratedCommandsMemoryRequirementsEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkCreateIndirectCommandsLayoutEXT device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCreateIndirectCommandsLayoutEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCreateIndirectCommandsLayoutEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkDestroyIndirectCommandsLayoutEXT device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkIndirectCommandsLayoutEXT) <= sizeof(void*), "tycho ABI: vkDestroyIndirectCommandsLayoutEXT indirectCommandsLayout wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkDestroyIndirectCommandsLayoutEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkDestroyIndirectCommandsLayoutEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkCreateIndirectExecutionSetEXT device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCreateIndirectExecutionSetEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCreateIndirectExecutionSetEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkDestroyIndirectExecutionSetEXT device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkIndirectExecutionSetEXT) <= sizeof(void*), "tycho ABI: vkDestroyIndirectExecutionSetEXT indirectExecutionSet wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkDestroyIndirectExecutionSetEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkDestroyIndirectExecutionSetEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkUpdateIndirectExecutionSetPipelineEXT device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkIndirectExecutionSetEXT) <= sizeof(void*), "tycho ABI: vkUpdateIndirectExecutionSetPipelineEXT indirectExecutionSet wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkUpdateIndirectExecutionSetPipelineEXT executionSetWriteCount wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkUpdateIndirectExecutionSetPipelineEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkUpdateIndirectExecutionSetPipelineEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkUpdateIndirectExecutionSetShaderEXT device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkIndirectExecutionSetEXT) <= sizeof(void*), "tycho ABI: vkUpdateIndirectExecutionSetShaderEXT indirectExecutionSet wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkUpdateIndirectExecutionSetShaderEXT executionSetWriteCount wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkUpdateIndirectExecutionSetShaderEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkUpdateIndirectExecutionSetShaderEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdPushDescriptorSet commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkPipelineBindPoint) <= 4, "tycho ABI: vkCmdPushDescriptorSet pipelineBindPoint wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkPipelineLayout) <= sizeof(void*), "tycho ABI: vkCmdPushDescriptorSet layout wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdPushDescriptorSet set wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdPushDescriptorSet descriptorWriteCount wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdPushDescriptorSet(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdPushDescriptorSet"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdPushDescriptorSetKHR commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkPipelineBindPoint) <= 4, "tycho ABI: vkCmdPushDescriptorSetKHR pipelineBindPoint wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkPipelineLayout) <= sizeof(void*), "tycho ABI: vkCmdPushDescriptorSetKHR layout wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdPushDescriptorSetKHR set wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdPushDescriptorSetKHR descriptorWriteCount wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdPushDescriptorSetKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdPushDescriptorSetKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkTrimCommandPool device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkCommandPool) <= sizeof(void*), "tycho ABI: vkTrimCommandPool commandPool wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkCommandPoolTrimFlags) <= 4, "tycho ABI: vkTrimCommandPool flags wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkTrimCommandPool(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkTrimCommandPool"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkTrimCommandPoolKHR device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkCommandPool) <= sizeof(void*), "tycho ABI: vkTrimCommandPoolKHR commandPool wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkCommandPoolTrimFlags) <= 4, "tycho ABI: vkTrimCommandPoolKHR flags wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkTrimCommandPoolKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkTrimCommandPoolKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetMemoryWin32HandleKHR device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetMemoryWin32HandleKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetMemoryWin32HandleKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetMemoryWin32HandlePropertiesKHR device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkExternalMemoryHandleTypeFlagBits) <= 4, "tycho ABI: vkGetMemoryWin32HandlePropertiesKHR handleType wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetMemoryWin32HandlePropertiesKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetMemoryWin32HandlePropertiesKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetMemoryFdKHR device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetMemoryFdKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetMemoryFdKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetMemoryFdPropertiesKHR device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkExternalMemoryHandleTypeFlagBits) <= 4, "tycho ABI: vkGetMemoryFdPropertiesKHR handleType wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(int) <= 4, "tycho ABI: vkGetMemoryFdPropertiesKHR fd wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetMemoryFdPropertiesKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetMemoryFdPropertiesKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetMemoryZirconHandleFUCHSIA device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetMemoryZirconHandleFUCHSIA(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetMemoryZirconHandleFUCHSIA"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetMemoryZirconHandlePropertiesFUCHSIA device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkExternalMemoryHandleTypeFlagBits) <= 4, "tycho ABI: vkGetMemoryZirconHandlePropertiesFUCHSIA handleType wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetMemoryZirconHandlePropertiesFUCHSIA(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetMemoryZirconHandlePropertiesFUCHSIA"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetMemoryRemoteAddressNV device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetMemoryRemoteAddressNV(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetMemoryRemoteAddressNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetMemorySciBufNV device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetMemorySciBufNV(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetMemorySciBufNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetSemaphoreWin32HandleKHR device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetSemaphoreWin32HandleKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetSemaphoreWin32HandleKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkImportSemaphoreWin32HandleKHR device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkImportSemaphoreWin32HandleKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkImportSemaphoreWin32HandleKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetSemaphoreFdKHR device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetSemaphoreFdKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetSemaphoreFdKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkImportSemaphoreFdKHR device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkImportSemaphoreFdKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkImportSemaphoreFdKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetSemaphoreZirconHandleFUCHSIA device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetSemaphoreZirconHandleFUCHSIA(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetSemaphoreZirconHandleFUCHSIA"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkImportSemaphoreZirconHandleFUCHSIA device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkImportSemaphoreZirconHandleFUCHSIA(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkImportSemaphoreZirconHandleFUCHSIA"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetFenceWin32HandleKHR device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetFenceWin32HandleKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetFenceWin32HandleKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkImportFenceWin32HandleKHR device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkImportFenceWin32HandleKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkImportFenceWin32HandleKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetFenceFdKHR device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetFenceFdKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetFenceFdKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkImportFenceFdKHR device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkImportFenceFdKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkImportFenceFdKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetFenceSciSyncFenceNV device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetFenceSciSyncFenceNV(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetFenceSciSyncFenceNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetFenceSciSyncObjNV device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetFenceSciSyncObjNV(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetFenceSciSyncObjNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkImportFenceSciSyncFenceNV device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkImportFenceSciSyncFenceNV(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkImportFenceSciSyncFenceNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkImportFenceSciSyncObjNV device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkImportFenceSciSyncObjNV(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkImportFenceSciSyncObjNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetSemaphoreSciSyncObjNV device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetSemaphoreSciSyncObjNV(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetSemaphoreSciSyncObjNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkImportSemaphoreSciSyncObjNV device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkImportSemaphoreSciSyncObjNV(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkImportSemaphoreSciSyncObjNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkCreateSemaphoreSciSyncPoolNV device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCreateSemaphoreSciSyncPoolNV(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCreateSemaphoreSciSyncPoolNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkDestroySemaphoreSciSyncPoolNV device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkDestroySemaphoreSciSyncPoolNV(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkDestroySemaphoreSciSyncPoolNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkDisplayPowerControlEXT device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDisplayKHR) <= sizeof(void*), "tycho ABI: vkDisplayPowerControlEXT display wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkDisplayPowerControlEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkDisplayPowerControlEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkRegisterDeviceEventEXT device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkRegisterDeviceEventEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkRegisterDeviceEventEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkRegisterDisplayEventEXT device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDisplayKHR) <= sizeof(void*), "tycho ABI: vkRegisterDisplayEventEXT display wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkRegisterDisplayEventEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkRegisterDisplayEventEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetSwapchainCounterEXT device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkSwapchainKHR) <= sizeof(void*), "tycho ABI: vkGetSwapchainCounterEXT swapchain wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkSurfaceCounterFlagBitsEXT) <= 4, "tycho ABI: vkGetSwapchainCounterEXT counter wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetSwapchainCounterEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetSwapchainCounterEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetDeviceGroupPeerMemoryFeatures device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkGetDeviceGroupPeerMemoryFeatures heapIndex wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkGetDeviceGroupPeerMemoryFeatures localDeviceIndex wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkGetDeviceGroupPeerMemoryFeatures remoteDeviceIndex wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetDeviceGroupPeerMemoryFeatures(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetDeviceGroupPeerMemoryFeatures"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetDeviceGroupPeerMemoryFeaturesKHR device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkGetDeviceGroupPeerMemoryFeaturesKHR heapIndex wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkGetDeviceGroupPeerMemoryFeaturesKHR localDeviceIndex wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkGetDeviceGroupPeerMemoryFeaturesKHR remoteDeviceIndex wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetDeviceGroupPeerMemoryFeaturesKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetDeviceGroupPeerMemoryFeaturesKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkBindBufferMemory2 device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkBindBufferMemory2 bindInfoCount wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkBindBufferMemory2(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkBindBufferMemory2"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkBindBufferMemory2KHR device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkBindBufferMemory2KHR bindInfoCount wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkBindBufferMemory2KHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkBindBufferMemory2KHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkBindImageMemory2 device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkBindImageMemory2 bindInfoCount wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkBindImageMemory2(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkBindImageMemory2"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkBindImageMemory2KHR device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkBindImageMemory2KHR bindInfoCount wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkBindImageMemory2KHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkBindImageMemory2KHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetDeviceMask commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdSetDeviceMask deviceMask wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetDeviceMask(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetDeviceMask"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetDeviceMaskKHR commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdSetDeviceMaskKHR deviceMask wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetDeviceMaskKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetDeviceMaskKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetDeviceGroupPresentCapabilitiesKHR device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetDeviceGroupPresentCapabilitiesKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetDeviceGroupPresentCapabilitiesKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetDeviceGroupSurfacePresentModesKHR device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkSurfaceKHR) <= sizeof(void*), "tycho ABI: vkGetDeviceGroupSurfacePresentModesKHR surface wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetDeviceGroupSurfacePresentModesKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetDeviceGroupSurfacePresentModesKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkAcquireNextImage2KHR device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkAcquireNextImage2KHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkAcquireNextImage2KHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdDispatchBase commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdDispatchBase baseGroupX wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdDispatchBase baseGroupY wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdDispatchBase baseGroupZ wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdDispatchBase groupCountX wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdDispatchBase groupCountY wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdDispatchBase groupCountZ wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdDispatchBase(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdDispatchBase"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdDispatchBaseKHR commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdDispatchBaseKHR baseGroupX wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdDispatchBaseKHR baseGroupY wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdDispatchBaseKHR baseGroupZ wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdDispatchBaseKHR groupCountX wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdDispatchBaseKHR groupCountY wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdDispatchBaseKHR groupCountZ wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdDispatchBaseKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdDispatchBaseKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkCreateDescriptorUpdateTemplate device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCreateDescriptorUpdateTemplate(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCreateDescriptorUpdateTemplate"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkCreateDescriptorUpdateTemplateKHR device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCreateDescriptorUpdateTemplateKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCreateDescriptorUpdateTemplateKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkDestroyDescriptorUpdateTemplate device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDescriptorUpdateTemplate) <= sizeof(void*), "tycho ABI: vkDestroyDescriptorUpdateTemplate descriptorUpdateTemplate wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkDestroyDescriptorUpdateTemplate(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkDestroyDescriptorUpdateTemplate"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkDestroyDescriptorUpdateTemplateKHR device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDescriptorUpdateTemplate) <= sizeof(void*), "tycho ABI: vkDestroyDescriptorUpdateTemplateKHR descriptorUpdateTemplate wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkDestroyDescriptorUpdateTemplateKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkDestroyDescriptorUpdateTemplateKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkUpdateDescriptorSetWithTemplate device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDescriptorSet) <= sizeof(void*), "tycho ABI: vkUpdateDescriptorSetWithTemplate descriptorSet wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDescriptorUpdateTemplate) <= sizeof(void*), "tycho ABI: vkUpdateDescriptorSetWithTemplate descriptorUpdateTemplate wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkUpdateDescriptorSetWithTemplate(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkUpdateDescriptorSetWithTemplate"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkUpdateDescriptorSetWithTemplateKHR device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDescriptorSet) <= sizeof(void*), "tycho ABI: vkUpdateDescriptorSetWithTemplateKHR descriptorSet wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDescriptorUpdateTemplate) <= sizeof(void*), "tycho ABI: vkUpdateDescriptorSetWithTemplateKHR descriptorUpdateTemplate wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkUpdateDescriptorSetWithTemplateKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkUpdateDescriptorSetWithTemplateKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdPushDescriptorSetWithTemplate commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDescriptorUpdateTemplate) <= sizeof(void*), "tycho ABI: vkCmdPushDescriptorSetWithTemplate descriptorUpdateTemplate wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkPipelineLayout) <= sizeof(void*), "tycho ABI: vkCmdPushDescriptorSetWithTemplate layout wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdPushDescriptorSetWithTemplate set wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdPushDescriptorSetWithTemplate(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdPushDescriptorSetWithTemplate"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdPushDescriptorSetWithTemplateKHR commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDescriptorUpdateTemplate) <= sizeof(void*), "tycho ABI: vkCmdPushDescriptorSetWithTemplateKHR descriptorUpdateTemplate wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkPipelineLayout) <= sizeof(void*), "tycho ABI: vkCmdPushDescriptorSetWithTemplateKHR layout wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdPushDescriptorSetWithTemplateKHR set wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdPushDescriptorSetWithTemplateKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdPushDescriptorSetWithTemplateKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkSetHdrMetadataEXT device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkSetHdrMetadataEXT swapchainCount wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkSetHdrMetadataEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkSetHdrMetadataEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetSwapchainStatusKHR device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkSwapchainKHR) <= sizeof(void*), "tycho ABI: vkGetSwapchainStatusKHR swapchain wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetSwapchainStatusKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetSwapchainStatusKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetRefreshCycleDurationGOOGLE device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkSwapchainKHR) <= sizeof(void*), "tycho ABI: vkGetRefreshCycleDurationGOOGLE swapchain wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetRefreshCycleDurationGOOGLE(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetRefreshCycleDurationGOOGLE"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetPastPresentationTimingGOOGLE device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkSwapchainKHR) <= sizeof(void*), "tycho ABI: vkGetPastPresentationTimingGOOGLE swapchain wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetPastPresentationTimingGOOGLE(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetPastPresentationTimingGOOGLE"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetViewportWScalingNV commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdSetViewportWScalingNV firstViewport wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdSetViewportWScalingNV viewportCount wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetViewportWScalingNV(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetViewportWScalingNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetDiscardRectangleEXT commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdSetDiscardRectangleEXT firstDiscardRectangle wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdSetDiscardRectangleEXT discardRectangleCount wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetDiscardRectangleEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetDiscardRectangleEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetDiscardRectangleEnableEXT commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkBool32) <= 4, "tycho ABI: vkCmdSetDiscardRectangleEnableEXT discardRectangleEnable wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetDiscardRectangleEnableEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetDiscardRectangleEnableEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetDiscardRectangleModeEXT commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDiscardRectangleModeEXT) <= 4, "tycho ABI: vkCmdSetDiscardRectangleModeEXT discardRectangleMode wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetDiscardRectangleModeEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetDiscardRectangleModeEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetSampleLocationsEXT commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetSampleLocationsEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetSampleLocationsEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetBufferMemoryRequirements2 device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetBufferMemoryRequirements2(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetBufferMemoryRequirements2"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetBufferMemoryRequirements2KHR device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetBufferMemoryRequirements2KHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetBufferMemoryRequirements2KHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetImageMemoryRequirements2 device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetImageMemoryRequirements2(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetImageMemoryRequirements2"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetImageMemoryRequirements2KHR device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetImageMemoryRequirements2KHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetImageMemoryRequirements2KHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetImageSparseMemoryRequirements2 device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetImageSparseMemoryRequirements2(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetImageSparseMemoryRequirements2"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetImageSparseMemoryRequirements2KHR device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetImageSparseMemoryRequirements2KHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetImageSparseMemoryRequirements2KHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetDeviceBufferMemoryRequirements device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetDeviceBufferMemoryRequirements(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetDeviceBufferMemoryRequirements"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetDeviceBufferMemoryRequirementsKHR device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetDeviceBufferMemoryRequirementsKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetDeviceBufferMemoryRequirementsKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetDeviceImageMemoryRequirements device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetDeviceImageMemoryRequirements(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetDeviceImageMemoryRequirements"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetDeviceImageMemoryRequirementsKHR device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetDeviceImageMemoryRequirementsKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetDeviceImageMemoryRequirementsKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetDeviceImageSparseMemoryRequirements device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetDeviceImageSparseMemoryRequirements(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetDeviceImageSparseMemoryRequirements"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetDeviceImageSparseMemoryRequirementsKHR device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetDeviceImageSparseMemoryRequirementsKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetDeviceImageSparseMemoryRequirementsKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkCreateSamplerYcbcrConversion device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCreateSamplerYcbcrConversion(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCreateSamplerYcbcrConversion"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkCreateSamplerYcbcrConversionKHR device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCreateSamplerYcbcrConversionKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCreateSamplerYcbcrConversionKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkDestroySamplerYcbcrConversion device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkSamplerYcbcrConversion) <= sizeof(void*), "tycho ABI: vkDestroySamplerYcbcrConversion ycbcrConversion wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkDestroySamplerYcbcrConversion(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkDestroySamplerYcbcrConversion"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkDestroySamplerYcbcrConversionKHR device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkSamplerYcbcrConversion) <= sizeof(void*), "tycho ABI: vkDestroySamplerYcbcrConversionKHR ycbcrConversion wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkDestroySamplerYcbcrConversionKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkDestroySamplerYcbcrConversionKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetDeviceQueue2 device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetDeviceQueue2(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetDeviceQueue2"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkCreateValidationCacheEXT device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCreateValidationCacheEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCreateValidationCacheEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkDestroyValidationCacheEXT device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkValidationCacheEXT) <= sizeof(void*), "tycho ABI: vkDestroyValidationCacheEXT validationCache wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkDestroyValidationCacheEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkDestroyValidationCacheEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetValidationCacheDataEXT device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkValidationCacheEXT) <= sizeof(void*), "tycho ABI: vkGetValidationCacheDataEXT validationCache wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetValidationCacheDataEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetValidationCacheDataEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkMergeValidationCachesEXT device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkValidationCacheEXT) <= sizeof(void*), "tycho ABI: vkMergeValidationCachesEXT dstCache wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkMergeValidationCachesEXT srcCacheCount wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkMergeValidationCachesEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkMergeValidationCachesEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetDescriptorSetLayoutSupport device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetDescriptorSetLayoutSupport(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetDescriptorSetLayoutSupport"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetDescriptorSetLayoutSupportKHR device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetDescriptorSetLayoutSupportKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetDescriptorSetLayoutSupportKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetSwapchainGrallocUsageANDROID device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkFormat) <= 4, "tycho ABI: vkGetSwapchainGrallocUsageANDROID format wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkImageUsageFlags) <= 4, "tycho ABI: vkGetSwapchainGrallocUsageANDROID imageUsage wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetSwapchainGrallocUsageANDROID(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetSwapchainGrallocUsageANDROID"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetSwapchainGrallocUsage2ANDROID device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkFormat) <= 4, "tycho ABI: vkGetSwapchainGrallocUsage2ANDROID format wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkImageUsageFlags) <= 4, "tycho ABI: vkGetSwapchainGrallocUsage2ANDROID imageUsage wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetSwapchainGrallocUsage2ANDROID(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetSwapchainGrallocUsage2ANDROID"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkAcquireImageANDROID device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkImage) <= sizeof(void*), "tycho ABI: vkAcquireImageANDROID image wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(int) <= 4, "tycho ABI: vkAcquireImageANDROID nativeFenceFd wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkSemaphore) <= sizeof(void*), "tycho ABI: vkAcquireImageANDROID semaphore wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkFence) <= sizeof(void*), "tycho ABI: vkAcquireImageANDROID fence wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkAcquireImageANDROID(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkAcquireImageANDROID"); }
TYCHO_STATIC_ASSERT(sizeof(VkQueue) <= sizeof(void*), "tycho ABI: vkQueueSignalReleaseImageANDROID queue wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkQueueSignalReleaseImageANDROID waitSemaphoreCount wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkImage) <= sizeof(void*), "tycho ABI: vkQueueSignalReleaseImageANDROID image wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkQueueSignalReleaseImageANDROID(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkQueueSignalReleaseImageANDROID"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetShaderInfoAMD device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkPipeline) <= sizeof(void*), "tycho ABI: vkGetShaderInfoAMD pipeline wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkShaderStageFlagBits) <= 4, "tycho ABI: vkGetShaderInfoAMD shaderStage wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkShaderInfoTypeAMD) <= 4, "tycho ABI: vkGetShaderInfoAMD infoType wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetShaderInfoAMD(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetShaderInfoAMD"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkSetLocalDimmingAMD device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkSwapchainKHR) <= sizeof(void*), "tycho ABI: vkSetLocalDimmingAMD swapChain wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkBool32) <= 4, "tycho ABI: vkSetLocalDimmingAMD localDimmingEnable wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkSetLocalDimmingAMD(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkSetLocalDimmingAMD"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetCalibratedTimestampsKHR device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkGetCalibratedTimestampsKHR timestampCount wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetCalibratedTimestampsKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetCalibratedTimestampsKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetCalibratedTimestampsEXT device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkGetCalibratedTimestampsEXT timestampCount wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetCalibratedTimestampsEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetCalibratedTimestampsEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkSetDebugUtilsObjectNameEXT device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkSetDebugUtilsObjectNameEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkSetDebugUtilsObjectNameEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkSetDebugUtilsObjectTagEXT device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkSetDebugUtilsObjectTagEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkSetDebugUtilsObjectTagEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkQueue) <= sizeof(void*), "tycho ABI: vkQueueBeginDebugUtilsLabelEXT queue wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkQueueBeginDebugUtilsLabelEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkQueueBeginDebugUtilsLabelEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkQueue) <= sizeof(void*), "tycho ABI: vkQueueEndDebugUtilsLabelEXT queue wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkQueueEndDebugUtilsLabelEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkQueueEndDebugUtilsLabelEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkQueue) <= sizeof(void*), "tycho ABI: vkQueueInsertDebugUtilsLabelEXT queue wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkQueueInsertDebugUtilsLabelEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkQueueInsertDebugUtilsLabelEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdBeginDebugUtilsLabelEXT commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdBeginDebugUtilsLabelEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdBeginDebugUtilsLabelEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdEndDebugUtilsLabelEXT commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdEndDebugUtilsLabelEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdEndDebugUtilsLabelEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdInsertDebugUtilsLabelEXT commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdInsertDebugUtilsLabelEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdInsertDebugUtilsLabelEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetMemoryHostPointerPropertiesEXT device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkExternalMemoryHandleTypeFlagBits) <= 4, "tycho ABI: vkGetMemoryHostPointerPropertiesEXT handleType wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetMemoryHostPointerPropertiesEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetMemoryHostPointerPropertiesEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdWriteBufferMarkerAMD commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkPipelineStageFlagBits) <= 4, "tycho ABI: vkCmdWriteBufferMarkerAMD pipelineStage wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkBuffer) <= sizeof(void*), "tycho ABI: vkCmdWriteBufferMarkerAMD dstBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDeviceSize) <= 8, "tycho ABI: vkCmdWriteBufferMarkerAMD dstOffset wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdWriteBufferMarkerAMD marker wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdWriteBufferMarkerAMD(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdWriteBufferMarkerAMD"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkCreateRenderPass2 device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCreateRenderPass2(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCreateRenderPass2"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkCreateRenderPass2KHR device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCreateRenderPass2KHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCreateRenderPass2KHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdBeginRenderPass2 commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdBeginRenderPass2(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdBeginRenderPass2"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdBeginRenderPass2KHR commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdBeginRenderPass2KHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdBeginRenderPass2KHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdNextSubpass2 commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdNextSubpass2(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdNextSubpass2"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdNextSubpass2KHR commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdNextSubpass2KHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdNextSubpass2KHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdEndRenderPass2 commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdEndRenderPass2(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdEndRenderPass2"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdEndRenderPass2KHR commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdEndRenderPass2KHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdEndRenderPass2KHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetSemaphoreCounterValue device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkSemaphore) <= sizeof(void*), "tycho ABI: vkGetSemaphoreCounterValue semaphore wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetSemaphoreCounterValue(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetSemaphoreCounterValue"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetSemaphoreCounterValueKHR device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkSemaphore) <= sizeof(void*), "tycho ABI: vkGetSemaphoreCounterValueKHR semaphore wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetSemaphoreCounterValueKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetSemaphoreCounterValueKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkWaitSemaphores device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint64_t) <= 8, "tycho ABI: vkWaitSemaphores timeout wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkWaitSemaphores(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkWaitSemaphores"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkWaitSemaphoresKHR device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint64_t) <= 8, "tycho ABI: vkWaitSemaphoresKHR timeout wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkWaitSemaphoresKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkWaitSemaphoresKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkSignalSemaphore device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkSignalSemaphore(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkSignalSemaphore"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkSignalSemaphoreKHR device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkSignalSemaphoreKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkSignalSemaphoreKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetAndroidHardwareBufferPropertiesANDROID device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetAndroidHardwareBufferPropertiesANDROID(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetAndroidHardwareBufferPropertiesANDROID"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetMemoryAndroidHardwareBufferANDROID device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetMemoryAndroidHardwareBufferANDROID(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetMemoryAndroidHardwareBufferANDROID"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdDrawIndirectCount commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkBuffer) <= sizeof(void*), "tycho ABI: vkCmdDrawIndirectCount buffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDeviceSize) <= 8, "tycho ABI: vkCmdDrawIndirectCount offset wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkBuffer) <= sizeof(void*), "tycho ABI: vkCmdDrawIndirectCount countBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDeviceSize) <= 8, "tycho ABI: vkCmdDrawIndirectCount countBufferOffset wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdDrawIndirectCount maxDrawCount wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdDrawIndirectCount stride wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdDrawIndirectCount(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdDrawIndirectCount"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdDrawIndirectCountKHR commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkBuffer) <= sizeof(void*), "tycho ABI: vkCmdDrawIndirectCountKHR buffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDeviceSize) <= 8, "tycho ABI: vkCmdDrawIndirectCountKHR offset wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkBuffer) <= sizeof(void*), "tycho ABI: vkCmdDrawIndirectCountKHR countBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDeviceSize) <= 8, "tycho ABI: vkCmdDrawIndirectCountKHR countBufferOffset wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdDrawIndirectCountKHR maxDrawCount wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdDrawIndirectCountKHR stride wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdDrawIndirectCountKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdDrawIndirectCountKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdDrawIndirectCountAMD commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkBuffer) <= sizeof(void*), "tycho ABI: vkCmdDrawIndirectCountAMD buffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDeviceSize) <= 8, "tycho ABI: vkCmdDrawIndirectCountAMD offset wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkBuffer) <= sizeof(void*), "tycho ABI: vkCmdDrawIndirectCountAMD countBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDeviceSize) <= 8, "tycho ABI: vkCmdDrawIndirectCountAMD countBufferOffset wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdDrawIndirectCountAMD maxDrawCount wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdDrawIndirectCountAMD stride wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdDrawIndirectCountAMD(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdDrawIndirectCountAMD"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdDrawIndexedIndirectCount commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkBuffer) <= sizeof(void*), "tycho ABI: vkCmdDrawIndexedIndirectCount buffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDeviceSize) <= 8, "tycho ABI: vkCmdDrawIndexedIndirectCount offset wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkBuffer) <= sizeof(void*), "tycho ABI: vkCmdDrawIndexedIndirectCount countBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDeviceSize) <= 8, "tycho ABI: vkCmdDrawIndexedIndirectCount countBufferOffset wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdDrawIndexedIndirectCount maxDrawCount wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdDrawIndexedIndirectCount stride wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdDrawIndexedIndirectCount(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdDrawIndexedIndirectCount"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdDrawIndexedIndirectCountKHR commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkBuffer) <= sizeof(void*), "tycho ABI: vkCmdDrawIndexedIndirectCountKHR buffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDeviceSize) <= 8, "tycho ABI: vkCmdDrawIndexedIndirectCountKHR offset wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkBuffer) <= sizeof(void*), "tycho ABI: vkCmdDrawIndexedIndirectCountKHR countBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDeviceSize) <= 8, "tycho ABI: vkCmdDrawIndexedIndirectCountKHR countBufferOffset wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdDrawIndexedIndirectCountKHR maxDrawCount wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdDrawIndexedIndirectCountKHR stride wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdDrawIndexedIndirectCountKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdDrawIndexedIndirectCountKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdDrawIndexedIndirectCountAMD commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkBuffer) <= sizeof(void*), "tycho ABI: vkCmdDrawIndexedIndirectCountAMD buffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDeviceSize) <= 8, "tycho ABI: vkCmdDrawIndexedIndirectCountAMD offset wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkBuffer) <= sizeof(void*), "tycho ABI: vkCmdDrawIndexedIndirectCountAMD countBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDeviceSize) <= 8, "tycho ABI: vkCmdDrawIndexedIndirectCountAMD countBufferOffset wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdDrawIndexedIndirectCountAMD maxDrawCount wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdDrawIndexedIndirectCountAMD stride wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdDrawIndexedIndirectCountAMD(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdDrawIndexedIndirectCountAMD"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetCheckpointNV commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetCheckpointNV(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetCheckpointNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkQueue) <= sizeof(void*), "tycho ABI: vkGetQueueCheckpointDataNV queue wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetQueueCheckpointDataNV(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetQueueCheckpointDataNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdBindTransformFeedbackBuffersEXT commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdBindTransformFeedbackBuffersEXT firstBinding wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdBindTransformFeedbackBuffersEXT bindingCount wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdBindTransformFeedbackBuffersEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdBindTransformFeedbackBuffersEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdBeginTransformFeedbackEXT commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdBeginTransformFeedbackEXT firstCounterBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdBeginTransformFeedbackEXT counterBufferCount wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdBeginTransformFeedbackEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdBeginTransformFeedbackEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdEndTransformFeedbackEXT commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdEndTransformFeedbackEXT firstCounterBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdEndTransformFeedbackEXT counterBufferCount wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdEndTransformFeedbackEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdEndTransformFeedbackEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdBeginQueryIndexedEXT commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkQueryPool) <= sizeof(void*), "tycho ABI: vkCmdBeginQueryIndexedEXT queryPool wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdBeginQueryIndexedEXT query wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkQueryControlFlags) <= 4, "tycho ABI: vkCmdBeginQueryIndexedEXT flags wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdBeginQueryIndexedEXT index wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdBeginQueryIndexedEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdBeginQueryIndexedEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdEndQueryIndexedEXT commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkQueryPool) <= sizeof(void*), "tycho ABI: vkCmdEndQueryIndexedEXT queryPool wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdEndQueryIndexedEXT query wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdEndQueryIndexedEXT index wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdEndQueryIndexedEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdEndQueryIndexedEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdDrawIndirectByteCountEXT commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdDrawIndirectByteCountEXT instanceCount wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdDrawIndirectByteCountEXT firstInstance wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkBuffer) <= sizeof(void*), "tycho ABI: vkCmdDrawIndirectByteCountEXT counterBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDeviceSize) <= 8, "tycho ABI: vkCmdDrawIndirectByteCountEXT counterBufferOffset wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdDrawIndirectByteCountEXT counterOffset wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdDrawIndirectByteCountEXT vertexStride wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdDrawIndirectByteCountEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdDrawIndirectByteCountEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetExclusiveScissorNV commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdSetExclusiveScissorNV firstExclusiveScissor wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdSetExclusiveScissorNV exclusiveScissorCount wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetExclusiveScissorNV(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetExclusiveScissorNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetExclusiveScissorEnableNV commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdSetExclusiveScissorEnableNV firstExclusiveScissor wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdSetExclusiveScissorEnableNV exclusiveScissorCount wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetExclusiveScissorEnableNV(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetExclusiveScissorEnableNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdBindShadingRateImageNV commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkImageView) <= sizeof(void*), "tycho ABI: vkCmdBindShadingRateImageNV imageView wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkImageLayout) <= 4, "tycho ABI: vkCmdBindShadingRateImageNV imageLayout wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdBindShadingRateImageNV(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdBindShadingRateImageNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetViewportShadingRatePaletteNV commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdSetViewportShadingRatePaletteNV firstViewport wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdSetViewportShadingRatePaletteNV viewportCount wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetViewportShadingRatePaletteNV(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetViewportShadingRatePaletteNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetCoarseSampleOrderNV commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkCoarseSampleOrderTypeNV) <= 4, "tycho ABI: vkCmdSetCoarseSampleOrderNV sampleOrderType wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdSetCoarseSampleOrderNV customSampleOrderCount wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetCoarseSampleOrderNV(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetCoarseSampleOrderNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdDrawMeshTasksNV commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdDrawMeshTasksNV taskCount wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdDrawMeshTasksNV firstTask wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdDrawMeshTasksNV(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdDrawMeshTasksNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdDrawMeshTasksIndirectNV commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkBuffer) <= sizeof(void*), "tycho ABI: vkCmdDrawMeshTasksIndirectNV buffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDeviceSize) <= 8, "tycho ABI: vkCmdDrawMeshTasksIndirectNV offset wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdDrawMeshTasksIndirectNV drawCount wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdDrawMeshTasksIndirectNV stride wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdDrawMeshTasksIndirectNV(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdDrawMeshTasksIndirectNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdDrawMeshTasksIndirectCountNV commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkBuffer) <= sizeof(void*), "tycho ABI: vkCmdDrawMeshTasksIndirectCountNV buffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDeviceSize) <= 8, "tycho ABI: vkCmdDrawMeshTasksIndirectCountNV offset wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkBuffer) <= sizeof(void*), "tycho ABI: vkCmdDrawMeshTasksIndirectCountNV countBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDeviceSize) <= 8, "tycho ABI: vkCmdDrawMeshTasksIndirectCountNV countBufferOffset wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdDrawMeshTasksIndirectCountNV maxDrawCount wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdDrawMeshTasksIndirectCountNV stride wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdDrawMeshTasksIndirectCountNV(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdDrawMeshTasksIndirectCountNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdDrawMeshTasksEXT commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdDrawMeshTasksEXT groupCountX wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdDrawMeshTasksEXT groupCountY wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdDrawMeshTasksEXT groupCountZ wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdDrawMeshTasksEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdDrawMeshTasksEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdDrawMeshTasksIndirectEXT commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkBuffer) <= sizeof(void*), "tycho ABI: vkCmdDrawMeshTasksIndirectEXT buffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDeviceSize) <= 8, "tycho ABI: vkCmdDrawMeshTasksIndirectEXT offset wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdDrawMeshTasksIndirectEXT drawCount wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdDrawMeshTasksIndirectEXT stride wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdDrawMeshTasksIndirectEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdDrawMeshTasksIndirectEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdDrawMeshTasksIndirectCountEXT commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkBuffer) <= sizeof(void*), "tycho ABI: vkCmdDrawMeshTasksIndirectCountEXT buffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDeviceSize) <= 8, "tycho ABI: vkCmdDrawMeshTasksIndirectCountEXT offset wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkBuffer) <= sizeof(void*), "tycho ABI: vkCmdDrawMeshTasksIndirectCountEXT countBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDeviceSize) <= 8, "tycho ABI: vkCmdDrawMeshTasksIndirectCountEXT countBufferOffset wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdDrawMeshTasksIndirectCountEXT maxDrawCount wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdDrawMeshTasksIndirectCountEXT stride wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdDrawMeshTasksIndirectCountEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdDrawMeshTasksIndirectCountEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkCompileDeferredNV device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkPipeline) <= sizeof(void*), "tycho ABI: vkCompileDeferredNV pipeline wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCompileDeferredNV shader wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCompileDeferredNV(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCompileDeferredNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkCreateAccelerationStructureNV device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCreateAccelerationStructureNV(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCreateAccelerationStructureNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdBindInvocationMaskHUAWEI commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkImageView) <= sizeof(void*), "tycho ABI: vkCmdBindInvocationMaskHUAWEI imageView wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkImageLayout) <= 4, "tycho ABI: vkCmdBindInvocationMaskHUAWEI imageLayout wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdBindInvocationMaskHUAWEI(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdBindInvocationMaskHUAWEI"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkDestroyAccelerationStructureKHR device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkAccelerationStructureKHR) <= sizeof(void*), "tycho ABI: vkDestroyAccelerationStructureKHR accelerationStructure wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkDestroyAccelerationStructureKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkDestroyAccelerationStructureKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkDestroyAccelerationStructureNV device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkAccelerationStructureNV) <= sizeof(void*), "tycho ABI: vkDestroyAccelerationStructureNV accelerationStructure wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkDestroyAccelerationStructureNV(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkDestroyAccelerationStructureNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetAccelerationStructureMemoryRequirementsNV device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetAccelerationStructureMemoryRequirementsNV(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetAccelerationStructureMemoryRequirementsNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkBindAccelerationStructureMemoryNV device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkBindAccelerationStructureMemoryNV bindInfoCount wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkBindAccelerationStructureMemoryNV(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkBindAccelerationStructureMemoryNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdCopyAccelerationStructureNV commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkAccelerationStructureNV) <= sizeof(void*), "tycho ABI: vkCmdCopyAccelerationStructureNV dst wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkAccelerationStructureNV) <= sizeof(void*), "tycho ABI: vkCmdCopyAccelerationStructureNV src wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkCopyAccelerationStructureModeKHR) <= 4, "tycho ABI: vkCmdCopyAccelerationStructureNV mode wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdCopyAccelerationStructureNV(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdCopyAccelerationStructureNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdCopyAccelerationStructureKHR commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdCopyAccelerationStructureKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdCopyAccelerationStructureKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkCopyAccelerationStructureKHR device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDeferredOperationKHR) <= sizeof(void*), "tycho ABI: vkCopyAccelerationStructureKHR deferredOperation wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCopyAccelerationStructureKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCopyAccelerationStructureKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdCopyAccelerationStructureToMemoryKHR commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdCopyAccelerationStructureToMemoryKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdCopyAccelerationStructureToMemoryKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkCopyAccelerationStructureToMemoryKHR device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDeferredOperationKHR) <= sizeof(void*), "tycho ABI: vkCopyAccelerationStructureToMemoryKHR deferredOperation wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCopyAccelerationStructureToMemoryKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCopyAccelerationStructureToMemoryKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdCopyMemoryToAccelerationStructureKHR commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdCopyMemoryToAccelerationStructureKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdCopyMemoryToAccelerationStructureKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkCopyMemoryToAccelerationStructureKHR device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDeferredOperationKHR) <= sizeof(void*), "tycho ABI: vkCopyMemoryToAccelerationStructureKHR deferredOperation wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCopyMemoryToAccelerationStructureKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCopyMemoryToAccelerationStructureKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdWriteAccelerationStructuresPropertiesKHR commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdWriteAccelerationStructuresPropertiesKHR accelerationStructureCount wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkQueryType) <= 4, "tycho ABI: vkCmdWriteAccelerationStructuresPropertiesKHR queryType wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkQueryPool) <= sizeof(void*), "tycho ABI: vkCmdWriteAccelerationStructuresPropertiesKHR queryPool wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdWriteAccelerationStructuresPropertiesKHR firstQuery wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdWriteAccelerationStructuresPropertiesKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdWriteAccelerationStructuresPropertiesKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdWriteAccelerationStructuresPropertiesNV commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdWriteAccelerationStructuresPropertiesNV accelerationStructureCount wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkQueryType) <= 4, "tycho ABI: vkCmdWriteAccelerationStructuresPropertiesNV queryType wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkQueryPool) <= sizeof(void*), "tycho ABI: vkCmdWriteAccelerationStructuresPropertiesNV queryPool wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdWriteAccelerationStructuresPropertiesNV firstQuery wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdWriteAccelerationStructuresPropertiesNV(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdWriteAccelerationStructuresPropertiesNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdBuildAccelerationStructureNV commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkBuffer) <= sizeof(void*), "tycho ABI: vkCmdBuildAccelerationStructureNV instanceData wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDeviceSize) <= 8, "tycho ABI: vkCmdBuildAccelerationStructureNV instanceOffset wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkBool32) <= 4, "tycho ABI: vkCmdBuildAccelerationStructureNV update wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkAccelerationStructureNV) <= sizeof(void*), "tycho ABI: vkCmdBuildAccelerationStructureNV dst wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkAccelerationStructureNV) <= sizeof(void*), "tycho ABI: vkCmdBuildAccelerationStructureNV src wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkBuffer) <= sizeof(void*), "tycho ABI: vkCmdBuildAccelerationStructureNV scratch wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDeviceSize) <= 8, "tycho ABI: vkCmdBuildAccelerationStructureNV scratchOffset wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdBuildAccelerationStructureNV(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdBuildAccelerationStructureNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkWriteAccelerationStructuresPropertiesKHR device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkWriteAccelerationStructuresPropertiesKHR accelerationStructureCount wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkQueryType) <= 4, "tycho ABI: vkWriteAccelerationStructuresPropertiesKHR queryType wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(size_t) <= 8, "tycho ABI: vkWriteAccelerationStructuresPropertiesKHR dataSize wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(size_t) <= 8, "tycho ABI: vkWriteAccelerationStructuresPropertiesKHR stride wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkWriteAccelerationStructuresPropertiesKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkWriteAccelerationStructuresPropertiesKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdTraceRaysKHR commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdTraceRaysKHR width wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdTraceRaysKHR height wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdTraceRaysKHR depth wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdTraceRaysKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdTraceRaysKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdTraceRaysNV commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkBuffer) <= sizeof(void*), "tycho ABI: vkCmdTraceRaysNV raygenShaderBindingTableBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDeviceSize) <= 8, "tycho ABI: vkCmdTraceRaysNV raygenShaderBindingOffset wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkBuffer) <= sizeof(void*), "tycho ABI: vkCmdTraceRaysNV missShaderBindingTableBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDeviceSize) <= 8, "tycho ABI: vkCmdTraceRaysNV missShaderBindingOffset wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDeviceSize) <= 8, "tycho ABI: vkCmdTraceRaysNV missShaderBindingStride wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkBuffer) <= sizeof(void*), "tycho ABI: vkCmdTraceRaysNV hitShaderBindingTableBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDeviceSize) <= 8, "tycho ABI: vkCmdTraceRaysNV hitShaderBindingOffset wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDeviceSize) <= 8, "tycho ABI: vkCmdTraceRaysNV hitShaderBindingStride wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkBuffer) <= sizeof(void*), "tycho ABI: vkCmdTraceRaysNV callableShaderBindingTableBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDeviceSize) <= 8, "tycho ABI: vkCmdTraceRaysNV callableShaderBindingOffset wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDeviceSize) <= 8, "tycho ABI: vkCmdTraceRaysNV callableShaderBindingStride wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdTraceRaysNV width wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdTraceRaysNV height wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdTraceRaysNV depth wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdTraceRaysNV(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdTraceRaysNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetRayTracingShaderGroupHandlesKHR device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkPipeline) <= sizeof(void*), "tycho ABI: vkGetRayTracingShaderGroupHandlesKHR pipeline wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkGetRayTracingShaderGroupHandlesKHR firstGroup wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkGetRayTracingShaderGroupHandlesKHR groupCount wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(size_t) <= 8, "tycho ABI: vkGetRayTracingShaderGroupHandlesKHR dataSize wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetRayTracingShaderGroupHandlesKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetRayTracingShaderGroupHandlesKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetRayTracingShaderGroupHandlesNV device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkPipeline) <= sizeof(void*), "tycho ABI: vkGetRayTracingShaderGroupHandlesNV pipeline wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkGetRayTracingShaderGroupHandlesNV firstGroup wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkGetRayTracingShaderGroupHandlesNV groupCount wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(size_t) <= 8, "tycho ABI: vkGetRayTracingShaderGroupHandlesNV dataSize wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetRayTracingShaderGroupHandlesNV(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetRayTracingShaderGroupHandlesNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetRayTracingCaptureReplayShaderGroupHandlesKHR device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkPipeline) <= sizeof(void*), "tycho ABI: vkGetRayTracingCaptureReplayShaderGroupHandlesKHR pipeline wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkGetRayTracingCaptureReplayShaderGroupHandlesKHR firstGroup wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkGetRayTracingCaptureReplayShaderGroupHandlesKHR groupCount wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(size_t) <= 8, "tycho ABI: vkGetRayTracingCaptureReplayShaderGroupHandlesKHR dataSize wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetRayTracingCaptureReplayShaderGroupHandlesKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetRayTracingCaptureReplayShaderGroupHandlesKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetAccelerationStructureHandleNV device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkAccelerationStructureNV) <= sizeof(void*), "tycho ABI: vkGetAccelerationStructureHandleNV accelerationStructure wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(size_t) <= 8, "tycho ABI: vkGetAccelerationStructureHandleNV dataSize wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetAccelerationStructureHandleNV(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetAccelerationStructureHandleNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkCreateRayTracingPipelinesNV device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkPipelineCache) <= sizeof(void*), "tycho ABI: vkCreateRayTracingPipelinesNV pipelineCache wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCreateRayTracingPipelinesNV createInfoCount wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCreateRayTracingPipelinesNV(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCreateRayTracingPipelinesNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkCreateRayTracingPipelinesKHR device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDeferredOperationKHR) <= sizeof(void*), "tycho ABI: vkCreateRayTracingPipelinesKHR deferredOperation wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkPipelineCache) <= sizeof(void*), "tycho ABI: vkCreateRayTracingPipelinesKHR pipelineCache wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCreateRayTracingPipelinesKHR createInfoCount wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCreateRayTracingPipelinesKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCreateRayTracingPipelinesKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdTraceRaysIndirectKHR commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDeviceAddress) <= 8, "tycho ABI: vkCmdTraceRaysIndirectKHR indirectDeviceAddress wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdTraceRaysIndirectKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdTraceRaysIndirectKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdTraceRaysIndirect2KHR commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDeviceAddress) <= 8, "tycho ABI: vkCmdTraceRaysIndirect2KHR indirectDeviceAddress wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdTraceRaysIndirect2KHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdTraceRaysIndirect2KHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetClusterAccelerationStructureBuildSizesNV device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetClusterAccelerationStructureBuildSizesNV(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetClusterAccelerationStructureBuildSizesNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdBuildClusterAccelerationStructureIndirectNV commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdBuildClusterAccelerationStructureIndirectNV(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdBuildClusterAccelerationStructureIndirectNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetDeviceAccelerationStructureCompatibilityKHR device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetDeviceAccelerationStructureCompatibilityKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetDeviceAccelerationStructureCompatibilityKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetRayTracingShaderGroupStackSizeKHR device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkPipeline) <= sizeof(void*), "tycho ABI: vkGetRayTracingShaderGroupStackSizeKHR pipeline wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkGetRayTracingShaderGroupStackSizeKHR group wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkShaderGroupShaderKHR) <= 4, "tycho ABI: vkGetRayTracingShaderGroupStackSizeKHR groupShader wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetRayTracingShaderGroupStackSizeKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetRayTracingShaderGroupStackSizeKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetRayTracingPipelineStackSizeKHR commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdSetRayTracingPipelineStackSizeKHR pipelineStackSize wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetRayTracingPipelineStackSizeKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetRayTracingPipelineStackSizeKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetImageViewHandleNVX device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetImageViewHandleNVX(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetImageViewHandleNVX"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetImageViewHandle64NVX device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetImageViewHandle64NVX(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetImageViewHandle64NVX"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetImageViewAddressNVX device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkImageView) <= sizeof(void*), "tycho ABI: vkGetImageViewAddressNVX imageView wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetImageViewAddressNVX(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetImageViewAddressNVX"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetDeviceCombinedImageSamplerIndexNVX device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint64_t) <= 8, "tycho ABI: vkGetDeviceCombinedImageSamplerIndexNVX imageViewIndex wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint64_t) <= 8, "tycho ABI: vkGetDeviceCombinedImageSamplerIndexNVX samplerIndex wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetDeviceCombinedImageSamplerIndexNVX(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetDeviceCombinedImageSamplerIndexNVX"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetDeviceGroupSurfacePresentModes2EXT device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetDeviceGroupSurfacePresentModes2EXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetDeviceGroupSurfacePresentModes2EXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkAcquireFullScreenExclusiveModeEXT device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkSwapchainKHR) <= sizeof(void*), "tycho ABI: vkAcquireFullScreenExclusiveModeEXT swapchain wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkAcquireFullScreenExclusiveModeEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkAcquireFullScreenExclusiveModeEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkReleaseFullScreenExclusiveModeEXT device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkSwapchainKHR) <= sizeof(void*), "tycho ABI: vkReleaseFullScreenExclusiveModeEXT swapchain wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkReleaseFullScreenExclusiveModeEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkReleaseFullScreenExclusiveModeEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkAcquireProfilingLockKHR device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkAcquireProfilingLockKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkAcquireProfilingLockKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkReleaseProfilingLockKHR device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkReleaseProfilingLockKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkReleaseProfilingLockKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetImageDrmFormatModifierPropertiesEXT device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkImage) <= sizeof(void*), "tycho ABI: vkGetImageDrmFormatModifierPropertiesEXT image wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetImageDrmFormatModifierPropertiesEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetImageDrmFormatModifierPropertiesEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetBufferOpaqueCaptureAddress device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetBufferOpaqueCaptureAddress(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetBufferOpaqueCaptureAddress"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetBufferOpaqueCaptureAddressKHR device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetBufferOpaqueCaptureAddressKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetBufferOpaqueCaptureAddressKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetBufferDeviceAddress device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetBufferDeviceAddress(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetBufferDeviceAddress"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetBufferDeviceAddressKHR device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetBufferDeviceAddressKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetBufferDeviceAddressKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetBufferDeviceAddressEXT device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetBufferDeviceAddressEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetBufferDeviceAddressEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkInitializePerformanceApiINTEL device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkInitializePerformanceApiINTEL(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkInitializePerformanceApiINTEL"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkUninitializePerformanceApiINTEL device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkUninitializePerformanceApiINTEL(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkUninitializePerformanceApiINTEL"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetPerformanceMarkerINTEL commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetPerformanceMarkerINTEL(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetPerformanceMarkerINTEL"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetPerformanceStreamMarkerINTEL commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetPerformanceStreamMarkerINTEL(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetPerformanceStreamMarkerINTEL"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetPerformanceOverrideINTEL commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetPerformanceOverrideINTEL(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetPerformanceOverrideINTEL"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkAcquirePerformanceConfigurationINTEL device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkAcquirePerformanceConfigurationINTEL(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkAcquirePerformanceConfigurationINTEL"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkReleasePerformanceConfigurationINTEL device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkPerformanceConfigurationINTEL) <= sizeof(void*), "tycho ABI: vkReleasePerformanceConfigurationINTEL configuration wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkReleasePerformanceConfigurationINTEL(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkReleasePerformanceConfigurationINTEL"); }
TYCHO_STATIC_ASSERT(sizeof(VkQueue) <= sizeof(void*), "tycho ABI: vkQueueSetPerformanceConfigurationINTEL queue wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkPerformanceConfigurationINTEL) <= sizeof(void*), "tycho ABI: vkQueueSetPerformanceConfigurationINTEL configuration wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkQueueSetPerformanceConfigurationINTEL(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkQueueSetPerformanceConfigurationINTEL"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetPerformanceParameterINTEL device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkPerformanceParameterTypeINTEL) <= 4, "tycho ABI: vkGetPerformanceParameterINTEL parameter wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetPerformanceParameterINTEL(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetPerformanceParameterINTEL"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetDeviceMemoryOpaqueCaptureAddress device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetDeviceMemoryOpaqueCaptureAddress(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetDeviceMemoryOpaqueCaptureAddress"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetDeviceMemoryOpaqueCaptureAddressKHR device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetDeviceMemoryOpaqueCaptureAddressKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetDeviceMemoryOpaqueCaptureAddressKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetPipelineExecutablePropertiesKHR device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetPipelineExecutablePropertiesKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetPipelineExecutablePropertiesKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetPipelineExecutableStatisticsKHR device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetPipelineExecutableStatisticsKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetPipelineExecutableStatisticsKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetPipelineExecutableInternalRepresentationsKHR device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetPipelineExecutableInternalRepresentationsKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetPipelineExecutableInternalRepresentationsKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetLineStipple commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdSetLineStipple lineStippleFactor wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint16_t) <= 4, "tycho ABI: vkCmdSetLineStipple lineStipplePattern wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetLineStipple(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetLineStipple"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetLineStippleKHR commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdSetLineStippleKHR lineStippleFactor wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint16_t) <= 4, "tycho ABI: vkCmdSetLineStippleKHR lineStipplePattern wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetLineStippleKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetLineStippleKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetLineStippleEXT commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdSetLineStippleEXT lineStippleFactor wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint16_t) <= 4, "tycho ABI: vkCmdSetLineStippleEXT lineStipplePattern wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetLineStippleEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetLineStippleEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetFaultData device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetFaultData(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetFaultData"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkCreateAccelerationStructureKHR device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCreateAccelerationStructureKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCreateAccelerationStructureKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdBuildAccelerationStructuresKHR commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdBuildAccelerationStructuresKHR infoCount wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdBuildAccelerationStructuresKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdBuildAccelerationStructuresKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdBuildAccelerationStructuresIndirectKHR commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdBuildAccelerationStructuresIndirectKHR infoCount wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdBuildAccelerationStructuresIndirectKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdBuildAccelerationStructuresIndirectKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkBuildAccelerationStructuresKHR device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDeferredOperationKHR) <= sizeof(void*), "tycho ABI: vkBuildAccelerationStructuresKHR deferredOperation wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkBuildAccelerationStructuresKHR infoCount wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkBuildAccelerationStructuresKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkBuildAccelerationStructuresKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetAccelerationStructureDeviceAddressKHR device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetAccelerationStructureDeviceAddressKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetAccelerationStructureDeviceAddressKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkCreateDeferredOperationKHR device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCreateDeferredOperationKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCreateDeferredOperationKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkDestroyDeferredOperationKHR device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDeferredOperationKHR) <= sizeof(void*), "tycho ABI: vkDestroyDeferredOperationKHR operation wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkDestroyDeferredOperationKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkDestroyDeferredOperationKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetDeferredOperationMaxConcurrencyKHR device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDeferredOperationKHR) <= sizeof(void*), "tycho ABI: vkGetDeferredOperationMaxConcurrencyKHR operation wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetDeferredOperationMaxConcurrencyKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetDeferredOperationMaxConcurrencyKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetDeferredOperationResultKHR device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDeferredOperationKHR) <= sizeof(void*), "tycho ABI: vkGetDeferredOperationResultKHR operation wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetDeferredOperationResultKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetDeferredOperationResultKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkDeferredOperationJoinKHR device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDeferredOperationKHR) <= sizeof(void*), "tycho ABI: vkDeferredOperationJoinKHR operation wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkDeferredOperationJoinKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkDeferredOperationJoinKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetPipelineIndirectMemoryRequirementsNV device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetPipelineIndirectMemoryRequirementsNV(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetPipelineIndirectMemoryRequirementsNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetPipelineIndirectDeviceAddressNV device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetPipelineIndirectDeviceAddressNV(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetPipelineIndirectDeviceAddressNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkAntiLagUpdateAMD device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkAntiLagUpdateAMD(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkAntiLagUpdateAMD"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetCullMode commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkCullModeFlags) <= 4, "tycho ABI: vkCmdSetCullMode cullMode wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetCullMode(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetCullMode"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetCullModeEXT commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkCullModeFlags) <= 4, "tycho ABI: vkCmdSetCullModeEXT cullMode wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetCullModeEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetCullModeEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetFrontFace commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkFrontFace) <= 4, "tycho ABI: vkCmdSetFrontFace frontFace wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetFrontFace(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetFrontFace"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetFrontFaceEXT commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkFrontFace) <= 4, "tycho ABI: vkCmdSetFrontFaceEXT frontFace wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetFrontFaceEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetFrontFaceEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetPrimitiveTopology commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkPrimitiveTopology) <= 4, "tycho ABI: vkCmdSetPrimitiveTopology primitiveTopology wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetPrimitiveTopology(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetPrimitiveTopology"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetPrimitiveTopologyEXT commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkPrimitiveTopology) <= 4, "tycho ABI: vkCmdSetPrimitiveTopologyEXT primitiveTopology wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetPrimitiveTopologyEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetPrimitiveTopologyEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetViewportWithCount commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdSetViewportWithCount viewportCount wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetViewportWithCount(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetViewportWithCount"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetViewportWithCountEXT commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdSetViewportWithCountEXT viewportCount wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetViewportWithCountEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetViewportWithCountEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetScissorWithCount commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdSetScissorWithCount scissorCount wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetScissorWithCount(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetScissorWithCount"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetScissorWithCountEXT commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdSetScissorWithCountEXT scissorCount wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetScissorWithCountEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetScissorWithCountEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdBindIndexBuffer2 commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkBuffer) <= sizeof(void*), "tycho ABI: vkCmdBindIndexBuffer2 buffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDeviceSize) <= 8, "tycho ABI: vkCmdBindIndexBuffer2 offset wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDeviceSize) <= 8, "tycho ABI: vkCmdBindIndexBuffer2 size wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkIndexType) <= 4, "tycho ABI: vkCmdBindIndexBuffer2 indexType wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdBindIndexBuffer2(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdBindIndexBuffer2"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdBindIndexBuffer2KHR commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkBuffer) <= sizeof(void*), "tycho ABI: vkCmdBindIndexBuffer2KHR buffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDeviceSize) <= 8, "tycho ABI: vkCmdBindIndexBuffer2KHR offset wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDeviceSize) <= 8, "tycho ABI: vkCmdBindIndexBuffer2KHR size wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkIndexType) <= 4, "tycho ABI: vkCmdBindIndexBuffer2KHR indexType wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdBindIndexBuffer2KHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdBindIndexBuffer2KHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdBindVertexBuffers2 commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdBindVertexBuffers2 firstBinding wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdBindVertexBuffers2 bindingCount wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdBindVertexBuffers2(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdBindVertexBuffers2"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdBindVertexBuffers2EXT commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdBindVertexBuffers2EXT firstBinding wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdBindVertexBuffers2EXT bindingCount wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdBindVertexBuffers2EXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdBindVertexBuffers2EXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetDepthTestEnable commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkBool32) <= 4, "tycho ABI: vkCmdSetDepthTestEnable depthTestEnable wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetDepthTestEnable(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetDepthTestEnable"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetDepthTestEnableEXT commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkBool32) <= 4, "tycho ABI: vkCmdSetDepthTestEnableEXT depthTestEnable wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetDepthTestEnableEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetDepthTestEnableEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetDepthWriteEnable commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkBool32) <= 4, "tycho ABI: vkCmdSetDepthWriteEnable depthWriteEnable wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetDepthWriteEnable(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetDepthWriteEnable"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetDepthWriteEnableEXT commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkBool32) <= 4, "tycho ABI: vkCmdSetDepthWriteEnableEXT depthWriteEnable wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetDepthWriteEnableEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetDepthWriteEnableEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetDepthCompareOp commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkCompareOp) <= 4, "tycho ABI: vkCmdSetDepthCompareOp depthCompareOp wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetDepthCompareOp(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetDepthCompareOp"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetDepthCompareOpEXT commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkCompareOp) <= 4, "tycho ABI: vkCmdSetDepthCompareOpEXT depthCompareOp wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetDepthCompareOpEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetDepthCompareOpEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetDepthBoundsTestEnable commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkBool32) <= 4, "tycho ABI: vkCmdSetDepthBoundsTestEnable depthBoundsTestEnable wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetDepthBoundsTestEnable(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetDepthBoundsTestEnable"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetDepthBoundsTestEnableEXT commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkBool32) <= 4, "tycho ABI: vkCmdSetDepthBoundsTestEnableEXT depthBoundsTestEnable wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetDepthBoundsTestEnableEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetDepthBoundsTestEnableEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetStencilTestEnable commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkBool32) <= 4, "tycho ABI: vkCmdSetStencilTestEnable stencilTestEnable wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetStencilTestEnable(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetStencilTestEnable"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetStencilTestEnableEXT commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkBool32) <= 4, "tycho ABI: vkCmdSetStencilTestEnableEXT stencilTestEnable wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetStencilTestEnableEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetStencilTestEnableEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetStencilOp commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkStencilFaceFlags) <= 4, "tycho ABI: vkCmdSetStencilOp faceMask wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkStencilOp) <= 4, "tycho ABI: vkCmdSetStencilOp failOp wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkStencilOp) <= 4, "tycho ABI: vkCmdSetStencilOp passOp wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkStencilOp) <= 4, "tycho ABI: vkCmdSetStencilOp depthFailOp wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkCompareOp) <= 4, "tycho ABI: vkCmdSetStencilOp compareOp wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetStencilOp(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetStencilOp"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetStencilOpEXT commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkStencilFaceFlags) <= 4, "tycho ABI: vkCmdSetStencilOpEXT faceMask wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkStencilOp) <= 4, "tycho ABI: vkCmdSetStencilOpEXT failOp wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkStencilOp) <= 4, "tycho ABI: vkCmdSetStencilOpEXT passOp wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkStencilOp) <= 4, "tycho ABI: vkCmdSetStencilOpEXT depthFailOp wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkCompareOp) <= 4, "tycho ABI: vkCmdSetStencilOpEXT compareOp wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetStencilOpEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetStencilOpEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetPatchControlPointsEXT commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdSetPatchControlPointsEXT patchControlPoints wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetPatchControlPointsEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetPatchControlPointsEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetRasterizerDiscardEnable commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkBool32) <= 4, "tycho ABI: vkCmdSetRasterizerDiscardEnable rasterizerDiscardEnable wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetRasterizerDiscardEnable(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetRasterizerDiscardEnable"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetRasterizerDiscardEnableEXT commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkBool32) <= 4, "tycho ABI: vkCmdSetRasterizerDiscardEnableEXT rasterizerDiscardEnable wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetRasterizerDiscardEnableEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetRasterizerDiscardEnableEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetDepthBiasEnable commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkBool32) <= 4, "tycho ABI: vkCmdSetDepthBiasEnable depthBiasEnable wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetDepthBiasEnable(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetDepthBiasEnable"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetDepthBiasEnableEXT commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkBool32) <= 4, "tycho ABI: vkCmdSetDepthBiasEnableEXT depthBiasEnable wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetDepthBiasEnableEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetDepthBiasEnableEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetLogicOpEXT commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkLogicOp) <= 4, "tycho ABI: vkCmdSetLogicOpEXT logicOp wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetLogicOpEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetLogicOpEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetPrimitiveRestartEnable commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkBool32) <= 4, "tycho ABI: vkCmdSetPrimitiveRestartEnable primitiveRestartEnable wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetPrimitiveRestartEnable(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetPrimitiveRestartEnable"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetPrimitiveRestartEnableEXT commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkBool32) <= 4, "tycho ABI: vkCmdSetPrimitiveRestartEnableEXT primitiveRestartEnable wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetPrimitiveRestartEnableEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetPrimitiveRestartEnableEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetTessellationDomainOriginEXT commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkTessellationDomainOrigin) <= 4, "tycho ABI: vkCmdSetTessellationDomainOriginEXT domainOrigin wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetTessellationDomainOriginEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetTessellationDomainOriginEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetDepthClampEnableEXT commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkBool32) <= 4, "tycho ABI: vkCmdSetDepthClampEnableEXT depthClampEnable wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetDepthClampEnableEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetDepthClampEnableEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetPolygonModeEXT commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkPolygonMode) <= 4, "tycho ABI: vkCmdSetPolygonModeEXT polygonMode wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetPolygonModeEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetPolygonModeEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetRasterizationSamplesEXT commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkSampleCountFlagBits) <= 4, "tycho ABI: vkCmdSetRasterizationSamplesEXT rasterizationSamples wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetRasterizationSamplesEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetRasterizationSamplesEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetSampleMaskEXT commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkSampleCountFlagBits) <= 4, "tycho ABI: vkCmdSetSampleMaskEXT samples wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetSampleMaskEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetSampleMaskEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetAlphaToCoverageEnableEXT commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkBool32) <= 4, "tycho ABI: vkCmdSetAlphaToCoverageEnableEXT alphaToCoverageEnable wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetAlphaToCoverageEnableEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetAlphaToCoverageEnableEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetAlphaToOneEnableEXT commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkBool32) <= 4, "tycho ABI: vkCmdSetAlphaToOneEnableEXT alphaToOneEnable wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetAlphaToOneEnableEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetAlphaToOneEnableEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetLogicOpEnableEXT commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkBool32) <= 4, "tycho ABI: vkCmdSetLogicOpEnableEXT logicOpEnable wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetLogicOpEnableEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetLogicOpEnableEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetColorBlendEnableEXT commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdSetColorBlendEnableEXT firstAttachment wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdSetColorBlendEnableEXT attachmentCount wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetColorBlendEnableEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetColorBlendEnableEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetColorBlendEquationEXT commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdSetColorBlendEquationEXT firstAttachment wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdSetColorBlendEquationEXT attachmentCount wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetColorBlendEquationEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetColorBlendEquationEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetColorWriteMaskEXT commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdSetColorWriteMaskEXT firstAttachment wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdSetColorWriteMaskEXT attachmentCount wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetColorWriteMaskEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetColorWriteMaskEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetRasterizationStreamEXT commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdSetRasterizationStreamEXT rasterizationStream wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetRasterizationStreamEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetRasterizationStreamEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetConservativeRasterizationModeEXT commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkConservativeRasterizationModeEXT) <= 4, "tycho ABI: vkCmdSetConservativeRasterizationModeEXT conservativeRasterizationMode wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetConservativeRasterizationModeEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetConservativeRasterizationModeEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetExtraPrimitiveOverestimationSizeEXT commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(float) <= 4, "tycho ABI: vkCmdSetExtraPrimitiveOverestimationSizeEXT extraPrimitiveOverestimationSize wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetExtraPrimitiveOverestimationSizeEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetExtraPrimitiveOverestimationSizeEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetDepthClipEnableEXT commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkBool32) <= 4, "tycho ABI: vkCmdSetDepthClipEnableEXT depthClipEnable wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetDepthClipEnableEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetDepthClipEnableEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetSampleLocationsEnableEXT commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkBool32) <= 4, "tycho ABI: vkCmdSetSampleLocationsEnableEXT sampleLocationsEnable wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetSampleLocationsEnableEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetSampleLocationsEnableEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetColorBlendAdvancedEXT commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdSetColorBlendAdvancedEXT firstAttachment wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdSetColorBlendAdvancedEXT attachmentCount wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetColorBlendAdvancedEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetColorBlendAdvancedEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetProvokingVertexModeEXT commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkProvokingVertexModeEXT) <= 4, "tycho ABI: vkCmdSetProvokingVertexModeEXT provokingVertexMode wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetProvokingVertexModeEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetProvokingVertexModeEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetLineRasterizationModeEXT commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkLineRasterizationModeEXT) <= 4, "tycho ABI: vkCmdSetLineRasterizationModeEXT lineRasterizationMode wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetLineRasterizationModeEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetLineRasterizationModeEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetLineStippleEnableEXT commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkBool32) <= 4, "tycho ABI: vkCmdSetLineStippleEnableEXT stippledLineEnable wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetLineStippleEnableEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetLineStippleEnableEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetDepthClipNegativeOneToOneEXT commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkBool32) <= 4, "tycho ABI: vkCmdSetDepthClipNegativeOneToOneEXT negativeOneToOne wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetDepthClipNegativeOneToOneEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetDepthClipNegativeOneToOneEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetViewportWScalingEnableNV commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkBool32) <= 4, "tycho ABI: vkCmdSetViewportWScalingEnableNV viewportWScalingEnable wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetViewportWScalingEnableNV(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetViewportWScalingEnableNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetViewportSwizzleNV commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdSetViewportSwizzleNV firstViewport wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdSetViewportSwizzleNV viewportCount wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetViewportSwizzleNV(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetViewportSwizzleNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetCoverageToColorEnableNV commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkBool32) <= 4, "tycho ABI: vkCmdSetCoverageToColorEnableNV coverageToColorEnable wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetCoverageToColorEnableNV(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetCoverageToColorEnableNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetCoverageToColorLocationNV commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdSetCoverageToColorLocationNV coverageToColorLocation wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetCoverageToColorLocationNV(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetCoverageToColorLocationNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetCoverageModulationModeNV commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkCoverageModulationModeNV) <= 4, "tycho ABI: vkCmdSetCoverageModulationModeNV coverageModulationMode wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetCoverageModulationModeNV(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetCoverageModulationModeNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetCoverageModulationTableEnableNV commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkBool32) <= 4, "tycho ABI: vkCmdSetCoverageModulationTableEnableNV coverageModulationTableEnable wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetCoverageModulationTableEnableNV(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetCoverageModulationTableEnableNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetCoverageModulationTableNV commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdSetCoverageModulationTableNV coverageModulationTableCount wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetCoverageModulationTableNV(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetCoverageModulationTableNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetShadingRateImageEnableNV commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkBool32) <= 4, "tycho ABI: vkCmdSetShadingRateImageEnableNV shadingRateImageEnable wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetShadingRateImageEnableNV(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetShadingRateImageEnableNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetCoverageReductionModeNV commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkCoverageReductionModeNV) <= 4, "tycho ABI: vkCmdSetCoverageReductionModeNV coverageReductionMode wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetCoverageReductionModeNV(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetCoverageReductionModeNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetRepresentativeFragmentTestEnableNV commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkBool32) <= 4, "tycho ABI: vkCmdSetRepresentativeFragmentTestEnableNV representativeFragmentTestEnable wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetRepresentativeFragmentTestEnableNV(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetRepresentativeFragmentTestEnableNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkCreatePrivateDataSlot device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCreatePrivateDataSlot(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCreatePrivateDataSlot"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkCreatePrivateDataSlotEXT device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCreatePrivateDataSlotEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCreatePrivateDataSlotEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkDestroyPrivateDataSlot device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkPrivateDataSlot) <= sizeof(void*), "tycho ABI: vkDestroyPrivateDataSlot privateDataSlot wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkDestroyPrivateDataSlot(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkDestroyPrivateDataSlot"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkDestroyPrivateDataSlotEXT device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkPrivateDataSlot) <= sizeof(void*), "tycho ABI: vkDestroyPrivateDataSlotEXT privateDataSlot wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkDestroyPrivateDataSlotEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkDestroyPrivateDataSlotEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkSetPrivateData device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkObjectType) <= 4, "tycho ABI: vkSetPrivateData objectType wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint64_t) <= 8, "tycho ABI: vkSetPrivateData objectHandle wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkPrivateDataSlot) <= sizeof(void*), "tycho ABI: vkSetPrivateData privateDataSlot wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint64_t) <= 8, "tycho ABI: vkSetPrivateData data wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkSetPrivateData(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkSetPrivateData"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkSetPrivateDataEXT device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkObjectType) <= 4, "tycho ABI: vkSetPrivateDataEXT objectType wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint64_t) <= 8, "tycho ABI: vkSetPrivateDataEXT objectHandle wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkPrivateDataSlot) <= sizeof(void*), "tycho ABI: vkSetPrivateDataEXT privateDataSlot wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint64_t) <= 8, "tycho ABI: vkSetPrivateDataEXT data wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkSetPrivateDataEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkSetPrivateDataEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetPrivateData device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkObjectType) <= 4, "tycho ABI: vkGetPrivateData objectType wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint64_t) <= 8, "tycho ABI: vkGetPrivateData objectHandle wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkPrivateDataSlot) <= sizeof(void*), "tycho ABI: vkGetPrivateData privateDataSlot wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetPrivateData(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetPrivateData"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetPrivateDataEXT device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkObjectType) <= 4, "tycho ABI: vkGetPrivateDataEXT objectType wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint64_t) <= 8, "tycho ABI: vkGetPrivateDataEXT objectHandle wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkPrivateDataSlot) <= sizeof(void*), "tycho ABI: vkGetPrivateDataEXT privateDataSlot wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetPrivateDataEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetPrivateDataEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdCopyBuffer2 commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdCopyBuffer2(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdCopyBuffer2"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdCopyBuffer2KHR commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdCopyBuffer2KHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdCopyBuffer2KHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdCopyImage2 commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdCopyImage2(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdCopyImage2"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdCopyImage2KHR commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdCopyImage2KHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdCopyImage2KHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdBlitImage2 commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdBlitImage2(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdBlitImage2"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdBlitImage2KHR commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdBlitImage2KHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdBlitImage2KHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdCopyBufferToImage2 commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdCopyBufferToImage2(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdCopyBufferToImage2"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdCopyBufferToImage2KHR commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdCopyBufferToImage2KHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdCopyBufferToImage2KHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdCopyImageToBuffer2 commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdCopyImageToBuffer2(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdCopyImageToBuffer2"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdCopyImageToBuffer2KHR commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdCopyImageToBuffer2KHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdCopyImageToBuffer2KHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdResolveImage2 commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdResolveImage2(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdResolveImage2"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdResolveImage2KHR commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdResolveImage2KHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdResolveImage2KHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdRefreshObjectsKHR commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdRefreshObjectsKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdRefreshObjectsKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetFragmentShadingRateKHR commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetFragmentShadingRateKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetFragmentShadingRateKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetFragmentShadingRateEnumNV commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkFragmentShadingRateNV) <= 4, "tycho ABI: vkCmdSetFragmentShadingRateEnumNV shadingRate wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetFragmentShadingRateEnumNV(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetFragmentShadingRateEnumNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetAccelerationStructureBuildSizesKHR device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkAccelerationStructureBuildTypeKHR) <= 4, "tycho ABI: vkGetAccelerationStructureBuildSizesKHR buildType wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetAccelerationStructureBuildSizesKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetAccelerationStructureBuildSizesKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetVertexInputEXT commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdSetVertexInputEXT vertexBindingDescriptionCount wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdSetVertexInputEXT vertexAttributeDescriptionCount wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetVertexInputEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetVertexInputEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetColorWriteEnableEXT commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdSetColorWriteEnableEXT attachmentCount wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetColorWriteEnableEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetColorWriteEnableEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetEvent2 commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkEvent) <= sizeof(void*), "tycho ABI: vkCmdSetEvent2 event wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetEvent2(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetEvent2"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetEvent2KHR commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkEvent) <= sizeof(void*), "tycho ABI: vkCmdSetEvent2KHR event wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetEvent2KHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetEvent2KHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdResetEvent2 commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkEvent) <= sizeof(void*), "tycho ABI: vkCmdResetEvent2 event wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkPipelineStageFlags2) <= 8, "tycho ABI: vkCmdResetEvent2 stageMask wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdResetEvent2(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdResetEvent2"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdResetEvent2KHR commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkEvent) <= sizeof(void*), "tycho ABI: vkCmdResetEvent2KHR event wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkPipelineStageFlags2) <= 8, "tycho ABI: vkCmdResetEvent2KHR stageMask wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdResetEvent2KHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdResetEvent2KHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdWaitEvents2 commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdWaitEvents2 eventCount wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdWaitEvents2(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdWaitEvents2"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdWaitEvents2KHR commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdWaitEvents2KHR eventCount wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdWaitEvents2KHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdWaitEvents2KHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdPipelineBarrier2 commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdPipelineBarrier2(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdPipelineBarrier2"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdPipelineBarrier2KHR commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdPipelineBarrier2KHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdPipelineBarrier2KHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkQueue) <= sizeof(void*), "tycho ABI: vkQueueSubmit2 queue wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkQueueSubmit2 submitCount wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkFence) <= sizeof(void*), "tycho ABI: vkQueueSubmit2 fence wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkQueueSubmit2(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkQueueSubmit2"); }
TYCHO_STATIC_ASSERT(sizeof(VkQueue) <= sizeof(void*), "tycho ABI: vkQueueSubmit2KHR queue wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkQueueSubmit2KHR submitCount wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkFence) <= sizeof(void*), "tycho ABI: vkQueueSubmit2KHR fence wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkQueueSubmit2KHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkQueueSubmit2KHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdWriteTimestamp2 commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkPipelineStageFlags2) <= 8, "tycho ABI: vkCmdWriteTimestamp2 stage wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkQueryPool) <= sizeof(void*), "tycho ABI: vkCmdWriteTimestamp2 queryPool wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdWriteTimestamp2 query wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdWriteTimestamp2(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdWriteTimestamp2"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdWriteTimestamp2KHR commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkPipelineStageFlags2) <= 8, "tycho ABI: vkCmdWriteTimestamp2KHR stage wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkQueryPool) <= sizeof(void*), "tycho ABI: vkCmdWriteTimestamp2KHR queryPool wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdWriteTimestamp2KHR query wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdWriteTimestamp2KHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdWriteTimestamp2KHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdWriteBufferMarker2AMD commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkPipelineStageFlags2) <= 8, "tycho ABI: vkCmdWriteBufferMarker2AMD stage wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkBuffer) <= sizeof(void*), "tycho ABI: vkCmdWriteBufferMarker2AMD dstBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDeviceSize) <= 8, "tycho ABI: vkCmdWriteBufferMarker2AMD dstOffset wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdWriteBufferMarker2AMD marker wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdWriteBufferMarker2AMD(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdWriteBufferMarker2AMD"); }
TYCHO_STATIC_ASSERT(sizeof(VkQueue) <= sizeof(void*), "tycho ABI: vkGetQueueCheckpointData2NV queue wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetQueueCheckpointData2NV(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetQueueCheckpointData2NV"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkCopyMemoryToImage device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCopyMemoryToImage(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCopyMemoryToImage"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkCopyMemoryToImageEXT device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCopyMemoryToImageEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCopyMemoryToImageEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkCopyImageToMemory device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCopyImageToMemory(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCopyImageToMemory"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkCopyImageToMemoryEXT device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCopyImageToMemoryEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCopyImageToMemoryEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkCopyImageToImage device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCopyImageToImage(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCopyImageToImage"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkCopyImageToImageEXT device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCopyImageToImageEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCopyImageToImageEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkTransitionImageLayout device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkTransitionImageLayout transitionCount wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkTransitionImageLayout(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkTransitionImageLayout"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkTransitionImageLayoutEXT device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkTransitionImageLayoutEXT transitionCount wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkTransitionImageLayoutEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkTransitionImageLayoutEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetCommandPoolMemoryConsumption device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkCommandPool) <= sizeof(void*), "tycho ABI: vkGetCommandPoolMemoryConsumption commandPool wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkGetCommandPoolMemoryConsumption commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetCommandPoolMemoryConsumption(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetCommandPoolMemoryConsumption"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkCreateVideoSessionKHR device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCreateVideoSessionKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCreateVideoSessionKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkDestroyVideoSessionKHR device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkVideoSessionKHR) <= sizeof(void*), "tycho ABI: vkDestroyVideoSessionKHR videoSession wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkDestroyVideoSessionKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkDestroyVideoSessionKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkCreateVideoSessionParametersKHR device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCreateVideoSessionParametersKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCreateVideoSessionParametersKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkUpdateVideoSessionParametersKHR device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkVideoSessionParametersKHR) <= sizeof(void*), "tycho ABI: vkUpdateVideoSessionParametersKHR videoSessionParameters wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkUpdateVideoSessionParametersKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkUpdateVideoSessionParametersKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetEncodedVideoSessionParametersKHR device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetEncodedVideoSessionParametersKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetEncodedVideoSessionParametersKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkDestroyVideoSessionParametersKHR device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkVideoSessionParametersKHR) <= sizeof(void*), "tycho ABI: vkDestroyVideoSessionParametersKHR videoSessionParameters wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkDestroyVideoSessionParametersKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkDestroyVideoSessionParametersKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetVideoSessionMemoryRequirementsKHR device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkVideoSessionKHR) <= sizeof(void*), "tycho ABI: vkGetVideoSessionMemoryRequirementsKHR videoSession wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetVideoSessionMemoryRequirementsKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetVideoSessionMemoryRequirementsKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkBindVideoSessionMemoryKHR device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkVideoSessionKHR) <= sizeof(void*), "tycho ABI: vkBindVideoSessionMemoryKHR videoSession wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkBindVideoSessionMemoryKHR bindSessionMemoryInfoCount wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkBindVideoSessionMemoryKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkBindVideoSessionMemoryKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdDecodeVideoKHR commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdDecodeVideoKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdDecodeVideoKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdBeginVideoCodingKHR commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdBeginVideoCodingKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdBeginVideoCodingKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdControlVideoCodingKHR commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdControlVideoCodingKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdControlVideoCodingKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdEndVideoCodingKHR commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdEndVideoCodingKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdEndVideoCodingKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdEncodeVideoKHR commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdEncodeVideoKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdEncodeVideoKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdDecompressMemoryNV commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdDecompressMemoryNV decompressRegionCount wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdDecompressMemoryNV(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdDecompressMemoryNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdDecompressMemoryIndirectCountNV commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDeviceAddress) <= 8, "tycho ABI: vkCmdDecompressMemoryIndirectCountNV indirectCommandsAddress wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDeviceAddress) <= 8, "tycho ABI: vkCmdDecompressMemoryIndirectCountNV indirectCommandsCountAddress wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdDecompressMemoryIndirectCountNV stride wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdDecompressMemoryIndirectCountNV(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdDecompressMemoryIndirectCountNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetPartitionedAccelerationStructuresBuildSizesNV device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetPartitionedAccelerationStructuresBuildSizesNV(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetPartitionedAccelerationStructuresBuildSizesNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdBuildPartitionedAccelerationStructuresNV commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdBuildPartitionedAccelerationStructuresNV(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdBuildPartitionedAccelerationStructuresNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdDecompressMemoryEXT commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdDecompressMemoryEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdDecompressMemoryEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdDecompressMemoryIndirectCountEXT commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkMemoryDecompressionMethodFlagsEXT) <= 8, "tycho ABI: vkCmdDecompressMemoryIndirectCountEXT decompressionMethod wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDeviceAddress) <= 8, "tycho ABI: vkCmdDecompressMemoryIndirectCountEXT indirectCommandsAddress wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDeviceAddress) <= 8, "tycho ABI: vkCmdDecompressMemoryIndirectCountEXT indirectCommandsCountAddress wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdDecompressMemoryIndirectCountEXT maxDecompressionCount wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdDecompressMemoryIndirectCountEXT stride wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdDecompressMemoryIndirectCountEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdDecompressMemoryIndirectCountEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkCreateCuModuleNVX device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCreateCuModuleNVX(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCreateCuModuleNVX"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkCreateCuFunctionNVX device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCreateCuFunctionNVX(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCreateCuFunctionNVX"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkDestroyCuModuleNVX device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkCuModuleNVX) <= sizeof(void*), "tycho ABI: vkDestroyCuModuleNVX module wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkDestroyCuModuleNVX(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkDestroyCuModuleNVX"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkDestroyCuFunctionNVX device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkCuFunctionNVX) <= sizeof(void*), "tycho ABI: vkDestroyCuFunctionNVX function wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkDestroyCuFunctionNVX(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkDestroyCuFunctionNVX"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdCuLaunchKernelNVX commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdCuLaunchKernelNVX(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdCuLaunchKernelNVX"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetDescriptorSetLayoutSizeEXT device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDescriptorSetLayout) <= sizeof(void*), "tycho ABI: vkGetDescriptorSetLayoutSizeEXT layout wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetDescriptorSetLayoutSizeEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetDescriptorSetLayoutSizeEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetDescriptorSetLayoutBindingOffsetEXT device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDescriptorSetLayout) <= sizeof(void*), "tycho ABI: vkGetDescriptorSetLayoutBindingOffsetEXT layout wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkGetDescriptorSetLayoutBindingOffsetEXT binding wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetDescriptorSetLayoutBindingOffsetEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetDescriptorSetLayoutBindingOffsetEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetDescriptorEXT device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(size_t) <= 8, "tycho ABI: vkGetDescriptorEXT dataSize wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetDescriptorEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetDescriptorEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdBindDescriptorBuffersEXT commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdBindDescriptorBuffersEXT bufferCount wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdBindDescriptorBuffersEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdBindDescriptorBuffersEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetDescriptorBufferOffsetsEXT commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkPipelineBindPoint) <= 4, "tycho ABI: vkCmdSetDescriptorBufferOffsetsEXT pipelineBindPoint wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkPipelineLayout) <= sizeof(void*), "tycho ABI: vkCmdSetDescriptorBufferOffsetsEXT layout wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdSetDescriptorBufferOffsetsEXT firstSet wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdSetDescriptorBufferOffsetsEXT setCount wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetDescriptorBufferOffsetsEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetDescriptorBufferOffsetsEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdBindDescriptorBufferEmbeddedSamplersEXT commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkPipelineBindPoint) <= 4, "tycho ABI: vkCmdBindDescriptorBufferEmbeddedSamplersEXT pipelineBindPoint wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkPipelineLayout) <= sizeof(void*), "tycho ABI: vkCmdBindDescriptorBufferEmbeddedSamplersEXT layout wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdBindDescriptorBufferEmbeddedSamplersEXT set wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdBindDescriptorBufferEmbeddedSamplersEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdBindDescriptorBufferEmbeddedSamplersEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetBufferOpaqueCaptureDescriptorDataEXT device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetBufferOpaqueCaptureDescriptorDataEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetBufferOpaqueCaptureDescriptorDataEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetImageOpaqueCaptureDescriptorDataEXT device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetImageOpaqueCaptureDescriptorDataEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetImageOpaqueCaptureDescriptorDataEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetImageViewOpaqueCaptureDescriptorDataEXT device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetImageViewOpaqueCaptureDescriptorDataEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetImageViewOpaqueCaptureDescriptorDataEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetSamplerOpaqueCaptureDescriptorDataEXT device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetSamplerOpaqueCaptureDescriptorDataEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetSamplerOpaqueCaptureDescriptorDataEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetAccelerationStructureOpaqueCaptureDescriptorDataEXT device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetAccelerationStructureOpaqueCaptureDescriptorDataEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetAccelerationStructureOpaqueCaptureDescriptorDataEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkSetDeviceMemoryPriorityEXT device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDeviceMemory) <= sizeof(void*), "tycho ABI: vkSetDeviceMemoryPriorityEXT memory wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(float) <= 4, "tycho ABI: vkSetDeviceMemoryPriorityEXT priority wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkSetDeviceMemoryPriorityEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkSetDeviceMemoryPriorityEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkWaitForPresent2KHR device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkSwapchainKHR) <= sizeof(void*), "tycho ABI: vkWaitForPresent2KHR swapchain wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkWaitForPresent2KHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkWaitForPresent2KHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkWaitForPresentKHR device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkSwapchainKHR) <= sizeof(void*), "tycho ABI: vkWaitForPresentKHR swapchain wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint64_t) <= 8, "tycho ABI: vkWaitForPresentKHR presentId wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint64_t) <= 8, "tycho ABI: vkWaitForPresentKHR timeout wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkWaitForPresentKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkWaitForPresentKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkCreateBufferCollectionFUCHSIA device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCreateBufferCollectionFUCHSIA(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCreateBufferCollectionFUCHSIA"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkSetBufferCollectionBufferConstraintsFUCHSIA device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkSetBufferCollectionBufferConstraintsFUCHSIA(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkSetBufferCollectionBufferConstraintsFUCHSIA"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkSetBufferCollectionImageConstraintsFUCHSIA device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkSetBufferCollectionImageConstraintsFUCHSIA(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkSetBufferCollectionImageConstraintsFUCHSIA"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkDestroyBufferCollectionFUCHSIA device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkDestroyBufferCollectionFUCHSIA(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkDestroyBufferCollectionFUCHSIA"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetBufferCollectionPropertiesFUCHSIA device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetBufferCollectionPropertiesFUCHSIA(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetBufferCollectionPropertiesFUCHSIA"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkCreateCudaModuleNV device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCreateCudaModuleNV(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCreateCudaModuleNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetCudaModuleCacheNV device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkCudaModuleNV) <= sizeof(void*), "tycho ABI: vkGetCudaModuleCacheNV module wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetCudaModuleCacheNV(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetCudaModuleCacheNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkCreateCudaFunctionNV device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCreateCudaFunctionNV(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCreateCudaFunctionNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkDestroyCudaModuleNV device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkCudaModuleNV) <= sizeof(void*), "tycho ABI: vkDestroyCudaModuleNV module wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkDestroyCudaModuleNV(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkDestroyCudaModuleNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkDestroyCudaFunctionNV device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkCudaFunctionNV) <= sizeof(void*), "tycho ABI: vkDestroyCudaFunctionNV function wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkDestroyCudaFunctionNV(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkDestroyCudaFunctionNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdCudaLaunchKernelNV commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdCudaLaunchKernelNV(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdCudaLaunchKernelNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdBeginRendering commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdBeginRendering(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdBeginRendering"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdBeginRenderingKHR commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdBeginRenderingKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdBeginRenderingKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdEndRendering commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdEndRendering(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdEndRendering"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdEndRendering2KHR commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdEndRendering2KHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdEndRendering2KHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdEndRendering2EXT commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdEndRendering2EXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdEndRendering2EXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdEndRenderingKHR commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdEndRenderingKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdEndRenderingKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetDescriptorSetLayoutHostMappingInfoVALVE device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetDescriptorSetLayoutHostMappingInfoVALVE(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetDescriptorSetLayoutHostMappingInfoVALVE"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetDescriptorSetHostMappingVALVE device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDescriptorSet) <= sizeof(void*), "tycho ABI: vkGetDescriptorSetHostMappingVALVE descriptorSet wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetDescriptorSetHostMappingVALVE(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetDescriptorSetHostMappingVALVE"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkCreateMicromapEXT device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCreateMicromapEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCreateMicromapEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdBuildMicromapsEXT commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdBuildMicromapsEXT infoCount wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdBuildMicromapsEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdBuildMicromapsEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkBuildMicromapsEXT device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDeferredOperationKHR) <= sizeof(void*), "tycho ABI: vkBuildMicromapsEXT deferredOperation wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkBuildMicromapsEXT infoCount wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkBuildMicromapsEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkBuildMicromapsEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkDestroyMicromapEXT device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkMicromapEXT) <= sizeof(void*), "tycho ABI: vkDestroyMicromapEXT micromap wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkDestroyMicromapEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkDestroyMicromapEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdCopyMicromapEXT commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdCopyMicromapEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdCopyMicromapEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkCopyMicromapEXT device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDeferredOperationKHR) <= sizeof(void*), "tycho ABI: vkCopyMicromapEXT deferredOperation wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCopyMicromapEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCopyMicromapEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdCopyMicromapToMemoryEXT commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdCopyMicromapToMemoryEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdCopyMicromapToMemoryEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkCopyMicromapToMemoryEXT device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDeferredOperationKHR) <= sizeof(void*), "tycho ABI: vkCopyMicromapToMemoryEXT deferredOperation wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCopyMicromapToMemoryEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCopyMicromapToMemoryEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdCopyMemoryToMicromapEXT commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdCopyMemoryToMicromapEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdCopyMemoryToMicromapEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkCopyMemoryToMicromapEXT device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDeferredOperationKHR) <= sizeof(void*), "tycho ABI: vkCopyMemoryToMicromapEXT deferredOperation wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCopyMemoryToMicromapEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCopyMemoryToMicromapEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdWriteMicromapsPropertiesEXT commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdWriteMicromapsPropertiesEXT micromapCount wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkQueryType) <= 4, "tycho ABI: vkCmdWriteMicromapsPropertiesEXT queryType wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkQueryPool) <= sizeof(void*), "tycho ABI: vkCmdWriteMicromapsPropertiesEXT queryPool wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdWriteMicromapsPropertiesEXT firstQuery wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdWriteMicromapsPropertiesEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdWriteMicromapsPropertiesEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkWriteMicromapsPropertiesEXT device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkWriteMicromapsPropertiesEXT micromapCount wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkQueryType) <= 4, "tycho ABI: vkWriteMicromapsPropertiesEXT queryType wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(size_t) <= 8, "tycho ABI: vkWriteMicromapsPropertiesEXT dataSize wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(size_t) <= 8, "tycho ABI: vkWriteMicromapsPropertiesEXT stride wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkWriteMicromapsPropertiesEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkWriteMicromapsPropertiesEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetDeviceMicromapCompatibilityEXT device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetDeviceMicromapCompatibilityEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetDeviceMicromapCompatibilityEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetMicromapBuildSizesEXT device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkAccelerationStructureBuildTypeKHR) <= 4, "tycho ABI: vkGetMicromapBuildSizesEXT buildType wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetMicromapBuildSizesEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetMicromapBuildSizesEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetShaderModuleIdentifierEXT device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkShaderModule) <= sizeof(void*), "tycho ABI: vkGetShaderModuleIdentifierEXT shaderModule wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetShaderModuleIdentifierEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetShaderModuleIdentifierEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetShaderModuleCreateInfoIdentifierEXT device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetShaderModuleCreateInfoIdentifierEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetShaderModuleCreateInfoIdentifierEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetImageSubresourceLayout2 device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkImage) <= sizeof(void*), "tycho ABI: vkGetImageSubresourceLayout2 image wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetImageSubresourceLayout2(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetImageSubresourceLayout2"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetImageSubresourceLayout2KHR device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkImage) <= sizeof(void*), "tycho ABI: vkGetImageSubresourceLayout2KHR image wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetImageSubresourceLayout2KHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetImageSubresourceLayout2KHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetImageSubresourceLayout2EXT device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkImage) <= sizeof(void*), "tycho ABI: vkGetImageSubresourceLayout2EXT image wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetImageSubresourceLayout2EXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetImageSubresourceLayout2EXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetPipelinePropertiesEXT device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetPipelinePropertiesEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetPipelinePropertiesEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkExportMetalObjectsEXT device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkExportMetalObjectsEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkExportMetalObjectsEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdBindTileMemoryQCOM commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdBindTileMemoryQCOM(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdBindTileMemoryQCOM"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetFramebufferTilePropertiesQCOM device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkFramebuffer) <= sizeof(void*), "tycho ABI: vkGetFramebufferTilePropertiesQCOM framebuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetFramebufferTilePropertiesQCOM(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetFramebufferTilePropertiesQCOM"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetDynamicRenderingTilePropertiesQCOM device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetDynamicRenderingTilePropertiesQCOM(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetDynamicRenderingTilePropertiesQCOM"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkCreateOpticalFlowSessionNV device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCreateOpticalFlowSessionNV(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCreateOpticalFlowSessionNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkDestroyOpticalFlowSessionNV device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkOpticalFlowSessionNV) <= sizeof(void*), "tycho ABI: vkDestroyOpticalFlowSessionNV session wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkDestroyOpticalFlowSessionNV(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkDestroyOpticalFlowSessionNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkBindOpticalFlowSessionImageNV device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkOpticalFlowSessionNV) <= sizeof(void*), "tycho ABI: vkBindOpticalFlowSessionImageNV session wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkOpticalFlowSessionBindingPointNV) <= 4, "tycho ABI: vkBindOpticalFlowSessionImageNV bindingPoint wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkImageView) <= sizeof(void*), "tycho ABI: vkBindOpticalFlowSessionImageNV view wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkImageLayout) <= 4, "tycho ABI: vkBindOpticalFlowSessionImageNV layout wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkBindOpticalFlowSessionImageNV(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkBindOpticalFlowSessionImageNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdOpticalFlowExecuteNV commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkOpticalFlowSessionNV) <= sizeof(void*), "tycho ABI: vkCmdOpticalFlowExecuteNV session wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdOpticalFlowExecuteNV(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdOpticalFlowExecuteNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetDeviceFaultInfoEXT device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetDeviceFaultInfoEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetDeviceFaultInfoEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetDeviceFaultReportsKHR device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint64_t) <= 8, "tycho ABI: vkGetDeviceFaultReportsKHR timeout wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetDeviceFaultReportsKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetDeviceFaultReportsKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetDeviceFaultDebugInfoKHR device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetDeviceFaultDebugInfoKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetDeviceFaultDebugInfoKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetDepthBias2EXT commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetDepthBias2EXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetDepthBias2EXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkReleaseSwapchainImagesKHR device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkReleaseSwapchainImagesKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkReleaseSwapchainImagesKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkReleaseSwapchainImagesEXT device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkReleaseSwapchainImagesEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkReleaseSwapchainImagesEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetDeviceImageSubresourceLayout device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetDeviceImageSubresourceLayout(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetDeviceImageSubresourceLayout"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetDeviceImageSubresourceLayoutKHR device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetDeviceImageSubresourceLayoutKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetDeviceImageSubresourceLayoutKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkMapMemory2 device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkMapMemory2(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkMapMemory2"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkMapMemory2KHR device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkMapMemory2KHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkMapMemory2KHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkUnmapMemory2 device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkUnmapMemory2(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkUnmapMemory2"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkUnmapMemory2KHR device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkUnmapMemory2KHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkUnmapMemory2KHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkCreateShadersEXT device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCreateShadersEXT createInfoCount wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCreateShadersEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCreateShadersEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkDestroyShaderEXT device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkShaderEXT) <= sizeof(void*), "tycho ABI: vkDestroyShaderEXT shader wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkDestroyShaderEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkDestroyShaderEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetShaderBinaryDataEXT device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkShaderEXT) <= sizeof(void*), "tycho ABI: vkGetShaderBinaryDataEXT shader wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetShaderBinaryDataEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetShaderBinaryDataEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdBindShadersEXT commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdBindShadersEXT stageCount wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdBindShadersEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdBindShadersEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkSetSwapchainPresentTimingQueueSizeEXT device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkSwapchainKHR) <= sizeof(void*), "tycho ABI: vkSetSwapchainPresentTimingQueueSizeEXT swapchain wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkSetSwapchainPresentTimingQueueSizeEXT size wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkSetSwapchainPresentTimingQueueSizeEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkSetSwapchainPresentTimingQueueSizeEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetSwapchainTimingPropertiesEXT device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkSwapchainKHR) <= sizeof(void*), "tycho ABI: vkGetSwapchainTimingPropertiesEXT swapchain wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetSwapchainTimingPropertiesEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetSwapchainTimingPropertiesEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetSwapchainTimeDomainPropertiesEXT device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkSwapchainKHR) <= sizeof(void*), "tycho ABI: vkGetSwapchainTimeDomainPropertiesEXT swapchain wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetSwapchainTimeDomainPropertiesEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetSwapchainTimeDomainPropertiesEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetPastPresentationTimingEXT device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetPastPresentationTimingEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetPastPresentationTimingEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetScreenBufferPropertiesQNX device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetScreenBufferPropertiesQNX(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetScreenBufferPropertiesQNX"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetExecutionGraphPipelineScratchSizeAMDX device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkPipeline) <= sizeof(void*), "tycho ABI: vkGetExecutionGraphPipelineScratchSizeAMDX executionGraph wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetExecutionGraphPipelineScratchSizeAMDX(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetExecutionGraphPipelineScratchSizeAMDX"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetExecutionGraphPipelineNodeIndexAMDX device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkPipeline) <= sizeof(void*), "tycho ABI: vkGetExecutionGraphPipelineNodeIndexAMDX executionGraph wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetExecutionGraphPipelineNodeIndexAMDX(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetExecutionGraphPipelineNodeIndexAMDX"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkCreateExecutionGraphPipelinesAMDX device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkPipelineCache) <= sizeof(void*), "tycho ABI: vkCreateExecutionGraphPipelinesAMDX pipelineCache wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCreateExecutionGraphPipelinesAMDX createInfoCount wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCreateExecutionGraphPipelinesAMDX(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCreateExecutionGraphPipelinesAMDX"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdInitializeGraphScratchMemoryAMDX commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkPipeline) <= sizeof(void*), "tycho ABI: vkCmdInitializeGraphScratchMemoryAMDX executionGraph wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDeviceAddress) <= 8, "tycho ABI: vkCmdInitializeGraphScratchMemoryAMDX scratch wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDeviceSize) <= 8, "tycho ABI: vkCmdInitializeGraphScratchMemoryAMDX scratchSize wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdInitializeGraphScratchMemoryAMDX(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdInitializeGraphScratchMemoryAMDX"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdDispatchGraphAMDX commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDeviceAddress) <= 8, "tycho ABI: vkCmdDispatchGraphAMDX scratch wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDeviceSize) <= 8, "tycho ABI: vkCmdDispatchGraphAMDX scratchSize wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdDispatchGraphAMDX(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdDispatchGraphAMDX"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdDispatchGraphIndirectAMDX commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDeviceAddress) <= 8, "tycho ABI: vkCmdDispatchGraphIndirectAMDX scratch wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDeviceSize) <= 8, "tycho ABI: vkCmdDispatchGraphIndirectAMDX scratchSize wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdDispatchGraphIndirectAMDX(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdDispatchGraphIndirectAMDX"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdDispatchGraphIndirectCountAMDX commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDeviceAddress) <= 8, "tycho ABI: vkCmdDispatchGraphIndirectCountAMDX scratch wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDeviceSize) <= 8, "tycho ABI: vkCmdDispatchGraphIndirectCountAMDX scratchSize wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDeviceAddress) <= 8, "tycho ABI: vkCmdDispatchGraphIndirectCountAMDX countInfo wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdDispatchGraphIndirectCountAMDX(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdDispatchGraphIndirectCountAMDX"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkCreateGpaSessionAMD device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCreateGpaSessionAMD(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCreateGpaSessionAMD"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkDestroyGpaSessionAMD device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkGpaSessionAMD) <= sizeof(void*), "tycho ABI: vkDestroyGpaSessionAMD gpaSession wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkDestroyGpaSessionAMD(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkDestroyGpaSessionAMD"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkSetGpaDeviceClockModeAMD device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkSetGpaDeviceClockModeAMD(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkSetGpaDeviceClockModeAMD"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetGpaDeviceClockInfoAMD device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetGpaDeviceClockInfoAMD(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetGpaDeviceClockInfoAMD"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdBeginGpaSessionAMD commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkGpaSessionAMD) <= sizeof(void*), "tycho ABI: vkCmdBeginGpaSessionAMD gpaSession wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdBeginGpaSessionAMD(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdBeginGpaSessionAMD"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdEndGpaSessionAMD commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkGpaSessionAMD) <= sizeof(void*), "tycho ABI: vkCmdEndGpaSessionAMD gpaSession wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdEndGpaSessionAMD(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdEndGpaSessionAMD"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdBeginGpaSampleAMD commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkGpaSessionAMD) <= sizeof(void*), "tycho ABI: vkCmdBeginGpaSampleAMD gpaSession wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdBeginGpaSampleAMD(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdBeginGpaSampleAMD"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdEndGpaSampleAMD commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkGpaSessionAMD) <= sizeof(void*), "tycho ABI: vkCmdEndGpaSampleAMD gpaSession wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdEndGpaSampleAMD sampleID wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdEndGpaSampleAMD(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdEndGpaSampleAMD"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetGpaSessionStatusAMD device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkGpaSessionAMD) <= sizeof(void*), "tycho ABI: vkGetGpaSessionStatusAMD gpaSession wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetGpaSessionStatusAMD(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetGpaSessionStatusAMD"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetGpaSessionResultsAMD device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkGpaSessionAMD) <= sizeof(void*), "tycho ABI: vkGetGpaSessionResultsAMD gpaSession wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkGetGpaSessionResultsAMD sampleID wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetGpaSessionResultsAMD(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetGpaSessionResultsAMD"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkResetGpaSessionAMD device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkGpaSessionAMD) <= sizeof(void*), "tycho ABI: vkResetGpaSessionAMD gpaSession wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkResetGpaSessionAMD(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkResetGpaSessionAMD"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdCopyGpaSessionResultsAMD commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkGpaSessionAMD) <= sizeof(void*), "tycho ABI: vkCmdCopyGpaSessionResultsAMD gpaSession wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdCopyGpaSessionResultsAMD(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdCopyGpaSessionResultsAMD"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdBindDescriptorSets2 commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdBindDescriptorSets2(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdBindDescriptorSets2"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdBindDescriptorSets2KHR commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdBindDescriptorSets2KHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdBindDescriptorSets2KHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdPushConstants2 commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdPushConstants2(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdPushConstants2"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdPushConstants2KHR commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdPushConstants2KHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdPushConstants2KHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdPushDescriptorSet2 commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdPushDescriptorSet2(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdPushDescriptorSet2"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdPushDescriptorSet2KHR commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdPushDescriptorSet2KHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdPushDescriptorSet2KHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdPushDescriptorSetWithTemplate2 commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdPushDescriptorSetWithTemplate2(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdPushDescriptorSetWithTemplate2"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdPushDescriptorSetWithTemplate2KHR commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdPushDescriptorSetWithTemplate2KHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdPushDescriptorSetWithTemplate2KHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetDescriptorBufferOffsets2EXT commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetDescriptorBufferOffsets2EXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetDescriptorBufferOffsets2EXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdBindDescriptorBufferEmbeddedSamplers2EXT commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdBindDescriptorBufferEmbeddedSamplers2EXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdBindDescriptorBufferEmbeddedSamplers2EXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkSetLatencySleepModeNV device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkSwapchainKHR) <= sizeof(void*), "tycho ABI: vkSetLatencySleepModeNV swapchain wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkSetLatencySleepModeNV(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkSetLatencySleepModeNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkLatencySleepNV device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkSwapchainKHR) <= sizeof(void*), "tycho ABI: vkLatencySleepNV swapchain wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkLatencySleepNV(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkLatencySleepNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkSetLatencyMarkerNV device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkSwapchainKHR) <= sizeof(void*), "tycho ABI: vkSetLatencyMarkerNV swapchain wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkSetLatencyMarkerNV(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkSetLatencyMarkerNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetLatencyTimingsNV device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkSwapchainKHR) <= sizeof(void*), "tycho ABI: vkGetLatencyTimingsNV swapchain wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetLatencyTimingsNV(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetLatencyTimingsNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkQueue) <= sizeof(void*), "tycho ABI: vkQueueNotifyOutOfBandNV queue wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkQueueNotifyOutOfBandNV(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkQueueNotifyOutOfBandNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkSetLatencySleepModeLegacyNV device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkBool32) <= 4, "tycho ABI: vkSetLatencySleepModeLegacyNV lowLatencyMode wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkBool32) <= 4, "tycho ABI: vkSetLatencySleepModeLegacyNV lowLatencyBoost wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkSetLatencySleepModeLegacyNV minimumIntervalUs wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkSetLatencySleepModeLegacyNV(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkSetLatencySleepModeLegacyNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkLatencySleepLegacyNV device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkSemaphore) <= sizeof(void*), "tycho ABI: vkLatencySleepLegacyNV signalSemaphore wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint64_t) <= 8, "tycho ABI: vkLatencySleepLegacyNV value wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkLatencySleepLegacyNV(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkLatencySleepLegacyNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkSetLatencyMarkerLegacyNV device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint64_t) <= 8, "tycho ABI: vkSetLatencyMarkerLegacyNV frameID wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkSetLatencyMarkerLegacyNV marker wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkSetLatencyMarkerLegacyNV(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkSetLatencyMarkerLegacyNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetLatencyTimingsLegacyNV device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetLatencyTimingsLegacyNV(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetLatencyTimingsLegacyNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkQueue) <= sizeof(void*), "tycho ABI: vkQueueNotifyOutOfBandLegacyNV queue wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkQueueNotifyOutOfBandLegacyNV queueType wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkQueueNotifyOutOfBandLegacyNV(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkQueueNotifyOutOfBandLegacyNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetSleepStatusLegacyNV device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetSleepStatusLegacyNV(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetSleepStatusLegacyNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkShutdownLatencyDeviceLegacyNV device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkShutdownLatencyDeviceLegacyNV(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkShutdownLatencyDeviceLegacyNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetRenderingAttachmentLocations commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetRenderingAttachmentLocations(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetRenderingAttachmentLocations"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetRenderingAttachmentLocationsKHR commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetRenderingAttachmentLocationsKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetRenderingAttachmentLocationsKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetRenderingInputAttachmentIndices commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetRenderingInputAttachmentIndices(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetRenderingInputAttachmentIndices"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetRenderingInputAttachmentIndicesKHR commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetRenderingInputAttachmentIndicesKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetRenderingInputAttachmentIndicesKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetDepthClampRangeEXT commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDepthClampModeEXT) <= 4, "tycho ABI: vkCmdSetDepthClampRangeEXT depthClampMode wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetDepthClampRangeEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetDepthClampRangeEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetMemoryMetalHandleEXT device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetMemoryMetalHandleEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetMemoryMetalHandleEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetMemoryMetalHandlePropertiesEXT device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkExternalMemoryHandleTypeFlagBits) <= 4, "tycho ABI: vkGetMemoryMetalHandlePropertiesEXT handleType wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetMemoryMetalHandlePropertiesEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetMemoryMetalHandlePropertiesEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkConvertCooperativeVectorMatrixNV device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkConvertCooperativeVectorMatrixNV(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkConvertCooperativeVectorMatrixNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdConvertCooperativeVectorMatrixNV commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdConvertCooperativeVectorMatrixNV infoCount wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdConvertCooperativeVectorMatrixNV(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdConvertCooperativeVectorMatrixNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdDispatchTileQCOM commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdDispatchTileQCOM(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdDispatchTileQCOM"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdBeginPerTileExecutionQCOM commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdBeginPerTileExecutionQCOM(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdBeginPerTileExecutionQCOM"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdEndPerTileExecutionQCOM commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdEndPerTileExecutionQCOM(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdEndPerTileExecutionQCOM"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkCreateExternalComputeQueueNV device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCreateExternalComputeQueueNV(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCreateExternalComputeQueueNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkDestroyExternalComputeQueueNV device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkExternalComputeQueueNV) <= sizeof(void*), "tycho ABI: vkDestroyExternalComputeQueueNV externalQueue wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkDestroyExternalComputeQueueNV(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkDestroyExternalComputeQueueNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkCreateShaderInstrumentationARM device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCreateShaderInstrumentationARM(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCreateShaderInstrumentationARM"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkDestroyShaderInstrumentationARM device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkShaderInstrumentationARM) <= sizeof(void*), "tycho ABI: vkDestroyShaderInstrumentationARM instrumentation wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkDestroyShaderInstrumentationARM(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkDestroyShaderInstrumentationARM"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdBeginShaderInstrumentationARM commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkShaderInstrumentationARM) <= sizeof(void*), "tycho ABI: vkCmdBeginShaderInstrumentationARM instrumentation wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdBeginShaderInstrumentationARM(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdBeginShaderInstrumentationARM"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdEndShaderInstrumentationARM commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdEndShaderInstrumentationARM(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdEndShaderInstrumentationARM"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetShaderInstrumentationValuesARM device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkShaderInstrumentationARM) <= sizeof(void*), "tycho ABI: vkGetShaderInstrumentationValuesARM instrumentation wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkShaderInstrumentationValuesFlagsARM) <= 4, "tycho ABI: vkGetShaderInstrumentationValuesARM flags wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetShaderInstrumentationValuesARM(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetShaderInstrumentationValuesARM"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkClearShaderInstrumentationMetricsARM device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkShaderInstrumentationARM) <= sizeof(void*), "tycho ABI: vkClearShaderInstrumentationMetricsARM instrumentation wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkClearShaderInstrumentationMetricsARM(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkClearShaderInstrumentationMetricsARM"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkCreateTensorARM device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCreateTensorARM(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCreateTensorARM"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkDestroyTensorARM device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkTensorARM) <= sizeof(void*), "tycho ABI: vkDestroyTensorARM tensor wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkDestroyTensorARM(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkDestroyTensorARM"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkCreateTensorViewARM device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCreateTensorViewARM(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCreateTensorViewARM"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkDestroyTensorViewARM device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkTensorViewARM) <= sizeof(void*), "tycho ABI: vkDestroyTensorViewARM tensorView wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkDestroyTensorViewARM(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkDestroyTensorViewARM"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetTensorMemoryRequirementsARM device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetTensorMemoryRequirementsARM(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetTensorMemoryRequirementsARM"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkBindTensorMemoryARM device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkBindTensorMemoryARM bindInfoCount wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkBindTensorMemoryARM(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkBindTensorMemoryARM"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetDeviceTensorMemoryRequirementsARM device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetDeviceTensorMemoryRequirementsARM(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetDeviceTensorMemoryRequirementsARM"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdCopyTensorARM commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdCopyTensorARM(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdCopyTensorARM"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetTensorOpaqueCaptureDescriptorDataARM device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetTensorOpaqueCaptureDescriptorDataARM(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetTensorOpaqueCaptureDescriptorDataARM"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetTensorViewOpaqueCaptureDescriptorDataARM device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetTensorViewOpaqueCaptureDescriptorDataARM(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetTensorViewOpaqueCaptureDescriptorDataARM"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkCreateDataGraphPipelinesARM device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDeferredOperationKHR) <= sizeof(void*), "tycho ABI: vkCreateDataGraphPipelinesARM deferredOperation wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkPipelineCache) <= sizeof(void*), "tycho ABI: vkCreateDataGraphPipelinesARM pipelineCache wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCreateDataGraphPipelinesARM createInfoCount wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCreateDataGraphPipelinesARM(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCreateDataGraphPipelinesARM"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkCreateDataGraphPipelineSessionARM device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCreateDataGraphPipelineSessionARM(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCreateDataGraphPipelineSessionARM"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetDataGraphPipelineSessionBindPointRequirementsARM device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetDataGraphPipelineSessionBindPointRequirementsARM(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetDataGraphPipelineSessionBindPointRequirementsARM"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetDataGraphPipelineSessionMemoryRequirementsARM device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetDataGraphPipelineSessionMemoryRequirementsARM(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetDataGraphPipelineSessionMemoryRequirementsARM"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkBindDataGraphPipelineSessionMemoryARM device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkBindDataGraphPipelineSessionMemoryARM bindInfoCount wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkBindDataGraphPipelineSessionMemoryARM(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkBindDataGraphPipelineSessionMemoryARM"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkDestroyDataGraphPipelineSessionARM device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDataGraphPipelineSessionARM) <= sizeof(void*), "tycho ABI: vkDestroyDataGraphPipelineSessionARM session wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkDestroyDataGraphPipelineSessionARM(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkDestroyDataGraphPipelineSessionARM"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdDispatchDataGraphARM commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDataGraphPipelineSessionARM) <= sizeof(void*), "tycho ABI: vkCmdDispatchDataGraphARM session wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdDispatchDataGraphARM(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdDispatchDataGraphARM"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetDataGraphPipelineAvailablePropertiesARM device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetDataGraphPipelineAvailablePropertiesARM(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetDataGraphPipelineAvailablePropertiesARM"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetDataGraphPipelinePropertiesARM device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkGetDataGraphPipelinePropertiesARM propertiesCount wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetDataGraphPipelinePropertiesARM(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetDataGraphPipelinePropertiesARM"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetNativeBufferPropertiesOHOS device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetNativeBufferPropertiesOHOS(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetNativeBufferPropertiesOHOS"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetMemoryNativeBufferOHOS device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetMemoryNativeBufferOHOS(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetMemoryNativeBufferOHOS"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetSwapchainGrallocUsageOHOS device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkFormat) <= 4, "tycho ABI: vkGetSwapchainGrallocUsageOHOS format wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkImageUsageFlags) <= 4, "tycho ABI: vkGetSwapchainGrallocUsageOHOS imageUsage wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetSwapchainGrallocUsageOHOS(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetSwapchainGrallocUsageOHOS"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkAcquireImageOHOS device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkImage) <= sizeof(void*), "tycho ABI: vkAcquireImageOHOS image wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(int32_t) <= 4, "tycho ABI: vkAcquireImageOHOS nativeFenceFd wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkSemaphore) <= sizeof(void*), "tycho ABI: vkAcquireImageOHOS semaphore wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkFence) <= sizeof(void*), "tycho ABI: vkAcquireImageOHOS fence wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkAcquireImageOHOS(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkAcquireImageOHOS"); }
TYCHO_STATIC_ASSERT(sizeof(VkQueue) <= sizeof(void*), "tycho ABI: vkQueueSignalReleaseImageOHOS queue wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkQueueSignalReleaseImageOHOS waitSemaphoreCount wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkImage) <= sizeof(void*), "tycho ABI: vkQueueSignalReleaseImageOHOS image wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkQueueSignalReleaseImageOHOS(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkQueueSignalReleaseImageOHOS"); }
TYCHO_STATIC_ASSERT(sizeof(VkQueue) <= sizeof(void*), "tycho ABI: vkQueueSetPerfHintQCOM queue wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkQueueSetPerfHintQCOM(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkQueueSetPerfHintQCOM"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetComputeOccupancyPriorityNV commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetComputeOccupancyPriorityNV(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetComputeOccupancyPriorityNV"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkWriteSamplerDescriptorsEXT device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkWriteSamplerDescriptorsEXT samplerCount wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkWriteSamplerDescriptorsEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkWriteSamplerDescriptorsEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkWriteResourceDescriptorsEXT device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkWriteResourceDescriptorsEXT resourceCount wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkWriteResourceDescriptorsEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkWriteResourceDescriptorsEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdBindSamplerHeapEXT commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdBindSamplerHeapEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdBindSamplerHeapEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdBindResourceHeapEXT commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdBindResourceHeapEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdBindResourceHeapEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdPushDataEXT commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdPushDataEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdPushDataEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkRegisterCustomBorderColorEXT device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkBool32) <= 4, "tycho ABI: vkRegisterCustomBorderColorEXT requestIndex wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkRegisterCustomBorderColorEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkRegisterCustomBorderColorEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkUnregisterCustomBorderColorEXT device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkUnregisterCustomBorderColorEXT index wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkUnregisterCustomBorderColorEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkUnregisterCustomBorderColorEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetImageOpaqueCaptureDataEXT device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkGetImageOpaqueCaptureDataEXT imageCount wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetImageOpaqueCaptureDataEXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetImageOpaqueCaptureDataEXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkGetTensorOpaqueCaptureDataARM device wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkGetTensorOpaqueCaptureDataARM tensorCount wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkGetTensorOpaqueCaptureDataARM(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkGetTensorOpaqueCaptureDataARM"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdCopyMemoryKHR commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdCopyMemoryKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdCopyMemoryKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdCopyMemoryToImageKHR commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdCopyMemoryToImageKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdCopyMemoryToImageKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdCopyImageToMemoryKHR commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdCopyImageToMemoryKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdCopyImageToMemoryKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdUpdateMemoryKHR commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkAddressCommandFlagsKHR) <= 4, "tycho ABI: vkCmdUpdateMemoryKHR dstFlags wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkDeviceSize) <= 8, "tycho ABI: vkCmdUpdateMemoryKHR dataSize wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdUpdateMemoryKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdUpdateMemoryKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdFillMemoryKHR commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkAddressCommandFlagsKHR) <= 4, "tycho ABI: vkCmdFillMemoryKHR dstFlags wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdFillMemoryKHR data wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdFillMemoryKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdFillMemoryKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdCopyQueryPoolResultsToMemoryKHR commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkQueryPool) <= sizeof(void*), "tycho ABI: vkCmdCopyQueryPoolResultsToMemoryKHR queryPool wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdCopyQueryPoolResultsToMemoryKHR firstQuery wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdCopyQueryPoolResultsToMemoryKHR queryCount wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkAddressCommandFlagsKHR) <= 4, "tycho ABI: vkCmdCopyQueryPoolResultsToMemoryKHR dstFlags wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(VkQueryResultFlags) <= 4, "tycho ABI: vkCmdCopyQueryPoolResultsToMemoryKHR queryResultFlags wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdCopyQueryPoolResultsToMemoryKHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdCopyQueryPoolResultsToMemoryKHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdBeginConditionalRendering2EXT commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdBeginConditionalRendering2EXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdBeginConditionalRendering2EXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdBindTransformFeedbackBuffers2EXT commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdBindTransformFeedbackBuffers2EXT firstBinding wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdBindTransformFeedbackBuffers2EXT bindingCount wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdBindTransformFeedbackBuffers2EXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdBindTransformFeedbackBuffers2EXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdBeginTransformFeedback2EXT commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdBeginTransformFeedback2EXT firstCounterRange wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdBeginTransformFeedback2EXT counterRangeCount wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdBeginTransformFeedback2EXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdBeginTransformFeedback2EXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdEndTransformFeedback2EXT commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdEndTransformFeedback2EXT firstCounterRange wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdEndTransformFeedback2EXT counterRangeCount wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdEndTransformFeedback2EXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdEndTransformFeedback2EXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdDrawIndirectByteCount2EXT commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdDrawIndirectByteCount2EXT instanceCount wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdDrawIndirectByteCount2EXT firstInstance wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdDrawIndirectByteCount2EXT counterOffset wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdDrawIndirectByteCount2EXT vertexStride wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdDrawIndirectByteCount2EXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdDrawIndirectByteCount2EXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdWriteMarkerToMemoryAMD commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdWriteMarkerToMemoryAMD(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdWriteMarkerToMemoryAMD"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdBindIndexBuffer3KHR commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdBindIndexBuffer3KHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdBindIndexBuffer3KHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdBindVertexBuffers3KHR commandBuffer wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdBindVertexBuffers3KHR firstBinding wider than MoonBit type");
TYCHO_STATIC_ASSERT(sizeof(uint32_t) <= 4, "tycho ABI: vkCmdBindVertexBuffers3KHR bindingCount wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdBindVertexBuffers3KHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdBindVertexBuffers3KHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdDrawIndirect2KHR commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdDrawIndirect2KHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdDrawIndirect2KHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdDrawIndexedIndirect2KHR commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdDrawIndexedIndirect2KHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdDrawIndexedIndirect2KHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdDrawIndirectCount2KHR commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdDrawIndirectCount2KHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdDrawIndirectCount2KHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdDrawIndexedIndirectCount2KHR commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdDrawIndexedIndirectCount2KHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdDrawIndexedIndirectCount2KHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdDrawMeshTasksIndirect2EXT commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdDrawMeshTasksIndirect2EXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdDrawMeshTasksIndirect2EXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdDrawMeshTasksIndirectCount2EXT commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdDrawMeshTasksIndirectCount2EXT(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdDrawMeshTasksIndirectCount2EXT"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdDispatchIndirect2KHR commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdDispatchIndirect2KHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdDispatchIndirect2KHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkDevice) <= sizeof(void*), "tycho ABI: vkCreateAccelerationStructure2KHR device wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCreateAccelerationStructure2KHR(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCreateAccelerationStructure2KHR"); }
TYCHO_STATIC_ASSERT(sizeof(VkCommandBuffer) <= sizeof(void*), "tycho ABI: vkCmdSetDispatchParametersARM commandBuffer wider than MoonBit type");
MOONBIT_FFI_EXPORT void *tycho_gpa_vkCmdSetDispatchParametersARM(void *h) { return tycho_vk_gdpa((VkDevice)h, "vkCmdSetDispatchParametersARM"); }
