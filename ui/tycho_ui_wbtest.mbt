// Pure-MoonBit unit tests for laplaceliu/tycho_ui Signals, BoxConstraints, Layout, Diffing, GestureArena, and ListView virtualization.

///|
test "signal tracks element subscriptions and marks dirty accurately" {
  let count = Signal::new(0)
  let ui = builder(fn(ctx) { text("val=\{count.get(ctx)}") })
  let tester = WidgetTester::new(ui, width=(400.0 : Float), height=(200.0 : Float))
  assert_true(count.subscriber_count() == 1)
  count.set(42)
  assert_true(tester.tree.has_dirty())
  let _ = tester.pump_frame()
  assert_eq(tester.tree.has_dirty(), false)
}

///|
test "row and column flex constraints distribute expanded space" {
  let ui = row(
    gap=(10.0 : Float),
    [
      sized_box(width=Some((80.0 : Float)), height=Some((40.0 : Float))),
      expanded(flex=1, sized_box(height=Some((40.0 : Float)))),
      expanded(flex=2, sized_box(height=Some((40.0 : Float)))),
    ],
  )
  let tester = WidgetTester::new(ui, width=(400.0 : Float), height=(100.0 : Float))
  let root = tester.tree.render_root().unwrap()
  assert_eq(root.size, @g2d.Size::new((400.0 : Float), (100.0 : Float)))
  // Remaining after 80 + 2*10 gaps = 300 -> flex 1 = 100, flex 2 = 200
  assert_eq(root.children[0].size.width, (80.0 : Float))
  assert_eq(root.children[1].children[0].size.width, (100.0 : Float))
  assert_eq(root.children[2].children[0].size.width, (200.0 : Float))
  assert_eq(root.children[1].offset.x, (90.0 : Float))
  assert_eq(root.children[2].offset.x, (200.0 : Float))
}

///|
test "gesture arena disambiguates tap vs drag via touch slop" {
  let tapped = Ref(0)
  let dragged = Ref(0)
  let ui = gesture_detector(
    on_scroll=Some(fn(_dx, _dy) { () }),
    on_drag_update=Some(fn(_p, _d) { dragged.val = dragged.val + 1 }),
    gesture_detector(
      on_tap=Some(fn() { tapped.val = tapped.val + 1 }),
      sized_box(width=Some((200.0 : Float)), height=Some((200.0 : Float))),
    ),
  )
  let tester = WidgetTester::new(ui, width=(200.0 : Float), height=(200.0 : Float))
  // Small movement within slop -> Tap wins
  tester.tap((50.0 : Float), (50.0 : Float))
  assert_eq(tapped.val, 1)
  assert_eq(dragged.val, 0)
  // Large movement beyond slop -> Drag wins, tap not fired
  let p0 = @g2d.Point::new((50.0 : Float), (50.0 : Float))
  let hits = tester.tree.hit_test(p0)
  tester.arena.handle_down(0, p0, hits)
  tester.arena.handle_move(0, @g2d.Point::new((50.0 : Float), (80.0 : Float)))
  tester.arena.handle_up(0, @g2d.Point::new((50.0 : Float), (80.0 : Float)), true)
  assert_eq(tapped.val, 1)
  assert_true(dragged.val >= 1)
}

///|
test "list_view_builder virtualizes 100000 items with constant node count" {
  let sc = ScrollController::new()
  let ui = list_view_builder(100000, (40.0 : Float), sc, fn(_ctx, i) {
    text("Row #\{i}")
  })
  let tester = WidgetTester::new(ui, width=(400.0 : Float), height=(400.0 : Float))
  // 400px / 40px = 10 visible + 2 cache buffer = ~12 items, nowhere near 100000!
  let initial_elems = tester.element_count()
  assert_true(initial_elems < 60)
  sc.jump_to((40000.0 : Float))
  let _ = tester.pump_frame()
  let scrolled_elems = tester.element_count()
  assert_true(scrolled_elems < 60)
}

///|
test "text_controller handles insertion, cursor movement, and backspace" {
  let tc = TextController::new(initial="abc")
  tc.move_left()
  tc.insert_char('X')
  assert_eq(tc.text.peek(), "abXc")
  tc.backspace()
  assert_eq(tc.text.peek(), "abc")
}

///|
test "text_controller handles selection, word select, undo and redo" {
  let tc = TextController::new(initial="hello world")
  tc.select_word_at(1)
  assert_eq(tc.selected_text(), "hello")
  tc.insert_text("hi")
  assert_eq(tc.text.peek(), "hi world")
  tc.undo()
  assert_eq(tc.text.peek(), "hello world")
  tc.redo()
  assert_eq(tc.text.peek(), "hi world")
  tc.select_all()
  assert_eq(tc.selected_text(), "hi world")
}

///|
test "focus_manager cycles nodes and dispatches shortcuts" {
  let fm = FocusManager::new()
  let n1 = FocusNode::new()
  let n2 = FocusNode::new()
  fm.register(n1)
  fm.register(n2)
  fm.next_focus()
  assert_true(n1.focused.peek())
  assert_true(!n2.focused.peek())
  fm.next_focus()
  assert_true(!n1.focused.peek())
  assert_true(n2.focused.peek())
  fm.prev_focus()
  assert_true(n1.focused.peek())
  let fired = Ref(false)
  fm.bind_shortcut(@tycho.KEY_S, 4, fn() { fired.val = true })
  assert_true(fm.dispatch_key(@tycho.KEY_S, 4))
  assert_true(fired.val)
}

///|
test "scroll_view, navigator, overlay, spring, and semantics work end-to-end" {
  let sc = ScrollController::new()
  let nav = NavigatorController::new("home", fn(_ctx) {
    single_child_scroll_view(
      controller=Some(sc),
      column([
        container(height=Some((800.0 : Float)), child=Some(text("tall"))),
        icon(IconKind::Star),
        badge(label="3", text_button("Go", fn() {  })),
      ]),
    )
  })
  let ov = OverlayController::new()
  let tester = WidgetTester::new(
    overlay(ov, scrollbar(sc, navigator(nav))),
    width=(400.0 : Float),
    height=(300.0 : Float),
  )
  tester.scroll((100.0 : Float), (100.0 : Float), (0.0 : Float), (-2.0 : Float))
  assert_true(sc.offset.peek() > (0.0 : Float))
  nav.push("detail", fn(_ctx) { text("detail page") })
  assert_eq(nav.current_name(), "detail")
  assert_true(nav.pop())
  assert_eq(nav.current_name(), "home")
  let sp = Curve::Spring((180.0 : Float), (18.0 : Float), (1.0 : Float))
  assert_eq(sp.eval((0.0 : Float)), (0.0 : Float))
  assert_eq(sp.eval((1.0 : Float)), (1.0 : Float))
  match tester.tree.build_semantics_tree() {
    Some(root_sem) => assert_true(root_sem.children.length() >= 1)
    None => assert_true(false)
  }
}
