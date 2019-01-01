package uk.aidanlee.flurry.api.maths;

class MatrixTransform
{
    public var position : Vector;
    public var rotation : Quaternion;
    public var scale    : Vector;

    public inline function new(_pos : Vector, _rot : Quaternion, _scl : Vector)
    {
        position = _pos;
        rotation = _rot;
        scale    = _scl;
    }
}