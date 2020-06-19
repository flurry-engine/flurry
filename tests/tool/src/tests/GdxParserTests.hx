package tests;

import haxe.Resource;
import sys.io.abstractions.mock.MockFileData;
import sys.io.abstractions.mock.MockFileSystem;
import parcel.GdxParser;
import buddy.BuddySuite;

using buddy.Should;

class GdxParserTests extends BuddySuite
{
    public function new()
    {
        describe('Parsing libgdx atlas files', {
            it('can parse single section atlases', {
                final fs    = new MockFileSystem([ 'file.atlas' => MockFileData.fromText(Resource.getString('single_section_atlas')) ], []);
                final atlas = GdxParser.parse('file.atlas', fs);

                atlas.length.should.be(1);
                atlas[0].image.file.should.be('image');
                atlas[0].image.ext.should.be('png');
                atlas[0].width.should.be(512);
                atlas[0].height.should.be(256);

                atlas[0].sections.length.should.be(1);
                atlas[0].sections[0].name.should.be('section_1');
                atlas[0].sections[0].x.should.be(4);
                atlas[0].sections[0].y.should.be(128);
                atlas[0].sections[0].width.should.be(64);
                atlas[0].sections[0].height.should.be(96);
            });
            it('can parse multi section atlases', {
                final fs    = new MockFileSystem([ 'file.atlas' => MockFileData.fromText(Resource.getString('multi_section_atlas')) ], []);
                final atlas = GdxParser.parse('file.atlas', fs);

                atlas.length.should.be(1);
                atlas[0].image.file.should.be('image');
                atlas[0].image.ext.should.be('png');
                atlas[0].width.should.be(512);
                atlas[0].height.should.be(256);

                atlas[0].sections.length.should.be(2);
                atlas[0].sections[0].name.should.be('section_1');
                atlas[0].sections[0].x.should.be(4);
                atlas[0].sections[0].y.should.be(128);
                atlas[0].sections[0].width.should.be(64);
                atlas[0].sections[0].height.should.be(96);
                atlas[0].sections[1].name.should.be('section_2');
                atlas[0].sections[1].x.should.be(16);
                atlas[0].sections[1].y.should.be(0);
                atlas[0].sections[1].width.should.be(48);
                atlas[0].sections[1].height.should.be(32);
            });
            it('can parse multi page atlases', {
                final fs    = new MockFileSystem([ 'file.atlas' => MockFileData.fromText(Resource.getString('multi_page_atlas')) ], []);
                final atlas = GdxParser.parse('file.atlas', fs);

                atlas.length.should.be(2);
                atlas[0].image.file.should.be('image');
                atlas[0].image.ext.should.be('png');
                atlas[0].width.should.be(512);
                atlas[0].height.should.be(256);
                atlas[1].image.file.should.be('image2');
                atlas[1].image.ext.should.be('png');
                atlas[1].width.should.be(512);
                atlas[1].height.should.be(256);

                atlas[0].sections.length.should.be(2);
                atlas[0].sections[0].name.should.be('section_1');
                atlas[0].sections[0].x.should.be(4);
                atlas[0].sections[0].y.should.be(128);
                atlas[0].sections[0].width.should.be(64);
                atlas[0].sections[0].height.should.be(96);
                atlas[0].sections[1].name.should.be('section_2');
                atlas[0].sections[1].x.should.be(16);
                atlas[0].sections[1].y.should.be(0);
                atlas[0].sections[1].width.should.be(48);
                atlas[0].sections[1].height.should.be(32);
                atlas[1].sections.length.should.be(2);
                atlas[1].sections[0].name.should.be('section_3');
                atlas[1].sections[0].x.should.be(48);
                atlas[1].sections[0].y.should.be(95);
                atlas[1].sections[0].width.should.be(184);
                atlas[1].sections[0].height.should.be(35);
                atlas[1].sections[1].name.should.be('section_4');
                atlas[1].sections[1].x.should.be(42);
                atlas[1].sections[1].y.should.be(16);
                atlas[1].sections[1].width.should.be(45);
                atlas[1].sections[1].height.should.be(192);
            });
        });
    }
}