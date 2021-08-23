package uk.aidanlee.flurry.api.gpu.backend.ogl3;

import opengl.OpenGL.glDeleteTextures;
import opengl.OpenGL.glDeleteRenderbuffers;
import opengl.OpenGL.glDeleteFramebuffers;

class OGL3SurfaceInformation
{
    public final texture : Int;

    public final renderBuffer : Int;

    public final frameBuffer : Int;

    public final width : Int;

    public final height : Int;

    public function new(_texture, _renderBuffer, _frameBuffer, _width, _height)
    {
        texture      = _texture;
        renderBuffer = _renderBuffer;
        frameBuffer  = _frameBuffer;
        width        = _width;
        height       = _height;
    }

    public function dispose()
    {
        glDeleteTextures(1, texture);
        glDeleteRenderbuffers(1, renderBuffer);
        glDeleteFramebuffers(1, frameBuffer);
    }
}