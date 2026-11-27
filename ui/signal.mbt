// Fine-grained reactive Signal[T] and Computed[T] with automatic Element subscription tracking.
//
// Subscription bookkeeping is per-Signal and per-Element: a `Signal` keeps the set of
// subscribing element ids *together with the owning tree's dirty notifier*, so no
// process-global hook is required. `Signal::get` records the read against the
// `BuildContext` it was given, and the tree stores a drop closure on the element so
// both rebuilds and unmounts can release subscriptions deterministically.

///|
let g_next_signal_id : Ref[Int] = Ref(1)

///|
priv struct SignalSub {
  elem_id : Int
  mut notify : (Int) -> Unit
}

///|
/// A cleanup handle owned by an `ElementNode`. Running `drop` removes the element
/// from the signal's subscriber list; `signal_id` lets the element diff rebuilds
/// without keeping duplicate subscriptions.
pub struct SignalAttachment {
  priv signal_id : Int
  priv drop : () -> Unit
}

///|
pub fn SignalAttachment::signal_id(self : SignalAttachment) -> Int {
  self.signal_id
}

///|
pub struct Signal[T] {
  priv id : Int
  priv mut value : T
  priv subs : Array[SignalSub]
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
/// Reads the value and registers a dependency on the element described by `ctx`.
/// The subscription is tracked by the owning `UiTree`, which releases it when the
/// element is rebuilt without reading the signal or when the element unmounts.
pub fn[T] Signal::get(self : Signal[T], ctx : BuildContext) -> T {
  ctx.track(self)
  self.value
}

///|
pub fn[T] Signal::subscribe_element(
  self : Signal[T],
  elem_id : Int,
  notify : (Int) -> Unit,
) -> Unit {
  if elem_id <= 0 {
    return
  }
  for sub in self.subs {
    if sub.elem_id == elem_id {
      sub.notify = notify
      return
    }
  }
  self.subs.push({ elem_id, notify })
}

///|
pub fn[T] Signal::unsubscribe_element(self : Signal[T], elem_id : Int) -> Unit {
  let mut i = 0
  while i < self.subs.length() {
    if self.subs[i].elem_id == elem_id {
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
  for sub in self.subs {
    let notify = sub.notify
    notify(sub.elem_id)
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
