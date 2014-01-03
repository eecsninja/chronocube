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


// Palette file.

module Palette(
    clk_a, wr_a, rd_a, addr_a, data_in_a, data_out_a, byte_en_a,
    clk_b, wr_b, rd_b, addr_b, data_in_b, data_out_b);
  parameter NUM_CHANNELS = 3;
  localparam BITS_PER_BYTE = 8;
  localparam DATA_WIDTH = NUM_CHANNELS * BITS_PER_BYTE;
  localparam ADDR_WIDTH = 10;

  input clk_a;
  input wr_a;
  input rd_a;
  input [NUM_CHANNELS-1:0] byte_en_a;
  input [ADDR_WIDTH-1:0] addr_a;
  input [DATA_WIDTH-1:0] data_in_a;
  output [DATA_WIDTH-1:0] data_out_a;

  input clk_b;
  input wr_b;
  input rd_b;
  input [ADDR_WIDTH-1:0] addr_b;
  input [DATA_WIDTH-1:0] data_in_b;
  output [DATA_WIDTH-1:0] data_out_b;

  genvar i;
  generate
    for (i = 0; i < NUM_CHANNELS; i = i + 1) begin : RAM
      // Instantiate 1Kx8 RAMs in parallel.
      palette_ram_1Kx8 ram(.clock_a(clk_a),      .clock_b(clk_b),
                           .address_a(addr_a),   .address_b(addr_b),
                           .wren_a(wr_a),        .wren_b(wr_b),
                           .rden_a(rd_a),        .rden_b(rd_b),
                           .data_a(data_in_a[(i + 1) * BITS_PER_BYTE - 1 :
                                             i * BITS_PER_BYTE]),
                           .data_b(data_in_b[(i + 1) * BITS_PER_BYTE - 1 :
                                             i * BITS_PER_BYTE]),
                           .q_a(data_out_a[(i + 1) * BITS_PER_BYTE - 1 :
                                           i * BITS_PER_BYTE]),
                           .q_b(data_out_b[(i + 1) * BITS_PER_BYTE - 1 :
                                           i * BITS_PER_BYTE]),
                           .byteena_a(byte_en_a[i]));
    end
  endgenerate

endmodule
