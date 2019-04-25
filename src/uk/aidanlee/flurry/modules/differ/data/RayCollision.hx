package uk.aidanlee.flurry.modules.differ.data;

import uk.aidanlee.flurry.modules.differ.shapes.Ray;
import uk.aidanlee.flurry.modules.differ.shapes.Shape;

/**
 * Ray collision intersection data, obtained by testing a shape and a ray.
 */
class RayCollision
{
    /**
     * Shape the intersection was with.
     */
    public var shape (default, null) : Shape;

    /**
     * The ray involved in the intersection.
     */
    public var ray (default, null) : Ray;

    /**
     * Distance along ray that the intersection start at.
     */
    public var start (default, null) : Float;

    /**
     * Distance along ray that the intersection ended at.
     */
    public var end (default, null) : Float;

    /**
     * Create a new ray collision.
     * @param _shape The shape in the collision.
     * @param _ray   The ray in the collision.
     * @param _start The distance along the ray the collision starts.
     * @param _end   The distance from the end of the ray where the collision ends.
     */
    public inline function new(_shape : Shape, _ray : Ray, _start : Float, _end : Float)
    {
        shape = _shape;
        ray   = _ray;
        start = _start;
        end   = _end;
    }

    /**
     * Update the values of this ray collision.
     * @param _shape The shape in the collision.
     * @param _ray   The ray in the collision.
     * @param _start The distance along the ray the collision starts.
     * @param _end   The distance from the end of the ray where the collision ends.
     * @return RayCollision
     */
    public inline function set(_shape : Shape, _ray : Ray, _start : Float, _end : Float) : RayCollision
    {
        shape = _shape;
        ray   = _ray;
        start = _start;
        end   = _end;

        return this;
    }

    /**
     * Copy the values from another ray collision.
     * @param _other The ray collision to copy.
     * @return RayCollision
     */
    public inline function copyFrom(_other : RayCollision) : RayCollision
    {
        shape = _other.shape;
        ray   = _other.ray;
        start = _other.start;
        end   = _other.end;

        return this;
    }

    /**
     * Returns a copy of itself.
     * The shape and ray in this collision are not cloned.
     * @return RayCollision
     */
    public inline function clone() : RayCollision
    {
        return new RayCollision(shape, ray, start, end);
    }
}

/**
 * A static extension class helper for RayCollision
 */
class RayCollisionHelper
{
    /**
     * Get the start x point along the line.
     * 
     * It is possible the start point is not along the ray itself, when the `start` value is less than zero the ray start is inside the shape.
     * To get that point use `ray.start`.
     * ```
     * if (data.start < 0)
     * {
     *     point = data.ray.start;
     * }
     * else
     * {
     *     point = data.hitStart();
     * }
     * ```
     */
    public static inline function hitStartX(_data : RayCollision) : Float
    {
        return _data.ray.start.x + (_data.ray.dir.x * _data.start);
    }

    /**
     * Get the start y point along the line.
     * 
     * It is possible the start point is not along the ray itself when the `start` value is less than zero, ray start of the ray is inside the shape.
     * To get that point use `ray.start`.
     * ```
     * if (data.start < 0)
     * {
     *     point = data.ray.start;
     * }
     * else
     * {
     *     point = data.hitStart();
     * }
     * ```
     */
    public static inline function hitStartY(_data : RayCollision) : Float
    {
        return _data.ray.start.y + (_data.ray.dir.y * _data.start);
    }

    /**
     * Get the end x point along the line.
     * 
     * It is possible that this extends beyond the length of the ray when the `end` value is greater than 1, the end of the ray is inside the shape.
     * To get that point use `ray.end`.
     * ```
     * if (data.end > 1)
     * {
     *     point = data.ray.end;
     * }
     * else
     * {
     *     point = data.hitEnd();
     * }
     * ```
     */
    public static inline function hitEndX(_data : RayCollision) : Float
    {
        return _data.ray.start.x + (_data.ray.dir.x * _data.end);
    }

    /**
     * Get the end y point along the line.
     * 
     * It is possible that this extends beyond the length of the ray when the `end` value is greater than 1, the end of the ray is inside the shape.
     * To get that point use `ray.end`.
     * ```
     * if (data.end > 1)
     * {
     *     point = data.ray.end;
     * }
     * else
     * {
     *     point = data.hitEnd();
     * }
     * ```
     */
    public static inline function hitEndY(_data : RayCollision) : Float
    {
        return _data.ray.start.y + (_data.ray.dir.y * _data.end);
    }
}