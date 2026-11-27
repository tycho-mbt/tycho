#version 450
layout(binding = 0) uniform SceneUBO {
    mat4 viewProj;
    mat4 lightVP;
    vec4 camPos;
    vec4 lightDir;
    vec4 lightColor;
} ubo;
layout(binding = 1) uniform sampler2DShadow uShadowMap;
layout(binding = 2) uniform samplerCube uEnvMap;

layout(push_constant) uniform ObjPC {
    vec4 posScale;
    vec4 albedoMetallic;
    vec4 roughEmissive;
} pc;

layout(location = 0) in vec3 vWorldPos;
layout(location = 1) in vec3 vNormal;
layout(location = 2) in vec2 vUV;

layout(location = 0) out vec4 outHDR;

const float PI = 3.14159265359;

float d_ggx(vec3 N, vec3 H, float roughness) {
    float a = roughness * roughness;
    float a2 = a * a;
    float ndoth = max(dot(N, H), 0.0);
    float denom = ndoth * ndoth * (a2 - 1.0) + 1.0;
    return a2 / max(PI * denom * denom, 0.0001);
}

float g_schlick_ggx(float ndotv, float roughness) {
    float r = roughness + 1.0;
    float k = (r * r) / 8.0;
    return ndotv / max(ndotv * (1.0 - k) + k, 0.0001);
}

float g_smith(vec3 N, vec3 V, vec3 L, float roughness) {
    return g_schlick_ggx(max(dot(N, V), 0.0), roughness) *
           g_schlick_ggx(max(dot(N, L), 0.0), roughness);
}

vec3 fresnel_schlick(float cosTheta, vec3 F0, float roughness) {
    return F0 + (max(vec3(1.0 - roughness), F0) - F0) * pow(clamp(1.0 - cosTheta, 0.0, 1.0), 5.0);
}

float sample_shadow_pcf(vec3 worldPos, vec3 N, vec3 L) {
    vec4 lc = ubo.lightVP * vec4(worldPos, 1.0);
    vec3 lndc = lc.xyz / lc.w;
    vec2 suv = lndc.xy * 0.5 + 0.5;
    float bias = max(0.004 * (1.0 - dot(N, L)), 0.0012);
    float sz = clamp(lndc.z - bias, 0.0, 1.0);
    float texel = 1.0 / 512.0;
    float sum = 0.0;
    for (int x = -1; x <= 1; x++) {
        for (int y = -1; y <= 1; y++) {
            sum += texture(uShadowMap, vec3(suv + vec2(float(x), float(y)) * texel, sz));
        }
    }
    return sum / 9.0;
}

void main() {
    vec3 N = normalize(vNormal);
    vec3 V = normalize(ubo.camPos.xyz - vWorldPos);
    vec3 L = normalize(ubo.lightDir.xyz);
    vec3 H = normalize(V + L);

    vec3 albedo = pc.albedoMetallic.rgb;
    float metallic = pc.albedoMetallic.a;
    float roughness = clamp(pc.roughEmissive.x, 0.05, 1.0);
    vec3 emissive = pc.roughEmissive.yzw;

    // Subtle procedural tile pattern on ground plane (emissive < 0 flags ground)
    if (emissive.x < -0.5) {
        vec2 tile = floor(vWorldPos.xz * 1.25);
        float chk = mod(tile.x + tile.y, 2.0);
        albedo = mix(vec3(0.14, 0.16, 0.20), vec3(0.32, 0.34, 0.38), chk);
        emissive = vec3(0.0);
    }

    vec3 F0 = mix(vec3(0.04), albedo, metallic);
    float ndotl = max(dot(N, L), 0.0);
    float ndotv = max(dot(N, V), 0.0);

    float D = d_ggx(N, H, roughness);
    float G = g_smith(N, V, L, roughness);
    vec3 F = fresnel_schlick(max(dot(H, V), 0.0), F0, roughness);
    vec3 spec = (D * G * F) / max(4.0 * ndotv * ndotl, 0.001);
    vec3 kD = (vec3(1.0) - F) * (1.0 - metallic);

    float shadow = sample_shadow_pcf(vWorldPos, N, L);
    vec3 direct = (kD * albedo / PI + spec) * ubo.lightColor.rgb * ndotl * shadow;

    // Cubemap IBL (diffuse irradiance + mirror-like env reflection attenuated by roughness)
    vec3 R = reflect(-V, N);
    vec3 envDiff = pow(texture(uEnvMap, N).rgb, vec3(2.2)) * 0.55;
    vec3 envSpec = pow(texture(uEnvMap, mix(R, N, roughness * roughness)).rgb, vec3(2.2)) * (1.4 - roughness * 0.85);
    vec3 F_env = fresnel_schlick(ndotv, F0, roughness);
    vec3 ambient = ((1.0 - F_env) * (1.0 - metallic) * envDiff * albedo + F_env * envSpec);

    outHDR = vec4(ambient + direct + emissive, 1.0);
}
