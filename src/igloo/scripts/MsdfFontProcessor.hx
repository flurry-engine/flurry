import igloo.processors.PackRequest;
import haxe.Json;
import haxe.Exception;
import haxe.io.Output;
import igloo.parcels.Asset;
import igloo.parcels.ParcelContext;
import igloo.processors.AssetRequest;
import igloo.processors.ProcessedAsset;
import igloo.processors.IAssetProcessor;

using igloo.utils.OutputUtils;

class MsdfFontProcessor implements IAssetProcessor<FontDefinition>
{
	public function ids()
    {
		return [ 'ttf', 'otf' ];
	}

	public function pack(_ctx:ParcelContext, _asset:Asset)
    {
        final absPath  = _ctx.assetDirectory.join(_asset.path);
        final imageOut = _ctx.tempDirectory.join(_asset.id + '.png');
        final jsonOut  = _ctx.tempDirectory.join(_asset.id + '.json');
        final toolArgs = [
            '-font', absPath.toString(),
            '-type', 'msdf',
            '-format', 'png',
            '-imageout', imageOut.toString(),
            '-json', jsonOut.toString(),
            '-size', '48'
        ];

        if (Sys.command(_ctx.tools.msdfAtlasGen.toString(), toolArgs) != 0)
        {
            throw new Exception('Failed to build msdf font');
        }

        final font = (Json.parse(jsonOut.toFile().readAsString()) : FontDefinition);

        if (font == null)
        {
            throw new Exception('Unable to parse font json');
        }

        return new AssetRequest(_asset.id, font, Pack(PackRequest.Image(imageOut)));
	}

	public function write(_ctx:ParcelContext, _writer:Output, _asset:ProcessedAsset<FontDefinition>)
    {
        switch _asset.response
        {
            case Packed(packed):
                final frame = packed.toAsset();

                _writer.writePrefixedString(_asset.id);

                _writer.writeFloat(_asset.data.metrics.lineHeight);
                _writer.writeInt32(_asset.data.glyphs.length);

                for (char in _asset.data.glyphs)
                {
                    if (char.atlasBounds != null && char.planeBounds != null)
                    {
                        // glyph atlas coords are packed bottom left origin so we transform to top left origin
                        final ax = char.atlasBounds.left;
                        final ay = (_asset.data.atlas.height - char.atlasBounds.top);
                        final aw = char.atlasBounds.right - char.atlasBounds.left;
                        final ah = (_asset.data.atlas.height - char.atlasBounds.bottom) - (_asset.data.atlas.height - char.atlasBounds.top);
    
                        final pLeft   = char.planeBounds.left;
                        final pTop    = 1 - char.planeBounds.top;
                        final pRight  = char.planeBounds.right;
                        final pBottom = 1 - char.planeBounds.bottom;

                        _writer.writeFloat(pLeft);
                        _writer.writeFloat(pTop);
                        _writer.writeFloat(pRight);
                        _writer.writeFloat(pBottom);
                        _writer.writeFloat(char.advance);
                        _writer.writeFloat((frame.x + ax) / frame.pageWidth);
                        _writer.writeFloat((frame.y + ay) / frame.pageHeight);
                        _writer.writeFloat((frame.x + ax + aw) / frame.pageWidth);
                        _writer.writeFloat((frame.y + ay + ah) / frame.pageHeight);

                    }
                    else
                    {
                        _writer.writeFloat(0);
                        _writer.writeFloat(0);
                        _writer.writeFloat(0);
                        _writer.writeFloat(0);
                        _writer.writeFloat(0);
                        _writer.writeFloat(0);
                        _writer.writeFloat(0);
                        _writer.writeFloat(0);
                        _writer.writeFloat(0);
                    }
                }
            case NotPacked:
                //
        }
    }
}

typedef FontDefinition = {
    public var atlas : FontAtlas;

    public var metrics : FontMetrics;

    public var glyphs : Array<FontGlyph>;

    public var kerning : Array<Dynamic>;
}

typedef FontAtlas = {
    public var type : String;

    public var distanceRange : Int;

    public var size : Int;

    public var width : Int;

    public var height : Int;

    public var yOrigin : String;
}

typedef FontMetrics = {
    public var lineHeight : Float;

    public var ascender : Float;

    public var descender : Float;

    public var underlineY : Float;

    public var underlineThickness : Float;
}

typedef FontGlyph = {
    public var unicode : Int;

    public var advance : Float;

    public var ?planeBounds : FontBound;

    public var ?atlasBounds : FontBound;
}

typedef FontBound = {
    public var left : Float;

    public var bottom : Float;

    public var right : Float;

    public var top : Float;
}