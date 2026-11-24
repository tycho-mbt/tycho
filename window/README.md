# laplaceliu/tycho_window

Thin pure-MoonBit native windowing, input event queue, and Vulkan WSI surface wrapper across **Linux** (Wayland + X11 via `dlopen`), **Windows** (Win32 via `LoadLibraryA`), and **macOS** (Cocoa + `CAMetalLayer` via `dlopen`) — zero GLFW, `libwayland-dev`, `libx11-dev`, or link-flag dependencies.

## Features

- **Cross-platform window backends** (zero native `cc-link-flags` required):
  - **Linux**: automatic `WAYLAND_DISPLAY` detection (`xdg-shell`, `zxdg_decoration_manager_v1`, `zwp_pointer_constraints_v1`, `zwp_relative_pointer_manager_v1`, `libxkbcommon`, `libwayland-cursor` via `dlopen`) with `dlopen("libX11.so.6")` Xlib fallback; override with `TYCHO_WINDOW_BACKEND=wayland|x11`
  - **Windows**: pure-C Win32 (`user32.dll` via `LoadLibraryA`), HiDPI `GetDpiForWindow` scaling, borderless fullscreen, cursor lock/hide, `VK_KHR_win32_surface`
  - **macOS**: pure-C Cocoa (`NSWindow`) + `CAMetalLayer` via `libobjc.A.dylib` runtime dispatch, Retina `backingScaleFactor`, `VK_EXT_metal_surface`
- Window lifecycle: `initialize`, `create`, `destroy`, `terminate`, `should_close`, `set_should_close`, `set_title`, `is_wayland`
- Resize & geometry: `width`, `height`, `framebuffer_size`, `take_resized`, `content_scale`, `set_fullscreen`, `is_fullscreen`
- Event & input queries: `poll`, `poll_events` (`Event::CloseRequested`, `Resized`, `KeyDown`, `KeyUp`, `MouseMove`, `MouseDown`, `MouseUp`, `MouseScroll`, `FocusChanged`), `mouse_pos`, `is_mouse_down`, `set_cursor_mode`, KeySym constants (`KEY_ESCAPE`, `KEY_W`, `KEY_A`, `KEY_S`, `KEY_D`, etc.)
- Vulkan WSI surface creation: `create_surface` (`VK_KHR_wayland_surface`, `VK_KHR_xlib_surface`, `VK_KHR_win32_surface`, `VK_EXT_metal_surface`), `surface_extensions`, `platform`

## Link flags

None required! Downstream `moon.pkg` files only need to import `laplaceliu/tycho_window`.

## Previewing Wayland on X11

From the repository root, `./tools/run-wayland.sh <example> --window` automatically launches a nested `weston --backend=x11-backend.so` window (if no Wayland compositor is running) and sets `WAYLAND_DISPLAY`, `XDG_RUNTIME_DIR`, `TYCHO_WINDOW_BACKEND=wayland`, and `VK_DRIVER_FILES` (defaulting to `lavapipe` inside nested Weston). See [51-wayland-window](../examples/51-wayland-window/README.md) for manual `weston` steps.
