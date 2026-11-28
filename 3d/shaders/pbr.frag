#version 460
#ifdef TYCHO_RAY_SHADOW
#extension GL_EXT_ray_query : require
#endif
#ifndef TYCHO_NO_BINDLESS
#extension GL_EXT_nonuniform_qualifier : require
#endif
layout(binding = 0) uniform FrameUBO {
    mat4 viewProj;
    mat4 lightVP0;
    mat4 lightVP1;
    vec4 camPos;
    vec4 params;   // x lightCount, y shadow texel, z shadows, w env intensity
    vec4 cascade;  // x split distance, y cascade count
    vec4 fogColor; // rgb fog colour, w mode (0 off, 1 linear, 2 exp2)
    vec4 fogParams;// x near, y far, z density
} frame;

struct MaterialGpu {
    vec4 baseColor;
    vec4 emissive;
    vec4 params;    // metallic, roughness, alphaCutoff, flags
    vec4 texParams; // albedo index, normal index, clearcoat, clearcoat roughness
    vec4 sheen;     // rgb sheen colour, w sheen roughness (0 colour disables)
    vec4 transmission; // x amount, y ior (screen-space transmission)
    vec4 iridescence;  // x amount, y film ior, z thickness nm
};
layout(std430, binding = 2) readonly buffer MaterialBuf { MaterialGpu materials[]; };

struct LightGpu {
    vec4 color;    // rgb, w = type
    vec4 posDir;   // position (point/spot) or direction (dir), w = range
    vec4 dir;      // spot direction, w = decay
    vec4 params;   // intensity, inner angle, outer angle, unused
    mat4 shadowVP; // directional/spot light view-projection
    vec4 shadowInfo; // xy tile offset, zw tile scale (z > 0 means enabled)
    vec4 shadowRef;  // x cube tile base, y face count, w 1 for point cube shadows
};
layout(std430, binding = 3) readonly buffer LightBuf { LightGpu lights[]; };

// One entry per shadow tile, shared by directional, spot and point faces.
struct ShadowTileGpu {
    mat4 vp;
    vec4 rect; // xy tile offset, zw tile scale
};
layout(std430, binding = 11) readonly buffer ShadowTileBuf { ShadowTileGpu shadowTiles[]; };

#ifdef TYCHO_RAY_SHADOW
// Hardware ray-traced sun visibility (VK_KHR_ray_query), one ray per fragment.
layout(binding = 14) uniform accelerationStructureEXT uTlas;
#endif

layout(binding = 4) uniform sampler2DShadow uShadow0;
layout(binding = 5) uniform sampler2DShadow uShadow1;
layout(binding = 6) uniform samplerCube uEnv;
layout(binding = 7) uniform sampler2D uBrdf;
#ifdef TYCHO_TRANSMISSION
// Opaque colour copy captured before the transmissive pass (screen space).
layout(binding = 10) uniform sampler2D uSceneColor;
#endif
#ifndef TYCHO_NO_BINDLESS
layout(set = 1, binding = 0) uniform sampler2D uTextures[];
#else
// Non-bindless fallback: one albedo and one normal map, rebound per batch.
layout(binding = 8) uniform sampler2D uAlbedoMap;
layout(binding = 9) uniform sampler2D uNormalMap;
#endif

layout(location = 0) in vec3 vWorldPos;
layout(location = 1) in vec3 vNormal;
layout(location = 2) in vec2 vUV;
layout(location = 3) in vec4 vTangent;
layout(location = 4) flat in float vMaterial;
layout(location = 0) out vec4 outHDR;

vec4 sample_albedo_map(MaterialGpu m, vec2 uv) {
#ifdef TYCHO_NO_BINDLESS
    return texture(uAlbedoMap, uv);
#else
    return texture(uTextures[nonuniformEXT(int(m.texParams.x + 0.5))], uv);
#endif
}

vec3 sample_normal_map(MaterialGpu m, vec2 uv) {
#ifdef TYCHO_NO_BINDLESS
    return texture(uNormalMap, uv).xyz * 2.0 - 1.0;
#else
    return texture(uTextures[nonuniformEXT(int(m.texParams.y + 0.5))], uv).xyz * 2.0 - 1.0;
#endif
}

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

// Shadow atlas: 2x2 tiles, each light owns one tile. Sampling clamps to the
// tile so PCF taps never bleed into a neighbouring light.
float sample_shadow_atlas(sampler2DShadow smap, mat4 lvp, vec4 info, vec3 worldPos, vec3 N, vec3 L) {
    vec4 lc = lvp * vec4(worldPos, 1.0);
    if (lc.w <= 0.0) {
        return 1.0;
    }
    vec3 lndc = lc.xyz / lc.w;
    vec2 suv = lndc.xy * 0.5 + 0.5;
    if (suv.x < 0.0 || suv.x > 1.0 || suv.y < 0.0 || suv.y > 1.0) {
        return 1.0;
    }
    float bias = max(0.004 * (1.0 - dot(N, L)), 0.0012);
    float sz = clamp(lndc.z - bias, 0.0, 1.0);
    vec2 scale = vec2(info.z, info.w);
    vec2 texel = vec2(frame.params.y) * scale; // atlas UV per tile texel
    vec2 base = info.xy + suv * scale;
    vec2 lo = info.xy + texel;
    vec2 hi = info.xy + scale - texel;
    float sum = 0.0;
    for (int x = -1; x <= 1; x++) {
        for (int y = -1; y <= 1; y++) {
            vec2 auv = clamp(base + vec2(float(x), float(y)) * texel, lo, hi);
            sum += texture(smap, vec3(auv, sz));
        }
    }
    return sum / 9.0;
}

// Physical clearcoat: a dielectric specular lobe evaluated at the coat
// roughness, scaled by the coat strength.
vec3 clearcoat_spec(vec3 N, vec3 V, vec3 L, vec3 radiance, float cc, float ccr) {
    if (cc <= 0.001) {
        return vec3(0.0);
    }
    vec3 H = normalize(V + L);
    float ndotl = max(dot(N, L), 0.0);
    float ndotv = max(dot(N, V), 0.0);
    float vdoth = max(dot(V, H), 0.0);
    float D = d_ggx(N, H, ccr);
    float G = g_smith(N, V, L, ccr);
    float F = 0.04 + 0.96 * pow(1.0 - vdoth, 5.0);
    float spec = D * G * F / max(4.0 * ndotv * ndotl, 0.001);
    return vec3(cc * spec) * radiance * ndotl;
}

// Two-beam thin-film interference (Airy) at the R/G/B wavelengths.
// `F0` is the base specular reflectance, `cosTheta` the view cosine and
// `thicknessNm` the film thickness in nanometres. The returned, view-dependent
// reflectance replaces F0 on an iridescent surface.
vec3 thin_film_f0(vec3 F0, float cosTheta, float filmIor, float thicknessNm) {
    float n = max(filmIor, 1.01);
    float cosV = clamp(cosTheta, 0.0, 1.0);
    float sin2 = 1.0 - cosV * cosV;
    // Snell: the angle inside the denser film is smaller than the view angle.
    float cosT = sqrt(max(1.0 - sin2 / (n * n), 0.0));
    const vec3 lambda = vec3(680.0, 550.0, 440.0);
    vec3 phase = (4.0 * PI * n * max(thicknessNm, 0.0) * cosT) / lambda;
    vec3 c = cos(phase);
    // Interface 1 is air -> film (fixed by the film IOR); interface 2 is
    // film -> base, whose reflectance is the material's F0. Treating the base
    // as a perfect mirror correctly removes the effect: a fully reflective
    // surface has nothing left for the film to modulate.
    float f0_film = (n - 1.0) / (n + 1.0);
    vec3 r12 = vec3(f0_film * f0_film);
    vec3 r23 = clamp(F0, 0.0, 1.0);
    vec3 g = sqrt(max(r12 * r23, vec3(0.0)));
    vec3 R = (r12 + r23 + 2.0 * g * c) / (1.0 + r12 * r23 + 2.0 * g * c);
    return clamp(R, 0.0, 1.0);
}

vec3 direct_brdf(vec3 N, vec3 V, vec3 L, vec3 radiance, vec3 albedo, float metallic, float roughness, vec3 F0) {
    vec3 H = normalize(V + L);
    float ndotl = max(dot(N, L), 0.0);
    float ndotv = max(dot(N, V), 0.0);
    float D = d_ggx(N, H, roughness);
    float G = g_smith(N, V, L, roughness);
    vec3 F = fresnel_schlick(max(dot(H, V), 0.0), F0, roughness);
    vec3 spec = (D * G * F) / max(4.0 * ndotv * ndotl, 0.001);
    vec3 kD = (vec3(1.0) - F) * (1.0 - metallic);
    return (kD * albedo / PI + spec) * radiance * ndotl;
}

// glTF KHR_materials_sheen: Charlie distribution + Ashikhmin visibility. It is
// a grazing-angle lobe added on top of the base BRDF, which is what gives
// cloth its soft rim instead of a mirror highlight.
float D_Charlie(float roughness, float NoH) {
    float invAlpha = 1.0 / max(roughness, 0.07);
    float cos2h = NoH * NoH;
    float sin2h = max(1.0 - cos2h, 0.0078125);
    return (2.0 + invAlpha) * pow(sin2h, invAlpha * 0.5) / (2.0 * PI);
}

vec3 sheen_brdf(vec3 N, vec3 V, vec3 L, vec3 sheenColor, float sheenRoughness) {
    vec3 H = normalize(V + L);
    float NoL = max(dot(N, L), 0.0);
    float NoV = max(dot(N, V), 0.0);
    float NoH = max(dot(N, H), 0.0);
    float D = D_Charlie(sheenRoughness, NoH);
    float vis = 1.0 / max(4.0 * (NoL + NoV - NoL * NoV), 1e-4);
    return sheenColor * D * vis * NoL;
}

// Linear-space distance fog, applied before the HDR target is written so the
// blend is tone-mapped with the rest of the frame.
vec3 apply_fog(vec3 color, vec3 worldPos) {
    float mode = frame.fogColor.w;
    if (mode < 0.5) {
        return color;
    }
    float depth = length(frame.camPos.xyz - worldPos);
    float f;
    if (mode < 1.5) {
        float span = max(frame.fogParams.y - frame.fogParams.x, 1e-4);
        f = clamp((depth - frame.fogParams.x) / span, 0.0, 1.0);
    } else {
        float d = frame.fogParams.z * depth;
        f = 1.0 - exp(-d * d);
    }
    return mix(color, frame.fogColor.rgb, f);
}

void main() {
    MaterialGpu m = materials[int(vMaterial + 0.5)];
    int flags = int(m.params.w + 0.5);
    bool hasAlbedo = (flags & 2) != 0;
    bool hasNormal = (flags & 4) != 0;
    vec4 base = m.baseColor;
    if (hasAlbedo) {
        base *= sample_albedo_map(m, vUV);
    }
    if (m.params.z > 0.0 && base.a < m.params.z) {
        discard;
    }
    vec3 emissive = m.emissive.rgb;
    if ((flags & 1) != 0) {
        outHDR = vec4(apply_fog(base.rgb + emissive, vWorldPos), base.a);
        return;
    }

    vec3 N = normalize(vNormal);
    if (hasNormal) {
        vec3 T = normalize(vTangent.xyz - N * dot(N, vTangent.xyz));
        vec3 B = cross(N, T) * vTangent.w;
        vec3 tn = sample_normal_map(m, vUV);
        N = normalize(mat3(T, B, N) * tn);
    }
    vec3 V = normalize(frame.camPos.xyz - vWorldPos);
    vec3 albedo = base.rgb;
    float metallic = clamp(m.params.x, 0.0, 1.0);
    float roughness = clamp(m.params.y, 0.05, 1.0);
    float cc = clamp(m.texParams.z, 0.0, 1.0);
    float ccr = clamp(m.texParams.w, 0.03, 1.0);
    bool hasSheen = (flags & 8) != 0;
    vec3 sheenColor = m.sheen.rgb;
    float sheenRoughness = clamp(m.sheen.w, 0.07, 1.0);
    // Base specular reflectance, shared by the direct and environment terms so
    // thin-film interference tints both consistently.
    float ndotv = max(dot(N, V), 0.0);
    vec3 F0 = mix(vec3(0.04), albedo, metallic);
    if ((flags & 16) != 0 && m.iridescence.x > 0.0) {
        F0 = mix(
            F0,
            thin_film_f0(F0, ndotv, m.iridescence.y, m.iridescence.z),
            clamp(m.iridescence.x, 0.0, 1.0)
        );
    }

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
            if (shadows && l.shadowInfo.z > 0.0) {
                sh = sample_shadow_atlas(uShadow0, l.shadowVP, l.shadowInfo, vWorldPos, N, L);
            }
#ifdef TYCHO_RAY_SHADOW
            {
                rayQueryEXT rq;
                vec3 origin = vWorldPos + N * 0.02;
                rayQueryInitializeEXT(
                    rq,
                    uTlas,
                    gl_RayFlagsTerminateOnFirstHitEXT | gl_RayFlagsOpaqueEXT,
                    0xFF,
                    origin,
                    0.0,
                    L,
                    200.0
                );
                while (rayQueryProceedEXT(rq)) {}
                if (rayQueryGetIntersectionTypeEXT(rq, true) !=
                    gl_RayQueryCommittedIntersectionNoneEXT) {
                    sh = 0.0;
                }
            }
#endif
            lighting += direct_brdf(N, V, L, l.color.rgb * l.params.x, albedo, metallic, roughness, F0) * sh;
            lighting += clearcoat_spec(N, V, L, l.color.rgb * l.params.x, cc, ccr) * sh;
            if (hasSheen) {
                lighting += sheen_brdf(N, V, L, sheenColor, sheenRoughness) * l.color.rgb * l.params.x * sh;
            }
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
                // params = (intensity, inner angle, outer angle)
                atten *= smoothstep(l.params.y, l.params.z, cd);
            }
            float sh = 1.0;
            if (shadows) {
                if (typeCode == 1 && l.shadowRef.w > 0.5) {
                    int base = int(l.shadowRef.x + 0.5);
                    vec3 d = vWorldPos - l.posDir.xyz;
                    vec3 ad = abs(d);
                    int face;
                    if (ad.x >= ad.y && ad.x >= ad.z) {
                        face = d.x > 0.0 ? 0 : 1;
                    } else if (ad.y >= ad.z) {
                        face = d.y > 0.0 ? 2 : 3;
                    } else {
                        face = d.z > 0.0 ? 4 : 5;
                    }
                    ShadowTileGpu st = shadowTiles[base + face];
                    sh = sample_shadow_atlas(uShadow0, st.vp, st.rect, vWorldPos, N, L);
                } else if (typeCode == 2 && l.shadowInfo.z > 0.0) {
                    sh = sample_shadow_atlas(uShadow0, l.shadowVP, l.shadowInfo, vWorldPos, N, L);
                }
            }
            lighting += direct_brdf(N, V, L, l.color.rgb * atten, albedo, metallic, roughness, F0) * sh;
            lighting += clearcoat_spec(N, V, L, l.color.rgb * atten, cc, ccr) * sh;
            if (hasSheen) {
                lighting += sheen_brdf(N, V, L, sheenColor, sheenRoughness) * l.color.rgb * atten * sh;
            }
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
    // Split sum: the LUT wraps the GGX/visibility integral, so the specular
    // term scales with F0 instead of a roughness-faded Fresnel guess.
    vec2 ab = texture(uBrdf, vec2(clamp(dot(N, V), 0.0, 1.0), roughness)).rg;
    vec3 F_env = clamp(F0 * ab.x + vec3(ab.y), 0.0, 1.0);
    vec3 kD = (vec3(1.0) - F_env) * (1.0 - metallic);
    vec3 ambient = kD * envDiff * albedo + F_env * envSpec + ambientSum * albedo;
    if (hasSheen) {
        // Sheen IBL approximation: the diffuse irradiance already holds the
        // hemisphere average a fabric lobe would gather at grazing angles.
        ambient += sheenColor * envDiff * 0.5;
    }
    if (cc > 0.001) {
        // Coat-reflection: a second, sharper environment lookup.
        vec3 ccSpec = textureLod(uEnv, R, ccr * maxLod).rgb;
        float ndv = clamp(dot(N, V), 0.0, 1.0);
        float ccF = 0.04 + 0.96 * pow(1.0 - ndv, 5.0);
        ambient += ccSpec * (cc * ccF) * envI;
    }

    vec3 lit = ambient + lighting + emissive;
#ifdef TYCHO_TRANSMISSION
    float transmission = clamp(m.transmission.x, 0.0, 1.0);
    if (transmission > 0.001) {
        float ior = clamp(m.transmission.y, 1.0, 2.5);
        vec2 vp = vec2(textureSize(uSceneColor, 0));
        vec2 uv = gl_FragCoord.xy / max(vp, vec2(1.0));
        vec3 rd = refract(-V, N, 1.0 / ior);
        // Total internal reflection leaves no refracted direction: look straight
        // through instead of sampling noise.
        if (dot(rd, rd) < 1e-6) {
            rd = -V;
        }
        vec2 offs = (rd.xy - (-V).xy) * 0.4 * transmission;
        vec3 behind = texture(uSceneColor, clamp(uv + offs, vec2(0.001), vec2(0.999))).rgb;
        vec3 reflected = textureLod(uEnv, reflect(-V, N), roughness * maxLod).rgb * envI;
        float fres = 0.04 + 0.96 * pow(1.0 - clamp(dot(N, V), 0.0, 1.0), 5.0);
        lit = mix(lit, mix(behind, reflected, fres), transmission);
    }
#endif
    outHDR = vec4(apply_fog(lit, vWorldPos), base.a);
}
