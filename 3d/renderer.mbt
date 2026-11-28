// Forward PBR renderer for M0: one directional shadow map, HDR scene target,
// separable bloom, and ACES tonemap. All pipelines are AOT SPIR-V; per-object
// data travels through SSBOs plus a 4-byte push constant.

///|
pub(all) struct RendererDesc {
  max_objects : Int
  max_lights : Int
  max_materials : Int
  max_textures : Int
  msaa : Bool
  shadow_cascades : Int
  gpu_culling : Bool
  // Bindless material sampling; automatically disabled when the device lacks
  // descriptor indexing, and forceable off to test the fallback.
  bindless : Bool
  bloom : Bool
  shadows : Bool
  shadow_map_size : Int
  // Screen-space ambient occlusion. Requires a single-sample depth buffer, so
  // enabling it forces MSAA off.
  ssao : Bool
}

///|
pub fn RendererDesc::default() -> RendererDesc {
  {
    max_objects: 4096,
    max_lights: 16,
    max_materials: 1024,
    max_textures: 1024,
    msaa: true,
    bloom: true,
    shadows: true,
    shadow_map_size: 1024,
    shadow_cascades: 2,
    gpu_culling: false,
    bindless: true,
    ssao: false,
  }
}

///|
pub fn RendererDesc::with_bindless(self : RendererDesc, on : Bool) -> RendererDesc {
  { ..self, bindless: on }
}

///|
pub fn RendererDesc::with_shadows(self : RendererDesc, on : Bool) -> RendererDesc {
  { ..self, shadows: on }
}

///|
/// Enable screen-space ambient occlusion. SSAO reconstructs positions from the
/// depth buffer, which a multisampled depth attachment cannot provide, so
/// turning it on also turns MSAA off (they are mutually exclusive).
pub fn RendererDesc::with_ssao(self : RendererDesc, on : Bool) -> RendererDesc {
  { ..self, ssao: on, msaa: if on { false } else { self.msaa } }
}

///|
pub fn RendererDesc::with_msaa(self : RendererDesc, on : Bool) -> RendererDesc {
  { ..self, msaa: on && !self.ssao }
}

const OBJECT_FLOATS : Int = 40

const OBJECT_BYTES : Int = 160

const LIGHT_FLOATS : Int = 40

const LIGHT_BYTES : Int = 160

const MATERIAL_FLOATS : Int = 24

const MATERIAL_BYTES : Int = 96

const SHADOW_TILES_MAX : Int = 8

const SHADOW_TILE_BYTES : Int = 80

const MAX_BONES : Int = 4096

const BONE_BYTES : Int = 64

const FRAME_FLOATS : Int = 68

const BRDF_LUT_SIZE : Int = 64

const FRAME_BYTES : Int = 272

const FRAME_SLOT_BYTES : Int = 512

const SKY_FLOATS : Int = 20

const SKY_BYTES : Int = 80

const SKY_SLOT_BYTES : Int = 128

// SSAO UBO: viewProj + invViewProj (2 mat4), camPos + params (2 vec4).
const SSAO_FLOATS : Int = 40

const SSAO_BYTES : Int = 160

///|
priv struct FrameTargets {
  w : Int
  h : Int
  depth : @tycho.Texture
  hdr : @tycho.Texture
  // Set when MSAA is on; `hdr` is the multisampled colour attachment.
  hdr_resolve : @tycho.Texture?
  // Copy of the opaque colour sampled by the transmission pass.
  scene_copy : @tycho.Texture
  // SSAO raw + blurred results; present only when SSAO is enabled.
  ao_a : @tycho.Texture?
  ao_b : @tycho.Texture?
  bloom_a : @tycho.Texture
  bloom_b : @tycho.Texture
}

///|
priv struct DrawItem {
  node : NodeId
  mesh : Int
  material : Int
  distance : Float
  cast_shadow : Bool
  transparent : Bool
}

///|
/// A contiguous run of object records drawn with one instanced call.
priv struct DrawBatch {
  mesh : Int
  material : Int
  first : Int
  mut count : Int
  // Set when the batch goes through GPU culling.
  mut cull_cmd : Int
  mut list_offset : Int
  skinned : Bool
  morph_w0 : Float
  morph_w1 : Float
}

///|
/// Per-mesh acceleration structure with the buffers its BLAS references.
priv struct RtMesh {
  blas : @tycho.AccelStruct
  vbuf : @tycho.Buffer
  ibuf : @tycho.Buffer
}

///|
/// Distance-based mesh selection for one node. `levels[0]` is the highest
/// detail; `switch_distances[i]` is the distance where level i+1 takes over.
priv struct LodGroup {
  node : NodeId
  levels : Array[MeshHandle]
  switch_distances : Array[Float]
}

///|
/// A skeleton bound to one scene node: joint nodes plus inverse bind matrices.
/// `offset` is the palette slot in the bone SSBO, stable for the renderer's life.
priv struct SkinBinding {
  node : NodeId
  joints : Array[NodeId]
  inverse_bind : Array[@tmath.Mat4]
  offset : Int
  count : Int
}

///|
/// A renderer-owned texture together with its bindless heap slot.
priv struct GpuTexture {
  tex : @tycho.Texture
  index : Int
}

///|
/// A resident line list uploaded from `@tgeo.LineData`: interleaved
/// position/colour vertices drawn through the shared `LineList` pipeline.
/// The CPU copy is kept for line picking (segments have no BVH).
priv struct GpuLines {
  buffer : @tycho.Buffer
  cpu : @tgeo.LineData
  vertex_count : Int
  segment_count : Int
  bounds : @tmath.Aabb3
}

///|
pub struct Renderer3D {
  priv dev : @tycho.Device
  priv desc : RendererDesc
  priv msaa : Bool
  priv meshes : Array[GpuMesh]
  // Shared vertex/index arenas for the static batch cache.
  priv mut vertex_arena : @tycho.Buffer
  priv mut index_arena : @tycho.Buffer
  priv arena_floats : Array[Float]
  priv arena_indices : Array[UInt]
  priv draw_count : @tycho.Buffer
  // Skinned meshes use a 80-byte vertex stream and a separate pipeline.
  priv mut skin_arena : @tycho.Buffer
  priv skin_floats : Array[Float]
  priv skin_pipe : @tycho.Pipeline
  priv skin_blend_pipe : @tycho.Pipeline
  priv shadow_skin_pipe : @tycho.Pipeline
  priv bone_ssbo : @tycho.Buffer
  priv shadow_tiles_ssbo : @tycho.Buffer
  priv bone_scratch : FixedArray[Float]
  priv mut bone_cursor : Int
  priv skins : Array[SkinBinding]
  priv lods : Array[LodGroup]
  // Morph meshes use a 72-byte stream; weights travel per draw.
  priv mut morph_arena : @tycho.Buffer
  priv morph_floats : Array[Float]
  priv morph_pipe : @tycho.Pipeline
  priv morph_shadow_pipe : @tycho.Pipeline
  priv morph_weights : Array[(NodeId, Array[Float])]
  priv rt_supported : Bool
  priv mut rt_enabled : Bool
  priv rt_pipe : @tycho.Pipeline?
  priv rt_cull_pipe : @tycho.Pipeline?
  priv mut rt_tlas : @tycho.AccelStruct?
  priv rt_meshes : Array[RtMesh?]
  // Lazily built per-mesh picking BVHs, parallel to `meshes`. `None` until a
  // pointer ray first reaches that mesh.
  priv pick_bvhs : Array[MeshBvh?]
  priv materials : Array[MaterialDesc]
  priv object_ring : @pool.FrameRing
  priv light_ring : @pool.FrameRing
  priv frame_ubo : @tycho.Buffer
  priv sky_ubo : @tycho.Buffer
  priv material_ssbo : @tycho.Buffer
  priv shadow_atlas : @tycho.Texture
  priv shadow_sampler : @tycho.Sampler
  priv env_sampler : @tycho.Sampler
  priv linear_sampler : @tycho.Sampler
  priv material_sampler : @tycho.Sampler
  priv brdf_lut : @tycho.Texture
  priv bindless : @tycho.BindlessHeap?
  priv bindless_ok : Bool
  priv white_tex : @tycho.Texture
  priv flat_normal_tex : @tycho.Texture
  priv white_index : Int
  priv flat_normal_index : Int
  priv textures : Array[GpuTexture]
  priv mut env_cube : @tycho.Texture
  priv mut env_sun : @tmath.Vec3
  priv mut env_intensity : Float
  priv mut owns_env : Bool
  // When set, the sky pass is skipped and the HDR target clears to this linear
  // color instead (three.js `scene.background`). `None` renders the environment.
  priv mut background : @tmath.Vec4?
  // Linear / exp2 distance fog applied by the PBR fragment shader.
  priv mut fog : Fog?
  priv shadow_pipe : @tycho.Pipeline
  priv pbr_pipe : @tycho.Pipeline
  priv pbr_blend_pipe : @tycho.Pipeline
  priv pbr_transmission_pipe : @tycho.Pipeline
  priv sky_pipe : @tycho.Pipeline
  priv bloom_extract_pipe : @tycho.Pipeline
  priv bloom_blur_pipe : @tycho.Pipeline
  priv tonemap_srgb_pipe : @tycho.Pipeline
  priv tonemap_linear_pipe : @tycho.Pipeline
  // Screen-space ambient occlusion (disabled unless `RendererDesc.ssao`).
  priv ssao : Bool
  priv mut ssao_radius : Float
  priv mut ssao_intensity : Float
  priv mut ssao_bias : Float
  priv ssao_ubo : @tycho.Buffer
  priv ssao_pipe : @tycho.Pipeline
  priv ssao_blur_pipe : @tycho.Pipeline
  priv ssao_writer : @tmath.GpuPackWriter
  priv depth_sampler : @tycho.Sampler
  priv gpu_culling : Bool
  priv cull_pipe : @tycho.Pipeline?
  priv pbr_cull_pipe : @tycho.Pipeline?
  priv cull_vis : Array[@tycho.Buffer]
  priv cull_cmds : Array[@tycho.Buffer]
  priv line_pipe : @tycho.Pipeline
  priv mut line_vbuf : @tycho.Buffer
  priv mut line_capacity : Int
  priv line_floats : Array[Float]
  priv line_sets : Array[GpuLines]
  priv object_writer : @tmath.GpuPackWriter
  priv light_writer : @tmath.GpuPackWriter
  priv material_writer : @tmath.GpuPackWriter
  priv frame_writer : @tmath.GpuPackWriter
  priv sky_writer : @tmath.GpuPackWriter
  priv mut targets : FrameTargets?
  priv mut present : @tycho.Texture?
  priv mut present_w : Int
  priv mut present_h : Int
  priv mut stats : RenderStats3D
}

///|
fn is_blend_mode(mode : AlphaMode) -> Bool {
  match mode {
    Blend => true
    _ => false
  }
}

///|
/// Descriptor ranges must be non-zero even when a scene has no objects or
/// lights; the shaders never index past `objectCount` / `lightCount`, so a
/// one-element range is safe and keeps validation clean.
fn bind_objects_bytes(count : Int) -> Int {
  if count > 0 {
    count * OBJECT_BYTES
  } else {
    OBJECT_BYTES
  }
}

///|
fn bind_lights_bytes(count : Int) -> Int {
  if count > 0 {
    count * LIGHT_BYTES
  } else {
    LIGHT_BYTES
  }
}

///|
fn byte_of(v : Int) -> Byte {
  (v.reinterpret_as_uint() & (0xFF : UInt)).to_byte()
}

///|
fn solid_texture(
  dev : @tycho.Device,
  r : Int,
  g : Int,
  b : Int,
  a : Int,
  srgb : Bool,
) -> @tycho.Texture raise {
  let bytes = Bytes::from_array([byte_of(r), byte_of(g), byte_of(b), byte_of(a)])
  dev.create_texture_format(
    1,
    1,
    if srgb { @tycho.TextureFormat::RGBA8Srgb } else { @tycho.TextureFormat::RGBA8 },
    bytes,
  )
}

///|
fn pc2_bytes(first : Int, material : Int) -> Bytes {
  let a = first.reinterpret_as_uint()
  let b = material.reinterpret_as_uint()
  let arr : Array[Byte] = []
  arr.push((a & (0xFF : UInt)).to_byte())
  arr.push(((a >> 8) & (0xFF : UInt)).to_byte())
  arr.push(((a >> 16) & (0xFF : UInt)).to_byte())
  arr.push(((a >> 24) & (0xFF : UInt)).to_byte())
  arr.push((b & (0xFF : UInt)).to_byte())
  arr.push(((b >> 8) & (0xFF : UInt)).to_byte())
  arr.push(((b >> 16) & (0xFF : UInt)).to_byte())
  arr.push(((b >> 24) & (0xFF : UInt)).to_byte())
  Bytes::from_array(arr)
}

///|
fn Renderer3D::texture_index(self : Renderer3D, h : TextureHandle?) -> Int {
  match h {
    Some(x) => {
      let i = x.id()
      if i >= 0 && i < self.textures.length() {
        self.textures[i].index
      } else {
        self.white_index
      }
    }
    None => self.white_index
  }
}

///|
fn cull_pc_floats(
  frustum : @tmath.Frustum,
  first : Int,
  count : Int,
  list_offset : Int,
  cmd_index : Int,
) -> FixedArray[Float] {
  let out = FixedArray::make(28, (0.0 : Float))
  for i = 0; i < 6; i = i + 1 {
    let p = frustum.planes[i]
    out[i * 4] = p.normal.x
    out[i * 4 + 1] = p.normal.y
    out[i * 4 + 2] = p.normal.z
    out[i * 4 + 3] = p.d
  }
  out[24] = f_of_int(first)
  out[25] = f_of_int(count)
  out[26] = f_of_int(list_offset)
  out[27] = f_of_int(cmd_index)
  out
}

///|
fn Renderer3D::bind_material_heap(
  self : Renderer3D,
  cmd : @tycho.CommandBuffer,
  pipe : @tycho.Pipeline,
) -> Unit {
  match self.bindless {
    Some(h) => cmd.bind_bindless_heap(pipe, h)
    None => ()
  }
}

///|
fn Renderer3D::texture_of(self : Renderer3D, h : TextureHandle) -> @tycho.Texture {
  let i = h.id()
  if i >= 0 && i < self.textures.length() {
    self.textures[i].tex
  } else {
    self.white_tex
  }
}

///|
/// Non-bindless material sampling: bind albedo (slot 4) and normal (slot 5) per
/// batch, falling back to the 1x1 white / flat-normal textures.
fn Renderer3D::bind_material_textures(
  self : Renderer3D,
  cmd : @tycho.CommandBuffer,
  pipe : @tycho.Pipeline,
  material : Int,
) -> Unit {
  if self.bindless_ok {
    return
  }
  if material < 0 || material >= self.materials.length() {
    return
  }
  let m = self.materials[material]
  let albedo = match m.albedo_tex {
    Some(h) => self.texture_of(h)
    None => self.white_tex
  }
  let normal = match m.normal_tex {
    Some(h) => self.texture_of(h)
    None => self.flat_normal_tex
  }
  cmd.bind_texture(pipe, 4, albedo, self.material_sampler)
  cmd.bind_texture(pipe, 5, normal, self.material_sampler)
}

///|
fn Renderer3D::pack_material(self : Renderer3D, m : MaterialDesc) -> Unit {
  let w = self.material_writer
  w.push_vec4(m.base_color)
  w.push_vec3_padded(m.emissive)
  let unlit : Bool = match m.shading {
    Unlit => true
    Pbr => false
  }
  let mut flags : Int = 0
  if unlit {
    flags = flags | 1
  }
  if m.albedo_tex is Some(_) {
    flags = flags | 2
  }
  if m.normal_tex is Some(_) {
    flags = flags | 4
  }
  let sheen_on = m.sheen_color.x > 0.0 ||
    m.sheen_color.y > 0.0 ||
    m.sheen_color.z > 0.0
  if sheen_on {
    flags = flags | 8
  }
  let cutoff : Float = match m.alpha_mode {
    Mask(c) => c
    _ => 0.0
  }
  w.push_float(m.metallic)
  w.push_float(m.roughness)
  w.push_float(cutoff)
  w.push_float(f_of_int(flags))
  let albedo = if m.albedo_tex is Some(_) {
    self.texture_index(m.albedo_tex)
  } else {
    self.white_index
  }
  let normal = if m.normal_tex is Some(_) {
    self.texture_index(m.normal_tex)
  } else {
    self.flat_normal_index
  }
  w.push_float(f_of_int(albedo))
  w.push_float(f_of_int(normal))
  w.push_float(m.clearcoat)
  w.push_float(m.clearcoat_roughness)
  // Sheen: rgb colour, w roughness (glTF KHR_materials_sheen).
  w.push_vec4(
    @tmath.Vec4::new(
      m.sheen_color.x,
      m.sheen_color.y,
      m.sheen_color.z,
      m.sheen_roughness,
    ),
  )
  // Transmission: x amount, y ior (three.js transmission / ior).
  w.push_vec4(@tmath.Vec4::new(m.transmission, m.ior, 0.0, 0.0))
}

///|
/// Bake the split-sum GGX/visibility integral into a 64x64 RG16F texture:
/// (A, B) per (NdotV, roughness) texel.
fn create_brdf_lut(dev : @tycho.Device) -> @tycho.Texture raise {
  let size = BRDF_LUT_SIZE
  let pipe = dev.create_graphics_pipeline(
    @tycho.PipelineDesc::from_spirv(
      spv_fullscreen_vert,
      spv_brdf_lut_frag,
      color_format=@tycho.TextureFormat::RG16F,
    ),
  )
  let rt = dev.create_render_target(size, size, @tycho.TextureFormat::RG16F)
  let cmd = dev.begin_commands()
  cmd.render_pass(
    [
      @tycho.RenderTargetDesc::new(
        rt,
        load_op=@tycho.LoadOp::Clear,
        store_op=@tycho.StoreOp::Store,
        clear_color=@tycho.ClearColor::black(),
      ),
    ],
  fn(pass) {
    pass.set_viewport(0.0, 0.0, f_of_int(size), f_of_int(size))
    pass.set_scissor(0, 0, size, size)
    pass.bind_pipeline(pipe)
    pass.push_constants_floats(pipe, [(128.0 : Float), 0.0, 0.0, 0.0])
    pass.draw(3, 1)
  
  },
)
  dev.end_commands(cmd)
  let px = rt.readback()
  let tex = dev.create_texture_format(
    size,
    size,
    @tycho.TextureFormat::RG16F,
    Bytes::from_fixedarray(px),
  )
  pipe.destroy()
  rt.destroy()
  tex
}

///|
pub fn Renderer3D::new(
  dev : @tycho.Device,
  desc? : RendererDesc = RendererDesc::default(),
) -> Renderer3D raise {
  let msaa = desc.msaa && !desc.ssao
  let samples = if msaa {
    @tycho.SampleCount::X4
  } else {
    @tycho.SampleCount::X1
  }
  let material_sampler = dev.create_sampler_desc(
    @tycho.SamplerDesc::new(
      mag=@tycho.Filter::Linear,
      min=@tycho.Filter::Linear,
      mipmap=@tycho.Filter::Linear,
      address=@tycho.AddressMode::Repeat,
    ),
  )
  let bindless_ok = desc.bindless && dev.capabilities().supports_bindless
  let bindless : @tycho.BindlessHeap? = if bindless_ok {
    Some(dev.create_bindless_heap(max_textures=desc.max_textures))
  } else {
    None
  }
  let white_tex = solid_texture(dev, 255, 255, 255, 255, true)
  let flat_normal_tex = solid_texture(dev, 128, 128, 255, 255, false)
  let mut white_index = 0
  let mut flat_normal_index = 0
  match bindless {
    Some(h) => {
      white_index = h.register_texture(white_tex, material_sampler)
      flat_normal_index = h.register_texture(flat_normal_tex, material_sampler)
    }
    None => ()
  }
  let mesh_layouts : Array[@tycho.VertexBufferLayout] = [
    @tycho.VertexBufferLayout::new(
      48,
      [
        @tycho.VertexAttribute::new(0, @tycho.VertexFormat::Float3, 0),
        @tycho.VertexAttribute::new(1, @tycho.VertexFormat::Float3, 12),
        @tycho.VertexAttribute::new(2, @tycho.VertexFormat::Float2, 24),
        @tycho.VertexAttribute::new(3, @tycho.VertexFormat::Float4, 32),
      ],
    ),
  ]
  let shadow_pipe = dev.create_graphics_pipeline(
    @tycho.PipelineDesc::from_spirv(
      spv_shadow_vert,
      [],
      depth_test=true,
      depth_write=true,
      depth_compare=@tycho.CompareOp::LessEqual,
      depth_format=@tycho.TextureFormat::Depth24Stencil8,
      depth_only=true,
      depth_bias=true,
      depth_bias_constant=(1.5 : Float),
      depth_bias_slope=(1.75 : Float),
      vertex_layouts=mesh_layouts,
    ),
  )
  let rt_supported = dev.capabilities().supports_ray_query && bindless_ok
  let pbr_frag = if bindless_ok {
    spv_pbr_frag
  } else {
    spv_pbr_frag_nobindless
  }
  let pbr_pipe = dev.create_graphics_pipeline(
    @tycho.PipelineDesc::from_spirv(
      spv_pbr_vert,
      pbr_frag,
      depth_test=true,
      depth_write=true,
      depth_compare=@tycho.CompareOp::GreaterEqual,
      depth_format=@tycho.TextureFormat::Depth32F,
      cull_mode=@tycho.CullMode::Back,
      front_face=@tycho.FrontFace::CounterClockwise,
      color_format=@tycho.TextureFormat::RGBA16F,
      vertex_layouts=mesh_layouts,
      bindless_heap?=bindless,
      samples=samples,
    ),
  )
  // Transmission samples an opaque color copy, so it is a separate pipeline
  // variant (static meshes only) drawn in a second pass. No blending: the
  // shader already composites the refracted background.
  let transmission_frag = if bindless_ok {
    spv_pbr_frag_transmission
  } else {
    spv_pbr_frag_transmission_nobindless
  }
  let pbr_transmission_pipe = dev.create_graphics_pipeline(
    @tycho.PipelineDesc::from_spirv(
      spv_pbr_vert,
      transmission_frag,
      depth_test=true,
      depth_write=false,
      depth_compare=@tycho.CompareOp::GreaterEqual,
      depth_format=@tycho.TextureFormat::Depth32F,
      cull_mode=@tycho.CullMode::Back,
      front_face=@tycho.FrontFace::CounterClockwise,
      color_format=@tycho.TextureFormat::RGBA16F,
      vertex_layouts=mesh_layouts,
      bindless_heap?=bindless,
      samples=samples,
    ),
  )
  let pbr_blend_pipe = dev.create_graphics_pipeline(
    @tycho.PipelineDesc::from_spirv(
      spv_pbr_vert,
      pbr_frag,
      depth_test=true,
      depth_write=false,
      depth_compare=@tycho.CompareOp::GreaterEqual,
      depth_format=@tycho.TextureFormat::Depth32F,
      cull_mode=@tycho.CullMode::Back,
      front_face=@tycho.FrontFace::CounterClockwise,
      blend=true,
      blend_mode=@tycho.BlendMode::Alpha,
      color_format=@tycho.TextureFormat::RGBA16F,
      vertex_layouts=mesh_layouts,
      bindless_heap?=bindless,
      samples=samples,
    ),
  )
  let skin_layouts : Array[@tycho.VertexBufferLayout] = [
    @tycho.VertexBufferLayout::new(
      SKIN_VERTEX_BYTES,
      [
        @tycho.VertexAttribute::new(0, @tycho.VertexFormat::Float3, 0),
        @tycho.VertexAttribute::new(1, @tycho.VertexFormat::Float3, 12),
        @tycho.VertexAttribute::new(2, @tycho.VertexFormat::Float2, 24),
        @tycho.VertexAttribute::new(3, @tycho.VertexFormat::Float4, 32),
        @tycho.VertexAttribute::new(4, @tycho.VertexFormat::Float4, 48),
        @tycho.VertexAttribute::new(5, @tycho.VertexFormat::Float4, 64),
      ],
    ),
  ]
  let skin_pipe = dev.create_graphics_pipeline(
    @tycho.PipelineDesc::from_spirv(
      spv_pbr_skin_vert,
      pbr_frag,
      depth_test=true,
      depth_write=true,
      depth_compare=@tycho.CompareOp::GreaterEqual,
      depth_format=@tycho.TextureFormat::Depth32F,
      cull_mode=@tycho.CullMode::Back,
      front_face=@tycho.FrontFace::CounterClockwise,
      color_format=@tycho.TextureFormat::RGBA16F,
      vertex_layouts=skin_layouts,
      bindless_heap?=bindless,
      samples=samples,
    ),
  )
  let skin_blend_pipe = dev.create_graphics_pipeline(
    @tycho.PipelineDesc::from_spirv(
      spv_pbr_skin_vert,
      pbr_frag,
      depth_test=true,
      depth_write=false,
      depth_compare=@tycho.CompareOp::GreaterEqual,
      depth_format=@tycho.TextureFormat::Depth32F,
      cull_mode=@tycho.CullMode::Back,
      front_face=@tycho.FrontFace::CounterClockwise,
      blend=true,
      blend_mode=@tycho.BlendMode::Alpha,
      color_format=@tycho.TextureFormat::RGBA16F,
      vertex_layouts=skin_layouts,
      bindless_heap?=bindless,
      samples=samples,
    ),
  )
  let morph_layouts : Array[@tycho.VertexBufferLayout] = [
    @tycho.VertexBufferLayout::new(
      MORPH_VERTEX_BYTES,
      [
        @tycho.VertexAttribute::new(0, @tycho.VertexFormat::Float3, 0),
        @tycho.VertexAttribute::new(1, @tycho.VertexFormat::Float3, 12),
        @tycho.VertexAttribute::new(2, @tycho.VertexFormat::Float2, 24),
        @tycho.VertexAttribute::new(3, @tycho.VertexFormat::Float4, 32),
        @tycho.VertexAttribute::new(6, @tycho.VertexFormat::Float3, 48),
        @tycho.VertexAttribute::new(7, @tycho.VertexFormat::Float3, 60),
      ],
    ),
  ]
  let morph_pipe = dev.create_graphics_pipeline(
    @tycho.PipelineDesc::from_spirv(
      spv_pbr_morph_vert,
      pbr_frag,
      depth_test=true,
      depth_write=true,
      depth_compare=@tycho.CompareOp::GreaterEqual,
      depth_format=@tycho.TextureFormat::Depth32F,
      cull_mode=@tycho.CullMode::Back,
      front_face=@tycho.FrontFace::CounterClockwise,
      color_format=@tycho.TextureFormat::RGBA16F,
      vertex_layouts=morph_layouts,
      bindless_heap?=bindless,
      samples=samples,
    ),
  )
  let morph_shadow_pipe = dev.create_graphics_pipeline(
    @tycho.PipelineDesc::from_spirv(
      spv_shadow_morph_vert,
      [],
      depth_test=true,
      depth_write=true,
      depth_compare=@tycho.CompareOp::LessEqual,
      depth_format=@tycho.TextureFormat::Depth24Stencil8,
      depth_only=true,
      depth_bias=true,
      depth_bias_constant=(1.5 : Float),
      depth_bias_slope=(1.75 : Float),
      vertex_layouts=morph_layouts,
    ),
  )
  let shadow_skin_pipe = dev.create_graphics_pipeline(
    @tycho.PipelineDesc::from_spirv(
      spv_shadow_skin_vert,
      [],
      depth_test=true,
      depth_write=true,
      depth_compare=@tycho.CompareOp::LessEqual,
      depth_format=@tycho.TextureFormat::Depth24Stencil8,
      depth_only=true,
      depth_bias=true,
      depth_bias_constant=(1.5 : Float),
      depth_bias_slope=(1.75 : Float),
      vertex_layouts=skin_layouts,
    ),
  )
  let rt_pipe = if rt_supported {
    Some(
      dev.create_graphics_pipeline(
        @tycho.PipelineDesc::from_spirv(
          spv_pbr_vert,
          spv_pbr_frag_rt,
          depth_test=true,
          depth_write=true,
          depth_compare=@tycho.CompareOp::GreaterEqual,
          depth_format=@tycho.TextureFormat::Depth32F,
          cull_mode=@tycho.CullMode::Back,
          front_face=@tycho.FrontFace::CounterClockwise,
          color_format=@tycho.TextureFormat::RGBA16F,
          vertex_layouts=mesh_layouts,
          bindless_heap?=bindless,
          samples=samples,
        ),
      ),
    )
  } else {
    None
  }
  let rt_cull_pipe = if rt_supported && desc.gpu_culling && bindless_ok {
    Some(
      dev.create_graphics_pipeline(
        @tycho.PipelineDesc::from_spirv(
          spv_pbr_cull_vert,
          spv_pbr_frag_rt,
          depth_test=true,
          depth_write=true,
          depth_compare=@tycho.CompareOp::GreaterEqual,
          depth_format=@tycho.TextureFormat::Depth32F,
          cull_mode=@tycho.CullMode::Back,
          front_face=@tycho.FrontFace::CounterClockwise,
          color_format=@tycho.TextureFormat::RGBA16F,
          vertex_layouts=mesh_layouts,
          bindless_heap?=bindless,
          samples=samples,
        ),
      ),
    )
  } else {
    None
  }
  let sky_pipe = dev.create_graphics_pipeline(
    @tycho.PipelineDesc::from_spirv(
      spv_skybox_vert,
      spv_skybox_frag,
      depth_format=@tycho.TextureFormat::Depth32F,
      color_format=@tycho.TextureFormat::RGBA16F,
      samples=samples,
    ),
  )
  let bloom_extract_pipe = dev.create_graphics_pipeline(
    @tycho.PipelineDesc::from_spirv(
      spv_fullscreen_vert,
      spv_bloom_extract_frag,
      color_format=@tycho.TextureFormat::RGBA16F,
    ),
  )
  let bloom_blur_pipe = dev.create_graphics_pipeline(
    @tycho.PipelineDesc::from_spirv(
      spv_fullscreen_vert,
      spv_bloom_blur_frag,
      color_format=@tycho.TextureFormat::RGBA16F,
    ),
  )
  let tonemap_srgb_pipe = dev.create_graphics_pipeline(
    @tycho.PipelineDesc::from_spirv(
      spv_fullscreen_vert,
      spv_tonemap_frag,
      color_format=@tycho.TextureFormat::RGBA8Srgb,
    ),
  )
  let tonemap_linear_pipe = dev.create_graphics_pipeline(
    @tycho.PipelineDesc::from_spirv(
      spv_fullscreen_vert,
      spv_tonemap_frag,
      color_format=@tycho.TextureFormat::RGBA8,
    ),
  )
  let ssao_pipe = dev.create_graphics_pipeline(
    @tycho.PipelineDesc::from_spirv(
      spv_fullscreen_vert,
      spv_ssao_frag,
      color_format=@tycho.TextureFormat::RGBA8,
    ),
  )
  let ssao_blur_pipe = dev.create_graphics_pipeline(
    @tycho.PipelineDesc::from_spirv(
      spv_fullscreen_vert,
      spv_ssao_blur_frag,
      color_format=@tycho.TextureFormat::RGBA8,
    ),
  )
  // Depth is sampled as a plain texel value, so nearest + clamp is the correct
  // filtering (linear depth filtering would blur silhouettes).
  let depth_sampler = dev.create_sampler_desc(
    @tycho.SamplerDesc::new(
      mag=@tycho.Filter::Nearest,
      min=@tycho.Filter::Nearest,
      mipmap=@tycho.Filter::Nearest,
      address=@tycho.AddressMode::ClampToEdge,
    ),
  )
  let ssao_ubo = dev.create_buffer_with(
    SSAO_BYTES,
    @tycho.BufferKind::Uniform,
    location=@tycho.MemoryLocation::CpuToGpu,
  )
  let mut cull_pipe : @tycho.Pipeline? = None
  let mut pbr_cull_pipe : @tycho.Pipeline? = None
  let cull_vis : Array[@tycho.Buffer] = []
  let cull_cmds : Array[@tycho.Buffer] = []
  // Indirect commands drive every solid draw (static batch cache), so these
  // buffers exist whether or not GPU culling is enabled.
  for i = 0; i < 2; i = i + 1 {
    cull_cmds.push(
      dev.create_buffer_with(
        desc.max_objects * 20,
        @tycho.BufferKind::Indirect,
        location=@tycho.MemoryLocation::CpuToGpu,
      ),
    )
  }
  if desc.gpu_culling && bindless_ok {
    cull_pipe = Some(dev.create_compute_pipeline_auto(spv_cull_comp))
    pbr_cull_pipe = Some(
      dev.create_graphics_pipeline(
        @tycho.PipelineDesc::from_spirv(
          spv_pbr_cull_vert,
          spv_pbr_frag,
          depth_test=true,
          depth_write=true,
          depth_compare=@tycho.CompareOp::GreaterEqual,
          depth_format=@tycho.TextureFormat::Depth32F,
          cull_mode=@tycho.CullMode::Back,
          front_face=@tycho.FrontFace::CounterClockwise,
          color_format=@tycho.TextureFormat::RGBA16F,
          vertex_layouts=mesh_layouts,
          bindless_heap?=bindless,
          samples=samples,
        ),
      ),
    )
    for i = 0; i < 2; i = i + 1 {
      cull_vis.push(
        dev.create_buffer_with(
          desc.max_objects * 4,
          @tycho.BufferKind::Storage,
          location=@tycho.MemoryLocation::CpuToGpu,
        ),
      )
    }
  }
  let line_layouts : Array[@tycho.VertexBufferLayout] = [
    @tycho.VertexBufferLayout::new(
      24,
      [
        @tycho.VertexAttribute::new(0, @tycho.VertexFormat::Float3, 0),
        @tycho.VertexAttribute::new(1, @tycho.VertexFormat::Float3, 12),
      ],
    ),
  ]
  let line_pipe = dev.create_graphics_pipeline(
    @tycho.PipelineDesc::from_spirv(
      spv_lines_vert,
      spv_lines_frag,
      topology=@tycho.PrimitiveTopology::LineList,
      depth_test=true,
      depth_write=false,
      depth_compare=@tycho.CompareOp::GreaterEqual,
      depth_format=@tycho.TextureFormat::Depth32F,
      color_format=@tycho.TextureFormat::RGBA16F,
      vertex_layouts=line_layouts,
      samples=samples,
    ),
  )
  let shadow_sampler = dev.create_sampler_desc(
    @tycho.SamplerDesc::new(
      mag=@tycho.Filter::Linear,
      min=@tycho.Filter::Linear,
      mipmap=@tycho.Filter::Nearest,
      address=@tycho.AddressMode::ClampToBorder,
      border_color=@tycho.BorderColor::OpaqueWhite,
      compare_op=@tycho.CompareOp::LessEqual,
    ),
  )
  let env_sampler = dev.create_sampler_desc(
    @tycho.SamplerDesc::new(
      mag=@tycho.Filter::Linear,
      min=@tycho.Filter::Linear,
      mipmap=@tycho.Filter::Linear,
      address=@tycho.AddressMode::ClampToEdge,
    ),
  )
  let linear_sampler = dev.create_sampler_desc(
    @tycho.SamplerDesc::new(
      mag=@tycho.Filter::Linear,
      min=@tycho.Filter::Linear,
      mipmap=@tycho.Filter::Nearest,
      address=@tycho.AddressMode::ClampToEdge,
    ),
  )
  let brdf_lut = create_brdf_lut(dev)
  let env_cube = default_environment_cubemap(dev)
  // 2x2 shadow atlas: up to four shadow-casting lights, one tile each.
  let shadow_atlas = dev.create_depth_texture_format(
    desc.shadow_map_size * 4,
    desc.shadow_map_size * 2,
    @tycho.TextureFormat::Depth24Stencil8,
  )
  {
    dev,
    desc,
    msaa,
    meshes: [],
    vertex_arena: dev.create_buffer_with(
      4,
      @tycho.BufferKind::Vertex,
      location=@tycho.MemoryLocation::GpuOnly,
    ),
    index_arena: dev.create_buffer_with(
      4,
      @tycho.BufferKind::Index,
      location=@tycho.MemoryLocation::GpuOnly,
    ),
    arena_floats: [],
    arena_indices: [],
    draw_count: dev.create_buffer_with(
      4,
      @tycho.BufferKind::Indirect,
      location=@tycho.MemoryLocation::CpuToGpu,
    ),
    skin_arena: dev.create_buffer_with(
      4,
      @tycho.BufferKind::Vertex,
      location=@tycho.MemoryLocation::GpuOnly,
    ),
    skin_floats: [],
    bone_ssbo: dev.create_buffer_with(
      MAX_BONES * BONE_BYTES,
      @tycho.BufferKind::Storage,
      location=@tycho.MemoryLocation::CpuToGpu,
    ),
    shadow_tiles_ssbo: dev.create_buffer_with(
      SHADOW_TILES_MAX * SHADOW_TILE_BYTES,
      @tycho.BufferKind::Storage,
      location=@tycho.MemoryLocation::CpuToGpu,
    ),
    bone_scratch: FixedArray::make(MAX_BONES * 16, (0.0 : Float)),
    bone_cursor: 0,
    skins: [],
    lods: [],
    morph_arena: dev.create_buffer_with(
      4,
      @tycho.BufferKind::Vertex,
      location=@tycho.MemoryLocation::GpuOnly,
    ),
    morph_floats: [],
    morph_weights: [],
    rt_supported,
    rt_enabled: false,
    rt_pipe,
    rt_cull_pipe,
    rt_tlas: None,
    rt_meshes: [],
    pick_bvhs: [],
    materials: [],
    object_ring: @pool.FrameRing::new(dev, desc.max_objects * OBJECT_BYTES),
    light_ring: @pool.FrameRing::new(dev, desc.max_lights * LIGHT_BYTES),
    frame_ubo: dev.create_buffer_with(
      FRAME_SLOT_BYTES * 2,
      @tycho.BufferKind::Uniform,
      location=@tycho.MemoryLocation::CpuToGpu,
    ),
    sky_ubo: dev.create_buffer_with(
      SKY_SLOT_BYTES * 2,
      @tycho.BufferKind::Uniform,
      location=@tycho.MemoryLocation::CpuToGpu,
    ),
    material_ssbo: dev.create_buffer_with(
      desc.max_materials * MATERIAL_BYTES,
      @tycho.BufferKind::Storage,
      location=@tycho.MemoryLocation::CpuToGpu,
    ),
    shadow_atlas,
    shadow_sampler,
    env_sampler,
    linear_sampler,
    material_sampler,
    brdf_lut,
    bindless,
    bindless_ok,
    white_tex,
    flat_normal_tex,
    white_index,
    flat_normal_index,
    textures: [],
    env_cube,
    env_sun: @tmath.Vec3::new(3.0, 4.0, -2.0).normalize(),
    env_intensity: 1.0,
    owns_env: true,
    background: None,
    fog: None,
    shadow_pipe,
    shadow_skin_pipe,
    pbr_pipe,
    skin_pipe,
    skin_blend_pipe,
    morph_pipe,
    morph_shadow_pipe,
    pbr_blend_pipe,
    pbr_transmission_pipe,
    sky_pipe,
    bloom_extract_pipe,
    bloom_blur_pipe,
    tonemap_srgb_pipe,
    tonemap_linear_pipe,
    ssao: desc.ssao,
    ssao_radius: 0.6,
    ssao_intensity: 1.0,
    ssao_bias: 0.02,
    ssao_ubo,
    ssao_pipe,
    ssao_blur_pipe,
    ssao_writer: @tmath.GpuPackWriter::std140(SSAO_FLOATS),
    depth_sampler,
    gpu_culling: desc.gpu_culling && bindless_ok,
    cull_pipe,
    pbr_cull_pipe,
    cull_vis,
    cull_cmds,
    line_pipe,
    line_vbuf: dev.create_buffer_with(
      1024 * 24,
      @tycho.BufferKind::Vertex,
      location=@tycho.MemoryLocation::GpuOnly,
    ),
    line_capacity: 1024,
    line_floats: [],
    line_sets: [],
    object_writer: @tmath.GpuPackWriter::std430(desc.max_objects * OBJECT_FLOATS),
    light_writer: @tmath.GpuPackWriter::std430(desc.max_lights * LIGHT_FLOATS),
    material_writer: @tmath.GpuPackWriter::std430(desc.max_materials * MATERIAL_FLOATS),
    frame_writer: @tmath.GpuPackWriter::std140(FRAME_FLOATS),
    sky_writer: @tmath.GpuPackWriter::std140(SKY_FLOATS),
    targets: None,
    present: None,
    present_w: 0,
    present_h: 0,
    stats: RenderStats3D::new(),
  }
}

///|
pub fn Renderer3D::upload_mesh(self : Renderer3D, mesh : @tgeo.MeshData) -> MeshHandle raise {
  if !mesh.has_tangents() {
    mesh.compute_tangents()
  }
  let first_index = self.arena_indices.length()
  for ix in mesh.indices() {
    self.arena_indices.push(ix)
  }
  let first_vertex = if mesh.has_skin() {
    let floats = mesh_skinned_vertex_floats(mesh)
    let fv = self.skin_floats.length() / SKIN_VERTEX_FLOATS
    for f in floats {
      self.skin_floats.push(f)
    }
    self.rebuild_skin_arena()
    fv
  } else if mesh.has_morph() {
    let floats = mesh_morph_vertex_floats(mesh)
    let fv = self.morph_floats.length() / MORPH_VERTEX_FLOATS
    for f in floats {
      self.morph_floats.push(f)
    }
    self.rebuild_morph_arena()
    fv
  } else {
    let floats = mesh_vertex_floats(mesh)
    let fv = self.arena_floats.length() / MESH_VERTEX_FLOATS
    for f in floats {
      self.arena_floats.push(f)
    }
    self.rebuild_arenas()
    fv
  }
  self.meshes.push(GpuMesh::range(mesh, first_vertex, first_index))
  self.pick_bvhs.push(None)
  if self.rt_supported && !mesh.has_skin() && !mesh.has_morph() {
    self.rt_meshes.push(Some(self.build_mesh_blas(mesh)))
  } else {
    self.rt_meshes.push(None)
  }
  MeshHandle::from_id(self.meshes.length() - 1)
}

///|
fn Renderer3D::build_mesh_blas(self : Renderer3D, mesh : @tgeo.MeshData) -> RtMesh raise {
  let floats = mesh_vertex_floats(mesh)
  let vbuf = self.dev.create_buffer_with(
    floats.length() * 4,
    @tycho.BufferKind::Vertex,
    location=@tycho.MemoryLocation::GpuOnly,
  )
  vbuf.upload_floats(floats)
  let ix = FixedArray::from_array(mesh.indices())
  let ibuf = self.dev.create_buffer_with(
    if ix.length() == 0 { 4 } else { ix.length() * 4 },
    @tycho.BufferKind::Index,
    location=@tycho.MemoryLocation::GpuOnly,
  )
  if ix.length() > 0 {
    ibuf.upload_uint32(ix)
  }
  let blas = self.dev.create_blas([
    @tycho.RayGeometryDesc::new(
      vbuf,
      mesh.vertex_count(),
      index_buffer=ibuf,
      index_count=mesh.index_count(),
    ),
  ])
  { blas, vbuf, ibuf }
}

///|
/// Upload a `@tgeo.LineData` line list as a *local-space* drawable.
///
/// The list is drawn by `NodePayload::Lines` scene nodes, which supply the
/// world transform and the colour tint through push constants. Vertices bake
/// white, so the node's `LineMaterial` fully controls the colour.
pub fn Renderer3D::upload_lines(
  self : Renderer3D,
  lines : @tgeo.LineData,
) -> LineHandle raise {
  let segments = lines.segment_count()
  let floats : Array[Float] = []
  for i = 0; i < segments; i = i + 1 {
    let ia = lines.indices[2 * i].reinterpret_as_int()
    let ib = lines.indices[2 * i + 1].reinterpret_as_int()
    for p in [lines.positions[ia], lines.positions[ib]] {
      floats.push(p.x)
      floats.push(p.y)
      floats.push(p.z)
      floats.push(1.0)
      floats.push(1.0)
      floats.push(1.0)
    }
  }
  let vertex_count = segments * 2
  let buffer = self.dev.create_buffer_with(
    if vertex_count == 0 { 24 } else { vertex_count * 24 },
    @tycho.BufferKind::Vertex,
    location=@tycho.MemoryLocation::GpuOnly,
  )
  if vertex_count > 0 {
    buffer.upload_floats(FixedArray::from_array(floats))
  }
  self.line_sets.push({
    buffer,
    cpu: lines,
    vertex_count,
    segment_count: segments,
    bounds: lines.bounds(),
  })
  LineHandle::from_id(self.line_sets.length() - 1)
}

///|
/// Bounds of an uploaded line list, or `None` for a stale handle.
pub fn Renderer3D::lines_bounds(
  self : Renderer3D,
  h : LineHandle,
) -> @tmath.Aabb3? {
  let id = h.id()
  if id >= 0 && id < self.line_sets.length() {
    Some(self.line_sets[id].bounds)
  } else {
    None
  }
}

///|
/// Rebuild the TLAS from the scene's static mesh instances (skinned and morph
/// meshes have no BLAS). Falls back to shadow maps when the cap is exceeded.
fn Renderer3D::rebuild_rt_tlas(self : Renderer3D, scene : Scene) -> Unit raise {
  if !self.rt_supported || !self.rt_enabled {
    return
  }
  match self.rt_tlas {
    Some(t) => {
      t.destroy()
      self.rt_tlas = None
    }
    None => ()
  }
  let ids : Array[NodeId] = []
  scene.traverse(fn(id) {
    match scene.payload(id) {
      Some(NodePayload::Mesh(_)) => ids.push(id)
      _ => ()
    }
  })
  let insts : Array[@tycho.RayInstanceDesc] = []
  for id in ids {
    if insts.length() >= 256 {
      break
    }
    match scene.payload(id) {
      Some(NodePayload::Mesh(inst)) => {
        let mi = inst.mesh.id()
        if mi >= 0 && mi < self.rt_meshes.length() {
          match self.rt_meshes[mi] {
            Some(rm) => {
              insts.push(
                @tycho.RayInstanceDesc::from_affine3(rm.blas, scene.world_transform(id)),
              )
            }
            None => ()
          }
        }
      }
      _ => ()
    }
  }
  if insts.length() == 0 || insts.length() >= 256 {
    return
  }
  self.rt_tlas = Some(self.dev.create_tlas(insts))
}

///|
/// Toggle hardware ray-traced sun shadows (no effect when unsupported).
pub fn Renderer3D::set_ray_shadows(self : Renderer3D, enabled : Bool) -> Unit {
  self.rt_enabled = enabled && self.rt_supported
}

///|
pub fn Renderer3D::ray_shadows_supported(self : Renderer3D) -> Bool {
  self.rt_supported
}

///|
fn Renderer3D::rebuild_arenas(self : Renderer3D) -> Unit raise {
  let vf = FixedArray::from_array(self.arena_floats)
  let ix = FixedArray::from_array(self.arena_indices)
  self.vertex_arena.destroy()
  self.index_arena.destroy()
  self.vertex_arena = self.dev.create_buffer_with(
    if vf.length() == 0 { 4 } else { vf.length() * 4 },
    @tycho.BufferKind::Vertex,
    location=@tycho.MemoryLocation::GpuOnly,
  )
  if vf.length() > 0 {
    self.vertex_arena.upload_floats(vf)
  }
  self.index_arena = self.dev.create_buffer_with(
    if ix.length() == 0 { 4 } else { ix.length() * 4 },
    @tycho.BufferKind::Index,
    location=@tycho.MemoryLocation::GpuOnly,
  )
  if ix.length() > 0 {
    self.index_arena.upload_uint32(ix)
  }
}

///|
fn Renderer3D::bind_arenas(self : Renderer3D, cmd : @tycho.CommandBuffer) -> Unit {
  cmd.bind_vertex(0, self.vertex_arena)
  cmd.bind_index(self.index_arena, @tycho.IndexType::Uint32)
}

///|
fn Renderer3D::rebuild_skin_arena(self : Renderer3D) -> Unit raise {
  let vf = FixedArray::from_array(self.skin_floats)
  let ix = FixedArray::from_array(self.arena_indices)
  self.skin_arena.destroy()
  self.index_arena.destroy()
  self.skin_arena = self.dev.create_buffer_with(
    if vf.length() == 0 { 4 } else { vf.length() * 4 },
    @tycho.BufferKind::Vertex,
    location=@tycho.MemoryLocation::GpuOnly,
  )
  if vf.length() > 0 {
    self.skin_arena.upload_floats(vf)
  }
  self.index_arena = self.dev.create_buffer_with(
    if ix.length() == 0 { 4 } else { ix.length() * 4 },
    @tycho.BufferKind::Index,
    location=@tycho.MemoryLocation::GpuOnly,
  )
  if ix.length() > 0 {
    self.index_arena.upload_uint32(ix)
  }
}

///|
fn Renderer3D::rebuild_morph_arena(self : Renderer3D) -> Unit raise {
  let vf = FixedArray::from_array(self.morph_floats)
  let ix = FixedArray::from_array(self.arena_indices)
  self.morph_arena.destroy()
  self.index_arena.destroy()
  self.morph_arena = self.dev.create_buffer_with(
    if vf.length() == 0 { 4 } else { vf.length() * 4 },
    @tycho.BufferKind::Vertex,
    location=@tycho.MemoryLocation::GpuOnly,
  )
  if vf.length() > 0 {
    self.morph_arena.upload_floats(vf)
  }
  self.index_arena = self.dev.create_buffer_with(
    if ix.length() == 0 { 4 } else { ix.length() * 4 },
    @tycho.BufferKind::Index,
    location=@tycho.MemoryLocation::GpuOnly,
  )
  if ix.length() > 0 {
    self.index_arena.upload_uint32(ix)
  }
}

///|
fn Renderer3D::bind_morph_arenas(self : Renderer3D, cmd : @tycho.CommandBuffer) -> Unit {
  cmd.bind_vertex(0, self.morph_arena)
  cmd.bind_index(self.index_arena, @tycho.IndexType::Uint32)
}

///|
fn Renderer3D::morph_weights_of(self : Renderer3D, node : NodeId) -> (Float, Float) {
  for entry in self.morph_weights {
    let (n, w) = entry
    if n == node {
      let w0 : Float = if w.length() > 0 { w[0] } else { 0.0 }
      let w1 : Float = if w.length() > 1 { w[1] } else { 0.0 }
      return (w0, w1)
    }
  }
  (0.0, 0.0)
}

///|
fn Renderer3D::pack_shadow_tiles(
  self : Renderer3D,
  tiles : Array[ShadowTile],
) -> Unit raise {
  let count = if tiles.length() > SHADOW_TILES_MAX {
    SHADOW_TILES_MAX
  } else {
    tiles.length()
  }
  if count == 0 {
    return
  }
  let data = FixedArray::make(count * 20, (0.0 : Float))
  for i = 0; i < count; i = i + 1 {
    let t = tiles[i]
    let o = i * 20
    let m = t.vp
    data[o] = m.x_axis.x
    data[o + 1] = m.x_axis.y
    data[o + 2] = m.x_axis.z
    data[o + 3] = m.x_axis.w
    data[o + 4] = m.y_axis.x
    data[o + 5] = m.y_axis.y
    data[o + 6] = m.y_axis.z
    data[o + 7] = m.y_axis.w
    data[o + 8] = m.z_axis.x
    data[o + 9] = m.z_axis.y
    data[o + 10] = m.z_axis.z
    data[o + 11] = m.z_axis.w
    data[o + 12] = m.w_axis.x
    data[o + 13] = m.w_axis.y
    data[o + 14] = m.w_axis.z
    data[o + 15] = m.w_axis.w
    data[o + 16] = f_of_int(t.tile % 4) * 0.25
    data[o + 17] = f_of_int(t.tile / 4) * 0.5
    data[o + 18] = 0.25
    data[o + 19] = 0.5
  }
  self.shadow_tiles_ssbo.upload_floats(data)
}

///|
fn bind_shadow_tiles_bytes(count : Int) -> Int {
  if count > 0 {
    (if count > SHADOW_TILES_MAX { SHADOW_TILES_MAX } else { count }) * SHADOW_TILE_BYTES
  } else {
    SHADOW_TILE_BYTES
  }
}

///|
fn shadow_morph_pc(vp : @tmath.Mat4, w0 : Float, w1 : Float) -> FixedArray[Float] {
  let out = FixedArray::make(20, (0.0 : Float))
  let base = shadow_pc_floats(vp)
  for i = 0; i < 16; i = i + 1 {
    out[i] = base[i]
  }
  out[16] = w0
  out[17] = w1
  out
}

///|
fn Renderer3D::bind_skin_arenas(self : Renderer3D, cmd : @tycho.CommandBuffer) -> Unit {
  cmd.bind_vertex(0, self.skin_arena)
  cmd.bind_index(self.index_arena, @tycho.IndexType::Uint32)
}

///|
/// Refresh the palette: joint world matrix * inverse bind, in mesh-local space.
fn Renderer3D::update_bones(self : Renderer3D, scene : Scene) -> Unit raise {
  for s in self.skins {
    for i = 0; i < s.count; i = i + 1 {
      let world = scene.world_transform(s.joints[i]).to_mat4()
      let m = world * s.inverse_bind[i]
      let base = (s.offset + i) * 16
      self.bone_scratch[base] = m.x_axis.x
      self.bone_scratch[base + 1] = m.x_axis.y
      self.bone_scratch[base + 2] = m.x_axis.z
      self.bone_scratch[base + 3] = m.x_axis.w
      self.bone_scratch[base + 4] = m.y_axis.x
      self.bone_scratch[base + 5] = m.y_axis.y
      self.bone_scratch[base + 6] = m.y_axis.z
      self.bone_scratch[base + 7] = m.y_axis.w
      self.bone_scratch[base + 8] = m.z_axis.x
      self.bone_scratch[base + 9] = m.z_axis.y
      self.bone_scratch[base + 10] = m.z_axis.z
      self.bone_scratch[base + 11] = m.z_axis.w
      self.bone_scratch[base + 12] = m.w_axis.x
      self.bone_scratch[base + 13] = m.w_axis.y
      self.bone_scratch[base + 14] = m.w_axis.z
      self.bone_scratch[base + 15] = m.w_axis.w
    }
  }
  if self.bone_cursor > 0 {
    self.bone_ssbo.upload_floats(
      self.bone_scratch,
      count=self.bone_cursor * 16,
    )
  }
}

///|
/// Descriptor ranges must stay non-zero even with no bones uploaded.
fn bind_bones_bytes(count : Int) -> Int {
  if count > 0 {
    count * BONE_BYTES
  } else {
    BONE_BYTES
  }
}

///|
pub fn Renderer3D::mesh_bounds(self : Renderer3D, h : MeshHandle) -> @tmath.Aabb3? {
  let i = h.id()
  if i >= 0 && i < self.meshes.length() {
    Some(self.meshes[i].bounds())
  } else {
    None
  }
}

///|
fn Renderer3D::repack_materials(self : Renderer3D) -> Unit raise {
  self.material_writer.reset()
  for m in self.materials {
    self.pack_material(m)
  }
  if self.materials.length() > 0 {
    self.material_ssbo.upload_floats(
      self.material_writer.buffer(),
      count=self.materials.length() * MATERIAL_FLOATS,
    )
  }
}

///|
/// Upload an RGBA8 texture. `srgb` selects `RGBA8Srgb` (albedo/emissive) versus
/// linear `RGBA8` (normal/metallic-roughness maps).
pub fn Renderer3D::create_texture(
  self : Renderer3D,
  width : Int,
  height : Int,
  rgba8 : FixedArray[Byte],
  srgb? : Bool = true,
) -> TextureHandle raise {
  let expected = width * height * 4
  if width <= 0 || height <= 0 || rgba8.length() != expected {
    raise Render3DError::InvalidTexture("Renderer3D: create_texture expects width*height*4 bytes")
  }
  let arr : Array[Byte] = []
  for b in rgba8 {
    arr.push(b)
  }
  let tex = self.dev.create_texture_format(
    width,
    height,
    if srgb { @tycho.TextureFormat::RGBA8Srgb } else { @tycho.TextureFormat::RGBA8 },
    Bytes::from_array(arr),
  )
  let index = match self.bindless {
    Some(h) => h.register_texture(tex, self.material_sampler)
    None => 0
  }
  self.textures.push({ tex, index })
  TextureHandle::from_id(self.textures.length() - 1)
}

///|
pub fn Renderer3D::create_material(self : Renderer3D, m : MaterialDesc) -> MaterialHandle raise {
  if self.materials.length() >= self.desc.max_materials {
    raise Render3DError::CapacityExceeded("Renderer3D: material capacity exhausted")
  }
  self.materials.push(m)
  self.repack_materials()
  MaterialHandle::from_id(self.materials.length() - 1)
}

///|
pub fn Renderer3D::update_material(
  self : Renderer3D,
  h : MaterialHandle,
  m : MaterialDesc,
) -> Unit raise {
  let i = h.id()
  if i < 0 || i >= self.materials.length() {
    raise Render3DError::InvalidMaterial("Renderer3D: invalid material handle")
  }
  self.materials[i] = m
  self.repack_materials()
}

///|
pub fn Renderer3D::set_environment(
  self : Renderer3D,
  cube : @tycho.Texture,
  sun_dir : @tmath.Vec3,
  intensity? : Float = 1.0,
) -> Unit {
  if self.owns_env {
    self.env_cube.destroy()
  }
  self.env_cube = cube
  self.env_sun = sun_dir.normalize()
  self.env_intensity = intensity
  self.owns_env = false
}

///|
fn Renderer3D::destroy_targets(targets : FrameTargets) -> Unit {
  targets.depth.destroy()
  match targets.hdr_resolve {
    Some(t) => t.destroy()
    None => ()
  }
  targets.hdr.destroy()
  targets.scene_copy.destroy()
  match targets.ao_a {
    Some(t) => t.destroy()
    None => ()
  }
  match targets.ao_b {
    Some(t) => t.destroy()
    None => ()
  }
  targets.bloom_a.destroy()
  targets.bloom_b.destroy()
}

///|
fn Renderer3D::create_targets(self : Renderer3D, w : Int, h : Int) -> FrameTargets raise {
  let bw = if w / 2 < 1 { 1 } else { w / 2 }
  let bh = if h / 2 < 1 { 1 } else { h / 2 }
  let samples = if self.msaa {
    @tycho.SampleCount::X4
  } else {
    @tycho.SampleCount::X1
  }
  {
    w,
    h,
    depth: self.dev.create_depth_texture_format(
      w,
      h,
      @tycho.TextureFormat::Depth32F,
      samples=samples,
    ),
    hdr: self.dev.create_render_target(
      w,
      h,
      @tycho.TextureFormat::RGBA16F,
      samples=samples,
    ),
    hdr_resolve: if self.msaa {
      Some(self.dev.create_render_target(w, h, @tycho.TextureFormat::RGBA16F))
    } else {
      None
    },
    scene_copy: self.dev.create_render_target(w, h, @tycho.TextureFormat::RGBA16F),
    ao_a: if self.ssao {
      Some(self.dev.create_render_target(w, h, @tycho.TextureFormat::RGBA8))
    } else {
      None
    },
    ao_b: if self.ssao {
      Some(self.dev.create_render_target(w, h, @tycho.TextureFormat::RGBA8))
    } else {
      None
    },
    bloom_a: self.dev.create_render_target(bw, bh, @tycho.TextureFormat::RGBA16F),
    bloom_b: self.dev.create_render_target(bw, bh, @tycho.TextureFormat::RGBA16F),
  }
}

///|
fn Renderer3D::ensure_targets(self : Renderer3D, w : Int, h : Int) -> FrameTargets raise {
  match self.targets {
    Some(t) =>
      if t.w == w && t.h == h {
        t
      } else {
        Renderer3D::destroy_targets(t)
        let nt = self.create_targets(w, h)
        self.targets = Some(nt)
        nt
      }
    None => {
      let nt = self.create_targets(w, h)
      self.targets = Some(nt)
      nt
    }
  }
}

///|
fn Renderer3D::ensure_present(self : Renderer3D, w : Int, h : Int) -> @tycho.Texture raise {
  match self.present {
    Some(t) =>
      if self.present_w == w && self.present_h == h {
        t
      } else {
        t.destroy()
        let nt = self.dev.create_render_target(w, h, @tycho.TextureFormat::RGBA8Srgb)
        self.present = Some(nt)
        self.present_w = w
        self.present_h = h
        nt
      }
    None => {
      let nt = self.dev.create_render_target(w, h, @tycho.TextureFormat::RGBA8Srgb)
      self.present = Some(nt)
      self.present_w = w
      self.present_h = h
      nt
    }
  }
}

///|
fn Renderer3D::pack_object(
  self : Renderer3D,
  item : DrawItem,
  scene : Scene,
) -> Unit {
  let world = scene.world_transform(item.node)
  self.object_writer.push_mat4(world.to_mat4())
  let nm = match world.normal_matrix() {
    Some(m) => m
    None => world.matrix3
  }
  self.object_writer.push_mat4(nm.to_mat4())
  // Local bounding sphere for GPU culling (material travels via push constant).
  let b = self.meshes[item.mesh].bounds()
  let c = b.center()
  self.object_writer.push_float(c.x)
  self.object_writer.push_float(c.y)
  self.object_writer.push_float(c.z)
  self.object_writer.push_float(b.half_extents().length())
  let mesh = self.meshes[item.mesh]
  let mut joint_offset : Float = 0.0
  let mut joint_count : Float = 0.0
  let mut skinned : Float = 0.0
  if mesh.skinned() {
    skinned = 1.0
    for s in self.skins {
      if s.node == item.node {
        joint_offset = f_of_int(s.offset)
        joint_count = f_of_int(s.count)
      }
    }
  }
  self.object_writer.push_float(f_of_int(item.material))
  self.object_writer.push_float(joint_offset)
  self.object_writer.push_float(joint_count)
  self.object_writer.push_float(skinned)
}

///|
priv struct ShadowTile {
  light_index : Int
  tile : Int
  vp : @tmath.Mat4
}

///|
fn directional_shadow_vp(
  center : @tmath.Vec3,
  radius : Float,
  to_light : @tmath.Vec3,
  sd : ShadowDesc,
) -> @tmath.Mat4 {
  let up = if to_light.y.abs() > 0.99 {
    @tmath.Vec3::unit_z()
  } else {
    @tmath.Vec3::unit_y()
  }
  let half = match sd.half_extents {
    Some(h) => h
    None => radius * 1.15 + 0.1
  }
  let eye = center + to_light.scale(radius * 2.0 + 1.0)
  @tmath.orthographic_rh(-half, half, -half, half, 0.05, radius * 4.0 + 2.0) *
  @tmath.look_at_rh(eye, center, up)
}

///|
/// Cube face order matches the fragment shader: +X, -X, +Y, -Y, +Z, -Z.
fn point_shadow_vp(eye : @tmath.Vec3, far : Float, face : Int) -> @tmath.Mat4 {
  let dir = match face {
    0 => @tmath.Vec3::new(1.0, 0.0, 0.0)
    1 => @tmath.Vec3::new(-1.0, 0.0, 0.0)
    2 => @tmath.Vec3::new(0.0, 1.0, 0.0)
    3 => @tmath.Vec3::new(0.0, -1.0, 0.0)
    4 => @tmath.Vec3::new(0.0, 0.0, 1.0)
    _ => @tmath.Vec3::new(0.0, 0.0, -1.0)
  }
  let up = if face == 2 || face == 3 {
    @tmath.Vec3::unit_z()
  } else {
    @tmath.Vec3::unit_y()
  }
  @tmath.perspective_rh(@tmath.PI / 2.0, 1.0, 0.05, far) *
  @tmath.look_at_rh(eye, eye + dir, up)
}

///|
fn spot_shadow_vp(
  eye : @tmath.Vec3,
  to_light : @tmath.Vec3,
  outer_angle : Float,
  range : Float,
) -> @tmath.Mat4 {
  let up = if to_light.y.abs() > 0.99 {
    @tmath.Vec3::unit_z()
  } else {
    @tmath.Vec3::unit_y()
  }
  let mut fov = outer_angle * 2.0
  if fov < 0.2 {
    fov = 0.2
  }
  if fov > 2.6 {
    fov = 2.6
  }
  let far = if range > 0.5 { range } else { 50.0 }
  @tmath.perspective_rh(fov, 1.0, 0.05, far) *
  @tmath.look_at_rh(eye, eye + to_light, up)
}

///|
/// Push constants for `shadow.vert`: two floats (object index, tile) plus the
/// 16-byte-aligned light matrix, matching the shader's std430 block.
fn shadow_pc_floats(vp : @tmath.Mat4) -> FixedArray[Float] {
  FixedArray::from_array([
    vp.x_axis.x,
    vp.x_axis.y,
    vp.x_axis.z,
    vp.x_axis.w,
    vp.y_axis.x,
    vp.y_axis.y,
    vp.y_axis.z,
    vp.y_axis.w,
    vp.z_axis.x,
    vp.z_axis.y,
    vp.z_axis.z,
    vp.z_axis.w,
    vp.w_axis.x,
    vp.w_axis.y,
    vp.w_axis.z,
    vp.w_axis.w,
  ])
}

///|
fn Renderer3D::collect_lights(
  self : Renderer3D,
  scene : Scene,
) -> (Array[(Light, @tmath.Affine3)], @tmath.Vec3?) {
  let nodes : Array[(Light, @tmath.Affine3)] = []
  scene.traverse(fn(id) {
    match scene.payload(id) {
      Some(NodePayload::Light(l)) =>
        // A hidden light (or one under a hidden group) contributes nothing,
        // matching `Object3D.visible` in three.js.
        if scene.is_visible_in_world(id) {
          nodes.push((l, scene.world_transform(id)))
        }
      _ => ()
    }
  })
  let mut shadow_dir : @tmath.Vec3? = None
  for entry in nodes {
    let (l, wmat) = entry
    match l {
      Directional(d) =>
        match d.shadow {
          Some(_) =>
            match shadow_dir {
              Some(_) => ()
              None => shadow_dir = Some(-wmat.matrix3.z_axis.normalize())
            }
          None => ()
        }
      _ => ()
    }
  }
  (nodes, shadow_dir)
}

///|
/// Choose up to four shadow-casting lights and fit each one's tile matrix.
fn Renderer3D::plan_shadows(
  self : Renderer3D,
  nodes : Array[(Light, @tmath.Affine3)],
  casters : @tmath.Aabb3?,
) -> Array[ShadowTile] {
  let tiles : Array[ShadowTile] = []
  if !self.desc.shadows {
    return tiles
  }
  let bounds = match casters {
    Some(b) => b
    None => return tiles
  }
  let center = bounds.center()
  let radius = bounds.half_extents().length() + 0.05
  for i = 0; i < nodes.length(); i = i + 1 {
    if tiles.length() >= SHADOW_TILES_MAX {
      break
    }
    let (l, wmat) = nodes[i]
    let to_light = -wmat.matrix3.z_axis.normalize()
    match l {
      Directional(d) =>
        match d.shadow {
          Some(sd) =>
            tiles.push({
              light_index: i,
              tile: tiles.length(),
              vp: directional_shadow_vp(center, radius, to_light, sd),
            })
          None => ()
        }
      Spot(s) =>
        match s.shadow {
          Some(_) =>
            tiles.push({
              light_index: i,
              tile: tiles.length(),
              vp: spot_shadow_vp(wmat.translation, to_light, s.outer_angle, s.range),
            })
          None => ()
        }
      Point(p) =>
        match p.shadow {
          Some(_) => {
            let far = if p.range > 0.5 { p.range } else { 50.0 }
            for face = 0; face < 6; face = face + 1 {
              if tiles.length() >= SHADOW_TILES_MAX {
                break
              }
              tiles.push({
                light_index: i,
                tile: tiles.length(),
                vp: point_shadow_vp(wmat.translation, far, face),
              })
            }
          }
          None => ()
        }
      _ => ()
    }
  }
  tiles
}

///|
fn Renderer3D::push_light_shadow(
  self : Renderer3D,
  index : Int,
  tiles : Array[ShadowTile],
) -> Unit {
  let mut vp = @tmath.Mat4::identity()
  let mut info = @tmath.Vec4::new(0.0, 0.0, 0.0, 0.0)
  let mut base : Float = 0.0
  let mut count = 0
  for t in tiles {
    if t.light_index == index {
      if count == 0 {
        base = f_of_int(t.tile)
        let ox = f_of_int(t.tile % 4) * 0.25
        let oy = f_of_int(t.tile / 4) * 0.5
        info = @tmath.Vec4::new(ox, oy, 0.25, 0.5)
      }
      vp = t.vp
      count = count + 1
    }
  }
  self.light_writer.push_mat4(vp)
  self.light_writer.push_vec4(info)
  if count >= 6 {
    self.light_writer.push_float(base)
    self.light_writer.push_float(6.0)
    self.light_writer.push_float(0.0)
    self.light_writer.push_float(1.0)
  } else {
    self.light_writer.push_float(0.0)
    self.light_writer.push_float(0.0)
    self.light_writer.push_float(0.0)
    self.light_writer.push_float(0.0)
  }
}

///|
fn Renderer3D::pack_lights(
  self : Renderer3D,
  light_nodes : Array[(Light, @tmath.Affine3)],
  shadow_tiles : Array[ShadowTile],
) -> Int {
  self.light_writer.reset()
  let mut count = 0
  for i = 0; i < light_nodes.length(); i = i + 1 {
    if count >= self.desc.max_lights {
      break
    }
    let (l, wmat) = light_nodes[i]
    let to_light = -wmat.matrix3.z_axis.normalize()
    match l {
      Directional(d) => {
        self.light_writer.push_float(d.color.x)
        self.light_writer.push_float(d.color.y)
        self.light_writer.push_float(d.color.z)
        self.light_writer.push_float(0.0)
        self.light_writer.push_float(to_light.x)
        self.light_writer.push_float(to_light.y)
        self.light_writer.push_float(to_light.z)
        self.light_writer.push_float(0.0)
        self.light_writer.push_float(0.0)
        self.light_writer.push_float(0.0)
        self.light_writer.push_float(0.0)
        self.light_writer.push_float(0.0)
        self.light_writer.push_float(d.intensity)
        self.light_writer.push_float(0.0)
        self.light_writer.push_float(0.0)
        self.light_writer.push_float(0.0)
      }
      Point(p) => {
        let pos = wmat.translation
        push_light_point(self.light_writer, p.color, 1.0, pos, p.range, p.intensity, 0.0)
      }
      Spot(s) => {
        let pos = wmat.translation
        let code : Float = 2.0
        self.light_writer.push_float(s.color.x)
        self.light_writer.push_float(s.color.y)
        self.light_writer.push_float(s.color.z)
        self.light_writer.push_float(code)
        self.light_writer.push_float(pos.x)
        self.light_writer.push_float(pos.y)
        self.light_writer.push_float(pos.z)
        self.light_writer.push_float(s.range)
        self.light_writer.push_float(to_light.x)
        self.light_writer.push_float(to_light.y)
        self.light_writer.push_float(to_light.z)
        self.light_writer.push_float(0.0)
        self.light_writer.push_float(s.intensity)
        self.light_writer.push_float(s.inner_angle)
        self.light_writer.push_float(s.outer_angle)
        self.light_writer.push_float(0.0)
      }
      Ambient(a) => {
        self.light_writer.push_float(a.color.x)
        self.light_writer.push_float(a.color.y)
        self.light_writer.push_float(a.color.z)
        self.light_writer.push_float(3.0)
        self.light_writer.push_float(0.0)
        self.light_writer.push_float(0.0)
        self.light_writer.push_float(0.0)
        self.light_writer.push_float(0.0)
        self.light_writer.push_float(0.0)
        self.light_writer.push_float(0.0)
        self.light_writer.push_float(0.0)
        self.light_writer.push_float(0.0)
        self.light_writer.push_float(a.intensity)
        self.light_writer.push_float(0.0)
        self.light_writer.push_float(0.0)
        self.light_writer.push_float(0.0)
      }
      Hemisphere(h) => {
        self.light_writer.push_float(h.sky.x)
        self.light_writer.push_float(h.sky.y)
        self.light_writer.push_float(h.sky.z)
        self.light_writer.push_float(4.0)
        self.light_writer.push_float(h.ground.x)
        self.light_writer.push_float(h.ground.y)
        self.light_writer.push_float(h.ground.z)
        self.light_writer.push_float(0.0)
        self.light_writer.push_float(0.0)
        self.light_writer.push_float(0.0)
        self.light_writer.push_float(0.0)
        self.light_writer.push_float(0.0)
        self.light_writer.push_float(h.intensity)
        self.light_writer.push_float(0.0)
        self.light_writer.push_float(0.0)
        self.light_writer.push_float(0.0)
      }
    }
    self.push_light_shadow(i, shadow_tiles)
    count = count + 1
  }
  count
}

///|
fn push_light_point(
  w : @tmath.GpuPackWriter,
  color : @tmath.Vec3,
  code : Float,
  pos : @tmath.Vec3,
  range : Float,
  intensity : Float,
  decay : Float,
) -> Unit {
  w.push_float(color.x)
  w.push_float(color.y)
  w.push_float(color.z)
  w.push_float(code)
  w.push_float(pos.x)
  w.push_float(pos.y)
  w.push_float(pos.z)
  w.push_float(range)
  w.push_float(0.0)
  w.push_float(0.0)
  w.push_float(0.0)
  w.push_float(decay)
  w.push_float(intensity)
  w.push_float(0.0)
  w.push_float(0.0)
  w.push_float(0.0)
}

///|
/// Push-constant payload for `lines.vert`: a 4x4 model matrix followed by an
/// RGBA tint (20 floats / 80 bytes).
fn line_push_constants(
  model : FixedArray[Float],
  color : @tmath.Vec3,
) -> FixedArray[Float] {
  let out : FixedArray[Float] = FixedArray::make(20, 0.0)
  for i = 0; i < 16; i = i + 1 {
    out[i] = model[i]
  }
  out[16] = color.x
  out[17] = color.y
  out[18] = color.z
  out[19] = 1.0
  out
}

///|
fn Renderer3D::render_frame(
  self : Renderer3D,
  cmd : @tycho.CommandBuffer,
  scene : Scene,
  camera : NodeId,
  w : Int,
  h : Int,
  dst : @tycho.Texture,
  final_format : @tycho.TextureFormat,
  slot : Int,
) -> Unit raise {
  self.stats = RenderStats3D::new()
  scene.update()
  self.prune_dead_bindings(scene)
  self.update_bones(scene)
  self.rebuild_rt_tlas(scene)
  let cam = match scene.payload(camera) {
    Some(NodePayload::Camera(c)) => c
    _ => raise Render3DError::InvalidCamera("Renderer3D: camera node has no Camera payload")
  }
  let cam_world = scene.world_transform(camera)
  let vp = match cam.view_proj(cam_world) {
    Some(v) => v
    None => raise Render3DError::InvalidCamera("Renderer3D: camera matrix is singular")
  }
  let eye = cam_world.translation
  let targets = self.ensure_targets(w, h)
  let (light_nodes, shadow_dir) = self.collect_lights(scene)
  let frustum = @tmath.Frustum::from_view_proj(vp)
  let mut gpu_cull_enabled = match self.cull_pipe {
    Some(_) => self.gpu_culling
    None => false
  }
  let visible : Array[NodeId] = if gpu_cull_enabled {
    // Hand every mesh to the GPU; per-instance culling happens in compute.
    let all : Array[NodeId] = []
    scene.traverse(fn(id) {
      match scene.payload(id) {
        Some(NodePayload::Mesh(_)) =>
          if scene.is_visible_in_world(id) {
            all.push(id)
          }
        _ => ()
      }
    })
    // Lines have no GPU cull path: reuse the CPU visibility test for them.
    for id in scene.collect_visible(frustum, (0xFFFFFFFF : UInt)) {
      match scene.payload(id) {
        Some(NodePayload::Lines(_)) => all.push(id)
        _ => ()
      }
    }
    all
  } else {
    scene.collect_visible(frustum, (0xFFFFFFFF : UInt))
  }
  let solid : Array[DrawItem] = []
  let transparent : Array[DrawItem] = []
  let transmissive : Array[DrawItem] = []
  let line_items : Array[(NodeId, LineInstance)] = []
  for id in visible {
    match scene.payload(id) {
      Some(NodePayload::Lines(inst)) => line_items.push((id, inst))
      Some(NodePayload::Mesh(inst)) => {
        let world = scene.world_transform(id)
        let dist = (world.translation - eye).length()
        let mut mi = inst.mesh.id()
        let mut level = 0
        for g in self.lods {
          if g.node == id {
            while level < g.switch_distances.length() &&
              dist > g.switch_distances[level] {
              level = level + 1
            }
            mi = g.levels[level].id()
            if level > 0 {
              self.stats.lod_switches = self.stats.lod_switches + 1
            }
          }
        }
        let mati = inst.material.id()
        if mi >= 0 &&
          mi < self.meshes.length() &&
          mati >= 0 &&
          mati < self.materials.length() {
          let mat = self.materials[mati]
          let item : DrawItem = {
            node: id,
            mesh: mi,
            material: mati,
            distance: dist,
            cast_shadow: inst.cast_shadow,
            transparent: is_blend_mode(mat.alpha_mode),
          }
          if item.transparent {
            transparent.push(item)
          } else if mat.transmission > 0.0 &&
            !self.meshes[mi].skinned() &&
            self.meshes[mi].morph() == 0 {
            // Screen-space transmission: static meshes only, drawn in the
            // second pass against the opaque color copy.
            transmissive.push(item)
          } else {
            solid.push(item)
          }
        }
      }
      _ => ()
    }
  }
  // Opaque objects are grouped by (mesh, material) so equal objects become one
  // instanced draw; depth testing makes front-to-back ordering optional.
  solid.sort_by(fn(a, b) {
    if a.mesh != b.mesh {
      a.mesh - b.mesh
    } else if a.material != b.material {
      a.material - b.material
    } else if a.distance < b.distance {
      -1
    } else if a.distance > b.distance {
      1
    } else {
      0
    }
  })
  transparent.sort_by(fn(a, b) {
    if a.distance > b.distance {
      -1
    } else if a.distance < b.distance {
      1
    } else {
      0
    }
  })
  // Transmissive objects sample a single opaque copy, so their relative order
  // does not affect the result; sort for deterministic draw order anyway.
  transmissive.sort_by(fn(a, b) {
    if a.distance > b.distance {
      -1
    } else if a.distance < b.distance {
      1
    } else {
      0
    }
  })
  // Object records: opaque batches, then transparent singles, then shadow-only
  // copies grouped per mesh. Shaders index this array as
  // `firstObject + gl_InstanceIndex`.
  self.object_writer.reset()
  let solid_batches : Array[DrawBatch] = []
  let mut records = 0
  for item in solid {
    self.pack_object(item, scene)
    let (mw0, mw1) = self.morph_weights_of(item.node)
    let n = solid_batches.length()
    if n > 0 &&
      solid_batches[n - 1].mesh == item.mesh &&
      solid_batches[n - 1].material == item.material &&
      self.meshes[item.mesh].morph() == 0 {
      solid_batches[n - 1].count = solid_batches[n - 1].count + 1
    } else {
      solid_batches.push({
        mesh: item.mesh,
        material: item.material,
        first: records,
        count: 1,
        cull_cmd: -1,
        list_offset: 0,
        skinned: self.meshes[item.mesh].skinned(),
        morph_w0: mw0,
        morph_w1: mw1,
      })
    }
    records = records + 1
  }
  let main_count = records
  // Transmissive batches reuse the same object records but are drawn in the
  // second pass, after the opaque color has been copied for refraction.
  let transmission_batches : Array[DrawBatch] = []
  for item in transmissive {
    self.pack_object(item, scene)
    let (mw0, mw1) = self.morph_weights_of(item.node)
    let n = transmission_batches.length()
    if n > 0 &&
      transmission_batches[n - 1].mesh == item.mesh &&
      transmission_batches[n - 1].material == item.material {
      transmission_batches[n - 1].count = transmission_batches[n - 1].count + 1
    } else {
      transmission_batches.push({
        mesh: item.mesh,
        material: item.material,
        first: records,
        count: 1,
        cull_cmd: -1,
        list_offset: 0,
        skinned: false,
        morph_w0: mw0,
        morph_w1: mw1,
      })
    }
    records = records + 1
  }
  let transparent_batches : Array[DrawBatch] = []
  for item in transparent {
    self.pack_object(item, scene)
    let (mw0, mw1) = self.morph_weights_of(item.node)
    transparent_batches.push({
      mesh: item.mesh,
      material: item.material,
      first: records,
      count: 1,
      cull_cmd: -1,
      list_offset: 0,
      skinned: self.meshes[item.mesh].skinned(),
      morph_w0: mw0,
      morph_w1: mw1,
    })
    records = records + 1
  }
  let casters : Array[DrawItem] = []
  for item in solid {
    if item.cast_shadow {
      casters.push(item)
    }
  }
  for item in transparent {
    if item.cast_shadow {
      casters.push(item)
    }
  }
  for item in transmissive {
    if item.cast_shadow {
      casters.push(item)
    }
  }
  casters.sort_by(fn(a, b) { a.mesh - b.mesh })
  let shadow_batches : Array[DrawBatch] = []
  for item in casters {
    self.pack_object(item, scene)
    let (mw0, mw1) = self.morph_weights_of(item.node)
    let n = shadow_batches.length()
    if n > 0 &&
      shadow_batches[n - 1].mesh == item.mesh &&
      self.meshes[item.mesh].morph() == 0 {
      shadow_batches[n - 1].count = shadow_batches[n - 1].count + 1
    } else {
      shadow_batches.push({
        mesh: item.mesh,
        material: -1,
        first: records,
        count: 1,
        cull_cmd: -1,
        list_offset: 0,
        skinned: self.meshes[item.mesh].skinned(),
        morph_w0: mw0,
        morph_w1: mw1,
      })
    }
    records = records + 1
  }
  let static_batches : Array[DrawBatch] = []
  let skin_batches : Array[DrawBatch] = []
  let morph_batches : Array[DrawBatch] = []
  for b in solid_batches {
    if b.skinned {
      skin_batches.push(b)
    } else if self.meshes[b.mesh].morph() > 0 {
      morph_batches.push(b)
    } else {
      static_batches.push(b)
    }
  }
  let mut cull_cmd_count = 0
  let mut cull_list_count = 0
  if gpu_cull_enabled {
    let mut total = 0
    for b in static_batches {
      total = total + b.count
    }
    // The visibility list is sized by max_objects; fall back to the CPU path
    // for the whole frame if the batch instances do not fit.
    if total > self.desc.max_objects {
      gpu_cull_enabled = false
    }
  }
  if gpu_cull_enabled {
    for i = 0; i < static_batches.length(); i = i + 1 {
      let b = static_batches[i]
      b.cull_cmd = i
      b.list_offset = cull_list_count
      cull_list_count = cull_list_count + b.count
      cull_cmd_count = cull_cmd_count + 1
    }
  }
  let object_count = records
  let mut caster_union : @tmath.Aabb3? = None
  for item in casters {
    if item.cast_shadow {
      match scene.world_bounds(item.node) {
        Some(b) =>
          caster_union = Some(
            match caster_union {
              Some(u) => u.union(b)
              None => b
            },
          )
        None => ()
      }
    }
  }
  let shadow_tiles = self.plan_shadows(light_nodes, caster_union)
  self.pack_shadow_tiles(shadow_tiles)
  let shadows_enabled = shadow_tiles.length() > 0
  let light_count = self.pack_lights(light_nodes, shadow_tiles)
  let light_vp0 = @tmath.Mat4::identity()
  let light_vp1 = @tmath.Mat4::identity()
  let cascade_split : Float = 1.0e9
  self.frame_writer.reset()
  self.frame_writer.push_mat4(vp)
  self.frame_writer.push_mat4(light_vp0)
  self.frame_writer.push_mat4(light_vp1)
  self.frame_writer.push_vec3_padded(eye)
  self.frame_writer.push_float(f_of_int(light_count))
  self.frame_writer.push_float(1.0 / f_of_int(self.desc.shadow_map_size))
  self.frame_writer.push_float(if shadows_enabled { 1.0 } else { 0.0 })
  self.frame_writer.push_float(self.env_intensity)
  self.frame_writer.push_float(cascade_split)
  self.frame_writer.push_float(f_of_int(shadow_tiles.length()))
  self.frame_writer.push_float(0.0)
  self.frame_writer.push_float(0.0)
  // Fog: `fogColor.w` is the mode (0 off, 1 linear, 2 exp2) and `fogParams`
  // carries (near, far, density, 0).
  match self.fog {
    Some(Fog::Linear(color, near, far)) => {
      self.frame_writer.push_vec4(
        @tmath.Vec4::new(color.x, color.y, color.z, 1.0),
      )
      self.frame_writer.push_vec4(@tmath.Vec4::new(near, far, 0.0, 0.0))
    }
    Some(Fog::Exp2(color, density)) => {
      self.frame_writer.push_vec4(
        @tmath.Vec4::new(color.x, color.y, color.z, 2.0),
      )
      self.frame_writer.push_vec4(@tmath.Vec4::new(0.0, 0.0, density, 0.0))
    }
    None => {
      self.frame_writer.push_vec4(@tmath.Vec4::zero())
      self.frame_writer.push_vec4(@tmath.Vec4::zero())
    }
  }
  self.frame_ubo.upload_floats(
    self.frame_writer.buffer(),
    offset=slot * FRAME_SLOT_BYTES,
    count=FRAME_FLOATS,
  )
  let sun = match shadow_dir {
    Some(d) => d
    None => self.env_sun
  }
  self.sky_writer.reset()
  let sky_m = match cam.sky_ray_matrix(cam_world) {
    Some(m) => m
    None => @tmath.Mat3::identity()
  }
  self.sky_writer.push_mat4(sky_m.to_mat4())
  self.sky_writer.push_vec4(
    @tmath.Vec4::new(sun.x, sun.y, sun.z, self.env_intensity),
  )
  self.sky_ubo.upload_floats(
    self.sky_writer.buffer(),
    offset=slot * SKY_SLOT_BYTES,
    count=SKY_FLOATS,
  )
  self.object_ring.begin_frame(slot)
  let object_offset = match self.object_ring.upload_floats(
    self.object_writer.buffer(),
    object_count * OBJECT_FLOATS,
  ) {
    Some(o) => o
    None => raise Render3DError::CapacityExceeded("Renderer3D: object ring capacity exhausted")
  }
  self.light_ring.begin_frame(slot)
  let light_offset = match self.light_ring.upload_floats(
    self.light_writer.buffer(),
    light_count * LIGHT_FLOATS,
  ) {
    Some(o) => o
    None => raise Render3DError::CapacityExceeded("Renderer3D: light ring capacity exhausted")
  }
  let mut upload_bytes = object_count * OBJECT_BYTES
  upload_bytes = upload_bytes + light_count * LIGHT_BYTES
  upload_bytes = upload_bytes + FRAME_BYTES + SKY_BYTES
  let line_verts = self.line_floats.length() / 6
  if line_verts > 0 {
    if line_verts > self.line_capacity {
      self.line_vbuf.destroy()
      self.line_capacity = line_verts * 2
      self.line_vbuf = self.dev.create_buffer_with(
        self.line_capacity * 24,
        @tycho.BufferKind::Vertex,
        location=@tycho.MemoryLocation::GpuOnly,
      )
    }
    self.line_vbuf.upload_floats(FixedArray::from_array(self.line_floats))
  }
  self.stats.upload_bytes = upload_bytes + line_verts * 24
  self.stats.visible_nodes = solid.length() + transparent.length()

  // Shadow pass.
  // Static batch cache: every solid batch is one indirect command over the
  // shared arenas. Culled batches start at instanceCount 0 and are filled by
  // the compute pass below; CPU-resolved batches are ready as-is.
  let batch_count = static_batches.length()
  if batch_count > 0 {
    let cmds = FixedArray::make(batch_count * 5, (0 : UInt))
    for i = 0; i < batch_count; i = i + 1 {
      let b = static_batches[i]
      let mesh = self.meshes[b.mesh]
      let culled = b.cull_cmd >= 0
      cmds[i * 5] = mesh.index_count().reinterpret_as_uint()
      cmds[i * 5 + 1] = if culled { 0 } else { b.count.reinterpret_as_uint() }
      cmds[i * 5 + 2] = mesh.first_index().reinterpret_as_uint()
      cmds[i * 5 + 3] = mesh.first_vertex().reinterpret_as_uint()
      cmds[i * 5 + 4] = (if culled {
        b.list_offset
      } else {
        b.first
      }).reinterpret_as_uint()
    }
    self.cull_cmds[slot & 1].upload_uint32(cmds)
    self.draw_count.upload_uint32(
      FixedArray::make(1, batch_count.reinterpret_as_uint()),
    )
  }
  if gpu_cull_enabled && cull_cmd_count > 0 {
    match self.cull_pipe {
      Some(pipe) => {
        cmd.bind_pipeline(pipe)
        cmd.bind_storage(
          pipe,
          0,
          self.object_ring.buffer(),
          offset=object_offset,
          size=bind_objects_bytes(object_count),
        )
        cmd.bind_storage(
          pipe,
          1,
          self.cull_vis[slot & 1],
          offset=0,
          size=self.desc.max_objects * 4,
        )
        cmd.bind_storage(
          pipe,
          2,
          self.cull_cmds[slot & 1],
          offset=0,
          size=self.desc.max_objects * 20,
        )
        for b in static_batches {
          if b.cull_cmd >= 0 {
            cmd.push_constants_floats(
              pipe,
              cull_pc_floats(frustum, b.first, b.count, b.list_offset, b.cull_cmd),
            )
            cmd.dispatch((b.count + 63) / 64, 1, 1)
          }
        }
        cmd.barrier()
      }
      None => ()
    }
  }

  let shadow_static : Array[DrawBatch] = []
  let shadow_skinned : Array[DrawBatch] = []
  let shadow_morph : Array[DrawBatch] = []
  for b in shadow_batches {
    if b.skinned {
      shadow_skinned.push(b)
    } else if self.meshes[b.mesh].morph() > 0 {
      shadow_morph.push(b)
    } else {
      shadow_static.push(b)
    }
  }

  // Single atlas pass: clear once, then each shadow light renders its casters
  // into its own tile through viewport/scissor.
  cmd.render_pass(
    [],
    depth=
      @tycho.DepthTargetDesc::new(
        self.shadow_atlas,
        load_op=@tycho.LoadOp::Clear,
        store_op=@tycho.StoreOp::Store,
        clear_depth=1.0,
      )
    ,
  fn(pass) {
    let tile_size = self.desc.shadow_map_size
    for st in shadow_tiles {
      let tx = (st.tile % 4) * tile_size
      let ty = (st.tile / 4) * tile_size
      pass.set_viewport(
        f_of_int(tx),
        f_of_int(ty),
        f_of_int(tile_size),
        f_of_int(tile_size),
      )
      pass.set_scissor(tx, ty, tile_size, tile_size)
      if shadow_static.length() > 0 {
        pass.bind_pipeline(self.shadow_pipe)
        pass.bind_uniform(
          self.shadow_pipe,
          0,
          self.frame_ubo,
          offset=slot * FRAME_SLOT_BYTES,
          size=FRAME_BYTES,
        )
        pass.bind_storage(
          self.shadow_pipe,
          0,
          self.object_ring.buffer(),
          offset=object_offset,
          size=bind_objects_bytes(object_count),
        )
        self.bind_arenas(cmd)
        pass.push_constants_floats(self.shadow_pipe, shadow_pc_floats(st.vp))
        for b in shadow_static {
          let mesh = self.meshes[b.mesh]
          pass.draw_indexed_full(
            mesh.index_count(),
            b.count,
            mesh.first_index(),
            mesh.first_vertex(),
            b.first,
          )
          self.stats.shadow_passes = self.stats.shadow_passes + 1
        }
      }
      if shadow_skinned.length() > 0 && self.bone_cursor > 0 {
        pass.bind_pipeline(self.shadow_skin_pipe)
        pass.bind_uniform(
          self.shadow_skin_pipe,
          0,
          self.frame_ubo,
          offset=slot * FRAME_SLOT_BYTES,
          size=FRAME_BYTES,
        )
        pass.bind_storage(
          self.shadow_skin_pipe,
          0,
          self.object_ring.buffer(),
          offset=object_offset,
          size=bind_objects_bytes(object_count),
        )
        pass.bind_storage(
          self.shadow_skin_pipe,
          1,
          self.bone_ssbo,
          offset=0,
          size=bind_bones_bytes(self.bone_cursor),
        )
        self.bind_skin_arenas(cmd)
        pass.push_constants_floats(self.shadow_skin_pipe, shadow_pc_floats(st.vp))
        for b in shadow_skinned {
          let mesh = self.meshes[b.mesh]
          pass.draw_indexed_full(
            mesh.index_count(),
            b.count,
            mesh.first_index(),
            mesh.first_vertex(),
            b.first,
          )
          self.stats.shadow_passes = self.stats.shadow_passes + 1
        }
      }
      if shadow_morph.length() > 0 {
        pass.bind_pipeline(self.morph_shadow_pipe)
        pass.bind_uniform(
          self.morph_shadow_pipe,
          0,
          self.frame_ubo,
          offset=slot * FRAME_SLOT_BYTES,
          size=FRAME_BYTES,
        )
        pass.bind_storage(
          self.morph_shadow_pipe,
          0,
          self.object_ring.buffer(),
          offset=object_offset,
          size=bind_objects_bytes(object_count),
        )
        self.bind_morph_arenas(cmd)
        for b in shadow_morph {
          pass.push_constants_floats(self.morph_shadow_pipe, shadow_morph_pc(st.vp, b.morph_w0, b.morph_w1))
          let mesh = self.meshes[b.mesh]
          pass.draw_indexed_full(
            mesh.index_count(),
            b.count,
            mesh.first_index(),
            mesh.first_vertex(),
            b.first,
          )
          self.stats.shadow_passes = self.stats.shadow_passes + 1
        }
      }
    }
  
  },
)

  // Main HDR pass.
  let resolved = match targets.hdr_resolve {
    Some(t) => t
    None => targets.hdr
  }
  cmd.render_pass(
    [
      @tycho.RenderTargetDesc::new(
        targets.hdr,
        load_op=@tycho.LoadOp::Clear,
        // The transmission pass loads this attachment, so an MSAA target must
        // be stored (not just resolved) when that pass will run.
        store_op=if targets.hdr_resolve is Some(_) &&
          transmission_batches.length() == 0 {
          @tycho.StoreOp::DontCare
        } else {
          @tycho.StoreOp::Store
        },
        clear_color=match self.background {
          Some(c) => @tycho.ClearColor::rgba(c.x, c.y, c.z, c.w)
          None => @tycho.ClearColor::black()
        },
        resolve_texture?=targets.hdr_resolve,
      ),
    ],
    depth=
      @tycho.DepthTargetDesc::new(
        targets.depth,
        load_op=@tycho.LoadOp::Clear,
        // The transmission pass re-tests against the opaque depth buffer.
        store_op=if transmission_batches.length() > 0 {
          @tycho.StoreOp::Store
        } else {
          @tycho.StoreOp::DontCare
        },
        clear_depth=0.0,
      )
    ,
  fn(pass) {
    pass.set_viewport(0.0, 0.0, f_of_int(w), f_of_int(h))
    pass.set_scissor(0, 0, w, h)
    // A flat background replaces the sky draw; the environment cubemap stays
    // bound for IBL, so lighting is unchanged.
    if self.background is None {
      pass.bind_pipeline(self.sky_pipe)
      pass.bind_uniform(
        self.sky_pipe,
        0,
        self.sky_ubo,
        offset=slot * SKY_SLOT_BYTES,
        size=SKY_BYTES,
      )
      pass.bind_texture(self.sky_pipe, 0, self.env_cube, self.env_sampler)
      pass.draw(3, 1)
    }
    if main_count > 0 {
      self.bind_arenas(cmd)
      let culling = cull_cmd_count > 0
      let use_rt = self.rt_enabled && self.rt_tlas is Some(_)
      let mut pipe_is_rt = false
      let pipe = if culling {
        match (if use_rt { self.rt_cull_pipe } else { None }) {
          Some(p) => {
            pipe_is_rt = true
            p
          }
          None => match self.pbr_cull_pipe {
            Some(p) => p
            None => self.pbr_pipe
          }
        }
      } else if use_rt {
        match self.rt_pipe {
          Some(p) => {
            pipe_is_rt = true
            p
          }
          None => self.pbr_pipe
        }
      } else {
        self.pbr_pipe
      }
      pass.bind_pipeline(pipe)
      if pipe_is_rt {
        match self.rt_tlas {
          Some(t) => pass.bind_accel_struct(pipe, 0, t)
          None => ()
        }
      }
      self.bind_material_heap(cmd, pipe)
      pass.bind_uniform(
        pipe,
        0,
        self.frame_ubo,
        offset=slot * FRAME_SLOT_BYTES,
        size=FRAME_BYTES,
      )
      pass.bind_storage(
        pipe,
        0,
        self.object_ring.buffer(),
        offset=object_offset,
        size=bind_objects_bytes(object_count),
      )
      pass.bind_storage(
        pipe,
        1,
        self.material_ssbo,
        offset=0,
        size=self.desc.max_materials * MATERIAL_BYTES,
      )
      pass.bind_storage(
        pipe,
        2,
        self.light_ring.buffer(),
        offset=light_offset,
        size=bind_lights_bytes(light_count),
      )
      pass.bind_storage(
        pipe,
        if culling { 4 } else { 3 },
        self.shadow_tiles_ssbo,
        offset=0,
        size=bind_shadow_tiles_bytes(shadow_tiles.length()),
      )
      if culling {
        pass.bind_storage(
          pipe,
          3,
          self.cull_vis[slot & 1],
          offset=0,
          size=self.desc.max_objects * 4,
        )
      }
      pass.bind_texture(pipe, 0, self.shadow_atlas, self.shadow_sampler)
      pass.bind_texture(pipe, 1, self.shadow_atlas, self.shadow_sampler)
      pass.bind_texture(pipe, 2, self.env_cube, self.env_sampler)
      pass.bind_texture(pipe, 3, self.brdf_lut, self.linear_sampler)
      if batch_count > 0 {
        if self.bindless_ok {
          pass.draw_indexed_indirect_count(
            self.cull_cmds[slot & 1],
            self.draw_count,
            batch_count,
          )
          self.stats.draw_calls = self.stats.draw_calls + 1
        } else {
          // The fallback binds albedo/normal per material, which a single
          // multi-draw cannot express, so it keeps one draw per batch.
          for b in static_batches {
            self.bind_material_textures(cmd, pipe, b.material)
            let mesh = self.meshes[b.mesh]
            pass.draw_indexed_full(
              mesh.index_count(),
              b.count,
              mesh.first_index(),
              mesh.first_vertex(),
              b.first,
            )
            self.stats.draw_calls = self.stats.draw_calls + 1
          }
        }
      }
      if skin_batches.length() > 0 && self.bone_cursor > 0 {
        self.bind_skin_arenas(cmd)
        pass.bind_pipeline(self.skin_pipe)
        self.bind_material_heap(cmd, self.skin_pipe)
        pass.bind_uniform(
          self.skin_pipe,
          0,
          self.frame_ubo,
          offset=slot * FRAME_SLOT_BYTES,
          size=FRAME_BYTES,
        )
        pass.bind_storage(
          self.skin_pipe,
          0,
          self.object_ring.buffer(),
          offset=object_offset,
          size=bind_objects_bytes(object_count),
        )
        pass.bind_storage(
          self.skin_pipe,
          1,
          self.material_ssbo,
          offset=0,
          size=self.desc.max_materials * MATERIAL_BYTES,
        )
        pass.bind_storage(
          self.skin_pipe,
          2,
          self.light_ring.buffer(),
          offset=light_offset,
          size=bind_lights_bytes(light_count),
        )
        pass.bind_storage(
          self.skin_pipe,
          3,
          self.bone_ssbo,
          offset=0,
          size=bind_bones_bytes(self.bone_cursor),
        )
        pass.bind_storage(
          self.skin_pipe,
          4,
          self.shadow_tiles_ssbo,
          offset=0,
          size=bind_shadow_tiles_bytes(shadow_tiles.length()),
        )
        pass.bind_texture(self.skin_pipe, 0, self.shadow_atlas, self.shadow_sampler)
        pass.bind_texture(self.skin_pipe, 1, self.shadow_atlas, self.shadow_sampler)
        pass.bind_texture(self.skin_pipe, 2, self.env_cube, self.env_sampler)
        pass.bind_texture(self.skin_pipe, 3, self.brdf_lut, self.linear_sampler)
        for b in skin_batches {
          self.bind_material_textures(cmd, self.skin_pipe, b.material)
          let mesh = self.meshes[b.mesh]
          pass.draw_indexed_full(
            mesh.index_count(),
            b.count,
            mesh.first_index(),
            mesh.first_vertex(),
            b.first,
          )
          self.stats.draw_calls = self.stats.draw_calls + 1
        }
        self.bind_arenas(cmd)
      }
      if morph_batches.length() > 0 {
        self.bind_morph_arenas(cmd)
        pass.bind_pipeline(self.morph_pipe)
        self.bind_material_heap(cmd, self.morph_pipe)
        pass.bind_uniform(
          self.morph_pipe,
          0,
          self.frame_ubo,
          offset=slot * FRAME_SLOT_BYTES,
          size=FRAME_BYTES,
        )
        pass.bind_storage(
          self.morph_pipe,
          0,
          self.object_ring.buffer(),
          offset=object_offset,
          size=bind_objects_bytes(object_count),
        )
        pass.bind_storage(
          self.morph_pipe,
          1,
          self.material_ssbo,
          offset=0,
          size=self.desc.max_materials * MATERIAL_BYTES,
        )
        pass.bind_storage(
          self.morph_pipe,
          2,
          self.light_ring.buffer(),
          offset=light_offset,
          size=bind_lights_bytes(light_count),
        )
        pass.bind_storage(
          self.morph_pipe,
          3,
          self.shadow_tiles_ssbo,
          offset=0,
          size=bind_shadow_tiles_bytes(shadow_tiles.length()),
        )
        pass.bind_texture(self.morph_pipe, 0, self.shadow_atlas, self.shadow_sampler)
        pass.bind_texture(self.morph_pipe, 1, self.shadow_atlas, self.shadow_sampler)
        pass.bind_texture(self.morph_pipe, 2, self.env_cube, self.env_sampler)
        pass.bind_texture(self.morph_pipe, 3, self.brdf_lut, self.linear_sampler)
        for b in morph_batches {
          self.bind_material_textures(cmd, self.morph_pipe, b.material)
          pass.push_constants_floats(self.morph_pipe, [
            b.morph_w0,
            b.morph_w1,
            (0.0 : Float),
            (0.0 : Float),
          ])
          let mesh = self.meshes[b.mesh]
          pass.draw_indexed_full(
            mesh.index_count(),
            b.count,
            mesh.first_index(),
            mesh.first_vertex(),
            b.first,
          )
          self.stats.draw_calls = self.stats.draw_calls + 1
        }
        self.bind_arenas(cmd)
      }
      for b in solid_batches {
        let mesh = self.meshes[b.mesh]
        self.stats.triangles = self.stats.triangles + mesh.index_count() / 3 * b.count
        if b.count > 1 {
          self.stats.instance_batches = self.stats.instance_batches + 1
        }
      }
      if transparent.length() > 0 {
        pass.bind_pipeline(self.pbr_blend_pipe)
        self.bind_material_heap(cmd, self.pbr_blend_pipe)
        pass.bind_uniform(
          self.pbr_blend_pipe,
          0,
          self.frame_ubo,
          offset=slot * FRAME_SLOT_BYTES,
          size=FRAME_BYTES,
        )
        pass.bind_storage(
          self.pbr_blend_pipe,
          0,
          self.object_ring.buffer(),
          offset=object_offset,
          size=bind_objects_bytes(object_count),
        )
        pass.bind_storage(
          self.pbr_blend_pipe,
          1,
          self.material_ssbo,
          offset=0,
          size=self.desc.max_materials * MATERIAL_BYTES,
        )
        pass.bind_storage(
          self.pbr_blend_pipe,
          2,
          self.light_ring.buffer(),
          offset=light_offset,
          size=bind_lights_bytes(light_count),
        )
        pass.bind_storage(
          self.pbr_blend_pipe,
          3,
          self.shadow_tiles_ssbo,
          offset=0,
          size=bind_shadow_tiles_bytes(shadow_tiles.length()),
        )
        pass.bind_texture(self.pbr_blend_pipe, 0, self.shadow_atlas, self.shadow_sampler)
        pass.bind_texture(self.pbr_blend_pipe, 1, self.shadow_atlas, self.shadow_sampler)
        pass.bind_texture(self.pbr_blend_pipe, 2, self.env_cube, self.env_sampler)
        pass.bind_texture(self.pbr_blend_pipe, 3, self.brdf_lut, self.linear_sampler)
        for b in transparent_batches {
          self.bind_material_textures(cmd, self.pbr_blend_pipe, b.material)
          let mesh = self.meshes[b.mesh]
          pass.draw_indexed_full(
            mesh.index_count(),
            b.count,
            mesh.first_index(),
            mesh.first_vertex(),
            b.first,
          )
          self.stats.draw_calls = self.stats.draw_calls + 1
          self.stats.triangles = self.stats.triangles + mesh.index_count() / 3 * b.count
        }
      }
    }
    if line_verts > 0 || line_items.length() > 0 {
      pass.bind_pipeline(self.line_pipe)
      pass.bind_uniform(
        self.line_pipe,
        0,
        self.frame_ubo,
        offset=slot * FRAME_SLOT_BYTES,
        size=FRAME_BYTES,
      )
      if line_verts > 0 {
        // Debug segments are already in world space.
        pass.push_constants_floats(
          self.line_pipe,
          line_push_constants(@tmath.Mat4::identity().to_cols_array(), @tmath.Vec3::one()),
        )
        pass.bind_vertex(0, self.line_vbuf)
        pass.draw(line_verts, 1)
        self.stats.draw_calls = self.stats.draw_calls + 1
        self.stats.line_segments = self.stats.line_segments + line_verts / 2
      }
      // Line scene nodes: per-node model matrix plus material tint.
      for item in line_items {
        let (node, inst) = item
        let li = inst.lines.id()
        if li >= 0 && li < self.line_sets.length() {
          let set = self.line_sets[li]
          if set.vertex_count > 0 {
            pass.push_constants_floats(
              self.line_pipe,
              line_push_constants(
                scene.world_transform(node).to_mat4_array(),
                inst.material.color,
              ),
            )
            pass.bind_vertex(0, set.buffer)
            pass.draw(set.vertex_count, 1)
            self.stats.draw_calls = self.stats.draw_calls + 1
            self.stats.line_segments = self.stats.line_segments + set.segment_count
          }
        }
      }
    }
    self.line_floats.clear()
  
  },
)

  // Transmission pass: the opaque color was copied out, so this pass can
  // sample it while drawing the transmissive meshes into the same HDR target.
  if transmission_batches.length() > 0 {
    cmd.blit_texture(resolved, targets.scene_copy, filter=@tycho.Filter::Nearest)
    cmd.render_pass(
      [
        @tycho.RenderTargetDesc::new(
          targets.hdr,
          load_op=@tycho.LoadOp::Load,
          store_op=if targets.hdr_resolve is Some(_) {
            @tycho.StoreOp::DontCare
          } else {
            @tycho.StoreOp::Store
          },
          resolve_texture?=targets.hdr_resolve,
        ),
      ],
      depth=@tycho.DepthTargetDesc::new(
        targets.depth,
        load_op=@tycho.LoadOp::Load,
        store_op=@tycho.StoreOp::DontCare,
        clear_depth=0.0,
      ),
      fn(pass) {
        pass.set_viewport(0.0, 0.0, f_of_int(w), f_of_int(h))
        pass.set_scissor(0, 0, w, h)
        pass.bind_pipeline(self.pbr_transmission_pipe)
        self.bind_material_heap(cmd, self.pbr_transmission_pipe)
        pass.bind_uniform(
          self.pbr_transmission_pipe,
          0,
          self.frame_ubo,
          offset=slot * FRAME_SLOT_BYTES,
          size=FRAME_BYTES,
        )
        pass.bind_storage(
          self.pbr_transmission_pipe,
          0,
          self.object_ring.buffer(),
          offset=object_offset,
          size=bind_objects_bytes(object_count),
        )
        pass.bind_storage(
          self.pbr_transmission_pipe,
          1,
          self.material_ssbo,
          offset=0,
          size=self.desc.max_materials * MATERIAL_BYTES,
        )
        pass.bind_storage(
          self.pbr_transmission_pipe,
          2,
          self.light_ring.buffer(),
          offset=light_offset,
          size=bind_lights_bytes(light_count),
        )
        pass.bind_storage(
          self.pbr_transmission_pipe,
          3,
          self.shadow_tiles_ssbo,
          offset=0,
          size=bind_shadow_tiles_bytes(shadow_tiles.length()),
        )
        pass.bind_texture(
          self.pbr_transmission_pipe,
          0,
          self.shadow_atlas,
          self.shadow_sampler,
        )
        pass.bind_texture(
          self.pbr_transmission_pipe,
          1,
          self.shadow_atlas,
          self.shadow_sampler,
        )
        pass.bind_texture(
          self.pbr_transmission_pipe,
          2,
          self.env_cube,
          self.env_sampler,
        )
        pass.bind_texture(
          self.pbr_transmission_pipe,
          3,
          self.brdf_lut,
          self.linear_sampler,
        )
        // `uSceneColor` is declared at binding 10, after the bindless set (5
        // textures) or after albedo/normal (7) in the fallback variant.
        pass.bind_texture(
          self.pbr_transmission_pipe,
          if self.bindless_ok { 4 } else { 6 },
          targets.scene_copy,
          self.linear_sampler,
        )
        self.bind_arenas(cmd)
        for b in transmission_batches {
          self.bind_material_textures(cmd, self.pbr_transmission_pipe, b.material)
          let mesh = self.meshes[b.mesh]
          pass.draw_indexed_full(
            mesh.index_count(),
            b.count,
            mesh.first_index(),
            mesh.first_vertex(),
            b.first,
          )
          self.stats.draw_calls = self.stats.draw_calls + 1
          self.stats.triangles = self.stats.triangles + mesh.index_count() / 3 * b.count
        }
      },
    )
  }

  // SSAO: reconstruct positions from depth, accumulate hemisphere occlusion,
  // then box-blur the noisy result. Runs before bloom so the bloom source stays
  // untouched; the tonemap pass multiplies the blurred AO into the image.
  let mut ao_texture : @tycho.Texture? = None
  if self.ssao {
    match (targets.ao_a, targets.ao_b) {
      (Some(ssao_rt), Some(blur_rt)) => {
        let inv_vp = match @tmath.invert_view_proj(vp) {
          Some(m) => m
          None => @tmath.Mat4::identity()
        }
        self.ssao_writer.reset()
        self.ssao_writer.push_mat4(vp)
        self.ssao_writer.push_mat4(inv_vp)
        self.ssao_writer.push_vec3_padded(eye)
        self.ssao_writer.push_float(self.ssao_radius)
        self.ssao_writer.push_float(self.ssao_intensity)
        self.ssao_writer.push_float(self.ssao_bias)
        self.ssao_writer.push_float(0.0)
        self.ssao_ubo.upload_floats(self.ssao_writer.buffer(), count=SSAO_FLOATS)
        // The depth attachment is still in DEPTH_STENCIL_ATTACHMENT layout
        // after the scene pass; move it to a sampled layout before the AO
        // shader reads it.
        cmd.transition_for_sampling(targets.depth)
        cmd.render_pass(
          [
            @tycho.RenderTargetDesc::new(
              ssao_rt,
              load_op=@tycho.LoadOp::Clear,
              store_op=@tycho.StoreOp::Store,
              clear_color=@tycho.ClearColor::rgba(1.0, 1.0, 1.0, 1.0),
            ),
          ],
          fn(pass) {
            pass.set_viewport(0.0, 0.0, f_of_int(w), f_of_int(h))
            pass.set_scissor(0, 0, w, h)
            pass.bind_pipeline(self.ssao_pipe)
            pass.bind_uniform(
              self.ssao_pipe,
              0,
              self.ssao_ubo,
              offset=0,
              size=SSAO_BYTES,
            )
            pass.bind_texture(
              self.ssao_pipe,
              0,
              targets.depth,
              self.depth_sampler,
            )
            pass.draw(3, 1)
          },
        )
        cmd.render_pass(
          [
            @tycho.RenderTargetDesc::new(
              blur_rt,
              load_op=@tycho.LoadOp::Clear,
              store_op=@tycho.StoreOp::Store,
              clear_color=@tycho.ClearColor::rgba(1.0, 1.0, 1.0, 1.0),
            ),
          ],
          fn(pass) {
            pass.set_viewport(0.0, 0.0, f_of_int(w), f_of_int(h))
            pass.set_scissor(0, 0, w, h)
            pass.bind_pipeline(self.ssao_blur_pipe)
            pass.bind_texture(
              self.ssao_blur_pipe,
              0,
              ssao_rt,
              self.linear_sampler,
            )
            pass.push_constants_floats(
              self.ssao_blur_pipe,
              [
                1.0 / f_of_int(w),
                1.0 / f_of_int(h),
                0.0,
                0.0,
              ],
            )
            pass.draw(3, 1)
          },
        )
        ao_texture = Some(blur_rt)
      }
      _ => ()
    }
  }

  // Bloom chain.
  let mut bloom_result = resolved
  if self.desc.bloom {
    let bw = targets.bloom_a.width()
    let bh = targets.bloom_a.height()
    cmd.render_pass(
      [
        @tycho.RenderTargetDesc::new(
          targets.bloom_a,
          load_op=@tycho.LoadOp::Clear,
          store_op=@tycho.StoreOp::Store,
          clear_color=@tycho.ClearColor::black(),
        ),
      ],
  fn(pass) {
      pass.set_viewport(0.0, 0.0, f_of_int(bw), f_of_int(bh))
      pass.set_scissor(0, 0, bw, bh)
      pass.bind_pipeline(self.bloom_extract_pipe)
      pass.bind_texture(self.bloom_extract_pipe, 0, resolved, self.linear_sampler)
      pass.draw(3, 1)
    
  },
)
    cmd.render_pass(
      [
        @tycho.RenderTargetDesc::new(
          targets.bloom_b,
          load_op=@tycho.LoadOp::Clear,
          store_op=@tycho.StoreOp::Store,
          clear_color=@tycho.ClearColor::black(),
        ),
      ],
  fn(pass) {
      pass.set_viewport(0.0, 0.0, f_of_int(bw), f_of_int(bh))
      pass.set_scissor(0, 0, bw, bh)
      pass.bind_pipeline(self.bloom_blur_pipe)
      pass.bind_texture(self.bloom_blur_pipe, 0, targets.bloom_a, self.linear_sampler)
      pass.push_constants_floats(
        self.bloom_blur_pipe,
        [1.0 / f_of_int(bw), (0.0 : Float), (0.0 : Float), (0.0 : Float)],
      )
      pass.draw(3, 1)
    
  },
)
    cmd.render_pass(
      [
        @tycho.RenderTargetDesc::new(
          targets.bloom_a,
          load_op=@tycho.LoadOp::Clear,
          store_op=@tycho.StoreOp::Store,
          clear_color=@tycho.ClearColor::black(),
        ),
      ],
  fn(pass) {
      pass.set_viewport(0.0, 0.0, f_of_int(bw), f_of_int(bh))
      pass.set_scissor(0, 0, bw, bh)
      pass.bind_pipeline(self.bloom_blur_pipe)
      pass.bind_texture(self.bloom_blur_pipe, 0, targets.bloom_b, self.linear_sampler)
      pass.push_constants_floats(
        self.bloom_blur_pipe,
        [(0.0 : Float), 1.0 / f_of_int(bh), (0.0 : Float), (0.0 : Float)],
      )
      pass.draw(3, 1)
    
  },
)
    bloom_result = targets.bloom_a
  }

  // Tonemap into the caller's target.
  let tm_pipe = match final_format {
    @tycho.TextureFormat::RGBA8Srgb => self.tonemap_srgb_pipe
    @tycho.TextureFormat::RGBA8 => self.tonemap_linear_pipe
    _ => {
      raise Render3DError::Unsupported("Renderer3D: unsupported dst target format")
      self.tonemap_linear_pipe
    }
  }
  cmd.render_pass(
    [
      @tycho.RenderTargetDesc::new(
        dst,
        load_op=@tycho.LoadOp::Clear,
        store_op=@tycho.StoreOp::Store,
        clear_color=@tycho.ClearColor::black(),
      ),
    ],
  fn(pass) {
    pass.set_viewport(0.0, 0.0, f_of_int(w), f_of_int(h))
    pass.set_scissor(0, 0, w, h)
    pass.bind_pipeline(tm_pipe)
    pass.bind_texture(tm_pipe, 0, resolved, self.linear_sampler)
    pass.bind_texture(tm_pipe, 1, bloom_result, self.linear_sampler)
    // 1x1 white when SSAO is off, so the shader path stays identical.
    let ao_bind = match ao_texture {
      Some(t) => t
      None => self.white_tex
    }
    pass.bind_texture(tm_pipe, 2, ao_bind, self.linear_sampler)
    pass.draw(3, 1)
  
  },
)
  self.stats.draw_calls = self.stats.draw_calls + 4 + (if self.ssao { 2 } else { 0 })
}

///|
pub fn Renderer3D::render_swapchain(
  self : Renderer3D,
  sc : @tycho.Swapchain,
  scene : Scene,
  camera : CameraId,
) -> Unit raise {
  let cmd = sc.begin_frame_commands()
  self.render_swapchain_into(cmd, sc, scene, camera)
  sc.end_frame(cmd)
}

///|
/// Render into the already-acquired swapchain image without ending the frame,
/// so an overlay (e.g. `Renderer2D::render_swapchain_pass`) can draw on top
/// before the caller presents with `Swapchain::end_frame`.
pub fn Renderer3D::render_swapchain_into(
  self : Renderer3D,
  cmd : @tycho.CommandBuffer,
  sc : @tycho.Swapchain,
  scene : Scene,
  camera : CameraId,
) -> Unit raise {
  let w = sc.width()
  let h = sc.height()
  let slot = cmd.frame_slot()
  let out = self.ensure_present(w, h)
  self.render_frame(cmd, scene, camera.node(), w, h, out, @tycho.TextureFormat::RGBA8Srgb, slot)
  cmd.blit_to_swapchain(out, sc)
}

///|
pub fn Renderer3D::render_offscreen(
  self : Renderer3D,
  target : @tycho.Texture,
  scene : Scene,
  camera : CameraId,
) -> Unit raise {
  let cmd = self.dev.begin_commands()
  let slot = cmd.frame_slot()
  self.render_frame(
    cmd,
    scene,
    camera.node(),
    target.width(),
    target.height(),
    target,
    target.format(),
    slot,
  )
  self.dev.end_commands(cmd)
}

///|
/// Queue a world-space debug line for the next render call. Lines are
/// depth-tested against the scene and cleared after each frame.
pub fn Renderer3D::add_debug_line(
  self : Renderer3D,
  a : @tmath.Vec3,
  b : @tmath.Vec3,
  color : @tmath.Vec3,
) -> Unit {
  for p in [a, b] {
    self.line_floats.push(p.x)
    self.line_floats.push(p.y)
    self.line_floats.push(p.z)
    self.line_floats.push(color.x)
    self.line_floats.push(color.y)
    self.line_floats.push(color.z)
  }
}

///|
/// Queue the 12 edges of a world-space AABB.
pub fn Renderer3D::add_debug_aabb(
  self : Renderer3D,
  box : @tmath.Aabb3,
  color : @tmath.Vec3,
) -> Unit {
  let mn = box.min
  let mx = box.max
  let corners : Array[@tmath.Vec3] = [
    @tmath.Vec3::new(mn.x, mn.y, mn.z),
    @tmath.Vec3::new(mx.x, mn.y, mn.z),
    @tmath.Vec3::new(mx.x, mx.y, mn.z),
    @tmath.Vec3::new(mn.x, mx.y, mn.z),
    @tmath.Vec3::new(mn.x, mn.y, mx.z),
    @tmath.Vec3::new(mx.x, mn.y, mx.z),
    @tmath.Vec3::new(mx.x, mx.y, mx.z),
    @tmath.Vec3::new(mn.x, mx.y, mx.z),
  ]
  let edges : Array[(Int, Int)] = [
    (0, 1), (1, 2), (2, 3), (3, 0),
    (4, 5), (5, 6), (6, 7), (7, 4),
    (0, 4), (1, 5), (2, 6), (3, 7),
  ]
  for e in edges {
    self.add_debug_line(corners[e.0], corners[e.1], color)
  }
}

///|
pub fn Renderer3D::clear_debug_lines(self : Renderer3D) -> Unit {
  self.line_floats.clear()
}

///|
/// The baked split-sum BRDF LUT (RG16F), exposed for diagnostics and tests.
pub fn Renderer3D::brdf_lut(self : Renderer3D) -> @tycho.Texture {
  self.brdf_lut
}

///|
pub fn Renderer3D::stats(self : Renderer3D) -> RenderStats3D {
  self.stats
}

///|
pub fn Renderer3D::destroy(self : Renderer3D) -> Unit {
  self.vertex_arena.destroy()
  self.index_arena.destroy()
  self.skin_arena.destroy()
  self.morph_arena.destroy()
  self.draw_count.destroy()
  self.bone_ssbo.destroy()
  self.shadow_tiles_ssbo.destroy()
  match self.targets {
    Some(t) => Renderer3D::destroy_targets(t)
    None => ()
  }
  match self.present {
    Some(t) => t.destroy()
    None => ()
  }
  if self.owns_env {
    self.env_cube.destroy()
  }
  self.brdf_lut.destroy()
  for t in self.textures {
    t.tex.destroy()
  }
  match self.bindless {
    Some(h) => h.destroy()
    None => ()
  }
  self.white_tex.destroy()
  self.flat_normal_tex.destroy()
  self.material_sampler.destroy()
  self.shadow_atlas.destroy()
  self.material_ssbo.destroy()
  self.sky_ubo.destroy()
  self.frame_ubo.destroy()
  self.light_ring.destroy()
  self.object_ring.destroy()
  for b in self.cull_vis {
    b.destroy()
  }
  for b in self.cull_cmds {
    b.destroy()
  }
  match self.cull_pipe {
    Some(p) => p.destroy()
    None => ()
  }
  match self.pbr_cull_pipe {
    Some(p) => p.destroy()
    None => ()
  }
  self.line_pipe.destroy()
  self.line_vbuf.destroy()
  for set in self.line_sets {
    set.buffer.destroy()
  }
  self.tonemap_linear_pipe.destroy()
  self.tonemap_srgb_pipe.destroy()
  self.ssao_pipe.destroy()
  self.ssao_blur_pipe.destroy()
  self.ssao_ubo.destroy()
  self.depth_sampler.destroy()
  self.bloom_blur_pipe.destroy()
  self.bloom_extract_pipe.destroy()
  self.sky_pipe.destroy()
  self.pbr_blend_pipe.destroy()
  self.pbr_transmission_pipe.destroy()
  self.pbr_pipe.destroy()
  self.skin_pipe.destroy()
  self.skin_blend_pipe.destroy()
  self.shadow_skin_pipe.destroy()
  self.morph_pipe.destroy()
  self.morph_shadow_pipe.destroy()
  match self.rt_pipe {
    Some(p) => p.destroy()
    None => ()
  }
  match self.rt_cull_pipe {
    Some(p) => p.destroy()
    None => ()
  }
  match self.rt_tlas {
    Some(t) => t.destroy()
    None => ()
  }
  for m in self.rt_meshes {
    match m {
      Some(rm) => {
        rm.blas.destroy()
        rm.vbuf.destroy()
        rm.ibuf.destroy()
      }
      None => ()
    }
  }
  self.shadow_pipe.destroy()
  self.linear_sampler.destroy()
  self.env_sampler.destroy()
  self.shadow_sampler.destroy()
}

///|
/// Set the two GPU morph weights for a node. The mesh must carry morph targets
/// (see `MeshData::add_morph_target`); at most two are evaluated.
pub fn Renderer3D::set_morph_weights(
  self : Renderer3D,
  node : NodeId,
  weights : Array[Float],
) -> Unit raise {
  if weights.length() > MORPH_TARGETS_MAX {
    raise Render3DError::Unsupported("Renderer3D::set_morph_weights: at most two targets are supported")
  }
  for i = 0; i < self.morph_weights.length(); i = i + 1 {
    if self.morph_weights[i].0.index() == node.index() {
      self.morph_weights[i] = (node, weights)
      return
    }
  }
  self.morph_weights.push((node, weights))
}

///|
/// Create a morph-animated mesh node from an existing material handle.
pub fn Renderer3D::create_morph_mesh_node(
  self : Renderer3D,
  scene : Scene,
  mesh : MeshHandle,
  material : MaterialHandle,
  weights : Array[Float],
  transform? : @tmath.Transform = @tmath.Transform::identity(),
  name? : String = "",
  parent? : NodeId,
) -> NodeId raise {
  let mi = mesh.id()
  if mi < 0 || mi >= self.meshes.length() || self.meshes[mi].morph() == 0 {
    raise Render3DError::InvalidMesh("Renderer3D::create_morph_mesh_node: mesh has no morph targets")
  }
  if self.meshes[mi].skinned() {
    raise Render3DError::Unsupported("Renderer3D::create_morph_mesh_node: morph and skin cannot be combined yet")
  }
  let mati = material.id()
  if mati < 0 || mati >= self.materials.length() {
    raise Render3DError::InvalidMaterial("Renderer3D::create_morph_mesh_node: invalid material handle")
  }
  match self.materials[mati].alpha_mode {
    Blend(_) => raise Render3DError::Unsupported("Renderer3D::create_morph_mesh_node: opaque materials only")
    _ => ()
  }
  if weights.length() > self.meshes[mi].morph() {
    raise Render3DError::InvalidMesh("Renderer3D::create_morph_mesh_node: more weights than morph targets")
  }
  let node = self.create_mesh_node(
    scene,
    mesh,
    material,
    transform~,
    name~,
    parent?=parent,
  )
  self.set_morph_weights(node, weights)
  node
}

///|
/// Create a morph-animated mesh node (opaque materials only). The material is
/// allocated from `desc`; use `create_morph_mesh_node` to reuse one.
pub fn Renderer3D::create_morph_node(
  self : Renderer3D,
  scene : Scene,
  mesh : MeshHandle,
  desc : MaterialDesc,
  weights : Array[Float],
  transform? : @tmath.Transform = @tmath.Transform::identity(),
  name? : String = "",
  parent? : NodeId,
) -> NodeId raise {
  let mi = mesh.id()
  if mi < 0 || mi >= self.meshes.length() || self.meshes[mi].morph() == 0 {
    raise Render3DError::InvalidMesh("Renderer3D::create_morph_node: mesh has no morph targets")
  }
  if self.meshes[mi].skinned() {
    raise Render3DError::Unsupported("Renderer3D::create_morph_node: morph and skin cannot be combined yet")
  }
  match desc.alpha_mode {
    Blend(_) => raise Render3DError::Unsupported("Renderer3D::create_morph_node: opaque materials only")
    _ => ()
  }
  if weights.length() > self.meshes[mi].morph() {
    raise Render3DError::InvalidMesh("Renderer3D::create_morph_node: more weights than morph targets")
  }
  let material = self.create_material(desc)
  self.create_morph_mesh_node(
    scene,
    mesh,
    material,
    weights,
    transform~,
    name~,
    parent?=parent,
  )
}

///|
/// Create a node with distance-based mesh LOD. `levels` runs from highest to
/// lowest detail and `switch_distances` (length `levels.length() - 1`) holds the
/// strictly increasing world-space distances where the next level takes over.
pub fn Renderer3D::create_lod_node(
  self : Renderer3D,
  scene : Scene,
  levels : Array[MeshHandle],
  switch_distances : Array[Float],
  material : MaterialHandle,
  transform? : @tmath.Transform = @tmath.Transform::identity(),
  name? : String = "",
  parent? : NodeId,
) -> NodeId raise {
  if levels.length() == 0 || switch_distances.length() != levels.length() - 1 {
    raise Render3DError::InvalidMesh("Renderer3D::create_lod_node: levels/distances mismatch")
  }
  for i = 0; i < levels.length(); i = i + 1 {
    let mi = levels[i].id()
    if mi < 0 || mi >= self.meshes.length() {
      raise Render3DError::InvalidMesh("Renderer3D::create_lod_node: invalid mesh handle")
    }
    if self.meshes[mi].skinned() {
      raise Render3DError::Unsupported("Renderer3D::create_lod_node: skinned LOD is not supported")
    }
  }
  for i = 1; i < switch_distances.length(); i = i + 1 {
    if switch_distances[i] <= switch_distances[i - 1] {
      raise Render3DError::InvalidMesh("Renderer3D::create_lod_node: switch distances must increase")
    }
  }
  let mati = material.id()
  if mati < 0 || mati >= self.materials.length() {
    raise Render3DError::InvalidMaterial("Renderer3D::create_lod_node: invalid material handle")
  }
  let node = scene.create_node(
    parent?=parent,
    transform=transform,
    payload=NodePayload::Mesh(MeshInstance::new(levels[0], material)),
    name=name,
  )
  let mut bounds = self.mesh_bounds(levels[0])
  for i = 1; i < levels.length(); i = i + 1 {
    match (bounds, self.mesh_bounds(levels[i])) {
      (Some(b), Some(o)) => bounds = Some(b.union(o))
      (None, Some(o)) => bounds = Some(o)
      _ => ()
    }
  }
  scene.set_local_bounds(node, bounds)
  self.lods.push({ node, levels, switch_distances })
  node
}

///|
/// Create a mesh node driven by a skeleton, reusing an existing material
/// handle. `joints` are scene nodes and `inverse_bind` their rest-pose inverse
/// world matrices (mesh-local space).
pub fn Renderer3D::create_skinned_mesh_node(
  self : Renderer3D,
  scene : Scene,
  mesh : MeshHandle,
  material : MaterialHandle,
  joints : Array[NodeId],
  inverse_bind : Array[@tmath.Mat4],
  transform? : @tmath.Transform = @tmath.Transform::identity(),
  name? : String = "",
  parent? : NodeId,
) -> NodeId raise {
  if joints.length() == 0 || joints.length() != inverse_bind.length() {
    raise Render3DError::InvalidMesh("Renderer3D::create_skinned_mesh_node: joints and inverse_bind must match")
  }
  let mi = mesh.id()
  if mi < 0 || mi >= self.meshes.length() || !self.meshes[mi].skinned() {
    raise Render3DError::InvalidMesh("Renderer3D::create_skinned_mesh_node: mesh has no skin data")
  }
  let mati = material.id()
  if mati < 0 || mati >= self.materials.length() {
    raise Render3DError::InvalidMaterial("Renderer3D::create_skinned_mesh_node: invalid material handle")
  }
  if self.bone_cursor + joints.length() > MAX_BONES {
    raise Render3DError::CapacityExceeded("Renderer3D::create_skinned_mesh_node: bone palette exhausted")
  }
  let node = scene.create_node(
    parent?=parent,
    transform=transform,
    payload=NodePayload::Mesh(MeshInstance::new(mesh, material)),
    name=name,
  )
  scene.set_local_bounds(node, self.mesh_bounds(mesh))
  self.skins.push({
    node,
    joints,
    inverse_bind,
    offset: self.bone_cursor,
    count: joints.length(),
  })
  self.bone_cursor = self.bone_cursor + joints.length()
  node
}

///|
/// Create a mesh node driven by a skeleton. The material is allocated from
/// `desc`; use `create_skinned_mesh_node` to reuse one.
pub fn Renderer3D::create_skinned_node(
  self : Renderer3D,
  scene : Scene,
  mesh : MeshHandle,
  desc : MaterialDesc,
  joints : Array[NodeId],
  inverse_bind : Array[@tmath.Mat4],
  transform? : @tmath.Transform = @tmath.Transform::identity(),
  name? : String = "",
  parent? : NodeId,
) -> NodeId raise {
  if joints.length() == 0 || joints.length() != inverse_bind.length() {
    raise Render3DError::InvalidMesh("Renderer3D::create_skinned_node: joints and inverse_bind must match")
  }
  let mi = mesh.id()
  if mi < 0 || mi >= self.meshes.length() || !self.meshes[mi].skinned() {
    raise Render3DError::InvalidMesh("Renderer3D::create_skinned_node: mesh has no skin data")
  }
  if self.bone_cursor + joints.length() > MAX_BONES {
    raise Render3DError::CapacityExceeded("Renderer3D::create_skinned_node: bone palette exhausted")
  }
  let mat = self.create_material(desc)
  self.create_skinned_mesh_node(
    scene,
    mesh,
    mat,
    joints,
    inverse_bind,
    transform~,
    name~,
    parent?=parent,
  )
}

///|
/// Create a mesh node and register its local bounds in one call.
pub fn Renderer3D::create_mesh_node(
  self : Renderer3D,
  scene : Scene,
  mesh : MeshHandle,
  material : MaterialHandle,
  transform? : @tmath.Transform = @tmath.Transform::identity(),
  name? : String = "",
  parent? : NodeId,
) -> NodeId {
  let node = scene.create_node(
    parent?=parent,
    transform=transform,
    payload=NodePayload::Mesh(MeshInstance::new(mesh, material)),
    name=name,
  )
  scene.set_local_bounds(node, self.mesh_bounds(mesh))
  node
}

///|
/// Create a scene node that draws an uploaded line list.
///
/// The node's world transform is applied to the (local-space) vertices and
/// `material.color` tints them. Lines are depth-tested overlays: they do not
/// cast shadows, are not ray-traceable, and have no normals/UVs.
pub fn Renderer3D::create_line_node(
  self : Renderer3D,
  scene : Scene,
  lines : LineHandle,
  material? : LineMaterial = LineMaterial::new(),
  transform? : @tmath.Transform = @tmath.Transform::identity(),
  name? : String = "",
  parent? : NodeId,
) -> NodeId {
  let node = scene.create_node(
    parent?=parent,
    transform=transform,
    payload=NodePayload::Lines(LineInstance::new(lines, material)),
    name=name,
  )
  scene.set_local_bounds(node, self.lines_bounds(lines))
  node
}

///|
/// Build and own a procedural PMREM environment for `sun_dir`.
pub fn Renderer3D::set_procedural_environment(
  self : Renderer3D,
  sun_dir : @tmath.Vec3,
  size? : Int = 256,
  samples? : Int = 128,
) -> Unit raise {
  let cube = procedural_environment_cubemap(self.dev, sun_dir, size~, samples~)
  if self.owns_env {
    self.env_cube.destroy()
  }
  self.env_cube = cube
  self.env_sun = sun_dir.normalize()
  self.env_intensity = 1.0
  self.owns_env = true
}

///|
/// Create a material from `desc` and attach a mesh node using it.
pub fn Renderer3D::create_pbr_node(
  self : Renderer3D,
  scene : Scene,
  mesh : MeshHandle,
  desc : MaterialDesc,
  transform? : @tmath.Transform = @tmath.Transform::identity(),
  name? : String = "",
  parent? : NodeId,
) -> NodeId raise {
  let mat = self.create_material(desc)
  self.create_mesh_node(scene, mesh, mat, transform~, name~, parent?=parent)
}
