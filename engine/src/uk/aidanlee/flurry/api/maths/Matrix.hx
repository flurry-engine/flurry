package uk.aidanlee.flurry.api.maths;

import snow.api.buffers.Float32Array;

/**
 * 4x4 matrix class for transformations and perspective.
 */
class Matrix
{
    /**
     * Haxe vector containing the 16 elements of this matrix.
     */
    public var elements : Float32Array;

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

    inline function get_M11() : Float { return elements[0]; }
    inline function get_M21() : Float { return elements[1]; }
    inline function get_M31() : Float { return elements[2]; }
    inline function get_M41() : Float { return elements[3]; }

    inline function get_M12() : Float { return elements[4]; }
    inline function get_M22() : Float { return elements[5]; }
    inline function get_M32() : Float { return elements[6]; }
    inline function get_M42() : Float { return elements[7]; }

    inline function get_M13() : Float { return elements[ 8]; }
    inline function get_M23() : Float { return elements[ 9]; }
    inline function get_M33() : Float { return elements[10]; }
    inline function get_M43() : Float { return elements[11]; }

    inline function get_M14() : Float { return elements[12]; }
    inline function get_M24() : Float { return elements[13]; }
    inline function get_M34() : Float { return elements[14]; }
    inline function get_M44() : Float { return elements[15]; }

    inline function set_M11(_v : Float) : Float { elements[0] = _v; return _v; }
    inline function set_M21(_v : Float) : Float { elements[1] = _v; return _v; }
    inline function set_M31(_v : Float) : Float { elements[2] = _v; return _v; }
    inline function set_M41(_v : Float) : Float { elements[3] = _v; return _v; }

    inline function set_M12(_v : Float) : Float { elements[4] = _v; return _v; }
    inline function set_M22(_v : Float) : Float { elements[5] = _v; return _v; }
    inline function set_M32(_v : Float) : Float { elements[6] = _v; return _v; }
    inline function set_M42(_v : Float) : Float { elements[7] = _v; return _v; }

    inline function set_M13(_v : Float) : Float { elements[ 8] = _v; return _v; }
    inline function set_M23(_v : Float) : Float { elements[ 9] = _v; return _v; }
    inline function set_M33(_v : Float) : Float { elements[10] = _v; return _v; }
    inline function set_M43(_v : Float) : Float { elements[11] = _v; return _v; }

    inline function set_M14(_v : Float) : Float { elements[12] = _v; return _v; }
    inline function set_M24(_v : Float) : Float { elements[13] = _v; return _v; }
    inline function set_M34(_v : Float) : Float { elements[14] = _v; return _v; }
    inline function set_M44(_v : Float) : Float { elements[15] = _v; return _v; }

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
    inline public function new(
        _n11 : Float = 1, _n12 : Float = 0, _n13 : Float = 0, _n14 : Float = 0,
        _n21 : Float = 0, _n22 : Float = 1, _n23 : Float = 0, _n24 : Float = 0,
        _n31 : Float = 0, _n32 : Float = 0, _n33 : Float = 1, _n34 : Float = 0,
        _n41 : Float = 0, _n42 : Float = 0, _n43 : Float = 0, _n44 : Float = 1)
    {
        elements = new Float32Array(16);

        set(
            _n11, _n12, _n13, _n14,
            _n21, _n22, _n23, _n24,
            _n31, _n32, _n33, _n34,
            _n41, _n42, _n43, _n44
        );
    }

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
     * @return Matrix
     */
    inline public function set(
        _n11 : Float = 1, _n12 : Float = 0, _n13 : Float = 0, _n14 : Float = 0,
        _n21 : Float = 0, _n22 : Float = 1, _n23 : Float = 0, _n24 : Float = 0,
        _n31 : Float = 0, _n32 : Float = 0, _n33 : Float = 1, _n34 : Float = 0,
        _n41 : Float = 0, _n42 : Float = 0, _n43 : Float = 0, _n44 : Float = 1) : Matrix
    {
        var e = elements;

        e[0] = _n11; e[4] = _n12; e[ 8] = _n13; e[12] = _n14;
        e[1] = _n21; e[5] = _n22; e[ 9] = _n23; e[13] = _n24;
        e[2] = _n31; e[6] = _n32; e[10] = _n33; e[14] = _n34;
        e[3] = _n41; e[7] = _n42; e[11] = _n43; e[15] = _n44;

        return this;
    }

    /**
     * Copy another matrices elements into this ones.
     * @param _m Matrix to copy.
     * @return Matrix
     */
    inline public function copy(_m : Matrix) : Matrix
    {
        var me = _m.elements;

        set(
            me[0], me[4], me[ 8], me[12],
            me[1], me[5], me[ 9], me[13],
            me[2], me[6], me[10], me[14],
            me[3], me[7], me[11], me[15]
        );

        return this;
    }

    /**
     * Creates a clone of this matrix.
     * @return Matrix
     */
    inline public function clone() : Matrix
    {
        var me = elements;

        return new Matrix(
            me[0], me[4], me[ 8], me[12],
            me[1], me[5], me[ 9], me[13],
            me[2], me[6], me[10], me[14],
            me[3], me[7], me[11], me[15]
        );
    }

    /**
     * Sets the matrix elements from an array.
     * @param _a Array of 16 floats.
     * @return Matrix
     */
    inline public function fromArray(_a : Array<Float>) : Matrix
    {
        if (_a.length != 16) return this;

        var e = elements;
        e[ 0] = _a[ 0]; e[ 1] = _a[ 1]; e[ 2] = _a[ 2]; e[ 3] = _a[ 3];
        e[ 4] = _a[ 4]; e[ 5] = _a[ 5]; e[ 6] = _a[ 6]; e[ 7] = _a[ 7];
        e[ 8] = _a[ 8]; e[ 9] = _a[ 9]; e[10] = _a[ 9]; e[11] = _a[11];
        e[12] = _a[12]; e[13] = _a[13]; e[14] = _a[13]; e[15] = _a[15];

        return this;
    }

    /**
     * Returns a float array of the matrix elements.
     * @return Array<Float>
     */
    inline public function toArray() : Array<Float>
    {
        var e = elements;

        return [
            e[ 0], e[ 1], e[ 2], e[ 3],
            e[ 4], e[ 5], e[ 6], e[ 7],
            e[ 8], e[ 9], e[10], e[11],
            e[12], e[13], e[14], e[15]
        ];
    }

    /**
     * Returns a string representation of this matrix.
     * @return String
     */
    inline public function toString() : String
    {
        var e = elements;
        var str = '{ 11:' + Maths.fixed(e[0], 3) + ', 12:' + Maths.fixed(e[4], 3)  + ', 13:' + Maths.fixed(e[ 8], 3)  + ', 14:' + Maths.fixed(e[12], 3) + ' }, ' +
                  '{ 21:' + Maths.fixed(e[1], 3) + ', 22:' + Maths.fixed(e[5], 3)  + ', 23:' + Maths.fixed(e[ 9], 3)  + ', 24:' + Maths.fixed(e[13], 3) + ' }, ' +
                  '{ 31:' + Maths.fixed(e[2], 3) + ', 32:' + Maths.fixed(e[6], 3)  + ', 33:' + Maths.fixed(e[10], 3)  + ', 34:' + Maths.fixed(e[14], 3) + ' }, ' +
                  '{ 41:' + Maths.fixed(e[3], 3) + ', 42:' + Maths.fixed(e[7], 3)  + ', 43:' + Maths.fixed(e[11], 3)  + ', 44:' + Maths.fixed(e[15], 3) + ' }';
        return str;
    }

    inline public function invert() : Matrix
    {
        var te = elements;
        var me = elements;

        var n11 = me[0], n12 = me[4], n13 = me[8],  n14 = me[12];
        var n21 = me[1], n22 = me[5], n23 = me[9],  n24 = me[13];
        var n31 = me[2], n32 = me[6], n33 = me[10], n34 = me[14];
        var n41 = me[3], n42 = me[7], n43 = me[11], n44 = me[15];

        te[ 0] = (n23 * n34 * n42) - (n24 * n33 * n42) + (n24 * n32 * n43) - (n22 * n34 * n43) - (n23 * n32 * n44) + (n22 * n33 * n44);
        te[ 4] = (n14 * n33 * n42) - (n13 * n34 * n42) - (n14 * n32 * n43) + (n12 * n34 * n43) + (n13 * n32 * n44) - (n12 * n33 * n44);
        te[ 8] = (n13 * n24 * n42) - (n14 * n23 * n42) + (n14 * n22 * n43) - (n12 * n24 * n43) - (n13 * n22 * n44) + (n12 * n23 * n44);
        te[12] = (n14 * n23 * n32) - (n13 * n24 * n32) - (n14 * n22 * n33) + (n12 * n24 * n33) + (n13 * n22 * n34) - (n12 * n23 * n34);
        te[ 1] = (n24 * n33 * n41) - (n23 * n34 * n41) - (n24 * n31 * n43) + (n21 * n34 * n43) + (n23 * n31 * n44) - (n21 * n33 * n44);
        te[ 5] = (n13 * n34 * n41) - (n14 * n33 * n41) + (n14 * n31 * n43) - (n11 * n34 * n43) - (n13 * n31 * n44) + (n11 * n33 * n44);
        te[ 9] = (n14 * n23 * n41) - (n13 * n24 * n41) - (n14 * n21 * n43) + (n11 * n24 * n43) + (n13 * n21 * n44) - (n11 * n23 * n44);
        te[13] = (n13 * n24 * n31) - (n14 * n23 * n31) + (n14 * n21 * n33) - (n11 * n24 * n33) - (n13 * n21 * n34) + (n11 * n23 * n34);
        te[ 2] = (n22 * n34 * n41) - (n24 * n32 * n41) + (n24 * n31 * n42) - (n21 * n34 * n42) - (n22 * n31 * n44) + (n21 * n32 * n44);
        te[ 6] = (n14 * n32 * n41) - (n12 * n34 * n41) - (n14 * n31 * n42) + (n11 * n34 * n42) + (n12 * n31 * n44) - (n11 * n32 * n44);
        te[10] = (n12 * n24 * n41) - (n14 * n22 * n41) + (n14 * n21 * n42) - (n11 * n24 * n42) - (n12 * n21 * n44) + (n11 * n22 * n44);
        te[14] = (n14 * n22 * n31) - (n12 * n24 * n31) - (n14 * n21 * n32) + (n11 * n24 * n32) + (n12 * n21 * n34) - (n11 * n22 * n34);
        te[ 3] = (n23 * n32 * n41) - (n22 * n33 * n41) - (n23 * n31 * n42) + (n21 * n33 * n42) + (n22 * n31 * n43) - (n21 * n32 * n43);
        te[ 7] = (n12 * n33 * n41) - (n13 * n32 * n41) + (n13 * n31 * n42) - (n11 * n33 * n42) - (n12 * n31 * n43) + (n11 * n32 * n43);
        te[11] = (n13 * n22 * n41) - (n12 * n23 * n41) - (n13 * n21 * n42) + (n11 * n23 * n42) + (n12 * n21 * n43) - (n11 * n22 * n43);
        te[15] = (n12 * n23 * n31) - (n13 * n22 * n31) + (n13 * n21 * n32) - (n11 * n23 * n32) - (n12 * n21 * n33) + (n11 * n22 * n33);

        var det = me[ 0 ] * te[ 0 ] + me[ 1 ] * te[ 4 ] + me[ 2 ] * te[ 8 ] + me[ 3 ] * te[ 12 ];

        if (det == 0) {

            trace('Matrix.getInverse: cant invert matrix, determinant is 0');

            identity();

            return this;

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
    inline public function determinant() : Float
    {
        var e = elements;

        var n11 = e[0], n12 = e[4], n13 = e[ 8], n14 = e[12];
        var n21 = e[1], n22 = e[5], n23 = e[ 9], n24 = e[13];
        var n31 = e[2], n32 = e[6], n33 = e[10], n34 = e[14];
        var n41 = e[3], n42 = e[7], n43 = e[11], n44 = e[15];

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
    inline public function transpose() : Matrix
    {
        var e = elements;
        var tmp : Float;

        tmp = e[1]; e[1] = e[4]; e[4] = tmp;
        tmp = e[2]; e[2] = e[8]; e[8] = tmp;
        tmp = e[6]; e[6] = e[9]; e[9] = tmp;

        tmp = e[ 3]; e[ 3] = e[12]; e[12] = tmp;
        tmp = e[ 7]; e[ 7] = e[13]; e[13] = tmp;
        tmp = e[11]; e[11] = e[14]; e[14] = tmp;

        return this;
    }

    /**
     * Scale this matrix by a vector.
     * @param _v Scaling vector.
     * @return Matrix
     */
    inline public function scale(_v : Vector) : Matrix
    {
        var e = elements;

        var _x = _v.x;
        var _y = _v.y;
        var _z = _v.z;

        e[0] *= _x; e[4] *= _y; e[8]  *= _z;
        e[1] *= _x; e[5] *= _y; e[9]  *= _z;
        e[2] *= _x; e[6] *= _y; e[10] *= _z;
        e[3] *= _x; e[7] *= _y; e[11] *= _z;

        return this;
    }

    /**
     * Compose a matrix from the provided data.
     * @param _position   Position for the matrix.
     * @param _quaternion Rotation for the matrix.
     * @param _scale      Scale for the matrix.
     * @return Matrix
     */
    inline public function compose(_position : Vector, _quaternion : Quaternion, _scale : Vector) : Matrix
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
     * @return MatrixTransform
     */
    inline public function decompose(_position : Vector, _quaternion : Quaternion, _scale : Vector) : MatrixTransform
    {
        var me = elements;
        var matrix = new Matrix();

        var ax_x = me[0]; var ax_y = me[1]; var ax_z = me[ 2];
        var ay_x = me[4]; var ay_y = me[5]; var ay_z = me[ 6];
        var az_x = me[8]; var az_y = me[9]; var az_z = me[10];

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
            _position = new Vector(me[12], me[13], me[14]);
        }
        else
        {
            _position.set_xyz(me[12], me[13], me[14]);
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

        matrix.elements = Float32Array.fromView(elements);
        var me = matrix.elements;

        me[0] /= ax_length;
        me[1] /= ax_length;
        me[2] /= ax_length;

        me[4] /= ax_length;
        me[5] /= ax_length;
        me[6] /= ax_length;

        me[ 8] /= ax_length;
        me[ 9] /= ax_length;
        me[10] /= ax_length;

        _quaternion.setFromRotationMatrix(matrix);

        return new MatrixTransform(_position, _quaternion, _scale);
    }

    // #endregion

    // #region Operations

    /**
     * Multiply this matrix by another.
     * @param _m Matrix to multiply with.
     * @return Matrix
     */
    inline public function multiply(_m : Matrix) : Matrix
    {
        var ae = elements;
        var be = _m.elements;

        var a11 = ae[0], a12 = ae[4], a13 = ae[8],  a14 = ae[12];
        var a21 = ae[1], a22 = ae[5], a23 = ae[9],  a24 = ae[13];
        var a31 = ae[2], a32 = ae[6], a33 = ae[10], a34 = ae[14];
        var a41 = ae[3], a42 = ae[7], a43 = ae[11], a44 = ae[15];

        var b11 = be[0], b12 = be[4], b13 = be[8],  b14 = be[12];
        var b21 = be[1], b22 = be[5], b23 = be[9],  b24 = be[13];
        var b31 = be[2], b32 = be[6], b33 = be[10], b34 = be[14];
        var b41 = be[3], b42 = be[7], b43 = be[11], b44 = be[15];

        elements[ 0] = a11 * b11 + a12 * b21 + a13 * b31 + a14 * b41;
        elements[ 4] = a11 * b12 + a12 * b22 + a13 * b32 + a14 * b42;
        elements[ 8] = a11 * b13 + a12 * b23 + a13 * b33 + a14 * b43;
        elements[12] = a11 * b14 + a12 * b24 + a13 * b34 + a14 * b44;

        elements[ 1] = a21 * b11 + a22 * b21 + a23 * b31 + a24 * b41;
        elements[ 5] = a21 * b12 + a22 * b22 + a23 * b32 + a24 * b42;
        elements[ 9] = a21 * b13 + a22 * b23 + a23 * b33 + a24 * b43;
        elements[13] = a21 * b14 + a22 * b24 + a23 * b34 + a24 * b44;

        elements[ 2] = a31 * b11 + a32 * b21 + a33 * b31 + a34 * b41;
        elements[ 6] = a31 * b12 + a32 * b22 + a33 * b32 + a34 * b42;
        elements[10] = a31 * b13 + a32 * b23 + a33 * b33 + a34 * b43;
        elements[14] = a31 * b14 + a32 * b24 + a33 * b34 + a34 * b44;

        elements[ 3] = a41 * b11 + a42 * b21 + a43 * b31 + a44 * b41;
        elements[ 7] = a41 * b12 + a42 * b22 + a43 * b32 + a44 * b42;
        elements[11] = a41 * b13 + a42 * b23 + a43 * b33 + a44 * b43;
        elements[15] = a41 * b14 + a42 * b24 + a43 * b34 + a44 * b44;

        return this;
    }

    /**
     * Multiply two matrices together and store the result in this matrix.
     * @param _a Matrix A.
     * @param _b Matrix B.
     * @return Matrix
     */
    inline public function multiplyMatrices(_a : Matrix, _b : Matrix) : Matrix
    {
        var ae = _a.elements;
        var be = _b.elements;
        var te = elements;

        var a11 = ae[0], a12 = ae[4], a13 = ae[8],  a14 = ae[12];
        var a21 = ae[1], a22 = ae[5], a23 = ae[9],  a24 = ae[13];
        var a31 = ae[2], a32 = ae[6], a33 = ae[10], a34 = ae[14];
        var a41 = ae[3], a42 = ae[7], a43 = ae[11], a44 = ae[15];

        var b11 = be[0], b12 = be[4], b13 = be[8],  b14 = be[12];
        var b21 = be[1], b22 = be[5], b23 = be[9],  b24 = be[13];
        var b31 = be[2], b32 = be[6], b33 = be[10], b34 = be[14];
        var b41 = be[3], b42 = be[7], b43 = be[11], b44 = be[15];

        te[ 0] = a11 * b11 + a12 * b21 + a13 * b31 + a14 * b41;
        te[ 4] = a11 * b12 + a12 * b22 + a13 * b32 + a14 * b42;
        te[ 8] = a11 * b13 + a12 * b23 + a13 * b33 + a14 * b43;
        te[12] = a11 * b14 + a12 * b24 + a13 * b34 + a14 * b44;

        te[ 1] = a21 * b11 + a22 * b21 + a23 * b31 + a24 * b41;
        te[ 5] = a21 * b12 + a22 * b22 + a23 * b32 + a24 * b42;
        te[ 9] = a21 * b13 + a22 * b23 + a23 * b33 + a24 * b43;
        te[13] = a21 * b14 + a22 * b24 + a23 * b34 + a24 * b44;

        te[ 2] = a31 * b11 + a32 * b21 + a33 * b31 + a34 * b41;
        te[ 6] = a31 * b12 + a32 * b22 + a33 * b32 + a34 * b42;
        te[10] = a31 * b13 + a32 * b23 + a33 * b33 + a34 * b43;
        te[14] = a31 * b14 + a32 * b24 + a33 * b34 + a34 * b44;

        te[ 3] = a41 * b11 + a42 * b21 + a43 * b31 + a44 * b41;
        te[ 7] = a41 * b12 + a42 * b22 + a43 * b32 + a44 * b42;
        te[11] = a41 * b13 + a42 * b23 + a43 * b33 + a44 * b43;
        te[15] = a41 * b14 + a42 * b24 + a43 * b34 + a44 * b44;

        return this;
    }

    /**
     * Multiply this matrix by a scalar value.
     * @param _v Scalar value.
     * @return Matrix
     */
    inline public function multiplyScalar(_v : Float) : Matrix
    {
        var e = elements;

        e[0] *= _v; e[4] *= _v; e[ 8] *= _v; e[12] *= _v;
        e[1] *= _v; e[5] *= _v; e[ 9] *= _v; e[13] *= _v;
        e[2] *= _v; e[6] *= _v; e[10] *= _v; e[14] *= _v;
        e[3] *= _v; e[7] *= _v; e[11] *= _v; e[15] *= _v;

        return this;
    }

    inline public function up() : Vector
    {
        return new Vector(elements[4], elements[5], elements[6]);
    }

    inline public function down() : Vector
    {
        return up().invert();
    }

    inline public function left() : Vector
    {
        return right().invert();
    }

    inline public function right() : Vector
    {
        return new Vector(elements[0], elements[1], elements[2]);
    }

    inline public function forward() : Vector
    {
        return backwards().invert();
    }

    inline public function backwards() : Vector
    {
        return new Vector(elements[8], elements[9], elements[10]);
    }

    // #endregion

    // #region Transformations

    /**
     * Return the position from this matrix into a vector.
     * @return Vector
     */
    inline public function getPosition() : Vector
    {
        return new Vector(elements[12], elements[13], elements[14]);
    }

    /**
     * Set the position in the matrix based on a vector.
     * @param _v Position vector.
     * @return Matrix
     */
    inline public function setPosition(_v : Vector) : Matrix
    {
        elements[12] = _v.x;
        elements[13] = _v.y;
        elements[14] = _v.z;

        return this;
    }

    /**
     * Sets this matrix to look at a point from a position.
     * @param _eye    The eye position.
     * @param _target The target position.
     * @param _up     Up vector.
     * @return Matrix
     */
    inline public function lookAt(_eye : Vector, _target : Vector, _up : Vector) : Matrix
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

        elements[0] = _x.x; elements[4] = _y.x; elements[ 8] = _z.x;
        elements[1] = _x.y; elements[5] = _y.y; elements[ 9] = _z.y;
        elements[2] = _x.z; elements[6] = _y.z; elements[10] = _z.z;

        return this;
    }

    /**
     * Sets this matrix to an identity matrix.
     * @return Matrix
     */
    inline public function identity() : Matrix
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
     * @return Matrix
     */
    inline public function make2D(_x : Float, _y : Float, _scale : Float = 1, _rotation : Float = 0) : Matrix
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
     * @return Matrix
     */
    inline public function makeTranslation(_x : Float, _y : Float, _z : Float) : Matrix
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
     * @return Matrix
     */
    inline public function makeRotationAxis(_axis : Vector, _angle : Float) : Matrix
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
     * @return Matrix
     */
    inline public function makeRotationX(_theta : Float) : Matrix
    {
        var c = Maths.cos(_theta);
        var s = Maths.sin(_theta);

        set(
            1,  0,  0,  0,
            0,  c, -s,  0,
            0,  s,  c,  0,
            0,  0,  0,  1
        );

        return this;
    }

    /**
     * Make a rotation around the y axis.
     * @param _theta Angle radians.
     * @return Matrix
     */
    inline public function makeRotationY(_theta : Float) : Matrix
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
     * @return Matrix
     */
    inline public function makeRotationZ(_theta : Float) : Matrix
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
     * @return Matrix
     */
    inline public function makeScale(_x : Float, _y : Float, _z : Float) : Matrix
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
    inline public function makeRotationFromEuler(_v : Vector, _order : ComponentOrder = XYZ) : Matrix
    {
        var me = elements;

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

                me[ 0] = c * e;
                me[ 4] = - c * f;
                me[ 8] = d;

                me[ 1] = af + be * d;
                me[ 5] = ae - bf * d;
                me[ 9] = - b * c;

                me[ 2] = bf - ae * d;
                me[ 6] = be + af * d;
                me[10] = a * c;
            case YXZ:
                var ce = c * e, cf = c * f, de = d * e, df = d * f;

                me[ 0] = ce + df * b;
                me[ 4] = de * b - cf;
                me[ 8] = a * d;

                me[ 1] = a * f;
                me[ 5] = a * e;
                me[ 9] = - b;

                me[ 2] = cf * b - de;
                me[ 6] = df + ce * b;
                me[10] = a * c;
            case ZXY:
                var ce = c * e, cf = c * f, de = d * e, df = d * f;

                me[ 0] = ce - df * b;
                me[ 4] = - a * f;
                me[ 8] = de + cf * b;

                me[ 1] = cf + de * b;
                me[ 5] = a * e;
                me[ 9] = df - ce * b;

                me[ 2] = - a * d;
                me[ 6] = b;
                me[10] = a * c;
            case ZYX:
                var ae = a * e, af = a * f, be = b * e, bf = b * f;

                me[ 0] = c * e;
                me[ 4] = be * d - af;
                me[ 8] = ae * d + bf;

                me[ 1] = c * f;
                me[ 5] = bf * d + ae;
                me[ 9] = af * d - be;

                me[ 2] = - d;
                me[ 6] = b * c;
                me[10] = a * c;
            case YZX:
                var ac = a * c, ad = a * d, bc = b * c, bd = b * d;

                me[ 0] = c * e;
                me[ 4] = bd - ac * f;
                me[ 8] = bc * f + ad;

                me[ 1] = f;
                me[ 5] = a * e;
                me[ 9] = - b * e;

                me[ 2] = - d * e;
                me[ 6] = ad * f + bc;
                me[10] = ac - bd * f;
            case XZY:
                var ac = a * c, ad = a * d, bc = b * c, bd = b * d;

                me[ 0] = c * e;
                me[ 4] = - f;
                me[ 8] = d * e;

                me[ 1] = ac * f + bd;
                me[ 5] = a * e;
                me[ 9] = ad * f - bc;

                me[ 2] = bc * f - ad;
                me[ 6] = b * e;
                me[10] = bd * f + ac;
        }

        me[ 3] = 0;
        me[ 7] = 0;
        me[11] = 0;

        me[12] = 0;
        me[13] = 0;
        me[14] = 0;
        me[15] = 1;

        return this;
    }

    /**
     * Creates a rotation matrix from a quaternion.
     * @param _q Quaternion containing the rotation.
     * @return Matrix
     */
    inline public function makeRotationFromQuaternion(_q : Quaternion) : Matrix
    {
        var me = elements;

        var x2 = _q.x + _q.x, y2 = _q.y + _q.y, z2 = _q.z + _q.z;
        var xx = _q.x * x2,   xy = _q.x * y2,   xz = _q.x *  z2;
        var yy = _q.y * y2,   yz = _q.y * z2,   zz = _q.z *  z2;
        var wx = _q.w * x2,   wy = _q.w * y2,   wz = _q.w *  z2;

        me[0] = 1 - ( yy + zz );
        me[4] = xy - wz;
        me[8] = xz + wy;

        me[1] = xy + wz;
        me[5] = 1 - ( xx + zz );
        me[9] = yz - wx;

        me[2] = xz - wy;
        me[6] = yz + wx;
        me[10] = 1 - ( xx + yy );

        // last column
        me[3] = 0;
        me[7] = 0;
        me[11] = 0;

        // bottom row
        me[12] = 0;
        me[13] = 0;
        me[14] = 0;
        me[15] = 1;

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
    inline public function makeFrustum(_left : Float, _right : Float, _bottom : Float, _top : Float, _near : Float, _far : Float) : Matrix
    {
        var me = elements;

        var tx = 2 * _near / (_right - _left);
        var ty = 2 * _near / (_top - _bottom);

        var a =  (_right + _left) / (_right - _left);
        var b =  (_top + _bottom) / (_top - _bottom);
        var c = -(_far + _near)   / (_far - _near);
        var d = -2 * _far * _near / (_far - _near);

        me[0] = tx;     me[4] = 0;      me[8]  = a;     me[12] = 0;
        me[1] = 0;      me[5] = ty;     me[9]  = b;     me[13] = 0;
        me[2] = 0;      me[6] = 0;      me[10] = c;     me[14] = d;
        me[3] = 0;      me[7] = 0;      me[11] = -1;    me[15] = 0;

        return this;
    }

    /**
     * Create a perspective matrix.
     * @param _fov    - Vertical FOV of this perspective.
     * @param _aspect - Aspect ratio.
     * @param _near   - near clipping.
     * @param _far    - far clipping.
     * @return Matrix
     */
    inline public function makePerspective(_fov : Float, _aspect : Float, _near : Float, _far : Float) : Matrix
    {
        var ymax = _near * Maths.tan( Maths.toRadians(_fov * 0.5) );
        var ymin = -ymax;
        var xmin = ymin * _aspect;
        var xmax = ymax * _aspect;

        return makeFrustum(xmin, xmax, ymin, ymax, _near, _far);
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
    inline public function makeOrthographic(_left : Float, _right : Float, _top : Float, _bottom : Float, _near : Float, _far : Float) : Matrix
    {
        var te = elements;

        var w = _right - _left;
        var h = _top - _bottom;
        var p = _far - _near;

        var tx = ( _right + _left )   / w;
        var ty = ( _top   + _bottom ) / h;
        var tz = ( _far   + _near )   / p;

        te[0] = 2 / w;  te[4] = 0;      te[ 8] = 0;      te[12] = -tx;
        te[1] = 0;      te[5] = 2 / h;  te[ 9] = 0;      te[13] = -ty;
        te[2] = 0;      te[6] = 0;      te[10] = -2 / p; te[14] = -tz;
        te[3] = 0;      te[7] = 0;      te[11] = 0;      te[15] = 1;

        return this;
    }

    // #endregion
}
