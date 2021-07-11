package uk.aidanlee.flurry.api.gpu.geometry.shapes;

import uk.aidanlee.flurry.api.resources.loaders.MsdfFontLoader.FontGlyph;
import uk.aidanlee.flurry.api.resources.loaders.MsdfFontLoader.MsdfFontResource;
import uk.aidanlee.flurry.api.maths.Vector4;
import haxe.ds.ReadOnlyArray;
import haxe.Exception;
import haxe.io.StringInput;
import uk.aidanlee.flurry.api.gpu.state.BlendState;
import uk.aidanlee.flurry.api.gpu.state.ClipState;
import uk.aidanlee.flurry.api.gpu.batcher.Batcher;
import uk.aidanlee.flurry.api.gpu.geometry.Geometry;
import uk.aidanlee.flurry.api.gpu.geometry.IndexBlob.IndexBlobBuilder;
import uk.aidanlee.flurry.api.gpu.geometry.VertexBlob.VertexBlobBuilder;
import uk.aidanlee.flurry.api.gpu.textures.SamplerState;

using Safety;

/**
 * Geometry class which will draw a string with a bitmap font.
 */
class TextGeometry extends Geometry
{
    /**
     * Parsed bitmap font data.
     */
    public var font : MsdfFontResource;

    inline function set_font(_font : MsdfFontResource) : MsdfFontResource {
        font = _font;

        if (!ignore)
        {
            data = generateGeometry(font, text);
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
            data = generateGeometry(font, text);
        }

        return text;
    }

    /**
     * The pixel size to draw this text at.
     */
    public var size (default, set) : Float;

    inline function set_size(_size : Float) : Float {
        size = _size;

        scale.set_xy(size, size);

        return size;
    }

    var ignore = true;

    /**
     * Create a new geometry object which will display text.
     * @param _options Text geometry options.
     */
    public function new(_options : TextGeometryOptions)
    {
        super({
            data     : generateGeometry(_options.font, _options.text),
            textures : Some([ _options.font.page ]),
            samplers : Some([ _options.sampler ]),
            shader   : _options.shader,
            uniforms : _options.uniforms,
            depth    : _options.depth,
            clip     : _options.clip,
            blend    : _options.blend,
            batchers : _options.batchers
        });

        font       = _options.font;
        text       = _options.text;
        size       = _options.size;
        position.x = _options.x;
        position.y = _options.y;

        ignore = false;
    }

    public function rebuild(_lines : ReadOnlyArray<String>, _colour : Vector4)
    {
        final vtxBuilder = new VertexBlobBuilder();
        final idxBuilder = new IndexBlobBuilder();

        var x   = 0.0;
        var y   = 0.0;
        var idx = 0;

        for (line in _lines)
        {
            for (i in 0...line.length)
            {
                final code = line.charCodeAt(i).unsafe();
                final char = font.glyphs[code].unsafe();

                // bottom left
                vtxBuilder.addFloat3(x + char.x, y + char.height, 0);
                vtxBuilder.addFloat4(_colour.x, _colour.y, _colour.z, _colour.w);
                vtxBuilder.addFloat2(char.u1, char.v2);

                // Bottom right
                vtxBuilder.addFloat3(x + char.width, y + char.height, 0);
                vtxBuilder.addFloat4(_colour.x, _colour.y, _colour.z, _colour.w);
                vtxBuilder.addFloat2(char.u2, char.v2);

                // Top left
                vtxBuilder.addFloat3(x + char.x, y + char.y, 0);
                vtxBuilder.addFloat4(_colour.x, _colour.y, _colour.z, _colour.w);
                vtxBuilder.addFloat2(char.u1, char.v1);

                // Top right
                vtxBuilder.addFloat3(x + char.width, y + char.y, 0);
                vtxBuilder.addFloat4(_colour.x, _colour.y, _colour.z, _colour.w);
                vtxBuilder.addFloat2(char.u2, char.v1);

                // indicies
                idxBuilder.addInt(idx + 0);
                idxBuilder.addInt(idx + 1);
                idxBuilder.addInt(idx + 2);
                idxBuilder.addInt(idx + 2);
                idxBuilder.addInt(idx + 1);
                idxBuilder.addInt(idx + 3);

                idx += 4;
                x   += char.advance;
            }

            y += font.lineHeight;
            x  = 0;
        }

        data = Indexed(vtxBuilder.vertexBlob(), idxBuilder.indexBlob());
    }

    /**
     * Generates indexed geometry data for a given string.
     * @throws CharacterNotFoundException If the font does not contain a required character to create the text.
     * @param _font Font to get glyph data from.
     * @param _text String to generate geometry from.
     * @return GeometryData
     */
    static function generateGeometry(_font : MsdfFontResource, _text: String) : GeometryData
    {
        final input      = new StringInput(_text);
        final vtxBuilder = new VertexBlobBuilder();
        final idxBuilder = new IndexBlobBuilder();

        var xCursor = 0.0;
        var yCursor = 0.0;
        var index   = 0;

        while (input.position < input.length)
        {
            final line = input.readLine();

            for (i in 0...line.length)
            {
                final code = line.charCodeAt(i).unsafe();

                if (!_font.glyphs.exists(code))
                {
                    throw new CharacterNotFoundException(code, _font.id);
                }

                final char = _font.glyphs.get(code).unsafe();

                addCharacter(vtxBuilder, idxBuilder, char, index, xCursor, yCursor);

                index   += 4;
                xCursor += char.advance;
            }

            yCursor += _font.lineHeight;
            xCursor  = 0;
        }

        input.close();

        return Indexed(vtxBuilder.vertexBlob(), idxBuilder.indexBlob());
    }

    static function addCharacter(
        _vtxBuilder : VertexBlobBuilder,
        _idxBuilder : IndexBlobBuilder,
        _char : FontGlyph,
        _baseIndex : Int,
        _x : Float,
        _y : Float)
    {
        // bottom left
        _vtxBuilder.addFloat3(_x + _char.x, _y + _char.height, 0);
        _vtxBuilder.addFloat4(1, 1, 1, 1);
        _vtxBuilder.addFloat2(_char.u1, _char.v2);

        // Bottom right
        _vtxBuilder.addFloat3(_x + _char.width, _y + _char.height, 0);
        _vtxBuilder.addFloat4(1, 1, 1, 1);
        _vtxBuilder.addFloat2(_char.u2, _char.v2);

        // Top left
        _vtxBuilder.addFloat3(_x + _char.x, _y + _char.y, 0);
        _vtxBuilder.addFloat4(1, 1, 1, 1);
        _vtxBuilder.addFloat2(_char.u1, _char.v1);

        // Top right
        _vtxBuilder.addFloat3(_x + _char.width, _y + _char.y, 0);
        _vtxBuilder.addFloat4(1, 1, 1, 1);
        _vtxBuilder.addFloat2(_char.u2, _char.v1);

        // indicies
        _idxBuilder.addInt(_baseIndex + 0);
        _idxBuilder.addInt(_baseIndex + 1);
        _idxBuilder.addInt(_baseIndex + 2);
        _idxBuilder.addInt(_baseIndex + 2);
        _idxBuilder.addInt(_baseIndex + 1);
        _idxBuilder.addInt(_baseIndex + 3);
    }
}

class CharacterNotFoundException extends Exception
{
    public function new(_code : Int, _font : Int)
    {
        super('Unable to find a character for the code $_code in the font $_font');
    }
}

@:structInit class TextGeometryOptions
{
    /**
     * The font this text will use.
     */
    public final font : MsdfFontResource;

    /**
     * What this text geometry will initially display.
     */
    public final text : String;

    /**
     * Pixel height of the geometry.
     */
    public final size : Float;

    /**
     * Provide a custom sampler for the geometries texture.
     * If null is provided a default sampler is used.
     * Default samplers is clamp uv clipping and nearest neighbour scaling.
     */
    public final sampler = SamplerState.nearest;

    /**
     * Specify a custom shader to be used by this geometry.
     * If none is provided the batchers shader is used.
     */
    public final shader = GeometryShader.None;

    /**
     * Specify custom uniform blocks to be passed to the shader.
     * If none is provided the batchers uniforms are used.
     */
    public final uniforms = GeometryUniforms.None;

    /**
     * Initial depth of the geometry.
     * If none is provided 0 is used.
     */
    public final depth = 0.0;

    /**
     * Custom clip rectangle for this geometry.
     * Defaults to clipping based on the batchers camera.
     */
    public final clip = ClipState.None;

    /**
     * Provides custom blending operations for drawing this geometry.
     */
    public final blend = BlendState.none;

    /**
     * The batchers to initially add this geometry to.
     */
    public final batchers = new Array<Batcher>();

    /**
     * Initial x position of the top left of the geometry.
     */
    public final x = 0.0;

    /**
     * Initial y position of the top left of the geometry.
     */
    public final y = 0.0;
}