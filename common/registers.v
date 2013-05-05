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


// Primary control registers.

// Access to registers is asynchronous.  It is only controlled by the memory bus
// signals, and not by the system clock.

`include "registers.vh"
`include "tile_registers.vh"

module Register(reset, clk, en, be, d, q, value_in);
  parameter WIDTH=16;         // Number of bits in the register.
  parameter BUS_WIDTH=16;     // Width of data bus used to access register.
  parameter TYPE=`REG_RW;     // Register type: read/write, read-only, etc.

  input clk;        // System clock
  input reset;      // System reset
  input en;         // Access enable
  input [1:0] be;   // Byte enable

  input [BUS_WIDTH-1:0] d;      // Input and output ports.
  output [BUS_WIDTH-1:0] q;
  input [BUS_WIDTH-1:0] value_in;   // Read value for read-only registers.

  wire byte_lo_en = be[0];
  wire byte_hi_en = be[1];

  genvar i;
  generate
    if (TYPE == `REG_RW) begin
      for (i = 0; i < BUS_WIDTH; i = i + 1) begin: REG
        if (i < WIDTH) begin
          CC_DFlipFlop #(1) dff(.clk(clk),
                                .reset(reset),
                                .en(en & ((i < 8) ? byte_lo_en : byte_hi_en)),
                                .d(d[i]),
                                .q(q[i]));
        end else begin
          // Unused bits default to zero.
          assign q[i] = 1'b0;
        end
      end
    end else begin // if (TYPE == `REG_RO)
      // Read only register uses the |value_in| port.
      assign q = value_in;
    end
  endgenerate

endmodule

module Registers(reset, en, rd, wr, be, addr, data_in, data_out,
                 values_in, values_out);
  parameter ADDR_WIDTH=16;
  parameter DATA_WIDTH=16;
  parameter NUM_REGS=(1 << ADDR_WIDTH);
  parameter IS_GENERIC=1;

  input reset;      // System reset
  input en;         // Access enable
  input rd;         // Read enable
  input wr;         // Write enable
  input [1:0] be;   // Byte enable
  input [ADDR_WIDTH-1:0] addr;      // Address bus
  input [DATA_WIDTH-1:0] data_in;   // Data in bus
  output [DATA_WIDTH-1:0] data_out; // Data out bus

  // Port for obtaining read-only register values.
  input [DATA_WIDTH * NUM_REGS - 1 : 0] values_in;
  // Port for exposing all read/write register values.
  output [DATA_WIDTH * NUM_REGS - 1 : 0] values_out;

  // This function returns the register type, given a register address.
  function integer register_type;
    input [31:0] address;
    begin
      case (address)
        `ID:            register_type = `REG_RO;
        `OUTPUT_STATUS: register_type = `REG_RO;
        `SCAN_X:        register_type = `REG_RO;
        `SCAN_Y:        register_type = `REG_RO;

        `MODE_CTRL:     register_type = `REG_RW;
        `MEM_CTRL:      register_type = `REG_RW;
        `OUTPUT_CTRL:   register_type = `REG_RW;
        `SPRITE_Z:      register_type = `REG_RW;

        `SCROLL_X:      register_type = `REG_RW;
        `SCROLL_Y:      register_type = `REG_RW;

        default:        register_type = `REG_RO;
      endcase
    end

  endfunction

  function integer tile_reg_type;
    input [31:0] address;
    begin
      case (address)
        `TILE_CTRL0:          tile_reg_type = `REG_RW;
        `TILE_DATA_OFFSET:    tile_reg_type = `REG_RW;

        `TILE_NOP_VALUE:      tile_reg_type = `REG_RW;

        `TILE_COLOR_KEY:      tile_reg_type = `REG_RW;

        `TILE_OFFSET_X:       tile_reg_type = `REG_RW;
        `TILE_OFFSET_Y:       tile_reg_type = `REG_RW;

        default:              tile_reg_type = `REG_RO;
      endcase
    end

  endfunction

  // Generate the registers.
  wire [DATA_WIDTH-1:0] q_array [NUM_REGS - 1:0];
  genvar i;
  generate
    for (i = 0; i < NUM_REGS; i = i + 1) begin: REGS
      Register #(.WIDTH(DATA_WIDTH),
                 .TYPE(IS_GENERIC ? register_type(i) : tile_reg_type(i)))
          register(.clk(~wr),
                   .en(en & ~rd & (i == addr)),
                   .reset(reset),
                   .be(be),
                   .d(data_in),
                   .q(q_array[i]),
                   .value_in(values_in[DATA_WIDTH * (i + 1) - 1 :
                                       DATA_WIDTH * i]));
      assign values_out[DATA_WIDTH * (i + 1) - 1 : DATA_WIDTH * i] = q_array[i];
    end
  endgenerate

  // Memory bus data read.
  assign data_out = q_array[addr];

endmodule
