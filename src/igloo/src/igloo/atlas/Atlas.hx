package igloo.atlas;

import igloo.processors.PackRequest;

using Safety;

class Atlas
{
    final xPad : Int;

    final yPad : Int;

    final maxPageWidth : Int;

    final maxPageHeight : Int;

    final nextID : () -> Int;

    public final pages : Array<Page>;

    public function new(_xPad, _yPad, _maxWidth, _maxHeight, _nextID)
    {
        xPad          = _xPad;
        yPad          = _yPad;
        maxPageWidth  = _maxWidth;
        maxPageHeight = _maxHeight;
        nextID        = _nextID;
        pages         = [];
    }

    public function pack(_request : PackRequest)
    {
        // Get the width and height of the rectangle to pack.
        var width   = 0;
        var height  = 0;
        var assetID = '';

        switch _request
        {
            case Image(id, path):
                final info = stb.Image.info(path.toString());

                width   = info.w;
                height  = info.h;
                assetID = id;
            case Bytes(id, _, w, h, _):
                width   = w;
                height  = h;
                assetID = id;
        }

        // Try to pack the image into one of the existing pages.
        var frame = null;
        for (page in pages)
        {
            if (null != (frame = page.pack(assetID, _request, width, height)))
            {
                return frame.unsafe();
            }
        }

        // If it could not be fit into any of the existing pages, create a new one.
        final page   = new Page(nextID(), xPad, yPad, maxPageWidth, maxPageHeight);
        final packed = page.pack(assetID, _request, width, height);

        pages.push(page);

        return packed.unsafe();
    }
}