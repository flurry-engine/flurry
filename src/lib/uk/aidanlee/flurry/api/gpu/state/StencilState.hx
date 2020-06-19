package uk.aidanlee.flurry.api.gpu.state;

@:structInit
class StencilState
{
    public var stencilTesting (default, null) : Bool;

    public var stencilFrontMask (default, null) : Int;
    public var stencilFrontFunction (default, null) : ComparisonFunction;
    public var stencilFrontTestFail (default, null) : StencilFunction;
    public var stencilFrontDepthTestFail (default, null) : StencilFunction;
    public var stencilFrontDepthTestPass (default, null) : StencilFunction;

    public var stencilBackMask (default, null) : Int;
    public var stencilBackFunction (default, null) : ComparisonFunction;
    public var stencilBackTestFail (default, null) : StencilFunction;
    public var stencilBackDepthTestFail (default, null) : StencilFunction;
    public var stencilBackDepthTestPass (default, null) : StencilFunction;

    public function equals(_other : StencilState) : Bool
    {
        return
            stencilTesting == _other.stencilTesting &&

            stencilFrontMask == _other.stencilFrontMask &&
            stencilFrontFunction == _other.stencilFrontFunction &&
            stencilFrontTestFail == _other.stencilFrontTestFail &&
            stencilFrontDepthTestFail == _other.stencilFrontDepthTestFail &&
            stencilFrontDepthTestPass == _other.stencilFrontDepthTestPass &&

            stencilBackMask == _other.stencilBackMask &&
            stencilBackFunction == _other.stencilBackFunction &&
            stencilBackTestFail == _other.stencilBackTestFail &&
            stencilBackDepthTestFail == _other.stencilBackDepthTestFail &&
            stencilBackDepthTestPass == _other.stencilBackDepthTestPass;
    }

    public function copyFrom(_other : StencilState)
    {
        stencilTesting = _other.stencilTesting;

        stencilFrontMask          = _other.stencilFrontMask;
        stencilFrontFunction      = _other.stencilFrontFunction;
        stencilFrontTestFail      = _other.stencilFrontTestFail;
        stencilFrontDepthTestFail = _other.stencilFrontDepthTestFail;
        stencilFrontDepthTestPass = _other.stencilFrontDepthTestPass;

        stencilBackMask          = _other.stencilBackMask;
        stencilBackFunction      = _other.stencilBackFunction;
        stencilBackTestFail      = _other.stencilBackTestFail;
        stencilBackDepthTestFail = _other.stencilBackDepthTestFail;
        stencilBackDepthTestPass = _other.stencilBackDepthTestPass;
    }
}