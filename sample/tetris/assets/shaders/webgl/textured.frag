#version 130

varying vec4 Color;
varying vec2 TexCoord;

uniform sampler2D defaultTexture;

void main()
{
    gl_FragColor = texture(defaultTexture, TexCoord) * Color;
}
