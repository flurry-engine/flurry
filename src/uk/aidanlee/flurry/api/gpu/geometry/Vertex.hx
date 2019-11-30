package uk.aidanlee.flurry.api.gpu.geometry;

import uk.aidanlee.flurry.api.maths.Vector2;
import uk.aidanlee.flurry.api.maths.Vector3;

/**
 * Vertex class, contains the position, colour, and texture coordinates for this vertex.
 */
class Vertex
{
    /**
     * The position of this vertex.
     */
    public final position : Vector3;

    /**
     * The colour of this vertex.
     */
    public final color : Color;

    /**
     * The UV texture coordinates of this vertex.
     */
    public final texCoord : Vector2;

    /**
     * Creates a new vertex point.
     * @param _position This vertex's position.
     * @param _color    This vertex's colour.
     * @param _texCoord This vertex's UV texture coordinates.
     */
    public function new(_position : Vector3, _color : Color, _texCoord : Vector2)
    {
        position = _position;
        color    = _color;
        texCoord = _texCoord;
    }

    /**
     * Copy the position, colour, and texture coordinates of another vertex.
     * @param _other Vertex to copy from.
     * @return Vertex
     */
    public function copyFrom(_other : Vertex) : Vertex
    {
        position.copyFrom(_other.position);
        color   .copyFrom(_other.color);
        texCoord.copyFrom(_other.texCoord);

        return this;
    }

    /**
     * Return a clone of this vertex.
     * @return Vertex
     */
    public function clone() : Vertex
    {
        return new Vertex(position.clone(), color.clone(), texCoord.clone());
    }

    /**
     * Checks if another vertex is equal to this one.
     * @param _other Vertex to check with.
     * @return Bool
     */
    public function equals(_other : Vertex) : Bool
    {
        return position.equals(_other.position) && color.equals(_other.color) && texCoord.equals(_other.texCoord);
    }
}
