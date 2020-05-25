package uk.aidanlee.flurry.api.gpu.geometry.shapes;

import uk.aidanlee.flurry.api.gpu.batcher.Batcher;
import uk.aidanlee.flurry.api.gpu.state.BlendState;
import uk.aidanlee.flurry.api.gpu.state.ClipState;
import uk.aidanlee.flurry.api.gpu.textures.SamplerState;
import uk.aidanlee.flurry.api.resources.Resource.ImageFrameResource;
import uk.aidanlee.flurry.api.buffers.UInt16BufferData;
import uk.aidanlee.flurry.api.buffers.Float32BufferData;
import uk.aidanlee.flurry.api.importers.bmfont.BitmapFontData;
import uk.aidanlee.flurry.api.gpu.geometry.Geometry;

using Safety;

typedef TextGeometryOptions = {
    var font : BitmapFontData;
    var text : String;
    var texture : ImageFrameResource;
    var ?sampler : SamplerState;
    var ?shader : GeometryShader;
    var ?uniforms : GeometryUniforms;
    var ?depth : Float;
    var ?clip : ClipState;
    var ?blend : BlendState;
    var ?batchers : Array<Batcher>;
    var ?x : Float;
    var ?y : Float;
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

        if (!ignore)
        {
            data = generateGeometry(font, text, position.x, position.y, fontTexture.width, fontTexture.height);
        }

        return font;
    }

    /**
     * The string to draw.
     */
    public var text (default, set) : String;

    inline function set_text(_text : String) : String {
        text = _text;

        if (!ignore)
        {
            data = generateGeometry(font, text, position.x, position.y, fontTexture.width, fontTexture.height);
        }

        return text;
    }

    final fontTexture : ImageFrameResource;

    var ignore = true;

    /**
     * Create a new geometry object which will display text.
     * @param _options Text geometry options.
     */
    public function new(_options : TextGeometryOptions)
    {
        super({
            data : generateGeometry(_options.font, _options.text, _options.x.or(0), _options.y.or(0), _options.texture.width, _options.texture.height),
            textures : Textures([ _options.texture ]),
            samplers : _options.sampler == null ? None : Samplers([ _options.sampler ]),
            shader   : _options.shader,
            uniforms : _options.uniforms,
            depth    : _options.depth,
            clip     : _options.clip,
            blend    : _options.blend,
            batchers : _options.batchers
        });

        font        = _options.font;
        text        = _options.text;
        fontTexture = _options.texture;

        ignore = false;
    }

    /**
     * Remove any vertices from this geometry and create it for the text.
     */
    function generateGeometry(_font : BitmapFontData, _text: String, _xPos : Float, _yPos : Float, _texWidth : Int, _texHeight : Int) : GeometryData
    {
        final lines = _text.split('\n');
        final baseX = _xPos;

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

        for (line in lines)
        {
            for (i in 0...line.length)
            {
                final char = _font.chars.get(line.charCodeAt(i));

                // Move the cursor by the kerning amount.
                if (i != 0)
                {
                    if (_font.kernings.exists(char.id))
                    {
                        final map   = _font.kernings.get(char.id);
                        final value = map.get(line.charCodeAt(i - 1));

                        if (value != null)
                        {
                            _xPos += value;
                        }
                    }
                }

                // Add the character quad.
                addCharacter(vtxBuffer, idxBuffer, vtxOffset, idxOffset, baseIndex, char, _xPos, _yPos, _texWidth, _texHeight);
                vtxOffset += 4 * 9;
                idxOffset += 6;
                baseIndex += 4;

                // Move the cursor to the next characters position.
                _xPos += char.xAdvance;
            }

            _yPos += _font.lineHeight;
            _xPos  = baseX;
        }

        return Indexed(new VertexBlob(vtxBuffer), new IndexBlob(idxBuffer));
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
