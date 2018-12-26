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
                    m[ 0].should.beCloseTo(1);
                    m[ 1].should.beCloseTo(0);
                    m[ 2].should.beCloseTo(0);
                    m[ 3].should.beCloseTo(0);

                    m[ 4].should.beCloseTo(0);
                    m[ 5].should.beCloseTo(1);
                    m[ 6].should.beCloseTo(0);
                    m[ 7].should.beCloseTo(0);

                    m[ 8].should.beCloseTo(0);
                    m[ 9].should.beCloseTo(0);
                    m[10].should.beCloseTo(1);
                    m[11].should.beCloseTo(0);

                    m[12].should.beCloseTo(0);
                    m[13].should.beCloseTo(0);
                    m[14].should.beCloseTo(0);
                    m[15].should.beCloseTo(1);
                });
                it('Can create a custom matrix passing any number of the 16 elements', {
                    var m = new Matrix(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15);
                    m[ 0].should.beCloseTo(0);
                    m[ 1].should.beCloseTo(4);
                    m[ 2].should.beCloseTo(8);
                    m[ 3].should.beCloseTo(12);

                    m[ 4].should.beCloseTo(1);
                    m[ 5].should.beCloseTo(5);
                    m[ 6].should.beCloseTo(9);
                    m[ 7].should.beCloseTo(13);

                    m[ 8].should.beCloseTo(2);
                    m[ 9].should.beCloseTo(6);
                    m[10].should.beCloseTo(10);
                    m[11].should.beCloseTo(14);

                    m[12].should.beCloseTo(3);
                    m[13].should.beCloseTo(7);
                    m[14].should.beCloseTo(11);
                    m[15].should.beCloseTo(15);
                });
            });

            describe('General', {
                it('Can set any number of matrix elements', {
                    var m = new Matrix();
                    m.set(3.4, 7.4, -0.4, 0);

                    m[ 0].should.beCloseTo(3.4);
                    m[ 1].should.beCloseTo(0);
                    m[ 2].should.beCloseTo(0);
                    m[ 3].should.beCloseTo(0);

                    m[ 4].should.beCloseTo(7.4);
                    m[ 5].should.beCloseTo(1);
                    m[ 6].should.beCloseTo(0);
                    m[ 7].should.beCloseTo(0);

                    m[ 8].should.beCloseTo(-0.4);
                    m[ 9].should.beCloseTo(0);
                    m[10].should.beCloseTo(1);
                    m[11].should.beCloseTo(0);

                    m[12].should.beCloseTo(0);
                    m[13].should.beCloseTo(0);
                    m[14].should.beCloseTo(0);
                    m[15].should.beCloseTo(1);
                });
                it('Can copy the elements from another matrix into its own', {
                    var m1 = new Matrix(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15);
                    var m2 = new Matrix();

                    m2.copy(m1);
                    m1[ 0].should.beCloseTo(m2[ 0]);
                    m1[ 1].should.beCloseTo(m2[ 1]);
                    m1[ 2].should.beCloseTo(m2[ 2]);
                    m1[ 3].should.beCloseTo(m2[ 3]);

                    m1[ 4].should.beCloseTo(m2[ 4]);
                    m1[ 5].should.beCloseTo(m2[ 5]);
                    m1[ 6].should.beCloseTo(m2[ 6]);
                    m1[ 7].should.beCloseTo(m2[ 7]);

                    m1[ 8].should.beCloseTo(m2[ 8]);
                    m1[ 9].should.beCloseTo(m2[ 9]);
                    m1[10].should.beCloseTo(m2[10]);
                    m1[11].should.beCloseTo(m2[11]);

                    m1[12].should.beCloseTo(m2[12]);
                    m1[13].should.beCloseTo(m2[13]);
                    m1[14].should.beCloseTo(m2[14]);
                    m1[15].should.beCloseTo(m2[15]);
                });
                it('Can create a clone of itself', {
                    var m1 = new Matrix(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15);
                    var m2 = m1.clone();

                    m1[ 0].should.beCloseTo(m2[ 0]);
                    m1[ 1].should.beCloseTo(m2[ 1]);
                    m1[ 2].should.beCloseTo(m2[ 2]);
                    m1[ 3].should.beCloseTo(m2[ 3]);

                    m1[ 4].should.beCloseTo(m2[ 4]);
                    m1[ 5].should.beCloseTo(m2[ 5]);
                    m1[ 6].should.beCloseTo(m2[ 6]);
                    m1[ 7].should.beCloseTo(m2[ 7]);

                    m1[ 8].should.beCloseTo(m2[ 8]);
                    m1[ 9].should.beCloseTo(m2[ 9]);
                    m1[10].should.beCloseTo(m2[10]);
                    m1[11].should.beCloseTo(m2[11]);

                    m1[12].should.beCloseTo(m2[12]);
                    m1[13].should.beCloseTo(m2[13]);
                    m1[14].should.beCloseTo(m2[14]);
                    m1[15].should.beCloseTo(m2[15]);
                });
                it('Can set its elements from an array', {
                    var m = new Matrix().fromArray([ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15 ]);

                    m[ 0].should.beCloseTo( 0);
                    m[ 1].should.beCloseTo( 1);
                    m[ 2].should.beCloseTo( 2);
                    m[ 3].should.beCloseTo( 3);

                    m[ 4].should.beCloseTo( 4);
                    m[ 5].should.beCloseTo( 5);
                    m[ 6].should.beCloseTo( 6);
                    m[ 7].should.beCloseTo( 7);

                    m[ 8].should.beCloseTo( 8);
                    m[ 9].should.beCloseTo( 9);
                    m[10].should.beCloseTo(9);
                    m[11].should.beCloseTo(11);

                    m[12].should.beCloseTo(12);
                    m[13].should.beCloseTo(13);
                    m[14].should.beCloseTo(13);
                    m[15].should.beCloseTo(15);
                });
                it('Can return an array containing all elements', {
                    var m = new Matrix(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15);
                    var a = m.toArray();

                    a.should.containExactly([ 0, 4, 8, 12, 1, 5, 9, 13, 2, 6, 10, 14, 3, 7, 11, 15 ]);
                });
                it('Can print out a string with all the elements values to three decimal places', {
                    var m = new Matrix(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15);
                    var s = '{ 11:' + Maths.fixed(m[0], 3) + ', 12:' + Maths.fixed(m[4], 3)  + ', 13:' + Maths.fixed(m[ 8], 3)  + ', 14:' + Maths.fixed(m[12], 3) + ' }, ' +
                            '{ 21:' + Maths.fixed(m[1], 3) + ', 22:' + Maths.fixed(m[5], 3)  + ', 23:' + Maths.fixed(m[ 9], 3)  + ', 24:' + Maths.fixed(m[13], 3) + ' }, ' +
                            '{ 31:' + Maths.fixed(m[2], 3) + ', 32:' + Maths.fixed(m[6], 3)  + ', 33:' + Maths.fixed(m[10], 3)  + ', 34:' + Maths.fixed(m[14], 3) + ' }, ' +
                            '{ 41:' + Maths.fixed(m[3], 3) + ', 42:' + Maths.fixed(m[7], 3)  + ', 43:' + Maths.fixed(m[11], 3)  + ', 44:' + Maths.fixed(m[15], 3) + ' }';

                    m.toString().should.be(s);
                });
                it('Can invert itself', {
                    var m = new Matrix().makeOrthographic(0, 1280, 0, 720, 1, 0).invert();
                    
                    m[ 0].should.beCloseTo(640);
                    m[ 4].should.beCloseTo(0);
                    m[ 8].should.beCloseTo(0);
                    m[12].should.beCloseTo(640);

                    m[ 1].should.beCloseTo(0);
                    m[ 5].should.beCloseTo(-360);
                    m[ 9].should.beCloseTo(0);
                    m[13].should.beCloseTo(360);

                    m[ 2].should.beCloseTo(0);
                    m[ 6].should.beCloseTo(0);
                    m[10].should.beCloseTo(0.5);
                    m[14].should.beCloseTo(-0.5);

                    m[ 3].should.beCloseTo(0);
                    m[ 7].should.beCloseTo(0);
                    m[11].should.beCloseTo(0);
                    m[15].should.beCloseTo(1);
                });
            });

            describe('Maths', {
                it('Can calculate the determinant of the matrix', {
                    var determinant = new Matrix().makeOrthographic(0, 1280, 0, 720, 1, 0).determinant();
                    determinant.should.beCloseTo(-8.68055589510025e-06);
                });
                it('Can transpose the matrix', {
                    var m = new Matrix().makeOrthographic(0, 1280, 0, 720, 1, 0).transpose();
                    
                    m[ 0].should.beCloseTo(0.001);
                    m[ 4].should.beCloseTo(0);
                    m[ 8].should.beCloseTo(0);
                    m[12].should.beCloseTo(0);

                    m[ 1].should.beCloseTo(0);
                    m[ 5].should.beCloseTo(-0.002);
                    m[ 9].should.beCloseTo(0);
                    m[13].should.beCloseTo(0);

                    m[ 2].should.beCloseTo(0);
                    m[ 6].should.beCloseTo(0);
                    m[10].should.beCloseTo(2);
                    m[14].should.beCloseTo(0);

                    m[ 3].should.beCloseTo(-1);
                    m[ 7].should.beCloseTo(1);
                    m[11].should.beCloseTo(1);
                    m[15].should.beCloseTo(1);
                });
                it('Can scale the matrix', {
                    var m = new Matrix().makeOrthographic(0, 1280, 0, 720, 1, 0).scale(new Vector(2.3, 0.75, -0.4));
                    
                    m[ 0].should.beCloseTo(0.003);
                    m[ 4].should.beCloseTo(0);
                    m[ 8].should.beCloseTo(0);
                    m[12].should.beCloseTo(-1);

                    m[ 1].should.beCloseTo(0);
                    m[ 5].should.beCloseTo(-0.002);
                    m[ 9].should.beCloseTo(0);
                    m[13].should.beCloseTo(1);

                    m[ 2].should.beCloseTo(0);
                    m[ 6].should.beCloseTo(0);
                    m[10].should.beCloseTo(-0.8);
                    m[14].should.beCloseTo(1);

                    m[ 3].should.beCloseTo(0);
                    m[ 7].should.beCloseTo(0);
                    m[11].should.beCloseTo(0);
                    m[15].should.beCloseTo(1);
                });
                it('Can compose a matrix from a position, rotation, and scale', {
                    var m = new Matrix().makeOrthographic(0, 1280, 0, 720, 1, 0).transpose();

                    m[ 0].should.beCloseTo(0.001);
                    m[ 4].should.beCloseTo(0);
                    m[ 8].should.beCloseTo(0);
                    m[12].should.beCloseTo(0);

                    m[ 1].should.beCloseTo(0);
                    m[ 5].should.beCloseTo(-0.002);
                    m[ 9].should.beCloseTo(0);
                    m[13].should.beCloseTo(0);

                    m[ 2].should.beCloseTo(0);
                    m[ 6].should.beCloseTo(0);
                    m[10].should.beCloseTo(2);
                    m[14].should.beCloseTo(0);

                    m[ 3].should.beCloseTo(-1);
                    m[ 7].should.beCloseTo(1);
                    m[11].should.beCloseTo(1);
                    m[15].should.beCloseTo(1);
                });
                it('Can decompose a matrix into a position, rotation, and scale', {
                    var t = new Matrix().makeOrthographic(0, 1280, 0, 720, 1, 0).decompose(null, null, null);
                    
                    t.position.x.should.beCloseTo(-1);
                    t.position.y.should.beCloseTo(1);
                    t.position.z.should.beCloseTo(1);
                    t.position.w.should.beCloseTo(0);

                    t.scale.x.should.beCloseTo(0.00156);
                    t.scale.y.should.beCloseTo(0.00277);
                    t.scale.z.should.beCloseTo(2);
                    t.scale.w.should.beCloseTo(0);

                    t.rotation.x.should.beCloseTo(0);
                    t.rotation.y.should.beCloseTo(0);
                    t.rotation.z.should.beCloseTo(0);
                    t.rotation.w.should.beCloseTo(17.890);
                });
            });

            describe('Operations', {
                it('Can multiply itself with another matrix', {
                    var m1 = new Matrix().makeScale(0.5, 2.3, -0.7);
                    var m2 = new Matrix().makeOrthographic(0, 1280, 0, 720, 0, 1);
                    m1.multiply(m2);

                    m1[ 0].should.beCloseTo(0);
                    m1[ 4].should.beCloseTo(0);
                    m1[ 8].should.beCloseTo(0);
                    m1[12].should.beCloseTo(-0.5);

                    m1[ 1].should.beCloseTo(0);
                    m1[ 5].should.beCloseTo(-0.006);
                    m1[ 9].should.beCloseTo(0);
                    m1[13].should.beCloseTo(2.299);

                    m1[ 2].should.beCloseTo(0);
                    m1[ 6].should.beCloseTo(0);
                    m1[10].should.beCloseTo(1.399);
                    m1[14].should.beCloseTo(0.699);

                    m1[ 3].should.beCloseTo(0);
                    m1[ 7].should.beCloseTo(0);
                    m1[11].should.beCloseTo(0);
                    m1[15].should.beCloseTo(1);
                });
                it('Can multiply to matrices together and store the result in itself', {
                    var m1 = new Matrix().makeScale(0.5, 2.3, -0.7);
                    var m2 = new Matrix().makeOrthographic(0, 1280, 0, 720, 0, 1);
                    var m3 = new Matrix().multiplyMatrices(m1, m2);

                    m3[ 0].should.beCloseTo(0);
                    m3[ 4].should.beCloseTo(0);
                    m3[ 8].should.beCloseTo(0);
                    m3[12].should.beCloseTo(-0.5);

                    m3[ 1].should.beCloseTo(0);
                    m3[ 5].should.beCloseTo(-0.006);
                    m3[ 9].should.beCloseTo(0);
                    m3[13].should.beCloseTo(2.299);

                    m3[ 2].should.beCloseTo(0);
                    m3[ 6].should.beCloseTo(0);
                    m3[10].should.beCloseTo(1.399);
                    m3[14].should.beCloseTo(0.699);

                    m3[ 3].should.beCloseTo(0);
                    m3[ 7].should.beCloseTo(0);
                    m3[11].should.beCloseTo(0);
                    m3[15].should.beCloseTo(1);
                });
                it('Can multiply itself by a scalar value', {
                    var m = new Matrix().makeOrthographic(0, 1280, 0, 720, 0, 1).multiplyScalar(2.3);
                    
                    m[ 0].should.beCloseTo(0.003);
                    m[ 4].should.beCloseTo(0);
                    m[ 8].should.beCloseTo(0);
                    m[12].should.beCloseTo(-2.299);

                    m[ 1].should.beCloseTo(0);
                    m[ 5].should.beCloseTo(-0.006);
                    m[ 9].should.beCloseTo(0);
                    m[13].should.beCloseTo(2.299);

                    m[ 2].should.beCloseTo(0);
                    m[ 6].should.beCloseTo(0);
                    m[10].should.beCloseTo(-4.599);
                    m[14].should.beCloseTo(-2.299);

                    m[ 3].should.beCloseTo(0);
                    m[ 7].should.beCloseTo(0);
                    m[11].should.beCloseTo(0);
                    m[15].should.beCloseTo(2.299);
                });
                it('Can get the up vector of this matrix', {
                    var v = new Matrix().makeOrthographic(0, 1280, 0, 720, 0, 1).up();
                    v.x.should.beCloseTo(0);
                    v.y.should.beCloseTo(-0.002);
                    v.z.should.beCloseTo(0);
                    v.w.should.beCloseTo(0);
                });
                it('Can get the down vector of this matrix', {
                    var v = new Matrix().makeOrthographic(0, 1280, 0, 720, 0, 1).down();
                    v.x.should.beCloseTo(0);
                    v.y.should.beCloseTo(-0.002);
                    v.z.should.beCloseTo(0);
                    v.w.should.beCloseTo(0);
                });
                it('Can get the left vector of this matrix', {
                    var v = new Matrix().makeOrthographic(0, 1280, 0, 720, 0, 1).left();
                    v.x.should.beCloseTo(0);
                    v.y.should.beCloseTo(-0.001);
                    v.z.should.beCloseTo(0);
                    v.w.should.beCloseTo(0);
                });
                it('Can get the right vector of this matrix', {
                    var v = new Matrix().makeOrthographic(0, 1280, 0, 720, 0, 1).right();
                    v.x.should.beCloseTo(0);
                    v.y.should.beCloseTo(-0.001);
                    v.z.should.beCloseTo(0);
                    v.w.should.beCloseTo(0);
                });
                it('Can get the forward vector of this matrix', {
                    var v = new Matrix().makeOrthographic(0, 1280, 0, 720, 0, 1).forward();
                    v.x.should.beCloseTo(0);
                    v.y.should.beCloseTo(0);
                    v.z.should.beCloseTo(2);
                    v.w.should.beCloseTo(0);
                });
                it('Can get the backwards vector of this matrix', {
                    var v = new Matrix().makeOrthographic(0, 1280, 0, 720, 0, 1).backwards();
                    v.x.should.beCloseTo(0);
                    v.y.should.beCloseTo(0);
                    v.z.should.beCloseTo(-2);
                    v.w.should.beCloseTo(0);
                });
            });

            describe('Transformations', {
                it('Can set its position from a vector', {
                    var v = new Vector(3, -5, 7.5);
                    var m = new Matrix().setPosition(v);

                    m[ 0].should.beCloseTo(1);
                    m[ 1].should.beCloseTo(0);
                    m[ 2].should.beCloseTo(0);
                    m[ 3].should.beCloseTo(0);

                    m[ 4].should.beCloseTo(0);
                    m[ 5].should.beCloseTo(1);
                    m[ 6].should.beCloseTo(0);
                    m[ 7].should.beCloseTo(0);

                    m[ 8].should.beCloseTo(0);
                    m[ 9].should.beCloseTo(0);
                    m[10].should.beCloseTo(1);
                    m[11].should.beCloseTo(0);

                    m[12].should.beCloseTo(v.x);
                    m[13].should.beCloseTo(v.y);
                    m[14].should.beCloseTo(v.z);
                    m[15].should.beCloseTo(1);
                });
                it('Can return the position as a vector', {
                    var m = new Matrix().setPosition(new Vector(3, -5, 7.5));
                    var v = m.getPosition();
                    v.x.should.beCloseTo(3);
                    v.y.should.beCloseTo(-5);
                    v.z.should.beCloseTo(7.5);
                });
                it('Can create a look at matrix', {
                    var m = new Matrix().lookAt(new Vector(0.0, 3.0, -5.0), new Vector(0.0, 0.0, 0.0), new Vector(0.0, 1.0, 0.0));
                    
                    m[ 0].should.beCloseTo(1);
                    m[ 1].should.beCloseTo(0);
                    m[ 2].should.beCloseTo(0);
                    m[ 3].should.beCloseTo(0);

                    m[ 4].should.beCloseTo(0);
                    m[ 5].should.beCloseTo(0.857);
                    m[ 6].should.beCloseTo(0.514);
                    m[ 7].should.beCloseTo(0);

                    m[ 8].should.beCloseTo(0);
                    m[ 9].should.beCloseTo(-0.514);
                    m[10].should.beCloseTo(0.857);
                    m[11].should.beCloseTo(0);

                    m[12].should.beCloseTo(0);
                    m[13].should.beCloseTo(0);
                    m[14].should.beCloseTo(0);
                    m[15].should.beCloseTo(1);
                });
                it('Can create an identity matrix', {
                    var m = new Matrix(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15).identity();
                    
                    m[ 0].should.beCloseTo(1);
                    m[ 1].should.beCloseTo(0);
                    m[ 2].should.beCloseTo(0);
                    m[ 3].should.beCloseTo(0);

                    m[ 4].should.beCloseTo(0);
                    m[ 5].should.beCloseTo(1);
                    m[ 6].should.beCloseTo(0);
                    m[ 7].should.beCloseTo(0);

                    m[ 8].should.beCloseTo(0);
                    m[ 9].should.beCloseTo(0);
                    m[10].should.beCloseTo(1);
                    m[11].should.beCloseTo(0);

                    m[12].should.beCloseTo(0);
                    m[13].should.beCloseTo(0);
                    m[14].should.beCloseTo(0);
                    m[15].should.beCloseTo(1);
                });
                it('Can create a matrix representing a 2D view', {
                    var m = new Matrix().make2D(1280, 720, 1.25, 45);
                    
                    m[ 0].should.beCloseTo(0.883);
                    m[ 1].should.beCloseTo(-0.883);
                    m[ 2].should.beCloseTo(0);
                    m[ 3].should.beCloseTo(0);

                    m[ 4].should.beCloseTo(0.883);
                    m[ 5].should.beCloseTo(0.883);
                    m[ 6].should.beCloseTo(0);
                    m[ 7].should.beCloseTo(0);

                    m[ 8].should.beCloseTo(0);
                    m[ 9].should.beCloseTo(0);
                    m[10].should.beCloseTo(1);
                    m[11].should.beCloseTo(0);

                    m[12].should.beCloseTo(1280);
                    m[13].should.beCloseTo(720);
                    m[14].should.beCloseTo(0);
                    m[15].should.beCloseTo(1);
                });
                it('Can create a translation matrix', {
                    var m = new Matrix().makeTranslation(0.5, 2.3, -0.75);

                    m[ 0].should.beCloseTo(1);
                    m[ 1].should.beCloseTo(0);
                    m[ 2].should.beCloseTo(0);
                    m[ 3].should.beCloseTo(0);

                    m[ 4].should.beCloseTo(0);
                    m[ 5].should.beCloseTo(1);
                    m[ 6].should.beCloseTo(0);
                    m[ 7].should.beCloseTo(0);

                    m[ 8].should.beCloseTo(0);
                    m[ 9].should.beCloseTo(0);
                    m[10].should.beCloseTo(1);
                    m[11].should.beCloseTo(0);

                    m[12].should.beCloseTo(0.5);
                    m[13].should.beCloseTo(2.3);
                    m[14].should.beCloseTo(-0.75);
                    m[15].should.beCloseTo(1);
                });
                it('Can create a rotation matrix around the x axis', {
                    var m = new Matrix();
                    m.makeRotationX(0.5);

                    m[ 0].should.beCloseTo(1);
                    m[ 1].should.beCloseTo(0);
                    m[ 2].should.beCloseTo(0);
                    m[ 3].should.beCloseTo(0);

                    m[ 4].should.beCloseTo(0);
                    m[ 5].should.beCloseTo(0.877);
                    m[ 6].should.beCloseTo(0.479);
                    m[ 7].should.beCloseTo(0);

                    m[ 8].should.beCloseTo(0);
                    m[ 9].should.beCloseTo(-0.479);
                    m[10].should.beCloseTo(0.877);
                    m[11].should.beCloseTo(0);

                    m[12].should.beCloseTo(0);
                    m[13].should.beCloseTo(0);
                    m[14].should.beCloseTo(0);
                    m[15].should.beCloseTo(1);
                });
                it('Can create a rotation matrix around the y axis', {
                    var m = new Matrix().makeRotationY(0.5);

                    m[ 0].should.beCloseTo(0.877);
                    m[ 1].should.beCloseTo(0);
                    m[ 2].should.beCloseTo(-0.479);
                    m[ 3].should.beCloseTo(0);

                    m[ 4].should.beCloseTo(0);
                    m[ 5].should.beCloseTo(1);
                    m[ 6].should.beCloseTo(0);
                    m[ 7].should.beCloseTo(0);

                    m[ 8].should.beCloseTo(0.479);
                    m[ 9].should.beCloseTo(0);
                    m[10].should.beCloseTo(0.877);
                    m[11].should.beCloseTo(0);

                    m[12].should.beCloseTo(0);
                    m[13].should.beCloseTo(0);
                    m[14].should.beCloseTo(0);
                    m[15].should.beCloseTo(1);
                });
                it('Can create a rotation matrix around the z axis', {
                    var m = new Matrix().makeRotationZ(0.5);

                    m[ 0].should.beCloseTo(0.877);
                    m[ 1].should.beCloseTo(0.479);
                    m[ 2].should.beCloseTo(0);
                    m[ 3].should.beCloseTo(0);

                    m[ 4].should.beCloseTo(-0.479);
                    m[ 5].should.beCloseTo(0.877);
                    m[ 6].should.beCloseTo(0);
                    m[ 7].should.beCloseTo(0);

                    m[ 8].should.beCloseTo(0);
                    m[ 9].should.beCloseTo(0);
                    m[10].should.beCloseTo(1);
                    m[11].should.beCloseTo(0);

                    m[12].should.beCloseTo(0);
                    m[13].should.beCloseTo(0);
                    m[14].should.beCloseTo(0);
                    m[15].should.beCloseTo(1);
                });
                it('Can create a scale matrix', {
                    var m = new Matrix().makeScale(0.5, 2.3, -0.75);

                    m[ 0].should.beCloseTo(0.5);
                    m[ 1].should.beCloseTo(0);
                    m[ 2].should.beCloseTo(0);
                    m[ 3].should.beCloseTo(0);

                    m[ 4].should.beCloseTo(0);
                    m[ 5].should.beCloseTo(2.3);
                    m[ 6].should.beCloseTo(0);
                    m[ 7].should.beCloseTo(0);

                    m[ 8].should.beCloseTo(0);
                    m[ 9].should.beCloseTo(0);
                    m[10].should.beCloseTo(-0.75);
                    m[11].should.beCloseTo(0);

                    m[12].should.beCloseTo(0);
                    m[13].should.beCloseTo(0);
                    m[14].should.beCloseTo(0);
                    m[15].should.beCloseTo(1);
                });
                it('Can create a rotation matrix from a euler vector', {
                    var m = new Matrix().makeRotationFromEuler(new Vector(0.5, 1.2, -0.42));

                    m[ 0].should.beCloseTo(0.33);
                    m[ 1].should.beCloseTo(0.050);
                    m[ 2].should.beCloseTo(-0.942);
                    m[ 3].should.beCloseTo(0);

                    m[ 4].should.beCloseTo(0.147);
                    m[ 5].should.beCloseTo(0.983);
                    m[ 6].should.beCloseTo(0.104);
                    m[ 7].should.beCloseTo(0);

                    m[ 8].should.beCloseTo(0.932);
                    m[ 9].should.beCloseTo(-0.173);
                    m[10].should.beCloseTo(0.317);
                    m[11].should.beCloseTo(0);

                    m[12].should.beCloseTo(0);
                    m[13].should.beCloseTo(0);
                    m[14].should.beCloseTo(0);
                    m[15].should.beCloseTo(1);
                });
                it('Can create a rotation matrix from a axis vector and a rotation value', {
                    var m = new Matrix().makeRotationAxis(new Vector(1, 0, 1), 0.25);

                    m[ 0].should.beCloseTo(1);
                    m[ 1].should.beCloseTo(0.247);
                    m[ 2].should.beCloseTo(0.031);
                    m[ 3].should.beCloseTo(0);

                    m[ 4].should.beCloseTo(-0.247);
                    m[ 5].should.beCloseTo(0.968);
                    m[ 6].should.beCloseTo(0.247);
                    m[ 7].should.beCloseTo(0);

                    m[ 8].should.beCloseTo(0.031);
                    m[ 9].should.beCloseTo(-0.247);
                    m[10].should.beCloseTo(1);
                    m[11].should.beCloseTo(0);

                    m[12].should.beCloseTo(0);
                    m[13].should.beCloseTo(0);
                    m[14].should.beCloseTo(0);
                    m[15].should.beCloseTo(1);
                });
                it('Can create a rotation matrix from a quaternion', {
                    var m = new Matrix().makeRotationFromQuaternion(new Quaternion().setFromAxisAngle(new Vector(1, 0, 1), 0.25));

                    m[ 0].should.beCloseTo(0.968);
                    m[ 1].should.beCloseTo(0.247);
                    m[ 2].should.beCloseTo(0.031);
                    m[ 3].should.beCloseTo(0);

                    m[ 4].should.beCloseTo(-0.247);
                    m[ 5].should.beCloseTo(0.937);
                    m[ 6].should.beCloseTo(0.247);
                    m[ 7].should.beCloseTo(0);

                    m[ 8].should.beCloseTo(0.031);
                    m[ 9].should.beCloseTo(-0.247);
                    m[10].should.beCloseTo(0.968);
                    m[11].should.beCloseTo(0);

                    m[12].should.beCloseTo(0);
                    m[13].should.beCloseTo(0);
                    m[14].should.beCloseTo(0);
                    m[15].should.beCloseTo(1);
                });
                it('Can create a frumstum matrix', {
                    var m = new Matrix().makeFrustum(0, 1280, 720, 0, 0, 1);

                    m[ 0].should.beCloseTo(0);
                    m[ 1].should.beCloseTo(0);
                    m[ 2].should.beCloseTo(0);
                    m[ 3].should.beCloseTo(0);

                    m[ 4].should.beCloseTo(0);
                    m[ 5].should.beCloseTo(0);
                    m[ 6].should.beCloseTo(0);
                    m[ 7].should.beCloseTo(0);

                    m[ 8].should.beCloseTo(1);
                    m[ 9].should.beCloseTo(-1);
                    m[10].should.beCloseTo(-1);
                    m[11].should.beCloseTo(-1);

                    m[12].should.beCloseTo(0);
                    m[13].should.beCloseTo(0);
                    m[14].should.beCloseTo(0);
                    m[15].should.beCloseTo(0);
                });
                it('Can create a perspective matrix', {
                    var m = new Matrix().makePerspective(70, 1280 / 720, 0, 100);

                    Math.isNaN(m[0]).should.be(true);
                    m[ 1].should.beCloseTo(0);
                    m[ 2].should.beCloseTo(0);
                    m[ 3].should.beCloseTo(0);

                    m[ 4].should.beCloseTo(0);
                    Math.isNaN(m[5]).should.be(true);
                    m[ 6].should.beCloseTo(0);
                    m[ 7].should.beCloseTo(0);

                    Math.isNaN(m[8]).should.be(true);
                    Math.isNaN(m[9]).should.be(true);
                    m[10].should.beCloseTo(-1);
                    m[11].should.beCloseTo(-1);

                    m[12].should.beCloseTo(0);
                    m[13].should.beCloseTo(0);
                    m[14].should.beCloseTo(0);
                    m[15].should.beCloseTo(0);
                });
                it('Can create a orthographic matrix', {
                    var m = new Matrix().makeOrthographic(0, 1600, 0, 1280, 0, 1);

                    m[ 0].should.beCloseTo(0.001);
                    m[ 1].should.beCloseTo(0);
                    m[ 2].should.beCloseTo(0);
                    m[ 3].should.beCloseTo(0);

                    m[ 4].should.beCloseTo(0);
                    m[ 5].should.beCloseTo(-0.001);
                    m[ 6].should.beCloseTo(0);
                    m[ 7].should.beCloseTo(0);

                    m[ 8].should.beCloseTo(0);
                    m[ 9].should.beCloseTo(0);
                    m[10].should.beCloseTo(-2);
                    m[11].should.beCloseTo(0);

                    m[12].should.beCloseTo(-1);
                    m[13].should.beCloseTo(1);
                    m[14].should.beCloseTo(-1);
                    m[15].should.beCloseTo(1);
                });
            });

            describe('Operator Overloading', {
                it('Can multiply itself with another matrix', {
                    var m1 = new Matrix().makeScale(0.5, 2.3, -0.7);
                    var m2 = new Matrix().makeOrthographic(0, 1280, 0, 720, 0, 1);
                    var m3 = m1 * m2;

                    m3[ 0].should.beCloseTo(0);
                    m3[ 4].should.beCloseTo(0);
                    m3[ 8].should.beCloseTo(0);
                    m3[12].should.beCloseTo(-0.5);

                    m3[ 1].should.beCloseTo(0);
                    m3[ 5].should.beCloseTo(-0.006);
                    m3[ 9].should.beCloseTo(0);
                    m3[13].should.beCloseTo(2.299);

                    m3[ 2].should.beCloseTo(0);
                    m3[ 6].should.beCloseTo(0);
                    m3[10].should.beCloseTo(1.399);
                    m3[14].should.beCloseTo(0.699);

                    m3[ 3].should.beCloseTo(0);
                    m3[ 7].should.beCloseTo(0);
                    m3[11].should.beCloseTo(0);
                    m3[15].should.beCloseTo(1);
                });
                it('Can multiply itself by a scalar value', {
                    var m = new Matrix().makeOrthographic(0, 1280, 0, 720, 0, 1) * 2.3;
                    
                    m[ 0].should.beCloseTo(0.003);
                    m[ 4].should.beCloseTo(0);
                    m[ 8].should.beCloseTo(0);
                    m[12].should.beCloseTo(-2.299);

                    m[ 1].should.beCloseTo(0);
                    m[ 5].should.beCloseTo(-0.006);
                    m[ 9].should.beCloseTo(0);
                    m[13].should.beCloseTo(2.299);

                    m[ 2].should.beCloseTo(0);
                    m[ 6].should.beCloseTo(0);
                    m[10].should.beCloseTo(-4.599);
                    m[14].should.beCloseTo(-2.299);

                    m[ 3].should.beCloseTo(0);
                    m[ 7].should.beCloseTo(0);
                    m[11].should.beCloseTo(0);
                    m[15].should.beCloseTo(2.299);
                });
            });
        });
    }
}
