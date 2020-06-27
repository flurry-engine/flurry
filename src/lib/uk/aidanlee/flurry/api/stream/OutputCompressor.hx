package uk.aidanlee.flurry.api.stream;

import haxe.zip.Compress;
import haxe.io.Bytes;
import haxe.io.Output;

/**
 * Will apply Zlib compression to data passing through the output stream.
 * Use `InputDecompressor` to read the data back.
 */
class OutputCompressor extends Output
{
    /**
     * Size of the staging buffer.
     */
    final bufferSize = 64000000;

    /**
     * Stream compressed data will be output to.
     */
    final output : Output;

    /**
     * Staging buffer which will store added data until compression and output time.
     */
    final buffer : Bytes;

    /**
     * Zlib compression level (0 - 9).
     * 0 - no compression applied.
     * 9 - Maximum compression.
     */
    final level : Int;

    /**
     * Current length and write position into the staging buffer.
     */
    var cursor : Int;

    public function new(_output : Output, _level : Int)
    {
        output = _output;
        level  = _level;
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
        final deflat = if (level > 0) Compress.run(bytes, level) else bytes;

        output.writeInt32(deflat.length);
        output.writeByte(level);
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