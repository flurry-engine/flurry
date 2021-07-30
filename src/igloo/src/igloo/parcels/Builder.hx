package igloo.parcels;

import igloo.processors.ResourceResponse;
import igloo.processors.RequestType;
import sys.io.FileOutput;
import haxe.Exception;
import haxe.ds.Vector;
import haxe.ds.Either;
import haxe.io.Output;
import haxe.io.BytesOutput;
import hx.files.Path;
import igloo.blit.Blitter;
import igloo.atlas.Atlas;
import igloo.parcels.ParcelMeta.PageMeta;
import igloo.parcels.ParcelMeta.AssetMeta;
import igloo.parcels.ParcelMeta.ResourceMeta;
import igloo.processors.ResourceRequest;
import igloo.processors.ProcessedResource;
import igloo.processors.ProcessorLoadResults;
import json2object.JsonWriter;

using Lambda;
using Safety;
using igloo.parcels.ParcelWriter;

function build(_ctx : ParcelContext, _parcel : LoadedParcel, _processors : ProcessorLoadResult, _id : IDProvider)
{
    Console.log('Cached parcel is invalid');

    final packed = new Map<String, Array<ProcessedResource<Any>>>();
    final atlas  = new Atlas(_parcel.settings.xPad, _parcel.settings.yPad, _parcel.settings.maxWidth, _parcel.settings.maxHeight, _id);

    // Each source asset produces 1-n resource requests. Each request has a type, packed or unpacked.
    // These requests are then resolved by packing them into the atlas if needed.
    // The request and all resolved resources are then stored for blitting and writing.
    var totalResponses = 0;

    for (asset in _parcel.assets)
    {
        final ext  = haxe.io.Path.extension(asset.path);
        final proc = _processors.loaded.get(ext);

        if (proc == null)
        {
            throw new Exception('Processor was not found for extension $ext');
        }
        
        final request   = proc.pack(_ctx, asset);
        final processed = processRequest(asset.id, request, atlas, _id);
        final existing  = packed.get(ext);

        switch processed.response
        {
            case Left(_): totalResponses++;
            case Right(v): totalResponses += v.length;
        }

        if (existing == null)
        {
            packed.set(ext, [ processed ]);
        }
        else
        {
            existing.push(processed);
        }
    }

    final totalResources = atlas.pages.length + totalResponses;
    final blitTasks     = new Vector(atlas.pages.length);
    final output        = _parcel.parcelFile.toFile().openOutput(REPLACE);
    final writtenPages  = [];
    final writtenAssets = [];

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
    for (ext => assets in packed)
    {
        final proc = _processors.loaded.get(ext);

        if (proc == null)
        {
            throw new Exception('Processor was not found for extension $ext');
        }

        output.writeParcelProcessor(ext);

        // Each source asset can produce multiple resource requests.
        // For all resources a source asset produced write it into the parcel stream.
        // Store the position in the output stream before and after writing so we know where it is in the file.
        // This info is only stored in the meta file for now and is unused.
        for (asset in assets)
        {
            final produced = [];

            switch asset.response
            {
                case Left(v):
                    writeProcessedResource(output, proc, _ctx, asset.data, v, produced);
                case Right(vs):
                    for (v in vs)
                    {
                        writeProcessedResource(output, proc, _ctx, asset.data, v, produced);
                    }
            }

            writtenAssets.push(new AssetMeta(asset.source, produced));
        }
    }

    output.writeParcelFooter();
    output.close();

    writeMetaFile(_parcel.parcelMeta, _ctx.gpuApi, _processors.names, writtenPages, writtenAssets);
}

/**
 * Writes a resource into the parcel stream by invoking the `write` function of the processor which produced the request.
 * The position and length of the asset written into the stream is calculated and stored in the parcels meta file.
 */
private function writeProcessedResource(_output : FileOutput, _proc, _ctx, _data, _resource : ResourceResponse, _meta : Array<ResourceMeta>)
{
    final tellStart = _output.tell();

    _output.writeParcelResource(_proc, _ctx, _data, _resource);

    final tellEnd = _output.tell();
    final length  = tellEnd - tellStart;

    // Extract the id and name from the resource as we need it for the parcel meta.
    switch _resource
    {
        case Packed(_packed):
            _meta.push(new ResourceMeta(_packed.id, _packed.name, tellStart, length));
        case NotPacked(_name, _id):
            _meta.push(new ResourceMeta(_id, _name, tellStart, length));
    }
}

/**
 * Write a metadata json file for a parcel.
 * @param _file Location to write the json file.
 * @param _gpuApi The graphics API used for packaging this parcel.
 * @param _processorNames List of all processor names used in packaging this parcel.
 * @param _pages All pages packaged in this parcel.
 * @param _resources All resources packaged in this parcel.
 */
private function writeMetaFile(_file : Path, _gpuApi, _processorNames, _pages, _resources)
{
    final writer   = new JsonWriter<ParcelMeta>();
    final metaFile = new ParcelMeta(Date.now().getTime(), _gpuApi, _processorNames, _pages, _resources);
    final json     = writer.write(metaFile);
    
    _file.toFile().writeString(json);
}

/**
 * Process a request, packing any resources into the atlas.
 * @param _source Source asset name.
 * @param _request Resource request object.
 * @param _atlas Atlas to pack requests into.
 * @param _provider Object which will provide IDs for non packed resources.
 */
private function processRequest(_source : String, _request : ResourceRequest<Any>, _atlas : Atlas, _provider : IDProvider)
{
    return new ProcessedResource(_source, _request.data, switch _request.type
    {
        case Left(v): generateResponse(v, _atlas, _provider);
        case Right(vs): [ for (v in vs) generateResponse(v, _atlas, _provider) ];
    });
}

private function generateResponse(_type : RequestType, _atlas : Atlas, _provider : IDProvider)
{
    return switch _type
    {
        case PackImage(id, path):
            final info = stb.Image.info(path.toString());

            Packed(_atlas.pack(_type, id, info.w, info.h));
        case PackBytes(id, _, width, height, _):
            Packed(_atlas.pack(_type, id, width, height));
        case UnPacked(_name):
            NotPacked(_name, _provider.id());
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