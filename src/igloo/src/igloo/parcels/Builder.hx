package igloo.parcels;

import haxe.Exception;
import haxe.ds.Option;
import haxe.ds.Vector;
import haxe.ds.Either;
import haxe.io.Output;
import haxe.io.BytesOutput;
import hx.files.Path;
import igloo.blit.Blitter;
import igloo.utils.OneOf;
import igloo.atlas.Atlas;
import igloo.logger.Log;
import igloo.parcels.ParcelMeta.PageMeta;
import igloo.parcels.ParcelMeta.ResourceMeta;
import igloo.processors.RequestType;
import igloo.processors.ResourceRequest;
import igloo.processors.ProcessedResource;
import igloo.processors.ProcessorLoadResults;
import json2object.JsonWriter;

using Lambda;
using Safety;
using igloo.parcels.ParcelWriter;

function build(_ctx : ParcelContext, _log : Log, _id : Int, _parcel : LoadedParcel, _processors : ProcessorLoadResult, _provider : IDProvider)
{
    _log.debug('Cached parcel is invalid');

    final packed = new Map<String, Array<ProcessedResource<Any>>>();
    final atlas  = new Atlas(_parcel.settings.xPad, _parcel.settings.yPad, _parcel.settings.maxWidth, _parcel.settings.maxHeight, _provider);

    // Each source asset produces 1-n resource requests. Each request has a type, packed or unpacked.
    // These requests are then resolved by packing them into the atlas if needed.
    // The request and all resolved resources are then stored for blitting and writing.
    var totalResponses = 0;

    for (asset in _parcel.assets)
    {
        final ext = haxe.io.Path.extension(asset.path);

        switch _processors.loaded.get(ext)
        {
            case null:
                throw new Exception('Processor was not found for extension $ext');
            case proc:
                final request   = proc.pack(_ctx, asset);
                final processed = processRequest(asset.id, request, atlas, _provider);

                totalResponses += processed.length;

                switch packed.get(ext)
                {
                    case null:
                        packed.set(ext, processed);
                    case existing:
                        for (v in processed)
                        {
                            existing.push(v);
                        }
                }
        }
    }

    final totalResources   = atlas.pages.length + totalResponses;
    final blitTasks        = new Vector(atlas.pages.length);
    final output           = _parcel.parcelFile.toFile().openOutput(REPLACE);
    final writtenResources = new Map<String, Array<ResourceMeta>>();
    final writtenPages     = [];

    output.writeParcelHeader(totalResources, getPageFormatID(_parcel.settings.format));

    // At this stage all assets have been packed into atlas pages if they requested it.
    // We can now blit all the images into the final pages.
    // Each page is independent so we can get a nice speed boost by throwing it into a task pool.
    for (i in 0...atlas.pages.length)
    {
        final page = atlas.pages[i];

        blitTasks[i] = _ctx.executor.submit(() -> {
            final rgbaBytes = blit(page);
            final staging   = new BytesOutput();
    
            switch _parcel.settings.format
            {
                case 'jpg', 'jpeg':
                    if (stb.ImageWrite.write_jpg_func(cpp.Callable.fromStaticFunction(writeCallback), staging, page.width, page.height, 4, rgbaBytes, 90) == 0)
                    {
                        throw new Exception('Failed to write image');
                    }
                case 'png':
                    if (stb.ImageWrite.write_png_func(cpp.Callable.fromStaticFunction(writeCallback), staging, page.width, page.height, 4, rgbaBytes, page.width * 4) == 0)
                    {
                        throw new Exception('Failed to write image');
                    }
            }
            
            return staging.getBytes();
        });
    }

    // Each page is written into a in-memory staging buffer which allows each page to be generated on a separate thread.
    // The tasks return this staging buffer and we copy them into the output on the main thread.
    for (i in 0...blitTasks.length)
    {
        switch blitTasks[i].waitAndGet(-1)
        {
            case SUCCESS(result, _, _):
                final sourcePage = atlas.pages[i];
                final tellStart  = output.tell();

                output.writeParcelPage(sourcePage, result);

                final tellEnd = output.tell();
                final length  = tellEnd - tellStart;

                writtenPages.push(new PageMeta(sourcePage.id, tellStart, length, sourcePage.width, sourcePage.height));

                blitTasks[i].cancel();
            case _:
                throw new Exception('Failed to blit page');
        }
    }

    // Finally call the write function of processors passing in the appropriate asset data.
    // Grouping by the ID used to pack the source assets should allow reads to not have to constantly look
    // in some sort of string map for every single resource.
    for (ext => resources in packed)
    {
        switch _processors.loaded.get(ext)
        {
            case null:
                throw new Exception('Processor was not found for extension $ext');
            case proc:
                output.writeParcelProcessor(ext);

                for (resource in resources)
                {
                    final tellStart = output.tell();

                    output.writeParcelResource(proc, _ctx, resource);

                    final tellEnd = output.tell();
                    final length  = tellEnd - tellStart;
                    final meta    = new ResourceMeta(resource.id, resource.name, tellStart, length);

                    switch writtenResources.get(resource.source)
                    {
                        case null:
                            writtenResources.set(resource.source, [ meta ]);
                        case existing:
                            existing.push(meta);
                    }
                }
        }
    }

    output.writeParcelFooter();
    output.close();

    writeMetaFile(_parcel.parcelMeta, _id, _ctx.gpuApi, _ctx.release, _processors.names, writtenPages, writtenResources);
}

/**
 * Write a metadata json file for a parcel.
 * @param _file Location to write the json file.
 * @param _id Unique ID of this igloo compilation.
 * @param _gpuApi The graphics API used for packaging this parcel.
 * @param _release If release mode is enabled when building this parcel.
 * @param _processorNames List of all processor names used in packaging this parcel.
 * @param _pages All pages packaged in this parcel.
 * @param _resources All resources packaged in this parcel.
 */
private function writeMetaFile(_file : Path, _id, _gpuApi, _release, _processorNames, _pages, _resources)
{
    final writer   = new JsonWriter<ParcelMeta>();
    final metaFile = new ParcelMeta(Date.now().getTime(), _id, _gpuApi, _release, _processorNames, _pages, _resources);
    final json     = writer.write(metaFile);
    
    _file.toFile().writeString(json);
}

/**
 * Process a request, packing any resources into the atlas.
 * @param _source Source asset name.
 * @param _request Resource request generated from an asset.
 * @param _atlas Atlas to pack requests into.
 * @param _provider Object which will provide IDs for non packed resources.
 */
private function processRequest(_source, _requests : OneOf<ResourceRequest<Any>, Array<ResourceRequest<Any>>>, _atlas, _provider : IDProvider)
{
    return switch _requests
    {
        case Left(single):
            [ new ProcessedResource(_source, single.name, _provider.id(), single.data, expandImagePackRequests(single.packs, _atlas)) ];
        case Right(many):
            [ for (v in many) new ProcessedResource(_source, v.name, _provider.id(), v.data, expandImagePackRequests(v.packs, _atlas)) ];
    }
}

private function expandImagePackRequests(_requests : Option<OneOf<RequestType, Array<RequestType>>>, _atlas)
{
    return switch _requests
    {
        case Some(packs):
            switch packs
            {
                case Left(single):
                    Some(Left(packImageRequest(single, _atlas)));
                case Right(many):
                    Some(Right([ for (single in many) packImageRequest(single, _atlas) ]));
            }
        case None:
            None;
    }
}

private function packImageRequest(_type : RequestType, _atlas : Atlas)
{
    return switch _type
    {
        case PackImage(path):
            final info = stb.Image.info(path.toString());

            _atlas.pack(_type, info.w, info.h);
        case PackBytes(_, width, height, _):
            _atlas.pack(_type, width, height);
    }
}

private function getPageFormatID(_type : String)
{
    return switch _type
    {
        case 'jpg', 'jpeg': 0;
        case 'png': 1;
        case other: throw new Exception('Unsupported image format $other');
    }
}

@:void private function writeCallback(_ctx : cpp.Star<cpp.Void>, _data : cpp.Star<cpp.Void>, _size : Int)
{
    final output = (cpp.Pointer.fromStar(_ctx).reinterpret() : cpp.Pointer<Output>).value;
    final array  = (cpp.Pointer.fromStar(_data).reinterpret() : cpp.Pointer<cpp.UInt8>).toUnmanagedArray(_size);
    final bytes  = haxe.io.Bytes.ofData(array);

    output.write(bytes);
}