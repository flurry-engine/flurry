package;

class Shape
{
    /**
     * All of the tetromino shape definitions.
     */
    public static final SHAPE_DEFINITIONS = [
        [
            // I Block
            [
                [ 0, 0, 0, 0 ],
                [ 1, 1, 1, 1 ],
                [ 0, 0, 0, 0 ],
                [ 0, 0, 0, 0 ]
            ],
            [
                [ 0, 0, 1, 0 ],
                [ 0, 0, 1, 0 ],
                [ 0, 0, 1, 0 ],
                [ 0, 0, 1, 0 ]
            ],
            [
                [ 0, 0, 0, 0 ],
                [ 0, 0, 0, 0 ],
                [ 1, 1, 1, 1 ],
                [ 0, 0, 0, 0 ]
            ],
            [
                [ 0, 1, 0, 0 ],
                [ 0, 1, 0, 0 ],
                [ 0, 1, 0, 0 ],
                [ 0, 1, 0, 0 ]
            ]
        ],
        [
            // J Block
            [
                [ 2, 0, 0, 0 ],
                [ 2, 2, 2, 0 ],
                [ 0, 0, 0, 0 ],
                [ 0, 0, 0, 0 ]
            ],
            [
                [ 0, 2, 2, 0 ],
                [ 0, 2, 0, 0 ],
                [ 0, 2, 0, 0 ],
                [ 0, 0, 0, 0 ]
            ],
            [
                [ 0, 0, 0, 0 ],
                [ 2, 2, 2, 0 ],
                [ 0, 0, 2, 0 ],
                [ 0, 0, 0, 0 ]
            ],
            [
                [ 0, 2, 0, 0 ],
                [ 0, 2, 0, 0 ],
                [ 2, 2, 0, 0 ],
                [ 0, 0, 0, 0 ]
            ]
        ],
        [
            // L Block
            [
                [ 0, 0, 3, 0 ],
                [ 3, 3, 3, 0 ],
                [ 0, 0, 0, 0 ],
                [ 0, 0, 0, 0 ]
            ],
            [
                [ 0, 3, 0, 0 ],
                [ 0, 3, 0, 0 ],
                [ 0, 3, 3, 0 ],
                [ 0, 0, 0, 0 ]
            ],
            [
                [ 0, 0, 0, 0 ],
                [ 3, 3, 3, 0 ],
                [ 3, 0, 0, 0 ],
                [ 0, 0, 0, 0 ]
            ],
            [
                [ 3, 3, 0, 0 ],
                [ 0, 3, 0, 0 ],
                [ 0, 3, 0, 0 ],
                [ 0, 0, 0, 0 ]
            ]
        ],
        [
            // O Block
            [
                [ 0, 4, 4, 0 ],
                [ 0, 4, 4, 0 ],
                [ 0, 0, 0, 0 ],
                [ 0, 0, 0, 0 ]
            ],
            [
                [ 0, 4, 4, 0 ],
                [ 0, 4, 4, 0 ],
                [ 0, 0, 0, 0 ],
                [ 0, 0, 0, 0 ]
            ],
            [
                [ 0, 4, 4, 0 ],
                [ 0, 4, 4, 0 ],
                [ 0, 0, 0, 0 ],
                [ 0, 0, 0, 0 ]
            ],
            [
                [ 0, 4, 4, 0 ],
                [ 0, 4, 4, 0 ],
                [ 0, 0, 0, 0 ],
                [ 0, 0, 0, 0 ]
            ]
        ],
        [
            // S Block
            [
                [ 0, 5, 5, 0 ],
                [ 5, 5, 0, 0 ],
                [ 0, 0, 0, 0 ],
                [ 0, 0, 0, 0 ]
            ],
            [
                [ 0, 5, 0, 0 ],
                [ 0, 5, 5, 0 ],
                [ 0, 0, 5, 0 ],
                [ 0, 0, 0, 0 ]
            ],
            [
                [ 0, 0, 0, 0 ],
                [ 0, 5, 5, 0 ],
                [ 5, 5, 0, 0 ],
                [ 0, 0, 0, 0 ]
            ],
            [
                [ 5, 0, 0, 0 ],
                [ 5, 5, 0, 0 ],
                [ 0, 5, 0, 0 ],
                [ 0, 0, 0, 0 ]
            ]
        ],
        [
            // T Block
            [
                [ 0, 6, 0, 0 ],
                [ 6, 6, 6, 0 ],
                [ 0, 0, 0, 0 ],
                [ 0, 0, 0, 0 ]
            ],
            [
                [ 0, 6, 0, 0 ],
                [ 0, 6, 6, 0 ],
                [ 0, 6, 0, 0 ],
                [ 0, 0, 0, 0 ]
            ],
            [
                [ 0, 0, 0, 0 ],
                [ 6, 6, 6, 0 ],
                [ 0, 6, 0, 0 ],
                [ 0, 0, 0, 0 ]
            ],
            [
                [ 0, 6, 0, 0 ],
                [ 6, 6, 0, 0 ],
                [ 0, 6, 0, 0 ],
                [ 0, 0, 0, 0 ]
            ]
        ],
        [
            // Z Block
            [
                [ 7, 7, 0, 0 ],
                [ 0, 7, 7, 0 ],
                [ 0, 0, 0, 0 ],
                [ 0, 0, 0, 0 ]
            ],
            [
                [ 0, 0, 7, 0 ],
                [ 0, 7, 7, 0 ],
                [ 0, 7, 0, 0 ],
                [ 0, 0, 0, 0 ]
            ],
            [
                [ 0, 0, 0, 0 ],
                [ 7, 7, 0, 0 ],
                [ 0, 7, 7, 0 ],
                [ 0, 0, 0, 0 ]
            ],
            [
                [ 0, 7, 0, 0 ],
                [ 7, 7, 0, 0 ],
                [ 7, 0, 0, 0 ],
                [ 0, 0, 0, 0 ]
            ]
        ]
    ];

    /**
     * The current tetromino definition array.
     */
    public var shape (get, never) : Array<Array<Int>>;

    inline function get_shape() : Array<Array<Int>> {
        return shapes[index];
    }

    /**
     * The row the top left of the tetromino is located at.
     */
    public var row : Int;

    /**
     * The column the top left of the tetromino is located at.
     */
    public var col : Int;

    /**
     * All four of this tetrominoes rotations.
     */
    var shapes : Array<Array<Array<Int>>>;

    /**
     * The current index to find the correct tetromino rotation.
     */
    var index : Int;

    public function new()
    {
        index  = 0;
        shapes = SHAPE_DEFINITIONS[Std.random(SHAPE_DEFINITIONS.length - 1)];

        row = 0;
        col = 3;
    }

    /**
     * Rotate this tetromino clockwise 90 degrees.
     */
    public function cw()
    {
        index + 1 > shapes.length - 1 ? index = 0 : index++;
    }

    /**
     * Rotate this tetromino counter-clockwise 90 degrees.
     */
    public function ccw()
    {
        index - 1 < 0 ? index = shapes.length - 1 : index--;
    }

    /**
     * Return the tetromino definition if it were to be rotated clockwise 90 degrees.
     * @return Array<Array<Int>>
     */
    public function fetchCW() : Array<Array<Int>>
    {
        var cwIndex = index + 1;
        cwIndex + 1 > shapes.length - 1 ? cwIndex = 0 : cwIndex++;

        return shapes[cwIndex];
    }

    /**
     * Return the tetromino definition if it were to be rotated counter-clockwise 90 degrees.
     * @return Array<Array<Int>>
     */
    public function fetchCCW() : Array<Array<Int>>
    {
        var ccwIndex = index - 1;
        ccwIndex - 1 < 0 ? ccwIndex = shapes.length - 1 : ccwIndex--;

        return shapes[ccwIndex];
    }
}
