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

module GPU(clk, _reset, x, y, vblank, hblank,
           _vram_en, _vram_rd, _vram_wr, _vram_be,
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

  output wire [RGB_COLOR_DEPTH-1:0] rgb_out;      // Color output.

  assign _vram_wr = 1'b0;
  assign _vram_rd = ~hblank && ~vblank;
  assign _vram_en = ~hblank && ~vblank;
  assign _vram_be = 2'b11;
  assign vram_addr = { y[9:2], x[9:2] };

  // TODO: Build GPU here.
  CC_DFlipFlop #(VRAM_DATA_BUS_WIDTH)
      rgb_reg(.clk(clk),
              .en(_vram_en),
              .d(vram_data),
              .q(rgb_out[VRAM_DATA_BUS_WIDTH-1:0]));
  assign rgb_out[RGB_COLOR_DEPTH-1:RGB_COLOR_DEPTH-2] = 2'b0;

endmodule
