// Native window dispatch & cross-platform WSI glue for laplaceliu/tycho_window.
// On Linux, dispatches at runtime between window_wayland.c and window_x11.c;
// on Windows / macOS, window_win32.c / window_macos.c export tycho_win_* directly.
#include "moonbit.h"
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#if defined(__linux__)
static double g_start_time = 0.0;
static int g_init_done = 0;
static int g_use_wayland = 0;

// Wayland backend functions (window_wayland.c)
extern int tycho_wl_connect(void);
extern uint64_t tycho_wl_display(void);
extern uint64_t tycho_wl_create(int32_t w, int32_t h, const char *title);
extern void tycho_wl_destroy(uint64_t p);
extern void tycho_wl_poll(void);
extern int32_t tycho_wl_should_close(uint64_t p);
extern void tycho_wl_set_should_close(uint64_t p, int32_t v);
extern int32_t tycho_wl_width(uint64_t p);
extern int32_t tycho_wl_height(uint64_t p);
extern int32_t tycho_wl_take_resized(uint64_t p);
extern void tycho_wl_set_title(uint64_t p, const char *title);
extern double tycho_wl_mouse_x(uint64_t p);
extern double tycho_wl_mouse_y(uint64_t p);
extern int32_t tycho_wl_mouse_button(uint64_t p, int32_t btn);
extern int32_t tycho_wl_next_event(uint64_t p, int32_t *out4);
extern uint64_t tycho_wl_surface(uint64_t p);
extern void tycho_wl_set_cursor_mode(uint64_t p, int32_t mode);
extern void tycho_wl_set_cursor_shape(uint64_t p, int32_t shape);
extern void tycho_wl_set_fullscreen(uint64_t p, int32_t fs);
extern int32_t tycho_wl_is_fullscreen(uint64_t p);
extern double tycho_wl_content_scale(uint64_t p);
extern void tycho_wl_wait_events(int32_t timeout_ms);

// X11 backend functions (window_x11.c)
extern int tycho_x11_connect(void);
extern int tycho_x11_is_connected(void);
extern uint64_t tycho_x11_create(int32_t w, int32_t h, const char *title);
extern void tycho_x11_destroy(uint64_t p);
extern int32_t tycho_x11_should_close(uint64_t p);
extern void tycho_x11_set_should_close(uint64_t p, int32_t v);
extern int32_t tycho_x11_width(uint64_t p);
extern int32_t tycho_x11_height(uint64_t p);
extern int32_t tycho_x11_take_resized(uint64_t p);
extern void tycho_x11_set_title(uint64_t p, const char *title);
extern double tycho_x11_mouse_x(uint64_t p);
extern double tycho_x11_mouse_y(uint64_t p);
extern int32_t tycho_x11_mouse_button(uint64_t p, int32_t btn);
extern int32_t tycho_x11_next_event(uint64_t p, int32_t *out4);
extern void tycho_x11_poll(void);
extern uint64_t tycho_x11_display(uint64_t p);
extern uint64_t tycho_x11_handle(uint64_t p);
extern void tycho_x11_set_cursor_mode(uint64_t p, int32_t mode);
extern void tycho_x11_set_cursor_shape(uint64_t p, int32_t shape);
extern void tycho_x11_set_clipboard(uint64_t p, const char *text);
extern uint64_t tycho_x11_get_clipboard(uint64_t p);
extern void tycho_x11_set_fullscreen(uint64_t p, int32_t fs);
extern int32_t tycho_x11_is_fullscreen(uint64_t p);
extern double tycho_x11_content_scale(uint64_t p);
extern void tycho_x11_set_bg_color(uint64_t p, int32_t r, int32_t g, int32_t b);
extern int32_t tycho_x11_has_pending_sync(uint64_t p);
extern void tycho_x11_finish_sync(uint64_t p);
extern int tycho_x11_wait_events(int32_t timeout_ms);

static double now_sec(void) {
  struct timespec ts;
  clock_gettime(CLOCK_MONOTONIC, &ts);
  return (double)ts.tv_sec + (double)ts.tv_nsec * 1e-9;
}

MOONBIT_FFI_EXPORT int32_t tycho_win_init(void) {
  if (!g_init_done) {
    g_start_time = now_sec();
    g_init_done = 1;
    const char *pref = getenv("TYCHO_WINDOW_BACKEND");
    if (pref && strcmp(pref, "wayland") == 0) {
      if (tycho_wl_connect()) {
        g_use_wayland = 1;
        return 1;
      }
      return 0;
    }
    if (pref && strcmp(pref, "x11") == 0) {
      return tycho_x11_connect();
    }
    const char *wl = getenv("WAYLAND_DISPLAY");
    if (wl && wl[0] != '\0' && tycho_wl_connect()) {
      g_use_wayland = 1;
      return 1;
    }
    if (tycho_x11_connect()) return 1;
    if (tycho_wl_connect()) {
      g_use_wayland = 1;
      return 1;
    }
    return 0;
  }
  return (g_use_wayland || tycho_x11_is_connected()) ? 1 : 0;
}

MOONBIT_FFI_EXPORT int32_t tycho_win_is_wayland(void) {
  if (!g_init_done) tycho_win_init();
  return g_use_wayland ? 1 : 0;
}

MOONBIT_FFI_EXPORT void tycho_win_terminate(void) {
  // Intentionally do not call XCloseDisplay: on NVIDIA Linux drivers, closing
  // the X11 display after Vulkan swapchain presentation can segfault inside
  // the driver's teardown hooks. The OS reclaims the connection on exit.
}

MOONBIT_FFI_EXPORT uint64_t tycho_win_create(int32_t w, int32_t h, uint64_t title_ptr) {
  if (!g_init_done) tycho_win_init();
  const char *title = (const char *)(uintptr_t)title_ptr;
  return g_use_wayland ? tycho_wl_create(w, h, title) : tycho_x11_create(w, h, title);
}

MOONBIT_FFI_EXPORT void tycho_win_destroy(uint64_t p) {
  if (g_use_wayland) tycho_wl_destroy(p); else tycho_x11_destroy(p);
}

MOONBIT_FFI_EXPORT int32_t tycho_win_should_close(uint64_t p) {
  return g_use_wayland ? tycho_wl_should_close(p) : tycho_x11_should_close(p);
}

MOONBIT_FFI_EXPORT void tycho_win_set_should_close(uint64_t p, int32_t v) {
  if (g_use_wayland) tycho_wl_set_should_close(p, v); else tycho_x11_set_should_close(p, v);
}

MOONBIT_FFI_EXPORT int32_t tycho_win_width(uint64_t p) {
  return g_use_wayland ? tycho_wl_width(p) : tycho_x11_width(p);
}

MOONBIT_FFI_EXPORT int32_t tycho_win_height(uint64_t p) {
  return g_use_wayland ? tycho_wl_height(p) : tycho_x11_height(p);
}

MOONBIT_FFI_EXPORT int32_t tycho_win_take_resized(uint64_t p) {
  return g_use_wayland ? tycho_wl_take_resized(p) : tycho_x11_take_resized(p);
}

MOONBIT_FFI_EXPORT void tycho_win_set_title(uint64_t p, uint64_t title_ptr) {
  const char *title = (const char *)(uintptr_t)title_ptr;
  if (g_use_wayland) tycho_wl_set_title(p, title); else tycho_x11_set_title(p, title);
}

MOONBIT_FFI_EXPORT double tycho_win_mouse_x(uint64_t p) {
  return g_use_wayland ? tycho_wl_mouse_x(p) : tycho_x11_mouse_x(p);
}

MOONBIT_FFI_EXPORT double tycho_win_mouse_y(uint64_t p) {
  return g_use_wayland ? tycho_wl_mouse_y(p) : tycho_x11_mouse_y(p);
}

MOONBIT_FFI_EXPORT int32_t tycho_win_mouse_button(uint64_t p, int32_t btn) {
  return g_use_wayland ? tycho_wl_mouse_button(p, btn) : tycho_x11_mouse_button(p, btn);
}

MOONBIT_FFI_EXPORT int32_t tycho_win_next_event(uint64_t p, int32_t *out4) {
  return g_use_wayland ? tycho_wl_next_event(p, out4) : tycho_x11_next_event(p, out4);
}

MOONBIT_FFI_EXPORT void tycho_win_poll(void) {
  if (g_use_wayland) tycho_wl_poll(); else tycho_x11_poll();
}

MOONBIT_FFI_EXPORT double tycho_win_time(void) {
  return now_sec() - g_start_time;
}

MOONBIT_FFI_EXPORT uint64_t tycho_win_display(uint64_t p) {
  return g_use_wayland ? tycho_wl_display() : tycho_x11_display(p);
}

MOONBIT_FFI_EXPORT uint64_t tycho_win_handle(uint64_t p) {
  return g_use_wayland ? tycho_wl_surface(p) : tycho_x11_handle(p);
}

MOONBIT_FFI_EXPORT uint64_t tycho_win_monitor(uint64_t p) {
  (void)p;
  return 0;
}

MOONBIT_FFI_EXPORT void tycho_win_set_cursor_mode(uint64_t p, int32_t mode) {
  if (g_use_wayland) tycho_wl_set_cursor_mode(p, mode); else tycho_x11_set_cursor_mode(p, mode);
}

MOONBIT_FFI_EXPORT void tycho_win_set_cursor_shape(uint64_t p, int32_t shape) {
  if (g_use_wayland) tycho_wl_set_cursor_shape(p, shape); else tycho_x11_set_cursor_shape(p, shape);
}

MOONBIT_FFI_EXPORT void tycho_win_set_clipboard(uint64_t p, uint64_t text_ptr) {
  tycho_x11_set_clipboard(p, (const char *)(uintptr_t)text_ptr);
}

MOONBIT_FFI_EXPORT uint64_t tycho_win_get_clipboard(uint64_t p) {
  return tycho_x11_get_clipboard(p);
}

MOONBIT_FFI_EXPORT void tycho_win_set_fullscreen(uint64_t p, int32_t fs) {
  if (g_use_wayland) tycho_wl_set_fullscreen(p, fs); else tycho_x11_set_fullscreen(p, fs);
}

MOONBIT_FFI_EXPORT int32_t tycho_win_is_fullscreen(uint64_t p) {
  return g_use_wayland ? tycho_wl_is_fullscreen(p) : tycho_x11_is_fullscreen(p);
}

MOONBIT_FFI_EXPORT double tycho_win_content_scale(uint64_t p) {
  return g_use_wayland ? tycho_wl_content_scale(p) : tycho_x11_content_scale(p);
}

MOONBIT_FFI_EXPORT void tycho_win_set_bg_color(uint64_t p, int32_t r, int32_t g, int32_t b) {
  if (!g_use_wayland) tycho_x11_set_bg_color(p, r, g, b);
}

MOONBIT_FFI_EXPORT int32_t tycho_win_has_pending_sync(uint64_t p) {
  return g_use_wayland ? 0 : tycho_x11_has_pending_sync(p);
}

MOONBIT_FFI_EXPORT void tycho_win_finish_sync(uint64_t p) {
  if (!g_use_wayland) tycho_x11_finish_sync(p);
}

MOONBIT_FFI_EXPORT void tycho_win_wait_events(int32_t timeout_ms) {
  if (timeout_ms <= 0) return;
  if (g_use_wayland) {
    tycho_wl_wait_events(timeout_ms);
    return;
  }
  if (tycho_x11_wait_events(timeout_ms)) return;
  struct timespec ts;
  ts.tv_sec = timeout_ms / 1000;
  ts.tv_nsec = (long)(timeout_ms % 1000) * 1000000L;
  nanosleep(&ts, NULL);
}

#elif !defined(_WIN32) && !defined(__APPLE__)
MOONBIT_FFI_EXPORT int32_t tycho_win_init(void) { return 0; }
MOONBIT_FFI_EXPORT void tycho_win_terminate(void) {}
MOONBIT_FFI_EXPORT uint64_t tycho_win_create(int32_t w, int32_t h, uint64_t t) {
  (void)w; (void)h; (void)t; return 0;
}
MOONBIT_FFI_EXPORT void tycho_win_destroy(uint64_t p) { (void)p; }
MOONBIT_FFI_EXPORT int32_t tycho_win_should_close(uint64_t p) { (void)p; return 1; }
MOONBIT_FFI_EXPORT void tycho_win_set_should_close(uint64_t p, int32_t v) { (void)p; (void)v; }
MOONBIT_FFI_EXPORT int32_t tycho_win_width(uint64_t p) { (void)p; return 0; }
MOONBIT_FFI_EXPORT int32_t tycho_win_height(uint64_t p) { (void)p; return 0; }
MOONBIT_FFI_EXPORT int32_t tycho_win_take_resized(uint64_t p) { (void)p; return 0; }
MOONBIT_FFI_EXPORT void tycho_win_set_title(uint64_t p, uint64_t t) { (void)p; (void)t; }
MOONBIT_FFI_EXPORT double tycho_win_mouse_x(uint64_t p) { (void)p; return 0.0; }
MOONBIT_FFI_EXPORT double tycho_win_mouse_y(uint64_t p) { (void)p; return 0.0; }
MOONBIT_FFI_EXPORT int32_t tycho_win_mouse_button(uint64_t p, int32_t b) { (void)p; (void)b; return 0; }
MOONBIT_FFI_EXPORT int32_t tycho_win_next_event(uint64_t p, int32_t *out4) { (void)p; (void)out4; return 0; }
MOONBIT_FFI_EXPORT void tycho_win_poll(void) {}
MOONBIT_FFI_EXPORT double tycho_win_time(void) { return 0.0; }
MOONBIT_FFI_EXPORT uint64_t tycho_win_display(uint64_t p) { (void)p; return 0; }
MOONBIT_FFI_EXPORT uint64_t tycho_win_handle(uint64_t p) { (void)p; return 0; }
MOONBIT_FFI_EXPORT uint64_t tycho_win_monitor(uint64_t p) { (void)p; return 0; }
MOONBIT_FFI_EXPORT void tycho_win_set_cursor_mode(uint64_t p, int32_t m) { (void)p; (void)m; }
MOONBIT_FFI_EXPORT void tycho_win_set_cursor_shape(uint64_t p, int32_t s) { (void)p; (void)s; }
MOONBIT_FFI_EXPORT void tycho_win_set_clipboard(uint64_t p, uint64_t t) { (void)p; (void)t; }
MOONBIT_FFI_EXPORT uint64_t tycho_win_get_clipboard(uint64_t p) { (void)p; return (uint64_t)(uintptr_t)strdup(""); }
MOONBIT_FFI_EXPORT void tycho_win_set_fullscreen(uint64_t p, int32_t f) { (void)p; (void)f; }
MOONBIT_FFI_EXPORT int32_t tycho_win_is_fullscreen(uint64_t p) { (void)p; return 0; }
MOONBIT_FFI_EXPORT double tycho_win_content_scale(uint64_t p) { (void)p; return 1.0; }
MOONBIT_FFI_EXPORT void tycho_win_set_bg_color(uint64_t p, int32_t r, int32_t g, int32_t b) {
  (void)p; (void)r; (void)g; (void)b;
}
MOONBIT_FFI_EXPORT int32_t tycho_win_has_pending_sync(uint64_t p) { (void)p; return 0; }
MOONBIT_FFI_EXPORT void tycho_win_finish_sync(uint64_t p) { (void)p; }
MOONBIT_FFI_EXPORT void tycho_win_wait_events(int32_t timeout_ms) { (void)timeout_ms; }
MOONBIT_FFI_EXPORT int32_t tycho_win_is_wayland(void) { return 0; }
#endif

// ABI-matched WSI Vk*SurfaceCreateInfo* constructors (compile cleanly on every
// OS regardless of which platform headers vulkan/structs_stub.c enabled).
struct TychoVkXlibSurfaceCreateInfoKHR {
  int32_t sType;
  const void *pNext;
  uint32_t flags;
  void *dpy;
  unsigned long window;
};
struct TychoVkWaylandSurfaceCreateInfoKHR {
  int32_t sType;
  const void *pNext;
  uint32_t flags;
  void *display;
  void *surface;
};
struct TychoVkWin32SurfaceCreateInfoKHR {
  int32_t sType;
  const void *pNext;
  uint32_t flags;
  void *hinstance;
  void *hwnd;
};
struct TychoVkMetalSurfaceCreateInfoEXT {
  int32_t sType;
  const void *pNext;
  uint32_t flags;
  const void *pLayer;
};

MOONBIT_FFI_EXPORT uint64_t tycho_xlib_surface_ci_new(uint64_t dpy, uint64_t win) {
  struct TychoVkXlibSurfaceCreateInfoKHR *ci =
      (struct TychoVkXlibSurfaceCreateInfoKHR *)calloc(1, sizeof(*ci));
  ci->sType = 1000004000; // VK_STRUCTURE_TYPE_XLIB_SURFACE_CREATE_INFO_KHR
  ci->dpy = (void *)(uintptr_t)dpy;
  ci->window = (unsigned long)win;
  return (uint64_t)(uintptr_t)ci;
}
MOONBIT_FFI_EXPORT void tycho_xlib_surface_ci_free(uint64_t p) {
  free((void *)(uintptr_t)p);
}

MOONBIT_FFI_EXPORT uint64_t tycho_wl_surface_ci_new(uint64_t dpy, uint64_t surf) {
  struct TychoVkWaylandSurfaceCreateInfoKHR *ci =
      (struct TychoVkWaylandSurfaceCreateInfoKHR *)calloc(1, sizeof(*ci));
  ci->sType = 1000006000; // VK_STRUCTURE_TYPE_WAYLAND_SURFACE_CREATE_INFO_KHR
  ci->display = (void *)(uintptr_t)dpy;
  ci->surface = (void *)(uintptr_t)surf;
  return (uint64_t)(uintptr_t)ci;
}
MOONBIT_FFI_EXPORT void tycho_wl_surface_ci_free(uint64_t p) {
  free((void *)(uintptr_t)p);
}

MOONBIT_FFI_EXPORT uint64_t tycho_win32_surface_ci_new(uint64_t hinst, uint64_t hwnd) {
  struct TychoVkWin32SurfaceCreateInfoKHR *ci =
      (struct TychoVkWin32SurfaceCreateInfoKHR *)calloc(1, sizeof(*ci));
  ci->sType = 1000009000; // VK_STRUCTURE_TYPE_WIN32_SURFACE_CREATE_INFO_KHR
  ci->hinstance = (void *)(uintptr_t)hinst;
  ci->hwnd = (void *)(uintptr_t)hwnd;
  return (uint64_t)(uintptr_t)ci;
}
MOONBIT_FFI_EXPORT void tycho_win32_surface_ci_free(uint64_t p) {
  free((void *)(uintptr_t)p);
}

MOONBIT_FFI_EXPORT uint64_t tycho_metal_surface_ci_new(uint64_t layer) {
  struct TychoVkMetalSurfaceCreateInfoEXT *ci =
      (struct TychoVkMetalSurfaceCreateInfoEXT *)calloc(1, sizeof(*ci));
  ci->sType = 1000217000; // VK_STRUCTURE_TYPE_METAL_SURFACE_CREATE_INFO_EXT
  ci->pLayer = (const void *)(uintptr_t)layer;
  return (uint64_t)(uintptr_t)ci;
}
MOONBIT_FFI_EXPORT void tycho_metal_surface_ci_free(uint64_t p) {
  free((void *)(uintptr_t)p);
}

MOONBIT_FFI_EXPORT int tycho_window_platform(void) {
#if defined(_WIN32)
  return 1;
#elif defined(__APPLE__)
  return 2;
#else
  return 0;
#endif
}
