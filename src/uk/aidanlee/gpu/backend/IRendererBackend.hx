package uk.aidanlee.gpu.backend;

import uk.aidanlee.gpu.batcher.BufferDrawCommand;
import uk.aidanlee.gpu.batcher.GeometryDrawCommand;
import snow.api.buffers.Float32Array;
import snow.api.buffers.Uint8Array;
import uk.aidanlee.gpu.batcher.DrawCommand;

/**
 * Enum of all the shader types. These map onto whatever backend shader language types.
 * More will be added as and when needed.
 */
enum ShaderType {
    Matrix4;
    Vector4;
    Int;
}

/**
 * Anonymouse structure for describing the layout of a shader.
 * Shaders currently require several built in uniforms / blocks to draw stuff. Check each backends documentation for what is needed.
 */
typedef ShaderLayout = { textures : Array<String>, blocks : Array<ShaderBlock> };
typedef ShaderBlock  = { name : String, vals : Array<{ name : String, type : String }> };

/**
 * Backend renderers should implements this interface.
 * Provides functions for drawing data and creating backend specific resources.
 */
interface IRendererBackend
{
    /**
     * Clear the render target.
     */
    public function clear() : Void;

    /**
     * Will clear any unchanging geometry in the renderer.
     */
    public function clearUnchanging() : Void;

    /**
     * Called before any draw() functions.
     */
    public function preDraw() : Void;

    /**
     * Upload geometries to the gpu VRAM.
     * @param _commands Array of commands to upload.
     */
    public function uploadGeometryCommands(_commands : Array<GeometryDrawCommand>) : Void;

    /**
     * Upload buffer data to the gpu VRAM.
     * @param _commands Array of commands to upload.
     */
    public function uploadBufferCommands(_commands : Array<BufferDrawCommand>) : Void;

    /**
     * Draw an array of commands. Command data must be uploaded to the GPU before being used.
     * @param _commands    Commands to draw.
     * @param _recordStats Record stats for this submit.
     */
    public function submitCommands(_commands : Array<DrawCommand>, _recordStats : Bool = true) : Void;

    /**
     * Called after all draw() functions.
     */
    public function postDraw() : Void;

    /**
     * Called when the game window is resized.
     * @param _width  new width of the window.
     * @param _height new height of the window.
     */
    public function resize(_width : Int, _height : Int) : Void;

    /**
     * Creates a shader from a vertex and fragment source.
     * @param _vert Vertex shader source.
     * @param _frag Fragment shader source.
     * @return Shader
     */
    public function createShader(_vert : String, _frag : String, _layout : ShaderLayout) : Shader;

    /**
     * Removes and frees the resources used by a shader.
     * @param _id Unique ID of the shader.
     */
    public function removeShader(_id : Int) : Void;

    /**
     * Creates a new texture given an array of pixel data.
     * @param _pixels R8G8B8A8 pixel data.
     * @param _width  Width of the texture.
     * @param _height Height of the texture.
     * @return Texture
     */
    public function createTexture(_pixels : Uint8Array, _width : Int, _height : Int) : Texture;

    /**
     * Removes and frees the resources used by a texture.
     * @param _id Unique ID of the texture.
     */
    public function removeTexture(_id : Int) : Void;

    /**
     * Creates a render target which can be drawn to and used as a texture.
     * @param _width  Width of the target.
     * @param _height Height of the target.
     * @return RenderTexture
     */
    public function createRenderTarget(_width : Int, _height : Int) : RenderTexture;

    /**
     * Frees the openGL resources used by a render target.
     * @param _target Unique ID of the target.
     */
    public function removeRenderTarget(_id : Int) : Void;

    /**
     * Call when destroying the renderer. Will cleanup any resources used by the backend.
     */
    public function cleanup() : Void;
}
