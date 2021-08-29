package uk.aidanlee.flurry.api.gpu.camera;

import VectorMath;
import uk.aidanlee.flurry.api.maths.Matrix;

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

    public inline function worldToScreen(_world : Vec2)
    {
        return vec2(vec4(_world, 0, 1) * inverse(make2D(pos, origin, scale, angle)));
    }

    public inline function screenToWorld(_screen : Vec2)
    {
        return vec2(vec4(_screen, 0, 1) * make2D(pos, origin, scale, angle));
    }
}