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
  CC_DFlipFlop #(4) register(clk, en, data, rout);
  CC_DLatch #(4) latch(en, data, lout);

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

module RegDelayTest;
  // Inputs
  reg clk;
  reg reset;
  reg [3:0] data;

  // Outputs
  wire [3:0] out1;
  wire [3:0] out2;
  wire [3:0] out3;

  // Test different delays.
  CC_Delay #(.WIDTH(4), .DELAY(1)) delay1(clk, reset, data, out1);
  CC_Delay #(.WIDTH(4), .DELAY(2)) delay2(clk, reset, data, out2);
  CC_Delay #(.WIDTH(4), .DELAY(3)) delay3(clk, reset, data, out3);

  initial begin
    clk = 0;
    reset = 1;
    data = 0;

    #3 reset = 0;
  end

  always
    #1 clk = ~clk;

  always
    #2 data = data + 1;

endmodule


module CC_BidirTest;
  reg sel_in;
  wire [3:0] port, in, out;

  CC_Bidir #(4) bidir(sel_in, port, in, out);
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


module CC_MuxRegTest;
  reg clk;
  reg sel;
  reg en;
  reg [3:0] in_a, in_b;
  wire [3:0] out;

  CC_MuxReg #(4) muxreg(sel, clk, en, in_a, in_b, out);

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


module CC_DecoderTest;
  parameter WIDTH=4;

  // Inputs
  reg [WIDTH-1:0] in;

  // Outputs
  wire [(1 << WIDTH)-1:0] out;

  CC_Decoder #(WIDTH) decoder(.in(in), .out(out));

  initial
    in = 0;

  always
    #1 in = in + 1;

endmodule
