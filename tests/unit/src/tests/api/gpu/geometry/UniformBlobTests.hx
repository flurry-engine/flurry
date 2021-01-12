package tests.api.gpu.geometry;

import haxe.io.BytesBuffer;
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
                buffer.buffer.bytes.compare((matrix : Float32BufferData).bytes).should.be(0);
            });
            it('can define a vector4 in the uniform blob', {
                final buffer = new UniformBlobBuilder('uniforms').addVector4('vector').uniformBlob();

                buffer.buffer.byteLength.should.be(16);
            });
            it('can define a vector4 in the uniform blob and provide an initial value', {
                final vector = new Vector4(7, 14, 8.64, 9);
                final buffer = new UniformBlobBuilder('uniforms').addVector4('vector', vector).uniformBlob();

                buffer.buffer.byteLength.should.be(16);
                buffer.buffer.bytes.compare((vector : Float32BufferData).bytes).should.be(0);
            });
        });

        describe('UniformBlob', {
            it('can update a uniforms matrix', {
                final matrix = new Matrix().makeHomogeneousOrthographic(0, 1280, 720, 0, 0, 100);
                final buffer = new UniformBlobBuilder('uniforms').addMatrix('matrix').uniformBlob();

                buffer.setMatrix('matrix', matrix);
                buffer.buffer.byteLength.should.be(64);
                buffer.buffer.bytes.compare((matrix : Float32BufferData).bytes).should.be(0);
            });
            it('can update a uniforms vector4', {
                final vector = new Vector4(7, 14, 8.64, 9);
                final buffer = new UniformBlobBuilder('uniforms').addVector4('vector').uniformBlob();

                buffer.setVector4('vector', vector);
                buffer.buffer.byteLength.should.be(16);
                buffer.buffer.bytes.compare((vector : Float32BufferData).bytes).should.be(0);
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

                final concat = new BytesBuffer();
                concat.addBytes((matrix1 : Float32BufferData).bytes, 0, 64);
                concat.addBytes((vector1 : Float32BufferData).bytes, 0, 16);
                concat.addBytes((matrix2 : Float32BufferData).bytes, 0, 64);
                concat.addBytes((vector2 : Float32BufferData).bytes, 0, 16);

                buffer.buffer.byteLength.should.be(160);
                buffer.buffer.bytes.compare(concat.getBytes()).should.be(0);
            });
        });
    }
}