package igloo.processors;

class PackedResource
{
    /**
     * The ID of the atlas page this asset is contain within.
     */
    public final pageID : Int;

	/**
	 * The width in pixels of the page this asset is contained within.
	 */
	public final pageWidth : Int;

	/**
	 * The height in pixels of the page this asset is contained within.
	 */
	public final pageHeight : Int;

    public final x : Int;

    public final y : Int;

    public final w : Int;

    public final h : Int;

	public final u1 : Float;

	public final v1 : Float;

	public final u2 : Float;

	public final v2 : Float;

	public function new(_pageID, _pageWidth, _pageHeight, _x, _y, _w, _h, _u1, _v1, _u2, _v2)
	{
		pageID     = _pageID;
		pageWidth  = _pageWidth;
		pageHeight = _pageHeight;
		x          = _x;
		y          = _y;
		w          = _w;
		h          = _h;
		u1         = _u1;
		v1         = _v1;
		u2         = _u2;
		v2         = _v2;
	}
}