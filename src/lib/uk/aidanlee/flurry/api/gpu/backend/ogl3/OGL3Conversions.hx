package uk.aidanlee.flurry.api.gpu.backend.ogl3;

import uk.aidanlee.flurry.api.gpu.pipeline.ComparisonFunction;
import uk.aidanlee.flurry.api.gpu.pipeline.BlendOp;
import opengl.OpenGL.*;
import uk.aidanlee.flurry.api.gpu.pipeline.BlendMode;

function getBlend(_blend : BlendMode)
{
    return switch _blend
    {
        case Zero: GL_ZERO;
        case One: GL_ONE;
        case SrcAlphaSaturate: GL_SRC_ALPHA_SATURATE;
        case SrcColour: GL_SRC_COLOR;
        case OneMinusSrcColour: GL_ONE_MINUS_SRC_COLOR;
        case SrcAlpha: GL_SRC_ALPHA;
        case OneMinusSrcAlpha: GL_ONE_MINUS_SRC_ALPHA;
        case DstAlpha: GL_DST_ALPHA;
        case OneMinusDstAlpha: GL_ONE_MINUS_DST_ALPHA;
        case DstColour: GL_DST_COLOR;
        case OneMinusDstColour: GL_ONE_MINUS_DST_COLOR;
    }
}

function getBlendEquation(_equation : BlendOp)
{
    return switch _equation
    {
        case Add: GL_FUNC_ADD;
        case Subtract: GL_FUNC_SUBTRACT;
        case ReverseSubtract: GL_FUNC_REVERSE_SUBTRACT;
        case Min: GL_MIN;
        case Max: GL_MAX;
    }
}

function getDepthFunction(_function : ComparisonFunction)
{
    return switch _function
    {
        case Always: GL_ALWAYS;
        case Never: GL_NEVER;
        case Equal: GL_EQUAL;
        case LessThan: GL_LESS;
        case LessThanOrEqual: GL_LEQUAL;
        case GreaterThan: GL_GREATER;
        case GreaterThanOrEqual: GL_GEQUAL;
        case NotEqual: GL_NOTEQUAL;
    }
}