package tests.api.gpu.geometry.shapes;

import uk.aidanlee.flurry.api.resources.Resource.ImageResource;
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
                final ubuntuFont = haxe.Resource.getString('font-data');
                final fontData   = BitmapFontParser.parse(ubuntuFont);
                final string     = 'hello world!';
                final texture    = mock(ImageResource);
                texture.width.returns(512);
                texture.height.returns(512);

                final geometry = new TextGeometry({ font : fontData, text : string, texture : texture });
                switch geometry.data
                {
                    case Indexed(_vertices, _indices):
                        _vertices.buffer.byteLength.should.be(string.length * 144);
                        _indices.buffer.byteLength.should.be(string.length * 12);
                    case UnIndexed(_):
                        fail('data should be indexed');
                }
            });

            it('Will re-create the geometry when the text has changed', {
                var ubuntuFont = haxe.Resource.getString('font-data');
                var fontData   = BitmapFontParser.parse(ubuntuFont);
                var oldString  = 'hello world!';
                var newString  = 'hello from flurry!';
                var texture    = mock(ImageResource);
                texture.width.returns(512);
                texture.height.returns(512);

                var geometry = new TextGeometry({ font : fontData, text : oldString, texture : texture });
                switch geometry.data
                {
                    case Indexed(_vertices, _indices):
                        _vertices.buffer.byteLength.should.be(oldString.length * 144);
                        _indices.buffer.byteLength.should.be(oldString.length * 12);
                    case UnIndexed(_):
                        fail('data should be indexed');
                }

                geometry.text = newString;
                switch geometry.data
                {
                    case Indexed(_vertices, _indices):
                        _vertices.buffer.byteLength.should.be(newString.length * 144);
                        _indices.buffer.byteLength.should.be(newString.length * 12);
                    case UnIndexed(_):
                        fail('data should be indexed');
                }
            });
        });
    }
}
