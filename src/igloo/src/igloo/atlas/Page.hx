package igloo.atlas;

import haxe.Exception;
import igloo.processors.PackRequest;
import igloo.processors.PackedAsset;
import binpacking.MaxRectsPacker;

class Page
{
    public final name : String;

    public final xPad : Int;

    public final yPad : Int;

    public final width : Int;

    public final height : Int;

    public final frames : Array<Frame>;

    final packer : MaxRectsPacker;

    public function new(_name, _xPad, _yPad, _width, _height)
    {
        name   = _name;
        xPad   = _xPad;
        yPad   = _yPad;
        width  = _width;
        height = _height;
        frames = [];
        packer = new MaxRectsPacker(_width, _height, false);
    }

    public function pack(_request, _width, _height)
    {
        final paddedWidth  = _width + xPad;
        final paddedHeight = _height + yPad;

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
            final u1    = xSrc / packer.binWidth;
            final v1    = ySrc / packer.binHeight;
            final u2    = (xSrc + _width) / packer.binWidth;
            final v2    = (xSrc + _height) / packer.binHeight;

            frames.push(frame);

            new PackedAsset(name, width, height, _request, xSrc, ySrc, _width, _height, u1, v1, u2, v2);
        }
    }
}