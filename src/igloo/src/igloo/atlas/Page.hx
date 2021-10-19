package igloo.atlas;

import haxe.Exception;
import igloo.processors.PackedResource;
import binpacking.MaxRectsPacker;

class Page
{
    public final id : Int;

    public final xPad : Int;

    public final yPad : Int;

    public final width : Int;

    public final height : Int;

    public final frames : Array<Frame>;

    final packer : MaxRectsPacker;

    public function new(_id, _xPad, _yPad, _width, _height)
    {
        id     = _id;
        xPad   = _xPad;
        yPad   = _yPad;
        width  = _width;
        height = _height;
        frames = [];
        packer = new MaxRectsPacker(_width, _height, false);
    }

    public function pack(_request, _width, _height)
    {
        final paddedWidth  = _width + (xPad * 2);
        final paddedHeight = _height + (yPad * 2);

        if (paddedWidth > packer.binWidth || paddedHeight > packer.binHeight)
        {
            throw new Exception('Pack request exceeds maximum page size');
        }

        final rect = packer.insert(paddedWidth, paddedHeight, BestShortSideFit);
        return if (rect == null)
        {
            null;
        }
        else
        {
            final frame = new Frame(rect, _request);
            final xSrc  = Std.int(rect.x + xPad);
            final ySrc  = Std.int(rect.y + yPad);
            final u1    = xSrc / width;
            final v1    = ySrc / height;
            final u2    = (xSrc + _width) / width;
            final v2    = (ySrc + _height) / height;

            frames.push(frame);

            new PackedResource(id, width, height, xSrc, ySrc, _width, _height, u1, v1, u2, v2);
        }
    }
}