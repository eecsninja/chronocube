// Copyright (C) 2013 Simon Que
//
// This file is part of ChronoCube.
//
// ChronoCube is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ChronoCube is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ChronoCube.  If not, see <http://www.gnu.org/licenses/>.


// ChronoCube register sizes and addresses.


`ifndef _REGISTERS_VH_
`define _REGISTERS_VH_

`define REG_DATA_WIDTH 16

`define MAIN_CTRL_SIZE 5
`define MAIN_CTRL_ADDR 'h00

`define X_POS_SIZE 10
`define Y_POS_SIZE 10
`define X_POS_ADDR 'h08
`define Y_POS_ADDR 'h09

`define X_OFFSET_SIZE 10
`define Y_OFFSET_SIZE 10
`define X_OFFSET_ADDR 'h0c
`define Y_OFFSET_ADDR 'h0d

`endif  // _REGISTERS_VH_
