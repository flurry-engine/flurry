package igloo.parcels;

import haxe.Exception;
import haxe.ds.Option;
import hx.files.Path;
import json2object.ErrorUtils;
import json2object.JsonParser;
import igloo.utils.GraphicsApi;
import igloo.logger.Log;
import igloo.parcels.Parcel.Asset;
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
function resolveParcels(_projectPath : Path, _log : Log, _bundles : Array<String>, _outputDir : Path, _id, _gpuApi, _release, _processors)
{
    final parser = new JsonParser<Parcel>();
    final loaded = [];

    for (path in _bundles)
    {
        final parcelPath   = _projectPath.parent.join(path);
        final baseAssetDir = parcelPath.parent;
        final parcel       = parser.fromJson(parcelPath.toFile().readAsString());

        if (parser.errors.length > 0)
        {
            final parseError = ErrorUtils.convertErrorArray(parser.errors);

            _log.error('Failed to parse package file $parcelPath : $parseError');

            throw new Exception('Failed to parse package file : $parseError');
        }

        final tempOutput  = _outputDir.joinAll([ 'tmp', parcel.name ]);
        final parcelCache = _outputDir.joinAll([ 'cache', 'parcels', parcel.name ]);
        final parcelFile  = parcelCache.join('${ parcel.name }.parcel');
        final parcelMeta  = parcelCache.join('${ parcel.name }.parcel.meta');

        final metadata = loadCacheData(_log, parcelFile, parcelMeta);
        final isValid  = validateMetaData(_log, metadata, _id, _gpuApi, _release, _processors, parcel.assets, baseAssetDir);
        final data     = new LoadedParcel(
            parcelFile,
            parcelMeta,
            baseAssetDir,
            tempOutput,
            parcelCache,
            parcel,
            metadata,
            isValid);

        loaded.push(data);
    }

    return loaded;
}

/**
 * Given an array of loaded parcels calculate the initial ID from the cached metadata
 * and reclaim IDs of all assets in invalid cached parcels.
 * @param _parcels Parcels to search.
 */
function createIDProvider(_log : Log, _parcels : Array<LoadedParcel>)
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
                for (_ => resources in v.resources)
                {
                    for (resource in resources)
                    {
                        if (resource.id > maxID)
                        {
                            maxID = resource.id;
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

    _log.debug('ID provider will have an initial value of $maxID');

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
                    _log.verbose('reclaiming ${ id }', page.id);

                    provider.reclaim(page.id);
                }
                for (_ => resources in v.resources)
                {
                    for (resource in resources)
                    {
                        _log.verbose('reclaiming ${ id }', resource.id);

                        provider.reclaim(resource.id);
                    }
                }
            case None:
                //
        }
    }
    
    return provider;
}

private function loadCacheData(_log : Log, _parcelFile : Path, _parcelMeta : Path) : Option<ParcelMeta>
{
    return if (_parcelFile.exists() && _parcelMeta.exists())
    {
        final metaParser = new JsonParser<ParcelMeta>();
        final metaFile   = metaParser.fromJson(_parcelMeta.toFile().readAsString());

        if (metaParser.errors.length > 0)
        {
            final metaPath = _parcelMeta.toString();
            final metaErrors = ErrorUtils.convertErrorArray(metaParser.errors);

            _log.error('Unable to parse parcel meta file $metaPath : $metaErrors');

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
 * @param _id The unique ID of this igloo compilation.
 * @param _gpuApi Current gpu api in use.
 * @param _release If release mode is enabled.
 * @param _processors Object holding all loaded processors and load information.
 * @param _assets All assets for this parcel in the curent bundle.
 * @param _assetDir Base asset directory for this parcels asset paths.
 */
private function validateMetaData(_log : Log, _meta : Option<ParcelMeta>, _id : Int, _gpuApi : GraphicsApi, _release : Bool, _processors : ProcessorLoadResult, _assets : Array<Asset>, _assetDir : Path)
{
    switch _meta
    {
        case Some(v):
            if (v.id != _id)
            {
                _log.debug('Igloo has been recompiled');

                return false;
            }

            // Processors might output different data based on the graphics api.
            // If the cached parcel was built with a different api to the current it is invalid.
            if (v.gpuApi != _gpuApi)
            {
                _log.debug('Parcel was generated with a different graphics api');
        
                return false;
            }

            if (v.release != _release)
            {
                _log.debug('Parcel was generated with a different release mode state');

                return false;
            }
        
            // If any of the recompiled processors were used in creating the cached parcel it is invalid.
            for (processor in _processors.recompiled)
            {
                if (v.processorsInvolved.contains(processor))
                {
                    _log.debug('processor $processor was recompiled and has invalidated the parcel');
        
                    return false;
                }
            }
        
            // For each asset we want to pack see if its in the cached parcel
            // If it is check its modification date against the cached parcels.
            for (asset in _assets)
            {
                if (v.resources.exists(asset.id))
                {
                    final abs = _assetDir.join(asset.path);

                    switch _processors.loaded.get(abs.filenameExt)
                    {
                        case null:
                            throw new Exception('No processor found for asset ${ asset.id }');
                        case proc:
                            if (proc.isInvalid(abs, v.timeGenerated))
                            {
                                _log.debug('asset ${ asset.id } is invalid according to processor ${ abs.filenameExt }');
            
                                return false;
                            }
                    }
                }
                else
                {
                    _log.debug('asset ${ asset.id } not found in the parcel metadata');
        
                    return false;
                }
            }
        
            return true;
        case None:
            return false;
    }
}