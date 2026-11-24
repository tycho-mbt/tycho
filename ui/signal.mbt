// Fine-grained reactive Signal[T] and Computed[T] with automatic Element subscription tracking.

///|
let g_next_signal_id : Ref[Int] = Ref(1)

///|
let g_current_build_elem : Ref[Int] = Ref(0)

///|
let g_signal_dirty_hook : Ref[(Int) -> Unit] = Ref(fn(_id) { () })

///|
pub fn set_signal_dirty_hook(hook : (Int) -> Unit) -> Unit {
  g_signal_dirty_hook.val = hook
}

///|
fn push_unique_elem_id(arr : Array[Int], id : Int) -> Unit {
  for x in arr {
    if x == id {
      return
    }
  }
  arr.push(id)
}

///|
pub struct Signal[T] {
  priv id : Int
  priv mut value : T
  priv subs : Array[Int]
  priv listeners : Array[() -> Unit]
}

///|
pub fn[T] Signal::new(initial : T) -> Signal[T] {
  let id = g_next_signal_id.val
  g_next_signal_id.val = id + 1
  { id, value: initial, subs: [], listeners: [] }
}

///|
pub fn[T] Signal::id(self : Signal[T]) -> Int {
  self.id
}

///|
pub fn[T] Signal::peek(self : Signal[T]) -> T {
  self.value
}

///|
pub fn[T] Signal::get(self : Signal[T], _ctx : BuildContext) -> T {
  let eid = g_current_build_elem.val
  if eid > 0 {
    push_unique_elem_id(self.subs, eid)
  }
  self.value
}

///|
pub fn[T] Signal::subscribe_element(self : Signal[T], elem_id : Int) -> Unit {
  if elem_id > 0 {
    push_unique_elem_id(self.subs, elem_id)
  }
}

///|
pub fn[T] Signal::unsubscribe_element(self : Signal[T], elem_id : Int) -> Unit {
  let mut i = 0
  while i < self.subs.length() {
    if self.subs[i] == elem_id {
      let _ = self.subs.remove(i)
    } else {
      i = i + 1
    }
  }
}

///|
pub fn[T] Signal::on_change(self : Signal[T], f : () -> Unit) -> Unit {
  self.listeners.push(f)
}

///|
pub fn[T] Signal::set(self : Signal[T], value : T) -> Unit {
  self.value = value
  for eid in self.subs {
    (g_signal_dirty_hook.val)(eid)
  }
  for f in self.listeners {
    f()
  }
}

///|
pub fn[T] Signal::update(self : Signal[T], f : (T) -> T) -> Unit {
  self.set(f(self.value))
}

///|
pub fn[T] Signal::subscriber_count(self : Signal[T]) -> Int {
  self.subs.length()
}

///|
pub struct Computed[T] {
  priv compute : (BuildContext) -> T
}

///|
pub fn[T] Computed::new(compute : (BuildContext) -> T) -> Computed[T] {
  { compute, }
}

///|
pub fn[T] Computed::get(self : Computed[T], ctx : BuildContext) -> T {
  (self.compute)(ctx)
}
