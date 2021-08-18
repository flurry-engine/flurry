package uk.aidanlee.flurry.api.gpu.drawing;

import uk.aidanlee.flurry.api.gpu.textures.SamplerState;
import VectorMath;
import uk.aidanlee.flurry.api.maths.Matrix;
import uk.aidanlee.flurry.api.resources.builtin.PageFrameResource;

//
// drawFrameScaled
//

overload extern inline function drawFrame(_ctx : GraphicsContext, _frame : PageFrameResource, _pos : Vec2)
{
    drawFrameTransformed(_ctx, _frame, make2D(_pos), vec4(1));
}

overload extern inline function drawFrame(_ctx : GraphicsContext, _frame : PageFrameResource, _pos : Vec2, _angle : Float)
{
    drawFrameTransformed(_ctx, _frame, make2D(_pos, radians(_angle)), vec4(1));
}

overload extern inline function drawFrame(_ctx : GraphicsContext, _frame : PageFrameResource, _pos : Vec2, _angle : Float, _colour : Vec4)
{
    drawFrameTransformed(_ctx, _frame, make2D(_pos, radians(_angle)), _colour);
}

overload extern inline function drawFrame(_ctx : GraphicsContext, _frame : PageFrameResource, _pos : Vec2, _origin : Vec2)
{
    final origin    = _origin * vec2(_frame.width, _frame.height);
    final transform = make2D(_pos, origin);

    drawFrameTransformed(_ctx, _frame, transform, vec4(1));
}

overload extern inline function drawFrame(_ctx : GraphicsContext, _frame : PageFrameResource, _pos : Vec2, _origin : Vec2, _angle : Float)
{
    final origin    = _origin * vec2(_frame.width, _frame.height);
    final transform = make2D(_pos, origin, radians(_angle));

    drawFrameTransformed(_ctx, _frame, transform, vec4(1));
}

overload extern inline function drawFrame(_ctx : GraphicsContext, _frame : PageFrameResource, _pos : Vec2, _origin : Vec2, _angle : Float, _colour : Vec4)
{
    final origin    = _origin * vec2(_frame.width, _frame.height);
    final transform = make2D(_pos, origin, radians(_angle));

    drawFrameTransformed(_ctx, _frame, transform, _colour);
}

//
// drawFrameScaled
//

overload extern inline function drawFrameScaled(_ctx : GraphicsContext, _frame : PageFrameResource, _pos : Vec2, _scale : Vec2)
{
    drawFrameTransformed(_ctx, _frame, make2D(_pos, vec2(0), _scale), vec4(1));
}

overload extern inline function drawFrameScaled(_ctx : GraphicsContext, _frame : PageFrameResource, _pos : Vec2, _scale : Vec2, _angle : Float)
{
    drawFrameTransformed(_ctx, _frame, make2D(_pos, vec2(0), _scale, _angle), vec4(1));
}

overload extern inline function drawFrameScaled(_ctx : GraphicsContext, _frame : PageFrameResource, _pos : Vec2, _scale : Vec2, _angle : Float, _colour : Vec4)
{
    drawFrameTransformed(_ctx, _frame, make2D(_pos, vec2(0), _scale, _angle), _colour);
}

overload extern inline function drawFrameScaled(_ctx : GraphicsContext, _frame : PageFrameResource, _pos : Vec2, _origin : Vec2, _scale : Vec2)
{
    final origin = _origin * vec2(_frame.width, _frame.height);

    drawFrameTransformed(_ctx, _frame, make2D(_pos, origin, _scale), vec4(1));
}

overload extern inline function drawFrameScaled(_ctx : GraphicsContext, _frame : PageFrameResource, _pos : Vec2, _origin : Vec2, _scale : Vec2, _angle : Float)
{
    final origin = _origin * vec2(_frame.width, _frame.height);

    drawFrameTransformed(_ctx, _frame, make2D(_pos, origin, _scale, _angle), vec4(1));
}

overload extern inline function drawFrameScaled(_ctx : GraphicsContext, _frame : PageFrameResource, _pos : Vec2, _origin : Vec2, _scale : Vec2, _angle : Float, _colour : Vec4)
{
    final origin = _origin * vec2(_frame.width, _frame.height);

    drawFrameTransformed(_ctx, _frame, make2D(_pos, origin, _scale, _angle), _colour);
}

//
// drawFrameStretched
//

overload extern inline function drawFrameStretched(_ctx : GraphicsContext, _frame : PageFrameResource, _pos : Vec2, _size : Vec2)
{
    final scale = _size / vec2(_frame.width, _frame.height);

    drawFrameScaled(_ctx, _frame, _pos, scale);
}

overload extern inline function drawFrameStretched(_ctx : GraphicsContext, _frame : PageFrameResource, _pos : Vec2, _size : Vec2, _angle : Float)
{
    final scale = _size / vec2(_frame.width, _frame.height);

    drawFrameScaled(_ctx, _frame, _pos, scale, _angle);
}

overload extern inline function drawFrameStretched(_ctx : GraphicsContext, _frame : PageFrameResource, _pos : Vec2, _size : Vec2, _angle : Float, _colour : Vec4)
{
    final scale = _size / vec2(_frame.width, _frame.height);

    drawFrameScaled(_ctx, _frame, _pos, scale, _angle, _colour);
}

overload extern inline function drawFrameStretched(_ctx : GraphicsContext, _frame : PageFrameResource, _pos : Vec2, _origin : Vec2, _size : Vec2)
{
    final scale  = _size / vec2(_frame.width, _frame.height);
    final origin = _origin * vec2(_frame.width, _frame.height);

    drawFrameScaled(_ctx, _frame, _pos, origin, scale);
}

overload extern inline function drawFrameStretched(_ctx : GraphicsContext, _frame : PageFrameResource, _pos : Vec2, _origin : Vec2, _size : Vec2, _angle : Float)
{
    final scale  = _size / vec2(_frame.width, _frame.height);
    final origin = _origin * vec2(_frame.width, _frame.height);

    drawFrameScaled(_ctx, _frame, _pos, origin, scale, _angle);
}

overload extern inline function drawFrameStretched(_ctx : GraphicsContext, _frame : PageFrameResource, _pos : Vec2, _origin : Vec2, _size : Vec2, _angle : Float, _colour : Vec4)
{
    final scale  = _size / vec2(_frame.width, _frame.height);
    final origin = _origin * vec2(_frame.width, _frame.height);

    drawFrameScaled(_ctx, _frame, _pos, origin, scale, _angle, _colour);
}

//
// drawFramePartial
//

overload extern inline function drawFramePartial(_ctx : GraphicsContext, _frame : PageFrameResource, _pos : Vec2, _area : Vec4)
{
    drawFramePartialStretched(_ctx, _frame, _pos, _area, vec2(_frame.width, _frame.height));
}

overload extern inline function drawFramePartial(_ctx : GraphicsContext, _frame : PageFrameResource, _pos : Vec2, _area : Vec4, _angle : Float)
{
    //
}

overload extern inline function drawFramePartial(_ctx : GraphicsContext, _frame : PageFrameResource, _pos : Vec2, _area : Vec4, _angle : Float, _colour : Vec4)
{
    //
}

overload extern inline function drawFramePartial(_ctx : GraphicsContext, _frame : PageFrameResource, _pos : Vec2, _origin : Vec2, _area : Vec4)
{
    //
}

overload extern inline function drawFramePartial(_ctx : GraphicsContext, _frame : PageFrameResource, _pos : Vec2, _origin : Vec2, _area : Vec4, _angle : Float)
{
    //
}

overload extern inline function drawFramePartial(_ctx : GraphicsContext, _frame : PageFrameResource, _pos : Vec2, _origin : Vec2, _area : Vec4, _angle : Float, _colour : Vec4)
{
    //
}

//
// drawFramePartialStretched
//

overload extern inline function drawFramePartialStretched(_ctx : GraphicsContext, _frame : PageFrameResource, _pos : Vec2, _area : Vec4, _size : Vec2)
{
    // Calculate UV coordinates from the frames UV coordinates and the provided pixel area vec4
    final pxSize    = vec2(_frame.width, _frame.height);
    final uvSize    = vec2(_frame.u2 - _frame.u1, _frame.v2 - _frame.v1);
    final uv1       = vec2(_frame.u1, _frame.v1) + (vec2(_area) / pxSize * uvSize);
    final uv2       = vec2(_frame.u1, _frame.v1) + ((vec2(_area.xy) + vec2(_area.zw)) / pxSize * uvSize);
    final transform = make2D(_pos);

    _ctx.usePage(_frame.page, SamplerState.nearest);
    
    drawQuad(
        _ctx,
        vec3(transform * vec4(0, 0, 0, 1)),
        vec3(transform * vec4(_size.x, 0, 0, 1)),
        vec3(transform * vec4(_size.x, _size.y, 0, 1)),
        vec3(transform * vec4(0, _size.y, 0, 1)),
        vec4(1),
        vec4(1),
        vec4(1),
        vec4(1),
        vec2(uv1.x, uv1.y),
        vec2(uv2.x, uv1.y),
        vec2(uv2.x, uv2.y),
        vec2(uv1.x, uv2.y));
}

overload extern inline function drawFramePartialStretched(_ctx : GraphicsContext, _frame : PageFrameResource, _pos : Vec2, _area : Vec4, _size : Vec2, _angle : Float)
{
    // Calculate UV coordinates from the frames UV coordinates and the provided pixel area vec4
    final pxSize    = vec2(_frame.width, _frame.height);
    final uvSize    = vec2(_frame.u2 - _frame.u1, _frame.v2 - _frame.v1);
    final uv1       = vec2(_frame.u1, _frame.v1) + (vec2(_area) / pxSize * uvSize);
    final uv2       = vec2(_frame.u1, _frame.v1) + ((vec2(_area.xy) + vec2(_area.zw)) / pxSize * uvSize);
    final transform = make2D(_pos, radians(_angle));

    _ctx.usePage(_frame.page, SamplerState.nearest);
    
    drawQuad(
        _ctx,
        vec3(transform * vec4(0, 0, 0, 1)),
        vec3(transform * vec4(_size.x, 0, 0, 1)),
        vec3(transform * vec4(_size.x, _size.y, 0, 1)),
        vec3(transform * vec4(0, _size.y, 0, 1)),
        vec4(1),
        vec4(1),
        vec4(1),
        vec4(1),
        vec2(uv1.x, uv1.y),
        vec2(uv2.x, uv1.y),
        vec2(uv2.x, uv2.y),
        vec2(uv1.x, uv2.y));
}

overload extern inline function drawFramePartialStretched(_ctx : GraphicsContext, _frame : PageFrameResource, _pos : Vec2, _area : Vec4, _size : Vec2, _angle : Float, _colour : Vec4)
{
    // Calculate UV coordinates from the frames UV coordinates and the provided pixel area vec4
    final pxSize    = vec2(_frame.width, _frame.height);
    final uvSize    = vec2(_frame.u2 - _frame.u1, _frame.v2 - _frame.v1);
    final uv1       = vec2(_frame.u1, _frame.v1) + (vec2(_area) / pxSize * uvSize);
    final uv2       = vec2(_frame.u1, _frame.v1) + ((vec2(_area.xy) + vec2(_area.zw)) / pxSize * uvSize);
    final transform = make2D(_pos, radians(_angle));

    _ctx.usePage(_frame.page, SamplerState.nearest);
    
    drawQuad(
        _ctx,
        vec3(transform * vec4(0, 0, 0, 1)),
        vec3(transform * vec4(_size.x, 0, 0, 1)),
        vec3(transform * vec4(_size.x, _size.y, 0, 1)),
        vec3(transform * vec4(0, _size.y, 0, 1)),
        vec4(_colour),
        vec4(_colour),
        vec4(_colour),
        vec4(_colour),
        vec2(uv1.x, uv1.y),
        vec2(uv2.x, uv1.y),
        vec2(uv2.x, uv2.y),
        vec2(uv1.x, uv2.y));
}

overload extern inline function drawFramePartialStretched(_ctx : GraphicsContext, _frame : PageFrameResource, _pos : Vec2, _origin : Vec2, _area : Vec4, _size : Vec2)
{
    // Calculate UV coordinates from the frames UV coordinates and the provided pixel area vec4
    final pxSize    = vec2(_frame.width, _frame.height);
    final uvSize    = vec2(_frame.u2 - _frame.u1, _frame.v2 - _frame.v1);
    final uv1       = vec2(_frame.u1, _frame.v1) + (vec2(_area) / pxSize * uvSize);
    final uv2       = vec2(_frame.u1, _frame.v1) + ((vec2(_area.xy) + vec2(_area.zw)) / pxSize * uvSize);
    final origin    = _origin * _size;
    final transform = make2D(_pos, origin);

    _ctx.usePage(_frame.page, SamplerState.nearest);
    
    drawQuad(
        _ctx,
        vec3(transform * vec4(0, 0, 0, 1)),
        vec3(transform * vec4(_size.x, 0, 0, 1)),
        vec3(transform * vec4(_size.x, _size.y, 0, 1)),
        vec3(transform * vec4(0, _size.y, 0, 1)),
        vec4(1),
        vec4(1),
        vec4(1),
        vec4(1),
        vec2(uv1.x, uv1.y),
        vec2(uv2.x, uv1.y),
        vec2(uv2.x, uv2.y),
        vec2(uv1.x, uv2.y));
}

overload extern inline function drawFramePartialStretched(_ctx : GraphicsContext, _frame : PageFrameResource, _pos : Vec2, _origin : Vec2, _area : Vec4, _size : Vec2, _angle : Float)
{
    // Calculate UV coordinates from the frames UV coordinates and the provided pixel area vec4
    final pxSize    = vec2(_frame.width, _frame.height);
    final uvSize    = vec2(_frame.u2 - _frame.u1, _frame.v2 - _frame.v1);
    final uv1       = vec2(_frame.u1, _frame.v1) + (vec2(_area) / pxSize * uvSize);
    final uv2       = vec2(_frame.u1, _frame.v1) + ((vec2(_area.xy) + vec2(_area.zw)) / pxSize * uvSize);
    final origin    = _origin * _size;
    final transform = make2D(_pos, origin, _angle);

    _ctx.usePage(_frame.page, SamplerState.nearest);
    
    drawQuad(
        _ctx,
        vec3(transform * vec4(0, 0, 0, 1)),
        vec3(transform * vec4(_size.x, 0, 0, 1)),
        vec3(transform * vec4(_size.x, _size.y, 0, 1)),
        vec3(transform * vec4(0, _size.y, 0, 1)),
        vec4(1),
        vec4(1),
        vec4(1),
        vec4(1),
        vec2(uv1.x, uv1.y),
        vec2(uv2.x, uv1.y),
        vec2(uv2.x, uv2.y),
        vec2(uv1.x, uv2.y));
}

overload extern inline function drawFramePartialStretched(_ctx : GraphicsContext, _frame : PageFrameResource, _pos : Vec2, _origin : Vec2, _area : Vec4, _size : Vec2, _angle : Float, _colour : Vec4)
{
    // Calculate UV coordinates from the frames UV coordinates and the provided pixel area vec4
    final pxSize    = vec2(_frame.width, _frame.height);
    final uvSize    = vec2(_frame.u2 - _frame.u1, _frame.v2 - _frame.v1);
    final uv1       = vec2(_frame.u1, _frame.v1) + (vec2(_area) / pxSize * uvSize);
    final uv2       = vec2(_frame.u1, _frame.v1) + ((vec2(_area.xy) + vec2(_area.zw)) / pxSize * uvSize);
    final origin    = _origin * _size;
    final transform = make2D(_pos, origin, _angle);

    _ctx.usePage(_frame.page, SamplerState.nearest);
    
    drawQuad(
        _ctx,
        vec3(transform * vec4(0, 0, 0, 1)),
        vec3(transform * vec4(_size.x, 0, 0, 1)),
        vec3(transform * vec4(_size.x, _size.y, 0, 1)),
        vec3(transform * vec4(0, _size.y, 0, 1)),
        vec4(_colour),
        vec4(_colour),
        vec4(_colour),
        vec4(_colour),
        vec2(uv1.x, uv1.y),
        vec2(uv2.x, uv1.y),
        vec2(uv2.x, uv2.y),
        vec2(uv1.x, uv2.y));
}

//
// drawFrameTiled
//

overload extern inline function drawFrameTiled(_ctx : GraphicsContext, _frame : PageFrameResource, _pos : Vec2, _size : Vec2)
{
    drawFrameTiled(_ctx, _frame, _pos, _size, vec4(1));
}

overload extern inline function drawFrameTiled(_ctx : GraphicsContext, _frame : PageFrameResource, _pos : Vec2, _size : Vec2, _colour : Vec4)
{
    final horizontalCount = Math.ceil(_size.x / _frame.width);
    final verticalCount   = Math.ceil(_size.y / _frame.height);

    for (row in 0...verticalCount)
    {
        for (col in 0...horizontalCount)
        {
            final x = col * _frame.width;
            final y = row * _frame.height;

            drawFrameTransformed(_ctx, _frame, make2D(_pos + vec2(x, y)), vec4(1));
        }
    }
}

//
// drawFrameDistorted
//

overload extern inline function drawFrameDistorted(_ctx : GraphicsContext, _frame : PageFrameResource, _p1 : Vec2, _p2 : Vec2, _p3 : Vec2, _p4 : Vec2)
{
    drawFrameDistorted(_ctx, _frame, _p1, _p2, _p3, _p4, vec4(1));
}

overload extern inline function drawFrameDistorted(_ctx : GraphicsContext, _frame : PageFrameResource, _p1 : Vec2, _p2 : Vec2, _p3 : Vec2, _p4 : Vec2, _colour : Vec4)
{
    _ctx.usePage(_frame.page, SamplerState.nearest);
    
    drawQuad(
        _ctx,
        vec3(_p1, 0),
        vec3(_p2, 0),
        vec3(_p3, 0),
        vec3(_p4, 0),
        _colour,
        _colour,
        _colour,
        _colour,
        vec2(_frame.u1, _frame.v1),
        vec2(_frame.u2, _frame.v1),
        vec2(_frame.u2, _frame.v2),
        vec2(_frame.u1, _frame.v2));
}

//
// Internal shared functions for drawing quads.
//

/**
 * Draw a frame transformed by the provided 4x4 matrix.
 * UV coordinates are provided by the frame resources.
 * @param _ctx Graphic context to draw the quad to.
 * @param _frame Frame resource to draw.
 * @param _transform Transformation matrix to apply to each vertex.
 * @param _colour Colour of each vertex.
 */
private inline function drawFrameTransformed(_ctx : GraphicsContext, _frame : PageFrameResource, _transform : Mat4, _colour : Vec4)
{
    _ctx.usePage(_frame.page, SamplerState.nearest);
    
    drawQuad(
        _ctx,
        vec3(_transform * vec4(0, 0, 0, 1)),
        vec3(_transform * vec4(_frame.width, 0, 0, 1)),
        vec3(_transform * vec4(_frame.width, _frame.height, 0, 1)),
        vec3(_transform * vec4(0, _frame.height, 0, 1)),
        _colour,
        _colour,
        _colour,
        _colour,
        vec2(_frame.u1, _frame.v1),
        vec2(_frame.u2, _frame.v1),
        vec2(_frame.u2, _frame.v2),
        vec2(_frame.u1, _frame.v2));
}

/**
 * Draw a indexed quad into the graphics context with a format of XYZ RGBA UV per vertex.
 * This function calls prepare before writing but does not set a page as it takes in no frame.
 * @param _ctx Graphic context to draw the quad to.
 * @param _p1 World position of the top left vertex of the quad.
 * @param _p2 World position of the top right vertex of the quad.
 * @param _p3 World position of the bottom right vertex of the quad.
 * @param _p4 World position of the bottom left vertex of the quad.
 * @param _c1 Colour of the top left vertex of the quad.
 * @param _c2 Colour of the top right vertex of the quad.
 * @param _c3 Colour of the bottom right vertex of the quad.
 * @param _c4 Colour of the bottom left vertex of the quad.
 * @param _t1 UV texture coordinate of the top left vertex of the quad.
 * @param _t2 UV texture coordinate of the top right vertex of the quad.
 * @param _t3 UV texture coordinate of the bottom right vertex of the quad.
 * @param _t4 UV texture coordinate of the bottom left vertex of the quad.
 */
private inline function drawQuad(
    _ctx : GraphicsContext,

    _p1 : Vec3,
    _p2 : Vec3,
    _p3 : Vec3,
    _p4 : Vec3,

    _c1 : Vec4,
    _c2 : Vec4,
    _c3 : Vec4,
    _c4 : Vec4,
    
    _t1 : Vec2,
    _t2 : Vec2,
    _t3 : Vec2,
    _t4 : Vec2)
{
    // Clockwise Winding Order
    _ctx.prepare();

    // top right
    _ctx.vtxOutput.write(_p2);
    _ctx.vtxOutput.write(_c2);
    _ctx.vtxOutput.write(_t2);

    // top left
    _ctx.vtxOutput.write(_p1);
    _ctx.vtxOutput.write(_c1);
    _ctx.vtxOutput.write(_t1);

    // bottom left
    _ctx.vtxOutput.write(_p4);
    _ctx.vtxOutput.write(_c4);
    _ctx.vtxOutput.write(_t4);

    // bottom right
    _ctx.vtxOutput.write(_p3);
    _ctx.vtxOutput.write(_c3);
    _ctx.vtxOutput.write(_t3);

    // Indices
    _ctx.idxOutput.write(0);
    _ctx.idxOutput.write(1);
    _ctx.idxOutput.write(2);

    _ctx.idxOutput.write(0);
    _ctx.idxOutput.write(2);
    _ctx.idxOutput.write(3);
}