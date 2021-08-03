package uk.aidanlee.flurry.api.gpu.drawing;

import VectorMath;
import uk.aidanlee.flurry.api.maths.Matrix;
import uk.aidanlee.flurry.api.resources.builtin.PageFrameResource;

/**
 * Draw a frame at the given location in the world.
 * 
 * The position given represents the top left of the frame and the size of the drawn frame will be the pixel width and height of the actual frame.
 * @param _ctx Graphics context to draw to.
 * @param _frame Frame resource to draw.
 * @param _pos Location in the world to draw the frame at.
 */
overload extern inline function drawFrame(_ctx : GraphicsContext, _frame : PageFrameResource, _pos : Vec2)
{
    _ctx.usePage(_frame.page);
    _ctx.prepare();

    // v1
    _ctx.vtxOutput.write(vec3(_pos.x, _pos.y + _frame.height, 0));
    _ctx.vtxOutput.write(vec4(1));
    _ctx.vtxOutput.write(vec2(_frame.u1, _frame.v2));

    // v2
    _ctx.vtxOutput.write(vec3(_pos.x, _pos.y, 0));
    _ctx.vtxOutput.write(vec4(1));
    _ctx.vtxOutput.write(vec2(_frame.u1, _frame.v1));

    // v3
    _ctx.vtxOutput.write(vec3(_pos.x + _frame.width, _pos.y, 0));
    _ctx.vtxOutput.write(vec4(1));
    _ctx.vtxOutput.write(vec2(_frame.u2, _frame.v1));

    // v4
    _ctx.vtxOutput.write(vec3(_pos.x + _frame.width, _pos.y + _frame.height, 0));
    _ctx.vtxOutput.write(vec4(1));
    _ctx.vtxOutput.write(vec2(_frame.u2, _frame.v2));

    // Indices
    _ctx.idxOutput.write(0);
    _ctx.idxOutput.write(1);
    _ctx.idxOutput.write(2);

    _ctx.idxOutput.write(0);
    _ctx.idxOutput.write(2);
    _ctx.idxOutput.write(3);
}

/**
 * Draw a frame at the given location in the world offset around an origin.
 * 
 * The position the frame is drawn in the world is offset by the origin. The origin is a normalised value to offset against the frame size.
 * For example, an origin of `vec2(0.5, 0.5)` will cause the frame to be centred around the given position instead of the top left of the frame.
 * 
 * The size of the drawn frame will be the pixel width and height of the actual frame.
 * @param _ctx Graphics context to draw to.
 * @param _frame Frame resource to draw.
 * @param _pos Location in the world to draw the frame at.
 * @param _origin Normalised origin to centre the frame at.
 */
overload extern inline function drawFrame(_ctx : GraphicsContext, _frame : PageFrameResource, _pos : Vec2, _origin : Vec2)
{
    final origin   = _origin * vec2(_frame.width, _frame.height);
    final position = _pos - origin;

    drawFrame(_ctx, _frame, position);
}

overload extern inline function drawFrame(_ctx : GraphicsContext, _frame : PageFrameResource, _pos : Vec2, _angle : Float)
{
    drawFrame(_ctx, _frame, _pos, vec2(0, 0), _angle);
}

overload extern inline function drawFrame(_ctx : GraphicsContext, _frame : PageFrameResource, _pos : Vec2, _origin : Vec2, _angle : Float)
{
    drawFrame(_ctx, _frame, _pos, _origin, vec2(1), _angle, vec4(1));
}

overload extern inline function drawFrame(_ctx : GraphicsContext, _frame : PageFrameResource, _pos : Vec2, _origin : Vec2, _scale : Vec2)
{
    drawFrame(_ctx, _frame, _pos, _origin, _scale, 0, vec4(1));
}

overload extern inline function drawFrame(_ctx : GraphicsContext, _frame : PageFrameResource, _pos : Vec2, _origin : Vec2, _scale : Vec2, _angle)
{
    drawFrame(_ctx, _frame, _pos, _origin, _scale, _angle, vec4(1));
}

overload extern inline function drawFrame(_ctx : GraphicsContext, _frame : PageFrameResource, _pos : Vec2, _origin : Vec2, _scale : Vec2, _angle : Float, _colour : Vec4)
{
    final originAbs   = _origin * vec2(_frame.width, _frame.height);
    final translation = makeTranslation(_pos - originAbs);
    final origin      = makeTranslation(originAbs);
    final rotation    = makeRotationZ(radians(_angle));
    final scale       = makeScale(_scale);
    final originUndo  = makeTranslation(-originAbs);
    final transform   = translation * origin * rotation * scale * originUndo;

    _ctx.usePage(_frame.page);
    _ctx.prepare();

    // v1
    final o = transform * vec3(1, _frame.height, 1);
    _ctx.vtxOutput.write(o);
    _ctx.vtxOutput.write(_colour);
    _ctx.vtxOutput.write(vec2(_frame.u1, _frame.v2));

    // v2
    final o = transform * vec3(1);
    _ctx.vtxOutput.write(o);
    _ctx.vtxOutput.write(_colour);
    _ctx.vtxOutput.write(vec2(_frame.u1, _frame.v1));

    // v3
    final o = transform * vec3(_frame.width, 1, 1);
    _ctx.vtxOutput.write(o);
    _ctx.vtxOutput.write(_colour);
    _ctx.vtxOutput.write(vec2(_frame.u2, _frame.v1));

    // v4
    final o = transform * vec3(_frame.width, _frame.height, 1);
    _ctx.vtxOutput.write(o);
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