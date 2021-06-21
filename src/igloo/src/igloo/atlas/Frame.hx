package igloo.atlas;

import igloo.processors.PackRequest;
import binpacking.Rect;

class Frame
{
    public final rect : Rect;

    public final request : PackRequest;

	public function new(_rect, _request)
    {
		rect    = _rect;
		request = _request;
	}
}