package igloo.parcels;

import sys.io.FileOutput;
import igloo.processors.PackedAsset;
import igloo.utils.OneOf;
import igloo.processors.AssetProcessor;
import igloo.parcels.ParcelCache.AssetMeta;
import igloo.parcels.ParcelCache.PageMeta;
import igloo.utils.GraphicsApi;
import igloo.processors.ProcessorLoadResults.ProcessorLoadResult;
import haxe.Exception;
import haxe.ds.Vector;
import haxe.ds.Either;
import haxe.io.Output;
import haxe.io.BytesOutput;
import igloo.processors.AssetRequest;
import igloo.processors.ProcessedAsset;
import igloo.blit.Blitter;
import igloo.atlas.Atlas;

using Lambda;
using Safety;
using igloo.parcels.ParcelWriter;

function build(_ctx : ParcelContext, _parcel : Parcel, _all : Array<Asset>, _processors : ProcessorLoadResult, _gpuApi : GraphicsApi, _nextID : () -> Int)
{
    final parcelFile = _ctx.cacheDirectory.join('${ _parcel.name }.parcel');
    final parcelMeta = _ctx.cacheDirectory.join('${ _parcel.name }.parcel.meta');
    final assets     = resolveAssets(_parcel.assets, _all);
    final cache      = new ParcelCache(_ctx.assetDirectory, parcelFile, parcelMeta, assets, _processors, _gpuApi);

    if (cache.isValid())
    {
        Console.log('Cached parcel is valid');

        return parcelFile;
    }

    Console.log('Cached parcel is invalid');

    final packed = new Map<String, Array<ProcessedAsset<Any>>>();
    final atlas  = new Atlas(_parcel.settings.xPad, _parcel.settings.yPad, _parcel.settings.maxWidth, _parcel.settings.maxHeight, _nextID);

    // processed assets are stored in a map keyed by the ID of the processor which operated on them.
    // This allows us to pass them into the write function of that same processor later on.
    for (asset in assets)
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
    final output        = parcelFile.toFile().openOutput(REPLACE);
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
            switch asset.response
            {
                case Packed(packed):
                    switch packed
                    {
                        case Left(v):
                            writtenAssets.push(writeParcelResource(output, proc, _ctx, asset.data, v, _nextID));
                        case Right(vs):
                            for (v in vs)
                            {
                                writtenAssets.push(writeParcelResource(output, proc, _ctx, asset.data, v, _nextID));
                            }
                    }
                case NotPacked(id):
                    writtenAssets.push(writeParcelResource(output, proc, _ctx, asset.data, id, _nextID));
            }
        }
    }

    output.writeParcelFooter();
    output.close();

    cache.writeMetaFile(writtenPages, writtenAssets);

    return parcelFile;
}

private function writeParcelResource(_output : FileOutput, _processor : AssetProcessor<Any>, _ctx : ParcelContext, _data : Any, _asset : OneOf<PackedAsset, String>, _nextID : () -> Int)
{
    final tellStart = _output.tell();
    final assetID   = _nextID();
    final assetName = switch _asset {
        case Left(v)  : v.id;
        case Right(v) : v;
    }

    _output.writeString('RESR');

    _processor.write(_ctx, _output, _data, _asset);

    final tellEnd = _output.tell();
    final length  = tellEnd - tellStart;

    return new AssetMeta(assetID, assetName, tellStart, length);
}

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

private function processRequest(_id : String, _asset : AssetRequest<Any>, _atlas : Atlas)
{
    return switch _asset.request
    {
        case Pack(either):
            switch either
            {
                case Left(request):
                    new ProcessedAsset(_asset.data, Packed(Left(_atlas.pack(request))));
                case Right(requests):
                    new ProcessedAsset(_asset.data, Packed(Right([ for (request in requests) _atlas.pack(request) ])));
            }
        case None(id):
            new ProcessedAsset(_asset.data, NotPacked(id));
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