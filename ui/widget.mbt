// Widget tree descriptors, Keys, BuildContext, Controllers, and declarative Widget constructors.

///|
#derive(Eq, Debug)
pub(all) enum Key {
  IntKey(Int)
  StrKey(String)
}

///|
pub(all) struct ElementId {
  id : Int
}

///|
pub struct BuildContext {
  priv elem_id : Int
  priv theme_ref : ThemeData
}

///|
pub fn BuildContext::theme(self : BuildContext) -> ThemeData {
  self.theme_ref
}

///|
pub fn BuildContext::colors(self : BuildContext) -> ColorScheme {
  self.theme_ref.colors
}

///|
pub fn BuildContext::element_id(self : BuildContext) -> Int {
  self.elem_id
}

///|
pub struct ScrollController {
  offset : Signal[Float]
  priv mut max_extent : Float
  priv mut viewport_extent : Float
}

///|
pub fn ScrollController::new(initial_offset? : Float = (0.0 : Float)) -> ScrollController {
  {
    offset: Signal::new(max_f((0.0 : Float), initial_offset)),
    max_extent: (0.0 : Float),
    viewport_extent: (400.0 : Float),
  }
}

///|
pub fn ScrollController::scroll_by(self : ScrollController, delta : Float) -> Unit {
  let next = clamp_f(self.offset.peek() + delta, (0.0 : Float), self.max_extent)
  if next != self.offset.peek() {
    self.offset.set(next)
  }
}

///|
pub fn ScrollController::jump_to(self : ScrollController, offset : Float) -> Unit {
  let next = clamp_f(offset, (0.0 : Float), self.max_extent)
  if next != self.offset.peek() {
    self.offset.set(next)
  }
}

///|
pub struct TextController {
  text : Signal[String]
  cursor : Signal[Int]
  sel_anchor : Signal[Int]
  focused : Signal[Bool]
  multiline : Bool
  max_lines : Int
  mut blink_phase : Double
  priv undo_stack : Array[(String, Int)]
  priv redo_stack : Array[(String, Int)]
  priv mut last_tap_time : Double
  priv mut last_tap_pos : Int
}

///|
pub fn TextController::new(
  initial? : String = "",
  multiline? : Bool = false,
  max_lines? : Int = 1,
) -> TextController {
  let len = initial.length()
  {
    text: Signal::new(initial),
    cursor: Signal::new(len),
    sel_anchor: Signal::new(len),
    focused: Signal::new(false),
    multiline,
    max_lines,
    blink_phase: 0.0,
    undo_stack: [],
    redo_stack: [],
    last_tap_time: -10.0,
    last_tap_pos: -1,
  }
}

///|
fn TextController::push_undo(self : TextController) -> Unit {
  let snap = (self.text.peek(), self.cursor.peek())
  if self.undo_stack.length() >= 100 {
    let _ = self.undo_stack.remove(0)
  }
  self.undo_stack.push(snap)
  self.redo_stack.clear()
}

///|
pub fn TextController::selection_range(self : TextController) -> (Int, Int) {
  let len = self.text.peek().length()
  let a = clamp_i(self.sel_anchor.peek(), 0, len)
  let b = clamp_i(self.cursor.peek(), 0, len)
  if a <= b { (a, b) } else { (b, a) }
}

///|
pub fn TextController::selected_text(self : TextController) -> String {
  let (s0, s1) = self.selection_range()
  if s0 == s1 {
    ""
  } else {
    self.text.peek()[s0:s1].to_owned()
  }
}

///|
pub fn TextController::delete_selection(self : TextController) -> Bool {
  let (s0, s1) = self.selection_range()
  if s0 == s1 {
    return false
  }
  self.push_undo()
  let s = self.text.peek()
  let prefix = s[:s0].to_owned()
  let suffix = s[s1:].to_owned()
  self.text.set(prefix + suffix)
  self.cursor.set(s0)
  self.sel_anchor.set(s0)
  self.blink_phase = 0.0
  true
}

///|
pub fn TextController::insert_text(self : TextController, txt : String) -> Unit {
  if txt == "" {
    return
  }
  self.push_undo()
  let (s0, s1) = self.selection_range()
  let s = self.text.peek()
  let prefix = s[:s0].to_owned()
  let suffix = s[s1:].to_owned()
  self.text.set(prefix + txt + suffix)
  let next_cur = s0 + txt.length()
  self.cursor.set(next_cur)
  self.sel_anchor.set(next_cur)
  self.blink_phase = 0.0
}

///|
pub fn TextController::insert_char(self : TextController, ch : Char) -> Unit {
  self.insert_text(ch.to_string())
}

///|
pub fn TextController::backspace(self : TextController) -> Unit {
  if self.delete_selection() {
    return
  }
  let s = self.text.peek()
  let cur = clamp_i(self.cursor.peek(), 0, s.length())
  if cur <= 0 {
    return
  }
  self.push_undo()
  let prefix = s[:cur - 1].to_owned()
  let suffix = s[cur:].to_owned()
  self.text.set(prefix + suffix)
  self.cursor.set(cur - 1)
  self.sel_anchor.set(cur - 1)
  self.blink_phase = 0.0
}

///|
pub fn TextController::delete_forward(self : TextController) -> Unit {
  if self.delete_selection() {
    return
  }
  let s = self.text.peek()
  let cur = clamp_i(self.cursor.peek(), 0, s.length())
  if cur >= s.length() {
    return
  }
  self.push_undo()
  let prefix = s[:cur].to_owned()
  let suffix = s[cur + 1:].to_owned()
  self.text.set(prefix + suffix)
  self.blink_phase = 0.0
}

///|
pub fn TextController::move_left(
  self : TextController,
  select? : Bool = false,
) -> Unit {
  let cur = self.cursor.peek()
  let next = if cur > 0 { cur - 1 } else { 0 }
  self.cursor.set(next)
  if !select {
    self.sel_anchor.set(next)
  }
  self.blink_phase = 0.0
}

///|
pub fn TextController::move_right(
  self : TextController,
  select? : Bool = false,
) -> Unit {
  let len = self.text.peek().length()
  let cur = self.cursor.peek()
  let next = if cur < len { cur + 1 } else { len }
  self.cursor.set(next)
  if !select {
    self.sel_anchor.set(next)
  }
  self.blink_phase = 0.0
}

///|
pub fn TextController::move_home(
  self : TextController,
  select? : Bool = false,
) -> Unit {
  self.cursor.set(0)
  if !select {
    self.sel_anchor.set(0)
  }
  self.blink_phase = 0.0
}

///|
pub fn TextController::move_end(
  self : TextController,
  select? : Bool = false,
) -> Unit {
  let len = self.text.peek().length()
  self.cursor.set(len)
  if !select {
    self.sel_anchor.set(len)
  }
  self.blink_phase = 0.0
}

///|
pub fn TextController::select_all(self : TextController) -> Unit {
  let len = self.text.peek().length()
  self.sel_anchor.set(0)
  self.cursor.set(len)
  self.blink_phase = 0.0
}

///|
fn is_word_char(c : Int) -> Bool {
  (c >= 48 && c <= 57) ||
  (c >= 65 && c <= 90) ||
  (c >= 97 && c <= 122) ||
  c == 95
}

///|
pub fn TextController::select_word_at(self : TextController, pos : Int) -> Unit {
  let s = self.text.peek()
  let n = s.length()
  if n == 0 {
    return
  }
  let p = clamp_i(pos, 0, n - 1)
  let mut l = p
  let mut r = p + 1
  if is_word_char(s[p].to_int()) {
    while l > 0 && is_word_char(s[l - 1].to_int()) {
      l = l - 1
    }
    while r < n && is_word_char(s[r].to_int()) {
      r = r + 1
    }
  }
  self.sel_anchor.set(l)
  self.cursor.set(r)
  self.blink_phase = 0.0
}

///|
pub fn TextController::undo(self : TextController) -> Unit {
  match self.undo_stack.pop() {
    Some((prev_txt, prev_cur)) => {
      self.redo_stack.push((self.text.peek(), self.cursor.peek()))
      self.text.set(prev_txt)
      self.cursor.set(prev_cur)
      self.sel_anchor.set(prev_cur)
      self.blink_phase = 0.0
    }
    None => ()
  }
}

///|
pub fn TextController::redo(self : TextController) -> Unit {
  match self.redo_stack.pop() {
    Some((next_txt, next_cur)) => {
      self.undo_stack.push((self.text.peek(), self.cursor.peek()))
      self.text.set(next_txt)
      self.cursor.set(next_cur)
      self.sel_anchor.set(next_cur)
      self.blink_phase = 0.0
    }
    None => ()
  }
}

///|
fn clamp_i(v : Int, lo : Int, hi : Int) -> Int {
  if v < lo { lo } else if v > hi { hi } else { v }
}

///|
pub(all) struct DecoratedProps {
  fill : @g2d.Color?
  shader : @g2d.Shader2D?
  border_color : @g2d.Color?
  border_width : Float
  tl : Float
  tr : Float
  br : Float
  bl : Float
  shadow_blur : Float
  shadow_dx : Float
  shadow_dy : Float
  shadow_color : @g2d.Color?
}

///|
pub fn DecoratedProps::new(
  fill? : @g2d.Color? = None,
  shader? : @g2d.Shader2D? = None,
  border_color? : @g2d.Color? = None,
  border_width? : Float = (0.0 : Float),
  radius? : Float = (0.0 : Float),
  tl? : Float = (-1.0 : Float),
  tr? : Float = (-1.0 : Float),
  br? : Float = (-1.0 : Float),
  bl? : Float = (-1.0 : Float),
  shadow_blur? : Float = (0.0 : Float),
  shadow_dx? : Float = (0.0 : Float),
  shadow_dy? : Float = (4.0 : Float),
  shadow_color? : @g2d.Color? = None,
) -> DecoratedProps {
  {
    fill,
    shader,
    border_color,
    border_width,
    tl: if tl >= (0.0 : Float) { tl } else { radius },
    tr: if tr >= (0.0 : Float) { tr } else { radius },
    br: if br >= (0.0 : Float) { br } else { radius },
    bl: if bl >= (0.0 : Float) { bl } else { radius },
    shadow_blur,
    shadow_dx,
    shadow_dy,
    shadow_color,
  }
}

///|
pub(all) struct FrameStats {
  build_ms : Double
  layout_ms : Double
  paint_ms : Double
  gpu_ms : Double
  element_count : Int
  render_count : Int
}

///|
pub(all) enum WidgetKind {
  Builder(Int, (BuildContext) -> Widget) // type_tag, build_fn
  ThemeProvider(ThemeData, Widget)
  SizedBox(Float?, Float?, Widget?)
  Padding(EdgeInsets, Widget)
  Align(Alignment, Widget)
  ConstrainedBox(BoxConstraints, Widget)
  DecoratedBox(DecoratedProps, Widget?)
  Flex(Axis, MainAxisAlignment, CrossAxisAlignment, MainAxisSize, Float, Array[Widget])
  Expanded(Int, FlexFit, Widget)
  Stack(Alignment, Array[Widget])
  Positioned(Float?, Float?, Float?, Float?, Float?, Float?, Widget)
  Wrap(Float, Float, Array[Widget])
  ClipRect(Widget)
  ClipRRect(Float, Widget)
  Opacity(Float, Widget)
  Transform(@g2d.Matrix3, Widget)
  BackdropFilter(Float, Float, @g2d.Color, Widget) // blur_sigma, radius, tint
  RepaintBoundary(Widget)
  TextNode(String, @g2d.TextStyle, @g2d.TextAlign, Int, String)
  ImageNode(@g2d.Image2D, Float, Float)
  CustomPaint(@g2d.Size, (@g2d.Canvas, @g2d.Size) -> Unit)
  GestureNode(GestureCallbacks, Widget)
  ListViewBuilder(Int, Float, ScrollController, (BuildContext, Int) -> Widget)
  ScrollViewportNode(ScrollController, Axis, Widget)
  TextFieldNode(TextController, String, Float, Float) // ctrl, placeholder, width, font_size
}

///|
pub struct Widget {
  key : Key?
  kind : WidgetKind
}

///|
fn WidgetKind::tag(self : WidgetKind) -> Int {
  match self {
    Builder(tag, _) => 1000 + tag
    ThemeProvider(_, _) => 1
    SizedBox(_, _, _) => 2
    Padding(_, _) => 3
    Align(_, _) => 4
    ConstrainedBox(_, _) => 5
    DecoratedBox(_, _) => 6
    Flex(ax, _, _, _, _, _) => if ax == Axis::Horizontal { 7 } else { 8 }
    Expanded(_, _, _) => 9
    Stack(_, _) => 10
    Positioned(_, _, _, _, _, _, _) => 11
    Wrap(_, _, _) => 12
    ClipRect(_) => 13
    ClipRRect(_, _) => 14
    Opacity(_, _) => 15
    Transform(_, _) => 16
    BackdropFilter(_, _, _, _) => 17
    RepaintBoundary(_) => 18
    TextNode(_, _, _, _, _) => 19
    ImageNode(_, _, _) => 20
    CustomPaint(_, _) => 21
    GestureNode(_, _) => 22
    ListViewBuilder(_, _, _, _) => 23
    TextFieldNode(_, _, _, _) => 24
    ScrollViewportNode(_, _, _) => 25
  }
}

///|
pub fn builder(
  key? : Key? = None,
  tag? : Int = 0,
  build : (BuildContext) -> Widget,
) -> Widget {
  { key, kind: WidgetKind::Builder(tag, build) }
}

///|
pub fn theme_provider(
  key? : Key? = None,
  theme : ThemeData,
  child : Widget,
) -> Widget {
  { key, kind: WidgetKind::ThemeProvider(theme, child) }
}

///|
pub fn sized_box(
  key? : Key? = None,
  width? : Float? = None,
  height? : Float? = None,
  child? : Widget? = None,
) -> Widget {
  { key, kind: WidgetKind::SizedBox(width, height, child) }
}

///|
pub fn padding(
  key? : Key? = None,
  insets : EdgeInsets,
  child : Widget,
) -> Widget {
  { key, kind: WidgetKind::Padding(insets, child) }
}

///|
pub fn align(
  key? : Key? = None,
  alignment : Alignment,
  child : Widget,
) -> Widget {
  { key, kind: WidgetKind::Align(alignment, child) }
}

///|
pub fn center(key? : Key? = None, child : Widget) -> Widget {
  align(key~, Alignment::center(), child)
}

///|
pub fn constrained_box(
  key? : Key? = None,
  constraints : BoxConstraints,
  child : Widget,
) -> Widget {
  { key, kind: WidgetKind::ConstrainedBox(constraints, child) }
}

///|
pub fn decorated_box(
  key? : Key? = None,
  decoration : DecoratedProps,
  child? : Widget? = None,
) -> Widget {
  { key, kind: WidgetKind::DecoratedBox(decoration, child) }
}

///|
pub fn container(
  key? : Key? = None,
  width? : Float? = None,
  height? : Float? = None,
  pad? : EdgeInsets? = None,
  color? : @g2d.Color? = None,
  shader? : @g2d.Shader2D? = None,
  border_color? : @g2d.Color? = None,
  border_width? : Float = (0.0 : Float),
  radius? : Float = (0.0 : Float),
  tl? : Float = (-1.0 : Float),
  tr? : Float = (-1.0 : Float),
  br? : Float = (-1.0 : Float),
  bl? : Float = (-1.0 : Float),
  shadow_blur? : Float = (0.0 : Float),
  shadow_dx? : Float = (0.0 : Float),
  shadow_dy? : Float = (4.0 : Float),
  shadow_color? : @g2d.Color? = None,
  alignment? : Alignment? = None,
  child? : Widget? = None,
) -> Widget {
  let mut w = child
  match alignment {
    Some(al) =>
      match w {
        Some(c) => w = Some(align(al, c))
        None => ()
      }
    None => ()
  }
  match pad {
    Some(p) =>
      match w {
        Some(c) => w = Some(padding(p, c))
        None => w = Some(sized_box(width=Some(p.horizontal()), height=Some(p.vertical())))
      }
    None => ()
  }
  let has_deco = color is Some(_) ||
    shader is Some(_) ||
    border_color is Some(_) ||
    shadow_color is Some(_)
  if has_deco {
    let deco = DecoratedProps::new(
      fill=color,
      shader~,
      border_color~,
      border_width~,
      radius~,
      tl~,
      tr~,
      br~,
      bl~,
      shadow_blur~,
      shadow_dx~,
      shadow_dy~,
      shadow_color~,
    )
    w = Some(decorated_box(deco, child=w))
  }
  if width is Some(_) || height is Some(_) {
    sized_box(key~, width~, height~, child=w)
  } else {
    match w {
      Some(inner) => { key, kind: inner.kind }
      None => sized_box(key~)
    }
  }
}

///|
pub fn row(
  key? : Key? = None,
  main_axis? : MainAxisAlignment = MainAxisAlignment::Start,
  cross_axis? : CrossAxisAlignment = CrossAxisAlignment::Center,
  main_size? : MainAxisSize = MainAxisSize::Max,
  gap? : Float = (0.0 : Float),
  children : Array[Widget],
) -> Widget {
  {
    key,
    kind: WidgetKind::Flex(
      Axis::Horizontal,
      main_axis,
      cross_axis,
      main_size,
      gap,
      children,
    ),
  }
}

///|
pub fn column(
  key? : Key? = None,
  main_axis? : MainAxisAlignment = MainAxisAlignment::Start,
  cross_axis? : CrossAxisAlignment = CrossAxisAlignment::Start,
  main_size? : MainAxisSize = MainAxisSize::Max,
  gap? : Float = (0.0 : Float),
  children : Array[Widget],
) -> Widget {
  {
    key,
    kind: WidgetKind::Flex(
      Axis::Vertical,
      main_axis,
      cross_axis,
      main_size,
      gap,
      children,
    ),
  }
}

///|
pub fn expanded(
  key? : Key? = None,
  flex? : Int = 1,
  child : Widget,
) -> Widget {
  { key, kind: WidgetKind::Expanded(flex, FlexFit::Tight, child) }
}

///|
pub fn flexible(
  key? : Key? = None,
  flex? : Int = 1,
  fit? : FlexFit = FlexFit::Loose,
  child : Widget,
) -> Widget {
  { key, kind: WidgetKind::Expanded(flex, fit, child) }
}

///|
pub fn stack(
  key? : Key? = None,
  alignment? : Alignment = Alignment::top_left(),
  children : Array[Widget],
) -> Widget {
  { key, kind: WidgetKind::Stack(alignment, children) }
}

///|
pub fn positioned(
  key? : Key? = None,
  left? : Float? = None,
  top? : Float? = None,
  right? : Float? = None,
  bottom? : Float? = None,
  width? : Float? = None,
  height? : Float? = None,
  child : Widget,
) -> Widget {
  { key, kind: WidgetKind::Positioned(left, top, right, bottom, width, height, child) }
}

///|
pub fn wrap(
  key? : Key? = None,
  spacing? : Float = (8.0 : Float),
  run_spacing? : Float = (8.0 : Float),
  children : Array[Widget],
) -> Widget {
  { key, kind: WidgetKind::Wrap(spacing, run_spacing, children) }
}

///|
pub fn clip_rect(key? : Key? = None, child : Widget) -> Widget {
  { key, kind: WidgetKind::ClipRect(child) }
}

///|
pub fn clip_rrect(
  key? : Key? = None,
  radius : Float,
  child : Widget,
) -> Widget {
  { key, kind: WidgetKind::ClipRRect(radius, child) }
}

///|
pub fn opacity(key? : Key? = None, value : Float, child : Widget) -> Widget {
  { key, kind: WidgetKind::Opacity(value, child) }
}

///|
pub fn transform(
  key? : Key? = None,
  matrix : @g2d.Matrix3,
  child : Widget,
) -> Widget {
  { key, kind: WidgetKind::Transform(matrix, child) }
}

///|
pub fn backdrop_filter(
  key? : Key? = None,
  blur_sigma? : Float = (12.0 : Float),
  radius? : Float = (14.0 : Float),
  tint? : @g2d.Color = @g2d.Color::rgba((0.12 : Float), (0.15 : Float), (0.24 : Float), (0.72 : Float)),
  child : Widget,
) -> Widget {
  { key, kind: WidgetKind::BackdropFilter(blur_sigma, radius, tint, child) }
}

///|
pub fn repaint_boundary(key? : Key? = None, child : Widget) -> Widget {
  { key, kind: WidgetKind::RepaintBoundary(child) }
}

///|
pub fn text(
  key? : Key? = None,
  content : String,
  size? : Float = (15.0 : Float),
  color? : @g2d.Color? = None,
  font? : @g2d.FontFace? = None,
  align? : @g2d.TextAlign = @g2d.TextAlign::Left,
  max_lines? : Int = 0,
  ellipsis? : String = "",
) -> Widget {
  builder(key~, tag=190, fn(ctx) {
    let th = ctx.theme()
    let col = match color {
      Some(c) => c
      None => th.colors.text_primary
    }
    let f = match font {
      Some(ff) => ff
      None => th.font
    }
    let st = @g2d.TextStyle::new(font=f, font_size=size, color=col)
    { key: None, kind: WidgetKind::TextNode(content, st, align, max_lines, ellipsis) }
  })
}

///|
pub fn image_widget(
  key? : Key? = None,
  img : @g2d.Image2D,
  width : Float,
  height : Float,
) -> Widget {
  { key, kind: WidgetKind::ImageNode(img, width, height) }
}

///|
pub fn custom_paint(
  key? : Key? = None,
  size : @g2d.Size,
  painter : (@g2d.Canvas, @g2d.Size) -> Unit,
) -> Widget {
  { key, kind: WidgetKind::CustomPaint(size, painter) }
}

///|
pub fn gesture_detector(
  key? : Key? = None,
  on_tap? : (() -> Unit)? = None,
  on_drag_start? : ((@g2d.Point) -> Unit)? = None,
  on_drag_update? : ((@g2d.Point, @g2d.Point) -> Unit)? = None,
  on_drag_end? : (() -> Unit)? = None,
  on_scroll? : ((Float, Float) -> Unit)? = None,
  child : Widget,
) -> Widget {
  let cbs : GestureCallbacks = {
    on_tap,
    on_drag_start,
    on_drag_update,
    on_drag_end,
    on_scroll,
    on_mouse_enter: None,
    on_mouse_exit: None,
    on_hover: None,
    cursor: None,
  }
  { key, kind: WidgetKind::GestureNode(cbs, child) }
}

///|
pub fn mouse_region(
  key? : Key? = None,
  on_enter? : (() -> Unit)? = None,
  on_exit? : (() -> Unit)? = None,
  on_hover? : ((@g2d.Point) -> Unit)? = None,
  cursor? : @tycho.CursorShape? = None,
  child : Widget,
) -> Widget {
  let cbs : GestureCallbacks = {
    on_tap: None,
    on_drag_start: None,
    on_drag_update: None,
    on_drag_end: None,
    on_scroll: None,
    on_mouse_enter: on_enter,
    on_mouse_exit: on_exit,
    on_hover,
    cursor,
  }
  { key, kind: WidgetKind::GestureNode(cbs, child) }
}

///|
pub fn list_view_builder(
  key? : Key? = None,
  item_count : Int,
  item_extent : Float,
  controller : ScrollController,
  item_builder : (BuildContext, Int) -> Widget,
) -> Widget {
  { key, kind: WidgetKind::ListViewBuilder(item_count, item_extent, controller, item_builder) }
}

///|
pub fn single_child_scroll_view(
  key? : Key? = None,
  controller? : ScrollController? = None,
  direction? : Axis = Axis::Vertical,
  child : Widget,
) -> Widget {
  let ctrl = match controller {
    Some(c) => c
    None => ScrollController::new()
  }
  { key, kind: WidgetKind::ScrollViewportNode(ctrl, direction, child) }
}

///|
pub fn text_field(
  key? : Key? = None,
  controller : TextController,
  placeholder? : String = "Type here...",
  width? : Float = (260.0 : Float),
  font_size? : Float = (15.0 : Float),
) -> Widget {
  { key, kind: WidgetKind::TextFieldNode(controller, placeholder, width, font_size) }
}
