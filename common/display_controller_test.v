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


// Test bench for video display signal generator
// Note: this testbench simulates a realistic 50 MHz clock.
// Run it for 17 ms to get a full VGA refresh cycle.

module DisplayController_Test;

  parameter HCOUNT_WIDTH=10;
  parameter VCOUNT_WIDTH=10;

  reg clk;          // System clock
  reg reset;        // System reset

  wire [HCOUNT_WIDTH-1:0] h_pos;    // Output scan position counters.
  wire [VCOUNT_WIDTH-1:0] v_pos;
  wire hsync;       // Horizontal sync
  wire vsync;       // Vertical sync
  wire hblank;      // Horizontal blanking indicator
  wire vblank;      // Vertical blanking indicator

  DisplayController #(HCOUNT_WIDTH, VCOUNT_WIDTH)
      display_controller(.clk(clk),
                         ._reset(~reset),
                         .h_pos(h_pos),
                         .v_pos(v_pos),
                         .hsync(hsync),
                         .vsync(vsync),
                         .hblank(hblank),
                         .vblank(vblank));


  initial begin
    clk = 0;
    reset = 0;

    // Test a reset.
    #100 reset = 1;
    #200  reset = 0;
  end

  // 50 MHz clock.
  always
    #10 clk = !clk;

endmodule
