package igloo.parcels;

import igloo.parcels.ParcelMeta.ProducedMeta;
import sys.io.FileOutput;
import haxe.Exception;
import haxe.ds.Vector;
import haxe.ds.Either;
import haxe.io.Output;
import haxe.io.BytesOutput;
import hx.files.Path;
import igloo.blit.Blitter;
import igloo.atlas.Atlas;
import igloo.utils.OneOf;
import igloo.parcels.ParcelMeta.PageMeta;
import igloo.parcels.ParcelMeta.AssetMeta;
import igloo.processors.PackedAsset;
import igloo.processors.AssetRequest;
import igloo.processors.ProcessedAsset;
import igloo.processors.AssetProcessor;
import igloo.processors.ProcessorLoadResults;
import json2object.JsonWriter;

using Lambda;
using Safety;
using igloo.parcels.ParcelWriter;

function build(_ctx : ParcelContext, _parcel : LoadedParcel, _processors : ProcessorLoadResult, _id : IDProvider)
{
    Console.log('Cached parcel is invalid');

    final packed = new Map<String, Array<ProcessedAsset<Any>>>();
    final atlas  = new Atlas(_parcel.settings.xPad, _parcel.settings.yPad, _parcel.settings.maxWidth, _parcel.settings.maxHeight, _id);

    // processed assets are stored in a map keyed by the ID of the processor which operated on them.
    // This allows us to pass them into the write function of that same processor later on.
    for (asset in _parcel.assets)
    {
        final ext  = haxe.io.Path.extension(asset.path);
        final proc = _processors.loaded.get(ext);

        if (proc == null)
        {
            throw new Exception('Processor was not found for extension $ext');
        }
        
        final request   = proc.pack(_ctx, asset);
        final processed = processRequest(asset.id, request, atlas);
        final existing  = packed.get(ext);

        if (existing == null)
        {
            packed.set(ext, [ processed ]);
        }
        else
        {
            existing.push(processed);
        }
    }

    final blitTasks     = new Vector(atlas.pages.length);
    final output        = _parcel.parcelFile.toFile().openOutput(REPLACE);
    final writtenPages  = [];
    final writtenAssets = [];

    output.writeParcelHeader(atlas.pages.length, getPageFormatID(_parcel.settings.format));

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

    // All the individual pages get written into a staging buffer which is returned by the task.
    // Once each task is complete write the staging buffer into the output stream on the original thread.
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
    for (ext => assets in packed)
    {
        final proc = _processors.loaded.get(ext);

        if (proc == null)
        {
            throw new Exception('Processor was not found for extension $ext');
        }

        output.writeParcelProcessor(ext);

        for (asset in assets)
        {
            final produced = [];
            
            switch asset.response
            {
                case Packed(packed):
                    switch packed
                    {
                        case Left(v):
                            produced.push(writeParcelResource(output, proc, _ctx, asset.data, v, _id.id()));
                        case Right(vs):
                            for (v in vs)
                            {
                                produced.push(writeParcelResource(output, proc, _ctx, asset.data, v, _id.id()));
                            }
                    }
                case NotPacked(id):
                    produced.push(writeParcelResource(output, proc, _ctx, asset.data, id, _id.id()));
            }

            writtenAssets.push(new AssetMeta(asset.name, produced));
        }
    }

    output.writeParcelFooter();
    output.close();

    writeMetaFile(_parcel.parcelMeta, _ctx.gpuApi, _processors.names, writtenPages, writtenAssets);
}

private function writeParcelResource(_output : FileOutput, _processor : AssetProcessor<Any>, _ctx : ParcelContext, _data : Any, _asset : OneOf<PackedAsset, String>, _assetID : Int)
{
    final tellStart = _output.tell();
    final assetName = switch _asset {
        case Left(v)  : v.id;
        case Right(v) : v;
    }

    _output.writeInt32(_assetID);
    _processor.write(_ctx, _output, _data, _asset);

    final tellEnd = _output.tell();
    final length  = tellEnd - tellStart;

    return new ProducedMeta(_assetID, assetName, tellStart, length);
}

private function writeMetaFile(_file : Path, _gpuApi, _processorNames, _pages, _assets)
{
    final writer   = new JsonWriter<ParcelMeta>();
    final metaFile = new ParcelMeta(Date.now().getTime(), _gpuApi, _processorNames, _pages, _assets);
    final json     = writer.write(metaFile);
    
    _file.toFile().writeString(json);
}

private function processRequest(_id : String, _asset : AssetRequest<Any>, _atlas : Atlas)
{
    return switch _asset.request
    {
        case Pack(either):
            switch either
            {
                case Left(request):
                    new ProcessedAsset(_id, _asset.data, Packed(Left(_atlas.pack(request))));
                case Right(requests):
                    new ProcessedAsset(_id, _asset.data, Packed(Right([ for (request in requests) _atlas.pack(request) ])));
            }
        case None(id):
            new ProcessedAsset(_id, _asset.data, NotPacked(id));
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