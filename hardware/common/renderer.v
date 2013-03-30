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


// Chronocube graphics engine
// TODO: implement scrolling.
// TODO: implement tilemaps.

`define PAL_ADDR_WIDTH 10
`define PAL_DATA_WIDTH 24
`define MPU_DATA_WIDTH 16
`define NUM_PAL_CHANNELS 3

module Renderer(clk, _reset, x, y, vblank, hblank,
                _vram_en, _vram_rd, _vram_wr, _vram_be,
                _pal_en, _pal_rd, _pal_wr, _pal_be, pal_addr,
                pal_data_in, pal_data_out,
                vram_addr, vram_data, rgb_out);
  parameter VRAM_ADDR_BUS_WIDTH=16;
  parameter VRAM_DATA_BUS_WIDTH=16;
  parameter RGB_COLOR_DEPTH=18;
  parameter SCREEN_X_WIDTH=10;
  parameter SCREEN_Y_WIDTH=10;

  input clk;                      // System clock
  input _reset;                   // Reset (active low)
  input [SCREEN_X_WIDTH-1:0] x;   // Current screen refresh coordinates
  input [SCREEN_Y_WIDTH-1:0] y;
  input hblank, vblank;           // Screen blanking signals

  // VRAM interface
  output wire _vram_en;         // Chip enable (active low)
  output wire _vram_rd;         // Read enable (active low)
  output wire _vram_wr;         // Write enable (active low)
  output wire [1:0] _vram_be;   // Byte enable (active low)

  output [VRAM_ADDR_BUS_WIDTH-1:0] vram_addr;     // Address bus
  input [VRAM_DATA_BUS_WIDTH-1:0] vram_data;      // Data bus

  // Palette interface
  input _pal_en;
  input _pal_wr;
  input _pal_rd;
  input [1:0] _pal_be;
  input [`PAL_ADDR_WIDTH-1:0] pal_addr;
  input [`MPU_DATA_WIDTH-1:0] pal_data_in;
  output [`MPU_DATA_WIDTH-1:0] pal_data_out;

  output wire [RGB_COLOR_DEPTH-1:0] rgb_out;      // Color output.

  wire [`PAL_ADDR_WIDTH-1:0] pal_addr_b;
  wire [`PAL_DATA_WIDTH-1:0] pal_data_b;
  wire [`NUM_PAL_CHANNELS-1:0] pal_byte_en;
  assign pal_byte_en[0] = (pal_addr[0] == 0) & ~_pal_be[0];
  assign pal_byte_en[1] = (pal_addr[0] == 0) & ~_pal_be[1];
  assign pal_byte_en[2] = (pal_addr[0] == 1) & ~_pal_be[0];
  wire [`NUM_PAL_CHANNELS * 8 - 1 : 0] pal_data_out_temp;
  assign pal_data_out = (pal_addr[0] == 0) ? pal_data_out_temp[15:0]
                                           : pal_data_out_temp[23:16];
  Palette #(.NUM_CHANNELS(`NUM_PAL_CHANNELS)) palette(
      .clk_a(clk),
      .wr_a(~_pal_wr & ~_pal_en),
      .rd_a(~_pal_rd & ~_pal_en),
      .addr_a(pal_addr >> 1),
      .data_in_a({pal_data_in, pal_data_in}),
      .data_out_a(pal_data_out_temp),
      .byte_en_a(pal_byte_en),
      .clk_b(clk),
      .wr_b(0),
      .rd_b(1),
      .addr_b(pal_addr_b),
      .data_in_b(0),
      .data_out_b(pal_data_b)
      );

  assign _vram_wr = 1'b0;
  assign _vram_rd = ~hblank && ~vblank;
  assign _vram_en = ~hblank && ~vblank;
  assign _vram_be = 2'b11;
  assign vram_addr = { y[9:2], x[9:2] };

  // TODO: Build Renderer here.
  CC_DFlipFlop #(VRAM_DATA_BUS_WIDTH)
      rgb_reg(.clk(clk),
              .en(_vram_en),
              .d(vram_data),
              .q(rgb_out[VRAM_DATA_BUS_WIDTH-1:0]));
  assign rgb_out[RGB_COLOR_DEPTH-1:RGB_COLOR_DEPTH-2] = 2'b0;

endmodule
