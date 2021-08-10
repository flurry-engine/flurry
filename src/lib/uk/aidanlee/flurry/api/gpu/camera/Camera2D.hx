package uk.aidanlee.flurry.api.gpu.camera;

import VectorMath;

class Camera2D
{
    public final pos : Vec2;

    public final origin : Vec2;

    public final scale : Vec2;
    public final size : Vec2;

    public final viewport : Vec4;

    public var angle : Float;

    public function new(_pos, _size, _viewport)
    {
        pos      = _pos;
        origin   = vec2(0);
        scale    = vec2(1);
        size     = _size;
        viewport = _viewport;
        angle    = 0;
    }

    public inline function worldToScreen(_vec : Vec2)
    {
        return vec2(0);
    }

    public inline function screenToWorld(_vec : Vec2)
    {
        return vec2(0);
    }
}