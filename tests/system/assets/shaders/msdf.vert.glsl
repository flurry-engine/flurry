#version 460 core

layout(std140, binding = 0) uniform flurry_matrices
{
    mat4 projection;
    mat4 view;
    mat4 model;
};

layout(location = 0) in vec3 aPos;
layout(location = 1) in vec4 aCol;
layout(location = 2) in vec2 aTex;

layout(location = 0) out vec4 Color;
layout(location = 1) out vec2 TexCoord;

void main()
{
    gl_Position = projection * view * model * vec4(aPos, 1.0);
    Color       = aCol;
    TexCoord    = aTex;
}
