#version 450
layout(location = 0) in vec3 inPos;
layout(location = 1) in vec2 inUV;
layout(location = 2) in vec3 inNormal;

layout(push_constant) uniform ShadowPC {
    mat4 lightVP;
} pc;

void main() {
    gl_Position = pc.lightVP * vec4(inPos, 1.0);
}
