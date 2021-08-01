package uk.aidanlee.flurry.api.gpu.backend.d3d11;

import d3d11.enumerations.D3d11Blend;
import d3d11.enumerations.D3d11Filter;
import d3d11.enumerations.D3d11StencilOp;
import d3d11.enumerations.D3d11ComparisonFunction;
import d3d11.enumerations.D3d11TextureAddressMode;
import d3d11.enumerations.D3d11PrimitiveTopology;
import uk.aidanlee.flurry.api.gpu.textures.Filtering;
import uk.aidanlee.flurry.api.gpu.textures.EdgeClamping;

function getBlend(_blend : BlendMode) : D3d11Blend
{
    return switch _blend
    {
        case Zero             : Zero;
        case One              : One;
        case SrcAlphaSaturate : SourceAlphaSat;
        case SrcColor         : SourceColor;
        case OneMinusSrcColor : InverseSourceColor;
        case SrcAlpha         : SourceAlpha;
        case OneMinusSrcAlpha : InverseSourceAlpha;
        case DstAlpha         : DestinationAlpha;
        case OneMinusDstAlpha : InverseDestinationAlpha;
        case DstColor         : DestinationColor;
        case OneMinusDstColor : InverseDestinationColour;
    }
}

function getPrimitive(_primitive : PrimitiveType) : D3d11PrimitiveTopology
{
    return switch _primitive
    {
        case Points        : PointList;
        case Lines         : LineList;
        case LineStrip     : LineStrip;
        case Triangles     : TriangleList;
        case TriangleStrip : TriangleStrip;
    }
}

function getComparisonFunction(_function : ComparisonFunction) : D3d11ComparisonFunction
{
    return switch _function
    {
        case Always             : Always;
        case Never              : Never;
        case Equal              : Equal;
        case LessThan           : Less;
        case LessThanOrEqual    : LessEqual;
        case GreaterThan        : Greater;
        case GreaterThanOrEqual : GreaterEqual;
        case NotEqual           : NotEqual;
    }
}

function getStencilOp(_stencil : StencilFunction) : D3d11StencilOp
{
    return switch _stencil
    {
        case Keep          : Keep;
        case Zero          : Zero;
        case Replace       : Replace;
        case Invert        : Invert;
        case Increment     : IncrSat;
        case IncrementWrap : Incr;
        case Decrement     : DecrSat;
        case DecrementWrap : Decr;
    }
}

function getFilterType(_min : Filtering, _mag : Filtering) : D3d11Filter
{
    if (_min == Filtering.Linear && _mag == Filtering.Linear)
    {
        return MinMagMipLinear;
    }
    else if (_min == Filtering.Linear && _mag == Filtering.Nearest)
    {
        return MinMagLinearMipPoint;
    }
    if (_min == Filtering.Nearest && _mag == Filtering.Linear)
    {
        return MinPointMagMipLinear;
    }
    else
    {
        return MinMagPointMipLinear;
    }
}

function getEdgeClamping(_clamp : EdgeClamping) : D3d11TextureAddressMode
{
    return switch _clamp
    {
        case Wrap   : Wrap;
        case Mirror : Mirror;
        case Clamp  : Clamp;
        case Border : Border;
    }
}