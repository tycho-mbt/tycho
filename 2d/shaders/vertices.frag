#version 450

layout(push_constant) uniform PC {
  vec4 vp;
  vec4 uv_rect;
  vec4 flags;
  vec4 pad;
} pc;

layout(set = 0, binding = 0) uniform sampler2D u_tex;

layout(location = 0) in vec4 v_color;
layout(location = 1) in vec2 v_uv;

layout(location = 0) out vec4 out_color;

void main() {
  vec4 c = v_color;
  if (pc.flags.x > 0.5) {
    c = c * texture(u_tex, v_uv);
  }
  out_color = vec4(c.rgb * c.a, c.a);
}
