// Example 38 — Rotating 3D cube using pure-MoonBit @tycho:
// depth testing, back-face culling, index buffers, push constants, event queue,
// and GPU memory sub-allocator block sharing.

///|
fn sin_cos_approx(theta : Float) -> (Float, Float) {
  let pi : Double = 3.141592653589793
  let two_pi : Double = 6.283185307179586
  let mut x = theta.to_double() % two_pi
  if x > pi {
    x = x - two_pi
  } else if x < -pi {
    x = x + two_pi
  }
  // Reduce to [-pi/2, pi/2] for cosine sign accuracy
  let mut cos_sign : Double = 1.0
  let half_pi : Double = 1.5707963267948966
  let mut sx = x
  if sx > half_pi {
    sx = pi - sx
    cos_sign = -1.0
  } else if sx < -half_pi {
    sx = -pi - sx
    cos_sign = -1.0
  }
  let x2 = sx * sx
  let s = sx *
    (1.0 - x2 / 6.0 * (1.0 - x2 / 20.0 * (1.0 - x2 / 42.0 * (1.0 - x2 / 72.0))))
  let c = cos_sign *
    (1.0 - x2 / 2.0 * (1.0 - x2 / 12.0 * (1.0 - x2 / 30.0 * (1.0 - x2 / 56.0))))
  (Float::from_double(s), Float::from_double(c))
}

///|
fn mat4_mul(a : FixedArray[Float], b : FixedArray[Float]) -> FixedArray[Float] {
  let out = FixedArray::make(16, (0.0 : Float))
  for col = 0; col < 4; col = col + 1 {
    for row = 0; row < 4; row = row + 1 {
      let mut sum : Float = (0.0 : Float)
      for k = 0; k < 4; k = k + 1 {
        sum = sum + a[k * 4 + row] * b[col * 4 + k]
      }
      out[col * 4 + row] = sum
    }
  }
  out
}

///|
fn make_mvp(angle : Float, aspect : Float) -> FixedArray[Float] {
  // Perspective matrix for Vulkan clip space (Y flipped, depth in [0, 1])
  let f : Float = (1.7320508 : Float) // 1 / tan(30 deg)
  let near : Float = (0.1 : Float)
  let far : Float = (10.0 : Float)
  let proj = FixedArray::make(16, (0.0 : Float))
  proj[0] = f / aspect
  proj[5] = -f
  proj[10] = far / (near - far)
  proj[11] = (-1.0 : Float)
  proj[14] = near * far / (near - far)

  // Translation to z = -2.2
  let view = FixedArray::make(16, (0.0 : Float))
  view[0] = (1.0 : Float)
  view[5] = (1.0 : Float)
  view[10] = (1.0 : Float)
  view[14] = (-2.2 : Float)
  view[15] = (1.0 : Float)

  // Y rotation * X rotation
  let (sy, cy) = sin_cos_approx(angle)
  let (sx, cx) = sin_cos_approx(angle * (0.6 : Float))
  let ry = FixedArray::make(16, (0.0 : Float))
  ry[0] = cy
  ry[2] = -sy
  ry[5] = (1.0 : Float)
  ry[8] = sy
  ry[10] = cy
  ry[15] = (1.0 : Float)

  let rx = FixedArray::make(16, (0.0 : Float))
  rx[0] = (1.0 : Float)
  rx[5] = cx
  rx[6] = sx
  rx[9] = -sx
  rx[10] = cx
  rx[15] = (1.0 : Float)

  let model = mat4_mul(ry, rx)
  let mv = mat4_mul(view, model)
  mat4_mul(proj, mv)
}

///|
fn main {
  try {
    let dev = @tycho.Device::new("Tycho RHI 3D Cube", true)
    let sc = dev.create_swapchain_desc(
      @tycho.SwapchainDesc::new("Tycho RHI 3D Cube", 800, 600, depth=true),
    )
    let vert = @tycho.compile_glsl(
      "examples/38-rhi-3d-cube/shader.vert",
      @tycho.ShaderStage::Vertex,
    )
    let frag = @tycho.compile_glsl(
      "examples/38-rhi-3d-cube/shader.frag",
      @tycho.ShaderStage::Fragment,
    )
    let pipe = sc.create_pipeline_desc(
      @tycho.PipelineDesc::new(
        vert,
        frag,
        vertex_formats=[@tycho.VertexFormat::Float3, @tycho.VertexFormat::Float3],
        push_constant_size=64,
        depth_test=true,
        depth_write=true,
        cull_mode=@tycho.CullMode::Back,
        front_face=@tycho.FrontFace::CounterClockwise,
      ),
    )

    // 24 vertices (4 per face, unique normals/colors), CCW winding when viewed from outside
    let verts : FixedArray[Float] = [
      // +Z front face (Red)
      -0.5, -0.5, 0.5, 1.0, 0.1, 0.1,
      0.5, -0.5, 0.5, 1.0, 0.1, 0.1,
      0.5, 0.5, 0.5, 1.0, 0.1, 0.1,
      -0.5, 0.5, 0.5, 1.0, 0.1, 0.1,
      // -Z back face (Blue)
      0.5, -0.5, -0.5, 0.1, 0.1, 1.0,
      -0.5, -0.5, -0.5, 0.1, 0.1, 1.0,
      -0.5, 0.5, -0.5, 0.1, 0.1, 1.0,
      0.5, 0.5, -0.5, 0.1, 0.1, 1.0,
      // +X right face (Green)
      0.5, -0.5, 0.5, 0.1, 0.9, 0.2,
      0.5, -0.5, -0.5, 0.1, 0.9, 0.2,
      0.5, 0.5, -0.5, 0.1, 0.9, 0.2,
      0.5, 0.5, 0.5, 0.1, 0.9, 0.2,
      // -X left face (Yellow)
      -0.5, -0.5, -0.5, 0.9, 0.9, 0.1,
      -0.5, -0.5, 0.5, 0.9, 0.9, 0.1,
      -0.5, 0.5, 0.5, 0.9, 0.9, 0.1,
      -0.5, 0.5, -0.5, 0.9, 0.9, 0.1,
      // +Y top face (Cyan)
      -0.5, 0.5, 0.5, 0.1, 0.9, 0.9,
      0.5, 0.5, 0.5, 0.1, 0.9, 0.9,
      0.5, 0.5, -0.5, 0.1, 0.9, 0.9,
      -0.5, 0.5, -0.5, 0.1, 0.9, 0.9,
      // -Y bottom face (Magenta)
      -0.5, -0.5, -0.5, 0.9, 0.1, 0.9,
      0.5, -0.5, -0.5, 0.9, 0.1, 0.9,
      0.5, -0.5, 0.5, 0.9, 0.1, 0.9,
      -0.5, -0.5, 0.5, 0.9, 0.1, 0.9,
    ]
    let indices : FixedArray[UInt16] = [
      0, 1, 2, 0, 2, 3,
      4, 5, 6, 4, 6, 7,
      8, 9, 10, 8, 10, 11,
      12, 13, 14, 12, 14, 15,
      16, 17, 18, 16, 18, 19,
      20, 21, 22, 20, 22, 23,
    ]
    let vbuf = dev.create_buffer(verts.length() * 4, @tycho.BufferKind::Vertex)
    vbuf.upload_floats(verts)
    let ibuf = dev.create_buffer(indices.length() * 2, @tycho.BufferKind::Index)
    ibuf.upload_uint16(indices)

    let (blocks, allocs) = dev.allocator_stats()
    let start = @tycho.Swapchain::time()
    let mut pixels : FixedArray[Byte] = []
    let mut frames = 0
    let mut quit = false
    while !sc.should_close() && !quit && frames < 16 && @tycho.Swapchain::time() - start < 1.0 {
      for ev in sc.poll_events() {
        match ev {
          @tycho.Event::KeyDown(k, _) => if k == @tycho.KEY_ESCAPE { quit = true }
          _ => ()
        }
      }
      // Frame 0 uses angle=0 so the red front face faces camera cleanly for check
      let angle : Float = if frames == 0 {
        (0.0 : Float)
      } else {
        Float::from_int(frames) * (0.12 : Float)
      }
      let aspect = Float::from_int(sc.width()) / Float::from_int(sc.height())
      let mvp = make_mvp(angle, aspect)
      let cmd = sc.begin_frame()
      cmd.bind_pipeline(pipe)
      cmd.push_constants_floats(pipe, mvp)
      cmd.bind_vertex(0, vbuf)
      cmd.bind_index(ibuf, @tycho.IndexType::Uint16)
      cmd.draw_indexed(36)
      sc.end_frame(cmd)
      if frames == 0 {
        pixels = sc.readback()
      }
      frames = frames + 1
    }

    let c = (300 * 800 + 400) * 4
    let b = pixels[c].to_int()
    let g = pixels[c + 1].to_int()
    let r = pixels[c + 2].to_int()
    let errs = dev.validation_errors()
    ibuf.destroy()
    vbuf.destroy()
    pipe.destroy()
    sc.destroy()
    dev.destroy()
    println(
      "[38-rhi-3d-cube] centre RGB=(\{r},\{g},\{b}) allocator=(blocks=\{blocks}, allocs=\{allocs}) frames=\{frames}",
    )
    if r > 200 && g < 60 && b < 60 && blocks <= 2 && allocs >= 3 && errs == 0 {
      println(
        "[38-rhi-3d-cube] OK — 3D cube rendered with depth+cull+index+push_constants, shared sub-allocator blocks, 0 validation errors",
      )
    } else {
      println(
        "[38-rhi-3d-cube] FAIL — rgb=(\{r},\{g},\{b}) blocks=\{blocks} allocs=\{allocs} errs=\{errs}",
      )
    }
  } catch {
    err => println("[38-rhi-3d-cube] FAIL — \{err}")
  }
}
