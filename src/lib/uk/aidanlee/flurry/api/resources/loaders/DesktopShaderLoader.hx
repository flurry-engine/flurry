package uk.aidanlee.flurry.api.resources.loaders;

import uk.aidanlee.flurry.api.resources.builtin.DataBlobResource;
import uk.aidanlee.flurry.api.resources.builtin.ShaderResource;
import haxe.Exception;
import haxe.io.Bytes;
import haxe.io.Input;
import haxe.ds.Vector;
import uk.aidanlee.flurry.api.gpu.pipeline.VertexFormat;
import uk.aidanlee.flurry.api.gpu.pipeline.VertexElement;

using uk.aidanlee.flurry.api.resources.loaders.DesktopShaderLoader;

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

        final inputCount = _input.readByte();
        final inputs     = new Vector(inputCount);

        for (i in 0...inputCount)
        {
            final location = _input.readByte();
            final type     = _input.readByte();

            inputs[i] = new VertexElement(location, cast type);
        }

        final vertexFormat = new VertexFormat(
            inputCount,
            inputs[0],
            inputs[1],
            inputs[2],
            inputs[3],
            inputs[4]);

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

                // Pack both of the shader data into a single bytes object preceeded by its length.
                final vertCodeLen = _input.readInt32();
                final fragCodeLen = _input.readInt32();
                final codeBlob    = Bytes.alloc(vertCodeLen + fragCodeLen);

                _input.readBytes(codeBlob, 0, vertCodeLen);
                _input.readBytes(codeBlob, vertCodeLen, fragCodeLen);

                new DataBlobResource(
                    new Ogl3Shader(new ResourceID(id), vertexFormat, blocks, samplers, vertCodeLen, fragCodeLen),
                    codeBlob);
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

                // Pack both of the shader data into a single bytes object preceeded by its length.
                final vertCodeLen = _input.readInt32();
                final fragCodeLen = _input.readInt32();
                final codeBlob    = Bytes.alloc(vertCodeLen + fragCodeLen);

                _input.readBytes(codeBlob, 0, vertCodeLen);
                _input.readBytes(codeBlob, vertCodeLen, fragCodeLen);

                new DataBlobResource(
                    new D3d11Shader(new ResourceID(id), vertexFormat, vertBlocks, fragBlocks, textureCount, vertCodeLen, fragCodeLen),
                    codeBlob);
            case other:
                throw new Exception('DesktopShaderLoader cannot produced shaders of type $other');
        }
    }

    static function readPrefixedString(_input : Input)
    {
        final len = _input.readInt32();
        final str = _input.readString(len);
    
        return str;
    }
}

class D3d11Shader extends ShaderResource
{
    public final format : VertexFormat;

    public final vertBlocks : Vector<String>;

    public final fragBlocks : Vector<String>;

    public final textureCount : Int;

    public final vertCodeLength : Int;

    public final fragCodeLength : Int;

	public function new(_name, _format, _vertBlocks, _fragBlocks, _textureCount, _vertCodeLength, _fragCodeLength)
    {
        super(_name);

        format         = _format;
        vertBlocks     = _vertBlocks;
		fragBlocks     = _fragBlocks;
		textureCount   = _textureCount;
        vertCodeLength = _vertCodeLength;
        fragCodeLength = _fragCodeLength;
	}

    public function vertCodeOffset()
    {
        return 0;
    }

    public function fragCodeOffset()
    {
        return vertCodeLength;
    }
}

class Ogl3Shader extends ShaderResource
{
    public final format : VertexFormat;

    public final blocks : Vector<Ogl3ShaderBlock>;

    public final samplers : Vector<String>;

    public final vertCodeLength : Int;

    public final fragCodeLength : Int;

	public function new(_name, _format, _blocks, _samplers, _vertCodeLength, _fragCodeLength)
    {
        super(_name);

        format         = _format;
		blocks         = _blocks;
		samplers       = _samplers;
        vertCodeLength = _vertCodeLength;
        fragCodeLength = _fragCodeLength;
	}

    public function vertCodeOffset()
    {
        return 0;
    }

    public function fragCodeOffset()
    {
        return vertCodeLength;
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