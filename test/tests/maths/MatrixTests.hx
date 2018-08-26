package tests.maths;

import buddy.BuddySuite;
import uk.aidanlee.maths.Vector;
import uk.aidanlee.maths.Quaternion;
import uk.aidanlee.maths.Maths;

using buddy.Should;

class MatrixTests extends BuddySuite
{
    public function new()
    {
        describe('Matrix', {
            describe('Constructor', {
                it('Can create a default identity matrix');
                it('Can create a custom matrix passing any number of the 16 elements');
            });

            describe('Properties', {
                it('Can access the 16 elements through row getters');
                it('Can set the 16 elements through row setters');
                it('Can directly access element vector');
            });

            describe('General', {
                it('Can set any number of matrix elements');
                it('Can copy the elements from another matrix into its own');
                it('Can create a clone of itself');
                it('Can set its elements from an array');
                it('Can return an array containing all elements');
                it('Can print out a string with all the elements values');
                it('Can invert itself');
            });

            describe('Maths', {
                it('Can calculate the determinant of the matrix');
                it('Can transpose the matrix');
                it('Can scale the matrix');
                it('Can compose a matrix from a position, rotation, and scale');
                it('Can decompose a matrix into a position, rotation, and scale');
            });

            describe('Operations', {
                it('Can multiply itself with another matrix');
                it('Can multiply to matrices together and store the result in itself');
                it('Can multiply itself by a scalar value');
                it('Can get the up vector of this matrix');
                it('Can get the down vector of this matrix');
                it('Can get the left vector of this matrix');
                it('Can get the right vector of this matrix');
                it('Can get the forward vector of this matrix');
                it('Can get the backwards vector of this matrix');
            });

            describe('Transformations', {
                it('Can set its position from a vector');
                it('Can return the position as a vector');
                it('Can create a look at matrix');
                it('Can create an identity matrix');
                it('Can create a matrix representing a 2D view');
                it('Can create a translation matrix');
                it('Can create a rotation matrix around the x axis');
                it('Can create a rotation matrix around the y axis');
                it('Can create a rotation matrix around the z axis');
                it('Can create a scale matrix');
                it('Can create a rotation matrix from a euler vector');
                it('Can create a rotation matrix from a quaternion');
                it('Can create a frumstum matrix');
                it('Can create a perspective matrix');
                it('Can create a orthographic matrix');
            });
        });
    }
}
