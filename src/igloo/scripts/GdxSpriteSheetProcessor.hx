import haxe.Exception;
import haxe.io.Input;
import haxe.io.Output;
import haxe.ds.ReadOnlyArray;
import hx.files.Path;
import igloo.processors.PackRequest;
import igloo.processors.AssetRequest;
import igloo.processors.ProcessedAsset;
import igloo.processors.IAssetProcessor;
import igloo.parcels.Asset;
import igloo.parcels.ParcelContext;

using Lambda;
using igloo.utils.OutputUtils;

class GdxSpriteSheetProcessor implements IAssetProcessor<Array<GdxPage>>
{
    public function new()
    {
        //
    }

	public function ids()
    {
		return [ 'atlas' ];
	}

	public function pack(_ctx : ParcelContext, _asset : Asset) : AssetRequest<Array<GdxPage>>
    {
		final absPath = _ctx.assetDirectory.join(_asset.path);
        final pages   = parse(absPath);
        final images  = [ for (page in pages) Image(page.image) ];

        return new AssetRequest(pages, Pack(images));
	}

	public function write(_ctx : ParcelContext, _writer : Output, _asset : ProcessedAsset<Array<GdxPage>>)
    {
        switch _asset.response
        {
            case Packed(packed):
                final frames = packed.toAssets();

                // Writes the resources ID.
				_writer.writePrefixedString(_asset.id);

                // write the number of assets (gdx atlas images) packed.
                _writer.writeInt32(frames.length);

                for (frame in frames)
                {
                    // Attempt to find the original gdx page by looking at the path of the original request.
                    final gdxPage = switch frame.request
                    {
                        case Image(path): findPage(path.filenameStem, _asset.data);
                        case _: throw new Exception('Gdx pages should be images');
                    }

                    // Write all frames in the page.
                    _writer.writeInt32(gdxPage.sections.length);

                    for (section in gdxPage.sections)
                    {
                        _writer.writePrefixedString(section.name);

                        // Write the pixel position within the texture.
                        _writer.writeInt32(section.x + frame.x);
                        _writer.writeInt32(section.y + frame.y);
                        _writer.writeInt32(section.width);
                        _writer.writeInt32(section.height);

                        // Write the UV coordinates.
                        final u1 = (frame.x + section.x) / frame.pageWidth;
                        final v1 = (frame.y + section.y) / frame.pageHeight;
                        final u2 = (frame.x + section.x + section.width) / frame.pageWidth;
                        final v2 = (frame.y + section.y + section.height) / frame.pageHeight;

                        _writer.writeFloat(u1);
                        _writer.writeFloat(v1);
                        _writer.writeFloat(u2);
                        _writer.writeFloat(v2);
                    }
                }
            case NotPacked:
                throw new Exception('Images can only be packed');
        }
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