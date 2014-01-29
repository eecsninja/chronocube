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


// Video display signal generator
// The current values are for 640x480 @ 60 MHz.
// See: http://tinyvga.com/vga-timing/640x480@60Hz
// TODO: support other display modes.

`include "video_modes.vh"

module DisplayController(clk, reset, h_pos, v_pos, mode);
  input clk;          // System clock
  input reset;        // System reset
  input [`VIDEO_MODE_WIDTH-1:0] mode;     // Video mode.

  output reg [`VIDEO_COUNT_WIDTH-1:0] h_pos;    // Output scan position counters.
  output reg [`VIDEO_COUNT_WIDTH-1:0] v_pos;

  // Detect the end of a horizontal or vertical scan period.
  wire h_end, v_end;
  DisplayTiming timing(.h_pos(h_pos),
                       .v_pos(v_pos),
                       .h_end(h_end),
                       .v_end(v_end),
                       .mode(mode));

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
      if (h_end)
      begin
        if (v_end)
          v_pos <= 0;
        else
          v_pos <= v_pos + `VIDEO_COUNT_WIDTH'b1;
        h_pos <= 0;
      end else
      begin
        h_pos <= h_pos + `VIDEO_COUNT_WIDTH'b1;
      end
    end
  end

endmodule

// Decodes horizontal and vertical scan position into blanking, sync, etc.
module DisplayTiming(h_pos, v_pos, h_sync, v_sync, h_blank, v_blank,
                     h_visible_pos, v_visible_pos, h_end, v_end,
                     mode);
  input [`VIDEO_COUNT_WIDTH-1:0] h_pos;
  input [`VIDEO_COUNT_WIDTH-1:0] v_pos;
  input [`VIDEO_MODE_WIDTH-1:0] mode;

  // Sync signals.
  output h_sync, v_sync;
  // Blanking signals indicating that scanout is in an off-screen area.
  output h_blank, v_blank;
  // Position of scanout relative to upper-left corner of visible portion of
  // screen.
  output [`VIDEO_COUNT_WIDTH-1:0] h_visible_pos;
  output [`VIDEO_COUNT_WIDTH-1:0] v_visible_pos;
  // Indicates that the last pixel or line of the h/v scan is being displayed.
  output h_end, v_end;

  wire [`VIDEO_COUNT_WIDTH * `NUM_TIMING_VALUES - 1:0] h_timing_values_array;
  wire [`VIDEO_COUNT_WIDTH * `NUM_TIMING_VALUES - 1:0] v_timing_values_array;
  // Decode the timing values for the video mode.
  VideoModeDecoder decoder(mode, h_timing_values_array, v_timing_values_array);

  // Distribute them into separate values.
  wire [`VIDEO_COUNT_WIDTH-1:0] h_timing_values [`NUM_TIMING_VALUES-1:0];
  wire [`VIDEO_COUNT_WIDTH-1:0] v_timing_values [`NUM_TIMING_VALUES-1:0];
  genvar i;
  generate
    for (i = 0; i < `NUM_TIMING_VALUES; i = i + 1) begin : timing_values
      // Do this in reverse, as the order is reversed in the concatenation
      // in VideoModeDecoder.
      assign h_timing_values[`NUM_TIMING_VALUES - 1 - i] =
          h_timing_values_array[`VIDEO_COUNT_WIDTH * (i + 1) - 1:
                                `VIDEO_COUNT_WIDTH * i];
      assign v_timing_values[`NUM_TIMING_VALUES - 1 - i] =
          v_timing_values_array[`VIDEO_COUNT_WIDTH * (i + 1) - 1:
                                `VIDEO_COUNT_WIDTH * i];
    end
  endgenerate

  `define H_VISIBLE_LENGTH    h_timing_values[0]
  `define H_FRONT_LENGTH      h_timing_values[1]
  `define H_SYNC_LENGTH       h_timing_values[2]
  `define H_BACK_LENGTH       h_timing_values[3]
  `define H_SYNC_START        h_timing_values[4]
  `define H_BACK_START        h_timing_values[5]
  `define H_VISIBLE_START     h_timing_values[6]
  `define H_FRONT_START       h_timing_values[7]
  `define H_TOTAL_LENGTH      h_timing_values[8]

  `define V_VISIBLE_LENGTH    v_timing_values[0]
  `define V_FRONT_LENGTH      v_timing_values[1]
  `define V_SYNC_LENGTH       v_timing_values[2]
  `define V_BACK_LENGTH       v_timing_values[3]
  `define V_SYNC_START        v_timing_values[4]
  `define V_BACK_START        v_timing_values[5]
  `define V_VISIBLE_START     v_timing_values[6]
  `define V_FRONT_START       v_timing_values[7]
  `define V_TOTAL_LENGTH      v_timing_values[8]

  assign h_sync = ~(h_pos < `H_SYNC_LENGTH);
  assign v_sync = ~(v_pos < `V_SYNC_LENGTH);
  assign h_blank = (h_pos < `H_VISIBLE_START || h_pos >= `H_FRONT_START);
  assign v_blank = (v_pos < `V_VISIBLE_START || v_pos >= `V_FRONT_START);
  assign h_visible_pos = h_pos - `H_VISIBLE_START;
  assign v_visible_pos = v_pos - `V_VISIBLE_START;
  assign h_end = (h_pos == (`H_TOTAL_LENGTH - 1));
  assign v_end = (v_pos == (`V_TOTAL_LENGTH - 1));

endmodule

module VideoModeDecoder(mode, h_values, v_values);
  // TODO: Use different modes.
  input [`VIDEO_MODE_WIDTH-1:0] mode;

  // Nine values for each of H/V scan: see video_modes.vh.
  output [`VIDEO_COUNT_WIDTH*9-1:0] h_values;
  output [`VIDEO_COUNT_WIDTH*9-1:0] v_values;

  assign h_values = { `VGA_640X480_60HZ_H_VISIBLE_LENGTH,
                      `VGA_640X480_60HZ_H_FRONT_LENGTH,
                      `VGA_640X480_60HZ_H_SYNC_LENGTH,
                      `VGA_640X480_60HZ_H_BACK_LENGTH,
                      `VGA_640X480_60HZ_H_SYNC_START,
                      `VGA_640X480_60HZ_H_BACK_START,
                      `VGA_640X480_60HZ_H_VISIBLE_START,
                      `VGA_640X480_60HZ_H_FRONT_START,
                      `VGA_640X480_60HZ_H_TOTAL_LENGTH };
  assign v_values = { `VGA_640X480_60HZ_V_VISIBLE_LENGTH,
                      `VGA_640X480_60HZ_V_FRONT_LENGTH,
                      `VGA_640X480_60HZ_V_SYNC_LENGTH,
                      `VGA_640X480_60HZ_V_BACK_LENGTH,
                      `VGA_640X480_60HZ_V_SYNC_START,
                      `VGA_640X480_60HZ_V_BACK_START,
                      `VGA_640X480_60HZ_V_VISIBLE_START,
                      `VGA_640X480_60HZ_V_FRONT_START,
                      `VGA_640X480_60HZ_V_TOTAL_LENGTH };
endmodule
