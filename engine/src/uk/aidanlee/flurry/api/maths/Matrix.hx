package uk.aidanlee.flurry.api.maths;

import snow.api.buffers.Float32Array;

/**
 * 4x4 matrix class for transformations and perspective.
 */
abstract Matrix(Float32Array) from Float32Array to Float32Array
{
    public var M11 (get, set) : Float;
    public var M21 (get, set) : Float;
    public var M31 (get, set) : Float;
    public var M41 (get, set) : Float;

    public var M12 (get, set) : Float;
    public var M22 (get, set) : Float;
    public var M32 (get, set) : Float;
    public var M42 (get, set) : Float;

    public var M13 (get, set) : Float;
    public var M23 (get, set) : Float;
    public var M33 (get, set) : Float;
    public var M43 (get, set) : Float;

    public var M14 (get, set) : Float;
    public var M24 (get, set) : Float;
    public var M34 (get, set) : Float;
    public var M44 (get, set) : Float;

    inline function get_M11() : Float { return this[0]; }
    inline function get_M21() : Float { return this[1]; }
    inline function get_M31() : Float { return this[2]; }
    inline function get_M41() : Float { return this[3]; }

    inline function get_M12() : Float { return this[4]; }
    inline function get_M22() : Float { return this[5]; }
    inline function get_M32() : Float { return this[6]; }
    inline function get_M42() : Float { return this[7]; }

    inline function get_M13() : Float { return this[ 8]; }
    inline function get_M23() : Float { return this[ 9]; }
    inline function get_M33() : Float { return this[10]; }
    inline function get_M43() : Float { return this[11]; }

    inline function get_M14() : Float { return this[12]; }
    inline function get_M24() : Float { return this[13]; }
    inline function get_M34() : Float { return this[14]; }
    inline function get_M44() : Float { return this[15]; }

    inline function set_M11(_v : Float) : Float { this[0] = _v; return _v; }
    inline function set_M21(_v : Float) : Float { this[1] = _v; return _v; }
    inline function set_M31(_v : Float) : Float { this[2] = _v; return _v; }
    inline function set_M41(_v : Float) : Float { this[3] = _v; return _v; }

    inline function set_M12(_v : Float) : Float { this[4] = _v; return _v; }
    inline function set_M22(_v : Float) : Float { this[5] = _v; return _v; }
    inline function set_M32(_v : Float) : Float { this[6] = _v; return _v; }
    inline function set_M42(_v : Float) : Float { this[7] = _v; return _v; }

    inline function set_M13(_v : Float) : Float { this[ 8] = _v; return _v; }
    inline function set_M23(_v : Float) : Float { this[ 9] = _v; return _v; }
    inline function set_M33(_v : Float) : Float { this[10] = _v; return _v; }
    inline function set_M43(_v : Float) : Float { this[11] = _v; return _v; }

    inline function set_M14(_v : Float) : Float { this[12] = _v; return _v; }
    inline function set_M24(_v : Float) : Float { this[13] = _v; return _v; }
    inline function set_M34(_v : Float) : Float { this[14] = _v; return _v; }
    inline function set_M44(_v : Float) : Float { this[15] = _v; return _v; }

    @:arrayAccess public inline function arrayGet(_key : Int) : Float { return this[_key]; }
    @:arrayAccess public inline function arraySet(_key : Int, _val : Float) { this[_key] = _val; }

    /**
     * Creates a 4x4 matrix.
     * Defaults to an identity matrix.
     * @param _n11 Value for column 1, row 1.
     * @param _n12 Value for column 1, row 2.
     * @param _n13 Value for column 1, row 3.
     * @param _n14 Value for column 1, row 4.
     * @param _n21 Value for column 2, row 1.
     * @param _n22 Value for column 2, row 2.
     * @param _n23 Value for column 2, row 3.
     * @param _n24 Value for column 2, row 4.
     * @param _n31 Value for column 3, row 1.
     * @param _n32 Value for column 3, row 2.
     * @param _n33 Value for column 3, row 3.
     * @param _n34 Value for column 3, row 4.
     * @param _n41 Value for column 4, row 1.
     * @param _n42 Value for column 4, row 2.
     * @param _n43 Value for column 4, row 3.
     * @param _n44 Value for column 4, row 4.
     */
    public inline function new(
        _n11 : Float = 1, _n12 : Float = 0, _n13 : Float = 0, _n14 : Float = 0,
        _n21 : Float = 0, _n22 : Float = 1, _n23 : Float = 0, _n24 : Float = 0,
        _n31 : Float = 0, _n32 : Float = 0, _n33 : Float = 1, _n34 : Float = 0,
        _n41 : Float = 0, _n42 : Float = 0, _n43 : Float = 0, _n44 : Float = 1)
    {
        this = new Float32Array(16);

        set(
            _n11, _n12, _n13, _n14,
            _n21, _n22, _n23, _n24,
            _n31, _n32, _n33, _n34,
            _n41, _n42, _n43, _n44
        );
    }

    // #region Operator Overloading

    @:op(A * B) public inline function opMultiply(_rhs : Matrix) : Matrix
    {
        return multiply(_rhs);
    }

    @:op(A * B) public inline function opMultiplyScalar(_rhs : Float) : Matrix
    {
        return multiplyScalar(_rhs);
    }

    // #endregion

    // #region General

    /**
     * Set all elements in the matrix.
     * Defaults to an identity matrix.
     * @param _n11 Value for column 1, row 1.
     * @param _n12 Value for column 1, row 2.
     * @param _n13 Value for column 1, row 3.
     * @param _n14 Value for column 1, row 4.
     * @param _n21 Value for column 2, row 1.
     * @param _n22 Value for column 2, row 2.
     * @param _n23 Value for column 2, row 3.
     * @param _n24 Value for column 2, row 4.
     * @param _n31 Value for column 3, row 1.
     * @param _n32 Value for column 3, row 2.
     * @param _n33 Value for column 3, row 3.
     * @param _n34 Value for column 3, row 4.
     * @param _n41 Value for column 4, row 1.
     * @param _n42 Value for column 4, row 2.
     * @param _n43 Value for column 4, row 3.
     * @param _n44 Value for column 4, row 4.
     */
    public inline function set(
        _n11 : Float = 1, _n12 : Float = 0, _n13 : Float = 0, _n14 : Float = 0,
        _n21 : Float = 0, _n22 : Float = 1, _n23 : Float = 0, _n24 : Float = 0,
        _n31 : Float = 0, _n32 : Float = 0, _n33 : Float = 1, _n34 : Float = 0,
        _n41 : Float = 0, _n42 : Float = 0, _n43 : Float = 0, _n44 : Float = 1) : Matrix
    {
        this[0] = _n11; this[4] = _n12; this[ 8] = _n13; this[12] = _n14;
        this[1] = _n21; this[5] = _n22; this[ 9] = _n23; this[13] = _n24;
        this[2] = _n31; this[6] = _n32; this[10] = _n33; this[14] = _n34;
        this[3] = _n41; this[7] = _n42; this[11] = _n43; this[15] = _n44;

        return this;
    }

    /**
     * Copy another matrices elements into this ones.
     * @param _m Matrix to copy.
     */
    public inline function copy(_m : Matrix) : Matrix
    {
        set(
            _m[0], _m[4], _m[ 8], _m[12],
            _m[1], _m[5], _m[ 9], _m[13],
            _m[2], _m[6], _m[10], _m[14],
            _m[3], _m[7], _m[11], _m[15]
        );

        return this;
    }

    /**
     * Creates a clone of this matrix.
     * @return Matrix
     */
    public inline function clone() : Matrix
    {
        return new Matrix(
            this[0], this[4], this[ 8], this[12],
            this[1], this[5], this[ 9], this[13],
            this[2], this[6], this[10], this[14],
            this[3], this[7], this[11], this[15]
        );
    }

    /**
     * Sets the matrix elements from an array.
     * @param _a Array of 16 floats.
     * @return Matrix
     */
    public inline function fromArray(_a : Array<Float>) : Matrix
    {
        if (_a.length != 16) return this;

        this[ 0] = _a[ 0]; this[ 1] = _a[ 1]; this[ 2] = _a[ 2]; this[ 3] = _a[ 3];
        this[ 4] = _a[ 4]; this[ 5] = _a[ 5]; this[ 6] = _a[ 6]; this[ 7] = _a[ 7];
        this[ 8] = _a[ 8]; this[ 9] = _a[ 9]; this[10] = _a[ 9]; this[11] = _a[11];
        this[12] = _a[12]; this[13] = _a[13]; this[14] = _a[13]; this[15] = _a[15];

        return this;
    }

    /**
     * Returns a float array of the matrix elements.
     * @return Array<Float>
     */
    public inline function toArray() : Array<Float>
    {
        return [
            this[ 0], this[ 1], this[ 2], this[ 3],
            this[ 4], this[ 5], this[ 6], this[ 7],
            this[ 8], this[ 9], this[10], this[11],
            this[12], this[13], this[14], this[15]
        ];
    }

    /**
     * Returns a string representation of this matrix.
     * @return String
     */
    public inline function toString() : String
    {
        var str = '{ 11:' + Maths.fixed(this[0], 3) + ', 12:' + Maths.fixed(this[4], 3)  + ', 13:' + Maths.fixed(this[ 8], 3)  + ', 14:' + Maths.fixed(this[12], 3) + ' }, ' +
                  '{ 21:' + Maths.fixed(this[1], 3) + ', 22:' + Maths.fixed(this[5], 3)  + ', 23:' + Maths.fixed(this[ 9], 3)  + ', 24:' + Maths.fixed(this[13], 3) + ' }, ' +
                  '{ 31:' + Maths.fixed(this[2], 3) + ', 32:' + Maths.fixed(this[6], 3)  + ', 33:' + Maths.fixed(this[10], 3)  + ', 34:' + Maths.fixed(this[14], 3) + ' }, ' +
                  '{ 41:' + Maths.fixed(this[3], 3) + ', 42:' + Maths.fixed(this[7], 3)  + ', 43:' + Maths.fixed(this[11], 3)  + ', 44:' + Maths.fixed(this[15], 3) + ' }';
        return str;
    }

    public inline function invert() : Matrix
    {
        var me = clone();

        var n11 = me[0], n12 = me[4], n13 = me[8],  n14 = me[12];
        var n21 = me[1], n22 = me[5], n23 = me[9],  n24 = me[13];
        var n31 = me[2], n32 = me[6], n33 = me[10], n34 = me[14];
        var n41 = me[3], n42 = me[7], n43 = me[11], n44 = me[15];

        this[ 0] = (n23 * n34 * n42) - (n24 * n33 * n42) + (n24 * n32 * n43) - (n22 * n34 * n43) - (n23 * n32 * n44) + (n22 * n33 * n44);
        this[ 4] = (n14 * n33 * n42) - (n13 * n34 * n42) - (n14 * n32 * n43) + (n12 * n34 * n43) + (n13 * n32 * n44) - (n12 * n33 * n44);
        this[ 8] = (n13 * n24 * n42) - (n14 * n23 * n42) + (n14 * n22 * n43) - (n12 * n24 * n43) - (n13 * n22 * n44) + (n12 * n23 * n44);
        this[12] = (n14 * n23 * n32) - (n13 * n24 * n32) - (n14 * n22 * n33) + (n12 * n24 * n33) + (n13 * n22 * n34) - (n12 * n23 * n34);
        this[ 1] = (n24 * n33 * n41) - (n23 * n34 * n41) - (n24 * n31 * n43) + (n21 * n34 * n43) + (n23 * n31 * n44) - (n21 * n33 * n44);
        this[ 5] = (n13 * n34 * n41) - (n14 * n33 * n41) + (n14 * n31 * n43) - (n11 * n34 * n43) - (n13 * n31 * n44) + (n11 * n33 * n44);
        this[ 9] = (n14 * n23 * n41) - (n13 * n24 * n41) - (n14 * n21 * n43) + (n11 * n24 * n43) + (n13 * n21 * n44) - (n11 * n23 * n44);
        this[13] = (n13 * n24 * n31) - (n14 * n23 * n31) + (n14 * n21 * n33) - (n11 * n24 * n33) - (n13 * n21 * n34) + (n11 * n23 * n34);
        this[ 2] = (n22 * n34 * n41) - (n24 * n32 * n41) + (n24 * n31 * n42) - (n21 * n34 * n42) - (n22 * n31 * n44) + (n21 * n32 * n44);
        this[ 6] = (n14 * n32 * n41) - (n12 * n34 * n41) - (n14 * n31 * n42) + (n11 * n34 * n42) + (n12 * n31 * n44) - (n11 * n32 * n44);
        this[10] = (n12 * n24 * n41) - (n14 * n22 * n41) + (n14 * n21 * n42) - (n11 * n24 * n42) - (n12 * n21 * n44) + (n11 * n22 * n44);
        this[14] = (n14 * n22 * n31) - (n12 * n24 * n31) - (n14 * n21 * n32) + (n11 * n24 * n32) + (n12 * n21 * n34) - (n11 * n22 * n34);
        this[ 3] = (n23 * n32 * n41) - (n22 * n33 * n41) - (n23 * n31 * n42) + (n21 * n33 * n42) + (n22 * n31 * n43) - (n21 * n32 * n43);
        this[ 7] = (n12 * n33 * n41) - (n13 * n32 * n41) + (n13 * n31 * n42) - (n11 * n33 * n42) - (n12 * n31 * n43) + (n11 * n32 * n43);
        this[11] = (n13 * n22 * n41) - (n12 * n23 * n41) - (n13 * n21 * n42) + (n11 * n23 * n42) + (n12 * n21 * n43) - (n11 * n22 * n43);
        this[15] = (n12 * n23 * n31) - (n13 * n22 * n31) + (n13 * n21 * n32) - (n11 * n23 * n32) - (n12 * n21 * n33) + (n11 * n22 * n33);

        var det = me[ 0 ] * this[ 0 ] + me[ 1 ] * this[ 4 ] + me[ 2 ] * this[ 8 ] + me[ 3 ] * this[ 12 ];

        if (det == 0) {

            trace('Matrix.getInverse: cant invert matrix, determinant is 0');

            identity();

        } //det == 0

        multiplyScalar( 1 / det );

        return this;
    }

    // #endregion

    // #region Maths

    /**
     * Calculates the determinant of this matrix.
     * @return Float
     */
    public inline function determinant() : Float
    {
        var n11 = this[0], n12 = this[4], n13 = this[ 8], n14 = this[12];
        var n21 = this[1], n22 = this[5], n23 = this[ 9], n24 = this[13];
        var n31 = this[2], n32 = this[6], n33 = this[10], n34 = this[14];
        var n41 = this[3], n42 = this[7], n43 = this[11], n44 = this[15];

        return (
            n41 * (
                 n14 * n23 * n32
                -n13 * n24 * n32
                -n14 * n22 * n33
                +n12 * n24 * n33
                +n13 * n22 * n34
                -n12 * n23 * n34
            ) +
            n42 * (
                 n11 * n23 * n34
                -n11 * n24 * n33
                +n14 * n21 * n33
                -n13 * n21 * n34
                +n13 * n24 * n31
                -n14 * n23 * n31
            ) +
            n43 * (
                 n11 * n24 * n32
                -n11 * n22 * n34
                -n14 * n21 * n32
                +n12 * n21 * n34
                +n14 * n22 * n31
                -n12 * n24 * n31
            ) +
            n44 * (
                -n13 * n22 * n31
                -n11 * n23 * n32
                +n11 * n22 * n33
                +n13 * n21 * n32
                -n12 * n21 * n33
                +n12 * n23 * n31
            )
        );
    }

    /**
     * Transpose this matrix.
     * @return Matrix
     */
    public inline function transpose() : Matrix
    {
        var tmp : Float;

        tmp = this[1]; this[1] = this[4]; this[4] = tmp;
        tmp = this[2]; this[2] = this[8]; this[8] = tmp;
        tmp = this[6]; this[6] = this[9]; this[9] = tmp;

        tmp = this[ 3]; this[ 3] = this[12]; this[12] = tmp;
        tmp = this[ 7]; this[ 7] = this[13]; this[13] = tmp;
        tmp = this[11]; this[11] = this[14]; this[14] = tmp;

        return this;
    }

    /**
     * Scale this matrix by a vector.
     * @param _v Scaling vector.
     */
    public inline function scale(_v : Vector) : Matrix
    {
        var _x = _v.x;
        var _y = _v.y;
        var _z = _v.z;

        this[0] *= _x; this[4] *= _y; this[8]  *= _z;
        this[1] *= _x; this[5] *= _y; this[9]  *= _z;
        this[2] *= _x; this[6] *= _y; this[10] *= _z;
        this[3] *= _x; this[7] *= _y; this[11] *= _z;

        return this;
    }

    /**
     * Compose a matrix from the provided data.
     * @param _position   Position for the matrix.
     * @param _quaternion Rotation for the matrix.
     * @param _scale      Scale for the matrix.
     */
    public inline function compose(_position : Vector, _quaternion : Quaternion, _scale : Vector) : Matrix
    {
        makeRotationFromQuaternion(_quaternion);
        scale(_scale);
        setPosition(_position);

        return this;
    }

    /**
     * Decompose a matrix into its three parts.
     * @param _position   Optional vector to store the position in.
     * @param _quaternion Optional quaternion to store the rotation in.
     * @param _scale      Optional vector to store the scale in.
     */
    public inline function decompose(_position : Vector, _quaternion : Quaternion, _scale : Vector) : MatrixTransform
    {
        var ax_x = this[0]; var ax_y = this[1]; var ax_z = this[ 2];
        var ay_x = this[4]; var ay_y = this[5]; var ay_z = this[ 6];
        var az_x = this[8]; var az_y = this[9]; var az_z = this[10];

        var ax_length = Maths.sqrt(ax_x * ax_x + ax_y * ax_y + ax_z * ax_z);
        var ay_length = Maths.sqrt(ay_x * ay_x + ay_y * ay_y + ay_z * ay_z);
        var az_length = Maths.sqrt(az_x * az_x + az_y * az_y + az_z * az_z);

        if(_quaternion == null)
        {
            _quaternion = new Quaternion();
        }

        // Get the position from the matrix.
        if (_position == null)
        {
            _position = new Vector(this[12], this[13], this[14]);
        }
        else
        {
            _position.set_xyz(this[12], this[13], this[14]);
        }

        // Get the scale from the matrix
        if (_scale == null)
        {
            _scale = new Vector(ax_length, ay_length, az_length);
        }
        else
        {
            _scale.set_xyz(ax_length, ay_length, az_length);
        }

        var matrix : Matrix = cast Float32Array.fromView(this);

        matrix[0] /= ax_length;
        matrix[1] /= ax_length;
        matrix[2] /= ax_length;

        matrix[4] /= ax_length;
        matrix[5] /= ax_length;
        matrix[6] /= ax_length;

        matrix[ 8] /= ax_length;
        matrix[ 9] /= ax_length;
        matrix[10] /= ax_length;

        _quaternion.setFromRotationMatrix(matrix);

        return new MatrixTransform(_position, _quaternion, _scale);
    }

    // #endregion

    // #region Operations

    /**
     * Multiply this matrix by another.
     * @param _m Matrix to multiply with.
     */
    public inline function multiply(_m : Matrix) : Matrix
    {
        var a11 = this[0], a12 = this[4], a13 = this[8],  a14 = this[12];
        var a21 = this[1], a22 = this[5], a23 = this[9],  a24 = this[13];
        var a31 = this[2], a32 = this[6], a33 = this[10], a34 = this[14];
        var a41 = this[3], a42 = this[7], a43 = this[11], a44 = this[15];

        var b11 = _m[0], b12 = _m[4], b13 = _m[8],  b14 = _m[12];
        var b21 = _m[1], b22 = _m[5], b23 = _m[9],  b24 = _m[13];
        var b31 = _m[2], b32 = _m[6], b33 = _m[10], b34 = _m[14];
        var b41 = _m[3], b42 = _m[7], b43 = _m[11], b44 = _m[15];

        this[ 0] = a11 * b11 + a12 * b21 + a13 * b31 + a14 * b41;
        this[ 4] = a11 * b12 + a12 * b22 + a13 * b32 + a14 * b42;
        this[ 8] = a11 * b13 + a12 * b23 + a13 * b33 + a14 * b43;
        this[12] = a11 * b14 + a12 * b24 + a13 * b34 + a14 * b44;

        this[ 1] = a21 * b11 + a22 * b21 + a23 * b31 + a24 * b41;
        this[ 5] = a21 * b12 + a22 * b22 + a23 * b32 + a24 * b42;
        this[ 9] = a21 * b13 + a22 * b23 + a23 * b33 + a24 * b43;
        this[13] = a21 * b14 + a22 * b24 + a23 * b34 + a24 * b44;

        this[ 2] = a31 * b11 + a32 * b21 + a33 * b31 + a34 * b41;
        this[ 6] = a31 * b12 + a32 * b22 + a33 * b32 + a34 * b42;
        this[10] = a31 * b13 + a32 * b23 + a33 * b33 + a34 * b43;
        this[14] = a31 * b14 + a32 * b24 + a33 * b34 + a34 * b44;

        this[ 3] = a41 * b11 + a42 * b21 + a43 * b31 + a44 * b41;
        this[ 7] = a41 * b12 + a42 * b22 + a43 * b32 + a44 * b42;
        this[11] = a41 * b13 + a42 * b23 + a43 * b33 + a44 * b43;
        this[15] = a41 * b14 + a42 * b24 + a43 * b34 + a44 * b44;

        return this;
    }

    /**
     * Multiply two matrices together and store the result in this matrix.
     * @param _a Matrix A.
     * @param _b Matrix B.
     */
    public inline function multiplyMatrices(_a : Matrix, _b : Matrix) : Matrix
    {
        var a11 = _a[0], a12 = _a[4], a13 = _a[8],  a14 = _a[12];
        var a21 = _a[1], a22 = _a[5], a23 = _a[9],  a24 = _a[13];
        var a31 = _a[2], a32 = _a[6], a33 = _a[10], a34 = _a[14];
        var a41 = _a[3], a42 = _a[7], a43 = _a[11], a44 = _a[15];

        var b11 = _b[0], b12 = _b[4], b13 = _b[8],  b14 = _b[12];
        var b21 = _b[1], b22 = _b[5], b23 = _b[9],  b24 = _b[13];
        var b31 = _b[2], b32 = _b[6], b33 = _b[10], b34 = _b[14];
        var b41 = _b[3], b42 = _b[7], b43 = _b[11], b44 = _b[15];

        this[ 0] = a11 * b11 + a12 * b21 + a13 * b31 + a14 * b41;
        this[ 4] = a11 * b12 + a12 * b22 + a13 * b32 + a14 * b42;
        this[ 8] = a11 * b13 + a12 * b23 + a13 * b33 + a14 * b43;
        this[12] = a11 * b14 + a12 * b24 + a13 * b34 + a14 * b44;

        this[ 1] = a21 * b11 + a22 * b21 + a23 * b31 + a24 * b41;
        this[ 5] = a21 * b12 + a22 * b22 + a23 * b32 + a24 * b42;
        this[ 9] = a21 * b13 + a22 * b23 + a23 * b33 + a24 * b43;
        this[13] = a21 * b14 + a22 * b24 + a23 * b34 + a24 * b44;

        this[ 2] = a31 * b11 + a32 * b21 + a33 * b31 + a34 * b41;
        this[ 6] = a31 * b12 + a32 * b22 + a33 * b32 + a34 * b42;
        this[10] = a31 * b13 + a32 * b23 + a33 * b33 + a34 * b43;
        this[14] = a31 * b14 + a32 * b24 + a33 * b34 + a34 * b44;

        this[ 3] = a41 * b11 + a42 * b21 + a43 * b31 + a44 * b41;
        this[ 7] = a41 * b12 + a42 * b22 + a43 * b32 + a44 * b42;
        this[11] = a41 * b13 + a42 * b23 + a43 * b33 + a44 * b43;
        this[15] = a41 * b14 + a42 * b24 + a43 * b34 + a44 * b44;

        return this;
    }

    /**
     * Multiply this matrix by a scalar value.
     * @param _v Scalar value.
     */
    public inline function multiplyScalar(_v : Float) : Matrix
    {
        this[0] *= _v; this[4] *= _v; this[ 8] *= _v; this[12] *= _v;
        this[1] *= _v; this[5] *= _v; this[ 9] *= _v; this[13] *= _v;
        this[2] *= _v; this[6] *= _v; this[10] *= _v; this[14] *= _v;
        this[3] *= _v; this[7] *= _v; this[11] *= _v; this[15] *= _v;

        return this;
    }

    public inline function up() : Vector
    {
        return new Vector(this[4], this[5], this[6]);
    }

    public inline function down() : Vector
    {
        return up().invert();
    }

    public inline function left() : Vector
    {
        return right().invert();
    }

    public inline function right() : Vector
    {
        return new Vector(this[0], this[1], this[2]);
    }

    public inline function forward() : Vector
    {
        return backwards().invert();
    }

    public inline function backwards() : Vector
    {
        return new Vector(this[8], this[9], this[10]);
    }

    // #endregion

    // #region Transformations

    /**
     * Return the position from this matrix into a vector.
     * @return Vector
     */
    public inline function getPosition() : Vector
    {
        return new Vector(this[12], this[13], this[14]);
    }

    /**
     * Set the position in the matrix based on a vector.
     * @param _v Position vector.
     */
    public inline function setPosition(_v : Vector) : Matrix
    {
        this[12] = _v.x;
        this[13] = _v.y;
        this[14] = _v.z;

        return this;
    }

    /**
     * Sets this matrix to look at a point from a position.
     * @param _eye    The eye position.
     * @param _target The target position.
     * @param _up     Up vector.
     */
    public inline function lookAt(_eye : Vector, _target : Vector, _up : Vector) : Matrix
    {
        var _z = Vector.Subtract(_target, _eye).normalize();
        if (_z.length == 0)
        {
            _z.z = 1;
        }

        var _x = Vector.Cross(_up, _z).normalize();
        if (_x.length == 0)
        {
            _z.x += 0.0001;
            _z = Vector.Cross(_up, _z).normalize();
        }

        var _y = Vector.Cross(_z, _x);

        this[0] = _x.x; this[4] = _y.x; this[ 8] = _z.x;
        this[1] = _x.y; this[5] = _y.y; this[ 9] = _z.y;
        this[2] = _x.z; this[6] = _y.z; this[10] = _z.z;

        return this;
    }

    /**
     * Sets this matrix to an identity matrix.
     */
    public inline function identity() : Matrix
    {
        set(
            1, 0, 0, 0,
            0, 1, 0, 0,
            0, 0, 1, 0,
            0, 0, 0, 1
        );

        return this;
    }

    /**
     * Makes this matrix represents a 2D space.
     * @param _x        x position.
     * @param _y        y position.
     * @param _scale    scale value. (default 1)
     * @param _rotation rotation value. (default 0)
     */
    public inline function make2D(_x : Float, _y : Float, _scale : Float = 1, _rotation : Float = 0) : Matrix
    {
        var theta = Maths.toRadians(_rotation);
        var c     = Maths.cos(theta);
        var s     = Maths.cos(theta);

        set(
             c * _scale, s * _scale,  0, _x,
            -s * _scale, c * _scale,  0, _y,
                      0,          0,  1,  0,
                      0,          0,  0,  1
        );

        return this;
    }

    /**
     * Translate this matrix to the provided position.
     * @param _x x position.
     * @param _y y position.
     * @param _z z position.
     */
    public inline function makeTranslation(_x : Float, _y : Float, _z : Float) : Matrix
    {
        set(
            1, 0, 0, _x,
            0, 1, 0, _y,
            0, 0, 1, _z,
            0, 0, 0, 1
        );

        return this;
    }

    /**
     * Set this matrix to a rotation.
     * @param _axis  Vector containing the x, y, and z axis.
     * @param _angle Angle value.
     */
    public inline function makeRotationAxis(_axis : Vector, _angle : Float) : Matrix
    {
        var c = Maths.cos(_angle);
        var s = Maths.sin(_angle);
        var t = 1 - c;

        var ax = _axis.x;
        var ay = _axis.y;
        var az = _axis.z;

        var tx = t * ax;
        var ty = t * ay;

        set(
            (tx * ax + c)     ,   (tx * ay - s * az),   (tx * az + s * ay),   0,
            (tx * ay + s * az),   (ty * ay + c)     ,   (ty * az - s * ax),   0,
            (tx * az - s * ay),   (ty * az + s * ax),   (t * az * az + c) ,   0,
            0, 0, 0, 1
        );

        return this;
    }

    /**
     * Make a rotation around the x axis.
     * @param _theta Angle radians.
     */
    public inline function makeRotationX(_theta : Float)
    {
        var c = Maths.cos(_theta);
        var s = Maths.sin(_theta);

        set(
            1,  0,  0,  0,
            0,  c, -s,  0,
            0,  s,  c,  0,
            0,  0,  0,  1
        );
    }

    /**
     * Make a rotation around the y axis.
     * @param _theta Angle radians.
     */
    public inline function makeRotationY(_theta : Float) : Matrix
    {
        var c = Maths.cos(_theta);
        var s = Maths.sin(_theta);

        set(
            c,  0,  s,  0,
            0,  1,  0,  0,
           -s,  0,  c,  0,
            0,  0,  0,  1
        );

        return this;
    }

    /**
     * Make a rotation around the z axis.
     * @param _theta Angle radians.
     */
    public inline function makeRotationZ(_theta : Float) : Matrix
    {
        var c = Maths.cos(_theta);
        var s = Maths.sin(_theta);

        set(
            c, -s,  0,  0,
            s,  c,  0,  0,
            0,  0,  1,  0,
            0,  0,  0,  1
        );

        return this;
    }

    /**
     * Set the scale of this matrix.
     * @param _x x scale.
     * @param _y y scale.
     * @param _z z scale.
     */
    public inline function makeScale(_x : Float, _y : Float, _z : Float) : Matrix
    {
        set(
            _x,  0,  0,  0,
             0, _y,  0,  0,
             0,  0, _z,  0,
             0,  0,  0,  1
        );

        return this;
    }

    /**
     * Make a rotation from an euler angle.
     * @param _v     Vector containing the euler angle.
     * @param _order Component order.
     * @return Matrix
     */
    public inline function makeRotationFromEuler(_v : Vector, _order : ComponentOrder = XYZ) : Matrix
    {
        var x = _v.x;
        var y = _v.y;
        var z = _v.z;

        var a = Maths.cos(x), b = Maths.sin(x);
        var c = Maths.cos(y), d = Maths.sin(y);
        var e = Maths.cos(z), f = Maths.sin(z);

        switch(_order)
        {
            case XYZ:
                var ae = a * e, af = a * f, be = b * e, bf = b * f;

                this[ 0] = c * e;
                this[ 4] = - c * f;
                this[ 8] = d;

                this[ 1] = af + be * d;
                this[ 5] = ae - bf * d;
                this[ 9] = - b * c;

                this[ 2] = bf - ae * d;
                this[ 6] = be + af * d;
                this[10] = a * c;
            case YXZ:
                var ce = c * e, cf = c * f, de = d * e, df = d * f;

                this[ 0] = ce + df * b;
                this[ 4] = de * b - cf;
                this[ 8] = a * d;

                this[ 1] = a * f;
                this[ 5] = a * e;
                this[ 9] = - b;

                this[ 2] = cf * b - de;
                this[ 6] = df + ce * b;
                this[10] = a * c;
            case ZXY:
                var ce = c * e, cf = c * f, de = d * e, df = d * f;

                this[ 0] = ce - df * b;
                this[ 4] = - a * f;
                this[ 8] = de + cf * b;

                this[ 1] = cf + de * b;
                this[ 5] = a * e;
                this[ 9] = df - ce * b;

                this[ 2] = - a * d;
                this[ 6] = b;
                this[10] = a * c;
            case ZYX:
                var ae = a * e, af = a * f, be = b * e, bf = b * f;

                this[ 0] = c * e;
                this[ 4] = be * d - af;
                this[ 8] = ae * d + bf;

                this[ 1] = c * f;
                this[ 5] = bf * d + ae;
                this[ 9] = af * d - be;

                this[ 2] = - d;
                this[ 6] = b * c;
                this[10] = a * c;
            case YZX:
                var ac = a * c, ad = a * d, bc = b * c, bd = b * d;

                this[ 0] = c * e;
                this[ 4] = bd - ac * f;
                this[ 8] = bc * f + ad;

                this[ 1] = f;
                this[ 5] = a * e;
                this[ 9] = - b * e;

                this[ 2] = - d * e;
                this[ 6] = ad * f + bc;
                this[10] = ac - bd * f;
            case XZY:
                var ac = a * c, ad = a * d, bc = b * c, bd = b * d;

                this[ 0] = c * e;
                this[ 4] = - f;
                this[ 8] = d * e;

                this[ 1] = ac * f + bd;
                this[ 5] = a * e;
                this[ 9] = ad * f - bc;

                this[ 2] = bc * f - ad;
                this[ 6] = b * e;
                this[10] = bd * f + ac;
        }

        this[ 3] = 0;
        this[ 7] = 0;
        this[11] = 0;

        this[12] = 0;
        this[13] = 0;
        this[14] = 0;
        this[15] = 1;

        return this;
    }

    /**
     * Creates a rotation matrix from a quaternion.
     * @param _q Quaternion containing the rotation.
     */
    public inline function makeRotationFromQuaternion(_q : Quaternion) : Matrix
    {

        var x2 = _q.x + _q.x, y2 = _q.y + _q.y, z2 = _q.z + _q.z;
        var xx = _q.x * x2,   xy = _q.x * y2,   xz = _q.x *  z2;
        var yy = _q.y * y2,   yz = _q.y * z2,   zz = _q.z *  z2;
        var wx = _q.w * x2,   wy = _q.w * y2,   wz = _q.w *  z2;

        this[0] = 1 - ( yy + zz );
        this[4] = xy - wz;
        this[8] = xz + wy;

        this[1] = xy + wz;
        this[5] = 1 - ( xx + zz );
        this[9] = yz - wx;

        this[ 2] = xz - wy;
        this[ 6] = yz + wx;
        this[10] = 1 - ( xx + yy );

        // last column
        this[ 3] = 0;
        this[ 7] = 0;
        this[11] = 0;

        // bottom row
        this[12] = 0;
        this[13] = 0;
        this[14] = 0;
        this[15] = 1;

        return this;
    }

    /**
     * Create a matrix representing a frustum.
     * @param _left   - 
     * @param _right  - 
     * @param _bottom - 
     * @param _top    - 
     * @param _near   - 
     * @param _far    - 
     * @return Matrix
     */
    public inline function makeFrustum(_left : Float, _right : Float, _bottom : Float, _top : Float, _near : Float, _far : Float) : Matrix
    {
        var tx = 2 * _near / (_right - _left);
        var ty = 2 * _near / (_top - _bottom);

        var a =  (_right + _left) / (_right - _left);
        var b =  (_top + _bottom) / (_top - _bottom);
        var c = -(_far + _near)   / (_far - _near);
        var d = -2 * _far * _near / (_far - _near);

        this[0] = tx;  this[4] = 0;   this[8]  = a;   this[12] = 0;
        this[1] = 0;   this[5] = ty;  this[9]  = b;   this[13] = 0;
        this[2] = 0;   this[6] = 0;   this[10] = c;   this[14] = d;
        this[3] = 0;   this[7] = 0;   this[11] = -1;  this[15] = 0;

        return this;
    }

    /**
     * Create a perspective matrix.
     * @param _fov    - Vertical FOV of this perspective.
     * @param _aspect - Aspect ratio.
     * @param _near   - near clipping.
     * @param _far    - far clipping.
     */
    public function makePerspective(_fov : Float, _aspect : Float, _near : Float, _far : Float) : Matrix
    {
        var ymax = _near * Maths.tan( Maths.toRadians(_fov * 0.5) );
        var ymin = -ymax;
        var xmin = ymin * _aspect;
        var xmax = ymax * _aspect;

        makeFrustum(xmin, xmax, ymin, ymax, _near, _far);

        return this;
    }

    /**
     * Creates an orthographic projection matrix.
     * @param _left - 
     * @param _right - 
     * @param _top - 
     * @param _bottom - 
     * @param _near - 
     * @param _far - 
     * @return Matrix
     */
    public inline function makeOrthographic(_left : Float, _right : Float, _top : Float, _bottom : Float, _near : Float, _far : Float) : Matrix
    {
        var w = _right - _left;
        var h = _top - _bottom;
        var p = _far - _near;

        var tx = ( _right + _left )   / w;
        var ty = ( _top   + _bottom ) / h;
        var tz = ( _far   + _near )   / p;

        this[0] = 2 / w;  this[4] = 0;      this[ 8] = 0;       this[12] = -tx;
        this[1] = 0;      this[5] = 2 / h;  this[ 9] = 0;       this[13] = -ty;
        this[2] = 0;      this[6] = 0;      this[10] = -2 / p;  this[14] = -tz;
        this[3] = 0;      this[7] = 0;      this[11] = 0;       this[15] = 1;

        return this;
    }

    // #endregion
}
