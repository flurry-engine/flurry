package tests.api.maths;

import buddy.BuddySuite;
import uk.aidanlee.flurry.api.maths.Vector;
import uk.aidanlee.flurry.api.maths.Quaternion;
import uk.aidanlee.flurry.api.maths.Matrix;
import uk.aidanlee.flurry.api.maths.Maths;

using buddy.Should;

class MatrixTests extends BuddySuite
{
    public function new()
    {
        describe('Column Major Matrix', {
            describe('Constructor', {
                it('Can create a default identity matrix', {
                    var m = new Matrix();
                    m[ 0].should.be(1);
                    m[ 1].should.be(0);
                    m[ 2].should.be(0);
                    m[ 3].should.be(0);

                    m[ 4].should.be(0);
                    m[ 5].should.be(1);
                    m[ 6].should.be(0);
                    m[ 7].should.be(0);

                    m[ 8].should.be(0);
                    m[ 9].should.be(0);
                    m[10].should.be(1);
                    m[11].should.be(0);

                    m[12].should.be(0);
                    m[13].should.be(0);
                    m[14].should.be(0);
                    m[15].should.be(1);
                });
                it('Can create a custom matrix passing any number of the 16 elements', {
                    var m = new Matrix(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15);
                    m[ 0].should.be(0);
                    m[ 1].should.be(4);
                    m[ 2].should.be(8);
                    m[ 3].should.be(12);

                    m[ 4].should.be(1);
                    m[ 5].should.be(5);
                    m[ 6].should.be(9);
                    m[ 7].should.be(13);

                    m[ 8].should.be(2);
                    m[ 9].should.be(6);
                    m[10].should.be(10);
                    m[11].should.be(14);

                    m[12].should.be(3);
                    m[13].should.be(7);
                    m[14].should.be(11);
                    m[15].should.be(15);
                });
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
                it('Can set its position from a vector', {
                    var v = new Vector(3, -5, 7.5);
                    var m = new Matrix().setPosition(v);

                    m[ 0].should.be(1);
                    m[ 1].should.be(0);
                    m[ 2].should.be(0);
                    m[ 3].should.be(0);

                    m[ 4].should.be(0);
                    m[ 5].should.be(1);
                    m[ 6].should.be(0);
                    m[ 7].should.be(0);

                    m[ 8].should.be(0);
                    m[ 9].should.be(0);
                    m[10].should.be(1);
                    m[11].should.be(0);

                    m[12].should.be(v.x);
                    m[13].should.be(v.y);
                    m[14].should.be(v.z);
                    m[15].should.be(1);
                });
                it('Can return the position as a vector', {
                    var m = new Matrix().setPosition(new Vector(3, -5, 7.5));
                    var v = m.getPosition();
                    v.x.should.be(3);
                    v.y.should.be(-5);
                    v.z.should.be(7.5);
                });
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

            describe('Operator Overloading', {
                it('Can multiply itself with another matrix');
                it('Can multiply itself by a scalar value');
            });
        });
    }
}
