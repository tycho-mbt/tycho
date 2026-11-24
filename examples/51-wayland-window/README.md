# 51-wayland-window

Verifies the runtime-loaded Linux **Wayland** backend (`window_wayland.c`, `xdg-shell`, `zxdg_decoration_manager_v1`, `zwp_pointer_constraints_v1`, `zwp_relative_pointer_manager_v1`, and `VK_KHR_wayland_surface`).

When a Wayland compositor is active (`WAYLAND_DISPLAY` set or `TYCHO_WINDOW_BACKEND=wayland`), it opens an `xdg_toplevel` window, exercises title updates, HiDPI `content_scale`, `CursorMode` (`Hidden`/`Locked`/`Normal`), fullscreen toggles, and swapchain presentation + readback with zero validation errors. On X11-only sessions without a Wayland compositor, it reports `SKIP`.

## Run

```bash
WAYLAND_DISPLAY=wayland-0 TYCHO_WINDOW_BACKEND=wayland \
  ./_build/native/debug/build/laplaceliu/tycho_vulkan_examples/51-wayland-window/51-wayland-window.exe
```

