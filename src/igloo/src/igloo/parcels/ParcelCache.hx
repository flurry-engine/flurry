package igloo.parcels;

import igloo.processors.ProcessorLoadResults.ProcessorLoadResult;
import json2object.ErrorUtils;
import json2object.JsonParser;
import json2object.JsonWriter;
import igloo.utils.GraphicsApi;
import haxe.Exception;
import igloo.processors.AssetProcessor;
import haxe.io.Eof;
import haxe.ds.Vector;
import hx.files.Path;

using Lambda;

class ParcelCache
{
    /**
     * Absolute path all relative paths within a assets package will be based on.
     * Used to construct the absolute path of assets to get their modification time.
     */
    final assetDir : Path;

    /**
     * Absolute path to the cached parcel file.
     * This is the actual parcel which was built.
     */
    final cachedParcel : Path;

    /**
     * Absolute path to the cached parcel hash file.
     * This json file contains information about the environment the cached parcel was built in.
     */
    final cachedParcelMeta : Path;

    /**
     * List of all assets we want to go into the parcel.
     * We cross reference this lists against the assets found in the parcel hash to check if its still valid.
     * If there are extra assets in the cached parcel it is not considered invalid.
     */
    final assets : Vector<Asset>;

    /**
     * The result object of all processors being loaded.
     */
    final processors : ProcessorLoadResult;

    /**
     * The gaphics API current used.
     */
    final gpuApi : GraphicsApi;

	public function new(_assetDir, _cachedParcel, _cachedParcelMeta, _assets, _processors, _gpuApi)
    {
		assetDir          = _assetDir;
		cachedParcel      = _cachedParcel;
		cachedParcelMeta  = _cachedParcelMeta;
        assets            = _assets;
        processors        = _processors;
        gpuApi            = _gpuApi;
	}

    /**
     * Checks if there is an existing parcel and if its valid.
     */
    public function isValid()
    {
        if (!cachedParcel.exists() || !cachedParcelMeta.exists())
        {
            Console.debug('Cached parcel or hash file does not exist');

            return false;
        }

        final metaParser = new JsonParser<ParcelMeta>();
        final metaFile   = metaParser.fromJson(cachedParcelMeta.toFile().readAsString());

        if (metaParser.errors.length > 0)
        {
            Console.debug('Unable to parse parcel meta file');
            Console.debug(ErrorUtils.convertErrorArray(metaParser.errors));

            return false;
        }

        // Processors might output different data based on the graphics api.
        // If the cached parcel was built with a different api to the current it is invalid.
        if (gpuApi != metaFile.gpuApi)
        {
            Console.debug('Parcel was generated with a different graphics api');

            return false;
        }

        // If any of the recompiled processors were used in creating the cached parcel it is invalid.
        for (processor in processors.recompiled)
        {
            if (metaFile.processorsInvolved.contains(processor))
            {
                Console.debug('processor $processor was recompiled and has invalidated the parcel');

                return false;
            }
        }

        // For each asset we want to pack see if its in the cached parcel
        // If it is check its modification date against the cached parcels.
        for (asset in assets)
        {
            if (metaFile.assetsPacked.find(i -> i == asset.id) == null)
            {
                Console.debug('asset ${ asset.id } not found in the parcel hash ${ cachedParcelMeta }');

                return false;
            }
            else
            {
                final abs  = assetDir.join(asset.path);
                final proc = processors.loaded.get(abs.filenameExt);

                if (proc != null)
                {
                    if (proc.isInvalid(abs, metaFile.timeGenerated))
                    {
                        Console.debug('asset ${ asset.id } is invalid according to processor ${ abs.filenameExt }');
    
                        return false;
                    }
                }
                else
                {
                    throw new Exception('No processor found for asset ${ asset.id }');
                }
            }
        }

        return true;
    }

    public function writeMetaFile()
    {
        final writer   = new JsonWriter<ParcelMeta>();
        final assets   = [ for (asset in assets) asset.id ];
        final metaFile = new ParcelMeta(Date.now().getTime(), gpuApi, processors.names, assets);
        final json     = writer.write(metaFile);
        
        cachedParcelMeta.toFile().writeString(json);
    }
}

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

    /**
     * IDs of all the assets in the cached parcel.
     * If one of the assets we want to pack for this build is not already in the parcel it is immediately invalidated.
     */
    public var assetsPacked : Array<String>;

    public function new(_timeGenerated, _gpuApi, _processorsInvolved, _assetsPacked)
    {
        flurryVersion      = '';
        timeGenerated      = _timeGenerated;
        gpuApi             = _gpuApi;
        processorsInvolved = _processorsInvolved;
        assetsPacked       = _assetsPacked;
    }
}