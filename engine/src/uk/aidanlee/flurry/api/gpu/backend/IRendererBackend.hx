package uk.aidanlee.flurry.api.gpu.backend;

import uk.aidanlee.flurry.api.gpu.batcher.BufferDrawCommand;
import uk.aidanlee.flurry.api.gpu.batcher.GeometryDrawCommand;
import uk.aidanlee.flurry.api.gpu.batcher.DrawCommand;

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
 * Describes the shader layout.
 */
typedef ShaderLayout = { textures : Array<String>, blocks : Array<ShaderBlock> };

/**
 * Describes the layout of a shader block.
 */
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
     * Call when destroying the renderer. Will cleanup any resources used by the backend.
     */
    public function cleanup() : Void;
}
