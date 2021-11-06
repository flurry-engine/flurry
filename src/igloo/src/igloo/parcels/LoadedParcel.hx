package igloo.parcels;

import igloo.parcels.Parcel;
import hx.files.Path;
import haxe.ds.Option;

class LoadedParcel
{
    public final parcelFile : Path;

    public final parcelMeta : Path;

    public final assetDir : Path;

    public final tempDir : Path;

    public final cacheDir : Path;

    public final parcel : Parcel;

    public final metadata : Option<ParcelMeta>;

    public final validCache : Bool;

    public function new(_parcelFile, _parcelMeta, _assetDir, _tempDir, _cacheDir, _parcel, _metadata, _validCache)
    {
        parcelFile = _parcelFile;
        parcelMeta = _parcelMeta;
        assetDir   = _assetDir;
        tempDir    = _tempDir;
        cacheDir   = _cacheDir;
        parcel     = _parcel;
        metadata   = _metadata;
        validCache = _validCache;
    }
}