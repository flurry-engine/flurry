package igloo.blit;

import haxe.Exception;
import igloo.processors.PackRequest;
import igloo.atlas.Page;

function blit(_page : Page)
{
    final bpp    = 4;
    final output = haxe.io.Bytes.alloc(_page.width * _page.height * bpp);

    for (frame in _page.frames)
    {
        final input  = getDataForRequest(frame.request);
        final xSrc   = Std.int(frame.rect.x + _page.xPad);
        final ySrc   = Std.int(frame.rect.y + _page.yPad);
        final width  = Std.int(frame.rect.width - (_page.xPad * 2));
        final height = Std.int(frame.rect.height - (_page.yPad * 2));
        final line   = width * bpp;

        for (i in 0...height)
        {
            final dstAddr = ((i + ySrc) * _page.width * bpp) + (xSrc * bpp);
            final srcAddr = (i * width * bpp);

            output.blit(dstAddr, input, srcAddr, line);
        }
    }

    return output;
}

private function getDataForRequest(_request : PackRequest)
{
    return switch _request
    {
        case Image(path):
            final data = stb.Image.load(path.toString(), 4);

            haxe.io.Bytes.ofData(data.bytes);
        case Bytes(bytes, _, _, format):
            switch format
            {
                case RGBA:
                    bytes;
                case other:
                    throw new Exception('Bytes format $other is not yet supported');
            }
    }
}