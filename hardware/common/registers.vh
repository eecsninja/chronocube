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

// ChronoCube main register sizes and addresses.

`ifndef _REGISTERS_VH_
`define _REGISTERS_VH_

`define REG_DATA_WIDTH         16

`define ID                   'h00
`define OUTPUT_STATUS        'h01
`define SCAN_X               'h02
`define SCAN_Y               'h03

`define MODE_CTRL            'h04
`define MEM_CTRL             'h05
`define OUTPUT_CTRL          'h06
`define SPRITE_Z             'h07

`define SCROLL_X             'h0e
`define SCROLL_Y             'h0f

`define MAIN_REG_ADDR_BASE  'h000   // Start of main regs.
`define NUM_MAIN_REGS       'h010   // Length of main regs.
`define MAIN_REG_ADDR_WIDTH     8   // Width of address bus for |NUM_MAIN_REGS|.

`define REG_RW                  0   // Read-write register.
`define REG_RO                  1   // Read-only register.

`define ID_REG_VALUE       'h4343   // "CC" in ASCII, used to identify system.

`endif  // _REGISTERS_VH_
