#version 450

layout(set = 0, binding = 1) uniform sampler2D u_atlas;

layout(location = 0) in vec2 v_local_pos;
layout(location = 1) flat in vec2 v_half_size;
layout(location = 2) flat in vec4 v_radii;
layout(location = 3) flat in vec4 v_fill;
layout(location = 4) flat in vec4 v_border;
layout(location = 5) in vec2 v_uv;
layout(location = 6) flat in vec4 v_uv_rect;
layout(location = 7) flat in vec4 v_params;

layout(location = 0) out vec4 out_color;

float sdRoundedBox(vec2 p, vec2 b, vec4 r) {
  vec2 rr = (p.x > 0.0) ? vec2(r.y, r.z) : vec2(r.x, r.w);
  float rad = (p.y > 0.0) ? rr.y : rr.x;
  rad = min(rad, min(b.x, b.y));
  vec2 q = abs(p) - b + vec2(rad);
  return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - rad;
}

void main() {
  float d = sdRoundedBox(v_local_pos, v_half_size, v_radii);
  int kind = int(v_params.z + 0.5);

  if (kind == 1) {
    // Analytical drop shadow
    float soft = max(v_params.y, 1.0);
    float a = (1.0 - smoothstep(-soft * 0.35, soft, d)) * v_fill.a;
    out_color = vec4(v_fill.rgb * a, a);
    return;
  }

  float cov = clamp(0.5 - d, 0.0, 1.0);
  if (kind == 2) {
    // Atlas icon / glyph tinted by v_fill, clipped by SDF rounded rect
    vec4 tex = texture(u_atlas, clamp(v_uv, v_uv_rect.xy, v_uv_rect.zw));
    float a = v_fill.a * tex.a * cov;
    out_color = vec4(v_fill.rgb * tex.rgb * a, a);
    return;
  }

  // kind == 0: SDF rounded rect + optional border + optional atlas tint
  vec4 tex = (v_uv_rect.z > v_uv_rect.x)
    ? texture(u_atlas, clamp(v_uv, v_uv_rect.xy, v_uv_rect.zw))
    : vec4(1.0);
  vec4 col = v_fill * tex;
  float bw = v_params.x;
  if (bw > 0.0) {
    float inner_cov = clamp(0.5 - (d + bw), 0.0, 1.0);
    col = mix(v_border, col, inner_cov);
  }
  float a = col.a * cov;
  out_color = vec4(col.rgb * a, a);
}
