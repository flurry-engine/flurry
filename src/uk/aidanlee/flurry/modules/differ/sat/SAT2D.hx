package uk.aidanlee.flurry.modules.differ.sat;

import uk.aidanlee.flurry.api.maths.Vector;
import uk.aidanlee.flurry.modules.differ.data.RayCollision;
import uk.aidanlee.flurry.modules.differ.data.RayIntersection;
import uk.aidanlee.flurry.modules.differ.data.ShapeCollision;
import uk.aidanlee.flurry.modules.differ.shapes.Circle;
import uk.aidanlee.flurry.modules.differ.shapes.Polygon;
import uk.aidanlee.flurry.modules.differ.shapes.Ray;

using Safety;

/**
 * Implementation details for the 2D SAT collision queries.
 * Used by the various shapes, and Collision API, mostly internally.
 */
class SAT2D
{
    static var tmp1 = new ShapeCollision();
    static var tmp2 = new ShapeCollision();

    /**
     * Test for a collision between a circle and a polygon.
     * 
     * If no collision has occured `null` is returned.
     * @param _circle  The circle to test.
     * @param _polygon The polygon to test.
     * @param _into    An existing collision result instance to place the result into.
     * @param _flip    If the polygon is to be treated as the first shape.
     * @return Null<ShapeCollision>
     */
    public static function testCircleVsPolygon(_circle : Circle, _polygon : Polygon, ?_into : Null<ShapeCollision>, _flip : Bool = false) : Null<ShapeCollision>
    {
        _into = _into.or(new ShapeCollision()).reset();

        var verts = _polygon.transformedVertices;

        var circleX = _circle.x;
        var circleY = _circle.y;

        var testDistance : Float = 0x3FFFFFFF;
        var distance = 0.0;
        var closestX = 0.0;
        var closestY = 0.0;

        for (i in 0...verts.length)
        {
            distance = vecLengthsq(circleX - verts[i].x, circleY - verts[i].y);

            if (distance < testDistance)
            {
                testDistance = distance;
                closestX = verts[i].x;
                closestY = verts[i].y;
            }
        }

        var normalAxisX = closestX - circleX;
        var normalAxisY = closestY - circleY;
        var normAxisLen = vecLength(normalAxisX, normalAxisY);

        normalAxisX = vecNormalize(normAxisLen, normalAxisX);
        normalAxisY = vecNormalize(normAxisLen, normalAxisY);

        // project all its points, 0 outside the loop
        var test = 0.0;
        var min1 = vecDot(normalAxisX, normalAxisY, verts[0].x, verts[0].y);
        var max1 = min1;

        for (j in 1...verts.length)
        {
            test = vecDot(normalAxisX, normalAxisY, verts[j].x, verts[j].y);
            if (test < min1) min1 = test;
            if (test > max1) max1 = test;
        }

        // project the circle
        var max2 =  _circle.transformedRadius;
        var min2 = -_circle.transformedRadius;
        var offset = vecDot(normalAxisX, normalAxisY, -circleX, -circleY);

        min1 += offset;
        max1 += offset;

        var test1 = min1 - max2;
        var test2 = min2 - max1;

        // if either test is greater than 0, there is a gap, we can give up now.
        if (test1 > 0 || test2 > 0) return null;

        // circle distance check
        var distMin = -(max2 - min1);
        if (_flip) distMin *= -1;

        _into.overlap = distMin;
        _into.unitVectorX = normalAxisX;
        _into.unitVectorY = normalAxisY;
        var closest = Math.abs(distMin);

        // find the normal axis for each point and project
        for (i in 0...verts.length)
        {
            normalAxisX = findNormalAxisX(verts, i);
            normalAxisY = findNormalAxisY(verts, i);

            var aLen = vecLength(normalAxisX, normalAxisY);
            normalAxisX = vecNormalize(aLen, normalAxisX);
            normalAxisY = vecNormalize(aLen, normalAxisY);

            // project the polygon(again? yes, circles vs. polygon require more testing...)
            min1 = vecDot(normalAxisX, normalAxisY, verts[0].x, verts[0].y);
            max1 = min1; //set max and min

            // project all the other points(see, cirlces v. polygons use lots of this...)
            for (j in 1 ... verts.length)
            {
                test = vecDot(normalAxisX, normalAxisY, verts[j].x, verts[j].y);
                if (test < min1) min1 = test;
                if (test > max1) max1 = test;
            }

            // project the circle(again)
            max2 =  _circle.transformedRadius; //max is radius
            min2 = -_circle.transformedRadius; //min is negative radius

            // offset points
            offset = vecDot(normalAxisX, normalAxisY, -circleX, -circleY);
            min1 += offset;
            max1 += offset;

            // do the test, again
            test1 = min1 - max2;
            test2 = min2 - max1;

            // failed.. quit now
            if (test1 > 0 || test2 > 0) return null;

            distMin = -(max2 - min1);
            if (_flip) distMin *= -1;

            if (Math.abs(distMin) < closest)
            {
                _into.unitVectorX = normalAxisX;
                _into.unitVectorY = normalAxisY;
                _into.overlap = distMin;
                closest = Math.abs(distMin);
            }
        }

        // if you made it here, there is a collision!!!!!

        _into.shape1 = if (_flip) _polygon else _circle;
        _into.shape2 = if (_flip)  _circle else _polygon;
        _into.separationX = _into.unitVectorX * _into.overlap;
        _into.separationY = _into.unitVectorY * _into.overlap;

        if (!_flip)
        {
            _into.unitVectorX = -_into.unitVectorX;
            _into.unitVectorY = -_into.unitVectorY;
        }

        return _into;
    }

    /**
     * Test for a collision between two circles.
     * 
     * If no collision has occured `null` is returned.
     * @param _circleA The first circle to test.
     * @param _circleB The second circle to test.
     * @param _into    An existing collision result instance to place the result into.
     * @param _flip    If circle B is to be treated as the first circle.
     * @return Null<ShapeCollision>
     */
    public static function testCircleVsCircle(_circleA : Circle, _circleB : Circle, ?_into : Null<ShapeCollision>, _flip :  Bool = false) : Null<ShapeCollision>
    {
        var circle1 = _flip ? _circleB : _circleA;
        var circle2 = _flip ? _circleA : _circleB;

        // add both radii together to get the colliding distance
        var totalRadius = circle1.transformedRadius + circle2.transformedRadius;

        // find the distance between the two circles using Pythagorean theorem. No square roots for optimization
        var distancesq = vecLengthsq(circle1.x - circle2.x, circle1.y - circle2.y);

        // if your distance is less than the totalRadius square(because distance is squared)
        // if distancesq < r^2
        if (distancesq < totalRadius * totalRadius)
        {
            _into = _into.or(new ShapeCollision()).reset();

            // find the difference. Square roots are needed here.
            var difference = totalRadius - Math.sqrt(distancesq);

                _into.shape1 = circle1;
                _into.shape2 = circle2;

                var unitVecX = circle1.x - circle2.x;
                var unitVecY = circle1.y - circle2.y;
                var unitVecLen = vecLength(unitVecX, unitVecY);

                unitVecX = vecNormalize(unitVecLen, unitVecX);
                unitVecY = vecNormalize(unitVecLen, unitVecY);

                _into.unitVectorX = unitVecX;
                _into.unitVectorY = unitVecY;

                // find the movement needed to separate the circles
                _into.separationX = _into.unitVectorX * difference;
                _into.separationY = _into.unitVectorY * difference;
                _into.overlap = difference;

            return _into;
        }

        return null;
    }

    /**
     * Test for a collision between two polygons.
     * 
     * If no collision has occured `null` is returned.
     * @param _polygon1 The first polygon to test.
     * @param _polygon2 The second polygon to test.
     * @param _into     An existing collision result instance to place the result into.
     * @param _flip     If polygon2 is to be treated as the first polygon.
     * @return Null<ShapeCollision>
     */
    public static function testPolygonVsPolygon(_polygon1 : Polygon, _polygon2 : Polygon, ?_into : Null<ShapeCollision>, _flip : Bool = false) : Null<ShapeCollision>
    {
        _into = _into.or(new ShapeCollision()).reset();

        if (checkPolygons(_polygon1, _polygon2, tmp1, _flip) == null)
        {
            return null;
        }

        if (checkPolygons(_polygon2, _polygon1, tmp2, !_flip) == null)
        {
            return null;
        }

        var result = null;
        var other  = null;

        if (Math.abs(tmp1.overlap) < Math.abs(tmp2.overlap))
        {
            result = tmp1;
            other  = tmp2;
        }
        else
        {
            result = tmp2;
            other  = tmp1;
        }

        result.otherOverlap = other.overlap;
        result.otherSeparationX = other.separationX;
        result.otherSeparationY = other.separationY;
        result.otherUnitVectorX = other.unitVectorX;
        result.otherUnitVectorY = other.unitVectorY;

        _into.copy_from(result);
        result = null;
        other  = null;

        return _into;
    }

    /**
     * Test for a collision between a ray and a circle.
     * 
     * If no collision has occured `null` is returned.
     * @param _ray    The ray to test.
     * @param _circle The circle to test.
     * @param _into   An existing collision result instance to place the result into.
     * @return Null<RayCollision>
     */
    public static function testRayVsCircle(_ray : Ray, _circle : Circle, ?_into : Null<RayCollision>) : Null<RayCollision>
    {
        var deltaX = _ray.end.x - _ray.start.x;
        var deltaY = _ray.end.y - _ray.start.y;
        var ray2circleX = _ray.start.x - _circle.position.x;
        var ray2circleY = _ray.start.y - _circle.position.y;

        var a = vecLengthsq(deltaX, deltaY);
        var b = 2 * vecDot(deltaX, deltaY, ray2circleX, ray2circleY);
        var c = vecDot(ray2circleX, ray2circleY, ray2circleX, ray2circleY) - (_circle.radius * _circle.radius);
        var d = b * b - 4 * a * c;

        if (d >= 0) {

            d = Math.sqrt(d);

            var t1 = (-b - d) / (2 * a);
            var t2 = (-b + d) / (2 * a);

            var valid = switch (_ray.infinite)
            {
                case not_infinite: t1 >= 0.0 && t1 <= 1.0;
                case infinite_from_start: t1 >= 0.0;
                case infinite: true;
            }

            if (valid)
            {
                _into = _into.or(new RayCollision()).reset();
                _into.shape = _circle;
                _into.ray   = _ray;
                _into.start = t1;
                _into.end   = t2;

                return _into;
            }
        }

        return null;
    }

    /**
     * Test for a collision between a ray and a polygon.
     * 
     * If no collision has occured `null` is returned.
     * @param _ray     The ray to test.
     * @param _polygon The polygon to test.
     * @param _into    An existing collision result instance to place the result into.
     * @return Null<RayCollision>
     */
    public static function testRayVsPolygon(_ray : Ray, _polygon : Polygon, ?_into : Null<RayCollision>) : Null<RayCollision>
    {
        var min_u = Math.POSITIVE_INFINITY;
        var max_u = Math.NEGATIVE_INFINITY;

        var startX = _ray.start.x;
        var startY = _ray.start.y;
        var deltaX = _ray.end.x - startX;
        var deltaY = _ray.end.y - startY;

        var verts = _polygon.transformedVertices;
        var v1 = verts[verts.length - 1];
        var v2 = verts[0];

        var ud = (v2.y - v1.y) * deltaX - (v2.x - v1.x) * deltaY;
        var ua = rayU(ud, startX, startY, v1.x, v1.y, v2.x - v1.x, v2.y - v1.y);
        var ub = rayU(ud, startX, startY, v1.x, v1.y, deltaX, deltaY);

        if (ud != 0.0 && ub >= 0.0 && ub <= 1.0)
        {
            if (ua < min_u) min_u = ua;
            if (ua > max_u) max_u = ua;
        }

        for (i in 1...verts.length)
        {
            v1 = verts[i - 1];
            v2 = verts[i];

            ud = (v2.y - v1.y) * deltaX - (v2.x - v1.x) * deltaY;
            ua = rayU(ud, startX, startY, v1.x, v1.y, v2.x - v1.x, v2.y - v1.y);
            ub = rayU(ud, startX, startY, v1.x, v1.y, deltaX, deltaY);

            if (ud != 0.0 && ub >= 0.0 && ub <= 1.0)
            {
                if (ua < min_u) min_u = ua;
                if (ua > max_u) max_u = ua;
            }
        }

        var valid = switch (_ray.infinite)
        {
            case not_infinite: min_u >= 0.0 && min_u <= 1.0;
            case infinite_from_start: min_u != Math.POSITIVE_INFINITY && min_u >= 0.0;
            case infinite: (min_u != Math.POSITIVE_INFINITY);
        }

        if (valid)
        {
            _into = _into.or(new RayCollision()).reset();
            _into.shape = _polygon;
            _into.ray   = _ray;
            _into.start = min_u;
            _into.end   = max_u;

            return _into;
        }

        return null;
    }

    /**
     * Test for a collision between two rays.
     * 
     * If no collision has occured `null` is returned.
     * @param _ray1 The first ray to test.
     * @param _ray2 The second ray to test.
     * @param _into An existing collision result instance to place the result into.
     * @return Null<RayIntersection>
     */
    public static function testRayVsRay(_ray1 : Ray, _ray2 : Ray, ?_into : Null<RayIntersection>) : Null<RayIntersection>
    {
        var delta1X = _ray1.end.x - _ray1.start.x;
        var delta1Y = _ray1.end.y - _ray1.start.y;
        var delta2X = _ray2.end.x - _ray2.start.x;
        var delta2Y = _ray2.end.y - _ray2.start.y;
        var diffX = _ray1.start.x - _ray2.start.x;
        var diffY = _ray1.start.y - _ray2.start.y;
        var ud = delta2Y * delta1X - delta2X * delta1Y;

        if (ud == 0.0) return null;

        var u1 = (delta2X * diffY - delta2Y * diffX) / ud;
        var u2 = (delta1X * diffY - delta1Y * diffX) / ud;

        // TODO : ask if ray hit condition difference is intentional (> 0 and not >= 0 like other checks)
        var valid1 = switch (_ray1.infinite)
        {
            case not_infinite: (u1 > 0.0 && u1 <= 1.0);
            case infinite_from_start: u1 > 0.0;
            case infinite: true;
        }

        var valid2 = switch (_ray2.infinite)
        {
            case not_infinite: (u2 > 0.0 && u2 <= 1.0);
            case infinite_from_start: u2 > 0.0;
            case infinite: true;
        }

        if (valid1 && valid2)
        {
            if (_into == null)
            {
                return new RayIntersection(_ray1, _ray2, u1, u2);
            }
            else
            {
                return _into.set(_ray1, _ray2, u1, u2);
            }
        }

        return null;
    }

    /**
     * Internal api - implementation details for testPolygonVsPolygon
     */

    /**
     * Calculate the collision between two polygons.
     * @param _polygon1 The first polygon.
     * @param _polygon2 The second polygon.
     * @param _into     Where the collision result will be placed.
     * @param _flip     If polygon 2 is to be treated as the first polygon.
     * @return ShapeCollision
     */
    static function checkPolygons(_polygon1 : Polygon, _polygon2 : Polygon, _into : ShapeCollision, _flip : Bool = false) : ShapeCollision
    {
        _into.reset();

        var test1   = 0.0;
        var test2   = 0.0;
        var testNum = 0.0;
        var min1    = 0.0;
        var max1    = 0.0;
        var min2    = 0.0;
        var max2    = 0.0;
        var closest : Float = 0x3FFFFFFF;

        var axisX  = 0.0;
        var axisY  = 0.0;
        var verts1 = _polygon1.transformedVertices;
        var verts2 = _polygon2.transformedVertices;

        // loop to begin projection
        for (i in 0...verts1.length)
        {
            axisX = findNormalAxisX(verts1, i);
            axisY = findNormalAxisY(verts1, i);
            var aLen = vecLength(axisX, axisY);
            axisX = vecNormalize(aLen, axisX);
            axisY = vecNormalize(aLen, axisY);

            // project polygon1
            min1 = vecDot(axisX, axisY, verts1[0].x, verts1[0].y);
            max1 = min1;

            for (j in 1...verts1.length)
            {
                testNum = vecDot(axisX, axisY, verts1[j].x, verts1[j].y);
                if (testNum < min1) min1 = testNum;
                if (testNum > max1) max1 = testNum;
            }

            // project polygon2
            min2 = vecDot(axisX, axisY, verts2[0].x, verts2[0].y);
            max2 = min2;

            for (j in 1 ... verts2.length)
            {
                testNum = vecDot(axisX, axisY, verts2[j].x, verts2[j].y);
                if (testNum < min2) min2 = testNum;
                if (testNum > max2) max2 = testNum;
            }

            test1 = min1 - max2;
            test2 = min2 - max1;

            if (test1 > 0 || test2 > 0) return null;

            var distMin = -(max2 - min1);
            if (_flip) distMin *= -1;

            if (Math.abs(distMin) < closest)
            {
                _into.unitVectorX = axisX;
                _into.unitVectorY = axisY;
                _into.overlap = distMin;
                closest = Math.abs(distMin);
            }
        }

        _into.shape1 = if (_flip) _polygon2 else _polygon1;
        _into.shape2 = if (_flip) _polygon1 else _polygon2;
        _into.separationX = -_into.unitVectorX * _into.overlap;
        _into.separationY = -_into.unitVectorY * _into.overlap;

        if (_flip)
        {
            _into.unitVectorX = -_into.unitVectorX;
            _into.unitVectorY = -_into.unitVectorY;
        }

        return _into;
    }

    /**
     * Internal helper for ray overlaps
     */

    static inline function rayU(_uDelta : Float, _aX : Float, _aY : Float, _bX : Float, _bY : Float, _dX : Float, _dY : Float) : Float
    {
        return (_dX * (_aY - _bY) - _dY * (_aX - _bX)) / _uDelta;
    }

    static inline function findNormalAxisX(_verts : Array<Vector>, _index : Int) : Float
    {
        var v2 = (_index >= _verts.length - 1) ? _verts[0] : _verts[_index + 1];

        return -(v2.y - _verts[_index].y);
    }

    static inline function findNormalAxisY(_verts : Array<Vector>, _index : Int) : Float
    {
        var v2 = (_index >= _verts.length - 1) ? _verts[0] : _verts[_index + 1];

        return (v2.x - _verts[_index].x);
    }

    static inline function vecLengthsq(_x : Float, _y : Float) : Float
    {
        return _x * _x + _y * _y;
    }

    static inline function vecLength(_x : Float, _y : Float) : Float
    {
        return Math.sqrt(vecLengthsq(_x, _y));
    }

    static inline function vecNormalize(_length : Float, _component : Float) : Float
    {
        return _length == 0 ? 0 : _component / _length;
    }

    static inline function vecDot(_x1 : Float, _y1 : Float, _x2 : Float, _y2 : Float) : Float
    {
        return _x1 * _x2 + _y1 * _y2;
    }
}
