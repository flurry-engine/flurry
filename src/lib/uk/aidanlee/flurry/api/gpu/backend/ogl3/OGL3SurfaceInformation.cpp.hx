package uk.aidanlee.flurry.api.gpu.backend.ogl3;

import uk.aidanlee.flurry.api.gpu.surfaces.SurfaceState;

class OGL3SurfaceInformation
{
    public final state : SurfaceState;

    public final texture : Int;

    public final renderBuffer : Int;

    public final frameBuffer : Int;

    public function new(_state, _texture, _renderBuffer, _frameBuffer)
    {
        state        = _state;
        texture      = _texture;
        renderBuffer = _renderBuffer;
        frameBuffer  = _frameBuffer;
    }
}