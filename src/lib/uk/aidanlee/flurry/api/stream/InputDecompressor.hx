package uk.aidanlee.flurry.api.stream;

import haxe.zip.Uncompress;
import haxe.io.BytesBuffer;
import haxe.io.Error;
import haxe.io.Bytes;
import haxe.io.Input;
import haxe.io.Eof;

class InputDecompressor
{
    final bufferSize = 64000000;

    final input : Input;

    final buffer : Bytes;

    public function new(_input : Input)
    {
        input  = _input;
        buffer = Bytes.alloc(bufferSize);
    }

    public function inflate() : Bytes
    {
        final acc = new BytesBuffer();

        try
        {
            while (true)
            {
                final len  = input.readInt32();
                final read = input.readBytes(buffer, 0, len);

                if (read != len)
                {
                    throw Error.Blocked;
                }

                acc.add(Uncompress.run(buffer, len));
            }
        } catch (e : Eof) { }

        input.close();

        return acc.getBytes();
    }
}