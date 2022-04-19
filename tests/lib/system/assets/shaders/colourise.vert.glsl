#version 460 core

layout(location = 0) in vec3 aPos;
layout(location = 1) in vec4 aCol;
layout(location = 2) in vec2 aTex;

layout(std140, binding = 0) uniform flurry_matrices
{
    mat4 viewproj;
};

layout(std140, binding = 1) uniform colours
{
    vec3 colour;
};

layout(location = 0) out vec4 Color;
layout(location = 1) out vec2 TexCoord;

void main()
{
    gl_Position = viewproj * vec4(aPos, 1.0);
    Color       = vec4(aCol.r * colour.r, aCol.g * colour.g, aCol.b * colour.b, aCol.a);
    TexCoord    = aTex;
}
