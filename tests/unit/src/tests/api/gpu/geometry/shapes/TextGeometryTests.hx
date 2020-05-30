package tests.api.gpu.geometry.shapes;

import uk.aidanlee.flurry.api.resources.Resource.Character;
import uk.aidanlee.flurry.api.resources.Resource.FontResource;
import uk.aidanlee.flurry.api.gpu.geometry.shapes.TextGeometry;
import buddy.BuddySuite;

using buddy.Should;

class TextGeometryTests extends BuddySuite
{
    public function new()
    {
        describe('TextGeometry', {
            it('Can create a text geometry from an initial string and bitmap font data', {
                final string   = 'hello';
                final chars    = [
                    "h".code => new Character(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
                    "e".code => new Character(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
                    "l".code => new Character(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
                    "o".code => new Character(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
                ];
                final font     = new FontResource('', '', chars, 0, 0, 256, 256, 0, 0, 1, 1);
                final geometry = new TextGeometry({ font : font, text : string, size : 48 });

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
                final oldString = 'hello';
                final newString = 'hello!';
                final chars     = [
                    "h".code => new Character(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
                    "e".code => new Character(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
                    "l".code => new Character(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
                    "o".code => new Character(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
                    "!".code => new Character(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
                ];
                final font      = new FontResource('', '', chars, 0, 0, 256, 256, 0, 0, 1, 1);
                final geometry  = new TextGeometry({ font : font, text : oldString, size : 48 });

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
