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
layout(std430, set = 0, binding = 1) readonly buffer ColorMatBuf {
  vec4 m[5];
} cmat;

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
  if (mode == 4) {
    // 4-tap box downsample: params.xy = source texel size in UV units.
    vec2 t = pc.params.xy;
    vec4 s = texture(u_tex, clamp(v_uv, uv_min, uv_max));
    s += texture(u_tex, clamp(v_uv + vec2(t.x, 0.0), uv_min, uv_max));
    s += texture(u_tex, clamp(v_uv + vec2(0.0, t.y), uv_min, uv_max));
    s += texture(u_tex, clamp(v_uv + t, uv_min, uv_max));
    out_color = s * 0.25;
    return;
  }
  if (mode == 1 || mode == 2 || mode == 3) {
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
    if (mode == 2) {
      vec3 rgb = (s.a > 1e-5) ? (s.rgb / s.a) : vec3(0.0);
      vec4 u = vec4(rgb, s.a);
      vec4 r0 = cmat.m[0];
      vec4 r1 = vec4(cmat.m[1].yzw, cmat.m[2].x);
      vec4 r2 = vec4(cmat.m[2].zw, cmat.m[3].xy);
      vec4 r3 = vec4(cmat.m[3].w, cmat.m[4].xyz);
      float r = clamp(dot(r0, u) + cmat.m[1].x, 0.0, 1.0);
      float g = clamp(dot(r1, u) + cmat.m[2].y, 0.0, 1.0);
      float b = clamp(dot(r2, u) + cmat.m[3].z, 0.0, 1.0);
      float a = clamp(dot(r3, u) + cmat.m[4].w, 0.0, 1.0) * pc.tint.a * cov;
      out_color = vec4(vec3(r, g, b) * a, a);
      return;
    }
    if (mode == 3) {
      float a = s.a * pc.tint.a * cov;
      out_color = vec4(pc.tint.rgb * a, a);
      return;
    }
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
