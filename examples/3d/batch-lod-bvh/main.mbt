// 3d/batch-lod-bvh — port of three.js `webgl_batch_lod_bvh`
// (github.com/mrdoob/three.js, examples/webgl_batch_lod_bvh.html, snapshot
// `refs/three.js` 0.187.0).
//
// The reference demo scatters 500,000 instances of ten torus-knot geometries in
// a grid, gives each geometry five LODs, uploads one shared material and hovers
// a red highlight through a BVH-accelerated raycast. This is the same scene at
// a CI-sized instance count:
//
//   * 10 (p, q) torus-knot families x 5 authored LODs = 50 GPU meshes;
//   * one shared `LodHandle` per family, so 4096 nodes cost 10 specs, not 4096
//     per-node level arrays;
//   * one shared metal material, with the per-instance colour coming from
//     `MeshInstance::tint` (three.js `BatchedMesh.setColorAt`);
//   * `Renderer3D::pick_pixels` resolves the hovered instance through the
//     per-mesh BVH, and only that node's tint is rewritten.
//
// The headless gate renders the field, asserts instancing (few draws, thousands
// of visible nodes), asserts LOD actually cut triangles, picks the pixel under
// the cursor, highlights it red and proves the pixel changed — then restores the
// tint and proves the frame is bit-identical to the first one again.

///|
fn f_batch(i : Int) -> Float {
  Float::from_double(i.to_double())
}

///|
/// Deterministic [0, 1) hash: the reference demo uses `Math.random()`, but a
/// gate must produce the same field on every run and every driver.
fn hash_batch(i : Int, salt : Int) -> Float {
  @tmath.fract(@tmath.sin(f_batch(i) * 12.9898 + f_batch(salt) * 78.233) * 43758.5453)
}

///|
/// (tubular, radial) tessellation of the five LOD levels, highest first.
/// three.js derives them with meshoptimizer; authored levels keep the gate
/// free of an external simplifier while exercising the same distance switch.
fn lod_chain() -> Array[(Int, Int)] {
  [(96, 16), (48, 10), (24, 8), (12, 6), (8, 4)]
}

///|
/// The ten (p, q) knot families of the reference demo.
fn knot_families() -> Array[(Int, Int)] {
  [(1, 1), (1, 2), (1, 3), (1, 4), (1, 5), (2, 1), (2, 3), (3, 1), (4, 1), (5, 3)]
}

///|
fn no_node(v : @t3d.NodeId?) -> Bool {
  match v {
    Some(_) => false
    None => true
  }
}

///|
fn same_node(a : @t3d.NodeId?, b : @t3d.NodeId) -> Bool {
  match a {
    Some(n) => n == b
    None => false
  }
}

///|
/// Hover highlight colour (linear red, like the reference `highlight`).
fn highlight_color() -> @tmath.Vec4 {
  @t3d.linear(1.0, 0.02, 0.02, a=1.0)
}

///|
fn main {
  try {
    let opts = @exwin.Options::parse("3d/batch-lod-bvh")
    let show_win = opts.window
    // 64x64 = 4096 instances. The reference uses 500,000 because it can sort
    // 500k matrices on the GPU; a software rasteriser has to render every
    // visible triangle, so the port keeps the topology and shrinks the field.
    let instances : Int = 4096
    let side : Int = 64
    let dev = @tycho.Device::new_desc(
      @tycho.DeviceDesc::new(
        "3d/batch-lod-bvh",
        validation=true,
        headless=!show_win,
      ),
    )
    // Every instance is packed once for the main pass and once as a shadow
    // caster, so the object SSBO holds 2x the instance count.
    let renderer = @t3d.Renderer3D::new(
      dev,
      desc=@t3d.RendererDesc::default().with_max_objects(instances * 2 + 8),
    )
    let scene = @t3d.Scene::new()

    // ---- geometries: 10 families x 5 LODs, one shared spec per family -------
    let chain = lod_chain()
    let families = knot_families()
    let switches : Array[Float] = [30.0, 70.0, 130.0, 200.0]
    let specs : Array[@t3d.LodHandle] = []
    let lod0_tris : Int = chain[0].0 * chain[0].1 * 2
    for fi = 0; fi < families.length(); fi = fi + 1 {
      let (p, q) = families[fi]
      let levels : Array[@t3d.MeshHandle] = []
      for li = 0; li < chain.length(); li = li + 1 {
        let (tubular, radial) = chain[li]
        let mesh = @tgeo.torus_knot(
          radius=1.0,
          tube=0.4,
          tubular_segments=tubular,
          radial_segments=radial,
          p=p,
          q=q,
        )
        levels.push(renderer.upload_mesh(mesh))
      }
      specs.push(renderer.create_lod_spec(levels, switches))
    }

    // ---- one shared metal, coloured per instance by the tint -----------------
    let metal = renderer.create_material(
      @t3d.MaterialDesc::pbr(@tmath.Vec4::one(), metallic=1.0, roughness=0.8),
    )

    let spacing : Float = 3.4
    let start : Float = -(f_batch(side - 1) * 0.5) * spacing
    let nodes : Array[@t3d.NodeId] = []
    for i = 0; i < instances; i = i + 1 {
      let row = i / side
      let col = i % side
      let family = (i * 7 + i / 97) % families.length()
      let yaw = hash_batch(i, 1) * @tmath.TAU
      let tilt = (hash_batch(i, 2) - 0.5) * 1.1
      let roll = (hash_batch(i, 3) - 0.5) * 1.1
      let rotation = @tmath.Quat::from_rotation_y(yaw) *
        @tmath.Quat::from_rotation_x(tilt) *
        @tmath.Quat::from_rotation_z(roll)
      let node = renderer.create_lod_instance(
        scene,
        specs[family],
        metal,
        transform=@tmath.Transform::new(
          @tmath.Vec3::new(
            start + f_batch(col) * spacing,
            0.0,
            start + f_batch(row) * spacing,
          ),
          rotation,
          @tmath.Vec3::one(),
        ),
      )
      // Hue-only palette exactly like `color.setHSL(Math.random(), 0.6, 0.5)`.
      scene.set_instance_tint(
        node,
        @t3d.hsl(hash_batch(i, 4) * 360.0, 0.6, 0.5),
      )
      nodes.push(node)
    }

    // ---- lighting: image-based only, matching the reference -----------------
    let sun = @tmath.Vec3::new(0.35, 0.9, 0.3).normalize()
    let env = @t3d.procedural_environment_cubemap(dev, sun, size=128, samples=32)
    renderer.set_environment(env, sun, intensity=1.4)

    // The reference camera sits inside the field, a little above it, so near
    // instances resolve at full detail and the far ones fall away into LODs.
    let orbit = @t3d.OrbitCamera::new(
      target=@tmath.Vec3::new(0.0, 1.2, 0.0),
      distance=72.0,
      yaw=0.62,
      pitch=0.17,
    )
    let fov : Float = 2.0 * @tmath.atan((1.0 : Float) / (1.07 : Float))
    let cam = @t3d.Camera::perspective(fov, (800.0 : Float) / (600.0 : Float), near=0.1)
    let cam_node = scene.add_camera(cam, transform=orbit.transform())

    if !show_win {
      let rt = dev.create_render_target(800, 600, @tycho.TextureFormat::RGBA8Srgb)
      renderer.render_offscreen(rt, scene, cam_node)
      let first = rt.readback()
      let st = renderer.stats()
      let mut lit = 0
      let mut i = 0
      while i + 3 < first.length() {
        if first[i].to_int() + first[i + 1].to_int() + first[i + 2].to_int() > 30 {
          lit = lit + 1
        }
        i = i + 4
      }

      // Hover: resolve the instance under a cluster of candidate pixels, which
      // is what a pointer-move handler does frame by frame.
      let mut hovered : @t3d.NodeId? = None
      let mut hovered_px = 0
      let mut hovered_py = 0
      let mut attempt = 0
      while attempt < 60 && no_node(hovered) {
        let gx = attempt % 10
        let gy = attempt / 10
        // Start near the bottom, where the closest (highest-detail) instances
        // are, so the highlight covers a meaningful patch of pixels.
        let px : Float = 60.0 + f_batch(gx) * 76.0
        let py : Float = 540.0 - f_batch(gy) * 76.0
        match renderer.pick_pixels(
          scene,
          cam_node,
          px,
          py,
          800.0,
          600.0,
        ) {
          Some(hit) => {
            hovered = Some(hit.node)
            hovered_px = px.to_int()
            hovered_py = py.to_int()
          }
          None => ()
        }
        attempt = attempt + 1
      }

      // The hit must be one of the instanced field nodes, not a stray drawable.
      let mut known = false
      for n = 0; n < nodes.length(); n = n + 1 {
        if same_node(hovered, nodes[n]) {
          known = true
        }
      }

      let mut picked = false
      let mut tint_pixels = 0
      let mut identical = false
      match hovered {
        Some(node) => {
          picked = true
          let authored = match scene.instance_tint(node) {
            Some(t) => t
            None => @tmath.Vec4::one()
          }
          scene.set_instance_tint(node, highlight_color())
          renderer.render_offscreen(rt, scene, cam_node)
          let hl = rt.readback()
          let mut k = 0
          while k + 3 < first.length() {
            let dr = hl[k].to_int() - first[k].to_int()
            let dg = hl[k + 1].to_int() - first[k + 1].to_int()
            let db = hl[k + 2].to_int() - first[k + 2].to_int()
            if dr + dg.abs() + db.abs() > 30 {
              tint_pixels = tint_pixels + 1
            }
            k = k + 4
          }
          // Restore the authored tint: the highlight touched exactly one
          // instance record, so the frame must come back bit-for-bit.
          scene.set_instance_tint(node, authored)
          renderer.render_offscreen(rt, scene, cam_node)
          let again = rt.readback()
          identical = true
          let mut d = 0
          while d < first.length() {
            if first[d] != again[d] {
              identical = false
            }
            d = d + 1
          }
        }
        None => ()
      }

      let draws_ok = st.draw_calls <= 80
      let batch_ok = st.instance_batches >= 10
      // The camera sits inside the field: most instances are behind it, so the
      // frustum cull (and the BVH pick) never touch them.
      let culled_ok = st.visible_nodes > 400 && st.culled_nodes > 1500
      let lod_ok = st.lod_switches > 100
      let tris_ok = st.triangles * 2 < st.visible_nodes * lod0_tris
      opts.capture(800, 600, first)
      let errs = dev.validation_errors()
      println(
        "[3d/batch-lod-bvh] \{st.summary()} instances=\{instances} lod0_tris=\{lod0_tris} lit=\{lit} picked=\{picked} known=\{known} tint_pixels=\{tint_pixels} hover=(\{hovered_px},\{hovered_py}) identical=\{identical} validation=\{errs}",
      )
      if errs == 0 &&
        lit > 10000 &&
        picked &&
        known &&
        tint_pixels > 4 &&
        identical &&
        draws_ok &&
        batch_ok &&
        culled_ok &&
        lod_ok &&
        tris_ok {
        println(
          "[3d/batch-lod-bvh] OK — \{instances} LOD instances in \{st.draw_calls} draws, hover repaints \{tint_pixels} px",
        )
      } else {
        println(
          "[3d/batch-lod-bvh] FAIL — draws=\{st.draw_calls} batches=\{st.instance_batches} visible=\{st.visible_nodes} culled=\{st.culled_nodes} lod=\{st.lod_switches} tris=\{st.triangles} lit=\{lit} picked=\{picked} known=\{known} tint_pixels=\{tint_pixels} identical=\{identical} errs=\{errs}",
        )
      }
      rt.destroy()
    } else {
      let sc = @exwin_rhi.open(dev, opts)
      let mut hovered : @t3d.NodeId? = None
      let mut hovered_tint = @tmath.Vec4::one()
      while true {
        let (events, stop) = @exwin_rhi.poll(sc)
        if stop {
          break
        }
        for ev in events {
          if orbit.apply(ev) {
            scene.set_transform(cam_node.node(), orbit.transform())
          }
          match ev {
            @tycho.Event::MouseMove(mx, my) => {
              let hit = renderer.pick_pixels(
                scene,
                cam_node,
                f_batch(mx),
                f_batch(my),
                f_batch(sc.width()),
                f_batch(sc.height()),
              )
              match hit {
                Some(h) =>
                  if !same_node(hovered, h.node) {
                    // Leave the previous instance exactly as authored.
                    match hovered {
                      Some(prev) => scene.set_instance_tint(prev, hovered_tint)
                      None => ()
                    }
                    hovered_tint = match scene.instance_tint(h.node) {
                      Some(t) => t
                      None => @tmath.Vec4::one()
                    }
                    scene.set_instance_tint(h.node, highlight_color())
                    hovered = Some(h.node)
                  }
                None =>
                  match hovered {
                    Some(prev) => {
                      scene.set_instance_tint(prev, hovered_tint)
                      hovered = None
                    }
                    None => ()
                  }
              }
            }
            _ => ()
          }
        }
        renderer.render_swapchain(sc, scene, cam_node)
      }
      sc.destroy()
    }

    let errs = dev.validation_errors()
    renderer.destroy()
    env.destroy()
    let leaks = dev.allocator_used_bytes()
    dev.destroy()
    if leaks != (0 : UInt64) {
      println("[3d/batch-lod-bvh] LEAK — \{leaks} bytes after destroy")
    }
    if errs != 0 {
      println("[3d/batch-lod-bvh] validation errors: \{errs}")
    }
  } catch {
    err => println("[3d/batch-lod-bvh] FAIL — \{err}")
  }
}
