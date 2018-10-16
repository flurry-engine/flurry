package uk.aidanlee.flurry.api.gpu.geometry.shapes;

import snow.api.Debug.def;
import uk.aidanlee.flurry.api.maths.Rectangle;
import uk.aidanlee.flurry.api.maths.Vector;
import uk.aidanlee.flurry.api.gpu.geometry.Geometry;
import uk.aidanlee.flurry.api.gpu.geometry.Vertex;

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
        _options.r         = def(_options.r, new Rectangle(def(_options.x, 0), def(_options.y, 0), def(_options.w, 1), def(_options.h, 1)));

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
     * @param _w Width.
     * @param _h Height.
     */
    public function set_xywh(_x : Float, _y : Float, _w : Float, _h : Float)
    {
        vertices[1].position.set_xy(_w,  0);
        vertices[2].position.set_xy(_w, _h);
        vertices[3].position.set_xy( 0, _h);

        transformation.position.set_xy(_x, _y);
    }
}
