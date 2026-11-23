// Native window shim for laplaceliu/tycho_window.
// On Linux, backed directly by Xlib (libX11) — zero GLFW dependency.
#include "moonbit.h"
#include <stdint.h>
#include <stdlib.h>
#include <time.h>

#if defined(__linux__)
#include <X11/Xlib.h>
#include <X11/Xutil.h>

typedef struct TychoWindow {
  Display *dpy;
  Window win;
  Atom wm_delete;
  int should_close;
} TychoWindow;

static Display *g_dpy = NULL;
static TychoWindow *g_active = NULL;
static double g_start_time = 0.0;

static double now_sec(void) {
  struct timespec ts;
  clock_gettime(CLOCK_MONOTONIC, &ts);
  return (double)ts.tv_sec + (double)ts.tv_nsec * 1e-9;
}

MOONBIT_FFI_EXPORT int32_t tycho_win_init(void) {
  g_start_time = now_sec();
  if (!g_dpy) {
    g_dpy = XOpenDisplay(NULL);
  }
  return g_dpy ? 1 : 0;
}

MOONBIT_FFI_EXPORT void tycho_win_terminate(void) {
  // Intentionally do not call XCloseDisplay: on NVIDIA Linux drivers, closing
  // the X11 display after Vulkan swapchain presentation can segfault inside
  // the driver's teardown hooks. The OS reclaims the connection on exit.
}

MOONBIT_FFI_EXPORT uint64_t tycho_win_create(int32_t w, int32_t h, uint64_t title_ptr) {
  if (!g_dpy) {
    g_dpy = XOpenDisplay(NULL);
  }
  if (!g_dpy) return 0;
  int screen = DefaultScreen(g_dpy);
  Window root = RootWindow(g_dpy, screen);
  Window win = XCreateSimpleWindow(
      g_dpy, root, 0, 0, (unsigned int)w, (unsigned int)h, 0,
      BlackPixel(g_dpy, screen), BlackPixel(g_dpy, screen));
  const char *title = (const char *)(uintptr_t)title_ptr;
  if (title) {
    XStoreName(g_dpy, win, title);
  }
  Atom wm_delete = XInternAtom(g_dpy, "WM_DELETE_WINDOW", False);
  XSetWMProtocols(g_dpy, win, &wm_delete, 1);
  XSelectInput(g_dpy, win, StructureNotifyMask | KeyPressMask | ExposureMask);
  XMapWindow(g_dpy, win);
  XSync(g_dpy, False);

  TychoWindow *tw = (TychoWindow *)calloc(1, sizeof(TychoWindow));
  tw->dpy = g_dpy;
  tw->win = win;
  tw->wm_delete = wm_delete;
  tw->should_close = 0;
  g_active = tw;
  return (uint64_t)(uintptr_t)tw;
}

MOONBIT_FFI_EXPORT void tycho_win_destroy(uint64_t p) {
  TychoWindow *tw = (TychoWindow *)(uintptr_t)p;
  if (!tw) return;
  if (tw->dpy && tw->win) {
    XSync(tw->dpy, False);
    XDestroyWindow(tw->dpy, tw->win);
    XFlush(tw->dpy);
  }
  if (g_active == tw) g_active = NULL;
  free(tw);
}

MOONBIT_FFI_EXPORT int32_t tycho_win_should_close(uint64_t p) {
  TychoWindow *tw = (TychoWindow *)(uintptr_t)p;
  return tw ? tw->should_close : 1;
}

MOONBIT_FFI_EXPORT void tycho_win_poll(void) {
  if (!g_dpy) return;
  while (XPending(g_dpy) > 0) {
    XEvent ev;
    XNextEvent(g_dpy, &ev);
    if (ev.type == ClientMessage && g_active &&
        (Atom)ev.xclient.data.l[0] == g_active->wm_delete) {
      g_active->should_close = 1;
    } else if (ev.type == DestroyNotify && g_active &&
               ev.xdestroywindow.window == g_active->win) {
      g_active->should_close = 1;
    }
  }
}

MOONBIT_FFI_EXPORT double tycho_win_time(void) {
  return now_sec() - g_start_time;
}

MOONBIT_FFI_EXPORT uint64_t tycho_win_display(uint64_t p) {
  TychoWindow *tw = (TychoWindow *)(uintptr_t)p;
  return tw ? (uint64_t)(uintptr_t)tw->dpy : 0;
}

MOONBIT_FFI_EXPORT uint64_t tycho_win_handle(uint64_t p) {
  TychoWindow *tw = (TychoWindow *)(uintptr_t)p;
  return tw ? (uint64_t)tw->win : 0;
}
#else
MOONBIT_FFI_EXPORT int32_t tycho_win_init(void) { return 0; }
MOONBIT_FFI_EXPORT void tycho_win_terminate(void) {}
MOONBIT_FFI_EXPORT uint64_t tycho_win_create(int32_t w, int32_t h, uint64_t t) {
  (void)w; (void)h; (void)t; return 0;
}
MOONBIT_FFI_EXPORT void tycho_win_destroy(uint64_t p) { (void)p; }
MOONBIT_FFI_EXPORT int32_t tycho_win_should_close(uint64_t p) { (void)p; return 1; }
MOONBIT_FFI_EXPORT void tycho_win_poll(void) {}
MOONBIT_FFI_EXPORT double tycho_win_time(void) { return 0.0; }
MOONBIT_FFI_EXPORT uint64_t tycho_win_display(uint64_t p) { (void)p; return 0; }
MOONBIT_FFI_EXPORT uint64_t tycho_win_handle(uint64_t p) { (void)p; return 0; }
#endif

MOONBIT_FFI_EXPORT int tycho_window_platform(void) {
#if defined(_WIN32)
  return 1;
#elif defined(__APPLE__)
  return 2;
#else
  return 0;
#endif
}
