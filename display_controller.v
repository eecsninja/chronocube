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


// Chronocube video display signal generator

module DisplayController(
    clk, _reset, h_pos, v_pos, hsync, vsync, hblank, vblank);

  parameter HCOUNT_WIDTH;
  parameter VCOUNT_WIDTH;

  input clk;          // System clock
  input _reset;       // System reset

  output reg [HCOUNT_WIDTH-1:0] h_pos;    // Output scan position counters.
  output reg [VCOUNT_WIDTH-1:0] v_pos;
  output hsync;       // Horizontal sync
  output vsync;       // Vertical sync
  output hblank;      // Horizontal blanking indicator
  output vblank;      // Vertical blanking indicator

  // TODO: use functions for these.
  assign hsync = ~(h_pos < 120);
  assign vsync = ~(v_pos < 6);
  assign vblank = (h_pos < 184 || v_pos >= 984);
  assign hblank = (v_pos < 29 || v_pos >= 629);

  always @ (posedge clk)
  begin
    if (_reset == 0) begin
      h_pos <= 10'b0;
      v_pos <= 10'b0;
    end else begin
      if (h_pos == 10'h3ff)
        v_pos <= v_pos + 10'b1;
      h_pos <= h_pos + 10'b1;
    end
  end

endmodule
