// Native shim for laplaceliu/tycho_shader:
// - GLSL -> SPIR-V via glslangValidator (Vulkan SDK / system PATH, zero C link deps)
// - Slang -> SPIR-V via slangc (Vulkan SDK / TYCHO_SLANGC / PATH)
// - Binary SPIR-V loader
// - Minimal PPM/BMP image loader (zero libstb-dev dependency)
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <stdint.h>
#ifdef _WIN32
#include <io.h>
#include <direct.h>
#include <windows.h>
#else
#include <unistd.h>
#include <sys/stat.h>
#endif
#ifdef __APPLE__
#include <mach-o/dyld.h>
#endif
#include "moonbit.h"

#ifdef _WIN32
#define TYCHO_READ_OK(p) (_access((p), 0) == 0)
#define TYCHO_EXEC_OK(p) (_access((p), 0) == 0)
#else
#define TYCHO_READ_OK(p) (access((p), R_OK) == 0)
#define TYCHO_EXEC_OK(p) (access((p), X_OK) == 0)
#endif

static void tycho_dirname(char *p) {
  char *slash = NULL;
  for (char *q = p; *q; q++) {
    if (*q == '/' || *q == '\\') slash = q;
  }
  if (slash) *slash = 0;
  else p[0] = 0;
}

static int tycho_exe_path(char *out, size_t n) {
#ifdef _WIN32
  DWORD k = GetModuleFileNameA(NULL, out, (DWORD)n);
  if (k == 0 || k >= n) return 0;
#elif defined(__APPLE__)
  uint32_t sz = (uint32_t)n;
  if (_NSGetExecutablePath(out, &sz) != 0) return 0;
#else
  ssize_t k = readlink("/proc/self/exe", out, n - 1);
  if (k <= 0) return 0;
  out[k] = 0;
#endif
  return 1;
}

static void tycho_temp_path(char *out, size_t n, const char *suffix) {
  static unsigned long seq = 0;
  seq++;
  unsigned long pid = 0;
#ifndef _WIN32
  pid = (unsigned long)getpid();
#endif
  const char *tmp = getenv("TMPDIR");
#ifdef _WIN32
  if (!tmp || !*tmp) tmp = getenv("TEMP");
  if (!tmp || !*tmp) tmp = getenv("TMP");
#endif
  if (!tmp || !*tmp) tmp = "/tmp";
  /* TMPDIR is usually set without a trailing slash ("/tmp"), so appending the
     filename directly would produce "/tmptycho_..." in the filesystem root. */
  size_t len = strlen(tmp);
  const char *sep = (tmp[len - 1] == '/' || tmp[len - 1] == '\\') ? "" : "/";
  snprintf(out, n, "%s%stycho_%lu_%lu%s", tmp, sep, pid, seq, suffix);
}

static int tycho_resolve_path(const char *rel, char *out, size_t outsz) {
  if (TYCHO_READ_OK(rel)) {
    snprintf(out, outsz, "%s", rel);
    return 1;
  }
  char exe[1024];
  if (!tycho_exe_path(exe, sizeof exe)) return 0;
  char dir[1024];
  snprintf(dir, sizeof dir, "%s", exe);
  for (int i = 0; i < 12; i++) {
    tycho_dirname(dir);
    char cand[1280];
    snprintf(cand, sizeof cand, "%s/%s", dir, rel);
    if (TYCHO_READ_OK(cand)) {
      snprintf(out, outsz, "%s", cand);
      return 1;
    }
    if (dir[0] == 0) break;
  }
  return 0;
}

static uint64_t tycho_fnv1a(const void *data, size_t n, uint64_t seed) {
  const uint8_t *p = (const uint8_t *)data;
  uint64_t h = seed;
  for (size_t i = 0; i < n; i++) {
    h ^= (uint64_t)p[i];
    h *= 1099511628211ULL;
  }
  return h;
}

static int tycho_cache_enabled(void) {
  const char *e = getenv("TYCHO_NO_SHADER_CACHE");
  return !(e && e[0] == '1');
}

static void tycho_cache_path(char *out, size_t n, uint64_t hash) {
  const char *tmp = getenv("TMPDIR");
#ifdef _WIN32
  if (!tmp || !*tmp) tmp = getenv("TEMP");
  if (!tmp || !*tmp) tmp = getenv("TMP");
#endif
  if (!tmp || !*tmp) tmp = "/tmp";
  size_t len = strlen(tmp);
  const char *sep = (len > 0 && (tmp[len - 1] == '/' || tmp[len - 1] == '\\')) ? "" : "/";
  char dir[512];
  snprintf(dir, sizeof dir, "%s%stycho_spv_cache", tmp, sep);
#ifdef _WIN32
  _mkdir(dir);
#else
  mkdir(dir, 0755);
#endif
  snprintf(out, n, "%s/%016llx.spv", dir, (unsigned long long)hash);
}

static uint32_t *tycho_read_spv(const char *p) {
  FILE *f = fopen(p, "rb");
  if (!f) return (uint32_t *)moonbit_make_int32_array(0, 0);
  fseek(f, 0, SEEK_END);
  long sz = ftell(f);
  fseek(f, 0, SEEK_SET);
  int32_t words = (int32_t)(sz / 4);
  uint32_t *arr = (uint32_t *)moonbit_make_int32_array(words, 0);
  size_t rd = fread(arr, 4, words, f);
  (void)rd;
  fclose(f);
  return arr;
}

static void tycho_write_spv(const char *p, const uint32_t *arr, int32_t words) {
  FILE *f = fopen(p, "wb");
  if (!f) return;
  fwrite(arr, 4, (size_t)words, f);
  fclose(f);
}

static uint8_t *tycho_read_all(const char *p, long *out_len) {
  FILE *f = fopen(p, "rb");
  if (!f) return NULL;
  fseek(f, 0, SEEK_END);
  long sz = ftell(f);
  fseek(f, 0, SEEK_SET);
  if (sz <= 0) {
    fclose(f);
    return NULL;
  }
  uint8_t *buf = (uint8_t *)malloc((size_t)sz);
  if (!buf) {
    fclose(f);
    return NULL;
  }
  size_t rd = fread(buf, 1, (size_t)sz, f);
  fclose(f);
  *out_len = (long)rd;
  return buf;
}

static uint16_t rd_u16(const uint8_t *p) {
  return (uint16_t)p[0] | ((uint16_t)p[1] << 8);
}

static uint32_t rd_u32(const uint8_t *p) {
  return (uint32_t)p[0] | ((uint32_t)p[1] << 8) |
         ((uint32_t)p[2] << 16) | ((uint32_t)p[3] << 24);
}

static int32_t rd_i32(const uint8_t *p) {
  return (int32_t)rd_u32(p);
}

MOONBIT_FFI_EXPORT uint32_t *tycho_shader_load_spirv(
    const uint8_t *path, int32_t path_len, int32_t *out_count) {
  char rel[512];
  memcpy(rel, path, path_len);
  rel[path_len] = 0;
  char p[1280];
  if (!tycho_resolve_path(rel, p, sizeof(p))) {
    *out_count = 0;
    return (uint32_t *)moonbit_make_int32_array(0, 0);
  }
  uint32_t *arr = tycho_read_spv(p);
  *out_count = Moonbit_array_length(arr);
  return arr;
}

// Self-contained P6 PPM, 24/32-bit uncompressed BMP, and 24/32-bit uncompressed TGA loader -> RGBA8.
MOONBIT_FFI_EXPORT uint8_t *tycho_shader_load_image(
    const uint8_t *path, int32_t path_len, int32_t *out_w, int32_t *out_h) {
  char rel[512];
  memcpy(rel, path, path_len);
  rel[path_len] = 0;
  char p[1280];
  if (!tycho_resolve_path(rel, p, sizeof(p))) {
    *out_w = 0;
    *out_h = 0;
    return (uint8_t *)moonbit_make_bytes(0, 0);
  }
  long sz = 0;
  uint8_t *buf = tycho_read_all(p, &sz);
  if (!buf) {
    *out_w = 0;
    *out_h = 0;
    return (uint8_t *)moonbit_make_bytes(0, 0);
  }

  // 1. BMP ("BM", uncompressed BI_RGB = 0, 24 or 32 bpp)
  if (sz >= 54 && buf[0] == 'B' && buf[1] == 'M') {
    uint32_t data_off = rd_u32(buf + 10);
    int32_t w = rd_i32(buf + 18);
    int32_t h_raw = rd_i32(buf + 22);
    uint16_t bpp = rd_u16(buf + 28);
    uint32_t comp = rd_u32(buf + 30);
    int top_down = (h_raw < 0);
    int32_t h = top_down ? -h_raw : h_raw;
    if (w > 0 && h > 0 && comp == 0 && (bpp == 24 || bpp == 32)) {
      int32_t row_bytes = ((w * bpp + 31) / 32) * 4;
      if ((long)data_off + (long)row_bytes * h <= sz) {
        uint8_t *arr = (uint8_t *)moonbit_make_bytes(w * h * 4, 0);
        int ch = bpp / 8;
        for (int y = 0; y < h; y++) {
          int src_y = top_down ? y : (h - 1 - y);
          const uint8_t *row = buf + data_off + (long)src_y * row_bytes;
          for (int x = 0; x < w; x++) {
            int di = (y * w + x) * 4;
            arr[di + 0] = row[x * ch + 2];
            arr[di + 1] = row[x * ch + 1];
            arr[di + 2] = row[x * ch + 0];
            arr[di + 3] = (ch == 4) ? row[x * ch + 3] : 255;
          }
        }
        free(buf);
        *out_w = w;
        *out_h = h;
        return arr;
      }
    }
  }

  // 2. P6 binary PPM
  if (sz >= 9 && buf[0] == 'P' && buf[1] == '6') {
    FILE *f = fopen(p, "rb");
    if (f) {
      char magic[4] = {0};
      int w = 0, h = 0, maxv = 0;
      if (fscanf(f, "%2s %d %d %d", magic, &w, &h, &maxv) == 4 &&
          strcmp(magic, "P6") == 0 && w > 0 && h > 0) {
        fgetc(f);
        int32_t len = w * h * 4;
        uint8_t *arr = (uint8_t *)moonbit_make_bytes(len, 0);
        for (int i = 0; i < w * h; i++) {
          uint8_t rgb[3] = {0, 0, 0};
          if (fread(rgb, 1, 3, f) != 3) break;
          arr[i * 4 + 0] = rgb[0];
          arr[i * 4 + 1] = rgb[1];
          arr[i * 4 + 2] = rgb[2];
          arr[i * 4 + 3] = 255;
        }
        fclose(f);
        free(buf);
        *out_w = w;
        *out_h = h;
        return arr;
      }
      fclose(f);
    }
  }

  // 3. Uncompressed 24/32-bit TGA (image type 2)
  if (sz >= 18 && buf[2] == 2 && buf[1] == 0) {
    uint8_t id_len = buf[0];
    int w = (int)rd_u16(buf + 12);
    int h = (int)rd_u16(buf + 14);
    uint8_t bpp = buf[16];
    int top_down = (buf[17] & 0x20) != 0;
    int ch = bpp / 8;
    long pix_off = 18 + (long)id_len;
    if (w > 0 && h > 0 && (bpp == 24 || bpp == 32) && pix_off + (long)w * h * ch <= sz) {
      uint8_t *arr = (uint8_t *)moonbit_make_bytes(w * h * 4, 0);
      for (int y = 0; y < h; y++) {
        int src_y = top_down ? y : (h - 1 - y);
        const uint8_t *row = buf + pix_off + (long)src_y * w * ch;
        for (int x = 0; x < w; x++) {
          int di = (y * w + x) * 4;
          arr[di + 0] = row[x * ch + 2];
          arr[di + 1] = row[x * ch + 1];
          arr[di + 2] = row[x * ch + 0];
          arr[di + 3] = (ch == 4) ? row[x * ch + 3] : 255;
        }
      }
      free(buf);
      *out_w = w;
      *out_h = h;
      return arr;
    }
  }

  free(buf);
  *out_w = 0;
  *out_h = 0;
  return (uint8_t *)moonbit_make_bytes(0, 0);
}

static const char *tycho_glslang(void) {
  const char *e = getenv("TYCHO_GLSLANG");
  if (e && *e) return e;
  return "glslangValidator";
}

static const char *tycho_stage_flag(uint32_t k) {
  switch (k) {
    case 0: return "vert";
    case 1: return "frag";
    case 2: return "comp";
    case 3: return "task";
    case 4: return "mesh";
    case 5: return "rgen";
    case 6: return "rahit";
    case 7: return "rchit";
    case 8: return "rmiss";
    case 9: return "rint";
    default: return "rcall";
  }
}

static const char *tycho_env_flag(uint32_t e) {
  switch (e) {
    case 1: return "vulkan1.1";
    case 2: return "vulkan1.2";
    case 3: return "vulkan1.3";
    default: return "vulkan1.0";
  }
}

static uint32_t *tycho_glsl_run(const char *in, uint32_t kind, uint32_t env) {
  char cache_file[640] = {0};
  int use_cache = tycho_cache_enabled();
  if (use_cache) {
    long src_sz = 0;
    uint8_t *src = tycho_read_all(in, &src_sz);
    if (src) {
      uint64_t h = 14695981039346656037ULL;
      h = tycho_fnv1a("glsl", 4, h);
      h = tycho_fnv1a(&kind, sizeof(kind), h);
      h = tycho_fnv1a(&env, sizeof(env), h);
      h = tycho_fnv1a(src, (size_t)src_sz, h);
      free(src);
      tycho_cache_path(cache_file, sizeof cache_file, h);
      if (TYCHO_READ_OK(cache_file)) {
        uint32_t *cached = tycho_read_spv(cache_file);
        if (Moonbit_array_length(cached) > 0) {
          return cached;
        }
      }
    }
  }
  char out[512];
  char err[512];
  tycho_temp_path(out, sizeof out, ".spv");
  tycho_temp_path(err, sizeof err, ".log");
  char cmd[2048];
  snprintf(cmd, sizeof cmd,
           "\"%s\" -V --target-env %s -S %s \"%s\" -o \"%s\" >\"%s\" 2>&1",
           tycho_glslang(), tycho_env_flag(env), tycho_stage_flag(kind), in, out, err);
  int rc = system(cmd);
  uint32_t *arr;
  if (rc != 0) {
    fprintf(stderr, "[tycho_shader] glslang compile failed (rc=%d):\n", rc);
    FILE *ef = fopen(err, "rb");
    if (ef) {
      char b[2048];
      size_t n = fread(b, 1, sizeof b - 1, ef);
      b[n] = 0;
      fprintf(stderr, "%s", b);
      fclose(ef);
    }
    arr = (uint32_t *)moonbit_make_int32_array(0, 0);
  } else {
    arr = tycho_read_spv(out);
    if (use_cache && cache_file[0] && Moonbit_array_length(arr) > 0) {
      tycho_write_spv(cache_file, arr, Moonbit_array_length(arr));
    }
  }
  remove(out);
  remove(err);
  return arr;
}

MOONBIT_FFI_EXPORT uint32_t *tycho_shader_compile_env(
    const uint8_t *source, int32_t len, uint32_t kind, uint32_t env) {
  char in[512];
  tycho_temp_path(in, sizeof in, ".glsl");
  FILE *f = fopen(in, "wb");
  if (!f) return (uint32_t *)moonbit_make_int32_array(0, 0);
  fwrite(source, 1, (size_t)len, f);
  fclose(f);
  uint32_t *r = tycho_glsl_run(in, kind, env);
  remove(in);
  return r;
}

MOONBIT_FFI_EXPORT uint32_t *tycho_shader_compile(
    const uint8_t *source, int32_t len, uint32_t kind) {
  return tycho_shader_compile_env(source, len, kind, 0);
}

MOONBIT_FFI_EXPORT uint32_t *tycho_shader_compile_file_env(
    const uint8_t *path, int32_t path_len, uint32_t kind, uint32_t env) {
  char rel[512];
  memcpy(rel, path, path_len);
  rel[path_len] = 0;
  char p[1280];
  if (!tycho_resolve_path(rel, p, sizeof(p))) {
    fprintf(stderr, "[tycho_shader] shader file not found: %s\n", rel);
    return (uint32_t *)moonbit_make_int32_array(0, 0);
  }
  return tycho_glsl_run(p, kind, env);
}

MOONBIT_FFI_EXPORT uint32_t *tycho_shader_compile_file(
    const uint8_t *path, int32_t path_len, uint32_t kind) {
  return tycho_shader_compile_file_env(path, path_len, kind, 0);
}

static const char *tycho_slangc(void) {
  const char *e = getenv("TYCHO_SLANGC");
  if (e && *e) return e;
  /* Search like every other input path (CWD, then upward from the executable)
     instead of only the CWD, so examples run from any directory. */
  static char local[1024];
  if (tycho_resolve_path("third_party/slang/bin/slangc", local, sizeof local) &&
      TYCHO_EXEC_OK(local))
    return local;
  return "slangc";
}

static uint32_t *tycho_slang_run(const char *in, const char *entry) {
  char cache_file[640] = {0};
  int use_cache = tycho_cache_enabled();
  if (use_cache) {
    long src_sz = 0;
    uint8_t *src = tycho_read_all(in, &src_sz);
    if (src) {
      uint64_t h = 14695981039346656037ULL;
      h = tycho_fnv1a("slang", 5, h);
      h = tycho_fnv1a(entry, strlen(entry), h);
      h = tycho_fnv1a(src, (size_t)src_sz, h);
      free(src);
      tycho_cache_path(cache_file, sizeof cache_file, h);
      if (TYCHO_READ_OK(cache_file)) {
        uint32_t *cached = tycho_read_spv(cache_file);
        if (Moonbit_array_length(cached) > 0) {
          return cached;
        }
      }
    }
  }
  char out[512];
  char err[512];
  tycho_temp_path(out, sizeof out, ".spv");
  tycho_temp_path(err, sizeof err, ".log");
  char cmd[2048];
  snprintf(cmd, sizeof cmd,
           "\"%s\" \"%s\" -target spirv -entry \"%s\" -o \"%s\" 2>\"%s\"",
           tycho_slangc(), in, entry, out, err);
  int rc = system(cmd);
  uint32_t *arr;
  if (rc != 0) {
    fprintf(stderr, "[tycho_shader] slang compile failed (rc=%d):\n", rc);
    FILE *ef = fopen(err, "rb");
    if (ef) {
      char b[2048];
      size_t n = fread(b, 1, sizeof b - 1, ef);
      b[n] = 0;
      fprintf(stderr, "%s", b);
      fclose(ef);
    }
    arr = (uint32_t *)moonbit_make_int32_array(0, 0);
  } else {
    arr = tycho_read_spv(out);
    if (use_cache && cache_file[0] && Moonbit_array_length(arr) > 0) {
      tycho_write_spv(cache_file, arr, Moonbit_array_length(arr));
    }
  }
  remove(out);
  remove(err);
  return arr;
}

MOONBIT_FFI_EXPORT uint32_t *tycho_shader_compile_slang(
    const uint8_t *source, int32_t slen, const uint8_t *entry, int32_t elen) {
  char in[512];
  tycho_temp_path(in, sizeof in, ".slang");
  FILE *f = fopen(in, "wb");
  if (!f) return (uint32_t *)moonbit_make_int32_array(0, 0);
  fwrite(source, 1, (size_t)slen, f);
  fclose(f);
  char en[256];
  memcpy(en, entry, elen);
  en[elen] = 0;
  uint32_t *r = tycho_slang_run(in, en);
  remove(in);
  return r;
}

MOONBIT_FFI_EXPORT uint32_t *tycho_shader_compile_slang_file(
    const uint8_t *path, int32_t plen, const uint8_t *entry, int32_t elen) {
  char rel[512];
  memcpy(rel, path, plen);
  rel[plen] = 0;
  char p[1280];
  if (!tycho_resolve_path(rel, p, sizeof p)) {
    fprintf(stderr, "[tycho_shader] slang file not found: %s\n", rel);
    return (uint32_t *)moonbit_make_int32_array(0, 0);
  }
  char en[256];
  memcpy(en, entry, elen);
  en[elen] = 0;
  return tycho_slang_run(p, en);
}

MOONBIT_FFI_EXPORT uint8_t *tycho_shader_read_file(
    const uint8_t *path, int32_t plen) {
  char rel[512];
  if (plen <= 0 || plen >= (int32_t)sizeof(rel)) {
    return (uint8_t *)moonbit_make_bytes(0, 0);
  }
  memcpy(rel, path, plen);
  rel[plen] = 0;
  char p[1280];
  if (!tycho_resolve_path(rel, p, sizeof p)) {
    return (uint8_t *)moonbit_make_bytes(0, 0);
  }
  long sz = 0;
  uint8_t *buf = tycho_read_all(p, &sz);
  if (!buf || sz <= 0) {
    if (buf) free(buf);
    return (uint8_t *)moonbit_make_bytes(0, 0);
  }
  uint8_t *out = (uint8_t *)moonbit_make_bytes((int32_t)sz, 0);
  memcpy(out, buf, (size_t)sz);
  free(buf);
  return out;
}

static int tycho_cmdline_match(const char *flag, char *out_val, size_t out_sz) {
  FILE *f = fopen("/proc/self/cmdline", "rb");
  if (!f) return 0;
  char buf[4096];
  size_t n = fread(buf, 1, sizeof(buf) - 1, f);
  fclose(f);
  buf[n] = '\0';
  size_t flen = strlen(flag);
  size_t i = 0;
  while (i < n) {
    const char *arg = buf + i;
    size_t alen = strlen(arg);
    if (strcmp(arg, flag) == 0) {
      if (out_val && out_sz > 0) {
        size_t next = i + alen + 1;
        if (next < n) {
          snprintf(out_val, out_sz, "%s", buf + next);
        } else {
          out_val[0] = '\0';
        }
      }
      return 1;
    }
    if (out_val && out_sz > 0 && strncmp(arg, flag, flen) == 0 && arg[flen] == '=') {
      snprintf(out_val, out_sz, "%s", arg + flen + 1);
      return 1;
    }
    i += alen + 1;
  }
  return 0;
}

MOONBIT_FFI_EXPORT int32_t tycho_shader_want_window(void) {
  const char *e = getenv("TYCHO_WINDOW");
  if (e && (strcmp(e, "1") == 0 || strcmp(e, "true") == 0 || strcmp(e, "yes") == 0)) {
    return 1;
  }
  if (tycho_cmdline_match("--window", NULL, 0) ||
      tycho_cmdline_match("-w", NULL, 0) ||
      tycho_cmdline_match("--screen", NULL, 0) ||
      tycho_cmdline_match("--show", NULL, 0)) {
    return 1;
  }
  return 0;
}

MOONBIT_FFI_EXPORT uint8_t *tycho_shader_screenshot_path(void) {
  char path[1024] = {0};
  const char *e = getenv("TYCHO_SCREENSHOT");
  if (e && *e) {
    snprintf(path, sizeof(path), "%s", e);
  } else {
    tycho_cmdline_match("--screenshot", path, sizeof(path));
  }
  size_t len = strlen(path);
  uint8_t *out = (uint8_t *)moonbit_make_bytes((int32_t)len, 0);
  if (len > 0) memcpy(out, path, len);
  return out;
}

static uint32_t tycho_crc32(const uint8_t *data, size_t len) {
  uint32_t crc = 0xFFFFFFFFu;
  for (size_t i = 0; i < len; i++) {
    crc ^= data[i];
    for (int k = 0; k < 8; k++) {
      crc = (crc >> 1) ^ (0xEDB88320u & (uint32_t)(-(int32_t)(crc & 1u)));
    }
  }
  return crc ^ 0xFFFFFFFFu;
}

static void png_write_be32(FILE *f, uint32_t v) {
  uint8_t b[4] = {(uint8_t)(v >> 24), (uint8_t)(v >> 16), (uint8_t)(v >> 8), (uint8_t)v};
  fwrite(b, 1, 4, f);
}

static void png_write_chunk(FILE *f, const char type[4], const uint8_t *data, uint32_t len) {
  png_write_be32(f, len);
  uint32_t crc = 0xFFFFFFFFu;
  for (int i = 0; i < 4; i++) {
    crc ^= (uint8_t)type[i];
    for (int k = 0; k < 8; k++) crc = (crc >> 1) ^ (0xEDB88320u & (uint32_t)(-(int32_t)(crc & 1u)));
  }
  for (uint32_t i = 0; i < len; i++) {
    crc ^= data[i];
    for (int k = 0; k < 8; k++) crc = (crc >> 1) ^ (0xEDB88320u & (uint32_t)(-(int32_t)(crc & 1u)));
  }
  crc ^= 0xFFFFFFFFu;
  fwrite(type, 1, 4, f);
  if (len > 0) fwrite(data, 1, len, f);
  png_write_be32(f, crc);
}

MOONBIT_FFI_EXPORT int32_t tycho_shader_save_png(
    const uint8_t *path, int32_t plen, int32_t w, int32_t h, const uint8_t *rgba, int32_t bgra) {
  if (plen <= 0 || plen >= 1024 || w <= 0 || h <= 0) return 0;
  char p[1024];
  memcpy(p, path, plen);
  p[plen] = '\0';
  FILE *f = fopen(p, "wb");
  if (!f) return 0;
  static const uint8_t sig[8] = {137, 80, 78, 71, 13, 10, 26, 10};
  fwrite(sig, 1, 8, f);
  uint8_t ihdr[13] = {
    (uint8_t)(w >> 24), (uint8_t)(w >> 16), (uint8_t)(w >> 8), (uint8_t)w,
    (uint8_t)(h >> 24), (uint8_t)(h >> 16), (uint8_t)(h >> 8), (uint8_t)h,
    8, 6, 0, 0, 0
  };
  png_write_chunk(f, "IHDR", ihdr, 13);

  size_t row_bytes = 1 + (size_t)w * 4;
  size_t raw_sz = row_bytes * (size_t)h;
  size_t max_blocks = (raw_sz + 65534) / 65535;
  size_t zlib_sz = 2 + raw_sz + max_blocks * 5 + 4;
  uint8_t *zlib = (uint8_t *)malloc(zlib_sz);
  if (!zlib) {
    fclose(f);
    return 0;
  }
  size_t zp = 0;
  zlib[zp++] = 0x78;
  zlib[zp++] = 0x01;
  uint32_t s1 = 1, s2 = 0;
  uint8_t *raw = (uint8_t *)malloc(raw_sz);
  if (!raw) {
    free(zlib);
    fclose(f);
    return 0;
  }
  for (int32_t y = 0; y < h; y++) {
    uint8_t *dst = raw + (size_t)y * row_bytes;
    dst[0] = 0;
    const uint8_t *src = rgba + (size_t)y * (size_t)w * 4;
    if (bgra) {
      for (int32_t x = 0; x < w; x++) {
        dst[1 + x * 4 + 0] = src[x * 4 + 2];
        dst[1 + x * 4 + 1] = src[x * 4 + 1];
        dst[1 + x * 4 + 2] = src[x * 4 + 0];
        dst[1 + x * 4 + 3] = 255;
      }
    } else {
      for (int32_t x = 0; x < w; x++) {
        dst[1 + x * 4 + 0] = src[x * 4 + 0];
        dst[1 + x * 4 + 1] = src[x * 4 + 1];
        dst[1 + x * 4 + 2] = src[x * 4 + 2];
        dst[1 + x * 4 + 3] = 255;
      }
    }
  }
  for (size_t i = 0; i < raw_sz; i++) {
    s1 = (s1 + raw[i]) % 65521u;
    s2 = (s2 + s1) % 65521u;
  }
  size_t off = 0;
  while (off < raw_sz) {
    size_t chunk = raw_sz - off;
    if (chunk > 65535) chunk = 65535;
    uint8_t bfinal = (off + chunk >= raw_sz) ? 1 : 0;
    zlib[zp++] = bfinal;
    zlib[zp++] = (uint8_t)(chunk & 0xFF);
    zlib[zp++] = (uint8_t)((chunk >> 8) & 0xFF);
    uint16_t nlen = (uint16_t)(~chunk);
    zlib[zp++] = (uint8_t)(nlen & 0xFF);
    zlib[zp++] = (uint8_t)((nlen >> 8) & 0xFF);
    memcpy(zlib + zp, raw + off, chunk);
    zp += chunk;
    off += chunk;
  }
  uint32_t adler = (s2 << 16) | s1;
  zlib[zp++] = (uint8_t)(adler >> 24);
  zlib[zp++] = (uint8_t)(adler >> 16);
  zlib[zp++] = (uint8_t)(adler >> 8);
  zlib[zp++] = (uint8_t)adler;
  free(raw);

  (void)tycho_crc32;
  png_write_chunk(f, "IDAT", zlib, (uint32_t)zp);
  free(zlib);
  png_write_chunk(f, "IEND", NULL, 0);
  fclose(f);
  return 1;
}

static void rgbe_to_float(const uint8_t rgbe[4], float out[4]) {
  if (rgbe[3] <= 9) {
    out[0] = out[1] = out[2] = 0.0f;
    out[3] = 1.0f;
    return;
  }
  uint32_t bits = (uint32_t)(rgbe[3] - 9) << 23;
  float f = 0.0f;
  memcpy(&f, &bits, sizeof(float));
  out[0] = (float)rgbe[0] * f;
  out[1] = (float)rgbe[1] * f;
  out[2] = (float)rgbe[2] * f;
  out[3] = 1.0f;
}

MOONBIT_FFI_EXPORT float *tycho_shader_load_hdr(
    const uint8_t *path, int32_t plen, int32_t *out_w, int32_t *out_h) {
  *out_w = 0;
  *out_h = 0;
  if (plen <= 0 || plen >= 512) return moonbit_make_float_array(0, 0.0f);
  char rel[512];
  memcpy(rel, path, plen);
  rel[plen] = '\0';
  char p[1280];
  if (!tycho_resolve_path(rel, p, sizeof p)) return moonbit_make_float_array(0, 0.0f);
  long sz = 0;
  uint8_t *buf = tycho_read_all(p, &sz);
  if (!buf || sz < 16) {
    if (buf) free(buf);
    return moonbit_make_float_array(0, 0.0f);
  }
  long pos = 0;
  // Skip header lines until empty line ("\n\n" or "\r\n\r\n")
  while (pos < sz) {
    long ls = pos;
    while (pos < sz && buf[pos] != '\n') pos++;
    long le = pos;
    if (pos < sz && buf[pos] == '\n') pos++;
    if (le == ls || (le == ls + 1 && buf[ls] == '\r')) break;
  }
  // Parse resolution line: "-Y <h> +X <w>"
  long rls = pos;
  while (pos < sz && buf[pos] != '\n') pos++;
  long rle = pos;
  if (pos < sz && buf[pos] == '\n') pos++;
  char res_line[128];
  long rlen = rle - rls;
  if (rlen <= 0 || rlen >= (long)sizeof(res_line)) {
    free(buf);
    return moonbit_make_float_array(0, 0.0f);
  }
  memcpy(res_line, buf + rls, (size_t)rlen);
  res_line[rlen] = '\0';
  int w = 0, h = 0;
  if (sscanf(res_line, "-Y %d +X %d", &h, &w) != 2 || w <= 0 || h <= 0) {
    free(buf);
    return moonbit_make_float_array(0, 0.0f);
  }
  float *out = moonbit_make_float_array(w * h * 4, 0.0f);
  uint8_t *scan = (uint8_t *)malloc((size_t)w * 4);
  if (!scan) {
    free(buf);
    return moonbit_make_float_array(0, 0.0f);
  }
  for (int y = 0; y < h; y++) {
    if (pos + 4 <= sz && buf[pos] == 2 && buf[pos + 1] == 2 &&
        (((int)buf[pos + 2] << 8) | buf[pos + 3]) == w && w >= 8 && w <= 0x7FFF) {
      pos += 4;
      for (int ch = 0; ch < 4; ch++) {
        int x = 0;
        while (x < w && pos < sz) {
          uint8_t code = buf[pos++];
          if (code > 128) {
            int run = code - 128;
            if (pos >= sz) break;
            uint8_t val = buf[pos++];
            while (run-- > 0 && x < w) scan[x++ * 4 + ch] = val;
          } else {
            int cnt = code;
            while (cnt-- > 0 && x < w && pos < sz) scan[x++ * 4 + ch] = buf[pos++];
          }
        }
      }
    } else {
      long need = (long)w * 4;
      if (pos + need > sz) break;
      memcpy(scan, buf + pos, (size_t)need);
      pos += need;
    }
    for (int x = 0; x < w; x++) {
      rgbe_to_float(scan + x * 4, out + ((size_t)y * (size_t)w + (size_t)x) * 4);
    }
  }
  free(scan);
  free(buf);
  *out_w = w;
  *out_h = h;
  return out;
}
