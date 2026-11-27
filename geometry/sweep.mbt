// Swept primitives: `lathe` (surface of revolution) and `tube` (extrusion
// along a sampled 3D polyline), ported from three.js `LatheGeometry` and
// `TubeGeometry`.
//
// three.js takes a `Curve` object for `TubeGeometry`; this module takes plain
// data instead: a polyline of `Vec3` samples. `catmull_rom_chain` is provided
// to turn a coarse control polygon into such a polyline.

///|
/// Clamp a profile/segment argument into a usable range.
fn sweep_segments(v : Int, lo : Int) -> Int {
  if v < lo {
    lo
  } else {
    v
  }
}

///|
/// Surface of revolution around the +Y axis.
///
/// `profile` is a polyline in the XY plane (x is the radius, y the height);
/// it must be ordered from the bottom of the shape to the top so that
/// triangles come out CCW. Triangles are not capped, matching three.js.
pub fn lathe(
  profile : Array[@tmath.Vec2],
  segments? : Int = 12,
  phi_start? : Float = 0.0,
  phi_length? : Float = @tmath.TAU,
) -> MeshData {
  let builder = MeshBuilder::new()
  let count = profile.length()
  let segs = sweep_segments(segments, 1)
  if count < 2 {
    return builder.build()
  }
  // Clamping matches three.js: a full turn at most.
  let sweep = @tmath.clamp_f(phi_length, 0.0, @tmath.TAU)
  // Initial meridian normals: each segment contributes (dy, -dx), averaged at
  // the shared points so the revolve gets smooth shading along the profile.
  let init_normals : Array[@tmath.Vec3] = []
  let mut prev = @tmath.Vec3::zero()
  for j = 0; j < count; j = j + 1 {
    if j == 0 {
      let dx = profile[1].x - profile[0].x
      let dy = profile[1].y - profile[0].y
      prev = @tmath.Vec3::new(dy, -dx, 0.0)
      init_normals.push(prev.normalize())
    } else if j == count - 1 {
      init_normals.push(prev.normalize())
    } else {
      let dx = profile[j + 1].x - profile[j].x
      let dy = profile[j + 1].y - profile[j].y
      let current = @tmath.Vec3::new(dy, -dx, 0.0)
      init_normals.push((current + prev).normalize())
      prev = current
    }
  }
  let inv_segments : Float = 1.0 / f_of_int(segs)
  let inv_profile : Float = 1.0 / f_of_int(count - 1)
  for i = 0; i <= segs; i = i + 1 {
    let phi = phi_start + f_of_int(i) * inv_segments * sweep
    let (sin, cos) = @tmath.sin_cos(phi)
    for j = 0; j < count; j = j + 1 {
      let point = profile[j]
      let normal = init_normals[j]
      let _ = builder.vertex(
        @tmath.Vec3::new(point.x * sin, point.y, point.x * cos),
        @tmath.Vec3::new(normal.x * sin, normal.y, normal.x * cos),
        @tmath.Vec2::new(f_of_int(i) * inv_segments, f_of_int(j) * inv_profile),
      )
    }
  }
  for i = 0; i < segs; i = i + 1 {
    for j = 0; j < count - 1; j = j + 1 {
      let a = (j + i * count).reinterpret_as_uint()
      let b = (j + (i + 1) * count).reinterpret_as_uint()
      let c = (j + (i + 1) * count + 1).reinterpret_as_uint()
      let d = (j + i * count + 1).reinterpret_as_uint()
      builder.tri(a, b, d)
      builder.tri(c, d, b)
    }
  }
  builder.build()
}

///|
/// Resample `path` into `count + 1` points evenly spaced by arc length.
/// A closed path wraps around and repeats its first point at the end.
fn polyline_resample(
  path : Array[@tmath.Vec3],
  count : Int,
  closed : Bool,
) -> Array[@tmath.Vec3] {
  let n = path.length()
  let out : Array[@tmath.Vec3] = []
  if n == 0 || count == 0 {
    return out
  }
  if n == 1 {
    for i = 0; i <= count; i = i + 1 {
      out.push(path[0])
    }
    return out
  }
  let segment_count = if closed { n } else { n - 1 }
  let cumulative : Array[Float] = [0.0]
  let mut total : Float = 0.0
  for s = 0; s < segment_count; s = s + 1 {
    total = total + path[s].distance(path[(s + 1) % n])
    cumulative.push(total)
  }
  if total <= (1.0e-12 : Float) {
    for i = 0; i <= count; i = i + 1 {
      out.push(path[0])
    }
    return out
  }
  let mut s = 0
  for i = 0; i <= count; i = i + 1 {
    let target = f_of_int(i) / f_of_int(count) * total
    while s < segment_count && cumulative[s + 1] < target {
      s = s + 1
    }
    let seg = if s >= segment_count { segment_count - 1 } else { s }
    let span = cumulative[seg + 1] - cumulative[seg]
    let frac : Float = if span > (1.0e-12 : Float) {
      (target - cumulative[seg]) / span
    } else {
      0.0
    }
    let t = @tmath.clamp_f(frac, 0.0, 1.0)
    out.push(path[seg % n].lerp(path[(seg + 1) % n], t))
  }
  out
}

///|
/// Per-row tangents of a sampled polyline (central differences inside,
/// one-sided at the ends). The trailing duplicate row of a closed loop reuses
/// the first tangent.
fn polyline_tangents(
  points : Array[@tmath.Vec3],
  closed : Bool,
) -> Array[@tmath.Vec3] {
  let m = points.length()
  let tangents : Array[@tmath.Vec3] = []
  if m == 0 {
    return tangents
  }
  let unique = if closed && m > 1 { m - 1 } else { m }
  for i = 0; i < m; i = i + 1 {
    let tangent = if closed {
      let prev = points[(i + unique - 1) % unique]
      let next = points[(i + 1) % unique]
      next - prev
    } else if i == 0 {
      points[1] - points[0]
    } else if i == m - 1 {
      points[m - 1] - points[m - 2]
    } else {
      points[i + 1] - points[i - 1]
    }
    tangents.push(match tangent.try_normalize() {
      Some(v) => v
      None => @tmath.Vec3::unit_x()
    })
  }
  if closed && m > 1 {
    tangents[m - 1] = tangents[0]
  }
  tangents
}

///|
/// Rotation-minimizing frames along a polyline: start from an arbitrary normal
/// orthogonal to the first tangent, then parallel-transport it (project onto
/// each new normal plane). This is the twist-free equivalent of three.js
/// `Curve.computeFrenetFrames`.
fn polyline_frames(
  points : Array[@tmath.Vec3],
  closed : Bool,
) -> (Array[@tmath.Vec3], Array[@tmath.Vec3]) {
  let m = points.length()
  let tangents = polyline_tangents(points, closed)
  let normals : Array[@tmath.Vec3] = []
  let binormals : Array[@tmath.Vec3] = []
  if m == 0 {
    return (normals, binormals)
  }
  let t0 = tangents[0]
  let seed = if t0.x.abs() < 0.9 {
    @tmath.Vec3::unit_x()
  } else {
    @tmath.Vec3::unit_y()
  }
  let mut normal = match (seed - t0.scale(seed.dot(t0))).try_normalize() {
    Some(v) => v
    None => t0.any_orthonormal()
  }
  for i = 0; i < m; i = i + 1 {
    let tangent = tangents[i]
    normal = match (normal - tangent.scale(tangent.dot(normal))).try_normalize() {
      Some(v) => v
      None => tangent.any_orthonormal()
    }
    let binormal = match tangent.cross(normal).try_normalize() {
      Some(v) => v
      None => tangent.any_orthonormal()
    }
    normals.push(normal)
    binormals.push(binormal)
  }
  if closed && m > 1 {
    normals[m - 1] = normals[0]
    binormals[m - 1] = binormals[0]
  }
  (normals, binormals)
}

///|
/// Tube swept along `path` (a polyline sampled in 3D). The path is resampled
/// to `tubular_segments + 1` rows evenly spaced by arc length, and the
/// cross-section frames are parallel-transported to avoid twisting.
pub fn tube(
  path : Array[@tmath.Vec3],
  tubular_segments? : Int = 64,
  radius? : Float = 1.0,
  radial_segments? : Int = 8,
  closed? : Bool = false,
) -> MeshData {
  let builder = MeshBuilder::new()
  if path.length() < 2 {
    return builder.build()
  }
  let tubular = sweep_segments(tubular_segments, 3)
  let radial = sweep_segments(radial_segments, 3)
  let points = polyline_resample(path, tubular, closed)
  let (normals, binormals) = polyline_frames(points, closed)
  for i = 0; i <= tubular; i = i + 1 {
    let center = points[i]
    let n = normals[i]
    let b = binormals[i]
    for j = 0; j <= radial; j = j + 1 {
      let v = f_of_int(j) / f_of_int(radial) * @tmath.TAU
      let (sin, cos) = @tmath.sin_cos(v)
      let direction = n.scale(-cos) + b.scale(sin)
      let normal = direction.normalize()
      let _ = builder.vertex(
        center + normal.scale(radius),
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

///|
/// Sample a Catmull-Rom spline through `points`.
///
/// Each input segment contributes `samples_per_segment` samples (end excluded,
/// plus the final point once), so the result can be fed straight to `tube`.
/// This is the data-only replacement for three.js `CatmullRomCurve3`.
pub fn catmull_rom_chain(
  points : Array[@tmath.Vec3],
  samples_per_segment? : Int = 8,
  closed? : Bool = false,
) -> Array[@tmath.Vec3] {
  let out : Array[@tmath.Vec3] = []
  let n = points.length()
  if n == 0 {
    return out
  }
  if n == 1 {
    out.push(points[0])
    return out
  }
  let samples = sweep_segments(samples_per_segment, 1)
  let segment_count = if closed { n } else { n - 1 }
  let last = n - 1
  for s = 0; s < segment_count; s = s + 1 {
    let p0 = if closed {
      points[(s + n - 1) % n]
    } else if s == 0 {
      points[0]
    } else {
      points[s - 1]
    }
    let p1 = points[s % n]
    let p2 = points[(s + 1) % n]
    let p3 = if closed {
      points[(s + 2) % n]
    } else if s == last - 1 {
      points[last]
    } else {
      points[s + 2]
    }
    for k = 0; k < samples; k = k + 1 {
      let t = f_of_int(k) / f_of_int(samples)
      let t2 = t * t
      let t3 = t2 * t
      // Standard uniform Catmull-Rom basis (tension 0.5).
      let a = p1.scale(2.0)
      let b = p2 - p0
      let c = p0.scale(2.0) - p1.scale(5.0) + p2.scale(4.0) - p3
      let d = p1.scale(3.0) - p0 - p2.scale(3.0) + p3
      out.push((a + b.scale(t) + c.scale(t2) + d.scale(t3)).scale(0.5))
    }
  }
  if closed {
    out.push(points[0])
  } else {
    out.push(points[last])
  }
  out
}
