package uk.aidanlee.flurry.api.gpu.backend;

import uk.aidanlee.flurry.api.gpu.batcher.DrawCommand;
import uk.aidanlee.flurry.api.gpu.backend.IRendererBackend.ShaderLayout;
import uk.aidanlee.flurry.api.gpu.batcher.BufferDrawCommand;
import uk.aidanlee.flurry.api.gpu.batcher.GeometryDrawCommand;
import uk.aidanlee.flurry.api.resources.Resource.ImageResource;
import uk.aidanlee.flurry.api.resources.Resource.ShaderResource;

class NullBackend implements IRendererBackend
{
    /**
     * Shader sequence will simply be incremented each time a shader is created.
     */
    var shaderSequence : Int;

    /**
     * Texture sequence will simply be incremented each time a texture or target is created.
     */
    var textureSequence : Int;

    /**
     * Target sequence will simply be incremented each time a target is created.
     */
    var targetSequence : Int;

    public function new()
    {
        shaderSequence  = 0;
        textureSequence = 0;
        targetSequence  = 0;
    }

    /**
     * Clear the render target.
     */
    public function clear()
    {
        //
    }

    /**
     * Will clear any unchanging geometry in the renderer.
     */
    public function clearUnchanging()
    {
        //
    }

    /**
     * Called before any draw() functions.
     */
    public function preDraw()
    {
        //
    }

    /**
     * Upload geometries to the gpu VRAM.
     * @param _commands Array of commands to upload.
     */
    public function uploadGeometryCommands(_commands : Array<GeometryDrawCommand>) : Void {}

    /**
     * Upload buffer data to the gpu VRAM.
     * @param _commands Array of commands to upload.
     */
    public function uploadBufferCommands(_commands : Array<BufferDrawCommand>) : Void {}

    /**
     * Draw an array of commands. Command data must be uploaded to the GPU before being used.
     * @param _commands    Commands to draw.
     * @param _recordStats Record stats for this submit.
     */
    public function submitCommands(_commands : Array<DrawCommand>, _recordStats : Bool = true) : Void {}

    /**
     * Called after all draw() functions.
     */
    public function postDraw()
    {
        //
    }

    /**
     * Called when the game window is resized.
     * @param _width  new width of the window.
     * @param _height new height of the window.
     */
    public function resize(_width : Int, _height : Int)
    {
        //
    }

    /**
     * Cleans up any resources used by the backend.
     */
    public function cleanup()
    {
        //
    }

    /**
     * Creates a shader from a vertex and fragment source.
     * @param _vert Vertex shader source.
     * @param _frag Fragment shader source.
     * @return Shader
     */
    public function createShader(_resource : ShaderResource)
    {
        //
    }

    /**
     * Removes and frees the resources used by a shader.
     * @param _id Unique ID of the shader.
     */
    public function removeShader(_resource : ShaderResource)
    {
        //
    }

    /**
     * Creates a new texture given an array of pixel data.
     * @param _pixels R8G8B8A8 pixel data.
     * @param _width  Width of the texture.
     * @param _height Height of the texture.
     * @return Texture
     */
    public function createTexture(_resource : ImageResource)
    {
        //
    }

    /**
     * Removes and frees the resources used by a texture.
     * @param _id Unique ID of the texture.
     */
    public function removeTexture(_resource : ImageResource)
    {
        //
    }
}
