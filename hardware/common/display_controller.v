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


// Chronocube video display signal generator
// The current values are for 640x480 @ 60 MHz.
// See: http://tinyvga.com/vga-timing/640x480@60Hz
// TODO: support other display modes.

module DisplayController(
    clk, _reset, h_pos, v_pos, hsync, vsync, hblank, vblank);

  parameter HCOUNT_WIDTH=10;
  parameter VCOUNT_WIDTH=10;

  input clk;          // System clock
  input _reset;       // System reset

  output reg [HCOUNT_WIDTH-1:0] h_pos;    // Output scan position counters.
  output reg [VCOUNT_WIDTH-1:0] v_pos;
  output hsync;       // Horizontal sync
  output vsync;       // Vertical sync
  output hblank;      // Horizontal blanking indicator
  output vblank;      // Vertical blanking indicator

  assign hsync = get_hsync(h_pos);
  assign vsync = get_vsync(v_pos);
  assign hblank = get_hblank(h_pos);
  assign vblank = get_vblank(v_pos);

  wire reset = ~_reset;

  reg clk_25mhz;
  always @ (posedge clk)
    clk_25mhz <= ~clk_25mhz;

  always @ (posedge ~clk_25mhz)
  begin
    if (reset == 1) begin
      h_pos <= 0;
      v_pos <= 0;
    end else begin
      if (h_pos + 1 == 800)
      begin
        if (v_pos + 1 == 525)
          v_pos <= 0;
        else
          v_pos <= v_pos + {{(VCOUNT_WIDTH-1){1'b0}}, 1'b1};
        h_pos <= 0;
      end else
      begin
        h_pos <= h_pos + {{(HCOUNT_WIDTH-1){1'b0}}, 1'b1};
      end
    end
  end

  function get_hsync;
  input [HCOUNT_WIDTH-1:0] h_pos;
    get_hsync = (h_pos < 96) ? 1'b0 : 1'b1;
  endfunction

  function get_vsync;
  input [VCOUNT_WIDTH-1:0] v_pos;
    get_vsync = (v_pos < 2) ? 1'b0 : 1'b1;
  endfunction

  function get_hblank;
  input [HCOUNT_WIDTH-1:0] h_pos;
    get_hblank = (h_pos < 144 || h_pos >= 784);
  endfunction

  function get_vblank;
  input [VCOUNT_WIDTH-1:0] v_pos;
    get_vblank = (v_pos < 35 || v_pos >= 515);
  endfunction

endmodule
