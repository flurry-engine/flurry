package igloo.processors;

import igloo.macros.BuildPaths;
import sys.io.Process;
import cpp.cppia.Module;
import haxe.crypto.Md5;
import hx.files.Path;

/**
 * The script cache will attempt to load existing pre-compiled cppia scripts if they're still valid.
 * If they are no longer valid (flags changed or the source modification date is newer than the pre-compiled) or
 * don't exist it will compile and then cache the result.
 */
class Cache
{
    /**
     * Folder where cached scripts will be stored.
     */
    final directory : Path;

    /**
     * Path to the igloo src path.
     */
    final iglooCodePath : Path;

    /**
     * Path to the file which contains a list of all classes compiled into the igloo host program.
     */
    final iglooDllExportFile : Path;

    public function new(_directory)
    {
        directory          = _directory;
        iglooCodePath      = getIglooCodePath();
        iglooDllExportFile = getIglooDllExportFile();
    }

    /**
     * Return a `IAssetProcessor<Any>` object from a script file.
     * The script must contain a class with the same name as the file which implements `IAssetProcessor<T>`.
     * @param _path Absolute path to the scripts location.
     * @param _flags Flags to be provided to haxe when compiling the script.
     */
    public function load(_path : Path, _flags : String)
    {
        Sys.println('loading $_path');

        final precompiledScript  = directory.join('${ _path.filenameStem }.cppia');
        final scriptHashPath     = directory.join('${ _path.filenameStem }.cppia.hash');
        final sourceLastModified = _path.getModificationTime();
        final sourceFlagsHash    = Md5.encode(_flags);

        if (precompiledScript.exists() && scriptHashPath.exists())
        {
            Sys.println('Cached script found');

            // There is a precompiled script and hash file, if its no longer valid recompile from source.
            final input              = scriptHashPath.toFile().openInput(false);
            final cachedLastModified = Std.parseFloat(input.readLine());
            final cachedFlagsHash    = input.readLine();
            input.close();

            if (sourceLastModified > cachedLastModified || cachedFlagsHash != sourceFlagsHash)
            {
                Sys.println('Cached script invalidated');

                // Details about the processor script have changed since the cache, need to recompile.
                compileScript(_path, precompiledScript, _flags);
                outputCacheHash(scriptHashPath, sourceLastModified, sourceFlagsHash);
            }
        }
        else
        {
            // cppia compilation will fail if the output directory doesn't exist, ensure it does.
            precompiledScript.parent.toDir().create();

            // There is no cached script, so compile the source and cache it.
            compileScript(_path, precompiledScript, _flags);
            outputCacheHash(scriptHashPath, sourceLastModified, sourceFlagsHash);
        }

        return loadCompiledScript(precompiledScript);
    }

    /**
     * Compiles the provided haxe file as a cppia script.
     * If compilation is unsuccessful the stderr of haxe is piped to this programs stdout and exits with a non zero code.
     * @param _path Absolute path to the haxe file to compile.
     * @param _output Absolute path of the generated cppia file.
     * @param _flags Haxe cli command line flags to provide.
     */
    function compileScript(_path : Path, _output : Path, _flags : String)
    {
        final proc = new Process('npx haxe -p $iglooCodePath -p ${ _path.parent } -L safety -L haxe-files -D dll_import=$iglooDllExportFile ${ _path.filenameStem } $_flags --cppia $_output');
        final exit = proc.exitCode();
        
        if (exit == 0)
        {
            Sys.println('Compiled $_path');
            Sys.stdout().write(proc.stdout.readAll());
        }
        else
        {
            Sys.println('Failed to compile $_path');
            Sys.stderr().write(proc.stderr.readAll());
            Sys.exit(1);
        }

        proc.close();
    }

    /**
     * Write the last modified timestamp of a scripts source hx file and a md5 hash of the flags used to a file.
     * @param _path Absolute path to the file to store the hash data.
     * @param _lastModified Last modified timestamp of the source haxe file.
     * @param _flagsHash Md5 hash of the flags used to compile the script.
     */
    function outputCacheHash(_path : Path, _lastModified : Float, _flagsHash : String)
    {
        final output = _path.toFile().openOutput(REPLACE, false);
        output.writeString('$_lastModified\n');
        output.writeString('$_flagsHash\n');
        output.close();
    }

    /**
     * Load a `IAssetProcessor<Any>` from the provided cppia file.
     * The filename of the path is used for the class name.
     * @param _path Absolute path of the cppia script to load.
     */
    function loadCompiledScript(_path : Path) : IAssetProcessor<Any>
    {
        final module   = Module.fromData(_path.toFile().readAsBytes().getData());
        final objClass = module.resolveClass(_path.filenameStem);

        return Type.createInstance(objClass, []);
    }
}