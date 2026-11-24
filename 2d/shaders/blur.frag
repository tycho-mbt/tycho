#version 450

layout(push_constant) uniform BlurPC {
  vec4 dst_rect;   // (x, y, w, h) normalized [0..1]
  vec4 src_uv;     // (u0, v0, u1, v1)
  vec4 params;     // x=dx, y=dy, z=dst_tex_w, w=mode (0=9-tap blur, 1=composite)
  vec4 tint;       // xyz=rgb tint, w=alpha (or dst_tex_h packed? keep w=alpha; compute px from gl_FragCoord.xy!)
  vec4 clip_rect;  // (x, y, w, h) in pixels; z/w <= 0 disables
  vec4 clip_radii; // (tl, tr, br, bl)
} pc;

layout(set = 0, binding = 0) uniform sampler2D u_tex;

layout(location = 0) in vec2 v_uv;
layout(location = 1) in vec2 v_px;
layout(location = 0) out vec4 out_color;

float sdRoundedBox(vec2 p, vec2 b, vec4 r) {
  vec2 rr = (p.x > 0.0) ? vec2(r.y, r.z) : vec2(r.x, r.w);
  float rad = (p.y > 0.0) ? rr.y : rr.x;
  rad = min(rad, min(b.x, b.y));
  vec2 q = abs(p) - b + vec2(rad);
  return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - rad;
}

void main() {
  int mode = int(pc.params.w + 0.5);
  vec2 uv_min = min(pc.src_uv.xy, pc.src_uv.zw);
  vec2 uv_max = max(pc.src_uv.xy, pc.src_uv.zw);
  if (mode == 1) {
    float cov = 1.0;
    if (pc.clip_rect.z > 0.0 && pc.clip_rect.w > 0.0) {
      vec2 chalf = pc.clip_rect.zw * 0.5;
      vec2 ccenter = pc.clip_rect.xy + chalf;
      float d = sdRoundedBox(gl_FragCoord.xy - ccenter, chalf, pc.clip_radii);
      cov = clamp(0.5 - d, 0.0, 1.0);
      if (cov <= 0.001) {
        out_color = vec4(0.0);
        return;
      }
    }
    vec4 s = texture(u_tex, clamp(v_uv, uv_min, uv_max));
    out_color = vec4(s.rgb * pc.tint.rgb * pc.tint.a * cov, s.a * pc.tint.a * cov);
    return;
  }
  vec2 step_uv = pc.params.xy;
  vec4 sum = texture(u_tex, clamp(v_uv, uv_min, uv_max)) * 0.227027;
  float w1 = 0.1945946;
  float w2 = 0.1216216;
  float w3 = 0.054054;
  float w4 = 0.016216;
  sum += texture(u_tex, clamp(v_uv + step_uv * 1.0, uv_min, uv_max)) * w1;
  sum += texture(u_tex, clamp(v_uv - step_uv * 1.0, uv_min, uv_max)) * w1;
  sum += texture(u_tex, clamp(v_uv + step_uv * 2.0, uv_min, uv_max)) * w2;
  sum += texture(u_tex, clamp(v_uv - step_uv * 2.0, uv_min, uv_max)) * w2;
  sum += texture(u_tex, clamp(v_uv + step_uv * 3.0, uv_min, uv_max)) * w3;
  sum += texture(u_tex, clamp(v_uv - step_uv * 3.0, uv_min, uv_max)) * w3;
  sum += texture(u_tex, clamp(v_uv + step_uv * 4.0, uv_min, uv_max)) * w4;
  sum += texture(u_tex, clamp(v_uv - step_uv * 4.0, uv_min, uv_max)) * w4;
  out_color = sum;
}
