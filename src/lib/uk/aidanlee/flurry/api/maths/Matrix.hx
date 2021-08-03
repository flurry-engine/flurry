package uk.aidanlee.flurry.api.maths;

import VectorMath;

overload extern inline function identity()
{
    return mat4(1);
}

overload extern inline function make2D(_x : Float, _y : Float)
{
    return makeTranslation(_x, _y);
}

overload extern inline function make2D(_x : Float, _y : Float, _angle : Float)
{
    return make2D(_x, _y, _angle, 1);
}

overload extern inline function make2D(_x : Float, _y : Float, _angle : Float, _scale : Float)
{
    final c   = Math.cos(_angle);
    final s   = Math.sin(_angle);
    final mat = mat3(
        c * _scale, -s * _scale, 0,
        s * _scale,  c * _scale, 0,
                _x,          _y, 1
    );
    
    return mat;
}

overload extern inline function makeScale(_v : Vec2)
{
    return makeScale(_v.x, _v.y, 1);
}

overload extern inline function makeScale(_x : Float, _y : Float)
{
    return makeScale(_x, _y, 1);
}

overload extern inline function makeScale(_x : Float, _y : Float, _z : Float)
{
    return mat3(
        _x,  0,  0,
         0, _y,  0,
         0,  0, _z
    );
}

overload extern inline function makeTranslation(_x : Float, _y : Float)
{
    return makeTranslation(_x, _y, 1);
}

overload extern inline function makeTranslation(_v : Vec2)
{
    return makeTranslation(_v.x, _v.y, 1);
}

overload extern inline function makeTranslation(_v : Vec3)
{
    return makeTranslation(_v.x, _v.y, _v.z);
}

overload extern inline function makeTranslation(_x : Float, _y : Float, _z : Float)
{
    return mat3(
        1,  0,  0,
        0,  1,  0,
       _x, _y, _z
   );
}

inline function makeRotationZ(_angle : Float)
{
    final c = Maths.cos(_angle);
    final s = Maths.sin(_angle);

    return mat3(
        c, -s,  0,
        s,  c,  0,
        0,  0,  1
    );
}

/**
 * Produces a column major, right handed orthographic projection matrix compatible with D3D.
 * https://blog.demofox.org/2017/03/31/orthogonal-projection-matrix-plainly-explained/
 */
overload extern inline function makeFrustum(_left : Float, _right : Float, _top : Float, _bottom : Float, _near : Float, _far : Float)
{
    final a   =  2 / (_right - _left);
    final b   =  2 / (_top - _bottom);
    final c   = - 2 / (_far - _near);
    final x   = - (_right + _left) / (_right - _left);
    final y   = - (_top + _bottom) / (_top - _bottom);
    final z   = - (_far + _near) / (_far - _near);

    return mat4(
        a, 0, 0, 0,
        0, b, 0, 0,
        0, 0, c, 0,
        x, y, z, 1
    );
}

overload extern inline function makeFrustumOpenGL(_left : Float, _right : Float, _top : Float, _bottom : Float, _near : Float, _far : Float)
{
    final a = (2 * _near) / (_right - _left);
    final b = (2 * _near) / (_top - _bottom);
    final c = (_right + _left) / (_right - _left);
    final d = (_top + _bottom) / (_top - _bottom);
    final e = - (_far + _near) / (_far - _near);
    final f = -1;
    final g = - (2 * _far * _near) / (_far - _near);

    return mat4(1);
}

// import uk.aidanlee.flurry.api.buffers.Float32BufferData;

// /**
//  * 4x4 matrix class for transformations and perspective.
//  */
// @:forward(subscribe, edit)
// abstract Matrix(Float32BufferData) from Float32BufferData to Float32BufferData
// {
//     public var m11 (get, set) : Float;
//     public var m21 (get, set) : Float;
//     public var m31 (get, set) : Float;
//     public var m41 (get, set) : Float;

//     public var m12 (get, set) : Float;
//     public var m22 (get, set) : Float;
//     public var m32 (get, set) : Float;
//     public var m42 (get, set) : Float;

//     public var m13 (get, set) : Float;
//     public var m23 (get, set) : Float;
//     public var m33 (get, set) : Float;
//     public var m43 (get, set) : Float;

//     public var m14 (get, set) : Float;
//     public var m24 (get, set) : Float;
//     public var m34 (get, set) : Float;
//     public var m44 (get, set) : Float;

//     inline function get_m11() : Float { return this[0]; }
//     inline function get_m21() : Float { return this[1]; }
//     inline function get_m31() : Float { return this[2]; }
//     inline function get_m41() : Float { return this[3]; }

//     inline function get_m12() : Float { return this[4]; }
//     inline function get_m22() : Float { return this[5]; }
//     inline function get_m32() : Float { return this[6]; }
//     inline function get_m42() : Float { return this[7]; }

//     inline function get_m13() : Float { return this[ 8]; }
//     inline function get_m23() : Float { return this[ 9]; }
//     inline function get_m33() : Float { return this[10]; }
//     inline function get_m43() : Float { return this[11]; }

//     inline function get_m14() : Float { return this[12]; }
//     inline function get_m24() : Float { return this[13]; }
//     inline function get_m34() : Float { return this[14]; }
//     inline function get_m44() : Float { return this[15]; }

//     inline function set_m11(_v : Float) : Float { this[0] = _v; return _v; }
//     inline function set_m21(_v : Float) : Float { this[1] = _v; return _v; }
//     inline function set_m31(_v : Float) : Float { this[2] = _v; return _v; }
//     inline function set_m41(_v : Float) : Float { this[3] = _v; return _v; }

//     inline function set_m12(_v : Float) : Float { this[4] = _v; return _v; }
//     inline function set_m22(_v : Float) : Float { this[5] = _v; return _v; }
//     inline function set_m32(_v : Float) : Float { this[6] = _v; return _v; }
//     inline function set_m42(_v : Float) : Float { this[7] = _v; return _v; }

//     inline function set_m13(_v : Float) : Float { this[ 8] = _v; return _v; }
//     inline function set_m23(_v : Float) : Float { this[ 9] = _v; return _v; }
//     inline function set_m33(_v : Float) : Float { this[10] = _v; return _v; }
//     inline function set_m43(_v : Float) : Float { this[11] = _v; return _v; }

//     inline function set_m14(_v : Float) : Float { this[12] = _v; return _v; }
//     inline function set_m24(_v : Float) : Float { this[13] = _v; return _v; }
//     inline function set_m34(_v : Float) : Float { this[14] = _v; return _v; }
//     inline function set_m44(_v : Float) : Float { this[15] = _v; return _v; }

//     @:arrayAccess public inline function arrayGet(_key : Int) : Float { return this[_key]; }
//     @:arrayAccess public inline function arraySet(_key : Int, _val : Float) { this[_key] = _val; }

//     /**
//      * Creates a 4x4 matrix.
//      * Defaults to an identity matrix.
//      * @param _n11 Value for column 1, row 1.
//      * @param _n12 Value for column 1, row 2.
//      * @param _n13 Value for column 1, row 3.
//      * @param _n14 Value for column 1, row 4.
//      * @param _n21 Value for column 2, row 1.
//      * @param _n22 Value for column 2, row 2.
//      * @param _n23 Value for column 2, row 3.
//      * @param _n24 Value for column 2, row 4.
//      * @param _n31 Value for column 3, row 1.
//      * @param _n32 Value for column 3, row 2.
//      * @param _n33 Value for column 3, row 3.
//      * @param _n34 Value for column 3, row 4.
//      * @param _n41 Value for column 4, row 1.
//      * @param _n42 Value for column 4, row 2.
//      * @param _n43 Value for column 4, row 3.
//      * @param _n44 Value for column 4, row 4.
//      */
//     public function new(
//         _n11 : Float = 1, _n12 : Float = 0, _n13 : Float = 0, _n14 : Float = 0,
//         _n21 : Float = 0, _n22 : Float = 1, _n23 : Float = 0, _n24 : Float = 0,
//         _n31 : Float = 0, _n32 : Float = 0, _n33 : Float = 1, _n34 : Float = 0,
//         _n41 : Float = 0, _n42 : Float = 0, _n43 : Float = 0, _n44 : Float = 1)
//     {
//         this = new Float32BufferData(16);

//         set(
//             _n11, _n12, _n13, _n14,
//             _n21, _n22, _n23, _n24,
//             _n31, _n32, _n33, _n34,
//             _n41, _n42, _n43, _n44
//         );
//     }

//     // #region Operator Overloading

//     @:op(A * B) public inline function opMultiply(_rhs : Matrix) : Matrix
//     {
//         return multiply(_rhs);
//     }

//     @:op(A * B) public inline function opMultiplyScalar(_rhs : Float) : Matrix
//     {
//         return multiplyScalar(_rhs);
//     }

//     // #endregion

//     // #region General

//     /**
//      * Set all elements in the matrix.
//      * Defaults to an identity matrix.
//      * @param _n11 Value for column 1, row 1.
//      * @param _n12 Value for column 1, row 2.
//      * @param _n13 Value for column 1, row 3.
//      * @param _n14 Value for column 1, row 4.
//      * @param _n21 Value for column 2, row 1.
//      * @param _n22 Value for column 2, row 2.
//      * @param _n23 Value for column 2, row 3.
//      * @param _n24 Value for column 2, row 4.
//      * @param _n31 Value for column 3, row 1.
//      * @param _n32 Value for column 3, row 2.
//      * @param _n33 Value for column 3, row 3.
//      * @param _n34 Value for column 3, row 4.
//      * @param _n41 Value for column 4, row 1.
//      * @param _n42 Value for column 4, row 2.
//      * @param _n43 Value for column 4, row 3.
//      * @param _n44 Value for column 4, row 4.
//      */
//     public function set(
//         _n11 : Float = 1, _n12 : Float = 0, _n13 : Float = 0, _n14 : Float = 0,
//         _n21 : Float = 0, _n22 : Float = 1, _n23 : Float = 0, _n24 : Float = 0,
//         _n31 : Float = 0, _n32 : Float = 0, _n33 : Float = 1, _n34 : Float = 0,
//         _n41 : Float = 0, _n42 : Float = 0, _n43 : Float = 0, _n44 : Float = 1) : Matrix
//     {
//         return this.edit(_data -> {
//             _data[0] = _n11; _data[4] = _n12; _data[ 8] = _n13; _data[12] = _n14;
//             _data[1] = _n21; _data[5] = _n22; _data[ 9] = _n23; _data[13] = _n24;
//             _data[2] = _n31; _data[6] = _n32; _data[10] = _n33; _data[14] = _n34;
//             _data[3] = _n41; _data[7] = _n42; _data[11] = _n43; _data[15] = _n44;
//         });
//     }

//     /**
//      * Copy another matrices elements into this ones.
//      * @param _m Matrix to copy.
//      */
//     public function copy(_m : Matrix) : Matrix
//     {
//         return set(
//             _m[0], _m[4], _m[ 8], _m[12],
//             _m[1], _m[5], _m[ 9], _m[13],
//             _m[2], _m[6], _m[10], _m[14],
//             _m[3], _m[7], _m[11], _m[15]
//         );
//     }

//     /**
//      * Creates a clone of this matrix.
//      * @return Matrix
//      */
//     public function clone() : Matrix
//     {
//         return new Matrix(
//             this[0], this[4], this[ 8], this[12],
//             this[1], this[5], this[ 9], this[13],
//             this[2], this[6], this[10], this[14],
//             this[3], this[7], this[11], this[15]
//         );
//     }

//     /**
//      * Sets the matrix elements from an array.
//      * @param _a Array of 16 floats.
//      * @return Matrix
//      */
//     public function fromArray(_a : Array<Float>) : Matrix
//     {
//         if (_a.length != 16) return this;

//         return this.edit(_data -> {
//             _data[ 0] = _a[ 0]; _data[ 1] = _a[ 1]; _data[ 2] = _a[ 2]; _data[ 3] = _a[ 3];
//             _data[ 4] = _a[ 4]; _data[ 5] = _a[ 5]; _data[ 6] = _a[ 6]; _data[ 7] = _a[ 7];
//             _data[ 8] = _a[ 8]; _data[ 9] = _a[ 9]; _data[10] = _a[10]; _data[11] = _a[11];
//             _data[12] = _a[12]; _data[13] = _a[13]; _data[14] = _a[14]; _data[15] = _a[15];
//         });
//     }

//     /**
//      * Returns a float array of the matrix elements.
//      * @return Array<Float>
//      */
//     public function toArray() : Array<Float>
//     {
//         return [
//             this[ 0], this[ 1], this[ 2], this[ 3],
//             this[ 4], this[ 5], this[ 6], this[ 7],
//             this[ 8], this[ 9], this[10], this[11],
//             this[12], this[13], this[14], this[15]
//         ];
//     }

//     /**
//      * Returns a string representation of this matrix.
//      * @return String
//      */
//     public function toString() : String
//     {
//         return '{ 11:${Maths.fixed(this[0], 3)}, 12:${Maths.fixed(this[4], 3)}, 13:${Maths.fixed(this[ 8], 3)}, 14: ${Maths.fixed(this[12], 3)} }, { 21:${Maths.fixed(this[1], 3)}, 22:${Maths.fixed(this[5], 3)}, 23:${Maths.fixed(this[ 9], 3)}, 24: ${Maths.fixed(this[13], 3)} }, { 31:${Maths.fixed(this[2], 3)}, 32:${Maths.fixed(this[6], 3)}, 33:${Maths.fixed(this[10], 3)}, 34: ${Maths.fixed(this[14], 3)} }, { 41:${Maths.fixed(this[3], 3)}, 42:${Maths.fixed(this[7], 3)}, 43:${Maths.fixed(this[11], 3)}, 44: ${Maths.fixed(this[15], 3)} }';
//     }

//     public function invert() : Matrix
//     {
//         return this.edit(_data -> {
//             final me = clone();

//             final n11 = me[0], n12 = me[4], n13 = me[8],  n14 = me[12];
//             final n21 = me[1], n22 = me[5], n23 = me[9],  n24 = me[13];
//             final n31 = me[2], n32 = me[6], n33 = me[10], n34 = me[14];
//             final n41 = me[3], n42 = me[7], n43 = me[11], n44 = me[15];
    
//             _data[ 0] = (n23 * n34 * n42) - (n24 * n33 * n42) + (n24 * n32 * n43) - (n22 * n34 * n43) - (n23 * n32 * n44) + (n22 * n33 * n44);
//             _data[ 4] = (n14 * n33 * n42) - (n13 * n34 * n42) - (n14 * n32 * n43) + (n12 * n34 * n43) + (n13 * n32 * n44) - (n12 * n33 * n44);
//             _data[ 8] = (n13 * n24 * n42) - (n14 * n23 * n42) + (n14 * n22 * n43) - (n12 * n24 * n43) - (n13 * n22 * n44) + (n12 * n23 * n44);
//             _data[12] = (n14 * n23 * n32) - (n13 * n24 * n32) - (n14 * n22 * n33) + (n12 * n24 * n33) + (n13 * n22 * n34) - (n12 * n23 * n34);
//             _data[ 1] = (n24 * n33 * n41) - (n23 * n34 * n41) - (n24 * n31 * n43) + (n21 * n34 * n43) + (n23 * n31 * n44) - (n21 * n33 * n44);
//             _data[ 5] = (n13 * n34 * n41) - (n14 * n33 * n41) + (n14 * n31 * n43) - (n11 * n34 * n43) - (n13 * n31 * n44) + (n11 * n33 * n44);
//             _data[ 9] = (n14 * n23 * n41) - (n13 * n24 * n41) - (n14 * n21 * n43) + (n11 * n24 * n43) + (n13 * n21 * n44) - (n11 * n23 * n44);
//             _data[13] = (n13 * n24 * n31) - (n14 * n23 * n31) + (n14 * n21 * n33) - (n11 * n24 * n33) - (n13 * n21 * n34) + (n11 * n23 * n34);
//             _data[ 2] = (n22 * n34 * n41) - (n24 * n32 * n41) + (n24 * n31 * n42) - (n21 * n34 * n42) - (n22 * n31 * n44) + (n21 * n32 * n44);
//             _data[ 6] = (n14 * n32 * n41) - (n12 * n34 * n41) - (n14 * n31 * n42) + (n11 * n34 * n42) + (n12 * n31 * n44) - (n11 * n32 * n44);
//             _data[10] = (n12 * n24 * n41) - (n14 * n22 * n41) + (n14 * n21 * n42) - (n11 * n24 * n42) - (n12 * n21 * n44) + (n11 * n22 * n44);
//             _data[14] = (n14 * n22 * n31) - (n12 * n24 * n31) - (n14 * n21 * n32) + (n11 * n24 * n32) + (n12 * n21 * n34) - (n11 * n22 * n34);
//             _data[ 3] = (n23 * n32 * n41) - (n22 * n33 * n41) - (n23 * n31 * n42) + (n21 * n33 * n42) + (n22 * n31 * n43) - (n21 * n32 * n43);
//             _data[ 7] = (n12 * n33 * n41) - (n13 * n32 * n41) + (n13 * n31 * n42) - (n11 * n33 * n42) - (n12 * n31 * n43) + (n11 * n32 * n43);
//             _data[11] = (n13 * n22 * n41) - (n12 * n23 * n41) - (n13 * n21 * n42) + (n11 * n23 * n42) + (n12 * n21 * n43) - (n11 * n22 * n43);
//             _data[15] = (n12 * n23 * n31) - (n13 * n22 * n31) + (n13 * n21 * n32) - (n11 * n23 * n32) - (n12 * n21 * n33) + (n11 * n22 * n33);
    
//             final det = me[ 0 ] * this[ 0 ] + me[ 1 ] * this[ 4 ] + me[ 2 ] * this[ 8 ] + me[ 3 ] * this[ 12 ];
    
//             if (det == 0)
//             {
//                 identity();
//             }

//             multiplyScalar( 1 / det );
//         });
//     }

//     // #endregion

//     // #region Maths

//     /**
//      * Calculates the determinant of this matrix.
//      * @return Float
//      */
//     public function determinant() : Float
//     {
//         var n11 = this[0], n12 = this[4], n13 = this[ 8], n14 = this[12];
//         var n21 = this[1], n22 = this[5], n23 = this[ 9], n24 = this[13];
//         var n31 = this[2], n32 = this[6], n33 = this[10], n34 = this[14];
//         var n41 = this[3], n42 = this[7], n43 = this[11], n44 = this[15];

//         return (
//             n41 * (
//                  n14 * n23 * n32
//                 -n13 * n24 * n32
//                 -n14 * n22 * n33
//                 +n12 * n24 * n33
//                 +n13 * n22 * n34
//                 -n12 * n23 * n34
//             ) +
//             n42 * (
//                  n11 * n23 * n34
//                 -n11 * n24 * n33
//                 +n14 * n21 * n33
//                 -n13 * n21 * n34
//                 +n13 * n24 * n31
//                 -n14 * n23 * n31
//             ) +
//             n43 * (
//                  n11 * n24 * n32
//                 -n11 * n22 * n34
//                 -n14 * n21 * n32
//                 +n12 * n21 * n34
//                 +n14 * n22 * n31
//                 -n12 * n24 * n31
//             ) +
//             n44 * (
//                 -n13 * n22 * n31
//                 -n11 * n23 * n32
//                 +n11 * n22 * n33
//                 +n13 * n21 * n32
//                 -n12 * n21 * n33
//                 +n12 * n23 * n31
//             )
//         );
//     }

//     /**
//      * Transpose this matrix.
//      * @return Matrix
//      */
//     public function transpose() : Matrix
//     {
//         return this.edit(_data -> {
//             var tmp = 0.0;

//             tmp = _data[1]; _data[1] = _data[4]; _data[4] = tmp;
//             tmp = _data[2]; _data[2] = _data[8]; _data[8] = tmp;
//             tmp = _data[6]; _data[6] = _data[9]; _data[9] = tmp;
    
//             tmp = _data[ 3]; _data[ 3] = _data[12]; _data[12] = tmp;
//             tmp = _data[ 7]; _data[ 7] = _data[13]; _data[13] = tmp;
//             tmp = _data[11]; _data[11] = _data[14]; _data[14] = tmp;
//         });
//     }

//     /**
//      * Scale this matrix by a vector.
//      * @param _v Scaling vector.
//      */
//     public function scale(_v : Vector3) : Matrix
//     {
//         return this.edit(_data -> {
//             final x = _v.x;
//             final y = _v.y;
//             final z = _v.z;

//             _data[0] *= x; _data[4] *= y; _data[8]  *= z;
//             _data[1] *= x; _data[5] *= y; _data[9]  *= z;
//             _data[2] *= x; _data[6] *= y; _data[10] *= z;
//             _data[3] *= x; _data[7] *= y; _data[11] *= z;
//         });
//     }

//     /**
//      * Compose a matrix from the provided data.
//      * @param _position   Position for the matrix.
//      * @param _quaternion Rotation for the matrix.
//      * @param _scale      Scale for the matrix.
//      */
//     public function compose(_position : Vector3, _quaternion : Quaternion, _scale : Vector3) : Matrix
//     {
//         makeRotationFromQuaternion(_quaternion);
//         scale(_scale);
//         setPosition(_position);

//         return this;
//     }

//     /**
//      * Decompose a matrix into its three parts.
//      * @param _position   Optional vector to store the position in.
//      * @param _quaternion Optional quaternion to store the rotation in.
//      * @param _scale      Optional vector to store the scale in.
//      */
//     public function decompose(_position : Vector3, _quaternion : Quaternion, _scale : Vector3) : Matrix
//     {
//         var ax_x = this[0]; var ax_y = this[1]; var ax_z = this[ 2];
//         var ay_x = this[4]; var ay_y = this[5]; var ay_z = this[ 6];
//         var az_x = this[8]; var az_y = this[9]; var az_z = this[10];

//         var ax_length = Maths.sqrt(ax_x * ax_x + ax_y * ax_y + ax_z * ax_z);
//         var ay_length = Maths.sqrt(ay_x * ay_x + ay_y * ay_y + ay_z * ay_z);
//         var az_length = Maths.sqrt(az_x * az_x + az_y * az_y + az_z * az_z);

//         // Get the position from the matrix.
//         _position.set(this[12], this[13], this[14]);

//         // Get the scale from the matrix
//         _scale.set(ax_length, ay_length, az_length);

//         var me = clone();
//         me[0] /= ax_length;
//         me[1] /= ax_length;
//         me[2] /= ax_length;

//         me[4] /= ax_length;
//         me[5] /= ax_length;
//         me[6] /= ax_length;

//         me[ 8] /= ax_length;
//         me[ 9] /= ax_length;
//         me[10] /= ax_length;

//         _quaternion.setFromRotationMatrix(me);

//         return this;
//     }

//     // #endregion

//     // #region Operations

//     /**
//      * Multiply this matrix by another.
//      * @param _m Matrix to multiply with.
//      */
//     public function multiply(_m : Matrix) : Matrix
//     {
//         return this.edit(_data -> {
//             final a11 = _data[0], a12 = _data[4], a13 = _data[8],  a14 = _data[12];
//             final a21 = _data[1], a22 = _data[5], a23 = _data[9],  a24 = _data[13];
//             final a31 = _data[2], a32 = _data[6], a33 = _data[10], a34 = _data[14];
//             final a41 = _data[3], a42 = _data[7], a43 = _data[11], a44 = _data[15];
    
//             final b11 = _m[0], b12 = _m[4], b13 = _m[8],  b14 = _m[12];
//             final b21 = _m[1], b22 = _m[5], b23 = _m[9],  b24 = _m[13];
//             final b31 = _m[2], b32 = _m[6], b33 = _m[10], b34 = _m[14];
//             final b41 = _m[3], b42 = _m[7], b43 = _m[11], b44 = _m[15];
    
//             _data[ 0] = a11 * b11 + a12 * b21 + a13 * b31 + a14 * b41;
//             _data[ 4] = a11 * b12 + a12 * b22 + a13 * b32 + a14 * b42;
//             _data[ 8] = a11 * b13 + a12 * b23 + a13 * b33 + a14 * b43;
//             _data[12] = a11 * b14 + a12 * b24 + a13 * b34 + a14 * b44;
    
//             _data[ 1] = a21 * b11 + a22 * b21 + a23 * b31 + a24 * b41;
//             _data[ 5] = a21 * b12 + a22 * b22 + a23 * b32 + a24 * b42;
//             _data[ 9] = a21 * b13 + a22 * b23 + a23 * b33 + a24 * b43;
//             _data[13] = a21 * b14 + a22 * b24 + a23 * b34 + a24 * b44;
    
//             _data[ 2] = a31 * b11 + a32 * b21 + a33 * b31 + a34 * b41;
//             _data[ 6] = a31 * b12 + a32 * b22 + a33 * b32 + a34 * b42;
//             _data[10] = a31 * b13 + a32 * b23 + a33 * b33 + a34 * b43;
//             _data[14] = a31 * b14 + a32 * b24 + a33 * b34 + a34 * b44;
    
//             _data[ 3] = a41 * b11 + a42 * b21 + a43 * b31 + a44 * b41;
//             _data[ 7] = a41 * b12 + a42 * b22 + a43 * b32 + a44 * b42;
//             _data[11] = a41 * b13 + a42 * b23 + a43 * b33 + a44 * b43;
//             _data[15] = a41 * b14 + a42 * b24 + a43 * b34 + a44 * b44;
//         });
//     }

//     /**
//      * Multiply two matrices together and store the result in this matrix.
//      * @param _a Matrix A.
//      * @param _b Matrix B.
//      */
//     public function multiplyMatrices(_a : Matrix, _b : Matrix) : Matrix
//     {
//         return this.edit(_data -> {
//             final a11 = _a[0], a12 = _a[4], a13 = _a[8],  a14 = _a[12];
//             final a21 = _a[1], a22 = _a[5], a23 = _a[9],  a24 = _a[13];
//             final a31 = _a[2], a32 = _a[6], a33 = _a[10], a34 = _a[14];
//             final a41 = _a[3], a42 = _a[7], a43 = _a[11], a44 = _a[15];
    
//             final b11 = _b[0], b12 = _b[4], b13 = _b[8],  b14 = _b[12];
//             final b21 = _b[1], b22 = _b[5], b23 = _b[9],  b24 = _b[13];
//             final b31 = _b[2], b32 = _b[6], b33 = _b[10], b34 = _b[14];
//             final b41 = _b[3], b42 = _b[7], b43 = _b[11], b44 = _b[15];
    
//             _data[ 0] = a11 * b11 + a12 * b21 + a13 * b31 + a14 * b41;
//             _data[ 4] = a11 * b12 + a12 * b22 + a13 * b32 + a14 * b42;
//             _data[ 8] = a11 * b13 + a12 * b23 + a13 * b33 + a14 * b43;
//             _data[12] = a11 * b14 + a12 * b24 + a13 * b34 + a14 * b44;
    
//             _data[ 1] = a21 * b11 + a22 * b21 + a23 * b31 + a24 * b41;
//             _data[ 5] = a21 * b12 + a22 * b22 + a23 * b32 + a24 * b42;
//             _data[ 9] = a21 * b13 + a22 * b23 + a23 * b33 + a24 * b43;
//             _data[13] = a21 * b14 + a22 * b24 + a23 * b34 + a24 * b44;
    
//             _data[ 2] = a31 * b11 + a32 * b21 + a33 * b31 + a34 * b41;
//             _data[ 6] = a31 * b12 + a32 * b22 + a33 * b32 + a34 * b42;
//             _data[10] = a31 * b13 + a32 * b23 + a33 * b33 + a34 * b43;
//             _data[14] = a31 * b14 + a32 * b24 + a33 * b34 + a34 * b44;
    
//             _data[ 3] = a41 * b11 + a42 * b21 + a43 * b31 + a44 * b41;
//             _data[ 7] = a41 * b12 + a42 * b22 + a43 * b32 + a44 * b42;
//             _data[11] = a41 * b13 + a42 * b23 + a43 * b33 + a44 * b43;
//             _data[15] = a41 * b14 + a42 * b24 + a43 * b34 + a44 * b44;
//         });
//     }

//     /**
//      * Multiply this matrix by a scalar value.
//      * @param _v Scalar value.
//      */
//     public function multiplyScalar(_v : Float) : Matrix
//     {
//         return this.edit(_data -> {
//             _data[0] *= _v; _data[4] *= _v; _data[ 8] *= _v; _data[12] *= _v;
//             _data[1] *= _v; _data[5] *= _v; _data[ 9] *= _v; _data[13] *= _v;
//             _data[2] *= _v; _data[6] *= _v; _data[10] *= _v; _data[14] *= _v;
//             _data[3] *= _v; _data[7] *= _v; _data[11] *= _v; _data[15] *= _v;
//         });
//     }

//     public function up() : Vector3
//     {
//         return new Vector3(this[4], this[5], this[6]);
//     }

//     public function down() : Vector3
//     {
//         return up().invert();
//     }

//     public function left() : Vector3
//     {
//         return right().invert();
//     }

//     public function right() : Vector3
//     {
//         return new Vector3(this[0], this[1], this[2]);
//     }

//     public function forward() : Vector3
//     {
//         return backwards().invert();
//     }

//     public function backwards() : Vector3
//     {
//         return new Vector3(this[8], this[9], this[10]);
//     }

//     // #endregion

//     // #region Transformations

//     /**
//      * Return the position from this matrix into a vector.
//      * @return Vector
//      */
//     public function getPosition() : Vector3
//     {
//         return new Vector3(this[12], this[13], this[14]);
//     }

//     /**
//      * Set the position in the matrix based on a vector.
//      * @param _v Position vector.
//      */
//     public function setPosition(_v : Vector3) : Matrix
//     {
//         return this.edit(_data -> {
//             _data[12] = _v.x;
//             _data[13] = _v.y;
//             _data[14] = _v.z;
//         });
//     }

//     /**
//      * Sets this matrix to look at a point from a position.
//      * @param _eye    The eye position.
//      * @param _target The target position.
//      * @param _up     Up vector.
//      */
//     public function lookAt(_eye : Vector3, _target : Vector3, _up : Vector3) : Matrix
//     {
//         return this.edit(_data -> {
//             var z = Vector3.Subtract(_target, _eye).normalize();
//             if (z.length == 0)
//             {
//                 z.z = 1;
//             }

//             var x = Vector3.Cross(_up, z).normalize();
//             if (x.length == 0)
//             {
//                 z.x += 0.0001;
//                 z = Vector3.Cross(_up, z).normalize();
//             }

//             var y = Vector3.Cross(z, x);

//             _data[0] = x.x; _data[4] = y.x; _data[ 8] = z.x;
//             _data[1] = x.y; _data[5] = y.y; _data[ 9] = z.y;
//             _data[2] = x.z; _data[6] = y.z; _data[10] = z.z;
//         });
//     }

//     /**
//      * Sets this matrix to an identity matrix.
//      */
//     public function identity() : Matrix
//     {
//         return set(
//             1, 0, 0, 0,
//             0, 1, 0, 0,
//             0, 0, 1, 0,
//             0, 0, 0, 1
//         );
//     }

//     /**
//      * Makes this matrix represents a 2D space.
//      * @param _x        x position.
//      * @param _y        y position.
//      * @param _scale    scale value. (default 1)
//      * @param _rotation rotation value. (default 0)
//      */
//     public function make2D(_x : Float, _y : Float, _scale : Float = 1, _rotation : Float = 0) : Matrix
//     {
//         final theta = Maths.toRadians(_rotation);
//         final c     = Maths.cos(theta);
//         final s     = Maths.cos(theta);

//         return set(
//              c * _scale, s * _scale,  0, _x,
//             -s * _scale, c * _scale,  0, _y,
//                       0,          0,  1,  0,
//                       0,          0,  0,  1
//         );
//     }

//     /**
//      * Translate this matrix to the provided position.
//      * @param _x x position.
//      * @param _y y position.
//      * @param _z z position.
//      */
//     public function makeTranslation(_x : Float, _y : Float, _z : Float) : Matrix
//     {
//         return set(
//             1, 0, 0, _x,
//             0, 1, 0, _y,
//             0, 0, 1, _z,
//             0, 0, 0, 1
//         );
//     }

//     /**
//      * Set this matrix to a rotation.
//      * @param _axis  Vector containing the x, y, and z axis.
//      * @param _angle Angle value.
//      */
//     public function makeRotationAxis(_axis : Vector3, _angle : Float) : Matrix
//     {
//         final c = Maths.cos(_angle);
//         final s = Maths.sin(_angle);
//         final t = 1 - c;

//         final ax = _axis.x;
//         final ay = _axis.y;
//         final az = _axis.z;

//         final tx = t * ax;
//         final ty = t * ay;

//         return set(
//             (tx * ax + c)     ,   (tx * ay - s * az),   (tx * az + s * ay),   0,
//             (tx * ay + s * az),   (ty * ay + c)     ,   (ty * az - s * ax),   0,
//             (tx * az - s * ay),   (ty * az + s * ax),   (t * az * az + c) ,   0,
//             0, 0, 0, 1
//         );
//     }

//     /**
//      * Make a rotation around the x axis.
//      * @param _theta Angle radians.
//      */
//     public function makeRotationX(_theta : Float) : Matrix
//     {
//         final c = Maths.cos(_theta);
//         final s = Maths.sin(_theta);

//         return set(
//             1,  0,  0,  0,
//             0,  c, -s,  0,
//             0,  s,  c,  0,
//             0,  0,  0,  1
//         );
//     }

//     /**
//      * Make a rotation around the y axis.
//      * @param _theta Angle radians.
//      */
//     public function makeRotationY(_theta : Float) : Matrix
//     {
//         final c = Maths.cos(_theta);
//         final s = Maths.sin(_theta);

//         return set(
//             c,  0,  s,  0,
//             0,  1,  0,  0,
//            -s,  0,  c,  0,
//             0,  0,  0,  1
//         );
//     }

//     /**
//      * Make a rotation around the z axis.
//      * @param _theta Angle radians.
//      */
//     public function makeRotationZ(_theta : Float) : Matrix
//     {
//         final c = Maths.cos(_theta);
//         final s = Maths.sin(_theta);

//         return set(
//             c, -s,  0,  0,
//             s,  c,  0,  0,
//             0,  0,  1,  0,
//             0,  0,  0,  1
//         );
//     }

//     /**
//      * Set the scale of this matrix.
//      * @param _x x scale.
//      * @param _y y scale.
//      * @param _z z scale.
//      */
//     public function makeScale(_x : Float, _y : Float, _z : Float) : Matrix
//     {
//         return set(
//             _x,  0,  0,  0,
//              0, _y,  0,  0,
//              0,  0, _z,  0,
//              0,  0,  0,  1
//         );
//     }

//     /**
//      * Make a rotation from an euler angle.
//      * @param _v     Vector containing the euler angle.
//      * @param _order Component order.
//      * @return Matrix
//      */
//     public function makeRotationFromEuler(_v : Vector3, _order : ComponentOrder = XYZ) : Matrix
//     {
//         return this.edit(_data -> {
//             final x = _v.x;
//             final y = _v.y;
//             final z = _v.z;
    
//             final a = Maths.cos(x);
//             final c = Maths.cos(y);
//             final e = Maths.cos(z);
    
//             final b = Maths.sin(x);
//             final d = Maths.sin(y);
//             final f = Maths.sin(z);
    
//             switch (_order)
//             {
//                 case XYZ:
//                     final ae = a * e, af = a * f, be = b * e, bf = b * f;
    
//                     _data[ 0] = c * e;
//                     _data[ 4] = -c * f;
//                     _data[ 8] = d;
    
//                     _data[ 1] = af + be * d;
//                     _data[ 5] = ae - bf * d;
//                     _data[ 9] = -b * c;
    
//                     _data[ 2] = bf - ae * d;
//                     _data[ 6] = be + af * d;
//                     _data[10] = a * c;
//                 case YXZ:
//                     final ce = c * e, cf = c * f, de = d * e, df = d * f;
    
//                     _data[ 0] = ce + df * b;
//                     _data[ 4] = de * b - cf;
//                     _data[ 8] = a * d;
    
//                     _data[ 1] = a * f;
//                     _data[ 5] = a * e;
//                     _data[ 9] = -b;
    
//                     _data[ 2] = cf * b - de;
//                     _data[ 6] = df + ce * b;
//                     _data[10] = a * c;
//                 case ZXY:
//                     final ce = c * e, cf = c * f, de = d * e, df = d * f;
    
//                     _data[ 0] = ce - df * b;
//                     _data[ 4] = -a * f;
//                     _data[ 8] = de + cf * b;
    
//                     _data[ 1] = cf + de * b;
//                     _data[ 5] = a * e;
//                     _data[ 9] = df - ce * b;
    
//                     _data[ 2] = -a * d;
//                     _data[ 6] = b;
//                     _data[10] = a * c;
//                 case ZYX:
//                     final ae = a * e, af = a * f, be = b * e, bf = b * f;
    
//                     _data[ 0] = c * e;
//                     _data[ 4] = be * d - af;
//                     _data[ 8] = ae * d + bf;
    
//                     _data[ 1] = c * f;
//                     _data[ 5] = bf * d + ae;
//                     _data[ 9] = af * d - be;
    
//                     _data[ 2] = -d;
//                     _data[ 6] = b * c;
//                     _data[10] = a * c;
//                 case YZX:
//                     final ac = a * c, ad = a * d, bc = b * c, bd = b * d;
    
//                     _data[ 0] = c * e;
//                     _data[ 4] = bd - ac * f;
//                     _data[ 8] = bc * f + ad;
    
//                     _data[ 1] = f;
//                     _data[ 5] = a * e;
//                     _data[ 9] = -b * e;
    
//                     _data[ 2] = -d * e;
//                     _data[ 6] = ad * f + bc;
//                     _data[10] = ac - bd * f;
//                 case XZY:
//                     final ac = a * c, ad = a * d, bc = b * c, bd = b * d;
    
//                     _data[ 0] = c * e;
//                     _data[ 4] = -f;
//                     _data[ 8] = d * e;
    
//                     _data[ 1] = ac * f + bd;
//                     _data[ 5] = a * e;
//                     _data[ 9] = ad * f - bc;
    
//                     _data[ 2] = bc * f - ad;
//                     _data[ 6] = b * e;
//                     _data[10] = bd * f + ac;
//             }
    
//             _data[ 3] = 0;
//             _data[ 7] = 0;
//             _data[11] = 0;
    
//             _data[12] = 0;
//             _data[13] = 0;
//             _data[14] = 0;
//             _data[15] = 1;
//         });
//     }

//     /**
//      * Creates a rotation matrix from a quaternion.
//      * @param _q Quaternion containing the rotation.
//      */
//     public function makeRotationFromQuaternion(_q : Quaternion) : Matrix
//     {
//         return this.edit(_data -> {
//             final x2 = _q.x + _q.x, y2 = _q.y + _q.y, z2 = _q.z + _q.z;
//             final xx = _q.x * x2,   xy = _q.x * y2,   xz = _q.x *  z2;
//             final yy = _q.y * y2,   yz = _q.y * z2,   zz = _q.z *  z2;
//             final wx = _q.w * x2,   wy = _q.w * y2,   wz = _q.w *  z2;
    
//             _data[0] = 1 - ( yy + zz );
//             _data[4] = xy - wz;
//             _data[8] = xz + wy;
    
//             _data[1] = xy + wz;
//             _data[5] = 1 - ( xx + zz );
//             _data[9] = yz - wx;
    
//             _data[ 2] = xz - wy;
//             _data[ 6] = yz + wx;
//             _data[10] = 1 - ( xx + yy );
    
//             // last column
//             _data[ 3] = 0;
//             _data[ 7] = 0;
//             _data[11] = 0;
    
//             // bottom row
//             _data[12] = 0;
//             _data[13] = 0;
//             _data[14] = 0;
//             _data[15] = 1;
//         });
//     }

//     /**
//      * Create a matrix representing a frustum.
//      * @param _left   - 
//      * @param _right  - 
//      * @param _bottom - 
//      * @param _top    - 
//      * @param _near   - 
//      * @param _far    - 
//      * @return Matrix
//      */
//     public function makeHomogeneousFrustum(_left : Float, _right : Float, _bottom : Float, _top : Float, _near : Float, _far : Float) : Matrix
//     {
//         return this.edit(_data -> {
//             final a = (2 * _near) / (_right - _left);
//             final b = (2 * _near) / (_top - _bottom);
//             final c = (_right + _left) / (_right - _left);
//             final d = (_top + _bottom) / (_top - _bottom);
//             final e = - (_far + _near) / (_far - _near);
//             final f = -1;
//             final g = - (2 * _far * _near) / (_far - _near);
    
//             _data[0] = a;   _data[4] = 0;   _data[ 8] = c;   _data[12] = 0;
//             _data[1] = 0;   _data[5] = b;   _data[ 9] = d;   _data[13] = 0;
//             _data[2] = 0;   _data[6] = 0;   _data[10] = e;   _data[14] = g;
//             _data[3] = 0;   _data[7] = 0;   _data[11] = f;   _data[15] = 0;
//         });
//     }

//     /**
//      * Create a matrix representing a frustum.
//      * @param _left   - 
//      * @param _right  - 
//      * @param _bottom - 
//      * @param _top    - 
//      * @param _near   - 
//      * @param _far    - 
//      * @return Matrix
//      */
//     public function makeHeterogeneousFrustum(_left : Float, _right : Float, _bottom : Float, _top : Float, _near : Float, _far : Float) : Matrix
//     {
//         return this.edit(_data -> {
//             final a = (2 * _near) / (_right - _left);
//             final b = (2 * _near) / (_top - _bottom);
//             final c = (_right + _left) / (_right - _left);
//             final d = (_top + _bottom) / (_top - _bottom);
//             final e = -_far / (_far - _near);
//             final f = -1;
//             final g = - (_far * _near) / (_far - _near);
            
//             _data[0] = a;   _data[4] = 0;   _data[ 8] = c;   _data[12] = 0;
//             _data[1] = 0;   _data[5] = b;   _data[ 9] = d;   _data[13] = 0;
//             _data[2] = 0;   _data[6] = 0;   _data[10] = e;   _data[14] = g;
//             _data[3] = 0;   _data[7] = 0;   _data[11] = f;   _data[15] = 0;
//         });
//     }

//     /**
//      * Create a perspective matrix.
//      * @param _fov    Vertical FOV in degrees.
//      * @param _aspect Aspect ratio.
//      * @param _near   Near clipping distance.
//      * @param _far    Far clipping distance.
//      */
//     public function makeHomogeneousPerspective(_fov : Float, _aspect : Float, _near : Float, _far : Float) : Matrix
//     {
//         return this.edit(_data -> {
//             final tanHalfFov = Maths.tan(_fov / 2);
//             final a = 1 / (_aspect * tanHalfFov);
//             final b = 1 / tanHalfFov;
//             final c = - (_far + _near) / (_far - _near);
//             final d = - 1;
//             final e = - (2 * _far * _near) / (_far - _near);
    
//             _data[0] = a;   _data[4] = 0;   _data[ 8] = 0;   _data[12] = 0;
//             _data[1] = 0;   _data[5] = b;   _data[ 9] = 0;   _data[13] = 0;
//             _data[2] = 0;   _data[6] = 0;   _data[10] = c;   _data[14] = e;
//             _data[3] = 0;   _data[7] = 0;   _data[11] = d;   _data[15] = 0;
//         });
//     }

//     /**
//      * Create a perspective matrix.
//      * @param _fov    - Vertical FOV of this perspective.
//      * @param _aspect - Aspect ratio.
//      * @param _near   - near clipping.
//      * @param _far    - far clipping.
//      */
//     public function makeHeterogeneousPerspective(_fov : Float, _aspect : Float, _near : Float, _far : Float) : Matrix
//     {
//         return this.edit(_data -> {
//             final tanHalfFov = Maths.tan(_fov / 2);
//             final a = 1 / (_aspect * tanHalfFov);
//             final b = 1 / tanHalfFov;
//             final c = _far / (_near - _far);
//             final d = - 1;
//             final e = - (_far * _near) / (_far - _near);
    
//             _data[0] = a;   _data[4] = 0;   _data[ 8] = 0;   _data[12] = 0;
//             _data[1] = 0;   _data[5] = b;   _data[ 9] = 0;   _data[13] = 0;
//             _data[2] = 0;   _data[6] = 0;   _data[10] = c;   _data[14] = e;
//             _data[3] = 0;   _data[7] = 0;   _data[11] = d;   _data[15] = 0;
//         });
//     }

//     /**
//      * Creates an orthographic projection matrix.
//      * @param _left - 
//      * @param _right - 
//      * @param _top - 
//      * @param _bottom - 
//      * @param _near - 
//      * @param _far - 
//      * @return Matrix
//      */
//     public function makeHomogeneousOrthographic(_left : Float, _right : Float, _top : Float, _bottom : Float, _near : Float, _far : Float) : Matrix
//     {
//         return this.edit(_data -> {
//             final a =  2 / (_right - _left);
//             final b =  2 / (_top - _bottom);
//             final c = -2 / (_far - _near);
    
//             _data[0] = a;      _data[4] = 0;      _data[ 8] = 0;       _data[12] = - (_right + _left) / (_right - _left);
//             _data[1] = 0;      _data[5] = b;      _data[ 9] = 0;       _data[13] = - (_top + _bottom) / (_top - _bottom);
//             _data[2] = 0;      _data[6] = 0;      _data[10] = c;       _data[14] = - (_far + _near) / (_far - _near);
//             _data[3] = 0;      _data[7] = 0;      _data[11] = 0;       _data[15] = 1;
//         });
//     }

//     /**
//      * Creates an orthographic projection matrix.
//      * @param _left - 
//      * @param _right - 
//      * @param _top - 
//      * @param _bottom - 
//      * @param _near - 
//      * @param _far - 
//      * @return Matrix
//      */
//     public function makeHeterogeneousOrthographic(_left : Float, _right : Float, _top : Float, _bottom : Float, _near : Float, _far : Float) : Matrix
//     {
//         return this.edit(_data -> {
//             final a =  2 / (_right - _left);
//             final b =  2 / (_top - _bottom);
//             final c = -1 / (_far - _near);
    
//             _data[0] = a;      _data[4] = 0;      _data[ 8] = 0;       _data[12] = - (_right + _left) / (_right - _left);
//             _data[1] = 0;      _data[5] = b;      _data[ 9] = 0;       _data[13] = - (_top + _bottom) / (_top - _bottom);
//             _data[2] = 0;      _data[6] = 0;      _data[10] = c;       _data[14] = - _near / (_far - _near);
//             _data[3] = 0;      _data[7] = 0;      _data[11] = 0;       _data[15] = 1;
//         });
//     }

//     // #endregion
// }
