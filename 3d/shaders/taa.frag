#version 450
// Temporal anti-aliasing (camera-only reprojection).
//
// Each frame is rasterised with a sub-pixel projection jitter. This pass
// reconstructs the world position of the current pixel with the jittered
// inverse view-projection, projects it with the *previous* unjittered
// view-projection to find the history texel, clamps that history sample to the
// 3x3 neighbourhood of the current frame (so disocclusions and moving objects
// cannot smear), and blends.
//
// There are no per-object motion vectors yet, so moving geometry can ghost;
// call `Renderer3D::reset_taa` after a camera cut to drop the history.
layout(binding = 0) uniform TAAUBO {
    mat4 invViewProj;
    mat4 prevViewProj;
    vec4 params; // x history weight, y history valid
} ubo;
layout(binding = 1) uniform sampler2D uCurrent;
layout(binding = 2) uniform sampler2D uHistory;
layout(binding = 3) uniform sampler2D uDepth;

layout(location = 0) in vec2 vUV;
layout(location = 0) out vec4 outColor;

void main() {
    vec3 current = texture(uCurrent, vUV).rgb;
    if (ubo.params.y < 0.5) {
        outColor = vec4(current, 1.0);
        return;
    }
    float d = texture(uDepth, vUV).r;
    if (d <= 0.0) {
        // Sky: no depth to reproject, keep the current colour.
        outColor = vec4(current, 1.0);
        return;
    }
    vec2 ndc = vUV * 2.0 - 1.0;
    vec4 world = ubo.invViewProj * vec4(ndc, d, 1.0);
    world /= world.w;
    vec4 prev = ubo.prevViewProj * world;
    if (prev.w <= 0.0) {
        outColor = vec4(current, 1.0);
        return;
    }
    vec2 prevUV = prev.xy / prev.w * 0.5 + 0.5;
    if (prevUV.x < 0.0 || prevUV.x > 1.0 || prevUV.y < 0.0 || prevUV.y > 1.0) {
        outColor = vec4(current, 1.0);
        return;
    }

    // 3x3 neighbourhood of the current frame, used as the history clamp.
    vec2 texel = 1.0 / vec2(textureSize(uCurrent, 0));
    vec3 mn = current;
    vec3 mx = current;
    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            vec3 c = texture(uCurrent, vUV + vec2(float(x), float(y)) * texel).rgb;
            mn = min(mn, c);
            mx = max(mx, c);
        }
    }
    vec3 history = clamp(texture(uHistory, prevUV).rgb, mn, mx);

    // A large residual means the reprojection is probably wrong (camera cut or
    // a fast object): lean on the current frame instead of smearing.
    float w = ubo.params.x;
    float residual = length(history - current);
    if (residual > 2.0) {
        w *= 0.25;
    }
    outColor = vec4(mix(current, history, w), 1.0);
}
