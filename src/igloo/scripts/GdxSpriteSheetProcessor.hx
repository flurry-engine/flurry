import igloo.processors.PackedAsset;
import igloo.utils.OneOf;
import haxe.Exception;
import haxe.io.Input;
import haxe.io.Output;
import haxe.ds.ReadOnlyArray;
import hx.files.Path;
import igloo.processors.PackRequest;
import igloo.processors.AssetRequest;
import igloo.processors.AssetProcessor;
import igloo.parcels.Asset;
import igloo.parcels.ParcelContext;

using Lambda;
using igloo.utils.OutputUtils;

class GdxSpriteSheetProcessor extends AssetProcessor<Array<GdxPage>>
{
	override public function ids()
    {
		return [ 'atlas' ];
	}

	override public function pack(_ctx : ParcelContext, _asset : Asset) : AssetRequest<Array<GdxPage>>
    {
		final absPath = _ctx.assetDirectory.join(_asset.path);
        final pages   = parse(absPath);
        final images  = [];

        for (page in pages)
        {
            final bpp    = 4;
            final input  = page.image.toFile().openInput();
            final reader = new format.png.Reader(input);
            final data   = reader.read();
            final header = format.png.Tools.getHeader(data);
            final source = format.png.Tools.extract32(data);

            input.close();

            for (section in page.sections)
            {
                final buffer = haxe.io.Bytes.alloc(section.width * section.height * bpp);

                for (i in 0...section.height)
                {
                    final srcAddr = ((i + section.y) * header.width * bpp) + (section.x * bpp);
                    final dstAddr = (i * section.width * bpp);

                    buffer.blit(dstAddr, source, srcAddr, section.width * bpp);
                }

                images.push(Bytes(section.name, buffer, section.width, section.height, BGRA));
            }
        }

        return new AssetRequest(pages, Pack(images));
	}

	override public function write(_ctx : ParcelContext, _writer : Output, _data : Array<GdxPage>, _either : OneOf<PackedAsset, String>)
    {
        final frame = _either.toA();

        // Writes the resources ID.
        _writer.writePrefixedString(frame.id);
        _writer.writeInt32(frame.pageID);

        // Write UV information for the packed frame.
		_writer.writeInt32(frame.x);
		_writer.writeInt32(frame.y);
		_writer.writeInt32(frame.w);
		_writer.writeInt32(frame.h);

		_writer.writeFloat(frame.u1);
		_writer.writeFloat(frame.v1);
		_writer.writeFloat(frame.u2);
		_writer.writeFloat(frame.v2);
    }

    function parse(_path : Path)
    {
        final pages = [];
        final input = _path.toFile().openInput(false);

        input.readLine();

        while (true)
        {
            final image    = input.readLine();
            final size     = input.readLine();
            final format   = input.readLine();
            final filter   = input.readLine();
            final repeat   = input.readLine();
            final sections = [];
            final exit     = parseSections(input, sections);

            final wh   = size.split(':')[1].split(',');
            final path = _path.parent.join(image);

            pages.push(new GdxPage(
                path,
                Std.parseInt(wh[0]),
                Std.parseInt(wh[1]),
                sections
            ));

            if (exit)
            {
                break;
            }
        }

        input.close();

        return pages;
    }

    function parseSections(_input : Input, _sections : Array<GdxSection>)
    {
        var line = _input.readLine();
        while (line != '')
        {
            final name     = line;
            final rotated  = _input.readLine();
            final position = _input.readLine();
            final size     = _input.readLine();
            final original = _input.readLine();
            final offset   = _input.readLine();
            final index    = _input.readLine();

            final xy = position.split(':')[1].split(',');
            final wh = size.split(':')[1].split(',');

            final x = Std.parseInt(xy[0]);
            final y = Std.parseInt(xy[1]);
            final w = Std.parseInt(wh[0]);
            final h = Std.parseInt(wh[1]);
            
            _sections.push(new GdxSection(name, x, y, w, h));

            try
            {
                line = _input.readLine();
            }
            catch (_)
            {
                return true;
            }
        }

        return false;
    }

    function findPage(_filename : String, _pages : Array<GdxPage>)
    {
        for (page in _pages)
        {
            if (page.image.filenameStem == _filename)
            {
                return page;
            }
        }

        throw new Exception('unable to find page with name $_filename');
    }
}

class GdxPage
{
    public final image : Path;
    public final width : Int;
    public final height : Int;
    public final sections : ReadOnlyArray<GdxSection>;

    public function new(_image : Path, _width : Int, _height : Int, _sections : ReadOnlyArray<GdxSection>)
    {
        image    = _image;
        width    = _width;
        height   = _height;
        sections = _sections;
    }
}

class GdxSection
{
    public final name : String;
    public final x : Int;
    public final y : Int;
    public final width : Int;
    public final height : Int;

    public function new(_name : String, _x : Int, _y : Int, _width : Int, _height : Int)
    {
        name   = _name;
        x      = _x;
        y      = _y;
        width  = _width;
        height = _height;
    }
}