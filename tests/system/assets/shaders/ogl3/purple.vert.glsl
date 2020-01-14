#version 330 core

layout (location = 0) in vec3 aPos;
layout (location = 1) in vec4 aCol;
layout (location = 2) in vec2 aTex;

layout (std140) uniform flurry_matrices
{
    mat4 projection;
    mat4 view;
    mat4 model;
};

layout (std140) uniform colours
{
    float red;
    float green;
    float blue;
};

void main()
{
    gl_Position = projection * view * model * vec4(aPos, 1.0);
}
