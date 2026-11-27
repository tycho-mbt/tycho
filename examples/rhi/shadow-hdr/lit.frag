#version 450
layout(binding = 0) uniform SceneUBO {
    mat4 viewProj;
    mat4 lightVP;
    vec4 lightDir;
} ubo;
layout(binding = 1) uniform sampler2DShadow uShadowMap;
layout(binding = 2) uniform sampler2DArray uTexArray;

layout(location = 0) in vec3 vWorldPos;
layout(location = 1) in vec2 vUV;
layout(location = 2) in vec3 vNormal;

layout(location = 0) out vec4 outHDR;

void main() {
    vec3 N = normalize(vNormal);
    vec3 L = normalize(ubo.lightDir.xyz);
    float ndotl = max(dot(N, L), 0.0);

    float layer = (vWorldPos.y < -0.495) ? 0.0 : 1.0;
    vec3 tex = texture(uTexArray, vec3(vUV, layer)).rgb;
    vec3 albedo = mix(vec3(0.30), tex, 0.70);

    vec4 lc = ubo.lightVP * vec4(vWorldPos, 1.0);
    vec3 lndc = lc.xyz / lc.w;
    vec2 suv = lndc.xy * 0.5 + 0.5;
    float sz = clamp(lndc.z - 0.002, 0.0, 1.0);
    float vis = texture(uShadowMap, vec3(suv, sz));

    vec3 ambient = albedo * 0.06;
    vec3 direct = albedo * (ndotl * 3.8 * vis);
    outHDR = vec4(ambient + direct, 1.0);
}
