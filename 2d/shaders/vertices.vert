#version 450

layout(push_constant) uniform PC {
  vec4 vp;       // (width, height, 1/width, 1/height)
  vec4 uv_rect;  // atlas (u0, v0, u1, v1)
  vec4 flags;    // x = use_texture
  vec4 pad;
} pc;

layout(location = 0) in vec2 a_pos;
layout(location = 1) in vec4 a_color;
layout(location = 2) in vec2 a_uv;

layout(location = 0) out vec4 v_color;
layout(location = 1) out vec2 v_uv;

void main() {
  vec2 ndc = a_pos * pc.vp.zw * 2.0 - 1.0;
  gl_Position = vec4(ndc, 0.0, 1.0);
  v_color = a_color;
  v_uv = mix(pc.uv_rect.xy, pc.uv_rect.zw, a_uv);
}
