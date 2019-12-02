#version 330 core

layout (location = 0) in vec3 aPos;
layout (location = 1) in vec4 aCol;
layout (location = 2) in vec2 aTex;

layout (std140) uniform defaultMatrices
{
    mat4 projection;
    mat4 view;
    mat4 model;
};

layout (std140) uniform colours
{
    vec4 colour;
};

out vec4 Color;
out vec2 TexCoord;

void main()
{
    gl_Position = projection * view * model * vec4(aPos, 1.0);
    Color       = vec4(aCol.r * colour.r, aCol.g * colour.g, aCol.b * colour.b, aCol.a);
    TexCoord    = aTex;
}
