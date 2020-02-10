package uk.aidanlee.flurry.api.importers.bmfont;

/**
 * Describes on character in the font. There is one for each included character in the font.
 */
class Character
{
    /**
     * The ID of the character.
     */
    public final id : Int;

    /**
     * The left position of the character image in the texture.
     */
    public final x : Float;

    /**
     * The top position of the character image in the texture.
     */
    public final y : Float;

    /**
     * The width of the character image in the texture.
     */
    public final width : Float;

    /**
     * The height of the character image in the texture.
     */
    public final height : Float;

    /**
     * How much the current position should be offset when copying the image from the texture to the screen.
     */
    public final xOffset : Float;

    /**
     * How much the current position should be offset when copying the image from the texture to the screen.
     */
    public final yOffset : Float;

    /**
     * How much the current position should be advanced after drawing the character.
     */
    public final xAdvance : Float;

    /**
     * The texture page where the character image is found.
     */
    public final page : Int;

    public function new(
        _id       : Int,
        _x        : Float,
        _y        : Float,
        _width    : Float,
        _height   : Float,
        _xOffset  : Float,
        _yOffset  : Float,
        _xAdvance : Float,
        _page     : Int
    )
    {
        id       = _id;
        x        = _x;
        y        = _y;
        width    = _width;
        height   = _height;
        xOffset  = _xOffset;
        yOffset  = _yOffset;
        xAdvance = _xAdvance;
        page     = _page;
    }
}

/**
 * Holds data on how the font was generated and information common to all characters.
 */
class BitmapFontData
{
    /**
     * The name of the true type font this bitmap was generated from.
     */
    public var face : String;

    /**
     * The size of the true type font this bitmap was generated from.
     */
    public var pointSize : Float;

    /**
     * The number of pixels from the absolute top of the line to the base of the characters.
     */
    public var baseSize : Float;

    /**
     * All of the pages in this bitmap font.
     * 
     * Anonymouse structure maps the ID to the texture file name.
     */
    public var pages : Array<{ id : Int, file : String }>;

    /**
     * The distance in pixels between each line of text.
     */
    public var lineHeight : Float;

    /**
     * The number of characters in this bitmap font.
     */
    public var charCount : Int;

    /**
     * Map of character IDs to character 
     */
    public var chars : Map<Int, Character>;

    /**
     * The total number of kerning mappings in this bitmap font.
     */
    public var kerningCount : Int;

    /**
     * Kerning information is used to adjust the distance between certain characters.
     * 
     * This nested map contains the kerning values between two characters.
     * 
     * The key in the first map is the ID of the first character, the key in the sub map is the ID of the second character.
     * The float in the value of that sub map is how much the x position should be adjusted between those two characters.
     */
    public var kernings : Map<Int, Map<Int, Float>>;

    public function new(
        _face : String,
        _pointSize : Float,
        _baseSize : Float,
        _pages : Array<{ id : Int, file : String }>,
        _lineHeight : Float,
        _charCount : Int,
        _chars : Map<Int, Character>,
        _kerningCount : Int,
        _kernings : Map<Int, Map<Int, Float>>
    )
    {
        face         = _face;
        pointSize    = _pointSize;
        baseSize     = _baseSize;
        pages        = _pages;
        lineHeight   = _lineHeight;
        charCount    = _charCount;
        chars        = _chars;
        kerningCount = _kerningCount;
        kernings     = _kernings;
    }
}
