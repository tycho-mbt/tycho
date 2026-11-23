# laplaceliu/tycho_window

Thin pure-MoonBit native windowing, input event queue, and Vulkan WSI surface wrapper (Xlib on Linux — zero GLFW dependency) for the Tycho graphics stack.

## Features

- Window lifecycle: `initialize`, `create`, `destroy`, `terminate`, `should_close`, `set_should_close`, `set_title`
- Resize & geometry: `width`, `height`, `framebuffer_size`, `take_resized`
- Event & input queries: `poll`, `poll_events` (`Event::CloseRequested`, `Resized`, `KeyDown`, `KeyUp`, `MouseMove`, `MouseDown`, `MouseUp`, `MouseScroll`, `FocusChanged`), `mouse_pos`, `is_mouse_down`, X11 KeySym constants (`KEY_ESCAPE`, `KEY_W`, `KEY_A`, `KEY_S`, `KEY_D`, etc.)
- Vulkan WSI surface creation: `create_surface`, `surface_extensions`, `platform`
