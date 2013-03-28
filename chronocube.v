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

`include "registers.vh"

`define MPU_ADDR_WIDTH 16
`define MPU_DATA_WIDTH 16

`define VRAM_ADDR_WIDTH 16
`define VRAM_DATA_WIDTH 16

`define RGB_COLOR_DEPTH 18

`define DISPLAY_HCOUNT_WIDTH 10
`define DISPLAY_VCOUNT_WIDTH 10

module ChronoCube(clk, _reset, _int,
                  _mpu_rd, _mpu_wr, _mpu_en, _mpu_be, mpu_addr, mpu_data,
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
  input [`MPU_ADDR_WIDTH-1:0] mpu_addr;  // Address bus
  inout [`MPU_DATA_WIDTH-1:0] mpu_data;  // Data bus

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
  wire [`VRAM_ADDR_WIDTH-1:0] gpu_bus_addr;
  wire [`VRAM_DATA_WIDTH-1:0] gpu_bus_data;
  wire _gpu_bus_en;
  wire _gpu_bus_rd;
  wire _gpu_bus_wr;
  wire [1:0] _gpu_bus_be;
  wire [`RGB_COLOR_DEPTH-1:0] gpu_rgb_out;
  GPU gpu(.clk(clk),
          ._reset(_reset),
          ._vram_en(_gpu_bus_en),
          ._vram_rd(_gpu_bus_rd),
          ._vram_wr(_gpu_bus_wr),
          ._vram_be(_gpu_bus_be),
          .vram_addr(gpu_bus_addr),
          .vram_data(gpu_bus_data),
          .x(h_pos),
          .y(v_pos),
          .vblank(vblank),
          .hblank(hblank),
          .rgb_out(gpu_rgb_out));

  wire [`REG_DATA_WIDTH * `NUM_MAIN_REGS - 1 : 0] reg_values;

  wire [`REG_DATA_WIDTH-1:0] reg_array [`NUM_MAIN_REGS-1:0];
  genvar i;
  generate
    for (i = 0; i < `NUM_MAIN_REGS; i = i + 1) begin : REGS
      assign reg_array[i] = reg_values[`REG_DATA_WIDTH * (i + 1) - 1:
                                       `REG_DATA_WIDTH * i];
    end
  endgenerate

  // For now, send the values of the register to the lines of the screen, for
  // visual verification.
  // TODO: This test mechanism needs to be changed later.
  assign vga_rgb = (hblank | vblank) ? {`RGB_COLOR_DEPTH {1'b0}}
                                     : {`RGB_COLOR_DEPTH {reg_values[v_pos]}};

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
                .data(mpu_data),
                .values_out(reg_values));

  // VRAM interface logic
  // TODO: the multiplexed VRAM access by both GPU and MPU here may be too
  // simple.
  wire vram_uses_mpu = ~_mpu_en;
  assign _vram_en = vram_uses_mpu ? _mpu_en : _gpu_bus_en;
  assign _vram_wr = vram_uses_mpu ? _mpu_wr : _gpu_bus_wr;
  assign _vram_rd = vram_uses_mpu ? _mpu_rd : _gpu_bus_rd;
  assign _vram_be = vram_uses_mpu ? _mpu_be : _gpu_bus_be;
  assign vram_addr = vram_uses_mpu ? mpu_addr : gpu_bus_addr;

  assign vram_data = vram_uses_mpu ? mpu_data : {`VRAM_DATA_WIDTH {1'bz}};
  assign gpu_bus_data = vram_data;

endmodule
