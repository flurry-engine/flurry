package igloo.parcels;

import igloo.utils.GraphicsApi;

/**
 * Each parcel has a .meta file which is a json structure describing the environment when the cached parcel was built.
 * We compare that against the current environment to see if it is still valid or needs rebuilding.
 */
class ParcelMeta
{
    /**
     * The commit hash the igloo tool was built from when building the cached parcel.
     * If this does not match the current igloo tools commit has the parcel is invalid.
     */
    public var flurryVersion : String;

    /**
     * The date time stamp the cached parcel was created at.
     * This value is passed to asset processors to decide if the assets are still valid.
     */
    public var timeGenerated : Float;

    /**
     * The graphics api that was set when the cached parcel was created.
     * If this differs from the current one the parcel will be invalid.
     */
    public var gpuApi : GraphicsApi;

    /**
     * List of all processors which were used when building the cached parcel.
     * If any processor in this list was re-compiled for this build the parcel will be invalid.
     */
    public var processorsInvolved : Array<String>;
    
    public var pages : Array<PageMeta>;

    public var assets : Array<AssetMeta>;

    public function new(_timeGenerated, _gpuApi, _processorsInvolved, _pages, _assets)
    {
        flurryVersion      = '';
        timeGenerated      = _timeGenerated;
        gpuApi             = _gpuApi;
        processorsInvolved = _processorsInvolved;
        pages              = _pages;
        assets             = _assets;
    }
}

class PageMeta
{
    /**
     * Project unique ID of this page.
     */
    public final id : Int;

    /**
     * The byte position of this page in the parcel (includes the PAGE header).
     */
    public final pos : Int;

    public final length : Int;

    public final width : Int;

    public final height : Int;

    public function new(_id, _pos, _length, _width, _height)
    {
        id     = _id;
        pos    = _pos;
        length = _length;
        width  = _width;
        height = _height;
    }
}

class AssetMeta
{
    /**
     * ID of the source asset which produced the resources.
     */
    public final name : String;

    /**
     * All resources produced by this asset.
     */
    public final produced : Array<ResourceMeta>;

    public function new(_name, _produced)
    {
        name     = _name;
        produced = _produced;
    }
}

class ResourceMeta
{
    /**
     * Parcel unique name of this resource.
     */
    public final name : String;

    /**
     * Project unique ID of this resource.
     */
    public final id : Int;

    /**
     * The byte position of this resource in the parcel (includes the RESR header).
     */
    public final pos : Int;

    /**
     * The number of bytes this resource takes in the parcel (including the RESR header).
     */
    public final length : Int;

    public function new(_id, _name, _pos, _length)
    {
        id     = _id;
        name   = _name;
        pos    = _pos;
        length = _length;
    }
}