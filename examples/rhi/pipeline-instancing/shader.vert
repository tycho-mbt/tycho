#version 450
layout(location = 0) in vec3 inPos;
layout(location = 1) in vec2 inInstOffset;
layout(location = 2) in vec4 inInstColor;
layout(location = 0) out vec4 vColor;
void main() {
    gl_Position = vec4(inPos.xy + inInstOffset, inPos.z, 1.0);
    vColor = inInstColor;
}
