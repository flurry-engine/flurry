package tests.maths;

import buddy.BuddySuite;
import uk.aidanlee.maths.Rectangle;
import uk.aidanlee.maths.Vector;

using buddy.Should;

class RectangleTests extends BuddySuite
{
    public function new()
    {
        describe('Rectangle', {
            describe('General', {
                it('Can set the size of the rectangle', {
                    var x = 2;
                    var y = 3;
                    var w = 14;
                    var h = 8;

                    var r = new Rectangle();
                    r.set(x, y, w, h);

                    r.x.should.be(x);
                    r.y.should.be(y);
                    r.w.should.be(w);
                    r.h.should.be(h);
                });
                it('Can copy the size of another rectangle', {
                    var x = 2;
                    var y = 3;
                    var w = 14;
                    var h = 8;

                    var r1 = new Rectangle(x, y, w, h);
                    var r2 = new Rectangle();

                    r2.copyFrom(r1);

                    r2.x.should.be(x);
                    r2.y.should.be(y);
                    r2.w.should.be(w);
                    r2.h.should.be(h);
                });
                it('Can check if its equal to another rectangle', {
                    var x = 2;
                    var y = 3;
                    var w = 14;
                    var h = 8;

                    var r1 = new Rectangle(x, y, w, h);
                    var r2 = new Rectangle(x, y, w, h);
                    var r3 = new Rectangle();

                    r1.equals(r2).should.be(true);
                    r1.equals(r3).should.not.be(true);
                });
                it('Can clone itself', {
                    var x = 2;
                    var y = 3;
                    var w = 14;
                    var h = 8;

                    var r1 = new Rectangle(x, y, w, h);
                    var r2 = r1.clone();

                    r2.x.should.be(x);
                    r2.y.should.be(y);
                    r2.w.should.be(w);
                    r2.h.should.be(h);
                });
                it('Can produce a string reprentation of the rectangle', {
                    var x = 2;
                    var y = 3;
                    var w = 14;
                    var h = 8;

                    var r = new Rectangle(x, y, w, h);
                    var s = ' { x : $x, y : $y, w : $w, h : $h } ';

                    r.toString().should.be(s);
                });
            });

            describe('Maths', {
                it('Can check if a vector is within the rectangle', {
                    var x = 2;
                    var y = 3;
                    var w = 14;
                    var h = 8;

                    var r = new Rectangle(x, y, w, h);
                    var v1 = new Vector(x + 2, y + 2);
                    var v2 = new Vector(x - 2, y - 2);
                    var v3 = new Vector(x + w + 2, y + h + 2);

                    r.containsPoint(v1).should.be(true);
                    r.containsPoint(v2).should.not.be(true);
                    r.containsPoint(v3).should.not.be(true);
                });
                it('Can check if another rectangle overlaps with it', {
                    var x1 = 2;
                    var y1 = 3;
                    var w1 = 14;
                    var h1 = 8;

                    var x2 = 4;
                    var y2 = 5;
                    var w2 = 16;
                    var h2 = 10;

                    var r1 = new Rectangle(x1, y1, w1, h1);
                    var r2 = new Rectangle(x2, y2, w2, h2);

                    r1.overlaps(r2).should.be(true);
                    r1.contains(r2).should.not.be(true);
                });
                it('Can check if another rectangle is completely contained by it', {
                    var x1 = 2;
                    var y1 = 3;
                    var w1 = 14;
                    var h1 = 8;

                    var x2 = 3;
                    var y2 = 4;
                    var w2 = 8;
                    var h2 = 4;

                    var r1 = new Rectangle(x1, y1, w1, h1);
                    var r2 = new Rectangle(x2, y2, w2, h2);

                    r1.overlaps(r2).should.be(true);
                    r1.contains(r2).should.be(true);
                });
            });

            describe('Emitters', {
                it('Should emit size changed events when setting the individual properties', {
                    var callCount = 0;
                    var onChanged = function(_event : EvRectangle) {
                        callCount++;
                    }

                    var r = new Rectangle();
                    r.events.on(ChangedSize, onChanged);

                    r.x = 1;
                    callCount.should.be(1);

                    r.y = 1;
                    callCount.should.be(2);

                    r.w = 1;
                    callCount.should.be(3);

                    r.h = 1;
                    callCount.should.be(4);
                });

                it('Should emit size changed events when calling resize functions', {
                    var callCount = 0;
                    var onChanged = function(_event : EvRectangle) {
                        callCount++;
                    }

                    var r1 = new Rectangle();
                    var r2 = new Rectangle(1, 1, 1, 1);
                    r1.events.on(ChangedSize, onChanged);

                    r1.set(1, 1, 1, 1);
                    callCount.should.be(1);

                    r1.copyFrom(r2);
                    callCount.should.be(2);
                });
            });
        });
    }
}
