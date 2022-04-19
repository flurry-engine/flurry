package uk.aidanlee.flurry.api.gpu.backend.mock;

import haxe.io.ArrayBufferView;
import uk.aidanlee.flurry.api.gpu.pipeline.PipelineID;
import uk.aidanlee.flurry.api.gpu.pipeline.PipelineState;
import uk.aidanlee.flurry.api.gpu.surfaces.SurfaceID;
import uk.aidanlee.flurry.api.gpu.surfaces.SurfaceState;
import uk.aidanlee.flurry.api.resources.ResourceID;
import uk.aidanlee.flurry.api.resources.builtin.DataBlobResource;
import uk.aidanlee.flurry.api.resources.builtin.PageFrameResource;

class MockRenderer extends Renderer
{
    final ctx : MockGraphicsContext;

    var nextPipelineID : Int;

    var nextSurfaceID : Int;

    public function new(_resourceEvents)
    {
        super(_resourceEvents);

        ctx            = new MockGraphicsContext();
        nextPipelineID = 0;
        nextSurfaceID  = 0;
    }

	public function getGraphicsContext():GraphicsContext
    {
		return ctx;
	}

	public function present()
    {
        //
    }

	public function createPipeline(_state : PipelineState)
    {
		return new PipelineID(nextPipelineID++);
	}

	public function deletePipeline(_pipeline : PipelineID)
    {
        //
    }

	public function createSurface(_state : SurfaceState)
    {
		return new SurfaceID(nextSurfaceID++);
	}

	public function deleteSurface(_id : SurfaceID)
    {
        //
    }

	public function updateTexture(_frame : PageFrameResource, _data : ArrayBufferView)
    {
        //
    }

	function createShader(_resource : DataBlobResource)
    {
        //
    }

	function deleteShader(_id : ResourceID)
    {
        //
    }

	function createTexture(_resource : DataBlobResource)
    {
        //
    }

	function deleteTexture(_id : ResourceID)
    {
        //
    }
}