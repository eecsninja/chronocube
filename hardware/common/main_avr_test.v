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


// Test bench for main module.

`timescale 10 ns / 1 ns

module Main_Test;

  parameter ADDR_WIDTH=16;
  parameter DATA_WIDTH=8;

  reg clk;          // System clock
  reg reset;        // System reset

  reg rd;           // Read enable
  reg wr;           // Write enable
  reg ale;          // Address latch enable.
  reg [ADDR_WIDTH-1:0] addr;      // Address bus
  reg [DATA_WIDTH-1:0] data_in;   // Data in bus

  reg data_valid;                 // Indicates data-in is valid.

  wire [DATA_WIDTH-1:0] data_out; // Data out bus

  wire [DATA_WIDTH-1:0] ad;
  MainAVR main_avr(._reset(~reset), .clk(clk),
                   ._mpu_rd(~rd), ._mpu_wr(~wr), .mpu_ale(ale),
                   .mpu_ah(addr[ADDR_WIDTH-1:DATA_WIDTH]), .mpu_ad(ad));

  assign data_out = (rd & ~wr & ~ale) ? ad : 'bx;
  assign ad = ale ? addr[DATA_WIDTH-1:0] : (data_valid ? data_in : 'bz);

  // Generate clock.
  always
    #1 clk = ~clk;

  integer i;
  reg [4:0] stage = 0;

  initial begin
    clk = 0;

    reset = 0;
    rd = 0;
    wr = 0;
    addr = 0;
    data_in = 0;
    data_valid = 0;

    // Reset
    #5 stage = 1;
    #1 reset = 1;
    #5 reset = 0;

    #1 addr = 'bx;

    // Test some writes
    #5 stage = 2;
    #1 write16(0, 'hdead);
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
    #5 stage = 3;
    #1 read_test();

    #1 addr = 'bx;

    // Test some byte writes
    #5 stage = 4;
    for (i = 0; i < 16; i = i + 1)
    begin
      #1 write8(i * 2, 'h0000);
      #1 write8(i * 2 + 1, 'hffff);
    end

    // Test some reads
    #5 stage = 5;
    #1 read_test();

    // Test some palette writes
    #5 stage = 6;
    for (i = 0; i < 16; i = i + 1)
    begin
      #1 write16('h1000 + i * 2, ~i);
    end

    #5 stage = 7;
    for (i = 0; i < 32; i = i + 1)
    begin
      #1 read8('h1000 + i);
    end
  end


  // Task to write a byte.
  task write8;
    input [ADDR_WIDTH-1:0] addr_arg;
    input [DATA_WIDTH-1:0] data_arg;
    begin
          addr = addr_arg;
          data_in = data_arg;
      #2  rd = 0; wr = 0; ale = 1; data_valid = 0;
      #2  rd = 0; wr = 1; ale = 0; data_valid = 1;
      #2  rd = 0; wr = 0; ale = 0; data_valid = 1;
      #2                           data_valid = 0;
    end
  endtask

  // Task to write a word.
  task write16;
    input [ADDR_WIDTH-1:0] addr_arg;
    input [DATA_WIDTH*2-1:0] data_arg;
    begin
      write8(addr_arg, data_arg[DATA_WIDTH-1:0]);
      write8(addr_arg + 1, data_arg[DATA_WIDTH*2-1:DATA_WIDTH]);
    end
  endtask

  // Task to read a byte.
  task read8;
    input [ADDR_WIDTH-1:0] addr_arg;
    begin
          addr = addr_arg;
      #2  rd = 0; wr = 0; ale = 1;
      #2  rd = 1; wr = 0; ale = 0;
      #2  rd = 0; wr = 0; ale = 0;
    end
  endtask

  // Readback test for the register
  task read_test;
    integer i;
    begin
      // Test some reads
      #5 
      for (i = 0; i < 30; i = i + 1) begin
        #1 read8(i);
      end
    end
  endtask

endmodule

