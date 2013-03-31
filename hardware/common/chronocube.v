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


// Top-level ChronoCube module.

`include "memory_map.vh"
`include "registers.vh"
`include "tile_registers.vh"

`define MPU_ADDR_WIDTH 16
`define MPU_DATA_WIDTH 16

`define VRAM_ADDR_WIDTH 16
`define VRAM_DATA_WIDTH 16

`define RGB_COLOR_DEPTH 18

`define DISPLAY_HCOUNT_WIDTH 10
`define DISPLAY_VCOUNT_WIDTH 10

`define MPU_DATA_WIDTH 16

module ChronoCube(clk, _reset, _int,
                  _mpu_rd, _mpu_wr, _mpu_en, _mpu_be,
                  mpu_addr, mpu_data_in, mpu_data_out,
                  _vram_en, _vram_rd, _vram_wr, _vram_be, vram_addr, vram_data,
                  vga_vsync, vga_hsync, vga_rgb);

  input clk;                // System clock

  input _reset;             // Reset (active low)
  input _int;               // Interrupt (active low)

  // MPU-side interface
  input _mpu_en;            // Enable access (active low)
  input _mpu_rd;            // Read enable (active low)
  input _mpu_wr;            // Write enable (active low)
  input [1:0] _mpu_be;      // Byte enable (active low)
  input [`MPU_ADDR_WIDTH-1:0] mpu_addr;           // Address bus
  input [`MPU_DATA_WIDTH-1:0] mpu_data_in;        // Data-in bus
  output [`MPU_DATA_WIDTH-1:0] mpu_data_out;      // Data-out bus

  // VRAM interface
  output _vram_en;          // Enable access (active low)
  output _vram_rd;          // Read enable (active low)
  output _vram_wr;          // Write enable (active low)
  output [1:0] _vram_be;    // Byte enable (active low)
  output [`VRAM_ADDR_WIDTH-1:0] vram_addr;   // Address bus
  inout [`VRAM_DATA_WIDTH-1:0]  vram_data;   // Data bus

  // VGA display interface
  // Note that Hsync and Vsync are active low for some modes and active high for
  // others.
  output vga_vsync;        // Hsync
  output vga_hsync;        // Vsync
  output [`RGB_COLOR_DEPTH-1:0] vga_rgb;   // RGB data

  // VGA signal generator
  // Counters for the position of the refresh.
  wire [`DISPLAY_HCOUNT_WIDTH-1:0] h_pos;
  wire [`DISPLAY_VCOUNT_WIDTH-1:0] v_pos;
  // Signals to indicate that refresh is in an off-screen area.
  wire hblank;
  wire vblank;
  DisplayController #(.HCOUNT_WIDTH(`DISPLAY_HCOUNT_WIDTH),
                      .VCOUNT_WIDTH(`DISPLAY_VCOUNT_WIDTH))
      display(.clk(clk),
              ._reset(_reset),
              .v_pos(v_pos),
              .h_pos(h_pos),
              .hsync(vga_hsync),
              .vsync(vga_vsync),
              .vblank(vblank),
              .hblank(hblank));

  // Graphics processor
  // TODO: add switching between 16-bit full color and 8-bit palettes.
  wire [`VRAM_ADDR_WIDTH-1:0] ren_bus_addr;
  wire [`VRAM_DATA_WIDTH-1:0] ren_bus_data;
  wire _ren_bus_en;
  wire _ren_bus_rd;
  wire _ren_bus_wr;
  wire [1:0] _ren_bus_be;
  wire [`RGB_COLOR_DEPTH-1:0] ren_rgb_out;

  wire [`MPU_DATA_WIDTH-1:0] pal_data_out;
  wire [`MPU_DATA_WIDTH-1:0] reg_data_out;
  assign mpu_data_out = (_mpu_rd | _mpu_en) ? {`MPU_DATA_WIDTH {1'b0}} :
                        (palette_select  ? pal_data_out :
                        (map_select      ? map_data_out :
                        (main_reg_select ? reg_data_out :
                        (vram_select     ? vram_data_out :
                        {`MPU_DATA_WIDTH {1'b0}}))));

  // Palette interface
  wire palette_select = (mpu_addr >= `PAL_ADDR_BASE) &
                        (mpu_addr < `PAL_ADDR_BASE + `PAL_ADDR_LENGTH);
  wire pal_wr = palette_select & ~_mpu_wr;
  wire pal_rd = palette_select & ~_mpu_rd;

  wire [`NUM_PAL_CHANNELS-1:0] pal_byte_en;
  assign pal_byte_en[0] = (mpu_addr[0] == 0) & ~_mpu_be[0];
  assign pal_byte_en[1] = (mpu_addr[0] == 0) & ~_mpu_be[1];
  assign pal_byte_en[2] = (mpu_addr[0] == 1) & ~_mpu_be[0];

  wire [`NUM_PAL_CHANNELS*8-1:0] pal_data_out_temp;
  assign pal_data_out = (mpu_addr[0] == 0) ? pal_data_out_temp[15:0]
                                           : pal_data_out_temp[23:16];

  // Port B: to renderer
  wire ren_pal_clk;
  wire ren_pal_rd;
  wire ren_pal_wr;
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
      .wr_b(ren_pal_wr),
      .rd_b(ren_pal_rd),
      .addr_b(ren_pal_addr),
      .data_in_b(0),
      .data_out_b(ren_pal_data)
      );

  // Tile map
  wire map_select = (mpu_addr >= `TILEMAP_ADDR_BASE) &
                    (mpu_addr < `TILEMAP_ADDR_BASE + `TILEMAP_ADDR_LENGTH);
  wire map_wr = map_select & ~_mpu_wr;
  wire map_rd = map_select & ~_mpu_rd;
  wire [1:0] map_be = ~_mpu_be;
  wire [`MPU_DATA_WIDTH-1:0] map_data_out;

  // Port B: to renderer
  wire ren_map_clk;
  wire ren_map_rd;
  wire ren_map_wr;
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
      .rden_b(ren_map_rd),
      .wren_b(ren_map_wr),
      .address_b(ren_map_addr),
      .data_b(0),
      .q_b(ren_map_data)
      );

  // Temporary internal VRAM
  // TODO: set up external VRAM interface.
  wire vram_select = (mpu_addr >= `VRAM_ADDR_BASE) &
                     (mpu_addr < `VRAM_ADDR_BASE + `VRAM_ADDR_LENGTH);
  wire [1:0] vram_be = ~_mpu_be;
  wire vram_rd = vram_select & ~_mpu_rd;
  wire vram_wr = vram_select & ~_mpu_wr;
  wire [`VRAM_DATA_WIDTH-1:0] vram_data_out;
  vram_8Kx16 temp_vram(
      .clock_a(clk),
      .address_a(mpu_addr),
      .byteena_a(vram_be),
      .rden_a(vram_rd),
      .wren_a(vram_wr),
      .data_a(mpu_data_in),
      .q_a(vram_data_out),
      );

  // Renderer
  Renderer renderer(.clk(clk),
                    ._reset(_reset),

                    ._vram_en(_ren_bus_en),
                    ._vram_rd(_ren_bus_rd),
                    ._vram_wr(_ren_bus_wr),
                    ._vram_be(_ren_bus_be),
                    .vram_addr(ren_bus_addr),
                    .vram_data(ren_bus_data),

                    .pal_clk(ren_pal_clk),
                    .pal_rd(ren_pal_rd),
                    .pal_wr(ren_pal_wr),
                    .pal_addr(ren_pal_addr),
                    .pal_data(ren_pal_data),

                    .map_clk(ren_map_clk),
                    .map_rd(ren_map_rd),
                    .map_wr(ren_map_wr),
                    .map_addr(ren_map_addr),
                    .map_data(ren_map_data),

                    .x(h_pos),
                    .y(v_pos),
                    .vblank(vblank),
                    .hblank(hblank),
                    .rgb_out(ren_rgb_out));

  wire [`REG_DATA_WIDTH * `NUM_MAIN_REGS - 1 : 0] reg_values;

  wire [`REG_DATA_WIDTH-1:0] reg_array [`NUM_MAIN_REGS-1:0];
  genvar i;
  generate
    for (i = 0; i < `NUM_MAIN_REGS; i = i + 1) begin : REGS
      assign reg_array[i] = reg_values[`REG_DATA_WIDTH * (i + 1) - 1:
                                       `REG_DATA_WIDTH * i];
    end
  endgenerate

  // Video output from renderer.
  assign vga_rgb = (hblank | vblank) ? {`RGB_COLOR_DEPTH {1'b0}} : ren_rgb_out;

  wire main_reg_select = (mpu_addr >= `MAIN_REG_ADDR_BASE) &
                         (mpu_addr < `MAIN_REG_ADDR_BASE + `NUM_MAIN_REGS);
  Registers #(.DATA_WIDTH(`REG_DATA_WIDTH),
              .ADDR_WIDTH(`MAIN_REG_ADDR_WIDTH),
              .NUM_REGS(`NUM_MAIN_REGS))
      registers(.reset(~_reset),
                .en(main_reg_select),
                .rd(~_mpu_rd),
                .wr(~_mpu_wr),
                .be(~_mpu_be),
                .addr(mpu_addr[`MAIN_REG_ADDR_WIDTH-1:0]),
                .data_in(mpu_data_in),
                .data_out(reg_data_out),
                .values_out(reg_values));

  // VRAM interface logic
  // TODO: the multiplexed VRAM access by both Renderer and MPU here may be too
  // simple.
  wire vram_uses_mpu = ~_mpu_en;
  assign _vram_en = vram_uses_mpu ? _mpu_en : _ren_bus_en;
  assign _vram_wr = vram_uses_mpu ? _mpu_wr : _ren_bus_wr;
  assign _vram_rd = vram_uses_mpu ? _mpu_rd : _ren_bus_rd;
  assign _vram_be = vram_uses_mpu ? _mpu_be : _ren_bus_be;
  assign vram_addr = vram_uses_mpu ? mpu_addr : ren_bus_addr;

  assign vram_data = vram_uses_mpu ? mpu_data_in : {`VRAM_DATA_WIDTH {1'bz}};
  assign ren_bus_data = vram_data;

endmodule
