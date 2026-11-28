// Pure-CPU tests for the three.js-shaped authoring layer: colors, material
// aliases, transform / look_at ergonomics, inherited visibility, scene
// structure helpers, camera pixel rays, the clock and the line helpers.

///|
test "hex and hsl authoring colors" {
  let red = hex(0xFF0000)
  need(close(red.x, 1.0, eps=1.0e-5), "hex red")
  need(close(red.y, 0.0), "hex red green")
  need(close(red.z, 0.0), "hex red blue")
  let gray = hex(0x808080)
  need(close(gray.x, 0.2158605, eps=1.0e-4), "hex mid gray is linear")
  need(close(gray.x, gray.y) && close(gray.y, gray.z), "hex gray is neutral")
  need(close(hex(0x00FF00, a=0.25).w, 0.25), "hex alpha")
  // HSL primaries must land on the same linear values as the hex form.
  need_vec3(hsl(0.0, 1.0, 0.5).truncate(), hex(0xFF0000).truncate(), eps=1.0e-5)
  need_vec3(hsl(120.0, 1.0, 0.5).truncate(), hex(0x00FF00).truncate(), eps=2.0e-5)
  need_vec3(hsl(240.0, 1.0, 0.5).truncate(), hex(0x0000FF).truncate(), eps=1.0e-5)
  // Grey has no chroma and wraps at 360.
  need_vec3(hsl(360.0, 0.0, 0.5).truncate(), hsl(0.0, 0.0, 0.5).truncate())
  need(close(hsl(0.0, 0.0, 0.5).x, srgb_to_linear(0.5), eps=1.0e-4), "hsl lightness")
  let lin = linear(2.0, 0.5, 0.0)
  need(lin.x == 2.0 && lin.y == 0.5 && lin.w == 1.0, "linear passthrough")
}

///|
test "material three.js-style aliases" {
  let m = MaterialDesc::standard(hex(0x3366FF), metallic=0.25, roughness=0.75)
  match m.shading {
    Shading::Pbr => ()
    Shading::Unlit => fail("standard is pbr")
  }
  need(close(m.metallic, (0.25 : Float)), "standard metallic")
  need(close(m.roughness, (0.75 : Float)), "standard roughness")
  let b = MaterialDesc::basic(hex(0x112233))
  match b.shading {
    Shading::Unlit => ()
    Shading::Pbr => fail("basic is unlit")
  }
  let tweaked = m.with_metallic((1.0 : Float)).with_roughness((0.1 : Float)).with_base_color(hex(0xFFFFFF))
  need(close(tweaked.metallic, (1.0 : Float)) && close(tweaked.roughness, (0.1 : Float)), "with_* factors")
  need(close(tweaked.base_color.x, (1.0 : Float), eps=1.0e-5), "with_base_color")
}

///|
test "scene transform ergonomics" {
  let s = Scene::new()
  let n = s.create_node(
    transform=@tmath.Transform::new(
      @tmath.Vec3::new(1.0, 2.0, 3.0),
      @tmath.Quat::from_rotation_y(@tmath.FRAC_PI_2),
      @tmath.Vec3::splat(2.0),
    ),
  )
  s.set_position(n, @tmath.Vec3::new(4.0, 5.0, 6.0))
  need_vec3(s.position(n), @tmath.Vec3::new(4.0, 5.0, 6.0))
  // Rotation and scale survive a position write.
  need_vec3(s.scale(n), @tmath.Vec3::splat(2.0))
  let before = s.rotation(n)
  need(close(before.w, @tmath.cos(@tmath.FRAC_PI_4), eps=1.0e-4), "rotation kept")
  s.translate(n, @tmath.Vec3::new(0.0, -1.0, 0.0))
  need_vec3(s.position(n), @tmath.Vec3::new(4.0, 4.0, 6.0))
  s.set_uniform_scale(n, (0.5 : Float))
  need_vec3(s.scale(n), @tmath.Vec3::splat(0.5))
  // Euler XYZ and rotate(): local +Y rotation maps -Z to -X.
  s.set_position(n, @tmath.Vec3::zero())
  s.set_uniform_scale(n, (1.0 : Float))
  s.set_euler(n, 0.0, @tmath.FRAC_PI_2, 0.0)
  need_vec3(
    s.direction_to_world(n, @tmath.Vec3::neg_z()),
    @tmath.Vec3::new(-1.0, 0.0, 0.0),
    eps=1.0e-4,
  )
  s.set_rotation(n, @tmath.Quat::identity())
  s.rotate(n, @tmath.Vec3::unit_y(), @tmath.FRAC_PI_2)
  need_vec3(
    s.direction_to_world(n, @tmath.Vec3::neg_z()),
    @tmath.Vec3::new(-1.0, 0.0, 0.0),
    eps=1.0e-4,
  )
  // World-axis rotation after the local one: another +90 degrees around +Y.
  s.rotate_world(n, @tmath.Vec3::unit_y(), @tmath.FRAC_PI_2)
  need_vec3(
    s.direction_to_world(n, @tmath.Vec3::neg_z()),
    @tmath.Vec3::new(0.0, 0.0, 1.0),
    eps=1.0e-4,
  )
}

///|
test "scene look_at root and under a rotated parent" {
  let s = Scene::new()
  let n = s.create_node()
  // Looking down -Z is already the identity orientation.
  s.look_at(n, @tmath.Vec3::new(0.0, 0.0, -1.0))
  need_vec3(
    s.direction_to_world(n, @tmath.Vec3::neg_z()),
    @tmath.Vec3::new(0.0, 0.0, -1.0),
    eps=1.0e-4,
  )
  // Looking towards +X.
  s.look_at(n, @tmath.Vec3::new(1.0, 0.0, 0.0))
  need_vec3(
    s.direction_to_world(n, @tmath.Vec3::neg_z()),
    @tmath.Vec3::new(1.0, 0.0, 0.0),
    eps=1.0e-4,
  )
  need_vec3(
    s.direction_to_world(n, @tmath.Vec3::unit_y()),
    @tmath.Vec3::new(0.0, 1.0, 0.0),
    eps=1.0e-4,
  )
  // The same call under a +90 degree parent must still aim at the world target.
  let parent = s.create_node(
    transform=@tmath.Transform::from_rotation(
      @tmath.Quat::from_rotation_y(@tmath.FRAC_PI_2),
    ),
  )
  let child = s.create_node(parent=parent)
  s.look_at(child, @tmath.Vec3::new(1.0, 0.0, 0.0))
  need_vec3(
    s.direction_to_world(child, @tmath.Vec3::neg_z()),
    @tmath.Vec3::new(1.0, 0.0, 0.0),
    eps=1.0e-4,
  )
  // A node sitting on the target keeps a finite rotation.
  s.look_at(child, s.world_transform(child).translation)
  let q = s.rotation(child)
  need(q.is_normalized(eps=(1.0e-3 : Float)), "degenerate look_at stays finite")
}

///|
test "group visibility hides the whole subtree" {
  let s = Scene::new()
  let box = @tmath.Aabb3::new(@tmath.Vec3::splat(-1.0), @tmath.Vec3::splat(1.0))
  let group = s.add_group()
  let child = s.create_node(
    parent=group,
    payload=NodePayload::Mesh(
      MeshInstance::new(MeshHandle::from_id(1), MaterialHandle::from_id(1)),
    ),
  )
  s.set_local_bounds(child, Some(box))
  let lamp = s.add_point_light(parent=group, intensity=(2.0 : Float))
  s.update()
  let cam = Camera::perspective(@tmath.deg_to_rad(60.0), 1.0, near=0.1, far=50.0)
  let vp = need_some_mat4(cam.view_proj(@tmath.Affine3::identity()), "view-proj")
  let frustum = @tmath.Frustum::from_view_proj(vp)
  need(s.collect_visible(frustum, (0xFFFFFFFF : UInt)).length() == 1, "visible by default")
  need(s.is_visible_in_world(child), "child visible")
  // Hiding the group hides the subtree without touching the child's own flag.
  s.set_visible(group, false)
  need(!s.is_visible_in_world(child), "child hidden through parent")
  need(!s.is_visible_in_world(lamp), "light hidden through parent")
  need(s.visible(child), "own flag untouched")
  need(s.collect_visible(frustum, (0xFFFFFFFF : UInt)).length() == 0, "subtree culled")
  s.set_visible(group, true)
  need(s.collect_visible(frustum, (0xFFFFFFFF : UInt)).length() == 1, "subtree back")
}

///|
test "scene structure helpers" {
  let s = Scene::new()
  let group = s.add_group(name="pivot")
  let a = s.create_node(parent=group, name="a")
  let _b = s.create_node(parent=group, name="b")
  need(s.child_count(group) == 2, "child count")
  need(s.name(group) == "pivot", "name getter")
  need(s.roots().length() == 1, "one root")
  need(s.find_all_by_name("a").length() == 1, "find all by name")
  // remove() detaches but keeps the node (and its subtree) alive.
  s.remove(a)
  need(s.is_alive(a), "removed node stays alive")
  need(s.roots().length() == 2, "removed node becomes a root")
  need(s.child_count(group) == 1, "group lost the child")
  need(s.parent_of(a) == None, "no parent after remove")
  // Mesh / light accessors.
  let mesh_node = s.create_node(
    payload=NodePayload::Mesh(
      MeshInstance::new(MeshHandle::from_id(2), MaterialHandle::from_id(2)),
    ),
  )
  need(s.mesh_of(mesh_node) is Some(_), "mesh_of")
  let lamp = s.add_point_light(
    position=@tmath.Vec3::new(0.0, 3.0, 0.0),
    intensity=(1.5 : Float),
  )
  need(s.light_of(lamp) is Some(_), "light_of")
  need_vec3(s.position(lamp), @tmath.Vec3::new(0.0, 3.0, 0.0))
  match s.camera_component(lamp) {
    Some(_) => fail("camera_component on a light")
    None => ()
  }
  s.clear()
  need(s.alive_count() == 0, "clear destroys everything")
  need(s.roots().length() == 0, "no roots after clear")
}

///|
test "scene local/world helpers" {
  let s = Scene::new()
  let parent = s.create_node(
    transform=@tmath.Transform::new(
      @tmath.Vec3::new(1.0, 0.0, 0.0),
      @tmath.Quat::from_rotation_y(@tmath.FRAC_PI_2),
      @tmath.Vec3::one(),
    ),
  )
  let child = s.create_node(parent=parent)
  let world = s.local_to_world(child, @tmath.Vec3::new(0.0, 0.0, -2.0))
  // -Z under a +90 degree Y rotation becomes -X, then the parent offset applies.
  need_vec3(world, @tmath.Vec3::new(-1.0, 0.0, 0.0), eps=1.0e-4)
  match s.world_to_local(child, world) {
    Some(local_p) => need_vec3(local_p, @tmath.Vec3::new(0.0, 0.0, -2.0), eps=1.0e-4)
    None => fail("world_to_local")
  }
}

///|
test "light helpers" {
  let s = Scene::new()
  let sun = s.add_directional_light(
    intensity=(3.0 : Float),
    direction=@tmath.Vec3::new(0.0, -1.0, 0.0),
    shadow=false,
  )
  match s.light_of(sun) {
    Some(Light::Directional(d)) => {
      need(close(d.intensity, (3.0 : Float)), "sun intensity")
      match d.shadow {
        Some(_) => fail("shadow disabled")
        None => ()
      }
    }
    _ => fail("directional payload")
  }
  // direction (0,-1,0) tilts local -Z down.
  need_vec3(
    s.direction_to_world(sun, @tmath.Vec3::neg_z()),
    @tmath.Vec3::new(0.0, -1.0, 0.0),
    eps=1.0e-4,
  )
  let spot = s.add_spot_light(
    position=@tmath.Vec3::new(0.0, 5.0, 0.0),
    direction=@tmath.Vec3::new(0.0, 0.0, -1.0),
    shadow=true,
  )
  match s.light_of(spot) {
    Some(Light::Spot(sp)) => {
      need(close(sp.range, (10.0 : Float)), "spot default range")
      need(sp.shadow is Some(_), "spot shadow")
    }
    _ => fail("spot payload")
  }
  need_vec3(s.position(spot), @tmath.Vec3::new(0.0, 5.0, 0.0))
  let hemi = s.add_hemisphere_light(
    @tmath.Vec3::one(),
    @tmath.Vec3::new(0.2, 0.2, 0.2),
    intensity=(0.5 : Float),
  )
  need(s.light_of(hemi) is Some(_), "hemisphere payload")
  let amb = s.add_ambient_light(intensity=(0.3 : Float))
  need(s.light_of(amb) is Some(_), "ambient payload")
}

///|
test "camera degree constructor and pixel rays" {
  let deg = Camera::perspective_deg(60.0, 1.5, near=0.1, far=100.0)
  let rad = Camera::perspective(@tmath.deg_to_rad(60.0), 1.5, near=0.1, far=100.0)
  need(close(deg.fov_y(), rad.fov_y(), eps=1.0e-5), "degree fov")
  need(close(deg.aspect(), (1.5 : Float)), "aspect getter")
  need(close(deg.near(), (0.1 : Float)), "near getter")
  match deg.far() {
    Some(f) => need(close(f, (100.0 : Float)), "far getter")
    None => fail("far missing")
  }
  need(!deg.is_orthographic(), "perspective is not orthographic")
  let ortho = Camera::orthographic(-1.0, 1.0, -1.0, 1.0)
  need(ortho.is_orthographic(), "ortho flag")
  // Pixel centres map to the centre ray; the top-left pixel points left/up.
  match deg.screen_ray_pixels(
    @tmath.Affine3::identity(),
    (750.0 : Float),
    (300.0 : Float),
    (1500.0 : Float),
    (600.0 : Float),
  ) {
    Some(r) => need_vec3(r.dir, @tmath.Vec3::new(0.0, 0.0, -1.0), eps=1.0e-4)
    None => fail("centre pixel ray")
  }
  match deg.screen_ray_pixels(
    @tmath.Affine3::identity(),
    (0.0 : Float),
    (0.0 : Float),
    (1500.0 : Float),
    (600.0 : Float),
  ) {
    Some(r) => need(r.dir.x < 0.0 && r.dir.y > 0.0, "top-left ray points left and up")
    None => fail("top-left pixel ray")
  }
  // The y-up (Metal/WebGPU) clip space flips the pixel rows, not the result.
  let mtl = Camera::perspective_deg(
    60.0,
    2.5,
    near=0.1,
    far=100.0,
    clip=@tmath.ClipSpace::ZeroToOne,
  )
  match mtl.screen_ray_pixels(
    @tmath.Affine3::identity(),
    (0.0 : Float),
    (0.0 : Float),
    (1500.0 : Float),
    (600.0 : Float),
  ) {
    Some(r) => need(r.dir.x < 0.0 && r.dir.y > 0.0, "y-up top-left ray")
    None => fail("y-up top-left pixel ray")
  }
  need(
    mtl.screen_ray_pixels(
      @tmath.Affine3::identity(),
      (0.0 : Float),
      (0.0 : Float),
      (0.0 : Float),
      (600.0 : Float),
    ) ==
    None,
    "zero width",
  )
}

///|
test "clock clamps and accumulates" {
  let c = Clock::new(max_delta=(0.1 : Float))
  need(close(c.tick((1000.0 : Float)), (0.0 : Float)), "first tick has no delta")
  need(close(c.tick((1000.016 : Float)), (0.016 : Float), eps=1.0e-5), "second tick delta")
  need(close(c.elapsed(), (0.016 : Float), eps=1.0e-5), "elapsed")
  need(c.frames() == 2, "frame count")
  need(close(c.fps(), (62.5 : Float), eps=0.5), "fps")
  // A long stall is clamped instead of jumping animations forward.
  need(close(c.tick((1010.0 : Float)), (0.1 : Float)), "clamped delta")
  // Non-monotonic input yields zero rather than a negative step.
  need(close(c.tick((1009.0 : Float)), (0.0 : Float)), "backwards clock")
  c.reset()
  need(close(c.elapsed(), (0.0 : Float)) && c.frames() == 0, "reset")
  need(close(c.tick((5.0 : Float)), (0.0 : Float)), "first tick after reset")
}

///|
test "line helper geometry" {
  let grid = grid_line_data(size=(4.0 : Float), divisions=4)
  // 5 lines per direction, so 10 segments.
  need(grid.segment_count() == 10, "grid segments")
  let b = grid.bounds()
  need(close(b.min.x, (-2.0 : Float)) && close(b.max.z, (2.0 : Float)), "grid bounds")
  let axis = axis_line_data(size=(3.0 : Float))
  need(axis.segment_count() == 1, "axis segment")
  need(close(axis.positions[1].z, (3.0 : Float)), "axis length")
  let box = aabb_line_data(
    @tmath.Aabb3::new(@tmath.Vec3::splat(-1.0), @tmath.Vec3::splat(1.0)),
  )
  need(box.segment_count() == 12, "aabb edges")
  let ring = circle_line_data(radius=(2.0 : Float), segments=16)
  need(ring.segment_count() == 16, "circle segments")
  need(close(ring.bounds().max.x, (2.0 : Float), eps=1.0e-4), "circle radius")
}

///|
test "scene update reuses scratch across frames" {
  let s = Scene::new()
  let a = s.create_node()
  let b = s.create_node(parent=a)
  s.update()
  need_vec3(s.world_transform(b).translation, @tmath.Vec3::zero())
  // The scratch stacks are cleared between passes: a second update still sees
  // both nodes and the new transform.
  s.set_position(a, @tmath.Vec3::new(2.0, 0.0, 0.0))
  s.update()
  need_vec3(s.world_transform(b).translation, @tmath.Vec3::new(2.0, 0.0, 0.0))
  s.update()
  need_vec3(s.world_transform(b).translation, @tmath.Vec3::new(2.0, 0.0, 0.0))
  let c = s.create_node(parent=b)
  s.update()
  need_vec3(s.world_transform(c).translation, @tmath.Vec3::new(2.0, 0.0, 0.0))
}

///|
test "camera viewport helper" {
  let cam = Camera::perspective_deg(60.0, 1.0)
  need(close(cam.with_viewport((800.0 : Float), (600.0 : Float)).aspect(), (4.0 : Float) / (3.0 : Float)), "aspect from pixels")
  // Non-positive sizes keep the camera unchanged.
  need(close(cam.with_viewport((0.0 : Float), (600.0 : Float)).aspect(), (1.0 : Float)), "zero width ignored")
  need(close(cam.with_viewport((800.0 : Float), (-1.0 : Float)).aspect(), (1.0 : Float)), "negative height ignored")
}

///|
test "typed camera handle get and resize" {
  let s = Scene::new()
  let handle = s.add_camera(Camera::perspective_deg(60.0, 1.0), name="main")
  match s.camera(handle) {
    Some(c) => need(close(c.aspect(), (1.0 : Float)), "initial aspect")
    None => fail("camera component")
  }
  // Resize: recompute the aspect from the new viewport and write it back.
  match s.camera(handle) {
    Some(c) => s.set_camera(handle, c.with_viewport((1600.0 : Float), (900.0 : Float)))
    None => fail("camera component")
  }
  match s.camera(handle) {
    Some(c) => need(close(c.aspect(), (16.0 : Float) / (9.0 : Float)), "resized aspect")
    None => fail("camera component after resize")
  }
  need(s.camera_of(handle.node()) is Some(_), "handle still typed as a camera")
}

///|
test "bvh matches brute force picking" {
  let mesh = @tgeo.sphere(radius=1.0, width_segments=16, height_segments=12)
  let bvh = MeshBvh::build(mesh)
  need(bvh.triangle_count() == mesh.triangle_count(), "indexes every triangle")
  need(bvh.node_count() > 1, "tree is split")
  need(close(bvh.bounds().max.y, (1.0 : Float), eps=1.0e-3), "bvh bounds")
  // Non-trivial world transform: translation + rotation + non-uniform scale.
  let world = @tmath.Transform::new(
    @tmath.Vec3::new(0.3, -0.2, 0.5),
    @tmath.Quat::from_euler(@tmath.EulerOrder::YXZ, 0.4, 0.9, 0.1),
    @tmath.Vec3::new(1.5, 0.8, 1.2),
  ).to_affine3()
  let origins : Array[@tmath.Vec3] = [
    @tmath.Vec3::new(0.0, 0.0, 3.0),
    @tmath.Vec3::new(2.0, 1.0, 2.0),
    @tmath.Vec3::new(-2.0, -1.0, 2.0),
    @tmath.Vec3::new(0.0, 0.0, -3.0),
  ]
  let dirs : Array[@tmath.Vec3] = [
    @tmath.Vec3::new(0.0, 0.0, -1.0),
    @tmath.Vec3::new(-0.3, -0.2, -1.0),
    @tmath.Vec3::new(0.25, 0.1, -1.0),
  ]
  for origin in origins {
    for dir in dirs {
      let ray = @tmath.Ray::new_normalized(origin, dir)
      let expected = ray_mesh_hit(ray, mesh, world)
      let actual = bvh.ray_hit(ray, world)
      match (expected, actual) {
        (Some(e), Some(a)) => {
          need(close(e.distance, a.distance, eps=1.0e-3), "bvh distance matches")
          need(e.triangle == a.triangle, "bvh triangle matches")
          need(close((e.position - a.position).length(), (0.0 : Float), eps=1.0e-3), "bvh position matches")
          need(close(e.normal.length(), (1.0 : Float), eps=1.0e-3), "bvh normal normalized")
        }
        (None, None) => ()
        _ => fail("bvh/brute-force disagreement")
      }
    }
  }
  // A ray pointing away from the mesh misses in both paths.
  let away = @tmath.Ray::new_normalized(
    @tmath.Vec3::new(0.0, 0.0, 5.0),
    @tmath.Vec3::new(0.0, 0.0, 1.0),
  )
  match ray_mesh_hit(away, mesh, world) {
    None => ()
    Some(_) => fail("brute force should miss")
  }
  match bvh.ray_hit(away, world) {
    None => ()
    Some(_) => fail("bvh should miss")
  }
}

///|
test "bvh handles an empty mesh" {
  let empty = @tgeo.MeshData::new(
    FixedArray::make(0, @tmath.Vec3::zero()),
    FixedArray::make(0, @tmath.Vec3::zero()),
    FixedArray::make(0, @tmath.Vec2::zero()),
    FixedArray::make(0, (0 : UInt)),
  )
  let bvh = MeshBvh::build(empty)
  need(bvh.triangle_count() == 0, "no triangles")
  need(bvh.node_count() == 1, "placeholder node")
  let ray = @tmath.Ray::new_normalized(@tmath.Vec3::zero(), @tmath.Vec3::unit_z())
  match bvh.ray_hit(ray, @tmath.Affine3::identity()) {
    None => ()
    Some(_) => fail("empty bvh should miss")
  }
}

///|
test "fog models" {
  let color = @tmath.Vec3::new(0.5, 0.6, 0.7)
  match fog_linear(color, near=(2.0 : Float), far=(50.0 : Float)) {
    Fog::Linear(c, near, far) => {
      need_vec3(c, color)
      need(close(near, (2.0 : Float)), "fog near")
      need(close(far, (50.0 : Float)), "fog far")
    }
    Fog::Exp2(_, _) => fail("expected linear fog")
  }
  // A degenerate range is widened instead of producing a division by zero.
  match fog_linear(color, near=(10.0 : Float), far=(5.0 : Float)) {
    Fog::Linear(_, near, far) => {
      need(close(near, (10.0 : Float)), "clamped near")
      need(close(far, (11.0 : Float)), "widened far")
    }
    Fog::Exp2(_, _) => fail("expected linear fog")
  }
  match fog_exp2(color, density=(-1.0 : Float)) {
    Fog::Exp2(c, density) => {
      need_vec3(c, color)
      need(close(density, (0.0 : Float)), "negative density clamps to zero")
    }
    Fog::Linear(_, _, _) => fail("expected exp2 fog")
  }
  need_vec3(fog_exp2(color).color(), color)
}

///|
test "sheen material builder" {
  let m = MaterialDesc::standard(hex(0x808080), roughness=(0.6 : Float))
  need_vec3(m.sheen_color, @tmath.Vec3::zero())
  need(close(m.sheen_roughness, (0.5 : Float)), "default sheen roughness")
  let s = m.with_sheen(@tmath.Vec3::one(), roughness=(0.15 : Float))
  need_vec3(s.sheen_color, @tmath.Vec3::one())
  need(close(s.sheen_roughness, (0.15 : Float)), "sheen roughness")
  // The base PBR parameters are untouched.
  need(close(s.roughness, (0.6 : Float)) && close(s.metallic, m.metallic), "base untouched")
  need_vec3(s.base_color.truncate(), m.base_color.truncate())
}

///|
test "transmission material builder" {
  let m = MaterialDesc::standard(hex(0xBFD8E6), roughness=(0.05 : Float))
  need(close(m.transmission, (0.0 : Float)), "transmission off by default")
  need(close(m.ior, (1.5 : Float)), "default ior")
  let t = m.with_transmission((0.9 : Float), ior=(1.45 : Float))
  need(close(t.transmission, (0.9 : Float)), "transmission amount")
  need(close(t.ior, (1.45 : Float)), "ior")
  // Out-of-range amounts clamp instead of producing negative or HDR weights.
  need(close(m.with_transmission((-1.0 : Float)).transmission, (0.0 : Float)), "clamp low")
  need(close(m.with_transmission((2.0 : Float)).transmission, (1.0 : Float)), "clamp high")
  // The base material survives.
  need(close(t.roughness, (0.05 : Float)) && close(t.metallic, m.metallic), "base untouched")
}

///|
test "ssao descriptor is mutually exclusive with msaa" {
  let d = RendererDesc::default().with_ssao(true)
  need(d.ssao, "ssao enabled")
  need(!d.msaa, "ssao forces single-sample depth")
  // MSAA cannot be re-enabled while SSAO is on.
  let forced = d.with_msaa(true)
  need(!forced.msaa && forced.ssao, "ssao wins over msaa")
  let off = d.with_ssao(false)
  need(!off.ssao, "ssao disabled")
  // Turning SSAO off leaves MSAA as it was (off, because with_ssao cleared it).
  need(!off.msaa, "msaa stays off after toggling ssao")
}
