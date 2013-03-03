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

// Test bench for basic logic elements.

`timescale 1ns/1ps

module RegLatchTest;
  // Inputs
  reg en, clk;
  reg [3:0] data;

  // Outputs
  wire [3:0] rout;
  wire [3:0] lout;

  // Instantiate the Unit Under Test (UUT)
  DFlipFlop #(4) register(clk, en, data, rout);
  DLatch #(4) latch(en, data, lout);

  initial begin
    en = 0;
    data = 'b0;
    clk = 0;
  end

  always
    #1 clk = ~clk;

  always
    #4 en = ~en;

  always
    #2 data = data + 1;

endmodule


module BidirTest;
  reg sel_in;
  wire [3:0] port, in, out;

  Bidir #(4) bidir(sel_in, port, in, out);
  reg [3:0] count_in;
  reg [3:0] count_out;

  initial begin
    sel_in = 0;
    count_in = 'b0;
    count_out = 'b0;
  end

  always begin
    #1
    count_in = count_in + 1;
    count_out = count_out - 1;
  end

  assign port = sel_in ? count_in : 'bz;
  assign out = count_out;

  always
    #4 sel_in = ~sel_in;

endmodule


module MuxRegTest;
  reg clk;
  reg sel;
  reg en;
  reg [3:0] in_a, in_b;
  wire [3:0] out;

  MuxReg #(4) muxreg(sel, clk, en, in_a, in_b, out);

  initial begin
    sel = 0;
    en = 0;
    clk = 0;
    in_a = 'b0;
    in_b = 'b0;
  end

  always
    #1 clk = ~clk;

  always
    #4 en = ~en;

  always
    #7 sel = ~sel;

  always
    #6 in_a = in_a + 1;

  always
    #10 in_b = in_b + 1;

endmodule

