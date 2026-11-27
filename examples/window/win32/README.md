# window/win32

Verifies the runtime-loaded Windows **Win32** backend (`window_win32.c`, `user32.dll` via `LoadLibraryA`, with `PER_MONITOR_AWARE_V2` DPI awareness) plus `VK_KHR_win32_surface` and the Vulkan swapchain present path.

On Windows it opens a `WS_OVERLAPPEDWINDOW` window, exercises title updates, HiDPI `content_scale`, `CursorMode` (`Hidden`/`Locked`/`Normal`), cursor shapes, a clipboard round-trip (`OpenClipboard` / `SetClipboardData` / `GetClipboardData`), fullscreen toggling, swapchain acquire/present and readback — with zero validation errors. The fullscreen toggle calls `SetWindowPos` over the monitor rect, so the resulting `WM_SIZE` drives the RHI's resize detection and exercises swapchain recreation through `oldSwapchain`; the run fails if the swapchain extent does not follow the window through `480x320 -> monitor extent -> 480x320`.

Non-Windows hosts report `SKIP` (the Linux gate in `tools/run-all.sh` stays green); the code still builds on every platform. The run also reports `SKIP` instead of a fake pass when no Win32 surface can be created or when the desktop refuses the fullscreen resize — as happens on a session-0 CI runner — so a real swapchain regression still fails everywhere else.

## Screenshot

![window/win32 screenshot](./screenshot.png)

## Run

```powershell
moon build --target native examples/window/win32
.\_build\native\debug\build\laplaceliu\tycho_vulkan_examples\window\win32\win32.exe
```

Expected (on a 3440x1440 monitor at 150% scale):

```
[window/win32] OK — Win32 WSI presented 8 frames (480x320 -> fullscreen 3440x1440 -> 480x320, scale=1.5, 0 validation errors)
```

Add `--window` (or set `TYCHO_WINDOW=1`) to keep presenting frames interactively; close the window or press `Esc` to exit.

Add `--screenshot <path>` (or set `TYCHO_SCREENSHOT`) to write the last presented frame as PNG. The
file is saved with `bgra=sc.color_format() == TextureFormat::BGRA8`, because Vulkan presents BGRA8
on most Windows drivers — skipping that flag swaps the red and blue channels in the output.
