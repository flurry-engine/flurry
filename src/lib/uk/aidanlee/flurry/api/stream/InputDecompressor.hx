package uk.aidanlee.flurry.api.stream;

import haxe.zip.Uncompress;
import haxe.io.Bytes;
import haxe.io.Input;

/**
 * Allows reading from a DEFLATE compressed chunk stream.
 */
class InputDecompressor extends Input
{
    /**
     * Input to read from.
     */
    final input : Input;

    final bufferSize : Int;

    final buffer : Bytes;

    var cursor : Int;

    var length : Int;

    public function new(_input : Input, _bufferSize : Int)
    {
        input      = _input;
        bufferSize = _bufferSize;
        buffer     = Bytes.alloc(bufferSize);
        cursor     = 0;
        length     = 0;
    }

    override function readByte() : Int
    {
        if (cursor >= length)
        {
            readChunk();
        }

        return buffer.get(cursor++);
    }

    function readChunk()
    {
        final len     = input.readInt32();
        final staging = Bytes.alloc(len);
        final read    = input.readBytes(staging, 0, len);

        length = inflate(staging);
        cursor = 0;
    }

    function inflate(_source : Bytes) : Int
    {
#if cpp
        // Slightly modified cpp decompress code to decompress right into the buffer.
        // Skips an extra allocation and blit this way.
        final u = new Uncompress(null);
        var srcPos = 0;
        var dstPos = 0;
        
		u.setFlushMode(SYNC);
        while (true)
        {
			final r = u.execute(_source, srcPos, buffer, dstPos);
            srcPos += r.read;
            dstPos += r.write;

            if (r.done)
            {
				break;
            }
		}
        u.close();

        return dstPos;
#else
        final decompressed = Uncompress.run(_source);

        buffer.blit(0, decompressed, 0, decompressed.length);

        return decompressed.length;
#end
    }
}