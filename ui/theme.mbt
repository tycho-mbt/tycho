// Theme tokens (dark / light ColorScheme + Typography + radii) injected via BuildContext.

///|
#derive(Eq, Debug)
pub(all) struct ColorScheme {
  is_dark : Bool
  background : @g2d.Color
  surface : @g2d.Color
  surface_variant : @g2d.Color
  primary : @g2d.Color
  on_primary : @g2d.Color
  secondary : @g2d.Color
  text_primary : @g2d.Color
  text_secondary : @g2d.Color
  border : @g2d.Color
  danger : @g2d.Color
}

///|
pub fn ColorScheme::dark() -> ColorScheme {
  {
    is_dark: true,
    background: @g2d.Color::from_rgba8(14, 17, 27),
    surface: @g2d.Color::from_rgba8(24, 30, 48),
    surface_variant: @g2d.Color::from_rgba8(36, 44, 68),
    primary: @g2d.Color::from_rgba8(72, 162, 255),
    on_primary: @g2d.Color::from_rgba8(255, 255, 255),
    secondary: @g2d.Color::from_rgba8(82, 224, 162),
    text_primary: @g2d.Color::from_rgba8(236, 242, 255),
    text_secondary: @g2d.Color::from_rgba8(152, 166, 198),
    border: @g2d.Color::from_rgba8(54, 66, 98),
    danger: @g2d.Color::from_rgba8(244, 78, 92),
  }
}

///|
pub fn ColorScheme::light() -> ColorScheme {
  {
    is_dark: false,
    background: @g2d.Color::from_rgba8(242, 245, 251),
    surface: @g2d.Color::from_rgba8(255, 255, 255),
    surface_variant: @g2d.Color::from_rgba8(229, 235, 247),
    primary: @g2d.Color::from_rgba8(32, 110, 232),
    on_primary: @g2d.Color::from_rgba8(255, 255, 255),
    secondary: @g2d.Color::from_rgba8(16, 168, 114),
    text_primary: @g2d.Color::from_rgba8(22, 28, 45),
    text_secondary: @g2d.Color::from_rgba8(96, 108, 134),
    border: @g2d.Color::from_rgba8(204, 214, 232),
    danger: @g2d.Color::from_rgba8(216, 48, 66),
  }
}

///|
pub(all) struct ThemeData {
  colors : ColorScheme
  font : @g2d.FontFace
  radius_sm : Float
  radius_md : Float
  radius_lg : Float
}

///|
pub fn ThemeData::dark(font? : @g2d.FontFace = @g2d.FontFace::builtin()) -> ThemeData {
  {
    colors: ColorScheme::dark(),
    font,
    radius_sm: (6.0 : Float),
    radius_md: (12.0 : Float),
    radius_lg: (18.0 : Float),
  }
}

///|
pub fn ThemeData::light(font? : @g2d.FontFace = @g2d.FontFace::builtin()) -> ThemeData {
  {
    colors: ColorScheme::light(),
    font,
    radius_sm: (6.0 : Float),
    radius_md: (12.0 : Float),
    radius_lg: (18.0 : Float),
  }
}
