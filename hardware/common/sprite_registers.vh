// Copyright (C) 2013 Simon Que
//
// This file is part of ChronoCube.
//
// ChronoCube is free software: you can redistribute it and/or modify
// it under the terms of the GNU Lesser General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ChronoCube is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public License
// along with ChronoCube.  If not, see <http://www.gnu.org/licenses/>.

// ChronoCube sprite register sizes and addresses.

`ifndef _SPRITE_REGISTERS_VH_
`define _SPRITE_REGISTERS_VH_

`include "registers.vh"

`define NUM_SPRITES               128

// Number of registers for each sprite.
`define NUM_SPRITE_REGS             16

// Number of register bits per sprite.
`define NUM_REG_BITS_PER_SPRITE (`NUM_SPRITE_REGS * `REG_DATA_WIDTH)

// Register offsets within each register block.
`define SPRITE_CTRL0               'h00
`define SPRITE_CTRL1               'h01
`define SPRITE_DATA_OFFSET         'h03

`define SPRITE_REF_XY              'h04
`define SPRITE_COLOR_KEY           'h05

`define SPRITE_OFFSET_X            'h08
`define SPRITE_OFFSET_Y            'h09

`define SPRITE_ROT_ANGLE           'h08
`define SPRITE_ROT_X               'h0a
`define SPRITE_ROT_Y               'h0b

`define SPRITE_SCALE_X             'h0c
`define SPRITE_SCALE_Y             'h0d

// Register fields

// SPRITE_CTRL0
`define SPRITE_ENABLED             0
`define SPRITE_ENABLE_SCROLL       4
`define SPRITE_ENABLE_TRANSP       5
`define SPRITE_ENABLE_ALPHA        6
`define SPRITE_ENABLE_COLOR        7
`define SPRITE_FLIP_X              8
`define SPRITE_FLIP_Y              9
`define SPRITE_FLIP_XY            10

`define SPRITE_PALETTE_START      12
`define SPRITE_PALETTE_END        15
`define SPRITE_PALETTE_WIDTH  (`SPRITE_PALETTE_END - `SPRITE_PALETTE_START + 1)

// SPRITE_CTRL1
`define SPRITE_HSIZE_START         0
`define SPRITE_HSIZE_END           1
`define SPRITE_VSIZE_START         2
`define SPRITE_VSIZE_END           3
`define SPRITE_LAYER_HSIZE_0       4
`define SPRITE_LAYER_HSIZE_1       5
`define SPRITE_LAYER_VSIZE_0       6
`define SPRITE_LAYER_VSIZE_1       7


// SPRITE_REF_XY
`define SPRITE_REF_XY_X_START      0
`define SPRITE_REF_XY_X_END        5
`define SPRITE_REF_XY_X_WIDTH  \
    (`SPRITE_REF_XY_X_END - `SPRITE_REF_XY_X_START + 1)
`define SPRITE_REF_XY_Y_START      8
`define SPRITE_REF_XY_Y_END       13
`define SPRITE_REF_XY_Y_WIDTH  \
    (`SPRITE_REF_XY_Y_END - `SPRITE_REF_XY_Y_START + 1)

// Sprite register address definitions.
`define SPRITE_ADDR_BASE       'h1000  // Start at 8 KB.
`define SPRITE_ADDR_LENGTH     (`NUM_SPRITES * `NUM_SPRITE_REGS)

// Sprite access bus size.
`define SPRITE_ADDR_WIDTH           8
`define SPRITE_DATA_WIDTH         128

`endif  // _SPRITE_REGISTERS_VH_
