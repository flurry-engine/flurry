package uk.aidanlee.flurry.modules.differ.shapes;

import uk.aidanlee.flurry.api.maths.Maths;
import uk.aidanlee.flurry.api.maths.Vector;

/**
 * A ray with a start, end, direction, and infinite state for collision queries.
 */
class Ray
{
    /**
     * The start point of the ray.
     */
    public var start : Vector;

    /**
     * The end point of the ray.
     */
    public var end : Vector;

    /**
     * The direction of the ray.
     * Returns a cached vector, so modifying it will affect this instance.
     * Updates only when the dir value is accessed.
     */
    public var dir (get, never) : Vector;

    inline function get_dir() {
        dirCache.x = end.x - start.x;
        dirCache.y = end.y - start.y;
        
        return dirCache;
    }

    /**
     * The angle in degrees this ray is pointing in.
     */
    public var angle (get, never) : Float;

    inline function get_angle() {
        return Maths.toDegrees(Maths.atan2(end.y - start.y, end.x - start.x));
    }

    /**
     * Whether or not the ray is infinite.
     */
    public var infinite : InfiniteState;

    final dirCache : Vector;

    /**
     * Create a new ray with the start and end point, which determine the direction of the ray, and optionally specifying that this ray is infinite in some way.
     */
    public function new(_start : Vector, _end : Vector, ?_infinite : InfiniteState)
    {
        start    = _start;
        end      = _end;
        infinite = _infinite == null ? NotInfinite : _infinite;
        dirCache = new Vector(end.x - start.x, end.y - start.y);
    }
}

/**
 * A flag for the infinite state of a Ray.
 */
enum InfiniteState
{
    /**
     * The line is a fixed length between the start and end points.
     */
    NotInfinite;

    /**
     * The line is infinite from it's starting point.
     */
    InfiniteFromStart;

    /**
     * The line is infinite in both directions from it's starting point.
     */
    Infinite;
}