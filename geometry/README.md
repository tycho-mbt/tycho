# `laplaceliu/tycho_geometry`

Zero-dependency pure-MoonBit **mesh data, parametric primitive generators, and
geometry-only format IO**, built on `laplaceliu/tycho_math` and nothing else.

This module is the CPU content layer of the Tycho graphics stack (see
[ADR-003](../../roadmap/adr-003-standalone-geometry-module.md)):

- **No GPU / RHI dependency** — compiles on `native`, `wasm`, and `js`, and all
  tests run headless.
- **Mesh data** — `MeshData` with a fixed canonical layout:
  `positions : FixedArray[Vec3]`, `normals : FixedArray[Vec3]`,
  `uvs : FixedArray[Vec2]`, `indices : FixedArray[UInt]`, plus optional
  `tangents` / vertex `colors` and multi-material `groups`.
- **Generators** — `box`, `plane`, `circle`, `ring`, `sphere`, `cylinder`,
  `cone`, `capsule`, `torus`.
- **Operations** — `bounds`, `compute_vertex_normals`, `compute_tangents`,
  `transformed`, `merge`, `to_non_indexed`, `flipped`.
- **IO** — `parse_obj` / `parse_obj_text` (v/vt/vn, polygons, `o`/`g` parts,
  positive and negative indices), and `parse_gltf` (glTF 2.0 subset: embedded
  base64 buffers, POSITION/NORMAL/TEXCOORD_0, sparse accessors, TRS/matrix
  nodes, PBR factors plus base-colour/normal texture references with embedded
  `data:` image URIs decoded to bytes).

## Conventions

- Right-handed, +Y up, -Z forward.
- **CCW is the front face** (`tycho_3d` always sets `FrontFace::CounterClockwise`).
- UV `(0, 0)` is the **top-left** of the image (glTF / Vulkan convention).
- Units are meters; default primitive size is 1.
- `MeshData` indices are always 32-bit; renderers may narrow to 16-bit on upload.

## Usage

```moonbit
let cube = @tgeo.box(width=1.0, height=1.0, depth=1.0)
let ball = @tgeo.sphere(radius=0.5, width_segments=32, height_segments=16)
let parts = @tgeo.parse_obj_text(text) // Array[(String, MeshData)]
```

GPU residency (`GpuMesh`) and everything scene/material-related live in
`laplaceliu/tycho_3d`, not here.

## Test

```bash
moon test --target native
```
