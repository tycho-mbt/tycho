#version 450
layout(location = 0) in vec3 inPos;
layout(location = 1) in vec3 inNormal;
layout(location = 2) in vec2 inUV;

layout(push_constant) uniform ShadowPC {
    mat4 lightVP;
    vec4 posScale;
} pc;

void main() {
    vec3 worldPos = inPos * pc.posScale.w + pc.posScale.xyz;
    gl_Position = pc.lightVP * vec4(worldPos, 1.0);
}
