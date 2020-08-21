package commands;

import Types.Project;
import haxe.io.Path;
import haxe.io.BytesInput;
import sys.io.abstractions.IFileSystem;
import sys.io.abstractions.concrete.FileSystem;
import uk.aidanlee.flurry.api.core.Result;
import uk.aidanlee.flurry.api.core.Unit;
import uk.aidanlee.flurry.api.core.Log;

using Utils;
using Safety;
using Lambda;
using StringTools;

private enum ArchiveType
{
    Zip;
    Tgz;
}

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

    public function run() : Result<Unit, String>
    {
        var res = Result.Success(Unit.value);

        Log.log('Restoring Project', Success);

        // Download all dependent haxe libraries
        switch proc.run('npx', [ 'lix', 'download' ], true)
        {
            case Failure(message): return Failure(message);
            case _: Log.log('haxe', Item);
        }

        // Download all pre-compiled tools.
        switch res = getMsdfAtlasGen()
        {
            case Failure(_): return res;
            case _: Log.log('msdf-atlas-gen', Item);
        }
        switch res = getAtlasCreator()
        {
            case Failure(_): return res;
            case _: Log.log('atlas-creator', Item);
        }
        switch res = getGlslang()
        {
            case Failure(_): return res;
            case _: Log.log('glslangValidator', Item);
        }
        switch res = getSpirvCross()
        {
            case Failure(_): return res;
            case _: Log.log('spirv-cross', Item);
        }

        return res;
    }

    function getMsdfAtlasGen() : Result<Unit, String>
    {
        final exe  = Utils.msdfAtlasExecutable();
        final tool = Path.join([ toolPath, exe ]);
        final url  = switch Utils.platform()
        {
            case Windows : 'https://github.com/flurry-engine/msdf-atlas-gen/releases/download/CI/windows-latest.tar.gz';
            case Mac     : 'https://github.com/flurry-engine/msdf-atlas-gen/releases/download/CI/macOS-latest.tar.gz';
            case Linux   : 'https://github.com/flurry-engine/msdf-atlas-gen/releases/download/CI/ubuntu-latest.tar.gz';
        }
        
        return githubDownload(url, tool, Tgz, exe);
    }

    function getAtlasCreator() : Result<Unit, String>
    {
        final exe  = Utils.atlasCreatorExecutable();
        final tool = Path.join([ toolPath, exe ]);
        final url  = switch Utils.platform()
        {
            case Windows : 'https://github.com/flurry-engine/atlas-creator/releases/download/CI/windows-latest.tar.gz';
            case Mac     : 'https://github.com/flurry-engine/atlas-creator/releases/download/CI/macOS-latest.tar.gz';
            case Linux   : 'https://github.com/flurry-engine/atlas-creator/releases/download/CI/ubuntu-latest.tar.gz';
        }
        
        return githubDownload(url, tool, Tgz, exe);
    }

    function getGlslang() : Result<Unit, String>
    {
        final exe  = Utils.glslangExecutable();
        final tool = Path.join([ toolPath, exe ]);
        final url  = switch Utils.platform()
        {
            case Windows : 'https://github.com/KhronosGroup/glslang/releases/download/SDK-candidate-26-Jul-2020/glslang-master-windows-x64-Release.zip';
            case Mac     : 'https://github.com/KhronosGroup/glslang/releases/download/SDK-candidate-26-Jul-2020/glslang-master-osx-Release.zip';
            case Linux   : 'https://github.com/KhronosGroup/glslang/releases/download/SDK-candidate-26-Jul-2020/glslang-master-linux-Release.zip';
        }

        return githubDownload(url, tool, Zip, 'bin/$exe');
    }

    function getSpirvCross() : Result<Unit, String>
    {
        final exe  = Utils.spirvCrossExecutable();
        final tool = Path.join([ toolPath, exe ]);
        final url  = switch Utils.platform()
        {
            case Windows : 'https://github.com/KhronosGroup/SPIRV-Cross/releases/download/2020-06-29/spirv-cross-vs2017-64bit-b1082c10af.tar.gz';
            case Mac     : 'https://github.com/KhronosGroup/SPIRV-Cross/releases/download/2020-06-29/spirv-cross-clang-macos-64bit-b1082c10af.tar.gz';
            case Linux   : 'https://github.com/KhronosGroup/SPIRV-Cross/releases/download/2020-06-29/spirv-cross-gcc-trusty-64bit-b1082c10af.tar.gz';
        }

        return githubDownload(url, tool, Tgz, 'bin/$exe');
    }

    function githubDownload(_url : String, _tool : String, _archive : ArchiveType, _target : String) : Result<Unit, String>
    {
        if (fs.file.exists(_tool))
        {
            return Success(Unit.value);
        }

        return switch net.download(_url, proc)
        {
            case Success(data):
                final input   = new BytesInput(data);
                final entries = switch _archive {
                    case Zip : new format.zip.Reader(input).read();
                    case Tgz : cast new format.tgz.Reader(input).read();
                }

                entries
                    .find(e -> e.fileName == _target)
                    .run(e -> {
                        if (e.compressed)
                        {
                            #if neko format.zip.Tools.uncompress(e); #end
                        }

                        fs.file.writeBytes(_tool, e.data.sure());

                        if (Utils.platform() != Windows)
                        {
                            switch proc.run('chmod', [ 'a+x', _tool ], true)
                            {
                                case Failure(message): Failure(message);
                                case _:
                            }
                        }
                    });

                Success(Unit.value);
            case Failure(message): Failure(message);
        }
    }
}