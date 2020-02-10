package uk.aidanlee.flurry.api.gpu.geometry.shapes;

import uk.aidanlee.flurry.api.gpu.geometry.Geometry;
import uk.aidanlee.flurry.api.gpu.geometry.shapes.CircleGeometry.CircleGeometryOptions;
import uk.aidanlee.flurry.api.maths.Maths;
import uk.aidanlee.flurry.api.maths.Vector2;
import uk.aidanlee.flurry.api.maths.Vector3;

using Safety;

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

        _options.endAngle   = _options.endAngle  .or(360);
        _options.startAngle = _options.startAngle.or(  0);

        var radiusX = _options.r.or(32);
        var radiusY = _options.r.or(32);

        radiusX = _options.rx.or(radiusX);
        radiusY = _options.ry.or(radiusY);

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
    public function set(_x : Float, _y : Float, _rx : Float, _ry : Float, _steps : Int, _startAngle : Float = 0, _endAngle : Float = 360)
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
            var segment = new Vector3(x, y / radialRatio);
            segmentPosition.push(segment);

            vertices.push(new Vertex( segment, color, new Vector2() ));

            // If past 0 add one for the previous segment to close the triangle.
            if (index > 0)
            {
                var prevVert = segmentPosition[index];
                vertices.push(new Vertex( prevVert.clone(), color, new Vector2() ));
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
            vertices.push(new Vertex( segmentPosition[0].clone(), color, new Vector2() ));
        }

        transformation.position.set_xy(_x, _y);
    }

    /**
     * Returns the number of segments needed to draw a smooth circle of the provided radius.
     * @param _radius The circles radius.
     * @param _smooth The circles smoothness.
     * @return Int
     */
    function segmentsForSmoothCircle(_radius : Float, _smooth : Float = 5) : Int
    {
        return Std.int(_smooth * Maths.sqrt(_radius));
    }
}
