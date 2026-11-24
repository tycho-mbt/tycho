# laplaceliu/tycho_window

Thin pure-MoonBit native windowing, input event queue, and Vulkan WSI surface wrapper (Linux X11/Xlib + runtime-loaded Wayland — zero GLFW or `libwayland-dev` dependency) for the Tycho graphics stack.

## Features

- Dual Linux display backends: automatic `WAYLAND_DISPLAY` detection (`xdg-shell`, `zxdg_decoration_manager_v1`, `zwp_pointer_constraints_v1`, `zwp_relative_pointer_manager_v1`, `libxkbcommon`, `libwayland-cursor` via `dlopen`) with Xlib fallback; override with `TYCHO_WINDOW_BACKEND=wayland|x11`
- Window lifecycle: `initialize`, `create`, `destroy`, `terminate`, `should_close`, `set_should_close`, `set_title`, `is_wayland`
- Resize & geometry: `width`, `height`, `framebuffer_size`, `take_resized`, `content_scale`, `set_fullscreen`, `is_fullscreen`
- Event & input queries: `poll`, `poll_events` (`Event::CloseRequested`, `Resized`, `KeyDown`, `KeyUp`, `MouseMove`, `MouseDown`, `MouseUp`, `MouseScroll`, `FocusChanged`), `mouse_pos`, `is_mouse_down`, `set_cursor_mode`, KeySym constants (`KEY_ESCAPE`, `KEY_W`, `KEY_A`, `KEY_S`, `KEY_D`, etc.)
- Vulkan WSI surface creation: `create_surface` (`VK_KHR_wayland_surface` / `VK_KHR_xlib_surface`), `surface_extensions`, `platform`

## Link flags

Link flags are not transitive in MoonBit; the executable package must declare them:

```moonbit
// moon.pkg of your executable
options(
  "link": {
    "native": {
      "cc": "cc",
      "cc-link-flags": "-lX11 -lvulkan",
    },
  },
)
```

Requires `libx11-dev` and a Vulkan 1.3 loader (`libvulkan-dev`) at link time.
