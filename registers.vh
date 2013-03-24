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
`define MEM_CTRL             'h01

`define OUTPUT_STATUS        'h08
`define OUTPUT_CTRL          'h09
`define COLOR_MODE           'h0a
`define VIDEO_MODE           'h0b

`define SCAN_X               'h0c
`define SCAN_Y               'h0d
`define SCROLL_X             'h0e
`define SCROLL_Y             'h0f

`define MAIN_REG_ADDR_BASE  'h000   // Start of main regs.
`define MAIN_REG_ADDR_LEN   'h100   // Length of main regs.

`define REGISTER_RW             0   // Read-write register.
`define REGISTER_RO             1   // Read-only register.

// This function returns the register size in bits, given a register address.
// A zero size means there is no register at that address.
function register_info;
  input [31:0] address;

  integer width, type;
  begin
    case (address)
      `ID:            begin   width = 16;  type = `REGISTER_RO;  end
      `MEM_CTRL:      begin   width = 16;  type = `REGISTER_RW;  end

      `OUTPUT_STATUS: begin   width = 16;  type = `REGISTER_RO;  end
      `OUTPUT_CTRL:   begin   width = 16;  type = `REGISTER_RW;  end
      `COLOR_MODE:    begin   width = 16;  type = `REGISTER_RW;  end
      `VIDEO_MODE:    begin   width = 16;  type = `REGISTER_RW;  end

      `SCAN_X:        begin   width = 16;  type = `REGISTER_RO;  end
      `SCAN_Y:        begin   width = 16;  type = `REGISTER_RO;  end
      `SCROLL_X:      begin   width = 16;  type = `REGISTER_RW;  end
      `SCROLL_Y:      begin   width = 16;  type = `REGISTER_RW;  end

      default:        begin   width = 0;   type =            0;  end
    endcase

    register_info = width | (type << 16);
  end

endfunction

`endif  // _REGISTERS_VH_
