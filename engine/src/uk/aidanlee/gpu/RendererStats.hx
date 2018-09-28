package uk.aidanlee.gpu;

class RendererStats
{
    public var totalBatchers : Int;
    public var totalGeometry : Int;
    public var totalVertices : Int;
    public var unchangingDraws : Int;
    public var dynamicDraws : Int;

    public var targetSwaps : Int;
    public var shaderSwaps : Int;
    public var textureSwaps : Int;
    public var scissorSwaps : Int;
    public var blendSwaps : Int;
    public var viewportSwaps : Int;

    public function new()
    {
        reset();
    }

    public function reset()
    {
        totalBatchers   = 0;
        totalGeometry   = 0;
        totalVertices   = 0;
        unchangingDraws = 0;
        dynamicDraws    = 0;

        targetSwaps   = 0;
        shaderSwaps   = 0;
        textureSwaps  = 0;
        scissorSwaps  = 0;
        blendSwaps    = 0;
        viewportSwaps = 0;
    }
}
