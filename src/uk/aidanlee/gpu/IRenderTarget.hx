package uk.aidanlee.gpu;

/**
 * Render target interface.
 * 
 * Targets such as the backbuffer or render textures should implements this interface.
 */
interface IRenderTarget
{
    /**
     * target ID.
     */
    public var targetID : Int;

    /**
     * Width of the target.
     */
    public var width : Int;

    /**
     * Height of the target.
     */
    public var height : Int;

    /**
     * Float containing the scaling required.
     */
    public var viewportScale : Float;
}
