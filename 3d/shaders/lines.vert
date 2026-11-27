#version 450
layout(location = 0) in vec3 inPos;
layout(location = 1) in vec3 inColor;

layout(binding = 0) uniform FrameUBO {
    mat4 viewProj;
    mat4 lightVP;
    vec4 camPos;
    vec4 params;
} frame;

// Per-draw state: the node's world transform plus a colour tint. Debug lines
// push the identity matrix and a white tint.
layout(push_constant) uniform LinePush {
    mat4 model;
    vec4 tint;
} pc;

layout(location = 0) out vec3 vColor;

void main() {
    vColor = inColor * pc.tint.rgb;
    gl_Position = frame.viewProj * pc.model * vec4(inPos, 1.0);
}
