# laplaceliu/tycho_window

Thin pure-MoonBit native windowing, input event queue, and Vulkan WSI surface wrapper (Xlib on Linux — zero GLFW dependency) for the Tycho graphics stack.

## Features

- Window lifecycle: `initialize`, `create`, `destroy`, `terminate`, `should_close`, `set_should_close`, `set_title`
- Resize & geometry: `width`, `height`, `framebuffer_size`, `take_resized`
- Event & input queries: `poll`, `poll_events` (`Event::CloseRequested`, `Resized`, `KeyDown`, `KeyUp`, `MouseMove`, `MouseDown`, `MouseUp`, `MouseScroll`, `FocusChanged`), `mouse_pos`, `is_mouse_down`, X11 KeySym constants (`KEY_ESCAPE`, `KEY_W`, `KEY_A`, `KEY_S`, `KEY_D`, etc.)
- Vulkan WSI surface creation: `create_surface`, `surface_extensions`, `platform`

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
