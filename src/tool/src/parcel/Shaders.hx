package parcel;

import sys.io.Process;
import sys.io.abstractions.IFileSystem;
import Types.GraphicsBackend;
import haxe.Exception;
import haxe.DynamicAccess;
import haxe.io.Path;
import parcel.Types.JsonShaderResource;
import uk.aidanlee.flurry.api.resources.Resource;
import uk.aidanlee.flurry.api.core.Result;

using Safety;
using StringTools;

typedef SpvcInputOutput = {
    final name : String;
    final type : String;
    final location : Int;
}

typedef SpvcUbo = {
    final type : String;
    final name : String;
    final block_size : Int;
    final binding : Int;
}

typedef SpvcType = {
    final name : String;
    final members : Array<SpvcTypeMember>;
}

typedef SpvcTypeMember = {
    final name : String;
    final type : String;
    final ?offset : Int;
}

typedef SpvcSeparateImages = {
    final type : String;
    final name : String;
    final binding : Int;
}

typedef SpvcSeparateSamples = {
    final type : String;
    final name : String;
    final binding : Int;
}

typedef SpvcReflection = {
    final ?inputs : Array<SpvcInputOutput>;
    final ?ubos : Array<SpvcUbo>;
    final ?types : DynamicAccess<SpvcType>;
    final ?separate_images : Array<SpvcSeparateImages>;
    final ?separate_samplers : Array<SpvcSeparateSamples>;
}

class Shaders
{
    final toolsDir : String;

    final proc : Proc;

    final fs : IFileSystem;

    final gpu : GraphicsBackend;

    final glslang : String;

    final spirvCross : String;

    public function new(_toolsDir, _proc, _fs, _gpu)
    {
        toolsDir   = _toolsDir;
        proc       = _proc;
        fs         = _fs;
        gpu        = _gpu;
        glslang    = Path.join([ toolsDir, Utils.glslangExecutable() ]);
        spirvCross = Path.join([ toolsDir, Utils.spirvCrossExecutable() ]);
    }

    /**
     * Create a serialisable shader resource from the provided shader sources.
     * @param _baseDir Base assets path all other asset paths are relative to.
     * @param _tempAssets Directory to intermediate data in.
     * @param _shader Shader asset to create.
     * @return Result<ShaderResource, String>
     */
    public function compile(_baseDir : String, _tempAssets : String, _shader : JsonShaderResource) : Result<ShaderResource, String>
    {
        // Stage 1, compile the vulkan glsl intp spirv bytecode

        final vertPath = Path.join([ _baseDir, _shader.vertex ]);
        final fragPath = Path.join([ _baseDir, _shader.fragment ]);

        final vertSpvPath = Path.join([ _tempAssets, '${ _shader.id }.vert.spv' ]);
        final fragSpvPath = Path.join([ _tempAssets, '${ _shader.id }.frag.spv' ]);

        switch proc.run(glslang, [ vertPath, '-V100', '-S', 'vert', '-e', 'main', '-o', vertSpvPath ])
        {
            case Success(_): trace('generated vert spv');
            case Failure(_):
        }
        switch proc.run(glslang, [ fragPath, '-V100', '-S', 'frag', '-e', 'main', '-o', fragSpvPath ])
        {
            case Success(_): trace('generated frag spv');
            case Failure(_):
        }

        // Stage 2, generate reflection data from the spirv

        final vertJsonPath = Path.join([ _tempAssets, '${ _shader.id }.vert.json' ]);
        final fragJsonPath = Path.join([ _tempAssets, '${ _shader.id }.frag.json' ]);

        switch proc.run(spirvCross, [ vertSpvPath, '--stage', 'vert', '--entry', 'main', '--reflect', '--output', vertJsonPath ])
        {
            case Success(_): trace('generated vert json');
            case Failure(_): return Failure('failed to generated vert json');
        }
        switch proc.run(spirvCross, [ fragSpvPath, '--stage', 'frag', '--entry', 'main', '--reflect', '--output', fragJsonPath ])
        {
            case Success(_): trace('generated frag json');
            case Failure(_): return Failure('failed to generated frag json');
        }

        final vertInfo = generateVertexInfo(tink.Json.parse(fs.file.getText(vertJsonPath)));
        final fragInfo = generateFragmentInfo(tink.Json.parse(fs.file.getText(fragJsonPath)));

        // Stage 3, generate opengl 3.3 glsl or shader model 5 hlsl from the spirv

        return switch gpu
        {
            case Mock, Ogl3:
                final vertGlslPath = Path.join([ _tempAssets, '${ _shader.id }.vert.glsl' ]);
                final fragGlslPath = Path.join([ _tempAssets, '${ _shader.id }.frag.glsl' ]);

                switch proc.run(spirvCross, [ vertSpvPath, '--stage', 'vert', '--entry', 'main', '--version', '330', '--no-420pack-extension', '--output', vertGlslPath ])
                {
                    case Success(_): trace('generated vert glsl');
                    case Failure(_): return Failure('failed to generated vert glsl');
                }
                switch proc.run(spirvCross, [ fragSpvPath, '--stage', 'frag', '--entry', 'main', '--version', '330', '--no-420pack-extension', '--output', fragGlslPath ])
                {
                    case Success(_): trace('generated frag glsl');
                    case Failure(_): return Failure('failed to generated frag glsl');
                }

                Success(new ShaderResource(_shader.id, fs.file.getBytes(vertGlslPath), fs.file.getBytes(fragGlslPath), vertInfo, fragInfo));
            case D3d11:
                final vertHlslPath = Path.join([ _tempAssets, '${ _shader.id }.vert.hlsl' ]);
                final fragHlslPath = Path.join([ _tempAssets, '${ _shader.id }.frag.hlsl' ]);

                switch proc.run(spirvCross, [ vertSpvPath, '--stage', 'vert', '--entry', 'main', '--hlsl', '--shader-model', '50', '--output', vertHlslPath ])
                {
                    case Success(_): trace('generated vert hlsl');
                    case Failure(_): return Failure('failed to generated vert hlsl');
                }
                switch proc.run(spirvCross, [ fragSpvPath, '--stage', 'frag', '--entry', 'main', '--hlsl', '--shader-model', '50', '--output', fragHlslPath ])
                {
                    case Success(_): trace('generated frag hlsl');
                    case Failure(_): return Failure('failed to generated frag hlsl');
                }

                final vertDxbcPath = Path.join([ _tempAssets, '${ _shader.id }.vert.dxbc' ]);
                final fragDxbcPath = Path.join([ _tempAssets, '${ _shader.id }.frag.dxbc' ]);

                switch getFxc()
                {
                    case Success(fxc):
                        switch proc.run(fxc, [ '/T', 'vs_5_0', '/E', 'main', '/Fo', vertDxbcPath, vertHlslPath ])
                        {
                            case Success(_): trace('generated vert dxbc');
                            case Failure(_): return Failure('failed to generated vert dxbc');
                        }
                        switch proc.run(fxc, [ '/T', 'ps_5_0', '/E', 'main', '/Fo', fragDxbcPath, fragHlslPath ])
                        {
                            case Success(_): trace('generated frag dxbc');
                            case Failure(_): return Failure('failed to generated frag dxbc');
                        }
                    case Failure(message): return Failure(message);
                }

                Success(new ShaderResource(_shader.id, fs.file.getBytes(vertDxbcPath), fs.file.getBytes(fragDxbcPath), vertInfo, fragInfo));
        }
    }

    /**
     * Generate a serialisable structure from a reflection vertex input.
     * @param _input Vertex stage reflection data from spirv-cross.
     * @return ShaderVertInfo
     */
    function generateVertexInfo(_input : SpvcReflection) : ShaderVertInfo
    {
        final layout = [ for (i in _input.inputs.or([])) new ShaderInput(i.name, parseType(i.type), i.location) ];
        final blocks = [ for (b in _input.ubos.or([])) new ShaderBlock(b.name, b.block_size, b.binding, getMembers(_input, b.name)) ];

        return new ShaderVertInfo(layout, blocks);
    }

    /**
     * Generate a serialisable structure from a reflected fragment input.
     * @param _input Fragment stage reflection data from spirv-cross.
     * @return ShaderFragInfo
     */
    function generateFragmentInfo(_input : SpvcReflection) : ShaderFragInfo
    {
        final textures = [ for (t in _input.separate_images.or([])) new ShaderInput(t.name, parseType(t.type), t.binding) ];
        final samplers = [ for (s in _input.separate_samplers.or([])) new ShaderInput(s.name, parseType(s.type), s.binding) ];
        final blocks   = [ for (b in _input.ubos.or([])) new ShaderBlock(b.name, b.block_size, b.binding, getMembers(_input, b.name)) ];

        return new ShaderFragInfo(textures, samplers, blocks);
    }

    /**
     * Convert a reflected string type into the equivilent enum.
     * @param _type String to match.
     * @return ShaderType
     */
    function parseType(_type : String) : ShaderType
    {
        return switch _type
        {
            case 'mat4': Matrix4;
            case 'vec2': Vector2;
            case 'vec3': Vector3;
            case 'vec4': Vector4;
            case 'texture2D': Texture2D;
            case 'sampler': Sampler;
            case 'float': TFloat;
            case other: throw new Exception('unknown glsl type $other');
        }
    }

    /**
     * Return an array of inputs for a block.
     * Block needs to be searched for due to the reflection json format.
     * @param _input Complete reflection structure.
     * @param _name Name of the block to get members for.
     */
    function getMembers(_input : SpvcReflection, _name : String)
    {
        if (_input.types != null)
        {
            for (type in _input.types)
            {
                if (type.name == _name)
                {
                    return [ for (member in type.members) new ShaderInput(member.name, parseType(member.type), member.offset.or(0)) ];
                }
            }

            throw new Exception('$_name not found');
        }
        else
        {
            throw new Exception('no types were defined in this shader');
        }
    }

    /**
     * Try and find fxc.exe using the installed Windows SDK.
     * @return Result<fxc path, error message>
     */
    function getFxc() : Result<String, String>
    {
        final psLine  = "powershell -command \"(Get-Item 'hklm:\\SOFTWARE\\WOW6432Node\\Microsoft\\Microsoft SDKs\\Windows\\v10.0').GetValue('ProductVersion')\"";
        final sdkDir  = 'C:/Program Files (x86)/Windows Kits/10/bin';

        final proc    = new Process(psLine);
        final version = proc.stdout.readLine();
        final exit    = proc.exitCode();

        proc.close();

        if (exit != 0)
        {
            return Failure('Failed to read Windows SDK registry key');
        }

        for (dir in fs.directory.read(sdkDir))
        {
            if (fs.directory.isDirectory(Path.join([ sdkDir, dir ])) && dir.startsWith(version))
            {
                return Success(Path.join([ sdkDir, dir, 'x64', 'fxc.exe' ]));
            }
        }

        return Failure('Failed to find fxc.exe');
    }
}