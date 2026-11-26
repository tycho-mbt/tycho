# `laplaceliu/tycho_3d`

three.js-inspired pure-MoonBit 3D rendering library over `laplaceliu/tycho`
(RHI), `laplaceliu/tycho_math`, and `laplaceliu/tycho_geometry`.

This first slice is the **pure CPU core** (no GPU objects yet):

- `Scene`: arena-based scene graph with generation-checked `NodeId` handles,
  dirty-flag world-transform propagation, reparenting with `keep_world`,
  layers, traversal, subtree destruction, and frustum-culled collection.
- `Camera`: perspective (default infinite reversed-Z) / orthographic
  projections, view/view-projection matrices, screen rays for picking, and the
  rotation-only sky ray matrix.
- `MaterialDesc`: PBR metallic-roughness / unlit descriptions in linear space,
  with an `srgb()` authoring helper.
- `Light`: directional / point / spot / ambient / hemisphere value components
  and shadow configuration.
- `RenderStats3D`: counters with `summary()` and `to_json()` for gates.

The GPU renderer (AOT pipelines, shadow pass, HDR bloom/ACES, examples 61+)
lands in follow-up milestones described in
[`roadmap/tycho-3d-design.md`](../../roadmap/tycho-3d-design.md).

## Conventions

- Right-handed, +Y up, -Z forward; lights and cameras look down local -Z.
- Linear working space; sRGB only at texture input and output encoding.
- One `Quat` source of truth in `Transform` (no Euler/quaternion dual state).

## Test

```bash
moon test --target native
```
