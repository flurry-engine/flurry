package igloo.atlas;

import igloo.processors.RequestType;
import binpacking.Rect;

class Frame
{
    public final rect : Rect;

    public final request : RequestType;

	public function new(_rect, _request)
    {
		rect    = _rect;
		request = _request;
	}
}