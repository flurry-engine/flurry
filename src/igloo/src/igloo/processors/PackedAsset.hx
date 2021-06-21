package igloo.processors;

class PackedAsset
{
    /**
     * The name of the atlas page this asset is contain within.
     */
    public final pageName : String;

	/**
	 * The width in pixels of the page this asset is contained within.
	 */
	public final pageWidth : Int;

	/**
	 * The height in pixels of the page this asset is contained within.
	 */
	public final pageHeight : Int;

	/**
	 * The request which generated this packed asset.
	 */
	public final request : PackRequest;

    public final x : Int;

    public final y : Int;

    public final w : Int;

    public final h : Int;

	public final u1 : Float;

	public final v1 : Float;

	public final u2 : Float;

	public final v2 : Float;

	public function new(_pageName, _pageWidth, _pageHeight, _request, _x, _y, _w, _h, _u1, _v1, _u2, _v2)
	{
		pageName   = _pageName;
		pageWidth  = _pageWidth;
		pageHeight = _pageHeight;
		request    = _request;
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