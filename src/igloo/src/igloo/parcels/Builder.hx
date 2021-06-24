package igloo.parcels;

import haxe.Exception;
import haxe.ds.Vector;
import haxe.ds.Either;
import haxe.io.Path;
import haxe.io.Output;
import haxe.io.BytesOutput;
import igloo.processors.PackRequest;
import igloo.processors.AssetRequest;
import igloo.processors.ProcessedAsset;
import igloo.processors.IAssetProcessor;
import igloo.blit.Blitter;
import igloo.atlas.Atlas;

using Safety;
using igloo.parcels.ParcelWriter;

function build(_ctx : ParcelContext, _parcel : Parcel, _all : Array<Asset>, _processors : Map<String, IAssetProcessor<Any>>)
{
    final assets = resolveAssets(_parcel.assets, _all);
    final packed = new Map<String, Array<ProcessedAsset<Any>>>();
    final atlas  = new Atlas(_parcel.name, _parcel.settings.xPad, _parcel.settings.yPad, _parcel.settings.maxWidth, _parcel.settings.maxHeight);

    // processed assets are stored in a map keyed by the ID of the processor which operated on them.
    // This allows us to pass them into the write function of that same processor later on.
    for (asset in assets)
    {
        final ext  = Path.extension(asset.path);
        final proc = _processors.get(ext);

        if (proc == null)
        {
            throw new Exception('Processor was not found for extension $ext');
        }
        
        final request   = proc.pack(_ctx, asset);
        final processed = processRequest(request, atlas);
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

    final futures = new Vector(atlas.pages.length);
    final output  = _ctx.tempDirectory
        .join('${ _parcel.name }.parcel')
        .toFile()
        .openOutput(REPLACE);

    output.writeParcelHeader();
    output.writeParcelMeta(atlas.pages.length, assets.length, getPageFormatID(_parcel.settings.format));

    // During the above processing assets are packed if they requested it.
    // We can now blit all the packed images and write zlib compressed image data into the output stream.
    for (i in 0...atlas.pages.length)
    {
        final page = atlas.pages[i];

        futures[i] = _ctx.executor.submit(() -> {
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

    for (i in 0...futures.length)
    {
        switch futures[i].waitAndGet(-1)
        {
            case SUCCESS(result, _, _):
                output.writeParcelPage(atlas.pages[i], result);
                futures[i].cancel();
            case _:
                throw new Exception('Failed to blit page');
        }
    }

    // Finally call the write function of processors passing in the appropriate asset data.
    for (ext => assets in packed)
    {
        final proc = _processors.get(ext);

        if (proc == null)
        {
            throw new Exception('Processor was not found for extension $ext');
        }

        output.writeParcelResources(ext, assets.length);

        for (asset in assets)
        {
            proc.write(_ctx, output, asset);
        }
    }

    output.writeParcelFooter();
    output.close();
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

private function processRequest(_asset : AssetRequest<Any>, _atlas : Atlas)
{
    return switch _asset.request
    {
        case Pack(either):
            switch (either : Either<PackRequest, Array<PackRequest>>)
            {
                case Left(request):
                    new ProcessedAsset(_asset.id, _asset.data, Packed(_atlas.pack(request)));
                case Right(requests):
                    new ProcessedAsset(_asset.id, _asset.data, Packed([ for (request in requests) _atlas.pack(request) ]));
            }
        case None:
            new ProcessedAsset(_asset.id, _asset.data, NotPacked);
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