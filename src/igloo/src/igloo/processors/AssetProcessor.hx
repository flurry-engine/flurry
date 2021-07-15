package igloo.processors;

import haxe.ds.Option;
import haxe.Exception;
import igloo.project.ProjectContext;
import hx.files.Path;
import igloo.parcels.ParcelContext;
import igloo.parcels.Asset;
import haxe.io.Output;

/**
 * Abstract class all asset processors must extend.
 */
class AssetProcessor<T>
{
    /**
     * The project context is an immutable object which contains various bits of information about the project.
     * It holds the location of paths you can use to store processor specific data.
     */
    final projectCtx : ProjectContext;

    /**
     * Each specified processor is created once and is re-used for all assets which match its IDs.
     * If you want to perform one off startup code (e.g. download an external tool) the constructor is the place.
     * @param _projectCtx Project context object.
     */
    public function new(_projectCtx)
    {
        projectCtx = _projectCtx;
    }

    /**
     * Allows the processor to check if an asset is invalid since the cached parcel was built.
     * The default implementation simply checks the modification date of the file at the path.
     * @param _path Absolute file path of the asset to check.
     * @param _time Time stamp the cached parcel was created.
     */
    public function isInvalid(_path : Path, _time : Float)
    {
        return _path.getModificationTime() >= _time;
    }

    /**
     * All IDs this asset processor can operate on.
     * These can either be file extensions or manually specified strings.
     */
    public function ids() : Array<String>
    {
        throw new Exception('Not implemented');
    }

    public function pack(_ctx : ParcelContext, _asset : Asset) : ResourceRequest<T>
    {
        throw new Exception('Not implemented');
    }

    public function write(_ctx : ParcelContext, _writer : Output, _data : T, _response : ResourceResponse) : Void
    {
        throw new Exception('Not implemented');
    }
}