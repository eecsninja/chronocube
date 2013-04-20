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
`include "tile_registers.vh"

`define LINE_BUF_ADDR_WIDTH 10
`define NUM_SPRITES 128

module Renderer(clk, reset, reg_values, tile_reg_values,
                h_pos, v_pos, h_sync, v_sync,
                pal_clk, pal_addr, pal_data,
                map_clk, map_addr, map_data,
                vram_en, vram_rd, vram_wr, vram_be,
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
  input [`NUM_TOTAL_TILE_REG_BITS-1:0] tile_reg_values;

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

  wire h_blank_delayed;
  wire v_blank_delayed;

  // Delay the vertical sync output by two horizontal lines to match the delayed
  // line buffer scanout.
  DisplayTiming v_delay(.h_pos(h_pos),
                        .v_pos(v_pos - 2),
                        .v_sync(v_sync),
                        .v_blank(v_blank_delayed));
  // Delay horizontal sync and blank by two clocks.  This is to to match the
  // scanout from the line buffer plus the registered RGB output.
  CC_Delay #(.WIDTH(2), .DELAY(2)) h_delay(.clk(clk),
                                           .reset(reset),
                                           .d({h_sync_in, h_blank}),
                                           .q({h_sync, h_blank_delayed}));

  // Palette interface
  output pal_clk;
  output [`PAL_ADDR_WIDTH-1:0] pal_addr;
  input [`PAL_DATA_WIDTH-1:0] pal_data;

  // Palette interface
  output map_clk;
  output [`TILEMAP_ADDR_WIDTH-1:0] map_addr;
  input [`TILEMAP_DATA_WIDTH-1:0] map_data;

  // VRAM interface
  output wire vram_en;         // Chip enable (active low)
  output wire vram_rd;         // Read enable (active low)
  output wire vram_wr;         // Write enable (active low)
  output wire [1:0] vram_be;   // Byte enable (active low)

  output vram_clk;
  output [VRAM_ADDR_BUS_WIDTH-1:0] vram_addr;     // Address bus
  input [VRAM_DATA_BUS_WIDTH-1:0] vram_data;      // Data bus

  output [RGB_COLOR_DEPTH-1:0] rgb_out;           // Color output.

  assign vram_wr = 1'b0;
  assign vram_rd = 1'b1;    // TODO: switch these off when not rendering.
  assign vram_en = 1'b1;
  assign vram_be = 2'b11;

  // Main register values.
  wire [`REG_DATA_WIDTH-1:0] reg_array [`NUM_MAIN_REGS-1:0];
  genvar i;
  generate
    for (i = 0; i < `NUM_MAIN_REGS; i = i + 1) begin : REGS
      assign reg_array[i] = reg_values[`REG_DATA_WIDTH * (i + 1) - 1:
                                       `REG_DATA_WIDTH * i];
    end
  endgenerate

  // Tile register logic.
  wire [`REG_DATA_WIDTH-1:0] tile_ctrl0;
  wire [`REG_DATA_WIDTH-1:0] tile_ctrl1;
  wire [`REG_DATA_WIDTH-1:0] tile_nop_value;
  wire [`REG_DATA_WIDTH-1:0] tile_color_key;
  TileRegDecoder tile_reg_decoder(
      .current_layer(current_tile_layer),
      .reg_values(tile_reg_values),
      .ctrl0(tile_ctrl0),
      .ctrl1(tile_ctrl1),
      .nop_value(tile_nop_value),
      .color_key(tile_color_key));

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
  `define STATE_IDLE           0
  `define STATE_DECIDE         1
  `define STATE_DRAW_LAYER     2
  `define STATE_DRAW_SPRITES   3
  reg [3:0] render_state;
  reg [`LINE_BUF_ADDR_WIDTH-2:0] render_x;
  // Handle y-scrolling.
  wire [`LINE_BUF_ADDR_WIDTH-2:0] render_y = screen_y + reg_array[`SCROLL_Y];

  // For keeping track of what's been rendered.
  reg [31:0] num_layers_drawn;
  reg [31:0] num_sprites_drawn;
  reg [31:0] num_texels_drawn;
  wire [31:0] current_tile_layer = num_layers_drawn;
  always @ (posedge clk or posedge reset) begin
    if (reset)
      render_state <= `STATE_IDLE;
    else begin
      case (render_state)
      `STATE_IDLE:
        begin
          // Start drawing at the start of an even numbered on-screen scanline.
          if (h_pos == 0 && v_blank == 0 && v_visible[0] == 0) begin
            render_state <= `STATE_DECIDE;
            num_layers_drawn <= 0;
            num_sprites_drawn <= 0;
            num_texels_drawn <= 0;
          end
        end
      `STATE_DECIDE:
        begin
          // TODO: eventually this state will need to be removed for maximum
          // efficiency.  Deciding what to draw next should be immediate,
          // without having to go through an intermediate step.

          // Draw layers.
          if (num_layers_drawn < 2 ||
              (num_layers_drawn < `NUM_TILE_LAYERS && num_sprites_drawn > 0))
          begin
            if (tile_ctrl0[`TILE_LAYER_ENABLED])
              render_state <= `STATE_DRAW_LAYER;
            // Skip to the next layer if the current one is disabled.
            else
              num_layers_drawn <= num_layers_drawn + 1;
          end
          // Draw sprites.
          else if (num_layers_drawn == 2 && num_sprites_drawn <= 0)
            render_state <= `STATE_DRAW_SPRITES;
          // All done.
          else
            render_state <= `STATE_IDLE;

          // Reset the render counter.
          render_x <= 0;
        end
      `STATE_DRAW_LAYER:
        begin
          // Stop drawing at the end of an odd numbered on-screen scanline.
          // TODO: create define for '800', the max 640x480 horizontal count.
          if (h_pos + 1 == 800 && v_visible[0] == 1) begin
            render_state <= `STATE_IDLE;
          end else if (render_x + 1 == 320) begin
            // Stop drawing if the screen has been drawn.
            // TODO: direct drawing based on tile coordinates rather than screen
            // coordinates.
            // TODO: create define for '320', the horizontal image resolution.
            render_state <= `STATE_DECIDE;
            num_layers_drawn <= num_layers_drawn + 1;
          end else begin
            render_x <= render_x + 1;
          end
        end
      `STATE_DRAW_SPRITES:
        begin
          // TODO: implement sprite drawing.
          num_sprites_drawn <= `NUM_SPRITES;
          render_state <= `STATE_DECIDE;
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
  assign map_addr = {current_tile_layer, map_y, map_x};

  // Handle tile flip bits, if flipping is enabled.
  // If not, all bits of the tile map data are used for the tile value.
  wire tile_enable_flip = tile_ctrl0[`TILE_ENABLE_FLIP];
  wire tile_flip_x = tile_enable_flip & map_data[`TILE_FLIP_X_BIT];
  wire tile_flip_y = tile_enable_flip & map_data[`TILE_FLIP_Y_BIT];
  wire tile_flip_xy = tile_enable_flip & map_data[`TILE_FLIP_XY_BIT];
  wire [`TILEMAP_DATA_WIDTH-1:0] tile_value =
      tile_enable_flip ? (~`TILE_FLIP_BITS_MASK & map_data) : map_data;

  reg [3:0] tile_x_reg;
  reg [3:0] tile_y_reg;
  always @ (posedge clk) begin
    tile_x_reg <= tile_x;
    tile_y_reg <= tile_y;
  end

  reg [3:0] tile_x_flipped;
  reg [3:0] tile_y_flipped;
  always @ (tile_flip_x or tile_flip_y or tile_flip_xy or
            tile_x_reg or tile_y_reg)
  begin
    if (tile_flip_xy) begin
      tile_x_flipped <= tile_flip_y ? ~tile_y_reg : tile_y_reg;
      tile_y_flipped <= tile_flip_x ? ~tile_x_reg : tile_x_reg;
    end else begin
      tile_x_flipped <= tile_flip_x ? ~tile_x_reg : tile_x_reg;
      tile_y_flipped <= tile_flip_y ? ~tile_y_reg : tile_y_reg;
    end
  end

  // Map data -> VRAM address
  assign vram_addr = {tile_value, tile_y_flipped, tile_x_flipped[3:1]};
  wire vram_byte_select;
  CC_Delay #(.WIDTH(1), .DELAY(2))
      vram_byte_select_delay(.clk(clk),
                             .reset(reset),
                             .d(tile_x_flipped[0]),
                             .q(vram_byte_select));

  // VRAM data -> palette address
  assign pal_addr = (vram_byte_select == 0) ? vram_data[7:0] : vram_data[15:8];
  reg [RGB_COLOR_DEPTH-1:0] rgb_out;

  // Palette data -> Line buffer

  // Interface A: writing to the line buffer.
  wire [`LINE_BUF_ADDR_WIDTH-1:0] buf_addr;

  // Delay the line buffer write address by five cycles due to the need for data
  // to pass through the rendering pipeline.
  // The five-clock delay is broken down as follows:
  // - Tile map RAM access
  // - Registered VRAM address
  // - Registered VRAM data
  //     TODO: In my current setup, VRAM requires its ports to be registered.
  //     My setup has 10cm wires between the FPGA and VRAM.  In a production
  //     system, there should be board traces instead of wires, and the traces
  //     should be shorter.  That might eliminate the need for VRAM ports to be
  //     registered.
  // - Palette access.
  // - Something else in the pipeline that I can't account for.  But it works if
  //   I use a delay of 3.
  `define RENDER_DELAY 5
  CC_Delay #(.WIDTH(`LINE_BUF_ADDR_WIDTH), .DELAY(`RENDER_DELAY))
      buf_addr_delay(.clk(clk),
                     .reset(reset),
                     .d({screen_y[0], render_x}),
                     .q(buf_addr));

  wire [3:0] render_state_delayed;
  wire [`TILEMAP_DATA_WIDTH-1:0] tile_value_delayed;
  wire [`REG_DATA_WIDTH-1:0] tile_ctrl0_delayed;
  wire [`REG_DATA_WIDTH-1:0] tile_nop_value_delayed;
  wire [`REG_DATA_WIDTH-1:0] tile_color_key_delayed;
  wire [7:0] pixel_value_delayed;
  CC_Delay #(.WIDTH(3), .DELAY(`RENDER_DELAY))
      render_state_delay(.clk(clk),
                         .reset(reset),
                         .d(render_state),
                         .q(render_state_delayed));
  CC_Delay #(.WIDTH(`REG_DATA_WIDTH), .DELAY(`RENDER_DELAY))
      tile_enable_nop_delay(.clk(clk),
                            .reset(reset),
                            .d(tile_ctrl0),
                            .q(tile_ctrl0_delayed));
  CC_Delay #(.WIDTH(`REG_DATA_WIDTH), .DELAY(`RENDER_DELAY))
      tile_nop_value_delay(.clk(clk),
                           .reset(reset),
                           .d(tile_nop_value[`TILEMAP_DATA_WIDTH-1:0]),
                           .q(tile_nop_value_delayed));
  CC_Delay #(.WIDTH(`REG_DATA_WIDTH), .DELAY(`RENDER_DELAY))
      tile_color_key_delay(.clk(clk),
                           .reset(reset),
                           .d(tile_color_key),
                           .q(tile_color_key_delayed));
  CC_Delay #(.WIDTH(`TILEMAP_DATA_WIDTH), .DELAY(`RENDER_DELAY-1))
      tile_value_delay(.clk(clk),
                       .reset(reset),
                       .d(map_data),
                       .q(tile_value_delayed));
  CC_Delay #(.WIDTH(8), .DELAY(2))
      pixel_value_delay(.clk(clk),
                        .reset(reset),
                        .d(pal_addr[7:0]),
                        .q(pixel_value_delayed));

  wire buf_wr = (render_state_delayed == `STATE_DRAW_LAYER) &&
                !(tile_value_delayed == tile_nop_value_delayed &&
                  tile_ctrl0_delayed[`TILE_ENABLE_NOP]) &&
                !(pixel_value_delayed == tile_color_key_delayed &&
                  tile_ctrl0_delayed[`TILE_ENABLE_TRANSP]);

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
      .rd_b(~(h_blank | v_blank_delayed)),
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
      rgb_out <= {RGB_COLOR_DEPTH {1'b0}};
    end else begin
      rgb_out <= {buf_scanout_blue[7:2],
                  buf_scanout_green[7:2],
                  buf_scanout_red[7:2]};
    end
  end

endmodule
