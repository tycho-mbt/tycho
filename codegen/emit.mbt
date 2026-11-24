///|
fn has(arr : Array[String], x : String) -> Bool {
  for a in arr {
    if a == x {
      return true
    }
  }
  false
}

///|
// Map a C type to a MoonBit type for FuncRef signatures. Struct/union pointers
// become opaque #external types (real byte layouts arrive in M1-d); unmapped
// types fall back to UInt64 (pointer-width) so generation always compiles.
fn mb_type(ctype : String, t : VkTypes) -> String {
  // A C array parameter decays to a pointer (e.g. `const float blendConstants[4]`
  // in vkCmdSetBlendConstants), so it must marshal as FixedArray, not a scalar.
  let is_ptr = ctype.contains_char('*') || ctype.contains_char('[')
  let base = base_type(ctype)
  // `void**` / `const T* const*` are pointer-to-pointer: the callee writes or
  // reads an array of pointers. Passing UInt64 by value would hand it a garbage
  // address (this silently broke vkMapMemory / vkMapMemory2).
  let mut stars = 0
  for ch in ctype {
    if ch == '*' {
      stars = stars + 1
    }
  }
  if stars >= 2 {
    return "FixedArray[UInt64]"
  }
  if base == "void" {
    return if is_ptr { "UInt64" } else { "Unit" }
  }
  if base == "char" {
    return if is_ptr { "UInt64" } else { "Byte" }
  }
  if base == "VkResult" {
    return "Int32"
  }
  let scalar = match base {
    "uint32_t" | "VkBool32" | "VkFlags" | "VkSampleMask" | "DWORD" | "xcb_window_t" |
    "xcb_visualid_t" => "UInt32"
    "int32_t" | "int" => "Int32"
    "uint64_t" | "size_t" | "VkDeviceSize" | "VkDeviceAddress" => "UInt64"
    "int64_t" => "Int64"
    "float" => "Float"
    "double" => "Double"
    "uint8_t" => "Byte"
    "int8_t" => "Int"
    "uint16_t" => "UInt"
    "int16_t" => "Int"
    _ => ""
  }
  if scalar != "" {
    return if is_ptr { "FixedArray[\{scalar}]" } else { scalar }
  }
  if has(t.handles, base) {
    return if is_ptr { "FixedArray[\{base}]" } else { base }
  }
  if has(t.flags64, base) {
    return if is_ptr { "FixedArray[UInt64]" } else { "UInt64" }
  }
  if has(t.enums, base) || has(t.bitmasks, base) {
    return if is_ptr { "FixedArray[UInt32]" } else { "UInt32" }
  }
  if has(t.structs, base) || has(t.unions, base) {
    return base
  }
  "UInt64"
}

///|
pub fn funcref_type(cmd : VkCommand, t : VkTypes) -> String {
  let params = StringBuilder()
  let mut first = true
  for p in cmd.params {
    if !first {
      params.write_string(", ")
    }
    first = false
    params.write_string(mb_type(p.ctype, t))
  }
  "FuncRef[(\{params.to_string()}) -> \{mb_type(cmd.ret, t)}]"
}

///|
fn emit_opaque(sb : StringBuilder, name : String) -> Unit {
  sb.write_string("#external\npub type \{name}\n")
  sb.write_string("extern \"c\" fn \{name}::null_ffi() -> \{name} = \"tycho_null_ptr\"\n")
  sb.write_string("pub fn \{name}::null() -> \{name} { \{name}::null_ffi() }\n\n")
}

///|
pub fn emit_types(t : VkTypes) -> String {
  let sb = StringBuilder()
  sb.write_string("// Generated handles + opaque struct/union types + null constants.\n\n")
  for h in t.handles {
    emit_opaque(sb, h)
    // Handles need pointer identity too: vkSetPrivateData and the debug-utils
    // object naming/tagging APIs take objectHandle as a raw UInt64.
    sb.write_string("extern \"c\" fn \{h}::as_ptr_ffi(self : \{h}) -> UInt64 = \"tycho_as_ptr\"\n")
    sb.write_string("pub fn \{h}::as_ptr(self : \{h}) -> UInt64 { self.as_ptr_ffi() }\n")
    sb.write_string("extern \"c\" fn \{h}::from_ptr_ffi(p : UInt64) -> \{h} = \"tycho_from_ptr\"\n")
    sb.write_string("pub fn \{h}::from_ptr(p : UInt64) -> \{h} { \{h}::from_ptr_ffi(p) }\n\n")
  }
  for s in t.structs {
    emit_opaque(sb, s)
  }
  for u in t.unions {
    emit_opaque(sb, u)
  }
  sb.to_string()
}

///|
fn emit_level(
  sb : StringBuilder,
  name : String,
  cmds : Array[VkCommand],
  t : VkTypes,
  handle : String,
  arg : String,
) -> Unit {
  sb.write_string("pub struct \{name} {\n")
  for cmd in cmds {
    sb.write_string("  \{cmd.name} : \{funcref_type(cmd, t)}\n")
  }
  sb.write_string("}\n\n")
  for cmd in cmds {
    sb.write_string(
      "extern \"c\" fn load_\{cmd.name}(\{arg} : \{handle}) -> \{funcref_type(cmd, t)} = \"tycho_gpa_\{cmd.name}\"\n",
    )
  }
  sb.write_string("\npub fn \{name}::load(\{arg} : \{handle}) -> \{name} {\n  {\n")
  for cmd in cmds {
    sb.write_string("    \{cmd.name}: load_\{cmd.name}(\{arg}),\n")
  }
  sb.write_string("  }\n}\n\n")
}

///|
fn group(commands : Array[VkCommand]) -> (Array[VkCommand], Array[VkCommand], Array[VkCommand]) {
  let core : @hashmap.HashMap[String, VkCommand] = @hashmap.HashMap::new()
  for cmd in commands {
    if cmd.alias_of is None {
      core.set(cmd.name, cmd)
    }
  }
  let entry : Array[VkCommand] = []
  let inst : Array[VkCommand] = []
  let dev : Array[VkCommand] = []
  for cmd in commands {
    // Promoted extension aliases (e.g. vkGetPhysicalDeviceFeatures2KHR) reuse the
    // core command's signature but are loaded under their own (extension) name.
    let resolved : VkCommand = match cmd.alias_of {
      Some(y) =>
        match core.get(y) {
          Some(c) => { name: cmd.name, ret: c.ret, params: c.params, alias_of: None }
          None => continue
        }
      None => cmd
    }
    match classify(resolved) {
      Entry => entry.push(resolved)
      Instance => inst.push(resolved)
      Device => dev.push(resolved)
    }
  }
  (entry, inst, dev)
}

///|
pub fn emit_dispatch(commands : Array[VkCommand], t : VkTypes) -> String {
  let (entry, inst, dev) = group(commands)
  let sb = StringBuilder()
  sb.write_string("// Generated three-layer dispatch (ash-style). Entry = global linked symbols;\n")
  sb.write_string("// Instance/Device = FuncRef tables loaded via per-command C wrappers.\n\n")
  for cmd in entry {
    let params = StringBuilder()
    let mut first = true
    for p in cmd.params {
      if !first {
        params.write_string(", ")
      }
      first = false
      params.write_string("\{p.name} : \{mb_type(p.ctype, t)}")
    }
    sb.write_string(
      "pub extern \"c\" fn \{cmd.name}(\{params.to_string()}) -> \{mb_type(cmd.ret, t)} = \"tycho_entry_\{cmd.name}\"\n",
    )
  }
  sb.write_string("\n")
  emit_level(sb, "InstanceFn", inst, t, "VkInstance", "inst")
  emit_level(sb, "DeviceFn", dev, t, "VkDevice", "dev")
  sb.to_string()
}

///|
// C wrappers that load each instance/device command by name (hardcoded), so the
// MoonBit side never needs to marshal null-terminated C strings.
pub fn emit_dispatch_stub(
  commands : Array[VkCommand],
  t : VkTypes,
  defined : @hashmap.HashMap[String, Unit],
) -> String {
  let (_, inst, dev) = group(commands)
  let sb = StringBuilder()
  sb.write_string("// Generated loaders — DO NOT EDIT.\n")
  sb.write_string("#define VK_NO_PROTOTYPES\n")
  sb.write_string("#define VK_ENABLE_BETA_EXTENSIONS\n")
  sb.write_string("#if defined(_WIN32)\n#define WIN32_LEAN_AND_MEAN\n#define NOMINMAX\n#include <windows.h>\n#else\n#include <dlfcn.h>\n#endif\n")
  sb.write_string("#include <stdlib.h>\n")
  sb.write_string("#include \"include/vulkan/vulkan.h\"\n#include \"moonbit.h\"\n\n")
  sb.write_string("#if defined(__STDC_VERSION__) && __STDC_VERSION__ >= 201112L\n#define TYCHO_STATIC_ASSERT(cond, msg) _Static_assert(cond, msg)\n#else\n#define TYCHO_SA_JOIN2(a, b) a##b\n#define TYCHO_SA_JOIN(a, b) TYCHO_SA_JOIN2(a, b)\n#define TYCHO_STATIC_ASSERT(cond, msg) typedef char TYCHO_SA_JOIN(tycho_sa_, __LINE__)[(cond) ? 1 : -1]\n#endif\n\n")
  sb.write_string(
    "static PFN_vkGetInstanceProcAddr g_tycho_gipa = NULL;\n" +
    "static PFN_vkGetDeviceProcAddr g_tycho_gdpa = NULL;\n" +
    "static VkInstance g_tycho_last_inst = VK_NULL_HANDLE;\n" +
    "static int g_tycho_vk_tried = 0;\n\n" +
    "static void tycho_vk_ensure_loaded(void) {\n" +
    "  if (g_tycho_vk_tried) return;\n" +
    "  g_tycho_vk_tried = 1;\n" +
    "  const char *env = getenv(\"TYCHO_VULKAN_LIB\");\n" +
    "#if defined(_WIN32)\n" +
    "  HMODULE lib = (env && env[0]) ? LoadLibraryA(env) : NULL;\n" +
    "  if (!lib) lib = LoadLibraryA(\"vulkan-1.dll\");\n" +
    "  if (lib) {\n" +
    "    g_tycho_gipa = (PFN_vkGetInstanceProcAddr)GetProcAddress(lib, \"vkGetInstanceProcAddr\");\n" +
    "  }\n" +
    "#else\n" +
    "  const char *cands[] = {\n" +
    "#if defined(__APPLE__)\n" +
    "    \"libvulkan.1.dylib\",\n" +
    "    \"libvulkan.dylib\",\n" +
    "    \"/opt/homebrew/lib/libvulkan.1.dylib\",\n" +
    "    \"/usr/local/lib/libvulkan.1.dylib\",\n" +
    "    \"libMoltenVK.dylib\",\n" +
    "    \"/opt/homebrew/lib/libMoltenVK.dylib\",\n" +
    "    \"/usr/local/lib/libMoltenVK.dylib\",\n" +
    "#else\n" +
    "    \"libvulkan.so.1\",\n" +
    "    \"libvulkan.so\",\n" +
    "#endif\n" +
    "    NULL\n" +
    "  };\n" +
    "  if (env && env[0]) {\n" +
    "    void *lib = dlopen(env, RTLD_NOW | RTLD_LOCAL);\n" +
    "    if (lib) g_tycho_gipa = (PFN_vkGetInstanceProcAddr)dlsym(lib, \"vkGetInstanceProcAddr\");\n" +
    "  }\n" +
    "  for (int i = 0; !g_tycho_gipa && cands[i]; i++) {\n" +
    "    void *lib = dlopen(cands[i], RTLD_NOW | RTLD_LOCAL);\n" +
    "    if (lib) g_tycho_gipa = (PFN_vkGetInstanceProcAddr)dlsym(lib, \"vkGetInstanceProcAddr\");\n" +
    "  }\n" +
    "#endif\n" +
    "}\n\n" +
    "VkInstance tycho_vk_last_instance(void) { return g_tycho_last_inst; }\n\n" +
    "void *tycho_vk_gpa(VkInstance inst, const char *name) {\n" +
    "  tycho_vk_ensure_loaded();\n" +
    "  if (!g_tycho_gipa) return NULL;\n" +
    "  if (inst != VK_NULL_HANDLE) g_tycho_last_inst = inst;\n" +
    "  return (void *)g_tycho_gipa(inst, name);\n" +
    "}\n\n" +
    "void *tycho_vk_gdpa(VkDevice dev, const char *name) {\n" +
    "  tycho_vk_ensure_loaded();\n" +
    "  if (!g_tycho_gipa) return NULL;\n" +
    "  if (!g_tycho_gdpa && g_tycho_last_inst != VK_NULL_HANDLE) {\n" +
    "    g_tycho_gdpa = (PFN_vkGetDeviceProcAddr)g_tycho_gipa(g_tycho_last_inst, \"vkGetDeviceProcAddr\");\n" +
    "  }\n" +
    "  if (!g_tycho_gdpa) {\n" +
    "    g_tycho_gdpa = (PFN_vkGetDeviceProcAddr)g_tycho_gipa(VK_NULL_HANDLE, \"vkGetDeviceProcAddr\");\n" +
    "  }\n" +
    "  if (g_tycho_gdpa && dev != VK_NULL_HANDLE) return (void *)g_tycho_gdpa(dev, name);\n" +
    "  return (void *)g_tycho_gipa(g_tycho_last_inst, name);\n" +
    "}\n\n" +
    "MOONBIT_FFI_EXPORT void *tycho_entry_vkGetInstanceProcAddr(VkInstance inst, const char *pName) {\n" +
    "  return tycho_vk_gpa(inst, pName);\n" +
    "}\n" +
    "MOONBIT_FFI_EXPORT int32_t tycho_entry_vkCreateInstance(const VkInstanceCreateInfo *pCreateInfo, const VkAllocationCallbacks *pAllocator, VkInstance *pInstance) {\n" +
    "  PFN_vkCreateInstance fn = (PFN_vkCreateInstance)tycho_vk_gpa(VK_NULL_HANDLE, \"vkCreateInstance\");\n" +
    "  if (!fn) return (int32_t)VK_ERROR_INITIALIZATION_FAILED;\n" +
    "  VkResult r = fn(pCreateInfo, pAllocator, pInstance);\n" +
    "  if (r == VK_SUCCESS && pInstance && *pInstance != VK_NULL_HANDLE) g_tycho_last_inst = *pInstance;\n" +
    "  return (int32_t)r;\n" +
    "}\n" +
    "MOONBIT_FFI_EXPORT int32_t tycho_entry_vkEnumerateInstanceVersion(uint32_t *pApiVersion) {\n" +
    "  PFN_vkEnumerateInstanceVersion fn = (PFN_vkEnumerateInstanceVersion)tycho_vk_gpa(VK_NULL_HANDLE, \"vkEnumerateInstanceVersion\");\n" +
    "  if (!fn) { if (pApiVersion) *pApiVersion = VK_API_VERSION_1_0; return 0; }\n" +
    "  return (int32_t)fn(pApiVersion);\n" +
    "}\n" +
    "MOONBIT_FFI_EXPORT int32_t tycho_entry_vkEnumerateInstanceLayerProperties(uint32_t *pPropertyCount, VkLayerProperties *pProperties) {\n" +
    "  PFN_vkEnumerateInstanceLayerProperties fn = (PFN_vkEnumerateInstanceLayerProperties)tycho_vk_gpa(VK_NULL_HANDLE, \"vkEnumerateInstanceLayerProperties\");\n" +
    "  return fn ? (int32_t)fn(pPropertyCount, pProperties) : (int32_t)VK_ERROR_INITIALIZATION_FAILED;\n" +
    "}\n" +
    "MOONBIT_FFI_EXPORT int32_t tycho_entry_vkEnumerateInstanceExtensionProperties(const char *pLayerName, uint32_t *pPropertyCount, VkExtensionProperties *pProperties) {\n" +
    "  PFN_vkEnumerateInstanceExtensionProperties fn = (PFN_vkEnumerateInstanceExtensionProperties)tycho_vk_gpa(VK_NULL_HANDLE, \"vkEnumerateInstanceExtensionProperties\");\n" +
    "  return fn ? (int32_t)fn(pLayerName, pPropertyCount, pProperties) : (int32_t)VK_ERROR_INITIALIZATION_FAILED;\n" +
    "}\n" +
    "MOONBIT_FFI_EXPORT void tycho_entry_vkGetExternalComputeQueueDataNV(VkExternalComputeQueueNV externalQueue, VkExternalComputeQueueDataParamsNV *params, void *pData) {\n" +
    "  typedef void (VKAPI_PTR *TychoPFN_ECQ)(VkExternalComputeQueueNV, VkExternalComputeQueueDataParamsNV *, void *);\n" +
    "  TychoPFN_ECQ fn = (TychoPFN_ECQ)tycho_vk_gpa(VK_NULL_HANDLE, \"vkGetExternalComputeQueueDataNV\");\n" +
    "  if (fn) fn(externalQueue, params, pData);\n" +
    "}\n\n",
  )
  // ABI audit: every command parameter's C width must fit the MoonBit type it
  // is marshalled as. A uint64_t param mapped to UInt32 would silently lose
  // the high half; this makes the compiler reject it instead.
  for cmd in inst {
    emit_param_asserts(sb, cmd, t, defined)
    sb.write_string(
      "MOONBIT_FFI_EXPORT void *tycho_gpa_\{cmd.name}(void *h) { return tycho_vk_gpa((VkInstance)h, \"\{cmd.name}\"); }\n",
    )
  }
  for cmd in dev {
    emit_param_asserts(sb, cmd, t, defined)
    sb.write_string(
      "MOONBIT_FFI_EXPORT void *tycho_gpa_\{cmd.name}(void *h) { return tycho_vk_gdpa((VkDevice)h, \"\{cmd.name}\"); }\n",
    )
  }
  sb.to_string()
}

///|
fn emit_param_asserts(
  sb : StringBuilder,
  cmd : VkCommand,
  t : VkTypes,
  defined : @hashmap.HashMap[String, Unit],
) -> Unit {
  for p in cmd.params {
    let ct = p.ctype.trim().to_owned()
    // Pointers and decayed arrays are pointer-sized by construction; asserting
    // on them would drag in every platform/external header.
    if ct.contains_char('*') || ct.contains_char('[') {
      continue
    }
    let base = base_type(ct)
    let known = is_scalar_base(base) || (base.has_prefix("Vk") && defined.contains(base))
    if !known {
      continue
    }
    let mb_t = mb_type(p.ctype, t)
    if mb_t == "Unit" {
      continue
    }
    let w = mb_scalar_width(mb_t)
    let expr = if w == 0 { "sizeof(void*)" } else { w.to_string() }
    sb.write_string(
      "TYCHO_STATIC_ASSERT(sizeof(\{ct}) <= \{expr}, \"tycho ABI: \{cmd.name} \{p.name} wider than MoonBit type\");\n",
    )
  }
}