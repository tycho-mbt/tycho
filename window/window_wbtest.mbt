///|
test "IME event codes decode to preedit/commit/cancel" {
  assert_eq(event_from_code(11, 0x306B, 0, 0), Event::ImePreedit("に"))
  assert_eq(event_from_code(12, 0, 0, 0), Event::ImePreeditClear)
  assert_eq(event_from_code(13, 0x65E5, 0, 0), Event::ImeCommit("日"))
  assert_eq(event_from_code(14, 0, 0, 0), Event::ImeCancel)
  assert_eq(event_from_code(10, 65, 0, 0), Event::TextInput("A"))
}

///|
test "key codes round-trip through keysyms" {
  let keys = [
    KeyCode::Escape, KeyCode::Return, KeyCode::Tab, KeyCode::Space,
    KeyCode::Left, KeyCode::Up, KeyCode::Right, KeyCode::Down,
    KeyCode::Home, KeyCode::End, KeyCode::Insert, KeyCode::Delete,
    KeyCode::Num0, KeyCode::Num9, KeyCode::A, KeyCode::Z,
    KeyCode::F1, KeyCode::F12, KeyCode::LShift, KeyCode::RAlt,
  ]
  for k in keys {
    assert_eq(KeyCode::from_keysym(k.to_keysym()), k)
  }
  assert_eq(KeyCode::from_keysym(0x1234), KeyCode::Unknown(0x1234))
  assert_eq(KeyCode::Unknown(0x1234).to_keysym(), 0x1234)
}

///|
test "key events decode to typed key codes and modifiers" {
  // kind 3 = KeyDown, keysym 0x0073 = 's', mask 5 = Shift | Ctrl.
  let ev = event_from_code(3, 0x0073, 5, 0)
  match ev {
    Event::KeyDown(key, mods) => {
      assert_eq(key, KeyCode::S)
      assert_true(mods.shift)
      assert_true(mods.ctrl)
      assert_true(!mods.alt)
      assert_eq(mods.bits(), 5)
    }
    _ => fail("expected KeyDown")
  }
  match event_from_code(4, 0xff1b, 0, 0) {
    Event::KeyUp(key, mods) => {
      assert_eq(key, KeyCode::Escape)
      assert_true(mods.is_empty())
    }
    _ => fail("expected KeyUp")
  }
}

///|
test "modifier masks map to named fields" {
  assert_eq(Modifiers::from_bits(0), Modifiers::none())
  assert_eq(Modifiers::new(shift=true, alt=true).bits(), 9)
  assert_true(Modifiers::from_bits(64).super_key)
  assert_true(!Modifiers::from_bits(2).shift)
}

///|
test "mouse events decode to typed buttons" {
  match event_from_code(6, 1, 10, 20) {
    Event::MouseDown(button, x, y) => {
      assert_eq(button, MouseButton::Left)
      assert_eq(x, 10)
      assert_eq(y, 20)
    }
    _ => fail("expected MouseDown")
  }
  assert_eq(MouseButton::from_index(3), MouseButton::Right)
  assert_eq(MouseButton::from_index(9), MouseButton::Other(9))
  assert_eq(MouseButton::Right.index(), 3)
}

///|
test "window desc carries size and title" {
  let desc = WindowDesc::new(800, 600, "demo")
  assert_eq(desc.width, 800)
  assert_eq(desc.height, 600)
  assert_eq(desc.title, "demo")
}
