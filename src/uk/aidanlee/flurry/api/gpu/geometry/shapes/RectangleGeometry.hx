package uk.aidanlee.flurry.api.gpu.geometry.shapes;

import uk.aidanlee.flurry.api.maths.Rectangle;
import uk.aidanlee.flurry.api.maths.Vector;
import uk.aidanlee.flurry.api.gpu.geometry.Geometry;
import uk.aidanlee.flurry.api.gpu.geometry.Vertex;

using Safety;

typedef RectangleGeometryOptions = {
    >GeometryOptions,

    var ?x : Float;
    var ?y : Float;
    var ?w : Float;
    var ?h : Float;
    var ?r : Rectangle;
}

class RectangleGeometry extends Geometry
{
    public function new(_options : RectangleGeometryOptions)
    {
        _options.primitive = LineStrip;
        _options.r         = _options.r.or(new Rectangle(_options.x.or(0), _options.y.or(0), _options.w.or(1), _options.h.or(1)));

        super(_options);

        var emptyCoords = new Vector();
        addVertex(new Vertex( new Vector(           0,            0), color, emptyCoords ));
        addVertex(new Vertex( new Vector(_options.r.w,            0), color, emptyCoords ));
        addVertex(new Vertex( new Vector(_options.r.w, _options.r.h), color, emptyCoords ));
        addVertex(new Vertex( new Vector(           0, _options.r.h), color, emptyCoords ));
        addVertex(vertices[0]);

        transformation.position.set_xy(_options.r.x, _options.r.y);
    }

    /**
     * Resize the rectangle to the width and height of a vector.
     * @param _size Vector containing the size.
     */
    public function resize(_size : Vector)
    {
        vertices[1].position.set_xy(_size.x,       0);
        vertices[2].position.set_xy(_size.x, _size.y);
        vertices[3].position.set_xy(      0, _size.y);
    }

    /**
     * Resize the rectangle to the width and height of two floats.
     * @param _x Width of the rectangle.
     * @param _y Height of the rectangle.
     */
    public function resize_xy(_x : Float, _y : Float)
    {
        vertices[1].position.set_xy(_x,  0);
        vertices[2].position.set_xy(_x, _y);
        vertices[3].position.set_xy( 0, _y);
    }

    /**
     * Set the position and size of the geometry from a rectangle.
     * @param _rect Rectangle containing position and size.
     */
    public function set(_rect : Rectangle)
    {
        vertices[1].position.set_xy(_rect.w,       0);
        vertices[2].position.set_xy(_rect.w, _rect.h);
        vertices[3].position.set_xy(      0, _rect.h);

        transformation.position.set_xy(_rect.x, _rect.y);
    }

    /**
     * Set the position and size of the geometry from four floats.
     * @param _x x position.
     * @param _y y position.
     * @param _width Width.
     * @param _height Height.
     */
    public function set_xywh(_x : Float, _y : Float, _width : Float, _height : Float)
    {
        vertices[1].position.set_xy( _width,  0);
        vertices[2].position.set_xy( _width, _height);
        vertices[3].position.set_xy(      0, _height);

        transformation.position.set_xy(_x, _y);
    }
}
