import sys.io.abstractions.IFileSystem;
import haxe.io.Path;
import Types.Project;
import Types.Platform;

using StringTools;

class Utils
{
    public static function platform() : Platform
        return Sys.systemName().toLowerCase();

    public static function toolPath(_project : Project)
        return Path.join([ _project.app.output, 'tools', platform() ]);

    public static function releasePath(_project : Project)
        return Path.join([ _project.app.output, platform() ]);

    public static function buildPath(_project : Project)
        return releasePath(_project) + '.build';

    public static function baseTempDir(_project : Project)
        return Path.join([ _project.app.output, 'temp' ]);

    public static function tempFonts(_project : Project)
        return Path.join([ baseTempDir(_project), 'fonts' ]);

    public static function tempSprites(_project : Project)
        return Path.join([ baseTempDir(_project), 'sprites' ]);

    public static function tempAssets(_project : Project)
        return Path.join([ baseTempDir(_project), 'assets' ]);

    public static function tempParcels(_project : Project)
        return Path.join([ baseTempDir(_project), 'parcels' ]);

    public static function executable(_project : Project)
        return switch platform()
        {
            case Windows: Path.join([ releasePath(_project), '${ _project.app.name }.exe' ]);
            case Mac, Linux: Path.join([ releasePath(_project), _project.app.name ]);
        }

    public static function msdfAtlasExecutable()
        return switch platform()
        {
            case Windows : 'msdf-atlas-gen.exe';
            case _ : 'msdf-atlas-gen';
        }

    public static function atlasCreatorExecutable()
        return switch platform()
        {
            case Windows : 'atlas-creator.exe';
            case _ : 'atlas-creator';
        }

    public static function glslangExecutable()
        return switch platform()
        {
            case Windows : 'glslangValidator.exe';
            case _ : 'glslangValidator';
        }

    public static function asepriteExecutable()
        return switch platform()
        {
            case Windows : Path.join([ 'C:', 'Program Files', 'Aseprite', 'aseprite.exe' ]);
            case _ : 'aseprite';
        }

    /**
     * Returns the substring before the first occurance of the provided string.
     * If the source string does not contain the provided delimeter the entire source string is returned.
     * @param _str source string.
     * @param _search delimeter
     */
    public static function substringBefore(_str : String, _search : String)
    {
        final idx = _str.indexOf(_search);

        return if (idx == -1) _str else _str.substring(0, idx);
    }

    /**
     * Returns a substring from the first position until the last occurence of the provided character.
     * If the string does not contain the provided character the entire string is returned.
     * @param _str source string.
     * @param _search character code to search for.
     */
    public static function substringBeforeLast(_str : String, _search : Int)
    {
        final length = _str.length;
        var idx = length - 1;

        while (idx >= 0)
        {
            if (_str.charCodeAt(idx) == _search)
            {
                break;
            }

            --idx;
        }

        return if (idx <= 0) _str else _str.substr(0, idx);
    }
    
    /**
     * Recursively search the provided directory returning an array of all found files.
     * @param _fs File system interface.
     * @param _dir Directory to search.
     * @param _collection array to place files into.
     * @return All files found so far.
     */
    public static function walk(_fs : IFileSystem, _dir : String, _collection : Array<String>) : Array<String>
    {
        for (item in _fs.directory.read(_dir))
        {
            final path = Path.join([ _dir, item ]);

            if (_fs.directory.isDirectory(path))
            {
                walk(_fs, path, _collection);
            }
            else
            {
                _collection.push(path);
            }
        }

        return _collection;
    }
}
