#version 450
layout(location = 0) in vec2 inPos;
layout(push_constant) uniform PC {
    vec4 color;
} pc;
layout(location = 0) out vec4 vColor;
void main() {
    gl_Position = vec4(inPos, 0.5, 1.0);
    vColor = pc.color;
}
