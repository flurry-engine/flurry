package igloo.atlas;

import igloo.processors.PackRequest;
import binpacking.Rect;

class Frame
{
    public final rect : Rect;

    public final request : PackRequest;

    public final xPad : Int;

    public final yPad : Int;

	public function new(_rect, _request, _xPad, _yPad)
    {
		rect    = _rect;
		request = _request;
		xPad    = _xPad;
		yPad    = _yPad;
	}
}