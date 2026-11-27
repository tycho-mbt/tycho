// Tycho windowing: thin pure-MoonBit native window + Vulkan WSI surface wrapper.
// On Linux, backed directly by Xlib (libX11) — zero GLFW dependency.
// Users call @win.* and never write C or X11/WSI boilerplate.

extern "c" fn win_init_ffi() -> Int32 = "tycho_win_init"

extern "c" fn win_terminate_ffi() = "tycho_win_terminate"

extern "c" fn win_create_ffi(w : Int, h : Int, title : UInt64) -> UInt64 = "tycho_win_create"

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

extern "c" fn win_set_bg_color_ffi(win : UInt64, r : Int32, g : Int32, b : Int32) = "tycho_win_set_bg_color"

extern "c" fn win_has_pending_sync_ffi(win : UInt64) -> Int32 = "tycho_win_has_pending_sync"

extern "c" fn win_finish_sync_ffi(win : UInt64) = "tycho_win_finish_sync"

extern "c" fn win_wait_events_ffi(timeout_ms : Int32) = "tycho_win_wait_events"

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
/// Logical key identity. The platform layer reports X11 keysyms for historical
/// reasons; `from_keysym` / `to_keysym` translate losslessly, and keys the enum
/// does not name are preserved as `Unknown(keysym)`.
#derive(Eq, Debug)
pub(all) enum KeyCode {
  Escape
  Return
  Tab
  Backspace
  Space
  Left
  Up
  Right
  Down
  Home
  End
  PageUp
  PageDown
  Insert
  Delete
  Num0
  Num1
  Num2
  Num3
  Num4
  Num5
  Num6
  Num7
  Num8
  Num9
  A
  B
  C
  D
  E
  F
  G
  H
  I
  J
  K
  L
  M
  N
  O
  P
  Q
  R
  S
  T
  U
  V
  W
  X
  Y
  Z
  F1
  F2
  F3
  F4
  F5
  F6
  F7
  F8
  F9
  F10
  F11
  F12
  LShift
  RShift
  LCtrl
  RCtrl
  LAlt
  RAlt
  Unknown(Int)
}

///|
pub fn KeyCode::from_keysym(sym : Int) -> KeyCode {
  match sym {
    0xff1b => Escape
    0xff0d => Return
    0xff09 => Tab
    0xff08 => Backspace
    0x0020 => Space
    0xff51 => Left
    0xff52 => Up
    0xff53 => Right
    0xff54 => Down
    0xff50 => Home
    0xff57 => End
    0xff55 => PageUp
    0xff56 => PageDown
    0xff63 => Insert
    0xffff => Delete
    0x0030 => Num0
    0x0031 => Num1
    0x0032 => Num2
    0x0033 => Num3
    0x0034 => Num4
    0x0035 => Num5
    0x0036 => Num6
    0x0037 => Num7
    0x0038 => Num8
    0x0039 => Num9
    0x0061 => A
    0x0062 => B
    0x0063 => C
    0x0064 => D
    0x0065 => E
    0x0066 => F
    0x0067 => G
    0x0068 => H
    0x0069 => I
    0x006a => J
    0x006b => K
    0x006c => L
    0x006d => M
    0x006e => N
    0x006f => O
    0x0070 => P
    0x0071 => Q
    0x0072 => R
    0x0073 => S
    0x0074 => T
    0x0075 => U
    0x0076 => V
    0x0077 => W
    0x0078 => X
    0x0079 => Y
    0x007a => Z
    0xffbe => F1
    0xffbf => F2
    0xffc0 => F3
    0xffc1 => F4
    0xffc2 => F5
    0xffc3 => F6
    0xffc4 => F7
    0xffc5 => F8
    0xffc6 => F9
    0xffc7 => F10
    0xffc8 => F11
    0xffc9 => F12
    0xffe1 => LShift
    0xffe2 => RShift
    0xffe3 => LCtrl
    0xffe4 => RCtrl
    0xffe9 => LAlt
    0xffea => RAlt
    other => Unknown(other)
  }
}

///|
pub fn KeyCode::to_keysym(self : KeyCode) -> Int {
  match self {
    Escape => 0xff1b
    Return => 0xff0d
    Tab => 0xff09
    Backspace => 0xff08
    Space => 0x0020
    Left => 0xff51
    Up => 0xff52
    Right => 0xff53
    Down => 0xff54
    Home => 0xff50
    End => 0xff57
    PageUp => 0xff55
    PageDown => 0xff56
    Insert => 0xff63
    Delete => 0xffff
    Num0 => 0x0030
    Num1 => 0x0031
    Num2 => 0x0032
    Num3 => 0x0033
    Num4 => 0x0034
    Num5 => 0x0035
    Num6 => 0x0036
    Num7 => 0x0037
    Num8 => 0x0038
    Num9 => 0x0039
    A => 0x0061
    B => 0x0062
    C => 0x0063
    D => 0x0064
    E => 0x0065
    F => 0x0066
    G => 0x0067
    H => 0x0068
    I => 0x0069
    J => 0x006a
    K => 0x006b
    L => 0x006c
    M => 0x006d
    N => 0x006e
    O => 0x006f
    P => 0x0070
    Q => 0x0071
    R => 0x0072
    S => 0x0073
    T => 0x0074
    U => 0x0075
    V => 0x0076
    W => 0x0077
    X => 0x0078
    Y => 0x0079
    Z => 0x007a
    F1 => 0xffbe
    F2 => 0xffbf
    F3 => 0xffc0
    F4 => 0xffc1
    F5 => 0xffc2
    F6 => 0xffc3
    F7 => 0xffc4
    F8 => 0xffc5
    F9 => 0xffc6
    F10 => 0xffc7
    F11 => 0xffc8
    F12 => 0xffc9
    LShift => 0xffe1
    RShift => 0xffe2
    LCtrl => 0xffe3
    RCtrl => 0xffe4
    LAlt => 0xffe9
    RAlt => 0xffea
    Unknown(sym) => sym
  }
}

///|
/// Keyboard modifiers, decoded from the X11-compatible mask the platform layer
/// reports (Shift=1, Lock=2, Ctrl=4, Mod1/Alt=8, Mod4/Super=64).
#derive(Eq, Debug)
pub(all) struct Modifiers {
  shift : Bool
  ctrl : Bool
  alt : Bool
  super_key : Bool
}

///|
pub fn Modifiers::new(
  shift? : Bool = false,
  ctrl? : Bool = false,
  alt? : Bool = false,
  super_key? : Bool = false,
) -> Modifiers {
  { shift, ctrl, alt, super_key }
}

///|
pub fn Modifiers::none() -> Modifiers {
  { shift: false, ctrl: false, alt: false, super_key: false }
}

///|
pub fn Modifiers::from_bits(bits : Int) -> Modifiers {
  {
    shift: (bits & 1) != 0,
    ctrl: (bits & 4) != 0,
    alt: (bits & 8) != 0,
    super_key: (bits & 64) != 0,
  }
}

///|
pub fn Modifiers::bits(self : Modifiers) -> Int {
  (if self.shift { 1 } else { 0 }) |
  (if self.ctrl { 4 } else { 0 }) |
  (if self.alt { 8 } else { 0 }) |
  (if self.super_key { 64 } else { 0 })
}

///|
pub fn Modifiers::is_empty(self : Modifiers) -> Bool {
  !self.shift && !self.ctrl && !self.alt && !self.super_key
}

///|
#derive(Eq, Debug)
pub(all) enum MouseButton {
  Left
  Right
  Middle
  Other(Int)
}

///|
///|
/// Platform button index (X11 numbering: 1 = left, 2 = middle, 3 = right,
/// 8/9 = side buttons).
pub fn MouseButton::from_index(index : Int) -> MouseButton {
  match index {
    1 => Left
    2 => Middle
    3 => Right
    other => Other(other)
  }
}

///|
pub fn MouseButton::index(self : MouseButton) -> Int {
  match self {
    Left => 1
    Middle => 2
    Right => 3
    Other(i) => i
  }
}

///|
#derive(Eq, Debug)
pub(all) enum Event {
  CloseRequested
  Resized(Int, Int)
  KeyDown(KeyCode, Modifiers)
  KeyUp(KeyCode, Modifiers)
  MouseMove(Int, Int)
  MouseDown(MouseButton, Int, Int)
  MouseUp(MouseButton, Int, Int)
  MouseScroll(Int, Int)
  FocusChanged(Bool)
  TextInput(String)
  // IME composition: preedit chars arrive one at a time after a clear, then
  // either commit chars or a cancel. The host feeds these into
  // TextController::set_preedit/commit_preedit/clear_preedit.
  ImePreedit(String)
  ImePreeditClear
  ImeCommit(String)
  ImeCancel
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
pub fn create(w : Int, h : Int, title : String) -> UInt64 {
  win_create_ffi(w, h, @vk.cstr(title))
}

///|
pub fn destroy(win : UInt64) -> Unit {
  win_destroy_ffi(win)
}

///|
pub suberror WindowError {
  InitFailed(String)
  CreateFailed(String)
}

///|
pub(all) struct WindowDesc {
  width : Int
  height : Int
  title : String
}

///|
pub fn WindowDesc::new(width : Int, height : Int, title : String) -> WindowDesc {
  { width, height, title }
}

///|
/// Opaque native window handle. Every window, input, and clipboard operation is
/// a method here; the raw `UInt64` never leaves the module unless explicitly
/// requested with `handle()`.
pub struct Window {
  priv handle : UInt64
}

///|
/// Idempotent platform initialization. `Window::new` calls this for you.
pub fn Window::init() -> Unit raise WindowError {
  if initialize() == 0 {
    raise WindowError::InitFailed("could not initialise the platform window layer")
  }
}

///|
pub fn Window::new(desc : WindowDesc) -> Window raise WindowError {
  Window::init()
  let title = @vk.cstr(desc.title)
  let handle = win_create_ffi(desc.width, desc.height, title)
  @vk.free_ptr(title)
  if handle == 0 {
    raise WindowError::CreateFailed(desc.title)
  }
  { handle, }
}

///|
/// Wraps a handle produced elsewhere (e.g. a swapchain that already owns one).
pub fn Window::from_handle(handle : UInt64) -> Window {
  { handle, }
}

///|
pub fn Window::handle(self : Window) -> UInt64 {
  self.handle
}

///|
pub fn Window::destroy(self : Window) -> Unit {
  win_destroy_ffi(self.handle)
}

///|
pub fn Window::width(self : Window) -> Int {
  win_width_ffi(self.handle).to_int()
}

///|
pub fn Window::height(self : Window) -> Int {
  win_height_ffi(self.handle).to_int()
}

///|
pub fn Window::framebuffer_size(self : Window) -> (Int, Int) {
  (self.width(), self.height())
}

///|
pub fn Window::should_close(self : Window) -> Bool {
  win_should_close_ffi(self.handle) != 0
}

///|
pub fn Window::set_should_close(self : Window, close : Bool) -> Unit {
  win_set_should_close_ffi(self.handle, if close { (1 : Int32) } else { (0 : Int32) })
}

///|
pub fn Window::take_resized(self : Window) -> Bool {
  win_take_resized_ffi(self.handle) != 0
}

///|
pub fn Window::native_handle(self : Window) -> UInt64 {
  win_handle_ffi(self.handle)
}

///|
pub fn Window::set_title(self : Window, title : String) -> Unit {
  let s = @vk.cstr(title)
  win_set_title_ffi(self.handle, s)
  @vk.free_ptr(s)
}

///|
pub fn Window::set_cursor_mode(self : Window, mode : CursorMode) -> Unit {
  set_cursor_mode(self.handle, mode)
}

///|
pub fn Window::set_cursor_shape(self : Window, shape : CursorShape) -> Unit {
  set_cursor_shape(self.handle, shape)
}

///|
pub fn Window::set_clipboard_text(self : Window, text : String) -> Unit {
  set_clipboard_text(self.handle, text)
}

///|
pub fn Window::clipboard_text(self : Window) -> String {
  clipboard_text(self.handle)
}

///|
pub fn Window::set_fullscreen(self : Window, fullscreen : Bool) -> Unit {
  set_fullscreen(self.handle, fullscreen)
}

///|
pub fn Window::is_fullscreen(self : Window) -> Bool {
  is_fullscreen(self.handle)
}

///|
pub fn Window::content_scale(self : Window) -> Double {
  content_scale(self.handle)
}

///|
pub fn Window::set_bg_color(self : Window, r : Int, g : Int, b : Int) -> Unit {
  set_bg_color(self.handle, r, g, b)
}

///|
pub fn Window::has_pending_sync(self : Window) -> Bool {
  has_pending_sync(self.handle)
}

///|
pub fn Window::finish_sync(self : Window) -> Unit {
  finish_sync(self.handle)
}

///|
pub fn Window::mouse_pos(self : Window) -> (Double, Double) {
  mouse_pos(self.handle)
}

///|
pub fn Window::is_mouse_down(self : Window, button : MouseButton) -> Bool {
  is_mouse_down(self.handle, button)
}

///|
pub fn Window::poll_events(self : Window) -> Array[Event] {
  poll_events(self.handle)
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
/// The raw native window handle: `HWND` on Windows, `Window` (X11) on Linux and
/// the `CAMetalLayer` pointer on macOS. Needed by backends that create their own
/// swapchain, e.g. DXGI's `CreateSwapChainForHwnd`.
pub fn native_handle(win : UInt64) -> UInt64 {
  win_handle_ffi(win)
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
pub fn set_bg_color(win : UInt64, r : Int, g : Int, b : Int) -> Unit {
  win_set_bg_color_ffi(win, r, g, b)
}

///|
pub fn has_pending_sync(win : UInt64) -> Bool {
  win_has_pending_sync_ffi(win) != 0
}

///|
pub fn finish_sync(win : UInt64) -> Unit {
  win_finish_sync_ffi(win)
}

///|
pub fn wait_events(timeout_ms : Int) -> Unit {
  win_wait_events_ffi(timeout_ms)
}

///|
pub fn mouse_pos(win : UInt64) -> (Double, Double) {
  (win_mouse_x_ffi(win), win_mouse_y_ffi(win))
}

///|
pub fn is_mouse_down(win : UInt64, button : MouseButton) -> Bool {
  win_mouse_button_ffi(win, button.index()) != 0
}

///|
pub fn poll() -> Unit {
  win_poll_ffi()
}

///|
fn event_from_code(kind : Int, a : Int, b : Int, c : Int) -> Event {
  match kind {
    1 => Event::CloseRequested
    2 => Event::Resized(a, b)
    3 => Event::KeyDown(KeyCode::from_keysym(a), Modifiers::from_bits(b))
    4 => Event::KeyUp(KeyCode::from_keysym(a), Modifiers::from_bits(b))
    5 => Event::MouseMove(a, b)
    6 => Event::MouseDown(MouseButton::from_index(a), b, c)
    7 => Event::MouseUp(MouseButton::from_index(a), b, c)
    8 => Event::MouseScroll(a, b)
    9 => Event::FocusChanged(a != 0)
    10 => {
      let ch = Int::unsafe_to_char(a)
      Event::TextInput(ch.to_string())
    }
    11 => {
      let ch = Int::unsafe_to_char(a)
      Event::ImePreedit(ch.to_string())
    }
    12 => Event::ImePreeditClear
    13 => {
      let ch = Int::unsafe_to_char(a)
      Event::ImeCommit(ch.to_string())
    }
    14 => Event::ImeCancel
    _ => Event::CloseRequested
  }
}

///|
pub fn poll_events(win : UInt64) -> Array[Event] {
  win_poll_ffi()
  let out : Array[Event] = []
  let buf : FixedArray[Int32] = FixedArray::make(4, (0 : Int32))
  while win_next_event_ffi(win, buf) != 0 {
    let ev = event_from_code(
      buf[0].to_int(),
      buf[1].to_int(),
      buf[2].to_int(),
      buf[3].to_int(),
    )
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
