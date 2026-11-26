// Picking and camera-controller contracts.

///|
test "ray mesh picking" {
  let plane = @tgeo.plane(width=2.0, height=2.0)
  let ray = @tmath.Ray::new_normalized(
    @tmath.Vec3::new(0.0, 0.0, 3.0),
    @tmath.Vec3::new(0.0, 0.0, -1.0),
  )
  match ray_mesh_hit(ray, plane, @tmath.Affine3::identity()) {
    Some(h) => {
      need(close(h.distance, 3.0), "distance")
      need_vec3(h.position, @tmath.Vec3::zero())
      need_vec3(h.normal, @tmath.Vec3::new(0.0, 0.0, 1.0))
    }
    None => fail("expected a plane hit")
  }
  let moved = @tmath.Affine3::from_translation(@tmath.Vec3::new(0.0, 0.0, -5.0))
  match ray_mesh_hit(ray, plane, moved) {
    Some(h) => {
      need(close(h.distance, 8.0), "translated distance")
      need_vec3(h.position, @tmath.Vec3::new(0.0, 0.0, -5.0))
    }
    None => fail("expected a translated hit")
  }
  let miss = @tmath.Ray::new_normalized(
    @tmath.Vec3::new(5.0, 0.0, 3.0),
    @tmath.Vec3::new(0.0, 0.0, -1.0),
  )
  match ray_mesh_hit(miss, plane, @tmath.Affine3::identity()) {
    Some(_) => fail("expected a miss")
    None => ()
  }
}

///|
test "orbit camera" {
  let cam = OrbitCamera::new(
    target=@tmath.Vec3::zero(),
    distance=5.0,
    yaw=0.0,
    pitch=0.0,
  )
  need_vec3(cam.position(), @tmath.Vec3::new(0.0, 0.0, 5.0))
  let tr = cam.transform()
  need_vec3(tr.translation, @tmath.Vec3::new(0.0, 0.0, 5.0))
  need_vec3(
    tr.rotation.mul_vec3(@tmath.Vec3::neg_z()),
    @tmath.Vec3::new(0.0, 0.0, -1.0),
  )
  let d0 = cam.distance()
  need(cam.apply(@tycho.Event::MouseScroll(0, 1)), "scroll handled")
  need(cam.distance() < d0, "scroll zooms in")
  need(cam.apply(@tycho.Event::MouseDown(0, 10, 10)), "drag start")
  need(cam.apply(@tycho.Event::MouseMove(30, 10)), "drag move")
  need(cam.yaw() != 0.0, "drag rotates")
  let _ = cam.apply(@tycho.Event::MouseUp(0, 0, 0))
  need(!cam.apply(@tycho.Event::MouseMove(60, 10)), "no rotation after release")
  cam.set_distance(0.01)
  need(close(cam.distance(), 0.5), "min distance clamp")
}

///|
test "fly camera" {
  let cam = FlyCamera::new()
  need(cam.apply(@tycho.Event::KeyDown(@tycho.KEY_W, 0)), "W handled")
  need(cam.position().z < 0.0, "W moves forward")
  let y0 = cam.yaw()
  let _ = cam.apply(@tycho.Event::MouseDown(0, 0, 0))
  let _ = cam.apply(@tycho.Event::MouseMove(20, 0))
  need(cam.yaw() != y0, "drag rotates")
  need(!cam.apply(@tycho.Event::MouseScroll(0, 1)), "scroll ignored by fly")
}
