package uk.aidanlee.flurry.api.gpu.state;

@:structInit
class DepthState
{
    public var depthTesting (default, null) : Bool;
    public var depthMasking (default, null) : Bool;
    public var depthFunction (default, null) : ComparisonFunction;

    public function equals(_other : DepthState) : Bool
    {
        return
            depthTesting  == _other.depthTesting &&
            depthMasking  == _other.depthMasking &&
            depthFunction == _other.depthFunction;
    }

    public function copyFrom(_other : DepthState)
    {
        depthTesting  = _other.depthTesting;
        depthMasking  = _other.depthMasking;
        depthFunction = _other.depthFunction;
    }
}