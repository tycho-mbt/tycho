// Single-pass Flutter-style BoxConstraints, EdgeInsets, Alignment, and Flex types.

///|
pub const INF : Float = (1.0e30 : Float)

///|
#derive(Eq, Debug)
pub(all) struct BoxConstraints {
  min_width : Float
  max_width : Float
  min_height : Float
  max_height : Float
}

///|
pub fn BoxConstraints::new(
  min_width? : Float = (0.0 : Float),
  max_width? : Float = INF,
  min_height? : Float = (0.0 : Float),
  max_height? : Float = INF,
) -> BoxConstraints {
  {
    min_width: @tmath.max_f((0.0 : Float), min_width),
    max_width: @tmath.max_f(min_width, max_width),
    min_height: @tmath.max_f((0.0 : Float), min_height),
    max_height: @tmath.max_f(min_height, max_height),
  }
}

///|
pub fn BoxConstraints::tight(size : @g2d.Size) -> BoxConstraints {
  {
    min_width: size.width,
    max_width: size.width,
    min_height: size.height,
    max_height: size.height,
  }
}

///|
pub fn BoxConstraints::loose(size : @g2d.Size) -> BoxConstraints {
  {
    min_width: (0.0 : Float),
    max_width: size.width,
    min_height: (0.0 : Float),
    max_height: size.height,
  }
}

///|
pub fn BoxConstraints::expand() -> BoxConstraints {
  { min_width: INF, max_width: INF, min_height: INF, max_height: INF }
}

///|
pub fn BoxConstraints::unbounded() -> BoxConstraints {
  { min_width: (0.0 : Float), max_width: INF, min_height: (0.0 : Float), max_height: INF }
}

///|
pub fn BoxConstraints::is_tight(self : BoxConstraints) -> Bool {
  self.min_width == self.max_width && self.min_height == self.max_height
}

///|
pub fn BoxConstraints::has_bounded_width(self : BoxConstraints) -> Bool {
  self.max_width < INF * (0.5 : Float)
}

///|
pub fn BoxConstraints::has_bounded_height(self : BoxConstraints) -> Bool {
  self.max_height < INF * (0.5 : Float)
}

///|
pub fn BoxConstraints::constrain(
  self : BoxConstraints,
  size : @g2d.Size,
) -> @g2d.Size {
  @g2d.Size::new(
    @tmath.clamp_f(size.width, self.min_width, self.max_width),
    @tmath.clamp_f(size.height, self.min_height, self.max_height),
  )
}

///|
pub fn BoxConstraints::constrain_width(self : BoxConstraints, w : Float) -> Float {
  @tmath.clamp_f(w, self.min_width, self.max_width)
}

///|
pub fn BoxConstraints::constrain_height(self : BoxConstraints, h : Float) -> Float {
  @tmath.clamp_f(h, self.min_height, self.max_height)
}

///|
pub fn BoxConstraints::loosen(self : BoxConstraints) -> BoxConstraints {
  {
    min_width: (0.0 : Float),
    max_width: self.max_width,
    min_height: (0.0 : Float),
    max_height: self.max_height,
  }
}

///|
pub fn BoxConstraints::deflate(
  self : BoxConstraints,
  insets : EdgeInsets,
) -> BoxConstraints {
  let h = insets.horizontal()
  let v = insets.vertical()
  let new_min_w = @tmath.max_f((0.0 : Float), self.min_width - h)
  let new_max_w = if self.has_bounded_width() {
    @tmath.max_f(new_min_w, self.max_width - h)
  } else {
    INF
  }
  let new_min_h = @tmath.max_f((0.0 : Float), self.min_height - v)
  let new_max_h = if self.has_bounded_height() {
    @tmath.max_f(new_min_h, self.max_height - v)
  } else {
    INF
  }
  {
    min_width: new_min_w,
    max_width: new_max_w,
    min_height: new_min_h,
    max_height: new_max_h,
  }
}

///|
pub fn BoxConstraints::enforce(
  self : BoxConstraints,
  other : BoxConstraints,
) -> BoxConstraints {
  {
    min_width: @tmath.clamp_f(self.min_width, other.min_width, other.max_width),
    max_width: @tmath.clamp_f(self.max_width, other.min_width, other.max_width),
    min_height: @tmath.clamp_f(self.min_height, other.min_height, other.max_height),
    max_height: @tmath.clamp_f(self.max_height, other.min_height, other.max_height),
  }
}

///|
#derive(Eq, Debug)
pub(all) struct EdgeInsets {
  left : Float
  top : Float
  right : Float
  bottom : Float
}

///|
pub fn EdgeInsets::zero() -> EdgeInsets {
  { left: (0.0 : Float), top: (0.0 : Float), right: (0.0 : Float), bottom: (0.0 : Float) }
}

///|
pub fn EdgeInsets::all(v : Float) -> EdgeInsets {
  { left: v, top: v, right: v, bottom: v }
}

///|
pub fn EdgeInsets::symmetric(
  horizontal? : Float = (0.0 : Float),
  vertical? : Float = (0.0 : Float),
) -> EdgeInsets {
  { left: horizontal, top: vertical, right: horizontal, bottom: vertical }
}

///|
pub fn EdgeInsets::only(
  left? : Float = (0.0 : Float),
  top? : Float = (0.0 : Float),
  right? : Float = (0.0 : Float),
  bottom? : Float = (0.0 : Float),
) -> EdgeInsets {
  { left, top, right, bottom }
}

///|
pub fn EdgeInsets::horizontal(self : EdgeInsets) -> Float {
  self.left + self.right
}

///|
pub fn EdgeInsets::vertical(self : EdgeInsets) -> Float {
  self.top + self.bottom
}

///|
#derive(Eq, Debug)
pub(all) struct Alignment {
  x : Float // -1.0 (left) .. 1.0 (right)
  y : Float // -1.0 (top) .. 1.0 (bottom)
}

///|
pub fn Alignment::new(x : Float, y : Float) -> Alignment {
  { x, y }
}

///|
pub fn Alignment::top_left() -> Alignment { { x: (-1.0 : Float), y: (-1.0 : Float) } }

///|
pub fn Alignment::top_center() -> Alignment { { x: (0.0 : Float), y: (-1.0 : Float) } }

///|
pub fn Alignment::top_right() -> Alignment { { x: (1.0 : Float), y: (-1.0 : Float) } }

///|
pub fn Alignment::center_left() -> Alignment { { x: (-1.0 : Float), y: (0.0 : Float) } }

///|
pub fn Alignment::center() -> Alignment { { x: (0.0 : Float), y: (0.0 : Float) } }

///|
pub fn Alignment::center_right() -> Alignment { { x: (1.0 : Float), y: (0.0 : Float) } }

///|
pub fn Alignment::bottom_left() -> Alignment { { x: (-1.0 : Float), y: (1.0 : Float) } }

///|
pub fn Alignment::bottom_center() -> Alignment { { x: (0.0 : Float), y: (1.0 : Float) } }

///|
pub fn Alignment::bottom_right() -> Alignment { { x: (1.0 : Float), y: (1.0 : Float) } }

///|
pub fn Alignment::along_offset(
  self : Alignment,
  parent : @g2d.Size,
  child : @g2d.Size,
) -> @g2d.Point {
  let dx = (parent.width - child.width) * (0.5 : Float) * (self.x + (1.0 : Float))
  let dy = (parent.height - child.height) * (0.5 : Float) * (self.y + (1.0 : Float))
  @g2d.Point::new(dx, dy)
}

///|
#derive(Eq, Debug)
pub(all) enum Axis {
  Horizontal
  Vertical
}

///|
#derive(Eq, Debug)
pub(all) enum MainAxisAlignment {
  Start
  Center
  End
  SpaceBetween
  SpaceAround
  SpaceEvenly
}

///|
#derive(Eq, Debug)
pub(all) enum CrossAxisAlignment {
  Start
  Center
  End
  Stretch
}

///|
#derive(Eq, Debug)
pub(all) enum MainAxisSize {
  Min
  Max
}

///|
#derive(Eq, Debug)
pub(all) enum FlexFit {
  Tight
  Loose
}
