package igloo.parcels;

import igloo.tools.Tools;
import hx.files.Path;

class ParcelContext
{
    public final assetDirectory : Path;

    public final tempDirectory : Path;

    public final cacheDirectory : Path;

    public final gpuApi : String;

    public final tools : Tools;

    public function new(_assetDirectory, _tempDirectory, _cacheDirectory, _tools)
    {
        assetDirectory = _assetDirectory;
        tempDirectory  = _tempDirectory;
        cacheDirectory = _cacheDirectory;
        gpuApi         = 'd3d11';
        tools          = _tools;
    }
}