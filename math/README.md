# `laplaceliu/tycho_math`

Zero-dependency, pure-MoonBit fixed-dimension graphics and geometry math, in the spirit of Rust `glam` and C++ `GLM` / `DirectXMath`.

## Highlights
- **`Float` by default**: 32-bit values that map directly to GPU precision. A `f64/` subpackage provides `Double` (`DVec*` / `DMat*` / `DQuat`) for large-world camera and shadow construction, with zero-cost `to_vec3()` / `to_mat4()` down-casts on upload.
- **Column-major everywhere**: `Mat4` stores four `Vec4` columns, so the 16 floats are byte-identical to GLSL / Slang / WGSL / SPIR-V / Metal `mat4` and can be uploaded to a UBO/SSBO without transposing.
- **Right-handed by default** (`+X` right, `+Y` up, `-Z` forward), with explicit `_lh` variants for left-handed engines.
- **Clip space is an explicit parameter**: `ClipSpace::{Vulkan, ZeroToOne, NegOneToOne}` plus reversed-Z and infinite-far projections. No global macro state.
- **Value types, no heap**: every primitive is a `#valtype` struct; matrix math is allocation-free and ready for a future `V128` kernel.
- **No C, no link flags**: pure MoonBit, works on `native`, `wasm`, `wasm-gc`, and `js`.

## Dependencies

```text
laplaceliu/tycho_math
  └── moonbitlang/core/math   (scalar transcendentals only)
```

## Quick start

```moonbit
let view = @tmath.look_to_rh(cam_pos, cam_forward, @tmath.Vec3::unit_y())
let proj = @tmath.perspective_rh(
  @tmath.deg_to_rad(53.13),
  aspect,
  0.1,
  40.0,
  clip=@tmath.ClipSpace::Vulkan,
)
let vp = proj * view

let mut writer = @tmath.GpuPackWriter::std140(48)
writer.push_mat4(vp)
let floats = writer.as_floats()
```

Downstream `moon.pkg` should alias the package as `@tmath` to avoid clashing with `moonbitlang/core/math`:

```text
import {
  "laplaceliu/tycho_math" @tmath,
}
```

## Module layout

| File | Contents |
|---|---|
| `scalar.mbt` | Constants, `clamp_f` / `lerp_f` / `smoothstep` / `fract`, degrees↔radians, `approx_eq_f`, `sin_cos` |
| `vec2.mbt` / `vec3.mbt` / `vec4.mbt` | Single-precision vectors |
| `ivec.mbt` | `IVec2/3/4` (`Int`) and `UVec2/3/4` (`UInt`) |
| `quat.mbt` | Unit quaternions, Euler orders, SLERP / NLERP |
| `mat2.mbt` / `mat3.mbt` / `mat4.mbt` | Column-major matrices, inverse, normal matrix |
| `affine2.mbt` / `affine3.mbt` / `transform.mbt` | 2D/3D affine transforms and TRS |
| `projection.mbt` | `ClipSpace`, perspective / orthographic, `look_at`, `project` / `unproject` |
| `geometry.mbt` | `Ray` / `Plane` / `Aabb2` / `Aabb3` / `Sphere` / `Frustum` |
| `gpu_pack.mbt` | std140 / std430 aligned writer |
| `batch.mbt` | Contiguous-array batch kernels (accelerator seam for `V128`) |
| `f64/` | `Double` subpackage: `DVec*`, `DMat*`, `DQuat`, double-precision projections |

## Non-goals

No dynamic arbitrary-dimension matrices, no scientific decompositions (LU/QR/SVD), no CUDA / OpenCL / OpenBLAS, and no C FFI for single-element operations.

## Usage notes

- `Vec3::normalize` returns the zero vector for zero input; use `try_normalize` when you need to detect degeneracy. The same "never emit `NaN`" rule applies to `Mat4::inverse`, `Quat::slerp`, and `Plane::normalize`.
- `Mat3::from_quat` / `Mat4::from_quat` expect a unit quaternion; `Quat::from_mat3` expects a pure rotation matrix.
- `Vec3::extend_w` and `Vec2::extend_z` are the widening helpers (`extend` is a MoonBit keyword).
- `Ray` directions are not normalized automatically; `t` values are in `dir` units. Use `Ray::new_normalized` when you want distances.
- `Frustum::from_view_proj` accepts the same `clip` value that built the projection matrix.
