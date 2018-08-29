package uk.aidanlee.gpu.batcher;

import uk.aidanlee.maths.Rectangle;
import uk.aidanlee.maths.Matrix;
import uk.aidanlee.gpu.geometry.Geometry;

class GeometryDrawCommand extends DrawCommand
{
    public final geometry : Array<Geometry>;

    inline public function new(
        _geometry   : Array<Geometry>,

        _id         : Int,
        _unchanging : Bool,
        _startIdx   : Int,
        _endIdx     : Int,
        _vertices   : Int,
        _projection : Matrix,
        _view       : Matrix,
        _viewport   : Rectangle,
        _primitive  : PrimitiveType,
        _target     : IRenderTarget,
        _shader     : Shader,
        _textures   : Array<Texture>,
        _clip       : Rectangle,
        _blending   : Bool,
        _srcRGB     : BlendMode = null,
        _dstRGB     : BlendMode = null,
        _srcAlpha   : BlendMode = null,
        _dstAlpha   : BlendMode = null
    )
    {
        geometry = _geometry;

        super(_id, _unchanging, _startIdx, _endIdx, _vertices, _projection, _view, _viewport, _primitive, _target, _shader, _textures, _clip, _blending, _srcRGB, _dstRGB, _srcAlpha, _dstAlpha);
    }
}