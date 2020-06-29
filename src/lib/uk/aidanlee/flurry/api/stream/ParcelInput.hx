package uk.aidanlee.flurry.api.stream;

import uk.aidanlee.flurry.api.resources.Resource.ImageResource;
import haxe.io.BytesInput;
import uk.aidanlee.flurry.api.stream.Compression;
import uk.aidanlee.flurry.api.stream.ImageFormat;
import uk.aidanlee.flurry.api.resources.Resource.Resource;
import haxe.io.Input;
import haxe.io.Bytes;
import hxbit.Serializer;
import format.png.Tools as PngTools;
import format.png.Reader as PngReader;

class ParcelInput
{
    final serialiser : Serializer;

    final input : Input;

    public function new(_input : Input)
    {
        serialiser = new Serializer();
        input      = _input;
    }

    public function parcel() : Array<Resource>
    {
        final resources = [];

        // Read Header

        if ('PRCL' != input.readString(4))
        {
            throw 'invalid magic bytes';
        }

        final compressionByte = input.readByte();
        final compression     = switch compressionByte
        {
            case 0: None;
            case 1:
                final level     = input.readByte();
                final chunkSize = input.readInt32();

                Deflate(level, chunkSize);
            case other:
                throw 'Unknown compression type $other';
        }
        final payloadLength = input.readInt32();

        // Get out data input based on the compression
        final dataInput = switch compression
        {
            case None: input;
            case Deflate(_, _chunkSize): new InputDecompressor(input, _chunkSize);
        }

        trace('Valid header read');
        trace(compression);
        trace(payloadLength);

        // Read the expected number of payload entries
        for (_ in 0...payloadLength)
        {
            final id = dataInput.readByte();

            switch id
            {
                case 0:
                    trace('hxbit data');

                    // hxbit serialised resource.
                    final length = dataInput.readInt32();
                    final tmp    = Bytes.alloc(length);
                    final read   = dataInput.readBytes(tmp, 0, length);

                    if (length != read)
                    {
                        throw 'did not read the expected number of bytes';
                    }

                    resources.push(serialiser.unserialize(tmp, Resource));
                case 1:
                    trace('image data');

                    // Image data
                    final format = dataInput.readByte();
                    final length = dataInput.readInt32();
                    final name   = dataInput.readString(length);
                    final length = dataInput.readInt32();
                    final tmp    = Bytes.alloc(length);
                    final read   = dataInput.readBytes(tmp, 0, length);

                    if (length != read)
                    {
                        throw 'did not read the expected number of bytes';
                    }

                    switch format
                    {
                        case RawBGRA:
                            //
                        case Png:
                            final input  = new BytesInput(tmp);
                            final reader = new PngReader(input);
                            final data   = reader.read();
                            final header = PngTools.getHeader(data);
                            final pixels = PngTools.extract32(data);

                            resources.push(new ImageResource(name, header.width, header.height, pixels));
                        case Jpeg:
                            //
                    }

                case other:
                    throw 'Unknown payload type $other';
            }
        }

        return resources;
    }
}