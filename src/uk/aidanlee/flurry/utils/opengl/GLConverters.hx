package uk.aidanlee.flurry.utils.opengl;

import opengl.GL.*;
import uk.aidanlee.flurry.api.gpu.StencilFunction;
import uk.aidanlee.flurry.api.gpu.ComparisonFunction;
import uk.aidanlee.flurry.api.gpu.BlendMode;
import uk.aidanlee.flurry.api.gpu.PrimitiveType;

class GLConverters
{
    public static function getPrimitiveType(_primitive : PrimitiveType) : Int
    {
        return switch _primitive
        {
            case Points        : GL_POINTS;
            case Lines         : GL_LINES;
            case LineStrip     : GL_LINE_STRIP;
            case Triangles     : GL_TRIANGLES;
            case TriangleStrip : GL_TRIANGLE_STRIP;
        }
    }

    public static function getBlendMode(_mode : BlendMode) : Int
    {
        return switch _mode
        {
            case Zero             : GL_ZERO;
            case One              : GL_ONE;
            case SrcAlphaSaturate : GL_SRC_ALPHA_SATURATE;
            case SrcColor         : GL_SRC_COLOR;
            case OneMinusSrcColor : GL_ONE_MINUS_SRC_COLOR;
            case SrcAlpha         : GL_SRC_ALPHA;
            case OneMinusSrcAlpha : GL_ONE_MINUS_SRC_ALPHA;
            case DstAlpha         : GL_DST_ALPHA;
            case OneMinusDstAlpha : GL_ONE_MINUS_DST_ALPHA;
            case DstColor         : GL_DST_COLOR;
            case OneMinusDstColor : GL_ONE_MINUS_DST_COLOR;
            case _: 0;
        }
    }

    public static function getComparisonFunc(_func : ComparisonFunction) : Int
    {
        return switch _func
        {
            case Always             : GL_ALWAYS;
            case Never              : GL_NEVER;
            case LessThan           : GL_LESS;
            case Equal              : GL_EQUAL;
            case LessThanOrEqual    : GL_LEQUAL;
            case GreaterThan        : GL_GREATER;
            case GreaterThanOrEqual : GL_GEQUAL;
            case NotEqual           : GL_NOTEQUAL;
        }
    }

    public static function getStencilFunc(_func : StencilFunction) : Int
    {
        return switch _func
        {
            case Keep          : GL_KEEP;
            case Zero          : GL_ZERO;
            case Replace       : GL_REPLACE;
            case Invert        : GL_INVERT;
            case Increment     : GL_INCR;
            case IncrementWrap : GL_INCR_WRAP;
            case Decrement     : GL_DECR;
            case DecrementWrap : GL_DECR_WRAP;
        }
    }
}