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

`include "spi_memory.vh"

module SPIMemoryTest;
  // SPI interface.
  reg _select, sck, mosi;
  wire miso;

  // Memory interface.
  wire [`MEM_ADDR_WIDTH-1:0] addr;
  wire [`MEM_DATA_WIDTH-1:0] data_in;
  wire [`MEM_DATA_WIDTH-1:0] data_out;
  wire rd, wr;

  // Instantiate the Unit Under Test (UUT).
  SPIMemory spi_memory(
      ._select(_select), .sck(sck), .mosi(mosi), .miso(miso),
      .addr(addr), .data_in(data_in), .data_out(data_out), .rd(rd), .wr(wr)
  );

  // Don't have actual memory, so just use the lower byte of memory as the data
  // read from memory.
  assign data_in = addr[`MEM_DATA_WIDTH-1:0];

  initial begin
    _select = 0;
    sck = 0;
    mosi = 0;
    #1 _select = 1;

    // Perform some writes.
    #10
    _select = 0;
    spi_transmit(8'had);  // Write to address 0x5ead.
    spi_transmit(8'hde);
    spi_transmit(8'h01);  // These are the data bytes written.
    spi_transmit(8'h02);
    spi_transmit(8'h04);
    spi_transmit(8'h08);
    _select = 1;

    #10
    _select = 0;
    spi_transmit(8'hef);  // Write to address 0x6eef.
    spi_transmit(8'hbe);
    spi_transmit(8'h11);  // These are the data bytes written.
    spi_transmit(8'h22);
    spi_transmit(8'h44);
    spi_transmit(8'h88);
    _select = 1;

    // Perform some reads.
    #10
    _select = 0;
    spi_transmit(8'hfe);  // Read from address 0x5afe.
    spi_transmit(8'h5a);
    spi_transmit(8'h01);  // These dummy data bytes should not show up.
    spi_transmit(8'h02);
    spi_transmit(8'h04);
    spi_transmit(8'h08);
    _select = 1;

    #10
    _select = 0;
    spi_transmit(8'hfe);  // Test wraparound during read.
    spi_transmit(8'h7f);
    spi_transmit(8'h11);  // These dummy data bytes should not show up.
    spi_transmit(8'h22);
    spi_transmit(8'h44);
    spi_transmit(8'h88);
    _select = 1;

    #10
    _select = 0;
    spi_transmit(8'hfe);  // Test wraparound during write.
    spi_transmit(8'hff);
    spi_transmit(8'h11);  // These dummy data bytes should not show up.
    spi_transmit(8'h22);
    spi_transmit(8'h44);
    spi_transmit(8'h88);
    _select = 1;

  end

  // Task to send a byte over SPI.
  task spi_transmit;
    input [`BYTE_WIDTH-1:0] data;
    integer i;
    begin
      sck = 0;
      #2
      sck = 0;
      for (i = 0; i < `BYTE_WIDTH; i = i + 1) begin
        mosi = data[i];
        #1
        sck = 1;
        #1
        sck = 0;
      end
      #2
      sck = 0;
    end
  endtask

endmodule

