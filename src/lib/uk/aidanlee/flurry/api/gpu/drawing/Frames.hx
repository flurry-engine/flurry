package uk.aidanlee.flurry.api.gpu.drawing;

import VectorMath;
import uk.aidanlee.flurry.api.maths.Matrix;
import uk.aidanlee.flurry.api.resources.builtin.PageFrameResource;

overload extern inline function drawFrame(_ctx : GraphicsContext, _frame : PageFrameResource, _pos : Vec2)
{
    drawTransformedQuad(_ctx, _frame, make2D(_pos), vec4(1));
}

overload extern inline function drawFrame(_ctx : GraphicsContext, _frame : PageFrameResource, _pos : Vec2, _origin : Vec2)
{
    final origin    = _origin * vec2(_frame.width, _frame.height);
    final transform = make2D(_pos, origin);

    drawTransformedQuad(_ctx, _frame, transform, vec4(1));
}

overload extern inline function drawFrame(_ctx : GraphicsContext, _frame : PageFrameResource, _pos : Vec2, _angle : Float)
{
    final transform = make2D(_pos, radians(_angle));

    drawTransformedQuad(_ctx, _frame, transform, vec4(1));
}

overload extern inline function drawFrame(_ctx : GraphicsContext, _frame : PageFrameResource, _pos : Vec2, _origin : Vec2, _angle : Float)
{
    final origin    = _origin * vec2(_frame.width, _frame.height);
    final transform = make2D(_pos, origin, radians(_angle));

    drawTransformedQuad(_ctx, _frame, transform, vec4(1));
}

overload extern inline function drawFrame(_ctx : GraphicsContext, _frame : PageFrameResource, _pos : Vec2, _origin : Vec2, _scale : Vec2)
{
    final origin    = _origin * vec2(_frame.width, _frame.height);
    final transform = make2D(_pos, origin, _scale);

    drawTransformedQuad(_ctx, _frame, transform, vec4(1));
}

overload extern inline function drawFrame(_ctx : GraphicsContext, _frame : PageFrameResource, _pos : Vec2, _origin : Vec2, _scale : Vec2, _angle : Float)
{
    drawFrame(_ctx, _frame, _pos, _origin, _scale, _angle, vec4(1));
}

overload extern inline function drawFrame(_ctx : GraphicsContext, _frame : PageFrameResource, _pos : Vec2, _origin : Vec2, _scale : Vec2, _angle : Float, _colour : Vec4)
{
    final origin    = _origin * vec2(_frame.width, _frame.height);
    final transform = make2D(_pos, origin, _scale, radians(_angle));

    drawTransformedQuad(_ctx, _frame, transform, _colour);
}

overload extern inline function drawFrameTiled(_ctx : GraphicsContext, _frame : PageFrameResource, _pos : Vec2, _size : Vec2)
{
    final horizontalCount = Math.ceil(_size.x / _frame.width);
    final verticalCount   = Math.ceil(_size.y / _frame.height);

    for (row in 0...verticalCount)
    {
        for (col in 0...horizontalCount)
        {
            final x = col * _frame.width;
            final y = row * _frame.height;

            drawFrame(_ctx, _frame, vec2(x, y));
        }
    }
}

private inline function drawTransformedQuad(_ctx : GraphicsContext, _frame : PageFrameResource, _transform : Mat4, _colour : Vec4)
{
    _ctx.usePage(_frame.page);
    _ctx.prepare();

    // Clockwise Winding Order

    // top right
    _ctx.vtxOutput.write(vec3(_transform * vec4(_frame.width, 0, 0, 1)));
    _ctx.vtxOutput.write(_colour);
    _ctx.vtxOutput.write(vec2(_frame.u2, _frame.v1));

    // top left
    _ctx.vtxOutput.write(vec3(_transform * vec4(0, 0, 0, 1)));
    _ctx.vtxOutput.write(_colour);
    _ctx.vtxOutput.write(vec2(_frame.u1, _frame.v1));

    // bottom left
    _ctx.vtxOutput.write(vec3(_transform * vec4(0, _frame.height, 0, 1)));
    _ctx.vtxOutput.write(_colour);
    _ctx.vtxOutput.write(vec2(_frame.u1, _frame.v2));

    // bottom right
    _ctx.vtxOutput.write(vec3(_transform * vec4(_frame.width, _frame.height, 0, 1)));
    _ctx.vtxOutput.write(_colour);
    _ctx.vtxOutput.write(vec2(_frame.u2, _frame.v2));

    // Indices
    _ctx.idxOutput.write(0);
    _ctx.idxOutput.write(1);
    _ctx.idxOutput.write(2);

    _ctx.idxOutput.write(0);
    _ctx.idxOutput.write(2);
    _ctx.idxOutput.write(3);
}