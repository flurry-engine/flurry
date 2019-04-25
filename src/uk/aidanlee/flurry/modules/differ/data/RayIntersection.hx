package uk.aidanlee.flurry.modules.differ.data;

import uk.aidanlee.flurry.modules.differ.shapes.Ray;

/**
 * Ray intersection data obtained by testing two rays for intersection.
 */
class RayIntersection
{
    /**
     * The first ray in the test
     */
    public var ray1 (default, null) : Ray;

    /**
     * The second ray in the test
     */
    public var ray2 (default, null) : Ray;

    /**
     * u value for ray1.
     */
    public var u1 (default, null) : Float;

    /**
     * u value for ray2.
     */
    public var u2 (default, null) : Float;

    /**
     * Create a new ray intersection collision result.
     * @param _ray1 First ray in the collision.
     * @param _ray2 Second Ray in the collision
     * @param _u1 u value for ray 1.
     * @param _u2 u value for ray 2.
     */
    public inline function new(_ray1 : Ray, _ray2 : Ray, _u1 : Float, _u2 : Float)
    {
        ray1 = _ray1;
        ray2 = _ray2;
        u1   = _u1;
        u2   = _u2;
    }

    /**
     * Copy the values from another ray intersection
     * @param _other The ray intersection to copy.
     * @return RayIntersection
     */
    public inline function copyFrom(_other : RayIntersection) : RayIntersection
    {
        ray1 = _other.ray1;
        ray2 = _other.ray2;
        u1   = _other.u1;
        u2   = _other.u2;

        return this;
    }

    /**
     * Update the values of this ray collision.
     * @param _ray1 First ray in the collision.
     * @param _ray2 Second Ray in the collision
     * @param _u1 u value for ray 1.
     * @param _u2 u value for ray 2.
     * @return RayIntersection
     */
    public inline function set(_ray1 : Ray, _ray2 : Ray, _u1 : Float, _u2 : Float) : RayIntersection
    {
        ray1 = _ray1;
        ray2 = _ray2;
        u1   = _u1;
        u2   = _u2;

        return this;
    }

    /**
     * Returns a copy of itself.
     * The rays in this collision are not cloned.
     * @return RayIntersection
     */
    public inline function clone() : RayIntersection
    {
        return new RayIntersection(ray1, ray2, u1, u2);
    }
}