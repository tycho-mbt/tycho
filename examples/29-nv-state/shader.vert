#version 450
layout(location = 0) out vec3 vColor;
void main() {
    vec2 p = vec2((gl_VertexIndex << 1) & 2, gl_VertexIndex & 2);
    vColor = vec3(1.0, 0.0, 0.0);
    gl_Position = vec4(p * 2.0 - 1.0, 0.0, 1.0);
}
