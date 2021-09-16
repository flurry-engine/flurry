package igloo.parcels;

import hx.concurrent.executor.Executor;
import igloo.tools.Tools;
import hx.files.Path;

class ParcelContext
{
    public final name : String;

    public final assetDirectory : Path;

    public final tempDirectory : Path;

    public final cacheDirectory : Path;

    public final gpuApi : String;

    public final release : Bool;

    public final tools : Tools;

    public final executor : Executor;

    public function new(_name, _assetDirectory, _tempDirectory, _cacheDirectory, _graphicsApi, _release, _tools, _executor)
    {
        name           = _name;
        assetDirectory = _assetDirectory;
        tempDirectory  = _tempDirectory;
        cacheDirectory = _cacheDirectory;
        gpuApi         = _graphicsApi;
        release        = _release;
        tools          = _tools;
        executor       = _executor;
    }
}