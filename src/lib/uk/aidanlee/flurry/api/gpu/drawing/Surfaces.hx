package uk.aidanlee.flurry.api.gpu.drawing;

import VectorMath;
import uk.aidanlee.flurry.api.maths.Matrix;

overload extern inline function drawSurface(_ctx : GraphicsContext, _surface : SurfaceID, _pos : Vec2, _size : Vec2)
{
    drawSurface(_ctx, _surface, _pos, _size, vec2(0), vec2(1), 0, vec4(1));
}

overload extern inline function drawSurface(_ctx : GraphicsContext, _surface : SurfaceID, _pos : Vec2, _size : Vec2, _origin : Vec2)
{
    drawSurface(_ctx, _surface, _pos, _size, _origin, vec2(1), 0, vec4(1));
}

overload extern inline function drawSurface(_ctx : GraphicsContext, _surface : SurfaceID, _pos : Vec2, _size : Vec2, _origin : Vec2, _angle : Float)
{
    drawSurface(_ctx, _surface, _pos, _size, _origin, vec2(1), _angle, vec4(1));
}

overload extern inline function drawSurface(_ctx : GraphicsContext, _surface : SurfaceID, _pos : Vec2, _size : Vec2, _origin : Vec2, _scale : Vec2)
{
    drawSurface(_ctx, _surface, _pos, _size, _origin, _scale, 0, vec4(1));
}

overload extern inline function drawSurface(_ctx : GraphicsContext, _surface : SurfaceID, _pos : Vec2, _size : Vec2, _origin : Vec2, _scale : Vec2, _angle : Float)
{
    drawSurface(_ctx, _surface, _pos, _size, _origin, _scale, _angle, vec4(1));
}

overload extern inline function drawSurface(_ctx : GraphicsContext, _surface : SurfaceID, _pos : Vec2, _size : Vec2, _origin : Vec2, _scale : Vec2, _angle : Float, _colour : Vec4)
{   
    _ctx.useSurface(_surface);
    _ctx.prepare();

    // Generate Transformation
    final origin    = _origin * _size;
    final transform = make2D(_pos, origin, _scale, radians(_angle));

    // v1
    _ctx.vtxOutput.write(vec3(transform * vec4(0, _size.y, 0, 1)));
    _ctx.vtxOutput.write(_colour);
    _ctx.vtxOutput.write(vec2(0, 1));

    // v2
    _ctx.vtxOutput.write(vec3(transform * vec4(0, 0, 0, 1)));
    _ctx.vtxOutput.write(_colour);
    _ctx.vtxOutput.write(vec2(0, 0));

    // v3
    _ctx.vtxOutput.write(vec3(transform * vec4(_size.x, 0, 0, 1)));
    _ctx.vtxOutput.write(_colour);
    _ctx.vtxOutput.write(vec2(1, 0));

    // v4
    _ctx.vtxOutput.write(vec3(transform * vec4(_size.x, _size.y, 0, 1)));
    _ctx.vtxOutput.write(_colour);
    _ctx.vtxOutput.write(vec2(1, 1));

    // Indices
    _ctx.idxOutput.write(0);
    _ctx.idxOutput.write(1);
    _ctx.idxOutput.write(2);

    _ctx.idxOutput.write(0);
    _ctx.idxOutput.write(2);
    _ctx.idxOutput.write(3);
}