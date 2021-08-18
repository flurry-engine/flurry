package uk.aidanlee.flurry.api.resources.builtin;

import uk.aidanlee.flurry.api.resources.ResourceID;

class FontResource extends Resource
{
    public final page : ResourceID;

    public final lineHeight : Float;

    public final glyphs : Map<Int, FontGlyph>;

    public function new(_id, _page, _lineHeight, _glyphs)
    {
        super(_id);

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