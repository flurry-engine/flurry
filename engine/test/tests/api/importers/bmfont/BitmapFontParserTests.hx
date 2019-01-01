package tests.api.importers.bmfont;

import uk.aidanlee.flurry.api.importers.bmfont.BitmapFontParser;
import buddy.BuddySuite;

using buddy.Should;

class BitmapFontParserTests extends BuddySuite
{
    public function new()
    {
        describe('BMFont Parser', {
            it('Can successfully parse a .fnt file', {
                var ubuntuFont = haxe.Resource.getString('fntUbuntu');
                var fontData   = BitmapFontParser.parse(ubuntuFont);

                fontData.face.should.be('Ubuntu');
                fontData.charCount.should.be(96);
                fontData.kerningCount.should.be(800);
                fontData.pointSize.should.be(32);
                fontData.baseSize.should.be(30);
                fontData.lineHeight.should.be(37);
            });

            it('Will throw an exception when given an empty string', {
                BitmapFontParser.parse.bind('').should.throwValue('BMFont Parser : Font data string is empty');
            });

            it('Will thrown an exception when not given a plain text .fnt file', {
                BitmapFontParser.parse.bind('not info').should.throwValue('BMFont Parser : Invalid font data for parser. Format should be plain text .fnt file');
            });
        });
    }
}
