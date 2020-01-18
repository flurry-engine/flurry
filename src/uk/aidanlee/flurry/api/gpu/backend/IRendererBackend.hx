package uk.aidanlee.flurry.api.gpu.backend;

import uk.aidanlee.flurry.api.gpu.batcher.DrawCommand;

/**
 * Backend renderers should implements this interface.
 * Provides functions for drawing data and creating backend specific resources.
 */
interface IRendererBackend
{
    /**
     * Called before any draw() functions.
     */
    function preDraw() : Void;

    /**
     * Upload geometries to the gpu VRAM.
     * @param _commands Array of commands to upload.
     */
    function queue(_command : DrawCommand) : Void;

    /**
     * Draw an array of commands. Command data must be uploaded to the GPU before being used.
     * @param _commands    Commands to draw.
     * @param _recordStats Record stats for this submit.
     */
    function submit() : Void;

    /**
     * Called after all draw() functions.
     */
    function postDraw() : Void;

    /**
     * Call when destroying the renderer. Will cleanup any resources used by the backend.
     */
    function cleanup() : Void;
}
