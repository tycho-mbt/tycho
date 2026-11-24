///|
pub struct VkMember {
  ctype : String
  name : String
  stype : String?
  is_array : Bool
}

///|
fn member_ctype(m : XmlNode) -> String {
  let sb = StringBuilder()
  for c in m.children {
    if c.name == "name" || c.name == "comment" {
      continue
    }
    if c.name == "#text" {
      sb.write_string(c.text)
    } else {
      sb.write_string(c.inner_text())
    }
  }
  sb.to_string().trim().to_owned()
}

///|
fn str_has(arr : Array[String], x : String) -> Bool {
  for a in arr {
    if a == x {
      return true
    }
  }
  false
}

///|
// Escape member names that collide with MoonBit keywords when used as method names.
fn safe_method(f : String) -> String {
  match f {
    "type" | "module" | "fn" | "let" | "mut" | "match" | "if" | "else" | "for" | "while" |
    "return" | "struct" | "enum" | "trait" | "impl" | "pub" | "priv" | "extern" | "import" |
    "true" | "false" | "as" | "in" | "is" | "break" | "continue" | "defer" | "guard" | "raise" |
    "try" | "catch" | "async" | "await" | "const" | "self" | "where" | "with" | "do" | "export" |
    "static" | "super" | "yield" | "finally" | "throw" => f + "_"
    _ => f
  }
}

///|
pub fn parse_struct_members(registry : XmlNode, name : String) -> Array[VkMember] {
  let out : Array[VkMember] = []
  let seen : Array[String] = []
  guard registry.child("types") is Some(types) else { return out }
  for ty in types.children {
    if ty.name != "type" {
      continue
    }
    guard ty.attr("name") is Some(n) && n == name else { continue }
    for m in ty.children {
      if m.name != "member" {
        continue
      }
      let nm = match m.child("name") {
        Some(nn) => nn.inner_text().trim().to_owned()
        None => ""
      }
      if nm == "" || str_has(seen, nm) {
        continue
      }
      seen.push(nm)
      let ct = member_ctype(m)
      out.push({ ctype: ct, name: nm, stype: m.attr("values"), is_array: ct.contains_char('[') })
    }
  }
  out
}

///|
// Extract type names actually defined in vulkan_core.h, so we only generate
// accessors for structs whose types exist in the SDK header (vk.xml may be ahead).
pub fn header_defined_types(text : String) -> Array[String] {
  let out : Array[String] = []
  for line in text.split("\n") {
    let l = line.trim().to_owned()
    if l.has_prefix("} Vk") && l.has_suffix(";") {
      let name = l.substring(start=2, end=l.length() - 1).trim().to_owned()
      if name.has_prefix("Vk") && !name.contains_char(' ') {
        out.push(name)
      }
    }
    if l.contains("HANDLE(") {
      match l.split_once("(") {
        Some((_, rest)) =>
          match rest.split_once(")") {
            Some((nm, _)) => {
              let name = nm.trim().to_owned()
              if name.has_prefix("Vk") {
                out.push(name)
              }
            }
            None => ()
          }
        None => ()
      }
    }
    if l.has_prefix("typedef") && l.has_suffix(";") {
      let body = l.substring(start=0, end=l.length() - 1)
      let mut last = ""
      for tok in body.split(" ") {
        let t = tok.trim().to_owned()
        if t != "" {
          last = t
        }
      }
      if last.has_prefix("Vk") {
        out.push(last)
      }
    }
  }
  out
}

///|
fn is_scalar_base(base : String) -> Bool {
  match base {
    "uint32_t" | "int32_t" | "uint64_t" | "int64_t" | "float" | "double" | "uint8_t" |
    "int8_t" | "uint16_t" | "int16_t" | "size_t" | "int" => true
    _ => false
  }
}

///|
// Core types start with "Vk" or are C scalars/void/char. Platform types
// (Display, HWND, ANativeWindow, CAMetalLayer, ...) do not -> skip such structs.
fn is_core_base(base : String) -> Bool {
  base.has_prefix("Vk") || is_scalar_base(base) || base == "void" || base == "char" ||
  base == "Display" || base == "Window" || base == "VisualID" ||
  is_platform_base(base)
}

///|
// Window-system types appearing in WSI structs. They are opaque handles or
// pointers on every platform; DWORD is the only sized scalar among them.
fn is_platform_base(base : String) -> Bool {
  match base {
    "HINSTANCE" | "HWND" | "HANDLE" | "HMONITOR" | "DWORD" | "LPCWSTR" |
    "SECURITY_ATTRIBUTES" | "CAMetalLayer" | "IOSurfaceRef" | "MTLDevice_id" |
    "MTLCommandQueue_id" | "MTLBuffer_id" | "MTLTexture_id" | "MTLSharedEvent_id" |
    "xcb_connection_t" | "xcb_window_t" | "xcb_visualid_t" | "wl_display" |
    "wl_surface" => true
    _ => false
  }
}

///|
// WSI structs are only compilable on their own platform; the C accessors are
// guarded while the MoonBit API stays declared everywhere (unused externs do
// not create link references).
fn platform_guard(
  name : String,
  platforms : @hashmap.HashMap[String, String],
) -> String? {
  platforms.get(name)
}

///|
fn struct_generatable(
  members : Array[VkMember],
  fp : @hashmap.HashMap[String, String],
) -> Bool {
  for m in members {
    if m.name == "" || m.name == "sType" {
      continue
    }
    if m.ctype.contains_char(':') {
      return false
    }
    let b0 = base_type(m.ctype)
    let b = match b0.split_once("[") {
      Some((pre, _)) => pre.trim().to_owned()
      None => b0
    }
    if !is_core_base(b) && !fp.contains(b) {
      return false
    }
  }
  true
}

///|
// One C symbol per FixedArray element type. MoonBit emits a single forward
// declaration per symbol, so sharing `tycho_pin` across element types makes it
// infer e.g. `void tycho_pin(void*, float*)` and warn on every handle array.
fn pin_symbol(mb_t : String) -> String {
  let inner = mb_t.replace_all(old="FixedArray[", new="").replace_all(old="]", new="")
  "tycho_pin_\{inner}"
}

///|
// Byte width of a MoonBit scalar as passed through the C ABI. 0 means the type
// is pointer-shaped (opaque handle, FixedArray, FuncRef, String, void* UInt64).
// Used to emit _Static_asserts so every generated accessor is ABI-audited by
// the compiler, not just the handful the examples happen to exercise.
fn mb_scalar_width(mb_t : String) -> Int {
  match mb_t {
    "Byte" => 1
    "UInt16" | "Int16" => 2
    "UInt32" | "Int32" | "Float" | "Int" | "UInt" => 4
    "UInt64" | "Int64" | "Double" => 8
    _ => 0
  }
}

///|
fn abi_width_expr(mb_t : String) -> String {
  let w = mb_scalar_width(mb_t)
  if w == 0 {
    "sizeof(void*)"
  } else {
    w.to_string()
  }
}

///|
fn emit_ptr_accessor(
  mb : StringBuilder,
  c : StringBuilder,
  sname : String,
  f : String,
  mb_t : String,
  c_cast : String,
  pins : @hashmap.HashMap[String, Unit],
) -> Unit {
  c.write_string(
    "MOONBIT_FFI_EXPORT void tycho_\{sname}_set_\{f}(void *p, void *v) { ((\{sname}*)p)->\{f} = \{c_cast}v; }\n",
  )
  c.write_string(
    "TYCHO_STATIC_ASSERT(sizeof(((\{sname}*)0)->\{f}) == sizeof(void*), \"tycho ABI: \{sname}.\{f} must be pointer-sized\");\n",
  )
  c.write_string(
    "MOONBIT_FFI_EXPORT void *tycho_\{sname}_get_\{f}(void *p) { return (void*)\{c_cast}((\{sname}*)p)->\{f}; }\n",
  )
  c.write_string(
    "MOONBIT_FFI_EXPORT void tycho_\{sname}_set_\{f}_at(void *p, int32_t i, void *v) { ((\{sname}*)p)[i].\{f} = \{c_cast}v; }\n",
  )
  c.write_string(
    "MOONBIT_FFI_EXPORT void *tycho_\{sname}_get_\{f}_at(void *p, int32_t i) { return (void*)\{c_cast}((\{sname}*)p)[i].\{f}; }\n",
  )
  mb.write_string(
    "extern \"c\" fn \{sname}::set_\{f}_ffi(self : \{sname}, v : \{mb_t}) = \"tycho_\{sname}_set_\{f}\"\n",
  )
  if mb_t.has_prefix("FixedArray") {
    pins.set(pin_symbol(mb_t), ())
    mb.write_string(
      "extern \"c\" fn \{sname}::pin_\{f}(self : \{sname}, v : \{mb_t}) = \"\{pin_symbol(mb_t)}\"\n",
    )
    mb.write_string(
      "pub fn \{sname}::set_\{f}(self : \{sname}, v : \{mb_t}) -> Unit { self.set_\{f}_ffi(v); self.pin_\{f}(v) }\n",
    )
  } else {
    mb.write_string(
      "pub fn \{sname}::set_\{f}(self : \{sname}, v : \{mb_t}) -> Unit { self.set_\{f}_ffi(v) }\n",
    )
  }
  mb.write_string(
    "extern \"c\" fn \{sname}::get_\{f}_ffi(self : \{sname}) -> \{mb_t} = \"tycho_\{sname}_get_\{f}\"\n",
  )
  mb.write_string("pub fn \{sname}::get_\{f}(self : \{sname}) -> \{mb_t} { self.get_\{f}_ffi() }\n")
  mb.write_string(
    "extern \"c\" fn \{sname}::set_\{f}_at_ffi(self : \{sname}, i : Int32, v : \{mb_t}) = \"tycho_\{sname}_set_\{f}_at\"\n",
  )
  if mb_t.has_prefix("FixedArray") {
    pins.set(pin_symbol(mb_t), ())
    mb.write_string(
      "extern \"c\" fn \{sname}::pin_\{f}_at(self : \{sname}, v : \{mb_t}) = \"\{pin_symbol(mb_t)}\"\n",
    )
    mb.write_string(
      "pub fn \{sname}::set_\{f}_at(self : \{sname}, i : Int32, v : \{mb_t}) -> Unit { self.set_\{f}_at_ffi(i, v); self.pin_\{f}_at(v) }\n",
    )
  } else {
    mb.write_string(
      "pub fn \{sname}::set_\{f}_at(self : \{sname}, i : Int32, v : \{mb_t}) -> Unit { self.set_\{f}_at_ffi(i, v) }\n",
    )
  }
  mb.write_string(
    "extern \"c\" fn \{sname}::get_\{f}_at_ffi(self : \{sname}, i : Int32) -> \{mb_t} = \"tycho_\{sname}_get_\{f}_at\"\n",
  )
  mb.write_string(
    "pub fn \{sname}::get_\{f}_at(self : \{sname}, i : Int32) -> \{mb_t} { self.get_\{f}_at_ffi(i) }\n",
  )
}

///|
fn emit_scalar_accessor(
  mb : StringBuilder,
  c : StringBuilder,
  sname : String,
  f : String,
  mb_t : String,
  c_t : String,
  pins : @hashmap.HashMap[String, Unit],
) -> Unit {
  c.write_string(
    "MOONBIT_FFI_EXPORT void tycho_\{sname}_set_\{f}(void *p, \{c_t} v) { ((\{sname}*)p)->\{f} = v; }\n",
  )
  c.write_string(
    "TYCHO_STATIC_ASSERT(sizeof(((\{sname}*)0)->\{f}) <= \{abi_width_expr(mb_t)}, \"tycho ABI: \{sname}.\{f} wider than its MoonBit type\");\n",
  )
  c.write_string(
    "MOONBIT_FFI_EXPORT \{c_t} tycho_\{sname}_get_\{f}(void *p) { return ((\{sname}*)p)->\{f}; }\n",
  )
  c.write_string(
    "MOONBIT_FFI_EXPORT void tycho_\{sname}_set_\{f}_at(void *p, int32_t i, \{c_t} v) { ((\{sname}*)p)[i].\{f} = v; }\n",
  )
  c.write_string(
    "MOONBIT_FFI_EXPORT \{c_t} tycho_\{sname}_get_\{f}_at(void *p, int32_t i) { return ((\{sname}*)p)[i].\{f}; }\n",
  )
  mb.write_string(
    "extern \"c\" fn \{sname}::set_\{f}_ffi(self : \{sname}, v : \{mb_t}) = \"tycho_\{sname}_set_\{f}\"\n",
  )
  if mb_t.has_prefix("FixedArray") {
    pins.set(pin_symbol(mb_t), ())
    mb.write_string(
      "extern \"c\" fn \{sname}::pin_\{f}(self : \{sname}, v : \{mb_t}) = \"\{pin_symbol(mb_t)}\"\n",
    )
    mb.write_string(
      "pub fn \{sname}::set_\{f}(self : \{sname}, v : \{mb_t}) -> Unit { self.set_\{f}_ffi(v); self.pin_\{f}(v) }\n",
    )
  } else {
    mb.write_string(
      "pub fn \{sname}::set_\{f}(self : \{sname}, v : \{mb_t}) -> Unit { self.set_\{f}_ffi(v) }\n",
    )
  }
  mb.write_string(
    "extern \"c\" fn \{sname}::get_\{f}_ffi(self : \{sname}) -> \{mb_t} = \"tycho_\{sname}_get_\{f}\"\n",
  )
  mb.write_string("pub fn \{sname}::get_\{f}(self : \{sname}) -> \{mb_t} { self.get_\{f}_ffi() }\n")
  mb.write_string(
    "extern \"c\" fn \{sname}::set_\{f}_at_ffi(self : \{sname}, i : Int32, v : \{mb_t}) = \"tycho_\{sname}_set_\{f}_at\"\n",
  )
  if mb_t.has_prefix("FixedArray") {
    pins.set(pin_symbol(mb_t), ())
    mb.write_string(
      "extern \"c\" fn \{sname}::pin_\{f}_at(self : \{sname}, v : \{mb_t}) = \"\{pin_symbol(mb_t)}\"\n",
    )
    mb.write_string(
      "pub fn \{sname}::set_\{f}_at(self : \{sname}, i : Int32, v : \{mb_t}) -> Unit { self.set_\{f}_at_ffi(i, v); self.pin_\{f}_at(v) }\n",
    )
  } else {
    mb.write_string(
      "pub fn \{sname}::set_\{f}_at(self : \{sname}, i : Int32, v : \{mb_t}) -> Unit { self.set_\{f}_at_ffi(i, v) }\n",
    )
  }
  mb.write_string(
    "extern \"c\" fn \{sname}::get_\{f}_at_ffi(self : \{sname}, i : Int32) -> \{mb_t} = \"tycho_\{sname}_get_\{f}_at\"\n",
  )
  mb.write_string(
    "pub fn \{sname}::get_\{f}_at(self : \{sname}, i : Int32) -> \{mb_t} { self.get_\{f}_at_ffi(i) }\n",
  )
}

///|
// Array / nested-by-value member: copy bytes from a source pointer.
fn emit_memcpy_setter(
  mb : StringBuilder,
  c : StringBuilder,
  sname : String,
  f : String,
  mb_t : String,
) -> Unit {
  c.write_string(
    "MOONBIT_FFI_EXPORT void tycho_\{sname}_set_\{f}(void *p, const void *src) { memcpy(&((\{sname}*)p)->\{f}, src, sizeof(((\{sname}*)p)->\{f})); }\n",
  )
  c.write_string(
    "MOONBIT_FFI_EXPORT void tycho_\{sname}_set_\{f}_at(void *p, int32_t i, const void *src) { memcpy(&((\{sname}*)p)[i].\{f}, src, sizeof(((\{sname}*)p)[i].\{f})); }\n",
  )
  mb.write_string(
    "extern \"c\" fn \{sname}::set_\{f}_ffi(self : \{sname}, src : \{mb_t}) = \"tycho_\{sname}_set_\{f}\"\n",
  )
  mb.write_string(
    "pub fn \{sname}::set_\{f}(self : \{sname}, src : \{mb_t}) -> Unit { self.set_\{f}_ffi(src) }\n",
  )
  mb.write_string(
    "extern \"c\" fn \{sname}::set_\{f}_at_ffi(self : \{sname}, i : Int32, src : \{mb_t}) = \"tycho_\{sname}_set_\{f}_at\"\n",
  )
  mb.write_string(
    "pub fn \{sname}::set_\{f}_at(self : \{sname}, i : Int32, src : \{mb_t}) -> Unit { self.set_\{f}_at_ffi(i, src) }\n",
  )
}

///|
// Getter for a nested-by-value struct member: returns a pointer to the field.
fn emit_nested_getter(
  mb : StringBuilder,
  c : StringBuilder,
  sname : String,
  f : String,
  nested_t : String,
) -> Unit {
  c.write_string(
    "MOONBIT_FFI_EXPORT void *tycho_\{sname}_get_\{f}(void *p) { return &((\{sname}*)p)->\{f}; }\n",
  )
  mb.write_string(
    "extern \"c\" fn \{sname}::get_\{f}_ffi(self : \{sname}) -> \{nested_t} = \"tycho_\{sname}_get_\{f}\"\n",
  )
  mb.write_string(
    "pub fn \{sname}::get_\{f}(self : \{sname}) -> \{nested_t} { self.get_\{f}_ffi() }\n",
  )
}

///|
// Indexed getter for an array-of-struct member: returns a pointer to element i.
fn emit_array_struct_getter(
  mb : StringBuilder,
  c : StringBuilder,
  sname : String,
  f : String,
  elem_t : String,
) -> Unit {
  c.write_string(
    "MOONBIT_FFI_EXPORT void *tycho_\{sname}_get_\{f}_at(void *p, int32_t i) { return &((\{sname}*)p)->\{f}[i]; }\n",
  )
  mb.write_string(
    "extern \"c\" fn \{sname}::get_\{f}_at_ffi(self : \{sname}, i : Int32) -> \{elem_t} = \"tycho_\{sname}_get_\{f}_at\"\n",
  )
  mb.write_string(
    "pub fn \{sname}::get_\{f}_at(self : \{sname}, i : Int32) -> \{elem_t} { self.get_\{f}_at_ffi(i) }\n",
  )
}

///|
// Getters for fixed-size scalar/char array members. Without these, fields like
// VkPhysicalDeviceProperties.deviceName and VkExtensionProperties.extensionName
// are write-only. Setters stay memcpy-based (emit_memcpy_setter); only the
// getter symbols are new, so nothing collides.
fn emit_array_scalar_getter(
  mb : StringBuilder,
  c : StringBuilder,
  sname : String,
  f : String,
  elem : String,
  mb_elem : String,
  ndims : Int,
) -> Unit {
  c.write_string(
    "MOONBIT_FFI_EXPORT uint8_t *tycho_\{sname}_get_\{f}(void *p) { size_t n = sizeof(((\{sname}*)p)->\{f}); uint8_t *a = (uint8_t*)moonbit_make_bytes((int32_t)n, 0); memcpy(a, &((\{sname}*)p)->\{f}, n); return a; }\n",
  )
  mb.write_string(
    "extern \"c\" fn \{sname}::get_\{f}_ffi(self : \{sname}) -> Bytes = \"tycho_\{sname}_get_\{f}\"\n",
  )
  mb.write_string("pub fn \{sname}::get_\{f}(self : \{sname}) -> Bytes { self.get_\{f}_ffi() }\n")
  // `float matrix[3][4]` indexes to a row pointer, not a scalar: only 1-D
  // arrays get per-element and C-string getters.
  if ndims != 1 {
    return
  }
  c.write_string(
    "MOONBIT_FFI_EXPORT \{elem} tycho_\{sname}_get_\{f}_at(void *p, int32_t i) { return ((\{sname}*)p)->\{f}[i]; }\n",
  )
  mb.write_string(
    "extern \"c\" fn \{sname}::get_\{f}_at_ffi(self : \{sname}, i : Int32) -> \{mb_elem} = \"tycho_\{sname}_get_\{f}_at\"\n",
  )
  mb.write_string(
    "pub fn \{sname}::get_\{f}_at(self : \{sname}, i : Int32) -> \{mb_elem} { self.get_\{f}_at_ffi(i) }\n",
  )
  if elem == "char" {
    c.write_string(
      "MOONBIT_FFI_EXPORT moonbit_string_t tycho_\{sname}_get_\{f}_string(void *p) { const char *s = ((\{sname}*)p)->\{f}; size_t n = sizeof(((\{sname}*)p)->\{f}); size_t len = 0; while (len < n && s[len]) len++; moonbit_string_t out = moonbit_make_string_raw((int32_t)len); for (size_t i = 0; i < len; i++) out[i] = (uint16_t)(unsigned char)s[i]; return out; }\n",
    )
    mb.write_string(
      "extern \"c\" fn \{sname}::get_\{f}_string_ffi(self : \{sname}) -> String = \"tycho_\{sname}_get_\{f}_string\"\n",
    )
    mb.write_string(
      "pub fn \{sname}::get_\{f}_string(self : \{sname}) -> String { self.get_\{f}_string_ffi() }\n",
    )
    c.write_string(
      "MOONBIT_FFI_EXPORT moonbit_string_t tycho_\{sname}_get_\{f}_string_at(void *p, int32_t i) { const char *s = ((\{sname}*)p)[i].\{f}; size_t n = sizeof(((\{sname}*)p)[i].\{f}); size_t len = 0; while (len < n && s[len]) len++; moonbit_string_t out = moonbit_make_string_raw((int32_t)len); for (size_t k = 0; k < len; k++) out[k] = (uint16_t)(unsigned char)s[k]; return out; }\n",
    )
    mb.write_string(
      "extern \"c\" fn \{sname}::get_\{f}_string_at_ffi(self : \{sname}, i : Int32) -> String = \"tycho_\{sname}_get_\{f}_string_at\"\n",
    )
    mb.write_string(
      "pub fn \{sname}::get_\{f}_string_at(self : \{sname}, i : Int32) -> String { self.get_\{f}_string_at_ffi(i) }\n",
    )
  }
}

///|
pub fn emit_structs(
  registry : XmlNode,
  names : Array[String],
  t : VkTypes,
  defined : @hashmap.HashMap[String, Unit],
  platforms : @hashmap.HashMap[String, String],
  fp : @hashmap.HashMap[String, String],
) -> (String, String) {
  let mb = StringBuilder()
  let c = StringBuilder()
  mb.write_string("// Generated struct constructors + field accessors (C handles layout).\n")
  mb.write_string("// pNext chains: head.set_pNext(next.as_ptr()). Both structs must stay\n")
  mb.write_string("// alive (not .free()d) until the Vulkan call that consumes head returns.\n\n")
  mb.write_string("extern \"c\" fn cstr_ffi(bytes : Bytes, len : Int32) -> UInt64 = \"tycho_cstr\"\n")
  mb.write_string(
    "pub fn cstr(s : String) -> UInt64 { let b = @utf8.encode(s); cstr_ffi(b, b.length()) }\n",
  )
  mb.write_string(
    "pub fn cstr_array(strs : FixedArray[String]) -> FixedArray[UInt64] { let ptrs = FixedArray::make(strs.length(), (0 : UInt64)); for i = 0; i < strs.length(); i = i + 1 { ptrs[i] = cstr(strs[i]) }; ptrs }\n\n",
  )
  // Read a driver-owned C string (e.g. a validation message) into a MoonBit String.
  mb.write_string("extern \"c\" fn read_cstr_ffi(p : UInt64) -> String = \"tycho_read_cstr\"\n")
  mb.write_string("pub fn read_cstr(p : UInt64) -> String { read_cstr_ffi(p) }\n")
  mb.write_string("extern \"c\" fn bytes_ptr_ffi(a : Bytes) -> UInt64 = \"tycho_as_ptr\"\n")
  mb.write_string("pub fn bytes_ptr(a : Bytes) -> UInt64 { bytes_ptr_ffi(a) }\n")
  // Vulkan requires aligned host pointers in several places (shader binary data
  // 16B, imported host memory page-aligned); MoonBit arrays cannot guarantee it.
  mb.write_string(
    "extern \"c\" fn aligned_alloc_ffi(size : Int32, alignment : Int32) -> UInt64 = \"tycho_aligned_alloc\"\n",
  )
  mb.write_string(
    "pub fn aligned_alloc(size : Int32, alignment : Int32) -> UInt64 { aligned_alloc_ffi(size, alignment) }\n",
  )
  mb.write_string("extern \"c\" fn free_ptr_ffi(p : UInt64) = \"tycho_free_ptr\"\n")
  mb.write_string("pub fn free_ptr(p : UInt64) -> Unit { free_ptr_ffi(p) }\n")
  mb.write_string(
    "extern \"c\" fn memcpy_ptr_ffi(dst : UInt64, src : UInt64, bytes : Int32) = \"tycho_memcpy_ptr\"\n",
  )
  mb.write_string(
    "pub fn memcpy_ptr(dst : UInt64, src : UInt64, bytes : Int32) -> Unit { memcpy_ptr_ffi(dst, src, bytes) }\n",
  )
  // TLAS instances: the struct has bitfields, so construction is a C helper.
  mb.write_string(
    "extern \"c\" fn rt_instance_array_ffi(n : Int32) -> UInt64 = \"tycho_rt_instance_array\"\n",
  )
  mb.write_string(
    "#borrow(transform)\nextern \"c\" fn rt_instance_set_ffi(p : UInt64, i : Int32, transform : VkTransformMatrixKHR, customIndex : UInt32, mask : UInt32, sbtOffset : UInt32, flags : UInt32, addr : UInt64) = \"tycho_rt_instance_set\"\n",
  )
  mb.write_string(
    "extern \"c\" fn rt_instance_free_ffi(p : UInt64) = \"tycho_rt_instance_free\"\n",
  )
  mb.write_string(
    "pub fn rt_instance_array(n : Int32) -> UInt64 { rt_instance_array_ffi(n) }\n",
  )
  mb.write_string(
    "pub fn rt_instance_set(p : UInt64, i : Int32, transform : VkTransformMatrixKHR, customIndex : UInt32, mask : UInt32, sbtOffset : UInt32, flags : UInt32, addr : UInt64) -> Unit { rt_instance_set_ffi(p, i, transform, customIndex, mask, sbtOffset, flags, addr) }\n",
  )
  mb.write_string("pub fn rt_instance_free(p : UInt64) -> Unit { rt_instance_free_ffi(p) }\n\n")
  // `void*` params are UInt64, so users need a way to hand a MoonBit array's
  // address to Vulkan (e.g. vkGetPipelineCacheData's pData). The array stays
  // alive as a call argument, so no pinning is needed for synchronous calls.
  for (suffix, ty) in [
    ("byte", "Byte"), ("uint32", "UInt32"), ("uint64", "UInt64"), ("float", "Float"),
    ("int32", "Int32"),
  ] {
    mb.write_string(
      "extern \"c\" fn \{suffix}_ptr_ffi(a : FixedArray[\{ty}]) -> UInt64 = \"tycho_as_ptr\"\n",
    )
    mb.write_string(
      "pub fn \{suffix}_ptr(a : FixedArray[\{ty}]) -> UInt64 { \{suffix}_ptr_ffi(a) }\n",
    )
  }
  mb.write_string("\n")
  // Debug messenger: the callback must be capture-free (FuncRef requirement);
  // accumulate state in a top-level `let g : Ref[T]` instead of a local.
  mb.write_string(
    "pub fn create_debug_messenger(inst : VkInstance, ifn : InstanceFn, severity : UInt32, types : UInt32, cb : FuncRef[(UInt32, UInt32, VkDebugUtilsMessengerCallbackDataEXT, UInt64) -> UInt32]) -> VkDebugUtilsMessengerEXT { let ci = VkDebugUtilsMessengerCreateInfoEXT::new(); ci.set_messageSeverity(severity); ci.set_messageType(types); ci.set_pfnUserCallback(cb); ci.set_pUserData((0 : UInt64)); let out = FixedArray::make(1, VkDebugUtilsMessengerEXT::null()); let _ = (ifn.vkCreateDebugUtilsMessengerEXT)(inst, ci, VkAllocationCallbacks::null(), out); ci.free(); out[0] }\n",
  )
  mb.write_string(
    "pub fn destroy_debug_messenger(inst : VkInstance, ifn : InstanceFn, m : VkDebugUtilsMessengerEXT) -> Unit { (ifn.vkDestroyDebugUtilsMessengerEXT)(inst, m, VkAllocationCallbacks::null()) }\n\n",
  )
  // Convenience marshaling helpers for VkClearValue union member setters.
  mb.write_string(
    "extern \"c\" fn VkClearValue::set_color_rgba_ffi(self : VkClearValue, r : Float, g : Float, b : Float, a : Float) = \"tycho_set_clear_color\"\n",
  )
  mb.write_string(
    "pub fn VkClearValue::set_color_rgba(self : VkClearValue, r : Float, g : Float, b : Float, a : Float) -> Unit { self.set_color_rgba_ffi(r, g, b, a) }\n",
  )
  mb.write_string(
    "extern \"c\" fn VkClearValue::set_depth_stencil_ffi(self : VkClearValue, depth : Float, stencil : UInt32) = \"tycho_set_clear_depth_stencil\"\n",
  )
  mb.write_string(
    "pub fn VkClearValue::set_depth_stencil(self : VkClearValue, depth : Float, stencil : UInt32) -> Unit { self.set_depth_stencil_ffi(depth, stencil) }\n\n",
  )
  // Buffer-upload + render-readback conveniences so examples/users stay pure MoonBit.
  mb.write_string(
    "#borrow(data)\nextern \"c\" fn upload_buffer_ffi(dev : VkDevice, mem : VkDeviceMemory, data : FixedArray[Float], bytes : Int32) -> Int32 = \"tycho_upload_buffer\"\n",
  )
  mb.write_string(
    "pub fn upload_buffer(dev : VkDevice, mem : VkDeviceMemory, data : FixedArray[Float], bytes : Int32) -> Int32 { upload_buffer_ffi(dev, mem, data, bytes) }\n",
  )
  mb.write_string(
    "#borrow(data)\nextern \"c\" fn upload_bytes_ffi(dev : VkDevice, mem : VkDeviceMemory, data : Bytes, bytes : Int32) -> Int32 = \"tycho_upload_bytes\"\n",
  )
  mb.write_string(
    "pub fn upload_bytes(dev : VkDevice, mem : VkDeviceMemory, data : Bytes, bytes : Int32) -> Int32 { upload_bytes_ffi(dev, mem, data, bytes) }\n",
  )
  mb.write_string(
    "#borrow(data)\nextern \"c\" fn upload_uint32_ffi(dev : VkDevice, mem : VkDeviceMemory, data : FixedArray[UInt32], bytes : Int32) -> Int32 = \"tycho_upload_bytes\"\n",
  )
  mb.write_string(
    "pub fn upload_uint32(dev : VkDevice, mem : VkDeviceMemory, data : FixedArray[UInt32], bytes : Int32) -> Int32 { upload_uint32_ffi(dev, mem, data, bytes) }\n",
  )
  mb.write_string(
    "extern \"c\" fn download_buffer_ffi(dev : VkDevice, mem : VkDeviceMemory, bytes : Int32) -> Bytes = \"tycho_download_buffer\"\n",
  )
  mb.write_string(
    "pub fn download_buffer(dev : VkDevice, mem : VkDeviceMemory, bytes : Int32) -> Bytes { download_buffer_ffi(dev, mem, bytes) }\n",
  )
  mb.write_string(
    "extern \"c\" fn count_rendered_ffi(dev : VkDevice, phys : VkPhysicalDevice, queue : VkQueue, pool : VkCommandPool, image : VkImage, w : UInt32, h : UInt32) -> UInt32 = \"tycho_count_rendered\"\n",
  )
  mb.write_string(
    "pub fn count_rendered(dev : VkDevice, phys : VkPhysicalDevice, queue : VkQueue, pool : VkCommandPool, image : VkImage, w : UInt32, h : UInt32) -> UInt32 { count_rendered_ffi(dev, phys, queue, pool, image, w, h) }\n",
  )
  mb.write_string(
    "extern \"c\" fn readback_image_ffi(dev : VkDevice, phys : VkPhysicalDevice, queue : VkQueue, pool : VkCommandPool, image : VkImage, w : UInt32, h : UInt32) -> FixedArray[Byte] = \"tycho_readback_image\"\n",
  )
  mb.write_string(
    "pub fn readback_image(dev : VkDevice, phys : VkPhysicalDevice, queue : VkQueue, pool : VkCommandPool, image : VkImage, w : UInt32, h : UInt32) -> FixedArray[Byte] { readback_image_ffi(dev, phys, queue, pool, image, w, h) }\n\n",
  )
  c.write_string("// Generated struct accessors — DO NOT EDIT.\n")
  c.write_string("#define VK_NO_PROTOTYPES\n")
  c.write_string("#define VK_ENABLE_BETA_EXTENSIONS\n")
  c.write_string("#if defined(_WIN32)\n#define WIN32_LEAN_AND_MEAN\n#define NOMINMAX\n#define VK_USE_PLATFORM_WIN32_KHR\n#include <windows.h>\n#elif defined(__APPLE__)\n#define VK_USE_PLATFORM_METAL_EXT\n#else\n// Xlib/XCB/Wayland are enabled only where their dev headers exist, so the same\n// tree builds cleanly on minimal/headless systems. vulkan.h pulls WSI headers.\n#if defined(__has_include)\n#if __has_include(<X11/Xlib.h>)\n#define VK_USE_PLATFORM_XLIB_KHR\n#endif\n#if __has_include(<xcb/xcb.h>)\n#define VK_USE_PLATFORM_XCB_KHR\n#endif\n#if __has_include(<wayland-client.h>)\n#define VK_USE_PLATFORM_WAYLAND_KHR\n#endif\n#else\n#define VK_USE_PLATFORM_XLIB_KHR\n#endif\n#endif\n")
  c.write_string("#include \"include/vulkan/vulkan.h\"\n#include <stdlib.h>\n#include <string.h>\n#include <stdio.h>\n#ifdef _WIN32\n#include <malloc.h>\n#endif\n#include \"moonbit.h\"\n\n")
  c.write_string("#if defined(__STDC_VERSION__) && __STDC_VERSION__ >= 201112L\n#define TYCHO_STATIC_ASSERT(cond, msg) _Static_assert(cond, msg)\n#else\n#define TYCHO_SA_JOIN2(a, b) a##b\n#define TYCHO_SA_JOIN(a, b) TYCHO_SA_JOIN2(a, b)\n#define TYCHO_STATIC_ASSERT(cond, msg) typedef char TYCHO_SA_JOIN(tycho_sa_, __LINE__)[(cond) ? 1 : -1]\n#endif\n\n")
  c.write_string("extern VkInstance tycho_vk_last_instance(void);\nextern void *tycho_vk_gpa(VkInstance inst, const char *name);\nextern void *tycho_vk_gdpa(VkDevice dev, const char *name);\n\n")
  c.write_string("MOONBIT_FFI_EXPORT void *tycho_null_ptr(void) { return NULL; }\n")
  // VkAccelerationStructureInstanceKHR packs four bitfields, which the accessor
  // generator cannot express. Pack them in C so TLAS instances stay pure MoonBit.
  c.write_string(
    "MOONBIT_FFI_EXPORT void *tycho_rt_instance_array(int32_t n) { return calloc((size_t)n, sizeof(VkAccelerationStructureInstanceKHR)); }\n",
  )
  c.write_string(
    "MOONBIT_FFI_EXPORT void tycho_rt_instance_set(void *p, int32_t i, const void *transform, uint32_t customIndex, uint32_t mask, uint32_t sbtOffset, uint32_t flags, uint64_t addr) { VkAccelerationStructureInstanceKHR *a = (VkAccelerationStructureInstanceKHR*)p; memcpy(&a[i].transform, transform, sizeof(VkTransformMatrixKHR)); a[i].instanceCustomIndex = customIndex & 0xFFFFFFu; a[i].mask = mask & 0xFFu; a[i].instanceShaderBindingTableRecordOffset = sbtOffset & 0xFFFFFFu; a[i].flags = flags & 0xFFu; a[i].accelerationStructureReference = addr; }\n",
  )
  c.write_string("MOONBIT_FFI_EXPORT void tycho_rt_instance_free(void *p) { free(p); }\n")
  c.write_string(
    "MOONBIT_FFI_EXPORT void tycho_memcpy_ptr(uint64_t dst, uint64_t src, int32_t bytes) { memcpy((void*)(uintptr_t)dst, (const void*)(uintptr_t)src, (size_t)bytes); }\n",
  )
  c.write_string(
    "MOONBIT_FFI_EXPORT uint64_t tycho_as_ptr(const void *p) { return (uint64_t)(uintptr_t)p; }\n",
  )
  c.write_string(
    "MOONBIT_FFI_EXPORT void *tycho_from_ptr(uint64_t p) { return (void*)(uintptr_t)p; }\n\n",
  )
  c.write_string(
    "MOONBIT_FFI_EXPORT char *tycho_cstr(const uint8_t *bytes, int32_t len) { char *s = (char*)malloc(len + 1); memcpy(s, bytes, len); s[len] = 0; return s; }\n",
  )
  c.write_string(
    "MOONBIT_FFI_EXPORT moonbit_string_t tycho_read_cstr(uint64_t p) { const char *s = (const char*)(uintptr_t)p; if (!s) return moonbit_make_string_raw(0); int32_t len = (int32_t)strlen(s); moonbit_string_t out = moonbit_make_string_raw(len); for (int32_t i = 0; i < len; i++) out[i] = (uint16_t)(unsigned char)s[i]; return out; }\n",
  )
  c.write_string(
    "#ifdef _WIN32\ntypedef struct TychoAlignedNode { void *ptr; struct TychoAlignedNode *next; } TychoAlignedNode;\nstatic TychoAlignedNode *g_tycho_aligned = NULL;\n#endif\n" +
    "MOONBIT_FFI_EXPORT uint64_t tycho_aligned_alloc(int32_t size, int32_t alignment) { void *p = NULL;\n#ifdef _WIN32\n  p = _aligned_malloc((size_t)size, (size_t)alignment);\n  if (p) { TychoAlignedNode *n = (TychoAlignedNode*)malloc(sizeof(TychoAlignedNode)); if (n) { n->ptr = p; n->next = g_tycho_aligned; g_tycho_aligned = n; } }\n#else\n  if (posix_memalign(&p, (size_t)alignment, (size_t)size) != 0) p = NULL;\n#endif\n  return (uint64_t)(uintptr_t)p; }\n",
  )
  c.write_string(
    "MOONBIT_FFI_EXPORT void tycho_free_ptr(uint64_t p) { if (!p) return; void *raw = (void*)(uintptr_t)p;\n#ifdef _WIN32\n  TychoAlignedNode **pp = &g_tycho_aligned;\n  while (*pp) { TychoAlignedNode *cur = *pp; if (cur->ptr == raw) { *pp = cur->next; free(cur); _aligned_free(raw); return; } pp = &cur->next; }\n  free(raw);\n#else\n  free(raw);\n#endif\n  }\n\n",
  )
  c.write_string(
    "MOONBIT_FFI_EXPORT void tycho_set_clear_color(void *cv, float r, float g, float b, float a) { VkClearValue *c = (VkClearValue*)cv; c->color.float32[0]=r; c->color.float32[1]=g; c->color.float32[2]=b; c->color.float32[3]=a; }\n",
  )
  c.write_string(
    "MOONBIT_FFI_EXPORT void tycho_set_clear_depth_stencil(void *cv, float depth, uint32_t stencil) { VkClearValue *c = (VkClearValue*)cv; c->depthStencil.depth = depth; c->depthStencil.stencil = stencil; }\n\n",
  )
  c.write_string(
    "MOONBIT_FFI_EXPORT int32_t tycho_upload_buffer(VkDevice dev, VkDeviceMemory mem, const float *data, int32_t bytes) { PFN_vkMapMemory fn_map = (PFN_vkMapMemory)tycho_vk_gdpa(dev, \"vkMapMemory\"); PFN_vkUnmapMemory fn_unmap = (PFN_vkUnmapMemory)tycho_vk_gdpa(dev, \"vkUnmapMemory\"); if (!fn_map || !fn_unmap) return (int32_t)VK_ERROR_INITIALIZATION_FAILED; void *mapped; VkResult r = fn_map(dev, mem, 0, bytes, 0, &mapped); if (r != VK_SUCCESS) return (int32_t)r; memcpy(mapped, data, bytes); fn_unmap(dev, mem); return 0; }\n",
  )
  c.write_string(
    "MOONBIT_FFI_EXPORT int32_t tycho_upload_bytes(VkDevice dev, VkDeviceMemory mem, const uint8_t *data, int32_t bytes) { PFN_vkMapMemory fn_map = (PFN_vkMapMemory)tycho_vk_gdpa(dev, \"vkMapMemory\"); PFN_vkUnmapMemory fn_unmap = (PFN_vkUnmapMemory)tycho_vk_gdpa(dev, \"vkUnmapMemory\"); if (!fn_map || !fn_unmap) return (int32_t)VK_ERROR_INITIALIZATION_FAILED; void *mapped; VkResult r = fn_map(dev, mem, 0, bytes, 0, &mapped); if (r != VK_SUCCESS) return (int32_t)r; memcpy(mapped, data, bytes); fn_unmap(dev, mem); return 0; }\n",
  )
  c.write_string(
    "MOONBIT_FFI_EXPORT uint8_t *tycho_download_buffer(VkDevice dev, VkDeviceMemory mem, int32_t bytes) { PFN_vkMapMemory fn_map = (PFN_vkMapMemory)tycho_vk_gdpa(dev, \"vkMapMemory\"); PFN_vkUnmapMemory fn_unmap = (PFN_vkUnmapMemory)tycho_vk_gdpa(dev, \"vkUnmapMemory\"); void *mapped; uint8_t *arr = (uint8_t*)moonbit_make_bytes(bytes, 0); if (fn_map && fn_unmap && fn_map(dev, mem, 0, bytes, 0, &mapped) == VK_SUCCESS) { memcpy(arr, mapped, bytes); fn_unmap(dev, mem); } return arr; }\n",
  )
  c.write_string(
    "static int tycho_readback_common(VkDevice dev, VkPhysicalDevice phys, VkQueue queue, VkCommandPool pool, VkImage image, uint32_t w, uint32_t h, VkBuffer *out_buf, VkDeviceMemory *out_mem, void **out_mapped) {\n" +
    "  PFN_vkCreateBuffer fn_cb = (PFN_vkCreateBuffer)tycho_vk_gdpa(dev, \"vkCreateBuffer\");\n" +
    "  PFN_vkGetBufferMemoryRequirements fn_mr = (PFN_vkGetBufferMemoryRequirements)tycho_vk_gdpa(dev, \"vkGetBufferMemoryRequirements\");\n" +
    "  PFN_vkGetPhysicalDeviceMemoryProperties fn_mp = (PFN_vkGetPhysicalDeviceMemoryProperties)tycho_vk_gpa(tycho_vk_last_instance(), \"vkGetPhysicalDeviceMemoryProperties\");\n" +
    "  PFN_vkAllocateMemory fn_am = (PFN_vkAllocateMemory)tycho_vk_gdpa(dev, \"vkAllocateMemory\");\n" +
    "  PFN_vkDestroyBuffer fn_db = (PFN_vkDestroyBuffer)tycho_vk_gdpa(dev, \"vkDestroyBuffer\");\n" +
    "  PFN_vkFreeMemory fn_fm = (PFN_vkFreeMemory)tycho_vk_gdpa(dev, \"vkFreeMemory\");\n" +
    "  PFN_vkBindBufferMemory fn_bm = (PFN_vkBindBufferMemory)tycho_vk_gdpa(dev, \"vkBindBufferMemory\");\n" +
    "  PFN_vkAllocateCommandBuffers fn_acb = (PFN_vkAllocateCommandBuffers)tycho_vk_gdpa(dev, \"vkAllocateCommandBuffers\");\n" +
    "  PFN_vkBeginCommandBuffer fn_bcb = (PFN_vkBeginCommandBuffer)tycho_vk_gdpa(dev, \"vkBeginCommandBuffer\");\n" +
    "  PFN_vkCmdPipelineBarrier fn_pb = (PFN_vkCmdPipelineBarrier)tycho_vk_gdpa(dev, \"vkCmdPipelineBarrier\");\n" +
    "  PFN_vkCmdCopyImageToBuffer fn_citb = (PFN_vkCmdCopyImageToBuffer)tycho_vk_gdpa(dev, \"vkCmdCopyImageToBuffer\");\n" +
    "  PFN_vkEndCommandBuffer fn_ecb = (PFN_vkEndCommandBuffer)tycho_vk_gdpa(dev, \"vkEndCommandBuffer\");\n" +
    "  PFN_vkQueueSubmit fn_qs = (PFN_vkQueueSubmit)tycho_vk_gdpa(dev, \"vkQueueSubmit\");\n" +
    "  PFN_vkQueueWaitIdle fn_qwi = (PFN_vkQueueWaitIdle)tycho_vk_gdpa(dev, \"vkQueueWaitIdle\");\n" +
    "  PFN_vkMapMemory fn_map = (PFN_vkMapMemory)tycho_vk_gdpa(dev, \"vkMapMemory\");\n" +
    "  PFN_vkFreeCommandBuffers fn_fcb = (PFN_vkFreeCommandBuffers)tycho_vk_gdpa(dev, \"vkFreeCommandBuffers\");\n" +
    "  if (!fn_cb||!fn_mr||!fn_mp||!fn_am||!fn_db||!fn_fm||!fn_bm||!fn_acb||!fn_bcb||!fn_pb||!fn_citb||!fn_ecb||!fn_qs||!fn_qwi||!fn_map||!fn_fcb) return 0;\n" +
    "  uint32_t bytes = w*h*4; VkBufferCreateInfo bci; memset(&bci,0,sizeof bci); bci.sType=VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO; bci.size=bytes; bci.usage=VK_BUFFER_USAGE_TRANSFER_DST_BIT; bci.sharingMode=VK_SHARING_MODE_EXCLUSIVE;\n" +
    "  VkBuffer buf; if (fn_cb(dev,&bci,NULL,&buf)!=VK_SUCCESS) return 0;\n" +
    "  VkMemoryRequirements req; fn_mr(dev,buf,&req); VkPhysicalDeviceMemoryProperties mp; fn_mp(phys,&mp);\n" +
    "  uint32_t mi=0; VkMemoryPropertyFlags want=VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT|VK_MEMORY_PROPERTY_HOST_COHERENT_BIT;\n" +
    "  for(uint32_t i=0;i<mp.memoryTypeCount;i++) if((req.memoryTypeBits&(1u<<i))&&(mp.memoryTypes[i].propertyFlags&want)==want){mi=i;break;}\n" +
    "  VkMemoryAllocateInfo mai; memset(&mai,0,sizeof mai); mai.sType=VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO; mai.allocationSize=req.size; mai.memoryTypeIndex=mi;\n" +
    "  VkDeviceMemory mem; if(fn_am(dev,&mai,NULL,&mem)!=VK_SUCCESS){fn_db(dev,buf,NULL);return 0;}\n" +
    "  fn_bm(dev,buf,mem,0);\n" +
    "  VkCommandBufferAllocateInfo cbai; memset(&cbai,0,sizeof cbai); cbai.sType=VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO; cbai.commandPool=pool; cbai.level=VK_COMMAND_BUFFER_LEVEL_PRIMARY; cbai.commandBufferCount=1;\n" +
    "  VkCommandBuffer cmd; fn_acb(dev,&cbai,&cmd); VkCommandBufferBeginInfo bi; memset(&bi,0,sizeof bi); bi.sType=VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO; bi.flags=VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT; fn_bcb(cmd,&bi);\n" +
    "  VkImageMemoryBarrier b; memset(&b,0,sizeof b); b.sType=VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER; b.srcQueueFamilyIndex=VK_QUEUE_FAMILY_IGNORED; b.dstQueueFamilyIndex=VK_QUEUE_FAMILY_IGNORED; b.image=image; b.subresourceRange.aspectMask=VK_IMAGE_ASPECT_COLOR_BIT; b.subresourceRange.levelCount=1; b.subresourceRange.layerCount=1; b.srcAccessMask=VK_ACCESS_MEMORY_READ_BIT; b.dstAccessMask=VK_ACCESS_TRANSFER_READ_BIT; b.oldLayout=VK_IMAGE_LAYOUT_PRESENT_SRC_KHR; b.newLayout=VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL;\n" +
    "  fn_pb(cmd,VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT,VK_PIPELINE_STAGE_TRANSFER_BIT,0,0,NULL,0,NULL,1,&b);\n" +
    "  VkBufferImageCopy region; memset(&region,0,sizeof region); region.imageSubresource.aspectMask=VK_IMAGE_ASPECT_COLOR_BIT; region.imageSubresource.layerCount=1; region.imageExtent.width=w; region.imageExtent.height=h; region.imageExtent.depth=1;\n" +
    "  fn_citb(cmd,image,VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,buf,1,&region);\n" +
    "  b.srcAccessMask=VK_ACCESS_TRANSFER_READ_BIT; b.dstAccessMask=VK_ACCESS_MEMORY_READ_BIT; b.oldLayout=VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL; b.newLayout=VK_IMAGE_LAYOUT_PRESENT_SRC_KHR;\n" +
    "  fn_pb(cmd,VK_PIPELINE_STAGE_TRANSFER_BIT,VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT,0,0,NULL,0,NULL,1,&b); fn_ecb(cmd);\n" +
    "  VkSubmitInfo si; memset(&si,0,sizeof si); si.sType=VK_STRUCTURE_TYPE_SUBMIT_INFO; si.commandBufferCount=1; si.pCommandBuffers=&cmd; fn_qs(queue,1,&si,VK_NULL_HANDLE); fn_qwi(queue);\n" +
    "  void *mapped=NULL; int ok=(fn_map(dev,mem,0,bytes,0,&mapped)==VK_SUCCESS);\n" +
    "  fn_fcb(dev,pool,1,&cmd); *out_buf=buf; *out_mem=mem; *out_mapped=ok?mapped:NULL; return 1;\n" +
    "}\n",
  )
  c.write_string(
    "MOONBIT_FFI_EXPORT uint32_t tycho_count_rendered(VkDevice dev, VkPhysicalDevice phys, VkQueue queue, VkCommandPool pool, VkImage image, uint32_t w, uint32_t h) { VkBuffer buf=VK_NULL_HANDLE; VkDeviceMemory mem=VK_NULL_HANDLE; void *mapped=NULL; if(!tycho_readback_common(dev,phys,queue,pool,image,w,h,&buf,&mem,&mapped)) return 0; uint32_t count=0; if(mapped){ uint32_t*px=(uint32_t*)mapped; for(uint32_t i=0;i<w*h;i++) if((px[i]&0x00FFFFFFu)!=0) count++; PFN_vkUnmapMemory fn_um=(PFN_vkUnmapMemory)tycho_vk_gdpa(dev,\"vkUnmapMemory\"); if(fn_um) fn_um(dev,mem); } PFN_vkDestroyBuffer fn_db=(PFN_vkDestroyBuffer)tycho_vk_gdpa(dev,\"vkDestroyBuffer\"); PFN_vkFreeMemory fn_fm=(PFN_vkFreeMemory)tycho_vk_gdpa(dev,\"vkFreeMemory\"); if(fn_db) fn_db(dev,buf,NULL); if(fn_fm) fn_fm(dev,mem,NULL); return count; }\n",
  )
  c.write_string(
    "MOONBIT_FFI_EXPORT uint8_t *tycho_readback_image(VkDevice dev, VkPhysicalDevice phys, VkQueue queue, VkCommandPool pool, VkImage image, uint32_t w, uint32_t h) { VkBuffer buf=VK_NULL_HANDLE; VkDeviceMemory mem=VK_NULL_HANDLE; void *mapped=NULL; if(!tycho_readback_common(dev,phys,queue,pool,image,w,h,&buf,&mem,&mapped)) return (uint8_t*)moonbit_make_bytes(0,0); uint32_t bytes=w*h*4; uint8_t *arr=(uint8_t*)moonbit_make_bytes(bytes,0); if(mapped){ memcpy(arr,mapped,bytes); PFN_vkUnmapMemory fn_um=(PFN_vkUnmapMemory)tycho_vk_gdpa(dev,\"vkUnmapMemory\"); if(fn_um) fn_um(dev,mem); } PFN_vkDestroyBuffer fn_db=(PFN_vkDestroyBuffer)tycho_vk_gdpa(dev,\"vkDestroyBuffer\"); PFN_vkFreeMemory fn_fm=(PFN_vkFreeMemory)tycho_vk_gdpa(dev,\"vkFreeMemory\"); if(fn_db) fn_db(dev,buf,NULL); if(fn_fm) fn_fm(dev,mem,NULL); return arr; }\n\n",
  )
  // Pin registry: struct pointer-fields that reference GC-managed FixedArrays
  // incref the array so MoonBit's RC (which frees at last use) cannot reclaim it
  // while the struct still holds the pointer. Released when the struct is freed.
  c.write_string(
    "typedef struct TychoPin { uint64_t owner; void *obj; struct TychoPin *next; } TychoPin;\nstatic TychoPin *g_tycho_pins = NULL;\nstatic void tycho_pin_impl(void *owner, void *obj) { moonbit_incref(obj); TychoPin *e = (TychoPin*)malloc(sizeof(TychoPin)); e->owner = (uint64_t)(uintptr_t)owner; e->obj = obj; e->next = g_tycho_pins; g_tycho_pins = e; }\nMOONBIT_FFI_EXPORT void tycho_release_pins(void *owner) { TychoPin **pp = &g_tycho_pins; while (*pp) { TychoPin *e = *pp; if (e->owner == (uint64_t)(uintptr_t)owner) { moonbit_decref(e->obj); *pp = e->next; free(e); } else { pp = &e->next; } } }\n\n",
  )
  let pins : @hashmap.HashMap[String, Unit] = @hashmap.HashMap::new()
  let mut generated = 0
  for name in names {
    if !defined.contains(name) {
      continue
    }
    let members = parse_struct_members(registry, name)
    if members.length() == 0 || !struct_generatable(members, fp) {
      continue
    }
    let mut missing = false
    for m in members {
      let b0 = base_type(m.ctype)
      let b = match b0.split_once("[") {
        Some((pre, _)) => pre.trim().to_owned()
        None => b0
      }
      if b.has_prefix("Vk") && !defined.contains(b) {
        missing = true
      }
    }
    if missing {
      continue
    }
    generated = generated + 1
    let pguard = platform_guard(name, platforms)
    match pguard {
      Some(g) => c.write_string("#if defined(\{g})\n")
      None => ()
    }
    let mut stype = ""
    for m in members {
      if m.name == "sType" && m.stype is Some(v) {
        stype = v
      }
    }
    c.write_string(
      "MOONBIT_FFI_EXPORT void *tycho_\{name}_new(void) { \{name}* s = (\{name}*)calloc(1, sizeof(\{name})); ",
    )
    if stype != "" {
      c.write_string("s->sType = \{stype}; ")
    }
    c.write_string("return s; }\n")
    c.write_string("MOONBIT_FFI_EXPORT void tycho_\{name}_free(void *p) { tycho_release_pins(p); free(p); }\n")
    mb.write_string("///|\nextern \"c\" fn \{name}::new_ffi() -> \{name} = \"tycho_\{name}_new\"\n")
    mb.write_string("pub fn \{name}::new() -> \{name} { \{name}::new_ffi() }\n")
    mb.write_string("extern \"c\" fn \{name}::free_ffi(self : \{name}) = \"tycho_\{name}_free\"\n")
    mb.write_string("pub fn \{name}::free(self : \{name}) -> Unit { self.free_ffi() }\n")
    c.write_string(
      "MOONBIT_FFI_EXPORT void *tycho_\{name}_array(int32_t n) { \{name}* a = (\{name}*)calloc(n, sizeof(\{name})); ",
    )
    if stype != "" {
      c.write_string("for (int32_t i = 0; i < n; i++) a[i].sType = \{stype}; ")
    }
    c.write_string("return a; }\n")
    mb.write_string("extern \"c\" fn \{name}::array_ffi(n : Int32) -> \{name} = \"tycho_\{name}_array\"\n")
    mb.write_string("pub fn \{name}::array(n : Int32) -> \{name} { \{name}::array_ffi(n) }\n")
    // Pointer identity for pNext chains and for wrapping driver-returned pointers.
    // One C symbol serves every opaque type; no offsetof/ABI assumption is made.
    mb.write_string(
      "extern \"c\" fn \{name}::as_ptr_ffi(self : \{name}) -> UInt64 = \"tycho_as_ptr\"\n",
    )
    mb.write_string("pub fn \{name}::as_ptr(self : \{name}) -> UInt64 { self.as_ptr_ffi() }\n")
    mb.write_string(
      "extern \"c\" fn \{name}::from_ptr_ffi(p : UInt64) -> \{name} = \"tycho_from_ptr\"\n",
    )
    mb.write_string("pub fn \{name}::from_ptr(p : UInt64) -> \{name} { \{name}::from_ptr_ffi(p) }\n")
    for m in members {
      if m.name == "sType" || m.name == "" || m.ctype.contains_char(':') {
        continue
      }
      let base = base_type(m.ctype)
      let is_ptr = m.ctype.contains_char('*')
      // PFN typedefs already carry the '*', so they must be matched before the
      // pointer/scalar branches; the C side needs an explicit function-ptr cast.
      match fp.get(base) {
        Some(fr) => {
          emit_ptr_accessor(mb, c, name, m.name, fr, "(\{base})", pins)
          continue
        }
        None => ()
      }
      if m.is_array {
        emit_memcpy_setter(mb, c, name, m.name, "Bytes")
        let elem = match m.ctype.split_once("[") {
          Some((pre, _)) => base_type(pre.to_owned())
          None => base
        }
        if has(t.structs, elem) || has(t.unions, elem) {
          emit_array_struct_getter(mb, c, name, m.name, elem)
        } else {
          let mut ndims = 0
          for ch in m.ctype {
            if ch == '[' {
              ndims = ndims + 1
            }
          }
          emit_array_scalar_getter(mb, c, name, m.name, elem, mb_type(elem, t), ndims)
        }
      } else if (has(t.structs, base) || has(t.unions, base)) && !is_ptr {
        emit_memcpy_setter(mb, c, name, m.name, base)
        emit_nested_getter(mb, c, name, m.name, base)
      } else if is_ptr {
        emit_ptr_accessor(mb, c, name, m.name, mb_type(m.ctype, t), "", pins)
      } else if has(t.handles, base) {
        emit_ptr_accessor(mb, c, name, m.name, base, "", pins)
      } else {
        emit_scalar_accessor(mb, c, name, m.name, mb_type(m.ctype, t), base, pins)
      }
    }
    mb.write_string("\n")
    c.write_string("\n")
    match pguard {
      Some(_) => c.write_string("#endif\n")
      None => ()
    }
  }
  // Deterministic order: HashMap iteration order would break regen idempotency.
  let pin_names : Array[String] = []
  for (k, _) in pins {
    pin_names.push(k)
  }
  pin_names.sort()
  for pn in pin_names {
    c.write_string(
      "MOONBIT_FFI_EXPORT void \{pn}(void *owner, void *obj) { tycho_pin_impl(owner, obj); }\n",
    )
  }
  (mb.to_string(), c.to_string())
}