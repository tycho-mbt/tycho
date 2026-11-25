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

extern "c" fn win_set_cursor_mode_ffi(win : UInt64, mode : Int32) = "tycho_win_set_cursor_mode"

extern "c" fn win_set_cursor_shape_ffi(win : UInt64, shape : Int32) = "tycho_win_set_cursor_shape"

extern "c" fn win_set_clipboard_ffi(win : UInt64, text : UInt64) = "tycho_win_set_clipboard"

extern "c" fn win_get_clipboard_ffi(win : UInt64) -> UInt64 = "tycho_win_get_clipboard"

extern "c" fn win_set_fullscreen_ffi(win : UInt64, fs : Int32) = "tycho_win_set_fullscreen"

extern "c" fn win_is_fullscreen_ffi(win : UInt64) -> Int32 = "tycho_win_is_fullscreen"

extern "c" fn win_content_scale_ffi(win : UInt64) -> Double = "tycho_win_content_scale"

extern "c" fn win_is_wayland_ffi() -> Int32 = "tycho_win_is_wayland"

extern "c" fn xlib_surface_ci_new_ffi(dpy : UInt64, win : UInt64) -> UInt64 = "tycho_xlib_surface_ci_new"

extern "c" fn xlib_surface_ci_free_ffi(p : UInt64) = "tycho_xlib_surface_ci_free"

extern "c" fn wl_surface_ci_new_ffi(dpy : UInt64, surf : UInt64) -> UInt64 = "tycho_wl_surface_ci_new"

extern "c" fn wl_surface_ci_free_ffi(p : UInt64) = "tycho_wl_surface_ci_free"

extern "c" fn win32_surface_ci_new_ffi(hinst : UInt64, hwnd : UInt64) -> UInt64 = "tycho_win32_surface_ci_new"

extern "c" fn win32_surface_ci_free_ffi(p : UInt64) = "tycho_win32_surface_ci_free"

extern "c" fn metal_surface_ci_new_ffi(layer : UInt64) -> UInt64 = "tycho_metal_surface_ci_new"

extern "c" fn metal_surface_ci_free_ffi(p : UInt64) = "tycho_metal_surface_ci_free"

///|
pub const KEY_ESCAPE : Int = 0xff1b

///|
pub const KEY_RETURN : Int = 0xff0d

///|
pub const KEY_TAB : Int = 0xff09

///|
pub const KEY_BACKSPACE : Int = 0xff08

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
pub const KEY_0 : Int = 0x0030

///|
pub const KEY_1 : Int = 0x0031

///|
pub const KEY_2 : Int = 0x0032

///|
pub const KEY_3 : Int = 0x0033

///|
pub const KEY_4 : Int = 0x0034

///|
pub const KEY_5 : Int = 0x0035

///|
pub const KEY_6 : Int = 0x0036

///|
pub const KEY_7 : Int = 0x0037

///|
pub const KEY_8 : Int = 0x0038

///|
pub const KEY_9 : Int = 0x0039

///|
pub const KEY_A : Int = 0x0061

///|
pub const KEY_B : Int = 0x0062

///|
pub const KEY_C : Int = 0x0063

///|
pub const KEY_D : Int = 0x0064

///|
pub const KEY_E : Int = 0x0065

///|
pub const KEY_F : Int = 0x0066

///|
pub const KEY_G : Int = 0x0067

///|
pub const KEY_H : Int = 0x0068

///|
pub const KEY_I : Int = 0x0069

///|
pub const KEY_J : Int = 0x006a

///|
pub const KEY_K : Int = 0x006b

///|
pub const KEY_L : Int = 0x006c

///|
pub const KEY_M : Int = 0x006d

///|
pub const KEY_N : Int = 0x006e

///|
pub const KEY_O : Int = 0x006f

///|
pub const KEY_P : Int = 0x0070

///|
pub const KEY_Q : Int = 0x0071

///|
pub const KEY_R : Int = 0x0072

///|
pub const KEY_S : Int = 0x0073

///|
pub const KEY_T : Int = 0x0074

///|
pub const KEY_U : Int = 0x0075

///|
pub const KEY_V : Int = 0x0076

///|
pub const KEY_W : Int = 0x0077

///|
pub const KEY_X : Int = 0x0078

///|
pub const KEY_Y : Int = 0x0079

///|
pub const KEY_Z : Int = 0x007a

///|
pub const KEY_F1 : Int = 0xffbe

///|
pub const KEY_F2 : Int = 0xffbf

///|
pub const KEY_F3 : Int = 0xffc0

///|
pub const KEY_F4 : Int = 0xffc1

///|
pub const KEY_F5 : Int = 0xffc2

///|
pub const KEY_F6 : Int = 0xffc3

///|
pub const KEY_F7 : Int = 0xffc4

///|
pub const KEY_F8 : Int = 0xffc5

///|
pub const KEY_F9 : Int = 0xffc6

///|
pub const KEY_F10 : Int = 0xffc7

///|
pub const KEY_F11 : Int = 0xffc8

///|
pub const KEY_F12 : Int = 0xffc9

///|
pub const KEY_LSHIFT : Int = 0xffe1

///|
pub const KEY_RSHIFT : Int = 0xffe2

///|
pub const KEY_LCTRL : Int = 0xffe3

///|
pub const KEY_RCTRL : Int = 0xffe4

///|
pub const KEY_LALT : Int = 0xffe9

///|
pub const KEY_RALT : Int = 0xffea

///|
#derive(Eq, Debug)
pub(all) enum CursorMode {
  Normal
  Hidden
  Locked
}

///|
#derive(Eq, Debug)
pub(all) enum CursorShape {
  Default
  Pointer
  IBeam
  Crosshair
  HResize
  VResize
}

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
  MouseScroll(Int, Int)
  FocusChanged(Bool)
  TextInput(String)
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
pub fn set_cursor_mode(win : UInt64, mode : CursorMode) -> Unit {
  let m : Int32 = match mode {
    CursorMode::Normal => 0
    CursorMode::Hidden => 1
    CursorMode::Locked => 2
  }
  win_set_cursor_mode_ffi(win, m)
}

///|
pub fn set_cursor_shape(win : UInt64, shape : CursorShape) -> Unit {
  let s : Int32 = match shape {
    CursorShape::Default => 0
    CursorShape::Pointer => 1
    CursorShape::IBeam => 2
    CursorShape::Crosshair => 3
    CursorShape::HResize => 4
    CursorShape::VResize => 5
  }
  win_set_cursor_shape_ffi(win, s)
}

///|
pub fn set_clipboard_text(win : UInt64, text : String) -> Unit {
  let s = @vk.cstr(text)
  win_set_clipboard_ffi(win, s)
  @vk.free_ptr(s)
}

///|
pub fn clipboard_text(win : UInt64) -> String {
  let ptr = win_get_clipboard_ffi(win)
  if ptr == (0 : UInt64) {
    ""
  } else {
    let s = @vk.read_cstr(ptr)
    @vk.free_ptr(ptr)
    s
  }
}

///|
pub fn set_fullscreen(win : UInt64, fullscreen : Bool) -> Unit {
  win_set_fullscreen_ffi(win, if fullscreen { (1 : Int32) } else { (0 : Int32) })
}

///|
pub fn is_fullscreen(win : UInt64) -> Bool {
  win_is_fullscreen_ffi(win) != 0
}

///|
pub fn content_scale(win : UInt64) -> Double {
  win_content_scale_ffi(win)
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
      8 => Event::MouseScroll(a, b)
      9 => Event::FocusChanged(a != 0)
      10 => {
        let ch = Int::unsafe_to_char(a)
        Event::TextInput(ch.to_string())
      }
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
pub fn is_wayland() -> Bool {
  win_is_wayland_ffi() != 0
}

///|
// Creates a Vulkan surface for the window using pure MoonBit @vk structs &
// InstanceFn dispatch across Linux (Wayland/Xlib), Windows (Win32), and macOS (Metal).
pub fn create_surface(inst : @vk.VkInstance, win : UInt64) -> @vk.VkSurfaceKHR {
  let ifn = @vk.InstanceFn::load(inst)
  let out = FixedArray::make(1, @vk.VkSurfaceKHR::null())
  match platform() {
    Platform::Windows => {
      let ci_ptr = win32_surface_ci_new_ffi(win_display_ffi(win), win_handle_ffi(win))
      let ci = @vk.VkWin32SurfaceCreateInfoKHR::from_ptr(ci_ptr)
      let _ = (ifn.vkCreateWin32SurfaceKHR)(
        inst,
        ci,
        @vk.VkAllocationCallbacks::null(),
        out,
      )
      win32_surface_ci_free_ffi(ci_ptr)
    }
    Platform::MacOS => {
      let ci_ptr = metal_surface_ci_new_ffi(win_handle_ffi(win))
      let ci = @vk.VkMetalSurfaceCreateInfoEXT::from_ptr(ci_ptr)
      let _ = (ifn.vkCreateMetalSurfaceEXT)(
        inst,
        ci,
        @vk.VkAllocationCallbacks::null(),
        out,
      )
      metal_surface_ci_free_ffi(ci_ptr)
    }
    Platform::Linux =>
      if win_is_wayland_ffi() != 0 {
        let ci_ptr = wl_surface_ci_new_ffi(win_display_ffi(win), win_handle_ffi(win))
        let ci = @vk.VkWaylandSurfaceCreateInfoKHR::from_ptr(ci_ptr)
        let _ = (ifn.vkCreateWaylandSurfaceKHR)(
          inst,
          ci,
          @vk.VkAllocationCallbacks::null(),
          out,
        )
        wl_surface_ci_free_ffi(ci_ptr)
      } else {
        let ci_ptr = xlib_surface_ci_new_ffi(win_display_ffi(win), win_handle_ffi(win))
        let ci = @vk.VkXlibSurfaceCreateInfoKHR::from_ptr(ci_ptr)
        let _ = (ifn.vkCreateXlibSurfaceKHR)(
          inst,
          ci,
          @vk.VkAllocationCallbacks::null(),
          out,
        )
        xlib_surface_ci_free_ffi(ci_ptr)
      }
  }
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
    Platform::Linux =>
      if win_is_wayland_ffi() != 0 {
        let a = FixedArray::make(2, "")
        a[0] = "VK_KHR_surface"
        a[1] = "VK_KHR_wayland_surface"
        a
      } else {
        let a = FixedArray::make(3, "")
        a[0] = "VK_KHR_surface"
        a[1] = "VK_KHR_xlib_surface"
        a[2] = "VK_KHR_xcb_surface"
        a
      }
  }
}
