package uk.aidanlee.flurry.api.gpu.backend.ogl3;

import haxe.Exception;
import opengl.OpenGL.GLint;
import opengl.OpenGL.GLuint;

class OGL3ShaderInformation
{
    public final program : Int;

    public final elements : Array<OGL3ShaderInputElement>;

    public final byteStride : Int;

    public final samplerLocations : Array<GLint>;

    public final blockLocations : Array<Int>;

    public final matrixLocation : GLint;

    public final blockNames : Array<String>;

    public function new(_program, _elements, _byteStride, _samplers, _blocks, _matrix, _names)
    {
        program          = _program;
        elements         = _elements;
        byteStride       = _byteStride;
        samplerLocations = _samplers;
        blockLocations   = _blocks;
        matrixLocation   = _matrix;
        blockNames       = _names;
    }

    public function findBlockIndexByName(_name : String)
    {
        for (idx => name in blockNames)
        {
            if (name == _name)
            {
                return blockLocations[idx];
            }
        }

        return -1;
    }
}

class OGL3ShaderInputElement
{
    public final index : Int;

    public final floatSize : Int;

    public final byteOffset : Int;

    public function new(_index, _floatSize, _byteOffset)
    {
        index      = _index;
        floatSize  = _floatSize;
        byteOffset = _byteOffset;
    }
}