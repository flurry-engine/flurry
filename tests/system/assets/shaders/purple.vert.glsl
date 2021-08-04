#version 460 core

layout(location = 0) in vec3 aPos;
layout(location = 1) in vec4 aCol;
layout(location = 2) in vec2 aTex;

layout(std140, binding = 0) uniform flurry_matrices
{
    mat4 viewproj;
};

void main()
{
    gl_Position = viewproj * vec4(aPos, 1.0);
}
