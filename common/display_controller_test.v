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


// Test bench for video display signal generator
// Note: this testbench simulates a realistic 50 MHz clock.
// Run it for 17 ms to get a full VGA refresh cycle.

`include "video_modes.vh"

module DisplayController_Test;

  reg clk;          // System clock
  reg reset;        // System reset

  wire [`VIDEO_COUNT_WIDTH-1:0] h_pos;    // Output scan position counters.
  wire [`VIDEO_COUNT_WIDTH-1:0] v_pos;
  wire hsync;       // Horizontal sync
  wire vsync;       // Vertical sync
  wire hblank;      // Horizontal blanking indicator
  wire vblank;      // Vertical blanking indicator

  DisplayController display_controller(.clk(clk),
                                       .reset(reset),
                                       .h_pos(h_pos),
                                       .v_pos(v_pos));

  DisplayTiming display_timing(.h_pos(h_pos), .v_pos(v_pos),
                               .h_sync(hsync), .v_sync(vsync),
                               .h_blank(hblank), .v_blank(vblank));

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
