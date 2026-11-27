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
  Dst
  DstOver
  SrcIn
  DstIn
  SrcOut
  DstOut
  SrcAtop
  DstAtop
  Xor
  Plus
  Multiply
  Screen
  Darken
  Lighten
  Clear
}

///|
pub fn BlendMode2D::to_rhi(self : BlendMode2D) -> @tycho.BlendMode {
  match self {
    SrcOver => @tycho.BlendMode::Premultiplied
    Src => @tycho.BlendMode::Opaque
    Dst => @tycho.BlendMode::Opaque
    DstOver => @tycho.BlendMode::Premultiplied
    SrcIn => @tycho.BlendMode::SrcIn
    DstIn => @tycho.BlendMode::DstIn
    SrcOut => @tycho.BlendMode::Premultiplied
    DstOut => @tycho.BlendMode::Premultiplied
    SrcAtop => @tycho.BlendMode::Premultiplied
    DstAtop => @tycho.BlendMode::Premultiplied
    Xor => @tycho.BlendMode::Premultiplied
    Plus => @tycho.BlendMode::Additive
    Multiply => @tycho.BlendMode::Multiply
    Screen => @tycho.BlendMode::Additive
    Darken => @tycho.BlendMode::Opaque
    Lighten => @tycho.BlendMode::Opaque
    Clear => @tycho.BlendMode::Clear
  }
}

///|
// Explicit blend equations for modes the preset `BlendMode` values do not
// cover. `None` means the preset is exact.
pub fn BlendMode2D::to_blend_state(self : BlendMode2D) -> @tycho.BlendState? {
  let one = @tycho.BlendFactor::One
  let zero = @tycho.BlendFactor::Zero
  let sa = @tycho.BlendFactor::SrcAlpha
  let osa = @tycho.BlendFactor::OneMinusSrcAlpha
  let da = @tycho.BlendFactor::DstAlpha
  let oda = @tycho.BlendFactor::OneMinusDstAlpha
  match self {
    SrcOver => None
    Src => None
    Dst => Some(@tycho.BlendState::new(zero, one, zero, one))
    DstOver => Some(@tycho.BlendState::new(oda, one, oda, one))
    SrcIn => None
    DstIn => None
    SrcOut => Some(@tycho.BlendState::new(oda, zero, oda, zero))
    DstOut => Some(@tycho.BlendState::new(zero, osa, zero, osa))
    SrcAtop => Some(@tycho.BlendState::new(da, osa, da, osa))
    DstAtop => Some(@tycho.BlendState::new(oda, sa, oda, sa))
    Xor => Some(@tycho.BlendState::new(oda, osa, oda, osa))
    Plus => Some(@tycho.BlendState::new(one, one, one, one))
    Multiply => None
    Screen => Some(
      @tycho.BlendState::new(
        @tycho.BlendFactor::OneMinusDstColor,
        one,
        one,
        osa,
      ),
    )
    Darken => Some(
      @tycho.BlendState::new(one, one, one, osa, color_op=@tycho.BlendOp::Min),
    )
    Lighten => Some(
      @tycho.BlendState::new(one, one, one, osa, color_op=@tycho.BlendOp::Max),
    )
    Clear => None
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
// Monotonic id source for Image2D handles. Ids are only used as renderer cache
// keys, so allocating them internally removes a whole class of user-side
// collisions (two components both picking `id = 1`).
let g_next_image_id : Ref[Int] = Ref(1)

///|
fn alloc_image_id() -> Int {
  let id = g_next_image_id.val
  g_next_image_id.val = id + 1
  id
}

// Image2D handle wraps a GPU texture (or queued pixels uploaded via Renderer2D).
pub(all) struct Image2D {
  priv id : Int
  width : Int
  height : Int
  pixels : Bytes
  texture : @tycho.Texture?
  // Pixel encoding hints. `pixels` is straight-alpha RGBA8 by default;
  // `premultiplied` marks data that is already premultiplied. `srgb` selects
  // an sRGB texture format when the image is promoted out of the atlas.
  srgb : Bool
  premultiplied : Bool
}

///|
/// Renderer-side cache key. Unique per handle, allocated on construction.
pub fn Image2D::id(self : Image2D) -> Int {
  self.id
}

///|
fn is_srgb_texture_format(f : @tycho.TextureFormat) -> Bool {
  match f {
    @tycho.TextureFormat::RGBA8Srgb => true
    @tycho.TextureFormat::BGRA8Srgb => true
    _ => false
  }
}

///|
pub fn Image2D::from_bytes(
  width : Int,
  height : Int,
  pixels : Bytes,
  srgb? : Bool = false,
  premultiplied? : Bool = false,
) -> Image2D {
  {
    id: alloc_image_id(),
    width,
    height,
    pixels,
    texture: None,
    srgb,
    premultiplied,
  }
}

///|
pub fn Image2D::from_texture(texture : @tycho.Texture) -> Image2D {
  {
    id: alloc_image_id(),
    width: texture.width(),
    height: texture.height(),
    pixels: b"",
    texture: Some(texture),
    srgb: is_srgb_texture_format(texture.format()),
    premultiplied: true,
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
// Paint-level color filter, independent of ImageFilter. `Matrix` is a 4x5
// row-major color matrix; `Blend` is reserved for a future shader path.
pub(all) enum ColorFilter {
  Matrix(FixedArray[Float])
  Blend(Color, BlendMode2D)
}

///|
pub(all) enum MaskFilter {
  Blur(Float, Float)
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
  color_filter : ColorFilter?
  mask_filter : MaskFilter?
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
  shader? : Shader2D,
  image_filter? : ImageFilter,
  color_filter? : ColorFilter,
  mask_filter? : MaskFilter,
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
    color_filter,
    mask_filter,
    anti_alias,
  }
}

///|
// A drop shadow described by named fields instead of four anonymous floats.
// `blur` is the gaussian sigma, `spread` grows (or shrinks, when negative) the
// shadow shape before blurring.
pub(all) struct BoxShadow {
  dx : Float
  dy : Float
  blur : Float
  spread : Float
  color : Color
}

///|
pub fn BoxShadow::new(
  color : Color,
  dx? : Float = (0.0 : Float),
  dy? : Float = (4.0 : Float),
  blur? : Float = (8.0 : Float),
  spread? : Float = (0.0 : Float),
) -> BoxShadow {
  { dx, dy, blur, spread, color }
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
