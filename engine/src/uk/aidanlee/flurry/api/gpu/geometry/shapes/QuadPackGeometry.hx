package uk.aidanlee.flurry.api.gpu.geometry.shapes;

import haxe.ds.Map;
import uk.aidanlee.flurry.api.importers.textureatlas.TextureAtlas;
import uk.aidanlee.flurry.api.gpu.geometry.Geometry.GeometryOptions;
import uk.aidanlee.flurry.api.gpu.geometry.Vertex;
import uk.aidanlee.flurry.api.maths.Vector;
import uk.aidanlee.flurry.api.maths.Rectangle;
import uk.aidanlee.flurry.api.maths.Hash;

class QuadPackGeometry extends Geometry
{
    /**
     * Map of packed quads keyed by their unique ID.
     */
    public final quads : Map<Int, PackedQuad>;

    public function new(_options : GeometryOptions)
    {
        super(_options);

        // Quadpack geometry must have a texture
        if (_options.textures.length == 0)
        {
            throw 'QuadPackGeometry Exception : Texture must not be null';
        }

        quads = new Map();
    }

    /**
     * Add a quad to this geometry.
     * @param _frame     Frame to UV this quad from.
     * @param _rectangle Rectangle containing the position and size of the quad.
     * @param _color     The colour tint of the quad.
     * @param _flipX     If the quads image should be flipped on its x axis. (defaults false)
     * @param _flipY     If the quads image should be flipped on its y axis. (defaults false)
     * @return Unique quad int ID.
     */
    public function add(_frame : TextureAtlasFrame, _rectangle : Rectangle, _color : Color, _flipX : Bool = false, _flipY : Bool = false) : Int
    {
        var id   = Hash.uniqueHash();
        var quad = new PackedQuad(id, [
            new Vertex( new Vector(_rectangle.x               , _rectangle.y               ), _color.clone(), new Vector(0, 0) ),
            new Vertex( new Vector(_rectangle.x + _rectangle.w, _rectangle.y               ), _color.clone(), new Vector(0, 0) ),
            new Vertex( new Vector(_rectangle.x + _rectangle.w, _rectangle.y + _rectangle.h), _color.clone(), new Vector(0, 0) ),

            new Vertex( new Vector(_rectangle.x               , _rectangle.y + _rectangle.h), _color.clone(), new Vector(0, 0) ),
            new Vertex( new Vector(_rectangle.x               , _rectangle.y               ), _color.clone(), new Vector(0, 0) ),
            new Vertex( new Vector(_rectangle.x + _rectangle.w, _rectangle.y + _rectangle.h), _color.clone(), new Vector(0, 0) )
        ]);

        applyUV(quad, _frame.region, _flipX, _flipY);
        addVertex(quad.vertices[0]);
        addVertex(quad.vertices[1]);
        addVertex(quad.vertices[2]);
        addVertex(quad.vertices[3]);
        addVertex(quad.vertices[4]);
        addVertex(quad.vertices[5]);

        quads.set(id, quad);

        return id;
    }

    /**
     * Add a quad to this geometry.
     * @param _frame Frame to UV this quad from.
     * @param _x     X position of this quad.
     * @param _y     Y position of this quad.
     * @param _w     Width of this quad.
     * @param _h     Height of this quad.
     * @param _color The colour tint of the quad.
     * @param _flipX If the quads image should be flipped on its x axis. (defaults false)
     * @param _flipY If the quads image should be flipped on its y axis. (defaults false)
     * @return Unique quad int ID.
     */
    public function add_xywh(_frame : TextureAtlasFrame, _x : Float, _y : Float, _w : Float, _h : Float, _color : Color, _flipX : Bool = false, _flipY : Bool = false) : Int
    {
        var id   = Hash.uniqueHash();
        var quad = new PackedQuad(id, [
            new Vertex( new Vector(_x     , _y     ), _color.clone(), new Vector(0, 0) ),
            new Vertex( new Vector(_x + _w, _y     ), _color.clone(), new Vector(0, 0) ),
            new Vertex( new Vector(_x + _w, _y + _h), _color.clone(), new Vector(0, 0) ),

            new Vertex( new Vector(_x     , _y + _h), _color.clone(), new Vector(0, 0) ),
            new Vertex( new Vector(_x     , _y     ), _color.clone(), new Vector(0, 0) ),
            new Vertex( new Vector(_x + _w, _y + _h), _color.clone(), new Vector(0, 0) )
        ]);

        applyUV(quad, _frame.region, _flipX, _flipY);
        addVertex(quad.vertices[0]);
        addVertex(quad.vertices[1]);
        addVertex(quad.vertices[2]);
        addVertex(quad.vertices[3]);
        addVertex(quad.vertices[4]);
        addVertex(quad.vertices[5]);

        quads.set(id, quad);

        return id;
    }

    /**
     * Add a quad to this geometry.
     * Vector objects passed are NOT cloned.
     * @param _frame Frame to UV this quad from.
     * @param _p1    Top left position of the quad.
     * @param _p2    Top right position of the quad.
     * @param _p3    Bottom right position of the quad.
     * @param _p4    Bottom left position of the quad.
     * @param _color The colour tint of the quad.
     * @param _flipX If the quads image should be flipped on its x axis. (defaults false)
     * @param _flipY If the quads image should be flipped on its y axis. (defaults false)
     * @return Unique quad int ID.
     */
    public function add_quad(_frame : TextureAtlasFrame, _p1 : Vector, _p2 : Vector, _p3 : Vector, _p4 : Vector, _color : Color, _flipX : Bool = false, _flipY : Bool = false) : Int
    {
        var id   = Hash.uniqueHash();
        var quad = new PackedQuad(id, [
            new Vertex( _p1, _color.clone(), new Vector(0, 0) ),
            new Vertex( _p2, _color.clone(), new Vector(0, 0) ),
            new Vertex( _p3, _color.clone(), new Vector(0, 0) ),

            new Vertex( _p4, _color.clone(), new Vector(0, 0) ),
            new Vertex( _p1, _color.clone(), new Vector(0, 0) ),
            new Vertex( _p3, _color.clone(), new Vector(0, 0) )
        ]);

        applyUV(quad, _frame.region, _flipX, _flipY);
        addVertex(quad.vertices[0]);
        addVertex(quad.vertices[1]);
        addVertex(quad.vertices[2]);
        addVertex(quad.vertices[3]);
        addVertex(quad.vertices[4]);
        addVertex(quad.vertices[5]);

        quads.set(id, quad);

        return id;
    }

    /**
     * Removes all quads from this geometry.
     */
    public function clear()
    {
        for (key in quads.keys())
        {
            quadRemove(key);
        }
    }

    /**
     * Remove a specific quad from this geometry.
     * @param _id ID of the quad to remove.
     */
    public function quadRemove(_id : Int)
    {
        var quad = quads.get(_id);

        if (quad != null)
        {
            removeVertex(quad.vertices[0]);
            removeVertex(quad.vertices[1]);
            removeVertex(quad.vertices[2]);
            removeVertex(quad.vertices[3]);
            removeVertex(quad.vertices[4]);
            removeVertex(quad.vertices[5]);

            quads.remove(_id);
        }
    }

    /**
     * Set the visibility of a specific quad.
     * @param _id      ID of the quad.
     * @param _visible If this quad will be visible.
     */
    public function quadVisible(_id : Int, _visible : Bool)
    {
        var quad = quads.get(_id);

        if (quad != null)
        {
            for (vertex in quad.vertices)
            {
                vertex.color.a = _visible ? 1 : 0;
            }
        }
    }

    /**
     * Resize a specific quad.
     * @param _id   ID of the quad.
     * @param _size Rectangle containing the quads new size.
     */
    public function quadResize(_id : Int, _size : Rectangle)
    {
        var quad = quads.get(_id);

        if (quad != null)
        {
            quad.vertices[0].position.set_xy(_size.x          , _size.y          );
            quad.vertices[1].position.set_xy(_size.x + _size.w, _size.y          );
            quad.vertices[2].position.set_xy(_size.x + _size.w, _size.y + _size.h);

            quad.vertices[3].position.set_xy(_size.x          , _size.y + _size.h);
            quad.vertices[4].position.set_xy(_size.x          , _size.y          );
            quad.vertices[5].position.set_xy(_size.x + _size.w, _size.y + _size.h);
        }
    }

    /**
     * Set the position of a specific quad.
     * @param _id       ID of the quad.
     * @param _position Vector containing the quads new position.
     */
    public function quadPosition(_id : Int, _position : Vector)
    {
        var quad = quads.get(_id);

        if (quad != null)
        {
            var diffx = _position.x - quad.vertices[0].position.x;
            var diffy = _position.y - quad.vertices[0].position.y;

            for (vertex in quad.vertices)
            {
                vertex.position.x += diffx;
                vertex.position.y += diffy;
            }
        }
    }

    /**
     * Set the colour of a specific quad.
     * Colour objects values are copied.
     * @param _id    ID of the quad.
     * @param _color Colour to set the quad.
     */
    public function quadColor(_id : Int, _color : Color)
    {
        var quad = quads.get(_id);

        if (quad != null)
        {
            for (vertex in quad.vertices)
            {
                vertex.color.copyFrom(_color);
            }
        }
    }

    /**
     * Set only the alpha of a specific quad.
     * @param _id    ID of the quad.
     * @param _alpha Normalized alpha value to set the quad.
     */
    public function quadAlpha(_id : Int, _alpha : Float)
    {
        var quad = quads.get(_id);

        if (quad != null)
        {
            for (vertex in quad.vertices)
            {
                vertex.color.a = _alpha;
            }
        }
    }

    /**
     * Set the image of a specific quad.
     * @param _id    ID of the quad.
     * @param _frame Texture atlas frame to set this quad.
     * @param _flipX If the texture is to be flipped on the x axis. (defaults false)
     * @param _flipY If the texture is to be flipped on the y axis. (defaults false)
     */
    public function quadTile(_id : Int, _frame : TextureAtlasFrame, _flipX : Bool = false, _flipY : Bool = false)
    {
        var quad = quads.get(_id);

        if (quad != null)
        {
            applyUV(quad, _frame.region, _flipX, _flipY);
        }
    }

    /**
     * Set the x flip state of a specific quad.
     * @param _id   ID of the quad.
     * @param _flip If the texture of the quad will be flipped on the x axis.
     */
    public function quadFlipX(_id : Int, _flip : Bool)
    {
        var quad = quads.get(_id);

        if (quad != null)
        {
            applyUV(quad, quad.uv, _flip, quad.flipY);
        }
    }

    /**
     * Set the y flip state of a specific quad.
     * @param _id   ID of the quad.
     * @param _flip If the texture of the quad will be flipped on the x axis.
     */
    public function quadFlipY(_id : Int, _flip : Bool)
    {
        var quad = quads.get(_id);

        if (quad != null)
        {
            applyUV(quad, quad.uv, quad.flipX, _flip);
        }
    }

    /**
     * Applys UV texturing to a specific quad.
     * @param _quad  Quad to texture.
     * @param _uv    UV rectangle. (not normalised)
     * @param _flipX If it is to be flipped on the x axis.
     * @param _flipY If it is to be flipped on the y axis.
     */
    function applyUV(_quad : PackedQuad, _uv : Rectangle, _flipX : Bool, _flipY : Bool)
    {
        var sz_x = _uv.w / textures[0].width;
        var sz_y = _uv.h / textures[0].height;

        // Top left
        var tl_x = _uv.x / textures[0].width;
        var tl_y = _uv.y / textures[0].height;

        // Top right
        var tr_x = tl_x + sz_x;
        var tr_y = tl_y;

        // Bottom right
        var br_x = tl_x + sz_x;
        var br_y = tl_y + sz_y;

        // Bottom left
        var bl_x = tl_x;
        var bl_y = tl_y + sz_y;

        var tmp_x = 0.0;
        var tmp_y = 0.0;

        // flipped x swaps tl and bl with tr and br, only on x
        if (_flipX)
        {
            //swap tl and tr
            tmp_x = tr_x;
            tr_x  = tl_x;
            tl_x  = tmp_x;

            //swap bl and br
            tmp_x = br_x;
            br_x  = bl_x;
            bl_x  = tmp_x;
        }

        // flipped y swaps tl and tr with bl and br, only on y
        if (_flipY)
        {
            //swap tl and bl
            tmp_y = bl_y;
            bl_y  = tl_y;
            tl_y  = tmp_y;

            //swap tr and br
            tmp_y = br_y;
            br_y  = tr_y;
            tr_y  = tmp_y;
        }

        _quad.vertices[0].texCoord.set_xy(tl_x, tl_y);
        _quad.vertices[1].texCoord.set_xy(tr_x, tr_y);
        _quad.vertices[2].texCoord.set_xy(br_x, br_y);

        _quad.vertices[3].texCoord.set_xy(bl_x, bl_y);
        _quad.vertices[4].texCoord.set_xy(tl_x, tl_y);
        _quad.vertices[5].texCoord.set_xy(br_x, br_y);

        _quad.uv.copyFrom(_uv);
        _quad.flipX = _flipX;
        _quad.flipY = _flipY;
    }
}

/**
 * Class which stores information about a specific quad.
 */
private class PackedQuad
{
    /**
     * Unique ID of this quad.
     * This is the key into the quads map.
     */
    public final id : Int;

    /**
     * The six vertices of this quad.
     */
    public final vertices : Array<Vertex>;

    /**
     * The current (un-normalised) UV rectangle of this quad.
     * Changing this does not change the actual quads UV.
     */
    public final uv : Rectangle;

    /**
     * If this quad is flipped on its x axis.
     * Changing this does not change if the quad is flipped.
     */
    public var flipX : Bool;

    /**
     * If this quad is flipped on its y axis.
     * Changing this does not change if the quad is flipped.
     */
    public var flipY : Bool;

    public function new(_id : Int, _vertices : Array<Vertex>)
    {
        id       = _id;
        vertices = _vertices;
        uv       = new Rectangle();
        flipX    = false;
        flipY    = false;
    }
}
