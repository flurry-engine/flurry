package uk.aidanlee.flurry.api.gpu.geometry.shapes;

import uk.aidanlee.flurry.api.importers.bmfont.BitmapFontData;
import uk.aidanlee.flurry.api.gpu.geometry.Geometry;
import uk.aidanlee.flurry.api.maths.Vector;

typedef TextGeometryOptions = {
    > GeometryOptions,

    /**
     * The bitmap font to draw using.
     */
    var font : BitmapFontData;

    /**
     * The string to draw.
     */
    var text : String;

    /**
     * The starting (top left aligned) position.
     */
    var position : Vector;
}

/**
 * Geometry class which will draw a string with a bitmap font.
 */
class TextGeometry extends Geometry
{
    /**
     * Parsed bitmap font data.
     */
    public var font : BitmapFontData;

    inline function set_font(_font : BitmapFontData) : BitmapFontData {
        font = _font;

        if (autoUpdateGeometry)
        {
            generateGeometry();
        }

        return font;
    }

    /**
     * The string to draw.
     */
    public var text (default, set) : String;

    inline function set_text(_text : String) : String {
        text = _text;

        if (autoUpdateGeometry)
        {
            generateGeometry();
        }

        return text;
    }

    /**
     * Cursors position for creating quads.
     */
    var cursorPosition : Vector;

    /**
     * If the listeners should rebuild the geometry, is set to true for the constructor.
     */
    var autoUpdateGeometry : Bool;

    /**
     * Create a new geometry object which will display text.
     * @param _options Text geometry options.
     */
    public function new(_options : TextGeometryOptions)
    {
        super(_options);

        cursorPosition     = _options.position.clone();
        autoUpdateGeometry = false;
        text = _options.text;
        font = _options.font;
        autoUpdateGeometry = true;

        generateGeometry();
    }

    /**
     * Remove any vertices from this geometry and create it for the text.
     */
    function generateGeometry()
    {
        // Remove all verticies.
        vertices.resize(0);

        // Generate all of the text geometry.
        for (line in text.split('\n'))
        {
            for (i in 0...line.length)
            {
                var char = font.chars.get(line.charCodeAt(i));

                // Move the cursor by the kerning amount.
                if (i != 0)
                {
                    var map = font.kernings.get(char.id);
                    if (map != null)
                    {
                        var value = map.get(line.charCodeAt(i - 1));
                        if (value != null)
                        {
                            cursorPosition.x += value;
                        }
                    }
                }

                // Add the character quad.
                addCharacter(char, cursorPosition.x, cursorPosition.y);

                // Move the cursor to the next characters position.
                cursorPosition.x += char.xAdvance;
            }

            cursorPosition.y += font.lineHeight;
            cursorPosition.x  = position.x;
        }
    }

    /**
     * Create a textured quad for a character.
     * @param _char Character to draw.
     * @param _x Top left start x for the quad.
     * @param _y Top left start y for the quad.
     */
    function addCharacter(_char : Character, _x : Float, _y : Float)
    {
        var tlPos = new Vector((_x + _char.xOffset)              , _y + _char.yOffset);
        var trPos = new Vector((_x + _char.xOffset) + _char.width, _y + _char.yOffset);
        var blPos = new Vector((_x + _char.xOffset)              , _y + _char.yOffset + _char.height);
        var brPos = new Vector((_x + _char.xOffset) + _char.width, _y + _char.yOffset + _char.height);

        var tlUV = new Vector(_char.x / textures[0].width                , _char.y / textures[0].height);
        var trUV = new Vector((_char.x + _char.width) / textures[0].width, _char.y / textures[0].height);
        var blUV = new Vector(_char.x / textures[0].width                , (_char.y + _char.height) / textures[0].height);
        var brUV = new Vector((_char.x + _char.width) / textures[0].width, (_char.y + _char.height) / textures[0].height);

        vertices.push(new Vertex( blPos, color, blUV ));
        vertices.push(new Vertex( brPos, color, brUV ));
        vertices.push(new Vertex( tlPos, color, tlUV ));

        vertices.push(new Vertex( tlPos, color, tlUV ));
        vertices.push(new Vertex( brPos, color, brUV ));
        vertices.push(new Vertex( trPos, color, trUV ));
    }
}
