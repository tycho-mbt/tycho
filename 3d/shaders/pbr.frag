#version 450
#extension GL_EXT_nonuniform_qualifier : require
layout(binding = 0) uniform FrameUBO {
    mat4 viewProj;
    mat4 lightVP0;
    mat4 lightVP1;
    vec4 camPos;
    vec4 params;   // x lightCount, y shadow texel, z shadows, w env intensity
    vec4 cascade;  // x split distance, y cascade count
} frame;

struct MaterialGpu {
    vec4 baseColor;
    vec4 emissive;
    vec4 params;    // metallic, roughness, alphaCutoff, flags
    vec4 texParams; // albedo index, normal index, unused, unused
};
layout(std430, binding = 2) readonly buffer MaterialBuf { MaterialGpu materials[]; };

struct LightGpu {
    vec4 color;    // rgb, w = type
    vec4 posDir;   // position (point/spot) or direction (dir), w = range
    vec4 dir;      // spot direction, w = decay
    vec4 params;   // intensity, inner angle, outer angle, unused
};
layout(std430, binding = 3) readonly buffer LightBuf { LightGpu lights[]; };

layout(binding = 4) uniform sampler2DShadow uShadow0;
layout(binding = 5) uniform sampler2DShadow uShadow1;
layout(binding = 6) uniform samplerCube uEnv;
layout(set = 1, binding = 0) uniform sampler2D uTextures[];

layout(push_constant) uniform PC { vec4 params; } pc;

layout(location = 0) in vec3 vWorldPos;
layout(location = 1) in vec3 vNormal;
layout(location = 2) in vec2 vUV;
layout(location = 3) in vec4 vTangent;
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

float sample_shadow_pcf(sampler2DShadow smap, mat4 lvp, vec3 worldPos, vec3 N, vec3 L) {
    vec4 lc = lvp * vec4(worldPos, 1.0);
    vec3 lndc = lc.xyz / lc.w;
    vec2 suv = lndc.xy * 0.5 + 0.5;
    float bias = max(0.004 * (1.0 - dot(N, L)), 0.0012);
    float sz = clamp(lndc.z - bias, 0.0, 1.0);
    float texel = frame.params.y;
    float sum = 0.0;
    for (int x = -1; x <= 1; x++) {
        for (int y = -1; y <= 1; y++) {
            sum += texture(smap, vec3(suv + vec2(float(x), float(y)) * texel, sz));
        }
    }
    return sum / 9.0;
}

vec3 direct_brdf(vec3 N, vec3 V, vec3 L, vec3 radiance, vec3 albedo, float metallic, float roughness) {
    vec3 H = normalize(V + L);
    vec3 F0 = mix(vec3(0.04), albedo, metallic);
    float ndotl = max(dot(N, L), 0.0);
    float ndotv = max(dot(N, V), 0.0);
    float D = d_ggx(N, H, roughness);
    float G = g_smith(N, V, L, roughness);
    vec3 F = fresnel_schlick(max(dot(H, V), 0.0), F0, roughness);
    vec3 spec = (D * G * F) / max(4.0 * ndotv * ndotl, 0.001);
    vec3 kD = (vec3(1.0) - F) * (1.0 - metallic);
    return (kD * albedo / PI + spec) * radiance * ndotl;
}

void main() {
    MaterialGpu m = materials[int(pc.params.y + 0.5)];
    int flags = int(m.params.w + 0.5);
    bool hasAlbedo = (flags & 2) != 0;
    bool hasNormal = (flags & 4) != 0;
    vec4 base = m.baseColor;
    if (hasAlbedo) {
        base *= texture(uTextures[nonuniformEXT(int(m.texParams.x + 0.5))], vUV);
    }
    if (m.params.z > 0.0 && base.a < m.params.z) {
        discard;
    }
    vec3 emissive = m.emissive.rgb;
    if ((flags & 1) != 0) {
        outHDR = vec4(base.rgb + emissive, base.a);
        return;
    }

    vec3 N = normalize(vNormal);
    if (hasNormal) {
        vec3 T = normalize(vTangent.xyz - N * dot(N, vTangent.xyz));
        vec3 B = cross(N, T) * vTangent.w;
        vec3 tn = texture(uTextures[nonuniformEXT(int(m.texParams.y + 0.5))], vUV).xyz * 2.0 - 1.0;
        N = normalize(mat3(T, B, N) * tn);
    }
    vec3 V = normalize(frame.camPos.xyz - vWorldPos);
    vec3 albedo = base.rgb;
    float metallic = clamp(m.params.x, 0.0, 1.0);
    float roughness = clamp(m.params.y, 0.05, 1.0);

    vec3 lighting = vec3(0.0);
    vec3 ambientSum = vec3(0.0);
    int count = int(frame.params.x + 0.5);
    bool shadows = frame.params.z > 0.5;
    for (int i = 0; i < count; ++i) {
        LightGpu l = lights[i];
        int typeCode = int(l.color.w + 0.5);
        if (typeCode == 0) {
            vec3 L = normalize(l.posDir.xyz);
            float sh = 1.0;
            if (shadows) {
                float dist = length(vWorldPos - frame.camPos.xyz);
                sh = dist < frame.cascade.x
                    ? sample_shadow_pcf(uShadow0, frame.lightVP0, vWorldPos, N, L)
                    : sample_shadow_pcf(uShadow1, frame.lightVP1, vWorldPos, N, L);
            }
            lighting += direct_brdf(N, V, L, l.color.rgb * l.params.x, albedo, metallic, roughness) * sh;
        } else if (typeCode == 1 || typeCode == 2) {
            vec3 toLight = l.posDir.xyz - vWorldPos;
            float dist = length(toLight);
            vec3 L = toLight / max(dist, 0.0001);
            float range = l.posDir.w;
            float atten = l.params.x / (1.0 + 0.15 * dist * dist);
            if (range > 0.0) {
                float t = dist / range;
                atten *= clamp(1.0 - t * t, 0.0, 1.0);
            }
            if (typeCode == 2) {
                float cd = dot(-L, normalize(l.dir.xyz));
                atten *= smoothstep(l.params.z, l.params.y, cd);
            }
            lighting += direct_brdf(N, V, L, l.color.rgb * atten, albedo, metallic, roughness);
        } else if (typeCode == 3) {
            ambientSum += l.color.rgb * l.params.x;
        } else if (typeCode == 4) {
            ambientSum += mix(l.posDir.xyz, l.color.rgb, N.y * 0.5 + 0.5) * l.params.x;
        }
    }

    vec3 R = reflect(-V, N);
    float envI = frame.params.w;
    // PMREM chain: mip 0 is sharp, the last mip is a diffuse average.
    float maxLod = float(max(textureQueryLevels(uEnv) - 1, 0));
    vec3 envDiff = textureLod(uEnv, N, maxLod).rgb;
    vec3 envSpec = textureLod(uEnv, R, roughness * maxLod).rgb;
    vec3 F0 = mix(vec3(0.04), albedo, metallic);
    vec3 F_env = fresnel_schlick(max(dot(N, V), 0.0), F0, roughness);
    vec3 ambient = ((1.0 - F_env) * (1.0 - metallic) * envDiff * albedo + F_env * envSpec) + ambientSum * albedo;

    outHDR = vec4(ambient + lighting + emissive, base.a);
}
