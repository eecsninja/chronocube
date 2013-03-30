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

`define TILE_CTRL                'h00
`define TILE_DATA_OFFSET         'h01
`define TILE_DISABLED_VALUE      'h02
`define TILE_PALETTE             'h03

`define TILE_OFFSET_X            'h04
`define TILE_OFFSET_Y            'h05

`define TILE_OFFSET_ALPHA        'h06

`define TILE_ROT_ANGLE           'h08
`define TILE_ROT_X               'h0a
`define TILE_ROT_Y               'h0b

`define TILE_SCALE_X             'h0c
`define TILE_SCALE_Y             'h0d
`define TILE_OFFSET_X            'h0e
`define TILE_OFFSET_Y            'h0f

`define TILE_REG_ADDR_BASE     'h0800
`define TILE_REG_ADDR_STEP       'h40

`endif  // _TILE_REGISTERS_VH_
