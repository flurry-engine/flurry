package igloo.parcels;

import hx.files.Path;

class ParcelContext
{
    public final assetDirectory : Path;

    public final tempDirectory : Path;

    public final cacheDirectory : Path;

    public function new(_assetDirectory, _tempDirectory, _cacheDirectory)
    {
        assetDirectory = _assetDirectory;
        tempDirectory  = _tempDirectory;
        cacheDirectory = _cacheDirectory;
    }
}