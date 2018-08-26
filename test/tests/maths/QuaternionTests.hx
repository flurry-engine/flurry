package tests.maths;

import buddy.BuddySuite;
import uk.aidanlee.maths.Vector;
import uk.aidanlee.maths.Maths;

using buddy.Should;

class QuaternionTests extends BuddySuite
{
    public function new()
    {
        describe('Quaternion', {
            describe('Constructor', {
                it('Can create a quaternion with the x, y, and z components zero and w one');
                it('Can create a quaternion with components equal to the values given');
            });

            describe('Properties', {
                it('Can update the x component');
                it('Can update the y component');
                it('Can update the z component');
                it('Can update the w component');
                it('Can get the length of the quaternion');
                it('Can get the square of the quaternions length');
                it('Can get a normalized instance of the quaternion');
            });

            describe('General', {
                it('Can set all four of its components');
                it('Can set the x, y, and z components');
                it('Can get a string representation containing all four components values');
                it('Can check equality to other quaternions');
                it('Can copy another quaternions values into itself');
                it('Can clone itself to create another instance with the same component values');
                it('Can return an array containing the four component values');
                it('Can set its component values from an array');
            });

            describe('Maths', {
               it('Can normalize the quaternion');
               it('Can conjugate the quaternion');
               it('Can invert the quaternion');
               it('Can set the quaternion to the dot product between it and another quaternion');
            });

            describe('Operations', {
                it('Can add a scalar value to all component values');
                it('Can add another quaternion to itself');
                it('Can multiply all its components with a scalar value');
                it('Can multiply itself with another quaternion');
            });

            describe('Transformations', {
                it('Can set its components from a vector containing an euler angle');
                it('Can set its components from an axis array and an angle value');
                it('Can set its components from a rotation matrix');
            });
        });
    }
}
