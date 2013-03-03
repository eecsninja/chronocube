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


// Primary control registers.

// Access to registers is asynchronous.  It is only controlled by the memory bus
// signals, and not by the system clock.

module Registers(reset, en, rd, wr, be, addr, data, values);
  parameter ADDR_WIDTH=8;
  parameter DATA_WIDTH=16;

  input reset;      // System reset
  input en;         // Access enable
  input rd;         // Read enable
  input wr;         // Write enable
  input [1:0] be;   // Byte enable
  input [ADDR_WIDTH-1:0] addr;    // Address bus
  inout [DATA_WIDTH-1:0] data;    // Data bus

  inout [1023:0] values;

  wire byte_lo_en = be[0];
  wire byte_hi_en = be[1];

  wire [7:0] data_lo, data_hi;
  assign {data_hi, data_lo} = data;

  wire [(1 << ADDR_WIDTH)-1:0] reg_select;
  CC_Decoder #(ADDR_WIDTH) address_decoder(.in(addr), .out(reg_select));

  // MAIN_CTRL: Main control register
  //  0 Enable output
  //  1 Enable MPU VRAM access
  //  2 Video mode [2]
  //  4 Take screenshot
  parameter MAIN_CTRL_SIZE=5;
  parameter MAIN_CTRL_ADDR='h00;
  wire [MAIN_CTRL_SIZE-1:0] main_ctrl_value;
  CC_DFlipFlop #(MAIN_CTRL_SIZE)
      main_ctrl_lo(.clk(~wr),
                   .en(en & ~rd & byte_lo_en & reg_select[MAIN_CTRL_ADDR]),
                   .reset(reset),
                   .d(data_lo),
                   .q(main_ctrl_value));

  // X_POS, Y_POS: display refresh coordinates
  // Read-only, not stored in register file.
  parameter X_POS_SIZE=10;
  parameter Y_POS_SIZE=10;
  parameter X_POS_ADDR='h08;
  parameter Y_POS_ADDR='h09;
  wire [X_POS_SIZE-1:0] x_pos_value;
  wire [Y_POS_SIZE-1:0] y_pos_value;
  assign x_pos_value = values[DATA_WIDTH * X_POS_ADDR + X_POS_SIZE - 1:
                              DATA_WIDTH * X_POS_ADDR];
  assign y_pos_value = values[DATA_WIDTH * Y_POS_ADDR + Y_POS_SIZE - 1:
                              DATA_WIDTH * Y_POS_ADDR];

  // X_OFFSET, Y_OFFSET: display offset
  parameter X_OFFSET_SIZE=10;
  parameter Y_OFFSET_SIZE=10;
  parameter X_OFFSET_ADDR='h0c;
  parameter Y_OFFSET_ADDR='h0d;
  wire [X_OFFSET_SIZE-1:0] x_offset_value;
  wire [Y_OFFSET_SIZE-1:0] y_offset_value;
  CC_DFlipFlop #(8)
      x_offset_lo(.clk(~wr),
                  .en(en & ~rd & byte_lo_en & reg_select[X_OFFSET_ADDR]),
                  .reset(reset),
                  .d(data_lo),
                  .q(x_offset_value[7:0]));
  CC_DFlipFlop #(X_OFFSET_SIZE-8)
      x_offset_hi(.clk(~wr),
                  .en(en & ~rd & byte_hi_en & reg_select[X_OFFSET_ADDR]),
                  .reset(reset),
                  .d(data_hi),
                  .q(x_offset_value[X_OFFSET_SIZE-1:8]));

  CC_DFlipFlop #(8)
      y_offset_lo(.clk(~wr),
                  .en(en & ~rd & byte_lo_en & reg_select[Y_OFFSET_ADDR]),
                  .reset(reset),
                  .d(data_lo),
                  .q(y_offset_value[7:0]));
  CC_DFlipFlop #(Y_OFFSET_SIZE-8)
      y_offset_hi(.clk(~wr),
                  .en(en & ~rd & byte_hi_en & reg_select[Y_OFFSET_ADDR]),
                  .reset(reset),
                  .d(data_hi),
                  .q(y_offset_value[Y_OFFSET_SIZE-1:8]));

  // Logic for reading the registers.
  reg [DATA_WIDTH-1:0] data_out;
  CC_Bidir #(DATA_WIDTH)
      data_io(.sel_in(~(rd & en & ~reset)),
              .io(data),
              .out(data_out));
  always @ (addr or main_ctrl_value or x_pos_value or y_pos_value or
            x_offset_value or y_offset_value)
  begin
    case(addr)
    MAIN_CTRL_ADDR: data_out <= main_ctrl_value;
    X_POS_ADDR:     data_out <= x_pos_value;
    Y_POS_ADDR:     data_out <= y_pos_value;
    X_OFFSET_ADDR:  data_out <= x_offset_value;
    Y_OFFSET_ADDR:  data_out <= y_offset_value;
    default:        data_out <= {{DATA_WIDTH} {1'b0}};
    endcase
  end
endmodule
