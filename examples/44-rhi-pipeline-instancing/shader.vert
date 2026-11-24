#version 450
layout(location = 0) in vec2 inPos;
layout(location = 1) in vec2 inInstOffset;
layout(location = 2) in vec3 inInstColor;
layout(location = 0) out vec3 vColor;
void main() {
    gl_Position = vec4(inPos + inInstOffset, 0.0, 1.0);
    vColor = inInstColor;
}
