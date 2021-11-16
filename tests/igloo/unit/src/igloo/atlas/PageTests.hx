package igloo.atlas;

import buddy.*;

using buddy.Should;

class PageTests extends BuddySuite
{
    public function new()
    {
        describe('packing requests', {
            final page    = new Page(0, 0, 0, 64, 64);
            final request = igloo.processors.RequestType.PackImage(hx.files.Path.of(''));

            it('will throw an exception when trying to pack a request larger than the page', {
                page.pack.bind(request, 128, 128).should.throwType(haxe.Exception);
            });

            final frameWidth  = 32;
            final frameHeight = 48;
            final packed      = page.pack(request, frameWidth, frameHeight);

            it('will return packed resources with the pixel coordinates of the packed rectangle', {
                packed.x.should.be(0);
                packed.y.should.be(0);
                packed.w.should.be(frameWidth);
                packed.h.should.be(frameHeight);
            });

            it('will return packed resources with the uv coordinates of the packed rectangle', {
                packed.u1.should.be(0);
                packed.v1.should.be(0);
                packed.u2.should.be(0 + (frameWidth / page.width));
                packed.v2.should.be(0 + (frameHeight / page.height));
            });

            it('will return packed resources with the id and size of the parent page', {
                packed.pageID.should.be(page.id);
                packed.pageWidth.should.be(page.width);
                packed.pageHeight.should.be(page.height);
            });

            it('will return null if there is not enough space in the page to pack the request', {
                page.pack(request, 48, 48).should.be(null);
            });
        });
    }
}