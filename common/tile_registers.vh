// Copyright (C) 2013 Simon Que
//
// This file is part of DuinoCube.
//
// DuinoCube is free software: you can redistribute it and/or modify
// it under the terms of the GNU Lesser General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// DuinoCube is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public License
// along with DuinoCube.  If not, see <http://www.gnu.org/licenses/>.

// DuinoCube tile layer register sizes and addresses.

`ifndef _TILE_REGISTERS_VH_
`define _TILE_REGISTERS_VH_

`include "registers.vh"

`define NUM_TILE_LAYERS             4

// Number of tile registers for each layer.
`define NUM_TILE_REGISTERS         16

// Number of tile register bits per layer.
`define NUM_REG_BITS_PER_TILE_LAYER  (`NUM_TILE_REGISTERS * `REG_DATA_WIDTH)

// Total number of bits in all the tile layer registers.
`define NUM_TOTAL_TILE_REG_BITS \
    (`NUM_TILE_LAYERS * `NUM_REG_BITS_PER_TILE_LAYER)

// Register offsets within each register block.
`define TILE_CTRL0               'h00
`define TILE_CTRL1               'h01
`define TILE_DATA_OFFSET         'h03

`define TILE_NOP_VALUE           'h04
`define TILE_COLOR_KEY           'h05

`define TILE_OFFSET_X            'h08
`define TILE_OFFSET_Y            'h09

`define TILE_ROT_ANGLE           'h08
`define TILE_ROT_X               'h0a
`define TILE_ROT_Y               'h0b

`define TILE_SCALE_X             'h0c
`define TILE_SCALE_Y             'h0d

// Register fields

// TILE_CTRL0
`define TILE_LAYER_ENABLED       0
// This is a temporary feature until TILE_(H|V)SIZE in TILE_CTRL1 are done.
`define TILE_ENABLE_8x8          1
`define TILE_ENABLE_8_BIT        2
`define TILE_ENABLE_NOP          3
`define TILE_ENABLE_SCROLL       4
`define TILE_ENABLE_TRANSP       5
`define TILE_ENABLE_ALPHA        6
`define TILE_ENABLE_COLOR        7
`define TILE_ENABLE_WRAP_X       8
`define TILE_ENABLE_WRAP_Y       9
`define TILE_ENABLE_FLIP        10
`define TILE_SHIFT_DATA_OFFSET  11

`define TILE_PALETTE_START      12
`define TILE_PALETTE_END        15
`define TILE_PALETTE_WIDTH  (`TILE_PALETTE_END - `TILE_PALETTE_START + 1)

// TILE_CTRL1
`define TILE_HSIZE_0             0
`define TILE_HSIZE_1             1
`define TILE_VSIZE_0             2
`define TILE_VSIZE_1             3
`define TILE_HSIZE_WIDTH         (`TILE_HSIZE_1 - `TILE_HSIZE_0 + 1)
`define TILE_VSIZE_WIDTH         (`TILE_VSIZE_1 - `TILE_VSIZE_0 + 1)

`define TILE_LAYER_HSIZE_0       4
`define TILE_LAYER_HSIZE_1       5
`define TILE_LAYER_VSIZE_0       6
`define TILE_LAYER_VSIZE_1       7

// TILE_DATA_OFFSET
`define TILE_INDEX_OFFSET_START  0
`define TILE_INDEX_OFFSET_END    7
`define TILE_IMAGE_OFFSET_START  8
`define TILE_IMAGE_OFFSET_END   15

// TILE_NOP_VALUE
`define TILE_NOP_VALUE_START     0
`define TILE_NOP_VALUE_END      12

// TILE_TRANSP_VALUE
`define TILE_TRANSP_VALUE_START  0
`define TILE_TRANSP_VALUE_END    7


// Tile register address definitions.
`define TILE_REG_ADDR_BASE     'h0080
`define TILE_REG_ADDR_STEP     'h0020
`define TILE_REG_ADDR_WIDTH         4
`define TILE_BLOCK_ADDR_WIDTH       5  // Must be large enough to hold values
                                       // from 0 to TILE_BLOCK_ADDR_WIDTH-1.

// Tile flip bits in a tilemap value.
`define TILE_FLIP_X_BIT             13
`define TILE_FLIP_Y_BIT             14
`define TILE_FLIP_XY_BIT            15
`define TILE_FLIP_BITS_MASK   ((1 << `TILE_FLIP_X_BIT) | \
                               (1 << `TILE_FLIP_Y_BIT) | \
                               (1 << `TILE_FLIP_XY_BIT))

// Number of bits by which to shift TILE_DATA_OFFSET reg, if
// TILE_SHIFT_DATA_OFFSET bit is set.
`define TILE_DATA_OFFSET_SHIFT       6

`endif  // _TILE_REGISTERS_VH_
