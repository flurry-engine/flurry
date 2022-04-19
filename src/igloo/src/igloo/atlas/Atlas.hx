package igloo.atlas;

import igloo.parcels.IDProvider;

using Safety;

class Atlas
{
    final xPad : Int;

    final yPad : Int;

    final maxPageWidth : Int;

    final maxPageHeight : Int;

    final provider : IDProvider;

    public final pages : Array<Page>;

    public function new(_xPad, _yPad, _maxWidth, _maxHeight, _provider)
    {
        xPad          = _xPad;
        yPad          = _yPad;
        maxPageWidth  = _maxWidth;
        maxPageHeight = _maxHeight;
        provider      = _provider;
        pages         = [];
    }

    public function pack(_request, _width, _height)
    {
        // Try to pack the image into one of the existing pages.
        var frame = null;
        for (page in pages)
        {
            if (null != (frame = page.pack(_request, _width, _height)))
            {
                return frame.unsafe();
            }
        }

        // If it could not be fit into any of the existing pages, create a new one.
        final page   = new Page(provider.id(), xPad, yPad, maxPageWidth, maxPageHeight);
        final packed = page.pack(_request, _width, _height);

        pages.push(page);

        return packed.unsafe();
    }
}