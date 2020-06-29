package uk.aidanlee.flurry.api.stream;

import haxe.io.Bytes;
import haxe.io.Output;
import hxbit.Serializer;
import uk.aidanlee.flurry.api.resources.Resource;

enum Payload
{
    SerialisedResource(_resource : Resource);
    ImageData(_bytes : Bytes, _format : ImageFormat, _name : String);
}

class ParcelOutput
{
    final serialiser : Serializer;

    final headOutput : Output;

    final dataOutput : Output;

    final compression : Compression;

    final payload : Array<Payload>;

    public function new(_output : Output, _compression : Compression)
    {
        serialiser  = new Serializer();
        payload     = [];
        compression = _compression;
        headOutput  = _output;
        dataOutput  = switch compression {
            case None: _output;
            case Deflate(_level, _chunkSize): new OutputCompressor(_output, _level, _chunkSize);
        }
    }

    public function add(_payload : Payload)
    {
        payload.push(_payload);
    }

    public function commit()
    {
        trace('committing parcel to output');

        writeHeader();
        writePayload();
    }

    public function close()
    {
        dataOutput.close();
    }

    function writeHeader()
    {
        headOutput.writeString('PRCL');

        switch compression
        {
            case None:
                headOutput.writeByte(0);
            case Deflate(_level, _chunkSize):
                headOutput.writeByte(1);
                headOutput.writeByte(_level);
                headOutput.writeInt32(_chunkSize);
        }

        headOutput.writeInt32(payload.length);

        trace('header written');
    }

    function writePayload()
    {
        for (entry in payload)
        {
            trace('writing entry');
            switch entry
            {
                case SerialisedResource(_resource):
                    final bytes = serialiser.serialize(_resource);
                    final len   = bytes.length;

                    dataOutput.writeByte(0);
                    dataOutput.writeInt32(len);
                    dataOutput.write(bytes);

                    trace('resource ${ _resource.id }');
                case ImageData(_bytes, _format, _name):
                    dataOutput.writeByte(1);
                    dataOutput.writeByte(_format);
                    dataOutput.writeInt32(_name.length);
                    dataOutput.writeString(_name);
                    dataOutput.writeInt32(_bytes.length);
                    dataOutput.write(_bytes);

                    trace('image $_format');
            }
        }
    }
}