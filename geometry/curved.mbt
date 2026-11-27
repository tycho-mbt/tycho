// Curved parametric primitives: sphere, cylinder, cone, capsule, torus,
// torus_knot.
// Parameter semantics follow three.js `src/geometries/` so meshes can be
// compared against the reference implementation.

///|
/// UV sphere. Poles are at ±Y. `phi_*` sweeps around Y, `theta_*` from the
/// north pole downwards (three.js convention).
pub fn sphere(
  radius? : Float = 1.0,
  width_segments? : Int = 32,
  height_segments? : Int = 16,
  phi_start? : Float = 0.0,
  phi_length? : Float = @tmath.TAU,
  theta_start? : Float = 0.0,
  theta_length? : Float = @tmath.PI,
) -> MeshData {
  let ws = clamp_segs(width_segments, 3)
  let hs = clamp_segs(height_segments, 2)
  let builder = MeshBuilder::new()
  let base = builder.positions.length()
  let row = ws + 1
  let theta_end = theta_start + theta_length
  for iy = 0; iy <= hs; iy = iy + 1 {
    let v = f_of_int(iy) / f_of_int(hs)
    let theta = theta_start + v * theta_length
    let (sin_t, cos_t) = @tmath.sin_cos(theta)
    for ix = 0; ix <= ws; ix = ix + 1 {
      let u = f_of_int(ix) / f_of_int(ws)
      let phi = phi_start + u * phi_length
      let (sin_p, cos_p) = @tmath.sin_cos(phi)
      let p = @tmath.Vec3::new(
        -radius * cos_p * sin_t,
        radius * cos_t,
        radius * sin_p * sin_t,
      )
      let _ = builder.vertex(p, p.normalize(), @tmath.Vec2::new(u, 1.0 - v))
    }
  }
  for iy = 0; iy < hs; iy = iy + 1 {
    for ix = 0; ix < ws; ix = ix + 1 {
      let a = (base + iy * row + ix).reinterpret_as_uint()
      let b = (base + (iy + 1) * row + ix).reinterpret_as_uint()
      let c = (base + (iy + 1) * row + ix + 1).reinterpret_as_uint()
      let d = (base + iy * row + ix + 1).reinterpret_as_uint()
      if iy != 0 || theta_start > 0.0 {
        builder.tri(a, b, d)
      }
      if iy != hs - 1 || theta_end < @tmath.PI {
        builder.tri(b, c, d)
      }
    }
  }
  builder.build()
}

///|
/// Capped cylinder (optionally a cone frustum). Groups: 0 = side, 1 = top cap,
/// 2 = bottom cap (three.js layout).
pub fn cylinder(
  radius_top? : Float = 1.0,
  radius_bottom? : Float = 1.0,
  height? : Float = 1.0,
  radial_segments? : Int = 32,
  height_segments? : Int = 1,
  open_ended? : Bool = false,
  theta_start? : Float = 0.0,
  theta_length? : Float = @tmath.TAU,
) -> MeshData {
  let radial = clamp_segs(radial_segments, 3)
  let hseg = clamp_segs(height_segments, 1)
  let builder = MeshBuilder::new()
  let half_h = height * 0.5
  let slope = if height.abs() > (1.0e-12 : Float) {
    (radius_bottom - radius_top) / height
  } else {
    0.0
  }
  let side_start = builder.group_start(0)
  let base = builder.positions.length()
  for y = 0; y <= hseg; y = y + 1 {
    let v = f_of_int(y) / f_of_int(hseg)
    let r = v * (radius_bottom - radius_top) + radius_top
    for x = 0; x <= radial; x = x + 1 {
      let u = f_of_int(x) / f_of_int(radial)
      let theta = u * theta_length + theta_start
      let (s, c) = @tmath.sin_cos(theta)
      let p = @tmath.Vec3::new(r * s, -v * height + half_h, r * c)
      let n = @tmath.Vec3::new(s, slope, c).normalize()
      let _ = builder.vertex(p, n, @tmath.Vec2::new(u, 1.0 - v))
    }
  }
  for y = 0; y < hseg; y = y + 1 {
    for x = 0; x < radial; x = x + 1 {
      let a = (base + (radial + 1) * y + x).reinterpret_as_uint()
      let b = (base + (radial + 1) * (y + 1) + x).reinterpret_as_uint()
      let c = (base + (radial + 1) * (y + 1) + x + 1).reinterpret_as_uint()
      let d = (base + (radial + 1) * y + x + 1).reinterpret_as_uint()
      // Skip the degenerate ring at a cone apex (three.js does the same).
      if radius_top > 0.0 || y != 0 {
        builder.tri(a, b, d)
      }
      if radius_bottom > 0.0 || y != hseg - 1 {
        builder.tri(b, c, d)
      }
    }
  }
  builder.group_end(side_start)
  let full_circle = theta_length >= @tmath.TAU - (1.0e-4 : Float)
  if !open_ended && radius_top > 0.0 && full_circle {
    let gi = builder.group_start(1)
    add_cap(builder, radius_top, half_h, radial, (1.0 : Float), theta_start, theta_length)
    builder.group_end(gi)
  }
  if !open_ended && radius_bottom > 0.0 && full_circle {
    let gi = builder.group_start(2)
    add_cap(builder, radius_bottom, -half_h, radial, (-1.0 : Float), theta_start, theta_length)
    builder.group_end(gi)
  }
  builder.build()
}

///|
/// Disk cap for `cylinder`: `sign = +1` faces +Y, `sign = -1` faces -Y.
fn add_cap(
  builder : MeshBuilder,
  radius : Float,
  y : Float,
  radial : Int,
  sign : Float,
  theta_start : Float,
  theta_length : Float,
) -> Unit {
  let normal = @tmath.Vec3::new(0.0, sign, 0.0)
  let center = builder.vertex(
    @tmath.Vec3::new(0.0, y, 0.0),
    normal,
    @tmath.Vec2::new(0.5, 0.5),
  )
  let ring : Array[UInt] = []
  for x = 0; x < radial; x = x + 1 {
    let u = f_of_int(x) / f_of_int(radial)
    let theta = u * theta_length + theta_start
    let (s, c) = @tmath.sin_cos(theta)
    let p = @tmath.Vec3::new(radius * s, y, radius * c)
    let uv = @tmath.Vec2::new(0.5 + 0.5 * s, 0.5 + 0.5 * c * sign)
    ring.push(builder.vertex(p, normal, uv))
  }
  for x = 0; x < radial; x = x + 1 {
    let i0 = ring[x]
    let i1 = ring[(x + 1) % radial]
    if sign > 0.0 {
      builder.tri(center, i0, i1)
    } else {
      builder.tri(center, i1, i0)
    }
  }
}

///|
/// Cone = cylinder with a zero top radius (three.js composition pattern).
pub fn cone(
  radius? : Float = 1.0,
  height? : Float = 1.0,
  radial_segments? : Int = 32,
  height_segments? : Int = 1,
  open_ended? : Bool = false,
  theta_start? : Float = 0.0,
  theta_length? : Float = @tmath.TAU,
) -> MeshData {
  cylinder(
    radius_top=0.0,
    radius_bottom=radius,
    height=height,
    radial_segments=radial_segments,
    height_segments=height_segments,
    open_ended=open_ended,
    theta_start=theta_start,
    theta_length=theta_length,
  )
}

///|
/// Capsule along Y: a cylinder of `length` plus two hemispherical caps of
/// `radius`. Normals are analytic (distance to the axis segment).
pub fn capsule(
  radius? : Float = 0.5,
  length? : Float = 1.0,
  cap_segments? : Int = 8,
  radial_segments? : Int = 16,
) -> MeshData {
  let caps = clamp_segs(cap_segments, 2)
  let radial = clamp_segs(radial_segments, 3)
  let half = length * 0.5
  let builder = MeshBuilder::new()
  let profile : Array[@tmath.Vec2] = []
  for i = 0; i <= caps; i = i + 1 {
    let a = -@tmath.FRAC_PI_2 + @tmath.FRAC_PI_2 * (f_of_int(i) / f_of_int(caps))
    let (s, c) = @tmath.sin_cos(a)
    profile.push(@tmath.Vec2::new(radius * c, -half + radius * s))
  }
  for i = 0; i <= caps; i = i + 1 {
    let a = @tmath.FRAC_PI_2 * (f_of_int(i) / f_of_int(caps))
    let (s, c) = @tmath.sin_cos(a)
    profile.push(@tmath.Vec2::new(radius * c, half + radius * s))
  }
  let pcount = profile.length()
  let base = builder.positions.length()
  for j = 0; j <= radial; j = j + 1 {
    let u = f_of_int(j) / f_of_int(radial)
    let theta = u * @tmath.TAU
    let (s, c) = @tmath.sin_cos(theta)
    for i = 0; i < pcount; i = i + 1 {
      let pr = profile[i]
      let p = @tmath.Vec3::new(pr.x * s, pr.y, pr.x * c)
      let yc = @tmath.clamp_f(pr.y, -half, half)
      let d = @tmath.Vec3::new(p.x, p.y - yc, p.z)
      let n = match d.try_normalize() {
        Some(v) => v
        None => if pr.y >= 0.0 { @tmath.Vec3::unit_y() } else { @tmath.Vec3::neg_y() }
      }
      let _ = builder.vertex(p, n, @tmath.Vec2::new(u, 1.0 - f_of_int(i) / f_of_int(pcount - 1)))
    }
  }
  for j = 0; j < radial; j = j + 1 {
    for i = 0; i < pcount - 1; i = i + 1 {
      let a = (base + j * pcount + i).reinterpret_as_uint()
      let b = (base + (j + 1) * pcount + i).reinterpret_as_uint()
      let c = (base + (j + 1) * pcount + i + 1).reinterpret_as_uint()
      let d = (base + j * pcount + i + 1).reinterpret_as_uint()
      builder.tri(a, b, c)
      builder.tri(a, c, d)
    }
  }
  builder.build()
}

///|
/// Torus in the XY plane (hole axis = +Z), matching three.js `TorusGeometry`.
pub fn torus(
  radius? : Float = 1.0,
  tube? : Float = 0.4,
  radial_segments? : Int = 12,
  tubular_segments? : Int = 48,
  arc? : Float = @tmath.TAU,
) -> MeshData {
  let radial = clamp_segs(radial_segments, 3)
  let tubular = clamp_segs(tubular_segments, 3)
  let builder = MeshBuilder::new()
  for j = 0; j <= radial; j = j + 1 {
    let v = f_of_int(j) / f_of_int(radial) * @tmath.TAU
    let (sv, cv) = @tmath.sin_cos(v)
    for i = 0; i <= tubular; i = i + 1 {
      let u = f_of_int(i) / f_of_int(tubular) * arc
      let (su, cu) = @tmath.sin_cos(u)
      let p = @tmath.Vec3::new((radius + tube * cv) * cu, (radius + tube * cv) * su, tube * sv)
      let center = @tmath.Vec3::new(radius * cu, radius * su, 0.0)
      let n = (p - center).normalize()
      let _ = builder.vertex(
        p,
        n,
        @tmath.Vec2::new(f_of_int(i) / f_of_int(tubular), f_of_int(j) / f_of_int(radial)),
      )
    }
  }
  for j = 1; j <= radial; j = j + 1 {
    for i = 1; i <= tubular; i = i + 1 {
      let a = ((tubular + 1) * j + i - 1).reinterpret_as_uint()
      let b = ((tubular + 1) * (j - 1) + i - 1).reinterpret_as_uint()
      let c = ((tubular + 1) * (j - 1) + i).reinterpret_as_uint()
      let d = ((tubular + 1) * j + i).reinterpret_as_uint()
      builder.tri(a, b, d)
      builder.tri(b, c, d)
    }
  }
  builder.build()
}

///|
/// Point on the (p, q) torus knot curve, matching three.js
/// `TorusKnotGeometry.calculatePositionOnCurve`.
fn torus_knot_point(
  u : Float,
  p : Int,
  q : Int,
  radius : Float,
) -> @tmath.Vec3 {
  let (su, cu) = @tmath.sin_cos(u)
  let qu_over_p = f_of_int(q) / f_of_int(p) * u
  let (ss, cs) = @tmath.sin_cos(qu_over_p)
  @tmath.Vec3::new(
    radius * (2.0 + cs) * 0.5 * cu,
    radius * (2.0 + cs) * su * 0.5,
    radius * ss * 0.5,
  )
}

///|
/// (p, q) torus knot: the tube sweeps a curve that winds `p` times around the
/// knot axis and `q` times around the torus interior. `p` and `q` must be
/// coprime for a single knot (otherwise the result is a torus link).
pub fn torus_knot(
  radius? : Float = 1.0,
  tube? : Float = 0.4,
  tubular_segments? : Int = 64,
  radial_segments? : Int = 8,
  p? : Int = 2,
  q? : Int = 3,
) -> MeshData {
  let tubular = clamp_segs(tubular_segments, 3)
  let radial = clamp_segs(radial_segments, 3)
  let pv = if p < 1 { 1 } else { p }
  let qv = if q < 1 { 1 } else { q }
  let builder = MeshBuilder::new()
  for i = 0; i <= tubular; i = i + 1 {
    let u = f_of_int(i) / f_of_int(tubular) * f_of_int(pv) * @tmath.TAU
    let p1 = torus_knot_point(u, pv, qv, radius)
    let p2 = torus_knot_point(u + 0.01, pv, qv, radius)
    // Orthonormal frame: tangent T, then N / B derived from T and P1 + P2.
    let t = p2 - p1
    let n0 = p2 + p1
    let b0 = t.cross(n0)
    // Degenerate frames only happen for a degenerate curve; fall back to a
    // fixed orthonormal pair so the mesh stays finite.
    let n1 = match b0.cross(t).try_normalize() {
      Some(v) => v
      None => @tmath.Vec3::unit_y()
    }
    let b1 = match b0.try_normalize() {
      Some(v) => v
      None => @tmath.Vec3::unit_z()
    }
    for j = 0; j <= radial; j = j + 1 {
      let v = f_of_int(j) / f_of_int(radial) * @tmath.TAU
      let (sv, cv) = @tmath.sin_cos(v)
      let cx = -tube * cv
      let cy = tube * sv
      let offset = n1.scale(cx) + b1.scale(cy)
      let position = p1 + offset
      let normal = offset.normalize()
      let _ = builder.vertex(
        position,
        normal,
        @tmath.Vec2::new(
          f_of_int(i) / f_of_int(tubular),
          f_of_int(j) / f_of_int(radial),
        ),
      )
    }
  }
  for j = 1; j <= tubular; j = j + 1 {
    for i = 1; i <= radial; i = i + 1 {
      let a = ((radial + 1) * (j - 1) + (i - 1)).reinterpret_as_uint()
      let b = ((radial + 1) * j + (i - 1)).reinterpret_as_uint()
      let c = ((radial + 1) * j + i).reinterpret_as_uint()
      let d = ((radial + 1) * (j - 1) + i).reinterpret_as_uint()
      builder.tri(a, b, d)
      builder.tri(b, c, d)
    }
  }
  builder.build()
}
