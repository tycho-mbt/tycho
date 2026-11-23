// Example 01 — Setup (following vulkan-tutorial.com/Drawing_a_triangle/Setup).
// Instance + validation layers + physical device + queue families + logical device.
// Pure MoonBit generated binding; validation messages go to stderr.

///|
fn main {
  // --- Instance (with validation layer + debug utils extension) ---
  let app = @vk.VkApplicationInfo::new()
  app.set_pApplicationName(@vk.cstr("Hello Triangle"))
  app.set_applicationVersion((4194304 : UInt32))
  app.set_pEngineName(@vk.cstr("No Engine"))
  app.set_engineVersion((4194304 : UInt32))
  app.set_apiVersion((4194304 : UInt32))
  let ici = @vk.VkInstanceCreateInfo::new()
  ici.set_pApplicationInfo(app)
  ici.set_enabledLayerCount((1 : UInt32))
  ici.set_ppEnabledLayerNames(@vk.cstr_array(["VK_LAYER_KHRONOS_validation"]))
  ici.set_enabledExtensionCount((1 : UInt32))
  ici.set_ppEnabledExtensionNames(@vk.cstr_array(["VK_EXT_debug_utils"]))
  let inst_out = FixedArray::make(1, @vk.VkInstance::null())
  let ir = @vk.vkCreateInstance(ici, @vk.VkAllocationCallbacks::null(), inst_out)
  println("[01-setup] vkCreateInstance = \{ir} (0=VK_SUCCESS)")
  let inst = inst_out[0]
  let ifn = @vk.InstanceFn::load(inst)

  // --- Physical device: enumerate into a preallocated array, pick the first ---
  let pc = FixedArray::make(1, (16 : UInt32))
  let devs = FixedArray::make(16, @vk.VkPhysicalDevice::null())
  let _ = (ifn.vkEnumeratePhysicalDevices)(inst, pc, devs)
  let ndev = pc[0].reinterpret_as_int()
  let phys = devs[0]
  println("[01-setup] physical devices = \{ndev}, picked first")

  // --- Queue families: find a graphics-capable family ---
  let qc = FixedArray::make(1, (0 : UInt32))
  let _ = (ifn.vkGetPhysicalDeviceQueueFamilyProperties)(phys, qc, @vk.VkQueueFamilyProperties::null())
  let nq = qc[0].reinterpret_as_int()
  let qprops = @vk.VkQueueFamilyProperties::array(nq)
  let _ = (ifn.vkGetPhysicalDeviceQueueFamilyProperties)(phys, qc, qprops)
  let mut gfx : Int = -1
  for i = 0; i < nq; i = i + 1 {
    if (qprops.get_queueFlags_at(i) & (1 : UInt32)) != (0 : UInt32) {
      gfx = i
      break
    }
  }
  println("[01-setup] queue families = \{nq}, graphics family = \{gfx}")

  // --- Logical device + graphics queue ---
  let prio = FixedArray::make(1, (1.0 : Float))
  let qci = @vk.VkDeviceQueueCreateInfo::new()
  qci.set_queueFamilyIndex(gfx.reinterpret_as_uint())
  qci.set_queueCount((1 : UInt32))
  qci.set_pQueuePriorities(prio)
  let dci = @vk.VkDeviceCreateInfo::new()
  dci.set_queueCreateInfoCount((1 : UInt32))
  dci.set_pQueueCreateInfos(qci)
  let dev_out = FixedArray::make(1, @vk.VkDevice::null())
  let dr = (ifn.vkCreateDevice)(phys, dci, @vk.VkAllocationCallbacks::null(), dev_out)
  let dev = dev_out[0]
  let dfn = @vk.DeviceFn::load(dev)
  let queue_out = FixedArray::make(1, @vk.VkQueue::null())
  (dfn.vkGetDeviceQueue)(dev, gfx.reinterpret_as_uint(), (0 : UInt32), queue_out)
  println("[01-setup] vkCreateDevice = \{dr}, graphics queue retrieved")

  // --- Cleanup ---
  (dfn.vkDestroyDevice)(dev, @vk.VkAllocationCallbacks::null())
  (ifn.vkDestroyInstance)(inst, @vk.VkAllocationCallbacks::null())
  qprops.free()
  qci.free()
  dci.free()
  ici.free()
  app.free()
  println("[01-setup] OK — setup chapter validated")
}