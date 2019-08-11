package uk.aidanlee.flurry.utils.opengl;

import opengl.GL.GLSync;

/**
 * Very simple wrapper around a GLSync object.
 * Needed to work around hxcpp's weirdness with native types in haxe arrays.
 */
class GLSyncWrapper
{
    public var sync : Null<GLSync>;

    public function new()
    {
        sync = null;
    }
}
