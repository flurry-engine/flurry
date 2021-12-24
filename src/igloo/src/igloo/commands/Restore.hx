package igloo.commands;

import sys.io.Process;
import json2object.ErrorUtils;
import igloo.tools.ToolsFetcher;
import haxe.Exception;
import hx.files.Path;
import igloo.logger.LogLevel;
import igloo.logger.LogConfig;
import json2object.JsonParser;
import igloo.logger.Log;
import igloo.project.Project;

class Restore
{
    final root : Log;
    
    final projectParser : JsonParser<Project>;

    /**
     * Path to the json build file.
     * default : build.json
     */
    @:flag('file')
    @:alias('f')
    public var buildFile = 'build.json';

    @:flag('log')
    @:alias('l')
    public var log : LogLevel = 'INF';

    public function new(_log)
    {
        root          = _log;
        projectParser = new JsonParser<Project>();
    }

    @:command
    public function help()
    {
        //
    }

    @:defaultCommand
    public function execute()
    {
        final logger =
            new LogConfig()
                .setMinimumLevel(log)
                .writeTo(root)
                .enrichWith('command', 'restore')
                .create();

        logger.info('Igloo v0.1');

        final projectPath = getBuildFilePath();
        final project     = projectParser.fromJson(projectPath.toFile().readAsString());
        final toolsLog    =
            new LogConfig()
                .setMinimumLevel(log)
                .writeTo(logger)
                .enrichWith('stage', 'tools')
                .create();

        if (projectParser.errors.length > 0)
        {
            throw new Exception('Failed to parse project file ${ projectPath.toString() }', new Exception(ErrorUtils.convertErrorArray(projectParser.errors)));
        }

        final outputDir  = projectPath.parent.join(project.app.output);
        final tools      = fetchTools(outputDir, toolsLog);

        toolsLog.debug('$mdsfAtlasPath', tools.msdfAtlasGen);
        toolsLog.debug('$glslangPath', tools.glslang);
        toolsLog.debug('$spirvcrossPath', tools.spirvcross);

        final lixProc = new Process('npx lix download');
        final lixLog  =
            new LogConfig()
                .setMinimumLevel(log)
                .writeTo(logger)
                .enrichWith('stage', 'tools')
                .create();

        var code : Null<Int> = null;
        while (null == (code = lixProc.exitCode(false)))
        {
            try
            {
                lixLog.info('${ stdout }', lixProc.stdout.readLine());
            }
            catch (e)
            {
                // potential EoF exception from stdout
            }
        }

        if (code == 0)
        {
            lixLog.info('lix restore succeeded');
        }
        else
        {
            final stderr = try lixProc.stderr.readAll().toString() catch (_) '';

            lixLog.error('lix restore failed $stderr');
        }
    }

    function getBuildFilePath()
    {
        final path = Path.of(buildFile);

        return if (path.isAbsolute)
        {
            path;
        }
        else
        {
            Path.of(path.getAbsolutePath());
        }
    }
}