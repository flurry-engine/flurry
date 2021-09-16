package igloo.parcels;

import haxe.Exception;
import haxe.ds.Option;
import haxe.ds.Vector;
import hx.files.Path;
import json2object.ErrorUtils;
import json2object.JsonParser;
import igloo.utils.GraphicsApi;
import igloo.processors.ProcessorLoadResults;

using Lambda;

/**
 * Resolve all parcels in a project by loading bundles, finding the appropriate assets,
 * and reading any cached parcel metadata to figure out if the cached parcel is still valid.
 * @param _projectPath Absolute path to the json build file.
 * @param _bundles Array of paths to all bundle files in the project.
 * @param _outputDir Root output directory of the project.
 * @param _gpuApi Graphics backend in use.
 * @param _processors Object holding all loaded processors and load information.
 */
function resolveParcels(_projectPath : Path, _bundles : Array<String>, _outputDir : Path, _gpuApi, _release, _processors)
{
    final parser = new JsonParser<Package>();
    final loaded = [];

    for (path in _bundles)
    {
        final bundlePath   = _projectPath.parent.join(path);
        final baseAssetDir = bundlePath.parent;
        final bundle       = parser.fromJson(bundlePath.toFile().readAsString());

        if (parser.errors.length > 0)
        {
            Console.error('Failed to parse package file ${ bundlePath.toString() } : ${ ErrorUtils.convertErrorArray(parser.errors) }');

            throw new Exception('Failed to parse package file : ${ ErrorUtils.convertErrorArray(parser.errors) }');
        }

        for (parcel in bundle.parcels)
        {
            final tempOutput  = _outputDir.joinAll([ 'tmp', parcel.name ]);
            final parcelCache = _outputDir.joinAll([ 'cache', 'parcels' ]);
            final parcelFile  = parcelCache.join('${ parcel.name }.parcel');
            final parcelMeta  = parcelCache.join('${ parcel.name }.parcel.meta');

            final assets   = resolveAssets(parcel.assets, bundle.assets);
            final metadata = loadCacheData(parcelFile, parcelMeta);
            final isValid  = validateMetaData(metadata, _gpuApi, _release, _processors, assets, baseAssetDir);
            final data     = new LoadedParcel(
                parcelFile,
                parcelMeta,
                baseAssetDir,
                tempOutput,
                parcelCache,
                parcel.name,
                parcel.settings,
                assets,
                metadata,
                isValid);

            loaded.push(data);
        }
    }

    return loaded;
}

/**
 * Given an array of loaded parcels calculate the initial ID from the cached metadata
 * and reclaim IDs of all assets in invalid cached parcels.
 * @param _parcels Parcels to search.
 */
function createIDProvider(_parcels : Array<LoadedParcel>)
{
    // Find the initial cached ID.
    // We want to look through all parcel metas (both valid and invalid).
    var maxID = 0;
    for (parcel in _parcels)
    {
        switch parcel.metadata
        {
            case Some(v):
                for (page in v.pages)
                {
                    if (page.id > maxID)
                    {
                        maxID = page.id;
                    }
                }
                for (asset in v.assets)
                {
                    for (produced in asset.produced)
                    {
                        if (produced.id > maxID)
                        {
                            maxID = produced.id;
                        }
                    }
                }
            case None:
                //
        }
    }

    // If the max ID is greater than zero then some parcels were invalidated
    // In this case we want to increment the max ID so the first valid ID will be the next in the sequence.
    if (maxID > 0)
    {
        maxID++;
    }

    Console.log('ID provider will have an initial value of $maxID');

    final provider = new IDProvider(maxID);
    
    for (parcel in _parcels)
    {
        if (parcel.validCache)
        {
            continue;
        }

        switch parcel.metadata
        {
            case Some(v):
                for (page in v.pages)
                {
                    Console.log('reclaiming ${ page.id }');

                    provider.reclaim(page.id);
                }
                for (asset in v.assets)
                {
                    for (produced in asset.produced)
                    {
                        Console.log('reclaiming ${ produced.id }');

                        provider.reclaim(produced.id);
                    }
                }
            case None:
                //
        }
    }
    
    return provider;
}

/**
 * Given an array of asset names fetch all asset objects which match.
 * @param _wanted Array of name strings to find assets for.
 * @param _all Array of asset objects from a bundle.
 * @throws Exception If an asset object could not be found for a asset name.
 */
private function resolveAssets(_wanted : Array<String>, _all : Array<Asset>)
{
    final assets = new Vector(_wanted.length);

    for (idx => id in _wanted)
    {
        assets[idx] = findAsset(id, _all);
    }

    return assets;
}

private function findAsset(_id : String, _all : Array<Asset>)
{
    for (asset in _all)
    {
        if (asset.id == _id)
        {
            return asset;
        }
    }

    throw new Exception('Could not find an asset with ID $_id');
}

private function loadCacheData(_parcelFile : Path, _parcelMeta : Path) : Option<ParcelMeta>
{
    return if (_parcelFile.exists() && _parcelMeta.exists())
    {
        final metaParser = new JsonParser<ParcelMeta>();
        final metaFile   = metaParser.fromJson(_parcelMeta.toFile().readAsString());

        if (metaParser.errors.length > 0)
        {
            Console.log('Unable to parse parcel meta file');
            Console.log(ErrorUtils.convertErrorArray(metaParser.errors));

            None;
        }
        else
        {
            Some(metaFile);
        }
    }
    else
    {
        None;
    }
}

/**
 * Given a parcel metadata option it will check if that metadata represents a valid parcel with the given compilation options.
 * @param _meta Metadata option to check.
 * @param _gpuApi Current gpu api in use.
 * @param _processors Object holding all loaded processors and load information.
 * @param _assets All assets for this parcel in the curent bundle.
 * @param _assetDir Base asset directory for this parcels asset paths.
 */
private function validateMetaData(_meta : Option<ParcelMeta>, _gpuApi : GraphicsApi, _release : Bool, _processors : ProcessorLoadResult, _assets : Vector<Asset>, _assetDir : Path)
{
    switch _meta
    {
        case Some(v):
            // Processors might output different data based on the graphics api.
            // If the cached parcel was built with a different api to the current it is invalid.
            if (v.gpuApi != _gpuApi)
            {
                Console.log('Parcel was generated with a different graphics api');
        
                return false;
            }

            if (v.release != _release)
            {
                Console.log('Parcel was generated with a different release mode state');

                return false;
            }
        
            // If any of the recompiled processors were used in creating the cached parcel it is invalid.
            for (processor in _processors.recompiled)
            {
                if (v.processorsInvolved.contains(processor))
                {
                    Console.log('processor $processor was recompiled and has invalidated the parcel');
        
                    return false;
                }
            }
        
            // For each asset we want to pack see if its in the cached parcel
            // If it is check its modification date against the cached parcels.
            for (asset in _assets)
            {
                if (v.assets.find(item -> item.name == asset.id) == null)
                {
                    Console.log('asset ${ asset.id } not found in the parcel metadata');
        
                    return false;
                }
                else
                {
                    final abs  = _assetDir.join(asset.path);
                    final proc = _processors.loaded.get(abs.filenameExt);
        
                    if (proc != null)
                    {
                        if (proc.isInvalid(abs, v.timeGenerated))
                        {
                            Console.log('asset ${ asset.id } is invalid according to processor ${ abs.filenameExt }');
        
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
        case None:
            return false;
    }
}