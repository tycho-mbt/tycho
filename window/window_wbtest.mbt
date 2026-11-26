///|
test "IME event codes decode to preedit/commit/cancel" {
  assert_eq(event_from_code(11, 0x306B, 0, 0), Event::ImePreedit("に"))
  assert_eq(event_from_code(12, 0, 0, 0), Event::ImePreeditClear)
  assert_eq(event_from_code(13, 0x65E5, 0, 0), Event::ImeCommit("日"))
  assert_eq(event_from_code(14, 0, 0, 0), Event::ImeCancel)
  assert_eq(event_from_code(10, 65, 0, 0), Event::TextInput("A"))
}
