package igloo.parcels;

import hx.files.Path;
import haxe.ds.Option;
import haxe.ds.Vector;

class LoadedParcel
{
    public final parcelFile : Path;

    public final parcelMeta : Path;

    public final assetDir : Path;

    public final tempDir : Path;

    public final cacheDir : Path;

    public final name : String;

    public final settings : PageSettings;

    public final assets : Vector<Asset>;

    public final metadata : Option<ParcelMeta>;

    public final validCache : Bool;

    public function new(_parcelFile, _parcelMeta, _assetDir, _tempDir, _cacheDir, _name, _settings, _assets, _metadata, _validCache)
    {
        parcelFile = _parcelFile;
        parcelMeta = _parcelMeta;
        assetDir   = _assetDir;
        tempDir    = _tempDir;
        cacheDir   = _cacheDir;
        name       = _name;
        settings   = _settings;
        assets     = _assets;
        metadata   = _metadata;
        validCache = _validCache;
    }
}