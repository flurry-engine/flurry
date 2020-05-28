#version 330 core

in vec4 Color;
in vec2 TexCoord;

out vec4 FragColor;

uniform sampler2D defaultTexture;

float median(vec3 v)
{
    return max( min(v.x, v.y), min( max(v.x, v.y), v.z ) );
}

void main()
{
    vec2  msdfUnit = 2.0 / vec2(textureSize(defaultTexture, 0));
    vec3  sampled  = texture(defaultTexture, TexCoord).rgb;
    float sigDist  = median(sampled) - 0.5;
    sigDist *= dot(msdfUnit, 0.5 / fwidth(TexCoord));

    FragColor = vec4(Color.r, Color.g, Color.b, clamp(sigDist + 0.5, 0.0, 1.0));
}
