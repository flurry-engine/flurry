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

/**
 * Calculate the number of bytes the provided string and its prefixed length header would consume.
 * This function probably doesn't work with non english characters.
 * @param _string Input string to calculate the size for.
 */
function prefixedStringSize(_string : String)
{
    return 4 + _string.length;
}