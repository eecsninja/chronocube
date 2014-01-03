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


// Test bench for renderer.

`include "registers.vh"
`include "tile_registers.vh"
`include "sprite_registers.vh"

`define DISPLAY_HCOUNT_WIDTH 10
`define DISPLAY_VCOUNT_WIDTH 10

module Renderer_Test;

  reg clk;          // System clock
  reg reset;        // System reset

  wire [`DISPLAY_HCOUNT_WIDTH-1:0] h_pos;
  wire [`DISPLAY_VCOUNT_WIDTH-1:0] v_pos;
  DisplayController #(.HCOUNT_WIDTH(`DISPLAY_HCOUNT_WIDTH),
                      .VCOUNT_WIDTH(`DISPLAY_VCOUNT_WIDTH))
      display(.clk(clk),
              .reset(reset),
              .v_pos(v_pos),
              .h_pos(h_pos));

  wire h_sync, v_sync;

  reg [127:0] spr_values [255:0];
  reg [127:0] spr_data;
  reg [127:0] spr_data_reg;
  wire [7:0] spr_addr;
  wire spr_clk;

  // Simulate the reading of sprite RAM.
  always @ (posedge spr_clk)
    spr_data <= spr_values[spr_addr];

  // Renderer
  Renderer renderer(.clk(clk),
                    .reset(reset),
                    .reg_values(0),
                    .tile_reg_values(0),

                    .spr_clk(spr_clk),
                    .spr_addr(spr_addr),
                    .spr_data(spr_data),

                    .h_pos(h_pos),
                    .v_pos(v_pos),
                    .h_sync(h_sync),
                    .v_sync(v_sync));


  // Generate clock.
  always
    #1 clk = ~clk;

  integer i;
  integer stage = 0;

  initial begin
    clk = 0;
    reset = 0;

    // Reset
    #5 reset = 1;
    #1 reset = 0;

    // Set up sprite register values.
    for (i = 0; i < `NUM_SPRITES; i = i + 1) begin
      if (i < 4) begin
        // Enable the first four registers.
        spr_values[i * 2] = 1 | ((15-i)) << 16;
        // Also give them x/y offsets.
        spr_values[i * 2 + 1] = (i * 8) | ((i * 8) << 16);
      end else begin
        spr_values[i * 2] = 0;
        spr_values[i * 2 + 1] = 0;
      end
    end

  end

endmodule
