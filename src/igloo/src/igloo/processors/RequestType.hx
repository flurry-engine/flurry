package igloo.processors;

import haxe.io.Bytes;
import hx.files.Path;

enum RequestType
{
    /**
     * Pack the image found at the provided absolute path.
     * It should be a png, jpg, tga, or bmp. Other formats are not supported.
     */
    PackImage(id : String, path : Path);

    /**
     * Pack the provided bytes object.
     * The width, height, and pixel format must be provided.
     */
    PackBytes(id : String, bytes : Bytes, width : Int, height : Int, format : PixelFormat);

    /**
     * Indicate that the provided asset does not need to be packed in an atlas page.
     * The request contains the name of the resource.
     */
    UnPacked(_name : String);
}