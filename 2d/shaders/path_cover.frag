#version 450

layout(push_constant) uniform CoverPC {
  vec4 vp;
  vec4 color0;
  vec4 color1;
  vec4 grad_pts;
  vec4 grad_params;
} pc;

layout(location = 0) in vec2 v_pos;
layout(location = 0) out vec4 out_color;

float tileParam(float t, int mode) {
  if (mode == 1) return fract(t);
  if (mode == 2) {
    float p = mod(t, 2.0);
    return (p <= 1.0) ? p : (2.0 - p);
  }
  return clamp(t, 0.0, 1.0);
}

void main() {
  int gtype = int(pc.grad_params.x + 0.5);
  vec4 col = pc.color0;
  if (gtype != 0) {
    int tile = int(pc.grad_params.y + 0.5);
    float t = 0.0;
    if (gtype == 1) {
      vec2 a = pc.grad_pts.xy;
      vec2 ab = pc.grad_pts.zw - a;
      t = dot(v_pos - a, ab) / max(dot(ab, ab), 1e-6);
    } else {
      t = length(v_pos - pc.grad_pts.xy) / max(pc.grad_pts.z, 1e-4);
    }
    col = mix(pc.color0, pc.color1, tileParam(t, tile));
  }
  out_color = vec4(col.rgb * col.a, col.a);
}
