#version 450

layout(push_constant) uniform PathPC {
  vec4 vp; // (width, height, 1/width, 1/height)
} pc;

layout(location = 0) in vec2 in_pos;

void main() {
  vec2 ndc = in_pos * pc.vp.zw * 2.0 - 1.0;
  gl_Position = vec4(ndc, 0.0, 1.0);
}
