package uk.aidanlee.flurry.api.stream;

import haxe.zip.Compress;
import haxe.io.Bytes;
import haxe.io.Output;

class OutputCompressor extends Output
{
    final bufferSize = 64000000;

    final output : Output;

    final buffer : Bytes;

    var cursor : Int;

    public function new(_output : Output)
    {
        output = _output;
        buffer = Bytes.alloc(bufferSize);
        cursor = 0;
    }

    override function writeByte(_b : Int)
    {
        if (cursor >= bufferSize) {
            flush();
        }

        buffer.set(cursor++, _b);
    }

    override function flush()
    {
        final bytes  = if (cursor >= bufferSize) buffer else buffer.sub(0, cursor);
        final deflat = Compress.run(bytes, 9);

        output.writeInt32(deflat.length);
        output.write(deflat);

        cursor = 0;
    }

    override function close()
    {
        if (cursor > 0)
        {
            flush();
        }
        
        output.close();
    }
}