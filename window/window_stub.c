// Native window shim for laplaceliu/tycho_window.
// On Linux, backed by Wayland (window_wayland.c) and X11 (dlopen libX11.so.6);
// on Windows by window_win32.c; on macOS by window_macos.c — zero GLFW and
// zero OS link flags required.
#include "moonbit.h"
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#if defined(__linux__)
#include <dlfcn.h>
#if !defined(__has_include) || __has_include(<X11/Xlib.h>)
#define TYCHO_HAVE_XLIB 1
#include <X11/Xlib.h>
#include <X11/Xutil.h>
#else
#define TYCHO_HAVE_XLIB 0
#endif

#define TYCHO_MAX_WINDOWS 16
#define TYCHO_MAX_EVENTS 128

typedef struct TychoEvent {
  int32_t kind;
  int32_t a;
  int32_t b;
  int32_t c;
} TychoEvent;

#if TYCHO_HAVE_XLIB
static struct {
  void *lib;
  int tried;
  Display *(*XOpenDisplay)(const char *);
  Window (*XCreateSimpleWindow)(Display *, Window, int, int, unsigned int,
                                unsigned int, unsigned int, unsigned long,
                                unsigned long);
  int (*XStoreName)(Display *, Window, const char *);
  Atom (*XInternAtom)(Display *, const char *, Bool);
  Status (*XSetWMProtocols)(Display *, Window, Atom *, int);
  int (*XSelectInput)(Display *, Window, long);
  int (*XMapWindow)(Display *, Window);
  int (*XSync)(Display *, Bool);
  int (*XFlush)(Display *);
  int (*XPending)(Display *);
  int (*XNextEvent)(Display *, XEvent *);
  KeySym (*XLookupKeysym)(XKeyEvent *, int);
  int (*XLookupString)(XKeyEvent *, char *, int, KeySym *, void *);
  Cursor (*XCreateFontCursor)(Display *, unsigned int);
  int (*XWarpPointer)(Display *, Window, Window, int, int, unsigned int,
                      unsigned int, int, int);
  Pixmap (*XCreateBitmapFromData)(Display *, Drawable, const char *,
                                  unsigned int, unsigned int);
  Cursor (*XCreatePixmapCursor)(Display *, Pixmap, Pixmap, XColor *, XColor *,
                                unsigned int, unsigned int);
  int (*XFreePixmap)(Display *, Pixmap);
  int (*XFreeCursor)(Display *, Cursor);
  int (*XDefineCursor)(Display *, Window, Cursor);
  int (*XUndefineCursor)(Display *, Window);
  int (*XGrabPointer)(Display *, Window, Bool, unsigned int, int, int, Window,
                      Cursor, Time);
  int (*XUngrabPointer)(Display *, Time);
  int (*XDestroyWindow)(Display *, Window);
  Status (*XSendEvent)(Display *, Window, Bool, long, XEvent *);
  char *(*XResourceManagerString)(Display *);
} X11;

static int tycho_x11_load(void) {
  if (X11.tried) return X11.lib != NULL;
  X11.tried = 1;
  void *lib = dlopen("libX11.so.6", RTLD_NOW | RTLD_LOCAL);
  if (!lib) lib = dlopen("libX11.so", RTLD_NOW | RTLD_LOCAL);
  if (!lib) return 0;
#define XLOAD(sym) *(void **)&X11.sym = dlsym(lib, #sym)
  XLOAD(XOpenDisplay);
  XLOAD(XCreateSimpleWindow);
  XLOAD(XStoreName);
  XLOAD(XInternAtom);
  XLOAD(XSetWMProtocols);
  XLOAD(XSelectInput);
  XLOAD(XMapWindow);
  XLOAD(XSync);
  XLOAD(XFlush);
  XLOAD(XPending);
  XLOAD(XNextEvent);
  XLOAD(XLookupKeysym);
  XLOAD(XLookupString);
  XLOAD(XCreateFontCursor);
  XLOAD(XWarpPointer);
  XLOAD(XCreateBitmapFromData);
  XLOAD(XCreatePixmapCursor);
  XLOAD(XFreePixmap);
  XLOAD(XFreeCursor);
  XLOAD(XDefineCursor);
  XLOAD(XUndefineCursor);
  XLOAD(XGrabPointer);
  XLOAD(XUngrabPointer);
  XLOAD(XDestroyWindow);
  XLOAD(XSendEvent);
  XLOAD(XResourceManagerString);
#undef XLOAD
  if (!X11.XOpenDisplay || !X11.XCreateSimpleWindow || !X11.XPending || !X11.XNextEvent) {
    dlclose(lib);
    return 0;
  }
  X11.lib = lib;
  return 1;
}

typedef struct TychoWindow {
  Display *dpy;
  Window win;
  Atom wm_delete;
  Cursor hidden_cursor;
  int should_close;
  int width;
  int height;
  int resized;
  int focused;
  int cursor_mode; // 0=Normal, 1=Hidden, 2=Locked
  int fullscreen;
  int ignore_warp;
  double mouse_x;
  double mouse_y;
  uint32_t mouse_buttons;
  Cursor shape_cursors[6];
  TychoEvent events[TYCHO_MAX_EVENTS];
  int ev_head;
  int ev_tail;
  int ev_count;
} TychoWindow;

static Display *g_dpy = NULL;
static TychoWindow *g_windows[TYCHO_MAX_WINDOWS] = {0};
#endif
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

static double now_sec(void) {
  struct timespec ts;
  clock_gettime(CLOCK_MONOTONIC, &ts);
  return (double)ts.tv_sec + (double)ts.tv_nsec * 1e-9;
}

#if TYCHO_HAVE_XLIB
static Display *open_x11_display(void) {
  return tycho_x11_load() ? X11.XOpenDisplay(NULL) : NULL;
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
#endif

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
#if TYCHO_HAVE_XLIB
    if (pref && strcmp(pref, "x11") == 0) {
      g_dpy = open_x11_display();
      return g_dpy ? 1 : 0;
    }
#endif
    const char *wl = getenv("WAYLAND_DISPLAY");
    if (wl && wl[0] != '\0' && tycho_wl_connect()) {
      g_use_wayland = 1;
      return 1;
    }
#if TYCHO_HAVE_XLIB
    g_dpy = open_x11_display();
    if (g_dpy) return 1;
#endif
    if (tycho_wl_connect()) {
      g_use_wayland = 1;
      return 1;
    }
    return 0;
  }
#if TYCHO_HAVE_XLIB
  return (g_use_wayland || g_dpy) ? 1 : 0;
#else
  return g_use_wayland ? 1 : 0;
#endif
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
  if (g_use_wayland) {
    return tycho_wl_create(w, h, title);
  }
#if TYCHO_HAVE_XLIB
  if (!g_dpy) {
    g_dpy = open_x11_display();
  }
  if (!g_dpy) return 0;
  int screen = DefaultScreen(g_dpy);
  Window root = RootWindow(g_dpy, screen);
  Window win = X11.XCreateSimpleWindow(
      g_dpy, root, 0, 0, (unsigned int)w, (unsigned int)h, 0,
      BlackPixel(g_dpy, screen), BlackPixel(g_dpy, screen));
  if (title) {
    X11.XStoreName(g_dpy, win, title);
  }
  Atom wm_delete = X11.XInternAtom(g_dpy, "WM_DELETE_WINDOW", False);
  X11.XSetWMProtocols(g_dpy, win, &wm_delete, 1);
  X11.XSelectInput(g_dpy, win,
                   StructureNotifyMask | KeyPressMask | KeyReleaseMask |
                       ButtonPressMask | ButtonReleaseMask | PointerMotionMask |
                       FocusChangeMask | ExposureMask);
  X11.XMapWindow(g_dpy, win);
  X11.XSync(g_dpy, False);

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
#else
  (void)w; (void)h;
  return 0;
#endif
}

MOONBIT_FFI_EXPORT void tycho_win_destroy(uint64_t p) {
  if (g_use_wayland) { tycho_wl_destroy(p); return; }
#if TYCHO_HAVE_XLIB
  TychoWindow *tw = (TychoWindow *)(uintptr_t)p;
  if (!tw) return;
  unregister_window(tw);
  if (tw->dpy) {
    if (tw->cursor_mode == 2) {
      X11.XUngrabPointer(tw->dpy, CurrentTime);
    }
    if (tw->hidden_cursor) {
      X11.XFreeCursor(tw->dpy, tw->hidden_cursor);
      tw->hidden_cursor = 0;
    }
    if (tw->win) {
      X11.XSync(tw->dpy, False);
      X11.XDestroyWindow(tw->dpy, tw->win);
      X11.XFlush(tw->dpy);
    }
  }
  free(tw);
#else
  (void)p;
#endif
}

MOONBIT_FFI_EXPORT int32_t tycho_win_should_close(uint64_t p) {
  if (g_use_wayland) return tycho_wl_should_close(p);
#if TYCHO_HAVE_XLIB
  TychoWindow *tw = (TychoWindow *)(uintptr_t)p;
  return tw ? tw->should_close : 1;
#else
  (void)p; return 1;
#endif
}

MOONBIT_FFI_EXPORT void tycho_win_set_should_close(uint64_t p, int32_t v) {
  if (g_use_wayland) { tycho_wl_set_should_close(p, v); return; }
#if TYCHO_HAVE_XLIB
  TychoWindow *tw = (TychoWindow *)(uintptr_t)p;
  if (tw) tw->should_close = v ? 1 : 0;
#else
  (void)p; (void)v;
#endif
}

MOONBIT_FFI_EXPORT int32_t tycho_win_width(uint64_t p) {
  if (g_use_wayland) return tycho_wl_width(p);
#if TYCHO_HAVE_XLIB
  TychoWindow *tw = (TychoWindow *)(uintptr_t)p;
  return tw ? tw->width : 0;
#else
  (void)p; return 0;
#endif
}

MOONBIT_FFI_EXPORT int32_t tycho_win_height(uint64_t p) {
  if (g_use_wayland) return tycho_wl_height(p);
#if TYCHO_HAVE_XLIB
  TychoWindow *tw = (TychoWindow *)(uintptr_t)p;
  return tw ? tw->height : 0;
#else
  (void)p; return 0;
#endif
}

MOONBIT_FFI_EXPORT int32_t tycho_win_take_resized(uint64_t p) {
  if (g_use_wayland) return tycho_wl_take_resized(p);
#if TYCHO_HAVE_XLIB
  TychoWindow *tw = (TychoWindow *)(uintptr_t)p;
  if (!tw) return 0;
  int32_t r = tw->resized;
  tw->resized = 0;
  return r;
#else
  (void)p; return 0;
#endif
}

MOONBIT_FFI_EXPORT void tycho_win_set_title(uint64_t p, uint64_t title_ptr) {
  const char *title = (const char *)(uintptr_t)title_ptr;
  if (g_use_wayland) { tycho_wl_set_title(p, title); return; }
#if TYCHO_HAVE_XLIB
  TychoWindow *tw = (TychoWindow *)(uintptr_t)p;
  if (tw && tw->dpy && tw->win && title) {
    X11.XStoreName(tw->dpy, tw->win, title);
    X11.XFlush(tw->dpy);
  }
#else
  (void)p; (void)title;
#endif
}

MOONBIT_FFI_EXPORT double tycho_win_mouse_x(uint64_t p) {
  if (g_use_wayland) return tycho_wl_mouse_x(p);
#if TYCHO_HAVE_XLIB
  TychoWindow *tw = (TychoWindow *)(uintptr_t)p;
  return tw ? tw->mouse_x : 0.0;
#else
  (void)p; return 0.0;
#endif
}

MOONBIT_FFI_EXPORT double tycho_win_mouse_y(uint64_t p) {
  if (g_use_wayland) return tycho_wl_mouse_y(p);
#if TYCHO_HAVE_XLIB
  TychoWindow *tw = (TychoWindow *)(uintptr_t)p;
  return tw ? tw->mouse_y : 0.0;
#else
  (void)p; return 0.0;
#endif
}

MOONBIT_FFI_EXPORT int32_t tycho_win_mouse_button(uint64_t p, int32_t btn) {
  if (g_use_wayland) return tycho_wl_mouse_button(p, btn);
#if TYCHO_HAVE_XLIB
  TychoWindow *tw = (TychoWindow *)(uintptr_t)p;
  if (!tw || btn < 1 || btn >= 32) return 0;
  return (tw->mouse_buttons & (1u << (uint32_t)btn)) ? 1 : 0;
#else
  (void)p; (void)btn; return 0;
#endif
}

MOONBIT_FFI_EXPORT int32_t tycho_win_next_event(uint64_t p, int32_t *out4) {
  if (g_use_wayland) return tycho_wl_next_event(p, out4);
#if TYCHO_HAVE_XLIB
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
#else
  (void)p; (void)out4; return 0;
#endif
}

MOONBIT_FFI_EXPORT void tycho_win_poll(void) {
  if (g_use_wayland) { tycho_wl_poll(); return; }
#if TYCHO_HAVE_XLIB
  if (!g_dpy) return;
  while (X11.XPending(g_dpy) > 0) {
    XEvent ev;
    X11.XNextEvent(g_dpy, &ev);
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
        KeySym ks = X11.XLookupKeysym(&ev.xkey, 0);
        push_event(tw, 3, (int32_t)ks, (int32_t)ev.xkey.state, 0);
        // Emit TextInput for printable characters when Ctrl/Alt are not held.
        if (X11.XLookupString && !(ev.xkey.state & (ControlMask | Mod1Mask))) {
          char tbuf[16];
          KeySym tks = 0;
          int tlen = X11.XLookupString(&ev.xkey, tbuf, (int)sizeof(tbuf) - 1, &tks, NULL);
          for (int ti = 0; ti < tlen; ti++) {
            unsigned char ch = (unsigned char)tbuf[ti];
            if (ch >= 0x20 && ch != 0x7f) {
              push_event(tw, 10, (int32_t)ch, 0, 0);
            }
          }
        }
        break;
      }
      case KeyRelease: {
        KeySym ks = X11.XLookupKeysym(&ev.xkey, 0);
        push_event(tw, 4, (int32_t)ks, (int32_t)ev.xkey.state, 0);
        break;
      }
      case MotionNotify:
        if (tw->cursor_mode == 2) {
          int cx = tw->width / 2;
          int cy = tw->height / 2;
          if (tw->ignore_warp && ev.xmotion.x == cx && ev.xmotion.y == cy) {
            tw->ignore_warp = 0;
            break;
          }
          int dx = ev.xmotion.x - cx;
          int dy = ev.xmotion.y - cy;
          tw->mouse_x += (double)dx;
          tw->mouse_y += (double)dy;
          push_event(tw, 5, (int32_t)tw->mouse_x, (int32_t)tw->mouse_y, 0);
          if (dx != 0 || dy != 0) {
            tw->ignore_warp = 1;
            X11.XWarpPointer(tw->dpy, None, tw->win, 0, 0, 0, 0, cx, cy);
            X11.XFlush(tw->dpy);
          }
        } else {
          tw->mouse_x = (double)ev.xmotion.x;
          tw->mouse_y = (double)ev.xmotion.y;
          push_event(tw, 5, (int32_t)ev.xmotion.x, (int32_t)ev.xmotion.y, 0);
        }
        break;
      case ButtonPress: {
        int btn = (int)ev.xbutton.button;
        if (btn == 4) {
          push_event(tw, 8, 0, 1, 0);
        } else if (btn == 5) {
          push_event(tw, 8, 0, -1, 0);
        } else if (btn == 6) {
          push_event(tw, 8, -1, 0, 0);
        } else if (btn == 7) {
          push_event(tw, 8, 1, 0, 0);
        } else if (btn >= 1 && btn < 32) {
          tw->mouse_buttons |= (1u << (uint32_t)btn);
          push_event(tw, 6, (int32_t)btn, (int32_t)ev.xbutton.x, (int32_t)ev.xbutton.y);
        }
        break;
      }
      case ButtonRelease: {
        int btn = (int)ev.xbutton.button;
        if (btn != 4 && btn != 5 && btn != 6 && btn != 7 && btn >= 1 && btn < 32) {
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
#endif
}

MOONBIT_FFI_EXPORT double tycho_win_time(void) {
  return now_sec() - g_start_time;
}

MOONBIT_FFI_EXPORT uint64_t tycho_win_display(uint64_t p) {
  if (g_use_wayland) return tycho_wl_display();
#if TYCHO_HAVE_XLIB
  TychoWindow *tw = (TychoWindow *)(uintptr_t)p;
  return tw ? (uint64_t)(uintptr_t)tw->dpy : 0;
#else
  (void)p; return 0;
#endif
}

MOONBIT_FFI_EXPORT uint64_t tycho_win_handle(uint64_t p) {
  if (g_use_wayland) return tycho_wl_surface(p);
#if TYCHO_HAVE_XLIB
  TychoWindow *tw = (TychoWindow *)(uintptr_t)p;
  return tw ? (uint64_t)tw->win : 0;
#else
  (void)p; return 0;
#endif
}

#if TYCHO_HAVE_XLIB
static Cursor ensure_hidden_cursor(TychoWindow *tw) {
  if (!tw->hidden_cursor && tw->dpy && tw->win) {
    char blank[1] = {0};
    XColor dummy;
    memset(&dummy, 0, sizeof(dummy));
    Pixmap pm = X11.XCreateBitmapFromData(tw->dpy, tw->win, blank, 1, 1);
    tw->hidden_cursor = X11.XCreatePixmapCursor(tw->dpy, pm, pm, &dummy, &dummy, 0, 0);
    X11.XFreePixmap(tw->dpy, pm);
  }
  return tw->hidden_cursor;
}
#endif

MOONBIT_FFI_EXPORT void tycho_win_set_cursor_mode(uint64_t p, int32_t mode) {
  if (g_use_wayland) { tycho_wl_set_cursor_mode(p, mode); return; }
#if TYCHO_HAVE_XLIB
  TychoWindow *tw = (TychoWindow *)(uintptr_t)p;
  if (!tw || !tw->dpy || !tw->win) return;
  if (tw->cursor_mode == 2 && mode != 2) {
    X11.XUngrabPointer(tw->dpy, CurrentTime);
  }
  tw->cursor_mode = mode;
  if (mode == 0) {
    X11.XUndefineCursor(tw->dpy, tw->win);
  } else {
    Cursor c = ensure_hidden_cursor(tw);
    if (c) X11.XDefineCursor(tw->dpy, tw->win, c);
    if (mode == 2) {
      X11.XGrabPointer(tw->dpy, tw->win, True,
                       ButtonPressMask | ButtonReleaseMask | PointerMotionMask,
                       GrabModeAsync, GrabModeAsync, tw->win, None, CurrentTime);
      tw->ignore_warp = 1;
      X11.XWarpPointer(tw->dpy, None, tw->win, 0, 0, 0, 0, tw->width / 2, tw->height / 2);
    }
  }
  X11.XFlush(tw->dpy);
#else
  (void)p; (void)mode;
#endif
}

static char *g_x11_clipboard = NULL;

MOONBIT_FFI_EXPORT void tycho_win_set_cursor_shape(uint64_t p, int32_t shape) {
  if (g_use_wayland) { tycho_wl_set_cursor_shape(p, shape); return; }
#if TYCHO_HAVE_XLIB
  TychoWindow *tw = (TychoWindow *)(uintptr_t)p;
  if (!tw || !tw->dpy || !tw->win || tw->cursor_mode != 0) return;
  if (shape <= 0 || shape > 5) {
    X11.XUndefineCursor(tw->dpy, tw->win);
    X11.XFlush(tw->dpy);
    return;
  }
  if (!tw->shape_cursors[shape] && X11.XCreateFontCursor) {
    static const unsigned int xc_ids[6] = {68, 60, 152, 34, 108, 116};
    tw->shape_cursors[shape] = X11.XCreateFontCursor(tw->dpy, xc_ids[shape]);
  }
  if (tw->shape_cursors[shape]) {
    X11.XDefineCursor(tw->dpy, tw->win, tw->shape_cursors[shape]);
    X11.XFlush(tw->dpy);
  }
#else
  (void)p; (void)shape;
#endif
}

MOONBIT_FFI_EXPORT void tycho_win_set_clipboard(uint64_t p, uint64_t text_ptr) {
  (void)p;
  const char *text = (const char *)(uintptr_t)text_ptr;
  free(g_x11_clipboard);
  g_x11_clipboard = text ? strdup(text) : NULL;
}

MOONBIT_FFI_EXPORT uint64_t tycho_win_get_clipboard(uint64_t p) {
  (void)p;
  const char *s = g_x11_clipboard ? g_x11_clipboard : "";
  return (uint64_t)(uintptr_t)strdup(s);
}

MOONBIT_FFI_EXPORT void tycho_win_set_fullscreen(uint64_t p, int32_t fs) {
  if (g_use_wayland) { tycho_wl_set_fullscreen(p, fs); return; }
#if TYCHO_HAVE_XLIB
  TychoWindow *tw = (TychoWindow *)(uintptr_t)p;
  if (!tw || !tw->dpy || !tw->win) return;
  int want = fs ? 1 : 0;
  if (tw->fullscreen == want) return;
  tw->fullscreen = want;
  Atom wm_state = X11.XInternAtom(tw->dpy, "_NET_WM_STATE", False);
  Atom wm_fs = X11.XInternAtom(tw->dpy, "_NET_WM_STATE_FULLSCREEN", False);
  if (wm_state != None && wm_fs != None) {
    XEvent xev;
    memset(&xev, 0, sizeof(xev));
    xev.type = ClientMessage;
    xev.xclient.window = tw->win;
    xev.xclient.message_type = wm_state;
    xev.xclient.format = 32;
    xev.xclient.data.l[0] = want ? 1 : 0;
    xev.xclient.data.l[1] = (long)wm_fs;
    xev.xclient.data.l[2] = 0;
    xev.xclient.data.l[3] = 1;
    X11.XSendEvent(tw->dpy, DefaultRootWindow(tw->dpy), False,
                   SubstructureRedirectMask | SubstructureNotifyMask, &xev);
    X11.XFlush(tw->dpy);
  }
#else
  (void)p; (void)fs;
#endif
}

MOONBIT_FFI_EXPORT int32_t tycho_win_is_fullscreen(uint64_t p) {
  if (g_use_wayland) return tycho_wl_is_fullscreen(p);
#if TYCHO_HAVE_XLIB
  TychoWindow *tw = (TychoWindow *)(uintptr_t)p;
  return tw ? tw->fullscreen : 0;
#else
  (void)p; return 0;
#endif
}

MOONBIT_FFI_EXPORT double tycho_win_content_scale(uint64_t p) {
  if (g_use_wayland) return tycho_wl_content_scale(p);
#if TYCHO_HAVE_XLIB
  TychoWindow *tw = (TychoWindow *)(uintptr_t)p;
  if (!tw || !tw->dpy) return 1.0;
  const char *xrm = X11.XResourceManagerString(tw->dpy);
  if (xrm) {
    const char *hit = strstr(xrm, "Xft.dpi:");
    if (hit) {
      double dpi = atof(hit + 8);
      if (dpi > 0.0) return dpi / 96.0;
    }
  }
#else
  (void)p;
#endif
  return 1.0;
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
MOONBIT_FFI_EXPORT void tycho_win_set_cursor_mode(uint64_t p, int32_t m) { (void)p; (void)m; }
MOONBIT_FFI_EXPORT void tycho_win_set_cursor_shape(uint64_t p, int32_t s) { (void)p; (void)s; }
MOONBIT_FFI_EXPORT void tycho_win_set_clipboard(uint64_t p, uint64_t t) { (void)p; (void)t; }
MOONBIT_FFI_EXPORT uint64_t tycho_win_get_clipboard(uint64_t p) { (void)p; return (uint64_t)(uintptr_t)strdup(""); }
MOONBIT_FFI_EXPORT void tycho_win_set_fullscreen(uint64_t p, int32_t f) { (void)p; (void)f; }
MOONBIT_FFI_EXPORT int32_t tycho_win_is_fullscreen(uint64_t p) { (void)p; return 0; }
MOONBIT_FFI_EXPORT double tycho_win_content_scale(uint64_t p) { (void)p; return 1.0; }
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
