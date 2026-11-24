// Native macOS Cocoa + CAMetalLayer window backend for laplaceliu/tycho_window.
// Pure C99 using dlopen + libobjc runtime — zero Objective-C compiler flags
// and zero `-framework Cocoa` / `-framework QuartzCore` link flags required.
#if defined(__APPLE__)
#include <dlfcn.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include "moonbit.h"

#define TYCHO_MAX_WINDOWS 16
#define TYCHO_MAX_EVENTS 128

typedef struct { double x, y; } TychoCGPoint;
typedef struct { double width, height; } TychoCGSize;
typedef struct { TychoCGPoint origin; TychoCGSize size; } TychoCGRect;

typedef struct TychoMacEvent {
  int32_t kind;
  int32_t a;
  int32_t b;
  int32_t c;
} TychoMacEvent;

typedef struct TychoMacWindow {
  void *ns_win;
  void *ns_view;
  void *metal_layer;
  int should_close;
  int width;
  int height;
  int resized;
  int focused;
  int cursor_mode; // 0=Normal, 1=Hidden, 2=Locked
  int cursor_hidden;
  int fullscreen;
  double scale;
  double mouse_x;
  double mouse_y;
  uint32_t mouse_buttons;
  TychoMacEvent events[TYCHO_MAX_EVENTS];
  int ev_head;
  int ev_tail;
  int ev_count;
} TychoMacWindow;

static struct {
  void *objc;
  void *foundation;
  void *appkit;
  void *quartz;
  void *(*objc_getClass)(const char *);
  void *(*sel_registerName)(const char *);
  void *msgSend;
  void *msgSend_fpret;
  void *msgSend_stret;
  void *ns_app;
  void *default_run_loop_mode;
} O;

static TychoMacWindow *g_windows[TYCHO_MAX_WINDOWS] = {0};
static double g_start_time = 0.0;
static int g_init_done = 0;

static double now_sec(void) {
  struct timespec ts;
  clock_gettime(CLOCK_MONOTONIC, &ts);
  return (double)ts.tv_sec + (double)ts.tv_nsec * 1e-9;
}

static void *cls(const char *name) { return O.objc_getClass(name); }
static void *sel(const char *name) { return O.sel_registerName(name); }

// Strict non-variadic objc_msgSend wrappers (critical for arm64 ABI!).
static void *call0(void *obj, const char *s) {
  typedef void *(*F)(void *, void *);
  return ((F)O.msgSend)(obj, sel(s));
}
static long call0_long(void *obj, const char *s) {
  typedef long (*F)(void *, void *);
  return ((F)O.msgSend)(obj, sel(s));
}
static unsigned long call0_ulong(void *obj, const char *s) {
  typedef unsigned long (*F)(void *, void *);
  return ((F)O.msgSend)(obj, sel(s));
}
static int call0_bool(void *obj, const char *s) {
  typedef signed char (*F)(void *, void *);
  return (int)((F)O.msgSend)(obj, sel(s));
}
static double call0_double(void *obj, const char *s) {
#if defined(__x86_64__)
  typedef double (*F)(void *, void *);
  return ((F)O.msgSend_fpret)(obj, sel(s));
#else
  typedef double (*F)(void *, void *);
  return ((F)O.msgSend)(obj, sel(s));
#endif
}
static void *call1_ptr(void *obj, const char *s, void *a) {
  typedef void *(*F)(void *, void *, void *);
  return ((F)O.msgSend)(obj, sel(s), a);
}
static void call1_bool(void *obj, const char *s, int a) {
  typedef void (*F)(void *, void *, signed char);
  ((F)O.msgSend)(obj, sel(s), (signed char)(a ? 1 : 0));
}
static void call1_long(void *obj, const char *s, long a) {
  typedef void (*F)(void *, void *, long);
  ((F)O.msgSend)(obj, sel(s), a);
}
static void call1_double(void *obj, const char *s, double a) {
  typedef void (*F)(void *, void *, double);
  ((F)O.msgSend)(obj, sel(s), a);
}
static TychoCGRect call0_rect(void *obj, const char *s) {
  TychoCGRect r;
  memset(&r, 0, sizeof(r));
#if defined(__x86_64__)
  typedef void (*F)(TychoCGRect *, void *, void *);
  ((F)O.msgSend_stret)(&r, obj, sel(s));
#else
  typedef TychoCGRect (*F)(void *, void *);
  r = ((F)O.msgSend)(obj, sel(s));
#endif
  return r;
}
static TychoCGPoint call0_point(void *obj, const char *s) {
  typedef TychoCGPoint (*F)(void *, void *);
  return ((F)O.msgSend)(obj, sel(s));
}

static void push_event(TychoMacWindow *tw, int32_t kind, int32_t a,
                       int32_t b, int32_t c) {
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

static void register_window(TychoMacWindow *tw) {
  for (int i = 0; i < TYCHO_MAX_WINDOWS; i++) {
    if (!g_windows[i]) { g_windows[i] = tw; return; }
  }
}

static void unregister_window(TychoMacWindow *tw) {
  for (int i = 0; i < TYCHO_MAX_WINDOWS; i++) {
    if (g_windows[i] == tw) { g_windows[i] = NULL; return; }
  }
}

static TychoMacWindow *find_window(void *ns_win) {
  for (int i = 0; i < TYCHO_MAX_WINDOWS; i++) {
    if (g_windows[i] && g_windows[i]->ns_win == ns_win) return g_windows[i];
  }
  if (!ns_win) {
    for (int i = 0; i < TYCHO_MAX_WINDOWS; i++) {
      if (g_windows[i]) return g_windows[i];
    }
  }
  return NULL;
}

static int32_t mac_keycode_to_tycho(unsigned short kc) {
  switch (kc) {
    case 0x00: return 'a'; case 0x0b: return 'b'; case 0x08: return 'c';
    case 0x02: return 'd'; case 0x0e: return 'e'; case 0x03: return 'f';
    case 0x05: return 'g'; case 0x04: return 'h'; case 0x22: return 'i';
    case 0x26: return 'j'; case 0x28: return 'k'; case 0x25: return 'l';
    case 0x2e: return 'm'; case 0x2d: return 'n'; case 0x1f: return 'o';
    case 0x23: return 'p'; case 0x0c: return 'q'; case 0x0f: return 'r';
    case 0x01: return 's'; case 0x11: return 't'; case 0x20: return 'u';
    case 0x09: return 'v'; case 0x0d: return 'w'; case 0x07: return 'x';
    case 0x10: return 'y'; case 0x06: return 'z';
    case 0x1d: return '0'; case 0x12: return '1'; case 0x13: return '2';
    case 0x14: return '3'; case 0x15: return '4'; case 0x17: return '5';
    case 0x16: return '6'; case 0x1a: return '7'; case 0x1c: return '8';
    case 0x19: return '9';
    case 0x35: return 0xff1b; // Escape
    case 0x24: return 0xff0d; // Return
    case 0x30: return 0xff09; // Tab
    case 0x33: return 0xff08; // Backspace
    case 0x31: return 0x0020; // Space
    case 0x7b: return 0xff51; // Left
    case 0x7e: return 0xff52; // Up
    case 0x7c: return 0xff53; // Right
    case 0x7d: return 0xff54; // Down
    case 0x7a: return 0xffbe; // F1
    case 0x78: return 0xffbf; // F2
    case 0x63: return 0xffc0; // F3
    case 0x76: return 0xffc1; // F4
    case 0x60: return 0xffc2; // F5
    case 0x61: return 0xffc3; // F6
    case 0x62: return 0xffc4; // F7
    case 0x64: return 0xffc5; // F8
    case 0x65: return 0xffc6; // F9
    case 0x6d: return 0xffc7; // F10
    case 0x67: return 0xffc8; // F11
    case 0x6f: return 0xffc9; // F12
    case 0x38: return 0xffe1; // LShift
    case 0x3c: return 0xffe2; // RShift
    case 0x3b: return 0xffe3; // LCtrl
    case 0x3e: return 0xffe4; // RCtrl
    case 0x3a: return 0xffe9; // LAlt
    case 0x3d: return 0xffea; // RAlt
    default: return (int32_t)kc;
  }
}

static int32_t mac_mods(unsigned long flags) {
  int32_t m = 0;
  if (flags & (1ul << 17)) m |= 1; // Shift
  if (flags & (1ul << 18)) m |= 4; // Control
  if (flags & (1ul << 19)) m |= 8; // Option/Alt
  return m;
}

MOONBIT_FFI_EXPORT int32_t tycho_win_init(void) {
  if (!g_init_done) {
    g_start_time = now_sec();
    g_init_done = 1;
    O.objc = dlopen("/usr/lib/libobjc.A.dylib", RTLD_NOW | RTLD_LOCAL);
    O.foundation = dlopen("/System/Library/Frameworks/Foundation.framework/Foundation",
                          RTLD_NOW | RTLD_LOCAL);
    O.appkit = dlopen("/System/Library/Frameworks/AppKit.framework/AppKit",
                      RTLD_NOW | RTLD_LOCAL);
    O.quartz = dlopen("/System/Library/Frameworks/QuartzCore.framework/QuartzCore",
                      RTLD_NOW | RTLD_LOCAL);
    if (!O.objc || !O.foundation || !O.appkit || !O.quartz) return 0;
    *(void **)&O.objc_getClass = dlsym(O.objc, "objc_getClass");
    *(void **)&O.sel_registerName = dlsym(O.objc, "sel_registerName");
    O.msgSend = dlsym(O.objc, "objc_msgSend");
#if defined(__x86_64__)
    O.msgSend_fpret = dlsym(O.objc, "objc_msgSend_fpret");
    O.msgSend_stret = dlsym(O.objc, "objc_msgSend_stret");
#endif
    void **mode_ptr = (void **)dlsym(O.foundation, "NSDefaultRunLoopMode");
    O.default_run_loop_mode = mode_ptr ? *mode_ptr : NULL;
    if (!O.objc_getClass || !O.sel_registerName || !O.msgSend) return 0;
    void *nsapp_cls = cls("NSApplication");
    if (!nsapp_cls) return 0;
    O.ns_app = call0(nsapp_cls, "sharedApplication");
    if (!O.ns_app) return 0;
    call1_long(O.ns_app, "setActivationPolicy:", 0);
    call0(O.ns_app, "finishLaunching");
  }
  return O.ns_app ? 1 : 0;
}

MOONBIT_FFI_EXPORT int32_t tycho_win_is_wayland(void) { return 0; }
MOONBIT_FFI_EXPORT void tycho_win_terminate(void) {}

MOONBIT_FFI_EXPORT uint64_t tycho_win_create(int32_t w, int32_t h, uint64_t title_ptr) {
  if (!tycho_win_init()) return 0;
  void *pool_cls = cls("NSAutoreleasePool");
  void *pool = pool_cls ? call0(pool_cls, "new") : NULL;
  void *win_cls = cls("NSWindow");
  void *layer_cls = cls("CAMetalLayer");
  void *str_cls = cls("NSString");
  if (!win_cls || !layer_cls || !str_cls) {
    if (pool) call0(pool, "drain");
    return 0;
  }

  TychoCGRect frame = {{100.0, 100.0}, {(double)w, (double)h}};
  typedef void *(*InitWinFn)(void *, void *, TychoCGRect, unsigned long, unsigned long, signed char);
  void *win_alloc = call0(win_cls, "alloc");
  void *win = ((InitWinFn)O.msgSend)(
      win_alloc,
      sel("initWithContentRect:styleMask:backing:defer:"),
      frame, 15ul /* titled|closable|miniaturizable|resizable */,
      2ul /* NSBackingStoreBuffered */, (signed char)0);
  if (!win) {
    if (pool) call0(pool, "drain");
    return 0;
  }
  call1_bool(win, "setReleasedWhenClosed:", 0);
  const char *title = (const char *)(uintptr_t)title_ptr;
  if (title) {
    void *ns_title = call1_ptr(str_cls, "stringWithUTF8String:", (void *)title);
    if (ns_title) call1_ptr(win, "setTitle:", ns_title);
  }
  void *view = call0(win, "contentView");
  if (!view) {
    if (pool) call0(pool, "drain");
    return 0;
  }
  call1_bool(view, "setWantsLayer:", 1);
  void *layer = call0(layer_cls, "layer");
  if (!layer) {
    if (pool) call0(pool, "drain");
    return 0;
  }
  double scale = call0_double(win, "backingScaleFactor");
  if (scale <= 0.0) scale = 1.0;
  call1_double(layer, "setContentsScale:", scale);
  call1_ptr(view, "setLayer:", layer);
  call1_ptr(win, "makeKeyAndOrderFront:", NULL);
  call1_bool(O.ns_app, "activateIgnoringOtherApps:", 1);

  TychoMacWindow *tw = (TychoMacWindow *)calloc(1, sizeof(TychoMacWindow));
  tw->ns_win = win;
  tw->ns_view = view;
  tw->metal_layer = layer;
  tw->scale = scale;
  TychoCGRect vr = call0_rect(view, "bounds");
  tw->width = (int)(vr.size.width * scale + 0.5);
  tw->height = (int)(vr.size.height * scale + 0.5);
  if (tw->width <= 0) tw->width = w;
  if (tw->height <= 0) tw->height = h;
  tw->focused = 1;
  register_window(tw);
  if (pool) call0(pool, "drain");
  return (uint64_t)(uintptr_t)tw;
}

MOONBIT_FFI_EXPORT void tycho_win_destroy(uint64_t p) {
  TychoMacWindow *tw = (TychoMacWindow *)(uintptr_t)p;
  if (!tw) return;
  if (tw->cursor_hidden) {
    void *c = cls("NSCursor");
    if (c) call0(c, "unhide");
    tw->cursor_hidden = 0;
  }
  unregister_window(tw);
  if (tw->ns_win) call0(tw->ns_win, "close");
  free(tw);
}

MOONBIT_FFI_EXPORT int32_t tycho_win_should_close(uint64_t p) {
  TychoMacWindow *tw = (TychoMacWindow *)(uintptr_t)p;
  return tw ? tw->should_close : 1;
}

MOONBIT_FFI_EXPORT void tycho_win_set_should_close(uint64_t p, int32_t v) {
  TychoMacWindow *tw = (TychoMacWindow *)(uintptr_t)p;
  if (tw) tw->should_close = v ? 1 : 0;
}

MOONBIT_FFI_EXPORT int32_t tycho_win_width(uint64_t p) {
  TychoMacWindow *tw = (TychoMacWindow *)(uintptr_t)p;
  return tw ? tw->width : 0;
}

MOONBIT_FFI_EXPORT int32_t tycho_win_height(uint64_t p) {
  TychoMacWindow *tw = (TychoMacWindow *)(uintptr_t)p;
  return tw ? tw->height : 0;
}

MOONBIT_FFI_EXPORT int32_t tycho_win_take_resized(uint64_t p) {
  TychoMacWindow *tw = (TychoMacWindow *)(uintptr_t)p;
  if (!tw) return 0;
  int32_t r = tw->resized;
  tw->resized = 0;
  return r;
}

MOONBIT_FFI_EXPORT void tycho_win_set_title(uint64_t p, uint64_t title_ptr) {
  TychoMacWindow *tw = (TychoMacWindow *)(uintptr_t)p;
  const char *title = (const char *)(uintptr_t)title_ptr;
  if (!tw || !tw->ns_win || !title) return;
  void *pool_cls = cls("NSAutoreleasePool");
  void *pool = pool_cls ? call0(pool_cls, "new") : NULL;
  void *ns_title = call1_ptr(cls("NSString"), "stringWithUTF8String:", (void *)title);
  if (ns_title) call1_ptr(tw->ns_win, "setTitle:", ns_title);
  if (pool) call0(pool, "drain");
}

MOONBIT_FFI_EXPORT double tycho_win_mouse_x(uint64_t p) {
  TychoMacWindow *tw = (TychoMacWindow *)(uintptr_t)p;
  return tw ? tw->mouse_x : 0.0;
}

MOONBIT_FFI_EXPORT double tycho_win_mouse_y(uint64_t p) {
  TychoMacWindow *tw = (TychoMacWindow *)(uintptr_t)p;
  return tw ? tw->mouse_y : 0.0;
}

MOONBIT_FFI_EXPORT int32_t tycho_win_mouse_button(uint64_t p, int32_t btn) {
  TychoMacWindow *tw = (TychoMacWindow *)(uintptr_t)p;
  if (!tw || btn < 1 || btn >= 32) return 0;
  return (tw->mouse_buttons & (1u << (uint32_t)btn)) ? 1 : 0;
}

MOONBIT_FFI_EXPORT int32_t tycho_win_next_event(uint64_t p, int32_t *out4) {
  TychoMacWindow *tw = (TychoMacWindow *)(uintptr_t)p;
  if (!tw || tw->ev_count <= 0) return 0;
  TychoMacEvent ev = tw->events[tw->ev_head];
  tw->ev_head = (tw->ev_head + 1) % TYCHO_MAX_EVENTS;
  tw->ev_count--;
  out4[0] = ev.kind;
  out4[1] = ev.a;
  out4[2] = ev.b;
  out4[3] = ev.c;
  return 1;
}

MOONBIT_FFI_EXPORT void tycho_win_poll(void) {
  if (!O.ns_app) return;
  typedef void *(*NextEvFn)(void *, void *, unsigned long long, void *, void *, signed char);
  NextEvFn next_ev = (NextEvFn)O.msgSend;
  void *s_next = sel("nextEventMatchingMask:untilDate:inMode:dequeue:");
  for (;;) {
    void *ev = next_ev(O.ns_app, s_next, ~0ULL, NULL, O.default_run_loop_mode, (signed char)1);
    if (!ev) break;
    long etype = call0_long(ev, "type");
    void *ewin = call0(ev, "window");
    TychoMacWindow *tw = find_window(ewin);
    if (tw) {
      unsigned long flags = call0_ulong(ev, "modifierFlags");
      switch (etype) {
        case 10: { // NSKeyDown
          unsigned short kc = (unsigned short)call0_ulong(ev, "keyCode");
          push_event(tw, 3, mac_keycode_to_tycho(kc), mac_mods(flags), 0);
          break;
        }
        case 11: { // NSKeyUp
          unsigned short kc = (unsigned short)call0_ulong(ev, "keyCode");
          push_event(tw, 4, mac_keycode_to_tycho(kc), mac_mods(flags), 0);
          break;
        }
        case 5: case 6: case 7: case 27: { // MouseMoved / Dragged
          TychoCGPoint pt = call0_point(ev, "locationInWindow");
          double y = (double)tw->height / (tw->scale > 0.0 ? tw->scale : 1.0) - pt.y;
          tw->mouse_x = pt.x;
          tw->mouse_y = y;
          push_event(tw, 5, (int32_t)tw->mouse_x, (int32_t)tw->mouse_y, 0);
          break;
        }
        case 1: case 3: case 25: { // MouseDown (L=1, R=3, O=25)
          int btn = (etype == 1) ? 1 : (etype == 3) ? 3 : 2;
          tw->mouse_buttons |= (1u << (uint32_t)btn);
          push_event(tw, 6, btn, (int32_t)tw->mouse_x, (int32_t)tw->mouse_y);
          break;
        }
        case 2: case 4: case 26: { // MouseUp
          int btn = (etype == 2) ? 1 : (etype == 4) ? 3 : 2;
          tw->mouse_buttons &= ~(1u << (uint32_t)btn);
          push_event(tw, 7, btn, (int32_t)tw->mouse_x, (int32_t)tw->mouse_y);
          break;
        }
        case 22: { // ScrollWheel
          double dy = call0_double(ev, "scrollingDeltaY");
          if (dy != 0.0) push_event(tw, 8, dy > 0.0 ? 1 : -1, 0, 0);
          break;
        }
        default: break;
      }
    }
    call1_ptr(O.ns_app, "sendEvent:", ev);
  }
  for (int i = 0; i < TYCHO_MAX_WINDOWS; i++) {
    TychoMacWindow *tw = g_windows[i];
    if (!tw || !tw->ns_win) continue;
    if (!tw->should_close && !call0_bool(tw->ns_win, "isVisible")) {
      tw->should_close = 1;
      push_event(tw, 1, 0, 0, 0);
    }
    double scale = call0_double(tw->ns_win, "backingScaleFactor");
    if (scale > 0.0 && scale != tw->scale) {
      tw->scale = scale;
      if (tw->metal_layer) call1_double(tw->metal_layer, "setContentsScale:", scale);
    }
    if (tw->ns_view) {
      TychoCGRect vr = call0_rect(tw->ns_view, "bounds");
      int pw = (int)(vr.size.width * tw->scale + 0.5);
      int ph = (int)(vr.size.height * tw->scale + 0.5);
      if (pw > 0 && ph > 0 && (pw != tw->width || ph != tw->height)) {
        tw->width = pw;
        tw->height = ph;
        tw->resized = 1;
        push_event(tw, 2, pw, ph, 0);
      }
    }
  }
}

MOONBIT_FFI_EXPORT double tycho_win_time(void) {
  if (!g_init_done) tycho_win_init();
  return now_sec() - g_start_time;
}

MOONBIT_FFI_EXPORT uint64_t tycho_win_display(uint64_t p) {
  TychoMacWindow *tw = (TychoMacWindow *)(uintptr_t)p;
  return tw ? (uint64_t)(uintptr_t)tw->ns_win : 0;
}

MOONBIT_FFI_EXPORT uint64_t tycho_win_handle(uint64_t p) {
  TychoMacWindow *tw = (TychoMacWindow *)(uintptr_t)p;
  return tw ? (uint64_t)(uintptr_t)tw->metal_layer : 0;
}

MOONBIT_FFI_EXPORT void tycho_win_set_cursor_mode(uint64_t p, int32_t mode) {
  TychoMacWindow *tw = (TychoMacWindow *)(uintptr_t)p;
  if (!tw) return;
  tw->cursor_mode = mode;
  void *c = cls("NSCursor");
  if (!c) return;
  int want_hidden = (mode != 0);
  if (want_hidden && !tw->cursor_hidden) {
    call0(c, "hide");
    tw->cursor_hidden = 1;
  } else if (!want_hidden && tw->cursor_hidden) {
    call0(c, "unhide");
    tw->cursor_hidden = 0;
  }
}

MOONBIT_FFI_EXPORT void tycho_win_set_fullscreen(uint64_t p, int32_t fs) {
  TychoMacWindow *tw = (TychoMacWindow *)(uintptr_t)p;
  if (!tw || !tw->ns_win) return;
  int want = fs ? 1 : 0;
  if (tw->fullscreen == want) return;
  tw->fullscreen = want;
  call1_ptr(tw->ns_win, "toggleFullScreen:", NULL);
}

MOONBIT_FFI_EXPORT int32_t tycho_win_is_fullscreen(uint64_t p) {
  TychoMacWindow *tw = (TychoMacWindow *)(uintptr_t)p;
  return tw ? tw->fullscreen : 0;
}

MOONBIT_FFI_EXPORT double tycho_win_content_scale(uint64_t p) {
  TychoMacWindow *tw = (TychoMacWindow *)(uintptr_t)p;
  return (tw && tw->scale > 0.0) ? tw->scale : 1.0;
}
#endif
