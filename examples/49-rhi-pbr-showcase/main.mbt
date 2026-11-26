// Example 49 — Flagship pure-MoonBit 3D PBR showcase:
// - Procedural UV spheres & checker floor (GpuOnly vertex/index buffers)
// - Cook-Torrance GGX PBR (2x5 metallic/dielectric x roughness grid)
// - Procedural HDR Cubemap skybox + environment IBL reflection/diffuse
// - Depth-only Depth24Stencil8 shadow map + 3x3 PCF (CompareOp::LessEqual + ClampToBorder)
// - HDR RGBA16F forward + 2-pass separable Gaussian Bloom + ACES tone map -> RGBA8Srgb
// - Default headless verification; pass `--window` for interactive WASD/Q/E/mouse camera

///|
fn build_scene_mesh() -> (FixedArray[Float], FixedArray[UInt16], Int) {
  let stacks = 18
  let slices = 28
  let vdata : Array[Float] = []
  let idata : Array[UInt16] = []
  let pi = 3.141592653589793
  for st = 0; st <= stacks; st = st + 1 {
    let v = st.to_double() / stacks.to_double()
    let phi = v * pi
    let (sp, cp) = (@math.sin(phi), @math.cos(phi))
    for sl = 0; sl <= slices; sl = sl + 1 {
      let u = sl.to_double() / slices.to_double()
      let theta = u * 2.0 * pi
      let (st_h, ct_h) = (@math.sin(theta), @math.cos(theta))
      let nx = sp * ct_h
      let ny = cp
      let nz = sp * st_h
      vdata.push(Float::from_double(nx))
      vdata.push(Float::from_double(ny))
      vdata.push(Float::from_double(nz))
      vdata.push(Float::from_double(nx))
      vdata.push(Float::from_double(ny))
      vdata.push(Float::from_double(nz))
      vdata.push(Float::from_double(u))
      vdata.push(Float::from_double(v))
    }
  }
  let ring = slices + 1
  for st = 0; st < stacks; st = st + 1 {
    for sl = 0; sl < slices; sl = sl + 1 {
      let i0 = st * ring + sl
      let i1 = i0 + 1
      let i2 = i0 + ring
      let i3 = i2 + 1
      // CCW outward winding
      idata.push(i0.to_uint16())
      idata.push(i1.to_uint16())
      idata.push(i2.to_uint16())
      idata.push(i1.to_uint16())
      idata.push(i3.to_uint16())
      idata.push(i2.to_uint16())
    }
  }
  let sphere_idx_count = idata.length()
  let base_v = (stacks + 1) * (slices + 1)
  // Ground plane at y = 0 (scaled & shifted via push constant)
  let ground_verts : Array[Float] = [
    -1.0, 0.0, 1.0, 0.0, 1.0, 0.0, 0.0, 0.0,
    1.0, 0.0, 1.0, 0.0, 1.0, 0.0, 1.0, 0.0,
    1.0, 0.0, -1.0, 0.0, 1.0, 0.0, 1.0, 1.0,
    -1.0, 0.0, -1.0, 0.0, 1.0, 0.0, 0.0, 1.0,
  ]
  for x in ground_verts {
    vdata.push(x)
  }
  let g_idx : Array[Int] = [0, 1, 2, 0, 2, 3]
  for idx in g_idx {
    idata.push((base_v + idx).to_uint16())
  }
  (
    FixedArray::makei(vdata.length(), fn(i) { vdata[i] }),
    FixedArray::makei(idata.length(), fn(i) { idata[i] }),
    sphere_idx_count,
  )
}

///|
fn cube_dir(face : Int, u : Double, v : Double) -> @dmath.DVec3 {
  let raw = match face {
    0 => @dmath.DVec3::new(1.0, -v, -u)
    1 => @dmath.DVec3::new(-1.0, -v, u)
    2 => @dmath.DVec3::new(u, 1.0, v)
    3 => @dmath.DVec3::new(u, -1.0, -v)
    4 => @dmath.DVec3::new(u, -v, 1.0)
    _ => @dmath.DVec3::new(-u, -v, -1.0)
  }
  raw.normalize()
}

///|
fn make_env_cubemap(sun_dir : @dmath.DVec3) -> Array[Bytes] {
  let sz = 32
  let faces : Array[Bytes] = []
  for f = 0; f < 6; f = f + 1 {
    let arr = FixedArray::make(sz * sz * 4, (0 : Byte))
    for y = 0; y < sz; y = y + 1 {
      let v = (y.to_double() + 0.5) / sz.to_double() * 2.0 - 1.0
      for x = 0; x < sz; x = x + 1 {
        let u = (x.to_double() + 0.5) / sz.to_double() * 2.0 - 1.0
        let d = cube_dir(f, u, v)
        let (r, g, b) = if d.y >= 0.0 {
          let t = d.y
          let rr = 0.85 * (1.0 - t) + 0.16 * t
          let gg = 0.58 * (1.0 - t) + 0.34 * t
          let bb = 0.42 * (1.0 - t) + 0.78 * t
          let sd = d.dot(sun_dir)
          let sun = if sd > 0.0 { sd * sd * sd * sd * sd * sd * 0.45 } else { 0.0 }
          (rr + sun, gg + sun * 0.9, bb + sun * 0.6)
        } else {
          let t = -d.y
          (0.26 * (1.0 - t) + 0.09 * t, 0.24 * (1.0 - t) + 0.10 * t, 0.28 * (1.0 - t) + 0.13 * t)
        }
        let clamp255 = fn(val : Double) {
          let c = if val < 0.0 { 0.0 } else if val > 1.0 { 1.0 } else { val }
          (c * 255.0).to_int().to_byte()
        }
        let i = (y * sz + x) * 4
        arr[i] = clamp255(r)
        arr[i + 1] = clamp255(g)
        arr[i + 2] = clamp255(b)
        arr[i + 3] = (255 : Byte)
      }
    }
    faces.push(Bytes::from_array(arr))
  }
  faces
}

///|
fn main {
  try {
    let show_win = @tycho.want_window()
    let shot = @tycho.screenshot_path()
    let (hdr_test, hw, hh) = @tycho.load_hdr_image("shader/testdata/test_2x2.hdr")
    let hdr_ok = hw == 2 && hh == 2 && hdr_test.length() == 16 && hdr_test[0] > (3.5 : Float)

    let dev = @tycho.Device::new_desc(
      @tycho.DeviceDesc::new("49-rhi-pbr-showcase", validation=true, headless=!show_win),
    )

    let (verts, indices, sphere_idx_count) = build_scene_mesh()
    let vbuf = dev.create_buffer_with(
      verts.length() * 4,
      @tycho.BufferKind::Vertex,
      location=@tycho.MemoryLocation::GpuOnly,
    )
    vbuf.upload_floats(verts)
    let ibuf = dev.create_buffer_with(
      indices.length() * 2,
      @tycho.BufferKind::Index,
      location=@tycho.MemoryLocation::GpuOnly,
    )
    ibuf.upload_uint16(indices)

    let sun_dir = @dmath.DVec3::new(4.0, 3.6, -2.2).normalize()
    let env_cube = dev.create_cubemap(
      32,
      @tycho.TextureFormat::RGBA8,
      make_env_cubemap(sun_dir),
    )
    let env_samp = dev.create_sampler_desc(
      @tycho.SamplerDesc::new(
        mag=@tycho.Filter::Linear,
        min=@tycho.Filter::Linear,
        mipmap=@tycho.Filter::Nearest,
        address=@tycho.AddressMode::ClampToEdge,
      ),
    )
    let shadow_samp = dev.create_sampler_desc(
      @tycho.SamplerDesc::new(
        mag=@tycho.Filter::Linear,
        min=@tycho.Filter::Linear,
        mipmap=@tycho.Filter::Nearest,
        address=@tycho.AddressMode::ClampToBorder,
        border_color=@tycho.BorderColor::OpaqueWhite,
        compare_op=Some(@tycho.CompareOp::LessEqual),
      ),
    )
    let lin_samp = dev.create_sampler_desc(
      @tycho.SamplerDesc::new(
        mag=@tycho.Filter::Linear,
        min=@tycho.Filter::Linear,
        mipmap=@tycho.Filter::Nearest,
        address=@tycho.AddressMode::ClampToEdge,
      ),
    )

    let shadow_vert = @tycho.compile_glsl("examples/49-rhi-pbr-showcase/shadow.vert", @tycho.ShaderStage::Vertex)
    let sky_vert = @tycho.compile_glsl("examples/49-rhi-pbr-showcase/skybox.vert", @tycho.ShaderStage::Vertex)
    let sky_frag = @tycho.compile_glsl("examples/49-rhi-pbr-showcase/skybox.frag", @tycho.ShaderStage::Fragment)
    let pbr_vert = @tycho.compile_glsl("examples/49-rhi-pbr-showcase/pbr.vert", @tycho.ShaderStage::Vertex)
    let pbr_frag = @tycho.compile_glsl("examples/49-rhi-pbr-showcase/pbr.frag", @tycho.ShaderStage::Fragment)
    let fs_vert = @tycho.compile_glsl("examples/49-rhi-pbr-showcase/fullscreen.vert", @tycho.ShaderStage::Vertex)
    let be_frag = @tycho.compile_glsl("examples/49-rhi-pbr-showcase/bloom_extract.frag", @tycho.ShaderStage::Fragment)
    let bb_frag = @tycho.compile_glsl("examples/49-rhi-pbr-showcase/bloom_blur.frag", @tycho.ShaderStage::Fragment)
    let tm_frag = @tycho.compile_glsl("examples/49-rhi-pbr-showcase/tonemap.frag", @tycho.ShaderStage::Fragment)

    let mesh_layouts = [
      @tycho.VertexBufferLayout::new(
        32,
        [
          @tycho.VertexAttribute::new(0, @tycho.VertexFormat::Float3, 0),
          @tycho.VertexAttribute::new(1, @tycho.VertexFormat::Float3, 12),
          @tycho.VertexAttribute::new(2, @tycho.VertexFormat::Float2, 24),
        ],
      ),
    ]

    let shadow_pipe = dev.create_graphics_pipeline(
      @tycho.PipelineDesc::from_spirv(
        shadow_vert,
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
    let sky_pipe = dev.create_graphics_pipeline(
      @tycho.PipelineDesc::from_spirv(
        sky_vert,
        sky_frag,
        depth_format=Some(@tycho.TextureFormat::Depth32F),
        color_format=Some(@tycho.TextureFormat::RGBA16F),
      ),
    )
    let pbr_pipe = dev.create_graphics_pipeline(
      @tycho.PipelineDesc::from_spirv(
        pbr_vert,
        pbr_frag,
        depth_test=true,
        depth_write=true,
        depth_compare=@tycho.CompareOp::LessEqual,
        depth_format=Some(@tycho.TextureFormat::Depth32F),
        cull_mode=@tycho.CullMode::Back,
        front_face=@tycho.FrontFace::CounterClockwise,
        color_format=Some(@tycho.TextureFormat::RGBA16F),
        vertex_layouts=mesh_layouts,
      ),
    )
    let bloom_ext_pipe = dev.create_graphics_pipeline(
      @tycho.PipelineDesc::from_spirv(fs_vert, be_frag, color_format=Some(@tycho.TextureFormat::RGBA16F)),
    )
    let bloom_blur_pipe = dev.create_graphics_pipeline(
      @tycho.PipelineDesc::from_spirv(fs_vert, bb_frag, color_format=Some(@tycho.TextureFormat::RGBA16F)),
    )
    let tm_pipe = dev.create_graphics_pipeline(
      @tycho.PipelineDesc::from_spirv(fs_vert, tm_frag, color_format=Some(@tycho.TextureFormat::RGBA8Srgb)),
    )

    let shadow_depth = dev.create_depth_texture_format(512, 512, @tycho.TextureFormat::Depth24Stencil8)
    let hdr_rt = dev.create_render_target(800, 600, @tycho.TextureFormat::RGBA16F)
    let scene_depth = dev.create_depth_texture_format(800, 600, @tycho.TextureFormat::Depth32F)
    let bloom_a = dev.create_render_target(400, 300, @tycho.TextureFormat::RGBA16F)
    let bloom_b = dev.create_render_target(400, 300, @tycho.TextureFormat::RGBA16F)
    let srgb_rt = dev.create_render_target(800, 600, @tycho.TextureFormat::RGBA8Srgb)
    let ts = dev.create_timestamp_pool(2)

    let scene_ubo = dev.create_buffer(176, @tycho.BufferKind::Uniform)
    let sky_ubo = dev.create_buffer(80, @tycho.BufferKind::Uniform)
    // Reused across frames; reset() keeps the write cursor at the start.
    let scene_writer = @tmath.GpuPackWriter::std140(44)
    let sky_writer = @tmath.GpuPackWriter::std140(20)

    let light_vp = @dmath.dorthographic_rh(
        -4.5,
        4.5,
        -4.5,
        4.5,
        0.5,
        18.0,
        clip=@tmath.ClipSpace::Vulkan,
      ) *
      @dmath.dlook_at_rh(
        @dmath.DVec3::new(5.5, 5.0, -3.0),
        @dmath.DVec3::new(0.0, -0.4, 0.0),
        @dmath.DVec3::unit_y(),
      )
    let light_vp_f = light_vp.to_mat4().to_cols_array()

    let col_x : Array[Float] = [-2.0, -1.0, 0.0, 1.0, 2.0]
    let roughs : Array[Float] = [0.12, 0.28, 0.48, 0.70, 0.90]
    let metal_colors : Array[(Float, Float, Float)] = [
      (1.0, 0.78, 0.30),
      (0.95, 0.52, 0.36),
      (0.92, 0.94, 0.96),
      (0.35, 0.65, 0.98),
      (0.28, 0.90, 0.56),
    ]
    let diel_colors : Array[(Float, Float, Float)] = [
      (0.86, 0.14, 0.14),
      (0.94, 0.54, 0.10),
      (0.90, 0.88, 0.82),
      (0.14, 0.34, 0.88),
      (0.14, 0.74, 0.36),
    ]

    let record_scene = fn(
      cmd : @tycho.CommandBuffer,
      cam_pos : @dmath.DVec3,
      yaw : Double,
      pitch : Double,
      measure : Bool,
    ) raise @tycho.RhiError {
      let (sy, cy) = (@math.sin(yaw), @math.cos(yaw))
      let (sp, cp) = (@math.sin(pitch), @math.cos(pitch))
      let fwd = @dmath.DVec3::new(cp * cy, sp, cp * sy)
      let view = @dmath.dlook_to_rh(cam_pos, fwd, @dmath.DVec3::unit_y())
      let aspect = 800.0 / 600.0
      // focal = 1 / tan(fov_y / 2); recover the angle in double precision.
      let focal = 1.65
      let fov_y = 2.0 * @math.atan(1.0 / focal)
      let vp = @dmath.dperspective_rh(
          fov_y,
          aspect,
          0.1,
          40.0,
          clip=@tmath.ClipSpace::Vulkan,
        ) *
        view
      // Direction -> NDC matrix used by the sky pass: view rotation scaled by
      // (aspect / focal, -1 / focal) with the forward axis restored to +Z.
      let inv_rp = @dmath.DMat4::from_dmat3(
        view.to_dmat3().transpose() *
        @dmath.DMat3::from_diagonal(
          @dmath.DVec3::new(aspect / focal, -1.0 / focal, -1.0),
        ),
      )
      // std140 SceneUBO { mat4 viewProj; mat4 lightVP; vec4 camPos;
      //                   vec4 lightDir; vec4 lightColor; } = 44 floats
      scene_writer.reset()
      scene_writer.push_mat4(vp.to_mat4())
      scene_writer.push_mat4(light_vp.to_mat4())
      scene_writer.push_vec3_padded(cam_pos.to_vec3())
      scene_writer.push_vec3_padded(sun_dir.to_vec3())
      scene_writer.push_vec3_padded(@tmath.Vec3::new(4.6, 4.1, 3.5))
      scene_ubo.upload_floats(scene_writer.buffer(), count=scene_writer.length())

      // std140 SkyUBO { mat4 invRotProj; vec4 sunDir; } = 20 floats
      sky_writer.reset()
      sky_writer.push_mat4(inv_rp.to_mat4())
      sky_writer.push_vec3_padded(sun_dir.to_vec3())
      sky_ubo.upload_floats(sky_writer.buffer(), count=sky_writer.length())

      if measure {
        cmd.reset_timestamps(ts)
        cmd.write_timestamp(ts, 0, at_start=true)
      }

      // Pass 1: Depth-only Shadow Map
      cmd.begin_render_pass(
        [],
        depth=Some(@tycho.DepthTargetDesc::new(shadow_depth, load_op=@tycho.LoadOp::Clear, store_op=@tycho.StoreOp::Store)),
      )
      cmd.bind_pipeline(shadow_pipe)
      cmd.bind_vertex(0, vbuf)
      cmd.bind_index(ibuf, @tycho.IndexType::Uint16)
      let spc = FixedArray::make(20, (0.0 : Float))
      for i = 0; i < 16; i = i + 1 {
        spc[i] = light_vp_f[i]
      }
      for row = 0; row < 2; row = row + 1 {
        let zz : Float = if row == 0 { -0.75 } else { 0.75 }
        for col = 0; col < 5; col = col + 1 {
          spc[16] = col_x[col]
          spc[17] = (-0.42 : Float)
          spc[18] = zz
          spc[19] = (0.38 : Float)
          cmd.push_constants_floats(shadow_pipe, spc)
          cmd.draw_indexed(sphere_idx_count)
        }
      }
      cmd.end_render_pass()

      // Pass 2: Skybox + PBR Forward into RGBA16F
      cmd.begin_render_pass(
        [@tycho.RenderTargetDesc::new(hdr_rt, clear_color=@tycho.ClearColor::black())],
        depth=Some(@tycho.DepthTargetDesc::new(scene_depth, load_op=@tycho.LoadOp::Clear, store_op=@tycho.StoreOp::DontCare)),
      )
      cmd.bind_pipeline(sky_pipe)
      cmd.bind_uniform(sky_pipe, 0, sky_ubo)
      cmd.bind_texture(sky_pipe, 0, env_cube, env_samp)
      cmd.draw(3, 1)

      cmd.bind_pipeline(pbr_pipe)
      cmd.bind_uniform(pbr_pipe, 0, scene_ubo)
      cmd.bind_texture(pbr_pipe, 0, shadow_depth, shadow_samp)
      cmd.bind_texture(pbr_pipe, 1, env_cube, env_samp)
      cmd.bind_vertex(0, vbuf)
      cmd.bind_index(ibuf, @tycho.IndexType::Uint16)

      // Ground plane
      cmd.push_constants_floats(pbr_pipe, [
        (0.0 : Float), (-0.80 : Float), (0.0 : Float), (6.0 : Float),
        (0.3 : Float), (0.3 : Float), (0.35 : Float), (0.0 : Float),
        (0.85 : Float), (-1.0 : Float), (0.0 : Float), (0.0 : Float),
      ])
      cmd.draw_indexed_full(6, 1, sphere_idx_count, 0, 0)

      // Back metallic row + Front dielectric row
      for col = 0; col < 5; col = col + 1 {
        let (mr, mg, mb) = metal_colors[col]
        cmd.push_constants_floats(pbr_pipe, [
          col_x[col], (-0.42 : Float), (-0.75 : Float), (0.38 : Float),
          mr, mg, mb, (1.0 : Float),
          roughs[col], (0.0 : Float), (0.0 : Float), (0.0 : Float),
        ])
        cmd.draw_indexed(sphere_idx_count)
        let (dr, dg, db) = diel_colors[col]
        cmd.push_constants_floats(pbr_pipe, [
          col_x[col], (-0.42 : Float), (0.75 : Float), (0.38 : Float),
          dr, dg, db, (0.0 : Float),
          roughs[col], (0.0 : Float), (0.0 : Float), (0.0 : Float),
        ])
        cmd.draw_indexed(sphere_idx_count)
      }

      // Emissive light orb for Bloom
      cmd.push_constants_floats(pbr_pipe, [
        (2.3 : Float), (1.35 : Float), (-1.45 : Float), (0.24 : Float),
        (1.0 : Float), (0.9 : Float), (0.7 : Float), (0.0 : Float),
        (0.2 : Float), (6.0 : Float), (4.6 : Float), (2.4 : Float),
      ])
      cmd.draw_indexed(sphere_idx_count)
      cmd.end_render_pass()

      // Pass 3: Bloom extract + separable H/V blur
      cmd.begin_render_pass([@tycho.RenderTargetDesc::new(bloom_a, clear_color=@tycho.ClearColor::black())])
      cmd.bind_pipeline(bloom_ext_pipe)
      cmd.bind_texture(bloom_ext_pipe, 0, hdr_rt, lin_samp)
      cmd.draw(3, 1)
      cmd.end_render_pass()

      cmd.begin_render_pass([@tycho.RenderTargetDesc::new(bloom_b, clear_color=@tycho.ClearColor::black())])
      cmd.bind_pipeline(bloom_blur_pipe)
      cmd.bind_texture(bloom_blur_pipe, 0, bloom_a, lin_samp)
      cmd.push_constants_floats(bloom_blur_pipe, [(1.0 / 400.0 : Float), (0.0 : Float), (0.0 : Float), (0.0 : Float)])
      cmd.draw(3, 1)
      cmd.end_render_pass()

      cmd.begin_render_pass([@tycho.RenderTargetDesc::new(bloom_a, clear_color=@tycho.ClearColor::black())])
      cmd.bind_pipeline(bloom_blur_pipe)
      cmd.bind_texture(bloom_blur_pipe, 0, bloom_b, lin_samp)
      cmd.push_constants_floats(bloom_blur_pipe, [(0.0 : Float), (1.0 / 300.0 : Float), (0.0 : Float), (0.0 : Float)])
      cmd.draw(3, 1)
      cmd.end_render_pass()

      // Pass 4: ACES Tone Mapping + Bloom -> RGBA8Srgb
      cmd.begin_render_pass([@tycho.RenderTargetDesc::new(srgb_rt, clear_color=@tycho.ClearColor::black())])
      cmd.bind_pipeline(tm_pipe)
      cmd.bind_texture(tm_pipe, 0, hdr_rt, lin_samp)
      cmd.bind_texture(tm_pipe, 1, bloom_a, lin_samp)
      cmd.draw(3, 1)
      cmd.end_render_pass()

      if measure {
        cmd.write_timestamp(ts, 1)
      }
    }

    let mut cam_pos = @dmath.DVec3::new(0.0, 1.75, 4.3)
    let mut yaw = -1.5707963
    let mut pitch = -0.36
    let cmd0 = dev.begin_commands()
    record_scene(cmd0, cam_pos, yaw, pitch, true)
    dev.end_commands(cmd0)

    let gpu_ms = ts.elapsed_ms(0, 1)
    let px = srgb_rt.readback()
    if shot != "" {
      let _ = @tycho.save_png(shot, 800, 600, px)
    }

    // Verify scene has sky, bright specular/emissive highlights, and rich RGB diversity
    let mut warm_sky = 0
    let mut bright_px = 0
    let mut green_px = 0
    let mut blue_px = 0
    for i = 0; i < 800 * 600; i = i + 4 {
      let r = px[i * 4].to_int()
      let g = px[i * 4 + 1].to_int()
      let b = px[i * 4 + 2].to_int()
      if r > 220 && g > 200 {
        bright_px = bright_px + 1
      }
      if b > 140 && b > r + 20 {
        blue_px = blue_px + 1
      }
      if g > r + 30 && g > b + 15 {
        green_px = green_px + 1
      }
      if r > 120 && g > 80 && b < 140 {
        warm_sky = warm_sky + 1
      }
    }

    if show_win {
      let sc = dev.create_swapchain("49-rhi-pbr-showcase", 800, 600)
      let mut dragging = false
      let mut last_mx = 0
      let mut last_my = 0
      let mut quit = false
      while !sc.should_close() && !quit {
        for ev in sc.poll_events() {
          match ev {
            @tycho.Event::CloseRequested => quit = true
            @tycho.Event::KeyDown(k, _) => {
              let (sy, cy) = (@math.sin(yaw), @math.cos(yaw))
              let step = 0.18
              if k == @tycho.KEY_ESCAPE {
                quit = true
              } else if k == @tycho.KEY_W {
                cam_pos = @dmath.DVec3::new(cam_pos.x + cy * step, cam_pos.y, cam_pos.z + sy * step)
              } else if k == @tycho.KEY_S {
                cam_pos = @dmath.DVec3::new(cam_pos.x - cy * step, cam_pos.y, cam_pos.z - sy * step)
              } else if k == @tycho.KEY_A {
                cam_pos = @dmath.DVec3::new(cam_pos.x + sy * step, cam_pos.y, cam_pos.z - cy * step)
              } else if k == @tycho.KEY_D {
                cam_pos = @dmath.DVec3::new(cam_pos.x - sy * step, cam_pos.y, cam_pos.z + cy * step)
              } else if k == @tycho.KEY_E {
                cam_pos = @dmath.DVec3::new(cam_pos.x, cam_pos.y + step, cam_pos.z)
              } else if k == @tycho.KEY_Q {
                cam_pos = @dmath.DVec3::new(cam_pos.x, cam_pos.y - step, cam_pos.z)
              } else if k == @tycho.KEY_LEFT {
                yaw = yaw - 0.06
              } else if k == @tycho.KEY_RIGHT {
                yaw = yaw + 0.06
              } else if k == @tycho.KEY_UP {
                pitch = if pitch + 0.05 > 1.2 { 1.2 } else { pitch + 0.05 }
              } else if k == @tycho.KEY_DOWN {
                pitch = if pitch - 0.05 < -1.2 { -1.2 } else { pitch - 0.05 }
              }
            }
            @tycho.Event::MouseDown(btn, mx, my) =>
              if btn == 1 {
                dragging = true
                last_mx = mx
                last_my = my
              }
            @tycho.Event::MouseUp(btn, _, _) => if btn == 1 { dragging = false }
            @tycho.Event::MouseMove(mx, my) =>
              if dragging {
                yaw = yaw + (mx - last_mx).to_double() * 0.006
                let np = pitch - (my - last_my).to_double() * 0.006
                pitch = if np > 1.2 { 1.2 } else if np < -1.2 { -1.2 } else { np }
                last_mx = mx
                last_my = my
              }
            _ => ()
          }
        }
        let cmd = sc.begin_frame_commands()
        record_scene(cmd, cam_pos, yaw, pitch, false)
        cmd.blit_to_swapchain(srgb_rt, sc)
        sc.end_frame(cmd)
      }
      sc.destroy()
    }

    let errs = dev.validation_errors()
    sky_ubo.destroy()
    scene_ubo.destroy()
    ts.destroy()
    srgb_rt.destroy()
    bloom_b.destroy()
    bloom_a.destroy()
    scene_depth.destroy()
    hdr_rt.destroy()
    shadow_depth.destroy()
    tm_pipe.destroy()
    bloom_blur_pipe.destroy()
    bloom_ext_pipe.destroy()
    pbr_pipe.destroy()
    sky_pipe.destroy()
    shadow_pipe.destroy()
    lin_samp.destroy()
    shadow_samp.destroy()
    env_samp.destroy()
    env_cube.destroy()
    ibuf.destroy()
    vbuf.destroy()
    dev.destroy()

    let visual_ok = hdr_ok && bright_px > 50 && green_px > 50 && blue_px > 50 && warm_sky > 100
    println(
      "[49-rhi-pbr-showcase] hdr_ok=\{hdr_ok} gpu_ms=\{gpu_ms} bright=\{bright_px} green=\{green_px} blue=\{blue_px} warm=\{warm_sky}",
    )
    if visual_ok && gpu_ms >= 0.0 && errs == 0 {
      println(
        "[49-rhi-pbr-showcase] OK — Cook-Torrance PBR + Cubemap IBL + Depth24Stencil8 PCF shadow + HDR Bloom + ACES passed in \{gpu_ms} ms (0 validation errors)",
      )
    } else {
      println(
        "[49-rhi-pbr-showcase] FAIL — visual_ok=\{visual_ok} gpu_ms=\{gpu_ms} errs=\{errs}",
      )
    }
  } catch {
    err => println("[49-rhi-pbr-showcase] FAIL — \{err}")
  }
}
