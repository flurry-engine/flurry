package uk.aidanlee.flurry.api.gpu.drawing;

import VectorMath;
import uk.aidanlee.flurry.api.maths.Matrix;
import uk.aidanlee.flurry.api.resources.builtin.PageFrameResource;

overload extern inline function drawNineSlice(_ctx : GraphicsContext, _frame : PageFrameResource, _size : Vec2, _slice : Vec4, _pos : Vec2)
{
    drawNineSliceTransformed(_ctx, _frame, make2D(_pos), _size, _slice, vec4(1));
}

overload extern inline function drawNineSlice(_ctx : GraphicsContext, _frame : PageFrameResource, _size : Vec2, _slice : Vec4, _pos : Vec2, _angle : Float)
{
    drawNineSliceTransformed(_ctx, _frame, make2D(_pos, _angle), _size, _slice, vec4(1));
}

overload extern inline function drawNineSlice(_ctx : GraphicsContext, _frame : PageFrameResource, _size : Vec2, _slice : Vec4, _pos : Vec2, _angle : Float, _colour : Vec4)
{
    drawNineSliceTransformed(_ctx, _frame, make2D(_pos, _angle), _size, _slice, _colour);
}

overload extern inline function drawNineSlice(_ctx : GraphicsContext, _frame : PageFrameResource, _size : Vec2, _slice : Vec4, _pos : Vec2, _origin : Vec2)
{
    final origin    = _origin * _size;
    final transform = make2D(_pos, origin);

    drawNineSliceTransformed(_ctx, _frame, transform, _size, _slice, vec4(1));
}

overload extern inline function drawNineSlice(_ctx : GraphicsContext, _frame : PageFrameResource, _size : Vec2, _slice : Vec4, _pos : Vec2, _origin : Vec2, _angle : Float)
{
    final origin    = _origin * _size;
    final transform = make2D(_pos, origin, _angle);

    drawNineSliceTransformed(_ctx, _frame, transform, _size, _slice, vec4(1));
}

overload extern inline function drawNineSlice(_ctx : GraphicsContext, _frame : PageFrameResource, _size : Vec2, _slice : Vec4, _pos : Vec2, _origin : Vec2, _angle : Float, _colour : Vec4)
{
    final origin    = _origin * _size;
    final transform = make2D(_pos, origin, _angle);

    drawNineSliceTransformed(_ctx, _frame, transform, _size, _slice, _colour);
}

private inline function drawNineSliceTransformed(_ctx : GraphicsContext, _frame : PageFrameResource, _transform : Mat4, _size : Vec2, _slice : Vec4, _colour : Vec4)
{
    _ctx.usePage(_frame.page);

    final frameSize = vec2(_frame.width, _frame.height);
    final uvSize    = vec2(_frame.u2 - _frame.u1, _frame.v2 - _frame.v1);

    final slice1 = vec2(_slice.x, _slice.y);
    final slice2 = frameSize - vec2(_slice.z, _slice.w);

    final p1 = vec2(0);
    final p2 = vec2(_slice.x, _slice.y);
    final p3 = _size - vec2(_slice.z, _slice.w);
    final p4 = _size;

    final uv1 = vec2(_frame.u1, _frame.v1);
    final uv2 = uv1 + (slice1 / frameSize * uvSize);
    final uv3 = uv1 + (slice2 / frameSize * uvSize);
    final uv4 = vec2(_frame.u2, _frame.v2);

    // Top row
    drawQuad(_ctx, _transform, vec2(p1.x, p1.y), vec2(p2.x - p1.x, p2.y - p1.y), vec2(uv1.x, uv1.y), vec2(uv2.x, uv2.y), _colour);
    drawQuad(_ctx, _transform, vec2(p2.x, p1.y), vec2(p3.x - p2.x, p2.y - p1.y), vec2(uv2.x, uv1.y), vec2(uv3.x, uv2.y), _colour);
    drawQuad(_ctx, _transform, vec2(p3.x, p1.y), vec2(p4.x - p3.x, p2.y - p1.y), vec2(uv3.x, uv1.y), vec2(uv4.x, uv2.y), _colour);

    // Middle row
    drawQuad(_ctx, _transform, vec2(p1.x, p2.y), vec2(p2.x - p1.x, p3.y - p2.y), vec2(uv1.x, uv2.y), vec2(uv2.x, uv3.y), _colour);
    drawQuad(_ctx, _transform, vec2(p2.x, p2.y), vec2(p3.x - p2.x, p3.y - p2.y), vec2(uv2.x, uv2.y), vec2(uv3.x, uv3.y), _colour);
    drawQuad(_ctx, _transform, vec2(p3.x, p2.y), vec2(p4.x - p3.x, p3.y - p2.y), vec2(uv3.x, uv2.y), vec2(uv4.x, uv3.y), _colour);

    // Bottom row
    drawQuad(_ctx, _transform, vec2(p1.x, p3.y), vec2(p2.x - p1.x, p4.y - p3.y), vec2(uv1.x, uv3.y), vec2(uv2.x, uv4.y), _colour);
    drawQuad(_ctx, _transform, vec2(p2.x, p3.y), vec2(p3.x - p2.x, p4.y - p3.y), vec2(uv2.x, uv3.y), vec2(uv3.x, uv4.y), _colour);
    drawQuad(_ctx, _transform, vec2(p3.x, p3.y), vec2(p4.x - p3.x, p4.y - p3.y), vec2(uv3.x, uv3.y), vec2(uv4.x, uv4.y), _colour);
}

private inline function drawQuad(_ctx : GraphicsContext, _transform : Mat4, _pos : Vec2, _size : Vec2, _uv1 : Vec2, _uv2 : Vec2, _colour : Vec4)
{
    _ctx.prepare();

    // v1
    final o = _transform * vec4(_pos.x, _pos.y + _size.y, 0, 1);
    _ctx.vtxOutput.write(vec3(o));
    _ctx.vtxOutput.write(_colour);
    _ctx.vtxOutput.write(vec2(_uv1.x, _uv2.y));

    // v2
    final o = _transform * vec4(_pos.x, _pos.y, 0, 1);
    _ctx.vtxOutput.write(vec3(o));
    _ctx.vtxOutput.write(_colour);
    _ctx.vtxOutput.write(vec2(_uv1.x, _uv1.y));

    // v3
    final o = _transform * vec4(_pos.x + _size.x, _pos.y, 0, 1);
    _ctx.vtxOutput.write(vec3(o));
    _ctx.vtxOutput.write(_colour);
    _ctx.vtxOutput.write(vec2(_uv2.x, _uv1.y));

    // v4
    final o = _transform * vec4(_pos.x + _size.x, _pos.y + _size.y, 0, 1);
    _ctx.vtxOutput.write(vec3(o));
    _ctx.vtxOutput.write(_colour);
    _ctx.vtxOutput.write(vec2(_uv2.x, _uv2.y));

    // Indices
    _ctx.idxOutput.write(0);
    _ctx.idxOutput.write(1);
    _ctx.idxOutput.write(2);

    _ctx.idxOutput.write(0);
    _ctx.idxOutput.write(2);
    _ctx.idxOutput.write(3);
}