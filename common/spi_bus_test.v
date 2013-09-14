// Copyright (c) 2013, Simon Que
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer.
// Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation
// and/or other materials provided with the distribution.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.

`timescale 1ns/1ps

`include "spi_bus.vh"

module SPIBusTest;
  // Main SPI interface.
  reg main_nss, main_sck, main_mosi;
  wire main_miso;

  // Secondary SPI interface.
  reg alt_nss, alt_sck, alt_mosi;
  wire alt_miso;

  // SPI memory bus interface.
  wire mem_nss, mem_sck, mem_mosi;
  reg mem_miso;

  // Instantiate the Unit Under Test (UUT).
  SPIBus spi_bus(main_nss, main_sck, main_mosi, main_miso,
                 alt_nss, alt_sck, alt_mosi, alt_miso,
                 mem_nss, mem_sck, mem_mosi, mem_miso);

  integer stage;      // Keeps track of test progress.

  // Generate contents of |mem_miso| as the inverse of |mem_mosi|.
  always @ (*)
    mem_miso <= ~mem_mosi;

  initial begin
    main_nss = 0;
    main_sck = 0;
    main_mosi = 0;

    alt_nss = 1;
    alt_sck = 0;
    alt_mosi = 0;

    stage = 0;

    #1 main_nss = 1;

    #10
    stage = 1;

    // Set main SPI bus control.
    main_nss = 0;
    main_spi_transmit(`SPI_BUS_STATE_MAIN_BUS);
    main_nss = 1;

    // Perform some memory bus accesses.
    #10
    main_nss = 0;
    main_spi_transmit(`SPI_BUS_STATE_MEMORY);
    main_spi_transmit(8'h01);
    main_spi_transmit(8'h02);
    main_spi_transmit(8'h04);
    main_spi_transmit(8'h08);
    main_nss = 1;

    // Attempt a secondary SPI access, should not go through.
    #10
    alt_nss = 0;
    alt_spi_transmit(8'h11);
    alt_spi_transmit(8'h22);
    alt_spi_transmit(8'h44);
    alt_spi_transmit(8'h88);
    alt_nss = 1;

    // Hand over control to the secondary bus.
    #10
    stage = 2;
    main_nss = 0;
    main_spi_transmit(`SPI_BUS_STATE_ALT_BUS);
    main_nss = 1;

    // The main bus should no longer have access.
    #10
    main_nss = 0;
    main_spi_transmit(`SPI_BUS_STATE_MEMORY);
    main_spi_transmit(8'h01);
    main_spi_transmit(8'h02);
    main_spi_transmit(8'h04);
    main_spi_transmit(8'h08);
    main_nss = 1;

    // Attempt a secondary SPI access, should go through to the memory bus.
    #10
    alt_nss = 0;
    alt_spi_transmit(8'h11);
    alt_spi_transmit(8'h22);
    alt_spi_transmit(8'h44);
    alt_spi_transmit(8'h88);
    alt_nss = 1;

    // Retake control for the main bus.
    #10
    stage = 3;
    main_nss = 0;
    main_spi_transmit(`SPI_BUS_STATE_MAIN_BUS);
    main_nss = 1;

    // Things should be back to normal.  Main bus goes through, secondary bus
    // does not.
    #10
    main_nss = 0;
    main_spi_transmit(`SPI_BUS_STATE_MEMORY);
    main_spi_transmit(8'h01);
    main_spi_transmit(8'h02);
    main_spi_transmit(8'h04);
    main_spi_transmit(8'h08);
    main_nss = 1;
    #10
    alt_nss = 0;
    alt_spi_transmit(8'h11);
    alt_spi_transmit(8'h22);
    alt_spi_transmit(8'h44);
    alt_spi_transmit(8'h88);
    alt_nss = 1;

    #10
    stage = 4;
  end

  // Task to send a byte over primary SPI bus.
  task main_spi_transmit;
    input [`BYTE_WIDTH-1:0] data;
    integer i;
    begin
      main_sck = 0;
      #2
      main_sck = 0;
      for (i = 0; i < `BYTE_WIDTH; i = i + 1) begin
        main_mosi = data[`BYTE_WIDTH - 1 - i];
        #1
        main_sck = 1;
        #1
        main_sck = 0;
      end
      #2
      main_sck = 0;
      main_mosi = 0;
    end
  endtask

  // Task to send a byte over secondary SPI bus.
  task alt_spi_transmit;
    input [`BYTE_WIDTH-1:0] data;
    integer i;
    begin
      alt_sck = 0;
      #2
      alt_sck = 0;
      for (i = 0; i < `BYTE_WIDTH; i = i + 1) begin
        alt_mosi = data[`BYTE_WIDTH - 1 - i];
        #1
        alt_sck = 1;
        #1
        alt_sck = 0;
      end
      #2
      alt_sck = 0;
      alt_mosi = 0;
    end
  endtask

endmodule

