package igloo.atlas;

import igloo.processors.PackRequest;

using Safety;

class Atlas
{
    public final name : String;

    public final pages : Array<Page>;

    public function new(_name)
    {
        name  = _name;
        pages = [];
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
        final page   = new Page(name + pages.length, 0, 0, 4096, 4096);
        final packed = page.pack(_request, width, height);

        pages.push(page);

        return packed.unsafe();
    }
}