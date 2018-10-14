package uk.aidanlee.flurry.api.gpu.geometry.shapes;

import snow.api.Debug.def;
import uk.aidanlee.flurry.api.gpu.geometry.Geometry;
import uk.aidanlee.flurry.api.gpu.geometry.shapes.CircleGeometry.CircleGeometryOptions;
import uk.aidanlee.flurry.api.maths.Maths;
import uk.aidanlee.flurry.api.maths.Vector;

/**
 * Draws the outline of a complete or partial ring.
 */
class RingGeometry extends Geometry
{
    /**
     * Create the initial ring geometry.
     * @param _options - 
     */
    public function new(_options : CircleGeometryOptions)
    {
        _options.primitive = Lines;

        super(_options);

        _options.endAngle   = def(_options.endAngle  , 360);
        _options.startAngle = def(_options.startAngle,   0);

        var radiusX = def(_options.r, 32);
        var radiusY = def(_options.r, 32);

        radiusX = def(_options.rx, radiusX);
        radiusY = def(_options.ry, radiusY);

        if (_options.steps == null)
        {
            if (_options.smooth == null)
            {
                var max = Maths.max(radiusX, radiusY);
                _options.steps = segmentsForSmoothCircle(max);
            }
            else
            {
                var max = Maths.max(radiusX, radiusY);
                _options.steps = segmentsForSmoothCircle(max, _options.smooth);
            }
        }

        set(_options.x, _options.y, radiusX, radiusY, _options.steps, _options.startAngle, _options.endAngle);
    }

    /**
     * Creates the ring geometry.
     * @param _x          The x centre position.
     * @param _y          The y centre position.
     * @param _rx         The x radius.
     * @param _ry         The y radius.
     * @param _steps      The number of steps when drawing the ring.
     * @param _startAngle Start angle in degrees.
     * @param _endAngle   End angle in degrees.
     */
    public function set(_x : Float, _y : Float, _rx : Float, _ry : Float, _steps : Int, _startAngle : Float, _endAngle : Float)
    {
        // Remove all verticies.
        while (vertices.length > 0)
        {
            vertices.pop();
        }

        // Clamp degrees angles
        if (Maths.abs(_startAngle) > 360) _startAngle %= 360;
        if (Maths.abs(_endAngle  ) > 360) _endAngle   %= 360;

        var startAngleRad = Maths.toRadians(_startAngle);
        var endAngleRad   = Maths.toRadians(_endAngle  );

        var range = endAngleRad - startAngleRad;
        var theta = range / _steps;

        var tangentFactor = Maths.tan(theta);
        var radialFactor  = Maths.cos(theta);

        var x = _rx * Maths.cos(startAngleRad);
        var y = _ry * Maths.sin(startAngleRad);

        //

        var radialRatio = _rx / _ry;
        if (radialRatio == 0) radialRatio = 0.000000001;

        var index           = 0;
        var segmentPosition = [];
        for (i in 0..._steps)
        {
            var segment = new Vector(x, y / radialRatio);
            segmentPosition.push(segment);

            addVertex(new Vertex( segment, color, new Vector() ));

            // If past 0 add one for the previous segment to close the triangle.
            if (index > 0)
            {
                var prevVert = segmentPosition[index];
                addVertex(new Vertex( prevVert.clone(), color, new Vector() ));
            }

            var tx = -y;
            var ty =  x;

            x += tx * tangentFactor;
            y += ty * tangentFactor;

            x *= radialFactor;
            y *= radialFactor;

            index++;
        }

        if (segmentPosition.length > 0)
        {
            addVertex(new Vertex( segmentPosition[0].clone(), color, new Vector() ));
        }

        transformation.position.set_xy(_x, _y);
    }

    /**
     * Returns the number of segments needed to draw a smooth circle of the provided radius.
     * @param _radius The circles radius.
     * @param _smooth The circles smoothness.
     * @return Int
     */
    inline function segmentsForSmoothCircle(_radius : Float, _smooth : Float = 5) : Int
    {
        return Std.int(_smooth * Maths.sqrt(_radius));
    }
}
