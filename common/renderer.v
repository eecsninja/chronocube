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

`include "collision_buffer.vh"
`include "memory_map.vh"
`include "registers.vh"
`include "sprite_registers.vh"
`include "tile_registers.vh"

`define LINE_BUF_ADDR_WIDTH         10
`define BYTE_WIDTH                   8

`define SCREEN_WIDTH               640
`define SCREEN_HEIGHT              480
`define SCREEN_IMAGE_WIDTH         (`SCREEN_WIDTH / 2)
`define SCREEN_IMAGE_HEIGHT        (`SCREEN_HEIGHT / 2)

`define WORLD_WIDTH                512
`define WORLD_HEIGHT               512

//`define TEST_COLLISION_BUFFER
//`define TEST_COLLISION_REGIONS_ONLY

//`define SPRITE_LAYER_LEVEL           3  // TODO: use registers to specify level.
//`define SPRITE_LAYER_LEVEL           reg_array[`SPRITE_Z]

module Renderer(clk, reset, reg_values, tile_reg_values,
                h_pos, v_pos, h_sync, v_sync,
                pal_clk, pal_addr, pal_data,
                map_clk, map_addr, map_data,
                spr_clk, spr_addr, spr_data,
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

  // Sprite memory interface.
  output spr_clk;
  output [`SPRITE_ADDR_WIDTH-1:0] spr_addr;
  input [`SPRITE_DATA_WIDTH-1:0] spr_data;

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
  wire [`REG_DATA_WIDTH-1:0] tile_data_offset;
  wire [`REG_DATA_WIDTH-1:0] tile_offset_x;
  wire [`REG_DATA_WIDTH-1:0] tile_offset_y;

  TileRegDecoder tile_reg_decoder(
      .current_layer(current_tile_layer),
      .reg_values(tile_reg_values),
      .ctrl0(tile_ctrl0),
      .ctrl1(tile_ctrl1),
      .data_offset(tile_data_offset),
      .nop_value(tile_nop_value),
      .color_key(tile_color_key),
      .offset_x(tile_offset_x),
      .offset_y(tile_offset_y));

  // Sprite register decoding.
  wire [`REG_DATA_WIDTH-1:0] sprite_ctrl0;
  wire [`REG_DATA_WIDTH-1:0] sprite_ctrl1;
  wire [`REG_DATA_WIDTH-1:0] sprite_data_offset;
  wire [`REG_DATA_WIDTH-1:0] sprite_color_key;
  wire [`REG_DATA_WIDTH-1:0] sprite_offset_x;
  wire [`REG_DATA_WIDTH-1:0] sprite_offset_y;
  wire sprite_enabled;
  wire sprite_enable_scroll;
  wire sprite_enable_transp;
  wire sprite_enable_alpha;
  wire sprite_enable_color;
  wire sprite_flip_x;
  wire sprite_flip_y;
  wire sprite_flip_xy;
  wire [8:0] sprite_pal_index;
  wire [8:0] sprite_width;
  wire [8:0] sprite_height;
  SpriteRegDecoder sprite_reg_decoder(
      .reg_values(sprite_reg_values),

      .enabled(sprite_enabled),
      .enable_scroll(sprite_enable_scroll),
      .enable_transp(sprite_enable_transp),
      .enable_alpha(sprite_enable_alpha),
      .enable_color(sprite_enable_color),
      .flip_x(sprite_flip_x),
      .flip_y(sprite_flip_y),
      .flip_xy(sprite_flip_xy),
      .palette(sprite_pal_index),
      .width(sprite_width),
      .height(sprite_height),

      .ctrl0(sprite_ctrl0),
      .ctrl1(sprite_ctrl1),
      .data_offset(sprite_data_offset),
      .color_key(sprite_color_key),
      .offset_x(sprite_offset_x),
      .offset_y(sprite_offset_y));

  // The dimensions of the sprite as it is shown on the screen.  Takes diagonal
  // flipping into account.
  wire [8:0] sprite_render_width = sprite_flip_xy ? sprite_height
                                                   : sprite_width;
  wire [8:0] sprite_render_height = sprite_flip_xy ? sprite_width
                                                    : sprite_height;

  // Compute the offset of the sprite on the screen.
  // If sprite scrolling is enabled, then the world scroll offset is taken into
  // account; the sprite's offset is considered to be in world coordinates.
  // if sprite scrolling is disabled, then the sprite's offset is considered to
  // be in screen coordinates.
  wire [SCREEN_X_WIDTH-1:0] sprite_screen_offset_x =
      sprite_enable_scroll ? sprite_offset_x - reg_array[`SCROLL_X]
                           : sprite_offset_x;
  wire [SCREEN_Y_WIDTH-1:0] sprite_screen_offset_y =
      sprite_enable_scroll ? sprite_offset_y - reg_array[`SCROLL_Y]
                           : sprite_offset_y;

  wire [SCREEN_Y_WIDTH-2:0] sprite_top = sprite_screen_offset_y;
  wire [SCREEN_Y_WIDTH-2:0] sprite_bottom =
      sprite_screen_offset_y + sprite_render_height;

  // TODO: complete the rendering pipeline.
  // For now, this setup uses contents of the tilemap RAM to look up palette
  // colors.  The palette color goes straight to the output.
  // TODO: create global functions or tasks for computing screen coordinates
  // from VGA counter values.
  wire [SCREEN_X_WIDTH-2:0] screen_x = h_visible / 2;
  wire [SCREEN_Y_WIDTH-2:0] screen_y = v_visible / 2;

  // The y-coordinate in world space of the line currently being rendered.
  wire [SCREEN_Y_WIDTH-2:0] world_y = screen_y + reg_array[`SCROLL_Y];

  assign pal_clk = clk;
  assign map_clk = clk;
  assign vram_clk = clk;
  assign spr_clk = ~clk;

  // The logic for drawing to the line buffer.
  `define STATE_IDLE           0
  `define STATE_DECIDE         1
  `define STATE_DRAW_LAYER     2
  `define STATE_READ_SPRITE    3
  `define STATE_DRAW_SPRITE    4
  reg [3:0] render_state;
  reg [`LINE_BUF_ADDR_WIDTH-2:0] render_x;

  // For keeping track of what's been rendered.
  reg [4:0] num_layers_drawn;
  reg [8:0] num_sprites_drawn;
  reg [15:0] num_texels_drawn;
  reg [8:0] num_sprite_words_read;
  wire [4:0] current_tile_layer = num_layers_drawn;
  wire [`BYTE_WIDTH-1:0] current_sprite = num_sprites_drawn[`BYTE_WIDTH-1:0];
  assign spr_addr = {current_sprite, num_sprite_words_read[0]};

  reg [`NUM_SPRITE_REGS * `REG_DATA_WIDTH - 1 : 0] sprite_reg_values;

  always @ (posedge clk or posedge reset) begin
    if (reset) begin
      render_state <= `STATE_IDLE;
      sprite_reg_values <= 0;
    end else begin
      case (render_state)
      `STATE_IDLE:
        begin
          // Start drawing at the start of an even numbered on-screen scanline.
          if (h_pos == 0 && v_blank == 0 && v_visible[0] == 0) begin
            render_state <= `STATE_DECIDE;
            num_layers_drawn <= 0;
            num_sprites_drawn <= 0;
            num_texels_drawn <= 0;
            num_sprite_words_read <= 0;
          end
        end
      `STATE_DECIDE:
        begin
          // TODO: eventually this state will need to be removed for maximum
          // efficiency.  Deciding what to draw next should be immediate,
          // without having to go through an intermediate step.

          // Draw all layers.  The sprite layer's order relative to the tile
          // layers is hardcoded.
          // TODO: Make sprite layer more dynamic.
          //if (num_layers_drawn < `SPRITE_LAYER_LEVEL ||
          if (num_layers_drawn < reg_array[`SPRITE_Z] ||
              (num_layers_drawn < `NUM_TILE_LAYERS && num_sprites_drawn > 0))
          begin
            if (tile_ctrl0[`TILE_LAYER_ENABLED]) begin
              render_state <= `STATE_DRAW_LAYER;
              render_x <= 0;
            end
            // Skip to the next layer if the current one is disabled.
            else
              num_layers_drawn <= num_layers_drawn + 1;
          end
          // Draw sprites if all layers below it.
          //else if ((num_layers_drawn == `SPRITE_LAYER_LEVEL ||
          else if ((num_layers_drawn == reg_array[`SPRITE_Z] ||
                    num_layers_drawn == `NUM_TILE_LAYERS) &&
                   num_sprites_drawn < `NUM_SPRITES)
          begin
            render_state <= `STATE_READ_SPRITE;
            num_sprite_words_read <= 0;
          end
          // All done.
          else
            render_state <= `STATE_IDLE;

        end
      `STATE_DRAW_LAYER:
        begin
          // Stop drawing at the end of an odd numbered on-screen scanline.
          // TODO: create define for '800', the max 640x480 horizontal count.
          if (h_pos + 1 == 800 && v_visible[0] == 1) begin
            render_state <= `STATE_IDLE;
          end else if (render_x + 1 >= `SCREEN_IMAGE_WIDTH) begin
            // Stop drawing if the screen has been drawn.
            // TODO: direct drawing based on tile coordinates rather than screen
            // coordinates.
            render_state <= `STATE_DECIDE;
            num_layers_drawn <= num_layers_drawn + 1;
          end else begin
            render_x <= render_x + 1;
          end
        end
      `STATE_READ_SPRITE:
        begin
          if (num_sprites_drawn >= `NUM_SPRITES) begin
            render_state <= `STATE_DECIDE;
          end else if (num_sprite_words_read < 2) begin
            if (num_sprite_words_read == 0)
              sprite_reg_values[`SPRITE_DATA_WIDTH-1:0] <= spr_data;
            else if (num_sprite_words_read == 1)
              sprite_reg_values[`SPRITE_DATA_WIDTH*2-1:`SPRITE_DATA_WIDTH] <=
                  spr_data;
            num_sprite_words_read <= num_sprite_words_read + 1;
          end else begin
            // Skip sprite if it is:
            // 1. not enabled
            // 2. not on the current line (two cases):
            //    a. sprite does not cross y-boundary of the world
            //    b. sprite wraps around y-boundary of the world
            if (!sprite_enabled ||    // Condition #1
                (sprite_top <= sprite_bottom &&   // Condition #2a
                 (screen_y < sprite_top || screen_y >= sprite_bottom)) ||
                (sprite_top >= sprite_bottom &&   // Condition #2b
                 (screen_y >= sprite_bottom && screen_y < sprite_top))
                // TODO: Handle horizontal boundary checking as well.
                ) begin
              num_sprite_words_read <= 0;
              num_sprites_drawn <= num_sprites_drawn + 1;
            end else begin
              // TODO: do not render parts of sprite that are not visible
              // (either to the left or to the right of the visible area).
              render_state <= `STATE_DRAW_SPRITE;
              render_x <= 0;
            end
          end
        end
      `STATE_DRAW_SPRITE:
        begin
          if (render_x + 1 >= sprite_render_width) begin
            render_state <= `STATE_READ_SPRITE;
            num_sprites_drawn <= num_sprites_drawn + 1;
            num_sprite_words_read <= 0;
          end else begin
            render_x <= render_x + 1;
          end
        end
      endcase
    end
  end

  wire render_tiles = (render_state == `STATE_DRAW_LAYER);
  wire render_sprite = (render_state == `STATE_DRAW_SPRITE);
  reg render_tiles_delayed;
  reg render_sprite_delayed;
  always @ (posedge clk) begin
    render_tiles_delayed <= render_tiles;
    render_sprite_delayed <= render_sprite;
  end

  wire [`LINE_BUF_ADDR_WIDTH-2:0] tile_render_x = render_x;
  wire [`LINE_BUF_ADDR_WIDTH-2:0] tile_render_y =
      screen_y + reg_array[`SCROLL_Y] - tile_offset_y;
  wire [`LINE_BUF_ADDR_WIDTH-2:0] sprite_render_x =
      (render_x + sprite_screen_offset_x) % `WORLD_WIDTH;

  // Sprite rendering pipeline.

  // Location within the sprite to render from.
  reg [15:0] sprite_x;
  reg [15:0] sprite_y;

  // Location within the on-screen sprite currently being drawn.
  // Be sure to handle wraparound when |screen_y| < |sprite_screen_offset_y|.
  wire [15:0] sprite_render_y =
      (screen_y - sprite_screen_offset_y) % `WORLD_HEIGHT;
  wire [15:0] sprite_flipped_x = sprite_render_width - render_x - 1;
  wire [15:0] sprite_flipped_y = sprite_render_height - sprite_render_y - 1;

  // Start location of sprite data in VRAM.
  reg [`REG_DATA_WIDTH-1:0] sprite_vram_offset;
  // Delay by one clock to match the timing of the tile pipeline.  There is
  // no tilemap to read.
  always @ (posedge clk) begin
    if (~sprite_flip_xy) begin
      sprite_x <= sprite_flip_x ? sprite_flipped_x : render_x;
      sprite_y <= sprite_flip_y ? sprite_flipped_y : sprite_render_y;
    end else begin
      sprite_x <= sprite_flip_x ? sprite_flipped_y : sprite_render_y;
      sprite_y <= sprite_flip_y ? sprite_flipped_x : render_x;
    end

    sprite_vram_offset <= sprite_data_offset / 2;
  end
  // This assumes that the sprite data is not aligned to any power of two.
  wire [15:0] sprite_pixel_offset = sprite_y * sprite_width + sprite_x;

  // Tile rendering pipeline.

  // Handle x-scrolling.
  wire [`LINE_BUF_ADDR_WIDTH-2:0] render_x_world =
      tile_render_x + reg_array[`SCROLL_X] - tile_offset_x;

  wire tile_enable_8x8 = tile_ctrl0[`TILE_ENABLE_8x8];
  wire tile_enable_8_bit = tile_ctrl0[`TILE_ENABLE_8_BIT];

  reg [4:0] map_x;
  reg [5:0] map_y;
  reg [3:0] tile_x;
  reg [3:0] tile_y;

  always @ (render_x_world or tile_render_y or tile_enable_8x8) begin
    if (tile_enable_8x8) begin
      if (tile_enable_8_bit) begin
        // If reading tile map as 8-bits, the tile map is twice as wide.
        map_x <= render_x_world[7:3];
        map_y <= {tile_render_y[8:3], render_x_world[8]};
      end else begin
        map_x <= render_x_world[8:3];
        map_y <= tile_render_y[8:3];
      end
      tile_x <= render_x_world[2:0];
      tile_y <= tile_render_y[2:0];
    end else begin
      map_x <= render_x_world[8:4];
      map_y <= tile_render_y[8:4];
      tile_x <= render_x_world[3:0];
      tile_y <= tile_render_y[3:0];
    end
  end

  // Screen location -> map address
  assign map_addr =
        tile_enable_8_bit ? {current_tile_layer, map_y[5:0], map_x[4:1]}
                          : {current_tile_layer, map_y[4:0], map_x[4:0]};
  reg map_data_byte_select;
  always @ (posedge clk)
    map_data_byte_select <= map_x[0];

  // Handle tile flip bits, if flipping is enabled.
  // If not, all bits of the tile map data are used for the tile value.
  wire tile_enable_flip =
      tile_ctrl0[`TILE_ENABLE_FLIP] & ~tile_enable_8x8 & ~tile_enable_8_bit;
  wire tile_flip_x = tile_enable_flip & map_data[`TILE_FLIP_X_BIT];
  wire tile_flip_y = tile_enable_flip & map_data[`TILE_FLIP_Y_BIT];
  wire tile_flip_xy = tile_enable_flip & map_data[`TILE_FLIP_XY_BIT];
  wire [`TILEMAP_DATA_WIDTH-1:0] tile_value =
      tile_enable_8_bit
            ? (map_data_byte_select
                    ? map_data[`TILEMAP_DATA_WIDTH-1:`TILEMAP_DATA_WIDTH/2]
                    : map_data[`TILEMAP_DATA_WIDTH/2-1:0])
            : (tile_enable_flip ? (~`TILE_FLIP_BITS_MASK & map_data)
                                : map_data);

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
  reg [VRAM_ADDR_BUS_WIDTH-1:0] tile_vram_offset;
  always @ (posedge clk)
    tile_vram_offset <= tile_data_offset / 2;
  wire [`VRAM_ADDR_WIDTH-1:0] tile_vram_addr =
      tile_enable_8x8 ? {tile_value, tile_y_flipped[2:0], tile_x_flipped[2:1]}
                      : {tile_value, tile_y_flipped[3:0], tile_x_flipped[3:1]} +
      tile_vram_offset;
  wire [`VRAM_ADDR_WIDTH-1:0] sprite_vram_addr =
      sprite_pixel_offset[15:1] + sprite_vram_offset;
  assign vram_addr = render_tiles_delayed ? tile_vram_addr : sprite_vram_addr;

  wire vram_byte_select;
  CC_Delay #(.WIDTH(1), .DELAY(2))
      vram_byte_select_delay(
          .clk(clk),
          .reset(reset),
          .d(render_tiles_delayed ? tile_x_flipped[0] : sprite_pixel_offset[0]),
          .q(vram_byte_select));

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
  //   I use an extra delay.
  `define RENDER_DELAY 5

  // VRAM data -> palette address
  wire [`TILE_PALETTE_WIDTH-1:0] tile_pal_index =
      tile_ctrl0[`TILE_PALETTE_END:`TILE_PALETTE_START];
  wire [`TILE_PALETTE_WIDTH-1:0] pal_index_delayed;
  CC_Delay #(.WIDTH(`TILE_PALETTE_WIDTH), .DELAY(`RENDER_DELAY-2))
      pal_index_delay(.clk(clk),
                      .reset(reset),
                      .d(render_tiles ? tile_pal_index : sprite_pal_index),
                      .q(pal_index_delayed));
  // Prepend the palette index to the palette address.
  assign pal_addr =
      { pal_index_delayed,
        (vram_byte_select == 0) ? vram_data[7:0] : vram_data[15:8] };
  reg [RGB_COLOR_DEPTH-1:0] rgb_out;

  // Palette data -> Line buffer

  // Interface A: writing to the line buffer.
  wire [`LINE_BUF_ADDR_WIDTH-1:0] buf_addr;

  CC_Delay #(.WIDTH(`LINE_BUF_ADDR_WIDTH), .DELAY(`RENDER_DELAY))
      buf_addr_delay(
          .clk(clk),
          .reset(reset),
          .d({screen_y[0],
              render_tiles_delayed ? tile_render_x : sprite_render_x}),
          .q(buf_addr));

  wire [3:0] render_state_delayed;
  CC_Delay #(.WIDTH(3), .DELAY(`RENDER_DELAY))
      render_state_delay(.clk(clk),
                         .reset(reset),
                         .d(render_state),
                         .q(render_state_delayed));

  // Delayed sprite values.
  wire [`REG_DATA_WIDTH-1:0] sprite_ctrl0_delayed;
  wire [`REG_DATA_WIDTH-1:0] sprite_color_key_delayed;
  wire [`BYTE_WIDTH-1:0] current_sprite_delayed;
  CC_Delay #(.WIDTH(`REG_DATA_WIDTH), .DELAY(`RENDER_DELAY))
      sprite_ctrl0_delay(.clk(clk),
                         .reset(reset),
                         .d(sprite_ctrl0),
                         .q(sprite_ctrl0_delayed));
  CC_Delay #(.WIDTH(`REG_DATA_WIDTH), .DELAY(`RENDER_DELAY))
      sprite_color_key_delay(.clk(clk),
                             .reset(reset),
                             .d(sprite_color_key),
                             .q(sprite_color_key_delayed));
  CC_Delay #(.WIDTH(`BYTE_WIDTH), .DELAY(`RENDER_DELAY))
      current_sprite_delay(.clk(clk),
                           .reset(reset),
                           .d(current_sprite),
                           .q(current_sprite_delayed));

  // Delayed tile values.
  wire [`TILEMAP_DATA_WIDTH-1:0] tile_value_delayed;
  wire [`REG_DATA_WIDTH-1:0] tile_ctrl0_delayed;
  wire [`REG_DATA_WIDTH-1:0] tile_nop_value_delayed;
  wire [`REG_DATA_WIDTH-1:0] tile_color_key_delayed;
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

  // Delayed VRAM output.
  wire [7:0] pixel_value_delayed;
  CC_Delay #(.WIDTH(8), .DELAY(2))
      pixel_value_delay(.clk(clk),
                        .reset(reset),
                        .d(pal_addr[7:0]),
                        .q(pixel_value_delayed));

  wire tile_buf_wr = (render_state_delayed == `STATE_DRAW_LAYER) &&
                     !(tile_value_delayed == tile_nop_value_delayed &&
                       tile_ctrl0_delayed[`TILE_ENABLE_NOP]) &&
                     !(pixel_value_delayed == tile_color_key_delayed &&
                       tile_ctrl0_delayed[`TILE_ENABLE_TRANSP]);
  wire sprite_buf_wr = (render_state_delayed == `STATE_DRAW_SPRITE) &&
                       !(pixel_value_delayed == sprite_color_key_delayed &&
                         sprite_ctrl0_delayed[`SPRITE_ENABLE_TRANSP]);

  // The Palette memory module happens to be good for a line drawing buffer,
  // since its contents are of the same color format.
  Palette #(.NUM_CHANNELS(`NUM_PAL_CHANNELS)) line_buffer(
      .clk_a(clk),
      .wr_a(tile_buf_wr | sprite_buf_wr),
      .rd_a(0),
      .addr_a(buf_addr),
      .data_in_a(pal_data),
      .byte_en_a(3'b111),

      .clk_b(clk),
      .wr_b(h_visible[0] & v_visible[0]),  // Clear the old data for a new line.
      .rd_b(~(h_blank | v_blank_delayed)),
      .addr_b(buf_scanout_addr),
      .data_in_b(0),
      .data_out_b(buf_scanout_data)
      );

  // Sprite index buffer, for detecting collisions between sprites.
  // Writing sprite data to it parallels drawing sprites to the line buffer.
  wire [`COLL_DATA_WIDTH-1:0] sprite_buffer_out;
  wire [`COLL_DATA_WIDTH-1:0] sprite_buffer_write_location_out;
  CollisionBuffer sprite_buffer(
      .clk(clk),

      // Interface A.
      .wr_a(sprite_buf_wr),
      .addr_a(buf_addr),
      // The uppermost bit indicates a valid sprite pixel.
      .wr_data_a({1'b1, current_sprite_delayed}),
      .rd_data_a(sprite_buffer_write_location_out),

      // Interface B.
      .wr_b(h_visible[0] & v_visible[0]),  // Clear old data for a new line.
      .addr_b(buf_scanout_addr),
      .wr_data_b(0),
      .rd_data_b(sprite_buffer_out),
      );

  // The read value is valid one clock after the write value.  Use a delayed
  // write value to compare the two.
  reg sprite_buf_wr_delayed;
  reg [`BYTE_WIDTH-1:0] new_sprite_index;
  reg [`LINE_BUF_ADDR_WIDTH-1:0] buf_addr_delayed;
  always @ (posedge clk) begin
    sprite_buf_wr_delayed <= sprite_buf_wr;
    new_sprite_index <= current_sprite_delayed;
    buf_addr_delayed <= buf_addr;
  end

  wire existing_sprite_pixel_valid;
  wire [`BYTE_WIDTH-1:0] existing_sprite_index;
  assign {existing_sprite_pixel_valid, existing_sprite_index} =
      sprite_buffer_write_location_out;

  // A collision is detected if there's an existing sprite pixel and it doesn't
  // come from the same sprite as the new one.
  // TODO: The screen goes black if the logic for comparing old vs new sprite
  // is used.  Figure out why.
  // TODO: Implement actual collision table.
  wire sprite_collision = sprite_buf_wr_delayed & existing_sprite_pixel_valid;

  // Collision buffer, for recording data about collisions.
  wire [`COLL_DATA_WIDTH-1:0] collision_buffer_out;
  CollisionBuffer collision_buffer(
      .clk(clk),

      // Interface A.
      .wr_a(sprite_collision),
      .addr_a(buf_addr_delayed),
      // The uppermost bit indicates a valid sprite pixel.
      // TODO: Write actual collision information here, as opposed to just pixel
      // information.
      .wr_data_a({`COLL_DATA_WIDTH{1'b1}}),

      // Interface B.
      .wr_b(h_visible[0] & v_visible[0]),  // Clear old data for a new line.
      .addr_b(buf_scanout_addr),
      .wr_data_b(0),
      .rd_data_b(collision_buffer_out),
      );


  // Line buffer -> VGA output

  // Interface B: reading from the line buffer
  wire [`LINE_BUF_ADDR_WIDTH-1:0] buf_scanout_addr;
  // Make sure to scan out from the part of the buffer that was rendered to
  // the previous line.
  assign buf_scanout_addr = {~screen_y[0], screen_x};

  wire [`PAL_DATA_WIDTH-1:0] buf_scanout_data;
  reg [7:0] buf_scanout_red;
  reg [7:0] buf_scanout_green;
  reg [7:0] buf_scanout_blue;
  // Latch the line buffer output.  This is needed to preserve the line buffer
  // output after it gets cleared for a new line.
  // TODO: I got this to work properly after a bit of trial and error.  In the
  // future, this may need to be revisited to get a better understanding of how
  // it works.
  always @ (negedge clk) begin
`ifndef TEST_COLLISION_BUFFER
    buf_scanout_red = buf_scanout_data[7:0];
    buf_scanout_green = buf_scanout_data[15:8];
    buf_scanout_blue = buf_scanout_data[23:16];
`else
  `ifndef TEST_COLLISION_REGIONS_ONLY
    // Test the sprite buffer.
    `define BUFFER_TEST_BIT sprite_buffer_out[`COLL_DATA_WIDTH-1]
  `else
    // Test the collision buffer.
    `define BUFFER_TEST_BIT collision_buffer_out[`COLL_DATA_WIDTH-1]
  `endif  // defined(TEST_COLLISION_REGIONS_ONLY)
  // For testing the collision buffer, show the buffer contents as part of the
  // scanout.  Regions with sprite pixels are shown as grey.
  {buf_scanout_red, buf_scanout_green, buf_scanout_blue} =
      `BUFFER_TEST_BIT ? 'h7f7f7f : {buf_scanout_data[7:0],
                                     buf_scanout_data[15:8],
                                     buf_scanout_data[23:16]};
`endif  // defined(TEST_COLLISION_BUFFER)
  end

  always @ (negedge clk) begin
    if (h_blank_delayed | v_blank_delayed) begin
      rgb_out <= {RGB_COLOR_DEPTH {1'b0}};
    end else if (~h_visible[0]) begin
      rgb_out <= {buf_scanout_blue[7:2],
                  buf_scanout_green[7:2],
                  buf_scanout_red[7:2]};
    end
  end

endmodule
