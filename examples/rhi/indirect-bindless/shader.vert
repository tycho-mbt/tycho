#version 450
layout(location = 0) in vec2 inPos;
layout(location = 1) in vec2 inTexIdx; // x = bindless texture index
layout(location = 0) flat out int vTexIdx;
void main() {
    gl_Position = vec4(inPos, 0.0, 1.0);
    vTexIdx = int(inTexIdx.x + 0.5);
}
