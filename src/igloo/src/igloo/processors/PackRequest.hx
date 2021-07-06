package igloo.processors;

import hx.files.Path;
import haxe.io.Bytes;

enum PackRequest
{
    /**
     * Pack the image found at the provided absolute path.
     * It should be a png, jpg, tga, or bmp. Other formats are not supported.
     */
    Image(id : String, path : Path);

    /**
     * Pack the provided bytes object.
     * The width, height, and pixel format must be provided.
     */
    Bytes(id : String, bytes : Bytes, width : Int, height : Int, format : PixelFormat);
}