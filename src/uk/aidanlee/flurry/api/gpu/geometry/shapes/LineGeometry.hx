package uk.aidanlee.flurry.api.gpu.geometry.shapes;

import uk.aidanlee.flurry.api.gpu.geometry.Geometry;
import uk.aidanlee.flurry.api.maths.Vector2;
import uk.aidanlee.flurry.api.maths.Vector3;

using Safety;

typedef LineGeometryOptions = {
    
    >GeometryOptions,

    /**
     * The position of the first point.
     */
    @:optional var point0 : Vector3;

    /**
     * The position of the second point.
     */
    @:optional var point1 : Vector3;

    /**
     * The position of the second point.
     */
    @:optional var color0 : Color;

    /**
     * The colour of the second point.
     */
    @:optional var color1 : Color;
}

/**
 * Line geometry draws a line between two points.
 * The two points have both a position and colour.
 */
class LineGeometry extends Geometry
{
    /**
     * The position of the first point.
     */
    public final point0 : Vector3;

    /**
     * The position of the second point.
     */
    public final point1 : Vector3;

    /**
     * The colour of the first point.
     */
    public final color0 : Color;

    /**
     * The colour of the second point.
     */
    public final color1 : Color;

    /**
     * Create a new line geometry.
     * @param _options Line options.
     */
    public function new(_options : LineGeometryOptions)
    {
        _options.primitive = Lines;

        super(_options);

        point0 = _options.point0.or(new Vector3(0, 0, 0));
        point1 = _options.point1.or(new Vector3(1, 1, 1));
        color0 = _options.color0.or(color);
        color1 = _options.color1.or(color);

        vertices.push(new Vertex( point0, color0, new Vector2() ));
        vertices.push(new Vertex( point1, color1, new Vector2() ));
    }
}
