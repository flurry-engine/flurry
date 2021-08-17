#version 460 core

layout(location = 0) in vec4 Color;

layout(location = 0) out vec4 FragColor;

void main()
{
    FragColor = Color;
}
