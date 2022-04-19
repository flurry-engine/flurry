package uk.aidanlee.flurry.api.io;

import sys.io.File;
import sys.FileSystem;
import uk.aidanlee.flurry.FlurryConfig.FlurryProjectConfig;
import haxe.io.Path;
import haxe.io.Bytes;
import haxe.ds.Option;

using Safety;

/**
 * IO preferences implementation which uses the file system.
 * Each preference key is stored in a file with that key name in the folder given by `preferencePath`.
 */
class FileSystemIO implements IIO
{
    final project : FlurryProjectConfig;

    final configDir : String;

    public function new(_project)
    {
        project   = _project;
        configDir = switch Sys.systemName()
        {
            case 'Windows' : Path.join([ Sys.getEnv('APPDATA'), project.author, project.name ]);
            case 'Mac'     : Path.join([ Sys.getEnv('HOME'), 'Library', 'Application Support', project.author, project.name ]);
            case 'Linux'   : Path.join([ Sys.getEnv('XDG_DATA_HOME'), project.author, project.name ]);
            case _: '';
        }
    }

    public function preferencePath()
    {
        if (!FileSystem.exists(configDir))
        {
            FileSystem.createDirectory(configDir);
        }

        return configDir;
    }

    public function has(_key : String)
    {
        return FileSystem.exists(Path.join([ preferencePath(), _key ]));
    }

    public function remove(_key : String)
    {
        FileSystem.deleteFile(Path.join([ preferencePath(), _key ]));
    }

    public function getString(_key : String)
    {
        return if (has(_key))
            Some(File.getContent(Path.join([ preferencePath(), _key ])))
        else
            None;
    }

    public function getBytes(_key : String)
    {
        return if (has(_key))
            Some(File.getBytes(Path.join([ preferencePath(), _key ])))
        else
            None;
    }

    public function setString(_key : String, _val : String)
    {
        File.saveContent(Path.join([ preferencePath(), _key ]), _val);
    }

    public function setBytes(_key : String, _val : Bytes)
    {
        File.saveBytes(Path.join([ preferencePath(), _key ]), _val);
    }
}