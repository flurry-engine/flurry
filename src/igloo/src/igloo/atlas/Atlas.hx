package igloo.atlas;

import igloo.processors.PackRequest;

using Safety;

class Atlas
{
    public final name : String;

    public final pages : Array<Page>;

    final xPad : Int;

    final yPad : Int;

    final maxPageWidth : Int;

    final maxPageHeight : Int;

    public function new(_name, _xPad, _yPad, _maxWidth, _maxHeight)
    {
        name          = _name;
        pages         = [];
        xPad          = _xPad;
        yPad          = _yPad;
        maxPageWidth  = _maxWidth;
        maxPageHeight = _maxHeight;
    }

    public function pack(_request : PackRequest)
    {
        // Get the width and height of the rectangle to pack.
        var width  = 0;
        var height = 0;

        switch _request
        {
            case Image(path):
                final info = stb.Image.info(path.toString());

                width  = info.w;
                height = info.h;
            case Bytes(_, w, h, _):
                width  = w;
                height = h;
        }

        // Try to pack the image into one of the existing pages.
        var frame = null;
        for (page in pages)
        {
            if (null != (frame = page.pack(_request, width, height)))
            {
                return frame.unsafe();
            }
        }

        // If it could not be fit into any of the existing pages, create a new one.
        final page   = new Page(name + pages.length, xPad, yPad, maxPageWidth, maxPageHeight);
        final packed = page.pack(_request, width, height);

        pages.push(page);

        return packed.unsafe();
    }
}