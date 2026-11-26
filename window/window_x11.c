// Native X11 (Xlib + XSync) backend for laplaceliu/tycho_window.
// Loads libX11.so.6 and libXext.so.6 at runtime via dlopen — zero X11 link flags required.
#include <stdint.h>

#if defined(__linux__)
#include <dlfcn.h>
#include <poll.h>
#include <stdlib.h>
#include <string.h>
#if !defined(__has_include) || __has_include(<X11/Xlib.h>)
#define TYCHO_HAVE_XLIB 1
#include <X11/Xatom.h>
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
  int (*Xutf8LookupString)(void *, XKeyEvent *, char *, int, KeySym *, int *);
  void *(*XOpenIM)(Display *, void *, char *, char *);
  int (*XCloseIM)(void *);
  void *(*XCreateIC)(void *, ...);
  void (*XDestroyIC)(void *);
  int (*XSetICValues)(void *, ...);
  void (*XSetICFocus)(void *);
  void (*XUnsetICFocus)(void *);
  int (*XFilterEvent)(XEvent *, Window);
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
  int (*XChangeWindowAttributes)(Display *, Window, unsigned long,
                                 XSetWindowAttributes *);
  int (*XChangeProperty)(Display *, Window, Atom, Atom, int, int,
                         const unsigned char *, int);
  int (*XConnectionNumber)(Display *);
  char *(*XResourceManagerString)(Display *);
} X11;

typedef XID TychoXSyncCounter;
typedef struct {
  int hi;
  unsigned int lo;
} TychoXSyncValue;

static struct {
  void *lib;
  int tried;
  int ready;
  Status (*XSyncInitialize)(Display *, int *, int *);
  TychoXSyncCounter (*XSyncCreateCounter)(Display *, TychoXSyncValue);
  Status (*XSyncDestroyCounter)(Display *, TychoXSyncCounter);
  Status (*XSyncSetCounter)(Display *, TychoXSyncCounter, TychoXSyncValue);
} XSyncExt;

static int tycho_xsync_load(Display *dpy) {
  if (!XSyncExt.tried) {
    XSyncExt.tried = 1;
    void *lib = dlopen("libXext.so.6", RTLD_NOW | RTLD_LOCAL);
    if (!lib) lib = dlopen("libXext.so", RTLD_NOW | RTLD_LOCAL);
    if (lib) {
      *(void **)&XSyncExt.XSyncInitialize = dlsym(lib, "XSyncInitialize");
      *(void **)&XSyncExt.XSyncCreateCounter = dlsym(lib, "XSyncCreateCounter");
      *(void **)&XSyncExt.XSyncDestroyCounter = dlsym(lib, "XSyncDestroyCounter");
      *(void **)&XSyncExt.XSyncSetCounter = dlsym(lib, "XSyncSetCounter");
      XSyncExt.lib = lib;
    }
  }
  if (!XSyncExt.ready && XSyncExt.XSyncInitialize && XSyncExt.XSyncCreateCounter &&
      XSyncExt.XSyncDestroyCounter && XSyncExt.XSyncSetCounter && dpy) {
    int maj = 0, min = 0;
    if (XSyncExt.XSyncInitialize(dpy, &maj, &min)) {
      XSyncExt.ready = 1;
    }
  }
  return XSyncExt.ready;
}

static unsigned long pack_color_mask(unsigned long mask, int val8) {
  if (!mask) return 0;
  int shift = 0;
  unsigned long m = mask;
  while ((m & 1UL) == 0UL) { m >>= 1; shift++; }
  int bits = 0;
  while ((m & 1UL) != 0UL) { m >>= 1; bits++; }
  unsigned long v = (unsigned long)(val8 < 0 ? 0 : (val8 > 255 ? 255 : val8));
  unsigned long scaled = bits >= 8 ? (v << (bits - 8)) : (v >> (8 - bits));
  return (scaled << shift) & mask;
}

static unsigned long x11_pack_rgb(Display *dpy, int screen, int r, int g, int b) {
  Visual *vis = DefaultVisual(dpy, screen);
  if (!vis || (vis->class != TrueColor && vis->class != DirectColor) ||
      (!vis->red_mask && !vis->green_mask && !vis->blue_mask)) {
    return BlackPixel(dpy, screen);
  }
  unsigned long px = pack_color_mask(vis->red_mask, r) |
                     pack_color_mask(vis->green_mask, g) |
                     pack_color_mask(vis->blue_mask, b);
  int depth = DefaultDepth(dpy, screen);
  if (depth == 32) {
    unsigned long all = 0xFFFFFFFFUL;
    px |= (all & ~(vis->red_mask | vis->green_mask | vis->blue_mask));
  }
  return px;
}

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
  XLOAD(Xutf8LookupString);
  XLOAD(XOpenIM);
  XLOAD(XCloseIM);
  XLOAD(XCreateIC);
  XLOAD(XDestroyIC);
  XLOAD(XSetICValues);
  XLOAD(XSetICFocus);
  XLOAD(XUnsetICFocus);
  XLOAD(XFilterEvent);
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
  XLOAD(XChangeWindowAttributes);
  XLOAD(XChangeProperty);
  XLOAD(XConnectionNumber);
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
  Atom wm_protocols;
  Atom wm_sync_request;
  TychoXSyncCounter sync_counter;
  uint32_t sync_lo;
  int32_t sync_hi;
  int sync_pending;
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
  void *xim;
  void *xic;
  TychoEvent events[TYCHO_MAX_EVENTS];
  int ev_head;
  int ev_tail;
  int ev_count;
} TychoWindow;

static Display *g_dpy = NULL;
static TychoWindow *g_windows[TYCHO_MAX_WINDOWS] = {0};
static char *g_x11_clipboard = NULL;

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

static void push_utf8_codepoints(TychoWindow *tw, int32_t kind, const char *s, int len) {
  if (!s) return;
  int i = 0;
  while (i < len && s[i]) {
    unsigned char c = (unsigned char)s[i];
    uint32_t cp = 0;
    int n = 1;
    if (c < 0x80) {
      cp = c;
    } else if ((c & 0xE0) == 0xC0 && i + 1 < len) {
      cp = ((uint32_t)(c & 0x1F) << 6) | ((unsigned char)s[i + 1] & 0x3F);
      n = 2;
    } else if ((c & 0xF0) == 0xE0 && i + 2 < len) {
      cp = ((uint32_t)(c & 0x0F) << 12) | (((unsigned char)s[i + 1] & 0x3F) << 6) |
           ((unsigned char)s[i + 2] & 0x3F);
      n = 3;
    } else if ((c & 0xF8) == 0xF0 && i + 3 < len) {
      cp = ((uint32_t)(c & 0x07) << 18) | (((unsigned char)s[i + 1] & 0x3F) << 12) |
           (((unsigned char)s[i + 2] & 0x3F) << 6) | ((unsigned char)s[i + 3] & 0x3F);
      n = 4;
    }
    push_event(tw, kind, (int32_t)cp, 0, 0);
    i += n;
  }
}

static void push_xtext(TychoWindow *tw, int32_t kind, XIMText *text) {
  if (!text) return;
  if (!text->encoding_is_wchar && text->string.multi_byte) {
    push_utf8_codepoints(tw, kind, text->string.multi_byte,
                         (int)strlen(text->string.multi_byte));
  } else if (text->encoding_is_wchar && text->string.wide_char) {
    for (int i = 0; i < (int)text->length; i++) {
      push_event(tw, kind, (int32_t)text->string.wide_char[i], 0, 0);
    }
  }
}


static void x11_ime_commit_key(TychoWindow *tw, XKeyEvent *ke) {
  if (!tw || !tw->xic || !X11.Xutf8LookupString) return;
  if (ke->state & (ControlMask | Mod1Mask)) return;
  char tbuf[64];
  KeySym tks = 0;
  int status = 0;
  int tlen = X11.Xutf8LookupString(tw->xic, ke, tbuf, (int)sizeof(tbuf) - 1,
                                   &tks, &status);
  if (tlen > 0) {
    tbuf[tlen] = 0;
    push_utf8_codepoints(tw, 13, tbuf, tlen);
  }
}

static void x11_ime_preedit(XIC ic, XPointer client, XPointer call) {
  (void)ic;
  TychoWindow *tw = (TychoWindow *)client;
  XIMPreeditDrawCallbackStruct *d = (XIMPreeditDrawCallbackStruct *)call;
  if (!tw) return;
  push_event(tw, 12, 0, 0, 0);
  if (d && d->text) push_xtext(tw, 11, d->text);
}


int tycho_x11_connect(void) {
  if (g_dpy) return 1;
  if (tycho_x11_load()) {
    g_dpy = X11.XOpenDisplay(NULL);
  }
  return g_dpy ? 1 : 0;
}

int tycho_x11_is_connected(void) {
  return g_dpy ? 1 : 0;
}

uint64_t tycho_x11_create(int32_t w, int32_t h, const char *title) {
  if (!tycho_x11_connect()) return 0;
  int screen = DefaultScreen(g_dpy);
  Window root = RootWindow(g_dpy, screen);
  unsigned long bg = x11_pack_rgb(g_dpy, screen, 13, 16, 26);
  Window win = X11.XCreateSimpleWindow(
      g_dpy, root, 0, 0, (unsigned int)w, (unsigned int)h, 0,
      bg, bg);
  if (X11.XChangeWindowAttributes) {
    // Preserve top-left pixels on resize with NorthWestGravity and fill newly
    // uncovered resize bands using bg pixel (matching Swapchain clear_color).
    XSetWindowAttributes xwa;
    memset(&xwa, 0, sizeof(xwa));
    xwa.background_pixel = bg;
    xwa.bit_gravity = NorthWestGravity;
    X11.XChangeWindowAttributes(g_dpy, win, CWBackPixel | CWBitGravity, &xwa);
  }
  if (title) {
    X11.XStoreName(g_dpy, win, title);
  }
  Atom wm_protocols = X11.XInternAtom(g_dpy, "WM_PROTOCOLS", False);
  Atom wm_delete = X11.XInternAtom(g_dpy, "WM_DELETE_WINDOW", False);
  Atom wm_sync_request = None;
  TychoXSyncCounter sync_counter = 0;
  if (tycho_xsync_load(g_dpy) && X11.XChangeProperty) {
    wm_sync_request = X11.XInternAtom(g_dpy, "_NET_WM_SYNC_REQUEST", False);
    Atom sync_prop = X11.XInternAtom(g_dpy, "_NET_WM_SYNC_REQUEST_COUNTER", False);
    if (wm_sync_request != None && sync_prop != None) {
      TychoXSyncValue init_val = {0, 0u};
      sync_counter = XSyncExt.XSyncCreateCounter(g_dpy, init_val);
      if (sync_counter != 0) {
        unsigned long card = (unsigned long)sync_counter;
        X11.XChangeProperty(g_dpy, win, sync_prop, XA_CARDINAL, 32,
                            PropModeReplace, (const unsigned char *)&card, 1);
      }
    }
  }
  if (sync_counter != 0) {
    Atom protos[2] = {wm_delete, wm_sync_request};
    X11.XSetWMProtocols(g_dpy, win, protos, 2);
  } else {
    X11.XSetWMProtocols(g_dpy, win, &wm_delete, 1);
  }
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
  tw->wm_protocols = wm_protocols;
  tw->wm_sync_request = wm_sync_request;
  tw->sync_counter = sync_counter;
  tw->should_close = 0;
  tw->width = w;
  tw->height = h;
  tw->focused = 1;
  if (X11.XOpenIM && X11.XCreateIC && X11.XSetICValues) {
    tw->xim = X11.XOpenIM(g_dpy, NULL, NULL, NULL);
    if (tw->xim) {
      tw->xic = X11.XCreateIC(
          tw->xim, XNInputStyle, XIMPreeditNothing | XIMStatusNothing,
          XNClientWindow, win, XNFocusWindow, win, NULL);
      if (tw->xic) {
        XIMCallback pre;
        pre.client_data = (XPointer)tw;
        pre.callback = (XIMProc)x11_ime_preedit;
        X11.XSetICValues(tw->xic, XNPreeditDrawCallback, &pre, NULL);
      }
    }
  }
  register_window(tw);
  return (uint64_t)(uintptr_t)tw;
}

void tycho_x11_destroy(uint64_t p) {
  TychoWindow *tw = (TychoWindow *)(uintptr_t)p;
  if (!tw) return;
  unregister_window(tw);
  if (tw->xic && X11.XDestroyIC) {
    X11.XDestroyIC(tw->xic);
    tw->xic = NULL;
  }
  if (tw->xim && X11.XCloseIM) {
    X11.XCloseIM(tw->xim);
    tw->xim = NULL;
  }
  if (tw->dpy) {
    if (tw->cursor_mode == 2) {
      X11.XUngrabPointer(tw->dpy, CurrentTime);
    }
    if (tw->hidden_cursor) {
      X11.XFreeCursor(tw->dpy, tw->hidden_cursor);
      tw->hidden_cursor = 0;
    }
    if (tw->sync_counter && XSyncExt.ready && XSyncExt.XSyncDestroyCounter) {
      XSyncExt.XSyncDestroyCounter(tw->dpy, tw->sync_counter);
      tw->sync_counter = 0;
    }
    if (tw->win) {
      X11.XSync(tw->dpy, False);
      X11.XDestroyWindow(tw->dpy, tw->win);
      X11.XFlush(tw->dpy);
    }
  }
  free(tw);
}

int32_t tycho_x11_should_close(uint64_t p) {
  TychoWindow *tw = (TychoWindow *)(uintptr_t)p;
  return tw ? tw->should_close : 1;
}

void tycho_x11_set_should_close(uint64_t p, int32_t v) {
  TychoWindow *tw = (TychoWindow *)(uintptr_t)p;
  if (tw) tw->should_close = v ? 1 : 0;
}

int32_t tycho_x11_width(uint64_t p) {
  TychoWindow *tw = (TychoWindow *)(uintptr_t)p;
  return tw ? tw->width : 0;
}

int32_t tycho_x11_height(uint64_t p) {
  TychoWindow *tw = (TychoWindow *)(uintptr_t)p;
  return tw ? tw->height : 0;
}

int32_t tycho_x11_take_resized(uint64_t p) {
  TychoWindow *tw = (TychoWindow *)(uintptr_t)p;
  if (!tw) return 0;
  int32_t r = tw->resized;
  tw->resized = 0;
  return r;
}

void tycho_x11_set_title(uint64_t p, const char *title) {
  TychoWindow *tw = (TychoWindow *)(uintptr_t)p;
  if (tw && tw->dpy && tw->win && title) {
    X11.XStoreName(tw->dpy, tw->win, title);
    X11.XFlush(tw->dpy);
  }
}

double tycho_x11_mouse_x(uint64_t p) {
  TychoWindow *tw = (TychoWindow *)(uintptr_t)p;
  return tw ? tw->mouse_x : 0.0;
}

double tycho_x11_mouse_y(uint64_t p) {
  TychoWindow *tw = (TychoWindow *)(uintptr_t)p;
  return tw ? tw->mouse_y : 0.0;
}

int32_t tycho_x11_mouse_button(uint64_t p, int32_t btn) {
  TychoWindow *tw = (TychoWindow *)(uintptr_t)p;
  if (!tw || btn < 1 || btn >= 32) return 0;
  return (tw->mouse_buttons & (1u << (uint32_t)btn)) ? 1 : 0;
}

int32_t tycho_x11_next_event(uint64_t p, int32_t *out4) {
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

void tycho_x11_poll(void) {
  if (!g_dpy) return;
  while (X11.XPending(g_dpy) > 0) {
    XEvent ev;
    X11.XNextEvent(g_dpy, &ev);
    TychoWindow *tw = find_window(ev.xany.window);
    if (!tw) continue;
    if (tw->xic && X11.XFilterEvent && X11.XFilterEvent(&ev, tw->win)) {
      if (ev.type == KeyPress) x11_ime_commit_key(tw, &ev.xkey);
      continue;
    }
    switch (ev.type) {
      case ClientMessage:
        if (ev.xclient.message_type == tw->wm_protocols) {
          if ((Atom)ev.xclient.data.l[0] == tw->wm_delete) {
            tw->should_close = 1;
            push_event(tw, 1, 0, 0, 0);
          } else if (tw->wm_sync_request != None &&
                     (Atom)ev.xclient.data.l[0] == tw->wm_sync_request) {
            tw->sync_lo = (uint32_t)(unsigned long)ev.xclient.data.l[2];
            tw->sync_hi = (int32_t)ev.xclient.data.l[3];
            tw->sync_pending = 1;
          }
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
        // XIM commit goes through Xutf8LookupString; without an IC fall back to
        // the plain keysym path.
        if (tw->xic) {
          x11_ime_commit_key(tw, &ev.xkey);
        } else if (X11.XLookupString &&
                   !(ev.xkey.state & (ControlMask | Mod1Mask))) {
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
        if (tw->xic && X11.XSetICFocus) X11.XSetICFocus(tw->xic);
        push_event(tw, 9, 1, 0, 0);
        break;
      case FocusOut:
        tw->focused = 0;
        if (tw->xic && X11.XUnsetICFocus) X11.XUnsetICFocus(tw->xic);
        push_event(tw, 9, 0, 0, 0);
        break;
      default:
        break;
    }
  }
}

uint64_t tycho_x11_display(uint64_t p) {
  TychoWindow *tw = (TychoWindow *)(uintptr_t)p;
  return tw ? (uint64_t)(uintptr_t)tw->dpy : 0;
}

uint64_t tycho_x11_handle(uint64_t p) {
  TychoWindow *tw = (TychoWindow *)(uintptr_t)p;
  return tw ? (uint64_t)tw->win : 0;
}

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

void tycho_x11_set_cursor_mode(uint64_t p, int32_t mode) {
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
}

void tycho_x11_set_cursor_shape(uint64_t p, int32_t shape) {
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
}

void tycho_x11_set_clipboard(uint64_t p, const char *text) {
  (void)p;
  free(g_x11_clipboard);
  g_x11_clipboard = text ? strdup(text) : NULL;
}

uint64_t tycho_x11_get_clipboard(uint64_t p) {
  (void)p;
  const char *s = g_x11_clipboard ? g_x11_clipboard : "";
  return (uint64_t)(uintptr_t)strdup(s);
}

void tycho_x11_set_fullscreen(uint64_t p, int32_t fs) {
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
}

int32_t tycho_x11_is_fullscreen(uint64_t p) {
  TychoWindow *tw = (TychoWindow *)(uintptr_t)p;
  return tw ? tw->fullscreen : 0;
}

double tycho_x11_content_scale(uint64_t p) {
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
  return 1.0;
}

void tycho_x11_set_bg_color(uint64_t p, int32_t r, int32_t g, int32_t b) {
  TychoWindow *tw = (TychoWindow *)(uintptr_t)p;
  if (!tw || !tw->dpy || !tw->win || !X11.XChangeWindowAttributes) return;
  int screen = DefaultScreen(tw->dpy);
  unsigned long bg = x11_pack_rgb(tw->dpy, screen, r, g, b);
  XSetWindowAttributes xwa;
  memset(&xwa, 0, sizeof(xwa));
  xwa.background_pixel = bg;
  X11.XChangeWindowAttributes(tw->dpy, tw->win, CWBackPixel, &xwa);
}

int32_t tycho_x11_has_pending_sync(uint64_t p) {
  TychoWindow *tw = (TychoWindow *)(uintptr_t)p;
  return (tw && tw->sync_counter && tw->sync_pending) ? 1 : 0;
}

void tycho_x11_finish_sync(uint64_t p) {
  TychoWindow *tw = (TychoWindow *)(uintptr_t)p;
  if (!tw || !tw->dpy || !tw->sync_counter || !tw->sync_pending) return;
  tw->sync_pending = 0;
  if (XSyncExt.ready && XSyncExt.XSyncSetCounter) {
    TychoXSyncValue val;
    val.hi = (int)tw->sync_hi;
    val.lo = (unsigned int)tw->sync_lo;
    XSyncExt.XSyncSetCounter(tw->dpy, tw->sync_counter, val);
    X11.XFlush(tw->dpy);
  }
}

int tycho_x11_wait_events(int32_t timeout_ms) {
  if (!g_dpy) return 0;
  if (X11.XPending(g_dpy) > 0) return 1;
  if (X11.XConnectionNumber) {
    X11.XFlush(g_dpy);
    struct pollfd pfd;
    pfd.fd = X11.XConnectionNumber(g_dpy);
    pfd.events = POLLIN;
    pfd.revents = 0;
    poll(&pfd, 1, timeout_ms);
    return 1;
  }
  return 0;
}

#else
int tycho_x11_connect(void) { return 0; }
int tycho_x11_is_connected(void) { return 0; }
uint64_t tycho_x11_create(int32_t w, int32_t h, const char *t) { (void)w; (void)h; (void)t; return 0; }
void tycho_x11_destroy(uint64_t p) { (void)p; }
int32_t tycho_x11_should_close(uint64_t p) { (void)p; return 1; }
void tycho_x11_set_should_close(uint64_t p, int32_t v) { (void)p; (void)v; }
int32_t tycho_x11_width(uint64_t p) { (void)p; return 0; }
int32_t tycho_x11_height(uint64_t p) { (void)p; return 0; }
int32_t tycho_x11_take_resized(uint64_t p) { (void)p; return 0; }
void tycho_x11_set_title(uint64_t p, const char *t) { (void)p; (void)t; }
double tycho_x11_mouse_x(uint64_t p) { (void)p; return 0.0; }
double tycho_x11_mouse_y(uint64_t p) { (void)p; return 0.0; }
int32_t tycho_x11_mouse_button(uint64_t p, int32_t b) { (void)p; (void)b; return 0; }
int32_t tycho_x11_next_event(uint64_t p, int32_t *out4) { (void)p; (void)out4; return 0; }
void tycho_x11_poll(void) {}
uint64_t tycho_x11_display(uint64_t p) { (void)p; return 0; }
uint64_t tycho_x11_handle(uint64_t p) { (void)p; return 0; }
void tycho_x11_set_cursor_mode(uint64_t p, int32_t m) { (void)p; (void)m; }
void tycho_x11_set_cursor_shape(uint64_t p, int32_t s) { (void)p; (void)s; }
void tycho_x11_set_clipboard(uint64_t p, const char *t) { (void)p; (void)t; }
uint64_t tycho_x11_get_clipboard(uint64_t p) { (void)p; return (uint64_t)(uintptr_t)strdup(""); }
void tycho_x11_set_fullscreen(uint64_t p, int32_t f) { (void)p; (void)f; }
int32_t tycho_x11_is_fullscreen(uint64_t p) { (void)p; return 0; }
double tycho_x11_content_scale(uint64_t p) { (void)p; return 1.0; }
void tycho_x11_set_bg_color(uint64_t p, int32_t r, int32_t g, int32_t b) { (void)p; (void)r; (void)g; (void)b; }
int32_t tycho_x11_has_pending_sync(uint64_t p) { (void)p; return 0; }
void tycho_x11_finish_sync(uint64_t p) { (void)p; }
int tycho_x11_wait_events(int32_t timeout_ms) { (void)timeout_ms; return 0; }
#endif
#endif
