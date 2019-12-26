package uk.aidanlee.flurry.api.gpu.textures;

import uk.aidanlee.flurry.api.resources.Resource.ImageResource;

enum ImageFlip
{
    None;
    Horizontal;
    Vertical;
    Diagonal;
}

/**
 * Immutable region of an image resource.
 */
@:structInit class ImageRegion
{
    public final image : ImageResource;

    public final x : Int;

    public final y : Int;

    public final width : Int;

    public final height : Int;

    public final u1 : Float;

    public final v1 : Float;

    public final u2 : Float;

    public final v2 : Float;

    public function new(_image : ImageResource, _x : Int = 0, _y : Int = 0, _width : Int, _height : Int, _flip : ImageFlip = None)
    {
        image  = _image;
        x      = _x;
        y      = _y;
        width  = _width;
        height = _height;

        switch _flip
        {
            case None:
                u1 = x / image.width;
                v1 = y / image.height;
                u2 = (x + width) / image.width;
                v2 = (y + height) / image.height;
            case Horizontal:
                u1 = (x + width) / image.width;
                v1 = y / image.height;
                u2 = x / image.width;
                v2 = (y + height) / image.height;
            case Vertical:
                u1 = x / image.width;
                v1 = (y + height) / image.height;
                u2 = (x + width) / image.width;
                v2 = y / image.height;
            case Diagonal:
                u1 = (x + width) / image.width;
                v1 = (y + height) / image.height;
                u2 = x / image.width;
                v2 = y / image.height;
        }
    }
}