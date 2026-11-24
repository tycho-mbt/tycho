#version 450

layout(push_constant) uniform CoverPC {
  vec4 vp;          // (width, height, 1/width, 1/height)
  vec4 color0;      // straight RGBA
  vec4 color1;      // straight RGBA (gradient end)
  vec4 grad_pts;    // linear: (x0,y0,x1,y1), radial: (cx,cy,r,0)
  vec4 grad_params; // x=grad_type (0=solid,1=linear,2=radial), y=tile_mode
} pc;

layout(location = 0) in vec2 in_pos;
layout(location = 0) out vec2 v_pos;

void main() {
  vec2 ndc = in_pos * pc.vp.zw * 2.0 - 1.0;
  gl_Position = vec4(ndc, 0.0, 1.0);
  v_pos = in_pos;
}
