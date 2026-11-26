#version 450
// Split-sum BRDF integration LUT.
//
// x axis = NdotV, y axis = roughness. Each texel stores (A, B) so the PBR
// shader evaluates the environment specular term as
// `prefiltered * (F0 * A + B)` instead of an analytic approximation.
layout(location = 0) in vec2 vUV;
layout(location = 0) out vec2 outAB;

layout(push_constant) uniform PC {
    vec4 params; // x sample count
} pc;

const float PI = 3.14159265359;

vec2 hammersley(int i, int n) {
    float x = float(i) / float(n);
    float y = float(bitfieldReverse(uint(i))) * 2.3283064365386963e-10;
    return vec2(x, y);
}

vec3 importance_sample_ggx(vec2 xi, vec3 n, float roughness) {
    float a = roughness * roughness;
    float phi = 2.0 * PI * xi.x;
    float cos_theta = sqrt((1.0 - xi.y) / (1.0 + (a * a - 1.0) * xi.y));
    float sin_theta = sqrt(max(0.0, 1.0 - cos_theta * cos_theta));
    vec3 h = vec3(cos(phi) * sin_theta, sin(phi) * sin_theta, cos_theta);
    vec3 up = abs(n.z) < 0.999 ? vec3(0.0, 0.0, 1.0) : vec3(1.0, 0.0, 0.0);
    vec3 t = normalize(cross(up, n));
    vec3 b = cross(n, t);
    return normalize(t * h.x + b * h.y + n * h.z);
}

float g_schlick_ibl(float ndot, float roughness) {
    float a = roughness * roughness;
    float k = a * 0.5;
    return ndot / max(ndot * (1.0 - k) + k, 0.0001);
}

void main() {
    int samples = int(pc.params.x + 0.5);
    float ndotv = clamp(vUV.x, 0.001, 1.0);
    float roughness = clamp(vUV.y, 0.001, 1.0);
    vec3 N = vec3(0.0, 0.0, 1.0);
    vec3 V = vec3(sqrt(max(1.0 - ndotv * ndotv, 0.0)), 0.0, ndotv);
    float a = 0.0;
    float b = 0.0;
    for (int i = 0; i < samples; ++i) {
        vec3 H = importance_sample_ggx(hammersley(i, samples), N, roughness);
        vec3 L = normalize(2.0 * dot(V, H) * H - V);
        if (L.z > 0.0) {
            float ndotl = max(L.z, 0.0);
            float ndoth = max(H.z, 0.0);
            float vdoth = max(dot(V, H), 0.0);
            float g = g_schlick_ibl(ndotv, roughness) * g_schlick_ibl(ndotl, roughness);
            float g_vis = (g * vdoth) / max(ndoth * ndotv, 0.0001);
            float fc = pow(1.0 - vdoth, 5.0);
            a += (1.0 - fc) * g_vis;
            b += fc * g_vis;
        }
    }
    outAB = vec2(a, b) / float(samples);
}
