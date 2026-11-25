// Native Wayland backend for laplaceliu/tycho_window.
//
// libwayland-client, libxkbcommon and libwayland-cursor are loaded at runtime
// with dlopen, so:
//   * consumers need no extra link flags (only -lX11 -lvulkan, as before);
//   * no Wayland development headers or wayland-scanner are needed to build;
//   * X11-only systems keep working: if the libraries or a compositor are
//     missing, window_stub.c falls back to the Xlib backend.
//
// The client ABI subset below (wl_message / wl_interface / wl_proxy_*) has been
// stable since libwayland 1.0. Protocol tables for xdg-shell, xdg-decoration,
// pointer-constraints and relative-pointer are written by hand from the
// upstream (MIT-licensed) XML so wayland-scanner is not required.
#include "moonbit.h"
#include <stdint.h>

#if defined(__linux__)
#include <dlfcn.h>
#include <poll.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <time.h>
#include <unistd.h>

#define TYCHO_WL_MAX_EVENTS 128
#define TYCHO_WL_MAX_WINDOWS 16
#define TYCHO_WL_MAX_OUTPUTS 8

// ---------------------------------------------------------------------------
// Minimal libwayland-client ABI
// ---------------------------------------------------------------------------
struct wl_proxy;
struct wl_display;
struct wl_message {
  const char *name;
  const char *signature;
  const struct wl_interface **types;
};
struct wl_interface {
  const char *name;
  int version;
  int method_count;
  const struct wl_message *methods;
  int event_count;
  const struct wl_message *events;
};
struct wl_array {
  size_t size;
  size_t alloc;
  void *data;
};
typedef int32_t wl_fixed_t;
typedef void (*wl_fn)(void);

static double wl_fixed_to_d(wl_fixed_t f) { return (double)f / 256.0; }

static struct {
  void *lib;
  struct wl_display *(*display_connect)(const char *);
  int (*display_get_fd)(struct wl_display *);
  int (*display_dispatch_pending)(struct wl_display *);
  int (*display_flush)(struct wl_display *);
  int (*display_roundtrip)(struct wl_display *);
  int (*display_prepare_read)(struct wl_display *);
  int (*display_read_events)(struct wl_display *);
  void (*display_cancel_read)(struct wl_display *);
  int (*display_get_error)(struct wl_display *);
  void (*proxy_marshal)(struct wl_proxy *, uint32_t, ...);
  struct wl_proxy *(*proxy_marshal_constructor)(struct wl_proxy *, uint32_t,
                                                const struct wl_interface *, ...);
  struct wl_proxy *(*proxy_marshal_constructor_versioned)(
      struct wl_proxy *, uint32_t, const struct wl_interface *, uint32_t, ...);
  int (*proxy_add_listener)(struct wl_proxy *, wl_fn *, void *);
  void (*proxy_destroy)(struct wl_proxy *);
  const struct wl_interface *registry_iface;
  const struct wl_interface *compositor_iface;
  const struct wl_interface *surface_iface;
  const struct wl_interface *seat_iface;
  const struct wl_interface *pointer_iface;
  const struct wl_interface *keyboard_iface;
  const struct wl_interface *output_iface;
  const struct wl_interface *shm_iface;
} W;

// libxkbcommon (optional: keysym translation honours the user's layout).
static struct {
  void *lib;
  void *(*context_new)(int);
  void *(*keymap_new_from_string)(void *, const char *, int, int);
  void (*keymap_unref)(void *);
  void *(*state_new)(void *);
  void (*state_unref)(void *);
  int (*state_update_mask)(void *, uint32_t, uint32_t, uint32_t, uint32_t,
                           uint32_t, uint32_t);
  int (*keymap_key_get_syms_by_level)(void *, uint32_t, uint32_t, uint32_t,
                                      const uint32_t **);
  int (*state_mod_name_is_active)(void *, const char *, int);
  void *ctx;
  void *keymap;
  void *state;
} X;

// libwayland-cursor (optional: themed arrow cursor in Normal mode).
struct wl_cursor_image {
  uint32_t width, height, hotspot_x, hotspot_y, delay;
};
struct wl_cursor {
  unsigned int image_count;
  struct wl_cursor_image **images;
  char *name;
};
static struct {
  void *lib;
  void *(*theme_load)(const char *, int, struct wl_proxy *);
  struct wl_cursor *(*theme_get_cursor)(void *, const char *);
  struct wl_proxy *(*image_get_buffer)(struct wl_cursor_image *);
  void *theme;
  struct wl_cursor_image *image;
  struct wl_proxy *surface;
} C;

// ---------------------------------------------------------------------------
// Hand-written protocol tables
// ---------------------------------------------------------------------------
static const struct wl_interface *nulls[8] = {0};

static const struct wl_interface xdg_positioner_iface = {"xdg_positioner", 1, 0, 0, 0, 0};
static const struct wl_interface xdg_popup_iface = {"xdg_popup", 1, 0, 0, 0, 0};
static const struct wl_interface zwp_confined_pointer_v1_iface = {
    "zwp_confined_pointer_v1", 1, 0, 0, 0, 0};

// xdg_toplevel (v5)
static const struct wl_message xdg_toplevel_requests[] = {
    {"destroy", "", nulls},
    {"set_parent", "?o", nulls},
    {"set_title", "s", nulls},
    {"set_app_id", "s", nulls},
    {"show_window_menu", "ouii", nulls},
    {"move", "ou", nulls},
    {"resize", "ouu", nulls},
    {"set_max_size", "ii", nulls},
    {"set_min_size", "ii", nulls},
    {"set_maximized", "", nulls},
    {"unset_maximized", "", nulls},
    {"set_fullscreen", "?o", nulls},
    {"unset_fullscreen", "", nulls},
    {"set_minimized", "", nulls},
};
static const struct wl_message xdg_toplevel_events[] = {
    {"configure", "iia", nulls},
    {"close", "", nulls},
    {"configure_bounds", "4ii", nulls},
    {"wm_capabilities", "5a", nulls},
};
static const struct wl_interface xdg_toplevel_iface = {
    "xdg_toplevel", 5, 14, xdg_toplevel_requests, 4, xdg_toplevel_events};

// xdg_surface (v5)
static const struct wl_interface *xdg_surface_get_toplevel_types[] = {&xdg_toplevel_iface};
static const struct wl_interface *xdg_surface_get_popup_types[] = {
    &xdg_popup_iface, NULL, &xdg_positioner_iface};
static const struct wl_message xdg_surface_requests[] = {
    {"destroy", "", nulls},
    {"get_toplevel", "n", xdg_surface_get_toplevel_types},
    {"get_popup", "n?oo", xdg_surface_get_popup_types},
    {"set_window_geometry", "iiii", nulls},
    {"ack_configure", "u", nulls},
};
static const struct wl_message xdg_surface_events[] = {
    {"configure", "u", nulls},
};
static const struct wl_interface xdg_surface_iface = {
    "xdg_surface", 5, 5, xdg_surface_requests, 1, xdg_surface_events};

// xdg_wm_base (v5)
static const struct wl_interface *xdg_wm_base_positioner_types[] = {&xdg_positioner_iface};
static const struct wl_interface *xdg_wm_base_get_surface_types[] = {&xdg_surface_iface, NULL};
static const struct wl_message xdg_wm_base_requests[] = {
    {"destroy", "", nulls},
    {"create_positioner", "n", xdg_wm_base_positioner_types},
    {"get_xdg_surface", "no", xdg_wm_base_get_surface_types},
    {"pong", "u", nulls},
};
static const struct wl_message xdg_wm_base_events[] = {
    {"ping", "u", nulls},
};
static const struct wl_interface xdg_wm_base_iface = {
    "xdg_wm_base", 5, 4, xdg_wm_base_requests, 1, xdg_wm_base_events};

// zxdg_decoration_manager_v1 / zxdg_toplevel_decoration_v1
static const struct wl_message zxdg_toplevel_decoration_requests[] = {
    {"destroy", "", nulls},
    {"set_mode", "u", nulls},
    {"unset_mode", "", nulls},
};
static const struct wl_message zxdg_toplevel_decoration_events[] = {
    {"configure", "u", nulls},
};
static const struct wl_interface zxdg_toplevel_decoration_iface = {
    "zxdg_toplevel_decoration_v1", 1, 3, zxdg_toplevel_decoration_requests, 1,
    zxdg_toplevel_decoration_events};
static const struct wl_interface *zxdg_get_decoration_types[] = {
    &zxdg_toplevel_decoration_iface, &xdg_toplevel_iface};
static const struct wl_message zxdg_decoration_manager_requests[] = {
    {"destroy", "", nulls},
    {"get_toplevel_decoration", "no", zxdg_get_decoration_types},
};
static const struct wl_interface zxdg_decoration_manager_iface = {
    "zxdg_decoration_manager_v1", 1, 2, zxdg_decoration_manager_requests, 0, 0};

// zwp_pointer_constraints_v1 / zwp_locked_pointer_v1
static const struct wl_message zwp_locked_pointer_requests[] = {
    {"destroy", "", nulls},
    {"set_cursor_position_hint", "ff", nulls},
    {"set_region", "?o", nulls},
};
static const struct wl_message zwp_locked_pointer_events[] = {
    {"locked", "", nulls},
    {"unlocked", "", nulls},
};
static const struct wl_interface zwp_locked_pointer_iface = {
    "zwp_locked_pointer_v1", 1, 3, zwp_locked_pointer_requests, 2,
    zwp_locked_pointer_events};
static const struct wl_interface *zwp_lock_types[] = {&zwp_locked_pointer_iface, NULL, NULL,
                                                      NULL, NULL};
static const struct wl_interface *zwp_confine_types[] = {&zwp_confined_pointer_v1_iface, NULL,
                                                         NULL, NULL, NULL};
static const struct wl_message zwp_pointer_constraints_requests[] = {
    {"destroy", "", nulls},
    {"lock_pointer", "noo?ou", zwp_lock_types},
    {"confine_pointer", "noo?ou", zwp_confine_types},
};
static const struct wl_interface zwp_pointer_constraints_iface = {
    "zwp_pointer_constraints_v1", 1, 3, zwp_pointer_constraints_requests, 0, 0};

// zwp_relative_pointer_manager_v1 / zwp_relative_pointer_v1
static const struct wl_message zwp_relative_pointer_requests[] = {
    {"destroy", "", nulls},
};
static const struct wl_message zwp_relative_pointer_events[] = {
    {"relative_motion", "uuffff", nulls},
};
static const struct wl_interface zwp_relative_pointer_iface = {
    "zwp_relative_pointer_v1", 1, 1, zwp_relative_pointer_requests, 1,
    zwp_relative_pointer_events};
static const struct wl_interface *zwp_get_relative_types[] = {&zwp_relative_pointer_iface, NULL};
static const struct wl_message zwp_relative_pointer_manager_requests[] = {
    {"destroy", "", nulls},
    {"get_relative_pointer", "no", zwp_get_relative_types},
};
static const struct wl_interface zwp_relative_pointer_manager_iface = {
    "zwp_relative_pointer_manager_v1", 1, 2, zwp_relative_pointer_manager_requests, 0, 0};

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------
typedef struct TychoWlEvent {
  int32_t kind, a, b, c;
} TychoWlEvent;

typedef struct TychoWlWindow {
  struct wl_proxy *surface;
  struct wl_proxy *xdg_surface;
  struct wl_proxy *toplevel;
  struct wl_proxy *decoration;
  struct wl_proxy *locked;
  int should_close;
  int width, height;
  int pending_w, pending_h, pending_fs;
  int resized;
  int configured;
  int focused;
  int cursor_mode; // 0=Normal, 1=Hidden, 2=Locked
  int fullscreen;
  struct wl_proxy *entered[TYCHO_WL_MAX_OUTPUTS];
  int n_entered;
  double mouse_x, mouse_y;
  uint32_t mouse_buttons;
  TychoWlEvent events[TYCHO_WL_MAX_EVENTS];
  int ev_head, ev_tail, ev_count;
} TychoWlWindow;

typedef struct TychoWlOutput {
  struct wl_proxy *proxy;
  uint32_t name;
  int scale;
} TychoWlOutput;

static struct wl_display *g_wl = NULL;
static struct wl_proxy *g_registry, *g_compositor, *g_wm_base, *g_seat, *g_shm;
static struct wl_proxy *g_deco_mgr, *g_constraints, *g_rel_mgr;
static struct wl_proxy *g_pointer, *g_keyboard, *g_relative;
static uint32_t g_seat_version = 1;
static uint32_t g_pointer_serial = 0;
static TychoWlWindow *g_pointer_focus = NULL;
static TychoWlWindow *g_keyboard_focus = NULL;
static uint32_t g_xmods = 0; // X11-compatible modifier mask (Shift=1, Lock=2, Ctrl=4, Mod1=8)
static TychoWlWindow *g_wl_windows[TYCHO_WL_MAX_WINDOWS] = {0};
static TychoWlOutput g_outputs[TYCHO_WL_MAX_OUTPUTS];
static int g_n_outputs = 0;

static void wl_push_event(TychoWlWindow *tw, int32_t kind, int32_t a, int32_t b, int32_t c) {
  if (!tw) return;
  if (tw->ev_count == TYCHO_WL_MAX_EVENTS) {
    tw->ev_head = (tw->ev_head + 1) % TYCHO_WL_MAX_EVENTS;
    tw->ev_count--;
  }
  TychoWlEvent *e = &tw->events[tw->ev_tail];
  e->kind = kind;
  e->a = a;
  e->b = b;
  e->c = c;
  tw->ev_tail = (tw->ev_tail + 1) % TYCHO_WL_MAX_EVENTS;
  tw->ev_count++;
}

static TychoWlWindow *wl_find_window(struct wl_proxy *surface) {
  if (!surface) return NULL;
  for (int i = 0; i < TYCHO_WL_MAX_WINDOWS; i++) {
    if (g_wl_windows[i] && g_wl_windows[i]->surface == surface) return g_wl_windows[i];
  }
  return NULL;
}

static void add_listener(struct wl_proxy *p, const void *listener, void *data) {
  if (p) W.proxy_add_listener(p, (wl_fn *)listener, data);
}

static void destroy_with_request(struct wl_proxy *p, uint32_t destroy_opcode) {
  if (!p) return;
  W.proxy_marshal(p, destroy_opcode);
  W.proxy_destroy(p);
}

// ---------------------------------------------------------------------------
// Library loading
// ---------------------------------------------------------------------------
#define LOAD_SYM(lib, dst, name)                         \
  do {                                                   \
    *(void **)(&(dst)) = dlsym((lib), (name));           \
    if (!(dst)) return 0;                                \
  } while (0)

static int load_wayland(void) {
  if (W.lib) return 1;
  void *lib = dlopen("libwayland-client.so.0", RTLD_NOW | RTLD_LOCAL);
  if (!lib) return 0;
  LOAD_SYM(lib, W.display_connect, "wl_display_connect");
  LOAD_SYM(lib, W.display_get_fd, "wl_display_get_fd");
  LOAD_SYM(lib, W.display_dispatch_pending, "wl_display_dispatch_pending");
  LOAD_SYM(lib, W.display_flush, "wl_display_flush");
  LOAD_SYM(lib, W.display_roundtrip, "wl_display_roundtrip");
  LOAD_SYM(lib, W.display_prepare_read, "wl_display_prepare_read");
  LOAD_SYM(lib, W.display_read_events, "wl_display_read_events");
  LOAD_SYM(lib, W.display_cancel_read, "wl_display_cancel_read");
  LOAD_SYM(lib, W.display_get_error, "wl_display_get_error");
  LOAD_SYM(lib, W.proxy_marshal, "wl_proxy_marshal");
  LOAD_SYM(lib, W.proxy_marshal_constructor, "wl_proxy_marshal_constructor");
  LOAD_SYM(lib, W.proxy_marshal_constructor_versioned,
           "wl_proxy_marshal_constructor_versioned");
  LOAD_SYM(lib, W.proxy_add_listener, "wl_proxy_add_listener");
  LOAD_SYM(lib, W.proxy_destroy, "wl_proxy_destroy");
  LOAD_SYM(lib, W.registry_iface, "wl_registry_interface");
  LOAD_SYM(lib, W.compositor_iface, "wl_compositor_interface");
  LOAD_SYM(lib, W.surface_iface, "wl_surface_interface");
  LOAD_SYM(lib, W.seat_iface, "wl_seat_interface");
  LOAD_SYM(lib, W.pointer_iface, "wl_pointer_interface");
  LOAD_SYM(lib, W.keyboard_iface, "wl_keyboard_interface");
  LOAD_SYM(lib, W.output_iface, "wl_output_interface");
  LOAD_SYM(lib, W.shm_iface, "wl_shm_interface");
  W.lib = lib;
  return 1;
}

static int load_xkb(void) {
  if (X.lib) return 1;
  void *lib = dlopen("libxkbcommon.so.0", RTLD_NOW | RTLD_LOCAL);
  if (!lib) return 0;
  LOAD_SYM(lib, X.context_new, "xkb_context_new");
  LOAD_SYM(lib, X.keymap_new_from_string, "xkb_keymap_new_from_string");
  LOAD_SYM(lib, X.keymap_unref, "xkb_keymap_unref");
  LOAD_SYM(lib, X.state_new, "xkb_state_new");
  LOAD_SYM(lib, X.state_unref, "xkb_state_unref");
  LOAD_SYM(lib, X.state_update_mask, "xkb_state_update_mask");
  LOAD_SYM(lib, X.keymap_key_get_syms_by_level, "xkb_keymap_key_get_syms_by_level");
  LOAD_SYM(lib, X.state_mod_name_is_active, "xkb_state_mod_name_is_active");
  X.ctx = X.context_new(0);
  if (!X.ctx) return 0;
  X.lib = lib;
  return 1;
}

static int load_cursor(void) {
  if (C.lib) return 1;
  void *lib = dlopen("libwayland-cursor.so.0", RTLD_NOW | RTLD_LOCAL);
  if (!lib) return 0;
  LOAD_SYM(lib, C.theme_load, "wl_cursor_theme_load");
  LOAD_SYM(lib, C.theme_get_cursor, "wl_cursor_theme_get_cursor");
  LOAD_SYM(lib, C.image_get_buffer, "wl_cursor_image_get_buffer");
  C.lib = lib;
  return 1;
}

// ---------------------------------------------------------------------------
// Keyboard: evdev keycode -> X11 keysym (matches the KEY_* constants)
// ---------------------------------------------------------------------------
static uint32_t evdev_fallback_keysym(uint32_t key) {
  static const char row1[] = "1234567890";  // evdev 2..11
  static const char row2[] = "qwertyuiop";  // evdev 16..25
  static const char row3[] = "asdfghjkl";   // evdev 30..38
  static const char row4[] = "zxcvbnm";     // evdev 44..50
  if (key >= 2 && key <= 11) return (uint32_t)row1[key - 2];
  if (key >= 16 && key <= 25) return (uint32_t)row2[key - 16];
  if (key >= 30 && key <= 38) return (uint32_t)row3[key - 30];
  if (key >= 44 && key <= 50) return (uint32_t)row4[key - 44];
  if (key >= 59 && key <= 68) return 0xffbe + (key - 59); // F1..F10
  switch (key) {
    case 1: return 0xff1b;   // Escape
    case 14: return 0xff08;  // BackSpace
    case 15: return 0xff09;  // Tab
    case 28: return 0xff0d;  // Return
    case 29: return 0xffe3;  // Control_L
    case 42: return 0xffe1;  // Shift_L
    case 54: return 0xffe2;  // Shift_R
    case 56: return 0xffe9;  // Alt_L
    case 57: return 0x0020;  // space
    case 87: return 0xffc8;  // F11
    case 88: return 0xffc9;  // F12
    case 97: return 0xffe4;  // Control_R
    case 100: return 0xffea; // Alt_R
    case 103: return 0xff52; // Up
    case 105: return 0xff51; // Left
    case 106: return 0xff53; // Right
    case 108: return 0xff54; // Down
    default: return 0;
  }
}

static uint32_t keysym_for(uint32_t key) {
  if (X.keymap) {
    const uint32_t *syms = NULL;
    // Level 0 of layout 0 == XLookupKeysym(ev, 0) on the X11 backend.
    int n = X.keymap_key_get_syms_by_level(X.keymap, key + 8, 0, 0, &syms);
    if (n > 0 && syms) return syms[0];
  }
  return evdev_fallback_keysym(key);
}

static void kb_keymap(void *d, struct wl_proxy *kb, uint32_t format, int32_t fd, uint32_t size) {
  (void)d; (void)kb;
  if (format != 1 /* WL_KEYBOARD_KEYMAP_FORMAT_XKB_V1 */ || !load_xkb()) {
    close(fd);
    return;
  }
  char *map = mmap(NULL, size, PROT_READ, MAP_PRIVATE, fd, 0);
  close(fd);
  if (map == MAP_FAILED) return;
  void *keymap = X.keymap_new_from_string(X.ctx, map, 1 /* TEXT_V1 */, 0);
  munmap(map, size);
  if (!keymap) return;
  void *state = X.state_new(keymap);
  if (!state) {
    X.keymap_unref(keymap);
    return;
  }
  if (X.state) X.state_unref(X.state);
  if (X.keymap) X.keymap_unref(X.keymap);
  X.keymap = keymap;
  X.state = state;
}

static void kb_enter(void *d, struct wl_proxy *kb, uint32_t serial, struct wl_proxy *surface,
                     struct wl_array *keys) {
  (void)d; (void)kb; (void)serial; (void)keys;
  TychoWlWindow *tw = wl_find_window(surface);
  g_keyboard_focus = tw;
  if (tw) {
    tw->focused = 1;
    wl_push_event(tw, 9, 1, 0, 0);
  }
}

static void kb_leave(void *d, struct wl_proxy *kb, uint32_t serial, struct wl_proxy *surface) {
  (void)d; (void)kb; (void)serial;
  TychoWlWindow *tw = wl_find_window(surface);
  if (tw) {
    tw->focused = 0;
    wl_push_event(tw, 9, 0, 0, 0);
  }
  if (g_keyboard_focus == tw) g_keyboard_focus = NULL;
}

static void kb_key(void *d, struct wl_proxy *kb, uint32_t serial, uint32_t time, uint32_t key,
                   uint32_t state) {
  (void)d; (void)kb; (void)serial; (void)time;
  if (!g_keyboard_focus) return;
  uint32_t ks = keysym_for(key);
  if (ks == 0) return;
  // state: 0 = released, 1 = pressed (2 = repeated, wl_keyboard v10+).
  wl_push_event(g_keyboard_focus, state ? 3 : 4, (int32_t)ks, (int32_t)g_xmods, 0);
  if (state && !(g_xmods & 4u) && !(g_xmods & 8u)) {
    // Emit printable ASCII/Latin-1 codepoint as TextInput (kind 10)
    if (ks >= 0x20 && ks <= 0x7e) {
      wl_push_event(g_keyboard_focus, 10, (int32_t)ks, 0, 0);
    }
  }
}

static void kb_modifiers(void *d, struct wl_proxy *kb, uint32_t serial, uint32_t depressed,
                         uint32_t latched, uint32_t locked, uint32_t group) {
  (void)d; (void)kb; (void)serial;
  if (!X.state) return;
  X.state_update_mask(X.state, depressed, latched, locked, 0, 0, group);
  const int effective = 1 << 3; // XKB_STATE_MODS_EFFECTIVE
  uint32_t m = 0;
  if (X.state_mod_name_is_active(X.state, "Shift", effective) > 0) m |= 1;
  if (X.state_mod_name_is_active(X.state, "Lock", effective) > 0) m |= 2;
  if (X.state_mod_name_is_active(X.state, "Control", effective) > 0) m |= 4;
  if (X.state_mod_name_is_active(X.state, "Mod1", effective) > 0) m |= 8;
  g_xmods = m;
}

static void kb_repeat_info(void *d, struct wl_proxy *kb, int32_t rate, int32_t delay) {
  (void)d; (void)kb; (void)rate; (void)delay;
}

static const struct {
  void (*keymap)(void *, struct wl_proxy *, uint32_t, int32_t, uint32_t);
  void (*enter)(void *, struct wl_proxy *, uint32_t, struct wl_proxy *, struct wl_array *);
  void (*leave)(void *, struct wl_proxy *, uint32_t, struct wl_proxy *);
  void (*key)(void *, struct wl_proxy *, uint32_t, uint32_t, uint32_t, uint32_t);
  void (*modifiers)(void *, struct wl_proxy *, uint32_t, uint32_t, uint32_t, uint32_t, uint32_t);
  void (*repeat_info)(void *, struct wl_proxy *, int32_t, int32_t);
} keyboard_listener = {kb_keymap, kb_enter, kb_leave, kb_key, kb_modifiers, kb_repeat_info};

// ---------------------------------------------------------------------------
// Pointer
// ---------------------------------------------------------------------------
static void apply_cursor(TychoWlWindow *tw) {
  if (!g_pointer || !tw || g_pointer_focus != tw) return;
  if (tw->cursor_mode == 0 && C.image && C.surface) {
    // wl_pointer.set_cursor(serial, surface, hotspot_x, hotspot_y)
    W.proxy_marshal(g_pointer, 0, g_pointer_serial, C.surface, (int32_t)C.image->hotspot_x,
                    (int32_t)C.image->hotspot_y);
  } else {
    W.proxy_marshal(g_pointer, 0, g_pointer_serial, (struct wl_proxy *)NULL, 0, 0);
  }
}

static void ensure_cursor_theme(void) {
  if (C.theme || !g_shm || !g_compositor || !load_cursor()) return;
  const char *theme = getenv("XCURSOR_THEME");
  const char *size_s = getenv("XCURSOR_SIZE");
  int size = size_s ? atoi(size_s) : 24;
  if (size <= 0) size = 24;
  C.theme = C.theme_load(theme, size, g_shm);
  if (!C.theme) return;
  struct wl_cursor *cur = C.theme_get_cursor(C.theme, "left_ptr");
  if (!cur) cur = C.theme_get_cursor(C.theme, "default");
  if (!cur || cur->image_count == 0) return;
  C.image = cur->images[0];
  struct wl_proxy *buf = C.image_get_buffer(C.image);
  if (!buf) return;
  C.surface = W.proxy_marshal_constructor(g_compositor, 0, W.surface_iface, NULL);
  if (!C.surface) return;
  W.proxy_marshal(C.surface, 1, buf, 0, 0);                                         // attach
  W.proxy_marshal(C.surface, 2, 0, 0, (int32_t)C.image->width, (int32_t)C.image->height); // damage
  W.proxy_marshal(C.surface, 6);                                                    // commit
}

static void ptr_enter(void *d, struct wl_proxy *p, uint32_t serial, struct wl_proxy *surface,
                      wl_fixed_t x, wl_fixed_t y) {
  (void)d; (void)p;
  g_pointer_serial = serial;
  TychoWlWindow *tw = wl_find_window(surface);
  g_pointer_focus = tw;
  if (!tw) return;
  if (tw->cursor_mode != 2) {
    tw->mouse_x = wl_fixed_to_d(x);
    tw->mouse_y = wl_fixed_to_d(y);
  }
  ensure_cursor_theme();
  apply_cursor(tw);
}

static void ptr_leave(void *d, struct wl_proxy *p, uint32_t serial, struct wl_proxy *surface) {
  (void)d; (void)p; (void)serial;
  if (g_pointer_focus == wl_find_window(surface)) g_pointer_focus = NULL;
}

static void ptr_motion(void *d, struct wl_proxy *p, uint32_t time, wl_fixed_t x, wl_fixed_t y) {
  (void)d; (void)p; (void)time;
  TychoWlWindow *tw = g_pointer_focus;
  if (!tw || (tw->cursor_mode == 2 && tw->locked)) return; // relative_motion drives Locked
  tw->mouse_x = wl_fixed_to_d(x);
  tw->mouse_y = wl_fixed_to_d(y);
  wl_push_event(tw, 5, (int32_t)tw->mouse_x, (int32_t)tw->mouse_y, 0);
}

static void ptr_button(void *d, struct wl_proxy *p, uint32_t serial, uint32_t time,
                       uint32_t button, uint32_t state) {
  (void)d; (void)p; (void)time;
  g_pointer_serial = serial;
  TychoWlWindow *tw = g_pointer_focus;
  if (!tw) return;
  // Linux input codes -> X11 button numbers (1=left, 2=middle, 3=right, 8/9=side).
  int btn;
  switch (button) {
    case 0x110: btn = 1; break; // BTN_LEFT
    case 0x111: btn = 3; break; // BTN_RIGHT
    case 0x112: btn = 2; break; // BTN_MIDDLE
    case 0x113: btn = 8; break; // BTN_SIDE
    case 0x114: btn = 9; break; // BTN_EXTRA
    default: btn = 10 + (int)(button & 0xf); break;
  }
  if (state) {
    tw->mouse_buttons |= (1u << (uint32_t)btn);
    wl_push_event(tw, 6, btn, (int32_t)tw->mouse_x, (int32_t)tw->mouse_y);
  } else {
    tw->mouse_buttons &= ~(1u << (uint32_t)btn);
    wl_push_event(tw, 7, btn, (int32_t)tw->mouse_x, (int32_t)tw->mouse_y);
  }
}

static void ptr_axis(void *d, struct wl_proxy *p, uint32_t time, uint32_t axis, wl_fixed_t v) {
  (void)d; (void)p; (void)time;
  TychoWlWindow *tw = g_pointer_focus;
  if (!tw || v == 0) return;
  if (axis == 0 /* VERTICAL_SCROLL */) {
    wl_push_event(tw, 8, 0, v > 0 ? -1 : 1, 0);
  } else if (axis == 1 /* HORIZONTAL_SCROLL */) {
    wl_push_event(tw, 8, v > 0 ? 1 : -1, 0, 0);
  }
}

static void ptr_frame(void *d, struct wl_proxy *p) { (void)d; (void)p; }
static void ptr_axis_source(void *d, struct wl_proxy *p, uint32_t s) { (void)d; (void)p; (void)s; }
static void ptr_axis_stop(void *d, struct wl_proxy *p, uint32_t t, uint32_t a) {
  (void)d; (void)p; (void)t; (void)a;
}
static void ptr_axis_discrete(void *d, struct wl_proxy *p, uint32_t a, int32_t v) {
  (void)d; (void)p; (void)a; (void)v;
}

static const struct {
  void (*enter)(void *, struct wl_proxy *, uint32_t, struct wl_proxy *, wl_fixed_t, wl_fixed_t);
  void (*leave)(void *, struct wl_proxy *, uint32_t, struct wl_proxy *);
  void (*motion)(void *, struct wl_proxy *, uint32_t, wl_fixed_t, wl_fixed_t);
  void (*button)(void *, struct wl_proxy *, uint32_t, uint32_t, uint32_t, uint32_t);
  void (*axis)(void *, struct wl_proxy *, uint32_t, uint32_t, wl_fixed_t);
  void (*frame)(void *, struct wl_proxy *);
  void (*axis_source)(void *, struct wl_proxy *, uint32_t);
  void (*axis_stop)(void *, struct wl_proxy *, uint32_t, uint32_t);
  void (*axis_discrete)(void *, struct wl_proxy *, uint32_t, int32_t);
} pointer_listener = {ptr_enter,  ptr_leave,       ptr_motion,    ptr_button,       ptr_axis,
                      ptr_frame, ptr_axis_source, ptr_axis_stop, ptr_axis_discrete};

static void rel_motion(void *d, struct wl_proxy *p, uint32_t hi, uint32_t lo, wl_fixed_t dx,
                       wl_fixed_t dy, wl_fixed_t udx, wl_fixed_t udy) {
  (void)d; (void)p; (void)hi; (void)lo; (void)udx; (void)udy;
  TychoWlWindow *tw = g_pointer_focus;
  if (!tw || tw->cursor_mode != 2) return;
  tw->mouse_x += wl_fixed_to_d(dx);
  tw->mouse_y += wl_fixed_to_d(dy);
  wl_push_event(tw, 5, (int32_t)tw->mouse_x, (int32_t)tw->mouse_y, 0);
}

static const struct {
  void (*relative_motion)(void *, struct wl_proxy *, uint32_t, uint32_t, wl_fixed_t, wl_fixed_t,
                          wl_fixed_t, wl_fixed_t);
} relative_listener = {rel_motion};

static void locked_noop(void *d, struct wl_proxy *p) { (void)d; (void)p; }
static const struct {
  void (*locked)(void *, struct wl_proxy *);
  void (*unlocked)(void *, struct wl_proxy *);
} locked_listener = {locked_noop, locked_noop};

// ---------------------------------------------------------------------------
// Seat / output / registry / shell
// ---------------------------------------------------------------------------
static void seat_capabilities(void *d, struct wl_proxy *seat, uint32_t caps) {
  (void)d;
  int has_pointer = (caps & 1) != 0;
  int has_keyboard = (caps & 2) != 0;
  if (has_pointer && !g_pointer) {
    g_pointer = W.proxy_marshal_constructor(seat, 0, W.pointer_iface, NULL);
    add_listener(g_pointer, &pointer_listener, NULL);
    if (g_rel_mgr && g_pointer) {
      g_relative = W.proxy_marshal_constructor(g_rel_mgr, 1, &zwp_relative_pointer_iface, NULL,
                                               g_pointer);
      add_listener(g_relative, &relative_listener, NULL);
    }
  } else if (!has_pointer && g_pointer) {
    destroy_with_request(g_relative, 0);
    g_relative = NULL;
    if (g_seat_version >= 3) destroy_with_request(g_pointer, 1); // release
    else W.proxy_destroy(g_pointer);
    g_pointer = NULL;
    g_pointer_focus = NULL;
  }
  if (has_keyboard && !g_keyboard) {
    g_keyboard = W.proxy_marshal_constructor(seat, 1, W.keyboard_iface, NULL);
    add_listener(g_keyboard, &keyboard_listener, NULL);
  } else if (!has_keyboard && g_keyboard) {
    if (g_seat_version >= 3) destroy_with_request(g_keyboard, 0); // release
    else W.proxy_destroy(g_keyboard);
    g_keyboard = NULL;
    g_keyboard_focus = NULL;
  }
}

static void seat_name(void *d, struct wl_proxy *seat, const char *name) {
  (void)d; (void)seat; (void)name;
}

static const struct {
  void (*capabilities)(void *, struct wl_proxy *, uint32_t);
  void (*name)(void *, struct wl_proxy *, const char *);
} seat_listener = {seat_capabilities, seat_name};

static void out_geometry(void *d, struct wl_proxy *o, int32_t x, int32_t y, int32_t pw,
                         int32_t ph, int32_t sub, const char *make, const char *model,
                         int32_t transform) {
  (void)d; (void)o; (void)x; (void)y; (void)pw; (void)ph; (void)sub; (void)make; (void)model;
  (void)transform;
}
static void out_mode(void *d, struct wl_proxy *o, uint32_t f, int32_t w, int32_t h, int32_t r) {
  (void)d; (void)o; (void)f; (void)w; (void)h; (void)r;
}
static void out_done(void *d, struct wl_proxy *o) { (void)d; (void)o; }
static void out_scale(void *d, struct wl_proxy *o, int32_t factor) {
  (void)o;
  TychoWlOutput *out = (TychoWlOutput *)d;
  if (out && factor > 0) out->scale = factor;
}

static const struct {
  void (*geometry)(void *, struct wl_proxy *, int32_t, int32_t, int32_t, int32_t, int32_t,
                   const char *, const char *, int32_t);
  void (*mode)(void *, struct wl_proxy *, uint32_t, int32_t, int32_t, int32_t);
  void (*done)(void *, struct wl_proxy *);
  void (*scale)(void *, struct wl_proxy *, int32_t);
} output_listener = {out_geometry, out_mode, out_done, out_scale};

static void wm_base_ping(void *d, struct wl_proxy *wm, uint32_t serial) {
  (void)d;
  W.proxy_marshal(wm, 3, serial); // pong
}

static const struct {
  void (*ping)(void *, struct wl_proxy *, uint32_t);
} wm_base_listener = {wm_base_ping};

static uint32_t min_u32(uint32_t a, uint32_t b) { return a < b ? a : b; }

static struct wl_proxy *bind_global(uint32_t name, const struct wl_interface *iface,
                                    uint32_t version) {
  return W.proxy_marshal_constructor_versioned(g_registry, 0, iface, version, name, iface->name,
                                               version, NULL);
}

static void registry_global(void *d, struct wl_proxy *reg, uint32_t name, const char *iface,
                            uint32_t version) {
  (void)d; (void)reg;
  if (strcmp(iface, "wl_compositor") == 0 && !g_compositor) {
    g_compositor = bind_global(name, W.compositor_iface, min_u32(version, 4));
  } else if (strcmp(iface, "xdg_wm_base") == 0 && !g_wm_base) {
    g_wm_base = bind_global(name, &xdg_wm_base_iface, min_u32(version, 5));
    add_listener(g_wm_base, &wm_base_listener, NULL);
  } else if (strcmp(iface, "wl_seat") == 0 && !g_seat) {
    g_seat_version = min_u32(version, 5);
    g_seat = bind_global(name, W.seat_iface, g_seat_version);
    add_listener(g_seat, &seat_listener, NULL);
  } else if (strcmp(iface, "wl_shm") == 0 && !g_shm) {
    g_shm = bind_global(name, W.shm_iface, 1);
  } else if (strcmp(iface, "wl_output") == 0 && g_n_outputs < TYCHO_WL_MAX_OUTPUTS) {
    TychoWlOutput *out = &g_outputs[g_n_outputs];
    out->proxy = bind_global(name, W.output_iface, min_u32(version, 2));
    out->name = name;
    out->scale = 1;
    if (out->proxy) {
      add_listener(out->proxy, &output_listener, out);
      g_n_outputs++;
    }
  } else if (strcmp(iface, "zxdg_decoration_manager_v1") == 0 && !g_deco_mgr) {
    g_deco_mgr = bind_global(name, &zxdg_decoration_manager_iface, 1);
  } else if (strcmp(iface, "zwp_pointer_constraints_v1") == 0 && !g_constraints) {
    g_constraints = bind_global(name, &zwp_pointer_constraints_iface, 1);
  } else if (strcmp(iface, "zwp_relative_pointer_manager_v1") == 0 && !g_rel_mgr) {
    g_rel_mgr = bind_global(name, &zwp_relative_pointer_manager_iface, 1);
  }
}

static void registry_global_remove(void *d, struct wl_proxy *reg, uint32_t name) {
  (void)d; (void)reg;
  for (int i = 0; i < g_n_outputs; i++) {
    if (g_outputs[i].name == name) {
      struct wl_proxy *gone = g_outputs[i].proxy;
      for (int w = 0; w < TYCHO_WL_MAX_WINDOWS; w++) {
        TychoWlWindow *tw = g_wl_windows[w];
        if (!tw) continue;
        for (int k = 0; k < tw->n_entered; k++) {
          if (tw->entered[k] == gone) tw->entered[k] = tw->entered[--tw->n_entered];
        }
      }
      W.proxy_destroy(gone);
      g_outputs[i] = g_outputs[--g_n_outputs];
      return;
    }
  }
}

static const struct {
  void (*global)(void *, struct wl_proxy *, uint32_t, const char *, uint32_t);
  void (*global_remove)(void *, struct wl_proxy *, uint32_t);
} registry_listener = {registry_global, registry_global_remove};

static void surface_enter(void *d, struct wl_proxy *s, struct wl_proxy *output) {
  (void)s;
  TychoWlWindow *tw = (TychoWlWindow *)d;
  if (tw && tw->n_entered < TYCHO_WL_MAX_OUTPUTS) tw->entered[tw->n_entered++] = output;
}

static void surface_leave(void *d, struct wl_proxy *s, struct wl_proxy *output) {
  (void)s;
  TychoWlWindow *tw = (TychoWlWindow *)d;
  if (!tw) return;
  for (int k = 0; k < tw->n_entered; k++) {
    if (tw->entered[k] == output) {
      tw->entered[k] = tw->entered[--tw->n_entered];
      return;
    }
  }
}

static const struct {
  void (*enter)(void *, struct wl_proxy *, struct wl_proxy *);
  void (*leave)(void *, struct wl_proxy *, struct wl_proxy *);
} surface_listener = {surface_enter, surface_leave};

static void xdg_surface_configure(void *d, struct wl_proxy *xs, uint32_t serial) {
  TychoWlWindow *tw = (TychoWlWindow *)d;
  if (tw) {
    if (tw->pending_w > 0 && tw->pending_h > 0 &&
        (tw->pending_w != tw->width || tw->pending_h != tw->height)) {
      tw->width = tw->pending_w;
      tw->height = tw->pending_h;
      tw->resized = 1;
      wl_push_event(tw, 2, tw->width, tw->height, 0);
    }
    tw->fullscreen = tw->pending_fs;
    tw->configured = 1;
  }
  W.proxy_marshal(xs, 4, serial); // ack_configure
}

static const struct {
  void (*configure)(void *, struct wl_proxy *, uint32_t);
} xdg_surface_listener = {xdg_surface_configure};

static void toplevel_configure(void *d, struct wl_proxy *t, int32_t w, int32_t h,
                               struct wl_array *states) {
  (void)t;
  TychoWlWindow *tw = (TychoWlWindow *)d;
  if (!tw) return;
  // 0x0 means "client picks": keep the current size.
  tw->pending_w = w;
  tw->pending_h = h;
  tw->pending_fs = 0;
  if (states && states->data) {
    const uint32_t *s = (const uint32_t *)states->data;
    size_t n = states->size / sizeof(uint32_t);
    for (size_t i = 0; i < n; i++) {
      if (s[i] == 2 /* XDG_TOPLEVEL_STATE_FULLSCREEN */) tw->pending_fs = 1;
    }
  }
}

static void toplevel_close(void *d, struct wl_proxy *t) {
  (void)t;
  TychoWlWindow *tw = (TychoWlWindow *)d;
  if (!tw) return;
  tw->should_close = 1;
  wl_push_event(tw, 1, 0, 0, 0);
}

static void toplevel_bounds(void *d, struct wl_proxy *t, int32_t w, int32_t h) {
  (void)d; (void)t; (void)w; (void)h;
}

static void toplevel_caps(void *d, struct wl_proxy *t, struct wl_array *caps) {
  (void)d; (void)t; (void)caps;
}

static const struct {
  void (*configure)(void *, struct wl_proxy *, int32_t, int32_t, struct wl_array *);
  void (*close)(void *, struct wl_proxy *);
  void (*configure_bounds)(void *, struct wl_proxy *, int32_t, int32_t);
  void (*wm_capabilities)(void *, struct wl_proxy *, struct wl_array *);
} toplevel_listener = {toplevel_configure, toplevel_close, toplevel_bounds, toplevel_caps};

static void deco_configure(void *d, struct wl_proxy *p, uint32_t mode) {
  (void)d; (void)p; (void)mode;
}
static const struct {
  void (*configure)(void *, struct wl_proxy *, uint32_t);
} deco_listener = {deco_configure};

// ---------------------------------------------------------------------------
// Backend entry points (called from window_stub.c)
// ---------------------------------------------------------------------------
static void mark_all_closed(void) {
  for (int i = 0; i < TYCHO_WL_MAX_WINDOWS; i++) {
    TychoWlWindow *tw = g_wl_windows[i];
    if (tw && !tw->should_close) {
      tw->should_close = 1;
      wl_push_event(tw, 1, 0, 0, 0);
    }
  }
}

int tycho_wl_connect(void) {
  if (g_wl) return 1;
  if (!load_wayland()) return 0;
  struct wl_display *dpy = W.display_connect(NULL);
  if (!dpy) return 0;
  g_wl = dpy;
  // wl_display.get_registry (opcode 1)
  g_registry = W.proxy_marshal_constructor((struct wl_proxy *)dpy, 1, W.registry_iface, NULL);
  add_listener(g_registry, &registry_listener, NULL);
  W.display_roundtrip(dpy); // globals
  W.display_roundtrip(dpy); // seat capabilities, output scale
  if (!g_compositor || !g_wm_base) {
    // Not a desktop compositor we can map toplevels on: let the caller fall
    // back to X11. Proxies are intentionally leaked with the connection.
    g_wl = NULL;
    return 0;
  }
  return 1;
}

uint64_t tycho_wl_display(void) { return (uint64_t)(uintptr_t)g_wl; }

uint64_t tycho_wl_create(int32_t w, int32_t h, const char *title) {
  if (!g_wl && !tycho_wl_connect()) return 0;
  int slot = -1;
  for (int i = 0; i < TYCHO_WL_MAX_WINDOWS; i++) {
    if (!g_wl_windows[i]) {
      slot = i;
      break;
    }
  }
  if (slot < 0) return 0;
  TychoWlWindow *tw = (TychoWlWindow *)calloc(1, sizeof(TychoWlWindow));
  if (!tw) return 0;
  tw->width = w > 0 ? w : 1;
  tw->height = h > 0 ? h : 1;
  tw->focused = 0;
  tw->surface = W.proxy_marshal_constructor(g_compositor, 0, W.surface_iface, NULL);
  if (!tw->surface) {
    free(tw);
    return 0;
  }
  add_listener(tw->surface, &surface_listener, tw);
  tw->xdg_surface =
      W.proxy_marshal_constructor(g_wm_base, 2, &xdg_surface_iface, NULL, tw->surface);
  add_listener(tw->xdg_surface, &xdg_surface_listener, tw);
  tw->toplevel = W.proxy_marshal_constructor(tw->xdg_surface, 1, &xdg_toplevel_iface, NULL);
  add_listener(tw->toplevel, &toplevel_listener, tw);
  if (title) W.proxy_marshal(tw->toplevel, 2, title); // set_title
  W.proxy_marshal(tw->toplevel, 3, "tycho");           // set_app_id
  if (g_deco_mgr) {
    tw->decoration = W.proxy_marshal_constructor(g_deco_mgr, 1, &zxdg_toplevel_decoration_iface,
                                                 NULL, tw->toplevel);
    add_listener(tw->decoration, &deco_listener, tw);
    if (tw->decoration) W.proxy_marshal(tw->decoration, 1, 2u); // SERVER_SIDE
  }
  g_wl_windows[slot] = tw;
  // Initial commit without a buffer, then wait for the first configure: the
  // swapchain may only attach buffers to an acknowledged xdg_surface.
  W.proxy_marshal(tw->surface, 6);
  for (int i = 0; i < 20 && !tw->configured; i++) {
    if (W.display_roundtrip(g_wl) < 0) break;
  }
  return (uint64_t)(uintptr_t)tw;
}

static void unlock_pointer(TychoWlWindow *tw) {
  if (tw->locked) {
    destroy_with_request(tw->locked, 0);
    tw->locked = NULL;
  }
}

void tycho_wl_destroy(uint64_t p) {
  TychoWlWindow *tw = (TychoWlWindow *)(uintptr_t)p;
  if (!tw) return;
  for (int i = 0; i < TYCHO_WL_MAX_WINDOWS; i++) {
    if (g_wl_windows[i] == tw) g_wl_windows[i] = NULL;
  }
  if (g_pointer_focus == tw) g_pointer_focus = NULL;
  if (g_keyboard_focus == tw) g_keyboard_focus = NULL;
  unlock_pointer(tw);
  destroy_with_request(tw->decoration, 0);
  destroy_with_request(tw->toplevel, 0);
  destroy_with_request(tw->xdg_surface, 0);
  destroy_with_request(tw->surface, 0);
  if (g_wl) W.display_flush(g_wl);
  free(tw);
}

void tycho_wl_poll(void) {
  if (!g_wl) return;
  while (W.display_prepare_read(g_wl) != 0) {
    if (W.display_dispatch_pending(g_wl) < 0) break;
  }
  W.display_flush(g_wl);
  struct pollfd pfd = {W.display_get_fd(g_wl), POLLIN, 0};
  if (poll(&pfd, 1, 0) > 0 && (pfd.revents & POLLIN)) {
    W.display_read_events(g_wl);
  } else {
    W.display_cancel_read(g_wl);
  }
  W.display_dispatch_pending(g_wl);
  if (W.display_get_error(g_wl) != 0) mark_all_closed(); // compositor went away
}

int32_t tycho_wl_should_close(uint64_t p) {
  TychoWlWindow *tw = (TychoWlWindow *)(uintptr_t)p;
  return tw ? tw->should_close : 1;
}

void tycho_wl_set_should_close(uint64_t p, int32_t v) {
  TychoWlWindow *tw = (TychoWlWindow *)(uintptr_t)p;
  if (tw) tw->should_close = v ? 1 : 0;
}

int32_t tycho_wl_width(uint64_t p) {
  TychoWlWindow *tw = (TychoWlWindow *)(uintptr_t)p;
  return tw ? tw->width : 0;
}

int32_t tycho_wl_height(uint64_t p) {
  TychoWlWindow *tw = (TychoWlWindow *)(uintptr_t)p;
  return tw ? tw->height : 0;
}

int32_t tycho_wl_take_resized(uint64_t p) {
  TychoWlWindow *tw = (TychoWlWindow *)(uintptr_t)p;
  if (!tw) return 0;
  int32_t r = tw->resized;
  tw->resized = 0;
  return r;
}

void tycho_wl_set_title(uint64_t p, const char *title) {
  TychoWlWindow *tw = (TychoWlWindow *)(uintptr_t)p;
  if (!tw || !tw->toplevel || !title) return;
  W.proxy_marshal(tw->toplevel, 2, title);
  W.display_flush(g_wl);
}

double tycho_wl_mouse_x(uint64_t p) {
  TychoWlWindow *tw = (TychoWlWindow *)(uintptr_t)p;
  return tw ? tw->mouse_x : 0.0;
}

double tycho_wl_mouse_y(uint64_t p) {
  TychoWlWindow *tw = (TychoWlWindow *)(uintptr_t)p;
  return tw ? tw->mouse_y : 0.0;
}

int32_t tycho_wl_mouse_button(uint64_t p, int32_t btn) {
  TychoWlWindow *tw = (TychoWlWindow *)(uintptr_t)p;
  if (!tw || btn < 1 || btn >= 32) return 0;
  return (tw->mouse_buttons & (1u << (uint32_t)btn)) ? 1 : 0;
}

int32_t tycho_wl_next_event(uint64_t p, int32_t *out4) {
  TychoWlWindow *tw = (TychoWlWindow *)(uintptr_t)p;
  if (!tw || tw->ev_count <= 0) return 0;
  TychoWlEvent ev = tw->events[tw->ev_head];
  tw->ev_head = (tw->ev_head + 1) % TYCHO_WL_MAX_EVENTS;
  tw->ev_count--;
  out4[0] = ev.kind;
  out4[1] = ev.a;
  out4[2] = ev.b;
  out4[3] = ev.c;
  return 1;
}

uint64_t tycho_wl_surface(uint64_t p) {
  TychoWlWindow *tw = (TychoWlWindow *)(uintptr_t)p;
  return tw ? (uint64_t)(uintptr_t)tw->surface : 0;
}

void tycho_wl_set_cursor_mode(uint64_t p, int32_t mode) {
  TychoWlWindow *tw = (TychoWlWindow *)(uintptr_t)p;
  if (!tw) return;
  if (mode != 2) unlock_pointer(tw);
  tw->cursor_mode = mode;
  if (mode == 2 && !tw->locked && g_constraints && g_pointer) {
    // lock_pointer(id, surface, pointer, region=NULL, lifetime=PERSISTENT(2))
    tw->locked = W.proxy_marshal_constructor(g_constraints, 1, &zwp_locked_pointer_iface, NULL,
                                             tw->surface, g_pointer, (struct wl_proxy *)NULL, 2u);
    add_listener(tw->locked, &locked_listener, tw);
  }
  ensure_cursor_theme();
  apply_cursor(tw);
  W.display_flush(g_wl);
}

void tycho_wl_set_cursor_shape(uint64_t p, int32_t shape) {
  TychoWlWindow *tw = (TychoWlWindow *)(uintptr_t)p;
  if (!tw || !C.theme || !C.surface || tw->cursor_mode != 0) return;
  static const char *names[6] = {"left_ptr", "pointer", "xterm", "crosshair", "ew-resize", "ns-resize"};
  const char *name = (shape >= 0 && shape < 6) ? names[shape] : "left_ptr";
  struct wl_cursor *cur = C.theme_get_cursor(C.theme, name);
  if (!cur && shape == 1) cur = C.theme_get_cursor(C.theme, "hand2");
  if (!cur && shape == 2) cur = C.theme_get_cursor(C.theme, "text");
  if (!cur) cur = C.theme_get_cursor(C.theme, "left_ptr");
  if (!cur || cur->image_count == 0) return;
  C.image = cur->images[0];
  struct wl_proxy *buf = C.image_get_buffer(C.image);
  if (!buf) return;
  W.proxy_marshal(C.surface, 1, buf, 0, 0);
  W.proxy_marshal(C.surface, 2, 0, 0, (int32_t)C.image->width, (int32_t)C.image->height);
  W.proxy_marshal(C.surface, 6);
  apply_cursor(tw);
  W.display_flush(g_wl);
}

void tycho_wl_set_fullscreen(uint64_t p, int32_t fs) {
  TychoWlWindow *tw = (TychoWlWindow *)(uintptr_t)p;
  if (!tw || !tw->toplevel) return;
  if (fs) {
    W.proxy_marshal(tw->toplevel, 11, (struct wl_proxy *)NULL); // set_fullscreen(output=NULL)
  } else {
    W.proxy_marshal(tw->toplevel, 12); // unset_fullscreen
  }
  // The compositor confirms through configure; wait for it so is_fullscreen()
  // reflects the request like the X11 backend does.
  W.display_roundtrip(g_wl);
  tycho_wl_poll();
}

int32_t tycho_wl_is_fullscreen(uint64_t p) {
  TychoWlWindow *tw = (TychoWlWindow *)(uintptr_t)p;
  return tw ? tw->fullscreen : 0;
}

double tycho_wl_content_scale(uint64_t p) {
  TychoWlWindow *tw = (TychoWlWindow *)(uintptr_t)p;
  if (!tw) return 1.0;
  int best = 0;
  for (int k = 0; k < tw->n_entered; k++) {
    for (int i = 0; i < g_n_outputs; i++) {
      if (g_outputs[i].proxy == tw->entered[k] && g_outputs[i].scale > best) {
        best = g_outputs[i].scale;
      }
    }
  }
  if (best == 0 && g_n_outputs > 0) best = g_outputs[0].scale;
  return best > 0 ? (double)best : 1.0;
}
#endif
