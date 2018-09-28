package uk.aidanlee.gpu.geometry;

import uk.aidanlee.maths.Vector;

/**
 * Vertex class, contains the position, colour, and texture coordinates for this vertex.
 */
class Vertex
{
    /**
     * The position of this vertex.
     */
    public final position : Vector;

    /**
     * The colour of this vertex.
     */
    public final color : Color;

    /**
     * The UV texture coordinates of this vertex.
     */
    public final texCoord : Vector;

    /**
     * Creates a new vertex point.
     * @param _position This vertex's position.
     * @param _color    This vertex's colour.
     * @param _texCoord This vertex's UV texture coordinates.
     */
    inline public function new(_position : Vector, _color : Color, _texCoord : Vector)
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
    inline public function copyFrom(_other : Vertex) : Vertex
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
    inline public function clone() : Vertex
    {
        return new Vertex(position.clone(), color.clone(), texCoord.clone());
    }

    /**
     * Checks if another vertex is equal to this one.
     * @param _other Vertex to check with.
     * @return Bool
     */
    inline public function equals(_other : Vertex) : Bool
    {
        return position.equals(_other.position) && color.equals(_other.color) && texCoord.equals(_other.texCoord);
    }
}
