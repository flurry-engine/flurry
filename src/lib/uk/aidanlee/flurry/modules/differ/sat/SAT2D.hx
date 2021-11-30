/**
 * MIT License
 * 
 * Copyright (c) 2017 Sven Bergström
 * Copyright (c) 2017 differ contributors
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

package uk.aidanlee.flurry.modules.differ.sat;

import VectorMath;
import uk.aidanlee.flurry.api.maths.Matrix;
import uk.aidanlee.flurry.modules.differ.shapes.Ray;
import uk.aidanlee.flurry.modules.differ.shapes.Circle;
import uk.aidanlee.flurry.modules.differ.shapes.Polygon;

class TestResult
{
    public final overlap : Float;
    public final separation : Vec2;
    public final unitVector : Vec2;

	public inline function new(_overlap, _separation, _unitVector)
    {
		overlap    = _overlap;
		separation = _separation;
		unitVector = _unitVector;
	}
}

class PolygonCollisionResult
{
    public final result : TestResult;

    public final other : TestResult;

    public inline function new(_result, _other)
    {
        result = _result;
        other  = _other;
    }
}

class RayCollisionResult
{
    public final start : Float;

    public final end : Float;

    public inline function new(_start, _end)
    {
        start = _start;
        end   = _end;
    }

    public inline function hitStart(_ray : Ray)
    {
        return _ray.start + (_ray.direction() * start);
    }

    public inline function hitEnd(_ray : Ray)
    {
        return _ray.start + (_ray.direction() * end);
    }
}

function testCircleVsCircle(_a : Circle, _b : Circle, _flip = false) : Null<TestResult>
{
    final circle1 = if (_flip) _b else _a;
    final circle2 = if (_flip) _a else _b;

    // add both radii together to get the colliding distance
    final totalRadius = (circle1.radius * circle1.scale) + (circle2.radius * circle2.scale);

    // find the distance between the two circles.
    final distance = (circle1.pos - circle2.pos).length();

    // if your distance is less than the totalRadius square(because distance is squared)
    return if (distance < totalRadius)
    {
        final difference = totalRadius - distance;
        final unitVector = (circle1.pos - circle2.pos).normalize();

        new TestResult(difference, unitVector * difference, unitVector);
    }
    else
    {
        null;
    }
}

function testCircleVsPolygon(_circle : Circle, _polygon : Polygon, _flip = false) : Null<TestResult>
{
    final matrix  = make2D(_polygon.pos, _polygon.origin, _polygon.scale, radians(_polygon.angle));
    final closest = {
        var point        = vec2(0);
        var testDistance = (0x3FFFFFFF : Float);

        for (i in 0..._polygon.vertices.length)
        {
            final transformed = vec2(matrix * vec4(_polygon.vertices[i], 0, 1));
            final distance    = transformed.distance(_circle.pos);
    
            if (distance < testDistance)
            {
                testDistance = distance;
                point        = transformed;
            }
        }

        point;
    }
    
    // Project all its points, 0 outside the loop
    final normalAxis = (closest - _circle.pos).normalize();
    final firstPoint = vec2(matrix * vec4(_polygon.vertices[0], 0, 1));

    var min1 = dot(normalAxis, firstPoint);
    var max1 = min1;

    for (i in 1..._polygon.vertices.length)
    {
        final transformed = vec2(matrix * vec4(_polygon.vertices[i], 0, 1));
        final dotProduct  = dot(normalAxis, transformed);

        if (dotProduct < min1)
        {
            min1 = dotProduct;
        }
        if (dotProduct > max1)
        {
            max1 = dotProduct;
        }
    }

    // project the circle
    final offset = dot(normalAxis, -_circle.pos);
    final max2   =  (_circle.radius * _circle.scale);
    final min2   = -(_circle.radius * _circle.scale);

    min1 += offset;
    max1 += offset;

    // if either test is greater than 0, there is a gap so we can exit early.
    final test1 = min1 - max2;
    final test2 = min2 - max1;

    if (test1 > 0 || test2 > 0)
    {
        return null;
    }

    // circle distance check
    final baseMin    = -(max2 - min1) * if (_flip) -1 else 1;
    final unitVector = vec2(normalAxis);

    var overlap = baseMin;
    var closest = Math.abs(baseMin);

    // find the normal axis for each point and project
    for (i in 0..._polygon.vertices.length)
    {
        normalAxis.copyFrom(findNormalAxis(matrix, _polygon.vertices, i).normalize());

        // project the polygon(again? yes, circles vs. polygon require more testing...)

        var min1 = dot(normalAxis, vec2(matrix * vec4(_polygon.vertices[0], 0, 1)));
        var max1 = min1;

        // project all the other points(see, cirlces v. polygons use lots of this...)
        for (j in 1..._polygon.vertices.length)
        {
            final dotProduct = dot(normalAxis, vec2(matrix * vec4(_polygon.vertices[j], 0, 1)));

            if (dotProduct < min1)
            {
                min1 = dotProduct;
            }
            if (dotProduct > max1)
            {
                max1 = dotProduct;
            }
        }

        // project the circle(again)
        var max2 =   _circle.radius * _circle.scale;
        var min2 = -(_circle.radius * _circle.scale);

        // offset points
        final offset = dot(normalAxis, -_circle.pos);
        min1 += offset;
        max1 += offset;

        // do the test, again
        final test1 = min1 - max2;
        final test2 = min2 - max1;

        // failed.. quit now
        if (test1 > 0 || test2 > 0)
        {
            return null;
        }

        var distMin = -(max2 - min1);
        if (_flip)
        {
            distMin *= -1;
        }

        if (Math.abs(distMin) < closest)
        {
            unitVector.copyFrom(normalAxis);
            overlap = distMin;
            closest = Math.abs(distMin);
        }
    }

    return new TestResult(overlap, unitVector * overlap, if (_flip) unitVector else -unitVector);
}

function testPolygonVsPolygon(_polygon1 : Polygon, _polygon2 : Polygon, _flip = false) : Null<PolygonCollisionResult>
{
    return switch checkPolygons(_polygon1, _polygon2, _flip)
    {
        case null: null;
        case hit1:
            switch checkPolygons(_polygon2, _polygon1, !_flip)
            {
                case null: null;
                case hit2:
                    var result = hit2;
                    var other  = hit1;

                    if (Math.abs(other.overlap) < Math.abs(result.overlap))
                    {
                        result = hit1;
                        other  = hit2;
                    }

                    new PolygonCollisionResult(result, other);
            }
    }
}

function testRayVsCircle(_ray : Ray, _circle : Circle) : Null<RayCollisionResult>
{
    final delta      = _ray.end - _ray.start;
    final ray2circle = _ray.start - _circle.pos;

    final r = _circle.radius * _circle.scale;
    final a = delta.x * delta.x + delta.y * delta.y;
    final b = 2 * dot(delta, ray2circle);
    final c = dot(ray2circle, ray2circle) - (r * r);
    final d = b * b - 4 * a * c;

    return if (d >= 0)
    {
        final d     = Math.sqrt(d);
        final t1    = (-b - d) / (2 * a);
        final t2    = (-b + d) / (2 * a);
        final valid = switch _ray.mode
        {
            case NotInfinite:
                t1 >= 0.0 && t1 <= 1.0;
            case InfiniteFromStart:
                t1 >= 0.0;
            case Infinite:
                true;
        }

        if (valid)
        {
            new RayCollisionResult(t1, t2);
        }
        else
        {
            null;
        }
    }
    else
    {
        null;
    }
}

function testRayVsPolygon(_ray : Ray, _polygon : Polygon) : Null<RayCollisionResult>
{
    var minU = Math.POSITIVE_INFINITY;
    var maxU = Math.NEGATIVE_INFINITY;

    final delta  = _ray.end - _ray.start;
    final matrix = make2D(_polygon.pos, _polygon.origin, _polygon.scale, radians(_polygon.angle));

    final v1 = vec2(matrix * vec4(_polygon.vertices[_polygon.vertices.length - 1], 0, 1));
    final v2 = vec2(matrix * vec4(_polygon.vertices[0], 0, 1));

    final ud = (v2.y - v1.y) * delta.x - (v2.x - v1.x) * delta.y;
    final ua = rayU(ud, _ray.start.x, _ray.start.y, v1.x, v1.y, v2.x - v1.x, v2.y - v1.y);
    final ub = rayU(ud, _ray.start.x, _ray.start.y, v1.x, v1.y, delta.x, delta.y);

    if (ud != 0.0 && ub >= 0.0 && ub <= 1.0)
    {
        if (ua < minU) minU = ua;
        if (ua > maxU) maxU = ua;
    }

    for (i in 1..._polygon.vertices.length)
    {
        final v1 = vec2(matrix * vec4(_polygon.vertices[i - 1], 0, 1));
        final v2 = vec2(matrix * vec4(_polygon.vertices[i], 0, 1));

        final ud = (v2.y - v1.y) * delta.x - (v2.x - v1.x) * delta.y;
        final ua = rayU(ud, _ray.start.x, _ray.start.y, v1.x, v1.y, v2.x - v1.x, v2.y - v1.y);
        final ub = rayU(ud, _ray.start.x, _ray.start.y, v1.x, v1.y, delta.x, delta.y);

        if (ud != 0.0 && ub >= 0.0 && ub <= 1.0)
        {
            if (ua < minU) minU = ua;
            if (ua > maxU) maxU = ua;
        }
    }

    final valid = switch (_ray.mode)
    {
        case NotInfinite:
            minU >= 0.0 && minU <= 1.0;
        case InfiniteFromStart:
            minU != Math.POSITIVE_INFINITY && minU >= 0.0;
        case Infinite:
            minU != Math.POSITIVE_INFINITY;
    }

    if (valid)
    {
        return new RayCollisionResult(minU, maxU);
    }

    return null;
}

function testRayVsRay(_ray1 : Ray, _ray2 : Ray) : Null<RayCollisionResult>
{
    final delta1 = _ray1.end - _ray1.start;
    final delta2 = _ray2.end - _ray2.start;
    final diff   = _ray1.start - _ray2.start;
    final ud     = delta2.y * delta1.x - delta2.x * delta1.y;

    if (ud == 0)
    {
        return null;
    }

    final u1 = (delta2.x * diff.y - delta2.y * diff.x) / ud;
    final u2 = (delta1.x * diff.y - delta1.y * diff.x) / ud;

    // TODO : ask if ray hit condition difference is intentional (> 0 and not >= 0 like other checks)
    final valid1 = switch _ray1.mode
    {
        case NotInfinite:
            u1 > 0 && u1 <= 1;
        case InfiniteFromStart:
            u1 > 0;
        case Infinite:
            true;
    }

    final valid2 = switch _ray2.mode
    {
        case NotInfinite:
            u2 > 0 && u2 <= 1;
        case InfiniteFromStart:
            u2 > 0;
        case Infinite:
            true;
    }

    if (valid1 && valid2)
    {
        return new RayCollisionResult(u1, u2);
    }

    return null;
}

private function checkPolygons(_polygon1 : Polygon, _polygon2 : Polygon, _flip = false) : Null<TestResult>
{
    var closest = (0x3FFFFFFF : Float);
    var overlap = 0.0;
    
    final unitVec     = vec2(0);
    final poly1Matrix = make2D(_polygon1.pos, _polygon1.origin, _polygon1.scale, radians(_polygon1.angle));
    final poly2Matrix = make2D(_polygon2.pos, _polygon2.origin, _polygon2.scale, radians(_polygon2.angle));

    // loop to begin projection
    for (i in 0..._polygon1.vertices.length)
    {
        final axis = findNormalAxis(poly1Matrix, _polygon1.vertices, i).normalize();

        // project polygon1
        var min1 = dot(axis, vec2(poly1Matrix * vec4(_polygon1.vertices[0], 0, 1)));
        var max1 = min1;

        for (j in 1..._polygon1.vertices.length)
        {
            final transformed = poly1Matrix * vec4(_polygon1.vertices[j], 0, 1);
            final testNum     = dot(axis, vec2(transformed));

            if (testNum < min1)
            {
                min1 = testNum;
            }
            if (testNum > max1)
            {
                max1 = testNum;
            }
        }

        // project polygon2
        var min2 = dot(axis, vec2(poly2Matrix * vec4(_polygon2.vertices[0], 0, 1)));
        var max2 = min2;

        for (j in 1..._polygon2.vertices.length)
        {
            final transformed = poly2Matrix * vec4(_polygon2.vertices[j], 0, 1);
            final testNum     = dot(axis, vec2(transformed));

            if (testNum < min2)
            {
                min2 = testNum;
            }
            if (testNum > max2)
            {
                max2 = testNum;
            }
        }

        final test1 = min1 - max2;
        final test2 = min2 - max1;

        if (test1 > 0 || test2 > 0)
        {
            return null;
        }

        var distMin = -(max2 - min1);
        if (_flip)
        {
            distMin *= -1;
        }

        if (Math.abs(distMin) < closest)
        {
            unitVec.copyFrom(axis);
            overlap = distMin;
            closest = Math.abs(distMin);
        }
    }

    return new TestResult(overlap, unitVec * overlap, if (_flip) -unitVec else unitVec);
}

private function rayU(_uDelta : Float, _aX : Float, _aY : Float, _bX : Float, _bY : Float, _dX : Float, _dY : Float)
{
    return (_dX * (_aY - _bY) - _dY * (_aX - _bX)) / _uDelta;
}

private inline function findNormalAxis(_matrix : Mat4, _vertices : Array<Vec2>, _index : Int)
{
    final nextVertex  = if (_index >= _vertices.length - 1) _vertices[0] else _vertices[_index + 1];
    final current     = _matrix * vec4(_vertices[_index], 0, 1);
    final transformed = _matrix * vec4(nextVertex, 0, 1);

    return vec2(
        -(transformed.y - current.y),
         (transformed.x - current.x)
    );
}
