package tests.api.maths;

import uk.aidanlee.flurry.api.maths.Quaternion;
import uk.aidanlee.flurry.api.maths.Vector3;
import uk.aidanlee.flurry.api.maths.Matrix;
import buddy.BuddySuite;

using buddy.Should;
using rx.Observable;

class QuaternionTests extends BuddySuite
{
    public function new()
    {
        describe('Quaternion', {
            describe('Constructor', {
                it('Can create a quaternion with the x, y, and z components zero and w one', {
                    var q = new Quaternion();
                    q.x.should.beCloseTo(0);
                    q.y.should.beCloseTo(0);
                    q.z.should.beCloseTo(0);
                    q.w.should.beCloseTo(1);
                });
                it('Can create a quaternion with components equal to the values given', {
                    var q = new Quaternion(1, 2, 3, 4);
                    q.x.should.beCloseTo(1);
                    q.y.should.beCloseTo(2);
                    q.z.should.beCloseTo(3);
                    q.w.should.beCloseTo(4);
                });
            });

            describe('Properties', {
                it('Can update the x component', {
                    var q = new Quaternion();
                    q.x = 42;

                    q.x.should.beCloseTo(42);
                    q.y.should.beCloseTo(0);
                    q.z.should.beCloseTo(0);
                    q.w.should.beCloseTo(1);
                });
                it('Can update the y component', {
                    var q = new Quaternion();
                    q.y = 42;

                    q.x.should.beCloseTo(0);
                    q.y.should.beCloseTo(42);
                    q.z.should.beCloseTo(0);
                    q.w.should.beCloseTo(1);
                });
                it('Can update the z component', {
                    var q = new Quaternion();
                    q.z = 42;

                    q.x.should.beCloseTo(0);
                    q.y.should.beCloseTo(0);
                    q.z.should.beCloseTo(42);
                    q.w.should.beCloseTo(1);
                });
                it('Can update the w component', {
                    var q = new Quaternion();
                    q.z = 42;

                    q.x.should.beCloseTo(0);
                    q.y.should.beCloseTo(0);
                    q.z.should.beCloseTo(42);
                    q.w.should.beCloseTo(1);
                });
                it('Can get the length of the quaternion', {
                    var q = new Quaternion();
                    q.w = 42;

                    q.x.should.beCloseTo(0);
                    q.y.should.beCloseTo(0);
                    q.z.should.beCloseTo(0);
                    q.w.should.beCloseTo(42);
                });
                it('Can get the quaternions length', {
                    var q = new Quaternion(1, 2, 3, 4);
                    q.length.should.beCloseTo(5.477);
                });
                it('Can get the square of the quaternions length', {
                    var q = new Quaternion(1, 2, 3, 4);
                    q.lengthsq.should.beCloseTo(30);
                });
                it('Can get a normalized instance of the quaternion', {
                    var q = new Quaternion(1, 2, 3, 4).normalized;

                    q.x.should.beCloseTo(0.182);
                    q.y.should.beCloseTo(0.365);
                    q.z.should.beCloseTo(0.547);
                    q.w.should.beCloseTo(0.730);
                });
            });

            describe('General', {
                it('Can set all four of its components', {
                    var q = new Quaternion();
                    q.set_xyzw(1, 2, 3, 4);

                    q.x.should.beCloseTo(1);
                    q.y.should.beCloseTo(2);
                    q.z.should.beCloseTo(3);
                    q.w.should.beCloseTo(4);
                });
                it('Can set the x, y, and z components', {
                    var q = new Quaternion();
                    q.set_xyz(1, 2, 3);

                    q.x.should.beCloseTo(1);
                    q.y.should.beCloseTo(2);
                    q.z.should.beCloseTo(3);
                    q.w.should.beCloseTo(1);
                });
                it('Can get a string representation containing all four components values', {
                    var q = new Quaternion(1, 2, 3, 4);
                    q.toString().should.be(' { x : 1, y : 2, z : 3, w : 4 } ');
                });
                it('Can check equality to other quaternions', {
                    var q1 = new Quaternion(1, 2, 3, 4);
                    var q2 = new Quaternion(1, 2, 3, 4);
                    var q3 = new Quaternion(1, 2, 3, 7);

                    q1.equals(q2).should.be(true);
                    q1.equals(q3).should.be(false);
                });
                it('Can copy another quaternions values into itself', {
                    var q1 = new Quaternion(1, 2, 3, 4);
                    var q2 = new Quaternion();

                    q2.copy(q1);
                    q2.x.should.beCloseTo(1);
                    q2.y.should.beCloseTo(2);
                    q2.z.should.beCloseTo(3);
                    q2.w.should.beCloseTo(4);
                });
                it('Can clone itself to create another instance with the same component values', {
                    var q1 = new Quaternion(1, 2, 3, 4);
                    var q2 = q1.clone();

                    q1.x.should.be(q2.x);
                    q1.y.should.be(q2.y);
                    q1.z.should.be(q2.z);
                    q1.w.should.be(q2.w);
                });
                it('Can return an array containing the four component values', {
                    var a = new Quaternion(1, 2, 3, 4).toArray();
                    a.should.containExactly([ 1, 2, 3, 4 ]);
                });
                it('Can set its component values from an array', {
                    var q = new Quaternion().fromArray([ 1, 2, 3, 4 ]);
                    q.x.should.beCloseTo(1);
                    q.y.should.beCloseTo(2);
                    q.z.should.beCloseTo(3);
                    q.w.should.beCloseTo(4);
                });
            });

            describe('Maths', {
               it('Can normalize the quaternion', {
                    var q = new Quaternion(1, 2, 3, 4).normalize();
                    q.x.should.beCloseTo(0.182);
                    q.y.should.beCloseTo(0.365);
                    q.z.should.beCloseTo(0.547);
                    q.w.should.beCloseTo(0.730);
               });
               it('Can conjugate the quaternion', {
                    var q = new Quaternion(1, 2, 3, 4).conjugate();
                    q.x.should.beCloseTo(-1);
                    q.y.should.beCloseTo(-2);
                    q.z.should.beCloseTo(-3);
                    q.w.should.beCloseTo( 4);
               });
               it('Can invert the quaternion', {
                    var q = new Quaternion(1, 2, 3, 4).inverse();
                    q.x.should.beCloseTo(-0.182);
                    q.y.should.beCloseTo(-0.365);
                    q.z.should.beCloseTo(-0.547);
                    q.w.should.beCloseTo( 0.730);
               });
               it('Can set the quaternion to the dot product between it and another quaternion', {
                    var q1 = new Quaternion(1, 2, 3, 4);
                    var q2 = new Quaternion(5, 6, 7, 8);

                    q1.dot(q2);
                    q1.x.should.beCloseTo(1);
                    q1.y.should.beCloseTo(2);
                    q1.z.should.beCloseTo(3);
                    q1.w.should.beCloseTo(4);
               });
            });

            describe('Operations', {
                it('Can add a scalar value to all component values', {
                    var q = new Quaternion(1, 2, 3, 4).addScalar(3);
                    q.x.should.beCloseTo(4);
                    q.y.should.beCloseTo(5);
                    q.z.should.beCloseTo(6);
                    q.w.should.beCloseTo(7);
                });
                it('Can add another quaternion to itself', {
                    var q1 = new Quaternion(1, 2, 3, 4);
                    var q2 = new Quaternion(2, 3, 4, 5);

                    q1.add(q2);
                    q1.x.should.beCloseTo(3);
                    q1.y.should.beCloseTo(5);
                    q1.z.should.beCloseTo(7);
                    q1.w.should.beCloseTo(9);
                });
                it('Can multiply all its components with a scalar value', {
                    var q = new Quaternion(1, 2, 3, 4).multiplyScalar(2);
                    q.x.should.beCloseTo(2);
                    q.y.should.beCloseTo(4);
                    q.z.should.beCloseTo(6);
                    q.w.should.beCloseTo(8);
                });
                it('Can multiply itself with another quaternion', {
                    var q1 = new Quaternion(1, 2, 3, 4);
                    var q2 = new Quaternion(2, 3, 4, 5);

                    q1.multiply(q2);
                    q1.x.should.beCloseTo(12);
                    q1.y.should.beCloseTo(24);
                    q1.z.should.beCloseTo(30);
                    q1.w.should.beCloseTo( 0);
                });
            });

            describe('Transformations', {
                it('Can set its components from a vector containing an euler angle', {
                    var q = new Quaternion().setFromEuler(new Vector3(0.25, 1.5, 0.75));
                    q.x.should.beCloseTo(0.332);
                    q.y.should.beCloseTo(0.595);
                    q.z.should.beCloseTo(0.344);
                    q.w.should.beCloseTo(0.644);
                });
                it('Can set its components from an axis array and an angle value', {
                    var q = new Quaternion().setFromAxisAngle(new Vector3(1, 0, 1), 0.75);
                    q.x.should.beCloseTo(0.366);
                    q.y.should.beCloseTo(0);
                    q.z.should.beCloseTo(0.366);
                    q.w.should.beCloseTo(0.930);
                });
                it('Can set its components from a rotation matrix', {
                    var q = new Quaternion().setFromRotationMatrix(new Matrix().makeRotationY(0.75));
                    q.x.should.beCloseTo(0);
                    q.y.should.beCloseTo(0.366);
                    q.z.should.beCloseTo(0);
                    q.w.should.beCloseTo(0.930);
                });
            });

            describe('Observing change', {
                var count = 0;
                var quat  = new Quaternion();

                it('allows subscribing to the quaternion', {
                    quat.subscribeFunction(_ -> count++);
                });

                it('will tick a unit value when the quaternion changes', {
                    quat.addScalar(3);
                    count.should.beGreaterThan(0);
                });

                it('will only tick one value when multiple components are changed', {
                    count.should.be(1);
                });
            });
        });
    }
}
