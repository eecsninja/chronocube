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

// A library of various basic logic elements.

// D flip-flop.
module DFlipFlop(clk, en, d, q);
  parameter WIDTH=1;
  input clk;
  input en;
  input [WIDTH-1:0] d;
  output [WIDTH-1:0] q;

  reg [WIDTH-1:0] q;

  always @ (posedge clk)
  if (en) begin
    q <= d;
  end
endmodule

// D-type Latch.
module DLatch(en, d, q);
  parameter WIDTH=1;
  input en;
  input [WIDTH-1:0] d;
  output [WIDTH-1:0] q;

  wire [WIDTH-1:0] reg_out;

  DFlipFlop #(WIDTH) r(~en, 1'b1, d, reg_out);

  assign q = en ? d : reg_out;
endmodule

// Bidirectional I/O pin.
module Bidir(sel_in, io, in, out);
  parameter WIDTH=1;
  input sel_in;
  inout [WIDTH-1:0] io;
  output [WIDTH-1:0] in;
  input [WIDTH-1:0] out;

  assign in = sel_in ? io : 'bz;
  assign io = sel_in ? 'bz : out;
endmodule

// Double D flip-flop with a 2:1 multiplexed output.
module MuxReg(sel, clk, en, in_a, in_b, out);
  parameter WIDTH=8;
  input sel;
  input clk;
  input en;
  input [WIDTH-1:0] in_a;
  input [WIDTH-1:0] in_b;

  output [WIDTH-1:0] out;

  wire [WIDTH-1:0] out_a;
  wire [WIDTH-1:0] out_b;

  DFlipFlop #(WIDTH) reg_a(clk, en, in_a, out_a);
  DFlipFlop #(WIDTH) reg_b(clk, en, in_b, out_b);

  assign out = sel ? out_a : out_b;
endmodule
