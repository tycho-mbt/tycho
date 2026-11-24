#version 450
vec2 pos[6] = vec2[](
    vec2(-1.0, -1.0), vec2(1.0, -1.0), vec2(1.0, 1.0),
    vec2(-1.0, -1.0), vec2(1.0, 1.0), vec2(-1.0, 1.0)
);
vec2 uvs[6] = vec2[](
    vec2(0.0, 0.0), vec2(1.0, 0.0), vec2(1.0, 1.0),
    vec2(0.0, 0.0), vec2(1.0, 1.0), vec2(0.0, 1.0)
);
layout(location = 0) out vec2 vUV;
void main() {
    gl_Position = vec4(pos[gl_VertexIndex], 0.0, 1.0);
    vUV = uvs[gl_VertexIndex];
}
