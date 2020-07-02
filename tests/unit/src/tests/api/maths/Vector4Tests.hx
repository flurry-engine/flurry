package tests.api.maths;

import buddy.BuddySuite;
import uk.aidanlee.flurry.api.maths.Vector4;
import uk.aidanlee.flurry.api.maths.Matrix;
import uk.aidanlee.flurry.api.maths.Quaternion;
import uk.aidanlee.flurry.api.maths.Maths;

using buddy.Should;
using rx.Observable;

class Vector4Tests extends BuddySuite
{
    public function new()
    {
        describe('Vector4', {
            describe('Constructor', {
                it('Can create a vector with all components zero', {
                    var v = new Vector4();
                    v.x.should.beCloseTo(0);
                    v.y.should.beCloseTo(0);
                    v.z.should.beCloseTo(0);
                    v.w.should.beCloseTo(0);
                });

                it('Can create a vector with the components equal to the values given', {
                    var x = 12;
                    var y = 42.58;
                    var z = -32;
                    var w = 19;

                    var v = new Vector4(x, y, z, w);
                    v.x.should.beCloseTo(x);
                    v.y.should.beCloseTo(y);
                    v.z.should.beCloseTo(z);
                    v.w.should.beCloseTo(w);
                });
            });

            describe('Properties', {
                it('Can get the length of the vector', {
                    var v = new Vector4(3.2, 4, -7);
                    v.length.should.beCloseTo(Maths.sqrt(v.x * v.x + v.y * v.y + v.z * v.z));
                });

                it('Can get the square of the vectors length', {
                    var v = new Vector4(3.2, 4, -7);
                    v.lengthsq.should.beCloseTo(v.x * v.x + v.y * v.y + v.z + v.z);
                });

                it('Can get the 2D angle this vector represents', {
                    var v = new Vector4(3.2, 4, -7);
                    v.angle2D.should.beCloseTo(Maths.atan2(v.y, v.x));
                });

                it('Can get a normalized instance of this vector', {
                    var v = new Vector4(3.2, 4, -7);
                    var n = v.normalized;

                    n.x.should.beCloseTo(v.x / v.length);
                    n.y.should.beCloseTo(v.y / v.length);
                    n.z.should.beCloseTo(v.z / v.length);
                });

                it('Can get an inverted instance of this vector', {
                    var v = new Vector4(3.2, 4, -7);
                    var i = v.inverted;

                    i.x.should.beCloseTo(-v.x);
                    i.y.should.beCloseTo(-v.y);
                    i.z.should.beCloseTo(-v.z);
                });
            });

            describe('General', {
                it('Can set all four component values', {
                    var x = 12;
                    var y = 42.58;
                    var z = -32;
                    var w = 19;

                    var v = new Vector4();
                    v.set(x, y, z, w);

                    v.x.should.beCloseTo(x);
                    v.y.should.beCloseTo(y);
                    v.z.should.beCloseTo(z);
                    v.w.should.beCloseTo(w);
                });

                it('Can only set the x, y, and z components', {
                    var x = 12;
                    var y = 42.58;
                    var z = -32;

                    var v = new Vector4();
                    v.set_xyz(x, y, z);
                    
                    v.x.should.beCloseTo(x);
                    v.y.should.beCloseTo(y);
                    v.z.should.beCloseTo(z);
                    v.w.should.beCloseTo(0);
                });

                it('Can only set the x and y components', {
                    var x = 12;
                    var y = 42.58;

                    var v = new Vector4();
                    v.set_xy(x, y);
                    
                    v.x.should.beCloseTo(x);
                    v.y.should.beCloseTo(y);
                    v.z.should.beCloseTo(0);
                    v.w.should.beCloseTo(0);
                });

                it('Can copy all component values from another vector into itself', {
                    var v1 = new Vector4(12, 42.58, -32, 19);
                    var v2 = new Vector4();

                    v2.copyFrom(v1);
                    v2.x.should.be(v1.x);
                    v2.y.should.be(v1.y);
                    v2.z.should.be(v1.z);
                    v2.w.should.be(v1.w);
                });

                it('Can create a string representation of the vector with all four components', {
                    var v = new Vector4(12, 42.58, -32, 19);
                    v.toString().should.be(' { x : ${v.x}, y : ${v.y}, z : ${v.z}, w : ${v.w} } ');
                });

                it('Can check if another vector contains the same component values', {
                    var v1 = new Vector4(12, 42.58, -32, 19);
                    var v2 = new Vector4(12, 42.58, -32, 19);
                    var v3 = new Vector4(12, 42.587, -32, 19);

                    v1.equals(v2).should.be(true);
                    v1.equals(v3).should.not.be(true);
                });

                it('Can create a clone of itself which is equal to the original', {
                    var v1 = new Vector4(12, 42.58, -32, 19);
                    var v2 = v1.clone();

                    v1.equals(v2).should.be(true);
                });
            });

            describe('Maths', {
                it('Can calculate the dot product between it and another vector', {
                    var v1 = new Vector4(1, 2, 5);
                    var v2 = new Vector4(2, 4, 7);

                    v1.dot(v2).should.beCloseTo(45);
                });

                it('Can store the cross product between two other vectors', {
                    var v1 = new Vector4(1, 2, 5);
                    var v2 = new Vector4(2, 4, 7);

                    var results = new Vector4().cross(v1, v2);
                    results.x.should.beCloseTo(-6);
                    results.y.should.beCloseTo( 3);
                    results.z.should.beCloseTo( 0);
                });

                it('Can invert its x, y, and z components', {
                    var v = new Vector4(3, 7.24, -15).invert();
                    v.x.should.beCloseTo(-3);
                    v.y.should.beCloseTo(-7.24);
                    v.z.should.beCloseTo( 15);
                });

                it('Can normalize its components', {
                    var v1 = new Vector4(3, 7.24, -15).normalize();
                    var v2 = new Vector4(3, 7.24, -15);

                    v1.x.should.beCloseTo(v2.x / v2.length);
                    v1.y.should.beCloseTo(v2.y / v2.length);
                    v1.z.should.beCloseTo(v2.z / v2.length);
                });
            });

            describe('Operations', {
                it('Can add another vector instance', {
                    var v1 = new Vector4(1, 4.5, -12);
                    var v2 = new Vector4(1, 4.5, -12);
                    var v3 = new Vector4(4, -2 , 8);

                    v1.add(v3);
                    v1.x.should.beCloseTo(v2.x + v3.x);
                    v1.y.should.beCloseTo(v2.y + v3.y);
                    v1.z.should.beCloseTo(v2.z + v3.z);
                });

                it('Can add values to vector components', {
                    var x = 23;
                    var y = -2;
                    var z = 0.3;

                    var v1 = new Vector4(3, -5, 7.2);
                    var v2 = new Vector4(3, -5, 7.2);

                    v1.add_xyz(x, y, z);
                    v1.x.should.beCloseTo(v2.x + x);
                    v1.y.should.beCloseTo(v2.y + y);
                    v1.z.should.beCloseTo(v2.z + z);
                });

                it('Can add subtract vector instance', {
                    var v1 = new Vector4(1, 4.5, -12);
                    var v2 = new Vector4(1, 4.5, -12);
                    var v3 = new Vector4(4, -2 , 8);

                    v1.subtract(v3);
                    v1.x.should.beCloseTo(v2.x - v3.x);
                    v1.y.should.beCloseTo(v2.y - v3.y);
                    v1.z.should.beCloseTo(v2.z - v3.z);
                });

                it('Can add values to vector components', {
                    var x = 23;
                    var y = -2;
                    var z = 0.3;

                    var v1 = new Vector4(3, -5, 7.2);
                    var v2 = new Vector4(3, -5, 7.2);

                    v1.subtract_xyz(x, y, z);
                    v1.x.should.beCloseTo(v2.x - x);
                    v1.y.should.beCloseTo(v2.y - y);
                    v1.z.should.beCloseTo(v2.z - z);
                });

                it('Can multiply its components by another vector', {
                    var v1 = new Vector4(1, 4.5, -12);
                    var v2 = new Vector4(1, 4.5, -12);
                    var v3 = new Vector4(4, -2 , 8);

                    v1.multiply(v3);
                    v1.x.should.beCloseTo(v2.x * v3.x);
                    v1.y.should.beCloseTo(v2.y * v3.y);
                    v1.z.should.beCloseTo(v2.z * v3.z);
                });

                it('Can multiply its components by separate values', {
                    var x = 23;
                    var y = -2;
                    var z = 0.3;

                    var v1 = new Vector4(3, -5, 7.2);
                    var v2 = new Vector4(3, -5, 7.2);

                    v1.multiply_xyz(x, y, z);
                    v1.x.should.beCloseTo(v2.x * x);
                    v1.y.should.beCloseTo(v2.y * y);
                    v1.z.should.beCloseTo(v2.z * z);
                });

                it('Can divide its components by another vector', {
                    var v1 = new Vector4(1, 4.5, -12);
                    var v2 = new Vector4(1, 4.5, -12);
                    var v3 = new Vector4(4, -2 , 8);

                    v1.divide(v3);
                    v1.x.should.beCloseTo(v2.x / v3.x);
                    v1.y.should.beCloseTo(v2.y / v3.y);
                    v1.z.should.beCloseTo(v2.z / v3.z);
                });

                it('Can divide its components by separate values', {
                    var x = 23;
                    var y = -2;
                    var z = 0.3;

                    var v1 = new Vector4(3, -5, 7.2);
                    var v2 = new Vector4(3, -5, 7.2);

                    v1.divide_xyz(x, y, z);
                    v1.x.should.beCloseTo(v2.x / x);
                    v1.y.should.beCloseTo(v2.y / y);
                    v1.z.should.beCloseTo(v2.z / z);
                });

                it('Can add a scalar value to all three components', {
                    var sc = 12.4;
                    var v1 = new Vector4(3, -5, 7.2);
                    var v2 = new Vector4(3, -5, 7.2);

                    v1.addScalar(sc);
                    v1.x.should.beCloseTo(v2.x + sc);
                    v1.y.should.beCloseTo(v2.y + sc);
                    v1.z.should.beCloseTo(v2.z + sc);
                });

                it('Can subtract a scalar value from all three components', {
                    var sc = 12.4;
                    var v1 = new Vector4(3, -5, 7.2);
                    var v2 = new Vector4(3, -5, 7.2);

                    v1.subtractScalar(sc);
                    v1.x.should.beCloseTo(v2.x - sc);
                    v1.y.should.beCloseTo(v2.y - sc);
                    v1.z.should.beCloseTo(v2.z - sc);
                });

                it('Can multiply all three components by a scalar value', {
                    var sc = 12.4;
                    var v1 = new Vector4(3, -5, 7.2);
                    var v2 = new Vector4(3, -5, 7.2);

                    v1.multiplyScalar(sc);
                    v1.x.should.beCloseTo(v2.x * sc);
                    v1.y.should.beCloseTo(v2.y * sc);
                    v1.z.should.beCloseTo(v2.z * sc);
                });

                it('Can divide all three components by a scalar value', {
                    var sc = 12.4;
                    var v1 = new Vector4(3, -5, 7.2);
                    var v2 = new Vector4(3, -5, 7.2);

                    v1.divideScalar(sc);
                    v1.x.should.beCloseTo(v2.x / sc);
                    v1.y.should.beCloseTo(v2.y / sc);
                    v1.z.should.beCloseTo(v2.z / sc);
                });
            });

            describe('Transformations', {
                it('Can transform itself by a matrix', {
                    var x =  3;
                    var y = -5;
                    var z =  7.2;
                    var m = new Matrix().makeTranslation(7.2, 3, -5);
                    var v = new Vector4(x, y, z).transform(m);

                    v.x.should.beCloseTo(m[0] * x + m[4] * y + m[ 8] * z + m[12]);
                    v.y.should.beCloseTo(m[1] * x + m[5] * y + m[ 9] * z + m[13]);
                    v.z.should.beCloseTo(m[2] * x + m[6] * y + m[10] * z + m[14]);
                });

                it('Can set itself to the euler angle from a quaternion', {
                    var q = new Quaternion().setFromAxisAngle(new Vector4(1, 0, 1), Maths.toRadians(45));
                    var v = new Vector4().setEulerFromQuaternion(q);

                    var sqx = q.x * q.x;
                    var sqy = q.y * q.y;
                    var sqz = q.z * q.z;
                    var sqw = q.w * q.w;
                    v.x.should.beCloseTo(Maths.atan2(2 * (q.x * q.w - q.y * q.z), (sqw - sqx - sqy + sqz)));
                    v.y.should.beCloseTo(Maths.asin(Maths.clamp(2 * (q.x * q.z + q.y * q.w), -1, 1)));
                    v.z.should.beCloseTo(Maths.atan2(2 * (q.z * q.w - q.x * q.y), (sqw + sqx - sqy - sqz)));
                });
            });

            describe('Overloaded Operators', {
                it('Can add another vector instance', {
                    var v1 = new Vector4(1, 4.5, -12);
                    var v2 = new Vector4(1, 4.5, -12);
                    var v3 = new Vector4(4, -2 , 8);

                    v1 + v3;
                    v1.x.should.beCloseTo(v2.x + v3.x);
                    v1.y.should.beCloseTo(v2.y + v3.y);
                    v1.z.should.beCloseTo(v2.z + v3.z);
                });

                it('Can add subtract vector instance', {
                    var v1 = new Vector4(1, 4.5, -12);
                    var v2 = new Vector4(1, 4.5, -12);
                    var v3 = new Vector4(4, -2 , 8);

                    v1 - v3;
                    v1.x.should.beCloseTo(v2.x - v3.x);
                    v1.y.should.beCloseTo(v2.y - v3.y);
                    v1.z.should.beCloseTo(v2.z - v3.z);
                });

                it('Can multiply its components by another vector', {
                    var v1 = new Vector4(1, 4.5, -12);
                    var v2 = new Vector4(1, 4.5, -12);
                    var v3 = new Vector4(4, -2 , 8);

                    v1 * v3;
                    v1.x.should.beCloseTo(v2.x * v3.x);
                    v1.y.should.beCloseTo(v2.y * v3.y);
                    v1.z.should.beCloseTo(v2.z * v3.z);
                });

                it('Can divide its components by another vector', {
                    var v1 = new Vector4(1, 4.5, -12);
                    var v2 = new Vector4(1, 4.5, -12);
                    var v3 = new Vector4(4, -2 , 8);

                    v1 / v3;
                    v1.x.should.beCloseTo(v2.x / v3.x);
                    v1.y.should.beCloseTo(v2.y / v3.y);
                    v1.z.should.beCloseTo(v2.z / v3.z);
                });

                it('Can add a scalar value to all three components', {
                    var sc = 12.4;
                    var v1 = new Vector4(3, -5, 7.2);
                    var v2 = new Vector4(3, -5, 7.2);

                    v1 + sc;
                    v1.x.should.beCloseTo(v2.x + sc);
                    v1.y.should.beCloseTo(v2.y + sc);
                    v1.z.should.beCloseTo(v2.z + sc);
                });

                it('Can subtract a scalar value from all three components', {
                    var sc = 12.4;
                    var v1 = new Vector4(3, -5, 7.2);
                    var v2 = new Vector4(3, -5, 7.2);

                    v1 - sc;
                    v1.x.should.beCloseTo(v2.x - sc);
                    v1.y.should.beCloseTo(v2.y - sc);
                    v1.z.should.beCloseTo(v2.z - sc);
                });

                it('Can multiply all three components by a scalar value', {
                    var sc = 12.4;
                    var v1 = new Vector4(3, -5, 7.2);
                    var v2 = new Vector4(3, -5, 7.2);

                    v1 * sc;
                    v1.x.should.beCloseTo(v2.x * sc);
                    v1.y.should.beCloseTo(v2.y * sc);
                    v1.z.should.beCloseTo(v2.z * sc);
                });

                it('Can divide all three components by a scalar value', {
                    var sc = 12.4;
                    var v1 = new Vector4(3, -5, 7.2);
                    var v2 = new Vector4(3, -5, 7.2);

                    v1 / sc;
                    v1.x.should.beCloseTo(v2.x / sc);
                    v1.y.should.beCloseTo(v2.y / sc);
                    v1.z.should.beCloseTo(v2.z / sc);
                });
            });

            describe('Static Creators', {
                it('Can add two vectors together and store the result in a new Vector4', {
                    var v1 = new Vector4(1, 4.5, -12);
                    var v2 = new Vector4(4, -2 , 8);
                    var rs = Vector4.Add(v1, v2);

                    rs.x.should.beCloseTo(v1.x + v2.x);
                    rs.y.should.beCloseTo(v1.y + v2.y);
                    rs.z.should.beCloseTo(v1.z + v2.z);
                    rs.equals(v1).should.be(false);
                    rs.equals(v2).should.be(false);
                });
                it('Can subtract two vectors together and store the result in a new Vector4', {
                    var v1 = new Vector4(1, 4.5, -12);
                    var v2 = new Vector4(4, -2 , 8);
                    var rs = Vector4.Subtract(v1, v2);

                    rs.x.should.beCloseTo(v1.x - v2.x);
                    rs.y.should.beCloseTo(v1.y - v2.y);
                    rs.z.should.beCloseTo(v1.z - v2.z);
                    rs.equals(v1).should.be(false);
                    rs.equals(v2).should.be(false);
                });
                it('Can multiply two vectors together and store the result in a new Vector4', {
                    var v1 = new Vector4(1, 4.5, -12);
                    var v2 = new Vector4(4, -2 , 8);
                    var rs = Vector4.Multiply(v1, v2);

                    rs.x.should.beCloseTo(v1.x * v2.x);
                    rs.y.should.beCloseTo(v1.y * v2.y);
                    rs.z.should.beCloseTo(v1.z * v2.z);
                    rs.equals(v1).should.be(false);
                    rs.equals(v2).should.be(false);
                });
                it('Can divide two vectors together and store the result in a new Vector4', {
                    var v1 = new Vector4(1, 4.5, -12);
                    var v2 = new Vector4(4, -2 , 8);
                    var rs = Vector4.Divide(v1, v2);

                    rs.x.should.beCloseTo(v1.x / v2.x);
                    rs.y.should.beCloseTo(v1.y / v2.y);
                    rs.z.should.beCloseTo(v1.z / v2.z);
                    rs.equals(v1).should.be(false);
                    rs.equals(v2).should.be(false);
                });
                it('Can add a scalar to a vector and store the result in a new Vector4', {
                    var v = new Vector4(1, 4.5, -12);
                    var s = 24.7;
                    var r = Vector4.AddScalar(v, s);

                    r.x.should.beCloseTo(v.x + s);
                    r.y.should.beCloseTo(v.y + s);
                    r.z.should.beCloseTo(v.z + s);
                    r.equals(v).should.be(false);
                });
                it('Can subtract a scalar from a vector and store the result in a new Vector4', {
                    var v = new Vector4(1, 4.5, -12);
                    var s = 24.7;
                    var r = Vector4.SubtractScalar(v, s);

                    r.x.should.beCloseTo(v.x - s);
                    r.y.should.beCloseTo(v.y - s);
                    r.z.should.beCloseTo(v.z - s);
                    r.equals(v).should.be(false);
                });
                it('Can multiply a vector by a scalar and store the result in a new Vector4', {
                    var v = new Vector4(1, 4.5, -12);
                    var s = 24.7;
                    var r = Vector4.MultiplyScalar(v, s);

                    r.x.should.beCloseTo(v.x * s);
                    r.y.should.beCloseTo(v.y * s);
                    r.z.should.beCloseTo(v.z * s);
                    r.equals(v).should.be(false);
                });
                it('Can divide a vector by a scalar and store the result in a new Vector4', {
                    var v = new Vector4(1, 4.5, -12);
                    var s = 24.7;
                    var r = Vector4.DivideScalar(v, s);

                    r.x.should.beCloseTo(v.x / s);
                    r.y.should.beCloseTo(v.y / s);
                    r.z.should.beCloseTo(v.z / s);
                    r.equals(v).should.be(false);
                });
                it('Can calculate the cross product of two vectors and store the result in a new Vector4', {
                    var v1 = new Vector4(1, 4.5, -12);
                    var v2 = new Vector4(4, -2 , 8);
                    var rs = Vector4.Cross(v1, v2);

                    rs.x.should.beCloseTo(v1.y * v2.z - v1.z * v2.y);
                    rs.y.should.beCloseTo(v1.z * v2.x - v1.x * v2.z);
                    rs.z.should.beCloseTo(v1.x * v2.y - v1.y * v2.x);
                    rs.equals(v1).should.be(false);
                    rs.equals(v2).should.be(false);
                });
            });
            
            describe('Observing change', {
                var count  = 0;
                var vector = new Vector4();

                it('allows subscribing to the vector4', {
                    vector.subscribeFunction(_ -> count++);
                });

                it('will tick a unit value when the vector4 changes', {
                    vector.set(1, 2, 3, 4);
                    count.should.beGreaterThan(0);
                });

                it('will only tick one value when multiple components are changed', {
                    count.should.be(1);
                });
            });
        });
    }
}
