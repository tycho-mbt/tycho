#version 450
layout(location = 0) in vec3 inPos;
layout(location = 1) in vec3 inNormal;
layout(location = 2) in vec2 inUV;

layout(binding = 0) uniform SceneUBO {
    mat4 viewProj;
    mat4 lightVP;
    vec4 camPos;
    vec4 lightDir;
    vec4 lightColor;
} ubo;

layout(push_constant) uniform ObjPC {
    vec4 posScale;
    vec4 albedoMetallic;
    vec4 roughEmissive;
} pc;

layout(location = 0) out vec3 vWorldPos;
layout(location = 1) out vec3 vNormal;
layout(location = 2) out vec2 vUV;

void main() {
    vec3 worldPos = inPos * pc.posScale.w + pc.posScale.xyz;
    vWorldPos = worldPos;
    vNormal = inNormal;
    vUV = inUV;
    gl_Position = ubo.viewProj * vec4(worldPos, 1.0);
}
