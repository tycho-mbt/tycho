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
      "pub extern \"c\" fn \{cmd.name}(\{params.to_string()}) -> \{mb_type(cmd.ret, t)} = \"\{cmd.name}\"\n",
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
  sb.write_string("#define VK_ENABLE_BETA_EXTENSIONS\n")
  sb.write_string("#include \"include/vulkan/vulkan.h\"\n#include \"moonbit.h\"\n\n")
  // ABI audit: every command parameter's C width must fit the MoonBit type it
  // is marshalled as. A uint64_t param mapped to UInt32 would silently lose
  // the high half; this makes the compiler reject it instead.
  for cmd in inst {
    emit_param_asserts(sb, cmd, t, defined)
    sb.write_string(
      "MOONBIT_FFI_EXPORT void *tycho_gpa_\{cmd.name}(void *h) { return (void *)vkGetInstanceProcAddr((VkInstance)h, \"\{cmd.name}\"); }\n",
    )
  }
  for cmd in dev {
    emit_param_asserts(sb, cmd, t, defined)
    sb.write_string(
      "MOONBIT_FFI_EXPORT void *tycho_gpa_\{cmd.name}(void *h) { return (void *)vkGetDeviceProcAddr((VkDevice)h, \"\{cmd.name}\"); }\n",
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
      "_Static_assert(sizeof(\{ct}) <= \{expr}, \"tycho ABI: \{cmd.name} \{p.name} wider than MoonBit type\");\n",
    )
  }
}