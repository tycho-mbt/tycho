// Paint styles, gradients, blend modes, and image filters for laplaceliu/tycho_2d.

///|
#derive(Eq, Debug)
pub(all) enum PaintStyle {
  Fill
  Stroke
  StrokeAndFill
}

///|
#derive(Eq, Debug)
pub(all) enum StrokeCap {
  Butt
  Round
  Square
}

///|
#derive(Eq, Debug)
pub(all) enum StrokeJoin {
  Miter
  Round
  Bevel
}

///|
#derive(Eq, Debug)
pub(all) enum TileMode {
  Clamp
  Repeat
  Mirror
  Decal
}

///|
#derive(Eq, Debug)
pub(all) enum BlendMode2D {
  SrcOver
  Src
  Plus
  Multiply
  DstIn
  SrcIn
  Clear
}

///|
pub fn BlendMode2D::to_rhi(self : BlendMode2D) -> @tycho.BlendMode {
  match self {
    SrcOver => @tycho.BlendMode::Premultiplied
    Src => @tycho.BlendMode::Opaque
    Plus => @tycho.BlendMode::Additive
    Multiply => @tycho.BlendMode::Multiply
    DstIn => @tycho.BlendMode::DstIn
    SrcIn => @tycho.BlendMode::SrcIn
    Clear => @tycho.BlendMode::Clear
  }
}

///|
#derive(Eq, Debug)
pub(all) struct GradientStop {
  offset : Float
  color : Color
}

///|
pub fn GradientStop::new(offset : Float, color : Color) -> GradientStop {
  { offset: @tmath.clamp_f(offset, (0.0 : Float), (1.0 : Float)), color }
}

///|
// Image2D handle wraps a GPU texture (or queued pixels uploaded via Renderer2D).
pub(all) struct Image2D {
  id : Int
  width : Int
  height : Int
  pixels : Bytes
  texture : @tycho.Texture?
}

///|
pub fn Image2D::from_bytes(
  id : Int,
  width : Int,
  height : Int,
  pixels : Bytes,
) -> Image2D {
  { id, width, height, pixels, texture: None }
}

///|
pub fn Image2D::from_texture(id : Int, texture : @tycho.Texture) -> Image2D {
  {
    id,
    width: texture.width(),
    height: texture.height(),
    pixels: b"",
    texture: Some(texture),
  }
}

///|
pub(all) enum Shader2D {
  Solid(Color)
  LinearGradient(Point, Point, Array[GradientStop], TileMode)
  RadialGradient(Point, Float, Array[GradientStop], TileMode)
  SweepGradient(Point, Float, Float, Array[GradientStop], TileMode)
  ImagePattern(Image2D, Matrix3, @tycho.Filter, TileMode, TileMode)
}

///|
pub(all) enum ImageFilter {
  Blur(Float, Float, TileMode)
  DropShadow(Float, Float, Float, Float, Color)
  ColorMatrix(FixedArray[Float])
}

///|
pub(all) struct Paint {
  color : Color
  style : PaintStyle
  stroke_width : Float
  stroke_cap : StrokeCap
  stroke_join : StrokeJoin
  stroke_miter : Float
  blend_mode : BlendMode2D
  shader : Shader2D?
  image_filter : ImageFilter?
  anti_alias : Bool
}

///|
pub fn Paint::new(
  color? : Color = Color::white(),
  style? : PaintStyle = PaintStyle::Fill,
  stroke_width? : Float = (1.0 : Float),
  stroke_cap? : StrokeCap = StrokeCap::Butt,
  stroke_join? : StrokeJoin = StrokeJoin::Miter,
  stroke_miter? : Float = (4.0 : Float),
  blend_mode? : BlendMode2D = BlendMode2D::SrcOver,
  shader? : Shader2D? = None,
  image_filter? : ImageFilter? = None,
  anti_alias? : Bool = true,
) -> Paint {
  {
    color,
    style,
    stroke_width,
    stroke_cap,
    stroke_join,
    stroke_miter,
    blend_mode,
    shader,
    image_filter,
    anti_alias,
  }
}

///|
pub fn Paint::fill(color : Color) -> Paint {
  Paint::new(color~)
}

///|
pub fn Paint::stroke(
  color : Color,
  width : Float,
  cap? : StrokeCap = StrokeCap::Butt,
  join? : StrokeJoin = StrokeJoin::Miter,
) -> Paint {
  Paint::new(
    color~,
    style=PaintStyle::Stroke,
    stroke_width=width,
    stroke_cap=cap,
    stroke_join=join,
  )
}
