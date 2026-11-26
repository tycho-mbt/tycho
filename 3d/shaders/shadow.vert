#version 450
layout(location = 0) in vec3 inPos;
layout(location = 1) in vec3 inNormal;
layout(location = 2) in vec2 inUV;

layout(binding = 0) uniform FrameUBO {
    mat4 viewProj;
    mat4 lightVP;
    vec4 camPos;
    vec4 params;
} frame;

struct ObjectGpu {
    mat4 model;
    mat4 normalMat;
    float material;
    float pad0;
    float pad1;
    float pad2;
};
layout(std430, binding = 1) readonly buffer ObjectBuf { ObjectGpu objects[]; };

layout(push_constant) uniform PC { uint firstObject; } pc;

void main() {
    ObjectGpu o = objects[pc.firstObject + uint(gl_InstanceIndex)];
    gl_Position = frame.lightVP * o.model * vec4(inPos, 1.0);
}
