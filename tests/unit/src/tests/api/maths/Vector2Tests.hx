package tests.api.maths;

import buddy.BuddySuite;
import uk.aidanlee.flurry.api.maths.Vector2;
import uk.aidanlee.flurry.api.maths.Matrix;
import uk.aidanlee.flurry.api.maths.Maths;

using buddy.Should;
using rx.Observable;

class Vector2Tests extends BuddySuite
{
    public function new()
    {
        describe('Vector2', {
            describe('Constructor', {
                it('Can create a vector with all components zero', {
                    var v = new Vector2();
                    v.x.should.beCloseTo(0);
                    v.y.should.beCloseTo(0);
                });

                it('Can create a vector with the components equal to the values given', {
                    var x = 12;
                    var y = 42.58;

                    var v = new Vector2(x, y);
                    v.x.should.beCloseTo(x);
                    v.y.should.beCloseTo(y);
                });
            });

            describe('Properties', {
                it('Can get the length of the vector', {
                    var v = new Vector2(3.2);
                    v.length.should.beCloseTo(Maths.sqrt(v.x * v.x + v.y * v.y));
                });

                it('Can get the square of the vectors length', {
                    var v = new Vector2(3.2, 4);
                    v.lengthsq.should.beCloseTo(v.x * v.x + v.y * v.y);
                });

                it('Can get the 2D angle this vector represents', {
                    var v = new Vector2(3.2, 4);
                    v.angle2D.should.beCloseTo(Maths.atan2(v.y, v.x));
                });

                it('Can get a normalized instance of this vector', {
                    var v = new Vector2(3.2, 4);
                    var n = v.normalized;

                    n.x.should.beCloseTo(v.x / v.length);
                    n.y.should.beCloseTo(v.y / v.length);
                });

                it('Can get an inverted instance of this vector', {
                    var v = new Vector2(3.2, 4);
                    var i = v.inverted;

                    i.x.should.beCloseTo(-v.x);
                    i.y.should.beCloseTo(-v.y);
                });
            });

            describe('General', {
                it('Can set all component values', {
                    var x = 12;
                    var y = 42.58;

                    var v = new Vector2();
                    v.set(x, y);

                    v.x.should.beCloseTo(x);
                    v.y.should.beCloseTo(y);
                });

                it('Can copy all component values from another vector into itself', {
                    var v1 = new Vector2(12, 42.58);
                    var v2 = new Vector2();

                    v2.copyFrom(v1);
                    v2.x.should.be(v1.x);
                    v2.y.should.be(v1.y);
                });

                it('Can create a string representation of the vector with all four components', {
                    var v = new Vector2(12, 42.58);
                    v.toString().should.be(' { x : ${v.x}, y : ${v.y} } ');
                });

                it('Can check if another vector contains the same component values', {
                    var v1 = new Vector2(12, 42.58);
                    var v2 = new Vector2(12, 42.58);
                    var v3 = new Vector2(12, 42.587);

                    v1.equals(v2).should.be(true);
                    v1.equals(v3).should.not.be(true);
                });

                it('Can create a clone of itself which is equal to the original', {
                    var v1 = new Vector2(12, 42.58);
                    var v2 = v1.clone();

                    v1.equals(v2).should.be(true);
                });
            });

            describe('Maths', {
                it('Can invert its x, y, and z components', {
                    var v = new Vector2(3, 7.24).invert();
                    v.x.should.beCloseTo(-3);
                    v.y.should.beCloseTo(-7.24);
                });

                it('Can normalize its components', {
                    var v1 = new Vector2(3, 7.24).normalize();
                    var v2 = new Vector2(3, 7.24);

                    v1.x.should.beCloseTo(v2.x / v2.length);
                    v1.y.should.beCloseTo(v2.y / v2.length);
                });
            });

            describe('Operations', {
                it('Can add another vector instance', {
                    var v1 = new Vector2(1, 4.5);
                    var v2 = new Vector2(1, 4.5);
                    var v3 = new Vector2(4, -2 );

                    v1.add(v3);
                    v1.x.should.beCloseTo(v2.x + v3.x);
                    v1.y.should.beCloseTo(v2.y + v3.y);
                });

                it('Can add values to vector components', {
                    var x = 23;
                    var y = -2;

                    var v1 = new Vector2(3, -5);
                    var v2 = new Vector2(3, -5);

                    v1.add_xy(x, y);
                    v1.x.should.beCloseTo(v2.x + x);
                    v1.y.should.beCloseTo(v2.y + y);
                });

                it('Can add subtract vector instance', {
                    var v1 = new Vector2(1, 4.5);
                    var v2 = new Vector2(1, 4.5);
                    var v3 = new Vector2(4, -2 );

                    v1.subtract(v3);
                    v1.x.should.beCloseTo(v2.x - v3.x);
                    v1.y.should.beCloseTo(v2.y - v3.y);
                });

                it('Can add values to vector components', {
                    var x = 23;
                    var y = -2;
                    var z = 0.3;

                    var v1 = new Vector2(3, -5);
                    var v2 = new Vector2(3, -5);

                    v1.subtract_xy(x, y);
                    v1.x.should.beCloseTo(v2.x - x);
                    v1.y.should.beCloseTo(v2.y - y);
                });

                it('Can multiply its components by another vector', {
                    var v1 = new Vector2(1, 4.5);
                    var v2 = new Vector2(1, 4.5);
                    var v3 = new Vector2(4, -2 );

                    v1.multiply(v3);
                    v1.x.should.beCloseTo(v2.x * v3.x);
                    v1.y.should.beCloseTo(v2.y * v3.y);
                });

                it('Can multiply its components by separate values', {
                    var x = 23;
                    var y = -2;

                    var v1 = new Vector2(3, -5);
                    var v2 = new Vector2(3, -5);

                    v1.multiply_xy(x, y);
                    v1.x.should.beCloseTo(v2.x * x);
                    v1.y.should.beCloseTo(v2.y * y);
                });

                it('Can divide its components by another vector', {
                    var v1 = new Vector2(1, 4.5);
                    var v2 = new Vector2(1, 4.5);
                    var v3 = new Vector2(4, -2 );

                    v1.divide(v3);
                    v1.x.should.beCloseTo(v2.x / v3.x);
                    v1.y.should.beCloseTo(v2.y / v3.y);
                });

                it('Can divide its components by separate values', {
                    var x = 23;
                    var y = -2;
                    var z = 0.3;

                    var v1 = new Vector2(3, -5);
                    var v2 = new Vector2(3, -5);

                    v1.divide_xy(x, y);
                    v1.x.should.beCloseTo(v2.x / x);
                    v1.y.should.beCloseTo(v2.y / y);
                });

                it('Can add a scalar value to all three components', {
                    var sc = 12.4;
                    var v1 = new Vector2(3, -5);
                    var v2 = new Vector2(3, -5);

                    v1.addScalar(sc);
                    v1.x.should.beCloseTo(v2.x + sc);
                    v1.y.should.beCloseTo(v2.y + sc);
                });

                it('Can subtract a scalar value from all three components', {
                    var sc = 12.4;
                    var v1 = new Vector2(3, -5);
                    var v2 = new Vector2(3, -5);

                    v1.subtractScalar(sc);
                    v1.x.should.beCloseTo(v2.x - sc);
                    v1.y.should.beCloseTo(v2.y - sc);
                });

                it('Can multiply all three components by a scalar value', {
                    var sc = 12.4;
                    var v1 = new Vector2(3, -5);
                    var v2 = new Vector2(3, -5);

                    v1.multiplyScalar(sc);
                    v1.x.should.beCloseTo(v2.x * sc);
                    v1.y.should.beCloseTo(v2.y * sc);
                });

                it('Can divide all three components by a scalar value', {
                    var sc = 12.4;
                    var v1 = new Vector2(3, -5);
                    var v2 = new Vector2(3, -5);

                    v1.divideScalar(sc);
                    v1.x.should.beCloseTo(v2.x / sc);
                    v1.y.should.beCloseTo(v2.y / sc);
                });
            });

            describe('Transformations', {
                it('Can transform itself by a matrix', {
                    var v = new Vector2();
                    var m = new Matrix().makeTranslation(32, 48, 0);

                    v.transform(m);
                    v.x.should.beCloseTo(32);
                    v.y.should.beCloseTo(48);
                });
            });

            describe('Overloaded Operators', {
                it('Can add another vector instance', {
                    var v1 = new Vector2(1, 4.5);
                    var v2 = new Vector2(1, 4.5);
                    var v3 = new Vector2(4, -2 );

                    v1 + v3;
                    v1.x.should.beCloseTo(v2.x + v3.x);
                    v1.y.should.beCloseTo(v2.y + v3.y);
                });

                it('Can add subtract vector instance', {
                    var v1 = new Vector2(1, 4.5);
                    var v2 = new Vector2(1, 4.5);
                    var v3 = new Vector2(4, -2 );

                    v1 - v3;
                    v1.x.should.beCloseTo(v2.x - v3.x);
                    v1.y.should.beCloseTo(v2.y - v3.y);
                });

                it('Can multiply its components by another vector', {
                    var v1 = new Vector2(1, 4.5);
                    var v2 = new Vector2(1, 4.5);
                    var v3 = new Vector2(4, -2 );

                    v1 * v3;
                    v1.x.should.beCloseTo(v2.x * v3.x);
                    v1.y.should.beCloseTo(v2.y * v3.y);
                });

                it('Can divide its components by another vector', {
                    var v1 = new Vector2(1, 4.5);
                    var v2 = new Vector2(1, 4.5);
                    var v3 = new Vector2(4, -2 );

                    v1 / v3;
                    v1.x.should.beCloseTo(v2.x / v3.x);
                    v1.y.should.beCloseTo(v2.y / v3.y);
                });

                it('Can add a scalar value to all three components', {
                    var sc = 12.4;
                    var v1 = new Vector2(3, -5);
                    var v2 = new Vector2(3, -5);

                    v1 + sc;
                    v1.x.should.beCloseTo(v2.x + sc);
                    v1.y.should.beCloseTo(v2.y + sc);
                });

                it('Can subtract a scalar value from all three components', {
                    var sc = 12.4;
                    var v1 = new Vector2(3, -5);
                    var v2 = new Vector2(3, -5);

                    v1 - sc;
                    v1.x.should.beCloseTo(v2.x - sc);
                    v1.y.should.beCloseTo(v2.y - sc);
                });

                it('Can multiply all three components by a scalar value', {
                    var sc = 12.4;
                    var v1 = new Vector2(3, -5);
                    var v2 = new Vector2(3, -5);

                    v1 * sc;
                    v1.x.should.beCloseTo(v2.x * sc);
                    v1.y.should.beCloseTo(v2.y * sc);
                });

                it('Can divide all three components by a scalar value', {
                    var sc = 12.4;
                    var v1 = new Vector2(3, -5);
                    var v2 = new Vector2(3, -5);

                    v1 / sc;
                    v1.x.should.beCloseTo(v2.x / sc);
                    v1.y.should.beCloseTo(v2.y / sc);
                });
            });

            describe('Static Creators', {
                it('Can add two vectors together and store the result in a new Vector2', {
                    var v1 = new Vector2(1, 4.5);
                    var v2 = new Vector2(4, -2 );
                    var rs = Vector2.Add(v1, v2);

                    rs.x.should.beCloseTo(v1.x + v2.x);
                    rs.y.should.beCloseTo(v1.y + v2.y);
                    rs.equals(v1).should.be(false);
                    rs.equals(v2).should.be(false);
                });
                it('Can subtract two vectors together and store the result in a new Vector2', {
                    var v1 = new Vector2(1, 4.5);
                    var v2 = new Vector2(4, -2 );
                    var rs = Vector2.Subtract(v1, v2);

                    rs.x.should.beCloseTo(v1.x - v2.x);
                    rs.y.should.beCloseTo(v1.y - v2.y);
                    rs.equals(v1).should.be(false);
                    rs.equals(v2).should.be(false);
                });
                it('Can multiply two vectors together and store the result in a new Vector2', {
                    var v1 = new Vector2(1, 4.5);
                    var v2 = new Vector2(4, -2 );
                    var rs = Vector2.Multiply(v1, v2);

                    rs.x.should.beCloseTo(v1.x * v2.x);
                    rs.y.should.beCloseTo(v1.y * v2.y);
                    rs.equals(v1).should.be(false);
                    rs.equals(v2).should.be(false);
                });
                it('Can divide two vectors together and store the result in a new Vector2', {
                    var v1 = new Vector2(1, 4.5);
                    var v2 = new Vector2(4, -2 );
                    var rs = Vector2.Divide(v1, v2);

                    rs.x.should.beCloseTo(v1.x / v2.x);
                    rs.y.should.beCloseTo(v1.y / v2.y);
                    rs.equals(v1).should.be(false);
                    rs.equals(v2).should.be(false);
                });
                it('Can add a scalar to a vector and store the result in a new Vector2', {
                    var v = new Vector2(1, 4.5);
                    var s = 24.7;
                    var r = Vector2.AddScalar(v, s);

                    r.x.should.beCloseTo(v.x + s);
                    r.y.should.beCloseTo(v.y + s);
                    r.equals(v).should.be(false);
                });
                it('Can subtract a scalar from a vector and store the result in a new Vector2', {
                    var v = new Vector2(1, 4.5);
                    var s = 24.7;
                    var r = Vector2.SubtractScalar(v, s);

                    r.x.should.beCloseTo(v.x - s);
                    r.y.should.beCloseTo(v.y - s);
                    r.equals(v).should.be(false);
                });
                it('Can multiply a vector by a scalar and store the result in a new Vector2', {
                    var v = new Vector2(1, 4.5);
                    var s = 24.7;
                    var r = Vector2.MultiplyScalar(v, s);

                    r.x.should.beCloseTo(v.x * s);
                    r.y.should.beCloseTo(v.y * s);
                    r.equals(v).should.be(false);
                });
                it('Can divide a vector by a scalar and store the result in a new Vector2', {
                    var v = new Vector2(1, 4.5);
                    var s = 24.7;
                    var r = Vector2.DivideScalar(v, s);

                    r.x.should.beCloseTo(v.x / s);
                    r.y.should.beCloseTo(v.y / s);
                    r.equals(v).should.be(false);
                });
            });

            describe('Observing change', {
                var count  = 0;
                var vector = new Vector2();

                it('allows subscribing to the vector2', {
                    vector.subscribeFunction(_ -> count++);
                });

                it('will tick a unit value when the vector2 changes', {
                    vector.set(1, 2);
                    count.should.beGreaterThan(0);
                });

                it('will only tick one value when multiple components are changed', {
                    count.should.be(1);
                });
            });
        });
    }
}