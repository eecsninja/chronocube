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

`include "defines.vh"

module CoreLogicTest;
  // MCU SPI interface
  reg mcu_nss, mcu_sck, mcu_mosi;
  wire mcu_miso;

  // Coprocessor SPI interface
  reg [`DEV_SELECT_WIDTH-1:0] cop_nss;
  reg cop_sck, cop_mosi;
  wire cop_miso, cop_nreset;

  // Serial RAM interface
  wire ram_nss, ram_sck, ram_mosi;
  wire ram_miso;

  // Instantiate the Unit Under Test (UUT).
  CoreLogic core_logic(mcu_nss, mcu_sck, mcu_mosi, mcu_miso,
                       cop_nss, cop_sck, cop_mosi, cop_miso,
                       cop_nreset,
                       ram_nss, ram_sck, ram_mosi, ram_miso);

  // Simulate RAM data out by inverting the current RAM data in.
  assign ram_miso = ~ram_mosi;

  initial begin
    mcu_nss = 0;
    mcu_sck = 0;
    mcu_mosi = 0;
    #1 mcu_nss = 1;

    cop_nss = `DEV_SELECT_NONE;
    cop_sck = 0;
    cop_mosi = 0;

    #10    // Reset the system with a 0.
    mcu_nss = 0;
    spi_transmit(`MCU_OP_RESET);
    spi_transmit(`MCU_OP_RESET);
    spi_transmit(`MCU_OP_RESET);
    spi_transmit(0);  // Transmitting other values should not change the state.
    spi_transmit(0);
    mcu_nss = 1;

    #10    // Test sending a dummy byte.
    mcu_nss = 0;
    spi_transmit(65);
    mcu_nss = 1;

    #10    // Test ram access.
    mcu_nss = 0;
    spi_transmit(`MCU_OP_ACCESS_RAM);
    spi_transmit(41);
    spi_transmit(42);
    spi_transmit(50);
    mcu_nss = 1;

    #10   // Test command write.
    mcu_nss = 0;
    spi_transmit(`MCU_OP_WRITE_COMMAND);
    spi_transmit(145);
    spi_transmit(105);
    spi_transmit(219);
    mcu_nss = 1;

  end

  // Task to send a byte over SPI.
  task spi_transmit;
    input [`BYTE_WIDTH-1:0] data;
    integer i;
    begin
      mcu_sck = 0;
      #2
      mcu_sck = 0;
      for (i = 0; i < `BYTE_WIDTH; i = i + 1) begin
        mcu_mosi = data[i];
        #1
        mcu_sck = 1;
        #1
        mcu_sck = 0;
      end
      #2
      mcu_sck = 0;
    end
  endtask

endmodule

