// Copyright (C) 2013 Simon Que
//
// This file is part of DuinoCube.
//
// DuinoCube is free software: you can redistribute it and/or modify
// it under the terms of the GNU Lesser General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// DuinoCube is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public License
// along with DuinoCube.  If not, see <http://www.gnu.org/licenses/>.


// Top-level DuinoCube module.

`include "collision.vh"
`include "memory_map.vh"
`include "registers.vh"
`include "sprite_registers.vh"
`include "tile_registers.vh"

`define MPU_ADDR_WIDTH 16
`define MPU_DATA_WIDTH 16

`define VRAM_DATA_WIDTH 16

`define RGB_COLOR_DEPTH 18

`define DISPLAY_HCOUNT_WIDTH 10
`define DISPLAY_VCOUNT_WIDTH 10

`define UNMAPPED_MEMORY_VALUE   'hdead

// The high/low memory space distinction is used to optimize the data readback
// path from each part of memory.
`define LOW_MEM_SIZE            'h1000

module Core(
    clk, reset, _int,
    mpu_rd, mpu_wr, mpu_en, mpu_be, mpu_addr_in, mpu_data_in, mpu_data_out,
    vram_en, vram_rd, vram_wr, vram_be, vram_addr, vram_data_in, vram_data_out,
    vga_vsync, vga_hsync, vga_rgb);

  input clk;                // System clock
  input reset;              // System reset

  input _int;               // Interrupt (active low)

  // MPU-side interface
  input mpu_en;             // Enable access
  input mpu_rd;             // Read enable
  input mpu_wr;             // Write enable
  input [1:0] mpu_be;       // Byte enable
  input [`MPU_ADDR_WIDTH-1:0] mpu_addr_in;        // Address bus
  input [`MPU_DATA_WIDTH-1:0] mpu_data_in;        // Data-in bus
  output [`MPU_DATA_WIDTH-1:0] mpu_data_out;      // Data-out bus

  // VRAM interface
  output vram_en;           // Enable access
  output vram_rd;           // Read enable
  output vram_wr;           // Write enable
  output [1:0] vram_be;     // Byte enable
  output reg  [`VRAM_ADDR_WIDTH-1:0] vram_addr;   // Address bus
  input [`VRAM_DATA_WIDTH-1:0] vram_data_in;      // Data input bus
  output [`VRAM_DATA_WIDTH-1:0] vram_data_out;    // Data output bus

  // VGA display interface
  // Note that Hsync and Vsync are active low for some modes and active high for
  // others.
  output vga_vsync;        // Hsync
  output vga_hsync;        // Vsync
  output [`RGB_COLOR_DEPTH-1:0] vga_rgb;   // RGB data

  // Memory banking
  // Break down the address input into page index and offset.
  wire [`PAGE_OFFSET_WIDTH-1:0] page_offset =
      mpu_addr_in[`PAGE_OFFSET_WIDTH-1:0];
  wire [`MPU_ADDR_WIDTH-`PAGE_OFFSET_WIDTH-1:0] page_index =
      mpu_addr_in >> `PAGE_OFFSET_WIDTH;

  // Map the second page using the bank register.
  wire [`INT_ADDR_WIDTH-1:0] mpu_addr;
  wire [7:0] bank_value = reg_array_out[`MEM_BANK];
  assign mpu_addr = { ((page_index == 0) ? {16'b0} : bank_value), page_offset };

  // VGA signal generator
  // Counters for the position of the refresh.
  wire [`DISPLAY_HCOUNT_WIDTH-1:0] h_pos;
  wire [`DISPLAY_VCOUNT_WIDTH-1:0] v_pos;
  DisplayController display(.clk(clk),
                            // TODO: Should the reset bit be used to reset this?
                            .reset(reset),
                            .h_pos(h_pos),
                            .v_pos(v_pos));

  wire [`MPU_DATA_WIDTH-1:0] pal_data_out;
  wire [`MPU_DATA_WIDTH-1:0] reg_data_out;

  wire [`MPU_DATA_WIDTH-1:0] low_mem_data_out;
  wire [`MPU_DATA_WIDTH-1:0] high_mem_data_out;

  // The data output of the memory interface has to select from the various
  // sources.  Using a nested conditional block seems to result in long paths
  // when compiling.  The solution is to break it into low/high memory, each
  // with its own nested conditionals.  Then, select the resulting data output
  // from one or the other.
  // TODO: Come up with a neater way to do this.
  wire low_mem_select = mpu_addr < `LOW_MEM_SIZE;
  assign mpu_data_out =
      (~mpu_rd | ~mpu_en) ? {`MPU_DATA_WIDTH {1'b0}}
                          : (low_mem_select ? low_mem_data_out
                                            : high_mem_data_out);
  assign low_mem_data_out = (main_regs_select   ? reg_data_out :
                            (tile_regs_select   ? tile_data_out :
                            (collision_select   ? coll_data_out :
                            (palette_select     ? pal_data_out :
                             `UNMAPPED_MEMORY_VALUE))));
  assign high_mem_data_out = (sprite_select     ? sprite_data_out :
                             (map_select        ? map_data_out :
                             (vram_select       ? vram_data_in :
                              `UNMAPPED_MEMORY_VALUE)));

  // Collision table interface.
  wire collision_select = (mpu_addr >= `COLL_ADDR_BASE) &
                          (mpu_addr < `COLL_ADDR_BASE + `COLL_ADDR_LENGTH);
  wire [`COLL_ADDR_WIDTH-1:0] coll_addr = (mpu_addr - `COLL_ADDR_BASE);
  wire [`MPU_DATA_WIDTH-1:0] coll_data_out;

  // Collision table.
  wire ren_coll_wr;
  wire [`COLL_ADDR_WIDTH-1:0] ren_coll_addr;
  wire [`COLL_DATA_WIDTH-1:0] ren_coll_data;
  CollisionTable collision_table(
      .clk(clk),
      .reset(master_reset),

      // Write to the collision buffer only when there's a collision.
      .write_collision(ren_coll_wr),
      // Write to the offset corresponding to the new sprite's index...
      .table_index(ren_coll_addr),
      // ... and the data written is the old sprite that was covered by the new
      // sprite.  The uppermost bit indicates that there is a valid entry.
      .table_value(ren_coll_data),

      // The MPU-side access port.
      .wr(mpu_wr & collision_select),
      .be(mpu_be),
      .addr(coll_addr),
      .data_in(mpu_data_in),
      .data_out(coll_data_out),
      );

  // Palette interface
  wire palette_select = (mpu_addr >= `PAL_ADDR_BASE) &
                        (mpu_addr < `PAL_ADDR_BASE + `PAL_ADDR_LENGTH);
  wire pal_wr = palette_select & mpu_wr;
  wire pal_rd = palette_select & mpu_rd;

  wire [`NUM_PAL_CHANNELS-1:0] pal_byte_en;
  assign pal_byte_en[0] = (mpu_addr[0] == 0) & mpu_be[0];
  assign pal_byte_en[1] = (mpu_addr[0] == 0) & mpu_be[1];
  assign pal_byte_en[2] = (mpu_addr[0] == 1) & mpu_be[0];

  wire [`NUM_PAL_CHANNELS*8-1:0] pal_data_out_temp;
  assign pal_data_out = (mpu_addr[0] == 0) ? pal_data_out_temp[15:0]
                                           : pal_data_out_temp[23:16];

  // Port B: to renderer
  wire ren_pal_clk;
  wire [`PAL_ADDR_WIDTH-1:0] ren_pal_addr;
  wire [`PAL_DATA_WIDTH-1:0] ren_pal_data;

  Palette #(.NUM_CHANNELS(`NUM_PAL_CHANNELS)) palette(
      .clk_a(clk),
      .wr_a(pal_wr),
      .rd_a(pal_rd),
      .addr_a(mpu_addr >> 1),
      .data_in_a({mpu_data_in, mpu_data_in}),
      .data_out_a(pal_data_out_temp),
      .byte_en_a(pal_byte_en),

      .clk_b(ren_pal_clk),
      .wr_b(0),
      .rd_b(1),
      .addr_b(ren_pal_addr),
      .data_in_b(0),
      .data_out_b(ren_pal_data)
      );

  // Sprite RAM
  wire sprite_select = (mpu_addr >= `SPRITE_ADDR_BASE) &
                       (mpu_addr < `SPRITE_ADDR_BASE + `SPRITE_ADDR_LENGTH);
  // This is an alias of all the sprite OFFSET_X and OFFSET_Y registers, mapped
  // to be contiguous.  It speeds up sprite location updates using sequential
  // memory access, since there is no need to send a new address before each
  // sprite.
  wire sprite_xy_select =
      (mpu_addr >= `SPRITE_XY_ADDR_BASE) &
      (mpu_addr < `SPRITE_XY_ADDR_BASE + `SPRITE_XY_ADDR_LENGTH);
  wire [`MPU_ADDR_WIDTH-1:0] sprite_xy_addr = mpu_addr - `SPRITE_XY_ADDR_BASE;
  // The sprite registers are grouped in pairs.
  wire [`MPU_ADDR_WIDTH-1:0] sprite_xy_index = sprite_xy_addr / 2;
  wire [`MPU_ADDR_WIDTH-1:0] sprite_xy_offset =
      (sprite_xy_addr % 2) ? `SPRITE_OFFSET_Y : `SPRITE_OFFSET_X;
  wire [`MPU_ADDR_WIDTH-1:0] sprite_xy_mapped_addr =
      sprite_xy_index * `NUM_SPRITE_REGS + sprite_xy_offset;

  // Select between the normal sprite registers or the aliased X/Y registers.
  wire [`MPU_ADDR_WIDTH-1:0] sprite_addr =
      sprite_select ? (mpu_addr - `SPRITE_ADDR_BASE)
                    : (sprite_xy_select ? sprite_xy_mapped_addr : 0);

  wire ren_spr_clk;
  wire [`SPRITE_ADDR_WIDTH-1:0] ren_spr_addr;
  wire [`SPRITE_DATA_WIDTH-1:0] ren_spr_data;
  wire [`SPRITE_DATA_WIDTH-1:0] ren_spr_data_out;
  wire [`MPU_DATA_WIDTH-1:0] sprite_data_out;

  sprite_ram_4Kx16 sprite_ram(
      .clock_a(clk),
      .address_a(sprite_addr),
      .byteena_a(mpu_be),
      .wren_a((sprite_select | sprite_xy_select) & mpu_wr & ~mpu_rd),
      .data_a(mpu_data_in),
      .q_a(sprite_data_out),

      .clock_b(ren_spr_clk),
      .address_b(ren_spr_addr),
      .data_b('bx),
      .wren_b(0),
      .q_b(ren_spr_data));

  // Tile map
  wire map_select = (mpu_addr >= `TILEMAP_ADDR_BASE) &
                    (mpu_addr < `TILEMAP_ADDR_BASE + `TILEMAP_ADDR_LENGTH);
  wire map_wr = map_select & mpu_wr;
  wire map_rd = map_select & mpu_rd;
  wire [1:0] map_be = mpu_be;
  wire [`MPU_DATA_WIDTH-1:0] map_data_out;

  // Port B: to renderer
  wire ren_map_clk;
  wire [`TILEMAP_ADDR_WIDTH-1:0] ren_map_addr;
  wire [`TILEMAP_DATA_WIDTH-1:0] ren_map_data;

  tilemap_ram_4Kx16 tilemap(
      .clock_a(clk),
      .address_a(mpu_addr),
      .byteena_a(map_be),
      .rden_a(map_rd),
      .wren_a(map_wr),
      .data_a(mpu_data_in),
      .q_a(map_data_out),

      .clock_b(ren_map_clk),
      .rden_b(1),
      .wren_b(0),
      .address_b(ren_map_addr),
      .data_b(0),
      .q_b(ren_map_data)
      );

  // VRAM interface logic
  wire vram_select = (mpu_addr >= `VRAM_ADDR_BASE) &
                     (mpu_addr < `VRAM_ADDR_BASE + `VRAM_ADDR_LENGTH);
  // Allow MPU access to VRAM only when the SYS_CTRL_VRAM_ACCESS bit is set.
  wire vram_uses_mpu = reg_array_out[`SYS_CTRL][`SYS_CTRL_VRAM_ACCESS];
  wire vram_en = vram_uses_mpu ? vram_uses_mpu : ren_vram_en;
  wire vram_wr = vram_uses_mpu ? mpu_wr : ren_vram_wr;
  wire vram_rd = vram_uses_mpu ? mpu_rd : ren_vram_rd;
  wire [1:0] vram_be = vram_uses_mpu ? mpu_be : ren_vram_be;
  always @ (posedge clk)
    vram_addr <= vram_uses_mpu ? (mpu_addr - `VRAM_ADDR_BASE) : ren_vram_addr;
  wire [`VRAM_DATA_WIDTH-1:0] vram_data_out =
      vram_uses_mpu ? mpu_data_in : {`VRAM_DATA_WIDTH {1'b0}};

  wire ren_vram_en;
  wire ren_vram_rd;
  wire ren_vram_wr;
  wire [1:0] ren_vram_be;
  wire [`VRAM_ADDR_WIDTH-1:0] ren_vram_addr;
  reg [`VRAM_DATA_WIDTH-1:0] ren_vram_data;
  always @ (posedge clk)
    ren_vram_data <= vram_uses_mpu ? 0 : vram_data_in;

  // Renderer
  // TODO: add switching between 16-bit full color and 8-bit palettes.
  Renderer renderer(.clk(clk),
                    .reset(master_reset),
                    .reg_values(reg_values_out),
                    .tile_reg_values(tile_reg_values),

                    .vram_en(ren_vram_en),
                    .vram_rd(ren_vram_rd),
                    .vram_wr(ren_vram_wr),
                    .vram_be(ren_vram_be),
                    .vram_addr(ren_vram_addr),
                    .vram_data(ren_vram_data),

                    .pal_clk(ren_pal_clk),
                    .pal_addr(ren_pal_addr),
                    .pal_data(ren_pal_data),

                    .map_clk(ren_map_clk),
                    .map_addr(ren_map_addr),
                    .map_data(ren_map_data),

                    .spr_clk(ren_spr_clk),
                    .spr_addr(ren_spr_addr),
                    .spr_data(ren_spr_data),

                    .coll_wr(ren_coll_wr),
                    .coll_addr(ren_coll_addr),
                    .coll_data(ren_coll_data),

                    .h_pos(h_pos),
                    .v_pos(v_pos),
                    .h_sync(vga_hsync),
                    .v_sync(vga_vsync),
                    .rgb_out(vga_rgb));

  // Values from the read/write registers.
  wire [`REG_DATA_WIDTH * `NUM_MAIN_REGS - 1 : 0] reg_values_out;
  wire [`REG_DATA_WIDTH-1:0] reg_array_out [`NUM_MAIN_REGS-1:0];
  genvar i;
  generate
    for (i = 0; i < `NUM_MAIN_REGS; i = i + 1) begin : OUT_REGS
      assign reg_array_out[i] = reg_values_out[`REG_DATA_WIDTH * (i + 1) - 1:
                                               `REG_DATA_WIDTH * i];
    end
  endgenerate

  // Use a register bit to reset the chip.
  reg reset_bit;
  // Delay it by one clock to avoid race condition.
  always @ (posedge clk or posedge reset) begin
    if (reset)
      reset_bit <= 0;
    else
      reset_bit <= reg_array_out[`SYS_CTRL][`SYS_CTRL_RESET];
  end
  wire master_reset = reset | reset_bit;

  // Values to the read-only registers.
  wire [`REG_DATA_WIDTH * `NUM_MAIN_REGS - 1 : 0] reg_values_in;
  wire [`REG_DATA_WIDTH-1:0] reg_array_in [`NUM_MAIN_REGS-1:0];
  generate
    for (i = 0; i < `NUM_MAIN_REGS; i = i + 1) begin : IN_REGS
      assign reg_values_in[`REG_DATA_WIDTH * (i + 1) - 1: `REG_DATA_WIDTH * i] =
         reg_array_in[i];
    end
  endgenerate

  // Assing ID value to ID register.
  assign reg_array_in[`ID] = `ID_REG_VALUE;

  // Output VGA status
  DisplayTiming timing(.h_pos(h_pos),
                       .v_pos(v_pos),
                       .h_sync(reg_array_in[`OUTPUT_STATUS][0]),
                       .v_sync(reg_array_in[`OUTPUT_STATUS][1]),
                       .h_blank(reg_array_in[`OUTPUT_STATUS][2]),
                       .v_blank(reg_array_in[`OUTPUT_STATUS][3]),
                       .h_visible_pos(reg_array_in[`SCAN_X]),
                       .v_visible_pos(reg_array_in[`SCAN_Y]));

  // Main registers.
  wire main_regs_select = (mpu_addr >= `MAIN_REG_ADDR_BASE) &
                          (mpu_addr < `MAIN_REG_ADDR_BASE + `NUM_MAIN_REGS);
  Registers #(.DATA_WIDTH(`REG_DATA_WIDTH),
              .ADDR_WIDTH(`MAIN_REG_ADDR_WIDTH),
              .NUM_REGS(`NUM_MAIN_REGS),
              .IS_GENERIC(1))
      registers(.clk(clk),
                .reset(master_reset),
                .en(main_regs_select),
                .rd(mpu_rd),
                .wr(mpu_wr),
                .be(mpu_be),
                .addr(mpu_addr[`MAIN_REG_ADDR_WIDTH-1:0]),
                .data_in(mpu_data_in),
                .data_out(reg_data_out),
                .values_in(reg_values_in),
                .values_out(reg_values_out));

  // Tile layer registers.
  wire tile_regs_select =
      (mpu_addr >= `TILE_REG_ADDR_BASE) &
      (mpu_addr < `TILE_REG_ADDR_BASE + `TILE_REG_ADDR_STEP * `NUM_TILE_LAYERS);
  wire [`NUM_TILE_LAYERS-1:0] tile_layer_reg_select;

  wire [`REG_DATA_WIDTH-1:0] tile_data_out_array[`NUM_TILE_LAYERS-1:0];
  wire [`NUM_REG_BITS_PER_TILE_LAYER-1:0]
      tile_values_out_array[`NUM_TILE_LAYERS-1:0];

  wire [`NUM_TOTAL_TILE_REG_BITS-1:0] tile_reg_values;
  generate
    for (i = 0; i < `NUM_TILE_LAYERS; i = i + 1) begin: TILE_REG_VALUES
      assign tile_reg_values[(i + 1) * `NUM_REG_BITS_PER_TILE_LAYER - 1:
                             i * `NUM_REG_BITS_PER_TILE_LAYER]
          = tile_values_out_array[i];
    end
  endgenerate

  reg [`REG_DATA_WIDTH-1:0] tile_data_out;
  wire [1:0] tile_index =
      mpu_addr[`TILE_BLOCK_ADDR_WIDTH+1:`TILE_BLOCK_ADDR_WIDTH];
  wire [`TILE_BLOCK_ADDR_WIDTH-1:0] tile_reg_addr =
      mpu_addr[`TILE_BLOCK_ADDR_WIDTH-1:0];
  always @ (*) begin
    if (~tile_regs_select) begin
      tile_data_out <= 'bx;
    end else begin
      if (tile_index < `NUM_TILE_REGISTERS)
        tile_data_out <= tile_data_out_array[tile_index];
      else
        tile_data_out <= 0;
    end
  end

  generate
    for (i = 0; i < `NUM_TILE_LAYERS; i = i + 1) begin: TILE_REG_SELECT
      assign tile_layer_reg_select[i] =
          tile_regs_select &
          (mpu_addr >= `TILE_REG_ADDR_BASE + i * `TILE_REG_ADDR_STEP) &
          (mpu_addr < `TILE_REG_ADDR_BASE +
                      i * `TILE_REG_ADDR_STEP +
                      `NUM_TILE_REGISTERS);
      Registers #(.DATA_WIDTH(`REG_DATA_WIDTH),
                  .ADDR_WIDTH(`TILE_REG_ADDR_WIDTH),
                  .NUM_REGS(`NUM_TILE_REGISTERS),
                  .IS_GENERIC(0))
          tile_registers(.clk(clk),
                         .reset(master_reset),
                         .en(tile_layer_reg_select[i]),
                         .rd(mpu_rd),
                         .wr(mpu_wr),
                         .be(mpu_be),
                         .addr(mpu_addr[`TILE_REG_ADDR_WIDTH-1:0]),
                         .data_in(mpu_data_in[`REG_DATA_WIDTH-1:0]),
                         .data_out(tile_data_out_array[i]),
                         .values_in(0),
                         .values_out(tile_values_out_array[i]));
    end
  endgenerate

endmodule
