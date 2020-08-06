package uk.aidanlee.flurry.api.stream;

import uk.aidanlee.flurry.api.core.Result;
import uk.aidanlee.flurry.api.stream.Compression;
import uk.aidanlee.flurry.api.stream.ImageFormat;
import uk.aidanlee.flurry.api.resources.Resource.Resource;
import uk.aidanlee.flurry.api.resources.Resource.ImageResource;
import haxe.io.Input;
import haxe.io.Bytes;
import haxe.io.BytesInput;
import format.png.Tools as PngTools;
import format.png.Reader as PngReader;
import hxbit.Serializer;

/**
 * Reads a parcel from the provided stream.
 */
class ParcelInput
{
    final serialiser : Serializer;

    final origin : Input;

    var reader : Input;

    var assets : Int;

    var compression : Compression;

    public function new(_input : Input)
    {
        serialiser  = new Serializer();
        origin      = _input;
        reader      = _input;
        assets      = 0;
        compression = None;
    }

    /**
     * Read the header data from the parcel.
     * Returns `Failure` if the input stream is not a valid parcel.
     * @return Result<ParcelHeader, String>
     */
    public function readHeader() : Result<ParcelHeader, String>
    {
        // Read magic bytes
        if ('PRCL' != origin.readString(4))
        {
            return Failure('Provided input stream is not a parcel');
        }

        compression = switch origin.readByte()
        {
            case 0: None;
            case 1:
                final level     = origin.readByte();
                final chunkSize = origin.readInt32();

                Deflate(level, chunkSize);
            case other: return Failure('unexpected compression byte $other');
        }
        reader = switch compression
        {
            case None: origin;
            case Deflate(_, _chunkSize): new InputDecompressor(origin, _chunkSize);
        }
        assets = origin.readInt32();

        return Success({
            compression : compression,
            assets      : assets
        });
    }

    /**
     * Read a resource from the input stream.
     * @return Result<Resource, String>
     */
    public function readAsset() : Result<Resource, String>
    {
        final id = reader.readByte();

        switch id
        {
            case 0:
                // hxbit serialised resource.
                final length = reader.readInt32();
                final tmp    = Bytes.alloc(length);
                final read   = reader.readBytes(tmp, 0, length);

                if (length != read)
                {
                    return Failure('did not read the expected number of bytes');
                }

                return Success(serialiser.unserialize(tmp, Resource));
            case 1:
                // Image data
                final format = reader.readByte();
                final width  = reader.readInt32();
                final height = reader.readInt32();
                final length = reader.readInt32();
                final name   = reader.readString(length);
                final length = reader.readInt32();
                final tmp    = Bytes.alloc(length);
                final read   = reader.readBytes(tmp, 0, length);

                if (length != read)
                {
                    return Failure('did not read the expected number of bytes');
                }

                return switch format
                {
                    case RawBGRA:
                        Success(new ImageResource(name, width, height, BGRAUNorm, tmp.getData()));
                    case Png:
#if linc_stb
                        final image = stb.Image.load_from_memory(tmp.getData(), read, 4);

                        Success(new ImageResource(name, width, height, RGBAUNorm, image.bytes));
#else
                        final input  = new BytesInput(tmp);
                        final data   = new PngReader(input).read();
                        final pixels = PngTools.extract32(data);

                        Success(new ImageResource(name, width, height, BGRAUNorm ,pixels.getData()));
#end
                    case Jpeg:
#if linc_stb
                        final image = stb.Image.load_from_memory(tmp.getData(), read, 4);

                        Success(new ImageResource(name, width, height, RGBAUNorm, image.bytes));
#else
                        final image = JpegReader.decode(tmp, Chromatic);
                                                    
                        Success(new ImageResource(name, image.width, image.height, RGBAUNorm, image.pixels.getData()));
#end
                    case other: Failure('Unknown image format $other');
                }

            case other: return Failure('Unknown payload type $other');
        }
    }

    /**
     * Closes the input stream provided in the constructor.
     */
    public function close()
    {
        origin.close();
    }
}

/**
 * Stores information about the parcels data.
 */
@:structInit @:publicFields private class ParcelHeader
{
    /**
     * Compression level applied to this parcel.
     */
    final compression : Compression;

    /**
     * Number of resources stored in this parcel.
     */
    final assets : Int;
}