package igloo.atlas;

import buddy.*;

using buddy.Should;

class AtlasTests extends BuddySuite
{
    public function new()
    {
        describe('packing requests', {
            final atlas   = new Atlas(0, 0, 64, 64, new igloo.parcels.IDProvider(0));
            final request = igloo.processors.RequestType.PackImage(hx.files.Path.of(''));

            it('will throw an exception when trying to pack a request larger than the atlas', {
                atlas.pack.bind(request, 128, 128).should.throwType(haxe.Exception);
            });

            final frameWidth  = 32;
            final frameHeight = 48;
            final packed      = atlas.pack(request, frameWidth, frameHeight);

            it('will return packed resources with the pixel coordinates of the packed rectangle', {
                packed.x.should.be(0);
                packed.y.should.be(0);
                packed.w.should.be(frameWidth);
                packed.h.should.be(frameHeight);
            });

            it('will return packed resources with the uv coordinates of the packed rectangle', {
                packed.u1.should.be(0);
                packed.v1.should.be(0);
                packed.u2.should.be(0 + (frameWidth / 64));
                packed.v2.should.be(0 + (frameHeight / 64));
            });

            it('will return packed resources with the id and size of the parent page', {
                packed.pageID.should.be(0);
                packed.pageWidth.should.be(64);
                packed.pageHeight.should.be(64);
            });

            it('will create a new page in the atlas if there is not enough space in the current one for the request', {
                final frameWidth  = 48;
                final frameHeight = 48;
                final packed      = atlas.pack(request, frameWidth, frameHeight);

                packed.pageID.should.be(1);
                packed.x.should.be(0);
                packed.y.should.be(0);
                packed.w.should.be(frameWidth);
                packed.h.should.be(frameHeight);
            });
        });
    }
}