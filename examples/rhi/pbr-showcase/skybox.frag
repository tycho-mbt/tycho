#version 450
layout(binding = 0) uniform SkyUBO {
    mat4 invRotProj;
    vec4 sunDir;
} ubo;
layout(binding = 1) uniform samplerCube uEnvMap;

layout(location = 0) in vec3 vDir;
layout(location = 0) out vec4 outHDR;

void main() {
    vec3 d = normalize(vDir);
    vec3 env = pow(texture(uEnvMap, d).rgb, vec3(2.2)) * 1.4;
    float sunDot = max(dot(d, normalize(ubo.sunDir.xyz)), 0.0);
    vec3 sunGlow = vec3(1.0, 0.88, 0.65) * (pow(sunDot, 128.0) * 5.0 + pow(sunDot, 12.0) * 0.45);
    outHDR = vec4(env + sunGlow, 1.0);
}
