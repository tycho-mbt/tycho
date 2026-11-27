// rhi/shadow-hdr — End-to-end 3D Shadow Map + HDR -> sRGB verification:
// 1. Parses `examples/assets/scene.obj` (v/vt/vn/f) and loads `examples/assets/checker16.bmp`
// 2. Creates a 2-layer Texture2DArray (layer 0 = BMP checker, layer 1 = patched via upload_subregion)
// 3. Pass 1: Depth-only shadow map into Depth24Stencil8 (depth_only=true, depth_bias=true)
// 4. Pass 2: HDR lighting into RGBA16F + Depth32F with CompareOp::LessEqual + ClampToBorder(OpaqueWhite)
// 5. Pass 3: Tone mapping into RGBA8Srgb + strict pixel probes (shadowed, lit, border, subregion)

///|
fn parse_int_slice(b : Bytes, start : Int32, end : Int32) -> Int32 {
  let mut i = start
  let mut sign = 1
  if i < end && b[i] == b'-' {
    sign = -1
    i = i + 1
  }
  let mut acc = 0
  while i < end {
    let c = b[i].to_int()
    if c >= 48 && c <= 57 {
      acc = acc * 10 + (c - 48)
    }
    i = i + 1
  }
  acc * sign
}

///|
fn parse_float_slice(b : Bytes, start : Int32, end : Int32) -> Float {
  let mut i = start
  let mut sign = 1.0
  if i < end && b[i] == b'-' {
    sign = -1.0
    i = i + 1
  } else if i < end && b[i] == b'+' {
    i = i + 1
  }
  let mut int_part = 0.0
  while i < end && b[i] != b'.' {
    let c = b[i].to_int()
    if c >= 48 && c <= 57 {
      int_part = int_part * 10.0 + (c - 48).to_double()
    }
    i = i + 1
  }
  let mut frac_part = 0.0
  let mut scale = 1.0
  if i < end && b[i] == b'.' {
    i = i + 1
    while i < end {
      let c = b[i].to_int()
      if c >= 48 && c <= 57 {
        frac_part = frac_part * 10.0 + (c - 48).to_double()
        scale = scale * 10.0
      }
      i = i + 1
    }
  }
  Float::from_double(sign * (int_part + frac_part / scale))
}

///|
fn split_tokens(b : Bytes, start : Int32, end : Int32) -> Array[(Int32, Int32)] {
  let out : Array[(Int32, Int32)] = []
  let mut i = start
  while i < end {
    while i < end && (b[i] == b' ' || b[i] == b'\t' || b[i] == b'\r') {
      i = i + 1
    }
    if i < end {
      let ts = i
      while i < end && b[i] != b' ' && b[i] != b'\t' && b[i] != b'\r' {
        i = i + 1
      }
      out.push((ts, i))
    }
  }
  out
}

///|
fn parse_obj(b : Bytes) -> Array[Float] {
  let pos : Array[(Float, Float, Float)] = []
  let uv : Array[(Float, Float)] = []
  let norm : Array[(Float, Float, Float)] = []
  let verts : Array[Float] = []
  let n = b.length()
  let mut line_start = 0
  while line_start < n {
    let mut line_end = line_start
    while line_end < n && b[line_end] != b'\n' {
      line_end = line_end + 1
    }
    let toks = split_tokens(b, line_start, line_end)
    if toks.length() >= 3 {
      let (s0, e0) = toks[0]
      let len0 = e0 - s0
      if len0 == 1 && b[s0] == b'v' && toks.length() >= 4 {
        let (s1, e1) = toks[1]
        let (s2, e2) = toks[2]
        let (s3, e3) = toks[3]
        pos.push(
          (
            parse_float_slice(b, s1, e1),
            parse_float_slice(b, s2, e2),
            parse_float_slice(b, s3, e3),
          ),
        )
      } else if len0 == 2 &&
        b[s0] == b'v' &&
        b[s0 + 1] == b't' &&
        toks.length() >= 3 {
        let (s1, e1) = toks[1]
        let (s2, e2) = toks[2]
        uv.push((parse_float_slice(b, s1, e1), parse_float_slice(b, s2, e2)))
      } else if len0 == 2 &&
        b[s0] == b'v' &&
        b[s0 + 1] == b'n' &&
        toks.length() >= 4 {
        let (s1, e1) = toks[1]
        let (s2, e2) = toks[2]
        let (s3, e3) = toks[3]
        norm.push(
          (
            parse_float_slice(b, s1, e1),
            parse_float_slice(b, s2, e2),
            parse_float_slice(b, s3, e3),
          ),
        )
      } else if len0 == 1 && b[s0] == b'f' && toks.length() >= 4 {
        for ti = 1; ti <= 3; ti = ti + 1 {
          let (ts, te) = toks[ti]
          let mut slash1 = ts
          while slash1 < te && b[slash1] != b'/' {
            slash1 = slash1 + 1
          }
          let mut slash2 = slash1 + 1
          while slash2 < te && b[slash2] != b'/' {
            slash2 = slash2 + 1
          }
          let vi = parse_int_slice(b, ts, slash1) - 1
          let vti = parse_int_slice(b, slash1 + 1, slash2) - 1
          let vni = parse_int_slice(b, slash2 + 1, te) - 1
          let (px, py, pz) = pos[vi]
          let (tu, tv) = uv[vti]
          let (nx, ny, nz) = norm[vni]
          verts.push(px)
          verts.push(py)
          verts.push(pz)
          verts.push(tu)
          verts.push(tv)
          verts.push(nx)
          verts.push(ny)
          verts.push(nz)
        }
      }
    }
    line_start = line_end + 1
  }
  verts
}

///|
fn project_px(
  vp : @dmath.DMat4,
  p : @dmath.DVec3,
  w : Int32,
  h : Int32,
) -> (Int32, Int32, Bool) {
  let v = vp.mul_vec4(p.extend_w(1.0))
  let nx = v.x / v.w
  let ny = v.y / v.w
  let px = ((nx * 0.5 + 0.5) * w.to_double()).to_int()
  let py = ((ny * 0.5 + 0.5) * h.to_double()).to_int()
  let ok = px >= 4 && px < w - 4 && py >= 4 && py < h - 4
  (px, py, ok)
}

///|
fn sample_rgba(
  pixels : FixedArray[Byte],
  w : Int32,
  x : Int32,
  y : Int32,
) -> (Int32, Int32, Int32) {
  let i = (y * w + x) * 4
  (pixels[i].to_int(), pixels[i + 1].to_int(), pixels[i + 2].to_int())
}

///|
fn should_quit(sc : @tycho.Swapchain) -> Bool {
  if sc.should_close() {
    return true
  }
  for ev in sc.poll_events() {
    match ev {
      @tycho.Event::KeyDown(k, _) => if k == @tycho.KEY_ESCAPE { return true }
      _ => ()
    }
  }
  false
}

///|
fn main {
  try {
    let show_win = @tycho.want_window()
    let shot = @tycho.screenshot_path()
    let dev = @tycho.Device::new_desc(
      @tycho.DeviceDesc::new(
        "Tycho RHI Shadow HDR",
        validation=true,
        headless=!show_win,
      ),
    )

    let obj_bytes = @tycho.read_file_bytes("examples/assets/scene.obj")
    let obj_floats = parse_obj(obj_bytes)
    let vertex_count = obj_floats.length() / 8
    let obj_ok = obj_bytes.length() > 0 && vertex_count == 36
    let vbuf_arr = FixedArray::makei(obj_floats.length(), fn(i) {
      obj_floats[i]
    })
    let vbuf = dev.create_buffer_with(
      obj_floats.length() * 4,
      @tycho.BufferKind::Vertex,
      location=@tycho.MemoryLocation::GpuOnly,
    )
    vbuf.upload_floats(vbuf_arr)

    let (bmp_px, bmp_w, bmp_h) = @tycho.load_image(
      "examples/assets/checker16.bmp",
    )
    let bmp_ok = bmp_w == 16 && bmp_h == 16 && bmp_px.length() == 1024
    let layer_bytes = Bytes::makei(1024 * 2, fn(i) {
      if i < 1024 {
        bmp_px[i]
      } else {
        (10 : Byte)
      }
    })
    let tex_array = dev.create_texture_array(
      16,
      16,
      2,
      @tycho.TextureFormat::RGBA8,
      layer_bytes,
    )
    // Patch center 8x8 region (4..12, 4..12) on layer 1 with bright green
    let green_patch = Bytes::makei(8 * 8 * 4, fn(i) {
      let c = i % 4
      if c == 1 {
        (240 : Byte)
      } else if c == 3 {
        (255 : Byte)
      } else {
        (20 : Byte)
      }
    })
    tex_array.upload_subregion(4, 4, 8, 8, green_patch, layer=1)

    let obj_layouts = [
      @tycho.VertexBufferLayout::new(32, [
        @tycho.VertexAttribute::new(0, @tycho.VertexFormat::Float3, 0),
        @tycho.VertexAttribute::new(1, @tycho.VertexFormat::Float2, 12),
        @tycho.VertexAttribute::new(2, @tycho.VertexFormat::Float3, 20),
      ]),
    ]

    let shadow_vert = @tycho.compile_glsl(
      "examples/rhi/shadow-hdr/shadow.vert",
      @tycho.ShaderStage::Vertex,
    )
    let lit_vert = @tycho.compile_glsl(
      "examples/rhi/shadow-hdr/lit.vert",
      @tycho.ShaderStage::Vertex,
    )
    let lit_frag = @tycho.compile_glsl(
      "examples/rhi/shadow-hdr/lit.frag",
      @tycho.ShaderStage::Fragment,
    )
    let tm_vert = @tycho.compile_glsl(
      "examples/rhi/shadow-hdr/tonemap.vert",
      @tycho.ShaderStage::Vertex,
    )
    let tm_frag = @tycho.compile_glsl(
      "examples/rhi/shadow-hdr/tonemap.frag",
      @tycho.ShaderStage::Fragment,
    )

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
        vertex_layouts=obj_layouts,
      ),
    )
    let lit_pipe = dev.create_graphics_pipeline(
      @tycho.PipelineDesc::from_spirv(
        lit_vert,
        lit_frag,
        depth_test=true,
        depth_write=true,
        depth_compare=@tycho.CompareOp::LessEqual,
        depth_format=Some(@tycho.TextureFormat::Depth32F),
        color_format=Some(@tycho.TextureFormat::RGBA16F),
        vertex_layouts=obj_layouts,
      ),
    )
    let tm_pipe = dev.create_graphics_pipeline(
      @tycho.PipelineDesc::from_spirv(
        tm_vert,
        tm_frag,
        color_format=Some(@tycho.TextureFormat::RGBA8Srgb),
      ),
    )

    let shadow_depth = dev.create_depth_texture_format(
      512,
      512,
      @tycho.TextureFormat::Depth24Stencil8,
    )
    let hdr_rt = dev.create_render_target(
      256,
      256,
      @tycho.TextureFormat::RGBA16F,
    )
    let scene_depth = dev.create_depth_texture_format(
      256,
      256,
      @tycho.TextureFormat::Depth32F,
    )
    let srgb_rt = dev.create_render_target(
      256,
      256,
      @tycho.TextureFormat::RGBA8Srgb,
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
    let color_samp = dev.create_sampler_desc(
      @tycho.SamplerDesc::new(
        mag=@tycho.Filter::Nearest,
        min=@tycho.Filter::Nearest,
        mipmap=@tycho.Filter::Nearest,
        address=@tycho.AddressMode::Repeat,
      ),
    )

    // The camera was authored as `f = 1 / tan(fov_y / 2) = 1.4`; recover the
    // angle in double precision so the matrix matches bit-for-bit.
    let fov_y = 2.0 * @math.atan(1.0 / 1.4)
    let cam_vp = @dmath.dperspective_rh(
        fov_y,
        1.0,
        0.2,
        20.0,
        clip=@tmath.ClipSpace::Vulkan,
      ) *
      @dmath.dlook_at_rh(
        @dmath.DVec3::new(0.0, 3.0, 4.8),
        @dmath.DVec3::new(0.0, -0.3, 0.0),
        @dmath.DVec3::unit_y(),
      )
    let light_pos = @dmath.DVec3::new(-2.0, 2.0, 0.8)
    let light_vp = @dmath.dorthographic_rh(
        -1.25,
        1.25,
        -1.25,
        1.25,
        0.1,
        10.0,
        clip=@tmath.ClipSpace::Vulkan,
      ) *
      @dmath.dlook_at_rh(light_pos, @dmath.DVec3::zero(), @dmath.DVec3::unit_z())
    let ldir = light_pos.normalize()

    // std140 SceneUBO { mat4 viewProj; mat4 lightVP; vec4 lightDir; } = 36 floats
    let scene_writer = @tmath.GpuPackWriter::std140(36)
    scene_writer.push_mat4(cam_vp.to_mat4())
    scene_writer.push_mat4(light_vp.to_mat4())
    scene_writer.push_vec3_padded(ldir.to_vec3())

    let scene_ubo = dev.create_buffer(144, @tycho.BufferKind::Uniform)
    scene_ubo.upload_floats(scene_writer.buffer(), count=scene_writer.length())

    let cmd = dev.begin_commands()
    // Pass 1: Depth-only shadow map into Depth24Stencil8
    cmd.begin_render_pass(
      [],
      depth=Some(
        @tycho.DepthTargetDesc::new(
          shadow_depth,
          load_op=@tycho.LoadOp::Clear,
          store_op=@tycho.StoreOp::Store,
          clear_depth=(1.0 : Float),
        ),
      ),
    )
    cmd.bind_pipeline(shadow_pipe)
    cmd.bind_vertex(0, vbuf)
    cmd.push_constants_mat4(shadow_pipe, light_vp.to_mat4())
    cmd.draw(vertex_count, 1)
    cmd.end_render_pass()

    // Pass 2: HDR forward lighting into RGBA16F
    cmd.begin_render_pass(
      [
        @tycho.RenderTargetDesc::new(
          hdr_rt,
          clear_color=@tycho.ClearColor::rgba(0.02, 0.02, 0.04, 1.0),
        ),
      ],
      depth=Some(
        @tycho.DepthTargetDesc::new(
          scene_depth,
          load_op=@tycho.LoadOp::Clear,
          store_op=@tycho.StoreOp::DontCare,
          clear_depth=(1.0 : Float),
        ),
      ),
    )
    cmd.bind_pipeline(lit_pipe)
    cmd.bind_uniform(lit_pipe, 0, scene_ubo)
    cmd.bind_texture(lit_pipe, 0, shadow_depth, shadow_samp)
    cmd.bind_texture(lit_pipe, 1, tex_array, color_samp)
    cmd.bind_vertex(0, vbuf)
    cmd.draw(vertex_count, 1)
    cmd.end_render_pass()

    // Pass 3: Tone map HDR -> RGBA8Srgb
    cmd.begin_render_pass([
      @tycho.RenderTargetDesc::new(
        srgb_rt,
        clear_color=@tycho.ClearColor::black(),
      ),
    ])
    cmd.bind_pipeline(tm_pipe)
    cmd.bind_texture(tm_pipe, 0, hdr_rt, color_samp)
    cmd.draw(3, 1)
    cmd.end_render_pass()
    dev.end_commands(cmd)

    let px = srgb_rt.readback()
    if shot != "" {
      let _ = @tycho.save_png(shot, 256, 256, px)
    }
    if show_win {
      let sc = dev.create_swapchain("rhi/shadow-hdr", 768, 768)
      while !should_quit(sc) {
        sc.present_texture(srgb_rt)
      }
      sc.destroy()
    }
    // World probes:
    //   A (0.80, -0.50, 0.00): shadowed ground behind occluder
    //   B (-1.10, -0.50, 0.00): lit ground inside shadow frustum
    //   C (1.70, -0.50, 1.70): lit ground OUTSIDE shadow frustum (tests ClampToBorder OpaqueWhite)
    //   D (-0.25, 0.20, 0.35): occluder front face (tests Texture2DArray layer 1 upload_subregion green patch)
    let (ax, ay, a_in) = project_px(cam_vp, @dmath.DVec3::new(0.80, -0.50, 0.00), 256, 256)
    let (bx, by, b_in) = project_px(cam_vp, @dmath.DVec3::new(-1.10, -0.50, 0.00), 256, 256)
    let (cx, cy, c_in) = project_px(cam_vp, @dmath.DVec3::new(1.70, -0.50, 1.70), 256, 256)
    let (dx, dy, d_in) = project_px(cam_vp, @dmath.DVec3::new(-0.25, 0.20, 0.35), 256, 256)

    let (ar, ag, ab) = sample_rgba(px, 256, ax, ay)
    let (br, bg, bb) = sample_rgba(px, 256, bx, by)
    let (cr, cg, cb) = sample_rgba(px, 256, cx, cy)
    let (dr, dg, db) = sample_rgba(px, 256, dx, dy)

    let a_luma = ar + ag + ab
    let b_luma = br + bg + bb
    let c_luma = cr + cg + cb
    let shadow_ok = a_in && b_in && b_luma > a_luma + 180 && a_luma < 260
    let border_ok = c_in && c_luma > a_luma + 180
    let subreg_ok = d_in && dg > dr + 60 && dg > db + 60

    let errs = dev.validation_errors()
    scene_ubo.destroy()
    color_samp.destroy()
    shadow_samp.destroy()
    srgb_rt.destroy()
    scene_depth.destroy()
    hdr_rt.destroy()
    shadow_depth.destroy()
    tm_pipe.destroy()
    lit_pipe.destroy()
    shadow_pipe.destroy()
    tex_array.destroy()
    vbuf.destroy()
    dev.destroy()

    println(
      "[rhi/shadow-hdr] probes A@(\{ax},\{ay})=(\{ar},\{ag},\{ab}) B@(\{bx},\{by})=(\{br},\{bg},\{bb}) C@(\{cx},\{cy})=(\{cr},\{cg},\{cb}) D@(\{dx},\{dy})=(\{dr},\{dg},\{db})",
    )
    if obj_ok && bmp_ok && shadow_ok && border_ok && subreg_ok && errs == 0 {
      println(
        "[rhi/shadow-hdr] OK — OBJ + BMP + Texture2DArray + upload_subregion + depth_only(Depth24Stencil8) + shadow(ClampToBorder) + RGBA16F->RGBA8Srgb passed (0 validation errors)",
      )
    } else {
      println(
        "[rhi/shadow-hdr] FAIL — obj=\{obj_ok} bmp=\{bmp_ok} shadow=\{shadow_ok} border=\{border_ok} subreg=\{subreg_ok} errs=\{errs}",
      )
    }
  } catch {
    err => println("[rhi/shadow-hdr] FAIL — \{err}")
  }
}
