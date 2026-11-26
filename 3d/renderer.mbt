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
  bloom : Bool
  shadows : Bool
  shadow_map_size : Int
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
  }
}

const OBJECT_FLOATS : Int = 36

const OBJECT_BYTES : Int = 144

const LIGHT_FLOATS : Int = 16

const LIGHT_BYTES : Int = 64

const MATERIAL_FLOATS : Int = 16

const MATERIAL_BYTES : Int = 64

const FRAME_FLOATS : Int = 60

const FRAME_BYTES : Int = 240

const FRAME_SLOT_BYTES : Int = 256

const SKY_FLOATS : Int = 20

const SKY_BYTES : Int = 80

const SKY_SLOT_BYTES : Int = 128

///|
priv struct FrameTargets {
  w : Int
  h : Int
  depth : @tycho.Texture
  hdr : @tycho.Texture
  // Set when MSAA is on; `hdr` is the multisampled colour attachment.
  hdr_resolve : @tycho.Texture?
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
}

///|
/// A renderer-owned texture together with its bindless heap slot.
priv struct GpuTexture {
  tex : @tycho.Texture
  index : Int
}

///|
pub struct Renderer3D {
  priv dev : @tycho.Device
  priv desc : RendererDesc
  priv msaa : Bool
  priv meshes : Array[GpuMesh]
  priv materials : Array[MaterialDesc]
  priv object_ring : @pool.FrameRing
  priv light_ring : @pool.FrameRing
  priv frame_ubo : @tycho.Buffer
  priv sky_ubo : @tycho.Buffer
  priv material_ssbo : @tycho.Buffer
  priv shadow_maps : Array[@tycho.Texture]
  priv shadow_sampler : @tycho.Sampler
  priv env_sampler : @tycho.Sampler
  priv linear_sampler : @tycho.Sampler
  priv material_sampler : @tycho.Sampler
  priv bindless : @tycho.BindlessHeap
  priv white_tex : @tycho.Texture
  priv flat_normal_tex : @tycho.Texture
  priv white_index : Int
  priv flat_normal_index : Int
  priv textures : Array[GpuTexture]
  priv mut env_cube : @tycho.Texture
  priv mut env_sun : @tmath.Vec3
  priv mut env_intensity : Float
  priv mut owns_env : Bool
  priv shadow_pipe : @tycho.Pipeline
  priv pbr_pipe : @tycho.Pipeline
  priv pbr_blend_pipe : @tycho.Pipeline
  priv sky_pipe : @tycho.Pipeline
  priv bloom_extract_pipe : @tycho.Pipeline
  priv bloom_blur_pipe : @tycho.Pipeline
  priv tonemap_srgb_pipe : @tycho.Pipeline
  priv tonemap_linear_pipe : @tycho.Pipeline
  priv gpu_culling : Bool
  priv cull_pipe : @tycho.Pipeline?
  priv pbr_cull_pipe : @tycho.Pipeline?
  priv cull_vis : Array[@tycho.Buffer]
  priv cull_cmds : Array[@tycho.Buffer]
  priv line_pipe : @tycho.Pipeline
  priv mut line_vbuf : @tycho.Buffer
  priv mut line_capacity : Int
  priv line_floats : Array[Float]
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
  w.push_float(0.0)
  w.push_float(0.0)
}

///|
pub fn Renderer3D::new(
  dev : @tycho.Device,
  desc? : RendererDesc = RendererDesc::default(),
) -> Renderer3D raise {
  let samples = if desc.msaa {
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
  let bindless = dev.create_bindless_heap(max_textures=desc.max_textures)
  let white_tex = solid_texture(dev, 255, 255, 255, 255, true)
  let flat_normal_tex = solid_texture(dev, 128, 128, 255, 255, false)
  let white_index = bindless.register_texture(white_tex, material_sampler)
  let flat_normal_index = bindless.register_texture(flat_normal_tex, material_sampler)
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
      depth_format=Some(@tycho.TextureFormat::Depth24Stencil8),
      depth_only=true,
      depth_bias=true,
      depth_bias_constant=(1.5 : Float),
      depth_bias_slope=(1.75 : Float),
      vertex_layouts=mesh_layouts,
    ),
  )
  let pbr_pipe = dev.create_graphics_pipeline(
    @tycho.PipelineDesc::from_spirv(
      spv_pbr_vert,
      spv_pbr_frag,
      depth_test=true,
      depth_write=true,
      depth_compare=@tycho.CompareOp::GreaterEqual,
      depth_format=Some(@tycho.TextureFormat::Depth32F),
      cull_mode=@tycho.CullMode::Back,
      front_face=@tycho.FrontFace::CounterClockwise,
      color_format=Some(@tycho.TextureFormat::RGBA16F),
      vertex_layouts=mesh_layouts,
      bindless_heap=Some(bindless),
      samples=samples,
    ),
  )
  let pbr_blend_pipe = dev.create_graphics_pipeline(
    @tycho.PipelineDesc::from_spirv(
      spv_pbr_vert,
      spv_pbr_frag,
      depth_test=true,
      depth_write=false,
      depth_compare=@tycho.CompareOp::GreaterEqual,
      depth_format=Some(@tycho.TextureFormat::Depth32F),
      cull_mode=@tycho.CullMode::Back,
      front_face=@tycho.FrontFace::CounterClockwise,
      blend=true,
      blend_mode=Some(@tycho.BlendMode::Alpha),
      color_format=Some(@tycho.TextureFormat::RGBA16F),
      vertex_layouts=mesh_layouts,
      bindless_heap=Some(bindless),
      samples=samples,
    ),
  )
  let sky_pipe = dev.create_graphics_pipeline(
    @tycho.PipelineDesc::from_spirv(
      spv_skybox_vert,
      spv_skybox_frag,
      depth_format=Some(@tycho.TextureFormat::Depth32F),
      color_format=Some(@tycho.TextureFormat::RGBA16F),
      samples=samples,
    ),
  )
  let bloom_extract_pipe = dev.create_graphics_pipeline(
    @tycho.PipelineDesc::from_spirv(
      spv_fullscreen_vert,
      spv_bloom_extract_frag,
      color_format=Some(@tycho.TextureFormat::RGBA16F),
    ),
  )
  let bloom_blur_pipe = dev.create_graphics_pipeline(
    @tycho.PipelineDesc::from_spirv(
      spv_fullscreen_vert,
      spv_bloom_blur_frag,
      color_format=Some(@tycho.TextureFormat::RGBA16F),
    ),
  )
  let tonemap_srgb_pipe = dev.create_graphics_pipeline(
    @tycho.PipelineDesc::from_spirv(
      spv_fullscreen_vert,
      spv_tonemap_frag,
      color_format=Some(@tycho.TextureFormat::RGBA8Srgb),
    ),
  )
  let tonemap_linear_pipe = dev.create_graphics_pipeline(
    @tycho.PipelineDesc::from_spirv(
      spv_fullscreen_vert,
      spv_tonemap_frag,
      color_format=Some(@tycho.TextureFormat::RGBA8),
    ),
  )
  let mut cull_pipe : @tycho.Pipeline? = None
  let mut pbr_cull_pipe : @tycho.Pipeline? = None
  let cull_vis : Array[@tycho.Buffer] = []
  let cull_cmds : Array[@tycho.Buffer] = []
  if desc.gpu_culling {
    cull_pipe = Some(dev.create_compute_pipeline_auto(spv_cull_comp))
    pbr_cull_pipe = Some(
      dev.create_graphics_pipeline(
        @tycho.PipelineDesc::from_spirv(
          spv_pbr_cull_vert,
          spv_pbr_frag,
          depth_test=true,
          depth_write=true,
          depth_compare=@tycho.CompareOp::GreaterEqual,
          depth_format=Some(@tycho.TextureFormat::Depth32F),
          cull_mode=@tycho.CullMode::Back,
          front_face=@tycho.FrontFace::CounterClockwise,
          color_format=Some(@tycho.TextureFormat::RGBA16F),
          vertex_layouts=mesh_layouts,
          bindless_heap=Some(bindless),
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
      cull_cmds.push(
        dev.create_buffer_with(
          desc.max_objects * 20,
          @tycho.BufferKind::Indirect,
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
      depth_format=Some(@tycho.TextureFormat::Depth32F),
      color_format=Some(@tycho.TextureFormat::RGBA16F),
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
      compare_op=Some(@tycho.CompareOp::LessEqual),
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
  let env_cube = default_environment_cubemap(dev)
  let shadow_maps : Array[@tycho.Texture] = []
  let cascades = if desc.shadow_cascades < 1 { 1 } else { desc.shadow_cascades }
  for i = 0; i < cascades; i = i + 1 {
    shadow_maps.push(
      dev.create_depth_texture_format(
        desc.shadow_map_size,
        desc.shadow_map_size,
        @tycho.TextureFormat::Depth24Stencil8,
      ),
    )
  }
  {
    dev,
    desc,
    msaa: desc.msaa,
    meshes: [],
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
    shadow_maps,
    shadow_sampler,
    env_sampler,
    linear_sampler,
    material_sampler,
    bindless,
    white_tex,
    flat_normal_tex,
    white_index,
    flat_normal_index,
    textures: [],
    env_cube,
    env_sun: @tmath.Vec3::new(3.0, 4.0, -2.0).normalize(),
    env_intensity: 1.0,
    owns_env: true,
    shadow_pipe,
    pbr_pipe,
    pbr_blend_pipe,
    sky_pipe,
    bloom_extract_pipe,
    bloom_blur_pipe,
    tonemap_srgb_pipe,
    tonemap_linear_pipe,
    gpu_culling: desc.gpu_culling,
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
  let gpu = GpuMesh::upload(self.dev, mesh)
  self.meshes.push(gpu)
  MeshHandle::from_id(self.meshes.length() - 1)
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
    fail("Renderer3D: create_texture expects width*height*4 bytes")
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
  let index = self.bindless.register_texture(tex, self.material_sampler)
  self.textures.push({ tex, index })
  TextureHandle::from_id(self.textures.length() - 1)
}

///|
pub fn Renderer3D::create_material(self : Renderer3D, m : MaterialDesc) -> MaterialHandle raise {
  if self.materials.length() >= self.desc.max_materials {
    fail("Renderer3D: material capacity exhausted")
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
    fail("Renderer3D: invalid material handle")
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
}

///|
fn Renderer3D::pack_lights(self : Renderer3D, scene : Scene) -> (Int, @tmath.Vec3?) {
  let light_nodes : Array[(Light, @tmath.Affine3)] = []
  scene.traverse(
    fn(id) {
      match scene.payload(id) {
        Some(NodePayload::Light(l)) => light_nodes.push(
          (l, scene.world_transform(id)),
        )
        _ => ()
      }
    },
  )
  self.light_writer.reset()
  let mut count = 0
  let mut shadow_dir : @tmath.Vec3? = None
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
        match d.shadow {
          Some(_) =>
            match shadow_dir {
              Some(_) => ()
              None => shadow_dir = Some(to_light)
            }
          None => ()
        }
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
    count = count + 1
  }
  (count, shadow_dir)
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
  let cam = match scene.payload(camera) {
    Some(NodePayload::Camera(c)) => c
    _ => fail("Renderer3D: camera node has no Camera payload")
  }
  let cam_world = scene.world_transform(camera)
  let vp = match cam.view_proj(cam_world) {
    Some(v) => v
    None => fail("Renderer3D: camera matrix is singular")
  }
  let eye = cam_world.translation
  let targets = self.ensure_targets(w, h)
  let (light_count, shadow_dir) = self.pack_lights(scene)
  let frustum = @tmath.Frustum::from_view_proj(vp)
  let gpu_cull_enabled = match self.cull_pipe {
    Some(_) => self.gpu_culling
    None => false
  }
  let visible : Array[NodeId] = if gpu_cull_enabled {
    // Hand every mesh to the GPU; per-instance culling happens in compute.
    let all : Array[NodeId] = []
    scene.traverse(fn(id) {
      match scene.payload(id) {
        Some(NodePayload::Mesh(_)) => all.push(id)
        _ => ()
      }
    })
    all
  } else {
    scene.collect_visible(frustum, (0xFFFFFFFF : UInt))
  }
  let solid : Array[DrawItem] = []
  let transparent : Array[DrawItem] = []
  for id in visible {
    match scene.payload(id) {
      Some(NodePayload::Mesh(inst)) => {
        let mi = inst.mesh.id()
        let mati = inst.material.id()
        if mi >= 0 &&
          mi < self.meshes.length() &&
          mati >= 0 &&
          mati < self.materials.length() {
          let world = scene.world_transform(id)
          let dist = (world.translation - eye).length()
          let item : DrawItem = {
            node: id,
            mesh: mi,
            material: mati,
            distance: dist,
            cast_shadow: inst.cast_shadow,
            transparent: is_blend_mode(self.materials[mati].alpha_mode),
          }
          if item.transparent {
            transparent.push(item)
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
  // Object records: opaque batches, then transparent singles, then shadow-only
  // copies grouped per mesh. Shaders index this array as
  // `firstObject + gl_InstanceIndex`.
  self.object_writer.reset()
  let solid_batches : Array[DrawBatch] = []
  let mut records = 0
  for item in solid {
    self.pack_object(item, scene)
    let n = solid_batches.length()
    if n > 0 &&
      solid_batches[n - 1].mesh == item.mesh &&
      solid_batches[n - 1].material == item.material {
      solid_batches[n - 1].count = solid_batches[n - 1].count + 1
    } else {
      solid_batches.push({
        mesh: item.mesh,
        material: item.material,
        first: records,
        count: 1,
        cull_cmd: -1,
        list_offset: 0,
      })
    }
    records = records + 1
  }
  let main_count = records
  let transparent_batches : Array[DrawBatch] = []
  for item in transparent {
    self.pack_object(item, scene)
    transparent_batches.push({
      mesh: item.mesh,
      material: item.material,
      first: records,
      count: 1,
      cull_cmd: -1,
      list_offset: 0,
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
  casters.sort_by(fn(a, b) { a.mesh - b.mesh })
  let shadow_batches : Array[DrawBatch] = []
  for item in casters {
    self.pack_object(item, scene)
    let n = shadow_batches.length()
    if n > 0 && shadow_batches[n - 1].mesh == item.mesh {
      shadow_batches[n - 1].count = shadow_batches[n - 1].count + 1
    } else {
      shadow_batches.push({
        mesh: item.mesh,
        material: -1,
        first: records,
        count: 1,
        cull_cmd: -1,
        list_offset: 0,
      })
    }
    records = records + 1
  }
  let mut cull_cmd_count = 0
  let mut cull_list_count = 0
  if gpu_cull_enabled {
    for b in solid_batches {
      if b.count >= 16 && cull_list_count + b.count <= self.desc.max_objects &&
        cull_cmd_count < self.desc.max_objects {
        b.cull_cmd = cull_cmd_count
        b.list_offset = cull_list_count
        cull_list_count = cull_list_count + b.count
        cull_cmd_count = cull_cmd_count + 1
      }
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
  let mut light_vp0 = @tmath.Mat4::identity()
  let mut light_vp1 = @tmath.Mat4::identity()
  let mut cascade_split : Float = 1.0e9
  let mut shadows_enabled = false
  match shadow_dir {
    Some(to_light) =>
      match caster_union {
        Some(bounds) =>
          if self.desc.shadows {
            let center = bounds.center()
            let radius = bounds.half_extents().length() + 0.05
            let up = if to_light.y.abs() > 0.99 {
              @tmath.Vec3::unit_z()
            } else {
              @tmath.Vec3::unit_y()
            }
            // Cascade 0 covers the inner half radius at twice the density;
            // cascade 1 covers the whole caster union.
            let r0 = if self.shadow_maps.length() > 1 {
              radius * 0.5
            } else {
              radius
            }
            let half0 = r0 * 1.15 + 0.1
            let eye0 = center + to_light.scale(r0 * 2.0 + 1.0)
            light_vp0 = @tmath.orthographic_rh(
              -half0,
              half0,
              -half0,
              half0,
              0.05,
              r0 * 4.0 + 2.0,
            ) * @tmath.look_at_rh(eye0, center, up)
            if self.shadow_maps.length() > 1 {
              let half1 = radius * 1.15 + 0.1
              let eye1 = center + to_light.scale(radius * 2.0 + 1.0)
              light_vp1 = @tmath.orthographic_rh(
                -half1,
                half1,
                -half1,
                half1,
                0.05,
                radius * 4.0 + 2.0,
              ) * @tmath.look_at_rh(eye1, center, up)
              cascade_split = (center - eye).length() + r0
            } else {
              light_vp1 = light_vp0
            }
            shadows_enabled = true
          }
        None => ()
      }
    None => ()
  }
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
  self.frame_writer.push_float(f_of_int(self.shadow_maps.length()))
  self.frame_writer.push_float(0.0)
  self.frame_writer.push_float(0.0)
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
    None => fail("Renderer3D: object ring capacity exhausted")
  }
  self.light_ring.begin_frame(slot)
  let light_offset = match self.light_ring.upload_floats(
    self.light_writer.buffer(),
    light_count * LIGHT_FLOATS,
  ) {
    Some(o) => o
    None => fail("Renderer3D: light ring capacity exhausted")
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
  // GPU culling prepass: compute writes compacted lists and grows the
  // indirect instance counts. Dispatches must stay outside a render pass.
  if gpu_cull_enabled && cull_cmd_count > 0 {
    let cmds = FixedArray::make(cull_cmd_count * 5, (0 : UInt))
    for b in solid_batches {
      if b.cull_cmd >= 0 {
        let o = b.cull_cmd * 5
        cmds[o] = self.meshes[b.mesh].index_count().reinterpret_as_uint()
        cmds[o + 1] = 0
        cmds[o + 2] = 0
        cmds[o + 3] = 0
        cmds[o + 4] = 0
      }
    }
    self.cull_cmds[slot & 1].upload_uint32(cmds)
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
        for b in solid_batches {
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

  // Always run one pass per cascade: it clears the map and transitions it to
  // SHADER_READ_ONLY even with no casters, since the PBR pipeline always
  // binds both shadow maps.
  for c = 0; c < self.shadow_maps.length(); c = c + 1 {
    cmd.begin_render_pass(
      [],
      depth=Some(
        @tycho.DepthTargetDesc::new(
          self.shadow_maps[c],
          load_op=@tycho.LoadOp::Clear,
          store_op=@tycho.StoreOp::Store,
          clear_depth=1.0,
        ),
      ),
    )
    cmd.set_viewport(0.0, 0.0, f_of_int(self.desc.shadow_map_size), f_of_int(self.desc.shadow_map_size))
    cmd.set_scissor(0, 0, self.desc.shadow_map_size, self.desc.shadow_map_size)
    cmd.bind_pipeline(self.shadow_pipe)
    cmd.bind_uniform(
      self.shadow_pipe,
      0,
      self.frame_ubo,
      offset=slot * FRAME_SLOT_BYTES,
      size=FRAME_BYTES,
    )
    cmd.bind_storage(
      self.shadow_pipe,
      0,
      self.object_ring.buffer(),
      offset=object_offset,
      size=bind_objects_bytes(object_count),
    )
    if shadows_enabled {
      for b in shadow_batches {
        cmd.push_constants_bytes(self.shadow_pipe, pc2_bytes(b.first, c))
        let mesh = self.meshes[b.mesh]
        mesh.bind(cmd)
        cmd.draw_indexed(mesh.index_count(), instances=b.count)
        self.stats.shadow_passes = self.stats.shadow_passes + 1
      }
    }
    cmd.end_render_pass()
  }

  // Main HDR pass.
  let resolved = match targets.hdr_resolve {
    Some(t) => t
    None => targets.hdr
  }
  cmd.begin_render_pass(
    [
      @tycho.RenderTargetDesc::new(
        targets.hdr,
        load_op=@tycho.LoadOp::Clear,
        store_op=if targets.hdr_resolve is Some(_) {
          @tycho.StoreOp::DontCare
        } else {
          @tycho.StoreOp::Store
        },
        clear_color=@tycho.ClearColor::black(),
        resolve_texture=targets.hdr_resolve,
      ),
    ],
    depth=Some(
      @tycho.DepthTargetDesc::new(
        targets.depth,
        load_op=@tycho.LoadOp::Clear,
        store_op=@tycho.StoreOp::DontCare,
        clear_depth=0.0,
      ),
    ),
  )
  cmd.set_viewport(0.0, 0.0, f_of_int(w), f_of_int(h))
  cmd.set_scissor(0, 0, w, h)
  cmd.bind_pipeline(self.sky_pipe)
  cmd.bind_uniform(
    self.sky_pipe,
    0,
    self.sky_ubo,
    offset=slot * SKY_SLOT_BYTES,
    size=SKY_BYTES,
  )
  cmd.bind_texture(self.sky_pipe, 0, self.env_cube, self.env_sampler)
  cmd.draw(3, 1)
  if main_count > 0 {
    cmd.bind_pipeline(self.pbr_pipe)
    cmd.bind_bindless_heap(self.pbr_pipe, self.bindless)
    cmd.bind_uniform(
      self.pbr_pipe,
      0,
      self.frame_ubo,
      offset=slot * FRAME_SLOT_BYTES,
      size=FRAME_BYTES,
    )
    cmd.bind_storage(
      self.pbr_pipe,
      0,
      self.object_ring.buffer(),
      offset=object_offset,
      size=bind_objects_bytes(object_count),
    )
    cmd.bind_storage(
      self.pbr_pipe,
      1,
      self.material_ssbo,
      offset=0,
      size=self.desc.max_materials * MATERIAL_BYTES,
    )
    cmd.bind_storage(
      self.pbr_pipe,
      2,
      self.light_ring.buffer(),
      offset=light_offset,
      size=bind_lights_bytes(light_count),
    )
    cmd.bind_texture(self.pbr_pipe, 0, self.shadow_maps[0], self.shadow_sampler)
    cmd.bind_texture(
      self.pbr_pipe,
      1,
      self.shadow_maps[self.shadow_maps.length() - 1],
      self.shadow_sampler,
    )
    cmd.bind_texture(self.pbr_pipe, 2, self.env_cube, self.env_sampler)
    for b in solid_batches {
      if b.cull_cmd < 0 {
        cmd.push_constants_floats(
          self.pbr_pipe,
          [f_of_int(b.first), f_of_int(b.material), 0.0, 0.0],
        )
        let mesh = self.meshes[b.mesh]
        mesh.bind(cmd)
        cmd.draw_indexed(mesh.index_count(), instances=b.count)
        self.stats.draw_calls = self.stats.draw_calls + 1
        self.stats.triangles = self.stats.triangles + mesh.index_count() / 3 * b.count
        if b.count > 1 {
          self.stats.instance_batches = self.stats.instance_batches + 1
        }
      }
    }
    if cull_cmd_count > 0 {
      match self.pbr_cull_pipe {
        Some(pipe) => {
          cmd.bind_pipeline(pipe)
          cmd.bind_bindless_heap(pipe, self.bindless)
          cmd.bind_uniform(
            pipe,
            0,
            self.frame_ubo,
            offset=slot * FRAME_SLOT_BYTES,
            size=FRAME_BYTES,
          )
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
            self.material_ssbo,
            offset=0,
            size=self.desc.max_materials * MATERIAL_BYTES,
          )
          cmd.bind_storage(
            pipe,
            2,
            self.light_ring.buffer(),
            offset=light_offset,
            size=bind_lights_bytes(light_count),
          )
          cmd.bind_storage(
            pipe,
            3,
            self.cull_vis[slot & 1],
            offset=0,
            size=self.desc.max_objects * 4,
          )
          cmd.bind_texture(pipe, 0, self.shadow_maps[0], self.shadow_sampler)
          cmd.bind_texture(
            pipe,
            1,
            self.shadow_maps[self.shadow_maps.length() - 1],
            self.shadow_sampler,
          )
          cmd.bind_texture(pipe, 2, self.env_cube, self.env_sampler)
          for b in solid_batches {
            if b.cull_cmd >= 0 {
              cmd.push_constants_floats(
                pipe,
                [f_of_int(b.first), f_of_int(b.material), f_of_int(b.list_offset), 0.0],
              )
              let mesh = self.meshes[b.mesh]
              mesh.bind(cmd)
              cmd.draw_indexed_indirect(
                self.cull_cmds[slot & 1],
                1,
                offset=b.cull_cmd * 20,
                stride=20,
              )
              self.stats.draw_calls = self.stats.draw_calls + 1
              self.stats.triangles = self.stats.triangles + mesh.index_count() / 3 * b.count
              if b.count > 1 {
                self.stats.instance_batches = self.stats.instance_batches + 1
              }
            }
          }
        }
        None => ()
      }
    }
    if transparent.length() > 0 {
      cmd.bind_pipeline(self.pbr_blend_pipe)
      cmd.bind_bindless_heap(self.pbr_blend_pipe, self.bindless)
      cmd.bind_uniform(
        self.pbr_blend_pipe,
        0,
        self.frame_ubo,
        offset=slot * FRAME_SLOT_BYTES,
        size=FRAME_BYTES,
      )
      cmd.bind_storage(
        self.pbr_blend_pipe,
        0,
        self.object_ring.buffer(),
        offset=object_offset,
        size=bind_objects_bytes(object_count),
      )
      cmd.bind_storage(
        self.pbr_blend_pipe,
        1,
        self.material_ssbo,
        offset=0,
        size=self.desc.max_materials * MATERIAL_BYTES,
      )
      cmd.bind_storage(
        self.pbr_blend_pipe,
        2,
        self.light_ring.buffer(),
        offset=light_offset,
        size=bind_lights_bytes(light_count),
      )
      cmd.bind_texture(self.pbr_blend_pipe, 0, self.shadow_maps[0], self.shadow_sampler)
      cmd.bind_texture(
        self.pbr_blend_pipe,
        1,
        self.shadow_maps[self.shadow_maps.length() - 1],
        self.shadow_sampler,
      )
      cmd.bind_texture(self.pbr_blend_pipe, 2, self.env_cube, self.env_sampler)
      for b in transparent_batches {
        cmd.push_constants_floats(
          self.pbr_blend_pipe,
          [f_of_int(b.first), f_of_int(b.material), 0.0, 0.0],
        )
        let mesh = self.meshes[b.mesh]
        mesh.bind(cmd)
        cmd.draw_indexed(mesh.index_count(), instances=b.count)
        self.stats.draw_calls = self.stats.draw_calls + 1
        self.stats.triangles = self.stats.triangles + mesh.index_count() / 3 * b.count
      }
    }
  }
  if line_verts > 0 {
    cmd.bind_pipeline(self.line_pipe)
    cmd.bind_uniform(
      self.line_pipe,
      0,
      self.frame_ubo,
      offset=slot * FRAME_SLOT_BYTES,
      size=FRAME_BYTES,
    )
    cmd.bind_vertex(0, self.line_vbuf)
    cmd.draw(line_verts, 1)
    self.stats.draw_calls = self.stats.draw_calls + 1
    self.stats.line_segments = self.stats.line_segments + line_verts / 2
  }
  self.line_floats.clear()
  cmd.end_render_pass()

  // Bloom chain.
  let mut bloom_result = resolved
  if self.desc.bloom {
    let bw = targets.bloom_a.width()
    let bh = targets.bloom_a.height()
    cmd.begin_render_pass(
      [
        @tycho.RenderTargetDesc::new(
          targets.bloom_a,
          load_op=@tycho.LoadOp::Clear,
          store_op=@tycho.StoreOp::Store,
          clear_color=@tycho.ClearColor::black(),
        ),
      ],
    )
    cmd.set_viewport(0.0, 0.0, f_of_int(bw), f_of_int(bh))
    cmd.set_scissor(0, 0, bw, bh)
    cmd.bind_pipeline(self.bloom_extract_pipe)
    cmd.bind_texture(self.bloom_extract_pipe, 0, resolved, self.linear_sampler)
    cmd.draw(3, 1)
    cmd.end_render_pass()
    cmd.begin_render_pass(
      [
        @tycho.RenderTargetDesc::new(
          targets.bloom_b,
          load_op=@tycho.LoadOp::Clear,
          store_op=@tycho.StoreOp::Store,
          clear_color=@tycho.ClearColor::black(),
        ),
      ],
    )
    cmd.set_viewport(0.0, 0.0, f_of_int(bw), f_of_int(bh))
    cmd.set_scissor(0, 0, bw, bh)
    cmd.bind_pipeline(self.bloom_blur_pipe)
    cmd.bind_texture(self.bloom_blur_pipe, 0, targets.bloom_a, self.linear_sampler)
    cmd.push_constants_floats(
      self.bloom_blur_pipe,
      [1.0 / f_of_int(bw), (0.0 : Float), (0.0 : Float), (0.0 : Float)],
    )
    cmd.draw(3, 1)
    cmd.end_render_pass()
    cmd.begin_render_pass(
      [
        @tycho.RenderTargetDesc::new(
          targets.bloom_a,
          load_op=@tycho.LoadOp::Clear,
          store_op=@tycho.StoreOp::Store,
          clear_color=@tycho.ClearColor::black(),
        ),
      ],
    )
    cmd.set_viewport(0.0, 0.0, f_of_int(bw), f_of_int(bh))
    cmd.set_scissor(0, 0, bw, bh)
    cmd.bind_pipeline(self.bloom_blur_pipe)
    cmd.bind_texture(self.bloom_blur_pipe, 0, targets.bloom_b, self.linear_sampler)
    cmd.push_constants_floats(
      self.bloom_blur_pipe,
      [(0.0 : Float), 1.0 / f_of_int(bh), (0.0 : Float), (0.0 : Float)],
    )
    cmd.draw(3, 1)
    cmd.end_render_pass()
    bloom_result = targets.bloom_a
  }

  // Tonemap into the caller's target.
  let tm_pipe = match final_format {
    @tycho.TextureFormat::RGBA8Srgb => self.tonemap_srgb_pipe
    @tycho.TextureFormat::RGBA8 => self.tonemap_linear_pipe
    _ => {
      fail("Renderer3D: unsupported dst target format")
      self.tonemap_linear_pipe
    }
  }
  cmd.begin_render_pass(
    [
      @tycho.RenderTargetDesc::new(
        dst,
        load_op=@tycho.LoadOp::Clear,
        store_op=@tycho.StoreOp::Store,
        clear_color=@tycho.ClearColor::black(),
      ),
    ],
  )
  cmd.set_viewport(0.0, 0.0, f_of_int(w), f_of_int(h))
  cmd.set_scissor(0, 0, w, h)
  cmd.bind_pipeline(tm_pipe)
  cmd.bind_texture(tm_pipe, 0, resolved, self.linear_sampler)
  cmd.bind_texture(tm_pipe, 1, bloom_result, self.linear_sampler)
  cmd.draw(3, 1)
  cmd.end_render_pass()
  self.stats.draw_calls = self.stats.draw_calls + 4
}

///|
pub fn Renderer3D::render_swapchain(
  self : Renderer3D,
  sc : @tycho.Swapchain,
  scene : Scene,
  camera : NodeId,
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
  camera : NodeId,
) -> Unit raise {
  let w = sc.width()
  let h = sc.height()
  let slot = cmd.frame_slot()
  let out = self.ensure_present(w, h)
  self.render_frame(cmd, scene, camera, w, h, out, @tycho.TextureFormat::RGBA8Srgb, slot)
  cmd.blit_to_swapchain(out, sc)
}

///|
pub fn Renderer3D::render_offscreen(
  self : Renderer3D,
  scene : Scene,
  camera : NodeId,
  target : @tycho.Texture,
) -> Unit raise {
  let cmd = self.dev.begin_commands()
  let slot = cmd.frame_slot()
  self.render_frame(
    cmd,
    scene,
    camera,
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
pub fn Renderer3D::stats(self : Renderer3D) -> RenderStats3D {
  self.stats
}

///|
pub fn Renderer3D::destroy(self : Renderer3D) -> Unit {
  for m in self.meshes {
    m.destroy()
  }
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
  for t in self.textures {
    t.tex.destroy()
  }
  self.bindless.destroy()
  self.white_tex.destroy()
  self.flat_normal_tex.destroy()
  self.material_sampler.destroy()
  for m in self.shadow_maps {
    m.destroy()
  }
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
  self.tonemap_linear_pipe.destroy()
  self.tonemap_srgb_pipe.destroy()
  self.bloom_blur_pipe.destroy()
  self.bloom_extract_pipe.destroy()
  self.sky_pipe.destroy()
  self.pbr_blend_pipe.destroy()
  self.pbr_pipe.destroy()
  self.shadow_pipe.destroy()
  self.linear_sampler.destroy()
  self.env_sampler.destroy()
  self.shadow_sampler.destroy()
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
) -> NodeId {
  let node = scene.create_node(
    transform=transform,
    payload=NodePayload::Mesh(MeshInstance::new(mesh, material)),
    name=name,
  )
  scene.set_local_bounds(node, self.mesh_bounds(mesh))
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
) -> NodeId raise {
  let mat = self.create_material(desc)
  self.create_mesh_node(scene, mesh, mat, transform~, name~)
}
