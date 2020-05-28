#version 460 core

layout(binding = 0) uniform sampler2D defaultTexture;

layout(location = 0) in vec4 Color;
layout(location = 1) in vec2 TexCoord;

layout(location = 0) out vec4 FragColor;

float median(vec3 v)
{
    return max( min(v.x, v.y), min( max(v.x, v.y), v.z ) );
}

void main()
{
    vec2  msdfUnit = 2.0 / vec2(textureSize(defaultTexture, 0));
    vec3  sample   = texture(defaultTexture, TexCoord).rgb;
    float sigDist  = median(sample) - 0.5;
    sigDist *= dot(msdfUnit, 0.5 / fwidth(TexCoord));

    FragColor = vec4(Color.r, Color.g, Color.b, clamp(sigDist + 0.5, 0.0, 1.0));
}
