///|
fn is_int_lit(v : String) -> Bool {
  // vk.xml uses hex for composite masks (VK_SHADER_STAGE_ALL,
  // VK_STENCIL_FACE_FRONT_AND_BACK, vendor ids); rejecting them silently drops
  // those constants.
  if v.has_prefix("0x") || v.has_prefix("0X") {
    let body = v[2:].to_owned()
    if body.length() == 0 {
      return false
    }
    for c in body {
      if !((c >= '0' && c <= '9') || (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F')) {
        return false
      }
    }
    return true
  }
  let s = if v.has_prefix("-") {
    v[1:].to_owned()
  } else {
    v
  }
  if s.length() == 0 {
    return false
  }
  for c in s {
    if c < '0' || c > '9' {
      return false
    }
  }
  true
}

///|
async fn main raise {
  let args = @env.args()
  let path = if args.length() > 1 {
    args[1]
  } else {
    "codegen/registry/vk.xml"
  }
  let out_path = if args.length() > 2 {
    args[2]
  } else {
    "vulkan/enums.mbt"
  }
  let xml_text = @fs.read_text(path)
  let reader = @xml.Reader::from_string(xml_text)
  let events = reader.read_events_until_eof()
  let out = StringBuilder()
  out.write_string("// Generated from vk.xml by laplaceliu/tycho_codegen — DO NOT EDIT.\n")
  out.write_string("// Typed UInt32 constants for all enum/bitmask/extension values.\n")
  out.write_string("// (MoonBit enum constructors share the top-level namespace with consts,\n")
  out.write_string("//  so we emit plain UInt32 consts usable directly in UInt32 setters.)\n\n")
  // Typed UInt32 constants for every enum value (core + extension + bitmask) so
  // users write @vk.VK_* instead of C magic numbers. Dedup by name; skip aliases
  // and non-integer literals; negative values become two's-complement hex.
  let seen : @hashmap.HashMap[String, Unit] = @hashmap.HashMap::new()
  // vk.xml marks 64-bit enum groups with bitwidth="64"; their values must be
  // UInt64 or `1 << bitpos` silently truncates at bit 32.
  let group_width : @hashmap.HashMap[String, Int] = @hashmap.HashMap::new()
  // Resolved constant values, so alias enums (VK_DYNAMIC_STATE_CULL_MODE_EXT ->
  // ..._CULL_MODE) can be emitted too instead of silently missing.
  let values : @hashmap.HashMap[String, (String, String)] = @hashmap.HashMap::new()
  let aliases : Array[(String, String)] = []
  let mut cur_width = 32
  let mut nconst = 0
  let mut cur_ext = 0
  for ev in events {
    let elem = match ev.kind {
      @xml.EventKind::Start(e) => Some(e)
      @xml.EventKind::Empty(e) => Some(e)
      _ => None
    }
    match elem {
      Some(e) => {
        if e.name == "extension" {
          match e.get("number") {
            Some(n) => cur_ext = @string.parse_int(n)
            None => ()
          }
        }
        if e.name == "enums" {
          match e.get("name") {
            Some(gn) => {
              let w = match e.get("bitwidth") {
                Some(b) => @string.parse_int(b)
                None => 32
              }
              group_width.set(gn, w)
              cur_width = w
            }
            None => ()
          }
        }
        if e.name == "enum" && e.get("alias") is Some(al) {
          match e.get("name") {
            Some(n) =>
              if !seen.contains(n) {
                aliases.push((n, al))
              }
            None => ()
          }
        }
        if e.name == "enum" && e.get("alias") is None {
          let width = match e.get("extends") {
            Some(gn) =>
              match group_width.get(gn) {
                Some(w) => w
                None => cur_width
              }
            None => cur_width
          }
          let ty = if width == 64 { "UInt64" } else { "UInt32" }
          match (e.get("name"), e.get("value"), e.get("bitpos")) {
            (Some(n), Some(v), None) => {
              if !seen.contains(n) && is_int_lit(v) {
                seen.set(n, ())
                let lit = if v.has_prefix("-") {
                  let mag = @string.parse_int(v[1:].to_owned())
                  if width == 64 {
                    "0x" + ((0 : UInt64) - mag.to_uint64()).to_string(radix=16)
                  } else {
                    "0x" + ((0 : UInt32) - mag.reinterpret_as_uint()).to_string(radix=16)
                  }
                } else {
                  v
                }
                out.write_string("pub const \{n} : \{ty} = \{lit}\n")
                values.set(n, (ty, lit))
                nconst = nconst + 1
              }
            }
            (Some(n), None, Some(b)) => {
              if !seen.contains(n) && is_int_lit(b) {
                seen.set(n, ())
                if width == 64 {
                  let val = (1 : UInt64) << @string.parse_int(b)
                  out.write_string("pub const \{n} : UInt64 = \{val}\n")
                  values.set(n, ("UInt64", val.to_string()))
                } else {
                  let val = (1 : UInt32) << @string.parse_int(b)
                  out.write_string("pub const \{n} : UInt32 = \{val}\n")
                  values.set(n, ("UInt32", val.to_string()))
                }
                nconst = nconst + 1
              }
            }
            (Some(n), None, None) => {
              // Extension enum: value = 1000000000 + (extnumber-1)*1000 + offset.
              match e.get("offset") {
                Some(o) => {
                  // Promoted enums inside <feature> blocks carry their own
                  // extnumber; the enclosing <extension> number is absent there.
                  let extnum = match e.get("extnumber") {
                    Some(en) => @string.parse_int(en)
                    None => cur_ext
                  }
                  if !seen.contains(n) && extnum > 0 && is_int_lit(o) {
                    seen.set(n, ())
                    let off = @string.parse_int(o)
                    let base = 1000000000 + (extnum - 1) * 1000
                    let val = if e.get("dir") is Some("-") {
                      base - off
                    } else {
                      base + off
                    }
                    out.write_string("pub const \{n} : \{ty} = \{val}\n")
                    values.set(n, (ty, val.to_string()))
                    nconst = nconst + 1
                  }
                }
                None => ()
              }
            }
            _ => ()
          }
        }
      }
      None => ()
    }
  }
  // Resolve alias chains; iterate because an alias may target another alias.
  let mut pending = aliases
  let mut progress = true
  while progress && pending.length() > 0 {
    progress = false
    let next : Array[(String, String)] = []
    for (n, target) in pending {
      match values.get(target) {
        Some((ty, lit)) => {
          if !seen.contains(n) {
            seen.set(n, ())
            out.write_string("pub const \{n} : \{ty} = \{lit}\n")
            values.set(n, (ty, lit))
            nconst = nconst + 1
            progress = true
          }
        }
        None => next.push((n, target))
      }
    }
    pending = next
  }
  @fs.write_text(out_path, out.to_string())
  println("generated \{nconst} constants -> \{out_path}")
  // M1-c: commands -> handle/struct types + three-layer dispatch tables.
  let dom = build_dom(events)
  guard dom.child("registry") is Some(registry) else { return }
  let commands = parse_commands(registry)
  let types = parse_types(registry)
  let header_text = @fs.read_text(
    "vulkan/include/vulkan/vulkan_core.h",
  )
  let xlib_text = @fs.read_text(
    "vulkan/include/vulkan/vulkan_xlib.h",
  )
  let win32_text = @fs.read_text(
    "vulkan/include/vulkan/vulkan_win32.h",
  )
  let metal_text = @fs.read_text(
    "vulkan/include/vulkan/vulkan_metal.h",
  )
  let beta_text = @fs.read_text(
    "vulkan/include/vulkan/vulkan_beta.h",
  )
  let xcb_text = @fs.read_text(
    "vulkan/include/vulkan/vulkan_xcb.h",
  )
  let wayland_text = @fs.read_text(
    "vulkan/include/vulkan/vulkan_wayland.h",
  )
  for f64 in header_flags64([header_text, xlib_text, win32_text, metal_text]) {
    types.flags64.push(f64)
  }
  let defined : @hashmap.HashMap[String, Unit] = @hashmap.HashMap::new()
  for ht in [
    header_text, xlib_text, win32_text, metal_text, beta_text, xcb_text, wayland_text,
  ] {
    for tn in header_defined_types(ht) {
      defined.set(tn, ())
    }
  }
  @fs.write_text("vulkan/types.mbt", emit_types(types))
  @fs.write_text("vulkan/dispatch.mbt", emit_dispatch(commands, types))
  @fs.write_text(
    "vulkan/dispatch_stub.c",
    emit_dispatch_stub(commands, types, defined),
  )
  let struct_names : Array[String] = []
  for s in types.structs {
    struct_names.push(s)
  }
  for u in types.unions {
    struct_names.push(u)
  }
  // Platform of a type is decided by the header that declares it, not by its
  // name (e.g. VkD3D12FenceSubmitInfoKHR lives in vulkan_win32.h).
  let platforms : @hashmap.HashMap[String, String] = @hashmap.HashMap::new()
  for tn in header_defined_types(xlib_text) {
    platforms.set(tn, "VK_USE_PLATFORM_XLIB_KHR")
  }
  for tn in header_defined_types(win32_text) {
    platforms.set(tn, "VK_USE_PLATFORM_WIN32_KHR")
  }
  for tn in header_defined_types(metal_text) {
    platforms.set(tn, "VK_USE_PLATFORM_METAL_EXT")
  }
  for tn in header_defined_types(xcb_text) {
    platforms.set(tn, "VK_USE_PLATFORM_XCB_KHR")
  }
  for tn in header_defined_types(wayland_text) {
    platforms.set(tn, "VK_USE_PLATFORM_WAYLAND_KHR")
  }
  // Callback typedefs -> typed FuncRef signatures, so structs holding a PFN
  // member (debug messengers, allocation callbacks) are generatable.
  let fp_types : @hashmap.HashMap[String, String] = @hashmap.HashMap::new()
  for fp in parse_funcpointers(registry) {
    let as_cmd : VkCommand = { name: fp.name, ret: fp.ret, params: fp.params, alias_of: None }
    fp_types.set(fp.name, funcref_type(as_cmd, types))
  }
  let (mb_structs, c_structs) = emit_structs(
    registry,
    struct_names,
    types,
    defined,
    platforms,
    fp_types,
  )
  @fs.write_text("vulkan/structs.mbt", mb_structs)
  @fs.write_text("vulkan/structs_stub.c", c_structs)
  println(
    "generated dispatch: \{commands.length()} commands, \{types.handles.length()} handles; struct accessors attempted for \{struct_names.length()} types",
  )
}