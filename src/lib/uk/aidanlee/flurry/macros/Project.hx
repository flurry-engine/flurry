package uk.aidanlee.flurry.macros;

import haxe.macro.Context;
import sys.FileSystem;
import sys.io.File;
import haxe.Json;

using Safety;

class Project
{
    public static macro function name() : ExprOf<String>
    {
        if (!Context.defined('flurry-build-file'))
        {
            Context.warning('flurry-build-file define does not exist', Context.currentPos());

            return macro $v{ 'unknown_project' };
        }

        final buildFile = Context.definedValue('flurry-build-file');

        if (!FileSystem.exists(buildFile))
        {
            Context.warning('Build file $buildFile does not exist', Context.currentPos());

            return macro $v{ 'unknown_project' };
        }

        final json = Json.parse(File.getContent(buildFile));

        if (json != null && json.app != null && json.app.name != null)
        {
            return macro $v{ json.app.name }
        }

        Context.warning('Project json from $buildFile does not contain the app name', Context.currentPos());

        return macro $v{ 'unknown_project' };
    }

    public static macro function author() : ExprOf<String>
    {
        if (!Context.defined('flurry-build-file'))
        {
            Context.warning('flurry-build-file define does not exist', Context.currentPos());

            return macro $v{ 'unknown_project' };
        }

        final buildFile = Context.definedValue('flurry-build-file');

        if (!FileSystem.exists('build.json'))
        {
            Context.warning('Build file $buildFile does not exist', Context.currentPos());

            return macro $v{ 'unknown_project' };
        }

        final json = Json.parse(File.getContent(buildFile));

        if (json != null && json.app != null && json.app.author != null)
        {
            return macro $v{ json.app.author }
        }

        Context.warning('Project json from $buildFile does not contain the app author', Context.currentPos());

        return macro $v{ 'unknown_author' };
    }
}