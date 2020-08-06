package uk.aidanlee.flurry.macros;

import sys.io.File;
import sys.FileSystem;
import haxe.Json;

using Safety;

class Project
{
    public static macro function name() : ExprOf<String>
    {
        if (FileSystem.exists('build.json'))
        {
            final json = Json.parse(File.getContent('build.json'));

            if (json != null && json.app != null && json.app.name != null)
            {
                return macro $v{ json.app.name };
            }
        }

        return macro $v{ 'unknown_project' };
    }

    public static macro function author() : ExprOf<String>
    {
        if (FileSystem.exists('build.json'))
        {
            final json = Json.parse(File.getContent('build.json'));

            if (json != null && json.app != null && json.app.author != null)
            {
                return macro $v{ json.app.author };
            }
        }

        return macro $v{ 'unknown_author' };
    }
}