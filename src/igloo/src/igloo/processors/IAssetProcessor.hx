package igloo.processors;

import igloo.parcels.ParcelContext;
import igloo.parcels.Asset;
import haxe.io.Output;

/**
 * Interface custom asset processors must implements.
 */
interface IAssetProcessor<T>
{
    /**
     * All IDs this asset processor can operate on.
     * These will either be file extensions or manually specified strings.
     */
    public function ids() : Array<String>;

    public function pack(_ctx : ParcelContext, _asset : Asset) : AssetRequest<T>;

    public function write(_ctx : ParcelContext, _writer : Output, _asset : ProcessedAsset<T>) : Void;
}