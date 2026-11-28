#version 450
// Screen-space ambient occlusion from the scene depth buffer.
//
// Reversed-Z is assumed: the depth clear is 0 (far) and nearer fragments hold
// larger values, so a 0 sample means "sky" and is skipped. World positions are
// reconstructed with the inverse view-projection, normals come from the world
// position derivatives (no G-buffer), and a 12-sample rotated hemisphere kernel
// tests whether nearby geometry is closer to the eye than the sample point.
layout(binding = 0) uniform SSAOUBO {
    mat4 viewProj;
    mat4 invViewProj;
    vec4 camPos;
    vec4 params; // x radius, y intensity, z bias, w unused
} ubo;
layout(binding = 1) uniform sampler2D uDepth;

layout(location = 0) in vec2 vUV;
layout(location = 0) out vec4 outAO;

vec3 reconstruct(vec2 uv, float d) {
    vec2 ndc = uv * 2.0 - 1.0;
    vec4 p = ubo.invViewProj * vec4(ndc, d, 1.0);
    return p.xyz / p.w;
}

float hash12(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

void main() {
    float d = texture(uDepth, vUV).r;
    if (d <= 0.0) {
        outAO = vec4(1.0);
        return;
    }
    vec3 world = reconstruct(vUV, d);
    vec3 n = normalize(cross(dFdx(world), dFdy(world)));
    vec3 toEye = ubo.camPos.xyz - world;
    if (dot(n, toEye) < 0.0) {
        n = -n;
    }

    float radius = ubo.params.x;
    float bias = ubo.params.z;
    float baseDist = length(toEye);

    // Orthonormal basis around the normal.
    vec3 up = abs(n.z) < 0.999 ? vec3(0.0, 0.0, 1.0) : vec3(1.0, 0.0, 0.0);
    vec3 t = normalize(cross(up, n));
    vec3 b = cross(n, t);
    mat3 tbn = mat3(t, b, n);

    float rot = hash12(gl_FragCoord.xy) * 6.2831853;
    float cs = cos(rot);
    float sn = sin(rot);
    mat2 rotm = mat2(cs, -sn, sn, cs);

    const int SAMPLES = 12;
    float occ = 0.0;
    for (int i = 0; i < SAMPLES; i++) {
        float fi = float(i) + 0.5;
        // Golden-angle spiral filling a hemisphere, denser near the centre.
        float a = fi * 2.39996323;
        float r = sqrt(fi / float(SAMPLES));
        vec3 k = vec3(cos(a) * r, sin(a) * r, sqrt(max(1.0 - r * r, 0.0)));
        k.xy = rotm * k.xy;
        vec3 sp = world + tbn * k * radius;

        vec4 clip = ubo.viewProj * vec4(sp, 1.0);
        if (clip.w <= 0.0) {
            continue;
        }
        vec2 suv = clip.xy / clip.w * 0.5 + 0.5;
        if (suv.x < 0.0 || suv.x > 1.0 || suv.y < 0.0 || suv.y > 1.0) {
            continue;
        }
        float sd = texture(uDepth, suv).r;
        if (sd <= 0.0) {
            continue;
        }
        vec3 sw = reconstruct(suv, sd);
        float sampleDist = length(ubo.camPos.xyz - sw);
        float pointDist = length(ubo.camPos.xyz - sp);
        // Occluded when the recorded surface is closer to the eye than the
        // sample point, and both stay within the sampling radius.
        if (pointDist - sampleDist > bias && abs(sampleDist - baseDist) < radius * 2.0) {
            occ += 1.0;
        }
    }
    float ao = 1.0 - (occ / float(SAMPLES)) * ubo.params.y;
    outAO = vec4(vec3(clamp(ao, 0.0, 1.0)), 1.0);
}
