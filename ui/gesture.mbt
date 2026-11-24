// Hit-testing entries, pointer events, hover tracking, and GestureArena (tap vs drag disambiguation).

///|
pub(all) enum PointerEvent {
  Down(Int, @g2d.Point, Int)      // pointer_id, logical_pos, button
  Move(Int, @g2d.Point)
  Up(Int, @g2d.Point, Int)
  Scroll(@g2d.Point, Float, Float) // logical_pos, dx, dy
}

///|
pub(all) struct KeyEvent {
  key : Int
  mods : Int
  pressed : Bool
}

///|
pub(all) struct GestureCallbacks {
  on_tap : (() -> Unit)?
  on_drag_start : ((@g2d.Point) -> Unit)?
  on_drag_update : ((@g2d.Point, @g2d.Point) -> Unit)? // pos, delta
  on_drag_end : (() -> Unit)?
  on_scroll : ((Float, Float) -> Unit)?
  on_mouse_enter : (() -> Unit)?
  on_mouse_exit : (() -> Unit)?
  on_hover : ((@g2d.Point) -> Unit)?
}

///|
pub fn GestureCallbacks::empty() -> GestureCallbacks {
  {
    on_tap: None,
    on_drag_start: None,
    on_drag_update: None,
    on_drag_end: None,
    on_scroll: None,
    on_mouse_enter: None,
    on_mouse_exit: None,
    on_hover: None,
  }
}

///|
pub(all) struct HitTestEntry {
  node_id : Int
  local_pos : @g2d.Point
  callbacks : GestureCallbacks
}

///|
const K_TOUCH_SLOP : Float = (6.0 : Float)

///|
#derive(Eq, Debug)
pub(all) enum ArenaWinner {
  Undecided
  Tap
  Drag
  Cancelled
}

///|
pub struct GestureArena {
  priv mut active_pointer : Int
  priv mut down_pos : @g2d.Point
  priv mut last_pos : @g2d.Point
  priv mut winner : ArenaWinner
  priv mut tap_target : GestureCallbacks?
  priv mut drag_target : GestureCallbacks?
  priv mut hovered_ids : Array[Int]
  priv mut hovered_cbs : Array[GestureCallbacks]
}

///|
pub fn GestureArena::new() -> GestureArena {
  {
    active_pointer: -1,
    down_pos: @g2d.Point::zero(),
    last_pos: @g2d.Point::zero(),
    winner: ArenaWinner::Undecided,
    tap_target: None,
    drag_target: None,
    hovered_ids: [],
    hovered_cbs: [],
  }
}

///|
pub fn GestureArena::winner(self : GestureArena) -> ArenaWinner {
  self.winner
}

///|
pub fn GestureArena::update_hover(
  self : GestureArena,
  hits : Array[HitTestEntry],
) -> Unit {
  let new_ids : Array[Int] = []
  let new_cbs : Array[GestureCallbacks] = []
  for h in hits {
    new_ids.push(h.node_id)
    new_cbs.push(h.callbacks)
  }
  // Exit callbacks for previously hovered nodes no longer hit
  for i = 0; i < self.hovered_ids.length(); i = i + 1 {
    let old_id = self.hovered_ids[i]
    let mut still_in = false
    for nid in new_ids {
      if nid == old_id {
        still_in = true
        break
      }
    }
    if !still_in {
      match self.hovered_cbs[i].on_mouse_exit {
        Some(f) => f()
        None => ()
      }
    }
  }
  // Enter & hover callbacks
  for h in hits {
    let mut was_in = false
    for old_id in self.hovered_ids {
      if old_id == h.node_id {
        was_in = true
        break
      }
    }
    if !was_in {
      match h.callbacks.on_mouse_enter {
        Some(f) => f()
        None => ()
      }
    }
    match h.callbacks.on_hover {
      Some(f) => f(h.local_pos)
      None => ()
    }
  }
  self.hovered_ids = new_ids
  self.hovered_cbs = new_cbs
}

///|
pub fn GestureArena::handle_down(
  self : GestureArena,
  pointer : Int,
  pos : @g2d.Point,
  hits : Array[HitTestEntry],
) -> Unit {
  self.active_pointer = pointer
  self.down_pos = pos
  self.last_pos = pos
  self.winner = ArenaWinner::Undecided
  self.tap_target = None
  self.drag_target = None
  for h in hits {
    if self.tap_target is None && h.callbacks.on_tap is Some(_) {
      self.tap_target = Some(h.callbacks)
    }
    if self.drag_target is None &&
      (h.callbacks.on_drag_start is Some(_) || h.callbacks.on_drag_update is Some(_)) {
      self.drag_target = Some(h.callbacks)
    }
  }
  if self.drag_target is None && self.tap_target is Some(_) {
    self.winner = ArenaWinner::Tap
  } else if self.tap_target is None && self.drag_target is Some(_) {
    self.winner = ArenaWinner::Drag
    match self.drag_target {
      Some(cb) =>
        match cb.on_drag_start {
          Some(f) => f(pos)
          None => ()
        }
      None => ()
    }
  }
}

///|
pub fn GestureArena::handle_move(
  self : GestureArena,
  pointer : Int,
  pos : @g2d.Point,
) -> Unit {
  if self.active_pointer != pointer {
    return
  }
  let dist = pos.distance_to(self.down_pos)
  if self.winner == ArenaWinner::Undecided && dist > K_TOUCH_SLOP {
    match self.drag_target {
      Some(cb) => {
        self.winner = ArenaWinner::Drag
        match cb.on_drag_start {
          Some(f) => f(self.down_pos)
          None => ()
        }
      }
      None => self.winner = ArenaWinner::Cancelled
    }
  } else if self.winner == ArenaWinner::Tap && dist > K_TOUCH_SLOP * (2.5 : Float) {
    self.winner = ArenaWinner::Cancelled
  }
  if self.winner == ArenaWinner::Drag {
    let delta = pos.sub(self.last_pos)
    match self.drag_target {
      Some(cb) =>
        match cb.on_drag_update {
          Some(f) => f(pos, delta)
          None => ()
        }
      None => ()
    }
  }
  self.last_pos = pos
}

///|
pub fn GestureArena::handle_up(
  self : GestureArena,
  pointer : Int,
  _pos : @g2d.Point,
  still_inside_tap : Bool,
) -> Unit {
  if self.active_pointer != pointer {
    return
  }
  match self.winner {
    Undecided | Tap =>
      if still_inside_tap {
        self.winner = ArenaWinner::Tap
        match self.tap_target {
          Some(cb) =>
            match cb.on_tap {
              Some(f) => f()
              None => ()
            }
          None => ()
        }
      } else {
        self.winner = ArenaWinner::Cancelled
      }
    Drag =>
      match self.drag_target {
        Some(cb) =>
          match cb.on_drag_end {
            Some(f) => f()
            None => ()
          }
        None => ()
      }
    Cancelled => ()
  }
  self.active_pointer = -1
}

///|
pub fn GestureArena::handle_scroll(
  _self : GestureArena,
  hits : Array[HitTestEntry],
  dx : Float,
  dy : Float,
) -> Unit {
  for h in hits {
    match h.callbacks.on_scroll {
      Some(f) => {
        f(dx, dy)
        return
      }
      None => ()
    }
  }
}
