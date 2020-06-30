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

class ParcelInput
{
    final serialiser : Serializer;

    final input : Input;

    public function new(_input : Input)
    {
        serialiser = new Serializer();
        input      = _input;
    }

    public function read() : Result<Array<Resource>, String>
    {
        final resources = [];

        // Read magic bytes
        if ('PRCL' != input.readString(4))
        {
            return Failure('invalid magic bytes');
        }

        // Read Compression info
        final compressionByte = input.readByte();
        final compression     = switch compressionByte
        {
            case 0: None;
            case 1:
                final level     = input.readByte();
                final chunkSize = input.readInt32();

                Deflate(level, chunkSize);
            case other:
                return Failure('Unknown compression type $other');
        }

        // Read payload info
        final payloadLength = input.readInt32();

        // Get out data input stream based on the compression
        final dataInput = switch compression
        {
            case None: input;
            case Deflate(_, _chunkSize): new InputDecompressor(input, _chunkSize);
        }

        // Read the expected number of payload entries
        for (_ in 0...payloadLength)
        {
            final id = dataInput.readByte();

            switch id
            {
                case 0:
                    // hxbit serialised resource.
                    final length = dataInput.readInt32();
                    final tmp    = Bytes.alloc(length);
                    final read   = dataInput.readBytes(tmp, 0, length);

                    if (length != read)
                    {
                        return Failure('did not read the expected number of bytes');
                    }

                    resources.push(serialiser.unserialize(tmp, Resource));
                case 1:
                    // Image data
                    final format = dataInput.readByte();
                    final width  = dataInput.readInt32();
                    final height = dataInput.readInt32();
                    final length = dataInput.readInt32();
                    final name   = dataInput.readString(length);
                    final length = dataInput.readInt32();
                    final tmp    = Bytes.alloc(length);
                    final read   = dataInput.readBytes(tmp, 0, length);

                    if (length != read)
                    {
                        return Failure('did not read the expected number of bytes');
                    }

                    switch format
                    {
                        case RawBGRA:
                            resources.push(new ImageResource(name, width, height, BGRAUNorm, tmp.getData()));
                        case Png:
#if linc_stb
                            final image = stb.Image.load_from_memory(tmp.getData(), read, 4);

                            resources.push(new ImageResource(name, width, height, RGBAUNorm, image.bytes));
#else
                            final input  = new BytesInput(tmp);
                            final reader = new PngReader(input);
                            final data   = reader.read();
                            final pixels = PngTools.extract32(data);

                            resources.push(new ImageResource(name, width, height, BGRAUNorm ,pixels.getData()));
#end
                        case Jpeg:
#if linc_stb
                            final image = stb.Image.load_from_memory(tmp.getData(), read, 4);

                            resources.push(new ImageResource(name, width, height, RGBAUNorm, image.bytes));
#else
                            throw 'not implemented on this story';
#end
                    }

                case other:
                    return Failure('Unknown payload type $other');
            }
        }

        return Success(resources);
    }

    public function close()
    {
        input.close();
    }
}