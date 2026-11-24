#version 450

layout(push_constant) uniform BlurPC {
  vec4 dst_rect;   // (x, y, w, h) normalized [0..1] in destination target
  vec4 src_uv;     // (u0, v0, u1, v1)
  vec4 params;     // x=dx, y=dy, z=dst_tex_w, w=mode (0=blur, 1=composite)
  vec4 tint;       // RGBA tint/alpha multiplier for composite
  vec4 clip_rect;  // (x, y, w, h) in pixels; w < 0 disables rounded clip
  vec4 clip_radii; // (tl, tr, br, bl)
} pc;

layout(location = 0) out vec2 v_uv;
layout(location = 1) out vec2 v_px;

const vec2 QUAD[6] = vec2[6](
  vec2(0.0, 0.0),
  vec2(1.0, 0.0),
  vec2(1.0, 1.0),
  vec2(0.0, 0.0),
  vec2(1.0, 1.0),
  vec2(0.0, 1.0)
);

void main() {
  vec2 c = QUAD[gl_VertexIndex];
  vec2 pos = pc.dst_rect.xy + c * pc.dst_rect.zw;
  gl_Position = vec4(pos * 2.0 - 1.0, 0.0, 1.0);
  v_uv = mix(pc.src_uv.xy, pc.src_uv.zw, c);
  v_px = pos * vec2(pc.params.z, pc.tint.w > 1.5 ? pc.tint.w : pc.params.z);
}
