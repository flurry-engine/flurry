package parcel;

import sys.io.abstractions.IFileSystem;
import haxe.io.Path;
import haxe.io.Input;
import haxe.ds.ReadOnlyArray;

using Safety;

class GdxParser
{
    /**
     * Parse a libgdx atlas file into a read only array of pages.
     * @param _path Path to atlas file.
     * @param _fs File system to use.
     * @return ReadOnlyArray<GdxPage>
     */
    public static function parse(_path : String, _fs : IFileSystem) : ReadOnlyArray<GdxPage>
    {
        final input = _fs.file.read(_path);
        final pages = [];

        readPages(input, pages);

        input.close();

        return pages;
    }

    /**
     * Read all pages from the input.
     * @param _input Input to read from.
     * @param _output Array to add pages to.
     */
    static function readPages(_input : Input, _output : Array<GdxPage>)
    {
        _input.readLine();

        while (true)
        {
            final image    = _input.readLine();
            final size     = _input.readLine();
            final format   = _input.readLine();
            final filter   = _input.readLine();
            final repeat   = _input.readLine();
            final sections = [];
            final exit     = readSections(_input, sections);

            final wh = size.split(':')[1].split(',');

            _output.push(new GdxPage(
                new Path(image),
                Std.parseInt(wh[0]).sure(),
                Std.parseInt(wh[1]).sure(),
                sections));

            if (exit)
            {
                return;
            }
        }
    }

    /**
     * Read sections from the input. It will read sections until an empty line is encounted or the input throws an exception.
     * True is returned if the input throws an exception, as this indicates that there is no more data to process.
     * False is returned if a new line was encounted, as this indicates that all sections for this page has been read.
     * @param _input 
     * @param _sections 
     * @return If there is any more data to read.
     */
    static function readSections(_input : Input, _sections : Array<GdxSection>) : Bool
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

            final x = Std.parseInt(xy[0]).sure();
            final y = Std.parseInt(xy[1]).sure();
            final w = Std.parseInt(wh[0]).sure();
            final h = Std.parseInt(wh[1]).sure();
            
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
