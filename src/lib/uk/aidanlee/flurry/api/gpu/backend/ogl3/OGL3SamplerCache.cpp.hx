package uk.aidanlee.flurry.api.gpu.backend.ogl3;

import opengl.OpenGL;
import opengl.OpenGL.*;
import uk.aidanlee.flurry.api.gpu.textures.Filtering;
import uk.aidanlee.flurry.api.gpu.textures.EdgeClamping;
import uk.aidanlee.flurry.api.gpu.textures.SamplerState;

using Safety;

class OGL3SamplerCache
{
    final samplers : Map<SamplerState, GLuint>;

    public function new()
    {
        samplers = [];
    }

    public function get(_sampler : SamplerState) : GLuint
    {
        return switch samplers[_sampler]
        {
            case null:
                final id = 0;
                glGenSamplers(1, id);
                glSamplerParameteri(id, GL_TEXTURE_MAG_FILTER, getFilterType(_sampler.magnification));
                glSamplerParameteri(id, GL_TEXTURE_MIN_FILTER, getFilterType(_sampler.minification));
                glSamplerParameteri(id, GL_TEXTURE_WRAP_S, getEdgeClamping(_sampler.uClamping));
                glSamplerParameteri(id, GL_TEXTURE_WRAP_T, getEdgeClamping(_sampler.vClamping));

                samplers[_sampler] = id;
            case existing:
                existing.unsafe();
        }
    }

    function getFilterType(_filter : Filtering)
    {
        return switch _filter
        {
            case Nearest : GL_NEAREST;
            case Linear  : GL_LINEAR;
        }
    }

    function getEdgeClamping(_clamping : EdgeClamping)
    {
        return switch _clamping
        {
            case Wrap   : GL_REPEAT;
            case Mirror : GL_MIRRORED_REPEAT;
            case Clamp  : GL_CLAMP_TO_EDGE;
            case Border : GL_CLAMP_TO_BORDER;
        }
    }
}