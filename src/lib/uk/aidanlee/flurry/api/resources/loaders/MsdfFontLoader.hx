package uk.aidanlee.flurry.api.resources.loaders;

import uk.aidanlee.flurry.api.maths.Hash;
import uk.aidanlee.flurry.api.resources.Resource.ResourceID;
import haxe.io.Input;

using uk.aidanlee.flurry.api.InputUtils;

class MsdfFontLoader extends ResourceReader
{
    override function ids()
    {
        return [ 'ttf', 'otf' ];
    }

    override function read(_input : Input) : Array<Resource>
    {
        final name       = _input.readPrefixedString();
        final page       = _input.readPrefixedString();
        final lineHeight = _input.readFloat();
        final glyphCount = _input.readInt32();
        final glyphs     = new Map();

        trace(name, page, lineHeight, glyphCount);

        for (_ in 0...glyphCount)
        {
            final unicode = _input.readInt32();
            final advance = _input.readFloat();

            final pLeft   = _input.readFloat();
            final pTop    = _input.readFloat();
            final pRight  = _input.readFloat();
            final pBottom = _input.readFloat();

            final u1 = _input.readFloat();
            final v1 = _input.readFloat();
            final u2 = _input.readFloat();
            final v2 = _input.readFloat();

            glyphs[unicode] = new FontGlyph(advance, pLeft, pTop, pRight, pBottom, u1, v1, u2, v2);
        }

        return [ new MsdfFontResource(name, Hash.hash(page), lineHeight, glyphs) ];
    }
}

class MsdfFontResource extends Resource
{
    public final page : ResourceID;

    public final lineHeight : Float;

    public final glyphs : Map<Int, FontGlyph>;

    public function new(_name, _page, _lineHeight, _glyphs)
    {
        super(_name);

        page       = _page;
        lineHeight = _lineHeight;
        glyphs     = _glyphs;
    }
}

class FontGlyph
{
    public final advance : Float;

    public final x : Float;

    public final y : Float;

    public final width : Float;

    public final height : Float;

    public final u1 : Float;

    public final v1 : Float;

    public final u2 : Float;

    public final v2 : Float;

	public function new(_advance, _x, _y, _width, _height, _u1, _v1, _u2, _v2)
    {
        advance = _advance;
		x       = _x;
		y       = _y;
		width   = _width;
		height  = _height;
		u1      = _u1;
		v1      = _v1;
		u2      = _u2;
		v2      = _v2;
	}
}