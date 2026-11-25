// Native Win32 window backend for laplaceliu/tycho_window.
// Loads user32.dll dynamically via LoadLibraryA so consumers need zero
// user32.lib / gdi32.lib link flags.
#if defined(_WIN32)
#define WIN32_LEAN_AND_MEAN
#define NOMINMAX
#include <windows.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include "moonbit.h"

#define TYCHO_MAX_WINDOWS 16
#define TYCHO_MAX_EVENTS 128

typedef struct TychoWin32Event {
  int32_t kind;
  int32_t a;
  int32_t b;
  int32_t c;
} TychoWin32Event;

typedef struct TychoWin32Window {
  HWND hwnd;
  HINSTANCE hinst;
  int should_close;
  int width;
  int height;
  int resized;
  int focused;
  int cursor_mode; // 0=Normal, 1=Hidden, 2=Locked
  int cursor_hidden;
  int cursor_shape;
  uint16_t high_surrogate;
  int fullscreen;
  int ignore_warp;
  DWORD saved_style;
  WINDOWPLACEMENT saved_place;
  double mouse_x;
  double mouse_y;
  uint32_t mouse_buttons;
  TychoWin32Event events[TYCHO_MAX_EVENTS];
  int ev_head;
  int ev_tail;
  int ev_count;
} TychoWin32Window;

// Dynamic user32.dll function table (zero user32.lib link requirement).
static struct {
  HMODULE dll;
  ATOM (WINAPI *RegisterClassExA)(const WNDCLASSEXA *);
  HWND (WINAPI *CreateWindowExA)(DWORD, LPCSTR, LPCSTR, DWORD, int, int, int,
                                 int, HWND, HMENU, HINSTANCE, LPVOID);
  BOOL (WINAPI *DestroyWindow)(HWND);
  LRESULT (WINAPI *DefWindowProcA)(HWND, UINT, WPARAM, LPARAM);
  BOOL (WINAPI *ShowWindow)(HWND, int);
  BOOL (WINAPI *UpdateWindow)(HWND);
  BOOL (WINAPI *SetWindowTextA)(HWND, LPCSTR);
  BOOL (WINAPI *PeekMessageA)(LPMSG, HWND, UINT, UINT, UINT);
  BOOL (WINAPI *TranslateMessage)(const MSG *);
  LRESULT (WINAPI *DispatchMessageA)(const MSG *);
  BOOL (WINAPI *GetClientRect)(HWND, LPRECT);
  BOOL (WINAPI *AdjustWindowRectEx)(LPRECT, DWORD, BOOL, DWORD);
  LONG (WINAPI *GetWindowLongA)(HWND, int);
  LONG (WINAPI *SetWindowLongA)(HWND, int, LONG);
#ifdef _WIN64
  LONG_PTR (WINAPI *GetWindowLongPtrA)(HWND, int);
  LONG_PTR (WINAPI *SetWindowLongPtrA)(HWND, int, LONG_PTR);
#endif
  BOOL (WINAPI *GetWindowPlacement)(HWND, WINDOWPLACEMENT *);
  BOOL (WINAPI *SetWindowPlacement)(HWND, const WINDOWPLACEMENT *);
  HMONITOR (WINAPI *MonitorFromWindow)(HWND, DWORD);
  BOOL (WINAPI *GetMonitorInfoA)(HMONITOR, LPMONITORINFO);
  BOOL (WINAPI *SetWindowPos)(HWND, HWND, int, int, int, int, UINT);
  int (WINAPI *ShowCursor)(BOOL);
  BOOL (WINAPI *ClipCursor)(const RECT *);
  BOOL (WINAPI *SetCursorPos)(int, int);
  BOOL (WINAPI *ClientToScreen)(HWND, LPPOINT);
  SHORT (WINAPI *GetKeyState)(int);
  HCURSOR (WINAPI *LoadCursorA)(HINSTANCE, LPCSTR);
  HCURSOR (WINAPI *SetCursor)(HCURSOR);
  BOOL (WINAPI *ValidateRect)(HWND, const RECT *);
  BOOL (WINAPI *OpenClipboard)(HWND);
  BOOL (WINAPI *CloseClipboard)(void);
  BOOL (WINAPI *EmptyClipboard)(void);
  HANDLE (WINAPI *GetClipboardData)(UINT);
  HANDLE (WINAPI *SetClipboardData)(UINT, HANDLE);
  UINT (WINAPI *GetDpiForWindow)(HWND);
  BOOL (WINAPI *SetProcessDpiAwarenessContext)(HANDLE);
  DWORD (WINAPI *MsgWaitForMultipleObjectsEx)(DWORD, const HANDLE *, DWORD, DWORD, DWORD);
} U;

static TychoWin32Window *g_windows[TYCHO_MAX_WINDOWS] = {0};
static int g_init_done = 0;
static int g_class_registered = 0;
static HINSTANCE g_hinst = NULL;
static LARGE_INTEGER g_qpc_freq;
static LARGE_INTEGER g_qpc_start;

static void push_event(TychoWin32Window *tw, int32_t kind, int32_t a,
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

static void register_window(TychoWin32Window *tw) {
  for (int i = 0; i < TYCHO_MAX_WINDOWS; i++) {
    if (!g_windows[i]) {
      g_windows[i] = tw;
      return;
    }
  }
}

static void unregister_window(TychoWin32Window *tw) {
  for (int i = 0; i < TYCHO_MAX_WINDOWS; i++) {
    if (g_windows[i] == tw) {
      g_windows[i] = NULL;
      return;
    }
  }
}

static TychoWin32Window *find_window(HWND hwnd) {
  for (int i = 0; i < TYCHO_MAX_WINDOWS; i++) {
    if (g_windows[i] && g_windows[i]->hwnd == hwnd) {
      return g_windows[i];
    }
  }
  return NULL;
}

static int32_t vk_to_tycho_key(WPARAM vk) {
  if (vk >= '0' && vk <= '9') return (int32_t)vk;
  if (vk >= 'A' && vk <= 'Z') return (int32_t)(vk + 32); // lowercase ASCII matches KEY_A..KEY_Z
  if (vk >= VK_F1 && vk <= VK_F12) return 0xffbe + (int32_t)(vk - VK_F1);
  switch (vk) {
    case VK_ESCAPE: return 0xff1b;
    case VK_RETURN: return 0xff0d;
    case VK_TAB: return 0xff09;
    case VK_BACK: return 0xff08;
    case VK_SPACE: return 0x0020;
    case VK_LEFT: return 0xff51;
    case VK_UP: return 0xff52;
    case VK_RIGHT: return 0xff53;
    case VK_DOWN: return 0xff54;
    case VK_SHIFT:
      return (U.GetKeyState && (U.GetKeyState(VK_RSHIFT) & 0x8000)) ? 0xffe2 : 0xffe1;
    case VK_LSHIFT: return 0xffe1;
    case VK_RSHIFT: return 0xffe2;
    case VK_CONTROL:
      return (U.GetKeyState && (U.GetKeyState(VK_RCONTROL) & 0x8000)) ? 0xffe4 : 0xffe3;
    case VK_LCONTROL: return 0xffe3;
    case VK_RCONTROL: return 0xffe4;
    case VK_MENU:
      return (U.GetKeyState && (U.GetKeyState(VK_RMENU) & 0x8000)) ? 0xffea : 0xffe9;
    case VK_LMENU: return 0xffe9;
    case VK_RMENU: return 0xffea;
    default: return (int32_t)vk;
  }
}

static int32_t query_mods(void) {
  int32_t mods = 0;
  if (!U.GetKeyState) return 0;
  if (U.GetKeyState(VK_SHIFT) & 0x8000) mods |= 1;
  if (U.GetKeyState(VK_CONTROL) & 0x8000) mods |= 4;
  if (U.GetKeyState(VK_MENU) & 0x8000) mods |= 8;
  return mods;
}

static void warp_to_center(TychoWin32Window *tw) {
  if (!tw || !tw->hwnd || !U.ClientToScreen || !U.SetCursorPos) return;
  POINT pt;
  pt.x = tw->width / 2;
  pt.y = tw->height / 2;
  U.ClientToScreen(tw->hwnd, &pt);
  tw->ignore_warp = 1;
  U.SetCursorPos(pt.x, pt.y);
}

static void update_clip(TychoWin32Window *tw) {
  if (!U.ClipCursor) return;
  if (tw && tw->cursor_mode == 2 && tw->focused && tw->hwnd && U.ClientToScreen) {
    RECT rc;
    rc.left = 0;
    rc.top = 0;
    rc.right = tw->width;
    rc.bottom = tw->height;
    POINT tl = {rc.left, rc.top};
    POINT br = {rc.right, rc.bottom};
    U.ClientToScreen(tw->hwnd, &tl);
    U.ClientToScreen(tw->hwnd, &br);
    rc.left = tl.x;
    rc.top = tl.y;
    rc.right = br.x;
    rc.bottom = br.y;
    U.ClipCursor(&rc);
  } else {
    U.ClipCursor(NULL);
  }
}

static LRESULT CALLBACK tycho_wndproc(HWND hwnd, UINT msg, WPARAM wp, LPARAM lp) {
  TychoWin32Window *tw = find_window(hwnd);
  if (!tw) {
    return U.DefWindowProcA ? U.DefWindowProcA(hwnd, msg, wp, lp) : 0;
  }
  switch (msg) {
    case WM_CLOSE:
      tw->should_close = 1;
      push_event(tw, 1, 0, 0, 0);
      return 0;
    case WM_ERASEBKGND:
      return 1;
    case WM_PAINT:
      if (U.ValidateRect) U.ValidateRect(hwnd, NULL);
      return 0;
    case WM_SIZE:
      if (wp != SIZE_MINIMIZED) {
        int w = (int)(LOWORD(lp));
        int h = (int)(HIWORD(lp));
        if (w > 0 && h > 0 && (w != tw->width || h != tw->height)) {
          tw->width = w;
          tw->height = h;
          tw->resized = 1;
          push_event(tw, 2, w, h, 0);
          if (tw->cursor_mode == 2 && tw->focused) update_clip(tw);
        }
      }
      return 0;
    case WM_SETFOCUS:
      tw->focused = 1;
      push_event(tw, 9, 1, 0, 0);
      if (tw->cursor_mode == 2) {
        update_clip(tw);
        warp_to_center(tw);
      }
      return 0;
    case WM_KILLFOCUS:
      tw->focused = 0;
      push_event(tw, 9, 0, 0, 0);
      if (U.ClipCursor) U.ClipCursor(NULL);
      return 0;
    case WM_KEYDOWN:
    case WM_SYSKEYDOWN:
      push_event(tw, 3, vk_to_tycho_key(wp), query_mods(), 0);
      return 0;
    case WM_KEYUP:
    case WM_SYSKEYUP:
      push_event(tw, 4, vk_to_tycho_key(wp), query_mods(), 0);
      return 0;
    case WM_CHAR: {
      uint32_t ch = (uint32_t)wp;
      if (ch >= 0xD800 && ch <= 0xDBFF) {
        tw->high_surrogate = (uint16_t)ch;
      } else if (ch >= 0xDC00 && ch <= 0xDFFF && tw->high_surrogate) {
        uint32_t cp = 0x10000u + (((uint32_t)(tw->high_surrogate - 0xD800u) << 10) | (ch - 0xDC00u));
        tw->high_surrogate = 0;
        push_event(tw, 10, (int32_t)cp, 0, 0);
      } else {
        tw->high_surrogate = 0;
        if (ch >= 0x20 && ch != 0x7F) {
          push_event(tw, 10, (int32_t)ch, 0, 0);
        }
      }
      return 0;
    }
    case WM_MOUSEMOVE: {
      int x = (int)(short)LOWORD(lp);
      int y = (int)(short)HIWORD(lp);
      if (tw->cursor_mode == 2 && tw->focused) {
        int cx = tw->width / 2;
        int cy = tw->height / 2;
        if (tw->ignore_warp && x == cx && y == cy) {
          tw->ignore_warp = 0;
          return 0;
        }
        int dx = x - cx;
        int dy = y - cy;
        tw->mouse_x += (double)dx;
        tw->mouse_y += (double)dy;
        push_event(tw, 5, (int32_t)tw->mouse_x, (int32_t)tw->mouse_y, 0);
        if (dx != 0 || dy != 0) warp_to_center(tw);
      } else {
        tw->mouse_x = (double)x;
        tw->mouse_y = (double)y;
        push_event(tw, 5, x, y, 0);
      }
      return 0;
    }
    case WM_LBUTTONDOWN:
      tw->mouse_buttons |= (1u << 1);
      push_event(tw, 6, 1, (int)(short)LOWORD(lp), (int)(short)HIWORD(lp));
      return 0;
    case WM_LBUTTONUP:
      tw->mouse_buttons &= ~(1u << 1);
      push_event(tw, 7, 1, (int)(short)LOWORD(lp), (int)(short)HIWORD(lp));
      return 0;
    case WM_MBUTTONDOWN:
      tw->mouse_buttons |= (1u << 2);
      push_event(tw, 6, 2, (int)(short)LOWORD(lp), (int)(short)HIWORD(lp));
      return 0;
    case WM_MBUTTONUP:
      tw->mouse_buttons &= ~(1u << 2);
      push_event(tw, 7, 2, (int)(short)LOWORD(lp), (int)(short)HIWORD(lp));
      return 0;
    case WM_RBUTTONDOWN:
      tw->mouse_buttons |= (1u << 3);
      push_event(tw, 6, 3, (int)(short)LOWORD(lp), (int)(short)HIWORD(lp));
      return 0;
    case WM_RBUTTONUP:
      tw->mouse_buttons &= ~(1u << 3);
      push_event(tw, 7, 3, (int)(short)LOWORD(lp), (int)(short)HIWORD(lp));
      return 0;
    case WM_MOUSEWHEEL: {
      short delta = GET_WHEEL_DELTA_WPARAM(wp);
      if (delta != 0) push_event(tw, 8, 0, delta > 0 ? 1 : -1, 0);
      return 0;
    }
    case 0x020E: { // WM_MOUSEHWHEEL
      short delta = GET_WHEEL_DELTA_WPARAM(wp);
      if (delta != 0) push_event(tw, 8, delta > 0 ? 1 : -1, 0, 0);
      return 0;
    }
    case WM_SETCURSOR:
      if (LOWORD(lp) == 1 && tw->cursor_mode == 0 && U.LoadCursorA && U.SetCursor) {
        static const uintptr_t ids[6] = {32512, 32649, 32513, 32515, 32644, 32645};
        int s = (tw->cursor_shape >= 0 && tw->cursor_shape < 6) ? tw->cursor_shape : 0;
        U.SetCursor(U.LoadCursorA(NULL, (LPCSTR)ids[s]));
        return TRUE;
      }
      return U.DefWindowProcA ? U.DefWindowProcA(hwnd, msg, wp, lp) : 0;
    default:
      return U.DefWindowProcA ? U.DefWindowProcA(hwnd, msg, wp, lp) : 0;
  }
}

static int load_user32(void) {
  if (U.dll) return 1;
  HMODULE dll = LoadLibraryA("user32.dll");
  if (!dll) return 0;
#define LOAD(fn) *(FARPROC *)&U.fn = GetProcAddress(dll, #fn)
  LOAD(RegisterClassExA);
  LOAD(CreateWindowExA);
  LOAD(DestroyWindow);
  LOAD(DefWindowProcA);
  LOAD(ShowWindow);
  LOAD(UpdateWindow);
  LOAD(SetWindowTextA);
  LOAD(PeekMessageA);
  LOAD(TranslateMessage);
  LOAD(DispatchMessageA);
  LOAD(GetClientRect);
  LOAD(AdjustWindowRectEx);
  LOAD(GetWindowLongA);
  LOAD(SetWindowLongA);
#ifdef _WIN64
  LOAD(GetWindowLongPtrA);
  LOAD(SetWindowLongPtrA);
#endif
  LOAD(GetWindowPlacement);
  LOAD(SetWindowPlacement);
  LOAD(MonitorFromWindow);
  LOAD(GetMonitorInfoA);
  LOAD(SetWindowPos);
  LOAD(ShowCursor);
  LOAD(ClipCursor);
  LOAD(SetCursorPos);
  LOAD(ClientToScreen);
  LOAD(GetKeyState);
  LOAD(LoadCursorA);
  LOAD(SetCursor);
  LOAD(ValidateRect);
  LOAD(OpenClipboard);
  LOAD(CloseClipboard);
  LOAD(EmptyClipboard);
  LOAD(GetClipboardData);
  LOAD(SetClipboardData);
  LOAD(GetDpiForWindow);
  LOAD(SetProcessDpiAwarenessContext);
  LOAD(MsgWaitForMultipleObjectsEx);
#undef LOAD
  if (!U.RegisterClassExA || !U.CreateWindowExA || !U.DestroyWindow ||
      !U.DefWindowProcA || !U.PeekMessageA) {
    return 0;
  }
  U.dll = dll;
  return 1;
}

MOONBIT_FFI_EXPORT int32_t tycho_win_init(void) {
  if (!g_init_done) {
    QueryPerformanceFrequency(&g_qpc_freq);
    QueryPerformanceCounter(&g_qpc_start);
    g_hinst = GetModuleHandleA(NULL);
    g_init_done = 1;
    if (!load_user32()) return 0;
    if (U.SetProcessDpiAwarenessContext) {
      U.SetProcessDpiAwarenessContext((HANDLE)(intptr_t)-4);
    }
  }
  return U.dll ? 1 : 0;
}

MOONBIT_FFI_EXPORT int32_t tycho_win_is_wayland(void) { return 0; }
MOONBIT_FFI_EXPORT void tycho_win_terminate(void) {}

MOONBIT_FFI_EXPORT uint64_t tycho_win_create(int32_t w, int32_t h, uint64_t title_ptr) {
  if (!tycho_win_init()) return 0;
  if (!g_class_registered) {
    WNDCLASSEXA wc;
    memset(&wc, 0, sizeof(wc));
    wc.cbSize = sizeof(wc);
    wc.style = CS_OWNDC;
    wc.lpfnWndProc = tycho_wndproc;
    wc.hInstance = g_hinst;
    wc.hCursor = U.LoadCursorA ? U.LoadCursorA(NULL, IDC_ARROW) : NULL;
    wc.lpszClassName = "TychoWindowClass";
    if (!U.RegisterClassExA(&wc)) return 0;
    g_class_registered = 1;
  }
  DWORD style = WS_OVERLAPPEDWINDOW;
  RECT rc = {0, 0, w, h};
  if (U.AdjustWindowRectEx) U.AdjustWindowRectEx(&rc, style, FALSE, 0);
  const char *title = (const char *)(uintptr_t)title_ptr;
  HWND hwnd = U.CreateWindowExA(0, "TychoWindowClass", title ? title : "Tycho",
                                style, CW_USEDEFAULT, CW_USEDEFAULT,
                                rc.right - rc.left, rc.bottom - rc.top,
                                NULL, NULL, g_hinst, NULL);
  if (!hwnd) return 0;
  TychoWin32Window *tw = (TychoWin32Window *)calloc(1, sizeof(TychoWin32Window));
  tw->hwnd = hwnd;
  tw->hinst = g_hinst;
  tw->width = w;
  tw->height = h;
  tw->focused = 1;
  tw->saved_place.length = sizeof(WINDOWPLACEMENT);
  register_window(tw);
  if (U.GetClientRect) {
    RECT cr;
    if (U.GetClientRect(hwnd, &cr) && cr.right > 0 && cr.bottom > 0) {
      tw->width = cr.right - cr.left;
      tw->height = cr.bottom - cr.top;
    }
  }
  if (U.ShowWindow) U.ShowWindow(hwnd, SW_SHOW);
  if (U.UpdateWindow) U.UpdateWindow(hwnd);
  return (uint64_t)(uintptr_t)tw;
}

MOONBIT_FFI_EXPORT void tycho_win_destroy(uint64_t p) {
  TychoWin32Window *tw = (TychoWin32Window *)(uintptr_t)p;
  if (!tw) return;
  if (tw->cursor_hidden && U.ShowCursor) {
    U.ShowCursor(TRUE);
    tw->cursor_hidden = 0;
  }
  if (tw->cursor_mode == 2 && U.ClipCursor) U.ClipCursor(NULL);
  unregister_window(tw);
  if (tw->hwnd && U.DestroyWindow) U.DestroyWindow(tw->hwnd);
  free(tw);
}

MOONBIT_FFI_EXPORT int32_t tycho_win_should_close(uint64_t p) {
  TychoWin32Window *tw = (TychoWin32Window *)(uintptr_t)p;
  return tw ? tw->should_close : 1;
}

MOONBIT_FFI_EXPORT void tycho_win_set_should_close(uint64_t p, int32_t v) {
  TychoWin32Window *tw = (TychoWin32Window *)(uintptr_t)p;
  if (tw) tw->should_close = v ? 1 : 0;
}

MOONBIT_FFI_EXPORT int32_t tycho_win_width(uint64_t p) {
  TychoWin32Window *tw = (TychoWin32Window *)(uintptr_t)p;
  return tw ? tw->width : 0;
}

MOONBIT_FFI_EXPORT int32_t tycho_win_height(uint64_t p) {
  TychoWin32Window *tw = (TychoWin32Window *)(uintptr_t)p;
  return tw ? tw->height : 0;
}

MOONBIT_FFI_EXPORT int32_t tycho_win_take_resized(uint64_t p) {
  TychoWin32Window *tw = (TychoWin32Window *)(uintptr_t)p;
  if (!tw) return 0;
  int32_t r = tw->resized;
  tw->resized = 0;
  return r;
}

MOONBIT_FFI_EXPORT void tycho_win_set_title(uint64_t p, uint64_t title_ptr) {
  TychoWin32Window *tw = (TychoWin32Window *)(uintptr_t)p;
  const char *title = (const char *)(uintptr_t)title_ptr;
  if (tw && tw->hwnd && title && U.SetWindowTextA) U.SetWindowTextA(tw->hwnd, title);
}

MOONBIT_FFI_EXPORT double tycho_win_mouse_x(uint64_t p) {
  TychoWin32Window *tw = (TychoWin32Window *)(uintptr_t)p;
  return tw ? tw->mouse_x : 0.0;
}

MOONBIT_FFI_EXPORT double tycho_win_mouse_y(uint64_t p) {
  TychoWin32Window *tw = (TychoWin32Window *)(uintptr_t)p;
  return tw ? tw->mouse_y : 0.0;
}

MOONBIT_FFI_EXPORT int32_t tycho_win_mouse_button(uint64_t p, int32_t btn) {
  TychoWin32Window *tw = (TychoWin32Window *)(uintptr_t)p;
  if (!tw || btn < 1 || btn >= 32) return 0;
  return (tw->mouse_buttons & (1u << (uint32_t)btn)) ? 1 : 0;
}

MOONBIT_FFI_EXPORT int32_t tycho_win_next_event(uint64_t p, int32_t *out4) {
  TychoWin32Window *tw = (TychoWin32Window *)(uintptr_t)p;
  if (!tw || tw->ev_count <= 0) return 0;
  TychoWin32Event ev = tw->events[tw->ev_head];
  tw->ev_head = (tw->ev_head + 1) % TYCHO_MAX_EVENTS;
  tw->ev_count--;
  out4[0] = ev.kind;
  out4[1] = ev.a;
  out4[2] = ev.b;
  out4[3] = ev.c;
  return 1;
}

MOONBIT_FFI_EXPORT void tycho_win_poll(void) {
  if (!U.PeekMessageA) return;
  MSG msg;
  while (U.PeekMessageA(&msg, NULL, 0, 0, PM_REMOVE)) {
    if (U.TranslateMessage) U.TranslateMessage(&msg);
    if (U.DispatchMessageA) U.DispatchMessageA(&msg);
  }
}

MOONBIT_FFI_EXPORT double tycho_win_time(void) {
  if (!g_init_done) tycho_win_init();
  LARGE_INTEGER now;
  QueryPerformanceCounter(&now);
  return (double)(now.QuadPart - g_qpc_start.QuadPart) / (double)g_qpc_freq.QuadPart;
}

MOONBIT_FFI_EXPORT uint64_t tycho_win_display(uint64_t p) {
  TychoWin32Window *tw = (TychoWin32Window *)(uintptr_t)p;
  return tw ? (uint64_t)(uintptr_t)tw->hinst : 0;
}

MOONBIT_FFI_EXPORT uint64_t tycho_win_handle(uint64_t p) {
  TychoWin32Window *tw = (TychoWin32Window *)(uintptr_t)p;
  return tw ? (uint64_t)(uintptr_t)tw->hwnd : 0;
}

MOONBIT_FFI_EXPORT void tycho_win_set_cursor_mode(uint64_t p, int32_t mode) {
  TychoWin32Window *tw = (TychoWin32Window *)(uintptr_t)p;
  if (!tw) return;
  tw->cursor_mode = mode;
  int want_hidden = (mode != 0);
  if (want_hidden && !tw->cursor_hidden && U.ShowCursor) {
    U.ShowCursor(FALSE);
    tw->cursor_hidden = 1;
  } else if (!want_hidden && tw->cursor_hidden && U.ShowCursor) {
    U.ShowCursor(TRUE);
    tw->cursor_hidden = 0;
  }
  update_clip(tw);
  if (mode == 2 && tw->focused) warp_to_center(tw);
}

static char *g_win32_clipboard = NULL;

MOONBIT_FFI_EXPORT void tycho_win_set_cursor_shape(uint64_t p, int32_t shape) {
  TychoWin32Window *tw = (TychoWin32Window *)(uintptr_t)p;
  if (!tw) return;
  tw->cursor_shape = shape;
  if (tw->cursor_mode == 0 && U.LoadCursorA && U.SetCursor) {
    static const uintptr_t ids[6] = {32512, 32649, 32513, 32515, 32644, 32645};
    int s = (shape >= 0 && shape < 6) ? shape : 0;
    U.SetCursor(U.LoadCursorA(NULL, (LPCSTR)ids[s]));
  }
}

MOONBIT_FFI_EXPORT void tycho_win_set_clipboard(uint64_t p, uint64_t text_ptr) {
  TychoWin32Window *tw = (TychoWin32Window *)(uintptr_t)p;
  const char *text = (const char *)(uintptr_t)text_ptr;
  free(g_win32_clipboard);
  g_win32_clipboard = text ? _strdup(text) : NULL;
  if (!text || !U.OpenClipboard || !U.EmptyClipboard || !U.SetClipboardData || !U.CloseClipboard) return;
  if (!U.OpenClipboard(tw ? tw->hwnd : NULL)) return;
  U.EmptyClipboard();
  int wlen = MultiByteToWideChar(CP_UTF8, 0, text, -1, NULL, 0);
  if (wlen > 0) {
    HGLOBAL hg = GlobalAlloc(GMEM_MOVEABLE, (size_t)wlen * sizeof(wchar_t));
    if (hg) {
      wchar_t *dst = (wchar_t *)GlobalLock(hg);
      if (dst) {
        MultiByteToWideChar(CP_UTF8, 0, text, -1, dst, wlen);
        GlobalUnlock(hg);
        U.SetClipboardData(CF_UNICODETEXT, hg);
      } else {
        GlobalFree(hg);
      }
    }
  }
  U.CloseClipboard();
}

MOONBIT_FFI_EXPORT uint64_t tycho_win_get_clipboard(uint64_t p) {
  TychoWin32Window *tw = (TychoWin32Window *)(uintptr_t)p;
  if (U.OpenClipboard && U.GetClipboardData && U.CloseClipboard &&
      U.OpenClipboard(tw ? tw->hwnd : NULL)) {
    HANDLE hg = U.GetClipboardData(CF_UNICODETEXT);
    char *out = NULL;
    if (hg) {
      const wchar_t *ws = (const wchar_t *)GlobalLock(hg);
      if (ws) {
        int u8len = WideCharToMultiByte(CP_UTF8, 0, ws, -1, NULL, 0, NULL, NULL);
        if (u8len > 0) {
          out = (char *)malloc((size_t)u8len);
          if (out) WideCharToMultiByte(CP_UTF8, 0, ws, -1, out, u8len, NULL, NULL);
        }
        GlobalUnlock(hg);
      }
    }
    U.CloseClipboard();
    if (out) return (uint64_t)(uintptr_t)out;
  }
  return (uint64_t)(uintptr_t)_strdup(g_win32_clipboard ? g_win32_clipboard : "");
}

MOONBIT_FFI_EXPORT void tycho_win_set_fullscreen(uint64_t p, int32_t fs) {
  TychoWin32Window *tw = (TychoWin32Window *)(uintptr_t)p;
  if (!tw || !tw->hwnd || !U.GetWindowLongA || !U.SetWindowLongA || !U.SetWindowPos) return;
  int want = fs ? 1 : 0;
  if (tw->fullscreen == want) return;
  if (want) {
    tw->saved_style = (DWORD)U.GetWindowLongA(tw->hwnd, GWL_STYLE);
    if (U.GetWindowPlacement) U.GetWindowPlacement(tw->hwnd, &tw->saved_place);
    if (U.MonitorFromWindow && U.GetMonitorInfoA) {
      MONITORINFO mi;
      memset(&mi, 0, sizeof(mi));
      mi.cbSize = sizeof(mi);
      HMONITOR mon = U.MonitorFromWindow(tw->hwnd, MONITOR_DEFAULTTOPRIMARY);
      if (U.GetMonitorInfoA(mon, &mi)) {
        U.SetWindowLongA(tw->hwnd, GWL_STYLE, (LONG)(tw->saved_style & ~WS_OVERLAPPEDWINDOW));
        U.SetWindowPos(tw->hwnd, HWND_TOP, mi.rcMonitor.left, mi.rcMonitor.top,
                       mi.rcMonitor.right - mi.rcMonitor.left,
                       mi.rcMonitor.bottom - mi.rcMonitor.top,
                       SWP_NOOWNERZORDER | SWP_FRAMECHANGED);
        tw->fullscreen = 1;
      }
    }
  } else {
    U.SetWindowLongA(tw->hwnd, GWL_STYLE, (LONG)tw->saved_style);
    if (U.SetWindowPlacement) U.SetWindowPlacement(tw->hwnd, &tw->saved_place);
    U.SetWindowPos(tw->hwnd, NULL, 0, 0, 0, 0,
                   SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_NOOWNERZORDER | SWP_FRAMECHANGED);
    tw->fullscreen = 0;
  }
}

MOONBIT_FFI_EXPORT int32_t tycho_win_is_fullscreen(uint64_t p) {
  TychoWin32Window *tw = (TychoWin32Window *)(uintptr_t)p;
  return tw ? tw->fullscreen : 0;
}

MOONBIT_FFI_EXPORT double tycho_win_content_scale(uint64_t p) {
  TychoWin32Window *tw = (TychoWin32Window *)(uintptr_t)p;
  if (!tw || !tw->hwnd || !U.GetDpiForWindow) return 1.0;
  UINT dpi = U.GetDpiForWindow(tw->hwnd);
  return dpi > 0 ? (double)dpi / 96.0 : 1.0;
}

MOONBIT_FFI_EXPORT void tycho_win_set_bg_color(uint64_t p, int32_t r, int32_t g, int32_t b) {
  (void)p; (void)r; (void)g; (void)b;
}

MOONBIT_FFI_EXPORT int32_t tycho_win_has_pending_sync(uint64_t p) {
  (void)p; return 0;
}

MOONBIT_FFI_EXPORT void tycho_win_finish_sync(uint64_t p) {
  (void)p;
}

MOONBIT_FFI_EXPORT void tycho_win_wait_events(int32_t timeout_ms) {
  if (timeout_ms <= 0) return;
  if (U.MsgWaitForMultipleObjectsEx) {
    U.MsgWaitForMultipleObjectsEx(0, NULL, (DWORD)timeout_ms, QS_ALLINPUT, MWMO_INPUTAVAILABLE);
  } else {
    Sleep((DWORD)timeout_ms);
  }
}
#endif
