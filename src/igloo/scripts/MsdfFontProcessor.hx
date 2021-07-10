import igloo.processors.PackedAsset;
import igloo.utils.OneOf;
import igloo.processors.PackRequest;
import haxe.Json;
import haxe.Exception;
import haxe.io.Output;
import igloo.parcels.Asset;
import igloo.parcels.ParcelContext;
import igloo.processors.AssetRequest;
import igloo.processors.ProcessedAsset;
import igloo.processors.AssetProcessor;

using igloo.utils.OutputUtils;

class MsdfFontProcessor extends AssetProcessor<FontDefinition>
{
	override public function ids()
    {
		return [ 'ttf', 'otf' ];
	}

	override public function pack(_ctx:ParcelContext, _asset:Asset)
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

        return new AssetRequest(font, Pack(Image(_asset.id, imageOut)));
	}

	override public function write(_ctx:ParcelContext, _writer:Output, _data : FontDefinition, _either : OneOf<PackedAsset, String>)
    {
        final frame = _either.toA();

        _writer.writeInt32(frame.pageID);
        _writer.writeFloat(_data.metrics.lineHeight);
        _writer.writeInt32(_data.glyphs.length);

        for (char in _data.glyphs)
        {
            _writer.writeInt32(char.unicode);
            _writer.writeFloat(char.advance);

            if (char.atlasBounds != null && char.planeBounds != null)
            {
                // glyph atlas coords are packed bottom left origin so we transform to top left origin
                final ax = char.atlasBounds.left;
                final ay = (_data.atlas.height - char.atlasBounds.top);
                final aw = char.atlasBounds.right - char.atlasBounds.left;
                final ah = (_data.atlas.height - char.atlasBounds.bottom) - (_data.atlas.height - char.atlasBounds.top);

                final pLeft   = char.planeBounds.left;
                final pTop    = 1 - char.planeBounds.top;
                final pRight  = char.planeBounds.right;
                final pBottom = 1 - char.planeBounds.bottom;

                _writer.writeFloat(pLeft);
                _writer.writeFloat(pTop);
                _writer.writeFloat(pRight);
                _writer.writeFloat(pBottom);

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
            }
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