package uk.aidanlee.flurry.api.gpu.state;

import uk.aidanlee.flurry.api.maths.Maths;

abstract DepthState(Int)
{
	public static final none = new DepthState(false, false, Always);

	public var enabled (get, never) : Bool;

	inline function get_enabled() return this & 0x1 == 1;

	public var masking (get, never) : Bool;

	inline function get_masking() return this >>> 1 & 0x1 == 1;

	public var func (get, never) : ComparisonFunction;

	inline function get_func() return cast this >>> 2 & 0x7;

	public inline function new(_enabled : Bool, _masking : Bool, _func : ComparisonFunction)
	{
		this = (((_func << 1) | (Maths.boolToInt(_masking) & 1)) << 1) | (Maths.boolToInt(_enabled) & 0x1);
    }
    
    public inline function equal(_rhs : Int) return this == _rhs;

    public inline function notEqual(_rhs : Int) return this != _rhs;
}