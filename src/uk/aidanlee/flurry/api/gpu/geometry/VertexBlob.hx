package uk.aidanlee.flurry.api.gpu.geometry;

import uk.aidanlee.flurry.api.buffers.Float32BufferData;

class VertexBlob
{
    final FLOATS_PER_VERTEX = 9;

    final buffer : Float32BufferData;

    final vertices : Int;

    final cachedIterator : VertexBlobIterator;

    public function new(_vertices : Int)
    {
        vertices       = _vertices;
        buffer         = new Float32BufferData(vertices * FLOATS_PER_VERTEX);
        cachedIterator = new VertexBlobIterator(vertices, buffer);
    }

    public function iterator(_reuse : Bool = true) : VertexBlobIterator
    {
        return _reuse ? cachedIterator.reset() : new VertexBlobIterator(vertices, buffer);
    }
}

private class VertexBlobIterator
{
    final buffer : Float32BufferData;

    final vertices : Int;

    final position : Float32BufferData;

    final colour : Float32BufferData;

    final texcoord : Float32BufferData;

    final vertex : Vertex;

    var current : Int;

    public function new(_vertices : Int, _buffer : Float32BufferData)
    {
        vertices = _vertices;
        buffer   = _buffer;
        current  = 0;

        position = buffer.sub(0, 3);
        colour   = buffer.sub(3, 4);
        texcoord = buffer.sub(7, 2);
        vertex   = new Vertex(position, colour, texcoord);
    }

    public function reset() : VertexBlobIterator
    {
        current = 0;

        return this;
    }

    public function hasNext() : Bool
    {
        return current < vertices;
    }

    public function next() : Vertex
    {
        final baseOffset = current++ * 9;

        position.offset = baseOffset + 0;
        colour.offset   = baseOffset + 3;
        texcoord.offset = baseOffset + 7;

        return vertex;
    }
}
