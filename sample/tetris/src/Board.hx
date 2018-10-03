package;

typedef LineClear = {
    var startRow : Int;
    var length : Int;
}

class Board
{
    /**
     * The maximum number of rows in this tetris game board.
     */
    public final gridRows = 20;

    /**
     * The maximum number of columns in this tetris game board.
     */
    public final gridCols = 10;

    /**
     * Staggered array of all landed tetrominoes.
     */
    public final landed : Array<Array<Int>>;

    /**
     * The current tetromino controllable by the player.
     */
    public var active : Shape;

    public function new()
    {
        active = new Shape();
        landed = [
            [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ],
            [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ],
            [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ],
            [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ],
            [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ],
            [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ],
            [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ],
            [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ],
            [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ],
            [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ],
            [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ],
            [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ],
            [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ],
            [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ],
            [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ],
            [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ],
            [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ],
            [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ],
            [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ],
            [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ]
        ];
    }

    /**
     * Move the active tetromino a specific number of rows and columns.
     * @param _rowRel Number of rows to move.
     * @param _colRel Number of columns to move.
     */
    public function move(_rowRel : Int, _colRel : Int)
    {
        // Check to ensure we can move in the requested position.
        var canMove = true;
        for (row in 0...active.shape.length)
        {
            for (col in 0...active.shape[row].length)
            {
                if (active.shape[row][col] != 0 && !validPosition(active.row + row + _rowRel, active.col + col + _colRel))
                {
                    canMove = false;
                }
            }
        }

        if (canMove)
        {
            active.row += _rowRel;
            active.col += _colRel;
        }

        // Check to see if we've landed
        var haveLanded = false;
        for (row in 0...active.shape.length)
        {
            for (col in 0...active.shape[row].length)
            {
                if (active.shape[row][col] == 0)
                {
                    continue;
                }

                // Check to see if we've collided on the bottom of the grid.
                if (active.row + row >= landed.length - 1)
                {
                    haveLanded = true;

                    break;
                }

                // Check to see if we've collided with the grid.
                if (landed[active.row + row + 1][active.col + col] != 0)
                {
                    haveLanded = true;

                    break;
                }
            }
        }

        // If we've landed copy the shape into the board and create a new one.
        if (haveLanded)
        {
            for (row in 0...active.shape.length)
            {
                for (col in 0...active.shape[row].length)
                {
                    if (active.shape[row][col] != 0)
                    {
                        landed[active.row + row][active.col + col] = active.shape[row][col];
                    }
                }
            }

            active = new Shape();
        }

        naiveGravity(cleanLines());
    }

    /**
     * Rotate the active tetromino clockwise 90 degrees.
     */
    public function cw()
    {
        var rotation  = active.fetchCW();
        var canRotate = true;

        for (row in 0...active.shape.length)
        {
            for (col in 0...active.shape[row].length)
            {
                if (rotation[row][col] != 0 && !validPosition(active.row + row, active.col + col))
                {
                    canRotate = false;
                }
            }
        }

        if (canRotate)
        {
            active.cw();
        }
    }

    /**
     * Rotate the active tetromino counter-clockwise 90 degrees.
     */
    public function ccw()
    {
        var rotation  = active.fetchCCW();
        var canRotate = true;

        for (row in 0...active.shape.length)
        {
            for (col in 0...active.shape[row].length)
            {
                if (rotation[row][col] != 0 && !validPosition(active.row + row, active.col + col))
                {
                    canRotate = false;
                }
            }
        }

        if (canRotate)
        {
            active.ccw();
        }
    }

    /**
     * Returns if the specified position is a valid to move into.
     * @param _row Row
     * @param _col Column
     * @return Bool
     */
    function validPosition(_row : Int, _col : Int) : Bool
    {
        return (withinGrid(_row, _col) && landed[_row][_col] == 0);
    }

    /**
     * Returns if the specified position is within the tetris grid.
     * @param _row Row
     * @param _col Column
     */
    function withinGrid(_row : Int, _col : Int)
    {
        return (_row >= 0 && _row < gridRows && _col >= 0 && _col < gridCols);
    }

    /**
     * Clear all completed lines from the grid.
     * @return LineClear
     */
    function cleanLines() : LineClear
    {
        var info : LineClear = { startRow : -1, length : 0 };

        for (row in 0...gridRows)
        {
            var rowComplete = true;

            for (col in 0...gridCols)
            {
                if (landed[row][col] == 0)
                {
                    rowComplete = false;

                    break;
                }
            }

            if (rowComplete)
            {
                if (info.startRow == -1)
                {
                    info.startRow = row;
                }
                
                info.length++;

                for (col in 0...gridCols)
                {
                    landed[row][col] = 0;
                }
            }
        }

        return info;
    }

    /**
     * Apply gravity to shapes based on cleared lines.
     * All non empty cells above the cleard line will be moved down by the number of lines clear.
     * @param _info Line clear information.
     */
    function naiveGravity(_info : LineClear)
    {
        if (_info.length == 0) return;

        var row = _info.startRow - 1;
        while (row >= 0)
        {
            for (col in 0...landed[row].length)
            {
                if (landed[row][col] == 0) continue;

                landed[row + _info.length][col] = landed[row][col];
                landed[row][col] = 0;
            }

            row--;
        }
    }
}
