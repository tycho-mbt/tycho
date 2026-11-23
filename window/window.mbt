// Tycho windowing: thin pure-MoonBit native window + Vulkan WSI surface wrapper.
// On Linux, backed directly by Xlib (libX11) — zero GLFW dependency.
// Users call @win.* and never write C or X11/WSI boilerplate.

extern "c" fn win_init_ffi() -> Int32 = "tycho_win_init"

extern "c" fn win_terminate_ffi() = "tycho_win_terminate"

extern "c" fn win_create_ffi(w : Int32, h : Int32, title : UInt64) -> UInt64 = "tycho_win_create"

extern "c" fn win_destroy_ffi(win : UInt64) = "tycho_win_destroy"

extern "c" fn win_should_close_ffi(win : UInt64) -> Int32 = "tycho_win_should_close"

extern "c" fn win_poll_ffi() = "tycho_win_poll"

extern "c" fn win_time_ffi() -> Double = "tycho_win_time"

extern "c" fn win_display_ffi(win : UInt64) -> UInt64 = "tycho_win_display"

extern "c" fn win_handle_ffi(win : UInt64) -> UInt64 = "tycho_win_handle"

///|
pub fn initialize() -> Int32 {
  win_init_ffi()
}

///|
pub fn terminate() -> Unit {
  win_terminate_ffi()
}

///|
pub fn create(w : Int32, h : Int32, title : String) -> UInt64 {
  win_create_ffi(w, h, @vk.cstr(title))
}

///|
pub fn destroy(win : UInt64) -> Unit {
  win_destroy_ffi(win)
}

///|
pub fn should_close(win : UInt64) -> Int32 {
  win_should_close_ffi(win)
}

///|
pub fn poll() -> Unit {
  win_poll_ffi()
}

///|
pub fn time() -> Double {
  win_time_ffi()
}

///|
// Creates a Vulkan surface for the window using pure MoonBit @vk structs &
// InstanceFn dispatch (VK_KHR_xlib_surface on Linux).
pub fn create_surface(inst : @vk.VkInstance, win : UInt64) -> @vk.VkSurfaceKHR {
  let ifn = @vk.InstanceFn::load(inst)
  let ci = @vk.VkXlibSurfaceCreateInfoKHR::new()
  ci.set_dpy(win_display_ffi(win))
  ci.set_window(win_handle_ffi(win))
  let out = FixedArray::make(1, @vk.VkSurfaceKHR::null())
  let _ = (ifn.vkCreateXlibSurfaceKHR)(
    inst,
    ci,
    @vk.VkAllocationCallbacks::null(),
    out,
  )
  ci.free()
  out[0]
}

///|
pub(all) enum Platform {
  Linux
  Windows
  MacOS
}

extern "c" fn window_platform_ffi() -> Int = "tycho_window_platform"

///|
pub fn platform() -> Platform {
  match window_platform_ffi() {
    1 => Platform::Windows
    2 => Platform::MacOS
    _ => Platform::Linux
  }
}

///|
// Instance extensions needed to present to a native window on this platform.
pub fn surface_extensions() -> FixedArray[String] {
  match platform() {
    Platform::Windows => {
      let a = FixedArray::make(2, "")
      a[0] = "VK_KHR_surface"
      a[1] = "VK_KHR_win32_surface"
      a
    }
    Platform::MacOS => {
      let a = FixedArray::make(3, "")
      a[0] = "VK_KHR_surface"
      a[1] = "VK_EXT_metal_surface"
      a[2] = "VK_KHR_portability_enumeration"
      a
    }
    Platform::Linux => {
      let a = FixedArray::make(3, "")
      a[0] = "VK_KHR_surface"
      a[1] = "VK_KHR_xlib_surface"
      a[2] = "VK_KHR_xcb_surface"
      a
    }
  }
}
