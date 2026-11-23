// Native window shim for laplaceliu/tycho_window.
// On Linux, backed directly by Xlib (libX11) — zero GLFW dependency.
#include "moonbit.h"
#include <stdint.h>
#include <stdlib.h>
#include <time.h>

#if defined(__linux__)
#include <X11/Xlib.h>
#include <X11/Xutil.h>

#define TYCHO_MAX_WINDOWS 16
#define TYCHO_MAX_EVENTS 128

typedef struct TychoEvent {
  int32_t kind;
  int32_t a;
  int32_t b;
  int32_t c;
} TychoEvent;

typedef struct TychoWindow {
  Display *dpy;
  Window win;
  Atom wm_delete;
  int should_close;
  int width;
  int height;
  int resized;
  int focused;
  double mouse_x;
  double mouse_y;
  uint32_t mouse_buttons;
  TychoEvent events[TYCHO_MAX_EVENTS];
  int ev_head;
  int ev_tail;
  int ev_count;
} TychoWindow;

static Display *g_dpy = NULL;
static TychoWindow *g_windows[TYCHO_MAX_WINDOWS] = {0};
static double g_start_time = 0.0;

static double now_sec(void) {
  struct timespec ts;
  clock_gettime(CLOCK_MONOTONIC, &ts);
  return (double)ts.tv_sec + (double)ts.tv_nsec * 1e-9;
}

static void register_window(TychoWindow *tw) {
  for (int i = 0; i < TYCHO_MAX_WINDOWS; i++) {
    if (!g_windows[i]) {
      g_windows[i] = tw;
      return;
    }
  }
}

static void unregister_window(TychoWindow *tw) {
  for (int i = 0; i < TYCHO_MAX_WINDOWS; i++) {
    if (g_windows[i] == tw) {
      g_windows[i] = NULL;
      return;
    }
  }
}

static TychoWindow *find_window(Window w) {
  for (int i = 0; i < TYCHO_MAX_WINDOWS; i++) {
    if (g_windows[i] && g_windows[i]->win == w) {
      return g_windows[i];
    }
  }
  return NULL;
}

static void push_event(TychoWindow *tw, int32_t kind, int32_t a, int32_t b, int32_t c) {
  if (!tw) return;
  if (tw->ev_count == TYCHO_MAX_EVENTS) {
    tw->ev_head = (tw->ev_head + 1) % TYCHO_MAX_EVENTS;
    tw->ev_count--;
  }
  tw->events[tw->ev_tail].kind = kind;
  tw->events[tw->ev_tail].a = a;
  tw->events[tw->ev_tail].b = b;
  tw->events[tw->ev_tail].c = c;
  tw->ev_tail = (tw->ev_tail + 1) % TYCHO_MAX_EVENTS;
  tw->ev_count++;
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
  XSelectInput(g_dpy, win,
               StructureNotifyMask | KeyPressMask | KeyReleaseMask |
                   ButtonPressMask | ButtonReleaseMask | PointerMotionMask |
                   FocusChangeMask | ExposureMask);
  XMapWindow(g_dpy, win);
  XSync(g_dpy, False);

  TychoWindow *tw = (TychoWindow *)calloc(1, sizeof(TychoWindow));
  tw->dpy = g_dpy;
  tw->win = win;
  tw->wm_delete = wm_delete;
  tw->should_close = 0;
  tw->width = w;
  tw->height = h;
  tw->focused = 1;
  register_window(tw);
  return (uint64_t)(uintptr_t)tw;
}

MOONBIT_FFI_EXPORT void tycho_win_destroy(uint64_t p) {
  TychoWindow *tw = (TychoWindow *)(uintptr_t)p;
  if (!tw) return;
  unregister_window(tw);
  if (tw->dpy && tw->win) {
    XSync(tw->dpy, False);
    XDestroyWindow(tw->dpy, tw->win);
    XFlush(tw->dpy);
  }
  free(tw);
}

MOONBIT_FFI_EXPORT int32_t tycho_win_should_close(uint64_t p) {
  TychoWindow *tw = (TychoWindow *)(uintptr_t)p;
  return tw ? tw->should_close : 1;
}

MOONBIT_FFI_EXPORT void tycho_win_set_should_close(uint64_t p, int32_t v) {
  TychoWindow *tw = (TychoWindow *)(uintptr_t)p;
  if (tw) tw->should_close = v ? 1 : 0;
}

MOONBIT_FFI_EXPORT int32_t tycho_win_width(uint64_t p) {
  TychoWindow *tw = (TychoWindow *)(uintptr_t)p;
  return tw ? tw->width : 0;
}

MOONBIT_FFI_EXPORT int32_t tycho_win_height(uint64_t p) {
  TychoWindow *tw = (TychoWindow *)(uintptr_t)p;
  return tw ? tw->height : 0;
}

MOONBIT_FFI_EXPORT int32_t tycho_win_take_resized(uint64_t p) {
  TychoWindow *tw = (TychoWindow *)(uintptr_t)p;
  if (!tw) return 0;
  int32_t r = tw->resized;
  tw->resized = 0;
  return r;
}

MOONBIT_FFI_EXPORT void tycho_win_set_title(uint64_t p, uint64_t title_ptr) {
  TychoWindow *tw = (TychoWindow *)(uintptr_t)p;
  const char *title = (const char *)(uintptr_t)title_ptr;
  if (tw && tw->dpy && tw->win && title) {
    XStoreName(tw->dpy, tw->win, title);
    XFlush(tw->dpy);
  }
}

MOONBIT_FFI_EXPORT double tycho_win_mouse_x(uint64_t p) {
  TychoWindow *tw = (TychoWindow *)(uintptr_t)p;
  return tw ? tw->mouse_x : 0.0;
}

MOONBIT_FFI_EXPORT double tycho_win_mouse_y(uint64_t p) {
  TychoWindow *tw = (TychoWindow *)(uintptr_t)p;
  return tw ? tw->mouse_y : 0.0;
}

MOONBIT_FFI_EXPORT int32_t tycho_win_mouse_button(uint64_t p, int32_t btn) {
  TychoWindow *tw = (TychoWindow *)(uintptr_t)p;
  if (!tw || btn < 1 || btn >= 32) return 0;
  return (tw->mouse_buttons & (1u << (uint32_t)btn)) ? 1 : 0;
}

MOONBIT_FFI_EXPORT int32_t tycho_win_next_event(uint64_t p, int32_t *out4) {
  TychoWindow *tw = (TychoWindow *)(uintptr_t)p;
  if (!tw || tw->ev_count <= 0) return 0;
  TychoEvent ev = tw->events[tw->ev_head];
  tw->ev_head = (tw->ev_head + 1) % TYCHO_MAX_EVENTS;
  tw->ev_count--;
  out4[0] = ev.kind;
  out4[1] = ev.a;
  out4[2] = ev.b;
  out4[3] = ev.c;
  return 1;
}

MOONBIT_FFI_EXPORT void tycho_win_poll(void) {
  if (!g_dpy) return;
  while (XPending(g_dpy) > 0) {
    XEvent ev;
    XNextEvent(g_dpy, &ev);
    TychoWindow *tw = find_window(ev.xany.window);
    if (!tw) continue;
    switch (ev.type) {
      case ClientMessage:
        if ((Atom)ev.xclient.data.l[0] == tw->wm_delete) {
          tw->should_close = 1;
          push_event(tw, 1, 0, 0, 0);
        }
        break;
      case DestroyNotify:
        if (ev.xdestroywindow.window == tw->win) {
          tw->should_close = 1;
          push_event(tw, 1, 0, 0, 0);
        }
        break;
      case ConfigureNotify:
        if (ev.xconfigure.width > 0 && ev.xconfigure.height > 0 &&
            (ev.xconfigure.width != tw->width || ev.xconfigure.height != tw->height)) {
          tw->width = ev.xconfigure.width;
          tw->height = ev.xconfigure.height;
          tw->resized = 1;
          push_event(tw, 2, tw->width, tw->height, 0);
        }
        break;
      case KeyPress: {
        KeySym ks = XLookupKeysym(&ev.xkey, 0);
        push_event(tw, 3, (int32_t)ks, (int32_t)ev.xkey.state, 0);
        break;
      }
      case KeyRelease: {
        KeySym ks = XLookupKeysym(&ev.xkey, 0);
        push_event(tw, 4, (int32_t)ks, (int32_t)ev.xkey.state, 0);
        break;
      }
      case MotionNotify:
        tw->mouse_x = (double)ev.xmotion.x;
        tw->mouse_y = (double)ev.xmotion.y;
        push_event(tw, 5, (int32_t)ev.xmotion.x, (int32_t)ev.xmotion.y, 0);
        break;
      case ButtonPress: {
        int btn = (int)ev.xbutton.button;
        if (btn == 4) {
          push_event(tw, 8, 1, 0, 0);
        } else if (btn == 5) {
          push_event(tw, 8, -1, 0, 0);
        } else if (btn >= 1 && btn < 32) {
          tw->mouse_buttons |= (1u << (uint32_t)btn);
          push_event(tw, 6, (int32_t)btn, (int32_t)ev.xbutton.x, (int32_t)ev.xbutton.y);
        }
        break;
      }
      case ButtonRelease: {
        int btn = (int)ev.xbutton.button;
        if (btn != 4 && btn != 5 && btn >= 1 && btn < 32) {
          tw->mouse_buttons &= ~(1u << (uint32_t)btn);
          push_event(tw, 7, (int32_t)btn, (int32_t)ev.xbutton.x, (int32_t)ev.xbutton.y);
        }
        break;
      }
      case FocusIn:
        tw->focused = 1;
        push_event(tw, 9, 1, 0, 0);
        break;
      case FocusOut:
        tw->focused = 0;
        push_event(tw, 9, 0, 0, 0);
        break;
      default:
        break;
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
