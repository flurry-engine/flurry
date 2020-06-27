package uk.aidanlee.flurry.api.stream;

import haxe.zip.Uncompress;
import haxe.io.BytesBuffer;
import haxe.io.Error;
import haxe.io.Bytes;
import haxe.io.Input;
import haxe.io.Eof;

/**
 * Uncompress a Zlib compressed input stream.
 */
class InputDecompressor
{
    /**
     * Size of the staging buffer.
     */
    final bufferSize = 64000000;

    /**
     * Input to read from.
     */
    final input : Input;

    public function new(_input : Input)
    {
        input = _input;
    }

    public function inflate() : Bytes
    {
        final accumulator = new BytesBuffer();
        final buffer      = Bytes.alloc(bufferSize);

        try
        {
            while (true)
            {
                final len   = input.readInt32();
                final level = input.readByte();
                final read  = input.readBytes(buffer, 0, len);

                if (read != len)
                {
                    throw Error.Blocked;
                }

                accumulator.add(if (level > 0) Uncompress.run(buffer, read) else buffer.sub(0, read));
            }
        } catch (e : Eof) { }

        input.close();

        return accumulator.getBytes();
    }
}