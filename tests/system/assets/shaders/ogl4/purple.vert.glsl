#version 460 core

layout(location = 0) in vec3 aPos;
layout(location = 1) in vec4 aCol;
layout(location = 2) in vec2 aTex;

layout(std430, binding = 0) buffer defaultMatrices
{
    mat4 projection;
    mat4 view;
    mat4 models[];
};

layout(std430, binding = 1) buffer colours
{
    float red;
    float green;
    float blue;
};

void main()
{
    gl_Position = projection * view * models[gl_DrawID] * vec4(aPos, 1.0);
}
