#version 460 core

out vec4 FragColor;

in vec4 Color;
in vec2 TexCoord;

layout(binding = 0) uniform sampler2D defaultTexture;

void main()
{
    FragColor = texture(defaultTexture, TexCoord) * Color;
}
