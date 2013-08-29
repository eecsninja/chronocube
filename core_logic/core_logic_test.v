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

  // For storing values read from SPI MISO.
  reg [`BYTE_WIDTH-1:0] mcu_read_value;
  reg [`BYTE_WIDTH-1:0] cop_read_value;

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

  // Used to provide a visual code reference when looking at waveforms.
  integer stage;

  initial begin
    stage = 0;

    mcu_nss = 0;
    mcu_sck = 0;
    mcu_mosi = 0;
    #1 mcu_nss = 1;

    cop_nss = `DEV_SELECT_NONE;
    cop_sck = 0;
    cop_mosi = 0;

    mcu_read_value = 0;
    cop_read_value = 0;

    #10    // Reset the system with a 0.
    mcu_nss = 0;
    mcu_spi_transmit(`MCU_OP_RESET);
    mcu_spi_transmit(`MCU_OP_RESET);
    mcu_spi_transmit(`MCU_OP_RESET);
    mcu_spi_transmit(0);  // Transmitting other values should not change the state.
    mcu_spi_transmit(0);
    mcu_nss = 1;

    #10    // Test sending a dummy byte.
    mcu_nss = 0;
    mcu_spi_transmit(65);
    mcu_nss = 1;

    #10  stage = 1;

    #10    // Test ram access.
    mcu_nss = 0;
    mcu_spi_transmit(`MCU_OP_ACCESS_RAM);
    mcu_spi_transmit(41);
    mcu_spi_transmit(42);
    mcu_spi_transmit(50);
    mcu_nss = 1;

    #10   // Test command write.
    mcu_nss = 0;
    mcu_spi_transmit(`MCU_OP_WRITE_COMMAND);
    mcu_spi_transmit(145);
    mcu_spi_transmit(105);
    mcu_spi_transmit(219);
    mcu_nss = 1;

    #10  stage = 2;

    #10   // Test coprocessor read.
    cop_nss = `DEV_SELECT_LOGIC;
    cop_spi_transmit(`COP_OP_READ_COMMAND);
    cop_spi_transmit(0);
    cop_nss = `DEV_SELECT_NONE;

    #10   // Test coprocessor write.
    cop_nss = `DEV_SELECT_LOGIC;
    cop_spi_transmit(`COP_OP_WRITE_STATUS);
    cop_spi_transmit(31);
    cop_spi_transmit(85);
    cop_spi_transmit(131);
    cop_spi_transmit(200);
    cop_nss = `DEV_SELECT_NONE;

    #10  stage = 3;

    #10   // Test status read.
    mcu_nss = 0;
    mcu_spi_transmit(`MCU_OP_READ_STATUS);
    mcu_spi_transmit(0);
    mcu_nss = 1;

    #10    // Test coprocessor RAM access when bus is in MCU mode.
    cop_nss = `DEV_SELECT_LOGIC;
    cop_spi_transmit(`COP_OP_ACCESS_RAM);
    cop_spi_transmit(1);
    cop_spi_transmit(2);
    cop_spi_transmit(4);
    cop_spi_transmit(8);
    cop_nss = `DEV_SELECT_NONE;

    #10  stage = 4;

    #10    // Hand over RAM bus to coprocessor.
    mcu_nss = 0;
    mcu_spi_transmit(`MCU_OP_WRITE_COMMAND);
    mcu_spi_transmit(`RPC_CMD_NONE);
    mcu_nss = 1;

    cop_nss = `DEV_SELECT_LOGIC;
    mcu_spi_transmit(`COP_OP_WRITE_STATUS);
    mcu_spi_transmit(`RPC_CMD_NONE + 1);
    mcu_nss = `DEV_SELECT_NONE;

    #10    // Test coprocessor RAM access when bus is in coprocessor mode.
    cop_nss = `DEV_SELECT_LOGIC;
    cop_spi_transmit(`COP_OP_ACCESS_RAM);
    cop_spi_transmit(1);
    cop_spi_transmit(2);
    cop_spi_transmit(4);
    cop_spi_transmit(8);
    cop_nss = `DEV_SELECT_NONE;

    #10  stage = 5;

    #10    // Try coprocessor RAM access with another command value.
    mcu_nss = 0;
    cop_nss = `DEV_SELECT_LOGIC;
    mcu_spi_transmit(`COP_OP_WRITE_STATUS);
    mcu_spi_transmit(~`RPC_CMD_NONE);
    mcu_nss = `DEV_SELECT_NONE;
    mcu_nss = 1;
    #10
    cop_nss = `DEV_SELECT_LOGIC;
    cop_spi_transmit(`COP_OP_ACCESS_RAM);
    cop_spi_transmit(1);
    cop_spi_transmit(2);
    cop_spi_transmit(4);
    cop_spi_transmit(8);
    cop_nss = `DEV_SELECT_NONE;

    #10  stage = 6;

  end

  // Task to send a byte over MCU SPI bus.
  task mcu_spi_transmit;
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
        mcu_read_value[i] = mcu_miso;
        #1
        mcu_sck = 0;
      end
      #2
      mcu_sck = 0;
    end
  endtask

  // Task to send a byte over Coprocessor SPI bus.
  task cop_spi_transmit;
    input [`BYTE_WIDTH-1:0] data;
    integer i;
    begin
      cop_sck = 0;
      #2
      cop_sck = 0;
      for (i = 0; i < `BYTE_WIDTH; i = i + 1) begin
        cop_mosi = data[i];
        #1
        cop_sck = 1;
        cop_read_value[i] = cop_miso;
        #1
        cop_sck = 0;
      end
      #2
      cop_sck = 0;
    end
  endtask

endmodule

