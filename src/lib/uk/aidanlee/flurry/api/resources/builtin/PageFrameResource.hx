package uk.aidanlee.flurry.api.resources.builtin;

import uk.aidanlee.flurry.api.resources.Resource.ResourceID;

class PageFrameResource extends Resource
{
    public final page : ResourceID;

    public final x : Int;

    public final y : Int;

    public final width : Int;

    public final height : Int;

    public final u1 : Float;

    public final v1 : Float;

    public final u2 : Float;

    public final v2 : Float;

	public function new(_name, _page, _x, _y, _width, _height, _u1, _v1, _u2, _v2)
    {
        super(_name);

		page   = _page;
		x      = _x;
		y      = _y;
		width  = _width;
		height = _height;
		u1     = _u1;
		v1     = _v1;
		u2     = _u2;
		v2     = _v2;
	}
}