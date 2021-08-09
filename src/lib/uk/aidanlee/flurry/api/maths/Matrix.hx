package uk.aidanlee.flurry.api.maths;

import VectorMath;

overload extern inline function identity()
{
    return mat4(1);
}

overload extern inline function make2D(_pos : Vec2)
{
    return makeTranslation(_pos);
}

overload extern inline function make2D(_pos : Vec2, _origin : Vec2)
{
    return makeTranslation(_pos - _origin);
}

overload extern inline function make2D(_pos : Vec2, _angle : Float)
{
    final translation = makeTranslation(_pos);
    final rotation    = makeRotationZ(_angle);

    return translation * rotation;
}

overload extern inline function make2D(_pos : Vec2, _origin : Vec2, _angle : Float)
{
    final translation = makeTranslation(_pos - _origin);
    final origin      = makeTranslation(_origin);
    final rotation    = makeRotationZ(_angle);
    final originUndo  = makeTranslation(-_origin);

    return translation * origin * rotation * originUndo;
}

overload extern inline function make2D(_pos : Vec2, _origin : Vec2, _scale : Vec2)
{
    final translation = makeTranslation(_pos - _origin);
    final origin      = makeTranslation(_origin);
    final scale       = makeScale(_scale);
    final originUndo  = makeTranslation(-_origin);
    
    return translation * origin * scale * originUndo;
}

overload extern inline function make2D(_pos : Vec2, _origin : Vec2, _scale : Vec2, _angle : Float)
{
    final translation = makeTranslation(_pos - _origin);
    final origin      = makeTranslation(_origin);
    final rotation    = makeRotationZ(_angle);
    final scale       = makeScale(_scale);
    final originUndo  = makeTranslation(-_origin);
    
    return translation * origin * rotation * scale * originUndo;
}

overload extern inline function makeScale(_v : Vec2)
{
    return makeScale(vec3(_v, 1));
}

overload extern inline function makeScale(_v : Vec3)
{
    return mat3(
        _v.x,     0,    0,
            0, _v.y,    0,
            0,    0, _v.z
    );
}

overload extern inline function makeTranslation(_v : Vec2)
{
    return makeTranslation(vec3(_v, 1));
}

overload extern inline function makeTranslation(_v : Vec3)
{
    return mat3(
          1,    0,    0,
          0,    1,    0,
       _v.x, _v.y, _v.z
   );
}

inline function makeRotationZ(_angle : Float)
{
    final c = Maths.cos(_angle);
    final s = Maths.sin(_angle);

    return mat3(
        c, -s,  0,
        s,  c,  0,
        0,  0,  1
    );
}

/**
 * Produces a column major, right handed orthographic projection matrix compatible with D3D.
 * https://blog.demofox.org/2017/03/31/orthogonal-projection-matrix-plainly-explained/
 */
overload extern inline function makeFrustum(_left : Float, _right : Float, _top : Float, _bottom : Float, _near : Float, _far : Float)
{
    final a   =  2 / (_right - _left);
    final b   =  2 / (_top - _bottom);
    final c   = - 2 / (_far - _near);
    final x   = - (_right + _left) / (_right - _left);
    final y   = - (_top + _bottom) / (_top - _bottom);
    final z   = - (_far + _near) / (_far - _near);

    return mat4(
        a, 0, 0, 0,
        0, b, 0, 0,
        0, 0, c, 0,
        x, y, z, 1
    );
}

overload extern inline function makeFrustumOpenGL(_left : Float, _right : Float, _top : Float, _bottom : Float, _near : Float, _far : Float)
{
    final a = (2 * _near) / (_right - _left);
    final b = (2 * _near) / (_top - _bottom);
    final c = (_right + _left) / (_right - _left);
    final d = (_top + _bottom) / (_top - _bottom);
    final e = - (_far + _near) / (_far - _near);
    final f = -1;
    final g = - (2 * _far * _near) / (_far - _near);

    return mat4(1);
}