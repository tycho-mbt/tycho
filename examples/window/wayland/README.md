# window/wayland

Verifies the runtime-loaded Linux **Wayland** backend (`window_wayland.c`, `xdg-shell`, `zxdg_decoration_manager_v1`, `zwp_pointer_constraints_v1`, `zwp_relative_pointer_manager_v1`, and `VK_KHR_wayland_surface`).

When a Wayland compositor is active (`WAYLAND_DISPLAY` set or `TYCHO_WINDOW_BACKEND=wayland`), it opens an `xdg_toplevel` window, exercises title updates, HiDPI `content_scale`, `CursorMode` (`Hidden`/`Locked`/`Normal`), fullscreen toggles, and swapchain presentation + readback with zero validation errors. On X11-only sessions without a Wayland compositor, it reports `SKIP`.

## Quick Run (One Command)

Use `./tools/run-wayland.sh` to automatically start/reuse a nested Weston window on X11 (with `lavapipe`) and run any example under Wayland:

```bash
./tools/run-wayland.sh window/wayland
./tools/run-wayland.sh window/wayland --window
./tools/run-wayland.sh rhi/pbr-showcase --window
```

## Manual Setup on an X11 Desktop

If you want to preview Wayland apps manually on an X11 session using `weston`:

1. Terminal 1 — start a nested Weston compositor inside X11:
   ```bash
   XDG_RUNTIME_DIR=/run/user/$(id -u) weston --backend=x11-backend.so --socket=wl-preview
   ```
2. Terminal 2 — point the example at that Wayland socket (nested Weston uses Mesa/llvmpipe buffers, so select `lavapipe` on NVIDIA X11 hosts):
   ```bash
   VK_DRIVER_FILES=/usr/share/vulkan/icd.d/lvp_icd.x86_64.json \
   XDG_RUNTIME_DIR=/run/user/$(id -u) \
   WAYLAND_DISPLAY=wl-preview \
   TYCHO_WINDOW_BACKEND=wayland \
     ./_build/native/debug/build/laplaceliu/tycho_vulkan_examples/window/wayland/wayland.exe --window
   ```

On a native Wayland desktop session (`WAYLAND_DISPLAY=wayland-0` already active), run directly without `weston` or `VK_DRIVER_FILES`:

```bash
./_build/native/debug/build/laplaceliu/tycho_vulkan_examples/window/wayland/wayland.exe --window
```
