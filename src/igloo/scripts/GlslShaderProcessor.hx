import sys.io.Process;
import haxe.ds.Option;
import haxe.Json;
import haxe.Exception;
import haxe.DynamicAccess;
import haxe.io.Output;
import hx.files.Path;
import igloo.parcels.ParcelContext;
import igloo.parcels.Asset;
import igloo.processors.AssetRequest;
import igloo.processors.ProcessedAsset;
import igloo.processors.IAssetProcessor;

using Lambda;
using Safety;
using StringTools;
using igloo.utils.OutputUtils;

class GlslShaderProcessor implements IAssetProcessor<ProducedShader>
{
	public function ids()
    {
		return [ 'glsl' ];
	}

	public function pack(_ctx : ParcelContext, _asset : Asset)
	{
		// Transform our input asset path into vert and fragment versions.
		// Throw if either don't exist.
		final source      = Path.of(_asset.path);
		final vertPath    = _ctx.assetDirectory.joinAll([ source.parent, source.filenameStem + '.vert.glsl' ]);
		final fragPath    = _ctx.assetDirectory.joinAll([ source.parent, source.filenameStem + '.frag.glsl' ]);

		// Generate spirv data for the vertex and fragment shader.
		final vertSpvPath = _ctx.tempDirectory.join(_asset.id + '.vert.spv');
		final fragSpvPath = _ctx.tempDirectory.join(_asset.id + '.frag.spv');

		if (Sys.command(_ctx.tools.glslang.toString(), [ vertPath.toString(), '-V100', '-S', 'vert', '-e', 'main', '-o', vertSpvPath.toString() ]) != 0)
		{
			throw new Exception('Failed to generate vertex spirv');
		}
		if (Sys.command(_ctx.tools.glslang.toString(), [ fragPath.toString(), '-V100', '-S', 'frag', '-e', 'main', '-o', fragSpvPath.toString() ]) != 0)
		{
			throw new Exception('Failed to generate fragment spirv');
		}

		// Generate json reflection data for the vertex and fragment shader.
		final vertJsonPath = _ctx.tempDirectory.join(_asset.id + '.vert.json');
		final fragJsonPath = _ctx.tempDirectory.join(_asset.id + '.frag.json');

		if (Sys.command(_ctx.tools.spirvcross.toString(), [ vertSpvPath.toString(), '--stage', 'vert', '--entry', 'main', '--reflect', '--output', vertJsonPath.toString() ]) != 0)
		{
			throw new Exception('Failed to generate vertex reflection json');
		}
		if (Sys.command(_ctx.tools.spirvcross.toString(), [ fragSpvPath.toString(), '--stage', 'frag', '--entry', 'main', '--reflect', '--output', fragJsonPath.toString() ]) != 0)
		{
			throw new Exception('Failed to generate fragment reflection json');
		}

		final vertReflection = (Json.parse(vertJsonPath.toFile().readAsString()) : SpvcReflection);
		final fragReflection = (Json.parse(fragJsonPath.toFile().readAsString()) : SpvcReflection);

		// Generate api specific consumable data.
		return switch _ctx.gpuApi
		{
			case 'mock', 'ogl3':
				final vertGlslPath = _ctx.tempDirectory.join(_asset.id + '.vert.glsl');
				final fragGlslPath = _ctx.tempDirectory.join(_asset.id + '.frag.glsl');

				if (Sys.command(_ctx.tools.spirvcross.toString(), [ vertSpvPath.toString(), '--stage', 'vert', '--entry', 'main', '--version', '330', '--no-420pack-extension', '--output', vertGlslPath.toString() ]) != 0)
				{
					throw new Exception('Failed to generate core 3.3 glsl vertex shader');
				}
				if (Sys.command(_ctx.tools.spirvcross.toString(), [ fragSpvPath.toString(), '--stage', 'frag', '--entry', 'main', '--version', '330', '--no-420pack-extension', '--output', fragGlslPath.toString() ]) != 0)
				{
					throw new Exception('Failed to generate core 3.3 glsl fragment shader');
				}

				new AssetRequest(new ProducedShader(vertReflection, fragReflection, vertGlslPath, fragGlslPath), None);
			case 'd3d11':
				final vertHlslPath = _ctx.tempDirectory.join(_asset.id + '.vert.hlsl');
				final fragHlslPath = _ctx.tempDirectory.join(_asset.id + '.frag.hlsl');

				if (Sys.command(_ctx.tools.spirvcross.toString(), [ vertSpvPath.toString(), '--stage', 'vert', '--entry', 'main', '--hlsl', '--shader-model', '50', '--output', vertHlslPath.toString() ]) != 0)
				{
					throw new Exception('Failed to generate core 3.3 glsl vertex shader');
				}
				if (Sys.command(_ctx.tools.spirvcross.toString(), [ fragSpvPath.toString(), '--stage', 'frag', '--entry', 'main', '--hlsl', '--shader-model', '50', '--output', fragHlslPath.toString() ]) != 0)
				{
					throw new Exception('Failed to generate core 3.3 glsl fragment shader');
				}

				switch getFxc()
				{
					case Some(fxc):
						final vertDxbcPath = _ctx.tempDirectory.join(_asset.id + '.vert.dxbc');
						final fragDxbcPath = _ctx.tempDirectory.join(_asset.id + '.frag.dxbc');
						
						if (Sys.command(fxc.toString(), [ '/T', 'vs_5_0', '/E', 'main', '/Fo', vertDxbcPath.toString(), vertHlslPath.toString() ]) != 0)
						{
							throw new Exception('Failed to generate vertex dxbc');
						}
						if (Sys.command(fxc.toString(), [ '/T', 'ps_5_0', '/E', 'main', '/Fo', fragDxbcPath.toString(), fragHlslPath.toString() ]) != 0)
						{
							throw new Exception('Failed to generate fragment dxbc');
						}

						new AssetRequest(new ProducedShader(vertReflection, fragReflection, vertDxbcPath, fragDxbcPath), None);
					case None:
						throw new Exception('Unable to find fxc.exe path');
				}
			case other:
				throw new Exception('GlslShaderProcessor cannot generate shaders for $other');
		}
	}

	public function write(_ctx : ParcelContext, _writer : Output, _asset : ProcessedAsset<ProducedShader>)
	{
		_writer.writePrefixedString(_asset.id);
		_writer.writePrefixedString(_ctx.gpuApi);

		switch _ctx.gpuApi
		{
			case 'ogl3', 'mock':
				// OpenGL doesn't really distinguish between vertex and fragment stages when binding.
				// So we can filter to what we actually want.
				final blocks = getDistinctBlocks(
					_asset.data.vertReflection.ubos.or([]),
					_asset.data.fragReflection.ubos.or([]));
		
				final combined = generateCombinedSamplers(
					_asset.data.fragReflection.separate_images.or([]),
					_asset.data.fragReflection.separate_samplers.or([]));
		
				_writer.writeInt32(blocks.length);
				for (block in blocks)
				{
					_writer.writePrefixedString(block.name);
					_writer.writePrefixedString(block.type);
					_writer.writeInt32(block.binding);
				}
		
				_writer.writeInt32(combined.length);
				for (sampler in combined)
				{
					_writer.writePrefixedString(sampler);
				}
			case 'd3d11':
				// D3D11 does care about the blocks in each stage, so include the full info.
				final vertBlocks = _asset.data.vertReflection.ubos.or([]);
				final fragBlocks = _asset.data.fragReflection.ubos.or([]);

				_writer.writeInt32(vertBlocks.length);
				for (block in vertBlocks)
				{
					_writer.writePrefixedString(block.name);
				}

				_writer.writeInt32(fragBlocks.length);
				for (block in fragBlocks)
				{
					_writer.writePrefixedString(block.name);
				}

				if (_asset.data.fragReflection.separate_images.length != _asset.data.fragReflection.separate_samplers.length)
				{
					throw new Exception('Number of samplers and textures do not match');		
				}

				_writer.writeInt32(_asset.data.fragReflection.separate_images.length);
			case other:
				throw new Exception('GlslShaderProcessor cannot write shaders for $other');
		}

		final vertBlob = _asset.data.vertPath.toFile().readAsBytes();
		final fragBlob = _asset.data.fragPath.toFile().readAsBytes();

		_writer.writeInt32(vertBlob.length);
		_writer.write(vertBlob);

		_writer.writeInt32(fragBlob.length);
		_writer.write(fragBlob);
	}

	function getDistinctBlocks(_set1 : Array<SpvcUbo>, _set2 : Array<SpvcUbo>)
	{
		final out = _set1.copy();

		for (block in _set2)
		{
			if (!out.exists(item -> item.name == block.name))
			{
				out.push(block);
			}
		}

		return out;
	}

	function generateCombinedSamplers(_images : Array<SpvcSeparateImages>, _samplers : Array<SpvcSeparateSamples>)
	{
		if (_images.length != _samplers.length)
		{
			throw new Exception('Number of samplers and textures do not match');
		}

		return [ for (i in 0..._images.length) 'SPIRV_Cross_Combined${ _images[i].name }${ _samplers[i].name }' ];
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
					return [ for (member in type.members) { name : member.name, type : member.type, offset : member.offset.or(0) } ];
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
     * @return Option<fxc path>
     */
    function getFxc() : Option<Path>
	{
		final psLine  = "powershell -command \"(Get-Item 'hklm:\\SOFTWARE\\WOW6432Node\\Microsoft\\Microsoft SDKs\\Windows\\v10.0').GetValue('ProductVersion')\"";
		final sdkDir  = Path.of('C:/Program Files (x86)/Windows Kits/10/bin');

		final proc    = new Process(psLine);
		final version = proc.stdout.readLine();
		final exit    = proc.exitCode();

		proc.close();

		if (exit != 0)
		{
			return None;
		}

		for (dir in sdkDir.toDir().listDirs())
		{
			if (dir.path.filename.startsWith(version))
			{
				return Some(dir.path.joinAll([ 'x64', 'fxc.exe' ]));
			}
		}

		return None;
	}
}

class ProducedShader
{
	public final vertReflection : SpvcReflection;

	public final fragReflection : SpvcReflection;

	public final vertPath : Path;

	public final fragPath : Path;

	public function new(_vertReflection, _fragReflection, _vertPath, _fragPath)
	{
		vertReflection = _vertReflection;
		fragReflection = _fragReflection;
		vertPath       = _vertPath;
		fragPath       = _fragPath;
	}
}

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

typedef SpvcEntryPoint = {
	final name : String;
	final mode : String;
}

typedef SpvcReflection = {
	final entryPoints : Array<SpvcEntryPoint>;
    final inputs : Array<SpvcInputOutput>;
	final outputs : Array<SpvcInputOutput>;
    final ?ubos : Array<SpvcUbo>;
    final ?types : DynamicAccess<SpvcType>;
    final ?separate_images : Array<SpvcSeparateImages>;
    final ?separate_samplers : Array<SpvcSeparateSamples>;
}
