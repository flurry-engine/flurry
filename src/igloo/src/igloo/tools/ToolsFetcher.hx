package igloo.tools;

import haxe.zip.Uncompress;
import haxe.zip.Entry;
import haxe.io.BytesInput;
import haxe.Exception;
import haxe.Http;
import hx.files.Path;
import igloo.macros.ToolPaths;
import igloo.macros.Platform;
import igloo.macros.Urls;

using Safety;
using Lambda;

/**
 * Returns a tool object with the path to all the 3rd party tools used.
 * If any tool is not found in the projects `tools/platform` folder it will be downloaded.
 * @param _output Output path of the project.
 */
function fetchTools(_output : Path)
{
    final toolsDir     = _output.joinAll([ 'tools', getHostPlatformName() ]);
    final msdfAtlasGen = getMsdfAtlasGenPath(toolsDir);
    final glslang      = getGlslangPath(toolsDir);
    final spirvcross   = getSprivCrossPath(toolsDir);

    // Ensure the directory exists before we copy any files else exceptions will occur.
    toolsDir.toDir().create();
    
    if (!msdfAtlasGen.exists())
    {
        restore(msdfAtlasGen, getMsdfAtlasGenUrl(), Tgz, getMsdfAtlasGenFileEntry());
    }
    if (!glslang.exists())
    {
        restore(glslang, getGlslangUrl(), Zip, getGlslangFileEntry());
    }
    if (!spirvcross.exists())
    {
        restore(spirvcross, getSpirvCrossUrl(), Tgz, getSpirvCrossFileEntry());
    }

    return new Tools(msdfAtlasGen, glslang, spirvcross);
}

/**
 * Download and extract an executable from a remote URL.
 * @param _destination Path to place the final extracted executables bytes in.
 * @param _url URL to download.
 * @param _archive The type of archive contained at the URL.
 * @param _target name of the file entry within the archive to extract to the destination.
 */
private function restore(_destination : Path, _url : String, _archive : ArchiveType, _target : String)
{
    final source  = download(_url);
    final input   = new BytesInput(source);
    final entries = switch _archive {
        case Zip: new format.zip.Reader(input).read();
        case Tgz: cast new format.tgz.Reader(input).read();
    }

    entries
        .find(e -> e.fileName == _target)
        .run(e -> {
            Sys.println('Extracting $_target');

            if (e.compressed)
            {
                uncompress(e);
            }

            _destination
                .toFile()
                .writeBytes(e.data);

            if (Sys.systemName() != 'Windows')
            {
                if (Sys.command('chmod', [ 'a+x', _destination.toString() ]) != 0)
                {
                    throw new Exception('Failed to set the executable bit of $_destination');
                }
            }
        });
}

/**
 * Given a URL it will download and return the file as a bytes object.
 * It will follow github url redirects as needed.
 * @param _url Url to download.
 */
private function download(_url : String)
{
    Sys.println('Downloading ${ _url }');

    var code  = 0;
    var bytes = null;

    final request = new Http(_url);
    request.onStatus = v -> code = v;
    request.onError  = s -> throw new Exception(s);
    request.onBytes  = data -> {
        switch code
        {
            case 200:
                bytes = data;
            case 302:
                // Github returns redirects as <html><body><a href="redirect url"></body></html>
                final access = new haxe.xml.Access(Xml.parse(data.toString()).firstElement());
                final redir  = access.node.body.node.a.att.href;

                bytes = download(redir);
            case other:
                throw new Exception('Unexpected http status $other');
        }
    }
    request.request();

    return bytes;
}

/**
 * Slighly modified uncompress function from the format lib.
 * For some reason formats zip file entry uncompress is only implemented on neko.
 * @param _entry File entry to decompress.
 */
private function uncompress(_entry : Entry)
{
    if (!_entry.compressed)
    {
        return;
    }
    
    var c = new haxe.zip.Uncompress(-15);
    var s = haxe.io.Bytes.alloc(_entry.fileSize);
    var r = c.execute(_entry.data, 0, s, 0);
    c.close();

    if (!r.done || r.read != _entry.data.length || r.write != _entry.fileSize)
    {
        throw new Exception('Invalid compressed data for ${ _entry.fileName }');
    }

    _entry.compressed = false;
    _entry.dataSize   = _entry.fileSize;
    _entry.data = s;
}