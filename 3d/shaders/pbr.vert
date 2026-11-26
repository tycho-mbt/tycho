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

layout(push_constant) uniform PC { uint objectIndex; } pc;

layout(location = 0) out vec3 vWorldPos;
layout(location = 1) out vec3 vNormal;
layout(location = 2) out vec2 vUV;

void main() {
    ObjectGpu o = objects[pc.objectIndex];
    vec4 wp = o.model * vec4(inPos, 1.0);
    vWorldPos = wp.xyz;
    vNormal = mat3(o.normalMat) * inNormal;
    vUV = inUV;
    gl_Position = frame.viewProj * wp;
}
