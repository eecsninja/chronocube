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

// ChronoCube tile layer register sizes and addresses.

`ifndef _TILE_REGISTERS_VH_
`define _TILE_REGISTERS_VH_

`include "registers.vh"

`define TILE_CTRL0               'h00
`define TILE_CTRL1               'h01
`define TILE_PALETTE             'h02
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

`define NUM_TILE_REGISTERS         16
`define NUM_TILE_LAYERS             4

`define TILE_REG_ADDR_BASE     'h0400
`define TILE_REG_ADDR_STEP       'h40
`define TILE_REG_ADDR_WIDTH         4
`define TILE_BLOCK_ADDR_WIDTH       6

`endif  // _TILE_REGISTERS_VH_
