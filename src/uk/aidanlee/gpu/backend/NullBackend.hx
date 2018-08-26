package uk.aidanlee.gpu.backend;

import snow.api.buffers.Uint8Array;
import snow.api.buffers.Float32Array;
import uk.aidanlee.gpu.batcher.DrawCommand;
import uk.aidanlee.gpu.backend.IRendererBackend.ShaderLayout;

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
     * Draw vertex information contained within a buffer.
     * @param _buffer       32 bit float buffer containing vertex data.
     * @param _commands     Array of commands describing how the draw data into the buffer.
     * @param _disableStats If stats will not be counted for this draw. Useful for imgui stuff.
     */
    public function draw(_buffer : Float32Array, _commands : Array<DrawCommand>, _disableStats : Bool)
    {
        //
    }

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
    public function createShader(_vert : String, _frag : String, _layout : ShaderLayout) : Shader
    {
        return new Shader(shaderSequence++);
    }

    /**
     * Removes and frees the resources used by a shader.
     * @param _id Unique ID of the shader.
     */
    public function removeShader(_id : Int)
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
    public function createTexture(_pixels : Uint8Array, _width : Int, _height : Int) : Texture
    {
        return new Texture(textureSequence++, _width, _height);
    }

    /**
     * Removes and frees the resources used by a texture.
     * @param _id Unique ID of the texture.
     */
    public function removeTexture(_id : Int)
    {
        //
    }

    /**
     * Creates a render target which can be drawn to and used as a texture.
     * @param _width  Width of the target.
     * @param _height Height of the target.
     * @return RenderTexture
     */
    public function createRenderTarget(_width : Int, _height : Int) : RenderTexture
    {
        return new RenderTexture(targetSequence++, textureSequence++, _width, _height, 1);
    }

    /**
     * Frees the openGL resources used by a render target.
     * @param _target Unique ID of the target.
     */
    public function removeRenderTarget(_id : Int)
    {
        //
    }
}
