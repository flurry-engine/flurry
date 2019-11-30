package uk.aidanlee.flurry.api.importers.textureatlas;

import uk.aidanlee.flurry.api.maths.Rectangle;
import uk.aidanlee.flurry.api.maths.Vector2;

enum TextureAtlasFormat
{
    Alpha;
    Intensity;
    LuminanceAlpha;
    RGB565;
    RGBA4444;
    RGB888;
    RGBA8888;
}

enum TextureAtlasFilter
{
    Nearest;
    Linear;
    MipMap;
    MipMapNearestNearest;
    MipMapLinearNearest;
    MipMapNearestLinear;
    MipMapLinearLinear;
}

enum TextureAtlasRepeat
{
    X;
    Y;
    XY;
    none;
}

class TextureAtlas
{
    /**
     * The name of the image file for this texture atlas.
     */
    public final name : String;

    /**
     * The size of the image texture.
     */
    public final size : Vector2;

    /**
     * The texture pixel format.
     */
    public final format : TextureAtlasFormat;

    /**
     * The min and mag filter type for the texture.
     * [0] min filter.
     * [1] mag filter.
     */
    public final filter : Array<TextureAtlasFilter>;

    /**
     * Texture repeat type.
     */
    public final repeat : TextureAtlasRepeat;

    /**
     * All of the individual images in the atlas.
     */
    public final frames : Array<TextureAtlasFrame>;

    public function new(_name : String, _size : Vector2, _format : TextureAtlasFormat, _filter : Array<TextureAtlasFilter>, _repeat : TextureAtlasRepeat, _frames : Array<TextureAtlasFrame>)
    {
        name   = _name;
        size   = _size;
        format = _format;
        filter = _filter;
        repeat = _repeat;
        frames = _frames;
    }

    /**
     * Returns the first frame with the specified name.
     * @param _name Frame name.
     * @return TextureAtlasFrame
     */
    public function findRegion(_name : String) : TextureAtlasFrame
    {
        for (frame in frames)
        {
            if (frame.name == _name)
            {
                return frame;
            }
        }

        return null;
    }

    /**
     * Returns the frame with the specified name and index.
     * @param _name  Frame name.
     * @param _index Frame index.
     * @return TextureAtlasFrame
     */
    public function findRegionID(_name : String, _index : Int) : TextureAtlasFrame
    {
        for (frame in frames)
        {
            if (frame.name == _name && frame.index == _index)
            {
                return frame;
            }
        }

        return null;
    }

    /**
     * Returns all regions with the specified name.
     * @param _name Frame name.
     * @return Array<TextureAtlasFrame>
     */
    public function findRegions(_name : String) : Array<TextureAtlasFrame>
    {
        var foundFrames = new Array<TextureAtlasFrame>();

        for (frame in frames)
        {
            if (frame.name == _name)
            {
                foundFrames.push(frame);
            }
        }

        return foundFrames;
    }
}

class TextureAtlasFrame
{
    /**
     * The name of the frame.
     */
    public final name : String;

    /**
     * If the frame is rotated 90 degrees anti-clockwise.
     */
    public final rotated : Bool;

    /**
     * The region in the texture of this frame.
     */
    public final region : Rectangle;

    /**
     * The original width and height of the frame, Before any scaling.
     */
    public final original : Vector2;

    /**
     * Offset of this frame.
     */
    public final offset : Vector2;

    /**
     * Frame index. Unique ID so frame names can be the same.
     */
    public final index : Int;

    public function new(_name : String, _rotated : Bool, _region : Rectangle, _original : Vector2, _offset : Vector2, _index : Int)
    {
        name     = _name;
        rotated  = _rotated;
        region   = _region;
        original = _original;
        offset   = _offset;
        index    = _index;
    }
}
