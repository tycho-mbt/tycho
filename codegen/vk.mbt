///|
// Minimal DOM built from the XML pull-parser event stream, for navigating vk.xml.
pub struct XmlNode {
  name : String
  attrs : Array[(String, String)]
  children : Array[XmlNode]
  text : String
}

///|
fn elem_attrs(elem : @xml.XmlElement) -> Array[(String, String)] {
  let out : Array[(String, String)] = []
  for a in elem.attributes {
    out.push((a.name, a.value))
  }
  out
}

///|
pub fn build_dom(events : Array[@xml.Event]) -> XmlNode {
  let root : XmlNode = { name: "#root", attrs: [], children: [], text: "" }
  let stack : Array[XmlNode] = [root]
  for ev in events {
    let top = stack[stack.length() - 1]
    match ev.kind {
      @xml.EventKind::Start(elem) => {
        let n : XmlNode = { name: elem.name, attrs: elem_attrs(elem), children: [], text: "" }
        top.children.push(n)
        stack.push(n)
      }
      @xml.EventKind::Empty(elem) => {
        let n : XmlNode = { name: elem.name, attrs: elem_attrs(elem), children: [], text: "" }
        top.children.push(n)
      }
      @xml.EventKind::Text(t) => {
        top.children.push({ name: "#text", attrs: [], children: [], text: t })
      }
      @xml.EventKind::End(_) => ignore(stack.pop())
      _ => ()
    }
  }
  root
}

///|
pub fn XmlNode::child(self : XmlNode, name : String) -> XmlNode? {
  for c in self.children {
    if c.name == name {
      return Some(c)
    }
  }
  None
}

///|
pub fn XmlNode::attr(self : XmlNode, name : String) -> String? {
  for (k, v) in self.attrs {
    if k == name {
      return Some(v)
    }
  }
  None
}

///|
pub fn XmlNode::inner_text(self : XmlNode) -> String {
  let sb = StringBuilder()
  for c in self.children {
    if c.name == "#text" {
      sb.write_string(c.text)
    } else {
      sb.write_string(c.inner_text())
    }
  }
  sb.to_string()
}

///|
pub struct VkParam {
  ctype : String
  name : String
}

///|
pub struct VkCommand {
  name : String
  ret : String
  params : Array[VkParam]
  alias_of : String?
}

///|
fn param_ctype(p : XmlNode) -> String {
  let sb = StringBuilder()
  for c in p.children {
    if c.name == "name" {
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
pub fn parse_commands(registry : XmlNode) -> Array[VkCommand] {
  let out : Array[VkCommand] = []
  let seen : Array[String] = []
  guard registry.child("commands") is Some(cmds) else { return out }
  for c in cmds.children {
    if c.name != "command" {
      continue
    }
    if c.attr("alias") is Some(al) {
      let nm = c.attr("name").unwrap()
      if !has_name(seen, nm) {
        seen.push(nm)
        out.push({ name: nm, ret: "", params: [], alias_of: Some(al) })
      }
      continue
    }
    guard c.child("proto") is Some(proto) else { continue }
    guard proto.child("name") is Some(pname) else { continue }
    let nm = pname.inner_text().trim().to_owned()
    if has_name(seen, nm) {
      continue
    }
    seen.push(nm)
    let ret = match proto.child("type") {
      Some(t) => t.inner_text().trim().to_owned()
      None => "void"
    }
    let params : Array[VkParam] = []
    let pseen : Array[String] = []
    for p in c.children {
      if p.name != "param" {
        continue
      }
      let pn = match p.child("name") {
        Some(n) => n.inner_text().trim().to_owned()
        None => ""
      }
      if pn == "" || has_name(pseen, pn) {
        continue
      }
      pseen.push(pn)
      params.push({ ctype: param_ctype(p), name: pn })
    }
    out.push({ name: nm, ret, params, alias_of: None })
  }
  out
}

///|
fn has_name(arr : Array[String], x : String) -> Bool {
  for a in arr {
    if a == x {
      return true
    }
  }
  false
}

///|
pub fn base_type(ctype : String) -> String {
  let s = ctype.trim().to_owned()
  let s = s.replace_all(old="const", new="")
  let s = s.replace_all(old="*", new="")
  // Self-referential members are written `struct VkBaseOutStructure* pNext`;
  // the elaborated type specifier must go or the Vk prefix test fails.
  let s = s.replace_all(old="struct", new="")
  let s = s.replace_all(old="union", new="")
  // Array suffix: `const float blendConstants[4]` is a decayed pointer param,
  // and the element type is what decides the MoonBit mapping.
  let s = match s.split_once("[") {
    Some((pre, _)) => pre
    None => s
  }
  s.trim().to_owned()
}

///|
pub enum DispatchLevel {
  Entry
  Instance
  Device
}

///|
pub fn classify(cmd : VkCommand) -> DispatchLevel {
  if cmd.name == "vkGetInstanceProcAddr" {
    return Entry
  }
  if cmd.name == "vkGetDeviceProcAddr" {
    return Instance
  }
  if cmd.params.length() == 0 {
    return Entry
  }
  let first = base_type(cmd.params[0].ctype)
  match first {
    "VkInstance" | "VkPhysicalDevice" => Instance
    "VkDevice" | "VkQueue" | "VkCommandBuffer" => Device
    _ => Entry
  }
}

///|
pub struct VkFuncPointer {
  name : String
  ret : String
  params : Array[VkParam]
}

///|
// Callback typedefs (<type category="funcpointer">). Without these, any struct
// holding a PFN member is skipped wholesale — including the debug messengers.
pub fn parse_funcpointers(registry : XmlNode) -> Array[VkFuncPointer] {
  let out : Array[VkFuncPointer] = []
  guard registry.child("types") is Some(types) else { return out }
  for ty in types.children {
    if ty.name != "type" {
      continue
    }
    match ty.attr("category") {
      Some("funcpointer") => ()
      _ => continue
    }
    guard ty.child("proto") is Some(proto) else { continue }
    guard proto.child("name") is Some(pname) else { continue }
    let nm = pname.inner_text().trim().to_owned()
    let ret = match proto.child("type") {
      Some(t) => t.inner_text().trim().to_owned()
      None => "void"
    }
    let params : Array[VkParam] = []
    for p in ty.children {
      if p.name != "param" {
        continue
      }
      let pn = match p.child("name") {
        Some(n) => n.inner_text().trim().to_owned()
        None => ""
      }
      if pn == "" {
        continue
      }
      params.push({ ctype: param_ctype(p), name: pn })
    }
    out.push({ name: nm, ret, params })
  }
  out
}

///|
pub struct VkTypes {
  handles : Array[String]
  structs : Array[String]
  unions : Array[String]
  enums : Array[String]
  bitmasks : Array[String]
  flags64 : Array[String]
}

///|
// Types whose C ABI is 64-bit. vk.xml declares them as `typedef VkFlags64 X;`
// (VkFlags64 = uint64_t); aliases chain from there. Mapping these to UInt32
// would silently truncate the high half of every sync2 stage/access mask.
pub fn header_flags64(texts : Array[String]) -> Array[String] {
  let aliases : Array[(String, String)] = []
  for text in texts {
    for line in text.split("\n") {
      let l = line.trim().to_owned()
      if !l.has_prefix("typedef") || !l.has_suffix(";") {
        continue
      }
      let body = l.substring(start=0, end=l.length() - 1)
      let toks : Array[String] = []
      for tok in body.split(" ") {
        let t = tok.trim().to_owned()
        if t != "" {
          toks.push(t)
        }
      }
      if toks.length() == 3 {
        aliases.push((toks[1], toks[2]))
      }
    }
  }
  let set : @hashmap.HashMap[String, Unit] = @hashmap.HashMap::new()
  set.set("uint64_t", ())
  let mut changed = true
  while changed {
    changed = false
    for (src, dst) in aliases {
      if set.contains(src) && !set.contains(dst) {
        set.set(dst, ())
        changed = true
      }
    }
  }
  let out : Array[String] = []
  for (k, _) in set {
    if k != "uint64_t" {
      out.push(k)
    }
  }
  out
}

///|
pub fn parse_types(registry : XmlNode) -> VkTypes {
  let t : VkTypes = {
    handles: [],
    structs: [],
    unions: [],
    enums: [],
    bitmasks: [],
    flags64: [],
  }
  guard registry.child("types") is Some(types) else { return t }
  for ty in types.children {
    if ty.name != "type" {
      continue
    }
    let name = match ty.attr("name") {
      Some(n) => n
      None =>
        match ty.child("name") {
          Some(n) => n.inner_text().trim().to_owned()
          None => ""
        }
    }
    if name == "" {
      continue
    }
    match ty.attr("category") {
      Some("handle") => t.handles.push(name)
      Some("struct") => t.structs.push(name)
      Some("union") => t.unions.push(name)
      Some("enum") => t.enums.push(name)
      Some("bitmask") => t.bitmasks.push(name)
      _ => ()
    }
  }
  t
}