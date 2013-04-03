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

`include "memory_map.vh"

`define LINE_BUF_ADDR_WIDTH 10

module Renderer(clk, _reset, x, y, vblank, hblank,
                pal_clk, pal_addr, pal_data,
                map_clk, map_addr, map_data,
                _vram_en, _vram_rd, _vram_wr, _vram_be,
                vram_clk, vram_addr, vram_data,
                rgb_out);
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

  // Palette interface
  output pal_clk;
  output [`PAL_ADDR_WIDTH-1:0] pal_addr;
  input [`PAL_DATA_WIDTH-1:0] pal_data;

  // Palette interface
  output map_clk;
  output [`TILEMAP_ADDR_WIDTH-1:0] map_addr;
  input [`TILEMAP_DATA_WIDTH-1:0] map_data;

  // VRAM interface
  output wire _vram_en;         // Chip enable (active low)
  output wire _vram_rd;         // Read enable (active low)
  output wire _vram_wr;         // Write enable (active low)
  output wire [1:0] _vram_be;   // Byte enable (active low)

  output vram_clk;
  output [VRAM_ADDR_BUS_WIDTH-1:0] vram_addr;     // Address bus
  input [VRAM_DATA_BUS_WIDTH-1:0] vram_data;      // Data bus

  output [RGB_COLOR_DEPTH-1:0] rgb_out;           // Color output.

  assign _vram_wr = 1'b0;
  assign _vram_rd = ~hblank && ~vblank;
  assign _vram_en = ~hblank && ~vblank;
  assign _vram_be = 2'b11;

  // TODO: complete the rendering pipeline.
  // For now, this setup uses contents of the tilemap RAM to look up palette
  // colors.  The palette color goes straight to the output.
  // TODO: create global functions or tasks for computing screen coordinates
  // from VGA counter values.
  wire [SCREEN_X_WIDTH-2:0] screen_x = (x - 144) / 2;
  wire [SCREEN_Y_WIDTH-2:0] screen_y = (y - 35) / 2;

  assign pal_clk = ~clk;
  assign map_clk = ~clk;
  assign vram_clk = ~clk;

  wire [4:0] map_x = screen_x[8:4];
  wire [4:0] map_y = screen_y[8:4];
  wire [3:0] tile_x = screen_x[3:0];
  wire [3:0] tile_y = screen_y[3:0];
  // Screen location -> map address
  assign map_addr = {map_y, map_x};

  reg [3:0] tile_x_reg;
  reg [3:0] tile_y_reg;
  always @ (posedge clk) begin
    tile_x_reg <= tile_x;
    tile_y_reg <= tile_y;
  end

  // Map data -> VRAM address
  // TODO: unpack map entry fields.
  assign vram_addr = {map_data, tile_y_reg, tile_x_reg[3:1]};

  reg vram_byte_select;
  always @ (posedge clk) begin
    vram_byte_select <= tile_x_reg[0];
  end

  // VRAM data -> palette address
  CC_DFlipFlop #(`PAL_ADDR_WIDTH)
      rgb_reg(.clk(clk),
              .en(1),
              .d((vram_byte_select == 0) ? vram_data[7:0] : vram_data[15:8]),
              .q(pal_addr));
  reg [RGB_COLOR_DEPTH-1:0] rgb_out;

  // Palette data -> Line buffer

  // Interface A: writing to the line buffer.
  reg buf_wr;
  reg [`LINE_BUF_ADDR_WIDTH-1:0] buf_addr;

  // The logic for drawing to the line buffer.
  always @ (posedge clk) begin
    buf_wr <= ~(vblank | hblank);
    buf_addr <= {screen_y[0], screen_x};
  end

  // The Palette memory module happens to be good for a line drawing buffer,
  // since its contents are of the same color format.
  Palette #(.NUM_CHANNELS(`NUM_PAL_CHANNELS)) line_buffer(
      .clk_a(clk),
      .wr_a(buf_wr),
      .rd_a(0),
      .addr_a(buf_addr),
      .data_in_a(pal_data),
      .byte_en_a(3'b111),

      .clk_b(clk),
      .wr_b(0),
      .rd_b(1),
      .addr_b(buf_scanout_addr),
      .data_in_b(0),
      .data_out_b(buf_scanout_data)
      );

  // Line buffer -> VGA output

  // Interface B: reading from the line buffer
  wire [`LINE_BUF_ADDR_WIDTH-1:0] buf_scanout_addr;
  wire [`PAL_DATA_WIDTH-1:0] buf_scanout_data;
  // Make sure to scan out from the part of the buffer that was rendered to
  // the previous line.
  assign buf_scanout_addr = {~screen_y[0], screen_x};

  wire [7:0] buf_scanout_red = buf_scanout_data[7:0];
  wire [7:0] buf_scanout_green = buf_scanout_data[15:8];
  wire [7:0] buf_scanout_blue = buf_scanout_data[23:16];
  always @ (posedge clk) begin
    rgb_out <= {buf_scanout_blue[7:2],
                buf_scanout_green[7:2],
                buf_scanout_red[7:2]};
  end

endmodule
