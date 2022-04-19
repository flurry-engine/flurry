package uk.aidanlee.flurry.api.gpu.backend.mock;

import uk.aidanlee.flurry.api.gpu.camera.Camera2D;
import uk.aidanlee.flurry.api.gpu.shaders.UniformBlob;
import uk.aidanlee.flurry.api.gpu.surfaces.SurfaceID;
import uk.aidanlee.flurry.api.gpu.pipeline.PipelineID;
import uk.aidanlee.flurry.api.gpu.textures.SamplerState;
import uk.aidanlee.flurry.api.resources.ResourceID;

class MockGraphicsContext extends GraphicsContext
{
    public function new()
    {
        super(new VertexOutput(), new IndexOutput());
    }

	public function usePipeline(_id : PipelineID)
    {
        //
    }

	public function useCamera(_camera : Camera2D)
    {
        //
    }

	public function usePage(_slot : Int, _id : ResourceID, _sampler : SamplerState)
    {
        //
    }

	public function useSurface(_slot : Int, _id : SurfaceID, _sampler : SamplerState)
    {
        //
    }

	public function useUniformBlob(_blob : UniformBlob)
    {
        //
    }

	public function useScissorRegion(_x : Int, _y : Int, _width : Int, _height : Int)
    {
        //
    }

	public function prepare()
    {
        //
    }

	public function flush()
    {
        //
    }

	public function close()
    {
        //
    }
}