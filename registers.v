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

module Register(reset, clk, en, be, d, q);
  parameter WIDTH=16;         // Number of bits in the register.
  parameter BUS_WIDTH=16;     // Width of data bus used to access register.

  input clk;        // System clock
  input reset;      // System reset
  input en;         // Access enable
  input [1:0] be;   // Byte enable

  input [BUS_WIDTH-1:0] d;      // Input and output ports.
  output [BUS_WIDTH-1:0] q;

  wire byte_lo_en = be[0];
  wire byte_hi_en = be[1];

  // Set up low byte.
  genvar i;
  generate
    for (i = 0; i < BUS_WIDTH; i = i + 1) begin: REG
      if (i < WIDTH) begin
        CC_DFlipFlop dff(.clk(clk),
                         .reset(reset),
                         .en(en & ((i < 8) ? byte_lo_en : byte_hi_en)),
                         .d(d[i]),
                         .q(q[i]));
      end else begin
        assign q[i] = 1'b0;
      end
    end
  endgenerate

endmodule

module Registers(reset, en, rd, wr, be, addr, data, values_in, values_out);
  parameter ADDR_WIDTH=8;
  parameter DATA_WIDTH=16;

  input reset;      // System reset
  input en;         // Access enable
  input rd;         // Read enable
  input wr;         // Write enable
  input [1:0] be;   // Byte enable
  input [ADDR_WIDTH-1:0] addr;    // Address bus
  inout [DATA_WIDTH-1:0] data;    // Data bus

  input [DATA_WIDTH * `MAIN_REG_ADDR_SPACE - 1 : 0] values_in;
  output [DATA_WIDTH * `MAIN_REG_ADDR_SPACE - 1 : 0] values_out;

  wire [DATA_WIDTH:0] q_array [`MAIN_REG_ADDR_SPACE - 1:0];

  wire [DATA_WIDTH-1:0] data_out;
  CC_Bidir #(DATA_WIDTH)
      data_io(.sel_in(~(rd & en & ~reset)),
              .io(data),
              .out(data_out));

  genvar i;
  generate
    for (i = 0; i < `MAIN_REG_ADDR_SPACE; i = i + 1) begin: REGS
      localparam integer size = register_info(i) & 8'hfff;
      localparam integer dir = register_info(i) >> 16;
      wire [DATA_WIDTH-1:0] data_in;
      wire [DATA_WIDTH-1:0] q;
      Register #(16) register(.clk(~wr),
                              .en(en & ~rd & (i == addr)),
                              .reset(reset),
                              .be(be),
                              .d((dir == `REGISTER_RW) ? data : data_in),
                              .q(q));

      assign q_array[i] = q;
      assign data_in = values_in[DATA_WIDTH * (i + 1) - 1 : DATA_WIDTH * i];
      assign values_out[DATA_WIDTH * (i + 1) - 1 : DATA_WIDTH * i] = q;
    end
  endgenerate

  assign data_out = (rd & en & ~reset) ? q_array[addr] : {DATA_WIDTH {1'bz}};

endmodule
