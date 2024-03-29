package igloo.processors;

import haxe.io.Eof;
import sys.io.Process;
import cpp.cppia.Module;
import haxe.Exception;
import haxe.crypto.Md5;
import hx.files.Path;
import igloo.logger.Log;
import igloo.logger.LogConfig;
import igloo.macros.BuildPaths;

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
     * @param _log Log object which will schedule all log requests onto a dedicated thread.
     * @param _path Absolute path to the scripts location.
     * @param _flags Flags to be provided to haxe when compiling the script.
     */
    public function load(_log, _path : Path, _flags : String)
    {
        final logger =
            new LogConfig()
                .writeTo(_log)
                .enrichWith('processor', _path.filenameStem)
                .create();
        final precompiledScript  = directory.join('${ _path.filenameStem }.cppia');
        final scriptHashPath     = directory.join('${ _path.filenameStem }.cppia.hash');
        final sourceLastModified = _path.getModificationTime();
        final sourceFlagsHash    = Md5.encode(_flags);

        logger.info('Loading script $_path');

        final wasRecompiled = if (precompiledScript.exists() && scriptHashPath.exists())
        {
            logger.info('Cached script found');

            // There is a precompiled script and hash file, if its no longer valid recompile from source.
            final input              = scriptHashPath.toFile().openInput(false);
            final cachedLastModified = Std.parseFloat(input.readLine());
            final cachedFlagsHash    = input.readLine();
            input.close();

            if (sourceLastModified > cachedLastModified || cachedFlagsHash != sourceFlagsHash)
            {
                logger.info('Cached script is invalid');

                // Details about the processor script have changed since the cache, need to recompile.
                compileScript(logger, _path, precompiledScript, _flags);
                outputCacheHash(scriptHashPath, sourceLastModified, sourceFlagsHash);

                true;
            }
            else
            {
                false;
            }
        }
        else
        {
            // There is no cached script, so compile the source and cache it.
            compileScript(logger, _path, precompiledScript, _flags);
            outputCacheHash(scriptHashPath, sourceLastModified, sourceFlagsHash);

            true;
        }

        return new CacheLoadResult(_path, loadCompiledScript(precompiledScript), wasRecompiled);
    }

    /**
     * Compiles the provided haxe file as a cppia script.
     * If compilation is unsuccessful the stderr of haxe is piped to this programs stdout and exits with a non zero code.
     * @param _logger
     * @param _path Absolute path to the haxe file to compile.
     * @param _output Absolute path of the generated cppia file.
     * @param _flags Haxe cli command line flags to provide.
     */
    function compileScript(_logger : Log, _path : Path, _output : Path, _flags : String)
    {
        final proc = new Process('npx haxe -p $iglooCodePath -p ${ _path.parent } -L haxe-files -D dll_import=$iglooDllExportFile ${ _path.filenameStem } $_flags --cppia $_output');
        final exit = proc.exitCode();
        
        if (exit == 0)
        {
            final stdout = proc.stdout.readAll().toString();
            final stderr = proc.stderr.readAll().toString();

            _logger.info('Compiled ${ script }', _path);
            _logger.info('$stdout');
            _logger.warning('$stderr');

            proc.close();
        }
        else
        {
            final stdout = proc.stdout.readAll().toString();
            final stderr = proc.stderr.readAll().toString();

            proc.close();

            throw new Exception(stdout, new Exception(stderr));
        }
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
     * Load a `AssetProcessor<Any>` from the provided cppia file.
     * The filename of the path is used for the class name.
     * @param _path Absolute path of the cppia script to load.
     */
    function loadCompiledScript(_path : Path) : AssetProcessor<Any>
    {
        final module   = Module.fromData(_path.toFile().readAsBytes().getData());
        final objClass = module.resolveClass(_path.filenameStem);

        // Boot ensure any static variables have default values applied.
        module.boot();

        return Type.createInstance(objClass, []);
    }
}

class CacheLoadResult
{
    public final source : Path;

    public final processor : AssetProcessor<Any>;

    public final wasRecompiled : Bool;

    public function new(_source, _processor, _wasRecompiled)
    {
        source        = _source;
        processor     = _processor;
        wasRecompiled = _wasRecompiled;
    }
}