package uk.aidanlee.flurry.api.gpu.backend.ogl3;

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
}