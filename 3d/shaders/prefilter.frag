#version 450
// GGX importance-sampled environment prefilter. One draw per cubemap face,
// rendered into a 6*s x s strip; the CPU copies each strip back into the final
// cubemap mip.
layout(binding = 0) uniform samplerCube uSrc;

layout(push_constant) uniform PC {
    vec4 params; // x face, y roughness, z sample count, w face size
} pc;

layout(location = 0) out vec4 outColor;

const float PI = 3.14159265359;

vec3 cube_dir(int face, float u, float v) {
    vec3 d;
    if (face == 0) {
        d = vec3(1.0, -v, -u);
    } else if (face == 1) {
        d = vec3(-1.0, -v, u);
    } else if (face == 2) {
        d = vec3(u, 1.0, v);
    } else if (face == 3) {
        d = vec3(u, -1.0, -v);
    } else if (face == 4) {
        d = vec3(u, -v, 1.0);
    } else {
        d = vec3(-u, -v, -1.0);
    }
    return normalize(d);
}

vec2 hammersley(int i, int n) {
    float x = float(i) / float(n);
    float y = float(bitfieldReverse(uint(i))) * 2.3283064365386963e-10;
    return vec2(x, y);
}

vec3 prefilter_env(vec3 n, float roughness, int samples) {
    float a = roughness * roughness;
    float a2 = a * a;
    vec3 up = abs(n.z) < 0.999 ? vec3(0.0, 0.0, 1.0) : vec3(1.0, 0.0, 0.0);
    vec3 t = normalize(cross(up, n));
    vec3 b = cross(n, t);
    vec3 sum = vec3(0.0);
    float weight = 0.0;
    for (int i = 0; i < samples; ++i) {
        vec2 xi = hammersley(i, samples);
        float phi = 2.0 * PI * xi.x;
        float cos_theta = sqrt((1.0 - xi.y) / (1.0 + (a2 - 1.0) * xi.y));
        float sin_theta = sqrt(max(0.0, 1.0 - cos_theta * cos_theta));
        vec3 l = t * (cos(phi) * sin_theta) + b * (sin(phi) * sin_theta) + n * cos_theta;
        float ndotl = dot(n, l);
        if (ndotl > 0.0) {
            sum += textureLod(uSrc, l, 0.0).rgb * ndotl;
            weight += ndotl;
        }
    }
    return weight > 0.0 ? sum / weight : textureLod(uSrc, n, 0.0).rgb;
}

void main() {
    int face = int(pc.params.x + 0.5);
    float roughness = pc.params.y;
    int samples = int(pc.params.z + 0.5);
    float size = pc.params.w;
    vec2 st = (gl_FragCoord.xy - vec2(float(face) * size, 0.0)) / size;
    float u = st.x * 2.0 - 1.0;
    float v = st.y * 2.0 - 1.0;
    vec3 n = cube_dir(face, u, v);
    vec3 c = roughness <= 0.0 ? textureLod(uSrc, n, 0.0).rgb : prefilter_env(n, roughness, samples);
    outColor = vec4(c, 1.0);
}
