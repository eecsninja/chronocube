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


// ChronoCube register sizes and addresses.


`ifndef _REGISTERS_VH_
`define _REGISTERS_VH_

`define REG_DATA_WIDTH 16

`define MAIN_CTRL_ADDR 5

`define X_POS_ADDR 'h08
`define Y_POS_ADDR 'h09

`define X_OFFSET_ADDR 'h0c
`define Y_OFFSET_ADDR 'h0d

`define MAIN_REG_ADDR_SPACE 'h100

`define REGISTER_RW 0         // Read-write register.
`define REGISTER_RO 1         // Read-only register.

// This function returns the register size in bits, given a register address.
// A zero size means there is no register at that address.
function register_info;
  input [31:0] address;

  integer width, type;
  begin
    case (address)
    `MAIN_CTRL_ADDR:  begin   width = 5;   type = `REGISTER_RW;  end
    `X_POS_ADDR:      begin   width = 10;  type = `REGISTER_RO;  end
    `Y_POS_ADDR:      begin   width = 10;  type = `REGISTER_RO;  end
    `X_OFFSET_ADDR:   begin   width = 10;  type = `REGISTER_RW;  end
    `Y_OFFSET_ADDR:   begin   width = 10;  type = `REGISTER_RW;  end
    default:          begin   width = 0;   type =            0;  end
    endcase

    register_info = width | (type << 16);
  end

endfunction

`endif  // _REGISTERS_VH_
