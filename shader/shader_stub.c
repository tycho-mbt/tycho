// Native shim for laplaceliu/tycho_shader:
// - GLSL -> SPIR-V via glslangValidator (Vulkan SDK / system PATH, zero C link deps)
// - Slang -> SPIR-V via slangc (Vulkan SDK / TYCHO_SLANGC / PATH)
// - Binary SPIR-V loader
// - Minimal PPM/BMP image loader (zero libstb-dev dependency)
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#ifdef _WIN32
#include <io.h>
#include <direct.h>
#include <windows.h>
#else
#include <unistd.h>
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

// Minimal P6 binary PPM loader -> RGBA8 (no external library dependency).
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
  FILE *f = fopen(p, "rb");
  if (!f) {
    *out_w = 0;
    *out_h = 0;
    return (uint8_t *)moonbit_make_bytes(0, 0);
  }
  char magic[4] = {0};
  int w = 0, h = 0, maxv = 0;
  if (fscanf(f, "%2s %d %d %d", magic, &w, &h, &maxv) != 4 || strcmp(magic, "P6") != 0 ||
      w <= 0 || h <= 0) {
    fclose(f);
    *out_w = 0;
    *out_h = 0;
    return (uint8_t *)moonbit_make_bytes(0, 0);
  }
  fgetc(f); // consume single whitespace byte
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
  *out_w = w;
  *out_h = h;
  return arr;
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
