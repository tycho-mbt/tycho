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
      sized_box(width=(80.0 : Float), height=(40.0 : Float)),
      expanded(flex=1, sized_box(height=(40.0 : Float))),
      expanded(flex=2, sized_box(height=(40.0 : Float))),
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
    on_scroll=fn(_dx, _dy) { () },
    on_drag_update=fn(_p, _d) { dragged.val = dragged.val + 1 },
    gesture_detector(
      on_tap=fn() { tapped.val = tapped.val + 1 },
      sized_box(width=(200.0 : Float), height=(200.0 : Float)),
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
test "text_controller IME preedit commit" {
  let tc = TextController::new(initial="ab")
  tc.set_preedit("にほ")
  assert_eq(tc.display_text(), "abにほ")
  assert_eq(tc.text.peek(), "ab")
  tc.commit_preedit()
  assert_eq(tc.text.peek(), "abにほ")
  assert_eq(tc.preedit.peek(), "")
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
  fm.bind_shortcut(@tycho.KeyCode::S.to_keysym(), 4, fn() { fired.val = true })
  assert_true(fm.dispatch_key(@tycho.KeyCode::S.to_keysym(), 4))
  assert_true(fired.val)
}

///|
test "scroll_view, navigator, overlay, spring, and semantics work end-to-end" {
  let sc = ScrollController::new()
  let nav = NavigatorController::new("home", fn(_ctx) {
    single_child_scroll_view(
      controller=sc,
      column([
        container(height=(800.0 : Float), child=text("tall")),
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

///|
test "stale signal dependencies are pruned when a build stops reading them" {
  let show = Signal::new(true)
  let counter = Signal::new(0)
  let root = builder(fn(ctx) {
    if show.get(ctx) {
      text("count=\{counter.get(ctx)}")
    } else {
      text("off")
    }
  })
  let tester = WidgetTester::new(root, width=(200.0 : Float), height=(100.0 : Float))
  assert_eq(counter.subscriber_count(), 1)
  show.set(false)
  let _ = tester.pump_frame()
  // The rebuild no longer reads `counter`, so its subscription must be released.
  assert_eq(counter.subscriber_count(), 0)
  assert_eq(show.subscriber_count(), 1)
}

///|
test "unmounting a subtree releases its signal subscriptions" {
  let show = Signal::new(true)
  let counter = Signal::new(0)
  let inner = builder(fn(ctx) { text("n=\{counter.get(ctx)}") })
  let root = builder(fn(ctx) {
    if show.get(ctx) {
      stack([inner])
    } else {
      stack([])
    }
  })
  let tester = WidgetTester::new(root, width=(200.0 : Float), height=(100.0 : Float))
  assert_eq(counter.subscriber_count(), 1)
  show.set(false)
  let _ = tester.pump_frame()
  assert_eq(counter.subscriber_count(), 0)
}

///|
test "signal dirty tracking is scoped to one UiTree" {
  let shared = Signal::new(0)
  let a = WidgetTester::new(builder(fn(ctx) { text("a=\{shared.get(ctx)}") }))
  let b = WidgetTester::new(builder(fn(_ctx) { text("b") }))
  assert_eq(shared.subscriber_count(), 1)
  shared.set(1)
  assert_true(a.tree.has_dirty())
  assert_true(!b.tree.has_dirty())
}

///|
test "tooltip hover stays stable and frosted_dialog blocks hits behind modal" {
  let behind_taps = Ref(0)
  let show_modal = Signal::new(false)
  let root = builder(tag=901, fn(ctx) {
    let base = tooltip(
      "Help",
      outlined_button("Action", fn() { behind_taps.val = behind_taps.val + 1 }),
    )
    if show_modal.get(ctx) {
      stack([
        base,
        frosted_dialog("Modal", text("Body"), fn() { show_modal.set(false) }),
      ])
    } else {
      stack([base])
    }
  })
  let tester = WidgetTester::new(root, width=(400.0 : Float), height=(300.0 : Float))
  // Hover repeatedly over Action button — tooltip must not oscillate or break tap
  tester.move_mouse((20.0 : Float), (16.0 : Float))
  tester.move_mouse((21.0 : Float), (16.0 : Float))
  tester.tap((20.0 : Float), (16.0 : Float))
  assert_eq(behind_taps.val, 1)
  // Open modal -> tapping Action coordinate behind modal must not increment behind_taps
  show_modal.set(true)
  let _ = tester.pump_frame()
  tester.tap((20.0 : Float), (16.0 : Float))
  assert_eq(behind_taps.val, 1)
}

///|
test "tooltip positioned child does not resize or shift button in row" {
  let root = row(main_axis=MainAxisAlignment::End, [
    tooltip(
      "This is a much wider tooltip message than the button",
      filled_button("Go", fn() {  }),
    ),
  ])
  let tester = WidgetTester::new(root, width=(400.0 : Float), height=(100.0 : Float))
  let box_before = tester.tree.build_semantics_tree().unwrap().children[0].bounds
  tester.move_mouse(box_before.x + (5.0 : Float), box_before.y + (5.0 : Float))
  let box_after = tester.tree.build_semantics_tree().unwrap().children[0].bounds
  assert_eq(box_before.x, box_after.x)
  assert_eq(box_before.width, box_after.width)
}
