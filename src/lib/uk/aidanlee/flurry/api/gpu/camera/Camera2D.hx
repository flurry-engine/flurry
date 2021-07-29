package uk.aidanlee.flurry.api.gpu.camera;

class Camera2D
{
    public final pos : Vec2;

    public final size : Vec2;

    public final viewport : Vec4;

    public function new(_pos, _size, _viewport)
    {
        pos      = _pos;
        size     = _size;
        viewport = _viewport;
    }
}