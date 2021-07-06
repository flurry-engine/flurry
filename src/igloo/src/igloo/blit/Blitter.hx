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
        case Image(_, path):
            final data = stb.Image.load(path.toString(), 4);

            haxe.io.Bytes.ofData(data.bytes);
        case Bytes(_, bytes, width, height, format):
            switch format
            {
                case RGBA:
                    bytes;
                case BGRA:
                    // Swizzle to RGBA
                    for (row in 0...height)
                    {
                        for (col in 0...width)
                        {
                            final base = row + col * 4;
                            final b    = bytes.get(base + 0);
                            final g    = bytes.get(base + 1);
                            final r    = bytes.get(base + 2);
                            final a    = bytes.get(base + 3);

                            bytes.set(base + 0, r);
                            bytes.set(base + 0, g);
                            bytes.set(base + 0, b);
                            bytes.set(base + 0, a);
                        }
                    }

                    bytes;
                case ARGB:
                        // Swizzle to RGBA
                        for (row in 0...height)
                        {
                            for (col in 0...width)
                            {
                                final base = row + col * 4;
                                final a    = bytes.get(base + 0);
                                final r    = bytes.get(base + 1);
                                final g    = bytes.get(base + 2);
                                final b    = bytes.get(base + 3);
    
                                bytes.set(base + 0, r);
                                bytes.set(base + 0, g);
                                bytes.set(base + 0, b);
                                bytes.set(base + 0, a);
                            }
                        }
    
                        bytes;
                case other:
                    throw new Exception('Bytes format $other is not yet supported');
            }
    }
}