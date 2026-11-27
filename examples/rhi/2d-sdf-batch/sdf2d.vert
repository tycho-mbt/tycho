#version 450

layout(push_constant) uniform Viewport {
  vec4 vp; // (width, height, 1.0 / width, 1.0 / height)
} pc;

struct UiQuad {
  vec4 rect;         // x, y, w, h (pixels, Y-down)
  vec4 radii;        // tl, tr, br, bl corner radii (pixels)
  vec4 fill_color;   // straight RGBA
  vec4 border_color; // straight RGBA
  vec4 uv_rect;      // u0, v0, u1, v1 (normalized atlas coords; 0 if unused)
  vec4 params;       // x=border_width, y=softness, z=kind (0=rect, 1=shadow, 2=icon), w=unused
};

layout(std430, set = 0, binding = 0) readonly buffer QuadBuf {
  UiQuad quads[];
};

layout(location = 0) out vec2 v_local_pos;
layout(location = 1) flat out vec2 v_half_size;
layout(location = 2) flat out vec4 v_radii;
layout(location = 3) flat out vec4 v_fill;
layout(location = 4) flat out vec4 v_border;
layout(location = 5) out vec2 v_uv;
layout(location = 6) flat out vec4 v_uv_rect;
layout(location = 7) flat out vec4 v_params;

const vec2 CORNERS[6] = vec2[6](
  vec2(-1.0, -1.0),
  vec2( 1.0, -1.0),
  vec2( 1.0,  1.0),
  vec2(-1.0, -1.0),
  vec2( 1.0,  1.0),
  vec2(-1.0,  1.0)
);

void main() {
  UiQuad q = quads[gl_InstanceIndex];
  vec2 b = max(q.rect.zw * 0.5, vec2(0.5));
  vec2 center = q.rect.xy + b;
  float pad = q.params.y + 1.5;
  vec2 half_ext = b + vec2(pad);
  vec2 c = CORNERS[gl_VertexIndex];
  vec2 p = c * half_ext;
  vec2 screen_pos = center + p;
  vec2 ndc = screen_pos * pc.vp.zw * 2.0 - 1.0;

  gl_Position = vec4(ndc, 0.0, 1.0);
  v_local_pos = p;
  v_half_size = b;
  v_radii = q.radii;
  v_fill = q.fill_color;
  v_border = q.border_color;
  vec2 unit_uv = (p / (2.0 * b)) + 0.5;
  v_uv = mix(q.uv_rect.xy, q.uv_rect.zw, unit_uv);
  v_uv_rect = q.uv_rect;
  v_params = q.params;
}
