package igloo.processors;

import haxe.io.Bytes;
import hx.files.Path;

enum RequestType
{
    /**
     * Pack the image found at the provided absolute path.
     * It should be a png, jpg, tga, or bmp. Other formats are not supported.
     */
    PackImage(path : Path);

    /**
     * Pack the provided bytes object.
     * The width, height, and pixel format must be provided.
     */
    PackBytes(bytes : Bytes, width : Int, height : Int, format : PixelFormat);
}