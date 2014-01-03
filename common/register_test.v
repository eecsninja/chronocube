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


// Test bench for single register module.

module Register_Test;

  reg clk;          // System clock
  reg reset;        // System reset

  reg en;           // Access enable
  reg byte_lo;      // Low byte enable
  reg byte_hi;      // High byte enable

  reg [15:0] data_in;
  wire [15:0] data_out;

  assign data = data_in;
  Register register(.reset(reset),
                    .clk(clk),
                    .en(en),
                    .be({byte_hi, byte_lo}),
                    .d(data_in),
                    .q(data_out));

  // Generate clock.
  always
    #1 clk = ~clk;

  initial begin
    clk = 0;

    reset = 0;
    byte_hi = 1;
    byte_lo = 1;
    en = 0;

    // Reset
    #5 reset = 1;
    #1 reset = 0;

    #4 data_in = 'hdead;
    #4 data_in = 'hbeef;

    #1 en = 1;

    #4 data_in = 'hdead;
    #4 data_in = 'hbeef;

    #1 byte_lo = 1;
       byte_hi = 0;

    #4 data_in = 'hface;
    #4 data_in = 'hcafe;

    #1 byte_lo = 0;
       byte_hi = 1;

    #4 data_in = 'hf00d;
    #4 data_in = 'hbead;
  end

endmodule
