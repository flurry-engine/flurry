package uk.aidanlee.flurry.api.gpu;

@:structInit
class DepthOptions
{
    public var depthTesting (default, null) : Bool;
    public var depthMasking (default, null) : Bool;
    public var depthFunction (default, null) : ComparisonFunction;

    public function equals(_other : DepthOptions) : Bool
    {
        return
            depthTesting  == _other.depthTesting &&
            depthMasking  == _other.depthMasking &&
            depthFunction == _other.depthFunction;
    }

    public function copyFrom(_other : DepthOptions)
    {
        depthTesting  = _other.depthTesting;
        depthMasking  = _other.depthMasking;
        depthFunction = _other.depthFunction;
    }
}