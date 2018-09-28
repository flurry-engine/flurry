#version 130

attribute vec3 aPos;
attribute vec4 aCol;
attribute vec2 aTex;

uniform mat4 projection;
uniform mat4 view;

varying vec4 Color;
varying vec2 TexCoord;

void main()
{
    gl_Position = projection * view * vec4(aPos, 1.0);
    Color       = aCol;
    TexCoord    = aTex;
}
