// Copyright (C) 2013 Simon Que
//
// This file is part of ChronoCube.
//
// ChronoCube is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ChronoCube is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ChronoCube.  If not, see <http://www.gnu.org/licenses/>.


// Test bench for registers.

module Registers_Test;

  parameter ADDR_WIDTH=8;
  parameter DATA_WIDTH=16;

  reg clk;          // System clock
  reg reset;        // System reset

  reg en;           // Access enable
  reg rd;           // Read enable
  reg wr;           // Write enable
  reg byte_lo;      // Low byte enable
  reg byte_hi;      // High byte enable

  reg [ADDR_WIDTH-1:0] addr;
  reg [DATA_WIDTH-1:0] data_in;
  wire [DATA_WIDTH-1:0] data;
/*
  CC_Bidir #(DATA_WIDTH) bidir(.sel_in(en & wr),
                               .io(data),
                               .in(data_in));
*/
  assign data = data_in;
  Registers #(.ADDR_BUS_WIDTH(ADDR_WIDTH), .DATA_BUS_WIDTH(DATA_WIDTH))
      registers(.reset(reset),
                .en(en),
                .rd(rd),
                .wr(wr),
                .be({byte_hi, byte_lo}),
                .addr(addr),
                .data(data));

  // Generate clock.
  always
    #1 clk = ~clk;

  integer i;
  initial begin
    clk = 0;

    reset = 0;
    byte_hi = 1;
    byte_lo = 1;
    en = 0;
    rd = 0;
    wr = 0;

    // Reset
    #5 reset = 1;
    #1 reset = 0;

    #5 read_test();

    #1 addr = 'bx;

    // Test some writes
    #5 write16(0, 'hdead);
    #1 write16(2, 'hbeef);
    #1 write16(4, 'hcafe);
    #1 write16(8, 'hface);
    #1 write16(16, 'hbead);
    #1 write16(18, 'hfade);
    #1 write16(24, 'hdeaf);
    #1 write16(26, 'hface);
    #1 write16(28, 'hface);
    #1 write16(30, 'hface);

    #1 addr = 'bx;

    // Test some reads
    #5 read_test();

    #1 addr = 'bx;

    // Test some byte writes
    for (i = 0; i < 15; i = i + 1)
    begin
      #1 write8(i * 2, 'h0000);
      #1 write8(i * 2 + 1, 'hffff);
    end

    // Test some reads
    #5 read_test();

  end

  // Task to write a word.
  task write16;
    input [ADDR_WIDTH-1:0] addr_arg;
    input [DATA_WIDTH-1:0] data_arg;
    begin
          addr = addr_arg >> 1;
          data_in = data_arg;
      #1  en = 1; rd = 0; wr = 1; byte_lo = 1; byte_hi = 1;
      #1  en = 1; rd = 0; wr = 0;
      #1  en = 0; rd = 0; wr = 0; byte_lo = 0; byte_hi = 0;
    end
  endtask

  // Task to write a byte.
  task write8;
    input [ADDR_WIDTH-1:0] addr_arg;
    input [DATA_WIDTH/2-1:0] data_arg;
    begin
          addr = addr_arg >> 1;
          data_in = {data_arg, data_arg};
      #1  en = 1; rd = 0; wr = 1; byte_lo = ~addr_arg[0]; byte_hi = addr_arg[0];
      #1  en = 1; rd = 0; wr = 0;
      #1  en = 0; rd = 0; wr = 0; byte_lo = 0; byte_hi = 0;
    end
  endtask

  // Task to read a word.
  task read;
    input [ADDR_WIDTH-1:0] addr_arg;
    begin
          addr = addr_arg >> 1;
          data_in = 'bz;
      #1  en = 1; rd = 1; wr = 0;
      #3  en = 1; rd = 0; wr = 0;
      #1  en = 0; rd = 0; wr = 0;
    end
  endtask

  // Readback test for the register
  task read_test;
    begin
      // Test some reads
      #5 read(0);
      #1 read(2);
      #1 read(4);
      #1 read(8);
      #1 read(16);
      #1 read(17);
      #1 read(18);
      #1 read(19);
      #1 read(24);
      #1 read(25);
      #1 read(26);
      #1 read(27);
    end
  endtask

endmodule
