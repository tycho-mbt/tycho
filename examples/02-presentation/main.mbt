// Example 02 — Presentation (vulkan-tutorial.com/Drawing_a_triangle/Presentation).
// X11 window surface + swap chain + image views. Pure MoonBit (no C stub).







///|
fn main {
  // --- Instance with surface extensions ---
  let app = @vk.VkApplicationInfo::new()
  app.set_pApplicationName(@vk.cstr("Hello Triangle"))
  app.set_apiVersion((4194304 : UInt32))
  let ici = @vk.VkInstanceCreateInfo::new()
  ici.set_pApplicationInfo(app)
  ici.set_enabledExtensionCount((3 : UInt32))
  ici.set_ppEnabledExtensionNames(@vk.cstr_array(@win.surface_extensions()))
  let inst_out = FixedArray::make(1, @vk.VkInstance::null())
  let ir = @vk.vkCreateInstance(ici, @vk.VkAllocationCallbacks::null(), inst_out)
  let inst = inst_out[0]
  let ifn = @vk.InstanceFn::load(inst)
  let pc = FixedArray::make(1, (16 : UInt32))
  let devs = FixedArray::make(16, @vk.VkPhysicalDevice::null())
  let _ = (ifn.vkEnumeratePhysicalDevices)(inst, pc, devs)
  let phys = devs[0]

  // --- Logical device with swapchain extension ---
  let prio = FixedArray::make(1, (1.0 : Float))
  let qci = @vk.VkDeviceQueueCreateInfo::new()
  qci.set_queueFamilyIndex((0 : UInt32))
  qci.set_queueCount((1 : UInt32))
  qci.set_pQueuePriorities(prio)
  let dci = @vk.VkDeviceCreateInfo::new()
  dci.set_queueCreateInfoCount((1 : UInt32))
  dci.set_pQueueCreateInfos(qci)
  dci.set_enabledExtensionCount((1 : UInt32))
  dci.set_ppEnabledExtensionNames(@vk.cstr_array(["VK_KHR_swapchain"]))
  let dev_out = FixedArray::make(1, @vk.VkDevice::null())
  let dr = (ifn.vkCreateDevice)(phys, dci, @vk.VkAllocationCallbacks::null(), dev_out)
  let dev = dev_out[0]
  let dfn = @vk.DeviceFn::load(dev)
  println("[02-present] instance=\{ir} device=\{dr}")

  // --- X11 window + Vulkan surface ---
  let _ = @win.initialize()
  let win = @win.create((800 : Int32), (600 : Int32), "02-presentation")
  let surface = @win.create_surface(inst, win)

  // --- Surface capabilities + formats ---
  let caps = @vk.VkSurfaceCapabilitiesKHR::new()
  let _ = (ifn.vkGetPhysicalDeviceSurfaceCapabilitiesKHR)(phys, surface, caps)
  let fc = FixedArray::make(1, (0 : UInt32))
  let _ = (ifn.vkGetPhysicalDeviceSurfaceFormatsKHR)(phys, surface, fc, @vk.VkSurfaceFormatKHR::null())
  let nf = fc[0].reinterpret_as_int()
  let formats = @vk.VkSurfaceFormatKHR::array(nf)
  let _ = (ifn.vkGetPhysicalDeviceSurfaceFormatsKHR)(phys, surface, fc, formats)
  let format = formats.get_format_at(0)
  let color_space = formats.get_colorSpace_at(0)

  // --- Swap chain ---
  let extent = @vk.VkExtent2D::new()
  extent.set_width((800 : UInt32))
  extent.set_height((600 : UInt32))
  let swci = @vk.VkSwapchainCreateInfoKHR::new()
  swci.set_surface(surface)
  swci.set_minImageCount(caps.get_minImageCount())
  swci.set_imageFormat(format)
  swci.set_imageColorSpace(color_space)
  swci.set_imageExtent(extent)
  swci.set_imageArrayLayers((1 : UInt32))
  swci.set_imageUsage(@vk.VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT) // COLOR_ATTACHMENT
  swci.set_imageSharingMode(@vk.VK_SHARING_MODE_EXCLUSIVE) // EXCLUSIVE
  swci.set_preTransform(caps.get_currentTransform())
  swci.set_compositeAlpha(@vk.VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR) // OPAQUE
  swci.set_presentMode(@vk.VK_PRESENT_MODE_FIFO_KHR) // FIFO
  swci.set_clipped((1 : UInt32))
  let sc_out = FixedArray::make(1, @vk.VkSwapchainKHR::null())
  let scr = (dfn.vkCreateSwapchainKHR)(dev, swci, @vk.VkAllocationCallbacks::null(), sc_out)
  let swapchain = sc_out[0]
  println("[02-present] vkCreateSwapchainKHR = \{scr}")

  // --- Swap chain images + image views ---
  let ic = FixedArray::make(1, (8 : UInt32))
  let images = FixedArray::make(8, @vk.VkImage::null())
  let _ = (dfn.vkGetSwapchainImagesKHR)(dev, swapchain, ic, images)
  let nimg = ic[0].reinterpret_as_int()
  let mut views_ok = 0
  for i = 0; i < nimg; i = i + 1 {
    let range = @vk.VkImageSubresourceRange::new()
    range.set_aspectMask(@vk.VK_IMAGE_ASPECT_COLOR_BIT) // COLOR
    range.set_baseMipLevel((0 : UInt32))
    range.set_levelCount((1 : UInt32))
    range.set_baseArrayLayer((0 : UInt32))
    range.set_layerCount((1 : UInt32))
    let ivci = @vk.VkImageViewCreateInfo::new()
    ivci.set_image(images[i])
    ivci.set_viewType(@vk.VK_IMAGE_VIEW_TYPE_2D) // 2D
    ivci.set_format(format)
    ivci.set_subresourceRange(range)
    let iv_out = FixedArray::make(1, @vk.VkImageView::null())
    let ivr = (dfn.vkCreateImageView)(dev, ivci, @vk.VkAllocationCallbacks::null(), iv_out)
    if ivr == 0 {
      views_ok = views_ok + 1
    }
    (dfn.vkDestroyImageView)(dev, iv_out[0], @vk.VkAllocationCallbacks::null())
    ivci.free()
    range.free()
  }
  println("[02-present] swapchain images = \{nimg}, image views created = \{views_ok}")

  // --- Cleanup ---
  (dfn.vkDestroySwapchainKHR)(dev, swapchain, @vk.VkAllocationCallbacks::null())
  (ifn.vkDestroySurfaceKHR)(inst, surface, @vk.VkAllocationCallbacks::null())
  (dfn.vkDestroyDevice)(dev, @vk.VkAllocationCallbacks::null())
  (ifn.vkDestroyInstance)(inst, @vk.VkAllocationCallbacks::null())
  @win.destroy(win)
  @win.terminate()
  swci.free()
  extent.free()
  formats.free()
  caps.free()
  dci.free()
  qci.free()
  ici.free()
  app.free()
  // Judge on the swapchain/image-view results instead of printing OK unconditionally.
  if ir == 0 && dr == 0 && scr == 0 && nimg > 0 && views_ok == nimg {
    println("[02-present] OK — presentation chapter validated")
  } else {
    println("[02-present] FAIL — instance=\{ir} device=\{dr} swapchain=\{scr} images=\{nimg} views=\{views_ok}")
  }
}