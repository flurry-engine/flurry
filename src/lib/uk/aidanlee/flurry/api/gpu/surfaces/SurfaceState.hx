package uk.aidanlee.flurry.api.gpu.surfaces;

@:publicFields @:structInit class SurfaceState
{
    /**
     * Width in pixels of the surface.
     */
    final width : Int;

    /**
     * Height in pixels of the surface.
     */
    final height : Int;

    /**
     * If the surface is flagged as volatile it will be cleared at the beginning of each frame.
     */
    final volatile = true;

    /**
     * If the surface should be created with a depth and stencil buffer.
     */
    final depthStencilBuffer = false;
}