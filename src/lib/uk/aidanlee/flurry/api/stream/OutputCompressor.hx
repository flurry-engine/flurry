package uk.aidanlee.flurry.api.stream;

import haxe.zip.Compress;
import haxe.io.Bytes;
import haxe.io.Output;

/**
 * Will apply DEFLATE compression to data passing through the output stream.
 * Use `InputDecompressor` to read the data back.
 */
class OutputCompressor extends Output
{
    /**
     * Size of the staging buffer.
     */
    final bufferSize : Int;

    /**
     * Stream compressed data will be output to.
     */
    final output : Output;

    /**
     * Staging buffer which will store added data until compression and output time.
     */
    final buffer : Bytes;

    /**
     * DEFLATE compression level (0 - 9).
     */
    final level : Int;

    /**
     * Current length and write position into the staging buffer.
     */
    var cursor : Int;

    public function new(_output : Output, _level : Int, _bufferSize : Int)
    {
        output     = _output;
        level      = _level;
        bufferSize = _bufferSize;
        buffer     = Bytes.alloc(bufferSize);
        cursor     = 0;
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
        final deflat = Compress.run(bytes, level);

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