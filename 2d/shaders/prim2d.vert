#version 450

layout(push_constant) uniform PassPC {
  vec4 vp;          // (width, height, 1/width, 1/height)
  vec4 clip_rect;   // (x, y, w, h); w < 0 disables analytical ClipRRect
  vec4 clip_radii;  // (tl, tr, br, bl)
  vec4 pad;
} pc;

struct Prim2D {
  vec4 rect;         // (x, y, w, h) in local space, or line (x0, y0, x1, y1) when kind == 5
  vec4 radii;        // (tl, tr, br, bl)
  vec4 fill_color;   // straight RGBA
  vec4 border_color; // straight RGBA
  vec4 uv_rect;      // (u0, v0, u1, v1)
  vec4 params;       // x=border_w, y=softness, z=kind (0=rrect,1=shadow,2=rgba,3=glyph_r8,4=circle,5=line), w=unused
  vec4 xform0;       // (a, c, tx, grad_type: 0=solid,1=linear,2=radial,3=sweep)
  vec4 xform1;       // (b, d, ty, tile_mode: 0=clamp,1=repeat,2=mirror)
  vec4 grad_pts;     // linear: (x0,y0,x1,y1); radial: (cx,cy,r,0)
  vec4 grad_info;    // x=stop_offset, y=stop_count
};

layout(std430, set = 0, binding = 0) readonly buffer PrimBuf {
  Prim2D prims[];
};

layout(location = 0) out vec2 v_local_pos;
layout(location = 1) flat out vec2 v_half_size;
layout(location = 2) flat out vec4 v_radii;
layout(location = 3) flat out vec4 v_fill;
layout(location = 4) flat out vec4 v_border;
layout(location = 5) out vec2 v_uv;
layout(location = 6) flat out vec4 v_uv_rect;
layout(location = 7) flat out vec4 v_params;
layout(location = 8) out vec2 v_screen_pos;
layout(location = 9) out vec2 v_shape_pos;
layout(location = 10) flat out vec4 v_grad_pts;
layout(location = 11) flat out vec4 v_grad_meta; // x=grad_type, y=tile_mode, z=stop_off, w=stop_cnt

const vec2 CORNERS[6] = vec2[6](
  vec2(-1.0, -1.0),
  vec2( 1.0, -1.0),
  vec2( 1.0,  1.0),
  vec2(-1.0, -1.0),
  vec2( 1.0,  1.0),
  vec2(-1.0,  1.0)
);

void main() {
  Prim2D q = prims[gl_InstanceIndex];
  int kind = int(q.params.z + 0.5);
  vec2 c = CORNERS[gl_VertexIndex];
  vec2 local_pt;
  vec2 b;
  vec2 p;
  if (kind == 5) {
    // Line capsule: q.rect = (x0, y0, x1, y1), q.params.x = half_width
    vec2 p0 = q.rect.xy;
    vec2 p1 = q.rect.zw;
    float hw = max(q.params.x, 0.5);
    vec2 bmin = min(p0, p1) - vec2(hw + 2.0);
    vec2 bmax = max(p0, p1) + vec2(hw + 2.0);
    vec2 center = 0.5 * (bmin + bmax);
    vec2 half_ext = 0.5 * (bmax - bmin);
    local_pt = center + c * half_ext;
    b = vec2(hw, 0.0);
    p = local_pt;
  } else {
    b = max(q.rect.zw * 0.5, vec2(0.5));
    vec2 center = q.rect.xy + b;
    float pad = q.params.y + 1.5;
    vec2 half_ext = b + vec2(pad);
    p = c * half_ext;
    local_pt = center + p;
  }

  vec2 screen_pos = vec2(
    q.xform0.x * local_pt.x + q.xform0.y * local_pt.y + q.xform0.z,
    q.xform1.x * local_pt.x + q.xform1.y * local_pt.y + q.xform1.z
  );
  vec2 ndc = screen_pos * pc.vp.zw * 2.0 - 1.0;

  gl_Position = vec4(ndc, 0.0, 1.0);
  v_local_pos = p;
  v_half_size = b;
  v_radii = q.radii;
  v_fill = q.fill_color;
  v_border = q.border_color;
  vec2 unit_uv = (kind == 5) ? vec2(0.0) : ((p / (2.0 * b)) + 0.5);
  v_uv = mix(q.uv_rect.xy, q.uv_rect.zw, unit_uv);
  v_uv_rect = q.uv_rect;
  v_params = q.params;
  v_screen_pos = screen_pos;
  v_shape_pos = local_pt;
  v_grad_pts = q.grad_pts;
  v_grad_meta = vec4(q.xform0.w, q.xform1.w, q.grad_info.x, q.grad_info.y);
}
