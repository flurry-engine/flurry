package tests.api.gpu.geometry.shapes;

import uk.aidanlee.flurry.api.maths.Rectangle;
import uk.aidanlee.flurry.api.maths.Vector;
import uk.aidanlee.flurry.api.gpu.camera.Camera;
import uk.aidanlee.flurry.api.gpu.batcher.Batcher;
import uk.aidanlee.flurry.api.gpu.geometry.shapes.QuadPackGeometry;
import uk.aidanlee.flurry.api.gpu.geometry.Color;
import uk.aidanlee.flurry.api.importers.textureatlas.TextureAtlasParser;
import uk.aidanlee.flurry.api.resources.Resource.ShaderResource;
import uk.aidanlee.flurry.api.resources.Resource.ImageResource;
import mockatoo.Mockatoo.*;
import buddy.BuddySuite;

using mockatoo.Mockatoo;
using buddy.Should;

class QuadPackGeometryTests extends BuddySuite
{
    var geom : QuadPackGeometry;

    public function new()
    {
        describe('QuadPackGeometry', {

            var atlas   = TextureAtlasParser.parse(haxe.Resource.getString('atlasData'));
            var texture = mock(ImageResource);
            var batcher = new Batcher({
                camera : mock(Camera),
                shader : mock(ShaderResource)
            });

            texture.width .returns(atlas.size.x);
            texture.height.returns(atlas.size.y);

            beforeEach({
                geom = new QuadPackGeometry({
                    textures : [ texture ],
                    batchers : [ batcher ]
                });
            });

            afterEach({
                batcher.removeGeometry(geom);
            });
            
            it('Can add a quad using a rectangle as the size', {
                var name = 'cavesofgallet';
                var tile = atlas.findRegion(name);
                var size = new Rectangle(32, 48, 62, 96);

                geom.add(tile, size, geom.color);

                // Check position
                geom.vertices[0].position.x.should.be(size.x);
                geom.vertices[0].position.y.should.be(size.y);
                geom.vertices[1].position.x.should.be(size.x + size.w);
                geom.vertices[1].position.y.should.be(size.y);
                geom.vertices[2].position.x.should.be(size.x + size.w);
                geom.vertices[2].position.y.should.be(size.y + size.h);

                geom.vertices[3].position.x.should.be(size.x);
                geom.vertices[3].position.y.should.be(size.y + size.h);
                geom.vertices[4].position.x.should.be(size.x);
                geom.vertices[4].position.y.should.be(size.y);
                geom.vertices[5].position.x.should.be(size.x + size.w);
                geom.vertices[5].position.y.should.be(size.y + size.h);

                // Check colour
                geom.vertices[0].color.equals(geom.color).should.be(true);
                geom.vertices[1].color.equals(geom.color).should.be(true);
                geom.vertices[2].color.equals(geom.color).should.be(true);

                geom.vertices[3].color.equals(geom.color).should.be(true);
                geom.vertices[4].color.equals(geom.color).should.be(true);
                geom.vertices[5].color.equals(geom.color).should.be(true);

                // Check UV
                geom.vertices[0].texCoord.equals(new Vector(tile.region.x                   / texture.width, tile.region.y                   / texture.height)).should.be(true);
                geom.vertices[1].texCoord.equals(new Vector((tile.region.x + tile.region.w) / texture.width, tile.region.y                   / texture.height)).should.be(true);
                geom.vertices[2].texCoord.equals(new Vector((tile.region.x + tile.region.w) / texture.width, (tile.region.y + tile.region.h) / texture.height)).should.be(true);

                geom.vertices[3].texCoord.equals(new Vector(tile.region.x                   / texture.width, (tile.region.y + tile.region.h) / texture.height)).should.be(true);
                geom.vertices[4].texCoord.equals(new Vector(tile.region.x                   / texture.width, tile.region.y                   / texture.height)).should.be(true);
                geom.vertices[5].texCoord.equals(new Vector((tile.region.x + tile.region.w) / texture.width, (tile.region.y + tile.region.h) / texture.height)).should.be(true);
            });

            it('Can add a quad using a rectangle as the size and flip the UV on the x axis', {
                var name = 'cavesofgallet';
                var tile = atlas.findRegion(name);
                var size = new Rectangle(32, 48, 62, 96);

                geom.add(tile, size, geom.color, true);

                // Check position
                geom.vertices[0].position.x.should.be(size.x);
                geom.vertices[0].position.y.should.be(size.y);
                geom.vertices[1].position.x.should.be(size.x + size.w);
                geom.vertices[1].position.y.should.be(size.y);
                geom.vertices[2].position.x.should.be(size.x + size.w);
                geom.vertices[2].position.y.should.be(size.y + size.h);

                geom.vertices[3].position.x.should.be(size.x);
                geom.vertices[3].position.y.should.be(size.y + size.h);
                geom.vertices[4].position.x.should.be(size.x);
                geom.vertices[4].position.y.should.be(size.y);
                geom.vertices[5].position.x.should.be(size.x + size.w);
                geom.vertices[5].position.y.should.be(size.y + size.h);

                // Check colour
                geom.vertices[0].color.equals(geom.color).should.be(true);
                geom.vertices[1].color.equals(geom.color).should.be(true);
                geom.vertices[2].color.equals(geom.color).should.be(true);

                geom.vertices[3].color.equals(geom.color).should.be(true);
                geom.vertices[4].color.equals(geom.color).should.be(true);
                geom.vertices[5].color.equals(geom.color).should.be(true);

                // Check UV
                geom.vertices[0].texCoord.equals(new Vector((tile.region.x + tile.region.w) / texture.width,  tile.region.y                  / texture.height)).should.be(true);
                geom.vertices[1].texCoord.equals(new Vector( tile.region.x                  / texture.width,  tile.region.y                  / texture.height)).should.be(true);
                geom.vertices[2].texCoord.equals(new Vector( tile.region.x                  / texture.width, (tile.region.y + tile.region.h) / texture.height)).should.be(true);

                geom.vertices[3].texCoord.equals(new Vector((tile.region.x + tile.region.w) / texture.width, (tile.region.y + tile.region.h) / texture.height)).should.be(true);
                geom.vertices[4].texCoord.equals(new Vector((tile.region.x + tile.region.w) / texture.width,  tile.region.y                  / texture.height)).should.be(true);
                geom.vertices[5].texCoord.equals(new Vector( tile.region.x                  / texture.width, (tile.region.y + tile.region.h) / texture.height)).should.be(true);
            });

            it('Can add a quad using a rectangle as the size and flip the UV on the y axis', {
                var name = 'cavesofgallet';
                var tile = atlas.findRegion(name);
                var size = new Rectangle(32, 48, 62, 96);

                geom.add(tile, size, geom.color, false, true);

                // Check position
                geom.vertices[0].position.x.should.be(size.x);
                geom.vertices[0].position.y.should.be(size.y);
                geom.vertices[1].position.x.should.be(size.x + size.w);
                geom.vertices[1].position.y.should.be(size.y);
                geom.vertices[2].position.x.should.be(size.x + size.w);
                geom.vertices[2].position.y.should.be(size.y + size.h);

                geom.vertices[3].position.x.should.be(size.x);
                geom.vertices[3].position.y.should.be(size.y + size.h);
                geom.vertices[4].position.x.should.be(size.x);
                geom.vertices[4].position.y.should.be(size.y);
                geom.vertices[5].position.x.should.be(size.x + size.w);
                geom.vertices[5].position.y.should.be(size.y + size.h);

                // Check colour
                geom.vertices[0].color.equals(geom.color).should.be(true);
                geom.vertices[1].color.equals(geom.color).should.be(true);
                geom.vertices[2].color.equals(geom.color).should.be(true);

                geom.vertices[3].color.equals(geom.color).should.be(true);
                geom.vertices[4].color.equals(geom.color).should.be(true);
                geom.vertices[5].color.equals(geom.color).should.be(true);

                // Check UV
                geom.vertices[0].texCoord.equals(new Vector( tile.region.x                  / texture.width, (tile.region.y + tile.region.h) / texture.height)).should.be(true);
                geom.vertices[1].texCoord.equals(new Vector((tile.region.x + tile.region.w) / texture.width, (tile.region.y + tile.region.h) / texture.height)).should.be(true);
                geom.vertices[2].texCoord.equals(new Vector((tile.region.x + tile.region.w) / texture.width,  tile.region.y                  / texture.height)).should.be(true);

                geom.vertices[3].texCoord.equals(new Vector( tile.region.x                  / texture.width,  tile.region.y                  / texture.height)).should.be(true);
                geom.vertices[4].texCoord.equals(new Vector( tile.region.x                  / texture.width, (tile.region.y + tile.region.h) / texture.height)).should.be(true);
                geom.vertices[5].texCoord.equals(new Vector((tile.region.x + tile.region.w) / texture.width,  tile.region.y                  / texture.height)).should.be(true);
            });

            it('Can add a quad using a rectangle as the size and flip the UV on the x and y axis', {
                var name = 'cavesofgallet';
                var tile = atlas.findRegion(name);
                var size = new Rectangle(32, 48, 62, 96);

                geom.add(tile, size, geom.color, true, true);

                // Check position
                geom.vertices[0].position.x.should.be(size.x);
                geom.vertices[0].position.y.should.be(size.y);
                geom.vertices[1].position.x.should.be(size.x + size.w);
                geom.vertices[1].position.y.should.be(size.y);
                geom.vertices[2].position.x.should.be(size.x + size.w);
                geom.vertices[2].position.y.should.be(size.y + size.h);

                geom.vertices[3].position.x.should.be(size.x);
                geom.vertices[3].position.y.should.be(size.y + size.h);
                geom.vertices[4].position.x.should.be(size.x);
                geom.vertices[4].position.y.should.be(size.y);
                geom.vertices[5].position.x.should.be(size.x + size.w);
                geom.vertices[5].position.y.should.be(size.y + size.h);

                // Check colour
                geom.vertices[0].color.equals(geom.color).should.be(true);
                geom.vertices[1].color.equals(geom.color).should.be(true);
                geom.vertices[2].color.equals(geom.color).should.be(true);

                geom.vertices[3].color.equals(geom.color).should.be(true);
                geom.vertices[4].color.equals(geom.color).should.be(true);
                geom.vertices[5].color.equals(geom.color).should.be(true);

                // Check UV
                geom.vertices[0].texCoord.equals(new Vector((tile.region.x + tile.region.w) / texture.width, (tile.region.y + tile.region.h) / texture.height)).should.be(true);
                geom.vertices[1].texCoord.equals(new Vector( tile.region.x                  / texture.width, (tile.region.y + tile.region.h) / texture.height)).should.be(true);
                geom.vertices[2].texCoord.equals(new Vector( tile.region.x                  / texture.width,  tile.region.y                  / texture.height)).should.be(true);

                geom.vertices[3].texCoord.equals(new Vector((tile.region.x + tile.region.w) / texture.width,  tile.region.y                  / texture.height)).should.be(true);
                geom.vertices[4].texCoord.equals(new Vector((tile.region.x + tile.region.w) / texture.width, (tile.region.y + tile.region.h) / texture.height)).should.be(true);
                geom.vertices[5].texCoord.equals(new Vector( tile.region.x                  / texture.width,  tile.region.y                  / texture.height)).should.be(true);
            });

            it('Can add a quad using four floats as the size', {
                var name = 'cavesofgallet';
                var tile = atlas.findRegion(name);
                var size = new Rectangle(32, 48, 62, 96);

                geom.add_xywh(tile, size.x, size.y, size.w, size.h, geom.color);

                // Check position
                geom.vertices[0].position.x.should.be(size.x);
                geom.vertices[0].position.y.should.be(size.y);
                geom.vertices[1].position.x.should.be(size.x + size.w);
                geom.vertices[1].position.y.should.be(size.y);
                geom.vertices[2].position.x.should.be(size.x + size.w);
                geom.vertices[2].position.y.should.be(size.y + size.h);

                geom.vertices[3].position.x.should.be(size.x);
                geom.vertices[3].position.y.should.be(size.y + size.h);
                geom.vertices[4].position.x.should.be(size.x);
                geom.vertices[4].position.y.should.be(size.y);
                geom.vertices[5].position.x.should.be(size.x + size.w);
                geom.vertices[5].position.y.should.be(size.y + size.h);

                // Check colour
                geom.vertices[0].color.equals(geom.color).should.be(true);
                geom.vertices[1].color.equals(geom.color).should.be(true);
                geom.vertices[2].color.equals(geom.color).should.be(true);

                geom.vertices[3].color.equals(geom.color).should.be(true);
                geom.vertices[4].color.equals(geom.color).should.be(true);
                geom.vertices[5].color.equals(geom.color).should.be(true);

                // Check UV
                geom.vertices[0].texCoord.equals(new Vector(tile.region.x                   / texture.width, tile.region.y                   / texture.height)).should.be(true);
                geom.vertices[1].texCoord.equals(new Vector((tile.region.x + tile.region.w) / texture.width, tile.region.y                   / texture.height)).should.be(true);
                geom.vertices[2].texCoord.equals(new Vector((tile.region.x + tile.region.w) / texture.width, (tile.region.y + tile.region.h) / texture.height)).should.be(true);

                geom.vertices[3].texCoord.equals(new Vector(tile.region.x                   / texture.width, (tile.region.y + tile.region.h) / texture.height)).should.be(true);
                geom.vertices[4].texCoord.equals(new Vector(tile.region.x                   / texture.width, tile.region.y                   / texture.height)).should.be(true);
                geom.vertices[5].texCoord.equals(new Vector((tile.region.x + tile.region.w) / texture.width, (tile.region.y + tile.region.h) / texture.height)).should.be(true);
            });

            it('Can add a quad using four floats as the size and flip the UV on the x axis', {
                var name = 'cavesofgallet';
                var tile = atlas.findRegion(name);
                var size = new Rectangle(32, 48, 62, 96);

                geom.add_xywh(tile, size.x, size.y, size.w, size.h, geom.color, true);

                // Check position
                geom.vertices[0].position.x.should.be(size.x);
                geom.vertices[0].position.y.should.be(size.y);
                geom.vertices[1].position.x.should.be(size.x + size.w);
                geom.vertices[1].position.y.should.be(size.y);
                geom.vertices[2].position.x.should.be(size.x + size.w);
                geom.vertices[2].position.y.should.be(size.y + size.h);

                geom.vertices[3].position.x.should.be(size.x);
                geom.vertices[3].position.y.should.be(size.y + size.h);
                geom.vertices[4].position.x.should.be(size.x);
                geom.vertices[4].position.y.should.be(size.y);
                geom.vertices[5].position.x.should.be(size.x + size.w);
                geom.vertices[5].position.y.should.be(size.y + size.h);

                // Check colour
                geom.vertices[0].color.equals(geom.color).should.be(true);
                geom.vertices[1].color.equals(geom.color).should.be(true);
                geom.vertices[2].color.equals(geom.color).should.be(true);

                geom.vertices[3].color.equals(geom.color).should.be(true);
                geom.vertices[4].color.equals(geom.color).should.be(true);
                geom.vertices[5].color.equals(geom.color).should.be(true);

                // Check UV
                geom.vertices[0].texCoord.equals(new Vector((tile.region.x + tile.region.w) / texture.width,  tile.region.y                  / texture.height)).should.be(true);
                geom.vertices[1].texCoord.equals(new Vector( tile.region.x                  / texture.width,  tile.region.y                  / texture.height)).should.be(true);
                geom.vertices[2].texCoord.equals(new Vector( tile.region.x                  / texture.width, (tile.region.y + tile.region.h) / texture.height)).should.be(true);

                geom.vertices[3].texCoord.equals(new Vector((tile.region.x + tile.region.w) / texture.width, (tile.region.y + tile.region.h) / texture.height)).should.be(true);
                geom.vertices[4].texCoord.equals(new Vector((tile.region.x + tile.region.w) / texture.width,  tile.region.y                  / texture.height)).should.be(true);
                geom.vertices[5].texCoord.equals(new Vector( tile.region.x                  / texture.width, (tile.region.y + tile.region.h) / texture.height)).should.be(true);
            });

            it('Can add a quad using four floats as the size and flip the UV on the y axis', {
                var name = 'cavesofgallet';
                var tile = atlas.findRegion(name);
                var size = new Rectangle(32, 48, 62, 96);

                geom.add_xywh(tile, size.x, size.y, size.w, size.h, geom.color, false, true);

                // Check position
                geom.vertices[0].position.x.should.be(size.x);
                geom.vertices[0].position.y.should.be(size.y);
                geom.vertices[1].position.x.should.be(size.x + size.w);
                geom.vertices[1].position.y.should.be(size.y);
                geom.vertices[2].position.x.should.be(size.x + size.w);
                geom.vertices[2].position.y.should.be(size.y + size.h);

                geom.vertices[3].position.x.should.be(size.x);
                geom.vertices[3].position.y.should.be(size.y + size.h);
                geom.vertices[4].position.x.should.be(size.x);
                geom.vertices[4].position.y.should.be(size.y);
                geom.vertices[5].position.x.should.be(size.x + size.w);
                geom.vertices[5].position.y.should.be(size.y + size.h);

                // Check colour
                geom.vertices[0].color.equals(geom.color).should.be(true);
                geom.vertices[1].color.equals(geom.color).should.be(true);
                geom.vertices[2].color.equals(geom.color).should.be(true);

                geom.vertices[3].color.equals(geom.color).should.be(true);
                geom.vertices[4].color.equals(geom.color).should.be(true);
                geom.vertices[5].color.equals(geom.color).should.be(true);

                // Check UV
                geom.vertices[0].texCoord.equals(new Vector( tile.region.x                  / texture.width, (tile.region.y + tile.region.h) / texture.height)).should.be(true);
                geom.vertices[1].texCoord.equals(new Vector((tile.region.x + tile.region.w) / texture.width, (tile.region.y + tile.region.h) / texture.height)).should.be(true);
                geom.vertices[2].texCoord.equals(new Vector((tile.region.x + tile.region.w) / texture.width,  tile.region.y                  / texture.height)).should.be(true);

                geom.vertices[3].texCoord.equals(new Vector( tile.region.x                  / texture.width,  tile.region.y                  / texture.height)).should.be(true);
                geom.vertices[4].texCoord.equals(new Vector( tile.region.x                  / texture.width, (tile.region.y + tile.region.h) / texture.height)).should.be(true);
                geom.vertices[5].texCoord.equals(new Vector((tile.region.x + tile.region.w) / texture.width,  tile.region.y                  / texture.height)).should.be(true);
            });

            it('Can add a quad using four floats as the size and flip the UV on the x and y axis', {
                var name = 'cavesofgallet';
                var tile = atlas.findRegion(name);
                var size = new Rectangle(32, 48, 62, 96);

                geom.add_xywh(tile, size.x, size.y, size.w, size.h, geom.color, true, true);

                // Check position
                geom.vertices[0].position.x.should.be(size.x);
                geom.vertices[0].position.y.should.be(size.y);
                geom.vertices[1].position.x.should.be(size.x + size.w);
                geom.vertices[1].position.y.should.be(size.y);
                geom.vertices[2].position.x.should.be(size.x + size.w);
                geom.vertices[2].position.y.should.be(size.y + size.h);

                geom.vertices[3].position.x.should.be(size.x);
                geom.vertices[3].position.y.should.be(size.y + size.h);
                geom.vertices[4].position.x.should.be(size.x);
                geom.vertices[4].position.y.should.be(size.y);
                geom.vertices[5].position.x.should.be(size.x + size.w);
                geom.vertices[5].position.y.should.be(size.y + size.h);

                // Check colour
                geom.vertices[0].color.equals(geom.color).should.be(true);
                geom.vertices[1].color.equals(geom.color).should.be(true);
                geom.vertices[2].color.equals(geom.color).should.be(true);

                geom.vertices[3].color.equals(geom.color).should.be(true);
                geom.vertices[4].color.equals(geom.color).should.be(true);
                geom.vertices[5].color.equals(geom.color).should.be(true);

                // Check UV
                geom.vertices[0].texCoord.equals(new Vector((tile.region.x + tile.region.w) / texture.width, (tile.region.y + tile.region.h) / texture.height)).should.be(true);
                geom.vertices[1].texCoord.equals(new Vector( tile.region.x                  / texture.width, (tile.region.y + tile.region.h) / texture.height)).should.be(true);
                geom.vertices[2].texCoord.equals(new Vector( tile.region.x                  / texture.width,  tile.region.y                  / texture.height)).should.be(true);

                geom.vertices[3].texCoord.equals(new Vector((tile.region.x + tile.region.w) / texture.width,  tile.region.y                  / texture.height)).should.be(true);
                geom.vertices[4].texCoord.equals(new Vector((tile.region.x + tile.region.w) / texture.width, (tile.region.y + tile.region.h) / texture.height)).should.be(true);
                geom.vertices[5].texCoord.equals(new Vector( tile.region.x                  / texture.width,  tile.region.y                  / texture.height)).should.be(true);
            });

            it('Can add a arbitrarily sized quad using four vertices', {
                var name = 'cavesofgallet';
                var tile = atlas.findRegion(name);
                var p1   = new Vector(32, 32);
                var p2   = new Vector(62, 32);
                var p3   = new Vector(62, 96);
                var p4   = new Vector(32, 48);

                geom.add_quad(tile, p1, p2, p3, p4, geom.color);

                // Check position
                geom.vertices[0].position.x.should.be(p1.x);
                geom.vertices[0].position.y.should.be(p1.y);
                geom.vertices[1].position.x.should.be(p2.x);
                geom.vertices[1].position.y.should.be(p2.y);
                geom.vertices[2].position.x.should.be(p3.x);
                geom.vertices[2].position.y.should.be(p3.y);

                geom.vertices[3].position.x.should.be(p4.x);
                geom.vertices[3].position.y.should.be(p4.y);
                geom.vertices[4].position.x.should.be(p1.x);
                geom.vertices[4].position.y.should.be(p1.y);
                geom.vertices[5].position.x.should.be(p3.x);
                geom.vertices[5].position.y.should.be(p3.y);

                // Check colour
                geom.vertices[0].color.equals(geom.color).should.be(true);
                geom.vertices[1].color.equals(geom.color).should.be(true);
                geom.vertices[2].color.equals(geom.color).should.be(true);

                geom.vertices[3].color.equals(geom.color).should.be(true);
                geom.vertices[4].color.equals(geom.color).should.be(true);
                geom.vertices[5].color.equals(geom.color).should.be(true);

                // Check UV
                geom.vertices[0].texCoord.equals(new Vector(tile.region.x                   / texture.width, tile.region.y                   / texture.height)).should.be(true);
                geom.vertices[1].texCoord.equals(new Vector((tile.region.x + tile.region.w) / texture.width, tile.region.y                   / texture.height)).should.be(true);
                geom.vertices[2].texCoord.equals(new Vector((tile.region.x + tile.region.w) / texture.width, (tile.region.y + tile.region.h) / texture.height)).should.be(true);

                geom.vertices[3].texCoord.equals(new Vector(tile.region.x                   / texture.width, (tile.region.y + tile.region.h) / texture.height)).should.be(true);
                geom.vertices[4].texCoord.equals(new Vector(tile.region.x                   / texture.width, tile.region.y                   / texture.height)).should.be(true);
                geom.vertices[5].texCoord.equals(new Vector((tile.region.x + tile.region.w) / texture.width, (tile.region.y + tile.region.h) / texture.height)).should.be(true);
            });

            it('Can add a arbitrarily sized quad using four vertices and flip the UV on the x axis', {
                var name = 'cavesofgallet';
                var tile = atlas.findRegion(name);
                var p1   = new Vector(32, 32);
                var p2   = new Vector(62, 32);
                var p3   = new Vector(62, 96);
                var p4   = new Vector(32, 48);

                geom.add_quad(tile, p1, p2, p3, p4, geom.color, true);

                // Check position
                geom.vertices[0].position.x.should.be(p1.x);
                geom.vertices[0].position.y.should.be(p1.y);
                geom.vertices[1].position.x.should.be(p2.x);
                geom.vertices[1].position.y.should.be(p2.y);
                geom.vertices[2].position.x.should.be(p3.x);
                geom.vertices[2].position.y.should.be(p3.y);

                geom.vertices[3].position.x.should.be(p4.x);
                geom.vertices[3].position.y.should.be(p4.y);
                geom.vertices[4].position.x.should.be(p1.x);
                geom.vertices[4].position.y.should.be(p1.y);
                geom.vertices[5].position.x.should.be(p3.x);
                geom.vertices[5].position.y.should.be(p3.y);

                // Check colour
                geom.vertices[0].color.equals(geom.color).should.be(true);
                geom.vertices[1].color.equals(geom.color).should.be(true);
                geom.vertices[2].color.equals(geom.color).should.be(true);

                geom.vertices[3].color.equals(geom.color).should.be(true);
                geom.vertices[4].color.equals(geom.color).should.be(true);
                geom.vertices[5].color.equals(geom.color).should.be(true);

                geom.vertices[0].texCoord.equals(new Vector((tile.region.x + tile.region.w) / texture.width,  tile.region.y                  / texture.height)).should.be(true);
                geom.vertices[1].texCoord.equals(new Vector( tile.region.x                  / texture.width,  tile.region.y                  / texture.height)).should.be(true);
                geom.vertices[2].texCoord.equals(new Vector( tile.region.x                  / texture.width, (tile.region.y + tile.region.h) / texture.height)).should.be(true);

                geom.vertices[3].texCoord.equals(new Vector((tile.region.x + tile.region.w) / texture.width, (tile.region.y + tile.region.h) / texture.height)).should.be(true);
                geom.vertices[4].texCoord.equals(new Vector((tile.region.x + tile.region.w) / texture.width,  tile.region.y                  / texture.height)).should.be(true);
                geom.vertices[5].texCoord.equals(new Vector( tile.region.x                  / texture.width, (tile.region.y + tile.region.h) / texture.height)).should.be(true);
            });

            it('Can add a arbitrarily sized quad using four vertices and flip the UV on the y axis', {
                var name = 'cavesofgallet';
                var tile = atlas.findRegion(name);
                var p1   = new Vector(32, 32);
                var p2   = new Vector(62, 32);
                var p3   = new Vector(62, 96);
                var p4   = new Vector(32, 48);

                geom.add_quad(tile, p1, p2, p3, p4, geom.color, false, true);

                // Check position
                geom.vertices[0].position.x.should.be(p1.x);
                geom.vertices[0].position.y.should.be(p1.y);
                geom.vertices[1].position.x.should.be(p2.x);
                geom.vertices[1].position.y.should.be(p2.y);
                geom.vertices[2].position.x.should.be(p3.x);
                geom.vertices[2].position.y.should.be(p3.y);

                geom.vertices[3].position.x.should.be(p4.x);
                geom.vertices[3].position.y.should.be(p4.y);
                geom.vertices[4].position.x.should.be(p1.x);
                geom.vertices[4].position.y.should.be(p1.y);
                geom.vertices[5].position.x.should.be(p3.x);
                geom.vertices[5].position.y.should.be(p3.y);

                // Check colour
                geom.vertices[0].color.equals(geom.color).should.be(true);
                geom.vertices[1].color.equals(geom.color).should.be(true);
                geom.vertices[2].color.equals(geom.color).should.be(true);

                geom.vertices[3].color.equals(geom.color).should.be(true);
                geom.vertices[4].color.equals(geom.color).should.be(true);
                geom.vertices[5].color.equals(geom.color).should.be(true);

                geom.vertices[0].texCoord.equals(new Vector( tile.region.x                  / texture.width, (tile.region.y + tile.region.h) / texture.height)).should.be(true);
                geom.vertices[1].texCoord.equals(new Vector((tile.region.x + tile.region.w) / texture.width, (tile.region.y + tile.region.h) / texture.height)).should.be(true);
                geom.vertices[2].texCoord.equals(new Vector((tile.region.x + tile.region.w) / texture.width,  tile.region.y                  / texture.height)).should.be(true);

                geom.vertices[3].texCoord.equals(new Vector( tile.region.x                  / texture.width,  tile.region.y                  / texture.height)).should.be(true);
                geom.vertices[4].texCoord.equals(new Vector( tile.region.x                  / texture.width, (tile.region.y + tile.region.h) / texture.height)).should.be(true);
                geom.vertices[5].texCoord.equals(new Vector((tile.region.x + tile.region.w) / texture.width,  tile.region.y                  / texture.height)).should.be(true);
            });

            it('Can add a arbitrarily sized quad using four vertices and flip the UV on the x and y axis', {
                var name = 'cavesofgallet';
                var tile = atlas.findRegion(name);
                var p1   = new Vector(32, 32);
                var p2   = new Vector(62, 32);
                var p3   = new Vector(62, 96);
                var p4   = new Vector(32, 48);

                geom.add_quad(tile, p1, p2, p3, p4, geom.color, true, true);

                // Check position
                geom.vertices[0].position.x.should.be(p1.x);
                geom.vertices[0].position.y.should.be(p1.y);
                geom.vertices[1].position.x.should.be(p2.x);
                geom.vertices[1].position.y.should.be(p2.y);
                geom.vertices[2].position.x.should.be(p3.x);
                geom.vertices[2].position.y.should.be(p3.y);

                geom.vertices[3].position.x.should.be(p4.x);
                geom.vertices[3].position.y.should.be(p4.y);
                geom.vertices[4].position.x.should.be(p1.x);
                geom.vertices[4].position.y.should.be(p1.y);
                geom.vertices[5].position.x.should.be(p3.x);
                geom.vertices[5].position.y.should.be(p3.y);

                // Check colour
                geom.vertices[0].color.equals(geom.color).should.be(true);
                geom.vertices[1].color.equals(geom.color).should.be(true);
                geom.vertices[2].color.equals(geom.color).should.be(true);

                geom.vertices[3].color.equals(geom.color).should.be(true);
                geom.vertices[4].color.equals(geom.color).should.be(true);
                geom.vertices[5].color.equals(geom.color).should.be(true);

                geom.vertices[0].texCoord.equals(new Vector((tile.region.x + tile.region.w) / texture.width, (tile.region.y + tile.region.h) / texture.height)).should.be(true);
                geom.vertices[1].texCoord.equals(new Vector( tile.region.x                  / texture.width, (tile.region.y + tile.region.h) / texture.height)).should.be(true);
                geom.vertices[2].texCoord.equals(new Vector( tile.region.x                  / texture.width,  tile.region.y                  / texture.height)).should.be(true);

                geom.vertices[3].texCoord.equals(new Vector((tile.region.x + tile.region.w) / texture.width,  tile.region.y                  / texture.height)).should.be(true);
                geom.vertices[4].texCoord.equals(new Vector((tile.region.x + tile.region.w) / texture.width, (tile.region.y + tile.region.h) / texture.height)).should.be(true);
                geom.vertices[5].texCoord.equals(new Vector( tile.region.x                  / texture.width,  tile.region.y                  / texture.height)).should.be(true);
            });

            it('Can remove a specific quad from the geometry', {
                var name = 'cavesofgallet';
                var id1  = geom.add(atlas.findRegion(name), new Rectangle(32, 32, 62, 62), geom.color);
                var id2  = geom.add(atlas.findRegion(name), new Rectangle(96, 32, 48, 48), geom.color);

                geom.vertices.length.should.be(12);
                geom.quadRemove(id1);
                geom.vertices.length.should.be(6);
            });

            it('Can remove all quads from the geometry', {
                var name = 'cavesofgallet';

                geom.add(atlas.findRegion(name), new Rectangle(32, 32, 62, 62), geom.color);
                geom.add(atlas.findRegion(name), new Rectangle(96, 32, 48, 48), geom.color);
                geom.clear();

                geom.vertices.length.should.be(0);
            });

            it('Can set a specific quad invisible', {
                var name = 'cavesofgallet';
                var id1  = geom.add(atlas.findRegion(name), new Rectangle(32, 32, 62, 62), geom.color);
                var id2  = geom.add(atlas.findRegion(name), new Rectangle(96, 32, 48, 48), geom.color);

                geom.quadVisible(id1, false);

                geom.vertices[0].color.a.should.be(0);
                geom.vertices[1].color.a.should.be(0);
                geom.vertices[2].color.a.should.be(0);
                geom.vertices[3].color.a.should.be(0);
                geom.vertices[4].color.a.should.be(0);
                geom.vertices[5].color.a.should.be(0);

                geom.vertices[ 6].color.a.should.not.be(0);
                geom.vertices[ 7].color.a.should.not.be(0);
                geom.vertices[ 8].color.a.should.not.be(0);
                geom.vertices[ 9].color.a.should.not.be(0);
                geom.vertices[10].color.a.should.not.be(0);
                geom.vertices[11].color.a.should.not.be(0);
            });

            it('Can set a specific quad visible', {
                var name = 'cavesofgallet';
                var id1  = geom.add(atlas.findRegion(name), new Rectangle(32, 32, 62, 62), geom.color);
                var id2  = geom.add(atlas.findRegion(name), new Rectangle(96, 32, 48, 48), geom.color);

                geom.quadVisible(id1, false);
                geom.quadVisible(id1, true);

                for (vertex in geom.vertices)
                {
                    vertex.color.a.should.not.be(0);
                }
            });

            it('Can resize a specific quad', {
                var name  = 'cavesofgallet';
                var size1 = new Rectangle(32, 32, 62, 62);
                var size2 = new Rectangle(96, 32, 48, 48);

                var id1 = geom.add(atlas.findRegion(name), size1, geom.color);
                var id2 = geom.add(atlas.findRegion(name), size1, geom.color);

                geom.quadResize(id2, size2);

                // id1
                geom.vertices[0].position.x.should.be(size1.x);
                geom.vertices[0].position.y.should.be(size1.y);
                geom.vertices[1].position.x.should.be(size1.x + size1.w);
                geom.vertices[1].position.y.should.be(size1.y);
                geom.vertices[2].position.x.should.be(size1.x + size1.w);
                geom.vertices[2].position.y.should.be(size1.y + size1.h);

                geom.vertices[3].position.x.should.be(size1.x);
                geom.vertices[3].position.y.should.be(size1.y + size1.h);
                geom.vertices[4].position.x.should.be(size1.x);
                geom.vertices[4].position.y.should.be(size1.y);
                geom.vertices[5].position.x.should.be(size1.x + size1.w);
                geom.vertices[5].position.y.should.be(size1.y + size1.h);

                // id2
                geom.vertices[ 6].position.x.should.be(size2.x);
                geom.vertices[ 6].position.y.should.be(size2.y);
                geom.vertices[ 7].position.x.should.be(size2.x + size2.w);
                geom.vertices[ 7].position.y.should.be(size2.y);
                geom.vertices[ 8].position.x.should.be(size2.x + size2.w);
                geom.vertices[ 8].position.y.should.be(size2.y + size2.h);

                geom.vertices[ 9].position.x.should.be(size2.x);
                geom.vertices[ 9].position.y.should.be(size2.y + size2.h);
                geom.vertices[10].position.x.should.be(size2.x);
                geom.vertices[10].position.y.should.be(size2.y);
                geom.vertices[11].position.x.should.be(size2.x + size2.w);
                geom.vertices[11].position.y.should.be(size2.y + size2.h);
            });

            it('Can set the position of a specific quad', {
                var name  = 'cavesofgallet';
                var size1 = new Rectangle(32, 32, 62, 62);
                var size2 = new Rectangle(96, 32, 62, 62);

                var id1 = geom.add(atlas.findRegion(name), size1, geom.color);
                var id2 = geom.add(atlas.findRegion(name), size1, geom.color);

                geom.quadPosition(id2, new Vector(size2.x, size2.y));

                // id1
                geom.vertices[0].position.x.should.be(size1.x);
                geom.vertices[0].position.y.should.be(size1.y);
                geom.vertices[1].position.x.should.be(size1.x + size1.w);
                geom.vertices[1].position.y.should.be(size1.y);
                geom.vertices[2].position.x.should.be(size1.x + size1.w);
                geom.vertices[2].position.y.should.be(size1.y + size1.h);

                geom.vertices[3].position.x.should.be(size1.x);
                geom.vertices[3].position.y.should.be(size1.y + size1.h);
                geom.vertices[4].position.x.should.be(size1.x);
                geom.vertices[4].position.y.should.be(size1.y);
                geom.vertices[5].position.x.should.be(size1.x + size1.w);
                geom.vertices[5].position.y.should.be(size1.y + size1.h);

                // id2
                geom.vertices[ 6].position.x.should.be(size2.x);
                geom.vertices[ 6].position.y.should.be(size2.y);
                geom.vertices[ 7].position.x.should.be(size2.x + size2.w);
                geom.vertices[ 7].position.y.should.be(size2.y);
                geom.vertices[ 8].position.x.should.be(size2.x + size2.w);
                geom.vertices[ 8].position.y.should.be(size2.y + size2.h);

                geom.vertices[ 9].position.x.should.be(size2.x);
                geom.vertices[ 9].position.y.should.be(size2.y + size2.h);
                geom.vertices[10].position.x.should.be(size2.x);
                geom.vertices[10].position.y.should.be(size2.y);
                geom.vertices[11].position.x.should.be(size2.x + size2.w);
                geom.vertices[11].position.y.should.be(size2.y + size2.h);
            });

            it('Can set the entire colour of a specific quad', {
                var name    = 'cavesofgallet';
                var colour1 = geom.color;
                var colour2 = new Color(1, 0, 0, 1);

                var id1 = geom.add(atlas.findRegion(name), new Rectangle(32, 32, 62, 62), colour1);
                var id2 = geom.add(atlas.findRegion(name), new Rectangle(96, 32, 62, 62), colour1);

                geom.quadColor(id2, colour2);

                // id1
                geom.vertices[0].color.equals(colour1).should.be(true);
                geom.vertices[1].color.equals(colour1).should.be(true);
                geom.vertices[2].color.equals(colour1).should.be(true);

                geom.vertices[3].color.equals(colour1).should.be(true);
                geom.vertices[4].color.equals(colour1).should.be(true);
                geom.vertices[5].color.equals(colour1).should.be(true);

                // id2
                geom.vertices[ 6].color.equals(colour2).should.be(true);
                geom.vertices[ 7].color.equals(colour2).should.be(true);
                geom.vertices[ 8].color.equals(colour2).should.be(true);

                geom.vertices[ 9].color.equals(colour2).should.be(true);
                geom.vertices[10].color.equals(colour2).should.be(true);
                geom.vertices[11].color.equals(colour2).should.be(true);
            });

            it('Can set just the alpha of a specific quad', {
                var name = 'cavesofgallet';
                var id1  = geom.add(atlas.findRegion(name), new Rectangle(32, 32, 62, 62), geom.color);
                var id2  = geom.add(atlas.findRegion(name), new Rectangle(96, 32, 62, 62), geom.color);
                var alp  = 0.75;

                geom.quadAlpha(id2, alp);

                // id1
                geom.vertices[0].color.a.should.be(geom.color.a);
                geom.vertices[1].color.a.should.be(geom.color.a);
                geom.vertices[2].color.a.should.be(geom.color.a);

                geom.vertices[3].color.a.should.be(geom.color.a);
                geom.vertices[4].color.a.should.be(geom.color.a);
                geom.vertices[5].color.a.should.be(geom.color.a);

                // id2
                geom.vertices[ 6].color.a.should.be(alp);
                geom.vertices[ 7].color.a.should.be(alp);
                geom.vertices[ 8].color.a.should.be(alp);

                geom.vertices[ 9].color.a.should.be(alp);
                geom.vertices[10].color.a.should.be(alp);
                geom.vertices[11].color.a.should.be(alp);
            });

            it('Can set the UV of a specific quad to a tile from the atlas', {
                var name = 'cavesofgallet';
                var tile1 = atlas.findRegionID(name, 0);
                var tile2 = atlas.findRegionID(name, 1);

                var id1 = geom.add(tile1, new Rectangle(32, 32, 62, 62), geom.color);
                var id2 = geom.add(tile1, new Rectangle(96, 32, 62, 62), geom.color);

                geom.quadTile(id2, tile2);

                // id1
                geom.vertices[0].texCoord.equals(new Vector( tile1.region.x                   / texture.width,  tile1.region.y                   / texture.height)).should.be(true);
                geom.vertices[1].texCoord.equals(new Vector((tile1.region.x + tile1.region.w) / texture.width,  tile1.region.y                   / texture.height)).should.be(true);
                geom.vertices[2].texCoord.equals(new Vector((tile1.region.x + tile1.region.w) / texture.width, (tile1.region.y + tile1.region.h) / texture.height)).should.be(true);

                geom.vertices[3].texCoord.equals(new Vector( tile1.region.x                   / texture.width, (tile1.region.y + tile1.region.h) / texture.height)).should.be(true);
                geom.vertices[4].texCoord.equals(new Vector( tile1.region.x                   / texture.width,  tile1.region.y                   / texture.height)).should.be(true);
                geom.vertices[5].texCoord.equals(new Vector((tile1.region.x + tile1.region.w) / texture.width, (tile1.region.y + tile1.region.h) / texture.height)).should.be(true);

                // id2
                geom.vertices[ 6].texCoord.equals(new Vector( tile2.region.x                   / texture.width,  tile2.region.y                   / texture.height)).should.be(true);
                geom.vertices[ 7].texCoord.equals(new Vector((tile2.region.x + tile2.region.w) / texture.width,  tile2.region.y                   / texture.height)).should.be(true);
                geom.vertices[ 8].texCoord.equals(new Vector((tile2.region.x + tile2.region.w) / texture.width, (tile2.region.y + tile2.region.h) / texture.height)).should.be(true);

                geom.vertices[ 9].texCoord.equals(new Vector( tile2.region.x                   / texture.width, (tile2.region.y + tile2.region.h) / texture.height)).should.be(true);
                geom.vertices[10].texCoord.equals(new Vector( tile2.region.x                   / texture.width,  tile2.region.y                   / texture.height)).should.be(true);
                geom.vertices[11].texCoord.equals(new Vector((tile2.region.x + tile2.region.w) / texture.width, (tile2.region.y + tile2.region.h) / texture.height)).should.be(true);
            });

            it('Can flip the quads UV on the x axis', {
                var name = 'cavesofgallet';
                var tile1 = atlas.findRegionID(name, 0);
                var tile2 = atlas.findRegionID(name, 1);

                var id1 = geom.add(tile1, new Rectangle(32, 32, 62, 62), geom.color);
                var id2 = geom.add(tile2, new Rectangle(96, 32, 62, 62), geom.color);

                geom.quadFlipX(id2, true);

                // id1
                geom.vertices[0].texCoord.equals(new Vector( tile1.region.x                   / texture.width,  tile1.region.y                   / texture.height)).should.be(true);
                geom.vertices[1].texCoord.equals(new Vector((tile1.region.x + tile1.region.w) / texture.width,  tile1.region.y                   / texture.height)).should.be(true);
                geom.vertices[2].texCoord.equals(new Vector((tile1.region.x + tile1.region.w) / texture.width, (tile1.region.y + tile1.region.h) / texture.height)).should.be(true);

                geom.vertices[3].texCoord.equals(new Vector( tile1.region.x                   / texture.width, (tile1.region.y + tile1.region.h) / texture.height)).should.be(true);
                geom.vertices[4].texCoord.equals(new Vector( tile1.region.x                   / texture.width,  tile1.region.y                   / texture.height)).should.be(true);
                geom.vertices[5].texCoord.equals(new Vector((tile1.region.x + tile1.region.w) / texture.width, (tile1.region.y + tile1.region.h) / texture.height)).should.be(true);

                // id2
                geom.vertices[ 6].texCoord.equals(new Vector((tile2.region.x + tile2.region.w) / texture.width,  tile2.region.y                   / texture.height)).should.be(true);
                geom.vertices[ 7].texCoord.equals(new Vector( tile2.region.x                   / texture.width,  tile2.region.y                   / texture.height)).should.be(true);
                geom.vertices[ 8].texCoord.equals(new Vector( tile2.region.x                   / texture.width, (tile2.region.y + tile2.region.h) / texture.height)).should.be(true);

                geom.vertices[ 9].texCoord.equals(new Vector((tile2.region.x + tile2.region.w) / texture.width, (tile2.region.y + tile2.region.h) / texture.height)).should.be(true);
                geom.vertices[10].texCoord.equals(new Vector((tile2.region.x + tile2.region.w) / texture.width,  tile2.region.y                   / texture.height)).should.be(true);
                geom.vertices[11].texCoord.equals(new Vector( tile2.region.x                   / texture.width, (tile2.region.y + tile2.region.h) / texture.height)).should.be(true);
            });

            it('Can flip the quads UV on the y axis', {
                var name = 'cavesofgallet';
                var tile1 = atlas.findRegionID(name, 0);
                var tile2 = atlas.findRegionID(name, 1);

                var id1 = geom.add(tile1, new Rectangle(32, 32, 62, 62), geom.color);
                var id2 = geom.add(tile2, new Rectangle(96, 32, 62, 62), geom.color);

                geom.quadFlipY(id2, true);

                // id1
                geom.vertices[0].texCoord.equals(new Vector( tile1.region.x                   / texture.width,  tile1.region.y                   / texture.height)).should.be(true);
                geom.vertices[1].texCoord.equals(new Vector((tile1.region.x + tile1.region.w) / texture.width,  tile1.region.y                   / texture.height)).should.be(true);
                geom.vertices[2].texCoord.equals(new Vector((tile1.region.x + tile1.region.w) / texture.width, (tile1.region.y + tile1.region.h) / texture.height)).should.be(true);

                geom.vertices[3].texCoord.equals(new Vector( tile1.region.x                   / texture.width, (tile1.region.y + tile1.region.h) / texture.height)).should.be(true);
                geom.vertices[4].texCoord.equals(new Vector( tile1.region.x                   / texture.width,  tile1.region.y                   / texture.height)).should.be(true);
                geom.vertices[5].texCoord.equals(new Vector((tile1.region.x + tile1.region.w) / texture.width, (tile1.region.y + tile1.region.h) / texture.height)).should.be(true);

                // id2
                geom.vertices[ 6].texCoord.equals(new Vector( tile2.region.x                   / texture.width, (tile2.region.y + tile2.region.h) / texture.height)).should.be(true);
                geom.vertices[ 7].texCoord.equals(new Vector((tile2.region.x + tile2.region.w) / texture.width, (tile2.region.y + tile2.region.h) / texture.height)).should.be(true);
                geom.vertices[ 8].texCoord.equals(new Vector((tile2.region.x + tile2.region.w) / texture.width,  tile2.region.y                   / texture.height)).should.be(true);

                geom.vertices[ 9].texCoord.equals(new Vector( tile2.region.x                   / texture.width,  tile2.region.y                   / texture.height)).should.be(true);
                geom.vertices[10].texCoord.equals(new Vector( tile2.region.x                   / texture.width, (tile2.region.y + tile2.region.h) / texture.height)).should.be(true);
                geom.vertices[11].texCoord.equals(new Vector((tile2.region.x + tile2.region.w) / texture.width,  tile2.region.y                   / texture.height)).should.be(true);
            });

            it('Can flip the quads UV on both the x and y axis', {
                var name = 'cavesofgallet';
                var tile1 = atlas.findRegionID(name, 0);
                var tile2 = atlas.findRegionID(name, 1);

                var id1 = geom.add(tile1, new Rectangle(32, 32, 62, 62), geom.color);
                var id2 = geom.add(tile2, new Rectangle(96, 32, 62, 62), geom.color);

                geom.quadFlipY(id2, true);
                geom.quadFlipX(id2, true);

                // id1
                geom.vertices[0].texCoord.equals(new Vector( tile1.region.x                   / texture.width,  tile1.region.y                   / texture.height)).should.be(true);
                geom.vertices[1].texCoord.equals(new Vector((tile1.region.x + tile1.region.w) / texture.width,  tile1.region.y                   / texture.height)).should.be(true);
                geom.vertices[2].texCoord.equals(new Vector((tile1.region.x + tile1.region.w) / texture.width, (tile1.region.y + tile1.region.h) / texture.height)).should.be(true);

                geom.vertices[3].texCoord.equals(new Vector( tile1.region.x                   / texture.width, (tile1.region.y + tile1.region.h) / texture.height)).should.be(true);
                geom.vertices[4].texCoord.equals(new Vector( tile1.region.x                   / texture.width,  tile1.region.y                   / texture.height)).should.be(true);
                geom.vertices[5].texCoord.equals(new Vector((tile1.region.x + tile1.region.w) / texture.width, (tile1.region.y + tile1.region.h) / texture.height)).should.be(true);

                // id2
                geom.vertices[ 6].texCoord.equals(new Vector((tile2.region.x + tile2.region.w) / texture.width, (tile2.region.y + tile2.region.h) / texture.height)).should.be(true);
                geom.vertices[ 7].texCoord.equals(new Vector( tile2.region.x                   / texture.width, (tile2.region.y + tile2.region.h) / texture.height)).should.be(true);
                geom.vertices[ 8].texCoord.equals(new Vector( tile2.region.x                   / texture.width,  tile2.region.y                   / texture.height)).should.be(true);

                geom.vertices[ 9].texCoord.equals(new Vector((tile2.region.x + tile2.region.w) / texture.width,  tile2.region.y                   / texture.height)).should.be(true);
                geom.vertices[10].texCoord.equals(new Vector((tile2.region.x + tile2.region.w) / texture.width, (tile2.region.y + tile2.region.h) / texture.height)).should.be(true);
                geom.vertices[11].texCoord.equals(new Vector( tile2.region.x                   / texture.width,  tile2.region.y                   / texture.height)).should.be(true);
            });
        });
    }
}
