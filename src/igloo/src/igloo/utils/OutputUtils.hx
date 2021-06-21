package igloo.utils;

import haxe.io.Bytes;
import haxe.io.Output;

function writePrefixedString(_output : Output, _string : String)
{
    final bytes  = Bytes.ofString(_string);
    final length = bytes.length;

    _output.writeInt32(length);
    _output.write(bytes);
}