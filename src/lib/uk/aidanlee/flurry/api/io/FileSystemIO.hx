package uk.aidanlee.flurry.api.io;

import uk.aidanlee.flurry.FlurryConfig.FlurryProjectConfig;
import sys.io.abstractions.IFileSystem;
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

    final fs : IFileSystem;

    final configDir : String;

    public function new(_project, _fs)
    {
        project   = _project;
        fs        = _fs;
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
        if (!fs.directory.exist(configDir))
        {
            fs.directory.create(configDir);
        }

        return configDir;
    }

    public function has(_key : String)
    {
        return fs.file.exists(Path.join([ preferencePath(), _key ]));
    }

    public function remove(_key : String)
    {
        fs.file.remove(Path.join([ preferencePath(), _key ]));
    }

    public function getString(_key : String)
    {
        return if (has(_key))
            Some(fs.file.getText(Path.join([ preferencePath(), _key ])))
        else
            None;
    }

    public function getBytes(_key : String)
    {
        return if (has(_key))
            Some(fs.file.getBytes(Path.join([ preferencePath(), _key ])))
        else
            None;
    }

    public function setString(_key : String, _val : String)
    {
        fs.file.writeText(Path.join([ preferencePath(), _key ]), _val);
    }

    public function setBytes(_key : String, _val : Bytes)
    {
        fs.file.writeBytes(Path.join([ preferencePath(), _key ]), _val);
    }
}