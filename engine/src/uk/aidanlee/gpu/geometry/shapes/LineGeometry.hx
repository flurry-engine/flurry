package uk.aidanlee.gpu.geometry.shapes;

import snow.api.Debug.def;
import uk.aidanlee.gpu.geometry.Geometry;
import uk.aidanlee.maths.Vector;

typedef LineGeometryOptions = {
    
    >GeometryOptions,

    /**
     * The position of the first point.
     */
    @:optional var point0 : Vector;

    /**
     * The position of the second point.
     */
    @:optional var point1 : Vector;

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
    public final point0 : Vector;

    /**
     * The position of the second point.
     */
    public final point1 : Vector;

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

        point0 = def(_options.point0, new Vector(0, 0, 0));
        point1 = def(_options.point1, new Vector(1, 1, 1));
        color0 = def(_options.color0, color);
        color1 = def(_options.color1, color);

        addVertex(new Vertex( point0, color0, new Vector() ));
        addVertex(new Vertex( point1, color1, new Vector() ));
    }
}
