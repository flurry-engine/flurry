#version 460 core

layout(binding = 0) uniform texture2D defaultTexture;
layout(binding = 0) uniform sampler defaultSampler;

layout(location = 0) in vec4 Color;
layout(location = 1) in vec2 TexCoord;

layout(location = 0) out vec4 FragColor;

void main()
{
    vec4 col = texture(sampler2D(defaultTexture, defaultSampler), TexCoord);

    FragColor = vec4(1 * col.a, 0 * col.a, 0.75 * col.a, col.a);
}
