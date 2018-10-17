package tests.api.maths;

import buddy.BuddySuite;
import uk.aidanlee.flurry.api.maths.Vector;
import uk.aidanlee.flurry.api.maths.Maths;

using buddy.Should;

class VectorTests extends BuddySuite
{
    public function new()
    {
        describe('Vector', {

            describe('Constructor', {
                it('Can create a vector with all components zero', {
                    var v = new Vector();
                    v.x.should.be(0);
                    v.y.should.be(0);
                    v.z.should.be(0);
                    v.w.should.be(0);
                });

                it('Can create a vector with the components equal to the values given', {
                    var x = 12;
                    var y = 42.58;
                    var z = -32;
                    var w = 19;

                    var v = new Vector(x, y, z, w);
                    v.x.should.be(x);
                    v.y.should.be(y);
                    v.z.should.be(z);
                    v.w.should.be(w);
                });
            });

            describe('Properties', {
                it('Can get the length of the vector', {
                    var v = new Vector(3.2, 4, -7);
                    v.length.should.be(Maths.sqrt(v.x * v.x + v.y * v.y + v.z * v.z));
                });

                it('Can get the square of the vectors length', {
                    var v = new Vector(3.2, 4, -7);
                    v.lengthsq.should.be(v.x * v.x + v.y * v.y + v.z + v.z);
                });

                it('Can get the 2D angle this vector represents', {
                    var v = new Vector(3.2, 4, -7);
                    v.angle2D.should.be(Maths.atan2(v.y, v.x));
                });

                it('Can get a normalized instance of this vector', {
                    var v = new Vector(3.2, 4, -7);
                    var n = v.normalized;

                    n.x.should.be(v.x / v.length);
                    n.y.should.be(v.y / v.length);
                    n.z.should.be(v.z / v.length);
                });

                it('Can get an inverted instance of this vector', {
                    var v = new Vector(3.2, 4, -7);
                    var i = v.inverted;

                    i.x.should.be(-v.x);
                    i.y.should.be(-v.y);
                    i.z.should.be(-v.z);
                });
            });

            describe('General', {
                it('Can set all four component values', {
                    var x = 12;
                    var y = 42.58;
                    var z = -32;
                    var w = 19;

                    var v = new Vector();
                    v.set(x, y, z, w);

                    v.x.should.be(x);
                    v.y.should.be(y);
                    v.z.should.be(z);
                    v.w.should.be(w);
                });

                it('Can only set the x, y, and z components', {
                    var x = 12;
                    var y = 42.58;
                    var z = -32;

                    var v = new Vector();
                    v.set_xyz(x, y, z);
                    
                    v.x.should.be(x);
                    v.y.should.be(y);
                    v.z.should.be(z);
                    v.w.should.be(0);
                });

                it('Can only set the x and y components', {
                    var x = 12;
                    var y = 42.58;

                    var v = new Vector();
                    v.set_xy(x, y);
                    
                    v.x.should.be(x);
                    v.y.should.be(y);
                    v.z.should.be(0);
                    v.w.should.be(0);
                });

                it('Can copy all component values from another vector into itself', {
                    var v1 = new Vector(12, 42.58, -32, 19);
                    var v2 = new Vector();

                    v2.copyFrom(v1);
                    v2.x.should.be(v1.x);
                    v2.y.should.be(v1.y);
                    v2.z.should.be(v1.z);
                    v2.w.should.be(v1.w);
                });

                it('Can create a string representation of the vector with all four components', {
                    var v = new Vector(12, 42.58, -32, 19);
                    v.toString().should.be(' { x : ${v.x}, y : ${v.y}, z : ${v.z}, w : ${v.w} } ');
                });

                it('Can check if another vector contains the same component values', {
                    var v1 = new Vector(12, 42.58, -32, 19);
                    var v2 = new Vector(12, 42.58, -32, 19);
                    var v3 = new Vector(12, 42.587, -32, 19);

                    v1.equals(v2).should.be(true);
                    v1.equals(v3).should.not.be(true);
                });

                it('Can create a clone of itself which is equal to the original', {
                    var v1 = new Vector(12, 42.58, -32, 19);
                    var v2 = v1.clone();

                    v1.equals(v2).should.be(true);
                });
            });

            describe('Maths', {
                it('Can calculate the dot product between it and another vector', {
                    var v1 = new Vector(1, 2, 5);
                    var v2 = new Vector(2, 4, 7);

                    v1.dot(v2).should.be(45);
                });

                it('Can store the cross product between two other vectors', {
                    var v1 = new Vector(1, 2, 5);
                    var v2 = new Vector(2, 4, 7);

                    var results = new Vector().cross(v1, v2);
                    results.x.should.be(-6);
                    results.y.should.be( 3);
                    results.z.should.be( 0);
                });

                it('Can invert its x, y, and z components', {
                    var v = new Vector(3, 7.24, -15).invert();
                    v.x.should.be(-3);
                    v.y.should.be(-7.24);
                    v.z.should.be( 15);
                });

                it('Can normalize its components', {
                    var v1 = new Vector(3, 7.24, -15).normalize();
                    var v2 = new Vector(3, 7.24, -15);

                    v1.x.should.be(v2.x / v2.length);
                    v1.y.should.be(v2.y / v2.length);
                    v1.z.should.be(v2.z / v2.length);
                });
            });

            describe('Operations', {
                it('Can add another vector instance', {
                    var v1 = new Vector(1, 4.5, -12);
                    var v2 = new Vector(1, 4.5, -12);
                    var v3 = new Vector(4, -2 , 8);

                    v1.add(v3);
                    v1.x.should.be(v2.x + v3.x);
                    v1.y.should.be(v2.y + v3.y);
                    v1.z.should.be(v2.z + v3.z);
                });

                it('Can add values to vector components', {
                    var x = 23;
                    var y = -2;
                    var z = 0.3;

                    var v1 = new Vector(3, -5, 7.2);
                    var v2 = new Vector(3, -5, 7.2);

                    v1.add_xyz(x, y, z);
                    v1.x.should.be(v2.x + x);
                    v1.y.should.be(v2.y + y);
                    v1.z.should.be(v2.z + z);
                });

                it('Can add subtract vector instance', {
                    var v1 = new Vector(1, 4.5, -12);
                    var v2 = new Vector(1, 4.5, -12);
                    var v3 = new Vector(4, -2 , 8);

                    v1.subtract(v3);
                    v1.x.should.be(v2.x - v3.x);
                    v1.y.should.be(v2.y - v3.y);
                    v1.z.should.be(v2.z - v3.z);
                });

                it('Can add values to vector components', {
                    var x = 23;
                    var y = -2;
                    var z = 0.3;

                    var v1 = new Vector(3, -5, 7.2);
                    var v2 = new Vector(3, -5, 7.2);

                    v1.subtract_xyz(x, y, z);
                    v1.x.should.be(v2.x - x);
                    v1.y.should.be(v2.y - y);
                    v1.z.should.be(v2.z - z);
                });

                it('Can multiply its components by another vector', {
                    var v1 = new Vector(1, 4.5, -12);
                    var v2 = new Vector(1, 4.5, -12);
                    var v3 = new Vector(4, -2 , 8);

                    v1.multiply(v3);
                    v1.x.should.be(v2.x * v3.x);
                    v1.y.should.be(v2.y * v3.y);
                    v1.z.should.be(v2.z * v3.z);
                });

                it('Can multiply its components by separate values', {
                    var x = 23;
                    var y = -2;
                    var z = 0.3;

                    var v1 = new Vector(3, -5, 7.2);
                    var v2 = new Vector(3, -5, 7.2);

                    v1.multiply_xyz(x, y, z);
                    v1.x.should.be(v2.x * x);
                    v1.y.should.be(v2.y * y);
                    v1.z.should.be(v2.z * z);
                });

                it('Can divide its components by another vector', {
                    var v1 = new Vector(1, 4.5, -12);
                    var v2 = new Vector(1, 4.5, -12);
                    var v3 = new Vector(4, -2 , 8);

                    v1.divide(v3);
                    v1.x.should.be(v2.x / v3.x);
                    v1.y.should.be(v2.y / v3.y);
                    v1.z.should.be(v2.z / v3.z);
                });

                it('Can divide its components by separate values', {
                    var x = 23;
                    var y = -2;
                    var z = 0.3;

                    var v1 = new Vector(3, -5, 7.2);
                    var v2 = new Vector(3, -5, 7.2);

                    v1.divide_xyz(x, y, z);
                    v1.x.should.be(v2.x / x);
                    v1.y.should.be(v2.y / y);
                    v1.z.should.be(v2.z / z);
                });

                it('Can add a scalar value to all three components', {
                    var sc = 12.4;
                    var v1 = new Vector(3, -5, 7.2);
                    var v2 = new Vector(3, -5, 7.2);

                    v1.addScalar(sc);
                    v1.x.should.be(v2.x + sc);
                    v1.y.should.be(v2.y + sc);
                    v1.z.should.be(v2.z + sc);
                });

                it('Can subtract a scalar value from all three components', {
                    var sc = 12.4;
                    var v1 = new Vector(3, -5, 7.2);
                    var v2 = new Vector(3, -5, 7.2);

                    v1.subtractScalar(sc);
                    v1.x.should.be(v2.x - sc);
                    v1.y.should.be(v2.y - sc);
                    v1.z.should.be(v2.z - sc);
                });

                it('Can multiply all three components by a scalar value', {
                    var sc = 12.4;
                    var v1 = new Vector(3, -5, 7.2);
                    var v2 = new Vector(3, -5, 7.2);

                    v1.multiplyScalar(sc);
                    v1.x.should.be(v2.x * sc);
                    v1.y.should.be(v2.y * sc);
                    v1.z.should.be(v2.z * sc);
                });

                it('Can divide all three components by a scalar value', {
                    var sc = 12.4;
                    var v1 = new Vector(3, -5, 7.2);
                    var v2 = new Vector(3, -5, 7.2);

                    v1.divideScalar(sc);
                    v1.x.should.be(v2.x / sc);
                    v1.y.should.be(v2.y / sc);
                    v1.z.should.be(v2.z / sc);
                });
            });

            describe('Transformations', {
                it('Can transform itself by a matrix');
                it('Can get the euler angles from a quaternion');
            });

            describe('Static Creators', {
                it('Can add two vectors together and store the result in a new vector', {
                    var v1 = new Vector(1, 4.5, -12);
                    var v2 = new Vector(4, -2 , 8);
                    var rs = Vector.Add(v1, v2);

                    rs.x.should.be(v1.x + v2.x);
                    rs.y.should.be(v1.y + v2.y);
                    rs.z.should.be(v1.z + v2.z);
                    rs.equals(v1).should.be(false);
                    rs.equals(v2).should.be(false);
                });
                it('Can subtract two vectors together and store the result in a new vector', {
                    var v1 = new Vector(1, 4.5, -12);
                    var v2 = new Vector(4, -2 , 8);
                    var rs = Vector.Subtract(v1, v2);

                    rs.x.should.be(v1.x - v2.x);
                    rs.y.should.be(v1.y - v2.y);
                    rs.z.should.be(v1.z - v2.z);
                    rs.equals(v1).should.be(false);
                    rs.equals(v2).should.be(false);
                });
                it('Can multiply two vectors together and store the result in a new vector', {
                    var v1 = new Vector(1, 4.5, -12);
                    var v2 = new Vector(4, -2 , 8);
                    var rs = Vector.Multiply(v1, v2);

                    rs.x.should.be(v1.x * v2.x);
                    rs.y.should.be(v1.y * v2.y);
                    rs.z.should.be(v1.z * v2.z);
                    rs.equals(v1).should.be(false);
                    rs.equals(v2).should.be(false);
                });
                it('Can divide two vectors together and store the result in a new vector', {
                    var v1 = new Vector(1, 4.5, -12);
                    var v2 = new Vector(4, -2 , 8);
                    var rs = Vector.Divide(v1, v2);

                    rs.x.should.be(v1.x / v2.x);
                    rs.y.should.be(v1.y / v2.y);
                    rs.z.should.be(v1.z / v2.z);
                    rs.equals(v1).should.be(false);
                    rs.equals(v2).should.be(false);
                });
                it('Can add a scalar to a vector and store the result in a new vector', {
                    var v = new Vector(1, 4.5, -12);
                    var s = 24.7;
                    var r = Vector.AddScalar(v, s);

                    r.x.should.be(v.x + s);
                    r.y.should.be(v.y + s);
                    r.z.should.be(v.z + s);
                    r.equals(v).should.be(false);
                });
                it('Can subtract a scalar from a vector and store the result in a new vector', {
                    var v = new Vector(1, 4.5, -12);
                    var s = 24.7;
                    var r = Vector.SubtractScalar(v, s);

                    r.x.should.be(v.x - s);
                    r.y.should.be(v.y - s);
                    r.z.should.be(v.z - s);
                    r.equals(v).should.be(false);
                });
                it('Can multiply a vector by a scalar and store the result in a new vector', {
                    var v = new Vector(1, 4.5, -12);
                    var s = 24.7;
                    var r = Vector.MultiplyScalar(v, s);

                    r.x.should.be(v.x * s);
                    r.y.should.be(v.y * s);
                    r.z.should.be(v.z * s);
                    r.equals(v).should.be(false);
                });
                it('Can divide a vector by a scalar and store the result in a new vector', {
                    var v = new Vector(1, 4.5, -12);
                    var s = 24.7;
                    var r = Vector.DivideScalar(v, s);

                    r.x.should.be(v.x / s);
                    r.y.should.be(v.y / s);
                    r.z.should.be(v.z / s);
                    r.equals(v).should.be(false);
                });
                it('Can calculate the cross product of two vectors and store the result in a new vector', {
                    var v1 = new Vector(1, 4.5, -12);
                    var v2 = new Vector(4, -2 , 8);
                    var rs = Vector.Cross(v1, v2);

                    rs.x.should.be(v1.y * v2.z - v1.z * v2.y);
                    rs.y.should.be(v1.z * v2.x - v1.x * v2.z);
                    rs.z.should.be(v1.x * v2.y - v1.y * v2.x);
                    rs.equals(v1).should.be(false);
                    rs.equals(v2).should.be(false);
                });
            });
        });
    }
}
