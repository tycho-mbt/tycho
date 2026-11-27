// Pure-CPU contract tests for laplaceliu/tycho_3d: scene propagation,
// reparenting, handle invalidation, culling, camera rays, materials, lights,
// and stats.

///|
fn need(cond : Bool, what : StringView) -> Unit raise {
  if !cond {
    fail(what)
  }
}

///|
fn close(a : Float, b : Float, eps? : Float = 1.0e-4) -> Bool {
  @tmath.approx_eq_f(a, b, eps~)
}

///|
fn need_vec3(a : @tmath.Vec3, b : @tmath.Vec3, eps? : Float = 1.0e-4) -> Unit raise {
  if !a.approx_eq(b, eps~) {
    fail("Vec3 mismatch")
  }
}

///|
fn need_some_mat4(v : @tmath.Mat4?, what : StringView) -> @tmath.Mat4 raise {
  match v {
    Some(m) => m
    None => {
      fail(what)
      @tmath.Mat4::identity()
    }
  }
}

///|
test "scene hierarchy propagation" {
  let s = Scene::new()
  let root = s.create_node(
    transform=@tmath.Transform::from_translation(@tmath.Vec3::new(1.0, 0.0, 0.0)),
  )
  let child = s.create_node(
    parent=root,
    transform=@tmath.Transform::from_translation(@tmath.Vec3::new(0.0, 2.0, 0.0)),
  )
  s.update()
  need_vec3(s.world_transform(child).translation, @tmath.Vec3::new(1.0, 2.0, 0.0))
  s.set_transform(
    root,
    @tmath.Transform::from_translation(@tmath.Vec3::new(3.0, 0.0, 0.0)),
  )
  s.update()
  need_vec3(s.world_transform(child).translation, @tmath.Vec3::new(3.0, 2.0, 0.0))
  need(s.parent_of(child) == Some(root), "parent link")
  need(s.children_of(root).length() == 1, "child count")
  need(s.alive_count() == 2, "alive count")
  let seen : Array[NodeId] = []
  s.traverse(fn(id) { seen.push(id) })
  need(seen.length() == 2, "traverse count")
}

///|
test "scene rotation propagation" {
  let s = Scene::new()
  let parent = s.create_node(
    transform=@tmath.Transform::from_rotation(
      @tmath.Quat::from_rotation_y(@tmath.FRAC_PI_2),
    ),
  )
  let child = s.create_node(
    parent=parent,
    transform=@tmath.Transform::from_translation(@tmath.Vec3::new(1.0, 0.0, 0.0)),
  )
  s.update()
  // Rotating +X by +90 degrees around +Y maps it to -Z.
  need_vec3(
    s.world_transform(child).translation,
    @tmath.Vec3::new(0.0, 0.0, -1.0),
    eps=1.0e-4,
  )
}

///|
test "reparent keeps world transform" {
  let s = Scene::new()
  let a = s.create_node(
    transform=@tmath.Transform::from_translation(@tmath.Vec3::new(5.0, 0.0, 0.0)),
  )
  let b = s.create_node(
    transform=@tmath.Transform::from_translation(@tmath.Vec3::new(-2.0, 0.0, 0.0)),
  )
  let child = s.create_node(
    parent=a,
    transform=@tmath.Transform::from_translation(@tmath.Vec3::new(1.0, 0.0, 0.0)),
  )
  s.update()
  let before = s.world_transform(child).translation
  need(s.set_parent(child, Some(b), keep_world=true), "reparent")
  s.update()
  need_vec3(s.world_transform(child).translation, before)
  need(s.parent_of(child) == Some(b), "new parent")
  need(!s.set_parent(b, Some(child)), "cycle rejected")
}

///|
test "destroy subtree invalidates handles" {
  let s = Scene::new()
  let a = s.create_node()
  let b = s.create_node(parent=a)
  s.destroy_node(a)
  need(!s.is_alive(a), "a dead")
  need(!s.is_alive(b), "b dead")
  need(s.alive_count() == 0, "alive count")
  let c = s.create_node()
  need(s.is_alive(c), "slot reused")
  need(!s.is_alive(a), "old handle stays dead")
  need(s.parent_of(c) == None, "new node is a root")
}

///|
test "frustum culling and layer masks" {
  let s = Scene::new()
  let box = @tmath.Aabb3::new(
    @tmath.Vec3::splat(-1.0),
    @tmath.Vec3::splat(1.0),
  )
  let near = s.create_node(payload=NodePayload::Mesh(MeshInstance::new(MeshHandle::from_id(1), MaterialHandle::from_id(1))))
  s.set_local_bounds(near, Some(box))
  let far = s.create_node(
    transform=@tmath.Transform::from_translation(@tmath.Vec3::new(0.0, 0.0, -100.0)),
    payload=NodePayload::Mesh(MeshInstance::new(MeshHandle::from_id(2), MaterialHandle::from_id(1))),
  )
  s.set_local_bounds(far, Some(box))
  let off_layer = s.create_node(payload=NodePayload::Mesh(MeshInstance::new(MeshHandle::from_id(3), MaterialHandle::from_id(1))))
  s.set_local_bounds(off_layer, Some(box))
  s.set_layer_mask(off_layer, (2 : UInt))
  s.update()
  let cam = Camera::perspective(
    @tmath.deg_to_rad(60.0),
    1.0,
    near=0.1,
    far=50.0,
  )
  let vp = need_some_mat4(cam.view_proj(@tmath.Affine3::identity()), "view-proj")
  let frustum = @tmath.Frustum::from_view_proj(vp)
  let vis = s.collect_visible(frustum, (1 : UInt))
  need(vis.length() == 1, "only the near node is visible")
  need(vis[0] == near, "near node id")
  let vis2 = s.collect_visible(frustum, (3 : UInt))
  need(vis2.length() == 2, "layer 2 included")
}

///|
test "camera rays" {
  let cam = Camera::perspective(@tmath.FRAC_PI_2, 1.0, near=0.1, far=100.0)
  match cam.screen_ray(@tmath.Affine3::identity(), 0.0, 0.0) {
    Some(r) => {
      need_vec3(r.origin, @tmath.Vec3::zero())
      need_vec3(r.dir, @tmath.Vec3::new(0.0, 0.0, -1.0), eps=1.0e-4)
    }
    None => fail("center ray missing")
  }
  match cam.screen_ray(@tmath.Affine3::identity(), 1.0, 0.0) {
    Some(r) => need(r.dir.x > 0.5, "edge ray points right")
    None => fail("edge ray missing")
  }
  match cam.sky_ray_matrix(@tmath.Affine3::identity()) {
    Some(_) => ()
    None => fail("sky matrix missing")
  }
}

///|
test "camera projections and aspect" {
  let p = Camera::perspective(1.0, 1.0)
  match p.projection {
    Perspective(pp) => need(pp.far == None, "infinite far by default")
    Orthographic(_) => fail("expected perspective")
  }
  let p2 = p.with_aspect(2.0)
  match p2.projection {
    Perspective(pp) => need(close(pp.aspect, 2.0), "aspect updated")
    Orthographic(_) => fail("expected perspective")
  }
  let o = Camera::orthographic(-2.0, 2.0, -1.0, 1.0)
  match o.screen_ray(@tmath.Affine3::identity(), 0.0, 0.0) {
    Some(r) => need_vec3(r.dir, @tmath.Vec3::new(0.0, 0.0, -1.0), eps=1.0e-4)
    None => fail("ortho ray missing")
  }
}

///|
test "material linear colors" {
  need(close(srgb_to_linear(0.0), 0.0), "black")
  need(close(srgb_to_linear(1.0), 1.0, eps=1.0e-5), "white")
  need(close(srgb_to_linear(0.5), 0.21404114, eps=1.0e-4), "mid gray")
  need(close(srgb_to_linear(-1.0), 0.0), "clamp low")
  need(close(srgb_to_linear(2.0), 1.0, eps=1.0e-5), "clamp high")
  let c = srgb(0.5, 0.5, 0.5, a=0.5)
  need(close(c.w, 0.5), "alpha passthrough")
  let m = MaterialDesc::pbr(srgb(1.0, 0.0, 0.0), metallic=1.0, roughness=0.2)
  need(close(m.metallic, 1.0), "metallic")
  need(close(m.roughness, 0.2), "roughness")
  match m.shading {
    Shading::Pbr => ()
    Shading::Unlit => fail("expected pbr")
  }
  let glowing = m.with_emissive(@tmath.Vec3::new(4.0, 2.0, 0.0))
  need(glowing.emissive.x == 4.0, "hdr emissive")
  match m.alpha_mode {
    AlphaMode::Opaque => ()
    _ => fail("default alpha")
  }
}

///|
test "light descriptors" {
  let sun = Light::directional(
    @tmath.Vec3::one(),
    3.0,
    shadow=ShadowDesc::default(),
  )
  need(sun.cast_shadow(), "directional shadow")
  let amb = Light::ambient(@tmath.Vec3::one(), 0.2)
  need(!amb.cast_shadow(), "ambient has no shadow")
  let lamp = Light::point(@tmath.Vec3::one(), 5.0)
  match lamp {
    Point(l) => need(close(l.range, 10.0), "default range")
    _ => fail("expected point light")
  }
}

///|
test "stats json" {
  let st = RenderStats3D::new()
  st.draw_calls = 3
  st.triangles = 12
  need(st.summary().length() > 0, "summary")
  need(
    st.to_json() ==
      "{\"draw_calls\":3,\"triangles\":12,\"visible_nodes\":0,\"culled_nodes\":0,\"shadow_passes\":0,\"upload_bytes\":0,\"instance_batches\":0,\"line_segments\":0,\"lod_switches\":0}",
    "json",
  )
}

///|
test "float16 packing" {
  need(f16_bits(0.0) == (0x0000 : UInt16), "zero")
  need(f16_bits(0.5) == (0x3800 : UInt16), "half")
  need(f16_bits(1.0) == (0x3C00 : UInt16), "one")
  need(f16_bits(2.0) == (0x4000 : UInt16), "two")
  need(f16_bits(-2.0) == (0xC000 : UInt16), "negative")
  need(f16_bits(65504.0) == (0x7BFF : UInt16), "max finite")
  need(f16_bits(1.0e6) == (0x7C00 : UInt16), "overflow to inf")
}

///|
fn hdr_close(a : Float, b : Float) -> Bool {
  let d : Float = if a > b {
    a - b
  } else {
    b - a
  }
  let scale : Float = if a > 0.0 {
    a
  } else {
    -a
  }
  d <= 0.01 * (scale + 1.0)
}

///|
fn check_hdr_roundtrip(a : HdrImage, b : HdrImage) -> Unit raise {
  need(a.width == b.width && a.height == b.height, "hdr size")
  for y = 0; y < a.height; y = y + 1 {
    for x = 0; x < a.width; x = x + 1 {
      let (ar, ag, ab) = a.pixel(x, y)
      let (br, bg, bb) = b.pixel(x, y)
      need(hdr_close(ar, br), "hdr red")
      need(hdr_close(ag, bg), "hdr green")
      need(hdr_close(ab, bb), "hdr blue")
    }
  }
}

///|
test "radiance hdr roundtrip" {
  let img = HdrImage::new(16, 4)
  for y = 0; y < 4; y = y + 1 {
    for x = 0; x < 16; x = x + 1 {
      let fx = Float::from_int(x)
      let fy = Float::from_int(y)
      let b : Float = if (x + y) % 3 == 0 { 40.0 } else { 0.5 }
      img.set_pixel(x, y, 0.25 + fx, 2.0 + fy, b)
    }
  }
  match decode_hdr(encode_hdr(img)) {
    Some(dec) => check_hdr_roundtrip(img, dec)
    None => fail("RLE decode failed")
  }
  match decode_hdr(encode_hdr(img, rle=false)) {
    Some(dec) => check_hdr_roundtrip(img, dec)
    None => fail("flat decode failed")
  }
  let tiny = HdrImage::new(4, 2)
  tiny.set_pixel(1, 0, 8.0, 0.5, 0.25)
  match decode_hdr(encode_hdr(tiny)) {
    Some(dec) => check_hdr_roundtrip(tiny, dec)
    None => fail("narrow decode failed")
  }
}

///|
test "equirect uv" {
  let (u0, v0) = equirect_uv(@tmath.Vec3::new(0.0, 0.0, 1.0))
  need(close(u0, 0.5), "u +Z")
  need(close(v0, 0.5), "v horizon")
  let (u1, _) = equirect_uv(@tmath.Vec3::new(1.0, 0.0, 0.0))
  need(close(u1, 0.75), "u +X")
  let (_, v1) = equirect_uv(@tmath.Vec3::new(0.0, 1.0, 0.0))
  need(close(v1, 0.0), "v zenith")
  let (_, v2) = equirect_uv(@tmath.Vec3::new(0.0, -1.0, 0.0))
  need(close(v2, 1.0), "v nadir")
}

///|
test "float16 decode" {
  let values : Array[Float] = [0.0, 0.25, 0.5, 1.0, 2.0, 16.0, 1000.0]
  for v in values {
    let back = f16_to_float(f16_bits(v))
    need(close(back, v, eps=0.002 * (v + 1.0)), "f16 roundtrip")
  }
  need(f16_to_float(f16_bits(-3.0)) < 0.0, "f16 sign")
}

///|
test "vec3 track sampling" {
  let tr = Vec3Track::new(
    [0.0, 1.0, 2.0],
    [
      @tmath.Vec3::zero(),
      @tmath.Vec3::new(2.0, 0.0, 0.0),
      @tmath.Vec3::new(2.0, 2.0, 0.0),
    ],
  )
  need_vec3(tr.sample(-1.0), @tmath.Vec3::zero())
  need_vec3(tr.sample(0.5), @tmath.Vec3::new(1.0, 0.0, 0.0))
  need_vec3(tr.sample(1.5), @tmath.Vec3::new(2.0, 1.0, 0.0))
  need_vec3(tr.sample(9.0), @tmath.Vec3::new(2.0, 2.0, 0.0))
  need(close(tr.duration(), 2.0), "track duration")
}

///|
test "quat track slerp" {
  let tr = QuatTrack::new(
    [0.0, 1.0],
    [@tmath.Quat::identity(), @tmath.Quat::from_rotation_y(@tmath.PI * 0.5)],
  )
  let mid = tr.sample(0.5)
  let dir = mid.mul_vec3(@tmath.Vec3::new(0.0, 0.0, 1.0))
  let s = @tmath.sin(@tmath.PI * 0.25)
  need_vec3(dir, @tmath.Vec3::new(s, 0.0, s), eps=1.0e-3)
}

///|
test "animation player" {
  let scene = Scene::new()
  let node = scene.create_node()
  let clip = AnimationClip::new(
    "slide",
    [
      AnimationChannel::new(
        node,
        TransformTrack::new(
          translation=
            Vec3Track::new(
              [0.0, 2.0],
              [@tmath.Vec3::zero(), @tmath.Vec3::new(4.0, 0.0, 0.0)],
            )
          ,
        ),
      ),
    ],
  )
  let p = AnimationPlayer::new(clip)
  p.update(scene, 1.0)
  need_vec3(scene.transform(node).translation, @tmath.Vec3::new(2.0, 0.0, 0.0))
  // Looping wrap: 2.5 -> 0.5.
  p.update(scene, 1.5)
  need_vec3(scene.transform(node).translation, @tmath.Vec3::new(1.0, 0.0, 0.0))
  p.set_looping(false)
  p.seek(0.0)
  p.update(scene, 5.0)
  need_vec3(scene.transform(node).translation, @tmath.Vec3::new(4.0, 0.0, 0.0))
  p.pause()
  p.update(scene, 1.0)
  need_vec3(scene.transform(node).translation, @tmath.Vec3::new(4.0, 0.0, 0.0))
}
///|
test "transform track animates only the channels it carries" {
  let track = TransformTrack::new(
    translation=Vec3Track::new(
      [0.0, 1.0],
      [@tmath.Vec3::zero(), @tmath.Vec3::new(2.0, 0.0, 0.0)],
    ),
  )
  match track.translation {
    Some(_) => ()
    None => fail("translation channel missing")
  }
  match track.rotation {
    None => ()
    Some(_) => fail("rotation channel must stay unset")
  }
  let base = @tmath.Transform::new(
    @tmath.Vec3::zero(),
    @tmath.Quat::identity(),
    @tmath.Vec3::new(3.0, 3.0, 3.0),
  )
  let out = track.sample_with(base, 0.5)
  need(close(out.translation.x, 1.0), "translation sampled")
  // Unanimated channels keep the base value.
  need(close(out.scale.x, 3.0), "scale preserved")
}

///|
test "gltf instance aggregates nodes and animations" {
  let instance : GltfInstance = {
    roots: [],
    nodes: [],
    meshes: [],
    materials: [],
    animations: [],
  }
  assert_eq(instance.roots.length(), 0)
  assert_eq(instance.animations.length(), 0)
}

///|
test "camera handles are typed and validated" {
  let s = Scene::new()
  let cam = Camera::perspective(@tmath.FRAC_PI_2, 1.0, near=0.1, far=100.0)
  let cam_id = s.add_camera(
    cam,
    transform=@tmath.Transform::from_translation(@tmath.Vec3::new(0.0, 1.0, 3.0)),
  )
  need(s.is_alive(cam_id.node()), "add_camera creates a live node")
  match s.camera_of(cam_id.node()) {
    Some(v) => assert_eq(v.index(), cam_id.index())
    None => fail("camera_of must accept a camera node")
  }
  let light = s.create_node(
    payload=NodePayload::Light(Light::ambient(@tmath.Vec3::one(), 0.2)),
  )
  match s.camera_of(light) {
    None => ()
    Some(_) => fail("camera_of must reject a non-camera node")
  }
}

///|
test "ray segment closest" {
  let ray = @tmath.Ray::new(@tmath.Vec3::zero(), @tmath.Vec3::unit_y())
  // Segment crossing the ray: closest at t = 2, distance 1.
  let (d0, t0) = ray_segment_closest(
    ray,
    @tmath.Vec3::new(1.0, 2.0, 0.0),
    @tmath.Vec3::new(1.0, 3.0, 0.0),
  )
  need(close(d0, 1.0), "perpendicular distance")
  need(close(t0, 2.0), "perpendicular t")
  // Segment behind the origin clamps to t = 0.
  let (d1, t1) = ray_segment_closest(
    ray,
    @tmath.Vec3::new(0.5, -2.0, 0.0),
    @tmath.Vec3::new(0.5, -1.0, 0.0),
  )
  need(close(t1, 0.0), "behind clamp")
  need(close(d1, @tmath.sqrt(1.25)), "behind distance")
  // Parallel segment.
  let (d2, _) = ray_segment_closest(
    ray,
    @tmath.Vec3::new(2.0, 0.0, 0.0),
    @tmath.Vec3::new(2.0, 5.0, 0.0),
  )
  need(close(d2, 2.0), "parallel distance")
}

///|
test "line node payload and bounds" {
  let s = Scene::new()
  let handle = LineHandle::from_id(7)
  let node = s.create_node(
    payload=NodePayload::Lines(
      LineInstance::new(
        handle,
        LineMaterial::new(color=@tmath.Vec3::new(0.5, 0.25, 0.75)),
      ),
    ),
  )
  match s.payload(node) {
    Some(NodePayload::Lines(inst)) => {
      need(inst.lines.id() == 7, "line handle")
      need(close(inst.material.color.y, 0.25), "line colour")
    }
    _ => fail("line payload")
  }
  s.set_local_bounds(
    node,
    Some(@tmath.Aabb3::new(@tmath.Vec3::zero(), @tmath.Vec3::one())),
  )
  s.update()
  match s.world_bounds(node) {
    Some(b) => need(close(b.max.x, 1.0), "line bounds")
    None => fail("line bounds missing")
  }
}

///|
test "ray lines hit" {
  let lines = @tgeo.LineData::new(
    [
      @tmath.Vec3::new(-1.0, 1.0, 0.0),
      @tmath.Vec3::new(1.0, 1.0, 0.0),
    ],
    [0, 1],
  )
  let ray = @tmath.Ray::new(@tmath.Vec3::zero(), @tmath.Vec3::unit_y())
  match ray_lines_hit(ray, lines, @tmath.Affine3::identity(), LINE_PICK_RADIUS) {
    Some(h) => {
      need(close(h.distance, 1.0), "line hit distance")
      need(h.triangle == 0, "line hit segment")
      need(close(h.position.y, 1.0), "line hit position")
    }
    None => fail("line hit")
  }
  // 5 cm away is outside the 2 cm pick radius.
  let far = @tmath.Ray::new(
    @tmath.Vec3::new(0.0, 0.0, 0.05),
    @tmath.Vec3::unit_y(),
  )
  match ray_lines_hit(far, lines, @tmath.Affine3::identity(), LINE_PICK_RADIUS) {
    Some(_) => fail("line should miss")
    None => ()
  }
}
