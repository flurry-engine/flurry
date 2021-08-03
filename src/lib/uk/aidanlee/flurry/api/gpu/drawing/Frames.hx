package uk.aidanlee.flurry.api.gpu.drawing;

import VectorMath;
import uk.aidanlee.flurry.api.maths.Matrix;
import uk.aidanlee.flurry.api.resources.builtin.PageFrameResource;

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

overload extern inline function drawFrame(_ctx : GraphicsContext, _frame : PageFrameResource, _pos : Vec2, _origin : Vec2)
{
    final origin   = _origin * vec2(_frame.width, _frame.height);
    final position = _pos - origin;

    drawFrame(_ctx, _frame, position);
}

overload extern inline function drawFrame(_ctx : GraphicsContext, _frame : PageFrameResource, _pos : Vec2, _origin : Vec2, _angle : Float)
{
    final originAbs   = _origin * vec2(_frame.width, _frame.height);
    final translation = makeTranslation(_pos - originAbs);
    final origin      = makeTranslation(originAbs);
    final rotation    = makeRotationZ(_angle);
    final originUndo  = makeTranslation(-originAbs);
    final transform   = translation * origin * rotation * originUndo;

    _ctx.usePage(_frame.page);
    _ctx.prepare();

    // v1
    final o = transform * vec3(1, _frame.height, 1);
    _ctx.vtxOutput.write(o);
    _ctx.vtxOutput.write(vec4(1));
    _ctx.vtxOutput.write(vec2(_frame.u1, _frame.v2));

    // v2
    final o = transform * vec3(1);
    _ctx.vtxOutput.write(o);
    _ctx.vtxOutput.write(vec4(1));
    _ctx.vtxOutput.write(vec2(_frame.u1, _frame.v1));

    // v3
    final o = transform * vec3(_frame.width, 1, 1);
    _ctx.vtxOutput.write(o);
    _ctx.vtxOutput.write(vec4(1));
    _ctx.vtxOutput.write(vec2(_frame.u2, _frame.v1));

    // v4
    final o = transform * vec3(_frame.width, _frame.height, 1);
    _ctx.vtxOutput.write(o);
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

overload extern inline function drawFrame(_ctx : GraphicsContext, _frame : PageFrameResource, _pos : Vec2, _origin : Vec2, _scale : Vec2)
{
    //
}

overload extern inline function drawFrame(_ctx : GraphicsContext, _frame : PageFrameResource, _pos : Vec2, _origin : Vec2, _scale : Vec2, _angle : Float)
{
    //
}