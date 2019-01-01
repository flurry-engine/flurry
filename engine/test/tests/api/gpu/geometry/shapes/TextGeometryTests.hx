package tests.api.gpu.geometry.shapes;

import uk.aidanlee.flurry.api.resources.Resource.ImageResource;
import uk.aidanlee.flurry.api.maths.Vector;
import uk.aidanlee.flurry.api.gpu.geometry.shapes.TextGeometry;
import uk.aidanlee.flurry.api.importers.bmfont.BitmapFontParser;
import buddy.BuddySuite;
import mockatoo.Mockatoo.mock;

using buddy.Should;
using mockatoo.Mockatoo;

class TextGeometryTests extends BuddySuite
{
    public function new()
    {
        describe('TextGeometry', {
            it('Can create a text geometry from an initial string and bitmap font data', {
                var ubuntuFont = haxe.Resource.getString('fntUbuntu');
                var fontData   = BitmapFontParser.parse(ubuntuFont);
                var string     = 'hello world!';
                var texture    = mock(ImageResource);
                texture.width.returns(512);
                texture.height.returns(512);

                var geometry = new TextGeometry({ font : fontData, text : string, position : new Vector(0, 0), textures : [ texture ] });
                geometry.vertices.length.should.be(string.length * 6);
            });

            it('Will re-create the geometry when the bitmap font has changed', {
                var ubuntuFont = haxe.Resource.getString('fntUbuntu');
                var fontData   = BitmapFontParser.parse(ubuntuFont);
                var string     = 'hello world!';
                var texture    = mock(ImageResource);
                texture.width.returns(512);
                texture.height.returns(512);

                var geometry = new TextGeometry({ font : fontData, text : string, position : new Vector(0, 0), textures : [ texture ] });
                geometry.vertices.length.should.be(string.length * 6);
                geometry.font = fontData;
                geometry.vertices.length.should.be(string.length * 6);
            });

            it('Will re-create the geometry when the text has changed', {
                var ubuntuFont = haxe.Resource.getString('fntUbuntu');
                var fontData   = BitmapFontParser.parse(ubuntuFont);
                var oldString  = 'hello world!';
                var newString  = 'hello from flurry!';
                var texture    = mock(ImageResource);
                texture.width.returns(512);
                texture.height.returns(512);

                var geometry = new TextGeometry({ font : fontData, text : oldString, position : new Vector(0, 0), textures : [ texture ] });
                geometry.vertices.length.should.be(oldString.length * 6);
                geometry.text = newString;
                geometry.vertices.length.should.be(newString.length * 6);
            });
        });
    }
}
