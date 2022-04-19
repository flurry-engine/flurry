package uk.aidanlee.flurry.api.gpu.drawing;

import VectorMath;
import uk.aidanlee.flurry.api.maths.Maths;

overload extern inline function drawLine(_ctx : GraphicsContext, _p0 : Vec2, _p1 : Vec2)
{
    drawLine(_ctx, _p0, _p1, 1, vec4(1));
}

overload extern inline function drawLine(_ctx : GraphicsContext, _p0 : Vec2, _p1 : Vec2, _thickness : Float)
{
    drawLine(_ctx, _p0, _p1, _thickness, vec4(1));
}

overload extern inline function drawLine(_ctx : GraphicsContext, _p0 : Vec2, _p1 : Vec2, _colour : Vec4)
{
    drawLine(_ctx, _p0, _p1, 1, _colour);
}

overload extern inline function drawLine(_ctx : GraphicsContext, _p0 : Vec2, _p1 : Vec2, _thickness : Float, _colour : Vec4)
{
    final angle = angleBetween(_p0, _p1) - 90;
    final width = _thickness * 0.5;
    final p0    = _p0 + polarToCartesian(width, angle);
    final p1    = _p0 - polarToCartesian(width, angle);
    final p2    = _p1 - polarToCartesian(width, angle);
    final p3    = _p1 + polarToCartesian(width, angle);

    // Clockwise Winding Order
    _ctx.prepare();

    _ctx.vtxOutput.write(vec3(p0, 0));
    _ctx.vtxOutput.write(_colour);

    _ctx.vtxOutput.write(vec3(p1, 0));
    _ctx.vtxOutput.write(_colour);

    _ctx.vtxOutput.write(vec3(p2, 0));
    _ctx.vtxOutput.write(_colour);

    _ctx.vtxOutput.write(vec3(p3, 0));
    _ctx.vtxOutput.write(_colour);

    // Indices
    _ctx.idxOutput.write(0);
    _ctx.idxOutput.write(1);
    _ctx.idxOutput.write(2);

    _ctx.idxOutput.write(0);
    _ctx.idxOutput.write(2);
    _ctx.idxOutput.write(3);
}

overload extern inline function drawCircle(_ctx : GraphicsContext, _centre : Vec2, _radius : Float)
{
    drawCircle(_ctx, _centre, _radius, vec4(1));
}

overload extern inline function drawCircle(_ctx : GraphicsContext, _centre : Vec2, _radius : Float, _colour : Vec4)
{
    drawSegment(_ctx, _centre, _radius, 0, 360, _colour);
}

overload extern inline function drawSegment(_ctx : GraphicsContext, _centre : Vec2, _radius : Float, _from : Float, _angle : Float)
{
    drawSegment(_ctx, _centre, _radius, _from, _angle, vec4(1));
}

overload extern inline function drawSegment(_ctx : GraphicsContext, _centre : Vec2, _radius : Float, _from : Float, _angle : Float, _colour : Vec4)
{
    // threshold is a magic number, the maximum number of pixels each segment in the drawn arc should be.
    final threshold = 3;
    final segments  = Std.int((_angle / 360 * Math.PI * (_radius * 2)) / threshold);
    final increment = _angle / segments;

    var vtxCount = 1;

    _ctx.prepare();

    // Since we're doing indexed drawing we can write the centre point once and re-use it by inserting its index for each segment.
    _ctx.vtxOutput.write(vec3(_centre, 0));
    _ctx.vtxOutput.write(_colour);

    for (i in 0...segments)
    {
        final p0 = _centre + polarToCartesian(_radius, _from + (increment * i));
        final p1 = _centre + polarToCartesian(_radius, _from + (increment * (i + 1)));

        _ctx.vtxOutput.write(vec3(p0, 0));
        _ctx.vtxOutput.write(_colour);
        _ctx.vtxOutput.write(vec3(p1, 0));
        _ctx.vtxOutput.write(_colour);
    
        // Indices
        _ctx.idxOutput.write(0);
        _ctx.idxOutput.write(vtxCount + 0);
        _ctx.idxOutput.write(vtxCount + 1);

        vtxCount += 2;
    }
}

overload extern inline function drawTriangle(_ctx : GraphicsContext, _p0 : Vec2, _p1 : Vec2, _p2 : Vec2)
{
    drawTriangle(_ctx, _p0, _p1, _p2, vec4(1));
}

overload extern inline function drawTriangle(_ctx : GraphicsContext, _p0 : Vec2, _p1 : Vec2, _p2 : Vec2, _colour : Vec4)
{
    _ctx.prepare();

    _ctx.vtxOutput.write(vec3(_p0, 0));
    _ctx.vtxOutput.write(_colour);

    _ctx.vtxOutput.write(vec3(_p1, 0));
    _ctx.vtxOutput.write(_colour);

    _ctx.vtxOutput.write(vec3(_p2, 0));
    _ctx.vtxOutput.write(_colour);

    _ctx.idxOutput.write(0);
    _ctx.idxOutput.write(1);
    _ctx.idxOutput.write(2);
}

overload extern inline function drawRectangle(_ctx : GraphicsContext, _size : Vec4)
{
    drawRectangle(_ctx, _size, vec4(1));
}

overload extern inline function drawRectangle(_ctx : GraphicsContext, _size : Vec4, _colour : Vec4)
{
    // Clockwise Winding Order
    _ctx.prepare();

    _ctx.vtxOutput.write(vec3(_size.xy, 0));
    _ctx.vtxOutput.write(_colour);

    _ctx.vtxOutput.write(vec3(_size.x + _size.z, _size.y, 0));
    _ctx.vtxOutput.write(_colour);

    _ctx.vtxOutput.write(vec3(_size.xy + _size.zw, 0));
    _ctx.vtxOutput.write(_colour);

    _ctx.vtxOutput.write(vec3(_size.x, _size.y + _size.w, 0));
    _ctx.vtxOutput.write(_colour);

    // Indices
    _ctx.idxOutput.write(0);
    _ctx.idxOutput.write(1);
    _ctx.idxOutput.write(2);

    _ctx.idxOutput.write(0);
    _ctx.idxOutput.write(2);
    _ctx.idxOutput.write(3);
}

overload extern inline function drawPolygon(_ctx : GraphicsContext, _centre : Vec2, _radius : Float, _sides : Int)
{
    drawPolygon(_ctx, _centre, _radius, _sides, vec4(1));
}

overload extern inline function drawPolygon(_ctx : GraphicsContext, _centre : Vec2, _radius : Float, _sides : Int, _colour : Vec4)
{
    final theta = 360 / _sides;
    
    var vtxCount = 1;

    _ctx.prepare();

    // Since we're doing indexed drawing we can write the centre point once and re-use it by inserting its index for each segment.
    _ctx.vtxOutput.write(vec3(_centre, 0));
    _ctx.vtxOutput.write(_colour);

    for (i in 0..._sides)
    {
        final p0 = _centre + polarToCartesian(_radius, theta * i);
        final p1 = _centre + polarToCartesian(_radius, theta * (i + 1));

        _ctx.vtxOutput.write(vec3(p0, 0));
        _ctx.vtxOutput.write(_colour);
        _ctx.vtxOutput.write(vec3(p1, 0));
        _ctx.vtxOutput.write(_colour);
    
        // Indices
        _ctx.idxOutput.write(0);
        _ctx.idxOutput.write(vtxCount + 0);
        _ctx.idxOutput.write(vtxCount + 1);

        vtxCount += 2;
    }
}

overload extern inline function drawCircleOutline(_ctx : GraphicsContext, _centre : Vec2, _radius : Float, _thickness = 1.0)
{
    drawCircleOutline(_ctx, _centre, _radius, _thickness, vec4(1));
}

overload extern inline function drawCircleOutline(_ctx : GraphicsContext, _centre : Vec2, _radius : Float, _thickness = 1.0, _colour : Vec4)
{
    drawArc(_ctx, _centre, _radius, 0, 360, _thickness, _colour);
}

overload extern inline function drawArc(_ctx : GraphicsContext, _centre : Vec2, _radius : Float, _from : Float, _angle : Float, _thickness : Float, _colour : Vec4)
{
    // threshold is a magic number, the maximum number of pixels each segment in the drawn arc should be.
    final threshold = 3;
    final segments  = Std.int((_angle / 360 * Math.PI * (_radius * 2)) / threshold);
    final increment = _angle / segments;
    final half      = _thickness * 0.5;

    _ctx.prepare();

    for (i in 0...segments)
    {
        final p0 = _centre + polarToCartesian(_radius - half, _from + (increment * i));
        final p1 = _centre + polarToCartesian(_radius + half, _from + (increment * i));
        final p3 = _centre + polarToCartesian(_radius + half, _from + (increment * (i + 1)));
        final p2 = _centre + polarToCartesian(_radius - half, _from + (increment * (i + 1)));

        _ctx.vtxOutput.write(vec3(p0, 0));
        _ctx.vtxOutput.write(_colour);

        _ctx.vtxOutput.write(vec3(p1, 0));
        _ctx.vtxOutput.write(_colour);

        _ctx.vtxOutput.write(vec3(p2, 0));
        _ctx.vtxOutput.write(_colour);

        _ctx.vtxOutput.write(vec3(p3, 0));
        _ctx.vtxOutput.write(_colour);

        // Indices
        _ctx.idxOutput.write((i * 4) + 0);
        _ctx.idxOutput.write((i * 4) + 1);
        _ctx.idxOutput.write((i * 4) + 3);

        _ctx.idxOutput.write((i * 4) + 0);
        _ctx.idxOutput.write((i * 4) + 3);
        _ctx.idxOutput.write((i * 4) + 2);
    }
}

overload extern inline function drawRectangleOutline(_ctx : GraphicsContext, _size : Vec4, _thickness = 1.0)
{
    drawRectangleOutline(_ctx, _size, _thickness, vec4(1));
}

overload extern inline function drawRectangleOutline(_ctx : GraphicsContext, _size : Vec4, _thickness = 1.0, _colour : Vec4)
{
    drawLine(_ctx, vec2(_size.xy), vec2(_size.x + _size.z, _size.y), _thickness, _colour);
    drawLine(_ctx, vec2(_size.x + _size.z, _size.y), vec2(_size.x + _size.z, _size.y + _size.w), _thickness, _colour);
    drawLine(_ctx, vec2(_size.x + _size.z, _size.y + _size.w), vec2(_size.x, _size.y + _size.w), _thickness, _colour);
    drawLine(_ctx, vec2(_size.x, _size.y + _size.w), vec2(_size.xy), _thickness, _colour);
}

overload extern inline function drawPolygonOutline(_ctx : GraphicsContext, _centre : Vec2, _radius : Float, _sides : Int, _thickness = 1.0)
{
    drawPolygonOutline(_ctx, _centre, _radius, _sides, _thickness, vec4(1));
}

overload extern inline function drawPolygonOutline(_ctx : GraphicsContext, _centre : Vec2, _radius : Float, _sides : Int, _thickness = 1.0, _colour : Vec4)
{
    final theta = 360 / _sides;
    final half  = _thickness * 0.5;

    // Clockwise Winding Order
    _ctx.prepare();

    for (i in 0..._sides)
    {
        final p0 = _centre + polarToCartesian(_radius - half, theta * i);
        final p1 = _centre + polarToCartesian(_radius + half, theta * i);
        final p3 = _centre + polarToCartesian(_radius + half, theta * (i + 1));
        final p2 = _centre + polarToCartesian(_radius - half, theta * (i + 1));

        _ctx.vtxOutput.write(vec3(p0, 0));
        _ctx.vtxOutput.write(_colour);

        _ctx.vtxOutput.write(vec3(p1, 0));
        _ctx.vtxOutput.write(_colour);

        _ctx.vtxOutput.write(vec3(p2, 0));
        _ctx.vtxOutput.write(_colour);

        _ctx.vtxOutput.write(vec3(p3, 0));
        _ctx.vtxOutput.write(_colour);

        // Indices
        _ctx.idxOutput.write((i * 4) + 0);
        _ctx.idxOutput.write((i * 4) + 1);
        _ctx.idxOutput.write((i * 4) + 3);

        _ctx.idxOutput.write((i * 4) + 0);
        _ctx.idxOutput.write((i * 4) + 3);
        _ctx.idxOutput.write((i * 4) + 2);
    }
}