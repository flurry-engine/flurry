package uk.aidanlee.gpu;

/**
 * Backbuffer render target. This is the default window.
 */
class BackBuffer implements IRenderTarget
{
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

    /**
     * framebuffer ID.
     */
    public var targetID : Int;

    /**
     * Create a new backbuffer representation.
     * @param _width  Width of the window.
     * @param _height Height of the window.
     * @param _scale  Window scaling ratio. Probably only used in high DPI monitors.
     * @param _fb     Framebuffer ID.
     * @param _rb     Renderbuffer ID.
     */
    public function new(_id : Int, _width : Int, _height : Int, _scale : Float)
    {
        targetID      = _id;
        width         = _width;
        height        = _height;
        viewportScale = _scale;
    }
}
