package uk.aidanlee.flurry.modules.differ.shapes;

import VectorMath;

enum abstract RayMode(Int)
{
    var NotInfinite;
    var InfiniteFromStart;
    var Infinite;
}

class Ray
{
    public final start : Vec2;

    public final end : Vec2;

    public final mode : RayMode;

    public inline function new(_start, _end, _mode)
    {
        start = _start;
        end   = _end;
        mode  = _mode;
    }

    public inline function angle()
    {
        return degrees(Math.atan2(end.y - start.y, end.x - start.x));
    }

    public inline function direction()
    {
        return vec2(end.x - start.x, end.y - start.y);
    }
}
