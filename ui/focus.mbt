// FocusManager, FocusNode, FocusScope, and Shortcut bindings for keyboard navigation.

///|
let g_next_focus_id : Ref[Int] = Ref(1)

///|
pub struct FocusNode {
  id : Int
  focused : Signal[Bool]
  can_request_focus : Bool
  on_key : ((Int, Int) -> Bool)?
}

///|
pub fn FocusNode::new(
  can_request_focus? : Bool = true,
  on_key? : ((Int, Int) -> Bool),
) -> FocusNode {
  let id = g_next_focus_id.val
  g_next_focus_id.val = id + 1
  { id, focused: Signal::new(false), can_request_focus, on_key }
}

///|
pub fn FocusNode::is_focused(self : FocusNode, ctx : BuildContext) -> Bool {
  self.focused.get(ctx)
}

///|
pub(all) struct ShortcutBinding {
  key : Int
  mods : Int // bit 0=Shift, bit 2=Ctrl, bit 3=Alt
  action : () -> Unit
}

///|
pub struct FocusManager {
  priv nodes : Array[FocusNode]
  priv mut current_idx : Int
  priv shortcuts : Array[ShortcutBinding]
}

///|
pub fn FocusManager::new() -> FocusManager {
  { nodes: [], current_idx: -1, shortcuts: [] }
}

///|
pub fn FocusManager::register(self : FocusManager, node : FocusNode) -> Unit {
  for n in self.nodes {
    if n.id == node.id {
      return
    }
  }
  self.nodes.push(node)
}

///|
pub fn FocusManager::unregister(self : FocusManager, id : Int) -> Unit {
  let mut i = 0
  while i < self.nodes.length() {
    if self.nodes[i].id == id {
      self.nodes[i].focused.set(false)
      let _ = self.nodes.remove(i)
      if self.current_idx == i {
        self.current_idx = -1
      } else if self.current_idx > i {
        self.current_idx = self.current_idx - 1
      }
      return
    }
    i = i + 1
  }
}

///|
pub fn FocusManager::clear_all(self : FocusManager) -> Unit {
  for n in self.nodes {
    n.focused.set(false)
  }
  self.current_idx = -1
}

///|
pub fn FocusManager::request_focus(self : FocusManager, node : FocusNode) -> Unit {
  if !node.can_request_focus {
    return
  }
  self.register(node)
  let mut target_idx = -1
  for i = 0; i < self.nodes.length(); i = i + 1 {
    if self.nodes[i].id == node.id {
      target_idx = i
      self.nodes[i].focused.set(true)
    } else {
      self.nodes[i].focused.set(false)
    }
  }
  self.current_idx = target_idx
}

///|
pub fn FocusManager::unfocus(self : FocusManager) -> Unit {
  if self.current_idx >= 0 && self.current_idx < self.nodes.length() {
    self.nodes[self.current_idx].focused.set(false)
  }
  self.current_idx = -1
}

///|
pub fn FocusManager::focused_node(self : FocusManager) -> FocusNode? {
  if self.current_idx >= 0 && self.current_idx < self.nodes.length() {
    Some(self.nodes[self.current_idx])
  } else {
    None
  }
}

///|
pub fn FocusManager::next_focus(self : FocusManager) -> Unit {
  let n = self.nodes.length()
  if n == 0 {
    return
  }
  for step = 1; step <= n; step = step + 1 {
    let idx = (self.current_idx + step) % n
    if self.nodes[idx].can_request_focus {
      self.request_focus(self.nodes[idx])
      return
    }
  }
}

///|
pub fn FocusManager::prev_focus(self : FocusManager) -> Unit {
  let n = self.nodes.length()
  if n == 0 {
    return
  }
  let start = if self.current_idx < 0 { 0 } else { self.current_idx }
  for step = 1; step <= n; step = step + 1 {
    let idx = (start - step + n * 2) % n
    if self.nodes[idx].can_request_focus {
      self.request_focus(self.nodes[idx])
      return
    }
  }
}

///|
pub fn FocusManager::bind_shortcut(
  self : FocusManager,
  key : Int,
  mods : Int,
  action : () -> Unit,
) -> Unit {
  self.shortcuts.push({ key, mods, action })
}

///|
pub fn FocusManager::dispatch_key(
  self : FocusManager,
  key : Int,
  mods : Int,
) -> Bool {
  match self.focused_node() {
    Some(node) =>
      match node.on_key {
        Some(f) => if f(key, mods) { return true }
        None => ()
      }
    None => ()
  }
  for sc in self.shortcuts {
    if sc.key == key && (mods & sc.mods) == sc.mods {
      (sc.action)()
      return true
    }
  }
  false
}
