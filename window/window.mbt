// Tycho windowing: thin pure-MoonBit native window + Vulkan WSI surface wrapper.
// On Linux, backed directly by Xlib (libX11) — zero GLFW dependency.
// Users call @win.* and never write C or X11/WSI boilerplate.

extern "c" fn win_init_ffi() -> Int32 = "tycho_win_init"

extern "c" fn win_terminate_ffi() = "tycho_win_terminate"

extern "c" fn win_create_ffi(w : Int32, h : Int32, title : UInt64) -> UInt64 = "tycho_win_create"

extern "c" fn win_destroy_ffi(win : UInt64) = "tycho_win_destroy"

extern "c" fn win_should_close_ffi(win : UInt64) -> Int32 = "tycho_win_should_close"

extern "c" fn win_set_should_close_ffi(win : UInt64, v : Int32) = "tycho_win_set_should_close"

extern "c" fn win_width_ffi(win : UInt64) -> Int32 = "tycho_win_width"

extern "c" fn win_height_ffi(win : UInt64) -> Int32 = "tycho_win_height"

extern "c" fn win_take_resized_ffi(win : UInt64) -> Int32 = "tycho_win_take_resized"

extern "c" fn win_set_title_ffi(win : UInt64, title : UInt64) = "tycho_win_set_title"

extern "c" fn win_mouse_x_ffi(win : UInt64) -> Double = "tycho_win_mouse_x"

extern "c" fn win_mouse_y_ffi(win : UInt64) -> Double = "tycho_win_mouse_y"

extern "c" fn win_mouse_button_ffi(win : UInt64, btn : Int32) -> Int32 = "tycho_win_mouse_button"

#borrow(out4)
extern "c" fn win_next_event_ffi(win : UInt64, out4 : FixedArray[Int32]) -> Int32 = "tycho_win_next_event"

extern "c" fn win_poll_ffi() = "tycho_win_poll"

extern "c" fn win_time_ffi() -> Double = "tycho_win_time"

extern "c" fn win_display_ffi(win : UInt64) -> UInt64 = "tycho_win_display"

extern "c" fn win_handle_ffi(win : UInt64) -> UInt64 = "tycho_win_handle"

///|
pub const KEY_ESCAPE : Int = 0xff1b

///|
pub const KEY_RETURN : Int = 0xff0d

///|
pub const KEY_SPACE : Int = 0x0020

///|
pub const KEY_LEFT : Int = 0xff51

///|
pub const KEY_UP : Int = 0xff52

///|
pub const KEY_RIGHT : Int = 0xff53

///|
pub const KEY_DOWN : Int = 0xff54

///|
pub const KEY_W : Int = 0x0077

///|
pub const KEY_A : Int = 0x0061

///|
pub const KEY_S : Int = 0x0073

///|
pub const KEY_D : Int = 0x0064

///|
#derive(Eq, Debug)
pub(all) enum Event {
  CloseRequested
  Resized(Int, Int)
  KeyDown(Int, Int)
  KeyUp(Int, Int)
  MouseMove(Int, Int)
  MouseDown(Int, Int, Int)
  MouseUp(Int, Int, Int)
  MouseScroll(Int)
  FocusChanged(Bool)
}

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
pub fn set_should_close(win : UInt64, close : Bool) -> Unit {
  win_set_should_close_ffi(win, if close { (1 : Int32) } else { (0 : Int32) })
}

///|
pub fn width(win : UInt64) -> Int {
  win_width_ffi(win).to_int()
}

///|
pub fn height(win : UInt64) -> Int {
  win_height_ffi(win).to_int()
}

///|
pub fn framebuffer_size(win : UInt64) -> (Int, Int) {
  (width(win), height(win))
}

///|
pub fn take_resized(win : UInt64) -> Bool {
  win_take_resized_ffi(win) != 0
}

///|
pub fn set_title(win : UInt64, title : String) -> Unit {
  let s = @vk.cstr(title)
  win_set_title_ffi(win, s)
  @vk.free_ptr(s)
}

///|
pub fn mouse_pos(win : UInt64) -> (Double, Double) {
  (win_mouse_x_ffi(win), win_mouse_y_ffi(win))
}

///|
pub fn is_mouse_down(win : UInt64, button : Int) -> Bool {
  win_mouse_button_ffi(win, button) != 0
}

///|
pub fn poll() -> Unit {
  win_poll_ffi()
}

///|
pub fn poll_events(win : UInt64) -> Array[Event] {
  win_poll_ffi()
  let out : Array[Event] = []
  let buf : FixedArray[Int32] = FixedArray::make(4, (0 : Int32))
  while win_next_event_ffi(win, buf) != 0 {
    let kind = buf[0]
    let a = buf[1].to_int()
    let b = buf[2].to_int()
    let c = buf[3].to_int()
    let ev = match kind {
      1 => Event::CloseRequested
      2 => Event::Resized(a, b)
      3 => Event::KeyDown(a, b)
      4 => Event::KeyUp(a, b)
      5 => Event::MouseMove(a, b)
      6 => Event::MouseDown(a, b, c)
      7 => Event::MouseUp(a, b, c)
      8 => Event::MouseScroll(a)
      9 => Event::FocusChanged(a != 0)
      _ => Event::CloseRequested
    }
    out.push(ev)
  }
  out
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
