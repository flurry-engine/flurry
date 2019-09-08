#version 460 core

layout(location = 0) out vec4 FragColor;

layout(location = 0) in vec4 Color;
layout(location = 1) in vec2 TexCoord;

layout(binding = 0) uniform sampler2D defaultTexture;

void main()
{
    FragColor = texture(defaultTexture, TexCoord) * Color;
}
