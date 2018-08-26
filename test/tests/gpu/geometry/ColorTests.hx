package tests.gpu.geometry;

import uk.aidanlee.gpu.geometry.Color;
import buddy.BuddySuite;
import mockatoo.Mockatoo.*;

using buddy.Should;

class ColorTests extends BuddySuite
{
    public function new()
    {
        describe('Color', {
            it('Can create a default white colour when no arguments are passed', {
                var colour = new Color();
                colour.r.should.be(1);
                colour.g.should.be(1);
                colour.b.should.be(1);
                colour.a.should.be(1);
            });

            it('Can create a custom RGBA colour through the constructor', {
                var r = 0.2;
                var g = 0.4;
                var b = 0.6;
                var a = 0.8;

                var colour = new Color(r, g, b, a);
                colour.r.should.be(r);
                colour.g.should.be(g);
                colour.b.should.be(b);
                colour.a.should.be(a);
            });

            it('Can copy its RGBA value from another colour object', {
                var r = 0.2;
                var g = 0.4;
                var b = 0.6;
                var a = 0.8;
                
                var colour1 = new Color();
                var colour2 = new Color(r, g, b, a);

                colour1.copyFrom(colour2);
                colour1.r.should.be(r);
                colour1.g.should.be(g);
                colour1.b.should.be(b);
                colour1.a.should.be(a);
            });

            it('Can check if its RGBA value is equal to another colour objects', {
                var r = 0.2;
                var g = 0.4;
                var b = 0.6;
                var a = 0.8;
                
                var colour1 = new Color();
                var colour2 = new Color(r, g, b, a);
                var colour3 = new Color(r, g, b, a);

                colour1.equals(colour2).should.not.be(true);
                colour2.equals(colour3).should.be(true);
            });

            it('Can create a clone of itself', {
                var r = 0.2;
                var g = 0.4;
                var b = 0.6;
                var a = 0.8;
                
                var colour1 = new Color(r, g, b, a);
                var colour2 = colour1.clone();

                colour1.equals(colour2).should.be(true);
                colour1.r = r / 2;
                colour1.g = g / 2;
                colour1.b = b / 2;
                colour1.a = a / 2;
                colour1.equals(colour2).should.not.be(true);
            });

            it('Can set the RBGA value with a single function', {
                var r = 0.2;
                var g = 0.4;
                var b = 0.6;
                var a = 0.8;
                
                var colour = new Color().fromRGBA(r, g, b, a);
                colour.r.should.be(r);
                colour.g.should.be(g);
                colour.b.should.be(b);
                colour.a.should.be(a);
            });

            it('Can set the RGBA value from a HSL value', {
                var r = 0.25;
                var g = 0.75;
                var b = 0.25;
                var a = 1;
                
                var colour = new Color().fromHSL(0.5, 0.5, 0.5);
                colour.r.should.beCloseTo(r, 2);
                colour.g.should.beCloseTo(g, 2);
                colour.b.should.beCloseTo(b, 2);
                colour.a.should.beCloseTo(a, 2);
            });
        });
    }
}
