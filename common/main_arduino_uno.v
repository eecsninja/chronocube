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


// Top-level implementation module for DuinoCube with Arduino Uno interface.

`define RGB_COLOR_DEPTH 18

`define VRAM_ADDR_WIDTH 16
`define VRAM_DATA_WIDTH 16

`define MPU_ADDR_WIDTH 16
`define MPU_DATA_WIDTH 16

`include "spi_memory.vh"

module MainArduinoUno(
    clk, _reset,
    _select, sck, mosi, miso,
    _alt_select, alt_sck, alt_mosi, alt_miso,
    _vram_en, _vram_rd, _vram_wr, _vram_be, vram_addr, vram_data,
    vsync, hsync, rgb,
    led);

  input clk;
  input _reset;

  // SPI memory interface.
  input _select, sck, mosi;
  output miso;

  // Alternate SPI memory interface.
  input _alt_select, alt_sck, alt_mosi;
  output alt_miso;

  // To VRAM.
  output _vram_en;          // Enable access (active low)
  output _vram_rd;          // Read enable (active low)
  output _vram_wr;          // Write enable (active low)
  output [1:0] _vram_be;    // Byte enable (active low)
  output [`VRAM_ADDR_WIDTH-1:0] vram_addr;   // Address bus
  inout [`VRAM_DATA_WIDTH-1:0]  vram_data;   // Data bus

  // To VGA connector.
  output vsync;
  output hsync;
  output [`RGB_COLOR_DEPTH-1:0] rgb;

  // Debug LED.
  output led = mem_nss;

  // Multiplex two SPI buses with the SPI memory interface.
  wire mem_nss, memsck, mem_mosi, mem_miso;
  wire spi_bus_alt_miso;
  SPIBus spi_bus(_select, sck, mosi, miso,
                 _alt_select, alt_sck, alt_mosi, spi_bus_alt_miso,
                 mem_nss, mem_sck, mem_mosi, mem_miso);
  assign alt_miso = _alt_select ? 'bz : spi_bus_alt_miso;

  //////////////////////////////////////////////////////////////////////
  // Internal memory bus conversion.
  // Convert 8-bit data bus to a full 16-bit data bus.
  // - Shift address bits down by 1.
  // - Determine byte enable.
  // - Connect both data_in and data_out ports.
  //////////////////////////////////////////////////////////////////////
  wire [`SPI_MEM_ADDR_WIDTH-1:0] spi_addr;
  wire [`SPI_MEM_DATA_WIDTH-1:0] spi_data_in;
  wire [`SPI_MEM_DATA_WIDTH-1:0] spi_data_out;
  wire spi_rd, spi_wr;

  SPIMemory spi_memory(
      ._select(mem_nss), .sck(mem_sck), .mosi(mem_mosi), .miso(mem_miso),
      .addr(spi_addr), .data_in(spi_data_in), .data_out(spi_data_out),
      .rd(spi_rd), .wr(spi_wr));

  // Shift the address bits down by 1 to convert to a 16-bit bus address.
  wire [`MPU_ADDR_WIDTH-1:0] cc_addr =
      {1'b0, spi_addr[`SPI_MEM_ADDR_WIDTH-1:1]};

  // Connect data ports.

  // Distribute the incoming 8-bit data to both bytes of the 16-bit data port.
  wire [`MPU_DATA_WIDTH-1:0] cc_data_in = {spi_data_out, spi_data_out};

  wire [`MPU_DATA_WIDTH-1:0] cc_data_out;

  // Convert an outgoing 16-bit data bus to an 8-bit data bus by selecting the
  // high or low byte.
  assign spi_data_in =
      spi_addr[0] ? cc_data_out[`BYTE_WIDTH*2-1:`BYTE_WIDTH]
                  : cc_data_out[`BYTE_WIDTH-1:0];

  // Determine byte enable based on whether the incoming address is odd or even.
  wire [1:0] cc_byte_enable = spi_addr[0] ? 2'b10 : 2'b01;

  // Enable bus if either read or write is enabled.
  wire cc_enable = (spi_rd ^ spi_wr);

  /////////////////////////////////////////////////
  // VRAM interface
  /////////////////////////////////////////////////
  wire vram_en;          // All control signals are internally active high.
  wire vram_rd;
  wire vram_wr;
  wire [1:0] vram_be;

  assign _vram_en = ~vram_en;
  assign _vram_rd = ~vram_rd;
  assign _vram_wr = ~vram_wr;
  assign _vram_be = ~vram_be;

  // Set up VRAM bidirectional I/Os.
  wire [`VRAM_DATA_WIDTH-1:0] vram_data_in;
  wire [`VRAM_DATA_WIDTH-1:0] vram_data_out;
  // Output to VRAM active only during write.
  assign vram_data = (vram_en & vram_wr) ? vram_data_out
                                         : {`VRAM_DATA_WIDTH {1'bz}};
  assign vram_data_in = vram_data;

  Core core(.clk(clk),
            .reset(~_reset),
            .mpu_rd(spi_rd),
            .mpu_wr(spi_wr),
            .mpu_en(cc_enable),
            .mpu_be(cc_byte_enable),
            .mpu_addr_in(cc_addr),
            .mpu_data_in(cc_data_in),
            .mpu_data_out(cc_data_out),

            .vram_en(vram_en),
            .vram_rd(vram_rd),
            .vram_wr(vram_wr),
            .vram_be(vram_be),
            .vram_addr(vram_addr),
            .vram_data_in(vram_data_in),
            .vram_data_out(vram_data_out),

            .vga_vsync(vsync),
            .vga_hsync(hsync),
            .vga_rgb(rgb)
            );

endmodule
