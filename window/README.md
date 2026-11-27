# laplaceliu/tycho_window

Thin pure-MoonBit native windowing, input event queue, and Vulkan WSI surface wrapper across **Linux** (Wayland + X11 via `dlopen`), **Windows** (Win32 via `LoadLibraryA`), and **macOS** (Cocoa + `CAMetalLayer` via `dlopen`) — zero GLFW, `libwayland-dev`, `libx11-dev`, or link-flag dependencies.

## Features

- **Cross-platform window backends** (zero native `cc-link-flags` required):
  - **Linux**: automatic `WAYLAND_DISPLAY` detection (`xdg-shell`, `zxdg_decoration_manager_v1`, `zwp_pointer_constraints_v1`, `zwp_relative_pointer_manager_v1`, `libxkbcommon`, `libwayland-cursor` via `dlopen`) with `dlopen("libX11.so.6")` Xlib fallback; override with `TYCHO_WINDOW_BACKEND=wayland|x11`
  - **Windows**: pure-C Win32 (`user32.dll` via `LoadLibraryA`), HiDPI `GetDpiForWindow` scaling, borderless fullscreen, cursor lock/hide, `VK_KHR_win32_surface`
  - **macOS**: pure-C Cocoa (`NSWindow`) + `CAMetalLayer` via `libobjc.A.dylib` runtime dispatch, Retina `backingScaleFactor`, `VK_EXT_metal_surface`
- **Typed API first**: `Window::new(WindowDesc(size, title))` / `Window::init()` raise `WindowError` (`InitFailed` / `CreateFailed`), and every window, input, cursor, fullscreen, and clipboard operation is a `Window` method — the raw `UInt64` handle never appears in the public surface unless asked for with `Window::handle()`.
- Window lifecycle: `Window::new`, `Window::destroy`, `Window::should_close`, `Window::set_should_close`, `Window::set_title`, `Window::init`, `terminate`, `is_wayland`
- Resize & geometry: `Window::width`, `Window::height`, `Window::framebuffer_size`, `Window::take_resized`, `Window::content_scale`, `Window::set_fullscreen`, `Window::is_fullscreen`
- Event & input queries: `Window::poll_events` returning typed events — `KeyDown(KeyCode, Modifiers)` / `KeyUp(KeyCode, Modifiers)` / `MouseDown(MouseButton, x, y)` / `MouseUp(MouseButton, x, y)` / `MouseMove` / `MouseScroll` / `Resized` / `FocusChanged` / `TextInput` / IME — plus `wait_events`, `Window::mouse_pos`, `Window::is_mouse_down(MouseButton)`, `Window::set_cursor_mode`, `Window::set_cursor_shape`, `time`.
- `KeyCode` (letters, digits, arrows, Home/End/Insert/Delete, F1–F12, modifiers, `Unknown(keysym)`) converts losslessly with `KeyCode::from_keysym` / `to_keysym`; `Modifiers` exposes `shift` / `ctrl` / `alt` / `super_key` with `bits()` for the legacy X11 mask.
- IME:
  - X11 uses XIM (`XFilterEvent` + preedit draw callback + `Xutf8LookupString`) and emits `Event::ImePreedit` / `ImePreeditClear` / `ImeCommit` / `ImeCancel`.
  - Wayland binds `zwp_text_input_manager_v3` / `zwp_text_input_v3` (hand-written protocol tables) for native preedit/commit; Unicode keymap commits still work as a fallback.
  - Hosts feed these into `ui.TextController::set_preedit` / `commit_preedit` / `clear_preedit`.
- Clipboard & appearance: `set_clipboard_text` / `clipboard_text`, `set_bg_color`
- Vulkan WSI surface creation: `create_surface` (`VK_KHR_wayland_surface`, `VK_KHR_xlib_surface`, `VK_KHR_win32_surface`, `VK_EXT_metal_surface`), `surface_extensions`, `platform`

## Link flags

None required! Downstream `moon.pkg` files only need to import `laplaceliu/tycho_window`.

## Previewing Wayland on X11

From the repository root, `./tools/run-wayland.sh <example> --window` automatically launches a nested `weston --backend=x11-backend.so` window (if no Wayland compositor is running) and sets `WAYLAND_DISPLAY`, `XDG_RUNTIME_DIR`, `TYCHO_WINDOW_BACKEND=wayland`, and `VK_DRIVER_FILES` (defaulting to `lavapipe` inside nested Weston). See [window/wayland](../examples/window/wayland/README.md) for manual `weston` steps.
