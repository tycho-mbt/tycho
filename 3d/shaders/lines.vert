#version 450
layout(location = 0) in vec3 inPos;
layout(location = 1) in vec3 inColor;

layout(binding = 0) uniform FrameUBO {
    mat4 viewProj;
    mat4 lightVP;
    vec4 camPos;
    vec4 params;
} frame;

layout(location = 0) out vec3 vColor;

void main() {
    vColor = inColor;
    gl_Position = frame.viewProj * vec4(inPos, 1.0);
}
