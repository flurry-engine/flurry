package commands;

import Types.Unit;
import Types.Result;
import Types.Project;
import haxe.io.Path;
import haxe.io.BytesInput;
import format.tgz.Reader;
import sys.io.abstractions.IFileSystem;
import sys.io.abstractions.concrete.FileSystem;

using Utils;
using Safety;

class Restore
{
    final fs : IFileSystem;

    final net : Net;

    final proc : Proc;

    final project : Project;

    final toolPath : String;

    public function new(_project : Project, _fs : IFileSystem = null, _net : Net = null, _proc : Proc = null)
    {
        fs       = _fs.or(new FileSystem());
        net      = _net.or(new Net());
        proc     = _proc.or(new Proc());
        project  = _project;
        toolPath = _project.toolPath();

        fs.directory.create(toolPath);
    }

    public function run() : Result<Unit>
    {
        var res = Success(Unit.value);

        // Download all dependent haxe libraries
        switch proc.run('npx', [ 'lix', 'download' ])
        {
            case Failure(message): return Failure(message);
            case _:
        }

        // Download all pre-compiled tools.
        switch res = getMsdfAtlasGen()
        {
            case Failure(_): return res;
            case _:
        }
        switch res = getLibgdxTexturePacker()
        {
            case Failure(_): return res;
            case _:
        }
        switch res = getGlslang()
        {
            case Failure(_): return res;
            case _:
        }

        return res;
    }

    function getMsdfAtlasGen() : Result<Unit>
    {
        final tool = Path.join([ toolPath, Utils.msdfAtlasExecutable() ]);
        final url  = switch Utils.platform()
        {
            case Windows : 'https://github.com/flurry-engine/msdf-atlas-gen/releases/download/CI/windows-latest.tar.gz';
            case Mac     : 'https://github.com/flurry-engine/msdf-atlas-gen/releases/download/CI/macOS-latest.tar.gz';
            case Linux   : 'https://github.com/flurry-engine/msdf-atlas-gen/releases/download/CI/ubuntu-latest.tar.gz';
        }

        if (fs.file.exists(tool))
        {
            return Success(Unit.value);
        }
        
        return switch net.download(url, proc)
        {
            case Success(data):
                final input = new BytesInput(data);
                final entry = new Reader(input).read().first().sure();

                fs.file.writeBytes(tool, entry.data.sure());

                if (Utils.platform() != Windows)
                {
                    switch proc.run('chmod', [ 'a+x', tool ])
                    {
                        case Failure(message): return Failure(message);
                        case _:
                    }
                }

                input.close();

                Success(Unit.value);
            case Failure(message): Failure(message);
        }
    }

    function getLibgdxTexturePacker() : Result<Unit>
    {
        final tool = Path.join([ toolPath, 'runnable-texturepacker.jar' ]);

        if (fs.file.exists(tool))
        {
            return Success(Unit.value);
        }

        return switch net.download('https://libgdx.badlogicgames.com/nightlies/runnables/runnable-texturepacker.jar', proc)
        {
            case Success(data): {
                fs.file.writeBytes(tool, data);

                Success(Unit.value);
            }
            case Failure(message): Failure(message);
        }
    }

    function getGlslang() : Result<Unit>
    {
        return Success(Unit.value);
    }
}