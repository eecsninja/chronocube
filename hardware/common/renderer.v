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
`include "registers.vh"

`define LINE_BUF_ADDR_WIDTH 10

module Renderer(clk, reset, reg_values,
                h_pos, v_pos, h_sync, v_sync,
                pal_clk, pal_addr, pal_data,
                map_clk, map_addr, map_data,
                _vram_en, _vram_rd, _vram_wr, _vram_be,
                vram_clk, vram_addr, vram_data,
                rgb_out);
  parameter VRAM_ADDR_BUS_WIDTH=16;
  parameter VRAM_DATA_BUS_WIDTH=16;
  parameter RGB_COLOR_DEPTH=18;
  localparam SCREEN_X_WIDTH=10;
  localparam SCREEN_Y_WIDTH=10;

  input clk;                      // System clock
  input reset;                    // Reset

  // Main register values
  input [`REG_DATA_WIDTH * `NUM_MAIN_REGS - 1 : 0] reg_values;

  input [SCREEN_X_WIDTH-1:0] h_pos;   // Current screen refresh coordinates
  input [SCREEN_Y_WIDTH-1:0] v_pos;
  output h_sync, v_sync;              // Sync signals

  // Decode video scanout position.
  wire h_blank, v_blank;
  wire h_sync_in, v_sync_in;
  wire [SCREEN_X_WIDTH-1:0] h_visible;
  wire [SCREEN_X_WIDTH-1:0] v_visible;
  DisplayTiming timing(.h_pos(h_pos),              .v_pos(v_pos),
                       .h_sync(h_sync_in),         .v_sync(v_sync_in),
                       .h_blank(h_blank),          .v_blank(v_blank),
                       .h_visible_pos(h_visible),  .v_visible_pos(v_visible));

  // Delay the vertical sync output by two horizontal lines to match the delayed
  // line buffer scanout.
  DisplayTiming delayed(.h_pos(h_pos),              .v_pos(v_pos - 2),
                        .h_sync(h_sync),            .v_sync(v_sync),
                        .h_blank(h_blank_delayed),  .v_blank(v_blank_delayed));

  wire h_blank_delayed;
  wire v_blank_delayed;

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
  assign _vram_rd = ~h_blank && ~v_blank;
  assign _vram_en = ~h_blank && ~v_blank;
  assign _vram_be = 2'b11;

  // Main register values.
  wire [`REG_DATA_WIDTH-1:0] reg_array [`NUM_MAIN_REGS-1:0];
  genvar i;
  generate
    for (i = 0; i < `NUM_MAIN_REGS; i = i + 1) begin : REGS
      assign reg_array[i] = reg_values[`REG_DATA_WIDTH * (i + 1) - 1:
                                       `REG_DATA_WIDTH * i];
    end
  endgenerate

  // TODO: complete the rendering pipeline.
  // For now, this setup uses contents of the tilemap RAM to look up palette
  // colors.  The palette color goes straight to the output.
  // TODO: create global functions or tasks for computing screen coordinates
  // from VGA counter values.
  wire [SCREEN_X_WIDTH-2:0] screen_x = h_visible / 2;
  wire [SCREEN_Y_WIDTH-2:0] screen_y = v_visible / 2;

  assign pal_clk = clk;
  assign map_clk = clk;
  assign vram_clk = clk;

  // The logic for drawing to the line buffer.
  `define STATE_IDLE     0
  `define STATE_DRAW     1
  reg [3:0] render_state;
  reg [`LINE_BUF_ADDR_WIDTH-2:0] render_x;
  // Handle y-scrolling.
  wire [`LINE_BUF_ADDR_WIDTH-2:0] render_y = screen_y + reg_array[`SCROLL_Y];

  always @ (posedge clk or posedge reset) begin
    if (reset)
      render_state <= `STATE_IDLE;
    else begin
      case (render_state)
      `STATE_IDLE:
        begin
          // Start drawing at the start of an even numbered on-screen scanline.
          if (h_pos == 0 && v_blank == 0 && v_visible[0] == 0) begin
            render_state <= `STATE_DRAW;
            render_x <= 0;
          end
        end
      `STATE_DRAW:
        begin
          // Stop drawing at the end of an odd numbered on-screen scanline.
          // TODO: create define for '800', the max 640x480 horizontal count.
          if (h_pos + 1 == 800 && v_visible[0] == 1)
            render_state <= `STATE_IDLE;
          // Stop drawing if the screen has been drawn.
          // TODO: direct drawing based on tile coordinates rather than screen
          // coordinates.
          // TODO: create define for '320', the horizontal image resolution.
          else if (render_x + 1 == 320)
            render_state <= `STATE_IDLE;
          else
            render_x <= render_x + 1;
        end
      endcase
    end
  end

  // Handle x-scrolling.
  wire [`LINE_BUF_ADDR_WIDTH-2:0] render_x_world =
      render_x + reg_array[`SCROLL_X];

  wire [4:0] map_x = render_x_world[8:4];
  wire [4:0] map_y = render_y[8:4];
  wire [3:0] tile_x = render_x_world[3:0];
  wire [3:0] tile_y = render_y[3:0];
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
  wire buf_wr = (render_state == `STATE_DRAW);
  wire [`LINE_BUF_ADDR_WIDTH-1:0] buf_addr;

  // Delay the line buffer write address by three cycles due to the tilemap ->
  // VRAM -> palette pipeline.
  CC_Delay #(.WIDTH(`LINE_BUF_ADDR_WIDTH), .DELAY(3))
      buf_addr_delay(.clk(clk),
                     .reset(reset),
                     .d({screen_y[0], render_x}),
                     .q(buf_addr));

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
      .rd_b(~(h_blank_delayed | v_blank_delayed)),
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
    if (h_blank_delayed | v_blank_delayed) begin
      rgb_out <= {`RGB_COLOR_DEPTH {1'b0}};
    end else begin
      rgb_out <= {buf_scanout_blue[7:2],
                  buf_scanout_green[7:2],
                  buf_scanout_red[7:2]};
    end
  end

endmodule
