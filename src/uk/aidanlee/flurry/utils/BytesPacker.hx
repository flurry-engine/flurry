package uk.aidanlee.flurry.utils;

import uk.aidanlee.flurry.api.resources.Resource.ShaderType;
import haxe.io.Bytes;

enum AlignmentType
{
    Std140;
    Std430;
    Dx11;
}

class BytesPacker
{
    public static function getPosition(_aligment : AlignmentType, _values : Array<{ name : String, type : String }>, _requested : String) : Int
    {
        final registerMaxByteSize = 16;

        var registerByteSize = 0;
        var bufferByteSize   = 0;

        for (val in _values)
        {
            var typeSize = switch (ShaderType.createByName(val.type))
            {
                case Matrix4: 64;
                case Vector4: 16;
                case Int, Float: 4;
            }

            if (registerByteSize == 0 || registerByteSize >= registerMaxByteSize)
            {
                if (val.name == _requested)
                {
                    return bufferByteSize;
                }

                bufferByteSize += typeSize;
                registerByteSize = typeSize;
            }
            else
            {
                if (registerByteSize + typeSize <= registerMaxByteSize)
                {
                    if (val.name == _requested)
                    {
                        return bufferByteSize;
                    }

                    // Can fit into the register
                    registerByteSize += typeSize;
                    bufferByteSize += typeSize;
                }
                else
                {
                    // Can't fit into the register, pad the buffer to fill the current register and start a new one.
                    bufferByteSize += 16 - bufferByteSize;

                    if (val.name == _requested)
                    {
                        return bufferByteSize;
                    }

                    bufferByteSize += typeSize;
                    registerByteSize = 0;
                }
            }
        }

        return 0;
    }

    public static function allocateBytes(_alignment : AlignmentType, _values : Array<{ name : String, type : String }>) : Bytes
    {
        final registerMaxByteSize = 16;

        var registerByteSize = 0;
        var bufferByteSize   = 0;

        for (val in _values)
        {
            var typeSize = switch (ShaderType.createByName(val.type))
            {
                case Matrix4: 64;
                case Vector4: 16;
                case Int, Float: 4;
            }

            if (registerByteSize == 0 || registerByteSize >= registerMaxByteSize)
            {
                bufferByteSize += typeSize;
                registerByteSize = typeSize;
            }
            else
            {
                if (registerByteSize + typeSize <= registerMaxByteSize)
                {
                    // Can fit into the register
                    registerByteSize += typeSize;
                    bufferByteSize += typeSize;
                }
                else
                {
                    // Can't fit into the register, pad the buffer to fill the current register and start a new one.
                    bufferByteSize += 16 - bufferByteSize;
                    bufferByteSize += typeSize;

                    registerByteSize = 0;
                }
            }
        }

        // Finally, pad to nearest 16 bytes to make HLSL happy.
        if (registerByteSize % 16 != 0)
        {
            bufferByteSize += (16 - registerByteSize);
        }

        return Bytes.alloc(bufferByteSize);
    }
}
