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

module DisplayController(clk, reset, h_pos, v_pos);

  parameter HCOUNT_WIDTH=10;
  parameter VCOUNT_WIDTH=10;

  input clk;          // System clock
  input reset;        // System reset

  output reg [HCOUNT_WIDTH-1:0] h_pos;    // Output scan position counters.
  output reg [VCOUNT_WIDTH-1:0] v_pos;

  reg clk_25mhz;
  always @ (posedge clk or posedge reset)
    if (reset)
      clk_25mhz <= 0;
    else
      clk_25mhz <= ~clk_25mhz;

  always @ (posedge clk_25mhz or posedge reset)
  begin
    if (reset) begin
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

endmodule

// Decodes horizontal and vertical scan position into blanking, sync, etc.
module DisplayTiming(h_pos, v_pos, h_sync, v_sync, h_blank, v_blank,
                     h_visible_pos, v_visible_pos);
  localparam FIELD_WIDTH = 10;
  input [FIELD_WIDTH-1:0] h_pos;
  input [FIELD_WIDTH-1:0] v_pos;

  // VGA timing values, measured in pixel clock cycles.
  `define H_VISIBLE_LENGTH               640
  `define H_FRONT_LENGTH                  16
  `define H_SYNC_LENGTH                   96
  `define H_BACK_LENGTH                   48
  `define H_SYNC_START                     0
  `define H_BACK_START         (`H_SYNC_START + `H_SYNC_LENGTH)
  `define H_VISIBLE_START      (`H_BACK_START + `H_BACK_LENGTH)
  `define H_FRONT_START        (`H_VISIBLE_START + `H_VISIBLE_LENGTH)
  `define H_TOTAL_LENGTH       (`H_VISIBLE_LENGTH + `H_FRONT_LENGTH + \
                                `H_SYNC_LENGTH + `H_BACK_LENGTH)

  `define V_VISIBLE_LENGTH               480
  `define V_FRONT_LENGTH                  10
  `define V_SYNC_LENGTH                    2
  `define V_BACK_LENGTH                   33
  `define V_SYNC_START                     0
  `define V_BACK_START         (`V_SYNC_START + `V_SYNC_LENGTH)
  `define V_VISIBLE_START      (`V_BACK_START + `V_BACK_LENGTH)
  `define V_FRONT_START        (`V_VISIBLE_START + `V_VISIBLE_LENGTH)
  `define V_TOTAL_LENGTH       (`V_VISIBLE_LENGTH + `V_FRONT_LENGTH + \
                                `V_SYNC_LENGTH + `V_BACK_LENGTH)

  // Sync signals.
  output h_sync, v_sync;
  // Blanking signals indicating that scanout is in an off-screen area.
  output h_blank, v_blank;
  // Position of scanout relative to upper-left corner of visible portion of
  // screen.
  output [FIELD_WIDTH-1:0] h_visible_pos;
  output [FIELD_WIDTH-1:0] v_visible_pos;

  assign h_sync = ~(h_pos < `H_SYNC_LENGTH);
  assign v_sync = ~(v_pos < `V_SYNC_LENGTH);
  assign h_blank = (h_pos < `H_VISIBLE_START || h_pos >= `H_FRONT_START);
  assign v_blank = (v_pos < `V_VISIBLE_START || v_pos >= `V_FRONT_START);
  assign h_visible_pos = h_pos - `H_VISIBLE_START;
  assign v_visible_pos = v_pos - `V_VISIBLE_START;

endmodule
