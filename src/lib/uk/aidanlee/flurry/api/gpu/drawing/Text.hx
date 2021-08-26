package uk.aidanlee.flurry.api.gpu.drawing;

import VectorMath;
import haxe.Exception;
import uk.aidanlee.flurry.api.gpu.textures.SamplerState;
import uk.aidanlee.flurry.api.maths.Matrix;
import uk.aidanlee.flurry.api.resources.builtin.FontResource;

inline function measureText(_font : FontResource, _text : String)
{
    var width  = 0.0;
    var height = _font.lineHeight;

    for (i in 0..._text.length)
    {
        switch _text.charCodeAt(i)
        {
            case null:
                throw new Exception('Character code was null at position $i');
            case code:
                switch _font.glyphs.get(code)
                {
                    case null:
                        throw new Exception('No glyph for character code $code was found');
                    case glyph:
                        width  += glyph.advance;
                        height  = Math.max(height, glyph.height);
                }
        }
    }

    return vec2(width, height);
}

overload extern inline function drawText(_ctx : GraphicsContext, _font : FontResource, _text : String, _pos : Vec2)
{
    drawText(_ctx, _font, _text, _pos, vec2(0), vec2(1), 0, vec4(1));
}

overload extern inline function drawText(_ctx : GraphicsContext, _font : FontResource, _text : String, _pos : Vec2, _alignment : Vec2)
{
    drawText(_ctx, _font, _text, _pos, _alignment, vec2(1), 0, vec4(1));
}

overload extern inline function drawText(_ctx : GraphicsContext, _font : FontResource, _text : String, _pos : Vec2, _alignment : Vec2, _angle : Float)
{
    drawText(_ctx, _font, _text, _pos, _alignment, vec2(1), _angle, vec4(1));
}

overload extern inline function drawText(_ctx : GraphicsContext, _font : FontResource, _text : String, _pos : Vec2, _alignment : Vec2, _scale : Vec2)
{
    drawText(_ctx, _font, _text, _pos, _alignment, _scale, 0, vec4(1));
}

overload extern inline function drawText(_ctx : GraphicsContext, _font : FontResource, _text : String, _pos : Vec2, _alignment : Vec2, _scale : Vec2, _angle : Float)
{
    drawText(_ctx, _font, _text, _pos, _alignment, _scale, _angle, vec4(1));
}

overload extern inline function drawText(_ctx : GraphicsContext, _font : FontResource, _text : String, _pos : Vec2, _alignment : Vec2, _scale : Vec2, _angle : Float, _colour : Vec4)
{
    _ctx.usePage(0, _font.page, SamplerState.linear);
    _ctx.prepare();

    var x     = 0.0;
    var y     = 0.0;
    var index = 0;

    final size      = measureText(_font, _text);
    final origin    = size * _alignment;
    final transform = make2D(_pos, origin, _scale, radians(_angle));

    for (i in 0..._text.length)
    {
        switch _text.charCodeAt(i)
        {
            case null:
                throw new Exception('Character code was null at position $i');
            case code:
                switch _font.glyphs.get(code)
                {
                    case null:
                        throw new Exception('No glyph for character code $code was found');
                    case glyph:
                        // bottom left
                        _ctx.vtxOutput.write(vec3(transform * vec4(x + glyph.x, y + glyph.height, 0, 1)));
                        _ctx.vtxOutput.write(_colour);
                        _ctx.vtxOutput.write(vec2(glyph.u1, glyph.v2));

                        // Bottom right
                        _ctx.vtxOutput.write(vec3(transform * vec4(x + glyph.width, y + glyph.height, 0, 1)));
                        _ctx.vtxOutput.write(_colour);
                        _ctx.vtxOutput.write(vec2(glyph.u2, glyph.v2));

                        // Top left
                        _ctx.vtxOutput.write(vec3(transform * vec4(x + glyph.x, y + glyph.y, 0, 1)));
                        _ctx.vtxOutput.write(_colour);
                        _ctx.vtxOutput.write(vec2(glyph.u1, glyph.v1));

                        // Top right
                        _ctx.vtxOutput.write(vec3(transform * vec4(x + glyph.width, y + glyph.y, 0, 1)));
                        _ctx.vtxOutput.write(_colour);
                        _ctx.vtxOutput.write(vec2(glyph.u2, glyph.v1));

                        // indicies
                        _ctx.idxOutput.write(index + 0);
                        _ctx.idxOutput.write(index + 1);
                        _ctx.idxOutput.write(index + 2);
                        _ctx.idxOutput.write(index + 2);
                        _ctx.idxOutput.write(index + 1);
                        _ctx.idxOutput.write(index + 3);

                        index += 4;
                        x     += glyph.advance;
                }
        }
    }
}