package uk.aidanlee.flurry.modules.differ.shapes;

import uk.aidanlee.flurry.api.maths.Matrix.make2D;
import uk.aidanlee.flurry.api.gpu.GraphicsContext;
import uk.aidanlee.flurry.api.gpu.drawing.Shapes;
import VectorMath;

class Polygon
{
    public final pos : Vec2;

    public final origin : Vec2;

    public final scale : Vec2;

    public var angle : Float;

    public final vertices : Array<Vec2>;

    public function new(_pos, _origin, _scale, _angle, _vertices)
    {
        pos       = _pos;
        origin    = _origin;
        scale     = _scale;
        angle     = _angle;
        origin    = _origin;
        vertices  = _vertices;
    }

    public inline function draw(_ctx : GraphicsContext, _colour : Vec4)
    {
        final matrix = make2D(pos, origin, scale, radians(angle));

        var previous : Null<Vec2> = null;
        for (i in 0...vertices.length)
        {
            final transformed = vec2(matrix * vec4(vertices[i], 0, 1));

            if (previous != null)
            {
                drawLine(_ctx, previous, transformed, 2, _colour);
            }

            previous = transformed;
        }

        if (previous != null)
        {
            drawLine(_ctx, previous, vec2(matrix * vec4(vertices[0], 0, 1)), 2, _colour);
        }
    }

    public static function ngon(_pos : Vec2, _sides : Int, _radius : Float)
    {
        final rotation = (Math.PI * 2) / _sides;
        final verts    = [];
        var angle = 0.0;

        for (i in 0..._sides)
        {
            angle = (i * rotation) + ((Math.PI - rotation) * 0.5);

            verts.push(vec2(Math.cos(angle) * _radius, Math.sin(angle) * _radius));
        }

        return new Polygon(_pos, vec2(0), vec2(1), 0, verts);
    }

    public static function rectangle(_pos : Vec2, _size : Vec2, _centred = false)
    {
        return
            new Polygon(
                _pos,
                if (_centred) _size * 0.5 else vec2(0),
                vec2(1),
                0,
                [
                    vec2(0, 0),
                    vec2(_size.x, 0),
                    _size,
                    vec2(0, _size.y)
                ]);
    }

    public static function square(_pos : Vec2, _size : Float, _centred = false)
    {
        rectangle(_pos, vec2(_size), _centred);
    }
}