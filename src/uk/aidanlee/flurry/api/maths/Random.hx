package uk.aidanlee.flurry.api.maths;

/**
 * Copyright (c) 2017 the Kha Development Team
 * 
 * This software is provided 'as-is', without any express or implied
 * warranty. In no event will the authors be held liable for any damages
 * arising from the use of this software.
 * 
 * Permission is granted to anyone to use this software for any purpose,
 * including commercial applications, and to alter it and redistribute it
 * freely, subject to the following restrictions:
 * 
 * 1. The origin of this software must not be misrepresented; you must not
 * claim that you wrote the original software. If you use this software
 * in a product, an acknowledgment in the product documentation would be
 * appreciated but is not required.
 * 
 * 2. Altered source versions must be plainly marked as such, and must not be
 * misrepresented as being the original software.
 * 
 * 3. This notice may not be removed or altered from any source distribution.
 * 
 * Random number generator
 * 
 * Please use this one instead of the native Haxe one to.
 * keep consistency between different platforms.
 * 
 * Mersenne twister.
 */
class Random
{
    final mt : Array<Int>;

    var index : Int;

	public function new(_seed : Int)
    {
        index = 0;
		mt    = [];

		mt.push(_seed);
		for (i in 1...624)
        {
            mt.push(0x6c078965 * (mt[i - 1] ^ (mt[i - 1] >> 30)) + i);
        }
	}
	
	public function get() : Int
    {
		if (index == 0)
        {
            generateNumbers();
        }

		var y = mt[index];
		y = y ^ (y >> 11);
		y = y ^ ((y << 7) & (0x9d2c5680));
		y = y ^ ((y << 15) & (0xefc60000));
		y = y ^ (y >> 18);

		index = (index + 1) % 624;

		return y;
	}
	
	public function getFloat() : Float
    {
		return get() / 0x7ffffffe;
	}
	
	public function getUpTo(_max : Int) : Int
    {
		return get() % (_max + 1);
	}
	
	public function getIn(_min : Int, _max : Int) : Int
    {
		return get() % (_max + 1 - _min) + _min;
	}
	
	public function getFloatIn(_min : Float, _max : Float) : Float
    {
		return _min + getFloat() * (_max - _min);
	}
	
	private function generateNumbers(): Void
    {
		for (i in 0...624)
        {
			var y : Int = (mt[i] & 1) + (mt[(i + 1) % 624]) & 0x7fffffff;

			mt[i] = mt[(i + 397) % 624] ^ (y >> 1);

			if ((y % 2) != 0)
            {
                mt[i] = mt[i] ^ 0x9908b0df;
            }
		}
	}
}