package igloo.atlas;

import igloo.parcels.IDProvider;
import igloo.processors.PackRequest;

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

    public function pack(_request : PackRequest)
    {
        // Get the width and height and name of the resource to pack.
        // Also generate an ID for it.
        var width  = 0;
        var height = 0;
        var name   = '';
        final id   = provider.id();

        switch _request
        {
            case Image(resource, path):
                final info = stb.Image.info(path.toString());

                width  = info.w;
                height = info.h;
                name   = resource;
            case Bytes(resource, _, w, h, _):
                width  = w;
                height = h;
                name   = resource;
        }

        // Try to pack the image into one of the existing pages.
        var frame = null;
        for (page in pages)
        {
            if (null != (frame = page.pack(id, name, _request, width, height)))
            {
                return frame.unsafe();
            }
        }

        // If it could not be fit into any of the existing pages, create a new one.
        final page   = new Page(provider.id(), xPad, yPad, maxPageWidth, maxPageHeight);
        final packed = page.pack(id, name, _request, width, height);

        pages.push(page);

        return packed.unsafe();
    }
}