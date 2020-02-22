package tests.api.gpu.geometry;

import uk.aidanlee.flurry.api.maths.Hash;
import uk.aidanlee.flurry.api.maths.Vector4;
import uk.aidanlee.flurry.api.buffers.Float32BufferData;
import uk.aidanlee.flurry.api.maths.Matrix;
import uk.aidanlee.flurry.api.gpu.geometry.UniformBlob.UniformBlobBuilder;
import buddy.BuddySuite;

using buddy.Should;

class UniformBlobTests extends BuddySuite
{
    public function new()
    {
        describe('UniformBlobBuilder', {
            it('can define a matrix in the uniform blob', {
                final buffer = new UniformBlobBuilder('uniforms').addMatrix('matrix').uniformBlob();

                buffer.buffer.byteLength.should.be(64);
            });
            it('can define a matrix in the uniform blob and provide an initial value', {
                final matrix = new Matrix().makeHomogeneousOrthographic(0, 1280, 720, 0, 0, 100);
                final buffer = new UniformBlobBuilder('uniforms').addMatrix('matrix', matrix).uniformBlob();

                buffer.buffer.byteLength.should.be(64);
                buffer.buffer.bytes.getData().should.containExactly((matrix : Float32BufferData).bytes.getData());
            });
            it('can define a vector4 in the uniform blob', {
                final buffer = new UniformBlobBuilder('uniforms').addVector4('vector').uniformBlob();

                buffer.buffer.byteLength.should.be(16);
            });
            it('can define a vector4 in the uniform blob and provide an initial value', {
                final vector = new Vector4(7, 14, 8.64, 9);
                final buffer = new UniformBlobBuilder('uniforms').addVector4('vector', vector).uniformBlob();

                buffer.buffer.byteLength.should.be(16);
                buffer.buffer.bytes.getData().should.containExactly((vector : Float32BufferData).bytes.getData());
            });
        });

        describe('UniformBlob', {
            it('can update a uniforms matrix', {
                final matrix = new Matrix().makeHomogeneousOrthographic(0, 1280, 720, 0, 0, 100);
                final buffer = new UniformBlobBuilder('uniforms').addMatrix('matrix').uniformBlob();

                buffer.setMatrix('matrix', matrix);
                buffer.buffer.byteLength.should.be(64);
                buffer.buffer.bytes.getData().should.containExactly((matrix : Float32BufferData).bytes.getData());
            });
            it('can update a uniforms vector4', {
                final vector = new Vector4(7, 14, 8.64, 9);
                final buffer = new UniformBlobBuilder('uniforms').addVector4('vector').uniformBlob();

                buffer.setVector4('vector', vector);
                buffer.buffer.byteLength.should.be(16);
                buffer.buffer.bytes.getData().should.containExactly((vector : Float32BufferData).bytes.getData());
            });
            it('can correctly update multiple uniforms at their offset', {
                final matrix1 = new Matrix().makeHomogeneousOrthographic(0, 1280, 720, 0, 0, 100);
                final matrix2 = new Matrix().makeTranslation(12.6, 42.999, 0.2256);
                final vector1 = new Vector4(7, 14, 8.64, 9);
                final vector2 = vector1.normalized;

                final buffer = new UniformBlobBuilder('uniforms')
                    .addMatrix('matrix1', matrix1)
                    .addVector4('vector1', vector1)
                    .addMatrix('matrix2', matrix2)
                    .addVector4('vector2', vector2)
                    .uniformBlob();

                buffer.buffer.byteLength.should.be(160);
                buffer.buffer.bytes.getData().should.containExactly(
                    (matrix1 : Float32BufferData).bytes.getData().concat(
                        (vector1 : Float32BufferData).bytes.getData().concat(
                            (matrix2 : Float32BufferData).bytes.getData().concat(
                                (vector2 : Float32BufferData).bytes.getData()
                            )
                        )
                    )
                );
            });
            it('contains an integer hash of the uniform blob name', {
                final buffer = new UniformBlobBuilder('uniforms').uniformBlob();
                buffer.name.should.be('uniforms');
                buffer.id.should.be(Hash.hash('uniforms'));
            });
        });
    }
}