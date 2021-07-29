package uk.aidanlee.flurry.api.resources.loaders;

import haxe.Exception;
import haxe.io.Bytes;
import haxe.ds.Vector;
import haxe.io.Input;

using uk.aidanlee.flurry.api.InputUtils;

class DesktopShaderLoader extends ResourceReader
{
    override function ids()
    {
        return [ 'glsl' ];
    }

    override function read(_input : Input)
    {
        final id   = _input.readInt32();
        final api  = _input.readPrefixedString();

        return switch api
        {
            case 'ogl3', 'mock':
                final blockCount = _input.readInt32();
                final blocks     = new Vector(blockCount);

                for (i in 0...blockCount)
                {
                    final name    = _input.readPrefixedString();
                    final type    = _input.readPrefixedString();
                    final binding = _input.readInt32();

                    blocks[i] = new Ogl3ShaderBlock(name, type, binding);
                }

                final samplerCount = _input.readInt32();
                final samplers     = new Vector(samplerCount);

                for (i in 0...samplerCount)
                {
                    samplers[i] = _input.readPrefixedString();
                }

                final vertCodeLen = _input.readInt32();
                final vertCode    = _input.read(vertCodeLen);

                final fragCodeLen = _input.readInt32();
                final fragCode    = _input.read(fragCodeLen);

                new Ogl3Shader(new ResourceID(id), blocks, samplers, vertCode, fragCode);
            case 'd3d11':
                final vertBlockCount = _input.readInt32();
                final vertBlocks     = new Vector(vertBlockCount);

                for (i in 0...vertBlockCount)
                {
                    vertBlocks[i] = _input.readPrefixedString();
                }

                final fragBlockCount = _input.readInt32();
                final fragBlocks     = new Vector(fragBlockCount);

                for (i in 0...fragBlockCount)
                {
                    fragBlocks[i] = _input.readPrefixedString();
                }

                final textureCount = _input.readInt32();

                final vertCodeLen = _input.readInt32();
                final vertCode    = _input.read(vertCodeLen);

                final fragCodeLen = _input.readInt32();
                final fragCode    = _input.read(fragCodeLen);

                new D3d11Shader(new ResourceID(id), vertBlocks, fragBlocks, textureCount, vertCode, fragCode);
            case other:
                throw new Exception('DesktopShaderLoader cannot produced shaders of type $other');
        }
    }
}

class D3d11Shader extends Resource
{
    public final vertBlocks : Vector<String>;

    public final fragBlocks : Vector<String>;

    public final textureCount : Int;

    public final vertCode : Bytes;

    public final fragCode : Bytes;

	public function new(_name, _vertBlocks, _fragBlocks, _textureCount, _vertCode, _fragCode)
    {
        super(_name);

		vertBlocks   = _vertBlocks;
		fragBlocks   = _fragBlocks;
		textureCount = _textureCount;
		vertCode     = _vertCode;
		fragCode     = _fragCode;
	}
}

class Ogl3Shader extends Resource
{
    public final blocks : Vector<Ogl3ShaderBlock>;

    public final samplers : Vector<String>;

    public final vertCode : Bytes;

    public final fragCode : Bytes;

	public function new(_name, _blocks, _samplers, _vertCode, _fragCode)
    {
        super(_name);

		blocks   = _blocks;
		samplers = _samplers;
        vertCode = _vertCode;
		fragCode = _fragCode;
	}
}

class Ogl3ShaderBlock
{
    public final name : String;

    public final type : String;

    public final binding : Int;

	public function new(_name, _type, _binding)
    {
		name    = _name;
		type    = _type;
		binding = _binding;
	}
}