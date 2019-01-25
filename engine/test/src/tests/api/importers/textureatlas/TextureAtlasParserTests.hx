package tests.api.importers.textureatlas;

import uk.aidanlee.flurry.api.maths.Vector;
import uk.aidanlee.flurry.api.maths.Rectangle;
import uk.aidanlee.flurry.api.importers.textureatlas.TextureAtlasParser;
import uk.aidanlee.flurry.api.importers.textureatlas.TextureAtlas.TextureAtlasFormat;
import uk.aidanlee.flurry.api.importers.textureatlas.TextureAtlas.TextureAtlasFilter;
import uk.aidanlee.flurry.api.importers.textureatlas.TextureAtlas.TextureAtlasRepeat;
import buddy.BuddySuite;

using buddy.Should;

class TextureAtlasParserTests extends BuddySuite
{
    public function new()
    {
        describe('TextureAtlas Parser', {

            it('Can successfully parse a .atlas file', {
                var atlas = TextureAtlasParser.parse(haxe.Resource.getString('atlas-data'));

                atlas.name.should.be('cavesofgallet_atlas.png');
                atlas.size.x.should.be(256);
                atlas.size.y.should.be(64);
                atlas.format.should.equal(TextureAtlasFormat.RGBA8888);
                atlas.filter[0].should.equal(TextureAtlasFilter.Nearest);
                atlas.filter[1].should.equal(TextureAtlasFilter.Nearest);
                atlas.repeat.should.equal(TextureAtlasRepeat.none);

                atlas.frames.length.should.be(93);
                atlas.frames[0].name.should.be('cavesofgallet');
                atlas.frames[0].rotated.should.be(false);
                atlas.frames[0].region.equals(new Rectangle(2, 52, 8, 8)).should.be(true);
                atlas.frames[0].original.equals(new Vector(8, 8)).should.be(true);
                atlas.frames[0].offset.equals(new Vector(0, 0)).should.be(true);
                atlas.frames[0].index.should.be(29);
            });

            it('Will throw an exception when given an empty string', {
                TextureAtlasParser.parse.bind('').should.throwValue('TextureAtlas Parser : Atlas data string is empty');
            });

            it('Can find the first frame with a specific name', {
                var atlas = TextureAtlasParser.parse(haxe.Resource.getString('atlas-data'));
                var frame = atlas.findRegion('cavesofgallet');
                frame.should.not.be(null);
                frame.index.should.be(atlas.frames[0].index);

                var frame = atlas.findRegion('not_in_atlas');
                frame.should.be(null);
            });

            it('Can find a frame with a specific name and index', {
                var atlas = TextureAtlasParser.parse(haxe.Resource.getString('atlas-data'));
                var frame = atlas.findRegionID('cavesofgallet', 29);
                frame.should.not.be(null);
                frame.index.should.be(29);
                frame.name.should.be('cavesofgallet');
            });

            it('Can find all frame with a specific name', {
                var atlas  = TextureAtlasParser.parse(haxe.Resource.getString('atlas-data'));
                var frames = atlas.findRegions('cavesofgallet');
                frames.length.should.be(93);
            });
        });
    }
}
