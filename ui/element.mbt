// Element reconciliation tree: key-based child Diff, Signal dirty tracking,
// depth-sorted rebuilds, Theme propagation, and virtualized ListView child materialization.

///|
pub struct ElementNode {
  priv id : Int
  priv mut depth : Int
  priv mut parent : ElementNode?
  priv mut widget : Widget
  priv mut dirty : Bool
  priv mut theme : ThemeData
  priv children : Array[ElementNode]
  priv render : RenderNode?
  // Live signal subscriptions owned by this element; dropped on unmount and on
  // rebuild when the element no longer reads the signal.
  priv subs : Array[SignalAttachment]
  // Signal ids read during the current build pass (used to prune stale subs).
  priv build_marks : Array[Int]
  // ListView virtualization window cache
  priv mut list_first : Int
  priv mut list_last : Int
}

///|
pub struct UiTree {
  priv mut root : ElementNode?
  priv by_id : Map[Int, ElementNode]
  priv dirty_ids : Array[Int]
  priv mut next_elem_id : Int
  priv default_theme : ThemeData
  priv active_text_controllers : Array[TextController]
  focus : FocusManager
}

///|
pub fn UiTree::new(theme? : ThemeData = ThemeData::dark()) -> UiTree {
  {
    root: None,
    by_id: {},
    dirty_ids: [],
    next_elem_id: 1,
    default_theme: theme,
    active_text_controllers: [],
    focus: FocusManager::new(),
  }
}

///|
fn UiTree::alloc_elem_id(self : UiTree) -> Int {
  let id = self.next_elem_id
  self.next_elem_id = id + 1
  id
}

///|
pub fn UiTree::mark_dirty(self : UiTree, elem_id : Int) -> Unit {
  match self.by_id.get(elem_id) {
    Some(e) =>
      if !e.dirty {
        e.dirty = true
        self.dirty_ids.push(elem_id)
      }
    None => ()
  }
}

///|
pub fn UiTree::has_dirty(self : UiTree) -> Bool {
  self.dirty_ids.length() > 0
}

///|
pub fn UiTree::element_count(self : UiTree) -> Int {
  self.by_id.length()
}

///|
pub fn UiTree::render_count(self : UiTree) -> Int {
  match self.render_root() {
    Some(r) => r.count_nodes()
    None => 0
  }
}

///|
pub fn UiTree::render_root(self : UiTree) -> RenderNode? {
  match self.root {
    Some(r) => find_descendant_render(r)
    None => None
  }
}

///|
fn find_descendant_render(e : ElementNode) -> RenderNode? {
  match e.render {
    Some(rn) => Some(rn)
    None =>
      if e.children.length() > 0 {
        find_descendant_render(e.children[0])
      } else {
        None
      }
  }
}

///|
fn collect_descendant_renders(e : ElementNode, out : Array[RenderNode]) -> Unit {
  match e.render {
    Some(rn) => out.push(rn)
    None =>
      for c in e.children {
        collect_descendant_renders(c, out)
      }
  }
}

///|
fn widget_to_render_kind(kind : WidgetKind, theme : ThemeData) -> RenderKind? {
  match kind {
    Builder(_, _) | ThemeProvider(_, _) => None
    SizedBox(w, h, _) => Some(RenderKind::Box(w, h))
    Padding(ins, _) => Some(RenderKind::Padding(ins))
    Align(al, _) => Some(RenderKind::Align(al))
    ConstrainedBox(bc, _) => Some(RenderKind::Constrained(bc))
    DecoratedBox(dp, _) => Some(RenderKind::Decorated(dp))
    Flex(ax, ma, ca, ms, gap, _) => Some(RenderKind::Flex(ax, ma, ca, ms, gap))
    Expanded(fl, fit, _) => Some(RenderKind::FlexChild(fl, fit))
    Stack(al, _) => Some(RenderKind::Stack(al))
    Positioned(l, t, r, b, w, h, _) => Some(RenderKind::Positioned(l, t, r, b, w, h))
    Wrap(sp, rsp, _) => Some(RenderKind::Wrap(sp, rsp))
    ClipRect(_) => Some(RenderKind::ClipRect)
    ClipRRect(rad, _) => Some(RenderKind::ClipRRect(rad))
    Opacity(a, _) => Some(RenderKind::Opacity(a))
    Transform(m, _) => Some(RenderKind::Transform(m))
    BackdropFilter(s, rad, tint, _) => Some(RenderKind::BackdropFilter(s, rad, tint))
    RepaintBoundary(_) => Some(RenderKind::RepaintBoundary)
    TextNode(txt, st, al, ml, el) => Some(RenderKind::Text(txt, st, al, ml, el))
    ImageNode(img, w, h) => Some(RenderKind::Image(img, w, h))
    CustomPaint(sz, pf) => Some(RenderKind::CustomPaint(sz, pf))
    GestureNode(cbs, _) => Some(RenderKind::Gesture(cbs))
    ListViewBuilder(cnt, ext, ctrl, _) => Some(RenderKind::ListView(cnt, ext, ctrl))
    ScrollViewportNode(ctrl, ax, _) => Some(RenderKind::ScrollViewport(ctrl, ax))
    TextFieldNode(ctrl, ph, w, fs) => Some(RenderKind::TextField(ctrl, ph, w, fs, theme))
  }
}

///|
fn widget_static_children(kind : WidgetKind) -> Array[Widget] {
  match kind {
    ThemeProvider(_, c)
    | Padding(_, c)
    | Align(_, c)
    | ConstrainedBox(_, c)
    | Expanded(_, _, c)
    | Positioned(_, _, _, _, _, _, c)
    | ClipRect(c)
    | ClipRRect(_, c)
    | Opacity(_, c)
    | Transform(_, c)
    | BackdropFilter(_, _, _, c)
    | RepaintBoundary(c)
    | GestureNode(_, c)
    | ScrollViewportNode(_, _, c) => [c]
    SizedBox(_, _, co) | DecoratedBox(_, co) =>
      match co {
        Some(c) => [c]
        None => []
      }
    Flex(_, _, _, _, _, cs) | Stack(_, cs) | Wrap(_, _, cs) => cs
    _ => []
  }
}

///|
fn contains_int(arr : Array[Int], v : Int) -> Bool {
  for x in arr {
    if x == v {
      return true
    }
  }
  false
}

///|
fn find_attachment(subs : Array[SignalAttachment], signal_id : Int) -> Bool {
  for s in subs {
    if s.signal_id() == signal_id {
      return true
    }
  }
  false
}

///|
/// Registers `sig` as a dependency of `elem_id`, storing a drop handle on the
/// element so the subscription is released deterministically.
fn[T] UiTree::attach_signal(
  self : UiTree,
  e : ElementNode,
  sig : Signal[T],
) -> Unit {
  let sid = sig.id()
  if find_attachment(e.subs, sid) {
    return
  }
  let elem_id = e.id
  sig.subscribe_element(elem_id, fn(dirty_id) { self.mark_dirty(dirty_id) })
  e.subs.push({
    signal_id: sid,
    drop: fn() { sig.unsubscribe_element(elem_id) },
  })
}

///|
pub fn[T] BuildContext::track(self : BuildContext, sig : Signal[T]) -> Unit {
  match self.tree {
    Some(tree) => tree.track_signal(self.elem_id, sig)
    None => ()
  }
}

///|
/// Records a `Signal::get` read during the build of `elem_id`. The read is
/// remembered in `build_marks` so stale dependencies can be pruned once the
/// build finishes.
fn[T] UiTree::track_signal(
  self : UiTree,
  elem_id : Int,
  sig : Signal[T],
) -> Unit {
  match self.by_id.get(elem_id) {
    Some(e) => {
      let sid = sig.id()
      if !contains_int(e.build_marks, sid) {
        e.build_marks.push(sid)
      }
      self.attach_signal(e, sig)
    }
    None => ()
  }
}

///|
/// Drops subscriptions that were not read during the last build of `e`.
fn prune_signals(e : ElementNode) -> Unit {
  let kept : Array[SignalAttachment] = []
  for sub in e.subs {
    if contains_int(e.build_marks, sub.signal_id()) {
      kept.push(sub)
    } else {
      (sub.drop)()
    }
  }
  e.subs.clear()
  for sub in kept {
    e.subs.push(sub)
  }
  e.build_marks.clear()
}

///|
fn UiTree::unmount_node(self : UiTree, e : ElementNode) -> Unit {
  let _ = self.by_id.remove(e.id)
  for sub in e.subs {
    (sub.drop)()
  }
  e.subs.clear()
  e.build_marks.clear()
  match e.widget.kind {
    TextFieldNode(ctrl, _, _, _) => self.remove_text_controller(ctrl)
    _ => ()
  }
  for ch in e.children {
    self.unmount_node(ch)
  }
  e.children.clear()
}

///|
fn UiTree::remove_text_controller(self : UiTree, ctrl : TextController) -> Unit {
  let kept : Array[TextController] = []
  let key = ctrl.text.id()
  for tc in self.active_text_controllers {
    if tc.text.id() != key {
      kept.push(tc)
    }
  }
  self.active_text_controllers.clear()
  for tc in kept {
    self.active_text_controllers.push(tc)
  }
}

///|
fn can_update(old_w : Widget, new_w : Widget) -> Bool {
  old_w.key == new_w.key && old_w.kind.tag() == new_w.kind.tag()
}

///|
fn UiTree::reconcile_children(
  self : UiTree,
  parent : ElementNode,
  new_widgets : Array[Widget],
  child_theme : ThemeData,
) -> Unit {
  let old_children : Array[ElementNode] = []
  for oc in parent.children {
    old_children.push(oc)
  }
  parent.children.clear()
  let used = Array::make(old_children.length(), false)

  for i = 0; i < new_widgets.length(); i = i + 1 {
    let nw = new_widgets[i]
    let mut matched : ElementNode? = None
    // First try matching by Key anywhere among unused old children
    match nw.key {
      Some(_) =>
        for oi = 0; oi < old_children.length(); oi = oi + 1 {
          if !used[oi] && can_update(old_children[oi].widget, nw) {
            used[oi] = true
            matched = Some(old_children[oi])
            break
          }
        }
      None =>
        // Positional match when unkeyed
        if i < old_children.length() && !used[i] && can_update(old_children[i].widget, nw) {
          used[i] = true
          matched = Some(old_children[i])
        }
    }
    match matched {
      Some(existing) => {
        existing.parent = Some(parent)
        self.update_element(existing, nw, child_theme, parent.depth + 1)
        parent.children.push(existing)
      }
      None => {
        let mounted = self.mount_element(nw, child_theme, parent.depth + 1, Some(parent))
        parent.children.push(mounted)
      }
    }
  }
  for oi = 0; oi < old_children.length(); oi = oi + 1 {
    if !used[oi] {
      self.unmount_node(old_children[oi])
    }
  }
}

///|
fn compute_list_window(
  count : Int,
  extent : Float,
  ctrl : ScrollController,
) -> (Int, Int) {
  if count <= 0 || extent <= (0.0 : Float) {
    return (0, 0)
  }
  let vh = if ctrl.viewport_extent > (0.0 : Float) {
    ctrl.viewport_extent
  } else {
    (400.0 : Float)
  }
  let sy = ctrl.offset.peek()
  let first_raw = (sy / extent).floor().to_int() - 2
  let last_raw = ((sy + vh) / extent).ceil().to_int() + 2
  let first = if first_raw < 0 { 0 } else { first_raw }
  let last = if last_raw > count { count } else { last_raw }
  (first, if last < first { first } else { last })
}

///|
fn propagate_render_dirty(start : ElementNode) -> Unit {
  let mut cur : ElementNode? = Some(start)
  while true {
    match cur {
      Some(node) => {
        match node.render {
          Some(rn) => {
            rn.needs_layout = true
            rn.needs_paint = true
            rn.cached_dl = None
          }
          None => ()
        }
        cur = node.parent
      }
      None => break
    }
  }
}

///|
fn sync_nearest_ancestor_render(start : ElementNode) -> Unit {
  let mut cur = start.parent
  while true {
    match cur {
      Some(node) => {
        match node.render {
          Some(rn) => {
            rn.children.clear()
            for ch in node.children {
              collect_descendant_renders(ch, rn.children)
            }
            propagate_render_dirty(node)
            return
          }
          None => ()
        }
        cur = node.parent
      }
      None => return
    }
  }
}

///|
fn UiTree::rebuild_element(self : UiTree, e : ElementNode) -> Unit {
  e.dirty = false
  match e.widget.kind {
    Builder(_, build_fn) => {
      e.build_marks.clear()
      let ctx : BuildContext = { elem_id: e.id, theme_ref: e.theme, tree: Some(self) }
      let built = build_fn(ctx)
      prune_signals(e)
      self.reconcile_children(e, [built], e.theme)
    }
    ThemeProvider(new_theme, child) => self.reconcile_children(e, [child], new_theme)
    ListViewBuilder(count, extent, ctrl, item_builder) => {
      self.attach_signal(e, ctrl.offset)
      let (first, last) = compute_list_window(count, extent, ctrl)
      e.list_first = first
      e.list_last = last
      let item_widgets : Array[Widget] = []
      let indices : Array[Int] = []
      let ctx : BuildContext = { elem_id: e.id, theme_ref: e.theme, tree: Some(self) }
      for idx = first; idx < last; idx = idx + 1 {
        let iw = item_builder(ctx, idx)
        item_widgets.push({ key: Some(Key::IntKey(idx)), kind: iw.kind })
        indices.push(idx)
      }
      self.reconcile_children(e, item_widgets, e.theme)
      match e.render {
        Some(rn) => {
          rn.list_indices.clear()
          for idx in indices {
            rn.list_indices.push(idx)
          }
        }
        None => ()
      }
    }
    _ => self.reconcile_children(e, widget_static_children(e.widget.kind), e.theme)
  }
  match e.render {
    Some(rn) => {
      rn.children.clear()
      for ch in e.children {
        collect_descendant_renders(ch, rn.children)
      }
      propagate_render_dirty(e)
    }
    None => sync_nearest_ancestor_render(e)
  }
}

///|
fn UiTree::mount_element(
  self : UiTree,
  w : Widget,
  theme : ThemeData,
  depth : Int,
  parent : ElementNode?,
) -> ElementNode {
  let id = self.alloc_elem_id()
  let rn = match widget_to_render_kind(w.kind, theme) {
    Some(rk) => Some(RenderNode::new(id, rk))
    None => None
  }
  let node : ElementNode = {
    id,
    depth,
    parent,
    widget: w,
    dirty: false,
    theme,
    children: [],
    render: rn,
    subs: [],
    build_marks: [],
    list_first: 0,
    list_last: 0,
  }
  self.by_id[id] = node
  match w.kind {
    TextFieldNode(ctrl, _, _, _) => {
      self.attach_signal(node, ctrl.text)
      self.attach_signal(node, ctrl.cursor)
      self.attach_signal(node, ctrl.focused)
      self.active_text_controllers.push(ctrl)
    }
    ScrollViewportNode(ctrl, _, _) => self.attach_signal(node, ctrl.offset)
    _ => ()
  }
  self.rebuild_element(node)
  node
}

///|
fn UiTree::update_element(
  self : UiTree,
  e : ElementNode,
  new_w : Widget,
  theme : ThemeData,
  depth : Int,
) -> Unit {
  e.depth = depth
  e.theme = theme
  e.widget = new_w
  match (e.render, widget_to_render_kind(new_w.kind, theme)) {
    (Some(rn), Some(rk)) => {
      rn.kind = rk
      rn.needs_layout = true
      rn.needs_paint = true
      rn.cached_dl = None
    }
    _ => ()
  }
  self.rebuild_element(e)
}

///|
pub fn UiTree::mount_root(self : UiTree, w : Widget) -> Unit {
  match self.root {
    Some(old) => self.unmount_node(old)
    None => ()
  }
  self.root = None
  self.by_id.clear()
  self.dirty_ids.clear()
  self.active_text_controllers.clear()
  let r = self.mount_element(w, self.default_theme, 0, None)
  self.root = Some(r)
}

///|
pub fn UiTree::flush_builds(self : UiTree) -> Unit {
  while self.dirty_ids.length() > 0 {
    let batch : Array[ElementNode] = []
    for id in self.dirty_ids {
      match self.by_id.get(id) {
        Some(e) => if e.dirty { batch.push(e) }
        None => ()
      }
    }
    self.dirty_ids.clear()
    // Build shallowest elements first so parent rebuilds coalesce dirty children cleanly
    batch.sort_by(fn(a, b) { a.depth - b.depth })
    for e in batch {
      if e.dirty {
        self.rebuild_element(e)
      }
    }
  }
}

///|
pub fn UiTree::sync_list_viewports(self : UiTree) -> Bool {
  let mut changed = false
  self.by_id.each(fn(_id, e) {
    match e.widget.kind {
      ListViewBuilder(count, extent, ctrl, _) => {
        let (f, l) = compute_list_window(count, extent, ctrl)
        if f != e.list_first || l != e.list_last {
          self.mark_dirty(e.id)
          changed = true
        }
      }
      _ => ()
    }
  })
  changed
}

///|
pub fn UiTree::layout_root(self : UiTree, width : Float, height : Float) -> Unit {
  match self.render_root() {
    Some(r) => {
      let _ = r.layout(BoxConstraints::tight(@g2d.Size::new(width, height)))
    }
    None => ()
  }
}

///|
pub fn UiTree::build_display_list(self : UiTree) -> @g2d.DisplayList {
  match self.render_root() {
    Some(r) => r.build_layer().to_display_list()
    None => @g2d.Canvas::new().finish()
  }
}

///|
pub fn UiTree::hit_test(self : UiTree, pos : @g2d.Point) -> Array[HitTestEntry] {
  let out : Array[HitTestEntry] = []
  match self.render_root() {
    Some(r) => {
      let _ = r.hit_test(pos, out)
    }
    None => ()
  }
  out
}

///|
pub fn UiTree::focused_text_controller(self : UiTree) -> TextController? {
  for tc in self.active_text_controllers {
    if tc.focused.peek() {
      return Some(tc)
    }
  }
  None
}

///|
pub fn UiTree::clear_text_focus_except(
  self : UiTree,
  keep : TextController?,
) -> Unit {
  for tc in self.active_text_controllers {
    let stay = match keep {
      Some(k) => tc.text.id() == k.text.id()
      None => false
    }
    if !stay && tc.focused.peek() {
      tc.focused.set(false)
    }
  }
}

///|
pub fn UiTree::cycle_text_focus(self : UiTree, reverse : Bool) -> Unit {
  let n = self.active_text_controllers.length()
  if n == 0 {
    if reverse {
      self.focus.prev_focus()
    } else {
      self.focus.next_focus()
    }
    return
  }
  let mut cur = -1
  for i = 0; i < n; i = i + 1 {
    if self.active_text_controllers[i].focused.peek() {
      cur = i
      break
    }
  }
  let next = if cur < 0 {
    if reverse { n - 1 } else { 0 }
  } else if reverse {
    (cur - 1 + n) % n
  } else {
    (cur + 1) % n
  }
  let target = self.active_text_controllers[next]
  self.clear_text_focus_except(Some(target))
  target.focused.set(true)
  target.blink_phase = 0.0
}

///|
pub fn UiTree::has_pending_dirty(self : UiTree) -> Bool {
  if self.dirty_ids.length() > 0 {
    return true
  }
  match self.root {
    Some(r) =>
      match r.render {
        Some(rn) => rn.needs_layout || rn.needs_paint
        None => false
      }
    None => false
  }
}

///|
pub fn UiTree::build_semantics_tree(self : UiTree) -> SemanticsNode? {
  match self.root {
    Some(r) => {
      let renders : Array[RenderNode] = []
      match r.render {
        Some(rn) => renders.push(rn)
        None => collect_descendant_renders(r, renders)
      }
      if renders.length() > 0 {
        Some(renders[0].build_semantics())
      } else {
        None
      }
    }
    None => None
  }
}

///|
pub fn UiTree::debug_paint_inspector(
  self : UiTree,
  canvas : @g2d.Canvas,
) -> Unit {
  match self.root {
    Some(r) => {
      let renders : Array[RenderNode] = []
      match r.render {
        Some(rn) => renders.push(rn)
        None => collect_descendant_renders(r, renders)
      }
      for rn in renders {
        rn.debug_draw_bounds(canvas)
      }
    }
    None => ()
  }
}
