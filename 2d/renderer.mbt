// GPU Renderer2D over laplaceliu/tycho RHI (AOT pipelines, Tier-1 SDF/Atlas batching,
// Tier-2 Stencil-then-Cover + Stroker, Tier-3 SaveLayer / BackdropFilter Gaussian Blur).

const PRIM_FLOATS : Int = 40
const PRIM_BYTES : Int = 160
const STOP_FLOATS : Int = 8
const STOP_BYTES : Int = 32
const PATH_VERT_FLOATS : Int = 2
const PATH_VERT_BYTES : Int = 8

///|
priv struct RenderSaveState {
  transform : Matrix3
  scissor : Rect
  clip_rrect : RRect?
  has_stencil_clip : Bool
  is_layer : Bool
  layer_paint : Paint
  outer_tex : @tycho.Texture?
  outer_ds : @tycho.Texture?
  outer_w : Int
  outer_h : Int
}

///|
pub struct Renderer2D {
  priv dev : @tycho.Device
  priv sampler : @tycho.Sampler
  priv glyph_cache : GlyphCache
  priv color_atlas : DynamicAtlas
  priv rt_pool : RenderTargetPool
  priv uploaded_images : Map[Int, (Float, Float, Float, Float)]
  // AOT pipelines (depth_format = Depth24Stencil8 for main / layer passes)
  priv prim_pipe : @tycho.Pipeline
  priv prim_clip_pipe : @tycho.Pipeline
  priv stencil_nz_pipe : @tycho.Pipeline
  priv stencil_eo_pipe : @tycho.Pipeline
  priv stencil_clip_pipe : @tycho.Pipeline
  priv path_cover_pipe : @tycho.Pipeline
  priv path_cover_clip_pipe : @tycho.Pipeline
  priv stroke_pipe : @tycho.Pipeline
  priv stroke_clip_pipe : @tycho.Pipeline
  priv composite_ds_pipe : @tycho.Pipeline
  priv composite_ds_dstin_pipe : @tycho.Pipeline
  priv composite_ds_srcin_pipe : @tycho.Pipeline
  priv composite_ds_mul_pipe : @tycho.Pipeline
  // Depth-free blur & swapchain presentation pipelines
  priv blur_pipe : @tycho.Pipeline
  priv present_pipe : @tycho.Pipeline
  priv mut present_sc_pipe : @tycho.Pipeline?
  priv mut present_sc_fmt : @tycho.TextureFormat?
  // Double-buffered dynamic buffers
  priv max_prims : Int
  priv max_stops : Int
  priv max_path_verts : Int
  priv prim_ssbo : @tycho.Buffer
  priv grad_ssbo : @tycho.Buffer
  priv path_vbuf : @tycho.Buffer
  priv prim_scratch : FixedArray[Float]
  priv stop_scratch : FixedArray[Float]
  priv path_scratch : FixedArray[Float]
  priv mut frame_idx : Int
  // Per-frame active batch cursors
  priv mut prim_cursor : Int
  priv mut prim_batch_start : Int
  priv mut stop_cursor : Int
  priv mut path_cursor : Int
  // Active traversal state
  priv mut cur_transform : Matrix3
  priv mut cur_scissor : Rect
  priv mut cur_clip_rrect : RRect?
  priv mut has_stencil_clip : Bool
  priv mut active_tex : @tycho.Texture?
  priv mut active_ds : @tycho.Texture?
  priv mut active_w : Int
  priv mut active_h : Int
  priv state_stack : Array[RenderSaveState]
}

///|
fn make_rhi_stencil_pipeline(
  dev : @tycho.Device,
  vert : FixedArray[UInt32],
  frag : FixedArray[UInt32],
  stencil : @tycho.StencilState,
  color_write : Bool,
  blend_mode : @tycho.BlendMode,
) -> @tycho.Pipeline raise @tycho.RhiError {
  dev.create_graphics_pipeline(
    @tycho.PipelineDesc::from_spirv(
      vert,
      frag,
      blend_mode=Some(blend_mode),
      color_write~,
      cull_mode=@tycho.CullMode::None,
      color_format=Some(@tycho.TextureFormat::RGBA8),
      depth_format=Some(@tycho.TextureFormat::Depth24Stencil8),
      stencil=Some(stencil),
    ),
  )
}

///|
pub fn Renderer2D::new(
  dev : @tycho.Device,
  max_prims_per_frame? : Int = 8192,
  max_stops_per_frame? : Int = 4096,
  max_path_verts_per_frame? : Int = 65536,
) -> Renderer2D raise @tycho.RhiError {
  let sampler = dev.create_sampler_desc(
    @tycho.SamplerDesc::new(
      mag=@tycho.Filter::Linear,
      min=@tycho.Filter::Linear,
      address=@tycho.AddressMode::ClampToEdge,
    ),
  )
  let glyph_cache = GlyphCache::new(dev, width=1024, height=1024)
  let color_atlas = DynamicAtlas::new(
    dev,
    1024,
    1024,
    @tycho.TextureFormat::RGBA8,
  )
  let rt_pool = RenderTargetPool::new(dev)

  let prim_pipe = dev.create_graphics_pipeline(
    @tycho.PipelineDesc::from_spirv(
      spv_prim2d_vert,
      spv_prim2d_frag,
      blend_mode=Some(@tycho.BlendMode::Premultiplied),
      cull_mode=@tycho.CullMode::None,
      color_format=Some(@tycho.TextureFormat::RGBA8),
      depth_format=Some(@tycho.TextureFormat::Depth24Stencil8),
    ),
  )
  let st_test_clip = @tycho.StencilState::new(
    front=@tycho.StencilFaceState::new(compare_op=@tycho.CompareOp::Equal),
    back=@tycho.StencilFaceState::new(compare_op=@tycho.CompareOp::Equal),
    compare_mask=(0x80 : UInt32),
    write_mask=(0 : UInt32),
    reference=(128 : UInt32),
  )
  let prim_clip_pipe = make_rhi_stencil_pipeline(
    dev,
    spv_prim2d_vert,
    spv_prim2d_frag,
    st_test_clip,
    true,
    @tycho.BlendMode::Premultiplied,
  )

  let st_nz = @tycho.StencilState::new(
    front=@tycho.StencilFaceState::new(
      pass_op=@tycho.StencilOp::IncrementAndWrap,
      compare_op=@tycho.CompareOp::Always,
    ),
    back=@tycho.StencilFaceState::new(
      pass_op=@tycho.StencilOp::DecrementAndWrap,
      compare_op=@tycho.CompareOp::Always,
    ),
    compare_mask=(0x7F : UInt32),
    write_mask=(0x7F : UInt32),
    reference=(0 : UInt32),
  )
  let stencil_nz_pipe = make_rhi_stencil_pipeline(
    dev,
    spv_path_stencil_vert,
    spv_path_stencil_frag,
    st_nz,
    false,
    @tycho.BlendMode::Opaque,
  )

  let st_eo = @tycho.StencilState::new(
    front=@tycho.StencilFaceState::new(
      pass_op=@tycho.StencilOp::Invert,
      compare_op=@tycho.CompareOp::Always,
    ),
    back=@tycho.StencilFaceState::new(
      pass_op=@tycho.StencilOp::Invert,
      compare_op=@tycho.CompareOp::Always,
    ),
    compare_mask=(0x7F : UInt32),
    write_mask=(0x7F : UInt32),
    reference=(0 : UInt32),
  )
  let stencil_eo_pipe = make_rhi_stencil_pipeline(
    dev,
    spv_path_stencil_vert,
    spv_path_stencil_frag,
    st_eo,
    false,
    @tycho.BlendMode::Opaque,
  )

  let st_clip_wr = @tycho.StencilState::new(
    front=@tycho.StencilFaceState::new(
      pass_op=@tycho.StencilOp::Replace,
      compare_op=@tycho.CompareOp::Always,
    ),
    back=@tycho.StencilFaceState::new(
      pass_op=@tycho.StencilOp::Replace,
      compare_op=@tycho.CompareOp::Always,
    ),
    compare_mask=(0x80 : UInt32),
    write_mask=(0x80 : UInt32),
    reference=(128 : UInt32),
  )
  let stencil_clip_pipe = make_rhi_stencil_pipeline(
    dev,
    spv_path_stencil_vert,
    spv_path_stencil_frag,
    st_clip_wr,
    false,
    @tycho.BlendMode::Opaque,
  )

  let st_cover = @tycho.StencilState::new(
    front=@tycho.StencilFaceState::new(
      pass_op=@tycho.StencilOp::Zero,
      fail_op=@tycho.StencilOp::Zero,
      depth_fail_op=@tycho.StencilOp::Zero,
      compare_op=@tycho.CompareOp::NotEqual,
    ),
    back=@tycho.StencilFaceState::new(
      pass_op=@tycho.StencilOp::Zero,
      fail_op=@tycho.StencilOp::Zero,
      depth_fail_op=@tycho.StencilOp::Zero,
      compare_op=@tycho.CompareOp::NotEqual,
    ),
    compare_mask=(0x7F : UInt32),
    write_mask=(0x7F : UInt32),
    reference=(0 : UInt32),
  )
  let path_cover_pipe = make_rhi_stencil_pipeline(
    dev,
    spv_path_cover_vert,
    spv_path_cover_frag,
    st_cover,
    true,
    @tycho.BlendMode::Premultiplied,
  )

  // When bit 0x80 is active, pass where stencil > 128 (meaning bit 0x80 set AND lower 7 bits != 0),
  // and clear lower 7 bits back to 0 via Replace(128) with write_mask = 0x7F.
  let st_cover_clip = @tycho.StencilState::new(
    front=@tycho.StencilFaceState::new(
      pass_op=@tycho.StencilOp::Replace,
      fail_op=@tycho.StencilOp::Replace,
      depth_fail_op=@tycho.StencilOp::Replace,
      compare_op=@tycho.CompareOp::Less,
    ),
    back=@tycho.StencilFaceState::new(
      pass_op=@tycho.StencilOp::Replace,
      fail_op=@tycho.StencilOp::Replace,
      depth_fail_op=@tycho.StencilOp::Replace,
      compare_op=@tycho.CompareOp::Less,
    ),
    compare_mask=(0xFF : UInt32),
    write_mask=(0x7F : UInt32),
    reference=(128 : UInt32),
  )
  let path_cover_clip_pipe = make_rhi_stencil_pipeline(
    dev,
    spv_path_cover_vert,
    spv_path_cover_frag,
    st_cover_clip,
    true,
    @tycho.BlendMode::Premultiplied,
  )

  let stroke_pipe = dev.create_graphics_pipeline(
    @tycho.PipelineDesc::from_spirv(
      spv_path_cover_vert,
      spv_path_cover_frag,
      blend_mode=Some(@tycho.BlendMode::Premultiplied),
      cull_mode=@tycho.CullMode::None,
      color_format=Some(@tycho.TextureFormat::RGBA8),
      depth_format=Some(@tycho.TextureFormat::Depth24Stencil8),
    ),
  )
  let stroke_clip_pipe = make_rhi_stencil_pipeline(
    dev,
    spv_path_cover_vert,
    spv_path_cover_frag,
    st_test_clip,
    true,
    @tycho.BlendMode::Premultiplied,
  )

  let composite_ds_pipe = dev.create_graphics_pipeline(
    @tycho.PipelineDesc::from_spirv(
      spv_blur_vert,
      spv_blur_frag,
      blend_mode=Some(@tycho.BlendMode::Premultiplied),
      cull_mode=@tycho.CullMode::None,
      color_format=Some(@tycho.TextureFormat::RGBA8),
      depth_format=Some(@tycho.TextureFormat::Depth24Stencil8),
    ),
  )
  let composite_ds_dstin_pipe = dev.create_graphics_pipeline(
    @tycho.PipelineDesc::from_spirv(
      spv_blur_vert,
      spv_blur_frag,
      blend_mode=Some(@tycho.BlendMode::DstIn),
      cull_mode=@tycho.CullMode::None,
      color_format=Some(@tycho.TextureFormat::RGBA8),
      depth_format=Some(@tycho.TextureFormat::Depth24Stencil8),
    ),
  )
  let composite_ds_srcin_pipe = dev.create_graphics_pipeline(
    @tycho.PipelineDesc::from_spirv(
      spv_blur_vert,
      spv_blur_frag,
      blend_mode=Some(@tycho.BlendMode::SrcIn),
      cull_mode=@tycho.CullMode::None,
      color_format=Some(@tycho.TextureFormat::RGBA8),
      depth_format=Some(@tycho.TextureFormat::Depth24Stencil8),
    ),
  )
  let composite_ds_mul_pipe = dev.create_graphics_pipeline(
    @tycho.PipelineDesc::from_spirv(
      spv_blur_vert,
      spv_blur_frag,
      blend_mode=Some(@tycho.BlendMode::Multiply),
      cull_mode=@tycho.CullMode::None,
      color_format=Some(@tycho.TextureFormat::RGBA8),
      depth_format=Some(@tycho.TextureFormat::Depth24Stencil8),
    ),
  )
  let blur_pipe = dev.create_graphics_pipeline(
    @tycho.PipelineDesc::from_spirv(
      spv_blur_vert,
      spv_blur_frag,
      blend_mode=Some(@tycho.BlendMode::Opaque),
      cull_mode=@tycho.CullMode::None,
      color_format=Some(@tycho.TextureFormat::RGBA8),
    ),
  )
  let present_pipe = dev.create_graphics_pipeline(
    @tycho.PipelineDesc::from_spirv(
      spv_blur_vert,
      spv_blur_frag,
      blend_mode=Some(@tycho.BlendMode::Opaque),
      cull_mode=@tycho.CullMode::None,
      color_format=Some(@tycho.TextureFormat::RGBA8),
    ),
  )

  let prim_ssbo = dev.create_buffer_with(
    2 * max_prims_per_frame * PRIM_BYTES,
    @tycho.BufferKind::Storage,
    location=@tycho.MemoryLocation::CpuToGpu,
  )
  let grad_ssbo = dev.create_buffer_with(
    2 * max_stops_per_frame * STOP_BYTES,
    @tycho.BufferKind::Storage,
    location=@tycho.MemoryLocation::CpuToGpu,
  )
  let path_vbuf = dev.create_buffer_with(
    2 * max_path_verts_per_frame * PATH_VERT_BYTES,
    @tycho.BufferKind::Vertex,
    location=@tycho.MemoryLocation::CpuToGpu,
  )

  {
    dev,
    sampler,
    glyph_cache,
    color_atlas,
    rt_pool,
    uploaded_images: {},
    prim_pipe,
    prim_clip_pipe,
    stencil_nz_pipe,
    stencil_eo_pipe,
    stencil_clip_pipe,
    path_cover_pipe,
    path_cover_clip_pipe,
    stroke_pipe,
    stroke_clip_pipe,
    composite_ds_pipe,
    composite_ds_dstin_pipe,
    composite_ds_srcin_pipe,
    composite_ds_mul_pipe,
    blur_pipe,
    present_pipe,
    present_sc_pipe: None,
    present_sc_fmt: None,
    max_prims: max_prims_per_frame,
    max_stops: max_stops_per_frame,
    max_path_verts: max_path_verts_per_frame,
    prim_ssbo,
    grad_ssbo,
    path_vbuf,
    prim_scratch: FixedArray::make(PRIM_FLOATS, (0.0 : Float)),
    stop_scratch: FixedArray::make(STOP_FLOATS, (0.0 : Float)),
    path_scratch: FixedArray::make(max_path_verts_per_frame * PATH_VERT_FLOATS, (0.0 : Float)),
    frame_idx: 0,
    prim_cursor: 0,
    prim_batch_start: 0,
    stop_cursor: 0,
    path_cursor: 0,
    cur_transform: Matrix3::identity(),
    cur_scissor: Rect::zero(),
    cur_clip_rrect: None,
    has_stencil_clip: false,
    active_tex: None,
    active_ds: None,
    active_w: 0,
    active_h: 0,
    state_stack: [],
  }
}

///|
pub fn Renderer2D::destroy(self : Renderer2D) -> Unit {
  self.prim_pipe.destroy()
  self.prim_clip_pipe.destroy()
  self.stencil_nz_pipe.destroy()
  self.stencil_eo_pipe.destroy()
  self.stencil_clip_pipe.destroy()
  self.path_cover_pipe.destroy()
  self.path_cover_clip_pipe.destroy()
  self.stroke_pipe.destroy()
  self.stroke_clip_pipe.destroy()
  self.composite_ds_pipe.destroy()
  self.composite_ds_dstin_pipe.destroy()
  self.composite_ds_srcin_pipe.destroy()
  self.composite_ds_mul_pipe.destroy()
  self.blur_pipe.destroy()
  self.present_pipe.destroy()
  match self.present_sc_pipe {
    Some(p) => p.destroy()
    None => ()
  }
  self.prim_ssbo.destroy()
  self.grad_ssbo.destroy()
  self.path_vbuf.destroy()
  self.rt_pool.destroy()
  self.glyph_cache.destroy()
  self.color_atlas.destroy()
  self.sampler.destroy()
}

///|
fn Renderer2D::slot_prim_base(self : Renderer2D) -> Int {
  (self.frame_idx % 2) * self.max_prims * PRIM_BYTES
}

///|
fn Renderer2D::slot_stop_base(self : Renderer2D) -> Int {
  (self.frame_idx % 2) * self.max_stops * STOP_BYTES
}

///|
fn Renderer2D::slot_path_base(self : Renderer2D) -> Int {
  (self.frame_idx % 2) * self.max_path_verts * PATH_VERT_BYTES
}

///|
fn tile_mode_float(m : TileMode) -> Float {
  match m {
    TileMode::Clamp => (0.0 : Float)
    TileMode::Repeat => (1.0 : Float)
    TileMode::Mirror => (2.0 : Float)
    TileMode::Decal => (0.0 : Float)
  }
}

///|
fn Renderer2D::push_gradient_stops(
  self : Renderer2D,
  stops : Array[GradientStop],
) -> (Float, Float) raise @tycho.RhiError {
  if stops.length() == 0 {
    return ((0.0 : Float), (0.0 : Float))
  }
  let avail = self.max_stops - self.stop_cursor
  let cnt = if stops.length() > avail { avail } else { stops.length() }
  if cnt <= 0 {
    return ((0.0 : Float), (0.0 : Float))
  }
  let start_idx = self.stop_cursor
  let base_bytes = self.slot_stop_base() + start_idx * STOP_BYTES
  for i = 0; i < cnt; i = i + 1 {
    let st = stops[i]
    self.stop_scratch[0] = st.color.r
    self.stop_scratch[1] = st.color.g
    self.stop_scratch[2] = st.color.b
    self.stop_scratch[3] = st.color.a
    self.stop_scratch[4] = st.offset
    self.stop_scratch[5] = (0.0 : Float)
    self.stop_scratch[6] = (0.0 : Float)
    self.stop_scratch[7] = (0.0 : Float)
    self.grad_ssbo.upload_floats(
      self.stop_scratch,
      offset=base_bytes + i * STOP_BYTES,
      count=STOP_FLOATS,
    )
  }
  self.stop_cursor = start_idx + cnt
  (Float::from_int(start_idx), Float::from_int(cnt))
}

///|
fn Renderer2D::resolve_paint_shader(
  self : Renderer2D,
  paint : Paint,
) -> (Color, Float, Float, Float, Float, Float, Float, Float, Float) raise @tycho.RhiError {
  match paint.shader {
    None =>
      (
        paint.color,
        (0.0 : Float),
        (0.0 : Float),
        (0.0 : Float),
        (0.0 : Float),
        (0.0 : Float),
        (0.0 : Float),
        (0.0 : Float),
        (0.0 : Float),
      )
    Some(Shader2D::Solid(col)) =>
      (
        col,
        (0.0 : Float),
        (0.0 : Float),
        (0.0 : Float),
        (0.0 : Float),
        (0.0 : Float),
        (0.0 : Float),
        (0.0 : Float),
        (0.0 : Float),
      )
    Some(Shader2D::LinearGradient(p0, p1, stops, tile)) => {
      let (soff, scnt) = self.push_gradient_stops(stops)
      let c0 = if stops.length() > 0 { stops[0].color } else { paint.color }
      (c0, (1.0 : Float), tile_mode_float(tile), p0.x, p0.y, p1.x, p1.y, soff, scnt)
    }
    Some(Shader2D::RadialGradient(center, radius, stops, tile)) => {
      let (soff, scnt) = self.push_gradient_stops(stops)
      let c0 = if stops.length() > 0 { stops[0].color } else { paint.color }
      (
        c0,
        (2.0 : Float),
        tile_mode_float(tile),
        center.x,
        center.y,
        radius,
        (0.0 : Float),
        soff,
        scnt,
      )
    }
    Some(Shader2D::SweepGradient(center, a0, a1, stops, tile)) => {
      let (soff, scnt) = self.push_gradient_stops(stops)
      let c0 = if stops.length() > 0 { stops[0].color } else { paint.color }
      (c0, (3.0 : Float), tile_mode_float(tile), center.x, center.y, a0, a1, soff, scnt)
    }
    Some(Shader2D::ImagePattern(_img, _m, _f, _tx, _ty)) =>
      (
        paint.color,
        (0.0 : Float),
        (0.0 : Float),
        (0.0 : Float),
        (0.0 : Float),
        (0.0 : Float),
        (0.0 : Float),
        (0.0 : Float),
        (0.0 : Float),
      )
  }
}

///|
fn Renderer2D::emit_prim(
  self : Renderer2D,
  rx : Float,
  ry : Float,
  rw : Float,
  rh : Float,
  tl : Float,
  tr : Float,
  br : Float,
  bl : Float,
  fill : Color,
  border : Color,
  u0 : Float,
  v0 : Float,
  u1 : Float,
  v1 : Float,
  bw : Float,
  soft : Float,
  kind : Float,
  stroke_only : Float,
  grad_type : Float,
  tile_mode : Float,
  gp0 : Float,
  gp1 : Float,
  gp2 : Float,
  gp3 : Float,
  stop_off : Float,
  stop_cnt : Float,
) -> Unit raise @tycho.RhiError {
  if self.prim_cursor >= self.max_prims {
    return
  }
  let p = self.prim_scratch
  let xf = self.cur_transform
  p[0] = rx
  p[1] = ry
  p[2] = rw
  p[3] = rh
  p[4] = tl
  p[5] = tr
  p[6] = br
  p[7] = bl
  p[8] = fill.r
  p[9] = fill.g
  p[10] = fill.b
  p[11] = fill.a
  p[12] = border.r
  p[13] = border.g
  p[14] = border.b
  p[15] = border.a
  p[16] = u0
  p[17] = v0
  p[18] = u1
  p[19] = v1
  p[20] = bw
  p[21] = soft
  p[22] = kind
  p[23] = stroke_only
  p[24] = xf.a
  p[25] = xf.c
  p[26] = xf.tx
  p[27] = grad_type
  p[28] = xf.b
  p[29] = xf.d
  p[30] = xf.ty
  p[31] = tile_mode
  p[32] = gp0
  p[33] = gp1
  p[34] = gp2
  p[35] = gp3
  p[36] = stop_off
  p[37] = stop_cnt
  p[38] = (0.0 : Float)
  p[39] = (0.0 : Float)
  let off = self.slot_prim_base() + self.prim_cursor * PRIM_BYTES
  self.prim_ssbo.upload_floats(self.prim_scratch, offset=off, count=PRIM_FLOATS)
  self.prim_cursor = self.prim_cursor + 1
}

///|
fn Renderer2D::flush_prims(self : Renderer2D, cmd : @tycho.CommandBuffer) -> Unit {
  let count = self.prim_cursor - self.prim_batch_start
  if count <= 0 || self.active_w <= 0 || self.active_h <= 0 {
    self.prim_batch_start = self.prim_cursor
    return
  }
  let pipe = if self.has_stencil_clip { self.prim_clip_pipe } else { self.prim_pipe }
  cmd.bind_pipeline(pipe)
  if self.has_stencil_clip {
    cmd.set_stencil_reference(128)
  }
  cmd.bind_storage(
    pipe,
    0,
    self.prim_ssbo,
    offset=self.slot_prim_base(),
    size=self.max_prims * PRIM_BYTES,
  )
  cmd.bind_storage(
    pipe,
    1,
    self.grad_ssbo,
    offset=self.slot_stop_base(),
    size=self.max_stops * STOP_BYTES,
  )
  cmd.bind_texture(pipe, 0, self.glyph_cache.atlas.texture, self.sampler)
  cmd.bind_texture(pipe, 1, self.color_atlas.texture, self.sampler)
  let fw = Float::from_int(self.active_w)
  let fh = Float::from_int(self.active_h)
  let (cx, cy, cw, ch, rtl, rtr, rbr, rbl) = match self.cur_clip_rrect {
    Some(rr) =>
      (rr.rect.x, rr.rect.y, rr.rect.width, rr.rect.height, rr.tl, rr.tr, rr.br, rr.bl)
    None =>
      (
        (0.0 : Float),
        (0.0 : Float),
        (-1.0 : Float),
        (-1.0 : Float),
        (0.0 : Float),
        (0.0 : Float),
        (0.0 : Float),
        (0.0 : Float),
      )
  }
  cmd.push_constants_floats(pipe, [
    fw,
    fh,
    (1.0 : Float) / fw,
    (1.0 : Float) / fh,
    cx,
    cy,
    cw,
    ch,
    rtl,
    rtr,
    rbr,
    rbl,
    (0.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
  ])
  cmd.set_scissor(
    self.cur_scissor.x.to_int(),
    self.cur_scissor.y.to_int(),
    self.cur_scissor.width.to_int(),
    self.cur_scissor.height.to_int(),
  )
  cmd.draw_instanced(6, count, 0, self.prim_batch_start)
  self.prim_batch_start = self.prim_cursor
}

///|
fn Renderer2D::ensure_image_uv(
  self : Renderer2D,
  img : Image2D,
) -> (Float, Float, Float, Float) raise @tycho.RhiError {
  match self.uploaded_images.get(img.id) {
    Some(uv) => return uv
    None => ()
  }
  let pixels = if img.pixels.length() > 0 {
    img.pixels
  } else {
    match img.texture {
      Some(tex) => {
        let raw = tex.readback()
        Bytes::from_array(raw[:])
      }
      None => b""
    }
  }
  if img.width <= 0 || img.height <= 0 || pixels.length() == 0 {
    return ((0.0 : Float), (0.0 : Float), (0.0 : Float), (0.0 : Float))
  }
  match self.color_atlas.alloc_and_upload(img.width, img.height, pixels) {
    Some((ax, ay)) => {
      let uv = self.color_atlas.uv_rect(ax, ay, img.width, img.height)
      self.uploaded_images[img.id] = uv
      uv
    }
    None => ((0.0 : Float), (0.0 : Float), (0.0 : Float), (0.0 : Float))
  }
}

///|
fn Renderer2D::upload_path_verts(
  self : Renderer2D,
  verts : Array[Float],
) -> (Int, Int) raise @tycho.RhiError {
  let n_verts = verts.length() / 2
  let avail = self.max_path_verts - self.path_cursor
  let use_verts = if n_verts > avail { avail } else { n_verts }
  if use_verts <= 0 {
    return (0, 0)
  }
  let n_floats = use_verts * 2
  for i = 0; i < n_floats; i = i + 1 {
    self.path_scratch[i] = verts[i]
  }
  let start_vert = self.path_cursor
  let byte_off = self.slot_path_base() + start_vert * PATH_VERT_BYTES
  self.path_vbuf.upload_floats(self.path_scratch, offset=byte_off, count=n_floats)
  self.path_cursor = start_vert + use_verts
  (start_vert, use_verts)
}

///|
fn path_cover_pc(
  w : Int,
  h : Int,
  paint : Paint,
) -> FixedArray[Float] {
  let fw = Float::from_int(w)
  let fh = Float::from_int(h)
  let mut c0 = paint.color
  let mut c1 = paint.color
  let mut gtype = (0.0 : Float)
  let mut tile = (0.0 : Float)
  let mut gp0 = (0.0 : Float)
  let mut gp1 = (0.0 : Float)
  let mut gp2 = (0.0 : Float)
  let mut gp3 = (0.0 : Float)
  match paint.shader {
    Some(Shader2D::Solid(col)) => c0 = col
    Some(Shader2D::LinearGradient(p0, p1, stops, t)) => {
      gtype = (1.0 : Float)
      tile = tile_mode_float(t)
      gp0 = p0.x
      gp1 = p0.y
      gp2 = p1.x
      gp3 = p1.y
      if stops.length() > 0 { c0 = stops[0].color }
      if stops.length() > 1 { c1 = stops[stops.length() - 1].color } else { c1 = c0 }
    }
    Some(Shader2D::RadialGradient(center, radius, stops, t)) => {
      gtype = (2.0 : Float)
      tile = tile_mode_float(t)
      gp0 = center.x
      gp1 = center.y
      gp2 = radius
      if stops.length() > 0 { c0 = stops[0].color }
      if stops.length() > 1 { c1 = stops[stops.length() - 1].color } else { c1 = c0 }
    }
    _ => ()
  }
  [
    fw,
    fh,
    (1.0 : Float) / fw,
    (1.0 : Float) / fh,
    c0.r,
    c0.g,
    c0.b,
    c0.a,
    c1.r,
    c1.g,
    c1.b,
    c1.a,
    gp0,
    gp1,
    gp2,
    gp3,
    gtype,
    tile,
    (0.0 : Float),
    (0.0 : Float),
  ]
}

///|
fn Renderer2D::draw_path_gpu(
  self : Renderer2D,
  cmd : @tycho.CommandBuffer,
  path : Path,
  paint : Paint,
) -> Unit raise @tycho.RhiError {
  self.flush_prims(cmd)
  let fw = Float::from_int(self.active_w)
  let fh = Float::from_int(self.active_h)
  cmd.set_scissor(
    self.cur_scissor.x.to_int(),
    self.cur_scissor.y.to_int(),
    self.cur_scissor.width.to_int(),
    self.cur_scissor.height.to_int(),
  )
  if paint.style == PaintStyle::Fill || paint.style == PaintStyle::StrokeAndFill {
    let (verts, bounds) = tessellate_fill_fan(path, self.cur_transform)
    let (vstart, vcnt) = self.upload_path_verts(verts)
    if vcnt >= 3 {
      let l = bounds.x
      let t = bounds.y
      let r = bounds.right()
      let b = bounds.bottom()
      let (cstart, ccnt) = self.upload_path_verts([l, t, r, t, r, b, l, t, r, b, l, b])
      let st_pipe = match path.fill_rule() {
        FillRule::NonZero => self.stencil_nz_pipe
        FillRule::EvenOdd => self.stencil_eo_pipe
      }
      cmd.bind_pipeline(st_pipe)
      cmd.bind_vertex(0, self.path_vbuf, offset=self.slot_path_base())
      cmd.push_constants_floats(st_pipe, [fw, fh, (1.0 : Float) / fw, (1.0 : Float) / fh])
      cmd.draw_instanced(vcnt, 1, vstart, 0)

      let cov_pipe = if self.has_stencil_clip {
        self.path_cover_clip_pipe
      } else {
        self.path_cover_pipe
      }
      cmd.bind_pipeline(cov_pipe)
      cmd.set_stencil_reference(if self.has_stencil_clip { 128 } else { 0 })
      cmd.bind_vertex(0, self.path_vbuf, offset=self.slot_path_base())
      cmd.push_constants_floats(cov_pipe, path_cover_pc(self.active_w, self.active_h, paint))
      cmd.draw_instanced(ccnt, 1, cstart, 0)
    }
  }
  if paint.style == PaintStyle::Stroke || paint.style == PaintStyle::StrokeAndFill {
    let verts = tessellate_stroke(
      path,
      self.cur_transform,
      paint.stroke_width,
      paint.stroke_cap,
      paint.stroke_join,
      paint.stroke_miter,
    )
    let (vstart, vcnt) = self.upload_path_verts(verts)
    if vcnt >= 3 {
      let spipe = if self.has_stencil_clip { self.stroke_clip_pipe } else { self.stroke_pipe }
      cmd.bind_pipeline(spipe)
      if self.has_stencil_clip {
        cmd.set_stencil_reference(128)
      }
      cmd.bind_vertex(0, self.path_vbuf, offset=self.slot_path_base())
      cmd.push_constants_floats(spipe, path_cover_pc(self.active_w, self.active_h, paint))
      cmd.draw_instanced(vcnt, 1, vstart, 0)
    }
  }
}

///|
fn Renderer2D::run_blur_passes(
  self : Renderer2D,
  cmd : @tycho.CommandBuffer,
  src : @tycho.Texture,
  src_w : Int,
  src_h : Int,
  sx : Float,
  sy : Float,
  src_u0? : Float = (0.0 : Float),
  src_v0? : Float = (0.0 : Float),
  src_u1? : Float = (1.0 : Float),
  src_v1? : Float = (1.0 : Float),
) -> (@tycho.Texture, Int, Int) raise @tycho.RhiError {
  let bw = if src_w / 2 > 1 { src_w / 2 } else { 1 }
  let bh = if src_h / 2 > 1 { src_h / 2 } else { 1 }
  let (tex_a, _) = self.rt_pool.acquire(bw, bh, with_depth_stencil=false)
  let (tex_b, _) = self.rt_pool.acquire(bw, bh, with_depth_stencil=false)
  let aw_f = Float::from_int(tex_a.width())
  let ah_f = Float::from_int(tex_a.height())
  let bw_norm = Float::from_int(bw) / aw_f
  let bh_norm = Float::from_int(bh) / ah_f
  let rad_x = clamp_f(sx * (0.25 : Float), (0.5 : Float), (4.0 : Float))
  let rad_y = clamp_f(sy * (0.25 : Float), (0.5 : Float), (4.0 : Float))

  // Horizontal pass into tex_a
  cmd.begin_render_pass([
    @tycho.RenderTargetDesc::new(
      tex_a,
      load_op=@tycho.LoadOp::Clear,
      store_op=@tycho.StoreOp::Store,
      clear_color=@tycho.ClearColor::rgba((0.0 : Float), (0.0 : Float), (0.0 : Float), (0.0 : Float)),
    ),
  ])
  cmd.set_viewport(0.0, 0.0, aw_f, ah_f)
  cmd.set_scissor(0, 0, bw, bh)
  cmd.bind_pipeline(self.blur_pipe)
  cmd.bind_texture(self.blur_pipe, 0, src, self.sampler)
  cmd.push_constants_floats(self.blur_pipe, [
    (0.0 : Float),
    (0.0 : Float),
    bw_norm,
    bh_norm,
    src_u0,
    src_v0,
    src_u1,
    src_v1,
    rad_x / Float::from_int(src.width()),
    (0.0 : Float),
    aw_f,
    (0.0 : Float),
    (1.0 : Float),
    (1.0 : Float),
    (1.0 : Float),
    (1.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (-1.0 : Float),
    (-1.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
  ])
  cmd.draw(6, 1)
  cmd.end_render_pass()

  // Vertical pass into tex_b
  let btex_w = Float::from_int(tex_b.width())
  let btex_h = Float::from_int(tex_b.height())
  cmd.begin_render_pass([
    @tycho.RenderTargetDesc::new(
      tex_b,
      load_op=@tycho.LoadOp::Clear,
      store_op=@tycho.StoreOp::Store,
      clear_color=@tycho.ClearColor::rgba((0.0 : Float), (0.0 : Float), (0.0 : Float), (0.0 : Float)),
    ),
  ])
  cmd.set_viewport(0.0, 0.0, btex_w, btex_h)
  cmd.set_scissor(0, 0, bw, bh)
  cmd.bind_pipeline(self.blur_pipe)
  cmd.bind_texture(self.blur_pipe, 0, tex_a, self.sampler)
  cmd.push_constants_floats(self.blur_pipe, [
    (0.0 : Float),
    (0.0 : Float),
    Float::from_int(bw) / btex_w,
    Float::from_int(bh) / btex_h,
    (0.0 : Float),
    (0.0 : Float),
    bw_norm,
    bh_norm,
    (0.0 : Float),
    rad_y / ah_f,
    btex_w,
    (0.0 : Float),
    (1.0 : Float),
    (1.0 : Float),
    (1.0 : Float),
    (1.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (-1.0 : Float),
    (-1.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
  ])
  cmd.draw(6, 1)
  cmd.end_render_pass()

  (tex_b, bw, bh)
}

///|
fn Renderer2D::begin_target_pass(
  self : Renderer2D,
  cmd : @tycho.CommandBuffer,
  tex : @tycho.Texture,
  ds : @tycho.Texture,
  logical_w : Int,
  logical_h : Int,
  load_op : @tycho.LoadOp,
  clear_color : Color,
  stencil_load_op : @tycho.LoadOp,
) -> Unit raise @tycho.RhiError {
  cmd.begin_render_pass(
    [
      @tycho.RenderTargetDesc::new(
        tex,
        load_op~,
        store_op=@tycho.StoreOp::Store,
        clear_color=clear_color.to_clear_color(),
      ),
    ],
    depth=Some(
      @tycho.DepthTargetDesc::new(
        ds,
        load_op=@tycho.LoadOp::DontCare,
        store_op=@tycho.StoreOp::DontCare,
        stencil_load_op~,
        stencil_store_op=@tycho.StoreOp::Store,
        clear_stencil=0,
      ),
    ),
  )
  cmd.set_viewport(
    (0.0 : Float),
    (0.0 : Float),
    Float::from_int(tex.width()),
    Float::from_int(tex.height()),
  )
  self.active_tex = Some(tex)
  self.active_ds = Some(ds)
  self.active_w = tex.width()
  self.active_h = tex.height()
  let _ = (logical_w, logical_h)
}

///|
fn Renderer2D::composite_texture(
  self : Renderer2D,
  cmd : @tycho.CommandBuffer,
  src : @tycho.Texture,
  src_u0 : Float,
  src_v0 : Float,
  src_u1 : Float,
  src_v1 : Float,
  dst_rect_px : Rect,
  tint : Color,
  blend_mode : BlendMode2D,
  clip_rrect : RRect?,
) -> Unit {
  let pipe = match blend_mode {
    BlendMode2D::DstIn => self.composite_ds_dstin_pipe
    BlendMode2D::SrcIn => self.composite_ds_srcin_pipe
    BlendMode2D::Multiply => self.composite_ds_mul_pipe
    _ => self.composite_ds_pipe
  }
  let aw_f = Float::from_int(self.active_w)
  let ah_f = Float::from_int(self.active_h)
  let (cx, cy, cw, ch, rtl, rtr, rbr, rbl) = match clip_rrect {
    Some(rr) =>
      (rr.rect.x, rr.rect.y, rr.rect.width, rr.rect.height, rr.tl, rr.tr, rr.br, rr.bl)
    None =>
      (
        (0.0 : Float),
        (0.0 : Float),
        (-1.0 : Float),
        (-1.0 : Float),
        (0.0 : Float),
        (0.0 : Float),
        (0.0 : Float),
        (0.0 : Float),
      )
  }
  cmd.set_scissor(
    self.cur_scissor.x.to_int(),
    self.cur_scissor.y.to_int(),
    self.cur_scissor.width.to_int(),
    self.cur_scissor.height.to_int(),
  )
  cmd.bind_pipeline(pipe)
  cmd.bind_texture(pipe, 0, src, self.sampler)
  cmd.push_constants_floats(pipe, [
    dst_rect_px.x / aw_f,
    dst_rect_px.y / ah_f,
    dst_rect_px.width / aw_f,
    dst_rect_px.height / ah_f,
    src_u0,
    src_v0,
    src_u1,
    src_v1,
    (0.0 : Float),
    (0.0 : Float),
    aw_f,
    (1.0 : Float),
    tint.r,
    tint.g,
    tint.b,
    tint.a,
    cx,
    cy,
    cw,
    ch,
    rtl,
    rtr,
    rbr,
    rbl,
  ])
  cmd.draw(6, 1)
}

///|
fn Renderer2D::replay_ops(
  self : Renderer2D,
  cmd : @tycho.CommandBuffer,
  ops : FixedArray[DrawOp],
) -> Unit raise @tycho.RhiError {
  for op in ops {
    match op {
      DrawOp::Clear(col) => {
        self.flush_prims(cmd)
        let prev_xf = self.cur_transform
        self.cur_transform = Matrix3::identity()
        self.emit_prim(
          (0.0 : Float),
          (0.0 : Float),
          Float::from_int(self.active_w),
          Float::from_int(self.active_h),
          (0.0 : Float),
          (0.0 : Float),
          (0.0 : Float),
          (0.0 : Float),
          col,
          col,
          (0.0 : Float),
          (0.0 : Float),
          (0.0 : Float),
          (0.0 : Float),
          (0.0 : Float),
          (0.0 : Float),
          (0.0 : Float),
          (0.0 : Float),
          (0.0 : Float),
          (0.0 : Float),
          (0.0 : Float),
          (0.0 : Float),
          (0.0 : Float),
          (0.0 : Float),
          (0.0 : Float),
          (0.0 : Float),
        )
        self.cur_transform = prev_xf
        self.flush_prims(cmd)
      }
      DrawOp::Save =>
        self.state_stack.push({
          transform: self.cur_transform,
          scissor: self.cur_scissor,
          clip_rrect: self.cur_clip_rrect,
          has_stencil_clip: self.has_stencil_clip,
          is_layer: false,
          layer_paint: Paint::new(),
          outer_tex: None,
          outer_ds: None,
          outer_w: 0,
          outer_h: 0,
        })
      DrawOp::SaveLayer(_bounds_opt, paint) => {
        self.flush_prims(cmd)
        let otex = self.active_tex
        let ods = self.active_ds
        let ow = self.active_w
        let oh = self.active_h
        self.state_stack.push({
          transform: self.cur_transform,
          scissor: self.cur_scissor,
          clip_rrect: self.cur_clip_rrect,
          has_stencil_clip: self.has_stencil_clip,
          is_layer: true,
          layer_paint: paint,
          outer_tex: otex,
          outer_ds: ods,
          outer_w: ow,
          outer_h: oh,
        })
        cmd.end_render_pass()
        let lw = self.cur_scissor.width.to_int()
        let lh = self.cur_scissor.height.to_int()
        let use_w = if lw > 0 { lw } else { 64 }
        let use_h = if lh > 0 { lh } else { 64 }
        let (ltex, lds_opt) = self.rt_pool.acquire(use_w, use_h, with_depth_stencil=true)
        let lds = lds_opt.unwrap()
        self.begin_target_pass(
          cmd,
          ltex,
          lds,
          ltex.width(),
          ltex.height(),
          @tycho.LoadOp::Clear,
          Color::transparent(),
          @tycho.LoadOp::Clear,
        )
        self.has_stencil_clip = false
      }
      DrawOp::SaveBackdropLayer(bounds, filter) => {
        self.flush_prims(cmd)
        self.state_stack.push({
          transform: self.cur_transform,
          scissor: self.cur_scissor,
          clip_rrect: self.cur_clip_rrect,
          has_stencil_clip: self.has_stencil_clip,
          is_layer: false,
          layer_paint: Paint::new(),
          outer_tex: None,
          outer_ds: None,
          outer_w: 0,
          outer_h: 0,
        })
        let otex = self.active_tex.unwrap()
        let ods = self.active_ds.unwrap()
        let screen_r = self.cur_transform
          .map_rect(bounds)
          .intersect(self.cur_scissor)
        if !screen_r.is_empty() {
          let (sx, sy) = match filter {
            ImageFilter::Blur(bx, by, _) => (bx, by)
            ImageFilter::DropShadow(_, _, bx, by, _) => (bx, by)
            _ => ((4.0 : Float), (4.0 : Float))
          }
          cmd.end_render_pass()
          let tw = Float::from_int(otex.width())
          let th = Float::from_int(otex.height())
          let (btex, bw, bh) = self.run_blur_passes(
            cmd,
            otex,
            screen_r.width.to_int(),
            screen_r.height.to_int(),
            sx,
            sy,
            src_u0=screen_r.x / tw,
            src_v0=screen_r.y / th,
            src_u1=screen_r.right() / tw,
            src_v1=screen_r.bottom() / th,
          )
          self.begin_target_pass(
            cmd,
            otex,
            ods,
            otex.width(),
            otex.height(),
            @tycho.LoadOp::Load,
            Color::transparent(),
            @tycho.LoadOp::Load,
          )
          let b_u1 = Float::from_int(bw) / Float::from_int(btex.width())
          let b_v1 = Float::from_int(bh) / Float::from_int(btex.height())
          self.composite_texture(
            cmd,
            btex,
            (0.0 : Float),
            (0.0 : Float),
            b_u1,
            b_v1,
            screen_r,
            Color::white(),
            BlendMode2D::SrcOver,
            self.cur_clip_rrect,
          )
        }
      }
      DrawOp::Restore =>
        match self.state_stack.pop() {
          Some(st) => {
            self.flush_prims(cmd)
            if st.is_layer {
              let ltex = self.active_tex.unwrap()
              cmd.end_render_pass()
              let mut draw_tex = ltex
              let mut src_u1 = (1.0 : Float)
              let mut src_v1 = (1.0 : Float)
              match st.layer_paint.image_filter {
                Some(ImageFilter::Blur(sx, sy, _)) => {
                  let lw = Float::from_int(ltex.width())
                  let lh = Float::from_int(ltex.height())
                  let (btex, bw, bh) = self.run_blur_passes(
                    cmd,
                    ltex,
                    st.scissor.width.to_int(),
                    st.scissor.height.to_int(),
                    sx,
                    sy,
                    src_u0=st.scissor.x / lw,
                    src_v0=st.scissor.y / lh,
                    src_u1=st.scissor.right() / lw,
                    src_v1=st.scissor.bottom() / lh,
                  )
                  draw_tex = btex
                  src_u1 = Float::from_int(bw) / Float::from_int(btex.width())
                  src_v1 = Float::from_int(bh) / Float::from_int(btex.height())
                }
                _ => ()
              }
              let otex = st.outer_tex.unwrap()
              let ods = st.outer_ds.unwrap()
              self.begin_target_pass(
                cmd,
                otex,
                ods,
                st.outer_w,
                st.outer_h,
                @tycho.LoadOp::Load,
                Color::transparent(),
                @tycho.LoadOp::Load,
              )
              self.cur_transform = st.transform
              self.cur_scissor = st.scissor
              self.cur_clip_rrect = st.clip_rrect
              self.has_stencil_clip = st.has_stencil_clip
              let (src_u0, src_v0) = match st.layer_paint.image_filter {
                Some(ImageFilter::Blur(_, _, _)) => ((0.0 : Float), (0.0 : Float))
                _ => {
                  let lw = Float::from_int(ltex.width())
                  let lh = Float::from_int(ltex.height())
                  src_u1 = st.scissor.right() / lw
                  src_v1 = st.scissor.bottom() / lh
                  (st.scissor.x / lw, st.scissor.y / lh)
                }
              }
              self.composite_texture(
                cmd,
                draw_tex,
                src_u0,
                src_v0,
                src_u1,
                src_v1,
                st.scissor,
                st.layer_paint.color,
                st.layer_paint.blend_mode,
                None,
              )
            } else {
              let had_stencil = self.has_stencil_clip
              self.cur_transform = st.transform
              self.cur_scissor = st.scissor
              self.cur_clip_rrect = st.clip_rrect
              self.has_stencil_clip = st.has_stencil_clip
              if had_stencil && !st.has_stencil_clip {
                // Re-clear stencil bit 0x80 via fast fullscreen pass? Only happens when leaving clip_path.
                ()
              }
            }
          }
          None => ()
        }
      DrawOp::Concat(m) => self.cur_transform = self.cur_transform.concat(m)
      DrawOp::ClipRect(r, _op) => {
        self.flush_prims(cmd)
        let mapped = self.cur_transform.map_rect(r)
        self.cur_scissor = self.cur_scissor.intersect(mapped)
      }
      DrawOp::ClipRRect(rr, _op) => {
        self.flush_prims(cmd)
        let mapped_r = self.cur_transform.map_rect(rr.rect)
        self.cur_scissor = self.cur_scissor.intersect(mapped_r)
        let sx = abs_f(self.cur_transform.a)
        self.cur_clip_rrect = Some({
          rect: mapped_r,
          tl: rr.tl * sx,
          tr: rr.tr * sx,
          br: rr.br * sx,
          bl: rr.bl * sx,
        })
      }
      DrawOp::ClipPath(path, _op) => {
        self.flush_prims(cmd)
        let (verts, _bounds) = tessellate_fill_fan(path, self.cur_transform)
        let (vstart, vcnt) = self.upload_path_verts(verts)
        if vcnt >= 3 {
          let fw = Float::from_int(self.active_w)
          let fh = Float::from_int(self.active_h)
          cmd.set_scissor(
            self.cur_scissor.x.to_int(),
            self.cur_scissor.y.to_int(),
            self.cur_scissor.width.to_int(),
            self.cur_scissor.height.to_int(),
          )
          cmd.bind_pipeline(self.stencil_clip_pipe)
          cmd.bind_vertex(0, self.path_vbuf, offset=self.slot_path_base())
          cmd.push_constants_floats(
            self.stencil_clip_pipe,
            [fw, fh, (1.0 : Float) / fw, (1.0 : Float) / fh],
          )
          cmd.draw_instanced(vcnt, 1, vstart, 0)
          self.has_stencil_clip = true
        }
      }
      DrawOp::DrawRect(r, paint) =>
        self.replay_ops(cmd, [DrawOp::DrawRRect(RRect::from_rect(r), paint)])
      DrawOp::DrawRRect(rr, paint) => {
        if paint.blend_mode != BlendMode2D::SrcOver {
          self.flush_prims(cmd)
        }
        let (fill_col, gt, tm, gp0, gp1, gp2, gp3, soff, scnt) = self.resolve_paint_shader(paint)
        let (bw, border_col, stroke_only) = match paint.style {
          PaintStyle::Fill => ((0.0 : Float), Color::transparent(), (0.0 : Float))
          PaintStyle::Stroke => (paint.stroke_width, paint.color, (1.0 : Float))
          PaintStyle::StrokeAndFill => (paint.stroke_width, paint.color, (0.0 : Float))
        }
        self.emit_prim(
          rr.rect.x,
          rr.rect.y,
          rr.rect.width,
          rr.rect.height,
          rr.tl,
          rr.tr,
          rr.br,
          rr.bl,
          fill_col,
          border_col,
          (0.0 : Float),
          (0.0 : Float),
          (0.0 : Float),
          (0.0 : Float),
          bw,
          (0.0 : Float),
          (0.0 : Float),
          stroke_only,
          gt,
          tm,
          gp0,
          gp1,
          gp2,
          gp3,
          soff,
          scnt,
        )
      }
      DrawOp::DrawCircle(center, radius, paint) => {
        let (fill_col, gt, tm, gp0, gp1, gp2, gp3, soff, scnt) = self.resolve_paint_shader(paint)
        let (bw, border_col, stroke_only) = match paint.style {
          PaintStyle::Fill => ((0.0 : Float), Color::transparent(), (0.0 : Float))
          PaintStyle::Stroke => (paint.stroke_width, paint.color, (1.0 : Float))
          PaintStyle::StrokeAndFill => (paint.stroke_width, paint.color, (0.0 : Float))
        }
        let d = radius * (2.0 : Float)
        self.emit_prim(
          center.x - radius,
          center.y - radius,
          d,
          d,
          radius,
          radius,
          radius,
          radius,
          fill_col,
          border_col,
          (0.0 : Float),
          (0.0 : Float),
          (0.0 : Float),
          (0.0 : Float),
          bw,
          (0.0 : Float),
          (4.0 : Float),
          stroke_only,
          gt,
          tm,
          gp0,
          gp1,
          gp2,
          gp3,
          soff,
          scnt,
        )
      }
      DrawOp::DrawLine(p0, p1, paint) => {
        let (fill_col, gt, tm, gp0, gp1, gp2, gp3, soff, scnt) = self.resolve_paint_shader(paint)
        self.emit_prim(
          p0.x,
          p0.y,
          p1.x,
          p1.y,
          p0.x,
          p0.y,
          p1.x,
          p1.y,
          fill_col,
          Color::transparent(),
          (0.0 : Float),
          (0.0 : Float),
          (0.0 : Float),
          (0.0 : Float),
          max_f((0.5 : Float), paint.stroke_width * (0.5 : Float)),
          (0.0 : Float),
          (5.0 : Float),
          (0.0 : Float),
          gt,
          tm,
          gp0,
          gp1,
          gp2,
          gp3,
          soff,
          scnt,
        )
      }
      DrawOp::DrawRRectShadow(rr, dx, dy, blur, spread, col) => {
        let r = rr.rect.offset(dx, dy).inflate(spread)
        let tl = if rr.tl > (0.0 : Float) { max_f((0.0 : Float), rr.tl + spread) } else { (0.0 : Float) }
        let tr = if rr.tr > (0.0 : Float) { max_f((0.0 : Float), rr.tr + spread) } else { (0.0 : Float) }
        let br = if rr.br > (0.0 : Float) { max_f((0.0 : Float), rr.br + spread) } else { (0.0 : Float) }
        let bl = if rr.bl > (0.0 : Float) { max_f((0.0 : Float), rr.bl + spread) } else { (0.0 : Float) }
        self.emit_prim(
          r.x,
          r.y,
          r.width,
          r.height,
          tl,
          tr,
          br,
          bl,
          col,
          Color::transparent(),
          (0.0 : Float),
          (0.0 : Float),
          (0.0 : Float),
          (0.0 : Float),
          (0.0 : Float),
          max_f((1.0 : Float), blur),
          (1.0 : Float),
          (0.0 : Float),
          (0.0 : Float),
          (0.0 : Float),
          (0.0 : Float),
          (0.0 : Float),
          (0.0 : Float),
          (0.0 : Float),
          (0.0 : Float),
          (0.0 : Float),
        )
      }
      DrawOp::DrawPath(path, paint) => self.draw_path_gpu(cmd, path, paint)
      DrawOp::DrawImage(img, src, dst, paint) => {
        let (u0, v0, u1, v1) = self.ensure_image_uv(img)
        let iw = Float::from_int(if img.width > 0 { img.width } else { 1 })
        let ih = Float::from_int(if img.height > 0 { img.height } else { 1 })
        let su0 = u0 + (u1 - u0) * (src.x / iw)
        let sv0 = v0 + (v1 - v0) * (src.y / ih)
        let su1 = u0 + (u1 - u0) * (src.right() / iw)
        let sv1 = v0 + (v1 - v0) * (src.bottom() / ih)
        self.emit_prim(
          dst.x,
          dst.y,
          dst.width,
          dst.height,
          (0.0 : Float),
          (0.0 : Float),
          (0.0 : Float),
          (0.0 : Float),
          paint.color,
          Color::transparent(),
          su0,
          sv0,
          su1,
          sv1,
          (0.0 : Float),
          (0.0 : Float),
          (2.0 : Float),
          (0.0 : Float),
          (0.0 : Float),
          (0.0 : Float),
          (0.0 : Float),
          (0.0 : Float),
          (0.0 : Float),
          (0.0 : Float),
          (0.0 : Float),
          (0.0 : Float),
        )
      }
      DrawOp::DrawParagraph(para, pos) => {
        para.layout((1.0e9 : Float))
        for g in para.placed_glyphs() {
          let ge = self.glyph_cache.get_or_rasterize(g.font, g.codepoint, g.font_size)
          if ge.width > 0 && ge.height > 0 {
            let gx = pos.x + g.x + Float::from_int(ge.offset_x)
            let gy = pos.y + g.baseline_y + Float::from_int(ge.offset_y)
            self.emit_prim(
              gx,
              gy,
              Float::from_int(ge.width),
              Float::from_int(ge.height),
              (0.0 : Float),
              (0.0 : Float),
              (0.0 : Float),
              (0.0 : Float),
              g.color,
              Color::transparent(),
              ge.uv_x0,
              ge.uv_y0,
              ge.uv_x1,
              ge.uv_y1,
              (0.0 : Float),
              (0.0 : Float),
              (3.0 : Float),
              (0.0 : Float),
              (0.0 : Float),
              (0.0 : Float),
              (0.0 : Float),
              (0.0 : Float),
              (0.0 : Float),
              (0.0 : Float),
              (0.0 : Float),
              (0.0 : Float),
            )
          }
        }
        for ul in para.underline_rects() {
          let (ux, uy, uw, uh, ucol) = ul
          self.emit_prim(
            pos.x + ux,
            pos.y + uy,
            uw,
            uh,
            (0.0 : Float),
            (0.0 : Float),
            (0.0 : Float),
            (0.0 : Float),
            ucol,
            Color::transparent(),
            (0.0 : Float),
            (0.0 : Float),
            (0.0 : Float),
            (0.0 : Float),
            (0.0 : Float),
            (0.0 : Float),
            (0.0 : Float),
            (0.0 : Float),
            (0.0 : Float),
            (0.0 : Float),
            (0.0 : Float),
            (0.0 : Float),
            (0.0 : Float),
            (0.0 : Float),
            (0.0 : Float),
            (0.0 : Float),
          )
        }
      }
      DrawOp::DrawDisplayList(sub) => self.replay_ops(cmd, sub.ops)
    }
  }
}

///|
fn Renderer2D::render_into_scene(
  self : Renderer2D,
  cmd : @tycho.CommandBuffer,
  dl : DisplayList,
  width : Int,
  height : Int,
  clear_color : Color,
) -> @tycho.Texture raise @tycho.RhiError {
  self.rt_pool.release_all()
  let (scene_tex, scene_ds_opt) = self.rt_pool.acquire(
    width,
    height,
    with_depth_stencil=true,
  )
  let scene_ds = scene_ds_opt.unwrap()
  self.prim_cursor = 0
  self.prim_batch_start = 0
  self.stop_cursor = 0
  self.path_cursor = 0
  self.cur_transform = Matrix3::identity()
  self.cur_scissor = Rect::new(
    (0.0 : Float),
    (0.0 : Float),
    Float::from_int(width),
    Float::from_int(height),
  )
  self.cur_clip_rrect = None
  self.has_stencil_clip = false
  self.state_stack.clear()

  self.begin_target_pass(
    cmd,
    scene_tex,
    scene_ds,
    width,
    height,
    @tycho.LoadOp::Clear,
    clear_color,
    @tycho.LoadOp::Clear,
  )
  self.replay_ops(cmd, dl.ops)
  self.flush_prims(cmd)
  cmd.end_render_pass()
  scene_tex
}

///|
pub fn Renderer2D::render_offscreen(
  self : Renderer2D,
  dl : DisplayList,
  target : @tycho.Texture,
  clear_color? : Color = Color::transparent(),
) -> Unit raise @tycho.RhiError {
  self.frame_idx = self.frame_idx + 1
  let w = target.width()
  let h = target.height()
  let cmd = self.dev.begin_commands()
  let scene_tex = self.render_into_scene(cmd, dl, w, h, clear_color)
  let u1 = Float::from_int(w) / Float::from_int(scene_tex.width())
  let v1 = Float::from_int(h) / Float::from_int(scene_tex.height())
  cmd.begin_render_pass([
    @tycho.RenderTargetDesc::new(
      target,
      load_op=@tycho.LoadOp::Clear,
      store_op=@tycho.StoreOp::Store,
      clear_color=clear_color.to_clear_color(),
    ),
  ])
  cmd.set_viewport((0.0 : Float), (0.0 : Float), Float::from_int(w), Float::from_int(h))
  cmd.set_scissor(0, 0, w, h)
  cmd.bind_pipeline(self.present_pipe)
  cmd.bind_texture(self.present_pipe, 0, scene_tex, self.sampler)
  cmd.push_constants_floats(self.present_pipe, [
    (0.0 : Float),
    (0.0 : Float),
    (1.0 : Float),
    (1.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    u1,
    v1,
    (0.0 : Float),
    (0.0 : Float),
    Float::from_int(w),
    (1.0 : Float),
    (1.0 : Float),
    (1.0 : Float),
    (1.0 : Float),
    (1.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (-1.0 : Float),
    (-1.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
  ])
  cmd.draw(6, 1)
  cmd.end_render_pass()
  self.dev.end_commands(cmd)
}

///|
pub fn Renderer2D::render_swapchain(
  self : Renderer2D,
  sc : @tycho.Swapchain,
  dl : DisplayList,
  clear_color? : Color = Color::black(),
) -> Unit raise @tycho.RhiError {
  self.frame_idx = self.frame_idx + 1
  let fmt = sc.color_format()
  let sc_pipe = match self.present_sc_pipe {
    Some(p) =>
      if self.present_sc_fmt == Some(fmt) {
        p
      } else {
        p.destroy()
        let np = self.dev.create_graphics_pipeline(
          @tycho.PipelineDesc::from_spirv(
            spv_blur_vert,
            spv_blur_frag,
            blend_mode=Some(@tycho.BlendMode::Opaque),
            cull_mode=@tycho.CullMode::None,
            color_format=Some(fmt),
          ),
        )
        self.present_sc_pipe = Some(np)
        self.present_sc_fmt = Some(fmt)
        np
      }
    None => {
      let np = self.dev.create_graphics_pipeline(
        @tycho.PipelineDesc::from_spirv(
          spv_blur_vert,
          spv_blur_frag,
          blend_mode=Some(@tycho.BlendMode::Opaque),
          cull_mode=@tycho.CullMode::None,
          color_format=Some(fmt),
        ),
      )
      self.present_sc_pipe = Some(np)
      self.present_sc_fmt = Some(fmt)
      np
    }
  }
  let cmd = sc.begin_frame_commands()
  let w = sc.width()
  let h = sc.height()
  let scene_tex = self.render_into_scene(cmd, dl, w, h, clear_color)
  let u1 = Float::from_int(w) / Float::from_int(scene_tex.width())
  let v1 = Float::from_int(h) / Float::from_int(scene_tex.height())
  cmd.begin_swapchain_pass(
    sc,
    load_op=@tycho.LoadOp::Clear,
    clear_color=Some(clear_color.to_clear_color()),
  )
  cmd.set_viewport((0.0 : Float), (0.0 : Float), Float::from_int(w), Float::from_int(h))
  cmd.set_scissor(0, 0, w, h)
  cmd.bind_pipeline(sc_pipe)
  cmd.bind_texture(sc_pipe, 0, scene_tex, self.sampler)
  cmd.push_constants_floats(sc_pipe, [
    (0.0 : Float),
    (0.0 : Float),
    (1.0 : Float),
    (1.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    u1,
    v1,
    (0.0 : Float),
    (0.0 : Float),
    Float::from_int(w),
    (1.0 : Float),
    (1.0 : Float),
    (1.0 : Float),
    (1.0 : Float),
    (1.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (-1.0 : Float),
    (-1.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
  ])
  cmd.draw(6, 1)
  cmd.end_swapchain_pass()
  sc.end_frame(cmd)
}
