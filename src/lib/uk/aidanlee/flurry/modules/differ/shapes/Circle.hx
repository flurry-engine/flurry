package uk.aidanlee.flurry.modules.differ.shapes;

class Circle
{
    public var pos : Vec2;

    public var scale : Float;
    
    public var radius : Float;

    public inline function new(_pos, _scale, _radius)
    {
        pos    = _pos;
        scale  = _scale;
        radius = _radius;
    }
}