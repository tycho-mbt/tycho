#version 450

layout(push_constant) uniform PassPC {
  vec4 vp;          // (width, height, 1/width, 1/height)
  vec4 clip_rect;   // (x, y, w, h); w < 0 disables analytical ClipRRect
  vec4 clip_radii;  // (tl, tr, br, bl)
  vec4 pad;
} pc;

struct GradientStop {
  vec4 color; // straight RGBA
  vec4 pos;   // x = offset
};

layout(std430, set = 0, binding = 1) readonly buffer GradBuf {
  GradientStop stops[];
};

layout(set = 0, binding = 2) uniform sampler2D u_glyph_atlas;
layout(set = 0, binding = 3) uniform sampler2D u_color_atlas;
layout(set = 0, binding = 4) uniform sampler2D u_msdf_atlas;

layout(location = 0) in vec2 v_local_pos;
layout(location = 1) flat in vec2 v_half_size;
layout(location = 2) flat in vec4 v_radii;
layout(location = 3) flat in vec4 v_fill;
layout(location = 4) flat in vec4 v_border;
layout(location = 5) in vec2 v_uv;
layout(location = 6) flat in vec4 v_uv_rect;
layout(location = 7) flat in vec4 v_params;
layout(location = 8) in vec2 v_screen_pos;
layout(location = 9) in vec2 v_shape_pos;
layout(location = 10) flat in vec4 v_grad_pts;
layout(location = 11) flat in vec4 v_grad_meta;
layout(location = 12) flat in vec4 v_grad_extra;
layout(location = 13) flat in vec4 v_radii_y;
layout(location = 14) flat in vec4 v_clip;

layout(location = 0) out vec4 out_color;

float sdRoundedBox(vec2 p, vec2 b, vec4 r) {
  vec2 rr = (p.x > 0.0) ? vec2(r.y, r.z) : vec2(r.x, r.w);
  float rad = (p.y > 0.0) ? rr.y : rr.x;
  rad = min(rad, min(b.x, b.y));
  vec2 q = abs(p) - b + vec2(rad);
  return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - rad;
}

// Rounded box with per-corner elliptical radii. The corner ellipse is evaluated
// with a first-order distance approximation, which is accurate where it matters
// (near the edge) and reduces exactly to sdRoundedBox when rx == ry.
float sdRoundBoxElliptic(vec2 p, vec2 b, vec4 rx, vec4 ry) {
  vec2 rx2 = (p.x > 0.0) ? vec2(rx.y, rx.z) : vec2(rx.x, rx.w);
  vec2 ry2 = (p.x > 0.0) ? vec2(ry.y, ry.z) : vec2(ry.x, ry.w);
  float rxc = (p.y > 0.0) ? rx2.y : rx2.x;
  float ryc = (p.y > 0.0) ? ry2.y : ry2.x;
  vec2 r = min(vec2(rxc, ryc), b);
  vec2 c = b - r;
  vec2 ap = abs(p);
  vec2 q = ap - c;
  if (q.x <= 0.0 && q.y <= 0.0) {
    return max(ap.x - b.x, ap.y - b.y);
  }
  if (q.x <= 0.0) {
    return ap.y - b.y;
  }
  if (q.y <= 0.0) {
    return ap.x - b.x;
  }
  vec2 rr = max(r, vec2(1e-4));
  float f = length(q / rr);
  float g = length(q / (rr * rr));
  return (f - 1.0) * f / max(g, 1e-6);
}

// Per-instance rectangular clip with a 1px analytic edge.
float rectClipCov(vec2 p, vec4 c) {
  if (c.z <= 0.0 || c.w <= 0.0) {
    return 1.0;
  }
  vec2 lo = c.xy;
  vec2 hi = c.xy + c.zw;
  vec2 a = smoothstep(lo - 0.5, lo + 0.5, p);
  vec2 b = vec2(1.0) - smoothstep(hi - 0.5, hi + 0.5, p);
  return a.x * a.y * b.x * b.y;
}

float sdSegment(vec2 p, vec2 a, vec2 b) {
  vec2 pa = p - a;
  vec2 ba = b - a;
  float h = clamp(dot(pa, ba) / max(dot(ba, ba), 1e-6), 0.0, 1.0);
  return length(pa - ba * h);
}

float tileParam(float t, int mode) {
  if (mode == 1) {
    return fract(t);
  } else if (mode == 2) {
    float p = mod(t, 2.0);
    return (p <= 1.0) ? p : (2.0 - p);
  }
  return clamp(t, 0.0, 1.0);
}

vec4 evalGradient(vec2 pt) {
  int gtype = int(v_grad_meta.x + 0.5);
  if (gtype == 0) {
    return v_fill;
  }
  if (gtype == 4) {
    // ImagePattern: inv_matrix in v_grad_pts + v_grad_extra.xy, tile_x in v_grad_meta.y, tile_y in v_params.w
    vec2 puv = vec2(
      v_grad_pts.x * pt.x + v_grad_pts.y * pt.y + v_grad_pts.z,
      v_grad_pts.w * pt.x + v_grad_extra.x * pt.y + v_grad_extra.y
    );
    int packed_tile = int(v_grad_meta.y + 0.5);
    int tx_mode = packed_tile & 3;
    int ty_mode = (packed_tile >> 2) & 3;
    if ((tx_mode == 3 && (puv.x < 0.0 || puv.x > 1.0)) ||
        (ty_mode == 3 && (puv.y < 0.0 || puv.y > 1.0))) {
      return vec4(0.0);
    }
    vec2 tuv = vec2(tileParam(puv.x, tx_mode), tileParam(puv.y, ty_mode));
    vec2 auv = mix(v_uv_rect.xy, v_uv_rect.zw, tuv);
    vec4 tex = texture(u_color_atlas, clamp(auv, v_uv_rect.xy, v_uv_rect.zw));
    return vec4(tex.rgb * v_fill.rgb, tex.a * v_fill.a);
  }
  int tile = int(v_grad_meta.y + 0.5);
  float t = 0.0;
  if (gtype == 1) {
    vec2 a = v_grad_pts.xy;
    vec2 ab = v_grad_pts.zw - a;
    t = dot(pt - a, ab) / max(dot(ab, ab), 1e-6);
  } else if (gtype == 2) {
    float r = max(v_grad_pts.z, 1e-4);
    t = length(pt - v_grad_pts.xy) / r;
  } else {
    vec2 d = pt - v_grad_pts.xy;
    float ang = atan(d.y, d.x);
    if (ang < 0.0) ang += 6.2831853;
    float a0 = v_grad_pts.z;
    float a1 = v_grad_pts.w;
    t = (ang - a0) / max(a1 - a0, 1e-4);
  }
  t = tileParam(t, tile);
  int off = int(v_grad_meta.z + 0.5);
  int cnt = int(v_grad_meta.w + 0.5);
  if (cnt <= 1) {
    return (cnt == 1) ? stops[off].color : v_fill;
  }
  if (t <= stops[off].pos.x) return stops[off].color;
  for (int i = 0; i < cnt - 1; i++) {
    GradientStop s0 = stops[off + i];
    GradientStop s1 = stops[off + i + 1];
    if (t <= s1.pos.x) {
      float f = (t - s0.pos.x) / max(s1.pos.x - s0.pos.x, 1e-5);
      return mix(s0.color, s1.color, clamp(f, 0.0, 1.0));
    }
  }
  return stops[off + cnt - 1].color;
}

void main() {
  float clip_cov = rectClipCov(v_screen_pos, v_clip);
  if (pc.clip_rect.z > 0.0 && pc.clip_rect.w > 0.0) {
    vec2 chalf = pc.clip_rect.zw * 0.5;
    vec2 ccenter = pc.clip_rect.xy + chalf;
    float dc = sdRoundedBox(v_screen_pos - ccenter, chalf, pc.clip_radii);
    clip_cov = clip_cov * clamp(0.5 - dc, 0.0, 1.0);
    if (clip_cov <= 0.001) {
      out_color = vec4(0.0);
      return;
    }
  }

  int kind = int(v_params.z + 0.5);
  if (kind == 5) {
    // Line capsule
    float d = sdSegment(v_shape_pos, v_radii.xy, v_radii.zw) - v_half_size.x;
    float cov = clamp(0.5 - d, 0.0, 1.0) * clip_cov;
    vec4 base = evalGradient(v_shape_pos);
    float a = base.a * cov;
    out_color = vec4(base.rgb * a, a);
    return;
  }

  if (kind == 6) {
    // Pre-rasterized CPU coverage bitmap (R8), already antialiased.
    float ga = texture(u_glyph_atlas, clamp(v_uv, v_uv_rect.xy, v_uv_rect.zw)).r;
    float a = v_fill.a * ga * clip_cov;
    out_color = vec4(v_fill.rgb * a, a);
    return;
  }

  if (kind == 7) {
    // Color glyph (CBDT emoji) from the RGBA atlas, no SDF edge.
    vec4 tex = texture(u_color_atlas, clamp(v_uv, v_uv_rect.xy, v_uv_rect.zw));
    float a = v_fill.a * tex.a * clip_cov;
    out_color = vec4(v_fill.rgb * tex.rgb * a, a);
    return;
  }

  if (kind == 8) {
    // Signed-distance glyph: d > 0.5 is inside.
    float d = texture(u_glyph_atlas, clamp(v_uv, v_uv_rect.xy, v_uv_rect.zw)).r;
    float w = max(fwidth(d), 0.0001);
    float a = smoothstep(0.5 - w, 0.5 + w, d) * v_fill.a * clip_cov;
    out_color = vec4(v_fill.rgb * a, a);
    return;
  }

  if (kind == 9) {
    // MSDF glyph from the dedicated RGBA atlas; median of RGB keeps corners.
    vec3 msd = texture(u_msdf_atlas, clamp(v_uv, v_uv_rect.xy, v_uv_rect.zw)).rgb;
    float d = max(min(msd.r, msd.g), min(max(msd.r, msd.g), msd.b));
    float w = max(fwidth(d), 0.0001);
    float a = smoothstep(0.5 - w, 0.5 + w, d) * v_fill.a * clip_cov;
    out_color = vec4(v_fill.rgb * a, a);
    return;
  }

  float d = (kind == 4)
    ? (length(v_local_pos) - min(v_half_size.x, v_half_size.y))
    : sdRoundBoxElliptic(v_local_pos, v_half_size, v_radii, v_radii_y);

  if (kind == 1) {
    // Analytical drop shadow
    float soft = max(v_params.y, 1.0);
    float a = (1.0 - smoothstep(-soft * 0.35, soft, d)) * v_fill.a * clip_cov;
    out_color = vec4(v_fill.rgb * a, a);
    return;
  }

  float cov = clamp(0.5 - d, 0.0, 1.0) * clip_cov;
  if (kind == 3) {
    // R8 glyph atlas tinted by v_fill
    float ga = texture(u_glyph_atlas, clamp(v_uv, v_uv_rect.xy, v_uv_rect.zw)).r;
    float a = v_fill.a * ga * cov;
    out_color = vec4(v_fill.rgb * a, a);
    return;
  }

  if (kind == 2) {
    // RGBA8 atlas/icon tinted by v_fill, SDF clipped
    vec4 tex = texture(u_color_atlas, clamp(v_uv, v_uv_rect.xy, v_uv_rect.zw));
    float a = v_fill.a * tex.a * cov;
    out_color = vec4(v_fill.rgb * tex.rgb * a, a);
    return;
  }

  // kind == 0 or 4: filled + optional border + optional gradient
  vec4 base = evalGradient(v_shape_pos);
  int gtype_check = int(v_grad_meta.x + 0.5);
  if (gtype_check != 4 && v_uv_rect.z > v_uv_rect.x) {
    base *= texture(u_color_atlas, clamp(v_uv, v_uv_rect.xy, v_uv_rect.zw));
  }
  float bw = v_params.x;
  if (bw > 0.0) {
    if (int(v_params.w + 0.5) == 1) {
      // Stroke-only (transparent interior)
      float outer_cov = clamp(0.5 - d, 0.0, 1.0);
      float inner_cov = clamp(0.5 - (d + bw), 0.0, 1.0);
      float ring = max(outer_cov - inner_cov, 0.0) * clip_cov;
      float a = v_border.a * ring;
      out_color = vec4(v_border.rgb * a, a);
      return;
    } else {
      float inner_cov = clamp(0.5 - (d + bw), 0.0, 1.0);
      base = mix(v_border, base, inner_cov);
    }
  }
  float a = base.a * cov;
  out_color = vec4(base.rgb * a, a);
}
