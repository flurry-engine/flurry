package uk.aidanlee.flurry.api.stream;

import haxe.io.Bytes;
import haxe.io.Output;
import hxbit.Serializer;
import uk.aidanlee.flurry.api.resources.Resource;

enum Payload
{
    SerialisedResource(_resource : Resource);
    ImageData(_bytes : Bytes, _format : ImageFormat, _width : Int, _height : Int, _name : String);
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

    /**
     * Queue a resource for serialisation.
     * @param _payload Item to add.
     */
    public function add(_payload : Payload)
    {
        payload.push(_payload);
    }

    /**
     * Write the header and all resources to the stream.
     */
    public function commit()
    {
        writeHeader();
        writePayload();
    }

    /**
     * Closes the output stream provided in the constructor.
     */
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
    }

    function writePayload()
    {
        for (entry in payload)
        {
            switch entry
            {
                case SerialisedResource(_resource):
                    final bytes = serialiser.serialize(_resource);
                    final len   = bytes.length;

                    dataOutput.writeByte(0);
                    dataOutput.writeInt32(len);
                    dataOutput.write(bytes);
                case ImageData(_bytes, _format, _width, _height, _name):
                    dataOutput.writeByte(1);
                    dataOutput.writeByte(_format);
                    dataOutput.writeInt32(_width);
                    dataOutput.writeInt32(_height);
                    dataOutput.writeInt32(_name.length);
                    dataOutput.writeString(_name);
                    dataOutput.writeInt32(_bytes.length);
                    dataOutput.write(_bytes);
            }
        }
    }
}