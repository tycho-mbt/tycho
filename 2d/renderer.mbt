// GPU Renderer2D over laplaceliu/tycho RHI (AOT pipelines, Tier-1 SDF/Atlas batching,
// Tier-2 Stencil-then-Cover + Stroker, Tier-3 SaveLayer / BackdropFilter Gaussian Blur).

const PRIM_FLOATS : Int = 48
const PRIM_BYTES : Int = 192
const STOP_FLOATS : Int = 8
const STOP_BYTES : Int = 32
const PATH_VERT_FLOATS : Int = 2
const PATH_VERT_BYTES : Int = 8

// Custom vertex mesh: position (2f) + color (4f) + uv (2f).
const VERT_FLOATS : Int = 8
const VERT_BYTES : Int = 32
const MAX_VERTS_PER_FRAME : Int = 16384
const MAX_INDICES_PER_FRAME : Int = 32768

///|
priv struct RenderSaveState {
  transform : Matrix3
  scissor : Rect
  clip_rrect : RRect?
  has_stencil_clip : Bool
  is_layer : Bool
  layer_paint : Paint
  // Screen-space pixel rect backing the layer render target (logical size,
  // not the 64px-bucketed texture size). Empty when the layer has no content.
  layer_rect : Rect
  layer_empty : Bool
  outer_tex : @tycho.Texture?
  outer_ds : @tycho.Texture?
  outer_w : Int
  outer_h : Int
}

///|
priv struct CachedColorGlyph {
  font_id : Int
  cp : Int
  q4 : Int
  uv0 : Float
  uv1 : Float
  uv2 : Float
  uv3 : Float
  width : Int
  height : Int
  bearing_x : Int
  bearing_y : Int
  ppem : Int
  mut last_frame : Int
}

///|
// A CPU-rasterized coverage bitmap cached in the shared R8 atlas. UVs are
// invalidated when the atlas generation changes (compaction/reset).
priv struct CachedCoverage {
  aq : Int
  bq : Int
  cq : Int
  dq : Int
  txq : Int
  tyq : Int
  rule : Int
  u0 : Float
  v0 : Float
  u1 : Float
  v1 : Float
  x : Int
  y : Int
  w : Int
  h : Int
  tex_id : Int
  mut last_frame : Int
}

// One cached tessellation of a path for a specific (quantized) transform and
// paint variant. `wq == -1` means fill; otherwise it is the stroke width in
// 1/16 px, paired with cap/join/miter codes.
priv struct CachedPathMesh {
  aq : Int
  bq : Int
  cq : Int
  dq : Int
  wq : Int
  cap : Int
  join : Int
  mq : Int
  verts : Array[Float]
  bounds : Rect
  mut last_frame : Int
}

///|
// A large image promoted out of the shared atlas into its own mipmapped
// texture. `tex_id` is its slot in the bindless heap; a non-negative tex_id is
// forwarded to the fragment shader so it samples the dedicated texture (and its
// mip chain) instead of the atlas.
priv struct ImageTexEntry {
  tex : @tycho.Texture
  tex_id : Int
  width : Int
  height : Int
}

///|
// A deferred AA path waiting to be drawn into a shared MSAA pass. Only
// non-overlapping SrcOver paths with no filter and no stencil clip are batched,
// so combining them is pixel-equivalent to drawing each on its own.
priv struct PendingPath {
  path : Path
  paint : Paint
  transform : Matrix3
}

///|
// Per-frame rendering statistics. `draw_calls` counts Tier-1 instanced draws
// (each may contain many prims), `path_passes` counts shared MSAA path passes,
// and `upload_bytes` counts per-frame geometry uploads (prim + path vertices).
pub(all) struct RenderStats {
  draw_calls : Int
  path_passes : Int
  prims : Int
  upload_bytes : Int
  glyph_entries : Int
  image_entries : Int
  atlas_resets : Int
  atlas_overflows : Int
  coverage_draws : Int
  coverage_entries : Int
  sdf_glyphs : Int
  msdf_glyphs : Int
}

///|
pub struct Renderer2D {
  priv dev : @tycho.Device
  priv sampler : @tycho.Sampler
  priv glyph_cache : GlyphCache
  priv color_atlas : DynamicAtlas
  priv rt_pool : RenderTargetPool
  priv uploaded_images : Map[Int, (Float, Float, Float, Float)]
  priv image_tex : Map[Int, ImageTexEntry]
  priv mip_sampler : @tycho.Sampler
  priv msaa_supported : Bool
  // AOT pipelines (depth_format = Depth24Stencil8 for main / layer passes)
  priv prim_pipe : @tycho.Pipeline
  priv prim_clip_pipe : @tycho.Pipeline
  priv bindless_heap : @tycho.BindlessHeap?
  priv prim_bindless_pipe : @tycho.Pipeline?
  priv prim_bindless_clip_pipe : @tycho.Pipeline?
  priv stencil_nz_pipe : @tycho.Pipeline
  priv stencil_eo_pipe : @tycho.Pipeline
  priv stencil_clip_pipe : @tycho.Pipeline
  priv stencil_clear_clip_pipe : @tycho.Pipeline
  priv st_test_clip : @tycho.StencilState
  // Lazily-created Tier-1 pipelines for non-SrcOver blend modes, indexed by
  // (blend_index * 4 + variant), where variant encodes clip/bindless.
  priv blend_prims : Array[@tycho.Pipeline?]
  priv mut cur_blend : BlendMode2D
  // Color format of the active target. Offscreen passes are RGBA8; direct
  // swapchain passes may be BGRA8/sRGB, so prim pipelines are cached per format.
  priv mut cur_color_format : @tycho.TextureFormat
  priv path_cover_pipe : @tycho.Pipeline
  priv path_cover_clip_pipe : @tycho.Pipeline
  priv stroke_pipe : @tycho.Pipeline
  priv stroke_clip_pipe : @tycho.Pipeline
  priv stencil_nz_msaa_pipe : @tycho.Pipeline?
  priv stencil_eo_msaa_pipe : @tycho.Pipeline?
  priv path_cover_msaa_pipe : @tycho.Pipeline?
  priv stroke_msaa_pipe : @tycho.Pipeline?
  priv composite_ds_pipe : @tycho.Pipeline
  priv composite_ds_dstin_pipe : @tycho.Pipeline
  priv composite_ds_srcin_pipe : @tycho.Pipeline
  priv composite_ds_mul_pipe : @tycho.Pipeline
  // Depth-free blur pipeline
  priv blur_pipe : @tycho.Pipeline
  priv mut present_sc_pipe : @tycho.Pipeline?
  priv mut present_sc_fmt : @tycho.TextureFormat?
  priv mut present_sc_depth_fmt : @tycho.TextureFormat?
  // Double-buffered dynamic buffers
  priv max_prims : Int
  priv max_stops : Int
  priv max_path_verts : Int
  priv prim_ssbo : @tycho.Buffer
  priv overflow_prim_ssbos : Array[@tycho.Buffer]
  priv overflow_last_used : Array[Int]
  priv mut active_prim_ssbo : @tycho.Buffer
  priv mut active_prim_slot_base : Int
  priv mut active_prim_chunk : Int
  priv grad_ssbo : @tycho.Buffer
  priv color_mat_ssbo : @tycho.Buffer
  priv path_vbuf : @tycho.Buffer
  priv prim_scratch : FixedArray[Float]
  // CPU staging for one prim batch; uploaded in a single call at flush time.
  priv prim_batch_scratch : FixedArray[Float]
  priv stop_scratch : FixedArray[Float]
  priv path_scratch : FixedArray[Float]
  priv vert_pipes : Array[@tycho.Pipeline?]
  priv vert_vbuf : @tycho.Buffer
  priv vert_ibuf : @tycho.Buffer
  priv vert_scratch : FixedArray[Float]
  priv vert_index_scratch : FixedArray[UInt32]
  priv mut vert_cursor : Int
  priv mut vert_index_cursor : Int
  priv path_cache : Map[Int, Array[CachedPathMesh]]
  priv mut path_cache_count : Int
  priv coverage_cache : Map[Int, Array[CachedCoverage]]
  priv mut coverage_count : Int
  priv mut coverage_generation : Int
  priv mut coverage_draws : Int
  priv color_glyphs : Map[Int, Array[CachedColorGlyph]]
  priv mut color_glyph_count : Int
  priv mut color_atlas_gen : Int
  priv coverage_atlas : DynamicAtlas
  priv coverage_tex_id : Int
  priv mut coverage_atlas_generation : Int
  priv mut coverage_enabled : Bool
  priv path_batch : Array[PendingPath]
  priv mut path_batch_bounds : Rect?
  priv mut path_batch_count : Int
  priv mut frame_idx : Int
  priv mut active_slot : Int
  priv mut active_rt_slot : Int
  // Per-frame active batch cursors
  priv mut prim_cursor : Int
  priv mut prim_batch_start : Int
  priv mut prim_draw_count : Int
  priv mut prim_total : Int
  priv mut upload_bytes : Int
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
  samples? : @tycho.SampleCount = @tycho.SampleCount::X1,
  bindless_heap? : @tycho.BindlessHeap? = None,
  color_format? : @tycho.TextureFormat = @tycho.TextureFormat::RGBA8,
  blend_state? : @tycho.BlendState? = None,
) -> @tycho.Pipeline raise @tycho.RhiError {
  dev.create_graphics_pipeline(
    @tycho.PipelineDesc::from_spirv(
      vert,
      frag,
      blend_mode=Some(blend_mode),
      blend_state~,
      color_write~,
      cull_mode=@tycho.CullMode::None,
      samples~,
      color_format=Some(color_format),
      depth_format=Some(@tycho.TextureFormat::Depth24Stencil8),
      stencil=Some(stencil),
      bindless_heap~,
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
  let mip_sampler = dev.create_sampler_desc(
    @tycho.SamplerDesc::new(
      mag=@tycho.Filter::Linear,
      min=@tycho.Filter::Linear,
      mipmap=@tycho.Filter::Linear,
      address=@tycho.AddressMode::ClampToEdge,
    ),
  )
  let glyph_cache = GlyphCache::new(dev)
  let color_atlas = DynamicAtlas::new(
    dev,
    2048,
    2048,
    @tycho.TextureFormat::RGBA8,
  )
  // Dedicated R8 atlas for CPU coverage bitmaps, so large path coverage does
  // not evict glyphs. Sampled through the bindless heap when available;
  // otherwise coverage falls back to the glyph atlas.
  let coverage_atlas = DynamicAtlas::new(
    dev,
    2048,
    2048,
    @tycho.TextureFormat::R8,
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
  let st_clip_clr = @tycho.StencilState::new(
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
    reference=(0 : UInt32),
  )
  let stencil_clear_clip_pipe = make_rhi_stencil_pipeline(
    dev,
    spv_path_stencil_vert,
    spv_path_stencil_frag,
    st_clip_clr,
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
  let msaa_supported = dev.capabilities().max_framebuffer_samples >= 4
  let (stencil_nz_msaa_pipe, stencil_eo_msaa_pipe, path_cover_msaa_pipe, stroke_msaa_pipe) = if msaa_supported {
    (
      Some(
        make_rhi_stencil_pipeline(
          dev,
          spv_path_stencil_vert,
          spv_path_stencil_frag,
          st_nz,
          false,
          @tycho.BlendMode::Opaque,
          samples=@tycho.SampleCount::X4,
        ),
      ),
      Some(
        make_rhi_stencil_pipeline(
          dev,
          spv_path_stencil_vert,
          spv_path_stencil_frag,
          st_eo,
          false,
          @tycho.BlendMode::Opaque,
          samples=@tycho.SampleCount::X4,
        ),
      ),
      Some(
        make_rhi_stencil_pipeline(
          dev,
          spv_path_cover_vert,
          spv_path_cover_frag,
          st_cover,
          true,
          @tycho.BlendMode::Premultiplied,
          samples=@tycho.SampleCount::X4,
        ),
      ),
      Some(
        dev.create_graphics_pipeline(
          @tycho.PipelineDesc::from_spirv(
            spv_path_cover_vert,
            spv_path_cover_frag,
            blend_mode=Some(@tycho.BlendMode::Premultiplied),
            cull_mode=@tycho.CullMode::None,
            samples=@tycho.SampleCount::X4,
            color_format=Some(@tycho.TextureFormat::RGBA8),
            depth_format=Some(@tycho.TextureFormat::Depth24Stencil8),
          ),
        ),
      ),
    )
  } else {
    (None, None, None, None)
  }

  let (bindless_heap, prim_bindless_pipe, prim_bindless_clip_pipe, coverage_tex_id) = if dev.capabilities().supports_bindless {
    let heap = dev.create_bindless_heap(max_textures=256)
    let _ = heap.register_texture(glyph_cache.atlas.texture, sampler)
    let _ = heap.register_texture(color_atlas.texture, sampler)
    let _ = heap.register_texture(glyph_cache.msdf_atlas.texture, sampler)
    let cid = heap.register_texture(coverage_atlas.texture, sampler)
    let bp = dev.create_graphics_pipeline(
      @tycho.PipelineDesc::from_spirv(
        spv_prim2d_vert,
        spv_prim2d_bindless_frag,
        blend_mode=Some(@tycho.BlendMode::Premultiplied),
        cull_mode=@tycho.CullMode::None,
        color_format=Some(@tycho.TextureFormat::RGBA8),
        depth_format=Some(@tycho.TextureFormat::Depth24Stencil8),
        bindless_heap=Some(heap),
      ),
    )
    let bcp = make_rhi_stencil_pipeline(
      dev,
      spv_prim2d_vert,
      spv_prim2d_bindless_frag,
      st_test_clip,
      true,
      @tycho.BlendMode::Premultiplied,
      bindless_heap=Some(heap),
    )
    (Some(heap), Some(bp), Some(bcp), cid)
  } else {
    (None, None, None, -1)
  }

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
  let color_mat_ssbo = dev.create_buffer_with(
    512,
    @tycho.BufferKind::Storage,
    location=@tycho.MemoryLocation::CpuToGpu,
  )
  let path_vbuf = dev.create_buffer_with(
    2 * max_path_verts_per_frame * PATH_VERT_BYTES,
    @tycho.BufferKind::Vertex,
    location=@tycho.MemoryLocation::CpuToGpu,
  )
  let vert_vbuf = dev.create_buffer_with(
    2 * MAX_VERTS_PER_FRAME * VERT_BYTES,
    @tycho.BufferKind::Vertex,
    location=@tycho.MemoryLocation::CpuToGpu,
  )
  let vert_ibuf = dev.create_buffer_with(
    2 * MAX_INDICES_PER_FRAME * 4,
    @tycho.BufferKind::Index,
    location=@tycho.MemoryLocation::CpuToGpu,
  )

  {
    dev,
    sampler,
    glyph_cache,
    color_atlas,
    rt_pool,
    uploaded_images: {},
    image_tex: {},
    mip_sampler,
    msaa_supported,
    prim_pipe,
    prim_clip_pipe,
    bindless_heap,
    prim_bindless_pipe,
    prim_bindless_clip_pipe,
    stencil_nz_pipe,
    stencil_eo_pipe,
    stencil_clip_pipe,
    stencil_clear_clip_pipe,
    st_test_clip,
    blend_prims: Array::make(4 * BLEND_MODE_COUNT * 4, (None : @tycho.Pipeline?)),
    cur_blend: BlendMode2D::SrcOver,
    cur_color_format: @tycho.TextureFormat::RGBA8,
    path_cover_pipe,
    path_cover_clip_pipe,
    stroke_pipe,
    stroke_clip_pipe,
    stencil_nz_msaa_pipe,
    stencil_eo_msaa_pipe,
    path_cover_msaa_pipe,
    stroke_msaa_pipe,
    composite_ds_pipe,
    composite_ds_dstin_pipe,
    composite_ds_srcin_pipe,
    composite_ds_mul_pipe,
    blur_pipe,
    present_sc_pipe: None,
    present_sc_fmt: None,
    present_sc_depth_fmt: None,
    max_prims: max_prims_per_frame,
    max_stops: max_stops_per_frame,
    max_path_verts: max_path_verts_per_frame,
    prim_ssbo,
    overflow_prim_ssbos: [],
    overflow_last_used: [],
    active_prim_ssbo: prim_ssbo,
    active_prim_slot_base: 0,
    active_prim_chunk: 0,
    grad_ssbo,
    color_mat_ssbo,
    path_vbuf,
    prim_scratch: FixedArray::make(PRIM_FLOATS, (0.0 : Float)),
    prim_batch_scratch: FixedArray::make(max_prims_per_frame * PRIM_FLOATS, (0.0 : Float)),
    stop_scratch: FixedArray::make(STOP_FLOATS, (0.0 : Float)),
    path_scratch: FixedArray::make(max_path_verts_per_frame * PATH_VERT_FLOATS, (0.0 : Float)),
    vert_pipes: Array::make(8, (None : @tycho.Pipeline?)),
    vert_vbuf,
    vert_ibuf,
    vert_scratch: FixedArray::make(MAX_VERTS_PER_FRAME * VERT_FLOATS, (0.0 : Float)),
    vert_index_scratch: FixedArray::make(MAX_INDICES_PER_FRAME, (0 : UInt32)),
    vert_cursor: 0,
    vert_index_cursor: 0,
    path_cache: {},
    path_cache_count: 0,
    coverage_cache: {},
    coverage_count: 0,
    coverage_generation: 0,
    coverage_draws: 0,
    color_glyphs: {},
    color_glyph_count: 0,
    color_atlas_gen: 0,
    coverage_atlas,
    coverage_tex_id,
    coverage_atlas_generation: 0,
    coverage_enabled: true,
    path_batch: [],
    path_batch_bounds: None,
    path_batch_count: 0,
    frame_idx: 0,
    active_slot: 0,
    active_rt_slot: 0,
    prim_cursor: 0,
    prim_batch_start: 0,
    prim_draw_count: 0,
    prim_total: 0,
    upload_bytes: 0,
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
  match self.prim_bindless_pipe {
    Some(p) => p.destroy()
    None => ()
  }
  match self.prim_bindless_clip_pipe {
    Some(p) => p.destroy()
    None => ()
  }
  for _, e in self.image_tex {
    match self.bindless_heap {
      Some(h) => h.unregister_texture(e.tex_id)
      None => ()
    }
    e.tex.destroy()
  }
  self.image_tex.clear()
  match self.bindless_heap {
    Some(h) => {
      if self.coverage_tex_id >= 0 {
        h.unregister_texture(self.coverage_tex_id)
      }
      h.destroy()
    }
    None => ()
  }
  self.stencil_nz_pipe.destroy()
  self.stencil_eo_pipe.destroy()
  self.stencil_clip_pipe.destroy()
  self.stencil_clear_clip_pipe.destroy()
  for p in self.blend_prims {
    match p {
      Some(pipe) => pipe.destroy()
      None => ()
    }
  }
  self.path_cover_pipe.destroy()
  self.path_cover_clip_pipe.destroy()
  self.stroke_pipe.destroy()
  self.stroke_clip_pipe.destroy()
  match self.stencil_nz_msaa_pipe {
    Some(p) => p.destroy()
    None => ()
  }
  match self.stencil_eo_msaa_pipe {
    Some(p) => p.destroy()
    None => ()
  }
  match self.path_cover_msaa_pipe {
    Some(p) => p.destroy()
    None => ()
  }
  match self.stroke_msaa_pipe {
    Some(p) => p.destroy()
    None => ()
  }
  self.composite_ds_pipe.destroy()
  self.composite_ds_dstin_pipe.destroy()
  self.composite_ds_srcin_pipe.destroy()
  self.composite_ds_mul_pipe.destroy()
  self.blur_pipe.destroy()
  match self.present_sc_pipe {
    Some(p) => p.destroy()
    None => ()
  }
  self.prim_ssbo.destroy()
  for ob in self.overflow_prim_ssbos {
    ob.destroy()
  }
  self.grad_ssbo.destroy()
  self.color_mat_ssbo.destroy()
  self.path_vbuf.destroy()
  self.rt_pool.destroy()
  self.vert_vbuf.destroy()
  self.vert_ibuf.destroy()
  for p in self.vert_pipes {
    match p {
      Some(pipe) => pipe.destroy()
      None => ()
    }
  }
  self.glyph_cache.destroy()
  self.color_atlas.destroy()
  self.coverage_atlas.destroy()
  self.mip_sampler.destroy()
  self.sampler.destroy()
}

///|
fn Renderer2D::slot_prim_base(self : Renderer2D) -> Int {
  (self.active_slot % 2) * self.max_prims * PRIM_BYTES
}

///|
fn Renderer2D::slot_stop_base(self : Renderer2D) -> Int {
  (self.active_slot % 2) * self.max_stops * STOP_BYTES
}

///|
fn Renderer2D::slot_path_base(self : Renderer2D) -> Int {
  (self.active_slot % 2) * self.max_path_verts * PATH_VERT_BYTES
}

///|
fn Renderer2D::slot_vert_base(self : Renderer2D) -> Int {
  (self.active_slot % 2) * MAX_VERTS_PER_FRAME * VERT_BYTES
}

///|
fn Renderer2D::slot_index_base(self : Renderer2D) -> Int {
  (self.active_slot % 2) * MAX_INDICES_PER_FRAME * 4
}

///|
fn Renderer2D::slot_cmat_base(self : Renderer2D) -> Int {
  (self.active_slot % 2) * 256
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
priv struct ResolvedShader {
  fill : Color
  grad_type : Float
  tile_mode : Float
  gp0 : Float
  gp1 : Float
  gp2 : Float
  gp3 : Float
  stop_off : Float
  stop_cnt : Float
  extra0 : Float
  extra1 : Float
  u0 : Float
  v0 : Float
  u1 : Float
  v1 : Float
}

///|
fn tile_mode_int(t : TileMode) -> Int {
  match t {
    TileMode::Clamp => 0
    TileMode::Repeat => 1
    TileMode::Mirror => 2
    TileMode::Decal => 3
  }
}

///|
fn Renderer2D::resolve_paint_shader(
  self : Renderer2D,
  paint : Paint,
) -> ResolvedShader raise @tycho.RhiError {
  match paint.shader {
    None =>
      {
        fill: paint.color,
        grad_type: (0.0 : Float),
        tile_mode: (0.0 : Float),
        gp0: (0.0 : Float),
        gp1: (0.0 : Float),
        gp2: (0.0 : Float),
        gp3: (0.0 : Float),
        stop_off: (0.0 : Float),
        stop_cnt: (0.0 : Float),
        extra0: (0.0 : Float),
        extra1: (0.0 : Float),
        u0: (0.0 : Float),
        v0: (0.0 : Float),
        u1: (0.0 : Float),
        v1: (0.0 : Float),
      }
    Some(Shader2D::Solid(col)) =>
      {
        fill: col,
        grad_type: (0.0 : Float),
        tile_mode: (0.0 : Float),
        gp0: (0.0 : Float),
        gp1: (0.0 : Float),
        gp2: (0.0 : Float),
        gp3: (0.0 : Float),
        stop_off: (0.0 : Float),
        stop_cnt: (0.0 : Float),
        extra0: (0.0 : Float),
        extra1: (0.0 : Float),
        u0: (0.0 : Float),
        v0: (0.0 : Float),
        u1: (0.0 : Float),
        v1: (0.0 : Float),
      }
    Some(Shader2D::LinearGradient(p0, p1, stops, tile)) => {
      let (soff, scnt) = self.push_gradient_stops(stops)
      let c0 = if stops.length() > 0 { stops[0].color } else { paint.color }
      {
        fill: c0,
        grad_type: (1.0 : Float),
        tile_mode: tile_mode_float(tile),
        gp0: p0.x,
        gp1: p0.y,
        gp2: p1.x,
        gp3: p1.y,
        stop_off: soff,
        stop_cnt: scnt,
        extra0: (0.0 : Float),
        extra1: (0.0 : Float),
        u0: (0.0 : Float),
        v0: (0.0 : Float),
        u1: (0.0 : Float),
        v1: (0.0 : Float),
      }
    }
    Some(Shader2D::RadialGradient(center, radius, stops, tile)) => {
      let (soff, scnt) = self.push_gradient_stops(stops)
      let c0 = if stops.length() > 0 { stops[0].color } else { paint.color }
      {
        fill: c0,
        grad_type: (2.0 : Float),
        tile_mode: tile_mode_float(tile),
        gp0: center.x,
        gp1: center.y,
        gp2: radius,
        gp3: (0.0 : Float),
        stop_off: soff,
        stop_cnt: scnt,
        extra0: (0.0 : Float),
        extra1: (0.0 : Float),
        u0: (0.0 : Float),
        v0: (0.0 : Float),
        u1: (0.0 : Float),
        v1: (0.0 : Float),
      }
    }
    Some(Shader2D::SweepGradient(center, a0, a1, stops, tile)) => {
      let (soff, scnt) = self.push_gradient_stops(stops)
      let c0 = if stops.length() > 0 { stops[0].color } else { paint.color }
      {
        fill: c0,
        grad_type: (3.0 : Float),
        tile_mode: tile_mode_float(tile),
        gp0: center.x,
        gp1: center.y,
        gp2: a0,
        gp3: a1,
        stop_off: soff,
        stop_cnt: scnt,
        extra0: (0.0 : Float),
        extra1: (0.0 : Float),
        u0: (0.0 : Float),
        v0: (0.0 : Float),
        u1: (0.0 : Float),
        v1: (0.0 : Float),
      }
    }
    Some(Shader2D::ImagePattern(img, mat, _f, tx, ty)) => {
      let (u0, v0, u1, v1) = self.ensure_image_uv(img)
      let iw = if img.width > 0 { Float::from_int(img.width) } else { (1.0 : Float) }
      let ih = if img.height > 0 { Float::from_int(img.height) } else { (1.0 : Float) }
      let det = mat.a * mat.d - mat.b * mat.c
      let (ia, ic, itx, ib, id_, ity) = if @tmath.abs_f(det) > (1.0e-6 : Float) {
        (
          mat.d / det,
          -mat.c / det,
          (mat.c * mat.ty - mat.d * mat.tx) / det,
          -mat.b / det,
          mat.a / det,
          (mat.b * mat.tx - mat.a * mat.ty) / det,
        )
      } else {
        ((1.0 : Float), (0.0 : Float), (0.0 : Float), (0.0 : Float), (1.0 : Float), (0.0 : Float))
      }
      let packed = Float::from_int(tile_mode_int(tx) + tile_mode_int(ty) * 4)
      {
        fill: paint.color,
        grad_type: (4.0 : Float),
        tile_mode: packed,
        gp0: ia / iw,
        gp1: ic / iw,
        gp2: itx / iw,
        gp3: ib / ih,
        stop_off: (0.0 : Float),
        stop_cnt: (0.0 : Float),
        extra0: id_ / ih,
        extra1: ity / ih,
        u0,
        v0,
        u1,
        v1,
      }
    }
  }
}

///|
fn Renderer2D::emit_prim(
  self : Renderer2D,
  cmd : @tycho.CommandBuffer,
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
  extra0? : Float = (-1.0 : Float),
  extra1? : Float = (0.0 : Float),
  radii_y? : (Float, Float, Float, Float)? = None,
) -> Unit raise @tycho.RhiError {
  if self.prim_cursor >= self.max_prims {
    self.flush_prims(cmd)
    let ov_idx = self.active_prim_chunk
    self.active_prim_chunk = self.active_prim_chunk + 1
    let buf = if ov_idx < self.overflow_prim_ssbos.length() {
      self.overflow_prim_ssbos[ov_idx]
    } else {
      let nb = self.dev.create_buffer_with(
        2 * self.max_prims * PRIM_BYTES,
        @tycho.BufferKind::Storage,
        location=@tycho.MemoryLocation::CpuToGpu,
      )
      self.overflow_prim_ssbos.push(nb)
      nb
    }
    while self.overflow_last_used.length() <= ov_idx {
      self.overflow_last_used.push(self.frame_idx)
    }
    self.overflow_last_used[ov_idx] = self.frame_idx
    self.active_prim_ssbo = buf
    self.active_prim_slot_base = self.slot_prim_base()
    self.prim_cursor = 0
    self.prim_batch_start = 0
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
  p[38] = extra0
  p[39] = extra1
  let (tly, tr_y, bry, bly) = match radii_y {
    Some(v) => v
    None => (tl, tr, br, bl)
  }
  p[40] = tly
  p[41] = tr_y
  p[42] = bry
  p[43] = bly
  // Per-instance rectangular clip in target space. This lets consecutive prims
  // with different rect clips share one draw call instead of flushing.
  p[44] = self.cur_scissor.x
  p[45] = self.cur_scissor.y
  p[46] = self.cur_scissor.width
  p[47] = self.cur_scissor.height
  let dst_base = (self.prim_cursor - self.prim_batch_start) * PRIM_FLOATS
  for i = 0; i < PRIM_FLOATS; i = i + 1 {
    self.prim_batch_scratch[dst_base + i] = self.prim_scratch[i]
  }
  self.prim_cursor = self.prim_cursor + 1
  self.prim_total = self.prim_total + 1
}

///|
const BLEND_MODE_COUNT : Int = 17

///|
fn blend_mode_index(b : BlendMode2D) -> Int {
  match b {
    BlendMode2D::SrcOver => 0
    BlendMode2D::Src => 1
    BlendMode2D::Dst => 2
    BlendMode2D::DstOver => 3
    BlendMode2D::SrcIn => 4
    BlendMode2D::DstIn => 5
    BlendMode2D::SrcOut => 6
    BlendMode2D::DstOut => 7
    BlendMode2D::SrcAtop => 8
    BlendMode2D::DstAtop => 9
    BlendMode2D::Xor => 10
    BlendMode2D::Plus => 11
    BlendMode2D::Multiply => 12
    BlendMode2D::Screen => 13
    BlendMode2D::Darken => 14
    BlendMode2D::Lighten => 15
    BlendMode2D::Clear => 16
  }
}

///|
// Resolve (creating lazily) the Tier-1 pipeline for a given blend mode and
// clip/bindless variant. SrcOver reuses the eagerly-created pipelines.
fn color_format_index(f : @tycho.TextureFormat) -> Int {
  match f {
    @tycho.TextureFormat::RGBA8 => 0
    @tycho.TextureFormat::BGRA8 => 1
    @tycho.TextureFormat::RGBA8Srgb => 2
    @tycho.TextureFormat::BGRA8Srgb => 3
    _ => 0
  }
}

///|
fn Renderer2D::prim_pipe_for(
  self : Renderer2D,
  has_clip : Bool,
  blend : BlendMode2D,
) -> @tycho.Pipeline raise @tycho.RhiError {
  let fi = color_format_index(self.cur_color_format)
  if blend == BlendMode2D::SrcOver && fi == 0 {
    return match (has_clip, self.prim_bindless_clip_pipe, self.prim_bindless_pipe) {
      (true, Some(bcp), _) => bcp
      (false, _, Some(bp)) => bp
      (true, None, _) => self.prim_clip_pipe
      (false, _, None) => self.prim_pipe
    }
  }
  let use_bindless = match (self.bindless_heap, self.prim_bindless_pipe) {
    (Some(_), Some(_)) => true
    _ => false
  }
  let variant = (if has_clip { 1 } else { 0 }) + (if use_bindless { 2 } else { 0 })
  let idx = fi * (BLEND_MODE_COUNT * 4) + blend_mode_index(blend) * 4 + variant
  match self.blend_prims[idx] {
    Some(p) => p
    None => {
      let heap = if use_bindless { self.bindless_heap } else { None }
      let frag = if use_bindless { spv_prim2d_bindless_frag } else { spv_prim2d_frag }
      let pipe = if has_clip {
        make_rhi_stencil_pipeline(
          self.dev,
          spv_prim2d_vert,
          frag,
          self.st_test_clip,
          true,
          blend.to_rhi(),
          bindless_heap=heap,
          color_format=self.cur_color_format,
          blend_state=blend.to_blend_state(),
        )
      } else {
        self.dev.create_graphics_pipeline(
          @tycho.PipelineDesc::from_spirv(
            spv_prim2d_vert,
            frag,
            blend_mode=Some(blend.to_rhi()),
            blend_state=blend.to_blend_state(),
            cull_mode=@tycho.CullMode::None,
            color_format=Some(self.cur_color_format),
            depth_format=Some(@tycho.TextureFormat::Depth24Stencil8),
            bindless_heap=heap,
          ),
        )
      }
      self.blend_prims[idx] = Some(pipe)
      pipe
    }
  }
}

///|
fn Renderer2D::set_blend(
  self : Renderer2D,
  cmd : @tycho.CommandBuffer,
  blend : BlendMode2D,
) -> Unit raise @tycho.RhiError {
  if blend != self.cur_blend {
    self.flush_prims(cmd)
    self.cur_blend = blend
  }
}

///|
fn Renderer2D::flush_prims(
  self : Renderer2D,
  cmd : @tycho.CommandBuffer,
) -> Unit raise @tycho.RhiError {
  let count = self.prim_cursor - self.prim_batch_start
  if count <= 0 || self.active_w <= 0 || self.active_h <= 0 {
    self.prim_batch_start = self.prim_cursor
    return
  }
  let pipe = self.prim_pipe_for(self.has_stencil_clip, self.cur_blend)
  cmd.bind_pipeline(pipe)
  if self.has_stencil_clip {
    cmd.set_stencil_reference(128)
  }
  cmd.bind_storage(
    pipe,
    0,
    self.active_prim_ssbo,
    offset=self.active_prim_slot_base,
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
  cmd.bind_texture(pipe, 2, self.glyph_cache.msdf_atlas.texture, self.sampler)
  match self.bindless_heap {
    Some(heap) => cmd.bind_bindless_heap(pipe, heap, set_index=1)
    None => ()
  }
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
  // Clipping is applied per instance in the fragment shader, so the hardware
  // scissor stays at the full target and batches survive rect-clip changes.
  // One upload per batch instead of one per primitive.
  self.active_prim_ssbo.upload_floats(
    self.prim_batch_scratch,
    offset=self.active_prim_slot_base + self.prim_batch_start * PRIM_BYTES,
    count=count * PRIM_FLOATS,
  )
  self.upload_bytes = self.upload_bytes + count * PRIM_BYTES
  cmd.set_scissor(0, 0, self.active_w, self.active_h)
  self.prim_draw_count = self.prim_draw_count + 1
  cmd.draw_instanced(6, count, 0, self.prim_batch_start)
  self.prim_batch_start = self.prim_cursor
}

///|
fn Renderer2D::flush_atlas_uploads(self : Renderer2D) -> Unit raise @tycho.RhiError {
  self.glyph_cache.atlas.flush_uploads()
  self.color_atlas.flush_uploads()
  self.coverage_atlas.flush_uploads()
}

///|
pub fn Renderer2D::dedicated_image_count(self : Renderer2D) -> Int {
  self.image_tex.length()
}

///|
pub fn Renderer2D::path_batch_count(self : Renderer2D) -> Int {
  self.path_batch_count
}

///|
pub fn Renderer2D::prim_draw_count(self : Renderer2D) -> Int {
  self.prim_draw_count
}

///|
///|
// Enable/disable the CPU coverage path (useful for A/B quality comparisons
// against MSAA).
pub fn Renderer2D::set_coverage_enabled(self : Renderer2D, enabled : Bool) -> Unit {
  self.coverage_enabled = enabled
}

///|
pub fn Renderer2D::stats(self : Renderer2D) -> RenderStats {
  {
    draw_calls: self.prim_draw_count,
    path_passes: self.path_batch_count,
    prims: self.prim_total,
    upload_bytes: self.upload_bytes,
    glyph_entries: self.glyph_cache.entry_count(),
    image_entries: self.uploaded_images.length() + self.image_tex.length(),
    atlas_resets: self.glyph_cache.atlas_reset_count(),
    atlas_overflows: self.glyph_cache.atlas_overflow_count(),
    coverage_draws: self.coverage_draws,
    coverage_entries: self.coverage_count,
    sdf_glyphs: self.glyph_cache.sdf_count(),
    msdf_glyphs: self.glyph_cache.msdf_count(),
  }
}

///|
// Compact single-line summary suitable for a debug/performance overlay.
pub fn RenderStats::summary(self : RenderStats) -> String {
  "draws \{self.draw_calls} | passes \{self.path_passes} | prims \{self.prims} | coverage \{self.coverage_draws} | uploads \{self.upload_bytes}B | glyphs \{self.glyph_entries} (sdf \{self.sdf_glyphs}) | atlas resets \{self.atlas_resets}/\{self.atlas_overflows}"
}

///|
pub fn RenderStats::to_json(self : RenderStats) -> String {
  "{\"draws\":\{self.draw_calls},\"path_passes\":\{self.path_passes},\"prims\":\{self.prims},\"uploads\":\{self.upload_bytes},\"glyphs\":\{self.glyph_entries},\"sdf_glyphs\":\{self.sdf_glyphs},\"msdf_glyphs\":\{self.msdf_glyphs},\"atlas_images\":\{self.image_entries},\"atlas_resets\":\{self.atlas_resets},\"atlas_overflows\":\{self.atlas_overflows},\"coverage_draws\":\{self.coverage_draws},\"coverage_entries\":\{self.coverage_entries}}"
}

///|
// The Tier-1 shaders expect straight-alpha texels and premultiply them at
// output (`rgb * a`). Convert premultiplied input back to straight alpha on
// upload so both encodings render identically.
fn unpremultiply_rgba(pixels : Bytes, w : Int, h : Int) -> Bytes {
  let n = w * h * 4
  if n <= 0 || pixels.length() < n {
    return pixels
  }
  let out = Array::make(n, (0 : Byte))
  for i = 0; i < n; i = i + 4 {
    let a = pixels[i + 3].to_int()
    if a == 0 {
      out[i] = (0 : Byte)
      out[i + 1] = (0 : Byte)
      out[i + 2] = (0 : Byte)
    } else {
      let r = pixels[i].to_int() * 255 / a
      let g = pixels[i + 1].to_int() * 255 / a
      let b = pixels[i + 2].to_int() * 255 / a
      out[i] = (if r > 255 { 255 } else { r }).to_byte()
      out[i + 1] = (if g > 255 { 255 } else { g }).to_byte()
      out[i + 2] = (if b > 255 { 255 } else { b }).to_byte()
    }
    out[i + 3] = pixels[i + 3]
  }
  Bytes::from_array(out)
}

///|
fn image_upload_pixels(img : Image2D) -> Bytes {
  if img.premultiplied && img.pixels.length() > 0 {
    unpremultiply_rgba(img.pixels, img.width, img.height)
  } else {
    img.pixels
  }
}

///|
// Promote a large image into its own mipmapped texture so minified draws are
// properly filtered. Only used when the device supports bindless sampling; the
// returned tex_id is forwarded to the shader via extra0. Returns None to fall
// back to the shared atlas (texture-backed images, small images, or no
// bindless).
fn Renderer2D::ensure_image_texture(
  self : Renderer2D,
  img : Image2D,
) -> (Int, Int, Int)? raise @tycho.RhiError {
  match self.bindless_heap {
    None => return None
    Some(_) => ()
  }
  if img.width < 64 || img.height < 64 || img.pixels.length() == 0 {
    return None
  }
  match self.image_tex.get(img.id) {
    Some(e) => return Some((e.tex_id, e.width, e.height))
    None => ()
  }
  // Keep the bindless table bounded; excess images fall back to the atlas.
  if self.image_tex.length() >= 64 {
    return None
  }
  let fmt = if img.srgb {
    @tycho.TextureFormat::RGBA8Srgb
  } else {
    @tycho.TextureFormat::RGBA8
  }
  let tex = self.dev.create_texture_mipmapped(
    img.width,
    img.height,
    fmt,
    image_upload_pixels(img),
  )
  let heap = self.bindless_heap.unwrap()
  let tex_id = heap.register_texture(tex, self.mip_sampler)
  self.image_tex[img.id] = { tex, tex_id, width: img.width, height: img.height }
  Some((tex_id, img.width, img.height))
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
    image_upload_pixels(img)
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
  // An image larger than the atlas page can never fit; skip resetting for it.
  if img.width > self.color_atlas.width || img.height > self.color_atlas.height {
    return ((0.0 : Float), (0.0 : Float), (0.0 : Float), (0.0 : Float))
  }
  match self.color_atlas.alloc_and_upload(img.width, img.height, pixels) {
    Some((ax, ay)) => {
      let uv = self.color_atlas.uv_rect(ax, ay, img.width, img.height)
      self.uploaded_images[img.id] = uv
      uv
    }
    None => {
      // Atlas full: reclaim the whole color atlas once and retry. Every cached
      // image UV becomes invalid, so clear the cache to force re-upload instead
      // of silently sampling stale/overlapping regions.
      self.color_atlas.reset()
      self.uploaded_images.clear()
      match self.color_atlas.alloc_and_upload(img.width, img.height, pixels) {
        Some((ax2, ay2)) => {
          let uv = self.color_atlas.uv_rect(ax2, ay2, img.width, img.height)
          self.uploaded_images[img.id] = uv
          uv
        }
        None => ((0.0 : Float), (0.0 : Float), (0.0 : Float), (0.0 : Float))
      }
    }
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
  self.upload_bytes = self.upload_bytes + n_floats * 4
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
fn stroke_cap_code(c : StrokeCap) -> Int {
  match c {
    StrokeCap::Butt => 0
    StrokeCap::Round => 1
    StrokeCap::Square => 2
  }
}

///|
fn stroke_join_code(j : StrokeJoin) -> Int {
  match j {
    StrokeJoin::Miter => 0
    StrokeJoin::Round => 1
    StrokeJoin::Bevel => 2
  }
}

///|
fn verts_bounds(verts : Array[Float]) -> Rect {
  let n = verts.length()
  if n < 2 {
    return Rect::zero()
  }
  let mut minx = verts[0]
  let mut miny = verts[1]
  let mut maxx = verts[0]
  let mut maxy = verts[1]
  let mut i = 2
  while i + 1 < n {
    let x = verts[i]
    let y = verts[i + 1]
    if x < minx {
      minx = x
    }
    if x > maxx {
      maxx = x
    }
    if y < miny {
      miny = y
    }
    if y > maxy {
      maxy = y
    }
    i = i + 2
  }
  Rect::new(minx, miny, maxx - minx, maxy - miny)
}

///|
fn translate_mesh(
  verts : Array[Float],
  bounds : Rect,
  xf : Matrix3,
) -> (Array[Float], Rect) {
  if xf.tx == (0.0 : Float) && xf.ty == (0.0 : Float) {
    return (verts, bounds)
  }
  let n = verts.length()
  let out = Array::make(n, (0.0 : Float))
  let mut i = 0
  while i + 1 < n {
    out[i] = verts[i] + xf.tx
    out[i + 1] = verts[i + 1] + xf.ty
    i = i + 2
  }
  (out, bounds.offset(xf.tx, xf.ty))
}

///|
// Evict the least-recently-used cached path variant. Only runs on insertion
// once the cache is at capacity, so the O(entries) scan stays off the hot path.
fn Renderer2D::evict_oldest_path(self : Renderer2D) -> Unit {
  let mut oldest_pid = 0
  let mut oldest_idx = -1
  let mut oldest_frame = self.frame_idx + 1
  for pid, arr in self.path_cache {
    for i = 0; i < arr.length(); i = i + 1 {
      if arr[i].last_frame < oldest_frame {
        oldest_frame = arr[i].last_frame
        oldest_pid = pid
        oldest_idx = i
      }
    }
  }
  if oldest_idx < 0 {
    return
  }
  match self.path_cache.get(oldest_pid) {
    Some(arr) => {
      let _ = arr.remove(oldest_idx)
      if arr.length() == 0 {
        let _ = self.path_cache.remove(oldest_pid)
      }
      self.path_cache_count = self.path_cache_count - 1
    }
    None => ()
  }
}

///|
fn Renderer2D::tessellate_fill_cached(
  self : Renderer2D,
  path : Path,
  xf : Matrix3,
) -> (Array[Float], Rect) {
  let pid = path.id().to_int()
  let aq = (xf.a * (16.0 : Float)).to_int()
  let bq = (xf.b * (16.0 : Float)).to_int()
  let cq = (xf.c * (16.0 : Float)).to_int()
  let dq = (xf.d * (16.0 : Float)).to_int()
  let arr = match self.path_cache.get(pid) {
    Some(a) => a
    None => []
  }
  let mut hit : CachedPathMesh? = None
  for e in arr {
    if e.aq == aq && e.bq == bq && e.cq == cq && e.dq == dq && e.wq == -1 {
      e.last_frame = self.frame_idx
      hit = Some(e)
    }
  }
  let (base_verts, base_bounds) = match hit {
    Some(e) => (e.verts, e.bounds)
    None => {
      if self.path_cache_count >= 256 {
        self.evict_oldest_path()
      }
      let linear_xf = Matrix3::{
        a: xf.a,
        c: xf.c,
        tx: (0.0 : Float),
        b: xf.b,
        d: xf.d,
        ty: (0.0 : Float),
      }
      let (verts, bounds) = tessellate_fill_fan(path, linear_xf)
      arr.push({
        aq,
        bq,
        cq,
        dq,
        wq: -1,
        cap: 0,
        join: 0,
        mq: 0,
        verts,
        bounds,
        last_frame: self.frame_idx,
      })
      self.path_cache[pid] = arr
      self.path_cache_count = self.path_cache_count + 1
      (verts, bounds)
    }
  }
  translate_mesh(base_verts, base_bounds, xf)
}

///|
fn Renderer2D::tessellate_stroke_cached(
  self : Renderer2D,
  path : Path,
  xf : Matrix3,
  paint : Paint,
) -> Array[Float] {
  let pid = path.id().to_int()
  let aq = (xf.a * (16.0 : Float)).to_int()
  let bq = (xf.b * (16.0 : Float)).to_int()
  let cq = (xf.c * (16.0 : Float)).to_int()
  let dq = (xf.d * (16.0 : Float)).to_int()
  let wq = @tmath.max_f(
    (0.0 : Float),
    paint.stroke_width * (16.0 : Float) + (0.5 : Float),
  ).to_int()
  let cap = stroke_cap_code(paint.stroke_cap)
  let join = stroke_join_code(paint.stroke_join)
  let mq = @tmath.max_f(
    (0.0 : Float),
    paint.stroke_miter * (4.0 : Float) + (0.5 : Float),
  ).to_int()
  let arr = match self.path_cache.get(pid) {
    Some(a) => a
    None => []
  }
  let mut hit : CachedPathMesh? = None
  for e in arr {
    if e.aq == aq &&
      e.bq == bq &&
      e.cq == cq &&
      e.dq == dq &&
      e.wq == wq &&
      e.cap == cap &&
      e.join == join &&
      e.mq == mq {
      e.last_frame = self.frame_idx
      hit = Some(e)
    }
  }
  let base_verts = match hit {
    Some(e) => e.verts
    None => {
      if self.path_cache_count >= 256 {
        self.evict_oldest_path()
      }
      let linear_xf = Matrix3::{
        a: xf.a,
        c: xf.c,
        tx: (0.0 : Float),
        b: xf.b,
        d: xf.d,
        ty: (0.0 : Float),
      }
      let verts = tessellate_stroke(
        path,
        linear_xf,
        Float::from_int(wq) * (0.0625 : Float),
        paint.stroke_cap,
        paint.stroke_join,
        Float::from_int(mq) * (0.25 : Float),
      )
      arr.push({
        aq,
        bq,
        cq,
        dq,
        wq,
        cap,
        join,
        mq,
        verts,
        bounds: verts_bounds(verts),
        last_frame: self.frame_idx,
      })
      self.path_cache[pid] = arr
      self.path_cache_count = self.path_cache_count + 1
      verts
    }
  }
  if xf.tx == (0.0 : Float) && xf.ty == (0.0 : Float) {
    return base_verts
  }
  let n = base_verts.length()
  let out = Array::make(n, (0.0 : Float))
  let mut i = 0
  while i + 1 < n {
    out[i] = base_verts[i] + xf.tx
    out[i + 1] = base_verts[i + 1] + xf.ty
    i = i + 2
  }
  out
}

///|
fn Renderer2D::draw_path_raw(
  self : Renderer2D,
  cmd : @tycho.CommandBuffer,
  path : Path,
  paint : Paint,
  xf : Matrix3,
  target_w : Int,
  target_h : Int,
  use_msaa : Bool,
) -> Unit raise @tycho.RhiError {
  let fw = Float::from_int(target_w)
  let fh = Float::from_int(target_h)
  if paint.style == PaintStyle::Fill || paint.style == PaintStyle::StrokeAndFill {
    let (verts, bounds) = self.tessellate_fill_cached(path, xf)
    let (vstart, vcnt) = self.upload_path_verts(verts)
    if vcnt >= 3 {
      let l = bounds.x
      let t = bounds.y
      let r = bounds.right()
      let b = bounds.bottom()
      let (cstart, ccnt) = self.upload_path_verts([l, t, r, t, r, b, l, t, r, b, l, b])
      let st_pipe = if use_msaa {
        match path.fill_rule() {
          FillRule::NonZero => self.stencil_nz_msaa_pipe.unwrap()
          FillRule::EvenOdd => self.stencil_eo_msaa_pipe.unwrap()
        }
      } else {
        match path.fill_rule() {
          FillRule::NonZero => self.stencil_nz_pipe
          FillRule::EvenOdd => self.stencil_eo_pipe
        }
      }
      cmd.bind_pipeline(st_pipe)
      cmd.bind_vertex(0, self.path_vbuf, offset=self.slot_path_base())
      cmd.push_constants_floats(st_pipe, [fw, fh, (1.0 : Float) / fw, (1.0 : Float) / fh])
      cmd.draw_instanced(vcnt, 1, vstart, 0)

      let cov_pipe = if use_msaa {
        self.path_cover_msaa_pipe.unwrap()
      } else if self.has_stencil_clip {
        self.path_cover_clip_pipe
      } else {
        self.path_cover_pipe
      }
      cmd.bind_pipeline(cov_pipe)
      cmd.set_stencil_reference(if !use_msaa && self.has_stencil_clip { 128 } else { 0 })
      cmd.bind_vertex(0, self.path_vbuf, offset=self.slot_path_base())
      cmd.push_constants_floats(cov_pipe, path_cover_pc(target_w, target_h, paint))
      cmd.draw_instanced(ccnt, 1, cstart, 0)
    }
  }
  if paint.style == PaintStyle::Stroke || paint.style == PaintStyle::StrokeAndFill {
    let verts = self.tessellate_stroke_cached(path, xf, paint)
    let (vstart, vcnt) = self.upload_path_verts(verts)
    if vcnt >= 3 {
      let spipe = if use_msaa {
        self.stroke_msaa_pipe.unwrap()
      } else if self.has_stencil_clip {
        self.stroke_clip_pipe
      } else {
        self.stroke_pipe
      }
      cmd.bind_pipeline(spipe)
      if !use_msaa && self.has_stencil_clip {
        cmd.set_stencil_reference(128)
      }
      cmd.bind_vertex(0, self.path_vbuf, offset=self.slot_path_base())
      cmd.push_constants_floats(spipe, path_cover_pc(target_w, target_h, paint))
      cmd.draw_instanced(vcnt, 1, vstart, 0)
    }
  }
}

///|
fn Renderer2D::evict_oldest_coverage(self : Renderer2D) -> Unit {
  let mut oldest_pid = 0
  let mut oldest_idx = -1
  let mut oldest_frame = self.frame_idx + 1
  for pid, arr in self.coverage_cache {
    for i = 0; i < arr.length(); i = i + 1 {
      if arr[i].last_frame < oldest_frame {
        oldest_frame = arr[i].last_frame
        oldest_pid = pid
        oldest_idx = i
      }
    }
  }
  if oldest_idx < 0 {
    return
  }
  match self.coverage_cache.get(oldest_pid) {
    Some(arr) => {
      let _ = arr.remove(oldest_idx)
      if arr.length() == 0 {
        let _ = self.coverage_cache.remove(oldest_pid)
      }
      self.coverage_count = self.coverage_count - 1
    }
    None => ()
  }
}

///|
fn Renderer2D::coverage_for(
  self : Renderer2D,
  path : Path,
  xf : Matrix3,
) -> CachedCoverage? raise @tycho.RhiError {
  if self.coverage_tex_id < 0 {
    // Fallback path stores coverage in the glyph atlas, so glyph compaction
    // invalidates coverage UVs too.
    let gen = self.glyph_cache.generation()
    if gen != self.coverage_generation {
      self.coverage_cache.clear()
      self.coverage_count = 0
      self.coverage_generation = gen
    }
  }
  let pid = path.id().to_int()
  let aq = (xf.a * (16.0 : Float)).to_int()
  let bq = (xf.b * (16.0 : Float)).to_int()
  let cq = (xf.c * (16.0 : Float)).to_int()
  let dq = (xf.d * (16.0 : Float)).to_int()
  let txq = (xf.tx * (16.0 : Float)).to_int()
  let tyq = (xf.ty * (16.0 : Float)).to_int()
  let rule = match path.fill_rule() {
    FillRule::NonZero => 0
    FillRule::EvenOdd => 1
  }
  let arr = match self.coverage_cache.get(pid) {
    Some(a) => a
    None => []
  }
  let mut hit : CachedCoverage? = None
  for e in arr {
    if e.aq == aq &&
      e.bq == bq &&
      e.cq == cq &&
      e.dq == dq &&
      e.txq == txq &&
      e.tyq == tyq &&
      e.rule == rule {
      e.last_frame = self.frame_idx
      hit = Some(e)
    }
  }
  match hit {
    Some(e) => return Some(e)
    None => ()
  }
  let bmp = match rasterize_coverage(path, xf) {
    Some(b) => b
    None => return None
  }
  if self.coverage_count >= 512 {
    self.evict_oldest_coverage()
  }
  let mut cleared = false
  let (u0, v0, u1, v1, tex_id) = if self.coverage_tex_id >= 0 {
    let first = self.coverage_atlas.alloc_and_upload(
      bmp.width,
      bmp.height,
      bmp.pixels,
      padding=1,
    )
    let placed = match first {
      Some(_) => first
      None => {
        // Dedicated atlas full: reset it and drop all cached coverage UVs.
        self.coverage_atlas.reset()
        self.coverage_cache.clear()
        self.coverage_count = 0
        self.coverage_atlas_generation = self.coverage_atlas_generation + 1
        cleared = true
        self.coverage_atlas.alloc_and_upload(
          bmp.width,
          bmp.height,
          bmp.pixels,
          padding=1,
        )
      }
    }
    match placed {
      Some((tx, ty)) => {
        let (a, b, c, d) = self.coverage_atlas.uv_rect(
          tx,
          ty,
          bmp.width,
          bmp.height,
        )
        (a, b, c, d, self.coverage_tex_id)
      }
      None => return None
    }
  } else {
    match self.glyph_cache.alloc_coverage(
      bmp.width,
      bmp.height,
      bmp.pixels,
    ) {
      Some((a, b, c, d)) => (a, b, c, d, -1)
      None => return None
    }
  }
  let e : CachedCoverage = {
    aq,
    bq,
    cq,
    dq,
    txq,
    tyq,
    rule,
    u0,
    v0,
    u1,
    v1,
    x: bmp.origin_x,
    y: bmp.origin_y,
    w: bmp.width,
    h: bmp.height,
    tex_id,
    last_frame: self.frame_idx,
  }
  if cleared {
    self.coverage_cache[pid] = [e]
    self.coverage_count = 1
  } else {
    arr.push(e)
    self.coverage_cache[pid] = arr
    self.coverage_count = self.coverage_count + 1
  }
  Some(e)
}

///|
fn Renderer2D::evict_oldest_color_glyph(self : Renderer2D) -> Unit {
  let mut oldest_key = 0
  let mut oldest_idx = -1
  let mut oldest_frame = self.frame_idx + 1
  for k, arr in self.color_glyphs {
    for i = 0; i < arr.length(); i = i + 1 {
      if arr[i].last_frame < oldest_frame {
        oldest_frame = arr[i].last_frame
        oldest_key = k
        oldest_idx = i
      }
    }
  }
  if oldest_idx < 0 {
    return
  }
  match self.color_glyphs.get(oldest_key) {
    Some(arr) => {
      let _ = arr.remove(oldest_idx)
      if arr.length() == 0 {
        let _ = self.color_glyphs.remove(oldest_key)
      }
      self.color_glyph_count = self.color_glyph_count - 1
    }
    None => ()
  }
}

///|
// Decode a CBDT color glyph and cache its RGBA bitmap in the color atlas.
fn Renderer2D::color_glyph_for(
  self : Renderer2D,
  font : FontFace,
  cp : Int,
  size : Float,
) -> CachedColorGlyph? raise @tycho.RhiError {
  let q4 = (size * (4.0 : Float) + (0.5 : Float)).to_int()
  let key = font.id()
  let arr = match self.color_glyphs.get(key) {
    Some(a) => a
    None => []
  }
  for e in arr {
    if e.font_id == key && e.cp == cp && e.q4 == q4 {
      e.last_frame = self.frame_idx
      return Some(e)
    }
  }
  let (cb, img) = match font.color_glyph(cp, size) {
    Some(v) => v
    None => return None
  }
  if img.width <= 0 || img.height <= 0 || img.rgba.length() < img.width * img.height * 4 {
    return None
  }
  if self.color_glyph_count >= 256 {
    self.evict_oldest_color_glyph()
  }
  let mut placed = self.color_atlas.alloc_and_upload(
    img.width,
    img.height,
    img.rgba,
    padding=1,
  )
  let mut cleared = false
  match placed {
    Some(_) => ()
    None => {
      self.color_atlas.reset()
      self.color_glyphs.clear()
      self.color_glyph_count = 0
      self.uploaded_images.clear()
      self.color_atlas_gen = self.color_atlas.generation()
      cleared = true
      placed = self.color_atlas.alloc_and_upload(
        img.width,
        img.height,
        img.rgba,
        padding=1,
      )
    }
  }
  let (tx, ty) = match placed {
    Some(v) => v
    None => return None
  }
  let (u0, v0, u1, v1) = self.color_atlas.uv_rect(
    tx,
    ty,
    img.width,
    img.height,
  )
  let e : CachedColorGlyph = {
    font_id: key,
    cp,
    q4,
    uv0: u0,
    uv1: v0,
    uv2: u1,
    uv3: v1,
    width: cb.width,
    height: cb.height,
    bearing_x: cb.bearing_x,
    bearing_y: cb.bearing_y,
    ppem: cb.ppem,
    last_frame: self.frame_idx,
  }
  if cleared {
    self.color_glyphs[key] = [e]
    self.color_glyph_count = 1
  } else {
    arr.push(e)
    self.color_glyphs[key] = arr
    self.color_glyph_count = self.color_glyph_count + 1
  }
  Some(e)
}

///|
// Draw a solid fill through the CPU coverage atlas. Returns false when the
// path is too large or could not be allocated (caller falls back to MSAA).
fn Renderer2D::try_draw_coverage(
  self : Renderer2D,
  cmd : @tycho.CommandBuffer,
  path : Path,
  paint : Paint,
) -> Bool raise @tycho.RhiError {
  if path.is_empty() {
    return false
  }
  let e = match self.coverage_for(path, self.cur_transform) {
    Some(e) => e
    None => return false
  }
  self.coverage_draws = self.coverage_draws + 1
  let saved = self.cur_transform
  self.cur_transform = Matrix3::identity()
  self.set_blend(cmd, paint.blend_mode)
  self.emit_prim(
    cmd,
    Float::from_int(e.x),
    Float::from_int(e.y),
    Float::from_int(e.w),
    Float::from_int(e.h),
    (0.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    paint.color,
    Color::transparent(),
    e.u0,
    e.v0,
    e.u1,
    e.v1,
    (0.0 : Float),
    (-1.5 : Float),
    (6.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    extra0=Float::from_int(e.tex_id),
  )
  self.cur_transform = saved
  true
}

///|
// Map a Paint color filter onto the layer's color-matrix path. Blend filters
// are supported for Multiply/Screen (both are affine for a constant color).
fn color_filter_matrix(cf : ColorFilter) -> FixedArray[Float]? {
  match cf {
    ColorFilter::Matrix(m) => Some(m)
    ColorFilter::Blend(c, BlendMode2D::Multiply) => {
      let m : FixedArray[Float] = FixedArray::make(20, (0.0 : Float))
      m[0] = c.r
      m[6] = c.g
      m[12] = c.b
      m[18] = (1.0 : Float)
      Some(m)
    }
    ColorFilter::Blend(c, BlendMode2D::Screen) => {
      let m : FixedArray[Float] = FixedArray::make(20, (0.0 : Float))
      m[0] = (1.0 : Float) - c.r
      m[4] = c.r
      m[6] = (1.0 : Float) - c.g
      m[9] = c.g
      m[12] = (1.0 : Float) - c.b
      m[14] = c.b
      m[18] = (1.0 : Float)
      Some(m)
    }
    _ => None
  }
}

///|
fn Renderer2D::vert_pipe_for(
  self : Renderer2D,
  fi : Int,
  has_clip : Bool,
) -> @tycho.Pipeline raise @tycho.RhiError {
  let idx = fi * 2 + (if has_clip { 1 } else { 0 })
  match self.vert_pipes[idx] {
    Some(p) => p
    None => {
      let fmt = match fi {
        0 => @tycho.TextureFormat::RGBA8
        1 => @tycho.TextureFormat::BGRA8
        2 => @tycho.TextureFormat::RGBA8Srgb
        _ => @tycho.TextureFormat::BGRA8Srgb
      }
      let layout = @tycho.VertexBufferLayout::new(VERT_BYTES, [
        @tycho.VertexAttribute::new(0, @tycho.VertexFormat::Float2, 0),
        @tycho.VertexAttribute::new(1, @tycho.VertexFormat::Float4, 8),
        @tycho.VertexAttribute::new(2, @tycho.VertexFormat::Float2, 24),
      ])
      let pipe = self.dev.create_graphics_pipeline(
        @tycho.PipelineDesc::from_spirv(
          spv_vertices_vert,
          spv_vertices_frag,
          blend_mode=Some(@tycho.BlendMode::Premultiplied),
          cull_mode=@tycho.CullMode::None,
          color_format=Some(fmt),
          depth_format=Some(@tycho.TextureFormat::Depth24Stencil8),
          stencil=if has_clip { Some(self.st_test_clip) } else { None },
          vertex_layouts=[layout],
        ),
      )
      self.vert_pipes[idx] = Some(pipe)
      pipe
    }
  }
}

///|
fn Renderer2D::draw_vertices_gpu(
  self : Renderer2D,
  cmd : @tycho.CommandBuffer,
  vertices : Array[Vertex2D],
  indices : Array[Int],
  _paint : Paint,
  image : Image2D?,
) -> Unit raise @tycho.RhiError {
  let n_in = vertices.length()
  if n_in < 3 || self.active_w <= 0 || self.active_h <= 0 {
    return
  }
  let avail = MAX_VERTS_PER_FRAME - self.vert_cursor
  if avail < 3 {
    return
  }
  let n = if n_in > avail { avail } else { n_in }
  let mut i = 0
  while i < n {
    let v = vertices[i]
    let p = self.cur_transform.map_point({ x: v.x, y: v.y })
    let o = i * VERT_FLOATS
    self.vert_scratch[o] = p.x
    self.vert_scratch[o + 1] = p.y
    self.vert_scratch[o + 2] = v.color.r
    self.vert_scratch[o + 3] = v.color.g
    self.vert_scratch[o + 4] = v.color.b
    self.vert_scratch[o + 5] = v.color.a
    self.vert_scratch[o + 6] = v.u
    self.vert_scratch[o + 7] = v.v
    i = i + 1
  }
  let vbase = self.slot_vert_base() + self.vert_cursor * VERT_BYTES
  self.vert_vbuf.upload_floats(
    self.vert_scratch,
    offset=vbase,
    count=n * VERT_FLOATS,
  )
  let idx_avail = MAX_INDICES_PER_FRAME - self.vert_index_cursor
  let idx_want = if indices.length() == 0 { n } else { indices.length() }
  let idx_count = if idx_want > idx_avail { idx_avail } else { idx_want }
  if idx_count < 3 {
    return
  }
  let mut k = 0
  while k < idx_count {
    let src = if indices.length() == 0 { k } else { indices[k] }
    let safe = if src < 0 || src >= n { 0 } else { src }
    self.vert_index_scratch[k] = safe.reinterpret_as_uint()
    k = k + 1
  }
  let ibase = self.slot_index_base() + self.vert_index_cursor * 4
  self.vert_ibuf.upload_uint32(
    self.vert_index_scratch,
    offset=ibase,
    count=idx_count,
  )
  self.vert_cursor = self.vert_cursor + n
  self.vert_index_cursor = self.vert_index_cursor + idx_count
  let (use_tex, u0, v0, u1, v1) = match image {
    Some(img) => {
      let (a, b, c, d) = self.ensure_image_uv(img)
      if c > a && d > b {
        ((1.0 : Float), a, b, c, d)
      } else {
        ((0.0 : Float), (0.0 : Float), (0.0 : Float), (0.0 : Float), (0.0 : Float))
      }
    }
    None =>
      ((0.0 : Float), (0.0 : Float), (0.0 : Float), (0.0 : Float), (0.0 : Float))
  }
  let fi = color_format_index(self.cur_color_format)
  let pipe = self.vert_pipe_for(fi, self.has_stencil_clip)
  cmd.bind_pipeline(pipe)
  if self.has_stencil_clip {
    cmd.set_stencil_reference(128)
  }
  cmd.bind_vertex(0, self.vert_vbuf, offset=vbase)
  cmd.bind_index(self.vert_ibuf, @tycho.IndexType::Uint32, offset=ibase)
  cmd.bind_texture(pipe, 0, self.color_atlas.texture, self.sampler)
  let fw = Float::from_int(self.active_w)
  let fh = Float::from_int(self.active_h)
  cmd.push_constants_floats(pipe, [
    fw,
    fh,
    (1.0 : Float) / fw,
    (1.0 : Float) / fh,
    u0,
    v0,
    u1,
    v1,
    use_tex,
    (0.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
  ])
  cmd.draw_indexed(idx_count)
}

///|
fn Renderer2D::draw_path_gpu(
  self : Renderer2D,
  cmd : @tycho.CommandBuffer,
  path : Path,
  paint : Paint,
) -> Unit raise @tycho.RhiError {
  self.flush_prims(cmd)
  let use_msaa = paint.anti_alias && self.msaa_supported
  let has_filter = match paint.image_filter {
    Some(_) => true
    None => false
  }
  if use_msaa || has_filter {
    let raw_bounds = self.cur_transform.map_rect(path.bounds()).inflate(paint.stroke_width + (4.0 : Float))
    let clipped = raw_bounds.intersect(self.cur_scissor)
    if clipped.is_empty() {
      return
    }
    let bx = clipped.x.floor()
    let by = clipped.y.floor()
    let bw = @tmath.max_f((1.0 : Float), (clipped.right().ceil() - bx)).to_int()
    let bh = @tmath.max_f((1.0 : Float), (clipped.bottom().ceil() - by)).to_int()
    let otex = self.active_tex.unwrap()
    let ods = self.active_ds.unwrap()
    let ow = self.active_w
    let oh = self.active_h
    cmd.end_render_pass()

    let local_xf = Matrix3::{
      a: self.cur_transform.a,
      c: self.cur_transform.c,
      tx: self.cur_transform.tx - bx,
      b: self.cur_transform.b,
      d: self.cur_transform.d,
      ty: self.cur_transform.ty - by,
    }
    let (res_col, res_ds) = self.rt_pool.acquire(
      bw,
      bh,
      with_depth_stencil=!use_msaa,
      slot=self.active_rt_slot,
    )
    if use_msaa {
      let (msaa_col, msaa_ds_opt) = self.rt_pool.acquire(
        bw,
        bh,
        with_depth_stencil=true,
        samples=@tycho.SampleCount::X4,
        slot=self.active_rt_slot,
      )
      let msaa_ds = msaa_ds_opt.unwrap()
      cmd.begin_render_pass(
        [
          @tycho.RenderTargetDesc::new(
            msaa_col,
            load_op=@tycho.LoadOp::Clear,
            store_op=@tycho.StoreOp::DontCare,
            clear_color=@tycho.ClearColor::rgba((0.0 : Float), (0.0 : Float), (0.0 : Float), (0.0 : Float)),
            resolve_texture=Some(res_col),
          ),
        ],
        depth=Some(
          @tycho.DepthTargetDesc::new(
            msaa_ds,
            load_op=@tycho.LoadOp::Clear,
            store_op=@tycho.StoreOp::DontCare,
            stencil_load_op=@tycho.LoadOp::Clear,
            stencil_store_op=@tycho.StoreOp::DontCare,
            clear_stencil=0,
          ),
        ),
      )
      cmd.set_viewport((0.0 : Float), (0.0 : Float), Float::from_int(msaa_col.width()), Float::from_int(msaa_col.height()))
      cmd.set_scissor(0, 0, bw, bh)
      self.draw_path_raw(cmd, path, paint, local_xf, msaa_col.width(), msaa_col.height(), true)
      cmd.end_render_pass()
    } else {
      self.begin_target_pass(
        cmd,
        res_col,
        res_ds.unwrap(),
        res_col.width(),
        res_col.height(),
        @tycho.LoadOp::Clear,
        Color::transparent(),
        @tycho.LoadOp::Clear,
      )
      cmd.set_scissor(0, 0, bw, bh)
      self.draw_path_raw(cmd, path, paint, local_xf, res_col.width(), res_col.height(), false)
      cmd.end_render_pass()
    }

    let rw_f = Float::from_int(res_col.width())
    let rh_f = Float::from_int(res_col.height())
    let su1 = Float::from_int(bw) / rw_f
    let sv1 = Float::from_int(bh) / rh_f
    let dst_r = Rect::new(bx, by, Float::from_int(bw), Float::from_int(bh))

    match paint.image_filter {
      Some(ImageFilter::Blur(sx, sy, _)) => {
        let (btex, bbw, bbh) = self.run_blur_passes(
          cmd,
          res_col,
          bw,
          bh,
          sx,
          sy,
          src_u0=(0.0 : Float),
          src_v0=(0.0 : Float),
          src_u1=su1,
          src_v1=sv1,
        )
        self.begin_target_pass(cmd, otex, ods, ow, oh, @tycho.LoadOp::Load, Color::transparent(), @tycho.LoadOp::Load)
        let bu1 = Float::from_int(bbw) / Float::from_int(btex.width())
        let bv1 = Float::from_int(bbh) / Float::from_int(btex.height())
        self.composite_texture(cmd, btex, (0.0 : Float), (0.0 : Float), bu1, bv1, dst_r, Color::white(), paint.blend_mode, self.cur_clip_rrect)
      }
      Some(ImageFilter::DropShadow(dx, dy, sx, sy, scol)) => {
        let (btex, bbw, bbh) = self.run_blur_passes(
          cmd,
          res_col,
          bw,
          bh,
          sx,
          sy,
          src_u0=(0.0 : Float),
          src_v0=(0.0 : Float),
          src_u1=su1,
          src_v1=sv1,
        )
        self.begin_target_pass(cmd, otex, ods, ow, oh, @tycho.LoadOp::Load, Color::transparent(), @tycho.LoadOp::Load)
        let bu1 = Float::from_int(bbw) / Float::from_int(btex.width())
        let bv1 = Float::from_int(bbh) / Float::from_int(btex.height())
        self.composite_texture(cmd, btex, (0.0 : Float), (0.0 : Float), bu1, bv1, dst_r.offset(dx, dy), scol, paint.blend_mode, self.cur_clip_rrect, mode=(3.0 : Float))
        self.composite_texture(cmd, res_col, (0.0 : Float), (0.0 : Float), su1, sv1, dst_r, Color::white(), paint.blend_mode, self.cur_clip_rrect)
      }
      Some(ImageFilter::ColorMatrix(mat)) => {
        self.begin_target_pass(cmd, otex, ods, ow, oh, @tycho.LoadOp::Load, Color::transparent(), @tycho.LoadOp::Load)
        self.composite_texture(cmd, res_col, (0.0 : Float), (0.0 : Float), su1, sv1, dst_r, Color::white(), paint.blend_mode, self.cur_clip_rrect, mode=(2.0 : Float), color_matrix=Some(mat))
      }
      None => {
        self.begin_target_pass(cmd, otex, ods, ow, oh, @tycho.LoadOp::Load, Color::transparent(), @tycho.LoadOp::Load)
        self.composite_texture(cmd, res_col, (0.0 : Float), (0.0 : Float), su1, sv1, dst_r, Color::white(), paint.blend_mode, self.cur_clip_rrect)
      }
    }
    return
  }
  cmd.set_scissor(
    self.cur_scissor.x.to_int(),
    self.cur_scissor.y.to_int(),
    self.cur_scissor.width.to_int(),
    self.cur_scissor.height.to_int(),
  )
  self.draw_path_raw(cmd, path, paint, self.cur_transform, self.active_w, self.active_h, false)
}

///|
fn Renderer2D::downsample_region(
  self : Renderer2D,
  cmd : @tycho.CommandBuffer,
  src : @tycho.Texture,
  src_w : Int,
  src_h : Int,
  src_u0 : Float,
  src_v0 : Float,
  src_u1 : Float,
  src_v1 : Float,
  dst_w : Int,
  dst_h : Int,
) -> (@tycho.Texture, Int, Int) raise @tycho.RhiError {
  let (dst, _) = self.rt_pool.acquire(
    dst_w,
    dst_h,
    with_depth_stencil=false,
    slot=self.active_rt_slot,
  )
  let dw = Float::from_int(dst.width())
  let dh = Float::from_int(dst.height())
  let sw = if src_w > 0 { src_w } else { 1 }
  let sh = if src_h > 0 { src_h } else { 1 }
  let texel_u = (src_u1 - src_u0) / Float::from_int(sw)
  let texel_v = (src_v1 - src_v0) / Float::from_int(sh)
  cmd.begin_render_pass([
    @tycho.RenderTargetDesc::new(
      dst,
      load_op=@tycho.LoadOp::Clear,
      store_op=@tycho.StoreOp::Store,
      clear_color=@tycho.ClearColor::rgba((0.0 : Float), (0.0 : Float), (0.0 : Float), (0.0 : Float)),
    ),
  ])
  cmd.set_viewport((0.0 : Float), (0.0 : Float), dw, dh)
  cmd.set_scissor(0, 0, dst_w, dst_h)
  cmd.bind_pipeline(self.blur_pipe)
  cmd.bind_texture(self.blur_pipe, 0, src, self.sampler)
  cmd.bind_storage(self.blur_pipe, 0, self.color_mat_ssbo, offset=self.slot_cmat_base(), size=80)
  cmd.push_constants_floats(self.blur_pipe, [
    (0.0 : Float),
    (0.0 : Float),
    Float::from_int(dst_w) / dw,
    Float::from_int(dst_h) / dh,
    src_u0,
    src_v0,
    src_u1,
    src_v1,
    texel_u,
    texel_v,
    dw,
    (4.0 : Float),
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
  (dst, dst_w, dst_h)
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
  // The embedded 9-tap kernel has sigma ~= 1.7 texels. Downsample by 2 until the
  // requested sigma is representable with a step <= 4 texels, so large-radius
  // blurs stay well sampled instead of becoming sparse and banded.
  let mut cur_tex = src
  let mut cur_w = src_w
  let mut cur_h = src_h
  let mut cu0 = src_u0
  let mut cv0 = src_v0
  let mut cu1 = src_u1
  let mut cv1 = src_v1
  let sigma = @tmath.max_f(@tmath.max_f(sx, sy), (0.01 : Float))
  let mut level = 0
  while level < 4 &&
    sigma / Float::from_int(1 << level) > (6.8 : Float) &&
    cur_w > 2 &&
    cur_h > 2 {
    let nw = if cur_w / 2 > 1 { cur_w / 2 } else { 1 }
    let nh = if cur_h / 2 > 1 { cur_h / 2 } else { 1 }
    let (ds, dw, dh) = self.downsample_region(
      cmd,
      cur_tex,
      cur_w,
      cur_h,
      cu0,
      cv0,
      cu1,
      cv1,
      nw,
      nh,
    )
    cur_tex = ds
    cur_w = dw
    cur_h = dh
    cu0 = (0.0 : Float)
    cv0 = (0.0 : Float)
    cu1 = Float::from_int(dw) / Float::from_int(ds.width())
    cv1 = Float::from_int(dh) / Float::from_int(ds.height())
    level = level + 1
  }
  let scale = Float::from_int(1 << level)
  let bw = if cur_w / 2 > 1 { cur_w / 2 } else { 1 }
  let bh = if cur_h / 2 > 1 { cur_h / 2 } else { 1 }
  let (tex_a, _) = self.rt_pool.acquire(bw, bh, with_depth_stencil=false, slot=self.active_rt_slot)
  let (tex_b, _) = self.rt_pool.acquire(bw, bh, with_depth_stencil=false, slot=self.active_rt_slot)
  let aw_f = Float::from_int(tex_a.width())
  let ah_f = Float::from_int(tex_a.height())
  let bw_norm = Float::from_int(bw) / aw_f
  let bh_norm = Float::from_int(bh) / ah_f
  let rad_x = @tmath.clamp_f(sx / scale / (1.7 : Float), (0.5 : Float), (4.0 : Float))
  let rad_y = @tmath.clamp_f(sy / scale / (1.7 : Float), (0.5 : Float), (4.0 : Float))

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
  cmd.bind_texture(self.blur_pipe, 0, cur_tex, self.sampler)
  cmd.bind_storage(self.blur_pipe, 0, self.color_mat_ssbo, offset=self.slot_cmat_base(), size=80)
  cmd.push_constants_floats(self.blur_pipe, [
    (0.0 : Float),
    (0.0 : Float),
    bw_norm,
    bh_norm,
    cu0,
    cv0,
    cu1,
    cv1,
    rad_x / Float::from_int(cur_tex.width()),
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
  cmd.bind_storage(self.blur_pipe, 0, self.color_mat_ssbo, offset=self.slot_cmat_base(), size=80)
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
  mode? : Float = (1.0 : Float),
  color_matrix? : FixedArray[Float]? = None,
) -> Unit raise @tycho.RhiError {
  match color_matrix {
    Some(mat) =>
      if mat.length() >= 20 {
        self.color_mat_ssbo.upload_floats(mat, offset=self.slot_cmat_base(), count=20)
      }
    None => ()
  }
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
  cmd.bind_storage(pipe, 0, self.color_mat_ssbo, offset=self.slot_cmat_base(), size=80)
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
    mode,
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
// Queue an anti-aliased path for the shared MSAA batch, or draw it immediately
// when batching is not pixel-equivalent (filters, non-SrcOver, stencil clips).
fn Renderer2D::queue_path(
  self : Renderer2D,
  cmd : @tycho.CommandBuffer,
  path : Path,
  paint : Paint,
) -> Unit raise @tycho.RhiError {
  // Solid antialiased fills go through the CPU coverage atlas first; MSAA
  // remains the fallback for large paths, gradients, and filters.
  let solid_fill = paint.style == PaintStyle::Fill &&
    (match paint.shader {
      None => true
      _ => false
    })
  if self.coverage_enabled && solid_fill && paint.anti_alias {
    self.flush_path_batch(cmd)
    if self.try_draw_coverage(cmd, path, paint) {
      return
    }
  }
  let no_filter = match paint.image_filter {
    None => true
    Some(_) => false
  }
  let batchable = self.msaa_supported &&
    paint.anti_alias &&
    no_filter &&
    paint.blend_mode == BlendMode2D::SrcOver &&
    !self.has_stencil_clip
  if !batchable {
    self.flush_path_batch(cmd)
    self.draw_path_gpu(cmd, path, paint)
    return
  }
  let raw = self.cur_transform.map_rect(path.bounds()).inflate(paint.stroke_width + (2.0 : Float))
  let b = raw.intersect(self.cur_scissor)
  if b.is_empty() {
    return
  }
  if self.path_batch.length() >= 8 {
    self.flush_path_batch(cmd)
  }
  let mut union = b
  match self.path_batch_bounds {
    Some(prev) => {
      let merged = prev.union(b)
      let target_area = Float::from_int(self.active_w * self.active_h)
      let too_big = merged.width * merged.height > target_area * (0.5 : Float)
      if !prev.intersect(b).is_empty() || too_big {
        self.flush_path_batch(cmd)
      } else {
        union = merged
      }
    }
    None => ()
  }
  self.path_batch.push({ path, paint, transform: self.cur_transform })
  let next = match self.path_batch_bounds {
    Some(p) => p.union(b)
    None => union
  }
  self.path_batch_bounds = Some(next)
}

///|
fn Renderer2D::flush_path_batch(
  self : Renderer2D,
  cmd : @tycho.CommandBuffer,
) -> Unit raise @tycho.RhiError {
  if self.path_batch.length() == 0 {
    self.path_batch_bounds = None
    return
  }
  let bounds = match self.path_batch_bounds {
    Some(b) => b
    None => {
      self.path_batch.clear()
      return
    }
  }
  self.path_batch_bounds = None
  let clipped = bounds.intersect(self.cur_scissor)
  let has_target = match (self.active_tex, self.active_ds) {
    (Some(_), Some(_)) => true
    _ => false
  }
  if clipped.is_empty() || !has_target {
    self.path_batch.clear()
    return
  }
  self.flush_prims(cmd)
  let bx = clipped.x.floor()
  let by = clipped.y.floor()
  let bw = @tmath.max_f((1.0 : Float), clipped.right().ceil() - bx).to_int()
  let bh = @tmath.max_f((1.0 : Float), clipped.bottom().ceil() - by).to_int()
  let otex = self.active_tex.unwrap()
  let ods = self.active_ds.unwrap()
  let ow = self.active_w
  let oh = self.active_h
  cmd.end_render_pass()
  let (res_col, _) = self.rt_pool.acquire(
    bw,
    bh,
    with_depth_stencil=false,
    slot=self.active_rt_slot,
  )
  let (msaa_col, msaa_ds_opt) = self.rt_pool.acquire(
    bw,
    bh,
    with_depth_stencil=true,
    samples=@tycho.SampleCount::X4,
    slot=self.active_rt_slot,
  )
  let msaa_ds = msaa_ds_opt.unwrap()
  self.path_batch_count = self.path_batch_count + 1
  cmd.begin_render_pass(
    [
      @tycho.RenderTargetDesc::new(
        msaa_col,
        load_op=@tycho.LoadOp::Clear,
        store_op=@tycho.StoreOp::DontCare,
        clear_color=@tycho.ClearColor::rgba((0.0 : Float), (0.0 : Float), (0.0 : Float), (0.0 : Float)),
        resolve_texture=Some(res_col),
      ),
    ],
    depth=Some(
      @tycho.DepthTargetDesc::new(
        msaa_ds,
        load_op=@tycho.LoadOp::Clear,
        store_op=@tycho.StoreOp::DontCare,
        stencil_load_op=@tycho.LoadOp::Clear,
        stencil_store_op=@tycho.StoreOp::DontCare,
        clear_stencil=0,
      ),
    ),
  )
  cmd.set_viewport(
    (0.0 : Float),
    (0.0 : Float),
    Float::from_int(msaa_col.width()),
    Float::from_int(msaa_col.height()),
  )
  cmd.set_scissor(0, 0, bw, bh)
  let count = self.path_batch.length()
  for i = 0; i < count; i = i + 1 {
    let pp = self.path_batch[i]
    let xf = pp.transform
    let local_xf = Matrix3::{
      a: xf.a,
      c: xf.c,
      tx: xf.tx - bx,
      b: xf.b,
      d: xf.d,
      ty: xf.ty - by,
    }
    self.draw_path_raw(
      cmd,
      pp.path,
      pp.paint,
      local_xf,
      msaa_col.width(),
      msaa_col.height(),
      true,
    )
  }
  self.path_batch.clear()
  cmd.end_render_pass()
  self.begin_target_pass(
    cmd,
    otex,
    ods,
    ow,
    oh,
    @tycho.LoadOp::Load,
    Color::transparent(),
    @tycho.LoadOp::Load,
  )
  let rw = Float::from_int(res_col.width())
  let rh = Float::from_int(res_col.height())
  let su1 = Float::from_int(bw) / rw
  let sv1 = Float::from_int(bh) / rh
  let dst = Rect::new(bx, by, Float::from_int(bw), Float::from_int(bh))
  self.composite_texture(
    cmd,
    res_col,
    (0.0 : Float),
    (0.0 : Float),
    su1,
    sv1,
    dst,
    Color::white(),
    BlendMode2D::SrcOver,
    self.cur_clip_rrect,
  )
}

///|
// Rotate an A8 glyph bitmap around its center for text-on-path.
fn rotate_coverage(
  w : Int,
  h : Int,
  pixels : Bytes,
  angle : Float,
) -> (Int, Int, Bytes) {
  if w <= 0 || h <= 0 {
    return (0, 0, b"")
  }
  let c = @tmath.cos(angle)
  let s = @tmath.sin(angle)
  if @tmath.abs_f(s) < (0.001 : Float) && c > (0.0 : Float) {
    return (w, h, pixels)
  }
  let fw = Float::from_int(w)
  let fh = Float::from_int(h)
  let nw = @tmath.max_f(
    (1.0 : Float),
    (@tmath.abs_f(fw * c) + @tmath.abs_f(fh * s)).ceil(),
  ).to_int()
  let nh = @tmath.max_f(
    (1.0 : Float),
    (@tmath.abs_f(fw * s) + @tmath.abs_f(fh * c)).ceil(),
  ).to_int()
  let out = Array::make(nw * nh, (0 : Byte))
  let cx = fw * (0.5 : Float)
  let cy = fh * (0.5 : Float)
  let ox = Float::from_int(nw) * (0.5 : Float)
  let oy = Float::from_int(nh) * (0.5 : Float)
  for y = 0; y < nh; y = y + 1 {
    for x = 0; x < nw; x = x + 1 {
      let dx = Float::from_int(x) + (0.5 : Float) - ox
      let dy = Float::from_int(y) + (0.5 : Float) - oy
      let sx = dx * c + dy * s + cx
      let sy = -dx * s + dy * c + cy
      let ix = sx.floor().to_int()
      let iy = sy.floor().to_int()
      if ix >= 0 && ix < w && iy >= 0 && iy < h {
        out[y * nw + x] = pixels[iy * w + ix]
      }
    }
  }
  (nw, nh, Bytes::from_array(out))
}

///|
fn Renderer2D::replay_ops(
  self : Renderer2D,
  cmd : @tycho.CommandBuffer,
  ops : FixedArray[DrawOp],
) -> Unit raise @tycho.RhiError {
  for op in ops {
    match op {
      DrawOp::DrawPath(path, paint) => {
        self.queue_path(cmd, path, paint)
        continue
      }
      _ => self.flush_path_batch(cmd)
    }
    match op {
      DrawOp::Clear(col) => {
        self.set_blend(cmd, BlendMode2D::SrcOver)
        let prev_xf = self.cur_transform
        self.cur_transform = Matrix3::identity()
        self.emit_prim(
          cmd,
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
          layer_rect: Rect::zero(),
          layer_empty: false,
          outer_tex: None,
          outer_ds: None,
          outer_w: 0,
          outer_h: 0,
        })
      DrawOp::SaveLayer(bounds_opt, paint) => {
        self.flush_prims(cmd)
        let otex = self.active_tex
        let ods = self.active_ds
        let ow = self.active_w
        let oh = self.active_h
        let parent_xf = self.cur_transform
        let parent_scissor = self.cur_scissor
        // The layer only needs to cover the caller-provided bounds (when given)
        // intersected with the active scissor, instead of the whole scissor.
        let mapped = match bounds_opt {
          Some(b) => parent_xf.map_rect(b)
          None => parent_scissor
        }
        let clipped = mapped.intersect(parent_scissor)
        let empty = clipped.is_empty()
        let (lx, ly, lw, lh) = if empty {
          ((0.0 : Float), (0.0 : Float), (1.0 : Float), (1.0 : Float))
        } else {
          let x = clipped.x.floor()
          let y = clipped.y.floor()
          let w = @tmath.max_f((1.0 : Float), clipped.right().ceil() - x)
          let h = @tmath.max_f((1.0 : Float), clipped.bottom().ceil() - y)
          (x, y, w, h)
        }
        let layer_rect = if empty {
          Rect::zero()
        } else {
          Rect::new(lx, ly, lw, lh)
        }
        // Paint-level filters are independent of ImageFilter; map them onto
        // the layer filter path (Blend color filters remain unsupported).
        let effective_filter = match paint.image_filter {
          Some(f) => Some(f)
          None =>
            match paint.mask_filter {
              Some(MaskFilter::Blur(sx, sy)) =>
                Some(ImageFilter::Blur(sx, sy, TileMode::Clamp))
              None =>
                match paint.color_filter {
                  Some(cf) =>
                    match color_filter_matrix(cf) {
                      Some(m) => Some(ImageFilter::ColorMatrix(m))
                      None => None
                    }
                  None => None
                }
            }
        }
        let layer_paint = { ..paint, image_filter: effective_filter }
        self.state_stack.push({
          transform: parent_xf,
          scissor: parent_scissor,
          clip_rrect: self.cur_clip_rrect,
          has_stencil_clip: self.has_stencil_clip,
          is_layer: true,
          layer_paint,
          layer_rect,
          layer_empty: empty,
          outer_tex: otex,
          outer_ds: ods,
          outer_w: ow,
          outer_h: oh,
        })
        cmd.end_render_pass()
        let (ltex, lds_opt) = self.rt_pool.acquire(
          lw.to_int(),
          lh.to_int(),
          with_depth_stencil=true,
          slot=self.active_rt_slot,
        )
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
        // Render layer content in layer-local coordinates so the bucket-padded
        // region stays empty and compositing only reads [0, lw] x [0, lh].
        self.cur_transform = parent_xf.concat(Matrix3::translate(-lx, -ly))
        self.cur_scissor = Rect::new((0.0 : Float), (0.0 : Float), lw, lh)
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
          layer_rect: Rect::zero(),
          layer_empty: false,
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
            if st.is_layer {
              self.flush_prims(cmd)
              let ltex = self.active_tex.unwrap()
              cmd.end_render_pass()
              let tex_w = Float::from_int(ltex.width())
              let tex_h = Float::from_int(ltex.height())
              let layer_w = st.layer_rect.width
              let layer_h = st.layer_rect.height
              let base_u1 = if tex_w > (0.0 : Float) { layer_w / tex_w } else { (0.0 : Float) }
              let base_v1 = if tex_h > (0.0 : Float) { layer_h / tex_h } else { (0.0 : Float) }
              let mut draw_tex = ltex
              let mut src_u1 = base_u1
              let mut src_v1 = base_v1
              let mut shadow_tex : @tycho.Texture? = None
              let mut shadow_u1 = (1.0 : Float)
              let mut shadow_v1 = (1.0 : Float)
              if !st.layer_empty {
                match st.layer_paint.image_filter {
                  Some(ImageFilter::Blur(sx, sy, _)) => {
                    let (btex, bw, bh) = self.run_blur_passes(
                      cmd,
                      ltex,
                      layer_w.to_int(),
                      layer_h.to_int(),
                      sx,
                      sy,
                      src_u0=(0.0 : Float),
                      src_v0=(0.0 : Float),
                      src_u1=base_u1,
                      src_v1=base_v1,
                    )
                    draw_tex = btex
                    src_u1 = Float::from_int(bw) / Float::from_int(btex.width())
                    src_v1 = Float::from_int(bh) / Float::from_int(btex.height())
                  }
                  Some(ImageFilter::DropShadow(_, _, sx, sy, _)) => {
                    let (btex, bw, bh) = self.run_blur_passes(
                      cmd,
                      ltex,
                      layer_w.to_int(),
                      layer_h.to_int(),
                      sx,
                      sy,
                      src_u0=(0.0 : Float),
                      src_v0=(0.0 : Float),
                      src_u1=base_u1,
                      src_v1=base_v1,
                    )
                    shadow_tex = Some(btex)
                    shadow_u1 = Float::from_int(bw) / Float::from_int(btex.width())
                    shadow_v1 = Float::from_int(bh) / Float::from_int(btex.height())
                  }
                  _ => ()
                }
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
              if !st.layer_empty {
                match (st.layer_paint.image_filter, shadow_tex) {
                  (Some(ImageFilter::DropShadow(dx, dy, _, _, scol)), Some(stex)) =>
                    self.composite_texture(
                      cmd,
                      stex,
                      (0.0 : Float),
                      (0.0 : Float),
                      shadow_u1,
                      shadow_v1,
                      st.layer_rect.offset(dx, dy),
                      scol,
                      st.layer_paint.blend_mode,
                      None,
                      mode=(3.0 : Float),
                    )
                  _ => ()
                }
                match st.layer_paint.image_filter {
                  Some(ImageFilter::ColorMatrix(mat)) =>
                    self.composite_texture(
                      cmd,
                      draw_tex,
                      (0.0 : Float),
                      (0.0 : Float),
                      src_u1,
                      src_v1,
                      st.layer_rect,
                      st.layer_paint.color,
                      st.layer_paint.blend_mode,
                      None,
                      mode=(2.0 : Float),
                      color_matrix=Some(mat),
                    )
                  _ =>
                    self.composite_texture(
                      cmd,
                      draw_tex,
                      (0.0 : Float),
                      (0.0 : Float),
                      src_u1,
                      src_v1,
                      st.layer_rect,
                      st.layer_paint.color,
                      st.layer_paint.blend_mode,
                      None,
                    )
                }
              }
            } else {
              let had_stencil = self.has_stencil_clip
              let clip_changed = self.cur_clip_rrect != st.clip_rrect
              // Rect clips are per-instance and transforms are baked into the
              // prim, so a plain save/restore does not need to split the batch.
              // Only an analytic ClipRRect change or leaving a stencil clip does.
              if clip_changed || (had_stencil && !st.has_stencil_clip) {
                self.flush_prims(cmd)
              }
              self.cur_transform = st.transform
              self.cur_scissor = st.scissor
              self.cur_clip_rrect = st.clip_rrect
              self.has_stencil_clip = st.has_stencil_clip
              if had_stencil && !st.has_stencil_clip {
                // Re-clear stencil bit 0x80 via fast fullscreen quad
                let fw = Float::from_int(self.active_w)
                let fh = Float::from_int(self.active_h)
                let (cstart, ccnt) = self.upload_path_verts([
                  (0.0 : Float), (0.0 : Float), fw, (0.0 : Float), fw, fh,
                  (0.0 : Float), (0.0 : Float), fw, fh, (0.0 : Float), fh,
                ])
                cmd.set_scissor(0, 0, self.active_w, self.active_h)
                cmd.bind_pipeline(self.stencil_clear_clip_pipe)
                cmd.bind_vertex(0, self.path_vbuf, offset=self.slot_path_base())
                cmd.push_constants_floats(
                  self.stencil_clear_clip_pipe,
                  [fw, fh, (1.0 : Float) / fw, (1.0 : Float) / fh],
                )
                cmd.draw_instanced(ccnt, 1, cstart, 0)
              }
            }
          }
          None => ()
        }
      DrawOp::Concat(m) => self.cur_transform = self.cur_transform.concat(m)
      DrawOp::ClipRect(r, op) => {
        let mapped = self.cur_transform.map_rect(r)
        match op {
          // Rect clips are emitted per instance, so no batch flush is needed.
          ClipOp::Intersect => self.cur_scissor = self.cur_scissor.intersect(mapped)
          ClipOp::Difference => {
            self.flush_prims(cmd)
            let fw = Float::from_int(self.active_w)
            let fh = Float::from_int(self.active_h)
            if !self.has_stencil_clip {
              let l = self.cur_scissor.x
              let t = self.cur_scissor.y
              let r_x = self.cur_scissor.right()
              let b_y = self.cur_scissor.bottom()
              let (sstart, scnt) = self.upload_path_verts([l, t, r_x, t, r_x, b_y, l, t, r_x, b_y, l, b_y])
              cmd.set_scissor(0, 0, self.active_w, self.active_h)
              cmd.bind_pipeline(self.stencil_clip_pipe)
              cmd.bind_vertex(0, self.path_vbuf, offset=self.slot_path_base())
              cmd.push_constants_floats(self.stencil_clip_pipe, [fw, fh, (1.0 : Float) / fw, (1.0 : Float) / fh])
              cmd.draw_instanced(scnt, 1, sstart, 0)
            }
            let (cstart, ccnt) = self.upload_path_verts([
              mapped.x, mapped.y, mapped.right(), mapped.y, mapped.right(), mapped.bottom(),
              mapped.x, mapped.y, mapped.right(), mapped.bottom(), mapped.x, mapped.bottom(),
            ])
            cmd.set_scissor(0, 0, self.active_w, self.active_h)
            cmd.bind_pipeline(self.stencil_clear_clip_pipe)
            cmd.bind_vertex(0, self.path_vbuf, offset=self.slot_path_base())
            cmd.push_constants_floats(self.stencil_clear_clip_pipe, [fw, fh, (1.0 : Float) / fw, (1.0 : Float) / fh])
            cmd.draw_instanced(ccnt, 1, cstart, 0)
            self.has_stencil_clip = true
          }
        }
      }
      DrawOp::ClipRRect(rr, op) => {
        let sx = @tmath.abs_f(self.cur_transform.a)
        let sy = @tmath.abs_f(self.cur_transform.d)
        let uniform_scale = @tmath.abs_f(sx - sy) <= (1.0e-4 : Float)
        if !rr.is_circular() || !self.cur_transform.is_axis_aligned() || !uniform_scale {
          // The analytic ClipRRect path in the SDF shader assumes an
          // axis-aligned, uniformly-scaled, circular-cornered clip. Anything
          // else falls back to the stencil clip path for correctness.
          let p = PathBuilder::new().add_rrect(rr).build()
          self.replay_ops(cmd, [DrawOp::ClipPath(p, op)])
          return
        }
        self.flush_prims(cmd)
        let mapped_r = self.cur_transform.map_rect(rr.rect)
        match op {
          ClipOp::Intersect => {
            self.cur_scissor = self.cur_scissor.intersect(mapped_r)
            self.cur_clip_rrect = Some({
              rect: mapped_r,
              tl: rr.tl * sx,
              tl_y: rr.tl_y * sy,
              tr: rr.tr * sx,
              tr_y: rr.tr_y * sy,
              br: rr.br * sx,
              br_y: rr.br_y * sy,
              bl: rr.bl * sx,
              bl_y: rr.bl_y * sy,
            })
          }
          ClipOp::Difference => {
            let pb = PathBuilder::new().add_rrect(rr).build()
            let (verts, _b) = self.tessellate_fill_cached(pb, self.cur_transform)
            let (vstart, vcnt) = self.upload_path_verts(verts)
            if vcnt >= 3 {
              let fw = Float::from_int(self.active_w)
              let fh = Float::from_int(self.active_h)
              if !self.has_stencil_clip {
                let l = self.cur_scissor.x
                let t = self.cur_scissor.y
                let r_x = self.cur_scissor.right()
                let b_y = self.cur_scissor.bottom()
                let (sstart, scnt) = self.upload_path_verts([l, t, r_x, t, r_x, b_y, l, t, r_x, b_y, l, b_y])
                cmd.set_scissor(0, 0, self.active_w, self.active_h)
                cmd.bind_pipeline(self.stencil_clip_pipe)
                cmd.bind_vertex(0, self.path_vbuf, offset=self.slot_path_base())
                cmd.push_constants_floats(self.stencil_clip_pipe, [fw, fh, (1.0 : Float) / fw, (1.0 : Float) / fh])
                cmd.draw_instanced(scnt, 1, sstart, 0)
              }
              cmd.set_scissor(0, 0, self.active_w, self.active_h)
              cmd.bind_pipeline(self.stencil_clear_clip_pipe)
              cmd.bind_vertex(0, self.path_vbuf, offset=self.slot_path_base())
              cmd.push_constants_floats(self.stencil_clear_clip_pipe, [fw, fh, (1.0 : Float) / fw, (1.0 : Float) / fh])
              cmd.draw_instanced(vcnt, 1, vstart, 0)
              self.has_stencil_clip = true
            }
          }
        }
      }
      DrawOp::ClipPath(path, op) => {
        self.flush_prims(cmd)
        let (verts, _bounds) = self.tessellate_fill_cached(path, self.cur_transform)
        let (vstart, vcnt) = self.upload_path_verts(verts)
        if vcnt >= 3 {
          let fw = Float::from_int(self.active_w)
          let fh = Float::from_int(self.active_h)
          match op {
            ClipOp::Intersect => {
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
            ClipOp::Difference => {
              if !self.has_stencil_clip {
                let l = self.cur_scissor.x
                let t = self.cur_scissor.y
                let r_x = self.cur_scissor.right()
                let b_y = self.cur_scissor.bottom()
                let (sstart, scnt) = self.upload_path_verts([l, t, r_x, t, r_x, b_y, l, t, r_x, b_y, l, b_y])
                cmd.set_scissor(0, 0, self.active_w, self.active_h)
                cmd.bind_pipeline(self.stencil_clip_pipe)
                cmd.bind_vertex(0, self.path_vbuf, offset=self.slot_path_base())
                cmd.push_constants_floats(self.stencil_clip_pipe, [fw, fh, (1.0 : Float) / fw, (1.0 : Float) / fh])
                cmd.draw_instanced(scnt, 1, sstart, 0)
              }
              cmd.set_scissor(0, 0, self.active_w, self.active_h)
              cmd.bind_pipeline(self.stencil_clear_clip_pipe)
              cmd.bind_vertex(0, self.path_vbuf, offset=self.slot_path_base())
              cmd.push_constants_floats(
                self.stencil_clear_clip_pipe,
                [fw, fh, (1.0 : Float) / fw, (1.0 : Float) / fh],
              )
              cmd.draw_instanced(vcnt, 1, vstart, 0)
              self.has_stencil_clip = true
            }
          }
        }
      }
      DrawOp::DrawRect(r, paint) =>
        self.replay_ops(cmd, [DrawOp::DrawRRect(RRect::from_rect(r), paint)])
      DrawOp::DrawRRect(rr, paint) => {
        self.set_blend(cmd, paint.blend_mode)
        let sh = self.resolve_paint_shader(paint)
        let (bw, border_col, stroke_only) = match paint.style {
          PaintStyle::Fill => ((0.0 : Float), Color::transparent(), (0.0 : Float))
          PaintStyle::Stroke => (paint.stroke_width, paint.color, (1.0 : Float))
          PaintStyle::StrokeAndFill => (paint.stroke_width, paint.color, (0.0 : Float))
        }
        self.emit_prim(
          cmd,
          rr.rect.x,
          rr.rect.y,
          rr.rect.width,
          rr.rect.height,
          rr.tl,
          rr.tr,
          rr.br,
          rr.bl,
          sh.fill,
          border_col,
          sh.u0,
          sh.v0,
          sh.u1,
          sh.v1,
          bw,
          (0.0 : Float),
          (0.0 : Float),
          stroke_only,
          sh.grad_type,
          sh.tile_mode,
          sh.gp0,
          sh.gp1,
          sh.gp2,
          sh.gp3,
          sh.stop_off,
          sh.stop_cnt,
          extra0=sh.extra0,
          extra1=sh.extra1,
          radii_y=Some((rr.tl_y, rr.tr_y, rr.br_y, rr.bl_y)),
        )
      }
      DrawOp::DrawCircle(center, radius, paint) => {
        self.set_blend(cmd, paint.blend_mode)
        let sh = self.resolve_paint_shader(paint)
        let (bw, border_col, stroke_only) = match paint.style {
          PaintStyle::Fill => ((0.0 : Float), Color::transparent(), (0.0 : Float))
          PaintStyle::Stroke => (paint.stroke_width, paint.color, (1.0 : Float))
          PaintStyle::StrokeAndFill => (paint.stroke_width, paint.color, (0.0 : Float))
        }
        let d = radius * (2.0 : Float)
        self.emit_prim(
          cmd,
          center.x - radius,
          center.y - radius,
          d,
          d,
          radius,
          radius,
          radius,
          radius,
          sh.fill,
          border_col,
          sh.u0,
          sh.v0,
          sh.u1,
          sh.v1,
          bw,
          (0.0 : Float),
          (4.0 : Float),
          stroke_only,
          sh.grad_type,
          sh.tile_mode,
          sh.gp0,
          sh.gp1,
          sh.gp2,
          sh.gp3,
          sh.stop_off,
          sh.stop_cnt,
          extra0=sh.extra0,
          extra1=sh.extra1,
        )
      }
      DrawOp::DrawLine(p0, p1, paint) => {
        self.set_blend(cmd, paint.blend_mode)
        let sh = self.resolve_paint_shader(paint)
        self.emit_prim(
          cmd,
          p0.x,
          p0.y,
          p1.x,
          p1.y,
          p0.x,
          p0.y,
          p1.x,
          p1.y,
          sh.fill,
          Color::transparent(),
          sh.u0,
          sh.v0,
          sh.u1,
          sh.v1,
          @tmath.max_f((0.5 : Float), paint.stroke_width * (0.5 : Float)),
          (0.0 : Float),
          (5.0 : Float),
          (0.0 : Float),
          sh.grad_type,
          sh.tile_mode,
          sh.gp0,
          sh.gp1,
          sh.gp2,
          sh.gp3,
          sh.stop_off,
          sh.stop_cnt,
          extra0=sh.extra0,
          extra1=sh.extra1,
        )
      }
      DrawOp::DrawRRectShadow(rr, dx, dy, blur, spread, col) => {
        self.set_blend(cmd, BlendMode2D::SrcOver)
        let r = rr.rect.offset(dx, dy).inflate(spread)
        let grow = fn(v : Float) {
          if v > (0.0 : Float) { @tmath.max_f((0.0 : Float), v + spread) } else { (0.0 : Float) }
        }
        let tl = grow(rr.tl)
        let tr = grow(rr.tr)
        let br = grow(rr.br)
        let bl = grow(rr.bl)
        let tly = grow(rr.tl_y)
        let tr_y = grow(rr.tr_y)
        let bry = grow(rr.br_y)
        let bly = grow(rr.bl_y)
        self.emit_prim(
          cmd,
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
          @tmath.max_f((1.0 : Float), blur),
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
          radii_y=Some((tly, tr_y, bry, bly)),
        )
      }
      DrawOp::DrawPath(_, _) => ()
      DrawOp::DrawVertices(verts, idx, paint, image) => {
        self.flush_path_batch(cmd)
        self.flush_prims(cmd)
        self.draw_vertices_gpu(cmd, verts, idx, paint, image)
      }
      DrawOp::DrawImage(img, src, dst, paint) => {
        self.set_blend(cmd, paint.blend_mode)
        let (u0, v0, u1, v1, iw, ih, tex_id) = match self.ensure_image_texture(img) {
          Some((tid, tw, th)) =>
            (
              (0.0 : Float),
              (0.0 : Float),
              (1.0 : Float),
              (1.0 : Float),
              Float::from_int(tw),
              Float::from_int(th),
              Float::from_int(tid),
            )
          None => {
            let (a, b, c, d) = self.ensure_image_uv(img)
            (
              a,
              b,
              c,
              d,
              Float::from_int(if img.width > 0 { img.width } else { 1 }),
              Float::from_int(if img.height > 0 { img.height } else { 1 }),
              (-1.0 : Float),
            )
          }
        }
        let su0 = u0 + (u1 - u0) * (src.x / iw)
        let sv0 = v0 + (v1 - v0) * (src.y / ih)
        let su1 = u0 + (u1 - u0) * (src.right() / iw)
        let sv1 = v0 + (v1 - v0) * (src.bottom() / ih)
        self.emit_prim(
          cmd,
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
          extra0=tex_id,
        )
      }
      DrawOp::DrawParagraph(para, pos) => {
        self.set_blend(cmd, BlendMode2D::SrcOver)
        para.layout((1.0e9 : Float))
        for g in para.placed_glyphs() {
          match g.image {
            Some(_) => continue
            None => ()
          }
          match self.color_glyph_for(g.font, g.codepoint, g.font_size) {
            Some(cg) => {
              let scale = g.font_size / Float::from_int(cg.ppem)
              let gx = pos.x + g.x + Float::from_int(cg.bearing_x) * scale
              let gy = pos.y + g.baseline_y - Float::from_int(cg.bearing_y) * scale
              self.emit_prim(
                cmd,
                gx,
                gy,
                Float::from_int(cg.width) * scale,
                Float::from_int(cg.height) * scale,
                (0.0 : Float),
                (0.0 : Float),
                (0.0 : Float),
                (0.0 : Float),
                Color::rgba((1.0 : Float), (1.0 : Float), (1.0 : Float), g.color.a),
                Color::transparent(),
                cg.uv0,
                cg.uv1,
                cg.uv2,
                cg.uv3,
                (0.0 : Float),
                (-1.5 : Float),
                (7.0 : Float),
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
            None => {
              let ge = self.glyph_cache.get_or_rasterize_styled(
                g.font,
                g.glyph_id,
                g.codepoint,
                g.font_size,
                g.bold,
                g.italic,
              )
              if ge.width > 0 && ge.height > 0 {
                let glyph_kind = if ge.is_msdf {
                  (9.0 : Float)
                } else if ge.is_sdf {
                  (8.0 : Float)
                } else {
                  (3.0 : Float)
                }
                let gx = pos.x + g.x + Float::from_int(ge.offset_x)
                let gy = pos.y + g.baseline_y + Float::from_int(ge.offset_y)
                self.emit_prim(
                  cmd,
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
                  glyph_kind,
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
          }
        }
        for g in para.placed_glyphs() {
          match g.image {
            Some(img) =>
              if g.image_w > (0.0 : Float) && g.image_h > (0.0 : Float) {
                let (u0, v0, u1, v1) = self.ensure_image_uv(img)
                let iy = pos.y + g.baseline_y - g.image_h
                self.emit_prim(
                  cmd,
                  pos.x + g.x,
                  iy,
                  g.image_w,
                  g.image_h,
                  (0.0 : Float),
                  (0.0 : Float),
                  (0.0 : Float),
                  (0.0 : Float),
                  Color::white(),
                  Color::transparent(),
                  u0,
                  v0,
                  u1,
                  v1,
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
            None => ()
          }
        }
        for ul in para.underline_rects() {
          let (ux, uy, uw, uh, ucol) = ul
          self.emit_prim(
            cmd,
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
      DrawOp::DrawTextOnPath(para, path, paint, offset) => {
        self.set_blend(cmd, BlendMode2D::SrcOver)
        para.layout((1.0e9 : Float))
        let pm = path.measure()
        for g in para.placed_glyphs() {
          match g.image {
            Some(_) => continue
            None => ()
          }
          let (ox, oy, w, h, pixels) = g.font.rasterize_bitmap(
            g.glyph_id,
            g.codepoint,
            g.font_size,
            g.bold,
            g.italic,
          )
          if w <= 0 || h <= 0 {
            continue
          }
          let (p, dir) = match pm.pos_at(offset + g.x) {
            Some(v) => v
            None => continue
          }
          let angle = @tmath.atan2(dir.y, dir.x)
          let (rw, rh, rpx) = rotate_coverage(w, h, pixels, angle)
          let uv = match self.glyph_cache.alloc_coverage(rw, rh, rpx) {
            Some(v) => v
            None => continue
          }
          let (u0, v0, u1, v1) = uv
          let c = @tmath.cos(angle)
          let s = @tmath.sin(angle)
          let lx = Float::from_int(ox) + Float::from_int(w) * (0.5 : Float)
          let ly = Float::from_int(oy) + Float::from_int(h) * (0.5 : Float)
          let rx = lx * c - ly * s
          let ry = lx * s + ly * c
          let qx = p.x + rx - Float::from_int(rw) * (0.5 : Float)
          let qy = p.y + ry - Float::from_int(rh) * (0.5 : Float)
          self.emit_prim(
            cmd,
            qx,
            qy,
            Float::from_int(rw),
            Float::from_int(rh),
            (0.0 : Float),
            (0.0 : Float),
            (0.0 : Float),
            (0.0 : Float),
            paint.color,
            Color::transparent(),
            u0,
            v0,
            u1,
            v1,
            (0.0 : Float),
            (0.0 : Float),
            (6.0 : Float),
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
fn Renderer2D::reset_frame_state(
  self : Renderer2D,
  width : Int,
  height : Int,
  slot : Int,
  rt_slot : Int,
) -> Unit {
  self.active_slot = slot
  self.active_rt_slot = rt_slot
  self.glyph_cache.begin_frame(self.frame_idx)
  self.rt_pool.release_slot(rt_slot)
  // Reclaim overflow prim buffers that have been idle for several frames (the
  // extra slack covers the 2-frames-in-flight submissions).
  while self.overflow_prim_ssbos.length() > 0 {
    let last = self.overflow_prim_ssbos.length() - 1
    let used = if last < self.overflow_last_used.length() {
      self.overflow_last_used[last]
    } else {
      0
    }
    if used < self.frame_idx - 3 {
      match self.overflow_prim_ssbos.pop() {
        Some(b) => b.destroy()
        None => ()
      }
      let _ = self.overflow_last_used.pop()
    } else {
      break
    }
  }
  self.prim_cursor = 0
  self.prim_batch_start = 0
  self.prim_draw_count = 0
  self.prim_total = 0
  self.upload_bytes = 0
  self.coverage_draws = 0
  self.vert_cursor = 0
  self.vert_index_cursor = 0
  let cgen = self.color_atlas.generation()
  if cgen != self.color_atlas_gen {
    self.color_glyphs.clear()
    self.color_glyph_count = 0
    self.uploaded_images.clear()
    self.color_atlas_gen = cgen
  }
  self.active_prim_ssbo = self.prim_ssbo
  self.active_prim_slot_base = self.slot_prim_base()
  self.active_prim_chunk = 0
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
  self.cur_blend = BlendMode2D::SrcOver
  self.cur_color_format = @tycho.TextureFormat::RGBA8
  self.path_batch.clear()
  self.path_batch_bounds = None
  self.path_batch_count = 0
  self.state_stack.clear()
}

///|
fn Renderer2D::render_into_scene(
  self : Renderer2D,
  cmd : @tycho.CommandBuffer,
  dl : DisplayList,
  width : Int,
  height : Int,
  clear_color : Color,
  slot? : Int = 0,
  rt_slot? : Int = 0,
) -> @tycho.Texture raise @tycho.RhiError {
  self.reset_frame_state(width, height, slot, rt_slot)
  let (scene_tex, scene_ds_opt) = self.rt_pool.acquire(
    width,
    height,
    with_depth_stencil=true,
    slot=rt_slot,
  )
  let scene_ds = scene_ds_opt.unwrap()
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
  self.flush_path_batch(cmd)
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
  damage? : Rect? = None,
) -> Unit raise @tycho.RhiError {
  self.frame_idx = self.frame_idx + 1
  self.dev.wait_idle()
  let w = target.width()
  let h = target.height()
  let cmd = self.dev.begin_commands()
  // Render straight into the caller's target: the previous implementation
  // rendered into a pooled scene texture and then blitted it, costing one full
  // extra color target plus a full-screen sample+write per offscreen render.
  self.reset_frame_state(w, h, 0, 2)
  self.cur_color_format = target.format()
  let damage_clip = match damage {
    Some(d) => {
      let clipped = d.intersect(
        Rect::new(
          (0.0 : Float),
          (0.0 : Float),
          Float::from_int(w),
          Float::from_int(h),
        ),
      )
      if clipped.is_empty() {
        self.rt_pool.release_slot(2)
        return
      }
      Some(clipped)
    }
    None => None
  }
  let ds = self.rt_pool.acquire_depth(w, h, slot=2)
  let color_load = match damage_clip {
    Some(_) => @tycho.LoadOp::Load
    None => @tycho.LoadOp::Clear
  }
  self.begin_target_pass(
    cmd,
    target,
    ds,
    w,
    h,
    color_load,
    clear_color,
    @tycho.LoadOp::Clear,
  )
  match damage_clip {
    Some(d) => {
      // Partial repaint: clip everything to the damage rect and clear only that
      // region so the rest of the target keeps the previous frame.
      self.cur_scissor = d
      self.set_blend(cmd, BlendMode2D::Src)
      self.emit_prim(
        cmd,
        d.x,
        d.y,
        d.width,
        d.height,
        (0.0 : Float),
        (0.0 : Float),
        (0.0 : Float),
        (0.0 : Float),
        clear_color,
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
      self.flush_prims(cmd)
      self.set_blend(cmd, BlendMode2D::SrcOver)
    }
    None => ()
  }
  self.replay_ops(cmd, dl.ops)
  self.flush_path_batch(cmd)
  self.flush_prims(cmd)
  cmd.end_render_pass()
  self.flush_atlas_uploads()
  self.dev.end_commands(cmd)
  self.rt_pool.release_slot(2)
}

///|
pub fn Renderer2D::render_swapchain(
  self : Renderer2D,
  sc : @tycho.Swapchain,
  dl : DisplayList,
  clear_color? : Color = Color::black(),
  dl_size? : (Int, Int)? = None,
) -> Unit raise @tycho.RhiError {
  self.frame_idx = self.frame_idx + 1
  let w = sc.width()
  let h = sc.height()
  let (scene_w, scene_h) = match dl_size {
    Some((dw, dh)) => if dw > 0 && dh > 0 { (dw, dh) } else { (w, h) }
    None => (w, h)
  }
  let ds_opt = if sc.has_depth() { Some(sc.depth_format()) } else { None }
  // Direct-to-swapchain: prim-only scenes that match the swapchain size and
  // carry a Depth24Stencil8 attachment (matching the prim pipelines) can skip
  // the offscreen scene texture and the full-screen presentation blit.
  if sc.has_depth() &&
    sc.depth_format() == @tycho.TextureFormat::Depth24Stencil8 &&
    !dl.needs_offscreen() &&
    scene_w == w &&
    scene_h == h {
    let cmd = sc.begin_frame_commands()
    let sc_slot = cmd.frame_slot() & 1
    self.reset_frame_state(w, h, sc_slot, sc_slot)
    self.active_tex = None
    self.active_ds = None
    self.active_w = w
    self.active_h = h
    self.cur_color_format = sc.color_format()
    cmd.begin_swapchain_pass(
      sc,
      load_op=@tycho.LoadOp::Clear,
      clear_color=Some(clear_color.to_clear_color()),
    )
    self.replay_ops(cmd, dl.ops)
    self.flush_path_batch(cmd)
    self.flush_prims(cmd)
    cmd.end_swapchain_pass()
    self.flush_atlas_uploads()
    sc.end_frame(cmd)
    return
  }
  let fmt = sc.color_format()
  let sc_pipe = match self.present_sc_pipe {
    Some(p) =>
      if self.present_sc_fmt == Some(fmt) && self.present_sc_depth_fmt == ds_opt {
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
            depth_format=ds_opt,
          ),
        )
        self.present_sc_pipe = Some(np)
        self.present_sc_fmt = Some(fmt)
        self.present_sc_depth_fmt = ds_opt
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
          depth_format=ds_opt,
        ),
      )
      self.present_sc_pipe = Some(np)
      self.present_sc_fmt = Some(fmt)
      self.present_sc_depth_fmt = ds_opt
      np
    }
  }
  let cmd = sc.begin_frame_commands()
  let sc_slot = cmd.frame_slot() & 1
  let scene_tex = self.render_into_scene(
    cmd,
    dl,
    scene_w,
    scene_h,
    clear_color,
    slot=sc_slot,
    rt_slot=sc_slot,
  )
  let u1 = Float::from_int(scene_w) / Float::from_int(scene_tex.width())
  let v1 = Float::from_int(scene_h) / Float::from_int(scene_tex.height())
  let dst_w_frac = Float::from_int(scene_w) / Float::from_int(w)
  let dst_h_frac = Float::from_int(scene_h) / Float::from_int(h)
  cmd.begin_swapchain_pass(
    sc,
    load_op=@tycho.LoadOp::Clear,
    clear_color=Some(clear_color.to_clear_color()),
  )
  cmd.set_viewport((0.0 : Float), (0.0 : Float), Float::from_int(w), Float::from_int(h))
  cmd.set_scissor(0, 0, w, h)
  cmd.bind_pipeline(sc_pipe)
  cmd.bind_texture(sc_pipe, 0, scene_tex, self.sampler)
  cmd.bind_storage(sc_pipe, 0, self.color_mat_ssbo, offset=self.slot_cmat_base(), size=80)
  cmd.push_constants_floats(sc_pipe, [
    (0.0 : Float),
    (0.0 : Float),
    dst_w_frac,
    dst_h_frac,
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
  self.flush_atlas_uploads()
  sc.end_frame(cmd)
}
