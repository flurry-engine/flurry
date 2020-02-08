package uk.aidanlee.flurry.api.gpu.geometry.shapes;

import uk.aidanlee.flurry.api.buffers.UInt16BufferData;
import uk.aidanlee.flurry.api.buffers.Float32BufferData;
import uk.aidanlee.flurry.api.gpu.geometry.VertexBlob.VertexBlobBuilder;
import uk.aidanlee.flurry.api.importers.bmfont.BitmapFontData;
import uk.aidanlee.flurry.api.gpu.geometry.Geometry;
import uk.aidanlee.flurry.api.maths.Vector2;
import uk.aidanlee.flurry.api.maths.Vector3;

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
    var position : Vector3;
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
    var cursorPosition : Vector3;

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
        _options.data = UnIndexed(new VertexBlobBuilder().vertexBlob());

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
        final lines = text.split('\n');

        var count = 0;
        for (line in lines)
        {
            count += line.length;
        }

        final vtxBuffer = new Float32BufferData(count * 4 * 9);
        final idxBuffer = new UInt16BufferData(count * 6);
        var vtxOffset = 0;
        var idxOffset = 0;
        var baseIndex = 0;

        var texWidth  = 1;
        var texHeight = 1;
        switch textures
        {
            case Textures(_textures):
                texWidth  = _textures[0].width;
                texHeight = _textures[0].height;
            case _:
        }

        for (line in lines)
        {
            for (i in 0...line.length)
            {
                final char = font.chars.get(line.charCodeAt(i));

                // Move the cursor by the kerning amount.
                if (i != 0)
                {
                    if (font.kernings.exists(char.id))
                    {
                        final map   = font.kernings.get(char.id);
                        final value = map.get(line.charCodeAt(i - 1));

                        if (value != null)
                        {
                            cursorPosition.x += value;
                        }
                    }
                }

                // Add the character quad.
                addCharacter(vtxBuffer, idxBuffer, vtxOffset, idxOffset, baseIndex, char, cursorPosition.x, cursorPosition.y, texWidth, texHeight);
                vtxOffset += 4 * 9;
                idxOffset += 6;
                baseIndex += 4;

                // Move the cursor to the next characters position.
                cursorPosition.x += char.xAdvance;
            }

            cursorPosition.y += font.lineHeight;
            cursorPosition.x  = position.x;
        }

        data = Indexed(new VertexBlob(vtxBuffer), new IndexBlob(idxBuffer));
    }

    /**
     * Create a textured quad for a character.
     * @param _char Character to draw.
     * @param _x Top left start x for the quad.
     * @param _y Top left start y for the quad.
     */
    function addCharacter(
        _vtxBuffer : Float32BufferData,
        _idxBuffer : UInt16BufferData,
        _vtxOffset : Int,
        _idxOffset : Int,
        _baseIndex : Int,
        _char : Character,
        _x : Float,
        _y : Float,
        _texWidth : Float,
        _texHeight : Float)
    {
        // bottom left
        _vtxBuffer[_vtxOffset++] = _x + _char.xOffset;
        _vtxBuffer[_vtxOffset++] = _y + _char.yOffset + _char.height;
        _vtxBuffer[_vtxOffset++] = 0;
        _vtxBuffer[_vtxOffset++] = 1;
        _vtxBuffer[_vtxOffset++] = 1;
        _vtxBuffer[_vtxOffset++] = 1;
        _vtxBuffer[_vtxOffset++] = 1;
        _vtxBuffer[_vtxOffset++] = _char.x / _texWidth;
        _vtxBuffer[_vtxOffset++] = (_char.y + _char.height) / _texHeight;

        // Bottom right
        _vtxBuffer[_vtxOffset++] = _x + _char.xOffset + _char.width;
        _vtxBuffer[_vtxOffset++] = _y + _char.yOffset + _char.height;
        _vtxBuffer[_vtxOffset++] = 0;
        _vtxBuffer[_vtxOffset++] = 1;
        _vtxBuffer[_vtxOffset++] = 1;
        _vtxBuffer[_vtxOffset++] = 1;
        _vtxBuffer[_vtxOffset++] = 1;
        _vtxBuffer[_vtxOffset++] = (_char.x + _char.width) / _texWidth;
        _vtxBuffer[_vtxOffset++] = (_char.y + _char.height) / _texHeight;

        // Top left
        _vtxBuffer[_vtxOffset++] = _x + _char.xOffset;
        _vtxBuffer[_vtxOffset++] = _y + _char.yOffset;
        _vtxBuffer[_vtxOffset++] = 0;
        _vtxBuffer[_vtxOffset++] = 1;
        _vtxBuffer[_vtxOffset++] = 1;
        _vtxBuffer[_vtxOffset++] = 1;
        _vtxBuffer[_vtxOffset++] = 1;
        _vtxBuffer[_vtxOffset++] = _char.x / _texWidth;
        _vtxBuffer[_vtxOffset++] = _char.y / _texHeight;

        // Top right
        _vtxBuffer[_vtxOffset++] = (_x + _char.xOffset) + _char.width;
        _vtxBuffer[_vtxOffset++] = _y + _char.yOffset;
        _vtxBuffer[_vtxOffset++] = 0;
        _vtxBuffer[_vtxOffset++] = 1;
        _vtxBuffer[_vtxOffset++] = 1;
        _vtxBuffer[_vtxOffset++] = 1;
        _vtxBuffer[_vtxOffset++] = 1;
        _vtxBuffer[_vtxOffset++] = (_char.x + _char.width) / _texWidth;
        _vtxBuffer[_vtxOffset++] = _char.y / _texHeight;

        // indicies
        _idxBuffer[_idxOffset++] = _baseIndex + 0;
        _idxBuffer[_idxOffset++] = _baseIndex + 1;
        _idxBuffer[_idxOffset++] = _baseIndex + 2;
        _idxBuffer[_idxOffset++] = _baseIndex + 2;
        _idxBuffer[_idxOffset++] = _baseIndex + 1;
        _idxBuffer[_idxOffset++] = _baseIndex + 3;
    }
}
